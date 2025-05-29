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

/* Check if given PCI device is ata-ide for us
 *
 * @param device *dev -- Device we're working with
 * @return bool true if this is ata-ide 
 */
bool pcidev_is_ata_ide(device *dev) {
    pci_device_data *pci = (pci_device_data *)dev->device_data;
    if (pci->generic_header_fields.class_code == pci_class_mass_storage_controller) {
        switch (pci->generic_header_fields.subclass) {
        case (pci_mass_storage_controller_ide_controller):
        case (pci_mass_storage_controller_ata_controller):
        case (pci_mass_storage_controller_sata_controller):
            dev->type = device_access_pio;
            return true;
        }
    }
    return false;
}

/* Reset both drives on this bus
 *
 * @param ata_bus *bus -- Bus we're working with
 */
void ata_bus_reset(ata_bus *bus) {
    ata_register reg = {0};
    reg.ctrl.disable_interrupts = true;
    reg.ctrl.sw_reset = true;
    ata_write_register(bus->dcr_addr, reg);
    reg.ctrl.sw_reset = false;
    ata_write_register(bus->dcr_addr, reg);
}

/* Wait for given ata settings to change at status register
 *
 * @param ata_bus *bus -- Ata bus we're working with
 * @param uint8_t mask -- Flags to wait for
 * @param bool set     -- Are we waiting for these flags to be set or clear
 * @param uint8_t wait -- Timeout 
 * @return bool true if changes happen, false if timeout or error is encountered
 */
bool ata_waitfor_status(ata_bus *bus, uint8_t mask, bool set, uint8_t wait) {
    ata_register reg = {0};
    for ( ; wait > 0; wait--) {
        reg = ata_read_status(bus);
        if (reg.status.error) {
            break;
        }
        reg.raw &= mask;
        if (set && (reg.raw == mask)) {
            return true;
        }
        if (!set && (reg.raw == 0)) {
            return true;
        }
    }
    return false;
}

/* Select given disk from ata bus
 *
 * @param ata_bus *bus              -- Ata bus we're working with
 * @param ata_drive_selection drive -- Drive to select
 * @return bool true if drive got selected, false on error
 */
bool ata_select_drive(ata_bus *bus, ata_drive_selection drive) {
    if (bus->active_drive != drive) {
        /* Set always_set bits on */
        ata_register reg = {0xA0};
        reg.drive_head.drive_selection = drive;
        ata_write_drive_head(bus, reg);
        reg = ata_read_drive_address(bus);
        bool select_err = (drive == drive0) ? reg.drive_addr.drive_0_selected : reg.drive_addr.drive_1_selected;
        if (!select_err) {
            bus->active_drive = drive;
        }
    }
    return (bus->active_drive == drive);
}


