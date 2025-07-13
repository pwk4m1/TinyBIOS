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
#include <mainboards/memory_init.h>
#include <mainboards/qemu/fwcfg/fwcfg.h>

#include <drivers/device.h>
#include <drivers/cmos/cmos.h>

#include <stdlib.h>
#include <panic.h>

/* Mainboard-specific helper to resolve memory map for us.
 *
 * @param device *dev -- Device structure for memory
 * @return bool success 
 */
static inline void add_from_to(memory_map *map, e820_e *e) {
    map->entry[map->count] = calloc(1, sizeof(e820_e));
    map->entry[map->count]->addr = e->addr;
    map->entry[map->count]->size = e->size;
    map->entry[map->count]->type = e->type;
    map->count++;
}

bool mainboard_specific_memory_init(device *dev) {
    if (qemu_fwcfg_present() == false) {
        blog("Qemu FW-CFG not present\n");
        return false;
    }
    memory_map *map = (memory_map *)dev->device_data;
    fwcfg_file *f = fwcfg_find_file_entry("etc/e820");
    if (!f) {
        blog("Missing 'etc/e820 file from qemu fw-cfg\n");
        return false;
    }
    blogf("Found '%s', parsing memory map\n", f->name);
    qemu_fwcfg_select(f->select);
    uint32_t pos = 0;
    while (pos < f->size) {
        e820_e e;
        qemu_fwcfg_insb((uint8_t *)&e, sizeof(e820_e));
        pos += sizeof(e);
        if (e.size == 0 || e.type != 1) {
            continue;
        }
        if (e.addr == 0) {
            e820_e low = {0};
            low.type = 1;
            low.size = 0x1FFFF;
            add_from_to(map, &low);
            low.addr = 0xA0000;
            low.size = 0xFFFFF;
            low.type = 3;
            add_from_to(map, &low);
            low.addr = 0x00100000;
            low.size = 0x00EFFFFF;
            low.type = 1;
            add_from_to(map, &low);
            low.addr = 0x00F00000;
            low.size = 0x00FFFFFF;
            low.type = 2;
            add_from_to(map, &low);
            e.addr = 0x01000000;
            add_from_to(map, &e);
        } else {
            add_from_to(map, &e);
        }
    }
    free(f);

    return (map->count != 0);
}

