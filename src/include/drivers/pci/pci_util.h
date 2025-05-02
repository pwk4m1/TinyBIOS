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

#ifndef __PCI_UTIL_H__
#define __PCI_UTIL_H__

#include <stdint.h>

#include <drivers/pci/pci.h>

/* helpers to read specific values out of pci config register
 *
 * @param uint32_t register -- register to read from
 * @return <desired value>
 */
static uint16_t pci_did(uint32_t pci_reg) {
    return (uint16_t)(pci_reg >> 16);
}

static uint16_t pci_vid(uint32_t pci_reg) {
    return (uint16_t)(pci_reg & 0x0000FFFF);
}

static enum pci_class_code pci_class(uint32_t pci_reg) {
    return (uint8_t)(pci_reg >> 24);
}

static uint8_t pci_subclass(uint32_t pci_reg) {
    return (uint8_t)(pci_reg >> 16);
}

static uint8_t pci_header_type(uint32_t pci_reg) {
    return (uint8_t)(pci_reg >> 16);
}

/* Read PCI Configuration dword with given address
 *
 * @param pci_config_address *addr -- PCI configuration address to read
 * @param uint8_t offset           -- Offset in pci configuration space to use
 * @return uint32_t configuration dword we received
 */
uint32_t pci_read_config(pci_config_address *addr, uint8_t offset);

/* Write PCI Configuration dword with given address
 *
 * @param pci_config_address *addr -- PCI configuration address to read
 * @param uint8_t offset           -- Offset in pci configuration space to use
 * @param uint32_t data            -- configuration dword to write 
 */
void pci_write_config(pci_config_address *addr, uint8_t offset, uint32_t data);

static pci_bist_register pci_read_bist(pci_device_data *dev) {
    dev->address.offset = 0;
    pci_bist_register ret;
    ret.register_raw = (uint8_t)(pci_read_config(&dev->address, 0x0C) >> 24);
    return ret;
}

/* Check if this device is a pci<->pci bridge
 *
 * @param pci_config_address *addr -- PCI configuration address to read
 * @return bool true if this is indeed, a pci2pci bridge
 */
static inline bool pci_dev_is_bridge(pci_config_address *addr) {
    uint32_t reg = pci_read_config(addr, 8);
    if (pci_class(reg) == pci_class_bridge) {
        enum pci_bridge_type type = pci_subclass(reg);
        if (type == pci_pci2pci_bridge) {
            return true;
        }
    }
    return false;
}

/* Start device self test if it's supported
 *
 * @param pci_device_data *dev -- Pointer to pci_device_data structure
 * @return bool started
 */
bool pci_start_selftest(pci_device_data *dev);

#endif // __PCI_H__
