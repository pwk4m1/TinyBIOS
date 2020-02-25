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

; All code here is based on http://www.osdever.net/FreeVGA/home.htm#vga
; under section VGA Chipset Reference
; (http://www.osdever.net/FreeVGA/vga/vga.htm)

%define VGA_MISC_OUT_READ		0x03CC
%define VGA_MISC_OUT_WRITE 		0x03C2
%define VGA_FEATURE_CTL_READ 		0x03CA 
%define VGA_FEATURE_CTL_WRITE_MONO 	0x03BA
%define VGA_FEATURE_CTL_WRITE_COLO 	0x03DA
%define VGA_INPUT_STATUS_ZERO_RO 	0x03C2
%define VGA_INPUT_STATUS_ONE_RO_MONO 	0x03BA
%define VGA_INPUT_STATUS_ONE_RO_COLO 	0x03DA

%define VGA_INDEX_HTOTAL 	0 	; horizontal total
%define VGA_INDEX_END_HDR 	1 	; end horizontal display
%define VGA_INDEX_START_HDR 	2 	; start horizontal display
%define VGA_INDEX_END_HBR 	3 	; end horizontal blanking
%define VGA_INDEX_START_HBR 	4 	; start horizontal blanking
%define VGA_INDEX_END_HRTRACE 	5 	; end horizontal retrace
%define VGA_INDEX_VT 		6 	; vertical total
%define VGA_INDEX_OFLOW 	7 	; overflow register
%define VGA_INDEX_PRS 		8 	; preset row scan
%define VGA_INDEX_MSL 		9 	; maximum scan line
%define VGA_INDEX_CS 		10 	; cursor line
%define VGA_INDEX_CE 		11 	; cursor end
%define VGA_INDEX_SAH 		12 	; start address high bits 
%define VGA_INDEX_SAL 		13 	; start address low bits
%define VGA_INDEX_CLH 		14 	; cursor location high
%define VGA_INDEX_CLL 		15  	; cursor location low
%define VGA_INDEX_VRS 		16 	; vertical retrace start
%define VGA_INDEX_VRE 		17 	; vertical retrace end
%define VGA_INDEX_VDE 		18 	; vertical display end
%define VGA_INDEX_OFFSET 	19 	; offset register
%define VGA_INDEX_UL 		20 	; underline location
%define VGA_INDEX_SVB 		21 	; start vertical blanking
%define VGA_INDEX_EVB 		22 	; end vertical blanking
%define VGA_INDEX_CRTC_MC 	23 	; crtc mode control
%define VGA_INDEX_LC 		24 	; line compare

; ========================================================================= ;
; misc output register config values

; Determine the polarity of vertical sync pulse. Can be used with
; HSP to control the vertical size of the display by utilizing the
; autosync feature of VGA displays
;
; set to 0 for positive vertical retrace sync pulse.
%define VGA_VSYNCP 			10000000b

; Determine the polarity of the horizontal sync pulse
; Set to 0 to select positive horizontal retrace sync pulse
%define VGA_HSYNCP 			01000000b

; Select the upper/lower 64K memory page when system is in eve/odd mode
; (modes 0 - 3 and 7)
;
; Set to 0 to select low page, or 
; 1 to select high page
%define VGA_OEPAGE 			00100000b

; Select wheter to use 25 or 28 Mhz clock by spec of 1998, possible
; external clock might be possible to use, but that is undefined as is.
%define VGA_CLOCK 			00001100b

; Enable RAM access, by setting this bit to 1 you enable Ram framebuffering,
; which is nice, as then we don't need to do anything but to write to 
; MMI/O area of vga buffer, and that gets fetched to monitor!
%define VGA_RAME 			00000010b

; Select CRT controller address, when this bit is clear the CRT controller
; can be found from address 0x03Bx, and address for input status register 1
; is at 0x03BA. 
; Set the bit to 1 to map CRTC to 0x03Dx and input status reg 1 to 0x03DA.
%define VGA_IOAS 			00000001b

; ========================================================================= ;
; Feature Control Register bit definitions
%define VGA_FCR_FC1 			00000001b ; all bits are reserved.
%define VGA_FCR_FC2 			00000010b ; as above

; ========================================================================= ;
; Input status bits

; SS - switch sense
; "Returns the status of the four sense switches as selected by the CS field 
; of the Miscellaneous Output Register"
%define VGA_INPUT_STATUS_ZERO_SS 	00010000b

; VRetrace - vertical retrace
; set to 1 to indicate, that display is in a vertical retrace intercval.
%define VGA_INPUT_STATUS_ONE_VRETRACE 	00001000b

; DD - Display Disabled
; when set to 1, this bit indicates a horizontal or vertical retrace interval.
%define VGA_INPUT_STATUS_ONE_DD 	00000001b


;
; Helper functions used by this driver
;

;
; Remap registers to 0x03D4 - 0x03D5
;
; Set carry flag on error 
;
__vga_remap_registers:
	clc
	push 	dx
	push 	ax

	; read misc out config
	mov 	dx, VGA_MISC_OUT_READ
	in 	al, dx

	; map ports to 03Dx
	or 	al, VGA_IOAS
	mov 	dx, VGA_MISC_OUT_WRITE
	out 	dx, al

	; check that write succeeded
	nop
	nop
	mov 	dx, VGA_MISC_OUT_READ
	test 	al, VGA_IOAS
	jz 	.write_failed
.do_ret:
	pop 	ax
	pop 	dx
	ret
.write_failed:
	stc
	jmp 	.do_ret

;
; Write to indexed vga register, requires:
;	ah = data to write
; 	al = index where to write the data to
; 	dx = port to write to
; returns:
;	carry flag set on error
;
vga_index_write:
	clc
	push 	ax

	; do write
	out 	dx, al
	mov 	al, ah
	out 	dx, al

	; verify write success
	pop 	ax
	push 	ax
	out 	dx, al
	in 	al, dx

	; if value @ register same that we wanted to write?
	cmp 	al, ah
	jne 	.write_failed
.ret:
	pop 	ax
	ret
.write_failed:
	stc
	jmp 	.ret


