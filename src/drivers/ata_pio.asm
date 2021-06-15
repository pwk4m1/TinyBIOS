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
; ****************************************************************************
; This file provides needed functionality to read ATA disks in PIO mode.
; ATA specs followed here are defined in ATA-ATAPI standard 8.
;
; This code is aimed to be used by Firmware or bootloader code running in
; single-process / single-threaded mode on x86 processor architecture family.
; As PIO mode is _extremely_ cpu exhausting, this code should not be used in
; any other mode.
;
; The code is 16-bits, but it should be fairly simple to port for 32-bit
; environment.
;
; Important:
;	- All ATA devices do not follow spec, we have functions with
;	  ata_nostd prefix that handle dealing with those. 
;	  Be extremely careful with those, and don't use them without knowing
;	  exactly what are you doing.
;
;
; 

[ bits	16 ]

; ======================================================================== ;
; ata specific GPIO ports
; ======================================================================== ;
%define __ata_dr	0x170		; Data Register
%define __ata_erfr	0x171		; Error/Feature Register
%define __ata_scr	0x172		; Sector Count Register
%define __ata_snr	0x173		; Sector Number Register (LBA low)
%define __ata_clr	0x174		; Cylinder low / LMA mid
%define __ata_chr	0x175		; cylinder high / LMA high
%define __ata_dhr	0x176		; drive/head Register
%define __ata_srcr	0x177		; Status/Command Register

%define __ata_asdcr	0x3F6		; Alternate Status 
					; & Device Control Register
%define __ata_dar	0x3F7		; Drive Address Register

; ======================================================================== ;
; ata error bit definitions
; ======================================================================== ;
%define __ata_err_amnf	00000001b	; Address Mark Not Found
%define __ata_err_tkznf	00000010b	; Track Zero Not Fount
%define __ata_err_abrt	00000100b	; Command Aborted
%define __ata_err_mcr	00001000b	; Media Change Request
%define __ata_idnf	00010000b	; ID not found
%define __ata_mc	00100000b	; Media Changed
%define __ata_unc	01000000b	; Uncorrectable Data Error
%define __ata_bbd	10000000b	; Bad Block Detected

; ======================================================================== ;
; status register bit definitions
; ======================================================================== ;
%define __ata_stat_err	00000001b	; Error
%define __ata_stat_ic	00000110b	; Index & correced data, always 0
%define __ata_stat_rdy	00001000b	; Drive has data/is ready to recv
%define __ata_stat_omsr	00010000b	; Overlapped Mode Service Request
%define __ata_stat_dfe	00100000b	; Drive fault err (does not set err!)
%define __ata_stat_cde	01000000b	; Clear on error / drive spun down
%define __ata_stat_wait	10000000b	; Drive is preparing for send/recv

; ======================================================================== ;
; device control register bit definitions
; ======================================================================== ;
%define __ata_dcr_zero	00000001b	; Always zero
%define __ata_dcr_cli	00000010b	; Set to disable interrupts
%define __ata_dcr_rst	00000100b	; Set to do reset on bus
%define __ata_dcr_rsvd	01111000b	; Reserved
%define __ata_dcr_hob	10000000b	; Set this to read the High Order Byte
					; of the last LBA48 value sent.

; ======================================================================== ;
; drive address register bit definitions
; ======================================================================== ;
%define __ata_dar_ds0	00000001b	; Drive Select 0
%define __ata_dar_ds1	00000010b	; Drive Select 1
%define __ata_dar_csh	00111100b	; Currently Selected Head
					;   as compliment of one.
%define __ata_dar_wg	01000000b	; Write Gate (0 when write active)
%define __ata_dar_rsvd	10000000b	; Reserved

; ======================================================================== ;
; Helper functions for driver. Implement cache flushesh, delays etc..
; I do suggest you read the comments before making _any_ changes at all, or
; use the functions below.
;
; Notes:
;	- we do not support detecting controller IO ports, they should be
;	    according to specs. If not, enumerate PCI bus to find disks.
;
; ======================================================================== ;

; ======================================================================== ;
;
; ATA spec suggests to check bits 7 and 3 of status register before sending
; command. However, as _everything_ is slow 'n all, we're basicly having to
; poll the pin 5 times (aka have 400ns delay.). With the delay, there's enough
; time for drive to push the correct voltages onto the bus.
;
; Requires:
;	dx = GPI/O port to poll (the status register. IO base + 7)
; Returns:
;	al = status register value
; ======================================================================== ;
ata_delay_in:
	in 	al, dx
	in 	al, dx
	in 	al, dx
	in 	al, dx
	in 	al, dx
	ret

; ======================================================================== ;
;
; Do manual cache flush - as some drives require.
; In case the drive does not do this, temporary bad sectors may be created,
; or the subsequent writes might fail invisibly. Be careful with this one!
;
; Requires:
;	dx = Command register.
; Returns:
;	Carry flag set on drive timeout.
;
; ======================================================================== ;
ata_cache_flush:
	push	ax
	push	cx
	clc
	mov	al, 0xE7
	out	dx, al
	
	mov	cx, 50			; We wait up to 5000ns.
	.wait_for_clear:
		in	al, dx
		test	al, __ata_stat_wait
		jz	.done
		loop	.wait_for_clear

	.fail:
		stc
	.done:
		pop	cx
		pop	dx
		ret

; ======================================================================== ;
;
; Do software reset for ATA device.
;
; Requires:
;	dx = device to reset (gpio port)
;
; ======================================================================== ;
ata_sw_reset:
	push	ax
	in	al, dx
	or	al, 00000100b
	out	dx, al
	nop
	nop
	and	al, 11111011b
	out	dx, al
	pop	ax
	ret

; ======================================================================== ;
;
; Check for 'floating bus'. Assuming we got booted from ATA disk, then
; the disk BIOS used to load us from should be selected. However, if this
; driver is either part of BIOS or similar firmware, or if we were booted
; from eg. USB media w/o having any ATA disks attached, then it's not very
; surprising to have disk to float.
;
; We can use Status register as a way to check this, as status register
; bits 1 and 2 should always be zero. If bus floats, and we only read
; 5 volts in (0xFF), then bits 1 and 2 are 1.
;
; Requires:
;	dx = port to bus to check (status register)
; Returns:
;	Carry flag set if bus floats.
; ======================================================================== ;
ata_check_fbus:
	push	ax
	add	dx, 7
	in	al, dx
	sub	dx, 7
	cmp	al, 0xFF
	pop	ax
	je	.bus_floats
	clc
	ret
	.bus_floats:
		stc
		ret

; ======================================================================== ;
;
; Non standard ways of detecting ATA drives. Avoid using these if possible.
; Both have been tested and seem to work with Qemu, but no experiments have
; been conducted with real hardware with these non-standard functions.
;
; ======================================================================== ;

; ======================================================================== ;
;
; Detect drive existense by selecting it, and checking if bit 7 of status
; register gets set. If it does, then we have a drive.
;
; Non standard way of doing things, please avoid :)
; This function wont work for detecting ATAPI devices, as they have bit 7
; clear until first packet command is sent to them. 
;
; Requires:
;	dx = IO base for device
;	ah = disk number (0/1)
; Returns:
;	al = 1 if drive exists, 0 if not.
;
; ======================================================================== ;
ata_nonstd_detect_disk_by_select:
	push	bp
	mov	bp, sp

	add	dx, 6
	in	al, dx
	shl	ah, 4
	xor	al, ah		; use XOR to toggle drive bit.
	shr	ah, 4		; restore value of ah.
	out	dx, al
	inc	dx
	
	call	ata_delay_in
	test	al, __ata_stat_cde
	jz	.no_drive
	mov	al, 1

	.ret:
		mov	sp, bp
		pop	bp
		ret
	.no_drive:
		xor	al, al
		jmp	.ret

; ======================================================================== ;
;
; Detect drive existense by running Device Diagnostics command, and checking
; error register. Allegedly DD command on existing device sets bits in the
; register, but I'm not 100% sure on this one.
;
; As above, do try to avoid using this function, and resort to this if
; nothing else works.
;
; Requires:
;	dx = IO base for device
; Returns:
;	al = 0 if no devices detected, or non-zero (error-register value)
;	     if device replies.
;
; ======================================================================== ;
ata_nonstd_detect_disk_by_dd:
	add	dx, 7
	mov	al, 0x90
	out	dx, al
	sub 	dx, 6
	in	al, dx
	dec 	dx
	cmp 	al, 0xFF
	jne 	.no_disk
	ret
.no_disk:
	xor 	al, al
	ret
	
; ======================================================================== ;
; End of non-std detection functionality.
; ======================================================================== ;


; ======================================================================== ;
;
; Detect ATA disk with help of Identify command. This is apparently de-facto
; way of detecting disks by modern firmware.
;
; Requires:
;	dx = port to 'IO base' for device.
;	al = primary/secondary (0xA0/0xB0)
; Returns:
;	al = 0 if disk not detected or
;	     1 if disk is detected, but it's not ATA
;	     2 if ATA disk is detected.
;	     3 if disk is SATA
;	     4 if disk is ATAPI
;
;	Sets carry flag on disk timeout.
;
; ======================================================================== ;
ata_detect_disk_by_identify:
	push	cx

	; select drive
	add	dx, 6
	out	dx, al
	
	; set Sector count, LBA values to 0.
	mov	cx, 4
	xor	al, al
	.loop_set_sc_lba:
		dec	dx
		out	dx, al
		loop	.loop_set_sc_lba

	; point dx to command port (base+7)
	add	dx, 5

	; send IDENTIFY command.
	mov	al, 0xEC
	out	dx, al
	in	al, dx

	; if status = 0, disk does not exist.
	test	al, al
	jz	.no_disk

	; if Error in Status Register, it's SATA or ATAPI device.
	test	al, __ata_stat_err
	jnz	.s_ata_pi_disk

	; keep polling until bit 7 is set or timeout of
	; 0.5 second (5000ns) is reached
	mov	cx, 5000
	.poll_wait:
		in	al, dx
		test	al, __ata_stat_wait
		jz	.poll_wait_done
		loop	.poll_wait

	.disk_timeout:
		stc
		xor	al, al
		jmp	.ret

	.no_disk:
		xor	ax, ax
		jmp	.ret

	; sata or atapi disk detected
	.s_ata_pi_disk:

		; check if it's ATAPI or SATA
		sub	dx, 3
		in	al, dx
		mov	ah, al
		inc	dx
		in	al, dx

		cmp	ax, 0x3c3c
		je	.sata_disk

		cmp	ax, 0x14EB
		je	.atapi_disk

	.non_ata_disk:
		; unknown disk :(
		mov	al, 1
		jmp	.ret

	.sata_disk:
		mov	al, 3
		jmp	.ret

	.atapi_disk:
		mov	al, 4
		jmp	.ret

	.poll_wait_done:
		;
		; Then, read LBA low & - mid values, if they're non-zero,
		; this is not ATA disk.
		;
		sub	dx, 4
		in	al, dx
		test	al, al
		jnz	.non_ata_disk
		inc	dx
		in	al, dx
		test	al, al
		jnz	.non_ata_disk

	add	dx, 3 		; point dx back to status port
	mov	cx, 5000
	.poll_rdy:
		in	al, dx
		test	al, __ata_stat_rdy
		jnz	.poll_rdy_done
		test	al, __ata_stat_err
		jnz	.poll_rdy_done
		loop	.poll_rdy

	jmp	.disk_timeout

	.poll_rdy_done:
		mov	al, 2

	.ret:
		pop	cx
		ret

; ======================================================================== ;
; 
; Check if given ATA disk exists, update disk count, and show
; user info about found disk
;
; Requires:
; 	dx = port IO base
; Returns:
;	clc set on bus float, or else
; 	none, updates ata_disk_addr_list values
;
; ======================================================================== ;
ata_check_disk_by_base:
	pusha
	push 	dx
	clc

	mov	si, ata_msg_checking_disk_dev
	call	serial_print
	mov	ax, dx
	call	serial_printh

	; check for floating bus
	call	ata_check_fbus
	jc	.ata_bus_float

	; try to identify disk
	mov	al, 0xA0
	call	ata_detect_disk_by_identify

	; if identification timed out, return
	jc	.disk_timeout

	; al = 0 : no disk
	; al = 1 : invalid disk
	; al >= 2 : disk is valid

	cmp	al, 0
	je	.ata_disk_not_found
	cmp	al, 2
	jge	.ata_disk_found
	mov	si, ata_msg_disk_invalid
	call	serial_print

	.done:
		pop 	dx
		popa
		ret

	.disk_timeout:
		mov	si, ata_msg_disk_timeout
		call	serial_print
		jmp	.done

	.ata_bus_float:
		mov	si, ata_msg_bus_floats
		call	serial_print
		stc
		jmp	.done

	.ata_disk_not_found: 
		jmp	.done

	.ata_disk_found:
		mov	si, ata_msg_disk_found
		call	serial_print
		mov	di, ata_disk_addr_list
		cmp 	word [di], 0
		je 	.do_store

	.get_free_slot:
		add 	di, 2
		cmp 	word [di], 0
		je 	.do_store
		sub 	di, ata_disk_addr_list
		cmp 	si, 8
		jl 	.disk_add_failed
		add 	di, ata_disk_addr_list
		jmp 	.get_free_slot

	; actual storage process after finding slot
	.do_store:
		pop 	dx
		push 	dx
		mov	word [di], dx
		jmp	.done
	
	.disk_add_failed:
		mov 	si, ata_msg_disk_add_err
		call 	serial_print
		jmp 	.done

; ======================================================================== ;
;
; Helper function to poll ata disk
;
; sets carry flag on disk timeout
;
; ======================================================================== ;
ata_poll:
	pusha
	mov	cl, 15
	clc
	.loop:
		call	ata_delay_in
		test	al, __ata_stat_wait
		jz	.done
		loop	.loop
	; disk timed out
	stc
	.done:
		popa
		ret

; ======================================================================== ;
;
; Following function may be used to read disk info, assuming
; that valid ATA disk has been found.
;
; Requires:
;       di = pointer to 512 bytes large buffer to read disk info into.
;       dx = disk io base
; Returns:
;       carry flag set on error
;
; ======================================================================== ;
ata_disk_read_info:
        push    cx
        mov     cx, 256
        .loop:
                in      ax, dx
                mov     word [di], ax
                add     di, 2
                loop    .loop
        pop     cx
        ret


; ======================================================================== ;
;
; Read data from ATA disk in 28 bit PIO mode.
; This function should not be called directly, use
; ata_disk_read () instead.
;
; Requires:
;	al	= 0xE0 for 'primary' or 0xF0 for 'secondary' device.
;	di 	= pointer to buffer to read data into
;	dx 	= device 'io base' port
;	cl 	= sector count
;	bx	= pointer to LBA 
; Returns:
;	Carry flag set on error
;
; ======================================================================== ;
ata_pio_b28_read:
	pusha

	push	ax
	; set sector count
	mov	al, cl

	; dx = BASE + 2
	add	dx, 2
	out	dx, al

	; send lba low
	; dx = BASE + 3
	inc	dx
	mov	al, byte [bx]
	out	dx, al

	inc	bx
	mov	al, byte [bx]

	; send lba mid
	; bx = BASE + 4
	inc	dx
	out	dx, al

	; bits 16 to 23 of LBA
	; dx = BASE + 5 
	inc	bx
	mov	al, byte [bx]
	inc	dx
	out	dx, al

	; bits 24 to28 OR'ed with primary/secondary flag
	; dx = BASE + 6
	pop	ax
	inc	bx
	mov	ah, byte [bx]
	or	ah, al
	mov	al, ah
	inc	dx
	out	dx, al

	; send READ command
	; dx = BASE + 7
	inc	dx
	mov	al, 0x20
	out	dx, al

	; read status
	call	ata_poll
	jc 	.disk_error

	.read_start:
		push	cx
		mov	cx, 256

		; point dx to BASE
		sub	dl, 7

		; read 256 words (1 sector)
		.loop:
			in 	ax, dx
			mov 	word [di], ax
			add 	di, 2
			loop 	.loop

		pop	cx

		; read status
		add 	dl, 7
		in 	al, dx
		test 	al, __ata_stat_err
		jnz 	.disk_error

		dec	cx
		test	cx, cx
		jnz	.read_start
		clc

	.done:
		popa
		ret

	.disk_error:
		stc
		jmp 	.done

; ======================================================================== ;
; 
; Helper function to handle ATA PIO disk read
;
; Requires:
;	di: pointer to destination buffer
; 	dx: device io base
; 	cl: sector count
;	bx: pointer to LBA
; Returns:
;	Carry flag set on error
;
; ======================================================================== ;
ata_disk_read:
	pusha

	LOG 	ata_msg_reading_disk

	mov	ax, dx
	call	serial_printh

	; I use si to store amount of disk read retry attempts 
	; remaining, don't want to bother w/ push + pop for cx.
	mov 	si, 60

.check_disk_status:
	; check disk status
	in	al, dx
	test	al, __ata_stat_wait
	jnz	.disk_status_ok

	; do disk reset
	call	ata_sw_reset

	; re-check
	in 	al, dx
	test 	al, __ata_stat_wait
	jnz 	.disk_status_ok

	cmp 	al, 0xFF
	je 	.ata_float_bug

	mov  	si, ata_msg_bus_unknown_bug
	call 	serial_print
	stc
	jmp 	.do_ret 

	; disk passed sanity checks, do the actual disk read now. 
	.disk_status_ok:
		dec 	si 		; retries = retries - 1
		test 	si, si 		; if 0 left, indicate error
		jz 	.disk_read_failed
		mov	al, 0xE0
		call	ata_pio_b28_read

		; if carry flag is set, we encountered error.
		; try fixing it by nuking it away with disk reset,
		; this is not the _correct_ way to do things but it'll
		; do for now (meaning it'll be here forever, I'd expect...)
		jc 	.read_errored
		clc

	.do_ret:
		popa
		ret
	
	.ata_float_bug:
		mov 	si, ata_msg_bus_float_bug
		call 	serial_print
		stc
		jmp 	.do_ret

	.disk_read_failed:
		;mov 	si, ata_msg_disk_read_failed
		;call 	serial_print
		stc
		jmp 	.do_ret

	.read_errored:
		call 	ata_sw_reset
		jmp 	.check_disk_status

; ======================================================================== ;
; Function to use for ata disk detection
; Does not require, nor return anything.
;
; updates ata_disk_addr_list values
;
; ======================================================================== ;
ata_check_disks:
	pusha
        ; get disk info, if bus floats, move to next one / end detection
        mov     dx, 0x1f0
        call    ata_check_disk_by_base
        jc      .ata_bus1_done

        mov     dx, 0x170
        call    ata_check_disk_by_base
        jc      .ata_bus1_done

.ata_bus1_done:
        mov     dx, 0x1e8
        call    ata_check_disk_by_base
        jc      .ata_bus2_done

        mov     dx, 0x168
        call    ata_check_disk_by_base
        jc      .ata_bus2_done

.ata_bus2_done:
	popa
	ret


; ======================================================================== ;
; Get ata disk count 
;
; returns amount of disks detected in CL
; ======================================================================== ;
ata_disk_count:
	push 	si
	push 	ax

	mov 	si, ata_disk_addr_list
	xor 	cx, cx
	.loop:
		lodsw
		test 	ax, ax
		jz 	.done
		inc 	cl
		jmp 	.loop

	.done:
		pop 	ax
		pop 	si
		ret


; ======================================================================== ;
; Messages related to ata bus
;
; ======================================================================== ;
ata_msg_bus_unknown_bug:
	db "ATA BUS UNKNOWN ERROR!", 0x0A, 0x0D, 0

ata_msg_bus_float_bug:
	db "ATA BUS FAIL, FLOAT AFTER RESET (CONSTANT +5V)!", 0x0A, 0x0D, 0

ata_msg_bus_floats:
	db "ATA BUS FLOATS, NO DISKS CONNECTED TO THIS BUS", 0x0A, 0x0D, 0

ata_msg_disk_timeout:
	db "ATA DISK IS NOT RESPONDING!", 0x0A, 0x0D, 0

ata_msg_disk_found:
	db "ATA DISK DETECTED.", 0x0A, 0x0D, 0

ata_msg_disk_invalid:
	db "ATA DISK DOES NOT FOLLOW SPECIFICATION, OR NOT REALLY ATA."
	db 0x0A, 0x0D, 0

ata_msg_disk_add_err:
	db "UNABLE TO ADD ATA DISK ADDR TO DISK ADDR LIST (BUG)."
	db 0x0A, 0x0D, 0

ata_msg_checking_disk_dev:
	db "CHECKING FOR ATA DISK AT: 0x", 0

ata_msg_reading_disk:
	db "ATTEMPTING ATA DISK READ. DEV: 0x", 0

ata_msg_disk_read_failed:
	db "DISK READ FAILED!", 0x0A, 0x0D, 0
