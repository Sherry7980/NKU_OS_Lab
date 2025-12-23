#include <defs.h>
#include <list.h>
#include <proc.h>
#include <assert.h>
#include <default_sched.h>

/* Fixed Priority: 总是选择优先级(lab6_priority)最高的进程 */

static void FP_init(struct run_queue *rq) {
    list_init(&(rq->run_list));
    rq->proc_num = 0;
}

static void FP_enqueue(struct run_queue *rq, struct proc_struct *proc) {
    assert(list_empty(&(proc->run_link)));
    list_add_before(&(rq->run_list), &(proc->run_link));
    proc->rq=rq;
    rq->proc_num++;
}

static void FP_dequeue(struct run_queue *rq, struct proc_struct *proc) {
    assert(!list_empty(&(proc->run_link)) && proc->rq == rq);
    list_del_init(&(proc->run_link));
    rq->proc_num--;
}

static struct proc_struct *FP_pick_next(struct run_queue *rq) {
    list_entry_t *le = list_next(&(rq->run_list));
    if (le == &(rq->run_list)) return NULL;

    struct proc_struct *max_p = NULL;
    uint32_t max_priority = 0;

    // 遍历队列，寻找优先级最高的进程
    while (le != &(rq->run_list)) {
        struct proc_struct *p = le2proc(le, run_link);
        if (max_p == NULL || p->lab6_priority > max_priority) {
            max_p = p;
            max_priority = p->lab6_priority;
        }
        le = list_next(le);
    }
    return max_p;
}

static void FP_proc_tick(struct run_queue *rq, struct proc_struct *proc) {
    if (proc == idleproc) {
        proc->need_resched = 1;
        return;
    }
    // 抢占逻辑：如果队列里有比当前进程优先级更高的进程，则发生调度
    list_entry_t *le = list_next(&(rq->run_list));
    while (le != &(rq->run_list)) {
        struct proc_struct *p = le2proc(le, run_link);
        if (p->lab6_priority > proc->lab6_priority) {
            proc->need_resched = 1;
            return;
        }
        le = list_next(le);
    }
}

struct sched_class fp_sched_class = {
    .name = "FP_scheduler",
    .init = FP_init,
    .enqueue = FP_enqueue,
    .dequeue = FP_dequeue,
    .pick_next = FP_pick_next,
    .proc_tick = FP_proc_tick,
};