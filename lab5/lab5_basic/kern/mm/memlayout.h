#ifndef __KERN_MM_MEMLAYOUT_H__
#define __KERN_MM_MEMLAYOUT_H__
// 定义了操作系统的内存布局和内存管理相关数据结构

/* This file contains the definitions for memory management in our OS. */

/* *
 * Virtual memory map: 虚拟地址空间布局图                                    Permissions
 *                                                              kernel/user
 *
 *     4G ------------------> +---------------------------------+
 *                            |                                 |
 *                            |         Empty Memory (*)        |
 *                            |                                 |
 *                            +---------------------------------+ 0xFB000000
 *                            |   Cur. Page Table (Kern, RW)    | RW/-- PTSIZE   （虚拟页表区域）
 *     VPT -----------------> +---------------------------------+ 0xFAC00000
 *                            |        Invalid Memory (*)       | --/--          （重映射的物理内存区域）
 *     KERNTOP -------------> +---------------------------------+ 0xF8000000
 *                            |                                 |
 *                            |    Remapped Physical Memory     | RW/-- KMEMSIZE （映射了所有物理内存）
 *                            |                                 |
 *     KERNBASE ------------> +---------------------------------+ 0xC0000000
 *                            |        Invalid Memory (*)       | --/--
 *     USERTOP -------------> +---------------------------------+ 0xB0000000
 *                            |           User stack            |
 *                            +---------------------------------+
 *                            |                                 |
 *                            :                                 :
 *                            |         ~~~~~~~~~~~~~~~~        |                 （用户空间 —— 0x00000000 ~ USERTOP）
 *                            :                                 :
 *                            |                                 |                   PS：用户栈向下增长、程序堆和代码段向上增长
 *                            ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 *                            |       User Program & Heap       |
 *     UTEXT ---------------> +---------------------------------+ 0x00800000      （用户程序代码段开始）
 *                            |        Invalid Memory (*)       | --/--
 *                            |  - - - - - - - - - - - - - - -  |
 *                            |    User STAB Data (optional)    |
 *     USERBASE, USTAB------> +---------------------------------+ 0x00200000      （用户STAB调试信息）
 *                            |        Invalid Memory (*)       | --/--           （无效内存，不可访问）
 *     0 -------------------> +---------------------------------+ 0x00000000
 * (*) Note: The kernel ensures that "Invalid Memory" is *never* mapped.
 *     "Empty Memory" is normally unmapped, but user programs may map pages
 *     there if desired.
 *
 * */

/* All physical memory mapped at this address */
#define KERNBASE 0xFFFFFFFFC0200000    // 内核基地址
#define KMEMSIZE 0x7E00000             // 126MB物理内存
#define KERNTOP (KERNBASE + KMEMSIZE)  // 内核顶部

#define PHYSICAL_MEMORY_OFFSET 0xFFFFFFFF40000000
/* *
 * Virtual page table. Entry PDX[VPT] in the PD (Page Directory) contains
 * a pointer to the page directory itself, thereby turning the PD into a page
 * table, which maps all the PTEs (Page Table Entry) containing the page mappings
 * for the entire virtual address space into that 4 Meg region starting at VPT.
 * */

#define KSTACKPAGE 2                     // # of pages in kernel stack
#define KSTACKSIZE (KSTACKPAGE * PGSIZE) // sizeof kernel stack

#define USERTOP 0x80000000             // 用户空间顶部
#define USTACKTOP USERTOP              // 用户栈顶
#define USTACKPAGE 256                 // 用户栈256页 = 1MB
#define USTACKSIZE (USTACKPAGE * PGSIZE) // sizeof user stack

#define USERBASE 0x00200000            // 用户空间基地址
#define UTEXT 0x00800000               // 用户程序入口点
#define USTAB USERBASE   // the location of the user STABS data structure

// 检查地址是否在用户空间
#define USER_ACCESS(start, end) \
    (USERBASE <= (start) && (start) < (end) && (end) <= USERTOP)

// 检查地址是否在内核空间
#define KERN_ACCESS(start, end) \
    (KERNBASE <= (start) && (start) < (end) && (end) <= KERNTOP)

#ifndef __ASSEMBLER__

#include <defs.h>
#include <atomic.h>
#include <list.h>

typedef uintptr_t pte_t;
typedef uintptr_t pde_t;
typedef pte_t swap_entry_t; // the pte can also be a swap entry

/* *
 * struct Page - Page descriptor structures. Each Page describes one
 * physical page. In kern/mm/pmm.h, you can find lots of useful functions
 * that convert Page to other data types, such as physical address.
 * */
struct Page
{
    int ref;                    // 引用计数（共享页数）
    uint64_t flags;            // 状态标志位
    unsigned int property;     // 连续空闲页数（用于首次适配算法）
    list_entry_t page_link;    // 空闲链表链接
    list_entry_t pra_page_link; // 页替换算法链表
    uintptr_t pra_vaddr;       // 对应的虚拟地址
};

/* Flags describing the status of a page frame */
#define PG_reserved 0 // if this bit=1: the Page is reserved for kernel, cannot be used in alloc/free_pages; otherwise, this bit=0
#define PG_property 1 // if this bit=1: the Page is the head page of a free memory block(contains some continuous_addrress pages), and can be used in alloc_pages; if this bit=0: if the Page is the the head page of a free memory block, then this Page and the memory block is alloced. Or this Page isn't the head page.

#define SetPageReserved(page) set_bit(PG_reserved, &((page)->flags))
#define ClearPageReserved(page) clear_bit(PG_reserved, &((page)->flags))
#define PageReserved(page) test_bit(PG_reserved, &((page)->flags))
#define SetPageProperty(page) set_bit(PG_property, &((page)->flags))
#define ClearPageProperty(page) clear_bit(PG_property, &((page)->flags))
#define PageProperty(page) test_bit(PG_property, &((page)->flags))

// convert list entry to page
#define le2page(le, member) \
    to_struct((le), struct Page, member)

/* free_area_t - maintains a doubly linked list to record free (unused) pages */
typedef struct
{
    list_entry_t free_list; // the list header
    unsigned int nr_free;   // # of free pages in this free list
} free_area_t;

#endif /* !__ASSEMBLER__ */

#endif /* !__KERN_MM_MEMLAYOUT_H__ */
