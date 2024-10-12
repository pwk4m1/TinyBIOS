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

%ifndef PCI_VGA
%define PCI_VGA

; requires:
; 	pci_init to be done.
;
; returns: si = 
; 	pointer to entry of vga-device ptr if vga-dev is found or
;	0 if not 
; 
; notes:
;	we'll return on _FIRST_ vga device found, for now
; 	I don't plant to support multiple monitors..
;
pci_find_vga_dev:
	push 	ax

	; go through all devices we have
	mov 	si, pci_dev_ptr_array
.loop_start:
	; there are some null-bytes after pci device pointers
	lodsw
	test 	ax, ax
	jz 	.not_found
	push 	si
	mov 	si, ax
	add 	si, 18 	; point to class/subclass
	lodsw
	pop 	si
	cmp 	ah, 0x03 ; video/graphics device
	jne 	.loop_start
	sub 	si, 2
	mov 	si, word [si]
.done:
	pop 	ax
	ret
.not_found:
	xor 	si, si
	pop 	ax
	ret

%endif
