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

#ifndef __SERIAL_H__
#define __SERIAL_H__

#include <stddef.h>
#include <stdbool.h>

#include <sys/io.h>

#include <drivers/device.h>
#include <console/console.h>

#define SERIAL_DATA(x)      (x)
#define SERIAL_IE(x)        (x + 1)
#define SERIAL_FIFO_CTRL(x) (x + 2)
#define SERIAL_LCR(x)       (x + 3)
#define SERIAL_MCR(x)       (x + 4)
#define SERIAL_LSR(x)       (x + 5)
#define SERIAL_MSR(x)       (x + 6)
#define SERIAL_SCRATCH(x)   (x + 7)

// Primary serial console port
#define SERIAL_COM_PRIMARY  0x03F8
// default baud rate divisor for 9600 brate
#define COM_DEFAULT_BRD     0x000C
// default line control value
#define COM_DEFAULT_LINE_CTL 0x03 

/* structure for line status register
 */
typedef union {
    struct __attribute__((packed)) {
        unsigned int data_ready    : 1;
        unsigned int overrun_err   : 1;
        unsigned int parity_err    : 1;
        unsigned int framing_err   : 1;
        unsigned int break_ind     : 1;
        unsigned int tx_ready      : 1;
        unsigned int tx_empty      : 1;
        unsigned int impending_err : 1;
    };
    uint8_t raw;
} serial_line_status;

/* Structure for interrupt identification values
 *
 */
typedef struct __attribute__((packed)) {
    unsigned int interrupt_pending   : 1;
    unsigned int interrupt_state     : 2;
    unsigned int timeout_int_pending : 1;
    unsigned int reserved            : 2;
    unsigned int fifo_buffer_state   : 2;
} serial_int_id_register;

/* Structure for serial/uart device related data
 *
 * @member unsigned short base_port        -- which com-port is this
 * @member unsigned short baudrate_divisor -- divisor value for set baud rate
 * @member unsigned char line_control      -- line control settings
 * @member unsigned char fifo_control      -- fifo control settings 
 */
typedef struct {
    unsigned short base_port;

    // baud rate, LCR, and other configuration values
    unsigned short baudrate_divisor;
    unsigned char line_control;
    unsigned char fifo_control;

} serial_uart_device;

/* Helper functions for serial devices */

/* Get serial line status
 *
 * @param unsigned short port -- port to read status from
 * @return unsigned char status
 */
static inline unsigned char serial_get_line_status(unsigned short port) {
    return inb(SERIAL_LSR(port));
}

/* Disable interrupts for device
 *
 * @param unsigned short port -- Device from which to disable interrupts from
 */
static inline void serial_interrupts_disable(unsigned short port) {
    outb(SERIAL_IE(port), 0);
}

/* Enable interrupts for device
 *
 * @param unsigned short port -- Device from which to enable interrupts from
 */
static inline void serial_interrupts_enable(unsigned short port) {
    outb(SERIAL_IE(port), 0);
}

/* Get serial modem status
 *
 * @param unsigned short port -- port to read status from
 * @return unsigned char status
 */
static inline unsigned char serial_get_modem_status(unsigned short port) {
    return inb(SERIAL_MSR(port));
}

/* Set Divisor Latch Access Bit
 * 
 * @param unsigned short port -- on which device to set DLAB
 */
static inline void serial_dlab_set(unsigned short port) {
    outb(SERIAL_FIFO_CTRL(port), 0x80);
}

/* Clear Divisor Latch Access Bit
 *
 * @param unsigned short port -- on which device to clear DLAB
 */
static inline void serial_dlab_clear(unsigned short port) {
    unsigned char stat = inb(SERIAL_FIFO_CTRL(port));
    stat &= ~(0x80);
    outb(SERIAL_FIFO_CTRL(port), stat);
}

/* Set baud rate for device
 *
 * @param unsigned short port -- device to set baudrate for
 * @param unsigned short brd  -- baud rate divisor
 */
static inline void serial_set_baudrate(unsigned short port, unsigned short brd) {
    serial_dlab_set(port);
    outb(SERIAL_DATA(port), (unsigned char)(brd & 0x00FF));
    outb(SERIAL_IE(port), (unsigned char)((brd >> 8) & 0x00FF));
    serial_dlab_clear(port);
}

/* Set line control for device
 *
 * @param unsigned short port -- device to set lc for
 * @param unsigned char lcr   -- line control value
 */
static inline void serial_set_linecontrol(unsigned short port, unsigned char lcr) {
    outb(lcr, SERIAL_LCR(port));
}

/* Check if we have faulty device. We'll do this by writing value 
 * FA to scratch register, and then reading the value back. IF
 * it's changed we know we've faulty device connected.
 * 
 * @param unsigned short port -- Device to test
 * @return non-zero if device is faulty
 */
static inline unsigned char serial_device_is_faulty(unsigned short port) {
    outb(0x1e, SERIAL_MCR(port));
    outb(0xae, SERIAL_DATA(port));
    return (inb(SERIAL_DATA(port)) != 0xae);
}

/* Poll for serial port until line is empty.
 *
 * @param unsigned short port -- Port to wait for
 * @return 0 when line is empty, or non-zero if timed out.
 */
unsigned char serial_wait_for_tx_empty(unsigned short port);

/* Initialise a serial port for comms
 *
 * @param device *dev     -- pointer to device structure
 * @return enum DEVICE_STATUS status
 */
enum DEVICE_STATUS serial_init_device(device *dev);

/* Write a string over serial line
 *
 * @param unsigned short port -- Device to write to
 * @param const unsigned char *msg  -- Absolute address to string to write
 * @param const size_t size -- size of message to print
 * @return amount of bytes transmitted
 */
size_t serial_tx(unsigned short port, const char *msg, size_t len);

/* Receive a string over serial line
 *
 * @param unsigned short port -- Device to read from
 * @param unsigned char *dst -- Buffer to read to
 * @param const size_t size -- How many bytes to read
 * @return amount of bytes received 
 */
size_t serial_rx(unsigned short port, char *dst, const size_t size);

/* printf() over serial line 
 *
 * @param unsigned short port -- Device to write to
 * @param const unsigned char *msg  -- Absolute address to string to write
 * @param const size_t size -- size of message to print
 * @return amount of bytes transmitted
 */
int serprintf(const char *restrict format, ...);

static inline void uart_print_info(device *dev) {
    serial_uart_device *sdev = dev->device_data;
    blogf("%s: %04x / %04x baud\n", dev->device_name, sdev->base_port, (115200 / sdev->baudrate_divisor));
}

#endif // __SERIAL_H__
