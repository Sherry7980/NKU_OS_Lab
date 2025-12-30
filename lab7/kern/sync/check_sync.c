#include <stdio.h>                               // 标准输入输出
#include <proc.h>                                // 进程相关
#include <sem.h>                                 // 信号量相关
#include <monitor.h>                             // 管程相关
#include <assert.h>                              // 断言

#define N 5                                      // 哲学家数目
#define LEFT (i-1+N)%N                           // i的左邻号码
#define RIGHT (i+1)%N                            // i的右邻号码
#define THINKING 0                               // 哲学家正在思考
#define HUNGRY 1                                 // 哲学家想取得叉子
#define EATING 2                                 // 哲学家正在吃面
#define TIMES  4                                 // 吃4次饭
#define SLEEP_TIME 10                            // 睡眠时间

//---------- philosophers problem using semaphore ----------------------
int state_sema[N];                               // 记录每个人状态的数组（信号量方案）
semaphore_t mutex;                               // 临界区互斥信号量
semaphore_t s[N];                                // 每个哲学家一个信号量

struct proc_struct *philosopher_proc_sema[N];    // 哲学家进程控制块指针数组（信号量方案）

void phi_test_sema(int i)                        // 测试哲学家i是否能进餐（信号量方案）
{ 
    if(state_sema[i]==HUNGRY&&state_sema[LEFT]!=EATING
            &&state_sema[RIGHT]!=EATING)         // 如果哲学家i饥饿且左右邻居都不在进餐
    {
        state_sema[i]=EATING;                    // 设置哲学家i状态为进餐
        up(&s[i]);                               // 唤醒哲学家i的信号量
    }
}

void phi_take_forks_sema(int i)                  // 哲学家i尝试拿叉子（信号量方案）
{ 
        down(&mutex);                            // 进入临界区
        state_sema[i]=HUNGRY;                    // 记录下哲学家i饥饿的事实
        phi_test_sema(i);                        // 试图得到两只叉子
        up(&mutex);                              // 离开临界区
        down(&s[i]);                             // 如果得不到叉子就阻塞
}

void phi_put_forks_sema(int i)                   // 哲学家i放下叉子（信号量方案）
{ 
        down(&mutex);                            // 进入临界区
        state_sema[i]=THINKING;                  // 哲学家进餐结束
        phi_test_sema(LEFT);                     // 看一下左邻居现在是否能进餐
        phi_test_sema(RIGHT);                    // 看一下右邻居现在是否能进餐
        up(&mutex);                              // 离开临界区
}

int philosopher_using_semaphore(void * arg)      // 哲学家线程函数（信号量方案）
{
    int i, iter=0;                               // i：哲学家编号，iter：迭代次数
    i=(int)arg;                                  // 从参数获取哲学家编号
    cprintf("I am No.%d philosopher_sema\n",i);  // 打印哲学家信息
    while(iter++<TIMES)                          // 循环执行TIMES次
    { 
        cprintf("Iter %d, No.%d philosopher_sema is thinking\n",iter,i); // 思考状态
        do_sleep(SLEEP_TIME);                    // 模拟思考时间
        phi_take_forks_sema(i);                  // 尝试拿叉子
        cprintf("Iter %d, No.%d philosopher_sema is eating\n",iter,i); // 进餐状态
        do_sleep(SLEEP_TIME);                    // 模拟进餐时间
        phi_put_forks_sema(i);                   // 放下叉子
    }
    cprintf("No.%d philosopher_sema quit\n",i);  // 哲学家退出
    return 0;    
}

struct proc_struct *philosopher_proc_condvar[N]; // 哲学家进程控制块指针数组（管程方案）
int state_condvar[N];                            // 哲学家状态数组（管程方案）
monitor_t mt, *mtp=&mt;                          // 管程实例和指针

void phi_test_condvar (int i)                    // 测试哲学家i是否能进餐（管程方案）
{ 
    if(state_condvar[i]==HUNGRY&&state_condvar[LEFT]!=EATING
            &&state_condvar[RIGHT]!=EATING)      // 如果哲学家i饥饿且左右邻居都不在进餐
    {
        cprintf("phi_test_condvar: state_condvar[%d] will eating\n",i); // 调试信息
        state_condvar[i] = EATING ;              // 设置哲学家i状态为进餐
        cprintf("phi_test_condvar: signal self_cv[%d] \n",i); // 调试信息
        cond_signal(&mtp->cv[i]) ;               // 发送信号给条件变量
    }
}

void phi_take_forks_condvar(int i) {
     down(&(mtp->mutex));   // 进入管程
//--------into routine in monitor--------------
     // LAB7 EXERCISE1: YOUR CODE
     // I am hungry
     // try to get fork
     
     // 记录哲学家 i 饥饿的事实
     state_condvar[i] = HUNGRY;
     
     // 尝试获取两把叉子
     phi_test_condvar(i);
     
     // 如果获取失败，则等待条件变量
     while (state_condvar[i] != EATING) {
         cprintf("phi_take_forks_condvar: %d didn't get fork and will wait\n", i);
         cond_wait(&mtp->cv[i]);
     }
    
//--------leave routine in monitor--------------
    if(mtp->next_count>0)                       // 如果有信号进程在等待
        up(&(mtp->next));                       // 唤醒一个信号进程
    else                                        // 如果没有信号进程等待
        up(&(mtp->mutex));                      // 释放管程互斥锁
}

void phi_put_forks_condvar(int i) {
     down(&(mtp->mutex));      // 进入管程

//--------into routine in monitor--------------
     // LAB7 EXERCISE1: YOUR CODE
     // I ate over
     // test left and right neighbors
     
     // 哲学家 i 吃完，进入思考状态
     state_condvar[i] = THINKING;
     
     // 测试左邻居是否能进餐
     phi_test_condvar(LEFT);
     
     // 测试右邻居是否能进餐
     phi_test_condvar(RIGHT);
    
//--------leave routine in monitor--------------
    if(mtp->next_count>0)                       // 如果有信号进程在等待
        up(&(mtp->next));                       // 唤醒一个信号进程
    else                                        // 如果没有信号进程等待
        up(&(mtp->mutex));                      // 释放管程互斥锁
}

//---------- philosophers using monitor (condition variable) ----------------------
int philosopher_using_condvar(void * arg)        // 哲学家线程函数（管程方案）
{ 
    int i, iter=0;                               // i：哲学家编号，iter：迭代次数
    i=(int)arg;                                  // 从参数获取哲学家编号
    cprintf("I am No.%d philosopher_condvar\n",i); // 打印哲学家信息
    while(iter++<TIMES)                          // 循环执行TIMES次
    { 
        cprintf("Iter %d, No.%d philosopher_condvar is thinking\n",iter,i); // 思考状态
        do_sleep(SLEEP_TIME);                    // 模拟思考时间
        phi_take_forks_condvar(i);               // 尝试拿叉子
        cprintf("Iter %d, No.%d philosopher_condvar is eating\n",iter,i); // 进餐状态
        do_sleep(SLEEP_TIME);                    // 模拟进餐时间
        phi_put_forks_condvar(i);                // 放下叉子
    }
    cprintf("No.%d philosopher_condvar quit\n",i); // 哲学家退出
    return 0;    
}

void check_sync(void)                            // 主测试函数
{
    int i, pids[N];                              // 循环计数器，进程ID数组

    //check semaphore                            // 测试信号量方案
    sem_init(&mutex, 1);                         // 初始化互斥信号量
    for(i=0;i<N;i++){                            // 初始化每个哲学家的信号量
        sem_init(&s[i], 0);                      // 初始化哲学家i的信号量
        int pid = kernel_thread(philosopher_using_semaphore, (void *)i, 0); // 创建哲学家线程
        if (pid <= 0) {                          // 如果创建失败
            panic("create No.%d philosopher_using_semaphore failed.\n"); // 触发panic
        }
        pids[i] = pid;                           // 保存进程ID
        philosopher_proc_sema[i] = find_proc(pid); // 查找进程控制块
        set_proc_name(philosopher_proc_sema[i], "philosopher_sema_proc"); // 设置进程名称
    }
    for (i=0;i<N;i++)                            // 等待所有哲学家线程结束
        assert(do_wait(pids[i],NULL) == 0);      // 断言等待成功

    //check condition variable                   // 测试管程方案
    monitor_init(&mt, N);                        // 初始化管程
    for(i=0;i<N;i++){                            // 初始化每个哲学家状态
        state_condvar[i]=THINKING;               // 设置初始状态为思考
        int pid = kernel_thread(philosopher_using_condvar, (void *)i, 0); // 创建哲学家线程
        if (pid <= 0) {                          // 如果创建失败
            panic("create No.%d philosopher_using_condvar failed.\n"); // 触发panic
        }
        pids[i] = pid;                           // 保存进程ID
        philosopher_proc_condvar[i] = find_proc(pid); // 查找进程控制块
        set_proc_name(philosopher_proc_condvar[i], "philosopher_condvar_proc"); // 设置进程名称
    }
    for (i=0;i<N;i++)                            // 等待所有哲学家线程结束
        assert(do_wait(pids[i],NULL) == 0);      // 断言等待成功
    monitor_free(&mt, N);                        // 释放管程资源
}