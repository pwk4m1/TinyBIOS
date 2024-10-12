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

; later on, add ifdef <TARGET PLATFORM> or smhn like that.

%include "src/log.asm"
%include "src/fixed_pointers.asm"
%include "src/drivers/qemu/superio.asm"

; ======================================================================== ;
; This is the first entry point of our BIOS code after reset vector.
; Offset from ROM beginning is 0x10000.
;
; ======================================================================== ;
bits	16

%define VER_NUM "0.3"

main:
	cli
	cld

	; save BIST result
	mov	ebp, eax

	; disable TLB
	xor	eax, eax
	mov	cr3, eax

	; this macro is provided by drivers/dev/superio.asm
	SUPERIO_INIT_MACRO

	; this macro is provided by drivers/cpu/YOURCPU.asm
%ifdef USE_CAR
	INIT_CAR_IF_ENABLED
%endif

; ======================================================================== ;
; At this point, ram init is completed, we can go on with our boot process
;
; ======================================================================== ;
	xor 	ax, ax
	mov 	ss, ax
	mov	sp, 0x7c00

	push 	ebp 		; store ebp/BIST to stack

	mov	bp, sp

	; Show a simple bootsplash over serial port
	mov	si, msg_boot_early
	call	serial_print
	call 	mm_heap_init

	call 	cpuid_print_cpu_vendor

	call 	pit_init
	call 	kbdctl_init

	call 	pci_init
	call 	pci_ide_test
	call 	pci_find_vga_dev

.ata_start:
	; setup ATA disk addr list to 0's
	mov 	cx, 16
	mov 	di, ata_disk_addr_list
	xor 	ax, ax
	rep 	stosw

	; check for ATA disks
	call 	ata_check_disks
	mov 	si, ata_disk_addr_list

.find_boot_sector:
	lodsw
	test 	ax, ax
	jz 	.boot_failed_no_bootsector
	mov 	dx, ax

	; we read disk up to 10 times, as disk-read may randomly
	; return all 0's for reson or another...
	mov 	cx, 10
	.read_retry_loop:
		call 	find_boot_sector
		jnc 	.read_success
		loop 	.read_retry_loop
	jmp 	.find_boot_sector

.read_success:	

	mov 	si, TMP_BOOTSECTOR_ADDR
	call	bootsector_to_ram

	mov 	si, msg_bootsector_found
	call 	serial_print

	mov 	si, msg_init_interrupts
	call 	serial_print

; ======================================================================== ;
; We now have bootloader set up at 0x0000:0x7c00, do not overwrite it
; accidentally.
; 
; Now, to do:
;	- setup interrupt controller + clear all IVT entries
; 	- set device specific interrupt handlers
; ======================================================================== ;

.setup_runtime:
	; setup bios data area before int handlers
	call 	setup_bda

;	call 	vga_init

	call 	init_interrupts
	call 	set_serial_ivt_entry
	call 	set_disk_ivt_entry
	call 	set_pseudo_vga_ivt_entry
	call 	init_fault_interrupts

	; Final device init sequence here
	call 	ps2_kbd_init

	xor 	esi, esi
	mov	si, msg_jump_to_loader
	call	serial_print

	; set boot device to dl
	mov 	dl, 0x80
	jmp	0x0000:0x7c00

.hang:
	cli
	hlt
	jmp 	.hang

.boot_failed_no_bootsector:
	mov 	si, msg_no_bootsector
	call 	serial_print
	jmp 	.hang

LBAPTR:
	db 	1 	; bits 0 - 8
	db 	0 	; 8 - 16
	db 	0 	; ...
	db 	0

msg_no_bootsector:
	db "FAILED TO FIND BOOTABLE DISK!", 0x0A, 0x0D, 0

msg_boot_early:
	db 0x0A, 0x0D, "TinyBIOS "
	db VER_NUM
	db " (C) 2019 k4m1,  <k4m1@protonmail.com>" 
	db 0x0A, 0x0D
	db "RAM READ/WRITE OK"
	db 0x0A, 0x0D, 0

msg_not_boot_sector:
	db "ATA DISK HAS NO BOOTLOADER, EXPECTED AA55, GOT: ", 0
msg_disk_read_failed:
	db "FAILED TO READ DISK 0x", 0

msg_bootsector_found:
	db "FOUND BOOT SECTOR SIGNATURE (AA55) FROM DISK", 0x0A, 0x0D, 0

msg_init_interrupts:
	db "SETTING UP IVT & INTERRUPT HANDLERS", 0x0A, 0x0D, 0

msg_jump_to_loader:
	db "JUMP TO 0x0000:0x7C00", 0x0A, 0x0D, 0

; Driver includes
; 
;%include "src/drivers/vga/vga_core.asm"
;%include "src/drivers/vga/vga_init.asm"
%include "src/drivers/cpu/common_ia86.asm"
%include "src/drivers/pit/pit.asm"

%include "src/drivers/8042_ps2.asm"
%include "src/drivers/8259_pic.asm"
%include "src/drivers/ata_pio.asm"
%include "src/drivers/serial.asm"
%include "src/drivers/parallel.asm"

%include "src/drivers/pci/pci_core.asm"
%include "src/drivers/pci/pci_helpers.asm"
%include "src/drivers/pci/pci_ide.asm"
%include "src/drivers/pci/pci_vga.asm"

%include "src/drivers/ps2/ps2.asm"

; Random helper & such includes
;
%include "src/str.asm"
%include "src/test_ram.asm"
%include "src/bootdisk.asm"
%include "src/mm.asm"
%include "src/interrupts.asm"
%include "src/bda.asm"

; Interrupt handlers
%include "src/int_handlers/pit.asm"

; software triggered interrupt handlers
%include "src/int_handlers/swint/serial.asm"
%include "src/int_handlers/swint/vga_dummy.asm"
%include "src/int_handlers/swint/disk.asm"
%include "src/int_handlers/swint/faults.asm"

