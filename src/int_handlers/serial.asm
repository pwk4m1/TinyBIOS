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
; Set ivt entry for serial interface
;
set_serial_ivt_entry:
	pusha
	mov 	eax, serial_service_int_handler
	and 	eax, 0x0000ffff
	mov 	bx, cs
	mov 	di, (0x14 * 4)
	call 	set_ivt_entry
	popa
	ret

; ======================================================================== ;
; Handler for serial port related services
;
serial_service_int_handler:
	cli
	cmp 	ah, 1
	jl 	serial_service_init_device
	je 	serial_service_putchar

	cmp 	ah, 3
	jl 	serial_service_getchar
	je 	serial_service_get_status

.done:
	; We get here by software interrupt by CPU, not by 
	; PIC generated int, so don't send EOI !
	iret

; ======================================================================== ;
; Helper function to get port to use based on DX value 0 - 3 (device 
; number)
;
__get_serial_by_id:

	cmp 	dx, 1
	jl 	.port1
	je 	.port2
	cmp 	dx, 3
	je 	.port3
	mov 	dx, 0x02e8
	ret
.port1:
	mov 	dx, 0x03f8
	ret
.port2:
	mov 	dx, 0x02f8
	ret
.port3:
	mov 	dx, 0x03e8
	ret

; ======================================================================== ;
; Serial port init service (AH = 00)
; This function should only be called by serial_service_handler
;
;	AH = 00
;	AL = parms for initialization (see tables below)
;	DX = zero based serial port number (0-1) (0-3 for AT)
;
;	|7|6|5|4|3|2|1|0|  AL   Parity (bits 4 & 3)
;	 | | | | | | `------ word length bits       00 = none
;	 | | | | | `------- stop bits flag       01 = odd
;	 | | | `---------- parity bits       10 = none
;	 `--------------- baud rate bits       11 = even
;
;	Word length (bits 1 & 0)	    Stop bit count (bit 2)
;
;	   10 = 7 bits      0 = 1 stop bit
;	   11 = 8 bits      1 = 2 stop bits
;
;	Baud rate (bits 7, 6 & 5)
;
;	000 = 110 baud    100 = 1200 baud
;	001 = 150 baud    101 = 2400 baud
;	010 = 300 baud    110 = 4800 baud
;	011 = 600 baud    111 = 9600 baud (4800 on PCjr)
;
;
;	on return:
;	AH = port status
;	AL = modem status
;
serial_service_init_device:
	push 	cx
	push 	bx

	; first, let's get the port we want to use
	call 	__get_serial_by_id

	; next, get byte count per "packet", and setup line control
	; bits according to user desires and wishes
	; we set AX as our line control register, and BX as baud rate 
	; divisor
	mov 	cl, al
	and 	cl, 11100000b

	and 	al, 00011111b ; clear baudrate bits out of al
	test 	cl, cl
	jz 	.baudrate_110
	mov 	bx, 1536
	.loop:
		shr 	bx, 1 ; we want baudrate *divisor*, not baudrate.
		loop 	.loop
	.done:
		; now dx = port, bx = baudrate divisor, al = line reg
		call 	serial_init
		pop 	bx
		pop 	cx
		jmp 	serial_service_int_handler.done
.baudrate_110:
	mov 	bx, 1047
	jmp 	.done

; ======================================================================== ;
; Serial write character (AH = 01) is used to put single character out 
; of serial port.
; 
; Parameters:
; 	AL = byte to write
; 	DX = Port to write to (0 - 3)
; 
; Returns:
;	AH bit 7 clear on success, set on error,
; 	bits 0 - 6 port status
;
serial_service_putchar:
	; get port again
	call 	__get_serial_by_id

	; check that serial tx is empty
	call 	serial_wait_tx_empty
	jc 	.error

	; write char to put to serial line
	out 	dx, al

	cli
	hlt
	jmp 	$ - 2

	; get port status to ah
	call 	serial_get_line_status

	; return back to handler
	jmp 	serial_service_int_handler.done
.error:
	call 	serial_get_line_status
	or 	ah, 10000000b
	jmp 	serial_service_int_handler.done

; ======================================================================== ;
; Serial read character (AH = 02) is.. as the name suggests, a function
; that reads 1 byte from serial line.
;
; Parameters:
;	DX = port to read from (0 - 3)
; 
; Returns:
; 	AL = Byte read
; 	AH = Line status
;
serial_service_getchar:
	; get port
	call 	__get_serial_by_id
	in 	al, dx

	; exchanges so we don't overwrite what was read from serial line
	xchg 	ah, al
	call 	serial_get_line_status
	xchg 	ah, al
	jmp 	serial_service_int_handler.done

; ======================================================================== ;
; Serial get status (AH = 03)
; 
; Parameters:
;	DX = port to read from (0 - 3)
;
; Returns:
; 	AL = modem status
; 	AH = Line status
;
serial_service_get_status:
	call 	__get_serial_by_id 	; get port by id
	call 	serial_get_line_status 	; get line status
	xchg 	ah, al 			; ah = line status
	call 	serial_get_modem_status ; get modem status to al
	jmp 	serial_service_int_handler.done


