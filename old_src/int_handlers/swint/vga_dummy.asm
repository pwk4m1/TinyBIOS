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

; ======================================================================== ;
; Set ivt entry for serial interface
;
set_pseudo_vga_ivt_entry:
	pusha
	mov 	eax, pseudo_vga_service_int_handler
	and 	eax, 0x0000ffff
	mov 	bx, cs
	mov 	di, (0x10 * 4)
	call 	set_ivt_entry
	popa
	ret

; ======================================================================== ;
; Handler for serial port related services
;
pseudo_vga_service_int_handler:
	pusha
	cli
	cmp 	ah, 0x09
	je 	.write
	cmp 	ah, 0x0a
	je 	.write
	cmp 	ah, 0x0e
	je 	.write
	cmp 	ah, 0x13
	je 	.write_str
	mov 	si, pseudovga_msg_unknown_command
	call 	serial_print
	call 	serial_printh
	
.done:
	; We get here by software interrupt by CPU, not by 
	; PIC generated int, so don't send EOI !
	popa
	iret

.write:
	mov 	dx, 0x03f8
	out 	dx, al
	jmp 	.done

.write_str:
	mov 	si, bp
	call 	serial_print
	jmp 	.done

pseudovga_msg_unknown_command:
	db "UNKNOWN INT 10H COMMAND: ", 0

