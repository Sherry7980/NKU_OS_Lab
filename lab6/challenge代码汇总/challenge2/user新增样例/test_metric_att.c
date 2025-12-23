#include <stdio.h>
#include <ulib.h>

#define LONG_WORK  200000000 
#define SHORT_WORK 20000000  

void work(int ticks) {
    volatile int i;
    for (i = 0; i < ticks; i++);
}

int main(void) {
    int pid;
    unsigned int end_ts, arrival_ts;
    unsigned int base_time = gettime_msec();

    cprintf("TEST: ATT/AWT Analysis Started.\n");

    // 1. 创建长作业 (P1)
    if ((pid = fork()) == 0) {
        lab6_setpriority(100); // SJF: 100代表长作业
        yield(); // 【修改点3】：让出CPU，确保短作业能先进入队列
        work(LONG_WORK);
        exit(0);
    }
    
    // 【修改点1】：删掉了 work(10000) 延时
    // 让长作业和短作业几乎同时进入队列，SJF 才有机会发挥作用

    // 2. 连续创建 3 个短作业
    for (int i = 0; i < 3; i++) {
        // 【修改点2】：在 Fork 之前记录时间！
        // 这样算出来的才是真正的"周转时间" (包含了在队列里排队的时间)
        arrival_ts = gettime_msec();

        if ((pid = fork()) == 0) {
            lab6_setpriority(10); // SJF: 10代表短作业
            
            // 子进程继承了 arrival_ts
            work(SHORT_WORK);
            
            end_ts = gettime_msec();
            // 打印真正的周转时间
            cprintf("Short_Job_%d Turnaround: %d ms\n", i+1, end_ts - arrival_ts);
            exit(0);
        }
    }

    while(wait() == 0);
    cprintf("TEST: ATT/AWT Analysis Finished.\n");
    return 0;
}