#include <stdio.h>
#include <monitor.h>
#include <kmalloc.h>
#include <assert.h>

// 初始化管程
void     
monitor_init (monitor_t * mtp, size_t num_cv) {
    int i;                                       // 循环计数器
    assert(num_cv>0);                            // 断言：条件变量数量必须大于0
    mtp->next_count = 0;                         // 初始化next_count为0（无信号进程等待）
    mtp->cv = NULL;                              // 暂时将条件变量指针设为NULL
    sem_init(&(mtp->mutex), 1); // 初始化互斥信号量为1（未锁定状态）
    sem_init(&(mtp->next), 0);  // 初始化next信号量为0（初始无信号进程）
    mtp->cv =(condvar_t *) kmalloc(sizeof(condvar_t)*num_cv); // 动态分配条件变量数组内存
    assert(mtp->cv!=NULL);                       // 断言：内存分配成功
    for(i=0; i<num_cv; i++){                     // 遍历初始化每个条件变量
        mtp->cv[i].count=0;                      // 初始化条件变量的等待进程数为0
        sem_init(&(mtp->cv[i].sem),0);           // 初始化条件变量的信号量为0（初始无等待进程）
        mtp->cv[i].owner=mtp;                    // 设置条件变量的所有者为本管程
    }
}

// 释放管程
void
monitor_free (monitor_t * mtp, size_t num_cv) {
    kfree(mtp->cv);                              // 释放条件变量数组的内存
}

// 解锁条件变量上等待的一个线程
void 
cond_signal (condvar_t *cvp) {
   //LAB7 EXERCISE1: YOUR CODE
   cprintf("cond_signal begin: cvp %x, cvp->count %d, cvp->owner->next_count %d\n", cvp, cvp->count, cvp->owner->next_count);  
   // 开始信号操作，打印调试信息：条件变量地址、等待进程数、管程的next_count

    if (cvp->count > 0) {                         // 如果条件变量上有等待进程
        cvp->owner->next_count++;                 // 增加管程的next_count（信号进程数）
        up(&(cvp->sem));                          // 唤醒条件变量信号量上的一个等待进程
        down(&(cvp->owner->next));                // 信号进程自身在管程的next信号量上等待
        cvp->owner->next_count--;                 // 信号进程被唤醒后，减少管程的next_count
    }
    
   cprintf("cond_signal end: cvp %x, cvp->count %d, cvp->owner->next_count %d\n", cvp, cvp->count, cvp->owner->next_count);
   // 结束信号操作，打印调试信息
}

// 将调用线程挂起在条件变量上等待条件，原子地解锁管程中的mutex，
// 并在唤醒后锁住mutex，将调用线程挂起在条件变量上
void
cond_wait (condvar_t *cvp) {
    //LAB7 EXERCISE1: YOUR CODE
    cprintf("cond_wait begin:  cvp %x, cvp->count %d, cvp->owner->next_count %d\n", cvp, cvp->count, cvp->owner->next_count);
    // 开始等待操作，打印调试信息
  
    cvp->count++;                                 // 增加条件变量的等待进程计数
    monitor_t *mtp = cvp->owner;                  // 获取条件变量所属的管程
    
    if (mtp->next_count > 0) {                    // 如果有信号进程在等待
        up(&(mtp->next));                         // 唤醒一个信号进程
    } else {                                      // 如果没有信号进程等待
        up(&(mtp->mutex));                        // 释放管程的互斥锁
    }
    
    down(&(cvp->sem));                            // 在条件变量信号量上等待
    cvp->count--;                                 // 被唤醒后，减少条件变量的等待进程计数
    
    cprintf("cond_wait end:  cvp %x, cvp->count %d, cvp->owner->next_count %d\n", cvp, cvp->count, cvp->owner->next_count);
    // 结束等待操作，打印调试信息
}
