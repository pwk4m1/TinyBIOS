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
#ifndef __TINY_ROMCALL_H__
#define __TINY_ROMCALL_H__

#include <stdbool.h>
#include <stdint.h>

static const uint16_t rom_exec_sign = 0x55AA;

/* Check if this segment has a valid option rom signature
 *
 * @param uint64_t mem -- Address of the option rom entry
 * @return bool option rom is present
 */
static inline bool rom_header_present(uint64_t mem) {
    uint16_t *hdr = (uint16_t *)mem;
    return (*hdr == rom_exec_sign);
}

/* Get size of option rom code
 *
 * @param uint64_t mem -- Address of the option rom entry
 * @return uint8_t size of the rom amount of kilobytes
 */
static inline uint8_t rom_get_size(uint64_t mem) {
    uint8_t *p = (uint8_t *)mem;
    return p[2];
}

/* Get option rom entrypoint
 *
 * @param uint64_t mem -- Address of the option rom entry
 * @return address to code entry
 */
static inline void *rom_code_entry(uint64_t mem) {
    return (void *)(mem + 3);
}

/* Execute option rom code
 *
 * @param uint16_t segment -- Segment in which the option rom can be found
 * @param uint16_t offset  -- Offset in segment for entry
 */
void execute_option_rom(uint16_t segment, uint16_t offset);

/* Scan low memory for potential option rom entries,
 * and execute them if found
 *
 */
void find_and_exec_roms(void);

#endif // __TINY_ROMCALL_H__
