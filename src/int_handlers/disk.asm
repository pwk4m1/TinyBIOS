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
	stc
	ret

; ======================================================================== ;
; Handler for hard disk related services. We only support disk reset
; and disk read, carry flag is set on error
;
; dl = disk to use
;
disk_service_int_handler:
	cli
	clc

	test 	ah, ah
	jz 	disk_service_reset
	cmp 	ah, 2
	; jl 	get_disk_status
	je 	disk_service_read
	stc
.done:
	iret

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
disk_service_read:
	push 	dx
	call 	__get_disk_base_to_dx
	test 	dx, dx
	jz 	.error

	push 	ax
	push 	bx
	push 	cx
	push 	di
	push 	si
	
	; set di = pointer to 
	mov 	di, bx

	; set LBA to stack
	push 	0x0000 	; bits 	32 - 16
	push 	cx 	; bits 	16 - 0
	mov 	bx, sp

	call 	ata_disk_read

	; clean up stack
	pop 	cx
	pop 	cx
	
	; restore registers
	pop 	si
	pop 	di
	pop 	cx
	pop 	bx
	pop 	ax
	pop 	dx
	xor 	ax, ax
	mov 	al, 1
	jmp 	disk_service_int_handler.done
.error:
	pop 	dx
	stc
	jmp 	disk_service_int_handler.done

