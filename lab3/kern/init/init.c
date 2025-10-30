// 需要调用中断机制的初始化函数。
#include <clock.h>
#include <console.h>
#include <defs.h>
#include <intr.h>
#include <kdebug.h>
#include <kmonitor.h>
#include <pmm.h>
#include <stdio.h>
#include <string.h>
#include <trap.h>
#include <dtb.h>

// 声明内核初始化函数，使用noreturn属性表示该函数不会返回
int kern_init(void) __attribute__((noreturn));
// 声明成绩回溯函数（用于调试）
void grade_backtrace(void);

// 内核初始化主函数
int kern_init(void) {
    // 声明外部变量，edata指向BSS段开始，end指向内核结束地址
    extern char edata[], end[];
    
    // 清零BSS段（未初始化的全局变量区域）
    memset(edata, 0, end - edata);
    
    // 初始化设备树（Device Tree Blob），获取硬件信息
    dtb_init();
    
    // 初始化控制台，设置输入输出
    cons_init();
    
    // 初始化消息字符串
    const char *message = "(THU.CST) os is loading ...\0";
    // 输出启动消息到控制台
    cputs(message);

    // 打印内核信息（如符号表等）
    print_kerninfo();

    // 调试用的回溯函数（当前被注释）
    // grade_backtrace();
    
    // 初始化中断描述符表
    idt_init();

    // 初始化物理内存管理
    pmm_init();

    // 再次初始化中断描述符表（可能是冗余代码）
    idt_init();

    // 初始化时钟中断
    clock_init();
    // 启用中断响应
    intr_enable();

    // 汇编指令：从机器模式返回（通常用于RISC-V架构）
    asm("mret");
    // 汇编指令：触发断点异常（用于调试）
    asm("ebreak");
    
    /* 无限循环，防止函数返回 */
    while (1)
        ;
}

// 不可内联的调试函数，用于调用监控器的回溯功能
void __attribute__((noinline))
grade_backtrace2(int arg0, int arg1, int arg2, int arg3) {
    mon_backtrace(0, NULL, NULL);
}

// 不可内联的调试函数，调用grade_backtrace2并传递参数地址
void __attribute__((noinline)) grade_backtrace1(int arg0, int arg1) {
    grade_backtrace2(arg0, (uintptr_t)&arg0, arg1, (uintptr_t)&arg1);
}

// 不可内联的调试函数，调整参数后调用grade_backtrace1
void __attribute__((noinline)) grade_backtrace0(int arg0, int arg1, int arg2) {
    grade_backtrace1(arg0, arg2);
}

// 成绩回溯入口函数，初始化调用链
void grade_backtrace(void) { 
    grade_backtrace0(0, (uintptr_t)kern_init, 0xffff0000); 
}