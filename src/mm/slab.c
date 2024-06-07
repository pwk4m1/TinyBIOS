
#include <mm/slab.h>
#include <mm/bitmap.h>

#include <stddef.h>
#include <stdint.h>
#include <string.h>

void init_slab(uint32_t mem_start, uint32_t mem_end, size_t allocation_size) {
    size_t mem_total   = mem_end   - mem_start;
    size_t num_entries = mem_total / allocation_size;
    size_t overhead    = bitmap_size(num_entries) + sizeof(SlabHeader);

    num_entries -= (overhead + allocation_size) / allocation_size;

    SlabHeader* header = (SlabHeader*)mem_start;
    header->allocation_size = allocation_size;
    header->num_entries     = num_entries;
    header->bitmap_size     = bitmap_size(num_entries);

    bitmap_t bitmap = (bitmap_t)((uint32_t)header + sizeof(SlabHeader));
    memset(bitmap, 0, header->bitmap_size);
}


