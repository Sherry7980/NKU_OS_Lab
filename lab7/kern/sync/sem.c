#include <defs.h>                               
#include <wait.h>                               
#include <atomic.h>                            
#include <kmalloc.h>                         
#include <sem.h>                             
#include <proc.h>                                
#include <sync.h>                                
#include <assert.h>                             

void
sem_init(semaphore_t *sem, int value) {          // 初始化信号量
    sem->value = value;                          // 设置信号量初始值
    wait_queue_init(&(sem->wait_queue));         // 初始化信号量的等待队列
}

static __noinline void __up(semaphore_t *sem, uint32_t wait_state) { // 内部up函数
    bool intr_flag;                              // 中断状态标志
    local_intr_save(intr_flag);                  // 保存中断状态并禁用中断，开始临界区
    {
        wait_t *wait;                            // 等待项指针
        if ((wait = wait_queue_first(&(sem->wait_queue))) == NULL) { // 检查等待队列是否为空
            sem->value ++;                       // 无等待进程，增加信号量值
        }
        else {                                   // 有进程在等待队列中
            assert(wait->proc->wait_state == wait_state); // 断言验证等待状态匹配
            wakeup_wait(&(sem->wait_queue), wait, wait_state, 1); // 唤醒第一个等待进程
        }
    }
    local_intr_restore(intr_flag);               // 恢复中断状态，结束临界区
}

static __noinline uint32_t __down(semaphore_t *sem, uint32_t wait_state) { // 内部down函数
    bool intr_flag;                              // 中断状态标志
    local_intr_save(intr_flag);                  // 保存中断状态并禁用中断，开始临界区
    if (sem->value > 0) {                        // 检查信号量值是否大于0
        sem->value --;                           // 减少信号量值
        local_intr_restore(intr_flag);           // 恢复中断状态
        return 0;                                // 返回0表示成功获取资源
    }
    wait_t __wait, *wait = &__wait;              // 在栈上分配等待项
    wait_current_set(&(sem->wait_queue), wait, wait_state); // 设置当前进程等待状态并加入队列
    local_intr_restore(intr_flag);               // 恢复中断状态，允许中断

    schedule();                                  // 调度其他进程，当前进程进入睡眠

    local_intr_save(intr_flag);                  // 保存中断状态并禁用中断
    wait_current_del(&(sem->wait_queue), wait);  // 从等待队列中删除当前进程
    local_intr_restore(intr_flag);               // 恢复中断状态

    if (wait->wakeup_flags != wait_state) {      // 检查唤醒标志是否与预期等待状态相同
        return wait->wakeup_flags;               // 返回非零值表示异常唤醒
    }
    return 0;                                    // 返回0表示正常唤醒
}

void
up(semaphore_t *sem) {                           // 公开的up函数（V操作）
    __up(sem, WT_KSEM);                          // 调用内部函数，WT_KSEM表示内核信号量等待状态
}

void
down(semaphore_t *sem) {                         // 公开的down函数（P操作）
    uint32_t flags = __down(sem, WT_KSEM);       // 调用内部函数获取唤醒标志
    assert(flags == 0);                          // 断言确保正常唤醒，非正常唤醒触发错误
}

bool
try_down(semaphore_t *sem) {                     // 尝试down操作，非阻塞版本
    bool intr_flag, ret = 0;                     // 中断标志和返回值
    local_intr_save(intr_flag);                  // 保存中断状态并禁用中断
    if (sem->value > 0) {                        // 检查信号量值是否大于0
        sem->value --, ret = 1;                  // 减少信号量值，设置返回值为1表示成功
    }
    local_intr_restore(intr_flag);               // 恢复中断状态
    return ret;                                  // 返回操作结果：1成功，0失败
}
