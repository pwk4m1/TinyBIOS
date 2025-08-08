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

#include <panic.h>

extern heap_start *heap;

/**
 * Initialise heap-space for us to use with malloc and co.
 *
 * @param start Is the start-address for our heap
 * @param size Tells the amount of bytes we can use
 */
void heap_init(uint64_t start, uint64_t size) {
    heap->start = (memory_header *)start + sizeof(heap_start);
    heap->size  = size;
    heap->start->free = true;
    heap->start->size = size - sizeof(memory_header);
    heap->start->previous = NULL;
    heap->start->next = NULL;
}

/**
 * Helper to check if the given memory header address is valid.
 *
 * @param memory_header Is the memory header we're working with.
 * @return true if the header address is valid
 */
static bool hdr_addr_is_valid(memory_header *hdr) {
    uint64_t check = (uint64_t)hdr;
    uint64_t start = (uint64_t)heap->start;
    uint64_t end   = start + heap->size - sizeof(memory_header);
    return (start <= check < end);
}

/**
 * Helper to check if the next memory header is out of bounds
 *
 * @param memory_header Is the memory header we're working with.
 * @return true if the next header is valid
 */
static bool __attribute__((always_inline)) next_hdr_is_valid(memory_header *hdr) {
    return hdr_addr_is_valid(hdr->next);
}

/**
 * Helper to check if the previous memory header is out of bounds
 *
 * @param memory_header Is the memory header we're working with.
 * @return true if the previous header is valid
 */
static bool __attribute__((always_inline)) previous_hdr_is_valid(memory_header *hdr) {
    return hdr_addr_is_valid(hdr->previous);
}

/**
 * Get associated memory header for a given pointer that's
 * earlier been returned by 'malloc()'.
 *
 * @param p Is pointer to beginning of allocated memory.
 * @return Pointer to memory_header structure associated with p.
 */
static memory_header * __attribute__((always_inline)) header_for_ptr(void *p) {
    return (memory_header *)(((uint64_t)p) - sizeof(memory_header));
}

/**
 * Get rounded-up size for malloc so that the linked list entries
 * are aligned for at least somewhat reasonably fast memory access I guess
 *
 * @param size Is the requested size to allocate
 * @return Rounded up / aligned size
 */
static uint64_t __attribute__((always_inline)) aligned_size(uint64_t size) {
    uint64_t ret = size + sizeof(memory_header);
    ret += (sizeof(memory_header) - (size % sizeof(memory_header)));
    return ret;
}

/**
 * Get pointer to beginning of memory for a given memory_header
 * structure.
 *
 * @param hdr Is a pointer to the memory header we're working with.
 * @return Pointer to associated memory.
 */
static void * __attribute__((always_inline)) ptr_for_header(memory_header *hdr) {
    return (void *)(((uint64_t)hdr) + sizeof(memory_header));
}

/**
 * Helper to combine two consecutive memory blocks together.
 *
 * @param a Is a pointer to a free memory header.
 * @param b Is a pointer to, *drumroll*, a free memory header.
 */
static void fuse_blocks(memory_header *a, memory_header *b) {
    memory_header *first, *second;
    first  = (a > b) ? a : b;
    second = (a > b) ? b : a;

    first->size += second->size;
    first->next = second->next;
    if (next_hdr_is_valid(first->next)) {
        first->next->previous = first;
    }
    memset(second, 0, sizeof(memory_header));
}

/**
 * Helper to walk through our heap linked list from a given 
 * starting location and fuse together consecutive free blocks.
 *
 * @param hdr Is a pointer to the starting point of our walkthrough
 */
static void fuse_walkthrough(memory_header *hdr) {
    while (next_hdr_is_valid(hdr)) {
        if (hdr->next->free == false) {
            break;
        }
        fuse_blocks(hdr, hdr->next);
    }
    while (previous_hdr_is_valid(hdr)) {
        if (hdr->previous->free == false) {
            break;
        }
        fuse_blocks(hdr, hdr->previous);
    }
}

/**
 * Find a free slot in memory for malloc()
 *
 * @param size Is the amount of bytes we want to allocate, including sizeof memory header.
 * @return Pointer to header of a suitable block on success or NULL on error.
 */
static memory_header *get_free_block(uint64_t size) {
    memory_header *hdr = heap->start;

    while ((hdr->free == false) || (hdr->size < size)) {
        if (next_hdr_is_valid(hdr) == false) {
            return NULL;
        }
        hdr = hdr->next;
    }

    return hdr;
}

/**
 * Helper to check if it's sensible to split the block we're allocating
 * into multiple smaller blocks, or just accept that we'll lose a few
 * bytes.
 *
 * @param hdr Is a pointer to the memory header we're working with.
 * @param size Is the amount of bytes we want to allocate, including sizeof memory header.
 * @return true if it makes sense to split the block.
 */
static bool space_for_new_blk(memory_header *hdr, uint64_t size) {
    return (hdr->size - size - sizeof(memory_header)) > (2 * sizeof(memory_header));
}

/**
 * Helper to add a new memory block between the one we're allocating and the following one.
 *
 * @param hdr Is a pointer to the memory header we're working with.
 * @param size Is the amount of bytes we want to allocate, including sizeof memory header.
 */
static void insert_new_block(memory_header *hdr, uint64_t size) {
    memory_header *next = (memory_header *)(((uint64_t)hdr) + size);

    next->free = true;
    next->size = (hdr->size - size);
    next->previous = hdr;
    next->next = hdr->next;

    if (next->next->free) {
        next->size += next->next->size;
        next->next  = next->next->next; // :D
        memset(next->next, 0, sizeof(memory_header));
    }

    next->next->previous = next;

    hdr->size = size;
    hdr->next = next;
}

/**
 * Helper to allocate a block and to adjust the heap accordingly
 *
 * @param hdr Is a pointer to the memory header we're working with.
 * @param size Is the amount of bytes we want to allocate, including sizeof memory header.
 */
static void allocate_block(memory_header *hdr, uint64_t size) {
    hdr->free = false;
    if (next_hdr_is_valid(hdr)) {
        if (space_for_new_blk(hdr, size)) {
            insert_new_block(hdr, size);
        }
    } else {
        if (hdr->next == NULL) {
            insert_new_block(hdr, size);
        }
    }
}

/**
 * Helper to free/delete a previously used memory block.
 *
 * @param hdr Is a pointer to memory header structure we want to release.
 */
static void __attribute__((always_inline)) delete_block(memory_header *hdr) {
    hdr->free = true;
    fuse_walkthrough(hdr);
}

/**
 * Helper to resize existing and allocated memory block.
 * The content of associated allocated memory is copied if the
 * block needs to be relocated.
 *
 * @param hdr Is a pointer to memory header structure for the block we're working with.
 * @param size Is the target size we want to match.
 * @return Pointer to memory header for resized block on success or NULL on error.
 */
static memory_header *resize_block(memory_header *hdr, uint64_t size) {
    memory_header *ret = hdr;
    if (size <= hdr->size) {
        if (space_for_new_blk(hdr, size)) {
            insert_new_block(hdr, size);
        }
    } else {
        ret = get_free_block(size);
        if (ret) {
            void *s = ptr_for_header(hdr);
            void *d = ptr_for_header(ret);
            memcpy(s, d, (size - sizeof(memory_header)));
            delete_block(hdr);
        }
    }
    return ret;
}

/**
 * Allocate memory from heap for the calling function.
 *
 * @param size Is the amount of bytes to allocate.
 * @return Pointer to allocated memory on success or NULL on error.
 */
void *malloc(uint64_t size) {
    size = aligned_size(size);
    memory_header *hdr = get_free_block(size);
    if (!hdr) {
        return NULL;
    }
    allocate_block(hdr, size);
    void *ret = ptr_for_header(hdr);
    return ret;
}

/**
 * Allocate continuous memory for nmemb times of object.
 * Initialize allocated memory to 0.
 *
 * @param nmemb Is the amount of objects to allocate.
 * @param size Is the size of the objects we're working with
 * @return Pointer to allocated memory on success or NULL on error.
 */
void *calloc(uint64_t nmemb, uint64_t size) {
    void *p = malloc(nmemb * size);
    if (p) {
        memset(p, 0, (nmemb * size));
    }
    return p;
}

/**
 * Resize previously allocated block of memory. Content of the 
 * previously allocated memory is relocated if needed.
 *
 * @param ptr Is pointer to the previously allocated space.
 * @param size Is the new size to adjust the memory to.
 * @return Pointer to reallocated memory on success or NULL on error.
 *
 */
void *realloc(void *ptr, uint64_t size) {
    memory_header *hdr = header_for_ptr(ptr);
    memory_header *got = resize_block(hdr, (size + sizeof(memory_header)));
    if (!got) {
        return NULL;
    }
    if (hdr == got) {
        return ptr;
    }
    void *dst = ptr_for_header(got);
    memcpy(ptr, dst, size);
    delete_block(hdr);
    return dst;
}

/**
 * Mark a previously allocated block of memory free to use again.
 *
 * @param ptr Is a pointer to previously allocated memory to free.
 */
void free(void *ptr) {
    memory_header *hdr = header_for_ptr(ptr);
    if (hdr->free) {
        panic("Double free for %p\n", ptr);
    }
    delete_block(hdr);
}

