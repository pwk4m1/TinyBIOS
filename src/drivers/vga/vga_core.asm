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

%define VGA_ATTRIB_INPUT_STATUS_REGISTER 	0x03DA
%define VGA_ATTRIB_INDEX_REGISTER 		0x03C0
%define VGA_ATTRIB_DATA_REGISTER_R 		0x03C1
%define VGA_ATTRIB_DATA_REGISTER_W 		0x03C0 

; A helper function for reading from sequencer, graphics, and crtc regs
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

; A helper function for writing to Sequencer, Graphics, and CRTC registers.
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

; A helper function for reading from attribute registers
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

	; Read input status #1 register to reset address/data flipflop
	in 	al, VGA_ATTRIB_INPUT_STATUS_REGISTER

	; Read original address register
	in 	al, VGA_ATTRIB_INDEX_REGISTER
	push 	ax

	; output new index
	mov 	ax, bx
	out 	VGA_ATTRIB_INDEX_REGISTER, al

	; read value from data register
	in 	al, VGA_ATTRIB_DATA_REGISTER_R

	; Restore original address
	xchg 	ax, bx
	pop 	ax
	out 	VGA_ATTRIB_INDEX_REGISTER, al

.done:
	pop 	bx
	ret

; A helper function for writing to attribute registers
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

	; Read input status #1 register to reset address/data flipflop
	in 	al, VGA_ATTRIB_INPUT_STATUS_REGISTER

	; Read original address register
	in 	al, VGA_ATTRIB_INDEX_REGISTER
	push 	ax

	; output new index
	mov 	ax, bx
	out 	VGA_ATTRIB_INDEX_REGISTER, al

	; output the data
	mov 	ax, cx
	out 	VGA_ATTRIB_DATA_REGISTER_W, al

	; restore original address
	pop 	ax
	out 	VGA_ATTRIB_INDEX_REGISTER, al

.done:
	pop 	bx
	ret

%endif ; VGA_CORE
