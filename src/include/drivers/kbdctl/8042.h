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
#ifndef __8042_KBDCTL_H__
#define __8042_KBDCTL_H__

#include <stdbool.h>

#include <drivers/device.h>

/* 8042 related definitions and declarations here. */ 
#define KBDCTL_DATA                     0x60
#define KBDCTL_STAT                     0x64
#define KBDCTL_CMD                      0x64

/* Status byte bit definitions */
#define KBDCTL_STAT_OUT_BUF             0x01 // Output / input status
#define KBDCTL_STAT_IN_BUF              0x02
#define KBDCTL_STAT_SYSF                0x04 // System flag
#define KBDCTL_STAT_CD                  0x08 // Command/Data, 0 = inbuf, 1 = ps2ctl
#define KBDCTL_STAT_TIMEOUT             0x40 // Timeout error (0 = good, 1 = timeout)
#define KBDCTL_STAT_PARITY              0x80 // Parity error (0 = good, 1 = timeout)

/* Configuration byte bit definitions */
#define KBDCTL_CTL_P1_IE                0x01 // PS2 Port 1 interrupts enabled
#define KBDCTL_CTL_P2_IE                0x02 // PS2 Port 2 interrupts enabled
#define KBDCTL_CTL_SF                   0x04 // System Flag (Passed POST or not)
#define KBDCTL_CTL_PS1_CLKE             0x10 // First PS2 port clock enabled
#define KBDCTL_CTL_PS2_CLKE             0x20 // 2nd PS2 port clock enabled
#define KBDCTL_CTL_PS1_TE               0x40 // PS2 Port translation enabled

#define KBDCTL_DEFAULT_CONFIG_MASK      0xBC // Disable IRQs and translation

/* Controller output port bit definitions */
#define KBDCTL_CTL_OUT_SYSRST           0x01 // Pulse to reset 
#define KBDCTL_CTL_OUT_A20              0x02 // A20 gate output
#define KBDCLT_CTL_OUT_P2_CLK           0x04 // Second ps2 port clock
#define KBDCTL_CTL_OUT_P2_DATA          0x08 // PS2 port data 
#define KBDCTL_CTL_OUT_BUF_FULL_IRQ1    0x10 // Output buffer full @ port 1 
#define KBDCTL_CTL_OUT_BUFF_FULL_IRQ2   0x20 // Output buffer full @ port 2
#define KBDCTL_CTL_OUT_P1_CLK           0x40 // First ps2 port clock
#define KBDCTL_CTL_OUT_P1_DATA          0x80 // First ps2 port data

// Command byte definitions:
// 1.)  Read "Byte 0" from internal ram, returns controller config byte
// 2.)  Read Nth byte of internal ram
// 3.)  Write byte0/controller configuration byte
// 4.)  Write Nth byte of internal ram
// 5.)  Disable second ps/2 port (if supported)
// 6.)  Enable second ps/2 port (if supported)
// 7.)  Test second ps/2 port (if supported)
// 8.)  Test ps/2 controller 
// 9.)  Test 1st ps/2 port 
// 10.) Diagnostic dump (Read all ram)
// 11.) Disable 1st ps/2 port
// 12.) Enable 1st ps/2 port
// 13.) Read controller input port
// 14.) Copy bits 0-3 of input to status 4-7
// 15.) Copy bits 4-7 of input to status 4-7
// 16.) Read controller output port 
// 17.) Write next byte to Controller Output Port
// 	Note: first check that output buffer is empty
// 18.) Write next byte to ps/2 port 1 output buffer
// 	Note: Makes it look like byte was from 1st ps/2 port
// 19.) Write next byte to ps/2 port 2 output buffer
// 	Note: Makes it look like the byte was from 2nd ps/2 port
// 20.) Write next byte to ps/2 port input buffer
// 	Note: Sends next byte to second ps/2 port)
//
#define KBDCTL_CMD_READ_CONFIG 		    0x20
#define KBDCTL_CMD_READBN(x) 		    (0x20 + x)
#define KBDCTL_CMD_WRITE_CONFIG 	    0x60
#define KBDCTL_CMD_WRITEBN(x) 		    (0x60 + x)
#define KBDCTL_CMD_DISABLE_P2 		    0xA7
#define KBDCTL_CMD_ENABLE_P2 		    0xA8
#define KBDCTL_CMD_TEST_P2 		        0xA9
#define KBDCTL_CMD_TEST_CTL 		    0xAA
#define KBDCTL_CMD_TEST_P1 		        0xAB
#define KBDCTL_CMD_DUMP_RAM 		    0xAC
#define KBDCTL_CMD_DISABLE_P1 		    0xAD
#define KBDCTL_CMD_ENABLE_P1 		    0xAE
#define KBDCTL_CMD_READ_CTL_IN 		    0xC0
#define KBDCTL_CMD_CP_INLO_STATHI 	    0xC1
#define KBDCTL_CMD_CP_INHI_STATHI 	    0xC2
#define KBDCTL_CMD_READ_CTL_OUT 	    0xC3
#define KBDCTL_CMD_WRITENEXT_CTL_OUT 	0xD1
#define KBDCTL_CMD_WRITENEXT_P1OUTBUF 	0xD2
#define KBDCTL_CMD_WRITENEXT_P2OUTBUF 	0xD3
#define KBDCTL_CMD_WRITENEXT_P2INBUF 	0xD4
#define KBDCTL_CMD_ENABLE_A20           0xDF
#define KBDCTL_CMD_PULSE_OUT_LOW(x) 	(0xF0 | x)
#define KBDCTL_CMD_CPU_HARD_RESET 	    0xFE
#define KBDCTL_CMD_RST_DEVICE           0xFF

// Device commands 
#define KBDCTL_DEV_CMD_RESET            0xFF

// Command responses 
#define KBDCTL_SELFTEST_SUCCESS         0x55
#define KBDCTL_STAT_ACK                 0xFA
#define KBDCTL_STAT_FAIL                0xFC

// 8042/ps2 controoler status related information
typedef struct {
    // Is this a dual channel controller
    bool dual_channel;

    // current configuration
    unsigned char current_configuration;

    // devices initialised
    int devices_initialised;

    // A20 line status for memory access :3
    bool a20line_enabled;

} ps2_8042_status;

// Send command to kbd controller, read response
// 
// @param unsigned char v -- Command byte to send
// @return bool true on success or fals eon error
//
bool kbdctl_send_cmd(unsigned char v);

// Read a byte from data port once data becomes readable
//
// @return unsigned char data we received or -1 on error
//
unsigned char kbdctl_recv_data_poll(void);

// Write 1 byte of data to kbdctl port once it becomes writable
//
// @param unsigned char v -- byte to write
// @return true on success or false on timeout
//
bool kbdctl_send_data_poll(unsigned char v);

// Disable both ps/2 ports
//
// @return int 0 on success or which port failed to disable on error (1, 2, or both)
// 
int kbdctl_disable_ports(void);

// Set keyboard controller byte with default config mask with 
// interrupts and translation layer disabled
//
// @return 0 on success, -1 on error, or -2 if we bricked the device
//
int kbdctl_set_default_init(pio_device *dev);

// Perform keyboard controller self test.
// 
// @return true on success or false on error
//
bool kbdctl_do_self_test(void);

// Test a single device
//
// @param unsigned char dev_cmd -- device specific test cmd (KBDCTL_CMD_TEST_P{1,2}
// @return unsigned char status of device test on success or -1 on error
//
unsigned char kbdctl_test_device(unsigned char dev_cmd);

// Enable all ps/2 devices
//
// @return unsigned char devices initialised
//
unsigned char kbdctl_enable_devices(pio_device *dev);

// Reset a specific device
//
// @param int device_number -- 0 or 1 for 1st or 2nd device
// @return bool true on success or false on error
//
bool kbdctl_reset_device(int which);

/* Helper to enable a20 line with keyboard controller
 *
 * @return true on success or false on error
 */
bool enable_a20line(pio_device *dev);

#endif // __8042_KBDCTL_H__ 
