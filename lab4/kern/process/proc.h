#ifndef __KERN_PROCESS_PROC_H__
#define __KERN_PROCESS_PROC_H__

#include <defs.h>
#include <list.h>
#include <trap.h>
#include <memlayout.h>

// process's state in his life cycle
enum proc_state
{
    PROC_UNINIT = 0, // 未初始化
    PROC_SLEEPING,   // sleeping
    PROC_RUNNABLE,   // runnable(maybe running)
    PROC_ZOMBIE,     // almost dead, and wait parent proc to reclaim his resource
};

struct context
{
    uintptr_t ra;     //ra：返回地址寄存器，用于保存函数调用后的返回地址。
    uintptr_t sp;     //sp：栈指针寄存器，指向当前线程的栈顶。
    uintptr_t s0;
    uintptr_t s1;
    uintptr_t s2;
    uintptr_t s3;
    uintptr_t s4;
    uintptr_t s5;
    uintptr_t s6;
    uintptr_t s7;
    uintptr_t s8;
    uintptr_t s9;
    uintptr_t s10;
    uintptr_t s11;
    //s0 到 s11：这些是保存寄存器（scratch registers），用于保存临时数据，它们在函数调用时不需要被保存和恢复，因为它们不会被调用者所保留。
};

#define PROC_NAME_LEN 15
#define MAX_PROCESS 4096
#define MAX_PID (MAX_PROCESS * 2) //有效 PID 范围是：1 到 8191 (MAX_PID-1), 0 被保留给特殊的空闲进程

extern list_entry_t proc_list;

struct proc_struct
{
    enum proc_state state;        // 进程状态（最上面的proc_state枚举类型_4种）
    int pid;                      // 进程唯一标识符 PID
    int runs;                     // 进程运行次数
    uintptr_t kstack;             // 进程内核栈的虚拟地址指针
    volatile bool need_resched;   // 调度标志，为true时表示需要让出CPU进行重新调度
    struct proc_struct *parent;   // 指向父进程的指针，只有idle进程没有父进程
    struct mm_struct *mm;         // 指向内存管理结构体 mm_struct(kern/mm/vmm.c种)，管理进程的虚拟内存空间。
                                  // mm 保存了内存管理的信息，包括内存映射，虚存管理等内容

    struct context context;       // 进程是上下文信息，用于进程切换
    struct trapframe *tf;         // 指向当前中断的陷阱帧Trap Frame，保存中断/异常时的寄存器状态
                                  // tf里保存了进程的中断帧。当进程从用户空间跳进内核空间的时候，进程的执行状态被保存在了中断帧中
                                  // （注意这里需要保存的执行状态数量不同于上下文切换）
                                  // 系统调用可能会改变用户寄存器的值，我们可以通过调整中断帧来使得系统调用返回特定的值

    uintptr_t pgdir;              // 页表目录(PDT)的基地址，控制地址转换
                                  // CPU 通过 satp 寄存器找到当前页表的根节点。pgdir字段保存的是每个进程的页表根节点的物理地址

    uint32_t flags;               // 进程标志（存储各种状态）
    char name[PROC_NAME_LEN + 1]; // 进程名称（PROC_NAME_LEN最大为15，+1是包含结尾符）
    list_entry_t list_link;       // 将进程链接到全局进程双向链表 proc_list 中
    list_entry_t hash_link;       // 将进程链接到进程哈希表中，便于快速查找
};

#define le2proc(le, member) \
    to_struct((le), struct proc_struct, member)

extern struct proc_struct *idleproc, *initproc, *current;

void proc_init(void);
void proc_run(struct proc_struct *proc);
int kernel_thread(int (*fn)(void *), void *arg, uint32_t clone_flags);

char *set_proc_name(struct proc_struct *proc, const char *name);
char *get_proc_name(struct proc_struct *proc);
void cpu_idle(void) __attribute__((noreturn));

struct proc_struct *find_proc(int pid);
int do_fork(uint32_t clone_flags, uintptr_t stack, struct trapframe *tf);
int do_exit(int error_code);

#endif /* !__KERN_PROCESS_PROC_H__ */
