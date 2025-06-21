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
#ifndef __TINY_CMOS_H__
#define __TINY_CMOS_H__

#include <sys/io.h>
#include <drivers/device.h>

static const uint8_t CMOS_CLI_FLAG       = 0x80;
static const uint16_t cmos_register_addr = 0x0070;
static const uint16_t cmos_data_addr     = 0x0071;

typedef struct {
    uint16_t iodelay;
    bool rtc_bcd_enabled;
    bool rtc_12hr_enabled;
} cmos_data;

enum CMOS_RTC_ADDR {
    rtc_second       = 0,
    rtc_minute       = 2,
    rtc_hour         = 4,
    rtc_day_of_week  = 6,
    rtc_day_of_month = 7,
    rtc_month        = 8,
    rtc_year         = 9,
    rtc_status_update = 0x0A,
    rtc_status_format = 0x0B
};

typedef struct {
    uint8_t second;
    uint8_t minute;
    uint8_t hour;
    uint8_t day_of_week;
    uint8_t day_of_month;
    uint8_t year;
} timedate;

/* Get current time and date
 *
 * @param device *dev -- Pointer to cmos device structure
 * @return timedate structure 
 */
timedate *cmos_read_timedate(device *dev);

/* Find an appropriate iodelay to use between
 * selecting CMOS register and reading from it
 *
 * @param device *dev -- Pointer to device structure we'll use
 * @return enum DEVICE_STATUS
 */
enum DEVICE_STATUS cmos_init(device *dev);

/* Check if RTC is updating currently
 *
 * @param device *dev -- CMOS device structure
 * @return bool update status
 */
bool cmos_rtc_update_ongoing(device *dev);

/* Select a given CMOS register
 *
 * @param device *dev -- CMOS device structure
 * @param uint8_t reg -- which cmos register to select
 */
static inline void cmos_select_register(device *dev, uint8_t reg) {
    cmos_data *cd = dev->device_data;
    outb(reg, cmos_register_addr);
    iodelay(cd->iodelay);
}

/* Read a byte of data from CMOS register 
 *
 * @param device *dev -- CMOS device structure
 * @param uint8_t reg -- which cmos register are we reading
 * @return uint8_t data
 */
static inline uint8_t cmos_read(device *dev, uint8_t reg) {
    cmos_select_register(dev, reg);
    return inb(cmos_data_addr);
}

/* Write a byte of data to CMOS register
 *
 * @param device *dev -- CMOS device structure
 * @param uint8_t v   -- value to write
 * @param uint8_t reg -- which cmos register are we writing to
 */ 
static inline void cmos_write(device *dev, uint8_t v, uint8_t reg) {
    cmos_select_register(dev, reg);
    outb(v, cmos_data_addr);
}

/* Helper to read CMOS/RTC data
 *
 * @param device *dev -- CMOS device structure
 * @param enum CMOS_RTC_ADDR field -- Which time-field are we reading
 * @return uint8_t RTC value
 */
static inline uint8_t rtc_read(device *dev, enum CMOS_RTC_ADDR field) {
    // TODO: Fix -- SLOW, Get multitasking going so we aren't stuck in poll-loops
    //
    do {} while (cmos_rtc_update_ongoing(dev));
    return cmos_read(dev, field);
}

/* Print current date stored in CMOS
 *
 * @param device *dev -- CMOS device structure
 */
static void cmos_print_date(device *dev);

/* Enable RTC interrupts
 *
 * @param device *dev -- Pointer to the cmos device structure
 */
void rtc_enable_nmi(device *dev);

#endif // __TINY_CMOS_H__
