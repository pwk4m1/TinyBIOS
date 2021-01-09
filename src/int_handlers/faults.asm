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

%macro ADD_EXCEPTION_HANDLR 2
exception_%1:
	mov 	si, %2
	jmp 	exception_abort
%endmacro

%macro ADD_IVT_EXCEPTION_ENTRY 1
	mov 	eax, exception_%1
	and 	eax, 0x0000FFFF
	call 	set_ivt_entry
%endmacro

ADD_EXCEPTION_HANDLR dbze, msg_exception_divide_by_zero
ADD_EXCEPTION_HANDLR breakpoint, msg_exception_breakpoint_trap
ADD_EXCEPTION_HANDLR overflow, msg_exception_overflow
ADD_EXCEPTION_HANDLR bre, msg_exception_bre
ADD_EXCEPTION_HANDLR invalid_opcode, msg_exception_ill
ADD_EXCEPTION_HANDLR dna, msg_exception_dna
ADD_EXCEPTION_HANDLR df, msg_exception_df

init_fault_interrupts:
	pusha
	mov 	bx, cs
	xor 	di, di
	
	ADD_IVT_EXCEPTION_ENTRY dbze
	add 	di, 12 			; past debug & NMI
	ADD_IVT_EXCEPTION_ENTRY breakpoint
	add 	di, 4
	ADD_IVT_EXCEPTION_ENTRY overflow
	add 	di, 4
	ADD_IVT_EXCEPTION_ENTRY bre
	add 	di, 4
	ADD_IVT_EXCEPTION_ENTRY invalid_opcode
	add 	di, 4
	ADD_IVT_EXCEPTION_ENTRY dna
	add 	di, 4
	ADD_IVT_EXCEPTION_ENTRY df

	popa
	ret

; ======================================================================= ;
; Generic fault handler(s)
;
; ======================================================================= ;
exception_abort:
	; print exception message
	push 	si
	mov 	si, msg_exception
	call 	serial_print
	pop 	si
	call 	serial_print

	; hang
	cli
	hlt
	jmp 	$ - 2


msg_exception:
	db "PANIC: ", 0

msg_exception_divide_by_zero:
	db "CODE ATTEMPTED DIV BY 0", 0x0A, 0x0D, 0

msg_exception_breakpoint_trap:
	db "BREAKPOINT", 0x0A, 0x0D, 0

msg_exception_overflow:
	db "OVERFLOW", 0x0A, 0x0D, 0

msg_exception_bre:
	db "BOUND RANGE EXCEEDED", 0x0A, 0x0D, 0

msg_exception_ill:
	db "INVALID INSTRUCTION", 0x0A, 0x0D, 0

msg_exception_dna:
	db "DEVICE NOT AVAILABLE", 0x0A, 0x0D, 0

msg_exception_df:
	db "DOUBLE FAULT", 0x0A, 0x0D, 0

msg_exception_invalid_tss:
	db "INVALID TSS", 0x0A, 0x0D, 0

msg_exception_snp:
	db "SEGMENT NOT PRESENT", 0x0A, 0x0D, 0

msg_exception_ssf:
	db "STACK SEGMENT FAULT", 0x0A, 0x0D, 0

msg_exception_gpf:
	db "GENERAL PROTECTION FAULT", 0x0A, 0x0D, 0

msg_exception_fpe:
	db "FLOATING POINT EXCEPTION", 0xA, 0x0D, 0

msg_excetpion_pf:
	db "PAGE FAULT", 0x0A, 0x0D, 0



