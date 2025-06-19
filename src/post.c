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

#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>

#include <panic.h>

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


extern device *cmos_dev;
extern device *uart_dev;
extern console_device default_console_device;
extern device *keyboard_controller_device;
extern device *programmable_interrupt_controller;
extern device *programmable_interrupt_timer;
extern device **pci_device_array;
extern ata_ide **ata_ide_array;

/* Initialize a output device, and make it our default
 * output device for blogf, panic, etc.
 *
 * @param device *dev                    -- Target device structure
 * @param device_init_function init_func -- Init function to use for the device
 * @param tx_func write_func             -- Function to use for writing output to this device
 * @param char *name                     -- Name of our output device
 * @param 
 * @return bool true if switch succeeded
 */
bool switch_output_device(device *dev, device_init_function init_func, tx_func write_func, char *name) {
    if (dev->status != status_initialised) {
        dev->status = init_func(dev);
        dev->device_name = name;
        if (dev->status != status_initialised) {
            blogf("Failed to switch to output device %s\n", name);
        }
    }
    default_console_device.enabled = true;
    default_console_device.dev = dev;
    default_console_device.tx_func = write_func;
    blogf("Switched default output device to %s\n", dev->device_name);
    return true;
}

void post_and_init(void) {
    uart_dev = new_device(sizeof(serial_uart_device));
    switch_output_device(uart_dev, serial_init_device, serial_tx, "UART 1");

    cmos_dev                          = new_device(sizeof(cmos_data));
    programmable_interrupt_controller = new_device(sizeof(pic_full_configuration));
    keyboard_controller_device        = new_device(sizeof(ps2_8042_status));
    programmable_interrupt_timer      = new_device(0);

    initialize_device(pic_initialize, programmable_interrupt_controller, "8259/PIC", false);
    initialize_device(cmos_init, cmos_dev, "CMOS/RTC", false);
    initialize_device(kbdctl_set_default_init, keyboard_controller_device, "8042/PS2", false);
    initialize_device(pit_init, programmable_interrupt_timer, "825X/PIT", false);

    pci_device_array = calloc(32, sizeof(device **));
    uint8_t devcnt = enumerate_pci_buses(pci_device_array);
    pci_print_devtree(pci_device_array, devcnt);
    ata_ide_array = calloc(1, sizeof(ata_ide **));
    uint8_t ide_cnt = init_ata_controllers(pci_device_array, ata_ide_array, devcnt);

} 

