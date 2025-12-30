// wait.c/wait.h：等待队列操作实现，用于进程阻塞和唤醒
#include <defs.h>
#include <list.h>
#include <sync.h>
#include <wait.h>
#include <proc.h>

void // 初始化函数
wait_init(wait_t *wait, struct proc_struct *proc) {
    wait->proc = proc;
    wait->wakeup_flags = WT_INTERRUPTED;  // 默认被中断唤醒，确保未设置正确标志时不会误判
    list_init(&(wait->wait_link));        // 初始化链表节点
}

void 
wait_queue_init(wait_queue_t *queue) {
    list_init(&(queue->wait_head));       // 初始化等待队列的链表头
}

void // 等待队列管理
wait_queue_add(wait_queue_t *queue, wait_t *wait) {
    assert(list_empty(&(wait->wait_link)) && wait->proc != NULL);  // 确保等待项未在其他队列中
    wait->wait_queue = queue;                                      // 设置等待项所属队列
    list_add_before(&(queue->wait_head), &(wait->wait_link));      // 在队列头部之前插入，实现FIFO
}

void
wait_queue_del(wait_queue_t *queue, wait_t *wait) {
    assert(!list_empty(&(wait->wait_link)) && wait->wait_queue == queue);  // 验证等待项在队列中且队列正确
    list_del_init(&(wait->wait_link));                                     // 从队列中删除等待项并重新初始化其链表节点
}

wait_t *
wait_queue_next(wait_queue_t *queue, wait_t *wait) {
    assert(!list_empty(&(wait->wait_link)) && wait->wait_queue == queue);  // 验证等待项在队列中且队列正确
    list_entry_t *le = list_next(&(wait->wait_link));                      // 获取等待项链表节点的下一个节点
    if (le != &(queue->wait_head)) {            // 如果下一个节点不是队列头
        return le2wait(le, wait_link);          // 将链表节点转换为wait_t结构体指针
    }
    return NULL;          // 已到队列末尾，返回NULL
}

wait_t *
wait_queue_prev(wait_queue_t *queue, wait_t *wait) {
    assert(!list_empty(&(wait->wait_link)) && wait->wait_queue == queue); // 验证等待项在队列中且队列正确
    list_entry_t *le = list_prev(&(wait->wait_link));   // 获取等待项链表节点的上一个节点
    if (le != &(queue->wait_head)) {                    // 如果上一个节点不是队列头
        return le2wait(le, wait_link);                  // 将链表节点转换为wait_t结构体指针
    }
    return NULL;                                        // 已到队列开头，返回NULL
}

wait_t *
wait_queue_first(wait_queue_t *queue) {
    list_entry_t *le = list_next(&(queue->wait_head));  // 获取队列头的下一个节点
    if (le != &(queue->wait_head)) {                    // 如果下一个节点不是队列头自身
        return le2wait(le, wait_link);                  // 将链表节点转换为wait_t结构体指针
    }
    return NULL;                                        // 队列为空，返回NULL
}

wait_t *
wait_queue_last(wait_queue_t *queue) {
    list_entry_t *le = list_prev(&(queue->wait_head)); // 获取队列头的上一个节点
    if (le != &(queue->wait_head)) {                   // 如果上一个节点不是队列头自身
        return le2wait(le, wait_link);                 // 将链表节点转换为wait_t结构体指针
    }
    return NULL;                                       // 队列为空，返回NULL
}

bool wait_queue_empty(wait_queue_t *queue) {
    return list_empty(&(queue->wait_head));     // 检查队列头是否指向自身，判断队列是否为空
}

bool wait_in_queue(wait_t *wait) {
    return !list_empty(&(wait->wait_link));     // 检查等待项的链表节点是否在链表中
}

void wakeup_wait(wait_queue_t *queue, wait_t *wait, uint32_t wakeup_flags, bool del) {
    if (del) {                                   // 如果需要从队列中删除
        wait_queue_del(queue, wait);             // 从等待队列中删除该等待项
    }
    wait->wakeup_flags = wakeup_flags;           // 设置等待项的唤醒标志
    wakeup_proc(wait->proc);                     // 唤醒关联的进程
}

void wakeup_first(wait_queue_t *queue, uint32_t wakeup_flags, bool del) {
    wait_t *wait;           // 声明等待项指针
    if ((wait = wait_queue_first(queue)) != NULL) {  // 获取队列第一个等待项
        wakeup_wait(queue, wait, wakeup_flags, del); // 唤醒该等待项关联的进程
    }
}

void wakeup_queue(wait_queue_t *queue, uint32_t wakeup_flags, bool del) {
    wait_t *wait;          // 声明等待项指针
    if ((wait = wait_queue_first(queue)) != NULL) {  // 获取队列第一个等待项
        if (del) {         // 如果需要从队列中删除
            do {
                wakeup_wait(queue, wait, wakeup_flags, 1); // 唤醒并删除当前等待项
            } while ((wait = wait_queue_first(queue)) != NULL); // 循环直到队列为空
        }
        else {             // 如果不从队列中删除
            do {
                wakeup_wait(queue, wait, wakeup_flags, 0); // 唤醒但不删除当前等待项
                wait = wait_queue_next(queue, wait);       // 获取下一个等待项
            } while (wait != NULL);                        // 循环直到队列末尾
        }
    }
}

void wait_current_set(wait_queue_t *queue, wait_t *wait, uint32_t wait_state) {
    assert(current != NULL);                      // 验证当前进程指针非空
    wait_init(wait, current);                     // 初始化等待项关联当前进程
    current->state = PROC_SLEEPING;               // 设置当前进程状态为睡眠
    current->wait_state = wait_state;             // 设置当前进程的等待状态
    wait_queue_add(queue, wait);                  // 将等待项添加到等待队列
}
