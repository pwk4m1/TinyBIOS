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
#ifndef __PCI_H__
#define __PCI_H__

#include <sys/io.h>
#include <drivers/device.h>

#include <stdint.h>

static const int PCI_MAX_DEVICES = 24;

enum pci_class_code {
    pci_class_unclassified = 0,
    pci_class_mass_storage_controller,
    pci_class_network_controller,
    pci_class_display_controller,
    pci_class_multimedia_controller,
    pci_class_memory_controller,
    pci_class_bridge,
    pci_class_simple_communication_controller,
    pci_class_base_system_peripheral,
    pci_class_input_device_controller,
    pci_class_docking_station,
    pci_class_processor,
    pci_class_serial_bus_controller,
    pci_class_wireless_controller,
    pci_class_intelligent_controller,
    pci_class_satellite_communication_controller,
    pci_class_encryption_controller,
    pci_class_signal_processing_controller,
    pci_class_processing_accelerator,
    pci_class_non_essential,
    pci_class_co_processor = 0x40,
    pci_class_unassigned = 0xFF
};

enum unclassified_devices {
    non_vga_unclassified,
    vga_compatible_unclassified
};

enum mass_storage_controllers {
    pci_mass_storage_controller_scsi_bus_controller,
    pci_mass_storage_controller_ide_controller,
    pci_mass_storage_controller_floppy_controller,
    pci_mass_storage_controller_ipi_bus_controller,
    pci_mass_storage_controller_raid_controller,
    pci_mass_storage_controller_ata_controller,
    pci_mass_storage_controller_sata_controller,
    pci_mass_storage_controller_serial_scsi_controller,
    pci_mass_storage_controller_nv_memory_controller,
    pci_mass_storage_controller_other_storage = 0x80
};

enum pci_bridge_type {
    pci_host_bridge,
    pci_isa_bridge,
    pci_eisa_bridge,
    pci_mca_bridge,
    pci_pci2pci_bridge,
    pci_pcmcia_bridge,
    pci_nubus_bridge,
    pci_cardbus_bridge,
    pci_raceway_bridge,
    pci_pci2pci_bridge2,
    pci_infiband_to_pci_host,
    pci_other_bridge = 0x80
};

typedef struct {
    uint32_t bar0;
    uint32_t bar1;
    uint32_t bar2;
    uint32_t bar3;
    uint32_t bar4;
    uint32_t bar5;
    uint32_t cardbus_cis_ptr;
    uint16_t subsystem_vendor_id;
    uint16_t subsystem_id;
    uint32_t expansion_rom_bar;
    uint8_t  capabilities;
    uint16_t reserved0;
    uint8_t  reserved2;
    uint32_t reserved3;
    uint8_t  interrupt_line;
    uint8_t  interrupt_pin;
    uint8_t  min_grant;
    uint8_t  max_latency;
} pci_general_device_data;

typedef struct {
    uint32_t bar0;
    uint32_t bar1;
    uint8_t  primary_bus_number;
    uint8_t  secondary_bus_number;
    uint8_t  subordinate_bus_number;
    uint8_t  secondary_latency_timer;
    uint8_t  io_base;
    uint8_t  io_limit;
    uint16_t secondary_status;
    uint16_t memory_base;
    uint16_t memory_limit;
    uint16_t prefetch_memory_base;
    uint16_t prefetch_memory_limit;
    uint32_t prefetch_base_hi;
    uint32_t prefetch_limit_hi;
    uint16_t io_base_hi;
    uint16_t io_limit_hi;
    uint8_t  capabilities;
    uint16_t reserved0;
    uint8_t  reserved1;
    uint32_t expansion_rom_bar;
    uint8_t  interrupt_line;
    uint8_t  interrupt_pin;
    uint16_t bridge_control;
} pci2pci_bridge_data;

typedef struct {
    uint16_t device_id;
    uint16_t vendor_id;
    uint16_t status;
    uint16_t command;
    uint8_t  class_code;
    uint8_t  subclass;
    uint8_t  prog_if;
    uint8_t  revision_id;
    uint8_t  bist;
    uint8_t  header_type;
    uint8_t  latency_timer;
    uint8_t  cache_line_size;
    uint32_t cb_socket_bar;
    uint16_t secondary_status;
    uint8_t  reserved;
    uint8_t  offset_of_capabilities_list;
    uint8_t  cardbus_latency_timer;
    uint8_t  subordinate_bus_number;
    uint8_t  cardbus_bus_number;
    uint8_t  pci_bus_number;
    uint32_t memory_base_0;
    uint32_t memory_limit_0;
    uint32_t memory_base_1;
    uint32_t memory_limit_1;
    uint32_t io_base_0;
    uint32_t io_limit_0;
    uint32_t io_base_1;
    uint32_t io_limit_1;
    uint16_t bridge_control;
    uint8_t  interrupt_pin;
    uint8_t  interrupt_line;
    uint16_t subsystem_vendor_id;
    uint16_t subsystem_device_id;
    uint32_t legacy_card_bar;
} pci2cbus_bridge_data;

typedef struct {
    uint16_t vendor_id;
    uint16_t device_id;
    uint16_t command;
    uint16_t status;
    uint8_t  revision_id;
    uint8_t  programming_interface_byte;
    uint8_t  subclass;
    uint8_t  class_code;
    uint8_t  cache_line_size;
    uint8_t  latency_timer;
    uint8_t  header_type;
    uint8_t  built_in_self_test;
} pci_header;

enum pci_header_type {
    pci_std_hdr,
    pci2pci_bridge_hdr,
    pci2cb_bridge_hdr,
    pci_mf_hdr = 0x80
};

/* PCI BIST register definition
 *
 */
typedef struct __attribute__((packed)) {
    unsigned completion_code : 4;
    unsigned reserved : 2;
    unsigned start_bist : 1;
    unsigned bist_capable : 1;
} pci_bist_register_fields;

typedef union {
    uint8_t register_raw;
    pci_bist_register_fields fields;
} pci_bist_register;

/* PIO addresses for PCI configuration and data.
 */
static const uint16_t pci_config_port = 0x0CF8;
static const uint16_t pci_data_port = 0x0CFC;

/* PCI Configuration address
 *
 * @member enable   -- Set to one to enable
 * @member reserved -- Set to 0
 * @member bus      -- Which PCI bus we're working with
 * @member device   -- Which PCI device in that bus we're working with
 * @member function -- Which device function do we want
 * @member offset   -- Which dword out of the 256-byte configuration space
 *                     are we interested in
 */
typedef struct __attribute__((packed)) {
    unsigned offset     : 8;
    unsigned function   : 3;
    unsigned device     : 5;
    unsigned bus        : 8;
    unsigned reserved   : 7;
    unsigned enable     : 1;
} pci_config_address;


/* Structure for holding information about our pci subsystem
 *
 */
typedef struct {
    pci_config_address address;
    uint16_t vendor_id;
    uint16_t device_id;
    uint8_t class_code;
    uint8_t subclass;
    bool bist_executed;
} pci_device_data;

/* Fetch headers for all pci devices we have plugged in
 *
 * @param device *pci_device_array -- Pointer to pci device data
 * @return uint8_t amount of devices found or -1 on error
 */
uint8_t enumerate_pci_buses(device *pci_device_array);

#endif // __PCI_H__
