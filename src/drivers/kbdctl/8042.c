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

#include <sys/io.h>
#include <drivers/device.h>
#include <drivers/kbdctl/8042.h>

#include <stdbool.h>
#include <drivers/device.h>

#include <console/console.h>

#define WAITFOR_READ KBDCTL_STAT_OUT_BUF
#define WAITFOR_WRITE 0

ps2_8042_status keyboard_controller_status;

// Wait until keyboard controller input buffer status is empty
// 
// @return int waitfor -- are we waiting for empty or non-empty status (read or write)
// @return bool true once controller is ready to recv or false on timeout
//
static bool kbdctl_ctrl_rdy(int waitfor) {
    unsigned char mask;
    if (waitfor != 0) {
        mask = waitfor;
    } else {
        mask = KBDCTL_STAT_IN_BUF;
    }
    for (int i = 0; i < 5000; i++) {
        if ((inb(KBDCTL_STAT) & mask) == waitfor) {
            return true;
        }
    }
    return false;
}

// Send command to kbd controller, read response
// 
// @param unsigned char v -- Command byte to send
// @return bool true on success or false on error
//
bool kbdctl_send_cmd(unsigned char v) { 
    if (kbdctl_ctrl_rdy(WAITFOR_WRITE) == false) {
        return false;
    }
    outb(v, KBDCTL_CMD);
    return true;
}

// Read a byte from data port once data becomes readable
//
// @return unsigned char data we received or -1 on error
//
unsigned char kbdctl_recv_data_poll(void) { 
    if (kbdctl_ctrl_rdy(WAITFOR_READ) == false) {
        blog("kbdctl_recv_data_poll timeout\n");
        return 0xff;
    }
    return inb(KBDCTL_DATA);
}

// Write 1 byte of data to kbdctl port once it becomes writable
//
// @param unsigned char v -- byte to write
// @return true on success or false on timeout
//
bool kbdctl_send_data_poll(unsigned char v) { 
    if (kbdctl_ctrl_rdy(WAITFOR_WRITE) == false) {
        return false;
    }
    outb(v, KBDCTL_DATA);
    return true;
}

// Disable both ps/2 ports
//
// @return int 0 on success or which port failed to disable on error (1, 2, or both)
// 
int kbdctl_disable_ports(void) { 
    int ret = 0;
    if (kbdctl_send_cmd(KBDCTL_CMD_DISABLE_P1) == false) {
        ret |= 1;
    }
    if (kbdctl_send_cmd(KBDCTL_CMD_DISABLE_P2) == false) {
        ret |= 2;
    }
    return ret;
}

// Try and read configuration byte from device
//
// @return unsigned char configuration on success or FF on error
//
static unsigned char kbdctl_read_config(void) {
    if (kbdctl_send_cmd(KBDCTL_CMD_READ_CONFIG) == false) {
        return 0xff;
    }
    return kbdctl_recv_data_poll();
}

// Try and write configuration to device
//
// @param unsigned char configuration
// @return bool true on success or false on error
//
static bool kbdctl_write_config(unsigned char config_byte) {
    if (kbdctl_send_cmd(KBDCTL_CMD_WRITE_CONFIG) == false) {
        return false;
    }
    if (kbdctl_send_data_poll(config_byte) == false) {
        return false;
    }
    unsigned char t = kbdctl_read_config();
    if (t != config_byte) {
        return false;
    }
    return true;
}

// Reset a specific device
//
// @param int device_number -- 0 or 1 for 1st or 2nd device
// @return bool true on success or false on error
//
bool kbdctl_reset_device(int which) {
    // If we're reseting secondary device, tell that to controller first
    if (which == 1) {
        if (kbdctl_send_cmd(KBDCTL_CMD_WRITENEXT_P2INBUF) == false) {
            return false;
        }
    }
    if (kbdctl_send_cmd(KBDCTL_CMD_RST_DEVICE) == false) {
        return false;
    }
    if (kbdctl_recv_data_poll() != KBDCTL_STAT_ACK) {
        return false;
    }
    return true;
}

// Set keyboard controller byte with default config mask with 
// interrupts and translation layer disabled
//
// @param pio_device *dev -- a pointer to pio_device structure to populate
// @return bool true on success or false on error
//
bool kbdctl_set_default_init(pio_device *dev) { 
    ps2_8042_status *status = &keyboard_controller_status;
    dev->device_name = "8042\n";

    // Start by reading inital configuration
    //
    unsigned char initial_config = kbdctl_read_config();
    if (initial_config == 0xff) {
        blog("Failed to get initial config\n");
        return false;
    }
    unsigned char new_config = initial_config & KBDCTL_DEFAULT_CONFIG_MASK;
    if (kbdctl_write_config(new_config) == false) {
        // Writing new configuration failed
        return false;
    }
    if (kbdctl_do_self_test() == false) {
        // Device failed self-test after our new configuration, fallback to old
        if (kbdctl_write_config(initial_config) == false) {
            // Can't write old configuration back anymore... 
            blog("8042 keyboard controller became unresponsive, hard reboot required.\n");
            do {} while (1);
        }
        return false;
    }
    dev->status = initialised;
    if (initial_config & KBDCTL_CTL_PS2_CLKE) {
        status->dual_channel = true;
    }
    status->current_configuration = new_config;
    return true;
}

// Perform keyboard controller self test.
// 
// @return true on success or false on error
//
bool kbdctl_do_self_test(void) { 
    if (kbdctl_send_cmd(KBDCTL_CMD_TEST_CTL) == false) {
        return false;
    }
    unsigned char stat = kbdctl_recv_data_poll();
    if (stat != KBDCTL_SELFTEST_SUCCESS) {
        return false;
    }
    return true;
}

// Test a single device
//
// @param unsigned char dev_cmd -- device specific test cmd (KBDCTL_CMD_TEST_P{1,2}
// @return unsigned char status of device test on success or 0xff on error
//
unsigned char kbdctl_test_device(unsigned char dev_cmd) { 
    if (kbdctl_send_cmd(dev_cmd) == false) {
        return 0xff; 
    }
    return kbdctl_recv_data_poll();
}

// Enable all ps/2 devices
//
// @return unsigned char devices initialised
//
unsigned char kbdctl_enable_devices(pio_device *dev) { 
    ps2_8042_status *stat = dev->device_data;
    if (kbdctl_send_cmd(KBDCTL_CMD_ENABLE_P1) == false) {
        return 0;
    }
    stat->devices_initialised++;
    if (stat->dual_channel) {
        if (kbdctl_send_cmd(KBDCTL_CMD_ENABLE_P2)) {
            return 2;
        }
    }
    return 1;
}

/* Helper to enable a20 line with keyboard controller
 *
 * @return true on success or false on error
 */
bool enable_a20line(pio_device *dev) {
    ps2_8042_status *stat = (ps2_8042_status *)dev->device_data;
    stat->a20line_enabled = false;
    if (kbdctl_send_cmd(KBDCTL_CMD_WRITENEXT_CTL_OUT) == false) {
        return false;
    }
    if (kbdctl_send_data_poll(KBDCTL_CMD_ENABLE_A20) == false) {
        return false;
    }
    volatile unsigned int *first     = (unsigned int *)0x012345;
    volatile unsigned int *second    = (unsigned int *)0x112345;
    *first  = 0x012345;
    *second = 0x112345;

    if (*first == *second) {
        return false;
    }
    stat->a20line_enabled = true;
    return true;
}


