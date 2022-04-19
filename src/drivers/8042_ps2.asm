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

; Driver for 8042/"ps2" controller. You might be
; familiar with this due such legacy treasures as a20
;

; Data, status, and command ports.
; Do note, that status and command happen over 0x64, but
; the port acts different based on read/write
;
%define 8042_data_rw 			0x60
%define 8042_stat_ro 			0x64
%define 8042_cmd_wo 			0x64

; Status register bit meanings:
; 1.) Output & input statuses
; 2.) System flag, this is cleared on reset
; 		and we set it when system has passed POST (Todo oneday)
; 3.) Command/data, if 0 then data written to input buffer is for ps/2 dev
; 		else data is for ps/2 controller
; 4.) Chipset specific
; 5.) Timeout error (0 = good, 1  = time'd out)
; 6.) Parity error (0 = good, 1 = parity error)
; 
%define 8042_stat_out_buf 		0x00
%define 8042_stat_in_buf 		0x02
%define 8042_stat_sysf 			0x04
%define 8042_stat_cd 			0x08
%define 8042_stat_timeout 		0x40
%define 8042_stat_parity 		0x80

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
%define 8042_ctl_p1_ie 			0x00
%define 8042_ctl_p2_ie 			0x02
%define 8042_ctl_sf 			0x04
%define 8042_ctl_ps1_clke 		0x10
%define 8042_ctl_ps2_clke 		0x20
%define 8042_ctl_ps1_te 		0x40

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
%define 8042_cmd_read_config 		0x20
%define 8042_cmd_readbN(N) 		(0x20 + N)
%define 8042_cmd_write_config 		0x60
%define 8042_cmd_writebN(N) 		(0x60 + N)
%define 8042_cmd_disable_p2 		0xA7
%define 8042_cmd_enable_p2 		0xA8
%define 8042_cmd_test_p2 		0xA9
%define 8042_cmd_test_ctl 		0xAA
%define 8042_cmd_test_p1 		0xAB
%define 8042_cmd_dump_ram 		0xAC
%define 8042_cmd_disable_p1 		0xAD
%define 8042_cmd_enable_p1 		0xAE
%define 8042_cmd_read_ctl_in 		0xC0
%define 8042_cmd_cp_inlo_stathi 	0xC1
%define 8042_cmd_cp_inhi_stathi 	0xC2
%define 8042_cmd_read_ctl_out 		0xC3
%define 8042_cmd_writenext_ctl_out 	0xD1
%define 8042_cmd_writenext_p1outbuf 	0xD2
%define 8042_cmd_writenext_p2outbuf 	0xD3
%define 8042_cmd_writenext_p4inbuf 	0xD4
%define 8042_cmd_pulse_out_low(n) 	(n | 0xF0)



