; BSD 3-Clause License
; 
; Copyright (c) 2021, k4m1 <k4m1@protonmail.com>
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

; This file implements two macros suitable for logging output, this
; allows for easy way to toggling different levels of output without
; removing the debug prints etc. & then re-adding them constantly...
;

%ifndef __LOG_UTIL_ASM__
%define __LOG_UTIL_ASM__

%ifdef __DO_VERBOSE_LOG__
	%macro LOG 1
		push 	si
		mov 	si, %1
		call 	serial_print
		pop 	si
	%endmacro
%else
	%macro LOG 1
	%endmacro
%endif ; __DO_VERBOSE_LOG__

%ifdef __DO_DEBUG_LOG__
	%macro DEBUG_call 1
		call 	%1
	%endmacro

	%macro DEBUG_LOG 1
		push 	si
		mov 	si, %1
		call 	serial_print
		pop 	si
	%endmacro
%else
	%macro DEBUG_LOG 1
	%endmacro

	%macro DEBUG_call 1
	%endmacro
%endif ; __DO_DEBUG_LOG__

msg_done:
	db "DONE", 0x0A, 0x0D, 0

%endif ; __LOG_UTIL_ASM__
