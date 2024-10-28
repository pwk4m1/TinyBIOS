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

#include <sys/io.h>

#include <drivers/device.h>
#include <drivers/pic_8259/pic.h>

#include <stdbool.h>
#include <stdint.h>

pic_ocw2 pic_current_ocw2 = {0};
pic_ocw3 pic_current_ocw3 = {0};

pic_icw1 pic_current_icw1 = {0};
pic_icw2 pic_current_icw2 = {0};
pic_icw3_primary pic_picw3 = {0};
pic_icw3_secondary pic_sicw3 = {0};
pic_icw4 pic_current_icw4 = {0};

pic_full_configuration *pic_config;

/* Helper to send control words to interrupt controller(s)
 *
 * @param uint16_t port -- which pic we're talking to
 * @param uint8_t *cw   -- pointer to control word to send
 */
static inline void pic_send_cmd(uint16_t port, uint8_t *cw) {
    outb(*cw, port);
    iodelay(50);
}

/* Send data to programmable interrupt controller
 *
 * @param uint16_t port -- which pic we're talking to
 * @param uint8_t *dw   -- pointer to data word to send
 */
static inline void pic_send_data(uint16_t port, uint8_t *ow) {
    outb(*ow, port+1);
    iodelay(50);
}

/* Send end of interrupt message to the programmable interrupt controller.
 *
 * @param uint8_t irq -- number of interrupt we're dealing with
 */
void pic_send_eoi(uint8_t irq) {
    if (irq >= 7) {
        outb(0x20, PIC_PRIMARY_PORT); 
    }
    outb(0x20, PIC_SECONDARY_PORT);
}

/* Initialise the programmable interrupt controller.
 * 
 * @param pio_device *dev -- pio_device structure for pic
 * @param char *name      -- name of this device
 * @return bool true on success, false on error.
 */
bool pic_initialise(pio_device *dev, char *name) {
    pic_current_icw1.icw4_needed = 1;
    pic_current_icw1.icw_1 = 1;

    // Start pic_initialisation sequence with command words 1 to 4
    pic_send_cmd(PIC_PRIMARY_PORT, (uint8_t*)&pic_current_icw1);
    pic_send_cmd(PIC_SECONDARY_PORT, (uint8_t*)&pic_current_icw1);

    // Send interrupt vector offsets (0, 0)
    pic_send_data(PIC_PRIMARY_PORT, (uint8_t *)&pic_current_ocw2);
    pic_send_data(PIC_SECONDARY_PORT, (uint8_t *)&pic_current_ocw2);

    // Send device cascading config (irq2 => secondary PIC, cascading identity to
    // secondary PIC)
    //
    pic_picw3.device_map = 4;
    pic_sicw3.primary_int = 2;

    pic_send_data(PIC_PRIMARY_PORT, (uint8_t *)&pic_picw3);
    pic_send_data(PIC_SECONDARY_PORT, (uint8_t *)&pic_sicw3);

    // Set both PICs to 8086 mode
    pic_current_icw4.mode = 1;
    
    pic_send_data(PIC_PRIMARY_PORT, (uint8_t *)&pic_current_icw4);
    pic_send_data(PIC_SECONDARY_PORT, (uint8_t *)&pic_current_icw4);

    // Mask away all interrupts for now, each handler should unmask
    // corresponding line.
    //
    uint8_t data = 0xff;
    pic_send_data(PIC_PRIMARY_PORT, &data);
    pic_send_data(PIC_SECONDARY_PORT, &data);

    pic_config->icw1 = &pic_current_icw1;
    pic_config->icw2 = &pic_current_icw2;
    pic_config->icw3_primary = &pic_picw3;
    pic_config->icw3_secondary = &pic_sicw3;
    pic_config->icw4 = &pic_current_icw4;
    pic_config->ocw2 = &pic_current_ocw2;
    pic_config->ocw3 = &pic_current_ocw3;

    dev->device_name = name;
    dev->device_data = &pic_config;
    dev->status = initialised;
    dev->type = device_other;
    
    return true;
}

/* Read irq register from the programmable interrupt controller.
 *
 * @param pic_ocw3 *ocw -- command byte to send
 * @return uint16_t irq
 */
uint16_t pic_read_irq(pic_ocw3 *ocw) {
    pic_send_cmd(PIC_PRIMARY_PORT, (uint8_t *)ocw);
    pic_send_cmd(PIC_SECONDARY_PORT, (uint8_t *)ocw);
    uint16_t ret = inb(PIC_SECONDARY_PORT) << 8;
    ret |= inb(PIC_PRIMARY_PORT);
    return ret;
}

/* Get in-service register value (Which irqs are served)
 *
 * @return uint16_t isr in form of SECONDARY << 8 | PRIMARY
 */
uint16_t pic_read_isr(void) {
    pic_ocw3 ocw = {0}; 
    ocw.nop_b0 = 1;
    ocw.ident = 2;
    return pic_read_irq(&ocw);
}

/* Get interrupt request register value (Which interrupts have been raised)
 *
 * @return uint16_t irr in form of SECONDARY << 8 | PRIMARY
 */
uint16_t pic_read_irr(void) {
    pic_ocw3 ocw = {0};
    ocw.next = 1;
    ocw.nop_b0 = 1;
    ocw.ident = 2;
    return pic_read_irq(&ocw);
}

