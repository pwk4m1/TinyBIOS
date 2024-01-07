; BSD 3-Clause License
;
; Copyright (c) 2021, k4m1 <k4m1@protonmail.com>
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

    %define CACHE_AS_RAM_BASE       0x08000000
    %define CACHE_AS_RAM_SIZE       0x2000
    %define MEMORY_TYPE_WRITEBACK   0x06
    %define MTRR_PAIR_VALID         0x800

    ; base
    %define MTRR_PHYB_LO 	        (CACHE_AS_RAM_BASE | \
    				                    MEMORY_TYPE_WRITEBACK)
    %define MTRR_PHYB_REG0 	        0x200
    %define MTRR_PHYB_HI 	        0x00

    ; mask
    %define MTRR_PHYM_LO 	        ((~((CACHE_AS_RAM_SIZE) - 1)) | \
    				                    MTRR_PAIR_VALID)

    %define MTRR_PHYM_HI 	        0xF
    %define MTRR_PHYM_REG0 	        0x201

    %define MTRR_DEFTYPE_REG0       0x2FF
    %define MTRR_ENABLE 	        0x800

%macro INIT_CAR 0
    ; setup MTRR base 
    mov eax, MTRR_PHYB_LO	; mtrr phybase low
    mov ecx, MTRR_PHYB_REG0	; ia32 mtrr phybase reg0
    xor edx, edx
    wrmsr

    ; setup MTRR mask
    mov eax, MTRR_PHYM_LO
    mov ecx, MTRR_PHYM_REG0
    mov edx, MTRR_PHYM_HI
    wrmsr

    ; enable MTRR subsystem
    mov ecx, MTRR_DEFTYPE_REG0
    rdmsr
    or eax, MTRR_ENABLE
    wrmsr

    ; enter normal cache mode
    mov eax, cr0
    and eax, 0x9fffffff
    invd
    mov cr0, eax

    ; establish tags for cache-as-ram region in cache
    mov esi, CACHE_AS_RAM_BASE
    mov ecx, (CACHE_AS_RAM_SIZE / 2)
    rep lodsw

    ; clear cache memory region
    mov edi, CACHE_AS_RAM_BASE
    mov ecx, (CACHE_AS_RAM_SIZE / 2)
    rep stosw

    xor ax, ax
    mov ss, ax
    mov esp, (CACHE_AS_RAM_BASE + CACHE_AS_RAM_SIZE)

%endmacro

%macro DISABLE_CAR 0
    mov eax, cr0
    or eax, 0x30000000
    mov cr0, eax

    mov ecx, MTRR_PHYB_REG0
    rdmsr
    xor eax, MTRR_ENABLE
    wrmsr    
%endmacro



