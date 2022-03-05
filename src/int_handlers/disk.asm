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
bits 	16

; ======================================================================== ;
; Set ivt entry for disk interface
;
set_disk_ivt_entry:
	pusha
	mov 	eax, disk_service_int_handler
	and 	eax, 0x0000ffff
	mov 	bx, cs
	mov 	di, (0x13 * 4)
	call 	set_ivt_entry
	popa
	ret

; ======================================================================== ;
; __get_disk_base_to_dx is used to get disk port i/o base by 
; dl (device id)
;
__get_disk_base_to_dx:
	cmp 	dl, 0x80
	jne 	.not_supported
	mov 	dx, 0x01f0
	ret
.not_supported:
	mov 	dx, 0
	ret

; ======================================================================== ;
; Helper function to handle parsing of the Disk Address Packet (DAP) 
;
; Requires: ds:si = DAP ptr
; Returns:
; 	
;	di: pointer to destination buffer
; 	dx: device io base
; 	cl: sector count
;	bx: pointer to LBA
;
; ======================================================================== ;
__parse_DAP:
	push 	ax

	xor 	cx, cx

	; move to rightmost byte of sector count
	add 	si, 3
	mov 	cl, byte [si]

	; get segment:offset to destination
	inc 	si
	mov 	es, word [si]
	add 	si, 2
	mov 	di, word [si]

	; Lba pointer
	add 	si, 2
	mov 	bx, si

	pop 	ax
	ret

; ======================================================================== ;
; Function to respond to extended disk read check.
;
; ======================================================================== ;
disk_service_extended_detect:
	DEBUG_LOG 	msg_extended_detect_check
	xor 	ax, ax
	xchg 	bh, bl
	mov 	cx, 1
	jmp 	disk_service_int_handler.done

; ======================================================================== ;
; we don't atm support extended disk read (NAAH WE DO NOW!)
;
; Requirements for extended disk read:
;	ah = 42h
;	dl = drive index
;	ds:si = DAP ptr
;
; return is handled by jump to disk_service_int_handler.done
; ======================================================================== ;
disk_service_extended_read:
	call 	__parse_DAP
	cmp 	cl, 0
	jne 	disk_service_read
	jmp 	disk_service_int_handler.done

; ======================================================================== ;
; Handle disk read parameters call, int 13h ah=8
;
; we'll get:
;	ah = 8
; 	dl = drive index
;	es:di = 0, probably
; return:
;	cf = set on error, clear on success
;	ah = return code
;	dl = number of disks
; 	dh = logical last index of heads, starts from 0
; 	cx = [7:6][15:8] logical last index of cylinders
; 	     [5:0] = logical last index of sectors per track
; 	bl = drive type for AT or PS2 floppies
;	es:di = pointer to drive param table for floppies
;
disk_service_read_parameters:
	call 	__get_disk_base_to_dx
	cmp 	dx, 0x1f0
	jne 	.not_supported

	; todo: make dynamic
	clc
	mov 	ah, 0
	mov 	dl, 1
	mov 	dh, 1
	mov 	cx, 0xff3f
	mov 	bl, 0
	mov 	di, 0

	jmp 	disk_service_int_handler.done

.not_supported:
	stc
	jmp 	disk_service_int_handler.done

; ======================================================================== ;
; Handler for hard disk related services. We only support disk reset
; and disk read, carry flag is set on error
;
; dl = disk to use
;
disk_service_int_handler:

	LOG 	msg_serving_disk_int
	pop 	word [INT_HANDLER_RET_PTR]
	push 	word [INT_HANDLER_RET_PTR]

	pushad
	clc

	DEBUG_LOG 	msg_disk_oper
	DEBUG_call 	serial_printh

	test 	ah, ah 			; ah = 0 => disk reset
	jz 	disk_service_reset
	cmp 	ah, 2
	jl 	disk_service_get_status ; ah = 1 => disk get status
	je 	disk_service_read 	; ah = 2 => read sectors from drive

	cmp 	ah, 8 			; ah = 8 => read drive params
	je 	disk_service_read_parameters

	cmp 	bx, 0x55aa
	je 	disk_service_extended_detect
	cmp 	ah, 0x41
	je 	disk_service_extended_detect
	cmp 	ah, 0x42
	je 	disk_service_extended_read

	; I could support disk writes etc. but I rather (for now) just
	; do read 1 sector at time, get status & reset disk, that's _all_
	;
	stc
	mov 	al, 0x01
	call 	__set_int_disk_drive_last_status

	; unified "DONE" part for functions to restore stack, check
	; address to return to is still correct, etc.
	;
.done:
	mov 	word [.retstatus], ax
	popad
	mov 	ax, word [.retstatus]
	cmp 	word [esp], 0
	je 	.panic_invalid_retptr
	clc

	DEBUG_LOG 	ata_msg_int_done
	DEBUG_LOG 	ata_msg_ret_to
	pop 	ax
	push 	ax
	DEBUG_call 	serial_printh
	cmp 	ax, word [INT_HANDLER_RET_PTR]
	jne 	.panic_invalid_retptr
	iret

.retstatus:
	dw 	0

.panic_invalid_retptr:
	mov 	si, msg_invalid_retptr
	call 	serial_print
	cli
	hlt
	jmp 	$ - 2


; ======================================================================== ;
; Do disk reset, that's fairly simple, we only need dx = I/O base
;
disk_service_reset:
	call 	__get_disk_base_to_dx
	test 	dx, dx
	jz 	disk_service_int_handler.done
	call 	ata_sw_reset
	jmp 	disk_service_int_handler.done

; ======================================================================== ;
; Get status of Last Drive Operation (13h, ah = 01)
; Requires:
; 	dl = drive
; Returns:
; 	cf set on error
;
; 	ah:
;		00 - success
; 		01 - invalid cmd
; 		02 - can't find addr mark
; 		03 - attempted write on write protected disk
;	 	04 - sector not found
; 		05 - reset failed
; 		06 - disk changed line active
; 		07 - drive param activity failed
; 		08 - DMA overrun
; 		09 - attempt to DMA over 64k bound
; 		0A - bad sector
; 		0B - bad track/cylinder
; 		0C - media type not found 
; 		0D - invalid number of sectors
; 		0E - Control data addr mark detected
; 		0F - DMA out of range
; 		10 - CRC/ECC data error
;		11 - ECC corrected data error
; 		20 - controller failure
; 		40 - seek failure
; 		80 - drive timed out, assumed not rdy
; 		AA - drive not ready
; 		BB - undefined error
; 		CC - write fault
; 		E0 - status error
; 		FF - sense operation failed
;
disk_service_get_status:
	; we read ATA Disk status register based on dx, and
	; if no errors report back, we also check DISK_DRIVE_LAST_STATUS
	; if both are 0, return ok
	; if disk reported error, update DISK_DRIVE_LAST_STATUS and return
	; if disk reported ok, but DISK_DRIVE_LAST_STATUS is not ok,
	; return DISK_DRIVE_LAST_STATUS
	;
	cmp 	dl, 0x80
	je 	.fetch_stat
	mov 	al, 0xE0
	ret
.fetch_stat:
	mov 	al, byte [DISK_DRIVE_LAST_STATUS]
	ret

; ======================================================================== ;
; Helper to calculate LBA from CHS.
; Requires:
; 	- CH 	= Cylinder
; 	- DH 	= Head
; 	- CL 	= Sector
; 	- BX 	= disk to read from
; sets LBA to DISK_INT_HANDLER_LBAPTR
;
; For now, assume 16 heads, 64 sectors. TODO: Find these from
; ata disk info.
;
calculate_lba_from_chs:
	; LBA = (C * HPC + H) * SPT + (S - 1)
	;
	push 	ax
	push 	bx

	; disk info is at 0x80100 now

	; ax = C * HPC + H
	xor 	ax, ax
	mov 	al, 16
	mul 	ch
	add 	al, dh

	mov 	bx, ax
	push 	dx
	mov 	ax, 63
	mul 	bx
	dec 	cl
	add 	al, cl

	mov 	word [INTHANDLER_LBAPTR], ax
	mov 	ax, dx
	mov 	word [INTHANDLER_LBAPTR+2], ax

	pop 	dx
	pop 	bx
	pop 	ax
	ret

INTHANDLER_LBAPTR:
	dw 	0
	dw 	0

; ======================================================================== ;
; Disk read is bit more difficult, we need lots of stuff from user,
; this is done in C/H/S mode. 
;
; Requires:
; 	- AH 	= 2
; 	- AL 	= Sector count
; 	- ES:BX = Destination pointer
; 	- CL 	= Sector
; 	- CH 	= Cylinder
; 	- DH 	= Head
; 	- DL 	= Drive	
;
; Returns:
; 	- CF 	= set on error
; 	- AH 	= return code
; 	- AL  	= Actual Sectors Read Count
;
;
; This is bit problematic, as this call uses C/H/S mode, but 
; my disk driver uses LBA... 
; Driver requires:
;	di: pointer to destination buffer
; 	dx: device io base
; 	cl: sector count
;	bx: pointer to LBA
;

disk_service_read:
	push 	ax
	push 	bx
	push 	cx
	push 	di
	push 	si
	push 	dx
	
	; Set CHS->LBA as driver needs
	call 	calculate_lba_from_chs

	; Sets destination for disk read
	mov 	di, bx

	; backup ax
	mov 	bx, ax

	; backup BDA 400h - 404h
	push 	word [0x400]
	push 	word [0x402]

	; set 400h = LBA 
	mov 	ax, word [INTHANDLER_LBAPTR]
	mov 	word [0x400], ax
	mov 	ax, word [INTHANDLER_LBAPTR+2]
	mov 	word [0x402], ax
	mov 	ax, bx

	; Get device "id" -> actual disk
	call 	__get_disk_base_to_dx

	; read sectors from disk, error management is done after
	; we've cleaned up stack & restored registers
	;
	DEBUG_LOG 	msg_call_ata_disk_read
	; set bx to point to LBA
	mov 	bx, 0x400

	; set sector count for disk read
	mov 	cl, al

	call 	ata_disk_read

	; restore BDA
	pop 	word [0x402]
	pop 	word [0x400]

	jc 	.error_disk_read_failed
	DEBUG_LOG 	msg_done

.cleanup:
	; restore registers
	pop 	si
	pop 	di
	pop 	cx
	pop 	bx
	pop 	ax
	pop 	dx

	; if no errors encountered, return ok
	xor 	ax, ax

	; set DISK_DRIVE_LAST_STATUS
	; call 	__set_int_disk_drive_last_status

	inc 	al ; set return code
	xor 	ah, ah
	jmp 	disk_service_int_handler.done

.error_invalid_options:
	push 	ax
	mov 	al, 0x0C
	call 	__set_int_disk_drive_last_status
	pop 	ax
	pop 	dx
	stc
	jmp 	disk_service_int_handler.done

.error_disk_read_failed:
	mov 	al, 0x07
	call 	__set_int_disk_drive_last_status
	xor 	ax, ax
	stc
	DEBUG_LOG 	msg_ata_disk_read_fail
	jmp 	disk_service_read.cleanup

; ======================================================================== ;
; Helper for setting status of disk operation
; requires:
;	al = status code
; ======================================================================== ;
__set_int_disk_drive_last_status:
	push 	esi
	mov 	esi, DISK_DRIVE_LAST_STATUS
	stosb
	pop 	esi
	ret


; All the messages are here
;
msg_call_ata_disk_read:
	db "CALLING ATA_DISK_READ", 0x0A, 0x0D, 0

msg_ata_disk_read_fail:
	db "DISK READ FAILED ON INT #13H", 0x0A, 0x0D, 0

msg_LBA_debug:
	db "LBA: ", 0

msg_extended_detect_check:
	db "RESPONDING TO INT #13H AH=41H", 0x0A, 0x0D, 0

ata_msg_ret_to:
	db "RET AFTER INT #13H TO: ", 0

msg_serving_disk_int:
	db "HANDLING INT #13H", 0x0A, 0x0D, 0

ata_msg_int_done:
	db "DONE HANDLING INT #13H", 0x0A, 0x0D, 0

msg_disk_oper:
	db "DISK OPERATION: ", 0

msg_invalid_retptr:
	db "INT #13H: CORRUPTED RETURN POINTER!", 0x0A, 0x0D, 0
