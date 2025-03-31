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
#ifndef __PIT_H__
#define __PIT_H__

#include <sys/io.h>
#include <drivers/device.h>

#include <stdbool.h>
#include <stdint.h>

static const short pit_channel_0_port = 0x40;
static const short pit_channel_1_port = 0x41;
static const short pit_channel_2_port = 0x42;
static const short pit_command_port   = 0x43;

/* Supported pit data modes:
 * 
 * @member binary -- Use traditional binary values
 * @member bcd    -- Use the silly binary decimal format
 *
 */
enum pit_binary_mode {
    binary,
    bcd
};

/* Supported pit operating modes
 *
 * 0 0 0 = Mode 0 (interrupt on terminal count)
 * 0 0 1 = Mode 1 (hardware re-triggerable one-shot)
 * 0 1 0 = Mode 2 (rate generator)
 * 0 1 1 = Mode 3 (square wave generator)
 * 1 0 0 = Mode 4 (software triggered strobe)
 * 1 0 1 = Mode 5 (hardware triggered strobe)
 * 1 1 0 = Mode 2 (rate generator, same as 010b)
 * 1 1 1 = Mode 3 (square wave generator, same as 011b)
 *
 * @member int_on_terminal_count
 * @member hardware_retriggerable_single_shot
 * @member rate_generator
 * @member square_wave_generator
 * @member sw_triggered_strobe
 * @member hw_triggered_strobe
 * @member rate_generator_2
 * @member square_wave_generator_2
 *
 */
enum pit_operating_mode {
    int_on_terminal_count,
    hardware_retriggerable_single_shot,
    rate_generator,
    square_wave_generator,
    sw_triggered_strobe,
    hw_triggered_strobe,
    rate_generator_2,
    square_wave_generator_2
};

/* Supported access modes
 *
 * @member latch_count_value -- Latch on count
 * @member lobyte_only       -- Only read low 8-bit values from channel
 * @member hibyte_only       -- Only read high 8-bit values from channel
 * @member lo_ and_hi_byte   -- First read returns 8-bit low, 2nd 8-bit high value
 */
enum pit_access_mode {
    latch_count_value,
    lobyte_only,
    hibyte_only,
    lo_and_hi_byte
};

/* channel mode for command
 *
 * @member channel_{0-n} -- We want to control channel 0, 1, or 2 
 * @member read_back     -- We want to read configuration of a given channel
 */
enum pit_channel_mode {
    channel_0,
    channel_1,
    channel_2,
    read_back
};

/* Pit command format
 *
 * @member enum pit_binary_mode                   -- Refer matching enum
 * @member enum pit_operating_mode operating_mode -- Refer matching enum
 * @member enum pit_access_mode access_mode       -- Refer matching enum
 * @member enum pit_channel_mode selected_channel -- Refer matching enum
 *
 */
typedef struct __attribute__((packed)) {
    enum pit_binary_mode binary_mode        : 1;
    enum pit_operating_mode operating_mode  : 3; 
    enum pit_access_mode access_mode        : 2;
    enum pit_channel_mode selected_channel  : 2;
} pit_command;

/* Pit readback command format
 *
 * @member unsigned reserved_zero                 -- Always 0
 * @member bool readback_timer_channel_N_selected -- Toggle to select channel N
 * @member bool status_latching_enabled           -- Toggle to enable status latching
 * @member bool count_latching_enabled            -- Toggle to enable count latching
 * @member unsigned reserved_one                  -- Always one 
 */
typedef struct __attribute__((packed)) {
    unsigned reserved_zero                  : 1;
    bool readback_timer_channel_0_selected  : 1;
    bool readback_timer_channel_1_selected  : 1;
    bool readback_timer_channel_2_selected  : 1;
    bool status_latching_enabled            : 1;
    bool count_latching_enabled             : 1;
    unsigned reserved_one                   : 2;
} pit_readback_command;

/* Readback response format
 *
 * @member enum pit_binary_mode binary_mode
 * @member enum pit_operating_mode operating_mode
 * @member enum pit_access_mode access_mode
 * @member unsigned null_count_flags
 * @member unsigned output_pin_state
 */
typedef struct __attribute__((packed)) {
    enum pit_binary_mode binary_mode        : 1;    
    enum pit_operating_mode operating_mode  : 3;
    enum pit_access_mode access_mode        : 2;
    unsigned null_count_flags               : 1;
    unsigned output_pin_state               : 1;
} pit_readback_status;

/* Helper to write command byte for programmable interrupt controller.
 *
 * @param uint8_t cmd -- Command to write
 */
static inline void pit_write_command_raw(uint8_t cmd) {
    outb(cmd, pit_command_port);
}

/* Helper to write pit_command to programmable interrupt controller from
 * pit_command structure.
 *
 * @param pit_command *command -- Command to write
 */
static inline void pit_write_command(pit_command *cmd) {
    uint8_t *cmd_byte = (uint8_t *)cmd;
    pit_write_command_raw(*cmd_byte);
}

/* Read pit value from given channel 
 *
 * @param unsigned short channel -- Channel to read from
 * @return uint16_t count
 */
static inline uint16_t pit_read_count(unsigned short channel) {
    pit_command cmd = {0};
    pit_write_command(&cmd);

    return inw(channel);
}

/* Helper to write pit_readback_command to programmable interrupt controller from
 * pit_readback_command structure.
 *
 * @param pit_readback_command *command -- Command to write
 */
static inline void pit_write_readback_command(pit_readback_command *cmd) {
    uint8_t *cmd_byte = (uint8_t *)cmd;
    pit_write_command_raw(*cmd_byte);
}

/* Read pit status for a given channel
 *
 * @param uint8_t channel -- channel to read
 * @return uint8_t status of the channel
 */
uint8_t pit_get_channel_mode(uint8_t channel);

/* Setup PIT with default init.
 *
 * @param device *dev -- Device info structure
 * @return bool true on success, false on error. 
 */
enum DEVICE_STATUS pit_init(device *dev);

#endif
