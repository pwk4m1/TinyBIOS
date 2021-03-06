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
	LOG 	msg_extended_detect_check
	popad
	xor 	ax, ax
	xchg 	bh, bl
	mov 	cx, 1

	DEBUG_LOG 	ata_msg_int_done
	iret

msg_extended_detect_check:
	db "RESPONDING TO INT #13H AH=41H", 0x0A, 0x0D, 0

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
; Handler for hard disk related services. We only support disk reset
; and disk read, carry flag is set on error
;
; dl = disk to use
;
msg_serving_disk_int:
	db "HANDLING INT #13H", 0x0A, 0x0D, 0

ata_msg_int_done:
	db "DONE HANDLING INT #13H", 0x0A, 0x0D, 0

msg_disk_oper:
	db "DISK OPERATION: ", 0

disk_service_int_handler:

	LOG 	msg_serving_disk_int

	pushad
	clc

	DEBUG_LOG 	msg_disk_oper
	; DEBUG_call 	serial_printh

	test 	ah, ah 			; ah = 0 => disk reset
	jz 	disk_service_reset
	cmp 	ah, 2
	jl 	disk_service_get_status ; ah = 1 => disk get status
	je 	disk_service_read 	; ah = 2 => read sectors from drive

;	cmp 	ah, 8 			; ah = 8 => read drive params

	cmp 	bx, 0x55aa
	je 	disk_service_extended_detect
	cmp 	ah, 0x42
	je 	disk_service_extended_read

	; I could support disk writes etc. but I rather (for now) just
	; do read 1 sector at time, get status & reset disk, that's _all_
	;
	stc
	mov 	al, 0x01
	call 	__set_int_disk_drive_last_status
.done:
	mov 	word [.retstatus], ax
	popad
	mov 	ax, word [.retstatus]
	cmp 	word [esp], 0
	je 	.panic_invalid_retptr
	clc

	DEBUG_LOG 	ata_msg_int_done
	iret

.retstatus:
	dw 	0

.panic_invalid_retptr:
	mov 	si, msg_invalid_retptr
	call 	serial_print
	cli
	hlt
	jmp 	$ - 2

msg_invalid_retptr:
	db "INT #13H: INVALID RETURN POINTER (0000H)", 0x0A, 0x0D, 0

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
	cli
	hlt
	jmp 	disk_service_get_status

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
msg_call_ata_disk_read:
	db "CALLING ATA_DISK_READ", 0x0A, 0x0D, 0

disk_service_read:
	push 	ax
	push 	bx
	push 	cx
	push 	di
	push 	si
	
	push 	dx
	call 	__get_disk_base_to_dx
	; set di = pointer to 
	mov 	di, bx

	; set LBA to stack
	push 	0x0000 	; bits 	32 - 16
	push 	cx 	; bits 	16 - 0
	mov 	bx, sp

	; read sectors from disk, error management is done after
	; we've cleaned up stack & restored registers
	;
	DEBUG_LOG 	msg_call_ata_disk_read
	call 	ata_disk_read
	DEBUG_LOG 	msg_done

	; clean up stack
	pop 	cx
	pop 	cx
	
	; restore registers
	pop 	si
	pop 	di
	pop 	cx
	pop 	bx
	pop 	ax

	; now do error management for ata_disk_read 
	jc 	.error_disk_read_failed
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
	pop 	dx
	jmp 	disk_service_int_handler.done

msg_LBA_debug:
	db "LBA: ", 0

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

