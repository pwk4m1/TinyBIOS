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

#ifndef __PAGING_H__
#define __PAGING_H__

#include <stdint.h>

/* Helper structures, definitions, & co shamelessly copied from
 * https://praios.lf-net.org/littlefox/lf-os_amd64/ :3
 */
// Page table entry
struct page_table_entry {
    unsigned int present            : 1;
    unsigned int writeable          : 1;
    unsigned int userspace          : 1;
    unsigned int pat0               : 1;
    unsigned int pat1               : 1;
    unsigned int accessed           : 1;
    unsigned int dirty              : 1;
    unsigned int huge               : 1;
    unsigned int global             : 1;
    unsigned int available          : 3;
    uint64_t next_base              : 40;
    unsigned int available2         : 11;
    unsigned int nx                 : 1;
} __attribute__((packed));

struct page_descriptor {
    unsigned int flags              : 30;
    unsigned char size              : 2;
    unsigned int refcount;
};

#define BASE_TO_PHYS(x)             ((char *)(x << 12))
#define PML4_INDEX(x)               (((x) >> 39) & 0x1FF)
#define PDP_INDEX(x)                (((x) >> 30) & 0x1FF)
#define PD_INDEX(x)                 (((x) >> 21) & 0x1FF)
#define PT_INDEX(x)                 (((x) >> 12) & 0x1FF)

#define LM_MSR 0xC0000080
#define ENABLE_PAGING 0x80000000
#define ENABLE_LM 0x100

void enable_paging(void);

#endif // __PAGING_H__
