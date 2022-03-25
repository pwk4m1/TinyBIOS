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

%define PIT_CHANNEL_0 	0x40
%define PIT_CHANNEL_1 	0x41
%define PIT_CHANNEL_2 	0x42
%define PIT_MCR_WO 	0x43 	; mode/command register, write-only

; Initialises PIT so that interrupt occures once a second.
;
init_pit:
	push 	eax

	mov 	eax, PIT_SYSTEM_TIME
	mov 	dword [eax], 0

	mov 	al, 0x36
	out 	PIT_MCR_WO, al

	mov 	al, 0x9b
	out 	PIT_CHANNEL_0, al
	mov 	al, 0x2e
	out 	PIT_CHANNEL_0, al

	pop 	eax
        ret

; Handle interrupts by PIT
;
dev_pit_handle_irq:
	push 	eax
	mov 	eax, PIT_SYSTEM_TIME
	add	dword [eax], 1
%ifdef __DO_DEBUG_LOG__
	push 	esi
	mov 	esi, pit_msg_system_time_updated
	call 	serial_print
	mov 	ax, word [eax]
	call 	serial_printh
	pop 	esi
%endif
	pop 	eax
	ret

pit_msg_system_time_updated:
	db "SYSTEM TIME: ", 0

