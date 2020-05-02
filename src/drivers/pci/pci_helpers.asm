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
; This file implements helper functions etc regarding PCI bus, such as 
; device recongnizion etc.
;

%ifndef PCI_HELPER
%define PCI_HELPER

; ======================================================================== ;
; helper functions regarding pci configuration command register
; 
; all these require si to poit to bus/slot/function/offset structure.
; [si]     = bus
; [si+4]   = slot
; [si+8]   = function
; [si+12]  = offset
; 
; cx       = command bit
; bl 	   = 0 for disable, 1 for enable
; ======================================================================== ;
pci_cmd_write:
	push 	bp
	mov 	bp, sp

	push 	eax
	mov 	eax, dword [si+12]
	push 	eax
	mov 	dword [si+12], 4 ; status & command are at offset 4
	call 	pci_config_inl
	test 	bl, bl
	jz 	.disable
	or 	ax, cx
	call 	pci_config_outl
.done:
	pop 	eax
	mov 	dword [si+12], eax
	pop 	eax
	mov 	sp, bp
	pop 	bp
	ret
.disable:
	xor 	cx, 0xffff ; flip the value around, each 0 to 1 and 1 to 0.
	and 	ax, cx
	call 	pci_config_outl
	jmp 	.done	
	

; Disable interrupts of pci device
pci_cli:
	push 	bp
	mov 	bp, sp
	push 	cx
	push 	bx

	mov 	cx, PCI_CMD_INT
	mov 	bl, 0
	call 	pci_cmd_write

	pop 	bx
	pop 	cx
	mov 	sp, bp
	pop 	bp
	ret

; Enable interrupts of pci device
pci_sti:
	push 	bp
	mov 	bp, sp
	push 	cx
	push 	bx

	mov 	cx, PCI_CMD_INT
	mov 	bl, 1
	call 	pci_cmd_write

	pop 	bx
	pop 	cx
	mov 	bp, sp
	pop 	bp
	ret

%endif ; PCI_HELPER
