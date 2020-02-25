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


;
; Requires:
;	esi = pointer to null-terminated string
; Notes:
;	do check esi address, be careful with segmentation. :P
;
serial_print:
	push	esi
	push	ax
	push	dx
	mov	dx, 0x3F8
	.print_loop:
		; can't use lodsb here yet
		mov	al, byte [esi]
		inc	esi
		test	al, al
		jz	.done
		out	dx, al
		jmp	.print_loop
	.done:
		pop	dx
		pop	ax
		pop	esi
		ret

;
; Function to print raw hex value as ascii hex over
; serial port. 
;
; Requires:
;	ax = 16-bit integer to print
;
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
		mov	al, 0x0D
		out	dx, al
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

