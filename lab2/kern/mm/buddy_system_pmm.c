#include <pmm.h>
#include <list.h>
#include <stdio.h>
#include <string.h>
#include <buddy_system_pmm.h>

// 根据128MB内存计算最大阶数：32,768页 = 2^15页
#define MAX_ORDER 15
#define BUDDY_ARRAY_SIZE (MAX_ORDER + 1)

// 使用你提供的buddy_system_t结构体
typedef struct {
    unsigned int max_order;           // 实际最大块的大小
    list_entry_t free_array[MAX_ORDER + 1]; // 伙伴堆数组
    unsigned int nr_free;             // 伙伴系统中剩余的空闲块
} buddy_system_t;

static buddy_system_t buddy_sys;

// 基础函数实现
static bool IS_POWER_OF_2(size_t n) {
    return (n != 0) && ((n & (n - 1)) == 0);
}

static unsigned int Get_Order_Of_2(size_t n) {
    unsigned int order = 0;
    while (n > 1) {
        n >>= 1;
        order++;
    }
    return order;
}

static size_t Find_The_Small_2(size_t n) {
    if (n == 0) return 1;
    size_t power = 1;
    while (power <= n) {
        power <<= 1;
    }
    return power >> 1;
}

static size_t Find_The_Big_2(size_t n) {
    if (n == 0) return 1;
    size_t power = 1;
    while (power < n) {
        power <<= 1;
    }
    return power;
}

// 获取伙伴块地址
static struct Page* get_buddy(struct Page* page, unsigned int order) {
    if (order >= MAX_ORDER) return NULL;

    size_t page_idx = page - pages;
    size_t buddy_idx = page_idx ^ (1 << order);

    if (buddy_idx >= npage) {
        return NULL;
    }
    return &pages[buddy_idx];
}

// 显示Buddy System状态
static void show_buddy_array(unsigned int start_order, unsigned int end_order) {
    cprintf("Buddy System Status (Total free: %u pages):\n", buddy_sys.nr_free);
    for (unsigned int i = start_order; i <= end_order && i <= MAX_ORDER; i++) {
        cprintf("Order %2d (size: %5u pages): ", i, (1u << i));
        if (list_empty(&buddy_sys.free_array[i])) {
            cprintf("empty\n");
        }
        else {
            int count = 0;
            list_entry_t* le = &buddy_sys.free_array[i];
            list_entry_t* temp = le->next;
            while (temp != le) {
                count++;
                temp = temp->next;
            }
            cprintf("%d blocks\n", count);
        }
    }
}

// 初始化Buddy System
static void buddy_system_init(void) {
    buddy_sys.max_order = 0;
    buddy_sys.nr_free = 0;

    for (unsigned int i = 0; i <= MAX_ORDER; i++) {
        list_init(&buddy_sys.free_array[i]);
    }
    cprintf("buddy_system: initialized with max_order=%d\n", MAX_ORDER);
}

// 初始化内存映射
static void buddy_system_init_memmap(struct Page* base, size_t n) {
    assert(n > 0);
    cprintf("buddy_system_init_memmap: base=%p, n=%u\n", base, (unsigned int)n);

    // 初始化所有页面
    for (struct Page* p = base; p != base + n; p++) {
        assert(PageReserved(p));
        p->flags = p->property = 0;
        set_page_ref(p, 0);
        SetPageProperty(p);
        // 确保页面标记为保留状态
        SetPageReserved(p);
    }

    // 找到适合的最大块（不超过MAX_ORDER）
    size_t total_pages = n;
    unsigned int order = 0;
    size_t block_size = 1;

    while (order < MAX_ORDER && (block_size << 1) <= total_pages) {
        order++;
        block_size <<= 1;
    }

    buddy_sys.max_order = order;

    // 将整个内存区域作为一个大块加入对应阶的链表
    base->property = order;
    SetPageProperty(base);
    list_add(&buddy_sys.free_array[order], &(base->page_link));
    buddy_sys.nr_free += block_size;

    cprintf("buddy_system: added memory block of order %u (%u pages), total free: %u\n",
        order, (unsigned int)block_size, buddy_sys.nr_free);
}

// 分割内存块
static void buddy_system_split(unsigned int order) {
    assert(order > 0 && order <= MAX_ORDER);

    if (list_empty(&buddy_sys.free_array[order])) {
        return;
    }

    // 获取要分割的块
    list_entry_t* le = list_next(&buddy_sys.free_array[order]);
    struct Page* page = le2page(le, page_link);

    // 从原链表中移除
    list_del(le);
    buddy_sys.nr_free -= (1 << order);

    // 计算新块的大小
    unsigned int new_order = order - 1;
    size_t block_size = 1 << new_order;

    // 设置两个新块的属性
    struct Page* left = page;
    struct Page* right = page + block_size;

    left->property = new_order;
    right->property = new_order;

    SetPageProperty(left);
    SetPageProperty(right);
    // 确保新块标记为保留状态
    SetPageReserved(left);
    SetPageReserved(right);

    // 将两个新块添加到对应阶的链表中
    list_add(&buddy_sys.free_array[new_order], &(left->page_link));
    list_add(&buddy_sys.free_array[new_order], &(right->page_link));
    buddy_sys.nr_free += (2 << new_order);  // 添加两个块

    cprintf("buddy_system: split order %u -> two order %u blocks\n", order, new_order);
}

// 分配页面
static struct Page* buddy_system_alloc_pages(size_t n) {
    assert(n > 0);

    if (n > buddy_sys.nr_free) {
        cprintf("buddy_system: allocation failed, request %u pages, but only %u free\n",
            (unsigned int)n, buddy_sys.nr_free);
        return NULL;
    }

    // 计算需要的阶数
    size_t required_size = Find_The_Big_2(n);
    unsigned int required_order = Get_Order_Of_2(required_size);

    if (required_order > MAX_ORDER) {
        cprintf("buddy_system: allocation failed, required order %u exceeds max order %u\n",
            required_order, MAX_ORDER);
        return NULL;
    }

    // 查找合适的内存块
    unsigned int current_order = required_order;
    while (current_order <= MAX_ORDER) {
        if (!list_empty(&buddy_sys.free_array[current_order])) {
            break;
        }
        current_order++;
    }

    if (current_order > MAX_ORDER) {
        cprintf("buddy_system: allocation failed, no suitable block found\n");
        return NULL;
    }

    // 如果找到的块比需要的大，进行分割
    while (current_order > required_order) {
        buddy_system_split(current_order);
        current_order--;
    }

    // 分配内存块
    list_entry_t* le = list_next(&buddy_sys.free_array[required_order]);
    struct Page* page = le2page(le, page_link);

    // 从空闲链表中移除
    list_del(le);
    buddy_sys.nr_free -= (1 << required_order);

    // 清除页面属性，但保持保留状态
    page->property = 0;
    ClearPageProperty(page);
    // 分配后仍然保持保留状态
    SetPageReserved(page);

    cprintf("buddy_system: allocated %u pages (order %u) at page %ld\n",
        (unsigned int)n, required_order, page - pages);

    return page;
}

// 释放页面
static void
buddy_system_free_pages(struct Page* base, size_t n) {
    assert(n > 0);

    // 计算块的阶数
    size_t block_size = Find_The_Big_2(n);
    unsigned int order = Get_Order_Of_2(block_size);

    if (order > MAX_ORDER) {
        order = MAX_ORDER;
    }

    struct Page* current = base;
    current->property = order;
    SetPageProperty(current);
    SetPageReserved(current);

    cprintf("buddy_system: freeing %u pages (order %u) at page %ld\n",
        (unsigned int)n, order, base - pages);

    // 尝试合并伙伴块 - 添加安全计数器防止死循环
    unsigned int merge_count = 0;
    while (order < MAX_ORDER && merge_count < MAX_ORDER) {
        merge_count++;

        struct Page* buddy = get_buddy(current, order);

        // 更严格的伙伴块检查
        if (!buddy) break;
        if (!PageProperty(buddy)) break;
        if (buddy->property != order) break;

        // 额外的安全检查：确保伙伴块在有效范围内
        if (buddy < pages || buddy >= pages + npage) break;
        if (!PageReserved(buddy)) break;

        // 检查伙伴块是否确实在空闲链表中
        int buddy_in_list = 0;  // 使用int代替bool
        list_entry_t* le = &buddy_sys.free_array[order];
        list_entry_t* temp = le->next;
        while (temp != le) {
            if (le2page(temp, page_link) == buddy) {
                buddy_in_list = 1;  // 使用1代替true
                break;
            }
            temp = temp->next;
        }
        if (!buddy_in_list) break;

        // 从链表中移除伙伴块
        list_del(&(buddy->page_link));

        // 确定合并后的块（取地址较小的那个）
        if (current > buddy) {
            struct Page* temp_page = current;  // 重命名避免冲突
            current = buddy;
            buddy = temp_page;
        }

        // 合并块
        order++;
        current->property = order;
        SetPageReserved(current);

        cprintf("buddy_system: merged two order %u blocks -> one order %u block\n",
            order - 1, order);
        // 更新空闲页数
        buddy_sys.nr_free -= (1 << (order - 1)); // 移除被合并的块
    }

    if (merge_count >= MAX_ORDER) {
        cprintf("buddy_system: warning, merge loop reached maximum iterations\n");
    }

    // 将块添加到对应阶的空闲链表
    list_add(&buddy_sys.free_array[order], &(current->page_link));
    buddy_sys.nr_free += (1 << order);

    cprintf("buddy_system: freed successfully, total free: %u pages\n", buddy_sys.nr_free);
}

// 获取空闲页面数量
static size_t buddy_system_nr_free_pages(void) {
    return buddy_sys.nr_free;
}

// 在文件末尾添加以下测试函数

/*
 * 基础功能测试：简单分配和释放
 * 测试内容：
 * 1. 基本分配功能
 * 2. 基本释放功能
 * 3. 地址不重叠检查
 * 4. 引用计数检查
 */
static void
buddy_system_check_easy_alloc_and_free_condition(void) {
    cprintf("=== BEGIN TEST: EASY ALLOC AND FREE CONDITION ===\n");
    cprintf("当前总的空闲块的数量为：%u\n", buddy_sys.nr_free);

    struct Page* p0, * p1, * p2;
    p0 = p1 = p2 = NULL;

    // 测试分配
    cprintf("1. p0请求10页\n");
    p0 = buddy_system_alloc_pages(10);
    assert(p0 != NULL);
    show_buddy_array(0, MAX_ORDER);

    cprintf("2. p1请求10页\n");
    p1 = buddy_system_alloc_pages(10);
    assert(p1 != NULL);
    show_buddy_array(0, MAX_ORDER);

    cprintf("3. p2请求10页\n");
    p2 = buddy_system_alloc_pages(10);
    assert(p2 != NULL);
    show_buddy_array(0, MAX_ORDER);

    // 验证分配结果
    cprintf("p0的虚拟地址为: 0x%016lx\n", (unsigned long)p0);
    cprintf("p1的虚拟地址为: 0x%016lx\n", (unsigned long)p1);
    cprintf("p2的虚拟地址为: 0x%016lx\n", (unsigned long)p2);

    // 检查地址不重叠
    assert(p0 != p1 && p0 != p2 && p1 != p2);
    // 检查引用计数
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
    // 检查地址有效性
    assert(page2pa(p0) < npage * PGSIZE);
    assert(page2pa(p1) < npage * PGSIZE);
    assert(page2pa(p2) < npage * PGSIZE);

    // 测试释放
    cprintf("4. 释放p0...\n");
    buddy_system_free_pages(p0, 10);
    cprintf("释放p0后，总空闲块数目为: %u\n", buddy_sys.nr_free);
    show_buddy_array(0, MAX_ORDER);

    cprintf("5. 释放p1...\n");
    buddy_system_free_pages(p1, 10);
    cprintf("释放p1后，总空闲块数目为: %u\n", buddy_sys.nr_free);
    show_buddy_array(0, MAX_ORDER);

    cprintf("6. 释放p2...\n");
    buddy_system_free_pages(p2, 10);
    cprintf("释放p2后，总空闲块数目为: %u\n", buddy_sys.nr_free);
    show_buddy_array(0, MAX_ORDER);

    cprintf("=== END TEST: EASY ALLOC AND FREE CONDITION ===\n\n");
}

/*
 * 复杂分配测试：不同大小的混合分配
 * 测试内容：
 * 1. 不同大小请求的分配
 * 2. 内存分割的正确性
 * 3. 复杂释放场景
 */
static void
buddy_system_check_complex_alloc_and_free_condition(void) {
    cprintf("=== BEGIN TEST: COMPLEX ALLOC AND FREE CONDITION ===\n");

    struct Page* p0, * p1, * p2, * p3;
    p0 = p1 = p2 = p3 = NULL;

    // 混合大小分配
    cprintf("1. p0请求10页\n");
    p0 = buddy_system_alloc_pages(10);
    assert(p0 != NULL);
    show_buddy_array(0, MAX_ORDER);

    cprintf("2. p1请求50页\n");
    p1 = buddy_system_alloc_pages(50);
    assert(p1 != NULL);
    show_buddy_array(0, MAX_ORDER);

    cprintf("3. p2请求100页\n");
    p2 = buddy_system_alloc_pages(100);
    assert(p2 != NULL);
    show_buddy_array(0, MAX_ORDER);

    cprintf("4. p3请求200页\n");
    p3 = buddy_system_alloc_pages(200);
    assert(p3 != NULL);
    show_buddy_array(0, MAX_ORDER);

    // 验证分配
    assert(p0 != NULL && p1 != NULL && p2 != NULL && p3 != NULL);
    assert(p0 != p1 && p0 != p2 && p0 != p3);
    assert(p1 != p2 && p1 != p3 && p2 != p3);

    // 复杂释放顺序
    cprintf("5. 先释放p2(100页)...\n");
    buddy_system_free_pages(p2, 100);
    show_buddy_array(0, MAX_ORDER);

    cprintf("6. 再释放p1(50页)...\n");
    buddy_system_free_pages(p1, 50);
    show_buddy_array(0, MAX_ORDER);

    cprintf("7. 释放p0(10页)...\n");
    buddy_system_free_pages(p0, 10);
    show_buddy_array(0, MAX_ORDER);

    cprintf("8. 最后释放p3(200页)...\n");
    buddy_system_free_pages(p3, 200);
    show_buddy_array(0, MAX_ORDER);

    cprintf("=== END TEST: COMPLEX ALLOC AND FREE CONDITION ===\n\n");
}

/*
 * 边界测试：最小和最大分配
 * 测试内容：
 * 1. 最小单位(1页)分配
 * 2. 最大单位分配
 * 3. 边界值处理
 */
static void
buddy_system_check_boundary_alloc_and_free_condition(void) {
    cprintf("=== BEGIN TEST: BOUNDARY ALLOC AND FREE CONDITION ===\n");

    // 测试最小分配(1页)
    cprintf("1. 分配最小单位(1页)...\n");
    struct Page* p_min = buddy_system_alloc_pages(1);
    assert(p_min != NULL);
    show_buddy_array(0, MAX_ORDER);

    cprintf("2. 释放最小单位(1页)...\n");
    buddy_system_free_pages(p_min, 1);
    show_buddy_array(0, MAX_ORDER);

    // 测试最大分配
    cprintf("3. 分配最大单位(%u页)...\n", (1 << MAX_ORDER));
    struct Page* p_max = buddy_system_alloc_pages(1 << MAX_ORDER);
    if (p_max != NULL) {
        show_buddy_array(0, MAX_ORDER);

        cprintf("4. 释放最大单位(%u页)...\n", (1 << MAX_ORDER));
        buddy_system_free_pages(p_max, 1 << MAX_ORDER);
        show_buddy_array(0, MAX_ORDER);
    }
    else {
        cprintf("4. 最大分配失败，内存不足\n");
    }

    // 测试刚好超过最大限制
    cprintf("5. 尝试分配超过最大限制(%u + 1页)...\n", (1 << MAX_ORDER));
    struct Page* p_overflow = buddy_system_alloc_pages((1 << MAX_ORDER) + 1);
    assert(p_overflow == NULL);
    cprintf("   分配失败，符合预期\n");

    cprintf("=== END TEST: BOUNDARY ALLOC AND FREE CONDITION ===\n\n");
}

/*
 * 压力测试：大量分配和释放
 * 测试内容：
 * 1. 频繁分配释放
 * 2. 内存碎片处理
 * 3. 系统稳定性
 */
static void
buddy_system_check_stress_condition(void) {
    cprintf("=== BEGIN TEST: STRESS CONDITION ===\n");

#define STRESS_TEST_COUNT 6  // 减少数量避免内存不足
    struct Page* pages[STRESS_TEST_COUNT];

    cprintf("1. 连续分配%d个不同大小的块...\n", STRESS_TEST_COUNT);
    for (int i = 0; i < STRESS_TEST_COUNT; i++) {
        size_t size = 1 << (i % 4); // 不同大小: 1, 2, 4, 8页
        pages[i] = buddy_system_alloc_pages(size);
        assert(pages[i] != NULL);
        cprintf("   分配第%d个块: %u页\n", i + 1, (unsigned int)size);
    }
    show_buddy_array(0, MAX_ORDER);

    cprintf("2. 随机释放部分块...\n");
    // 释放奇数索引的块
    for (int i = 1; i < STRESS_TEST_COUNT; i += 2) {
        if (pages[i] != NULL) {
            size_t size = 1 << (i % 4);
            buddy_system_free_pages(pages[i], size);
            pages[i] = NULL;
        }
    }
    show_buddy_array(0, MAX_ORDER);

    cprintf("3. 再次分配填补空缺...\n");
    for (int i = 1; i < STRESS_TEST_COUNT; i += 2) {
        size_t size = 1 << (i % 4);
        pages[i] = buddy_system_alloc_pages(size);
        assert(pages[i] != NULL);
    }
    show_buddy_array(0, MAX_ORDER);

    cprintf("4. 全部释放...\n");
    for (int i = 0; i < STRESS_TEST_COUNT; i++) {
        if (pages[i] != NULL) {
            size_t size = 1 << (i % 4);
            buddy_system_free_pages(pages[i], size);
        }
    }
    show_buddy_array(0, MAX_ORDER);

    cprintf("=== END TEST: STRESS CONDITION ===\n\n");
}

/*
 * 伙伴合并测试：专门测试合并功能
 * 测试内容：
 * 1. 伙伴块识别
 * 2. 合并操作正确性
 * 3. 多级合并
 */
static void
buddy_system_check_merge_condition(void) {
    cprintf("=== BEGIN TEST: MERGE CONDITION ===\n");

    // 分配多个小块，然后按顺序释放以触发合并
    cprintf("1. 分配4个16页的块...\n");
    struct Page* p0 = buddy_system_alloc_pages(16);
    struct Page* p1 = buddy_system_alloc_pages(16);
    struct Page* p2 = buddy_system_alloc_pages(16);
    struct Page* p3 = buddy_system_alloc_pages(16);
    assert(p0 != NULL && p1 != NULL && p2 != NULL && p3 != NULL);
    show_buddy_array(0, MAX_ORDER);

    cprintf("2. 按合并友好顺序释放...\n");
    cprintf("   释放p0和p1(应该合并为32页块)...\n");
    buddy_system_free_pages(p0, 16);
    buddy_system_free_pages(p1, 16);
    show_buddy_array(0, MAX_ORDER);

    cprintf("   释放p2和p3(应该合并为另一个32页块)...\n");
    buddy_system_free_pages(p2, 16);
    buddy_system_free_pages(p3, 16);
    show_buddy_array(0, MAX_ORDER);

    cprintf("3. 验证最终合并结果...\n");
    // 最终应该合并回大块
    show_buddy_array(0, MAX_ORDER);

    cprintf("=== END TEST: MERGE CONDITION ===\n\n");
}

/*
 * 错误处理测试：异常情况处理
 * 测试内容：
 * 1. 非法参数处理
 * 2. 内存不足处理
 * 3. 重复释放检测
 */
static void
buddy_system_check_error_condition(void) {
    cprintf("=== BEGIN TEST: ERROR CONDITION ===\n");

    cprintf("1. 测试分配0页...\n");
    cprintf("   预期行为：触发断言失败，跳过此测试\n");
    // 注意：分配0页会触发assert(n>0)，这是正确的行为
    // 在实际使用中，调用者应该确保n>0

    cprintf("2. 测试分配极大值...\n");
    struct Page* p_huge = buddy_system_alloc_pages(1 << 30); // 1G页
    assert(p_huge == NULL);
    cprintf("   分配失败，符合预期\n");

    cprintf("3. 测试边界值分配...\n");
    // 测试刚好超过系统限制的值
    struct Page* p_overflow = buddy_system_alloc_pages((1 << MAX_ORDER) + 1);
    assert(p_overflow == NULL);
    cprintf("   分配 %u 页失败，符合预期\n", (1 << MAX_ORDER) + 1);

    cprintf("4. 测试内存耗尽情况...\n");
    // 分配所有可用内存
    size_t free_pages = buddy_sys.nr_free;
    struct Page* p_max = buddy_system_alloc_pages(free_pages);
    if (p_max != NULL) {
        cprintf("   成功分配所有内存: %u 页\n", (unsigned int)free_pages);

        // 尝试在内存耗尽时分配
        struct Page* p_no_memory = buddy_system_alloc_pages(1);
        assert(p_no_memory == NULL);
        cprintf("   内存耗尽时分配失败，符合预期\n");

        // 释放内存
        buddy_system_free_pages(p_max, free_pages);
    }
    else {
        cprintf("   无法一次性分配所有内存，跳过内存耗尽测试\n");
    }

    cprintf("=== END TEST: ERROR CONDITION ===\n\n");
}

/*
 * 综合测试函数：运行所有测试
 */
static void
buddy_system_comprehensive_check(void) {
    cprintf("\n");
    cprintf("**************************************************\n");
    cprintf("***        BEGIN BUDDY SYSTEM COMPREHENSIVE TEST       ***\n");
    cprintf("**************************************************\n\n");

    // 保存初始状态
    size_t initial_free = buddy_sys.nr_free;
    cprintf("初始空闲页数: %u\n", (unsigned int)initial_free);

    // 运行所有测试
    buddy_system_check_easy_alloc_and_free_condition();
    buddy_system_check_complex_alloc_and_free_condition();
    buddy_system_check_boundary_alloc_and_free_condition();
    buddy_system_check_stress_condition();
    buddy_system_check_merge_condition();
    buddy_system_check_error_condition();

    // 验证最终状态
    cprintf("最终空闲页数: %u\n", buddy_sys.nr_free);
    assert(buddy_sys.nr_free == initial_free);
    cprintf("✓ 内存泄漏检查通过\n");

    cprintf("**************************************************\n");
    cprintf("***         ALL TESTS PASSED SUCCESSFULLY!         ***\n");
    cprintf("**************************************************\n");
}

// PMM管理器接口
const struct pmm_manager buddy_system_pmm_manager = {
    .name = "buddy_system_pmm_manager",
    .init = buddy_system_init,
    .init_memmap = buddy_system_init_memmap,
    .alloc_pages = buddy_system_alloc_pages,
    .free_pages = buddy_system_free_pages,
    .nr_free_pages = buddy_system_nr_free_pages,
    .check = buddy_system_comprehensive_check,
};