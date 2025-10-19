
#include <defs.h>
#include <stdio.h>
#include <assert.h>
#include <string.h>
#include <pmm.h>
#include "slub.h"

/* Hook this into kern_init() after pmm is inited */

void slub_run_tests(void){
    slub_init();
    int r = slub_selftest();
    if(r==0) {
        cprintf("SLUB tests: ALL PASSED\n");
    } else {
        cprintf("SLUB tests: FAILED (%d)\n", r);
    }

    // Showcase arbitrary sizes
    void *a = kmalloc(37);
    void *b = kmalloc(4095);
    void *c = kmalloc(1);
    assert(a && b && c);
    memset(a, 0x11, 37);
    memset(b, 0x22, 4095);
    memset(c, 0x33, 1);
    kfree(a); kfree(b); kfree(c);
}
