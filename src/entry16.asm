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

; ======================================================================== ;
; This is the first entry point of our BIOS code after reset vector.
; Offset from ROM beginning is 0x10000.
;
; ======================================================================== ;
bits	16

%define VER_NUM "0.2"

main:
	; save BIST result
	mov	ebp, eax

	; disable TLB
	xor	eax, eax
	mov	cr3, eax

	; first things first, let's initialize super-I/O
	mov	dx, 0x3f8
	xor	al, al
	out	dx, al
	out	dx, al

	; The init above is ridiculous, I know.. But that's how it's done
	; on Qemu :)
	;
	; Regarding Qemu by the way.. RAM has been initialized for us,
	; which is kind of nice. So is most of hardware.
	;

	; Just in case, check RAM & Stack
	call	check_ram_stack
	cmp	al, 0
	jne	.hang

	xor 	ax, ax
	mov 	ss, ax
	mov	sp, 0x7c00
	mov	bp, sp

	; Show a simple bootsplash over serial port
	mov	esi, msg_boot_early
	call	serial_print

	; let's test malloc
	call 	mm_heap_init

	call 	pci_init
	call 	pci_ide_test

.ata_start:

	; check for ATA disks
	call 	ata_check_disks

	; read disk info
	mov	dx, 0x1f0
	mov	di, 0x2000
	call	ata_disk_read_info

	mov	dx, 0x1f0
	mov	di, 0x3000
	mov	cl, 1
	mov	bx, LBAPTR
	call	ata_disk_read
	jc	.disk_read_fail

	mov	si, 0x3000
	call	sector_is_multiboot
	cmp	ax, 1
	jne	.not_boot_sector

	mov	si, msg_bootsector_found
	call	serial_print

	mov	si, 0x3000
	call	bootsector_to_ram

	mov	si, msg_jump_to_loader
	call	serial_print

	jmp	0x0000:0x7c00

.hang:
	cli
	hlt

.disk_read_fail:
	mov	si, msg_disk_read_failed
	call	serial_print
	mov	ax, dx
	call	serial_printh
	jmp	.hang

.not_boot_sector:
	mov	si, msg_not_boot_sector
	call	serial_print
	mov	ax, word [0x3000+510]
	call	serial_printh
	jmp	.hang

LBAPTR:
	db	0	; bits 32 - 24 
	db	0	; bits 24 - 16
	db	0	; bits 16 - 8
	db	0x01	; bits 8 - 0 

msg_boot_early:
	db 0x0A, 0x0D, "TinyBIOS "
	db VER_NUM
	db " (C) 2019 k4m1,  <k4m1@protonmail.com>" 
	db 0x0A, 0x0D
	db "RAM READ/WRITE OK"
	db 0x0A, 0x0D, 0

msg_not_boot_sector:
	db "ATA DISK HAS NO BOOTLOADER, EXPECTED 55AA, GOT: ", 0
msg_disk_read_failed:
	db "FAILED TO READ DISK 0x", 0

msg_bootsector_found:
	db "FOUND BOOT SECTOR SIGNATURE (55AA) FROM DISK", 0x0A, 0x0D, 0

msg_jump_to_loader:
	db "JUMP TO 0x0000:0x7C00", 0x0A, 0x0D, 0

%include "src/drivers/ata_pio.asm"
%include "src/drivers/serial.asm"

%include "src/drivers/pci/pci_core.asm"
%include "src/drivers/pci/pci_helpers.asm"
%include "src/drivers/pci/pci_ide.asm"

%include "src/test_ram.asm"
%include "src/bootdisk.asm"
%include "src/mm.asm"

