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

%define VGA_ENABLE_PORT 0x3c3
%define VGA_STAT_1 	0x3da

%define VGA_MISC_R 	0x3c2
%define VGA_MISC_W 	VGA_MISC_R + 1

%define VGA_CR_INDEX 	0x3d4
%define VGA_CR_VALUE 	VGA_CR_INDEX + 1

; http://www.osdever.net/FreeVGA/vga/vgareg.htm#general
; http://www.osdever.net/FreeVGA/vga/graphreg.htm#06
; http://www.osdever.net/FreeVGA/vga/extreg.htm#3CCR3C2W
; http://www.osdever.net/FreeVGA/vga/graphreg.htm#05
; http://www.osdever.net/FreeVGA/vga/vgamem.htm
; http://www.osdever.net/FreeVGA/vga/vga.htm#general
; coreboot src/drivers/pc80/vga/vga_io.c

; Function to enable masks on reasonable ports where no indexing is used
; requires:
;	bl = value
;	bh = mask
; 	dx = port
;
__vga_enable_mask_generic:
	push 	ax
	push 	bx

	and 	bl, bh
	not 	bh

	in 	al, dx
	and 	al, bh
	or 	al, bl
	out 	dx, al

	pop 	bx
	pop 	ax
	ret


; Function to enable masking in indexed ports
; requires:
;	bl = value
;	bh = mask
; 	dx = port
;
__vga_enable_mask_misc:
	push 	ax
	push 	bx
	push 	dx

	and 	bl, bh
	not 	bh

	in 	al, dx
	and 	al, bh
	or 	al, bl
	inc 	dx
	out 	dx, al

	pop 	dx
	pop 	bx
	pop 	ax
	ret

; Read CR, super messy, super gross, oh well
;
; require:
;	al = index
;	dx = port
;
__vga_cr_read:
	push 	dx

	out 	dx, al
	inc 	dx
	in 	al, dx

	pop 	dx
	ret

; Write CR, again, super messy & gross but well
;
; require:
;	al = index
;	ah = data
;	dx = port
;
__vga_cr_write:
	push 	dx
	push 	ax

	out 	dx, al
	xchg 	al, ah
	out 	dx, al

	pop 	ax
	pop 	dx
	ret

; Enable command register mask
;
; require:
;	al = index
;	ah = data
;	dx = port
;
__vga_enable_mask_cr:
	push 	ax
	push 	bx
	push 	dx

	and 	bl, bh
	not 	bh

	and 	al, bh
	or 	al, bl
	inc 	dx
	out 	dx, al

	pop 	dx
	pop 	bx
	pop 	ax
	ret

; After the above
; ah = 0x00 for enable
; ah = 0x20 for disable
__vga_palette_set:
	push 	dx
	push 	ax

	mov 	dx, VGA_STAT_1

	in 	al, dx
	xchg 	al, ah
	out 	dx, al
	in 	al, dx

	pop 	ax
	pop 	dx
	ret

%endif
