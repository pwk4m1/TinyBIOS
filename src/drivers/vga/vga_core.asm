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

%ifndef VGA_CORE
%define VGA_CORE

%define VGA_CR_INDEX 		0x03B4 ; crtc controller address
%define VGA_CR_DATA		0x03B5 ; crtc controller data

%define VGA_IN_STATUS_1_R	0x03BA ; input status #1
%define VGA_FEATURE_CTL_W 	0x03BA ; feature control

%define VGA_ATTRIB_INDEX 	0x03C0
%define VGA_ATTRIB_DATA 	0x03C1

%define VGA_IN_STATUS_0_R 	0x03C2 ; input status #0
%define VGA_MISC_OUT_W 		0x03C2 ; miscellaneous output

%define VGA_ENABLE 		0x03C3

%define VGA_SEQ_INDEX 		0x03C4 ; sequencer index & data
%define VGA_SEQ_DATA 		0x03C5

%define VGA_DAC_STATE_R		0x03C7
%define VGA_DAC_INDEX_RMODE_W	0x03C7

%define VGA_GC_INDEX 		0x03CE ; graphics controller address
%define VGA_GC_DATA 		0x03CF ; graphics controller data

%define VGA_CR_INDEX_HI 	0x03D4 ; CRTC Controller address
%define VGA_CR_DATA_HI 		0x03D5 ; CRTC Controller data

%define VGA_INPUT_STATUS_HI_R 	0x03DA
%define VGA_FEATURE_CTL_HI_W 	0x03DA

; read vga enable register content to al
__vga_enable_read:
	push 	dx
	mov 	dx, VGA_ENABLE
	in 	al, dx
	pop 	dx
	ret

; write vga enable register value from al
__vga_enable_write:
	push 	dx
	mov 	dx, VGA_ENABLE
	out 	dx, al
	pop 	dx
	ret

; enable vga mask, requires:
;	mask at bh
;	value at bl
;
__vga_enable_mask:
	push 	bp
	mov 	bp, sp

	push 	ax
	push 	bx
	push 	bx
	call 	__vga_enable_read
	not 	bh
	and 	al, bh
	pop 	bx
	and 	bl, bh
	or 	al, bl
	call 	__vga_enable_write
	pop 	bx
	pop 	ax

	mov 	sp, bp
	pop 	bp
	ret
	


%endif
