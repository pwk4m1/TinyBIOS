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

%ifndef LPT_ASM
%define LPT_ASM

; Common base addresses for LPT 
%define LPT1 		0x0378 		; IRQ 7
%define LPT1_secondary 	0x03BC 		; IRQ 7
%define LPT2 		0x0278 		; IRQ 6
%define LPT3 		0x03BC 		; IRQ 5 (... *sigh*)

; ======================================================================== ;
; Helper function to enumerate LPT devices
;
; Requires:
;	es:di pointing to BDA at offset to LPT ports
; Returns:
;	none
; sets:
;	word [es:di] => lpt ports
;
probe_lpt_ports:
	push 	dx
	push 	ax

	mov 	dx, LPT1
	call 	__probe_lpt_port

	mov 	dx, LPT2
	call 	__probe_lpt_port

	mov 	dx, LPT3
	call 	__probe_lpt_port

	pop 	ax
	pop 	dx
	ret


; Probe single port, we do this by first sending initialize, waiting 
; a bit, and then reading status.
;
; NOTE: initialize is active _LOW_ when writing
; 	init being set may result in a printer performing a reset &
; 	any buffers being reset,ut)
;
; we write [es:di] = port if lpt, 0 else, di += 2
;
__probe_lpt_port:
	xor 	al, al 	; init is active low, rest are active high...
	add 	dx, 2 	; command port = IO base + 2
	out 	dx, al 	; write init
	dec 	dx 	; status is IO base + 1
	nop 		; very small delay, I hope it's enough 
	nop
	nop
	nop
	in 	al, dx 	; read status
	
	; status error, ack, and busy are active low, they should
	; all be set to 1 now. rest should be 0
	test 	al, 00010011b
	jnz 	.not_lpt
	mov 	ax, dx
	dec 	dx
.write:
	stosw
	ret
.not_lpt:
	test 	dx, LPT1
	je 	.test_lpt1_secondary
	xor 	ax, ax
	jmp 	.write
.test_lpt1_secondary:
	mov 	dx, LPT1_secondary
	jmp 	__probe_lpt_port

%endif ; LPT_ASM
