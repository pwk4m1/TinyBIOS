/*
 BSD 3-Clause License
 
 Copyright (c) 2024, k4m1
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
#ifndef __PIC_H__
#define __PIC_H__

#include <drivers/device.h>

#include <stdint.h>

#define PIC_EOI_MSG 0x20
#define PIC_PRIMARY_PORT 0x20
#define PIC_SECONDARY_PORT 0xA0

/* programmamble interrupt controller buffering mode
 *
 * @member not_buffered_{p, s} -- not buffered mode for both primary and
 *                                secondary devices
 * @member buffered_secondary  -- secondary interrupt controller is buffered
 * @member buffered_primary    -- primary interrupt controller is buffered
 */
enum PIC_BUFFER_MODE {
    not_buffered_p = 0,
    not_buffered_s,
    buffered_secondary,
    buffered_primary
};

/* programmamble interrupt controller end-of-interrupt modes
 *
 */
enum PIC_EOI_TYPE {
    non_specific_eoi = 1,
    no_operation,
    specific_eoi,
    rotate_in_auto_eoi,
    rotate_on_non_specific_eoi,
    set_priority,
    rotate_on_specific_eoi
};

/* programmable interrupt controller initialisation command word 1
 *
 * @member icw4_needed       -- 1 if icw4 is needed
 * @member cascading         -- 0 if cascading, 1 if single 8259
 * @member iv_size           -- 0 for 8-bit interrupt vectors, 1 for 4-bit
 * @member trigger_mode      -- 0 for level, 1 for edge trigger
 * @member icw_1             -- always 1
 * @member pc_system         -- always 0
 */
typedef struct __attribute__((packed)) {
    unsigned icw4_needed    : 1;
    unsigned cascading      : 1;
    unsigned iv_size        : 1;
    unsigned trigger_mode   : 1;
    unsigned icw_1          : 1;
    unsigned pc_system      : 3;
} pic_icw1;

/* programmable interrupt controller initialisation command word 2
 *
 * @member unsigned int zero        -- these 3 bits are always 0 for 80x86 & alike
 * @member unsigned int int_vector  -- A7-A3 of interrupt vector for 80x86
 */
typedef struct __attribute__((packed)) {
    unsigned zero       : 3;
    unsigned int_vector : 5;
} pic_icw2;

/* programmamble interrupt controller inititialisation command word 3
 * for primary interrupt controller.
 *
 * Each bit indicates that this interrupt has secondary device,
 * eg:
 * bit 1 is set => 2nd interrupt request has secondary device
 */
typedef struct {
    uint8_t device_map;
} pic_icw3_primary;

/* programmamble interrupt controller inititialisation command word 3
 * for secondary interrupt controller.
 *
 * @member primary_int  -- primary interrupt request this device is attached to 
 * @member zero         -- always 0
 */
typedef struct __attribute__((packed)) {
    unsigned primary_int : 3;
    unsigned zero        : 5;
} pic_icw3_secondary;

/* programmamble interrupt controller inititialisation command word 4
 *
 * @member mode         -- 0 for 80x86, 1 for 80x85 (8086)
 * @member auto_eoi     -- 1 for automatic end-of-interrupt, 0 for normal
 * @member buffered     -- refer to enum PIC_BUFFER_MODE
 * @member sequential   -- 0 for sequential, 1 for special fully nested mode
 * @member zero         -- always 0
 */
typedef struct __attribute__((packed)) {
    unsigned mode                 : 1;
    unsigned auto_eoi             : 1;
    enum PIC_BUFFER_MODE buffered : 2;
    unsigned sequential           : 1;
    unsigned zero                 : 3;
} pic_icw4;

/* programmable interrupt controller operation word 2 for ports 21 and A1
 * 
 * @member int_level        -- interrupt request level to act upon
 * @member zero             -- always 0
 * @member end_of_int_type  -- refer to enum PIC_EOI_TYPE
 */
typedef struct __attribute__((packed)) {
    unsigned int_level      : 3;
    unsigned zero           : 2;
    enum PIC_EOI_TYPE type  : 3;
} pic_ocw2;

/* programmable interrupt controller operation word 3 for ports 20 and A0 
 *
 * @member next       -- 1 for reading IRR, 0 for ISR
 * @member nop_b0     -- 1 to act if bit 0 is set, 0 to NOP
 * @member poll       -- 1 if we've issued poll command
 * @member ident      -- always 10
 * @member reset_mask -- Set to 0 to reset special mask, 1 to set it
 * @member nop_b5     -- 1 to act if bit 5 is set, 0 to NOP
 * @member zero       -- always 0 
 */
typedef struct __attribute__((packed)) {
    unsigned next          : 1;
    unsigned nop_b0        : 1;
    unsigned poll          : 1;
    unsigned ident         : 2;
    unsigned reset_mask    : 1;
    unsigned nop_b5        : 1;
    unsigned zero          : 1;
} pic_ocw3;

typedef struct {
    pic_ocw2 *ocw2;
    pic_ocw3 *ocw3;
    pic_icw1 *icw1;
    pic_icw2 *icw2;
    pic_icw3_primary *icw3_primary;
    pic_icw3_secondary * icw3_secondary;
    pic_icw4 *icw4;
} pic_full_configuration;

/* Mask irq line
 *
 * @param uint8_t line -- line to mask 
 */
void pic_mask_irq(uint8_t line);

/* Unmask irq line
 *
 * @param uint8_t line -- line to mask 
 */
void pic_unmask_irq(uint8_t line);

/* Send end of interrupt message to the programmable interrupt controller.
 *
 * @param uint8_t irq -- number of interrupt we're dealing with
 */
void pic_send_eoi(uint8_t irq);

/* Initialise the programmable interrupt controller.
 *
 * @param pio_device *dev -- pointer to pio_device structure for PIC
 * @param char *name      -- name of the device
 * @return bool true on success or false on error.
 */
bool pic_initialize(pio_device *dev, char *name);

/* Read irq register from the programmable interrupt controller.
 *
 */
uint16_t pic_read_irq(pic_ocw3 *ocw);

/* Get in-service register value (Which irqs are served)
 *
 * @return uint16_t isr in form of SECONDARY << 8 | PRIMARY
 */
uint16_t pic_read_isr(void);

/* Get interrupt request register value (Which interrupts have been raised)
 *
 * @return uint16_t irr in form of SECONDARY << 8 | PRIMARY
 */
uint16_t pic_read_irr(void);

#endif // __PIC_H__
