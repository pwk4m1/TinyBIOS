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

#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#include <cpu/common.h>
#include <console/console.h>
#include <romcall/romcall.h>

/* Copy option rom to ram
 *
 * @param uint64_t mem -- linear address to rom
 * @return pointer in ram where we copied the rom code, or
 *         NULL on error
 */
static void *copy_rom_to_ram(uint64_t mem) {
    if (rom_header_present(mem) == false) {
        return NULL;
    }
    uint32_t size = (rom_get_size(mem) * 1024);
    if (size % 0x2000) {
        blogf("Incorrect rom size (0x%x), refusing to execute\n", size);
        return NULL;
    }
    void *p = malloc_align(size, 0x2000);
    if (!p) {
        blog("Unable to allocate memory for rom\n");
        return NULL;
    }
    memcpy((void *)mem, p, size);
    return p;
}

/* Execute option rom code
 *
 * @param uint16_t segment -- Segment in which the option rom can be found
 * @param uint16_t offset  -- Offset in segment for entry
 */
void execute_option_rom(uint16_t segment, uint16_t offset) {
    return;
}

/* Scan low memory for potential option rom entries,
 * and execute them if found
 *
 */
void find_and_exec_roms(void) {
    blog("Scanning for executable option roms...\n");
    for (uint64_t entry = 0xC0000; entry < 0xF0000; entry += 0x02000) {
        if (rom_header_present(entry) == false) {
            continue;
        }
        blogf("Found possible option rom entry at 0x%x\n", entry);

        void *shadow = copy_rom_to_ram(entry);
        if (!shadow) {
            continue;
        }
        free(shadow);
    }
}


