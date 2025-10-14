# Lab2

2311205李欣航&nbsp;&nbsp;&nbsp; 2310711陈子烨

## 练习1：理解 first-fit 连续物理内存分配算法

### 主要思想

First Fit 算法的核心思想是，当需要分配一个资源请求时，它会从内存或存储空间的起始地址开始，顺序遍历空闲区域列表，并选择所遇到的**第一个**大小满足该请求的空闲块进行分配，而不会继续寻找后续可能存在的、大小更吻合的空闲块。

First Fit 算法以实现简单和分配速度快为主要优点，因为它通常无需遍历整个列表；但其代价是容易在内存的低地址部分留下大量难以利用的小碎片，从而可能降低内存的长期利用率。

### 具体实现

在操作系统中实现 First Fit 算法的核心是**维护一个按地址排序的空闲内存块链表**。当收到内存请求时，算法从链表头部开始顺序遍历，找到**第一个**大小满足需求的空闲块：若大小正好匹配，则将该节点从链表中移除；若该空闲块更大，则将其分割，仅分配请求大小的部分，并将剩余部分作为新空闲块更新回链表。

### 相关代码分析

#### 数据结构

<pre style="background: #f8f8f8; padding: 10px; border-radius: 5px; font-family: 'Monaco', 'Consolas', monospace;">
static free_area_t free_area;

#define free_list (free_area.free_list) //内存空闲块链表
#define nr_free (free_area.nr_free)     //空闲页面总数
</pre>

`free_area_t` 是用于管理物理内存的空闲区域的数据结构，在`memlayout.h`中可以找到它的定义：

<pre style="background: #f8f8f8; padding: 10px; border-radius: 5px; font-family: 'Monaco', 'Consolas', monospace;">
typedef struct {
    list_entry_t free_list;      //空闲内存块的链表头
    unsigned int nr_free;        //空闲页面的总数
} free_area_t;
</pre>

#### 初始化函数 default_init

<pre style="background: #f8f8f8; padding: 10px; border-radius: 5px; font-family: 'Monaco', 'Consolas', monospace;">
static void
default_init(void) {
    list_init(&free_list);
    nr_free = 0;
}
</pre>

该函数用于初始化双向链表的头节点和空闲页面计数器。函数调用`list_init`函数初始化了一个空的双向链表`free_list`，然后定义了`nr_free = 0`，也就是将空闲块的个数定义为0。

#### 初始化函数 default_init_memmap

<pre style="background: #f8f8f8; padding: 10px; border-radius: 5px; font-family: 'Monaco', 'Consolas', monospace;">
static void
default_init_memmap(struct Page *base, size_t n) {
    assert(n > 0);                      //确保要初始化的页面数量大于0
    struct Page *p = base;              //创建遍历指针p，指向起始页面
    for (; p != base + n; p ++) {       //base + n 是指针运算，表示从 base 开始向后移动 n 个 struct Page 的位置，循环会遍历从 base 到 base + n - 1 的所有页面
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
</pre>

该函数的作用为：初始化一段连续的物理内存页面，将其标记为空闲状态，并加入到空闲内存管理链表中。

函数首先对一段连续的物理内存页面进行初始化准备：它遍历从起始页面base开始的n个连续页面，确保每个页面都处于保留状态，然后清除所有页面的标志位和属性值，并将引用计数设为0，表示这些页面当前未被使用且处于干净状态。

接下来函数将这段连续页面组织成一个完整的空闲内存块：仅在起始页面base中设置property属性为n来记录整个块的大小，并标记该页面为块头页面，而其他页面保持普通页面状态。同时更新全局空闲页面计数器nr_free，增加n个页面的计数。

最后函数将这个新初始化的空闲块按物理地址顺序插入到空闲链表中：如果链表为空则直接插入；否则遍历链表，找到第一个地址比当前块大的位置并在其前面插入，或者如果当前块地址最大则插入到链表末尾，确保链表始终按地址从小到大排序，为后续的内存合并操作奠定基础。

#### 内存分配函数 default_alloc_pages

<pre style="background: #f8f8f8; padding: 10px; border-radius: 5px; font-family: 'Monaco', 'Consolas', monospace;">
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
</pre>

该函数的作用为：使用首次适应算法从空闲链表中分配指定数量的连续物理页面。

函数首先验证请求的页面数量有效性，并快速检查系统总空闲页面是否足够。接着使用首次适应算法遍历按地址排序的空闲链表，寻找第一个大小满足需求的空闲内存块，通过le2page宏将链表节点转换为页面结构体指针进行比较，找到后立即停止搜索。

找到合适空闲块后，函数记录其前驱节点位置并将其从链表中移除。如果该空闲块大小大于请求数量，则进行分割处理：计算剩余部分的起始页面，设置其大小属性并标记为新的空闲块头页面，然后将剩余部分插入到原位置的前驱节点后，保持链表有序性。

最后函数更新全局空闲页面计数器，减少已分配的页面数量，并清除分配块的头页面标志位，表明该页面已被分配使用。最终返回分配的内存块起始页面指针，完成整个分配流程，若搜索阶段未找到合适块则直接返回NULL表示分配失败。

#### 内存释放函数 default_free_pages

<pre style="background: #f8f8f8; padding: 10px; border-radius: 5px; font-family: 'Monaco', 'Consolas', monospace;">
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
</pre>

该函数的作用为：释放一段已分配的连续物理页面，将其重新加入空闲链表，并尝试与相邻的空闲块合并以减少碎片。

函数首先验证释放页面的有效性，确保它们既非系统保留页面也非已空闲页面，然后重置所有页面的标志位和引用计数，将其恢复为干净状态。接着在起始页面设置空闲块大小属性并标记为块头页面，同时更新全局空闲页面计数器，完成基本内存状态的转换。

随后函数将新释放的空闲块按物理地址顺序插入到空闲链表中。如果链表为空则直接插入，否则遍历链表找到合适的插入位置，确保链表始终保持按地址从小到大排序，为后续的合并操作奠定基础，这是减少内存碎片的关键前提。

最后函数执行双向合并操作以减少内存碎片：先检查并合并低地址方向的相邻空闲块，更新基指针后再检查合并高地址方向的相邻块。通过计算物理地址的连续性判断是否相邻，合并时调整块大小属性、清除多余的头页面标志并清理链表节点，最终形成一个更大的连续空闲块。

#### 辅助函数 default_nr_free_pages

<pre style="background: #f8f8f8; padding: 10px; border-radius: 5px; font-family: 'Monaco', 'Consolas', monospace;">
static size_t
default_nr_free_pages(void) {
    return nr_free;
}
</pre>

这是一个简单的获取器函数，用于获取当前系统中可用的空闲物理页面总数。它直接返回全局变量`nr_free`的值，该变量在内存分配时减少、在内存释放时增加，为其他系统组件提供了一种快速查询内存剩余情况的方法，无需遍历复杂的空闲链表结构，具有O(1)的时间复杂度。

#### 测试函数 basic_check()

<pre style="background: #f8f8f8; padding: 10px; border-radius: 5px; font-family: 'Monaco', 'Consolas', monospace;">
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
</pre>

该函数的作用为：对物理内存分配器和释放器进行一系列基本功能测试，验证分配、释放、页面属性等核心功能的正确性。

函数首先验证物理内存管理器的基本分配和释放功能，通过分配多个页面检查其唯一性、引用计数初始状态以及物理地址有效性，确保分配器能正确提供不重复的合法内存页面。随后测试模拟内存耗尽场景，清空空闲链表后验证分配失败行为，并测试页面释放后计数器和链表状态的正确更新，全面检验内存管理的基本操作可靠性。

接下来函数进一步验证首次适应算法的特性，通过释放页面后立即重新分配来确认算法优先分配最近释放的块，同时检查空闲链表的状态管理。测试最后执行状态恢复操作，将全局变量还原到测试前状态并清理所有测试页面，确保测试过程不影响系统后续运行，完整覆盖了内存管理器的正常操作、边界条件处理和环境隔离能力。

#### 测试函数 default_check()

<pre style="background: #f8f8f8; padding: 10px; border-radius: 5px; font-family: 'Monaco', 'Consolas', monospace;">
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
</pre>

该函数的作用为：对首次适应内存分配算法进行深入测试，验证内存分割、合并、分配顺序等复杂场景的正确性。

这个测试函数通过精心设计的场景，全面验证了首次适应算法在复杂情况下的正确性，包括内存分割、跨碎片合并、分配顺序等重要特性，确保内存管理器在真实使用场景中的可靠性。

#### 结构体 default_pmm_manager

<pre style="background: #f8f8f8; padding: 10px; border-radius: 5px; font-family: 'Monaco', 'Consolas', monospace;">
const struct pmm_manager default_pmm_manager = {
    .name = "default_pmm_manager",           //管理器标识
    .init = default_init,                    //初始化函数
    .init_memmap = default_init_memmap,      //内存映射初始化
    .alloc_pages = default_alloc_pages,      //页面分配函数
    .free_pages = default_free_pages,        //页面释放函数
    .nr_free_pages = default_nr_free_pages,  //空闲页面查询
    .check = default_check,                  //自检函数
};
</pre>

default_pmm_manager 结构体是物理内存管理器的核心接口，它封装了完整的首次适应算法实现，提供了标准化的内存管理接口，支持系统启动自检和状态监控，为上层系统组件提供稳定的内存服务，具有良好的可扩展性和可维护性。

### 各函数作用分析

- **default_init**：初始化空闲内存块的链表，将空闲块的个数设置为0。
- **default_init_memmap**：用于初始化一个空闲内存块。先查询空闲内存块的链表，按照地址顺序插入到合适的位置，并将空闲内存块个数加n。
- **default_alloc_pages**：用于分配给定大小的内存块。如果剩余空闲内存块数量多于所需的内存区块数量，则从链表中查找大小超过所需大小的页，并更新该页剩余的大小。
- **default_free_pages**：用于释放内存块。将释放的内存块按照顺序插入到空闲内存块的链表中，并合并与之相邻且连续的空闲内存块。
- **default_nr_free_pages**：用于获取当前的空闲页面的数量。
- **basic_check**：基本功能检测。
- **default_check**：进阶功能检测。
- **结构体default_pmm_manager**：方便后续的调用，将上述功能包装为结构体。

### First Fit 算法改进空间

- **引入块大小分类管理**：可以将空闲块按大小范围划分到不同的链表中进行管理，这样能减少搜索时间，优化了小块分配的效率，同时保持大块分配的灵活性。
- **实现Next Fit分配策略**：针对当前First Fit算法总是从链表头开始搜索导致低地址碎片集中的问题，可以改为Next Fit算法，这样可以避免低地址区域产生大量无法使用的小碎片。
- **建立分割阈值机制**：当前实现无条件分割大块内存，容易产生很多过小的碎片。可以引入最小分割阈值概念，只有当分割后的剩余块大小超过某个阈值时才执行分割操作。
- **采用延迟合并策略**：现有的立即合并策略在频繁分配释放场景下会带来一定的的性能开销。可以改为延迟合并机制，等到空闲块数量积累到一定阈值或系统空闲时再执行批量合并操作。
- **添加内存碎片监控与整理**：可以增加碎片度监控机制，定期评估内存碎片化程度，当碎片超过阈值时触发主动整理操作。


## 练习2：实现 Best-Fit 连续物理内存分配算法

## 扩展练习Challenge：buddy system（伙伴系统）分配算法

## 扩展练习Challenge：任意大小的内存单元slub分配算法

## 扩展练习Challenge：硬件的可用物理内存范围的获取方法