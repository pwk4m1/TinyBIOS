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

/* Compare two strings
 *
 * @param unsigned char *s1 -- String 1
 * @param unsigned char *s2 -- String 2
 * @param unsigned int n    -- Only compare up to n bytes
 * @return amount of bytes that differ
 */
size_t strncmp(unsigned char *s1, unsigned char *s2, unsigned int n) {
    size_t ret = 0;
    for (unsigned int i = 0; i < n; i++) {
        if ((s1[i] == 0) || (s2[i] == 0)) {
            break;
        }
        if (s1[i] != s2[i]) {
            ret++;
        }
    }
    return ret;
}

void *memset(void *s, int c, size_t n) {
    unsigned char *dst = (unsigned char *)s;
    for (size_t i = 0; i < n; i++) {
        dst[i] = (unsigned char)c;
    }
    return dst;
}

/* Copy len bytes of memory from region A to B
 *
 * @param const void *src -- where to copy from
 * @param const void *dst -- where to copy to
 * @param size_t len -- how many bytes to copy
 */
void *memcpy(const void *src, void *dst, size_t len) {
    unsigned char *d = (unsigned char *)dst;
    unsigned char *s = (unsigned char *)src;
    for (size_t i = 0; i < len; i++) {
        d[i] = s[i];
    }
    return d;
}

