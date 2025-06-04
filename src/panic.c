/*
 BSD 3-Clause License
 
 Copyright (c) 2025, k4m1
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
#include <console/console.h>

#include <stdarg.h>
#include <panic.h>

static inline void dump_print_register(char *name, uint64_t val) {
    int written = blogf("%s=%016x ", name, val);
    if (written <= 25) blog(" ");
}

#define get_reg(name) asm volatile("mov   %0, " #name ";":"=r"(reg_for_dump))
#define dump(name) get_reg(name); dump_print_register(#name, reg_for_dump)
#define dump_line(a, b, c, d) blog("\t"); dump(a); dump(b); dump(c); dump(d); blog("\n")

#define dump_seg(name) reg_for_dump=read_##name(); dump_print_register(#name, reg_for_dump);
#define dump_seg_line(a, b, c, d) blog("\t"); dump_seg(a); dump_seg(b); dump_seg(c); dump_seg(d); blog("\n")

static inline void __attribute__((always_inline)) dump_registers() {
    blog("CPU State: \n");
    uint64_t reg_for_dump;
    dump_line(rax, rbx, rcx, rdx);
    dump_line(rsi, rdi, rbp, rsp);
    dump_line(r8, r9, r10, r11);
    dump_line(r12, r13, r14, r15);
    dump_seg_line(cs, es, ds, ss);
    blog("\t");
    dump(cr3);
    dump(cr4);
    blog("\n");
}

static inline void __attribute__((always_inline)) dump_stack() {
    blog("STACK: \n");
    uint64_t *rsp = (uint64_t *)get_gpr(rsp);
    blogf("\t%016x %016x %016x %016x\n\t%016x %016x %016x %016x\n",
            rsp[0], rsp[1], rsp[2], rsp[3], rsp[4], rsp[5], rsp[6], rsp[7]);

    blogf("\t%016x %016x %016x %016x\n\t%016x %016x %016x %016x\n",
            rsp[8], rsp[9], rsp[10], rsp[11], rsp[12], rsp[13], rsp[14], rsp[15]);
}

void __attribute__((noreturn)) panic(const char *restrict msg, ...) {
    blog("\n*** PANIC ***\nReason: ");
    va_list args;
    va_start(args, msg);
    vfblogf(msg, args);
    va_end(args);
    dump_registers();
    dump_stack();
    hang();
}

