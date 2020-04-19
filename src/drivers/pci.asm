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

%define __PCIDC_HDR_SIZE 0x9a

; array used for storing pointers to pci device headers
pci_dev_ptr_array:
	times 32 db 2

pci_dev_cnt:
	db 0

; build address to read pci config word from. see pci_config_read_word
; to see how-to setup memory at [si]
__pci_config_build_addr:
	push 	ebx
	push 	ecx
	push 	edx

	mov 	ecx, dword [si+12]
	mov 	ebx, dword [si+8]
	mov 	edx, dword [si]
	mov 	eax, ecx
	;and 	eax, 0xfc
	shl 	ebx, 8
	shl 	edx, 0x10
	or 	eax, 0x80000000
	or 	eax, ebx
	mov 	ebx, dword [si+4]
	shl 	ebx, 0xb
	or 	eax, ebx
	or 	eax, edx	

	pop 	edx
	pop 	ecx
	pop 	ebx
	ret

; parse config word we red, see pci_config_read_word to see how to
; set up memory at [si]
__pci_config_parse_reply:
	push 	ecx
	mov 	ecx, dword [si+12]
	and 	ecx, 2
	shl 	ecx, 3
	shr 	eax, cl
	pop 	ecx
	ret

; read pci config word, requires:
;	[si] 	= bus
; 	[si+4] 	= slot
; 	[si+8] 	= function
; 	[si+12] = offset
; returns:
;	ax = config word
; trashes:
;	high 16 bits of eax
pci_config_read_word:
	push 	bp
	mov 	bp, sp
	push 	dx

	; read config word
	call 	__pci_config_build_addr
	mov 	dx,0xcf8
	out 	dx, eax
	add 	dx, 4
	in 	eax, dx

	; parse it
	call 	__pci_config_parse_reply
	shr 	eax, 16
	pop 	dx
	mov 	bp, sp
	pop 	bp
	ret

; add found pci device header to our list of pci devices
; sets carry flag on error.
; assumes SI to point to bus/slot/fun/off struct
pci_add_device:
	clc
	push 	bp
	mov 	bp, sp
	pusha

	mov 	cx, __PCIDC_HDR_SIZE
	add 	cx, 2
	call 	malloc
	test 	di, di
	jz 	.error_no_memory

	mov 	al, byte [pci_dev_cnt]
	mov 	bx, 2
	mul 	bx
	add 	ax, pci_dev_ptr_array
	mov 	bx, ax
	mov 	word [bx], di

	movsd
	movsd
	xor 	cx, cx
	.loop:
		call 	pci_config_read_word
		stosw
		add 	cx, 2
		cmp 	cx, (__PCIDC_HDR_SIZE - 8)
		jne 	.loop
		
	.done:
		popa
		mov 	bp, sp
		pop 	bp
		ret
	.error_no_memory:
		stc
		mov 	si, __pci_msg_no_memory
		call 	serial_print
		jmp 	.done

; enumerate all pci devices & store info of them to ram, add pointer to
; header to pci_dev_ptr_array
pci_init:
	push 	bp
	mov 	bp, sp
	pusha

	; allocate space for our bus,slot,function,offset structure
	mov 	cx, 16
	call 	malloc
	test 	di, di
	jz 	.error

	xor 	eax, eax
	mov 	si, di
	stosd
	stosd

	.loop:
		call 	pci_config_read_word
		cmp 	ax, 0xFFFF
		je 	.get_next_slot

		push 	ax
		push 	si
		mov 	si, __pci_msg_found_dev_id
		call 	serial_print
		call 	serial_printh
		pop 	si
		pop 	ax
		call 	pci_add_device
		jc 	.done
		mov 	al, byte [pci_dev_cnt]
		inc 	al
		mov 	byte [pci_dev_cnt], al
		cmp 	al, 6 ; we support up to 6 devices for now
		je 	.done

	.get_next_slot:
		mov 	eax, dword [si+4]
		inc 	eax
		mov 	dword [si+4], eax
		cmp 	eax, 32 ; maximum of 32 slots in pci bus
		jne 	.loop

	.get_next_bus:
		mov 	dword [si+4], 0
		mov 	eax, dword [si]
		inc 	eax
		mov 	dword [si], eax
		cmp 	eax, 256 ; theoretical max of 256 buses
		jne 	.loop
	.done:
		popa
		mov 	sp, bp
		pop 	bp
		ret
	.error:
		mov 	si, __pci_msg_no_memory
		call 	serial_print
		jmp 	.done


__pci_msg_no_memory:
	db "PCI INIT FAILED, NOT ENOUGH MEMORY", 0x0A, 0x0D, 0
__pci_msg_found_dev_id:
	db "PCI DEVICE FOUND, ID: ", 0

