#ifndef _SLAB_H_INCLUDED
#define _SLAB_H_INCLUDED

#include <stddef.h>
#include <stdint.h>

#include <mm/bitmap.h>

// Type for indexing objects in a Slab region
typedef uint16_t SlabIndexType;

// Header of a Slab region
typedef struct {
    // Size of objects in this region
    uint16_t      allocation_size;

    // Number of objects in this region
    SlabIndexType num_entries;

    // Size of the bitmap in bytes
    uint32_t      bitmap_size;
} SlabHeader;

/*
 * Initialize a new slab allocator at the given memory location. After initialization,
 * you can use mem_start as pointer to SlabHeader for more operations.
 *
 * @param mem_start       Memory address where the slab allocator region begins
 * @param mem_end         Memory address where the slab allocator region ends
 * @param allocation_size Size of single objects in this allocator
 */
void init_slab(uint32_t mem_start, uint32_t mem_end, size_t allocation_size);

/*
 * Calculate the overhead of a given slab allocator.
 *
 * @param   slab Pointer to SlabHeader to calculate overhead.
 * @returns Allocator overhead in bytes.
 */
static inline size_t slab_overhead(const SlabHeader* slab) {
    size_t overhead = sizeof(SlabHeader) + slab->bitmap_size;
    return overhead + (slab->allocation_size - (overhead % slab->allocation_size));
}

/*
 * Calculate memory address for a given allocator and index
 *
 * @param slab Pointer to SlabHeader for calculation
 * @param idx  Index of the object in the allocator
 * @returns Memory address of the object
 */
static inline uint32_t slab_mem(const SlabHeader* slab, const SlabIndexType idx) {
    return (idx * slab->allocation_size) + slab_overhead(slab) + (uint32_t)slab;
}

/*
 * Calculate index for a given memory address in a given allocator
 *
 * @param slab Pointer to SlabHeader for calculation
 * @param mem  Memory address to calculate index
 * @returns    Index of the given memory address in the allocator
 */
static inline SlabIndexType slab_index(const SlabHeader* slab, const uint32_t mem) {
    return (mem - slab_overhead(slab) - (uint32_t)slab) / slab->allocation_size;
}

/*
 * Allocate object from slab allocator region.
 *
 * @param   slab mem_start given to init_slab before
 * @returns Address in memory with the allocated object, NULL if full
 */
static inline uint32_t slab_alloc(SlabHeader* slab) {
    bitmap_t bitmap = (bitmap_t)((uint32_t)slab + sizeof(SlabHeader));

    SlabIndexType idx;
    for(idx = 0; idx < slab->num_entries && bitmap_get(bitmap, idx); ++idx);

    if(idx < slab->num_entries) {
        bitmap_set(bitmap, idx);
        return slab_mem(slab, idx);
    }
    return 0;
}

/*
 * Free object in slab allocator region.
 *
 * @param slab   mem_start given to init_slab before
 * @param memory Address to mark as free
 */
static inline void slab_free(SlabHeader* slab, uint32_t mem) {
    bitmap_t bitmap = (bitmap_t)((uint32_t)slab + sizeof(SlabHeader));
    bitmap_clear(bitmap, slab_index(slab, mem));
}

#endif
