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
#ifndef __CPU_INST_COMMON_H__
#define __CPU_INST_COMMON_H__

#include <stdint.h>
#include <sys/io.h>

static inline uint64_t get_cr0(void) {
    uint64_t r;
    asm volatile("mov   %0, cr0":"=r"(r));
    return r;
}

static inline void set_cr0(uint64_t v) {
    asm volatile("mov   cr0, %0"::"r"(v));
}

static inline uint64_t get_cr3(void) {
    uint64_t r;
    asm volatile("mov   %0, cr3":"=r"(r));
    return r;
}

static inline void set_cr3(uint64_t v) {
    asm volatile("mov   cr3, %0"::"r"(v));
}

static inline uint64_t get_cr4(void) {
    uint64_t r;
    asm volatile("mov   %0, cr4":"=r"(r));
    return r;
}

static inline void set_cr4(uint64_t v) {
    asm volatile("mov   cr4, %0"::"r"(v));
}

static inline uint64_t rdmsr(uint64_t msr) {
    uint64_t ret;
    asm volatile(
            "mov   ecx, %0;"
            "rdmsr;"
            "mov   %1, eax;"
            :"=r"(ret)
            :"r"(msr)
            :"eax","ecx"
    );
    return ret;
}

static inline void wrmsr(uint64_t msr, uint64_t val) {
    asm volatile(
            "mov    ecx, %0;"
            "mov    eax, %1;"
            "wrmsr;"
            ::"r"(msr),"r"(val)
            :"eax","ecx"
    );
}

#endif // __CPU_INST_COMMON_H__
