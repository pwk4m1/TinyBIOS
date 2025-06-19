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

#include <sys/io.h>

#include <drivers/device.h>
#include <drivers/cmos/cmos.h>

#include <stdbool.h>
#include <stdint.h>


/* Find an appropriate iodelay to use between
 * selecting CMOS register and reading from it
 *
 * @param device *dev -- Pointer to device structure we'll use
 * @return enum DEVICE_STATUS
 */
enum DEVICE_STATUS cmos_init(device *dev) {
    for (dev->config_word = 0; dev->config_word < 0x500; dev->config_word++) {
        // TODO: Fix -- SLOW, Get multitasking going so we aren't stuck in poll-loops
        //
        do {} while (cmos_rtc_update_ongoing(dev));

        uint8_t v = cmos_read(dev, rtc_month);
        if (!v || (v > 13)) {
            continue;
        }
        if (cmos_read(dev, rtc_month) == v) {
            return status_initialised;
        }
    }
    return status_faulty;
}

/* Check if RTC is updating currently
 *
 * @param device *dev -- CMOS device structure
 * @return bool update status
 */
bool cmos_rtc_update_ongoing(device *dev) {
    uint8_t status = cmos_read(dev, rtc_status_update);
    if (status & CMOS_CLI_FLAG) {
        return true;
    }
    return false;
}

