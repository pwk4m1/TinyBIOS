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
#ifndef __SYS_IO_H__
#define __SYS_IO_H__

// i/o delay so that we don't have to implement it separately for
// all pio devices.
//
// @param unsigned short time -- how many NOPs should we execute
//
// NOTE: This function should only be used for delays until the point
// we have working sleep() / interrupts and programmamble interrupt timer
// initialised.
//
static inline void iodelay(unsigned short time) {
    do { asm volatile("nop"); } while (time--);
}

// Basic cpu port i/o
static inline unsigned char inb(unsigned short port) {
    unsigned char ret;
    asm volatile("in %0, %1":"=a"(ret):"dN"(port));
    return ret;
}

static inline unsigned short inw(unsigned short port) {
    unsigned short ret;
    asm volatile("in %0, %1":"=a"(ret):"dN"(port));
    return ret;
}

static inline unsigned short inl(unsigned short port) {
    unsigned int ret;
    asm volatile("in %0, %1":"=a"(ret):"dN"(port));
    return ret;
}

static inline void outb(unsigned char v, unsigned short port) {
    asm volatile("out %1, %0"::"a"(v),"dN"(port));
}

static inline void outw(unsigned short v, unsigned short port) {
    asm volatile("out %1, %0"::"a"(v),"dN"(port));
}

static inline void outl(unsigned int v, unsigned short port) {
    asm volatile("out %1, %0"::"a"(v),"dN"(port));
}

#endif
