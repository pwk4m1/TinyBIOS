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
.code16
.global common_int_handler

#include <interrupts/common.h>

/* 
 * function common_int_handler exists because we've no way of
 * predicting the runmode bootloader has set up so far. We'll unify things
 * from here. 
 *
 * We assume initial landing from interrupt to have done:
 * cli
 * push handler
 * jmp common_int_handler
 *
 * Here we'll do:
 *   1.) Set argument structure for interrupt handler
 *   2.) Switch to unreal mode
 *   3.) Call appropriate interrupt handler
 *   4.) Switch back to initial CPU state
 *   5.) Send EOI
 *   6.) iret
 *
 */
common_int_handler:
    push    bp
    push    ax
    mov     bp, sp
    add     sp, 4
    pop     ax // pop handler
    mov     sp, bda_ihandler_arg_structure - 18 // handler: 2 bytes, pusha: 16
    push    ax // push it into int handler arg structure
    pusha
    mov     sp, bp
    pop     ax
    pop     bp

    // See if we're too far in runmode changes that we can't safely just
    // 'pop cr0, ret' anymore. If we are, set error and return.
    //
    mov     eax, cr0
    test    eax, (1 << 31)
    jnz     .err

    // See if we are already in unreal or protected mode.
    //
    test    eax, 1
    jnz     .not_in_unreal_yet

    // Check if we're in protected mode instead of unreal mode.
    // If we are, return with error.
    //
    mov     bx, ds
    test    bx, bx
    jnz     .err

    // we're already in unreal mode, don't switch around
    //
    call    cx
    jmp     .ret

.not_in_unreal_yet:
    // Store cr0 content to stack, switch to unreal mode, and
    // execute interrupt handler of ours.
    //
    push    eax
    sub     esp, 6
    sgdt    [esp]
    dec     esp
    push    eax
    push    bx
    push    ds
    call    switch_to_unreal
.code32
    call    cx
    pop     cx
    pop     bx
    pop     eax
    inc     esp
    lgdt    [esp]
    mov     ds, bx
    add     esp, 6
    mov     cr0, eax
.code16
.ret:
    mov     al, 0x20
    cmp     dx, INTERRUPT_PRIMARY
    je      .ret_final
    out     SECONDARY_PIC_PORT, al
.ret_final:
    out     PRIMARY_PIC_PORT, al
    popa
    iret
.err:
    stc
    jmp     .ret

