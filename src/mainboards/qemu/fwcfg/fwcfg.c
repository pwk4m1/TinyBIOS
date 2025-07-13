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
#include <cpu/common.h>

#include <mainboards/qemu/fwcfg/fwcfg.h>

#include <console/console.h>

#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#include <byteswap.h>

/* Detect if qemu fwcfg interface is present or not
 *
 * @return bool present
 */
bool qemu_fwcfg_present(void) {
    char dst[4];
    qemu_fwcfg_select(0);

    for (int i = 0; i < 4; i++) {
        dst[i] = qemu_fwcfg_inb();
    }
    uint32_t *sign = (uint32_t *)&dst;
    return (*sign == 0x554D4551);
}

/* Find a file from qemu fw-cfg list
 *
 * @param char *name -- Name of file we're searching for
 * @return pointer to fwcfg_file on success or NULL on error.
 */
fwcfg_file *fwcfg_find_file_entry(char *name) {
    fwcfg_file *file = calloc(1, sizeof(fwcfg_file));
    if (!file) {
        blog("Failed to allocate memory for fwcfg_file!\n");
        return NULL;
    }
    uint32_t cnt = 0;
    qemu_fwcfg_select(fwcfg_file_dir);
    qemu_fwcfg_insb((uint8_t *)&cnt, sizeof(uint32_t));
    cnt = bswap_32(cnt);

    for (uint32_t i = 0; i < cnt; i++) {
        qemu_fwcfg_insb((uint8_t*)file, sizeof(fwcfg_file));
        if (strncmp((uint8_t *)file->name, (uint8_t *)name, sizeof(file->name)) == 0) {
            file->select = bswap_16(file->select);
            file->size = bswap_32(file->size);
            return file;
        }
    }
    blogf("QEMU FW-CFG Interface present but missing file '%s'\n", name);
    return NULL;
}

/* Read a file from qemu fw-cfg files
 *
 * @param fwcfg_file *file -- Pointer to populated fwcfg structure
 * @return pointer to the file buffer on success or NULL on error
 */
uint8_t *fwcfg_read_file(fwcfg_file *file) {
    uint32_t *ret = malloc(file->size);
    if (!ret) {
        return NULL;
    }
    for (int i = 0; i < (file->size / 4); i++) {
        qemu_fwcfg_insb((uint8_t *)ret, sizeof(uint32_t));
        ret[0] = bswap_32(ret[0]);
    }

    return (uint8_t *)ret;
}

