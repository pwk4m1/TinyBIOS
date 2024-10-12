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
 * 1.) Switch to unreal mode
 * 2.) Call appropriate interrupt handler
 * 3.) Switch back to initial CPU state
 * 4.) Send EOI
 * 5.) iret
 *
 * @param cx -- offset to appropriate interrupt handler
 * 
 * NOTE: We expect handler at IVT entry to have done;
 *       cli
 *       pusha
 *       mov cx, main_int_handler_offset
 *       mov dx, INT_PRIMARY ? INT_SECONDARY
 *       jmp common_int_handler
 * 
 */
common_int_handler:
    mov     eax, cr0
    // See if we're too far in runmode changes that we can't safely just
    // 'pop cr0, ret' anymore. If we are, set error and return.
    //
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
    call    switch_to_unreal
    call    cx
    inc     esp
    lgdt    [esp]
    add     esp, 6
    pop     eax
    mov     cr0, eax
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

