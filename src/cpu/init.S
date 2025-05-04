/*
 BSD 3-Clause License
 
 Copyright (c) 2024, k4m1
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
.global init_cpu
.global switch_to_unreal
.global switch_to_protected

#include <asm/cpu/longjmp.h>

/* Helper function for switching to protected mode, this is used during early boot
 * as well as by interrupt handlers.
 *
 * Clobbers cs, eax, gdtr
 */
switch_to_protected:
.code16
    mov     eax, offset gdt
    lgdt    [eax]
    xor     eax, eax
    lidt    [eax]
    mov     eax, cr0
    or      al, 1
    mov     cr0, eax
    LONGJMP(0x0008, next)
next:
.code32
    pop     eax
    or      eax, 0xf0000
    jmp     eax
.code16    

/* Helper function for switching to unreal mode, this is used during early boot
 * as well as by interrupt handlers.
 *
 * Clobbers ds, gdtr
 */
switch_to_unreal:
.code32
    push    eax
    push    bx
    mov     eax, offset gdt
    lgdt    [eax]
    mov     eax, cr0
    mov     bx, 0x08
    mov     ds, bx
    and     al, 0xFE
    mov     cr0, eax
    xor     ax, ax
    mov     ds, ax
    pop     bx
    pop     eax
    ret
.code16

setup_paging:
.code32
    pusha
    mov     ecx, ((2048 + 512) * 2)
    xor     eax, eax
    xor     edi, edi
    rep     stosd

    mov     eax, 3
    xor     edi, edi
    xor     ebx, ebx
    mov     ecx, 1024
    .loop_pt:
        stosd
        xchg    ebx, eax
        stosd
        xchg    ebx, eax
        add     eax, 0x1000
        loop    .loop_pt

    // pd 
    mov     ecx, 1024
    mov     eax, 3
    push    edi
    .loop_pd:
        stosd
        xchg    ebx, eax
        stosd
        xchg    ebx, eax
        loop    .loop_pd

    // pml4 
    pop     eax
    and     eax, 0xFFFFF000
    or      eax, 3
    stosd
    xchg    ebx, eax
    stosd

    mov     eax, edi
    sub     eax, 8
    mov     cr3, eax

    mov     ecx, 0xC0000080
    rdmsr
    or      eax, (1 << 8)
    wrmsr

    mov     eax, cr4
    or      eax, (1 << 5)
    mov     cr4, eax

    mov     eax, cr0
    or      eax, ((1 << 31) | (1 << 0))
    mov     cr0, eax

    mov     ax, 0x18
    mov     ds, ax
    mov     es, ax
    mov     gs, ax
    mov     fs, ax
    mov     ss, ax
    LONGJMP32(0x0010, .next_64)

.next_64:
.code64
    jmp     continue_entry_prep
.code16

// We'll land here from reset.S, things we'll want to do next are 
// to move to some more appropriate runmode which doesn't do segments and
// 20-bit addressing, etc.
//
init_cpu:
    .code16

    // Start by moving to 32 bit protected mode
    push    eax
    call    switch_to_protected
    .code32
    pop     eax
    mov     esp, 0x00007c00
    // call    switch_to_unreal
    call    setup_paging

.code64
continue_entry_prep:
    // Relocate our C code into ram
    //
    mov     rsi, 0xE0000
    mov     rdi, 0x70000 
    mov     rcx, 0x0FFFF
    rep     movsb
    mov     rsp, 0x00007c00
    mov     rbp, rsp

    xor     rdi, rdi
    xor     rsi, rsi
    call    c_main

    // Never reached but better be overly careful 
.hang:
    mov     rax, 0xdeadc0de 
    cli
    hlt
    jmp     .hang

