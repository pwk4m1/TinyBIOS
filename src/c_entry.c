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
#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>

#include <panic.h>
#include <post.h>

#include <sys/io.h>

#include <cpu/common.h>
#include <superio/superio.h>

#include <drivers/device.h>
#include <drivers/serial/serial.h>
#include <drivers/kbdctl/8042.h>
#include <drivers/pic_8259/pic.h>
#include <drivers/pit/pit.h>
#include <drivers/pci/pci.h>
#include <drivers/cmos/cmos.h>
#include <drivers/ata/ata.h>

#include <console/console.h>
#include <interrupts/interrupts.h>

#include <romcall/romcall.h>

extern void interrupt_handler_init_runtime(void);

heap_start *heap = (heap_start *)0x8000;

device *cmos_dev = 0;
device *uart_dev = 0;
console_device default_console_device = {0};
device *keyboard_controller_device = 0;
device *programmable_interrupt_controller = 0;
device *programmable_interrupt_timer = 0;
device **pci_device_array = 0;
ata_ide **ata_ide_array = 0;

/* The C entrypoint for early initialisation for {hard,soft}ware
 *
 * This function should never return.
 */
 __attribute__ ((noreturn)) void c_main(void) {
    superio_init();

    heap_start *start = (heap_start *)heap;
    if (start->start == (memory_header *)((uint64_t)start + sizeof(heap_start))) {
        hang();
    }
    heap_init((uint64_t)heap, (0x70000 - 0x8000));

    post_and_init();
    blog("Early chipset initialisation done\n");

    for (;;) { 
        blog("Hang\n");
        hang();
    }
}

