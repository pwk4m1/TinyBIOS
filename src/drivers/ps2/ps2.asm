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

%ifndef PS2_ASM
%define PS2_ASM

%include "src/drivers/ps2/ps2scancodes.asm"

; MF2 keyboard IDs with translation enabled in the PS/Controller
%define PS2_KBD_ID_1 		0xAB41
%define PS2_KBD_ID_2 		0xABC1
; MF2 keyboard ID
%define PS2_KBD_ID_3 		0xAB83


%define PS2_CMD_SET_LED 	0xED 	; set leds on or off
%define PS2_CMD_ECHO 		0xEE 	; echo for diagnostics 
%define PS2_CMD_GSSS 		0xF0 	; get or set scan code set
%define PS2_CMD_ID_KBD 		0xF2 	; identify keyboard
%define PS2_CMD_STRD 		0xF3 	; set typematic rate/delay
%define PS2_CMD_SCAN_ENABLE 	0xF4 	; enable scanning
%define PS2_CMD_SCAN_DISABLE 	0xF5 	; disable scanning, may rst keyboard
%define PS2_CMD_SET_DEFAULT 	0xF6 	; set default parameters
%define PS2_CMD_RESEND 		0xFE 	; resend last sent byte
%define PS2_CMD_RESET 		0xFF 	; detect_and_reset and start self test

%define PS2_REPLY_ERROR 	0x00 	; internal error or buffer overrun
%define PS2_REPLY_ACK 		0xFA 	; command acknowledged 
%define PS2_REPLY_RESEND 	0xFE 	; resend command or data
%define PS2_SELF_TEST_PASS 	0xAA 	; ...
%define PS2_SELF_TEST_FAIL 	0xFC 	; really?
%define PS2_SELF_TEST_FAIL_2 	0xFD 	; not going to explain.

%define PS2_KBD_BUFFER_PTR 	0x041e 	; Keyboard buffer in BDA (32 bytes)
%define PS2_KBD_BUFFER_START 	0x0480 	; Buffer start address (2 bytes)
%define PS2_KBD_BUFFER_END 	0x0482 	; Buffer end address (2 bytes)

%define PS2_KBD_GSC 		0x00 	; Get scancode set
%define PS2_KBD_SSC1 		0x01 	; set scancode set 1 .. 3
%define PS2_KBD_SSC2 		0x02
%define PS2_KBD_SSC3 		0x03

; For setting bits 2 and 3 of KBDCTL_PS2_DEV_STATUS_BITS
%define PS2_KBD_PORT1_ON 	00000100b
%define PS2_KBD_PORT2_ON 	00001000b
%define PS2_KBD_PORT1_OFF 	11111011b
%define PS2_KBD_PORT2_OFF 	11110111b

ps2_int_handler_entry:
	mov 	si, msg_keypress
	call 	serial_print
	ret

msg_keypress:
	db "KEYPRESS!", 0x0A, 0

; Helper to detect a PS2 keyboard.
; Procedure to detect:
;	1.) Send the "disable scanning" command 0xF5 to the device
;	2.) Wait for the device to send "ACK" back (0xFA)
;	3.) Send the "identify" command 0xF2 to the device
;	4.) Wait for the device to send "ACK" back (0xFA)
;	5.) Wait for the device to send up to 2 bytes of reply, 
; 	    with a time-out to determine when it's finished 
;	    (e.g. in case it only sends 1 byte) 
;
; Requires BL=1 if we're checking dev2, BL=0 if dev1
; Returns AL=1 if keyboard is detected, AL=0 if not, CF=1 on error
; 
ps2_detect_keyboard:
	clc
	test 	bl, bl
	jz 	.send_ds

	; We have to tell the 8042 ps2 controller that we want to talk to 
	; device 2 instead of the (default) device 1.
	;
	mov 	al, kbdctl_cmd_writenext_p2inbuf
	call 	kbdctl_send_cmd
	jc 	.error

.send_ds:
	mov 	al, PS2_CMD_SCAN_DISABLE
	call 	kbdctl_send_data_poll
	jc 	.error
	call 	kbdctl_recv_data_poll
	jc 	.error
	cmp 	al, PS2_REPLY_ACK
	jne 	.not_keyboard

	test 	bl, bl
	jz 	.send_id
	mov 	al, kbdctl_cmd_writenext_p2inbuf
	call 	kbdctl_send_cmd
	jc 	.error

.send_id:
	mov 	al, PS2_CMD_ID_KBD
	call 	kbdctl_send_data_poll
	jc 	.error
	call 	kbdctl_recv_data_poll
	jc 	.error
	cmp 	al, PS2_REPLY_ACK
	jne 	.not_keyboard

.waitfor_id:
	xor 	ax, ax
	call 	kbdctl_recv_data_poll
	jc 	.done
	mov 	ah, al
	call 	kbdctl_recv_data_poll

.done:
	cmp 	ax, PS2_KBD_ID_1
	je 	.keyboard_detected
	cmp 	ax, PS2_KBD_ID_2
	je 	.keyboard_detected
	cmp 	ax, PS2_KBD_ID_3
	je 	.keyboard_detected

.not_keyboard:
	mov 	al, 0
	ret

.keyboard_detected:
	mov 	al, 1
	ret

.error:
	stc
	mov 	al, 0
	ret

; Helper to detect and reset PS2 keyboard.
; 
ps2_detect_and_reset_keyboards:
	pusha

	; Check if ps2 device 2 is present
	and 	byte [KBDCTL_PS2_DEV_STATUS_BITS], 00000010b
	jz 	.port1
	mov 	bl, 1
	call 	ps2_detect_keyboard
	cmp 	al, 1
	jne 	.port1

	; We detected a PS2 keyboard on port 2, try to reset it and
	; perform self test.
	;
	mov 	al, kbdctl_cmd_writenext_p2inbuf
	call 	kbdctl_send_cmd
	call 	ps2_reset_keyboard
	test 	al, al
	jz 	.port2_error
	or 	byte [KBDCTL_PS2_DEV_STATUS_BITS], PS2_KBD_PORT2_ON

%ifdef __DO_DEBUG_LOG__
	mov 	si, ps2_msg_keyboard_selftest_done
	call 	serial_print
%endif
.port1:
	call 	ps2_reset_keyboard
	test 	al, al
	jz 	.port1_error
	or 	byte [KBDCTL_PS2_DEV_STATUS_BITS], PS2_KBD_PORT1_ON

%ifdef __DO_DEBUG_LOG__
	mov 	si, ps2_msg_keyboard_selftest_done
	call 	serial_print
%endif
.done:
	popa
	ret

.port1_error:
	mov 	si, ps2_msg_selftest_error
	call 	serial_print
	jmp 	.done
.port2_error:
	mov 	si, ps2_msg_selftest_error
	call 	serial_print
	jmp 	.port1

; A helper to reset PS2 keyboard and to perform self test on it.
; NOTE: To perform the reset/self test on port 2 you have to first
; send kbdctl_cmd_writenext_p2inbuf to controller, only then proceed
; to call this function.
;
; Returns:
;	al = 1 on success or 
; 	al = 0 if error
;
ps2_reset_keyboard:
	push 	cx

	mov 	cl, 5
.start:
	mov 	al, PS2_CMD_RESET
	call 	kbdctl_send_data_poll
	jc 	.error
	call 	kbdctl_recv_data_poll
	cmp 	al, PS2_REPLY_RESEND
	jne 	.check_status
	loop 	.start
.error:
	mov 	al, 0
	jmp 	.ret
.check_status:
	cmp 	al, PS2_REPLY_ACK
	jne 	.error
	mov 	al, 1
.ret:
	pop 	cx
	ret


; Helper to set scancode set on keyboard 
;
; Requires:
;	BL=0 if port 1 is used, BL=1 if port 2 is used
; 	AL=Scancode set (1-3)
; Returns:
; 	CF=0 on success or CF=1 on error
;
ps2_set_scancode_set:
	push 	ax
	push 	ax

	test 	bl, bl
	jz 	.set_sc
	mov 	al, kbdctl_cmd_writenext_p2inbuf
	call 	kbdctl_send_cmd
.set_sc:
	pop 	ax
	call 	kbdctl_send_data_poll
	jc 	.error

	test 	bl, bl
	jz 	.enable_scanning
	mov 	al, kbdctl_cmd_writenext_p2inbuf
	call 	kbdctl_send_cmd
.enable_scanning:
	mov 	al, PS2_CMD_SCAN_ENABLE
	call 	kbdctl_send_data_poll
	jc 	.error
	clc
.done:
	pop 	ax
	ret
.error:
	stc
	ret

; Helper to register our interrupt handler
;
; 1.) Register interrupt handler
; 2.) Detect and reset/self-test keyboards (Check KBDCTL_PS2_DEV_STATUS_BITS)
; 3.) Enable scancode set 1 on all keyboards
; 4.) Enable scanning on all keyboards
;
ps2_kbd_init:
	pusha

	; First, register our handler
	; 
	mov 	eax, ps2_int_handler_entry
	and 	eax, 0x0000ffff
	mov 	bx, cs
	mov 	di, (0x24 * 4)
	call 	set_ivt_entry

	; Next, detect keyboards
	call 	ps2_detect_and_reset_keyboards

	; Set scancode set 1 on all keyboards we've found
	mov 	al, PS2_KBD_SSC1
	test 	byte [KBDCTL_PS2_DEV_STATUS_BITS], PS2_KBD_PORT2_ON
	jz 	.set_port1
	mov 	bl, 1
	call 	ps2_set_scancode_set
	jc 	.port2_error
	mov 	si, ps2_msg_kbd_init_done
	call 	serial_print
.set_port1:
	xor 	bl, bl
	call 	ps2_set_scancode_set
	jc 	.port1_error
	mov 	si, ps2_msg_kbd_init_done
	call 	serial_print
.done:
	popa
	ret
.port1_error:
	and 	byte [KBDCTL_PS2_DEV_STATUS_BITS], PS2_KBD_PORT1_OFF
	mov 	si, ps2_msg_kbd_not_initialised
	call 	serial_print
	jmp 	.done
.port2_error:
	and 	byte [KBDCTL_PS2_DEV_STATUS_BITS], PS2_KBD_PORT2_OFF
	mov 	si, ps2_msg_kbd_not_initialised
	call 	serial_print
	jmp 	.done

ps2_msg_kbd_init_done:
	db "PS/2 KEYBOARD INITIALISED", 0x0A, 0x0D, 0

ps2_msg_kbd_not_initialised:
	db "PS/2 KEYBOARD DETECTED BUT INITIALISATION FAILED", 0x0A, 0x0D, 0

ps2_msg_keyboard_selftest_done:
	db "DEBUG: PS/2 KEYBOARD SELFTEST PASSED", 0x0A, 0x0D, 0

ps2_msg_selftest_error:
	db "DEBUG: PS/2 KEYBOARD SELFTEST FAILED", 0x0A, 0x0D, 0

%endif ; PS2_ASM
