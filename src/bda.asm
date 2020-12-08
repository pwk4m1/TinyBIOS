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

; This file contains code related to setting up BIOS Data Area (BDA)
;
; Memory map:
; 
; 	addr   (size)		|	description
; 	-=-=-=-=-=-=-=-=-=-=-=-=+=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
;	0x0400 (4 words) 	| 	IO ports for COM1-COM4 serial
; 	0x0408 (3 words)	|	IO ports for LPT1-LPT3 paraller
; 	0x040E (1 word)		|	EBDA base addr >> 4
;	0x0410 (1 word)		|	packed bit flags for detected hw
;	0x0413 (1 word)		|	Number of kb's of mem before EBDA
;	0x0417 (1 word) 	|	Keyboard state flags
;	0x041e (32 bytes)	|	keyboard buffer
;	0x0449 (1 byte)		|	Display mode
;	0x044A (1 word)		|	Number of columns in text mode
;	0x0463 (1 word)		|	base video IO port
;	0x046C (word)		|	# of IRQ0 timer ticks since boot
;	0x0475 (byte)		| 	# of hard disk drives detected
;	0x0480 (word) 		|	keyboard buffer start
;	0x0482 (word) 		|	keyboard buffer end
;	0x0497 (byte)		|	last keyboard led/shift key state
;
; EBDA:
;	used to store disk read status 'n other stuff for BIOS, nothing
;	interesting in bootloader/os POV, none of this data is to be
;	trusted by us internally as all of it can be changed by non-firmware
;	program code!
;
; 	extended bios data area (EBDA) is to be set between
;	0x00080000 and 0x0009FFFF, that leaves us 128kb of memory to use.
;	
;	NOTE: if malloc() and free() are used after boot by interrupt 
;	handlers, use EBDA + <to be announced> for that.
;
setup_bda:
	pusha
	pushf
	xor 	ax, ax
	mov 	es, ax
	mov 	di, 0x0400

	; first, enumerate all serial devices & set them to 
	; 0x0400 ->
	call 	serial_enum_devices

	popf
	popa
	ret





