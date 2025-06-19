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
#include <stdlib.h>

static inline bool rtc_in_bcd_mode(uint8_t status) {
    return ((status & 4) == 0);
}

static inline bool rtc_in_12hr_mode(uint8_t status) {
    return ((status & 2) == 0);
}

/* Find an appropriate iodelay to use between
 * selecting CMOS register and reading from it
 *
 * @param device *dev -- Pointer to device structure we'll use
 * @return enum DEVICE_STATUS
 */
enum DEVICE_STATUS cmos_init(device *dev) {
    cmos_data *cdata = dev->device_data;

    for (cdata->iodelay = 0; cdata->iodelay < 0x500; cdata->iodelay++) {
        // TODO: Fix -- SLOW, Get multitasking going so we aren't stuck in poll-loops
        //
        do {} while (cmos_rtc_update_ongoing(dev));

        uint8_t v = cmos_read(dev, rtc_month);
        if (!v || (v > 13)) {
            continue;
        }
        if (cmos_read(dev, rtc_month) == v) {
            uint8_t stat = cmos_read(dev, rtc_status_format);
            if (rtc_in_bcd_mode(stat)) {
                cdata->rtc_bcd_enabled = true;
            }
            if (rtc_in_12hr_mode(stat)) {
                cdata->rtc_12hr_enabled = true;
            }
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

/* Get current time and date
 *
 * @param device *dev -- Pointer to cmos device structure
 * @return timedate structure on success or NULL on error
 */
timedate *cmos_read_timedate(device *dev) {
    timedate *ret = calloc(1, sizeof(timedate));
    uint8_t *dst = (uint8_t *)ret;

    for (uint8_t rtc_off = 0; rtc_off < 9; rtc_off++, dst++) {
        if (rtc_off && (rtc_off < 6)) {
            rtc_off++;
        }
        *dst = rtc_read(dev, rtc_off);
    }
    return ret;    
}

static uint8_t bcd_convert(uint8_t bcd) {
    uint8_t v = bcd & 0x0F;
    return v + ( (bcd / 16) * 10 );
}

