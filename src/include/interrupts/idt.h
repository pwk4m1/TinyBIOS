/*
 BSD 3-Clause License
 
 Copyright (c) 2025, k4m1, <me@k4m1.net>
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
#ifndef __TINY_IDT_H__
#define __TINY_IDT_H__

#include <stdlib.h>
#include <stdint.h>

enum int_gate_type {
    interrupt_gate = 0xE,
    trap_gate      = 0xF
};

typedef struct __attribute__ ((packed)) {
    unsigned index      : 13;
    unsigned use_ldt    : 1;
    unsigned privilege  : 2;
} segment_selector;

typedef struct __attribute__ ((packed)) {
    uint32_t reserved;
    uint32_t offset_high;
    uint16_t offset_mid;
    unsigned present                : 1;
    unsigned dpl                    : 2;
    unsigned zero                   : 1;
    enum int_gate_type              : 4;
    unsigned reserved_low           : 5;
    unsigned interrupt_stack_table  : 3;
    segment_selector segment;
    uint16_t offset_low;
} idt_entry;

typedef struct __attribute__((packed)) {
    uint16_t size;
    uint64_t ptr;
    idt_entry entry[256];
} int_desc_table;

/* Allocate memory for interrupt descriptor table
 *
 * @return pointer to allocated interrupt descriptor table
 */
static inline int_desc_table *new_idt() {
    return calloc(1, sizeof(int_desc_table));
}

/* Setup interrupt descriptor table to use
 *
 */
void init_idt(void); 

/* Add a new interrupt handler to idt
 *
 * @param uint64_t entry   -- Which interrupt entry is this 
 * @param uint64_t handler -- Address to interrupt handler to register
 */
void add_interrupt_handler(uint64_t entry, uint64_t handler);

#endif // __TINY_IDT_H__
