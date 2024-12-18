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
#include <sys/types.h>
#include <sys/io.h>

#include <stdbool.h>

#include <drivers/device.h>
#include <drivers/pic_8259/pic.h>
#include <drivers/pit/pit.h>

#include <interrupts/ivt.h>

#include <console/console.h>

extern void pit_irq_entry(void);

pit_config pit_current_config = {0};

/* Initialise PIT to 1193182 hz with rate generator.
 *
 * @param pit_device *dev -- Device to use for pit
 * @param char *name      -- name of this device
 * @return bool true on success, false on error.
 */
bool pit_initialize(pio_device *dev, char *name) {
    dev->device_name = name;
    dev->device_data = &pit_current_config;
    dev->type = device_other;

    pit_current_config.channel = channel_0;
    pit_current_config.access = lohi;
    pit_current_config.mode = rate_generator;
    pit_current_config.bcd_enabled = 0;
    pit_set_config(&pit_current_config);
    
    uint8_t cs = pit_get_channel_state(&pit_current_config, 1);
    pit_config *readback = (pit_config *)(&cs);

    if (readback->mode != pit_current_config.mode) {
        // PIT is faulty or missing alltogether ...
        if ((readback->mode == 0xFF) || readback->mode == 0x00) {
            // All high? Assuming it's pull-ups and not a connected device
            // or pull downs and same.
            dev->status = not_present;
        } else {
            dev->status = faulty;
        }
        return false;
    }
    register_int_handler(0x0008, (uint16_t)(((uint64_t)pit_irq_entry) & 0x0000FFFF), 8);
    blogf("Setting irq handler to segment: 0x%x, offset: 0x%x\n", 0x08, pit_irq_entry);
    pic_unmask_irq(0);
    dev->status = initialised;
    return true;
}

/* PIT Interrupt handler 
 *
 */
void __attribute__((section(".rom_int_handler"))) pit_int_handler(void) {
    asm volatile("mov eax, 0x12345678");
    asm volatile("cli");
    asm volatile("hlt");
    do {} while (1);
}



