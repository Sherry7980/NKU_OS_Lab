#include <stdio.h>
#include <string.h>
#include <sbi.h>
//OS内核初始化函数
int kern_init(void) __attribute__((noreturn)); //不返回

int kern_init(void) { 
    // edata: BSS段的开始地址（未初始化数据段）
    // end:   程序结束地址（BSS段的结束地址）
    extern char edata[], end[]; //外部变量
    memset(edata, 0, end - edata);  //清零BSS段：将edata到end之间的内存区域初始化为0

    const char *message = "(THU.CST) os is loading ...\n"; //定义启动消息
    cprintf("%s\n\n", message); //使用控制台输出函数打印启动消息，cprintf是之前介绍过的格式化输出函数
   while (1) //无限循环
        ;
}
