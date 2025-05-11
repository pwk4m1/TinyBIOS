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

static uint8_t pci_prog_if(uint32_t pci_reg) {
    return (uint8_t)(pci_reg >> 8);
}

static uint16_t pci_io_base(uint32_t pci_reg) {
    return (uint16_t)(pci_reg);
}

static uint16_t pci_io_limit(uint32_t pci_reg) {
    return (uint16_t)(pci_reg >> 16);
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

static pci_bar pci_read_bar(pci_config_address *addr, uint8_t bar) {
    pci_bar ret;
    ret.raw_bar = pci_read_config(addr, (0x10 + (bar * 4)));
    return ret;
}

/* Check if bar is for memory space or I/O
 *
 * @param uint32_t bar -- bar to check
 * @return bool true if this is io-space bar
 */
static inline bool pci_io_bar(pci_bar bar) {
    return ((bar.raw_bar & 1) == 1);
}

/* decode pci io bar
 *
 * @param pci_bar bar
 * @return decoded io-bar address
 */
static inline uint32_t decode_io_bar(pci_bar bar) {
    return (bar.raw_bar & 0xFFFFFFFC);
}

/* decode pci mem bar
 *
 * @param pci_bar bar
 * @return decoded mem-bar address on success or 0 on error
 */
static inline uint32_t decode_mem_bar(pci_bar bar) {
    if (bar.memory_bar.type == 0) {
        return (bar.raw_bar & 0xFFFFFFF0);
    } else if (bar.memory_bar.type == 1) {
        return (bar.raw_bar & 0x0000FFF0);
    } else {
        return 0;
    }
}


/* Get decoded PCI bar address
 *
 * @param pci_bar bar -- bar to decode
 * @return uint32_t address
 */
static inline uint32_t pci_decode_bar(pci_bar bar) {
    if (pci_io_bar(bar)) {
        return decode_io_bar(bar);
    }
    return decode_mem_bar(bar);
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

/* Check status of device self test
 *
 * @param pci_device_data *dev -- Pointer to pci_device_data structure
 * @return bool true if self test succeeded
 */
static inline bool pci_selftest_success(pci_device_data *dev) {
    pci_bist_register reg = pci_read_bist(dev);
    return (reg.fields.completion_code == 0);
}

/* Start device self test if it's supported
 *
 * @param pci_device_data *dev -- Pointer to pci_device_data structure
 * @return bool started
 */
bool pci_start_selftest(pci_device_data *dev);

#endif // __PCI_H__
