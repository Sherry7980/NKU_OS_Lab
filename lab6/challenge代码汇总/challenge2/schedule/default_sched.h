#ifndef __KERN_SCHEDULE_SCHED_RR_H__
#define __KERN_SCHEDULE_SCHED_RR_H__

#include <sched.h>

extern struct sched_class default_sched_class;
extern struct sched_class stride_sched_class;
extern struct sched_class fifo_sched_class;    // FIFO (新增)
extern struct sched_class sjf_sched_class;     // SJF (新增)
extern struct sched_class fp_sched_class;      // Fixed Priority (新增)

#endif /* !__KERN_SCHEDULE_SCHED_RR_H__ */

