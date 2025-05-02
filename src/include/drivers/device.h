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

#ifndef __DRIVER_DEVICE_GENERIC__
#define __DRIVER_DEVICE_GENERIC__

#include <stddef.h>

// Generic status for all devices we have.
enum DEVICE_STATUS {
    status_unknown,        // We haven't started initialising device or can't determine it's state
    status_not_present,    // There's no device plugged into this port 
    status_present,        // We know the device is plugged in, but we haven't tried to initialize it yet.
    status_faulty,         // device initialisation incomplete and/or device is misbehaving
    status_initialised,    // Device initialisation completed and device is functional
};

enum DEVICE_TYPE {
    device_access_pio,      // This device is accessed primarily over pio
    device_access_mmio,     // This device is accessed primarily over mmio
    device_bridge           // This device provides connectivity to other devices
};

// This structure holds data related to a given device.
typedef struct __attribute__((packed)) {
    // Printable name of the device
    char *device_name;

    enum DEVICE_STATUS status : 5;
    enum DEVICE_TYPE type     : 3;

    // Device specific data
    void *device_data;
} device;

/* Typedef for all processor IO device initialization functions */
typedef enum DEVICE_STATUS (*device_init_function)(device *dev);

/* Initialize a given device 
 *
 * @param device_init_function init -- device initialisation function to use
 * @param device *dev -- device structure for this device
 * @param char *name -- device name
 * @param bool critical -- Do we fail to boot if we lack this device
 */
void initialize_device(device_init_function init, device *dev, char *name, bool critical);

#endif // __DRIVER_DEVICE_GENERIC__
