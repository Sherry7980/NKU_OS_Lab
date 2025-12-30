// sync.h：提供关中断的原子操作原语，保护临界区
#ifndef __KERN_SYNC_SYNC_H__
#define __KERN_SYNC_SYNC_H__

#include <defs.h>
#include <intr.h>
#include <sched.h>
#include <riscv.h>
#include <assert.h>
#include <atomic.h>

static inline bool __intr_save(void) {           // 静态内联函数：保存中断状态并禁用中断
    if (read_csr(sstatus) & SSTATUS_SIE) {       // 读取sstatus寄存器，检查SIE位是否被设置（中断是否启用）
        intr_disable();                          // 调用函数禁用中断
        return 1;                                // 返回1表示原本中断是启用的
    }
    return 0;                                    // 返回0表示原本中断是禁用的
}

static inline void __intr_restore(bool flag) {   // 静态内联函数：恢复中断状态
    if (flag) {                                  // 如果flag为真（原本中断是启用的）
        intr_enable();                           // 调用函数启用中断
    }
}

#define local_intr_save(x)      do { x = __intr_save(); } while (0)  // 宏：保存中断状态到变量x
#define local_intr_restore(x)   __intr_restore(x);                   // 宏：从变量x恢复中断状态

#endif /* !__KERN_SYNC_SYNC_H__ */

