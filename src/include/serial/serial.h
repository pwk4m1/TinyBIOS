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

#include <sys/types.h>
#include <sys/io.h>

#define SERIAL_DATA(x)      (x)
#define SERIAL_IE(x)        (x + 1)
#define SERIAL_FIFO_CTRL(x) (x + 2)
#define SERIAL_LCR(x)       (x + 3)
#define SERIAL_MCR(x)       (x + 4)
#define SERIAL_LSR(x)       (x + 5)
#define SERIAL_MSR(x)       (x + 6)
#define SERIAL_SCRATCH(x)   (x + 7)

/* Helper functions for serial devices */

/* Get serial line status
 *
 * @param unsigned short port -- port to read status from
 * @return unsigned char status
 */
inline unsigned char serial_get_line_status(unsigned short port) {
    return inb(SERIAL_LSR(port));
}

/* Disable interrupts for device
 *
 * @param unsigned short port -- Device from which to disable interrupts from
 */
inline void serial_interrupts_disable(unsigned short port) {
    outb(SERIAL_IE(port), 0);
}

/* Enable interrupts for device
 *
 * @param unsigned short port -- Device from which to enable interrupts from
 */
inline void serial_interrupts_enable(unsigned short port) {
    outb(SERIAL_IE(port), 0);
}

/* Get serial modem status
 *
 * @param unsigned short port -- port to read status from
 * @return unsigned char status
 */
inline unsigned char serial_get_modem_status(unsigned short port) {
    return inb(SERIAL_MSR(port));
}

/* Set Divisor Latch Access Bit
 * 
 * @param unsigned short port -- on which device to set DLAB
 */
inline void serial_dlab_set(unsigned short port) {
    outb(SERIAL_FIFO_CTRL(port), 0x80);
}

/* Clear Divisor Latch Access Bit
 *
 * @param unsigned short port -- on which device to clear DLAB
 */
inline void serial_dlab_clear(unsigned short port) {
    unsigned char stat = inb(SERIAL_FIFO_CTRL(port));
    stat &= ~(0x80);
    outb(SERIAL_FIFO_CTRL(port), 0x80);
}

/* Set baud rate for device
 *
 * @param unsigned short port -- device to set baudrate for
 * @param unsigned short brd  -- baud rate divisor
 */
inline void serial_set_baudrate(unsigned short port, unsigned short brd) {
    serial_dlab_set(port);
    outb(SERIAL_DATA(port), (unsigned char)(brd & 0x00FF));
    outb(SERIAL_IE(port), (unsigned char)(brd >> 8));
    serial_dlab_clear(port);
}

/* Set line control for device
 *
 * @param unsigned short port -- device to set lc for
 * @param unsigned char lcr   -- line control value
 */
inline void serial_set_linecontrol(unsigned short port, unsigned char lcr) {
    outb(SERIAL_LCR(port), lcr);
}

/* Check if we have faulty device. We'll do this by writing value 
 * FA to scratch register, and then reading the value back. IF
 * it's changed we know we've faulty device connected.
 * 
 * @param unsigned short port -- Device to test
 * @return non-zero if device is faulty
 */
inline unsigned char serial_device_is_faulty(unsigned short port) {
    outb(SERIAL_SCRATCH(port), 0xfa);
    return (inb(SERIAL_SCRATCH(port)) != 0xfa);
}

/* Poll for serial port until line is empty.
 *
 * @param unsigned short port -- Port to wait for
 * @return 0 when line is empty, or non-zero if timed out.
 */
unsigned char serial_wait_for_tx_empty(unsigned short port);

/* Initialise a serial port for comms
 *
 * @param unsigned short port -- Device to initialise
 * @param unsigned short brd  -- baud rate divisor
 * @param unsigned char  lcr  -- line control value
 * @return 0 on success or non-zero on error
 */
unsigned char serial_init_device(unsigned short port);

/* Write a string over serial line
 *
 * @param unsigned short port -- Device to write to
 * @param const unsigned char *msg  -- Absolute address to string to write
 * @param const ssize_t size -- size of message to print
 * @return amount of bytes transmitted
 */
ssize_t serial_tx(unsigned short port, const unsigned char *msg, const ssize_t size);

/* Receive a string over serial line
 *
 * @param unsigned short port -- Device to read from
 * @param unsigned char *dst -- Buffer to read to
 * @param const ssize_t size -- How many bytes to read
 * @return amount of bytes received 
 */
ssize_t serial_rx(unsigned short port, unsigned char *dst, const ssize_t size);

#endif // __SERIAL_H__
