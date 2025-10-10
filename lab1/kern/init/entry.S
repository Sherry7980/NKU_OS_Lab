#include <mmu.h>
#include <memlayout.h>

#核心：完成内核的初始栈设置与跳转。

    .section .text,"ax",%progbits # 定义代码段，ax表示可分配可执行，%progbits表示包含程序数据
    .globl kern_entry # 声明kern_entry为全局符号，可从其他文件访问
kern_entry:
    la sp, bootstacktop  # 加载bootstacktop的地址到栈指针sp，设置内核栈顶

    tail kern_init  # 尾调用（tail call）跳转到kern_init函数，不保存返回地址

.section .data # 定义数据段
    # .align 2^12
    .align PGSHIFT # 按页大小对齐（PGSHIFT通常为12，对应4KB页对齐）
    .global bootstack # 声明bootstack为全局符号
bootstack:
    .space KSTACKSIZE  # 分配KSTACKSIZE大小的空间给启动栈
    .global bootstacktop  # 声明bootstacktop为全局符号
bootstacktop:  # 栈顶位置标签，栈从此处向下增长