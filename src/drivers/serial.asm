; BSD 3-Clause License
; 
; Copyright (c) 2019, k4m1 <k4m1@protonmail.com>
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

; ======================================================================== ;
; Initialize serial port, this is used by int 14h
;
;	DX = Device to initialize, should be figured out by irq handler
; 	AX = Baud rate divisor
; 	BL = Line Control Register value
;
; ======================================================================== ;
serial_init:
	push 	dx

	; first, disable interrupts
	inc 	dx
	xor 	al, al
	out 	dx, al

	; set DLAB = 1
	add 	dx, 2
	add 	al, 10000000b
	out 	dx, al

	; set baud rate divisor
	sub 	dx, 3
	out 	dx, al
	mov 	ah, al
	inc 	dx
	out 	dx, al

	; set line control
	mov 	al, bl
	add 	dx, 2
	out 	dx, al
	dec 	dx

	; enable fifo, clear w/ 14 byte threshold
	mov 	al, 0xC7 
	out 	dx, al

	pop 	dx
	ret

; ======================================================================== ;
;
; Requires:
;	si = offset to null-terminated string
; 		assuming segment f000
; Notes:
;	do check esi address, be careful with segmentation. :P
;
; ======================================================================== ;
serial_print:
	push 	si
	push	ax
	push	dx
	mov 	ax, ds
	push 	ax

	mov 	ax, 0xf000
	mov 	ds, ax
	mov	dx, 0x3F8
	.print_loop:
		lodsb
		test	al, al
		jz	.done
		call 	serial_wait_tx_empty
		jc 	.done
		out	dx, al
		jmp	.print_loop
	.done:
		pop 	ax
		mov 	ds, ax
		pop	dx
		pop	ax
		pop 	si
		ret

; ======================================================================== ;
; Simple function to check that serial line is 'empty', we can 
; transmit byte
; (We read line status, and by 0x20 to check if tx is empty)
;
; We set carry flag on error.
;
serial_wait_tx_empty:
	push 	ax
	push 	cx
	mov 	cx, 50
	add 	dx, 5
	clc
	.loop:
		in 	al, dx
		and 	al, 0x20
		test 	al, al
		jz 	.done
		loop 	.loop
	stc
.done:
	sub 	dx, 5
	pop 	cx
	pop 	ax
	ret

; ======================================================================== ;
;
; Function to print raw hex value as ascii hex over
; serial port. 
;
; Requires:
;	ax = 16-bit integer to print
;
; ======================================================================== ;
serial_printh:
	push	dx
	push	ax
	push	bx
	push	cx

	mov	bx, ax
	xor	ax, ax
	mov	dx, 0x3F8
	mov	cx, 4

	.itoah:
		mov	al, bh
		and	al, 0xF0
		shr	al, 4
		shl	bx, 4

		cmp	al, 0x0A
		jl	.base10

	.base16:
		sub	al, 0x0A
		add	al, 0x41
		out	dx, al
		dec	cx
		jnz	.itoah

	.done:
		mov	al, 0x0A
		out	dx, al
		call 	serial_wait_tx_empty
		jc 	.end
		mov	al, 0x0D
		call 	serial_wait_tx_empty
		jc 	.end
		out	dx, al
	.end:
		pop	cx
		pop	bx
		pop	ax
		pop	dx
		ret

	.base10:
		add	al, 0x30
		out	dx, al
		dec	cx
		jnz	.itoah
		jmp	.done

; ======================================================================== ;
; Get serial line status, this may or may not be relevant here.
; Anyhow, int 14h, ah = 3 asks for status to be read to ah so here we go.
;
; requires:
;	DX = port to io base
; returns:
; 	AH = line status
;
serial_get_line_status:
	add 	dx, 5
	in 	al, dx
	sub 	dx, 5
	ret

; ======================================================================== ;
; Get modem status, used by int 14h ah = 3 aswell
serial_get_modem_status:
	add 	dx, 6
	in 	al, dx
	sub 	dx, 6
	ret
	

