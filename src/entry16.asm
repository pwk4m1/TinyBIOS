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

; later on, add ifdef <TARGET PLATFORM> or smhn like that.


; ======================================================================== ;
; This is the first entry point of our BIOS code after reset vector.
; Offset from ROM beginning is 0x10000.
;
; ======================================================================== ;
bits    16
%define VER_NUM "0.4"
entry:
    jmp     main

; ======================================================================== ;
; Includes here
; ======================================================================== ;
%include "src/fixed_pointers.asm"
%include "src/mm.asm"

%include "src/drivers/ram/ram_init_common_entry.asm"
%include "src/drivers/serial.asm"

%include "src/drivers/qemu/superio.asm"

%include "src/drivers/cpu/common_ia86.asm"
%include "src/drivers/cpu/intel_car.asm"

; ======================================================================== ;
; Messages to print and stuff
; ======================================================================== ;
%define EOL 0x0a, 0x0d, 0

msg_boot_early:
    db "Tinybios ", VER_NUM, " booting...", EOL

; ======================================================================== ;
; Main functionality
; ======================================================================== ;

main:
    cli
    cld

    ; save BIST result
    mov ebp, eax

    ; disable TLB
    xor eax, eax
    mov cr3, eax

    ; this macro is provided by drivers/dev/superio.asm
    SUPERIO_INIT_MACRO

    ; this macro is provided by drivers/cpu/YOURCPU.asm
    INIT_CAR

; ======================================================================== ;
; At this point, ram init is completed, we can go on with our boot process
;
; ======================================================================== ;
    push ebp         ; store ebp/BIST to stack
    mov ebp, esp

    ; Proceed to initialise superio, need this before serial is a thing
    ; 
    call superio_init_entry    

    ; Show a simple bootsplash over serial port
    mov si, msg_boot_early
    call serial_print

    ; Try and enable main memory, if ram_init fails we don't return
    call ram_init_entry

    ; We've now got ram, no need to use cache for that anymore.
    pop ebp
    DISABLE_CAR

    and esp, 0x0000FFFF
    mov sp, STACK_RAM + 512
    push ebp

    ; Start random device init here
    call mm_heap_init
    call cpuid_print_cpu_vendor


.hang:
    mov ax, 0xdead
    cli
    hlt
    jmp  $ - 2
