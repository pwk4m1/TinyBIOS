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

#include <drivers/device.h>
#include <drivers/serial/serial.h>
#include <drivers/kbdctl/8042.h>

#include <console/console.h>

pio_device primary_com_device;
serial_uart_device sdev;
console_device default_console_device;

pio_device keyboard_controller_device;
ps2_8042_status keyboard_controller_status;

/* The C entrypoint for early initialisation for {hard,soft}ware so
 * that we can move to 64-bit long mode.
 *
 * This function should never return.
 */
 __attribute__ ((noreturn)) void c_main(void) {
    superio_init();
    primary_com_device.device_data = &sdev;
    keyboard_controller_device.device_name = "8042\n";
    keyboard_controller_device.device_data = &keyboard_controller_status;
    default_console_device.pio_dev = &primary_com_device;
    default_console_device.tx_func = &serial_tx;

    (void)serial_init_device(&primary_com_device, 0x03f8, 0x0003, 0x03, "UART 1");
    blog("TinyBIOS 0.4\n");
    blog("SuperIO initialised\n");
    blog("UART 1 (0x03f8) set to be default output device\n");
    int stat = kbdctl_set_default_init(&keyboard_controller_device);
    if (stat) {
        blog("kbdctl init failed\n");
    } else {
        blog("8042 initialisation completed\n");
    }

    blogf("test: %s\n", "Hello");
    blogf("test2: %%\n");

    asm volatile("cli":::"memory");
    for (;;) { }
}


