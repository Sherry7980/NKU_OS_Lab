
obj/__user_sleep.out:     file format elf64-littleriscv


Disassembly of section .text:

0000000000800020 <_start>:
    # move down the esp register
    # since it may cause page fault in backtrace
    // subl $0x20, %esp

    # call user-program function
    call umain
  800020:	134000ef          	jal	ra,800154 <umain>
1:  j 1b
  800024:	a001                	j	800024 <_start+0x4>

0000000000800026 <__panic>:
#include <stdio.h>
#include <ulib.h>
#include <error.h>

void
__panic(const char *file, int line, const char *fmt, ...) {
  800026:	715d                	addi	sp,sp,-80
  800028:	8e2e                	mv	t3,a1
  80002a:	e822                	sd	s0,16(sp)
    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
    cprintf("user panic at %s:%d:\n    ", file, line);
  80002c:	85aa                	mv	a1,a0
__panic(const char *file, int line, const char *fmt, ...) {
  80002e:	8432                	mv	s0,a2
  800030:	fc3e                	sd	a5,56(sp)
    cprintf("user panic at %s:%d:\n    ", file, line);
  800032:	8672                	mv	a2,t3
    va_start(ap, fmt);
  800034:	103c                	addi	a5,sp,40
    cprintf("user panic at %s:%d:\n    ", file, line);
  800036:	00000517          	auipc	a0,0x0
  80003a:	5da50513          	addi	a0,a0,1498 # 800610 <main+0x70>
__panic(const char *file, int line, const char *fmt, ...) {
  80003e:	ec06                	sd	ra,24(sp)
  800040:	f436                	sd	a3,40(sp)
  800042:	f83a                	sd	a4,48(sp)
  800044:	e0c2                	sd	a6,64(sp)
  800046:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
  800048:	e43e                	sd	a5,8(sp)
    cprintf("user panic at %s:%d:\n    ", file, line);
  80004a:	058000ef          	jal	ra,8000a2 <cprintf>
    vcprintf(fmt, ap);
  80004e:	65a2                	ld	a1,8(sp)
  800050:	8522                	mv	a0,s0
  800052:	030000ef          	jal	ra,800082 <vcprintf>
    cprintf("\n");
  800056:	00000517          	auipc	a0,0x0
  80005a:	5da50513          	addi	a0,a0,1498 # 800630 <main+0x90>
  80005e:	044000ef          	jal	ra,8000a2 <cprintf>
    va_end(ap);
    exit(-E_PANIC);
  800062:	5559                	li	a0,-10
  800064:	0ce000ef          	jal	ra,800132 <exit>

0000000000800068 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
  800068:	1141                	addi	sp,sp,-16
  80006a:	e022                	sd	s0,0(sp)
  80006c:	e406                	sd	ra,8(sp)
  80006e:	842e                	mv	s0,a1
    sys_putc(c);
  800070:	0b2000ef          	jal	ra,800122 <sys_putc>
    (*cnt) ++;
  800074:	401c                	lw	a5,0(s0)
}
  800076:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
  800078:	2785                	addiw	a5,a5,1
  80007a:	c01c                	sw	a5,0(s0)
}
  80007c:	6402                	ld	s0,0(sp)
  80007e:	0141                	addi	sp,sp,16
  800080:	8082                	ret

0000000000800082 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
  800082:	1101                	addi	sp,sp,-32
  800084:	862a                	mv	a2,a0
  800086:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
  800088:	00000517          	auipc	a0,0x0
  80008c:	fe050513          	addi	a0,a0,-32 # 800068 <cputch>
  800090:	006c                	addi	a1,sp,12
vcprintf(const char *fmt, va_list ap) {
  800092:	ec06                	sd	ra,24(sp)
    int cnt = 0;
  800094:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
  800096:	136000ef          	jal	ra,8001cc <vprintfmt>
    return cnt;
}
  80009a:	60e2                	ld	ra,24(sp)
  80009c:	4532                	lw	a0,12(sp)
  80009e:	6105                	addi	sp,sp,32
  8000a0:	8082                	ret

00000000008000a2 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
  8000a2:	711d                	addi	sp,sp,-96
    va_list ap;

    va_start(ap, fmt);
  8000a4:	02810313          	addi	t1,sp,40
cprintf(const char *fmt, ...) {
  8000a8:	8e2a                	mv	t3,a0
  8000aa:	f42e                	sd	a1,40(sp)
  8000ac:	f832                	sd	a2,48(sp)
  8000ae:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
  8000b0:	00000517          	auipc	a0,0x0
  8000b4:	fb850513          	addi	a0,a0,-72 # 800068 <cputch>
  8000b8:	004c                	addi	a1,sp,4
  8000ba:	869a                	mv	a3,t1
  8000bc:	8672                	mv	a2,t3
cprintf(const char *fmt, ...) {
  8000be:	ec06                	sd	ra,24(sp)
  8000c0:	e0ba                	sd	a4,64(sp)
  8000c2:	e4be                	sd	a5,72(sp)
  8000c4:	e8c2                	sd	a6,80(sp)
  8000c6:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
  8000c8:	e41a                	sd	t1,8(sp)
    int cnt = 0;
  8000ca:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
  8000cc:	100000ef          	jal	ra,8001cc <vprintfmt>
    int cnt = vcprintf(fmt, ap);
    va_end(ap);

    return cnt;
}
  8000d0:	60e2                	ld	ra,24(sp)
  8000d2:	4512                	lw	a0,4(sp)
  8000d4:	6125                	addi	sp,sp,96
  8000d6:	8082                	ret

00000000008000d8 <syscall>:
#include <syscall.h>

#define MAX_ARGS            5

static inline int
syscall(int64_t num, ...) {
  8000d8:	7175                	addi	sp,sp,-144
  8000da:	f8ba                	sd	a4,112(sp)
    va_list ap;
    va_start(ap, num);
    uint64_t a[MAX_ARGS];
    int i, ret;
    for (i = 0; i < MAX_ARGS; i ++) {
        a[i] = va_arg(ap, uint64_t);
  8000dc:	e0ba                	sd	a4,64(sp)
  8000de:	0118                	addi	a4,sp,128
syscall(int64_t num, ...) {
  8000e0:	e42a                	sd	a0,8(sp)
  8000e2:	ecae                	sd	a1,88(sp)
  8000e4:	f0b2                	sd	a2,96(sp)
  8000e6:	f4b6                	sd	a3,104(sp)
  8000e8:	fcbe                	sd	a5,120(sp)
  8000ea:	e142                	sd	a6,128(sp)
  8000ec:	e546                	sd	a7,136(sp)
        a[i] = va_arg(ap, uint64_t);
  8000ee:	f42e                	sd	a1,40(sp)
  8000f0:	f832                	sd	a2,48(sp)
  8000f2:	fc36                	sd	a3,56(sp)
  8000f4:	f03a                	sd	a4,32(sp)
  8000f6:	e4be                	sd	a5,72(sp)
    }
    va_end(ap);

    asm volatile (
  8000f8:	4522                	lw	a0,8(sp)
  8000fa:	55a2                	lw	a1,40(sp)
  8000fc:	5642                	lw	a2,48(sp)
  8000fe:	56e2                	lw	a3,56(sp)
  800100:	4706                	lw	a4,64(sp)
  800102:	47a6                	lw	a5,72(sp)
  800104:	00000073          	ecall
  800108:	ce2a                	sw	a0,28(sp)
          "m" (a[3]),
          "m" (a[4])
        : "memory"
      );
    return ret;
}
  80010a:	4572                	lw	a0,28(sp)
  80010c:	6149                	addi	sp,sp,144
  80010e:	8082                	ret

0000000000800110 <sys_exit>:

int
sys_exit(int64_t error_code) {
  800110:	85aa                	mv	a1,a0
    return syscall(SYS_exit, error_code);
  800112:	4505                	li	a0,1
  800114:	b7d1                	j	8000d8 <syscall>

0000000000800116 <sys_fork>:
}

int
sys_fork(void) {
    return syscall(SYS_fork);
  800116:	4509                	li	a0,2
  800118:	b7c1                	j	8000d8 <syscall>

000000000080011a <sys_wait>:
}

int
sys_wait(int64_t pid, int *store) {
  80011a:	862e                	mv	a2,a1
    return syscall(SYS_wait, pid, store);
  80011c:	85aa                	mv	a1,a0
  80011e:	450d                	li	a0,3
  800120:	bf65                	j	8000d8 <syscall>

0000000000800122 <sys_putc>:
sys_getpid(void) {
    return syscall(SYS_getpid);
}

int
sys_putc(int64_t c) {
  800122:	85aa                	mv	a1,a0
    return syscall(SYS_putc, c);
  800124:	4579                	li	a0,30
  800126:	bf4d                	j	8000d8 <syscall>

0000000000800128 <sys_gettime>:
    return syscall(SYS_pgdir);
}

int
sys_gettime(void) {
    return syscall(SYS_gettime);
  800128:	4545                	li	a0,17
  80012a:	b77d                	j	8000d8 <syscall>

000000000080012c <sys_sleep>:
{
    syscall(SYS_lab6_set_priority, priority);
}

int
sys_sleep(uint64_t time) {
  80012c:	85aa                	mv	a1,a0
    return syscall(SYS_sleep, time);
  80012e:	452d                	li	a0,11
  800130:	b765                	j	8000d8 <syscall>

0000000000800132 <exit>:
#include <syscall.h>
#include <stdio.h>
#include <ulib.h>

void
exit(int error_code) {
  800132:	1141                	addi	sp,sp,-16
  800134:	e406                	sd	ra,8(sp)
    sys_exit(error_code);
  800136:	fdbff0ef          	jal	ra,800110 <sys_exit>
    cprintf("BUG: exit failed.\n");
  80013a:	00000517          	auipc	a0,0x0
  80013e:	4fe50513          	addi	a0,a0,1278 # 800638 <main+0x98>
  800142:	f61ff0ef          	jal	ra,8000a2 <cprintf>
    while (1);
  800146:	a001                	j	800146 <exit+0x14>

0000000000800148 <fork>:
}

int
fork(void) {
    return sys_fork();
  800148:	b7f9                	j	800116 <sys_fork>

000000000080014a <waitpid>:
    return sys_wait(0, NULL);
}

int
waitpid(int pid, int *store) {
    return sys_wait(pid, store);
  80014a:	bfc1                	j	80011a <sys_wait>

000000000080014c <gettime_msec>:
    sys_pgdir();
}

unsigned int
gettime_msec(void) {
    return (unsigned int)sys_gettime();
  80014c:	bff1                	j	800128 <sys_gettime>

000000000080014e <sleep>:
    sys_lab6_set_priority(priority);
}

int
sleep(unsigned int time) {
    return sys_sleep(time);
  80014e:	1502                	slli	a0,a0,0x20
  800150:	9101                	srli	a0,a0,0x20
  800152:	bfe9                	j	80012c <sys_sleep>

0000000000800154 <umain>:
#include <ulib.h>

int main(void);

void
umain(void) {
  800154:	1141                	addi	sp,sp,-16
  800156:	e406                	sd	ra,8(sp)
    int ret = main();
  800158:	448000ef          	jal	ra,8005a0 <main>
    exit(ret);
  80015c:	fd7ff0ef          	jal	ra,800132 <exit>

0000000000800160 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
  800160:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
  800164:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
  800166:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
  80016a:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
  80016c:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
  800170:	f022                	sd	s0,32(sp)
  800172:	ec26                	sd	s1,24(sp)
  800174:	e84a                	sd	s2,16(sp)
  800176:	f406                	sd	ra,40(sp)
  800178:	e44e                	sd	s3,8(sp)
  80017a:	84aa                	mv	s1,a0
  80017c:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
  80017e:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
  800182:	2a01                	sext.w	s4,s4
    if (num >= base) {
  800184:	03067e63          	bgeu	a2,a6,8001c0 <printnum+0x60>
  800188:	89be                	mv	s3,a5
        while (-- width > 0)
  80018a:	00805763          	blez	s0,800198 <printnum+0x38>
  80018e:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
  800190:	85ca                	mv	a1,s2
  800192:	854e                	mv	a0,s3
  800194:	9482                	jalr	s1
        while (-- width > 0)
  800196:	fc65                	bnez	s0,80018e <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
  800198:	1a02                	slli	s4,s4,0x20
  80019a:	00000797          	auipc	a5,0x0
  80019e:	4b678793          	addi	a5,a5,1206 # 800650 <main+0xb0>
  8001a2:	020a5a13          	srli	s4,s4,0x20
  8001a6:	9a3e                	add	s4,s4,a5
    // Crashes if num >= base. No idea what going on here
    // Here is a quick fix
    // update: Stack grows downward and destory the SBI
    // sbi_console_putchar("0123456789abcdef"[mod]);
    // (*(int *)putdat)++;
}
  8001a8:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
  8001aa:	000a4503          	lbu	a0,0(s4)
}
  8001ae:	70a2                	ld	ra,40(sp)
  8001b0:	69a2                	ld	s3,8(sp)
  8001b2:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
  8001b4:	85ca                	mv	a1,s2
  8001b6:	87a6                	mv	a5,s1
}
  8001b8:	6942                	ld	s2,16(sp)
  8001ba:	64e2                	ld	s1,24(sp)
  8001bc:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
  8001be:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
  8001c0:	03065633          	divu	a2,a2,a6
  8001c4:	8722                	mv	a4,s0
  8001c6:	f9bff0ef          	jal	ra,800160 <printnum>
  8001ca:	b7f9                	j	800198 <printnum+0x38>

00000000008001cc <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
  8001cc:	7119                	addi	sp,sp,-128
  8001ce:	f4a6                	sd	s1,104(sp)
  8001d0:	f0ca                	sd	s2,96(sp)
  8001d2:	ecce                	sd	s3,88(sp)
  8001d4:	e8d2                	sd	s4,80(sp)
  8001d6:	e4d6                	sd	s5,72(sp)
  8001d8:	e0da                	sd	s6,64(sp)
  8001da:	fc5e                	sd	s7,56(sp)
  8001dc:	f06a                	sd	s10,32(sp)
  8001de:	fc86                	sd	ra,120(sp)
  8001e0:	f8a2                	sd	s0,112(sp)
  8001e2:	f862                	sd	s8,48(sp)
  8001e4:	f466                	sd	s9,40(sp)
  8001e6:	ec6e                	sd	s11,24(sp)
  8001e8:	892a                	mv	s2,a0
  8001ea:	84ae                	mv	s1,a1
  8001ec:	8d32                	mv	s10,a2
  8001ee:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
  8001f0:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
  8001f4:	5b7d                	li	s6,-1
  8001f6:	00000a97          	auipc	s5,0x0
  8001fa:	48ea8a93          	addi	s5,s5,1166 # 800684 <main+0xe4>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
  8001fe:	00000b97          	auipc	s7,0x0
  800202:	6a2b8b93          	addi	s7,s7,1698 # 8008a0 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
  800206:	000d4503          	lbu	a0,0(s10)
  80020a:	001d0413          	addi	s0,s10,1
  80020e:	01350a63          	beq	a0,s3,800222 <vprintfmt+0x56>
            if (ch == '\0') {
  800212:	c121                	beqz	a0,800252 <vprintfmt+0x86>
            putch(ch, putdat);
  800214:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
  800216:	0405                	addi	s0,s0,1
            putch(ch, putdat);
  800218:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
  80021a:	fff44503          	lbu	a0,-1(s0)
  80021e:	ff351ae3          	bne	a0,s3,800212 <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
  800222:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
  800226:	02000793          	li	a5,32
        lflag = altflag = 0;
  80022a:	4c81                	li	s9,0
  80022c:	4881                	li	a7,0
        width = precision = -1;
  80022e:	5c7d                	li	s8,-1
  800230:	5dfd                	li	s11,-1
  800232:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
  800236:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
  800238:	fdd6059b          	addiw	a1,a2,-35
  80023c:	0ff5f593          	zext.b	a1,a1
  800240:	00140d13          	addi	s10,s0,1
  800244:	04b56263          	bltu	a0,a1,800288 <vprintfmt+0xbc>
  800248:	058a                	slli	a1,a1,0x2
  80024a:	95d6                	add	a1,a1,s5
  80024c:	4194                	lw	a3,0(a1)
  80024e:	96d6                	add	a3,a3,s5
  800250:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
  800252:	70e6                	ld	ra,120(sp)
  800254:	7446                	ld	s0,112(sp)
  800256:	74a6                	ld	s1,104(sp)
  800258:	7906                	ld	s2,96(sp)
  80025a:	69e6                	ld	s3,88(sp)
  80025c:	6a46                	ld	s4,80(sp)
  80025e:	6aa6                	ld	s5,72(sp)
  800260:	6b06                	ld	s6,64(sp)
  800262:	7be2                	ld	s7,56(sp)
  800264:	7c42                	ld	s8,48(sp)
  800266:	7ca2                	ld	s9,40(sp)
  800268:	7d02                	ld	s10,32(sp)
  80026a:	6de2                	ld	s11,24(sp)
  80026c:	6109                	addi	sp,sp,128
  80026e:	8082                	ret
            padc = '0';
  800270:	87b2                	mv	a5,a2
            goto reswitch;
  800272:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
  800276:	846a                	mv	s0,s10
  800278:	00140d13          	addi	s10,s0,1
  80027c:	fdd6059b          	addiw	a1,a2,-35
  800280:	0ff5f593          	zext.b	a1,a1
  800284:	fcb572e3          	bgeu	a0,a1,800248 <vprintfmt+0x7c>
            putch('%', putdat);
  800288:	85a6                	mv	a1,s1
  80028a:	02500513          	li	a0,37
  80028e:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
  800290:	fff44783          	lbu	a5,-1(s0)
  800294:	8d22                	mv	s10,s0
  800296:	f73788e3          	beq	a5,s3,800206 <vprintfmt+0x3a>
  80029a:	ffed4783          	lbu	a5,-2(s10)
  80029e:	1d7d                	addi	s10,s10,-1
  8002a0:	ff379de3          	bne	a5,s3,80029a <vprintfmt+0xce>
  8002a4:	b78d                	j	800206 <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
  8002a6:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
  8002aa:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
  8002ae:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
  8002b0:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
  8002b4:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
  8002b8:	02d86463          	bltu	a6,a3,8002e0 <vprintfmt+0x114>
                ch = *fmt;
  8002bc:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
  8002c0:	002c169b          	slliw	a3,s8,0x2
  8002c4:	0186873b          	addw	a4,a3,s8
  8002c8:	0017171b          	slliw	a4,a4,0x1
  8002cc:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
  8002ce:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
  8002d2:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
  8002d4:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
  8002d8:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
  8002dc:	fed870e3          	bgeu	a6,a3,8002bc <vprintfmt+0xf0>
            if (width < 0)
  8002e0:	f40ddce3          	bgez	s11,800238 <vprintfmt+0x6c>
                width = precision, precision = -1;
  8002e4:	8de2                	mv	s11,s8
  8002e6:	5c7d                	li	s8,-1
  8002e8:	bf81                	j	800238 <vprintfmt+0x6c>
            if (width < 0)
  8002ea:	fffdc693          	not	a3,s11
  8002ee:	96fd                	srai	a3,a3,0x3f
  8002f0:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
  8002f4:	00144603          	lbu	a2,1(s0)
  8002f8:	2d81                	sext.w	s11,s11
  8002fa:	846a                	mv	s0,s10
            goto reswitch;
  8002fc:	bf35                	j	800238 <vprintfmt+0x6c>
            precision = va_arg(ap, int);
  8002fe:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
  800302:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
  800306:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
  800308:	846a                	mv	s0,s10
            goto process_precision;
  80030a:	bfd9                	j	8002e0 <vprintfmt+0x114>
    if (lflag >= 2) {
  80030c:	4705                	li	a4,1
            precision = va_arg(ap, int);
  80030e:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
  800312:	01174463          	blt	a4,a7,80031a <vprintfmt+0x14e>
    else if (lflag) {
  800316:	1a088e63          	beqz	a7,8004d2 <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
  80031a:	000a3603          	ld	a2,0(s4)
  80031e:	46c1                	li	a3,16
  800320:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
  800322:	2781                	sext.w	a5,a5
  800324:	876e                	mv	a4,s11
  800326:	85a6                	mv	a1,s1
  800328:	854a                	mv	a0,s2
  80032a:	e37ff0ef          	jal	ra,800160 <printnum>
            break;
  80032e:	bde1                	j	800206 <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
  800330:	000a2503          	lw	a0,0(s4)
  800334:	85a6                	mv	a1,s1
  800336:	0a21                	addi	s4,s4,8
  800338:	9902                	jalr	s2
            break;
  80033a:	b5f1                	j	800206 <vprintfmt+0x3a>
    if (lflag >= 2) {
  80033c:	4705                	li	a4,1
            precision = va_arg(ap, int);
  80033e:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
  800342:	01174463          	blt	a4,a7,80034a <vprintfmt+0x17e>
    else if (lflag) {
  800346:	18088163          	beqz	a7,8004c8 <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
  80034a:	000a3603          	ld	a2,0(s4)
  80034e:	46a9                	li	a3,10
  800350:	8a2e                	mv	s4,a1
  800352:	bfc1                	j	800322 <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
  800354:	00144603          	lbu	a2,1(s0)
            altflag = 1;
  800358:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
  80035a:	846a                	mv	s0,s10
            goto reswitch;
  80035c:	bdf1                	j	800238 <vprintfmt+0x6c>
            putch(ch, putdat);
  80035e:	85a6                	mv	a1,s1
  800360:	02500513          	li	a0,37
  800364:	9902                	jalr	s2
            break;
  800366:	b545                	j	800206 <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
  800368:	00144603          	lbu	a2,1(s0)
            lflag ++;
  80036c:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
  80036e:	846a                	mv	s0,s10
            goto reswitch;
  800370:	b5e1                	j	800238 <vprintfmt+0x6c>
    if (lflag >= 2) {
  800372:	4705                	li	a4,1
            precision = va_arg(ap, int);
  800374:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
  800378:	01174463          	blt	a4,a7,800380 <vprintfmt+0x1b4>
    else if (lflag) {
  80037c:	14088163          	beqz	a7,8004be <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
  800380:	000a3603          	ld	a2,0(s4)
  800384:	46a1                	li	a3,8
  800386:	8a2e                	mv	s4,a1
  800388:	bf69                	j	800322 <vprintfmt+0x156>
            putch('0', putdat);
  80038a:	03000513          	li	a0,48
  80038e:	85a6                	mv	a1,s1
  800390:	e03e                	sd	a5,0(sp)
  800392:	9902                	jalr	s2
            putch('x', putdat);
  800394:	85a6                	mv	a1,s1
  800396:	07800513          	li	a0,120
  80039a:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
  80039c:	0a21                	addi	s4,s4,8
            goto number;
  80039e:	6782                	ld	a5,0(sp)
  8003a0:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
  8003a2:	ff8a3603          	ld	a2,-8(s4)
            goto number;
  8003a6:	bfb5                	j	800322 <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
  8003a8:	000a3403          	ld	s0,0(s4)
  8003ac:	008a0713          	addi	a4,s4,8
  8003b0:	e03a                	sd	a4,0(sp)
  8003b2:	14040263          	beqz	s0,8004f6 <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
  8003b6:	0fb05763          	blez	s11,8004a4 <vprintfmt+0x2d8>
  8003ba:	02d00693          	li	a3,45
  8003be:	0cd79163          	bne	a5,a3,800480 <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  8003c2:	00044783          	lbu	a5,0(s0)
  8003c6:	0007851b          	sext.w	a0,a5
  8003ca:	cf85                	beqz	a5,800402 <vprintfmt+0x236>
  8003cc:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
  8003d0:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  8003d4:	000c4563          	bltz	s8,8003de <vprintfmt+0x212>
  8003d8:	3c7d                	addiw	s8,s8,-1
  8003da:	036c0263          	beq	s8,s6,8003fe <vprintfmt+0x232>
                    putch('?', putdat);
  8003de:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
  8003e0:	0e0c8e63          	beqz	s9,8004dc <vprintfmt+0x310>
  8003e4:	3781                	addiw	a5,a5,-32
  8003e6:	0ef47b63          	bgeu	s0,a5,8004dc <vprintfmt+0x310>
                    putch('?', putdat);
  8003ea:	03f00513          	li	a0,63
  8003ee:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  8003f0:	000a4783          	lbu	a5,0(s4)
  8003f4:	3dfd                	addiw	s11,s11,-1
  8003f6:	0a05                	addi	s4,s4,1
  8003f8:	0007851b          	sext.w	a0,a5
  8003fc:	ffe1                	bnez	a5,8003d4 <vprintfmt+0x208>
            for (; width > 0; width --) {
  8003fe:	01b05963          	blez	s11,800410 <vprintfmt+0x244>
  800402:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
  800404:	85a6                	mv	a1,s1
  800406:	02000513          	li	a0,32
  80040a:	9902                	jalr	s2
            for (; width > 0; width --) {
  80040c:	fe0d9be3          	bnez	s11,800402 <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
  800410:	6a02                	ld	s4,0(sp)
  800412:	bbd5                	j	800206 <vprintfmt+0x3a>
    if (lflag >= 2) {
  800414:	4705                	li	a4,1
            precision = va_arg(ap, int);
  800416:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
  80041a:	01174463          	blt	a4,a7,800422 <vprintfmt+0x256>
    else if (lflag) {
  80041e:	08088d63          	beqz	a7,8004b8 <vprintfmt+0x2ec>
        return va_arg(*ap, long);
  800422:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
  800426:	0a044d63          	bltz	s0,8004e0 <vprintfmt+0x314>
            num = getint(&ap, lflag);
  80042a:	8622                	mv	a2,s0
  80042c:	8a66                	mv	s4,s9
  80042e:	46a9                	li	a3,10
  800430:	bdcd                	j	800322 <vprintfmt+0x156>
            err = va_arg(ap, int);
  800432:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
  800436:	4761                	li	a4,24
            err = va_arg(ap, int);
  800438:	0a21                	addi	s4,s4,8
            if (err < 0) {
  80043a:	41f7d69b          	sraiw	a3,a5,0x1f
  80043e:	8fb5                	xor	a5,a5,a3
  800440:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
  800444:	02d74163          	blt	a4,a3,800466 <vprintfmt+0x29a>
  800448:	00369793          	slli	a5,a3,0x3
  80044c:	97de                	add	a5,a5,s7
  80044e:	639c                	ld	a5,0(a5)
  800450:	cb99                	beqz	a5,800466 <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
  800452:	86be                	mv	a3,a5
  800454:	00000617          	auipc	a2,0x0
  800458:	22c60613          	addi	a2,a2,556 # 800680 <main+0xe0>
  80045c:	85a6                	mv	a1,s1
  80045e:	854a                	mv	a0,s2
  800460:	0ce000ef          	jal	ra,80052e <printfmt>
  800464:	b34d                	j	800206 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
  800466:	00000617          	auipc	a2,0x0
  80046a:	20a60613          	addi	a2,a2,522 # 800670 <main+0xd0>
  80046e:	85a6                	mv	a1,s1
  800470:	854a                	mv	a0,s2
  800472:	0bc000ef          	jal	ra,80052e <printfmt>
  800476:	bb41                	j	800206 <vprintfmt+0x3a>
                p = "(null)";
  800478:	00000417          	auipc	s0,0x0
  80047c:	1f040413          	addi	s0,s0,496 # 800668 <main+0xc8>
                for (width -= strnlen(p, precision); width > 0; width --) {
  800480:	85e2                	mv	a1,s8
  800482:	8522                	mv	a0,s0
  800484:	e43e                	sd	a5,8(sp)
  800486:	0c8000ef          	jal	ra,80054e <strnlen>
  80048a:	40ad8dbb          	subw	s11,s11,a0
  80048e:	01b05b63          	blez	s11,8004a4 <vprintfmt+0x2d8>
                    putch(padc, putdat);
  800492:	67a2                	ld	a5,8(sp)
  800494:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
  800498:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
  80049a:	85a6                	mv	a1,s1
  80049c:	8552                	mv	a0,s4
  80049e:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
  8004a0:	fe0d9ce3          	bnez	s11,800498 <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  8004a4:	00044783          	lbu	a5,0(s0)
  8004a8:	00140a13          	addi	s4,s0,1
  8004ac:	0007851b          	sext.w	a0,a5
  8004b0:	d3a5                	beqz	a5,800410 <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
  8004b2:	05e00413          	li	s0,94
  8004b6:	bf39                	j	8003d4 <vprintfmt+0x208>
        return va_arg(*ap, int);
  8004b8:	000a2403          	lw	s0,0(s4)
  8004bc:	b7ad                	j	800426 <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
  8004be:	000a6603          	lwu	a2,0(s4)
  8004c2:	46a1                	li	a3,8
  8004c4:	8a2e                	mv	s4,a1
  8004c6:	bdb1                	j	800322 <vprintfmt+0x156>
  8004c8:	000a6603          	lwu	a2,0(s4)
  8004cc:	46a9                	li	a3,10
  8004ce:	8a2e                	mv	s4,a1
  8004d0:	bd89                	j	800322 <vprintfmt+0x156>
  8004d2:	000a6603          	lwu	a2,0(s4)
  8004d6:	46c1                	li	a3,16
  8004d8:	8a2e                	mv	s4,a1
  8004da:	b5a1                	j	800322 <vprintfmt+0x156>
                    putch(ch, putdat);
  8004dc:	9902                	jalr	s2
  8004de:	bf09                	j	8003f0 <vprintfmt+0x224>
                putch('-', putdat);
  8004e0:	85a6                	mv	a1,s1
  8004e2:	02d00513          	li	a0,45
  8004e6:	e03e                	sd	a5,0(sp)
  8004e8:	9902                	jalr	s2
                num = -(long long)num;
  8004ea:	6782                	ld	a5,0(sp)
  8004ec:	8a66                	mv	s4,s9
  8004ee:	40800633          	neg	a2,s0
  8004f2:	46a9                	li	a3,10
  8004f4:	b53d                	j	800322 <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
  8004f6:	03b05163          	blez	s11,800518 <vprintfmt+0x34c>
  8004fa:	02d00693          	li	a3,45
  8004fe:	f6d79de3          	bne	a5,a3,800478 <vprintfmt+0x2ac>
                p = "(null)";
  800502:	00000417          	auipc	s0,0x0
  800506:	16640413          	addi	s0,s0,358 # 800668 <main+0xc8>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  80050a:	02800793          	li	a5,40
  80050e:	02800513          	li	a0,40
  800512:	00140a13          	addi	s4,s0,1
  800516:	bd6d                	j	8003d0 <vprintfmt+0x204>
  800518:	00000a17          	auipc	s4,0x0
  80051c:	151a0a13          	addi	s4,s4,337 # 800669 <main+0xc9>
  800520:	02800513          	li	a0,40
  800524:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
  800528:	05e00413          	li	s0,94
  80052c:	b565                	j	8003d4 <vprintfmt+0x208>

000000000080052e <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
  80052e:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
  800530:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
  800534:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
  800536:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
  800538:	ec06                	sd	ra,24(sp)
  80053a:	f83a                	sd	a4,48(sp)
  80053c:	fc3e                	sd	a5,56(sp)
  80053e:	e0c2                	sd	a6,64(sp)
  800540:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
  800542:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
  800544:	c89ff0ef          	jal	ra,8001cc <vprintfmt>
}
  800548:	60e2                	ld	ra,24(sp)
  80054a:	6161                	addi	sp,sp,80
  80054c:	8082                	ret

000000000080054e <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
  80054e:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
  800550:	e589                	bnez	a1,80055a <strnlen+0xc>
  800552:	a811                	j	800566 <strnlen+0x18>
        cnt ++;
  800554:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
  800556:	00f58863          	beq	a1,a5,800566 <strnlen+0x18>
  80055a:	00f50733          	add	a4,a0,a5
  80055e:	00074703          	lbu	a4,0(a4)
  800562:	fb6d                	bnez	a4,800554 <strnlen+0x6>
  800564:	85be                	mv	a1,a5
    }
    return cnt;
}
  800566:	852e                	mv	a0,a1
  800568:	8082                	ret

000000000080056a <sleepy>:
#include <stdio.h>
#include <ulib.h>

void
sleepy(int pid) {
  80056a:	1101                	addi	sp,sp,-32
  80056c:	e822                	sd	s0,16(sp)
  80056e:	e426                	sd	s1,8(sp)
  800570:	e04a                	sd	s2,0(sp)
  800572:	ec06                	sd	ra,24(sp)
    int i, time = 100;
    for (i = 0; i < 10; i ++) {
  800574:	4401                	li	s0,0
        sleep(time);
        cprintf("sleep %d x %d slices.\n", i + 1, time);
  800576:	00000917          	auipc	s2,0x0
  80057a:	3f290913          	addi	s2,s2,1010 # 800968 <error_string+0xc8>
    for (i = 0; i < 10; i ++) {
  80057e:	44a9                	li	s1,10
        sleep(time);
  800580:	06400513          	li	a0,100
  800584:	bcbff0ef          	jal	ra,80014e <sleep>
        cprintf("sleep %d x %d slices.\n", i + 1, time);
  800588:	2405                	addiw	s0,s0,1
  80058a:	06400613          	li	a2,100
  80058e:	85a2                	mv	a1,s0
  800590:	854a                	mv	a0,s2
  800592:	b11ff0ef          	jal	ra,8000a2 <cprintf>
    for (i = 0; i < 10; i ++) {
  800596:	fe9415e3          	bne	s0,s1,800580 <sleepy+0x16>
    }
    exit(0);
  80059a:	4501                	li	a0,0
  80059c:	b97ff0ef          	jal	ra,800132 <exit>

00000000008005a0 <main>:
}

int
main(void) {
  8005a0:	1101                	addi	sp,sp,-32
  8005a2:	e822                	sd	s0,16(sp)
  8005a4:	ec06                	sd	ra,24(sp)
    unsigned int time = gettime_msec();
  8005a6:	ba7ff0ef          	jal	ra,80014c <gettime_msec>
  8005aa:	0005041b          	sext.w	s0,a0
    int pid1, exit_code;

    if ((pid1 = fork()) == 0) {
  8005ae:	b9bff0ef          	jal	ra,800148 <fork>
  8005b2:	cd21                	beqz	a0,80060a <main+0x6a>
        sleepy(pid1);
    }
    
    assert(waitpid(pid1, &exit_code) == 0 && exit_code == 0);
  8005b4:	006c                	addi	a1,sp,12
  8005b6:	b95ff0ef          	jal	ra,80014a <waitpid>
  8005ba:	47b2                	lw	a5,12(sp)
  8005bc:	8fc9                	or	a5,a5,a0
  8005be:	2781                	sext.w	a5,a5
  8005c0:	e795                	bnez	a5,8005ec <main+0x4c>
    cprintf("use %04d msecs.\n", gettime_msec() - time);
  8005c2:	b8bff0ef          	jal	ra,80014c <gettime_msec>
  8005c6:	408505bb          	subw	a1,a0,s0
  8005ca:	00000517          	auipc	a0,0x0
  8005ce:	41650513          	addi	a0,a0,1046 # 8009e0 <error_string+0x140>
  8005d2:	ad1ff0ef          	jal	ra,8000a2 <cprintf>
    cprintf("sleep pass.\n");
  8005d6:	00000517          	auipc	a0,0x0
  8005da:	42250513          	addi	a0,a0,1058 # 8009f8 <error_string+0x158>
  8005de:	ac5ff0ef          	jal	ra,8000a2 <cprintf>
    return 0;
}
  8005e2:	60e2                	ld	ra,24(sp)
  8005e4:	6442                	ld	s0,16(sp)
  8005e6:	4501                	li	a0,0
  8005e8:	6105                	addi	sp,sp,32
  8005ea:	8082                	ret
    assert(waitpid(pid1, &exit_code) == 0 && exit_code == 0);
  8005ec:	00000697          	auipc	a3,0x0
  8005f0:	39468693          	addi	a3,a3,916 # 800980 <error_string+0xe0>
  8005f4:	00000617          	auipc	a2,0x0
  8005f8:	3c460613          	addi	a2,a2,964 # 8009b8 <error_string+0x118>
  8005fc:	45dd                	li	a1,23
  8005fe:	00000517          	auipc	a0,0x0
  800602:	3d250513          	addi	a0,a0,978 # 8009d0 <error_string+0x130>
  800606:	a21ff0ef          	jal	ra,800026 <__panic>
        sleepy(pid1);
  80060a:	f61ff0ef          	jal	ra,80056a <sleepy>
