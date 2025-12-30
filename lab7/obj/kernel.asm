
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	0000d297          	auipc	t0,0xd
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc020d000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	0000d297          	auipc	t0,0xd
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc020d008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)

    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c020c2b7          	lui	t0,0xc020c
    # t1 := 0xffffffff40000000 即虚实映射偏移量
    li      t1, 0xffffffffc0000000 - 0x80000000
ffffffffc020001c:	ffd0031b          	addiw	t1,zero,-3
ffffffffc0200020:	037a                	slli	t1,t1,0x1e
    # t0 减去虚实映射偏移量 0xffffffff40000000，变为三级页表的物理地址
    sub     t0, t0, t1
ffffffffc0200022:	406282b3          	sub	t0,t0,t1
    # t0 >>= 12，变为三级页表的物理页号
    srli    t0, t0, 12
ffffffffc0200026:	00c2d293          	srli	t0,t0,0xc

    # t1 := 8 << 60，设置 satp 的 MODE 字段为 Sv39
    li      t1, 8 << 60
ffffffffc020002a:	fff0031b          	addiw	t1,zero,-1
ffffffffc020002e:	137e                	slli	t1,t1,0x3f
    # 将刚才计算出的预设三级页表物理页号附加到 satp 中
    or      t0, t0, t1
ffffffffc0200030:	0062e2b3          	or	t0,t0,t1
    # 将算出的 t0(即新的MODE|页表基址物理页号) 覆盖到 satp 中
    csrw    satp, t0
ffffffffc0200034:	18029073          	csrw	satp,t0
    # 使用 sfence.vma 指令刷新 TLB
    sfence.vma
ffffffffc0200038:	12000073          	sfence.vma
    # 从此，我们给内核搭建出了一个完美的虚拟内存空间！
    #nop # 可能映射的位置有些bug。。插入一个nop
    
    # 我们在虚拟内存空间中：随意将 sp 设置为虚拟地址！
    lui sp, %hi(bootstacktop)
ffffffffc020003c:	c020c137          	lui	sp,0xc020c

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc0200040:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc0200044:	04a28293          	addi	t0,t0,74 # ffffffffc020004a <kern_init>
    jr t0
ffffffffc0200048:	8282                	jr	t0

ffffffffc020004a <kern_init>:
void grade_backtrace(void);

int kern_init(void)
{
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc020004a:	000db517          	auipc	a0,0xdb
ffffffffc020004e:	62650513          	addi	a0,a0,1574 # ffffffffc02db670 <buf>
ffffffffc0200052:	000e0617          	auipc	a2,0xe0
ffffffffc0200056:	c4e60613          	addi	a2,a2,-946 # ffffffffc02dfca0 <end>
{
ffffffffc020005a:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc020005c:	8e09                	sub	a2,a2,a0
ffffffffc020005e:	4581                	li	a1,0
{
ffffffffc0200060:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc0200062:	3f6060ef          	jal	ra,ffffffffc0206458 <memset>
    cons_init(); // init the console
ffffffffc0200066:	520000ef          	jal	ra,ffffffffc0200586 <cons_init>

    const char *message = "(THU.CST) os is loading ...";
    cprintf("%s\n\n", message);
ffffffffc020006a:	00006597          	auipc	a1,0x6
ffffffffc020006e:	41e58593          	addi	a1,a1,1054 # ffffffffc0206488 <etext+0x6>
ffffffffc0200072:	00006517          	auipc	a0,0x6
ffffffffc0200076:	43650513          	addi	a0,a0,1078 # ffffffffc02064a8 <etext+0x26>
ffffffffc020007a:	11e000ef          	jal	ra,ffffffffc0200198 <cprintf>

    print_kerninfo();
ffffffffc020007e:	1a2000ef          	jal	ra,ffffffffc0200220 <print_kerninfo>

    // grade_backtrace();

    dtb_init(); // init dtb
ffffffffc0200082:	576000ef          	jal	ra,ffffffffc02005f8 <dtb_init>
    pmm_init(); // init physical memory management
ffffffffc0200086:	590020ef          	jal	ra,ffffffffc0202616 <pmm_init>

    pic_init(); // init interrupt controller
ffffffffc020008a:	12b000ef          	jal	ra,ffffffffc02009b4 <pic_init>
    idt_init(); // init interrupt descriptor table
ffffffffc020008e:	129000ef          	jal	ra,ffffffffc02009b6 <idt_init>

    vmm_init(); // init virtual memory management
ffffffffc0200092:	08d030ef          	jal	ra,ffffffffc020391e <vmm_init>
    sched_init();
ffffffffc0200096:	1c7050ef          	jal	ra,ffffffffc0205a5c <sched_init>
    proc_init(); // init process table
ffffffffc020009a:	646050ef          	jal	ra,ffffffffc02056e0 <proc_init>

    clock_init();  // init clock interrupt
ffffffffc020009e:	4a0000ef          	jal	ra,ffffffffc020053e <clock_init>
    intr_enable(); // enable irq interrupt
ffffffffc02000a2:	107000ef          	jal	ra,ffffffffc02009a8 <intr_enable>

    cpu_idle(); // run idle process
ffffffffc02000a6:	7d2050ef          	jal	ra,ffffffffc0205878 <cpu_idle>

ffffffffc02000aa <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc02000aa:	715d                	addi	sp,sp,-80
ffffffffc02000ac:	e486                	sd	ra,72(sp)
ffffffffc02000ae:	e0a6                	sd	s1,64(sp)
ffffffffc02000b0:	fc4a                	sd	s2,56(sp)
ffffffffc02000b2:	f84e                	sd	s3,48(sp)
ffffffffc02000b4:	f452                	sd	s4,40(sp)
ffffffffc02000b6:	f056                	sd	s5,32(sp)
ffffffffc02000b8:	ec5a                	sd	s6,24(sp)
ffffffffc02000ba:	e85e                	sd	s7,16(sp)
    if (prompt != NULL) {
ffffffffc02000bc:	c901                	beqz	a0,ffffffffc02000cc <readline+0x22>
ffffffffc02000be:	85aa                	mv	a1,a0
        cprintf("%s", prompt);
ffffffffc02000c0:	00006517          	auipc	a0,0x6
ffffffffc02000c4:	3f050513          	addi	a0,a0,1008 # ffffffffc02064b0 <etext+0x2e>
ffffffffc02000c8:	0d0000ef          	jal	ra,ffffffffc0200198 <cprintf>
readline(const char *prompt) {
ffffffffc02000cc:	4481                	li	s1,0
    while (1) {
        c = getchar();
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000ce:	497d                	li	s2,31
            cputchar(c);
            buf[i ++] = c;
        }
        else if (c == '\b' && i > 0) {
ffffffffc02000d0:	49a1                	li	s3,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc02000d2:	4aa9                	li	s5,10
ffffffffc02000d4:	4b35                	li	s6,13
            buf[i ++] = c;
ffffffffc02000d6:	000dbb97          	auipc	s7,0xdb
ffffffffc02000da:	59ab8b93          	addi	s7,s7,1434 # ffffffffc02db670 <buf>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000de:	3fe00a13          	li	s4,1022
        c = getchar();
ffffffffc02000e2:	12e000ef          	jal	ra,ffffffffc0200210 <getchar>
        if (c < 0) {
ffffffffc02000e6:	00054a63          	bltz	a0,ffffffffc02000fa <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000ea:	00a95a63          	bge	s2,a0,ffffffffc02000fe <readline+0x54>
ffffffffc02000ee:	029a5263          	bge	s4,s1,ffffffffc0200112 <readline+0x68>
        c = getchar();
ffffffffc02000f2:	11e000ef          	jal	ra,ffffffffc0200210 <getchar>
        if (c < 0) {
ffffffffc02000f6:	fe055ae3          	bgez	a0,ffffffffc02000ea <readline+0x40>
            return NULL;
ffffffffc02000fa:	4501                	li	a0,0
ffffffffc02000fc:	a091                	j	ffffffffc0200140 <readline+0x96>
        else if (c == '\b' && i > 0) {
ffffffffc02000fe:	03351463          	bne	a0,s3,ffffffffc0200126 <readline+0x7c>
ffffffffc0200102:	e8a9                	bnez	s1,ffffffffc0200154 <readline+0xaa>
        c = getchar();
ffffffffc0200104:	10c000ef          	jal	ra,ffffffffc0200210 <getchar>
        if (c < 0) {
ffffffffc0200108:	fe0549e3          	bltz	a0,ffffffffc02000fa <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc020010c:	fea959e3          	bge	s2,a0,ffffffffc02000fe <readline+0x54>
ffffffffc0200110:	4481                	li	s1,0
            cputchar(c);
ffffffffc0200112:	e42a                	sd	a0,8(sp)
ffffffffc0200114:	0ba000ef          	jal	ra,ffffffffc02001ce <cputchar>
            buf[i ++] = c;
ffffffffc0200118:	6522                	ld	a0,8(sp)
ffffffffc020011a:	009b87b3          	add	a5,s7,s1
ffffffffc020011e:	2485                	addiw	s1,s1,1
ffffffffc0200120:	00a78023          	sb	a0,0(a5)
ffffffffc0200124:	bf7d                	j	ffffffffc02000e2 <readline+0x38>
        else if (c == '\n' || c == '\r') {
ffffffffc0200126:	01550463          	beq	a0,s5,ffffffffc020012e <readline+0x84>
ffffffffc020012a:	fb651ce3          	bne	a0,s6,ffffffffc02000e2 <readline+0x38>
            cputchar(c);
ffffffffc020012e:	0a0000ef          	jal	ra,ffffffffc02001ce <cputchar>
            buf[i] = '\0';
ffffffffc0200132:	000db517          	auipc	a0,0xdb
ffffffffc0200136:	53e50513          	addi	a0,a0,1342 # ffffffffc02db670 <buf>
ffffffffc020013a:	94aa                	add	s1,s1,a0
ffffffffc020013c:	00048023          	sb	zero,0(s1)
            return buf;
        }
    }
}
ffffffffc0200140:	60a6                	ld	ra,72(sp)
ffffffffc0200142:	6486                	ld	s1,64(sp)
ffffffffc0200144:	7962                	ld	s2,56(sp)
ffffffffc0200146:	79c2                	ld	s3,48(sp)
ffffffffc0200148:	7a22                	ld	s4,40(sp)
ffffffffc020014a:	7a82                	ld	s5,32(sp)
ffffffffc020014c:	6b62                	ld	s6,24(sp)
ffffffffc020014e:	6bc2                	ld	s7,16(sp)
ffffffffc0200150:	6161                	addi	sp,sp,80
ffffffffc0200152:	8082                	ret
            cputchar(c);
ffffffffc0200154:	4521                	li	a0,8
ffffffffc0200156:	078000ef          	jal	ra,ffffffffc02001ce <cputchar>
            i --;
ffffffffc020015a:	34fd                	addiw	s1,s1,-1
ffffffffc020015c:	b759                	j	ffffffffc02000e2 <readline+0x38>

ffffffffc020015e <cputch>:
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt)
{
ffffffffc020015e:	1141                	addi	sp,sp,-16
ffffffffc0200160:	e022                	sd	s0,0(sp)
ffffffffc0200162:	e406                	sd	ra,8(sp)
ffffffffc0200164:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc0200166:	422000ef          	jal	ra,ffffffffc0200588 <cons_putc>
    (*cnt)++;
ffffffffc020016a:	401c                	lw	a5,0(s0)
}
ffffffffc020016c:	60a2                	ld	ra,8(sp)
    (*cnt)++;
ffffffffc020016e:	2785                	addiw	a5,a5,1
ffffffffc0200170:	c01c                	sw	a5,0(s0)
}
ffffffffc0200172:	6402                	ld	s0,0(sp)
ffffffffc0200174:	0141                	addi	sp,sp,16
ffffffffc0200176:	8082                	ret

ffffffffc0200178 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int vcprintf(const char *fmt, va_list ap)
{
ffffffffc0200178:	1101                	addi	sp,sp,-32
ffffffffc020017a:	862a                	mv	a2,a0
ffffffffc020017c:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc020017e:	00000517          	auipc	a0,0x0
ffffffffc0200182:	fe050513          	addi	a0,a0,-32 # ffffffffc020015e <cputch>
ffffffffc0200186:	006c                	addi	a1,sp,12
{
ffffffffc0200188:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc020018a:	c602                	sw	zero,12(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc020018c:	6a9050ef          	jal	ra,ffffffffc0206034 <vprintfmt>
    return cnt;
}
ffffffffc0200190:	60e2                	ld	ra,24(sp)
ffffffffc0200192:	4532                	lw	a0,12(sp)
ffffffffc0200194:	6105                	addi	sp,sp,32
ffffffffc0200196:	8082                	ret

ffffffffc0200198 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int cprintf(const char *fmt, ...)
{
ffffffffc0200198:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc020019a:	02810313          	addi	t1,sp,40 # ffffffffc020c028 <boot_page_table_sv39+0x28>
{
ffffffffc020019e:	8e2a                	mv	t3,a0
ffffffffc02001a0:	f42e                	sd	a1,40(sp)
ffffffffc02001a2:	f832                	sd	a2,48(sp)
ffffffffc02001a4:	fc36                	sd	a3,56(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc02001a6:	00000517          	auipc	a0,0x0
ffffffffc02001aa:	fb850513          	addi	a0,a0,-72 # ffffffffc020015e <cputch>
ffffffffc02001ae:	004c                	addi	a1,sp,4
ffffffffc02001b0:	869a                	mv	a3,t1
ffffffffc02001b2:	8672                	mv	a2,t3
{
ffffffffc02001b4:	ec06                	sd	ra,24(sp)
ffffffffc02001b6:	e0ba                	sd	a4,64(sp)
ffffffffc02001b8:	e4be                	sd	a5,72(sp)
ffffffffc02001ba:	e8c2                	sd	a6,80(sp)
ffffffffc02001bc:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc02001be:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc02001c0:	c202                	sw	zero,4(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc02001c2:	673050ef          	jal	ra,ffffffffc0206034 <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc02001c6:	60e2                	ld	ra,24(sp)
ffffffffc02001c8:	4512                	lw	a0,4(sp)
ffffffffc02001ca:	6125                	addi	sp,sp,96
ffffffffc02001cc:	8082                	ret

ffffffffc02001ce <cputchar>:

/* cputchar - writes a single character to stdout */
void cputchar(int c)
{
    cons_putc(c);
ffffffffc02001ce:	ae6d                	j	ffffffffc0200588 <cons_putc>

ffffffffc02001d0 <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int cputs(const char *str)
{
ffffffffc02001d0:	1101                	addi	sp,sp,-32
ffffffffc02001d2:	e822                	sd	s0,16(sp)
ffffffffc02001d4:	ec06                	sd	ra,24(sp)
ffffffffc02001d6:	e426                	sd	s1,8(sp)
ffffffffc02001d8:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str++) != '\0')
ffffffffc02001da:	00054503          	lbu	a0,0(a0)
ffffffffc02001de:	c51d                	beqz	a0,ffffffffc020020c <cputs+0x3c>
ffffffffc02001e0:	0405                	addi	s0,s0,1
ffffffffc02001e2:	4485                	li	s1,1
ffffffffc02001e4:	9c81                	subw	s1,s1,s0
    cons_putc(c);
ffffffffc02001e6:	3a2000ef          	jal	ra,ffffffffc0200588 <cons_putc>
    while ((c = *str++) != '\0')
ffffffffc02001ea:	00044503          	lbu	a0,0(s0)
ffffffffc02001ee:	008487bb          	addw	a5,s1,s0
ffffffffc02001f2:	0405                	addi	s0,s0,1
ffffffffc02001f4:	f96d                	bnez	a0,ffffffffc02001e6 <cputs+0x16>
    (*cnt)++;
ffffffffc02001f6:	0017841b          	addiw	s0,a5,1
    cons_putc(c);
ffffffffc02001fa:	4529                	li	a0,10
ffffffffc02001fc:	38c000ef          	jal	ra,ffffffffc0200588 <cons_putc>
    {
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc0200200:	60e2                	ld	ra,24(sp)
ffffffffc0200202:	8522                	mv	a0,s0
ffffffffc0200204:	6442                	ld	s0,16(sp)
ffffffffc0200206:	64a2                	ld	s1,8(sp)
ffffffffc0200208:	6105                	addi	sp,sp,32
ffffffffc020020a:	8082                	ret
    while ((c = *str++) != '\0')
ffffffffc020020c:	4405                	li	s0,1
ffffffffc020020e:	b7f5                	j	ffffffffc02001fa <cputs+0x2a>

ffffffffc0200210 <getchar>:

/* getchar - reads a single non-zero character from stdin */
int getchar(void)
{
ffffffffc0200210:	1141                	addi	sp,sp,-16
ffffffffc0200212:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc0200214:	3a8000ef          	jal	ra,ffffffffc02005bc <cons_getc>
ffffffffc0200218:	dd75                	beqz	a0,ffffffffc0200214 <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc020021a:	60a2                	ld	ra,8(sp)
ffffffffc020021c:	0141                	addi	sp,sp,16
ffffffffc020021e:	8082                	ret

ffffffffc0200220 <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc0200220:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc0200222:	00006517          	auipc	a0,0x6
ffffffffc0200226:	29650513          	addi	a0,a0,662 # ffffffffc02064b8 <etext+0x36>
void print_kerninfo(void) {
ffffffffc020022a:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc020022c:	f6dff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  entry  0x%08x (virtual)\n", kern_init);
ffffffffc0200230:	00000597          	auipc	a1,0x0
ffffffffc0200234:	e1a58593          	addi	a1,a1,-486 # ffffffffc020004a <kern_init>
ffffffffc0200238:	00006517          	auipc	a0,0x6
ffffffffc020023c:	2a050513          	addi	a0,a0,672 # ffffffffc02064d8 <etext+0x56>
ffffffffc0200240:	f59ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  etext  0x%08x (virtual)\n", etext);
ffffffffc0200244:	00006597          	auipc	a1,0x6
ffffffffc0200248:	23e58593          	addi	a1,a1,574 # ffffffffc0206482 <etext>
ffffffffc020024c:	00006517          	auipc	a0,0x6
ffffffffc0200250:	2ac50513          	addi	a0,a0,684 # ffffffffc02064f8 <etext+0x76>
ffffffffc0200254:	f45ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  edata  0x%08x (virtual)\n", edata);
ffffffffc0200258:	000db597          	auipc	a1,0xdb
ffffffffc020025c:	41858593          	addi	a1,a1,1048 # ffffffffc02db670 <buf>
ffffffffc0200260:	00006517          	auipc	a0,0x6
ffffffffc0200264:	2b850513          	addi	a0,a0,696 # ffffffffc0206518 <etext+0x96>
ffffffffc0200268:	f31ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  end    0x%08x (virtual)\n", end);
ffffffffc020026c:	000e0597          	auipc	a1,0xe0
ffffffffc0200270:	a3458593          	addi	a1,a1,-1484 # ffffffffc02dfca0 <end>
ffffffffc0200274:	00006517          	auipc	a0,0x6
ffffffffc0200278:	2c450513          	addi	a0,a0,708 # ffffffffc0206538 <etext+0xb6>
ffffffffc020027c:	f1dff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc0200280:	000e0597          	auipc	a1,0xe0
ffffffffc0200284:	e1f58593          	addi	a1,a1,-481 # ffffffffc02e009f <end+0x3ff>
ffffffffc0200288:	00000797          	auipc	a5,0x0
ffffffffc020028c:	dc278793          	addi	a5,a5,-574 # ffffffffc020004a <kern_init>
ffffffffc0200290:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200294:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc0200298:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc020029a:	3ff5f593          	andi	a1,a1,1023
ffffffffc020029e:	95be                	add	a1,a1,a5
ffffffffc02002a0:	85a9                	srai	a1,a1,0xa
ffffffffc02002a2:	00006517          	auipc	a0,0x6
ffffffffc02002a6:	2b650513          	addi	a0,a0,694 # ffffffffc0206558 <etext+0xd6>
}
ffffffffc02002aa:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02002ac:	b5f5                	j	ffffffffc0200198 <cprintf>

ffffffffc02002ae <print_stackframe>:
 * Note that, the length of ebp-chain is limited. In boot/bootasm.S, before
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void) {
ffffffffc02002ae:	1141                	addi	sp,sp,-16
    
    panic("Not Implemented!");
ffffffffc02002b0:	00006617          	auipc	a2,0x6
ffffffffc02002b4:	2d860613          	addi	a2,a2,728 # ffffffffc0206588 <etext+0x106>
ffffffffc02002b8:	04e00593          	li	a1,78
ffffffffc02002bc:	00006517          	auipc	a0,0x6
ffffffffc02002c0:	2e450513          	addi	a0,a0,740 # ffffffffc02065a0 <etext+0x11e>
void print_stackframe(void) {
ffffffffc02002c4:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc02002c6:	1cc000ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc02002ca <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002ca:	1141                	addi	sp,sp,-16
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02002cc:	00006617          	auipc	a2,0x6
ffffffffc02002d0:	2ec60613          	addi	a2,a2,748 # ffffffffc02065b8 <etext+0x136>
ffffffffc02002d4:	00006597          	auipc	a1,0x6
ffffffffc02002d8:	30458593          	addi	a1,a1,772 # ffffffffc02065d8 <etext+0x156>
ffffffffc02002dc:	00006517          	auipc	a0,0x6
ffffffffc02002e0:	30450513          	addi	a0,a0,772 # ffffffffc02065e0 <etext+0x15e>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002e4:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02002e6:	eb3ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
ffffffffc02002ea:	00006617          	auipc	a2,0x6
ffffffffc02002ee:	30660613          	addi	a2,a2,774 # ffffffffc02065f0 <etext+0x16e>
ffffffffc02002f2:	00006597          	auipc	a1,0x6
ffffffffc02002f6:	32658593          	addi	a1,a1,806 # ffffffffc0206618 <etext+0x196>
ffffffffc02002fa:	00006517          	auipc	a0,0x6
ffffffffc02002fe:	2e650513          	addi	a0,a0,742 # ffffffffc02065e0 <etext+0x15e>
ffffffffc0200302:	e97ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
ffffffffc0200306:	00006617          	auipc	a2,0x6
ffffffffc020030a:	32260613          	addi	a2,a2,802 # ffffffffc0206628 <etext+0x1a6>
ffffffffc020030e:	00006597          	auipc	a1,0x6
ffffffffc0200312:	33a58593          	addi	a1,a1,826 # ffffffffc0206648 <etext+0x1c6>
ffffffffc0200316:	00006517          	auipc	a0,0x6
ffffffffc020031a:	2ca50513          	addi	a0,a0,714 # ffffffffc02065e0 <etext+0x15e>
ffffffffc020031e:	e7bff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    }
    return 0;
}
ffffffffc0200322:	60a2                	ld	ra,8(sp)
ffffffffc0200324:	4501                	li	a0,0
ffffffffc0200326:	0141                	addi	sp,sp,16
ffffffffc0200328:	8082                	ret

ffffffffc020032a <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
ffffffffc020032a:	1141                	addi	sp,sp,-16
ffffffffc020032c:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc020032e:	ef3ff0ef          	jal	ra,ffffffffc0200220 <print_kerninfo>
    return 0;
}
ffffffffc0200332:	60a2                	ld	ra,8(sp)
ffffffffc0200334:	4501                	li	a0,0
ffffffffc0200336:	0141                	addi	sp,sp,16
ffffffffc0200338:	8082                	ret

ffffffffc020033a <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
ffffffffc020033a:	1141                	addi	sp,sp,-16
ffffffffc020033c:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc020033e:	f71ff0ef          	jal	ra,ffffffffc02002ae <print_stackframe>
    return 0;
}
ffffffffc0200342:	60a2                	ld	ra,8(sp)
ffffffffc0200344:	4501                	li	a0,0
ffffffffc0200346:	0141                	addi	sp,sp,16
ffffffffc0200348:	8082                	ret

ffffffffc020034a <kmonitor>:
kmonitor(struct trapframe *tf) {
ffffffffc020034a:	7115                	addi	sp,sp,-224
ffffffffc020034c:	ed5e                	sd	s7,152(sp)
ffffffffc020034e:	8baa                	mv	s7,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc0200350:	00006517          	auipc	a0,0x6
ffffffffc0200354:	30850513          	addi	a0,a0,776 # ffffffffc0206658 <etext+0x1d6>
kmonitor(struct trapframe *tf) {
ffffffffc0200358:	ed86                	sd	ra,216(sp)
ffffffffc020035a:	e9a2                	sd	s0,208(sp)
ffffffffc020035c:	e5a6                	sd	s1,200(sp)
ffffffffc020035e:	e1ca                	sd	s2,192(sp)
ffffffffc0200360:	fd4e                	sd	s3,184(sp)
ffffffffc0200362:	f952                	sd	s4,176(sp)
ffffffffc0200364:	f556                	sd	s5,168(sp)
ffffffffc0200366:	f15a                	sd	s6,160(sp)
ffffffffc0200368:	e962                	sd	s8,144(sp)
ffffffffc020036a:	e566                	sd	s9,136(sp)
ffffffffc020036c:	e16a                	sd	s10,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc020036e:	e2bff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc0200372:	00006517          	auipc	a0,0x6
ffffffffc0200376:	30e50513          	addi	a0,a0,782 # ffffffffc0206680 <etext+0x1fe>
ffffffffc020037a:	e1fff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    if (tf != NULL) {
ffffffffc020037e:	000b8563          	beqz	s7,ffffffffc0200388 <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc0200382:	855e                	mv	a0,s7
ffffffffc0200384:	01b000ef          	jal	ra,ffffffffc0200b9e <print_trapframe>
ffffffffc0200388:	00006c17          	auipc	s8,0x6
ffffffffc020038c:	368c0c13          	addi	s8,s8,872 # ffffffffc02066f0 <commands>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc0200390:	00006917          	auipc	s2,0x6
ffffffffc0200394:	31890913          	addi	s2,s2,792 # ffffffffc02066a8 <etext+0x226>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200398:	00006497          	auipc	s1,0x6
ffffffffc020039c:	31848493          	addi	s1,s1,792 # ffffffffc02066b0 <etext+0x22e>
        if (argc == MAXARGS - 1) {
ffffffffc02003a0:	49bd                	li	s3,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc02003a2:	00006b17          	auipc	s6,0x6
ffffffffc02003a6:	316b0b13          	addi	s6,s6,790 # ffffffffc02066b8 <etext+0x236>
        argv[argc ++] = buf;
ffffffffc02003aa:	00006a17          	auipc	s4,0x6
ffffffffc02003ae:	22ea0a13          	addi	s4,s4,558 # ffffffffc02065d8 <etext+0x156>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02003b2:	4a8d                	li	s5,3
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02003b4:	854a                	mv	a0,s2
ffffffffc02003b6:	cf5ff0ef          	jal	ra,ffffffffc02000aa <readline>
ffffffffc02003ba:	842a                	mv	s0,a0
ffffffffc02003bc:	dd65                	beqz	a0,ffffffffc02003b4 <kmonitor+0x6a>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003be:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc02003c2:	4c81                	li	s9,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003c4:	e1bd                	bnez	a1,ffffffffc020042a <kmonitor+0xe0>
    if (argc == 0) {
ffffffffc02003c6:	fe0c87e3          	beqz	s9,ffffffffc02003b4 <kmonitor+0x6a>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02003ca:	6582                	ld	a1,0(sp)
ffffffffc02003cc:	00006d17          	auipc	s10,0x6
ffffffffc02003d0:	324d0d13          	addi	s10,s10,804 # ffffffffc02066f0 <commands>
        argv[argc ++] = buf;
ffffffffc02003d4:	8552                	mv	a0,s4
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02003d6:	4401                	li	s0,0
ffffffffc02003d8:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02003da:	024060ef          	jal	ra,ffffffffc02063fe <strcmp>
ffffffffc02003de:	c919                	beqz	a0,ffffffffc02003f4 <kmonitor+0xaa>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02003e0:	2405                	addiw	s0,s0,1
ffffffffc02003e2:	0b540063          	beq	s0,s5,ffffffffc0200482 <kmonitor+0x138>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02003e6:	000d3503          	ld	a0,0(s10)
ffffffffc02003ea:	6582                	ld	a1,0(sp)
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02003ec:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02003ee:	010060ef          	jal	ra,ffffffffc02063fe <strcmp>
ffffffffc02003f2:	f57d                	bnez	a0,ffffffffc02003e0 <kmonitor+0x96>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc02003f4:	00141793          	slli	a5,s0,0x1
ffffffffc02003f8:	97a2                	add	a5,a5,s0
ffffffffc02003fa:	078e                	slli	a5,a5,0x3
ffffffffc02003fc:	97e2                	add	a5,a5,s8
ffffffffc02003fe:	6b9c                	ld	a5,16(a5)
ffffffffc0200400:	865e                	mv	a2,s7
ffffffffc0200402:	002c                	addi	a1,sp,8
ffffffffc0200404:	fffc851b          	addiw	a0,s9,-1
ffffffffc0200408:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0) {
ffffffffc020040a:	fa0555e3          	bgez	a0,ffffffffc02003b4 <kmonitor+0x6a>
}
ffffffffc020040e:	60ee                	ld	ra,216(sp)
ffffffffc0200410:	644e                	ld	s0,208(sp)
ffffffffc0200412:	64ae                	ld	s1,200(sp)
ffffffffc0200414:	690e                	ld	s2,192(sp)
ffffffffc0200416:	79ea                	ld	s3,184(sp)
ffffffffc0200418:	7a4a                	ld	s4,176(sp)
ffffffffc020041a:	7aaa                	ld	s5,168(sp)
ffffffffc020041c:	7b0a                	ld	s6,160(sp)
ffffffffc020041e:	6bea                	ld	s7,152(sp)
ffffffffc0200420:	6c4a                	ld	s8,144(sp)
ffffffffc0200422:	6caa                	ld	s9,136(sp)
ffffffffc0200424:	6d0a                	ld	s10,128(sp)
ffffffffc0200426:	612d                	addi	sp,sp,224
ffffffffc0200428:	8082                	ret
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020042a:	8526                	mv	a0,s1
ffffffffc020042c:	016060ef          	jal	ra,ffffffffc0206442 <strchr>
ffffffffc0200430:	c901                	beqz	a0,ffffffffc0200440 <kmonitor+0xf6>
ffffffffc0200432:	00144583          	lbu	a1,1(s0)
            *buf ++ = '\0';
ffffffffc0200436:	00040023          	sb	zero,0(s0)
ffffffffc020043a:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020043c:	d5c9                	beqz	a1,ffffffffc02003c6 <kmonitor+0x7c>
ffffffffc020043e:	b7f5                	j	ffffffffc020042a <kmonitor+0xe0>
        if (*buf == '\0') {
ffffffffc0200440:	00044783          	lbu	a5,0(s0)
ffffffffc0200444:	d3c9                	beqz	a5,ffffffffc02003c6 <kmonitor+0x7c>
        if (argc == MAXARGS - 1) {
ffffffffc0200446:	033c8963          	beq	s9,s3,ffffffffc0200478 <kmonitor+0x12e>
        argv[argc ++] = buf;
ffffffffc020044a:	003c9793          	slli	a5,s9,0x3
ffffffffc020044e:	0118                	addi	a4,sp,128
ffffffffc0200450:	97ba                	add	a5,a5,a4
ffffffffc0200452:	f887b023          	sd	s0,-128(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200456:	00044583          	lbu	a1,0(s0)
        argv[argc ++] = buf;
ffffffffc020045a:	2c85                	addiw	s9,s9,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc020045c:	e591                	bnez	a1,ffffffffc0200468 <kmonitor+0x11e>
ffffffffc020045e:	b7b5                	j	ffffffffc02003ca <kmonitor+0x80>
ffffffffc0200460:	00144583          	lbu	a1,1(s0)
            buf ++;
ffffffffc0200464:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200466:	d1a5                	beqz	a1,ffffffffc02003c6 <kmonitor+0x7c>
ffffffffc0200468:	8526                	mv	a0,s1
ffffffffc020046a:	7d9050ef          	jal	ra,ffffffffc0206442 <strchr>
ffffffffc020046e:	d96d                	beqz	a0,ffffffffc0200460 <kmonitor+0x116>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200470:	00044583          	lbu	a1,0(s0)
ffffffffc0200474:	d9a9                	beqz	a1,ffffffffc02003c6 <kmonitor+0x7c>
ffffffffc0200476:	bf55                	j	ffffffffc020042a <kmonitor+0xe0>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc0200478:	45c1                	li	a1,16
ffffffffc020047a:	855a                	mv	a0,s6
ffffffffc020047c:	d1dff0ef          	jal	ra,ffffffffc0200198 <cprintf>
ffffffffc0200480:	b7e9                	j	ffffffffc020044a <kmonitor+0x100>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc0200482:	6582                	ld	a1,0(sp)
ffffffffc0200484:	00006517          	auipc	a0,0x6
ffffffffc0200488:	25450513          	addi	a0,a0,596 # ffffffffc02066d8 <etext+0x256>
ffffffffc020048c:	d0dff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    return 0;
ffffffffc0200490:	b715                	j	ffffffffc02003b4 <kmonitor+0x6a>

ffffffffc0200492 <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc0200492:	000df317          	auipc	t1,0xdf
ffffffffc0200496:	78630313          	addi	t1,t1,1926 # ffffffffc02dfc18 <is_panic>
ffffffffc020049a:	00033e03          	ld	t3,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc020049e:	715d                	addi	sp,sp,-80
ffffffffc02004a0:	ec06                	sd	ra,24(sp)
ffffffffc02004a2:	e822                	sd	s0,16(sp)
ffffffffc02004a4:	f436                	sd	a3,40(sp)
ffffffffc02004a6:	f83a                	sd	a4,48(sp)
ffffffffc02004a8:	fc3e                	sd	a5,56(sp)
ffffffffc02004aa:	e0c2                	sd	a6,64(sp)
ffffffffc02004ac:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc02004ae:	020e1a63          	bnez	t3,ffffffffc02004e2 <__panic+0x50>
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc02004b2:	4785                	li	a5,1
ffffffffc02004b4:	00f33023          	sd	a5,0(t1)

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
ffffffffc02004b8:	8432                	mv	s0,a2
ffffffffc02004ba:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02004bc:	862e                	mv	a2,a1
ffffffffc02004be:	85aa                	mv	a1,a0
ffffffffc02004c0:	00006517          	auipc	a0,0x6
ffffffffc02004c4:	27850513          	addi	a0,a0,632 # ffffffffc0206738 <commands+0x48>
    va_start(ap, fmt);
ffffffffc02004c8:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02004ca:	ccfff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    vcprintf(fmt, ap);
ffffffffc02004ce:	65a2                	ld	a1,8(sp)
ffffffffc02004d0:	8522                	mv	a0,s0
ffffffffc02004d2:	ca7ff0ef          	jal	ra,ffffffffc0200178 <vcprintf>
    cprintf("\n");
ffffffffc02004d6:	00007517          	auipc	a0,0x7
ffffffffc02004da:	35a50513          	addi	a0,a0,858 # ffffffffc0207830 <default_pmm_manager+0x578>
ffffffffc02004de:	cbbff0ef          	jal	ra,ffffffffc0200198 <cprintf>
#endif
}

static inline void sbi_shutdown(void)
{
	SBI_CALL_0(SBI_SHUTDOWN);
ffffffffc02004e2:	4501                	li	a0,0
ffffffffc02004e4:	4581                	li	a1,0
ffffffffc02004e6:	4601                	li	a2,0
ffffffffc02004e8:	48a1                	li	a7,8
ffffffffc02004ea:	00000073          	ecall
    va_end(ap);

panic_dead:
    // No debug monitor here
    sbi_shutdown();
    intr_disable();
ffffffffc02004ee:	4c0000ef          	jal	ra,ffffffffc02009ae <intr_disable>
    while (1) {
        kmonitor(NULL);
ffffffffc02004f2:	4501                	li	a0,0
ffffffffc02004f4:	e57ff0ef          	jal	ra,ffffffffc020034a <kmonitor>
    while (1) {
ffffffffc02004f8:	bfed                	j	ffffffffc02004f2 <__panic+0x60>

ffffffffc02004fa <__warn>:
    }
}

/* __warn - like panic, but don't */
void
__warn(const char *file, int line, const char *fmt, ...) {
ffffffffc02004fa:	715d                	addi	sp,sp,-80
ffffffffc02004fc:	832e                	mv	t1,a1
ffffffffc02004fe:	e822                	sd	s0,16(sp)
    va_list ap;
    va_start(ap, fmt);
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc0200500:	85aa                	mv	a1,a0
__warn(const char *file, int line, const char *fmt, ...) {
ffffffffc0200502:	8432                	mv	s0,a2
ffffffffc0200504:	fc3e                	sd	a5,56(sp)
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc0200506:	861a                	mv	a2,t1
    va_start(ap, fmt);
ffffffffc0200508:	103c                	addi	a5,sp,40
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc020050a:	00006517          	auipc	a0,0x6
ffffffffc020050e:	24e50513          	addi	a0,a0,590 # ffffffffc0206758 <commands+0x68>
__warn(const char *file, int line, const char *fmt, ...) {
ffffffffc0200512:	ec06                	sd	ra,24(sp)
ffffffffc0200514:	f436                	sd	a3,40(sp)
ffffffffc0200516:	f83a                	sd	a4,48(sp)
ffffffffc0200518:	e0c2                	sd	a6,64(sp)
ffffffffc020051a:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc020051c:	e43e                	sd	a5,8(sp)
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc020051e:	c7bff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    vcprintf(fmt, ap);
ffffffffc0200522:	65a2                	ld	a1,8(sp)
ffffffffc0200524:	8522                	mv	a0,s0
ffffffffc0200526:	c53ff0ef          	jal	ra,ffffffffc0200178 <vcprintf>
    cprintf("\n");
ffffffffc020052a:	00007517          	auipc	a0,0x7
ffffffffc020052e:	30650513          	addi	a0,a0,774 # ffffffffc0207830 <default_pmm_manager+0x578>
ffffffffc0200532:	c67ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    va_end(ap);
}
ffffffffc0200536:	60e2                	ld	ra,24(sp)
ffffffffc0200538:	6442                	ld	s0,16(sp)
ffffffffc020053a:	6161                	addi	sp,sp,80
ffffffffc020053c:	8082                	ret

ffffffffc020053e <clock_init>:
 * clock_init - initialize 8253 clock to interrupt 100 times per second,
 * and then enable IRQ_TIMER.
 * */
void clock_init(void)
{
    set_csr(sie, MIP_STIP);
ffffffffc020053e:	02000793          	li	a5,32
ffffffffc0200542:	1047a7f3          	csrrs	a5,sie,a5
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200546:	c0102573          	rdtime	a0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc020054a:	67e1                	lui	a5,0x18
ffffffffc020054c:	6a078793          	addi	a5,a5,1696 # 186a0 <_binary_obj___user_matrix_out_size+0xbda0>
ffffffffc0200550:	953e                	add	a0,a0,a5
	SBI_CALL_1(SBI_SET_TIMER, stime_value);
ffffffffc0200552:	4581                	li	a1,0
ffffffffc0200554:	4601                	li	a2,0
ffffffffc0200556:	4881                	li	a7,0
ffffffffc0200558:	00000073          	ecall
    cprintf("++ setup timer interrupts\n");
ffffffffc020055c:	00006517          	auipc	a0,0x6
ffffffffc0200560:	21c50513          	addi	a0,a0,540 # ffffffffc0206778 <commands+0x88>
    ticks = 0;
ffffffffc0200564:	000df797          	auipc	a5,0xdf
ffffffffc0200568:	6a07be23          	sd	zero,1724(a5) # ffffffffc02dfc20 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc020056c:	b135                	j	ffffffffc0200198 <cprintf>

ffffffffc020056e <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc020056e:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200572:	67e1                	lui	a5,0x18
ffffffffc0200574:	6a078793          	addi	a5,a5,1696 # 186a0 <_binary_obj___user_matrix_out_size+0xbda0>
ffffffffc0200578:	953e                	add	a0,a0,a5
ffffffffc020057a:	4581                	li	a1,0
ffffffffc020057c:	4601                	li	a2,0
ffffffffc020057e:	4881                	li	a7,0
ffffffffc0200580:	00000073          	ecall
ffffffffc0200584:	8082                	ret

ffffffffc0200586 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc0200586:	8082                	ret

ffffffffc0200588 <cons_putc>:
#include <riscv.h>
#include <assert.h>
#include <atomic.h>

static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0200588:	100027f3          	csrr	a5,sstatus
ffffffffc020058c:	8b89                	andi	a5,a5,2
	SBI_CALL_1(SBI_CONSOLE_PUTCHAR, ch);
ffffffffc020058e:	0ff57513          	zext.b	a0,a0
ffffffffc0200592:	e799                	bnez	a5,ffffffffc02005a0 <cons_putc+0x18>
ffffffffc0200594:	4581                	li	a1,0
ffffffffc0200596:	4601                	li	a2,0
ffffffffc0200598:	4885                	li	a7,1
ffffffffc020059a:	00000073          	ecall
    }
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
ffffffffc020059e:	8082                	ret

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) {
ffffffffc02005a0:	1101                	addi	sp,sp,-32
ffffffffc02005a2:	ec06                	sd	ra,24(sp)
ffffffffc02005a4:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc02005a6:	408000ef          	jal	ra,ffffffffc02009ae <intr_disable>
ffffffffc02005aa:	6522                	ld	a0,8(sp)
ffffffffc02005ac:	4581                	li	a1,0
ffffffffc02005ae:	4601                	li	a2,0
ffffffffc02005b0:	4885                	li	a7,1
ffffffffc02005b2:	00000073          	ecall
    local_intr_save(intr_flag);
    {
        sbi_console_putchar((unsigned char)c);
    }
    local_intr_restore(intr_flag);
}
ffffffffc02005b6:	60e2                	ld	ra,24(sp)
ffffffffc02005b8:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc02005ba:	a6fd                	j	ffffffffc02009a8 <intr_enable>

ffffffffc02005bc <cons_getc>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02005bc:	100027f3          	csrr	a5,sstatus
ffffffffc02005c0:	8b89                	andi	a5,a5,2
ffffffffc02005c2:	eb89                	bnez	a5,ffffffffc02005d4 <cons_getc+0x18>
	return SBI_CALL_0(SBI_CONSOLE_GETCHAR);
ffffffffc02005c4:	4501                	li	a0,0
ffffffffc02005c6:	4581                	li	a1,0
ffffffffc02005c8:	4601                	li	a2,0
ffffffffc02005ca:	4889                	li	a7,2
ffffffffc02005cc:	00000073          	ecall
ffffffffc02005d0:	2501                	sext.w	a0,a0
    {
        c = sbi_console_getchar();
    }
    local_intr_restore(intr_flag);
    return c;
}
ffffffffc02005d2:	8082                	ret
int cons_getc(void) {
ffffffffc02005d4:	1101                	addi	sp,sp,-32
ffffffffc02005d6:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc02005d8:	3d6000ef          	jal	ra,ffffffffc02009ae <intr_disable>
ffffffffc02005dc:	4501                	li	a0,0
ffffffffc02005de:	4581                	li	a1,0
ffffffffc02005e0:	4601                	li	a2,0
ffffffffc02005e2:	4889                	li	a7,2
ffffffffc02005e4:	00000073          	ecall
ffffffffc02005e8:	2501                	sext.w	a0,a0
ffffffffc02005ea:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc02005ec:	3bc000ef          	jal	ra,ffffffffc02009a8 <intr_enable>
}
ffffffffc02005f0:	60e2                	ld	ra,24(sp)
ffffffffc02005f2:	6522                	ld	a0,8(sp)
ffffffffc02005f4:	6105                	addi	sp,sp,32
ffffffffc02005f6:	8082                	ret

ffffffffc02005f8 <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc02005f8:	7119                	addi	sp,sp,-128
    cprintf("DTB Init\n");
ffffffffc02005fa:	00006517          	auipc	a0,0x6
ffffffffc02005fe:	19e50513          	addi	a0,a0,414 # ffffffffc0206798 <commands+0xa8>
void dtb_init(void) {
ffffffffc0200602:	fc86                	sd	ra,120(sp)
ffffffffc0200604:	f8a2                	sd	s0,112(sp)
ffffffffc0200606:	e8d2                	sd	s4,80(sp)
ffffffffc0200608:	f4a6                	sd	s1,104(sp)
ffffffffc020060a:	f0ca                	sd	s2,96(sp)
ffffffffc020060c:	ecce                	sd	s3,88(sp)
ffffffffc020060e:	e4d6                	sd	s5,72(sp)
ffffffffc0200610:	e0da                	sd	s6,64(sp)
ffffffffc0200612:	fc5e                	sd	s7,56(sp)
ffffffffc0200614:	f862                	sd	s8,48(sp)
ffffffffc0200616:	f466                	sd	s9,40(sp)
ffffffffc0200618:	f06a                	sd	s10,32(sp)
ffffffffc020061a:	ec6e                	sd	s11,24(sp)
    cprintf("DTB Init\n");
ffffffffc020061c:	b7dff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc0200620:	0000d597          	auipc	a1,0xd
ffffffffc0200624:	9e05b583          	ld	a1,-1568(a1) # ffffffffc020d000 <boot_hartid>
ffffffffc0200628:	00006517          	auipc	a0,0x6
ffffffffc020062c:	18050513          	addi	a0,a0,384 # ffffffffc02067a8 <commands+0xb8>
ffffffffc0200630:	b69ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc0200634:	0000d417          	auipc	s0,0xd
ffffffffc0200638:	9d440413          	addi	s0,s0,-1580 # ffffffffc020d008 <boot_dtb>
ffffffffc020063c:	600c                	ld	a1,0(s0)
ffffffffc020063e:	00006517          	auipc	a0,0x6
ffffffffc0200642:	17a50513          	addi	a0,a0,378 # ffffffffc02067b8 <commands+0xc8>
ffffffffc0200646:	b53ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc020064a:	00043a03          	ld	s4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc020064e:	00006517          	auipc	a0,0x6
ffffffffc0200652:	18250513          	addi	a0,a0,386 # ffffffffc02067d0 <commands+0xe0>
    if (boot_dtb == 0) {
ffffffffc0200656:	120a0463          	beqz	s4,ffffffffc020077e <dtb_init+0x186>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc020065a:	57f5                	li	a5,-3
ffffffffc020065c:	07fa                	slli	a5,a5,0x1e
ffffffffc020065e:	00fa0733          	add	a4,s4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc0200662:	431c                	lw	a5,0(a4)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200664:	00ff0637          	lui	a2,0xff0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200668:	6b41                	lui	s6,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020066a:	0087d59b          	srliw	a1,a5,0x8
ffffffffc020066e:	0187969b          	slliw	a3,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200672:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200676:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020067a:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020067e:	8df1                	and	a1,a1,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200680:	8ec9                	or	a3,a3,a0
ffffffffc0200682:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200686:	1b7d                	addi	s6,s6,-1
ffffffffc0200688:	0167f7b3          	and	a5,a5,s6
ffffffffc020068c:	8dd5                	or	a1,a1,a3
ffffffffc020068e:	8ddd                	or	a1,a1,a5
    if (magic != 0xd00dfeed) {
ffffffffc0200690:	d00e07b7          	lui	a5,0xd00e0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200694:	2581                	sext.w	a1,a1
    if (magic != 0xd00dfeed) {
ffffffffc0200696:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <end+0xfe0024d>
ffffffffc020069a:	10f59163          	bne	a1,a5,ffffffffc020079c <dtb_init+0x1a4>
        return;
    }
    
    // 提取内存信息
    uint64_t mem_base, mem_size;
    if (extract_memory_info(dtb_vaddr, header, &mem_base, &mem_size) == 0) {
ffffffffc020069e:	471c                	lw	a5,8(a4)
ffffffffc02006a0:	4754                	lw	a3,12(a4)
    int in_memory_node = 0;
ffffffffc02006a2:	4c81                	li	s9,0
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006a4:	0087d59b          	srliw	a1,a5,0x8
ffffffffc02006a8:	0086d51b          	srliw	a0,a3,0x8
ffffffffc02006ac:	0186941b          	slliw	s0,a3,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006b0:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006b4:	01879a1b          	slliw	s4,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006b8:	0187d81b          	srliw	a6,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006bc:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006c0:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006c4:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006c8:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006cc:	8d71                	and	a0,a0,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006ce:	01146433          	or	s0,s0,a7
ffffffffc02006d2:	0086969b          	slliw	a3,a3,0x8
ffffffffc02006d6:	010a6a33          	or	s4,s4,a6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006da:	8e6d                	and	a2,a2,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006dc:	0087979b          	slliw	a5,a5,0x8
ffffffffc02006e0:	8c49                	or	s0,s0,a0
ffffffffc02006e2:	0166f6b3          	and	a3,a3,s6
ffffffffc02006e6:	00ca6a33          	or	s4,s4,a2
ffffffffc02006ea:	0167f7b3          	and	a5,a5,s6
ffffffffc02006ee:	8c55                	or	s0,s0,a3
ffffffffc02006f0:	00fa6a33          	or	s4,s4,a5
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc02006f4:	1402                	slli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc02006f6:	1a02                	slli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc02006f8:	9001                	srli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc02006fa:	020a5a13          	srli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc02006fe:	943a                	add	s0,s0,a4
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200700:	9a3a                	add	s4,s4,a4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200702:	00ff0c37          	lui	s8,0xff0
        switch (token) {
ffffffffc0200706:	4b8d                	li	s7,3
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200708:	00006917          	auipc	s2,0x6
ffffffffc020070c:	11890913          	addi	s2,s2,280 # ffffffffc0206820 <commands+0x130>
ffffffffc0200710:	49bd                	li	s3,15
        switch (token) {
ffffffffc0200712:	4d91                	li	s11,4
ffffffffc0200714:	4d05                	li	s10,1
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200716:	00006497          	auipc	s1,0x6
ffffffffc020071a:	10248493          	addi	s1,s1,258 # ffffffffc0206818 <commands+0x128>
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc020071e:	000a2703          	lw	a4,0(s4)
ffffffffc0200722:	004a0a93          	addi	s5,s4,4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200726:	0087569b          	srliw	a3,a4,0x8
ffffffffc020072a:	0187179b          	slliw	a5,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020072e:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200732:	0106969b          	slliw	a3,a3,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200736:	0107571b          	srliw	a4,a4,0x10
ffffffffc020073a:	8fd1                	or	a5,a5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020073c:	0186f6b3          	and	a3,a3,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200740:	0087171b          	slliw	a4,a4,0x8
ffffffffc0200744:	8fd5                	or	a5,a5,a3
ffffffffc0200746:	00eb7733          	and	a4,s6,a4
ffffffffc020074a:	8fd9                	or	a5,a5,a4
ffffffffc020074c:	2781                	sext.w	a5,a5
        switch (token) {
ffffffffc020074e:	09778c63          	beq	a5,s7,ffffffffc02007e6 <dtb_init+0x1ee>
ffffffffc0200752:	00fbea63          	bltu	s7,a5,ffffffffc0200766 <dtb_init+0x16e>
ffffffffc0200756:	07a78663          	beq	a5,s10,ffffffffc02007c2 <dtb_init+0x1ca>
ffffffffc020075a:	4709                	li	a4,2
ffffffffc020075c:	00e79763          	bne	a5,a4,ffffffffc020076a <dtb_init+0x172>
ffffffffc0200760:	4c81                	li	s9,0
ffffffffc0200762:	8a56                	mv	s4,s5
ffffffffc0200764:	bf6d                	j	ffffffffc020071e <dtb_init+0x126>
ffffffffc0200766:	ffb78ee3          	beq	a5,s11,ffffffffc0200762 <dtb_init+0x16a>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc020076a:	00006517          	auipc	a0,0x6
ffffffffc020076e:	12e50513          	addi	a0,a0,302 # ffffffffc0206898 <commands+0x1a8>
ffffffffc0200772:	a27ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc0200776:	00006517          	auipc	a0,0x6
ffffffffc020077a:	15a50513          	addi	a0,a0,346 # ffffffffc02068d0 <commands+0x1e0>
}
ffffffffc020077e:	7446                	ld	s0,112(sp)
ffffffffc0200780:	70e6                	ld	ra,120(sp)
ffffffffc0200782:	74a6                	ld	s1,104(sp)
ffffffffc0200784:	7906                	ld	s2,96(sp)
ffffffffc0200786:	69e6                	ld	s3,88(sp)
ffffffffc0200788:	6a46                	ld	s4,80(sp)
ffffffffc020078a:	6aa6                	ld	s5,72(sp)
ffffffffc020078c:	6b06                	ld	s6,64(sp)
ffffffffc020078e:	7be2                	ld	s7,56(sp)
ffffffffc0200790:	7c42                	ld	s8,48(sp)
ffffffffc0200792:	7ca2                	ld	s9,40(sp)
ffffffffc0200794:	7d02                	ld	s10,32(sp)
ffffffffc0200796:	6de2                	ld	s11,24(sp)
ffffffffc0200798:	6109                	addi	sp,sp,128
    cprintf("DTB init completed\n");
ffffffffc020079a:	bafd                	j	ffffffffc0200198 <cprintf>
}
ffffffffc020079c:	7446                	ld	s0,112(sp)
ffffffffc020079e:	70e6                	ld	ra,120(sp)
ffffffffc02007a0:	74a6                	ld	s1,104(sp)
ffffffffc02007a2:	7906                	ld	s2,96(sp)
ffffffffc02007a4:	69e6                	ld	s3,88(sp)
ffffffffc02007a6:	6a46                	ld	s4,80(sp)
ffffffffc02007a8:	6aa6                	ld	s5,72(sp)
ffffffffc02007aa:	6b06                	ld	s6,64(sp)
ffffffffc02007ac:	7be2                	ld	s7,56(sp)
ffffffffc02007ae:	7c42                	ld	s8,48(sp)
ffffffffc02007b0:	7ca2                	ld	s9,40(sp)
ffffffffc02007b2:	7d02                	ld	s10,32(sp)
ffffffffc02007b4:	6de2                	ld	s11,24(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02007b6:	00006517          	auipc	a0,0x6
ffffffffc02007ba:	03a50513          	addi	a0,a0,58 # ffffffffc02067f0 <commands+0x100>
}
ffffffffc02007be:	6109                	addi	sp,sp,128
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02007c0:	bae1                	j	ffffffffc0200198 <cprintf>
                int name_len = strlen(name);
ffffffffc02007c2:	8556                	mv	a0,s5
ffffffffc02007c4:	3f3050ef          	jal	ra,ffffffffc02063b6 <strlen>
ffffffffc02007c8:	8a2a                	mv	s4,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02007ca:	4619                	li	a2,6
ffffffffc02007cc:	85a6                	mv	a1,s1
ffffffffc02007ce:	8556                	mv	a0,s5
                int name_len = strlen(name);
ffffffffc02007d0:	2a01                	sext.w	s4,s4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02007d2:	44b050ef          	jal	ra,ffffffffc020641c <strncmp>
ffffffffc02007d6:	e111                	bnez	a0,ffffffffc02007da <dtb_init+0x1e2>
                    in_memory_node = 1;
ffffffffc02007d8:	4c85                	li	s9,1
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc02007da:	0a91                	addi	s5,s5,4
ffffffffc02007dc:	9ad2                	add	s5,s5,s4
ffffffffc02007de:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc02007e2:	8a56                	mv	s4,s5
ffffffffc02007e4:	bf2d                	j	ffffffffc020071e <dtb_init+0x126>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc02007e6:	004a2783          	lw	a5,4(s4)
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc02007ea:	00ca0693          	addi	a3,s4,12
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007ee:	0087d71b          	srliw	a4,a5,0x8
ffffffffc02007f2:	01879a9b          	slliw	s5,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007f6:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007fa:	0107171b          	slliw	a4,a4,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007fe:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200802:	00caeab3          	or	s5,s5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200806:	01877733          	and	a4,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020080a:	0087979b          	slliw	a5,a5,0x8
ffffffffc020080e:	00eaeab3          	or	s5,s5,a4
ffffffffc0200812:	00fb77b3          	and	a5,s6,a5
ffffffffc0200816:	00faeab3          	or	s5,s5,a5
ffffffffc020081a:	2a81                	sext.w	s5,s5
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020081c:	000c9c63          	bnez	s9,ffffffffc0200834 <dtb_init+0x23c>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc0200820:	1a82                	slli	s5,s5,0x20
ffffffffc0200822:	00368793          	addi	a5,a3,3
ffffffffc0200826:	020ada93          	srli	s5,s5,0x20
ffffffffc020082a:	9abe                	add	s5,s5,a5
ffffffffc020082c:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc0200830:	8a56                	mv	s4,s5
ffffffffc0200832:	b5f5                	j	ffffffffc020071e <dtb_init+0x126>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200834:	008a2783          	lw	a5,8(s4)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200838:	85ca                	mv	a1,s2
ffffffffc020083a:	e436                	sd	a3,8(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020083c:	0087d51b          	srliw	a0,a5,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200840:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200844:	0187971b          	slliw	a4,a5,0x18
ffffffffc0200848:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020084c:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200850:	8f51                	or	a4,a4,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200852:	01857533          	and	a0,a0,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200856:	0087979b          	slliw	a5,a5,0x8
ffffffffc020085a:	8d59                	or	a0,a0,a4
ffffffffc020085c:	00fb77b3          	and	a5,s6,a5
ffffffffc0200860:	8d5d                	or	a0,a0,a5
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc0200862:	1502                	slli	a0,a0,0x20
ffffffffc0200864:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200866:	9522                	add	a0,a0,s0
ffffffffc0200868:	397050ef          	jal	ra,ffffffffc02063fe <strcmp>
ffffffffc020086c:	66a2                	ld	a3,8(sp)
ffffffffc020086e:	f94d                	bnez	a0,ffffffffc0200820 <dtb_init+0x228>
ffffffffc0200870:	fb59f8e3          	bgeu	s3,s5,ffffffffc0200820 <dtb_init+0x228>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc0200874:	00ca3783          	ld	a5,12(s4)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc0200878:	014a3703          	ld	a4,20(s4)
        cprintf("Physical Memory from DTB:\n");
ffffffffc020087c:	00006517          	auipc	a0,0x6
ffffffffc0200880:	fac50513          	addi	a0,a0,-84 # ffffffffc0206828 <commands+0x138>
           fdt32_to_cpu(x >> 32);
ffffffffc0200884:	4207d613          	srai	a2,a5,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200888:	0087d31b          	srliw	t1,a5,0x8
           fdt32_to_cpu(x >> 32);
ffffffffc020088c:	42075593          	srai	a1,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200890:	0187de1b          	srliw	t3,a5,0x18
ffffffffc0200894:	0186581b          	srliw	a6,a2,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200898:	0187941b          	slliw	s0,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020089c:	0107d89b          	srliw	a7,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02008a0:	0187d693          	srli	a3,a5,0x18
ffffffffc02008a4:	01861f1b          	slliw	t5,a2,0x18
ffffffffc02008a8:	0087579b          	srliw	a5,a4,0x8
ffffffffc02008ac:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02008b0:	0106561b          	srliw	a2,a2,0x10
ffffffffc02008b4:	010f6f33          	or	t5,t5,a6
ffffffffc02008b8:	0187529b          	srliw	t0,a4,0x18
ffffffffc02008bc:	0185df9b          	srliw	t6,a1,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02008c0:	01837333          	and	t1,t1,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02008c4:	01c46433          	or	s0,s0,t3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02008c8:	0186f6b3          	and	a3,a3,s8
ffffffffc02008cc:	01859e1b          	slliw	t3,a1,0x18
ffffffffc02008d0:	01871e9b          	slliw	t4,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02008d4:	0107581b          	srliw	a6,a4,0x10
ffffffffc02008d8:	0086161b          	slliw	a2,a2,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02008dc:	8361                	srli	a4,a4,0x18
ffffffffc02008de:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02008e2:	0105d59b          	srliw	a1,a1,0x10
ffffffffc02008e6:	01e6e6b3          	or	a3,a3,t5
ffffffffc02008ea:	00cb7633          	and	a2,s6,a2
ffffffffc02008ee:	0088181b          	slliw	a6,a6,0x8
ffffffffc02008f2:	0085959b          	slliw	a1,a1,0x8
ffffffffc02008f6:	00646433          	or	s0,s0,t1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02008fa:	0187f7b3          	and	a5,a5,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02008fe:	01fe6333          	or	t1,t3,t6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200902:	01877c33          	and	s8,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200906:	0088989b          	slliw	a7,a7,0x8
ffffffffc020090a:	011b78b3          	and	a7,s6,a7
ffffffffc020090e:	005eeeb3          	or	t4,t4,t0
ffffffffc0200912:	00c6e733          	or	a4,a3,a2
ffffffffc0200916:	006c6c33          	or	s8,s8,t1
ffffffffc020091a:	010b76b3          	and	a3,s6,a6
ffffffffc020091e:	00bb7b33          	and	s6,s6,a1
ffffffffc0200922:	01d7e7b3          	or	a5,a5,t4
ffffffffc0200926:	016c6b33          	or	s6,s8,s6
ffffffffc020092a:	01146433          	or	s0,s0,a7
ffffffffc020092e:	8fd5                	or	a5,a5,a3
           fdt32_to_cpu(x >> 32);
ffffffffc0200930:	1702                	slli	a4,a4,0x20
ffffffffc0200932:	1b02                	slli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200934:	1782                	slli	a5,a5,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc0200936:	9301                	srli	a4,a4,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200938:	1402                	slli	s0,s0,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc020093a:	020b5b13          	srli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc020093e:	0167eb33          	or	s6,a5,s6
ffffffffc0200942:	8c59                	or	s0,s0,a4
        cprintf("Physical Memory from DTB:\n");
ffffffffc0200944:	855ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc0200948:	85a2                	mv	a1,s0
ffffffffc020094a:	00006517          	auipc	a0,0x6
ffffffffc020094e:	efe50513          	addi	a0,a0,-258 # ffffffffc0206848 <commands+0x158>
ffffffffc0200952:	847ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc0200956:	014b5613          	srli	a2,s6,0x14
ffffffffc020095a:	85da                	mv	a1,s6
ffffffffc020095c:	00006517          	auipc	a0,0x6
ffffffffc0200960:	f0450513          	addi	a0,a0,-252 # ffffffffc0206860 <commands+0x170>
ffffffffc0200964:	835ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc0200968:	008b05b3          	add	a1,s6,s0
ffffffffc020096c:	15fd                	addi	a1,a1,-1
ffffffffc020096e:	00006517          	auipc	a0,0x6
ffffffffc0200972:	f1250513          	addi	a0,a0,-238 # ffffffffc0206880 <commands+0x190>
ffffffffc0200976:	823ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("DTB init completed\n");
ffffffffc020097a:	00006517          	auipc	a0,0x6
ffffffffc020097e:	f5650513          	addi	a0,a0,-170 # ffffffffc02068d0 <commands+0x1e0>
        memory_base = mem_base;
ffffffffc0200982:	000df797          	auipc	a5,0xdf
ffffffffc0200986:	2a87b323          	sd	s0,678(a5) # ffffffffc02dfc28 <memory_base>
        memory_size = mem_size;
ffffffffc020098a:	000df797          	auipc	a5,0xdf
ffffffffc020098e:	2b67b323          	sd	s6,678(a5) # ffffffffc02dfc30 <memory_size>
    cprintf("DTB init completed\n");
ffffffffc0200992:	b3f5                	j	ffffffffc020077e <dtb_init+0x186>

ffffffffc0200994 <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc0200994:	000df517          	auipc	a0,0xdf
ffffffffc0200998:	29453503          	ld	a0,660(a0) # ffffffffc02dfc28 <memory_base>
ffffffffc020099c:	8082                	ret

ffffffffc020099e <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
}
ffffffffc020099e:	000df517          	auipc	a0,0xdf
ffffffffc02009a2:	29253503          	ld	a0,658(a0) # ffffffffc02dfc30 <memory_size>
ffffffffc02009a6:	8082                	ret

ffffffffc02009a8 <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc02009a8:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc02009ac:	8082                	ret

ffffffffc02009ae <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc02009ae:	100177f3          	csrrci	a5,sstatus,2
ffffffffc02009b2:	8082                	ret

ffffffffc02009b4 <pic_init>:
#include <picirq.h>

void pic_enable(unsigned int irq) {}

/* pic_init - initialize the 8259A interrupt controllers */
void pic_init(void) {}
ffffffffc02009b4:	8082                	ret

ffffffffc02009b6 <idt_init>:
void idt_init(void)
{
    extern void __alltraps(void);
    /* Set sscratch register to 0, indicating to exception vector that we are
     * presently executing in the kernel */
    write_csr(sscratch, 0);
ffffffffc02009b6:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
ffffffffc02009ba:	00000797          	auipc	a5,0x0
ffffffffc02009be:	43278793          	addi	a5,a5,1074 # ffffffffc0200dec <__alltraps>
ffffffffc02009c2:	10579073          	csrw	stvec,a5
    /* Allow kernel to access user memory */
    set_csr(sstatus, SSTATUS_SUM);
ffffffffc02009c6:	000407b7          	lui	a5,0x40
ffffffffc02009ca:	1007a7f3          	csrrs	a5,sstatus,a5
}
ffffffffc02009ce:	8082                	ret

ffffffffc02009d0 <print_regs>:
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr)
{
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc02009d0:	610c                	ld	a1,0(a0)
{
ffffffffc02009d2:	1141                	addi	sp,sp,-16
ffffffffc02009d4:	e022                	sd	s0,0(sp)
ffffffffc02009d6:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc02009d8:	00006517          	auipc	a0,0x6
ffffffffc02009dc:	f1050513          	addi	a0,a0,-240 # ffffffffc02068e8 <commands+0x1f8>
{
ffffffffc02009e0:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc02009e2:	fb6ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc02009e6:	640c                	ld	a1,8(s0)
ffffffffc02009e8:	00006517          	auipc	a0,0x6
ffffffffc02009ec:	f1850513          	addi	a0,a0,-232 # ffffffffc0206900 <commands+0x210>
ffffffffc02009f0:	fa8ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc02009f4:	680c                	ld	a1,16(s0)
ffffffffc02009f6:	00006517          	auipc	a0,0x6
ffffffffc02009fa:	f2250513          	addi	a0,a0,-222 # ffffffffc0206918 <commands+0x228>
ffffffffc02009fe:	f9aff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc0200a02:	6c0c                	ld	a1,24(s0)
ffffffffc0200a04:	00006517          	auipc	a0,0x6
ffffffffc0200a08:	f2c50513          	addi	a0,a0,-212 # ffffffffc0206930 <commands+0x240>
ffffffffc0200a0c:	f8cff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc0200a10:	700c                	ld	a1,32(s0)
ffffffffc0200a12:	00006517          	auipc	a0,0x6
ffffffffc0200a16:	f3650513          	addi	a0,a0,-202 # ffffffffc0206948 <commands+0x258>
ffffffffc0200a1a:	f7eff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc0200a1e:	740c                	ld	a1,40(s0)
ffffffffc0200a20:	00006517          	auipc	a0,0x6
ffffffffc0200a24:	f4050513          	addi	a0,a0,-192 # ffffffffc0206960 <commands+0x270>
ffffffffc0200a28:	f70ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc0200a2c:	780c                	ld	a1,48(s0)
ffffffffc0200a2e:	00006517          	auipc	a0,0x6
ffffffffc0200a32:	f4a50513          	addi	a0,a0,-182 # ffffffffc0206978 <commands+0x288>
ffffffffc0200a36:	f62ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc0200a3a:	7c0c                	ld	a1,56(s0)
ffffffffc0200a3c:	00006517          	auipc	a0,0x6
ffffffffc0200a40:	f5450513          	addi	a0,a0,-172 # ffffffffc0206990 <commands+0x2a0>
ffffffffc0200a44:	f54ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc0200a48:	602c                	ld	a1,64(s0)
ffffffffc0200a4a:	00006517          	auipc	a0,0x6
ffffffffc0200a4e:	f5e50513          	addi	a0,a0,-162 # ffffffffc02069a8 <commands+0x2b8>
ffffffffc0200a52:	f46ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc0200a56:	642c                	ld	a1,72(s0)
ffffffffc0200a58:	00006517          	auipc	a0,0x6
ffffffffc0200a5c:	f6850513          	addi	a0,a0,-152 # ffffffffc02069c0 <commands+0x2d0>
ffffffffc0200a60:	f38ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc0200a64:	682c                	ld	a1,80(s0)
ffffffffc0200a66:	00006517          	auipc	a0,0x6
ffffffffc0200a6a:	f7250513          	addi	a0,a0,-142 # ffffffffc02069d8 <commands+0x2e8>
ffffffffc0200a6e:	f2aff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc0200a72:	6c2c                	ld	a1,88(s0)
ffffffffc0200a74:	00006517          	auipc	a0,0x6
ffffffffc0200a78:	f7c50513          	addi	a0,a0,-132 # ffffffffc02069f0 <commands+0x300>
ffffffffc0200a7c:	f1cff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc0200a80:	702c                	ld	a1,96(s0)
ffffffffc0200a82:	00006517          	auipc	a0,0x6
ffffffffc0200a86:	f8650513          	addi	a0,a0,-122 # ffffffffc0206a08 <commands+0x318>
ffffffffc0200a8a:	f0eff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc0200a8e:	742c                	ld	a1,104(s0)
ffffffffc0200a90:	00006517          	auipc	a0,0x6
ffffffffc0200a94:	f9050513          	addi	a0,a0,-112 # ffffffffc0206a20 <commands+0x330>
ffffffffc0200a98:	f00ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc0200a9c:	782c                	ld	a1,112(s0)
ffffffffc0200a9e:	00006517          	auipc	a0,0x6
ffffffffc0200aa2:	f9a50513          	addi	a0,a0,-102 # ffffffffc0206a38 <commands+0x348>
ffffffffc0200aa6:	ef2ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200aaa:	7c2c                	ld	a1,120(s0)
ffffffffc0200aac:	00006517          	auipc	a0,0x6
ffffffffc0200ab0:	fa450513          	addi	a0,a0,-92 # ffffffffc0206a50 <commands+0x360>
ffffffffc0200ab4:	ee4ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc0200ab8:	604c                	ld	a1,128(s0)
ffffffffc0200aba:	00006517          	auipc	a0,0x6
ffffffffc0200abe:	fae50513          	addi	a0,a0,-82 # ffffffffc0206a68 <commands+0x378>
ffffffffc0200ac2:	ed6ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200ac6:	644c                	ld	a1,136(s0)
ffffffffc0200ac8:	00006517          	auipc	a0,0x6
ffffffffc0200acc:	fb850513          	addi	a0,a0,-72 # ffffffffc0206a80 <commands+0x390>
ffffffffc0200ad0:	ec8ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200ad4:	684c                	ld	a1,144(s0)
ffffffffc0200ad6:	00006517          	auipc	a0,0x6
ffffffffc0200ada:	fc250513          	addi	a0,a0,-62 # ffffffffc0206a98 <commands+0x3a8>
ffffffffc0200ade:	ebaff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc0200ae2:	6c4c                	ld	a1,152(s0)
ffffffffc0200ae4:	00006517          	auipc	a0,0x6
ffffffffc0200ae8:	fcc50513          	addi	a0,a0,-52 # ffffffffc0206ab0 <commands+0x3c0>
ffffffffc0200aec:	eacff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc0200af0:	704c                	ld	a1,160(s0)
ffffffffc0200af2:	00006517          	auipc	a0,0x6
ffffffffc0200af6:	fd650513          	addi	a0,a0,-42 # ffffffffc0206ac8 <commands+0x3d8>
ffffffffc0200afa:	e9eff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc0200afe:	744c                	ld	a1,168(s0)
ffffffffc0200b00:	00006517          	auipc	a0,0x6
ffffffffc0200b04:	fe050513          	addi	a0,a0,-32 # ffffffffc0206ae0 <commands+0x3f0>
ffffffffc0200b08:	e90ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc0200b0c:	784c                	ld	a1,176(s0)
ffffffffc0200b0e:	00006517          	auipc	a0,0x6
ffffffffc0200b12:	fea50513          	addi	a0,a0,-22 # ffffffffc0206af8 <commands+0x408>
ffffffffc0200b16:	e82ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc0200b1a:	7c4c                	ld	a1,184(s0)
ffffffffc0200b1c:	00006517          	auipc	a0,0x6
ffffffffc0200b20:	ff450513          	addi	a0,a0,-12 # ffffffffc0206b10 <commands+0x420>
ffffffffc0200b24:	e74ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc0200b28:	606c                	ld	a1,192(s0)
ffffffffc0200b2a:	00006517          	auipc	a0,0x6
ffffffffc0200b2e:	ffe50513          	addi	a0,a0,-2 # ffffffffc0206b28 <commands+0x438>
ffffffffc0200b32:	e66ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc0200b36:	646c                	ld	a1,200(s0)
ffffffffc0200b38:	00006517          	auipc	a0,0x6
ffffffffc0200b3c:	00850513          	addi	a0,a0,8 # ffffffffc0206b40 <commands+0x450>
ffffffffc0200b40:	e58ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc0200b44:	686c                	ld	a1,208(s0)
ffffffffc0200b46:	00006517          	auipc	a0,0x6
ffffffffc0200b4a:	01250513          	addi	a0,a0,18 # ffffffffc0206b58 <commands+0x468>
ffffffffc0200b4e:	e4aff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc0200b52:	6c6c                	ld	a1,216(s0)
ffffffffc0200b54:	00006517          	auipc	a0,0x6
ffffffffc0200b58:	01c50513          	addi	a0,a0,28 # ffffffffc0206b70 <commands+0x480>
ffffffffc0200b5c:	e3cff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc0200b60:	706c                	ld	a1,224(s0)
ffffffffc0200b62:	00006517          	auipc	a0,0x6
ffffffffc0200b66:	02650513          	addi	a0,a0,38 # ffffffffc0206b88 <commands+0x498>
ffffffffc0200b6a:	e2eff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc0200b6e:	746c                	ld	a1,232(s0)
ffffffffc0200b70:	00006517          	auipc	a0,0x6
ffffffffc0200b74:	03050513          	addi	a0,a0,48 # ffffffffc0206ba0 <commands+0x4b0>
ffffffffc0200b78:	e20ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200b7c:	786c                	ld	a1,240(s0)
ffffffffc0200b7e:	00006517          	auipc	a0,0x6
ffffffffc0200b82:	03a50513          	addi	a0,a0,58 # ffffffffc0206bb8 <commands+0x4c8>
ffffffffc0200b86:	e12ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200b8a:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200b8c:	6402                	ld	s0,0(sp)
ffffffffc0200b8e:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200b90:	00006517          	auipc	a0,0x6
ffffffffc0200b94:	04050513          	addi	a0,a0,64 # ffffffffc0206bd0 <commands+0x4e0>
}
ffffffffc0200b98:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200b9a:	dfeff06f          	j	ffffffffc0200198 <cprintf>

ffffffffc0200b9e <print_trapframe>:
{
ffffffffc0200b9e:	1141                	addi	sp,sp,-16
ffffffffc0200ba0:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200ba2:	85aa                	mv	a1,a0
{
ffffffffc0200ba4:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc0200ba6:	00006517          	auipc	a0,0x6
ffffffffc0200baa:	04250513          	addi	a0,a0,66 # ffffffffc0206be8 <commands+0x4f8>
{
ffffffffc0200bae:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200bb0:	de8ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200bb4:	8522                	mv	a0,s0
ffffffffc0200bb6:	e1bff0ef          	jal	ra,ffffffffc02009d0 <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc0200bba:	10043583          	ld	a1,256(s0)
ffffffffc0200bbe:	00006517          	auipc	a0,0x6
ffffffffc0200bc2:	04250513          	addi	a0,a0,66 # ffffffffc0206c00 <commands+0x510>
ffffffffc0200bc6:	dd2ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200bca:	10843583          	ld	a1,264(s0)
ffffffffc0200bce:	00006517          	auipc	a0,0x6
ffffffffc0200bd2:	04a50513          	addi	a0,a0,74 # ffffffffc0206c18 <commands+0x528>
ffffffffc0200bd6:	dc2ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  tval 0x%08x\n", tf->tval);
ffffffffc0200bda:	11043583          	ld	a1,272(s0)
ffffffffc0200bde:	00006517          	auipc	a0,0x6
ffffffffc0200be2:	05250513          	addi	a0,a0,82 # ffffffffc0206c30 <commands+0x540>
ffffffffc0200be6:	db2ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200bea:	11843583          	ld	a1,280(s0)
}
ffffffffc0200bee:	6402                	ld	s0,0(sp)
ffffffffc0200bf0:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200bf2:	00006517          	auipc	a0,0x6
ffffffffc0200bf6:	04e50513          	addi	a0,a0,78 # ffffffffc0206c40 <commands+0x550>
}
ffffffffc0200bfa:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200bfc:	d9cff06f          	j	ffffffffc0200198 <cprintf>

ffffffffc0200c00 <interrupt_handler>:

extern struct mm_struct *check_mm_struct;

void interrupt_handler(struct trapframe *tf)
{
    intptr_t cause = (tf->cause << 1) >> 1;
ffffffffc0200c00:	11853783          	ld	a5,280(a0)
ffffffffc0200c04:	472d                	li	a4,11
ffffffffc0200c06:	0786                	slli	a5,a5,0x1
ffffffffc0200c08:	8385                	srli	a5,a5,0x1
ffffffffc0200c0a:	06f76863          	bltu	a4,a5,ffffffffc0200c7a <interrupt_handler+0x7a>
ffffffffc0200c0e:	00006717          	auipc	a4,0x6
ffffffffc0200c12:	0ea70713          	addi	a4,a4,234 # ffffffffc0206cf8 <commands+0x608>
ffffffffc0200c16:	078a                	slli	a5,a5,0x2
ffffffffc0200c18:	97ba                	add	a5,a5,a4
ffffffffc0200c1a:	439c                	lw	a5,0(a5)
ffffffffc0200c1c:	97ba                	add	a5,a5,a4
ffffffffc0200c1e:	8782                	jr	a5
        break;
    case IRQ_H_SOFT:
        cprintf("Hypervisor software interrupt\n");
        break;
    case IRQ_M_SOFT:
        cprintf("Machine software interrupt\n");
ffffffffc0200c20:	00006517          	auipc	a0,0x6
ffffffffc0200c24:	09850513          	addi	a0,a0,152 # ffffffffc0206cb8 <commands+0x5c8>
ffffffffc0200c28:	d70ff06f          	j	ffffffffc0200198 <cprintf>
        cprintf("Hypervisor software interrupt\n");
ffffffffc0200c2c:	00006517          	auipc	a0,0x6
ffffffffc0200c30:	06c50513          	addi	a0,a0,108 # ffffffffc0206c98 <commands+0x5a8>
ffffffffc0200c34:	d64ff06f          	j	ffffffffc0200198 <cprintf>
        cprintf("User software interrupt\n");
ffffffffc0200c38:	00006517          	auipc	a0,0x6
ffffffffc0200c3c:	02050513          	addi	a0,a0,32 # ffffffffc0206c58 <commands+0x568>
ffffffffc0200c40:	d58ff06f          	j	ffffffffc0200198 <cprintf>
        cprintf("Supervisor software interrupt\n");
ffffffffc0200c44:	00006517          	auipc	a0,0x6
ffffffffc0200c48:	03450513          	addi	a0,a0,52 # ffffffffc0206c78 <commands+0x588>
ffffffffc0200c4c:	d4cff06f          	j	ffffffffc0200198 <cprintf>
{
ffffffffc0200c50:	1141                	addi	sp,sp,-16
ffffffffc0200c52:	e406                	sd	ra,8(sp)
        // "All bits besides SSIP and USIP in the sip register are
        // read-only." -- privileged spec1.9.1, 4.1.4, p59
        // In fact, Call sbi_set_timer will clear STIP, or you can clear it
        // directly.
        // clear_csr(sip, SIP_STIP);
        clock_set_next_event();
ffffffffc0200c54:	91bff0ef          	jal	ra,ffffffffc020056e <clock_set_next_event>
        ++ticks;
ffffffffc0200c58:	000df717          	auipc	a4,0xdf
ffffffffc0200c5c:	fc870713          	addi	a4,a4,-56 # ffffffffc02dfc20 <ticks>
ffffffffc0200c60:	631c                	ld	a5,0(a4)
        break;
    default:
        print_trapframe(tf);
        break;
    }
}
ffffffffc0200c62:	60a2                	ld	ra,8(sp)
        ++ticks;
ffffffffc0200c64:	0785                	addi	a5,a5,1
ffffffffc0200c66:	e31c                	sd	a5,0(a4)
}
ffffffffc0200c68:	0141                	addi	sp,sp,16
        run_timer_list();
ffffffffc0200c6a:	1020506f          	j	ffffffffc0205d6c <run_timer_list>
        cprintf("Supervisor external interrupt\n");
ffffffffc0200c6e:	00006517          	auipc	a0,0x6
ffffffffc0200c72:	06a50513          	addi	a0,a0,106 # ffffffffc0206cd8 <commands+0x5e8>
ffffffffc0200c76:	d22ff06f          	j	ffffffffc0200198 <cprintf>
        print_trapframe(tf);
ffffffffc0200c7a:	b715                	j	ffffffffc0200b9e <print_trapframe>

ffffffffc0200c7c <exception_handler>:
void kernel_execve_ret(struct trapframe *tf, uintptr_t kstacktop);
void exception_handler(struct trapframe *tf)
{
    int ret;
    switch (tf->cause)
ffffffffc0200c7c:	11853783          	ld	a5,280(a0)
{
ffffffffc0200c80:	1141                	addi	sp,sp,-16
ffffffffc0200c82:	e022                	sd	s0,0(sp)
ffffffffc0200c84:	e406                	sd	ra,8(sp)
ffffffffc0200c86:	473d                	li	a4,15
ffffffffc0200c88:	842a                	mv	s0,a0
ffffffffc0200c8a:	0af76b63          	bltu	a4,a5,ffffffffc0200d40 <exception_handler+0xc4>
ffffffffc0200c8e:	00006717          	auipc	a4,0x6
ffffffffc0200c92:	22a70713          	addi	a4,a4,554 # ffffffffc0206eb8 <commands+0x7c8>
ffffffffc0200c96:	078a                	slli	a5,a5,0x2
ffffffffc0200c98:	97ba                	add	a5,a5,a4
ffffffffc0200c9a:	439c                	lw	a5,0(a5)
ffffffffc0200c9c:	97ba                	add	a5,a5,a4
ffffffffc0200c9e:	8782                	jr	a5
        // cprintf("Environment call from U-mode\n");
        tf->epc += 4;
        syscall();
        break;
    case CAUSE_SUPERVISOR_ECALL:
        cprintf("Environment call from S-mode\n");
ffffffffc0200ca0:	00006517          	auipc	a0,0x6
ffffffffc0200ca4:	17050513          	addi	a0,a0,368 # ffffffffc0206e10 <commands+0x720>
ffffffffc0200ca8:	cf0ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
        tf->epc += 4;
ffffffffc0200cac:	10843783          	ld	a5,264(s0)
        break;
    default:
        print_trapframe(tf);
        break;
    }
}
ffffffffc0200cb0:	60a2                	ld	ra,8(sp)
        tf->epc += 4;
ffffffffc0200cb2:	0791                	addi	a5,a5,4
ffffffffc0200cb4:	10f43423          	sd	a5,264(s0)
}
ffffffffc0200cb8:	6402                	ld	s0,0(sp)
ffffffffc0200cba:	0141                	addi	sp,sp,16
        syscall();
ffffffffc0200cbc:	2740506f          	j	ffffffffc0205f30 <syscall>
        cprintf("Environment call from H-mode\n");
ffffffffc0200cc0:	00006517          	auipc	a0,0x6
ffffffffc0200cc4:	17050513          	addi	a0,a0,368 # ffffffffc0206e30 <commands+0x740>
}
ffffffffc0200cc8:	6402                	ld	s0,0(sp)
ffffffffc0200cca:	60a2                	ld	ra,8(sp)
ffffffffc0200ccc:	0141                	addi	sp,sp,16
        cprintf("Instruction access fault\n");
ffffffffc0200cce:	ccaff06f          	j	ffffffffc0200198 <cprintf>
        cprintf("Environment call from M-mode\n");
ffffffffc0200cd2:	00006517          	auipc	a0,0x6
ffffffffc0200cd6:	17e50513          	addi	a0,a0,382 # ffffffffc0206e50 <commands+0x760>
ffffffffc0200cda:	b7fd                	j	ffffffffc0200cc8 <exception_handler+0x4c>
        cprintf("Instruction page fault\n");
ffffffffc0200cdc:	00006517          	auipc	a0,0x6
ffffffffc0200ce0:	19450513          	addi	a0,a0,404 # ffffffffc0206e70 <commands+0x780>
ffffffffc0200ce4:	b7d5                	j	ffffffffc0200cc8 <exception_handler+0x4c>
        cprintf("Load page fault\n");
ffffffffc0200ce6:	00006517          	auipc	a0,0x6
ffffffffc0200cea:	1a250513          	addi	a0,a0,418 # ffffffffc0206e88 <commands+0x798>
ffffffffc0200cee:	bfe9                	j	ffffffffc0200cc8 <exception_handler+0x4c>
        cprintf("Store/AMO page fault\n");
ffffffffc0200cf0:	00006517          	auipc	a0,0x6
ffffffffc0200cf4:	1b050513          	addi	a0,a0,432 # ffffffffc0206ea0 <commands+0x7b0>
ffffffffc0200cf8:	bfc1                	j	ffffffffc0200cc8 <exception_handler+0x4c>
        cprintf("Instruction address misaligned\n");
ffffffffc0200cfa:	00006517          	auipc	a0,0x6
ffffffffc0200cfe:	02e50513          	addi	a0,a0,46 # ffffffffc0206d28 <commands+0x638>
ffffffffc0200d02:	b7d9                	j	ffffffffc0200cc8 <exception_handler+0x4c>
        cprintf("Instruction access fault\n");
ffffffffc0200d04:	00006517          	auipc	a0,0x6
ffffffffc0200d08:	04450513          	addi	a0,a0,68 # ffffffffc0206d48 <commands+0x658>
ffffffffc0200d0c:	bf75                	j	ffffffffc0200cc8 <exception_handler+0x4c>
        cprintf("Illegal instruction\n");
ffffffffc0200d0e:	00006517          	auipc	a0,0x6
ffffffffc0200d12:	05a50513          	addi	a0,a0,90 # ffffffffc0206d68 <commands+0x678>
ffffffffc0200d16:	bf4d                	j	ffffffffc0200cc8 <exception_handler+0x4c>
        cprintf("Breakpoint\n");
ffffffffc0200d18:	00006517          	auipc	a0,0x6
ffffffffc0200d1c:	06850513          	addi	a0,a0,104 # ffffffffc0206d80 <commands+0x690>
ffffffffc0200d20:	b765                	j	ffffffffc0200cc8 <exception_handler+0x4c>
        cprintf("Load address misaligned\n");
ffffffffc0200d22:	00006517          	auipc	a0,0x6
ffffffffc0200d26:	06e50513          	addi	a0,a0,110 # ffffffffc0206d90 <commands+0x6a0>
ffffffffc0200d2a:	bf79                	j	ffffffffc0200cc8 <exception_handler+0x4c>
        cprintf("Load access fault\n");
ffffffffc0200d2c:	00006517          	auipc	a0,0x6
ffffffffc0200d30:	08450513          	addi	a0,a0,132 # ffffffffc0206db0 <commands+0x6c0>
ffffffffc0200d34:	bf51                	j	ffffffffc0200cc8 <exception_handler+0x4c>
        cprintf("Store/AMO access fault\n");
ffffffffc0200d36:	00006517          	auipc	a0,0x6
ffffffffc0200d3a:	0c250513          	addi	a0,a0,194 # ffffffffc0206df8 <commands+0x708>
ffffffffc0200d3e:	b769                	j	ffffffffc0200cc8 <exception_handler+0x4c>
        print_trapframe(tf);
ffffffffc0200d40:	8522                	mv	a0,s0
}
ffffffffc0200d42:	6402                	ld	s0,0(sp)
ffffffffc0200d44:	60a2                	ld	ra,8(sp)
ffffffffc0200d46:	0141                	addi	sp,sp,16
        print_trapframe(tf);
ffffffffc0200d48:	bd99                	j	ffffffffc0200b9e <print_trapframe>
        panic("AMO address misaligned\n");
ffffffffc0200d4a:	00006617          	auipc	a2,0x6
ffffffffc0200d4e:	07e60613          	addi	a2,a2,126 # ffffffffc0206dc8 <commands+0x6d8>
ffffffffc0200d52:	0b000593          	li	a1,176
ffffffffc0200d56:	00006517          	auipc	a0,0x6
ffffffffc0200d5a:	08a50513          	addi	a0,a0,138 # ffffffffc0206de0 <commands+0x6f0>
ffffffffc0200d5e:	f34ff0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0200d62 <trap>:
 * trap - handles or dispatches an exception/interrupt. if and when trap() returns,
 * the code in kern/trap/trapentry.S restores the old CPU state saved in the
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void trap(struct trapframe *tf)
{
ffffffffc0200d62:	1101                	addi	sp,sp,-32
ffffffffc0200d64:	e822                	sd	s0,16(sp)
    // dispatch based on what type of trap occurred
    //    cputs("some trap");
    if (current == NULL)
ffffffffc0200d66:	000df417          	auipc	s0,0xdf
ffffffffc0200d6a:	f0a40413          	addi	s0,s0,-246 # ffffffffc02dfc70 <current>
ffffffffc0200d6e:	6018                	ld	a4,0(s0)
{
ffffffffc0200d70:	ec06                	sd	ra,24(sp)
ffffffffc0200d72:	e426                	sd	s1,8(sp)
ffffffffc0200d74:	e04a                	sd	s2,0(sp)
    if ((intptr_t)tf->cause < 0)
ffffffffc0200d76:	11853683          	ld	a3,280(a0)
    if (current == NULL)
ffffffffc0200d7a:	cf1d                	beqz	a4,ffffffffc0200db8 <trap+0x56>
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200d7c:	10053483          	ld	s1,256(a0)
    {
        trap_dispatch(tf);
    }
    else
    {
        struct trapframe *otf = current->tf;
ffffffffc0200d80:	0a073903          	ld	s2,160(a4)
        current->tf = tf;
ffffffffc0200d84:	f348                	sd	a0,160(a4)
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200d86:	1004f493          	andi	s1,s1,256
    if ((intptr_t)tf->cause < 0)
ffffffffc0200d8a:	0206c463          	bltz	a3,ffffffffc0200db2 <trap+0x50>
        exception_handler(tf);
ffffffffc0200d8e:	eefff0ef          	jal	ra,ffffffffc0200c7c <exception_handler>

        bool in_kernel = trap_in_kernel(tf);

        trap_dispatch(tf);

        current->tf = otf;
ffffffffc0200d92:	601c                	ld	a5,0(s0)
ffffffffc0200d94:	0b27b023          	sd	s2,160(a5) # 400a0 <_binary_obj___user_matrix_out_size+0x337a0>
        if (!in_kernel)
ffffffffc0200d98:	e499                	bnez	s1,ffffffffc0200da6 <trap+0x44>
        {
            if (current->flags & PF_EXITING)
ffffffffc0200d9a:	0b07a703          	lw	a4,176(a5)
ffffffffc0200d9e:	8b05                	andi	a4,a4,1
ffffffffc0200da0:	e329                	bnez	a4,ffffffffc0200de2 <trap+0x80>
            {
                do_exit(-E_KILLED);
            }
            if (current->need_resched)
ffffffffc0200da2:	6f9c                	ld	a5,24(a5)
ffffffffc0200da4:	eb85                	bnez	a5,ffffffffc0200dd4 <trap+0x72>
            {
                schedule();
            }
        }
    }
}
ffffffffc0200da6:	60e2                	ld	ra,24(sp)
ffffffffc0200da8:	6442                	ld	s0,16(sp)
ffffffffc0200daa:	64a2                	ld	s1,8(sp)
ffffffffc0200dac:	6902                	ld	s2,0(sp)
ffffffffc0200dae:	6105                	addi	sp,sp,32
ffffffffc0200db0:	8082                	ret
        interrupt_handler(tf);
ffffffffc0200db2:	e4fff0ef          	jal	ra,ffffffffc0200c00 <interrupt_handler>
ffffffffc0200db6:	bff1                	j	ffffffffc0200d92 <trap+0x30>
    if ((intptr_t)tf->cause < 0)
ffffffffc0200db8:	0006c863          	bltz	a3,ffffffffc0200dc8 <trap+0x66>
}
ffffffffc0200dbc:	6442                	ld	s0,16(sp)
ffffffffc0200dbe:	60e2                	ld	ra,24(sp)
ffffffffc0200dc0:	64a2                	ld	s1,8(sp)
ffffffffc0200dc2:	6902                	ld	s2,0(sp)
ffffffffc0200dc4:	6105                	addi	sp,sp,32
        exception_handler(tf);
ffffffffc0200dc6:	bd5d                	j	ffffffffc0200c7c <exception_handler>
}
ffffffffc0200dc8:	6442                	ld	s0,16(sp)
ffffffffc0200dca:	60e2                	ld	ra,24(sp)
ffffffffc0200dcc:	64a2                	ld	s1,8(sp)
ffffffffc0200dce:	6902                	ld	s2,0(sp)
ffffffffc0200dd0:	6105                	addi	sp,sp,32
        interrupt_handler(tf);
ffffffffc0200dd2:	b53d                	j	ffffffffc0200c00 <interrupt_handler>
}
ffffffffc0200dd4:	6442                	ld	s0,16(sp)
ffffffffc0200dd6:	60e2                	ld	ra,24(sp)
ffffffffc0200dd8:	64a2                	ld	s1,8(sp)
ffffffffc0200dda:	6902                	ld	s2,0(sp)
ffffffffc0200ddc:	6105                	addi	sp,sp,32
                schedule();
ffffffffc0200dde:	5830406f          	j	ffffffffc0205b60 <schedule>
                do_exit(-E_KILLED);
ffffffffc0200de2:	555d                	li	a0,-9
ffffffffc0200de4:	63d030ef          	jal	ra,ffffffffc0204c20 <do_exit>
            if (current->need_resched)
ffffffffc0200de8:	601c                	ld	a5,0(s0)
ffffffffc0200dea:	bf65                	j	ffffffffc0200da2 <trap+0x40>

ffffffffc0200dec <__alltraps>:
    LOAD x2, 2*REGBYTES(sp)
    .endm

    .globl __alltraps
__alltraps:
    SAVE_ALL
ffffffffc0200dec:	14011173          	csrrw	sp,sscratch,sp
ffffffffc0200df0:	00011463          	bnez	sp,ffffffffc0200df8 <__alltraps+0xc>
ffffffffc0200df4:	14002173          	csrr	sp,sscratch
ffffffffc0200df8:	712d                	addi	sp,sp,-288
ffffffffc0200dfa:	e002                	sd	zero,0(sp)
ffffffffc0200dfc:	e406                	sd	ra,8(sp)
ffffffffc0200dfe:	ec0e                	sd	gp,24(sp)
ffffffffc0200e00:	f012                	sd	tp,32(sp)
ffffffffc0200e02:	f416                	sd	t0,40(sp)
ffffffffc0200e04:	f81a                	sd	t1,48(sp)
ffffffffc0200e06:	fc1e                	sd	t2,56(sp)
ffffffffc0200e08:	e0a2                	sd	s0,64(sp)
ffffffffc0200e0a:	e4a6                	sd	s1,72(sp)
ffffffffc0200e0c:	e8aa                	sd	a0,80(sp)
ffffffffc0200e0e:	ecae                	sd	a1,88(sp)
ffffffffc0200e10:	f0b2                	sd	a2,96(sp)
ffffffffc0200e12:	f4b6                	sd	a3,104(sp)
ffffffffc0200e14:	f8ba                	sd	a4,112(sp)
ffffffffc0200e16:	fcbe                	sd	a5,120(sp)
ffffffffc0200e18:	e142                	sd	a6,128(sp)
ffffffffc0200e1a:	e546                	sd	a7,136(sp)
ffffffffc0200e1c:	e94a                	sd	s2,144(sp)
ffffffffc0200e1e:	ed4e                	sd	s3,152(sp)
ffffffffc0200e20:	f152                	sd	s4,160(sp)
ffffffffc0200e22:	f556                	sd	s5,168(sp)
ffffffffc0200e24:	f95a                	sd	s6,176(sp)
ffffffffc0200e26:	fd5e                	sd	s7,184(sp)
ffffffffc0200e28:	e1e2                	sd	s8,192(sp)
ffffffffc0200e2a:	e5e6                	sd	s9,200(sp)
ffffffffc0200e2c:	e9ea                	sd	s10,208(sp)
ffffffffc0200e2e:	edee                	sd	s11,216(sp)
ffffffffc0200e30:	f1f2                	sd	t3,224(sp)
ffffffffc0200e32:	f5f6                	sd	t4,232(sp)
ffffffffc0200e34:	f9fa                	sd	t5,240(sp)
ffffffffc0200e36:	fdfe                	sd	t6,248(sp)
ffffffffc0200e38:	14001473          	csrrw	s0,sscratch,zero
ffffffffc0200e3c:	100024f3          	csrr	s1,sstatus
ffffffffc0200e40:	14102973          	csrr	s2,sepc
ffffffffc0200e44:	143029f3          	csrr	s3,stval
ffffffffc0200e48:	14202a73          	csrr	s4,scause
ffffffffc0200e4c:	e822                	sd	s0,16(sp)
ffffffffc0200e4e:	e226                	sd	s1,256(sp)
ffffffffc0200e50:	e64a                	sd	s2,264(sp)
ffffffffc0200e52:	ea4e                	sd	s3,272(sp)
ffffffffc0200e54:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200e56:	850a                	mv	a0,sp
    jal trap
ffffffffc0200e58:	f0bff0ef          	jal	ra,ffffffffc0200d62 <trap>

ffffffffc0200e5c <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200e5c:	6492                	ld	s1,256(sp)
ffffffffc0200e5e:	6932                	ld	s2,264(sp)
ffffffffc0200e60:	1004f413          	andi	s0,s1,256
ffffffffc0200e64:	e401                	bnez	s0,ffffffffc0200e6c <__trapret+0x10>
ffffffffc0200e66:	1200                	addi	s0,sp,288
ffffffffc0200e68:	14041073          	csrw	sscratch,s0
ffffffffc0200e6c:	10049073          	csrw	sstatus,s1
ffffffffc0200e70:	14191073          	csrw	sepc,s2
ffffffffc0200e74:	60a2                	ld	ra,8(sp)
ffffffffc0200e76:	61e2                	ld	gp,24(sp)
ffffffffc0200e78:	7202                	ld	tp,32(sp)
ffffffffc0200e7a:	72a2                	ld	t0,40(sp)
ffffffffc0200e7c:	7342                	ld	t1,48(sp)
ffffffffc0200e7e:	73e2                	ld	t2,56(sp)
ffffffffc0200e80:	6406                	ld	s0,64(sp)
ffffffffc0200e82:	64a6                	ld	s1,72(sp)
ffffffffc0200e84:	6546                	ld	a0,80(sp)
ffffffffc0200e86:	65e6                	ld	a1,88(sp)
ffffffffc0200e88:	7606                	ld	a2,96(sp)
ffffffffc0200e8a:	76a6                	ld	a3,104(sp)
ffffffffc0200e8c:	7746                	ld	a4,112(sp)
ffffffffc0200e8e:	77e6                	ld	a5,120(sp)
ffffffffc0200e90:	680a                	ld	a6,128(sp)
ffffffffc0200e92:	68aa                	ld	a7,136(sp)
ffffffffc0200e94:	694a                	ld	s2,144(sp)
ffffffffc0200e96:	69ea                	ld	s3,152(sp)
ffffffffc0200e98:	7a0a                	ld	s4,160(sp)
ffffffffc0200e9a:	7aaa                	ld	s5,168(sp)
ffffffffc0200e9c:	7b4a                	ld	s6,176(sp)
ffffffffc0200e9e:	7bea                	ld	s7,184(sp)
ffffffffc0200ea0:	6c0e                	ld	s8,192(sp)
ffffffffc0200ea2:	6cae                	ld	s9,200(sp)
ffffffffc0200ea4:	6d4e                	ld	s10,208(sp)
ffffffffc0200ea6:	6dee                	ld	s11,216(sp)
ffffffffc0200ea8:	7e0e                	ld	t3,224(sp)
ffffffffc0200eaa:	7eae                	ld	t4,232(sp)
ffffffffc0200eac:	7f4e                	ld	t5,240(sp)
ffffffffc0200eae:	7fee                	ld	t6,248(sp)
ffffffffc0200eb0:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
ffffffffc0200eb2:	10200073          	sret

ffffffffc0200eb6 <forkrets>:
 
    .globl forkrets
forkrets:
    # set stack to this new process's trapframe
    move sp, a0
ffffffffc0200eb6:	812a                	mv	sp,a0
ffffffffc0200eb8:	b755                	j	ffffffffc0200e5c <__trapret>

ffffffffc0200eba <default_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0200eba:	000db797          	auipc	a5,0xdb
ffffffffc0200ebe:	bb678793          	addi	a5,a5,-1098 # ffffffffc02dba70 <free_area>
ffffffffc0200ec2:	e79c                	sd	a5,8(a5)
ffffffffc0200ec4:	e39c                	sd	a5,0(a5)
#define nr_free (free_area.nr_free)

static void
default_init(void) {
    list_init(&free_list);
    nr_free = 0;
ffffffffc0200ec6:	0007a823          	sw	zero,16(a5)
}
ffffffffc0200eca:	8082                	ret

ffffffffc0200ecc <default_nr_free_pages>:
}

static size_t
default_nr_free_pages(void) {
    return nr_free;
}
ffffffffc0200ecc:	000db517          	auipc	a0,0xdb
ffffffffc0200ed0:	bb456503          	lwu	a0,-1100(a0) # ffffffffc02dba80 <free_area+0x10>
ffffffffc0200ed4:	8082                	ret

ffffffffc0200ed6 <default_check>:
}

// LAB2: below code is used to check the first fit allocation algorithm (your EXERCISE 1) 
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void) {
ffffffffc0200ed6:	715d                	addi	sp,sp,-80
ffffffffc0200ed8:	e0a2                	sd	s0,64(sp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200eda:	000db417          	auipc	s0,0xdb
ffffffffc0200ede:	b9640413          	addi	s0,s0,-1130 # ffffffffc02dba70 <free_area>
ffffffffc0200ee2:	641c                	ld	a5,8(s0)
ffffffffc0200ee4:	e486                	sd	ra,72(sp)
ffffffffc0200ee6:	fc26                	sd	s1,56(sp)
ffffffffc0200ee8:	f84a                	sd	s2,48(sp)
ffffffffc0200eea:	f44e                	sd	s3,40(sp)
ffffffffc0200eec:	f052                	sd	s4,32(sp)
ffffffffc0200eee:	ec56                	sd	s5,24(sp)
ffffffffc0200ef0:	e85a                	sd	s6,16(sp)
ffffffffc0200ef2:	e45e                	sd	s7,8(sp)
ffffffffc0200ef4:	e062                	sd	s8,0(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200ef6:	2a878d63          	beq	a5,s0,ffffffffc02011b0 <default_check+0x2da>
    int count = 0, total = 0;
ffffffffc0200efa:	4481                	li	s1,0
ffffffffc0200efc:	4901                	li	s2,0
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200efe:	ff07b703          	ld	a4,-16(a5)
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0200f02:	8b09                	andi	a4,a4,2
ffffffffc0200f04:	2a070a63          	beqz	a4,ffffffffc02011b8 <default_check+0x2e2>
        count ++, total += p->property;
ffffffffc0200f08:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200f0c:	679c                	ld	a5,8(a5)
ffffffffc0200f0e:	2905                	addiw	s2,s2,1
ffffffffc0200f10:	9cb9                	addw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200f12:	fe8796e3          	bne	a5,s0,ffffffffc0200efe <default_check+0x28>
    }
    assert(total == nr_free_pages());
ffffffffc0200f16:	89a6                	mv	s3,s1
ffffffffc0200f18:	6df000ef          	jal	ra,ffffffffc0201df6 <nr_free_pages>
ffffffffc0200f1c:	6f351e63          	bne	a0,s3,ffffffffc0201618 <default_check+0x742>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200f20:	4505                	li	a0,1
ffffffffc0200f22:	657000ef          	jal	ra,ffffffffc0201d78 <alloc_pages>
ffffffffc0200f26:	8aaa                	mv	s5,a0
ffffffffc0200f28:	42050863          	beqz	a0,ffffffffc0201358 <default_check+0x482>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200f2c:	4505                	li	a0,1
ffffffffc0200f2e:	64b000ef          	jal	ra,ffffffffc0201d78 <alloc_pages>
ffffffffc0200f32:	89aa                	mv	s3,a0
ffffffffc0200f34:	70050263          	beqz	a0,ffffffffc0201638 <default_check+0x762>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200f38:	4505                	li	a0,1
ffffffffc0200f3a:	63f000ef          	jal	ra,ffffffffc0201d78 <alloc_pages>
ffffffffc0200f3e:	8a2a                	mv	s4,a0
ffffffffc0200f40:	48050c63          	beqz	a0,ffffffffc02013d8 <default_check+0x502>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200f44:	293a8a63          	beq	s5,s3,ffffffffc02011d8 <default_check+0x302>
ffffffffc0200f48:	28aa8863          	beq	s5,a0,ffffffffc02011d8 <default_check+0x302>
ffffffffc0200f4c:	28a98663          	beq	s3,a0,ffffffffc02011d8 <default_check+0x302>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200f50:	000aa783          	lw	a5,0(s5)
ffffffffc0200f54:	2a079263          	bnez	a5,ffffffffc02011f8 <default_check+0x322>
ffffffffc0200f58:	0009a783          	lw	a5,0(s3)
ffffffffc0200f5c:	28079e63          	bnez	a5,ffffffffc02011f8 <default_check+0x322>
ffffffffc0200f60:	411c                	lw	a5,0(a0)
ffffffffc0200f62:	28079b63          	bnez	a5,ffffffffc02011f8 <default_check+0x322>
extern uint_t va_pa_offset;

static inline ppn_t
page2ppn(struct Page *page)
{
    return page - pages + nbase;
ffffffffc0200f66:	000df797          	auipc	a5,0xdf
ffffffffc0200f6a:	cf27b783          	ld	a5,-782(a5) # ffffffffc02dfc58 <pages>
ffffffffc0200f6e:	40fa8733          	sub	a4,s5,a5
ffffffffc0200f72:	00008617          	auipc	a2,0x8
ffffffffc0200f76:	2fe63603          	ld	a2,766(a2) # ffffffffc0209270 <nbase>
ffffffffc0200f7a:	8719                	srai	a4,a4,0x6
ffffffffc0200f7c:	9732                	add	a4,a4,a2
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200f7e:	000df697          	auipc	a3,0xdf
ffffffffc0200f82:	cd26b683          	ld	a3,-814(a3) # ffffffffc02dfc50 <npage>
ffffffffc0200f86:	06b2                	slli	a3,a3,0xc
}

static inline uintptr_t
page2pa(struct Page *page)
{
    return page2ppn(page) << PGSHIFT;
ffffffffc0200f88:	0732                	slli	a4,a4,0xc
ffffffffc0200f8a:	28d77763          	bgeu	a4,a3,ffffffffc0201218 <default_check+0x342>
    return page - pages + nbase;
ffffffffc0200f8e:	40f98733          	sub	a4,s3,a5
ffffffffc0200f92:	8719                	srai	a4,a4,0x6
ffffffffc0200f94:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200f96:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200f98:	4cd77063          	bgeu	a4,a3,ffffffffc0201458 <default_check+0x582>
    return page - pages + nbase;
ffffffffc0200f9c:	40f507b3          	sub	a5,a0,a5
ffffffffc0200fa0:	8799                	srai	a5,a5,0x6
ffffffffc0200fa2:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200fa4:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200fa6:	30d7f963          	bgeu	a5,a3,ffffffffc02012b8 <default_check+0x3e2>
    assert(alloc_page() == NULL);
ffffffffc0200faa:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200fac:	00043c03          	ld	s8,0(s0)
ffffffffc0200fb0:	00843b83          	ld	s7,8(s0)
    unsigned int nr_free_store = nr_free;
ffffffffc0200fb4:	01042b03          	lw	s6,16(s0)
    elm->prev = elm->next = elm;
ffffffffc0200fb8:	e400                	sd	s0,8(s0)
ffffffffc0200fba:	e000                	sd	s0,0(s0)
    nr_free = 0;
ffffffffc0200fbc:	000db797          	auipc	a5,0xdb
ffffffffc0200fc0:	ac07a223          	sw	zero,-1340(a5) # ffffffffc02dba80 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc0200fc4:	5b5000ef          	jal	ra,ffffffffc0201d78 <alloc_pages>
ffffffffc0200fc8:	2c051863          	bnez	a0,ffffffffc0201298 <default_check+0x3c2>
    free_page(p0);
ffffffffc0200fcc:	4585                	li	a1,1
ffffffffc0200fce:	8556                	mv	a0,s5
ffffffffc0200fd0:	5e7000ef          	jal	ra,ffffffffc0201db6 <free_pages>
    free_page(p1);
ffffffffc0200fd4:	4585                	li	a1,1
ffffffffc0200fd6:	854e                	mv	a0,s3
ffffffffc0200fd8:	5df000ef          	jal	ra,ffffffffc0201db6 <free_pages>
    free_page(p2);
ffffffffc0200fdc:	4585                	li	a1,1
ffffffffc0200fde:	8552                	mv	a0,s4
ffffffffc0200fe0:	5d7000ef          	jal	ra,ffffffffc0201db6 <free_pages>
    assert(nr_free == 3);
ffffffffc0200fe4:	4818                	lw	a4,16(s0)
ffffffffc0200fe6:	478d                	li	a5,3
ffffffffc0200fe8:	28f71863          	bne	a4,a5,ffffffffc0201278 <default_check+0x3a2>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200fec:	4505                	li	a0,1
ffffffffc0200fee:	58b000ef          	jal	ra,ffffffffc0201d78 <alloc_pages>
ffffffffc0200ff2:	89aa                	mv	s3,a0
ffffffffc0200ff4:	26050263          	beqz	a0,ffffffffc0201258 <default_check+0x382>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200ff8:	4505                	li	a0,1
ffffffffc0200ffa:	57f000ef          	jal	ra,ffffffffc0201d78 <alloc_pages>
ffffffffc0200ffe:	8aaa                	mv	s5,a0
ffffffffc0201000:	3a050c63          	beqz	a0,ffffffffc02013b8 <default_check+0x4e2>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201004:	4505                	li	a0,1
ffffffffc0201006:	573000ef          	jal	ra,ffffffffc0201d78 <alloc_pages>
ffffffffc020100a:	8a2a                	mv	s4,a0
ffffffffc020100c:	38050663          	beqz	a0,ffffffffc0201398 <default_check+0x4c2>
    assert(alloc_page() == NULL);
ffffffffc0201010:	4505                	li	a0,1
ffffffffc0201012:	567000ef          	jal	ra,ffffffffc0201d78 <alloc_pages>
ffffffffc0201016:	36051163          	bnez	a0,ffffffffc0201378 <default_check+0x4a2>
    free_page(p0);
ffffffffc020101a:	4585                	li	a1,1
ffffffffc020101c:	854e                	mv	a0,s3
ffffffffc020101e:	599000ef          	jal	ra,ffffffffc0201db6 <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0201022:	641c                	ld	a5,8(s0)
ffffffffc0201024:	20878a63          	beq	a5,s0,ffffffffc0201238 <default_check+0x362>
    assert((p = alloc_page()) == p0);
ffffffffc0201028:	4505                	li	a0,1
ffffffffc020102a:	54f000ef          	jal	ra,ffffffffc0201d78 <alloc_pages>
ffffffffc020102e:	30a99563          	bne	s3,a0,ffffffffc0201338 <default_check+0x462>
    assert(alloc_page() == NULL);
ffffffffc0201032:	4505                	li	a0,1
ffffffffc0201034:	545000ef          	jal	ra,ffffffffc0201d78 <alloc_pages>
ffffffffc0201038:	2e051063          	bnez	a0,ffffffffc0201318 <default_check+0x442>
    assert(nr_free == 0);
ffffffffc020103c:	481c                	lw	a5,16(s0)
ffffffffc020103e:	2a079d63          	bnez	a5,ffffffffc02012f8 <default_check+0x422>
    free_page(p);
ffffffffc0201042:	854e                	mv	a0,s3
ffffffffc0201044:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0201046:	01843023          	sd	s8,0(s0)
ffffffffc020104a:	01743423          	sd	s7,8(s0)
    nr_free = nr_free_store;
ffffffffc020104e:	01642823          	sw	s6,16(s0)
    free_page(p);
ffffffffc0201052:	565000ef          	jal	ra,ffffffffc0201db6 <free_pages>
    free_page(p1);
ffffffffc0201056:	4585                	li	a1,1
ffffffffc0201058:	8556                	mv	a0,s5
ffffffffc020105a:	55d000ef          	jal	ra,ffffffffc0201db6 <free_pages>
    free_page(p2);
ffffffffc020105e:	4585                	li	a1,1
ffffffffc0201060:	8552                	mv	a0,s4
ffffffffc0201062:	555000ef          	jal	ra,ffffffffc0201db6 <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0201066:	4515                	li	a0,5
ffffffffc0201068:	511000ef          	jal	ra,ffffffffc0201d78 <alloc_pages>
ffffffffc020106c:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc020106e:	26050563          	beqz	a0,ffffffffc02012d8 <default_check+0x402>
ffffffffc0201072:	651c                	ld	a5,8(a0)
ffffffffc0201074:	8385                	srli	a5,a5,0x1
ffffffffc0201076:	8b85                	andi	a5,a5,1
    assert(!PageProperty(p0));
ffffffffc0201078:	54079063          	bnez	a5,ffffffffc02015b8 <default_check+0x6e2>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc020107c:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc020107e:	00043b03          	ld	s6,0(s0)
ffffffffc0201082:	00843a83          	ld	s5,8(s0)
ffffffffc0201086:	e000                	sd	s0,0(s0)
ffffffffc0201088:	e400                	sd	s0,8(s0)
    assert(alloc_page() == NULL);
ffffffffc020108a:	4ef000ef          	jal	ra,ffffffffc0201d78 <alloc_pages>
ffffffffc020108e:	50051563          	bnez	a0,ffffffffc0201598 <default_check+0x6c2>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc0201092:	08098a13          	addi	s4,s3,128
ffffffffc0201096:	8552                	mv	a0,s4
ffffffffc0201098:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc020109a:	01042b83          	lw	s7,16(s0)
    nr_free = 0;
ffffffffc020109e:	000db797          	auipc	a5,0xdb
ffffffffc02010a2:	9e07a123          	sw	zero,-1566(a5) # ffffffffc02dba80 <free_area+0x10>
    free_pages(p0 + 2, 3);
ffffffffc02010a6:	511000ef          	jal	ra,ffffffffc0201db6 <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc02010aa:	4511                	li	a0,4
ffffffffc02010ac:	4cd000ef          	jal	ra,ffffffffc0201d78 <alloc_pages>
ffffffffc02010b0:	4c051463          	bnez	a0,ffffffffc0201578 <default_check+0x6a2>
ffffffffc02010b4:	0889b783          	ld	a5,136(s3)
ffffffffc02010b8:	8385                	srli	a5,a5,0x1
ffffffffc02010ba:	8b85                	andi	a5,a5,1
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc02010bc:	48078e63          	beqz	a5,ffffffffc0201558 <default_check+0x682>
ffffffffc02010c0:	0909a703          	lw	a4,144(s3)
ffffffffc02010c4:	478d                	li	a5,3
ffffffffc02010c6:	48f71963          	bne	a4,a5,ffffffffc0201558 <default_check+0x682>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc02010ca:	450d                	li	a0,3
ffffffffc02010cc:	4ad000ef          	jal	ra,ffffffffc0201d78 <alloc_pages>
ffffffffc02010d0:	8c2a                	mv	s8,a0
ffffffffc02010d2:	46050363          	beqz	a0,ffffffffc0201538 <default_check+0x662>
    assert(alloc_page() == NULL);
ffffffffc02010d6:	4505                	li	a0,1
ffffffffc02010d8:	4a1000ef          	jal	ra,ffffffffc0201d78 <alloc_pages>
ffffffffc02010dc:	42051e63          	bnez	a0,ffffffffc0201518 <default_check+0x642>
    assert(p0 + 2 == p1);
ffffffffc02010e0:	418a1c63          	bne	s4,s8,ffffffffc02014f8 <default_check+0x622>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc02010e4:	4585                	li	a1,1
ffffffffc02010e6:	854e                	mv	a0,s3
ffffffffc02010e8:	4cf000ef          	jal	ra,ffffffffc0201db6 <free_pages>
    free_pages(p1, 3);
ffffffffc02010ec:	458d                	li	a1,3
ffffffffc02010ee:	8552                	mv	a0,s4
ffffffffc02010f0:	4c7000ef          	jal	ra,ffffffffc0201db6 <free_pages>
ffffffffc02010f4:	0089b783          	ld	a5,8(s3)
    p2 = p0 + 1;
ffffffffc02010f8:	04098c13          	addi	s8,s3,64
ffffffffc02010fc:	8385                	srli	a5,a5,0x1
ffffffffc02010fe:	8b85                	andi	a5,a5,1
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0201100:	3c078c63          	beqz	a5,ffffffffc02014d8 <default_check+0x602>
ffffffffc0201104:	0109a703          	lw	a4,16(s3)
ffffffffc0201108:	4785                	li	a5,1
ffffffffc020110a:	3cf71763          	bne	a4,a5,ffffffffc02014d8 <default_check+0x602>
ffffffffc020110e:	008a3783          	ld	a5,8(s4)
ffffffffc0201112:	8385                	srli	a5,a5,0x1
ffffffffc0201114:	8b85                	andi	a5,a5,1
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0201116:	3a078163          	beqz	a5,ffffffffc02014b8 <default_check+0x5e2>
ffffffffc020111a:	010a2703          	lw	a4,16(s4)
ffffffffc020111e:	478d                	li	a5,3
ffffffffc0201120:	38f71c63          	bne	a4,a5,ffffffffc02014b8 <default_check+0x5e2>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0201124:	4505                	li	a0,1
ffffffffc0201126:	453000ef          	jal	ra,ffffffffc0201d78 <alloc_pages>
ffffffffc020112a:	36a99763          	bne	s3,a0,ffffffffc0201498 <default_check+0x5c2>
    free_page(p0);
ffffffffc020112e:	4585                	li	a1,1
ffffffffc0201130:	487000ef          	jal	ra,ffffffffc0201db6 <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0201134:	4509                	li	a0,2
ffffffffc0201136:	443000ef          	jal	ra,ffffffffc0201d78 <alloc_pages>
ffffffffc020113a:	32aa1f63          	bne	s4,a0,ffffffffc0201478 <default_check+0x5a2>

    free_pages(p0, 2);
ffffffffc020113e:	4589                	li	a1,2
ffffffffc0201140:	477000ef          	jal	ra,ffffffffc0201db6 <free_pages>
    free_page(p2);
ffffffffc0201144:	4585                	li	a1,1
ffffffffc0201146:	8562                	mv	a0,s8
ffffffffc0201148:	46f000ef          	jal	ra,ffffffffc0201db6 <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc020114c:	4515                	li	a0,5
ffffffffc020114e:	42b000ef          	jal	ra,ffffffffc0201d78 <alloc_pages>
ffffffffc0201152:	89aa                	mv	s3,a0
ffffffffc0201154:	48050263          	beqz	a0,ffffffffc02015d8 <default_check+0x702>
    assert(alloc_page() == NULL);
ffffffffc0201158:	4505                	li	a0,1
ffffffffc020115a:	41f000ef          	jal	ra,ffffffffc0201d78 <alloc_pages>
ffffffffc020115e:	2c051d63          	bnez	a0,ffffffffc0201438 <default_check+0x562>

    assert(nr_free == 0);
ffffffffc0201162:	481c                	lw	a5,16(s0)
ffffffffc0201164:	2a079a63          	bnez	a5,ffffffffc0201418 <default_check+0x542>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc0201168:	4595                	li	a1,5
ffffffffc020116a:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc020116c:	01742823          	sw	s7,16(s0)
    free_list = free_list_store;
ffffffffc0201170:	01643023          	sd	s6,0(s0)
ffffffffc0201174:	01543423          	sd	s5,8(s0)
    free_pages(p0, 5);
ffffffffc0201178:	43f000ef          	jal	ra,ffffffffc0201db6 <free_pages>
    return listelm->next;
ffffffffc020117c:	641c                	ld	a5,8(s0)

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc020117e:	00878963          	beq	a5,s0,ffffffffc0201190 <default_check+0x2ba>
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
ffffffffc0201182:	ff87a703          	lw	a4,-8(a5)
ffffffffc0201186:	679c                	ld	a5,8(a5)
ffffffffc0201188:	397d                	addiw	s2,s2,-1
ffffffffc020118a:	9c99                	subw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc020118c:	fe879be3          	bne	a5,s0,ffffffffc0201182 <default_check+0x2ac>
    }
    assert(count == 0);
ffffffffc0201190:	26091463          	bnez	s2,ffffffffc02013f8 <default_check+0x522>
    assert(total == 0);
ffffffffc0201194:	46049263          	bnez	s1,ffffffffc02015f8 <default_check+0x722>
}
ffffffffc0201198:	60a6                	ld	ra,72(sp)
ffffffffc020119a:	6406                	ld	s0,64(sp)
ffffffffc020119c:	74e2                	ld	s1,56(sp)
ffffffffc020119e:	7942                	ld	s2,48(sp)
ffffffffc02011a0:	79a2                	ld	s3,40(sp)
ffffffffc02011a2:	7a02                	ld	s4,32(sp)
ffffffffc02011a4:	6ae2                	ld	s5,24(sp)
ffffffffc02011a6:	6b42                	ld	s6,16(sp)
ffffffffc02011a8:	6ba2                	ld	s7,8(sp)
ffffffffc02011aa:	6c02                	ld	s8,0(sp)
ffffffffc02011ac:	6161                	addi	sp,sp,80
ffffffffc02011ae:	8082                	ret
    while ((le = list_next(le)) != &free_list) {
ffffffffc02011b0:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc02011b2:	4481                	li	s1,0
ffffffffc02011b4:	4901                	li	s2,0
ffffffffc02011b6:	b38d                	j	ffffffffc0200f18 <default_check+0x42>
        assert(PageProperty(p));
ffffffffc02011b8:	00006697          	auipc	a3,0x6
ffffffffc02011bc:	d4068693          	addi	a3,a3,-704 # ffffffffc0206ef8 <commands+0x808>
ffffffffc02011c0:	00006617          	auipc	a2,0x6
ffffffffc02011c4:	d4860613          	addi	a2,a2,-696 # ffffffffc0206f08 <commands+0x818>
ffffffffc02011c8:	0ef00593          	li	a1,239
ffffffffc02011cc:	00006517          	auipc	a0,0x6
ffffffffc02011d0:	d5450513          	addi	a0,a0,-684 # ffffffffc0206f20 <commands+0x830>
ffffffffc02011d4:	abeff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc02011d8:	00006697          	auipc	a3,0x6
ffffffffc02011dc:	de068693          	addi	a3,a3,-544 # ffffffffc0206fb8 <commands+0x8c8>
ffffffffc02011e0:	00006617          	auipc	a2,0x6
ffffffffc02011e4:	d2860613          	addi	a2,a2,-728 # ffffffffc0206f08 <commands+0x818>
ffffffffc02011e8:	0bc00593          	li	a1,188
ffffffffc02011ec:	00006517          	auipc	a0,0x6
ffffffffc02011f0:	d3450513          	addi	a0,a0,-716 # ffffffffc0206f20 <commands+0x830>
ffffffffc02011f4:	a9eff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc02011f8:	00006697          	auipc	a3,0x6
ffffffffc02011fc:	de868693          	addi	a3,a3,-536 # ffffffffc0206fe0 <commands+0x8f0>
ffffffffc0201200:	00006617          	auipc	a2,0x6
ffffffffc0201204:	d0860613          	addi	a2,a2,-760 # ffffffffc0206f08 <commands+0x818>
ffffffffc0201208:	0bd00593          	li	a1,189
ffffffffc020120c:	00006517          	auipc	a0,0x6
ffffffffc0201210:	d1450513          	addi	a0,a0,-748 # ffffffffc0206f20 <commands+0x830>
ffffffffc0201214:	a7eff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0201218:	00006697          	auipc	a3,0x6
ffffffffc020121c:	e0868693          	addi	a3,a3,-504 # ffffffffc0207020 <commands+0x930>
ffffffffc0201220:	00006617          	auipc	a2,0x6
ffffffffc0201224:	ce860613          	addi	a2,a2,-792 # ffffffffc0206f08 <commands+0x818>
ffffffffc0201228:	0bf00593          	li	a1,191
ffffffffc020122c:	00006517          	auipc	a0,0x6
ffffffffc0201230:	cf450513          	addi	a0,a0,-780 # ffffffffc0206f20 <commands+0x830>
ffffffffc0201234:	a5eff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(!list_empty(&free_list));
ffffffffc0201238:	00006697          	auipc	a3,0x6
ffffffffc020123c:	e7068693          	addi	a3,a3,-400 # ffffffffc02070a8 <commands+0x9b8>
ffffffffc0201240:	00006617          	auipc	a2,0x6
ffffffffc0201244:	cc860613          	addi	a2,a2,-824 # ffffffffc0206f08 <commands+0x818>
ffffffffc0201248:	0d800593          	li	a1,216
ffffffffc020124c:	00006517          	auipc	a0,0x6
ffffffffc0201250:	cd450513          	addi	a0,a0,-812 # ffffffffc0206f20 <commands+0x830>
ffffffffc0201254:	a3eff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201258:	00006697          	auipc	a3,0x6
ffffffffc020125c:	d0068693          	addi	a3,a3,-768 # ffffffffc0206f58 <commands+0x868>
ffffffffc0201260:	00006617          	auipc	a2,0x6
ffffffffc0201264:	ca860613          	addi	a2,a2,-856 # ffffffffc0206f08 <commands+0x818>
ffffffffc0201268:	0d100593          	li	a1,209
ffffffffc020126c:	00006517          	auipc	a0,0x6
ffffffffc0201270:	cb450513          	addi	a0,a0,-844 # ffffffffc0206f20 <commands+0x830>
ffffffffc0201274:	a1eff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(nr_free == 3);
ffffffffc0201278:	00006697          	auipc	a3,0x6
ffffffffc020127c:	e2068693          	addi	a3,a3,-480 # ffffffffc0207098 <commands+0x9a8>
ffffffffc0201280:	00006617          	auipc	a2,0x6
ffffffffc0201284:	c8860613          	addi	a2,a2,-888 # ffffffffc0206f08 <commands+0x818>
ffffffffc0201288:	0cf00593          	li	a1,207
ffffffffc020128c:	00006517          	auipc	a0,0x6
ffffffffc0201290:	c9450513          	addi	a0,a0,-876 # ffffffffc0206f20 <commands+0x830>
ffffffffc0201294:	9feff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201298:	00006697          	auipc	a3,0x6
ffffffffc020129c:	de868693          	addi	a3,a3,-536 # ffffffffc0207080 <commands+0x990>
ffffffffc02012a0:	00006617          	auipc	a2,0x6
ffffffffc02012a4:	c6860613          	addi	a2,a2,-920 # ffffffffc0206f08 <commands+0x818>
ffffffffc02012a8:	0ca00593          	li	a1,202
ffffffffc02012ac:	00006517          	auipc	a0,0x6
ffffffffc02012b0:	c7450513          	addi	a0,a0,-908 # ffffffffc0206f20 <commands+0x830>
ffffffffc02012b4:	9deff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc02012b8:	00006697          	auipc	a3,0x6
ffffffffc02012bc:	da868693          	addi	a3,a3,-600 # ffffffffc0207060 <commands+0x970>
ffffffffc02012c0:	00006617          	auipc	a2,0x6
ffffffffc02012c4:	c4860613          	addi	a2,a2,-952 # ffffffffc0206f08 <commands+0x818>
ffffffffc02012c8:	0c100593          	li	a1,193
ffffffffc02012cc:	00006517          	auipc	a0,0x6
ffffffffc02012d0:	c5450513          	addi	a0,a0,-940 # ffffffffc0206f20 <commands+0x830>
ffffffffc02012d4:	9beff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(p0 != NULL);
ffffffffc02012d8:	00006697          	auipc	a3,0x6
ffffffffc02012dc:	e1868693          	addi	a3,a3,-488 # ffffffffc02070f0 <commands+0xa00>
ffffffffc02012e0:	00006617          	auipc	a2,0x6
ffffffffc02012e4:	c2860613          	addi	a2,a2,-984 # ffffffffc0206f08 <commands+0x818>
ffffffffc02012e8:	0f700593          	li	a1,247
ffffffffc02012ec:	00006517          	auipc	a0,0x6
ffffffffc02012f0:	c3450513          	addi	a0,a0,-972 # ffffffffc0206f20 <commands+0x830>
ffffffffc02012f4:	99eff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(nr_free == 0);
ffffffffc02012f8:	00006697          	auipc	a3,0x6
ffffffffc02012fc:	de868693          	addi	a3,a3,-536 # ffffffffc02070e0 <commands+0x9f0>
ffffffffc0201300:	00006617          	auipc	a2,0x6
ffffffffc0201304:	c0860613          	addi	a2,a2,-1016 # ffffffffc0206f08 <commands+0x818>
ffffffffc0201308:	0de00593          	li	a1,222
ffffffffc020130c:	00006517          	auipc	a0,0x6
ffffffffc0201310:	c1450513          	addi	a0,a0,-1004 # ffffffffc0206f20 <commands+0x830>
ffffffffc0201314:	97eff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201318:	00006697          	auipc	a3,0x6
ffffffffc020131c:	d6868693          	addi	a3,a3,-664 # ffffffffc0207080 <commands+0x990>
ffffffffc0201320:	00006617          	auipc	a2,0x6
ffffffffc0201324:	be860613          	addi	a2,a2,-1048 # ffffffffc0206f08 <commands+0x818>
ffffffffc0201328:	0dc00593          	li	a1,220
ffffffffc020132c:	00006517          	auipc	a0,0x6
ffffffffc0201330:	bf450513          	addi	a0,a0,-1036 # ffffffffc0206f20 <commands+0x830>
ffffffffc0201334:	95eff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc0201338:	00006697          	auipc	a3,0x6
ffffffffc020133c:	d8868693          	addi	a3,a3,-632 # ffffffffc02070c0 <commands+0x9d0>
ffffffffc0201340:	00006617          	auipc	a2,0x6
ffffffffc0201344:	bc860613          	addi	a2,a2,-1080 # ffffffffc0206f08 <commands+0x818>
ffffffffc0201348:	0db00593          	li	a1,219
ffffffffc020134c:	00006517          	auipc	a0,0x6
ffffffffc0201350:	bd450513          	addi	a0,a0,-1068 # ffffffffc0206f20 <commands+0x830>
ffffffffc0201354:	93eff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201358:	00006697          	auipc	a3,0x6
ffffffffc020135c:	c0068693          	addi	a3,a3,-1024 # ffffffffc0206f58 <commands+0x868>
ffffffffc0201360:	00006617          	auipc	a2,0x6
ffffffffc0201364:	ba860613          	addi	a2,a2,-1112 # ffffffffc0206f08 <commands+0x818>
ffffffffc0201368:	0b800593          	li	a1,184
ffffffffc020136c:	00006517          	auipc	a0,0x6
ffffffffc0201370:	bb450513          	addi	a0,a0,-1100 # ffffffffc0206f20 <commands+0x830>
ffffffffc0201374:	91eff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201378:	00006697          	auipc	a3,0x6
ffffffffc020137c:	d0868693          	addi	a3,a3,-760 # ffffffffc0207080 <commands+0x990>
ffffffffc0201380:	00006617          	auipc	a2,0x6
ffffffffc0201384:	b8860613          	addi	a2,a2,-1144 # ffffffffc0206f08 <commands+0x818>
ffffffffc0201388:	0d500593          	li	a1,213
ffffffffc020138c:	00006517          	auipc	a0,0x6
ffffffffc0201390:	b9450513          	addi	a0,a0,-1132 # ffffffffc0206f20 <commands+0x830>
ffffffffc0201394:	8feff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201398:	00006697          	auipc	a3,0x6
ffffffffc020139c:	c0068693          	addi	a3,a3,-1024 # ffffffffc0206f98 <commands+0x8a8>
ffffffffc02013a0:	00006617          	auipc	a2,0x6
ffffffffc02013a4:	b6860613          	addi	a2,a2,-1176 # ffffffffc0206f08 <commands+0x818>
ffffffffc02013a8:	0d300593          	li	a1,211
ffffffffc02013ac:	00006517          	auipc	a0,0x6
ffffffffc02013b0:	b7450513          	addi	a0,a0,-1164 # ffffffffc0206f20 <commands+0x830>
ffffffffc02013b4:	8deff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02013b8:	00006697          	auipc	a3,0x6
ffffffffc02013bc:	bc068693          	addi	a3,a3,-1088 # ffffffffc0206f78 <commands+0x888>
ffffffffc02013c0:	00006617          	auipc	a2,0x6
ffffffffc02013c4:	b4860613          	addi	a2,a2,-1208 # ffffffffc0206f08 <commands+0x818>
ffffffffc02013c8:	0d200593          	li	a1,210
ffffffffc02013cc:	00006517          	auipc	a0,0x6
ffffffffc02013d0:	b5450513          	addi	a0,a0,-1196 # ffffffffc0206f20 <commands+0x830>
ffffffffc02013d4:	8beff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02013d8:	00006697          	auipc	a3,0x6
ffffffffc02013dc:	bc068693          	addi	a3,a3,-1088 # ffffffffc0206f98 <commands+0x8a8>
ffffffffc02013e0:	00006617          	auipc	a2,0x6
ffffffffc02013e4:	b2860613          	addi	a2,a2,-1240 # ffffffffc0206f08 <commands+0x818>
ffffffffc02013e8:	0ba00593          	li	a1,186
ffffffffc02013ec:	00006517          	auipc	a0,0x6
ffffffffc02013f0:	b3450513          	addi	a0,a0,-1228 # ffffffffc0206f20 <commands+0x830>
ffffffffc02013f4:	89eff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(count == 0);
ffffffffc02013f8:	00006697          	auipc	a3,0x6
ffffffffc02013fc:	e4868693          	addi	a3,a3,-440 # ffffffffc0207240 <commands+0xb50>
ffffffffc0201400:	00006617          	auipc	a2,0x6
ffffffffc0201404:	b0860613          	addi	a2,a2,-1272 # ffffffffc0206f08 <commands+0x818>
ffffffffc0201408:	12400593          	li	a1,292
ffffffffc020140c:	00006517          	auipc	a0,0x6
ffffffffc0201410:	b1450513          	addi	a0,a0,-1260 # ffffffffc0206f20 <commands+0x830>
ffffffffc0201414:	87eff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(nr_free == 0);
ffffffffc0201418:	00006697          	auipc	a3,0x6
ffffffffc020141c:	cc868693          	addi	a3,a3,-824 # ffffffffc02070e0 <commands+0x9f0>
ffffffffc0201420:	00006617          	auipc	a2,0x6
ffffffffc0201424:	ae860613          	addi	a2,a2,-1304 # ffffffffc0206f08 <commands+0x818>
ffffffffc0201428:	11900593          	li	a1,281
ffffffffc020142c:	00006517          	auipc	a0,0x6
ffffffffc0201430:	af450513          	addi	a0,a0,-1292 # ffffffffc0206f20 <commands+0x830>
ffffffffc0201434:	85eff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201438:	00006697          	auipc	a3,0x6
ffffffffc020143c:	c4868693          	addi	a3,a3,-952 # ffffffffc0207080 <commands+0x990>
ffffffffc0201440:	00006617          	auipc	a2,0x6
ffffffffc0201444:	ac860613          	addi	a2,a2,-1336 # ffffffffc0206f08 <commands+0x818>
ffffffffc0201448:	11700593          	li	a1,279
ffffffffc020144c:	00006517          	auipc	a0,0x6
ffffffffc0201450:	ad450513          	addi	a0,a0,-1324 # ffffffffc0206f20 <commands+0x830>
ffffffffc0201454:	83eff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0201458:	00006697          	auipc	a3,0x6
ffffffffc020145c:	be868693          	addi	a3,a3,-1048 # ffffffffc0207040 <commands+0x950>
ffffffffc0201460:	00006617          	auipc	a2,0x6
ffffffffc0201464:	aa860613          	addi	a2,a2,-1368 # ffffffffc0206f08 <commands+0x818>
ffffffffc0201468:	0c000593          	li	a1,192
ffffffffc020146c:	00006517          	auipc	a0,0x6
ffffffffc0201470:	ab450513          	addi	a0,a0,-1356 # ffffffffc0206f20 <commands+0x830>
ffffffffc0201474:	81eff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0201478:	00006697          	auipc	a3,0x6
ffffffffc020147c:	d8868693          	addi	a3,a3,-632 # ffffffffc0207200 <commands+0xb10>
ffffffffc0201480:	00006617          	auipc	a2,0x6
ffffffffc0201484:	a8860613          	addi	a2,a2,-1400 # ffffffffc0206f08 <commands+0x818>
ffffffffc0201488:	11100593          	li	a1,273
ffffffffc020148c:	00006517          	auipc	a0,0x6
ffffffffc0201490:	a9450513          	addi	a0,a0,-1388 # ffffffffc0206f20 <commands+0x830>
ffffffffc0201494:	ffffe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0201498:	00006697          	auipc	a3,0x6
ffffffffc020149c:	d4868693          	addi	a3,a3,-696 # ffffffffc02071e0 <commands+0xaf0>
ffffffffc02014a0:	00006617          	auipc	a2,0x6
ffffffffc02014a4:	a6860613          	addi	a2,a2,-1432 # ffffffffc0206f08 <commands+0x818>
ffffffffc02014a8:	10f00593          	li	a1,271
ffffffffc02014ac:	00006517          	auipc	a0,0x6
ffffffffc02014b0:	a7450513          	addi	a0,a0,-1420 # ffffffffc0206f20 <commands+0x830>
ffffffffc02014b4:	fdffe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc02014b8:	00006697          	auipc	a3,0x6
ffffffffc02014bc:	d0068693          	addi	a3,a3,-768 # ffffffffc02071b8 <commands+0xac8>
ffffffffc02014c0:	00006617          	auipc	a2,0x6
ffffffffc02014c4:	a4860613          	addi	a2,a2,-1464 # ffffffffc0206f08 <commands+0x818>
ffffffffc02014c8:	10d00593          	li	a1,269
ffffffffc02014cc:	00006517          	auipc	a0,0x6
ffffffffc02014d0:	a5450513          	addi	a0,a0,-1452 # ffffffffc0206f20 <commands+0x830>
ffffffffc02014d4:	fbffe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc02014d8:	00006697          	auipc	a3,0x6
ffffffffc02014dc:	cb868693          	addi	a3,a3,-840 # ffffffffc0207190 <commands+0xaa0>
ffffffffc02014e0:	00006617          	auipc	a2,0x6
ffffffffc02014e4:	a2860613          	addi	a2,a2,-1496 # ffffffffc0206f08 <commands+0x818>
ffffffffc02014e8:	10c00593          	li	a1,268
ffffffffc02014ec:	00006517          	auipc	a0,0x6
ffffffffc02014f0:	a3450513          	addi	a0,a0,-1484 # ffffffffc0206f20 <commands+0x830>
ffffffffc02014f4:	f9ffe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(p0 + 2 == p1);
ffffffffc02014f8:	00006697          	auipc	a3,0x6
ffffffffc02014fc:	c8868693          	addi	a3,a3,-888 # ffffffffc0207180 <commands+0xa90>
ffffffffc0201500:	00006617          	auipc	a2,0x6
ffffffffc0201504:	a0860613          	addi	a2,a2,-1528 # ffffffffc0206f08 <commands+0x818>
ffffffffc0201508:	10700593          	li	a1,263
ffffffffc020150c:	00006517          	auipc	a0,0x6
ffffffffc0201510:	a1450513          	addi	a0,a0,-1516 # ffffffffc0206f20 <commands+0x830>
ffffffffc0201514:	f7ffe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201518:	00006697          	auipc	a3,0x6
ffffffffc020151c:	b6868693          	addi	a3,a3,-1176 # ffffffffc0207080 <commands+0x990>
ffffffffc0201520:	00006617          	auipc	a2,0x6
ffffffffc0201524:	9e860613          	addi	a2,a2,-1560 # ffffffffc0206f08 <commands+0x818>
ffffffffc0201528:	10600593          	li	a1,262
ffffffffc020152c:	00006517          	auipc	a0,0x6
ffffffffc0201530:	9f450513          	addi	a0,a0,-1548 # ffffffffc0206f20 <commands+0x830>
ffffffffc0201534:	f5ffe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0201538:	00006697          	auipc	a3,0x6
ffffffffc020153c:	c2868693          	addi	a3,a3,-984 # ffffffffc0207160 <commands+0xa70>
ffffffffc0201540:	00006617          	auipc	a2,0x6
ffffffffc0201544:	9c860613          	addi	a2,a2,-1592 # ffffffffc0206f08 <commands+0x818>
ffffffffc0201548:	10500593          	li	a1,261
ffffffffc020154c:	00006517          	auipc	a0,0x6
ffffffffc0201550:	9d450513          	addi	a0,a0,-1580 # ffffffffc0206f20 <commands+0x830>
ffffffffc0201554:	f3ffe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0201558:	00006697          	auipc	a3,0x6
ffffffffc020155c:	bd868693          	addi	a3,a3,-1064 # ffffffffc0207130 <commands+0xa40>
ffffffffc0201560:	00006617          	auipc	a2,0x6
ffffffffc0201564:	9a860613          	addi	a2,a2,-1624 # ffffffffc0206f08 <commands+0x818>
ffffffffc0201568:	10400593          	li	a1,260
ffffffffc020156c:	00006517          	auipc	a0,0x6
ffffffffc0201570:	9b450513          	addi	a0,a0,-1612 # ffffffffc0206f20 <commands+0x830>
ffffffffc0201574:	f1ffe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc0201578:	00006697          	auipc	a3,0x6
ffffffffc020157c:	ba068693          	addi	a3,a3,-1120 # ffffffffc0207118 <commands+0xa28>
ffffffffc0201580:	00006617          	auipc	a2,0x6
ffffffffc0201584:	98860613          	addi	a2,a2,-1656 # ffffffffc0206f08 <commands+0x818>
ffffffffc0201588:	10300593          	li	a1,259
ffffffffc020158c:	00006517          	auipc	a0,0x6
ffffffffc0201590:	99450513          	addi	a0,a0,-1644 # ffffffffc0206f20 <commands+0x830>
ffffffffc0201594:	efffe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201598:	00006697          	auipc	a3,0x6
ffffffffc020159c:	ae868693          	addi	a3,a3,-1304 # ffffffffc0207080 <commands+0x990>
ffffffffc02015a0:	00006617          	auipc	a2,0x6
ffffffffc02015a4:	96860613          	addi	a2,a2,-1688 # ffffffffc0206f08 <commands+0x818>
ffffffffc02015a8:	0fd00593          	li	a1,253
ffffffffc02015ac:	00006517          	auipc	a0,0x6
ffffffffc02015b0:	97450513          	addi	a0,a0,-1676 # ffffffffc0206f20 <commands+0x830>
ffffffffc02015b4:	edffe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(!PageProperty(p0));
ffffffffc02015b8:	00006697          	auipc	a3,0x6
ffffffffc02015bc:	b4868693          	addi	a3,a3,-1208 # ffffffffc0207100 <commands+0xa10>
ffffffffc02015c0:	00006617          	auipc	a2,0x6
ffffffffc02015c4:	94860613          	addi	a2,a2,-1720 # ffffffffc0206f08 <commands+0x818>
ffffffffc02015c8:	0f800593          	li	a1,248
ffffffffc02015cc:	00006517          	auipc	a0,0x6
ffffffffc02015d0:	95450513          	addi	a0,a0,-1708 # ffffffffc0206f20 <commands+0x830>
ffffffffc02015d4:	ebffe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc02015d8:	00006697          	auipc	a3,0x6
ffffffffc02015dc:	c4868693          	addi	a3,a3,-952 # ffffffffc0207220 <commands+0xb30>
ffffffffc02015e0:	00006617          	auipc	a2,0x6
ffffffffc02015e4:	92860613          	addi	a2,a2,-1752 # ffffffffc0206f08 <commands+0x818>
ffffffffc02015e8:	11600593          	li	a1,278
ffffffffc02015ec:	00006517          	auipc	a0,0x6
ffffffffc02015f0:	93450513          	addi	a0,a0,-1740 # ffffffffc0206f20 <commands+0x830>
ffffffffc02015f4:	e9ffe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(total == 0);
ffffffffc02015f8:	00006697          	auipc	a3,0x6
ffffffffc02015fc:	c5868693          	addi	a3,a3,-936 # ffffffffc0207250 <commands+0xb60>
ffffffffc0201600:	00006617          	auipc	a2,0x6
ffffffffc0201604:	90860613          	addi	a2,a2,-1784 # ffffffffc0206f08 <commands+0x818>
ffffffffc0201608:	12500593          	li	a1,293
ffffffffc020160c:	00006517          	auipc	a0,0x6
ffffffffc0201610:	91450513          	addi	a0,a0,-1772 # ffffffffc0206f20 <commands+0x830>
ffffffffc0201614:	e7ffe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(total == nr_free_pages());
ffffffffc0201618:	00006697          	auipc	a3,0x6
ffffffffc020161c:	92068693          	addi	a3,a3,-1760 # ffffffffc0206f38 <commands+0x848>
ffffffffc0201620:	00006617          	auipc	a2,0x6
ffffffffc0201624:	8e860613          	addi	a2,a2,-1816 # ffffffffc0206f08 <commands+0x818>
ffffffffc0201628:	0f200593          	li	a1,242
ffffffffc020162c:	00006517          	auipc	a0,0x6
ffffffffc0201630:	8f450513          	addi	a0,a0,-1804 # ffffffffc0206f20 <commands+0x830>
ffffffffc0201634:	e5ffe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201638:	00006697          	auipc	a3,0x6
ffffffffc020163c:	94068693          	addi	a3,a3,-1728 # ffffffffc0206f78 <commands+0x888>
ffffffffc0201640:	00006617          	auipc	a2,0x6
ffffffffc0201644:	8c860613          	addi	a2,a2,-1848 # ffffffffc0206f08 <commands+0x818>
ffffffffc0201648:	0b900593          	li	a1,185
ffffffffc020164c:	00006517          	auipc	a0,0x6
ffffffffc0201650:	8d450513          	addi	a0,a0,-1836 # ffffffffc0206f20 <commands+0x830>
ffffffffc0201654:	e3ffe0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0201658 <default_free_pages>:
default_free_pages(struct Page *base, size_t n) {
ffffffffc0201658:	1141                	addi	sp,sp,-16
ffffffffc020165a:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc020165c:	14058463          	beqz	a1,ffffffffc02017a4 <default_free_pages+0x14c>
    for (; p != base + n; p ++) {
ffffffffc0201660:	00659693          	slli	a3,a1,0x6
ffffffffc0201664:	96aa                	add	a3,a3,a0
ffffffffc0201666:	87aa                	mv	a5,a0
ffffffffc0201668:	02d50263          	beq	a0,a3,ffffffffc020168c <default_free_pages+0x34>
ffffffffc020166c:	6798                	ld	a4,8(a5)
ffffffffc020166e:	8b05                	andi	a4,a4,1
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0201670:	10071a63          	bnez	a4,ffffffffc0201784 <default_free_pages+0x12c>
ffffffffc0201674:	6798                	ld	a4,8(a5)
ffffffffc0201676:	8b09                	andi	a4,a4,2
ffffffffc0201678:	10071663          	bnez	a4,ffffffffc0201784 <default_free_pages+0x12c>
        p->flags = 0;
ffffffffc020167c:	0007b423          	sd	zero,8(a5)
}

static inline void
set_page_ref(struct Page *page, int val)
{
    page->ref = val;
ffffffffc0201680:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0201684:	04078793          	addi	a5,a5,64
ffffffffc0201688:	fed792e3          	bne	a5,a3,ffffffffc020166c <default_free_pages+0x14>
    base->property = n;
ffffffffc020168c:	2581                	sext.w	a1,a1
ffffffffc020168e:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc0201690:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201694:	4789                	li	a5,2
ffffffffc0201696:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc020169a:	000da697          	auipc	a3,0xda
ffffffffc020169e:	3d668693          	addi	a3,a3,982 # ffffffffc02dba70 <free_area>
ffffffffc02016a2:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc02016a4:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc02016a6:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc02016aa:	9db9                	addw	a1,a1,a4
ffffffffc02016ac:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list)) {
ffffffffc02016ae:	0ad78463          	beq	a5,a3,ffffffffc0201756 <default_free_pages+0xfe>
            struct Page* page = le2page(le, page_link);
ffffffffc02016b2:	fe878713          	addi	a4,a5,-24
ffffffffc02016b6:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list)) {
ffffffffc02016ba:	4581                	li	a1,0
            if (base < page) {
ffffffffc02016bc:	00e56a63          	bltu	a0,a4,ffffffffc02016d0 <default_free_pages+0x78>
    return listelm->next;
ffffffffc02016c0:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc02016c2:	04d70c63          	beq	a4,a3,ffffffffc020171a <default_free_pages+0xc2>
    for (; p != base + n; p ++) {
ffffffffc02016c6:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc02016c8:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc02016cc:	fee57ae3          	bgeu	a0,a4,ffffffffc02016c0 <default_free_pages+0x68>
ffffffffc02016d0:	c199                	beqz	a1,ffffffffc02016d6 <default_free_pages+0x7e>
ffffffffc02016d2:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc02016d6:	6398                	ld	a4,0(a5)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc02016d8:	e390                	sd	a2,0(a5)
ffffffffc02016da:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc02016dc:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02016de:	ed18                	sd	a4,24(a0)
    if (le != &free_list) {
ffffffffc02016e0:	00d70d63          	beq	a4,a3,ffffffffc02016fa <default_free_pages+0xa2>
        if (p + p->property == base) {
ffffffffc02016e4:	ff872583          	lw	a1,-8(a4)
        p = le2page(le, page_link);
ffffffffc02016e8:	fe870613          	addi	a2,a4,-24
        if (p + p->property == base) {
ffffffffc02016ec:	02059813          	slli	a6,a1,0x20
ffffffffc02016f0:	01a85793          	srli	a5,a6,0x1a
ffffffffc02016f4:	97b2                	add	a5,a5,a2
ffffffffc02016f6:	02f50c63          	beq	a0,a5,ffffffffc020172e <default_free_pages+0xd6>
    return listelm->next;
ffffffffc02016fa:	711c                	ld	a5,32(a0)
    if (le != &free_list) {
ffffffffc02016fc:	00d78c63          	beq	a5,a3,ffffffffc0201714 <default_free_pages+0xbc>
        if (base + base->property == p) {
ffffffffc0201700:	4910                	lw	a2,16(a0)
        p = le2page(le, page_link);
ffffffffc0201702:	fe878693          	addi	a3,a5,-24
        if (base + base->property == p) {
ffffffffc0201706:	02061593          	slli	a1,a2,0x20
ffffffffc020170a:	01a5d713          	srli	a4,a1,0x1a
ffffffffc020170e:	972a                	add	a4,a4,a0
ffffffffc0201710:	04e68a63          	beq	a3,a4,ffffffffc0201764 <default_free_pages+0x10c>
}
ffffffffc0201714:	60a2                	ld	ra,8(sp)
ffffffffc0201716:	0141                	addi	sp,sp,16
ffffffffc0201718:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc020171a:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc020171c:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc020171e:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0201720:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list) {
ffffffffc0201722:	02d70763          	beq	a4,a3,ffffffffc0201750 <default_free_pages+0xf8>
    prev->next = next->prev = elm;
ffffffffc0201726:	8832                	mv	a6,a2
ffffffffc0201728:	4585                	li	a1,1
    for (; p != base + n; p ++) {
ffffffffc020172a:	87ba                	mv	a5,a4
ffffffffc020172c:	bf71                	j	ffffffffc02016c8 <default_free_pages+0x70>
            p->property += base->property;
ffffffffc020172e:	491c                	lw	a5,16(a0)
ffffffffc0201730:	9dbd                	addw	a1,a1,a5
ffffffffc0201732:	feb72c23          	sw	a1,-8(a4)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0201736:	57f5                	li	a5,-3
ffffffffc0201738:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc020173c:	01853803          	ld	a6,24(a0)
ffffffffc0201740:	710c                	ld	a1,32(a0)
            base = p;
ffffffffc0201742:	8532                	mv	a0,a2
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0201744:	00b83423          	sd	a1,8(a6)
    return listelm->next;
ffffffffc0201748:	671c                	ld	a5,8(a4)
    next->prev = prev;
ffffffffc020174a:	0105b023          	sd	a6,0(a1)
ffffffffc020174e:	b77d                	j	ffffffffc02016fc <default_free_pages+0xa4>
ffffffffc0201750:	e290                	sd	a2,0(a3)
        while ((le = list_next(le)) != &free_list) {
ffffffffc0201752:	873e                	mv	a4,a5
ffffffffc0201754:	bf41                	j	ffffffffc02016e4 <default_free_pages+0x8c>
}
ffffffffc0201756:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0201758:	e390                	sd	a2,0(a5)
ffffffffc020175a:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc020175c:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc020175e:	ed1c                	sd	a5,24(a0)
ffffffffc0201760:	0141                	addi	sp,sp,16
ffffffffc0201762:	8082                	ret
            base->property += p->property;
ffffffffc0201764:	ff87a703          	lw	a4,-8(a5)
ffffffffc0201768:	ff078693          	addi	a3,a5,-16
ffffffffc020176c:	9e39                	addw	a2,a2,a4
ffffffffc020176e:	c910                	sw	a2,16(a0)
ffffffffc0201770:	5775                	li	a4,-3
ffffffffc0201772:	60e6b02f          	amoand.d	zero,a4,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201776:	6398                	ld	a4,0(a5)
ffffffffc0201778:	679c                	ld	a5,8(a5)
}
ffffffffc020177a:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc020177c:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc020177e:	e398                	sd	a4,0(a5)
ffffffffc0201780:	0141                	addi	sp,sp,16
ffffffffc0201782:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0201784:	00006697          	auipc	a3,0x6
ffffffffc0201788:	ae468693          	addi	a3,a3,-1308 # ffffffffc0207268 <commands+0xb78>
ffffffffc020178c:	00005617          	auipc	a2,0x5
ffffffffc0201790:	77c60613          	addi	a2,a2,1916 # ffffffffc0206f08 <commands+0x818>
ffffffffc0201794:	08200593          	li	a1,130
ffffffffc0201798:	00005517          	auipc	a0,0x5
ffffffffc020179c:	78850513          	addi	a0,a0,1928 # ffffffffc0206f20 <commands+0x830>
ffffffffc02017a0:	cf3fe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(n > 0);
ffffffffc02017a4:	00006697          	auipc	a3,0x6
ffffffffc02017a8:	abc68693          	addi	a3,a3,-1348 # ffffffffc0207260 <commands+0xb70>
ffffffffc02017ac:	00005617          	auipc	a2,0x5
ffffffffc02017b0:	75c60613          	addi	a2,a2,1884 # ffffffffc0206f08 <commands+0x818>
ffffffffc02017b4:	07f00593          	li	a1,127
ffffffffc02017b8:	00005517          	auipc	a0,0x5
ffffffffc02017bc:	76850513          	addi	a0,a0,1896 # ffffffffc0206f20 <commands+0x830>
ffffffffc02017c0:	cd3fe0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc02017c4 <default_alloc_pages>:
    assert(n > 0);
ffffffffc02017c4:	c941                	beqz	a0,ffffffffc0201854 <default_alloc_pages+0x90>
    if (n > nr_free) {
ffffffffc02017c6:	000da597          	auipc	a1,0xda
ffffffffc02017ca:	2aa58593          	addi	a1,a1,682 # ffffffffc02dba70 <free_area>
ffffffffc02017ce:	0105a803          	lw	a6,16(a1)
ffffffffc02017d2:	872a                	mv	a4,a0
ffffffffc02017d4:	02081793          	slli	a5,a6,0x20
ffffffffc02017d8:	9381                	srli	a5,a5,0x20
ffffffffc02017da:	00a7ee63          	bltu	a5,a0,ffffffffc02017f6 <default_alloc_pages+0x32>
    list_entry_t *le = &free_list;
ffffffffc02017de:	87ae                	mv	a5,a1
ffffffffc02017e0:	a801                	j	ffffffffc02017f0 <default_alloc_pages+0x2c>
        if (p->property >= n) {
ffffffffc02017e2:	ff87a683          	lw	a3,-8(a5)
ffffffffc02017e6:	02069613          	slli	a2,a3,0x20
ffffffffc02017ea:	9201                	srli	a2,a2,0x20
ffffffffc02017ec:	00e67763          	bgeu	a2,a4,ffffffffc02017fa <default_alloc_pages+0x36>
    return listelm->next;
ffffffffc02017f0:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc02017f2:	feb798e3          	bne	a5,a1,ffffffffc02017e2 <default_alloc_pages+0x1e>
        return NULL;
ffffffffc02017f6:	4501                	li	a0,0
}
ffffffffc02017f8:	8082                	ret
    return listelm->prev;
ffffffffc02017fa:	0007b883          	ld	a7,0(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc02017fe:	0087b303          	ld	t1,8(a5)
        struct Page *p = le2page(le, page_link);
ffffffffc0201802:	fe878513          	addi	a0,a5,-24
            p->property = page->property - n;
ffffffffc0201806:	00070e1b          	sext.w	t3,a4
    prev->next = next;
ffffffffc020180a:	0068b423          	sd	t1,8(a7)
    next->prev = prev;
ffffffffc020180e:	01133023          	sd	a7,0(t1)
        if (page->property > n) {
ffffffffc0201812:	02c77863          	bgeu	a4,a2,ffffffffc0201842 <default_alloc_pages+0x7e>
            struct Page *p = page + n;
ffffffffc0201816:	071a                	slli	a4,a4,0x6
ffffffffc0201818:	972a                	add	a4,a4,a0
            p->property = page->property - n;
ffffffffc020181a:	41c686bb          	subw	a3,a3,t3
ffffffffc020181e:	cb14                	sw	a3,16(a4)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201820:	00870613          	addi	a2,a4,8
ffffffffc0201824:	4689                	li	a3,2
ffffffffc0201826:	40d6302f          	amoor.d	zero,a3,(a2)
    __list_add(elm, listelm, listelm->next);
ffffffffc020182a:	0088b683          	ld	a3,8(a7)
            list_add(prev, &(p->page_link));
ffffffffc020182e:	01870613          	addi	a2,a4,24
        nr_free -= n;
ffffffffc0201832:	0105a803          	lw	a6,16(a1)
    prev->next = next->prev = elm;
ffffffffc0201836:	e290                	sd	a2,0(a3)
ffffffffc0201838:	00c8b423          	sd	a2,8(a7)
    elm->next = next;
ffffffffc020183c:	f314                	sd	a3,32(a4)
    elm->prev = prev;
ffffffffc020183e:	01173c23          	sd	a7,24(a4)
ffffffffc0201842:	41c8083b          	subw	a6,a6,t3
ffffffffc0201846:	0105a823          	sw	a6,16(a1)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc020184a:	5775                	li	a4,-3
ffffffffc020184c:	17c1                	addi	a5,a5,-16
ffffffffc020184e:	60e7b02f          	amoand.d	zero,a4,(a5)
}
ffffffffc0201852:	8082                	ret
default_alloc_pages(size_t n) {
ffffffffc0201854:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc0201856:	00006697          	auipc	a3,0x6
ffffffffc020185a:	a0a68693          	addi	a3,a3,-1526 # ffffffffc0207260 <commands+0xb70>
ffffffffc020185e:	00005617          	auipc	a2,0x5
ffffffffc0201862:	6aa60613          	addi	a2,a2,1706 # ffffffffc0206f08 <commands+0x818>
ffffffffc0201866:	06100593          	li	a1,97
ffffffffc020186a:	00005517          	auipc	a0,0x5
ffffffffc020186e:	6b650513          	addi	a0,a0,1718 # ffffffffc0206f20 <commands+0x830>
default_alloc_pages(size_t n) {
ffffffffc0201872:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201874:	c1ffe0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0201878 <default_init_memmap>:
default_init_memmap(struct Page *base, size_t n) {
ffffffffc0201878:	1141                	addi	sp,sp,-16
ffffffffc020187a:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc020187c:	c5f1                	beqz	a1,ffffffffc0201948 <default_init_memmap+0xd0>
    for (; p != base + n; p ++) {
ffffffffc020187e:	00659693          	slli	a3,a1,0x6
ffffffffc0201882:	96aa                	add	a3,a3,a0
ffffffffc0201884:	87aa                	mv	a5,a0
ffffffffc0201886:	00d50f63          	beq	a0,a3,ffffffffc02018a4 <default_init_memmap+0x2c>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc020188a:	6798                	ld	a4,8(a5)
ffffffffc020188c:	8b05                	andi	a4,a4,1
        assert(PageReserved(p));
ffffffffc020188e:	cf49                	beqz	a4,ffffffffc0201928 <default_init_memmap+0xb0>
        p->flags = p->property = 0;
ffffffffc0201890:	0007a823          	sw	zero,16(a5)
ffffffffc0201894:	0007b423          	sd	zero,8(a5)
ffffffffc0201898:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc020189c:	04078793          	addi	a5,a5,64
ffffffffc02018a0:	fed795e3          	bne	a5,a3,ffffffffc020188a <default_init_memmap+0x12>
    base->property = n;
ffffffffc02018a4:	2581                	sext.w	a1,a1
ffffffffc02018a6:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02018a8:	4789                	li	a5,2
ffffffffc02018aa:	00850713          	addi	a4,a0,8
ffffffffc02018ae:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc02018b2:	000da697          	auipc	a3,0xda
ffffffffc02018b6:	1be68693          	addi	a3,a3,446 # ffffffffc02dba70 <free_area>
ffffffffc02018ba:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc02018bc:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc02018be:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc02018c2:	9db9                	addw	a1,a1,a4
ffffffffc02018c4:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list)) {
ffffffffc02018c6:	04d78a63          	beq	a5,a3,ffffffffc020191a <default_init_memmap+0xa2>
            struct Page* page = le2page(le, page_link);
ffffffffc02018ca:	fe878713          	addi	a4,a5,-24
ffffffffc02018ce:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list)) {
ffffffffc02018d2:	4581                	li	a1,0
            if (base < page) {
ffffffffc02018d4:	00e56a63          	bltu	a0,a4,ffffffffc02018e8 <default_init_memmap+0x70>
    return listelm->next;
ffffffffc02018d8:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc02018da:	02d70263          	beq	a4,a3,ffffffffc02018fe <default_init_memmap+0x86>
    for (; p != base + n; p ++) {
ffffffffc02018de:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc02018e0:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc02018e4:	fee57ae3          	bgeu	a0,a4,ffffffffc02018d8 <default_init_memmap+0x60>
ffffffffc02018e8:	c199                	beqz	a1,ffffffffc02018ee <default_init_memmap+0x76>
ffffffffc02018ea:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc02018ee:	6398                	ld	a4,0(a5)
}
ffffffffc02018f0:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc02018f2:	e390                	sd	a2,0(a5)
ffffffffc02018f4:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc02018f6:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02018f8:	ed18                	sd	a4,24(a0)
ffffffffc02018fa:	0141                	addi	sp,sp,16
ffffffffc02018fc:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc02018fe:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201900:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0201902:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0201904:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list) {
ffffffffc0201906:	00d70663          	beq	a4,a3,ffffffffc0201912 <default_init_memmap+0x9a>
    prev->next = next->prev = elm;
ffffffffc020190a:	8832                	mv	a6,a2
ffffffffc020190c:	4585                	li	a1,1
    for (; p != base + n; p ++) {
ffffffffc020190e:	87ba                	mv	a5,a4
ffffffffc0201910:	bfc1                	j	ffffffffc02018e0 <default_init_memmap+0x68>
}
ffffffffc0201912:	60a2                	ld	ra,8(sp)
ffffffffc0201914:	e290                	sd	a2,0(a3)
ffffffffc0201916:	0141                	addi	sp,sp,16
ffffffffc0201918:	8082                	ret
ffffffffc020191a:	60a2                	ld	ra,8(sp)
ffffffffc020191c:	e390                	sd	a2,0(a5)
ffffffffc020191e:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201920:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201922:	ed1c                	sd	a5,24(a0)
ffffffffc0201924:	0141                	addi	sp,sp,16
ffffffffc0201926:	8082                	ret
        assert(PageReserved(p));
ffffffffc0201928:	00006697          	auipc	a3,0x6
ffffffffc020192c:	96868693          	addi	a3,a3,-1688 # ffffffffc0207290 <commands+0xba0>
ffffffffc0201930:	00005617          	auipc	a2,0x5
ffffffffc0201934:	5d860613          	addi	a2,a2,1496 # ffffffffc0206f08 <commands+0x818>
ffffffffc0201938:	04800593          	li	a1,72
ffffffffc020193c:	00005517          	auipc	a0,0x5
ffffffffc0201940:	5e450513          	addi	a0,a0,1508 # ffffffffc0206f20 <commands+0x830>
ffffffffc0201944:	b4ffe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(n > 0);
ffffffffc0201948:	00006697          	auipc	a3,0x6
ffffffffc020194c:	91868693          	addi	a3,a3,-1768 # ffffffffc0207260 <commands+0xb70>
ffffffffc0201950:	00005617          	auipc	a2,0x5
ffffffffc0201954:	5b860613          	addi	a2,a2,1464 # ffffffffc0206f08 <commands+0x818>
ffffffffc0201958:	04500593          	li	a1,69
ffffffffc020195c:	00005517          	auipc	a0,0x5
ffffffffc0201960:	5c450513          	addi	a0,a0,1476 # ffffffffc0206f20 <commands+0x830>
ffffffffc0201964:	b2ffe0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0201968 <slob_free>:
static void slob_free(void *block, int size)
{
	slob_t *cur, *b = (slob_t *)block;
	unsigned long flags;

	if (!block)
ffffffffc0201968:	c94d                	beqz	a0,ffffffffc0201a1a <slob_free+0xb2>
{
ffffffffc020196a:	1141                	addi	sp,sp,-16
ffffffffc020196c:	e022                	sd	s0,0(sp)
ffffffffc020196e:	e406                	sd	ra,8(sp)
ffffffffc0201970:	842a                	mv	s0,a0
		return;

	if (size)
ffffffffc0201972:	e9c1                	bnez	a1,ffffffffc0201a02 <slob_free+0x9a>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201974:	100027f3          	csrr	a5,sstatus
ffffffffc0201978:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc020197a:	4501                	li	a0,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020197c:	ebd9                	bnez	a5,ffffffffc0201a12 <slob_free+0xaa>
		b->units = SLOB_UNITS(size);

	/* Find reinsertion point */
	spin_lock_irqsave(&slob_lock, flags);
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc020197e:	000da617          	auipc	a2,0xda
ffffffffc0201982:	cda60613          	addi	a2,a2,-806 # ffffffffc02db658 <slobfree>
ffffffffc0201986:	621c                	ld	a5,0(a2)
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201988:	873e                	mv	a4,a5
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc020198a:	679c                	ld	a5,8(a5)
ffffffffc020198c:	02877a63          	bgeu	a4,s0,ffffffffc02019c0 <slob_free+0x58>
ffffffffc0201990:	00f46463          	bltu	s0,a5,ffffffffc0201998 <slob_free+0x30>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201994:	fef76ae3          	bltu	a4,a5,ffffffffc0201988 <slob_free+0x20>
			break;

	if (b + b->units == cur->next)
ffffffffc0201998:	400c                	lw	a1,0(s0)
ffffffffc020199a:	00459693          	slli	a3,a1,0x4
ffffffffc020199e:	96a2                	add	a3,a3,s0
ffffffffc02019a0:	02d78a63          	beq	a5,a3,ffffffffc02019d4 <slob_free+0x6c>
		b->next = cur->next->next;
	}
	else
		b->next = cur->next;

	if (cur + cur->units == b)
ffffffffc02019a4:	4314                	lw	a3,0(a4)
		b->next = cur->next;
ffffffffc02019a6:	e41c                	sd	a5,8(s0)
	if (cur + cur->units == b)
ffffffffc02019a8:	00469793          	slli	a5,a3,0x4
ffffffffc02019ac:	97ba                	add	a5,a5,a4
ffffffffc02019ae:	02f40e63          	beq	s0,a5,ffffffffc02019ea <slob_free+0x82>
	{
		cur->units += b->units;
		cur->next = b->next;
	}
	else
		cur->next = b;
ffffffffc02019b2:	e700                	sd	s0,8(a4)

	slobfree = cur;
ffffffffc02019b4:	e218                	sd	a4,0(a2)
    if (flag) {
ffffffffc02019b6:	e129                	bnez	a0,ffffffffc02019f8 <slob_free+0x90>

	spin_unlock_irqrestore(&slob_lock, flags);
}
ffffffffc02019b8:	60a2                	ld	ra,8(sp)
ffffffffc02019ba:	6402                	ld	s0,0(sp)
ffffffffc02019bc:	0141                	addi	sp,sp,16
ffffffffc02019be:	8082                	ret
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc02019c0:	fcf764e3          	bltu	a4,a5,ffffffffc0201988 <slob_free+0x20>
ffffffffc02019c4:	fcf472e3          	bgeu	s0,a5,ffffffffc0201988 <slob_free+0x20>
	if (b + b->units == cur->next)
ffffffffc02019c8:	400c                	lw	a1,0(s0)
ffffffffc02019ca:	00459693          	slli	a3,a1,0x4
ffffffffc02019ce:	96a2                	add	a3,a3,s0
ffffffffc02019d0:	fcd79ae3          	bne	a5,a3,ffffffffc02019a4 <slob_free+0x3c>
		b->units += cur->next->units;
ffffffffc02019d4:	4394                	lw	a3,0(a5)
		b->next = cur->next->next;
ffffffffc02019d6:	679c                	ld	a5,8(a5)
		b->units += cur->next->units;
ffffffffc02019d8:	9db5                	addw	a1,a1,a3
ffffffffc02019da:	c00c                	sw	a1,0(s0)
	if (cur + cur->units == b)
ffffffffc02019dc:	4314                	lw	a3,0(a4)
		b->next = cur->next->next;
ffffffffc02019de:	e41c                	sd	a5,8(s0)
	if (cur + cur->units == b)
ffffffffc02019e0:	00469793          	slli	a5,a3,0x4
ffffffffc02019e4:	97ba                	add	a5,a5,a4
ffffffffc02019e6:	fcf416e3          	bne	s0,a5,ffffffffc02019b2 <slob_free+0x4a>
		cur->units += b->units;
ffffffffc02019ea:	401c                	lw	a5,0(s0)
		cur->next = b->next;
ffffffffc02019ec:	640c                	ld	a1,8(s0)
	slobfree = cur;
ffffffffc02019ee:	e218                	sd	a4,0(a2)
		cur->units += b->units;
ffffffffc02019f0:	9ebd                	addw	a3,a3,a5
ffffffffc02019f2:	c314                	sw	a3,0(a4)
		cur->next = b->next;
ffffffffc02019f4:	e70c                	sd	a1,8(a4)
ffffffffc02019f6:	d169                	beqz	a0,ffffffffc02019b8 <slob_free+0x50>
}
ffffffffc02019f8:	6402                	ld	s0,0(sp)
ffffffffc02019fa:	60a2                	ld	ra,8(sp)
ffffffffc02019fc:	0141                	addi	sp,sp,16
        intr_enable();
ffffffffc02019fe:	fabfe06f          	j	ffffffffc02009a8 <intr_enable>
		b->units = SLOB_UNITS(size);
ffffffffc0201a02:	25bd                	addiw	a1,a1,15
ffffffffc0201a04:	8191                	srli	a1,a1,0x4
ffffffffc0201a06:	c10c                	sw	a1,0(a0)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201a08:	100027f3          	csrr	a5,sstatus
ffffffffc0201a0c:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0201a0e:	4501                	li	a0,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201a10:	d7bd                	beqz	a5,ffffffffc020197e <slob_free+0x16>
        intr_disable();
ffffffffc0201a12:	f9dfe0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        return 1;
ffffffffc0201a16:	4505                	li	a0,1
ffffffffc0201a18:	b79d                	j	ffffffffc020197e <slob_free+0x16>
ffffffffc0201a1a:	8082                	ret

ffffffffc0201a1c <__slob_get_free_pages.constprop.0>:
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201a1c:	4785                	li	a5,1
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0201a1e:	1141                	addi	sp,sp,-16
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201a20:	00a7953b          	sllw	a0,a5,a0
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0201a24:	e406                	sd	ra,8(sp)
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201a26:	352000ef          	jal	ra,ffffffffc0201d78 <alloc_pages>
	if (!page)
ffffffffc0201a2a:	c91d                	beqz	a0,ffffffffc0201a60 <__slob_get_free_pages.constprop.0+0x44>
    return page - pages + nbase;
ffffffffc0201a2c:	000de697          	auipc	a3,0xde
ffffffffc0201a30:	22c6b683          	ld	a3,556(a3) # ffffffffc02dfc58 <pages>
ffffffffc0201a34:	8d15                	sub	a0,a0,a3
ffffffffc0201a36:	8519                	srai	a0,a0,0x6
ffffffffc0201a38:	00008697          	auipc	a3,0x8
ffffffffc0201a3c:	8386b683          	ld	a3,-1992(a3) # ffffffffc0209270 <nbase>
ffffffffc0201a40:	9536                	add	a0,a0,a3
    return KADDR(page2pa(page));
ffffffffc0201a42:	00c51793          	slli	a5,a0,0xc
ffffffffc0201a46:	83b1                	srli	a5,a5,0xc
ffffffffc0201a48:	000de717          	auipc	a4,0xde
ffffffffc0201a4c:	20873703          	ld	a4,520(a4) # ffffffffc02dfc50 <npage>
    return page2ppn(page) << PGSHIFT;
ffffffffc0201a50:	0532                	slli	a0,a0,0xc
    return KADDR(page2pa(page));
ffffffffc0201a52:	00e7fa63          	bgeu	a5,a4,ffffffffc0201a66 <__slob_get_free_pages.constprop.0+0x4a>
ffffffffc0201a56:	000de697          	auipc	a3,0xde
ffffffffc0201a5a:	2126b683          	ld	a3,530(a3) # ffffffffc02dfc68 <va_pa_offset>
ffffffffc0201a5e:	9536                	add	a0,a0,a3
}
ffffffffc0201a60:	60a2                	ld	ra,8(sp)
ffffffffc0201a62:	0141                	addi	sp,sp,16
ffffffffc0201a64:	8082                	ret
ffffffffc0201a66:	86aa                	mv	a3,a0
ffffffffc0201a68:	00006617          	auipc	a2,0x6
ffffffffc0201a6c:	88860613          	addi	a2,a2,-1912 # ffffffffc02072f0 <default_pmm_manager+0x38>
ffffffffc0201a70:	07100593          	li	a1,113
ffffffffc0201a74:	00006517          	auipc	a0,0x6
ffffffffc0201a78:	8a450513          	addi	a0,a0,-1884 # ffffffffc0207318 <default_pmm_manager+0x60>
ffffffffc0201a7c:	a17fe0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0201a80 <slob_alloc.constprop.0>:
static void *slob_alloc(size_t size, gfp_t gfp, int align)
ffffffffc0201a80:	1101                	addi	sp,sp,-32
ffffffffc0201a82:	ec06                	sd	ra,24(sp)
ffffffffc0201a84:	e822                	sd	s0,16(sp)
ffffffffc0201a86:	e426                	sd	s1,8(sp)
ffffffffc0201a88:	e04a                	sd	s2,0(sp)
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc0201a8a:	01050713          	addi	a4,a0,16
ffffffffc0201a8e:	6785                	lui	a5,0x1
ffffffffc0201a90:	0cf77363          	bgeu	a4,a5,ffffffffc0201b56 <slob_alloc.constprop.0+0xd6>
	int delta = 0, units = SLOB_UNITS(size);
ffffffffc0201a94:	00f50493          	addi	s1,a0,15
ffffffffc0201a98:	8091                	srli	s1,s1,0x4
ffffffffc0201a9a:	2481                	sext.w	s1,s1
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201a9c:	10002673          	csrr	a2,sstatus
ffffffffc0201aa0:	8a09                	andi	a2,a2,2
ffffffffc0201aa2:	e25d                	bnez	a2,ffffffffc0201b48 <slob_alloc.constprop.0+0xc8>
	prev = slobfree;
ffffffffc0201aa4:	000da917          	auipc	s2,0xda
ffffffffc0201aa8:	bb490913          	addi	s2,s2,-1100 # ffffffffc02db658 <slobfree>
ffffffffc0201aac:	00093683          	ld	a3,0(s2)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201ab0:	669c                	ld	a5,8(a3)
		if (cur->units >= units + delta)
ffffffffc0201ab2:	4398                	lw	a4,0(a5)
ffffffffc0201ab4:	08975e63          	bge	a4,s1,ffffffffc0201b50 <slob_alloc.constprop.0+0xd0>
		if (cur == slobfree)
ffffffffc0201ab8:	00f68b63          	beq	a3,a5,ffffffffc0201ace <slob_alloc.constprop.0+0x4e>
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201abc:	6780                	ld	s0,8(a5)
		if (cur->units >= units + delta)
ffffffffc0201abe:	4018                	lw	a4,0(s0)
ffffffffc0201ac0:	02975a63          	bge	a4,s1,ffffffffc0201af4 <slob_alloc.constprop.0+0x74>
		if (cur == slobfree)
ffffffffc0201ac4:	00093683          	ld	a3,0(s2)
ffffffffc0201ac8:	87a2                	mv	a5,s0
ffffffffc0201aca:	fef699e3          	bne	a3,a5,ffffffffc0201abc <slob_alloc.constprop.0+0x3c>
    if (flag) {
ffffffffc0201ace:	ee31                	bnez	a2,ffffffffc0201b2a <slob_alloc.constprop.0+0xaa>
			cur = (slob_t *)__slob_get_free_page(gfp);
ffffffffc0201ad0:	4501                	li	a0,0
ffffffffc0201ad2:	f4bff0ef          	jal	ra,ffffffffc0201a1c <__slob_get_free_pages.constprop.0>
ffffffffc0201ad6:	842a                	mv	s0,a0
			if (!cur)
ffffffffc0201ad8:	cd05                	beqz	a0,ffffffffc0201b10 <slob_alloc.constprop.0+0x90>
			slob_free(cur, PAGE_SIZE);
ffffffffc0201ada:	6585                	lui	a1,0x1
ffffffffc0201adc:	e8dff0ef          	jal	ra,ffffffffc0201968 <slob_free>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201ae0:	10002673          	csrr	a2,sstatus
ffffffffc0201ae4:	8a09                	andi	a2,a2,2
ffffffffc0201ae6:	ee05                	bnez	a2,ffffffffc0201b1e <slob_alloc.constprop.0+0x9e>
			cur = slobfree;
ffffffffc0201ae8:	00093783          	ld	a5,0(s2)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201aec:	6780                	ld	s0,8(a5)
		if (cur->units >= units + delta)
ffffffffc0201aee:	4018                	lw	a4,0(s0)
ffffffffc0201af0:	fc974ae3          	blt	a4,s1,ffffffffc0201ac4 <slob_alloc.constprop.0+0x44>
			if (cur->units == units)	/* exact fit? */
ffffffffc0201af4:	04e48763          	beq	s1,a4,ffffffffc0201b42 <slob_alloc.constprop.0+0xc2>
				prev->next = cur + units;
ffffffffc0201af8:	00449693          	slli	a3,s1,0x4
ffffffffc0201afc:	96a2                	add	a3,a3,s0
ffffffffc0201afe:	e794                	sd	a3,8(a5)
				prev->next->next = cur->next;
ffffffffc0201b00:	640c                	ld	a1,8(s0)
				prev->next->units = cur->units - units;
ffffffffc0201b02:	9f05                	subw	a4,a4,s1
ffffffffc0201b04:	c298                	sw	a4,0(a3)
				prev->next->next = cur->next;
ffffffffc0201b06:	e68c                	sd	a1,8(a3)
				cur->units = units;
ffffffffc0201b08:	c004                	sw	s1,0(s0)
			slobfree = prev;
ffffffffc0201b0a:	00f93023          	sd	a5,0(s2)
    if (flag) {
ffffffffc0201b0e:	e20d                	bnez	a2,ffffffffc0201b30 <slob_alloc.constprop.0+0xb0>
}
ffffffffc0201b10:	60e2                	ld	ra,24(sp)
ffffffffc0201b12:	8522                	mv	a0,s0
ffffffffc0201b14:	6442                	ld	s0,16(sp)
ffffffffc0201b16:	64a2                	ld	s1,8(sp)
ffffffffc0201b18:	6902                	ld	s2,0(sp)
ffffffffc0201b1a:	6105                	addi	sp,sp,32
ffffffffc0201b1c:	8082                	ret
        intr_disable();
ffffffffc0201b1e:	e91fe0ef          	jal	ra,ffffffffc02009ae <intr_disable>
			cur = slobfree;
ffffffffc0201b22:	00093783          	ld	a5,0(s2)
        return 1;
ffffffffc0201b26:	4605                	li	a2,1
ffffffffc0201b28:	b7d1                	j	ffffffffc0201aec <slob_alloc.constprop.0+0x6c>
        intr_enable();
ffffffffc0201b2a:	e7ffe0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0201b2e:	b74d                	j	ffffffffc0201ad0 <slob_alloc.constprop.0+0x50>
ffffffffc0201b30:	e79fe0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
}
ffffffffc0201b34:	60e2                	ld	ra,24(sp)
ffffffffc0201b36:	8522                	mv	a0,s0
ffffffffc0201b38:	6442                	ld	s0,16(sp)
ffffffffc0201b3a:	64a2                	ld	s1,8(sp)
ffffffffc0201b3c:	6902                	ld	s2,0(sp)
ffffffffc0201b3e:	6105                	addi	sp,sp,32
ffffffffc0201b40:	8082                	ret
				prev->next = cur->next; /* unlink */
ffffffffc0201b42:	6418                	ld	a4,8(s0)
ffffffffc0201b44:	e798                	sd	a4,8(a5)
ffffffffc0201b46:	b7d1                	j	ffffffffc0201b0a <slob_alloc.constprop.0+0x8a>
        intr_disable();
ffffffffc0201b48:	e67fe0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        return 1;
ffffffffc0201b4c:	4605                	li	a2,1
ffffffffc0201b4e:	bf99                	j	ffffffffc0201aa4 <slob_alloc.constprop.0+0x24>
		if (cur->units >= units + delta)
ffffffffc0201b50:	843e                	mv	s0,a5
ffffffffc0201b52:	87b6                	mv	a5,a3
ffffffffc0201b54:	b745                	j	ffffffffc0201af4 <slob_alloc.constprop.0+0x74>
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc0201b56:	00005697          	auipc	a3,0x5
ffffffffc0201b5a:	7d268693          	addi	a3,a3,2002 # ffffffffc0207328 <default_pmm_manager+0x70>
ffffffffc0201b5e:	00005617          	auipc	a2,0x5
ffffffffc0201b62:	3aa60613          	addi	a2,a2,938 # ffffffffc0206f08 <commands+0x818>
ffffffffc0201b66:	06300593          	li	a1,99
ffffffffc0201b6a:	00005517          	auipc	a0,0x5
ffffffffc0201b6e:	7de50513          	addi	a0,a0,2014 # ffffffffc0207348 <default_pmm_manager+0x90>
ffffffffc0201b72:	921fe0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0201b76 <kmalloc_init>:
	cprintf("use SLOB allocator\n");
}

inline void
kmalloc_init(void)
{
ffffffffc0201b76:	1141                	addi	sp,sp,-16
	cprintf("use SLOB allocator\n");
ffffffffc0201b78:	00005517          	auipc	a0,0x5
ffffffffc0201b7c:	7e850513          	addi	a0,a0,2024 # ffffffffc0207360 <default_pmm_manager+0xa8>
{
ffffffffc0201b80:	e406                	sd	ra,8(sp)
	cprintf("use SLOB allocator\n");
ffffffffc0201b82:	e16fe0ef          	jal	ra,ffffffffc0200198 <cprintf>
	slob_init();
	cprintf("kmalloc_init() succeeded!\n");
}
ffffffffc0201b86:	60a2                	ld	ra,8(sp)
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201b88:	00005517          	auipc	a0,0x5
ffffffffc0201b8c:	7f050513          	addi	a0,a0,2032 # ffffffffc0207378 <default_pmm_manager+0xc0>
}
ffffffffc0201b90:	0141                	addi	sp,sp,16
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201b92:	e06fe06f          	j	ffffffffc0200198 <cprintf>

ffffffffc0201b96 <kallocated>:

size_t
kallocated(void)
{
	return slob_allocated();
}
ffffffffc0201b96:	4501                	li	a0,0
ffffffffc0201b98:	8082                	ret

ffffffffc0201b9a <kmalloc>:
	return 0;
}

void *
kmalloc(size_t size)
{
ffffffffc0201b9a:	1101                	addi	sp,sp,-32
ffffffffc0201b9c:	e04a                	sd	s2,0(sp)
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201b9e:	6905                	lui	s2,0x1
{
ffffffffc0201ba0:	e822                	sd	s0,16(sp)
ffffffffc0201ba2:	ec06                	sd	ra,24(sp)
ffffffffc0201ba4:	e426                	sd	s1,8(sp)
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201ba6:	fef90793          	addi	a5,s2,-17 # fef <_binary_obj___user_faultread_out_size-0x9139>
{
ffffffffc0201baa:	842a                	mv	s0,a0
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201bac:	04a7f963          	bgeu	a5,a0,ffffffffc0201bfe <kmalloc+0x64>
	bb = slob_alloc(sizeof(bigblock_t), gfp, 0);
ffffffffc0201bb0:	4561                	li	a0,24
ffffffffc0201bb2:	ecfff0ef          	jal	ra,ffffffffc0201a80 <slob_alloc.constprop.0>
ffffffffc0201bb6:	84aa                	mv	s1,a0
	if (!bb)
ffffffffc0201bb8:	c929                	beqz	a0,ffffffffc0201c0a <kmalloc+0x70>
	bb->order = find_order(size);
ffffffffc0201bba:	0004079b          	sext.w	a5,s0
	int order = 0;
ffffffffc0201bbe:	4501                	li	a0,0
	for (; size > 4096; size >>= 1)
ffffffffc0201bc0:	00f95763          	bge	s2,a5,ffffffffc0201bce <kmalloc+0x34>
ffffffffc0201bc4:	6705                	lui	a4,0x1
ffffffffc0201bc6:	8785                	srai	a5,a5,0x1
		order++;
ffffffffc0201bc8:	2505                	addiw	a0,a0,1
	for (; size > 4096; size >>= 1)
ffffffffc0201bca:	fef74ee3          	blt	a4,a5,ffffffffc0201bc6 <kmalloc+0x2c>
	bb->order = find_order(size);
ffffffffc0201bce:	c088                	sw	a0,0(s1)
	bb->pages = (void *)__slob_get_free_pages(gfp, bb->order);
ffffffffc0201bd0:	e4dff0ef          	jal	ra,ffffffffc0201a1c <__slob_get_free_pages.constprop.0>
ffffffffc0201bd4:	e488                	sd	a0,8(s1)
ffffffffc0201bd6:	842a                	mv	s0,a0
	if (bb->pages)
ffffffffc0201bd8:	c525                	beqz	a0,ffffffffc0201c40 <kmalloc+0xa6>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201bda:	100027f3          	csrr	a5,sstatus
ffffffffc0201bde:	8b89                	andi	a5,a5,2
ffffffffc0201be0:	ef8d                	bnez	a5,ffffffffc0201c1a <kmalloc+0x80>
		bb->next = bigblocks;
ffffffffc0201be2:	000de797          	auipc	a5,0xde
ffffffffc0201be6:	05678793          	addi	a5,a5,86 # ffffffffc02dfc38 <bigblocks>
ffffffffc0201bea:	6398                	ld	a4,0(a5)
		bigblocks = bb;
ffffffffc0201bec:	e384                	sd	s1,0(a5)
		bb->next = bigblocks;
ffffffffc0201bee:	e898                	sd	a4,16(s1)
	return __kmalloc(size, 0);
}
ffffffffc0201bf0:	60e2                	ld	ra,24(sp)
ffffffffc0201bf2:	8522                	mv	a0,s0
ffffffffc0201bf4:	6442                	ld	s0,16(sp)
ffffffffc0201bf6:	64a2                	ld	s1,8(sp)
ffffffffc0201bf8:	6902                	ld	s2,0(sp)
ffffffffc0201bfa:	6105                	addi	sp,sp,32
ffffffffc0201bfc:	8082                	ret
		m = slob_alloc(size + SLOB_UNIT, gfp, 0);
ffffffffc0201bfe:	0541                	addi	a0,a0,16
ffffffffc0201c00:	e81ff0ef          	jal	ra,ffffffffc0201a80 <slob_alloc.constprop.0>
		return m ? (void *)(m + 1) : 0;
ffffffffc0201c04:	01050413          	addi	s0,a0,16
ffffffffc0201c08:	f565                	bnez	a0,ffffffffc0201bf0 <kmalloc+0x56>
ffffffffc0201c0a:	4401                	li	s0,0
}
ffffffffc0201c0c:	60e2                	ld	ra,24(sp)
ffffffffc0201c0e:	8522                	mv	a0,s0
ffffffffc0201c10:	6442                	ld	s0,16(sp)
ffffffffc0201c12:	64a2                	ld	s1,8(sp)
ffffffffc0201c14:	6902                	ld	s2,0(sp)
ffffffffc0201c16:	6105                	addi	sp,sp,32
ffffffffc0201c18:	8082                	ret
        intr_disable();
ffffffffc0201c1a:	d95fe0ef          	jal	ra,ffffffffc02009ae <intr_disable>
		bb->next = bigblocks;
ffffffffc0201c1e:	000de797          	auipc	a5,0xde
ffffffffc0201c22:	01a78793          	addi	a5,a5,26 # ffffffffc02dfc38 <bigblocks>
ffffffffc0201c26:	6398                	ld	a4,0(a5)
		bigblocks = bb;
ffffffffc0201c28:	e384                	sd	s1,0(a5)
		bb->next = bigblocks;
ffffffffc0201c2a:	e898                	sd	a4,16(s1)
        intr_enable();
ffffffffc0201c2c:	d7dfe0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
		return bb->pages;
ffffffffc0201c30:	6480                	ld	s0,8(s1)
}
ffffffffc0201c32:	60e2                	ld	ra,24(sp)
ffffffffc0201c34:	64a2                	ld	s1,8(sp)
ffffffffc0201c36:	8522                	mv	a0,s0
ffffffffc0201c38:	6442                	ld	s0,16(sp)
ffffffffc0201c3a:	6902                	ld	s2,0(sp)
ffffffffc0201c3c:	6105                	addi	sp,sp,32
ffffffffc0201c3e:	8082                	ret
	slob_free(bb, sizeof(bigblock_t));
ffffffffc0201c40:	45e1                	li	a1,24
ffffffffc0201c42:	8526                	mv	a0,s1
ffffffffc0201c44:	d25ff0ef          	jal	ra,ffffffffc0201968 <slob_free>
	return __kmalloc(size, 0);
ffffffffc0201c48:	b765                	j	ffffffffc0201bf0 <kmalloc+0x56>

ffffffffc0201c4a <kfree>:
void kfree(void *block)
{
	bigblock_t *bb, **last = &bigblocks;
	unsigned long flags;

	if (!block)
ffffffffc0201c4a:	c169                	beqz	a0,ffffffffc0201d0c <kfree+0xc2>
{
ffffffffc0201c4c:	1101                	addi	sp,sp,-32
ffffffffc0201c4e:	e822                	sd	s0,16(sp)
ffffffffc0201c50:	ec06                	sd	ra,24(sp)
ffffffffc0201c52:	e426                	sd	s1,8(sp)
		return;

	if (!((unsigned long)block & (PAGE_SIZE - 1)))
ffffffffc0201c54:	03451793          	slli	a5,a0,0x34
ffffffffc0201c58:	842a                	mv	s0,a0
ffffffffc0201c5a:	e3d9                	bnez	a5,ffffffffc0201ce0 <kfree+0x96>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201c5c:	100027f3          	csrr	a5,sstatus
ffffffffc0201c60:	8b89                	andi	a5,a5,2
ffffffffc0201c62:	e7d9                	bnez	a5,ffffffffc0201cf0 <kfree+0xa6>
	{
		/* might be on the big block list */
		spin_lock_irqsave(&block_lock, flags);
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201c64:	000de797          	auipc	a5,0xde
ffffffffc0201c68:	fd47b783          	ld	a5,-44(a5) # ffffffffc02dfc38 <bigblocks>
    return 0;
ffffffffc0201c6c:	4601                	li	a2,0
ffffffffc0201c6e:	cbad                	beqz	a5,ffffffffc0201ce0 <kfree+0x96>
	bigblock_t *bb, **last = &bigblocks;
ffffffffc0201c70:	000de697          	auipc	a3,0xde
ffffffffc0201c74:	fc868693          	addi	a3,a3,-56 # ffffffffc02dfc38 <bigblocks>
ffffffffc0201c78:	a021                	j	ffffffffc0201c80 <kfree+0x36>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201c7a:	01048693          	addi	a3,s1,16
ffffffffc0201c7e:	c3a5                	beqz	a5,ffffffffc0201cde <kfree+0x94>
		{
			if (bb->pages == block)
ffffffffc0201c80:	6798                	ld	a4,8(a5)
ffffffffc0201c82:	84be                	mv	s1,a5
			{
				*last = bb->next;
ffffffffc0201c84:	6b9c                	ld	a5,16(a5)
			if (bb->pages == block)
ffffffffc0201c86:	fe871ae3          	bne	a4,s0,ffffffffc0201c7a <kfree+0x30>
				*last = bb->next;
ffffffffc0201c8a:	e29c                	sd	a5,0(a3)
    if (flag) {
ffffffffc0201c8c:	ee2d                	bnez	a2,ffffffffc0201d06 <kfree+0xbc>
    return pa2page(PADDR(kva));
ffffffffc0201c8e:	c02007b7          	lui	a5,0xc0200
				spin_unlock_irqrestore(&block_lock, flags);
				__slob_free_pages((unsigned long)block, bb->order);
ffffffffc0201c92:	4098                	lw	a4,0(s1)
ffffffffc0201c94:	08f46963          	bltu	s0,a5,ffffffffc0201d26 <kfree+0xdc>
ffffffffc0201c98:	000de697          	auipc	a3,0xde
ffffffffc0201c9c:	fd06b683          	ld	a3,-48(a3) # ffffffffc02dfc68 <va_pa_offset>
ffffffffc0201ca0:	8c15                	sub	s0,s0,a3
    if (PPN(pa) >= npage)
ffffffffc0201ca2:	8031                	srli	s0,s0,0xc
ffffffffc0201ca4:	000de797          	auipc	a5,0xde
ffffffffc0201ca8:	fac7b783          	ld	a5,-84(a5) # ffffffffc02dfc50 <npage>
ffffffffc0201cac:	06f47163          	bgeu	s0,a5,ffffffffc0201d0e <kfree+0xc4>
    return &pages[PPN(pa) - nbase];
ffffffffc0201cb0:	00007517          	auipc	a0,0x7
ffffffffc0201cb4:	5c053503          	ld	a0,1472(a0) # ffffffffc0209270 <nbase>
ffffffffc0201cb8:	8c09                	sub	s0,s0,a0
ffffffffc0201cba:	041a                	slli	s0,s0,0x6
	free_pages(kva2page(kva), 1 << order);
ffffffffc0201cbc:	000de517          	auipc	a0,0xde
ffffffffc0201cc0:	f9c53503          	ld	a0,-100(a0) # ffffffffc02dfc58 <pages>
ffffffffc0201cc4:	4585                	li	a1,1
ffffffffc0201cc6:	9522                	add	a0,a0,s0
ffffffffc0201cc8:	00e595bb          	sllw	a1,a1,a4
ffffffffc0201ccc:	0ea000ef          	jal	ra,ffffffffc0201db6 <free_pages>
		spin_unlock_irqrestore(&block_lock, flags);
	}

	slob_free((slob_t *)block - 1, 0);
	return;
}
ffffffffc0201cd0:	6442                	ld	s0,16(sp)
ffffffffc0201cd2:	60e2                	ld	ra,24(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201cd4:	8526                	mv	a0,s1
}
ffffffffc0201cd6:	64a2                	ld	s1,8(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201cd8:	45e1                	li	a1,24
}
ffffffffc0201cda:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201cdc:	b171                	j	ffffffffc0201968 <slob_free>
ffffffffc0201cde:	e20d                	bnez	a2,ffffffffc0201d00 <kfree+0xb6>
ffffffffc0201ce0:	ff040513          	addi	a0,s0,-16
}
ffffffffc0201ce4:	6442                	ld	s0,16(sp)
ffffffffc0201ce6:	60e2                	ld	ra,24(sp)
ffffffffc0201ce8:	64a2                	ld	s1,8(sp)
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201cea:	4581                	li	a1,0
}
ffffffffc0201cec:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201cee:	b9ad                	j	ffffffffc0201968 <slob_free>
        intr_disable();
ffffffffc0201cf0:	cbffe0ef          	jal	ra,ffffffffc02009ae <intr_disable>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201cf4:	000de797          	auipc	a5,0xde
ffffffffc0201cf8:	f447b783          	ld	a5,-188(a5) # ffffffffc02dfc38 <bigblocks>
        return 1;
ffffffffc0201cfc:	4605                	li	a2,1
ffffffffc0201cfe:	fbad                	bnez	a5,ffffffffc0201c70 <kfree+0x26>
        intr_enable();
ffffffffc0201d00:	ca9fe0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0201d04:	bff1                	j	ffffffffc0201ce0 <kfree+0x96>
ffffffffc0201d06:	ca3fe0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0201d0a:	b751                	j	ffffffffc0201c8e <kfree+0x44>
ffffffffc0201d0c:	8082                	ret
        panic("pa2page called with invalid pa");
ffffffffc0201d0e:	00005617          	auipc	a2,0x5
ffffffffc0201d12:	6b260613          	addi	a2,a2,1714 # ffffffffc02073c0 <default_pmm_manager+0x108>
ffffffffc0201d16:	06900593          	li	a1,105
ffffffffc0201d1a:	00005517          	auipc	a0,0x5
ffffffffc0201d1e:	5fe50513          	addi	a0,a0,1534 # ffffffffc0207318 <default_pmm_manager+0x60>
ffffffffc0201d22:	f70fe0ef          	jal	ra,ffffffffc0200492 <__panic>
    return pa2page(PADDR(kva));
ffffffffc0201d26:	86a2                	mv	a3,s0
ffffffffc0201d28:	00005617          	auipc	a2,0x5
ffffffffc0201d2c:	67060613          	addi	a2,a2,1648 # ffffffffc0207398 <default_pmm_manager+0xe0>
ffffffffc0201d30:	07700593          	li	a1,119
ffffffffc0201d34:	00005517          	auipc	a0,0x5
ffffffffc0201d38:	5e450513          	addi	a0,a0,1508 # ffffffffc0207318 <default_pmm_manager+0x60>
ffffffffc0201d3c:	f56fe0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0201d40 <pa2page.part.0>:
pa2page(uintptr_t pa)
ffffffffc0201d40:	1141                	addi	sp,sp,-16
        panic("pa2page called with invalid pa");
ffffffffc0201d42:	00005617          	auipc	a2,0x5
ffffffffc0201d46:	67e60613          	addi	a2,a2,1662 # ffffffffc02073c0 <default_pmm_manager+0x108>
ffffffffc0201d4a:	06900593          	li	a1,105
ffffffffc0201d4e:	00005517          	auipc	a0,0x5
ffffffffc0201d52:	5ca50513          	addi	a0,a0,1482 # ffffffffc0207318 <default_pmm_manager+0x60>
pa2page(uintptr_t pa)
ffffffffc0201d56:	e406                	sd	ra,8(sp)
        panic("pa2page called with invalid pa");
ffffffffc0201d58:	f3afe0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0201d5c <pte2page.part.0>:
pte2page(pte_t pte)
ffffffffc0201d5c:	1141                	addi	sp,sp,-16
        panic("pte2page called with invalid pte");
ffffffffc0201d5e:	00005617          	auipc	a2,0x5
ffffffffc0201d62:	68260613          	addi	a2,a2,1666 # ffffffffc02073e0 <default_pmm_manager+0x128>
ffffffffc0201d66:	07f00593          	li	a1,127
ffffffffc0201d6a:	00005517          	auipc	a0,0x5
ffffffffc0201d6e:	5ae50513          	addi	a0,a0,1454 # ffffffffc0207318 <default_pmm_manager+0x60>
pte2page(pte_t pte)
ffffffffc0201d72:	e406                	sd	ra,8(sp)
        panic("pte2page called with invalid pte");
ffffffffc0201d74:	f1efe0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0201d78 <alloc_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201d78:	100027f3          	csrr	a5,sstatus
ffffffffc0201d7c:	8b89                	andi	a5,a5,2
ffffffffc0201d7e:	e799                	bnez	a5,ffffffffc0201d8c <alloc_pages+0x14>
{
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc0201d80:	000de797          	auipc	a5,0xde
ffffffffc0201d84:	ee07b783          	ld	a5,-288(a5) # ffffffffc02dfc60 <pmm_manager>
ffffffffc0201d88:	6f9c                	ld	a5,24(a5)
ffffffffc0201d8a:	8782                	jr	a5
{
ffffffffc0201d8c:	1141                	addi	sp,sp,-16
ffffffffc0201d8e:	e406                	sd	ra,8(sp)
ffffffffc0201d90:	e022                	sd	s0,0(sp)
ffffffffc0201d92:	842a                	mv	s0,a0
        intr_disable();
ffffffffc0201d94:	c1bfe0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201d98:	000de797          	auipc	a5,0xde
ffffffffc0201d9c:	ec87b783          	ld	a5,-312(a5) # ffffffffc02dfc60 <pmm_manager>
ffffffffc0201da0:	6f9c                	ld	a5,24(a5)
ffffffffc0201da2:	8522                	mv	a0,s0
ffffffffc0201da4:	9782                	jalr	a5
ffffffffc0201da6:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201da8:	c01fe0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc0201dac:	60a2                	ld	ra,8(sp)
ffffffffc0201dae:	8522                	mv	a0,s0
ffffffffc0201db0:	6402                	ld	s0,0(sp)
ffffffffc0201db2:	0141                	addi	sp,sp,16
ffffffffc0201db4:	8082                	ret

ffffffffc0201db6 <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201db6:	100027f3          	csrr	a5,sstatus
ffffffffc0201dba:	8b89                	andi	a5,a5,2
ffffffffc0201dbc:	e799                	bnez	a5,ffffffffc0201dca <free_pages+0x14>
void free_pages(struct Page *base, size_t n)
{
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc0201dbe:	000de797          	auipc	a5,0xde
ffffffffc0201dc2:	ea27b783          	ld	a5,-350(a5) # ffffffffc02dfc60 <pmm_manager>
ffffffffc0201dc6:	739c                	ld	a5,32(a5)
ffffffffc0201dc8:	8782                	jr	a5
{
ffffffffc0201dca:	1101                	addi	sp,sp,-32
ffffffffc0201dcc:	ec06                	sd	ra,24(sp)
ffffffffc0201dce:	e822                	sd	s0,16(sp)
ffffffffc0201dd0:	e426                	sd	s1,8(sp)
ffffffffc0201dd2:	842a                	mv	s0,a0
ffffffffc0201dd4:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc0201dd6:	bd9fe0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0201dda:	000de797          	auipc	a5,0xde
ffffffffc0201dde:	e867b783          	ld	a5,-378(a5) # ffffffffc02dfc60 <pmm_manager>
ffffffffc0201de2:	739c                	ld	a5,32(a5)
ffffffffc0201de4:	85a6                	mv	a1,s1
ffffffffc0201de6:	8522                	mv	a0,s0
ffffffffc0201de8:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc0201dea:	6442                	ld	s0,16(sp)
ffffffffc0201dec:	60e2                	ld	ra,24(sp)
ffffffffc0201dee:	64a2                	ld	s1,8(sp)
ffffffffc0201df0:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0201df2:	bb7fe06f          	j	ffffffffc02009a8 <intr_enable>

ffffffffc0201df6 <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201df6:	100027f3          	csrr	a5,sstatus
ffffffffc0201dfa:	8b89                	andi	a5,a5,2
ffffffffc0201dfc:	e799                	bnez	a5,ffffffffc0201e0a <nr_free_pages+0x14>
{
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc0201dfe:	000de797          	auipc	a5,0xde
ffffffffc0201e02:	e627b783          	ld	a5,-414(a5) # ffffffffc02dfc60 <pmm_manager>
ffffffffc0201e06:	779c                	ld	a5,40(a5)
ffffffffc0201e08:	8782                	jr	a5
{
ffffffffc0201e0a:	1141                	addi	sp,sp,-16
ffffffffc0201e0c:	e406                	sd	ra,8(sp)
ffffffffc0201e0e:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc0201e10:	b9ffe0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0201e14:	000de797          	auipc	a5,0xde
ffffffffc0201e18:	e4c7b783          	ld	a5,-436(a5) # ffffffffc02dfc60 <pmm_manager>
ffffffffc0201e1c:	779c                	ld	a5,40(a5)
ffffffffc0201e1e:	9782                	jalr	a5
ffffffffc0201e20:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201e22:	b87fe0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc0201e26:	60a2                	ld	ra,8(sp)
ffffffffc0201e28:	8522                	mv	a0,s0
ffffffffc0201e2a:	6402                	ld	s0,0(sp)
ffffffffc0201e2c:	0141                	addi	sp,sp,16
ffffffffc0201e2e:	8082                	ret

ffffffffc0201e30 <get_pte>:
//  la:     the linear address need to map
//  create: a logical value to decide if alloc a page for PT
// return vaule: the kernel virtual address of this pte
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create)
{
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201e30:	01e5d793          	srli	a5,a1,0x1e
ffffffffc0201e34:	1ff7f793          	andi	a5,a5,511
{
ffffffffc0201e38:	7139                	addi	sp,sp,-64
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201e3a:	078e                	slli	a5,a5,0x3
{
ffffffffc0201e3c:	f426                	sd	s1,40(sp)
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201e3e:	00f504b3          	add	s1,a0,a5
    if (!(*pdep1 & PTE_V))
ffffffffc0201e42:	6094                	ld	a3,0(s1)
{
ffffffffc0201e44:	f04a                	sd	s2,32(sp)
ffffffffc0201e46:	ec4e                	sd	s3,24(sp)
ffffffffc0201e48:	e852                	sd	s4,16(sp)
ffffffffc0201e4a:	fc06                	sd	ra,56(sp)
ffffffffc0201e4c:	f822                	sd	s0,48(sp)
ffffffffc0201e4e:	e456                	sd	s5,8(sp)
ffffffffc0201e50:	e05a                	sd	s6,0(sp)
    if (!(*pdep1 & PTE_V))
ffffffffc0201e52:	0016f793          	andi	a5,a3,1
{
ffffffffc0201e56:	892e                	mv	s2,a1
ffffffffc0201e58:	8a32                	mv	s4,a2
ffffffffc0201e5a:	000de997          	auipc	s3,0xde
ffffffffc0201e5e:	df698993          	addi	s3,s3,-522 # ffffffffc02dfc50 <npage>
    if (!(*pdep1 & PTE_V))
ffffffffc0201e62:	efbd                	bnez	a5,ffffffffc0201ee0 <get_pte+0xb0>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201e64:	14060c63          	beqz	a2,ffffffffc0201fbc <get_pte+0x18c>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201e68:	100027f3          	csrr	a5,sstatus
ffffffffc0201e6c:	8b89                	andi	a5,a5,2
ffffffffc0201e6e:	14079963          	bnez	a5,ffffffffc0201fc0 <get_pte+0x190>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201e72:	000de797          	auipc	a5,0xde
ffffffffc0201e76:	dee7b783          	ld	a5,-530(a5) # ffffffffc02dfc60 <pmm_manager>
ffffffffc0201e7a:	6f9c                	ld	a5,24(a5)
ffffffffc0201e7c:	4505                	li	a0,1
ffffffffc0201e7e:	9782                	jalr	a5
ffffffffc0201e80:	842a                	mv	s0,a0
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201e82:	12040d63          	beqz	s0,ffffffffc0201fbc <get_pte+0x18c>
    return page - pages + nbase;
ffffffffc0201e86:	000deb17          	auipc	s6,0xde
ffffffffc0201e8a:	dd2b0b13          	addi	s6,s6,-558 # ffffffffc02dfc58 <pages>
ffffffffc0201e8e:	000b3503          	ld	a0,0(s6)
ffffffffc0201e92:	00080ab7          	lui	s5,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201e96:	000de997          	auipc	s3,0xde
ffffffffc0201e9a:	dba98993          	addi	s3,s3,-582 # ffffffffc02dfc50 <npage>
ffffffffc0201e9e:	40a40533          	sub	a0,s0,a0
ffffffffc0201ea2:	8519                	srai	a0,a0,0x6
ffffffffc0201ea4:	9556                	add	a0,a0,s5
ffffffffc0201ea6:	0009b703          	ld	a4,0(s3)
ffffffffc0201eaa:	00c51793          	slli	a5,a0,0xc
    page->ref = val;
ffffffffc0201eae:	4685                	li	a3,1
ffffffffc0201eb0:	c014                	sw	a3,0(s0)
ffffffffc0201eb2:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0201eb4:	0532                	slli	a0,a0,0xc
ffffffffc0201eb6:	16e7f763          	bgeu	a5,a4,ffffffffc0202024 <get_pte+0x1f4>
ffffffffc0201eba:	000de797          	auipc	a5,0xde
ffffffffc0201ebe:	dae7b783          	ld	a5,-594(a5) # ffffffffc02dfc68 <va_pa_offset>
ffffffffc0201ec2:	6605                	lui	a2,0x1
ffffffffc0201ec4:	4581                	li	a1,0
ffffffffc0201ec6:	953e                	add	a0,a0,a5
ffffffffc0201ec8:	590040ef          	jal	ra,ffffffffc0206458 <memset>
    return page - pages + nbase;
ffffffffc0201ecc:	000b3683          	ld	a3,0(s6)
ffffffffc0201ed0:	40d406b3          	sub	a3,s0,a3
ffffffffc0201ed4:	8699                	srai	a3,a3,0x6
ffffffffc0201ed6:	96d6                	add	a3,a3,s5
}

// construct PTE from a page and permission bits
static inline pte_t pte_create(uintptr_t ppn, int type)
{
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0201ed8:	06aa                	slli	a3,a3,0xa
ffffffffc0201eda:	0116e693          	ori	a3,a3,17
        *pdep1 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0201ede:	e094                	sd	a3,0(s1)
    }

    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0201ee0:	77fd                	lui	a5,0xfffff
ffffffffc0201ee2:	068a                	slli	a3,a3,0x2
ffffffffc0201ee4:	0009b703          	ld	a4,0(s3)
ffffffffc0201ee8:	8efd                	and	a3,a3,a5
ffffffffc0201eea:	00c6d793          	srli	a5,a3,0xc
ffffffffc0201eee:	10e7ff63          	bgeu	a5,a4,ffffffffc020200c <get_pte+0x1dc>
ffffffffc0201ef2:	000dea97          	auipc	s5,0xde
ffffffffc0201ef6:	d76a8a93          	addi	s5,s5,-650 # ffffffffc02dfc68 <va_pa_offset>
ffffffffc0201efa:	000ab403          	ld	s0,0(s5)
ffffffffc0201efe:	01595793          	srli	a5,s2,0x15
ffffffffc0201f02:	1ff7f793          	andi	a5,a5,511
ffffffffc0201f06:	96a2                	add	a3,a3,s0
ffffffffc0201f08:	00379413          	slli	s0,a5,0x3
ffffffffc0201f0c:	9436                	add	s0,s0,a3
    if (!(*pdep0 & PTE_V))
ffffffffc0201f0e:	6014                	ld	a3,0(s0)
ffffffffc0201f10:	0016f793          	andi	a5,a3,1
ffffffffc0201f14:	ebad                	bnez	a5,ffffffffc0201f86 <get_pte+0x156>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201f16:	0a0a0363          	beqz	s4,ffffffffc0201fbc <get_pte+0x18c>
ffffffffc0201f1a:	100027f3          	csrr	a5,sstatus
ffffffffc0201f1e:	8b89                	andi	a5,a5,2
ffffffffc0201f20:	efcd                	bnez	a5,ffffffffc0201fda <get_pte+0x1aa>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201f22:	000de797          	auipc	a5,0xde
ffffffffc0201f26:	d3e7b783          	ld	a5,-706(a5) # ffffffffc02dfc60 <pmm_manager>
ffffffffc0201f2a:	6f9c                	ld	a5,24(a5)
ffffffffc0201f2c:	4505                	li	a0,1
ffffffffc0201f2e:	9782                	jalr	a5
ffffffffc0201f30:	84aa                	mv	s1,a0
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201f32:	c4c9                	beqz	s1,ffffffffc0201fbc <get_pte+0x18c>
    return page - pages + nbase;
ffffffffc0201f34:	000deb17          	auipc	s6,0xde
ffffffffc0201f38:	d24b0b13          	addi	s6,s6,-732 # ffffffffc02dfc58 <pages>
ffffffffc0201f3c:	000b3503          	ld	a0,0(s6)
ffffffffc0201f40:	00080a37          	lui	s4,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201f44:	0009b703          	ld	a4,0(s3)
ffffffffc0201f48:	40a48533          	sub	a0,s1,a0
ffffffffc0201f4c:	8519                	srai	a0,a0,0x6
ffffffffc0201f4e:	9552                	add	a0,a0,s4
ffffffffc0201f50:	00c51793          	slli	a5,a0,0xc
    page->ref = val;
ffffffffc0201f54:	4685                	li	a3,1
ffffffffc0201f56:	c094                	sw	a3,0(s1)
ffffffffc0201f58:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0201f5a:	0532                	slli	a0,a0,0xc
ffffffffc0201f5c:	0ee7f163          	bgeu	a5,a4,ffffffffc020203e <get_pte+0x20e>
ffffffffc0201f60:	000ab783          	ld	a5,0(s5)
ffffffffc0201f64:	6605                	lui	a2,0x1
ffffffffc0201f66:	4581                	li	a1,0
ffffffffc0201f68:	953e                	add	a0,a0,a5
ffffffffc0201f6a:	4ee040ef          	jal	ra,ffffffffc0206458 <memset>
    return page - pages + nbase;
ffffffffc0201f6e:	000b3683          	ld	a3,0(s6)
ffffffffc0201f72:	40d486b3          	sub	a3,s1,a3
ffffffffc0201f76:	8699                	srai	a3,a3,0x6
ffffffffc0201f78:	96d2                	add	a3,a3,s4
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0201f7a:	06aa                	slli	a3,a3,0xa
ffffffffc0201f7c:	0116e693          	ori	a3,a3,17
        *pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0201f80:	e014                	sd	a3,0(s0)
    }
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0201f82:	0009b703          	ld	a4,0(s3)
ffffffffc0201f86:	068a                	slli	a3,a3,0x2
ffffffffc0201f88:	757d                	lui	a0,0xfffff
ffffffffc0201f8a:	8ee9                	and	a3,a3,a0
ffffffffc0201f8c:	00c6d793          	srli	a5,a3,0xc
ffffffffc0201f90:	06e7f263          	bgeu	a5,a4,ffffffffc0201ff4 <get_pte+0x1c4>
ffffffffc0201f94:	000ab503          	ld	a0,0(s5)
ffffffffc0201f98:	00c95913          	srli	s2,s2,0xc
ffffffffc0201f9c:	1ff97913          	andi	s2,s2,511
ffffffffc0201fa0:	96aa                	add	a3,a3,a0
ffffffffc0201fa2:	00391513          	slli	a0,s2,0x3
ffffffffc0201fa6:	9536                	add	a0,a0,a3
}
ffffffffc0201fa8:	70e2                	ld	ra,56(sp)
ffffffffc0201faa:	7442                	ld	s0,48(sp)
ffffffffc0201fac:	74a2                	ld	s1,40(sp)
ffffffffc0201fae:	7902                	ld	s2,32(sp)
ffffffffc0201fb0:	69e2                	ld	s3,24(sp)
ffffffffc0201fb2:	6a42                	ld	s4,16(sp)
ffffffffc0201fb4:	6aa2                	ld	s5,8(sp)
ffffffffc0201fb6:	6b02                	ld	s6,0(sp)
ffffffffc0201fb8:	6121                	addi	sp,sp,64
ffffffffc0201fba:	8082                	ret
            return NULL;
ffffffffc0201fbc:	4501                	li	a0,0
ffffffffc0201fbe:	b7ed                	j	ffffffffc0201fa8 <get_pte+0x178>
        intr_disable();
ffffffffc0201fc0:	9effe0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201fc4:	000de797          	auipc	a5,0xde
ffffffffc0201fc8:	c9c7b783          	ld	a5,-868(a5) # ffffffffc02dfc60 <pmm_manager>
ffffffffc0201fcc:	6f9c                	ld	a5,24(a5)
ffffffffc0201fce:	4505                	li	a0,1
ffffffffc0201fd0:	9782                	jalr	a5
ffffffffc0201fd2:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201fd4:	9d5fe0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0201fd8:	b56d                	j	ffffffffc0201e82 <get_pte+0x52>
        intr_disable();
ffffffffc0201fda:	9d5fe0ef          	jal	ra,ffffffffc02009ae <intr_disable>
ffffffffc0201fde:	000de797          	auipc	a5,0xde
ffffffffc0201fe2:	c827b783          	ld	a5,-894(a5) # ffffffffc02dfc60 <pmm_manager>
ffffffffc0201fe6:	6f9c                	ld	a5,24(a5)
ffffffffc0201fe8:	4505                	li	a0,1
ffffffffc0201fea:	9782                	jalr	a5
ffffffffc0201fec:	84aa                	mv	s1,a0
        intr_enable();
ffffffffc0201fee:	9bbfe0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0201ff2:	b781                	j	ffffffffc0201f32 <get_pte+0x102>
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0201ff4:	00005617          	auipc	a2,0x5
ffffffffc0201ff8:	2fc60613          	addi	a2,a2,764 # ffffffffc02072f0 <default_pmm_manager+0x38>
ffffffffc0201ffc:	0f900593          	li	a1,249
ffffffffc0202000:	00005517          	auipc	a0,0x5
ffffffffc0202004:	40850513          	addi	a0,a0,1032 # ffffffffc0207408 <default_pmm_manager+0x150>
ffffffffc0202008:	c8afe0ef          	jal	ra,ffffffffc0200492 <__panic>
    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc020200c:	00005617          	auipc	a2,0x5
ffffffffc0202010:	2e460613          	addi	a2,a2,740 # ffffffffc02072f0 <default_pmm_manager+0x38>
ffffffffc0202014:	0ec00593          	li	a1,236
ffffffffc0202018:	00005517          	auipc	a0,0x5
ffffffffc020201c:	3f050513          	addi	a0,a0,1008 # ffffffffc0207408 <default_pmm_manager+0x150>
ffffffffc0202020:	c72fe0ef          	jal	ra,ffffffffc0200492 <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0202024:	86aa                	mv	a3,a0
ffffffffc0202026:	00005617          	auipc	a2,0x5
ffffffffc020202a:	2ca60613          	addi	a2,a2,714 # ffffffffc02072f0 <default_pmm_manager+0x38>
ffffffffc020202e:	0e800593          	li	a1,232
ffffffffc0202032:	00005517          	auipc	a0,0x5
ffffffffc0202036:	3d650513          	addi	a0,a0,982 # ffffffffc0207408 <default_pmm_manager+0x150>
ffffffffc020203a:	c58fe0ef          	jal	ra,ffffffffc0200492 <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc020203e:	86aa                	mv	a3,a0
ffffffffc0202040:	00005617          	auipc	a2,0x5
ffffffffc0202044:	2b060613          	addi	a2,a2,688 # ffffffffc02072f0 <default_pmm_manager+0x38>
ffffffffc0202048:	0f600593          	li	a1,246
ffffffffc020204c:	00005517          	auipc	a0,0x5
ffffffffc0202050:	3bc50513          	addi	a0,a0,956 # ffffffffc0207408 <default_pmm_manager+0x150>
ffffffffc0202054:	c3efe0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0202058 <get_page>:

// get_page - get related Page struct for linear address la using PDT pgdir
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store)
{
ffffffffc0202058:	1141                	addi	sp,sp,-16
ffffffffc020205a:	e022                	sd	s0,0(sp)
ffffffffc020205c:	8432                	mv	s0,a2
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc020205e:	4601                	li	a2,0
{
ffffffffc0202060:	e406                	sd	ra,8(sp)
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0202062:	dcfff0ef          	jal	ra,ffffffffc0201e30 <get_pte>
    if (ptep_store != NULL)
ffffffffc0202066:	c011                	beqz	s0,ffffffffc020206a <get_page+0x12>
    {
        *ptep_store = ptep;
ffffffffc0202068:	e008                	sd	a0,0(s0)
    }
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc020206a:	c511                	beqz	a0,ffffffffc0202076 <get_page+0x1e>
ffffffffc020206c:	611c                	ld	a5,0(a0)
    {
        return pte2page(*ptep);
    }
    return NULL;
ffffffffc020206e:	4501                	li	a0,0
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc0202070:	0017f713          	andi	a4,a5,1
ffffffffc0202074:	e709                	bnez	a4,ffffffffc020207e <get_page+0x26>
}
ffffffffc0202076:	60a2                	ld	ra,8(sp)
ffffffffc0202078:	6402                	ld	s0,0(sp)
ffffffffc020207a:	0141                	addi	sp,sp,16
ffffffffc020207c:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc020207e:	078a                	slli	a5,a5,0x2
ffffffffc0202080:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202082:	000de717          	auipc	a4,0xde
ffffffffc0202086:	bce73703          	ld	a4,-1074(a4) # ffffffffc02dfc50 <npage>
ffffffffc020208a:	00e7ff63          	bgeu	a5,a4,ffffffffc02020a8 <get_page+0x50>
ffffffffc020208e:	60a2                	ld	ra,8(sp)
ffffffffc0202090:	6402                	ld	s0,0(sp)
    return &pages[PPN(pa) - nbase];
ffffffffc0202092:	fff80537          	lui	a0,0xfff80
ffffffffc0202096:	97aa                	add	a5,a5,a0
ffffffffc0202098:	079a                	slli	a5,a5,0x6
ffffffffc020209a:	000de517          	auipc	a0,0xde
ffffffffc020209e:	bbe53503          	ld	a0,-1090(a0) # ffffffffc02dfc58 <pages>
ffffffffc02020a2:	953e                	add	a0,a0,a5
ffffffffc02020a4:	0141                	addi	sp,sp,16
ffffffffc02020a6:	8082                	ret
ffffffffc02020a8:	c99ff0ef          	jal	ra,ffffffffc0201d40 <pa2page.part.0>

ffffffffc02020ac <unmap_range>:
        tlb_invalidate(pgdir, la); //(6) flush tlb
    }
}

void unmap_range(pde_t *pgdir, uintptr_t start, uintptr_t end)
{
ffffffffc02020ac:	7159                	addi	sp,sp,-112
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02020ae:	00c5e7b3          	or	a5,a1,a2
{
ffffffffc02020b2:	f486                	sd	ra,104(sp)
ffffffffc02020b4:	f0a2                	sd	s0,96(sp)
ffffffffc02020b6:	eca6                	sd	s1,88(sp)
ffffffffc02020b8:	e8ca                	sd	s2,80(sp)
ffffffffc02020ba:	e4ce                	sd	s3,72(sp)
ffffffffc02020bc:	e0d2                	sd	s4,64(sp)
ffffffffc02020be:	fc56                	sd	s5,56(sp)
ffffffffc02020c0:	f85a                	sd	s6,48(sp)
ffffffffc02020c2:	f45e                	sd	s7,40(sp)
ffffffffc02020c4:	f062                	sd	s8,32(sp)
ffffffffc02020c6:	ec66                	sd	s9,24(sp)
ffffffffc02020c8:	e86a                	sd	s10,16(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02020ca:	17d2                	slli	a5,a5,0x34
ffffffffc02020cc:	e3ed                	bnez	a5,ffffffffc02021ae <unmap_range+0x102>
    assert(USER_ACCESS(start, end));
ffffffffc02020ce:	002007b7          	lui	a5,0x200
ffffffffc02020d2:	842e                	mv	s0,a1
ffffffffc02020d4:	0ef5ed63          	bltu	a1,a5,ffffffffc02021ce <unmap_range+0x122>
ffffffffc02020d8:	8932                	mv	s2,a2
ffffffffc02020da:	0ec5fa63          	bgeu	a1,a2,ffffffffc02021ce <unmap_range+0x122>
ffffffffc02020de:	4785                	li	a5,1
ffffffffc02020e0:	07fe                	slli	a5,a5,0x1f
ffffffffc02020e2:	0ec7e663          	bltu	a5,a2,ffffffffc02021ce <unmap_range+0x122>
ffffffffc02020e6:	89aa                	mv	s3,a0
        }
        if (*ptep != 0)
        {
            page_remove_pte(pgdir, start, ptep);
        }
        start += PGSIZE;
ffffffffc02020e8:	6a05                	lui	s4,0x1
    if (PPN(pa) >= npage)
ffffffffc02020ea:	000dec97          	auipc	s9,0xde
ffffffffc02020ee:	b66c8c93          	addi	s9,s9,-1178 # ffffffffc02dfc50 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc02020f2:	000dec17          	auipc	s8,0xde
ffffffffc02020f6:	b66c0c13          	addi	s8,s8,-1178 # ffffffffc02dfc58 <pages>
ffffffffc02020fa:	fff80bb7          	lui	s7,0xfff80
        pmm_manager->free_pages(base, n);
ffffffffc02020fe:	000ded17          	auipc	s10,0xde
ffffffffc0202102:	b62d0d13          	addi	s10,s10,-1182 # ffffffffc02dfc60 <pmm_manager>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc0202106:	00200b37          	lui	s6,0x200
ffffffffc020210a:	ffe00ab7          	lui	s5,0xffe00
        pte_t *ptep = get_pte(pgdir, start, 0);
ffffffffc020210e:	4601                	li	a2,0
ffffffffc0202110:	85a2                	mv	a1,s0
ffffffffc0202112:	854e                	mv	a0,s3
ffffffffc0202114:	d1dff0ef          	jal	ra,ffffffffc0201e30 <get_pte>
ffffffffc0202118:	84aa                	mv	s1,a0
        if (ptep == NULL)
ffffffffc020211a:	cd29                	beqz	a0,ffffffffc0202174 <unmap_range+0xc8>
        if (*ptep != 0)
ffffffffc020211c:	611c                	ld	a5,0(a0)
ffffffffc020211e:	e395                	bnez	a5,ffffffffc0202142 <unmap_range+0x96>
        start += PGSIZE;
ffffffffc0202120:	9452                	add	s0,s0,s4
    } while (start != 0 && start < end);
ffffffffc0202122:	ff2466e3          	bltu	s0,s2,ffffffffc020210e <unmap_range+0x62>
}
ffffffffc0202126:	70a6                	ld	ra,104(sp)
ffffffffc0202128:	7406                	ld	s0,96(sp)
ffffffffc020212a:	64e6                	ld	s1,88(sp)
ffffffffc020212c:	6946                	ld	s2,80(sp)
ffffffffc020212e:	69a6                	ld	s3,72(sp)
ffffffffc0202130:	6a06                	ld	s4,64(sp)
ffffffffc0202132:	7ae2                	ld	s5,56(sp)
ffffffffc0202134:	7b42                	ld	s6,48(sp)
ffffffffc0202136:	7ba2                	ld	s7,40(sp)
ffffffffc0202138:	7c02                	ld	s8,32(sp)
ffffffffc020213a:	6ce2                	ld	s9,24(sp)
ffffffffc020213c:	6d42                	ld	s10,16(sp)
ffffffffc020213e:	6165                	addi	sp,sp,112
ffffffffc0202140:	8082                	ret
    if (*ptep & PTE_V)
ffffffffc0202142:	0017f713          	andi	a4,a5,1
ffffffffc0202146:	df69                	beqz	a4,ffffffffc0202120 <unmap_range+0x74>
    if (PPN(pa) >= npage)
ffffffffc0202148:	000cb703          	ld	a4,0(s9)
    return pa2page(PTE_ADDR(pte));
ffffffffc020214c:	078a                	slli	a5,a5,0x2
ffffffffc020214e:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202150:	08e7ff63          	bgeu	a5,a4,ffffffffc02021ee <unmap_range+0x142>
    return &pages[PPN(pa) - nbase];
ffffffffc0202154:	000c3503          	ld	a0,0(s8)
ffffffffc0202158:	97de                	add	a5,a5,s7
ffffffffc020215a:	079a                	slli	a5,a5,0x6
ffffffffc020215c:	953e                	add	a0,a0,a5
    page->ref -= 1;
ffffffffc020215e:	411c                	lw	a5,0(a0)
ffffffffc0202160:	fff7871b          	addiw	a4,a5,-1
ffffffffc0202164:	c118                	sw	a4,0(a0)
        if (page_ref(page) ==
ffffffffc0202166:	cf11                	beqz	a4,ffffffffc0202182 <unmap_range+0xd6>
        *ptep = 0;                 //(5) clear second page table entry
ffffffffc0202168:	0004b023          	sd	zero,0(s1)

// invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
void tlb_invalidate(pde_t *pgdir, uintptr_t la)
{
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc020216c:	12040073          	sfence.vma	s0
        start += PGSIZE;
ffffffffc0202170:	9452                	add	s0,s0,s4
    } while (start != 0 && start < end);
ffffffffc0202172:	bf45                	j	ffffffffc0202122 <unmap_range+0x76>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc0202174:	945a                	add	s0,s0,s6
ffffffffc0202176:	01547433          	and	s0,s0,s5
    } while (start != 0 && start < end);
ffffffffc020217a:	d455                	beqz	s0,ffffffffc0202126 <unmap_range+0x7a>
ffffffffc020217c:	f92469e3          	bltu	s0,s2,ffffffffc020210e <unmap_range+0x62>
ffffffffc0202180:	b75d                	j	ffffffffc0202126 <unmap_range+0x7a>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0202182:	100027f3          	csrr	a5,sstatus
ffffffffc0202186:	8b89                	andi	a5,a5,2
ffffffffc0202188:	e799                	bnez	a5,ffffffffc0202196 <unmap_range+0xea>
        pmm_manager->free_pages(base, n);
ffffffffc020218a:	000d3783          	ld	a5,0(s10)
ffffffffc020218e:	4585                	li	a1,1
ffffffffc0202190:	739c                	ld	a5,32(a5)
ffffffffc0202192:	9782                	jalr	a5
    if (flag) {
ffffffffc0202194:	bfd1                	j	ffffffffc0202168 <unmap_range+0xbc>
ffffffffc0202196:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202198:	817fe0ef          	jal	ra,ffffffffc02009ae <intr_disable>
ffffffffc020219c:	000d3783          	ld	a5,0(s10)
ffffffffc02021a0:	6522                	ld	a0,8(sp)
ffffffffc02021a2:	4585                	li	a1,1
ffffffffc02021a4:	739c                	ld	a5,32(a5)
ffffffffc02021a6:	9782                	jalr	a5
        intr_enable();
ffffffffc02021a8:	801fe0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc02021ac:	bf75                	j	ffffffffc0202168 <unmap_range+0xbc>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02021ae:	00005697          	auipc	a3,0x5
ffffffffc02021b2:	26a68693          	addi	a3,a3,618 # ffffffffc0207418 <default_pmm_manager+0x160>
ffffffffc02021b6:	00005617          	auipc	a2,0x5
ffffffffc02021ba:	d5260613          	addi	a2,a2,-686 # ffffffffc0206f08 <commands+0x818>
ffffffffc02021be:	12100593          	li	a1,289
ffffffffc02021c2:	00005517          	auipc	a0,0x5
ffffffffc02021c6:	24650513          	addi	a0,a0,582 # ffffffffc0207408 <default_pmm_manager+0x150>
ffffffffc02021ca:	ac8fe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(USER_ACCESS(start, end));
ffffffffc02021ce:	00005697          	auipc	a3,0x5
ffffffffc02021d2:	27a68693          	addi	a3,a3,634 # ffffffffc0207448 <default_pmm_manager+0x190>
ffffffffc02021d6:	00005617          	auipc	a2,0x5
ffffffffc02021da:	d3260613          	addi	a2,a2,-718 # ffffffffc0206f08 <commands+0x818>
ffffffffc02021de:	12200593          	li	a1,290
ffffffffc02021e2:	00005517          	auipc	a0,0x5
ffffffffc02021e6:	22650513          	addi	a0,a0,550 # ffffffffc0207408 <default_pmm_manager+0x150>
ffffffffc02021ea:	aa8fe0ef          	jal	ra,ffffffffc0200492 <__panic>
ffffffffc02021ee:	b53ff0ef          	jal	ra,ffffffffc0201d40 <pa2page.part.0>

ffffffffc02021f2 <exit_range>:
{
ffffffffc02021f2:	7119                	addi	sp,sp,-128
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02021f4:	00c5e7b3          	or	a5,a1,a2
{
ffffffffc02021f8:	fc86                	sd	ra,120(sp)
ffffffffc02021fa:	f8a2                	sd	s0,112(sp)
ffffffffc02021fc:	f4a6                	sd	s1,104(sp)
ffffffffc02021fe:	f0ca                	sd	s2,96(sp)
ffffffffc0202200:	ecce                	sd	s3,88(sp)
ffffffffc0202202:	e8d2                	sd	s4,80(sp)
ffffffffc0202204:	e4d6                	sd	s5,72(sp)
ffffffffc0202206:	e0da                	sd	s6,64(sp)
ffffffffc0202208:	fc5e                	sd	s7,56(sp)
ffffffffc020220a:	f862                	sd	s8,48(sp)
ffffffffc020220c:	f466                	sd	s9,40(sp)
ffffffffc020220e:	f06a                	sd	s10,32(sp)
ffffffffc0202210:	ec6e                	sd	s11,24(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202212:	17d2                	slli	a5,a5,0x34
ffffffffc0202214:	20079a63          	bnez	a5,ffffffffc0202428 <exit_range+0x236>
    assert(USER_ACCESS(start, end));
ffffffffc0202218:	002007b7          	lui	a5,0x200
ffffffffc020221c:	24f5e463          	bltu	a1,a5,ffffffffc0202464 <exit_range+0x272>
ffffffffc0202220:	8ab2                	mv	s5,a2
ffffffffc0202222:	24c5f163          	bgeu	a1,a2,ffffffffc0202464 <exit_range+0x272>
ffffffffc0202226:	4785                	li	a5,1
ffffffffc0202228:	07fe                	slli	a5,a5,0x1f
ffffffffc020222a:	22c7ed63          	bltu	a5,a2,ffffffffc0202464 <exit_range+0x272>
    d1start = ROUNDDOWN(start, PDSIZE);
ffffffffc020222e:	c00009b7          	lui	s3,0xc0000
ffffffffc0202232:	0135f9b3          	and	s3,a1,s3
    d0start = ROUNDDOWN(start, PTSIZE);
ffffffffc0202236:	ffe00937          	lui	s2,0xffe00
ffffffffc020223a:	400007b7          	lui	a5,0x40000
    return KADDR(page2pa(page));
ffffffffc020223e:	5cfd                	li	s9,-1
ffffffffc0202240:	8c2a                	mv	s8,a0
ffffffffc0202242:	0125f933          	and	s2,a1,s2
ffffffffc0202246:	99be                	add	s3,s3,a5
    if (PPN(pa) >= npage)
ffffffffc0202248:	000ded17          	auipc	s10,0xde
ffffffffc020224c:	a08d0d13          	addi	s10,s10,-1528 # ffffffffc02dfc50 <npage>
    return KADDR(page2pa(page));
ffffffffc0202250:	00ccdc93          	srli	s9,s9,0xc
    return &pages[PPN(pa) - nbase];
ffffffffc0202254:	000de717          	auipc	a4,0xde
ffffffffc0202258:	a0470713          	addi	a4,a4,-1532 # ffffffffc02dfc58 <pages>
        pmm_manager->free_pages(base, n);
ffffffffc020225c:	000ded97          	auipc	s11,0xde
ffffffffc0202260:	a04d8d93          	addi	s11,s11,-1532 # ffffffffc02dfc60 <pmm_manager>
        pde1 = pgdir[PDX1(d1start)];
ffffffffc0202264:	c0000437          	lui	s0,0xc0000
ffffffffc0202268:	944e                	add	s0,s0,s3
ffffffffc020226a:	8079                	srli	s0,s0,0x1e
ffffffffc020226c:	1ff47413          	andi	s0,s0,511
ffffffffc0202270:	040e                	slli	s0,s0,0x3
ffffffffc0202272:	9462                	add	s0,s0,s8
ffffffffc0202274:	00043a03          	ld	s4,0(s0) # ffffffffc0000000 <_binary_obj___user_matrix_out_size+0xffffffffbfff3700>
        if (pde1 & PTE_V)
ffffffffc0202278:	001a7793          	andi	a5,s4,1
ffffffffc020227c:	eb99                	bnez	a5,ffffffffc0202292 <exit_range+0xa0>
    } while (d1start != 0 && d1start < end);
ffffffffc020227e:	12098463          	beqz	s3,ffffffffc02023a6 <exit_range+0x1b4>
ffffffffc0202282:	400007b7          	lui	a5,0x40000
ffffffffc0202286:	97ce                	add	a5,a5,s3
ffffffffc0202288:	894e                	mv	s2,s3
ffffffffc020228a:	1159fe63          	bgeu	s3,s5,ffffffffc02023a6 <exit_range+0x1b4>
ffffffffc020228e:	89be                	mv	s3,a5
ffffffffc0202290:	bfd1                	j	ffffffffc0202264 <exit_range+0x72>
    if (PPN(pa) >= npage)
ffffffffc0202292:	000d3783          	ld	a5,0(s10)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202296:	0a0a                	slli	s4,s4,0x2
ffffffffc0202298:	00ca5a13          	srli	s4,s4,0xc
    if (PPN(pa) >= npage)
ffffffffc020229c:	1cfa7263          	bgeu	s4,a5,ffffffffc0202460 <exit_range+0x26e>
    return &pages[PPN(pa) - nbase];
ffffffffc02022a0:	fff80637          	lui	a2,0xfff80
ffffffffc02022a4:	9652                	add	a2,a2,s4
    return page - pages + nbase;
ffffffffc02022a6:	000806b7          	lui	a3,0x80
ffffffffc02022aa:	96b2                	add	a3,a3,a2
    return KADDR(page2pa(page));
ffffffffc02022ac:	0196f5b3          	and	a1,a3,s9
    return &pages[PPN(pa) - nbase];
ffffffffc02022b0:	061a                	slli	a2,a2,0x6
    return page2ppn(page) << PGSHIFT;
ffffffffc02022b2:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02022b4:	18f5fa63          	bgeu	a1,a5,ffffffffc0202448 <exit_range+0x256>
ffffffffc02022b8:	000de817          	auipc	a6,0xde
ffffffffc02022bc:	9b080813          	addi	a6,a6,-1616 # ffffffffc02dfc68 <va_pa_offset>
ffffffffc02022c0:	00083b03          	ld	s6,0(a6)
            free_pd0 = 1;
ffffffffc02022c4:	4b85                	li	s7,1
    return &pages[PPN(pa) - nbase];
ffffffffc02022c6:	fff80e37          	lui	t3,0xfff80
    return KADDR(page2pa(page));
ffffffffc02022ca:	9b36                	add	s6,s6,a3
    return page - pages + nbase;
ffffffffc02022cc:	00080337          	lui	t1,0x80
ffffffffc02022d0:	6885                	lui	a7,0x1
ffffffffc02022d2:	a819                	j	ffffffffc02022e8 <exit_range+0xf6>
                    free_pd0 = 0;
ffffffffc02022d4:	4b81                	li	s7,0
                d0start += PTSIZE;
ffffffffc02022d6:	002007b7          	lui	a5,0x200
ffffffffc02022da:	993e                	add	s2,s2,a5
            } while (d0start != 0 && d0start < d1start + PDSIZE && d0start < end);
ffffffffc02022dc:	08090c63          	beqz	s2,ffffffffc0202374 <exit_range+0x182>
ffffffffc02022e0:	09397a63          	bgeu	s2,s3,ffffffffc0202374 <exit_range+0x182>
ffffffffc02022e4:	0f597063          	bgeu	s2,s5,ffffffffc02023c4 <exit_range+0x1d2>
                pde0 = pd0[PDX0(d0start)];
ffffffffc02022e8:	01595493          	srli	s1,s2,0x15
ffffffffc02022ec:	1ff4f493          	andi	s1,s1,511
ffffffffc02022f0:	048e                	slli	s1,s1,0x3
ffffffffc02022f2:	94da                	add	s1,s1,s6
ffffffffc02022f4:	609c                	ld	a5,0(s1)
                if (pde0 & PTE_V)
ffffffffc02022f6:	0017f693          	andi	a3,a5,1
ffffffffc02022fa:	dee9                	beqz	a3,ffffffffc02022d4 <exit_range+0xe2>
    if (PPN(pa) >= npage)
ffffffffc02022fc:	000d3583          	ld	a1,0(s10)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202300:	078a                	slli	a5,a5,0x2
ffffffffc0202302:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202304:	14b7fe63          	bgeu	a5,a1,ffffffffc0202460 <exit_range+0x26e>
    return &pages[PPN(pa) - nbase];
ffffffffc0202308:	97f2                	add	a5,a5,t3
    return page - pages + nbase;
ffffffffc020230a:	006786b3          	add	a3,a5,t1
    return KADDR(page2pa(page));
ffffffffc020230e:	0196feb3          	and	t4,a3,s9
    return &pages[PPN(pa) - nbase];
ffffffffc0202312:	00679513          	slli	a0,a5,0x6
    return page2ppn(page) << PGSHIFT;
ffffffffc0202316:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202318:	12bef863          	bgeu	t4,a1,ffffffffc0202448 <exit_range+0x256>
ffffffffc020231c:	00083783          	ld	a5,0(a6)
ffffffffc0202320:	96be                	add	a3,a3,a5
                    for (int i = 0; i < NPTEENTRY; i++)
ffffffffc0202322:	011685b3          	add	a1,a3,a7
                        if (pt[i] & PTE_V)
ffffffffc0202326:	629c                	ld	a5,0(a3)
ffffffffc0202328:	8b85                	andi	a5,a5,1
ffffffffc020232a:	f7d5                	bnez	a5,ffffffffc02022d6 <exit_range+0xe4>
                    for (int i = 0; i < NPTEENTRY; i++)
ffffffffc020232c:	06a1                	addi	a3,a3,8
ffffffffc020232e:	fed59ce3          	bne	a1,a3,ffffffffc0202326 <exit_range+0x134>
    return &pages[PPN(pa) - nbase];
ffffffffc0202332:	631c                	ld	a5,0(a4)
ffffffffc0202334:	953e                	add	a0,a0,a5
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0202336:	100027f3          	csrr	a5,sstatus
ffffffffc020233a:	8b89                	andi	a5,a5,2
ffffffffc020233c:	e7d9                	bnez	a5,ffffffffc02023ca <exit_range+0x1d8>
        pmm_manager->free_pages(base, n);
ffffffffc020233e:	000db783          	ld	a5,0(s11)
ffffffffc0202342:	4585                	li	a1,1
ffffffffc0202344:	e032                	sd	a2,0(sp)
ffffffffc0202346:	739c                	ld	a5,32(a5)
ffffffffc0202348:	9782                	jalr	a5
    if (flag) {
ffffffffc020234a:	6602                	ld	a2,0(sp)
ffffffffc020234c:	000de817          	auipc	a6,0xde
ffffffffc0202350:	91c80813          	addi	a6,a6,-1764 # ffffffffc02dfc68 <va_pa_offset>
ffffffffc0202354:	fff80e37          	lui	t3,0xfff80
ffffffffc0202358:	00080337          	lui	t1,0x80
ffffffffc020235c:	6885                	lui	a7,0x1
ffffffffc020235e:	000de717          	auipc	a4,0xde
ffffffffc0202362:	8fa70713          	addi	a4,a4,-1798 # ffffffffc02dfc58 <pages>
                        pd0[PDX0(d0start)] = 0;
ffffffffc0202366:	0004b023          	sd	zero,0(s1)
                d0start += PTSIZE;
ffffffffc020236a:	002007b7          	lui	a5,0x200
ffffffffc020236e:	993e                	add	s2,s2,a5
            } while (d0start != 0 && d0start < d1start + PDSIZE && d0start < end);
ffffffffc0202370:	f60918e3          	bnez	s2,ffffffffc02022e0 <exit_range+0xee>
            if (free_pd0)
ffffffffc0202374:	f00b85e3          	beqz	s7,ffffffffc020227e <exit_range+0x8c>
    if (PPN(pa) >= npage)
ffffffffc0202378:	000d3783          	ld	a5,0(s10)
ffffffffc020237c:	0efa7263          	bgeu	s4,a5,ffffffffc0202460 <exit_range+0x26e>
    return &pages[PPN(pa) - nbase];
ffffffffc0202380:	6308                	ld	a0,0(a4)
ffffffffc0202382:	9532                	add	a0,a0,a2
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0202384:	100027f3          	csrr	a5,sstatus
ffffffffc0202388:	8b89                	andi	a5,a5,2
ffffffffc020238a:	efad                	bnez	a5,ffffffffc0202404 <exit_range+0x212>
        pmm_manager->free_pages(base, n);
ffffffffc020238c:	000db783          	ld	a5,0(s11)
ffffffffc0202390:	4585                	li	a1,1
ffffffffc0202392:	739c                	ld	a5,32(a5)
ffffffffc0202394:	9782                	jalr	a5
ffffffffc0202396:	000de717          	auipc	a4,0xde
ffffffffc020239a:	8c270713          	addi	a4,a4,-1854 # ffffffffc02dfc58 <pages>
                pgdir[PDX1(d1start)] = 0;
ffffffffc020239e:	00043023          	sd	zero,0(s0)
    } while (d1start != 0 && d1start < end);
ffffffffc02023a2:	ee0990e3          	bnez	s3,ffffffffc0202282 <exit_range+0x90>
}
ffffffffc02023a6:	70e6                	ld	ra,120(sp)
ffffffffc02023a8:	7446                	ld	s0,112(sp)
ffffffffc02023aa:	74a6                	ld	s1,104(sp)
ffffffffc02023ac:	7906                	ld	s2,96(sp)
ffffffffc02023ae:	69e6                	ld	s3,88(sp)
ffffffffc02023b0:	6a46                	ld	s4,80(sp)
ffffffffc02023b2:	6aa6                	ld	s5,72(sp)
ffffffffc02023b4:	6b06                	ld	s6,64(sp)
ffffffffc02023b6:	7be2                	ld	s7,56(sp)
ffffffffc02023b8:	7c42                	ld	s8,48(sp)
ffffffffc02023ba:	7ca2                	ld	s9,40(sp)
ffffffffc02023bc:	7d02                	ld	s10,32(sp)
ffffffffc02023be:	6de2                	ld	s11,24(sp)
ffffffffc02023c0:	6109                	addi	sp,sp,128
ffffffffc02023c2:	8082                	ret
            if (free_pd0)
ffffffffc02023c4:	ea0b8fe3          	beqz	s7,ffffffffc0202282 <exit_range+0x90>
ffffffffc02023c8:	bf45                	j	ffffffffc0202378 <exit_range+0x186>
ffffffffc02023ca:	e032                	sd	a2,0(sp)
        intr_disable();
ffffffffc02023cc:	e42a                	sd	a0,8(sp)
ffffffffc02023ce:	de0fe0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc02023d2:	000db783          	ld	a5,0(s11)
ffffffffc02023d6:	6522                	ld	a0,8(sp)
ffffffffc02023d8:	4585                	li	a1,1
ffffffffc02023da:	739c                	ld	a5,32(a5)
ffffffffc02023dc:	9782                	jalr	a5
        intr_enable();
ffffffffc02023de:	dcafe0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc02023e2:	6602                	ld	a2,0(sp)
ffffffffc02023e4:	000de717          	auipc	a4,0xde
ffffffffc02023e8:	87470713          	addi	a4,a4,-1932 # ffffffffc02dfc58 <pages>
ffffffffc02023ec:	6885                	lui	a7,0x1
ffffffffc02023ee:	00080337          	lui	t1,0x80
ffffffffc02023f2:	fff80e37          	lui	t3,0xfff80
ffffffffc02023f6:	000de817          	auipc	a6,0xde
ffffffffc02023fa:	87280813          	addi	a6,a6,-1934 # ffffffffc02dfc68 <va_pa_offset>
                        pd0[PDX0(d0start)] = 0;
ffffffffc02023fe:	0004b023          	sd	zero,0(s1)
ffffffffc0202402:	b7a5                	j	ffffffffc020236a <exit_range+0x178>
ffffffffc0202404:	e02a                	sd	a0,0(sp)
        intr_disable();
ffffffffc0202406:	da8fe0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc020240a:	000db783          	ld	a5,0(s11)
ffffffffc020240e:	6502                	ld	a0,0(sp)
ffffffffc0202410:	4585                	li	a1,1
ffffffffc0202412:	739c                	ld	a5,32(a5)
ffffffffc0202414:	9782                	jalr	a5
        intr_enable();
ffffffffc0202416:	d92fe0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc020241a:	000de717          	auipc	a4,0xde
ffffffffc020241e:	83e70713          	addi	a4,a4,-1986 # ffffffffc02dfc58 <pages>
                pgdir[PDX1(d1start)] = 0;
ffffffffc0202422:	00043023          	sd	zero,0(s0)
ffffffffc0202426:	bfb5                	j	ffffffffc02023a2 <exit_range+0x1b0>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202428:	00005697          	auipc	a3,0x5
ffffffffc020242c:	ff068693          	addi	a3,a3,-16 # ffffffffc0207418 <default_pmm_manager+0x160>
ffffffffc0202430:	00005617          	auipc	a2,0x5
ffffffffc0202434:	ad860613          	addi	a2,a2,-1320 # ffffffffc0206f08 <commands+0x818>
ffffffffc0202438:	13600593          	li	a1,310
ffffffffc020243c:	00005517          	auipc	a0,0x5
ffffffffc0202440:	fcc50513          	addi	a0,a0,-52 # ffffffffc0207408 <default_pmm_manager+0x150>
ffffffffc0202444:	84efe0ef          	jal	ra,ffffffffc0200492 <__panic>
    return KADDR(page2pa(page));
ffffffffc0202448:	00005617          	auipc	a2,0x5
ffffffffc020244c:	ea860613          	addi	a2,a2,-344 # ffffffffc02072f0 <default_pmm_manager+0x38>
ffffffffc0202450:	07100593          	li	a1,113
ffffffffc0202454:	00005517          	auipc	a0,0x5
ffffffffc0202458:	ec450513          	addi	a0,a0,-316 # ffffffffc0207318 <default_pmm_manager+0x60>
ffffffffc020245c:	836fe0ef          	jal	ra,ffffffffc0200492 <__panic>
ffffffffc0202460:	8e1ff0ef          	jal	ra,ffffffffc0201d40 <pa2page.part.0>
    assert(USER_ACCESS(start, end));
ffffffffc0202464:	00005697          	auipc	a3,0x5
ffffffffc0202468:	fe468693          	addi	a3,a3,-28 # ffffffffc0207448 <default_pmm_manager+0x190>
ffffffffc020246c:	00005617          	auipc	a2,0x5
ffffffffc0202470:	a9c60613          	addi	a2,a2,-1380 # ffffffffc0206f08 <commands+0x818>
ffffffffc0202474:	13700593          	li	a1,311
ffffffffc0202478:	00005517          	auipc	a0,0x5
ffffffffc020247c:	f9050513          	addi	a0,a0,-112 # ffffffffc0207408 <default_pmm_manager+0x150>
ffffffffc0202480:	812fe0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0202484 <page_remove>:
{
ffffffffc0202484:	7179                	addi	sp,sp,-48
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0202486:	4601                	li	a2,0
{
ffffffffc0202488:	ec26                	sd	s1,24(sp)
ffffffffc020248a:	f406                	sd	ra,40(sp)
ffffffffc020248c:	f022                	sd	s0,32(sp)
ffffffffc020248e:	84ae                	mv	s1,a1
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0202490:	9a1ff0ef          	jal	ra,ffffffffc0201e30 <get_pte>
    if (ptep != NULL)
ffffffffc0202494:	c511                	beqz	a0,ffffffffc02024a0 <page_remove+0x1c>
    if (*ptep & PTE_V)
ffffffffc0202496:	611c                	ld	a5,0(a0)
ffffffffc0202498:	842a                	mv	s0,a0
ffffffffc020249a:	0017f713          	andi	a4,a5,1
ffffffffc020249e:	e711                	bnez	a4,ffffffffc02024aa <page_remove+0x26>
}
ffffffffc02024a0:	70a2                	ld	ra,40(sp)
ffffffffc02024a2:	7402                	ld	s0,32(sp)
ffffffffc02024a4:	64e2                	ld	s1,24(sp)
ffffffffc02024a6:	6145                	addi	sp,sp,48
ffffffffc02024a8:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc02024aa:	078a                	slli	a5,a5,0x2
ffffffffc02024ac:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02024ae:	000dd717          	auipc	a4,0xdd
ffffffffc02024b2:	7a273703          	ld	a4,1954(a4) # ffffffffc02dfc50 <npage>
ffffffffc02024b6:	06e7f363          	bgeu	a5,a4,ffffffffc020251c <page_remove+0x98>
    return &pages[PPN(pa) - nbase];
ffffffffc02024ba:	fff80537          	lui	a0,0xfff80
ffffffffc02024be:	97aa                	add	a5,a5,a0
ffffffffc02024c0:	079a                	slli	a5,a5,0x6
ffffffffc02024c2:	000dd517          	auipc	a0,0xdd
ffffffffc02024c6:	79653503          	ld	a0,1942(a0) # ffffffffc02dfc58 <pages>
ffffffffc02024ca:	953e                	add	a0,a0,a5
    page->ref -= 1;
ffffffffc02024cc:	411c                	lw	a5,0(a0)
ffffffffc02024ce:	fff7871b          	addiw	a4,a5,-1
ffffffffc02024d2:	c118                	sw	a4,0(a0)
        if (page_ref(page) ==
ffffffffc02024d4:	cb11                	beqz	a4,ffffffffc02024e8 <page_remove+0x64>
        *ptep = 0;                 //(5) clear second page table entry
ffffffffc02024d6:	00043023          	sd	zero,0(s0)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02024da:	12048073          	sfence.vma	s1
}
ffffffffc02024de:	70a2                	ld	ra,40(sp)
ffffffffc02024e0:	7402                	ld	s0,32(sp)
ffffffffc02024e2:	64e2                	ld	s1,24(sp)
ffffffffc02024e4:	6145                	addi	sp,sp,48
ffffffffc02024e6:	8082                	ret
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02024e8:	100027f3          	csrr	a5,sstatus
ffffffffc02024ec:	8b89                	andi	a5,a5,2
ffffffffc02024ee:	eb89                	bnez	a5,ffffffffc0202500 <page_remove+0x7c>
        pmm_manager->free_pages(base, n);
ffffffffc02024f0:	000dd797          	auipc	a5,0xdd
ffffffffc02024f4:	7707b783          	ld	a5,1904(a5) # ffffffffc02dfc60 <pmm_manager>
ffffffffc02024f8:	739c                	ld	a5,32(a5)
ffffffffc02024fa:	4585                	li	a1,1
ffffffffc02024fc:	9782                	jalr	a5
    if (flag) {
ffffffffc02024fe:	bfe1                	j	ffffffffc02024d6 <page_remove+0x52>
        intr_disable();
ffffffffc0202500:	e42a                	sd	a0,8(sp)
ffffffffc0202502:	cacfe0ef          	jal	ra,ffffffffc02009ae <intr_disable>
ffffffffc0202506:	000dd797          	auipc	a5,0xdd
ffffffffc020250a:	75a7b783          	ld	a5,1882(a5) # ffffffffc02dfc60 <pmm_manager>
ffffffffc020250e:	739c                	ld	a5,32(a5)
ffffffffc0202510:	6522                	ld	a0,8(sp)
ffffffffc0202512:	4585                	li	a1,1
ffffffffc0202514:	9782                	jalr	a5
        intr_enable();
ffffffffc0202516:	c92fe0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc020251a:	bf75                	j	ffffffffc02024d6 <page_remove+0x52>
ffffffffc020251c:	825ff0ef          	jal	ra,ffffffffc0201d40 <pa2page.part.0>

ffffffffc0202520 <page_insert>:
{
ffffffffc0202520:	7139                	addi	sp,sp,-64
ffffffffc0202522:	e852                	sd	s4,16(sp)
ffffffffc0202524:	8a32                	mv	s4,a2
ffffffffc0202526:	f822                	sd	s0,48(sp)
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0202528:	4605                	li	a2,1
{
ffffffffc020252a:	842e                	mv	s0,a1
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc020252c:	85d2                	mv	a1,s4
{
ffffffffc020252e:	f426                	sd	s1,40(sp)
ffffffffc0202530:	fc06                	sd	ra,56(sp)
ffffffffc0202532:	f04a                	sd	s2,32(sp)
ffffffffc0202534:	ec4e                	sd	s3,24(sp)
ffffffffc0202536:	e456                	sd	s5,8(sp)
ffffffffc0202538:	84b6                	mv	s1,a3
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc020253a:	8f7ff0ef          	jal	ra,ffffffffc0201e30 <get_pte>
    if (ptep == NULL)
ffffffffc020253e:	c961                	beqz	a0,ffffffffc020260e <page_insert+0xee>
    page->ref += 1;
ffffffffc0202540:	4014                	lw	a3,0(s0)
    if (*ptep & PTE_V)
ffffffffc0202542:	611c                	ld	a5,0(a0)
ffffffffc0202544:	89aa                	mv	s3,a0
ffffffffc0202546:	0016871b          	addiw	a4,a3,1
ffffffffc020254a:	c018                	sw	a4,0(s0)
ffffffffc020254c:	0017f713          	andi	a4,a5,1
ffffffffc0202550:	ef05                	bnez	a4,ffffffffc0202588 <page_insert+0x68>
    return page - pages + nbase;
ffffffffc0202552:	000dd717          	auipc	a4,0xdd
ffffffffc0202556:	70673703          	ld	a4,1798(a4) # ffffffffc02dfc58 <pages>
ffffffffc020255a:	8c19                	sub	s0,s0,a4
ffffffffc020255c:	000807b7          	lui	a5,0x80
ffffffffc0202560:	8419                	srai	s0,s0,0x6
ffffffffc0202562:	943e                	add	s0,s0,a5
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0202564:	042a                	slli	s0,s0,0xa
ffffffffc0202566:	8cc1                	or	s1,s1,s0
ffffffffc0202568:	0014e493          	ori	s1,s1,1
    *ptep = pte_create(page2ppn(page), PTE_V | perm);
ffffffffc020256c:	0099b023          	sd	s1,0(s3) # ffffffffc0000000 <_binary_obj___user_matrix_out_size+0xffffffffbfff3700>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202570:	120a0073          	sfence.vma	s4
    return 0;
ffffffffc0202574:	4501                	li	a0,0
}
ffffffffc0202576:	70e2                	ld	ra,56(sp)
ffffffffc0202578:	7442                	ld	s0,48(sp)
ffffffffc020257a:	74a2                	ld	s1,40(sp)
ffffffffc020257c:	7902                	ld	s2,32(sp)
ffffffffc020257e:	69e2                	ld	s3,24(sp)
ffffffffc0202580:	6a42                	ld	s4,16(sp)
ffffffffc0202582:	6aa2                	ld	s5,8(sp)
ffffffffc0202584:	6121                	addi	sp,sp,64
ffffffffc0202586:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc0202588:	078a                	slli	a5,a5,0x2
ffffffffc020258a:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc020258c:	000dd717          	auipc	a4,0xdd
ffffffffc0202590:	6c473703          	ld	a4,1732(a4) # ffffffffc02dfc50 <npage>
ffffffffc0202594:	06e7ff63          	bgeu	a5,a4,ffffffffc0202612 <page_insert+0xf2>
    return &pages[PPN(pa) - nbase];
ffffffffc0202598:	000dda97          	auipc	s5,0xdd
ffffffffc020259c:	6c0a8a93          	addi	s5,s5,1728 # ffffffffc02dfc58 <pages>
ffffffffc02025a0:	000ab703          	ld	a4,0(s5)
ffffffffc02025a4:	fff80937          	lui	s2,0xfff80
ffffffffc02025a8:	993e                	add	s2,s2,a5
ffffffffc02025aa:	091a                	slli	s2,s2,0x6
ffffffffc02025ac:	993a                	add	s2,s2,a4
        if (p == page)
ffffffffc02025ae:	01240c63          	beq	s0,s2,ffffffffc02025c6 <page_insert+0xa6>
    page->ref -= 1;
ffffffffc02025b2:	00092783          	lw	a5,0(s2) # fffffffffff80000 <end+0x3fca0360>
ffffffffc02025b6:	fff7869b          	addiw	a3,a5,-1
ffffffffc02025ba:	00d92023          	sw	a3,0(s2)
        if (page_ref(page) ==
ffffffffc02025be:	c691                	beqz	a3,ffffffffc02025ca <page_insert+0xaa>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02025c0:	120a0073          	sfence.vma	s4
}
ffffffffc02025c4:	bf59                	j	ffffffffc020255a <page_insert+0x3a>
ffffffffc02025c6:	c014                	sw	a3,0(s0)
    return page->ref;
ffffffffc02025c8:	bf49                	j	ffffffffc020255a <page_insert+0x3a>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02025ca:	100027f3          	csrr	a5,sstatus
ffffffffc02025ce:	8b89                	andi	a5,a5,2
ffffffffc02025d0:	ef91                	bnez	a5,ffffffffc02025ec <page_insert+0xcc>
        pmm_manager->free_pages(base, n);
ffffffffc02025d2:	000dd797          	auipc	a5,0xdd
ffffffffc02025d6:	68e7b783          	ld	a5,1678(a5) # ffffffffc02dfc60 <pmm_manager>
ffffffffc02025da:	739c                	ld	a5,32(a5)
ffffffffc02025dc:	4585                	li	a1,1
ffffffffc02025de:	854a                	mv	a0,s2
ffffffffc02025e0:	9782                	jalr	a5
    return page - pages + nbase;
ffffffffc02025e2:	000ab703          	ld	a4,0(s5)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02025e6:	120a0073          	sfence.vma	s4
ffffffffc02025ea:	bf85                	j	ffffffffc020255a <page_insert+0x3a>
        intr_disable();
ffffffffc02025ec:	bc2fe0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc02025f0:	000dd797          	auipc	a5,0xdd
ffffffffc02025f4:	6707b783          	ld	a5,1648(a5) # ffffffffc02dfc60 <pmm_manager>
ffffffffc02025f8:	739c                	ld	a5,32(a5)
ffffffffc02025fa:	4585                	li	a1,1
ffffffffc02025fc:	854a                	mv	a0,s2
ffffffffc02025fe:	9782                	jalr	a5
        intr_enable();
ffffffffc0202600:	ba8fe0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0202604:	000ab703          	ld	a4,0(s5)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202608:	120a0073          	sfence.vma	s4
ffffffffc020260c:	b7b9                	j	ffffffffc020255a <page_insert+0x3a>
        return -E_NO_MEM;
ffffffffc020260e:	5571                	li	a0,-4
ffffffffc0202610:	b79d                	j	ffffffffc0202576 <page_insert+0x56>
ffffffffc0202612:	f2eff0ef          	jal	ra,ffffffffc0201d40 <pa2page.part.0>

ffffffffc0202616 <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc0202616:	00005797          	auipc	a5,0x5
ffffffffc020261a:	ca278793          	addi	a5,a5,-862 # ffffffffc02072b8 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc020261e:	638c                	ld	a1,0(a5)
{
ffffffffc0202620:	7159                	addi	sp,sp,-112
ffffffffc0202622:	f85a                	sd	s6,48(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0202624:	00005517          	auipc	a0,0x5
ffffffffc0202628:	e3c50513          	addi	a0,a0,-452 # ffffffffc0207460 <default_pmm_manager+0x1a8>
    pmm_manager = &default_pmm_manager;
ffffffffc020262c:	000ddb17          	auipc	s6,0xdd
ffffffffc0202630:	634b0b13          	addi	s6,s6,1588 # ffffffffc02dfc60 <pmm_manager>
{
ffffffffc0202634:	f486                	sd	ra,104(sp)
ffffffffc0202636:	e8ca                	sd	s2,80(sp)
ffffffffc0202638:	e4ce                	sd	s3,72(sp)
ffffffffc020263a:	f0a2                	sd	s0,96(sp)
ffffffffc020263c:	eca6                	sd	s1,88(sp)
ffffffffc020263e:	e0d2                	sd	s4,64(sp)
ffffffffc0202640:	fc56                	sd	s5,56(sp)
ffffffffc0202642:	f45e                	sd	s7,40(sp)
ffffffffc0202644:	f062                	sd	s8,32(sp)
ffffffffc0202646:	ec66                	sd	s9,24(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc0202648:	00fb3023          	sd	a5,0(s6)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc020264c:	b4dfd0ef          	jal	ra,ffffffffc0200198 <cprintf>
    pmm_manager->init();
ffffffffc0202650:	000b3783          	ld	a5,0(s6)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0202654:	000dd997          	auipc	s3,0xdd
ffffffffc0202658:	61498993          	addi	s3,s3,1556 # ffffffffc02dfc68 <va_pa_offset>
    pmm_manager->init();
ffffffffc020265c:	679c                	ld	a5,8(a5)
ffffffffc020265e:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0202660:	57f5                	li	a5,-3
ffffffffc0202662:	07fa                	slli	a5,a5,0x1e
ffffffffc0202664:	00f9b023          	sd	a5,0(s3)
    uint64_t mem_begin = get_memory_base();
ffffffffc0202668:	b2cfe0ef          	jal	ra,ffffffffc0200994 <get_memory_base>
ffffffffc020266c:	892a                	mv	s2,a0
    uint64_t mem_size  = get_memory_size();
ffffffffc020266e:	b30fe0ef          	jal	ra,ffffffffc020099e <get_memory_size>
    if (mem_size == 0) {
ffffffffc0202672:	200505e3          	beqz	a0,ffffffffc020307c <pmm_init+0xa66>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc0202676:	84aa                	mv	s1,a0
    cprintf("physcial memory map:\n");
ffffffffc0202678:	00005517          	auipc	a0,0x5
ffffffffc020267c:	e2050513          	addi	a0,a0,-480 # ffffffffc0207498 <default_pmm_manager+0x1e0>
ffffffffc0202680:	b19fd0ef          	jal	ra,ffffffffc0200198 <cprintf>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc0202684:	00990433          	add	s0,s2,s1
    cprintf("  memory: 0x%08lx, [0x%08lx, 0x%08lx].\n", mem_size, mem_begin,
ffffffffc0202688:	fff40693          	addi	a3,s0,-1
ffffffffc020268c:	864a                	mv	a2,s2
ffffffffc020268e:	85a6                	mv	a1,s1
ffffffffc0202690:	00005517          	auipc	a0,0x5
ffffffffc0202694:	e2050513          	addi	a0,a0,-480 # ffffffffc02074b0 <default_pmm_manager+0x1f8>
ffffffffc0202698:	b01fd0ef          	jal	ra,ffffffffc0200198 <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc020269c:	c8000737          	lui	a4,0xc8000
ffffffffc02026a0:	87a2                	mv	a5,s0
ffffffffc02026a2:	54876163          	bltu	a4,s0,ffffffffc0202be4 <pmm_init+0x5ce>
ffffffffc02026a6:	757d                	lui	a0,0xfffff
ffffffffc02026a8:	000de617          	auipc	a2,0xde
ffffffffc02026ac:	5f760613          	addi	a2,a2,1527 # ffffffffc02e0c9f <end+0xfff>
ffffffffc02026b0:	8e69                	and	a2,a2,a0
ffffffffc02026b2:	000dd497          	auipc	s1,0xdd
ffffffffc02026b6:	59e48493          	addi	s1,s1,1438 # ffffffffc02dfc50 <npage>
ffffffffc02026ba:	00c7d513          	srli	a0,a5,0xc
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02026be:	000ddb97          	auipc	s7,0xdd
ffffffffc02026c2:	59ab8b93          	addi	s7,s7,1434 # ffffffffc02dfc58 <pages>
    npage = maxpa / PGSIZE;
ffffffffc02026c6:	e088                	sd	a0,0(s1)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02026c8:	00cbb023          	sd	a2,0(s7)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc02026cc:	000807b7          	lui	a5,0x80
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02026d0:	86b2                	mv	a3,a2
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc02026d2:	02f50863          	beq	a0,a5,ffffffffc0202702 <pmm_init+0xec>
ffffffffc02026d6:	4781                	li	a5,0
ffffffffc02026d8:	4585                	li	a1,1
ffffffffc02026da:	fff806b7          	lui	a3,0xfff80
        SetPageReserved(pages + i);
ffffffffc02026de:	00679513          	slli	a0,a5,0x6
ffffffffc02026e2:	9532                	add	a0,a0,a2
ffffffffc02026e4:	00850713          	addi	a4,a0,8 # fffffffffffff008 <end+0x3fd1f368>
ffffffffc02026e8:	40b7302f          	amoor.d	zero,a1,(a4)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc02026ec:	6088                	ld	a0,0(s1)
ffffffffc02026ee:	0785                	addi	a5,a5,1
        SetPageReserved(pages + i);
ffffffffc02026f0:	000bb603          	ld	a2,0(s7)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc02026f4:	00d50733          	add	a4,a0,a3
ffffffffc02026f8:	fee7e3e3          	bltu	a5,a4,ffffffffc02026de <pmm_init+0xc8>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02026fc:	071a                	slli	a4,a4,0x6
ffffffffc02026fe:	00e606b3          	add	a3,a2,a4
ffffffffc0202702:	c02007b7          	lui	a5,0xc0200
ffffffffc0202706:	2ef6ece3          	bltu	a3,a5,ffffffffc02031fe <pmm_init+0xbe8>
ffffffffc020270a:	0009b583          	ld	a1,0(s3)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc020270e:	77fd                	lui	a5,0xfffff
ffffffffc0202710:	8c7d                	and	s0,s0,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0202712:	8e8d                	sub	a3,a3,a1
    if (freemem < mem_end)
ffffffffc0202714:	5086eb63          	bltu	a3,s0,ffffffffc0202c2a <pmm_init+0x614>
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc0202718:	00005517          	auipc	a0,0x5
ffffffffc020271c:	dc050513          	addi	a0,a0,-576 # ffffffffc02074d8 <default_pmm_manager+0x220>
ffffffffc0202720:	a79fd0ef          	jal	ra,ffffffffc0200198 <cprintf>
    return page;
}

static void check_alloc_page(void)
{
    pmm_manager->check();
ffffffffc0202724:	000b3783          	ld	a5,0(s6)
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc0202728:	000dd917          	auipc	s2,0xdd
ffffffffc020272c:	52090913          	addi	s2,s2,1312 # ffffffffc02dfc48 <boot_pgdir_va>
    pmm_manager->check();
ffffffffc0202730:	7b9c                	ld	a5,48(a5)
ffffffffc0202732:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0202734:	00005517          	auipc	a0,0x5
ffffffffc0202738:	dbc50513          	addi	a0,a0,-580 # ffffffffc02074f0 <default_pmm_manager+0x238>
ffffffffc020273c:	a5dfd0ef          	jal	ra,ffffffffc0200198 <cprintf>
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc0202740:	0000a697          	auipc	a3,0xa
ffffffffc0202744:	8c068693          	addi	a3,a3,-1856 # ffffffffc020c000 <boot_page_table_sv39>
ffffffffc0202748:	00d93023          	sd	a3,0(s2)
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc020274c:	c02007b7          	lui	a5,0xc0200
ffffffffc0202750:	28f6ebe3          	bltu	a3,a5,ffffffffc02031e6 <pmm_init+0xbd0>
ffffffffc0202754:	0009b783          	ld	a5,0(s3)
ffffffffc0202758:	8e9d                	sub	a3,a3,a5
ffffffffc020275a:	000dd797          	auipc	a5,0xdd
ffffffffc020275e:	4ed7b323          	sd	a3,1254(a5) # ffffffffc02dfc40 <boot_pgdir_pa>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0202762:	100027f3          	csrr	a5,sstatus
ffffffffc0202766:	8b89                	andi	a5,a5,2
ffffffffc0202768:	4a079763          	bnez	a5,ffffffffc0202c16 <pmm_init+0x600>
        ret = pmm_manager->nr_free_pages();
ffffffffc020276c:	000b3783          	ld	a5,0(s6)
ffffffffc0202770:	779c                	ld	a5,40(a5)
ffffffffc0202772:	9782                	jalr	a5
ffffffffc0202774:	842a                	mv	s0,a0
    // so npage is always larger than KMEMSIZE / PGSIZE
    size_t nr_free_store;

    nr_free_store = nr_free_pages();

    assert(npage <= KERNTOP / PGSIZE);
ffffffffc0202776:	6098                	ld	a4,0(s1)
ffffffffc0202778:	c80007b7          	lui	a5,0xc8000
ffffffffc020277c:	83b1                	srli	a5,a5,0xc
ffffffffc020277e:	66e7e363          	bltu	a5,a4,ffffffffc0202de4 <pmm_init+0x7ce>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc0202782:	00093503          	ld	a0,0(s2)
ffffffffc0202786:	62050f63          	beqz	a0,ffffffffc0202dc4 <pmm_init+0x7ae>
ffffffffc020278a:	03451793          	slli	a5,a0,0x34
ffffffffc020278e:	62079b63          	bnez	a5,ffffffffc0202dc4 <pmm_init+0x7ae>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc0202792:	4601                	li	a2,0
ffffffffc0202794:	4581                	li	a1,0
ffffffffc0202796:	8c3ff0ef          	jal	ra,ffffffffc0202058 <get_page>
ffffffffc020279a:	60051563          	bnez	a0,ffffffffc0202da4 <pmm_init+0x78e>
ffffffffc020279e:	100027f3          	csrr	a5,sstatus
ffffffffc02027a2:	8b89                	andi	a5,a5,2
ffffffffc02027a4:	44079e63          	bnez	a5,ffffffffc0202c00 <pmm_init+0x5ea>
        page = pmm_manager->alloc_pages(n);
ffffffffc02027a8:	000b3783          	ld	a5,0(s6)
ffffffffc02027ac:	4505                	li	a0,1
ffffffffc02027ae:	6f9c                	ld	a5,24(a5)
ffffffffc02027b0:	9782                	jalr	a5
ffffffffc02027b2:	8a2a                	mv	s4,a0

    struct Page *p1, *p2;
    p1 = alloc_page();
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc02027b4:	00093503          	ld	a0,0(s2)
ffffffffc02027b8:	4681                	li	a3,0
ffffffffc02027ba:	4601                	li	a2,0
ffffffffc02027bc:	85d2                	mv	a1,s4
ffffffffc02027be:	d63ff0ef          	jal	ra,ffffffffc0202520 <page_insert>
ffffffffc02027c2:	26051ae3          	bnez	a0,ffffffffc0203236 <pmm_init+0xc20>

    pte_t *ptep;
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc02027c6:	00093503          	ld	a0,0(s2)
ffffffffc02027ca:	4601                	li	a2,0
ffffffffc02027cc:	4581                	li	a1,0
ffffffffc02027ce:	e62ff0ef          	jal	ra,ffffffffc0201e30 <get_pte>
ffffffffc02027d2:	240502e3          	beqz	a0,ffffffffc0203216 <pmm_init+0xc00>
    assert(pte2page(*ptep) == p1);
ffffffffc02027d6:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V))
ffffffffc02027d8:	0017f713          	andi	a4,a5,1
ffffffffc02027dc:	5a070263          	beqz	a4,ffffffffc0202d80 <pmm_init+0x76a>
    if (PPN(pa) >= npage)
ffffffffc02027e0:	6098                	ld	a4,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc02027e2:	078a                	slli	a5,a5,0x2
ffffffffc02027e4:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02027e6:	58e7fb63          	bgeu	a5,a4,ffffffffc0202d7c <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc02027ea:	000bb683          	ld	a3,0(s7)
ffffffffc02027ee:	fff80637          	lui	a2,0xfff80
ffffffffc02027f2:	97b2                	add	a5,a5,a2
ffffffffc02027f4:	079a                	slli	a5,a5,0x6
ffffffffc02027f6:	97b6                	add	a5,a5,a3
ffffffffc02027f8:	14fa17e3          	bne	s4,a5,ffffffffc0203146 <pmm_init+0xb30>
    assert(page_ref(p1) == 1);
ffffffffc02027fc:	000a2683          	lw	a3,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x9128>
ffffffffc0202800:	4785                	li	a5,1
ffffffffc0202802:	12f692e3          	bne	a3,a5,ffffffffc0203126 <pmm_init+0xb10>

    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc0202806:	00093503          	ld	a0,0(s2)
ffffffffc020280a:	77fd                	lui	a5,0xfffff
ffffffffc020280c:	6114                	ld	a3,0(a0)
ffffffffc020280e:	068a                	slli	a3,a3,0x2
ffffffffc0202810:	8efd                	and	a3,a3,a5
ffffffffc0202812:	00c6d613          	srli	a2,a3,0xc
ffffffffc0202816:	0ee67ce3          	bgeu	a2,a4,ffffffffc020310e <pmm_init+0xaf8>
ffffffffc020281a:	0009bc03          	ld	s8,0(s3)
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc020281e:	96e2                	add	a3,a3,s8
ffffffffc0202820:	0006ba83          	ld	s5,0(a3)
ffffffffc0202824:	0a8a                	slli	s5,s5,0x2
ffffffffc0202826:	00fafab3          	and	s5,s5,a5
ffffffffc020282a:	00cad793          	srli	a5,s5,0xc
ffffffffc020282e:	0ce7f3e3          	bgeu	a5,a4,ffffffffc02030f4 <pmm_init+0xade>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202832:	4601                	li	a2,0
ffffffffc0202834:	6585                	lui	a1,0x1
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202836:	9ae2                	add	s5,s5,s8
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202838:	df8ff0ef          	jal	ra,ffffffffc0201e30 <get_pte>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc020283c:	0aa1                	addi	s5,s5,8
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc020283e:	55551363          	bne	a0,s5,ffffffffc0202d84 <pmm_init+0x76e>
ffffffffc0202842:	100027f3          	csrr	a5,sstatus
ffffffffc0202846:	8b89                	andi	a5,a5,2
ffffffffc0202848:	3a079163          	bnez	a5,ffffffffc0202bea <pmm_init+0x5d4>
        page = pmm_manager->alloc_pages(n);
ffffffffc020284c:	000b3783          	ld	a5,0(s6)
ffffffffc0202850:	4505                	li	a0,1
ffffffffc0202852:	6f9c                	ld	a5,24(a5)
ffffffffc0202854:	9782                	jalr	a5
ffffffffc0202856:	8c2a                	mv	s8,a0

    p2 = alloc_page();
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc0202858:	00093503          	ld	a0,0(s2)
ffffffffc020285c:	46d1                	li	a3,20
ffffffffc020285e:	6605                	lui	a2,0x1
ffffffffc0202860:	85e2                	mv	a1,s8
ffffffffc0202862:	cbfff0ef          	jal	ra,ffffffffc0202520 <page_insert>
ffffffffc0202866:	060517e3          	bnez	a0,ffffffffc02030d4 <pmm_init+0xabe>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc020286a:	00093503          	ld	a0,0(s2)
ffffffffc020286e:	4601                	li	a2,0
ffffffffc0202870:	6585                	lui	a1,0x1
ffffffffc0202872:	dbeff0ef          	jal	ra,ffffffffc0201e30 <get_pte>
ffffffffc0202876:	02050fe3          	beqz	a0,ffffffffc02030b4 <pmm_init+0xa9e>
    assert(*ptep & PTE_U);
ffffffffc020287a:	611c                	ld	a5,0(a0)
ffffffffc020287c:	0107f713          	andi	a4,a5,16
ffffffffc0202880:	7c070e63          	beqz	a4,ffffffffc020305c <pmm_init+0xa46>
    assert(*ptep & PTE_W);
ffffffffc0202884:	8b91                	andi	a5,a5,4
ffffffffc0202886:	7a078b63          	beqz	a5,ffffffffc020303c <pmm_init+0xa26>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc020288a:	00093503          	ld	a0,0(s2)
ffffffffc020288e:	611c                	ld	a5,0(a0)
ffffffffc0202890:	8bc1                	andi	a5,a5,16
ffffffffc0202892:	78078563          	beqz	a5,ffffffffc020301c <pmm_init+0xa06>
    assert(page_ref(p2) == 1);
ffffffffc0202896:	000c2703          	lw	a4,0(s8)
ffffffffc020289a:	4785                	li	a5,1
ffffffffc020289c:	76f71063          	bne	a4,a5,ffffffffc0202ffc <pmm_init+0x9e6>

    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc02028a0:	4681                	li	a3,0
ffffffffc02028a2:	6605                	lui	a2,0x1
ffffffffc02028a4:	85d2                	mv	a1,s4
ffffffffc02028a6:	c7bff0ef          	jal	ra,ffffffffc0202520 <page_insert>
ffffffffc02028aa:	72051963          	bnez	a0,ffffffffc0202fdc <pmm_init+0x9c6>
    assert(page_ref(p1) == 2);
ffffffffc02028ae:	000a2703          	lw	a4,0(s4)
ffffffffc02028b2:	4789                	li	a5,2
ffffffffc02028b4:	70f71463          	bne	a4,a5,ffffffffc0202fbc <pmm_init+0x9a6>
    assert(page_ref(p2) == 0);
ffffffffc02028b8:	000c2783          	lw	a5,0(s8)
ffffffffc02028bc:	6e079063          	bnez	a5,ffffffffc0202f9c <pmm_init+0x986>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc02028c0:	00093503          	ld	a0,0(s2)
ffffffffc02028c4:	4601                	li	a2,0
ffffffffc02028c6:	6585                	lui	a1,0x1
ffffffffc02028c8:	d68ff0ef          	jal	ra,ffffffffc0201e30 <get_pte>
ffffffffc02028cc:	6a050863          	beqz	a0,ffffffffc0202f7c <pmm_init+0x966>
    assert(pte2page(*ptep) == p1);
ffffffffc02028d0:	6118                	ld	a4,0(a0)
    if (!(pte & PTE_V))
ffffffffc02028d2:	00177793          	andi	a5,a4,1
ffffffffc02028d6:	4a078563          	beqz	a5,ffffffffc0202d80 <pmm_init+0x76a>
    if (PPN(pa) >= npage)
ffffffffc02028da:	6094                	ld	a3,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc02028dc:	00271793          	slli	a5,a4,0x2
ffffffffc02028e0:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02028e2:	48d7fd63          	bgeu	a5,a3,ffffffffc0202d7c <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc02028e6:	000bb683          	ld	a3,0(s7)
ffffffffc02028ea:	fff80ab7          	lui	s5,0xfff80
ffffffffc02028ee:	97d6                	add	a5,a5,s5
ffffffffc02028f0:	079a                	slli	a5,a5,0x6
ffffffffc02028f2:	97b6                	add	a5,a5,a3
ffffffffc02028f4:	66fa1463          	bne	s4,a5,ffffffffc0202f5c <pmm_init+0x946>
    assert((*ptep & PTE_U) == 0);
ffffffffc02028f8:	8b41                	andi	a4,a4,16
ffffffffc02028fa:	64071163          	bnez	a4,ffffffffc0202f3c <pmm_init+0x926>

    page_remove(boot_pgdir_va, 0x0);
ffffffffc02028fe:	00093503          	ld	a0,0(s2)
ffffffffc0202902:	4581                	li	a1,0
ffffffffc0202904:	b81ff0ef          	jal	ra,ffffffffc0202484 <page_remove>
    assert(page_ref(p1) == 1);
ffffffffc0202908:	000a2c83          	lw	s9,0(s4)
ffffffffc020290c:	4785                	li	a5,1
ffffffffc020290e:	60fc9763          	bne	s9,a5,ffffffffc0202f1c <pmm_init+0x906>
    assert(page_ref(p2) == 0);
ffffffffc0202912:	000c2783          	lw	a5,0(s8)
ffffffffc0202916:	5e079363          	bnez	a5,ffffffffc0202efc <pmm_init+0x8e6>

    page_remove(boot_pgdir_va, PGSIZE);
ffffffffc020291a:	00093503          	ld	a0,0(s2)
ffffffffc020291e:	6585                	lui	a1,0x1
ffffffffc0202920:	b65ff0ef          	jal	ra,ffffffffc0202484 <page_remove>
    assert(page_ref(p1) == 0);
ffffffffc0202924:	000a2783          	lw	a5,0(s4)
ffffffffc0202928:	52079a63          	bnez	a5,ffffffffc0202e5c <pmm_init+0x846>
    assert(page_ref(p2) == 0);
ffffffffc020292c:	000c2783          	lw	a5,0(s8)
ffffffffc0202930:	50079663          	bnez	a5,ffffffffc0202e3c <pmm_init+0x826>

    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc0202934:	00093a03          	ld	s4,0(s2)
    if (PPN(pa) >= npage)
ffffffffc0202938:	608c                	ld	a1,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc020293a:	000a3683          	ld	a3,0(s4)
ffffffffc020293e:	068a                	slli	a3,a3,0x2
ffffffffc0202940:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage)
ffffffffc0202942:	42b6fd63          	bgeu	a3,a1,ffffffffc0202d7c <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202946:	000bb503          	ld	a0,0(s7)
ffffffffc020294a:	96d6                	add	a3,a3,s5
ffffffffc020294c:	069a                	slli	a3,a3,0x6
    return page->ref;
ffffffffc020294e:	00d507b3          	add	a5,a0,a3
ffffffffc0202952:	439c                	lw	a5,0(a5)
ffffffffc0202954:	4d979463          	bne	a5,s9,ffffffffc0202e1c <pmm_init+0x806>
    return page - pages + nbase;
ffffffffc0202958:	8699                	srai	a3,a3,0x6
ffffffffc020295a:	00080637          	lui	a2,0x80
ffffffffc020295e:	96b2                	add	a3,a3,a2
    return KADDR(page2pa(page));
ffffffffc0202960:	00c69713          	slli	a4,a3,0xc
ffffffffc0202964:	8331                	srli	a4,a4,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0202966:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202968:	48b77e63          	bgeu	a4,a1,ffffffffc0202e04 <pmm_init+0x7ee>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
    free_page(pde2page(pd0[0]));
ffffffffc020296c:	0009b703          	ld	a4,0(s3)
ffffffffc0202970:	96ba                	add	a3,a3,a4
    return pa2page(PDE_ADDR(pde));
ffffffffc0202972:	629c                	ld	a5,0(a3)
ffffffffc0202974:	078a                	slli	a5,a5,0x2
ffffffffc0202976:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202978:	40b7f263          	bgeu	a5,a1,ffffffffc0202d7c <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc020297c:	8f91                	sub	a5,a5,a2
ffffffffc020297e:	079a                	slli	a5,a5,0x6
ffffffffc0202980:	953e                	add	a0,a0,a5
ffffffffc0202982:	100027f3          	csrr	a5,sstatus
ffffffffc0202986:	8b89                	andi	a5,a5,2
ffffffffc0202988:	30079963          	bnez	a5,ffffffffc0202c9a <pmm_init+0x684>
        pmm_manager->free_pages(base, n);
ffffffffc020298c:	000b3783          	ld	a5,0(s6)
ffffffffc0202990:	4585                	li	a1,1
ffffffffc0202992:	739c                	ld	a5,32(a5)
ffffffffc0202994:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202996:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage)
ffffffffc020299a:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc020299c:	078a                	slli	a5,a5,0x2
ffffffffc020299e:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02029a0:	3ce7fe63          	bgeu	a5,a4,ffffffffc0202d7c <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc02029a4:	000bb503          	ld	a0,0(s7)
ffffffffc02029a8:	fff80737          	lui	a4,0xfff80
ffffffffc02029ac:	97ba                	add	a5,a5,a4
ffffffffc02029ae:	079a                	slli	a5,a5,0x6
ffffffffc02029b0:	953e                	add	a0,a0,a5
ffffffffc02029b2:	100027f3          	csrr	a5,sstatus
ffffffffc02029b6:	8b89                	andi	a5,a5,2
ffffffffc02029b8:	2c079563          	bnez	a5,ffffffffc0202c82 <pmm_init+0x66c>
ffffffffc02029bc:	000b3783          	ld	a5,0(s6)
ffffffffc02029c0:	4585                	li	a1,1
ffffffffc02029c2:	739c                	ld	a5,32(a5)
ffffffffc02029c4:	9782                	jalr	a5
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc02029c6:	00093783          	ld	a5,0(s2)
ffffffffc02029ca:	0007b023          	sd	zero,0(a5) # fffffffffffff000 <end+0x3fd1f360>
    asm volatile("sfence.vma");
ffffffffc02029ce:	12000073          	sfence.vma
ffffffffc02029d2:	100027f3          	csrr	a5,sstatus
ffffffffc02029d6:	8b89                	andi	a5,a5,2
ffffffffc02029d8:	28079b63          	bnez	a5,ffffffffc0202c6e <pmm_init+0x658>
        ret = pmm_manager->nr_free_pages();
ffffffffc02029dc:	000b3783          	ld	a5,0(s6)
ffffffffc02029e0:	779c                	ld	a5,40(a5)
ffffffffc02029e2:	9782                	jalr	a5
ffffffffc02029e4:	8a2a                	mv	s4,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc02029e6:	4b441b63          	bne	s0,s4,ffffffffc0202e9c <pmm_init+0x886>

    cprintf("check_pgdir() succeeded!\n");
ffffffffc02029ea:	00005517          	auipc	a0,0x5
ffffffffc02029ee:	e2e50513          	addi	a0,a0,-466 # ffffffffc0207818 <default_pmm_manager+0x560>
ffffffffc02029f2:	fa6fd0ef          	jal	ra,ffffffffc0200198 <cprintf>
ffffffffc02029f6:	100027f3          	csrr	a5,sstatus
ffffffffc02029fa:	8b89                	andi	a5,a5,2
ffffffffc02029fc:	24079f63          	bnez	a5,ffffffffc0202c5a <pmm_init+0x644>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202a00:	000b3783          	ld	a5,0(s6)
ffffffffc0202a04:	779c                	ld	a5,40(a5)
ffffffffc0202a06:	9782                	jalr	a5
ffffffffc0202a08:	8c2a                	mv	s8,a0
    pte_t *ptep;
    int i;

    nr_free_store = nr_free_pages();

    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202a0a:	6098                	ld	a4,0(s1)
ffffffffc0202a0c:	c0200437          	lui	s0,0xc0200
    {
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202a10:	7afd                	lui	s5,0xfffff
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202a12:	00c71793          	slli	a5,a4,0xc
ffffffffc0202a16:	6a05                	lui	s4,0x1
ffffffffc0202a18:	02f47c63          	bgeu	s0,a5,ffffffffc0202a50 <pmm_init+0x43a>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202a1c:	00c45793          	srli	a5,s0,0xc
ffffffffc0202a20:	00093503          	ld	a0,0(s2)
ffffffffc0202a24:	2ee7ff63          	bgeu	a5,a4,ffffffffc0202d22 <pmm_init+0x70c>
ffffffffc0202a28:	0009b583          	ld	a1,0(s3)
ffffffffc0202a2c:	4601                	li	a2,0
ffffffffc0202a2e:	95a2                	add	a1,a1,s0
ffffffffc0202a30:	c00ff0ef          	jal	ra,ffffffffc0201e30 <get_pte>
ffffffffc0202a34:	32050463          	beqz	a0,ffffffffc0202d5c <pmm_init+0x746>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202a38:	611c                	ld	a5,0(a0)
ffffffffc0202a3a:	078a                	slli	a5,a5,0x2
ffffffffc0202a3c:	0157f7b3          	and	a5,a5,s5
ffffffffc0202a40:	2e879e63          	bne	a5,s0,ffffffffc0202d3c <pmm_init+0x726>
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202a44:	6098                	ld	a4,0(s1)
ffffffffc0202a46:	9452                	add	s0,s0,s4
ffffffffc0202a48:	00c71793          	slli	a5,a4,0xc
ffffffffc0202a4c:	fcf468e3          	bltu	s0,a5,ffffffffc0202a1c <pmm_init+0x406>
    }

    assert(boot_pgdir_va[0] == 0);
ffffffffc0202a50:	00093783          	ld	a5,0(s2)
ffffffffc0202a54:	639c                	ld	a5,0(a5)
ffffffffc0202a56:	42079363          	bnez	a5,ffffffffc0202e7c <pmm_init+0x866>
ffffffffc0202a5a:	100027f3          	csrr	a5,sstatus
ffffffffc0202a5e:	8b89                	andi	a5,a5,2
ffffffffc0202a60:	24079963          	bnez	a5,ffffffffc0202cb2 <pmm_init+0x69c>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202a64:	000b3783          	ld	a5,0(s6)
ffffffffc0202a68:	4505                	li	a0,1
ffffffffc0202a6a:	6f9c                	ld	a5,24(a5)
ffffffffc0202a6c:	9782                	jalr	a5
ffffffffc0202a6e:	8a2a                	mv	s4,a0

    struct Page *p;
    p = alloc_page();
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0202a70:	00093503          	ld	a0,0(s2)
ffffffffc0202a74:	4699                	li	a3,6
ffffffffc0202a76:	10000613          	li	a2,256
ffffffffc0202a7a:	85d2                	mv	a1,s4
ffffffffc0202a7c:	aa5ff0ef          	jal	ra,ffffffffc0202520 <page_insert>
ffffffffc0202a80:	44051e63          	bnez	a0,ffffffffc0202edc <pmm_init+0x8c6>
    assert(page_ref(p) == 1);
ffffffffc0202a84:	000a2703          	lw	a4,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x9128>
ffffffffc0202a88:	4785                	li	a5,1
ffffffffc0202a8a:	42f71963          	bne	a4,a5,ffffffffc0202ebc <pmm_init+0x8a6>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc0202a8e:	00093503          	ld	a0,0(s2)
ffffffffc0202a92:	6405                	lui	s0,0x1
ffffffffc0202a94:	4699                	li	a3,6
ffffffffc0202a96:	10040613          	addi	a2,s0,256 # 1100 <_binary_obj___user_faultread_out_size-0x9028>
ffffffffc0202a9a:	85d2                	mv	a1,s4
ffffffffc0202a9c:	a85ff0ef          	jal	ra,ffffffffc0202520 <page_insert>
ffffffffc0202aa0:	72051363          	bnez	a0,ffffffffc02031c6 <pmm_init+0xbb0>
    assert(page_ref(p) == 2);
ffffffffc0202aa4:	000a2703          	lw	a4,0(s4)
ffffffffc0202aa8:	4789                	li	a5,2
ffffffffc0202aaa:	6ef71e63          	bne	a4,a5,ffffffffc02031a6 <pmm_init+0xb90>

    const char *str = "ucore: Hello world!!";
    strcpy((void *)0x100, str);
ffffffffc0202aae:	00005597          	auipc	a1,0x5
ffffffffc0202ab2:	eb258593          	addi	a1,a1,-334 # ffffffffc0207960 <default_pmm_manager+0x6a8>
ffffffffc0202ab6:	10000513          	li	a0,256
ffffffffc0202aba:	133030ef          	jal	ra,ffffffffc02063ec <strcpy>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc0202abe:	10040593          	addi	a1,s0,256
ffffffffc0202ac2:	10000513          	li	a0,256
ffffffffc0202ac6:	139030ef          	jal	ra,ffffffffc02063fe <strcmp>
ffffffffc0202aca:	6a051e63          	bnez	a0,ffffffffc0203186 <pmm_init+0xb70>
    return page - pages + nbase;
ffffffffc0202ace:	000bb683          	ld	a3,0(s7)
ffffffffc0202ad2:	00080737          	lui	a4,0x80
    return KADDR(page2pa(page));
ffffffffc0202ad6:	547d                	li	s0,-1
    return page - pages + nbase;
ffffffffc0202ad8:	40da06b3          	sub	a3,s4,a3
ffffffffc0202adc:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0202ade:	609c                	ld	a5,0(s1)
    return page - pages + nbase;
ffffffffc0202ae0:	96ba                	add	a3,a3,a4
    return KADDR(page2pa(page));
ffffffffc0202ae2:	8031                	srli	s0,s0,0xc
ffffffffc0202ae4:	0086f733          	and	a4,a3,s0
    return page2ppn(page) << PGSHIFT;
ffffffffc0202ae8:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202aea:	30f77d63          	bgeu	a4,a5,ffffffffc0202e04 <pmm_init+0x7ee>

    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0202aee:	0009b783          	ld	a5,0(s3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202af2:	10000513          	li	a0,256
    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0202af6:	96be                	add	a3,a3,a5
ffffffffc0202af8:	10068023          	sb	zero,256(a3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202afc:	0bb030ef          	jal	ra,ffffffffc02063b6 <strlen>
ffffffffc0202b00:	66051363          	bnez	a0,ffffffffc0203166 <pmm_init+0xb50>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
ffffffffc0202b04:	00093a83          	ld	s5,0(s2)
    if (PPN(pa) >= npage)
ffffffffc0202b08:	609c                	ld	a5,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202b0a:	000ab683          	ld	a3,0(s5) # fffffffffffff000 <end+0x3fd1f360>
ffffffffc0202b0e:	068a                	slli	a3,a3,0x2
ffffffffc0202b10:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage)
ffffffffc0202b12:	26f6f563          	bgeu	a3,a5,ffffffffc0202d7c <pmm_init+0x766>
    return KADDR(page2pa(page));
ffffffffc0202b16:	8c75                	and	s0,s0,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc0202b18:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202b1a:	2ef47563          	bgeu	s0,a5,ffffffffc0202e04 <pmm_init+0x7ee>
ffffffffc0202b1e:	0009b403          	ld	s0,0(s3)
ffffffffc0202b22:	9436                	add	s0,s0,a3
ffffffffc0202b24:	100027f3          	csrr	a5,sstatus
ffffffffc0202b28:	8b89                	andi	a5,a5,2
ffffffffc0202b2a:	1e079163          	bnez	a5,ffffffffc0202d0c <pmm_init+0x6f6>
        pmm_manager->free_pages(base, n);
ffffffffc0202b2e:	000b3783          	ld	a5,0(s6)
ffffffffc0202b32:	4585                	li	a1,1
ffffffffc0202b34:	8552                	mv	a0,s4
ffffffffc0202b36:	739c                	ld	a5,32(a5)
ffffffffc0202b38:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202b3a:	601c                	ld	a5,0(s0)
    if (PPN(pa) >= npage)
ffffffffc0202b3c:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202b3e:	078a                	slli	a5,a5,0x2
ffffffffc0202b40:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202b42:	22e7fd63          	bgeu	a5,a4,ffffffffc0202d7c <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202b46:	000bb503          	ld	a0,0(s7)
ffffffffc0202b4a:	fff80737          	lui	a4,0xfff80
ffffffffc0202b4e:	97ba                	add	a5,a5,a4
ffffffffc0202b50:	079a                	slli	a5,a5,0x6
ffffffffc0202b52:	953e                	add	a0,a0,a5
ffffffffc0202b54:	100027f3          	csrr	a5,sstatus
ffffffffc0202b58:	8b89                	andi	a5,a5,2
ffffffffc0202b5a:	18079d63          	bnez	a5,ffffffffc0202cf4 <pmm_init+0x6de>
ffffffffc0202b5e:	000b3783          	ld	a5,0(s6)
ffffffffc0202b62:	4585                	li	a1,1
ffffffffc0202b64:	739c                	ld	a5,32(a5)
ffffffffc0202b66:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202b68:	000ab783          	ld	a5,0(s5)
    if (PPN(pa) >= npage)
ffffffffc0202b6c:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202b6e:	078a                	slli	a5,a5,0x2
ffffffffc0202b70:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202b72:	20e7f563          	bgeu	a5,a4,ffffffffc0202d7c <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202b76:	000bb503          	ld	a0,0(s7)
ffffffffc0202b7a:	fff80737          	lui	a4,0xfff80
ffffffffc0202b7e:	97ba                	add	a5,a5,a4
ffffffffc0202b80:	079a                	slli	a5,a5,0x6
ffffffffc0202b82:	953e                	add	a0,a0,a5
ffffffffc0202b84:	100027f3          	csrr	a5,sstatus
ffffffffc0202b88:	8b89                	andi	a5,a5,2
ffffffffc0202b8a:	14079963          	bnez	a5,ffffffffc0202cdc <pmm_init+0x6c6>
ffffffffc0202b8e:	000b3783          	ld	a5,0(s6)
ffffffffc0202b92:	4585                	li	a1,1
ffffffffc0202b94:	739c                	ld	a5,32(a5)
ffffffffc0202b96:	9782                	jalr	a5
    free_page(p);
    free_page(pde2page(pd0[0]));
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc0202b98:	00093783          	ld	a5,0(s2)
ffffffffc0202b9c:	0007b023          	sd	zero,0(a5)
    asm volatile("sfence.vma");
ffffffffc0202ba0:	12000073          	sfence.vma
ffffffffc0202ba4:	100027f3          	csrr	a5,sstatus
ffffffffc0202ba8:	8b89                	andi	a5,a5,2
ffffffffc0202baa:	10079f63          	bnez	a5,ffffffffc0202cc8 <pmm_init+0x6b2>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202bae:	000b3783          	ld	a5,0(s6)
ffffffffc0202bb2:	779c                	ld	a5,40(a5)
ffffffffc0202bb4:	9782                	jalr	a5
ffffffffc0202bb6:	842a                	mv	s0,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc0202bb8:	4c8c1e63          	bne	s8,s0,ffffffffc0203094 <pmm_init+0xa7e>

    cprintf("check_boot_pgdir() succeeded!\n");
ffffffffc0202bbc:	00005517          	auipc	a0,0x5
ffffffffc0202bc0:	e1c50513          	addi	a0,a0,-484 # ffffffffc02079d8 <default_pmm_manager+0x720>
ffffffffc0202bc4:	dd4fd0ef          	jal	ra,ffffffffc0200198 <cprintf>
}
ffffffffc0202bc8:	7406                	ld	s0,96(sp)
ffffffffc0202bca:	70a6                	ld	ra,104(sp)
ffffffffc0202bcc:	64e6                	ld	s1,88(sp)
ffffffffc0202bce:	6946                	ld	s2,80(sp)
ffffffffc0202bd0:	69a6                	ld	s3,72(sp)
ffffffffc0202bd2:	6a06                	ld	s4,64(sp)
ffffffffc0202bd4:	7ae2                	ld	s5,56(sp)
ffffffffc0202bd6:	7b42                	ld	s6,48(sp)
ffffffffc0202bd8:	7ba2                	ld	s7,40(sp)
ffffffffc0202bda:	7c02                	ld	s8,32(sp)
ffffffffc0202bdc:	6ce2                	ld	s9,24(sp)
ffffffffc0202bde:	6165                	addi	sp,sp,112
    kmalloc_init();
ffffffffc0202be0:	f97fe06f          	j	ffffffffc0201b76 <kmalloc_init>
    npage = maxpa / PGSIZE;
ffffffffc0202be4:	c80007b7          	lui	a5,0xc8000
ffffffffc0202be8:	bc7d                	j	ffffffffc02026a6 <pmm_init+0x90>
        intr_disable();
ffffffffc0202bea:	dc5fd0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202bee:	000b3783          	ld	a5,0(s6)
ffffffffc0202bf2:	4505                	li	a0,1
ffffffffc0202bf4:	6f9c                	ld	a5,24(a5)
ffffffffc0202bf6:	9782                	jalr	a5
ffffffffc0202bf8:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc0202bfa:	daffd0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0202bfe:	b9a9                	j	ffffffffc0202858 <pmm_init+0x242>
        intr_disable();
ffffffffc0202c00:	daffd0ef          	jal	ra,ffffffffc02009ae <intr_disable>
ffffffffc0202c04:	000b3783          	ld	a5,0(s6)
ffffffffc0202c08:	4505                	li	a0,1
ffffffffc0202c0a:	6f9c                	ld	a5,24(a5)
ffffffffc0202c0c:	9782                	jalr	a5
ffffffffc0202c0e:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202c10:	d99fd0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0202c14:	b645                	j	ffffffffc02027b4 <pmm_init+0x19e>
        intr_disable();
ffffffffc0202c16:	d99fd0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202c1a:	000b3783          	ld	a5,0(s6)
ffffffffc0202c1e:	779c                	ld	a5,40(a5)
ffffffffc0202c20:	9782                	jalr	a5
ffffffffc0202c22:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202c24:	d85fd0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0202c28:	b6b9                	j	ffffffffc0202776 <pmm_init+0x160>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0202c2a:	6705                	lui	a4,0x1
ffffffffc0202c2c:	177d                	addi	a4,a4,-1
ffffffffc0202c2e:	96ba                	add	a3,a3,a4
ffffffffc0202c30:	8ff5                	and	a5,a5,a3
    if (PPN(pa) >= npage)
ffffffffc0202c32:	00c7d713          	srli	a4,a5,0xc
ffffffffc0202c36:	14a77363          	bgeu	a4,a0,ffffffffc0202d7c <pmm_init+0x766>
    pmm_manager->init_memmap(base, n);
ffffffffc0202c3a:	000b3683          	ld	a3,0(s6)
    return &pages[PPN(pa) - nbase];
ffffffffc0202c3e:	fff80537          	lui	a0,0xfff80
ffffffffc0202c42:	972a                	add	a4,a4,a0
ffffffffc0202c44:	6a94                	ld	a3,16(a3)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0202c46:	8c1d                	sub	s0,s0,a5
ffffffffc0202c48:	00671513          	slli	a0,a4,0x6
    pmm_manager->init_memmap(base, n);
ffffffffc0202c4c:	00c45593          	srli	a1,s0,0xc
ffffffffc0202c50:	9532                	add	a0,a0,a2
ffffffffc0202c52:	9682                	jalr	a3
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc0202c54:	0009b583          	ld	a1,0(s3)
}
ffffffffc0202c58:	b4c1                	j	ffffffffc0202718 <pmm_init+0x102>
        intr_disable();
ffffffffc0202c5a:	d55fd0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202c5e:	000b3783          	ld	a5,0(s6)
ffffffffc0202c62:	779c                	ld	a5,40(a5)
ffffffffc0202c64:	9782                	jalr	a5
ffffffffc0202c66:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc0202c68:	d41fd0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0202c6c:	bb79                	j	ffffffffc0202a0a <pmm_init+0x3f4>
        intr_disable();
ffffffffc0202c6e:	d41fd0ef          	jal	ra,ffffffffc02009ae <intr_disable>
ffffffffc0202c72:	000b3783          	ld	a5,0(s6)
ffffffffc0202c76:	779c                	ld	a5,40(a5)
ffffffffc0202c78:	9782                	jalr	a5
ffffffffc0202c7a:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202c7c:	d2dfd0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0202c80:	b39d                	j	ffffffffc02029e6 <pmm_init+0x3d0>
ffffffffc0202c82:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202c84:	d2bfd0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202c88:	000b3783          	ld	a5,0(s6)
ffffffffc0202c8c:	6522                	ld	a0,8(sp)
ffffffffc0202c8e:	4585                	li	a1,1
ffffffffc0202c90:	739c                	ld	a5,32(a5)
ffffffffc0202c92:	9782                	jalr	a5
        intr_enable();
ffffffffc0202c94:	d15fd0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0202c98:	b33d                	j	ffffffffc02029c6 <pmm_init+0x3b0>
ffffffffc0202c9a:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202c9c:	d13fd0ef          	jal	ra,ffffffffc02009ae <intr_disable>
ffffffffc0202ca0:	000b3783          	ld	a5,0(s6)
ffffffffc0202ca4:	6522                	ld	a0,8(sp)
ffffffffc0202ca6:	4585                	li	a1,1
ffffffffc0202ca8:	739c                	ld	a5,32(a5)
ffffffffc0202caa:	9782                	jalr	a5
        intr_enable();
ffffffffc0202cac:	cfdfd0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0202cb0:	b1dd                	j	ffffffffc0202996 <pmm_init+0x380>
        intr_disable();
ffffffffc0202cb2:	cfdfd0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202cb6:	000b3783          	ld	a5,0(s6)
ffffffffc0202cba:	4505                	li	a0,1
ffffffffc0202cbc:	6f9c                	ld	a5,24(a5)
ffffffffc0202cbe:	9782                	jalr	a5
ffffffffc0202cc0:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202cc2:	ce7fd0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0202cc6:	b36d                	j	ffffffffc0202a70 <pmm_init+0x45a>
        intr_disable();
ffffffffc0202cc8:	ce7fd0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202ccc:	000b3783          	ld	a5,0(s6)
ffffffffc0202cd0:	779c                	ld	a5,40(a5)
ffffffffc0202cd2:	9782                	jalr	a5
ffffffffc0202cd4:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202cd6:	cd3fd0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0202cda:	bdf9                	j	ffffffffc0202bb8 <pmm_init+0x5a2>
ffffffffc0202cdc:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202cde:	cd1fd0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202ce2:	000b3783          	ld	a5,0(s6)
ffffffffc0202ce6:	6522                	ld	a0,8(sp)
ffffffffc0202ce8:	4585                	li	a1,1
ffffffffc0202cea:	739c                	ld	a5,32(a5)
ffffffffc0202cec:	9782                	jalr	a5
        intr_enable();
ffffffffc0202cee:	cbbfd0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0202cf2:	b55d                	j	ffffffffc0202b98 <pmm_init+0x582>
ffffffffc0202cf4:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202cf6:	cb9fd0ef          	jal	ra,ffffffffc02009ae <intr_disable>
ffffffffc0202cfa:	000b3783          	ld	a5,0(s6)
ffffffffc0202cfe:	6522                	ld	a0,8(sp)
ffffffffc0202d00:	4585                	li	a1,1
ffffffffc0202d02:	739c                	ld	a5,32(a5)
ffffffffc0202d04:	9782                	jalr	a5
        intr_enable();
ffffffffc0202d06:	ca3fd0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0202d0a:	bdb9                	j	ffffffffc0202b68 <pmm_init+0x552>
        intr_disable();
ffffffffc0202d0c:	ca3fd0ef          	jal	ra,ffffffffc02009ae <intr_disable>
ffffffffc0202d10:	000b3783          	ld	a5,0(s6)
ffffffffc0202d14:	4585                	li	a1,1
ffffffffc0202d16:	8552                	mv	a0,s4
ffffffffc0202d18:	739c                	ld	a5,32(a5)
ffffffffc0202d1a:	9782                	jalr	a5
        intr_enable();
ffffffffc0202d1c:	c8dfd0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0202d20:	bd29                	j	ffffffffc0202b3a <pmm_init+0x524>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202d22:	86a2                	mv	a3,s0
ffffffffc0202d24:	00004617          	auipc	a2,0x4
ffffffffc0202d28:	5cc60613          	addi	a2,a2,1484 # ffffffffc02072f0 <default_pmm_manager+0x38>
ffffffffc0202d2c:	23a00593          	li	a1,570
ffffffffc0202d30:	00004517          	auipc	a0,0x4
ffffffffc0202d34:	6d850513          	addi	a0,a0,1752 # ffffffffc0207408 <default_pmm_manager+0x150>
ffffffffc0202d38:	f5afd0ef          	jal	ra,ffffffffc0200492 <__panic>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202d3c:	00005697          	auipc	a3,0x5
ffffffffc0202d40:	b3c68693          	addi	a3,a3,-1220 # ffffffffc0207878 <default_pmm_manager+0x5c0>
ffffffffc0202d44:	00004617          	auipc	a2,0x4
ffffffffc0202d48:	1c460613          	addi	a2,a2,452 # ffffffffc0206f08 <commands+0x818>
ffffffffc0202d4c:	23b00593          	li	a1,571
ffffffffc0202d50:	00004517          	auipc	a0,0x4
ffffffffc0202d54:	6b850513          	addi	a0,a0,1720 # ffffffffc0207408 <default_pmm_manager+0x150>
ffffffffc0202d58:	f3afd0ef          	jal	ra,ffffffffc0200492 <__panic>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202d5c:	00005697          	auipc	a3,0x5
ffffffffc0202d60:	adc68693          	addi	a3,a3,-1316 # ffffffffc0207838 <default_pmm_manager+0x580>
ffffffffc0202d64:	00004617          	auipc	a2,0x4
ffffffffc0202d68:	1a460613          	addi	a2,a2,420 # ffffffffc0206f08 <commands+0x818>
ffffffffc0202d6c:	23a00593          	li	a1,570
ffffffffc0202d70:	00004517          	auipc	a0,0x4
ffffffffc0202d74:	69850513          	addi	a0,a0,1688 # ffffffffc0207408 <default_pmm_manager+0x150>
ffffffffc0202d78:	f1afd0ef          	jal	ra,ffffffffc0200492 <__panic>
ffffffffc0202d7c:	fc5fe0ef          	jal	ra,ffffffffc0201d40 <pa2page.part.0>
ffffffffc0202d80:	fddfe0ef          	jal	ra,ffffffffc0201d5c <pte2page.part.0>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202d84:	00005697          	auipc	a3,0x5
ffffffffc0202d88:	8ac68693          	addi	a3,a3,-1876 # ffffffffc0207630 <default_pmm_manager+0x378>
ffffffffc0202d8c:	00004617          	auipc	a2,0x4
ffffffffc0202d90:	17c60613          	addi	a2,a2,380 # ffffffffc0206f08 <commands+0x818>
ffffffffc0202d94:	20a00593          	li	a1,522
ffffffffc0202d98:	00004517          	auipc	a0,0x4
ffffffffc0202d9c:	67050513          	addi	a0,a0,1648 # ffffffffc0207408 <default_pmm_manager+0x150>
ffffffffc0202da0:	ef2fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc0202da4:	00004697          	auipc	a3,0x4
ffffffffc0202da8:	7cc68693          	addi	a3,a3,1996 # ffffffffc0207570 <default_pmm_manager+0x2b8>
ffffffffc0202dac:	00004617          	auipc	a2,0x4
ffffffffc0202db0:	15c60613          	addi	a2,a2,348 # ffffffffc0206f08 <commands+0x818>
ffffffffc0202db4:	1fd00593          	li	a1,509
ffffffffc0202db8:	00004517          	auipc	a0,0x4
ffffffffc0202dbc:	65050513          	addi	a0,a0,1616 # ffffffffc0207408 <default_pmm_manager+0x150>
ffffffffc0202dc0:	ed2fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc0202dc4:	00004697          	auipc	a3,0x4
ffffffffc0202dc8:	76c68693          	addi	a3,a3,1900 # ffffffffc0207530 <default_pmm_manager+0x278>
ffffffffc0202dcc:	00004617          	auipc	a2,0x4
ffffffffc0202dd0:	13c60613          	addi	a2,a2,316 # ffffffffc0206f08 <commands+0x818>
ffffffffc0202dd4:	1fc00593          	li	a1,508
ffffffffc0202dd8:	00004517          	auipc	a0,0x4
ffffffffc0202ddc:	63050513          	addi	a0,a0,1584 # ffffffffc0207408 <default_pmm_manager+0x150>
ffffffffc0202de0:	eb2fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(npage <= KERNTOP / PGSIZE);
ffffffffc0202de4:	00004697          	auipc	a3,0x4
ffffffffc0202de8:	72c68693          	addi	a3,a3,1836 # ffffffffc0207510 <default_pmm_manager+0x258>
ffffffffc0202dec:	00004617          	auipc	a2,0x4
ffffffffc0202df0:	11c60613          	addi	a2,a2,284 # ffffffffc0206f08 <commands+0x818>
ffffffffc0202df4:	1fb00593          	li	a1,507
ffffffffc0202df8:	00004517          	auipc	a0,0x4
ffffffffc0202dfc:	61050513          	addi	a0,a0,1552 # ffffffffc0207408 <default_pmm_manager+0x150>
ffffffffc0202e00:	e92fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    return KADDR(page2pa(page));
ffffffffc0202e04:	00004617          	auipc	a2,0x4
ffffffffc0202e08:	4ec60613          	addi	a2,a2,1260 # ffffffffc02072f0 <default_pmm_manager+0x38>
ffffffffc0202e0c:	07100593          	li	a1,113
ffffffffc0202e10:	00004517          	auipc	a0,0x4
ffffffffc0202e14:	50850513          	addi	a0,a0,1288 # ffffffffc0207318 <default_pmm_manager+0x60>
ffffffffc0202e18:	e7afd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc0202e1c:	00005697          	auipc	a3,0x5
ffffffffc0202e20:	9a468693          	addi	a3,a3,-1628 # ffffffffc02077c0 <default_pmm_manager+0x508>
ffffffffc0202e24:	00004617          	auipc	a2,0x4
ffffffffc0202e28:	0e460613          	addi	a2,a2,228 # ffffffffc0206f08 <commands+0x818>
ffffffffc0202e2c:	22300593          	li	a1,547
ffffffffc0202e30:	00004517          	auipc	a0,0x4
ffffffffc0202e34:	5d850513          	addi	a0,a0,1496 # ffffffffc0207408 <default_pmm_manager+0x150>
ffffffffc0202e38:	e5afd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0202e3c:	00005697          	auipc	a3,0x5
ffffffffc0202e40:	93c68693          	addi	a3,a3,-1732 # ffffffffc0207778 <default_pmm_manager+0x4c0>
ffffffffc0202e44:	00004617          	auipc	a2,0x4
ffffffffc0202e48:	0c460613          	addi	a2,a2,196 # ffffffffc0206f08 <commands+0x818>
ffffffffc0202e4c:	22100593          	li	a1,545
ffffffffc0202e50:	00004517          	auipc	a0,0x4
ffffffffc0202e54:	5b850513          	addi	a0,a0,1464 # ffffffffc0207408 <default_pmm_manager+0x150>
ffffffffc0202e58:	e3afd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_ref(p1) == 0);
ffffffffc0202e5c:	00005697          	auipc	a3,0x5
ffffffffc0202e60:	94c68693          	addi	a3,a3,-1716 # ffffffffc02077a8 <default_pmm_manager+0x4f0>
ffffffffc0202e64:	00004617          	auipc	a2,0x4
ffffffffc0202e68:	0a460613          	addi	a2,a2,164 # ffffffffc0206f08 <commands+0x818>
ffffffffc0202e6c:	22000593          	li	a1,544
ffffffffc0202e70:	00004517          	auipc	a0,0x4
ffffffffc0202e74:	59850513          	addi	a0,a0,1432 # ffffffffc0207408 <default_pmm_manager+0x150>
ffffffffc0202e78:	e1afd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(boot_pgdir_va[0] == 0);
ffffffffc0202e7c:	00005697          	auipc	a3,0x5
ffffffffc0202e80:	a1468693          	addi	a3,a3,-1516 # ffffffffc0207890 <default_pmm_manager+0x5d8>
ffffffffc0202e84:	00004617          	auipc	a2,0x4
ffffffffc0202e88:	08460613          	addi	a2,a2,132 # ffffffffc0206f08 <commands+0x818>
ffffffffc0202e8c:	23e00593          	li	a1,574
ffffffffc0202e90:	00004517          	auipc	a0,0x4
ffffffffc0202e94:	57850513          	addi	a0,a0,1400 # ffffffffc0207408 <default_pmm_manager+0x150>
ffffffffc0202e98:	dfafd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc0202e9c:	00005697          	auipc	a3,0x5
ffffffffc0202ea0:	95468693          	addi	a3,a3,-1708 # ffffffffc02077f0 <default_pmm_manager+0x538>
ffffffffc0202ea4:	00004617          	auipc	a2,0x4
ffffffffc0202ea8:	06460613          	addi	a2,a2,100 # ffffffffc0206f08 <commands+0x818>
ffffffffc0202eac:	22b00593          	li	a1,555
ffffffffc0202eb0:	00004517          	auipc	a0,0x4
ffffffffc0202eb4:	55850513          	addi	a0,a0,1368 # ffffffffc0207408 <default_pmm_manager+0x150>
ffffffffc0202eb8:	ddafd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_ref(p) == 1);
ffffffffc0202ebc:	00005697          	auipc	a3,0x5
ffffffffc0202ec0:	a2c68693          	addi	a3,a3,-1492 # ffffffffc02078e8 <default_pmm_manager+0x630>
ffffffffc0202ec4:	00004617          	auipc	a2,0x4
ffffffffc0202ec8:	04460613          	addi	a2,a2,68 # ffffffffc0206f08 <commands+0x818>
ffffffffc0202ecc:	24300593          	li	a1,579
ffffffffc0202ed0:	00004517          	auipc	a0,0x4
ffffffffc0202ed4:	53850513          	addi	a0,a0,1336 # ffffffffc0207408 <default_pmm_manager+0x150>
ffffffffc0202ed8:	dbafd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0202edc:	00005697          	auipc	a3,0x5
ffffffffc0202ee0:	9cc68693          	addi	a3,a3,-1588 # ffffffffc02078a8 <default_pmm_manager+0x5f0>
ffffffffc0202ee4:	00004617          	auipc	a2,0x4
ffffffffc0202ee8:	02460613          	addi	a2,a2,36 # ffffffffc0206f08 <commands+0x818>
ffffffffc0202eec:	24200593          	li	a1,578
ffffffffc0202ef0:	00004517          	auipc	a0,0x4
ffffffffc0202ef4:	51850513          	addi	a0,a0,1304 # ffffffffc0207408 <default_pmm_manager+0x150>
ffffffffc0202ef8:	d9afd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0202efc:	00005697          	auipc	a3,0x5
ffffffffc0202f00:	87c68693          	addi	a3,a3,-1924 # ffffffffc0207778 <default_pmm_manager+0x4c0>
ffffffffc0202f04:	00004617          	auipc	a2,0x4
ffffffffc0202f08:	00460613          	addi	a2,a2,4 # ffffffffc0206f08 <commands+0x818>
ffffffffc0202f0c:	21d00593          	li	a1,541
ffffffffc0202f10:	00004517          	auipc	a0,0x4
ffffffffc0202f14:	4f850513          	addi	a0,a0,1272 # ffffffffc0207408 <default_pmm_manager+0x150>
ffffffffc0202f18:	d7afd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_ref(p1) == 1);
ffffffffc0202f1c:	00004697          	auipc	a3,0x4
ffffffffc0202f20:	6fc68693          	addi	a3,a3,1788 # ffffffffc0207618 <default_pmm_manager+0x360>
ffffffffc0202f24:	00004617          	auipc	a2,0x4
ffffffffc0202f28:	fe460613          	addi	a2,a2,-28 # ffffffffc0206f08 <commands+0x818>
ffffffffc0202f2c:	21c00593          	li	a1,540
ffffffffc0202f30:	00004517          	auipc	a0,0x4
ffffffffc0202f34:	4d850513          	addi	a0,a0,1240 # ffffffffc0207408 <default_pmm_manager+0x150>
ffffffffc0202f38:	d5afd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((*ptep & PTE_U) == 0);
ffffffffc0202f3c:	00005697          	auipc	a3,0x5
ffffffffc0202f40:	85468693          	addi	a3,a3,-1964 # ffffffffc0207790 <default_pmm_manager+0x4d8>
ffffffffc0202f44:	00004617          	auipc	a2,0x4
ffffffffc0202f48:	fc460613          	addi	a2,a2,-60 # ffffffffc0206f08 <commands+0x818>
ffffffffc0202f4c:	21900593          	li	a1,537
ffffffffc0202f50:	00004517          	auipc	a0,0x4
ffffffffc0202f54:	4b850513          	addi	a0,a0,1208 # ffffffffc0207408 <default_pmm_manager+0x150>
ffffffffc0202f58:	d3afd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc0202f5c:	00004697          	auipc	a3,0x4
ffffffffc0202f60:	6a468693          	addi	a3,a3,1700 # ffffffffc0207600 <default_pmm_manager+0x348>
ffffffffc0202f64:	00004617          	auipc	a2,0x4
ffffffffc0202f68:	fa460613          	addi	a2,a2,-92 # ffffffffc0206f08 <commands+0x818>
ffffffffc0202f6c:	21800593          	li	a1,536
ffffffffc0202f70:	00004517          	auipc	a0,0x4
ffffffffc0202f74:	49850513          	addi	a0,a0,1176 # ffffffffc0207408 <default_pmm_manager+0x150>
ffffffffc0202f78:	d1afd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0202f7c:	00004697          	auipc	a3,0x4
ffffffffc0202f80:	72468693          	addi	a3,a3,1828 # ffffffffc02076a0 <default_pmm_manager+0x3e8>
ffffffffc0202f84:	00004617          	auipc	a2,0x4
ffffffffc0202f88:	f8460613          	addi	a2,a2,-124 # ffffffffc0206f08 <commands+0x818>
ffffffffc0202f8c:	21700593          	li	a1,535
ffffffffc0202f90:	00004517          	auipc	a0,0x4
ffffffffc0202f94:	47850513          	addi	a0,a0,1144 # ffffffffc0207408 <default_pmm_manager+0x150>
ffffffffc0202f98:	cfafd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0202f9c:	00004697          	auipc	a3,0x4
ffffffffc0202fa0:	7dc68693          	addi	a3,a3,2012 # ffffffffc0207778 <default_pmm_manager+0x4c0>
ffffffffc0202fa4:	00004617          	auipc	a2,0x4
ffffffffc0202fa8:	f6460613          	addi	a2,a2,-156 # ffffffffc0206f08 <commands+0x818>
ffffffffc0202fac:	21600593          	li	a1,534
ffffffffc0202fb0:	00004517          	auipc	a0,0x4
ffffffffc0202fb4:	45850513          	addi	a0,a0,1112 # ffffffffc0207408 <default_pmm_manager+0x150>
ffffffffc0202fb8:	cdafd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_ref(p1) == 2);
ffffffffc0202fbc:	00004697          	auipc	a3,0x4
ffffffffc0202fc0:	7a468693          	addi	a3,a3,1956 # ffffffffc0207760 <default_pmm_manager+0x4a8>
ffffffffc0202fc4:	00004617          	auipc	a2,0x4
ffffffffc0202fc8:	f4460613          	addi	a2,a2,-188 # ffffffffc0206f08 <commands+0x818>
ffffffffc0202fcc:	21500593          	li	a1,533
ffffffffc0202fd0:	00004517          	auipc	a0,0x4
ffffffffc0202fd4:	43850513          	addi	a0,a0,1080 # ffffffffc0207408 <default_pmm_manager+0x150>
ffffffffc0202fd8:	cbafd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc0202fdc:	00004697          	auipc	a3,0x4
ffffffffc0202fe0:	75468693          	addi	a3,a3,1876 # ffffffffc0207730 <default_pmm_manager+0x478>
ffffffffc0202fe4:	00004617          	auipc	a2,0x4
ffffffffc0202fe8:	f2460613          	addi	a2,a2,-220 # ffffffffc0206f08 <commands+0x818>
ffffffffc0202fec:	21400593          	li	a1,532
ffffffffc0202ff0:	00004517          	auipc	a0,0x4
ffffffffc0202ff4:	41850513          	addi	a0,a0,1048 # ffffffffc0207408 <default_pmm_manager+0x150>
ffffffffc0202ff8:	c9afd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_ref(p2) == 1);
ffffffffc0202ffc:	00004697          	auipc	a3,0x4
ffffffffc0203000:	71c68693          	addi	a3,a3,1820 # ffffffffc0207718 <default_pmm_manager+0x460>
ffffffffc0203004:	00004617          	auipc	a2,0x4
ffffffffc0203008:	f0460613          	addi	a2,a2,-252 # ffffffffc0206f08 <commands+0x818>
ffffffffc020300c:	21200593          	li	a1,530
ffffffffc0203010:	00004517          	auipc	a0,0x4
ffffffffc0203014:	3f850513          	addi	a0,a0,1016 # ffffffffc0207408 <default_pmm_manager+0x150>
ffffffffc0203018:	c7afd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc020301c:	00004697          	auipc	a3,0x4
ffffffffc0203020:	6dc68693          	addi	a3,a3,1756 # ffffffffc02076f8 <default_pmm_manager+0x440>
ffffffffc0203024:	00004617          	auipc	a2,0x4
ffffffffc0203028:	ee460613          	addi	a2,a2,-284 # ffffffffc0206f08 <commands+0x818>
ffffffffc020302c:	21100593          	li	a1,529
ffffffffc0203030:	00004517          	auipc	a0,0x4
ffffffffc0203034:	3d850513          	addi	a0,a0,984 # ffffffffc0207408 <default_pmm_manager+0x150>
ffffffffc0203038:	c5afd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(*ptep & PTE_W);
ffffffffc020303c:	00004697          	auipc	a3,0x4
ffffffffc0203040:	6ac68693          	addi	a3,a3,1708 # ffffffffc02076e8 <default_pmm_manager+0x430>
ffffffffc0203044:	00004617          	auipc	a2,0x4
ffffffffc0203048:	ec460613          	addi	a2,a2,-316 # ffffffffc0206f08 <commands+0x818>
ffffffffc020304c:	21000593          	li	a1,528
ffffffffc0203050:	00004517          	auipc	a0,0x4
ffffffffc0203054:	3b850513          	addi	a0,a0,952 # ffffffffc0207408 <default_pmm_manager+0x150>
ffffffffc0203058:	c3afd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(*ptep & PTE_U);
ffffffffc020305c:	00004697          	auipc	a3,0x4
ffffffffc0203060:	67c68693          	addi	a3,a3,1660 # ffffffffc02076d8 <default_pmm_manager+0x420>
ffffffffc0203064:	00004617          	auipc	a2,0x4
ffffffffc0203068:	ea460613          	addi	a2,a2,-348 # ffffffffc0206f08 <commands+0x818>
ffffffffc020306c:	20f00593          	li	a1,527
ffffffffc0203070:	00004517          	auipc	a0,0x4
ffffffffc0203074:	39850513          	addi	a0,a0,920 # ffffffffc0207408 <default_pmm_manager+0x150>
ffffffffc0203078:	c1afd0ef          	jal	ra,ffffffffc0200492 <__panic>
        panic("DTB memory info not available");
ffffffffc020307c:	00004617          	auipc	a2,0x4
ffffffffc0203080:	3fc60613          	addi	a2,a2,1020 # ffffffffc0207478 <default_pmm_manager+0x1c0>
ffffffffc0203084:	06400593          	li	a1,100
ffffffffc0203088:	00004517          	auipc	a0,0x4
ffffffffc020308c:	38050513          	addi	a0,a0,896 # ffffffffc0207408 <default_pmm_manager+0x150>
ffffffffc0203090:	c02fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc0203094:	00004697          	auipc	a3,0x4
ffffffffc0203098:	75c68693          	addi	a3,a3,1884 # ffffffffc02077f0 <default_pmm_manager+0x538>
ffffffffc020309c:	00004617          	auipc	a2,0x4
ffffffffc02030a0:	e6c60613          	addi	a2,a2,-404 # ffffffffc0206f08 <commands+0x818>
ffffffffc02030a4:	25500593          	li	a1,597
ffffffffc02030a8:	00004517          	auipc	a0,0x4
ffffffffc02030ac:	36050513          	addi	a0,a0,864 # ffffffffc0207408 <default_pmm_manager+0x150>
ffffffffc02030b0:	be2fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc02030b4:	00004697          	auipc	a3,0x4
ffffffffc02030b8:	5ec68693          	addi	a3,a3,1516 # ffffffffc02076a0 <default_pmm_manager+0x3e8>
ffffffffc02030bc:	00004617          	auipc	a2,0x4
ffffffffc02030c0:	e4c60613          	addi	a2,a2,-436 # ffffffffc0206f08 <commands+0x818>
ffffffffc02030c4:	20e00593          	li	a1,526
ffffffffc02030c8:	00004517          	auipc	a0,0x4
ffffffffc02030cc:	34050513          	addi	a0,a0,832 # ffffffffc0207408 <default_pmm_manager+0x150>
ffffffffc02030d0:	bc2fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc02030d4:	00004697          	auipc	a3,0x4
ffffffffc02030d8:	58c68693          	addi	a3,a3,1420 # ffffffffc0207660 <default_pmm_manager+0x3a8>
ffffffffc02030dc:	00004617          	auipc	a2,0x4
ffffffffc02030e0:	e2c60613          	addi	a2,a2,-468 # ffffffffc0206f08 <commands+0x818>
ffffffffc02030e4:	20d00593          	li	a1,525
ffffffffc02030e8:	00004517          	auipc	a0,0x4
ffffffffc02030ec:	32050513          	addi	a0,a0,800 # ffffffffc0207408 <default_pmm_manager+0x150>
ffffffffc02030f0:	ba2fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc02030f4:	86d6                	mv	a3,s5
ffffffffc02030f6:	00004617          	auipc	a2,0x4
ffffffffc02030fa:	1fa60613          	addi	a2,a2,506 # ffffffffc02072f0 <default_pmm_manager+0x38>
ffffffffc02030fe:	20900593          	li	a1,521
ffffffffc0203102:	00004517          	auipc	a0,0x4
ffffffffc0203106:	30650513          	addi	a0,a0,774 # ffffffffc0207408 <default_pmm_manager+0x150>
ffffffffc020310a:	b88fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc020310e:	00004617          	auipc	a2,0x4
ffffffffc0203112:	1e260613          	addi	a2,a2,482 # ffffffffc02072f0 <default_pmm_manager+0x38>
ffffffffc0203116:	20800593          	li	a1,520
ffffffffc020311a:	00004517          	auipc	a0,0x4
ffffffffc020311e:	2ee50513          	addi	a0,a0,750 # ffffffffc0207408 <default_pmm_manager+0x150>
ffffffffc0203122:	b70fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_ref(p1) == 1);
ffffffffc0203126:	00004697          	auipc	a3,0x4
ffffffffc020312a:	4f268693          	addi	a3,a3,1266 # ffffffffc0207618 <default_pmm_manager+0x360>
ffffffffc020312e:	00004617          	auipc	a2,0x4
ffffffffc0203132:	dda60613          	addi	a2,a2,-550 # ffffffffc0206f08 <commands+0x818>
ffffffffc0203136:	20600593          	li	a1,518
ffffffffc020313a:	00004517          	auipc	a0,0x4
ffffffffc020313e:	2ce50513          	addi	a0,a0,718 # ffffffffc0207408 <default_pmm_manager+0x150>
ffffffffc0203142:	b50fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc0203146:	00004697          	auipc	a3,0x4
ffffffffc020314a:	4ba68693          	addi	a3,a3,1210 # ffffffffc0207600 <default_pmm_manager+0x348>
ffffffffc020314e:	00004617          	auipc	a2,0x4
ffffffffc0203152:	dba60613          	addi	a2,a2,-582 # ffffffffc0206f08 <commands+0x818>
ffffffffc0203156:	20500593          	li	a1,517
ffffffffc020315a:	00004517          	auipc	a0,0x4
ffffffffc020315e:	2ae50513          	addi	a0,a0,686 # ffffffffc0207408 <default_pmm_manager+0x150>
ffffffffc0203162:	b30fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(strlen((const char *)0x100) == 0);
ffffffffc0203166:	00005697          	auipc	a3,0x5
ffffffffc020316a:	84a68693          	addi	a3,a3,-1974 # ffffffffc02079b0 <default_pmm_manager+0x6f8>
ffffffffc020316e:	00004617          	auipc	a2,0x4
ffffffffc0203172:	d9a60613          	addi	a2,a2,-614 # ffffffffc0206f08 <commands+0x818>
ffffffffc0203176:	24c00593          	li	a1,588
ffffffffc020317a:	00004517          	auipc	a0,0x4
ffffffffc020317e:	28e50513          	addi	a0,a0,654 # ffffffffc0207408 <default_pmm_manager+0x150>
ffffffffc0203182:	b10fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc0203186:	00004697          	auipc	a3,0x4
ffffffffc020318a:	7f268693          	addi	a3,a3,2034 # ffffffffc0207978 <default_pmm_manager+0x6c0>
ffffffffc020318e:	00004617          	auipc	a2,0x4
ffffffffc0203192:	d7a60613          	addi	a2,a2,-646 # ffffffffc0206f08 <commands+0x818>
ffffffffc0203196:	24900593          	li	a1,585
ffffffffc020319a:	00004517          	auipc	a0,0x4
ffffffffc020319e:	26e50513          	addi	a0,a0,622 # ffffffffc0207408 <default_pmm_manager+0x150>
ffffffffc02031a2:	af0fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_ref(p) == 2);
ffffffffc02031a6:	00004697          	auipc	a3,0x4
ffffffffc02031aa:	7a268693          	addi	a3,a3,1954 # ffffffffc0207948 <default_pmm_manager+0x690>
ffffffffc02031ae:	00004617          	auipc	a2,0x4
ffffffffc02031b2:	d5a60613          	addi	a2,a2,-678 # ffffffffc0206f08 <commands+0x818>
ffffffffc02031b6:	24500593          	li	a1,581
ffffffffc02031ba:	00004517          	auipc	a0,0x4
ffffffffc02031be:	24e50513          	addi	a0,a0,590 # ffffffffc0207408 <default_pmm_manager+0x150>
ffffffffc02031c2:	ad0fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc02031c6:	00004697          	auipc	a3,0x4
ffffffffc02031ca:	73a68693          	addi	a3,a3,1850 # ffffffffc0207900 <default_pmm_manager+0x648>
ffffffffc02031ce:	00004617          	auipc	a2,0x4
ffffffffc02031d2:	d3a60613          	addi	a2,a2,-710 # ffffffffc0206f08 <commands+0x818>
ffffffffc02031d6:	24400593          	li	a1,580
ffffffffc02031da:	00004517          	auipc	a0,0x4
ffffffffc02031de:	22e50513          	addi	a0,a0,558 # ffffffffc0207408 <default_pmm_manager+0x150>
ffffffffc02031e2:	ab0fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc02031e6:	00004617          	auipc	a2,0x4
ffffffffc02031ea:	1b260613          	addi	a2,a2,434 # ffffffffc0207398 <default_pmm_manager+0xe0>
ffffffffc02031ee:	0c800593          	li	a1,200
ffffffffc02031f2:	00004517          	auipc	a0,0x4
ffffffffc02031f6:	21650513          	addi	a0,a0,534 # ffffffffc0207408 <default_pmm_manager+0x150>
ffffffffc02031fa:	a98fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02031fe:	00004617          	auipc	a2,0x4
ffffffffc0203202:	19a60613          	addi	a2,a2,410 # ffffffffc0207398 <default_pmm_manager+0xe0>
ffffffffc0203206:	08000593          	li	a1,128
ffffffffc020320a:	00004517          	auipc	a0,0x4
ffffffffc020320e:	1fe50513          	addi	a0,a0,510 # ffffffffc0207408 <default_pmm_manager+0x150>
ffffffffc0203212:	a80fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc0203216:	00004697          	auipc	a3,0x4
ffffffffc020321a:	3ba68693          	addi	a3,a3,954 # ffffffffc02075d0 <default_pmm_manager+0x318>
ffffffffc020321e:	00004617          	auipc	a2,0x4
ffffffffc0203222:	cea60613          	addi	a2,a2,-790 # ffffffffc0206f08 <commands+0x818>
ffffffffc0203226:	20400593          	li	a1,516
ffffffffc020322a:	00004517          	auipc	a0,0x4
ffffffffc020322e:	1de50513          	addi	a0,a0,478 # ffffffffc0207408 <default_pmm_manager+0x150>
ffffffffc0203232:	a60fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc0203236:	00004697          	auipc	a3,0x4
ffffffffc020323a:	36a68693          	addi	a3,a3,874 # ffffffffc02075a0 <default_pmm_manager+0x2e8>
ffffffffc020323e:	00004617          	auipc	a2,0x4
ffffffffc0203242:	cca60613          	addi	a2,a2,-822 # ffffffffc0206f08 <commands+0x818>
ffffffffc0203246:	20100593          	li	a1,513
ffffffffc020324a:	00004517          	auipc	a0,0x4
ffffffffc020324e:	1be50513          	addi	a0,a0,446 # ffffffffc0207408 <default_pmm_manager+0x150>
ffffffffc0203252:	a40fd0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0203256 <copy_range>:
{
ffffffffc0203256:	7119                	addi	sp,sp,-128
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0203258:	00d667b3          	or	a5,a2,a3
{
ffffffffc020325c:	fc86                	sd	ra,120(sp)
ffffffffc020325e:	f8a2                	sd	s0,112(sp)
ffffffffc0203260:	f4a6                	sd	s1,104(sp)
ffffffffc0203262:	f0ca                	sd	s2,96(sp)
ffffffffc0203264:	ecce                	sd	s3,88(sp)
ffffffffc0203266:	e8d2                	sd	s4,80(sp)
ffffffffc0203268:	e4d6                	sd	s5,72(sp)
ffffffffc020326a:	e0da                	sd	s6,64(sp)
ffffffffc020326c:	fc5e                	sd	s7,56(sp)
ffffffffc020326e:	f862                	sd	s8,48(sp)
ffffffffc0203270:	f466                	sd	s9,40(sp)
ffffffffc0203272:	f06a                	sd	s10,32(sp)
ffffffffc0203274:	ec6e                	sd	s11,24(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0203276:	17d2                	slli	a5,a5,0x34
ffffffffc0203278:	24079063          	bnez	a5,ffffffffc02034b8 <copy_range+0x262>
    assert(USER_ACCESS(start, end));
ffffffffc020327c:	002007b7          	lui	a5,0x200
ffffffffc0203280:	8432                	mv	s0,a2
ffffffffc0203282:	1cf66363          	bltu	a2,a5,ffffffffc0203448 <copy_range+0x1f2>
ffffffffc0203286:	8936                	mv	s2,a3
ffffffffc0203288:	1cd67063          	bgeu	a2,a3,ffffffffc0203448 <copy_range+0x1f2>
ffffffffc020328c:	4785                	li	a5,1
ffffffffc020328e:	07fe                	slli	a5,a5,0x1f
ffffffffc0203290:	1ad7ec63          	bltu	a5,a3,ffffffffc0203448 <copy_range+0x1f2>
ffffffffc0203294:	5b7d                	li	s6,-1
ffffffffc0203296:	8aaa                	mv	s5,a0
ffffffffc0203298:	89ae                	mv	s3,a1
        start += PGSIZE;
ffffffffc020329a:	6a05                	lui	s4,0x1
    if (PPN(pa) >= npage)
ffffffffc020329c:	000ddc17          	auipc	s8,0xdd
ffffffffc02032a0:	9b4c0c13          	addi	s8,s8,-1612 # ffffffffc02dfc50 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc02032a4:	000ddb97          	auipc	s7,0xdd
ffffffffc02032a8:	9b4b8b93          	addi	s7,s7,-1612 # ffffffffc02dfc58 <pages>
    return KADDR(page2pa(page));
ffffffffc02032ac:	00cb5b13          	srli	s6,s6,0xc
        page = pmm_manager->alloc_pages(n);
ffffffffc02032b0:	000ddc97          	auipc	s9,0xdd
ffffffffc02032b4:	9b0c8c93          	addi	s9,s9,-1616 # ffffffffc02dfc60 <pmm_manager>
        pte_t *ptep = get_pte(from, start, 0), *nptep;
ffffffffc02032b8:	4601                	li	a2,0
ffffffffc02032ba:	85a2                	mv	a1,s0
ffffffffc02032bc:	854e                	mv	a0,s3
ffffffffc02032be:	b73fe0ef          	jal	ra,ffffffffc0201e30 <get_pte>
ffffffffc02032c2:	84aa                	mv	s1,a0
        if (ptep == NULL) {
ffffffffc02032c4:	10050163          	beqz	a0,ffffffffc02033c6 <copy_range+0x170>
        if (*ptep & PTE_V) {
ffffffffc02032c8:	611c                	ld	a5,0(a0)
ffffffffc02032ca:	8b85                	andi	a5,a5,1
ffffffffc02032cc:	e785                	bnez	a5,ffffffffc02032f4 <copy_range+0x9e>
        start += PGSIZE;
ffffffffc02032ce:	9452                	add	s0,s0,s4
    } while (start != 0 && start < end);
ffffffffc02032d0:	ff2464e3          	bltu	s0,s2,ffffffffc02032b8 <copy_range+0x62>
    return 0;
ffffffffc02032d4:	4501                	li	a0,0
}
ffffffffc02032d6:	70e6                	ld	ra,120(sp)
ffffffffc02032d8:	7446                	ld	s0,112(sp)
ffffffffc02032da:	74a6                	ld	s1,104(sp)
ffffffffc02032dc:	7906                	ld	s2,96(sp)
ffffffffc02032de:	69e6                	ld	s3,88(sp)
ffffffffc02032e0:	6a46                	ld	s4,80(sp)
ffffffffc02032e2:	6aa6                	ld	s5,72(sp)
ffffffffc02032e4:	6b06                	ld	s6,64(sp)
ffffffffc02032e6:	7be2                	ld	s7,56(sp)
ffffffffc02032e8:	7c42                	ld	s8,48(sp)
ffffffffc02032ea:	7ca2                	ld	s9,40(sp)
ffffffffc02032ec:	7d02                	ld	s10,32(sp)
ffffffffc02032ee:	6de2                	ld	s11,24(sp)
ffffffffc02032f0:	6109                	addi	sp,sp,128
ffffffffc02032f2:	8082                	ret
            if ((nptep = get_pte(to, start, 1)) == NULL) {
ffffffffc02032f4:	4605                	li	a2,1
ffffffffc02032f6:	85a2                	mv	a1,s0
ffffffffc02032f8:	8556                	mv	a0,s5
ffffffffc02032fa:	b37fe0ef          	jal	ra,ffffffffc0201e30 <get_pte>
ffffffffc02032fe:	10050663          	beqz	a0,ffffffffc020340a <copy_range+0x1b4>
            uint32_t perm = (*ptep & PTE_USER);
ffffffffc0203302:	609c                	ld	a5,0(s1)
    if (!(pte & PTE_V))
ffffffffc0203304:	0017f713          	andi	a4,a5,1
ffffffffc0203308:	01f7f493          	andi	s1,a5,31
ffffffffc020330c:	18070a63          	beqz	a4,ffffffffc02034a0 <copy_range+0x24a>
    if (PPN(pa) >= npage)
ffffffffc0203310:	000c3683          	ld	a3,0(s8)
    return pa2page(PTE_ADDR(pte));
ffffffffc0203314:	078a                	slli	a5,a5,0x2
ffffffffc0203316:	00c7d713          	srli	a4,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc020331a:	16d77763          	bgeu	a4,a3,ffffffffc0203488 <copy_range+0x232>
    return &pages[PPN(pa) - nbase];
ffffffffc020331e:	000bb783          	ld	a5,0(s7)
ffffffffc0203322:	fff806b7          	lui	a3,0xfff80
ffffffffc0203326:	9736                	add	a4,a4,a3
ffffffffc0203328:	071a                	slli	a4,a4,0x6
ffffffffc020332a:	00e78db3          	add	s11,a5,a4
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020332e:	10002773          	csrr	a4,sstatus
ffffffffc0203332:	8b09                	andi	a4,a4,2
ffffffffc0203334:	e745                	bnez	a4,ffffffffc02033dc <copy_range+0x186>
        page = pmm_manager->alloc_pages(n);
ffffffffc0203336:	000cb703          	ld	a4,0(s9)
ffffffffc020333a:	4505                	li	a0,1
ffffffffc020333c:	6f18                	ld	a4,24(a4)
ffffffffc020333e:	9702                	jalr	a4
ffffffffc0203340:	8d2a                	mv	s10,a0
            assert(page != NULL);
ffffffffc0203342:	0e0d8363          	beqz	s11,ffffffffc0203428 <copy_range+0x1d2>
            assert(npage != NULL);
ffffffffc0203346:	120d0163          	beqz	s10,ffffffffc0203468 <copy_range+0x212>
    return page - pages + nbase;
ffffffffc020334a:	000bb703          	ld	a4,0(s7)
ffffffffc020334e:	000805b7          	lui	a1,0x80
    return KADDR(page2pa(page));
ffffffffc0203352:	000c3603          	ld	a2,0(s8)
    return page - pages + nbase;
ffffffffc0203356:	40ed86b3          	sub	a3,s11,a4
ffffffffc020335a:	8699                	srai	a3,a3,0x6
ffffffffc020335c:	96ae                	add	a3,a3,a1
    return KADDR(page2pa(page));
ffffffffc020335e:	0166f7b3          	and	a5,a3,s6
    return page2ppn(page) << PGSHIFT;
ffffffffc0203362:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0203364:	0ac7f663          	bgeu	a5,a2,ffffffffc0203410 <copy_range+0x1ba>
    return page - pages + nbase;
ffffffffc0203368:	40ed07b3          	sub	a5,s10,a4
    return KADDR(page2pa(page));
ffffffffc020336c:	000dd717          	auipc	a4,0xdd
ffffffffc0203370:	8fc70713          	addi	a4,a4,-1796 # ffffffffc02dfc68 <va_pa_offset>
ffffffffc0203374:	6308                	ld	a0,0(a4)
    return page - pages + nbase;
ffffffffc0203376:	8799                	srai	a5,a5,0x6
ffffffffc0203378:	97ae                	add	a5,a5,a1
    return KADDR(page2pa(page));
ffffffffc020337a:	0167f733          	and	a4,a5,s6
ffffffffc020337e:	00a685b3          	add	a1,a3,a0
    return page2ppn(page) << PGSHIFT;
ffffffffc0203382:	07b2                	slli	a5,a5,0xc
    return KADDR(page2pa(page));
ffffffffc0203384:	08c77563          	bgeu	a4,a2,ffffffffc020340e <copy_range+0x1b8>
ffffffffc0203388:	953e                	add	a0,a0,a5
ffffffffc020338a:	100027f3          	csrr	a5,sstatus
ffffffffc020338e:	8b89                	andi	a5,a5,2
ffffffffc0203390:	e3ad                	bnez	a5,ffffffffc02033f2 <copy_range+0x19c>
            memcpy(dst_kvaddr, src_kvaddr, PGSIZE);
ffffffffc0203392:	6605                	lui	a2,0x1
ffffffffc0203394:	0d6030ef          	jal	ra,ffffffffc020646a <memcpy>
            int ret = page_insert(to, npage, start, perm);
ffffffffc0203398:	86a6                	mv	a3,s1
ffffffffc020339a:	8622                	mv	a2,s0
ffffffffc020339c:	85ea                	mv	a1,s10
ffffffffc020339e:	8556                	mv	a0,s5
ffffffffc02033a0:	980ff0ef          	jal	ra,ffffffffc0202520 <page_insert>
            assert(ret == 0);
ffffffffc02033a4:	d50d                	beqz	a0,ffffffffc02032ce <copy_range+0x78>
ffffffffc02033a6:	00004697          	auipc	a3,0x4
ffffffffc02033aa:	67268693          	addi	a3,a3,1650 # ffffffffc0207a18 <default_pmm_manager+0x760>
ffffffffc02033ae:	00004617          	auipc	a2,0x4
ffffffffc02033b2:	b5a60613          	addi	a2,a2,-1190 # ffffffffc0206f08 <commands+0x818>
ffffffffc02033b6:	19800593          	li	a1,408
ffffffffc02033ba:	00004517          	auipc	a0,0x4
ffffffffc02033be:	04e50513          	addi	a0,a0,78 # ffffffffc0207408 <default_pmm_manager+0x150>
ffffffffc02033c2:	8d0fd0ef          	jal	ra,ffffffffc0200492 <__panic>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc02033c6:	00200637          	lui	a2,0x200
ffffffffc02033ca:	9432                	add	s0,s0,a2
ffffffffc02033cc:	ffe00637          	lui	a2,0xffe00
ffffffffc02033d0:	8c71                	and	s0,s0,a2
    } while (start != 0 && start < end);
ffffffffc02033d2:	f00401e3          	beqz	s0,ffffffffc02032d4 <copy_range+0x7e>
ffffffffc02033d6:	ef2461e3          	bltu	s0,s2,ffffffffc02032b8 <copy_range+0x62>
ffffffffc02033da:	bded                	j	ffffffffc02032d4 <copy_range+0x7e>
        intr_disable();
ffffffffc02033dc:	dd2fd0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc02033e0:	000cb703          	ld	a4,0(s9)
ffffffffc02033e4:	4505                	li	a0,1
ffffffffc02033e6:	6f18                	ld	a4,24(a4)
ffffffffc02033e8:	9702                	jalr	a4
ffffffffc02033ea:	8d2a                	mv	s10,a0
        intr_enable();
ffffffffc02033ec:	dbcfd0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc02033f0:	bf89                	j	ffffffffc0203342 <copy_range+0xec>
ffffffffc02033f2:	e42e                	sd	a1,8(sp)
ffffffffc02033f4:	e02a                	sd	a0,0(sp)
        intr_disable();
ffffffffc02033f6:	db8fd0ef          	jal	ra,ffffffffc02009ae <intr_disable>
            memcpy(dst_kvaddr, src_kvaddr, PGSIZE);
ffffffffc02033fa:	65a2                	ld	a1,8(sp)
ffffffffc02033fc:	6502                	ld	a0,0(sp)
ffffffffc02033fe:	6605                	lui	a2,0x1
ffffffffc0203400:	06a030ef          	jal	ra,ffffffffc020646a <memcpy>
        intr_enable();
ffffffffc0203404:	da4fd0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0203408:	bf41                	j	ffffffffc0203398 <copy_range+0x142>
                return -E_NO_MEM;
ffffffffc020340a:	5571                	li	a0,-4
ffffffffc020340c:	b5e9                	j	ffffffffc02032d6 <copy_range+0x80>
ffffffffc020340e:	86be                	mv	a3,a5
ffffffffc0203410:	00004617          	auipc	a2,0x4
ffffffffc0203414:	ee060613          	addi	a2,a2,-288 # ffffffffc02072f0 <default_pmm_manager+0x38>
ffffffffc0203418:	07100593          	li	a1,113
ffffffffc020341c:	00004517          	auipc	a0,0x4
ffffffffc0203420:	efc50513          	addi	a0,a0,-260 # ffffffffc0207318 <default_pmm_manager+0x60>
ffffffffc0203424:	86efd0ef          	jal	ra,ffffffffc0200492 <__panic>
            assert(page != NULL);
ffffffffc0203428:	00004697          	auipc	a3,0x4
ffffffffc020342c:	5d068693          	addi	a3,a3,1488 # ffffffffc02079f8 <default_pmm_manager+0x740>
ffffffffc0203430:	00004617          	auipc	a2,0x4
ffffffffc0203434:	ad860613          	addi	a2,a2,-1320 # ffffffffc0206f08 <commands+0x818>
ffffffffc0203438:	18b00593          	li	a1,395
ffffffffc020343c:	00004517          	auipc	a0,0x4
ffffffffc0203440:	fcc50513          	addi	a0,a0,-52 # ffffffffc0207408 <default_pmm_manager+0x150>
ffffffffc0203444:	84efd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(USER_ACCESS(start, end));
ffffffffc0203448:	00004697          	auipc	a3,0x4
ffffffffc020344c:	00068693          	mv	a3,a3
ffffffffc0203450:	00004617          	auipc	a2,0x4
ffffffffc0203454:	ab860613          	addi	a2,a2,-1352 # ffffffffc0206f08 <commands+0x818>
ffffffffc0203458:	17c00593          	li	a1,380
ffffffffc020345c:	00004517          	auipc	a0,0x4
ffffffffc0203460:	fac50513          	addi	a0,a0,-84 # ffffffffc0207408 <default_pmm_manager+0x150>
ffffffffc0203464:	82efd0ef          	jal	ra,ffffffffc0200492 <__panic>
            assert(npage != NULL);
ffffffffc0203468:	00004697          	auipc	a3,0x4
ffffffffc020346c:	5a068693          	addi	a3,a3,1440 # ffffffffc0207a08 <default_pmm_manager+0x750>
ffffffffc0203470:	00004617          	auipc	a2,0x4
ffffffffc0203474:	a9860613          	addi	a2,a2,-1384 # ffffffffc0206f08 <commands+0x818>
ffffffffc0203478:	18c00593          	li	a1,396
ffffffffc020347c:	00004517          	auipc	a0,0x4
ffffffffc0203480:	f8c50513          	addi	a0,a0,-116 # ffffffffc0207408 <default_pmm_manager+0x150>
ffffffffc0203484:	80efd0ef          	jal	ra,ffffffffc0200492 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0203488:	00004617          	auipc	a2,0x4
ffffffffc020348c:	f3860613          	addi	a2,a2,-200 # ffffffffc02073c0 <default_pmm_manager+0x108>
ffffffffc0203490:	06900593          	li	a1,105
ffffffffc0203494:	00004517          	auipc	a0,0x4
ffffffffc0203498:	e8450513          	addi	a0,a0,-380 # ffffffffc0207318 <default_pmm_manager+0x60>
ffffffffc020349c:	ff7fc0ef          	jal	ra,ffffffffc0200492 <__panic>
        panic("pte2page called with invalid pte");
ffffffffc02034a0:	00004617          	auipc	a2,0x4
ffffffffc02034a4:	f4060613          	addi	a2,a2,-192 # ffffffffc02073e0 <default_pmm_manager+0x128>
ffffffffc02034a8:	07f00593          	li	a1,127
ffffffffc02034ac:	00004517          	auipc	a0,0x4
ffffffffc02034b0:	e6c50513          	addi	a0,a0,-404 # ffffffffc0207318 <default_pmm_manager+0x60>
ffffffffc02034b4:	fdffc0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02034b8:	00004697          	auipc	a3,0x4
ffffffffc02034bc:	f6068693          	addi	a3,a3,-160 # ffffffffc0207418 <default_pmm_manager+0x160>
ffffffffc02034c0:	00004617          	auipc	a2,0x4
ffffffffc02034c4:	a4860613          	addi	a2,a2,-1464 # ffffffffc0206f08 <commands+0x818>
ffffffffc02034c8:	17b00593          	li	a1,379
ffffffffc02034cc:	00004517          	auipc	a0,0x4
ffffffffc02034d0:	f3c50513          	addi	a0,a0,-196 # ffffffffc0207408 <default_pmm_manager+0x150>
ffffffffc02034d4:	fbffc0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc02034d8 <pgdir_alloc_page>:
{
ffffffffc02034d8:	7179                	addi	sp,sp,-48
ffffffffc02034da:	ec26                	sd	s1,24(sp)
ffffffffc02034dc:	e84a                	sd	s2,16(sp)
ffffffffc02034de:	e052                	sd	s4,0(sp)
ffffffffc02034e0:	f406                	sd	ra,40(sp)
ffffffffc02034e2:	f022                	sd	s0,32(sp)
ffffffffc02034e4:	e44e                	sd	s3,8(sp)
ffffffffc02034e6:	8a2a                	mv	s4,a0
ffffffffc02034e8:	84ae                	mv	s1,a1
ffffffffc02034ea:	8932                	mv	s2,a2
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02034ec:	100027f3          	csrr	a5,sstatus
ffffffffc02034f0:	8b89                	andi	a5,a5,2
        page = pmm_manager->alloc_pages(n);
ffffffffc02034f2:	000dc997          	auipc	s3,0xdc
ffffffffc02034f6:	76e98993          	addi	s3,s3,1902 # ffffffffc02dfc60 <pmm_manager>
ffffffffc02034fa:	ef8d                	bnez	a5,ffffffffc0203534 <pgdir_alloc_page+0x5c>
ffffffffc02034fc:	0009b783          	ld	a5,0(s3)
ffffffffc0203500:	4505                	li	a0,1
ffffffffc0203502:	6f9c                	ld	a5,24(a5)
ffffffffc0203504:	9782                	jalr	a5
ffffffffc0203506:	842a                	mv	s0,a0
    if (page != NULL)
ffffffffc0203508:	cc09                	beqz	s0,ffffffffc0203522 <pgdir_alloc_page+0x4a>
        if (page_insert(pgdir, page, la, perm) != 0)
ffffffffc020350a:	86ca                	mv	a3,s2
ffffffffc020350c:	8626                	mv	a2,s1
ffffffffc020350e:	85a2                	mv	a1,s0
ffffffffc0203510:	8552                	mv	a0,s4
ffffffffc0203512:	80eff0ef          	jal	ra,ffffffffc0202520 <page_insert>
ffffffffc0203516:	e915                	bnez	a0,ffffffffc020354a <pgdir_alloc_page+0x72>
        assert(page_ref(page) == 1);
ffffffffc0203518:	4018                	lw	a4,0(s0)
        page->pra_vaddr = la;
ffffffffc020351a:	fc04                	sd	s1,56(s0)
        assert(page_ref(page) == 1);
ffffffffc020351c:	4785                	li	a5,1
ffffffffc020351e:	04f71e63          	bne	a4,a5,ffffffffc020357a <pgdir_alloc_page+0xa2>
}
ffffffffc0203522:	70a2                	ld	ra,40(sp)
ffffffffc0203524:	8522                	mv	a0,s0
ffffffffc0203526:	7402                	ld	s0,32(sp)
ffffffffc0203528:	64e2                	ld	s1,24(sp)
ffffffffc020352a:	6942                	ld	s2,16(sp)
ffffffffc020352c:	69a2                	ld	s3,8(sp)
ffffffffc020352e:	6a02                	ld	s4,0(sp)
ffffffffc0203530:	6145                	addi	sp,sp,48
ffffffffc0203532:	8082                	ret
        intr_disable();
ffffffffc0203534:	c7afd0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0203538:	0009b783          	ld	a5,0(s3)
ffffffffc020353c:	4505                	li	a0,1
ffffffffc020353e:	6f9c                	ld	a5,24(a5)
ffffffffc0203540:	9782                	jalr	a5
ffffffffc0203542:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0203544:	c64fd0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0203548:	b7c1                	j	ffffffffc0203508 <pgdir_alloc_page+0x30>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020354a:	100027f3          	csrr	a5,sstatus
ffffffffc020354e:	8b89                	andi	a5,a5,2
ffffffffc0203550:	eb89                	bnez	a5,ffffffffc0203562 <pgdir_alloc_page+0x8a>
        pmm_manager->free_pages(base, n);
ffffffffc0203552:	0009b783          	ld	a5,0(s3)
ffffffffc0203556:	8522                	mv	a0,s0
ffffffffc0203558:	4585                	li	a1,1
ffffffffc020355a:	739c                	ld	a5,32(a5)
            return NULL;
ffffffffc020355c:	4401                	li	s0,0
        pmm_manager->free_pages(base, n);
ffffffffc020355e:	9782                	jalr	a5
    if (flag) {
ffffffffc0203560:	b7c9                	j	ffffffffc0203522 <pgdir_alloc_page+0x4a>
        intr_disable();
ffffffffc0203562:	c4cfd0ef          	jal	ra,ffffffffc02009ae <intr_disable>
ffffffffc0203566:	0009b783          	ld	a5,0(s3)
ffffffffc020356a:	8522                	mv	a0,s0
ffffffffc020356c:	4585                	li	a1,1
ffffffffc020356e:	739c                	ld	a5,32(a5)
            return NULL;
ffffffffc0203570:	4401                	li	s0,0
        pmm_manager->free_pages(base, n);
ffffffffc0203572:	9782                	jalr	a5
        intr_enable();
ffffffffc0203574:	c34fd0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0203578:	b76d                	j	ffffffffc0203522 <pgdir_alloc_page+0x4a>
        assert(page_ref(page) == 1);
ffffffffc020357a:	00004697          	auipc	a3,0x4
ffffffffc020357e:	4ae68693          	addi	a3,a3,1198 # ffffffffc0207a28 <default_pmm_manager+0x770>
ffffffffc0203582:	00004617          	auipc	a2,0x4
ffffffffc0203586:	98660613          	addi	a2,a2,-1658 # ffffffffc0206f08 <commands+0x818>
ffffffffc020358a:	1e200593          	li	a1,482
ffffffffc020358e:	00004517          	auipc	a0,0x4
ffffffffc0203592:	e7a50513          	addi	a0,a0,-390 # ffffffffc0207408 <default_pmm_manager+0x150>
ffffffffc0203596:	efdfc0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc020359a <check_vma_overlap.part.0>:
    return vma;
}

// check_vma_overlap - check if vma1 overlaps vma2 ?
static inline void
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc020359a:	1141                	addi	sp,sp,-16
{
    assert(prev->vm_start < prev->vm_end);
    assert(prev->vm_end <= next->vm_start);
    assert(next->vm_start < next->vm_end);
ffffffffc020359c:	00004697          	auipc	a3,0x4
ffffffffc02035a0:	4a468693          	addi	a3,a3,1188 # ffffffffc0207a40 <default_pmm_manager+0x788>
ffffffffc02035a4:	00004617          	auipc	a2,0x4
ffffffffc02035a8:	96460613          	addi	a2,a2,-1692 # ffffffffc0206f08 <commands+0x818>
ffffffffc02035ac:	07400593          	li	a1,116
ffffffffc02035b0:	00004517          	auipc	a0,0x4
ffffffffc02035b4:	4b050513          	addi	a0,a0,1200 # ffffffffc0207a60 <default_pmm_manager+0x7a8>
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc02035b8:	e406                	sd	ra,8(sp)
    assert(next->vm_start < next->vm_end);
ffffffffc02035ba:	ed9fc0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc02035be <mm_create>:
{
ffffffffc02035be:	1141                	addi	sp,sp,-16
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc02035c0:	05800513          	li	a0,88
{
ffffffffc02035c4:	e022                	sd	s0,0(sp)
ffffffffc02035c6:	e406                	sd	ra,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc02035c8:	dd2fe0ef          	jal	ra,ffffffffc0201b9a <kmalloc>
ffffffffc02035cc:	842a                	mv	s0,a0
    if (mm != NULL)
ffffffffc02035ce:	c115                	beqz	a0,ffffffffc02035f2 <mm_create+0x34>
    elm->prev = elm->next = elm;
ffffffffc02035d0:	e408                	sd	a0,8(s0)
ffffffffc02035d2:	e008                	sd	a0,0(s0)
        mm->mmap_cache = NULL;
ffffffffc02035d4:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc02035d8:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc02035dc:	02052023          	sw	zero,32(a0)
        mm->sm_priv = NULL;
ffffffffc02035e0:	02053423          	sd	zero,40(a0)
}

static inline void
set_mm_count(struct mm_struct *mm, int val)
{
    mm->mm_count = val;
ffffffffc02035e4:	02052823          	sw	zero,48(a0)
        sem_init(&(mm->mm_sem), 1);
ffffffffc02035e8:	4585                	li	a1,1
ffffffffc02035ea:	03850513          	addi	a0,a0,56
ffffffffc02035ee:	6bd000ef          	jal	ra,ffffffffc02044aa <sem_init>
}
ffffffffc02035f2:	60a2                	ld	ra,8(sp)
ffffffffc02035f4:	8522                	mv	a0,s0
ffffffffc02035f6:	6402                	ld	s0,0(sp)
ffffffffc02035f8:	0141                	addi	sp,sp,16
ffffffffc02035fa:	8082                	ret

ffffffffc02035fc <find_vma>:
{
ffffffffc02035fc:	86aa                	mv	a3,a0
    if (mm != NULL)
ffffffffc02035fe:	c505                	beqz	a0,ffffffffc0203626 <find_vma+0x2a>
        vma = mm->mmap_cache;
ffffffffc0203600:	6908                	ld	a0,16(a0)
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc0203602:	c501                	beqz	a0,ffffffffc020360a <find_vma+0xe>
ffffffffc0203604:	651c                	ld	a5,8(a0)
ffffffffc0203606:	02f5f263          	bgeu	a1,a5,ffffffffc020362a <find_vma+0x2e>
    return listelm->next;
ffffffffc020360a:	669c                	ld	a5,8(a3)
            while ((le = list_next(le)) != list)
ffffffffc020360c:	00f68d63          	beq	a3,a5,ffffffffc0203626 <find_vma+0x2a>
                if (vma->vm_start <= addr && addr < vma->vm_end)
ffffffffc0203610:	fe87b703          	ld	a4,-24(a5) # 1fffe8 <_binary_obj___user_matrix_out_size+0x1f36e8>
ffffffffc0203614:	00e5e663          	bltu	a1,a4,ffffffffc0203620 <find_vma+0x24>
ffffffffc0203618:	ff07b703          	ld	a4,-16(a5)
ffffffffc020361c:	00e5ec63          	bltu	a1,a4,ffffffffc0203634 <find_vma+0x38>
ffffffffc0203620:	679c                	ld	a5,8(a5)
            while ((le = list_next(le)) != list)
ffffffffc0203622:	fef697e3          	bne	a3,a5,ffffffffc0203610 <find_vma+0x14>
    struct vma_struct *vma = NULL;
ffffffffc0203626:	4501                	li	a0,0
}
ffffffffc0203628:	8082                	ret
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc020362a:	691c                	ld	a5,16(a0)
ffffffffc020362c:	fcf5ffe3          	bgeu	a1,a5,ffffffffc020360a <find_vma+0xe>
            mm->mmap_cache = vma;
ffffffffc0203630:	ea88                	sd	a0,16(a3)
ffffffffc0203632:	8082                	ret
                vma = le2vma(le, list_link);
ffffffffc0203634:	fe078513          	addi	a0,a5,-32
            mm->mmap_cache = vma;
ffffffffc0203638:	ea88                	sd	a0,16(a3)
ffffffffc020363a:	8082                	ret

ffffffffc020363c <insert_vma_struct>:
}

// insert_vma_struct -insert vma in mm's list link
void insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma)
{
    assert(vma->vm_start < vma->vm_end);
ffffffffc020363c:	6590                	ld	a2,8(a1)
ffffffffc020363e:	0105b803          	ld	a6,16(a1) # 80010 <_binary_obj___user_matrix_out_size+0x73710>
{
ffffffffc0203642:	1141                	addi	sp,sp,-16
ffffffffc0203644:	e406                	sd	ra,8(sp)
ffffffffc0203646:	87aa                	mv	a5,a0
    assert(vma->vm_start < vma->vm_end);
ffffffffc0203648:	01066763          	bltu	a2,a6,ffffffffc0203656 <insert_vma_struct+0x1a>
ffffffffc020364c:	a085                	j	ffffffffc02036ac <insert_vma_struct+0x70>

    list_entry_t *le = list;
    while ((le = list_next(le)) != list)
    {
        struct vma_struct *mmap_prev = le2vma(le, list_link);
        if (mmap_prev->vm_start > vma->vm_start)
ffffffffc020364e:	fe87b703          	ld	a4,-24(a5)
ffffffffc0203652:	04e66863          	bltu	a2,a4,ffffffffc02036a2 <insert_vma_struct+0x66>
ffffffffc0203656:	86be                	mv	a3,a5
ffffffffc0203658:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != list)
ffffffffc020365a:	fef51ae3          	bne	a0,a5,ffffffffc020364e <insert_vma_struct+0x12>
    }

    le_next = list_next(le_prev);

    /* check overlap */
    if (le_prev != list)
ffffffffc020365e:	02a68463          	beq	a3,a0,ffffffffc0203686 <insert_vma_struct+0x4a>
    {
        check_vma_overlap(le2vma(le_prev, list_link), vma);
ffffffffc0203662:	ff06b703          	ld	a4,-16(a3)
    assert(prev->vm_start < prev->vm_end);
ffffffffc0203666:	fe86b883          	ld	a7,-24(a3)
ffffffffc020366a:	08e8f163          	bgeu	a7,a4,ffffffffc02036ec <insert_vma_struct+0xb0>
    assert(prev->vm_end <= next->vm_start);
ffffffffc020366e:	04e66f63          	bltu	a2,a4,ffffffffc02036cc <insert_vma_struct+0x90>
    }
    if (le_next != list)
ffffffffc0203672:	00f50a63          	beq	a0,a5,ffffffffc0203686 <insert_vma_struct+0x4a>
        if (mmap_prev->vm_start > vma->vm_start)
ffffffffc0203676:	fe87b703          	ld	a4,-24(a5)
    assert(prev->vm_end <= next->vm_start);
ffffffffc020367a:	05076963          	bltu	a4,a6,ffffffffc02036cc <insert_vma_struct+0x90>
    assert(next->vm_start < next->vm_end);
ffffffffc020367e:	ff07b603          	ld	a2,-16(a5)
ffffffffc0203682:	02c77363          	bgeu	a4,a2,ffffffffc02036a8 <insert_vma_struct+0x6c>
    }

    vma->vm_mm = mm;
    list_add_after(le_prev, &(vma->list_link));

    mm->map_count++;
ffffffffc0203686:	5118                	lw	a4,32(a0)
    vma->vm_mm = mm;
ffffffffc0203688:	e188                	sd	a0,0(a1)
    list_add_after(le_prev, &(vma->list_link));
ffffffffc020368a:	02058613          	addi	a2,a1,32
    prev->next = next->prev = elm;
ffffffffc020368e:	e390                	sd	a2,0(a5)
ffffffffc0203690:	e690                	sd	a2,8(a3)
}
ffffffffc0203692:	60a2                	ld	ra,8(sp)
    elm->next = next;
ffffffffc0203694:	f59c                	sd	a5,40(a1)
    elm->prev = prev;
ffffffffc0203696:	f194                	sd	a3,32(a1)
    mm->map_count++;
ffffffffc0203698:	0017079b          	addiw	a5,a4,1
ffffffffc020369c:	d11c                	sw	a5,32(a0)
}
ffffffffc020369e:	0141                	addi	sp,sp,16
ffffffffc02036a0:	8082                	ret
    if (le_prev != list)
ffffffffc02036a2:	fca690e3          	bne	a3,a0,ffffffffc0203662 <insert_vma_struct+0x26>
ffffffffc02036a6:	bfd1                	j	ffffffffc020367a <insert_vma_struct+0x3e>
ffffffffc02036a8:	ef3ff0ef          	jal	ra,ffffffffc020359a <check_vma_overlap.part.0>
    assert(vma->vm_start < vma->vm_end);
ffffffffc02036ac:	00004697          	auipc	a3,0x4
ffffffffc02036b0:	3c468693          	addi	a3,a3,964 # ffffffffc0207a70 <default_pmm_manager+0x7b8>
ffffffffc02036b4:	00004617          	auipc	a2,0x4
ffffffffc02036b8:	85460613          	addi	a2,a2,-1964 # ffffffffc0206f08 <commands+0x818>
ffffffffc02036bc:	07a00593          	li	a1,122
ffffffffc02036c0:	00004517          	auipc	a0,0x4
ffffffffc02036c4:	3a050513          	addi	a0,a0,928 # ffffffffc0207a60 <default_pmm_manager+0x7a8>
ffffffffc02036c8:	dcbfc0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(prev->vm_end <= next->vm_start);
ffffffffc02036cc:	00004697          	auipc	a3,0x4
ffffffffc02036d0:	3e468693          	addi	a3,a3,996 # ffffffffc0207ab0 <default_pmm_manager+0x7f8>
ffffffffc02036d4:	00004617          	auipc	a2,0x4
ffffffffc02036d8:	83460613          	addi	a2,a2,-1996 # ffffffffc0206f08 <commands+0x818>
ffffffffc02036dc:	07300593          	li	a1,115
ffffffffc02036e0:	00004517          	auipc	a0,0x4
ffffffffc02036e4:	38050513          	addi	a0,a0,896 # ffffffffc0207a60 <default_pmm_manager+0x7a8>
ffffffffc02036e8:	dabfc0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(prev->vm_start < prev->vm_end);
ffffffffc02036ec:	00004697          	auipc	a3,0x4
ffffffffc02036f0:	3a468693          	addi	a3,a3,932 # ffffffffc0207a90 <default_pmm_manager+0x7d8>
ffffffffc02036f4:	00004617          	auipc	a2,0x4
ffffffffc02036f8:	81460613          	addi	a2,a2,-2028 # ffffffffc0206f08 <commands+0x818>
ffffffffc02036fc:	07200593          	li	a1,114
ffffffffc0203700:	00004517          	auipc	a0,0x4
ffffffffc0203704:	36050513          	addi	a0,a0,864 # ffffffffc0207a60 <default_pmm_manager+0x7a8>
ffffffffc0203708:	d8bfc0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc020370c <mm_destroy>:

// mm_destroy - free mm and mm internal fields
void mm_destroy(struct mm_struct *mm)
{
    assert(mm_count(mm) == 0);
ffffffffc020370c:	591c                	lw	a5,48(a0)
{
ffffffffc020370e:	1141                	addi	sp,sp,-16
ffffffffc0203710:	e406                	sd	ra,8(sp)
ffffffffc0203712:	e022                	sd	s0,0(sp)
    assert(mm_count(mm) == 0);
ffffffffc0203714:	e78d                	bnez	a5,ffffffffc020373e <mm_destroy+0x32>
ffffffffc0203716:	842a                	mv	s0,a0
    return listelm->next;
ffffffffc0203718:	6508                	ld	a0,8(a0)

    list_entry_t *list = &(mm->mmap_list), *le;
    while ((le = list_next(list)) != list)
ffffffffc020371a:	00a40c63          	beq	s0,a0,ffffffffc0203732 <mm_destroy+0x26>
    __list_del(listelm->prev, listelm->next);
ffffffffc020371e:	6118                	ld	a4,0(a0)
ffffffffc0203720:	651c                	ld	a5,8(a0)
    {
        list_del(le);
        kfree(le2vma(le, list_link)); // kfree vma
ffffffffc0203722:	1501                	addi	a0,a0,-32
    prev->next = next;
ffffffffc0203724:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0203726:	e398                	sd	a4,0(a5)
ffffffffc0203728:	d22fe0ef          	jal	ra,ffffffffc0201c4a <kfree>
    return listelm->next;
ffffffffc020372c:	6408                	ld	a0,8(s0)
    while ((le = list_next(list)) != list)
ffffffffc020372e:	fea418e3          	bne	s0,a0,ffffffffc020371e <mm_destroy+0x12>
    }
    kfree(mm); // kfree mm
ffffffffc0203732:	8522                	mv	a0,s0
    mm = NULL;
}
ffffffffc0203734:	6402                	ld	s0,0(sp)
ffffffffc0203736:	60a2                	ld	ra,8(sp)
ffffffffc0203738:	0141                	addi	sp,sp,16
    kfree(mm); // kfree mm
ffffffffc020373a:	d10fe06f          	j	ffffffffc0201c4a <kfree>
    assert(mm_count(mm) == 0);
ffffffffc020373e:	00004697          	auipc	a3,0x4
ffffffffc0203742:	39268693          	addi	a3,a3,914 # ffffffffc0207ad0 <default_pmm_manager+0x818>
ffffffffc0203746:	00003617          	auipc	a2,0x3
ffffffffc020374a:	7c260613          	addi	a2,a2,1986 # ffffffffc0206f08 <commands+0x818>
ffffffffc020374e:	09e00593          	li	a1,158
ffffffffc0203752:	00004517          	auipc	a0,0x4
ffffffffc0203756:	30e50513          	addi	a0,a0,782 # ffffffffc0207a60 <default_pmm_manager+0x7a8>
ffffffffc020375a:	d39fc0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc020375e <mm_map>:

int mm_map(struct mm_struct *mm, uintptr_t addr, size_t len, uint32_t vm_flags,
           struct vma_struct **vma_store)
{
ffffffffc020375e:	7139                	addi	sp,sp,-64
ffffffffc0203760:	f822                	sd	s0,48(sp)
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc0203762:	6405                	lui	s0,0x1
ffffffffc0203764:	147d                	addi	s0,s0,-1
ffffffffc0203766:	77fd                	lui	a5,0xfffff
ffffffffc0203768:	9622                	add	a2,a2,s0
ffffffffc020376a:	962e                	add	a2,a2,a1
{
ffffffffc020376c:	f426                	sd	s1,40(sp)
ffffffffc020376e:	fc06                	sd	ra,56(sp)
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc0203770:	00f5f4b3          	and	s1,a1,a5
{
ffffffffc0203774:	f04a                	sd	s2,32(sp)
ffffffffc0203776:	ec4e                	sd	s3,24(sp)
ffffffffc0203778:	e852                	sd	s4,16(sp)
ffffffffc020377a:	e456                	sd	s5,8(sp)
    if (!USER_ACCESS(start, end))
ffffffffc020377c:	002005b7          	lui	a1,0x200
ffffffffc0203780:	00f67433          	and	s0,a2,a5
ffffffffc0203784:	06b4e363          	bltu	s1,a1,ffffffffc02037ea <mm_map+0x8c>
ffffffffc0203788:	0684f163          	bgeu	s1,s0,ffffffffc02037ea <mm_map+0x8c>
ffffffffc020378c:	4785                	li	a5,1
ffffffffc020378e:	07fe                	slli	a5,a5,0x1f
ffffffffc0203790:	0487ed63          	bltu	a5,s0,ffffffffc02037ea <mm_map+0x8c>
ffffffffc0203794:	89aa                	mv	s3,a0
    {
        return -E_INVAL;
    }

    assert(mm != NULL);
ffffffffc0203796:	cd21                	beqz	a0,ffffffffc02037ee <mm_map+0x90>

    int ret = -E_INVAL;

    struct vma_struct *vma;
    if ((vma = find_vma(mm, start)) != NULL && end > vma->vm_start)
ffffffffc0203798:	85a6                	mv	a1,s1
ffffffffc020379a:	8ab6                	mv	s5,a3
ffffffffc020379c:	8a3a                	mv	s4,a4
ffffffffc020379e:	e5fff0ef          	jal	ra,ffffffffc02035fc <find_vma>
ffffffffc02037a2:	c501                	beqz	a0,ffffffffc02037aa <mm_map+0x4c>
ffffffffc02037a4:	651c                	ld	a5,8(a0)
ffffffffc02037a6:	0487e263          	bltu	a5,s0,ffffffffc02037ea <mm_map+0x8c>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc02037aa:	03000513          	li	a0,48
ffffffffc02037ae:	becfe0ef          	jal	ra,ffffffffc0201b9a <kmalloc>
ffffffffc02037b2:	892a                	mv	s2,a0
    {
        goto out;
    }
    ret = -E_NO_MEM;
ffffffffc02037b4:	5571                	li	a0,-4
    if (vma != NULL)
ffffffffc02037b6:	02090163          	beqz	s2,ffffffffc02037d8 <mm_map+0x7a>

    if ((vma = vma_create(start, end, vm_flags)) == NULL)
    {
        goto out;
    }
    insert_vma_struct(mm, vma);
ffffffffc02037ba:	854e                	mv	a0,s3
        vma->vm_start = vm_start;
ffffffffc02037bc:	00993423          	sd	s1,8(s2)
        vma->vm_end = vm_end;
ffffffffc02037c0:	00893823          	sd	s0,16(s2)
        vma->vm_flags = vm_flags;
ffffffffc02037c4:	01592c23          	sw	s5,24(s2)
    insert_vma_struct(mm, vma);
ffffffffc02037c8:	85ca                	mv	a1,s2
ffffffffc02037ca:	e73ff0ef          	jal	ra,ffffffffc020363c <insert_vma_struct>
    if (vma_store != NULL)
    {
        *vma_store = vma;
    }
    ret = 0;
ffffffffc02037ce:	4501                	li	a0,0
    if (vma_store != NULL)
ffffffffc02037d0:	000a0463          	beqz	s4,ffffffffc02037d8 <mm_map+0x7a>
        *vma_store = vma;
ffffffffc02037d4:	012a3023          	sd	s2,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x9128>

out:
    return ret;
}
ffffffffc02037d8:	70e2                	ld	ra,56(sp)
ffffffffc02037da:	7442                	ld	s0,48(sp)
ffffffffc02037dc:	74a2                	ld	s1,40(sp)
ffffffffc02037de:	7902                	ld	s2,32(sp)
ffffffffc02037e0:	69e2                	ld	s3,24(sp)
ffffffffc02037e2:	6a42                	ld	s4,16(sp)
ffffffffc02037e4:	6aa2                	ld	s5,8(sp)
ffffffffc02037e6:	6121                	addi	sp,sp,64
ffffffffc02037e8:	8082                	ret
        return -E_INVAL;
ffffffffc02037ea:	5575                	li	a0,-3
ffffffffc02037ec:	b7f5                	j	ffffffffc02037d8 <mm_map+0x7a>
    assert(mm != NULL);
ffffffffc02037ee:	00004697          	auipc	a3,0x4
ffffffffc02037f2:	2fa68693          	addi	a3,a3,762 # ffffffffc0207ae8 <default_pmm_manager+0x830>
ffffffffc02037f6:	00003617          	auipc	a2,0x3
ffffffffc02037fa:	71260613          	addi	a2,a2,1810 # ffffffffc0206f08 <commands+0x818>
ffffffffc02037fe:	0b300593          	li	a1,179
ffffffffc0203802:	00004517          	auipc	a0,0x4
ffffffffc0203806:	25e50513          	addi	a0,a0,606 # ffffffffc0207a60 <default_pmm_manager+0x7a8>
ffffffffc020380a:	c89fc0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc020380e <dup_mmap>:

int dup_mmap(struct mm_struct *to, struct mm_struct *from)
{
ffffffffc020380e:	7139                	addi	sp,sp,-64
ffffffffc0203810:	fc06                	sd	ra,56(sp)
ffffffffc0203812:	f822                	sd	s0,48(sp)
ffffffffc0203814:	f426                	sd	s1,40(sp)
ffffffffc0203816:	f04a                	sd	s2,32(sp)
ffffffffc0203818:	ec4e                	sd	s3,24(sp)
ffffffffc020381a:	e852                	sd	s4,16(sp)
ffffffffc020381c:	e456                	sd	s5,8(sp)
    assert(to != NULL && from != NULL);
ffffffffc020381e:	c52d                	beqz	a0,ffffffffc0203888 <dup_mmap+0x7a>
ffffffffc0203820:	892a                	mv	s2,a0
ffffffffc0203822:	84ae                	mv	s1,a1
    list_entry_t *list = &(from->mmap_list), *le = list;
ffffffffc0203824:	842e                	mv	s0,a1
    assert(to != NULL && from != NULL);
ffffffffc0203826:	e595                	bnez	a1,ffffffffc0203852 <dup_mmap+0x44>
ffffffffc0203828:	a085                	j	ffffffffc0203888 <dup_mmap+0x7a>
        if (nvma == NULL)
        {
            return -E_NO_MEM;
        }

        insert_vma_struct(to, nvma);
ffffffffc020382a:	854a                	mv	a0,s2
        vma->vm_start = vm_start;
ffffffffc020382c:	0155b423          	sd	s5,8(a1) # 200008 <_binary_obj___user_matrix_out_size+0x1f3708>
        vma->vm_end = vm_end;
ffffffffc0203830:	0145b823          	sd	s4,16(a1)
        vma->vm_flags = vm_flags;
ffffffffc0203834:	0135ac23          	sw	s3,24(a1)
        insert_vma_struct(to, nvma);
ffffffffc0203838:	e05ff0ef          	jal	ra,ffffffffc020363c <insert_vma_struct>

        bool share = 0;
        if (copy_range(to->pgdir, from->pgdir, vma->vm_start, vma->vm_end, share) != 0)
ffffffffc020383c:	ff043683          	ld	a3,-16(s0) # ff0 <_binary_obj___user_faultread_out_size-0x9138>
ffffffffc0203840:	fe843603          	ld	a2,-24(s0)
ffffffffc0203844:	6c8c                	ld	a1,24(s1)
ffffffffc0203846:	01893503          	ld	a0,24(s2)
ffffffffc020384a:	4701                	li	a4,0
ffffffffc020384c:	a0bff0ef          	jal	ra,ffffffffc0203256 <copy_range>
ffffffffc0203850:	e105                	bnez	a0,ffffffffc0203870 <dup_mmap+0x62>
    return listelm->prev;
ffffffffc0203852:	6000                	ld	s0,0(s0)
    while ((le = list_prev(le)) != list)
ffffffffc0203854:	02848863          	beq	s1,s0,ffffffffc0203884 <dup_mmap+0x76>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203858:	03000513          	li	a0,48
        nvma = vma_create(vma->vm_start, vma->vm_end, vma->vm_flags);
ffffffffc020385c:	fe843a83          	ld	s5,-24(s0)
ffffffffc0203860:	ff043a03          	ld	s4,-16(s0)
ffffffffc0203864:	ff842983          	lw	s3,-8(s0)
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203868:	b32fe0ef          	jal	ra,ffffffffc0201b9a <kmalloc>
ffffffffc020386c:	85aa                	mv	a1,a0
    if (vma != NULL)
ffffffffc020386e:	fd55                	bnez	a0,ffffffffc020382a <dup_mmap+0x1c>
            return -E_NO_MEM;
ffffffffc0203870:	5571                	li	a0,-4
        {
            return -E_NO_MEM;
        }
    }
    return 0;
}
ffffffffc0203872:	70e2                	ld	ra,56(sp)
ffffffffc0203874:	7442                	ld	s0,48(sp)
ffffffffc0203876:	74a2                	ld	s1,40(sp)
ffffffffc0203878:	7902                	ld	s2,32(sp)
ffffffffc020387a:	69e2                	ld	s3,24(sp)
ffffffffc020387c:	6a42                	ld	s4,16(sp)
ffffffffc020387e:	6aa2                	ld	s5,8(sp)
ffffffffc0203880:	6121                	addi	sp,sp,64
ffffffffc0203882:	8082                	ret
    return 0;
ffffffffc0203884:	4501                	li	a0,0
ffffffffc0203886:	b7f5                	j	ffffffffc0203872 <dup_mmap+0x64>
    assert(to != NULL && from != NULL);
ffffffffc0203888:	00004697          	auipc	a3,0x4
ffffffffc020388c:	27068693          	addi	a3,a3,624 # ffffffffc0207af8 <default_pmm_manager+0x840>
ffffffffc0203890:	00003617          	auipc	a2,0x3
ffffffffc0203894:	67860613          	addi	a2,a2,1656 # ffffffffc0206f08 <commands+0x818>
ffffffffc0203898:	0cf00593          	li	a1,207
ffffffffc020389c:	00004517          	auipc	a0,0x4
ffffffffc02038a0:	1c450513          	addi	a0,a0,452 # ffffffffc0207a60 <default_pmm_manager+0x7a8>
ffffffffc02038a4:	beffc0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc02038a8 <exit_mmap>:

void exit_mmap(struct mm_struct *mm)
{
ffffffffc02038a8:	1101                	addi	sp,sp,-32
ffffffffc02038aa:	ec06                	sd	ra,24(sp)
ffffffffc02038ac:	e822                	sd	s0,16(sp)
ffffffffc02038ae:	e426                	sd	s1,8(sp)
ffffffffc02038b0:	e04a                	sd	s2,0(sp)
    assert(mm != NULL && mm_count(mm) == 0);
ffffffffc02038b2:	c531                	beqz	a0,ffffffffc02038fe <exit_mmap+0x56>
ffffffffc02038b4:	591c                	lw	a5,48(a0)
ffffffffc02038b6:	84aa                	mv	s1,a0
ffffffffc02038b8:	e3b9                	bnez	a5,ffffffffc02038fe <exit_mmap+0x56>
    return listelm->next;
ffffffffc02038ba:	6500                	ld	s0,8(a0)
    pde_t *pgdir = mm->pgdir;
ffffffffc02038bc:	01853903          	ld	s2,24(a0)
    list_entry_t *list = &(mm->mmap_list), *le = list;
    while ((le = list_next(le)) != list)
ffffffffc02038c0:	02850663          	beq	a0,s0,ffffffffc02038ec <exit_mmap+0x44>
    {
        struct vma_struct *vma = le2vma(le, list_link);
        unmap_range(pgdir, vma->vm_start, vma->vm_end);
ffffffffc02038c4:	ff043603          	ld	a2,-16(s0)
ffffffffc02038c8:	fe843583          	ld	a1,-24(s0)
ffffffffc02038cc:	854a                	mv	a0,s2
ffffffffc02038ce:	fdefe0ef          	jal	ra,ffffffffc02020ac <unmap_range>
ffffffffc02038d2:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != list)
ffffffffc02038d4:	fe8498e3          	bne	s1,s0,ffffffffc02038c4 <exit_mmap+0x1c>
ffffffffc02038d8:	6400                	ld	s0,8(s0)
    }
    while ((le = list_next(le)) != list)
ffffffffc02038da:	00848c63          	beq	s1,s0,ffffffffc02038f2 <exit_mmap+0x4a>
    {
        struct vma_struct *vma = le2vma(le, list_link);
        exit_range(pgdir, vma->vm_start, vma->vm_end);
ffffffffc02038de:	ff043603          	ld	a2,-16(s0)
ffffffffc02038e2:	fe843583          	ld	a1,-24(s0)
ffffffffc02038e6:	854a                	mv	a0,s2
ffffffffc02038e8:	90bfe0ef          	jal	ra,ffffffffc02021f2 <exit_range>
ffffffffc02038ec:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != list)
ffffffffc02038ee:	fe8498e3          	bne	s1,s0,ffffffffc02038de <exit_mmap+0x36>
    }
}
ffffffffc02038f2:	60e2                	ld	ra,24(sp)
ffffffffc02038f4:	6442                	ld	s0,16(sp)
ffffffffc02038f6:	64a2                	ld	s1,8(sp)
ffffffffc02038f8:	6902                	ld	s2,0(sp)
ffffffffc02038fa:	6105                	addi	sp,sp,32
ffffffffc02038fc:	8082                	ret
    assert(mm != NULL && mm_count(mm) == 0);
ffffffffc02038fe:	00004697          	auipc	a3,0x4
ffffffffc0203902:	21a68693          	addi	a3,a3,538 # ffffffffc0207b18 <default_pmm_manager+0x860>
ffffffffc0203906:	00003617          	auipc	a2,0x3
ffffffffc020390a:	60260613          	addi	a2,a2,1538 # ffffffffc0206f08 <commands+0x818>
ffffffffc020390e:	0e800593          	li	a1,232
ffffffffc0203912:	00004517          	auipc	a0,0x4
ffffffffc0203916:	14e50513          	addi	a0,a0,334 # ffffffffc0207a60 <default_pmm_manager+0x7a8>
ffffffffc020391a:	b79fc0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc020391e <vmm_init>:
}

// vmm_init - initialize virtual memory management
//          - now just call check_vmm to check correctness of vmm
void vmm_init(void)
{
ffffffffc020391e:	7139                	addi	sp,sp,-64
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0203920:	05800513          	li	a0,88
{
ffffffffc0203924:	fc06                	sd	ra,56(sp)
ffffffffc0203926:	f822                	sd	s0,48(sp)
ffffffffc0203928:	f426                	sd	s1,40(sp)
ffffffffc020392a:	f04a                	sd	s2,32(sp)
ffffffffc020392c:	ec4e                	sd	s3,24(sp)
ffffffffc020392e:	e852                	sd	s4,16(sp)
ffffffffc0203930:	e456                	sd	s5,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0203932:	a68fe0ef          	jal	ra,ffffffffc0201b9a <kmalloc>
    if (mm != NULL)
ffffffffc0203936:	2e050963          	beqz	a0,ffffffffc0203c28 <vmm_init+0x30a>
    elm->prev = elm->next = elm;
ffffffffc020393a:	e508                	sd	a0,8(a0)
ffffffffc020393c:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc020393e:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc0203942:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc0203946:	02052023          	sw	zero,32(a0)
        mm->sm_priv = NULL;
ffffffffc020394a:	02053423          	sd	zero,40(a0)
ffffffffc020394e:	02052823          	sw	zero,48(a0)
        sem_init(&(mm->mm_sem), 1);
ffffffffc0203952:	84aa                	mv	s1,a0
ffffffffc0203954:	4585                	li	a1,1
ffffffffc0203956:	03850513          	addi	a0,a0,56
ffffffffc020395a:	351000ef          	jal	ra,ffffffffc02044aa <sem_init>
ffffffffc020395e:	03200413          	li	s0,50
ffffffffc0203962:	a811                	j	ffffffffc0203976 <vmm_init+0x58>
        vma->vm_start = vm_start;
ffffffffc0203964:	e500                	sd	s0,8(a0)
        vma->vm_end = vm_end;
ffffffffc0203966:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0203968:	00052c23          	sw	zero,24(a0)
    assert(mm != NULL);

    int step1 = 10, step2 = step1 * 10;

    int i;
    for (i = step1; i >= 1; i--)
ffffffffc020396c:	146d                	addi	s0,s0,-5
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc020396e:	8526                	mv	a0,s1
ffffffffc0203970:	ccdff0ef          	jal	ra,ffffffffc020363c <insert_vma_struct>
    for (i = step1; i >= 1; i--)
ffffffffc0203974:	c80d                	beqz	s0,ffffffffc02039a6 <vmm_init+0x88>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203976:	03000513          	li	a0,48
ffffffffc020397a:	a20fe0ef          	jal	ra,ffffffffc0201b9a <kmalloc>
ffffffffc020397e:	85aa                	mv	a1,a0
ffffffffc0203980:	00240793          	addi	a5,s0,2
    if (vma != NULL)
ffffffffc0203984:	f165                	bnez	a0,ffffffffc0203964 <vmm_init+0x46>
        assert(vma != NULL);
ffffffffc0203986:	00004697          	auipc	a3,0x4
ffffffffc020398a:	32a68693          	addi	a3,a3,810 # ffffffffc0207cb0 <default_pmm_manager+0x9f8>
ffffffffc020398e:	00003617          	auipc	a2,0x3
ffffffffc0203992:	57a60613          	addi	a2,a2,1402 # ffffffffc0206f08 <commands+0x818>
ffffffffc0203996:	12c00593          	li	a1,300
ffffffffc020399a:	00004517          	auipc	a0,0x4
ffffffffc020399e:	0c650513          	addi	a0,a0,198 # ffffffffc0207a60 <default_pmm_manager+0x7a8>
ffffffffc02039a2:	af1fc0ef          	jal	ra,ffffffffc0200492 <__panic>
ffffffffc02039a6:	03700413          	li	s0,55
    }

    for (i = step1 + 1; i <= step2; i++)
ffffffffc02039aa:	1f900913          	li	s2,505
ffffffffc02039ae:	a819                	j	ffffffffc02039c4 <vmm_init+0xa6>
        vma->vm_start = vm_start;
ffffffffc02039b0:	e500                	sd	s0,8(a0)
        vma->vm_end = vm_end;
ffffffffc02039b2:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc02039b4:	00052c23          	sw	zero,24(a0)
    for (i = step1 + 1; i <= step2; i++)
ffffffffc02039b8:	0415                	addi	s0,s0,5
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc02039ba:	8526                	mv	a0,s1
ffffffffc02039bc:	c81ff0ef          	jal	ra,ffffffffc020363c <insert_vma_struct>
    for (i = step1 + 1; i <= step2; i++)
ffffffffc02039c0:	03240a63          	beq	s0,s2,ffffffffc02039f4 <vmm_init+0xd6>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc02039c4:	03000513          	li	a0,48
ffffffffc02039c8:	9d2fe0ef          	jal	ra,ffffffffc0201b9a <kmalloc>
ffffffffc02039cc:	85aa                	mv	a1,a0
ffffffffc02039ce:	00240793          	addi	a5,s0,2
    if (vma != NULL)
ffffffffc02039d2:	fd79                	bnez	a0,ffffffffc02039b0 <vmm_init+0x92>
        assert(vma != NULL);
ffffffffc02039d4:	00004697          	auipc	a3,0x4
ffffffffc02039d8:	2dc68693          	addi	a3,a3,732 # ffffffffc0207cb0 <default_pmm_manager+0x9f8>
ffffffffc02039dc:	00003617          	auipc	a2,0x3
ffffffffc02039e0:	52c60613          	addi	a2,a2,1324 # ffffffffc0206f08 <commands+0x818>
ffffffffc02039e4:	13300593          	li	a1,307
ffffffffc02039e8:	00004517          	auipc	a0,0x4
ffffffffc02039ec:	07850513          	addi	a0,a0,120 # ffffffffc0207a60 <default_pmm_manager+0x7a8>
ffffffffc02039f0:	aa3fc0ef          	jal	ra,ffffffffc0200492 <__panic>
    return listelm->next;
ffffffffc02039f4:	649c                	ld	a5,8(s1)
ffffffffc02039f6:	471d                	li	a4,7
    }

    list_entry_t *le = list_next(&(mm->mmap_list));

    for (i = 1; i <= step2; i++)
ffffffffc02039f8:	1fb00593          	li	a1,507
    {
        assert(le != &(mm->mmap_list));
ffffffffc02039fc:	16f48663          	beq	s1,a5,ffffffffc0203b68 <vmm_init+0x24a>
        struct vma_struct *mmap = le2vma(le, list_link);
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0203a00:	fe87b603          	ld	a2,-24(a5) # ffffffffffffefe8 <end+0x3fd1f348>
ffffffffc0203a04:	ffe70693          	addi	a3,a4,-2
ffffffffc0203a08:	10d61063          	bne	a2,a3,ffffffffc0203b08 <vmm_init+0x1ea>
ffffffffc0203a0c:	ff07b683          	ld	a3,-16(a5)
ffffffffc0203a10:	0ed71c63          	bne	a4,a3,ffffffffc0203b08 <vmm_init+0x1ea>
    for (i = 1; i <= step2; i++)
ffffffffc0203a14:	0715                	addi	a4,a4,5
ffffffffc0203a16:	679c                	ld	a5,8(a5)
ffffffffc0203a18:	feb712e3          	bne	a4,a1,ffffffffc02039fc <vmm_init+0xde>
ffffffffc0203a1c:	4a1d                	li	s4,7
ffffffffc0203a1e:	4415                	li	s0,5
        le = list_next(le);
    }

    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc0203a20:	1f900a93          	li	s5,505
    {
        struct vma_struct *vma1 = find_vma(mm, i);
ffffffffc0203a24:	85a2                	mv	a1,s0
ffffffffc0203a26:	8526                	mv	a0,s1
ffffffffc0203a28:	bd5ff0ef          	jal	ra,ffffffffc02035fc <find_vma>
ffffffffc0203a2c:	892a                	mv	s2,a0
        assert(vma1 != NULL);
ffffffffc0203a2e:	16050d63          	beqz	a0,ffffffffc0203ba8 <vmm_init+0x28a>
        struct vma_struct *vma2 = find_vma(mm, i + 1);
ffffffffc0203a32:	00140593          	addi	a1,s0,1
ffffffffc0203a36:	8526                	mv	a0,s1
ffffffffc0203a38:	bc5ff0ef          	jal	ra,ffffffffc02035fc <find_vma>
ffffffffc0203a3c:	89aa                	mv	s3,a0
        assert(vma2 != NULL);
ffffffffc0203a3e:	14050563          	beqz	a0,ffffffffc0203b88 <vmm_init+0x26a>
        struct vma_struct *vma3 = find_vma(mm, i + 2);
ffffffffc0203a42:	85d2                	mv	a1,s4
ffffffffc0203a44:	8526                	mv	a0,s1
ffffffffc0203a46:	bb7ff0ef          	jal	ra,ffffffffc02035fc <find_vma>
        assert(vma3 == NULL);
ffffffffc0203a4a:	16051f63          	bnez	a0,ffffffffc0203bc8 <vmm_init+0x2aa>
        struct vma_struct *vma4 = find_vma(mm, i + 3);
ffffffffc0203a4e:	00340593          	addi	a1,s0,3
ffffffffc0203a52:	8526                	mv	a0,s1
ffffffffc0203a54:	ba9ff0ef          	jal	ra,ffffffffc02035fc <find_vma>
        assert(vma4 == NULL);
ffffffffc0203a58:	1a051863          	bnez	a0,ffffffffc0203c08 <vmm_init+0x2ea>
        struct vma_struct *vma5 = find_vma(mm, i + 4);
ffffffffc0203a5c:	00440593          	addi	a1,s0,4
ffffffffc0203a60:	8526                	mv	a0,s1
ffffffffc0203a62:	b9bff0ef          	jal	ra,ffffffffc02035fc <find_vma>
        assert(vma5 == NULL);
ffffffffc0203a66:	18051163          	bnez	a0,ffffffffc0203be8 <vmm_init+0x2ca>

        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc0203a6a:	00893783          	ld	a5,8(s2)
ffffffffc0203a6e:	0a879d63          	bne	a5,s0,ffffffffc0203b28 <vmm_init+0x20a>
ffffffffc0203a72:	01093783          	ld	a5,16(s2)
ffffffffc0203a76:	0b479963          	bne	a5,s4,ffffffffc0203b28 <vmm_init+0x20a>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc0203a7a:	0089b783          	ld	a5,8(s3)
ffffffffc0203a7e:	0c879563          	bne	a5,s0,ffffffffc0203b48 <vmm_init+0x22a>
ffffffffc0203a82:	0109b783          	ld	a5,16(s3)
ffffffffc0203a86:	0d479163          	bne	a5,s4,ffffffffc0203b48 <vmm_init+0x22a>
    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc0203a8a:	0415                	addi	s0,s0,5
ffffffffc0203a8c:	0a15                	addi	s4,s4,5
ffffffffc0203a8e:	f9541be3          	bne	s0,s5,ffffffffc0203a24 <vmm_init+0x106>
ffffffffc0203a92:	4411                	li	s0,4
    }

    for (i = 4; i >= 0; i--)
ffffffffc0203a94:	597d                	li	s2,-1
    {
        struct vma_struct *vma_below_5 = find_vma(mm, i);
ffffffffc0203a96:	85a2                	mv	a1,s0
ffffffffc0203a98:	8526                	mv	a0,s1
ffffffffc0203a9a:	b63ff0ef          	jal	ra,ffffffffc02035fc <find_vma>
ffffffffc0203a9e:	0004059b          	sext.w	a1,s0
        if (vma_below_5 != NULL)
ffffffffc0203aa2:	c90d                	beqz	a0,ffffffffc0203ad4 <vmm_init+0x1b6>
        {
            cprintf("vma_below_5: i %x, start %x, end %x\n", i, vma_below_5->vm_start, vma_below_5->vm_end);
ffffffffc0203aa4:	6914                	ld	a3,16(a0)
ffffffffc0203aa6:	6510                	ld	a2,8(a0)
ffffffffc0203aa8:	00004517          	auipc	a0,0x4
ffffffffc0203aac:	19050513          	addi	a0,a0,400 # ffffffffc0207c38 <default_pmm_manager+0x980>
ffffffffc0203ab0:	ee8fc0ef          	jal	ra,ffffffffc0200198 <cprintf>
        }
        assert(vma_below_5 == NULL);
ffffffffc0203ab4:	00004697          	auipc	a3,0x4
ffffffffc0203ab8:	1ac68693          	addi	a3,a3,428 # ffffffffc0207c60 <default_pmm_manager+0x9a8>
ffffffffc0203abc:	00003617          	auipc	a2,0x3
ffffffffc0203ac0:	44c60613          	addi	a2,a2,1100 # ffffffffc0206f08 <commands+0x818>
ffffffffc0203ac4:	15900593          	li	a1,345
ffffffffc0203ac8:	00004517          	auipc	a0,0x4
ffffffffc0203acc:	f9850513          	addi	a0,a0,-104 # ffffffffc0207a60 <default_pmm_manager+0x7a8>
ffffffffc0203ad0:	9c3fc0ef          	jal	ra,ffffffffc0200492 <__panic>
    for (i = 4; i >= 0; i--)
ffffffffc0203ad4:	147d                	addi	s0,s0,-1
ffffffffc0203ad6:	fd2410e3          	bne	s0,s2,ffffffffc0203a96 <vmm_init+0x178>
    }

    mm_destroy(mm);
ffffffffc0203ada:	8526                	mv	a0,s1
ffffffffc0203adc:	c31ff0ef          	jal	ra,ffffffffc020370c <mm_destroy>

    cprintf("check_vma_struct() succeeded!\n");
ffffffffc0203ae0:	00004517          	auipc	a0,0x4
ffffffffc0203ae4:	19850513          	addi	a0,a0,408 # ffffffffc0207c78 <default_pmm_manager+0x9c0>
ffffffffc0203ae8:	eb0fc0ef          	jal	ra,ffffffffc0200198 <cprintf>
}
ffffffffc0203aec:	7442                	ld	s0,48(sp)
ffffffffc0203aee:	70e2                	ld	ra,56(sp)
ffffffffc0203af0:	74a2                	ld	s1,40(sp)
ffffffffc0203af2:	7902                	ld	s2,32(sp)
ffffffffc0203af4:	69e2                	ld	s3,24(sp)
ffffffffc0203af6:	6a42                	ld	s4,16(sp)
ffffffffc0203af8:	6aa2                	ld	s5,8(sp)
    cprintf("check_vmm() succeeded.\n");
ffffffffc0203afa:	00004517          	auipc	a0,0x4
ffffffffc0203afe:	19e50513          	addi	a0,a0,414 # ffffffffc0207c98 <default_pmm_manager+0x9e0>
}
ffffffffc0203b02:	6121                	addi	sp,sp,64
    cprintf("check_vmm() succeeded.\n");
ffffffffc0203b04:	e94fc06f          	j	ffffffffc0200198 <cprintf>
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0203b08:	00004697          	auipc	a3,0x4
ffffffffc0203b0c:	04868693          	addi	a3,a3,72 # ffffffffc0207b50 <default_pmm_manager+0x898>
ffffffffc0203b10:	00003617          	auipc	a2,0x3
ffffffffc0203b14:	3f860613          	addi	a2,a2,1016 # ffffffffc0206f08 <commands+0x818>
ffffffffc0203b18:	13d00593          	li	a1,317
ffffffffc0203b1c:	00004517          	auipc	a0,0x4
ffffffffc0203b20:	f4450513          	addi	a0,a0,-188 # ffffffffc0207a60 <default_pmm_manager+0x7a8>
ffffffffc0203b24:	96ffc0ef          	jal	ra,ffffffffc0200492 <__panic>
        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc0203b28:	00004697          	auipc	a3,0x4
ffffffffc0203b2c:	0b068693          	addi	a3,a3,176 # ffffffffc0207bd8 <default_pmm_manager+0x920>
ffffffffc0203b30:	00003617          	auipc	a2,0x3
ffffffffc0203b34:	3d860613          	addi	a2,a2,984 # ffffffffc0206f08 <commands+0x818>
ffffffffc0203b38:	14e00593          	li	a1,334
ffffffffc0203b3c:	00004517          	auipc	a0,0x4
ffffffffc0203b40:	f2450513          	addi	a0,a0,-220 # ffffffffc0207a60 <default_pmm_manager+0x7a8>
ffffffffc0203b44:	94ffc0ef          	jal	ra,ffffffffc0200492 <__panic>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc0203b48:	00004697          	auipc	a3,0x4
ffffffffc0203b4c:	0c068693          	addi	a3,a3,192 # ffffffffc0207c08 <default_pmm_manager+0x950>
ffffffffc0203b50:	00003617          	auipc	a2,0x3
ffffffffc0203b54:	3b860613          	addi	a2,a2,952 # ffffffffc0206f08 <commands+0x818>
ffffffffc0203b58:	14f00593          	li	a1,335
ffffffffc0203b5c:	00004517          	auipc	a0,0x4
ffffffffc0203b60:	f0450513          	addi	a0,a0,-252 # ffffffffc0207a60 <default_pmm_manager+0x7a8>
ffffffffc0203b64:	92ffc0ef          	jal	ra,ffffffffc0200492 <__panic>
        assert(le != &(mm->mmap_list));
ffffffffc0203b68:	00004697          	auipc	a3,0x4
ffffffffc0203b6c:	fd068693          	addi	a3,a3,-48 # ffffffffc0207b38 <default_pmm_manager+0x880>
ffffffffc0203b70:	00003617          	auipc	a2,0x3
ffffffffc0203b74:	39860613          	addi	a2,a2,920 # ffffffffc0206f08 <commands+0x818>
ffffffffc0203b78:	13b00593          	li	a1,315
ffffffffc0203b7c:	00004517          	auipc	a0,0x4
ffffffffc0203b80:	ee450513          	addi	a0,a0,-284 # ffffffffc0207a60 <default_pmm_manager+0x7a8>
ffffffffc0203b84:	90ffc0ef          	jal	ra,ffffffffc0200492 <__panic>
        assert(vma2 != NULL);
ffffffffc0203b88:	00004697          	auipc	a3,0x4
ffffffffc0203b8c:	01068693          	addi	a3,a3,16 # ffffffffc0207b98 <default_pmm_manager+0x8e0>
ffffffffc0203b90:	00003617          	auipc	a2,0x3
ffffffffc0203b94:	37860613          	addi	a2,a2,888 # ffffffffc0206f08 <commands+0x818>
ffffffffc0203b98:	14600593          	li	a1,326
ffffffffc0203b9c:	00004517          	auipc	a0,0x4
ffffffffc0203ba0:	ec450513          	addi	a0,a0,-316 # ffffffffc0207a60 <default_pmm_manager+0x7a8>
ffffffffc0203ba4:	8effc0ef          	jal	ra,ffffffffc0200492 <__panic>
        assert(vma1 != NULL);
ffffffffc0203ba8:	00004697          	auipc	a3,0x4
ffffffffc0203bac:	fe068693          	addi	a3,a3,-32 # ffffffffc0207b88 <default_pmm_manager+0x8d0>
ffffffffc0203bb0:	00003617          	auipc	a2,0x3
ffffffffc0203bb4:	35860613          	addi	a2,a2,856 # ffffffffc0206f08 <commands+0x818>
ffffffffc0203bb8:	14400593          	li	a1,324
ffffffffc0203bbc:	00004517          	auipc	a0,0x4
ffffffffc0203bc0:	ea450513          	addi	a0,a0,-348 # ffffffffc0207a60 <default_pmm_manager+0x7a8>
ffffffffc0203bc4:	8cffc0ef          	jal	ra,ffffffffc0200492 <__panic>
        assert(vma3 == NULL);
ffffffffc0203bc8:	00004697          	auipc	a3,0x4
ffffffffc0203bcc:	fe068693          	addi	a3,a3,-32 # ffffffffc0207ba8 <default_pmm_manager+0x8f0>
ffffffffc0203bd0:	00003617          	auipc	a2,0x3
ffffffffc0203bd4:	33860613          	addi	a2,a2,824 # ffffffffc0206f08 <commands+0x818>
ffffffffc0203bd8:	14800593          	li	a1,328
ffffffffc0203bdc:	00004517          	auipc	a0,0x4
ffffffffc0203be0:	e8450513          	addi	a0,a0,-380 # ffffffffc0207a60 <default_pmm_manager+0x7a8>
ffffffffc0203be4:	8affc0ef          	jal	ra,ffffffffc0200492 <__panic>
        assert(vma5 == NULL);
ffffffffc0203be8:	00004697          	auipc	a3,0x4
ffffffffc0203bec:	fe068693          	addi	a3,a3,-32 # ffffffffc0207bc8 <default_pmm_manager+0x910>
ffffffffc0203bf0:	00003617          	auipc	a2,0x3
ffffffffc0203bf4:	31860613          	addi	a2,a2,792 # ffffffffc0206f08 <commands+0x818>
ffffffffc0203bf8:	14c00593          	li	a1,332
ffffffffc0203bfc:	00004517          	auipc	a0,0x4
ffffffffc0203c00:	e6450513          	addi	a0,a0,-412 # ffffffffc0207a60 <default_pmm_manager+0x7a8>
ffffffffc0203c04:	88ffc0ef          	jal	ra,ffffffffc0200492 <__panic>
        assert(vma4 == NULL);
ffffffffc0203c08:	00004697          	auipc	a3,0x4
ffffffffc0203c0c:	fb068693          	addi	a3,a3,-80 # ffffffffc0207bb8 <default_pmm_manager+0x900>
ffffffffc0203c10:	00003617          	auipc	a2,0x3
ffffffffc0203c14:	2f860613          	addi	a2,a2,760 # ffffffffc0206f08 <commands+0x818>
ffffffffc0203c18:	14a00593          	li	a1,330
ffffffffc0203c1c:	00004517          	auipc	a0,0x4
ffffffffc0203c20:	e4450513          	addi	a0,a0,-444 # ffffffffc0207a60 <default_pmm_manager+0x7a8>
ffffffffc0203c24:	86ffc0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(mm != NULL);
ffffffffc0203c28:	00004697          	auipc	a3,0x4
ffffffffc0203c2c:	ec068693          	addi	a3,a3,-320 # ffffffffc0207ae8 <default_pmm_manager+0x830>
ffffffffc0203c30:	00003617          	auipc	a2,0x3
ffffffffc0203c34:	2d860613          	addi	a2,a2,728 # ffffffffc0206f08 <commands+0x818>
ffffffffc0203c38:	12400593          	li	a1,292
ffffffffc0203c3c:	00004517          	auipc	a0,0x4
ffffffffc0203c40:	e2450513          	addi	a0,a0,-476 # ffffffffc0207a60 <default_pmm_manager+0x7a8>
ffffffffc0203c44:	84ffc0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0203c48 <user_mem_check>:
}
bool user_mem_check(struct mm_struct *mm, uintptr_t addr, size_t len, bool write)
{
ffffffffc0203c48:	7179                	addi	sp,sp,-48
ffffffffc0203c4a:	f022                	sd	s0,32(sp)
ffffffffc0203c4c:	f406                	sd	ra,40(sp)
ffffffffc0203c4e:	ec26                	sd	s1,24(sp)
ffffffffc0203c50:	e84a                	sd	s2,16(sp)
ffffffffc0203c52:	e44e                	sd	s3,8(sp)
ffffffffc0203c54:	e052                	sd	s4,0(sp)
ffffffffc0203c56:	842e                	mv	s0,a1
    if (mm != NULL)
ffffffffc0203c58:	c135                	beqz	a0,ffffffffc0203cbc <user_mem_check+0x74>
    {
        if (!USER_ACCESS(addr, addr + len))
ffffffffc0203c5a:	002007b7          	lui	a5,0x200
ffffffffc0203c5e:	04f5e663          	bltu	a1,a5,ffffffffc0203caa <user_mem_check+0x62>
ffffffffc0203c62:	00c584b3          	add	s1,a1,a2
ffffffffc0203c66:	0495f263          	bgeu	a1,s1,ffffffffc0203caa <user_mem_check+0x62>
ffffffffc0203c6a:	4785                	li	a5,1
ffffffffc0203c6c:	07fe                	slli	a5,a5,0x1f
ffffffffc0203c6e:	0297ee63          	bltu	a5,s1,ffffffffc0203caa <user_mem_check+0x62>
ffffffffc0203c72:	892a                	mv	s2,a0
ffffffffc0203c74:	89b6                	mv	s3,a3
            {
                return 0;
            }
            if (write && (vma->vm_flags & VM_STACK))
            {
                if (start < vma->vm_start + PGSIZE)
ffffffffc0203c76:	6a05                	lui	s4,0x1
ffffffffc0203c78:	a821                	j	ffffffffc0203c90 <user_mem_check+0x48>
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203c7a:	0027f693          	andi	a3,a5,2
                if (start < vma->vm_start + PGSIZE)
ffffffffc0203c7e:	9752                	add	a4,a4,s4
            if (write && (vma->vm_flags & VM_STACK))
ffffffffc0203c80:	8ba1                	andi	a5,a5,8
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203c82:	c685                	beqz	a3,ffffffffc0203caa <user_mem_check+0x62>
            if (write && (vma->vm_flags & VM_STACK))
ffffffffc0203c84:	c399                	beqz	a5,ffffffffc0203c8a <user_mem_check+0x42>
                if (start < vma->vm_start + PGSIZE)
ffffffffc0203c86:	02e46263          	bltu	s0,a4,ffffffffc0203caa <user_mem_check+0x62>
                { // check stack start & size
                    return 0;
                }
            }
            start = vma->vm_end;
ffffffffc0203c8a:	6900                	ld	s0,16(a0)
        while (start < end)
ffffffffc0203c8c:	04947663          	bgeu	s0,s1,ffffffffc0203cd8 <user_mem_check+0x90>
            if ((vma = find_vma(mm, start)) == NULL || start < vma->vm_start)
ffffffffc0203c90:	85a2                	mv	a1,s0
ffffffffc0203c92:	854a                	mv	a0,s2
ffffffffc0203c94:	969ff0ef          	jal	ra,ffffffffc02035fc <find_vma>
ffffffffc0203c98:	c909                	beqz	a0,ffffffffc0203caa <user_mem_check+0x62>
ffffffffc0203c9a:	6518                	ld	a4,8(a0)
ffffffffc0203c9c:	00e46763          	bltu	s0,a4,ffffffffc0203caa <user_mem_check+0x62>
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203ca0:	4d1c                	lw	a5,24(a0)
ffffffffc0203ca2:	fc099ce3          	bnez	s3,ffffffffc0203c7a <user_mem_check+0x32>
ffffffffc0203ca6:	8b85                	andi	a5,a5,1
ffffffffc0203ca8:	f3ed                	bnez	a5,ffffffffc0203c8a <user_mem_check+0x42>
            return 0;
ffffffffc0203caa:	4501                	li	a0,0
        }
        return 1;
    }
    return KERN_ACCESS(addr, addr + len);
}
ffffffffc0203cac:	70a2                	ld	ra,40(sp)
ffffffffc0203cae:	7402                	ld	s0,32(sp)
ffffffffc0203cb0:	64e2                	ld	s1,24(sp)
ffffffffc0203cb2:	6942                	ld	s2,16(sp)
ffffffffc0203cb4:	69a2                	ld	s3,8(sp)
ffffffffc0203cb6:	6a02                	ld	s4,0(sp)
ffffffffc0203cb8:	6145                	addi	sp,sp,48
ffffffffc0203cba:	8082                	ret
    return KERN_ACCESS(addr, addr + len);
ffffffffc0203cbc:	c02007b7          	lui	a5,0xc0200
ffffffffc0203cc0:	4501                	li	a0,0
ffffffffc0203cc2:	fef5e5e3          	bltu	a1,a5,ffffffffc0203cac <user_mem_check+0x64>
ffffffffc0203cc6:	962e                	add	a2,a2,a1
ffffffffc0203cc8:	fec5f2e3          	bgeu	a1,a2,ffffffffc0203cac <user_mem_check+0x64>
ffffffffc0203ccc:	c8000537          	lui	a0,0xc8000
ffffffffc0203cd0:	0505                	addi	a0,a0,1
ffffffffc0203cd2:	00a63533          	sltu	a0,a2,a0
ffffffffc0203cd6:	bfd9                	j	ffffffffc0203cac <user_mem_check+0x64>
        return 1;
ffffffffc0203cd8:	4505                	li	a0,1
ffffffffc0203cda:	bfc9                	j	ffffffffc0203cac <user_mem_check+0x64>

ffffffffc0203cdc <phi_test_sema>:

struct proc_struct *philosopher_proc_sema[N];

void phi_test_sema(int i) /* i：哲学家号码从0到N-1 */
{ 
    if(state_sema[i]==HUNGRY&&state_sema[LEFT]!=EATING
ffffffffc0203cdc:	000d8697          	auipc	a3,0xd8
ffffffffc0203ce0:	ee468693          	addi	a3,a3,-284 # ffffffffc02dbbc0 <state_sema>
ffffffffc0203ce4:	00251793          	slli	a5,a0,0x2
ffffffffc0203ce8:	97b6                	add	a5,a5,a3
ffffffffc0203cea:	4390                	lw	a2,0(a5)
ffffffffc0203cec:	4705                	li	a4,1
ffffffffc0203cee:	00e60363          	beq	a2,a4,ffffffffc0203cf4 <phi_test_sema+0x18>
            &&state_sema[RIGHT]!=EATING)
    {
        state_sema[i]=EATING;
        up(&s[i]);
    }
}
ffffffffc0203cf2:	8082                	ret
    if(state_sema[i]==HUNGRY&&state_sema[LEFT]!=EATING
ffffffffc0203cf4:	0045071b          	addiw	a4,a0,4
ffffffffc0203cf8:	4595                	li	a1,5
ffffffffc0203cfa:	02b7673b          	remw	a4,a4,a1
ffffffffc0203cfe:	4609                	li	a2,2
ffffffffc0203d00:	070a                	slli	a4,a4,0x2
ffffffffc0203d02:	9736                	add	a4,a4,a3
ffffffffc0203d04:	4318                	lw	a4,0(a4)
ffffffffc0203d06:	fec706e3          	beq	a4,a2,ffffffffc0203cf2 <phi_test_sema+0x16>
            &&state_sema[RIGHT]!=EATING)
ffffffffc0203d0a:	0015071b          	addiw	a4,a0,1
ffffffffc0203d0e:	02b7673b          	remw	a4,a4,a1
ffffffffc0203d12:	070a                	slli	a4,a4,0x2
ffffffffc0203d14:	96ba                	add	a3,a3,a4
ffffffffc0203d16:	4298                	lw	a4,0(a3)
ffffffffc0203d18:	fcc70de3          	beq	a4,a2,ffffffffc0203cf2 <phi_test_sema+0x16>
        up(&s[i]);
ffffffffc0203d1c:	00151713          	slli	a4,a0,0x1
ffffffffc0203d20:	953a                	add	a0,a0,a4
ffffffffc0203d22:	050e                	slli	a0,a0,0x3
ffffffffc0203d24:	000d8717          	auipc	a4,0xd8
ffffffffc0203d28:	e0c70713          	addi	a4,a4,-500 # ffffffffc02dbb30 <s>
ffffffffc0203d2c:	953a                	add	a0,a0,a4
        state_sema[i]=EATING;
ffffffffc0203d2e:	c390                	sw	a2,0(a5)
        up(&s[i]);
ffffffffc0203d30:	7800006f          	j	ffffffffc02044b0 <up>

ffffffffc0203d34 <philosopher_using_semaphore>:
        phi_test_sema(RIGHT); /* 看一下右邻居现在是否能进餐 */
        up(&mutex); /* 离开临界区 */
}

int philosopher_using_semaphore(void * arg) /* i：哲学家号码，从0到N-1 */
{
ffffffffc0203d34:	711d                	addi	sp,sp,-96
ffffffffc0203d36:	e8a2                	sd	s0,80(sp)
    int i, iter=0;
    i=(int)arg;
ffffffffc0203d38:	0005041b          	sext.w	s0,a0
    cprintf("I am No.%d philosopher_sema\n",i);
ffffffffc0203d3c:	85a2                	mv	a1,s0
ffffffffc0203d3e:	00004517          	auipc	a0,0x4
ffffffffc0203d42:	f8250513          	addi	a0,a0,-126 # ffffffffc0207cc0 <default_pmm_manager+0xa08>
{
ffffffffc0203d46:	e4a6                	sd	s1,72(sp)
ffffffffc0203d48:	e0ca                	sd	s2,64(sp)
ffffffffc0203d4a:	fc4e                	sd	s3,56(sp)
ffffffffc0203d4c:	f852                	sd	s4,48(sp)
ffffffffc0203d4e:	f456                	sd	s5,40(sp)
ffffffffc0203d50:	f05a                	sd	s6,32(sp)
ffffffffc0203d52:	ec5e                	sd	s7,24(sp)
ffffffffc0203d54:	e862                	sd	s8,16(sp)
ffffffffc0203d56:	e466                	sd	s9,8(sp)
ffffffffc0203d58:	e06a                	sd	s10,0(sp)
ffffffffc0203d5a:	ec86                	sd	ra,88(sp)
    cprintf("I am No.%d philosopher_sema\n",i);
ffffffffc0203d5c:	c3cfc0ef          	jal	ra,ffffffffc0200198 <cprintf>
        phi_test_sema(LEFT); /* 看一下左邻居现在是否能进餐 */
ffffffffc0203d60:	4715                	li	a4,5
ffffffffc0203d62:	00440b1b          	addiw	s6,s0,4
        phi_test_sema(RIGHT); /* 看一下右邻居现在是否能进餐 */
ffffffffc0203d66:	00140a1b          	addiw	s4,s0,1
        phi_test_sema(LEFT); /* 看一下左邻居现在是否能进餐 */
ffffffffc0203d6a:	02eb6b3b          	remw	s6,s6,a4
        down(&s[i]); /* 如果得不到叉子就阻塞 */
ffffffffc0203d6e:	00141a93          	slli	s5,s0,0x1
ffffffffc0203d72:	9aa2                	add	s5,s5,s0
ffffffffc0203d74:	003a9793          	slli	a5,s5,0x3
ffffffffc0203d78:	00241693          	slli	a3,s0,0x2
ffffffffc0203d7c:	000d8a97          	auipc	s5,0xd8
ffffffffc0203d80:	db4a8a93          	addi	s5,s5,-588 # ffffffffc02dbb30 <s>
        state_sema[i]=HUNGRY; /* 记录下哲学家i饥饿的事实 */
ffffffffc0203d84:	000d8997          	auipc	s3,0xd8
ffffffffc0203d88:	e3c98993          	addi	s3,s3,-452 # ffffffffc02dbbc0 <state_sema>
        down(&s[i]); /* 如果得不到叉子就阻塞 */
ffffffffc0203d8c:	9abe                	add	s5,s5,a5
    while(iter++<TIMES)
ffffffffc0203d8e:	4485                	li	s1,1
    { /* 无限循环 */
        cprintf("Iter %d, No.%d philosopher_sema is thinking\n",iter,i); /* 哲学家正在思考 */
ffffffffc0203d90:	00004d17          	auipc	s10,0x4
ffffffffc0203d94:	f50d0d13          	addi	s10,s10,-176 # ffffffffc0207ce0 <default_pmm_manager+0xa28>
        down(&mutex); /* 进入临界区 */
ffffffffc0203d98:	000d8917          	auipc	s2,0xd8
ffffffffc0203d9c:	d3090913          	addi	s2,s2,-720 # ffffffffc02dbac8 <mutex>
        state_sema[i]=HUNGRY; /* 记录下哲学家i饥饿的事实 */
ffffffffc0203da0:	99b6                	add	s3,s3,a3
ffffffffc0203da2:	4c85                	li	s9,1
        do_sleep(SLEEP_TIME);
        phi_take_forks_sema(i); 
        /* 需要两只叉子，或者阻塞 */
        cprintf("Iter %d, No.%d philosopher_sema is eating\n",iter,i); /* 进餐 */
ffffffffc0203da4:	00004c17          	auipc	s8,0x4
ffffffffc0203da8:	f6cc0c13          	addi	s8,s8,-148 # ffffffffc0207d10 <default_pmm_manager+0xa58>
    while(iter++<TIMES)
ffffffffc0203dac:	4b95                	li	s7,5
        phi_test_sema(RIGHT); /* 看一下右邻居现在是否能进餐 */
ffffffffc0203dae:	02ea6a3b          	remw	s4,s4,a4
        cprintf("Iter %d, No.%d philosopher_sema is thinking\n",iter,i); /* 哲学家正在思考 */
ffffffffc0203db2:	85a6                	mv	a1,s1
ffffffffc0203db4:	8622                	mv	a2,s0
ffffffffc0203db6:	856a                	mv	a0,s10
ffffffffc0203db8:	be0fc0ef          	jal	ra,ffffffffc0200198 <cprintf>
        do_sleep(SLEEP_TIME);
ffffffffc0203dbc:	4529                	li	a0,10
ffffffffc0203dbe:	30f010ef          	jal	ra,ffffffffc02058cc <do_sleep>
        down(&mutex); /* 进入临界区 */
ffffffffc0203dc2:	854a                	mv	a0,s2
ffffffffc0203dc4:	6f0000ef          	jal	ra,ffffffffc02044b4 <down>
        phi_test_sema(i); /* 试图得到两只叉子 */
ffffffffc0203dc8:	8522                	mv	a0,s0
        state_sema[i]=HUNGRY; /* 记录下哲学家i饥饿的事实 */
ffffffffc0203dca:	0199a023          	sw	s9,0(s3)
        phi_test_sema(i); /* 试图得到两只叉子 */
ffffffffc0203dce:	f0fff0ef          	jal	ra,ffffffffc0203cdc <phi_test_sema>
        up(&mutex); /* 离开临界区 */
ffffffffc0203dd2:	854a                	mv	a0,s2
ffffffffc0203dd4:	6dc000ef          	jal	ra,ffffffffc02044b0 <up>
        down(&s[i]); /* 如果得不到叉子就阻塞 */
ffffffffc0203dd8:	8556                	mv	a0,s5
ffffffffc0203dda:	6da000ef          	jal	ra,ffffffffc02044b4 <down>
        cprintf("Iter %d, No.%d philosopher_sema is eating\n",iter,i); /* 进餐 */
ffffffffc0203dde:	85a6                	mv	a1,s1
ffffffffc0203de0:	8622                	mv	a2,s0
ffffffffc0203de2:	8562                	mv	a0,s8
ffffffffc0203de4:	bb4fc0ef          	jal	ra,ffffffffc0200198 <cprintf>
        do_sleep(SLEEP_TIME);
ffffffffc0203de8:	4529                	li	a0,10
ffffffffc0203dea:	2e3010ef          	jal	ra,ffffffffc02058cc <do_sleep>
        down(&mutex); /* 进入临界区 */
ffffffffc0203dee:	854a                	mv	a0,s2
ffffffffc0203df0:	6c4000ef          	jal	ra,ffffffffc02044b4 <down>
        phi_test_sema(LEFT); /* 看一下左邻居现在是否能进餐 */
ffffffffc0203df4:	855a                	mv	a0,s6
        state_sema[i]=THINKING; /* 哲学家进餐结束 */
ffffffffc0203df6:	0009a023          	sw	zero,0(s3)
        phi_test_sema(LEFT); /* 看一下左邻居现在是否能进餐 */
ffffffffc0203dfa:	ee3ff0ef          	jal	ra,ffffffffc0203cdc <phi_test_sema>
        phi_test_sema(RIGHT); /* 看一下右邻居现在是否能进餐 */
ffffffffc0203dfe:	8552                	mv	a0,s4
ffffffffc0203e00:	eddff0ef          	jal	ra,ffffffffc0203cdc <phi_test_sema>
    while(iter++<TIMES)
ffffffffc0203e04:	2485                	addiw	s1,s1,1
        up(&mutex); /* 离开临界区 */
ffffffffc0203e06:	854a                	mv	a0,s2
ffffffffc0203e08:	6a8000ef          	jal	ra,ffffffffc02044b0 <up>
    while(iter++<TIMES)
ffffffffc0203e0c:	fb7493e3          	bne	s1,s7,ffffffffc0203db2 <philosopher_using_semaphore+0x7e>
        phi_put_forks_sema(i); 
        /* 把两把叉子同时放回桌子 */
    }
    cprintf("No.%d philosopher_sema quit\n",i);
ffffffffc0203e10:	85a2                	mv	a1,s0
ffffffffc0203e12:	00004517          	auipc	a0,0x4
ffffffffc0203e16:	f2e50513          	addi	a0,a0,-210 # ffffffffc0207d40 <default_pmm_manager+0xa88>
ffffffffc0203e1a:	b7efc0ef          	jal	ra,ffffffffc0200198 <cprintf>
    return 0;    
}
ffffffffc0203e1e:	60e6                	ld	ra,88(sp)
ffffffffc0203e20:	6446                	ld	s0,80(sp)
ffffffffc0203e22:	64a6                	ld	s1,72(sp)
ffffffffc0203e24:	6906                	ld	s2,64(sp)
ffffffffc0203e26:	79e2                	ld	s3,56(sp)
ffffffffc0203e28:	7a42                	ld	s4,48(sp)
ffffffffc0203e2a:	7aa2                	ld	s5,40(sp)
ffffffffc0203e2c:	7b02                	ld	s6,32(sp)
ffffffffc0203e2e:	6be2                	ld	s7,24(sp)
ffffffffc0203e30:	6c42                	ld	s8,16(sp)
ffffffffc0203e32:	6ca2                	ld	s9,8(sp)
ffffffffc0203e34:	6d02                	ld	s10,0(sp)
ffffffffc0203e36:	4501                	li	a0,0
ffffffffc0203e38:	6125                	addi	sp,sp,96
ffffffffc0203e3a:	8082                	ret

ffffffffc0203e3c <phi_test_condvar>:

struct proc_struct *philosopher_proc_condvar[N]; // N philosopher
int state_condvar[N];                            // the philosopher's state: EATING, HUNGARY, THINKING  
monitor_t mt, *mtp=&mt;                          // monitor

void phi_test_condvar (int i) { 
ffffffffc0203e3c:	7179                	addi	sp,sp,-48
ffffffffc0203e3e:	ec26                	sd	s1,24(sp)
    if(state_condvar[i]==HUNGRY&&state_condvar[LEFT]!=EATING
ffffffffc0203e40:	000d8717          	auipc	a4,0xd8
ffffffffc0203e44:	d6870713          	addi	a4,a4,-664 # ffffffffc02dbba8 <state_condvar>
ffffffffc0203e48:	00251493          	slli	s1,a0,0x2
void phi_test_condvar (int i) { 
ffffffffc0203e4c:	e84a                	sd	s2,16(sp)
    if(state_condvar[i]==HUNGRY&&state_condvar[LEFT]!=EATING
ffffffffc0203e4e:	00970933          	add	s2,a4,s1
ffffffffc0203e52:	00092683          	lw	a3,0(s2)
void phi_test_condvar (int i) { 
ffffffffc0203e56:	f406                	sd	ra,40(sp)
ffffffffc0203e58:	f022                	sd	s0,32(sp)
ffffffffc0203e5a:	e44e                	sd	s3,8(sp)
    if(state_condvar[i]==HUNGRY&&state_condvar[LEFT]!=EATING
ffffffffc0203e5c:	4785                	li	a5,1
ffffffffc0203e5e:	00f68963          	beq	a3,a5,ffffffffc0203e70 <phi_test_condvar+0x34>
        cprintf("phi_test_condvar: state_condvar[%d] will eating\n",i);
        state_condvar[i] = EATING ;
        cprintf("phi_test_condvar: signal self_cv[%d] \n",i);
        cond_signal(&mtp->cv[i]) ;
    }
}
ffffffffc0203e62:	70a2                	ld	ra,40(sp)
ffffffffc0203e64:	7402                	ld	s0,32(sp)
ffffffffc0203e66:	64e2                	ld	s1,24(sp)
ffffffffc0203e68:	6942                	ld	s2,16(sp)
ffffffffc0203e6a:	69a2                	ld	s3,8(sp)
ffffffffc0203e6c:	6145                	addi	sp,sp,48
ffffffffc0203e6e:	8082                	ret
    if(state_condvar[i]==HUNGRY&&state_condvar[LEFT]!=EATING
ffffffffc0203e70:	0045079b          	addiw	a5,a0,4
ffffffffc0203e74:	4695                	li	a3,5
ffffffffc0203e76:	02d7e7bb          	remw	a5,a5,a3
ffffffffc0203e7a:	4989                	li	s3,2
ffffffffc0203e7c:	842a                	mv	s0,a0
ffffffffc0203e7e:	078a                	slli	a5,a5,0x2
ffffffffc0203e80:	97ba                	add	a5,a5,a4
ffffffffc0203e82:	439c                	lw	a5,0(a5)
ffffffffc0203e84:	fd378fe3          	beq	a5,s3,ffffffffc0203e62 <phi_test_condvar+0x26>
            &&state_condvar[RIGHT]!=EATING) {
ffffffffc0203e88:	0015079b          	addiw	a5,a0,1
ffffffffc0203e8c:	02d7e7bb          	remw	a5,a5,a3
ffffffffc0203e90:	078a                	slli	a5,a5,0x2
ffffffffc0203e92:	973e                	add	a4,a4,a5
ffffffffc0203e94:	431c                	lw	a5,0(a4)
ffffffffc0203e96:	fd3786e3          	beq	a5,s3,ffffffffc0203e62 <phi_test_condvar+0x26>
        cprintf("phi_test_condvar: state_condvar[%d] will eating\n",i);
ffffffffc0203e9a:	85aa                	mv	a1,a0
ffffffffc0203e9c:	00004517          	auipc	a0,0x4
ffffffffc0203ea0:	ec450513          	addi	a0,a0,-316 # ffffffffc0207d60 <default_pmm_manager+0xaa8>
ffffffffc0203ea4:	af4fc0ef          	jal	ra,ffffffffc0200198 <cprintf>
        cprintf("phi_test_condvar: signal self_cv[%d] \n",i);
ffffffffc0203ea8:	85a2                	mv	a1,s0
        state_condvar[i] = EATING ;
ffffffffc0203eaa:	01392023          	sw	s3,0(s2)
        cprintf("phi_test_condvar: signal self_cv[%d] \n",i);
ffffffffc0203eae:	00004517          	auipc	a0,0x4
ffffffffc0203eb2:	eea50513          	addi	a0,a0,-278 # ffffffffc0207d98 <default_pmm_manager+0xae0>
ffffffffc0203eb6:	ae2fc0ef          	jal	ra,ffffffffc0200198 <cprintf>
        cond_signal(&mtp->cv[i]) ;
ffffffffc0203eba:	000d7797          	auipc	a5,0xd7
ffffffffc0203ebe:	7a67b783          	ld	a5,1958(a5) # ffffffffc02db660 <mtp>
ffffffffc0203ec2:	7f88                	ld	a0,56(a5)
ffffffffc0203ec4:	9426                	add	s0,s0,s1
ffffffffc0203ec6:	040e                	slli	s0,s0,0x3
ffffffffc0203ec8:	9522                	add	a0,a0,s0
}
ffffffffc0203eca:	7402                	ld	s0,32(sp)
ffffffffc0203ecc:	70a2                	ld	ra,40(sp)
ffffffffc0203ece:	64e2                	ld	s1,24(sp)
ffffffffc0203ed0:	6942                	ld	s2,16(sp)
ffffffffc0203ed2:	69a2                	ld	s3,8(sp)
ffffffffc0203ed4:	6145                	addi	sp,sp,48
        cond_signal(&mtp->cv[i]) ;
ffffffffc0203ed6:	a6c9                	j	ffffffffc0204298 <cond_signal>

ffffffffc0203ed8 <phi_take_forks_condvar>:

void phi_take_forks_condvar(int i) {
ffffffffc0203ed8:	7139                	addi	sp,sp,-64
ffffffffc0203eda:	ec4e                	sd	s3,24(sp)
     down(&(mtp->mutex));
ffffffffc0203edc:	000d7997          	auipc	s3,0xd7
ffffffffc0203ee0:	78498993          	addi	s3,s3,1924 # ffffffffc02db660 <mtp>
void phi_take_forks_condvar(int i) {
ffffffffc0203ee4:	f822                	sd	s0,48(sp)
ffffffffc0203ee6:	842a                	mv	s0,a0
     down(&(mtp->mutex));
ffffffffc0203ee8:	0009b503          	ld	a0,0(s3)
void phi_take_forks_condvar(int i) {
ffffffffc0203eec:	fc06                	sd	ra,56(sp)
ffffffffc0203eee:	f426                	sd	s1,40(sp)
ffffffffc0203ef0:	f04a                	sd	s2,32(sp)
ffffffffc0203ef2:	e852                	sd	s4,16(sp)
ffffffffc0203ef4:	e456                	sd	s5,8(sp)
//--------into routine in monitor--------------
    // LAB7 EXERCISE1: YOUR CODE

    // 记录哲学家 i 饥饿的事实
    state_condvar[i] = HUNGRY;
ffffffffc0203ef6:	00241493          	slli	s1,s0,0x2
     down(&(mtp->mutex));
ffffffffc0203efa:	5ba000ef          	jal	ra,ffffffffc02044b4 <down>
    state_condvar[i] = HUNGRY;
ffffffffc0203efe:	000d8917          	auipc	s2,0xd8
ffffffffc0203f02:	caa90913          	addi	s2,s2,-854 # ffffffffc02dbba8 <state_condvar>
ffffffffc0203f06:	4785                	li	a5,1
ffffffffc0203f08:	9926                	add	s2,s2,s1
ffffffffc0203f0a:	00f92023          	sw	a5,0(s2)
     
    // 尝试获取两把叉子
    phi_test_condvar(i);
ffffffffc0203f0e:	8522                	mv	a0,s0
ffffffffc0203f10:	f2dff0ef          	jal	ra,ffffffffc0203e3c <phi_test_condvar>
     
    // 如果获取失败，则等待条件变量
    while (state_condvar[i] != EATING) {
ffffffffc0203f14:	00092703          	lw	a4,0(s2)
ffffffffc0203f18:	4789                	li	a5,2
ffffffffc0203f1a:	02f70763          	beq	a4,a5,ffffffffc0203f48 <phi_take_forks_condvar+0x70>
        cprintf("phi_take_forks_condvar: %d didn't get fork and will wait\n", i);
        cond_wait(&mtp->cv[i]);
ffffffffc0203f1e:	94a2                	add	s1,s1,s0
ffffffffc0203f20:	048e                	slli	s1,s1,0x3
        cprintf("phi_take_forks_condvar: %d didn't get fork and will wait\n", i);
ffffffffc0203f22:	00004a97          	auipc	s5,0x4
ffffffffc0203f26:	e9ea8a93          	addi	s5,s5,-354 # ffffffffc0207dc0 <default_pmm_manager+0xb08>
    while (state_condvar[i] != EATING) {
ffffffffc0203f2a:	4a09                	li	s4,2
        cprintf("phi_take_forks_condvar: %d didn't get fork and will wait\n", i);
ffffffffc0203f2c:	85a2                	mv	a1,s0
ffffffffc0203f2e:	8556                	mv	a0,s5
ffffffffc0203f30:	a68fc0ef          	jal	ra,ffffffffc0200198 <cprintf>
        cond_wait(&mtp->cv[i]);
ffffffffc0203f34:	0009b783          	ld	a5,0(s3)
ffffffffc0203f38:	7f88                	ld	a0,56(a5)
ffffffffc0203f3a:	9526                	add	a0,a0,s1
ffffffffc0203f3c:	3cc000ef          	jal	ra,ffffffffc0204308 <cond_wait>
    while (state_condvar[i] != EATING) {
ffffffffc0203f40:	00092783          	lw	a5,0(s2)
ffffffffc0203f44:	ff4794e3          	bne	a5,s4,ffffffffc0203f2c <phi_take_forks_condvar+0x54>
    }
    
//--------leave routine in monitor--------------
      if(mtp->next_count>0)
ffffffffc0203f48:	0009b503          	ld	a0,0(s3)
ffffffffc0203f4c:	591c                	lw	a5,48(a0)
ffffffffc0203f4e:	00f05363          	blez	a5,ffffffffc0203f54 <phi_take_forks_condvar+0x7c>
         up(&(mtp->next));
ffffffffc0203f52:	0561                	addi	a0,a0,24
      else
         up(&(mtp->mutex));
}
ffffffffc0203f54:	7442                	ld	s0,48(sp)
ffffffffc0203f56:	70e2                	ld	ra,56(sp)
ffffffffc0203f58:	74a2                	ld	s1,40(sp)
ffffffffc0203f5a:	7902                	ld	s2,32(sp)
ffffffffc0203f5c:	69e2                	ld	s3,24(sp)
ffffffffc0203f5e:	6a42                	ld	s4,16(sp)
ffffffffc0203f60:	6aa2                	ld	s5,8(sp)
ffffffffc0203f62:	6121                	addi	sp,sp,64
         up(&(mtp->mutex));
ffffffffc0203f64:	a3b1                	j	ffffffffc02044b0 <up>

ffffffffc0203f66 <phi_put_forks_condvar>:

void phi_put_forks_condvar(int i) {
ffffffffc0203f66:	1101                	addi	sp,sp,-32
ffffffffc0203f68:	e426                	sd	s1,8(sp)
     down(&(mtp->mutex));
ffffffffc0203f6a:	000d7497          	auipc	s1,0xd7
ffffffffc0203f6e:	6f648493          	addi	s1,s1,1782 # ffffffffc02db660 <mtp>
void phi_put_forks_condvar(int i) {
ffffffffc0203f72:	e822                	sd	s0,16(sp)
ffffffffc0203f74:	842a                	mv	s0,a0
     down(&(mtp->mutex));
ffffffffc0203f76:	6088                	ld	a0,0(s1)
void phi_put_forks_condvar(int i) {
ffffffffc0203f78:	ec06                	sd	ra,24(sp)
ffffffffc0203f7a:	e04a                	sd	s2,0(sp)
     down(&(mtp->mutex));
ffffffffc0203f7c:	538000ef          	jal	ra,ffffffffc02044b4 <down>

    // 哲学家 i 吃完，进入思考状态
    state_condvar[i] = THINKING;
     
    // 测试左邻居是否能进餐
    phi_test_condvar(LEFT);
ffffffffc0203f80:	4915                	li	s2,5
ffffffffc0203f82:	0044051b          	addiw	a0,s0,4
ffffffffc0203f86:	0325653b          	remw	a0,a0,s2
    state_condvar[i] = THINKING;
ffffffffc0203f8a:	00241713          	slli	a4,s0,0x2
ffffffffc0203f8e:	000d8797          	auipc	a5,0xd8
ffffffffc0203f92:	c1a78793          	addi	a5,a5,-998 # ffffffffc02dbba8 <state_condvar>
ffffffffc0203f96:	97ba                	add	a5,a5,a4
ffffffffc0203f98:	0007a023          	sw	zero,0(a5)
    phi_test_condvar(LEFT);
ffffffffc0203f9c:	ea1ff0ef          	jal	ra,ffffffffc0203e3c <phi_test_condvar>
     
    // 测试右邻居是否能进餐
    phi_test_condvar(RIGHT);
ffffffffc0203fa0:	0014051b          	addiw	a0,s0,1
ffffffffc0203fa4:	0325653b          	remw	a0,a0,s2
ffffffffc0203fa8:	e95ff0ef          	jal	ra,ffffffffc0203e3c <phi_test_condvar>
    
//--------leave routine in monitor--------------
     if(mtp->next_count>0)
ffffffffc0203fac:	6088                	ld	a0,0(s1)
ffffffffc0203fae:	591c                	lw	a5,48(a0)
ffffffffc0203fb0:	00f05363          	blez	a5,ffffffffc0203fb6 <phi_put_forks_condvar+0x50>
        up(&(mtp->next));
ffffffffc0203fb4:	0561                	addi	a0,a0,24
     else
        up(&(mtp->mutex));
}
ffffffffc0203fb6:	6442                	ld	s0,16(sp)
ffffffffc0203fb8:	60e2                	ld	ra,24(sp)
ffffffffc0203fba:	64a2                	ld	s1,8(sp)
ffffffffc0203fbc:	6902                	ld	s2,0(sp)
ffffffffc0203fbe:	6105                	addi	sp,sp,32
        up(&(mtp->mutex));
ffffffffc0203fc0:	a9c5                	j	ffffffffc02044b0 <up>

ffffffffc0203fc2 <philosopher_using_condvar>:

//---------- philosophers using monitor (condition variable) ----------------------
int philosopher_using_condvar(void * arg) { /* arg is the No. of philosopher 0~N-1*/
ffffffffc0203fc2:	7179                	addi	sp,sp,-48
ffffffffc0203fc4:	f022                	sd	s0,32(sp)
  
    int i, iter=0;
    i=(int)arg;
ffffffffc0203fc6:	0005041b          	sext.w	s0,a0
    cprintf("I am No.%d philosopher_condvar\n",i);
ffffffffc0203fca:	85a2                	mv	a1,s0
ffffffffc0203fcc:	00004517          	auipc	a0,0x4
ffffffffc0203fd0:	e3450513          	addi	a0,a0,-460 # ffffffffc0207e00 <default_pmm_manager+0xb48>
int philosopher_using_condvar(void * arg) { /* arg is the No. of philosopher 0~N-1*/
ffffffffc0203fd4:	ec26                	sd	s1,24(sp)
ffffffffc0203fd6:	e84a                	sd	s2,16(sp)
ffffffffc0203fd8:	e44e                	sd	s3,8(sp)
ffffffffc0203fda:	e052                	sd	s4,0(sp)
ffffffffc0203fdc:	f406                	sd	ra,40(sp)
    while(iter++<TIMES)
ffffffffc0203fde:	4485                	li	s1,1
    cprintf("I am No.%d philosopher_condvar\n",i);
ffffffffc0203fe0:	9b8fc0ef          	jal	ra,ffffffffc0200198 <cprintf>
    { /* iterate*/
        cprintf("Iter %d, No.%d philosopher_condvar is thinking\n",iter,i); /* thinking*/
ffffffffc0203fe4:	00004a17          	auipc	s4,0x4
ffffffffc0203fe8:	e3ca0a13          	addi	s4,s4,-452 # ffffffffc0207e20 <default_pmm_manager+0xb68>
        do_sleep(SLEEP_TIME);
        phi_take_forks_condvar(i); 
        /* need two forks, maybe blocked */
        cprintf("Iter %d, No.%d philosopher_condvar is eating\n",iter,i); /* eating*/
ffffffffc0203fec:	00004997          	auipc	s3,0x4
ffffffffc0203ff0:	e6498993          	addi	s3,s3,-412 # ffffffffc0207e50 <default_pmm_manager+0xb98>
    while(iter++<TIMES)
ffffffffc0203ff4:	4915                	li	s2,5
        cprintf("Iter %d, No.%d philosopher_condvar is thinking\n",iter,i); /* thinking*/
ffffffffc0203ff6:	85a6                	mv	a1,s1
ffffffffc0203ff8:	8622                	mv	a2,s0
ffffffffc0203ffa:	8552                	mv	a0,s4
ffffffffc0203ffc:	99cfc0ef          	jal	ra,ffffffffc0200198 <cprintf>
        do_sleep(SLEEP_TIME);
ffffffffc0204000:	4529                	li	a0,10
ffffffffc0204002:	0cb010ef          	jal	ra,ffffffffc02058cc <do_sleep>
        phi_take_forks_condvar(i); 
ffffffffc0204006:	8522                	mv	a0,s0
ffffffffc0204008:	ed1ff0ef          	jal	ra,ffffffffc0203ed8 <phi_take_forks_condvar>
        cprintf("Iter %d, No.%d philosopher_condvar is eating\n",iter,i); /* eating*/
ffffffffc020400c:	85a6                	mv	a1,s1
ffffffffc020400e:	8622                	mv	a2,s0
ffffffffc0204010:	854e                	mv	a0,s3
ffffffffc0204012:	986fc0ef          	jal	ra,ffffffffc0200198 <cprintf>
        do_sleep(SLEEP_TIME);
ffffffffc0204016:	4529                	li	a0,10
ffffffffc0204018:	0b5010ef          	jal	ra,ffffffffc02058cc <do_sleep>
    while(iter++<TIMES)
ffffffffc020401c:	2485                	addiw	s1,s1,1
        phi_put_forks_condvar(i); 
ffffffffc020401e:	8522                	mv	a0,s0
ffffffffc0204020:	f47ff0ef          	jal	ra,ffffffffc0203f66 <phi_put_forks_condvar>
    while(iter++<TIMES)
ffffffffc0204024:	fd2499e3          	bne	s1,s2,ffffffffc0203ff6 <philosopher_using_condvar+0x34>
        /* return two forks back*/
    }
    cprintf("No.%d philosopher_condvar quit\n",i);
ffffffffc0204028:	85a2                	mv	a1,s0
ffffffffc020402a:	00004517          	auipc	a0,0x4
ffffffffc020402e:	e5650513          	addi	a0,a0,-426 # ffffffffc0207e80 <default_pmm_manager+0xbc8>
ffffffffc0204032:	966fc0ef          	jal	ra,ffffffffc0200198 <cprintf>
    return 0;    
}
ffffffffc0204036:	70a2                	ld	ra,40(sp)
ffffffffc0204038:	7402                	ld	s0,32(sp)
ffffffffc020403a:	64e2                	ld	s1,24(sp)
ffffffffc020403c:	6942                	ld	s2,16(sp)
ffffffffc020403e:	69a2                	ld	s3,8(sp)
ffffffffc0204040:	6a02                	ld	s4,0(sp)
ffffffffc0204042:	4501                	li	a0,0
ffffffffc0204044:	6145                	addi	sp,sp,48
ffffffffc0204046:	8082                	ret

ffffffffc0204048 <check_sync>:

void check_sync(void){
ffffffffc0204048:	7159                	addi	sp,sp,-112
ffffffffc020404a:	f0a2                	sd	s0,96(sp)

    int i, pids[N];

    //check semaphore
    sem_init(&mutex, 1);
ffffffffc020404c:	4585                	li	a1,1
ffffffffc020404e:	000d8517          	auipc	a0,0xd8
ffffffffc0204052:	a7a50513          	addi	a0,a0,-1414 # ffffffffc02dbac8 <mutex>
ffffffffc0204056:	0020                	addi	s0,sp,8
void check_sync(void){
ffffffffc0204058:	eca6                	sd	s1,88(sp)
ffffffffc020405a:	e8ca                	sd	s2,80(sp)
ffffffffc020405c:	e4ce                	sd	s3,72(sp)
ffffffffc020405e:	e0d2                	sd	s4,64(sp)
ffffffffc0204060:	fc56                	sd	s5,56(sp)
ffffffffc0204062:	f85a                	sd	s6,48(sp)
ffffffffc0204064:	f45e                	sd	s7,40(sp)
ffffffffc0204066:	f486                	sd	ra,104(sp)
ffffffffc0204068:	f062                	sd	s8,32(sp)
ffffffffc020406a:	000d8a17          	auipc	s4,0xd8
ffffffffc020406e:	ac6a0a13          	addi	s4,s4,-1338 # ffffffffc02dbb30 <s>
    sem_init(&mutex, 1);
ffffffffc0204072:	438000ef          	jal	ra,ffffffffc02044aa <sem_init>
    for(i=0;i<N;i++){
ffffffffc0204076:	000d8997          	auipc	s3,0xd8
ffffffffc020407a:	a9298993          	addi	s3,s3,-1390 # ffffffffc02dbb08 <philosopher_proc_sema>
    sem_init(&mutex, 1);
ffffffffc020407e:	8922                	mv	s2,s0
ffffffffc0204080:	4481                	li	s1,0
        sem_init(&s[i], 0);
        int pid = kernel_thread(philosopher_using_semaphore, (void *)i, 0);
ffffffffc0204082:	00000b97          	auipc	s7,0x0
ffffffffc0204086:	cb2b8b93          	addi	s7,s7,-846 # ffffffffc0203d34 <philosopher_using_semaphore>
        if (pid <= 0) {
            panic("create No.%d philosopher_using_semaphore failed.\n");
        }
        pids[i] = pid;
        philosopher_proc_sema[i] = find_proc(pid);
        set_proc_name(philosopher_proc_sema[i], "philosopher_sema_proc");
ffffffffc020408a:	00004b17          	auipc	s6,0x4
ffffffffc020408e:	e66b0b13          	addi	s6,s6,-410 # ffffffffc0207ef0 <default_pmm_manager+0xc38>
    for(i=0;i<N;i++){
ffffffffc0204092:	4a95                	li	s5,5
        sem_init(&s[i], 0);
ffffffffc0204094:	4581                	li	a1,0
ffffffffc0204096:	8552                	mv	a0,s4
ffffffffc0204098:	412000ef          	jal	ra,ffffffffc02044aa <sem_init>
        int pid = kernel_thread(philosopher_using_semaphore, (void *)i, 0);
ffffffffc020409c:	4601                	li	a2,0
ffffffffc020409e:	85a6                	mv	a1,s1
ffffffffc02040a0:	855e                	mv	a0,s7
ffffffffc02040a2:	32f000ef          	jal	ra,ffffffffc0204bd0 <kernel_thread>
        if (pid <= 0) {
ffffffffc02040a6:	0ca05863          	blez	a0,ffffffffc0204176 <check_sync+0x12e>
        pids[i] = pid;
ffffffffc02040aa:	00a92023          	sw	a0,0(s2)
        philosopher_proc_sema[i] = find_proc(pid);
ffffffffc02040ae:	704000ef          	jal	ra,ffffffffc02047b2 <find_proc>
ffffffffc02040b2:	00a9b023          	sd	a0,0(s3)
        set_proc_name(philosopher_proc_sema[i], "philosopher_sema_proc");
ffffffffc02040b6:	85da                	mv	a1,s6
    for(i=0;i<N;i++){
ffffffffc02040b8:	0485                	addi	s1,s1,1
ffffffffc02040ba:	0a61                	addi	s4,s4,24
        set_proc_name(philosopher_proc_sema[i], "philosopher_sema_proc");
ffffffffc02040bc:	662000ef          	jal	ra,ffffffffc020471e <set_proc_name>
    for(i=0;i<N;i++){
ffffffffc02040c0:	0911                	addi	s2,s2,4
ffffffffc02040c2:	09a1                	addi	s3,s3,8
ffffffffc02040c4:	fd5498e3          	bne	s1,s5,ffffffffc0204094 <check_sync+0x4c>
ffffffffc02040c8:	01440a93          	addi	s5,s0,20
ffffffffc02040cc:	84a2                	mv	s1,s0
    }
    for (i=0;i<N;i++)
        assert(do_wait(pids[i],NULL) == 0);
ffffffffc02040ce:	4088                	lw	a0,0(s1)
ffffffffc02040d0:	4581                	li	a1,0
ffffffffc02040d2:	554010ef          	jal	ra,ffffffffc0205626 <do_wait>
ffffffffc02040d6:	0e051863          	bnez	a0,ffffffffc02041c6 <check_sync+0x17e>
    for (i=0;i<N;i++)
ffffffffc02040da:	0491                	addi	s1,s1,4
ffffffffc02040dc:	ff5499e3          	bne	s1,s5,ffffffffc02040ce <check_sync+0x86>

    //check condition variable
    monitor_init(&mt, N);
ffffffffc02040e0:	4595                	li	a1,5
ffffffffc02040e2:	000d8517          	auipc	a0,0xd8
ffffffffc02040e6:	9a650513          	addi	a0,a0,-1626 # ffffffffc02dba88 <mt>
ffffffffc02040ea:	0fc000ef          	jal	ra,ffffffffc02041e6 <monitor_init>
    for(i=0;i<N;i++){
ffffffffc02040ee:	000d8917          	auipc	s2,0xd8
ffffffffc02040f2:	aba90913          	addi	s2,s2,-1350 # ffffffffc02dbba8 <state_condvar>
ffffffffc02040f6:	000d8a17          	auipc	s4,0xd8
ffffffffc02040fa:	9eaa0a13          	addi	s4,s4,-1558 # ffffffffc02dbae0 <philosopher_proc_condvar>
    monitor_init(&mt, N);
ffffffffc02040fe:	89a2                	mv	s3,s0
ffffffffc0204100:	4481                	li	s1,0
        state_condvar[i]=THINKING;
        int pid = kernel_thread(philosopher_using_condvar, (void *)i, 0);
ffffffffc0204102:	00000b17          	auipc	s6,0x0
ffffffffc0204106:	ec0b0b13          	addi	s6,s6,-320 # ffffffffc0203fc2 <philosopher_using_condvar>
        if (pid <= 0) {
            panic("create No.%d philosopher_using_condvar failed.\n");
        }
        pids[i] = pid;
        philosopher_proc_condvar[i] = find_proc(pid);
        set_proc_name(philosopher_proc_condvar[i], "philosopher_condvar_proc");
ffffffffc020410a:	00004c17          	auipc	s8,0x4
ffffffffc020410e:	e4ec0c13          	addi	s8,s8,-434 # ffffffffc0207f58 <default_pmm_manager+0xca0>
    for(i=0;i<N;i++){
ffffffffc0204112:	4b95                	li	s7,5
        int pid = kernel_thread(philosopher_using_condvar, (void *)i, 0);
ffffffffc0204114:	4601                	li	a2,0
ffffffffc0204116:	85a6                	mv	a1,s1
ffffffffc0204118:	855a                	mv	a0,s6
        state_condvar[i]=THINKING;
ffffffffc020411a:	00092023          	sw	zero,0(s2)
        int pid = kernel_thread(philosopher_using_condvar, (void *)i, 0);
ffffffffc020411e:	2b3000ef          	jal	ra,ffffffffc0204bd0 <kernel_thread>
        if (pid <= 0) {
ffffffffc0204122:	08a05663          	blez	a0,ffffffffc02041ae <check_sync+0x166>
        pids[i] = pid;
ffffffffc0204126:	00a9a023          	sw	a0,0(s3)
        philosopher_proc_condvar[i] = find_proc(pid);
ffffffffc020412a:	688000ef          	jal	ra,ffffffffc02047b2 <find_proc>
ffffffffc020412e:	00aa3023          	sd	a0,0(s4)
        set_proc_name(philosopher_proc_condvar[i], "philosopher_condvar_proc");
ffffffffc0204132:	85e2                	mv	a1,s8
    for(i=0;i<N;i++){
ffffffffc0204134:	0485                	addi	s1,s1,1
ffffffffc0204136:	0911                	addi	s2,s2,4
        set_proc_name(philosopher_proc_condvar[i], "philosopher_condvar_proc");
ffffffffc0204138:	5e6000ef          	jal	ra,ffffffffc020471e <set_proc_name>
    for(i=0;i<N;i++){
ffffffffc020413c:	0991                	addi	s3,s3,4
ffffffffc020413e:	0a21                	addi	s4,s4,8
ffffffffc0204140:	fd749ae3          	bne	s1,s7,ffffffffc0204114 <check_sync+0xcc>
    }
    for (i=0;i<N;i++)
        assert(do_wait(pids[i],NULL) == 0);
ffffffffc0204144:	4008                	lw	a0,0(s0)
ffffffffc0204146:	4581                	li	a1,0
ffffffffc0204148:	4de010ef          	jal	ra,ffffffffc0205626 <do_wait>
ffffffffc020414c:	e129                	bnez	a0,ffffffffc020418e <check_sync+0x146>
    for (i=0;i<N;i++)
ffffffffc020414e:	0411                	addi	s0,s0,4
ffffffffc0204150:	ff541ae3          	bne	s0,s5,ffffffffc0204144 <check_sync+0xfc>
    monitor_free(&mt, N);
}
ffffffffc0204154:	7406                	ld	s0,96(sp)
ffffffffc0204156:	70a6                	ld	ra,104(sp)
ffffffffc0204158:	64e6                	ld	s1,88(sp)
ffffffffc020415a:	6946                	ld	s2,80(sp)
ffffffffc020415c:	69a6                	ld	s3,72(sp)
ffffffffc020415e:	6a06                	ld	s4,64(sp)
ffffffffc0204160:	7ae2                	ld	s5,56(sp)
ffffffffc0204162:	7b42                	ld	s6,48(sp)
ffffffffc0204164:	7ba2                	ld	s7,40(sp)
ffffffffc0204166:	7c02                	ld	s8,32(sp)
    monitor_free(&mt, N);
ffffffffc0204168:	4595                	li	a1,5
ffffffffc020416a:	000d8517          	auipc	a0,0xd8
ffffffffc020416e:	91e50513          	addi	a0,a0,-1762 # ffffffffc02dba88 <mt>
}
ffffffffc0204172:	6165                	addi	sp,sp,112
    monitor_free(&mt, N);
ffffffffc0204174:	aa39                	j	ffffffffc0204292 <monitor_free>
            panic("create No.%d philosopher_using_semaphore failed.\n");
ffffffffc0204176:	00004617          	auipc	a2,0x4
ffffffffc020417a:	d2a60613          	addi	a2,a2,-726 # ffffffffc0207ea0 <default_pmm_manager+0xbe8>
ffffffffc020417e:	0a400593          	li	a1,164
ffffffffc0204182:	00004517          	auipc	a0,0x4
ffffffffc0204186:	d5650513          	addi	a0,a0,-682 # ffffffffc0207ed8 <default_pmm_manager+0xc20>
ffffffffc020418a:	b08fc0ef          	jal	ra,ffffffffc0200492 <__panic>
        assert(do_wait(pids[i],NULL) == 0);
ffffffffc020418e:	00004697          	auipc	a3,0x4
ffffffffc0204192:	d7a68693          	addi	a3,a3,-646 # ffffffffc0207f08 <default_pmm_manager+0xc50>
ffffffffc0204196:	00003617          	auipc	a2,0x3
ffffffffc020419a:	d7260613          	addi	a2,a2,-654 # ffffffffc0206f08 <commands+0x818>
ffffffffc020419e:	0ba00593          	li	a1,186
ffffffffc02041a2:	00004517          	auipc	a0,0x4
ffffffffc02041a6:	d3650513          	addi	a0,a0,-714 # ffffffffc0207ed8 <default_pmm_manager+0xc20>
ffffffffc02041aa:	ae8fc0ef          	jal	ra,ffffffffc0200492 <__panic>
            panic("create No.%d philosopher_using_condvar failed.\n");
ffffffffc02041ae:	00004617          	auipc	a2,0x4
ffffffffc02041b2:	d7a60613          	addi	a2,a2,-646 # ffffffffc0207f28 <default_pmm_manager+0xc70>
ffffffffc02041b6:	0b300593          	li	a1,179
ffffffffc02041ba:	00004517          	auipc	a0,0x4
ffffffffc02041be:	d1e50513          	addi	a0,a0,-738 # ffffffffc0207ed8 <default_pmm_manager+0xc20>
ffffffffc02041c2:	ad0fc0ef          	jal	ra,ffffffffc0200492 <__panic>
        assert(do_wait(pids[i],NULL) == 0);
ffffffffc02041c6:	00004697          	auipc	a3,0x4
ffffffffc02041ca:	d4268693          	addi	a3,a3,-702 # ffffffffc0207f08 <default_pmm_manager+0xc50>
ffffffffc02041ce:	00003617          	auipc	a2,0x3
ffffffffc02041d2:	d3a60613          	addi	a2,a2,-710 # ffffffffc0206f08 <commands+0x818>
ffffffffc02041d6:	0ab00593          	li	a1,171
ffffffffc02041da:	00004517          	auipc	a0,0x4
ffffffffc02041de:	cfe50513          	addi	a0,a0,-770 # ffffffffc0207ed8 <default_pmm_manager+0xc20>
ffffffffc02041e2:	ab0fc0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc02041e6 <monitor_init>:
#include <kmalloc.h>
#include <assert.h>

// Initialize monitor.
void     
monitor_init (monitor_t * mtp, size_t num_cv) {
ffffffffc02041e6:	7179                	addi	sp,sp,-48
ffffffffc02041e8:	f406                	sd	ra,40(sp)
ffffffffc02041ea:	f022                	sd	s0,32(sp)
ffffffffc02041ec:	ec26                	sd	s1,24(sp)
ffffffffc02041ee:	e84a                	sd	s2,16(sp)
ffffffffc02041f0:	e44e                	sd	s3,8(sp)
    int i;
    assert(num_cv>0);
ffffffffc02041f2:	c1b5                	beqz	a1,ffffffffc0204256 <monitor_init+0x70>
    mtp->next_count = 0;
ffffffffc02041f4:	89ae                	mv	s3,a1
ffffffffc02041f6:	02052823          	sw	zero,48(a0)
    mtp->cv = NULL;
    sem_init(&(mtp->mutex), 1); //unlocked
ffffffffc02041fa:	4585                	li	a1,1
    mtp->cv = NULL;
ffffffffc02041fc:	02053c23          	sd	zero,56(a0)
    sem_init(&(mtp->mutex), 1); //unlocked
ffffffffc0204200:	892a                	mv	s2,a0
ffffffffc0204202:	2a8000ef          	jal	ra,ffffffffc02044aa <sem_init>
    sem_init(&(mtp->next), 0);
ffffffffc0204206:	4581                	li	a1,0
ffffffffc0204208:	01890513          	addi	a0,s2,24
ffffffffc020420c:	29e000ef          	jal	ra,ffffffffc02044aa <sem_init>
    mtp->cv =(condvar_t *) kmalloc(sizeof(condvar_t)*num_cv);
ffffffffc0204210:	00299513          	slli	a0,s3,0x2
ffffffffc0204214:	954e                	add	a0,a0,s3
ffffffffc0204216:	050e                	slli	a0,a0,0x3
ffffffffc0204218:	983fd0ef          	jal	ra,ffffffffc0201b9a <kmalloc>
ffffffffc020421c:	02a93c23          	sd	a0,56(s2)
    assert(mtp->cv!=NULL);
ffffffffc0204220:	4401                	li	s0,0
ffffffffc0204222:	4481                	li	s1,0
ffffffffc0204224:	c921                	beqz	a0,ffffffffc0204274 <monitor_init+0x8e>
    for(i=0; i<num_cv; i++){
        mtp->cv[i].count=0;
ffffffffc0204226:	9522                	add	a0,a0,s0
ffffffffc0204228:	00052c23          	sw	zero,24(a0)
        sem_init(&(mtp->cv[i].sem),0);
ffffffffc020422c:	4581                	li	a1,0
ffffffffc020422e:	27c000ef          	jal	ra,ffffffffc02044aa <sem_init>
        mtp->cv[i].owner=mtp;
ffffffffc0204232:	03893503          	ld	a0,56(s2)
    for(i=0; i<num_cv; i++){
ffffffffc0204236:	0485                	addi	s1,s1,1
        mtp->cv[i].owner=mtp;
ffffffffc0204238:	008507b3          	add	a5,a0,s0
ffffffffc020423c:	0327b023          	sd	s2,32(a5)
    for(i=0; i<num_cv; i++){
ffffffffc0204240:	02840413          	addi	s0,s0,40
ffffffffc0204244:	fe9991e3          	bne	s3,s1,ffffffffc0204226 <monitor_init+0x40>
    }
}
ffffffffc0204248:	70a2                	ld	ra,40(sp)
ffffffffc020424a:	7402                	ld	s0,32(sp)
ffffffffc020424c:	64e2                	ld	s1,24(sp)
ffffffffc020424e:	6942                	ld	s2,16(sp)
ffffffffc0204250:	69a2                	ld	s3,8(sp)
ffffffffc0204252:	6145                	addi	sp,sp,48
ffffffffc0204254:	8082                	ret
    assert(num_cv>0);
ffffffffc0204256:	00004697          	auipc	a3,0x4
ffffffffc020425a:	d2268693          	addi	a3,a3,-734 # ffffffffc0207f78 <default_pmm_manager+0xcc0>
ffffffffc020425e:	00003617          	auipc	a2,0x3
ffffffffc0204262:	caa60613          	addi	a2,a2,-854 # ffffffffc0206f08 <commands+0x818>
ffffffffc0204266:	45a9                	li	a1,10
ffffffffc0204268:	00004517          	auipc	a0,0x4
ffffffffc020426c:	d2050513          	addi	a0,a0,-736 # ffffffffc0207f88 <default_pmm_manager+0xcd0>
ffffffffc0204270:	a22fc0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(mtp->cv!=NULL);
ffffffffc0204274:	00004697          	auipc	a3,0x4
ffffffffc0204278:	d2c68693          	addi	a3,a3,-724 # ffffffffc0207fa0 <default_pmm_manager+0xce8>
ffffffffc020427c:	00003617          	auipc	a2,0x3
ffffffffc0204280:	c8c60613          	addi	a2,a2,-884 # ffffffffc0206f08 <commands+0x818>
ffffffffc0204284:	45c1                	li	a1,16
ffffffffc0204286:	00004517          	auipc	a0,0x4
ffffffffc020428a:	d0250513          	addi	a0,a0,-766 # ffffffffc0207f88 <default_pmm_manager+0xcd0>
ffffffffc020428e:	a04fc0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0204292 <monitor_free>:

// Free monitor.
void
monitor_free (monitor_t * mtp, size_t num_cv) {
    kfree(mtp->cv);
ffffffffc0204292:	7d08                	ld	a0,56(a0)
ffffffffc0204294:	9b7fd06f          	j	ffffffffc0201c4a <kfree>

ffffffffc0204298 <cond_signal>:

// Unlock one of threads waiting on the condition variable. 
void 
cond_signal (condvar_t *cvp) {
   //LAB7 EXERCISE1: YOUR CODE
   cprintf("cond_signal begin: cvp %x, cvp->count %d, cvp->owner->next_count %d\n", cvp, cvp->count, cvp->owner->next_count);  
ffffffffc0204298:	711c                	ld	a5,32(a0)
ffffffffc020429a:	4d10                	lw	a2,24(a0)
cond_signal (condvar_t *cvp) {
ffffffffc020429c:	1141                	addi	sp,sp,-16
   cprintf("cond_signal begin: cvp %x, cvp->count %d, cvp->owner->next_count %d\n", cvp, cvp->count, cvp->owner->next_count);  
ffffffffc020429e:	5b94                	lw	a3,48(a5)
cond_signal (condvar_t *cvp) {
ffffffffc02042a0:	e022                	sd	s0,0(sp)
   cprintf("cond_signal begin: cvp %x, cvp->count %d, cvp->owner->next_count %d\n", cvp, cvp->count, cvp->owner->next_count);  
ffffffffc02042a2:	85aa                	mv	a1,a0
cond_signal (condvar_t *cvp) {
ffffffffc02042a4:	842a                	mv	s0,a0
   cprintf("cond_signal begin: cvp %x, cvp->count %d, cvp->owner->next_count %d\n", cvp, cvp->count, cvp->owner->next_count);  
ffffffffc02042a6:	00004517          	auipc	a0,0x4
ffffffffc02042aa:	d0a50513          	addi	a0,a0,-758 # ffffffffc0207fb0 <default_pmm_manager+0xcf8>
cond_signal (condvar_t *cvp) {
ffffffffc02042ae:	e406                	sd	ra,8(sp)
   cprintf("cond_signal begin: cvp %x, cvp->count %d, cvp->owner->next_count %d\n", cvp, cvp->count, cvp->owner->next_count);  
ffffffffc02042b0:	ee9fb0ef          	jal	ra,ffffffffc0200198 <cprintf>
   *             mt.next_count--;
   *          }
   *       }
   */

    if (cvp->count > 0) {
ffffffffc02042b4:	4c10                	lw	a2,24(s0)
ffffffffc02042b6:	00c04e63          	bgtz	a2,ffffffffc02042d2 <cond_signal+0x3a>
        up(&(cvp->sem));
        down(&(cvp->owner->next));
        cvp->owner->next_count--;
    }
    
   cprintf("cond_signal end: cvp %x, cvp->count %d, cvp->owner->next_count %d\n", cvp, cvp->count, cvp->owner->next_count);
ffffffffc02042ba:	701c                	ld	a5,32(s0)
ffffffffc02042bc:	85a2                	mv	a1,s0
}
ffffffffc02042be:	6402                	ld	s0,0(sp)
ffffffffc02042c0:	60a2                	ld	ra,8(sp)
   cprintf("cond_signal end: cvp %x, cvp->count %d, cvp->owner->next_count %d\n", cvp, cvp->count, cvp->owner->next_count);
ffffffffc02042c2:	5b94                	lw	a3,48(a5)
ffffffffc02042c4:	00004517          	auipc	a0,0x4
ffffffffc02042c8:	d3450513          	addi	a0,a0,-716 # ffffffffc0207ff8 <default_pmm_manager+0xd40>
}
ffffffffc02042cc:	0141                	addi	sp,sp,16
   cprintf("cond_signal end: cvp %x, cvp->count %d, cvp->owner->next_count %d\n", cvp, cvp->count, cvp->owner->next_count);
ffffffffc02042ce:	ecbfb06f          	j	ffffffffc0200198 <cprintf>
        cvp->owner->next_count++;
ffffffffc02042d2:	7018                	ld	a4,32(s0)
        up(&(cvp->sem));
ffffffffc02042d4:	8522                	mv	a0,s0
        cvp->owner->next_count++;
ffffffffc02042d6:	5b1c                	lw	a5,48(a4)
ffffffffc02042d8:	2785                	addiw	a5,a5,1
ffffffffc02042da:	db1c                	sw	a5,48(a4)
        up(&(cvp->sem));
ffffffffc02042dc:	1d4000ef          	jal	ra,ffffffffc02044b0 <up>
        down(&(cvp->owner->next));
ffffffffc02042e0:	7008                	ld	a0,32(s0)
ffffffffc02042e2:	0561                	addi	a0,a0,24
ffffffffc02042e4:	1d0000ef          	jal	ra,ffffffffc02044b4 <down>
        cvp->owner->next_count--;
ffffffffc02042e8:	7018                	ld	a4,32(s0)
   cprintf("cond_signal end: cvp %x, cvp->count %d, cvp->owner->next_count %d\n", cvp, cvp->count, cvp->owner->next_count);
ffffffffc02042ea:	4c10                	lw	a2,24(s0)
ffffffffc02042ec:	85a2                	mv	a1,s0
        cvp->owner->next_count--;
ffffffffc02042ee:	5b1c                	lw	a5,48(a4)
}
ffffffffc02042f0:	6402                	ld	s0,0(sp)
ffffffffc02042f2:	60a2                	ld	ra,8(sp)
        cvp->owner->next_count--;
ffffffffc02042f4:	fff7869b          	addiw	a3,a5,-1
ffffffffc02042f8:	db14                	sw	a3,48(a4)
   cprintf("cond_signal end: cvp %x, cvp->count %d, cvp->owner->next_count %d\n", cvp, cvp->count, cvp->owner->next_count);
ffffffffc02042fa:	00004517          	auipc	a0,0x4
ffffffffc02042fe:	cfe50513          	addi	a0,a0,-770 # ffffffffc0207ff8 <default_pmm_manager+0xd40>
}
ffffffffc0204302:	0141                	addi	sp,sp,16
   cprintf("cond_signal end: cvp %x, cvp->count %d, cvp->owner->next_count %d\n", cvp, cvp->count, cvp->owner->next_count);
ffffffffc0204304:	e95fb06f          	j	ffffffffc0200198 <cprintf>

ffffffffc0204308 <cond_wait>:
// Suspend calling thread on a condition variable waiting for condition Atomically unlocks 
// mutex and suspends calling thread on conditional variable after waking up locks mutex. Notice: mp is mutex semaphore for monitor's procedures
void
cond_wait (condvar_t *cvp) {
    //LAB7 EXERCISE1: YOUR CODE
    cprintf("cond_wait begin:  cvp %x, cvp->count %d, cvp->owner->next_count %d\n", cvp, cvp->count, cvp->owner->next_count);
ffffffffc0204308:	711c                	ld	a5,32(a0)
ffffffffc020430a:	4d10                	lw	a2,24(a0)
cond_wait (condvar_t *cvp) {
ffffffffc020430c:	1141                	addi	sp,sp,-16
    cprintf("cond_wait begin:  cvp %x, cvp->count %d, cvp->owner->next_count %d\n", cvp, cvp->count, cvp->owner->next_count);
ffffffffc020430e:	5b94                	lw	a3,48(a5)
cond_wait (condvar_t *cvp) {
ffffffffc0204310:	e022                	sd	s0,0(sp)
    cprintf("cond_wait begin:  cvp %x, cvp->count %d, cvp->owner->next_count %d\n", cvp, cvp->count, cvp->owner->next_count);
ffffffffc0204312:	85aa                	mv	a1,a0
cond_wait (condvar_t *cvp) {
ffffffffc0204314:	842a                	mv	s0,a0
    cprintf("cond_wait begin:  cvp %x, cvp->count %d, cvp->owner->next_count %d\n", cvp, cvp->count, cvp->owner->next_count);
ffffffffc0204316:	00004517          	auipc	a0,0x4
ffffffffc020431a:	d2a50513          	addi	a0,a0,-726 # ffffffffc0208040 <default_pmm_manager+0xd88>
cond_wait (condvar_t *cvp) {
ffffffffc020431e:	e406                	sd	ra,8(sp)
    cprintf("cond_wait begin:  cvp %x, cvp->count %d, cvp->owner->next_count %d\n", cvp, cvp->count, cvp->owner->next_count);
ffffffffc0204320:	e79fb0ef          	jal	ra,ffffffffc0200198 <cprintf>
    *            signal(mt.mutex);
    *         wait(cv.sem);
    *         cv.count --;
    */
    cvp->count++;
    monitor_t *mtp = cvp->owner;
ffffffffc0204324:	7008                	ld	a0,32(s0)
    cvp->count++;
ffffffffc0204326:	4c1c                	lw	a5,24(s0)
    
    if (mtp->next_count > 0) {
ffffffffc0204328:	5918                	lw	a4,48(a0)
    cvp->count++;
ffffffffc020432a:	2785                	addiw	a5,a5,1
ffffffffc020432c:	cc1c                	sw	a5,24(s0)
    if (mtp->next_count > 0) {
ffffffffc020432e:	02e05763          	blez	a4,ffffffffc020435c <cond_wait+0x54>
        up(&(mtp->next));
ffffffffc0204332:	0561                	addi	a0,a0,24
ffffffffc0204334:	17c000ef          	jal	ra,ffffffffc02044b0 <up>
    } else {
        up(&(mtp->mutex));
    }
    
    down(&(cvp->sem));
ffffffffc0204338:	8522                	mv	a0,s0
ffffffffc020433a:	17a000ef          	jal	ra,ffffffffc02044b4 <down>
    cvp->count--;
ffffffffc020433e:	4c10                	lw	a2,24(s0)
    
    cprintf("cond_wait end:  cvp %x, cvp->count %d, cvp->owner->next_count %d\n", cvp, cvp->count, cvp->owner->next_count);
ffffffffc0204340:	701c                	ld	a5,32(s0)
ffffffffc0204342:	85a2                	mv	a1,s0
    cvp->count--;
ffffffffc0204344:	367d                	addiw	a2,a2,-1
    cprintf("cond_wait end:  cvp %x, cvp->count %d, cvp->owner->next_count %d\n", cvp, cvp->count, cvp->owner->next_count);
ffffffffc0204346:	5b94                	lw	a3,48(a5)
    cvp->count--;
ffffffffc0204348:	cc10                	sw	a2,24(s0)
}
ffffffffc020434a:	6402                	ld	s0,0(sp)
ffffffffc020434c:	60a2                	ld	ra,8(sp)
    cprintf("cond_wait end:  cvp %x, cvp->count %d, cvp->owner->next_count %d\n", cvp, cvp->count, cvp->owner->next_count);
ffffffffc020434e:	00004517          	auipc	a0,0x4
ffffffffc0204352:	d3a50513          	addi	a0,a0,-710 # ffffffffc0208088 <default_pmm_manager+0xdd0>
}
ffffffffc0204356:	0141                	addi	sp,sp,16
    cprintf("cond_wait end:  cvp %x, cvp->count %d, cvp->owner->next_count %d\n", cvp, cvp->count, cvp->owner->next_count);
ffffffffc0204358:	e41fb06f          	j	ffffffffc0200198 <cprintf>
        up(&(mtp->mutex));
ffffffffc020435c:	154000ef          	jal	ra,ffffffffc02044b0 <up>
ffffffffc0204360:	bfe1                	j	ffffffffc0204338 <cond_wait+0x30>

ffffffffc0204362 <__down.constprop.0>:
        }
    }
    local_intr_restore(intr_flag);
}

static __noinline uint32_t __down(semaphore_t *sem, uint32_t wait_state) {
ffffffffc0204362:	715d                	addi	sp,sp,-80
ffffffffc0204364:	e0a2                	sd	s0,64(sp)
ffffffffc0204366:	e486                	sd	ra,72(sp)
ffffffffc0204368:	fc26                	sd	s1,56(sp)
ffffffffc020436a:	842a                	mv	s0,a0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020436c:	100027f3          	csrr	a5,sstatus
ffffffffc0204370:	8b89                	andi	a5,a5,2
ffffffffc0204372:	ebb1                	bnez	a5,ffffffffc02043c6 <__down.constprop.0+0x64>
    bool intr_flag;
    local_intr_save(intr_flag);
    if (sem->value > 0) {
ffffffffc0204374:	411c                	lw	a5,0(a0)
ffffffffc0204376:	00f05a63          	blez	a5,ffffffffc020438a <__down.constprop.0+0x28>
        sem->value --;
ffffffffc020437a:	37fd                	addiw	a5,a5,-1
ffffffffc020437c:	c11c                	sw	a5,0(a0)
        local_intr_restore(intr_flag);
        return 0;
ffffffffc020437e:	4501                	li	a0,0

    if (wait->wakeup_flags != wait_state) {
        return wait->wakeup_flags;
    }
    return 0;
}
ffffffffc0204380:	60a6                	ld	ra,72(sp)
ffffffffc0204382:	6406                	ld	s0,64(sp)
ffffffffc0204384:	74e2                	ld	s1,56(sp)
ffffffffc0204386:	6161                	addi	sp,sp,80
ffffffffc0204388:	8082                	ret
    wait_current_set(&(sem->wait_queue), wait, wait_state);
ffffffffc020438a:	00850413          	addi	s0,a0,8
ffffffffc020438e:	0024                	addi	s1,sp,8
ffffffffc0204390:	10000613          	li	a2,256
ffffffffc0204394:	85a6                	mv	a1,s1
ffffffffc0204396:	8522                	mv	a0,s0
ffffffffc0204398:	1fe000ef          	jal	ra,ffffffffc0204596 <wait_current_set>
    schedule();
ffffffffc020439c:	7c4010ef          	jal	ra,ffffffffc0205b60 <schedule>
ffffffffc02043a0:	100027f3          	csrr	a5,sstatus
ffffffffc02043a4:	8b89                	andi	a5,a5,2
ffffffffc02043a6:	efb9                	bnez	a5,ffffffffc0204404 <__down.constprop.0+0xa2>
    wait_current_del(&(sem->wait_queue), wait);
ffffffffc02043a8:	8526                	mv	a0,s1
ffffffffc02043aa:	190000ef          	jal	ra,ffffffffc020453a <wait_in_queue>
ffffffffc02043ae:	e531                	bnez	a0,ffffffffc02043fa <__down.constprop.0+0x98>
    if (wait->wakeup_flags != wait_state) {
ffffffffc02043b0:	4542                	lw	a0,16(sp)
ffffffffc02043b2:	10000793          	li	a5,256
ffffffffc02043b6:	fcf515e3          	bne	a0,a5,ffffffffc0204380 <__down.constprop.0+0x1e>
}
ffffffffc02043ba:	60a6                	ld	ra,72(sp)
ffffffffc02043bc:	6406                	ld	s0,64(sp)
ffffffffc02043be:	74e2                	ld	s1,56(sp)
    return 0;
ffffffffc02043c0:	4501                	li	a0,0
}
ffffffffc02043c2:	6161                	addi	sp,sp,80
ffffffffc02043c4:	8082                	ret
        intr_disable();
ffffffffc02043c6:	de8fc0ef          	jal	ra,ffffffffc02009ae <intr_disable>
    if (sem->value > 0) {
ffffffffc02043ca:	401c                	lw	a5,0(s0)
ffffffffc02043cc:	00f05c63          	blez	a5,ffffffffc02043e4 <__down.constprop.0+0x82>
        sem->value --;
ffffffffc02043d0:	37fd                	addiw	a5,a5,-1
ffffffffc02043d2:	c01c                	sw	a5,0(s0)
        intr_enable();
ffffffffc02043d4:	dd4fc0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
}
ffffffffc02043d8:	60a6                	ld	ra,72(sp)
ffffffffc02043da:	6406                	ld	s0,64(sp)
ffffffffc02043dc:	74e2                	ld	s1,56(sp)
        return 0;
ffffffffc02043de:	4501                	li	a0,0
}
ffffffffc02043e0:	6161                	addi	sp,sp,80
ffffffffc02043e2:	8082                	ret
    wait_current_set(&(sem->wait_queue), wait, wait_state);
ffffffffc02043e4:	0421                	addi	s0,s0,8
ffffffffc02043e6:	0024                	addi	s1,sp,8
ffffffffc02043e8:	10000613          	li	a2,256
ffffffffc02043ec:	85a6                	mv	a1,s1
ffffffffc02043ee:	8522                	mv	a0,s0
ffffffffc02043f0:	1a6000ef          	jal	ra,ffffffffc0204596 <wait_current_set>
ffffffffc02043f4:	db4fc0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc02043f8:	b755                	j	ffffffffc020439c <__down.constprop.0+0x3a>
    wait_current_del(&(sem->wait_queue), wait);
ffffffffc02043fa:	85a6                	mv	a1,s1
ffffffffc02043fc:	8522                	mv	a0,s0
ffffffffc02043fe:	0ee000ef          	jal	ra,ffffffffc02044ec <wait_queue_del>
    if (flag) {
ffffffffc0204402:	b77d                	j	ffffffffc02043b0 <__down.constprop.0+0x4e>
        intr_disable();
ffffffffc0204404:	daafc0ef          	jal	ra,ffffffffc02009ae <intr_disable>
ffffffffc0204408:	8526                	mv	a0,s1
ffffffffc020440a:	130000ef          	jal	ra,ffffffffc020453a <wait_in_queue>
ffffffffc020440e:	e501                	bnez	a0,ffffffffc0204416 <__down.constprop.0+0xb4>
        intr_enable();
ffffffffc0204410:	d98fc0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0204414:	bf71                	j	ffffffffc02043b0 <__down.constprop.0+0x4e>
ffffffffc0204416:	85a6                	mv	a1,s1
ffffffffc0204418:	8522                	mv	a0,s0
ffffffffc020441a:	0d2000ef          	jal	ra,ffffffffc02044ec <wait_queue_del>
    if (flag) {
ffffffffc020441e:	bfcd                	j	ffffffffc0204410 <__down.constprop.0+0xae>

ffffffffc0204420 <__up.constprop.0>:
static __noinline void __up(semaphore_t *sem, uint32_t wait_state) {
ffffffffc0204420:	1101                	addi	sp,sp,-32
ffffffffc0204422:	e822                	sd	s0,16(sp)
ffffffffc0204424:	ec06                	sd	ra,24(sp)
ffffffffc0204426:	e426                	sd	s1,8(sp)
ffffffffc0204428:	e04a                	sd	s2,0(sp)
ffffffffc020442a:	842a                	mv	s0,a0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020442c:	100027f3          	csrr	a5,sstatus
ffffffffc0204430:	8b89                	andi	a5,a5,2
ffffffffc0204432:	4901                	li	s2,0
ffffffffc0204434:	eba1                	bnez	a5,ffffffffc0204484 <__up.constprop.0+0x64>
        if ((wait = wait_queue_first(&(sem->wait_queue))) == NULL) {
ffffffffc0204436:	00840493          	addi	s1,s0,8
ffffffffc020443a:	8526                	mv	a0,s1
ffffffffc020443c:	0ee000ef          	jal	ra,ffffffffc020452a <wait_queue_first>
ffffffffc0204440:	85aa                	mv	a1,a0
ffffffffc0204442:	cd0d                	beqz	a0,ffffffffc020447c <__up.constprop.0+0x5c>
            assert(wait->proc->wait_state == wait_state);
ffffffffc0204444:	6118                	ld	a4,0(a0)
ffffffffc0204446:	10000793          	li	a5,256
ffffffffc020444a:	0ec72703          	lw	a4,236(a4)
ffffffffc020444e:	02f71f63          	bne	a4,a5,ffffffffc020448c <__up.constprop.0+0x6c>
            wakeup_wait(&(sem->wait_queue), wait, wait_state, 1);
ffffffffc0204452:	4685                	li	a3,1
ffffffffc0204454:	10000613          	li	a2,256
ffffffffc0204458:	8526                	mv	a0,s1
ffffffffc020445a:	0ee000ef          	jal	ra,ffffffffc0204548 <wakeup_wait>
    if (flag) {
ffffffffc020445e:	00091863          	bnez	s2,ffffffffc020446e <__up.constprop.0+0x4e>
}
ffffffffc0204462:	60e2                	ld	ra,24(sp)
ffffffffc0204464:	6442                	ld	s0,16(sp)
ffffffffc0204466:	64a2                	ld	s1,8(sp)
ffffffffc0204468:	6902                	ld	s2,0(sp)
ffffffffc020446a:	6105                	addi	sp,sp,32
ffffffffc020446c:	8082                	ret
ffffffffc020446e:	6442                	ld	s0,16(sp)
ffffffffc0204470:	60e2                	ld	ra,24(sp)
ffffffffc0204472:	64a2                	ld	s1,8(sp)
ffffffffc0204474:	6902                	ld	s2,0(sp)
ffffffffc0204476:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0204478:	d30fc06f          	j	ffffffffc02009a8 <intr_enable>
            sem->value ++;
ffffffffc020447c:	401c                	lw	a5,0(s0)
ffffffffc020447e:	2785                	addiw	a5,a5,1
ffffffffc0204480:	c01c                	sw	a5,0(s0)
ffffffffc0204482:	bff1                	j	ffffffffc020445e <__up.constprop.0+0x3e>
        intr_disable();
ffffffffc0204484:	d2afc0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        return 1;
ffffffffc0204488:	4905                	li	s2,1
ffffffffc020448a:	b775                	j	ffffffffc0204436 <__up.constprop.0+0x16>
            assert(wait->proc->wait_state == wait_state);
ffffffffc020448c:	00004697          	auipc	a3,0x4
ffffffffc0204490:	c4468693          	addi	a3,a3,-956 # ffffffffc02080d0 <default_pmm_manager+0xe18>
ffffffffc0204494:	00003617          	auipc	a2,0x3
ffffffffc0204498:	a7460613          	addi	a2,a2,-1420 # ffffffffc0206f08 <commands+0x818>
ffffffffc020449c:	45e5                	li	a1,25
ffffffffc020449e:	00004517          	auipc	a0,0x4
ffffffffc02044a2:	c5a50513          	addi	a0,a0,-934 # ffffffffc02080f8 <default_pmm_manager+0xe40>
ffffffffc02044a6:	fedfb0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc02044aa <sem_init>:
    sem->value = value;
ffffffffc02044aa:	c10c                	sw	a1,0(a0)
    wait_queue_init(&(sem->wait_queue));
ffffffffc02044ac:	0521                	addi	a0,a0,8
ffffffffc02044ae:	a825                	j	ffffffffc02044e6 <wait_queue_init>

ffffffffc02044b0 <up>:

void
up(semaphore_t *sem) {
    __up(sem, WT_KSEM);
ffffffffc02044b0:	f71ff06f          	j	ffffffffc0204420 <__up.constprop.0>

ffffffffc02044b4 <down>:
}

void
down(semaphore_t *sem) {
ffffffffc02044b4:	1141                	addi	sp,sp,-16
ffffffffc02044b6:	e406                	sd	ra,8(sp)
    uint32_t flags = __down(sem, WT_KSEM);
ffffffffc02044b8:	eabff0ef          	jal	ra,ffffffffc0204362 <__down.constprop.0>
ffffffffc02044bc:	2501                	sext.w	a0,a0
    assert(flags == 0);
ffffffffc02044be:	e501                	bnez	a0,ffffffffc02044c6 <down+0x12>
}
ffffffffc02044c0:	60a2                	ld	ra,8(sp)
ffffffffc02044c2:	0141                	addi	sp,sp,16
ffffffffc02044c4:	8082                	ret
    assert(flags == 0);
ffffffffc02044c6:	00004697          	auipc	a3,0x4
ffffffffc02044ca:	c4268693          	addi	a3,a3,-958 # ffffffffc0208108 <default_pmm_manager+0xe50>
ffffffffc02044ce:	00003617          	auipc	a2,0x3
ffffffffc02044d2:	a3a60613          	addi	a2,a2,-1478 # ffffffffc0206f08 <commands+0x818>
ffffffffc02044d6:	04000593          	li	a1,64
ffffffffc02044da:	00004517          	auipc	a0,0x4
ffffffffc02044de:	c1e50513          	addi	a0,a0,-994 # ffffffffc02080f8 <default_pmm_manager+0xe40>
ffffffffc02044e2:	fb1fb0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc02044e6 <wait_queue_init>:
    elm->prev = elm->next = elm;
ffffffffc02044e6:	e508                	sd	a0,8(a0)
ffffffffc02044e8:	e108                	sd	a0,0(a0)
}

void
wait_queue_init(wait_queue_t *queue) {
    list_init(&(queue->wait_head));
}
ffffffffc02044ea:	8082                	ret

ffffffffc02044ec <wait_queue_del>:
    return list->next == list;
ffffffffc02044ec:	7198                	ld	a4,32(a1)
    list_add_before(&(queue->wait_head), &(wait->wait_link));
}

void
wait_queue_del(wait_queue_t *queue, wait_t *wait) {
    assert(!list_empty(&(wait->wait_link)) && wait->wait_queue == queue);
ffffffffc02044ee:	01858793          	addi	a5,a1,24
ffffffffc02044f2:	00e78b63          	beq	a5,a4,ffffffffc0204508 <wait_queue_del+0x1c>
ffffffffc02044f6:	6994                	ld	a3,16(a1)
ffffffffc02044f8:	00a69863          	bne	a3,a0,ffffffffc0204508 <wait_queue_del+0x1c>
    __list_del(listelm->prev, listelm->next);
ffffffffc02044fc:	6d94                	ld	a3,24(a1)
    prev->next = next;
ffffffffc02044fe:	e698                	sd	a4,8(a3)
    next->prev = prev;
ffffffffc0204500:	e314                	sd	a3,0(a4)
    elm->prev = elm->next = elm;
ffffffffc0204502:	f19c                	sd	a5,32(a1)
ffffffffc0204504:	ed9c                	sd	a5,24(a1)
ffffffffc0204506:	8082                	ret
wait_queue_del(wait_queue_t *queue, wait_t *wait) {
ffffffffc0204508:	1141                	addi	sp,sp,-16
    assert(!list_empty(&(wait->wait_link)) && wait->wait_queue == queue);
ffffffffc020450a:	00004697          	auipc	a3,0x4
ffffffffc020450e:	c5e68693          	addi	a3,a3,-930 # ffffffffc0208168 <default_pmm_manager+0xeb0>
ffffffffc0204512:	00003617          	auipc	a2,0x3
ffffffffc0204516:	9f660613          	addi	a2,a2,-1546 # ffffffffc0206f08 <commands+0x818>
ffffffffc020451a:	45f1                	li	a1,28
ffffffffc020451c:	00004517          	auipc	a0,0x4
ffffffffc0204520:	c3450513          	addi	a0,a0,-972 # ffffffffc0208150 <default_pmm_manager+0xe98>
wait_queue_del(wait_queue_t *queue, wait_t *wait) {
ffffffffc0204524:	e406                	sd	ra,8(sp)
    assert(!list_empty(&(wait->wait_link)) && wait->wait_queue == queue);
ffffffffc0204526:	f6dfb0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc020452a <wait_queue_first>:
    return listelm->next;
ffffffffc020452a:	651c                	ld	a5,8(a0)
}

wait_t *
wait_queue_first(wait_queue_t *queue) {
    list_entry_t *le = list_next(&(queue->wait_head));
    if (le != &(queue->wait_head)) {
ffffffffc020452c:	00f50563          	beq	a0,a5,ffffffffc0204536 <wait_queue_first+0xc>
        return le2wait(le, wait_link);
ffffffffc0204530:	fe878513          	addi	a0,a5,-24
ffffffffc0204534:	8082                	ret
    }
    return NULL;
ffffffffc0204536:	4501                	li	a0,0
}
ffffffffc0204538:	8082                	ret

ffffffffc020453a <wait_in_queue>:
    return list_empty(&(queue->wait_head));
}

bool
wait_in_queue(wait_t *wait) {
    return !list_empty(&(wait->wait_link));
ffffffffc020453a:	711c                	ld	a5,32(a0)
ffffffffc020453c:	0561                	addi	a0,a0,24
ffffffffc020453e:	40a78533          	sub	a0,a5,a0
}
ffffffffc0204542:	00a03533          	snez	a0,a0
ffffffffc0204546:	8082                	ret

ffffffffc0204548 <wakeup_wait>:

void
wakeup_wait(wait_queue_t *queue, wait_t *wait, uint32_t wakeup_flags, bool del) {
    if (del) {
ffffffffc0204548:	e689                	bnez	a3,ffffffffc0204552 <wakeup_wait+0xa>
        wait_queue_del(queue, wait);
    }
    wait->wakeup_flags = wakeup_flags;
    wakeup_proc(wait->proc);
ffffffffc020454a:	6188                	ld	a0,0(a1)
    wait->wakeup_flags = wakeup_flags;
ffffffffc020454c:	c590                	sw	a2,8(a1)
    wakeup_proc(wait->proc);
ffffffffc020454e:	5600106f          	j	ffffffffc0205aae <wakeup_proc>
    return list->next == list;
ffffffffc0204552:	7198                	ld	a4,32(a1)
    assert(!list_empty(&(wait->wait_link)) && wait->wait_queue == queue);
ffffffffc0204554:	01858793          	addi	a5,a1,24
ffffffffc0204558:	00e78e63          	beq	a5,a4,ffffffffc0204574 <wakeup_wait+0x2c>
ffffffffc020455c:	6994                	ld	a3,16(a1)
ffffffffc020455e:	00d51b63          	bne	a0,a3,ffffffffc0204574 <wakeup_wait+0x2c>
    __list_del(listelm->prev, listelm->next);
ffffffffc0204562:	6d94                	ld	a3,24(a1)
    wakeup_proc(wait->proc);
ffffffffc0204564:	6188                	ld	a0,0(a1)
    prev->next = next;
ffffffffc0204566:	e698                	sd	a4,8(a3)
    next->prev = prev;
ffffffffc0204568:	e314                	sd	a3,0(a4)
    elm->prev = elm->next = elm;
ffffffffc020456a:	f19c                	sd	a5,32(a1)
ffffffffc020456c:	ed9c                	sd	a5,24(a1)
    wait->wakeup_flags = wakeup_flags;
ffffffffc020456e:	c590                	sw	a2,8(a1)
    wakeup_proc(wait->proc);
ffffffffc0204570:	53e0106f          	j	ffffffffc0205aae <wakeup_proc>
wakeup_wait(wait_queue_t *queue, wait_t *wait, uint32_t wakeup_flags, bool del) {
ffffffffc0204574:	1141                	addi	sp,sp,-16
    assert(!list_empty(&(wait->wait_link)) && wait->wait_queue == queue);
ffffffffc0204576:	00004697          	auipc	a3,0x4
ffffffffc020457a:	bf268693          	addi	a3,a3,-1038 # ffffffffc0208168 <default_pmm_manager+0xeb0>
ffffffffc020457e:	00003617          	auipc	a2,0x3
ffffffffc0204582:	98a60613          	addi	a2,a2,-1654 # ffffffffc0206f08 <commands+0x818>
ffffffffc0204586:	45f1                	li	a1,28
ffffffffc0204588:	00004517          	auipc	a0,0x4
ffffffffc020458c:	bc850513          	addi	a0,a0,-1080 # ffffffffc0208150 <default_pmm_manager+0xe98>
wakeup_wait(wait_queue_t *queue, wait_t *wait, uint32_t wakeup_flags, bool del) {
ffffffffc0204590:	e406                	sd	ra,8(sp)
    assert(!list_empty(&(wait->wait_link)) && wait->wait_queue == queue);
ffffffffc0204592:	f01fb0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0204596 <wait_current_set>:
    }
}

void
wait_current_set(wait_queue_t *queue, wait_t *wait, uint32_t wait_state) {
    assert(current != NULL);
ffffffffc0204596:	000db797          	auipc	a5,0xdb
ffffffffc020459a:	6da7b783          	ld	a5,1754(a5) # ffffffffc02dfc70 <current>
ffffffffc020459e:	c39d                	beqz	a5,ffffffffc02045c4 <wait_current_set+0x2e>
    list_init(&(wait->wait_link));
ffffffffc02045a0:	01858713          	addi	a4,a1,24
    wait->wakeup_flags = WT_INTERRUPTED;
ffffffffc02045a4:	800006b7          	lui	a3,0x80000
ffffffffc02045a8:	ed98                	sd	a4,24(a1)
    wait->proc = proc;
ffffffffc02045aa:	e19c                	sd	a5,0(a1)
    wait->wakeup_flags = WT_INTERRUPTED;
ffffffffc02045ac:	c594                	sw	a3,8(a1)
    wait_init(wait, current);
    current->state = PROC_SLEEPING;
ffffffffc02045ae:	4685                	li	a3,1
ffffffffc02045b0:	c394                	sw	a3,0(a5)
    current->wait_state = wait_state;
ffffffffc02045b2:	0ec7a623          	sw	a2,236(a5)
    __list_add(elm, listelm->prev, listelm);
ffffffffc02045b6:	611c                	ld	a5,0(a0)
    wait->wait_queue = queue;
ffffffffc02045b8:	e988                	sd	a0,16(a1)
    prev->next = next->prev = elm;
ffffffffc02045ba:	e118                	sd	a4,0(a0)
ffffffffc02045bc:	e798                	sd	a4,8(a5)
    elm->next = next;
ffffffffc02045be:	f188                	sd	a0,32(a1)
    elm->prev = prev;
ffffffffc02045c0:	ed9c                	sd	a5,24(a1)
ffffffffc02045c2:	8082                	ret
wait_current_set(wait_queue_t *queue, wait_t *wait, uint32_t wait_state) {
ffffffffc02045c4:	1141                	addi	sp,sp,-16
    assert(current != NULL);
ffffffffc02045c6:	00004697          	auipc	a3,0x4
ffffffffc02045ca:	be268693          	addi	a3,a3,-1054 # ffffffffc02081a8 <default_pmm_manager+0xef0>
ffffffffc02045ce:	00003617          	auipc	a2,0x3
ffffffffc02045d2:	93a60613          	addi	a2,a2,-1734 # ffffffffc0206f08 <commands+0x818>
ffffffffc02045d6:	07400593          	li	a1,116
ffffffffc02045da:	00004517          	auipc	a0,0x4
ffffffffc02045de:	b7650513          	addi	a0,a0,-1162 # ffffffffc0208150 <default_pmm_manager+0xe98>
wait_current_set(wait_queue_t *queue, wait_t *wait, uint32_t wait_state) {
ffffffffc02045e2:	e406                	sd	ra,8(sp)
    assert(current != NULL);
ffffffffc02045e4:	eaffb0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc02045e8 <kernel_thread_entry>:
.text
.globl kernel_thread_entry
kernel_thread_entry:        # void kernel_thread(void)
	move a0, s1
ffffffffc02045e8:	8526                	mv	a0,s1
	jalr s0
ffffffffc02045ea:	9402                	jalr	s0

	jal do_exit
ffffffffc02045ec:	634000ef          	jal	ra,ffffffffc0204c20 <do_exit>

ffffffffc02045f0 <alloc_proc>:
void switch_to(struct context *from, struct context *to);

// alloc_proc - alloc a proc_struct and init all fields of proc_struct
static struct proc_struct *
alloc_proc(void)
{
ffffffffc02045f0:	1141                	addi	sp,sp,-16
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc02045f2:	14800513          	li	a0,328
{
ffffffffc02045f6:	e022                	sd	s0,0(sp)
ffffffffc02045f8:	e406                	sd	ra,8(sp)
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc02045fa:	da0fd0ef          	jal	ra,ffffffffc0201b9a <kmalloc>
ffffffffc02045fe:	842a                	mv	s0,a0
    if (proc != NULL)
ffffffffc0204600:	c941                	beqz	a0,ffffffffc0204690 <alloc_proc+0xa0>
    {
        // LAB4
        proc->state = PROC_UNINIT;                  // 初始化进程状态为未初始化
ffffffffc0204602:	57fd                	li	a5,-1
ffffffffc0204604:	1782                	slli	a5,a5,0x20
ffffffffc0204606:	e11c                	sd	a5,0(a0)
        proc->runs = 0;                             // 初始化运行次数为0
        proc->kstack = 0;                           // 初始化内核栈为0（空指针），后续通过setup_kstack()为进程分配实际的内核栈空间
        proc->need_resched = 0;                     // 初始化不需要重新调度
        proc->parent = NULL;                        // 初始化父进程指针为NULL
        proc->mm = NULL;                            // 初始化内存管理结构指针为NULL
        memset(&(proc->context), 0, sizeof(struct context)); // 初始化上下文结构体，全部设为0，为后续保存现场做准备
ffffffffc0204608:	07000613          	li	a2,112
ffffffffc020460c:	4581                	li	a1,0
        proc->runs = 0;                             // 初始化运行次数为0
ffffffffc020460e:	00052423          	sw	zero,8(a0)
        proc->kstack = 0;                           // 初始化内核栈为0（空指针），后续通过setup_kstack()为进程分配实际的内核栈空间
ffffffffc0204612:	00053823          	sd	zero,16(a0)
        proc->need_resched = 0;                     // 初始化不需要重新调度
ffffffffc0204616:	00053c23          	sd	zero,24(a0)
        proc->parent = NULL;                        // 初始化父进程指针为NULL
ffffffffc020461a:	02053023          	sd	zero,32(a0)
        proc->mm = NULL;                            // 初始化内存管理结构指针为NULL
ffffffffc020461e:	02053423          	sd	zero,40(a0)
        memset(&(proc->context), 0, sizeof(struct context)); // 初始化上下文结构体，全部设为0，为后续保存现场做准备
ffffffffc0204622:	03050513          	addi	a0,a0,48
ffffffffc0204626:	633010ef          	jal	ra,ffffffffc0206458 <memset>
        proc->tf = NULL;                            // 初始化陷阱帧为NULL
        proc->pgdir = boot_pgdir_pa;                // 初始化页目录表基址为boot_pgdir_pa
ffffffffc020462a:	000db797          	auipc	a5,0xdb
ffffffffc020462e:	6167b783          	ld	a5,1558(a5) # ffffffffc02dfc40 <boot_pgdir_pa>
ffffffffc0204632:	f45c                	sd	a5,168(s0)
        proc->tf = NULL;                            // 初始化陷阱帧为NULL
ffffffffc0204634:	0a043023          	sd	zero,160(s0)
        proc->flags = 0;                            // 初始化进程标志为0
ffffffffc0204638:	0a042823          	sw	zero,176(s0)
        memset(proc->name, 0, PROC_NAME_LEN + 1);   // 初始化进程名称数组全部清零，后续通过set_proc_name()设置具体的进程名称
ffffffffc020463c:	4641                	li	a2,16
ffffffffc020463e:	4581                	li	a1,0
ffffffffc0204640:	0b440513          	addi	a0,s0,180
ffffffffc0204644:	615010ef          	jal	ra,ffffffffc0206458 <memset>
        proc->optr = NULL;         // 初始化较年长兄弟进程(older sibling pointer)指针为NULL
        proc->yptr = NULL;         // 初始化较年轻兄弟进程(younger sibling pointer)指针为NULL

        // LAB6
        proc->rq = NULL;                    // 初始化运行队列指针为NULL
        list_init(&(proc->run_link));       // 初始化运行队列链表节点
ffffffffc0204648:	11040793          	addi	a5,s0,272
    elm->prev = elm->next = elm;
ffffffffc020464c:	10f43c23          	sd	a5,280(s0)
ffffffffc0204650:	10f43823          	sd	a5,272(s0)
        proc->time_slice = 0;               // 初始化时间片为0，后续由调度器设置
        proc->lab6_run_pool.left = NULL;    // 初始化斜堆的左子树指针
        proc->lab6_run_pool.right = NULL;   // 初始化斜堆的右子树指针
        proc->lab6_run_pool.parent = NULL;  // 初始化斜堆的父节点指针
        proc->lab6_stride = 0;              // 初始化stride值为0
ffffffffc0204654:	4785                	li	a5,1
        list_init(&(proc->list_link));
ffffffffc0204656:	0c840693          	addi	a3,s0,200
        list_init(&(proc->hash_link));
ffffffffc020465a:	0d840713          	addi	a4,s0,216
        proc->lab6_stride = 0;              // 初始化stride值为0
ffffffffc020465e:	1782                	slli	a5,a5,0x20
ffffffffc0204660:	e874                	sd	a3,208(s0)
ffffffffc0204662:	e474                	sd	a3,200(s0)
ffffffffc0204664:	f078                	sd	a4,224(s0)
ffffffffc0204666:	ec78                	sd	a4,216(s0)
        proc->wait_state = 0;      // 设置进程的等待状态为0，表示进程当前不在等待状态
ffffffffc0204668:	0e042623          	sw	zero,236(s0)
        proc->cptr = NULL;         // 初始化子进程指针为NULL
ffffffffc020466c:	0e043823          	sd	zero,240(s0)
        proc->optr = NULL;         // 初始化较年长兄弟进程(older sibling pointer)指针为NULL
ffffffffc0204670:	10043023          	sd	zero,256(s0)
        proc->yptr = NULL;         // 初始化较年轻兄弟进程(younger sibling pointer)指针为NULL
ffffffffc0204674:	0e043c23          	sd	zero,248(s0)
        proc->rq = NULL;                    // 初始化运行队列指针为NULL
ffffffffc0204678:	10043423          	sd	zero,264(s0)
        proc->time_slice = 0;               // 初始化时间片为0，后续由调度器设置
ffffffffc020467c:	12042023          	sw	zero,288(s0)
        proc->lab6_run_pool.parent = NULL;  // 初始化斜堆的父节点指针
ffffffffc0204680:	12043423          	sd	zero,296(s0)
        proc->lab6_run_pool.left = NULL;    // 初始化斜堆的左子树指针
ffffffffc0204684:	12043823          	sd	zero,304(s0)
        proc->lab6_run_pool.right = NULL;   // 初始化斜堆的右子树指针
ffffffffc0204688:	12043c23          	sd	zero,312(s0)
        proc->lab6_stride = 0;              // 初始化stride值为0
ffffffffc020468c:	14f43023          	sd	a5,320(s0)
        proc->lab6_priority = 1;            // 初始化优先级为1（最小的优先级值，确保所有进程都有默认优先级）
    }
    return proc;
}
ffffffffc0204690:	60a2                	ld	ra,8(sp)
ffffffffc0204692:	8522                	mv	a0,s0
ffffffffc0204694:	6402                	ld	s0,0(sp)
ffffffffc0204696:	0141                	addi	sp,sp,16
ffffffffc0204698:	8082                	ret

ffffffffc020469a <forkret>:
// NOTE: the addr of forkret is setted in copy_thread function
//       after switch_to, the current proc will execute here.
static void
forkret(void)
{
    forkrets(current->tf);
ffffffffc020469a:	000db797          	auipc	a5,0xdb
ffffffffc020469e:	5d67b783          	ld	a5,1494(a5) # ffffffffc02dfc70 <current>
ffffffffc02046a2:	73c8                	ld	a0,160(a5)
ffffffffc02046a4:	813fc06f          	j	ffffffffc0200eb6 <forkrets>

ffffffffc02046a8 <put_pgdir.isra.0>:
    return 0;
}

// put_pgdir - free the memory space of PDT
static void
put_pgdir(struct mm_struct *mm)
ffffffffc02046a8:	1141                	addi	sp,sp,-16
ffffffffc02046aa:	e406                	sd	ra,8(sp)
    return pa2page(PADDR(kva));
ffffffffc02046ac:	c02007b7          	lui	a5,0xc0200
ffffffffc02046b0:	02f56e63          	bltu	a0,a5,ffffffffc02046ec <put_pgdir.isra.0+0x44>
ffffffffc02046b4:	000db697          	auipc	a3,0xdb
ffffffffc02046b8:	5b46b683          	ld	a3,1460(a3) # ffffffffc02dfc68 <va_pa_offset>
ffffffffc02046bc:	8d15                	sub	a0,a0,a3
    if (PPN(pa) >= npage)
ffffffffc02046be:	8131                	srli	a0,a0,0xc
ffffffffc02046c0:	000db797          	auipc	a5,0xdb
ffffffffc02046c4:	5907b783          	ld	a5,1424(a5) # ffffffffc02dfc50 <npage>
ffffffffc02046c8:	02f57f63          	bgeu	a0,a5,ffffffffc0204706 <put_pgdir.isra.0+0x5e>
    return &pages[PPN(pa) - nbase];
ffffffffc02046cc:	00005697          	auipc	a3,0x5
ffffffffc02046d0:	ba46b683          	ld	a3,-1116(a3) # ffffffffc0209270 <nbase>
{
    free_page(kva2page(mm->pgdir));
}
ffffffffc02046d4:	60a2                	ld	ra,8(sp)
ffffffffc02046d6:	8d15                	sub	a0,a0,a3
    free_page(kva2page(mm->pgdir));
ffffffffc02046d8:	000db797          	auipc	a5,0xdb
ffffffffc02046dc:	5807b783          	ld	a5,1408(a5) # ffffffffc02dfc58 <pages>
ffffffffc02046e0:	051a                	slli	a0,a0,0x6
ffffffffc02046e2:	4585                	li	a1,1
ffffffffc02046e4:	953e                	add	a0,a0,a5
}
ffffffffc02046e6:	0141                	addi	sp,sp,16
    free_page(kva2page(mm->pgdir));
ffffffffc02046e8:	ecefd06f          	j	ffffffffc0201db6 <free_pages>
    return pa2page(PADDR(kva));
ffffffffc02046ec:	86aa                	mv	a3,a0
ffffffffc02046ee:	00003617          	auipc	a2,0x3
ffffffffc02046f2:	caa60613          	addi	a2,a2,-854 # ffffffffc0207398 <default_pmm_manager+0xe0>
ffffffffc02046f6:	07700593          	li	a1,119
ffffffffc02046fa:	00003517          	auipc	a0,0x3
ffffffffc02046fe:	c1e50513          	addi	a0,a0,-994 # ffffffffc0207318 <default_pmm_manager+0x60>
ffffffffc0204702:	d91fb0ef          	jal	ra,ffffffffc0200492 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0204706:	00003617          	auipc	a2,0x3
ffffffffc020470a:	cba60613          	addi	a2,a2,-838 # ffffffffc02073c0 <default_pmm_manager+0x108>
ffffffffc020470e:	06900593          	li	a1,105
ffffffffc0204712:	00003517          	auipc	a0,0x3
ffffffffc0204716:	c0650513          	addi	a0,a0,-1018 # ffffffffc0207318 <default_pmm_manager+0x60>
ffffffffc020471a:	d79fb0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc020471e <set_proc_name>:
{
ffffffffc020471e:	1101                	addi	sp,sp,-32
ffffffffc0204720:	e822                	sd	s0,16(sp)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204722:	0b450413          	addi	s0,a0,180
{
ffffffffc0204726:	e426                	sd	s1,8(sp)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204728:	4641                	li	a2,16
{
ffffffffc020472a:	84ae                	mv	s1,a1
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc020472c:	8522                	mv	a0,s0
ffffffffc020472e:	4581                	li	a1,0
{
ffffffffc0204730:	ec06                	sd	ra,24(sp)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204732:	527010ef          	jal	ra,ffffffffc0206458 <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0204736:	8522                	mv	a0,s0
}
ffffffffc0204738:	6442                	ld	s0,16(sp)
ffffffffc020473a:	60e2                	ld	ra,24(sp)
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc020473c:	85a6                	mv	a1,s1
}
ffffffffc020473e:	64a2                	ld	s1,8(sp)
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0204740:	463d                	li	a2,15
}
ffffffffc0204742:	6105                	addi	sp,sp,32
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0204744:	5270106f          	j	ffffffffc020646a <memcpy>

ffffffffc0204748 <proc_run>:
{
ffffffffc0204748:	7179                	addi	sp,sp,-48
ffffffffc020474a:	f026                	sd	s1,32(sp)
    if (proc != current)
ffffffffc020474c:	000db497          	auipc	s1,0xdb
ffffffffc0204750:	52448493          	addi	s1,s1,1316 # ffffffffc02dfc70 <current>
ffffffffc0204754:	6098                	ld	a4,0(s1)
{
ffffffffc0204756:	f406                	sd	ra,40(sp)
ffffffffc0204758:	ec4a                	sd	s2,24(sp)
    if (proc != current)
ffffffffc020475a:	02a70a63          	beq	a4,a0,ffffffffc020478e <proc_run+0x46>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020475e:	100027f3          	csrr	a5,sstatus
ffffffffc0204762:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0204764:	4901                	li	s2,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0204766:	ef9d                	bnez	a5,ffffffffc02047a4 <proc_run+0x5c>
        current->runs++;
ffffffffc0204768:	4514                	lw	a3,8(a0)
#define barrier() __asm__ __volatile__("fence" ::: "memory")

static inline void
lsatp(unsigned long pgdir)
{
  write_csr(satp, 0x8000000000000000 | (pgdir >> RISCV_PGSHIFT));
ffffffffc020476a:	755c                	ld	a5,168(a0)
        current = proc;
ffffffffc020476c:	e088                	sd	a0,0(s1)
        current->runs++;
ffffffffc020476e:	2685                	addiw	a3,a3,1
ffffffffc0204770:	c514                	sw	a3,8(a0)
ffffffffc0204772:	56fd                	li	a3,-1
ffffffffc0204774:	16fe                	slli	a3,a3,0x3f
ffffffffc0204776:	83b1                	srli	a5,a5,0xc
ffffffffc0204778:	8fd5                	or	a5,a5,a3
ffffffffc020477a:	18079073          	csrw	satp,a5
        switch_to(&prev->context, &current->context);
ffffffffc020477e:	03050593          	addi	a1,a0,48
ffffffffc0204782:	03070513          	addi	a0,a4,48
ffffffffc0204786:	1ca010ef          	jal	ra,ffffffffc0205950 <switch_to>
    if (flag) {
ffffffffc020478a:	00091763          	bnez	s2,ffffffffc0204798 <proc_run+0x50>
}
ffffffffc020478e:	70a2                	ld	ra,40(sp)
ffffffffc0204790:	7482                	ld	s1,32(sp)
ffffffffc0204792:	6962                	ld	s2,24(sp)
ffffffffc0204794:	6145                	addi	sp,sp,48
ffffffffc0204796:	8082                	ret
ffffffffc0204798:	70a2                	ld	ra,40(sp)
ffffffffc020479a:	7482                	ld	s1,32(sp)
ffffffffc020479c:	6962                	ld	s2,24(sp)
ffffffffc020479e:	6145                	addi	sp,sp,48
        intr_enable();
ffffffffc02047a0:	a08fc06f          	j	ffffffffc02009a8 <intr_enable>
ffffffffc02047a4:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc02047a6:	a08fc0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        struct proc_struct *prev = current;
ffffffffc02047aa:	6098                	ld	a4,0(s1)
        return 1;
ffffffffc02047ac:	6522                	ld	a0,8(sp)
ffffffffc02047ae:	4905                	li	s2,1
ffffffffc02047b0:	bf65                	j	ffffffffc0204768 <proc_run+0x20>

ffffffffc02047b2 <find_proc>:
    if (0 < pid && pid < MAX_PID)
ffffffffc02047b2:	6789                	lui	a5,0x2
ffffffffc02047b4:	fff5071b          	addiw	a4,a0,-1
ffffffffc02047b8:	17f9                	addi	a5,a5,-2
ffffffffc02047ba:	04e7e163          	bltu	a5,a4,ffffffffc02047fc <find_proc+0x4a>
{
ffffffffc02047be:	1141                	addi	sp,sp,-16
ffffffffc02047c0:	e022                	sd	s0,0(sp)
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc02047c2:	45a9                	li	a1,10
ffffffffc02047c4:	842a                	mv	s0,a0
ffffffffc02047c6:	2501                	sext.w	a0,a0
{
ffffffffc02047c8:	e406                	sd	ra,8(sp)
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc02047ca:	7e8010ef          	jal	ra,ffffffffc0205fb2 <hash32>
ffffffffc02047ce:	02051793          	slli	a5,a0,0x20
ffffffffc02047d2:	01c7d513          	srli	a0,a5,0x1c
ffffffffc02047d6:	000d7797          	auipc	a5,0xd7
ffffffffc02047da:	40278793          	addi	a5,a5,1026 # ffffffffc02dbbd8 <hash_list>
ffffffffc02047de:	953e                	add	a0,a0,a5
ffffffffc02047e0:	87aa                	mv	a5,a0
        while ((le = list_next(le)) != list)
ffffffffc02047e2:	a029                	j	ffffffffc02047ec <find_proc+0x3a>
            if (proc->pid == pid)
ffffffffc02047e4:	f2c7a703          	lw	a4,-212(a5)
ffffffffc02047e8:	00870c63          	beq	a4,s0,ffffffffc0204800 <find_proc+0x4e>
    return listelm->next;
ffffffffc02047ec:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc02047ee:	fef51be3          	bne	a0,a5,ffffffffc02047e4 <find_proc+0x32>
}
ffffffffc02047f2:	60a2                	ld	ra,8(sp)
ffffffffc02047f4:	6402                	ld	s0,0(sp)
    return NULL;
ffffffffc02047f6:	4501                	li	a0,0
}
ffffffffc02047f8:	0141                	addi	sp,sp,16
ffffffffc02047fa:	8082                	ret
    return NULL;
ffffffffc02047fc:	4501                	li	a0,0
}
ffffffffc02047fe:	8082                	ret
ffffffffc0204800:	60a2                	ld	ra,8(sp)
ffffffffc0204802:	6402                	ld	s0,0(sp)
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc0204804:	f2878513          	addi	a0,a5,-216
}
ffffffffc0204808:	0141                	addi	sp,sp,16
ffffffffc020480a:	8082                	ret

ffffffffc020480c <do_fork>:
 * @clone_flags: used to guide how to clone the child process
 * @stack:       the parent's user stack pointer. if stack==0, It means to fork a kernel thread.
 * @tf:          the trapframe info, which will be copied to child process's proc->tf
 */
int do_fork(uint32_t clone_flags, uintptr_t stack, struct trapframe *tf)
{
ffffffffc020480c:	7119                	addi	sp,sp,-128
ffffffffc020480e:	f4a6                	sd	s1,104(sp)
    int ret = -E_NO_FREE_PROC;
    struct proc_struct *proc;
    if (nr_process >= MAX_PROCESS)
ffffffffc0204810:	000db497          	auipc	s1,0xdb
ffffffffc0204814:	47848493          	addi	s1,s1,1144 # ffffffffc02dfc88 <nr_process>
ffffffffc0204818:	4098                	lw	a4,0(s1)
{
ffffffffc020481a:	fc86                	sd	ra,120(sp)
ffffffffc020481c:	f8a2                	sd	s0,112(sp)
ffffffffc020481e:	f0ca                	sd	s2,96(sp)
ffffffffc0204820:	ecce                	sd	s3,88(sp)
ffffffffc0204822:	e8d2                	sd	s4,80(sp)
ffffffffc0204824:	e4d6                	sd	s5,72(sp)
ffffffffc0204826:	e0da                	sd	s6,64(sp)
ffffffffc0204828:	fc5e                	sd	s7,56(sp)
ffffffffc020482a:	f862                	sd	s8,48(sp)
ffffffffc020482c:	f466                	sd	s9,40(sp)
ffffffffc020482e:	f06a                	sd	s10,32(sp)
ffffffffc0204830:	ec6e                	sd	s11,24(sp)
    if (nr_process >= MAX_PROCESS)
ffffffffc0204832:	6785                	lui	a5,0x1
ffffffffc0204834:	30f75d63          	bge	a4,a5,ffffffffc0204b4e <do_fork+0x342>
ffffffffc0204838:	8a2a                	mv	s4,a0
ffffffffc020483a:	892e                	mv	s2,a1
ffffffffc020483c:	89b2                	mv	s3,a2
     *    -------------------
     *    update step 1: set child proc's parent to current process, make sure current process's wait_state is 0
     *    update step 5: insert proc_struct into hash_list && proc_list, set the relation links of process
     */
    // 1) 分配进程控制块
    if ((proc = alloc_proc()) == NULL) {
ffffffffc020483e:	db3ff0ef          	jal	ra,ffffffffc02045f0 <alloc_proc>
ffffffffc0204842:	842a                	mv	s0,a0
ffffffffc0204844:	2e050e63          	beqz	a0,ffffffffc0204b40 <do_fork+0x334>
        goto fork_out;
    }
    
    // LAB5: 设置父进程，并确保父进程的 wait_state 为 
    proc->parent = current;
ffffffffc0204848:	000dbc17          	auipc	s8,0xdb
ffffffffc020484c:	428c0c13          	addi	s8,s8,1064 # ffffffffc02dfc70 <current>
ffffffffc0204850:	000c3783          	ld	a5,0(s8)
    struct Page *page = alloc_pages(KSTACKPAGE);
ffffffffc0204854:	4509                	li	a0,2
    proc->parent = current;
ffffffffc0204856:	f01c                	sd	a5,32(s0)
    struct Page *page = alloc_pages(KSTACKPAGE);
ffffffffc0204858:	d20fd0ef          	jal	ra,ffffffffc0201d78 <alloc_pages>
    if (page != NULL)
ffffffffc020485c:	2c050f63          	beqz	a0,ffffffffc0204b3a <do_fork+0x32e>
    return page - pages + nbase;
ffffffffc0204860:	000dbc97          	auipc	s9,0xdb
ffffffffc0204864:	3f8c8c93          	addi	s9,s9,1016 # ffffffffc02dfc58 <pages>
ffffffffc0204868:	000cb683          	ld	a3,0(s9)
    return KADDR(page2pa(page));
ffffffffc020486c:	000dbd17          	auipc	s10,0xdb
ffffffffc0204870:	3e4d0d13          	addi	s10,s10,996 # ffffffffc02dfc50 <npage>
    return page - pages + nbase;
ffffffffc0204874:	00005a97          	auipc	s5,0x5
ffffffffc0204878:	9fcaba83          	ld	s5,-1540(s5) # ffffffffc0209270 <nbase>
ffffffffc020487c:	40d506b3          	sub	a3,a0,a3
ffffffffc0204880:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0204882:	5dfd                	li	s11,-1
ffffffffc0204884:	000d3783          	ld	a5,0(s10)
    return page - pages + nbase;
ffffffffc0204888:	96d6                	add	a3,a3,s5
    return KADDR(page2pa(page));
ffffffffc020488a:	00cddd93          	srli	s11,s11,0xc
ffffffffc020488e:	01b6f733          	and	a4,a3,s11
    return page2ppn(page) << PGSHIFT;
ffffffffc0204892:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204894:	30f77563          	bgeu	a4,a5,ffffffffc0204b9e <do_fork+0x392>
    struct mm_struct *mm, *oldmm = current->mm;
ffffffffc0204898:	000c3603          	ld	a2,0(s8)
ffffffffc020489c:	000dbb17          	auipc	s6,0xdb
ffffffffc02048a0:	3ccb0b13          	addi	s6,s6,972 # ffffffffc02dfc68 <va_pa_offset>
ffffffffc02048a4:	000b3703          	ld	a4,0(s6)
ffffffffc02048a8:	02863b83          	ld	s7,40(a2)
ffffffffc02048ac:	96ba                	add	a3,a3,a4
        proc->kstack = (uintptr_t)page2kva(page);
ffffffffc02048ae:	e814                	sd	a3,16(s0)
    if (oldmm == NULL)
ffffffffc02048b0:	020b8863          	beqz	s7,ffffffffc02048e0 <do_fork+0xd4>
    if (clone_flags & CLONE_VM)
ffffffffc02048b4:	100a7a13          	andi	s4,s4,256
ffffffffc02048b8:	1c0a0263          	beqz	s4,ffffffffc0204a7c <do_fork+0x270>
}

static inline int
mm_count_inc(struct mm_struct *mm)
{
    mm->mm_count += 1;
ffffffffc02048bc:	030ba683          	lw	a3,48(s7)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc02048c0:	018bb703          	ld	a4,24(s7)
ffffffffc02048c4:	c0200637          	lui	a2,0xc0200
ffffffffc02048c8:	2685                	addiw	a3,a3,1
ffffffffc02048ca:	02dba823          	sw	a3,48(s7)
    proc->mm = mm;
ffffffffc02048ce:	03743423          	sd	s7,40(s0)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc02048d2:	2ec76263          	bltu	a4,a2,ffffffffc0204bb6 <do_fork+0x3aa>
ffffffffc02048d6:	000b3783          	ld	a5,0(s6)
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc02048da:	6814                	ld	a3,16(s0)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc02048dc:	8f1d                	sub	a4,a4,a5
ffffffffc02048de:	f458                	sd	a4,168(s0)
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc02048e0:	6789                	lui	a5,0x2
ffffffffc02048e2:	ee078793          	addi	a5,a5,-288 # 1ee0 <_binary_obj___user_faultread_out_size-0x8248>
ffffffffc02048e6:	96be                	add	a3,a3,a5
    *(proc->tf) = *tf;
ffffffffc02048e8:	864e                	mv	a2,s3
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc02048ea:	f054                	sd	a3,160(s0)
    *(proc->tf) = *tf;
ffffffffc02048ec:	87b6                	mv	a5,a3
ffffffffc02048ee:	12098893          	addi	a7,s3,288
ffffffffc02048f2:	00063803          	ld	a6,0(a2) # ffffffffc0200000 <kern_entry>
ffffffffc02048f6:	6608                	ld	a0,8(a2)
ffffffffc02048f8:	6a0c                	ld	a1,16(a2)
ffffffffc02048fa:	6e18                	ld	a4,24(a2)
ffffffffc02048fc:	0107b023          	sd	a6,0(a5)
ffffffffc0204900:	e788                	sd	a0,8(a5)
ffffffffc0204902:	eb8c                	sd	a1,16(a5)
ffffffffc0204904:	ef98                	sd	a4,24(a5)
ffffffffc0204906:	02060613          	addi	a2,a2,32
ffffffffc020490a:	02078793          	addi	a5,a5,32
ffffffffc020490e:	ff1612e3          	bne	a2,a7,ffffffffc02048f2 <do_fork+0xe6>
    proc->tf->gpr.a0 = 0;
ffffffffc0204912:	0406b823          	sd	zero,80(a3)
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc0204916:	14090063          	beqz	s2,ffffffffc0204a56 <do_fork+0x24a>
ffffffffc020491a:	0126b823          	sd	s2,16(a3)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc020491e:	00000797          	auipc	a5,0x0
ffffffffc0204922:	d7c78793          	addi	a5,a5,-644 # ffffffffc020469a <forkret>
ffffffffc0204926:	f81c                	sd	a5,48(s0)
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc0204928:	fc14                	sd	a3,56(s0)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020492a:	100027f3          	csrr	a5,sstatus
ffffffffc020492e:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0204930:	4981                	li	s3,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0204932:	14079163          	bnez	a5,ffffffffc0204a74 <do_fork+0x268>
    if (++last_pid >= MAX_PID)
ffffffffc0204936:	000d7817          	auipc	a6,0xd7
ffffffffc020493a:	d3280813          	addi	a6,a6,-718 # ffffffffc02db668 <last_pid.1>
ffffffffc020493e:	00082783          	lw	a5,0(a6)
ffffffffc0204942:	6709                	lui	a4,0x2
ffffffffc0204944:	0017851b          	addiw	a0,a5,1
ffffffffc0204948:	00a82023          	sw	a0,0(a6)
ffffffffc020494c:	08e55e63          	bge	a0,a4,ffffffffc02049e8 <do_fork+0x1dc>
    if (last_pid >= next_safe)
ffffffffc0204950:	000d7317          	auipc	t1,0xd7
ffffffffc0204954:	d1c30313          	addi	t1,t1,-740 # ffffffffc02db66c <next_safe.0>
ffffffffc0204958:	00032783          	lw	a5,0(t1)
ffffffffc020495c:	000db917          	auipc	s2,0xdb
ffffffffc0204960:	27c90913          	addi	s2,s2,636 # ffffffffc02dfbd8 <proc_list>
ffffffffc0204964:	08f55a63          	bge	a0,a5,ffffffffc02049f8 <do_fork+0x1ec>

    // 5) 分配唯一 pid
    bool intr_flag;
    local_intr_save(intr_flag);  // 关中断，保证原子性
    {
        proc->pid = get_pid();
ffffffffc0204968:	c048                	sw	a0,4(s0)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc020496a:	45a9                	li	a1,10
ffffffffc020496c:	2501                	sext.w	a0,a0
ffffffffc020496e:	644010ef          	jal	ra,ffffffffc0205fb2 <hash32>
ffffffffc0204972:	02051793          	slli	a5,a0,0x20
ffffffffc0204976:	01c7d513          	srli	a0,a5,0x1c
ffffffffc020497a:	000d7797          	auipc	a5,0xd7
ffffffffc020497e:	25e78793          	addi	a5,a5,606 # ffffffffc02dbbd8 <hash_list>
ffffffffc0204982:	953e                	add	a0,a0,a5
    __list_add(elm, listelm, listelm->next);
ffffffffc0204984:	650c                	ld	a1,8(a0)
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc0204986:	7014                	ld	a3,32(s0)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc0204988:	0d840793          	addi	a5,s0,216
    prev->next = next->prev = elm;
ffffffffc020498c:	e19c                	sd	a5,0(a1)
    __list_add(elm, listelm, listelm->next);
ffffffffc020498e:	00893603          	ld	a2,8(s2)
    prev->next = next->prev = elm;
ffffffffc0204992:	e51c                	sd	a5,8(a0)
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc0204994:	7af8                	ld	a4,240(a3)
    list_add(&proc_list, &(proc->list_link));
ffffffffc0204996:	0c840793          	addi	a5,s0,200
    elm->next = next;
ffffffffc020499a:	f06c                	sd	a1,224(s0)
    elm->prev = prev;
ffffffffc020499c:	ec68                	sd	a0,216(s0)
    prev->next = next->prev = elm;
ffffffffc020499e:	e21c                	sd	a5,0(a2)
ffffffffc02049a0:	00f93423          	sd	a5,8(s2)
    elm->next = next;
ffffffffc02049a4:	e870                	sd	a2,208(s0)
    elm->prev = prev;
ffffffffc02049a6:	0d243423          	sd	s2,200(s0)
    proc->yptr = NULL;
ffffffffc02049aa:	0e043c23          	sd	zero,248(s0)
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc02049ae:	10e43023          	sd	a4,256(s0)
ffffffffc02049b2:	c311                	beqz	a4,ffffffffc02049b6 <do_fork+0x1aa>
        proc->optr->yptr = proc;
ffffffffc02049b4:	ff60                	sd	s0,248(a4)
    nr_process++;
ffffffffc02049b6:	409c                	lw	a5,0(s1)
    proc->parent->cptr = proc;
ffffffffc02049b8:	fae0                	sd	s0,240(a3)
    nr_process++;
ffffffffc02049ba:	2785                	addiw	a5,a5,1
ffffffffc02049bc:	c09c                	sw	a5,0(s1)
    if (flag) {
ffffffffc02049be:	12099c63          	bnez	s3,ffffffffc0204af6 <do_fork+0x2ea>
        set_links(proc);
    }
    local_intr_restore(intr_flag);  // 恢复中断

    // 6) 唤醒子进程，使其可调度（会把 state 置为 PROC_RUNNABLE）
    wakeup_proc(proc);
ffffffffc02049c2:	8522                	mv	a0,s0
ffffffffc02049c4:	0ea010ef          	jal	ra,ffffffffc0205aae <wakeup_proc>

    // 7) 父进程得到子进程的 pid 作为返回值
    ret = proc->pid;
ffffffffc02049c8:	4048                	lw	a0,4(s0)
bad_fork_cleanup_kstack:
    put_kstack(proc);
bad_fork_cleanup_proc:
    kfree(proc);
    goto fork_out;
}
ffffffffc02049ca:	70e6                	ld	ra,120(sp)
ffffffffc02049cc:	7446                	ld	s0,112(sp)
ffffffffc02049ce:	74a6                	ld	s1,104(sp)
ffffffffc02049d0:	7906                	ld	s2,96(sp)
ffffffffc02049d2:	69e6                	ld	s3,88(sp)
ffffffffc02049d4:	6a46                	ld	s4,80(sp)
ffffffffc02049d6:	6aa6                	ld	s5,72(sp)
ffffffffc02049d8:	6b06                	ld	s6,64(sp)
ffffffffc02049da:	7be2                	ld	s7,56(sp)
ffffffffc02049dc:	7c42                	ld	s8,48(sp)
ffffffffc02049de:	7ca2                	ld	s9,40(sp)
ffffffffc02049e0:	7d02                	ld	s10,32(sp)
ffffffffc02049e2:	6de2                	ld	s11,24(sp)
ffffffffc02049e4:	6109                	addi	sp,sp,128
ffffffffc02049e6:	8082                	ret
        last_pid = 1;
ffffffffc02049e8:	4785                	li	a5,1
ffffffffc02049ea:	00f82023          	sw	a5,0(a6)
        goto inside;
ffffffffc02049ee:	4505                	li	a0,1
ffffffffc02049f0:	000d7317          	auipc	t1,0xd7
ffffffffc02049f4:	c7c30313          	addi	t1,t1,-900 # ffffffffc02db66c <next_safe.0>
    return listelm->next;
ffffffffc02049f8:	000db917          	auipc	s2,0xdb
ffffffffc02049fc:	1e090913          	addi	s2,s2,480 # ffffffffc02dfbd8 <proc_list>
ffffffffc0204a00:	00893e03          	ld	t3,8(s2)
        next_safe = MAX_PID;
ffffffffc0204a04:	6789                	lui	a5,0x2
ffffffffc0204a06:	00f32023          	sw	a5,0(t1)
ffffffffc0204a0a:	86aa                	mv	a3,a0
ffffffffc0204a0c:	4581                	li	a1,0
        while ((le = list_next(le)) != list)
ffffffffc0204a0e:	6e89                	lui	t4,0x2
ffffffffc0204a10:	132e0a63          	beq	t3,s2,ffffffffc0204b44 <do_fork+0x338>
ffffffffc0204a14:	88ae                	mv	a7,a1
ffffffffc0204a16:	87f2                	mv	a5,t3
ffffffffc0204a18:	6609                	lui	a2,0x2
ffffffffc0204a1a:	a811                	j	ffffffffc0204a2e <do_fork+0x222>
            else if (proc->pid > last_pid && next_safe > proc->pid)
ffffffffc0204a1c:	00e6d663          	bge	a3,a4,ffffffffc0204a28 <do_fork+0x21c>
ffffffffc0204a20:	00c75463          	bge	a4,a2,ffffffffc0204a28 <do_fork+0x21c>
ffffffffc0204a24:	863a                	mv	a2,a4
ffffffffc0204a26:	4885                	li	a7,1
ffffffffc0204a28:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc0204a2a:	01278d63          	beq	a5,s2,ffffffffc0204a44 <do_fork+0x238>
            if (proc->pid == last_pid)
ffffffffc0204a2e:	f3c7a703          	lw	a4,-196(a5) # 1f3c <_binary_obj___user_faultread_out_size-0x81ec>
ffffffffc0204a32:	fee695e3          	bne	a3,a4,ffffffffc0204a1c <do_fork+0x210>
                if (++last_pid >= next_safe)
ffffffffc0204a36:	2685                	addiw	a3,a3,1
ffffffffc0204a38:	0cc6d263          	bge	a3,a2,ffffffffc0204afc <do_fork+0x2f0>
ffffffffc0204a3c:	679c                	ld	a5,8(a5)
ffffffffc0204a3e:	4585                	li	a1,1
        while ((le = list_next(le)) != list)
ffffffffc0204a40:	ff2797e3          	bne	a5,s2,ffffffffc0204a2e <do_fork+0x222>
ffffffffc0204a44:	c581                	beqz	a1,ffffffffc0204a4c <do_fork+0x240>
ffffffffc0204a46:	00d82023          	sw	a3,0(a6)
ffffffffc0204a4a:	8536                	mv	a0,a3
ffffffffc0204a4c:	f0088ee3          	beqz	a7,ffffffffc0204968 <do_fork+0x15c>
ffffffffc0204a50:	00c32023          	sw	a2,0(t1)
ffffffffc0204a54:	bf11                	j	ffffffffc0204968 <do_fork+0x15c>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc0204a56:	8936                	mv	s2,a3
ffffffffc0204a58:	0126b823          	sd	s2,16(a3)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc0204a5c:	00000797          	auipc	a5,0x0
ffffffffc0204a60:	c3e78793          	addi	a5,a5,-962 # ffffffffc020469a <forkret>
ffffffffc0204a64:	f81c                	sd	a5,48(s0)
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc0204a66:	fc14                	sd	a3,56(s0)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0204a68:	100027f3          	csrr	a5,sstatus
ffffffffc0204a6c:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0204a6e:	4981                	li	s3,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0204a70:	ec0783e3          	beqz	a5,ffffffffc0204936 <do_fork+0x12a>
        intr_disable();
ffffffffc0204a74:	f3bfb0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        return 1;
ffffffffc0204a78:	4985                	li	s3,1
ffffffffc0204a7a:	bd75                	j	ffffffffc0204936 <do_fork+0x12a>
    if ((mm = mm_create()) == NULL)
ffffffffc0204a7c:	b43fe0ef          	jal	ra,ffffffffc02035be <mm_create>
ffffffffc0204a80:	e42a                	sd	a0,8(sp)
ffffffffc0204a82:	c549                	beqz	a0,ffffffffc0204b0c <do_fork+0x300>
    if ((page = alloc_page()) == NULL)
ffffffffc0204a84:	4505                	li	a0,1
ffffffffc0204a86:	af2fd0ef          	jal	ra,ffffffffc0201d78 <alloc_pages>
ffffffffc0204a8a:	cd35                	beqz	a0,ffffffffc0204b06 <do_fork+0x2fa>
    return page - pages + nbase;
ffffffffc0204a8c:	000cb683          	ld	a3,0(s9)
    return KADDR(page2pa(page));
ffffffffc0204a90:	000d3703          	ld	a4,0(s10)
    return page - pages + nbase;
ffffffffc0204a94:	40d506b3          	sub	a3,a0,a3
ffffffffc0204a98:	8699                	srai	a3,a3,0x6
ffffffffc0204a9a:	96d6                	add	a3,a3,s5
    return KADDR(page2pa(page));
ffffffffc0204a9c:	01b6fdb3          	and	s11,a3,s11
    return page2ppn(page) << PGSHIFT;
ffffffffc0204aa0:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204aa2:	0eedfe63          	bgeu	s11,a4,ffffffffc0204b9e <do_fork+0x392>
ffffffffc0204aa6:	000b3a03          	ld	s4,0(s6)
    memcpy(pgdir, boot_pgdir_va, PGSIZE);
ffffffffc0204aaa:	6605                	lui	a2,0x1
ffffffffc0204aac:	000db597          	auipc	a1,0xdb
ffffffffc0204ab0:	19c5b583          	ld	a1,412(a1) # ffffffffc02dfc48 <boot_pgdir_va>
ffffffffc0204ab4:	9a36                	add	s4,s4,a3
ffffffffc0204ab6:	8552                	mv	a0,s4
ffffffffc0204ab8:	1b3010ef          	jal	ra,ffffffffc020646a <memcpy>
    mm->pgdir = pgdir;
ffffffffc0204abc:	67a2                	ld	a5,8(sp)
static inline void
lock_mm(struct mm_struct *mm)
{
    if (mm != NULL)
    {
        down(&(mm->mm_sem));
ffffffffc0204abe:	038b8d93          	addi	s11,s7,56
ffffffffc0204ac2:	856e                	mv	a0,s11
ffffffffc0204ac4:	0147bc23          	sd	s4,24(a5)
ffffffffc0204ac8:	9edff0ef          	jal	ra,ffffffffc02044b4 <down>
        if (current != NULL)
ffffffffc0204acc:	000c3703          	ld	a4,0(s8)
ffffffffc0204ad0:	c701                	beqz	a4,ffffffffc0204ad8 <do_fork+0x2cc>
        {
            mm->locked_by = current->pid;
ffffffffc0204ad2:	4358                	lw	a4,4(a4)
ffffffffc0204ad4:	04eba823          	sw	a4,80(s7)
        ret = dup_mmap(mm, oldmm);
ffffffffc0204ad8:	6c22                	ld	s8,8(sp)
ffffffffc0204ada:	85de                	mv	a1,s7
ffffffffc0204adc:	8562                	mv	a0,s8
ffffffffc0204ade:	d31fe0ef          	jal	ra,ffffffffc020380e <dup_mmap>
ffffffffc0204ae2:	8a2a                	mv	s4,a0
static inline void
unlock_mm(struct mm_struct *mm)
{
    if (mm != NULL)
    {
        up(&(mm->mm_sem));
ffffffffc0204ae4:	856e                	mv	a0,s11
ffffffffc0204ae6:	9cbff0ef          	jal	ra,ffffffffc02044b0 <up>
        mm->locked_by = 0;
ffffffffc0204aea:	040ba823          	sw	zero,80(s7)
    if (ret != 0)
ffffffffc0204aee:	080a1d63          	bnez	s4,ffffffffc0204b88 <do_fork+0x37c>
ffffffffc0204af2:	8be2                	mv	s7,s8
ffffffffc0204af4:	b3e1                	j	ffffffffc02048bc <do_fork+0xb0>
        intr_enable();
ffffffffc0204af6:	eb3fb0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0204afa:	b5e1                	j	ffffffffc02049c2 <do_fork+0x1b6>
                    if (last_pid >= MAX_PID)
ffffffffc0204afc:	01d6c363          	blt	a3,t4,ffffffffc0204b02 <do_fork+0x2f6>
                        last_pid = 1;
ffffffffc0204b00:	4685                	li	a3,1
                    goto repeat;
ffffffffc0204b02:	4585                	li	a1,1
ffffffffc0204b04:	b731                	j	ffffffffc0204a10 <do_fork+0x204>
    mm_destroy(mm);
ffffffffc0204b06:	6522                	ld	a0,8(sp)
ffffffffc0204b08:	c05fe0ef          	jal	ra,ffffffffc020370c <mm_destroy>
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
ffffffffc0204b0c:	6814                	ld	a3,16(s0)
    return pa2page(PADDR(kva));
ffffffffc0204b0e:	c0200737          	lui	a4,0xc0200
ffffffffc0204b12:	04e6ef63          	bltu	a3,a4,ffffffffc0204b70 <do_fork+0x364>
ffffffffc0204b16:	000b3783          	ld	a5,0(s6)
    if (PPN(pa) >= npage)
ffffffffc0204b1a:	000d3703          	ld	a4,0(s10)
    return pa2page(PADDR(kva));
ffffffffc0204b1e:	40f687b3          	sub	a5,a3,a5
    if (PPN(pa) >= npage)
ffffffffc0204b22:	83b1                	srli	a5,a5,0xc
ffffffffc0204b24:	02e7fa63          	bgeu	a5,a4,ffffffffc0204b58 <do_fork+0x34c>
    return &pages[PPN(pa) - nbase];
ffffffffc0204b28:	000cb503          	ld	a0,0(s9)
ffffffffc0204b2c:	415787b3          	sub	a5,a5,s5
ffffffffc0204b30:	079a                	slli	a5,a5,0x6
ffffffffc0204b32:	4589                	li	a1,2
ffffffffc0204b34:	953e                	add	a0,a0,a5
ffffffffc0204b36:	a80fd0ef          	jal	ra,ffffffffc0201db6 <free_pages>
    kfree(proc);
ffffffffc0204b3a:	8522                	mv	a0,s0
ffffffffc0204b3c:	90efd0ef          	jal	ra,ffffffffc0201c4a <kfree>
    ret = -E_NO_MEM;
ffffffffc0204b40:	5571                	li	a0,-4
    return ret;
ffffffffc0204b42:	b561                	j	ffffffffc02049ca <do_fork+0x1be>
ffffffffc0204b44:	c599                	beqz	a1,ffffffffc0204b52 <do_fork+0x346>
ffffffffc0204b46:	00d82023          	sw	a3,0(a6)
    return last_pid;
ffffffffc0204b4a:	8536                	mv	a0,a3
ffffffffc0204b4c:	bd31                	j	ffffffffc0204968 <do_fork+0x15c>
    int ret = -E_NO_FREE_PROC;
ffffffffc0204b4e:	556d                	li	a0,-5
ffffffffc0204b50:	bdad                	j	ffffffffc02049ca <do_fork+0x1be>
    return last_pid;
ffffffffc0204b52:	00082503          	lw	a0,0(a6)
ffffffffc0204b56:	bd09                	j	ffffffffc0204968 <do_fork+0x15c>
        panic("pa2page called with invalid pa");
ffffffffc0204b58:	00003617          	auipc	a2,0x3
ffffffffc0204b5c:	86860613          	addi	a2,a2,-1944 # ffffffffc02073c0 <default_pmm_manager+0x108>
ffffffffc0204b60:	06900593          	li	a1,105
ffffffffc0204b64:	00002517          	auipc	a0,0x2
ffffffffc0204b68:	7b450513          	addi	a0,a0,1972 # ffffffffc0207318 <default_pmm_manager+0x60>
ffffffffc0204b6c:	927fb0ef          	jal	ra,ffffffffc0200492 <__panic>
    return pa2page(PADDR(kva));
ffffffffc0204b70:	00003617          	auipc	a2,0x3
ffffffffc0204b74:	82860613          	addi	a2,a2,-2008 # ffffffffc0207398 <default_pmm_manager+0xe0>
ffffffffc0204b78:	07700593          	li	a1,119
ffffffffc0204b7c:	00002517          	auipc	a0,0x2
ffffffffc0204b80:	79c50513          	addi	a0,a0,1948 # ffffffffc0207318 <default_pmm_manager+0x60>
ffffffffc0204b84:	90ffb0ef          	jal	ra,ffffffffc0200492 <__panic>
    exit_mmap(mm);
ffffffffc0204b88:	64a2                	ld	s1,8(sp)
ffffffffc0204b8a:	8526                	mv	a0,s1
ffffffffc0204b8c:	d1dfe0ef          	jal	ra,ffffffffc02038a8 <exit_mmap>
    put_pgdir(mm);
ffffffffc0204b90:	6c88                	ld	a0,24(s1)
ffffffffc0204b92:	b17ff0ef          	jal	ra,ffffffffc02046a8 <put_pgdir.isra.0>
    mm_destroy(mm);
ffffffffc0204b96:	8526                	mv	a0,s1
ffffffffc0204b98:	b75fe0ef          	jal	ra,ffffffffc020370c <mm_destroy>
ffffffffc0204b9c:	bf85                	j	ffffffffc0204b0c <do_fork+0x300>
    return KADDR(page2pa(page));
ffffffffc0204b9e:	00002617          	auipc	a2,0x2
ffffffffc0204ba2:	75260613          	addi	a2,a2,1874 # ffffffffc02072f0 <default_pmm_manager+0x38>
ffffffffc0204ba6:	07100593          	li	a1,113
ffffffffc0204baa:	00002517          	auipc	a0,0x2
ffffffffc0204bae:	76e50513          	addi	a0,a0,1902 # ffffffffc0207318 <default_pmm_manager+0x60>
ffffffffc0204bb2:	8e1fb0ef          	jal	ra,ffffffffc0200492 <__panic>
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc0204bb6:	86ba                	mv	a3,a4
ffffffffc0204bb8:	00002617          	auipc	a2,0x2
ffffffffc0204bbc:	7e060613          	addi	a2,a2,2016 # ffffffffc0207398 <default_pmm_manager+0xe0>
ffffffffc0204bc0:	18900593          	li	a1,393
ffffffffc0204bc4:	00003517          	auipc	a0,0x3
ffffffffc0204bc8:	5f450513          	addi	a0,a0,1524 # ffffffffc02081b8 <default_pmm_manager+0xf00>
ffffffffc0204bcc:	8c7fb0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0204bd0 <kernel_thread>:
{
ffffffffc0204bd0:	7129                	addi	sp,sp,-320
ffffffffc0204bd2:	fa22                	sd	s0,304(sp)
ffffffffc0204bd4:	f626                	sd	s1,296(sp)
ffffffffc0204bd6:	f24a                	sd	s2,288(sp)
ffffffffc0204bd8:	84ae                	mv	s1,a1
ffffffffc0204bda:	892a                	mv	s2,a0
ffffffffc0204bdc:	8432                	mv	s0,a2
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc0204bde:	4581                	li	a1,0
ffffffffc0204be0:	12000613          	li	a2,288
ffffffffc0204be4:	850a                	mv	a0,sp
{
ffffffffc0204be6:	fe06                	sd	ra,312(sp)
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc0204be8:	071010ef          	jal	ra,ffffffffc0206458 <memset>
    tf.gpr.s0 = (uintptr_t)fn;
ffffffffc0204bec:	e0ca                	sd	s2,64(sp)
    tf.gpr.s1 = (uintptr_t)arg;
ffffffffc0204bee:	e4a6                	sd	s1,72(sp)
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE;
ffffffffc0204bf0:	100027f3          	csrr	a5,sstatus
ffffffffc0204bf4:	edd7f793          	andi	a5,a5,-291
ffffffffc0204bf8:	1207e793          	ori	a5,a5,288
ffffffffc0204bfc:	e23e                	sd	a5,256(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc0204bfe:	860a                	mv	a2,sp
ffffffffc0204c00:	10046513          	ori	a0,s0,256
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc0204c04:	00000797          	auipc	a5,0x0
ffffffffc0204c08:	9e478793          	addi	a5,a5,-1564 # ffffffffc02045e8 <kernel_thread_entry>
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc0204c0c:	4581                	li	a1,0
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc0204c0e:	e63e                	sd	a5,264(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc0204c10:	bfdff0ef          	jal	ra,ffffffffc020480c <do_fork>
}
ffffffffc0204c14:	70f2                	ld	ra,312(sp)
ffffffffc0204c16:	7452                	ld	s0,304(sp)
ffffffffc0204c18:	74b2                	ld	s1,296(sp)
ffffffffc0204c1a:	7912                	ld	s2,288(sp)
ffffffffc0204c1c:	6131                	addi	sp,sp,320
ffffffffc0204c1e:	8082                	ret

ffffffffc0204c20 <do_exit>:
// do_exit - called by sys_exit
//   1. call exit_mmap & put_pgdir & mm_destroy to free the almost all memory space of process
//   2. set process' state as PROC_ZOMBIE, then call wakeup_proc(parent) to ask parent reclaim itself.
//   3. call scheduler to switch to other process
int do_exit(int error_code)
{
ffffffffc0204c20:	7179                	addi	sp,sp,-48
ffffffffc0204c22:	f022                	sd	s0,32(sp)
    if (current == idleproc)
ffffffffc0204c24:	000db417          	auipc	s0,0xdb
ffffffffc0204c28:	04c40413          	addi	s0,s0,76 # ffffffffc02dfc70 <current>
ffffffffc0204c2c:	601c                	ld	a5,0(s0)
{
ffffffffc0204c2e:	f406                	sd	ra,40(sp)
ffffffffc0204c30:	ec26                	sd	s1,24(sp)
ffffffffc0204c32:	e84a                	sd	s2,16(sp)
ffffffffc0204c34:	e44e                	sd	s3,8(sp)
ffffffffc0204c36:	e052                	sd	s4,0(sp)
    if (current == idleproc)
ffffffffc0204c38:	000db717          	auipc	a4,0xdb
ffffffffc0204c3c:	04073703          	ld	a4,64(a4) # ffffffffc02dfc78 <idleproc>
ffffffffc0204c40:	0ce78c63          	beq	a5,a4,ffffffffc0204d18 <do_exit+0xf8>
    {
        panic("idleproc exit.\n");
    }
    if (current == initproc)
ffffffffc0204c44:	000db497          	auipc	s1,0xdb
ffffffffc0204c48:	03c48493          	addi	s1,s1,60 # ffffffffc02dfc80 <initproc>
ffffffffc0204c4c:	6098                	ld	a4,0(s1)
ffffffffc0204c4e:	0ee78c63          	beq	a5,a4,ffffffffc0204d46 <do_exit+0x126>
    {
        panic("initproc exit.\n");
    }
    struct mm_struct *mm = current->mm;
ffffffffc0204c52:	0287b983          	ld	s3,40(a5)
ffffffffc0204c56:	892a                	mv	s2,a0
    if (mm != NULL)
ffffffffc0204c58:	02098663          	beqz	s3,ffffffffc0204c84 <do_exit+0x64>
ffffffffc0204c5c:	000db797          	auipc	a5,0xdb
ffffffffc0204c60:	fe47b783          	ld	a5,-28(a5) # ffffffffc02dfc40 <boot_pgdir_pa>
ffffffffc0204c64:	577d                	li	a4,-1
ffffffffc0204c66:	177e                	slli	a4,a4,0x3f
ffffffffc0204c68:	83b1                	srli	a5,a5,0xc
ffffffffc0204c6a:	8fd9                	or	a5,a5,a4
ffffffffc0204c6c:	18079073          	csrw	satp,a5
    mm->mm_count -= 1;
ffffffffc0204c70:	0309a783          	lw	a5,48(s3)
ffffffffc0204c74:	fff7871b          	addiw	a4,a5,-1
ffffffffc0204c78:	02e9a823          	sw	a4,48(s3)
    {
        lsatp(boot_pgdir_pa);
        if (mm_count_dec(mm) == 0)
ffffffffc0204c7c:	cb55                	beqz	a4,ffffffffc0204d30 <do_exit+0x110>
        {
            exit_mmap(mm);
            put_pgdir(mm);
            mm_destroy(mm);
        }
        current->mm = NULL;
ffffffffc0204c7e:	601c                	ld	a5,0(s0)
ffffffffc0204c80:	0207b423          	sd	zero,40(a5)
    }
    current->state = PROC_ZOMBIE;
ffffffffc0204c84:	601c                	ld	a5,0(s0)
ffffffffc0204c86:	470d                	li	a4,3
ffffffffc0204c88:	c398                	sw	a4,0(a5)
    current->exit_code = error_code;
ffffffffc0204c8a:	0f27a423          	sw	s2,232(a5)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0204c8e:	100027f3          	csrr	a5,sstatus
ffffffffc0204c92:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0204c94:	4a01                	li	s4,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0204c96:	e7e1                	bnez	a5,ffffffffc0204d5e <do_exit+0x13e>
    bool intr_flag;
    struct proc_struct *proc;
    local_intr_save(intr_flag);
    {
        proc = current->parent;
ffffffffc0204c98:	6018                	ld	a4,0(s0)
        if (proc->wait_state == WT_CHILD)
ffffffffc0204c9a:	800007b7          	lui	a5,0x80000
ffffffffc0204c9e:	0785                	addi	a5,a5,1
        proc = current->parent;
ffffffffc0204ca0:	7308                	ld	a0,32(a4)
        if (proc->wait_state == WT_CHILD)
ffffffffc0204ca2:	0ec52703          	lw	a4,236(a0)
ffffffffc0204ca6:	0cf70063          	beq	a4,a5,ffffffffc0204d66 <do_exit+0x146>
        {
            wakeup_proc(proc);
        }
        while (current->cptr != NULL)
ffffffffc0204caa:	6018                	ld	a4,0(s0)
ffffffffc0204cac:	7b7c                	ld	a5,240(a4)
ffffffffc0204cae:	c3a1                	beqz	a5,ffffffffc0204cee <do_exit+0xce>
            }
            proc->parent = initproc;
            initproc->cptr = proc;
            if (proc->state == PROC_ZOMBIE)
            {
                if (initproc->wait_state == WT_CHILD)
ffffffffc0204cb0:	800009b7          	lui	s3,0x80000
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204cb4:	490d                	li	s2,3
                if (initproc->wait_state == WT_CHILD)
ffffffffc0204cb6:	0985                	addi	s3,s3,1
ffffffffc0204cb8:	a021                	j	ffffffffc0204cc0 <do_exit+0xa0>
        while (current->cptr != NULL)
ffffffffc0204cba:	6018                	ld	a4,0(s0)
ffffffffc0204cbc:	7b7c                	ld	a5,240(a4)
ffffffffc0204cbe:	cb85                	beqz	a5,ffffffffc0204cee <do_exit+0xce>
            current->cptr = proc->optr;
ffffffffc0204cc0:	1007b683          	ld	a3,256(a5) # ffffffff80000100 <_binary_obj___user_matrix_out_size+0xffffffff7fff3800>
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc0204cc4:	6088                	ld	a0,0(s1)
            current->cptr = proc->optr;
ffffffffc0204cc6:	fb74                	sd	a3,240(a4)
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc0204cc8:	7978                	ld	a4,240(a0)
            proc->yptr = NULL;
ffffffffc0204cca:	0e07bc23          	sd	zero,248(a5)
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc0204cce:	10e7b023          	sd	a4,256(a5)
ffffffffc0204cd2:	c311                	beqz	a4,ffffffffc0204cd6 <do_exit+0xb6>
                initproc->cptr->yptr = proc;
ffffffffc0204cd4:	ff7c                	sd	a5,248(a4)
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204cd6:	4398                	lw	a4,0(a5)
            proc->parent = initproc;
ffffffffc0204cd8:	f388                	sd	a0,32(a5)
            initproc->cptr = proc;
ffffffffc0204cda:	f97c                	sd	a5,240(a0)
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204cdc:	fd271fe3          	bne	a4,s2,ffffffffc0204cba <do_exit+0x9a>
                if (initproc->wait_state == WT_CHILD)
ffffffffc0204ce0:	0ec52783          	lw	a5,236(a0)
ffffffffc0204ce4:	fd379be3          	bne	a5,s3,ffffffffc0204cba <do_exit+0x9a>
                {
                    wakeup_proc(initproc);
ffffffffc0204ce8:	5c7000ef          	jal	ra,ffffffffc0205aae <wakeup_proc>
ffffffffc0204cec:	b7f9                	j	ffffffffc0204cba <do_exit+0x9a>
    if (flag) {
ffffffffc0204cee:	020a1263          	bnez	s4,ffffffffc0204d12 <do_exit+0xf2>
                }
            }
        }
    }
    local_intr_restore(intr_flag);
    schedule();
ffffffffc0204cf2:	66f000ef          	jal	ra,ffffffffc0205b60 <schedule>
    panic("do_exit will not return!! %d.\n", current->pid);
ffffffffc0204cf6:	601c                	ld	a5,0(s0)
ffffffffc0204cf8:	00003617          	auipc	a2,0x3
ffffffffc0204cfc:	4f860613          	addi	a2,a2,1272 # ffffffffc02081f0 <default_pmm_manager+0xf38>
ffffffffc0204d00:	24500593          	li	a1,581
ffffffffc0204d04:	43d4                	lw	a3,4(a5)
ffffffffc0204d06:	00003517          	auipc	a0,0x3
ffffffffc0204d0a:	4b250513          	addi	a0,a0,1202 # ffffffffc02081b8 <default_pmm_manager+0xf00>
ffffffffc0204d0e:	f84fb0ef          	jal	ra,ffffffffc0200492 <__panic>
        intr_enable();
ffffffffc0204d12:	c97fb0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0204d16:	bff1                	j	ffffffffc0204cf2 <do_exit+0xd2>
        panic("idleproc exit.\n");
ffffffffc0204d18:	00003617          	auipc	a2,0x3
ffffffffc0204d1c:	4b860613          	addi	a2,a2,1208 # ffffffffc02081d0 <default_pmm_manager+0xf18>
ffffffffc0204d20:	21100593          	li	a1,529
ffffffffc0204d24:	00003517          	auipc	a0,0x3
ffffffffc0204d28:	49450513          	addi	a0,a0,1172 # ffffffffc02081b8 <default_pmm_manager+0xf00>
ffffffffc0204d2c:	f66fb0ef          	jal	ra,ffffffffc0200492 <__panic>
            exit_mmap(mm);
ffffffffc0204d30:	854e                	mv	a0,s3
ffffffffc0204d32:	b77fe0ef          	jal	ra,ffffffffc02038a8 <exit_mmap>
            put_pgdir(mm);
ffffffffc0204d36:	0189b503          	ld	a0,24(s3) # ffffffff80000018 <_binary_obj___user_matrix_out_size+0xffffffff7fff3718>
ffffffffc0204d3a:	96fff0ef          	jal	ra,ffffffffc02046a8 <put_pgdir.isra.0>
            mm_destroy(mm);
ffffffffc0204d3e:	854e                	mv	a0,s3
ffffffffc0204d40:	9cdfe0ef          	jal	ra,ffffffffc020370c <mm_destroy>
ffffffffc0204d44:	bf2d                	j	ffffffffc0204c7e <do_exit+0x5e>
        panic("initproc exit.\n");
ffffffffc0204d46:	00003617          	auipc	a2,0x3
ffffffffc0204d4a:	49a60613          	addi	a2,a2,1178 # ffffffffc02081e0 <default_pmm_manager+0xf28>
ffffffffc0204d4e:	21500593          	li	a1,533
ffffffffc0204d52:	00003517          	auipc	a0,0x3
ffffffffc0204d56:	46650513          	addi	a0,a0,1126 # ffffffffc02081b8 <default_pmm_manager+0xf00>
ffffffffc0204d5a:	f38fb0ef          	jal	ra,ffffffffc0200492 <__panic>
        intr_disable();
ffffffffc0204d5e:	c51fb0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        return 1;
ffffffffc0204d62:	4a05                	li	s4,1
ffffffffc0204d64:	bf15                	j	ffffffffc0204c98 <do_exit+0x78>
            wakeup_proc(proc);
ffffffffc0204d66:	549000ef          	jal	ra,ffffffffc0205aae <wakeup_proc>
ffffffffc0204d6a:	b781                	j	ffffffffc0204caa <do_exit+0x8a>

ffffffffc0204d6c <do_wait.part.0>:
}

// do_wait - wait one OR any children with PROC_ZOMBIE state, and free memory space of kernel stack
//         - proc struct of this child.
// NOTE: only after do_wait function, all resources of the child proces are free.
int do_wait(int pid, int *code_store)
ffffffffc0204d6c:	715d                	addi	sp,sp,-80
ffffffffc0204d6e:	f84a                	sd	s2,48(sp)
ffffffffc0204d70:	f44e                	sd	s3,40(sp)
        }
    }
    if (haskid)
    {
        current->state = PROC_SLEEPING;
        current->wait_state = WT_CHILD;
ffffffffc0204d72:	80000937          	lui	s2,0x80000
    if (0 < pid && pid < MAX_PID)
ffffffffc0204d76:	6989                	lui	s3,0x2
int do_wait(int pid, int *code_store)
ffffffffc0204d78:	fc26                	sd	s1,56(sp)
ffffffffc0204d7a:	f052                	sd	s4,32(sp)
ffffffffc0204d7c:	ec56                	sd	s5,24(sp)
ffffffffc0204d7e:	e85a                	sd	s6,16(sp)
ffffffffc0204d80:	e45e                	sd	s7,8(sp)
ffffffffc0204d82:	e486                	sd	ra,72(sp)
ffffffffc0204d84:	e0a2                	sd	s0,64(sp)
ffffffffc0204d86:	84aa                	mv	s1,a0
ffffffffc0204d88:	8a2e                	mv	s4,a1
        proc = current->cptr;
ffffffffc0204d8a:	000dbb97          	auipc	s7,0xdb
ffffffffc0204d8e:	ee6b8b93          	addi	s7,s7,-282 # ffffffffc02dfc70 <current>
    if (0 < pid && pid < MAX_PID)
ffffffffc0204d92:	00050b1b          	sext.w	s6,a0
ffffffffc0204d96:	fff50a9b          	addiw	s5,a0,-1
ffffffffc0204d9a:	19f9                	addi	s3,s3,-2
        current->wait_state = WT_CHILD;
ffffffffc0204d9c:	0905                	addi	s2,s2,1
    if (pid != 0)
ffffffffc0204d9e:	ccbd                	beqz	s1,ffffffffc0204e1c <do_wait.part.0+0xb0>
    if (0 < pid && pid < MAX_PID)
ffffffffc0204da0:	0359e863          	bltu	s3,s5,ffffffffc0204dd0 <do_wait.part.0+0x64>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204da4:	45a9                	li	a1,10
ffffffffc0204da6:	855a                	mv	a0,s6
ffffffffc0204da8:	20a010ef          	jal	ra,ffffffffc0205fb2 <hash32>
ffffffffc0204dac:	02051793          	slli	a5,a0,0x20
ffffffffc0204db0:	01c7d513          	srli	a0,a5,0x1c
ffffffffc0204db4:	000d7797          	auipc	a5,0xd7
ffffffffc0204db8:	e2478793          	addi	a5,a5,-476 # ffffffffc02dbbd8 <hash_list>
ffffffffc0204dbc:	953e                	add	a0,a0,a5
ffffffffc0204dbe:	842a                	mv	s0,a0
        while ((le = list_next(le)) != list)
ffffffffc0204dc0:	a029                	j	ffffffffc0204dca <do_wait.part.0+0x5e>
            if (proc->pid == pid)
ffffffffc0204dc2:	f2c42783          	lw	a5,-212(s0)
ffffffffc0204dc6:	02978163          	beq	a5,s1,ffffffffc0204de8 <do_wait.part.0+0x7c>
ffffffffc0204dca:	6400                	ld	s0,8(s0)
        while ((le = list_next(le)) != list)
ffffffffc0204dcc:	fe851be3          	bne	a0,s0,ffffffffc0204dc2 <do_wait.part.0+0x56>
        {
            do_exit(-E_KILLED);
        }
        goto repeat;
    }
    return -E_BAD_PROC;
ffffffffc0204dd0:	5579                	li	a0,-2
    }
    local_intr_restore(intr_flag);
    put_kstack(proc);
    kfree(proc);
    return 0;
}
ffffffffc0204dd2:	60a6                	ld	ra,72(sp)
ffffffffc0204dd4:	6406                	ld	s0,64(sp)
ffffffffc0204dd6:	74e2                	ld	s1,56(sp)
ffffffffc0204dd8:	7942                	ld	s2,48(sp)
ffffffffc0204dda:	79a2                	ld	s3,40(sp)
ffffffffc0204ddc:	7a02                	ld	s4,32(sp)
ffffffffc0204dde:	6ae2                	ld	s5,24(sp)
ffffffffc0204de0:	6b42                	ld	s6,16(sp)
ffffffffc0204de2:	6ba2                	ld	s7,8(sp)
ffffffffc0204de4:	6161                	addi	sp,sp,80
ffffffffc0204de6:	8082                	ret
        if (proc != NULL && proc->parent == current)
ffffffffc0204de8:	000bb683          	ld	a3,0(s7)
ffffffffc0204dec:	f4843783          	ld	a5,-184(s0)
ffffffffc0204df0:	fed790e3          	bne	a5,a3,ffffffffc0204dd0 <do_wait.part.0+0x64>
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204df4:	f2842703          	lw	a4,-216(s0)
ffffffffc0204df8:	478d                	li	a5,3
ffffffffc0204dfa:	0ef70b63          	beq	a4,a5,ffffffffc0204ef0 <do_wait.part.0+0x184>
        current->state = PROC_SLEEPING;
ffffffffc0204dfe:	4785                	li	a5,1
ffffffffc0204e00:	c29c                	sw	a5,0(a3)
        current->wait_state = WT_CHILD;
ffffffffc0204e02:	0f26a623          	sw	s2,236(a3)
        schedule();
ffffffffc0204e06:	55b000ef          	jal	ra,ffffffffc0205b60 <schedule>
        if (current->flags & PF_EXITING)
ffffffffc0204e0a:	000bb783          	ld	a5,0(s7)
ffffffffc0204e0e:	0b07a783          	lw	a5,176(a5)
ffffffffc0204e12:	8b85                	andi	a5,a5,1
ffffffffc0204e14:	d7c9                	beqz	a5,ffffffffc0204d9e <do_wait.part.0+0x32>
            do_exit(-E_KILLED);
ffffffffc0204e16:	555d                	li	a0,-9
ffffffffc0204e18:	e09ff0ef          	jal	ra,ffffffffc0204c20 <do_exit>
        proc = current->cptr;
ffffffffc0204e1c:	000bb683          	ld	a3,0(s7)
ffffffffc0204e20:	7ae0                	ld	s0,240(a3)
        for (; proc != NULL; proc = proc->optr)
ffffffffc0204e22:	d45d                	beqz	s0,ffffffffc0204dd0 <do_wait.part.0+0x64>
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204e24:	470d                	li	a4,3
ffffffffc0204e26:	a021                	j	ffffffffc0204e2e <do_wait.part.0+0xc2>
        for (; proc != NULL; proc = proc->optr)
ffffffffc0204e28:	10043403          	ld	s0,256(s0)
ffffffffc0204e2c:	d869                	beqz	s0,ffffffffc0204dfe <do_wait.part.0+0x92>
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204e2e:	401c                	lw	a5,0(s0)
ffffffffc0204e30:	fee79ce3          	bne	a5,a4,ffffffffc0204e28 <do_wait.part.0+0xbc>
    if (proc == idleproc || proc == initproc)
ffffffffc0204e34:	000db797          	auipc	a5,0xdb
ffffffffc0204e38:	e447b783          	ld	a5,-444(a5) # ffffffffc02dfc78 <idleproc>
ffffffffc0204e3c:	0c878963          	beq	a5,s0,ffffffffc0204f0e <do_wait.part.0+0x1a2>
ffffffffc0204e40:	000db797          	auipc	a5,0xdb
ffffffffc0204e44:	e407b783          	ld	a5,-448(a5) # ffffffffc02dfc80 <initproc>
ffffffffc0204e48:	0cf40363          	beq	s0,a5,ffffffffc0204f0e <do_wait.part.0+0x1a2>
    if (code_store != NULL)
ffffffffc0204e4c:	000a0663          	beqz	s4,ffffffffc0204e58 <do_wait.part.0+0xec>
        *code_store = proc->exit_code;
ffffffffc0204e50:	0e842783          	lw	a5,232(s0)
ffffffffc0204e54:	00fa2023          	sw	a5,0(s4)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0204e58:	100027f3          	csrr	a5,sstatus
ffffffffc0204e5c:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0204e5e:	4581                	li	a1,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0204e60:	e7c1                	bnez	a5,ffffffffc0204ee8 <do_wait.part.0+0x17c>
    __list_del(listelm->prev, listelm->next);
ffffffffc0204e62:	6c70                	ld	a2,216(s0)
ffffffffc0204e64:	7074                	ld	a3,224(s0)
    if (proc->optr != NULL)
ffffffffc0204e66:	10043703          	ld	a4,256(s0)
        proc->optr->yptr = proc->yptr;
ffffffffc0204e6a:	7c7c                	ld	a5,248(s0)
    prev->next = next;
ffffffffc0204e6c:	e614                	sd	a3,8(a2)
    next->prev = prev;
ffffffffc0204e6e:	e290                	sd	a2,0(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc0204e70:	6470                	ld	a2,200(s0)
ffffffffc0204e72:	6874                	ld	a3,208(s0)
    prev->next = next;
ffffffffc0204e74:	e614                	sd	a3,8(a2)
    next->prev = prev;
ffffffffc0204e76:	e290                	sd	a2,0(a3)
    if (proc->optr != NULL)
ffffffffc0204e78:	c319                	beqz	a4,ffffffffc0204e7e <do_wait.part.0+0x112>
        proc->optr->yptr = proc->yptr;
ffffffffc0204e7a:	ff7c                	sd	a5,248(a4)
    if (proc->yptr != NULL)
ffffffffc0204e7c:	7c7c                	ld	a5,248(s0)
ffffffffc0204e7e:	c3b5                	beqz	a5,ffffffffc0204ee2 <do_wait.part.0+0x176>
        proc->yptr->optr = proc->optr;
ffffffffc0204e80:	10e7b023          	sd	a4,256(a5)
    nr_process--;
ffffffffc0204e84:	000db717          	auipc	a4,0xdb
ffffffffc0204e88:	e0470713          	addi	a4,a4,-508 # ffffffffc02dfc88 <nr_process>
ffffffffc0204e8c:	431c                	lw	a5,0(a4)
ffffffffc0204e8e:	37fd                	addiw	a5,a5,-1
ffffffffc0204e90:	c31c                	sw	a5,0(a4)
    if (flag) {
ffffffffc0204e92:	e5a9                	bnez	a1,ffffffffc0204edc <do_wait.part.0+0x170>
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
ffffffffc0204e94:	6814                	ld	a3,16(s0)
    return pa2page(PADDR(kva));
ffffffffc0204e96:	c02007b7          	lui	a5,0xc0200
ffffffffc0204e9a:	04f6ee63          	bltu	a3,a5,ffffffffc0204ef6 <do_wait.part.0+0x18a>
ffffffffc0204e9e:	000db797          	auipc	a5,0xdb
ffffffffc0204ea2:	dca7b783          	ld	a5,-566(a5) # ffffffffc02dfc68 <va_pa_offset>
ffffffffc0204ea6:	8e9d                	sub	a3,a3,a5
    if (PPN(pa) >= npage)
ffffffffc0204ea8:	82b1                	srli	a3,a3,0xc
ffffffffc0204eaa:	000db797          	auipc	a5,0xdb
ffffffffc0204eae:	da67b783          	ld	a5,-602(a5) # ffffffffc02dfc50 <npage>
ffffffffc0204eb2:	06f6fa63          	bgeu	a3,a5,ffffffffc0204f26 <do_wait.part.0+0x1ba>
    return &pages[PPN(pa) - nbase];
ffffffffc0204eb6:	00004517          	auipc	a0,0x4
ffffffffc0204eba:	3ba53503          	ld	a0,954(a0) # ffffffffc0209270 <nbase>
ffffffffc0204ebe:	8e89                	sub	a3,a3,a0
ffffffffc0204ec0:	069a                	slli	a3,a3,0x6
ffffffffc0204ec2:	000db517          	auipc	a0,0xdb
ffffffffc0204ec6:	d9653503          	ld	a0,-618(a0) # ffffffffc02dfc58 <pages>
ffffffffc0204eca:	9536                	add	a0,a0,a3
ffffffffc0204ecc:	4589                	li	a1,2
ffffffffc0204ece:	ee9fc0ef          	jal	ra,ffffffffc0201db6 <free_pages>
    kfree(proc);
ffffffffc0204ed2:	8522                	mv	a0,s0
ffffffffc0204ed4:	d77fc0ef          	jal	ra,ffffffffc0201c4a <kfree>
    return 0;
ffffffffc0204ed8:	4501                	li	a0,0
ffffffffc0204eda:	bde5                	j	ffffffffc0204dd2 <do_wait.part.0+0x66>
        intr_enable();
ffffffffc0204edc:	acdfb0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0204ee0:	bf55                	j	ffffffffc0204e94 <do_wait.part.0+0x128>
        proc->parent->cptr = proc->optr;
ffffffffc0204ee2:	701c                	ld	a5,32(s0)
ffffffffc0204ee4:	fbf8                	sd	a4,240(a5)
ffffffffc0204ee6:	bf79                	j	ffffffffc0204e84 <do_wait.part.0+0x118>
        intr_disable();
ffffffffc0204ee8:	ac7fb0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        return 1;
ffffffffc0204eec:	4585                	li	a1,1
ffffffffc0204eee:	bf95                	j	ffffffffc0204e62 <do_wait.part.0+0xf6>
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc0204ef0:	f2840413          	addi	s0,s0,-216
ffffffffc0204ef4:	b781                	j	ffffffffc0204e34 <do_wait.part.0+0xc8>
    return pa2page(PADDR(kva));
ffffffffc0204ef6:	00002617          	auipc	a2,0x2
ffffffffc0204efa:	4a260613          	addi	a2,a2,1186 # ffffffffc0207398 <default_pmm_manager+0xe0>
ffffffffc0204efe:	07700593          	li	a1,119
ffffffffc0204f02:	00002517          	auipc	a0,0x2
ffffffffc0204f06:	41650513          	addi	a0,a0,1046 # ffffffffc0207318 <default_pmm_manager+0x60>
ffffffffc0204f0a:	d88fb0ef          	jal	ra,ffffffffc0200492 <__panic>
        panic("wait idleproc or initproc.\n");
ffffffffc0204f0e:	00003617          	auipc	a2,0x3
ffffffffc0204f12:	30260613          	addi	a2,a2,770 # ffffffffc0208210 <default_pmm_manager+0xf58>
ffffffffc0204f16:	36f00593          	li	a1,879
ffffffffc0204f1a:	00003517          	auipc	a0,0x3
ffffffffc0204f1e:	29e50513          	addi	a0,a0,670 # ffffffffc02081b8 <default_pmm_manager+0xf00>
ffffffffc0204f22:	d70fb0ef          	jal	ra,ffffffffc0200492 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0204f26:	00002617          	auipc	a2,0x2
ffffffffc0204f2a:	49a60613          	addi	a2,a2,1178 # ffffffffc02073c0 <default_pmm_manager+0x108>
ffffffffc0204f2e:	06900593          	li	a1,105
ffffffffc0204f32:	00002517          	auipc	a0,0x2
ffffffffc0204f36:	3e650513          	addi	a0,a0,998 # ffffffffc0207318 <default_pmm_manager+0x60>
ffffffffc0204f3a:	d58fb0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0204f3e <init_main>:
}

// init_main - the second kernel thread used to create user_main kernel threads
static int
init_main(void *arg)
{
ffffffffc0204f3e:	1141                	addi	sp,sp,-16
ffffffffc0204f40:	e406                	sd	ra,8(sp)
    size_t nr_free_pages_store = nr_free_pages();
ffffffffc0204f42:	eb5fc0ef          	jal	ra,ffffffffc0201df6 <nr_free_pages>
    size_t kernel_allocated_store = kallocated();
ffffffffc0204f46:	c51fc0ef          	jal	ra,ffffffffc0201b96 <kallocated>

    int pid = kernel_thread(user_main, NULL, 0);
ffffffffc0204f4a:	4601                	li	a2,0
ffffffffc0204f4c:	4581                	li	a1,0
ffffffffc0204f4e:	00000517          	auipc	a0,0x0
ffffffffc0204f52:	63250513          	addi	a0,a0,1586 # ffffffffc0205580 <user_main>
ffffffffc0204f56:	c7bff0ef          	jal	ra,ffffffffc0204bd0 <kernel_thread>
    if (pid <= 0)
ffffffffc0204f5a:	08a05a63          	blez	a0,ffffffffc0204fee <init_main+0xb0>
    {
        panic("create user_main failed.\n");
    }
    extern void check_sync(void);
    check_sync(); // check philosopher sync problem
ffffffffc0204f5e:	8eaff0ef          	jal	ra,ffffffffc0204048 <check_sync>

    while (do_wait(0, NULL) == 0)
ffffffffc0204f62:	a019                	j	ffffffffc0204f68 <init_main+0x2a>
    {
        schedule();
ffffffffc0204f64:	3fd000ef          	jal	ra,ffffffffc0205b60 <schedule>
    if (code_store != NULL)
ffffffffc0204f68:	4581                	li	a1,0
ffffffffc0204f6a:	4501                	li	a0,0
ffffffffc0204f6c:	e01ff0ef          	jal	ra,ffffffffc0204d6c <do_wait.part.0>
    while (do_wait(0, NULL) == 0)
ffffffffc0204f70:	d975                	beqz	a0,ffffffffc0204f64 <init_main+0x26>
    }

    cprintf("all user-mode processes have quit.\n");
ffffffffc0204f72:	00003517          	auipc	a0,0x3
ffffffffc0204f76:	2de50513          	addi	a0,a0,734 # ffffffffc0208250 <default_pmm_manager+0xf98>
ffffffffc0204f7a:	a1efb0ef          	jal	ra,ffffffffc0200198 <cprintf>
    assert(initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL);
ffffffffc0204f7e:	000db797          	auipc	a5,0xdb
ffffffffc0204f82:	d027b783          	ld	a5,-766(a5) # ffffffffc02dfc80 <initproc>
ffffffffc0204f86:	7bf8                	ld	a4,240(a5)
ffffffffc0204f88:	e339                	bnez	a4,ffffffffc0204fce <init_main+0x90>
ffffffffc0204f8a:	7ff8                	ld	a4,248(a5)
ffffffffc0204f8c:	e329                	bnez	a4,ffffffffc0204fce <init_main+0x90>
ffffffffc0204f8e:	1007b703          	ld	a4,256(a5)
ffffffffc0204f92:	ef15                	bnez	a4,ffffffffc0204fce <init_main+0x90>
    assert(nr_process == 2);
ffffffffc0204f94:	000db697          	auipc	a3,0xdb
ffffffffc0204f98:	cf46a683          	lw	a3,-780(a3) # ffffffffc02dfc88 <nr_process>
ffffffffc0204f9c:	4709                	li	a4,2
ffffffffc0204f9e:	0ae69463          	bne	a3,a4,ffffffffc0205046 <init_main+0x108>
    return listelm->next;
ffffffffc0204fa2:	000db697          	auipc	a3,0xdb
ffffffffc0204fa6:	c3668693          	addi	a3,a3,-970 # ffffffffc02dfbd8 <proc_list>
    assert(list_next(&proc_list) == &(initproc->list_link));
ffffffffc0204faa:	6698                	ld	a4,8(a3)
ffffffffc0204fac:	0c878793          	addi	a5,a5,200
ffffffffc0204fb0:	06f71b63          	bne	a4,a5,ffffffffc0205026 <init_main+0xe8>
    assert(list_prev(&proc_list) == &(initproc->list_link));
ffffffffc0204fb4:	629c                	ld	a5,0(a3)
ffffffffc0204fb6:	04f71863          	bne	a4,a5,ffffffffc0205006 <init_main+0xc8>

    cprintf("init check memory pass.\n");
ffffffffc0204fba:	00003517          	auipc	a0,0x3
ffffffffc0204fbe:	37e50513          	addi	a0,a0,894 # ffffffffc0208338 <default_pmm_manager+0x1080>
ffffffffc0204fc2:	9d6fb0ef          	jal	ra,ffffffffc0200198 <cprintf>
    return 0;
}
ffffffffc0204fc6:	60a2                	ld	ra,8(sp)
ffffffffc0204fc8:	4501                	li	a0,0
ffffffffc0204fca:	0141                	addi	sp,sp,16
ffffffffc0204fcc:	8082                	ret
    assert(initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL);
ffffffffc0204fce:	00003697          	auipc	a3,0x3
ffffffffc0204fd2:	2aa68693          	addi	a3,a3,682 # ffffffffc0208278 <default_pmm_manager+0xfc0>
ffffffffc0204fd6:	00002617          	auipc	a2,0x2
ffffffffc0204fda:	f3260613          	addi	a2,a2,-206 # ffffffffc0206f08 <commands+0x818>
ffffffffc0204fde:	3de00593          	li	a1,990
ffffffffc0204fe2:	00003517          	auipc	a0,0x3
ffffffffc0204fe6:	1d650513          	addi	a0,a0,470 # ffffffffc02081b8 <default_pmm_manager+0xf00>
ffffffffc0204fea:	ca8fb0ef          	jal	ra,ffffffffc0200492 <__panic>
        panic("create user_main failed.\n");
ffffffffc0204fee:	00003617          	auipc	a2,0x3
ffffffffc0204ff2:	24260613          	addi	a2,a2,578 # ffffffffc0208230 <default_pmm_manager+0xf78>
ffffffffc0204ff6:	3d300593          	li	a1,979
ffffffffc0204ffa:	00003517          	auipc	a0,0x3
ffffffffc0204ffe:	1be50513          	addi	a0,a0,446 # ffffffffc02081b8 <default_pmm_manager+0xf00>
ffffffffc0205002:	c90fb0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(list_prev(&proc_list) == &(initproc->list_link));
ffffffffc0205006:	00003697          	auipc	a3,0x3
ffffffffc020500a:	30268693          	addi	a3,a3,770 # ffffffffc0208308 <default_pmm_manager+0x1050>
ffffffffc020500e:	00002617          	auipc	a2,0x2
ffffffffc0205012:	efa60613          	addi	a2,a2,-262 # ffffffffc0206f08 <commands+0x818>
ffffffffc0205016:	3e100593          	li	a1,993
ffffffffc020501a:	00003517          	auipc	a0,0x3
ffffffffc020501e:	19e50513          	addi	a0,a0,414 # ffffffffc02081b8 <default_pmm_manager+0xf00>
ffffffffc0205022:	c70fb0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(list_next(&proc_list) == &(initproc->list_link));
ffffffffc0205026:	00003697          	auipc	a3,0x3
ffffffffc020502a:	2b268693          	addi	a3,a3,690 # ffffffffc02082d8 <default_pmm_manager+0x1020>
ffffffffc020502e:	00002617          	auipc	a2,0x2
ffffffffc0205032:	eda60613          	addi	a2,a2,-294 # ffffffffc0206f08 <commands+0x818>
ffffffffc0205036:	3e000593          	li	a1,992
ffffffffc020503a:	00003517          	auipc	a0,0x3
ffffffffc020503e:	17e50513          	addi	a0,a0,382 # ffffffffc02081b8 <default_pmm_manager+0xf00>
ffffffffc0205042:	c50fb0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(nr_process == 2);
ffffffffc0205046:	00003697          	auipc	a3,0x3
ffffffffc020504a:	28268693          	addi	a3,a3,642 # ffffffffc02082c8 <default_pmm_manager+0x1010>
ffffffffc020504e:	00002617          	auipc	a2,0x2
ffffffffc0205052:	eba60613          	addi	a2,a2,-326 # ffffffffc0206f08 <commands+0x818>
ffffffffc0205056:	3df00593          	li	a1,991
ffffffffc020505a:	00003517          	auipc	a0,0x3
ffffffffc020505e:	15e50513          	addi	a0,a0,350 # ffffffffc02081b8 <default_pmm_manager+0xf00>
ffffffffc0205062:	c30fb0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0205066 <do_execve>:
{
ffffffffc0205066:	7171                	addi	sp,sp,-176
ffffffffc0205068:	e4ee                	sd	s11,72(sp)
    struct mm_struct *mm = current->mm;
ffffffffc020506a:	000dbd97          	auipc	s11,0xdb
ffffffffc020506e:	c06d8d93          	addi	s11,s11,-1018 # ffffffffc02dfc70 <current>
ffffffffc0205072:	000db783          	ld	a5,0(s11)
{
ffffffffc0205076:	e54e                	sd	s3,136(sp)
ffffffffc0205078:	ed26                	sd	s1,152(sp)
    struct mm_struct *mm = current->mm;
ffffffffc020507a:	0287b983          	ld	s3,40(a5)
{
ffffffffc020507e:	e94a                	sd	s2,144(sp)
ffffffffc0205080:	f4de                	sd	s7,104(sp)
ffffffffc0205082:	892a                	mv	s2,a0
ffffffffc0205084:	8bb2                	mv	s7,a2
ffffffffc0205086:	84ae                	mv	s1,a1
    if (!user_mem_check(mm, (uintptr_t)name, len, 0))
ffffffffc0205088:	862e                	mv	a2,a1
ffffffffc020508a:	4681                	li	a3,0
ffffffffc020508c:	85aa                	mv	a1,a0
ffffffffc020508e:	854e                	mv	a0,s3
{
ffffffffc0205090:	f506                	sd	ra,168(sp)
ffffffffc0205092:	f122                	sd	s0,160(sp)
ffffffffc0205094:	e152                	sd	s4,128(sp)
ffffffffc0205096:	fcd6                	sd	s5,120(sp)
ffffffffc0205098:	f8da                	sd	s6,112(sp)
ffffffffc020509a:	f0e2                	sd	s8,96(sp)
ffffffffc020509c:	ece6                	sd	s9,88(sp)
ffffffffc020509e:	e8ea                	sd	s10,80(sp)
ffffffffc02050a0:	f05e                	sd	s7,32(sp)
    if (!user_mem_check(mm, (uintptr_t)name, len, 0))
ffffffffc02050a2:	ba7fe0ef          	jal	ra,ffffffffc0203c48 <user_mem_check>
ffffffffc02050a6:	40050d63          	beqz	a0,ffffffffc02054c0 <do_execve+0x45a>
    memset(local_name, 0, sizeof(local_name));
ffffffffc02050aa:	4641                	li	a2,16
ffffffffc02050ac:	4581                	li	a1,0
ffffffffc02050ae:	1808                	addi	a0,sp,48
ffffffffc02050b0:	3a8010ef          	jal	ra,ffffffffc0206458 <memset>
    memcpy(local_name, name, len);
ffffffffc02050b4:	47bd                	li	a5,15
ffffffffc02050b6:	8626                	mv	a2,s1
ffffffffc02050b8:	1e97e463          	bltu	a5,s1,ffffffffc02052a0 <do_execve+0x23a>
ffffffffc02050bc:	85ca                	mv	a1,s2
ffffffffc02050be:	1808                	addi	a0,sp,48
ffffffffc02050c0:	3aa010ef          	jal	ra,ffffffffc020646a <memcpy>
    if (mm != NULL)
ffffffffc02050c4:	1e098563          	beqz	s3,ffffffffc02052ae <do_execve+0x248>
        cputs("mm != NULL");
ffffffffc02050c8:	00003517          	auipc	a0,0x3
ffffffffc02050cc:	a2050513          	addi	a0,a0,-1504 # ffffffffc0207ae8 <default_pmm_manager+0x830>
ffffffffc02050d0:	900fb0ef          	jal	ra,ffffffffc02001d0 <cputs>
ffffffffc02050d4:	000db797          	auipc	a5,0xdb
ffffffffc02050d8:	b6c7b783          	ld	a5,-1172(a5) # ffffffffc02dfc40 <boot_pgdir_pa>
ffffffffc02050dc:	577d                	li	a4,-1
ffffffffc02050de:	177e                	slli	a4,a4,0x3f
ffffffffc02050e0:	83b1                	srli	a5,a5,0xc
ffffffffc02050e2:	8fd9                	or	a5,a5,a4
ffffffffc02050e4:	18079073          	csrw	satp,a5
ffffffffc02050e8:	0309a783          	lw	a5,48(s3) # 2030 <_binary_obj___user_faultread_out_size-0x80f8>
ffffffffc02050ec:	fff7871b          	addiw	a4,a5,-1
ffffffffc02050f0:	02e9a823          	sw	a4,48(s3)
        if (mm_count_dec(mm) == 0)
ffffffffc02050f4:	2c070663          	beqz	a4,ffffffffc02053c0 <do_execve+0x35a>
        current->mm = NULL;
ffffffffc02050f8:	000db783          	ld	a5,0(s11)
ffffffffc02050fc:	0207b423          	sd	zero,40(a5)
    if ((mm = mm_create()) == NULL)
ffffffffc0205100:	cbefe0ef          	jal	ra,ffffffffc02035be <mm_create>
ffffffffc0205104:	84aa                	mv	s1,a0
ffffffffc0205106:	1c050f63          	beqz	a0,ffffffffc02052e4 <do_execve+0x27e>
    if ((page = alloc_page()) == NULL)
ffffffffc020510a:	4505                	li	a0,1
ffffffffc020510c:	c6dfc0ef          	jal	ra,ffffffffc0201d78 <alloc_pages>
ffffffffc0205110:	3a050c63          	beqz	a0,ffffffffc02054c8 <do_execve+0x462>
    return page - pages + nbase;
ffffffffc0205114:	000dbc97          	auipc	s9,0xdb
ffffffffc0205118:	b44c8c93          	addi	s9,s9,-1212 # ffffffffc02dfc58 <pages>
ffffffffc020511c:	000cb683          	ld	a3,0(s9)
    return KADDR(page2pa(page));
ffffffffc0205120:	000dbc17          	auipc	s8,0xdb
ffffffffc0205124:	b30c0c13          	addi	s8,s8,-1232 # ffffffffc02dfc50 <npage>
    return page - pages + nbase;
ffffffffc0205128:	00004717          	auipc	a4,0x4
ffffffffc020512c:	14873703          	ld	a4,328(a4) # ffffffffc0209270 <nbase>
ffffffffc0205130:	40d506b3          	sub	a3,a0,a3
ffffffffc0205134:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0205136:	5afd                	li	s5,-1
ffffffffc0205138:	000c3783          	ld	a5,0(s8)
    return page - pages + nbase;
ffffffffc020513c:	96ba                	add	a3,a3,a4
ffffffffc020513e:	e83a                	sd	a4,16(sp)
    return KADDR(page2pa(page));
ffffffffc0205140:	00cad713          	srli	a4,s5,0xc
ffffffffc0205144:	ec3a                	sd	a4,24(sp)
ffffffffc0205146:	8f75                	and	a4,a4,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc0205148:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc020514a:	38f77363          	bgeu	a4,a5,ffffffffc02054d0 <do_execve+0x46a>
ffffffffc020514e:	000dbb17          	auipc	s6,0xdb
ffffffffc0205152:	b1ab0b13          	addi	s6,s6,-1254 # ffffffffc02dfc68 <va_pa_offset>
ffffffffc0205156:	000b3903          	ld	s2,0(s6)
    memcpy(pgdir, boot_pgdir_va, PGSIZE);
ffffffffc020515a:	6605                	lui	a2,0x1
ffffffffc020515c:	000db597          	auipc	a1,0xdb
ffffffffc0205160:	aec5b583          	ld	a1,-1300(a1) # ffffffffc02dfc48 <boot_pgdir_va>
ffffffffc0205164:	9936                	add	s2,s2,a3
ffffffffc0205166:	854a                	mv	a0,s2
ffffffffc0205168:	302010ef          	jal	ra,ffffffffc020646a <memcpy>
    if (elf->e_magic != ELF_MAGIC)
ffffffffc020516c:	7782                	ld	a5,32(sp)
ffffffffc020516e:	4398                	lw	a4,0(a5)
ffffffffc0205170:	464c47b7          	lui	a5,0x464c4
    mm->pgdir = pgdir;
ffffffffc0205174:	0124bc23          	sd	s2,24(s1)
    if (elf->e_magic != ELF_MAGIC)
ffffffffc0205178:	57f78793          	addi	a5,a5,1407 # 464c457f <_binary_obj___user_matrix_out_size+0x464b7c7f>
ffffffffc020517c:	14f71a63          	bne	a4,a5,ffffffffc02052d0 <do_execve+0x26a>
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc0205180:	7682                	ld	a3,32(sp)
ffffffffc0205182:	0386d703          	lhu	a4,56(a3)
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
ffffffffc0205186:	0206b983          	ld	s3,32(a3)
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc020518a:	00371793          	slli	a5,a4,0x3
ffffffffc020518e:	8f99                	sub	a5,a5,a4
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
ffffffffc0205190:	99b6                	add	s3,s3,a3
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc0205192:	078e                	slli	a5,a5,0x3
ffffffffc0205194:	97ce                	add	a5,a5,s3
ffffffffc0205196:	f43e                	sd	a5,40(sp)
    for (; ph < ph_end; ph++)
ffffffffc0205198:	00f9fc63          	bgeu	s3,a5,ffffffffc02051b0 <do_execve+0x14a>
        if (ph->p_type != ELF_PT_LOAD)
ffffffffc020519c:	0009a783          	lw	a5,0(s3)
ffffffffc02051a0:	4705                	li	a4,1
ffffffffc02051a2:	14e78363          	beq	a5,a4,ffffffffc02052e8 <do_execve+0x282>
    for (; ph < ph_end; ph++)
ffffffffc02051a6:	77a2                	ld	a5,40(sp)
ffffffffc02051a8:	03898993          	addi	s3,s3,56
ffffffffc02051ac:	fef9e8e3          	bltu	s3,a5,ffffffffc020519c <do_execve+0x136>
    if ((ret = mm_map(mm, USTACKTOP - USTACKSIZE, USTACKSIZE, vm_flags, NULL)) != 0)
ffffffffc02051b0:	4701                	li	a4,0
ffffffffc02051b2:	46ad                	li	a3,11
ffffffffc02051b4:	00100637          	lui	a2,0x100
ffffffffc02051b8:	7ff005b7          	lui	a1,0x7ff00
ffffffffc02051bc:	8526                	mv	a0,s1
ffffffffc02051be:	da0fe0ef          	jal	ra,ffffffffc020375e <mm_map>
ffffffffc02051c2:	8a2a                	mv	s4,a0
ffffffffc02051c4:	1e051463          	bnez	a0,ffffffffc02053ac <do_execve+0x346>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - PGSIZE, PTE_USER) != NULL);
ffffffffc02051c8:	6c88                	ld	a0,24(s1)
ffffffffc02051ca:	467d                	li	a2,31
ffffffffc02051cc:	7ffff5b7          	lui	a1,0x7ffff
ffffffffc02051d0:	b08fe0ef          	jal	ra,ffffffffc02034d8 <pgdir_alloc_page>
ffffffffc02051d4:	38050663          	beqz	a0,ffffffffc0205560 <do_execve+0x4fa>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 2 * PGSIZE, PTE_USER) != NULL);
ffffffffc02051d8:	6c88                	ld	a0,24(s1)
ffffffffc02051da:	467d                	li	a2,31
ffffffffc02051dc:	7fffe5b7          	lui	a1,0x7fffe
ffffffffc02051e0:	af8fe0ef          	jal	ra,ffffffffc02034d8 <pgdir_alloc_page>
ffffffffc02051e4:	34050e63          	beqz	a0,ffffffffc0205540 <do_execve+0x4da>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 3 * PGSIZE, PTE_USER) != NULL);
ffffffffc02051e8:	6c88                	ld	a0,24(s1)
ffffffffc02051ea:	467d                	li	a2,31
ffffffffc02051ec:	7fffd5b7          	lui	a1,0x7fffd
ffffffffc02051f0:	ae8fe0ef          	jal	ra,ffffffffc02034d8 <pgdir_alloc_page>
ffffffffc02051f4:	32050663          	beqz	a0,ffffffffc0205520 <do_execve+0x4ba>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 4 * PGSIZE, PTE_USER) != NULL);
ffffffffc02051f8:	6c88                	ld	a0,24(s1)
ffffffffc02051fa:	467d                	li	a2,31
ffffffffc02051fc:	7fffc5b7          	lui	a1,0x7fffc
ffffffffc0205200:	ad8fe0ef          	jal	ra,ffffffffc02034d8 <pgdir_alloc_page>
ffffffffc0205204:	2e050e63          	beqz	a0,ffffffffc0205500 <do_execve+0x49a>
    mm->mm_count += 1;
ffffffffc0205208:	589c                	lw	a5,48(s1)
    current->mm = mm;
ffffffffc020520a:	000db603          	ld	a2,0(s11)
    current->pgdir = PADDR(mm->pgdir);
ffffffffc020520e:	6c94                	ld	a3,24(s1)
ffffffffc0205210:	2785                	addiw	a5,a5,1
ffffffffc0205212:	d89c                	sw	a5,48(s1)
    current->mm = mm;
ffffffffc0205214:	f604                	sd	s1,40(a2)
    current->pgdir = PADDR(mm->pgdir);
ffffffffc0205216:	c02007b7          	lui	a5,0xc0200
ffffffffc020521a:	2cf6e763          	bltu	a3,a5,ffffffffc02054e8 <do_execve+0x482>
ffffffffc020521e:	000b3783          	ld	a5,0(s6)
ffffffffc0205222:	577d                	li	a4,-1
ffffffffc0205224:	177e                	slli	a4,a4,0x3f
ffffffffc0205226:	8e9d                	sub	a3,a3,a5
ffffffffc0205228:	00c6d793          	srli	a5,a3,0xc
ffffffffc020522c:	f654                	sd	a3,168(a2)
ffffffffc020522e:	8fd9                	or	a5,a5,a4
ffffffffc0205230:	18079073          	csrw	satp,a5
    struct trapframe *tf = current->tf;
ffffffffc0205234:	7240                	ld	s0,160(a2)
    memset(tf, 0, sizeof(struct trapframe));
ffffffffc0205236:	4581                	li	a1,0
ffffffffc0205238:	12000613          	li	a2,288
ffffffffc020523c:	8522                	mv	a0,s0
    uintptr_t sstatus = tf->status;
ffffffffc020523e:	10043483          	ld	s1,256(s0)
    memset(tf, 0, sizeof(struct trapframe));
ffffffffc0205242:	216010ef          	jal	ra,ffffffffc0206458 <memset>
    tf->epc = (uintptr_t)elf->e_entry;
ffffffffc0205246:	7782                	ld	a5,32(sp)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0205248:	000db903          	ld	s2,0(s11)
    tf->status = (sstatus & ~SSTATUS_SPP) | SSTATUS_SPIE;
ffffffffc020524c:	edf4f493          	andi	s1,s1,-289
    tf->epc = (uintptr_t)elf->e_entry;
ffffffffc0205250:	6f98                	ld	a4,24(a5)
    tf->gpr.sp = (uintptr_t)USTACKTOP;
ffffffffc0205252:	4785                	li	a5,1
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0205254:	0b490913          	addi	s2,s2,180 # ffffffff800000b4 <_binary_obj___user_matrix_out_size+0xffffffff7fff37b4>
    tf->gpr.sp = (uintptr_t)USTACKTOP;
ffffffffc0205258:	07fe                	slli	a5,a5,0x1f
    tf->status = (sstatus & ~SSTATUS_SPP) | SSTATUS_SPIE;
ffffffffc020525a:	0204e493          	ori	s1,s1,32
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc020525e:	4641                	li	a2,16
ffffffffc0205260:	4581                	li	a1,0
    tf->gpr.sp = (uintptr_t)USTACKTOP;
ffffffffc0205262:	e81c                	sd	a5,16(s0)
    tf->epc = (uintptr_t)elf->e_entry;
ffffffffc0205264:	10e43423          	sd	a4,264(s0)
    tf->gpr.a0 = 0;  // 把 SSTATUS_SPP 设置为0，使得 sret 的时候能回到 U mode
ffffffffc0205268:	04043823          	sd	zero,80(s0)
    tf->status = (sstatus & ~SSTATUS_SPP) | SSTATUS_SPIE;
ffffffffc020526c:	10943023          	sd	s1,256(s0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0205270:	854a                	mv	a0,s2
ffffffffc0205272:	1e6010ef          	jal	ra,ffffffffc0206458 <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0205276:	463d                	li	a2,15
ffffffffc0205278:	180c                	addi	a1,sp,48
ffffffffc020527a:	854a                	mv	a0,s2
ffffffffc020527c:	1ee010ef          	jal	ra,ffffffffc020646a <memcpy>
}
ffffffffc0205280:	70aa                	ld	ra,168(sp)
ffffffffc0205282:	740a                	ld	s0,160(sp)
ffffffffc0205284:	64ea                	ld	s1,152(sp)
ffffffffc0205286:	694a                	ld	s2,144(sp)
ffffffffc0205288:	69aa                	ld	s3,136(sp)
ffffffffc020528a:	7ae6                	ld	s5,120(sp)
ffffffffc020528c:	7b46                	ld	s6,112(sp)
ffffffffc020528e:	7ba6                	ld	s7,104(sp)
ffffffffc0205290:	7c06                	ld	s8,96(sp)
ffffffffc0205292:	6ce6                	ld	s9,88(sp)
ffffffffc0205294:	6d46                	ld	s10,80(sp)
ffffffffc0205296:	6da6                	ld	s11,72(sp)
ffffffffc0205298:	8552                	mv	a0,s4
ffffffffc020529a:	6a0a                	ld	s4,128(sp)
ffffffffc020529c:	614d                	addi	sp,sp,176
ffffffffc020529e:	8082                	ret
    memcpy(local_name, name, len);
ffffffffc02052a0:	463d                	li	a2,15
ffffffffc02052a2:	85ca                	mv	a1,s2
ffffffffc02052a4:	1808                	addi	a0,sp,48
ffffffffc02052a6:	1c4010ef          	jal	ra,ffffffffc020646a <memcpy>
    if (mm != NULL)
ffffffffc02052aa:	e0099fe3          	bnez	s3,ffffffffc02050c8 <do_execve+0x62>
    if (current->mm != NULL)
ffffffffc02052ae:	000db783          	ld	a5,0(s11)
ffffffffc02052b2:	779c                	ld	a5,40(a5)
ffffffffc02052b4:	e40786e3          	beqz	a5,ffffffffc0205100 <do_execve+0x9a>
        panic("load_icode: current->mm must be empty.\n");
ffffffffc02052b8:	00003617          	auipc	a2,0x3
ffffffffc02052bc:	0a060613          	addi	a2,a2,160 # ffffffffc0208358 <default_pmm_manager+0x10a0>
ffffffffc02052c0:	25100593          	li	a1,593
ffffffffc02052c4:	00003517          	auipc	a0,0x3
ffffffffc02052c8:	ef450513          	addi	a0,a0,-268 # ffffffffc02081b8 <default_pmm_manager+0xf00>
ffffffffc02052cc:	9c6fb0ef          	jal	ra,ffffffffc0200492 <__panic>
    put_pgdir(mm);
ffffffffc02052d0:	854a                	mv	a0,s2
ffffffffc02052d2:	bd6ff0ef          	jal	ra,ffffffffc02046a8 <put_pgdir.isra.0>
    mm_destroy(mm);
ffffffffc02052d6:	8526                	mv	a0,s1
ffffffffc02052d8:	c34fe0ef          	jal	ra,ffffffffc020370c <mm_destroy>
        ret = -E_INVAL_ELF;
ffffffffc02052dc:	5a61                	li	s4,-8
    do_exit(ret);
ffffffffc02052de:	8552                	mv	a0,s4
ffffffffc02052e0:	941ff0ef          	jal	ra,ffffffffc0204c20 <do_exit>
    int ret = -E_NO_MEM;
ffffffffc02052e4:	5a71                	li	s4,-4
ffffffffc02052e6:	bfe5                	j	ffffffffc02052de <do_execve+0x278>
        if (ph->p_filesz > ph->p_memsz)
ffffffffc02052e8:	0289b603          	ld	a2,40(s3)
ffffffffc02052ec:	0209b783          	ld	a5,32(s3)
ffffffffc02052f0:	1cf66e63          	bltu	a2,a5,ffffffffc02054cc <do_execve+0x466>
        if (ph->p_flags & ELF_PF_X)
ffffffffc02052f4:	0049a783          	lw	a5,4(s3)
ffffffffc02052f8:	0017f693          	andi	a3,a5,1
ffffffffc02052fc:	c291                	beqz	a3,ffffffffc0205300 <do_execve+0x29a>
            vm_flags |= VM_EXEC;
ffffffffc02052fe:	4691                	li	a3,4
        if (ph->p_flags & ELF_PF_W)
ffffffffc0205300:	0027f713          	andi	a4,a5,2
        if (ph->p_flags & ELF_PF_R)
ffffffffc0205304:	8b91                	andi	a5,a5,4
        if (ph->p_flags & ELF_PF_W)
ffffffffc0205306:	eb61                	bnez	a4,ffffffffc02053d6 <do_execve+0x370>
        vm_flags = 0, perm = PTE_U | PTE_V;
ffffffffc0205308:	4d45                	li	s10,17
        if (ph->p_flags & ELF_PF_R)
ffffffffc020530a:	c781                	beqz	a5,ffffffffc0205312 <do_execve+0x2ac>
            vm_flags |= VM_READ;
ffffffffc020530c:	0016e693          	ori	a3,a3,1
            perm |= PTE_R;
ffffffffc0205310:	4d4d                	li	s10,19
        if (vm_flags & VM_WRITE)
ffffffffc0205312:	0026f793          	andi	a5,a3,2
ffffffffc0205316:	e3f9                	bnez	a5,ffffffffc02053dc <do_execve+0x376>
        if (vm_flags & VM_EXEC)
ffffffffc0205318:	0046f793          	andi	a5,a3,4
ffffffffc020531c:	c399                	beqz	a5,ffffffffc0205322 <do_execve+0x2bc>
            perm |= PTE_X;
ffffffffc020531e:	008d6d13          	ori	s10,s10,8
        if ((ret = mm_map(mm, ph->p_va, ph->p_memsz, vm_flags, NULL)) != 0)
ffffffffc0205322:	0109b583          	ld	a1,16(s3)
ffffffffc0205326:	4701                	li	a4,0
ffffffffc0205328:	8526                	mv	a0,s1
ffffffffc020532a:	c34fe0ef          	jal	ra,ffffffffc020375e <mm_map>
ffffffffc020532e:	8a2a                	mv	s4,a0
ffffffffc0205330:	ed35                	bnez	a0,ffffffffc02053ac <do_execve+0x346>
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc0205332:	0109bb83          	ld	s7,16(s3)
ffffffffc0205336:	77fd                	lui	a5,0xfffff
        end = ph->p_va + ph->p_filesz;
ffffffffc0205338:	0209ba03          	ld	s4,32(s3)
        unsigned char *from = binary + ph->p_offset;
ffffffffc020533c:	0089b903          	ld	s2,8(s3)
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc0205340:	00fbfab3          	and	s5,s7,a5
        unsigned char *from = binary + ph->p_offset;
ffffffffc0205344:	7782                	ld	a5,32(sp)
        end = ph->p_va + ph->p_filesz;
ffffffffc0205346:	9a5e                	add	s4,s4,s7
        unsigned char *from = binary + ph->p_offset;
ffffffffc0205348:	993e                	add	s2,s2,a5
        while (start < end)
ffffffffc020534a:	054be963          	bltu	s7,s4,ffffffffc020539c <do_execve+0x336>
ffffffffc020534e:	aa9d                	j	ffffffffc02054c4 <do_execve+0x45e>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0205350:	6785                	lui	a5,0x1
ffffffffc0205352:	415b8533          	sub	a0,s7,s5
ffffffffc0205356:	9abe                	add	s5,s5,a5
ffffffffc0205358:	417a8633          	sub	a2,s5,s7
            if (end < la)
ffffffffc020535c:	015a7463          	bgeu	s4,s5,ffffffffc0205364 <do_execve+0x2fe>
                size -= la - end;
ffffffffc0205360:	417a0633          	sub	a2,s4,s7
    return page - pages + nbase;
ffffffffc0205364:	000cb683          	ld	a3,0(s9)
ffffffffc0205368:	67c2                	ld	a5,16(sp)
    return KADDR(page2pa(page));
ffffffffc020536a:	000c3583          	ld	a1,0(s8)
    return page - pages + nbase;
ffffffffc020536e:	40d406b3          	sub	a3,s0,a3
ffffffffc0205372:	8699                	srai	a3,a3,0x6
ffffffffc0205374:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0205376:	67e2                	ld	a5,24(sp)
ffffffffc0205378:	00f6f833          	and	a6,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc020537c:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc020537e:	14b87963          	bgeu	a6,a1,ffffffffc02054d0 <do_execve+0x46a>
ffffffffc0205382:	000b3803          	ld	a6,0(s6)
            memcpy(page2kva(page) + off, from, size);
ffffffffc0205386:	85ca                	mv	a1,s2
            start += size, from += size;
ffffffffc0205388:	9bb2                	add	s7,s7,a2
ffffffffc020538a:	96c2                	add	a3,a3,a6
            memcpy(page2kva(page) + off, from, size);
ffffffffc020538c:	9536                	add	a0,a0,a3
            start += size, from += size;
ffffffffc020538e:	e432                	sd	a2,8(sp)
            memcpy(page2kva(page) + off, from, size);
ffffffffc0205390:	0da010ef          	jal	ra,ffffffffc020646a <memcpy>
            start += size, from += size;
ffffffffc0205394:	6622                	ld	a2,8(sp)
ffffffffc0205396:	9932                	add	s2,s2,a2
        while (start < end)
ffffffffc0205398:	054bf463          	bgeu	s7,s4,ffffffffc02053e0 <do_execve+0x37a>
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL)
ffffffffc020539c:	6c88                	ld	a0,24(s1)
ffffffffc020539e:	866a                	mv	a2,s10
ffffffffc02053a0:	85d6                	mv	a1,s5
ffffffffc02053a2:	936fe0ef          	jal	ra,ffffffffc02034d8 <pgdir_alloc_page>
ffffffffc02053a6:	842a                	mv	s0,a0
ffffffffc02053a8:	f545                	bnez	a0,ffffffffc0205350 <do_execve+0x2ea>
        ret = -E_NO_MEM;
ffffffffc02053aa:	5a71                	li	s4,-4
    exit_mmap(mm);
ffffffffc02053ac:	8526                	mv	a0,s1
ffffffffc02053ae:	cfafe0ef          	jal	ra,ffffffffc02038a8 <exit_mmap>
    put_pgdir(mm);
ffffffffc02053b2:	6c88                	ld	a0,24(s1)
ffffffffc02053b4:	af4ff0ef          	jal	ra,ffffffffc02046a8 <put_pgdir.isra.0>
    mm_destroy(mm);
ffffffffc02053b8:	8526                	mv	a0,s1
ffffffffc02053ba:	b52fe0ef          	jal	ra,ffffffffc020370c <mm_destroy>
    return ret;
ffffffffc02053be:	b705                	j	ffffffffc02052de <do_execve+0x278>
            exit_mmap(mm);
ffffffffc02053c0:	854e                	mv	a0,s3
ffffffffc02053c2:	ce6fe0ef          	jal	ra,ffffffffc02038a8 <exit_mmap>
            put_pgdir(mm);
ffffffffc02053c6:	0189b503          	ld	a0,24(s3)
ffffffffc02053ca:	adeff0ef          	jal	ra,ffffffffc02046a8 <put_pgdir.isra.0>
            mm_destroy(mm);
ffffffffc02053ce:	854e                	mv	a0,s3
ffffffffc02053d0:	b3cfe0ef          	jal	ra,ffffffffc020370c <mm_destroy>
ffffffffc02053d4:	b315                	j	ffffffffc02050f8 <do_execve+0x92>
            vm_flags |= VM_WRITE;
ffffffffc02053d6:	0026e693          	ori	a3,a3,2
        if (ph->p_flags & ELF_PF_R)
ffffffffc02053da:	fb8d                	bnez	a5,ffffffffc020530c <do_execve+0x2a6>
            perm |= (PTE_W | PTE_R);
ffffffffc02053dc:	4d5d                	li	s10,23
ffffffffc02053de:	bf2d                	j	ffffffffc0205318 <do_execve+0x2b2>
        end = ph->p_va + ph->p_memsz;
ffffffffc02053e0:	0109b683          	ld	a3,16(s3)
ffffffffc02053e4:	0289b903          	ld	s2,40(s3)
ffffffffc02053e8:	9936                	add	s2,s2,a3
        if (start < la)
ffffffffc02053ea:	075bfd63          	bgeu	s7,s5,ffffffffc0205464 <do_execve+0x3fe>
            if (start == end)
ffffffffc02053ee:	db790ce3          	beq	s2,s7,ffffffffc02051a6 <do_execve+0x140>
            off = start + PGSIZE - la, size = PGSIZE - off;
ffffffffc02053f2:	6785                	lui	a5,0x1
ffffffffc02053f4:	00fb8533          	add	a0,s7,a5
ffffffffc02053f8:	41550533          	sub	a0,a0,s5
                size -= la - end;
ffffffffc02053fc:	41790a33          	sub	s4,s2,s7
            if (end < la)
ffffffffc0205400:	0b597d63          	bgeu	s2,s5,ffffffffc02054ba <do_execve+0x454>
    return page - pages + nbase;
ffffffffc0205404:	000cb683          	ld	a3,0(s9)
ffffffffc0205408:	67c2                	ld	a5,16(sp)
    return KADDR(page2pa(page));
ffffffffc020540a:	000c3603          	ld	a2,0(s8)
    return page - pages + nbase;
ffffffffc020540e:	40d406b3          	sub	a3,s0,a3
ffffffffc0205412:	8699                	srai	a3,a3,0x6
ffffffffc0205414:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0205416:	67e2                	ld	a5,24(sp)
ffffffffc0205418:	00f6f5b3          	and	a1,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc020541c:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc020541e:	0ac5f963          	bgeu	a1,a2,ffffffffc02054d0 <do_execve+0x46a>
ffffffffc0205422:	000b3803          	ld	a6,0(s6)
            memset(page2kva(page) + off, 0, size);
ffffffffc0205426:	8652                	mv	a2,s4
ffffffffc0205428:	4581                	li	a1,0
ffffffffc020542a:	96c2                	add	a3,a3,a6
ffffffffc020542c:	9536                	add	a0,a0,a3
ffffffffc020542e:	02a010ef          	jal	ra,ffffffffc0206458 <memset>
            start += size;
ffffffffc0205432:	017a0733          	add	a4,s4,s7
            assert((end < la && start == end) || (end >= la && start == la));
ffffffffc0205436:	03597463          	bgeu	s2,s5,ffffffffc020545e <do_execve+0x3f8>
ffffffffc020543a:	d6e906e3          	beq	s2,a4,ffffffffc02051a6 <do_execve+0x140>
ffffffffc020543e:	00003697          	auipc	a3,0x3
ffffffffc0205442:	f4268693          	addi	a3,a3,-190 # ffffffffc0208380 <default_pmm_manager+0x10c8>
ffffffffc0205446:	00002617          	auipc	a2,0x2
ffffffffc020544a:	ac260613          	addi	a2,a2,-1342 # ffffffffc0206f08 <commands+0x818>
ffffffffc020544e:	2ba00593          	li	a1,698
ffffffffc0205452:	00003517          	auipc	a0,0x3
ffffffffc0205456:	d6650513          	addi	a0,a0,-666 # ffffffffc02081b8 <default_pmm_manager+0xf00>
ffffffffc020545a:	838fb0ef          	jal	ra,ffffffffc0200492 <__panic>
ffffffffc020545e:	ff5710e3          	bne	a4,s5,ffffffffc020543e <do_execve+0x3d8>
ffffffffc0205462:	8bd6                	mv	s7,s5
        while (start < end)
ffffffffc0205464:	d52bf1e3          	bgeu	s7,s2,ffffffffc02051a6 <do_execve+0x140>
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL)
ffffffffc0205468:	6c88                	ld	a0,24(s1)
ffffffffc020546a:	866a                	mv	a2,s10
ffffffffc020546c:	85d6                	mv	a1,s5
ffffffffc020546e:	86afe0ef          	jal	ra,ffffffffc02034d8 <pgdir_alloc_page>
ffffffffc0205472:	842a                	mv	s0,a0
ffffffffc0205474:	d91d                	beqz	a0,ffffffffc02053aa <do_execve+0x344>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0205476:	6785                	lui	a5,0x1
ffffffffc0205478:	415b8533          	sub	a0,s7,s5
ffffffffc020547c:	9abe                	add	s5,s5,a5
ffffffffc020547e:	417a8633          	sub	a2,s5,s7
            if (end < la)
ffffffffc0205482:	01597463          	bgeu	s2,s5,ffffffffc020548a <do_execve+0x424>
                size -= la - end;
ffffffffc0205486:	41790633          	sub	a2,s2,s7
    return page - pages + nbase;
ffffffffc020548a:	000cb683          	ld	a3,0(s9)
ffffffffc020548e:	67c2                	ld	a5,16(sp)
    return KADDR(page2pa(page));
ffffffffc0205490:	000c3583          	ld	a1,0(s8)
    return page - pages + nbase;
ffffffffc0205494:	40d406b3          	sub	a3,s0,a3
ffffffffc0205498:	8699                	srai	a3,a3,0x6
ffffffffc020549a:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc020549c:	67e2                	ld	a5,24(sp)
ffffffffc020549e:	00f6f833          	and	a6,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc02054a2:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02054a4:	02b87663          	bgeu	a6,a1,ffffffffc02054d0 <do_execve+0x46a>
ffffffffc02054a8:	000b3803          	ld	a6,0(s6)
            memset(page2kva(page) + off, 0, size);
ffffffffc02054ac:	4581                	li	a1,0
            start += size;
ffffffffc02054ae:	9bb2                	add	s7,s7,a2
ffffffffc02054b0:	96c2                	add	a3,a3,a6
            memset(page2kva(page) + off, 0, size);
ffffffffc02054b2:	9536                	add	a0,a0,a3
ffffffffc02054b4:	7a5000ef          	jal	ra,ffffffffc0206458 <memset>
ffffffffc02054b8:	b775                	j	ffffffffc0205464 <do_execve+0x3fe>
            off = start + PGSIZE - la, size = PGSIZE - off;
ffffffffc02054ba:	417a8a33          	sub	s4,s5,s7
ffffffffc02054be:	b799                	j	ffffffffc0205404 <do_execve+0x39e>
        return -E_INVAL;
ffffffffc02054c0:	5a75                	li	s4,-3
ffffffffc02054c2:	bb7d                	j	ffffffffc0205280 <do_execve+0x21a>
        while (start < end)
ffffffffc02054c4:	86de                	mv	a3,s7
ffffffffc02054c6:	bf39                	j	ffffffffc02053e4 <do_execve+0x37e>
    int ret = -E_NO_MEM;
ffffffffc02054c8:	5a71                	li	s4,-4
ffffffffc02054ca:	b5fd                	j	ffffffffc02053b8 <do_execve+0x352>
            ret = -E_INVAL_ELF;
ffffffffc02054cc:	5a61                	li	s4,-8
ffffffffc02054ce:	bdf9                	j	ffffffffc02053ac <do_execve+0x346>
ffffffffc02054d0:	00002617          	auipc	a2,0x2
ffffffffc02054d4:	e2060613          	addi	a2,a2,-480 # ffffffffc02072f0 <default_pmm_manager+0x38>
ffffffffc02054d8:	07100593          	li	a1,113
ffffffffc02054dc:	00002517          	auipc	a0,0x2
ffffffffc02054e0:	e3c50513          	addi	a0,a0,-452 # ffffffffc0207318 <default_pmm_manager+0x60>
ffffffffc02054e4:	faffa0ef          	jal	ra,ffffffffc0200492 <__panic>
    current->pgdir = PADDR(mm->pgdir);
ffffffffc02054e8:	00002617          	auipc	a2,0x2
ffffffffc02054ec:	eb060613          	addi	a2,a2,-336 # ffffffffc0207398 <default_pmm_manager+0xe0>
ffffffffc02054f0:	2d900593          	li	a1,729
ffffffffc02054f4:	00003517          	auipc	a0,0x3
ffffffffc02054f8:	cc450513          	addi	a0,a0,-828 # ffffffffc02081b8 <default_pmm_manager+0xf00>
ffffffffc02054fc:	f97fa0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 4 * PGSIZE, PTE_USER) != NULL);
ffffffffc0205500:	00003697          	auipc	a3,0x3
ffffffffc0205504:	f9868693          	addi	a3,a3,-104 # ffffffffc0208498 <default_pmm_manager+0x11e0>
ffffffffc0205508:	00002617          	auipc	a2,0x2
ffffffffc020550c:	a0060613          	addi	a2,a2,-1536 # ffffffffc0206f08 <commands+0x818>
ffffffffc0205510:	2d400593          	li	a1,724
ffffffffc0205514:	00003517          	auipc	a0,0x3
ffffffffc0205518:	ca450513          	addi	a0,a0,-860 # ffffffffc02081b8 <default_pmm_manager+0xf00>
ffffffffc020551c:	f77fa0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 3 * PGSIZE, PTE_USER) != NULL);
ffffffffc0205520:	00003697          	auipc	a3,0x3
ffffffffc0205524:	f3068693          	addi	a3,a3,-208 # ffffffffc0208450 <default_pmm_manager+0x1198>
ffffffffc0205528:	00002617          	auipc	a2,0x2
ffffffffc020552c:	9e060613          	addi	a2,a2,-1568 # ffffffffc0206f08 <commands+0x818>
ffffffffc0205530:	2d300593          	li	a1,723
ffffffffc0205534:	00003517          	auipc	a0,0x3
ffffffffc0205538:	c8450513          	addi	a0,a0,-892 # ffffffffc02081b8 <default_pmm_manager+0xf00>
ffffffffc020553c:	f57fa0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 2 * PGSIZE, PTE_USER) != NULL);
ffffffffc0205540:	00003697          	auipc	a3,0x3
ffffffffc0205544:	ec868693          	addi	a3,a3,-312 # ffffffffc0208408 <default_pmm_manager+0x1150>
ffffffffc0205548:	00002617          	auipc	a2,0x2
ffffffffc020554c:	9c060613          	addi	a2,a2,-1600 # ffffffffc0206f08 <commands+0x818>
ffffffffc0205550:	2d200593          	li	a1,722
ffffffffc0205554:	00003517          	auipc	a0,0x3
ffffffffc0205558:	c6450513          	addi	a0,a0,-924 # ffffffffc02081b8 <default_pmm_manager+0xf00>
ffffffffc020555c:	f37fa0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - PGSIZE, PTE_USER) != NULL);
ffffffffc0205560:	00003697          	auipc	a3,0x3
ffffffffc0205564:	e6068693          	addi	a3,a3,-416 # ffffffffc02083c0 <default_pmm_manager+0x1108>
ffffffffc0205568:	00002617          	auipc	a2,0x2
ffffffffc020556c:	9a060613          	addi	a2,a2,-1632 # ffffffffc0206f08 <commands+0x818>
ffffffffc0205570:	2d100593          	li	a1,721
ffffffffc0205574:	00003517          	auipc	a0,0x3
ffffffffc0205578:	c4450513          	addi	a0,a0,-956 # ffffffffc02081b8 <default_pmm_manager+0xf00>
ffffffffc020557c:	f17fa0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0205580 <user_main>:
{
ffffffffc0205580:	1101                	addi	sp,sp,-32
ffffffffc0205582:	e04a                	sd	s2,0(sp)
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc0205584:	000da917          	auipc	s2,0xda
ffffffffc0205588:	6ec90913          	addi	s2,s2,1772 # ffffffffc02dfc70 <current>
ffffffffc020558c:	00093783          	ld	a5,0(s2)
ffffffffc0205590:	00003617          	auipc	a2,0x3
ffffffffc0205594:	f5060613          	addi	a2,a2,-176 # ffffffffc02084e0 <default_pmm_manager+0x1228>
ffffffffc0205598:	00003517          	auipc	a0,0x3
ffffffffc020559c:	f5050513          	addi	a0,a0,-176 # ffffffffc02084e8 <default_pmm_manager+0x1230>
ffffffffc02055a0:	43cc                	lw	a1,4(a5)
{
ffffffffc02055a2:	ec06                	sd	ra,24(sp)
ffffffffc02055a4:	e822                	sd	s0,16(sp)
ffffffffc02055a6:	e426                	sd	s1,8(sp)
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc02055a8:	bf1fa0ef          	jal	ra,ffffffffc0200198 <cprintf>
    size_t len = strlen(name);
ffffffffc02055ac:	00003517          	auipc	a0,0x3
ffffffffc02055b0:	f3450513          	addi	a0,a0,-204 # ffffffffc02084e0 <default_pmm_manager+0x1228>
ffffffffc02055b4:	603000ef          	jal	ra,ffffffffc02063b6 <strlen>
    struct trapframe *old_tf = current->tf;
ffffffffc02055b8:	00093783          	ld	a5,0(s2)
    size_t len = strlen(name);
ffffffffc02055bc:	84aa                	mv	s1,a0
    memcpy(new_tf, old_tf, sizeof(struct trapframe));
ffffffffc02055be:	12000613          	li	a2,288
    struct trapframe *new_tf = (struct trapframe *)(current->kstack + KSTACKSIZE - sizeof(struct trapframe));
ffffffffc02055c2:	6b80                	ld	s0,16(a5)
    memcpy(new_tf, old_tf, sizeof(struct trapframe));
ffffffffc02055c4:	73cc                	ld	a1,160(a5)
    struct trapframe *new_tf = (struct trapframe *)(current->kstack + KSTACKSIZE - sizeof(struct trapframe));
ffffffffc02055c6:	6789                	lui	a5,0x2
ffffffffc02055c8:	ee078793          	addi	a5,a5,-288 # 1ee0 <_binary_obj___user_faultread_out_size-0x8248>
ffffffffc02055cc:	943e                	add	s0,s0,a5
    memcpy(new_tf, old_tf, sizeof(struct trapframe));
ffffffffc02055ce:	8522                	mv	a0,s0
ffffffffc02055d0:	69b000ef          	jal	ra,ffffffffc020646a <memcpy>
    current->tf = new_tf;
ffffffffc02055d4:	00093783          	ld	a5,0(s2)
    ret = do_execve(name, len, binary, size);
ffffffffc02055d8:	3fe07697          	auipc	a3,0x3fe07
ffffffffc02055dc:	32868693          	addi	a3,a3,808 # c900 <_binary_obj___user_matrix_out_size>
ffffffffc02055e0:	00068617          	auipc	a2,0x68
ffffffffc02055e4:	04860613          	addi	a2,a2,72 # ffffffffc026d628 <_binary_obj___user_matrix_out_start>
    current->tf = new_tf;
ffffffffc02055e8:	f3c0                	sd	s0,160(a5)
    ret = do_execve(name, len, binary, size);
ffffffffc02055ea:	85a6                	mv	a1,s1
ffffffffc02055ec:	00003517          	auipc	a0,0x3
ffffffffc02055f0:	ef450513          	addi	a0,a0,-268 # ffffffffc02084e0 <default_pmm_manager+0x1228>
ffffffffc02055f4:	a73ff0ef          	jal	ra,ffffffffc0205066 <do_execve>
    asm volatile(
ffffffffc02055f8:	8122                	mv	sp,s0
ffffffffc02055fa:	863fb06f          	j	ffffffffc0200e5c <__trapret>
    panic("user_main execve failed.\n");
ffffffffc02055fe:	00003617          	auipc	a2,0x3
ffffffffc0205602:	f1260613          	addi	a2,a2,-238 # ffffffffc0208510 <default_pmm_manager+0x1258>
ffffffffc0205606:	3c600593          	li	a1,966
ffffffffc020560a:	00003517          	auipc	a0,0x3
ffffffffc020560e:	bae50513          	addi	a0,a0,-1106 # ffffffffc02081b8 <default_pmm_manager+0xf00>
ffffffffc0205612:	e81fa0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0205616 <do_yield>:
    current->need_resched = 1;
ffffffffc0205616:	000da797          	auipc	a5,0xda
ffffffffc020561a:	65a7b783          	ld	a5,1626(a5) # ffffffffc02dfc70 <current>
ffffffffc020561e:	4705                	li	a4,1
ffffffffc0205620:	ef98                	sd	a4,24(a5)
}
ffffffffc0205622:	4501                	li	a0,0
ffffffffc0205624:	8082                	ret

ffffffffc0205626 <do_wait>:
{
ffffffffc0205626:	1101                	addi	sp,sp,-32
ffffffffc0205628:	e822                	sd	s0,16(sp)
ffffffffc020562a:	e426                	sd	s1,8(sp)
ffffffffc020562c:	ec06                	sd	ra,24(sp)
ffffffffc020562e:	842e                	mv	s0,a1
ffffffffc0205630:	84aa                	mv	s1,a0
    if (code_store != NULL)
ffffffffc0205632:	c999                	beqz	a1,ffffffffc0205648 <do_wait+0x22>
    struct mm_struct *mm = current->mm;
ffffffffc0205634:	000da797          	auipc	a5,0xda
ffffffffc0205638:	63c7b783          	ld	a5,1596(a5) # ffffffffc02dfc70 <current>
        if (!user_mem_check(mm, (uintptr_t)code_store, sizeof(int), 1))
ffffffffc020563c:	7788                	ld	a0,40(a5)
ffffffffc020563e:	4685                	li	a3,1
ffffffffc0205640:	4611                	li	a2,4
ffffffffc0205642:	e06fe0ef          	jal	ra,ffffffffc0203c48 <user_mem_check>
ffffffffc0205646:	c909                	beqz	a0,ffffffffc0205658 <do_wait+0x32>
ffffffffc0205648:	85a2                	mv	a1,s0
}
ffffffffc020564a:	6442                	ld	s0,16(sp)
ffffffffc020564c:	60e2                	ld	ra,24(sp)
ffffffffc020564e:	8526                	mv	a0,s1
ffffffffc0205650:	64a2                	ld	s1,8(sp)
ffffffffc0205652:	6105                	addi	sp,sp,32
ffffffffc0205654:	f18ff06f          	j	ffffffffc0204d6c <do_wait.part.0>
ffffffffc0205658:	60e2                	ld	ra,24(sp)
ffffffffc020565a:	6442                	ld	s0,16(sp)
ffffffffc020565c:	64a2                	ld	s1,8(sp)
ffffffffc020565e:	5575                	li	a0,-3
ffffffffc0205660:	6105                	addi	sp,sp,32
ffffffffc0205662:	8082                	ret

ffffffffc0205664 <do_kill>:
{
ffffffffc0205664:	1141                	addi	sp,sp,-16
    if (0 < pid && pid < MAX_PID)
ffffffffc0205666:	6789                	lui	a5,0x2
{
ffffffffc0205668:	e406                	sd	ra,8(sp)
ffffffffc020566a:	e022                	sd	s0,0(sp)
    if (0 < pid && pid < MAX_PID)
ffffffffc020566c:	fff5071b          	addiw	a4,a0,-1
ffffffffc0205670:	17f9                	addi	a5,a5,-2
ffffffffc0205672:	02e7e963          	bltu	a5,a4,ffffffffc02056a4 <do_kill+0x40>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0205676:	842a                	mv	s0,a0
ffffffffc0205678:	45a9                	li	a1,10
ffffffffc020567a:	2501                	sext.w	a0,a0
ffffffffc020567c:	137000ef          	jal	ra,ffffffffc0205fb2 <hash32>
ffffffffc0205680:	02051793          	slli	a5,a0,0x20
ffffffffc0205684:	01c7d513          	srli	a0,a5,0x1c
ffffffffc0205688:	000d6797          	auipc	a5,0xd6
ffffffffc020568c:	55078793          	addi	a5,a5,1360 # ffffffffc02dbbd8 <hash_list>
ffffffffc0205690:	953e                	add	a0,a0,a5
ffffffffc0205692:	87aa                	mv	a5,a0
        while ((le = list_next(le)) != list)
ffffffffc0205694:	a029                	j	ffffffffc020569e <do_kill+0x3a>
            if (proc->pid == pid)
ffffffffc0205696:	f2c7a703          	lw	a4,-212(a5)
ffffffffc020569a:	00870b63          	beq	a4,s0,ffffffffc02056b0 <do_kill+0x4c>
ffffffffc020569e:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc02056a0:	fef51be3          	bne	a0,a5,ffffffffc0205696 <do_kill+0x32>
    return -E_INVAL;
ffffffffc02056a4:	5475                	li	s0,-3
}
ffffffffc02056a6:	60a2                	ld	ra,8(sp)
ffffffffc02056a8:	8522                	mv	a0,s0
ffffffffc02056aa:	6402                	ld	s0,0(sp)
ffffffffc02056ac:	0141                	addi	sp,sp,16
ffffffffc02056ae:	8082                	ret
        if (!(proc->flags & PF_EXITING))
ffffffffc02056b0:	fd87a703          	lw	a4,-40(a5)
ffffffffc02056b4:	00177693          	andi	a3,a4,1
ffffffffc02056b8:	e295                	bnez	a3,ffffffffc02056dc <do_kill+0x78>
            if (proc->wait_state & WT_INTERRUPTED)
ffffffffc02056ba:	4bd4                	lw	a3,20(a5)
            proc->flags |= PF_EXITING;
ffffffffc02056bc:	00176713          	ori	a4,a4,1
ffffffffc02056c0:	fce7ac23          	sw	a4,-40(a5)
            return 0;
ffffffffc02056c4:	4401                	li	s0,0
            if (proc->wait_state & WT_INTERRUPTED)
ffffffffc02056c6:	fe06d0e3          	bgez	a3,ffffffffc02056a6 <do_kill+0x42>
                wakeup_proc(proc);
ffffffffc02056ca:	f2878513          	addi	a0,a5,-216
ffffffffc02056ce:	3e0000ef          	jal	ra,ffffffffc0205aae <wakeup_proc>
}
ffffffffc02056d2:	60a2                	ld	ra,8(sp)
ffffffffc02056d4:	8522                	mv	a0,s0
ffffffffc02056d6:	6402                	ld	s0,0(sp)
ffffffffc02056d8:	0141                	addi	sp,sp,16
ffffffffc02056da:	8082                	ret
        return -E_KILLED;
ffffffffc02056dc:	545d                	li	s0,-9
ffffffffc02056de:	b7e1                	j	ffffffffc02056a6 <do_kill+0x42>

ffffffffc02056e0 <proc_init>:

// proc_init - set up the first kernel thread idleproc "idle" by itself and
//           - create the second kernel thread init_main
void proc_init(void)
{
ffffffffc02056e0:	1101                	addi	sp,sp,-32
ffffffffc02056e2:	e426                	sd	s1,8(sp)
    elm->prev = elm->next = elm;
ffffffffc02056e4:	000da797          	auipc	a5,0xda
ffffffffc02056e8:	4f478793          	addi	a5,a5,1268 # ffffffffc02dfbd8 <proc_list>
ffffffffc02056ec:	ec06                	sd	ra,24(sp)
ffffffffc02056ee:	e822                	sd	s0,16(sp)
ffffffffc02056f0:	e04a                	sd	s2,0(sp)
ffffffffc02056f2:	000d6497          	auipc	s1,0xd6
ffffffffc02056f6:	4e648493          	addi	s1,s1,1254 # ffffffffc02dbbd8 <hash_list>
ffffffffc02056fa:	e79c                	sd	a5,8(a5)
ffffffffc02056fc:	e39c                	sd	a5,0(a5)
    int i;

    list_init(&proc_list);
    for (i = 0; i < HASH_LIST_SIZE; i++)
ffffffffc02056fe:	000da717          	auipc	a4,0xda
ffffffffc0205702:	4da70713          	addi	a4,a4,1242 # ffffffffc02dfbd8 <proc_list>
ffffffffc0205706:	87a6                	mv	a5,s1
ffffffffc0205708:	e79c                	sd	a5,8(a5)
ffffffffc020570a:	e39c                	sd	a5,0(a5)
ffffffffc020570c:	07c1                	addi	a5,a5,16
ffffffffc020570e:	fef71de3          	bne	a4,a5,ffffffffc0205708 <proc_init+0x28>
    {
        list_init(hash_list + i);
    }

    if ((idleproc = alloc_proc()) == NULL)
ffffffffc0205712:	edffe0ef          	jal	ra,ffffffffc02045f0 <alloc_proc>
ffffffffc0205716:	000da917          	auipc	s2,0xda
ffffffffc020571a:	56290913          	addi	s2,s2,1378 # ffffffffc02dfc78 <idleproc>
ffffffffc020571e:	00a93023          	sd	a0,0(s2)
ffffffffc0205722:	0e050f63          	beqz	a0,ffffffffc0205820 <proc_init+0x140>
    {
        panic("cannot alloc idleproc.\n");
    }

    idleproc->pid = 0;
    idleproc->state = PROC_RUNNABLE;
ffffffffc0205726:	4789                	li	a5,2
ffffffffc0205728:	e11c                	sd	a5,0(a0)
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc020572a:	00005797          	auipc	a5,0x5
ffffffffc020572e:	8d678793          	addi	a5,a5,-1834 # ffffffffc020a000 <bootstack>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0205732:	0b450413          	addi	s0,a0,180
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc0205736:	e91c                	sd	a5,16(a0)
    idleproc->need_resched = 1;
ffffffffc0205738:	4785                	li	a5,1
ffffffffc020573a:	ed1c                	sd	a5,24(a0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc020573c:	4641                	li	a2,16
ffffffffc020573e:	4581                	li	a1,0
ffffffffc0205740:	8522                	mv	a0,s0
ffffffffc0205742:	517000ef          	jal	ra,ffffffffc0206458 <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0205746:	463d                	li	a2,15
ffffffffc0205748:	00003597          	auipc	a1,0x3
ffffffffc020574c:	e0058593          	addi	a1,a1,-512 # ffffffffc0208548 <default_pmm_manager+0x1290>
ffffffffc0205750:	8522                	mv	a0,s0
ffffffffc0205752:	519000ef          	jal	ra,ffffffffc020646a <memcpy>
    set_proc_name(idleproc, "idle");
    nr_process++;
ffffffffc0205756:	000da717          	auipc	a4,0xda
ffffffffc020575a:	53270713          	addi	a4,a4,1330 # ffffffffc02dfc88 <nr_process>
ffffffffc020575e:	431c                	lw	a5,0(a4)

    current = idleproc;
ffffffffc0205760:	00093683          	ld	a3,0(s2)

    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0205764:	4601                	li	a2,0
    nr_process++;
ffffffffc0205766:	2785                	addiw	a5,a5,1
    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0205768:	4581                	li	a1,0
ffffffffc020576a:	fffff517          	auipc	a0,0xfffff
ffffffffc020576e:	7d450513          	addi	a0,a0,2004 # ffffffffc0204f3e <init_main>
    nr_process++;
ffffffffc0205772:	c31c                	sw	a5,0(a4)
    current = idleproc;
ffffffffc0205774:	000da797          	auipc	a5,0xda
ffffffffc0205778:	4ed7be23          	sd	a3,1276(a5) # ffffffffc02dfc70 <current>
    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc020577c:	c54ff0ef          	jal	ra,ffffffffc0204bd0 <kernel_thread>
ffffffffc0205780:	842a                	mv	s0,a0
    if (pid <= 0)
ffffffffc0205782:	08a05363          	blez	a0,ffffffffc0205808 <proc_init+0x128>
    if (0 < pid && pid < MAX_PID)
ffffffffc0205786:	6789                	lui	a5,0x2
ffffffffc0205788:	fff5071b          	addiw	a4,a0,-1
ffffffffc020578c:	17f9                	addi	a5,a5,-2
ffffffffc020578e:	2501                	sext.w	a0,a0
ffffffffc0205790:	02e7e363          	bltu	a5,a4,ffffffffc02057b6 <proc_init+0xd6>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0205794:	45a9                	li	a1,10
ffffffffc0205796:	01d000ef          	jal	ra,ffffffffc0205fb2 <hash32>
ffffffffc020579a:	02051793          	slli	a5,a0,0x20
ffffffffc020579e:	01c7d693          	srli	a3,a5,0x1c
ffffffffc02057a2:	96a6                	add	a3,a3,s1
ffffffffc02057a4:	87b6                	mv	a5,a3
        while ((le = list_next(le)) != list)
ffffffffc02057a6:	a029                	j	ffffffffc02057b0 <proc_init+0xd0>
            if (proc->pid == pid)
ffffffffc02057a8:	f2c7a703          	lw	a4,-212(a5) # 1f2c <_binary_obj___user_faultread_out_size-0x81fc>
ffffffffc02057ac:	04870b63          	beq	a4,s0,ffffffffc0205802 <proc_init+0x122>
    return listelm->next;
ffffffffc02057b0:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc02057b2:	fef69be3          	bne	a3,a5,ffffffffc02057a8 <proc_init+0xc8>
    return NULL;
ffffffffc02057b6:	4781                	li	a5,0
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc02057b8:	0b478493          	addi	s1,a5,180
ffffffffc02057bc:	4641                	li	a2,16
ffffffffc02057be:	4581                	li	a1,0
    {
        panic("create init_main failed.\n");
    }

    initproc = find_proc(pid);
ffffffffc02057c0:	000da417          	auipc	s0,0xda
ffffffffc02057c4:	4c040413          	addi	s0,s0,1216 # ffffffffc02dfc80 <initproc>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc02057c8:	8526                	mv	a0,s1
    initproc = find_proc(pid);
ffffffffc02057ca:	e01c                	sd	a5,0(s0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc02057cc:	48d000ef          	jal	ra,ffffffffc0206458 <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc02057d0:	463d                	li	a2,15
ffffffffc02057d2:	00003597          	auipc	a1,0x3
ffffffffc02057d6:	d9e58593          	addi	a1,a1,-610 # ffffffffc0208570 <default_pmm_manager+0x12b8>
ffffffffc02057da:	8526                	mv	a0,s1
ffffffffc02057dc:	48f000ef          	jal	ra,ffffffffc020646a <memcpy>
    set_proc_name(initproc, "init");

    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc02057e0:	00093783          	ld	a5,0(s2)
ffffffffc02057e4:	cbb5                	beqz	a5,ffffffffc0205858 <proc_init+0x178>
ffffffffc02057e6:	43dc                	lw	a5,4(a5)
ffffffffc02057e8:	eba5                	bnez	a5,ffffffffc0205858 <proc_init+0x178>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc02057ea:	601c                	ld	a5,0(s0)
ffffffffc02057ec:	c7b1                	beqz	a5,ffffffffc0205838 <proc_init+0x158>
ffffffffc02057ee:	43d8                	lw	a4,4(a5)
ffffffffc02057f0:	4785                	li	a5,1
ffffffffc02057f2:	04f71363          	bne	a4,a5,ffffffffc0205838 <proc_init+0x158>
}
ffffffffc02057f6:	60e2                	ld	ra,24(sp)
ffffffffc02057f8:	6442                	ld	s0,16(sp)
ffffffffc02057fa:	64a2                	ld	s1,8(sp)
ffffffffc02057fc:	6902                	ld	s2,0(sp)
ffffffffc02057fe:	6105                	addi	sp,sp,32
ffffffffc0205800:	8082                	ret
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc0205802:	f2878793          	addi	a5,a5,-216
ffffffffc0205806:	bf4d                	j	ffffffffc02057b8 <proc_init+0xd8>
        panic("create init_main failed.\n");
ffffffffc0205808:	00003617          	auipc	a2,0x3
ffffffffc020580c:	d4860613          	addi	a2,a2,-696 # ffffffffc0208550 <default_pmm_manager+0x1298>
ffffffffc0205810:	40400593          	li	a1,1028
ffffffffc0205814:	00003517          	auipc	a0,0x3
ffffffffc0205818:	9a450513          	addi	a0,a0,-1628 # ffffffffc02081b8 <default_pmm_manager+0xf00>
ffffffffc020581c:	c77fa0ef          	jal	ra,ffffffffc0200492 <__panic>
        panic("cannot alloc idleproc.\n");
ffffffffc0205820:	00003617          	auipc	a2,0x3
ffffffffc0205824:	d1060613          	addi	a2,a2,-752 # ffffffffc0208530 <default_pmm_manager+0x1278>
ffffffffc0205828:	3f500593          	li	a1,1013
ffffffffc020582c:	00003517          	auipc	a0,0x3
ffffffffc0205830:	98c50513          	addi	a0,a0,-1652 # ffffffffc02081b8 <default_pmm_manager+0xf00>
ffffffffc0205834:	c5ffa0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc0205838:	00003697          	auipc	a3,0x3
ffffffffc020583c:	d6868693          	addi	a3,a3,-664 # ffffffffc02085a0 <default_pmm_manager+0x12e8>
ffffffffc0205840:	00001617          	auipc	a2,0x1
ffffffffc0205844:	6c860613          	addi	a2,a2,1736 # ffffffffc0206f08 <commands+0x818>
ffffffffc0205848:	40b00593          	li	a1,1035
ffffffffc020584c:	00003517          	auipc	a0,0x3
ffffffffc0205850:	96c50513          	addi	a0,a0,-1684 # ffffffffc02081b8 <default_pmm_manager+0xf00>
ffffffffc0205854:	c3ffa0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc0205858:	00003697          	auipc	a3,0x3
ffffffffc020585c:	d2068693          	addi	a3,a3,-736 # ffffffffc0208578 <default_pmm_manager+0x12c0>
ffffffffc0205860:	00001617          	auipc	a2,0x1
ffffffffc0205864:	6a860613          	addi	a2,a2,1704 # ffffffffc0206f08 <commands+0x818>
ffffffffc0205868:	40a00593          	li	a1,1034
ffffffffc020586c:	00003517          	auipc	a0,0x3
ffffffffc0205870:	94c50513          	addi	a0,a0,-1716 # ffffffffc02081b8 <default_pmm_manager+0xf00>
ffffffffc0205874:	c1ffa0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0205878 <cpu_idle>:

// cpu_idle - at the end of kern_init, the first kernel thread idleproc will do below works
void cpu_idle(void)
{
ffffffffc0205878:	1141                	addi	sp,sp,-16
ffffffffc020587a:	e022                	sd	s0,0(sp)
ffffffffc020587c:	e406                	sd	ra,8(sp)
ffffffffc020587e:	000da417          	auipc	s0,0xda
ffffffffc0205882:	3f240413          	addi	s0,s0,1010 # ffffffffc02dfc70 <current>
    while (1)
    {
        if (current->need_resched)
ffffffffc0205886:	6018                	ld	a4,0(s0)
ffffffffc0205888:	6f1c                	ld	a5,24(a4)
ffffffffc020588a:	dffd                	beqz	a5,ffffffffc0205888 <cpu_idle+0x10>
        {
            schedule();
ffffffffc020588c:	2d4000ef          	jal	ra,ffffffffc0205b60 <schedule>
ffffffffc0205890:	bfdd                	j	ffffffffc0205886 <cpu_idle+0xe>

ffffffffc0205892 <lab6_set_priority>:
        }
    }
}
// FOR LAB6, set the process's priority (bigger value will get more CPU time)
void lab6_set_priority(uint32_t priority)
{
ffffffffc0205892:	1141                	addi	sp,sp,-16
ffffffffc0205894:	e022                	sd	s0,0(sp)
    cprintf("set priority to %d\n", priority);
ffffffffc0205896:	85aa                	mv	a1,a0
{
ffffffffc0205898:	842a                	mv	s0,a0
    cprintf("set priority to %d\n", priority);
ffffffffc020589a:	00003517          	auipc	a0,0x3
ffffffffc020589e:	d2e50513          	addi	a0,a0,-722 # ffffffffc02085c8 <default_pmm_manager+0x1310>
{
ffffffffc02058a2:	e406                	sd	ra,8(sp)
    cprintf("set priority to %d\n", priority);
ffffffffc02058a4:	8f5fa0ef          	jal	ra,ffffffffc0200198 <cprintf>
    if (priority == 0)
        current->lab6_priority = 1;
ffffffffc02058a8:	000da797          	auipc	a5,0xda
ffffffffc02058ac:	3c87b783          	ld	a5,968(a5) # ffffffffc02dfc70 <current>
    if (priority == 0)
ffffffffc02058b0:	e801                	bnez	s0,ffffffffc02058c0 <lab6_set_priority+0x2e>
    else
        current->lab6_priority = priority;
}
ffffffffc02058b2:	60a2                	ld	ra,8(sp)
ffffffffc02058b4:	6402                	ld	s0,0(sp)
        current->lab6_priority = 1;
ffffffffc02058b6:	4705                	li	a4,1
ffffffffc02058b8:	14e7a223          	sw	a4,324(a5)
}
ffffffffc02058bc:	0141                	addi	sp,sp,16
ffffffffc02058be:	8082                	ret
ffffffffc02058c0:	60a2                	ld	ra,8(sp)
        current->lab6_priority = priority;
ffffffffc02058c2:	1487a223          	sw	s0,324(a5)
}
ffffffffc02058c6:	6402                	ld	s0,0(sp)
ffffffffc02058c8:	0141                	addi	sp,sp,16
ffffffffc02058ca:	8082                	ret

ffffffffc02058cc <do_sleep>:
// do_sleep - set current process state to sleep and add timer with "time"
//          - then call scheduler. if process run again, delete timer first.
int do_sleep(unsigned int time)
{
    if (time == 0)
ffffffffc02058cc:	c539                	beqz	a0,ffffffffc020591a <do_sleep+0x4e>
{
ffffffffc02058ce:	7179                	addi	sp,sp,-48
ffffffffc02058d0:	f022                	sd	s0,32(sp)
ffffffffc02058d2:	f406                	sd	ra,40(sp)
ffffffffc02058d4:	842a                	mv	s0,a0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02058d6:	100027f3          	csrr	a5,sstatus
ffffffffc02058da:	8b89                	andi	a5,a5,2
ffffffffc02058dc:	e3a9                	bnez	a5,ffffffffc020591e <do_sleep+0x52>
    {
        return 0;
    }
    bool intr_flag;
    local_intr_save(intr_flag);
    timer_t __timer, *timer = timer_init(&__timer, current, time);
ffffffffc02058de:	000da797          	auipc	a5,0xda
ffffffffc02058e2:	3927b783          	ld	a5,914(a5) # ffffffffc02dfc70 <current>
    elm->prev = elm->next = elm;
ffffffffc02058e6:	0818                	addi	a4,sp,16
to_struct((le), timer_t, member)

// init a timer
static inline timer_t *
timer_init(timer_t *timer, struct proc_struct *proc, int expires) {
    timer->expires = expires;
ffffffffc02058e8:	c02a                	sw	a0,0(sp)
ffffffffc02058ea:	ec3a                	sd	a4,24(sp)
ffffffffc02058ec:	e83a                	sd	a4,16(sp)
    timer->proc = proc;
ffffffffc02058ee:	e43e                	sd	a5,8(sp)
    current->state = PROC_SLEEPING;
ffffffffc02058f0:	4705                	li	a4,1
ffffffffc02058f2:	c398                	sw	a4,0(a5)
    current->wait_state = WT_TIMER;
ffffffffc02058f4:	80000737          	lui	a4,0x80000
ffffffffc02058f8:	840a                	mv	s0,sp
ffffffffc02058fa:	0709                	addi	a4,a4,2
ffffffffc02058fc:	0ee7a623          	sw	a4,236(a5)
    add_timer(timer);
ffffffffc0205900:	8522                	mv	a0,s0
ffffffffc0205902:	31e000ef          	jal	ra,ffffffffc0205c20 <add_timer>
    local_intr_restore(intr_flag);

    schedule();
ffffffffc0205906:	25a000ef          	jal	ra,ffffffffc0205b60 <schedule>

    del_timer(timer);
ffffffffc020590a:	8522                	mv	a0,s0
ffffffffc020590c:	3dc000ef          	jal	ra,ffffffffc0205ce8 <del_timer>
    return 0;
}
ffffffffc0205910:	70a2                	ld	ra,40(sp)
ffffffffc0205912:	7402                	ld	s0,32(sp)
ffffffffc0205914:	4501                	li	a0,0
ffffffffc0205916:	6145                	addi	sp,sp,48
ffffffffc0205918:	8082                	ret
ffffffffc020591a:	4501                	li	a0,0
ffffffffc020591c:	8082                	ret
        intr_disable();
ffffffffc020591e:	890fb0ef          	jal	ra,ffffffffc02009ae <intr_disable>
    timer_t __timer, *timer = timer_init(&__timer, current, time);
ffffffffc0205922:	000da797          	auipc	a5,0xda
ffffffffc0205926:	34e7b783          	ld	a5,846(a5) # ffffffffc02dfc70 <current>
ffffffffc020592a:	0818                	addi	a4,sp,16
    timer->expires = expires;
ffffffffc020592c:	c022                	sw	s0,0(sp)
    timer->proc = proc;
ffffffffc020592e:	e43e                	sd	a5,8(sp)
ffffffffc0205930:	ec3a                	sd	a4,24(sp)
ffffffffc0205932:	e83a                	sd	a4,16(sp)
    current->state = PROC_SLEEPING;
ffffffffc0205934:	4705                	li	a4,1
ffffffffc0205936:	c398                	sw	a4,0(a5)
    current->wait_state = WT_TIMER;
ffffffffc0205938:	80000737          	lui	a4,0x80000
ffffffffc020593c:	0709                	addi	a4,a4,2
ffffffffc020593e:	840a                	mv	s0,sp
    add_timer(timer);
ffffffffc0205940:	8522                	mv	a0,s0
    current->wait_state = WT_TIMER;
ffffffffc0205942:	0ee7a623          	sw	a4,236(a5)
    add_timer(timer);
ffffffffc0205946:	2da000ef          	jal	ra,ffffffffc0205c20 <add_timer>
        intr_enable();
ffffffffc020594a:	85efb0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc020594e:	bf65                	j	ffffffffc0205906 <do_sleep+0x3a>

ffffffffc0205950 <switch_to>:
.text
# void switch_to(struct proc_struct* from, struct proc_struct* to)
.globl switch_to
switch_to:
    # save from's registers
    STORE ra, 0*REGBYTES(a0)
ffffffffc0205950:	00153023          	sd	ra,0(a0)
    STORE sp, 1*REGBYTES(a0)
ffffffffc0205954:	00253423          	sd	sp,8(a0)
    STORE s0, 2*REGBYTES(a0)
ffffffffc0205958:	e900                	sd	s0,16(a0)
    STORE s1, 3*REGBYTES(a0)
ffffffffc020595a:	ed04                	sd	s1,24(a0)
    STORE s2, 4*REGBYTES(a0)
ffffffffc020595c:	03253023          	sd	s2,32(a0)
    STORE s3, 5*REGBYTES(a0)
ffffffffc0205960:	03353423          	sd	s3,40(a0)
    STORE s4, 6*REGBYTES(a0)
ffffffffc0205964:	03453823          	sd	s4,48(a0)
    STORE s5, 7*REGBYTES(a0)
ffffffffc0205968:	03553c23          	sd	s5,56(a0)
    STORE s6, 8*REGBYTES(a0)
ffffffffc020596c:	05653023          	sd	s6,64(a0)
    STORE s7, 9*REGBYTES(a0)
ffffffffc0205970:	05753423          	sd	s7,72(a0)
    STORE s8, 10*REGBYTES(a0)
ffffffffc0205974:	05853823          	sd	s8,80(a0)
    STORE s9, 11*REGBYTES(a0)
ffffffffc0205978:	05953c23          	sd	s9,88(a0)
    STORE s10, 12*REGBYTES(a0)
ffffffffc020597c:	07a53023          	sd	s10,96(a0)
    STORE s11, 13*REGBYTES(a0)
ffffffffc0205980:	07b53423          	sd	s11,104(a0)

    # restore to's registers
    LOAD ra, 0*REGBYTES(a1)
ffffffffc0205984:	0005b083          	ld	ra,0(a1)
    LOAD sp, 1*REGBYTES(a1)
ffffffffc0205988:	0085b103          	ld	sp,8(a1)
    LOAD s0, 2*REGBYTES(a1)
ffffffffc020598c:	6980                	ld	s0,16(a1)
    LOAD s1, 3*REGBYTES(a1)
ffffffffc020598e:	6d84                	ld	s1,24(a1)
    LOAD s2, 4*REGBYTES(a1)
ffffffffc0205990:	0205b903          	ld	s2,32(a1)
    LOAD s3, 5*REGBYTES(a1)
ffffffffc0205994:	0285b983          	ld	s3,40(a1)
    LOAD s4, 6*REGBYTES(a1)
ffffffffc0205998:	0305ba03          	ld	s4,48(a1)
    LOAD s5, 7*REGBYTES(a1)
ffffffffc020599c:	0385ba83          	ld	s5,56(a1)
    LOAD s6, 8*REGBYTES(a1)
ffffffffc02059a0:	0405bb03          	ld	s6,64(a1)
    LOAD s7, 9*REGBYTES(a1)
ffffffffc02059a4:	0485bb83          	ld	s7,72(a1)
    LOAD s8, 10*REGBYTES(a1)
ffffffffc02059a8:	0505bc03          	ld	s8,80(a1)
    LOAD s9, 11*REGBYTES(a1)
ffffffffc02059ac:	0585bc83          	ld	s9,88(a1)
    LOAD s10, 12*REGBYTES(a1)
ffffffffc02059b0:	0605bd03          	ld	s10,96(a1)
    LOAD s11, 13*REGBYTES(a1)
ffffffffc02059b4:	0685bd83          	ld	s11,104(a1)

    ret
ffffffffc02059b8:	8082                	ret

ffffffffc02059ba <RR_init>:
ffffffffc02059ba:	e508                	sd	a0,8(a0)
ffffffffc02059bc:	e108                	sd	a0,0(a0)
static void
RR_init(struct run_queue *rq)
{
    // LAB6: 填写你在lab6中实现的代码
    list_init(&(rq->run_list));        // 初始化运行队列链表
    rq->proc_num = 0;                  // 进程数量初始为0
ffffffffc02059be:	00052823          	sw	zero,16(a0)
}
ffffffffc02059c2:	8082                	ret

ffffffffc02059c4 <RR_enqueue>:
static void
RR_enqueue(struct run_queue *rq, struct proc_struct *proc)
{
    // LAB6: 填写你在lab6中实现的代码
    // 检查进程是否已经在队列中
    if (list_empty(&(proc->run_link))) {
ffffffffc02059c4:	1185b703          	ld	a4,280(a1)
ffffffffc02059c8:	11058793          	addi	a5,a1,272
ffffffffc02059cc:	00e78363          	beq	a5,a4,ffffffffc02059d2 <RR_enqueue+0xe>
        proc->rq = rq;
        
        // 增加运行队列中的进程计数
        rq->proc_num++;
    }
}
ffffffffc02059d0:	8082                	ret
    __list_add(elm, listelm->prev, listelm);
ffffffffc02059d2:	6118                	ld	a4,0(a0)
        if (proc->time_slice == 0 || proc->time_slice > rq->max_time_slice) {
ffffffffc02059d4:	1205a683          	lw	a3,288(a1)
    prev->next = next->prev = elm;
ffffffffc02059d8:	e11c                	sd	a5,0(a0)
ffffffffc02059da:	e71c                	sd	a5,8(a4)
    elm->next = next;
ffffffffc02059dc:	10a5bc23          	sd	a0,280(a1)
    elm->prev = prev;
ffffffffc02059e0:	10e5b823          	sd	a4,272(a1)
ffffffffc02059e4:	495c                	lw	a5,20(a0)
ffffffffc02059e6:	ea89                	bnez	a3,ffffffffc02059f8 <RR_enqueue+0x34>
            proc->time_slice = rq->max_time_slice;
ffffffffc02059e8:	12f5a023          	sw	a5,288(a1)
        rq->proc_num++;
ffffffffc02059ec:	491c                	lw	a5,16(a0)
        proc->rq = rq;
ffffffffc02059ee:	10a5b423          	sd	a0,264(a1)
        rq->proc_num++;
ffffffffc02059f2:	2785                	addiw	a5,a5,1
ffffffffc02059f4:	c91c                	sw	a5,16(a0)
}
ffffffffc02059f6:	8082                	ret
        if (proc->time_slice == 0 || proc->time_slice > rq->max_time_slice) {
ffffffffc02059f8:	fed7dae3          	bge	a5,a3,ffffffffc02059ec <RR_enqueue+0x28>
ffffffffc02059fc:	b7f5                	j	ffffffffc02059e8 <RR_enqueue+0x24>

ffffffffc02059fe <RR_dequeue>:
    return list->next == list;
ffffffffc02059fe:	1185b703          	ld	a4,280(a1)
static void
RR_dequeue(struct run_queue *rq, struct proc_struct *proc)
{
    // LAB6: 填写你在lab6中实现的代码
    // 从运行队列中移除进程
    if (!list_empty(&(proc->run_link))) {
ffffffffc0205a02:	11058793          	addi	a5,a1,272
ffffffffc0205a06:	02e78063          	beq	a5,a4,ffffffffc0205a26 <RR_dequeue+0x28>
    __list_del(listelm->prev, listelm->next);
ffffffffc0205a0a:	1105b603          	ld	a2,272(a1)
        list_del_init(&(proc->run_link));
        
        // 减少运行队列中的进程计数
        rq->proc_num--;
ffffffffc0205a0e:	4914                	lw	a3,16(a0)
    prev->next = next;
ffffffffc0205a10:	e618                	sd	a4,8(a2)
    next->prev = prev;
ffffffffc0205a12:	e310                	sd	a2,0(a4)
    elm->prev = elm->next = elm;
ffffffffc0205a14:	10f5bc23          	sd	a5,280(a1)
ffffffffc0205a18:	10f5b823          	sd	a5,272(a1)
ffffffffc0205a1c:	fff6879b          	addiw	a5,a3,-1
ffffffffc0205a20:	c91c                	sw	a5,16(a0)
        
        // 清除进程的运行队列指针
        proc->rq = NULL;
ffffffffc0205a22:	1005b423          	sd	zero,264(a1)
    }
}
ffffffffc0205a26:	8082                	ret

ffffffffc0205a28 <RR_pick_next>:
    return listelm->next;
ffffffffc0205a28:	651c                	ld	a5,8(a0)
{
    // LAB6: 填写你在lab6中实现的代码
    list_entry_t *le = list_next(&(rq->run_list));
    
    // 如果运行队列为空，返回NULL
    if (le == &(rq->run_list)) {
ffffffffc0205a2a:	00f50c63          	beq	a0,a5,ffffffffc0205a42 <RR_pick_next+0x1a>
    
    // 返回运行队列中的第一个进程（FIFO）
    struct proc_struct *proc = le2proc(le, run_link);
    
    // 确保进程状态是可运行的
    if (proc->state == PROC_RUNNABLE) {
ffffffffc0205a2e:	ef07a683          	lw	a3,-272(a5)
ffffffffc0205a32:	4709                	li	a4,2
        return NULL;
ffffffffc0205a34:	4501                	li	a0,0
    if (proc->state == PROC_RUNNABLE) {
ffffffffc0205a36:	00e68363          	beq	a3,a4,ffffffffc0205a3c <RR_pick_next+0x14>
        return proc;
    }
    
    return NULL;
}
ffffffffc0205a3a:	8082                	ret
    struct proc_struct *proc = le2proc(le, run_link);
ffffffffc0205a3c:	ef078513          	addi	a0,a5,-272
        return proc;
ffffffffc0205a40:	8082                	ret
        return NULL;
ffffffffc0205a42:	4501                	li	a0,0
}
ffffffffc0205a44:	8082                	ret

ffffffffc0205a46 <RR_proc_tick>:
 */
static void
RR_proc_tick(struct run_queue *rq, struct proc_struct *proc)
{
    // LAB6: 填写你在lab6中实现的代码
    if (proc->time_slice > 0) {
ffffffffc0205a46:	1205a783          	lw	a5,288(a1)
ffffffffc0205a4a:	00f05563          	blez	a5,ffffffffc0205a54 <RR_proc_tick+0xe>
        proc->time_slice--;
ffffffffc0205a4e:	37fd                	addiw	a5,a5,-1
ffffffffc0205a50:	12f5a023          	sw	a5,288(a1)
    }
    
    // 当时间片用完时，设置需要重新调度的标志
    if (proc->time_slice == 0) {
ffffffffc0205a54:	e399                	bnez	a5,ffffffffc0205a5a <RR_proc_tick+0x14>
        proc->need_resched = 1;
ffffffffc0205a56:	4785                	li	a5,1
ffffffffc0205a58:	ed9c                	sd	a5,24(a1)
    }
}
ffffffffc0205a5a:	8082                	ret

ffffffffc0205a5c <sched_init>:
}

static struct run_queue __rq;

void
sched_init(void) {
ffffffffc0205a5c:	1141                	addi	sp,sp,-16
    list_init(&timer_list);

    sched_class = &default_sched_class;
ffffffffc0205a5e:	000d6717          	auipc	a4,0xd6
ffffffffc0205a62:	bca70713          	addi	a4,a4,-1078 # ffffffffc02db628 <default_sched_class>
sched_init(void) {
ffffffffc0205a66:	e022                	sd	s0,0(sp)
ffffffffc0205a68:	e406                	sd	ra,8(sp)
    elm->prev = elm->next = elm;
ffffffffc0205a6a:	000da797          	auipc	a5,0xda
ffffffffc0205a6e:	19e78793          	addi	a5,a5,414 # ffffffffc02dfc08 <timer_list>

    rq = &__rq;
    rq->max_time_slice = MAX_TIME_SLICE;
    sched_class->init(rq);
ffffffffc0205a72:	6714                	ld	a3,8(a4)
    rq = &__rq;
ffffffffc0205a74:	000da517          	auipc	a0,0xda
ffffffffc0205a78:	17450513          	addi	a0,a0,372 # ffffffffc02dfbe8 <__rq>
ffffffffc0205a7c:	e79c                	sd	a5,8(a5)
ffffffffc0205a7e:	e39c                	sd	a5,0(a5)
    rq->max_time_slice = MAX_TIME_SLICE;
ffffffffc0205a80:	4795                	li	a5,5
ffffffffc0205a82:	c95c                	sw	a5,20(a0)
    sched_class = &default_sched_class;
ffffffffc0205a84:	000da417          	auipc	s0,0xda
ffffffffc0205a88:	21440413          	addi	s0,s0,532 # ffffffffc02dfc98 <sched_class>
    rq = &__rq;
ffffffffc0205a8c:	000da797          	auipc	a5,0xda
ffffffffc0205a90:	20a7b223          	sd	a0,516(a5) # ffffffffc02dfc90 <rq>
    sched_class = &default_sched_class;
ffffffffc0205a94:	e018                	sd	a4,0(s0)
    sched_class->init(rq);
ffffffffc0205a96:	9682                	jalr	a3

    cprintf("sched class: %s\n", sched_class->name);
ffffffffc0205a98:	601c                	ld	a5,0(s0)
}
ffffffffc0205a9a:	6402                	ld	s0,0(sp)
ffffffffc0205a9c:	60a2                	ld	ra,8(sp)
    cprintf("sched class: %s\n", sched_class->name);
ffffffffc0205a9e:	638c                	ld	a1,0(a5)
ffffffffc0205aa0:	00003517          	auipc	a0,0x3
ffffffffc0205aa4:	b5050513          	addi	a0,a0,-1200 # ffffffffc02085f0 <default_pmm_manager+0x1338>
}
ffffffffc0205aa8:	0141                	addi	sp,sp,16
    cprintf("sched class: %s\n", sched_class->name);
ffffffffc0205aaa:	eeefa06f          	j	ffffffffc0200198 <cprintf>

ffffffffc0205aae <wakeup_proc>:

void
wakeup_proc(struct proc_struct *proc) {
    assert(proc->state != PROC_ZOMBIE);
ffffffffc0205aae:	4118                	lw	a4,0(a0)
wakeup_proc(struct proc_struct *proc) {
ffffffffc0205ab0:	1101                	addi	sp,sp,-32
ffffffffc0205ab2:	ec06                	sd	ra,24(sp)
ffffffffc0205ab4:	e822                	sd	s0,16(sp)
ffffffffc0205ab6:	e426                	sd	s1,8(sp)
    assert(proc->state != PROC_ZOMBIE);
ffffffffc0205ab8:	478d                	li	a5,3
ffffffffc0205aba:	08f70363          	beq	a4,a5,ffffffffc0205b40 <wakeup_proc+0x92>
ffffffffc0205abe:	842a                	mv	s0,a0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0205ac0:	100027f3          	csrr	a5,sstatus
ffffffffc0205ac4:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0205ac6:	4481                	li	s1,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0205ac8:	e7bd                	bnez	a5,ffffffffc0205b36 <wakeup_proc+0x88>
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        if (proc->state != PROC_RUNNABLE) {
ffffffffc0205aca:	4789                	li	a5,2
ffffffffc0205acc:	04f70863          	beq	a4,a5,ffffffffc0205b1c <wakeup_proc+0x6e>
            proc->state = PROC_RUNNABLE;
ffffffffc0205ad0:	c01c                	sw	a5,0(s0)
            proc->wait_state = 0;
ffffffffc0205ad2:	0e042623          	sw	zero,236(s0)
            if (proc != current) {
ffffffffc0205ad6:	000da797          	auipc	a5,0xda
ffffffffc0205ada:	19a7b783          	ld	a5,410(a5) # ffffffffc02dfc70 <current>
ffffffffc0205ade:	02878363          	beq	a5,s0,ffffffffc0205b04 <wakeup_proc+0x56>
    if (proc != idleproc) {
ffffffffc0205ae2:	000da797          	auipc	a5,0xda
ffffffffc0205ae6:	1967b783          	ld	a5,406(a5) # ffffffffc02dfc78 <idleproc>
ffffffffc0205aea:	00f40d63          	beq	s0,a5,ffffffffc0205b04 <wakeup_proc+0x56>
        sched_class->enqueue(rq, proc);
ffffffffc0205aee:	000da797          	auipc	a5,0xda
ffffffffc0205af2:	1aa7b783          	ld	a5,426(a5) # ffffffffc02dfc98 <sched_class>
ffffffffc0205af6:	6b9c                	ld	a5,16(a5)
ffffffffc0205af8:	85a2                	mv	a1,s0
ffffffffc0205afa:	000da517          	auipc	a0,0xda
ffffffffc0205afe:	19653503          	ld	a0,406(a0) # ffffffffc02dfc90 <rq>
ffffffffc0205b02:	9782                	jalr	a5
    if (flag) {
ffffffffc0205b04:	e491                	bnez	s1,ffffffffc0205b10 <wakeup_proc+0x62>
        else {
            warn("wakeup runnable process.\n");
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc0205b06:	60e2                	ld	ra,24(sp)
ffffffffc0205b08:	6442                	ld	s0,16(sp)
ffffffffc0205b0a:	64a2                	ld	s1,8(sp)
ffffffffc0205b0c:	6105                	addi	sp,sp,32
ffffffffc0205b0e:	8082                	ret
ffffffffc0205b10:	6442                	ld	s0,16(sp)
ffffffffc0205b12:	60e2                	ld	ra,24(sp)
ffffffffc0205b14:	64a2                	ld	s1,8(sp)
ffffffffc0205b16:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0205b18:	e91fa06f          	j	ffffffffc02009a8 <intr_enable>
            warn("wakeup runnable process.\n");
ffffffffc0205b1c:	00003617          	auipc	a2,0x3
ffffffffc0205b20:	b2460613          	addi	a2,a2,-1244 # ffffffffc0208640 <default_pmm_manager+0x1388>
ffffffffc0205b24:	04800593          	li	a1,72
ffffffffc0205b28:	00003517          	auipc	a0,0x3
ffffffffc0205b2c:	b0050513          	addi	a0,a0,-1280 # ffffffffc0208628 <default_pmm_manager+0x1370>
ffffffffc0205b30:	9cbfa0ef          	jal	ra,ffffffffc02004fa <__warn>
ffffffffc0205b34:	bfc1                	j	ffffffffc0205b04 <wakeup_proc+0x56>
        intr_disable();
ffffffffc0205b36:	e79fa0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        if (proc->state != PROC_RUNNABLE) {
ffffffffc0205b3a:	4018                	lw	a4,0(s0)
        return 1;
ffffffffc0205b3c:	4485                	li	s1,1
ffffffffc0205b3e:	b771                	j	ffffffffc0205aca <wakeup_proc+0x1c>
    assert(proc->state != PROC_ZOMBIE);
ffffffffc0205b40:	00003697          	auipc	a3,0x3
ffffffffc0205b44:	ac868693          	addi	a3,a3,-1336 # ffffffffc0208608 <default_pmm_manager+0x1350>
ffffffffc0205b48:	00001617          	auipc	a2,0x1
ffffffffc0205b4c:	3c060613          	addi	a2,a2,960 # ffffffffc0206f08 <commands+0x818>
ffffffffc0205b50:	03c00593          	li	a1,60
ffffffffc0205b54:	00003517          	auipc	a0,0x3
ffffffffc0205b58:	ad450513          	addi	a0,a0,-1324 # ffffffffc0208628 <default_pmm_manager+0x1370>
ffffffffc0205b5c:	937fa0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0205b60 <schedule>:

void
schedule(void) {
ffffffffc0205b60:	7179                	addi	sp,sp,-48
ffffffffc0205b62:	f406                	sd	ra,40(sp)
ffffffffc0205b64:	f022                	sd	s0,32(sp)
ffffffffc0205b66:	ec26                	sd	s1,24(sp)
ffffffffc0205b68:	e84a                	sd	s2,16(sp)
ffffffffc0205b6a:	e44e                	sd	s3,8(sp)
ffffffffc0205b6c:	e052                	sd	s4,0(sp)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0205b6e:	100027f3          	csrr	a5,sstatus
ffffffffc0205b72:	8b89                	andi	a5,a5,2
ffffffffc0205b74:	4a01                	li	s4,0
ffffffffc0205b76:	e3cd                	bnez	a5,ffffffffc0205c18 <schedule+0xb8>
    bool intr_flag;
    struct proc_struct *next;
    local_intr_save(intr_flag);
    {
        current->need_resched = 0;
ffffffffc0205b78:	000da497          	auipc	s1,0xda
ffffffffc0205b7c:	0f848493          	addi	s1,s1,248 # ffffffffc02dfc70 <current>
ffffffffc0205b80:	608c                	ld	a1,0(s1)
        sched_class->enqueue(rq, proc);
ffffffffc0205b82:	000da997          	auipc	s3,0xda
ffffffffc0205b86:	11698993          	addi	s3,s3,278 # ffffffffc02dfc98 <sched_class>
ffffffffc0205b8a:	000da917          	auipc	s2,0xda
ffffffffc0205b8e:	10690913          	addi	s2,s2,262 # ffffffffc02dfc90 <rq>
        if (current->state == PROC_RUNNABLE) {
ffffffffc0205b92:	4194                	lw	a3,0(a1)
        current->need_resched = 0;
ffffffffc0205b94:	0005bc23          	sd	zero,24(a1)
        if (current->state == PROC_RUNNABLE) {
ffffffffc0205b98:	4709                	li	a4,2
        sched_class->enqueue(rq, proc);
ffffffffc0205b9a:	0009b783          	ld	a5,0(s3)
ffffffffc0205b9e:	00093503          	ld	a0,0(s2)
        if (current->state == PROC_RUNNABLE) {
ffffffffc0205ba2:	04e68e63          	beq	a3,a4,ffffffffc0205bfe <schedule+0x9e>
    return sched_class->pick_next(rq);
ffffffffc0205ba6:	739c                	ld	a5,32(a5)
ffffffffc0205ba8:	9782                	jalr	a5
ffffffffc0205baa:	842a                	mv	s0,a0
            sched_class_enqueue(current);
        }
        if ((next = sched_class_pick_next()) != NULL) {
ffffffffc0205bac:	c521                	beqz	a0,ffffffffc0205bf4 <schedule+0x94>
    sched_class->dequeue(rq, proc);
ffffffffc0205bae:	0009b783          	ld	a5,0(s3)
ffffffffc0205bb2:	00093503          	ld	a0,0(s2)
ffffffffc0205bb6:	85a2                	mv	a1,s0
ffffffffc0205bb8:	6f9c                	ld	a5,24(a5)
ffffffffc0205bba:	9782                	jalr	a5
            sched_class_dequeue(next);
        }
        if (next == NULL) {
            next = idleproc;
        }
        next->runs ++;
ffffffffc0205bbc:	441c                	lw	a5,8(s0)
        if (next != current) {
ffffffffc0205bbe:	6098                	ld	a4,0(s1)
        next->runs ++;
ffffffffc0205bc0:	2785                	addiw	a5,a5,1
ffffffffc0205bc2:	c41c                	sw	a5,8(s0)
        if (next != current) {
ffffffffc0205bc4:	00870563          	beq	a4,s0,ffffffffc0205bce <schedule+0x6e>
            proc_run(next);
ffffffffc0205bc8:	8522                	mv	a0,s0
ffffffffc0205bca:	b7ffe0ef          	jal	ra,ffffffffc0204748 <proc_run>
    if (flag) {
ffffffffc0205bce:	000a1a63          	bnez	s4,ffffffffc0205be2 <schedule+0x82>
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc0205bd2:	70a2                	ld	ra,40(sp)
ffffffffc0205bd4:	7402                	ld	s0,32(sp)
ffffffffc0205bd6:	64e2                	ld	s1,24(sp)
ffffffffc0205bd8:	6942                	ld	s2,16(sp)
ffffffffc0205bda:	69a2                	ld	s3,8(sp)
ffffffffc0205bdc:	6a02                	ld	s4,0(sp)
ffffffffc0205bde:	6145                	addi	sp,sp,48
ffffffffc0205be0:	8082                	ret
ffffffffc0205be2:	7402                	ld	s0,32(sp)
ffffffffc0205be4:	70a2                	ld	ra,40(sp)
ffffffffc0205be6:	64e2                	ld	s1,24(sp)
ffffffffc0205be8:	6942                	ld	s2,16(sp)
ffffffffc0205bea:	69a2                	ld	s3,8(sp)
ffffffffc0205bec:	6a02                	ld	s4,0(sp)
ffffffffc0205bee:	6145                	addi	sp,sp,48
        intr_enable();
ffffffffc0205bf0:	db9fa06f          	j	ffffffffc02009a8 <intr_enable>
            next = idleproc;
ffffffffc0205bf4:	000da417          	auipc	s0,0xda
ffffffffc0205bf8:	08443403          	ld	s0,132(s0) # ffffffffc02dfc78 <idleproc>
ffffffffc0205bfc:	b7c1                	j	ffffffffc0205bbc <schedule+0x5c>
    if (proc != idleproc) {
ffffffffc0205bfe:	000da717          	auipc	a4,0xda
ffffffffc0205c02:	07a73703          	ld	a4,122(a4) # ffffffffc02dfc78 <idleproc>
ffffffffc0205c06:	fae580e3          	beq	a1,a4,ffffffffc0205ba6 <schedule+0x46>
        sched_class->enqueue(rq, proc);
ffffffffc0205c0a:	6b9c                	ld	a5,16(a5)
ffffffffc0205c0c:	9782                	jalr	a5
    return sched_class->pick_next(rq);
ffffffffc0205c0e:	0009b783          	ld	a5,0(s3)
ffffffffc0205c12:	00093503          	ld	a0,0(s2)
ffffffffc0205c16:	bf41                	j	ffffffffc0205ba6 <schedule+0x46>
        intr_disable();
ffffffffc0205c18:	d97fa0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        return 1;
ffffffffc0205c1c:	4a05                	li	s4,1
ffffffffc0205c1e:	bfa9                	j	ffffffffc0205b78 <schedule+0x18>

ffffffffc0205c20 <add_timer>:

// add timer to timer_list
void
add_timer(timer_t *timer) {
ffffffffc0205c20:	1141                	addi	sp,sp,-16
ffffffffc0205c22:	e022                	sd	s0,0(sp)
ffffffffc0205c24:	e406                	sd	ra,8(sp)
ffffffffc0205c26:	842a                	mv	s0,a0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0205c28:	100027f3          	csrr	a5,sstatus
ffffffffc0205c2c:	8b89                	andi	a5,a5,2
ffffffffc0205c2e:	4501                	li	a0,0
ffffffffc0205c30:	eba5                	bnez	a5,ffffffffc0205ca0 <add_timer+0x80>
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        assert(timer->expires > 0 && timer->proc != NULL);
ffffffffc0205c32:	401c                	lw	a5,0(s0)
ffffffffc0205c34:	cbb5                	beqz	a5,ffffffffc0205ca8 <add_timer+0x88>
ffffffffc0205c36:	6418                	ld	a4,8(s0)
ffffffffc0205c38:	cb25                	beqz	a4,ffffffffc0205ca8 <add_timer+0x88>
        assert(list_empty(&(timer->timer_link)));
ffffffffc0205c3a:	6c18                	ld	a4,24(s0)
ffffffffc0205c3c:	01040593          	addi	a1,s0,16
ffffffffc0205c40:	08e59463          	bne	a1,a4,ffffffffc0205cc8 <add_timer+0xa8>
    return listelm->next;
ffffffffc0205c44:	000da617          	auipc	a2,0xda
ffffffffc0205c48:	fc460613          	addi	a2,a2,-60 # ffffffffc02dfc08 <timer_list>
ffffffffc0205c4c:	6618                	ld	a4,8(a2)
        list_entry_t *le = list_next(&timer_list);
        while (le != &timer_list) {
ffffffffc0205c4e:	00c71863          	bne	a4,a2,ffffffffc0205c5e <add_timer+0x3e>
ffffffffc0205c52:	a80d                	j	ffffffffc0205c84 <add_timer+0x64>
ffffffffc0205c54:	6718                	ld	a4,8(a4)
            timer_t *next = le2timer(le, timer_link);
            if (timer->expires < next->expires) {
                next->expires -= timer->expires;
                break;
            }
            timer->expires -= next->expires;
ffffffffc0205c56:	9f95                	subw	a5,a5,a3
ffffffffc0205c58:	c01c                	sw	a5,0(s0)
        while (le != &timer_list) {
ffffffffc0205c5a:	02c70563          	beq	a4,a2,ffffffffc0205c84 <add_timer+0x64>
            if (timer->expires < next->expires) {
ffffffffc0205c5e:	ff072683          	lw	a3,-16(a4)
ffffffffc0205c62:	fed7f9e3          	bgeu	a5,a3,ffffffffc0205c54 <add_timer+0x34>
                next->expires -= timer->expires;
ffffffffc0205c66:	40f687bb          	subw	a5,a3,a5
ffffffffc0205c6a:	fef72823          	sw	a5,-16(a4)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0205c6e:	631c                	ld	a5,0(a4)
    prev->next = next->prev = elm;
ffffffffc0205c70:	e30c                	sd	a1,0(a4)
ffffffffc0205c72:	e78c                	sd	a1,8(a5)
    elm->next = next;
ffffffffc0205c74:	ec18                	sd	a4,24(s0)
    elm->prev = prev;
ffffffffc0205c76:	e81c                	sd	a5,16(s0)
    if (flag) {
ffffffffc0205c78:	c105                	beqz	a0,ffffffffc0205c98 <add_timer+0x78>
            le = list_next(le);
        }
        list_add_before(le, &(timer->timer_link));
    }
    local_intr_restore(intr_flag);
}
ffffffffc0205c7a:	6402                	ld	s0,0(sp)
ffffffffc0205c7c:	60a2                	ld	ra,8(sp)
ffffffffc0205c7e:	0141                	addi	sp,sp,16
        intr_enable();
ffffffffc0205c80:	d29fa06f          	j	ffffffffc02009a8 <intr_enable>
    return 0;
ffffffffc0205c84:	000da717          	auipc	a4,0xda
ffffffffc0205c88:	f8470713          	addi	a4,a4,-124 # ffffffffc02dfc08 <timer_list>
    __list_add(elm, listelm->prev, listelm);
ffffffffc0205c8c:	631c                	ld	a5,0(a4)
    prev->next = next->prev = elm;
ffffffffc0205c8e:	e30c                	sd	a1,0(a4)
ffffffffc0205c90:	e78c                	sd	a1,8(a5)
    elm->next = next;
ffffffffc0205c92:	ec18                	sd	a4,24(s0)
    elm->prev = prev;
ffffffffc0205c94:	e81c                	sd	a5,16(s0)
    if (flag) {
ffffffffc0205c96:	f175                	bnez	a0,ffffffffc0205c7a <add_timer+0x5a>
ffffffffc0205c98:	60a2                	ld	ra,8(sp)
ffffffffc0205c9a:	6402                	ld	s0,0(sp)
ffffffffc0205c9c:	0141                	addi	sp,sp,16
ffffffffc0205c9e:	8082                	ret
        intr_disable();
ffffffffc0205ca0:	d0ffa0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        return 1;
ffffffffc0205ca4:	4505                	li	a0,1
ffffffffc0205ca6:	b771                	j	ffffffffc0205c32 <add_timer+0x12>
        assert(timer->expires > 0 && timer->proc != NULL);
ffffffffc0205ca8:	00003697          	auipc	a3,0x3
ffffffffc0205cac:	9b868693          	addi	a3,a3,-1608 # ffffffffc0208660 <default_pmm_manager+0x13a8>
ffffffffc0205cb0:	00001617          	auipc	a2,0x1
ffffffffc0205cb4:	25860613          	addi	a2,a2,600 # ffffffffc0206f08 <commands+0x818>
ffffffffc0205cb8:	06c00593          	li	a1,108
ffffffffc0205cbc:	00003517          	auipc	a0,0x3
ffffffffc0205cc0:	96c50513          	addi	a0,a0,-1684 # ffffffffc0208628 <default_pmm_manager+0x1370>
ffffffffc0205cc4:	fcefa0ef          	jal	ra,ffffffffc0200492 <__panic>
        assert(list_empty(&(timer->timer_link)));
ffffffffc0205cc8:	00003697          	auipc	a3,0x3
ffffffffc0205ccc:	9c868693          	addi	a3,a3,-1592 # ffffffffc0208690 <default_pmm_manager+0x13d8>
ffffffffc0205cd0:	00001617          	auipc	a2,0x1
ffffffffc0205cd4:	23860613          	addi	a2,a2,568 # ffffffffc0206f08 <commands+0x818>
ffffffffc0205cd8:	06d00593          	li	a1,109
ffffffffc0205cdc:	00003517          	auipc	a0,0x3
ffffffffc0205ce0:	94c50513          	addi	a0,a0,-1716 # ffffffffc0208628 <default_pmm_manager+0x1370>
ffffffffc0205ce4:	faefa0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0205ce8 <del_timer>:

// del timer from timer_list
void
del_timer(timer_t *timer) {
ffffffffc0205ce8:	1101                	addi	sp,sp,-32
ffffffffc0205cea:	e822                	sd	s0,16(sp)
ffffffffc0205cec:	ec06                	sd	ra,24(sp)
ffffffffc0205cee:	e426                	sd	s1,8(sp)
ffffffffc0205cf0:	842a                	mv	s0,a0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0205cf2:	100027f3          	csrr	a5,sstatus
ffffffffc0205cf6:	8b89                	andi	a5,a5,2
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        if (!list_empty(&(timer->timer_link))) {
ffffffffc0205cf8:	01050493          	addi	s1,a0,16
ffffffffc0205cfc:	eb9d                	bnez	a5,ffffffffc0205d32 <del_timer+0x4a>
    return list->next == list;
ffffffffc0205cfe:	6d1c                	ld	a5,24(a0)
ffffffffc0205d00:	02978463          	beq	a5,s1,ffffffffc0205d28 <del_timer+0x40>
            if (timer->expires != 0) {
ffffffffc0205d04:	4114                	lw	a3,0(a0)
    __list_del(listelm->prev, listelm->next);
ffffffffc0205d06:	6918                	ld	a4,16(a0)
ffffffffc0205d08:	ce81                	beqz	a3,ffffffffc0205d20 <del_timer+0x38>
                list_entry_t *le = list_next(&(timer->timer_link));
                if (le != &timer_list) {
ffffffffc0205d0a:	000da617          	auipc	a2,0xda
ffffffffc0205d0e:	efe60613          	addi	a2,a2,-258 # ffffffffc02dfc08 <timer_list>
ffffffffc0205d12:	00c78763          	beq	a5,a2,ffffffffc0205d20 <del_timer+0x38>
                    timer_t *next = le2timer(le, timer_link);
                    next->expires += timer->expires;
ffffffffc0205d16:	ff07a603          	lw	a2,-16(a5)
ffffffffc0205d1a:	9eb1                	addw	a3,a3,a2
ffffffffc0205d1c:	fed7a823          	sw	a3,-16(a5)
    prev->next = next;
ffffffffc0205d20:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0205d22:	e398                	sd	a4,0(a5)
    elm->prev = elm->next = elm;
ffffffffc0205d24:	ec04                	sd	s1,24(s0)
ffffffffc0205d26:	e804                	sd	s1,16(s0)
            }
            list_del_init(&(timer->timer_link));
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc0205d28:	60e2                	ld	ra,24(sp)
ffffffffc0205d2a:	6442                	ld	s0,16(sp)
ffffffffc0205d2c:	64a2                	ld	s1,8(sp)
ffffffffc0205d2e:	6105                	addi	sp,sp,32
ffffffffc0205d30:	8082                	ret
        intr_disable();
ffffffffc0205d32:	c7dfa0ef          	jal	ra,ffffffffc02009ae <intr_disable>
    return list->next == list;
ffffffffc0205d36:	6c1c                	ld	a5,24(s0)
        if (!list_empty(&(timer->timer_link))) {
ffffffffc0205d38:	02978463          	beq	a5,s1,ffffffffc0205d60 <del_timer+0x78>
            if (timer->expires != 0) {
ffffffffc0205d3c:	4014                	lw	a3,0(s0)
    __list_del(listelm->prev, listelm->next);
ffffffffc0205d3e:	6818                	ld	a4,16(s0)
ffffffffc0205d40:	ce81                	beqz	a3,ffffffffc0205d58 <del_timer+0x70>
                if (le != &timer_list) {
ffffffffc0205d42:	000da617          	auipc	a2,0xda
ffffffffc0205d46:	ec660613          	addi	a2,a2,-314 # ffffffffc02dfc08 <timer_list>
ffffffffc0205d4a:	00c78763          	beq	a5,a2,ffffffffc0205d58 <del_timer+0x70>
                    next->expires += timer->expires;
ffffffffc0205d4e:	ff07a603          	lw	a2,-16(a5)
ffffffffc0205d52:	9eb1                	addw	a3,a3,a2
ffffffffc0205d54:	fed7a823          	sw	a3,-16(a5)
    prev->next = next;
ffffffffc0205d58:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0205d5a:	e398                	sd	a4,0(a5)
    elm->prev = elm->next = elm;
ffffffffc0205d5c:	ec04                	sd	s1,24(s0)
ffffffffc0205d5e:	e804                	sd	s1,16(s0)
}
ffffffffc0205d60:	6442                	ld	s0,16(sp)
ffffffffc0205d62:	60e2                	ld	ra,24(sp)
ffffffffc0205d64:	64a2                	ld	s1,8(sp)
ffffffffc0205d66:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0205d68:	c41fa06f          	j	ffffffffc02009a8 <intr_enable>

ffffffffc0205d6c <run_timer_list>:

// call scheduler to update tick related info, and check the timer is expired? If expired, then wakup proc
void
run_timer_list(void) {
ffffffffc0205d6c:	7139                	addi	sp,sp,-64
ffffffffc0205d6e:	fc06                	sd	ra,56(sp)
ffffffffc0205d70:	f822                	sd	s0,48(sp)
ffffffffc0205d72:	f426                	sd	s1,40(sp)
ffffffffc0205d74:	f04a                	sd	s2,32(sp)
ffffffffc0205d76:	ec4e                	sd	s3,24(sp)
ffffffffc0205d78:	e852                	sd	s4,16(sp)
ffffffffc0205d7a:	e456                	sd	s5,8(sp)
ffffffffc0205d7c:	e05a                	sd	s6,0(sp)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0205d7e:	100027f3          	csrr	a5,sstatus
ffffffffc0205d82:	8b89                	andi	a5,a5,2
ffffffffc0205d84:	4b01                	li	s6,0
ffffffffc0205d86:	eff9                	bnez	a5,ffffffffc0205e64 <run_timer_list+0xf8>
    return listelm->next;
ffffffffc0205d88:	000da997          	auipc	s3,0xda
ffffffffc0205d8c:	e8098993          	addi	s3,s3,-384 # ffffffffc02dfc08 <timer_list>
ffffffffc0205d90:	0089b403          	ld	s0,8(s3)
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        list_entry_t *le = list_next(&timer_list);
        if (le != &timer_list) {
ffffffffc0205d94:	07340a63          	beq	s0,s3,ffffffffc0205e08 <run_timer_list+0x9c>
            timer_t *timer = le2timer(le, timer_link);
            assert(timer->expires != 0);
ffffffffc0205d98:	ff042783          	lw	a5,-16(s0)
            timer_t *timer = le2timer(le, timer_link);
ffffffffc0205d9c:	ff040913          	addi	s2,s0,-16
            assert(timer->expires != 0);
ffffffffc0205da0:	0e078663          	beqz	a5,ffffffffc0205e8c <run_timer_list+0x120>
            timer->expires --;
ffffffffc0205da4:	fff7871b          	addiw	a4,a5,-1
ffffffffc0205da8:	fee42823          	sw	a4,-16(s0)
            while (timer->expires == 0) {
ffffffffc0205dac:	ef31                	bnez	a4,ffffffffc0205e08 <run_timer_list+0x9c>
                struct proc_struct *proc = timer->proc;
                if (proc->wait_state != 0) {
                    assert(proc->wait_state & WT_INTERRUPTED);
                }
                else {
                    warn("process %d's wait_state == 0.\n", proc->pid);
ffffffffc0205dae:	00003a97          	auipc	s5,0x3
ffffffffc0205db2:	94aa8a93          	addi	s5,s5,-1718 # ffffffffc02086f8 <default_pmm_manager+0x1440>
ffffffffc0205db6:	00003a17          	auipc	s4,0x3
ffffffffc0205dba:	872a0a13          	addi	s4,s4,-1934 # ffffffffc0208628 <default_pmm_manager+0x1370>
ffffffffc0205dbe:	a005                	j	ffffffffc0205dde <run_timer_list+0x72>
                    assert(proc->wait_state & WT_INTERRUPTED);
ffffffffc0205dc0:	0a07d663          	bgez	a5,ffffffffc0205e6c <run_timer_list+0x100>
                }
                wakeup_proc(proc);
ffffffffc0205dc4:	8526                	mv	a0,s1
ffffffffc0205dc6:	ce9ff0ef          	jal	ra,ffffffffc0205aae <wakeup_proc>
                del_timer(timer);
ffffffffc0205dca:	854a                	mv	a0,s2
ffffffffc0205dcc:	f1dff0ef          	jal	ra,ffffffffc0205ce8 <del_timer>
                if (le == &timer_list) {
ffffffffc0205dd0:	03340c63          	beq	s0,s3,ffffffffc0205e08 <run_timer_list+0x9c>
            while (timer->expires == 0) {
ffffffffc0205dd4:	ff042783          	lw	a5,-16(s0)
                    break;
                }
                timer = le2timer(le, timer_link);
ffffffffc0205dd8:	ff040913          	addi	s2,s0,-16
            while (timer->expires == 0) {
ffffffffc0205ddc:	e795                	bnez	a5,ffffffffc0205e08 <run_timer_list+0x9c>
                struct proc_struct *proc = timer->proc;
ffffffffc0205dde:	00893483          	ld	s1,8(s2)
ffffffffc0205de2:	6400                	ld	s0,8(s0)
                if (proc->wait_state != 0) {
ffffffffc0205de4:	0ec4a783          	lw	a5,236(s1)
ffffffffc0205de8:	ffe1                	bnez	a5,ffffffffc0205dc0 <run_timer_list+0x54>
                    warn("process %d's wait_state == 0.\n", proc->pid);
ffffffffc0205dea:	40d4                	lw	a3,4(s1)
ffffffffc0205dec:	8656                	mv	a2,s5
ffffffffc0205dee:	0a300593          	li	a1,163
ffffffffc0205df2:	8552                	mv	a0,s4
ffffffffc0205df4:	f06fa0ef          	jal	ra,ffffffffc02004fa <__warn>
                wakeup_proc(proc);
ffffffffc0205df8:	8526                	mv	a0,s1
ffffffffc0205dfa:	cb5ff0ef          	jal	ra,ffffffffc0205aae <wakeup_proc>
                del_timer(timer);
ffffffffc0205dfe:	854a                	mv	a0,s2
ffffffffc0205e00:	ee9ff0ef          	jal	ra,ffffffffc0205ce8 <del_timer>
                if (le == &timer_list) {
ffffffffc0205e04:	fd3418e3          	bne	s0,s3,ffffffffc0205dd4 <run_timer_list+0x68>
            }
        }
        sched_class_proc_tick(current);
ffffffffc0205e08:	000da597          	auipc	a1,0xda
ffffffffc0205e0c:	e685b583          	ld	a1,-408(a1) # ffffffffc02dfc70 <current>
    if (proc != idleproc) {
ffffffffc0205e10:	000da797          	auipc	a5,0xda
ffffffffc0205e14:	e687b783          	ld	a5,-408(a5) # ffffffffc02dfc78 <idleproc>
ffffffffc0205e18:	04f58363          	beq	a1,a5,ffffffffc0205e5e <run_timer_list+0xf2>
        sched_class->proc_tick(rq, proc);
ffffffffc0205e1c:	000da797          	auipc	a5,0xda
ffffffffc0205e20:	e7c7b783          	ld	a5,-388(a5) # ffffffffc02dfc98 <sched_class>
ffffffffc0205e24:	779c                	ld	a5,40(a5)
ffffffffc0205e26:	000da517          	auipc	a0,0xda
ffffffffc0205e2a:	e6a53503          	ld	a0,-406(a0) # ffffffffc02dfc90 <rq>
ffffffffc0205e2e:	9782                	jalr	a5
    if (flag) {
ffffffffc0205e30:	000b1c63          	bnez	s6,ffffffffc0205e48 <run_timer_list+0xdc>
    }
    local_intr_restore(intr_flag);
}
ffffffffc0205e34:	70e2                	ld	ra,56(sp)
ffffffffc0205e36:	7442                	ld	s0,48(sp)
ffffffffc0205e38:	74a2                	ld	s1,40(sp)
ffffffffc0205e3a:	7902                	ld	s2,32(sp)
ffffffffc0205e3c:	69e2                	ld	s3,24(sp)
ffffffffc0205e3e:	6a42                	ld	s4,16(sp)
ffffffffc0205e40:	6aa2                	ld	s5,8(sp)
ffffffffc0205e42:	6b02                	ld	s6,0(sp)
ffffffffc0205e44:	6121                	addi	sp,sp,64
ffffffffc0205e46:	8082                	ret
ffffffffc0205e48:	7442                	ld	s0,48(sp)
ffffffffc0205e4a:	70e2                	ld	ra,56(sp)
ffffffffc0205e4c:	74a2                	ld	s1,40(sp)
ffffffffc0205e4e:	7902                	ld	s2,32(sp)
ffffffffc0205e50:	69e2                	ld	s3,24(sp)
ffffffffc0205e52:	6a42                	ld	s4,16(sp)
ffffffffc0205e54:	6aa2                	ld	s5,8(sp)
ffffffffc0205e56:	6b02                	ld	s6,0(sp)
ffffffffc0205e58:	6121                	addi	sp,sp,64
        intr_enable();
ffffffffc0205e5a:	b4ffa06f          	j	ffffffffc02009a8 <intr_enable>
        proc->need_resched = 1;
ffffffffc0205e5e:	4785                	li	a5,1
ffffffffc0205e60:	ed9c                	sd	a5,24(a1)
ffffffffc0205e62:	b7f9                	j	ffffffffc0205e30 <run_timer_list+0xc4>
        intr_disable();
ffffffffc0205e64:	b4bfa0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        return 1;
ffffffffc0205e68:	4b05                	li	s6,1
ffffffffc0205e6a:	bf39                	j	ffffffffc0205d88 <run_timer_list+0x1c>
                    assert(proc->wait_state & WT_INTERRUPTED);
ffffffffc0205e6c:	00003697          	auipc	a3,0x3
ffffffffc0205e70:	86468693          	addi	a3,a3,-1948 # ffffffffc02086d0 <default_pmm_manager+0x1418>
ffffffffc0205e74:	00001617          	auipc	a2,0x1
ffffffffc0205e78:	09460613          	addi	a2,a2,148 # ffffffffc0206f08 <commands+0x818>
ffffffffc0205e7c:	0a000593          	li	a1,160
ffffffffc0205e80:	00002517          	auipc	a0,0x2
ffffffffc0205e84:	7a850513          	addi	a0,a0,1960 # ffffffffc0208628 <default_pmm_manager+0x1370>
ffffffffc0205e88:	e0afa0ef          	jal	ra,ffffffffc0200492 <__panic>
            assert(timer->expires != 0);
ffffffffc0205e8c:	00003697          	auipc	a3,0x3
ffffffffc0205e90:	82c68693          	addi	a3,a3,-2004 # ffffffffc02086b8 <default_pmm_manager+0x1400>
ffffffffc0205e94:	00001617          	auipc	a2,0x1
ffffffffc0205e98:	07460613          	addi	a2,a2,116 # ffffffffc0206f08 <commands+0x818>
ffffffffc0205e9c:	09a00593          	li	a1,154
ffffffffc0205ea0:	00002517          	auipc	a0,0x2
ffffffffc0205ea4:	78850513          	addi	a0,a0,1928 # ffffffffc0208628 <default_pmm_manager+0x1370>
ffffffffc0205ea8:	deafa0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0205eac <sys_getpid>:
    return do_kill(pid);
}

static int
sys_getpid(uint64_t arg[]) {
    return current->pid;
ffffffffc0205eac:	000da797          	auipc	a5,0xda
ffffffffc0205eb0:	dc47b783          	ld	a5,-572(a5) # ffffffffc02dfc70 <current>
}
ffffffffc0205eb4:	43c8                	lw	a0,4(a5)
ffffffffc0205eb6:	8082                	ret

ffffffffc0205eb8 <sys_pgdir>:

static int
sys_pgdir(uint64_t arg[]) {
    //print_pgdir();
    return 0;
}
ffffffffc0205eb8:	4501                	li	a0,0
ffffffffc0205eba:	8082                	ret

ffffffffc0205ebc <sys_gettime>:
static int sys_gettime(uint64_t arg[]){
    return (int)ticks*10;
ffffffffc0205ebc:	000da797          	auipc	a5,0xda
ffffffffc0205ec0:	d647b783          	ld	a5,-668(a5) # ffffffffc02dfc20 <ticks>
ffffffffc0205ec4:	0027951b          	slliw	a0,a5,0x2
ffffffffc0205ec8:	9d3d                	addw	a0,a0,a5
}
ffffffffc0205eca:	0015151b          	slliw	a0,a0,0x1
ffffffffc0205ece:	8082                	ret

ffffffffc0205ed0 <sys_lab6_set_priority>:
static int sys_lab6_set_priority(uint64_t arg[]){
    uint64_t priority = (uint64_t)arg[0];
    lab6_set_priority(priority);
ffffffffc0205ed0:	4108                	lw	a0,0(a0)
static int sys_lab6_set_priority(uint64_t arg[]){
ffffffffc0205ed2:	1141                	addi	sp,sp,-16
ffffffffc0205ed4:	e406                	sd	ra,8(sp)
    lab6_set_priority(priority);
ffffffffc0205ed6:	9bdff0ef          	jal	ra,ffffffffc0205892 <lab6_set_priority>
    return 0;
}
ffffffffc0205eda:	60a2                	ld	ra,8(sp)
ffffffffc0205edc:	4501                	li	a0,0
ffffffffc0205ede:	0141                	addi	sp,sp,16
ffffffffc0205ee0:	8082                	ret

ffffffffc0205ee2 <sys_putc>:
    cputchar(c);
ffffffffc0205ee2:	4108                	lw	a0,0(a0)
sys_putc(uint64_t arg[]) {
ffffffffc0205ee4:	1141                	addi	sp,sp,-16
ffffffffc0205ee6:	e406                	sd	ra,8(sp)
    cputchar(c);
ffffffffc0205ee8:	ae6fa0ef          	jal	ra,ffffffffc02001ce <cputchar>
}
ffffffffc0205eec:	60a2                	ld	ra,8(sp)
ffffffffc0205eee:	4501                	li	a0,0
ffffffffc0205ef0:	0141                	addi	sp,sp,16
ffffffffc0205ef2:	8082                	ret

ffffffffc0205ef4 <sys_kill>:
    return do_kill(pid);
ffffffffc0205ef4:	4108                	lw	a0,0(a0)
ffffffffc0205ef6:	f6eff06f          	j	ffffffffc0205664 <do_kill>

ffffffffc0205efa <sys_sleep>:
static int
sys_sleep(uint64_t arg[]) {
    unsigned int time = (unsigned int)arg[0];
    return do_sleep(time);
ffffffffc0205efa:	4108                	lw	a0,0(a0)
ffffffffc0205efc:	9d1ff06f          	j	ffffffffc02058cc <do_sleep>

ffffffffc0205f00 <sys_yield>:
    return do_yield();
ffffffffc0205f00:	f16ff06f          	j	ffffffffc0205616 <do_yield>

ffffffffc0205f04 <sys_exec>:
    return do_execve(name, len, binary, size);
ffffffffc0205f04:	6d14                	ld	a3,24(a0)
ffffffffc0205f06:	6910                	ld	a2,16(a0)
ffffffffc0205f08:	650c                	ld	a1,8(a0)
ffffffffc0205f0a:	6108                	ld	a0,0(a0)
ffffffffc0205f0c:	95aff06f          	j	ffffffffc0205066 <do_execve>

ffffffffc0205f10 <sys_wait>:
    return do_wait(pid, store);
ffffffffc0205f10:	650c                	ld	a1,8(a0)
ffffffffc0205f12:	4108                	lw	a0,0(a0)
ffffffffc0205f14:	f12ff06f          	j	ffffffffc0205626 <do_wait>

ffffffffc0205f18 <sys_fork>:
    struct trapframe *tf = current->tf;
ffffffffc0205f18:	000da797          	auipc	a5,0xda
ffffffffc0205f1c:	d587b783          	ld	a5,-680(a5) # ffffffffc02dfc70 <current>
ffffffffc0205f20:	73d0                	ld	a2,160(a5)
    return do_fork(0, stack, tf);
ffffffffc0205f22:	4501                	li	a0,0
ffffffffc0205f24:	6a0c                	ld	a1,16(a2)
ffffffffc0205f26:	8e7fe06f          	j	ffffffffc020480c <do_fork>

ffffffffc0205f2a <sys_exit>:
    return do_exit(error_code);
ffffffffc0205f2a:	4108                	lw	a0,0(a0)
ffffffffc0205f2c:	cf5fe06f          	j	ffffffffc0204c20 <do_exit>

ffffffffc0205f30 <syscall>:
};

#define NUM_SYSCALLS        ((sizeof(syscalls)) / (sizeof(syscalls[0])))

void
syscall(void) {
ffffffffc0205f30:	715d                	addi	sp,sp,-80
ffffffffc0205f32:	fc26                	sd	s1,56(sp)
    struct trapframe *tf = current->tf;
ffffffffc0205f34:	000da497          	auipc	s1,0xda
ffffffffc0205f38:	d3c48493          	addi	s1,s1,-708 # ffffffffc02dfc70 <current>
ffffffffc0205f3c:	6098                	ld	a4,0(s1)
syscall(void) {
ffffffffc0205f3e:	e0a2                	sd	s0,64(sp)
ffffffffc0205f40:	f84a                	sd	s2,48(sp)
    struct trapframe *tf = current->tf;
ffffffffc0205f42:	7340                	ld	s0,160(a4)
syscall(void) {
ffffffffc0205f44:	e486                	sd	ra,72(sp)
    uint64_t arg[5];
    int num = tf->gpr.a0;
    if (num >= 0 && num < NUM_SYSCALLS) {
ffffffffc0205f46:	0ff00793          	li	a5,255
    int num = tf->gpr.a0;
ffffffffc0205f4a:	05042903          	lw	s2,80(s0)
    if (num >= 0 && num < NUM_SYSCALLS) {
ffffffffc0205f4e:	0327ee63          	bltu	a5,s2,ffffffffc0205f8a <syscall+0x5a>
        if (syscalls[num] != NULL) {
ffffffffc0205f52:	00391713          	slli	a4,s2,0x3
ffffffffc0205f56:	00003797          	auipc	a5,0x3
ffffffffc0205f5a:	80a78793          	addi	a5,a5,-2038 # ffffffffc0208760 <syscalls>
ffffffffc0205f5e:	97ba                	add	a5,a5,a4
ffffffffc0205f60:	639c                	ld	a5,0(a5)
ffffffffc0205f62:	c785                	beqz	a5,ffffffffc0205f8a <syscall+0x5a>
            arg[0] = tf->gpr.a1;
ffffffffc0205f64:	6c28                	ld	a0,88(s0)
            arg[1] = tf->gpr.a2;
ffffffffc0205f66:	702c                	ld	a1,96(s0)
            arg[2] = tf->gpr.a3;
ffffffffc0205f68:	7430                	ld	a2,104(s0)
            arg[3] = tf->gpr.a4;
ffffffffc0205f6a:	7834                	ld	a3,112(s0)
            arg[4] = tf->gpr.a5;
ffffffffc0205f6c:	7c38                	ld	a4,120(s0)
            arg[0] = tf->gpr.a1;
ffffffffc0205f6e:	e42a                	sd	a0,8(sp)
            arg[1] = tf->gpr.a2;
ffffffffc0205f70:	e82e                	sd	a1,16(sp)
            arg[2] = tf->gpr.a3;
ffffffffc0205f72:	ec32                	sd	a2,24(sp)
            arg[3] = tf->gpr.a4;
ffffffffc0205f74:	f036                	sd	a3,32(sp)
            arg[4] = tf->gpr.a5;
ffffffffc0205f76:	f43a                	sd	a4,40(sp)
            tf->gpr.a0 = syscalls[num](arg);
ffffffffc0205f78:	0028                	addi	a0,sp,8
ffffffffc0205f7a:	9782                	jalr	a5
        }
    }
    print_trapframe(tf);
    panic("undefined syscall %d, pid = %d, name = %s.\n",
            num, current->pid, current->name);
}
ffffffffc0205f7c:	60a6                	ld	ra,72(sp)
            tf->gpr.a0 = syscalls[num](arg);
ffffffffc0205f7e:	e828                	sd	a0,80(s0)
}
ffffffffc0205f80:	6406                	ld	s0,64(sp)
ffffffffc0205f82:	74e2                	ld	s1,56(sp)
ffffffffc0205f84:	7942                	ld	s2,48(sp)
ffffffffc0205f86:	6161                	addi	sp,sp,80
ffffffffc0205f88:	8082                	ret
    print_trapframe(tf);
ffffffffc0205f8a:	8522                	mv	a0,s0
ffffffffc0205f8c:	c13fa0ef          	jal	ra,ffffffffc0200b9e <print_trapframe>
    panic("undefined syscall %d, pid = %d, name = %s.\n",
ffffffffc0205f90:	609c                	ld	a5,0(s1)
ffffffffc0205f92:	86ca                	mv	a3,s2
ffffffffc0205f94:	00002617          	auipc	a2,0x2
ffffffffc0205f98:	78460613          	addi	a2,a2,1924 # ffffffffc0208718 <default_pmm_manager+0x1460>
ffffffffc0205f9c:	43d8                	lw	a4,4(a5)
ffffffffc0205f9e:	07300593          	li	a1,115
ffffffffc0205fa2:	0b478793          	addi	a5,a5,180
ffffffffc0205fa6:	00002517          	auipc	a0,0x2
ffffffffc0205faa:	7a250513          	addi	a0,a0,1954 # ffffffffc0208748 <default_pmm_manager+0x1490>
ffffffffc0205fae:	ce4fa0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0205fb2 <hash32>:
 *
 * High bits are more random, so we use them.
 * */
uint32_t
hash32(uint32_t val, unsigned int bits) {
    uint32_t hash = val * GOLDEN_RATIO_PRIME_32;
ffffffffc0205fb2:	9e3707b7          	lui	a5,0x9e370
ffffffffc0205fb6:	2785                	addiw	a5,a5,1
ffffffffc0205fb8:	02a7853b          	mulw	a0,a5,a0
    return (hash >> (32 - bits));
ffffffffc0205fbc:	02000793          	li	a5,32
ffffffffc0205fc0:	9f8d                	subw	a5,a5,a1
}
ffffffffc0205fc2:	00f5553b          	srlw	a0,a0,a5
ffffffffc0205fc6:	8082                	ret

ffffffffc0205fc8 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0205fc8:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0205fcc:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc0205fce:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0205fd2:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc0205fd4:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0205fd8:	f022                	sd	s0,32(sp)
ffffffffc0205fda:	ec26                	sd	s1,24(sp)
ffffffffc0205fdc:	e84a                	sd	s2,16(sp)
ffffffffc0205fde:	f406                	sd	ra,40(sp)
ffffffffc0205fe0:	e44e                	sd	s3,8(sp)
ffffffffc0205fe2:	84aa                	mv	s1,a0
ffffffffc0205fe4:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0205fe6:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc0205fea:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc0205fec:	03067e63          	bgeu	a2,a6,ffffffffc0206028 <printnum+0x60>
ffffffffc0205ff0:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc0205ff2:	00805763          	blez	s0,ffffffffc0206000 <printnum+0x38>
ffffffffc0205ff6:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0205ff8:	85ca                	mv	a1,s2
ffffffffc0205ffa:	854e                	mv	a0,s3
ffffffffc0205ffc:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0205ffe:	fc65                	bnez	s0,ffffffffc0205ff6 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0206000:	1a02                	slli	s4,s4,0x20
ffffffffc0206002:	00003797          	auipc	a5,0x3
ffffffffc0206006:	f5e78793          	addi	a5,a5,-162 # ffffffffc0208f60 <syscalls+0x800>
ffffffffc020600a:	020a5a13          	srli	s4,s4,0x20
ffffffffc020600e:	9a3e                	add	s4,s4,a5
    // Crashes if num >= base. No idea what going on here
    // Here is a quick fix
    // update: Stack grows downward and destory the SBI
    // sbi_console_putchar("0123456789abcdef"[mod]);
    // (*(int *)putdat)++;
}
ffffffffc0206010:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0206012:	000a4503          	lbu	a0,0(s4)
}
ffffffffc0206016:	70a2                	ld	ra,40(sp)
ffffffffc0206018:	69a2                	ld	s3,8(sp)
ffffffffc020601a:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020601c:	85ca                	mv	a1,s2
ffffffffc020601e:	87a6                	mv	a5,s1
}
ffffffffc0206020:	6942                	ld	s2,16(sp)
ffffffffc0206022:	64e2                	ld	s1,24(sp)
ffffffffc0206024:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0206026:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0206028:	03065633          	divu	a2,a2,a6
ffffffffc020602c:	8722                	mv	a4,s0
ffffffffc020602e:	f9bff0ef          	jal	ra,ffffffffc0205fc8 <printnum>
ffffffffc0206032:	b7f9                	j	ffffffffc0206000 <printnum+0x38>

ffffffffc0206034 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0206034:	7119                	addi	sp,sp,-128
ffffffffc0206036:	f4a6                	sd	s1,104(sp)
ffffffffc0206038:	f0ca                	sd	s2,96(sp)
ffffffffc020603a:	ecce                	sd	s3,88(sp)
ffffffffc020603c:	e8d2                	sd	s4,80(sp)
ffffffffc020603e:	e4d6                	sd	s5,72(sp)
ffffffffc0206040:	e0da                	sd	s6,64(sp)
ffffffffc0206042:	fc5e                	sd	s7,56(sp)
ffffffffc0206044:	f06a                	sd	s10,32(sp)
ffffffffc0206046:	fc86                	sd	ra,120(sp)
ffffffffc0206048:	f8a2                	sd	s0,112(sp)
ffffffffc020604a:	f862                	sd	s8,48(sp)
ffffffffc020604c:	f466                	sd	s9,40(sp)
ffffffffc020604e:	ec6e                	sd	s11,24(sp)
ffffffffc0206050:	892a                	mv	s2,a0
ffffffffc0206052:	84ae                	mv	s1,a1
ffffffffc0206054:	8d32                	mv	s10,a2
ffffffffc0206056:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0206058:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc020605c:	5b7d                	li	s6,-1
ffffffffc020605e:	00003a97          	auipc	s5,0x3
ffffffffc0206062:	f2ea8a93          	addi	s5,s5,-210 # ffffffffc0208f8c <syscalls+0x82c>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0206066:	00003b97          	auipc	s7,0x3
ffffffffc020606a:	142b8b93          	addi	s7,s7,322 # ffffffffc02091a8 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc020606e:	000d4503          	lbu	a0,0(s10)
ffffffffc0206072:	001d0413          	addi	s0,s10,1
ffffffffc0206076:	01350a63          	beq	a0,s3,ffffffffc020608a <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc020607a:	c121                	beqz	a0,ffffffffc02060ba <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc020607c:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc020607e:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc0206080:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0206082:	fff44503          	lbu	a0,-1(s0)
ffffffffc0206086:	ff351ae3          	bne	a0,s3,ffffffffc020607a <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020608a:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc020608e:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc0206092:	4c81                	li	s9,0
ffffffffc0206094:	4881                	li	a7,0
        width = precision = -1;
ffffffffc0206096:	5c7d                	li	s8,-1
ffffffffc0206098:	5dfd                	li	s11,-1
ffffffffc020609a:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc020609e:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02060a0:	fdd6059b          	addiw	a1,a2,-35
ffffffffc02060a4:	0ff5f593          	zext.b	a1,a1
ffffffffc02060a8:	00140d13          	addi	s10,s0,1
ffffffffc02060ac:	04b56263          	bltu	a0,a1,ffffffffc02060f0 <vprintfmt+0xbc>
ffffffffc02060b0:	058a                	slli	a1,a1,0x2
ffffffffc02060b2:	95d6                	add	a1,a1,s5
ffffffffc02060b4:	4194                	lw	a3,0(a1)
ffffffffc02060b6:	96d6                	add	a3,a3,s5
ffffffffc02060b8:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc02060ba:	70e6                	ld	ra,120(sp)
ffffffffc02060bc:	7446                	ld	s0,112(sp)
ffffffffc02060be:	74a6                	ld	s1,104(sp)
ffffffffc02060c0:	7906                	ld	s2,96(sp)
ffffffffc02060c2:	69e6                	ld	s3,88(sp)
ffffffffc02060c4:	6a46                	ld	s4,80(sp)
ffffffffc02060c6:	6aa6                	ld	s5,72(sp)
ffffffffc02060c8:	6b06                	ld	s6,64(sp)
ffffffffc02060ca:	7be2                	ld	s7,56(sp)
ffffffffc02060cc:	7c42                	ld	s8,48(sp)
ffffffffc02060ce:	7ca2                	ld	s9,40(sp)
ffffffffc02060d0:	7d02                	ld	s10,32(sp)
ffffffffc02060d2:	6de2                	ld	s11,24(sp)
ffffffffc02060d4:	6109                	addi	sp,sp,128
ffffffffc02060d6:	8082                	ret
            padc = '0';
ffffffffc02060d8:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc02060da:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02060de:	846a                	mv	s0,s10
ffffffffc02060e0:	00140d13          	addi	s10,s0,1
ffffffffc02060e4:	fdd6059b          	addiw	a1,a2,-35
ffffffffc02060e8:	0ff5f593          	zext.b	a1,a1
ffffffffc02060ec:	fcb572e3          	bgeu	a0,a1,ffffffffc02060b0 <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc02060f0:	85a6                	mv	a1,s1
ffffffffc02060f2:	02500513          	li	a0,37
ffffffffc02060f6:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc02060f8:	fff44783          	lbu	a5,-1(s0)
ffffffffc02060fc:	8d22                	mv	s10,s0
ffffffffc02060fe:	f73788e3          	beq	a5,s3,ffffffffc020606e <vprintfmt+0x3a>
ffffffffc0206102:	ffed4783          	lbu	a5,-2(s10)
ffffffffc0206106:	1d7d                	addi	s10,s10,-1
ffffffffc0206108:	ff379de3          	bne	a5,s3,ffffffffc0206102 <vprintfmt+0xce>
ffffffffc020610c:	b78d                	j	ffffffffc020606e <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc020610e:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc0206112:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0206116:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc0206118:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc020611c:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0206120:	02d86463          	bltu	a6,a3,ffffffffc0206148 <vprintfmt+0x114>
                ch = *fmt;
ffffffffc0206124:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0206128:	002c169b          	slliw	a3,s8,0x2
ffffffffc020612c:	0186873b          	addw	a4,a3,s8
ffffffffc0206130:	0017171b          	slliw	a4,a4,0x1
ffffffffc0206134:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc0206136:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc020613a:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc020613c:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc0206140:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0206144:	fed870e3          	bgeu	a6,a3,ffffffffc0206124 <vprintfmt+0xf0>
            if (width < 0)
ffffffffc0206148:	f40ddce3          	bgez	s11,ffffffffc02060a0 <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc020614c:	8de2                	mv	s11,s8
ffffffffc020614e:	5c7d                	li	s8,-1
ffffffffc0206150:	bf81                	j	ffffffffc02060a0 <vprintfmt+0x6c>
            if (width < 0)
ffffffffc0206152:	fffdc693          	not	a3,s11
ffffffffc0206156:	96fd                	srai	a3,a3,0x3f
ffffffffc0206158:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020615c:	00144603          	lbu	a2,1(s0)
ffffffffc0206160:	2d81                	sext.w	s11,s11
ffffffffc0206162:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0206164:	bf35                	j	ffffffffc02060a0 <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc0206166:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020616a:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc020616e:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0206170:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc0206172:	bfd9                	j	ffffffffc0206148 <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc0206174:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0206176:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc020617a:	01174463          	blt	a4,a7,ffffffffc0206182 <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc020617e:	1a088e63          	beqz	a7,ffffffffc020633a <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc0206182:	000a3603          	ld	a2,0(s4)
ffffffffc0206186:	46c1                	li	a3,16
ffffffffc0206188:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc020618a:	2781                	sext.w	a5,a5
ffffffffc020618c:	876e                	mv	a4,s11
ffffffffc020618e:	85a6                	mv	a1,s1
ffffffffc0206190:	854a                	mv	a0,s2
ffffffffc0206192:	e37ff0ef          	jal	ra,ffffffffc0205fc8 <printnum>
            break;
ffffffffc0206196:	bde1                	j	ffffffffc020606e <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc0206198:	000a2503          	lw	a0,0(s4)
ffffffffc020619c:	85a6                	mv	a1,s1
ffffffffc020619e:	0a21                	addi	s4,s4,8
ffffffffc02061a0:	9902                	jalr	s2
            break;
ffffffffc02061a2:	b5f1                	j	ffffffffc020606e <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc02061a4:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02061a6:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc02061aa:	01174463          	blt	a4,a7,ffffffffc02061b2 <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc02061ae:	18088163          	beqz	a7,ffffffffc0206330 <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc02061b2:	000a3603          	ld	a2,0(s4)
ffffffffc02061b6:	46a9                	li	a3,10
ffffffffc02061b8:	8a2e                	mv	s4,a1
ffffffffc02061ba:	bfc1                	j	ffffffffc020618a <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02061bc:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc02061c0:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02061c2:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02061c4:	bdf1                	j	ffffffffc02060a0 <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc02061c6:	85a6                	mv	a1,s1
ffffffffc02061c8:	02500513          	li	a0,37
ffffffffc02061cc:	9902                	jalr	s2
            break;
ffffffffc02061ce:	b545                	j	ffffffffc020606e <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02061d0:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc02061d4:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02061d6:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02061d8:	b5e1                	j	ffffffffc02060a0 <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc02061da:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02061dc:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc02061e0:	01174463          	blt	a4,a7,ffffffffc02061e8 <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc02061e4:	14088163          	beqz	a7,ffffffffc0206326 <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc02061e8:	000a3603          	ld	a2,0(s4)
ffffffffc02061ec:	46a1                	li	a3,8
ffffffffc02061ee:	8a2e                	mv	s4,a1
ffffffffc02061f0:	bf69                	j	ffffffffc020618a <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc02061f2:	03000513          	li	a0,48
ffffffffc02061f6:	85a6                	mv	a1,s1
ffffffffc02061f8:	e03e                	sd	a5,0(sp)
ffffffffc02061fa:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc02061fc:	85a6                	mv	a1,s1
ffffffffc02061fe:	07800513          	li	a0,120
ffffffffc0206202:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0206204:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0206206:	6782                	ld	a5,0(sp)
ffffffffc0206208:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc020620a:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc020620e:	bfb5                	j	ffffffffc020618a <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0206210:	000a3403          	ld	s0,0(s4)
ffffffffc0206214:	008a0713          	addi	a4,s4,8
ffffffffc0206218:	e03a                	sd	a4,0(sp)
ffffffffc020621a:	14040263          	beqz	s0,ffffffffc020635e <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc020621e:	0fb05763          	blez	s11,ffffffffc020630c <vprintfmt+0x2d8>
ffffffffc0206222:	02d00693          	li	a3,45
ffffffffc0206226:	0cd79163          	bne	a5,a3,ffffffffc02062e8 <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020622a:	00044783          	lbu	a5,0(s0)
ffffffffc020622e:	0007851b          	sext.w	a0,a5
ffffffffc0206232:	cf85                	beqz	a5,ffffffffc020626a <vprintfmt+0x236>
ffffffffc0206234:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0206238:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020623c:	000c4563          	bltz	s8,ffffffffc0206246 <vprintfmt+0x212>
ffffffffc0206240:	3c7d                	addiw	s8,s8,-1
ffffffffc0206242:	036c0263          	beq	s8,s6,ffffffffc0206266 <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc0206246:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0206248:	0e0c8e63          	beqz	s9,ffffffffc0206344 <vprintfmt+0x310>
ffffffffc020624c:	3781                	addiw	a5,a5,-32
ffffffffc020624e:	0ef47b63          	bgeu	s0,a5,ffffffffc0206344 <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc0206252:	03f00513          	li	a0,63
ffffffffc0206256:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0206258:	000a4783          	lbu	a5,0(s4)
ffffffffc020625c:	3dfd                	addiw	s11,s11,-1
ffffffffc020625e:	0a05                	addi	s4,s4,1
ffffffffc0206260:	0007851b          	sext.w	a0,a5
ffffffffc0206264:	ffe1                	bnez	a5,ffffffffc020623c <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc0206266:	01b05963          	blez	s11,ffffffffc0206278 <vprintfmt+0x244>
ffffffffc020626a:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc020626c:	85a6                	mv	a1,s1
ffffffffc020626e:	02000513          	li	a0,32
ffffffffc0206272:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0206274:	fe0d9be3          	bnez	s11,ffffffffc020626a <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0206278:	6a02                	ld	s4,0(sp)
ffffffffc020627a:	bbd5                	j	ffffffffc020606e <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc020627c:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc020627e:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc0206282:	01174463          	blt	a4,a7,ffffffffc020628a <vprintfmt+0x256>
    else if (lflag) {
ffffffffc0206286:	08088d63          	beqz	a7,ffffffffc0206320 <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc020628a:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc020628e:	0a044d63          	bltz	s0,ffffffffc0206348 <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc0206292:	8622                	mv	a2,s0
ffffffffc0206294:	8a66                	mv	s4,s9
ffffffffc0206296:	46a9                	li	a3,10
ffffffffc0206298:	bdcd                	j	ffffffffc020618a <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc020629a:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc020629e:	4761                	li	a4,24
            err = va_arg(ap, int);
ffffffffc02062a0:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc02062a2:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc02062a6:	8fb5                	xor	a5,a5,a3
ffffffffc02062a8:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02062ac:	02d74163          	blt	a4,a3,ffffffffc02062ce <vprintfmt+0x29a>
ffffffffc02062b0:	00369793          	slli	a5,a3,0x3
ffffffffc02062b4:	97de                	add	a5,a5,s7
ffffffffc02062b6:	639c                	ld	a5,0(a5)
ffffffffc02062b8:	cb99                	beqz	a5,ffffffffc02062ce <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc02062ba:	86be                	mv	a3,a5
ffffffffc02062bc:	00000617          	auipc	a2,0x0
ffffffffc02062c0:	1f460613          	addi	a2,a2,500 # ffffffffc02064b0 <etext+0x2e>
ffffffffc02062c4:	85a6                	mv	a1,s1
ffffffffc02062c6:	854a                	mv	a0,s2
ffffffffc02062c8:	0ce000ef          	jal	ra,ffffffffc0206396 <printfmt>
ffffffffc02062cc:	b34d                	j	ffffffffc020606e <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc02062ce:	00003617          	auipc	a2,0x3
ffffffffc02062d2:	cb260613          	addi	a2,a2,-846 # ffffffffc0208f80 <syscalls+0x820>
ffffffffc02062d6:	85a6                	mv	a1,s1
ffffffffc02062d8:	854a                	mv	a0,s2
ffffffffc02062da:	0bc000ef          	jal	ra,ffffffffc0206396 <printfmt>
ffffffffc02062de:	bb41                	j	ffffffffc020606e <vprintfmt+0x3a>
                p = "(null)";
ffffffffc02062e0:	00003417          	auipc	s0,0x3
ffffffffc02062e4:	c9840413          	addi	s0,s0,-872 # ffffffffc0208f78 <syscalls+0x818>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02062e8:	85e2                	mv	a1,s8
ffffffffc02062ea:	8522                	mv	a0,s0
ffffffffc02062ec:	e43e                	sd	a5,8(sp)
ffffffffc02062ee:	0e2000ef          	jal	ra,ffffffffc02063d0 <strnlen>
ffffffffc02062f2:	40ad8dbb          	subw	s11,s11,a0
ffffffffc02062f6:	01b05b63          	blez	s11,ffffffffc020630c <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc02062fa:	67a2                	ld	a5,8(sp)
ffffffffc02062fc:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0206300:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc0206302:	85a6                	mv	a1,s1
ffffffffc0206304:	8552                	mv	a0,s4
ffffffffc0206306:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0206308:	fe0d9ce3          	bnez	s11,ffffffffc0206300 <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020630c:	00044783          	lbu	a5,0(s0)
ffffffffc0206310:	00140a13          	addi	s4,s0,1
ffffffffc0206314:	0007851b          	sext.w	a0,a5
ffffffffc0206318:	d3a5                	beqz	a5,ffffffffc0206278 <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc020631a:	05e00413          	li	s0,94
ffffffffc020631e:	bf39                	j	ffffffffc020623c <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc0206320:	000a2403          	lw	s0,0(s4)
ffffffffc0206324:	b7ad                	j	ffffffffc020628e <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc0206326:	000a6603          	lwu	a2,0(s4)
ffffffffc020632a:	46a1                	li	a3,8
ffffffffc020632c:	8a2e                	mv	s4,a1
ffffffffc020632e:	bdb1                	j	ffffffffc020618a <vprintfmt+0x156>
ffffffffc0206330:	000a6603          	lwu	a2,0(s4)
ffffffffc0206334:	46a9                	li	a3,10
ffffffffc0206336:	8a2e                	mv	s4,a1
ffffffffc0206338:	bd89                	j	ffffffffc020618a <vprintfmt+0x156>
ffffffffc020633a:	000a6603          	lwu	a2,0(s4)
ffffffffc020633e:	46c1                	li	a3,16
ffffffffc0206340:	8a2e                	mv	s4,a1
ffffffffc0206342:	b5a1                	j	ffffffffc020618a <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc0206344:	9902                	jalr	s2
ffffffffc0206346:	bf09                	j	ffffffffc0206258 <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc0206348:	85a6                	mv	a1,s1
ffffffffc020634a:	02d00513          	li	a0,45
ffffffffc020634e:	e03e                	sd	a5,0(sp)
ffffffffc0206350:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0206352:	6782                	ld	a5,0(sp)
ffffffffc0206354:	8a66                	mv	s4,s9
ffffffffc0206356:	40800633          	neg	a2,s0
ffffffffc020635a:	46a9                	li	a3,10
ffffffffc020635c:	b53d                	j	ffffffffc020618a <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc020635e:	03b05163          	blez	s11,ffffffffc0206380 <vprintfmt+0x34c>
ffffffffc0206362:	02d00693          	li	a3,45
ffffffffc0206366:	f6d79de3          	bne	a5,a3,ffffffffc02062e0 <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc020636a:	00003417          	auipc	s0,0x3
ffffffffc020636e:	c0e40413          	addi	s0,s0,-1010 # ffffffffc0208f78 <syscalls+0x818>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0206372:	02800793          	li	a5,40
ffffffffc0206376:	02800513          	li	a0,40
ffffffffc020637a:	00140a13          	addi	s4,s0,1
ffffffffc020637e:	bd6d                	j	ffffffffc0206238 <vprintfmt+0x204>
ffffffffc0206380:	00003a17          	auipc	s4,0x3
ffffffffc0206384:	bf9a0a13          	addi	s4,s4,-1031 # ffffffffc0208f79 <syscalls+0x819>
ffffffffc0206388:	02800513          	li	a0,40
ffffffffc020638c:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0206390:	05e00413          	li	s0,94
ffffffffc0206394:	b565                	j	ffffffffc020623c <vprintfmt+0x208>

ffffffffc0206396 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0206396:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0206398:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc020639c:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc020639e:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02063a0:	ec06                	sd	ra,24(sp)
ffffffffc02063a2:	f83a                	sd	a4,48(sp)
ffffffffc02063a4:	fc3e                	sd	a5,56(sp)
ffffffffc02063a6:	e0c2                	sd	a6,64(sp)
ffffffffc02063a8:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc02063aa:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc02063ac:	c89ff0ef          	jal	ra,ffffffffc0206034 <vprintfmt>
}
ffffffffc02063b0:	60e2                	ld	ra,24(sp)
ffffffffc02063b2:	6161                	addi	sp,sp,80
ffffffffc02063b4:	8082                	ret

ffffffffc02063b6 <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc02063b6:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc02063ba:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc02063bc:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc02063be:	cb81                	beqz	a5,ffffffffc02063ce <strlen+0x18>
        cnt ++;
ffffffffc02063c0:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc02063c2:	00a707b3          	add	a5,a4,a0
ffffffffc02063c6:	0007c783          	lbu	a5,0(a5)
ffffffffc02063ca:	fbfd                	bnez	a5,ffffffffc02063c0 <strlen+0xa>
ffffffffc02063cc:	8082                	ret
    }
    return cnt;
}
ffffffffc02063ce:	8082                	ret

ffffffffc02063d0 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc02063d0:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc02063d2:	e589                	bnez	a1,ffffffffc02063dc <strnlen+0xc>
ffffffffc02063d4:	a811                	j	ffffffffc02063e8 <strnlen+0x18>
        cnt ++;
ffffffffc02063d6:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc02063d8:	00f58863          	beq	a1,a5,ffffffffc02063e8 <strnlen+0x18>
ffffffffc02063dc:	00f50733          	add	a4,a0,a5
ffffffffc02063e0:	00074703          	lbu	a4,0(a4)
ffffffffc02063e4:	fb6d                	bnez	a4,ffffffffc02063d6 <strnlen+0x6>
ffffffffc02063e6:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc02063e8:	852e                	mv	a0,a1
ffffffffc02063ea:	8082                	ret

ffffffffc02063ec <strcpy>:
char *
strcpy(char *dst, const char *src) {
#ifdef __HAVE_ARCH_STRCPY
    return __strcpy(dst, src);
#else
    char *p = dst;
ffffffffc02063ec:	87aa                	mv	a5,a0
    while ((*p ++ = *src ++) != '\0')
ffffffffc02063ee:	0005c703          	lbu	a4,0(a1)
ffffffffc02063f2:	0785                	addi	a5,a5,1
ffffffffc02063f4:	0585                	addi	a1,a1,1
ffffffffc02063f6:	fee78fa3          	sb	a4,-1(a5)
ffffffffc02063fa:	fb75                	bnez	a4,ffffffffc02063ee <strcpy+0x2>
        /* nothing */;
    return dst;
#endif /* __HAVE_ARCH_STRCPY */
}
ffffffffc02063fc:	8082                	ret

ffffffffc02063fe <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02063fe:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0206402:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0206406:	cb89                	beqz	a5,ffffffffc0206418 <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc0206408:	0505                	addi	a0,a0,1
ffffffffc020640a:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc020640c:	fee789e3          	beq	a5,a4,ffffffffc02063fe <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0206410:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0206414:	9d19                	subw	a0,a0,a4
ffffffffc0206416:	8082                	ret
ffffffffc0206418:	4501                	li	a0,0
ffffffffc020641a:	bfed                	j	ffffffffc0206414 <strcmp+0x16>

ffffffffc020641c <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc020641c:	c20d                	beqz	a2,ffffffffc020643e <strncmp+0x22>
ffffffffc020641e:	962e                	add	a2,a2,a1
ffffffffc0206420:	a031                	j	ffffffffc020642c <strncmp+0x10>
        n --, s1 ++, s2 ++;
ffffffffc0206422:	0505                	addi	a0,a0,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0206424:	00e79a63          	bne	a5,a4,ffffffffc0206438 <strncmp+0x1c>
ffffffffc0206428:	00b60b63          	beq	a2,a1,ffffffffc020643e <strncmp+0x22>
ffffffffc020642c:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc0206430:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0206432:	fff5c703          	lbu	a4,-1(a1)
ffffffffc0206436:	f7f5                	bnez	a5,ffffffffc0206422 <strncmp+0x6>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0206438:	40e7853b          	subw	a0,a5,a4
}
ffffffffc020643c:	8082                	ret
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc020643e:	4501                	li	a0,0
ffffffffc0206440:	8082                	ret

ffffffffc0206442 <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc0206442:	00054783          	lbu	a5,0(a0)
ffffffffc0206446:	c799                	beqz	a5,ffffffffc0206454 <strchr+0x12>
        if (*s == c) {
ffffffffc0206448:	00f58763          	beq	a1,a5,ffffffffc0206456 <strchr+0x14>
    while (*s != '\0') {
ffffffffc020644c:	00154783          	lbu	a5,1(a0)
            return (char *)s;
        }
        s ++;
ffffffffc0206450:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc0206452:	fbfd                	bnez	a5,ffffffffc0206448 <strchr+0x6>
    }
    return NULL;
ffffffffc0206454:	4501                	li	a0,0
}
ffffffffc0206456:	8082                	ret

ffffffffc0206458 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0206458:	ca01                	beqz	a2,ffffffffc0206468 <memset+0x10>
ffffffffc020645a:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc020645c:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc020645e:	0785                	addi	a5,a5,1
ffffffffc0206460:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0206464:	fec79de3          	bne	a5,a2,ffffffffc020645e <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0206468:	8082                	ret

ffffffffc020646a <memcpy>:
#ifdef __HAVE_ARCH_MEMCPY
    return __memcpy(dst, src, n);
#else
    const char *s = src;
    char *d = dst;
    while (n -- > 0) {
ffffffffc020646a:	ca19                	beqz	a2,ffffffffc0206480 <memcpy+0x16>
ffffffffc020646c:	962e                	add	a2,a2,a1
    char *d = dst;
ffffffffc020646e:	87aa                	mv	a5,a0
        *d ++ = *s ++;
ffffffffc0206470:	0005c703          	lbu	a4,0(a1)
ffffffffc0206474:	0585                	addi	a1,a1,1
ffffffffc0206476:	0785                	addi	a5,a5,1
ffffffffc0206478:	fee78fa3          	sb	a4,-1(a5)
    while (n -- > 0) {
ffffffffc020647c:	fec59ae3          	bne	a1,a2,ffffffffc0206470 <memcpy+0x6>
    }
    return dst;
#endif /* __HAVE_ARCH_MEMCPY */
}
ffffffffc0206480:	8082                	ret
