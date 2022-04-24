; BSD 3-Clause License
; 
; Copyright (c) 2022, k4m1 <k4m1@protonmail.com>
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


KBDCTL_CURRENT_CONFIG:
	db 0
KBDCTL_DUAL_CHANNEL_ENABLED:
	db 0

; Driver for kbdctl/"ps2" controller. You might be
; familiar with this due such legacy treasures as a20
;

; Data, status, and command ports.
; Do note, that status and command happen over 0x64, but
; the port acts different based on read/write
;
%define kbdctl_data_rw 			0x60
%define kbdctl_stat_ro 			0x64
%define kbdctl_cmd_wo 			0x64

; Status register bit meanings:
; 0,1.) Output & input statuses
; 2.) System flag, this is cleared on reset
; 		and we set it when system has passed POST (Todo oneday)
; 3.) Command/data, if 0 then data written to input buffer is for ps/2 dev
; 		else data is for ps/2 controller
; 4.) Chipset specific
; 5.) Timeout error (0 = good, 1  = time'd out)
; 6.) Parity error (0 = good, 1 = parity error)
; 
%define kbdctl_stat_out_buf 		0x01
%define kbdctl_stat_in_buf 		0x02
%define kbdctl_stat_sysf 		0x04
%define kbdctl_stat_cd 			0x08
%define kbdctl_stat_timeout 		0x40
%define kbdctl_stat_parity 		0x80

; Configuration byte bit definitions:
; 0.) First ps/2 port interrupt enabled
; 1.) Second ps/2 port interrupt enabled
; 2.) System flag (Passed POST or not)
; 3.) Zero
; 4.) First ps/2 port clock enabled
; 5.) Second ps/2 port clock enabled
; 6.) First ps/2 port translation enabled
; 7.) Zero
;
%define kbdctl_ctl_p1_ie 		0x01
%define kbdctl_ctl_p2_ie 		0x02
%define kbdctl_ctl_sf 			0x04
%define kbdctl_ctl_ps1_clke 		0x10
%define kbdctl_ctl_ps2_clke 		0x20
%define kbdctl_ctl_ps1_te 		0x40

; Disable IRQs and translation 
%define kbdctl_default_config_mask 	0xbc

; Controller output port bit definitions
; 0.) System reset (output), Always set to 1. Pulse reset with 0xFE
;     Setting to '0' can cause 'reset forever'.
; 1.) A20 gate (output)
; 2.) Second ps/2 port clock
; 3.) Second ps/2 port data
; 4.) Output buffer full with byte from 1st PS/2 port (IRQ1)
; 5.) As above for 2nd PS/2 port (IRQ12)
; 6.) First ps/2 port clock
; 7.) First ps/2 port data
%define kbdctl_ctl_out_sysrst 		0x01
%define kbdctl_ctl_out_a20 		0x02
%define kbdctl_ctl_out_p2_clk 		0x04
%define kbdctl_ctl_out_p2_data 		0x08
%define kbdctl_ctl_out_buf_full_irq1 	0x10
%define kbdctl_ctl_out_buf_full_irq12 	0x20
%define kbdctl_ctl_out_p1_clk 		0x40
%define kbdctl_ctl_out_p1_data 		0x80

; Command bytes:
; 1.)  Read "Byte 0" from internal ram, returns controller config byte
; 2.)  Read Nth byte of internal ram
; 3.)  Write byte0/controller configuration byte
; 4.)  Write Nth byte of internal ram
; 5.)  Disable second ps/2 port (if supported)
; 6.)  Enable second ps/2 port (if supported)
; 7.)  Test second ps/2 port (if supported)
; 8.)  Test ps/2 controller 
; 9.)  Test 1st ps/2 port 
; 10.) Diagnostic dump (Read all ram)
; 11.) Disable 1st ps/2 port
; 12.) Enable 1st ps/2 port
; 13.) Read controller input port
; 14.) Copy bits 0-3 of input to status 4-7
; 15.) Copy bits 4-7 of input to status 4-7
; 16.) Read controller output port 
; 17.) Write next byte to Controller Output Port
; 	Note: first check that output buffer is empty
; 18.) Write next byte to ps/2 port 1 output buffer
; 	Note: Makes it look like byte was from 1st ps/2 port
; 19.) Write next byte to ps/2 port 2 output buffer
; 	Note: Makes it look like the byte was from 2nd ps/2 port
; 20.) Write next byte to ps/2 port input buffer
; 	Note: Sends next byte to second ps/2 port)
;
%define kbdctl_cmd_read_config 		0x20
%define kbdctl_cmd_readbN(N) 		(0x20 + N)
%define kbdctl_cmd_write_config 	0x60
%define kbdctl_cmd_writebN(N) 		(0x60 + N)
%define kbdctl_cmd_disable_p2 		0xA7
%define kbdctl_cmd_enable_p2 		0xA8
%define kbdctl_cmd_test_p2 		0xA9
%define kbdctl_cmd_test_ctl 		0xAA
%define kbdctl_cmd_test_p1 		0xAB
%define kbdctl_cmd_dump_ram 		0xAC
%define kbdctl_cmd_disable_p1 		0xAD
%define kbdctl_cmd_enable_p1 		0xAE
%define kbdctl_cmd_read_ctl_in 		0xC0
%define kbdctl_cmd_cp_inlo_stathi 	0xC1
%define kbdctl_cmd_cp_inhi_stathi 	0xC2
%define kbdctl_cmd_read_ctl_out 	0xC3
%define kbdctl_cmd_writenext_ctl_out 	0xD1
%define kbdctl_cmd_writenext_p1outbuf 	0xD2
%define kbdctl_cmd_writenext_p2outbuf 	0xD3
%define kbdctl_cmd_writenext_p4inbuf 	0xD4
%define kbdctl_cmd_pulse_out_low(n) 	(n | 0xF0)
%define kbdctl_cmd_cpu_hard_reset 	0xFE

; Some predefined responses to commands
%define kbdctl_selftest_success 	0x55
%define kbdctl_stat_ack			0xFA

; Helper functions to various operations related to kbdctl
;

; Send command to controller, read response (ack)
; Requires:
;	al = command byte to send
; Returns:
; 	carry flag on error/nack
; Notes:
;	Display error if command is not acknowledged
;
kbdctl_send_cmd:
	clc
	push 	ax
	push 	cx

	mov 	cx, 50
	xchg 	al, ah
	.cmd_write:
		; check that controller input buffer status is empty
		;
		in 	al, kbdctl_stat_ro
		test 	al, kbdctl_stat_in_buf
		; if it's not, jump to loop
		;
		jnz 	.loop_next
		xchg  	ah, al
		; write command
		;
		out 	kbdctl_cmd_wo, al
		jmp 	.done
	.loop_next:
		loop 	.cmd_write
	; the thing has timed out, time to set carry flag
	; and display error
	;
	push 	si
	mov 	si, kbdctl_msg_ctl_timeout
	call 	serial_print
	pop 	si
	stc
	.done:
		pop 	cx
		pop 	ax
		ret

; Read 1 byte from data port once data becomes readable
; Requires:
;	 -
; Returns:
;	 Al = byte recv'd
; Notes:
; 	Carry flag set on timeout.
;
kbdctl_recv_data_poll:
	clc
	push 	cx

	mov 	cx, 50
	.data_recv:
		; check that controller input buffer is not empty
		;
		in 	al, kbdctl_stat_ro
		test 	al, kbdctl_stat_out_buf
		jz 	.read_loop
		in 	al, kbdctl_data_rw
		jmp 	.done
	.read_loop:
		loop 	.data_recv
	; data has not been readable for 50 iterations, call
	; it quits, display error
	;
	push 	si
	mov 	si, kbdctl_msg_ctl_timeout
	call 	serial_print
	pop 	si
	stc
	.done:
		pop 	cx
		ret

; Write 1 byte of data to port once it becomes writable.
; Requires:
;	Al = byte to write
; Returns:
;	-
; Notes:
;	Carry flag set on timeout.
;
kbdctl_send_data_poll:
	clc
	push 	cx
	push 	ax

	mov 	cx, 50
	.data_send:
		; check that controller input buffer is empty
		in 	al, kbdctl_stat_ro
		test 	al, kbdctl_stat_in_buf
		jnz 	.loop
		pop 	ax
		out 	kbdctl_data_rw, al
		jmp 	.done
	.loop:
		loop 	.data_send
	; data has not been writable for 50 iterations, call
	; it quits, display error
	;
	push 	si
	mov 	si, kbdctl_msg_ctl_timeout
	call 	serial_print
	pop 	si
	stc
	pop 	ax
	.done:
		pop 	cx
		ret
	

; Disable all devices, this is used for the controller init.
; Requires:
;	-
; Returns:
;	-
; Notes:
;	Carry flag set on error
;
kbdctl_disable_devices:
	push 	ax
	mov 	al, kbdctl_cmd_disable_p1
	call 	kbdctl_send_cmd
	jc 	.errored

	mov 	al, kbdctl_cmd_disable_p2
	call 	kbdctl_send_cmd
.errored:
	pop 	ax
	ret

; Set kbd controller byte with default config mask w/ interrupts and
; translation layer disabled. 
; Requires:
;	-
; Returns:
;	-
; Notes:
;	Carry flag set on error
;
kbdctl_init_config:
	push 	ax
	mov 	al, kbdctl_cmd_read_config
	call 	kbdctl_send_cmd
	jc 	.done
.get_data:
	call 	kbdctl_recv_data_poll

	and 	al, kbdctl_default_config_mask
	test 	al, kbdctl_ctl_ps2_clke
	jz 	.single_channel
	mov 	byte [KBDCTL_DUAL_CHANNEL_ENABLED], 1
	mov 	byte [KBDCTL_CURRENT_CONFIG], al
.single_channel:
	xchg 	al, ah
	mov 	al, kbdctl_cmd_write_config
	call 	kbdctl_send_cmd
	xchg 	al, ah
	call 	kbdctl_send_data_poll
	
.done:
	pop 	ax
	ret

; Perform controller self test. 
; If the device got reset, restore the configuration set at
; kbdctl_init_config.
; Requires:
;	-
; Returns:
;	-
; Notes:
;	Carry flag set on error
;
kbdctl_ctl_test:
	push 	ax
	mov 	al, kbdctl_cmd_test_ctl
	call 	kbdctl_send_cmd
	jc 	.done

	call 	kbdctl_recv_data_poll
	cmp 	al, kbdctl_selftest_success
	je 	.done
	push 	si
	mov 	si, kbdctl_msg_selftest_fail
	call 	serial_print
	call 	serial_printh

	; if self test has failed (response was not ACK+STAT OK)
	; 
	mov 	al, kbdctl_cmd_read_config
	call 	kbdctl_send_cmd
	jc 	.done
	call 	kbdctl_recv_data_poll
	jc 	.done
	
	; if prior configuration has been lost, device has been reset.
	; In such case, restore from KBDCTL_CURRENT_CONFIG
	;
	cmp 	al, byte [KBDCTL_CURRENT_CONFIG]
	je 	.done
	mov 	si, kbdctl_msg_dev_no_reset
	call 	serial_print
	pop 	si
	call 	kbdctl_init_config
.done:
	pop 	ax
	ret

; Super simple helper that only performs
; device test on single device
;
; Requires:
;	al = command for device to test
; Returns:
;	al = status of test
; Notes:
;	Carry flag set on timeout
;
kbdctl_dev_test:
	call 	kbdctl_send_cmd
	jc 	.done
	call 	kbdctl_recv_data_poll
.done:
	ret

; Print device status if it errored
;
kbdctl_print_device_status:
	push 	si
	cmp 	al, 0
	je 	.done
	cmp 	al, 2
	jl 	.cll
	je 	.clh
	cmp 	al, 4
	jl 	.dll
	je 	.dlh
	mov 	si, kbdctl_msg_dev_error_unknown
.print:
	call 	serial_print
.done:
	pop 	si
	ret
.cll:
	mov 	si, kbdctl_msg_dev_clock_low
	jmp 	.print
.clh:
	mov 	si, kbdctl_msg_dev_clock_high
	jmp 	.print
.dll:
	mov 	si, kbdctl_msg_dev_data_low
	jmp 	.print
.dlh:
	mov 	si, kbdctl_msg_dev_data_high
	jmp 	.print

; Perform device tests
; If device returns with:
; 	00, test passed
; 	01, clock line stuck low
;	02, clock line stuck high
; 	03, data line stuck low
; 	04, data line stuck high
; 
; Requires:
;	-
; Returns:
;	-
; Notes:
;	Carry flag set on error
;
kbdctl_dev_test_all:
	push 	ax
	mov 	al, kbdctl_cmd_test_p1
	call 	kbdctl_dev_test
	jc 	.done
	cmp 	byte [KBDCTL_DUAL_CHANNEL_ENABLED], 1
	jne 	.test_done_p1
	xchg 	al, ah
	mov 	al, kbdctl_cmd_test_p2
	call 	kbdctl_dev_test
	jc 	.done
.test_done_p2:
	cmp 	byte [KBDCTL_DUAL_CHANNEL_ENABLED], 1
	jne 	.test_done_p1
	call 	kbdctl_print_device_status
.test_done_p1:
	xchg 	ah, al
	call 	kbdctl_print_device_status
.done:
	pop 	ax
	ret

; test for now
kbdctl_init:
	push 	ax
	call 	kbdctl_disable_devices
	jc 	.done
	; flush output buffer, we don't care about content so 
	; no need to poll
	;
	in 	al, kbdctl_data_rw
	; flush done, go on.
	;
	call 	kbdctl_init_config
	jc 	.done
	call 	kbdctl_ctl_test
	jc 	.done
	call 	kbdctl_dev_test_all
	jc 	.done
.done:
	pop 	ax
	ret

kbdctl_msg_ctl_timeout:
	db "KEYBOARD CONTROLLER TIMED OUT", 0x0A, 0x0D, 0

kbdctl_msg_dev_no_reset:
	db "KEYBOARD CONTROLLER DIDN'T RESET AFTER FAILED SELF TEST!"
	db 0x0A, 0x0D, 0

kbdctl_msg_selftest_fail:
	db "KEYBOARD CONTROLLER FAILED SELF TEST, RESPONSE: ", 0

kbdctl_msg_dev_clock_low:
	db "CLOCK STUCK LOW", 0x0A, 0x0D, 0

kbdctl_msg_dev_clock_high:
	db "CLOCK STUCK HIGH", 0x0A, 0x0D, 0

kbdctl_msg_dev_data_low:
	db "DATA STUCK LOW", 0x0A, 0x0D, 0

kbdctl_msg_dev_data_high:
	db "DATA STUCK HIGH", 0x0A, 0x0D, 0

kbdctl_msg_dev_error_unknown:
	db "UNKNOWN ERROR", 0x0A, 0x0D, 0

