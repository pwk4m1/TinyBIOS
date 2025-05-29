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
#ifndef __ATA_H__
#define __ATA_H__

#include <sys/io.h>
#include <drivers/device.h>
#include <drivers/pci/pci.h>
#include <drivers/pci/pci_util.h>

#include <console/console.h>

#include <stdbool.h>
#include <stdint.h>

enum ata_drive_id {
    ata_drive_id_not_ata = -1,
    ata_drive_id_ata   = 1,
    ata_drive_id_sata  = 0x3cc3,
    ata_drive_id_atapi = 0x14eb
};

static const uint8_t ata_cmd_identify = 0xEC;

static const uint16_t ata_ide_compability_base_addrs[] = {0x01f0, 0x0170, 0x01e8, 0x0168};

static inline uint16_t ata_comp_base_to_dcr(uint16_t base) {
    return (base | 0x0206);
}

typedef struct __attribute__((packed)) {
    bool error          : 1;
    bool index          : 1;
    bool corrected      : 1;
    bool transmit_ready : 1;
    bool overlap_msr    : 1;
    bool drive_fault    : 1;
    bool drive_ready    : 1;
    bool drive_busy     : 1;
} ata_status_register;

typedef struct __attribute__((packed)) {
    bool address_mark_not_found : 1;
    bool track_zero_not_found   : 1;
    bool abort                  : 1;
    bool media_change_request   : 1;
    bool id_not_found           : 1;
    bool uncorrectable_data     : 1;
    bool bad_block              : 1;
} ata_error_register;

typedef struct __attribute__((packed)) {
    unsigned lba_hi      : 3;
    bool drive_selection : 1;
    bool always_set      : 1;
    bool use_lba         : 1;
    bool always_set_2    : 1;
} ata_drive_head_register;

typedef struct __attribute__((packed)) {
    bool always_zero        : 1;
    bool disable_interrupts : 1;
    bool sw_reset           : 1;
    unsigned reserved       : 4;
    bool hob                : 1;
} ata_device_ctrl_register;

typedef struct __attribute__((packed)) {
    bool drive_0_selected  : 1;
    bool drive_1_selected  : 1;
    unsigned hamming_sum   : 4;
    bool write_in_progress : 1;
    bool reserved          : 1;
} ata_drive_address_register;

typedef union {
    uint8_t raw;
    ata_status_register status;
    ata_error_register error;
    ata_drive_head_register drive_head;
    ata_device_ctrl_register ctrl;
    ata_drive_address_register drive_addr;
} ata_register;

typedef struct {
    uint16_t general_config;
    uint16_t cylinder_count;
    uint16_t specific_config;
    uint16_t head_count;
    uint32_t reserved;
    uint16_t sectors_per_track;
    uint8_t vendor_id[6];
    uint8_t serial_number[20];
    uint8_t reserved2[6];
    uint8_t firmware_revision[8];
    uint8_t model[40];
    uint8_t max_blk_transfer;
    uint8_t vendor_id_2;
    uint16_t trusted_computing_supported;
    uint16_t capabilities;
    uint16_t reserved3;
    uint32_t reserved4;
    uint8_t translation_field;
    uint8_t freefallctl_sense;
    uint16_t current_cylinders;
    uint16_t current_heads;
    uint16_t current_sector_per_track;
    uint32_t current_sector_capacity;
    uint8_t current_multisector_setting;
    uint8_t features;
    uint32_t adressable_sectors;
    uint16_t reserved5;
    uint8_t multiword_dma_supported;
    uint8_t multiword_dma_enabled;
    uint8_t advanced_pio_modes;
    uint8_t reserved6;
    uint16_t min_mwtransfer_cycle_time;
    uint16_t recommended_mwtransfer_cycle_time;
    uint16_t min_pio_time;
    uint16_t min_pio_time_ioready;
    uint16_t additional_features_supported;
    uint8_t reserved7[10];
    uint16_t queue_depth;
    uint32_t sata_capabilities;
    uint16_t sata_features_supported;
    uint16_t sata_features_enabled;
    uint16_t disk_rev_major;
    uint16_t disk_rev_minor;
    uint8_t commandset_supported[6];
    uint8_t commandset_active[6];
    uint8_t ultra_dma_supported;
    uint8_t ultra_dma_enabled;
    uint16_t security_erase_unit;
    uint16_t security_erase_unit_enhanced;
    uint8_t current_apm_level;
    uint8_t reserved8;
    uint16_t primary_password_id;
    uint16_t hw_rst_result;
    uint8_t curr_acoustic_value;
    uint8_t recommended_acoustic_value;
    uint16_t dma_stream_min_request_size;
    uint16_t dma_streaming_tx_time;
    uint16_t access_latency;
    uint32_t streaming_perf_granularity;
    uint64_t max48bit_lba;
    uint16_t stream_transfer_time;
    uint16_t dsm_cap;
    uint16_t physical_logical_sector_size;
    uint16_t interseek_delay;
    uint64_t wwname;
    uint64_t wwname_reserved;
    uint16_t words_per_sector;
    uint16_t extended_commandset_supported;
    uint16_t extended_commandset_enabled;
    uint32_t reserved9[3];
    uint16_t msn_support;
    uint16_t security_status;
    uint8_t reserved10[62];
    uint16_t cfa_powermode;
    uint8_t reserved11[14];
    uint16_t nominal_form_factor;
    uint16_t dataset_management_features;
    uint64_t additional_id;
    uint32_t reserved12;
    uint8_t current_media_serial[60];
    uint16_t sct_cmd_transport;
    uint32_t reserved13;
    uint16_t block_alignment;
    uint32_t rw_verify_sector_count_mode3;
    uint32_t rw_verify_sector_count_mode2;
    uint16_t nv_cache_capabilities;
    uint32_t nv_cache_size;
    uint16_t nominal_media_rotation_rate;
    uint16_t reserved14;
    uint16_t nv_cache_options;
    uint8_t rw_verify_sector_count_mode;
    uint16_t reserved15;
    uint32_t transport_version;
    uint32_t reserved16[3];
    uint64_t extended_number_of_addressable_sectors;
    uint32_t blocks_per_microcode_dl;
    uint8_t reserved17[38];
    uint8_t signature;
    uint8_t checksum;    
} ata_drive_header;

typedef enum {
    drive0 = 0x00,
    drive1 = 0x01
} ata_drive_selection;

typedef union {
    struct __attribute__((packed)) {
        bool pci_primary_native_enabled     : 1;
        bool pci_primary_native_supported   : 1;
        bool pci_secondary_native_enabled   : 1;
        bool pci_secondary_native_supported : 1;
        unsigned reserved                   : 2;
        bool dma_supported                  : 1;
    };
    uint8_t raw;
} ata_pci_iface;

typedef struct {
    ata_drive_header *hdr_addr;
    enum ata_drive_id drive_id;
    uint16_t *dma_ptr;
} ata_drive;

typedef struct {
    ata_drive **drive_array;
    ata_drive_selection active_drive;
    uint8_t drive_count;
    uint16_t base_addr;
    uint16_t dcr_addr;
} ata_bus;

typedef struct {
    ata_pci_iface iface;
    ata_bus **bus_array;
    uint8_t bus_count;
    device *ide_device_data;
} ata_ide;

/* Read given ata register
 *
 * @param uint16_t addr -- Register to read
 * @return ata_register register-value
 */
static inline ata_register ata_read_register(uint16_t addr) {
    ata_register ret;
    ret.raw = inb(addr);
    return ret;
}

static inline ata_register ata_read_error(ata_bus *bus) {
    return ata_read_register(bus->base_addr + 1);
}

static inline ata_register ata_read_sector_count(ata_bus *bus) {
    return ata_read_register(bus->base_addr + 2);
}

static inline ata_register ata_read_lba_lo(ata_bus *bus) {
    return ata_read_register(bus->base_addr + 3);
}

static inline ata_register ata_read_lba_mi(ata_bus *bus) {
    return ata_read_register(bus->base_addr + 4);
}

static inline ata_register ata_read_lba_hi(ata_bus *bus) {
    return ata_read_register(bus->base_addr + 5);
}

static inline ata_register ata_read_drive_head(ata_bus *bus) {
    return ata_read_register(bus->base_addr + 6);
}

static inline ata_register ata_read_status(ata_bus *bus) {
    return ata_read_register(bus->base_addr + 7);
}

static inline ata_register ata_read_drive_address(ata_bus *bus) {
    return ata_read_register(bus->dcr_addr + 1);
}

static inline void ata_write_register(uint16_t ata_addr, ata_register reg) {
    outb(reg.raw, ata_addr);
}

static inline void ata_write_features(ata_bus *bus, ata_register reg) {
    ata_write_register(bus->base_addr + 1, reg);
}

static inline void ata_write_sector_count(ata_bus *bus, ata_register reg) {
    ata_write_register(bus->base_addr + 2, reg);
}

static inline void ata_write_lba_lo(ata_bus *bus, ata_register reg) {
    ata_write_register(bus->base_addr + 3, reg);
}

static inline void ata_write_lba_mi(ata_bus *bus, ata_register reg) {
    ata_write_register(bus->base_addr + 4, reg);
}

static inline void ata_write_lba_hi(ata_bus *bus, ata_register reg) {
    ata_write_register(bus->base_addr + 5, reg);
}

static inline void ata_write_drive_head(ata_bus *bus, ata_register reg) {
    ata_write_register(bus->base_addr + 6, reg);
}

static inline void ata_write_command(ata_bus *bus, ata_register reg) {
    ata_write_register(bus->base_addr + 7, reg);
}

static inline bool ata_no_drives_in_bus(uint16_t port) {
    ata_register reg = ata_read_register(port);
    return (reg.raw == 0xFF);
}

/* Read 1 data word from currently active ata bus
 *
 * @param ata_bus *bus -- Bus to work with
 * @return uint16_t data-word
 */
static inline uint16_t ata_read_data(ata_bus *bus) {
    return inw(bus->base_addr);
}

/* Check if given PCI device is ata-ide for us
 *
 * @param device *dev -- Device we're working with
 * @return bool true if this is ata-ide 
 */
bool pcidev_is_ata_ide(device *dev);

/* Select given disk from ata bus
 *
 * @param ata_bus *bus              -- Ata bus we're working with
 * @param ata_drive_selection drive -- Drive to select
 * @return bool true if drive got selected, false on error
 */
bool ata_select_drive(ata_bus *bus, ata_drive_selection drive);

/* Go through our array of identified PCI devices,
 * and try to bring up every IDE controller we've found.
 *
 * @param device **pci_device_array -- Pointer to device array
 * @param ata_ide **ata_ide_array   -- Where to store our ATA IDE structures
 * @param uint8_t pci_dev_cnt       -- Amount of devices we've found
 * @return uint8_t amount of IDE controllers we've intialized
 */
uint8_t init_ata_controllers(device **pci_device_array, ata_ide **ata_ide_array, uint8_t pci_dev_cnt);

 /* Wait for given ata settings to change at status register
 *
 * @param ata_bus *bus -- Ata bus we're working with
 * @param uint8_t mask -- Flags to wait for
 * @param bool set     -- Are we waiting for these flags to be set or clear
 * @param uint8_t wait -- Timeout 
 * @return bool true if changes happen, false if timeout or error is encountered
 */
bool ata_waitfor_status(ata_bus *bus, uint8_t mask, bool set, uint8_t wait);
 
#endif // __ATA_H__
