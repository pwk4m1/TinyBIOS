/*
 BSD 3-Clause License
 
 Copyright (c) 2019, k4m1
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 
 1. Redistributions of source code must retain the above copyright notice, this
    list of conditions and the following disclaimer.
 
 2. Redistributions in binary form must reproduce the above copyright notice,
    this list of conditions and the following disclaimer in the documentation
    and/or other materials provided with the distribution.
 
 3. Neither the name of the copyright holder nor the names of its
    contributors may be used to endorse or promote products derived from
    this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 
*/
    
.section .rom_text
/* Entry at 0xF0000 */

.code16
entry:
    cld

    // Bist result to ebp
    mov     ebp, eax

    // Disable TLB
    xor     eax, eax
    mov     cr3, eax

    #include "cpu/cache.S"
    xor     esi, esi
    xor     edi, edi

    // We now have stack, store bist results there
    push    ebp
    mov     ebp, esp

    // Handle string segments
    // Handle main memory initialisation
    call    main_memory_init

    // Move stack from cache to ram, and move bist results
    // as well
    pop     ebp
    mov     esp, 0x7c00
    push    ebp

    // Disable MTRR subsystem for now, we don't really have a need
    // for it and I'd prefer to have the least amount possible running at
    // this point. The less things that can randomly break, the better.
    //
    mov     ecx, MTRR_DEFTYPE_REG0
    rdmsr
    and     eax, ~MTRR_ENABLE
    wrmsr

    // We've now got actual memory going on, time to switch runmodes
    // around so that we're not relying on segments / 20-bit addressing
    //
    call    init_cpu

    mov     ax, 0xDEAD
.hang:
    cli
    hlt
    jmp     .hang

.section .reset
/* Reset at 0xFFFF0 */
.global reset
reset:
    cli
    jmp     entry

