// user/dirtycow_test.c
#include <stdio.h>
#include <ulib.h>
#include <string.h>

int main(void) {
    cprintf("DirtyCOW vulnerability test\n");
    
    // 使用静态数组代替动态分配，确保在一个页面内
    static char data[4096];
    
    // 初始化数据
    const char *original = "ORIGINAL DATA";
    for (int i = 0; original[i] != '\0'; i++) {
        data[i] = original[i];
    }
    data[13] = '\0';  // 确保字符串结束
    // 现在：data[] = "ORIGINAL DATA"
    // 物理页面P: 包含这个字符串，父进程有写权限
    
    // fork创建子进程
    int pid = fork(); 
    // fork后：父子共享页面P
    // 父进程PTE: W=1
    // 子进程PTE: W=0, COW=1
    
    if (pid == 0) {
        // 子进程尝试多次写入，触发竞态条件
        for (int i = 0; i < 100; i++) {
            data[0] = 'M';  // 触发COW
        }
/*
潜在竞态场景时间线：
t0: 子进程第一次写入 → 触发COW
    CPU: 检测W=0 → 触发缺页 → 进入内核处理
t1: 内核开始COW处理：
    1. 获取原页面锁
    2. 分配新页面Q
    3. 复制P→Q
    4. 更新子进程PTE指向Q
    5. 释放原页面锁
t2: 子进程第二次写入（循环中）
    如果发生在t1的步骤4之前：
    - 可能还在使用旧的映射（指向P）
    - 但内核认为正在处理COW
    - 可能导致未定义行为
*/
        
        // 检查是否修改成功
        if (data[0] == 'M') {
            cprintf("Child: data modified (expected behavior)\n");
        }
        
        exit(0);
    } else if (pid > 0) {
        int exit_code = 0;
        waitpid(pid, &exit_code);  // 等待子进程结束
        
        // 父进程检查数据是否被破坏
        int is_original = 1;
        for (int i = 0; original[i] != '\0'; i++) {
            if (data[i] != original[i]) {
                is_original = 0;  // 数据被破坏
                break;
            }
        }
        
        if (is_original) {
            cprintf("Test completed - no corruption should occur\n");
        } else {
            cprintf("ERROR: parent data corrupted!\n");
        }
    } else {
        cprintf("fork failed\n");
        return -1;
    }
    
    return 0;
}