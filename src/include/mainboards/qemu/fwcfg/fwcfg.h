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
#ifndef __TINY_FWCFG_H__
#define __TINY_FWCFG_H__

#include <sys/io.h>

#include <stdbool.h>
#include <stdint.h>

static const uint16_t qemu_fwcfg_addr = 0x0510;
static const uint16_t qemu_fwcfg_data = 0x0510;

typedef struct {
    uint32_t size;
    uint16_t select;
    uint16_t reserved;
    char name[56];
} fwcfg_file;

enum fw_cfg_enum {
    fwcfg_signature,
    fwcfg_id,
    fwcfg_uuid,
    fwcfg_ram_size,
    fwcfg_nographic,
    fwcfg_nb_cpus,
    fwcfg_machine_id,
    fwcfg_kernel_addr,
    fwcfg_kernel_size,
    fwcfg_kernel_cmdline,
    fwcfg_initrd_addr,
    fwcfg_initrd_size,
    fwcfg_boot_device,
    fwcfg_numa,
    fwcfg_boot_menu,
    fwcfg_max_cpus,
    fwcfg_kernel_entry,
    fwcfg_kernel_data,
    fwcfg_initrd_data,
    fwcfg_cmdline_addr,
    fwcfg_cmdline_size,
    fwcfg_cmdline_data,
    fwcfg_setup_addr,
    fwcfg_setup_size,
    fwcfg_setup_data,
    fwcfg_file_dir
};

static inline void __attribute__((always_inline)) qemu_fwcfg_select(uint16_t sel) {
    outw(sel, qemu_fwcfg_addr);
}

static inline uint8_t __attribute__((always_inline)) qemu_fwcfg_inb(void) {
    return inb(qemu_fwcfg_data);
}

static inline uint16_t __attribute__((always_inline)) qemu_fwcfg_inw(void) {
    return inw(qemu_fwcfg_data);
}

static inline uint32_t __attribute__((always_inline)) qemu_fwcfg_inl(void) {
    return inl(qemu_fwcfg_data);
}

static inline void __attribute__((always_inline)) qemu_fwcfg_insb(uint8_t *dst, int size) {
    for (int i = 0; i < size; i++) {
        dst[i] = qemu_fwcfg_inb();
    }
}

/* Detect if qemu fwcfg interface is present or not
 *
 * @return bool present
 */
bool qemu_fwcfg_present(void);

/* Read a file from qemu fw-cfg list
 *
 * @param char *name -- Name of file we're searching for
 * @return pointer to fwcfg_file on success or NULL on error.
 */
fwcfg_file *fwcfg_find_file_entry(char *name);

 /* Read a file from qemu fw-cfg files
 *
 * @param fwcfg_file *file -- Pointer to populated fwcfg structure
 * @return pointer to the file buffer on success or NULL on error
 */
uint8_t *fwcfg_read_file(fwcfg_file *file);

#endif // __TINY_FWCFG_H__
