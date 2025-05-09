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

#include <itoa.h>

/* Convert unsigned 32-bit longeger to ascii characters
 *
 * @param unsigned long d -- number to parse
 * @param char *dst -- where to write our ascii to
 */
void itoa(unsigned long d, char *dst) {
    unsigned long carry = 0;

    for (unsigned long i = 0; i < (2 * sizeof(unsigned long)); i++) {
        char nibble = (d & 0x0000000F);
        d >>= 4;
        if (carry) {
            nibble += carry;
            carry = 0;
        }
        if (nibble > 0x09) {
            carry = 1;
            nibble -= 0x0A;
        }
        nibble |= 0x30;
        dst[(2 * sizeof(unsigned long)) - i - 1] = nibble;
    }
}

/* Convert unsigned 32-bit longeger to ascii hex characters
 *
 * @param unsigned long d -- number to parse
 * @param char *dst -- where to write our ascii to, We assume this to be
 *                     at least 9-byte memory buffer that's initialised to 0
 */
void itoah(unsigned long d, char *dst) {
    char nibble;

    for (unsigned long i = 0; i < (2 * sizeof(unsigned long)); i++) {
        nibble = (d & 0x0000000F);
        d >>= 4;
        if (nibble < 10) {
            nibble |= 0x30;
        } else {
            nibble -= 0x0A;
            nibble += 0x41;
        }
        dst[(2*sizeof(long)) - i - 1] = nibble;
    }
}


