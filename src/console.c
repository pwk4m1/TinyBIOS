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
#include <stdarg.h>

#include <sys/io.h>
#include <superio/superio.h>

#include <drivers/device.h>
#include <drivers/serial/serial.h>

#include <console/console.h>

#include <string.h>
#include <itoa.h>

extern console_device default_console_device;

/* Write log message over default output device
 *
 * @param console_device *dev -- device to use for output
 * @param char *msg -- message to print
 *
 */
void blog(char *msg) {
    if (default_console_device.enabled == false) {
        return;
    }
    serial_uart_device *udev = default_console_device.pio_dev->device_data;
    default_console_device.tx_func(udev->base_port, msg, strlen(msg));
}

/* Print a sinlge byte over default output device
 *
 * @param char c -- character to write
 */
static inline void bputchar(char c) {
    if (default_console_device.enabled == false) {
        return;
    }

    serial_uart_device *udev = default_console_device.pio_dev->device_data;
    default_console_device.tx_func(udev->base_port, &c, 1);
}

/* Print single integer over default output device
 *
 * @param int d -- integer to print
 * @param int base -- base number
 */
static inline void bputint(int d, int base) {
    char tmp[17];
    memset(tmp, 0, 17);

    if (base == 16) {
        itoah(d, tmp);
    } else {
        itoa(d, tmp);
    }

    char *start = tmp;
    for (int i = 0; i < 10; i++) {
        if (*start != 0x30)
            break;
        start++;
    }
    blog(start);
}

/* log messages, now with format string!
 *
 * @param const char *restrict format
 * @param ... :3
 * @return int bytes written
 */
int blogf(const char *restrict format, ...) {
    if (default_console_device.enabled == false) {
        return 0;
    }

    va_list ap;
    int written = 0;
    int d;
    char c;
    char *s;
    bool escaped = false;

    va_start(ap, format);

    do {
        if (escaped) {
            bputchar(*format);
            escaped = false;
        } else {
            if (*format == '\\') {
                escaped = true;
            } else if (*format == '%') {
                format++;
                switch (*format) {
                case 's':
                    s = va_arg(ap, char *);
                    blog(s);
                    written += strlen(s);
                    break;
                case 'x':
                    d = va_arg(ap, int);
                    bputint(d, 16);
                    written += sizeof(int);
                    break;
                case 'd':
                    d = va_arg(ap, int);
                    bputint(d, 10);
                    written += sizeof(int);
                    break;
                case 'c':
                    c = (char) va_arg(ap, int);
                    bputchar(c);
                    written++;
                    break;
                default:
                    format--;
                    bputchar(*format);
                    written++;
                }
            } else {
                bputchar(*format);
                written++;
            }
        }
    } while (*format++);

    va_end(ap);
    return written;
}

