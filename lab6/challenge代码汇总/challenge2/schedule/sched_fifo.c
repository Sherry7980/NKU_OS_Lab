#include <defs.h>
#include <list.h>
#include <proc.h>
#include <assert.h>
#include <default_sched.h>

/*
 * FIFO_init: 初始化运行队列
 */
static void
FIFO_init(struct run_queue *rq) {
    list_init(&(rq->run_list));
    rq->proc_num = 0;
}

/*
 * FIFO_enqueue: 将进程加入队列尾部
 */
static void
FIFO_enqueue(struct run_queue *rq, struct proc_struct *proc) {
    assert(list_empty(&(proc->run_link)));
    list_add_before(&(rq->run_list), &(proc->run_link));
    proc->rq = rq;
    rq->proc_num ++;
}

/*
 * FIFO_dequeue: 将进程从队列中移除
 */
static void
FIFO_dequeue(struct run_queue *rq, struct proc_struct *proc) {
    assert(!list_empty(&(proc->run_link)) && proc->rq == rq);
    list_del_init(&(proc->run_link));
    rq->proc_num --;
}

/*
 * FIFO_pick_next: 选择队头进程
 */
static struct proc_struct *
FIFO_pick_next(struct run_queue *rq) {
    list_entry_t *le = list_next(&(rq->run_list));
    if (le != &(rq->run_list)) {
        return le2proc(le, run_link);
    }
    return NULL;
}

/*
 * FIFO_proc_tick: 
 * FIFO 是非抢占式的 (Non-preemptive)。
 * 即使时间片耗尽，我们也不设置 need_resched，直到进程执行完毕或主动 yield。
 */
static void
FIFO_proc_tick(struct run_queue *rq, struct proc_struct *proc) {
    // 这里的逻辑可以保留为空，或者仅用于统计时间
    // 关键点：不要设置 proc->need_resched = 1
}

struct sched_class fifo_sched_class = {
    .name = "FIFO_scheduler",
    .init = FIFO_init,
    .enqueue = FIFO_enqueue,
    .dequeue = FIFO_dequeue,
    .pick_next = FIFO_pick_next,
    .proc_tick = FIFO_proc_tick,
};