// monitor.c/monitor.h：实现管程高级同步机制，封装条件变量
#ifndef __KERN_SYNC_MONITOR_CONDVAR_H__
#define __KERN_SYNC_MOINTOR_CONDVAR_H__

#include <sem.h>
/* In [OS CONCEPT] 7.7 section, the accurate define and approximate implementation of MONITOR was introduced.
 * INTRODUCTION:
 *  Monitors were invented by C. A. R. Hoare and Per Brinch Hansen, and were first implemented in Brinch Hansen's
 *  Concurrent Pascal language. Generally, a monitor is a language construct and the compiler usually enforces mutual exclusion. Compare this with semaphores, which are usually an OS construct.
 * DEFNIE & CHARACTERISTIC:
 *  A monitor is a collection of procedures, variables, and data structures grouped together.
 *  Processes can call the monitor procedures but cannot access the internal data structures.
 *  Only one process at a time may be be active in a monitor.
 *  Condition variables allow for blocking and unblocking.
 *     cv.wait() blocks a process.
 *        The process is said to be waiting for (or waiting on) the condition variable cv.
 *     cv.signal() (also called cv.notify) unblocks a process waiting for the condition variable cv.
 *        When this occurs, we need to still require that only one process is active in the monitor. This can be done in several ways:
 *            on some systems the old process (the one executing the signal) leaves the monitor and the new one enters
 *            on some systems the signal must be the last statement executed inside the monitor.
 *            on some systems the old process will block until the monitor is available again.
 *            on some systems the new process (the one unblocked by the signal) will remain blocked until the monitor is available again.
 *   If a condition variable is signaled with nobody waiting, the signal is lost. Compare this with semaphores, in which a signal will allow a process that executes a wait in the future to no block.
 *   You should not think of a condition variable as a variable in the traditional sense.
 *     It does not have a value.
 *     Think of it as an object in the OOP sense.
 *     It has two methods, wait and signal that manipulate the calling process.
 * IMPLEMENTATION:
 *   monitor mt {
 *     ----------------variable------------------
 *     semaphore mutex;
 *     semaphore next;
 *     int next_count;
 *     condvar {int count, sempahore sem}  cv[N];
 *     other variables in mt;
 *     --------condvar wait/signal---------------
 *     cond_wait (cv) {
 *         cv.count ++;
 *         if(mt.next_count>0)
 *            signal(mt.next)
 *         else
 *            signal(mt.mutex);
 *         wait(cv.sem);
 *         cv.count --;
 *      }
 *
 *      cond_signal(cv) {
 *          if(cv.count>0) {
 *             mt.next_count ++;
 *             signal(cv.sem);
 *             wait(mt.next);
 *             mt.next_count--;
 *          }
 *       }
 *     --------routines in monitor---------------
 *     routineA_in_mt () {
 *        wait(mt.mutex);
 *        ...
 *        real body of routineA
 *        ...
 *        if(next_count>0)
 *            signal(mt.next);
 *        else
 *            signal(mt.mutex);
 *     }
 */

typedef struct monitor monitor_t;                // 前向声明monitor_t结构体

typedef struct condvar{                           // 条件变量结构体定义
    semaphore_t sem;                              // 信号量：用于阻塞等待进程，信号进程应唤醒等待进程
    int count;                                    // 计数器：在该条件变量上等待的进程数量
    monitor_t * owner;                            // 指针：指向拥有此条件变量的管程
} condvar_t;                                      // 条件变量类型

typedef struct monitor{                           // 管程结构体定义
    semaphore_t mutex;                            // 互斥信号量：用于进入管程例程，应初始化为1
    semaphore_t next;                             // next信号量：用于阻塞信号进程自身，被唤醒的等待进程应唤醒睡眠的信号进程
    int next_count;                               // 计数器：在next上睡眠的信号进程数量
    condvar_t *cv;                                // 指针：指向管程中的条件变量数组
} monitor_t;                                      // 管程类型

// 初始化管程中的变量
void     monitor_init (monitor_t *cvp, size_t num_cv);
// 释放管程中的变量
void     monitor_free (monitor_t *cvp, size_t num_cv);
// 解锁条件变量上等待的一个线程
void     cond_signal (condvar_t *cvp);
// 将调用线程挂起在条件变量上等待条件，原子地解锁管程中的mutex，
// 并在唤醒后锁住mutex，将调用线程挂起在条件变量上
void     cond_wait (condvar_t *cvp);
     
#endif /* !__KERN_SYNC_MONITOR_CONDVAR_H__ */
