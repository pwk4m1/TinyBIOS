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

%ifndef PCI_IDE
%define PCI_IDE

; requires:
; 	si = pointer to current device configuration data
;
; returns:
;	al = 1 if device is ide controller, or
; 	al = 0 if device is not ide controller
;
__pci_device_is_ide:
	push 	si
	; get class/subclass word
	add 	si, 10
	lodsw
	cmp 	ax, 0x0101
	je 	.ret
	xor 	ax, ax
	.ret:
		pop 	si
		ret

pci_ide_test:
	push 	bp
	mov 	bp, sp
	pusha

	mov 	cx, 16
	mov 	si, pci_dev_ptr_array
	.loop:
		lodsw
		test 	ax, ax
		jz 	.done
		push 	si
		mov 	si, ax
		add 	si, 8
		; call 	__pci_dump_header
		call 	__pci_device_is_ide
		test 	al, al
		xor 	ah, ah
		pop 	si
		jnz 	.found_pci_ide_controller
		loop 	.loop
		jmp 	.done
	.found_pci_ide_controller:
		push 	si
		mov 	si, msg_found_pci_controller
		call 	serial_print
		pop 	si
		loop 	.loop
	.done:
		popa
		mov 	sp, bp
		pop 	bp
		ret

	popa
	mov 	sp, bp
	pop 	bp
	ret

msg_found_pci_controller:
	db "FOUND PCI IDE CONTROLLER", 0x0A, 0x0D, 0

%endif
