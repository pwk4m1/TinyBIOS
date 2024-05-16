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
#ifndef __UTIL_IO_H__
#define __UTIL_IO_H__

#include <sys/types.h>

/* Read single byte from processor I/O port
 * 
 * @param unsigned short port -- I/O port to read from
 * return bytes read from port
 */
unsigned inline char inb(unsigned short port) {
    unsigned char ret;
    asm volatile("inb %1, %0":"=a"(ret):"Nd"(port));
    return ret;
}

/* Read 2 bytes from processor I/O port
 *
 * @param unsigned short port -- I/O port to read from
 * return bytes read from port
 */
unsigned inline short inw(unsigned short port) {
    unsigned short ret;
    asm volatile("inw %1, %0":"=a"(ret):"Nd"(port));
    return ret;
}

/* Read 4 bytes from processor I/O port
 *
 * @param unsigned short port -- I/O port to read from
 * return bytes read from port
 */
unsigned inline long inl(unsigned short port) {
    unsigned short ret;
    asm volatile("inl %1, %0":"=a"(ret):"Nd"(port));
    return ret;
}

/* Write single byte to processor I/O port
 *
 * @param unsigned char val -- what to write 
 * @param unsigned short port -- port to write to
 */
inline void outb(unsigned char val, unsigned short port) {
    asm volatile("outb %1, %0"::"Nd"(val),"Nd"(port));
}

/* Write two bytes to processor I/O port
 *
 * @param unsigned short val -- what to write 
 * @param unsigned short port -- port to write to
 */
inline void outw(unsigned short val, unsigned short port) {
    asm volatile("outw %1, %0"::"Nd"(val),"Nd"(port));
}

/* Write four bytes to processor I/O port
 *
 * @param unsigned long val -- what to write 
 * @param unsigned short port -- port to write to
 */
inline void outl(unsigned long val, unsigned short port) {
    asm volatile("outl %1, %0"::"Nd"(val),"Nd"(port));
}

#endif // __UTIL_IO_H__
