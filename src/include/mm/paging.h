/*
 BSD 3-Clause License
 
 Copyright (c) 2025, k4m1  <me@k4m1.net>
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
#ifndef __TINY_PAGING_H__
#define __TINY_PAGING_H__

#include <cpu/common.h>

#include <mainboards/memory_init.h>

#include <stdint.h>
#include <stdlib.h>

/**
 * Helper structures for page tables and co
 * All of the tables use more or less the same format.
 */
typedef struct __attribute__ ((packed)) {
    unsigned present        : 1;
    unsigned writable       : 1;
    unsigned unprivileged   : 1;
    unsigned write_through  : 1;
    unsigned cache_disable  : 1;
    unsigned accessed       : 1;
    unsigned resvd1         : 5;
    uint64_t addr           : 58;
} page_table_entry;

/**
 * Helpers to get page table entries in use
 */
static inline page_table_entry * __attribute__((always_inline)) get_pml4(void) {
    page_table_entry *pml4 = 0;
    asm volatile("mov   %0, cr3":"=r"(pml4));
    return pml4;
}

static inline void __attribute__((always_inline)) set_pml4(page_table_entry *pml4) {
    asm volatile("mov    cr3, %0"::"r"(pml4));
}

static inline page_table_entry *alloc_map(uint64_t entry_count) {
    return (page_table_entry *)calloc(entry_count, sizeof(page_table_entry));
}

void init_paging(memory_map *mem_map);

#endif
