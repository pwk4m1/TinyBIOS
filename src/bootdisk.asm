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
; This file provides functionality related to finding and loading
; boot disk from MBR (first 512 bytes, ending with AA 55)
;

;
; Check if loaded sector contains a MBR signature AA 55.
; If so, return:
;	ax = 1
; else
;	ax = 0
;
; Requires:
;	si = pointer to loaded sector
;
sector_is_multiboot:
	xor	ax, ax
	add	si, 510
	mov	ax, word [si] ; get signature bytes
	cmp	ax, 0xAA55
	jne	.not_bootdisk
	mov	ax, 1
.done:
	sub	si, 510
	ret
.not_bootdisk:
	xor	ax, ax
	jmp	.done


;
; Load first boot sector from disk to ram
;
; Requires: SI = pointer to sector in ram
; Returns: No.
;
bootsector_to_ram:
	pusha
	mov	di, 0x7c00
	mov	cx, 0x100
	xor	ax, ax
	.loop:
		lodsw
		stosw
		loop	.loop
	popa
	ret


