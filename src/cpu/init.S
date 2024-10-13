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

/* Helper function for switching to unreal mode, this is used during early boot
 * as well as by interrupt handlers.
 *
 */
switch_to_unreal:
    mov     eax, offset gdt
    lgdt    [eax]
    mov     eax, cr0
    mov     bx, 0x08
    mov     ds, bx
    and     al, 0xFE
    mov     cr0, eax
    xor     ax, ax
    mov     ds, ax
    ret

/* Workaround for compiler/clang issue, refer
 * https://github.com/llvm/llvm-project/issues/49636
 */
#define LONGJMP(segment, target) \
    .byte   0x66; \
    .byte   0xEA; \
    .int    target; \
    .short  segment;

// We'll land here from reset.S, things we'll want to do next are 
// to move to some more appropriate runmode which doesn't do segments and
// 20-bit addressing, etc.
//
init_cpu:
    .code16
    // Start by moving to 32 bit protected mode
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
    // 16-bit compability mode now re; CS & cr0, set rest of segments
    // and start moving towards 64 bit long mode
    //
    cli

    call    switch_to_unreal

    // Relocate our C code into ram
    //
    mov     esi, 0xE0000
    mov     edi, 0x7E00 
    mov     ecx, 0x0FFFF
    rep     movsb
    mov     esp, 0x00007c00
    mov     ebp, esp
    xor     ax, ax
    mov     ds, ax
    call    c_main

    // Never reached but better be overly careful 
.hang:
    mov     eax, 0xdeadc0de 
    cli
    hlt
    jmp     .hang

