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

#include <sys/io.h>

#include <cpu/common.h>
#include <superio/superio.h>

#include <mm/slab.h>

#include <drivers/device.h>
#include <drivers/serial/serial.h>
#include <drivers/kbdctl/8042.h>
#include <drivers/pic_8259/pic.h>
#include <drivers/pit/pit.h>
#include <drivers/pci/pci.h>

#include <console/console.h>

#include <interrupts/interrupts.h>
#include <interrupts/ivt.h>

extern void interrupt_handler_init_runtime(void);

device primary_com_device;
serial_uart_device sdev;
console_device default_console_device;

device keyboard_controller_device;
device programmable_interrupt_controller;
device programmable_interrupt_timer;
device pci_device_array[24];

extern const uint32_t mem_mbr;
extern const uint32_t mem_slab;
SlabHeader *slab;

/* The C entrypoint for early initialisation for {hard,soft}ware
 *
 * This function should never return.
 */
 __attribute__ ((noreturn)) void c_main(void) {
    superio_init();
    primary_com_device.device_data = &sdev;
    initialize_device(serial_init_device, &primary_com_device, "UART 1", false);
    default_console_device.enabled = (primary_com_device.status == status_initialised);
    default_console_device.dev = &primary_com_device;
    default_console_device.tx_func = serial_tx;

    blog("TinyBIOS 0.4\n");
    blog("SuperIO initialised\n");
    blogf("Default output device: %s at %xh with %d baudrate\n", 
            primary_com_device.device_name,
            sdev.base_port, (115200 / sdev.baudrate_divisor)); 

    initialize_device(pic_initialize, &programmable_interrupt_controller, "8259/PIC", false);
    initialize_device(kbdctl_set_default_init, &keyboard_controller_device, "8042/PS2", false);
    initialize_device(pit_init, &programmable_interrupt_timer, "825X/PIT", false);
    uint8_t devcnt = enumerate_pci_buses(pci_device_array);


    blog("Early chipset initialisation done, halt\n");
    for (;;) { 
        hang();
    }
}

