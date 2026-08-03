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

#include <mm/slab.h>
#include <mm/paging.h>
#include <mainboards/memory_init.h>
#include <stdint.h>

#include <panic.h>

#include <stdint.h>
#include <string.h>

static const uint64_t pd_addr = 0xc000;
static const uint64_t pd_size = 1024 * sizeof(page_table_entry);

static const uint64_t pml4_addr = 0xa000;
static const uint64_t pml4_size  = 512 * sizeof(page_table_entry);

static const uint64_t page_table_addr = 0x10000;
static const uint64_t page_table_size = (0x50000 - 0x10000);
static SlabHeader *page_table_pool = (SlabHeader *)(page_table_addr - sizeof(SlabHeader) - 4); 

static page_table_entry *pd = (page_table_entry *)pd_addr;
static page_table_entry *pml4 = (page_table_entry *)pml4_addr;

static page_table_entry *get_pd(uint64_t idx) {
    return (page_table_entry *)(&pd[idx]);
}

static page_table_entry *get_pte(page_table_entry *pt, uint64_t idx) {
    return (page_table_entry *)(&pt[idx]);
}

static page_table_entry *get_pt_from_pd(page_table_entry *pde) {
    return (page_table_entry *)( (*(uint64_t *)pde) & 0xFFFFF000);
}

static page_table_entry *alloc_page_table(void) {
    return (page_table_entry *)slab_alloc(page_table_pool);
}

static void populate_entry(page_table_entry *e, void *addr, bool write, bool present) {
    uint64_t i_addr = (uint64_t)addr;
    i_addr &= 0x00000000FFFFF000;
    memset(e, 0, sizeof(page_table_entry));
    e->writable = write;
    e->present = present;
    e->addr = (i_addr >> 12);
}

bool map_page(void *physical, void *virtual) {
    uint64_t pd_idx = ((uint64_t)virtual >> 22);
    if (pd_idx > (pml4_size * pd_size)) {
        return false;
    }
    page_table_entry *pd_e = get_pd(pd_idx);
    page_table_entry *pt = NULL;
    if (!pd_e->present) {
        pt = alloc_page_table();
        if (!pt) {
            return false;
        }
        populate_entry(pd_e, pt, 1, 1);
    } else {
        pt = get_pt_from_pd(pd_e);
    }
    uint64_t pt_idx = ((uint64_t)virtual >> 12) & 0x03FF;
    page_table_entry *pt_e = get_pte(pt, pt_idx);

    if (pt_e->present) {
    }

    populate_entry(pt_e, physical, 1, 1);

    return true;
}

void init_paging(memory_map *mem_map) {
    // 1 page = 4 KB -> mbytes / 0x1000
    //
    memset((void *)pd_addr, 0, pd_size);
    memset((void *)pml4_addr, 0, pml4_size);
    memset((void *)page_table_pool, 0, (1024 * sizeof(page_table_entry) + sizeof(SlabHeader) + 4));
    init_slab(page_table_addr - sizeof(SlabHeader) - 4, page_table_addr + page_table_size, (1024 * sizeof(page_table_entry)));

    // Identity map all of the low memory
    for (uint64_t addr = 0; addr < 0x100000; addr += 0x1000) {
        bool stat = map_page((void *)addr, (void *)addr);
        if (stat == false) {
            panic("Mapping failed\n");
        }
    }

    // Map rest of the memory we're aware of (if any)
    //
    for (uint64_t idx = 0; idx < mem_map->count; idx++) {
        if (mem_map->entry[idx]->type != 1) {
            continue;
        }
        if (mem_map->entry[idx]->addr < 0x100000) {
            continue;
        }
        uint64_t page_cnt = (mem_map->entry[idx]->size / 0x1000);
        uint64_t addr = mem_map->entry[idx]->addr & 0xFFFFF000;
        do {
            bool got = map_page((void *)addr, (void *)addr);
            if (got == false) {
                break;
            }
            addr += 0x1000;
        } while (page_cnt--);
    }

    page_table_entry *pml4e = (page_table_entry *)(((uint64_t)pml4) & 0xFFFFF000);
    page_table_entry *pde = (page_table_entry *)pd_addr;
    populate_entry(pml4e, pde, 1, 1);

    set_pml4(pml4e);

    return;
}

