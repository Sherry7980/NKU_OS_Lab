#include <stdio.h>
#include <ulib.h>

/* * 调度开销测试 (修正版)
 * 增加负载以确保能测出时间
 */

// 将进程数从 20 增加到 1000，放大调度和 fork 的开销
#define PROCESS_NUM 1000 
#define TINY_WORK 100 

void work(int ticks) {
    volatile int i;
    for (i = 0; i < ticks; i++);
}

int main(void) {
    int pid;
    unsigned int start = gettime_msec();

    cprintf("TEST: Overhead Analysis Started (N=%d)...\n", PROCESS_NUM);

    for (int i = 0; i < PROCESS_NUM; i++) {
        if ((pid = fork()) == 0) {
            // 子进程
            work(TINY_WORK); 
            exit(0);
        }
    }

    // 父进程等待所有子进程结束
    // 这里的 wait() 次数要匹配 PROCESS_NUM
    for (int i = 0; i < PROCESS_NUM; i++) {
        wait();
    }
    
    unsigned int total_time = gettime_msec() - start;
    cprintf("Total time for %d tiny processes: %d ms\n", PROCESS_NUM, total_time);
    
    // 计算平均每个进程的开销 (总时间 / 进程数)
    // 注意：这里打印的是整数部分，可能为0，所以看 Total time 更准
    if (PROCESS_NUM > 0)
        cprintf("Average overhead per process: %d.%d ms\n", 
                total_time / PROCESS_NUM, 
                (total_time * 10 / PROCESS_NUM) % 10);
                
    return 0;
}