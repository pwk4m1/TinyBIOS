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

#include <cpu/paging.h>
#include <cpu/common.h>

#include <console/console.h>

#include <string.h>

struct vm_table {
    struct page_table_entry entries[512];
} __attribute__((packed));

#define paging_sym_pdt 0x10000

void enable_paging(void) {
    struct page_table_entry *pdpt = (struct page_table_entry *)paging_sym_pdt;
    struct vm_table *pde;
    struct vm_table *pt;
    memset((void *)paging_sym_pdt, 0, 0x1000);
    blogf("PDPT at 0x%x\n", pdpt);

    pdpt->present = 1;
    pdpt->writeable = 1;
    pdpt->next_base = (uint64_t)paging_sym_pdt + 0x1000;
    blogf("pdpt->next: 0x%x\n", (uint64_t)pdpt->next_base);
    pde = (struct vm_table *)pdpt->next_base;
    memset(pde, 0, sizeof(struct vm_table));
    

    set_cr3(paging_sym_pdt);
    uint64_t cr4 = get_cr4();
    cr4 |= 0x20;
    set_cr4(cr4);

    uint64_t LM = rdmsr(LM_MSR);
    LM |= ENABLE_LM;
    wrmsr(LM_MSR, LM);

    volatile uint64_t cr0 = get_cr0();
    cr0 |= ENABLE_PAGING;
    // set_cr0(cr0);
    asm volatile("cli");
    asm volatile("hlt");
}

