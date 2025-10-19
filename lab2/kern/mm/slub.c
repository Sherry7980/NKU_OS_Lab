
#include <defs.h>
#include <stdio.h>
#include <string.h>
#include <assert.h>
#include <pmm.h>

extern uintptr_t va_pa_offset;//声明内核虚拟地址与物理地址的固定偏移，RISC-V uCore 常见做法KVA = PA + va_pa_offset
//内核虚拟机地址=物理地址+va_pa_offset
static inline void *page2kva(struct Page *page) {
    return (void *)(page2pa(page)+va_pa_offset);//得到对应页框在内核虚拟空间中的地址
}
static inline struct Page *kva2page(void *kva) {//struct Page页描述符
    uintptr_t pa=(uintptr_t)kva-va_pa_offset;
    return pa2page(pa);//把物理地址映射回页描述符
}

#include <list.h>
#include "slub.h"

#ifndef MAX
#define MAX(a,b) (( (a) > (b) ) ? (a) : (b))
#endif

#ifndef MIN
#define MIN(a,b) (( (a) < (b) ) ? (a) : (b))
#endif

#ifndef offsetof
#define offsetof(type, member) ((size_t)&(((type *)0)->member))
#endif //计算某个结构体成员相对整个结构体起始地址的偏移

#ifndef LIST2STRUCT
#define LIST2STRUCT(le, type, member) \
    ((type *)((char *)(le) - offsetof(type, member)))
#endif //从链表节点反推外层结构体 同first-fit中的le2page

#ifndef PAGE_SIZE
#define PAGE_SIZE 4096
#endif


#define ALIGN_UP(x,a)   (((x)+((a)-1)) & ~((a)-1))

#ifndef PAGE_SIZE
#define PAGE_SIZE 4096
#endif

//初始化3个链表头，在slub分配器中每个kmem_cache都要维护三个不同状态的slab链表（已满full，部分可用partial，完全空闲empty
//如果只用一条链表，分配对象时必须遍历每个 slab 去找空位
static inline void list_init3(list_entry_t *a, list_entry_t *b, list_entry_t *c) {
    list_init(a); 
    list_init(b); 
    list_init(c);
}

static slab_page_t *slab_new(kmem_cache_t *c);
static void slab_delete(slab_page_t *sp);
static void *slab_alloc_obj(slab_page_t *sp);
static void slab_free_obj(slab_page_t *sp, void *obj);
static slab_page_t *ptr_to_slab(void *obj);

//为第二层基于任意大小的内存分配设计参数
#define KMALLOC_MIN 8  //最小 1字节
#define KMALLOC_MAX (PAGE_SIZE * 4)  //理论最大支持对象 16KB
#define KMALLOC_BUCKETS 32  //bucket数量 相同大小的对象会放在同一个bucket中
                            //bucket_size[i] = KMALLOC_MIN * (2^i)  KMALLOC_MIN = 8

static kmem_cache_t *size_caches[KMALLOC_BUCKETS]; //按bucket编号保存每个尺寸的 kmem_cache 指针
static size_t bucket_sizes[KMALLOC_BUCKETS]; //按bucket编号保存每个桶的字节大小
static bool slub_ready = 0; //slab已可用的全局标志，确保kmalloc和kfree不会在slab初始化前被用到

//将任意大小x向上取整到桶大小所使用的2的幂次方值（最小8字节）
//这个函数决定了对象会被放入哪个桶
static size_t next_pow2(size_t x){
    size_t p=KMALLOC_MIN;
    while(p < x) p <<= 1;
    return p;
}

//根据用户请求的 size，找到对应的桶号
static int bucket_index(size_t size){
    size = MAX(size, (size_t)KMALLOC_MIN); //保证最小也是8B
    size_t s = KMALLOC_MIN; //从第0号桶开始检查
    int i=0;
    while(s < size && i<KMALLOC_BUCKETS-1){ 
        s<<=1; 
        i++; 
    }
    return i;
}

//它用于创建并初始化一个对象缓存kmem_cache，这个缓存负责管理一类固定大小对象的所有slab页面
kmem_cache_t *kmem_cache_create(const char *name, size_t size, size_t align, size_t slab_pages){
    struct Page *pg = alloc_page(); //向页分配器申请1页 这一页用来存放kmem_cache_t管理结构
    assert(pg != NULL);
    kmem_cache_t *c = (kmem_cache_t*)page2kva(pg); //得到的申请页的内核虚拟地址用于指针
    memset(c, 0, sizeof(*c)); //清零结构体
    list_init3(&c->full, &c->partial, &c->empty);
    c->name = name;
    c->align = (align==0)?MIN(64, size):align; //让每个对象的起始地址满足对齐要求
    size = ALIGN_UP(size, c->align); //把对象大小向上取整到这个对齐
    c->size = size;
    c->slab_npages = (slab_pages==0)?1:slab_pages; //定义一个 slab由几页组成，这里固定使用1页
    return c;
}


void kmem_cache_destroy(kmem_cache_t *c){
    // full 列表：逐个删 slab
    {
        list_entry_t *le = list_next(&c->full);
        while (le != &c->full) {
            list_entry_t *next = list_next(le);
            slab_page_t *sp = LIST2STRUCT(le, slab_page_t, link);
            list_del(le);
            slab_delete(sp);
            le = next;
        }
    }

    // partial 列表：逐个删 slab
    {
        list_entry_t *le = list_next(&c->partial);
        while (le != &c->partial) {
            list_entry_t *next = list_next(le);
            slab_page_t *sp = LIST2STRUCT(le, slab_page_t, link);
            list_del(le);
            slab_delete(sp);
            le = next;
        }
    }

    // empty 列表：逐个删 slab
    {
        list_entry_t *le = list_next(&c->empty);
        while (le != &c->empty) {
            list_entry_t *next = list_next(le);
            slab_page_t *sp = LIST2STRUCT(le, slab_page_t, link);
            list_del(le);
            slab_delete(sp);
            le = next;
        }
    }

    free_page(kva2page((void*)c));
}

//向页分配器要一页，在页里布置好slab的元数据、位图、对象区，然后把它挂回给上层使用。这个函数把页层内存，变成对象层可用的slab
static slab_page_t *slab_new(kmem_cache_t *c){
    size_t npages = c->slab_npages; 
    struct Page *pg = alloc_pages(npages); //从第一层页分配器申请npages页
    if(pg == NULL) return NULL; 
    void *slab_mem = page2kva(pg); //把页描述符转成内核虚拟地址，后续在这片内存上布局
    size_t slab_bytes = npages * PAGE_SIZE; //slab的总字节数

    // 元数据在页头
    slab_page_t *sp = (slab_page_t*)slab_mem;
    memset(sp, 0, sizeof(*sp));
    sp->cache   = c; //把这个slab归属到哪一个哪种对象尺寸的缓存池kmem_cache
    sp->obj_size= (uint16_t)c->size; //记录单个对象的步长（已经在 kmem_cache_create 中按对齐向上取整过）
    sp->npages  = npages;  //这个slab占用了多少页

    // 先按 8B 对齐元数据
    size_t meta = ALIGN_UP(sizeof(*sp), 8);

    // --- 第一轮：用“最大可能对象数”粗略估算 bitmap 大小 ---
    size_t objs_guess = (slab_bytes - meta) / c->size; //假装除了元数据外，剩下全给对象区，能放下多少个对象。得到最大可能对象数”objs_guess
    if (objs_guess == 0) {
        // 无法容纳任何对象，直接回收并返回 NULL
        free_pages(pg, npages);
        return NULL;
    }
    size_t bits_guess = objs_guess; //位图需要的bit数 = 对象数
    size_t bm_bytes_guess = ALIGN_UP(((bits_guess + 31) / 32) * 4, 16);

    /*内存布局目前设想为：
      slab头(meta) → 位图(bm_bytes_guess) → 对象区(data_start)
      但对象区起点必须按对象对齐 c->align，所以对 (meta + 位图) 之后再做一次上取整对齐，得到对象区真实起点 data_start*/
    uintptr_t data_start = ALIGN_UP((uintptr_t)slab_mem + meta + bm_bytes_guess, c->align);

    // 根据真正可用空间重新计算“最终对象数”
    size_t used_hdr = (size_t)(data_start - (uintptr_t)slab_mem);   // meta + bitmap(+pad)
    if (used_hdr >= slab_bytes) { //如果头部就占用了整页，这一页无法再存放对象，回收返回
        free_pages(pg, npages);
        return NULL;
    }
    size_t objs_final = (slab_bytes - used_hdr) / c->size; //最终可容纳对象数
    if (objs_final == 0) {
        free_pages(pg, npages);
        return NULL;
    }

    // --- 第二轮：用最终对象数回写 bitmap 大小（只会更小，不会更大）---
    size_t bits = objs_final; //位图需要的位数 = 对象个数（每对象1bit）
    size_t bitmap_bytes = ALIGN_UP(((bits + 31) / 32) * 4, 16);

    // 写入 slab 结构
    sp->objs_per_slab = (uint16_t)objs_final; 
    sp->bitmap_words  = (uint16_t)(bitmap_bytes / 4);

    sp->bitmap = (uint32_t*)((uint8_t*)slab_mem + meta); //位图的实际地址 = 页首 + meta
    memset(sp->bitmap, 0, bitmap_bytes); //把位图清零，表示所有对象槽位都是空闲0

    sp->data = (void*)ALIGN_UP((uintptr_t)sp->bitmap + bitmap_bytes, c->align); ////data用最终bitmap大小再对齐一次
    sp->free_cnt = (uint16_t)objs_final; //初始化空闲计数 一开始所有对象槽都空闲，所以空闲数 = 槽位总数

    list_init(&sp->link);
    return sp;
}


static void slab_delete(slab_page_t *sp){
    struct Page *pg = kva2page((void*)sp);
    free_pages(pg, sp->npages);
}

//用来在slab的位图中找一个空对象槽位并占用，找到“第一个为 0 的位”，把它置为 1，并返回它的全局索引；若找不到，返回 -1
static int bitmap_find_zero_and_set(uint32_t *bm, int words, int limit) {
    for (int w = 0; w < words; w++) {
        int base = w * 32;
        if (base >= limit) break; //如果这个字的起点已经不小于 limit，说明从这字开始已经没有有效位，提前退出

        //最后一个 32 位字不能全部使用，只能使用有效的前几位
        int valid_bits = limit - base;
        if (valid_bits > 32) valid_bits = 32;

        // 只在有效位范围内查找 0 位：把无效位强制视为 1（占用）
        uint32_t mask;
        if (valid_bits == 32) {
            mask = 0xFFFFFFFFu;        // 全 1
        } else if (valid_bits == 0) {
            mask = 0u;                 // 没有有效位（通常不会走到这里）
        } else {
            mask = 0xFFFFFFFFu >> (32 - valid_bits);
        }

        // 只看有效位
        uint32_t word = bm[w] & mask;

        // 有效位全部为 1 → 这个 32 位块已满，继续下一个
        if (word == mask) {
            continue;
        }


        // 在有效范围内找第一个 0 位：等价于寻找 (~word & mask) 的第一个 1 位
        uint32_t freebits = (~word) & mask;
        int bit = 0;
        while ((freebits & 1u) == 0u) {
            freebits >>= 1;
            bit++; //记录右移了几次
        }

        int pos = base + bit;                     // 全局位索引
        bm[w] = word | (1u << bit);               // 置 1（占用）
        return pos;
    }
    return -1;
}

//用于清零位图里指定对象槽
static inline void bitmap_clear(uint32_t *bm, int idx){
    //idx是要清零的第几个对象槽
    //idx>>5：等价于 idx / 32，找到“第几个 32 位整数”
    bm[idx>>5] &= ~(1u<<(idx&31));
}

//用于检查位图中指定对象槽位是占用状态还是空闲状态
static inline bool bitmap_test(uint32_t *bm, int idx){
    return (bm[idx>>5] >> (idx&31)) & 1u;
}

//用于从 slab 中找一个空对象槽，标记为占用，并返回这个槽的地址
static void *slab_alloc_obj(slab_page_t *sp){
    if(sp->free_cnt == 0) return NULL;
    int idx = bitmap_find_zero_and_set(sp->bitmap, sp->bitmap_words, sp->objs_per_slab);
    if(idx < 0) return NULL;
    sp->free_cnt--;
    return (void*)((uint8_t*)sp->data + (size_t)idx * sp->obj_size);
}

static void slab_free_obj(slab_page_t *sp, void *obj){
    size_t offset = (uint8_t*)obj - (uint8_t*)sp->data; 
    int idx = (int)(offset / sp->obj_size); //先把指针obj换算成它是对象区里第几个对象
    
    //保证数据合法
    assert(idx >=0 && idx < sp->objs_per_slab); //idx必须在合法范围 [0, objs_per_slab)
    assert(bitmap_test(sp->bitmap, idx)); //该位必须现在就是 1
    bitmap_clear(sp->bitmap, idx); //位图清零
    sp->free_cnt++;
}

//把任意指针 obj 反推出它所属的 slab
static slab_page_t *ptr_to_slab(void *obj){
    if (obj == NULL) return NULL;

    // 映射到对象所在的页，再取该页首地址作为slab头
    struct Page *pg = kva2page(obj);
    if (pg == NULL) return NULL;
    slab_page_t *sp = (slab_page_t *)page2kva(pg);

    //cache 指针要存在，尺寸在合理范围内
    if (sp->cache == NULL) return NULL;
    if (sp->obj_size < KMALLOC_MIN || sp->obj_size > KMALLOC_MAX) return NULL;
    if (sp->objs_per_slab == 0) return NULL;

    // 边界检查：obj 必须落在对象区间范围内
    uint8_t *p    = (uint8_t*)obj;
    uint8_t *base = (uint8_t*)sp->data;
    size_t   span = (size_t)sp->objs_per_slab * (size_t)sp->obj_size;
    if (p < base || (size_t)(p - base) >= span) return NULL;
    if ( ((size_t)(p - base)) % sp->obj_size != 0 ) return NULL;

    return sp;
}

//从某个尺寸的缓存池 kmem_cache_t *c 里挑一块合适的 slab，向其中分配一个对象，并按结果把该 slab 移到正确的链表
void *kmem_cache_alloc(kmem_cache_t *c){
    slab_page_t *sp = NULL;
    //选择一个还有空位的slab
    if(!list_empty(&c->partial)){ //优先从partial中拿
        sp = LIST2STRUCT(list_next(&c->partial), slab_page_t, link);
    } else if(!list_empty(&c->empty)){  //其次从empty中拿
        sp = LIST2STRUCT(list_next(&c->empty), slab_page_t, link);
    } else {  //两者都没有，新建一个 slab（向页分配器要页、在页上布置元数据/位图/对象区），建好后先挂到 empty
        sp = slab_new(c);
        if(sp == NULL) return NULL;
        list_add(&c->empty, &sp->link);
    }

    void *obj = slab_alloc_obj(sp); //在选中的 slab 里分配一个对象
    assert(obj != NULL);

    //根据分配后的空闲数，把 slab 移到正确的链
    list_del(&sp->link);
    if(sp->free_cnt == 0){
        list_add(&c->full, &sp->link);
    } else {
        list_add(&c->partial, &sp->link);
    }
    return obj;
}

//把 obj 还回它所属的缓存池 c，并按释放后的空闲数把所在 slab 归位到正确链表
void kmem_cache_free(kmem_cache_t *c, void *obj){
    /*通过对象指针反查它所在的 slab 页头
    如果 obj 不是 SLUB 的小对象，ptr_to_slab 会返回 NULL，
    上层的通用 kfree 会走“整页释放”路径*/
    slab_page_t *sp = ptr_to_slab(obj);
    assert(sp->cache == c);
    slab_free_obj(sp, obj);
    list_del(&sp->link);
    if(sp->free_cnt == sp->objs_per_slab){
        list_add(&c->empty, &sp->link);
    } else {
        list_add(&c->partial, &sp->link);
    }
  
}

//slub分配器初始化，建立不同尺寸的桶
static void init_size_buckets(void){
    for(int i=0;i<KMALLOC_BUCKETS;i++){
        size_t s = ((size_t)1 << i) * KMALLOC_MIN;
        bucket_sizes[i] = s;
        if(s > KMALLOC_MAX) { 
            size_caches[i] = NULL; 
            continue; 
        }
    }
}

//初始化slub体系
void slub_init(void){
    init_size_buckets();
    slub_ready = 1;
    cprintf("[slub] init ok: buckets up to %d bytes\n", KMALLOC_MAX);
}

//把任意 size 映射到一个合适的固定尺寸对象缓存 kmem_cache_t 的入口
static kmem_cache_t *get_cache_for(size_t size){
    // 凡是 >= PAGE_SIZE 的尺寸（或映射桶 >= PAGE_SIZE），不走 SLUB，直接整页分配
    if (size >= PAGE_SIZE) {
        return NULL;
    }

    int i = bucket_index(size);
    size_t s = bucket_sizes[i];

    // 再次检查桶尺寸如果已经 >= PAGE_SIZE，也不走 SLUB，避免单页 slab 放不下一个对象
    if (s >= PAGE_SIZE) {
        return NULL;
    }

    if (size_caches[i] == NULL){
        size_t pages = 1; // 这个实现只支持单页 slab，和 ptr_to_slab 的假设一致
        size_caches[i] = kmem_cache_create("kmalloc", s, MIN(s, (size_t)64), pages);
    }
    return size_caches[i];
}

//小于一页的交给 SLUB（第二层）按桶分配；大于等于一页的直接按页分配
void *kmalloc(size_t size){
    assert(slub_ready);
    if(size == 0) return NULL;
    kmem_cache_t *c = get_cache_for(size); //如果 size < PAGE_SIZE 且对应的桶尺寸也 < 一页，就返回该桶的 kmem_cache
    if(c){ //若拿到 c，走 SLUB 路径：在该缓存池的 slab 里分一个对象
        return kmem_cache_alloc(c);
    }
    //不适合SLUB分配，整页分配
    size_t npages = (size + PAGE_SIZE - 1) / PAGE_SIZE;
    struct Page *p = alloc_pages(npages);
    if(!p) return NULL;
    void *kva = page2kva(p);
    
    ((size_t*)kva)[0] = npages; //在页首kva处写入npages
    return (void*)((uint8_t*)kva + sizeof(size_t));
}

//统一释放
//判定是来自slab的对象，走SLUB释放
//整页分配的按页释放
void kfree(void *ptr){
    if(ptr == NULL) return;
    //检查是否来自slab
    slab_page_t *sp = ptr_to_slab(ptr);
    //安全性检查，对象必须落在对象区
    if(sp!=NULL){
        kmem_cache_free(sp->cache, ptr);
        return;
    }
    //整页释放
    void *kva = (uint8_t*)ptr - sizeof(size_t); //减去在页首存的页数信息
    size_t npages = ((size_t*)kva)[0];
    struct Page *p = kva2page(kva);
    free_pages(p, npages);
}


/*测试用例*/

static uint32_t prng_state = 1;
static uint32_t prng(void){ prng_state = prng_state*1103515245 + 12345; return prng_state; }

int slub_selftest(void){
    cprintf("[slub] selftest start\n");
    prng_state = 1;

    // 1) 幂次尺寸 按规则分配和释放
    for(size_t s=8; s<=2048; s<<=1){
        void *p[32];
        int n=32;
        for(int i=0;i<n;i++){ p[i]=kmalloc(s); assert(p[i]!=NULL); memset(p[i], 0xA5, s<16? s:16); }
        for(int i=0;i<n;i+=2){ kfree(p[i]); }
        for(int i=1;i<n;i+=2){ kfree(p[i]); }
    }

    // 2) 小块随机分配和释放
    enum {N=256};
    void *arr[N]={0};
    for(int it=0; it<5000; it++){
        int i = prng() % N;
        if(arr[i]==NULL){
            size_t s = (prng()%3000)+1;
            arr[i] = kmalloc(s);
            assert(arr[i]!=NULL);
            ((uint8_t*)arr[i])[0] = 0x5A;
        }else{
            kfree(arr[i]);
            arr[i]=NULL;
        }
    }
    for(int i=0;i<N;i++) if(arr[i]) kfree(arr[i]);

    // 3) 整页分配和释放
    void *b1 = kmalloc(5000);
    void *b2 = kmalloc(12000);
    assert(b1 && b2);
    kfree(b1); 
    kfree(b2);

    cprintf("[slub] selftest passed\n");
    return 0;
}
