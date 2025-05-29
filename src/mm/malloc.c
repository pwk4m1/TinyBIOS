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
#ifndef __TINYMALLOC_H__
#define __TINYMALLOC_H__

#include <stdint.h>
#include <stdlib.h>
#include <string.h>

extern heap_start *heap;

static inline memory_header *block_address(memory_header *block, uint64_t bytes_to_next) {
    return (memory_header *)((uint64_t)block + bytes_to_next);
}

static inline memory_header *block_from_ptr(void *ptr) {
    return (memory_header *)((uint64_t)ptr - sizeof(memory_header));
}

static inline bool enough_space_for_extra_block(memory_header *block, uint64_t size) {
    if ((block->size - size) > (3 * sizeof(memory_header))) {
        return true;
    }
    return false;
}

void heap_init(uint64_t start, uint64_t size) {
    heap = (heap_start *)start;
    heap->size = size - sizeof(heap_start);
    heap->start = block_address((memory_header *)heap, sizeof(heap_start));
    memset(heap->start, 0, heap->size);
    heap->start->free = true;
    heap->start->size = heap->size - sizeof(memory_header);
}

static memory_header *get_block(uint64_t size) {
    memory_header *current = heap->start;
    while (
            (current->free == false) ||
            (current->size < size)   ||
            (current->next != 0))
    {
        current = current->next;
    }
    if (current->size >= size) {
        return current;
    }
    return 0;
}


static void create_new_block(memory_header *current, uint64_t size) {
    memory_header *next = block_address(current, size);
    next->size = current->size - size;
    next->free = true;
    next->previous = current;
    next->next = current->next;
    current->next = next;
}

static void allocate_block(memory_header *block, uint64_t size) {
    block->free = false;
    if (block->size == size) {
        return;
    }
    if (enough_space_for_extra_block(block, size)) {
        create_new_block(block, size);        
        block->size = size;
    }
}

void *malloc(uint64_t size) {
    size += sizeof(memory_header);
    memory_header *block = get_block(size);
    if (block) {
        allocate_block(block, size);
        return (void *)((uint64_t)block + sizeof(memory_header));
    }
    return 0;
}

void *calloc(uint64_t nmemb, uint64_t size) {
    void *ptr = malloc(nmemb * size);
    if (ptr) {
        memset(ptr, 0, nmemb * size);
    }
    return ptr;
}

static void merge_blocks(memory_header *a, memory_header *b, bool forward) {
    memory_header *back = (forward) ? a : b;
    memory_header *front = (back == a) ? b : a;

    back->size += front->size;
    back->next  = front->next;

}

static void defragment_free(memory_header *block) {
    while ((block->next != 0) && (block->next->free)) {
        merge_blocks(block, block->next, true);
    }
    while ((block->previous) && (block != heap->start) && (block->previous->free)) {
        merge_blocks(block, block->previous, false);
        block = block->previous;
    }
}

void free(void *ptr) {
    memory_header *block = block_from_ptr(ptr); 
    block->free = true;
    defragment_free(block);
}

void *realloc(void *ptr, uint64_t size) {
    void *ret = ptr;
    memory_header *block = block_from_ptr(ptr);
    
    if (block->size > size) {
        if (enough_space_for_extra_block(block, size)) {
            create_new_block(block, size);
        }
        block->size = size;
        return ret;
    }
    uint64_t size_diff = size - block->size;

    if (block->next->free && (block->next->size >= size_diff)) {
        if (enough_space_for_extra_block(block->next, size_diff)) {
            create_new_block(block->next, size_diff);
        }
        block->next = block->next->next;
        block->size += size_diff;
        return ret;
    }
    ret = calloc(1, size);
    if (ret) {
        memcpy(ptr, ret, (block->size - sizeof(memory_header)));
        free(ptr);
    }
    return ret;
}

#endif // __TINYMALLOC_H__
