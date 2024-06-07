#ifndef _BITMAP_H_INCLUDED
#define _BITMAP_H_INCLUDED

#include <stddef.h>
#include <stdint.h>
#include <stdbool.h>

//! Type for a single entry in the array.
typedef uint8_t* bitmap_t;

//! Return the size of the bitmap in bytes for a given amount of entries
static inline size_t bitmap_size(size_t num_entries) {
    return (num_entries + 7) / 8;
}

//! Return the index in the bitmap array for the given bitmap index
static inline uint32_t bitmap_idx(uint32_t entry) {
    return entry / 8;
}

//! Return the bitmask for the given bitmap index
static inline uint8_t bitmap_bit(uint32_t entry) {
    return 1 << (entry % 8);
}

//! Retrieve state of the given entry from bitmap
static inline bool bitmap_get(bitmap_t bitmap, uint32_t entry) {
    return (bitmap[bitmap_idx(entry)] & bitmap_bit(entry)) != 0;
}

//! Set given entry in bitmap
static inline void bitmap_set(bitmap_t bitmap, uint32_t entry) {
    bitmap[bitmap_idx(entry)] |= bitmap_bit(entry);
}

//! Unset given entry in bitmap
static inline void bitmap_clear(bitmap_t bitmap, uint32_t entry) {
    bitmap[bitmap_idx(entry)] &= ~bitmap_bit(entry);
}

#endif
