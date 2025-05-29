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
    uint32_t reg = pci_read_config(addr, 8);
    dev->generic_header_fields.class_code = pci_class(reg);
    dev->generic_header_fields.subclass = pci_subclass(reg);
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

static void pci_read_header(pci_device_data *dev) {
    uint32_t *hdr = (uint32_t *)&dev->generic_header_fields;
    for (int reg = 0; reg < 0x03; reg++) {
        hdr[reg] = pci_read_config(&dev->address, (reg * 4));
    }
    enum pci_header_type type = dev->generic_header_fields.header_type;
    int limit = (type == pci2cb_bridge_hdr) ? 0x11 : 0x0F;
    for (int reg = 0x4; reg < limit; reg++) {
        hdr[reg] = pci_read_config(&dev->address, (reg * 4));
    }
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
        dev->address = *addr;
        pci_device_array[offset]->device_data = (void *)dev;
        pci_read_header(dev);

        dev->bist_executed = pci_start_selftest(dev);
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

static const char *pci_get_dev_type_class_str(pci_device_data *dev) {
    if (dev->generic_header_fields.class_code < 0x14) {
        return pci_class_code_str[dev->generic_header_fields.class_code];
    }
    if (dev->generic_header_fields.cache_line_size == 0x40) {
        return "co-processor";
    }
    return pci_unknown_str;
}

static const char *pci_get_dev_type_subclass_str(pci_device_data *dev) {
    if (dev->generic_header_fields.subclass == 0x80) {
        return pci_unknown_str;
    }

    int off = 0;
    switch (dev->generic_header_fields.class_code) {
    case (pci_class_mass_storage_controller):
        break;
    case (pci_class_network_controller):
        off = 9;
        break;
    case (pci_class_display_controller):
        off = 18;
        break;
    case (pci_class_memory_controller):
        off = 21;
        break;
    case (pci_class_simple_communication_controller):
        off = 24;
        break;
    case (pci_class_base_system_peripheral):
        off = 31;
        break;
    case (pci_class_input_device_controller):
        off = 37;
        break;
    case (pci_class_serial_bus_controller):
        off = 41;
        break;
    case (pci_class_wireless_controller):
        off = 51;
        break;
    case (pci_class_bridge):
        off = 58;
        break;
    default:
        return pci_unknown_str;
    }
    off += dev->generic_header_fields.subclass;
    return pci_subclass_str[off];
}

/* Print pci device tree information
 *
 * @param device **pci_device_array -- Device array after enumerate_pci_buses() is done
 * @param uint8_t device_count -- Amount of devices we have
 */
void pci_print_devtree(device **pci_device_array, uint8_t count) {
    for (uint8_t off = 0; off < count; off++) {
        pci_device_data *dev = pci_device_array[off]->device_data;
        blogf("PCI @ %04x:%04x:%04x: %s %s controller\n",
            dev->address.bus, 
            dev->address.device, dev->address.function,
            pci_get_dev_type_subclass_str(dev),
            pci_get_dev_type_class_str(dev)
        );
        if (dev->bist_executed) {
            blog(" --> Self test executed\n");
        }
    }
}


