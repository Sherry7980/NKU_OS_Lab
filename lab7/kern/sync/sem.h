// sem.c/sem.h：实现内核级信号量，支持进程同步和互斥
#ifndef __KERN_SYNC_SEM_H__
#define __KERN_SYNC_SEM_H__

#include <defs.h>
#include <atomic.h>
#include <wait.h>

typedef struct {                                 // 定义信号量结构体
    int value;                                   // 信号量计数值：>0表示可用资源数，<0表示等待进程数
    wait_queue_t wait_queue;                     // 等待队列：当资源不足时，进程在此队列中等待
} semaphore_t;                                   // 信号量类型

void sem_init(semaphore_t *sem, int value);      // 函数声明：初始化信号量，设置初始计数值
void up(semaphore_t *sem);                       // 函数声明：V操作，释放资源，唤醒等待进程
void down(semaphore_t *sem);                     // 函数声明：P操作，申请资源，可能阻塞进程
bool try_down(semaphore_t *sem);                 // 函数声明：尝试P操作，非阻塞版本，立即返回结果

#endif /* !__KERN_SYNC_SEM_H__ */

