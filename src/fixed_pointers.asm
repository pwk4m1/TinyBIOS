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

%ifndef FIXED_PTRS
%define FIXED_PTRS

; entry.asm
%define TMP_BOOTSECTOR_ADDR 		0x3000

; mm.asm
%define __MM_MEM_START  		0xC000
%define __MM_MEM_END    		0xCFFF

; ata.asm
%define ata_disk_addr_list 		0x3200

; 8042
%define KBDCTL_CONFIG_BYTE 		0x3400
%define KBDCTL_CURRENT_CONFIG 		0x3401
%define KBDCTL_DUAL_CHANNEL_ENABLED 	0x3402
; bit 0: ps2 device 1 status: 1 ok, 0 error
; bit 1: ps2 device 2 status: 1 ok, 0 error
; bit 2: ps2 device 1 is initialised keyboard: 1, else 0
; bit 3: ps2 device 2 is initialised keyboard: 1, else 0
%define KBDCTL_PS2_DEV_STATUS_BITS 	0x3403

; pci.asm
%define pci_dev_ptr_array       	0x5002
%define pci_dev_cnt             	0x5000

%define EBDA_BASE_ADDR 			0x8000 ; shifted right by 4.

%define DISK_DRIVE_LAST_STATUS 		0x04A0 	; 1 byte
%define INT_HANDLER_RET_PTR 		0x04A1 	; 2 bytes
%define DISK_MAIN_SIZE_LBA 		0x04A3 	; 2 bytes

%define PIT_SYSTEM_TIME 		0x00080000 ; System time, 4 bytes


%endif
