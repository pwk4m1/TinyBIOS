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
#ifndef __TINY_BOCHS_FB_H__
#define __TINY_BOCHS_FB_H__

#include <sys/types.h>
#include <sys/io.h>

#include <drivers/device.h>

#include <stdbool.h>
#include <stdint.h>

static const uint16_t bochs_vbe_ioidx = 0x01CE;
static const uint16_t bochs_vbe_ioval = 0x01CF;

enum BOCHS_VBE_IDX {
    bochs_vbe_idx_id = 0,
    bochs_vbe_idx_xres,
    bochs_vbe_idx_yres,
    bochs_vbe_idx_bpp,
    bochs_vbe_idx_enable,
    bochs_vbe_idx_bank,
    bochs_vbe_idx_v_width,
    bochs_vbe_idx_v_height,
    bochs_vbe_idx_x_off,
    bochs_vbe_idx_y_off,
    bochs_vbe_idx_vmem
};

/**
 * Check if vbe extensions should be disabled for a write operation
 * to take place.
 *
 * @param idx Is the index the next write affects.
 * @return true if extensions need to be disabled.
 */
static inline bool __attribute__((always_inline)) bochs_vbe_must_disable(uint16_t idx) {
    return (idx && (idx < 4));
}

/**
 * Helper to disable vbe extensions
 *
 * @param addr Is either bochs_vbe_ioidx or BAR0.
 */
static inline void __attribute__((always_inline)) bochs_vbe_disable(uint16_t addr) {
    outw(bochs_vbe_idx_enable, addr);
    outw(0, (addr + 1));
}

/**
 * Helper to enable vbe extensions
 *
 * @param addr Is either bochs_vbe_ioidx or BAR0.
 */
static inline void __attribute__((always_inline)) bochs_vbe_enable(uint16_t addr) {
    outw(bochs_vbe_idx_enable, addr);
    outw(1, (addr + 1));
}

/**
 * Read from bochs vbe register 
 *
 * @param addr Is either bochs_vbe_ioidx or BAR0.
 * @param idx Is the index of register to read.
 * @return 16-bit value
 */
static inline uint16_t __attribute__((always_inline)) bochs_vbe_in(uint16_t addr, uint16_t idx) {
    outw(idx, addr);
    return inw((addr + 1));
}

/**
 * write to bochs vbe register 
 *
 * @param addr Is either bochs_vbe_ioidx or BAR0.
 * @param v Is the value to write
 * @param idx Is the index of register to read.
 */
static inline void __attribute__((always_inline)) bochs_vbe_out(uint16_t addr, uint16_t v, uint16_t idx) {
    outw(idx, addr);
    outw(v, (addr + 1));
}

/**
 * Helper to check bochs version
 *
 * @param addr Is either bochs_vbe_ioidx or BAR0.
 * @return version number
 */
static inline uint16_t __attribute__((always_inline)) bochs_vbe_version(uint16_t addr) {
    return bochs_vbe_in(addr, bochs_vbe_idx_id);
}

#endif // __TINY_BOCHS_FB_H__
