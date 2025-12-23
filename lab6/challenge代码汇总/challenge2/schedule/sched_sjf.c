#include <defs.h>
#include <list.h>
#include <proc.h>
#include <assert.h>
#include <default_sched.h>

/*
 * SJF_init: 初始化
 */
static void
SJF_init(struct run_queue *rq) {
    list_init(&(rq->run_list));
    rq->proc_num = 0;
}

/*
 * SJF_enqueue: 将进程按 estimated_time (lab6_priority) 从小到大插入队列
 * 越小的 lab6_priority 代表估计运行时间越短，应当排在前面
 */
static void
SJF_enqueue(struct run_queue *rq, struct proc_struct *proc) {
    assert(list_empty(&(proc->run_link)));
    
    list_entry_t *le = list_next(&(rq->run_list));
    while (le != &(rq->run_list)) {
        struct proc_struct *next = le2proc(le, run_link);
        // 如果当前进程的估计时间 < 队列中进程的估计时间，则插入到该进程前面
        if (proc->lab6_priority < next->lab6_priority) {
            break;
        }
        le = list_next(le);
    }
    
    list_add_before(le, &(proc->run_link));
    proc->rq = rq;
    rq->proc_num ++;
}

/*
 * SJF_dequeue: 移除进程
 */
static void
SJF_dequeue(struct run_queue *rq, struct proc_struct *proc) {
    assert(!list_empty(&(proc->run_link)) && proc->rq == rq);
    list_del_init(&(proc->run_link));
    rq->proc_num --;
}

/*
 * SJF_pick_next: 总是选择队头 (时间最短的)
 */
static struct proc_struct *
SJF_pick_next(struct run_queue *rq) {
    list_entry_t *le = list_next(&(rq->run_list));
    if (le != &(rq->run_list)) {
        return le2proc(le, run_link);
    }
    return NULL;
}

/*
 * SJF_proc_tick: 非抢占式
 */
static void
SJF_proc_tick(struct run_queue *rq, struct proc_struct *proc) {
    // SJF 通常是非抢占的，让短作业一口气跑完
    // 如果要实现 SRTF (Shortest Remaining Time First)，这里需要检查
    // 是否有新进程比当前进程剩余时间更短。但在本框架下，简单 SJF 即可。
}

struct sched_class sjf_sched_class = {
    .name = "SJF_scheduler",
    .init = SJF_init,
    .enqueue = SJF_enqueue,
    .dequeue = SJF_dequeue,
    .pick_next = SJF_pick_next,
    .proc_tick = SJF_proc_tick,
};