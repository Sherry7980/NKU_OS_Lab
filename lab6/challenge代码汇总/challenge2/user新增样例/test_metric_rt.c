#include <stdio.h>
#include <ulib.h>

/* 指标定义:
 * 响应时间 (Response Time) = 首次获得CPU时刻 - 到达时刻
 */

#define WORK_LOAD 200000000

void work(int ticks) {
    volatile int i;
    for (i = 0; i < ticks; i++);
}

int main(void) {
    int pid;
    unsigned int base_time = gettime_msec();

    // 1. 低优先级/长作业先运行
    if ((pid = fork()) == 0) {
        lab6_setpriority(10); // Low Priority
        work(WORK_LOAD);
        exit(0);
    }

    // 让它先跑一会 (比如 200ms)
    unsigned int delay_start = gettime_msec();
    while (gettime_msec() - delay_start < 200);

    // 2. 高优先级/紧急任务到达
    // 【修正】：在 Fork 之前记录到达时间（此时还在父进程中）
    // 【关键修改】: 父进程先提升自己优先级，让子进程继承 100
    lab6_setpriority(100);
    unsigned int arrival_time = gettime_msec();
    cprintf("Urgent_Job: Arrived (Forked) at %d ms\n", arrival_time - base_time);

    if ((pid = fork()) == 0) {
        lab6_setpriority(100); // High Priority
        
        // 子进程继承了 arrival_time 变量的值
        // 这一行执行时，意味着子进程真正拿到了 CPU
        unsigned int start_time = gettime_msec();
        
        cprintf("Urgent_Job: Started Running at %d ms\n", start_time - base_time);
        
        // 计算真实的响应时间
        cprintf("Urgent_Job: Response Time = %d ms\n", start_time - arrival_time);
        
        exit(0);
    }

    while(wait() == 0);
    return 0;
}