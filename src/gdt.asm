; BSD 3-Clause License
; 
; Copyright (c) 2020, k4m1 <k4m1@protonmail.com>
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

setup_gdt:
	pusha
	mov 	cx, 22
	call 	malloc
	test 	di, di
	jz 	.malloc_error

	mov 	si, .msg_gdt_at
	call 	serial_print
	mov 	ax, di
	call 	serial_printh

	mov 	bx, di
	add 	bx, 5
	sub 	bx, di
	mov 	word [di], bx

	mov 	bx, di
	add 	bx, 6
	mov 	word [di+2], bx
	mov 	word [di+4], 0

	mov 	dword [di+6], 0
	mov 	dword [di+10], 0
	mov 	word [di+14], 0xffff
	mov 	word [di+16], 0x0000
	mov 	byte [di+17], 0
	mov 	byte [di+18], 10010010b
	mov 	byte [di+19], 11001111b
	mov 	byte [di+20], 0

	lgdt 	[di]
.done:
	popa
	ret

.malloc_error:
	mov 	si, .msg_malloc_error
	call 	serial_print
	jmp 	.done

.msg_gdt_at:
	db "GDT IS AT: 0x", 0
.msg_malloc_error:
	db "FAILED TO MALLOC SPACE FOR GDT", 0x0A, 0x0D, 0

