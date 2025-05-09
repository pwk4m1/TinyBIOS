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

#include <console/console.h>

#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>

#include <panic.h>

static void add_device_class(pci_device_data *dev, pci_config_address *addr) {
    uint32_t reg = pci_read_config(addr, 4);
    dev->class_code = pci_class(reg);
    dev->subclass = pci_subclass(reg);
}

/* Fetch device data for next device in our list
 * 
 * @param pci_device_data *dev     -- Pointer to pci_device_data structure
 * @param pci_config_address *addr -- Pointer to current pci_config_address to use
 * @return bool true if device data was added, false if no device is plugged in
 */
static inline void pci_add_device_data(pci_device_data *dev, pci_config_address *addr) {
    add_device_class(dev, addr);
    dev->bist_executed = pci_start_selftest(dev);
}

/* populate device structures for all devices in a given PCI bus
 *
 * @param device *pci_device_array -- Pointer to our pci device list
 * @param uint8_t offset           -- Offset to next device in the list
 * @param pci_config_address *addr -- Pointer to current pci_config_address to use
 * @return uint8_t amount of devices added
 */
static uint8_t pci_add_devices_from_bus(device **pci_device_array, uint8_t offset, pci_config_address *addr) {
    uint8_t count = 0;

    for (unsigned i = 0; i < 31; i++) {
        addr->device = i;
        uint32_t reg = pci_read_config(addr, 0);
        if (reg == 0xFFFFFFFF) {
            continue;
        }
        pci_device_array[offset] = calloc(1, sizeof(device));
        pci_device_data *dev     = calloc(1, sizeof(pci_device_data));
        if (!dev || !pci_device_array[offset]) {
            panic("%s: pci_add_devices_from_bus: out of memory\n", __FILE__);
        }
        pci_device_array[offset]->device_data = (void *)dev;
        dev->vendor_id = pci_vid(reg);
        dev->device_id = pci_did(reg);
        add_device_class(dev, addr);
        pci_add_device_data(dev, addr);
        dev->bist_executed = pci_start_selftest(dev);
        dev->address = *addr;
        pci_device_array[offset]->status = status_present;
        if (pci_dev_is_bridge(addr)) {
            pci_device_array[offset]->type = device_bridge;
        } else {
            pci_device_array[offset]->type = device_access_mmio;
        }
        count++;
        offset++;
    }
    return count;
}

static enum pci_header_type get_hdr_type(pci_config_address *addr) {
    return pci_header_type(pci_read_config(addr, 0x0C));
}

/* Fetch headers for all pci devices we have plugged in
 *
 * @param device *pci_device_array -- Pointer to pci device array
 * @return uint8_t amount of devices found or -1 on error
 */
uint8_t enumerate_pci_buses(device **pci_device_array) {
    bool multibus_system = false;
    uint8_t dev_cnt = 0;
    pci_config_address addr = {0};
    addr.enable = 1;

    uint32_t reg = pci_read_config(&addr, 0);
    if (pci_vid(reg) == 0xFFFF) {
        return 0;
    }
    if (get_hdr_type(&addr) & pci_mf_hdr) {
        multibus_system = true;
    }
    dev_cnt += pci_add_devices_from_bus(pci_device_array, 0, &addr);

    if (multibus_system) {
        pci_config_address current_addr = addr;
        do {
            addr.function++;
            if (pci_vid(pci_read_config(&addr, 0)) == 0xFFFF) {
                break;
            }
            current_addr.bus = addr.function;
            dev_cnt += pci_add_devices_from_bus(pci_device_array, dev_cnt, &current_addr);
        } while (addr.function < 8);
    }

    return dev_cnt;
}

