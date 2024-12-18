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
#ifndef __PIT_H__
#define __PIT_H__

#include <sys/types.h>
#include <sys/io.h>

#include <drivers/device.h>

#include <stdint.h>

#define PIT_BP   0x40
#define PIT_CMDP 0x43

/* PIT Channel selection, 
 * set to readback to read back pit command byte from 0x43.
 */
enum pit_channel {
    channel_0,
    channel_1,
    channel_2,
    read_back
};

/*
 *  0 0 = Latch count value command
 *  0 1 = Access mode: lobyte only
 *  1 0 = Access mode: hibyte only
 *  1 1 = Access mode: lobyte/hibyte
 */
enum pit_access {
    latch_count,
    lo_only,
    hi_only,
    lohi
};

/*
 * 0 0 0 = Mode 0 (interrupt on terminal count)
 * 0 0 1 = Mode 1 (hardware re-triggerable one-shot)
 * 0 1 0 = Mode 2 (rate generator)
 * 0 1 1 = Mode 3 (square wave generator)
 * 1 0 0 = Mode 4 (software triggered strobe)
 * 1 0 1 = Mode 5 (hardware triggered strobe)
 * 1 1 0 = Mode 2 (rate generator, same as 010b)
 * 1 1 1 = Mode 3 (square wave generator, same as 011b)
 */
enum pit_op_mode {
    int_on_tc,
    hw_oneshot,
    rate_generator,
    squarewave_generator,
    sw_strobe,
    hw_strobe,
    rate_gen2,
    squarewave_gen2
};

/* pit configuration values.
 * Refer to corresponding enums for contents.
 * bcd_enabled: set to 0 for 16 bit binary, 1 for 4-digit BCD.
 */
typedef struct __attribute__((packed)) {
    unsigned bcd_enabled : 1;
    enum pit_op_mode mode : 3;
    enum pit_access access : 2;
    enum pit_channel channel : 2;
} pit_config;


/* Calculate pit channel port to use
 */
static inline uint8_t pit_channel(uint8_t x) {
    return PIT_BP | x;
}

/* Helpers to read and write channels and commands.
 * 
 * @param uint16_t frequency -- frequency we'll be using
 * @ param int channel       -- which channel we are setting up
 */
static inline void pit_set_channel_frequency(uint16_t value, int channel) {
    outb((uint8_t)(value & 0x00FF), pit_channel(channel));
    outb((uint8_t)(value >> 16), pit_channel(channel));
}

static inline uint8_t pit_get_channel(int channel) {
    return inb(pit_channel(channel));
}

static inline void pit_set_config(pit_config *value) {
    uint8_t v = ((uint8_t *)value)[0];
    outb(v, PIT_CMDP);
}

/* Get mode of given channel
 *
 * @param uint8_t mode -- Current configuration in place for our PIT
 * @param int channel  -- Which channel we want state from
 * @return uint8_t mode of given channel
 *
 */
static inline uint8_t pit_get_channel_state(pit_config *value, int channel) {
    pit_config readback = {0};
    readback.channel = read_back;
    readback.mode = channel;
    pit_set_config(&readback);

    uint8_t ret = pit_get_channel(channel-1);

    pit_set_config(value);
    return ret;
}

/* Initialise PIT to 1193182 hz with rate generator.
 *
 * @param pit_device *dev -- Device to use for pit
 * @param char *name      -- name of this device
 * @return bool true on success, false on error.
 */
bool pit_initialize(pio_device *dev, char *name); 

#endif // __PIT_H__
