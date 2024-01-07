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

section .bss
absolute 0

; Interrupt vector table
ADDR_IVT:
    resb 0x3ff

; Bios data area
ADDR_BDA:
    resb 256

; 29.75 KB of free memory
ADDR_ATA_DISK_ADDR_LIST:
    ; up to 4 buses with up to 2 disks each.
    resb 4 * 2 * 2

ADDR_KBDCTL_CONFIG:
    resb 1
ADDR_KBDCTL_CURRENT_CONFIG:
    resb 1
ADDR_KBDCTL_DUAL_CHANNEL_ENABLED:
    resb 1
ADDR_KBDCTL_PS2_DEV_STATUS:
    ; bit 0: ps2 device 1 status: 1 ok, 0 error
    ; bit 1: ps2 device 2 status: 1 ok, 0 error
    ; bit 2: ps2 device 1 is initialised keyboard: 1, else 0
    ; bit 3: ps2 device 2 is initialised keyboard: 1, else 0
    resb 1

; half a kilobyte of stack for us 
absolute 0x7000
STACK_RAM:
    resb 512

; Bootloader sector
absolute 0x7c00
ADDR_MBR:
    resb 0x200

; 480 Kilobytes of free space
; reserve 33 kilobytes for heap
ADDR_HEAP:
    resb (0xffff - 0x7e00)

section .text
%endif
