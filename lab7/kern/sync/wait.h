// wait.c/wait.h：等待队列数据结构定义
#ifndef __KERN_SYNC_WAIT_H__
#define __KERN_SYNC_WAIT_H__

#include <list.h>

typedef struct {
    list_entry_t wait_head;   // 双向链表头
} wait_queue_t;

struct proc_struct;

typedef struct {
    struct proc_struct *proc;  // 等待的进程
    uint32_t wakeup_flags;     // 唤醒标志（记录进程被唤醒的原因）
    wait_queue_t *wait_queue;  // 所属等待队列
    list_entry_t wait_link;    // 链表链接
} wait_t;

#define le2wait(le, member)         \
    to_struct((le), wait_t, member)   // 这个宏通过链表节点地址反推出包含它的 wait_t 结构体地址

void wait_init(wait_t *wait, struct proc_struct *proc);
void wait_queue_init(wait_queue_t *queue);
void wait_queue_add(wait_queue_t *queue, wait_t *wait);
void wait_queue_del(wait_queue_t *queue, wait_t *wait);

wait_t *wait_queue_next(wait_queue_t *queue, wait_t *wait);
wait_t *wait_queue_prev(wait_queue_t *queue, wait_t *wait);
wait_t *wait_queue_first(wait_queue_t *queue);
wait_t *wait_queue_last(wait_queue_t *queue);

bool wait_queue_empty(wait_queue_t *queue);
bool wait_in_queue(wait_t *wait);
void wakeup_wait(wait_queue_t *queue, wait_t *wait, uint32_t wakeup_flags, bool del);
void wakeup_first(wait_queue_t *queue, uint32_t wakeup_flags, bool del);
void wakeup_queue(wait_queue_t *queue, uint32_t wakeup_flags, bool del);

void wait_current_set(wait_queue_t *queue, wait_t *wait, uint32_t wait_state);

#define wait_current_del(queue, wait)                                       \
    do {                                                                    \
        if (wait_in_queue(wait)) {                                          \
            wait_queue_del(queue, wait);                                    \
        }                                                                   \
    } while (0)

#endif /* !__KERN_SYNC_WAIT_H__ */

