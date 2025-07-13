/*
 BSD 3-Clause License
 
 Copyright (c) 2025, k4m1 <me@k4m1.net>
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

#include <cpu/common.h>

#include <stdint.h>
#include <stdlib.h>
#include <panic.h>

extern void realmode_callback(void);

/* Helper to get cpu-state into memory
 *
 * @return cpu_state_64b *state
 */
static inline cpu_state_64b __attribute__((always_inline)) *save_cpu_state() {
    cpu_state_64b *state = calloc(1, sizeof(cpu_state_16b));
    if (!state) {
        panic_oom("Unable to context-switch\n");
    }
    /*
    state->cr.cr0 = get_cr0();
    state->cr.cr3 = get_cr3();
    state->cr.cr4 = get_cr4();
    */

    state->segments.cs = read_cs();
    state->segments.es = read_es();
    state->segments.ds = read_ds();
    state->segments.fs = read_fs();
    state->segments.gs = read_gs();
    state->segments.ss = read_ss();

    state->rax = get_rax();
    state->rbx = get_rbx();
    state->rcx = get_rcx();
    state->rdx = get_rdx();
    state->rsi = get_rsi();
    state->rdi = get_rdi();
    state->rbp = get_rbp();
    state->rsp = get_rsp();
    state->r8  = get_r8();
    state->r9  = get_r9();
    state->r10 = get_r10();
    state->r11 = get_r11();
    state->r12 = get_r12();
    state->r13 = get_r13();
    state->r14 = get_r14();
    state->r15 = get_r15();

    return state;
}

/* execute target code with a given 16-bit cpu state at given offset.
 * This works in practice by first setting up a timer, so that we can
 * timeout the code we're calling.
 *
 * Exec happens just by dropping back to 16-bit real-mode,
 * loading registers and segments from given tgt_ctx, and finally doing
 *
 * jmp tgt_ctx->segments.cs:tgt_offset
 *
 * @param cpu_state_16b *tgt_cxt -- CPU context to use
 * @param uint16_t tgt_offset    -- Target offset for executing our code
 */
void exec_in_ctx16(cpu_state_16b *tgt_ctx, uint16_t tgt_offset) {
    cli();
    cpu_state_64b *current_state = save_cpu_state();

    // TODO: Call to asm 16-bit entry with the saved current_state
    //
    realmode_callback();
    
    
}


