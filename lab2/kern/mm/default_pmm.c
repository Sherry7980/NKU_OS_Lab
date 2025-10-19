#include <pmm.h>
#include <list.h>
#include <string.h>
#include <default_pmm.h>

/* In the first fit algorithm, the allocator keeps a list of free blocks (known as the free list) and,
   on receiving a request for memory, scans along the list for the first block that is large enough to
   satisfy the request. If the chosen block is significantly larger than that requested, then it is 
   usually split, and the remainder added to the list as another free block.
   Please see Page 196~198, Section 8.2 of Yan Wei Min's chinese book "Data Structure -- C programming language"
*/
// LAB2 EXERCISE 1: YOUR CODE
// you should rewrite functions: default_init,default_init_memmap,default_alloc_pages, default_free_pages.
/*
 * Details of FFMA
 * (1) Prepare: In order to implement the First-Fit Mem Alloc (FFMA), we should manage the free mem block use some list.
 *              The struct free_area_t is used for the management of free mem blocks. At first you should
 *              be familiar to the struct list in list.h. struct list is a simple doubly linked list implementation.
 *              You should know howto USE: list_init, list_add(list_add_after), list_add_before, list_del, list_next, list_prev
 *              Another tricky method is to transform a general list struct to a special struct (such as struct page):
 *              you can find some MACRO: le2page (in memlayout.h), (in future labs: le2vma (in vmm.h), le2proc (in proc.h),etc.)
 * (2) default_init: you can reuse the  demo default_init fun to init the free_list and set nr_free to 0.
 *              free_list is used to record the free mem blocks. nr_free is the total number for free mem blocks.
 * (3) default_init_memmap:  CALL GRAPH: kern_init --> pmm_init-->page_init-->init_memmap--> pmm_manager->init_memmap
 *              This fun is used to init a free block (with parameter: addr_base, page_number).
 *              First you should init each page (in memlayout.h) in this free block, include:
 *                  p->flags should be set bit PG_property (means this page is valid. In pmm_init fun (in pmm.c),
 *                  the bit PG_reserved is setted in p->flags)
 *                  if this page  is free and is not the first page of free block, p->property should be set to 0.
 *                  if this page  is free and is the first page of free block, p->property should be set to total num of block.
 *                  p->ref should be 0, because now p is free and no reference.
 *                  We can use p->page_link to link this page to free_list, (such as: list_add_before(&free_list, &(p->page_link)); )
 *              Finally, we should sum the number of free mem block: nr_free+=n
 * (4) default_alloc_pages: search find a first free block (block size >=n) in free list and reszie the free block, return the addr
 *              of malloced block.
 *              (4.1) So you should search freelist like this:
 *                       list_entry_t le = &free_list;
 *                       while((le=list_next(le)) != &free_list) {
 *                       ....
 *                 (4.1.1) In while loop, get the struct page and check the p->property (record the num of free block) >=n?
 *                       struct Page *p = le2page(le, page_link);
 *                       if(p->property >= n){ ...
 *                 (4.1.2) If we find this p, then it' means we find a free block(block size >=n), and the first n pages can be malloced.
 *                     Some flag bits of this page should be setted: PG_reserved =1, PG_property =0
 *                     unlink the pages from free_list
 *                     (4.1.2.1) If (p->property >n), we should re-caluclate number of the the rest of this free block,
 *                           (such as: le2page(le,page_link))->property = p->property - n;)
 *                 (4.1.3)  re-caluclate nr_free (number of the the rest of all free block)
 *                 (4.1.4)  return p
 *               (4.2) If we can not find a free block (block size >=n), then return NULL
 * (5) default_free_pages: relink the pages into  free list, maybe merge small free blocks into big free blocks.
 *               (5.1) according the base addr of withdrawed blocks, search free list, find the correct position
 *                     (from low to high addr), and insert the pages. (may use list_next, le2page, list_add_before)
 *               (5.2) reset the fields of pages, such as p->ref, p->flags (PageProperty)
 *               (5.3) try to merge low addr or high addr blocks. Notice: should change some pages's p->property correctly.
 */
static free_area_t free_area;

#define free_list (free_area.free_list) //内存空闲块链表
#define nr_free (free_area.nr_free)     //空闲页面总数

static void 
default_init(void) {                    //该函数用于初始化双向链表的头节点和空闲页面计数器。
    list_init(&free_list);
    nr_free = 0;
}

static void
default_init_memmap(struct Page *base, size_t n) {
    assert(n > 0);                     //确保要初始化的页面数量大于0
    struct Page *p = base;             //创建遍历指针p，指向起始页面
    for (; p != base + n; p ++) {      //base + n 是指针运算，表示从 base 开始向后移动 n 个 struct Page 的位置，循环会遍历从 base 到 base + n - 1 的所有页面
        assert(PageReserved(p));       //检查页面是否被标记为"保留"状态
        p->flags = p->property = 0;    //将页面的所有标志位和属性清零
        set_page_ref(p, 0);            //将页面的引用次数设为0
    }
    base->property = n;                //在首个页面的property属性设为n，即空闲块的总大小
    SetPageProperty(base);             //设置页面的属性值
    nr_free += n;                      //更新空闲页面数量（加了n，因为刚才初始化了n个空闲页面）
    if (list_empty(&free_list)) {      //判断该列表是否为空
        list_add(&free_list, &(base->page_link));  //若空，将起始页面的链表节点添加到链表中
    } else {                           //若不空，则要按地址排序插入
        list_entry_t* le = &free_list; //先初始化一个指针指向空闲链表头
        while ((le = list_next(le)) != &free_list) {  //一直向后找，按物理地址从小到大排列
            struct Page* page = le2page(le, page_link);
            if (base < page) {         //若新页面的起始地址base小于当前遍历到的页面page的地址，说明找到了合适插入位置
                list_add_before(le, &(base->page_link));  //在当前位置的前面插入新节点
                break;
            } else if (list_next(le) == &free_list) {  //如不是，则插入到末尾
                list_add(le, &(base->page_link));
            }
        }
    }
}

static struct Page *
default_alloc_pages(size_t n) {           //参数为请求分配的连续页面数量
    assert(n > 0);                        //确保请求的页面数大于0
    if (n > nr_free) {                    //快速检查系统是否有足够的空闲页面
        return NULL;                      //如果请求的数量大于系统中空闲堆数量，则返回NULL
    }
    struct Page *page = NULL;             //用于记录找到的合适页面
    list_entry_t *le = &free_list;        //遍历指针，从链表头开始
    while ((le = list_next(le)) != &free_list) {  //获取下一个节点，且下一个不能是链表头，否则就回去了
        struct Page *p = le2page(le, page_link);  //将链表节点转换为对应的Page结构体指针
        if (p->property >= n) {           //检查当前空闲块的大小是否满足需求
            page = p;                     //记录找到的合适页面
            break;                        
        }
    }
    if (page != NULL) {                   //确认是否找到了合适的空闲块，如果 page 仍然是 NULL，说明没有足够大的空闲块
        list_entry_t* prev = list_prev(&(page->page_link));   //获取当前页面在链表中的前驱节点
        list_del(&(page->page_link));     //将找到的空闲块从链表中移除
        if (page->property > n) {         //检查找到的空闲块是否大于请求的大小，如果正好相等则不需要分割；如果更大则需要分割剩余部分
            struct Page *p = page + n;    //page + n 表示从 page 开始向后移动 n 个 struct Page 的位置
            p->property = page->property - n;   //设置剩余块的大小
            SetPageProperty(p);           //标记剩余块的第一个页面为块头页面
            list_add(prev, &(p->page_link));    //将剩余的空闲块插入到原位置的前驱节点后面
        }
        nr_free -= n;                     //更新全局空闲页面计数器
        ClearPageProperty(page);          //清除分配页面的 PG_property 标志
    }
    return page;                          //返回分配的内存块起始页面指针
}

static void
default_free_pages(struct Page *base, size_t n) {
    assert(n > 0);                        //确保释放的页面数大于0        
    struct Page *p = base;
    for (; p != base + n; p ++) {
        assert(!PageReserved(p) && !PageProperty(p));    //确保页面不是系统保留页面，也不是空闲块的头页面
        p->flags = 0;                     //清除页面标志
        set_page_ref(p, 0);               //引用计数清零
    }
    base->property = n;                   //记录空闲块大小
    SetPageProperty(base);                //标记为空闲块首页面
    nr_free += n;                         //更新计数器

    if (list_empty(&free_list)) {         //插入操作，与default_init_memmap中的逻辑相同，不再赘述
        list_add(&free_list, &(base->page_link));
    } else {
        list_entry_t* le = &free_list;
        while ((le = list_next(le)) != &free_list) {
            struct Page* page = le2page(le, page_link);
            if (base < page) {
                list_add_before(le, &(base->page_link));
                break;
            } else if (list_next(le) == &free_list) {
                list_add(le, &(base->page_link));
            }
        }
    }

    //向前合并（与低地址块合并）
    list_entry_t* le = list_prev(&(base->page_link));   //获取当前块在链表中的前一个节点
    if (le != &free_list) {              //确保前驱节点不是链表头，即确实存在前一个空闲块
        p = le2page(le, page_link);      //前一个空闲块的起始页面              
        if (p + p->property == base) {   //检查前一个块的结束是否正好等于当前块的开始，property是空闲块的大小
            p->property += base->property;   //合并块大小
            ClearPageProperty(base);         //清除原块头标志
            list_del(&(base->page_link));    //从链表移除原块
            base = p;                        //更新base指向合并后的块，为后续合并做准备
        }
    }

    //向后合并（与高地址块合并）
    le = list_next(&(base->page_link)); //获取当前块在链表中的后一个节点
    if (le != &free_list) {
        p = le2page(le, page_link);
        if (base + base->property == p) {    //检查当前块的结束是否正好等于后一个块的开始
            base->property += p->property;   //合并块大小
            ClearPageProperty(p);            //清除被合并块的头标志
            list_del(&(p->page_link));       //从链表移除被合并块
        }
    }
}

static size_t
default_nr_free_pages(void) {                //这是一个简单的获取器函数，用于获取当前系统中可用的空闲物理页面总数。
    return nr_free;
}

static void
basic_check(void) {
    struct Page *p0, *p1, *p2;             //分配三个单独的页面，检查分配是否成功（返回值不为NULL即为成功）
    p0 = p1 = p2 = NULL;
    assert((p0 = alloc_page()) != NULL);
    assert((p1 = alloc_page()) != NULL);
    assert((p2 = alloc_page()) != NULL);

    assert(p0 != p1 && p0 != p2 && p1 != p2);  //页面唯一性验证，确保三个指针指向不同的物理页面
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);                            //页面引用计数检查，page_ref(p) 应该返回页面的引用计数，新分配的页面引用计数应该为0

    assert(page2pa(p0) < npage * PGSIZE);  //物理地址范围的有效性验证，确保分配的页面地址不越界
    assert(page2pa(p1) < npage * PGSIZE);  //page2pa(p)将页面指针转换为物理地址，npage * PGSIZE是系统总物理内存大小
    assert(page2pa(p2) < npage * PGSIZE);

    list_entry_t free_list_store = free_list;  //模拟内存耗尽，测试内存不足时的处理，尝试分配页面应该返回NULL（分配失败）
    list_init(&free_list);
    assert(list_empty(&free_list));

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    assert(alloc_page() == NULL);

    free_page(p0);                        //页面释放测试，释放之前分配的三个页面，检查空闲页面计数器是否正确更新为3
    free_page(p1);
    free_page(p2);
    assert(nr_free == 3);

    assert((p0 = alloc_page()) != NULL);  //重新分配测试，重新分配三个页面，尝试分配第四个页面（应该失败，因为只有三个空闲页面）
    assert((p1 = alloc_page()) != NULL);
    assert((p2 = alloc_page()) != NULL);

    assert(alloc_page() == NULL);

    //链表状态和分配顺序测试，验证空闲链表状态和分配算法
    free_page(p0);                        //释放一个页面，链表不应该为空                 
    assert(!list_empty(&free_list));

    struct Page *p;
    assert((p = alloc_page()) == p0);     //验证首次适应算法：刚刚释放的p0应该在空闲链表中，下一次分配应该返回p0
    assert(alloc_page() == NULL);         //再次分配应该失败

    //恢复测试环境并清理资源，nr_free应该为0，所有页面都已分配
    assert(nr_free == 0);                 
    free_list = free_list_store;
    nr_free = nr_free_store;

    free_page(p);
    free_page(p1);
    free_page(p2);
}

// LAB2: below code is used to check the first fit allocation algorithm (your EXERCISE 1) 
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void) {
    int count = 0, total = 0;                      //验证空闲链表的内部一致性
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
        count ++, total += p->property;
    }
    assert(total == nr_free_pages());

    basic_check();                                //运行基础测试

    struct Page *p0 = alloc_pages(5), *p1, *p2;   //大块分配测试
    assert(p0 != NULL);
    assert(!PageProperty(p0));

    list_entry_t free_list_store = free_list;     //内存耗尽环境设置
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);                        //部分释放和分割测试
    assert(alloc_pages(4) == NULL);
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
    assert((p1 = alloc_pages(3)) != NULL);
    assert(alloc_page() == NULL);
    assert(p0 + 2 == p1);

    p2 = p0 + 1;                                  //复杂合并场景测试
    free_page(p0);
    free_pages(p1, 3);
    assert(PageProperty(p0) && p0->property == 1);
    assert(PageProperty(p1) && p1->property == 3);

    assert((p0 = alloc_page()) == p2 - 1);        //分配顺序和边界测试
    free_page(p0);
    assert((p0 = alloc_pages(2)) == p2 + 1);

    free_pages(p0, 2);                            //最终合并测试
    free_page(p2);

    assert((p0 = alloc_pages(5)) != NULL);
    assert(alloc_page() == NULL);

    assert(nr_free == 0);                         //状态恢复和最终验证
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
    }
    assert(count == 0);
    assert(total == 0);
}

const struct pmm_manager default_pmm_manager = {
    .name = "default_pmm_manager",           //管理器标识
    .init = default_init,                    //初始化函数
    .init_memmap = default_init_memmap,      //内存映射初始化
    .alloc_pages = default_alloc_pages,      //页面分配函数
    .free_pages = default_free_pages,        //页面释放函数
    .nr_free_pages = default_nr_free_pages,  //空闲页面查询
    .check = default_check,                  //自检函数
};

