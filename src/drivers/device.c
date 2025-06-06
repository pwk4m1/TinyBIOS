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
#include <stdbool.h>
#include <stdlib.h>

#include <panic.h>
#include <drivers/device.h>
#include <console/console.h>


/* Helper for allocating new device structures
 *
 * @param size_t size of device_data structure to allocate
 * @return pointer to our calloc'ed dev struct
 */
device *new_device(size_t dev_size) {
    device *ret = calloc(1, sizeof(device));
    if (!ret) {
        panic_oom("creating new device");
    }
    ret->device_data = calloc(1, dev_size);
    if (!ret->device_data) {
        panic_oom("Allocating space for device data");
    }
    return ret;
}

/* Print why initilaisation failed, if possible.
 *
 */
static inline char *status_to_str(enum DEVICE_STATUS status) {
    switch (status) {
    case (status_present):
        return "device is present";
    case (status_not_present):
        return "device is not present";
    case (status_unknown):
        return "unable to determine device state";
    case (status_faulty):
        return "device is misbehaving";
    case (status_initialised):
        return "device initialisation completed";
    default:
        return "unknown device status";
    }
}

/* Wrapper for calling various device initialisation routines
 *
 * @param pio_device_init init -- pio device initialisation function to use
 * @param pio_device *dev -- pio device structure for this device
 * @param bool critical -- Do we fail to boot if we lack this device
 * @param char *name -- device name
 */
void initialize_device(device_init_function init, device *dev, char *name, bool critical) {
    blogf("Initializing %s... ", name);

    dev->status = init(dev);
    dev->device_name = name;
    if (dev->status != status_initialised) {
        blogf("Failed, reason: %s\n", status_to_str(dev->status));
        if (critical) {
            panic("Unable to initialize a critical component");
        }
    } else {
        blog("ok\n");
    }
}

