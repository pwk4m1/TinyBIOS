/*
 BSD 3-Clause License

 Copyright (c) 2025, k4m1 <me@k4m1.net>
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
#include <stdint.h>

#include <stdlib.h>
#include <string.h>

#include <console/console.h>

extern heap_start *heap;

/**
 * Initialise heap-space for us to use with malloc and co.
 *
 * @param start Is the start-address for our heap
 * @param size Tells the amount of bytes we can use
 */
void heap_init(uint64_t start, uint64_t size) {
    memset((void *)start, 0, size);
    heap->start = (memory_header *)(start + sizeof(heap_start));
    heap->size  = size;
    heap->end_addr = (start + size);
    heap->start->free = true;
    heap->start->size = size - sizeof(memory_header);
    heap->start->previous = NULL;
    heap->start->next = NULL;
}

/**
 * Check if the current header is within heap region
 */
static bool blk_in_bounds(void *hdr) {
    uint64_t val   = (uint64_t)hdr;
    uint64_t start = (uint64_t)heap->start;
    if ((val < heap->end_addr) && (val > start)) {
        return true;
    }
    return false;
}

/**
 * Convert a memory address/ptr to beginning of
 * the corresponding memory block
 */
static memory_header *ptr_to_block(void *ptr) {
    uint64_t addr = (uint64_t)ptr;
    addr -= sizeof(memory_header);
    return (memory_header *)addr;
}

/**
 * Walk memory from start to end, block by block, until
 * a free block with a given size is found.
 */
static memory_header *get_free_block(uint64_t size) {
    memory_header *ret = NULL;
    memory_header *cur = heap->start;

    while ((cur->free == false) || cur->size < size) {
        if (cur->next == NULL) {
            break;
        }
        if (blk_in_bounds(cur->next) == false) {
            panic("Heap corrupted, hdr->next: %x\n", cur->next);
        }
        cur = cur->next;
    }
    if (cur->free) {
        ret = cur;
    } else {
        panic("Out of memory\n");
    }

    return ret;
}

/**
 * Convert a memory block into a pointer to the beginning
 * of the now-allocated memory region
 */
static void *blk_to_ptr(memory_header *hdr) {
    uint64_t addr = (uint64_t)hdr;
    addr += sizeof(memory_header);
    return (void *)addr;
}

static memory_header *new_hdr_ptr(memory_header *current, uint64_t size) {
    uint64_t start = (uint64_t)current;
    start += size;
    return (memory_header *)start;
}

void split_block(memory_header *blk, uint64_t size) {
    if ((blk->size - size) < (3 * sizeof(memory_header))) {
        return;
    }

    memory_header *new = new_hdr_ptr(blk, size);

    new->next = blk->next;
    new->free = true;
    new->size = (blk->size - size);
    new->previous = blk;
    new->next->previous = new;

    blk->next = new;
    blk->size = size;
}

/**
 * Allocate a given amount of memory from the heap
 *
 * @param size Is the amount of bytes to allocate
 * @return pointer to the allocated memory on success or NULL on error
 */
void *malloc(uint64_t size) {
    void *ret = NULL;
    size += sizeof(memory_header);

    if (size < (heap->size - heap->total_used)) {
        memory_header *blk = get_free_block(size);

        if (blk) {
            if (blk->size > size) {
                split_block(blk, size);
            }
            blk->free = false;
            ret = blk_to_ptr(blk);
        }
    }

    return ret;
}

void *calloc(uint64_t nmemb, uint64_t size) {
    uint64_t len = (nmemb * size);
    void *ret = malloc(len);
    if (ret) {
        memset(ret, 0, len);
    }
    return ret;
}

void merge_blocks_forward(memory_header *hdr) {
    while (hdr->next) {
        if (blk_in_bounds(hdr->next) == false) {
            panic("Heap out of sync!\n");
        }
        if (hdr->next->free == false) {
            break;
        }
        memory_header *next = hdr->next;
        hdr->size += next->size;
        hdr->next = next->next;
        memset(next, 0, sizeof(memory_header));
    }
}

void merge_blocks_backward(memory_header *hdr) {
    while (hdr->previous) {
        if (blk_in_bounds(hdr->previous) == false) {
            panic("Heap out of sync!\n");
        }
        if (hdr->previous->free == false) {
            break;
        }
        memory_header *previous = hdr->previous;
        previous->next = hdr->next;
        previous->size += hdr->size;
        previous->next = hdr;
        memset(hdr, 0, sizeof(memory_header));
    }
}

void *realloc(void *ptr, uint64_t size) {
    memory_header *blk = ptr_to_block(ptr);

    panic("realloc()\n");
    return NULL;
}

void free(void *ptr) {
    memory_header *blk = ptr_to_block(ptr);
    if (blk->free) {
        panic("Double free for %x\n", ptr);
        return;
    }
    blk->free = true;
    merge_blocks_forward(blk);
    merge_blocks_backward(blk);
}

