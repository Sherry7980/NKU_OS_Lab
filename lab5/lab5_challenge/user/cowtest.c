// user/cowtest.c
#include <stdio.h>
#include <ulib.h>

#define TEST_SIZE 10

int main(void) {
    cprintf("COW Test Starting...\n");
    
    static int data[TEST_SIZE];   // 测试数据结构，10个int = 40字节，通常一个页面4KB，data数组只占很小部分
    
    for (int i = 0; i < TEST_SIZE; i++) {   //父进程初始化数组
        data[i] = i * 100;   // [0, 100, 200, ..., 900]
    }
    cprintf("Parent: initialized data\n");
    // 此时：
    // 物理页A: [0, 100, 200, 300, 400, 500, 600, 700, 800, 900, ...]
    // 父进程PTE: 指向物理页A，有写权限(W=1)
    
    int pid = fork();   // COW机制在这里生效，fork()函数是系统调用，创建子进程
    
    // 物理页A: [0, 100, 200, ..., 900]  ← 被两个进程共享
    //          ↗                  ↖
    // 父进程PTE(W=1)         子进程PTE(W=0, COW=1）
    // 引用计数：page.ref = 2
    
    if (pid == 0) { //OS内核硬性保证父进程 pid > 0，子进程 pid == 0，如果出错则 pid < 0
        // 子进程: 只读操作，不触发COW
        cprintf("Child: reading parent's data...\n");
        int sum = 0;
        for (int i = 0; i < TEST_SIZE; i++) {
            sum += data[i];   // 只是读取，页表项W=0但R=1，允许读取
        }
        // sum = 0+100+200+...+900 = 4500 ✓
        cprintf("Child: sum before write = %d\n", sum);
        
        if (sum != 4500) {
            cprintf("Child: ERROR - sum should be 4500\n");
            exit(-1);
        }
        
        // 子进程写入操作 - 触发COW
        cprintf("Child: writing data (trigger COW)...\n");
        for (int i = 0; i < TEST_SIZE; i++) {
            data[i] = i * 200;
        }
        /*
        1. 子进程执行：data[0] = 0 * 200 = 0
        2. CPU检测：页表项PTE_W=0，无写权限
        3. 触发页面错误（Page Fault）
        4. 缺页处理程序检查：PTE_COW=1 → 是COW页面
        5. 执行COW处理：
           a. 分配新物理页B
           b. 复制A的内容到B
           c. 更新子进程PTE指向B，设置W=1，清除COW
           d. 原页面A引用计数减为1
        6. 恢复执行，写入成功
        */
        /*
        写入后的内存状态：
        物理页A: [0, 100, 200, ..., 900]    ← 仅父进程使用，ref=1
        物理页B: [0, 200, 400, ..., 1800]   ← 子进程独享，ref=1
        */
        
        // 再次读取，求和验证子进程的写入结果
        sum = 0;
        for (int i = 0; i < TEST_SIZE; i++) {
            sum += data[i];
        }
        // sum = 0+200+400+...+1800 = 9000 ✓
        cprintf("Child: sum after write = %d\n", sum);
        
        if (sum != 9000) {
            cprintf("Child: ERROR - sum should be 9000\n");
            exit(-2);
        }
        
        exit(0);
    } else if (pid > 0) {
        int exit_code = 0;
        waitpid(pid, &exit_code);  // 父进程等待子进程结束
         
        if (exit_code == 0) {
            cprintf("Child completed successfully\n");
        } else {
            cprintf("Child failed with code %d\n", exit_code);
        }
        
        cprintf("Parent: checking data after child...\n");
        // 验证父进程的数据未受影响
        int sum = 0;
        for (int i = 0; i < TEST_SIZE; i++) {
            sum += data[i];   // 读取的是物理页A，原始数据
        }
        // sum = 0+100+200+...+900 = 4500 ✓
        cprintf("Parent: sum = %d (should be 4500)\n", sum);
        
        if (sum == 4500 && exit_code == 0) {
            cprintf("COW Test PASSED!\n");
        } else {
            cprintf("COW Test FAILED!\n");
        }
    } else {
        cprintf("fork failed\n");
        return -1;
    }
    
    return 0;
}