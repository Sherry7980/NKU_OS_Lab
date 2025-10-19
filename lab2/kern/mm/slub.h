
#ifndef __KERN_MM_SLUB_H__
#define __KERN_MM_SLUB_H__

#include <defs.h>
#include <list.h>
#include <pmm.h>

/*
 * Minimal SLUB-like allocator for uCore
 * Two layers:
 *  - Page allocator: uses pmm->alloc_pages / free_pages
 *  - Object allocator: kmem_cache for fixed-size objects + kmalloc/kfree for arbitrary sizes
 *
 * This is a simplified teaching implementation: no NUMA, no CPU-local mags, no debug poisoning.
 */

struct kmem_cache;

typedef struct slab_page {
    list_entry_t link;            // link in cache lists
    struct kmem_cache *cache;     // owning cache
    uint16_t obj_size;            // size of objects
    uint16_t objs_per_slab;       // how many objects in this slab
    uint16_t free_cnt;            // number of free objects
    uint16_t bitmap_words;        // size of bitmap in u32 words
    uint32_t *bitmap;             // allocation bitmap (1 = used, 0 = free)
    void *data;                   // start of object area
    size_t npages;                // how many pages in this slab
} slab_page_t;

typedef struct kmem_cache {
    list_entry_t full;            // slabs with no free objects
    list_entry_t partial;         // slabs with some free objects
    list_entry_t empty;           // slabs with all objects free
    size_t size;                  // object size (aligned)
    size_t align;                 // alignment
    size_t slab_npages;           // pages per slab
    const char *name;
} kmem_cache_t;

void slub_init(void);

/* General-purpose allocation */
void *kmalloc(size_t size);
void  kfree(void *ptr);

/* Cache API (subset of Linux's) */
kmem_cache_t *kmem_cache_create(const char *name, size_t size, size_t align, size_t slab_pages);
void          kmem_cache_destroy(kmem_cache_t *cache);
void         *kmem_cache_alloc(kmem_cache_t *cache);
void          kmem_cache_free(kmem_cache_t *cache, void *obj);

/* Self test */
int slub_selftest(void);

#endif /* !__KERN_MM_SLUB_H__ */
