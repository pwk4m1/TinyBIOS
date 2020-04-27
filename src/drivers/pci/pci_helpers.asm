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
; ======================================================================== ;

; Disable interrupts of pci device
pci_cli:
	push 	bp
	mov 	bp, sp
	; backup eax original value, and original offset from struct
	push 	eax
	mov 	eax, dword [si+12]
	push 	eax
	mov 	dword [si+12], 4 ; status & command are at offset 4
	call 	pci_config_inl
	; eax now has status:command, bit 10 is interrupt disable bit
	and 	eax, 0xfbff
	call 	pci_config_outl
	; restore original offset value & original eax
	pop 	eax
	mov 	dword [si+12], eax
	pop 	eax
	mov 	sp, bp
	pop 	bp
	ret

; Enable interrupts of pci device
pci_sti:
	push 	bp
	mov 	bp, sp
	push 	eax
	mov 	eax, dword [si+12]
	push 	eax
	mov 	dword [si+12], 4
	call 	pci_config_inl
	or 	eax, 0x400
	call 	pci_config_outl
	pop 	eax
	mov 	dword [si+12], eax
	pop 	eax
	mov 	bp, sp
	pop 	bp
	ret


%endif ; PCI_HELPER
