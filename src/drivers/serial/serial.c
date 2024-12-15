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

#include <stddef.h>
#include <sys/io.h>

#include <drivers/device.h>
#include <drivers/serial/serial.h>

#include <stdbool.h>

/* interrupt handler for serial port driver
 *
 */
void __attribute__((section(".rom_int_handler"))) serial_int_handler(void) {

}

/* Poll for serial port until line is empty.
 *
 * @param unsigned short port -- Port to wait for
 * @return 0 when line is empty, or non-zero if timed out.
 */
unsigned char serial_wait_for_tx_empty(unsigned short port) {
    for (int i = 0; i < 5000; i++) {
        if ((serial_get_line_status(port) & 0x01) == 0) {
            return 0;
        }
        asm volatile("nop":::"memory");
    }
    return 1;
}

/* Initialise a serial port for comms
 *
 * @param unsigned short port -- Device to initialise
 * @param unsigned short brd  -- baud rate divisor
 * @param unsigned char  lcr  -- line control value
 * @return 0 on success or non-zero on error
 */
bool serial_init_device(pio_device *dev, unsigned short port, unsigned short brd, unsigned char lcr, char *name) {
    serial_uart_device *sdev = (serial_uart_device *)dev->device_data;
    serial_interrupts_disable(port);
    serial_set_baudrate(port, brd);
    serial_set_linecontrol(port, lcr);
    if (serial_device_is_faulty(port)) {
        return false;
    }
    outb(0x0F, SERIAL_MCR(port));

    // Enable FIFO, clear with 14 byte treshold 
    outb(0xC7, SERIAL_FIFO_CTRL(port));

    dev->status = initialised;
    dev->device_name = name;
    sdev->base_port = port;
    sdev->baudrate_divisor = brd;
    sdev->fifo_control = 0xC7;
    return true;
}

/* Write a string over serial line
 *
 * @param unsigned short port -- Device to write to
 * @param const unsigned char *msg  -- Absolute address to string to write
 * @return amount of bytes transmitted
 */
size_t serial_tx(unsigned short port, const char *msg, size_t len) {
    size_t i;

    for (i = 0; i < len; i++) {
        do { } while (serial_wait_for_tx_empty(port));
        if (msg[i] == '\n') {
            outb('\r', port);
            do { } while (serial_wait_for_tx_empty(port));
        }
        outb(msg[i], port);
    }
    return i;
}

/* Receive a string over serial line
 *
 * @param unsigned short port -- Device to read from
 * @param unsigned char *dst -- Buffer to read to
 * @param const size_t size -- How many bytes to read
 * @return amount of bytes received 
 */
size_t serial_rx(unsigned short port, char *dst, const size_t size) {
    size_t i;
    for (i = 0; i < size; i++) {
        while (serial_wait_for_tx_empty(port) != 0) {
            continue;
        }
        dst[i] = inb(SERIAL_DATA(port));
    }
    return i;
}


