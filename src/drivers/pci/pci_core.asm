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
; This file contains core functionality regarding PCI bus, only bus CAM opers,
; address calculations, and input/output
;
%ifndef PCI_CORE
%define PCI_CORE

%macro DORET 0
	popa
	mov 	sp, bp
	pop 	bp
	ret
%endmacro

%define __PCIDC_HDR_SIZE 32

%define PCI_CMD_IOS 		0x0001 ; io space
%define PCI_CMD_MS 		0x0002 ; memory space
%define PCI_CMD_BM 		0x0004 ; busmaster 
%define PCI_CMD_SCS 		0x0008 ; special cycles
%define PCI_CMD_MWIE 		0x0010 ; memory write and invalidate enable
%define PCI_CMD_VGAPS 		0x0020 ; vga palette snoop
%define PCI_CMD_PER 		0x0040 ; parity error response
%define PCI_CMD_SERRE 		0x0100 ; serr# enable
%define PCI_CMD_FBTBE 		0x0200 ; fast back to back enable
%define PCI_CMD_INT 		0x0400 ; interrupt disable

%define PCI_STAT_INT 		0x0004 ; interrupt status
%define PCI_STAT_CAPLIST 	0x0008 ; capabilities list 
%define PCI_STAT_66MHZ_CAP 	0x0010 ; 66MHz capable
%define PCI_STAT_FBTBE_CAP 	0x0040 ; fast back to back enable capable
%define PCI_STAT_MDPE 		0x0100 ; master data parity error
%define PCI_STAT_DEVSEL_TIMING 	0x0200
%define PCI_STAT_STABRT 	0x0400 ; signaled target abort
%define PCI_STAT_RTABRT 	0x0800 ; received target abort
%define PCI_STAT_RMABRT 	0x1000 ; received master abort
%define PCI_STAT_SIG_SYS_ERR 	0x2000 ; signaled system error
%define PCI_STAT_DPERR 		0x4000 ; detected parity error_

; ======================================================================== ;
; array used for storing pointers to pci device headers
; ======================================================================== ;
pci_dev_ptr_array 	equ 0x5002
pci_dev_cnt 		equ 0x5000

; ======================================================================== ;
; build address to read pci config word from. see pci_config_inw
; to see how-to setup memory at [si]
; ======================================================================== ;
__pci_config_build_addr:
	push 	ebx
	push 	ecx
	push 	edx

	mov 	ecx, dword [si+12]
	mov 	ebx, dword [si+8]
	mov 	edx, dword [si]
	mov 	eax, ecx
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


; ======================================================================== ;
; Helper functions, mainly use these for developing additional logic based 
; on PCI bus
; 
; ======================================================================== ;

; ======================================================================== ;
; read 1 byte from pci configuration space
; requires:
;	[si] 	= bus
; 	[si+4]  = slot
; 	[si+8]  = function
; 	[si+12] = offset
; returns:
;	al = config byte
; ======================================================================== ;
pci_config_inb:
	push 	bp
	mov 	bp, sp
	push 	dx
	push 	eax

	call 	__pci_config_build_addr
	mov 	dx, 0xCF8
	out 	dx, eax
	pop 	eax
	add 	dx, 4
	in 	al, dx

	pop 	dx
	mov 	sp, bp
	pop 	bp
	ret

; ======================================================================== ;
; write pci configuration byte
; requires:
;	[si]    = bus
; 	[si+4]  = slot
; 	[si+8]  = function
; 	[si+12] = offset 
;	al      = config byte to write
; ======================================================================== ;
pci_config_outb:
	push 	bp
	mov 	bp, sp
	push 	dx
	push 	eax
	call 	__pci_config_build_addr
	mov 	dx, 0xCF8
	out 	dx, eax
	pop 	eax
	out 	dx, al
	pop 	dx
	mov 	sp, bp
	pop 	bp
	ret

; as outb, word to write needs to be at ax.
pci_config_outw:
	push 	bp
	mov 	bp, sp
	push 	dx
	push 	eax
	call 	__pci_config_build_addr
	mov 	dx, 0xCF8
	out 	dx, eax
	pop 	eax
	out 	dx, ax
	pop 	dx
	mov 	sp, bp
	pop 	bp
	ret

pci_config_outl:
	push 	bp
	mov 	bp, sp
	push 	dx
	push 	eax
	call 	__pci_config_build_addr
	mov 	dx, 0xCF8
	out 	dx, eax
	pop 	eax
	out 	dx, eax
	pop 	dx
	mov 	sp, bp
	pop 	bp
	ret



; ======================================================================== ;
; read pci config word, requires:
;	[si] 	= bus
; 	[si+4] 	= slot
; 	[si+8] 	= function
; 	[si+12] = offset
; returns:
;	ax = config word
; trashes:
;	high 16 bits of eax
; ======================================================================== ;
pci_config_inw:
	push 	bp
	mov 	bp, sp
	push 	dx
	push 	eax

	call 	__pci_config_build_addr
	mov 	dx, 0xCF8
	out 	dx, eax
	pop 	eax
	add 	dx, 4
	in 	ax, dx

	pop 	dx
	mov 	sp, bp
	pop 	bp
	ret

; ======================================================================== ;
; read pci config dword, requires:
;	[si] 	= bus
; 	[si+4] 	= slot
; 	[si+8] 	= function
; 	[si+12] = offset
; returns:
;	eax = config dword
; ======================================================================== ;
pci_config_inl:
	push 	bp
	mov 	bp, sp
	push 	dx
	push 	eax

	call 	__pci_config_build_addr
	mov 	dx, 0xCF8
	out 	dx, eax
	pop 	eax
	add 	dx, 4
	in 	eax, dx

	pop 	dx
	mov 	sp, bp
	pop 	bp
	ret

; ======================================================================== ;
; Write pci command, return status
; requires:
;	[si] 	= bus
; 	[si+4] 	= slot
; 	[si+8]  = anything, but allocated
; 	[si+12] = anything, but allocated
;	ax = config word to write
; returns:
;	ax = config word
; trashes:
;	high 16 bits of eax
; ======================================================================== ;
pci_write_cmd:
	push 	bp
	mov 	bp, sp
	push 	dx
	push 	ax

	mov 	dword [si+12], 0x04 ; offset to command word
	mov 	dword [si+8],  0x00
	call 	__pci_config_build_addr

	mov 	dx, 0xCF8
	out	dx, eax	 	; write out the address to use

	pop 	ax
	add 	dx, 4
	out 	dx, ax 		; write out the command word

	sub 	dx, 4 		; read the status
	mov 	dword [si+12], 0x06
	call 	__pci_config_build_addr
	out 	dx, eax
	add 	dx, 4
	in 	ax, dx

	mov 	sp, bp
	pop 	bp
	ret

; ======================================================================== ;
; add found pci device header to our list of pci devices
; sets carry flag on error.
; assumes SI to point to bus/slot/fun/off struct
; ======================================================================== ;
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

	xor 	ax, ax
	mov 	al, byte [pci_dev_cnt]
	test 	al, al
	jz 	.add_addr
	mov 	bl, 1
	mul 	bl
.add_addr:
	push 	di
	mov 	di, pci_dev_ptr_array
	add 	di, ax
	pop 	ax
	stosw
	mov 	di, ax
	mov 	al, byte [pci_dev_cnt]
	inc 	al
	mov 	byte [pci_dev_cnt], al

	movsd
	movsd
	sub 	si, 8
	xor 	cx, cx
	; backup original offset
	mov 	eax, dword [si+12]
	push 	eax
	.loop:
		call 	pci_config_inw
		stosw
		add 	dword [si+12], 2
		add 	cx, 2
		cmp 	cx, (__PCIDC_HDR_SIZE - 8)
		jne 	.loop
	.done:
		pop 	eax
		mov 	dword [si+12], eax
		popa
		mov	sp, bp
		pop 	bp
		ret
	.error_no_memory:
		stc
		mov 	si, __pci_msg_no_memory
		call 	serial_print
		jmp 	.done

; ======================================================================== ;
; enumerate all pci devices & store info of them to ram, add pointer to
; header to pci_dev_ptr_array
; ======================================================================== ;
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
	stosd
	stosd

	.loop:
		call 	pci_config_inw
		cmp 	ax, 0xFFFF
		je 	.get_next_slot

		; print device ID
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
		mov 	di, si
		call 	free
		popa
		mov 	sp, bp
		pop 	bp
		ret
	.error:
		mov 	si, __pci_msg_no_memory
		call 	serial_print
		jmp 	.done

; ======================================================================== ;
__pci_msg_no_memory:
	db "PCI INIT FAILED, NOT ENOUGH MEMORY", 0x0A, 0x0D, 0
__pci_msg_found_dev_id:
	db "PCI DEVICE FOUND, VENDOR ID: ", 0

; ======================================================================== ;
%endif
