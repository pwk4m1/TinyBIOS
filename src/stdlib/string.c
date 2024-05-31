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

#include <stddef.h>

/* Get length of a null-terminated string
 *
 * @param const char *str -- string of which to count length for
 * @return size_t string length
 */
size_t strlen(const char *str) {
    size_t i = 0;
    while (str[i] != 0) {
        i++;
    }
    return i;
}

/* Set memory range to specified byte
 *
 * @param void *dst -- start address
 * @param unsigned char b -- what to set the memory to
 * @param size_t len -- how many bytes to write
 */
void memset(const void *dst, unsigned char c, size_t len) {
    unsigned char *cdst = (unsigned char *)dst;
    for (size_t i = 0; i < len; i++) {
        cdst[i] = c;
    }
}

/* Copy len bytes of memory from region A to B
 *
 * @param void *src -- where to copy from
 * @param void *dst -- where to copy to
 * @param size_t len -- how many bytes to copy
 */
void memcpy(const void *src, const void *dst, size_t len) {
    unsigned char *csrc = (unsigned char *)src;
    unsigned char *cdst = (unsigned char *)dst;
    for (size_t i = 0; i < len; i++) {
        cdst[i] = csrc[i];
    }
}


