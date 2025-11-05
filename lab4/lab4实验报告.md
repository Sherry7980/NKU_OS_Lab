# Lab4

## 练习1：分配并初始化一个进程控制块

### alloc_proc()函数的编写

我们首先到`proc.h`中看一下`proc_struct`结构体的定义：

```C
struct proc_struct
{
    enum proc_state state;        // 进程状态
    int pid;                      // PID
    int runs;                     // 进程运行次数
    uintptr_t kstack;             // 进程内核栈
    volatile bool need_resched;   // 是否需要重新调度以释放CPU？
    struct proc_struct *parent;   // 父进程
    struct mm_struct *mm;         // 进程内存管理字段
    struct context context;       // 上下文，用于进程切换
    struct trapframe *tf;         // 当前中断的陷阱帧
    uintptr_t pgdir;              // 页表目录(PDT)的基地址
    uint32_t flags;               // 进程标志
    char name[PROC_NAME_LEN + 1]; // 进程名称
    list_entry_t list_link;       // 进程链表链接
    list_entry_t hash_link;       // 进程哈希表链接
};
```
我们的任务就是要初始化这些变量。编写的`alloc_proc()`函数如下：

```C
alloc_proc(void)
{
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
    if (proc != NULL)
    {
        // LAB4:EXERCISE1 YOUR CODE 2310711        
        proc->state = PROC_UNINIT;                  // 初始化进程状态为未初始化
        proc->pid = -1;                             // 初始化进程ID为-1（无效ID）
        proc->runs = 0;                             // 初始化运行次数为0
        proc->kstack = 0;                           // 初始化内核栈为0
        proc->need_resched = 0;                     // 初始化不需要重新调度
        proc->parent = NULL;                        // 初始化父进程为NULL
        proc->mm = NULL;                            // 初始化内存管理结构为NULL
        memset(&(proc->context), 0, sizeof(struct context));// 初始化上下文，全部设为0
        proc->tf = NULL;                            // 初始化陷阱帧为NULL
        proc->pgdir = 0;                            // 初始化页目录表基址为0
        proc->flags = 0;                            // 初始化进程标志为0
        memset(proc->name, 0, PROC_NAME_LEN + 1);   // 初始化进程名称为空字符串
    }
    return proc;
}
```
解释：
- `state`：由`proc.h`中的`enum proc_state`，我们将进程状态设置为 `PROC_UNINIT`，表示新分配但还未完全初始化的进程控制块。
- `pid`：设置进程ID为`-1`，用来表示一个无效的进程`ID`，后续会通过 `proc.c` 中的 `get_pid()` 函数分配一个唯一的有效`PID`。
- `runs`：将该进程被调度运行的次数初始化为`0`，每次进程被调度执行时这个值会增加。
- `kstack`：内核栈指针初始化为`0`（空指针），后续会通过 `proc.c` 中的 `setup_kstack()` 函数为进程分配实际的内核栈空间
- `need_resched`：将调度标志位初始化为`0`，表示不需要重新调度。当设置为`1`时，表示进程应该主动让出`CPU`。
- `parent`：父进程指针初始化为`NULL`，在创建子进程时会设置这个字段指向创建它的父进程。
- `mm`：内存管理结构指针初始化为`NULL`。对于内核线程，通常不需要用户空间内存管理，所以保持`NULL`。
- `memset(&(proc->context), 0, sizeof(struct context))`：将进程的上下文结构体全部清零。上下文保存了进程的寄存器状态，用于进程切换时保存和恢复执行现场。
- `tf`：陷阱帧指针初始化为`NULL`。陷阱帧用于保存中断或异常发生时的`CPU`状态。
- `pgdir`：页目录表基地址初始化为`0`，后续会设置为有效的页表物理地址。
- `flags`：进程标志位初始化为`0`，用于存储进程的各种状态标志。
- `memset(proc->name, 0, PROC_NAME_LEN + 1)`：将进程名称数组全部清零，确保名称字符串以空字符结尾。后续可以通过 `proc.c` 中的 `set_proc_name()` 函数设置具体的进程名称。

上述代码完成了`PCB`的分配与初始化。

### 问题

- `struct context context` 的含义及作用
  
`context`是**保存进程执行的上下文**，也就是关键的几个寄存器的值。可用于在进程切换中还原之前的运行状态。在通过 `proc_run` 切换到`CPU`上运行时，需要调用 `switch_to` 将原进程的寄存器保存，以便下次切换回去时读出，保持之前的状态。
  
- `struct trapframe *tf` 的含义及作用

`struct trapframe *tf` 是**陷阱帧指针**，用于在发生中断、异常或系统调用时保存和恢复处理器的完整执行状态。它包含了所有通用寄存器、程序计数器、状态寄存器等关键信息，既用于在中断处理期间保护现场确保正确返回，也用于在创建新进程时初始化其执行环境，是实现进程上下文切换和用户态-内核态转换的核心数据结构。

## 练习2：为新创建的内核线程分配资源

### 代码实现
按照提示的步骤一步步实现：
```C
    // 1) 分配进程控制块
    if ((proc = alloc_proc()) == NULL) {
        goto fork_out;
    }

    // 2) 分配子进程的内核栈
    if (setup_kstack(proc) != 0) {
        goto bad_fork_cleanup_proc;
    }

    // 3) 复制/共享内存管理信息（本实验中内核线程为 share，用户态暂不涉及）
    if (copy_mm(clone_flags, proc) != 0) {
        goto bad_fork_cleanup_kstack;
    }

    // 4) 复制上下文（含 trapframe），并设置返回路径
    copy_thread(proc, stack, tf);

    // 5) 分配唯一 pid，建立父子关系与链表/哈希挂接
    proc->pid    = get_pid();
    proc->parent = current;

    // 挂到哈希表，便于 O(1) 按 pid 查找
    hash_proc(proc);
    // 插入全局进程双向链表（头插或尾插均可，保持简单）
    list_add(&proc_list, &(proc->list_link));

    // 维护全局计数
    nr_process++;

    // 6) 唤醒子进程，使其可调度（会把 state 置为 PROC_RUNNABLE）
    wakeup_proc(proc);

    // 7) 父进程得到子进程的 pid 作为返回值
    ret = proc->pid;
```
### ucore是否做到给每个新fork的线程一个唯一的id？
`ucore`通过`get_pid`函数保证了线程`id`的唯一性。
`last_pid`是上一次分配的`pid`，`next_safe`是比当前`last_pid`更大的且最靠近`last_pid`的一个已占用的`pid`，因此只要`last_pid`落在`[last_pid + 1, next_safe - 1]`这段范围内，函数就不必重新扫描整个进程链表。
1. 入口约束：可用`pid`空间>最大并发进程数
```C
static_assert(MAX_PID > MAX_PROCESS)
```
确保可分配的`pid`数量严格多于系统允许的活跃进程数上限，避免出现冲突导致无法分配。

2. 候选值生成：自增并按上界回绕
`last_pid`每次先自增，到达上界`（>= MAX_PID）`就回到`1`，形成环形编号空间。保证遍历整个`pid`空间寻找未占用值，不会卡在某个区间。

3. 位于安全区间内可直接返回
若 `last_pid < next_safe`，代表还在上次扫描得到的安全区间 `[last_pid, next_safe)` 内；这个区间被证明不含任何存活进程的`pid`，因此无需扫描即可把`last_pid`返回给新进程，且与现有进程不冲突。

4. 需要重新扫描时，重建安全区间并逐一校验
若 `last_pid >= next_safe`（或刚回绕），将 `next_safe` 设为 `MAX_PID`，从 `proc_list` 头开始扫描所有存活进程。

5. 冲突处理
若扫描时发现某进程 `proc->pid == last_pid`，说明候选值正被占用，立刻把 `last_pid` 再自增一个新候选。若自增后的 `last_pid` 已越过当前边界 `next_safe`，则必要时回绕到 `1`，并把 `next_safe` 复位为 `MAX_PID`，重新扫描直到找到未占用的候选。

6. 收紧右边界
若遇到某存活进程 `proc->pid > last_pid` 且比当前 `next_safe` 更小，就把 `next_safe` 更新为该值。

它维护静态的 `last_pid`，每次递增尝试新 `pid`；若碰到冲突，会扫描 `proc_list`，并用 `next_safe` 跳过已占用区间，必要时从 `1` 重新循环，直到找到未被任何现存进程占用的 `pid` 才返回。因此，在同一时刻系统中不会出现重复 `pid`。当旧进程退出、其 `pid` 释放后，`pid` 可能在将来被重用，但不会与存活进程冲突。

## 练习3：编写 proc_run 函数

```C
void proc_run(struct proc_struct *proc)
{
    // 只有当要运行的进程不是当前进程时，才需要执行切换
    if (proc != current)
    {
        /* 关闭本地中断，并保存当前中断标志状态 */
        unsigned long irq_flags;
        local_intr_save(irq_flags);

        /* 保存原来的当前进程指针，将 current 切换为目标进程 */
        struct proc_struct *prev = current;
        current = proc;

        /* 记录该进程被调度运行的次数（用于统计或调度算法） */
        current->runs++;

        /* 切换页表，加载新进程的地址空间 */
        lsatp(current->pgdir);

        /*
         * 进行上下文切换：
         * 保存 prev 的寄存器上下文，恢复 current 的寄存器上下文。
         * 当 CPU 再次切换回 prev 时，switch_to 函数会从这里继续执行。
         */
        switch_to(&prev->context, &current->context);

        /* 恢复之前保存的中断标志状态 */
        local_intr_restore(irq_flags);
    }
}
```

创建两个线程：
- idle 线程（空闲线程，系统初始化后第一个内核线程）
  **idleproc 的特点**：
  - **PID = 0**
  - **作用**：系统空闲时运行，不占用实际工作任务。
  - **状态**：`PROC_RUNNABLE`，并且内核调度器会优先保证其存在。
  - **栈**：直接使用内核启动栈 `bootstack`，不需要新分配。
  
-  init 线程（由 idle 创建，用于执行后续初始化或用户程序）
  **initproc 的特点**：
   - **PID = 1**
   - **作用**：执行实验中“用户程序初始化”的功能，比如打印 "Hello world!!"
   - **状态**：`PROC_RUNNABLE`，可被调度器调度运行。
   - **栈**：分配了独立的内核栈，并且通过 `do_fork()` 完成上下文初始化。

## 扩展练习 Challenge

### 1.说明语句`local_intr_save(intr_flag);....local_intr_restore(intr_flag);`是如何实现开关中断的？

`local_intr_save(intr_flag)` 和 `local_intr_restore(intr_flag) `是通过操作 RISC-V 的 `SSTATUS` 寄存器中的 `SIE (Supervisor Interrupt Enable)` 位来实现开关中断的。

当调用 `local_intr_save` 时，会读取 `sstatus` 寄存器，判断 `SIE` 位的值，如果该位为`1`，则说明中断是能进行的，这时需要调用`intr_disable`将该位置`0`，并返回`1`，将 `intr_flag` 赋值为`1`;如果该位为`0`，则说明中断此时已经不能进行，则返回`0`，将 `intr_flag` 赋值为`0`。这样就可以保证之后的代码执行时不会发生中断。

当需要恢复中断时，调用`local_intr_restore`，需要判断 `intr_flag` 的值，如果其值为`1`，则需要调用`intr_enable`将 `sstatus` 寄存器的 `SIE`位置`1`，否则该位依然保持`0`。以此来恢复调用`local_intr_save` 之前的 `SIE` 的值。

### 2.深入理解不同分页模式的工作原理

- `get_pte()`函数中有两段形式类似的代码， 结合`sv32，sv39，sv48`的异同，解释这两段代码为什么如此相像。

`get_pte()` 函数用于在多级页表中查找或创建页表项，实现虚拟地址到物理页的映射。在 `RISC-V` 的分页机制`（sv32 / sv39 / sv48）`下，地址转换过程需要逐级遍历页表。每一级页表的处理逻辑完全一致。

相同点：无论是 `sv32`、`sv39` 还是 `sv48`，页表都是多级结构，每一级都要完成以下三步：
1. 定位索引项
从虚拟地址中取出对应层级的索引（如 VPN[1]、VPN[0]），计算页目录项`（PDE）`的地址。

1. 检查有效性
若该项无效且允许创建，则为下一层页表分配一页物理内存，并清零；
然后在当前 `PDE` 中写入这页的物理地址和 `Valid` 位。

1. 继续向下层查找
若有效，则取出 `PDE` 中保存的物理页地址，进入下一层页表继续查找。

这三步在每一层都完全相同，因此每一层的代码结构几乎一致。

不同点：`sv32`、`sv39` 和 `sv48` 的主要区别在于地址宽度和页表层数。

1. `sv32` 采用 `32` 位虚拟地址，使用两级页表，虚拟页号被拆分为` VPN[1]` 和 `VPN[0]`

2. `sv39` 采用 `39` 位虚拟地址，使用三级页表，虚拟页号被拆分为 `VPN[2]`、`VPN[1]` 和 `VPN[0]`

3. `sv48` 则扩展到 `48`位虚拟地址，使用四级页表，对应 `VPN[3]`、`VPN[2]`、`VPN[1]` 和 `VPN[0]`

`ucore`中采用的是`sv39`模式，页表共三层。因此 `get_pte()` 中就出现了两段几乎相同的代码：第一段处理第一级目录项 `pdep1`，第二段处理第二级目录项 `pdep0`。两段代码的逻辑完全相同，只是索引宏`（PDX1、PDX0）`不同。

- 目前get_pte()函数将页表项的查找和页表项的分配合并在一个函数里，你认为这种写法好吗？有没有必要把两个功能拆开？

方便但可读性和可维护性较差，可以一个函数专门查找页表项，另一个函数负责在需要时分配新的页表项。

**find_pte()**
- 仅查找页表项，不分配。
- 返回 PTE 地址或者 NULL。
- 上层可以安全地用于**只读操作或检查映射**。

**alloc_pte()**
- 在需要时分配页表页并返回 PTE。
- 明确告知调用者该操作可能会分配物理内存。
