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

%define ENABLE 	0x0000
%define DISABLE 0x0001

; ======================================================================== ;
; helper functions regarding pci configuration command register
; 
; all these require si to point to bus/slot/function/offset structure.
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

; ======================================================================== ;
; helper functions regarding pci configuration status register
; 
; all these require si to point to bus/slot/function/offset structure.
; [si]     = bus
; [si+4]   = slot
; [si+8]   = function
; [si+12]  = offset
; 
; sets ax  = status register content
; trashes  = high 16 bits of eax
; ======================================================================== ;
pci_stat_read:
	push 	bp
	mov 	bp, sp
	push 	ebx
	mov 	eax, dword [si+12]
	push 	eax
	mov 	dword [si+12], 4
	call 	pci_config_inl
	shr 	eax, 16
	pop 	ebx
	mov 	dword [si+12], ebx
	pop 	ebx
	mov 	sp, bp
	pop 	bp
	ret

; The macro below are used to help/ease developing pci driver code.
; All of the macros require [si] to be set up as pci_cmd_write needs it to be.
;	PCI_CMD(PCI_CMD_XX, ENABLE/DISABLE)
;
; Refer to pci_core.asm to see PCI_CMD_ definitions.
;
%macro PCI_CMD 2
	push 	cx
	push 	bx
	mov 	cx, %0
	mov 	bx, %1
	call 	pci_cmd_write
	pop 	bx
	pop 	cx
%endmacro

; Macro to get pci status, sets carry flag if bit is *NOT* set.
; Usage:
;	PCI_STAT(PCI_STAT_XXX)
;
%macro PCI_STAT 1
	push 	eax
	clc
	call 	pci_stat_read
	test 	ax, %1
	jnz 	$ + 2
	stc
	pop 	eax
%endmacro

%endif ; PCI_HELPER
