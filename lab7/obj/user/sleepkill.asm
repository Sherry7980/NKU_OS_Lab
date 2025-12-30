
obj/__user_sleepkill.out:     file format elf64-littleriscv


Disassembly of section .text:

0000000000800020 <_start>:
    # move down the esp register
    # since it may cause page fault in backtrace
    // subl $0x20, %esp

    # call user-program function
    call umain
  800020:	12c000ef          	jal	ra,80014c <umain>
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
  80003a:	5b250513          	addi	a0,a0,1458 # 8005e8 <main+0x86>
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
  80005a:	5b250513          	addi	a0,a0,1458 # 800608 <main+0xa6>
  80005e:	044000ef          	jal	ra,8000a2 <cprintf>
    va_end(ap);
    exit(-E_PANIC);
  800062:	5559                	li	a0,-10
  800064:	0c8000ef          	jal	ra,80012c <exit>

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
  800070:	0b0000ef          	jal	ra,800120 <sys_putc>
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
  800096:	12e000ef          	jal	ra,8001c4 <vprintfmt>
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
  8000cc:	0f8000ef          	jal	ra,8001c4 <vprintfmt>
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

000000000080011a <sys_kill>:
sys_yield(void) {
    return syscall(SYS_yield);
}

int
sys_kill(int64_t pid) {
  80011a:	85aa                	mv	a1,a0
    return syscall(SYS_kill, pid);
  80011c:	4531                	li	a0,12
  80011e:	bf6d                	j	8000d8 <syscall>

0000000000800120 <sys_putc>:
sys_getpid(void) {
    return syscall(SYS_getpid);
}

int
sys_putc(int64_t c) {
  800120:	85aa                	mv	a1,a0
    return syscall(SYS_putc, c);
  800122:	4579                	li	a0,30
  800124:	bf55                	j	8000d8 <syscall>

0000000000800126 <sys_sleep>:
{
    syscall(SYS_lab6_set_priority, priority);
}

int
sys_sleep(uint64_t time) {
  800126:	85aa                	mv	a1,a0
    return syscall(SYS_sleep, time);
  800128:	452d                	li	a0,11
  80012a:	b77d                	j	8000d8 <syscall>

000000000080012c <exit>:
#include <syscall.h>
#include <stdio.h>
#include <ulib.h>

void
exit(int error_code) {
  80012c:	1141                	addi	sp,sp,-16
  80012e:	e406                	sd	ra,8(sp)
    sys_exit(error_code);
  800130:	fe1ff0ef          	jal	ra,800110 <sys_exit>
    cprintf("BUG: exit failed.\n");
  800134:	00000517          	auipc	a0,0x0
  800138:	4dc50513          	addi	a0,a0,1244 # 800610 <main+0xae>
  80013c:	f67ff0ef          	jal	ra,8000a2 <cprintf>
    while (1);
  800140:	a001                	j	800140 <exit+0x14>

0000000000800142 <fork>:
}

int
fork(void) {
    return sys_fork();
  800142:	bfd1                	j	800116 <sys_fork>

0000000000800144 <kill>:
    sys_yield();
}

int
kill(int pid) {
    return sys_kill(pid);
  800144:	bfd9                	j	80011a <sys_kill>

0000000000800146 <sleep>:
    sys_lab6_set_priority(priority);
}

int
sleep(unsigned int time) {
    return sys_sleep(time);
  800146:	1502                	slli	a0,a0,0x20
  800148:	9101                	srli	a0,a0,0x20
  80014a:	bff1                	j	800126 <sys_sleep>

000000000080014c <umain>:
#include <ulib.h>

int main(void);

void
umain(void) {
  80014c:	1141                	addi	sp,sp,-16
  80014e:	e406                	sd	ra,8(sp)
    int ret = main();
  800150:	412000ef          	jal	ra,800562 <main>
    exit(ret);
  800154:	fd9ff0ef          	jal	ra,80012c <exit>

0000000000800158 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
  800158:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
  80015c:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
  80015e:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
  800162:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
  800164:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
  800168:	f022                	sd	s0,32(sp)
  80016a:	ec26                	sd	s1,24(sp)
  80016c:	e84a                	sd	s2,16(sp)
  80016e:	f406                	sd	ra,40(sp)
  800170:	e44e                	sd	s3,8(sp)
  800172:	84aa                	mv	s1,a0
  800174:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
  800176:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
  80017a:	2a01                	sext.w	s4,s4
    if (num >= base) {
  80017c:	03067e63          	bgeu	a2,a6,8001b8 <printnum+0x60>
  800180:	89be                	mv	s3,a5
        while (-- width > 0)
  800182:	00805763          	blez	s0,800190 <printnum+0x38>
  800186:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
  800188:	85ca                	mv	a1,s2
  80018a:	854e                	mv	a0,s3
  80018c:	9482                	jalr	s1
        while (-- width > 0)
  80018e:	fc65                	bnez	s0,800186 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
  800190:	1a02                	slli	s4,s4,0x20
  800192:	00000797          	auipc	a5,0x0
  800196:	49678793          	addi	a5,a5,1174 # 800628 <main+0xc6>
  80019a:	020a5a13          	srli	s4,s4,0x20
  80019e:	9a3e                	add	s4,s4,a5
    // Crashes if num >= base. No idea what going on here
    // Here is a quick fix
    // update: Stack grows downward and destory the SBI
    // sbi_console_putchar("0123456789abcdef"[mod]);
    // (*(int *)putdat)++;
}
  8001a0:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
  8001a2:	000a4503          	lbu	a0,0(s4)
}
  8001a6:	70a2                	ld	ra,40(sp)
  8001a8:	69a2                	ld	s3,8(sp)
  8001aa:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
  8001ac:	85ca                	mv	a1,s2
  8001ae:	87a6                	mv	a5,s1
}
  8001b0:	6942                	ld	s2,16(sp)
  8001b2:	64e2                	ld	s1,24(sp)
  8001b4:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
  8001b6:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
  8001b8:	03065633          	divu	a2,a2,a6
  8001bc:	8722                	mv	a4,s0
  8001be:	f9bff0ef          	jal	ra,800158 <printnum>
  8001c2:	b7f9                	j	800190 <printnum+0x38>

00000000008001c4 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
  8001c4:	7119                	addi	sp,sp,-128
  8001c6:	f4a6                	sd	s1,104(sp)
  8001c8:	f0ca                	sd	s2,96(sp)
  8001ca:	ecce                	sd	s3,88(sp)
  8001cc:	e8d2                	sd	s4,80(sp)
  8001ce:	e4d6                	sd	s5,72(sp)
  8001d0:	e0da                	sd	s6,64(sp)
  8001d2:	fc5e                	sd	s7,56(sp)
  8001d4:	f06a                	sd	s10,32(sp)
  8001d6:	fc86                	sd	ra,120(sp)
  8001d8:	f8a2                	sd	s0,112(sp)
  8001da:	f862                	sd	s8,48(sp)
  8001dc:	f466                	sd	s9,40(sp)
  8001de:	ec6e                	sd	s11,24(sp)
  8001e0:	892a                	mv	s2,a0
  8001e2:	84ae                	mv	s1,a1
  8001e4:	8d32                	mv	s10,a2
  8001e6:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
  8001e8:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
  8001ec:	5b7d                	li	s6,-1
  8001ee:	00000a97          	auipc	s5,0x0
  8001f2:	46ea8a93          	addi	s5,s5,1134 # 80065c <main+0xfa>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
  8001f6:	00000b97          	auipc	s7,0x0
  8001fa:	682b8b93          	addi	s7,s7,1666 # 800878 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
  8001fe:	000d4503          	lbu	a0,0(s10)
  800202:	001d0413          	addi	s0,s10,1
  800206:	01350a63          	beq	a0,s3,80021a <vprintfmt+0x56>
            if (ch == '\0') {
  80020a:	c121                	beqz	a0,80024a <vprintfmt+0x86>
            putch(ch, putdat);
  80020c:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
  80020e:	0405                	addi	s0,s0,1
            putch(ch, putdat);
  800210:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
  800212:	fff44503          	lbu	a0,-1(s0)
  800216:	ff351ae3          	bne	a0,s3,80020a <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
  80021a:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
  80021e:	02000793          	li	a5,32
        lflag = altflag = 0;
  800222:	4c81                	li	s9,0
  800224:	4881                	li	a7,0
        width = precision = -1;
  800226:	5c7d                	li	s8,-1
  800228:	5dfd                	li	s11,-1
  80022a:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
  80022e:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
  800230:	fdd6059b          	addiw	a1,a2,-35
  800234:	0ff5f593          	zext.b	a1,a1
  800238:	00140d13          	addi	s10,s0,1
  80023c:	04b56263          	bltu	a0,a1,800280 <vprintfmt+0xbc>
  800240:	058a                	slli	a1,a1,0x2
  800242:	95d6                	add	a1,a1,s5
  800244:	4194                	lw	a3,0(a1)
  800246:	96d6                	add	a3,a3,s5
  800248:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
  80024a:	70e6                	ld	ra,120(sp)
  80024c:	7446                	ld	s0,112(sp)
  80024e:	74a6                	ld	s1,104(sp)
  800250:	7906                	ld	s2,96(sp)
  800252:	69e6                	ld	s3,88(sp)
  800254:	6a46                	ld	s4,80(sp)
  800256:	6aa6                	ld	s5,72(sp)
  800258:	6b06                	ld	s6,64(sp)
  80025a:	7be2                	ld	s7,56(sp)
  80025c:	7c42                	ld	s8,48(sp)
  80025e:	7ca2                	ld	s9,40(sp)
  800260:	7d02                	ld	s10,32(sp)
  800262:	6de2                	ld	s11,24(sp)
  800264:	6109                	addi	sp,sp,128
  800266:	8082                	ret
            padc = '0';
  800268:	87b2                	mv	a5,a2
            goto reswitch;
  80026a:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
  80026e:	846a                	mv	s0,s10
  800270:	00140d13          	addi	s10,s0,1
  800274:	fdd6059b          	addiw	a1,a2,-35
  800278:	0ff5f593          	zext.b	a1,a1
  80027c:	fcb572e3          	bgeu	a0,a1,800240 <vprintfmt+0x7c>
            putch('%', putdat);
  800280:	85a6                	mv	a1,s1
  800282:	02500513          	li	a0,37
  800286:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
  800288:	fff44783          	lbu	a5,-1(s0)
  80028c:	8d22                	mv	s10,s0
  80028e:	f73788e3          	beq	a5,s3,8001fe <vprintfmt+0x3a>
  800292:	ffed4783          	lbu	a5,-2(s10)
  800296:	1d7d                	addi	s10,s10,-1
  800298:	ff379de3          	bne	a5,s3,800292 <vprintfmt+0xce>
  80029c:	b78d                	j	8001fe <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
  80029e:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
  8002a2:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
  8002a6:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
  8002a8:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
  8002ac:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
  8002b0:	02d86463          	bltu	a6,a3,8002d8 <vprintfmt+0x114>
                ch = *fmt;
  8002b4:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
  8002b8:	002c169b          	slliw	a3,s8,0x2
  8002bc:	0186873b          	addw	a4,a3,s8
  8002c0:	0017171b          	slliw	a4,a4,0x1
  8002c4:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
  8002c6:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
  8002ca:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
  8002cc:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
  8002d0:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
  8002d4:	fed870e3          	bgeu	a6,a3,8002b4 <vprintfmt+0xf0>
            if (width < 0)
  8002d8:	f40ddce3          	bgez	s11,800230 <vprintfmt+0x6c>
                width = precision, precision = -1;
  8002dc:	8de2                	mv	s11,s8
  8002de:	5c7d                	li	s8,-1
  8002e0:	bf81                	j	800230 <vprintfmt+0x6c>
            if (width < 0)
  8002e2:	fffdc693          	not	a3,s11
  8002e6:	96fd                	srai	a3,a3,0x3f
  8002e8:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
  8002ec:	00144603          	lbu	a2,1(s0)
  8002f0:	2d81                	sext.w	s11,s11
  8002f2:	846a                	mv	s0,s10
            goto reswitch;
  8002f4:	bf35                	j	800230 <vprintfmt+0x6c>
            precision = va_arg(ap, int);
  8002f6:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
  8002fa:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
  8002fe:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
  800300:	846a                	mv	s0,s10
            goto process_precision;
  800302:	bfd9                	j	8002d8 <vprintfmt+0x114>
    if (lflag >= 2) {
  800304:	4705                	li	a4,1
            precision = va_arg(ap, int);
  800306:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
  80030a:	01174463          	blt	a4,a7,800312 <vprintfmt+0x14e>
    else if (lflag) {
  80030e:	1a088e63          	beqz	a7,8004ca <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
  800312:	000a3603          	ld	a2,0(s4)
  800316:	46c1                	li	a3,16
  800318:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
  80031a:	2781                	sext.w	a5,a5
  80031c:	876e                	mv	a4,s11
  80031e:	85a6                	mv	a1,s1
  800320:	854a                	mv	a0,s2
  800322:	e37ff0ef          	jal	ra,800158 <printnum>
            break;
  800326:	bde1                	j	8001fe <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
  800328:	000a2503          	lw	a0,0(s4)
  80032c:	85a6                	mv	a1,s1
  80032e:	0a21                	addi	s4,s4,8
  800330:	9902                	jalr	s2
            break;
  800332:	b5f1                	j	8001fe <vprintfmt+0x3a>
    if (lflag >= 2) {
  800334:	4705                	li	a4,1
            precision = va_arg(ap, int);
  800336:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
  80033a:	01174463          	blt	a4,a7,800342 <vprintfmt+0x17e>
    else if (lflag) {
  80033e:	18088163          	beqz	a7,8004c0 <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
  800342:	000a3603          	ld	a2,0(s4)
  800346:	46a9                	li	a3,10
  800348:	8a2e                	mv	s4,a1
  80034a:	bfc1                	j	80031a <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
  80034c:	00144603          	lbu	a2,1(s0)
            altflag = 1;
  800350:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
  800352:	846a                	mv	s0,s10
            goto reswitch;
  800354:	bdf1                	j	800230 <vprintfmt+0x6c>
            putch(ch, putdat);
  800356:	85a6                	mv	a1,s1
  800358:	02500513          	li	a0,37
  80035c:	9902                	jalr	s2
            break;
  80035e:	b545                	j	8001fe <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
  800360:	00144603          	lbu	a2,1(s0)
            lflag ++;
  800364:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
  800366:	846a                	mv	s0,s10
            goto reswitch;
  800368:	b5e1                	j	800230 <vprintfmt+0x6c>
    if (lflag >= 2) {
  80036a:	4705                	li	a4,1
            precision = va_arg(ap, int);
  80036c:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
  800370:	01174463          	blt	a4,a7,800378 <vprintfmt+0x1b4>
    else if (lflag) {
  800374:	14088163          	beqz	a7,8004b6 <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
  800378:	000a3603          	ld	a2,0(s4)
  80037c:	46a1                	li	a3,8
  80037e:	8a2e                	mv	s4,a1
  800380:	bf69                	j	80031a <vprintfmt+0x156>
            putch('0', putdat);
  800382:	03000513          	li	a0,48
  800386:	85a6                	mv	a1,s1
  800388:	e03e                	sd	a5,0(sp)
  80038a:	9902                	jalr	s2
            putch('x', putdat);
  80038c:	85a6                	mv	a1,s1
  80038e:	07800513          	li	a0,120
  800392:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
  800394:	0a21                	addi	s4,s4,8
            goto number;
  800396:	6782                	ld	a5,0(sp)
  800398:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
  80039a:	ff8a3603          	ld	a2,-8(s4)
            goto number;
  80039e:	bfb5                	j	80031a <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
  8003a0:	000a3403          	ld	s0,0(s4)
  8003a4:	008a0713          	addi	a4,s4,8
  8003a8:	e03a                	sd	a4,0(sp)
  8003aa:	14040263          	beqz	s0,8004ee <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
  8003ae:	0fb05763          	blez	s11,80049c <vprintfmt+0x2d8>
  8003b2:	02d00693          	li	a3,45
  8003b6:	0cd79163          	bne	a5,a3,800478 <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  8003ba:	00044783          	lbu	a5,0(s0)
  8003be:	0007851b          	sext.w	a0,a5
  8003c2:	cf85                	beqz	a5,8003fa <vprintfmt+0x236>
  8003c4:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
  8003c8:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  8003cc:	000c4563          	bltz	s8,8003d6 <vprintfmt+0x212>
  8003d0:	3c7d                	addiw	s8,s8,-1
  8003d2:	036c0263          	beq	s8,s6,8003f6 <vprintfmt+0x232>
                    putch('?', putdat);
  8003d6:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
  8003d8:	0e0c8e63          	beqz	s9,8004d4 <vprintfmt+0x310>
  8003dc:	3781                	addiw	a5,a5,-32
  8003de:	0ef47b63          	bgeu	s0,a5,8004d4 <vprintfmt+0x310>
                    putch('?', putdat);
  8003e2:	03f00513          	li	a0,63
  8003e6:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  8003e8:	000a4783          	lbu	a5,0(s4)
  8003ec:	3dfd                	addiw	s11,s11,-1
  8003ee:	0a05                	addi	s4,s4,1
  8003f0:	0007851b          	sext.w	a0,a5
  8003f4:	ffe1                	bnez	a5,8003cc <vprintfmt+0x208>
            for (; width > 0; width --) {
  8003f6:	01b05963          	blez	s11,800408 <vprintfmt+0x244>
  8003fa:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
  8003fc:	85a6                	mv	a1,s1
  8003fe:	02000513          	li	a0,32
  800402:	9902                	jalr	s2
            for (; width > 0; width --) {
  800404:	fe0d9be3          	bnez	s11,8003fa <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
  800408:	6a02                	ld	s4,0(sp)
  80040a:	bbd5                	j	8001fe <vprintfmt+0x3a>
    if (lflag >= 2) {
  80040c:	4705                	li	a4,1
            precision = va_arg(ap, int);
  80040e:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
  800412:	01174463          	blt	a4,a7,80041a <vprintfmt+0x256>
    else if (lflag) {
  800416:	08088d63          	beqz	a7,8004b0 <vprintfmt+0x2ec>
        return va_arg(*ap, long);
  80041a:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
  80041e:	0a044d63          	bltz	s0,8004d8 <vprintfmt+0x314>
            num = getint(&ap, lflag);
  800422:	8622                	mv	a2,s0
  800424:	8a66                	mv	s4,s9
  800426:	46a9                	li	a3,10
  800428:	bdcd                	j	80031a <vprintfmt+0x156>
            err = va_arg(ap, int);
  80042a:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
  80042e:	4761                	li	a4,24
            err = va_arg(ap, int);
  800430:	0a21                	addi	s4,s4,8
            if (err < 0) {
  800432:	41f7d69b          	sraiw	a3,a5,0x1f
  800436:	8fb5                	xor	a5,a5,a3
  800438:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
  80043c:	02d74163          	blt	a4,a3,80045e <vprintfmt+0x29a>
  800440:	00369793          	slli	a5,a3,0x3
  800444:	97de                	add	a5,a5,s7
  800446:	639c                	ld	a5,0(a5)
  800448:	cb99                	beqz	a5,80045e <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
  80044a:	86be                	mv	a3,a5
  80044c:	00000617          	auipc	a2,0x0
  800450:	20c60613          	addi	a2,a2,524 # 800658 <main+0xf6>
  800454:	85a6                	mv	a1,s1
  800456:	854a                	mv	a0,s2
  800458:	0ce000ef          	jal	ra,800526 <printfmt>
  80045c:	b34d                	j	8001fe <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
  80045e:	00000617          	auipc	a2,0x0
  800462:	1ea60613          	addi	a2,a2,490 # 800648 <main+0xe6>
  800466:	85a6                	mv	a1,s1
  800468:	854a                	mv	a0,s2
  80046a:	0bc000ef          	jal	ra,800526 <printfmt>
  80046e:	bb41                	j	8001fe <vprintfmt+0x3a>
                p = "(null)";
  800470:	00000417          	auipc	s0,0x0
  800474:	1d040413          	addi	s0,s0,464 # 800640 <main+0xde>
                for (width -= strnlen(p, precision); width > 0; width --) {
  800478:	85e2                	mv	a1,s8
  80047a:	8522                	mv	a0,s0
  80047c:	e43e                	sd	a5,8(sp)
  80047e:	0c8000ef          	jal	ra,800546 <strnlen>
  800482:	40ad8dbb          	subw	s11,s11,a0
  800486:	01b05b63          	blez	s11,80049c <vprintfmt+0x2d8>
                    putch(padc, putdat);
  80048a:	67a2                	ld	a5,8(sp)
  80048c:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
  800490:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
  800492:	85a6                	mv	a1,s1
  800494:	8552                	mv	a0,s4
  800496:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
  800498:	fe0d9ce3          	bnez	s11,800490 <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  80049c:	00044783          	lbu	a5,0(s0)
  8004a0:	00140a13          	addi	s4,s0,1
  8004a4:	0007851b          	sext.w	a0,a5
  8004a8:	d3a5                	beqz	a5,800408 <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
  8004aa:	05e00413          	li	s0,94
  8004ae:	bf39                	j	8003cc <vprintfmt+0x208>
        return va_arg(*ap, int);
  8004b0:	000a2403          	lw	s0,0(s4)
  8004b4:	b7ad                	j	80041e <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
  8004b6:	000a6603          	lwu	a2,0(s4)
  8004ba:	46a1                	li	a3,8
  8004bc:	8a2e                	mv	s4,a1
  8004be:	bdb1                	j	80031a <vprintfmt+0x156>
  8004c0:	000a6603          	lwu	a2,0(s4)
  8004c4:	46a9                	li	a3,10
  8004c6:	8a2e                	mv	s4,a1
  8004c8:	bd89                	j	80031a <vprintfmt+0x156>
  8004ca:	000a6603          	lwu	a2,0(s4)
  8004ce:	46c1                	li	a3,16
  8004d0:	8a2e                	mv	s4,a1
  8004d2:	b5a1                	j	80031a <vprintfmt+0x156>
                    putch(ch, putdat);
  8004d4:	9902                	jalr	s2
  8004d6:	bf09                	j	8003e8 <vprintfmt+0x224>
                putch('-', putdat);
  8004d8:	85a6                	mv	a1,s1
  8004da:	02d00513          	li	a0,45
  8004de:	e03e                	sd	a5,0(sp)
  8004e0:	9902                	jalr	s2
                num = -(long long)num;
  8004e2:	6782                	ld	a5,0(sp)
  8004e4:	8a66                	mv	s4,s9
  8004e6:	40800633          	neg	a2,s0
  8004ea:	46a9                	li	a3,10
  8004ec:	b53d                	j	80031a <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
  8004ee:	03b05163          	blez	s11,800510 <vprintfmt+0x34c>
  8004f2:	02d00693          	li	a3,45
  8004f6:	f6d79de3          	bne	a5,a3,800470 <vprintfmt+0x2ac>
                p = "(null)";
  8004fa:	00000417          	auipc	s0,0x0
  8004fe:	14640413          	addi	s0,s0,326 # 800640 <main+0xde>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  800502:	02800793          	li	a5,40
  800506:	02800513          	li	a0,40
  80050a:	00140a13          	addi	s4,s0,1
  80050e:	bd6d                	j	8003c8 <vprintfmt+0x204>
  800510:	00000a17          	auipc	s4,0x0
  800514:	131a0a13          	addi	s4,s4,305 # 800641 <main+0xdf>
  800518:	02800513          	li	a0,40
  80051c:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
  800520:	05e00413          	li	s0,94
  800524:	b565                	j	8003cc <vprintfmt+0x208>

0000000000800526 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
  800526:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
  800528:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
  80052c:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
  80052e:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
  800530:	ec06                	sd	ra,24(sp)
  800532:	f83a                	sd	a4,48(sp)
  800534:	fc3e                	sd	a5,56(sp)
  800536:	e0c2                	sd	a6,64(sp)
  800538:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
  80053a:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
  80053c:	c89ff0ef          	jal	ra,8001c4 <vprintfmt>
}
  800540:	60e2                	ld	ra,24(sp)
  800542:	6161                	addi	sp,sp,80
  800544:	8082                	ret

0000000000800546 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
  800546:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
  800548:	e589                	bnez	a1,800552 <strnlen+0xc>
  80054a:	a811                	j	80055e <strnlen+0x18>
        cnt ++;
  80054c:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
  80054e:	00f58863          	beq	a1,a5,80055e <strnlen+0x18>
  800552:	00f50733          	add	a4,a0,a5
  800556:	00074703          	lbu	a4,0(a4)
  80055a:	fb6d                	bnez	a4,80054c <strnlen+0x6>
  80055c:	85be                	mv	a1,a5
    }
    return cnt;
}
  80055e:	852e                	mv	a0,a1
  800560:	8082                	ret

0000000000800562 <main>:
#include <stdio.h>
#include <ulib.h>

int
main(void) {
  800562:	1141                	addi	sp,sp,-16
  800564:	e406                	sd	ra,8(sp)
  800566:	e022                	sd	s0,0(sp)
    int pid;
    if ((pid = fork()) == 0) {
  800568:	bdbff0ef          	jal	ra,800142 <fork>
  80056c:	c51d                	beqz	a0,80059a <main+0x38>
  80056e:	842a                	mv	s0,a0
        sleep(~0);
        exit(0xdead);
    }
    assert(pid > 0);
  800570:	04a05c63          	blez	a0,8005c8 <main+0x66>

    sleep(100);
  800574:	06400513          	li	a0,100
  800578:	bcfff0ef          	jal	ra,800146 <sleep>
    assert(kill(pid) == 0);
  80057c:	8522                	mv	a0,s0
  80057e:	bc7ff0ef          	jal	ra,800144 <kill>
  800582:	e505                	bnez	a0,8005aa <main+0x48>
    cprintf("sleepkill pass.\n");
  800584:	00000517          	auipc	a0,0x0
  800588:	40450513          	addi	a0,a0,1028 # 800988 <error_string+0x110>
  80058c:	b17ff0ef          	jal	ra,8000a2 <cprintf>
    return 0;
}
  800590:	60a2                	ld	ra,8(sp)
  800592:	6402                	ld	s0,0(sp)
  800594:	4501                	li	a0,0
  800596:	0141                	addi	sp,sp,16
  800598:	8082                	ret
        sleep(~0);
  80059a:	557d                	li	a0,-1
  80059c:	babff0ef          	jal	ra,800146 <sleep>
        exit(0xdead);
  8005a0:	6539                	lui	a0,0xe
  8005a2:	ead50513          	addi	a0,a0,-339 # dead <_start-0x7f2173>
  8005a6:	b87ff0ef          	jal	ra,80012c <exit>
    assert(kill(pid) == 0);
  8005aa:	00000697          	auipc	a3,0x0
  8005ae:	3ce68693          	addi	a3,a3,974 # 800978 <error_string+0x100>
  8005b2:	00000617          	auipc	a2,0x0
  8005b6:	39660613          	addi	a2,a2,918 # 800948 <error_string+0xd0>
  8005ba:	45b9                	li	a1,14
  8005bc:	00000517          	auipc	a0,0x0
  8005c0:	3a450513          	addi	a0,a0,932 # 800960 <error_string+0xe8>
  8005c4:	a63ff0ef          	jal	ra,800026 <__panic>
    assert(pid > 0);
  8005c8:	00000697          	auipc	a3,0x0
  8005cc:	37868693          	addi	a3,a3,888 # 800940 <error_string+0xc8>
  8005d0:	00000617          	auipc	a2,0x0
  8005d4:	37860613          	addi	a2,a2,888 # 800948 <error_string+0xd0>
  8005d8:	45ad                	li	a1,11
  8005da:	00000517          	auipc	a0,0x0
  8005de:	38650513          	addi	a0,a0,902 # 800960 <error_string+0xe8>
  8005e2:	a45ff0ef          	jal	ra,800026 <__panic>
