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

#include <mm/paging.h>
#include <mainboards/memory_init.h>
#include <stdint.h>

#include <panic.h>

#include <stdint.h>

static page_table_entry *pml4;
static page_table_entry *pdpt;
static page_table_entry *pte_array;

static uint64_t memory_size_in_megabytes(memory_map *mem_map) {
    uint64_t ret = 0;
    uint64_t tmp = 0;

    for (uint8_t i = 0; i < mem_map->count; i++) {
        tmp += mem_map->entry[i]->size;
        if (tmp >= (1024 * 1024)) {
            ret++;
            tmp = 0;
        }
    }
    return ret;
}

static void map_page(page_table_entry *entry, void *addr) {
    uint64_t v_addr = ((uint64_t)addr) >> 22;
    entry->addr = v_addr;
    entry->present = 1;
    entry->writable = 1;
    entry->unprivileged = 1;
}

bool map_address(void *addr, uint64_t size) {
    if (size & 0x00000FFF) {
        blogf("refusing to map unaligned memory: 0x%x bytes\n", size);
        return false;
    }
    uint64_t vaddr = (uint64_t)addr;

    return true;
}

void init_paging(memory_map *mem_map) {
    // 1 page = 4 KB -> mbytes / 0x1000
    //
    uint64_t mbytes_to_map = memory_size_in_megabytes(mem_map);
    mbytes_to_map *= 1024; // megabytes -> kilobytes 
    uint64_t pages_to_map = mbytes_to_map / 0x1000;
    uint64_t pdpt_cnt = pages_to_map / 1024;
    uint64_t pml4_cnt = pdpt_cnt / 1024;

    if (!pdpt_cnt) 
        pdpt_cnt = 1;
    if (!pml4_cnt) 
        pml4_cnt = 1;

    pte_array = alloc_map(pages_to_map);
    pdpt = alloc_map(pdpt_cnt);
    pml4 = alloc_map(pml4_cnt);

    if (!pte_array || !pdpt || !pml4) {
        panic_oom("Failed to allocate memory for paging structures");
    }

    map_page(&pdpt[0], &pte_array[0]);
    map_page(&pml4[0], &pdpt[0]);

    uint64_t pdpt_off = 0;
    uint64_t pml4_off = 0;

    for (uint64_t page = 0; page < pages_to_map; page++) {
        map_page(&pte_array[page], (void *)(page * 0x1000));
        if (page && ((page % 1024) == 0)) {
            pdpt_off++;
            map_page(&pdpt[pdpt_off], &pte_array[page]);
        }
        if (pdpt_off && ((pdpt_off % 1024) == 0)) {
            pml4_off++;
            map_page(&pml4[pml4_off], &pdpt[pdpt_off]);
        }
    }
    set_pml4(pml4);

    return;
}

