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

#include <interrupts/idt.h>
#include <drivers/pic_8259/pic.h>
#include <cpu/common.h>

#include <stdint.h>
#include <string.h>

#include <panic.h>

int_desc_table *idt;
extern void default_int_handler(void); 

/* Setup interrupt descriptor table to use
 *
 */
void init_idt(void) { 
    idt = new_idt();
    if (!idt) {
        panic_oom("No enough memory to setup interrupt handling\n");
    }
    idt->ptr = (uint64_t)(&idt->entry[0]); 
    idt->size = (256 * 16) - 1;
    for (int i = 0; i < 256; i++) {
        add_interrupt_handler(i, (uint64_t)default_int_handler);
    }
    write_idtr((void *)idt);
}

/* Add a new interrupt handler to idt
 *
 * @param uint64_t entry   -- Which interrupt entry is this 
 * @param uint64_t handler -- Address to interrupt handler to register
 */
void add_interrupt_handler(uint64_t entry, uint64_t handler) {

    memset((void *)&idt->entry[entry], 0, sizeof(idt_entry));

    uint16_t lo = (uint16_t)handler;
    uint16_t mi = (uint16_t)(handler >> 16);
    uint32_t hi = (uint32_t)(handler >> 32);

    idt->entry[entry].offset_low = lo;
    idt->entry[entry].offset_mid = mi;
    idt->entry[entry].offset_high = hi;
    idt->entry[entry].present = 1;
    idt->entry[entry].segment.privilege = 0;
    idt->entry[entry].segment.use_ldt = 0;
    idt->entry[entry].segment.index = 0x10;
    idt->entry[entry].int_gate_type = 0x0E; 

}

