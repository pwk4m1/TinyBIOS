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

#include <sys/types.h>
#include <sys/io.h>

#include <mainboards/qemu/bochsfb.h>

#include <drivers/device.h>
#include <drivers/pci/pci.h>
#include <drivers/pci/pci_util.h>

#include <stdbool.h>
#include <stdint.h>

#include <console/console.h>

/**
 * Enable and initialise bochs framebuffer.
 *
 * @param dev Is a pointer to preallocated device structure.
 * @return status of vga device
 */
enum DEVICE_STATUS init_vga_controller(device *vgadev) {
    pci_device_data *pdev = vgadev->device_data;

    uint16_t base;
    if (pdev->device_hdr.bar2) {
        base = pdev->device_hdr.bar2;
    } else {
        base = bochs_vbe_ioidx;
    }

    uint16_t ver = bochs_vbe_version(base);
    if (ver < 0xB0C0 || ver > 0xB0C5) {
        return status_not_present;
    }

    bochs_vbe_disable(base);
    bochs_vbe_out(base, 0, bochs_vbe_idx_bank);
    bochs_vbe_out(base, 32, bochs_vbe_idx_bpp);
    bochs_vbe_out(base, 760, bochs_vbe_idx_xres);
    bochs_vbe_out(base, 480, bochs_vbe_idx_yres);
    bochs_vbe_out(base, 760, bochs_vbe_idx_v_width);
    bochs_vbe_out(base, 480, bochs_vbe_idx_v_height);
    bochs_vbe_out(base, 0, bochs_vbe_idx_x_off);
    bochs_vbe_out(base, 0, bochs_vbe_idx_y_off);
    bochs_vbe_out(base, (0x40 | 0x01), bochs_vbe_idx_enable);
    outb(0x20, (base + 0x03c0));
    pci_write_config(&pdev->address, 0x10, 0x1000008);

    return status_initialised;
}


