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
		; try writing command, backup command byte in case
		; we don't get ack
		;
		out 	kbdctl_cmd_wo, al
		xchg 	ah, al
		; check status of write command, if ACK, we're
		; done here. go back to loop othervice.
		; 
		in 	al, kbdctl_data_rw
		cmp 	al, kbdctl_stat_ack
		je 	.done
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

; Read 1 byte from data port once data become s readable


