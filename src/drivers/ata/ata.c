/*
 BSD 3-Clause License
 
 Copyright (c) 2025, k4m1
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
#include <drivers/pci/pci.h>
#include <drivers/pci/pci_util.h>
#include <drivers/ata/ata.h>

#include <console/console.h>

#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>

#include <panic.h>

/* Try and read ID of sata/atapi device
 *
 * @param ata_bus *bus -- Bus we're currently working with
 * @return uint16_t id
 */
static uint16_t ata_try_read_id(ata_bus *bus) {
    uint16_t ret;
    ata_register reg = ata_read_lba_mi(bus);
    ret = (reg.raw) << 8;
    reg = ata_read_lba_hi(bus);
    ret |= reg.raw;
    return ret;
}

/* Clear out ata sector count and lba
 * values
 *
 * @param ata_bus *bus -- Bus we're currently working with
 */
static void ata_clear_sc_lba(ata_bus *bus) {
    ata_register reg = {0};
    ata_write_sector_count(bus, reg);
    ata_write_lba_lo(bus, reg);
    ata_write_lba_mi(bus, reg);
    ata_write_lba_hi(bus, reg);
}

/* Try and identify ATA drive we're working with
 *
 * @param ata_bus *bus -- Bus we're currently working with
 * @return enum ata_drive_id id on success or -1 on timeout
 */
static enum ata_drive_id ata_identify_drive(ata_bus *bus) {
    ata_clear_sc_lba(bus);
    ata_register reg = {0};
    reg.raw = ata_cmd_identify;
    ata_write_command(bus, reg);
    uint16_t id = ata_try_read_id(bus);

    if ((id == ata_drive_id_sata) || (id == ata_drive_id_atapi)) {
        return id;
    }
    reg.raw = 0;
    reg.status.drive_busy = false;
    if (ata_waitfor_status(bus, reg.raw, false, 50) == false) {
        return ata_drive_id_not_ata;
    }
    id = ata_try_read_id(bus);
    if (id) {
        return ata_drive_id_not_ata;
    }
    reg.raw = 0;
    reg.status.drive_ready = true;
    if (ata_waitfor_status(bus, reg.raw, true, 50) == false) {
        return ata_drive_id_not_ata;
    }
    return ata_drive_id_ata;
}

static char *ata_drive_model_to_string(uint8_t *model) {
    char *ret = calloc(41, sizeof(char));
    if (ret) {
        for (int i = 0; i < 40; i += 2) {
            ret[i] = model[i + 1];
            ret[i + 1] = model[i];
        }
    }
    return ret;
}

/* Initialize currently selected active drive
 *
 * @param ata_bus *bus -- Bus we're currently working with
 * @return pointer to allocated ata_drive structure on success
 * or NULL on error.
 */
static ata_drive *init_ata_drive(ata_bus *bus) {
    ata_drive *ret = calloc(1, sizeof(ata_drive));
    if (!ret) {
        return NULL;
    }
    ret->drive_id = ata_identify_drive(bus);
    if ((ret->drive_id == ata_drive_id_not_ata) || (ret->drive_id == 0)) {
        free(ret);
        return NULL;
    }

    ret->hdr_addr = calloc(1, sizeof(ata_drive_header));
    if (!ret->hdr_addr) {
        blogf("No enough space for reading ata drive info!\n");
    } else {
        uint16_t *dst = (uint16_t *)ret->hdr_addr;
        for (int i = 0; i < 256; i++) {
            dst[i] = ata_read_data(bus);
        }
        blogf("Found drive: %s\n", ata_drive_model_to_string(ret->hdr_addr->model));
    }
    return ret;
}

static ata_bus *init_ata_bus(uint16_t base, uint16_t dcr) {
    if (ata_no_drives_in_bus(base)) {
        return NULL;
    }
    ata_bus *ret = calloc(1, sizeof(ata_bus));
    if (!ret) {
        return ret;
    }
    ret->base_addr      = base;
    ret->dcr_addr       = dcr;

    if (ata_select_drive(ret, drive1)) {
        ret->drive_array[1] = init_ata_drive(ret);
    }
    if (ata_select_drive(ret, drive0)) {
        ret->drive_array[0] = init_ata_drive(ret);
    }
    return ret;
}

static void ata_init_all_buses(ata_ide *ide) {
    if (ide->iface.pci_primary_native_enabled) {
        /* TODO */
    } else {
        for (int i = 0; i < 4; i++) {
            uint16_t base = ata_ide_compability_base_addrs[i];
            uint16_t dcr  = ata_comp_base_to_dcr(base);
            ata_bus *bus = init_ata_bus(base, dcr);
            if (bus) {
                ide->bus_array[ide->bus_count] = bus;
                ide->bus_count++;
            }
        }
    }
}

ata_ide *ata_init_ide(device *ide) {
    ata_ide *ret = calloc(1, sizeof(ata_ide));
    if (!ret) {
        return ret;
    }
    pci_device_data *dev = ide->device_data;
    ret->ide_device_data = ide;
    ret->iface.raw       = dev->generic_header_fields.programming_interface_byte;
    ata_init_all_buses(ret);
    return ret;
}

/* Go through our array of identified PCI devices,
 * and try to bring up every IDE controller we've found.
 *
 * @param device **pci_device_array -- Pointer to device array
 * @param ata_ide **ata_ide_array   -- Where to store our ATA IDE structures
 * @param uint8_t pci_dev_cnt       -- Amount of devices we've found
 * @return uint8_t amount of IDE controllers we've intialized
 */
uint8_t init_ata_controllers(device **pci_device_array, ata_ide **ata_ide_array, uint8_t pci_dev_cnt) {
    uint8_t ide_count = 0;
    for (uint8_t offset = 0; offset < pci_dev_cnt; offset++) {
        device *dev = pci_device_array[offset];
        if (pcidev_is_ata_ide(dev) == false) {
            continue;
        }
        ata_ide *ide = ata_init_ide(dev);
        if (ide) {
            ata_ide_array[ide_count] = ide;
            ide_count++;
            ata_ide_array = realloc(ata_ide_array, ((ide_count + 1) * sizeof(ata_ide **)));
            if (!ata_ide_array) {
                panic("Out of memory, too many IDEs found!");
            }
        }
    }
    return ide_count;
}

