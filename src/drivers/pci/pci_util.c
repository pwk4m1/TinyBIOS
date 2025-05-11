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

#include <stdbool.h>
#include <stdint.h>

/* Read PCI Configuration dword with given address
 *
 * @param pci_config_address *addr -- PCI configuration address to read
 * @param uint8_t offset           -- Offset in pci configuration space to use
 * @return uint32_t configuration word we received
 */
uint32_t pci_read_config(pci_config_address *addr, uint8_t offset) {
    addr->offset = offset;
    outl(to_uint32_t(addr), pci_config_port);
    addr->offset = 0;
    return inl(pci_data_port);
}

/* Write PCI Configuration dword with given address
 *
 * @param pci_config_address *addr -- PCI configuration address to read
 * @param uint8_t offset           -- Offset in pci configuration space to use
 * @param uint32_t data            -- configuration dword to write 
 */
void pci_write_config(pci_config_address *addr, uint8_t offset, uint32_t data) {
    addr->offset = offset;
    outl(to_uint32_t(addr), pci_config_port);
    outl(data, pci_data_port);
    addr->offset = 0;
}

/* Start device self test if it's supported
 *
 * @param pci_device_data *dev -- Pointer to pci_device_data structure
 * @return bool started
 */
bool pci_start_selftest(pci_device_data *dev) {
    pci_bist_register reg;
    reg.register_raw = dev->generic_header_fields.built_in_self_test;
    if (reg.fields.bist_capable) {
        reg.fields.start_bist = 1;
        pci_write_config(&dev->address, 0x0C, reg.register_raw);
        return true;
    }
    return false;
}

