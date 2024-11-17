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
.global interrupt_handler_init_runtime
.extern bda_int_handler_gdtr

/* This function is used by all other interrupt handlers after they have
 * disabled interrupts, and stored cpu state to an appropriate location.
 *
 * We'll store GDTR, cr0, and segments here, but all other registers
 * should be saved by initial interrupt handler entry.
 *
 * @param bx -- offset to actual interrupt handler
 * Clobbers high half of ebx
 *
 * NOTE: This function is supposed to be Jumped to, not called. We'll
 *       perform IRET at the end of our operations.
 */
.code16
interrupt_handler_init_runtime:
    sgdt    [bda_int_handler_gdtr]
    push    cs
    push    eax
    call    switch_to_protected
.code32
    pop     eax
    push    ds
    call    switch_to_unreal
    and     ebx, 0x0000FFFF
    or      ebx, 0x000F0000
    call    ebx
    pop     ds
    lgdt    [bda_int_handler_gdtr]
    iret

