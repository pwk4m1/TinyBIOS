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
#include <sys/io.h>

#include <stdbool.h>
#include <stdint.h>

#include <drivers/device.h>
#include <drivers/pit/pit.h>

/* Read pit status for a given channel
 *
 * @param uint8_t channel -- channel to read
 * @return uint8_t status of the channel
 */

/* Setup PIT with default init.
 *
 * @param pio_device *dev -- Device info structure
 * @param char *name      -- Name of this device
 * @return bool true on success, false on error. 
 */
bool pit_init(pio_device *dev, char *name) { 
    pit_command cmd;

    cmd.access_mode      = lo_and_hi_byte;
    cmd.binary_mode      = binary;
    cmd.operating_mode   = rate_generator;
    cmd.selected_channel = channel_0;

    pit_write_command(&cmd);
    outb(0x00, 0x40);
    outb(0x10, 0x40);

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

