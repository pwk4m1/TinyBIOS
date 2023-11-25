; BSD 3-Clause License
; 
; Copyright (c) 2022, k4m1 <k4m1@protonmail.com>
; All rights reserved.
; 
; Redistribution and use in source and binary forms, with or without
; modification, are permitted provided that the following conditions are met:
; 
; * Redistributions of source code must retain the above copyright notice, 
;   this list of conditions and the following disclaimer.
; 
; * Redistributions in binary form must reproduce the above copyright notice,
;   this list of conditions and the following disclaimer in the documentation
;   and/or other materials provided with the distribution.
; 
; * Neither the name of the copyright holder nor the names of its
;   contributors may be used to endorse or promote products derived from
;   this software without specific prior written permission.
; 
; THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
; AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
; IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR 
; PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR 
; CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, 
; EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
; PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR 
; PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF 
; LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING 
; NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
; OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
; 

%ifndef VGA_CORE
%define VGA_CORE

; Include subsystems
%include "src/drivers/vga/vga_dac.asm"

%define VGA_ATTRIB_INPUT_STATUS_REGISTER 	0x03DA
%define VGA_ATTRIB_INDEX_REGISTER 		0x03C0
%define VGA_ATTRIB_DATA_REGISTER_R 		0x03C1
%define VGA_ATTRIB_DATA_REGISTER_W 		0x03C0 

%define VGA_PEL_ADDRESS_WRITE_MODE_REGISTER 	0x03C8
%define VGA_PEL_DATA_REGISTER_R 		0x03C7
%define VGA_PEL_DATA_REGISTER_W			0x03C9

; read from sequencer, graphics, and crtc regs
;
; Requires:
; 	dx = Address register
; 	bx = address register value for reading
; 	cx = Data register
; Returns:
; 	ax = value from data register on success OR
; 	carry flag set, ax undefined on error
;
vga_sgc_r:
	clc
	push 	dx
	push 	bx
	push 	cx

	; Read in original address register value, and write new address
	; Original address register value is backed up to bx.
	; Also, check that address was really written.
	in 	ax, dx
	xchg 	ax, bx
	out 	dx, ax
	in 	ax, dx
	cmp 	ax, bx
	jne 	.error

	; Read data register
	xchg 	dx, cx
	in 	ax, dx

	; Restore original address register, and check that it
	; indeed succeeded
	push 	ax
	mov 	ax, bx
	mov 	dx, cx
	out 	dx, ax
	in 	ax, dx
	cmp 	ax, bx
	pop 	ax
	je 	.done
	
.error:
	stc
.done:
	pop 	cx
	pop 	bx
	pop 	dx
	ret

; write to Sequencer, Graphics, and CRTC registers.
;
; Requires:
;	dx = Address register
; 	bx = address register value for writing
; 	cx = Data register
; 	si = Data to write to data register
; Returns:
; 	Carry flag set on error
; NOTE:
;	DO be mindful of potential for reserved, undefined, etc. bits in
; 	registers. DO back them up and only change those bits you _NEED_ to.
;
vga_sgc_w:
	clc
	push 	si
	push 	cx
	push 	bx
	push 	ax
	
	; Read in original address register value, and write new address
	; Original address register value is backed up to bx.
	; Also, check that address was really written.
	in 	ax, dx
	xchg 	ax, bx
	out 	dx, ax
	in 	ax, dx
	cmp 	ax, bx
	jne 	.error

	; Write data that you've modified to data register
	mov 	ax, si
	xchg 	cx, dx
	out 	dx, ax

	; Check that write actually succeeded
	in 	ax, dx
	cmp 	ax, si
	jne 	.error

	; If write succeeded, restore original addr reg
	mov 	dx, cx
	mov 	ax, bx
	out 	dx, ax

	; Ensure address is indeed restored correctly
	in 	ax, dx
	cmp 	ax, bx
	je 	.done
.error:
	stc
.done:
	pop 	ax
	pop 	bx
	pop 	cx
	pop 	si
	ret

; read from attribute registers
;
; Requires:
; 	bx = address register value for reading
; Returns:
; 	ax = value from data register on success OR
; 	carry flag set, ax undefined on error
;
; NOTE:
;	Accessing attribute register is confusing and odd, I'll add status
;	checking etc. after verifying it works.
;
; Note for future: you can read CRTC index 0x24, bit 7 on some (S)VGA chipsets
; to determine the status of the flip-flot (0=address,1=data).
; 	To check if this is supported, do:
;		1.) read in from Input Status #1
; 		2.) Check CRTC 0x24, bit 7 = 0
; 		3.) Write index/address to Attrib addr/data register
;		4.) Check CRTC 0x24, bit 7 = 1
; 		5.) Steps 1 and 2 again
;
vga_attrib_r:
	push 	bx
	push 	dx

	; Read input status #1 register to reset address/data flipflop
	mov 	dx, VGA_ATTRIB_INPUT_STATUS_REGISTER
	in 	al, dx

	; Read original address register
	mov 	dx, VGA_ATTRIB_INDEX_REGISTER
	in 	al, dx
	push 	ax

	; output new index
	mov 	ax, bx
	out 	dx, al

	; read value from data register
	mov 	dx, VGA_ATTRIB_DATA_REGISTER_W
	in 	al, dx

	; Restore original address
	xchg 	ax, bx
	pop 	ax
	mov 	dx, VGA_ATTRIB_INDEX_REGISTER
	out 	dx, al

.done:
	pop 	dx
	pop 	bx
	ret

; Write to attribute registers
;
; Requires:
; 	bx = address register value for reading
; 	cx = data to write
; Returns:
; 	carry flag set, ax undefined on error
;
; NOTE:
;	Accessing attribute register is confusing and odd, I'll add status
;	checking etc. after verifying it works.
;
;	DO be mindful of potential for reserved, undefined, etc. bits in
; 	registers. DO back them up and only change those bits you _NEED_ to.
;
vga_attrib_w:
	clc
	push 	bx
	push 	dx

	; Read input status #1 register to reset address/data flipflop
	mov 	dx, VGA_ATTRIB_INPUT_STATUS_REGISTER
	in 	al, dx

	; Read original address register
	mov 	dx, VGA_ATTRIB_INDEX_REGISTER
	push 	ax

	; output new index
	mov 	ax, bx
	out 	dx, al

	; output the data
	mov 	ax, cx
	mov 	dx, VGA_ATTRIB_DATA_REGISTER_W
	out 	dx, al

	; restore original address
	pop 	ax
	mov 	dx, VGA_ATTRIB_INDEX_REGISTER
	out 	dx, al

.done:
	pop 	dx
	pop 	bx
	ret

; read/write 
;
; Requires:
;	bl = 1st colo entry to read 
; 	cl = how many colour bytes to read
;	di = where to read VGA Colour data
; 	bh = is this read/write mode
; Read:
;	Requires:
;		di = where to read to
; Write:
; 	Requires:
;		si = where to write from
;
vga_colo_op:
	pusha

	; backup VGA DEC STATE
	call 	vga_core_dac_status_register_r
	push 	ax

	; backup VGA_PEL_ADDRESS_WRITE_MODE_REGISTER
	mov 	dx, VGA_PEL_ADDRESS_WRITE_MODE_REGISTER
	in 	al, dx
	push 	ax

	; write the 1st colour entry to be read to the PEL Address Read Mode Register
	mov 	al, bl
	out 	dx, al

	; Read colours
	mov 	dx, VGA_PEL_DATA_REGISTER_R
	cmp 	bh, 1
	je 	.do_write
	rep 	insb
	jmp 	.op_done
.do_write:
	rep 	outsb
.op_done:
	; r/w done
	pop 	ax 		; original VGA_PEL_ADDRESS_WRITE_MODE_REGISTER
	pop 	bx 		; original DEC STATE

	; restore PEL on r/w depending on DAC status 
	cmp 	bl, VGA_DAC_STATUS_READ
	je 	.dac_read_set

	mov 	dx, VGA_PEL_DATA_REGISTER_W
	out 	dx, al
	jmp 	.done

.dac_read_set:
	mov 	dx, VGA_PEL_DATA_REGISTER_R
	out 	dx, al
	popa
	ret

; Read/Write functions
vga_colo_r:
	push 	bx
	mov 	bh, 1
	call 	vga_colo_op
	pop 	bx
	ret

vga_colo_w:
	push 	bx
	mov 	bh, 0
	call 	vga_colo_op
	pop 	bx
	ret

%endif ; VGA_CORE
