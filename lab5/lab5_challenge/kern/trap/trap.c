#include <defs.h>
#include <mmu.h>
#include <memlayout.h>
#include <clock.h>
#include <trap.h>
#include <riscv.h>
#include <stdio.h>
#include <assert.h>
#include <console.h>
#include <vmm.h>
#include <kdebug.h>
#include <unistd.h>
#include <syscall.h>
#include <error.h>
#include <sched.h>
#include <sync.h>
#include <sbi.h>
#include <pmm.h>      // 提供 get_pte, page_insert, page_remove 等
#include <string.h>   // 提供 memcpy

#define TICK_NUM 100

static void print_ticks()
{
    cprintf("%d ticks\n", TICK_NUM);
#ifdef DEBUG_GRADE
    cprintf("End of Test.\n");
    panic("EOT: kernel seems ok.");
#endif
}

static int do_cow_page_fault(struct mm_struct *mm, uint32_t error_code, uintptr_t addr);

// 页面错误总处理函数
static int pgfault_handler(struct trapframe *tf) { 
    uintptr_t addr = tf->tval;         // 发生错误的虚拟地址
    uint32_t error_code = tf->cause;   // 错误原因
    
    if (current == NULL) { //表示内核线程缺页（不可能啊！）所以直接panic
        print_trapframe(tf);
        panic("page fault in kernel!"); // current是当前运行进程的PCB指针
    }
    
    if (current->mm == NULL) { //表示内核线程缺页（不可能啊！）所以直接panic
        print_trapframe(tf);
        panic("page fault in kernel thread!"); // current->mm是进程的内存管理结构
    }
    
    // 检查是否是写时复制触发的页面错误
    pde_t *pgdir_va = current->mm->pgdir;      // 进程页目录
    pte_t *ptep = get_pte(pgdir_va, addr, 0);  // 获取页表项
    
    if (ptep != NULL && (*ptep & PTE_V)) {     // 页表项存在且有效
    
        // 检查COW标志 且 是写操作引起的缺页错误
        if ((*ptep & PTE_COW) && (error_code == CAUSE_STORE_PAGE_FAULT)) {
            int ret = do_cow_page_fault(current->mm, error_code, addr);
            return ret;
        }
    }
    
    cprintf("page fault at 0x%08x: %c/%c\n", addr,
            (error_code == CAUSE_LOAD_PAGE_FAULT) ? 'R' : 'W',
            (tf->status & SSTATUS_SPP) ? 'K' : 'U');
    
    return -E_INVAL; // 不是COW错误，返回无效参数错误
}

// COW页面错误处理函数————执行真正的COW复制操作
static int do_cow_page_fault(struct mm_struct *mm, uint32_t error_code, uintptr_t addr) {
    int ret = 0;
    pte_t *ptep = NULL;
    uintptr_t la = ROUNDDOWN(addr, PGSIZE);   // la = 页面对齐的地址
    
    ptep = get_pte(mm->pgdir, la, 0);         // ptep是指向虚拟地址 la 对应的页表项的指针
    if (ptep == NULL || !(*ptep & PTE_V)) {
        return -E_INVAL;
    }
    
    pte_t old_pte_value = *ptep;              // 保存原页表项
    
    struct Page *old_page = pte2page(*ptep);  // 从页表项的值 → 对应物理页的Page结构指针
    int ref_count = page_ref(old_page);       // 获取引用计数
    
    //（1）只有一个进程引用,直接恢复写权限（其他进程已经执行了COW，只剩当前进程使用）
    if (ref_count == 1) { 
        pte_t new_pte = (old_pte_value | PTE_W) & ~PTE_COW;
        *ptep = new_pte;
        
        // 强制刷新TLB
        asm volatile("sfence.vma zero, %0" :: "r"(la) : "memory");
        asm volatile("fence" ::: "memory");
        
        return 0;
    }
    
    //（2）多个进程共享,需要真正复制页面
    struct Page *new_page = alloc_page();   // 分配新物理页
    if (new_page == NULL) {                 
        return -E_NO_MEM; 
    }
    uintptr_t src_kva = (uintptr_t)page2kva(old_page); // 复制页面内容
    uintptr_t dst_kva = (uintptr_t)page2kva(new_page);
    memcpy((void*)dst_kva, (void*)src_kva, PGSIZE); // 复制4KB数据
    page_ref_dec(old_page); //原页面引用减一
    
    //（3）更新页表项
    uint32_t perm = (old_pte_value & (PTE_U | PTE_R | PTE_X)) | PTE_W; // 计算新权限
    set_page_ref(new_page, 1); // 修改PTE
    *ptep = pte_create(page2ppn(new_page), PTE_V | perm);
    
    // 强制刷新TLB，确保操作顺序
    asm volatile("sfence.vma zero, %0" :: "r"(la) : "memory");
    asm volatile("fence" ::: "memory");
    
    return 0;
}

/* idt_init - initialize IDT to each of the entry points in kern/trap/vectors.S */
void idt_init(void)
{
    extern void __alltraps(void);
    /* Set sscratch register to 0, indicating to exception vector that we are
     * presently executing in the kernel */
    write_csr(sscratch, 0);
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
    /* Allow kernel to access user memory */
    set_csr(sstatus, SSTATUS_SUM);
}

/* trap_in_kernel - test if trap happened in kernel */
bool trap_in_kernel(struct trapframe *tf)
{
    return (tf->status & SSTATUS_SPP) != 0;
}

void print_trapframe(struct trapframe *tf)
{
    cprintf("trapframe at %p\n", tf);
    // cprintf("trapframe at 0x%x\n", tf);
    print_regs(&tf->gpr);
    cprintf("  status   0x%08x\n", tf->status);
    cprintf("  epc      0x%08x\n", tf->epc);
    cprintf("  tval 0x%08x\n", tf->tval);
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr)
{
    cprintf("  zero     0x%08x\n", gpr->zero);
    cprintf("  ra       0x%08x\n", gpr->ra);
    cprintf("  sp       0x%08x\n", gpr->sp);
    cprintf("  gp       0x%08x\n", gpr->gp);
    cprintf("  tp       0x%08x\n", gpr->tp);
    cprintf("  t0       0x%08x\n", gpr->t0);
    cprintf("  t1       0x%08x\n", gpr->t1);
    cprintf("  t2       0x%08x\n", gpr->t2);
    cprintf("  s0       0x%08x\n", gpr->s0);
    cprintf("  s1       0x%08x\n", gpr->s1);
    cprintf("  a0       0x%08x\n", gpr->a0);
    cprintf("  a1       0x%08x\n", gpr->a1);
    cprintf("  a2       0x%08x\n", gpr->a2);
    cprintf("  a3       0x%08x\n", gpr->a3);
    cprintf("  a4       0x%08x\n", gpr->a4);
    cprintf("  a5       0x%08x\n", gpr->a5);
    cprintf("  a6       0x%08x\n", gpr->a6);
    cprintf("  a7       0x%08x\n", gpr->a7);
    cprintf("  s2       0x%08x\n", gpr->s2);
    cprintf("  s3       0x%08x\n", gpr->s3);
    cprintf("  s4       0x%08x\n", gpr->s4);
    cprintf("  s5       0x%08x\n", gpr->s5);
    cprintf("  s6       0x%08x\n", gpr->s6);
    cprintf("  s7       0x%08x\n", gpr->s7);
    cprintf("  s8       0x%08x\n", gpr->s8);
    cprintf("  s9       0x%08x\n", gpr->s9);
    cprintf("  s10      0x%08x\n", gpr->s10);
    cprintf("  s11      0x%08x\n", gpr->s11);
    cprintf("  t3       0x%08x\n", gpr->t3);
    cprintf("  t4       0x%08x\n", gpr->t4);
    cprintf("  t5       0x%08x\n", gpr->t5);
    cprintf("  t6       0x%08x\n", gpr->t6);
}

extern struct mm_struct *check_mm_struct;

void interrupt_handler(struct trapframe *tf)
{
    intptr_t cause = (tf->cause << 1) >> 1;
    switch (cause)
    {
    case IRQ_U_SOFT:
        cprintf("User software interrupt\n");
        break;
    case IRQ_S_SOFT:
        cprintf("Supervisor software interrupt\n");
        break;
    case IRQ_H_SOFT:
        cprintf("Hypervisor software interrupt\n");
        break;
    case IRQ_M_SOFT:
        cprintf("Machine software interrupt\n");
        break;
    case IRQ_U_TIMER:
        cprintf("User software interrupt\n");
        break;
    case IRQ_S_TIMER:{
        // "All bits besides SSIP and USIP in the sip register are
        // read-only." -- privileged spec1.9.1, 4.1.4, p59
        // In fact, Call sbi_set_timer will clear STIP, or you can clear it
        // directly.
        // cprintf("Supervisor timer interrupt\n");
        /* LAB5 GRADE   YOUR CODE :  */
        /* 时间片轮转： 
        *(1) 设置下一次时钟中断（clock_set_next_event）
        *(2) ticks 计数器自增
        *(3) 每 TICK_NUM 次中断（如 100 次），进行判断当前是否有进程正在运行，如果有则标记该进程需要被重新调度（current->need_resched）
        */
        // (1) 设置下一次时钟中断
        clock_set_next_event();
        
        // (2) ticks 计数器自增
        ticks++;
        
        // (3) 每 TICK_NUM 次中断，标记进程需要重新调度
        if (ticks % TICK_NUM == 0) {
            if (current != NULL) {
                current->need_resched = 1;
            }
        }
        
        break;
    } 
    case IRQ_H_TIMER:
        cprintf("Hypervisor software interrupt\n");
        break;
    case IRQ_M_TIMER:
        cprintf("Machine software interrupt\n");
        break;
    case IRQ_U_EXT:
        cprintf("User software interrupt\n");
        break;
    case IRQ_S_EXT:
        cprintf("Supervisor external interrupt\n");
        break;
    case IRQ_H_EXT:
        cprintf("Hypervisor software interrupt\n");
        break;
    case IRQ_M_EXT:
        cprintf("Machine software interrupt\n");
        break;
    default:
        print_trapframe(tf);
        break;
    }
}
void kernel_execve_ret(struct trapframe *tf, uintptr_t kstacktop);
void exception_handler(struct trapframe *tf)
{
    int ret;
    switch (tf->cause)
    {
    case CAUSE_MISALIGNED_FETCH:
        cprintf("Instruction address misaligned\n");
        break;
    case CAUSE_FETCH_ACCESS:
        cprintf("Instruction access fault\n");
        break;
    case CAUSE_ILLEGAL_INSTRUCTION:
        cprintf("Illegal instruction\n");
        break;
    case CAUSE_BREAKPOINT:
        cprintf("Breakpoint\n");
        if (tf->gpr.a7 == 10)
        {
            tf->epc += 4;
            syscall();
            kernel_execve_ret(tf, current->kstack + KSTACKSIZE);
        }
        break;
    case CAUSE_MISALIGNED_LOAD:
        cprintf("Load address misaligned\n");
        break;
    case CAUSE_LOAD_ACCESS:
        cprintf("Load access fault\n");
        break;
    case CAUSE_MISALIGNED_STORE:
        panic("AMO address misaligned\n");
        break;
    case CAUSE_STORE_ACCESS:
        cprintf("Store/AMO access fault\n");
        break;
    case CAUSE_USER_ECALL:
        // cprintf("Environment call from U-mode\n");
        tf->epc += 4;
        syscall();
        break;
    case CAUSE_SUPERVISOR_ECALL:
        cprintf("Environment call from S-mode\n");
        tf->epc += 4;
        syscall();
        break;
    case CAUSE_HYPERVISOR_ECALL:
        cprintf("Environment call from H-mode\n");
        break;
    case CAUSE_MACHINE_ECALL:
        cprintf("Environment call from M-mode\n");
        break;
    case CAUSE_FETCH_PAGE_FAULT:
        // cprintf("Instruction page fault\n");
        if ((ret = pgfault_handler(tf)) != 0) {
            cprintf("Instruction page fault\n");
            print_trapframe(tf);
            if (current != NULL) {
                do_exit(-E_KILLED);
            } else {
                panic("kernel page fault");
            }
        }
        break;
    case CAUSE_LOAD_PAGE_FAULT:
        // cprintf("Load page fault\n");
        if ((ret = pgfault_handler(tf)) != 0) {
            cprintf("Load page fault\n");
            print_trapframe(tf);
            if (current != NULL) {
                do_exit(-E_KILLED);
            } else {
                panic("kernel page fault");
            }
        }
        break;
    case CAUSE_STORE_PAGE_FAULT:
        // cprintf("Store/AMO page fault\n");
        if ((ret = pgfault_handler(tf)) != 0) {
            cprintf("Store/AMO page fault\n");
            print_trapframe(tf);
            if (current != NULL) {
                do_exit(-E_KILLED);
            } else {
                panic("kernel page fault");
            }
        }
        break;
    default:
        print_trapframe(tf);
        break;
    }
}

static inline void trap_dispatch(struct trapframe *tf)
{
    if ((intptr_t)tf->cause < 0)
    {
        // interrupts
        interrupt_handler(tf);
    }
    else
    {
        // exceptions
        exception_handler(tf);
    }
}

/* *
 * trap - handles or dispatches an exception/interrupt. if and when trap() returns,
 * the code in kern/trap/trapentry.S restores the old CPU state saved in the
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void trap(struct trapframe *tf)
{
    // dispatch based on what type of trap occurred
    //    cputs("some trap");
    if (current == NULL)
    {
        trap_dispatch(tf);
    }
    else
    {
        struct trapframe *otf = current->tf;
        current->tf = tf;

        bool in_kernel = trap_in_kernel(tf);

        trap_dispatch(tf);

        current->tf = otf;
        if (!in_kernel)
        {
            if (current->flags & PF_EXITING)
            {
                do_exit(-E_KILLED);
            }
            if (current->need_resched)
            {
                schedule();
            }
        }
    }
}
