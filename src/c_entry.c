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
#include <superio/superio.h>

#include <mm/slab.h>

#include <drivers/device.h>
#include <drivers/serial/serial.h>
#include <drivers/kbdctl/8042.h>
#include <drivers/pic_8259/pic.h>
#include <drivers/pit/pit.h>

#include <console/console.h>

#include <interrupts/interrupts.h>
#include <interrupts/ivt.h>

extern void interrupt_handler_init_runtime(void);

pio_device primary_com_device;
serial_uart_device sdev;
console_device default_console_device;

pio_device keyboard_controller_device;
pio_device programmable_interrupt_controller;
pio_device programmable_interrupt_timer;

/* Helper to initialise uart 1 for us.
 *
 * @param console_device *default_console_device -- default console device structure
 */
static inline void init_uart1(console_device *default_console_device) {
    default_console_device->pio_dev = &primary_com_device;
    default_console_device->tx_func = &serial_tx;
    if (serial_init_device(&primary_com_device, 
                SERIAL_COM_PRIMARY, 
                COM_DEFAULT_BRD, 
                COM_DEFAULT_LINE_CTL, 
                "UART 1") == false) 
    {
        default_console_device->enabled = false;
    } else {
        default_console_device->enabled = true;
    }
}

/* Wrapper for calling various PIO device initialisation routines
 *
 * @param bool (*init)(pio_device *dev) -- pointer to device initialisation routine
 * @param pio_device *dev -- pio device structure for this device
 * @param char *name -- device name
 */
static void init_device(bool (*init)(pio_device *dev, char *name), pio_device *dev, char *name) {
    blogf("Initialising %s... ", name);
    if (init(dev, name) == true) {
        blog("ok\n");
    } else {
        blog(" failed\n");
    }
}

/* The C entrypoint for early initialisation for {hard,soft}ware
 *
 * This function should never return.
 */
 __attribute__ ((noreturn)) void c_main(void) {
    superio_init();
    primary_com_device.device_data = &sdev;
    init_uart1(&default_console_device);

    blog("TinyBIOS 0.4\n");
    blog("SuperIO initialised\n");

    blogf("Default output device: %s at %xh with %d baudrate\n", 
            primary_com_device.device_name,
            sdev.base_port, (115200 / sdev.baudrate_divisor)); 

    init_device(pic_initialize, &programmable_interrupt_controller, "8259 PIC");

    init_device(kbdctl_set_default_init, 
            &keyboard_controller_device, 
            "8042 ps2 controller");

    init_device(enable_a20line, &keyboard_controller_device, "high memory");
    init_device(pit_init, &programmable_interrupt_timer, "825X PIT");
    blog("Early chipset initialisation done\n");

    asm volatile("sti");

    for (;;) { 
        for (int i = 0; i < 0xffffff; i++) { asm volatile("nop"); }
        uint8_t irr = pic_read_irr();
        uint8_t isr = pic_read_isr();

        blogf("irr: %x, isr: %x\n", irr, isr);
        uint16_t cnt = pit_read_count(pit_channel_0_port);
        blogf("pit count: %x\n", cnt);
    }
}

