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

#define free_list (free_area.free_list) //�ڴ���п�����
#define nr_free (free_area.nr_free)     //����ҳ������

static void
default_init(void) { //�ú������ڳ�ʼ��˫�������ͷ�ڵ�Ϳ���ҳ�������
    list_init(&free_list);
    nr_free = 0;
}

static void
default_init_memmap(struct Page* base, size_t n) {
    assert(n > 0);                      //ȷ��Ҫ��ʼ����ҳ����������0
    struct Page* p = base;              //��������ָ��p��ָ����ʼҳ��
    for (; p != base + n; p++) {       //base + n ��ָ�����㣬��ʾ�� base ��ʼ����ƶ� n �� struct Page ��λ�ã�ѭ��������� base �� base + n - 1 ������ҳ��
        assert(PageReserved(p));       //���ҳ���Ƿ񱻱��Ϊ"����"״̬
        p->flags = p->property = 0;    //��ҳ������б�־λ����������
        set_page_ref(p, 0);            //��ҳ������ô�����Ϊ0
    }
    base->property = n;                //���׸�ҳ���property������Ϊn�������п���ܴ�С
    SetPageProperty(base);             //����ҳ�������ֵ
    nr_free += n;                      //���¿���ҳ������������n����Ϊ�ղų�ʼ����n������ҳ�棩
    if (list_empty(&free_list)) {      //�жϸ��б��Ƿ�Ϊ��
        list_add(&free_list, &(base->page_link));  //���գ�����ʼҳ�������ڵ���ӵ�������
    }
    else {                           //�����գ���Ҫ����ַ�������
        list_entry_t* le = &free_list; //�ȳ�ʼ��һ��ָ��ָ���������ͷ
        while ((le = list_next(le)) != &free_list) {  //һֱ����ң��������ַ��С��������
            struct Page* page = le2page(le, page_link);
            if (base < page) {         //����ҳ�����ʼ��ַbaseС�ڵ�ǰ��������ҳ��page�ĵ�ַ��˵���ҵ��˺��ʲ���λ��
                list_add_before(le, &(base->page_link));  //�ڵ�ǰλ�õ�ǰ������½ڵ�
                break;
            }
            else if (list_next(le) == &free_list) {  //�粻�ǣ�����뵽ĩβ
                list_add(le, &(base->page_link));
            }
        }
    }
}

static struct Page*
default_alloc_pages(size_t n) {           //����Ϊ������������ҳ������
    assert(n > 0);                        //ȷ�������ҳ��������0
    if (n > nr_free) {                    //���ټ��ϵͳ�Ƿ����㹻�Ŀ���ҳ��
        return NULL;                      //����������������ϵͳ�п��ж��������򷵻�NULL
    }
    struct Page* page = NULL;             //���ڼ�¼�ҵ��ĺ���ҳ��
    list_entry_t* le = &free_list;        //����ָ�룬������ͷ��ʼ
    while ((le = list_next(le)) != &free_list) {  //��ȡ��һ���ڵ㣬����һ������������ͷ������ͻ�ȥ��
        struct Page* p = le2page(le, page_link);  //������ڵ�ת��Ϊ��Ӧ��Page�ṹ��ָ��
        if (p->property >= n) {           //��鵱ǰ���п�Ĵ�С�Ƿ���������
            page = p;                     //��¼�ҵ��ĺ���ҳ��
            break;
        }
    }
    if (page != NULL) {                   //ȷ���Ƿ��ҵ��˺��ʵĿ��п飬��� page ��Ȼ�� NULL��˵��û���㹻��Ŀ��п�
        list_entry_t* prev = list_prev(&(page->page_link));   //��ȡ��ǰҳ���������е�ǰ���ڵ�
        list_del(&(page->page_link));     //���ҵ��Ŀ��п���������Ƴ�
        if (page->property > n) {         //����ҵ��Ŀ��п��Ƿ��������Ĵ�С����������������Ҫ�ָ�����������Ҫ�ָ�ʣ�ಿ��
            struct Page* p = page + n;    //page + n ��ʾ�� page ��ʼ����ƶ� n �� struct Page ��λ��
            p->property = page->property - n;   //����ʣ���Ĵ�С
            SetPageProperty(p);           //���ʣ���ĵ�һ��ҳ��Ϊ��ͷҳ��
            list_add(prev, &(p->page_link));    //��ʣ��Ŀ��п���뵽ԭλ�õ�ǰ���ڵ����
        }
        nr_free -= n;                     //����ȫ�ֿ���ҳ�������
        ClearPageProperty(page);          //�������ҳ��� PG_property ��־
    }
    return page;                          //���ط�����ڴ����ʼҳ��ָ��
}

static void
default_free_pages(struct Page* base, size_t n) {
    assert(n > 0);                        //ȷ���ͷŵ�ҳ��������0        
    struct Page* p = base;
    for (; p != base + n; p++) {
        assert(!PageReserved(p) && !PageProperty(p));    //ȷ��ҳ�治��ϵͳ����ҳ�棬Ҳ���ǿ��п��ͷҳ��
        p->flags = 0;                     //���ҳ���־
        set_page_ref(p, 0);               //���ü�������
    }
    base->property = n;                   //��¼���п��С
    SetPageProperty(base);                //���Ϊ���п���ҳ��
    nr_free += n;                         //���¼�����

    if (list_empty(&free_list)) {         //�����������default_init_memmap�е��߼���ͬ������׸��
        list_add(&free_list, &(base->page_link));
    }
    else {
        list_entry_t* le = &free_list;
        while ((le = list_next(le)) != &free_list) {
            struct Page* page = le2page(le, page_link);
            if (base < page) {
                list_add_before(le, &(base->page_link));
                break;
            }
            else if (list_next(le) == &free_list) {
                list_add(le, &(base->page_link));
            }
        }
    }

    //��ǰ�ϲ�����͵�ַ��ϲ���
    list_entry_t* le = list_prev(&(base->page_link));   //��ȡ��ǰ���������е�ǰһ���ڵ�
    if (le != &free_list) {              //ȷ��ǰ���ڵ㲻������ͷ����ȷʵ����ǰһ�����п�
        p = le2page(le, page_link);      //ǰһ�����п����ʼҳ��              
        if (p + p->property == base) {   //���ǰһ����Ľ����Ƿ����õ��ڵ�ǰ��Ŀ�ʼ��property�ǿ��п�Ĵ�С
            p->property += base->property;   //�ϲ����С
            ClearPageProperty(base);         //���ԭ��ͷ��־
            list_del(&(base->page_link));    //�������Ƴ�ԭ��
            base = p;                        //����baseָ��ϲ���Ŀ飬Ϊ�����ϲ���׼��
        }
    }

    //���ϲ�����ߵ�ַ��ϲ���
    le = list_next(&(base->page_link)); //��ȡ��ǰ���������еĺ�һ���ڵ�
    if (le != &free_list) {
        p = le2page(le, page_link);
        if (base + base->property == p) {    //��鵱ǰ��Ľ����Ƿ����õ��ں�һ����Ŀ�ʼ
            base->property += p->property;   //�ϲ����С
            ClearPageProperty(p);            //������ϲ����ͷ��־
            list_del(&(p->page_link));       //�������Ƴ����ϲ���
        }
    }
}

static size_t
default_nr_free_pages(void) { //����һ���򵥵Ļ�ȡ�����������ڻ�ȡ��ǰϵͳ�п��õĿ�������ҳ��������
    return nr_free;
}

static void
basic_check(void) {
    struct Page* p0, * p1, * p2;             //��������������ҳ�棬�������Ƿ�ɹ�������ֵ��ΪNULL��Ϊ�ɹ���
    p0 = p1 = p2 = NULL;
    assert((p0 = alloc_page()) != NULL);
    assert((p1 = alloc_page()) != NULL);
    assert((p2 = alloc_page()) != NULL);

    assert(p0 != p1 && p0 != p2 && p1 != p2);  //ҳ��Ψһ����֤��ȷ������ָ��ָ��ͬ������ҳ��
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);                            //ҳ�����ü�����飬page_ref(p) Ӧ�÷���ҳ������ü������·����ҳ�����ü���Ӧ��Ϊ0

    assert(page2pa(p0) < npage * PGSIZE);  //�����ַ��Χ����Ч����֤��ȷ�������ҳ���ַ��Խ��
    assert(page2pa(p1) < npage * PGSIZE);  //page2pa(p)��ҳ��ָ��ת��Ϊ�����ַ��npage * PGSIZE��ϵͳ�������ڴ��С
    assert(page2pa(p2) < npage * PGSIZE);

    list_entry_t free_list_store = free_list;  //ģ���ڴ�ľ��������ڴ治��ʱ�Ĵ������Է���ҳ��Ӧ�÷���NULL������ʧ�ܣ�
    list_init(&free_list);
    assert(list_empty(&free_list));

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    assert(alloc_page() == NULL);

    free_page(p0);                        //ҳ���ͷŲ��ԣ��ͷ�֮ǰ���������ҳ�棬������ҳ��������Ƿ���ȷ����Ϊ3
    free_page(p1);
    free_page(p2);
    assert(nr_free == 3);

    assert((p0 = alloc_page()) != NULL);  //���·�����ԣ����·�������ҳ�棬���Է�����ĸ�ҳ�棨Ӧ��ʧ�ܣ���Ϊֻ����������ҳ�棩
    assert((p1 = alloc_page()) != NULL);
    assert((p2 = alloc_page()) != NULL);

    assert(alloc_page() == NULL);

    //����״̬�ͷ���˳����ԣ���֤��������״̬�ͷ����㷨
    free_page(p0);                        //�ͷ�һ��ҳ�棬����Ӧ��Ϊ��                 
    assert(!list_empty(&free_list));

    struct Page* p;
    assert((p = alloc_page()) == p0);     //��֤�״���Ӧ�㷨���ո��ͷŵ�p0Ӧ���ڿ��������У���һ�η���Ӧ�÷���p0
    assert(alloc_page() == NULL);         //�ٴη���Ӧ��ʧ��

    //�ָ����Ի�����������Դ��nr_freeӦ��Ϊ0������ҳ�涼�ѷ���
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
    int count = 0, total = 0;                      //��֤����������ڲ�һ����
    list_entry_t* le = &free_list;
    while ((le = list_next(le)) != &free_list) {
        struct Page* p = le2page(le, page_link);
        assert(PageProperty(p));
        count++, total += p->property;
    }
    assert(total == nr_free_pages());

    basic_check();                                //���л�������

    struct Page* p0 = alloc_pages(5), * p1, * p2;   //���������
    assert(p0 != NULL);
    assert(!PageProperty(p0));

    list_entry_t free_list_store = free_list;     //�ڴ�ľ���������
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);                        //�����ͷźͷָ����
    assert(alloc_pages(4) == NULL);
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
    assert((p1 = alloc_pages(3)) != NULL);
    assert(alloc_page() == NULL);
    assert(p0 + 2 == p1);

    p2 = p0 + 1;                                  //���Ӻϲ���������
    free_page(p0);
    free_pages(p1, 3);
    assert(PageProperty(p0) && p0->property == 1);
    assert(PageProperty(p1) && p1->property == 3);

    assert((p0 = alloc_page()) == p2 - 1);        //����˳��ͱ߽����
    free_page(p0);
    assert((p0 = alloc_pages(2)) == p2 + 1);

    free_pages(p0, 2);                            //���պϲ�����
    free_page(p2);

    assert((p0 = alloc_pages(5)) != NULL);
    assert(alloc_page() == NULL);

    assert(nr_free == 0);                         //״̬�ָ���������֤
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
        struct Page* p = le2page(le, page_link);
        count--, total -= p->property;
    }
    assert(count == 0);
    assert(total == 0);
}

const struct pmm_manager default_pmm_manager = {
    .name = "default_pmm_manager",           //��������ʶ
    .init = default_init,                    //��ʼ������
    .init_memmap = default_init_memmap,      //�ڴ�ӳ���ʼ��
    .alloc_pages = default_alloc_pages,      //ҳ����亯��
    .free_pages = default_free_pages,        //ҳ���ͷź���
    .nr_free_pages = default_nr_free_pages,  //����ҳ���ѯ
    .check = default_check,                  //�Լ캯��
};

