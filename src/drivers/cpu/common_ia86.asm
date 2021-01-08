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

; ======================================================================== ;
; Helper to get cpuid related stuff 
; ======================================================================== ;

; Function to get cpu vendor string, requires:
;	di: pointer to memory where to store the string
; Returns:
;	nothing
;
cpuid_get_cpu_vendor:
	pusha
	xor 	eax, eax
	cpuid

	; store right-most byte at time to di
	.loop_ebx:
		mov 	al, bl
		stosb
		shr 	ebx, 1
		test 	ebx, ebx
		jnz 	.loop_ebx

	.loop_edx:
		mov 	al, dl
		stosb
		shr 	edx, 1
		test 	edx, edx
		jnz 	.loop_edx

	.loop_ecx:
		mov 	al, cl
		stosb
		shr 	ecx, 1
		test 	ecx, ecx
		jnz 	.loop_ecx
	
	xor 	al, al
	stosb
	popa
	ret

; Function to print cpu vendor string, requires no arguments
; and returns nothing.
;
; cpu vendor is printed over serial line
;
cpuid_print_cpu_vendor:
	push 	bp
	mov 	bp, sp

	push 	cx
	push 	di
	push 	si

	mov 	cx, 13
	call 	malloc
	test 	di, di
	jz 	.end

	push 	di
	call 	cpuid_get_cpu_vendor
	pop 	si
	call 	serial_print
	call 	free

.end:
	pop 	si
	pop 	di
	pop 	cx

	mov 	sp, bp
	pop 	bp
	ret

