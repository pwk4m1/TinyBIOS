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
#ifndef __IVT_H__
#define __IVT_H__

#include <stdbool.h>
#include <stdint.h>

/* Helper to register interrupt handler for a driver or other bit of
 * software that wants to listen to interrupts.
 *
 * Note, that preboot and boot-services must use different IVT entries, as
 * different segment value is needed.
 *
 * @param uint16_t segment -- what CS value should we have upon jump to handler
 * @param uint16_t offset  -- where in that segment our handler is at? 
 * @param uint16_t entry   -- which interrupt are we handling
 */
static inline void register_int_handler(uint16_t segment, uint16_t offset, uint16_t entry) {
    uint16_t *ptr = (uint16_t *)((entry * 4));
    ptr[0] = segment;
    ptr[1] = offset;
}

/* Helper to get currently registered interrupt handler at IVT
 *
 * @param uint32_t entry -- Which interrupt are we handling 
 */
static inline uint32_t get_ivt_handler(uint16_t entry) {
    uint16_t *ptr = (uint16_t *)((entry * 4));
    uint32_t ret;
    ret = ptr[0] << 16;
    ret |= ptr[1];
    return ret;
}


#endif // __IVT_H__
