
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	0000c297          	auipc	t0,0xc
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc020c000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	0000c297          	auipc	t0,0xc
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc020c008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)

    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c020b2b7          	lui	t0,0xc020b
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
ffffffffc020003c:	c020b137          	lui	sp,0xc020b

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
ffffffffc020004a:	000c2517          	auipc	a0,0xc2
ffffffffc020004e:	7d650513          	addi	a0,a0,2006 # ffffffffc02c2820 <buf>
ffffffffc0200052:	000c7617          	auipc	a2,0xc7
ffffffffc0200056:	cb660613          	addi	a2,a2,-842 # ffffffffc02c6d08 <end>
{
ffffffffc020005a:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc020005c:	8e09                	sub	a2,a2,a0
ffffffffc020005e:	4581                	li	a1,0
{
ffffffffc0200060:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc0200062:	7c2050ef          	jal	ra,ffffffffc0205824 <memset>
    cons_init(); // init the console
ffffffffc0200066:	520000ef          	jal	ra,ffffffffc0200586 <cons_init>

    const char *message = "(THU.CST) os is loading ...";
    cprintf("%s\n\n", message);
ffffffffc020006a:	00005597          	auipc	a1,0x5
ffffffffc020006e:	7e658593          	addi	a1,a1,2022 # ffffffffc0205850 <etext+0x2>
ffffffffc0200072:	00005517          	auipc	a0,0x5
ffffffffc0200076:	7fe50513          	addi	a0,a0,2046 # ffffffffc0205870 <etext+0x22>
ffffffffc020007a:	11e000ef          	jal	ra,ffffffffc0200198 <cprintf>

    print_kerninfo();
ffffffffc020007e:	1a2000ef          	jal	ra,ffffffffc0200220 <print_kerninfo>

    // grade_backtrace();

    dtb_init(); // init dtb
ffffffffc0200082:	576000ef          	jal	ra,ffffffffc02005f8 <dtb_init>

    pmm_init(); // init physical memory management
ffffffffc0200086:	5e0020ef          	jal	ra,ffffffffc0202666 <pmm_init>

    pic_init(); // init interrupt controller
ffffffffc020008a:	12b000ef          	jal	ra,ffffffffc02009b4 <pic_init>
    idt_init(); // init interrupt descriptor table
ffffffffc020008e:	129000ef          	jal	ra,ffffffffc02009b6 <idt_init>

    vmm_init(); // init virtual memory management
ffffffffc0200092:	0cf030ef          	jal	ra,ffffffffc0203960 <vmm_init>
    sched_init();
ffffffffc0200096:	024050ef          	jal	ra,ffffffffc02050ba <sched_init>
    proc_init(); // init process table
ffffffffc020009a:	501040ef          	jal	ra,ffffffffc0204d9a <proc_init>

    clock_init();  // init clock interrupt
ffffffffc020009e:	4a0000ef          	jal	ra,ffffffffc020053e <clock_init>
    intr_enable(); // enable irq interrupt
ffffffffc02000a2:	107000ef          	jal	ra,ffffffffc02009a8 <intr_enable>

    cpu_idle(); // run idle process
ffffffffc02000a6:	68d040ef          	jal	ra,ffffffffc0204f32 <cpu_idle>

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
ffffffffc02000c0:	00005517          	auipc	a0,0x5
ffffffffc02000c4:	7b850513          	addi	a0,a0,1976 # ffffffffc0205878 <etext+0x2a>
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
ffffffffc02000d6:	000c2b97          	auipc	s7,0xc2
ffffffffc02000da:	74ab8b93          	addi	s7,s7,1866 # ffffffffc02c2820 <buf>
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
ffffffffc0200132:	000c2517          	auipc	a0,0xc2
ffffffffc0200136:	6ee50513          	addi	a0,a0,1774 # ffffffffc02c2820 <buf>
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
ffffffffc020018c:	274050ef          	jal	ra,ffffffffc0205400 <vprintfmt>
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
ffffffffc020019a:	02810313          	addi	t1,sp,40 # ffffffffc020b028 <boot_page_table_sv39+0x28>
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
ffffffffc02001c2:	23e050ef          	jal	ra,ffffffffc0205400 <vprintfmt>
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
ffffffffc0200222:	00005517          	auipc	a0,0x5
ffffffffc0200226:	65e50513          	addi	a0,a0,1630 # ffffffffc0205880 <etext+0x32>
void print_kerninfo(void) {
ffffffffc020022a:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc020022c:	f6dff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  entry  0x%08x (virtual)\n", kern_init);
ffffffffc0200230:	00000597          	auipc	a1,0x0
ffffffffc0200234:	e1a58593          	addi	a1,a1,-486 # ffffffffc020004a <kern_init>
ffffffffc0200238:	00005517          	auipc	a0,0x5
ffffffffc020023c:	66850513          	addi	a0,a0,1640 # ffffffffc02058a0 <etext+0x52>
ffffffffc0200240:	f59ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  etext  0x%08x (virtual)\n", etext);
ffffffffc0200244:	00005597          	auipc	a1,0x5
ffffffffc0200248:	60a58593          	addi	a1,a1,1546 # ffffffffc020584e <etext>
ffffffffc020024c:	00005517          	auipc	a0,0x5
ffffffffc0200250:	67450513          	addi	a0,a0,1652 # ffffffffc02058c0 <etext+0x72>
ffffffffc0200254:	f45ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  edata  0x%08x (virtual)\n", edata);
ffffffffc0200258:	000c2597          	auipc	a1,0xc2
ffffffffc020025c:	5c858593          	addi	a1,a1,1480 # ffffffffc02c2820 <buf>
ffffffffc0200260:	00005517          	auipc	a0,0x5
ffffffffc0200264:	68050513          	addi	a0,a0,1664 # ffffffffc02058e0 <etext+0x92>
ffffffffc0200268:	f31ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  end    0x%08x (virtual)\n", end);
ffffffffc020026c:	000c7597          	auipc	a1,0xc7
ffffffffc0200270:	a9c58593          	addi	a1,a1,-1380 # ffffffffc02c6d08 <end>
ffffffffc0200274:	00005517          	auipc	a0,0x5
ffffffffc0200278:	68c50513          	addi	a0,a0,1676 # ffffffffc0205900 <etext+0xb2>
ffffffffc020027c:	f1dff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc0200280:	000c7597          	auipc	a1,0xc7
ffffffffc0200284:	e8758593          	addi	a1,a1,-377 # ffffffffc02c7107 <end+0x3ff>
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
ffffffffc02002a2:	00005517          	auipc	a0,0x5
ffffffffc02002a6:	67e50513          	addi	a0,a0,1662 # ffffffffc0205920 <etext+0xd2>
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
ffffffffc02002b0:	00005617          	auipc	a2,0x5
ffffffffc02002b4:	6a060613          	addi	a2,a2,1696 # ffffffffc0205950 <etext+0x102>
ffffffffc02002b8:	04d00593          	li	a1,77
ffffffffc02002bc:	00005517          	auipc	a0,0x5
ffffffffc02002c0:	6ac50513          	addi	a0,a0,1708 # ffffffffc0205968 <etext+0x11a>
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
ffffffffc02002cc:	00005617          	auipc	a2,0x5
ffffffffc02002d0:	6b460613          	addi	a2,a2,1716 # ffffffffc0205980 <etext+0x132>
ffffffffc02002d4:	00005597          	auipc	a1,0x5
ffffffffc02002d8:	6cc58593          	addi	a1,a1,1740 # ffffffffc02059a0 <etext+0x152>
ffffffffc02002dc:	00005517          	auipc	a0,0x5
ffffffffc02002e0:	6cc50513          	addi	a0,a0,1740 # ffffffffc02059a8 <etext+0x15a>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002e4:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02002e6:	eb3ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
ffffffffc02002ea:	00005617          	auipc	a2,0x5
ffffffffc02002ee:	6ce60613          	addi	a2,a2,1742 # ffffffffc02059b8 <etext+0x16a>
ffffffffc02002f2:	00005597          	auipc	a1,0x5
ffffffffc02002f6:	6ee58593          	addi	a1,a1,1774 # ffffffffc02059e0 <etext+0x192>
ffffffffc02002fa:	00005517          	auipc	a0,0x5
ffffffffc02002fe:	6ae50513          	addi	a0,a0,1710 # ffffffffc02059a8 <etext+0x15a>
ffffffffc0200302:	e97ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
ffffffffc0200306:	00005617          	auipc	a2,0x5
ffffffffc020030a:	6ea60613          	addi	a2,a2,1770 # ffffffffc02059f0 <etext+0x1a2>
ffffffffc020030e:	00005597          	auipc	a1,0x5
ffffffffc0200312:	70258593          	addi	a1,a1,1794 # ffffffffc0205a10 <etext+0x1c2>
ffffffffc0200316:	00005517          	auipc	a0,0x5
ffffffffc020031a:	69250513          	addi	a0,a0,1682 # ffffffffc02059a8 <etext+0x15a>
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
ffffffffc0200350:	00005517          	auipc	a0,0x5
ffffffffc0200354:	6d050513          	addi	a0,a0,1744 # ffffffffc0205a20 <etext+0x1d2>
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
ffffffffc0200372:	00005517          	auipc	a0,0x5
ffffffffc0200376:	6d650513          	addi	a0,a0,1750 # ffffffffc0205a48 <etext+0x1fa>
ffffffffc020037a:	e1fff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    if (tf != NULL) {
ffffffffc020037e:	000b8563          	beqz	s7,ffffffffc0200388 <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc0200382:	855e                	mv	a0,s7
ffffffffc0200384:	01b000ef          	jal	ra,ffffffffc0200b9e <print_trapframe>
ffffffffc0200388:	00005c17          	auipc	s8,0x5
ffffffffc020038c:	730c0c13          	addi	s8,s8,1840 # ffffffffc0205ab8 <commands>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc0200390:	00005917          	auipc	s2,0x5
ffffffffc0200394:	6e090913          	addi	s2,s2,1760 # ffffffffc0205a70 <etext+0x222>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200398:	00005497          	auipc	s1,0x5
ffffffffc020039c:	6e048493          	addi	s1,s1,1760 # ffffffffc0205a78 <etext+0x22a>
        if (argc == MAXARGS - 1) {
ffffffffc02003a0:	49bd                	li	s3,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc02003a2:	00005b17          	auipc	s6,0x5
ffffffffc02003a6:	6deb0b13          	addi	s6,s6,1758 # ffffffffc0205a80 <etext+0x232>
        argv[argc ++] = buf;
ffffffffc02003aa:	00005a17          	auipc	s4,0x5
ffffffffc02003ae:	5f6a0a13          	addi	s4,s4,1526 # ffffffffc02059a0 <etext+0x152>
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
ffffffffc02003cc:	00005d17          	auipc	s10,0x5
ffffffffc02003d0:	6ecd0d13          	addi	s10,s10,1772 # ffffffffc0205ab8 <commands>
        argv[argc ++] = buf;
ffffffffc02003d4:	8552                	mv	a0,s4
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02003d6:	4401                	li	s0,0
ffffffffc02003d8:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02003da:	3f0050ef          	jal	ra,ffffffffc02057ca <strcmp>
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
ffffffffc02003ee:	3dc050ef          	jal	ra,ffffffffc02057ca <strcmp>
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
ffffffffc020042c:	3e2050ef          	jal	ra,ffffffffc020580e <strchr>
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
ffffffffc020046a:	3a4050ef          	jal	ra,ffffffffc020580e <strchr>
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
ffffffffc0200484:	00005517          	auipc	a0,0x5
ffffffffc0200488:	61c50513          	addi	a0,a0,1564 # ffffffffc0205aa0 <etext+0x252>
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
ffffffffc0200492:	000c6317          	auipc	t1,0xc6
ffffffffc0200496:	7e630313          	addi	t1,t1,2022 # ffffffffc02c6c78 <is_panic>
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
ffffffffc02004c0:	00005517          	auipc	a0,0x5
ffffffffc02004c4:	64050513          	addi	a0,a0,1600 # ffffffffc0205b00 <commands+0x48>
    va_start(ap, fmt);
ffffffffc02004c8:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02004ca:	ccfff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    vcprintf(fmt, ap);
ffffffffc02004ce:	65a2                	ld	a1,8(sp)
ffffffffc02004d0:	8522                	mv	a0,s0
ffffffffc02004d2:	ca7ff0ef          	jal	ra,ffffffffc0200178 <vcprintf>
    cprintf("\n");
ffffffffc02004d6:	00006517          	auipc	a0,0x6
ffffffffc02004da:	73250513          	addi	a0,a0,1842 # ffffffffc0206c08 <default_pmm_manager+0x578>
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
ffffffffc020050a:	00005517          	auipc	a0,0x5
ffffffffc020050e:	61650513          	addi	a0,a0,1558 # ffffffffc0205b20 <commands+0x68>
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
ffffffffc020052a:	00006517          	auipc	a0,0x6
ffffffffc020052e:	6de50513          	addi	a0,a0,1758 # ffffffffc0206c08 <default_pmm_manager+0x578>
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
ffffffffc020054c:	6a078793          	addi	a5,a5,1696 # 186a0 <_binary_obj___user_matrix_out_size+0xbf80>
ffffffffc0200550:	953e                	add	a0,a0,a5
	SBI_CALL_1(SBI_SET_TIMER, stime_value);
ffffffffc0200552:	4581                	li	a1,0
ffffffffc0200554:	4601                	li	a2,0
ffffffffc0200556:	4881                	li	a7,0
ffffffffc0200558:	00000073          	ecall
    cprintf("++ setup timer interrupts\n");
ffffffffc020055c:	00005517          	auipc	a0,0x5
ffffffffc0200560:	5e450513          	addi	a0,a0,1508 # ffffffffc0205b40 <commands+0x88>
    ticks = 0;
ffffffffc0200564:	000c6797          	auipc	a5,0xc6
ffffffffc0200568:	7007be23          	sd	zero,1820(a5) # ffffffffc02c6c80 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc020056c:	b135                	j	ffffffffc0200198 <cprintf>

ffffffffc020056e <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc020056e:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200572:	67e1                	lui	a5,0x18
ffffffffc0200574:	6a078793          	addi	a5,a5,1696 # 186a0 <_binary_obj___user_matrix_out_size+0xbf80>
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
#include <assert.h>
#include <atomic.h>

static inline bool __intr_save(void)
{
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0200588:	100027f3          	csrr	a5,sstatus
ffffffffc020058c:	8b89                	andi	a5,a5,2
	SBI_CALL_1(SBI_CONSOLE_PUTCHAR, ch);
ffffffffc020058e:	0ff57513          	zext.b	a0,a0
ffffffffc0200592:	e799                	bnez	a5,ffffffffc02005a0 <cons_putc+0x18>
ffffffffc0200594:	4581                	li	a1,0
ffffffffc0200596:	4601                	li	a2,0
ffffffffc0200598:	4885                	li	a7,1
ffffffffc020059a:	00000073          	ecall
    return 0;
}

static inline void __intr_restore(bool flag)
{
    if (flag)
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
    {
        intr_enable();
ffffffffc02005ba:	a6fd                	j	ffffffffc02009a8 <intr_enable>

ffffffffc02005bc <cons_getc>:
    if (read_csr(sstatus) & SSTATUS_SIE)
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
ffffffffc02005fa:	00005517          	auipc	a0,0x5
ffffffffc02005fe:	56650513          	addi	a0,a0,1382 # ffffffffc0205b60 <commands+0xa8>
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
ffffffffc0200620:	0000c597          	auipc	a1,0xc
ffffffffc0200624:	9e05b583          	ld	a1,-1568(a1) # ffffffffc020c000 <boot_hartid>
ffffffffc0200628:	00005517          	auipc	a0,0x5
ffffffffc020062c:	54850513          	addi	a0,a0,1352 # ffffffffc0205b70 <commands+0xb8>
ffffffffc0200630:	b69ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc0200634:	0000c417          	auipc	s0,0xc
ffffffffc0200638:	9d440413          	addi	s0,s0,-1580 # ffffffffc020c008 <boot_dtb>
ffffffffc020063c:	600c                	ld	a1,0(s0)
ffffffffc020063e:	00005517          	auipc	a0,0x5
ffffffffc0200642:	54250513          	addi	a0,a0,1346 # ffffffffc0205b80 <commands+0xc8>
ffffffffc0200646:	b53ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc020064a:	00043a03          	ld	s4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc020064e:	00005517          	auipc	a0,0x5
ffffffffc0200652:	54a50513          	addi	a0,a0,1354 # ffffffffc0205b98 <commands+0xe0>
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
ffffffffc0200696:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <end+0xfe191e5>
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
ffffffffc0200708:	00005917          	auipc	s2,0x5
ffffffffc020070c:	4e090913          	addi	s2,s2,1248 # ffffffffc0205be8 <commands+0x130>
ffffffffc0200710:	49bd                	li	s3,15
        switch (token) {
ffffffffc0200712:	4d91                	li	s11,4
ffffffffc0200714:	4d05                	li	s10,1
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200716:	00005497          	auipc	s1,0x5
ffffffffc020071a:	4ca48493          	addi	s1,s1,1226 # ffffffffc0205be0 <commands+0x128>
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
ffffffffc020076a:	00005517          	auipc	a0,0x5
ffffffffc020076e:	4f650513          	addi	a0,a0,1270 # ffffffffc0205c60 <commands+0x1a8>
ffffffffc0200772:	a27ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc0200776:	00005517          	auipc	a0,0x5
ffffffffc020077a:	52250513          	addi	a0,a0,1314 # ffffffffc0205c98 <commands+0x1e0>
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
ffffffffc02007b6:	00005517          	auipc	a0,0x5
ffffffffc02007ba:	40250513          	addi	a0,a0,1026 # ffffffffc0205bb8 <commands+0x100>
}
ffffffffc02007be:	6109                	addi	sp,sp,128
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02007c0:	bae1                	j	ffffffffc0200198 <cprintf>
                int name_len = strlen(name);
ffffffffc02007c2:	8556                	mv	a0,s5
ffffffffc02007c4:	7bf040ef          	jal	ra,ffffffffc0205782 <strlen>
ffffffffc02007c8:	8a2a                	mv	s4,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02007ca:	4619                	li	a2,6
ffffffffc02007cc:	85a6                	mv	a1,s1
ffffffffc02007ce:	8556                	mv	a0,s5
                int name_len = strlen(name);
ffffffffc02007d0:	2a01                	sext.w	s4,s4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02007d2:	016050ef          	jal	ra,ffffffffc02057e8 <strncmp>
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
ffffffffc0200868:	763040ef          	jal	ra,ffffffffc02057ca <strcmp>
ffffffffc020086c:	66a2                	ld	a3,8(sp)
ffffffffc020086e:	f94d                	bnez	a0,ffffffffc0200820 <dtb_init+0x228>
ffffffffc0200870:	fb59f8e3          	bgeu	s3,s5,ffffffffc0200820 <dtb_init+0x228>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc0200874:	00ca3783          	ld	a5,12(s4)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc0200878:	014a3703          	ld	a4,20(s4)
        cprintf("Physical Memory from DTB:\n");
ffffffffc020087c:	00005517          	auipc	a0,0x5
ffffffffc0200880:	37450513          	addi	a0,a0,884 # ffffffffc0205bf0 <commands+0x138>
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
ffffffffc020094a:	00005517          	auipc	a0,0x5
ffffffffc020094e:	2c650513          	addi	a0,a0,710 # ffffffffc0205c10 <commands+0x158>
ffffffffc0200952:	847ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc0200956:	014b5613          	srli	a2,s6,0x14
ffffffffc020095a:	85da                	mv	a1,s6
ffffffffc020095c:	00005517          	auipc	a0,0x5
ffffffffc0200960:	2cc50513          	addi	a0,a0,716 # ffffffffc0205c28 <commands+0x170>
ffffffffc0200964:	835ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc0200968:	008b05b3          	add	a1,s6,s0
ffffffffc020096c:	15fd                	addi	a1,a1,-1
ffffffffc020096e:	00005517          	auipc	a0,0x5
ffffffffc0200972:	2da50513          	addi	a0,a0,730 # ffffffffc0205c48 <commands+0x190>
ffffffffc0200976:	823ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("DTB init completed\n");
ffffffffc020097a:	00005517          	auipc	a0,0x5
ffffffffc020097e:	31e50513          	addi	a0,a0,798 # ffffffffc0205c98 <commands+0x1e0>
        memory_base = mem_base;
ffffffffc0200982:	000c6797          	auipc	a5,0xc6
ffffffffc0200986:	3087b323          	sd	s0,774(a5) # ffffffffc02c6c88 <memory_base>
        memory_size = mem_size;
ffffffffc020098a:	000c6797          	auipc	a5,0xc6
ffffffffc020098e:	3167b323          	sd	s6,774(a5) # ffffffffc02c6c90 <memory_size>
    cprintf("DTB init completed\n");
ffffffffc0200992:	b3f5                	j	ffffffffc020077e <dtb_init+0x186>

ffffffffc0200994 <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc0200994:	000c6517          	auipc	a0,0xc6
ffffffffc0200998:	2f453503          	ld	a0,756(a0) # ffffffffc02c6c88 <memory_base>
ffffffffc020099c:	8082                	ret

ffffffffc020099e <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
}
ffffffffc020099e:	000c6517          	auipc	a0,0xc6
ffffffffc02009a2:	2f253503          	ld	a0,754(a0) # ffffffffc02c6c90 <memory_size>
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
ffffffffc02009be:	48278793          	addi	a5,a5,1154 # ffffffffc0200e3c <__alltraps>
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
ffffffffc02009d8:	00005517          	auipc	a0,0x5
ffffffffc02009dc:	2d850513          	addi	a0,a0,728 # ffffffffc0205cb0 <commands+0x1f8>
{
ffffffffc02009e0:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc02009e2:	fb6ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc02009e6:	640c                	ld	a1,8(s0)
ffffffffc02009e8:	00005517          	auipc	a0,0x5
ffffffffc02009ec:	2e050513          	addi	a0,a0,736 # ffffffffc0205cc8 <commands+0x210>
ffffffffc02009f0:	fa8ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc02009f4:	680c                	ld	a1,16(s0)
ffffffffc02009f6:	00005517          	auipc	a0,0x5
ffffffffc02009fa:	2ea50513          	addi	a0,a0,746 # ffffffffc0205ce0 <commands+0x228>
ffffffffc02009fe:	f9aff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc0200a02:	6c0c                	ld	a1,24(s0)
ffffffffc0200a04:	00005517          	auipc	a0,0x5
ffffffffc0200a08:	2f450513          	addi	a0,a0,756 # ffffffffc0205cf8 <commands+0x240>
ffffffffc0200a0c:	f8cff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc0200a10:	700c                	ld	a1,32(s0)
ffffffffc0200a12:	00005517          	auipc	a0,0x5
ffffffffc0200a16:	2fe50513          	addi	a0,a0,766 # ffffffffc0205d10 <commands+0x258>
ffffffffc0200a1a:	f7eff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc0200a1e:	740c                	ld	a1,40(s0)
ffffffffc0200a20:	00005517          	auipc	a0,0x5
ffffffffc0200a24:	30850513          	addi	a0,a0,776 # ffffffffc0205d28 <commands+0x270>
ffffffffc0200a28:	f70ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc0200a2c:	780c                	ld	a1,48(s0)
ffffffffc0200a2e:	00005517          	auipc	a0,0x5
ffffffffc0200a32:	31250513          	addi	a0,a0,786 # ffffffffc0205d40 <commands+0x288>
ffffffffc0200a36:	f62ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc0200a3a:	7c0c                	ld	a1,56(s0)
ffffffffc0200a3c:	00005517          	auipc	a0,0x5
ffffffffc0200a40:	31c50513          	addi	a0,a0,796 # ffffffffc0205d58 <commands+0x2a0>
ffffffffc0200a44:	f54ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc0200a48:	602c                	ld	a1,64(s0)
ffffffffc0200a4a:	00005517          	auipc	a0,0x5
ffffffffc0200a4e:	32650513          	addi	a0,a0,806 # ffffffffc0205d70 <commands+0x2b8>
ffffffffc0200a52:	f46ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc0200a56:	642c                	ld	a1,72(s0)
ffffffffc0200a58:	00005517          	auipc	a0,0x5
ffffffffc0200a5c:	33050513          	addi	a0,a0,816 # ffffffffc0205d88 <commands+0x2d0>
ffffffffc0200a60:	f38ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc0200a64:	682c                	ld	a1,80(s0)
ffffffffc0200a66:	00005517          	auipc	a0,0x5
ffffffffc0200a6a:	33a50513          	addi	a0,a0,826 # ffffffffc0205da0 <commands+0x2e8>
ffffffffc0200a6e:	f2aff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc0200a72:	6c2c                	ld	a1,88(s0)
ffffffffc0200a74:	00005517          	auipc	a0,0x5
ffffffffc0200a78:	34450513          	addi	a0,a0,836 # ffffffffc0205db8 <commands+0x300>
ffffffffc0200a7c:	f1cff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc0200a80:	702c                	ld	a1,96(s0)
ffffffffc0200a82:	00005517          	auipc	a0,0x5
ffffffffc0200a86:	34e50513          	addi	a0,a0,846 # ffffffffc0205dd0 <commands+0x318>
ffffffffc0200a8a:	f0eff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc0200a8e:	742c                	ld	a1,104(s0)
ffffffffc0200a90:	00005517          	auipc	a0,0x5
ffffffffc0200a94:	35850513          	addi	a0,a0,856 # ffffffffc0205de8 <commands+0x330>
ffffffffc0200a98:	f00ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc0200a9c:	782c                	ld	a1,112(s0)
ffffffffc0200a9e:	00005517          	auipc	a0,0x5
ffffffffc0200aa2:	36250513          	addi	a0,a0,866 # ffffffffc0205e00 <commands+0x348>
ffffffffc0200aa6:	ef2ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200aaa:	7c2c                	ld	a1,120(s0)
ffffffffc0200aac:	00005517          	auipc	a0,0x5
ffffffffc0200ab0:	36c50513          	addi	a0,a0,876 # ffffffffc0205e18 <commands+0x360>
ffffffffc0200ab4:	ee4ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc0200ab8:	604c                	ld	a1,128(s0)
ffffffffc0200aba:	00005517          	auipc	a0,0x5
ffffffffc0200abe:	37650513          	addi	a0,a0,886 # ffffffffc0205e30 <commands+0x378>
ffffffffc0200ac2:	ed6ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200ac6:	644c                	ld	a1,136(s0)
ffffffffc0200ac8:	00005517          	auipc	a0,0x5
ffffffffc0200acc:	38050513          	addi	a0,a0,896 # ffffffffc0205e48 <commands+0x390>
ffffffffc0200ad0:	ec8ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200ad4:	684c                	ld	a1,144(s0)
ffffffffc0200ad6:	00005517          	auipc	a0,0x5
ffffffffc0200ada:	38a50513          	addi	a0,a0,906 # ffffffffc0205e60 <commands+0x3a8>
ffffffffc0200ade:	ebaff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc0200ae2:	6c4c                	ld	a1,152(s0)
ffffffffc0200ae4:	00005517          	auipc	a0,0x5
ffffffffc0200ae8:	39450513          	addi	a0,a0,916 # ffffffffc0205e78 <commands+0x3c0>
ffffffffc0200aec:	eacff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc0200af0:	704c                	ld	a1,160(s0)
ffffffffc0200af2:	00005517          	auipc	a0,0x5
ffffffffc0200af6:	39e50513          	addi	a0,a0,926 # ffffffffc0205e90 <commands+0x3d8>
ffffffffc0200afa:	e9eff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc0200afe:	744c                	ld	a1,168(s0)
ffffffffc0200b00:	00005517          	auipc	a0,0x5
ffffffffc0200b04:	3a850513          	addi	a0,a0,936 # ffffffffc0205ea8 <commands+0x3f0>
ffffffffc0200b08:	e90ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc0200b0c:	784c                	ld	a1,176(s0)
ffffffffc0200b0e:	00005517          	auipc	a0,0x5
ffffffffc0200b12:	3b250513          	addi	a0,a0,946 # ffffffffc0205ec0 <commands+0x408>
ffffffffc0200b16:	e82ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc0200b1a:	7c4c                	ld	a1,184(s0)
ffffffffc0200b1c:	00005517          	auipc	a0,0x5
ffffffffc0200b20:	3bc50513          	addi	a0,a0,956 # ffffffffc0205ed8 <commands+0x420>
ffffffffc0200b24:	e74ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc0200b28:	606c                	ld	a1,192(s0)
ffffffffc0200b2a:	00005517          	auipc	a0,0x5
ffffffffc0200b2e:	3c650513          	addi	a0,a0,966 # ffffffffc0205ef0 <commands+0x438>
ffffffffc0200b32:	e66ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc0200b36:	646c                	ld	a1,200(s0)
ffffffffc0200b38:	00005517          	auipc	a0,0x5
ffffffffc0200b3c:	3d050513          	addi	a0,a0,976 # ffffffffc0205f08 <commands+0x450>
ffffffffc0200b40:	e58ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc0200b44:	686c                	ld	a1,208(s0)
ffffffffc0200b46:	00005517          	auipc	a0,0x5
ffffffffc0200b4a:	3da50513          	addi	a0,a0,986 # ffffffffc0205f20 <commands+0x468>
ffffffffc0200b4e:	e4aff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc0200b52:	6c6c                	ld	a1,216(s0)
ffffffffc0200b54:	00005517          	auipc	a0,0x5
ffffffffc0200b58:	3e450513          	addi	a0,a0,996 # ffffffffc0205f38 <commands+0x480>
ffffffffc0200b5c:	e3cff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc0200b60:	706c                	ld	a1,224(s0)
ffffffffc0200b62:	00005517          	auipc	a0,0x5
ffffffffc0200b66:	3ee50513          	addi	a0,a0,1006 # ffffffffc0205f50 <commands+0x498>
ffffffffc0200b6a:	e2eff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc0200b6e:	746c                	ld	a1,232(s0)
ffffffffc0200b70:	00005517          	auipc	a0,0x5
ffffffffc0200b74:	3f850513          	addi	a0,a0,1016 # ffffffffc0205f68 <commands+0x4b0>
ffffffffc0200b78:	e20ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200b7c:	786c                	ld	a1,240(s0)
ffffffffc0200b7e:	00005517          	auipc	a0,0x5
ffffffffc0200b82:	40250513          	addi	a0,a0,1026 # ffffffffc0205f80 <commands+0x4c8>
ffffffffc0200b86:	e12ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200b8a:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200b8c:	6402                	ld	s0,0(sp)
ffffffffc0200b8e:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200b90:	00005517          	auipc	a0,0x5
ffffffffc0200b94:	40850513          	addi	a0,a0,1032 # ffffffffc0205f98 <commands+0x4e0>
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
ffffffffc0200ba6:	00005517          	auipc	a0,0x5
ffffffffc0200baa:	40a50513          	addi	a0,a0,1034 # ffffffffc0205fb0 <commands+0x4f8>
{
ffffffffc0200bae:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200bb0:	de8ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200bb4:	8522                	mv	a0,s0
ffffffffc0200bb6:	e1bff0ef          	jal	ra,ffffffffc02009d0 <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc0200bba:	10043583          	ld	a1,256(s0)
ffffffffc0200bbe:	00005517          	auipc	a0,0x5
ffffffffc0200bc2:	40a50513          	addi	a0,a0,1034 # ffffffffc0205fc8 <commands+0x510>
ffffffffc0200bc6:	dd2ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200bca:	10843583          	ld	a1,264(s0)
ffffffffc0200bce:	00005517          	auipc	a0,0x5
ffffffffc0200bd2:	41250513          	addi	a0,a0,1042 # ffffffffc0205fe0 <commands+0x528>
ffffffffc0200bd6:	dc2ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  tval 0x%08x\n", tf->tval);
ffffffffc0200bda:	11043583          	ld	a1,272(s0)
ffffffffc0200bde:	00005517          	auipc	a0,0x5
ffffffffc0200be2:	41a50513          	addi	a0,a0,1050 # ffffffffc0205ff8 <commands+0x540>
ffffffffc0200be6:	db2ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200bea:	11843583          	ld	a1,280(s0)
}
ffffffffc0200bee:	6402                	ld	s0,0(sp)
ffffffffc0200bf0:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200bf2:	00005517          	auipc	a0,0x5
ffffffffc0200bf6:	41650513          	addi	a0,a0,1046 # ffffffffc0206008 <commands+0x550>
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
ffffffffc0200c0a:	08f76363          	bltu	a4,a5,ffffffffc0200c90 <interrupt_handler+0x90>
ffffffffc0200c0e:	00005717          	auipc	a4,0x5
ffffffffc0200c12:	4c270713          	addi	a4,a4,1218 # ffffffffc02060d0 <commands+0x618>
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
ffffffffc0200c20:	00005517          	auipc	a0,0x5
ffffffffc0200c24:	46050513          	addi	a0,a0,1120 # ffffffffc0206080 <commands+0x5c8>
ffffffffc0200c28:	d70ff06f          	j	ffffffffc0200198 <cprintf>
        cprintf("Hypervisor software interrupt\n");
ffffffffc0200c2c:	00005517          	auipc	a0,0x5
ffffffffc0200c30:	43450513          	addi	a0,a0,1076 # ffffffffc0206060 <commands+0x5a8>
ffffffffc0200c34:	d64ff06f          	j	ffffffffc0200198 <cprintf>
        cprintf("User software interrupt\n");
ffffffffc0200c38:	00005517          	auipc	a0,0x5
ffffffffc0200c3c:	3e850513          	addi	a0,a0,1000 # ffffffffc0206020 <commands+0x568>
ffffffffc0200c40:	d58ff06f          	j	ffffffffc0200198 <cprintf>
        cprintf("Supervisor software interrupt\n");
ffffffffc0200c44:	00005517          	auipc	a0,0x5
ffffffffc0200c48:	3fc50513          	addi	a0,a0,1020 # ffffffffc0206040 <commands+0x588>
ffffffffc0200c4c:	d4cff06f          	j	ffffffffc0200198 <cprintf>
{
ffffffffc0200c50:	1141                	addi	sp,sp,-16
ffffffffc0200c52:	e406                	sd	ra,8(sp)

        // lab6: YOUR CODE  (update LAB3 steps)
        //  在时钟中断时调用调度器的 sched_class_proc_tick 函数
    
        /* (1) 设置下次时钟中断 */
        clock_set_next_event();
ffffffffc0200c54:	91bff0ef          	jal	ra,ffffffffc020056e <clock_set_next_event>
    
        /* (2) 计数器（ticks）加一 */
        ticks++;
ffffffffc0200c58:	000c6797          	auipc	a5,0xc6
ffffffffc0200c5c:	02878793          	addi	a5,a5,40 # ffffffffc02c6c80 <ticks>
ffffffffc0200c60:	6398                	ld	a4,0(a5)
ffffffffc0200c62:	0705                	addi	a4,a4,1
ffffffffc0200c64:	e398                	sd	a4,0(a5)
    
        /* (3) 当计数器加到100的时候，输出一个`100ticks`表示触发了100次时钟中断，同时打印次数加一 */
        static int print_count = 0;
    
        if (ticks % TICK_NUM == 0) {
ffffffffc0200c66:	639c                	ld	a5,0(a5)
ffffffffc0200c68:	06400713          	li	a4,100
ffffffffc0200c6c:	02e7f7b3          	remu	a5,a5,a4
ffffffffc0200c70:	c785                	beqz	a5,ffffffffc0200c98 <interrupt_handler+0x98>
                    ;
            }
        }
        /* LAB6: 调用调度器的tick处理函数 */
        /* 注意：current是当前正在运行的进程 */
        if (current != NULL) {
ffffffffc0200c72:	000c6517          	auipc	a0,0xc6
ffffffffc0200c76:	06653503          	ld	a0,102(a0) # ffffffffc02c6cd8 <current>
ffffffffc0200c7a:	cd01                	beqz	a0,ffffffffc0200c92 <interrupt_handler+0x92>
        break;
    default:
        print_trapframe(tf);
        break;
    }
}
ffffffffc0200c7c:	60a2                	ld	ra,8(sp)
ffffffffc0200c7e:	0141                	addi	sp,sp,16
            sched_class_proc_tick(current);
ffffffffc0200c80:	4120406f          	j	ffffffffc0205092 <sched_class_proc_tick>
        cprintf("Supervisor external interrupt\n");
ffffffffc0200c84:	00005517          	auipc	a0,0x5
ffffffffc0200c88:	42c50513          	addi	a0,a0,1068 # ffffffffc02060b0 <commands+0x5f8>
ffffffffc0200c8c:	d0cff06f          	j	ffffffffc0200198 <cprintf>
        print_trapframe(tf);
ffffffffc0200c90:	b739                	j	ffffffffc0200b9e <print_trapframe>
}
ffffffffc0200c92:	60a2                	ld	ra,8(sp)
ffffffffc0200c94:	0141                	addi	sp,sp,16
ffffffffc0200c96:	8082                	ret
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200c98:	06400593          	li	a1,100
ffffffffc0200c9c:	00005517          	auipc	a0,0x5
ffffffffc0200ca0:	40450513          	addi	a0,a0,1028 # ffffffffc02060a0 <commands+0x5e8>
ffffffffc0200ca4:	cf4ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
            print_count++;
ffffffffc0200ca8:	000c6717          	auipc	a4,0xc6
ffffffffc0200cac:	ff070713          	addi	a4,a4,-16 # ffffffffc02c6c98 <print_count.0>
ffffffffc0200cb0:	431c                	lw	a5,0(a4)
            if (print_count >= 10) {
ffffffffc0200cb2:	46a5                	li	a3,9
            print_count++;
ffffffffc0200cb4:	0017861b          	addiw	a2,a5,1
ffffffffc0200cb8:	c310                	sw	a2,0(a4)
            if (print_count >= 10) {
ffffffffc0200cba:	fac6dce3          	bge	a3,a2,ffffffffc0200c72 <interrupt_handler+0x72>
	SBI_CALL_0(SBI_SHUTDOWN);
ffffffffc0200cbe:	4501                	li	a0,0
ffffffffc0200cc0:	4581                	li	a1,0
ffffffffc0200cc2:	4601                	li	a2,0
ffffffffc0200cc4:	48a1                	li	a7,8
ffffffffc0200cc6:	00000073          	ecall
                while (1)
ffffffffc0200cca:	a001                	j	ffffffffc0200cca <interrupt_handler+0xca>

ffffffffc0200ccc <exception_handler>:
void kernel_execve_ret(struct trapframe *tf, uintptr_t kstacktop);
void exception_handler(struct trapframe *tf)
{
    int ret;
    switch (tf->cause)
ffffffffc0200ccc:	11853783          	ld	a5,280(a0)
{
ffffffffc0200cd0:	1141                	addi	sp,sp,-16
ffffffffc0200cd2:	e022                	sd	s0,0(sp)
ffffffffc0200cd4:	e406                	sd	ra,8(sp)
ffffffffc0200cd6:	473d                	li	a4,15
ffffffffc0200cd8:	842a                	mv	s0,a0
ffffffffc0200cda:	0af76b63          	bltu	a4,a5,ffffffffc0200d90 <exception_handler+0xc4>
ffffffffc0200cde:	00005717          	auipc	a4,0x5
ffffffffc0200ce2:	5b270713          	addi	a4,a4,1458 # ffffffffc0206290 <commands+0x7d8>
ffffffffc0200ce6:	078a                	slli	a5,a5,0x2
ffffffffc0200ce8:	97ba                	add	a5,a5,a4
ffffffffc0200cea:	439c                	lw	a5,0(a5)
ffffffffc0200cec:	97ba                	add	a5,a5,a4
ffffffffc0200cee:	8782                	jr	a5
        // cprintf("Environment call from U-mode\n");
        tf->epc += 4;
        syscall();
        break;
    case CAUSE_SUPERVISOR_ECALL:
        cprintf("Environment call from S-mode\n");
ffffffffc0200cf0:	00005517          	auipc	a0,0x5
ffffffffc0200cf4:	4f850513          	addi	a0,a0,1272 # ffffffffc02061e8 <commands+0x730>
ffffffffc0200cf8:	ca0ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
        tf->epc += 4;
ffffffffc0200cfc:	10843783          	ld	a5,264(s0)
        break;
    default:
        print_trapframe(tf);
        break;
    }
}
ffffffffc0200d00:	60a2                	ld	ra,8(sp)
        tf->epc += 4;
ffffffffc0200d02:	0791                	addi	a5,a5,4
ffffffffc0200d04:	10f43423          	sd	a5,264(s0)
}
ffffffffc0200d08:	6402                	ld	s0,0(sp)
ffffffffc0200d0a:	0141                	addi	sp,sp,16
        syscall();
ffffffffc0200d0c:	5f00406f          	j	ffffffffc02052fc <syscall>
        cprintf("Environment call from H-mode\n");
ffffffffc0200d10:	00005517          	auipc	a0,0x5
ffffffffc0200d14:	4f850513          	addi	a0,a0,1272 # ffffffffc0206208 <commands+0x750>
}
ffffffffc0200d18:	6402                	ld	s0,0(sp)
ffffffffc0200d1a:	60a2                	ld	ra,8(sp)
ffffffffc0200d1c:	0141                	addi	sp,sp,16
        cprintf("Instruction access fault\n");
ffffffffc0200d1e:	c7aff06f          	j	ffffffffc0200198 <cprintf>
        cprintf("Environment call from M-mode\n");
ffffffffc0200d22:	00005517          	auipc	a0,0x5
ffffffffc0200d26:	50650513          	addi	a0,a0,1286 # ffffffffc0206228 <commands+0x770>
ffffffffc0200d2a:	b7fd                	j	ffffffffc0200d18 <exception_handler+0x4c>
        cprintf("Instruction page fault\n");
ffffffffc0200d2c:	00005517          	auipc	a0,0x5
ffffffffc0200d30:	51c50513          	addi	a0,a0,1308 # ffffffffc0206248 <commands+0x790>
ffffffffc0200d34:	b7d5                	j	ffffffffc0200d18 <exception_handler+0x4c>
        cprintf("Load page fault\n");
ffffffffc0200d36:	00005517          	auipc	a0,0x5
ffffffffc0200d3a:	52a50513          	addi	a0,a0,1322 # ffffffffc0206260 <commands+0x7a8>
ffffffffc0200d3e:	bfe9                	j	ffffffffc0200d18 <exception_handler+0x4c>
        cprintf("Store/AMO page fault\n");
ffffffffc0200d40:	00005517          	auipc	a0,0x5
ffffffffc0200d44:	53850513          	addi	a0,a0,1336 # ffffffffc0206278 <commands+0x7c0>
ffffffffc0200d48:	bfc1                	j	ffffffffc0200d18 <exception_handler+0x4c>
        cprintf("Instruction address misaligned\n");
ffffffffc0200d4a:	00005517          	auipc	a0,0x5
ffffffffc0200d4e:	3b650513          	addi	a0,a0,950 # ffffffffc0206100 <commands+0x648>
ffffffffc0200d52:	b7d9                	j	ffffffffc0200d18 <exception_handler+0x4c>
        cprintf("Instruction access fault\n");
ffffffffc0200d54:	00005517          	auipc	a0,0x5
ffffffffc0200d58:	3cc50513          	addi	a0,a0,972 # ffffffffc0206120 <commands+0x668>
ffffffffc0200d5c:	bf75                	j	ffffffffc0200d18 <exception_handler+0x4c>
        cprintf("Illegal instruction\n");
ffffffffc0200d5e:	00005517          	auipc	a0,0x5
ffffffffc0200d62:	3e250513          	addi	a0,a0,994 # ffffffffc0206140 <commands+0x688>
ffffffffc0200d66:	bf4d                	j	ffffffffc0200d18 <exception_handler+0x4c>
        cprintf("Breakpoint\n");
ffffffffc0200d68:	00005517          	auipc	a0,0x5
ffffffffc0200d6c:	3f050513          	addi	a0,a0,1008 # ffffffffc0206158 <commands+0x6a0>
ffffffffc0200d70:	b765                	j	ffffffffc0200d18 <exception_handler+0x4c>
        cprintf("Load address misaligned\n");
ffffffffc0200d72:	00005517          	auipc	a0,0x5
ffffffffc0200d76:	3f650513          	addi	a0,a0,1014 # ffffffffc0206168 <commands+0x6b0>
ffffffffc0200d7a:	bf79                	j	ffffffffc0200d18 <exception_handler+0x4c>
        cprintf("Load access fault\n");
ffffffffc0200d7c:	00005517          	auipc	a0,0x5
ffffffffc0200d80:	40c50513          	addi	a0,a0,1036 # ffffffffc0206188 <commands+0x6d0>
ffffffffc0200d84:	bf51                	j	ffffffffc0200d18 <exception_handler+0x4c>
        cprintf("Store/AMO access fault\n");
ffffffffc0200d86:	00005517          	auipc	a0,0x5
ffffffffc0200d8a:	44a50513          	addi	a0,a0,1098 # ffffffffc02061d0 <commands+0x718>
ffffffffc0200d8e:	b769                	j	ffffffffc0200d18 <exception_handler+0x4c>
        print_trapframe(tf);
ffffffffc0200d90:	8522                	mv	a0,s0
}
ffffffffc0200d92:	6402                	ld	s0,0(sp)
ffffffffc0200d94:	60a2                	ld	ra,8(sp)
ffffffffc0200d96:	0141                	addi	sp,sp,16
        print_trapframe(tf);
ffffffffc0200d98:	b519                	j	ffffffffc0200b9e <print_trapframe>
        panic("AMO address misaligned\n");
ffffffffc0200d9a:	00005617          	auipc	a2,0x5
ffffffffc0200d9e:	40660613          	addi	a2,a2,1030 # ffffffffc02061a0 <commands+0x6e8>
ffffffffc0200da2:	0d200593          	li	a1,210
ffffffffc0200da6:	00005517          	auipc	a0,0x5
ffffffffc0200daa:	41250513          	addi	a0,a0,1042 # ffffffffc02061b8 <commands+0x700>
ffffffffc0200dae:	ee4ff0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0200db2 <trap>:
 * trap - handles or dispatches an exception/interrupt. if and when trap() returns,
 * the code in kern/trap/trapentry.S restores the old CPU state saved in the
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void trap(struct trapframe *tf)
{
ffffffffc0200db2:	1101                	addi	sp,sp,-32
ffffffffc0200db4:	e822                	sd	s0,16(sp)
    // dispatch based on what type of trap occurred
    //    cputs("some trap");
    if (current == NULL)
ffffffffc0200db6:	000c6417          	auipc	s0,0xc6
ffffffffc0200dba:	f2240413          	addi	s0,s0,-222 # ffffffffc02c6cd8 <current>
ffffffffc0200dbe:	6018                	ld	a4,0(s0)
{
ffffffffc0200dc0:	ec06                	sd	ra,24(sp)
ffffffffc0200dc2:	e426                	sd	s1,8(sp)
ffffffffc0200dc4:	e04a                	sd	s2,0(sp)
    if ((intptr_t)tf->cause < 0)
ffffffffc0200dc6:	11853683          	ld	a3,280(a0)
    if (current == NULL)
ffffffffc0200dca:	cf1d                	beqz	a4,ffffffffc0200e08 <trap+0x56>
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200dcc:	10053483          	ld	s1,256(a0)
    {
        trap_dispatch(tf);
    }
    else
    {
        struct trapframe *otf = current->tf;
ffffffffc0200dd0:	0a073903          	ld	s2,160(a4)
        current->tf = tf;
ffffffffc0200dd4:	f348                	sd	a0,160(a4)
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200dd6:	1004f493          	andi	s1,s1,256
    if ((intptr_t)tf->cause < 0)
ffffffffc0200dda:	0206c463          	bltz	a3,ffffffffc0200e02 <trap+0x50>
        exception_handler(tf);
ffffffffc0200dde:	eefff0ef          	jal	ra,ffffffffc0200ccc <exception_handler>

        bool in_kernel = trap_in_kernel(tf);

        trap_dispatch(tf);

        current->tf = otf;
ffffffffc0200de2:	601c                	ld	a5,0(s0)
ffffffffc0200de4:	0b27b023          	sd	s2,160(a5)
        if (!in_kernel)
ffffffffc0200de8:	e499                	bnez	s1,ffffffffc0200df6 <trap+0x44>
        {
            if (current->flags & PF_EXITING)
ffffffffc0200dea:	0b07a703          	lw	a4,176(a5)
ffffffffc0200dee:	8b05                	andi	a4,a4,1
ffffffffc0200df0:	e329                	bnez	a4,ffffffffc0200e32 <trap+0x80>
            {
                do_exit(-E_KILLED);
            }
            if (current->need_resched)
ffffffffc0200df2:	6f9c                	ld	a5,24(a5)
ffffffffc0200df4:	eb85                	bnez	a5,ffffffffc0200e24 <trap+0x72>
            {
                schedule();
            }
        }
    }
}
ffffffffc0200df6:	60e2                	ld	ra,24(sp)
ffffffffc0200df8:	6442                	ld	s0,16(sp)
ffffffffc0200dfa:	64a2                	ld	s1,8(sp)
ffffffffc0200dfc:	6902                	ld	s2,0(sp)
ffffffffc0200dfe:	6105                	addi	sp,sp,32
ffffffffc0200e00:	8082                	ret
        interrupt_handler(tf);
ffffffffc0200e02:	dffff0ef          	jal	ra,ffffffffc0200c00 <interrupt_handler>
ffffffffc0200e06:	bff1                	j	ffffffffc0200de2 <trap+0x30>
    if ((intptr_t)tf->cause < 0)
ffffffffc0200e08:	0006c863          	bltz	a3,ffffffffc0200e18 <trap+0x66>
}
ffffffffc0200e0c:	6442                	ld	s0,16(sp)
ffffffffc0200e0e:	60e2                	ld	ra,24(sp)
ffffffffc0200e10:	64a2                	ld	s1,8(sp)
ffffffffc0200e12:	6902                	ld	s2,0(sp)
ffffffffc0200e14:	6105                	addi	sp,sp,32
        exception_handler(tf);
ffffffffc0200e16:	bd5d                	j	ffffffffc0200ccc <exception_handler>
}
ffffffffc0200e18:	6442                	ld	s0,16(sp)
ffffffffc0200e1a:	60e2                	ld	ra,24(sp)
ffffffffc0200e1c:	64a2                	ld	s1,8(sp)
ffffffffc0200e1e:	6902                	ld	s2,0(sp)
ffffffffc0200e20:	6105                	addi	sp,sp,32
        interrupt_handler(tf);
ffffffffc0200e22:	bbf9                	j	ffffffffc0200c00 <interrupt_handler>
}
ffffffffc0200e24:	6442                	ld	s0,16(sp)
ffffffffc0200e26:	60e2                	ld	ra,24(sp)
ffffffffc0200e28:	64a2                	ld	s1,8(sp)
ffffffffc0200e2a:	6902                	ld	s2,0(sp)
ffffffffc0200e2c:	6105                	addi	sp,sp,32
                schedule();
ffffffffc0200e2e:	3900406f          	j	ffffffffc02051be <schedule>
                do_exit(-E_KILLED);
ffffffffc0200e32:	555d                	li	a0,-9
ffffffffc0200e34:	4ae030ef          	jal	ra,ffffffffc02042e2 <do_exit>
            if (current->need_resched)
ffffffffc0200e38:	601c                	ld	a5,0(s0)
ffffffffc0200e3a:	bf65                	j	ffffffffc0200df2 <trap+0x40>

ffffffffc0200e3c <__alltraps>:
    LOAD x2, 2*REGBYTES(sp)
    .endm

    .globl __alltraps
__alltraps:
    SAVE_ALL
ffffffffc0200e3c:	14011173          	csrrw	sp,sscratch,sp
ffffffffc0200e40:	00011463          	bnez	sp,ffffffffc0200e48 <__alltraps+0xc>
ffffffffc0200e44:	14002173          	csrr	sp,sscratch
ffffffffc0200e48:	712d                	addi	sp,sp,-288
ffffffffc0200e4a:	e002                	sd	zero,0(sp)
ffffffffc0200e4c:	e406                	sd	ra,8(sp)
ffffffffc0200e4e:	ec0e                	sd	gp,24(sp)
ffffffffc0200e50:	f012                	sd	tp,32(sp)
ffffffffc0200e52:	f416                	sd	t0,40(sp)
ffffffffc0200e54:	f81a                	sd	t1,48(sp)
ffffffffc0200e56:	fc1e                	sd	t2,56(sp)
ffffffffc0200e58:	e0a2                	sd	s0,64(sp)
ffffffffc0200e5a:	e4a6                	sd	s1,72(sp)
ffffffffc0200e5c:	e8aa                	sd	a0,80(sp)
ffffffffc0200e5e:	ecae                	sd	a1,88(sp)
ffffffffc0200e60:	f0b2                	sd	a2,96(sp)
ffffffffc0200e62:	f4b6                	sd	a3,104(sp)
ffffffffc0200e64:	f8ba                	sd	a4,112(sp)
ffffffffc0200e66:	fcbe                	sd	a5,120(sp)
ffffffffc0200e68:	e142                	sd	a6,128(sp)
ffffffffc0200e6a:	e546                	sd	a7,136(sp)
ffffffffc0200e6c:	e94a                	sd	s2,144(sp)
ffffffffc0200e6e:	ed4e                	sd	s3,152(sp)
ffffffffc0200e70:	f152                	sd	s4,160(sp)
ffffffffc0200e72:	f556                	sd	s5,168(sp)
ffffffffc0200e74:	f95a                	sd	s6,176(sp)
ffffffffc0200e76:	fd5e                	sd	s7,184(sp)
ffffffffc0200e78:	e1e2                	sd	s8,192(sp)
ffffffffc0200e7a:	e5e6                	sd	s9,200(sp)
ffffffffc0200e7c:	e9ea                	sd	s10,208(sp)
ffffffffc0200e7e:	edee                	sd	s11,216(sp)
ffffffffc0200e80:	f1f2                	sd	t3,224(sp)
ffffffffc0200e82:	f5f6                	sd	t4,232(sp)
ffffffffc0200e84:	f9fa                	sd	t5,240(sp)
ffffffffc0200e86:	fdfe                	sd	t6,248(sp)
ffffffffc0200e88:	14001473          	csrrw	s0,sscratch,zero
ffffffffc0200e8c:	100024f3          	csrr	s1,sstatus
ffffffffc0200e90:	14102973          	csrr	s2,sepc
ffffffffc0200e94:	143029f3          	csrr	s3,stval
ffffffffc0200e98:	14202a73          	csrr	s4,scause
ffffffffc0200e9c:	e822                	sd	s0,16(sp)
ffffffffc0200e9e:	e226                	sd	s1,256(sp)
ffffffffc0200ea0:	e64a                	sd	s2,264(sp)
ffffffffc0200ea2:	ea4e                	sd	s3,272(sp)
ffffffffc0200ea4:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200ea6:	850a                	mv	a0,sp
    jal trap
ffffffffc0200ea8:	f0bff0ef          	jal	ra,ffffffffc0200db2 <trap>

ffffffffc0200eac <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200eac:	6492                	ld	s1,256(sp)
ffffffffc0200eae:	6932                	ld	s2,264(sp)
ffffffffc0200eb0:	1004f413          	andi	s0,s1,256
ffffffffc0200eb4:	e401                	bnez	s0,ffffffffc0200ebc <__trapret+0x10>
ffffffffc0200eb6:	1200                	addi	s0,sp,288
ffffffffc0200eb8:	14041073          	csrw	sscratch,s0
ffffffffc0200ebc:	10049073          	csrw	sstatus,s1
ffffffffc0200ec0:	14191073          	csrw	sepc,s2
ffffffffc0200ec4:	60a2                	ld	ra,8(sp)
ffffffffc0200ec6:	61e2                	ld	gp,24(sp)
ffffffffc0200ec8:	7202                	ld	tp,32(sp)
ffffffffc0200eca:	72a2                	ld	t0,40(sp)
ffffffffc0200ecc:	7342                	ld	t1,48(sp)
ffffffffc0200ece:	73e2                	ld	t2,56(sp)
ffffffffc0200ed0:	6406                	ld	s0,64(sp)
ffffffffc0200ed2:	64a6                	ld	s1,72(sp)
ffffffffc0200ed4:	6546                	ld	a0,80(sp)
ffffffffc0200ed6:	65e6                	ld	a1,88(sp)
ffffffffc0200ed8:	7606                	ld	a2,96(sp)
ffffffffc0200eda:	76a6                	ld	a3,104(sp)
ffffffffc0200edc:	7746                	ld	a4,112(sp)
ffffffffc0200ede:	77e6                	ld	a5,120(sp)
ffffffffc0200ee0:	680a                	ld	a6,128(sp)
ffffffffc0200ee2:	68aa                	ld	a7,136(sp)
ffffffffc0200ee4:	694a                	ld	s2,144(sp)
ffffffffc0200ee6:	69ea                	ld	s3,152(sp)
ffffffffc0200ee8:	7a0a                	ld	s4,160(sp)
ffffffffc0200eea:	7aaa                	ld	s5,168(sp)
ffffffffc0200eec:	7b4a                	ld	s6,176(sp)
ffffffffc0200eee:	7bea                	ld	s7,184(sp)
ffffffffc0200ef0:	6c0e                	ld	s8,192(sp)
ffffffffc0200ef2:	6cae                	ld	s9,200(sp)
ffffffffc0200ef4:	6d4e                	ld	s10,208(sp)
ffffffffc0200ef6:	6dee                	ld	s11,216(sp)
ffffffffc0200ef8:	7e0e                	ld	t3,224(sp)
ffffffffc0200efa:	7eae                	ld	t4,232(sp)
ffffffffc0200efc:	7f4e                	ld	t5,240(sp)
ffffffffc0200efe:	7fee                	ld	t6,248(sp)
ffffffffc0200f00:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
ffffffffc0200f02:	10200073          	sret

ffffffffc0200f06 <forkrets>:
 
    .globl forkrets
forkrets:
    # set stack to this new process's trapframe
    move sp, a0
ffffffffc0200f06:	812a                	mv	sp,a0
ffffffffc0200f08:	b755                	j	ffffffffc0200eac <__trapret>

ffffffffc0200f0a <default_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0200f0a:	000c2797          	auipc	a5,0xc2
ffffffffc0200f0e:	d1678793          	addi	a5,a5,-746 # ffffffffc02c2c20 <free_area>
ffffffffc0200f12:	e79c                	sd	a5,8(a5)
ffffffffc0200f14:	e39c                	sd	a5,0(a5)

static void
default_init(void)
{
    list_init(&free_list);
    nr_free = 0;
ffffffffc0200f16:	0007a823          	sw	zero,16(a5)
}
ffffffffc0200f1a:	8082                	ret

ffffffffc0200f1c <default_nr_free_pages>:

static size_t
default_nr_free_pages(void)
{
    return nr_free;
}
ffffffffc0200f1c:	000c2517          	auipc	a0,0xc2
ffffffffc0200f20:	d1456503          	lwu	a0,-748(a0) # ffffffffc02c2c30 <free_area+0x10>
ffffffffc0200f24:	8082                	ret

ffffffffc0200f26 <default_check>:

// LAB2: below code is used to check the first fit allocation algorithm (your EXERCISE 1)
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void)
{
ffffffffc0200f26:	715d                	addi	sp,sp,-80
ffffffffc0200f28:	e0a2                	sd	s0,64(sp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200f2a:	000c2417          	auipc	s0,0xc2
ffffffffc0200f2e:	cf640413          	addi	s0,s0,-778 # ffffffffc02c2c20 <free_area>
ffffffffc0200f32:	641c                	ld	a5,8(s0)
ffffffffc0200f34:	e486                	sd	ra,72(sp)
ffffffffc0200f36:	fc26                	sd	s1,56(sp)
ffffffffc0200f38:	f84a                	sd	s2,48(sp)
ffffffffc0200f3a:	f44e                	sd	s3,40(sp)
ffffffffc0200f3c:	f052                	sd	s4,32(sp)
ffffffffc0200f3e:	ec56                	sd	s5,24(sp)
ffffffffc0200f40:	e85a                	sd	s6,16(sp)
ffffffffc0200f42:	e45e                	sd	s7,8(sp)
ffffffffc0200f44:	e062                	sd	s8,0(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list)
ffffffffc0200f46:	2a878d63          	beq	a5,s0,ffffffffc0201200 <default_check+0x2da>
    int count = 0, total = 0;
ffffffffc0200f4a:	4481                	li	s1,0
ffffffffc0200f4c:	4901                	li	s2,0
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200f4e:	ff07b703          	ld	a4,-16(a5)
    {
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0200f52:	8b09                	andi	a4,a4,2
ffffffffc0200f54:	2a070a63          	beqz	a4,ffffffffc0201208 <default_check+0x2e2>
        count++, total += p->property;
ffffffffc0200f58:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200f5c:	679c                	ld	a5,8(a5)
ffffffffc0200f5e:	2905                	addiw	s2,s2,1
ffffffffc0200f60:	9cb9                	addw	s1,s1,a4
    while ((le = list_next(le)) != &free_list)
ffffffffc0200f62:	fe8796e3          	bne	a5,s0,ffffffffc0200f4e <default_check+0x28>
    }
    assert(total == nr_free_pages());
ffffffffc0200f66:	89a6                	mv	s3,s1
ffffffffc0200f68:	6df000ef          	jal	ra,ffffffffc0201e46 <nr_free_pages>
ffffffffc0200f6c:	6f351e63          	bne	a0,s3,ffffffffc0201668 <default_check+0x742>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200f70:	4505                	li	a0,1
ffffffffc0200f72:	657000ef          	jal	ra,ffffffffc0201dc8 <alloc_pages>
ffffffffc0200f76:	8aaa                	mv	s5,a0
ffffffffc0200f78:	42050863          	beqz	a0,ffffffffc02013a8 <default_check+0x482>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200f7c:	4505                	li	a0,1
ffffffffc0200f7e:	64b000ef          	jal	ra,ffffffffc0201dc8 <alloc_pages>
ffffffffc0200f82:	89aa                	mv	s3,a0
ffffffffc0200f84:	70050263          	beqz	a0,ffffffffc0201688 <default_check+0x762>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200f88:	4505                	li	a0,1
ffffffffc0200f8a:	63f000ef          	jal	ra,ffffffffc0201dc8 <alloc_pages>
ffffffffc0200f8e:	8a2a                	mv	s4,a0
ffffffffc0200f90:	48050c63          	beqz	a0,ffffffffc0201428 <default_check+0x502>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200f94:	293a8a63          	beq	s5,s3,ffffffffc0201228 <default_check+0x302>
ffffffffc0200f98:	28aa8863          	beq	s5,a0,ffffffffc0201228 <default_check+0x302>
ffffffffc0200f9c:	28a98663          	beq	s3,a0,ffffffffc0201228 <default_check+0x302>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200fa0:	000aa783          	lw	a5,0(s5)
ffffffffc0200fa4:	2a079263          	bnez	a5,ffffffffc0201248 <default_check+0x322>
ffffffffc0200fa8:	0009a783          	lw	a5,0(s3)
ffffffffc0200fac:	28079e63          	bnez	a5,ffffffffc0201248 <default_check+0x322>
ffffffffc0200fb0:	411c                	lw	a5,0(a0)
ffffffffc0200fb2:	28079b63          	bnez	a5,ffffffffc0201248 <default_check+0x322>
extern uint_t va_pa_offset;

static inline ppn_t
page2ppn(struct Page *page)
{
    return page - pages + nbase;
ffffffffc0200fb6:	000c6797          	auipc	a5,0xc6
ffffffffc0200fba:	d0a7b783          	ld	a5,-758(a5) # ffffffffc02c6cc0 <pages>
ffffffffc0200fbe:	40fa8733          	sub	a4,s5,a5
ffffffffc0200fc2:	00007617          	auipc	a2,0x7
ffffffffc0200fc6:	10663603          	ld	a2,262(a2) # ffffffffc02080c8 <nbase>
ffffffffc0200fca:	8719                	srai	a4,a4,0x6
ffffffffc0200fcc:	9732                	add	a4,a4,a2
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200fce:	000c6697          	auipc	a3,0xc6
ffffffffc0200fd2:	cea6b683          	ld	a3,-790(a3) # ffffffffc02c6cb8 <npage>
ffffffffc0200fd6:	06b2                	slli	a3,a3,0xc
}

static inline uintptr_t
page2pa(struct Page *page)
{
    return page2ppn(page) << PGSHIFT;
ffffffffc0200fd8:	0732                	slli	a4,a4,0xc
ffffffffc0200fda:	28d77763          	bgeu	a4,a3,ffffffffc0201268 <default_check+0x342>
    return page - pages + nbase;
ffffffffc0200fde:	40f98733          	sub	a4,s3,a5
ffffffffc0200fe2:	8719                	srai	a4,a4,0x6
ffffffffc0200fe4:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200fe6:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200fe8:	4cd77063          	bgeu	a4,a3,ffffffffc02014a8 <default_check+0x582>
    return page - pages + nbase;
ffffffffc0200fec:	40f507b3          	sub	a5,a0,a5
ffffffffc0200ff0:	8799                	srai	a5,a5,0x6
ffffffffc0200ff2:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200ff4:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200ff6:	30d7f963          	bgeu	a5,a3,ffffffffc0201308 <default_check+0x3e2>
    assert(alloc_page() == NULL);
ffffffffc0200ffa:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200ffc:	00043c03          	ld	s8,0(s0)
ffffffffc0201000:	00843b83          	ld	s7,8(s0)
    unsigned int nr_free_store = nr_free;
ffffffffc0201004:	01042b03          	lw	s6,16(s0)
    elm->prev = elm->next = elm;
ffffffffc0201008:	e400                	sd	s0,8(s0)
ffffffffc020100a:	e000                	sd	s0,0(s0)
    nr_free = 0;
ffffffffc020100c:	000c2797          	auipc	a5,0xc2
ffffffffc0201010:	c207a223          	sw	zero,-988(a5) # ffffffffc02c2c30 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc0201014:	5b5000ef          	jal	ra,ffffffffc0201dc8 <alloc_pages>
ffffffffc0201018:	2c051863          	bnez	a0,ffffffffc02012e8 <default_check+0x3c2>
    free_page(p0);
ffffffffc020101c:	4585                	li	a1,1
ffffffffc020101e:	8556                	mv	a0,s5
ffffffffc0201020:	5e7000ef          	jal	ra,ffffffffc0201e06 <free_pages>
    free_page(p1);
ffffffffc0201024:	4585                	li	a1,1
ffffffffc0201026:	854e                	mv	a0,s3
ffffffffc0201028:	5df000ef          	jal	ra,ffffffffc0201e06 <free_pages>
    free_page(p2);
ffffffffc020102c:	4585                	li	a1,1
ffffffffc020102e:	8552                	mv	a0,s4
ffffffffc0201030:	5d7000ef          	jal	ra,ffffffffc0201e06 <free_pages>
    assert(nr_free == 3);
ffffffffc0201034:	4818                	lw	a4,16(s0)
ffffffffc0201036:	478d                	li	a5,3
ffffffffc0201038:	28f71863          	bne	a4,a5,ffffffffc02012c8 <default_check+0x3a2>
    assert((p0 = alloc_page()) != NULL);
ffffffffc020103c:	4505                	li	a0,1
ffffffffc020103e:	58b000ef          	jal	ra,ffffffffc0201dc8 <alloc_pages>
ffffffffc0201042:	89aa                	mv	s3,a0
ffffffffc0201044:	26050263          	beqz	a0,ffffffffc02012a8 <default_check+0x382>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201048:	4505                	li	a0,1
ffffffffc020104a:	57f000ef          	jal	ra,ffffffffc0201dc8 <alloc_pages>
ffffffffc020104e:	8aaa                	mv	s5,a0
ffffffffc0201050:	3a050c63          	beqz	a0,ffffffffc0201408 <default_check+0x4e2>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201054:	4505                	li	a0,1
ffffffffc0201056:	573000ef          	jal	ra,ffffffffc0201dc8 <alloc_pages>
ffffffffc020105a:	8a2a                	mv	s4,a0
ffffffffc020105c:	38050663          	beqz	a0,ffffffffc02013e8 <default_check+0x4c2>
    assert(alloc_page() == NULL);
ffffffffc0201060:	4505                	li	a0,1
ffffffffc0201062:	567000ef          	jal	ra,ffffffffc0201dc8 <alloc_pages>
ffffffffc0201066:	36051163          	bnez	a0,ffffffffc02013c8 <default_check+0x4a2>
    free_page(p0);
ffffffffc020106a:	4585                	li	a1,1
ffffffffc020106c:	854e                	mv	a0,s3
ffffffffc020106e:	599000ef          	jal	ra,ffffffffc0201e06 <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0201072:	641c                	ld	a5,8(s0)
ffffffffc0201074:	20878a63          	beq	a5,s0,ffffffffc0201288 <default_check+0x362>
    assert((p = alloc_page()) == p0);
ffffffffc0201078:	4505                	li	a0,1
ffffffffc020107a:	54f000ef          	jal	ra,ffffffffc0201dc8 <alloc_pages>
ffffffffc020107e:	30a99563          	bne	s3,a0,ffffffffc0201388 <default_check+0x462>
    assert(alloc_page() == NULL);
ffffffffc0201082:	4505                	li	a0,1
ffffffffc0201084:	545000ef          	jal	ra,ffffffffc0201dc8 <alloc_pages>
ffffffffc0201088:	2e051063          	bnez	a0,ffffffffc0201368 <default_check+0x442>
    assert(nr_free == 0);
ffffffffc020108c:	481c                	lw	a5,16(s0)
ffffffffc020108e:	2a079d63          	bnez	a5,ffffffffc0201348 <default_check+0x422>
    free_page(p);
ffffffffc0201092:	854e                	mv	a0,s3
ffffffffc0201094:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0201096:	01843023          	sd	s8,0(s0)
ffffffffc020109a:	01743423          	sd	s7,8(s0)
    nr_free = nr_free_store;
ffffffffc020109e:	01642823          	sw	s6,16(s0)
    free_page(p);
ffffffffc02010a2:	565000ef          	jal	ra,ffffffffc0201e06 <free_pages>
    free_page(p1);
ffffffffc02010a6:	4585                	li	a1,1
ffffffffc02010a8:	8556                	mv	a0,s5
ffffffffc02010aa:	55d000ef          	jal	ra,ffffffffc0201e06 <free_pages>
    free_page(p2);
ffffffffc02010ae:	4585                	li	a1,1
ffffffffc02010b0:	8552                	mv	a0,s4
ffffffffc02010b2:	555000ef          	jal	ra,ffffffffc0201e06 <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc02010b6:	4515                	li	a0,5
ffffffffc02010b8:	511000ef          	jal	ra,ffffffffc0201dc8 <alloc_pages>
ffffffffc02010bc:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc02010be:	26050563          	beqz	a0,ffffffffc0201328 <default_check+0x402>
ffffffffc02010c2:	651c                	ld	a5,8(a0)
ffffffffc02010c4:	8385                	srli	a5,a5,0x1
ffffffffc02010c6:	8b85                	andi	a5,a5,1
    assert(!PageProperty(p0));
ffffffffc02010c8:	54079063          	bnez	a5,ffffffffc0201608 <default_check+0x6e2>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc02010cc:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc02010ce:	00043b03          	ld	s6,0(s0)
ffffffffc02010d2:	00843a83          	ld	s5,8(s0)
ffffffffc02010d6:	e000                	sd	s0,0(s0)
ffffffffc02010d8:	e400                	sd	s0,8(s0)
    assert(alloc_page() == NULL);
ffffffffc02010da:	4ef000ef          	jal	ra,ffffffffc0201dc8 <alloc_pages>
ffffffffc02010de:	50051563          	bnez	a0,ffffffffc02015e8 <default_check+0x6c2>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc02010e2:	08098a13          	addi	s4,s3,128
ffffffffc02010e6:	8552                	mv	a0,s4
ffffffffc02010e8:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc02010ea:	01042b83          	lw	s7,16(s0)
    nr_free = 0;
ffffffffc02010ee:	000c2797          	auipc	a5,0xc2
ffffffffc02010f2:	b407a123          	sw	zero,-1214(a5) # ffffffffc02c2c30 <free_area+0x10>
    free_pages(p0 + 2, 3);
ffffffffc02010f6:	511000ef          	jal	ra,ffffffffc0201e06 <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc02010fa:	4511                	li	a0,4
ffffffffc02010fc:	4cd000ef          	jal	ra,ffffffffc0201dc8 <alloc_pages>
ffffffffc0201100:	4c051463          	bnez	a0,ffffffffc02015c8 <default_check+0x6a2>
ffffffffc0201104:	0889b783          	ld	a5,136(s3)
ffffffffc0201108:	8385                	srli	a5,a5,0x1
ffffffffc020110a:	8b85                	andi	a5,a5,1
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc020110c:	48078e63          	beqz	a5,ffffffffc02015a8 <default_check+0x682>
ffffffffc0201110:	0909a703          	lw	a4,144(s3)
ffffffffc0201114:	478d                	li	a5,3
ffffffffc0201116:	48f71963          	bne	a4,a5,ffffffffc02015a8 <default_check+0x682>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc020111a:	450d                	li	a0,3
ffffffffc020111c:	4ad000ef          	jal	ra,ffffffffc0201dc8 <alloc_pages>
ffffffffc0201120:	8c2a                	mv	s8,a0
ffffffffc0201122:	46050363          	beqz	a0,ffffffffc0201588 <default_check+0x662>
    assert(alloc_page() == NULL);
ffffffffc0201126:	4505                	li	a0,1
ffffffffc0201128:	4a1000ef          	jal	ra,ffffffffc0201dc8 <alloc_pages>
ffffffffc020112c:	42051e63          	bnez	a0,ffffffffc0201568 <default_check+0x642>
    assert(p0 + 2 == p1);
ffffffffc0201130:	418a1c63          	bne	s4,s8,ffffffffc0201548 <default_check+0x622>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc0201134:	4585                	li	a1,1
ffffffffc0201136:	854e                	mv	a0,s3
ffffffffc0201138:	4cf000ef          	jal	ra,ffffffffc0201e06 <free_pages>
    free_pages(p1, 3);
ffffffffc020113c:	458d                	li	a1,3
ffffffffc020113e:	8552                	mv	a0,s4
ffffffffc0201140:	4c7000ef          	jal	ra,ffffffffc0201e06 <free_pages>
ffffffffc0201144:	0089b783          	ld	a5,8(s3)
    p2 = p0 + 1;
ffffffffc0201148:	04098c13          	addi	s8,s3,64
ffffffffc020114c:	8385                	srli	a5,a5,0x1
ffffffffc020114e:	8b85                	andi	a5,a5,1
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0201150:	3c078c63          	beqz	a5,ffffffffc0201528 <default_check+0x602>
ffffffffc0201154:	0109a703          	lw	a4,16(s3)
ffffffffc0201158:	4785                	li	a5,1
ffffffffc020115a:	3cf71763          	bne	a4,a5,ffffffffc0201528 <default_check+0x602>
ffffffffc020115e:	008a3783          	ld	a5,8(s4)
ffffffffc0201162:	8385                	srli	a5,a5,0x1
ffffffffc0201164:	8b85                	andi	a5,a5,1
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0201166:	3a078163          	beqz	a5,ffffffffc0201508 <default_check+0x5e2>
ffffffffc020116a:	010a2703          	lw	a4,16(s4)
ffffffffc020116e:	478d                	li	a5,3
ffffffffc0201170:	38f71c63          	bne	a4,a5,ffffffffc0201508 <default_check+0x5e2>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0201174:	4505                	li	a0,1
ffffffffc0201176:	453000ef          	jal	ra,ffffffffc0201dc8 <alloc_pages>
ffffffffc020117a:	36a99763          	bne	s3,a0,ffffffffc02014e8 <default_check+0x5c2>
    free_page(p0);
ffffffffc020117e:	4585                	li	a1,1
ffffffffc0201180:	487000ef          	jal	ra,ffffffffc0201e06 <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0201184:	4509                	li	a0,2
ffffffffc0201186:	443000ef          	jal	ra,ffffffffc0201dc8 <alloc_pages>
ffffffffc020118a:	32aa1f63          	bne	s4,a0,ffffffffc02014c8 <default_check+0x5a2>

    free_pages(p0, 2);
ffffffffc020118e:	4589                	li	a1,2
ffffffffc0201190:	477000ef          	jal	ra,ffffffffc0201e06 <free_pages>
    free_page(p2);
ffffffffc0201194:	4585                	li	a1,1
ffffffffc0201196:	8562                	mv	a0,s8
ffffffffc0201198:	46f000ef          	jal	ra,ffffffffc0201e06 <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc020119c:	4515                	li	a0,5
ffffffffc020119e:	42b000ef          	jal	ra,ffffffffc0201dc8 <alloc_pages>
ffffffffc02011a2:	89aa                	mv	s3,a0
ffffffffc02011a4:	48050263          	beqz	a0,ffffffffc0201628 <default_check+0x702>
    assert(alloc_page() == NULL);
ffffffffc02011a8:	4505                	li	a0,1
ffffffffc02011aa:	41f000ef          	jal	ra,ffffffffc0201dc8 <alloc_pages>
ffffffffc02011ae:	2c051d63          	bnez	a0,ffffffffc0201488 <default_check+0x562>

    assert(nr_free == 0);
ffffffffc02011b2:	481c                	lw	a5,16(s0)
ffffffffc02011b4:	2a079a63          	bnez	a5,ffffffffc0201468 <default_check+0x542>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc02011b8:	4595                	li	a1,5
ffffffffc02011ba:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc02011bc:	01742823          	sw	s7,16(s0)
    free_list = free_list_store;
ffffffffc02011c0:	01643023          	sd	s6,0(s0)
ffffffffc02011c4:	01543423          	sd	s5,8(s0)
    free_pages(p0, 5);
ffffffffc02011c8:	43f000ef          	jal	ra,ffffffffc0201e06 <free_pages>
    return listelm->next;
ffffffffc02011cc:	641c                	ld	a5,8(s0)

    le = &free_list;
    while ((le = list_next(le)) != &free_list)
ffffffffc02011ce:	00878963          	beq	a5,s0,ffffffffc02011e0 <default_check+0x2ba>
    {
        struct Page *p = le2page(le, page_link);
        count--, total -= p->property;
ffffffffc02011d2:	ff87a703          	lw	a4,-8(a5)
ffffffffc02011d6:	679c                	ld	a5,8(a5)
ffffffffc02011d8:	397d                	addiw	s2,s2,-1
ffffffffc02011da:	9c99                	subw	s1,s1,a4
    while ((le = list_next(le)) != &free_list)
ffffffffc02011dc:	fe879be3          	bne	a5,s0,ffffffffc02011d2 <default_check+0x2ac>
    }
    assert(count == 0);
ffffffffc02011e0:	26091463          	bnez	s2,ffffffffc0201448 <default_check+0x522>
    assert(total == 0);
ffffffffc02011e4:	46049263          	bnez	s1,ffffffffc0201648 <default_check+0x722>
}
ffffffffc02011e8:	60a6                	ld	ra,72(sp)
ffffffffc02011ea:	6406                	ld	s0,64(sp)
ffffffffc02011ec:	74e2                	ld	s1,56(sp)
ffffffffc02011ee:	7942                	ld	s2,48(sp)
ffffffffc02011f0:	79a2                	ld	s3,40(sp)
ffffffffc02011f2:	7a02                	ld	s4,32(sp)
ffffffffc02011f4:	6ae2                	ld	s5,24(sp)
ffffffffc02011f6:	6b42                	ld	s6,16(sp)
ffffffffc02011f8:	6ba2                	ld	s7,8(sp)
ffffffffc02011fa:	6c02                	ld	s8,0(sp)
ffffffffc02011fc:	6161                	addi	sp,sp,80
ffffffffc02011fe:	8082                	ret
    while ((le = list_next(le)) != &free_list)
ffffffffc0201200:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc0201202:	4481                	li	s1,0
ffffffffc0201204:	4901                	li	s2,0
ffffffffc0201206:	b38d                	j	ffffffffc0200f68 <default_check+0x42>
        assert(PageProperty(p));
ffffffffc0201208:	00005697          	auipc	a3,0x5
ffffffffc020120c:	0c868693          	addi	a3,a3,200 # ffffffffc02062d0 <commands+0x818>
ffffffffc0201210:	00005617          	auipc	a2,0x5
ffffffffc0201214:	0d060613          	addi	a2,a2,208 # ffffffffc02062e0 <commands+0x828>
ffffffffc0201218:	11000593          	li	a1,272
ffffffffc020121c:	00005517          	auipc	a0,0x5
ffffffffc0201220:	0dc50513          	addi	a0,a0,220 # ffffffffc02062f8 <commands+0x840>
ffffffffc0201224:	a6eff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0201228:	00005697          	auipc	a3,0x5
ffffffffc020122c:	16868693          	addi	a3,a3,360 # ffffffffc0206390 <commands+0x8d8>
ffffffffc0201230:	00005617          	auipc	a2,0x5
ffffffffc0201234:	0b060613          	addi	a2,a2,176 # ffffffffc02062e0 <commands+0x828>
ffffffffc0201238:	0db00593          	li	a1,219
ffffffffc020123c:	00005517          	auipc	a0,0x5
ffffffffc0201240:	0bc50513          	addi	a0,a0,188 # ffffffffc02062f8 <commands+0x840>
ffffffffc0201244:	a4eff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0201248:	00005697          	auipc	a3,0x5
ffffffffc020124c:	17068693          	addi	a3,a3,368 # ffffffffc02063b8 <commands+0x900>
ffffffffc0201250:	00005617          	auipc	a2,0x5
ffffffffc0201254:	09060613          	addi	a2,a2,144 # ffffffffc02062e0 <commands+0x828>
ffffffffc0201258:	0dc00593          	li	a1,220
ffffffffc020125c:	00005517          	auipc	a0,0x5
ffffffffc0201260:	09c50513          	addi	a0,a0,156 # ffffffffc02062f8 <commands+0x840>
ffffffffc0201264:	a2eff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0201268:	00005697          	auipc	a3,0x5
ffffffffc020126c:	19068693          	addi	a3,a3,400 # ffffffffc02063f8 <commands+0x940>
ffffffffc0201270:	00005617          	auipc	a2,0x5
ffffffffc0201274:	07060613          	addi	a2,a2,112 # ffffffffc02062e0 <commands+0x828>
ffffffffc0201278:	0de00593          	li	a1,222
ffffffffc020127c:	00005517          	auipc	a0,0x5
ffffffffc0201280:	07c50513          	addi	a0,a0,124 # ffffffffc02062f8 <commands+0x840>
ffffffffc0201284:	a0eff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(!list_empty(&free_list));
ffffffffc0201288:	00005697          	auipc	a3,0x5
ffffffffc020128c:	1f868693          	addi	a3,a3,504 # ffffffffc0206480 <commands+0x9c8>
ffffffffc0201290:	00005617          	auipc	a2,0x5
ffffffffc0201294:	05060613          	addi	a2,a2,80 # ffffffffc02062e0 <commands+0x828>
ffffffffc0201298:	0f700593          	li	a1,247
ffffffffc020129c:	00005517          	auipc	a0,0x5
ffffffffc02012a0:	05c50513          	addi	a0,a0,92 # ffffffffc02062f8 <commands+0x840>
ffffffffc02012a4:	9eeff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02012a8:	00005697          	auipc	a3,0x5
ffffffffc02012ac:	08868693          	addi	a3,a3,136 # ffffffffc0206330 <commands+0x878>
ffffffffc02012b0:	00005617          	auipc	a2,0x5
ffffffffc02012b4:	03060613          	addi	a2,a2,48 # ffffffffc02062e0 <commands+0x828>
ffffffffc02012b8:	0f000593          	li	a1,240
ffffffffc02012bc:	00005517          	auipc	a0,0x5
ffffffffc02012c0:	03c50513          	addi	a0,a0,60 # ffffffffc02062f8 <commands+0x840>
ffffffffc02012c4:	9ceff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(nr_free == 3);
ffffffffc02012c8:	00005697          	auipc	a3,0x5
ffffffffc02012cc:	1a868693          	addi	a3,a3,424 # ffffffffc0206470 <commands+0x9b8>
ffffffffc02012d0:	00005617          	auipc	a2,0x5
ffffffffc02012d4:	01060613          	addi	a2,a2,16 # ffffffffc02062e0 <commands+0x828>
ffffffffc02012d8:	0ee00593          	li	a1,238
ffffffffc02012dc:	00005517          	auipc	a0,0x5
ffffffffc02012e0:	01c50513          	addi	a0,a0,28 # ffffffffc02062f8 <commands+0x840>
ffffffffc02012e4:	9aeff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02012e8:	00005697          	auipc	a3,0x5
ffffffffc02012ec:	17068693          	addi	a3,a3,368 # ffffffffc0206458 <commands+0x9a0>
ffffffffc02012f0:	00005617          	auipc	a2,0x5
ffffffffc02012f4:	ff060613          	addi	a2,a2,-16 # ffffffffc02062e0 <commands+0x828>
ffffffffc02012f8:	0e900593          	li	a1,233
ffffffffc02012fc:	00005517          	auipc	a0,0x5
ffffffffc0201300:	ffc50513          	addi	a0,a0,-4 # ffffffffc02062f8 <commands+0x840>
ffffffffc0201304:	98eff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0201308:	00005697          	auipc	a3,0x5
ffffffffc020130c:	13068693          	addi	a3,a3,304 # ffffffffc0206438 <commands+0x980>
ffffffffc0201310:	00005617          	auipc	a2,0x5
ffffffffc0201314:	fd060613          	addi	a2,a2,-48 # ffffffffc02062e0 <commands+0x828>
ffffffffc0201318:	0e000593          	li	a1,224
ffffffffc020131c:	00005517          	auipc	a0,0x5
ffffffffc0201320:	fdc50513          	addi	a0,a0,-36 # ffffffffc02062f8 <commands+0x840>
ffffffffc0201324:	96eff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(p0 != NULL);
ffffffffc0201328:	00005697          	auipc	a3,0x5
ffffffffc020132c:	1a068693          	addi	a3,a3,416 # ffffffffc02064c8 <commands+0xa10>
ffffffffc0201330:	00005617          	auipc	a2,0x5
ffffffffc0201334:	fb060613          	addi	a2,a2,-80 # ffffffffc02062e0 <commands+0x828>
ffffffffc0201338:	11800593          	li	a1,280
ffffffffc020133c:	00005517          	auipc	a0,0x5
ffffffffc0201340:	fbc50513          	addi	a0,a0,-68 # ffffffffc02062f8 <commands+0x840>
ffffffffc0201344:	94eff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(nr_free == 0);
ffffffffc0201348:	00005697          	auipc	a3,0x5
ffffffffc020134c:	17068693          	addi	a3,a3,368 # ffffffffc02064b8 <commands+0xa00>
ffffffffc0201350:	00005617          	auipc	a2,0x5
ffffffffc0201354:	f9060613          	addi	a2,a2,-112 # ffffffffc02062e0 <commands+0x828>
ffffffffc0201358:	0fd00593          	li	a1,253
ffffffffc020135c:	00005517          	auipc	a0,0x5
ffffffffc0201360:	f9c50513          	addi	a0,a0,-100 # ffffffffc02062f8 <commands+0x840>
ffffffffc0201364:	92eff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201368:	00005697          	auipc	a3,0x5
ffffffffc020136c:	0f068693          	addi	a3,a3,240 # ffffffffc0206458 <commands+0x9a0>
ffffffffc0201370:	00005617          	auipc	a2,0x5
ffffffffc0201374:	f7060613          	addi	a2,a2,-144 # ffffffffc02062e0 <commands+0x828>
ffffffffc0201378:	0fb00593          	li	a1,251
ffffffffc020137c:	00005517          	auipc	a0,0x5
ffffffffc0201380:	f7c50513          	addi	a0,a0,-132 # ffffffffc02062f8 <commands+0x840>
ffffffffc0201384:	90eff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc0201388:	00005697          	auipc	a3,0x5
ffffffffc020138c:	11068693          	addi	a3,a3,272 # ffffffffc0206498 <commands+0x9e0>
ffffffffc0201390:	00005617          	auipc	a2,0x5
ffffffffc0201394:	f5060613          	addi	a2,a2,-176 # ffffffffc02062e0 <commands+0x828>
ffffffffc0201398:	0fa00593          	li	a1,250
ffffffffc020139c:	00005517          	auipc	a0,0x5
ffffffffc02013a0:	f5c50513          	addi	a0,a0,-164 # ffffffffc02062f8 <commands+0x840>
ffffffffc02013a4:	8eeff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02013a8:	00005697          	auipc	a3,0x5
ffffffffc02013ac:	f8868693          	addi	a3,a3,-120 # ffffffffc0206330 <commands+0x878>
ffffffffc02013b0:	00005617          	auipc	a2,0x5
ffffffffc02013b4:	f3060613          	addi	a2,a2,-208 # ffffffffc02062e0 <commands+0x828>
ffffffffc02013b8:	0d700593          	li	a1,215
ffffffffc02013bc:	00005517          	auipc	a0,0x5
ffffffffc02013c0:	f3c50513          	addi	a0,a0,-196 # ffffffffc02062f8 <commands+0x840>
ffffffffc02013c4:	8ceff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02013c8:	00005697          	auipc	a3,0x5
ffffffffc02013cc:	09068693          	addi	a3,a3,144 # ffffffffc0206458 <commands+0x9a0>
ffffffffc02013d0:	00005617          	auipc	a2,0x5
ffffffffc02013d4:	f1060613          	addi	a2,a2,-240 # ffffffffc02062e0 <commands+0x828>
ffffffffc02013d8:	0f400593          	li	a1,244
ffffffffc02013dc:	00005517          	auipc	a0,0x5
ffffffffc02013e0:	f1c50513          	addi	a0,a0,-228 # ffffffffc02062f8 <commands+0x840>
ffffffffc02013e4:	8aeff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02013e8:	00005697          	auipc	a3,0x5
ffffffffc02013ec:	f8868693          	addi	a3,a3,-120 # ffffffffc0206370 <commands+0x8b8>
ffffffffc02013f0:	00005617          	auipc	a2,0x5
ffffffffc02013f4:	ef060613          	addi	a2,a2,-272 # ffffffffc02062e0 <commands+0x828>
ffffffffc02013f8:	0f200593          	li	a1,242
ffffffffc02013fc:	00005517          	auipc	a0,0x5
ffffffffc0201400:	efc50513          	addi	a0,a0,-260 # ffffffffc02062f8 <commands+0x840>
ffffffffc0201404:	88eff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201408:	00005697          	auipc	a3,0x5
ffffffffc020140c:	f4868693          	addi	a3,a3,-184 # ffffffffc0206350 <commands+0x898>
ffffffffc0201410:	00005617          	auipc	a2,0x5
ffffffffc0201414:	ed060613          	addi	a2,a2,-304 # ffffffffc02062e0 <commands+0x828>
ffffffffc0201418:	0f100593          	li	a1,241
ffffffffc020141c:	00005517          	auipc	a0,0x5
ffffffffc0201420:	edc50513          	addi	a0,a0,-292 # ffffffffc02062f8 <commands+0x840>
ffffffffc0201424:	86eff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201428:	00005697          	auipc	a3,0x5
ffffffffc020142c:	f4868693          	addi	a3,a3,-184 # ffffffffc0206370 <commands+0x8b8>
ffffffffc0201430:	00005617          	auipc	a2,0x5
ffffffffc0201434:	eb060613          	addi	a2,a2,-336 # ffffffffc02062e0 <commands+0x828>
ffffffffc0201438:	0d900593          	li	a1,217
ffffffffc020143c:	00005517          	auipc	a0,0x5
ffffffffc0201440:	ebc50513          	addi	a0,a0,-324 # ffffffffc02062f8 <commands+0x840>
ffffffffc0201444:	84eff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(count == 0);
ffffffffc0201448:	00005697          	auipc	a3,0x5
ffffffffc020144c:	1d068693          	addi	a3,a3,464 # ffffffffc0206618 <commands+0xb60>
ffffffffc0201450:	00005617          	auipc	a2,0x5
ffffffffc0201454:	e9060613          	addi	a2,a2,-368 # ffffffffc02062e0 <commands+0x828>
ffffffffc0201458:	14600593          	li	a1,326
ffffffffc020145c:	00005517          	auipc	a0,0x5
ffffffffc0201460:	e9c50513          	addi	a0,a0,-356 # ffffffffc02062f8 <commands+0x840>
ffffffffc0201464:	82eff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(nr_free == 0);
ffffffffc0201468:	00005697          	auipc	a3,0x5
ffffffffc020146c:	05068693          	addi	a3,a3,80 # ffffffffc02064b8 <commands+0xa00>
ffffffffc0201470:	00005617          	auipc	a2,0x5
ffffffffc0201474:	e7060613          	addi	a2,a2,-400 # ffffffffc02062e0 <commands+0x828>
ffffffffc0201478:	13a00593          	li	a1,314
ffffffffc020147c:	00005517          	auipc	a0,0x5
ffffffffc0201480:	e7c50513          	addi	a0,a0,-388 # ffffffffc02062f8 <commands+0x840>
ffffffffc0201484:	80eff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201488:	00005697          	auipc	a3,0x5
ffffffffc020148c:	fd068693          	addi	a3,a3,-48 # ffffffffc0206458 <commands+0x9a0>
ffffffffc0201490:	00005617          	auipc	a2,0x5
ffffffffc0201494:	e5060613          	addi	a2,a2,-432 # ffffffffc02062e0 <commands+0x828>
ffffffffc0201498:	13800593          	li	a1,312
ffffffffc020149c:	00005517          	auipc	a0,0x5
ffffffffc02014a0:	e5c50513          	addi	a0,a0,-420 # ffffffffc02062f8 <commands+0x840>
ffffffffc02014a4:	feffe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc02014a8:	00005697          	auipc	a3,0x5
ffffffffc02014ac:	f7068693          	addi	a3,a3,-144 # ffffffffc0206418 <commands+0x960>
ffffffffc02014b0:	00005617          	auipc	a2,0x5
ffffffffc02014b4:	e3060613          	addi	a2,a2,-464 # ffffffffc02062e0 <commands+0x828>
ffffffffc02014b8:	0df00593          	li	a1,223
ffffffffc02014bc:	00005517          	auipc	a0,0x5
ffffffffc02014c0:	e3c50513          	addi	a0,a0,-452 # ffffffffc02062f8 <commands+0x840>
ffffffffc02014c4:	fcffe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc02014c8:	00005697          	auipc	a3,0x5
ffffffffc02014cc:	11068693          	addi	a3,a3,272 # ffffffffc02065d8 <commands+0xb20>
ffffffffc02014d0:	00005617          	auipc	a2,0x5
ffffffffc02014d4:	e1060613          	addi	a2,a2,-496 # ffffffffc02062e0 <commands+0x828>
ffffffffc02014d8:	13200593          	li	a1,306
ffffffffc02014dc:	00005517          	auipc	a0,0x5
ffffffffc02014e0:	e1c50513          	addi	a0,a0,-484 # ffffffffc02062f8 <commands+0x840>
ffffffffc02014e4:	faffe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc02014e8:	00005697          	auipc	a3,0x5
ffffffffc02014ec:	0d068693          	addi	a3,a3,208 # ffffffffc02065b8 <commands+0xb00>
ffffffffc02014f0:	00005617          	auipc	a2,0x5
ffffffffc02014f4:	df060613          	addi	a2,a2,-528 # ffffffffc02062e0 <commands+0x828>
ffffffffc02014f8:	13000593          	li	a1,304
ffffffffc02014fc:	00005517          	auipc	a0,0x5
ffffffffc0201500:	dfc50513          	addi	a0,a0,-516 # ffffffffc02062f8 <commands+0x840>
ffffffffc0201504:	f8ffe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0201508:	00005697          	auipc	a3,0x5
ffffffffc020150c:	08868693          	addi	a3,a3,136 # ffffffffc0206590 <commands+0xad8>
ffffffffc0201510:	00005617          	auipc	a2,0x5
ffffffffc0201514:	dd060613          	addi	a2,a2,-560 # ffffffffc02062e0 <commands+0x828>
ffffffffc0201518:	12e00593          	li	a1,302
ffffffffc020151c:	00005517          	auipc	a0,0x5
ffffffffc0201520:	ddc50513          	addi	a0,a0,-548 # ffffffffc02062f8 <commands+0x840>
ffffffffc0201524:	f6ffe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0201528:	00005697          	auipc	a3,0x5
ffffffffc020152c:	04068693          	addi	a3,a3,64 # ffffffffc0206568 <commands+0xab0>
ffffffffc0201530:	00005617          	auipc	a2,0x5
ffffffffc0201534:	db060613          	addi	a2,a2,-592 # ffffffffc02062e0 <commands+0x828>
ffffffffc0201538:	12d00593          	li	a1,301
ffffffffc020153c:	00005517          	auipc	a0,0x5
ffffffffc0201540:	dbc50513          	addi	a0,a0,-580 # ffffffffc02062f8 <commands+0x840>
ffffffffc0201544:	f4ffe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(p0 + 2 == p1);
ffffffffc0201548:	00005697          	auipc	a3,0x5
ffffffffc020154c:	01068693          	addi	a3,a3,16 # ffffffffc0206558 <commands+0xaa0>
ffffffffc0201550:	00005617          	auipc	a2,0x5
ffffffffc0201554:	d9060613          	addi	a2,a2,-624 # ffffffffc02062e0 <commands+0x828>
ffffffffc0201558:	12800593          	li	a1,296
ffffffffc020155c:	00005517          	auipc	a0,0x5
ffffffffc0201560:	d9c50513          	addi	a0,a0,-612 # ffffffffc02062f8 <commands+0x840>
ffffffffc0201564:	f2ffe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201568:	00005697          	auipc	a3,0x5
ffffffffc020156c:	ef068693          	addi	a3,a3,-272 # ffffffffc0206458 <commands+0x9a0>
ffffffffc0201570:	00005617          	auipc	a2,0x5
ffffffffc0201574:	d7060613          	addi	a2,a2,-656 # ffffffffc02062e0 <commands+0x828>
ffffffffc0201578:	12700593          	li	a1,295
ffffffffc020157c:	00005517          	auipc	a0,0x5
ffffffffc0201580:	d7c50513          	addi	a0,a0,-644 # ffffffffc02062f8 <commands+0x840>
ffffffffc0201584:	f0ffe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0201588:	00005697          	auipc	a3,0x5
ffffffffc020158c:	fb068693          	addi	a3,a3,-80 # ffffffffc0206538 <commands+0xa80>
ffffffffc0201590:	00005617          	auipc	a2,0x5
ffffffffc0201594:	d5060613          	addi	a2,a2,-688 # ffffffffc02062e0 <commands+0x828>
ffffffffc0201598:	12600593          	li	a1,294
ffffffffc020159c:	00005517          	auipc	a0,0x5
ffffffffc02015a0:	d5c50513          	addi	a0,a0,-676 # ffffffffc02062f8 <commands+0x840>
ffffffffc02015a4:	eeffe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc02015a8:	00005697          	auipc	a3,0x5
ffffffffc02015ac:	f6068693          	addi	a3,a3,-160 # ffffffffc0206508 <commands+0xa50>
ffffffffc02015b0:	00005617          	auipc	a2,0x5
ffffffffc02015b4:	d3060613          	addi	a2,a2,-720 # ffffffffc02062e0 <commands+0x828>
ffffffffc02015b8:	12500593          	li	a1,293
ffffffffc02015bc:	00005517          	auipc	a0,0x5
ffffffffc02015c0:	d3c50513          	addi	a0,a0,-708 # ffffffffc02062f8 <commands+0x840>
ffffffffc02015c4:	ecffe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc02015c8:	00005697          	auipc	a3,0x5
ffffffffc02015cc:	f2868693          	addi	a3,a3,-216 # ffffffffc02064f0 <commands+0xa38>
ffffffffc02015d0:	00005617          	auipc	a2,0x5
ffffffffc02015d4:	d1060613          	addi	a2,a2,-752 # ffffffffc02062e0 <commands+0x828>
ffffffffc02015d8:	12400593          	li	a1,292
ffffffffc02015dc:	00005517          	auipc	a0,0x5
ffffffffc02015e0:	d1c50513          	addi	a0,a0,-740 # ffffffffc02062f8 <commands+0x840>
ffffffffc02015e4:	eaffe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02015e8:	00005697          	auipc	a3,0x5
ffffffffc02015ec:	e7068693          	addi	a3,a3,-400 # ffffffffc0206458 <commands+0x9a0>
ffffffffc02015f0:	00005617          	auipc	a2,0x5
ffffffffc02015f4:	cf060613          	addi	a2,a2,-784 # ffffffffc02062e0 <commands+0x828>
ffffffffc02015f8:	11e00593          	li	a1,286
ffffffffc02015fc:	00005517          	auipc	a0,0x5
ffffffffc0201600:	cfc50513          	addi	a0,a0,-772 # ffffffffc02062f8 <commands+0x840>
ffffffffc0201604:	e8ffe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(!PageProperty(p0));
ffffffffc0201608:	00005697          	auipc	a3,0x5
ffffffffc020160c:	ed068693          	addi	a3,a3,-304 # ffffffffc02064d8 <commands+0xa20>
ffffffffc0201610:	00005617          	auipc	a2,0x5
ffffffffc0201614:	cd060613          	addi	a2,a2,-816 # ffffffffc02062e0 <commands+0x828>
ffffffffc0201618:	11900593          	li	a1,281
ffffffffc020161c:	00005517          	auipc	a0,0x5
ffffffffc0201620:	cdc50513          	addi	a0,a0,-804 # ffffffffc02062f8 <commands+0x840>
ffffffffc0201624:	e6ffe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0201628:	00005697          	auipc	a3,0x5
ffffffffc020162c:	fd068693          	addi	a3,a3,-48 # ffffffffc02065f8 <commands+0xb40>
ffffffffc0201630:	00005617          	auipc	a2,0x5
ffffffffc0201634:	cb060613          	addi	a2,a2,-848 # ffffffffc02062e0 <commands+0x828>
ffffffffc0201638:	13700593          	li	a1,311
ffffffffc020163c:	00005517          	auipc	a0,0x5
ffffffffc0201640:	cbc50513          	addi	a0,a0,-836 # ffffffffc02062f8 <commands+0x840>
ffffffffc0201644:	e4ffe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(total == 0);
ffffffffc0201648:	00005697          	auipc	a3,0x5
ffffffffc020164c:	fe068693          	addi	a3,a3,-32 # ffffffffc0206628 <commands+0xb70>
ffffffffc0201650:	00005617          	auipc	a2,0x5
ffffffffc0201654:	c9060613          	addi	a2,a2,-880 # ffffffffc02062e0 <commands+0x828>
ffffffffc0201658:	14700593          	li	a1,327
ffffffffc020165c:	00005517          	auipc	a0,0x5
ffffffffc0201660:	c9c50513          	addi	a0,a0,-868 # ffffffffc02062f8 <commands+0x840>
ffffffffc0201664:	e2ffe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(total == nr_free_pages());
ffffffffc0201668:	00005697          	auipc	a3,0x5
ffffffffc020166c:	ca868693          	addi	a3,a3,-856 # ffffffffc0206310 <commands+0x858>
ffffffffc0201670:	00005617          	auipc	a2,0x5
ffffffffc0201674:	c7060613          	addi	a2,a2,-912 # ffffffffc02062e0 <commands+0x828>
ffffffffc0201678:	11300593          	li	a1,275
ffffffffc020167c:	00005517          	auipc	a0,0x5
ffffffffc0201680:	c7c50513          	addi	a0,a0,-900 # ffffffffc02062f8 <commands+0x840>
ffffffffc0201684:	e0ffe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201688:	00005697          	auipc	a3,0x5
ffffffffc020168c:	cc868693          	addi	a3,a3,-824 # ffffffffc0206350 <commands+0x898>
ffffffffc0201690:	00005617          	auipc	a2,0x5
ffffffffc0201694:	c5060613          	addi	a2,a2,-944 # ffffffffc02062e0 <commands+0x828>
ffffffffc0201698:	0d800593          	li	a1,216
ffffffffc020169c:	00005517          	auipc	a0,0x5
ffffffffc02016a0:	c5c50513          	addi	a0,a0,-932 # ffffffffc02062f8 <commands+0x840>
ffffffffc02016a4:	deffe0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc02016a8 <default_free_pages>:
{
ffffffffc02016a8:	1141                	addi	sp,sp,-16
ffffffffc02016aa:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02016ac:	14058463          	beqz	a1,ffffffffc02017f4 <default_free_pages+0x14c>
    for (; p != base + n; p++)
ffffffffc02016b0:	00659693          	slli	a3,a1,0x6
ffffffffc02016b4:	96aa                	add	a3,a3,a0
ffffffffc02016b6:	87aa                	mv	a5,a0
ffffffffc02016b8:	02d50263          	beq	a0,a3,ffffffffc02016dc <default_free_pages+0x34>
ffffffffc02016bc:	6798                	ld	a4,8(a5)
ffffffffc02016be:	8b05                	andi	a4,a4,1
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc02016c0:	10071a63          	bnez	a4,ffffffffc02017d4 <default_free_pages+0x12c>
ffffffffc02016c4:	6798                	ld	a4,8(a5)
ffffffffc02016c6:	8b09                	andi	a4,a4,2
ffffffffc02016c8:	10071663          	bnez	a4,ffffffffc02017d4 <default_free_pages+0x12c>
        p->flags = 0;
ffffffffc02016cc:	0007b423          	sd	zero,8(a5)
}

static inline void
set_page_ref(struct Page *page, int val)
{
    page->ref = val;
ffffffffc02016d0:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p++)
ffffffffc02016d4:	04078793          	addi	a5,a5,64
ffffffffc02016d8:	fed792e3          	bne	a5,a3,ffffffffc02016bc <default_free_pages+0x14>
    base->property = n;
ffffffffc02016dc:	2581                	sext.w	a1,a1
ffffffffc02016de:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc02016e0:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02016e4:	4789                	li	a5,2
ffffffffc02016e6:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc02016ea:	000c1697          	auipc	a3,0xc1
ffffffffc02016ee:	53668693          	addi	a3,a3,1334 # ffffffffc02c2c20 <free_area>
ffffffffc02016f2:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc02016f4:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc02016f6:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc02016fa:	9db9                	addw	a1,a1,a4
ffffffffc02016fc:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list))
ffffffffc02016fe:	0ad78463          	beq	a5,a3,ffffffffc02017a6 <default_free_pages+0xfe>
            struct Page *page = le2page(le, page_link);
ffffffffc0201702:	fe878713          	addi	a4,a5,-24
ffffffffc0201706:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list))
ffffffffc020170a:	4581                	li	a1,0
            if (base < page)
ffffffffc020170c:	00e56a63          	bltu	a0,a4,ffffffffc0201720 <default_free_pages+0x78>
    return listelm->next;
ffffffffc0201710:	6798                	ld	a4,8(a5)
            else if (list_next(le) == &free_list)
ffffffffc0201712:	04d70c63          	beq	a4,a3,ffffffffc020176a <default_free_pages+0xc2>
    for (; p != base + n; p++)
ffffffffc0201716:	87ba                	mv	a5,a4
            struct Page *page = le2page(le, page_link);
ffffffffc0201718:	fe878713          	addi	a4,a5,-24
            if (base < page)
ffffffffc020171c:	fee57ae3          	bgeu	a0,a4,ffffffffc0201710 <default_free_pages+0x68>
ffffffffc0201720:	c199                	beqz	a1,ffffffffc0201726 <default_free_pages+0x7e>
ffffffffc0201722:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0201726:	6398                	ld	a4,0(a5)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc0201728:	e390                	sd	a2,0(a5)
ffffffffc020172a:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc020172c:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc020172e:	ed18                	sd	a4,24(a0)
    if (le != &free_list)
ffffffffc0201730:	00d70d63          	beq	a4,a3,ffffffffc020174a <default_free_pages+0xa2>
        if (p + p->property == base)
ffffffffc0201734:	ff872583          	lw	a1,-8(a4)
        p = le2page(le, page_link);
ffffffffc0201738:	fe870613          	addi	a2,a4,-24
        if (p + p->property == base)
ffffffffc020173c:	02059813          	slli	a6,a1,0x20
ffffffffc0201740:	01a85793          	srli	a5,a6,0x1a
ffffffffc0201744:	97b2                	add	a5,a5,a2
ffffffffc0201746:	02f50c63          	beq	a0,a5,ffffffffc020177e <default_free_pages+0xd6>
    return listelm->next;
ffffffffc020174a:	711c                	ld	a5,32(a0)
    if (le != &free_list)
ffffffffc020174c:	00d78c63          	beq	a5,a3,ffffffffc0201764 <default_free_pages+0xbc>
        if (base + base->property == p)
ffffffffc0201750:	4910                	lw	a2,16(a0)
        p = le2page(le, page_link);
ffffffffc0201752:	fe878693          	addi	a3,a5,-24
        if (base + base->property == p)
ffffffffc0201756:	02061593          	slli	a1,a2,0x20
ffffffffc020175a:	01a5d713          	srli	a4,a1,0x1a
ffffffffc020175e:	972a                	add	a4,a4,a0
ffffffffc0201760:	04e68a63          	beq	a3,a4,ffffffffc02017b4 <default_free_pages+0x10c>
}
ffffffffc0201764:	60a2                	ld	ra,8(sp)
ffffffffc0201766:	0141                	addi	sp,sp,16
ffffffffc0201768:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc020176a:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc020176c:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc020176e:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0201770:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list)
ffffffffc0201772:	02d70763          	beq	a4,a3,ffffffffc02017a0 <default_free_pages+0xf8>
    prev->next = next->prev = elm;
ffffffffc0201776:	8832                	mv	a6,a2
ffffffffc0201778:	4585                	li	a1,1
    for (; p != base + n; p++)
ffffffffc020177a:	87ba                	mv	a5,a4
ffffffffc020177c:	bf71                	j	ffffffffc0201718 <default_free_pages+0x70>
            p->property += base->property;
ffffffffc020177e:	491c                	lw	a5,16(a0)
ffffffffc0201780:	9dbd                	addw	a1,a1,a5
ffffffffc0201782:	feb72c23          	sw	a1,-8(a4)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0201786:	57f5                	li	a5,-3
ffffffffc0201788:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc020178c:	01853803          	ld	a6,24(a0)
ffffffffc0201790:	710c                	ld	a1,32(a0)
            base = p;
ffffffffc0201792:	8532                	mv	a0,a2
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0201794:	00b83423          	sd	a1,8(a6)
    return listelm->next;
ffffffffc0201798:	671c                	ld	a5,8(a4)
    next->prev = prev;
ffffffffc020179a:	0105b023          	sd	a6,0(a1)
ffffffffc020179e:	b77d                	j	ffffffffc020174c <default_free_pages+0xa4>
ffffffffc02017a0:	e290                	sd	a2,0(a3)
        while ((le = list_next(le)) != &free_list)
ffffffffc02017a2:	873e                	mv	a4,a5
ffffffffc02017a4:	bf41                	j	ffffffffc0201734 <default_free_pages+0x8c>
}
ffffffffc02017a6:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc02017a8:	e390                	sd	a2,0(a5)
ffffffffc02017aa:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02017ac:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02017ae:	ed1c                	sd	a5,24(a0)
ffffffffc02017b0:	0141                	addi	sp,sp,16
ffffffffc02017b2:	8082                	ret
            base->property += p->property;
ffffffffc02017b4:	ff87a703          	lw	a4,-8(a5)
ffffffffc02017b8:	ff078693          	addi	a3,a5,-16
ffffffffc02017bc:	9e39                	addw	a2,a2,a4
ffffffffc02017be:	c910                	sw	a2,16(a0)
ffffffffc02017c0:	5775                	li	a4,-3
ffffffffc02017c2:	60e6b02f          	amoand.d	zero,a4,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc02017c6:	6398                	ld	a4,0(a5)
ffffffffc02017c8:	679c                	ld	a5,8(a5)
}
ffffffffc02017ca:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc02017cc:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc02017ce:	e398                	sd	a4,0(a5)
ffffffffc02017d0:	0141                	addi	sp,sp,16
ffffffffc02017d2:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc02017d4:	00005697          	auipc	a3,0x5
ffffffffc02017d8:	e6c68693          	addi	a3,a3,-404 # ffffffffc0206640 <commands+0xb88>
ffffffffc02017dc:	00005617          	auipc	a2,0x5
ffffffffc02017e0:	b0460613          	addi	a2,a2,-1276 # ffffffffc02062e0 <commands+0x828>
ffffffffc02017e4:	09400593          	li	a1,148
ffffffffc02017e8:	00005517          	auipc	a0,0x5
ffffffffc02017ec:	b1050513          	addi	a0,a0,-1264 # ffffffffc02062f8 <commands+0x840>
ffffffffc02017f0:	ca3fe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(n > 0);
ffffffffc02017f4:	00005697          	auipc	a3,0x5
ffffffffc02017f8:	e4468693          	addi	a3,a3,-444 # ffffffffc0206638 <commands+0xb80>
ffffffffc02017fc:	00005617          	auipc	a2,0x5
ffffffffc0201800:	ae460613          	addi	a2,a2,-1308 # ffffffffc02062e0 <commands+0x828>
ffffffffc0201804:	09000593          	li	a1,144
ffffffffc0201808:	00005517          	auipc	a0,0x5
ffffffffc020180c:	af050513          	addi	a0,a0,-1296 # ffffffffc02062f8 <commands+0x840>
ffffffffc0201810:	c83fe0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0201814 <default_alloc_pages>:
    assert(n > 0);
ffffffffc0201814:	c941                	beqz	a0,ffffffffc02018a4 <default_alloc_pages+0x90>
    if (n > nr_free)
ffffffffc0201816:	000c1597          	auipc	a1,0xc1
ffffffffc020181a:	40a58593          	addi	a1,a1,1034 # ffffffffc02c2c20 <free_area>
ffffffffc020181e:	0105a803          	lw	a6,16(a1)
ffffffffc0201822:	872a                	mv	a4,a0
ffffffffc0201824:	02081793          	slli	a5,a6,0x20
ffffffffc0201828:	9381                	srli	a5,a5,0x20
ffffffffc020182a:	00a7ee63          	bltu	a5,a0,ffffffffc0201846 <default_alloc_pages+0x32>
    list_entry_t *le = &free_list;
ffffffffc020182e:	87ae                	mv	a5,a1
ffffffffc0201830:	a801                	j	ffffffffc0201840 <default_alloc_pages+0x2c>
        if (p->property >= n)
ffffffffc0201832:	ff87a683          	lw	a3,-8(a5)
ffffffffc0201836:	02069613          	slli	a2,a3,0x20
ffffffffc020183a:	9201                	srli	a2,a2,0x20
ffffffffc020183c:	00e67763          	bgeu	a2,a4,ffffffffc020184a <default_alloc_pages+0x36>
    return listelm->next;
ffffffffc0201840:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list)
ffffffffc0201842:	feb798e3          	bne	a5,a1,ffffffffc0201832 <default_alloc_pages+0x1e>
        return NULL;
ffffffffc0201846:	4501                	li	a0,0
}
ffffffffc0201848:	8082                	ret
    return listelm->prev;
ffffffffc020184a:	0007b883          	ld	a7,0(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc020184e:	0087b303          	ld	t1,8(a5)
        struct Page *p = le2page(le, page_link);
ffffffffc0201852:	fe878513          	addi	a0,a5,-24
            p->property = page->property - n;
ffffffffc0201856:	00070e1b          	sext.w	t3,a4
    prev->next = next;
ffffffffc020185a:	0068b423          	sd	t1,8(a7)
    next->prev = prev;
ffffffffc020185e:	01133023          	sd	a7,0(t1)
        if (page->property > n)
ffffffffc0201862:	02c77863          	bgeu	a4,a2,ffffffffc0201892 <default_alloc_pages+0x7e>
            struct Page *p = page + n;
ffffffffc0201866:	071a                	slli	a4,a4,0x6
ffffffffc0201868:	972a                	add	a4,a4,a0
            p->property = page->property - n;
ffffffffc020186a:	41c686bb          	subw	a3,a3,t3
ffffffffc020186e:	cb14                	sw	a3,16(a4)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201870:	00870613          	addi	a2,a4,8
ffffffffc0201874:	4689                	li	a3,2
ffffffffc0201876:	40d6302f          	amoor.d	zero,a3,(a2)
    __list_add(elm, listelm, listelm->next);
ffffffffc020187a:	0088b683          	ld	a3,8(a7)
            list_add(prev, &(p->page_link));
ffffffffc020187e:	01870613          	addi	a2,a4,24
        nr_free -= n;
ffffffffc0201882:	0105a803          	lw	a6,16(a1)
    prev->next = next->prev = elm;
ffffffffc0201886:	e290                	sd	a2,0(a3)
ffffffffc0201888:	00c8b423          	sd	a2,8(a7)
    elm->next = next;
ffffffffc020188c:	f314                	sd	a3,32(a4)
    elm->prev = prev;
ffffffffc020188e:	01173c23          	sd	a7,24(a4)
ffffffffc0201892:	41c8083b          	subw	a6,a6,t3
ffffffffc0201896:	0105a823          	sw	a6,16(a1)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc020189a:	5775                	li	a4,-3
ffffffffc020189c:	17c1                	addi	a5,a5,-16
ffffffffc020189e:	60e7b02f          	amoand.d	zero,a4,(a5)
}
ffffffffc02018a2:	8082                	ret
{
ffffffffc02018a4:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc02018a6:	00005697          	auipc	a3,0x5
ffffffffc02018aa:	d9268693          	addi	a3,a3,-622 # ffffffffc0206638 <commands+0xb80>
ffffffffc02018ae:	00005617          	auipc	a2,0x5
ffffffffc02018b2:	a3260613          	addi	a2,a2,-1486 # ffffffffc02062e0 <commands+0x828>
ffffffffc02018b6:	06c00593          	li	a1,108
ffffffffc02018ba:	00005517          	auipc	a0,0x5
ffffffffc02018be:	a3e50513          	addi	a0,a0,-1474 # ffffffffc02062f8 <commands+0x840>
{
ffffffffc02018c2:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02018c4:	bcffe0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc02018c8 <default_init_memmap>:
{
ffffffffc02018c8:	1141                	addi	sp,sp,-16
ffffffffc02018ca:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02018cc:	c5f1                	beqz	a1,ffffffffc0201998 <default_init_memmap+0xd0>
    for (; p != base + n; p++)
ffffffffc02018ce:	00659693          	slli	a3,a1,0x6
ffffffffc02018d2:	96aa                	add	a3,a3,a0
ffffffffc02018d4:	87aa                	mv	a5,a0
ffffffffc02018d6:	00d50f63          	beq	a0,a3,ffffffffc02018f4 <default_init_memmap+0x2c>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc02018da:	6798                	ld	a4,8(a5)
ffffffffc02018dc:	8b05                	andi	a4,a4,1
        assert(PageReserved(p));
ffffffffc02018de:	cf49                	beqz	a4,ffffffffc0201978 <default_init_memmap+0xb0>
        p->flags = p->property = 0;
ffffffffc02018e0:	0007a823          	sw	zero,16(a5)
ffffffffc02018e4:	0007b423          	sd	zero,8(a5)
ffffffffc02018e8:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p++)
ffffffffc02018ec:	04078793          	addi	a5,a5,64
ffffffffc02018f0:	fed795e3          	bne	a5,a3,ffffffffc02018da <default_init_memmap+0x12>
    base->property = n;
ffffffffc02018f4:	2581                	sext.w	a1,a1
ffffffffc02018f6:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02018f8:	4789                	li	a5,2
ffffffffc02018fa:	00850713          	addi	a4,a0,8
ffffffffc02018fe:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc0201902:	000c1697          	auipc	a3,0xc1
ffffffffc0201906:	31e68693          	addi	a3,a3,798 # ffffffffc02c2c20 <free_area>
ffffffffc020190a:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc020190c:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc020190e:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc0201912:	9db9                	addw	a1,a1,a4
ffffffffc0201914:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list))
ffffffffc0201916:	04d78a63          	beq	a5,a3,ffffffffc020196a <default_init_memmap+0xa2>
            struct Page *page = le2page(le, page_link);
ffffffffc020191a:	fe878713          	addi	a4,a5,-24
ffffffffc020191e:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list))
ffffffffc0201922:	4581                	li	a1,0
            if (base < page)
ffffffffc0201924:	00e56a63          	bltu	a0,a4,ffffffffc0201938 <default_init_memmap+0x70>
    return listelm->next;
ffffffffc0201928:	6798                	ld	a4,8(a5)
            else if (list_next(le) == &free_list)
ffffffffc020192a:	02d70263          	beq	a4,a3,ffffffffc020194e <default_init_memmap+0x86>
    for (; p != base + n; p++)
ffffffffc020192e:	87ba                	mv	a5,a4
            struct Page *page = le2page(le, page_link);
ffffffffc0201930:	fe878713          	addi	a4,a5,-24
            if (base < page)
ffffffffc0201934:	fee57ae3          	bgeu	a0,a4,ffffffffc0201928 <default_init_memmap+0x60>
ffffffffc0201938:	c199                	beqz	a1,ffffffffc020193e <default_init_memmap+0x76>
ffffffffc020193a:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc020193e:	6398                	ld	a4,0(a5)
}
ffffffffc0201940:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0201942:	e390                	sd	a2,0(a5)
ffffffffc0201944:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc0201946:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201948:	ed18                	sd	a4,24(a0)
ffffffffc020194a:	0141                	addi	sp,sp,16
ffffffffc020194c:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc020194e:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201950:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0201952:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0201954:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list)
ffffffffc0201956:	00d70663          	beq	a4,a3,ffffffffc0201962 <default_init_memmap+0x9a>
    prev->next = next->prev = elm;
ffffffffc020195a:	8832                	mv	a6,a2
ffffffffc020195c:	4585                	li	a1,1
    for (; p != base + n; p++)
ffffffffc020195e:	87ba                	mv	a5,a4
ffffffffc0201960:	bfc1                	j	ffffffffc0201930 <default_init_memmap+0x68>
}
ffffffffc0201962:	60a2                	ld	ra,8(sp)
ffffffffc0201964:	e290                	sd	a2,0(a3)
ffffffffc0201966:	0141                	addi	sp,sp,16
ffffffffc0201968:	8082                	ret
ffffffffc020196a:	60a2                	ld	ra,8(sp)
ffffffffc020196c:	e390                	sd	a2,0(a5)
ffffffffc020196e:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201970:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201972:	ed1c                	sd	a5,24(a0)
ffffffffc0201974:	0141                	addi	sp,sp,16
ffffffffc0201976:	8082                	ret
        assert(PageReserved(p));
ffffffffc0201978:	00005697          	auipc	a3,0x5
ffffffffc020197c:	cf068693          	addi	a3,a3,-784 # ffffffffc0206668 <commands+0xbb0>
ffffffffc0201980:	00005617          	auipc	a2,0x5
ffffffffc0201984:	96060613          	addi	a2,a2,-1696 # ffffffffc02062e0 <commands+0x828>
ffffffffc0201988:	04b00593          	li	a1,75
ffffffffc020198c:	00005517          	auipc	a0,0x5
ffffffffc0201990:	96c50513          	addi	a0,a0,-1684 # ffffffffc02062f8 <commands+0x840>
ffffffffc0201994:	afffe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(n > 0);
ffffffffc0201998:	00005697          	auipc	a3,0x5
ffffffffc020199c:	ca068693          	addi	a3,a3,-864 # ffffffffc0206638 <commands+0xb80>
ffffffffc02019a0:	00005617          	auipc	a2,0x5
ffffffffc02019a4:	94060613          	addi	a2,a2,-1728 # ffffffffc02062e0 <commands+0x828>
ffffffffc02019a8:	04700593          	li	a1,71
ffffffffc02019ac:	00005517          	auipc	a0,0x5
ffffffffc02019b0:	94c50513          	addi	a0,a0,-1716 # ffffffffc02062f8 <commands+0x840>
ffffffffc02019b4:	adffe0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc02019b8 <slob_free>:
static void slob_free(void *block, int size)
{
	slob_t *cur, *b = (slob_t *)block;
	unsigned long flags;

	if (!block)
ffffffffc02019b8:	c94d                	beqz	a0,ffffffffc0201a6a <slob_free+0xb2>
{
ffffffffc02019ba:	1141                	addi	sp,sp,-16
ffffffffc02019bc:	e022                	sd	s0,0(sp)
ffffffffc02019be:	e406                	sd	ra,8(sp)
ffffffffc02019c0:	842a                	mv	s0,a0
		return;

	if (size)
ffffffffc02019c2:	e9c1                	bnez	a1,ffffffffc0201a52 <slob_free+0x9a>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02019c4:	100027f3          	csrr	a5,sstatus
ffffffffc02019c8:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02019ca:	4501                	li	a0,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02019cc:	ebd9                	bnez	a5,ffffffffc0201a62 <slob_free+0xaa>
		b->units = SLOB_UNITS(size);

	/* Find reinsertion point */
	spin_lock_irqsave(&slob_lock, flags);
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc02019ce:	000c1617          	auipc	a2,0xc1
ffffffffc02019d2:	e4260613          	addi	a2,a2,-446 # ffffffffc02c2810 <slobfree>
ffffffffc02019d6:	621c                	ld	a5,0(a2)
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc02019d8:	873e                	mv	a4,a5
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc02019da:	679c                	ld	a5,8(a5)
ffffffffc02019dc:	02877a63          	bgeu	a4,s0,ffffffffc0201a10 <slob_free+0x58>
ffffffffc02019e0:	00f46463          	bltu	s0,a5,ffffffffc02019e8 <slob_free+0x30>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc02019e4:	fef76ae3          	bltu	a4,a5,ffffffffc02019d8 <slob_free+0x20>
			break;

	if (b + b->units == cur->next)
ffffffffc02019e8:	400c                	lw	a1,0(s0)
ffffffffc02019ea:	00459693          	slli	a3,a1,0x4
ffffffffc02019ee:	96a2                	add	a3,a3,s0
ffffffffc02019f0:	02d78a63          	beq	a5,a3,ffffffffc0201a24 <slob_free+0x6c>
		b->next = cur->next->next;
	}
	else
		b->next = cur->next;

	if (cur + cur->units == b)
ffffffffc02019f4:	4314                	lw	a3,0(a4)
		b->next = cur->next;
ffffffffc02019f6:	e41c                	sd	a5,8(s0)
	if (cur + cur->units == b)
ffffffffc02019f8:	00469793          	slli	a5,a3,0x4
ffffffffc02019fc:	97ba                	add	a5,a5,a4
ffffffffc02019fe:	02f40e63          	beq	s0,a5,ffffffffc0201a3a <slob_free+0x82>
	{
		cur->units += b->units;
		cur->next = b->next;
	}
	else
		cur->next = b;
ffffffffc0201a02:	e700                	sd	s0,8(a4)

	slobfree = cur;
ffffffffc0201a04:	e218                	sd	a4,0(a2)
    if (flag)
ffffffffc0201a06:	e129                	bnez	a0,ffffffffc0201a48 <slob_free+0x90>

	spin_unlock_irqrestore(&slob_lock, flags);
}
ffffffffc0201a08:	60a2                	ld	ra,8(sp)
ffffffffc0201a0a:	6402                	ld	s0,0(sp)
ffffffffc0201a0c:	0141                	addi	sp,sp,16
ffffffffc0201a0e:	8082                	ret
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201a10:	fcf764e3          	bltu	a4,a5,ffffffffc02019d8 <slob_free+0x20>
ffffffffc0201a14:	fcf472e3          	bgeu	s0,a5,ffffffffc02019d8 <slob_free+0x20>
	if (b + b->units == cur->next)
ffffffffc0201a18:	400c                	lw	a1,0(s0)
ffffffffc0201a1a:	00459693          	slli	a3,a1,0x4
ffffffffc0201a1e:	96a2                	add	a3,a3,s0
ffffffffc0201a20:	fcd79ae3          	bne	a5,a3,ffffffffc02019f4 <slob_free+0x3c>
		b->units += cur->next->units;
ffffffffc0201a24:	4394                	lw	a3,0(a5)
		b->next = cur->next->next;
ffffffffc0201a26:	679c                	ld	a5,8(a5)
		b->units += cur->next->units;
ffffffffc0201a28:	9db5                	addw	a1,a1,a3
ffffffffc0201a2a:	c00c                	sw	a1,0(s0)
	if (cur + cur->units == b)
ffffffffc0201a2c:	4314                	lw	a3,0(a4)
		b->next = cur->next->next;
ffffffffc0201a2e:	e41c                	sd	a5,8(s0)
	if (cur + cur->units == b)
ffffffffc0201a30:	00469793          	slli	a5,a3,0x4
ffffffffc0201a34:	97ba                	add	a5,a5,a4
ffffffffc0201a36:	fcf416e3          	bne	s0,a5,ffffffffc0201a02 <slob_free+0x4a>
		cur->units += b->units;
ffffffffc0201a3a:	401c                	lw	a5,0(s0)
		cur->next = b->next;
ffffffffc0201a3c:	640c                	ld	a1,8(s0)
	slobfree = cur;
ffffffffc0201a3e:	e218                	sd	a4,0(a2)
		cur->units += b->units;
ffffffffc0201a40:	9ebd                	addw	a3,a3,a5
ffffffffc0201a42:	c314                	sw	a3,0(a4)
		cur->next = b->next;
ffffffffc0201a44:	e70c                	sd	a1,8(a4)
ffffffffc0201a46:	d169                	beqz	a0,ffffffffc0201a08 <slob_free+0x50>
}
ffffffffc0201a48:	6402                	ld	s0,0(sp)
ffffffffc0201a4a:	60a2                	ld	ra,8(sp)
ffffffffc0201a4c:	0141                	addi	sp,sp,16
        intr_enable();
ffffffffc0201a4e:	f5bfe06f          	j	ffffffffc02009a8 <intr_enable>
		b->units = SLOB_UNITS(size);
ffffffffc0201a52:	25bd                	addiw	a1,a1,15
ffffffffc0201a54:	8191                	srli	a1,a1,0x4
ffffffffc0201a56:	c10c                	sw	a1,0(a0)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201a58:	100027f3          	csrr	a5,sstatus
ffffffffc0201a5c:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0201a5e:	4501                	li	a0,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201a60:	d7bd                	beqz	a5,ffffffffc02019ce <slob_free+0x16>
        intr_disable();
ffffffffc0201a62:	f4dfe0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        return 1;
ffffffffc0201a66:	4505                	li	a0,1
ffffffffc0201a68:	b79d                	j	ffffffffc02019ce <slob_free+0x16>
ffffffffc0201a6a:	8082                	ret

ffffffffc0201a6c <__slob_get_free_pages.constprop.0>:
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201a6c:	4785                	li	a5,1
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0201a6e:	1141                	addi	sp,sp,-16
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201a70:	00a7953b          	sllw	a0,a5,a0
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0201a74:	e406                	sd	ra,8(sp)
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201a76:	352000ef          	jal	ra,ffffffffc0201dc8 <alloc_pages>
	if (!page)
ffffffffc0201a7a:	c91d                	beqz	a0,ffffffffc0201ab0 <__slob_get_free_pages.constprop.0+0x44>
    return page - pages + nbase;
ffffffffc0201a7c:	000c5697          	auipc	a3,0xc5
ffffffffc0201a80:	2446b683          	ld	a3,580(a3) # ffffffffc02c6cc0 <pages>
ffffffffc0201a84:	8d15                	sub	a0,a0,a3
ffffffffc0201a86:	8519                	srai	a0,a0,0x6
ffffffffc0201a88:	00006697          	auipc	a3,0x6
ffffffffc0201a8c:	6406b683          	ld	a3,1600(a3) # ffffffffc02080c8 <nbase>
ffffffffc0201a90:	9536                	add	a0,a0,a3
    return KADDR(page2pa(page));
ffffffffc0201a92:	00c51793          	slli	a5,a0,0xc
ffffffffc0201a96:	83b1                	srli	a5,a5,0xc
ffffffffc0201a98:	000c5717          	auipc	a4,0xc5
ffffffffc0201a9c:	22073703          	ld	a4,544(a4) # ffffffffc02c6cb8 <npage>
    return page2ppn(page) << PGSHIFT;
ffffffffc0201aa0:	0532                	slli	a0,a0,0xc
    return KADDR(page2pa(page));
ffffffffc0201aa2:	00e7fa63          	bgeu	a5,a4,ffffffffc0201ab6 <__slob_get_free_pages.constprop.0+0x4a>
ffffffffc0201aa6:	000c5697          	auipc	a3,0xc5
ffffffffc0201aaa:	22a6b683          	ld	a3,554(a3) # ffffffffc02c6cd0 <va_pa_offset>
ffffffffc0201aae:	9536                	add	a0,a0,a3
}
ffffffffc0201ab0:	60a2                	ld	ra,8(sp)
ffffffffc0201ab2:	0141                	addi	sp,sp,16
ffffffffc0201ab4:	8082                	ret
ffffffffc0201ab6:	86aa                	mv	a3,a0
ffffffffc0201ab8:	00005617          	auipc	a2,0x5
ffffffffc0201abc:	c1060613          	addi	a2,a2,-1008 # ffffffffc02066c8 <default_pmm_manager+0x38>
ffffffffc0201ac0:	07100593          	li	a1,113
ffffffffc0201ac4:	00005517          	auipc	a0,0x5
ffffffffc0201ac8:	c2c50513          	addi	a0,a0,-980 # ffffffffc02066f0 <default_pmm_manager+0x60>
ffffffffc0201acc:	9c7fe0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0201ad0 <slob_alloc.constprop.0>:
static void *slob_alloc(size_t size, gfp_t gfp, int align)
ffffffffc0201ad0:	1101                	addi	sp,sp,-32
ffffffffc0201ad2:	ec06                	sd	ra,24(sp)
ffffffffc0201ad4:	e822                	sd	s0,16(sp)
ffffffffc0201ad6:	e426                	sd	s1,8(sp)
ffffffffc0201ad8:	e04a                	sd	s2,0(sp)
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc0201ada:	01050713          	addi	a4,a0,16
ffffffffc0201ade:	6785                	lui	a5,0x1
ffffffffc0201ae0:	0cf77363          	bgeu	a4,a5,ffffffffc0201ba6 <slob_alloc.constprop.0+0xd6>
	int delta = 0, units = SLOB_UNITS(size);
ffffffffc0201ae4:	00f50493          	addi	s1,a0,15
ffffffffc0201ae8:	8091                	srli	s1,s1,0x4
ffffffffc0201aea:	2481                	sext.w	s1,s1
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201aec:	10002673          	csrr	a2,sstatus
ffffffffc0201af0:	8a09                	andi	a2,a2,2
ffffffffc0201af2:	e25d                	bnez	a2,ffffffffc0201b98 <slob_alloc.constprop.0+0xc8>
	prev = slobfree;
ffffffffc0201af4:	000c1917          	auipc	s2,0xc1
ffffffffc0201af8:	d1c90913          	addi	s2,s2,-740 # ffffffffc02c2810 <slobfree>
ffffffffc0201afc:	00093683          	ld	a3,0(s2)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201b00:	669c                	ld	a5,8(a3)
		if (cur->units >= units + delta)
ffffffffc0201b02:	4398                	lw	a4,0(a5)
ffffffffc0201b04:	08975e63          	bge	a4,s1,ffffffffc0201ba0 <slob_alloc.constprop.0+0xd0>
		if (cur == slobfree)
ffffffffc0201b08:	00f68b63          	beq	a3,a5,ffffffffc0201b1e <slob_alloc.constprop.0+0x4e>
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201b0c:	6780                	ld	s0,8(a5)
		if (cur->units >= units + delta)
ffffffffc0201b0e:	4018                	lw	a4,0(s0)
ffffffffc0201b10:	02975a63          	bge	a4,s1,ffffffffc0201b44 <slob_alloc.constprop.0+0x74>
		if (cur == slobfree)
ffffffffc0201b14:	00093683          	ld	a3,0(s2)
ffffffffc0201b18:	87a2                	mv	a5,s0
ffffffffc0201b1a:	fef699e3          	bne	a3,a5,ffffffffc0201b0c <slob_alloc.constprop.0+0x3c>
    if (flag)
ffffffffc0201b1e:	ee31                	bnez	a2,ffffffffc0201b7a <slob_alloc.constprop.0+0xaa>
			cur = (slob_t *)__slob_get_free_page(gfp);
ffffffffc0201b20:	4501                	li	a0,0
ffffffffc0201b22:	f4bff0ef          	jal	ra,ffffffffc0201a6c <__slob_get_free_pages.constprop.0>
ffffffffc0201b26:	842a                	mv	s0,a0
			if (!cur)
ffffffffc0201b28:	cd05                	beqz	a0,ffffffffc0201b60 <slob_alloc.constprop.0+0x90>
			slob_free(cur, PAGE_SIZE);
ffffffffc0201b2a:	6585                	lui	a1,0x1
ffffffffc0201b2c:	e8dff0ef          	jal	ra,ffffffffc02019b8 <slob_free>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201b30:	10002673          	csrr	a2,sstatus
ffffffffc0201b34:	8a09                	andi	a2,a2,2
ffffffffc0201b36:	ee05                	bnez	a2,ffffffffc0201b6e <slob_alloc.constprop.0+0x9e>
			cur = slobfree;
ffffffffc0201b38:	00093783          	ld	a5,0(s2)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201b3c:	6780                	ld	s0,8(a5)
		if (cur->units >= units + delta)
ffffffffc0201b3e:	4018                	lw	a4,0(s0)
ffffffffc0201b40:	fc974ae3          	blt	a4,s1,ffffffffc0201b14 <slob_alloc.constprop.0+0x44>
			if (cur->units == units)	/* exact fit? */
ffffffffc0201b44:	04e48763          	beq	s1,a4,ffffffffc0201b92 <slob_alloc.constprop.0+0xc2>
				prev->next = cur + units;
ffffffffc0201b48:	00449693          	slli	a3,s1,0x4
ffffffffc0201b4c:	96a2                	add	a3,a3,s0
ffffffffc0201b4e:	e794                	sd	a3,8(a5)
				prev->next->next = cur->next;
ffffffffc0201b50:	640c                	ld	a1,8(s0)
				prev->next->units = cur->units - units;
ffffffffc0201b52:	9f05                	subw	a4,a4,s1
ffffffffc0201b54:	c298                	sw	a4,0(a3)
				prev->next->next = cur->next;
ffffffffc0201b56:	e68c                	sd	a1,8(a3)
				cur->units = units;
ffffffffc0201b58:	c004                	sw	s1,0(s0)
			slobfree = prev;
ffffffffc0201b5a:	00f93023          	sd	a5,0(s2)
    if (flag)
ffffffffc0201b5e:	e20d                	bnez	a2,ffffffffc0201b80 <slob_alloc.constprop.0+0xb0>
}
ffffffffc0201b60:	60e2                	ld	ra,24(sp)
ffffffffc0201b62:	8522                	mv	a0,s0
ffffffffc0201b64:	6442                	ld	s0,16(sp)
ffffffffc0201b66:	64a2                	ld	s1,8(sp)
ffffffffc0201b68:	6902                	ld	s2,0(sp)
ffffffffc0201b6a:	6105                	addi	sp,sp,32
ffffffffc0201b6c:	8082                	ret
        intr_disable();
ffffffffc0201b6e:	e41fe0ef          	jal	ra,ffffffffc02009ae <intr_disable>
			cur = slobfree;
ffffffffc0201b72:	00093783          	ld	a5,0(s2)
        return 1;
ffffffffc0201b76:	4605                	li	a2,1
ffffffffc0201b78:	b7d1                	j	ffffffffc0201b3c <slob_alloc.constprop.0+0x6c>
        intr_enable();
ffffffffc0201b7a:	e2ffe0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0201b7e:	b74d                	j	ffffffffc0201b20 <slob_alloc.constprop.0+0x50>
ffffffffc0201b80:	e29fe0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
}
ffffffffc0201b84:	60e2                	ld	ra,24(sp)
ffffffffc0201b86:	8522                	mv	a0,s0
ffffffffc0201b88:	6442                	ld	s0,16(sp)
ffffffffc0201b8a:	64a2                	ld	s1,8(sp)
ffffffffc0201b8c:	6902                	ld	s2,0(sp)
ffffffffc0201b8e:	6105                	addi	sp,sp,32
ffffffffc0201b90:	8082                	ret
				prev->next = cur->next; /* unlink */
ffffffffc0201b92:	6418                	ld	a4,8(s0)
ffffffffc0201b94:	e798                	sd	a4,8(a5)
ffffffffc0201b96:	b7d1                	j	ffffffffc0201b5a <slob_alloc.constprop.0+0x8a>
        intr_disable();
ffffffffc0201b98:	e17fe0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        return 1;
ffffffffc0201b9c:	4605                	li	a2,1
ffffffffc0201b9e:	bf99                	j	ffffffffc0201af4 <slob_alloc.constprop.0+0x24>
		if (cur->units >= units + delta)
ffffffffc0201ba0:	843e                	mv	s0,a5
ffffffffc0201ba2:	87b6                	mv	a5,a3
ffffffffc0201ba4:	b745                	j	ffffffffc0201b44 <slob_alloc.constprop.0+0x74>
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc0201ba6:	00005697          	auipc	a3,0x5
ffffffffc0201baa:	b5a68693          	addi	a3,a3,-1190 # ffffffffc0206700 <default_pmm_manager+0x70>
ffffffffc0201bae:	00004617          	auipc	a2,0x4
ffffffffc0201bb2:	73260613          	addi	a2,a2,1842 # ffffffffc02062e0 <commands+0x828>
ffffffffc0201bb6:	06300593          	li	a1,99
ffffffffc0201bba:	00005517          	auipc	a0,0x5
ffffffffc0201bbe:	b6650513          	addi	a0,a0,-1178 # ffffffffc0206720 <default_pmm_manager+0x90>
ffffffffc0201bc2:	8d1fe0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0201bc6 <kmalloc_init>:
	cprintf("use SLOB allocator\n");
}

inline void
kmalloc_init(void)
{
ffffffffc0201bc6:	1141                	addi	sp,sp,-16
	cprintf("use SLOB allocator\n");
ffffffffc0201bc8:	00005517          	auipc	a0,0x5
ffffffffc0201bcc:	b7050513          	addi	a0,a0,-1168 # ffffffffc0206738 <default_pmm_manager+0xa8>
{
ffffffffc0201bd0:	e406                	sd	ra,8(sp)
	cprintf("use SLOB allocator\n");
ffffffffc0201bd2:	dc6fe0ef          	jal	ra,ffffffffc0200198 <cprintf>
	slob_init();
	cprintf("kmalloc_init() succeeded!\n");
}
ffffffffc0201bd6:	60a2                	ld	ra,8(sp)
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201bd8:	00005517          	auipc	a0,0x5
ffffffffc0201bdc:	b7850513          	addi	a0,a0,-1160 # ffffffffc0206750 <default_pmm_manager+0xc0>
}
ffffffffc0201be0:	0141                	addi	sp,sp,16
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201be2:	db6fe06f          	j	ffffffffc0200198 <cprintf>

ffffffffc0201be6 <kallocated>:

size_t
kallocated(void)
{
	return slob_allocated();
}
ffffffffc0201be6:	4501                	li	a0,0
ffffffffc0201be8:	8082                	ret

ffffffffc0201bea <kmalloc>:
	return 0;
}

void *
kmalloc(size_t size)
{
ffffffffc0201bea:	1101                	addi	sp,sp,-32
ffffffffc0201bec:	e04a                	sd	s2,0(sp)
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201bee:	6905                	lui	s2,0x1
{
ffffffffc0201bf0:	e822                	sd	s0,16(sp)
ffffffffc0201bf2:	ec06                	sd	ra,24(sp)
ffffffffc0201bf4:	e426                	sd	s1,8(sp)
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201bf6:	fef90793          	addi	a5,s2,-17 # fef <_binary_obj___user_faultread_out_size-0x8f59>
{
ffffffffc0201bfa:	842a                	mv	s0,a0
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201bfc:	04a7f963          	bgeu	a5,a0,ffffffffc0201c4e <kmalloc+0x64>
	bb = slob_alloc(sizeof(bigblock_t), gfp, 0);
ffffffffc0201c00:	4561                	li	a0,24
ffffffffc0201c02:	ecfff0ef          	jal	ra,ffffffffc0201ad0 <slob_alloc.constprop.0>
ffffffffc0201c06:	84aa                	mv	s1,a0
	if (!bb)
ffffffffc0201c08:	c929                	beqz	a0,ffffffffc0201c5a <kmalloc+0x70>
	bb->order = find_order(size);
ffffffffc0201c0a:	0004079b          	sext.w	a5,s0
	int order = 0;
ffffffffc0201c0e:	4501                	li	a0,0
	for (; size > 4096; size >>= 1)
ffffffffc0201c10:	00f95763          	bge	s2,a5,ffffffffc0201c1e <kmalloc+0x34>
ffffffffc0201c14:	6705                	lui	a4,0x1
ffffffffc0201c16:	8785                	srai	a5,a5,0x1
		order++;
ffffffffc0201c18:	2505                	addiw	a0,a0,1
	for (; size > 4096; size >>= 1)
ffffffffc0201c1a:	fef74ee3          	blt	a4,a5,ffffffffc0201c16 <kmalloc+0x2c>
	bb->order = find_order(size);
ffffffffc0201c1e:	c088                	sw	a0,0(s1)
	bb->pages = (void *)__slob_get_free_pages(gfp, bb->order);
ffffffffc0201c20:	e4dff0ef          	jal	ra,ffffffffc0201a6c <__slob_get_free_pages.constprop.0>
ffffffffc0201c24:	e488                	sd	a0,8(s1)
ffffffffc0201c26:	842a                	mv	s0,a0
	if (bb->pages)
ffffffffc0201c28:	c525                	beqz	a0,ffffffffc0201c90 <kmalloc+0xa6>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201c2a:	100027f3          	csrr	a5,sstatus
ffffffffc0201c2e:	8b89                	andi	a5,a5,2
ffffffffc0201c30:	ef8d                	bnez	a5,ffffffffc0201c6a <kmalloc+0x80>
		bb->next = bigblocks;
ffffffffc0201c32:	000c5797          	auipc	a5,0xc5
ffffffffc0201c36:	06e78793          	addi	a5,a5,110 # ffffffffc02c6ca0 <bigblocks>
ffffffffc0201c3a:	6398                	ld	a4,0(a5)
		bigblocks = bb;
ffffffffc0201c3c:	e384                	sd	s1,0(a5)
		bb->next = bigblocks;
ffffffffc0201c3e:	e898                	sd	a4,16(s1)
	return __kmalloc(size, 0);
}
ffffffffc0201c40:	60e2                	ld	ra,24(sp)
ffffffffc0201c42:	8522                	mv	a0,s0
ffffffffc0201c44:	6442                	ld	s0,16(sp)
ffffffffc0201c46:	64a2                	ld	s1,8(sp)
ffffffffc0201c48:	6902                	ld	s2,0(sp)
ffffffffc0201c4a:	6105                	addi	sp,sp,32
ffffffffc0201c4c:	8082                	ret
		m = slob_alloc(size + SLOB_UNIT, gfp, 0);
ffffffffc0201c4e:	0541                	addi	a0,a0,16
ffffffffc0201c50:	e81ff0ef          	jal	ra,ffffffffc0201ad0 <slob_alloc.constprop.0>
		return m ? (void *)(m + 1) : 0;
ffffffffc0201c54:	01050413          	addi	s0,a0,16
ffffffffc0201c58:	f565                	bnez	a0,ffffffffc0201c40 <kmalloc+0x56>
ffffffffc0201c5a:	4401                	li	s0,0
}
ffffffffc0201c5c:	60e2                	ld	ra,24(sp)
ffffffffc0201c5e:	8522                	mv	a0,s0
ffffffffc0201c60:	6442                	ld	s0,16(sp)
ffffffffc0201c62:	64a2                	ld	s1,8(sp)
ffffffffc0201c64:	6902                	ld	s2,0(sp)
ffffffffc0201c66:	6105                	addi	sp,sp,32
ffffffffc0201c68:	8082                	ret
        intr_disable();
ffffffffc0201c6a:	d45fe0ef          	jal	ra,ffffffffc02009ae <intr_disable>
		bb->next = bigblocks;
ffffffffc0201c6e:	000c5797          	auipc	a5,0xc5
ffffffffc0201c72:	03278793          	addi	a5,a5,50 # ffffffffc02c6ca0 <bigblocks>
ffffffffc0201c76:	6398                	ld	a4,0(a5)
		bigblocks = bb;
ffffffffc0201c78:	e384                	sd	s1,0(a5)
		bb->next = bigblocks;
ffffffffc0201c7a:	e898                	sd	a4,16(s1)
        intr_enable();
ffffffffc0201c7c:	d2dfe0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
		return bb->pages;
ffffffffc0201c80:	6480                	ld	s0,8(s1)
}
ffffffffc0201c82:	60e2                	ld	ra,24(sp)
ffffffffc0201c84:	64a2                	ld	s1,8(sp)
ffffffffc0201c86:	8522                	mv	a0,s0
ffffffffc0201c88:	6442                	ld	s0,16(sp)
ffffffffc0201c8a:	6902                	ld	s2,0(sp)
ffffffffc0201c8c:	6105                	addi	sp,sp,32
ffffffffc0201c8e:	8082                	ret
	slob_free(bb, sizeof(bigblock_t));
ffffffffc0201c90:	45e1                	li	a1,24
ffffffffc0201c92:	8526                	mv	a0,s1
ffffffffc0201c94:	d25ff0ef          	jal	ra,ffffffffc02019b8 <slob_free>
	return __kmalloc(size, 0);
ffffffffc0201c98:	b765                	j	ffffffffc0201c40 <kmalloc+0x56>

ffffffffc0201c9a <kfree>:
void kfree(void *block)
{
	bigblock_t *bb, **last = &bigblocks;
	unsigned long flags;

	if (!block)
ffffffffc0201c9a:	c169                	beqz	a0,ffffffffc0201d5c <kfree+0xc2>
{
ffffffffc0201c9c:	1101                	addi	sp,sp,-32
ffffffffc0201c9e:	e822                	sd	s0,16(sp)
ffffffffc0201ca0:	ec06                	sd	ra,24(sp)
ffffffffc0201ca2:	e426                	sd	s1,8(sp)
		return;

	if (!((unsigned long)block & (PAGE_SIZE - 1)))
ffffffffc0201ca4:	03451793          	slli	a5,a0,0x34
ffffffffc0201ca8:	842a                	mv	s0,a0
ffffffffc0201caa:	e3d9                	bnez	a5,ffffffffc0201d30 <kfree+0x96>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201cac:	100027f3          	csrr	a5,sstatus
ffffffffc0201cb0:	8b89                	andi	a5,a5,2
ffffffffc0201cb2:	e7d9                	bnez	a5,ffffffffc0201d40 <kfree+0xa6>
	{
		/* might be on the big block list */
		spin_lock_irqsave(&block_lock, flags);
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201cb4:	000c5797          	auipc	a5,0xc5
ffffffffc0201cb8:	fec7b783          	ld	a5,-20(a5) # ffffffffc02c6ca0 <bigblocks>
    return 0;
ffffffffc0201cbc:	4601                	li	a2,0
ffffffffc0201cbe:	cbad                	beqz	a5,ffffffffc0201d30 <kfree+0x96>
	bigblock_t *bb, **last = &bigblocks;
ffffffffc0201cc0:	000c5697          	auipc	a3,0xc5
ffffffffc0201cc4:	fe068693          	addi	a3,a3,-32 # ffffffffc02c6ca0 <bigblocks>
ffffffffc0201cc8:	a021                	j	ffffffffc0201cd0 <kfree+0x36>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201cca:	01048693          	addi	a3,s1,16
ffffffffc0201cce:	c3a5                	beqz	a5,ffffffffc0201d2e <kfree+0x94>
		{
			if (bb->pages == block)
ffffffffc0201cd0:	6798                	ld	a4,8(a5)
ffffffffc0201cd2:	84be                	mv	s1,a5
			{
				*last = bb->next;
ffffffffc0201cd4:	6b9c                	ld	a5,16(a5)
			if (bb->pages == block)
ffffffffc0201cd6:	fe871ae3          	bne	a4,s0,ffffffffc0201cca <kfree+0x30>
				*last = bb->next;
ffffffffc0201cda:	e29c                	sd	a5,0(a3)
    if (flag)
ffffffffc0201cdc:	ee2d                	bnez	a2,ffffffffc0201d56 <kfree+0xbc>
    return pa2page(PADDR(kva));
ffffffffc0201cde:	c02007b7          	lui	a5,0xc0200
				spin_unlock_irqrestore(&block_lock, flags);
				__slob_free_pages((unsigned long)block, bb->order);
ffffffffc0201ce2:	4098                	lw	a4,0(s1)
ffffffffc0201ce4:	08f46963          	bltu	s0,a5,ffffffffc0201d76 <kfree+0xdc>
ffffffffc0201ce8:	000c5697          	auipc	a3,0xc5
ffffffffc0201cec:	fe86b683          	ld	a3,-24(a3) # ffffffffc02c6cd0 <va_pa_offset>
ffffffffc0201cf0:	8c15                	sub	s0,s0,a3
    if (PPN(pa) >= npage)
ffffffffc0201cf2:	8031                	srli	s0,s0,0xc
ffffffffc0201cf4:	000c5797          	auipc	a5,0xc5
ffffffffc0201cf8:	fc47b783          	ld	a5,-60(a5) # ffffffffc02c6cb8 <npage>
ffffffffc0201cfc:	06f47163          	bgeu	s0,a5,ffffffffc0201d5e <kfree+0xc4>
    return &pages[PPN(pa) - nbase];
ffffffffc0201d00:	00006517          	auipc	a0,0x6
ffffffffc0201d04:	3c853503          	ld	a0,968(a0) # ffffffffc02080c8 <nbase>
ffffffffc0201d08:	8c09                	sub	s0,s0,a0
ffffffffc0201d0a:	041a                	slli	s0,s0,0x6
	free_pages(kva2page(kva), 1 << order);
ffffffffc0201d0c:	000c5517          	auipc	a0,0xc5
ffffffffc0201d10:	fb453503          	ld	a0,-76(a0) # ffffffffc02c6cc0 <pages>
ffffffffc0201d14:	4585                	li	a1,1
ffffffffc0201d16:	9522                	add	a0,a0,s0
ffffffffc0201d18:	00e595bb          	sllw	a1,a1,a4
ffffffffc0201d1c:	0ea000ef          	jal	ra,ffffffffc0201e06 <free_pages>
		spin_unlock_irqrestore(&block_lock, flags);
	}

	slob_free((slob_t *)block - 1, 0);
	return;
}
ffffffffc0201d20:	6442                	ld	s0,16(sp)
ffffffffc0201d22:	60e2                	ld	ra,24(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201d24:	8526                	mv	a0,s1
}
ffffffffc0201d26:	64a2                	ld	s1,8(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201d28:	45e1                	li	a1,24
}
ffffffffc0201d2a:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201d2c:	b171                	j	ffffffffc02019b8 <slob_free>
ffffffffc0201d2e:	e20d                	bnez	a2,ffffffffc0201d50 <kfree+0xb6>
ffffffffc0201d30:	ff040513          	addi	a0,s0,-16
}
ffffffffc0201d34:	6442                	ld	s0,16(sp)
ffffffffc0201d36:	60e2                	ld	ra,24(sp)
ffffffffc0201d38:	64a2                	ld	s1,8(sp)
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201d3a:	4581                	li	a1,0
}
ffffffffc0201d3c:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201d3e:	b9ad                	j	ffffffffc02019b8 <slob_free>
        intr_disable();
ffffffffc0201d40:	c6ffe0ef          	jal	ra,ffffffffc02009ae <intr_disable>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201d44:	000c5797          	auipc	a5,0xc5
ffffffffc0201d48:	f5c7b783          	ld	a5,-164(a5) # ffffffffc02c6ca0 <bigblocks>
        return 1;
ffffffffc0201d4c:	4605                	li	a2,1
ffffffffc0201d4e:	fbad                	bnez	a5,ffffffffc0201cc0 <kfree+0x26>
        intr_enable();
ffffffffc0201d50:	c59fe0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0201d54:	bff1                	j	ffffffffc0201d30 <kfree+0x96>
ffffffffc0201d56:	c53fe0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0201d5a:	b751                	j	ffffffffc0201cde <kfree+0x44>
ffffffffc0201d5c:	8082                	ret
        panic("pa2page called with invalid pa");
ffffffffc0201d5e:	00005617          	auipc	a2,0x5
ffffffffc0201d62:	a3a60613          	addi	a2,a2,-1478 # ffffffffc0206798 <default_pmm_manager+0x108>
ffffffffc0201d66:	06900593          	li	a1,105
ffffffffc0201d6a:	00005517          	auipc	a0,0x5
ffffffffc0201d6e:	98650513          	addi	a0,a0,-1658 # ffffffffc02066f0 <default_pmm_manager+0x60>
ffffffffc0201d72:	f20fe0ef          	jal	ra,ffffffffc0200492 <__panic>
    return pa2page(PADDR(kva));
ffffffffc0201d76:	86a2                	mv	a3,s0
ffffffffc0201d78:	00005617          	auipc	a2,0x5
ffffffffc0201d7c:	9f860613          	addi	a2,a2,-1544 # ffffffffc0206770 <default_pmm_manager+0xe0>
ffffffffc0201d80:	07700593          	li	a1,119
ffffffffc0201d84:	00005517          	auipc	a0,0x5
ffffffffc0201d88:	96c50513          	addi	a0,a0,-1684 # ffffffffc02066f0 <default_pmm_manager+0x60>
ffffffffc0201d8c:	f06fe0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0201d90 <pa2page.part.0>:
pa2page(uintptr_t pa)
ffffffffc0201d90:	1141                	addi	sp,sp,-16
        panic("pa2page called with invalid pa");
ffffffffc0201d92:	00005617          	auipc	a2,0x5
ffffffffc0201d96:	a0660613          	addi	a2,a2,-1530 # ffffffffc0206798 <default_pmm_manager+0x108>
ffffffffc0201d9a:	06900593          	li	a1,105
ffffffffc0201d9e:	00005517          	auipc	a0,0x5
ffffffffc0201da2:	95250513          	addi	a0,a0,-1710 # ffffffffc02066f0 <default_pmm_manager+0x60>
pa2page(uintptr_t pa)
ffffffffc0201da6:	e406                	sd	ra,8(sp)
        panic("pa2page called with invalid pa");
ffffffffc0201da8:	eeafe0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0201dac <pte2page.part.0>:
pte2page(pte_t pte)
ffffffffc0201dac:	1141                	addi	sp,sp,-16
        panic("pte2page called with invalid pte");
ffffffffc0201dae:	00005617          	auipc	a2,0x5
ffffffffc0201db2:	a0a60613          	addi	a2,a2,-1526 # ffffffffc02067b8 <default_pmm_manager+0x128>
ffffffffc0201db6:	07f00593          	li	a1,127
ffffffffc0201dba:	00005517          	auipc	a0,0x5
ffffffffc0201dbe:	93650513          	addi	a0,a0,-1738 # ffffffffc02066f0 <default_pmm_manager+0x60>
pte2page(pte_t pte)
ffffffffc0201dc2:	e406                	sd	ra,8(sp)
        panic("pte2page called with invalid pte");
ffffffffc0201dc4:	ecefe0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0201dc8 <alloc_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201dc8:	100027f3          	csrr	a5,sstatus
ffffffffc0201dcc:	8b89                	andi	a5,a5,2
ffffffffc0201dce:	e799                	bnez	a5,ffffffffc0201ddc <alloc_pages+0x14>
{
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc0201dd0:	000c5797          	auipc	a5,0xc5
ffffffffc0201dd4:	ef87b783          	ld	a5,-264(a5) # ffffffffc02c6cc8 <pmm_manager>
ffffffffc0201dd8:	6f9c                	ld	a5,24(a5)
ffffffffc0201dda:	8782                	jr	a5
{
ffffffffc0201ddc:	1141                	addi	sp,sp,-16
ffffffffc0201dde:	e406                	sd	ra,8(sp)
ffffffffc0201de0:	e022                	sd	s0,0(sp)
ffffffffc0201de2:	842a                	mv	s0,a0
        intr_disable();
ffffffffc0201de4:	bcbfe0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201de8:	000c5797          	auipc	a5,0xc5
ffffffffc0201dec:	ee07b783          	ld	a5,-288(a5) # ffffffffc02c6cc8 <pmm_manager>
ffffffffc0201df0:	6f9c                	ld	a5,24(a5)
ffffffffc0201df2:	8522                	mv	a0,s0
ffffffffc0201df4:	9782                	jalr	a5
ffffffffc0201df6:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201df8:	bb1fe0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc0201dfc:	60a2                	ld	ra,8(sp)
ffffffffc0201dfe:	8522                	mv	a0,s0
ffffffffc0201e00:	6402                	ld	s0,0(sp)
ffffffffc0201e02:	0141                	addi	sp,sp,16
ffffffffc0201e04:	8082                	ret

ffffffffc0201e06 <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201e06:	100027f3          	csrr	a5,sstatus
ffffffffc0201e0a:	8b89                	andi	a5,a5,2
ffffffffc0201e0c:	e799                	bnez	a5,ffffffffc0201e1a <free_pages+0x14>
void free_pages(struct Page *base, size_t n)
{
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc0201e0e:	000c5797          	auipc	a5,0xc5
ffffffffc0201e12:	eba7b783          	ld	a5,-326(a5) # ffffffffc02c6cc8 <pmm_manager>
ffffffffc0201e16:	739c                	ld	a5,32(a5)
ffffffffc0201e18:	8782                	jr	a5
{
ffffffffc0201e1a:	1101                	addi	sp,sp,-32
ffffffffc0201e1c:	ec06                	sd	ra,24(sp)
ffffffffc0201e1e:	e822                	sd	s0,16(sp)
ffffffffc0201e20:	e426                	sd	s1,8(sp)
ffffffffc0201e22:	842a                	mv	s0,a0
ffffffffc0201e24:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc0201e26:	b89fe0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0201e2a:	000c5797          	auipc	a5,0xc5
ffffffffc0201e2e:	e9e7b783          	ld	a5,-354(a5) # ffffffffc02c6cc8 <pmm_manager>
ffffffffc0201e32:	739c                	ld	a5,32(a5)
ffffffffc0201e34:	85a6                	mv	a1,s1
ffffffffc0201e36:	8522                	mv	a0,s0
ffffffffc0201e38:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc0201e3a:	6442                	ld	s0,16(sp)
ffffffffc0201e3c:	60e2                	ld	ra,24(sp)
ffffffffc0201e3e:	64a2                	ld	s1,8(sp)
ffffffffc0201e40:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0201e42:	b67fe06f          	j	ffffffffc02009a8 <intr_enable>

ffffffffc0201e46 <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201e46:	100027f3          	csrr	a5,sstatus
ffffffffc0201e4a:	8b89                	andi	a5,a5,2
ffffffffc0201e4c:	e799                	bnez	a5,ffffffffc0201e5a <nr_free_pages+0x14>
{
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc0201e4e:	000c5797          	auipc	a5,0xc5
ffffffffc0201e52:	e7a7b783          	ld	a5,-390(a5) # ffffffffc02c6cc8 <pmm_manager>
ffffffffc0201e56:	779c                	ld	a5,40(a5)
ffffffffc0201e58:	8782                	jr	a5
{
ffffffffc0201e5a:	1141                	addi	sp,sp,-16
ffffffffc0201e5c:	e406                	sd	ra,8(sp)
ffffffffc0201e5e:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc0201e60:	b4ffe0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0201e64:	000c5797          	auipc	a5,0xc5
ffffffffc0201e68:	e647b783          	ld	a5,-412(a5) # ffffffffc02c6cc8 <pmm_manager>
ffffffffc0201e6c:	779c                	ld	a5,40(a5)
ffffffffc0201e6e:	9782                	jalr	a5
ffffffffc0201e70:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201e72:	b37fe0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc0201e76:	60a2                	ld	ra,8(sp)
ffffffffc0201e78:	8522                	mv	a0,s0
ffffffffc0201e7a:	6402                	ld	s0,0(sp)
ffffffffc0201e7c:	0141                	addi	sp,sp,16
ffffffffc0201e7e:	8082                	ret

ffffffffc0201e80 <get_pte>:
//  la:     the linear address need to map
//  create: a logical value to decide if alloc a page for PT
// return vaule: the kernel virtual address of this pte
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create)
{
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201e80:	01e5d793          	srli	a5,a1,0x1e
ffffffffc0201e84:	1ff7f793          	andi	a5,a5,511
{
ffffffffc0201e88:	7139                	addi	sp,sp,-64
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201e8a:	078e                	slli	a5,a5,0x3
{
ffffffffc0201e8c:	f426                	sd	s1,40(sp)
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201e8e:	00f504b3          	add	s1,a0,a5
    if (!(*pdep1 & PTE_V))
ffffffffc0201e92:	6094                	ld	a3,0(s1)
{
ffffffffc0201e94:	f04a                	sd	s2,32(sp)
ffffffffc0201e96:	ec4e                	sd	s3,24(sp)
ffffffffc0201e98:	e852                	sd	s4,16(sp)
ffffffffc0201e9a:	fc06                	sd	ra,56(sp)
ffffffffc0201e9c:	f822                	sd	s0,48(sp)
ffffffffc0201e9e:	e456                	sd	s5,8(sp)
ffffffffc0201ea0:	e05a                	sd	s6,0(sp)
    if (!(*pdep1 & PTE_V))
ffffffffc0201ea2:	0016f793          	andi	a5,a3,1
{
ffffffffc0201ea6:	892e                	mv	s2,a1
ffffffffc0201ea8:	8a32                	mv	s4,a2
ffffffffc0201eaa:	000c5997          	auipc	s3,0xc5
ffffffffc0201eae:	e0e98993          	addi	s3,s3,-498 # ffffffffc02c6cb8 <npage>
    if (!(*pdep1 & PTE_V))
ffffffffc0201eb2:	efbd                	bnez	a5,ffffffffc0201f30 <get_pte+0xb0>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201eb4:	14060c63          	beqz	a2,ffffffffc020200c <get_pte+0x18c>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201eb8:	100027f3          	csrr	a5,sstatus
ffffffffc0201ebc:	8b89                	andi	a5,a5,2
ffffffffc0201ebe:	14079963          	bnez	a5,ffffffffc0202010 <get_pte+0x190>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201ec2:	000c5797          	auipc	a5,0xc5
ffffffffc0201ec6:	e067b783          	ld	a5,-506(a5) # ffffffffc02c6cc8 <pmm_manager>
ffffffffc0201eca:	6f9c                	ld	a5,24(a5)
ffffffffc0201ecc:	4505                	li	a0,1
ffffffffc0201ece:	9782                	jalr	a5
ffffffffc0201ed0:	842a                	mv	s0,a0
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201ed2:	12040d63          	beqz	s0,ffffffffc020200c <get_pte+0x18c>
    return page - pages + nbase;
ffffffffc0201ed6:	000c5b17          	auipc	s6,0xc5
ffffffffc0201eda:	deab0b13          	addi	s6,s6,-534 # ffffffffc02c6cc0 <pages>
ffffffffc0201ede:	000b3503          	ld	a0,0(s6)
ffffffffc0201ee2:	00080ab7          	lui	s5,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201ee6:	000c5997          	auipc	s3,0xc5
ffffffffc0201eea:	dd298993          	addi	s3,s3,-558 # ffffffffc02c6cb8 <npage>
ffffffffc0201eee:	40a40533          	sub	a0,s0,a0
ffffffffc0201ef2:	8519                	srai	a0,a0,0x6
ffffffffc0201ef4:	9556                	add	a0,a0,s5
ffffffffc0201ef6:	0009b703          	ld	a4,0(s3)
ffffffffc0201efa:	00c51793          	slli	a5,a0,0xc
    page->ref = val;
ffffffffc0201efe:	4685                	li	a3,1
ffffffffc0201f00:	c014                	sw	a3,0(s0)
ffffffffc0201f02:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0201f04:	0532                	slli	a0,a0,0xc
ffffffffc0201f06:	16e7f763          	bgeu	a5,a4,ffffffffc0202074 <get_pte+0x1f4>
ffffffffc0201f0a:	000c5797          	auipc	a5,0xc5
ffffffffc0201f0e:	dc67b783          	ld	a5,-570(a5) # ffffffffc02c6cd0 <va_pa_offset>
ffffffffc0201f12:	6605                	lui	a2,0x1
ffffffffc0201f14:	4581                	li	a1,0
ffffffffc0201f16:	953e                	add	a0,a0,a5
ffffffffc0201f18:	10d030ef          	jal	ra,ffffffffc0205824 <memset>
    return page - pages + nbase;
ffffffffc0201f1c:	000b3683          	ld	a3,0(s6)
ffffffffc0201f20:	40d406b3          	sub	a3,s0,a3
ffffffffc0201f24:	8699                	srai	a3,a3,0x6
ffffffffc0201f26:	96d6                	add	a3,a3,s5
}

// construct PTE from a page and permission bits
static inline pte_t pte_create(uintptr_t ppn, int type)
{
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0201f28:	06aa                	slli	a3,a3,0xa
ffffffffc0201f2a:	0116e693          	ori	a3,a3,17
        *pdep1 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0201f2e:	e094                	sd	a3,0(s1)
    }

    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0201f30:	77fd                	lui	a5,0xfffff
ffffffffc0201f32:	068a                	slli	a3,a3,0x2
ffffffffc0201f34:	0009b703          	ld	a4,0(s3)
ffffffffc0201f38:	8efd                	and	a3,a3,a5
ffffffffc0201f3a:	00c6d793          	srli	a5,a3,0xc
ffffffffc0201f3e:	10e7ff63          	bgeu	a5,a4,ffffffffc020205c <get_pte+0x1dc>
ffffffffc0201f42:	000c5a97          	auipc	s5,0xc5
ffffffffc0201f46:	d8ea8a93          	addi	s5,s5,-626 # ffffffffc02c6cd0 <va_pa_offset>
ffffffffc0201f4a:	000ab403          	ld	s0,0(s5)
ffffffffc0201f4e:	01595793          	srli	a5,s2,0x15
ffffffffc0201f52:	1ff7f793          	andi	a5,a5,511
ffffffffc0201f56:	96a2                	add	a3,a3,s0
ffffffffc0201f58:	00379413          	slli	s0,a5,0x3
ffffffffc0201f5c:	9436                	add	s0,s0,a3
    if (!(*pdep0 & PTE_V))
ffffffffc0201f5e:	6014                	ld	a3,0(s0)
ffffffffc0201f60:	0016f793          	andi	a5,a3,1
ffffffffc0201f64:	ebad                	bnez	a5,ffffffffc0201fd6 <get_pte+0x156>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201f66:	0a0a0363          	beqz	s4,ffffffffc020200c <get_pte+0x18c>
ffffffffc0201f6a:	100027f3          	csrr	a5,sstatus
ffffffffc0201f6e:	8b89                	andi	a5,a5,2
ffffffffc0201f70:	efcd                	bnez	a5,ffffffffc020202a <get_pte+0x1aa>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201f72:	000c5797          	auipc	a5,0xc5
ffffffffc0201f76:	d567b783          	ld	a5,-682(a5) # ffffffffc02c6cc8 <pmm_manager>
ffffffffc0201f7a:	6f9c                	ld	a5,24(a5)
ffffffffc0201f7c:	4505                	li	a0,1
ffffffffc0201f7e:	9782                	jalr	a5
ffffffffc0201f80:	84aa                	mv	s1,a0
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201f82:	c4c9                	beqz	s1,ffffffffc020200c <get_pte+0x18c>
    return page - pages + nbase;
ffffffffc0201f84:	000c5b17          	auipc	s6,0xc5
ffffffffc0201f88:	d3cb0b13          	addi	s6,s6,-708 # ffffffffc02c6cc0 <pages>
ffffffffc0201f8c:	000b3503          	ld	a0,0(s6)
ffffffffc0201f90:	00080a37          	lui	s4,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201f94:	0009b703          	ld	a4,0(s3)
ffffffffc0201f98:	40a48533          	sub	a0,s1,a0
ffffffffc0201f9c:	8519                	srai	a0,a0,0x6
ffffffffc0201f9e:	9552                	add	a0,a0,s4
ffffffffc0201fa0:	00c51793          	slli	a5,a0,0xc
    page->ref = val;
ffffffffc0201fa4:	4685                	li	a3,1
ffffffffc0201fa6:	c094                	sw	a3,0(s1)
ffffffffc0201fa8:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0201faa:	0532                	slli	a0,a0,0xc
ffffffffc0201fac:	0ee7f163          	bgeu	a5,a4,ffffffffc020208e <get_pte+0x20e>
ffffffffc0201fb0:	000ab783          	ld	a5,0(s5)
ffffffffc0201fb4:	6605                	lui	a2,0x1
ffffffffc0201fb6:	4581                	li	a1,0
ffffffffc0201fb8:	953e                	add	a0,a0,a5
ffffffffc0201fba:	06b030ef          	jal	ra,ffffffffc0205824 <memset>
    return page - pages + nbase;
ffffffffc0201fbe:	000b3683          	ld	a3,0(s6)
ffffffffc0201fc2:	40d486b3          	sub	a3,s1,a3
ffffffffc0201fc6:	8699                	srai	a3,a3,0x6
ffffffffc0201fc8:	96d2                	add	a3,a3,s4
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0201fca:	06aa                	slli	a3,a3,0xa
ffffffffc0201fcc:	0116e693          	ori	a3,a3,17
        *pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0201fd0:	e014                	sd	a3,0(s0)
    }
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0201fd2:	0009b703          	ld	a4,0(s3)
ffffffffc0201fd6:	068a                	slli	a3,a3,0x2
ffffffffc0201fd8:	757d                	lui	a0,0xfffff
ffffffffc0201fda:	8ee9                	and	a3,a3,a0
ffffffffc0201fdc:	00c6d793          	srli	a5,a3,0xc
ffffffffc0201fe0:	06e7f263          	bgeu	a5,a4,ffffffffc0202044 <get_pte+0x1c4>
ffffffffc0201fe4:	000ab503          	ld	a0,0(s5)
ffffffffc0201fe8:	00c95913          	srli	s2,s2,0xc
ffffffffc0201fec:	1ff97913          	andi	s2,s2,511
ffffffffc0201ff0:	96aa                	add	a3,a3,a0
ffffffffc0201ff2:	00391513          	slli	a0,s2,0x3
ffffffffc0201ff6:	9536                	add	a0,a0,a3
}
ffffffffc0201ff8:	70e2                	ld	ra,56(sp)
ffffffffc0201ffa:	7442                	ld	s0,48(sp)
ffffffffc0201ffc:	74a2                	ld	s1,40(sp)
ffffffffc0201ffe:	7902                	ld	s2,32(sp)
ffffffffc0202000:	69e2                	ld	s3,24(sp)
ffffffffc0202002:	6a42                	ld	s4,16(sp)
ffffffffc0202004:	6aa2                	ld	s5,8(sp)
ffffffffc0202006:	6b02                	ld	s6,0(sp)
ffffffffc0202008:	6121                	addi	sp,sp,64
ffffffffc020200a:	8082                	ret
            return NULL;
ffffffffc020200c:	4501                	li	a0,0
ffffffffc020200e:	b7ed                	j	ffffffffc0201ff8 <get_pte+0x178>
        intr_disable();
ffffffffc0202010:	99ffe0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202014:	000c5797          	auipc	a5,0xc5
ffffffffc0202018:	cb47b783          	ld	a5,-844(a5) # ffffffffc02c6cc8 <pmm_manager>
ffffffffc020201c:	6f9c                	ld	a5,24(a5)
ffffffffc020201e:	4505                	li	a0,1
ffffffffc0202020:	9782                	jalr	a5
ffffffffc0202022:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202024:	985fe0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0202028:	b56d                	j	ffffffffc0201ed2 <get_pte+0x52>
        intr_disable();
ffffffffc020202a:	985fe0ef          	jal	ra,ffffffffc02009ae <intr_disable>
ffffffffc020202e:	000c5797          	auipc	a5,0xc5
ffffffffc0202032:	c9a7b783          	ld	a5,-870(a5) # ffffffffc02c6cc8 <pmm_manager>
ffffffffc0202036:	6f9c                	ld	a5,24(a5)
ffffffffc0202038:	4505                	li	a0,1
ffffffffc020203a:	9782                	jalr	a5
ffffffffc020203c:	84aa                	mv	s1,a0
        intr_enable();
ffffffffc020203e:	96bfe0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0202042:	b781                	j	ffffffffc0201f82 <get_pte+0x102>
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0202044:	00004617          	auipc	a2,0x4
ffffffffc0202048:	68460613          	addi	a2,a2,1668 # ffffffffc02066c8 <default_pmm_manager+0x38>
ffffffffc020204c:	0fa00593          	li	a1,250
ffffffffc0202050:	00004517          	auipc	a0,0x4
ffffffffc0202054:	79050513          	addi	a0,a0,1936 # ffffffffc02067e0 <default_pmm_manager+0x150>
ffffffffc0202058:	c3afe0ef          	jal	ra,ffffffffc0200492 <__panic>
    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc020205c:	00004617          	auipc	a2,0x4
ffffffffc0202060:	66c60613          	addi	a2,a2,1644 # ffffffffc02066c8 <default_pmm_manager+0x38>
ffffffffc0202064:	0ed00593          	li	a1,237
ffffffffc0202068:	00004517          	auipc	a0,0x4
ffffffffc020206c:	77850513          	addi	a0,a0,1912 # ffffffffc02067e0 <default_pmm_manager+0x150>
ffffffffc0202070:	c22fe0ef          	jal	ra,ffffffffc0200492 <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0202074:	86aa                	mv	a3,a0
ffffffffc0202076:	00004617          	auipc	a2,0x4
ffffffffc020207a:	65260613          	addi	a2,a2,1618 # ffffffffc02066c8 <default_pmm_manager+0x38>
ffffffffc020207e:	0e900593          	li	a1,233
ffffffffc0202082:	00004517          	auipc	a0,0x4
ffffffffc0202086:	75e50513          	addi	a0,a0,1886 # ffffffffc02067e0 <default_pmm_manager+0x150>
ffffffffc020208a:	c08fe0ef          	jal	ra,ffffffffc0200492 <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc020208e:	86aa                	mv	a3,a0
ffffffffc0202090:	00004617          	auipc	a2,0x4
ffffffffc0202094:	63860613          	addi	a2,a2,1592 # ffffffffc02066c8 <default_pmm_manager+0x38>
ffffffffc0202098:	0f700593          	li	a1,247
ffffffffc020209c:	00004517          	auipc	a0,0x4
ffffffffc02020a0:	74450513          	addi	a0,a0,1860 # ffffffffc02067e0 <default_pmm_manager+0x150>
ffffffffc02020a4:	beefe0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc02020a8 <get_page>:

// get_page - get related Page struct for linear address la using PDT pgdir
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store)
{
ffffffffc02020a8:	1141                	addi	sp,sp,-16
ffffffffc02020aa:	e022                	sd	s0,0(sp)
ffffffffc02020ac:	8432                	mv	s0,a2
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc02020ae:	4601                	li	a2,0
{
ffffffffc02020b0:	e406                	sd	ra,8(sp)
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc02020b2:	dcfff0ef          	jal	ra,ffffffffc0201e80 <get_pte>
    if (ptep_store != NULL)
ffffffffc02020b6:	c011                	beqz	s0,ffffffffc02020ba <get_page+0x12>
    {
        *ptep_store = ptep;
ffffffffc02020b8:	e008                	sd	a0,0(s0)
    }
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc02020ba:	c511                	beqz	a0,ffffffffc02020c6 <get_page+0x1e>
ffffffffc02020bc:	611c                	ld	a5,0(a0)
    {
        return pte2page(*ptep);
    }
    return NULL;
ffffffffc02020be:	4501                	li	a0,0
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc02020c0:	0017f713          	andi	a4,a5,1
ffffffffc02020c4:	e709                	bnez	a4,ffffffffc02020ce <get_page+0x26>
}
ffffffffc02020c6:	60a2                	ld	ra,8(sp)
ffffffffc02020c8:	6402                	ld	s0,0(sp)
ffffffffc02020ca:	0141                	addi	sp,sp,16
ffffffffc02020cc:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc02020ce:	078a                	slli	a5,a5,0x2
ffffffffc02020d0:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02020d2:	000c5717          	auipc	a4,0xc5
ffffffffc02020d6:	be673703          	ld	a4,-1050(a4) # ffffffffc02c6cb8 <npage>
ffffffffc02020da:	00e7ff63          	bgeu	a5,a4,ffffffffc02020f8 <get_page+0x50>
ffffffffc02020de:	60a2                	ld	ra,8(sp)
ffffffffc02020e0:	6402                	ld	s0,0(sp)
    return &pages[PPN(pa) - nbase];
ffffffffc02020e2:	fff80537          	lui	a0,0xfff80
ffffffffc02020e6:	97aa                	add	a5,a5,a0
ffffffffc02020e8:	079a                	slli	a5,a5,0x6
ffffffffc02020ea:	000c5517          	auipc	a0,0xc5
ffffffffc02020ee:	bd653503          	ld	a0,-1066(a0) # ffffffffc02c6cc0 <pages>
ffffffffc02020f2:	953e                	add	a0,a0,a5
ffffffffc02020f4:	0141                	addi	sp,sp,16
ffffffffc02020f6:	8082                	ret
ffffffffc02020f8:	c99ff0ef          	jal	ra,ffffffffc0201d90 <pa2page.part.0>

ffffffffc02020fc <unmap_range>:
        tlb_invalidate(pgdir, la); //(6) flush tlb
    }
}

void unmap_range(pde_t *pgdir, uintptr_t start, uintptr_t end)
{
ffffffffc02020fc:	7159                	addi	sp,sp,-112
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02020fe:	00c5e7b3          	or	a5,a1,a2
{
ffffffffc0202102:	f486                	sd	ra,104(sp)
ffffffffc0202104:	f0a2                	sd	s0,96(sp)
ffffffffc0202106:	eca6                	sd	s1,88(sp)
ffffffffc0202108:	e8ca                	sd	s2,80(sp)
ffffffffc020210a:	e4ce                	sd	s3,72(sp)
ffffffffc020210c:	e0d2                	sd	s4,64(sp)
ffffffffc020210e:	fc56                	sd	s5,56(sp)
ffffffffc0202110:	f85a                	sd	s6,48(sp)
ffffffffc0202112:	f45e                	sd	s7,40(sp)
ffffffffc0202114:	f062                	sd	s8,32(sp)
ffffffffc0202116:	ec66                	sd	s9,24(sp)
ffffffffc0202118:	e86a                	sd	s10,16(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc020211a:	17d2                	slli	a5,a5,0x34
ffffffffc020211c:	e3ed                	bnez	a5,ffffffffc02021fe <unmap_range+0x102>
    assert(USER_ACCESS(start, end));
ffffffffc020211e:	002007b7          	lui	a5,0x200
ffffffffc0202122:	842e                	mv	s0,a1
ffffffffc0202124:	0ef5ed63          	bltu	a1,a5,ffffffffc020221e <unmap_range+0x122>
ffffffffc0202128:	8932                	mv	s2,a2
ffffffffc020212a:	0ec5fa63          	bgeu	a1,a2,ffffffffc020221e <unmap_range+0x122>
ffffffffc020212e:	4785                	li	a5,1
ffffffffc0202130:	07fe                	slli	a5,a5,0x1f
ffffffffc0202132:	0ec7e663          	bltu	a5,a2,ffffffffc020221e <unmap_range+0x122>
ffffffffc0202136:	89aa                	mv	s3,a0
        }
        if (*ptep != 0)
        {
            page_remove_pte(pgdir, start, ptep);
        }
        start += PGSIZE;
ffffffffc0202138:	6a05                	lui	s4,0x1
    if (PPN(pa) >= npage)
ffffffffc020213a:	000c5c97          	auipc	s9,0xc5
ffffffffc020213e:	b7ec8c93          	addi	s9,s9,-1154 # ffffffffc02c6cb8 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc0202142:	000c5c17          	auipc	s8,0xc5
ffffffffc0202146:	b7ec0c13          	addi	s8,s8,-1154 # ffffffffc02c6cc0 <pages>
ffffffffc020214a:	fff80bb7          	lui	s7,0xfff80
        pmm_manager->free_pages(base, n);
ffffffffc020214e:	000c5d17          	auipc	s10,0xc5
ffffffffc0202152:	b7ad0d13          	addi	s10,s10,-1158 # ffffffffc02c6cc8 <pmm_manager>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc0202156:	00200b37          	lui	s6,0x200
ffffffffc020215a:	ffe00ab7          	lui	s5,0xffe00
        pte_t *ptep = get_pte(pgdir, start, 0);
ffffffffc020215e:	4601                	li	a2,0
ffffffffc0202160:	85a2                	mv	a1,s0
ffffffffc0202162:	854e                	mv	a0,s3
ffffffffc0202164:	d1dff0ef          	jal	ra,ffffffffc0201e80 <get_pte>
ffffffffc0202168:	84aa                	mv	s1,a0
        if (ptep == NULL)
ffffffffc020216a:	cd29                	beqz	a0,ffffffffc02021c4 <unmap_range+0xc8>
        if (*ptep != 0)
ffffffffc020216c:	611c                	ld	a5,0(a0)
ffffffffc020216e:	e395                	bnez	a5,ffffffffc0202192 <unmap_range+0x96>
        start += PGSIZE;
ffffffffc0202170:	9452                	add	s0,s0,s4
    } while (start != 0 && start < end);
ffffffffc0202172:	ff2466e3          	bltu	s0,s2,ffffffffc020215e <unmap_range+0x62>
}
ffffffffc0202176:	70a6                	ld	ra,104(sp)
ffffffffc0202178:	7406                	ld	s0,96(sp)
ffffffffc020217a:	64e6                	ld	s1,88(sp)
ffffffffc020217c:	6946                	ld	s2,80(sp)
ffffffffc020217e:	69a6                	ld	s3,72(sp)
ffffffffc0202180:	6a06                	ld	s4,64(sp)
ffffffffc0202182:	7ae2                	ld	s5,56(sp)
ffffffffc0202184:	7b42                	ld	s6,48(sp)
ffffffffc0202186:	7ba2                	ld	s7,40(sp)
ffffffffc0202188:	7c02                	ld	s8,32(sp)
ffffffffc020218a:	6ce2                	ld	s9,24(sp)
ffffffffc020218c:	6d42                	ld	s10,16(sp)
ffffffffc020218e:	6165                	addi	sp,sp,112
ffffffffc0202190:	8082                	ret
    if (*ptep & PTE_V)
ffffffffc0202192:	0017f713          	andi	a4,a5,1
ffffffffc0202196:	df69                	beqz	a4,ffffffffc0202170 <unmap_range+0x74>
    if (PPN(pa) >= npage)
ffffffffc0202198:	000cb703          	ld	a4,0(s9)
    return pa2page(PTE_ADDR(pte));
ffffffffc020219c:	078a                	slli	a5,a5,0x2
ffffffffc020219e:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02021a0:	08e7ff63          	bgeu	a5,a4,ffffffffc020223e <unmap_range+0x142>
    return &pages[PPN(pa) - nbase];
ffffffffc02021a4:	000c3503          	ld	a0,0(s8)
ffffffffc02021a8:	97de                	add	a5,a5,s7
ffffffffc02021aa:	079a                	slli	a5,a5,0x6
ffffffffc02021ac:	953e                	add	a0,a0,a5
    page->ref -= 1;
ffffffffc02021ae:	411c                	lw	a5,0(a0)
ffffffffc02021b0:	fff7871b          	addiw	a4,a5,-1
ffffffffc02021b4:	c118                	sw	a4,0(a0)
        if (page_ref(page) ==
ffffffffc02021b6:	cf11                	beqz	a4,ffffffffc02021d2 <unmap_range+0xd6>
        *ptep = 0;                 //(5) clear second page table entry
ffffffffc02021b8:	0004b023          	sd	zero,0(s1)

// invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
void tlb_invalidate(pde_t *pgdir, uintptr_t la)
{
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02021bc:	12040073          	sfence.vma	s0
        start += PGSIZE;
ffffffffc02021c0:	9452                	add	s0,s0,s4
    } while (start != 0 && start < end);
ffffffffc02021c2:	bf45                	j	ffffffffc0202172 <unmap_range+0x76>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc02021c4:	945a                	add	s0,s0,s6
ffffffffc02021c6:	01547433          	and	s0,s0,s5
    } while (start != 0 && start < end);
ffffffffc02021ca:	d455                	beqz	s0,ffffffffc0202176 <unmap_range+0x7a>
ffffffffc02021cc:	f92469e3          	bltu	s0,s2,ffffffffc020215e <unmap_range+0x62>
ffffffffc02021d0:	b75d                	j	ffffffffc0202176 <unmap_range+0x7a>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02021d2:	100027f3          	csrr	a5,sstatus
ffffffffc02021d6:	8b89                	andi	a5,a5,2
ffffffffc02021d8:	e799                	bnez	a5,ffffffffc02021e6 <unmap_range+0xea>
        pmm_manager->free_pages(base, n);
ffffffffc02021da:	000d3783          	ld	a5,0(s10)
ffffffffc02021de:	4585                	li	a1,1
ffffffffc02021e0:	739c                	ld	a5,32(a5)
ffffffffc02021e2:	9782                	jalr	a5
    if (flag)
ffffffffc02021e4:	bfd1                	j	ffffffffc02021b8 <unmap_range+0xbc>
ffffffffc02021e6:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc02021e8:	fc6fe0ef          	jal	ra,ffffffffc02009ae <intr_disable>
ffffffffc02021ec:	000d3783          	ld	a5,0(s10)
ffffffffc02021f0:	6522                	ld	a0,8(sp)
ffffffffc02021f2:	4585                	li	a1,1
ffffffffc02021f4:	739c                	ld	a5,32(a5)
ffffffffc02021f6:	9782                	jalr	a5
        intr_enable();
ffffffffc02021f8:	fb0fe0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc02021fc:	bf75                	j	ffffffffc02021b8 <unmap_range+0xbc>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02021fe:	00004697          	auipc	a3,0x4
ffffffffc0202202:	5f268693          	addi	a3,a3,1522 # ffffffffc02067f0 <default_pmm_manager+0x160>
ffffffffc0202206:	00004617          	auipc	a2,0x4
ffffffffc020220a:	0da60613          	addi	a2,a2,218 # ffffffffc02062e0 <commands+0x828>
ffffffffc020220e:	12200593          	li	a1,290
ffffffffc0202212:	00004517          	auipc	a0,0x4
ffffffffc0202216:	5ce50513          	addi	a0,a0,1486 # ffffffffc02067e0 <default_pmm_manager+0x150>
ffffffffc020221a:	a78fe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(USER_ACCESS(start, end));
ffffffffc020221e:	00004697          	auipc	a3,0x4
ffffffffc0202222:	60268693          	addi	a3,a3,1538 # ffffffffc0206820 <default_pmm_manager+0x190>
ffffffffc0202226:	00004617          	auipc	a2,0x4
ffffffffc020222a:	0ba60613          	addi	a2,a2,186 # ffffffffc02062e0 <commands+0x828>
ffffffffc020222e:	12300593          	li	a1,291
ffffffffc0202232:	00004517          	auipc	a0,0x4
ffffffffc0202236:	5ae50513          	addi	a0,a0,1454 # ffffffffc02067e0 <default_pmm_manager+0x150>
ffffffffc020223a:	a58fe0ef          	jal	ra,ffffffffc0200492 <__panic>
ffffffffc020223e:	b53ff0ef          	jal	ra,ffffffffc0201d90 <pa2page.part.0>

ffffffffc0202242 <exit_range>:
{
ffffffffc0202242:	7119                	addi	sp,sp,-128
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202244:	00c5e7b3          	or	a5,a1,a2
{
ffffffffc0202248:	fc86                	sd	ra,120(sp)
ffffffffc020224a:	f8a2                	sd	s0,112(sp)
ffffffffc020224c:	f4a6                	sd	s1,104(sp)
ffffffffc020224e:	f0ca                	sd	s2,96(sp)
ffffffffc0202250:	ecce                	sd	s3,88(sp)
ffffffffc0202252:	e8d2                	sd	s4,80(sp)
ffffffffc0202254:	e4d6                	sd	s5,72(sp)
ffffffffc0202256:	e0da                	sd	s6,64(sp)
ffffffffc0202258:	fc5e                	sd	s7,56(sp)
ffffffffc020225a:	f862                	sd	s8,48(sp)
ffffffffc020225c:	f466                	sd	s9,40(sp)
ffffffffc020225e:	f06a                	sd	s10,32(sp)
ffffffffc0202260:	ec6e                	sd	s11,24(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202262:	17d2                	slli	a5,a5,0x34
ffffffffc0202264:	20079a63          	bnez	a5,ffffffffc0202478 <exit_range+0x236>
    assert(USER_ACCESS(start, end));
ffffffffc0202268:	002007b7          	lui	a5,0x200
ffffffffc020226c:	24f5e463          	bltu	a1,a5,ffffffffc02024b4 <exit_range+0x272>
ffffffffc0202270:	8ab2                	mv	s5,a2
ffffffffc0202272:	24c5f163          	bgeu	a1,a2,ffffffffc02024b4 <exit_range+0x272>
ffffffffc0202276:	4785                	li	a5,1
ffffffffc0202278:	07fe                	slli	a5,a5,0x1f
ffffffffc020227a:	22c7ed63          	bltu	a5,a2,ffffffffc02024b4 <exit_range+0x272>
    d1start = ROUNDDOWN(start, PDSIZE);
ffffffffc020227e:	c00009b7          	lui	s3,0xc0000
ffffffffc0202282:	0135f9b3          	and	s3,a1,s3
    d0start = ROUNDDOWN(start, PTSIZE);
ffffffffc0202286:	ffe00937          	lui	s2,0xffe00
ffffffffc020228a:	400007b7          	lui	a5,0x40000
    return KADDR(page2pa(page));
ffffffffc020228e:	5cfd                	li	s9,-1
ffffffffc0202290:	8c2a                	mv	s8,a0
ffffffffc0202292:	0125f933          	and	s2,a1,s2
ffffffffc0202296:	99be                	add	s3,s3,a5
    if (PPN(pa) >= npage)
ffffffffc0202298:	000c5d17          	auipc	s10,0xc5
ffffffffc020229c:	a20d0d13          	addi	s10,s10,-1504 # ffffffffc02c6cb8 <npage>
    return KADDR(page2pa(page));
ffffffffc02022a0:	00ccdc93          	srli	s9,s9,0xc
    return &pages[PPN(pa) - nbase];
ffffffffc02022a4:	000c5717          	auipc	a4,0xc5
ffffffffc02022a8:	a1c70713          	addi	a4,a4,-1508 # ffffffffc02c6cc0 <pages>
        pmm_manager->free_pages(base, n);
ffffffffc02022ac:	000c5d97          	auipc	s11,0xc5
ffffffffc02022b0:	a1cd8d93          	addi	s11,s11,-1508 # ffffffffc02c6cc8 <pmm_manager>
        pde1 = pgdir[PDX1(d1start)];
ffffffffc02022b4:	c0000437          	lui	s0,0xc0000
ffffffffc02022b8:	944e                	add	s0,s0,s3
ffffffffc02022ba:	8079                	srli	s0,s0,0x1e
ffffffffc02022bc:	1ff47413          	andi	s0,s0,511
ffffffffc02022c0:	040e                	slli	s0,s0,0x3
ffffffffc02022c2:	9462                	add	s0,s0,s8
ffffffffc02022c4:	00043a03          	ld	s4,0(s0) # ffffffffc0000000 <_binary_obj___user_matrix_out_size+0xffffffffbfff38e0>
        if (pde1 & PTE_V)
ffffffffc02022c8:	001a7793          	andi	a5,s4,1
ffffffffc02022cc:	eb99                	bnez	a5,ffffffffc02022e2 <exit_range+0xa0>
    } while (d1start != 0 && d1start < end);
ffffffffc02022ce:	12098463          	beqz	s3,ffffffffc02023f6 <exit_range+0x1b4>
ffffffffc02022d2:	400007b7          	lui	a5,0x40000
ffffffffc02022d6:	97ce                	add	a5,a5,s3
ffffffffc02022d8:	894e                	mv	s2,s3
ffffffffc02022da:	1159fe63          	bgeu	s3,s5,ffffffffc02023f6 <exit_range+0x1b4>
ffffffffc02022de:	89be                	mv	s3,a5
ffffffffc02022e0:	bfd1                	j	ffffffffc02022b4 <exit_range+0x72>
    if (PPN(pa) >= npage)
ffffffffc02022e2:	000d3783          	ld	a5,0(s10)
    return pa2page(PDE_ADDR(pde));
ffffffffc02022e6:	0a0a                	slli	s4,s4,0x2
ffffffffc02022e8:	00ca5a13          	srli	s4,s4,0xc
    if (PPN(pa) >= npage)
ffffffffc02022ec:	1cfa7263          	bgeu	s4,a5,ffffffffc02024b0 <exit_range+0x26e>
    return &pages[PPN(pa) - nbase];
ffffffffc02022f0:	fff80637          	lui	a2,0xfff80
ffffffffc02022f4:	9652                	add	a2,a2,s4
    return page - pages + nbase;
ffffffffc02022f6:	000806b7          	lui	a3,0x80
ffffffffc02022fa:	96b2                	add	a3,a3,a2
    return KADDR(page2pa(page));
ffffffffc02022fc:	0196f5b3          	and	a1,a3,s9
    return &pages[PPN(pa) - nbase];
ffffffffc0202300:	061a                	slli	a2,a2,0x6
    return page2ppn(page) << PGSHIFT;
ffffffffc0202302:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202304:	18f5fa63          	bgeu	a1,a5,ffffffffc0202498 <exit_range+0x256>
ffffffffc0202308:	000c5817          	auipc	a6,0xc5
ffffffffc020230c:	9c880813          	addi	a6,a6,-1592 # ffffffffc02c6cd0 <va_pa_offset>
ffffffffc0202310:	00083b03          	ld	s6,0(a6)
            free_pd0 = 1;
ffffffffc0202314:	4b85                	li	s7,1
    return &pages[PPN(pa) - nbase];
ffffffffc0202316:	fff80e37          	lui	t3,0xfff80
    return KADDR(page2pa(page));
ffffffffc020231a:	9b36                	add	s6,s6,a3
    return page - pages + nbase;
ffffffffc020231c:	00080337          	lui	t1,0x80
ffffffffc0202320:	6885                	lui	a7,0x1
ffffffffc0202322:	a819                	j	ffffffffc0202338 <exit_range+0xf6>
                    free_pd0 = 0;
ffffffffc0202324:	4b81                	li	s7,0
                d0start += PTSIZE;
ffffffffc0202326:	002007b7          	lui	a5,0x200
ffffffffc020232a:	993e                	add	s2,s2,a5
            } while (d0start != 0 && d0start < d1start + PDSIZE && d0start < end);
ffffffffc020232c:	08090c63          	beqz	s2,ffffffffc02023c4 <exit_range+0x182>
ffffffffc0202330:	09397a63          	bgeu	s2,s3,ffffffffc02023c4 <exit_range+0x182>
ffffffffc0202334:	0f597063          	bgeu	s2,s5,ffffffffc0202414 <exit_range+0x1d2>
                pde0 = pd0[PDX0(d0start)];
ffffffffc0202338:	01595493          	srli	s1,s2,0x15
ffffffffc020233c:	1ff4f493          	andi	s1,s1,511
ffffffffc0202340:	048e                	slli	s1,s1,0x3
ffffffffc0202342:	94da                	add	s1,s1,s6
ffffffffc0202344:	609c                	ld	a5,0(s1)
                if (pde0 & PTE_V)
ffffffffc0202346:	0017f693          	andi	a3,a5,1
ffffffffc020234a:	dee9                	beqz	a3,ffffffffc0202324 <exit_range+0xe2>
    if (PPN(pa) >= npage)
ffffffffc020234c:	000d3583          	ld	a1,0(s10)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202350:	078a                	slli	a5,a5,0x2
ffffffffc0202352:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202354:	14b7fe63          	bgeu	a5,a1,ffffffffc02024b0 <exit_range+0x26e>
    return &pages[PPN(pa) - nbase];
ffffffffc0202358:	97f2                	add	a5,a5,t3
    return page - pages + nbase;
ffffffffc020235a:	006786b3          	add	a3,a5,t1
    return KADDR(page2pa(page));
ffffffffc020235e:	0196feb3          	and	t4,a3,s9
    return &pages[PPN(pa) - nbase];
ffffffffc0202362:	00679513          	slli	a0,a5,0x6
    return page2ppn(page) << PGSHIFT;
ffffffffc0202366:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202368:	12bef863          	bgeu	t4,a1,ffffffffc0202498 <exit_range+0x256>
ffffffffc020236c:	00083783          	ld	a5,0(a6)
ffffffffc0202370:	96be                	add	a3,a3,a5
                    for (int i = 0; i < NPTEENTRY; i++)
ffffffffc0202372:	011685b3          	add	a1,a3,a7
                        if (pt[i] & PTE_V)
ffffffffc0202376:	629c                	ld	a5,0(a3)
ffffffffc0202378:	8b85                	andi	a5,a5,1
ffffffffc020237a:	f7d5                	bnez	a5,ffffffffc0202326 <exit_range+0xe4>
                    for (int i = 0; i < NPTEENTRY; i++)
ffffffffc020237c:	06a1                	addi	a3,a3,8
ffffffffc020237e:	fed59ce3          	bne	a1,a3,ffffffffc0202376 <exit_range+0x134>
    return &pages[PPN(pa) - nbase];
ffffffffc0202382:	631c                	ld	a5,0(a4)
ffffffffc0202384:	953e                	add	a0,a0,a5
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0202386:	100027f3          	csrr	a5,sstatus
ffffffffc020238a:	8b89                	andi	a5,a5,2
ffffffffc020238c:	e7d9                	bnez	a5,ffffffffc020241a <exit_range+0x1d8>
        pmm_manager->free_pages(base, n);
ffffffffc020238e:	000db783          	ld	a5,0(s11)
ffffffffc0202392:	4585                	li	a1,1
ffffffffc0202394:	e032                	sd	a2,0(sp)
ffffffffc0202396:	739c                	ld	a5,32(a5)
ffffffffc0202398:	9782                	jalr	a5
    if (flag)
ffffffffc020239a:	6602                	ld	a2,0(sp)
ffffffffc020239c:	000c5817          	auipc	a6,0xc5
ffffffffc02023a0:	93480813          	addi	a6,a6,-1740 # ffffffffc02c6cd0 <va_pa_offset>
ffffffffc02023a4:	fff80e37          	lui	t3,0xfff80
ffffffffc02023a8:	00080337          	lui	t1,0x80
ffffffffc02023ac:	6885                	lui	a7,0x1
ffffffffc02023ae:	000c5717          	auipc	a4,0xc5
ffffffffc02023b2:	91270713          	addi	a4,a4,-1774 # ffffffffc02c6cc0 <pages>
                        pd0[PDX0(d0start)] = 0;
ffffffffc02023b6:	0004b023          	sd	zero,0(s1)
                d0start += PTSIZE;
ffffffffc02023ba:	002007b7          	lui	a5,0x200
ffffffffc02023be:	993e                	add	s2,s2,a5
            } while (d0start != 0 && d0start < d1start + PDSIZE && d0start < end);
ffffffffc02023c0:	f60918e3          	bnez	s2,ffffffffc0202330 <exit_range+0xee>
            if (free_pd0)
ffffffffc02023c4:	f00b85e3          	beqz	s7,ffffffffc02022ce <exit_range+0x8c>
    if (PPN(pa) >= npage)
ffffffffc02023c8:	000d3783          	ld	a5,0(s10)
ffffffffc02023cc:	0efa7263          	bgeu	s4,a5,ffffffffc02024b0 <exit_range+0x26e>
    return &pages[PPN(pa) - nbase];
ffffffffc02023d0:	6308                	ld	a0,0(a4)
ffffffffc02023d2:	9532                	add	a0,a0,a2
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02023d4:	100027f3          	csrr	a5,sstatus
ffffffffc02023d8:	8b89                	andi	a5,a5,2
ffffffffc02023da:	efad                	bnez	a5,ffffffffc0202454 <exit_range+0x212>
        pmm_manager->free_pages(base, n);
ffffffffc02023dc:	000db783          	ld	a5,0(s11)
ffffffffc02023e0:	4585                	li	a1,1
ffffffffc02023e2:	739c                	ld	a5,32(a5)
ffffffffc02023e4:	9782                	jalr	a5
ffffffffc02023e6:	000c5717          	auipc	a4,0xc5
ffffffffc02023ea:	8da70713          	addi	a4,a4,-1830 # ffffffffc02c6cc0 <pages>
                pgdir[PDX1(d1start)] = 0;
ffffffffc02023ee:	00043023          	sd	zero,0(s0)
    } while (d1start != 0 && d1start < end);
ffffffffc02023f2:	ee0990e3          	bnez	s3,ffffffffc02022d2 <exit_range+0x90>
}
ffffffffc02023f6:	70e6                	ld	ra,120(sp)
ffffffffc02023f8:	7446                	ld	s0,112(sp)
ffffffffc02023fa:	74a6                	ld	s1,104(sp)
ffffffffc02023fc:	7906                	ld	s2,96(sp)
ffffffffc02023fe:	69e6                	ld	s3,88(sp)
ffffffffc0202400:	6a46                	ld	s4,80(sp)
ffffffffc0202402:	6aa6                	ld	s5,72(sp)
ffffffffc0202404:	6b06                	ld	s6,64(sp)
ffffffffc0202406:	7be2                	ld	s7,56(sp)
ffffffffc0202408:	7c42                	ld	s8,48(sp)
ffffffffc020240a:	7ca2                	ld	s9,40(sp)
ffffffffc020240c:	7d02                	ld	s10,32(sp)
ffffffffc020240e:	6de2                	ld	s11,24(sp)
ffffffffc0202410:	6109                	addi	sp,sp,128
ffffffffc0202412:	8082                	ret
            if (free_pd0)
ffffffffc0202414:	ea0b8fe3          	beqz	s7,ffffffffc02022d2 <exit_range+0x90>
ffffffffc0202418:	bf45                	j	ffffffffc02023c8 <exit_range+0x186>
ffffffffc020241a:	e032                	sd	a2,0(sp)
        intr_disable();
ffffffffc020241c:	e42a                	sd	a0,8(sp)
ffffffffc020241e:	d90fe0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202422:	000db783          	ld	a5,0(s11)
ffffffffc0202426:	6522                	ld	a0,8(sp)
ffffffffc0202428:	4585                	li	a1,1
ffffffffc020242a:	739c                	ld	a5,32(a5)
ffffffffc020242c:	9782                	jalr	a5
        intr_enable();
ffffffffc020242e:	d7afe0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0202432:	6602                	ld	a2,0(sp)
ffffffffc0202434:	000c5717          	auipc	a4,0xc5
ffffffffc0202438:	88c70713          	addi	a4,a4,-1908 # ffffffffc02c6cc0 <pages>
ffffffffc020243c:	6885                	lui	a7,0x1
ffffffffc020243e:	00080337          	lui	t1,0x80
ffffffffc0202442:	fff80e37          	lui	t3,0xfff80
ffffffffc0202446:	000c5817          	auipc	a6,0xc5
ffffffffc020244a:	88a80813          	addi	a6,a6,-1910 # ffffffffc02c6cd0 <va_pa_offset>
                        pd0[PDX0(d0start)] = 0;
ffffffffc020244e:	0004b023          	sd	zero,0(s1)
ffffffffc0202452:	b7a5                	j	ffffffffc02023ba <exit_range+0x178>
ffffffffc0202454:	e02a                	sd	a0,0(sp)
        intr_disable();
ffffffffc0202456:	d58fe0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc020245a:	000db783          	ld	a5,0(s11)
ffffffffc020245e:	6502                	ld	a0,0(sp)
ffffffffc0202460:	4585                	li	a1,1
ffffffffc0202462:	739c                	ld	a5,32(a5)
ffffffffc0202464:	9782                	jalr	a5
        intr_enable();
ffffffffc0202466:	d42fe0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc020246a:	000c5717          	auipc	a4,0xc5
ffffffffc020246e:	85670713          	addi	a4,a4,-1962 # ffffffffc02c6cc0 <pages>
                pgdir[PDX1(d1start)] = 0;
ffffffffc0202472:	00043023          	sd	zero,0(s0)
ffffffffc0202476:	bfb5                	j	ffffffffc02023f2 <exit_range+0x1b0>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202478:	00004697          	auipc	a3,0x4
ffffffffc020247c:	37868693          	addi	a3,a3,888 # ffffffffc02067f0 <default_pmm_manager+0x160>
ffffffffc0202480:	00004617          	auipc	a2,0x4
ffffffffc0202484:	e6060613          	addi	a2,a2,-416 # ffffffffc02062e0 <commands+0x828>
ffffffffc0202488:	13700593          	li	a1,311
ffffffffc020248c:	00004517          	auipc	a0,0x4
ffffffffc0202490:	35450513          	addi	a0,a0,852 # ffffffffc02067e0 <default_pmm_manager+0x150>
ffffffffc0202494:	ffffd0ef          	jal	ra,ffffffffc0200492 <__panic>
    return KADDR(page2pa(page));
ffffffffc0202498:	00004617          	auipc	a2,0x4
ffffffffc020249c:	23060613          	addi	a2,a2,560 # ffffffffc02066c8 <default_pmm_manager+0x38>
ffffffffc02024a0:	07100593          	li	a1,113
ffffffffc02024a4:	00004517          	auipc	a0,0x4
ffffffffc02024a8:	24c50513          	addi	a0,a0,588 # ffffffffc02066f0 <default_pmm_manager+0x60>
ffffffffc02024ac:	fe7fd0ef          	jal	ra,ffffffffc0200492 <__panic>
ffffffffc02024b0:	8e1ff0ef          	jal	ra,ffffffffc0201d90 <pa2page.part.0>
    assert(USER_ACCESS(start, end));
ffffffffc02024b4:	00004697          	auipc	a3,0x4
ffffffffc02024b8:	36c68693          	addi	a3,a3,876 # ffffffffc0206820 <default_pmm_manager+0x190>
ffffffffc02024bc:	00004617          	auipc	a2,0x4
ffffffffc02024c0:	e2460613          	addi	a2,a2,-476 # ffffffffc02062e0 <commands+0x828>
ffffffffc02024c4:	13800593          	li	a1,312
ffffffffc02024c8:	00004517          	auipc	a0,0x4
ffffffffc02024cc:	31850513          	addi	a0,a0,792 # ffffffffc02067e0 <default_pmm_manager+0x150>
ffffffffc02024d0:	fc3fd0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc02024d4 <page_remove>:
{
ffffffffc02024d4:	7179                	addi	sp,sp,-48
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc02024d6:	4601                	li	a2,0
{
ffffffffc02024d8:	ec26                	sd	s1,24(sp)
ffffffffc02024da:	f406                	sd	ra,40(sp)
ffffffffc02024dc:	f022                	sd	s0,32(sp)
ffffffffc02024de:	84ae                	mv	s1,a1
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc02024e0:	9a1ff0ef          	jal	ra,ffffffffc0201e80 <get_pte>
    if (ptep != NULL)
ffffffffc02024e4:	c511                	beqz	a0,ffffffffc02024f0 <page_remove+0x1c>
    if (*ptep & PTE_V)
ffffffffc02024e6:	611c                	ld	a5,0(a0)
ffffffffc02024e8:	842a                	mv	s0,a0
ffffffffc02024ea:	0017f713          	andi	a4,a5,1
ffffffffc02024ee:	e711                	bnez	a4,ffffffffc02024fa <page_remove+0x26>
}
ffffffffc02024f0:	70a2                	ld	ra,40(sp)
ffffffffc02024f2:	7402                	ld	s0,32(sp)
ffffffffc02024f4:	64e2                	ld	s1,24(sp)
ffffffffc02024f6:	6145                	addi	sp,sp,48
ffffffffc02024f8:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc02024fa:	078a                	slli	a5,a5,0x2
ffffffffc02024fc:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02024fe:	000c4717          	auipc	a4,0xc4
ffffffffc0202502:	7ba73703          	ld	a4,1978(a4) # ffffffffc02c6cb8 <npage>
ffffffffc0202506:	06e7f363          	bgeu	a5,a4,ffffffffc020256c <page_remove+0x98>
    return &pages[PPN(pa) - nbase];
ffffffffc020250a:	fff80537          	lui	a0,0xfff80
ffffffffc020250e:	97aa                	add	a5,a5,a0
ffffffffc0202510:	079a                	slli	a5,a5,0x6
ffffffffc0202512:	000c4517          	auipc	a0,0xc4
ffffffffc0202516:	7ae53503          	ld	a0,1966(a0) # ffffffffc02c6cc0 <pages>
ffffffffc020251a:	953e                	add	a0,a0,a5
    page->ref -= 1;
ffffffffc020251c:	411c                	lw	a5,0(a0)
ffffffffc020251e:	fff7871b          	addiw	a4,a5,-1
ffffffffc0202522:	c118                	sw	a4,0(a0)
        if (page_ref(page) ==
ffffffffc0202524:	cb11                	beqz	a4,ffffffffc0202538 <page_remove+0x64>
        *ptep = 0;                 //(5) clear second page table entry
ffffffffc0202526:	00043023          	sd	zero,0(s0)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc020252a:	12048073          	sfence.vma	s1
}
ffffffffc020252e:	70a2                	ld	ra,40(sp)
ffffffffc0202530:	7402                	ld	s0,32(sp)
ffffffffc0202532:	64e2                	ld	s1,24(sp)
ffffffffc0202534:	6145                	addi	sp,sp,48
ffffffffc0202536:	8082                	ret
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0202538:	100027f3          	csrr	a5,sstatus
ffffffffc020253c:	8b89                	andi	a5,a5,2
ffffffffc020253e:	eb89                	bnez	a5,ffffffffc0202550 <page_remove+0x7c>
        pmm_manager->free_pages(base, n);
ffffffffc0202540:	000c4797          	auipc	a5,0xc4
ffffffffc0202544:	7887b783          	ld	a5,1928(a5) # ffffffffc02c6cc8 <pmm_manager>
ffffffffc0202548:	739c                	ld	a5,32(a5)
ffffffffc020254a:	4585                	li	a1,1
ffffffffc020254c:	9782                	jalr	a5
    if (flag)
ffffffffc020254e:	bfe1                	j	ffffffffc0202526 <page_remove+0x52>
        intr_disable();
ffffffffc0202550:	e42a                	sd	a0,8(sp)
ffffffffc0202552:	c5cfe0ef          	jal	ra,ffffffffc02009ae <intr_disable>
ffffffffc0202556:	000c4797          	auipc	a5,0xc4
ffffffffc020255a:	7727b783          	ld	a5,1906(a5) # ffffffffc02c6cc8 <pmm_manager>
ffffffffc020255e:	739c                	ld	a5,32(a5)
ffffffffc0202560:	6522                	ld	a0,8(sp)
ffffffffc0202562:	4585                	li	a1,1
ffffffffc0202564:	9782                	jalr	a5
        intr_enable();
ffffffffc0202566:	c42fe0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc020256a:	bf75                	j	ffffffffc0202526 <page_remove+0x52>
ffffffffc020256c:	825ff0ef          	jal	ra,ffffffffc0201d90 <pa2page.part.0>

ffffffffc0202570 <page_insert>:
{
ffffffffc0202570:	7139                	addi	sp,sp,-64
ffffffffc0202572:	e852                	sd	s4,16(sp)
ffffffffc0202574:	8a32                	mv	s4,a2
ffffffffc0202576:	f822                	sd	s0,48(sp)
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0202578:	4605                	li	a2,1
{
ffffffffc020257a:	842e                	mv	s0,a1
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc020257c:	85d2                	mv	a1,s4
{
ffffffffc020257e:	f426                	sd	s1,40(sp)
ffffffffc0202580:	fc06                	sd	ra,56(sp)
ffffffffc0202582:	f04a                	sd	s2,32(sp)
ffffffffc0202584:	ec4e                	sd	s3,24(sp)
ffffffffc0202586:	e456                	sd	s5,8(sp)
ffffffffc0202588:	84b6                	mv	s1,a3
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc020258a:	8f7ff0ef          	jal	ra,ffffffffc0201e80 <get_pte>
    if (ptep == NULL)
ffffffffc020258e:	c961                	beqz	a0,ffffffffc020265e <page_insert+0xee>
    page->ref += 1;
ffffffffc0202590:	4014                	lw	a3,0(s0)
    if (*ptep & PTE_V)
ffffffffc0202592:	611c                	ld	a5,0(a0)
ffffffffc0202594:	89aa                	mv	s3,a0
ffffffffc0202596:	0016871b          	addiw	a4,a3,1
ffffffffc020259a:	c018                	sw	a4,0(s0)
ffffffffc020259c:	0017f713          	andi	a4,a5,1
ffffffffc02025a0:	ef05                	bnez	a4,ffffffffc02025d8 <page_insert+0x68>
    return page - pages + nbase;
ffffffffc02025a2:	000c4717          	auipc	a4,0xc4
ffffffffc02025a6:	71e73703          	ld	a4,1822(a4) # ffffffffc02c6cc0 <pages>
ffffffffc02025aa:	8c19                	sub	s0,s0,a4
ffffffffc02025ac:	000807b7          	lui	a5,0x80
ffffffffc02025b0:	8419                	srai	s0,s0,0x6
ffffffffc02025b2:	943e                	add	s0,s0,a5
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc02025b4:	042a                	slli	s0,s0,0xa
ffffffffc02025b6:	8cc1                	or	s1,s1,s0
ffffffffc02025b8:	0014e493          	ori	s1,s1,1
    *ptep = pte_create(page2ppn(page), PTE_V | perm);
ffffffffc02025bc:	0099b023          	sd	s1,0(s3) # ffffffffc0000000 <_binary_obj___user_matrix_out_size+0xffffffffbfff38e0>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02025c0:	120a0073          	sfence.vma	s4
    return 0;
ffffffffc02025c4:	4501                	li	a0,0
}
ffffffffc02025c6:	70e2                	ld	ra,56(sp)
ffffffffc02025c8:	7442                	ld	s0,48(sp)
ffffffffc02025ca:	74a2                	ld	s1,40(sp)
ffffffffc02025cc:	7902                	ld	s2,32(sp)
ffffffffc02025ce:	69e2                	ld	s3,24(sp)
ffffffffc02025d0:	6a42                	ld	s4,16(sp)
ffffffffc02025d2:	6aa2                	ld	s5,8(sp)
ffffffffc02025d4:	6121                	addi	sp,sp,64
ffffffffc02025d6:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc02025d8:	078a                	slli	a5,a5,0x2
ffffffffc02025da:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02025dc:	000c4717          	auipc	a4,0xc4
ffffffffc02025e0:	6dc73703          	ld	a4,1756(a4) # ffffffffc02c6cb8 <npage>
ffffffffc02025e4:	06e7ff63          	bgeu	a5,a4,ffffffffc0202662 <page_insert+0xf2>
    return &pages[PPN(pa) - nbase];
ffffffffc02025e8:	000c4a97          	auipc	s5,0xc4
ffffffffc02025ec:	6d8a8a93          	addi	s5,s5,1752 # ffffffffc02c6cc0 <pages>
ffffffffc02025f0:	000ab703          	ld	a4,0(s5)
ffffffffc02025f4:	fff80937          	lui	s2,0xfff80
ffffffffc02025f8:	993e                	add	s2,s2,a5
ffffffffc02025fa:	091a                	slli	s2,s2,0x6
ffffffffc02025fc:	993a                	add	s2,s2,a4
        if (p == page)
ffffffffc02025fe:	01240c63          	beq	s0,s2,ffffffffc0202616 <page_insert+0xa6>
    page->ref -= 1;
ffffffffc0202602:	00092783          	lw	a5,0(s2) # fffffffffff80000 <end+0x3fcb92f8>
ffffffffc0202606:	fff7869b          	addiw	a3,a5,-1
ffffffffc020260a:	00d92023          	sw	a3,0(s2)
        if (page_ref(page) ==
ffffffffc020260e:	c691                	beqz	a3,ffffffffc020261a <page_insert+0xaa>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202610:	120a0073          	sfence.vma	s4
}
ffffffffc0202614:	bf59                	j	ffffffffc02025aa <page_insert+0x3a>
ffffffffc0202616:	c014                	sw	a3,0(s0)
    return page->ref;
ffffffffc0202618:	bf49                	j	ffffffffc02025aa <page_insert+0x3a>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020261a:	100027f3          	csrr	a5,sstatus
ffffffffc020261e:	8b89                	andi	a5,a5,2
ffffffffc0202620:	ef91                	bnez	a5,ffffffffc020263c <page_insert+0xcc>
        pmm_manager->free_pages(base, n);
ffffffffc0202622:	000c4797          	auipc	a5,0xc4
ffffffffc0202626:	6a67b783          	ld	a5,1702(a5) # ffffffffc02c6cc8 <pmm_manager>
ffffffffc020262a:	739c                	ld	a5,32(a5)
ffffffffc020262c:	4585                	li	a1,1
ffffffffc020262e:	854a                	mv	a0,s2
ffffffffc0202630:	9782                	jalr	a5
    return page - pages + nbase;
ffffffffc0202632:	000ab703          	ld	a4,0(s5)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202636:	120a0073          	sfence.vma	s4
ffffffffc020263a:	bf85                	j	ffffffffc02025aa <page_insert+0x3a>
        intr_disable();
ffffffffc020263c:	b72fe0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202640:	000c4797          	auipc	a5,0xc4
ffffffffc0202644:	6887b783          	ld	a5,1672(a5) # ffffffffc02c6cc8 <pmm_manager>
ffffffffc0202648:	739c                	ld	a5,32(a5)
ffffffffc020264a:	4585                	li	a1,1
ffffffffc020264c:	854a                	mv	a0,s2
ffffffffc020264e:	9782                	jalr	a5
        intr_enable();
ffffffffc0202650:	b58fe0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0202654:	000ab703          	ld	a4,0(s5)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202658:	120a0073          	sfence.vma	s4
ffffffffc020265c:	b7b9                	j	ffffffffc02025aa <page_insert+0x3a>
        return -E_NO_MEM;
ffffffffc020265e:	5571                	li	a0,-4
ffffffffc0202660:	b79d                	j	ffffffffc02025c6 <page_insert+0x56>
ffffffffc0202662:	f2eff0ef          	jal	ra,ffffffffc0201d90 <pa2page.part.0>

ffffffffc0202666 <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc0202666:	00004797          	auipc	a5,0x4
ffffffffc020266a:	02a78793          	addi	a5,a5,42 # ffffffffc0206690 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc020266e:	638c                	ld	a1,0(a5)
{
ffffffffc0202670:	7159                	addi	sp,sp,-112
ffffffffc0202672:	f85a                	sd	s6,48(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0202674:	00004517          	auipc	a0,0x4
ffffffffc0202678:	1c450513          	addi	a0,a0,452 # ffffffffc0206838 <default_pmm_manager+0x1a8>
    pmm_manager = &default_pmm_manager;
ffffffffc020267c:	000c4b17          	auipc	s6,0xc4
ffffffffc0202680:	64cb0b13          	addi	s6,s6,1612 # ffffffffc02c6cc8 <pmm_manager>
{
ffffffffc0202684:	f486                	sd	ra,104(sp)
ffffffffc0202686:	e8ca                	sd	s2,80(sp)
ffffffffc0202688:	e4ce                	sd	s3,72(sp)
ffffffffc020268a:	f0a2                	sd	s0,96(sp)
ffffffffc020268c:	eca6                	sd	s1,88(sp)
ffffffffc020268e:	e0d2                	sd	s4,64(sp)
ffffffffc0202690:	fc56                	sd	s5,56(sp)
ffffffffc0202692:	f45e                	sd	s7,40(sp)
ffffffffc0202694:	f062                	sd	s8,32(sp)
ffffffffc0202696:	ec66                	sd	s9,24(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc0202698:	00fb3023          	sd	a5,0(s6)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc020269c:	afdfd0ef          	jal	ra,ffffffffc0200198 <cprintf>
    pmm_manager->init();
ffffffffc02026a0:	000b3783          	ld	a5,0(s6)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc02026a4:	000c4997          	auipc	s3,0xc4
ffffffffc02026a8:	62c98993          	addi	s3,s3,1580 # ffffffffc02c6cd0 <va_pa_offset>
    pmm_manager->init();
ffffffffc02026ac:	679c                	ld	a5,8(a5)
ffffffffc02026ae:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc02026b0:	57f5                	li	a5,-3
ffffffffc02026b2:	07fa                	slli	a5,a5,0x1e
ffffffffc02026b4:	00f9b023          	sd	a5,0(s3)
    uint64_t mem_begin = get_memory_base();
ffffffffc02026b8:	adcfe0ef          	jal	ra,ffffffffc0200994 <get_memory_base>
ffffffffc02026bc:	892a                	mv	s2,a0
    uint64_t mem_size = get_memory_size();
ffffffffc02026be:	ae0fe0ef          	jal	ra,ffffffffc020099e <get_memory_size>
    if (mem_size == 0)
ffffffffc02026c2:	200505e3          	beqz	a0,ffffffffc02030cc <pmm_init+0xa66>
    uint64_t mem_end = mem_begin + mem_size;
ffffffffc02026c6:	84aa                	mv	s1,a0
    cprintf("physcial memory map:\n");
ffffffffc02026c8:	00004517          	auipc	a0,0x4
ffffffffc02026cc:	1a850513          	addi	a0,a0,424 # ffffffffc0206870 <default_pmm_manager+0x1e0>
ffffffffc02026d0:	ac9fd0ef          	jal	ra,ffffffffc0200198 <cprintf>
    uint64_t mem_end = mem_begin + mem_size;
ffffffffc02026d4:	00990433          	add	s0,s2,s1
    cprintf("  memory: 0x%08lx, [0x%08lx, 0x%08lx].\n", mem_size, mem_begin,
ffffffffc02026d8:	fff40693          	addi	a3,s0,-1
ffffffffc02026dc:	864a                	mv	a2,s2
ffffffffc02026de:	85a6                	mv	a1,s1
ffffffffc02026e0:	00004517          	auipc	a0,0x4
ffffffffc02026e4:	1a850513          	addi	a0,a0,424 # ffffffffc0206888 <default_pmm_manager+0x1f8>
ffffffffc02026e8:	ab1fd0ef          	jal	ra,ffffffffc0200198 <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc02026ec:	c8000737          	lui	a4,0xc8000
ffffffffc02026f0:	87a2                	mv	a5,s0
ffffffffc02026f2:	54876163          	bltu	a4,s0,ffffffffc0202c34 <pmm_init+0x5ce>
ffffffffc02026f6:	757d                	lui	a0,0xfffff
ffffffffc02026f8:	000c5617          	auipc	a2,0xc5
ffffffffc02026fc:	60f60613          	addi	a2,a2,1551 # ffffffffc02c7d07 <end+0xfff>
ffffffffc0202700:	8e69                	and	a2,a2,a0
ffffffffc0202702:	000c4497          	auipc	s1,0xc4
ffffffffc0202706:	5b648493          	addi	s1,s1,1462 # ffffffffc02c6cb8 <npage>
ffffffffc020270a:	00c7d513          	srli	a0,a5,0xc
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc020270e:	000c4b97          	auipc	s7,0xc4
ffffffffc0202712:	5b2b8b93          	addi	s7,s7,1458 # ffffffffc02c6cc0 <pages>
    npage = maxpa / PGSIZE;
ffffffffc0202716:	e088                	sd	a0,0(s1)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0202718:	00cbb023          	sd	a2,0(s7)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc020271c:	000807b7          	lui	a5,0x80
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0202720:	86b2                	mv	a3,a2
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0202722:	02f50863          	beq	a0,a5,ffffffffc0202752 <pmm_init+0xec>
ffffffffc0202726:	4781                	li	a5,0
ffffffffc0202728:	4585                	li	a1,1
ffffffffc020272a:	fff806b7          	lui	a3,0xfff80
        SetPageReserved(pages + i);
ffffffffc020272e:	00679513          	slli	a0,a5,0x6
ffffffffc0202732:	9532                	add	a0,a0,a2
ffffffffc0202734:	00850713          	addi	a4,a0,8 # fffffffffffff008 <end+0x3fd38300>
ffffffffc0202738:	40b7302f          	amoor.d	zero,a1,(a4)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc020273c:	6088                	ld	a0,0(s1)
ffffffffc020273e:	0785                	addi	a5,a5,1
        SetPageReserved(pages + i);
ffffffffc0202740:	000bb603          	ld	a2,0(s7)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0202744:	00d50733          	add	a4,a0,a3
ffffffffc0202748:	fee7e3e3          	bltu	a5,a4,ffffffffc020272e <pmm_init+0xc8>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc020274c:	071a                	slli	a4,a4,0x6
ffffffffc020274e:	00e606b3          	add	a3,a2,a4
ffffffffc0202752:	c02007b7          	lui	a5,0xc0200
ffffffffc0202756:	2ef6ece3          	bltu	a3,a5,ffffffffc020324e <pmm_init+0xbe8>
ffffffffc020275a:	0009b583          	ld	a1,0(s3)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc020275e:	77fd                	lui	a5,0xfffff
ffffffffc0202760:	8c7d                	and	s0,s0,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0202762:	8e8d                	sub	a3,a3,a1
    if (freemem < mem_end)
ffffffffc0202764:	5086eb63          	bltu	a3,s0,ffffffffc0202c7a <pmm_init+0x614>
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc0202768:	00004517          	auipc	a0,0x4
ffffffffc020276c:	14850513          	addi	a0,a0,328 # ffffffffc02068b0 <default_pmm_manager+0x220>
ffffffffc0202770:	a29fd0ef          	jal	ra,ffffffffc0200198 <cprintf>
    return page;
}

static void check_alloc_page(void)
{
    pmm_manager->check();
ffffffffc0202774:	000b3783          	ld	a5,0(s6)
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc0202778:	000c4917          	auipc	s2,0xc4
ffffffffc020277c:	53890913          	addi	s2,s2,1336 # ffffffffc02c6cb0 <boot_pgdir_va>
    pmm_manager->check();
ffffffffc0202780:	7b9c                	ld	a5,48(a5)
ffffffffc0202782:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0202784:	00004517          	auipc	a0,0x4
ffffffffc0202788:	14450513          	addi	a0,a0,324 # ffffffffc02068c8 <default_pmm_manager+0x238>
ffffffffc020278c:	a0dfd0ef          	jal	ra,ffffffffc0200198 <cprintf>
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc0202790:	00009697          	auipc	a3,0x9
ffffffffc0202794:	87068693          	addi	a3,a3,-1936 # ffffffffc020b000 <boot_page_table_sv39>
ffffffffc0202798:	00d93023          	sd	a3,0(s2)
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc020279c:	c02007b7          	lui	a5,0xc0200
ffffffffc02027a0:	28f6ebe3          	bltu	a3,a5,ffffffffc0203236 <pmm_init+0xbd0>
ffffffffc02027a4:	0009b783          	ld	a5,0(s3)
ffffffffc02027a8:	8e9d                	sub	a3,a3,a5
ffffffffc02027aa:	000c4797          	auipc	a5,0xc4
ffffffffc02027ae:	4ed7bf23          	sd	a3,1278(a5) # ffffffffc02c6ca8 <boot_pgdir_pa>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02027b2:	100027f3          	csrr	a5,sstatus
ffffffffc02027b6:	8b89                	andi	a5,a5,2
ffffffffc02027b8:	4a079763          	bnez	a5,ffffffffc0202c66 <pmm_init+0x600>
        ret = pmm_manager->nr_free_pages();
ffffffffc02027bc:	000b3783          	ld	a5,0(s6)
ffffffffc02027c0:	779c                	ld	a5,40(a5)
ffffffffc02027c2:	9782                	jalr	a5
ffffffffc02027c4:	842a                	mv	s0,a0
    // so npage is always larger than KMEMSIZE / PGSIZE
    size_t nr_free_store;

    nr_free_store = nr_free_pages();

    assert(npage <= KERNTOP / PGSIZE);
ffffffffc02027c6:	6098                	ld	a4,0(s1)
ffffffffc02027c8:	c80007b7          	lui	a5,0xc8000
ffffffffc02027cc:	83b1                	srli	a5,a5,0xc
ffffffffc02027ce:	66e7e363          	bltu	a5,a4,ffffffffc0202e34 <pmm_init+0x7ce>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc02027d2:	00093503          	ld	a0,0(s2)
ffffffffc02027d6:	62050f63          	beqz	a0,ffffffffc0202e14 <pmm_init+0x7ae>
ffffffffc02027da:	03451793          	slli	a5,a0,0x34
ffffffffc02027de:	62079b63          	bnez	a5,ffffffffc0202e14 <pmm_init+0x7ae>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc02027e2:	4601                	li	a2,0
ffffffffc02027e4:	4581                	li	a1,0
ffffffffc02027e6:	8c3ff0ef          	jal	ra,ffffffffc02020a8 <get_page>
ffffffffc02027ea:	60051563          	bnez	a0,ffffffffc0202df4 <pmm_init+0x78e>
ffffffffc02027ee:	100027f3          	csrr	a5,sstatus
ffffffffc02027f2:	8b89                	andi	a5,a5,2
ffffffffc02027f4:	44079e63          	bnez	a5,ffffffffc0202c50 <pmm_init+0x5ea>
        page = pmm_manager->alloc_pages(n);
ffffffffc02027f8:	000b3783          	ld	a5,0(s6)
ffffffffc02027fc:	4505                	li	a0,1
ffffffffc02027fe:	6f9c                	ld	a5,24(a5)
ffffffffc0202800:	9782                	jalr	a5
ffffffffc0202802:	8a2a                	mv	s4,a0

    struct Page *p1, *p2;
    p1 = alloc_page();
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc0202804:	00093503          	ld	a0,0(s2)
ffffffffc0202808:	4681                	li	a3,0
ffffffffc020280a:	4601                	li	a2,0
ffffffffc020280c:	85d2                	mv	a1,s4
ffffffffc020280e:	d63ff0ef          	jal	ra,ffffffffc0202570 <page_insert>
ffffffffc0202812:	26051ae3          	bnez	a0,ffffffffc0203286 <pmm_init+0xc20>

    pte_t *ptep;
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc0202816:	00093503          	ld	a0,0(s2)
ffffffffc020281a:	4601                	li	a2,0
ffffffffc020281c:	4581                	li	a1,0
ffffffffc020281e:	e62ff0ef          	jal	ra,ffffffffc0201e80 <get_pte>
ffffffffc0202822:	240502e3          	beqz	a0,ffffffffc0203266 <pmm_init+0xc00>
    assert(pte2page(*ptep) == p1);
ffffffffc0202826:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V))
ffffffffc0202828:	0017f713          	andi	a4,a5,1
ffffffffc020282c:	5a070263          	beqz	a4,ffffffffc0202dd0 <pmm_init+0x76a>
    if (PPN(pa) >= npage)
ffffffffc0202830:	6098                	ld	a4,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc0202832:	078a                	slli	a5,a5,0x2
ffffffffc0202834:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202836:	58e7fb63          	bgeu	a5,a4,ffffffffc0202dcc <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc020283a:	000bb683          	ld	a3,0(s7)
ffffffffc020283e:	fff80637          	lui	a2,0xfff80
ffffffffc0202842:	97b2                	add	a5,a5,a2
ffffffffc0202844:	079a                	slli	a5,a5,0x6
ffffffffc0202846:	97b6                	add	a5,a5,a3
ffffffffc0202848:	14fa17e3          	bne	s4,a5,ffffffffc0203196 <pmm_init+0xb30>
    assert(page_ref(p1) == 1);
ffffffffc020284c:	000a2683          	lw	a3,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8f48>
ffffffffc0202850:	4785                	li	a5,1
ffffffffc0202852:	12f692e3          	bne	a3,a5,ffffffffc0203176 <pmm_init+0xb10>

    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc0202856:	00093503          	ld	a0,0(s2)
ffffffffc020285a:	77fd                	lui	a5,0xfffff
ffffffffc020285c:	6114                	ld	a3,0(a0)
ffffffffc020285e:	068a                	slli	a3,a3,0x2
ffffffffc0202860:	8efd                	and	a3,a3,a5
ffffffffc0202862:	00c6d613          	srli	a2,a3,0xc
ffffffffc0202866:	0ee67ce3          	bgeu	a2,a4,ffffffffc020315e <pmm_init+0xaf8>
ffffffffc020286a:	0009bc03          	ld	s8,0(s3)
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc020286e:	96e2                	add	a3,a3,s8
ffffffffc0202870:	0006ba83          	ld	s5,0(a3)
ffffffffc0202874:	0a8a                	slli	s5,s5,0x2
ffffffffc0202876:	00fafab3          	and	s5,s5,a5
ffffffffc020287a:	00cad793          	srli	a5,s5,0xc
ffffffffc020287e:	0ce7f3e3          	bgeu	a5,a4,ffffffffc0203144 <pmm_init+0xade>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202882:	4601                	li	a2,0
ffffffffc0202884:	6585                	lui	a1,0x1
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202886:	9ae2                	add	s5,s5,s8
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202888:	df8ff0ef          	jal	ra,ffffffffc0201e80 <get_pte>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc020288c:	0aa1                	addi	s5,s5,8
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc020288e:	55551363          	bne	a0,s5,ffffffffc0202dd4 <pmm_init+0x76e>
ffffffffc0202892:	100027f3          	csrr	a5,sstatus
ffffffffc0202896:	8b89                	andi	a5,a5,2
ffffffffc0202898:	3a079163          	bnez	a5,ffffffffc0202c3a <pmm_init+0x5d4>
        page = pmm_manager->alloc_pages(n);
ffffffffc020289c:	000b3783          	ld	a5,0(s6)
ffffffffc02028a0:	4505                	li	a0,1
ffffffffc02028a2:	6f9c                	ld	a5,24(a5)
ffffffffc02028a4:	9782                	jalr	a5
ffffffffc02028a6:	8c2a                	mv	s8,a0

    p2 = alloc_page();
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc02028a8:	00093503          	ld	a0,0(s2)
ffffffffc02028ac:	46d1                	li	a3,20
ffffffffc02028ae:	6605                	lui	a2,0x1
ffffffffc02028b0:	85e2                	mv	a1,s8
ffffffffc02028b2:	cbfff0ef          	jal	ra,ffffffffc0202570 <page_insert>
ffffffffc02028b6:	060517e3          	bnez	a0,ffffffffc0203124 <pmm_init+0xabe>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc02028ba:	00093503          	ld	a0,0(s2)
ffffffffc02028be:	4601                	li	a2,0
ffffffffc02028c0:	6585                	lui	a1,0x1
ffffffffc02028c2:	dbeff0ef          	jal	ra,ffffffffc0201e80 <get_pte>
ffffffffc02028c6:	02050fe3          	beqz	a0,ffffffffc0203104 <pmm_init+0xa9e>
    assert(*ptep & PTE_U);
ffffffffc02028ca:	611c                	ld	a5,0(a0)
ffffffffc02028cc:	0107f713          	andi	a4,a5,16
ffffffffc02028d0:	7c070e63          	beqz	a4,ffffffffc02030ac <pmm_init+0xa46>
    assert(*ptep & PTE_W);
ffffffffc02028d4:	8b91                	andi	a5,a5,4
ffffffffc02028d6:	7a078b63          	beqz	a5,ffffffffc020308c <pmm_init+0xa26>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc02028da:	00093503          	ld	a0,0(s2)
ffffffffc02028de:	611c                	ld	a5,0(a0)
ffffffffc02028e0:	8bc1                	andi	a5,a5,16
ffffffffc02028e2:	78078563          	beqz	a5,ffffffffc020306c <pmm_init+0xa06>
    assert(page_ref(p2) == 1);
ffffffffc02028e6:	000c2703          	lw	a4,0(s8)
ffffffffc02028ea:	4785                	li	a5,1
ffffffffc02028ec:	76f71063          	bne	a4,a5,ffffffffc020304c <pmm_init+0x9e6>

    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc02028f0:	4681                	li	a3,0
ffffffffc02028f2:	6605                	lui	a2,0x1
ffffffffc02028f4:	85d2                	mv	a1,s4
ffffffffc02028f6:	c7bff0ef          	jal	ra,ffffffffc0202570 <page_insert>
ffffffffc02028fa:	72051963          	bnez	a0,ffffffffc020302c <pmm_init+0x9c6>
    assert(page_ref(p1) == 2);
ffffffffc02028fe:	000a2703          	lw	a4,0(s4)
ffffffffc0202902:	4789                	li	a5,2
ffffffffc0202904:	70f71463          	bne	a4,a5,ffffffffc020300c <pmm_init+0x9a6>
    assert(page_ref(p2) == 0);
ffffffffc0202908:	000c2783          	lw	a5,0(s8)
ffffffffc020290c:	6e079063          	bnez	a5,ffffffffc0202fec <pmm_init+0x986>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0202910:	00093503          	ld	a0,0(s2)
ffffffffc0202914:	4601                	li	a2,0
ffffffffc0202916:	6585                	lui	a1,0x1
ffffffffc0202918:	d68ff0ef          	jal	ra,ffffffffc0201e80 <get_pte>
ffffffffc020291c:	6a050863          	beqz	a0,ffffffffc0202fcc <pmm_init+0x966>
    assert(pte2page(*ptep) == p1);
ffffffffc0202920:	6118                	ld	a4,0(a0)
    if (!(pte & PTE_V))
ffffffffc0202922:	00177793          	andi	a5,a4,1
ffffffffc0202926:	4a078563          	beqz	a5,ffffffffc0202dd0 <pmm_init+0x76a>
    if (PPN(pa) >= npage)
ffffffffc020292a:	6094                	ld	a3,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc020292c:	00271793          	slli	a5,a4,0x2
ffffffffc0202930:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202932:	48d7fd63          	bgeu	a5,a3,ffffffffc0202dcc <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202936:	000bb683          	ld	a3,0(s7)
ffffffffc020293a:	fff80ab7          	lui	s5,0xfff80
ffffffffc020293e:	97d6                	add	a5,a5,s5
ffffffffc0202940:	079a                	slli	a5,a5,0x6
ffffffffc0202942:	97b6                	add	a5,a5,a3
ffffffffc0202944:	66fa1463          	bne	s4,a5,ffffffffc0202fac <pmm_init+0x946>
    assert((*ptep & PTE_U) == 0);
ffffffffc0202948:	8b41                	andi	a4,a4,16
ffffffffc020294a:	64071163          	bnez	a4,ffffffffc0202f8c <pmm_init+0x926>

    page_remove(boot_pgdir_va, 0x0);
ffffffffc020294e:	00093503          	ld	a0,0(s2)
ffffffffc0202952:	4581                	li	a1,0
ffffffffc0202954:	b81ff0ef          	jal	ra,ffffffffc02024d4 <page_remove>
    assert(page_ref(p1) == 1);
ffffffffc0202958:	000a2c83          	lw	s9,0(s4)
ffffffffc020295c:	4785                	li	a5,1
ffffffffc020295e:	60fc9763          	bne	s9,a5,ffffffffc0202f6c <pmm_init+0x906>
    assert(page_ref(p2) == 0);
ffffffffc0202962:	000c2783          	lw	a5,0(s8)
ffffffffc0202966:	5e079363          	bnez	a5,ffffffffc0202f4c <pmm_init+0x8e6>

    page_remove(boot_pgdir_va, PGSIZE);
ffffffffc020296a:	00093503          	ld	a0,0(s2)
ffffffffc020296e:	6585                	lui	a1,0x1
ffffffffc0202970:	b65ff0ef          	jal	ra,ffffffffc02024d4 <page_remove>
    assert(page_ref(p1) == 0);
ffffffffc0202974:	000a2783          	lw	a5,0(s4)
ffffffffc0202978:	52079a63          	bnez	a5,ffffffffc0202eac <pmm_init+0x846>
    assert(page_ref(p2) == 0);
ffffffffc020297c:	000c2783          	lw	a5,0(s8)
ffffffffc0202980:	50079663          	bnez	a5,ffffffffc0202e8c <pmm_init+0x826>

    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc0202984:	00093a03          	ld	s4,0(s2)
    if (PPN(pa) >= npage)
ffffffffc0202988:	608c                	ld	a1,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc020298a:	000a3683          	ld	a3,0(s4)
ffffffffc020298e:	068a                	slli	a3,a3,0x2
ffffffffc0202990:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage)
ffffffffc0202992:	42b6fd63          	bgeu	a3,a1,ffffffffc0202dcc <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202996:	000bb503          	ld	a0,0(s7)
ffffffffc020299a:	96d6                	add	a3,a3,s5
ffffffffc020299c:	069a                	slli	a3,a3,0x6
    return page->ref;
ffffffffc020299e:	00d507b3          	add	a5,a0,a3
ffffffffc02029a2:	439c                	lw	a5,0(a5)
ffffffffc02029a4:	4d979463          	bne	a5,s9,ffffffffc0202e6c <pmm_init+0x806>
    return page - pages + nbase;
ffffffffc02029a8:	8699                	srai	a3,a3,0x6
ffffffffc02029aa:	00080637          	lui	a2,0x80
ffffffffc02029ae:	96b2                	add	a3,a3,a2
    return KADDR(page2pa(page));
ffffffffc02029b0:	00c69713          	slli	a4,a3,0xc
ffffffffc02029b4:	8331                	srli	a4,a4,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc02029b6:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02029b8:	48b77e63          	bgeu	a4,a1,ffffffffc0202e54 <pmm_init+0x7ee>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
    free_page(pde2page(pd0[0]));
ffffffffc02029bc:	0009b703          	ld	a4,0(s3)
ffffffffc02029c0:	96ba                	add	a3,a3,a4
    return pa2page(PDE_ADDR(pde));
ffffffffc02029c2:	629c                	ld	a5,0(a3)
ffffffffc02029c4:	078a                	slli	a5,a5,0x2
ffffffffc02029c6:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02029c8:	40b7f263          	bgeu	a5,a1,ffffffffc0202dcc <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc02029cc:	8f91                	sub	a5,a5,a2
ffffffffc02029ce:	079a                	slli	a5,a5,0x6
ffffffffc02029d0:	953e                	add	a0,a0,a5
ffffffffc02029d2:	100027f3          	csrr	a5,sstatus
ffffffffc02029d6:	8b89                	andi	a5,a5,2
ffffffffc02029d8:	30079963          	bnez	a5,ffffffffc0202cea <pmm_init+0x684>
        pmm_manager->free_pages(base, n);
ffffffffc02029dc:	000b3783          	ld	a5,0(s6)
ffffffffc02029e0:	4585                	li	a1,1
ffffffffc02029e2:	739c                	ld	a5,32(a5)
ffffffffc02029e4:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc02029e6:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage)
ffffffffc02029ea:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc02029ec:	078a                	slli	a5,a5,0x2
ffffffffc02029ee:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02029f0:	3ce7fe63          	bgeu	a5,a4,ffffffffc0202dcc <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc02029f4:	000bb503          	ld	a0,0(s7)
ffffffffc02029f8:	fff80737          	lui	a4,0xfff80
ffffffffc02029fc:	97ba                	add	a5,a5,a4
ffffffffc02029fe:	079a                	slli	a5,a5,0x6
ffffffffc0202a00:	953e                	add	a0,a0,a5
ffffffffc0202a02:	100027f3          	csrr	a5,sstatus
ffffffffc0202a06:	8b89                	andi	a5,a5,2
ffffffffc0202a08:	2c079563          	bnez	a5,ffffffffc0202cd2 <pmm_init+0x66c>
ffffffffc0202a0c:	000b3783          	ld	a5,0(s6)
ffffffffc0202a10:	4585                	li	a1,1
ffffffffc0202a12:	739c                	ld	a5,32(a5)
ffffffffc0202a14:	9782                	jalr	a5
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc0202a16:	00093783          	ld	a5,0(s2)
ffffffffc0202a1a:	0007b023          	sd	zero,0(a5) # fffffffffffff000 <end+0x3fd382f8>
    asm volatile("sfence.vma");
ffffffffc0202a1e:	12000073          	sfence.vma
ffffffffc0202a22:	100027f3          	csrr	a5,sstatus
ffffffffc0202a26:	8b89                	andi	a5,a5,2
ffffffffc0202a28:	28079b63          	bnez	a5,ffffffffc0202cbe <pmm_init+0x658>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202a2c:	000b3783          	ld	a5,0(s6)
ffffffffc0202a30:	779c                	ld	a5,40(a5)
ffffffffc0202a32:	9782                	jalr	a5
ffffffffc0202a34:	8a2a                	mv	s4,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc0202a36:	4b441b63          	bne	s0,s4,ffffffffc0202eec <pmm_init+0x886>

    cprintf("check_pgdir() succeeded!\n");
ffffffffc0202a3a:	00004517          	auipc	a0,0x4
ffffffffc0202a3e:	1b650513          	addi	a0,a0,438 # ffffffffc0206bf0 <default_pmm_manager+0x560>
ffffffffc0202a42:	f56fd0ef          	jal	ra,ffffffffc0200198 <cprintf>
ffffffffc0202a46:	100027f3          	csrr	a5,sstatus
ffffffffc0202a4a:	8b89                	andi	a5,a5,2
ffffffffc0202a4c:	24079f63          	bnez	a5,ffffffffc0202caa <pmm_init+0x644>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202a50:	000b3783          	ld	a5,0(s6)
ffffffffc0202a54:	779c                	ld	a5,40(a5)
ffffffffc0202a56:	9782                	jalr	a5
ffffffffc0202a58:	8c2a                	mv	s8,a0
    pte_t *ptep;
    int i;

    nr_free_store = nr_free_pages();

    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202a5a:	6098                	ld	a4,0(s1)
ffffffffc0202a5c:	c0200437          	lui	s0,0xc0200
    {
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202a60:	7afd                	lui	s5,0xfffff
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202a62:	00c71793          	slli	a5,a4,0xc
ffffffffc0202a66:	6a05                	lui	s4,0x1
ffffffffc0202a68:	02f47c63          	bgeu	s0,a5,ffffffffc0202aa0 <pmm_init+0x43a>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202a6c:	00c45793          	srli	a5,s0,0xc
ffffffffc0202a70:	00093503          	ld	a0,0(s2)
ffffffffc0202a74:	2ee7ff63          	bgeu	a5,a4,ffffffffc0202d72 <pmm_init+0x70c>
ffffffffc0202a78:	0009b583          	ld	a1,0(s3)
ffffffffc0202a7c:	4601                	li	a2,0
ffffffffc0202a7e:	95a2                	add	a1,a1,s0
ffffffffc0202a80:	c00ff0ef          	jal	ra,ffffffffc0201e80 <get_pte>
ffffffffc0202a84:	32050463          	beqz	a0,ffffffffc0202dac <pmm_init+0x746>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202a88:	611c                	ld	a5,0(a0)
ffffffffc0202a8a:	078a                	slli	a5,a5,0x2
ffffffffc0202a8c:	0157f7b3          	and	a5,a5,s5
ffffffffc0202a90:	2e879e63          	bne	a5,s0,ffffffffc0202d8c <pmm_init+0x726>
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202a94:	6098                	ld	a4,0(s1)
ffffffffc0202a96:	9452                	add	s0,s0,s4
ffffffffc0202a98:	00c71793          	slli	a5,a4,0xc
ffffffffc0202a9c:	fcf468e3          	bltu	s0,a5,ffffffffc0202a6c <pmm_init+0x406>
    }

    assert(boot_pgdir_va[0] == 0);
ffffffffc0202aa0:	00093783          	ld	a5,0(s2)
ffffffffc0202aa4:	639c                	ld	a5,0(a5)
ffffffffc0202aa6:	42079363          	bnez	a5,ffffffffc0202ecc <pmm_init+0x866>
ffffffffc0202aaa:	100027f3          	csrr	a5,sstatus
ffffffffc0202aae:	8b89                	andi	a5,a5,2
ffffffffc0202ab0:	24079963          	bnez	a5,ffffffffc0202d02 <pmm_init+0x69c>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202ab4:	000b3783          	ld	a5,0(s6)
ffffffffc0202ab8:	4505                	li	a0,1
ffffffffc0202aba:	6f9c                	ld	a5,24(a5)
ffffffffc0202abc:	9782                	jalr	a5
ffffffffc0202abe:	8a2a                	mv	s4,a0

    struct Page *p;
    p = alloc_page();
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0202ac0:	00093503          	ld	a0,0(s2)
ffffffffc0202ac4:	4699                	li	a3,6
ffffffffc0202ac6:	10000613          	li	a2,256
ffffffffc0202aca:	85d2                	mv	a1,s4
ffffffffc0202acc:	aa5ff0ef          	jal	ra,ffffffffc0202570 <page_insert>
ffffffffc0202ad0:	44051e63          	bnez	a0,ffffffffc0202f2c <pmm_init+0x8c6>
    assert(page_ref(p) == 1);
ffffffffc0202ad4:	000a2703          	lw	a4,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8f48>
ffffffffc0202ad8:	4785                	li	a5,1
ffffffffc0202ada:	42f71963          	bne	a4,a5,ffffffffc0202f0c <pmm_init+0x8a6>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc0202ade:	00093503          	ld	a0,0(s2)
ffffffffc0202ae2:	6405                	lui	s0,0x1
ffffffffc0202ae4:	4699                	li	a3,6
ffffffffc0202ae6:	10040613          	addi	a2,s0,256 # 1100 <_binary_obj___user_faultread_out_size-0x8e48>
ffffffffc0202aea:	85d2                	mv	a1,s4
ffffffffc0202aec:	a85ff0ef          	jal	ra,ffffffffc0202570 <page_insert>
ffffffffc0202af0:	72051363          	bnez	a0,ffffffffc0203216 <pmm_init+0xbb0>
    assert(page_ref(p) == 2);
ffffffffc0202af4:	000a2703          	lw	a4,0(s4)
ffffffffc0202af8:	4789                	li	a5,2
ffffffffc0202afa:	6ef71e63          	bne	a4,a5,ffffffffc02031f6 <pmm_init+0xb90>

    const char *str = "ucore: Hello world!!";
    strcpy((void *)0x100, str);
ffffffffc0202afe:	00004597          	auipc	a1,0x4
ffffffffc0202b02:	23a58593          	addi	a1,a1,570 # ffffffffc0206d38 <default_pmm_manager+0x6a8>
ffffffffc0202b06:	10000513          	li	a0,256
ffffffffc0202b0a:	4af020ef          	jal	ra,ffffffffc02057b8 <strcpy>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc0202b0e:	10040593          	addi	a1,s0,256
ffffffffc0202b12:	10000513          	li	a0,256
ffffffffc0202b16:	4b5020ef          	jal	ra,ffffffffc02057ca <strcmp>
ffffffffc0202b1a:	6a051e63          	bnez	a0,ffffffffc02031d6 <pmm_init+0xb70>
    return page - pages + nbase;
ffffffffc0202b1e:	000bb683          	ld	a3,0(s7)
ffffffffc0202b22:	00080737          	lui	a4,0x80
    return KADDR(page2pa(page));
ffffffffc0202b26:	547d                	li	s0,-1
    return page - pages + nbase;
ffffffffc0202b28:	40da06b3          	sub	a3,s4,a3
ffffffffc0202b2c:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0202b2e:	609c                	ld	a5,0(s1)
    return page - pages + nbase;
ffffffffc0202b30:	96ba                	add	a3,a3,a4
    return KADDR(page2pa(page));
ffffffffc0202b32:	8031                	srli	s0,s0,0xc
ffffffffc0202b34:	0086f733          	and	a4,a3,s0
    return page2ppn(page) << PGSHIFT;
ffffffffc0202b38:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202b3a:	30f77d63          	bgeu	a4,a5,ffffffffc0202e54 <pmm_init+0x7ee>

    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0202b3e:	0009b783          	ld	a5,0(s3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202b42:	10000513          	li	a0,256
    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0202b46:	96be                	add	a3,a3,a5
ffffffffc0202b48:	10068023          	sb	zero,256(a3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202b4c:	437020ef          	jal	ra,ffffffffc0205782 <strlen>
ffffffffc0202b50:	66051363          	bnez	a0,ffffffffc02031b6 <pmm_init+0xb50>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
ffffffffc0202b54:	00093a83          	ld	s5,0(s2)
    if (PPN(pa) >= npage)
ffffffffc0202b58:	609c                	ld	a5,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202b5a:	000ab683          	ld	a3,0(s5) # fffffffffffff000 <end+0x3fd382f8>
ffffffffc0202b5e:	068a                	slli	a3,a3,0x2
ffffffffc0202b60:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage)
ffffffffc0202b62:	26f6f563          	bgeu	a3,a5,ffffffffc0202dcc <pmm_init+0x766>
    return KADDR(page2pa(page));
ffffffffc0202b66:	8c75                	and	s0,s0,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc0202b68:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202b6a:	2ef47563          	bgeu	s0,a5,ffffffffc0202e54 <pmm_init+0x7ee>
ffffffffc0202b6e:	0009b403          	ld	s0,0(s3)
ffffffffc0202b72:	9436                	add	s0,s0,a3
ffffffffc0202b74:	100027f3          	csrr	a5,sstatus
ffffffffc0202b78:	8b89                	andi	a5,a5,2
ffffffffc0202b7a:	1e079163          	bnez	a5,ffffffffc0202d5c <pmm_init+0x6f6>
        pmm_manager->free_pages(base, n);
ffffffffc0202b7e:	000b3783          	ld	a5,0(s6)
ffffffffc0202b82:	4585                	li	a1,1
ffffffffc0202b84:	8552                	mv	a0,s4
ffffffffc0202b86:	739c                	ld	a5,32(a5)
ffffffffc0202b88:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202b8a:	601c                	ld	a5,0(s0)
    if (PPN(pa) >= npage)
ffffffffc0202b8c:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202b8e:	078a                	slli	a5,a5,0x2
ffffffffc0202b90:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202b92:	22e7fd63          	bgeu	a5,a4,ffffffffc0202dcc <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202b96:	000bb503          	ld	a0,0(s7)
ffffffffc0202b9a:	fff80737          	lui	a4,0xfff80
ffffffffc0202b9e:	97ba                	add	a5,a5,a4
ffffffffc0202ba0:	079a                	slli	a5,a5,0x6
ffffffffc0202ba2:	953e                	add	a0,a0,a5
ffffffffc0202ba4:	100027f3          	csrr	a5,sstatus
ffffffffc0202ba8:	8b89                	andi	a5,a5,2
ffffffffc0202baa:	18079d63          	bnez	a5,ffffffffc0202d44 <pmm_init+0x6de>
ffffffffc0202bae:	000b3783          	ld	a5,0(s6)
ffffffffc0202bb2:	4585                	li	a1,1
ffffffffc0202bb4:	739c                	ld	a5,32(a5)
ffffffffc0202bb6:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202bb8:	000ab783          	ld	a5,0(s5)
    if (PPN(pa) >= npage)
ffffffffc0202bbc:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202bbe:	078a                	slli	a5,a5,0x2
ffffffffc0202bc0:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202bc2:	20e7f563          	bgeu	a5,a4,ffffffffc0202dcc <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202bc6:	000bb503          	ld	a0,0(s7)
ffffffffc0202bca:	fff80737          	lui	a4,0xfff80
ffffffffc0202bce:	97ba                	add	a5,a5,a4
ffffffffc0202bd0:	079a                	slli	a5,a5,0x6
ffffffffc0202bd2:	953e                	add	a0,a0,a5
ffffffffc0202bd4:	100027f3          	csrr	a5,sstatus
ffffffffc0202bd8:	8b89                	andi	a5,a5,2
ffffffffc0202bda:	14079963          	bnez	a5,ffffffffc0202d2c <pmm_init+0x6c6>
ffffffffc0202bde:	000b3783          	ld	a5,0(s6)
ffffffffc0202be2:	4585                	li	a1,1
ffffffffc0202be4:	739c                	ld	a5,32(a5)
ffffffffc0202be6:	9782                	jalr	a5
    free_page(p);
    free_page(pde2page(pd0[0]));
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc0202be8:	00093783          	ld	a5,0(s2)
ffffffffc0202bec:	0007b023          	sd	zero,0(a5)
    asm volatile("sfence.vma");
ffffffffc0202bf0:	12000073          	sfence.vma
ffffffffc0202bf4:	100027f3          	csrr	a5,sstatus
ffffffffc0202bf8:	8b89                	andi	a5,a5,2
ffffffffc0202bfa:	10079f63          	bnez	a5,ffffffffc0202d18 <pmm_init+0x6b2>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202bfe:	000b3783          	ld	a5,0(s6)
ffffffffc0202c02:	779c                	ld	a5,40(a5)
ffffffffc0202c04:	9782                	jalr	a5
ffffffffc0202c06:	842a                	mv	s0,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc0202c08:	4c8c1e63          	bne	s8,s0,ffffffffc02030e4 <pmm_init+0xa7e>

    cprintf("check_boot_pgdir() succeeded!\n");
ffffffffc0202c0c:	00004517          	auipc	a0,0x4
ffffffffc0202c10:	1a450513          	addi	a0,a0,420 # ffffffffc0206db0 <default_pmm_manager+0x720>
ffffffffc0202c14:	d84fd0ef          	jal	ra,ffffffffc0200198 <cprintf>
}
ffffffffc0202c18:	7406                	ld	s0,96(sp)
ffffffffc0202c1a:	70a6                	ld	ra,104(sp)
ffffffffc0202c1c:	64e6                	ld	s1,88(sp)
ffffffffc0202c1e:	6946                	ld	s2,80(sp)
ffffffffc0202c20:	69a6                	ld	s3,72(sp)
ffffffffc0202c22:	6a06                	ld	s4,64(sp)
ffffffffc0202c24:	7ae2                	ld	s5,56(sp)
ffffffffc0202c26:	7b42                	ld	s6,48(sp)
ffffffffc0202c28:	7ba2                	ld	s7,40(sp)
ffffffffc0202c2a:	7c02                	ld	s8,32(sp)
ffffffffc0202c2c:	6ce2                	ld	s9,24(sp)
ffffffffc0202c2e:	6165                	addi	sp,sp,112
    kmalloc_init();
ffffffffc0202c30:	f97fe06f          	j	ffffffffc0201bc6 <kmalloc_init>
    npage = maxpa / PGSIZE;
ffffffffc0202c34:	c80007b7          	lui	a5,0xc8000
ffffffffc0202c38:	bc7d                	j	ffffffffc02026f6 <pmm_init+0x90>
        intr_disable();
ffffffffc0202c3a:	d75fd0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202c3e:	000b3783          	ld	a5,0(s6)
ffffffffc0202c42:	4505                	li	a0,1
ffffffffc0202c44:	6f9c                	ld	a5,24(a5)
ffffffffc0202c46:	9782                	jalr	a5
ffffffffc0202c48:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc0202c4a:	d5ffd0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0202c4e:	b9a9                	j	ffffffffc02028a8 <pmm_init+0x242>
        intr_disable();
ffffffffc0202c50:	d5ffd0ef          	jal	ra,ffffffffc02009ae <intr_disable>
ffffffffc0202c54:	000b3783          	ld	a5,0(s6)
ffffffffc0202c58:	4505                	li	a0,1
ffffffffc0202c5a:	6f9c                	ld	a5,24(a5)
ffffffffc0202c5c:	9782                	jalr	a5
ffffffffc0202c5e:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202c60:	d49fd0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0202c64:	b645                	j	ffffffffc0202804 <pmm_init+0x19e>
        intr_disable();
ffffffffc0202c66:	d49fd0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202c6a:	000b3783          	ld	a5,0(s6)
ffffffffc0202c6e:	779c                	ld	a5,40(a5)
ffffffffc0202c70:	9782                	jalr	a5
ffffffffc0202c72:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202c74:	d35fd0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0202c78:	b6b9                	j	ffffffffc02027c6 <pmm_init+0x160>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0202c7a:	6705                	lui	a4,0x1
ffffffffc0202c7c:	177d                	addi	a4,a4,-1
ffffffffc0202c7e:	96ba                	add	a3,a3,a4
ffffffffc0202c80:	8ff5                	and	a5,a5,a3
    if (PPN(pa) >= npage)
ffffffffc0202c82:	00c7d713          	srli	a4,a5,0xc
ffffffffc0202c86:	14a77363          	bgeu	a4,a0,ffffffffc0202dcc <pmm_init+0x766>
    pmm_manager->init_memmap(base, n);
ffffffffc0202c8a:	000b3683          	ld	a3,0(s6)
    return &pages[PPN(pa) - nbase];
ffffffffc0202c8e:	fff80537          	lui	a0,0xfff80
ffffffffc0202c92:	972a                	add	a4,a4,a0
ffffffffc0202c94:	6a94                	ld	a3,16(a3)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0202c96:	8c1d                	sub	s0,s0,a5
ffffffffc0202c98:	00671513          	slli	a0,a4,0x6
    pmm_manager->init_memmap(base, n);
ffffffffc0202c9c:	00c45593          	srli	a1,s0,0xc
ffffffffc0202ca0:	9532                	add	a0,a0,a2
ffffffffc0202ca2:	9682                	jalr	a3
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc0202ca4:	0009b583          	ld	a1,0(s3)
}
ffffffffc0202ca8:	b4c1                	j	ffffffffc0202768 <pmm_init+0x102>
        intr_disable();
ffffffffc0202caa:	d05fd0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202cae:	000b3783          	ld	a5,0(s6)
ffffffffc0202cb2:	779c                	ld	a5,40(a5)
ffffffffc0202cb4:	9782                	jalr	a5
ffffffffc0202cb6:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc0202cb8:	cf1fd0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0202cbc:	bb79                	j	ffffffffc0202a5a <pmm_init+0x3f4>
        intr_disable();
ffffffffc0202cbe:	cf1fd0ef          	jal	ra,ffffffffc02009ae <intr_disable>
ffffffffc0202cc2:	000b3783          	ld	a5,0(s6)
ffffffffc0202cc6:	779c                	ld	a5,40(a5)
ffffffffc0202cc8:	9782                	jalr	a5
ffffffffc0202cca:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202ccc:	cddfd0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0202cd0:	b39d                	j	ffffffffc0202a36 <pmm_init+0x3d0>
ffffffffc0202cd2:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202cd4:	cdbfd0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202cd8:	000b3783          	ld	a5,0(s6)
ffffffffc0202cdc:	6522                	ld	a0,8(sp)
ffffffffc0202cde:	4585                	li	a1,1
ffffffffc0202ce0:	739c                	ld	a5,32(a5)
ffffffffc0202ce2:	9782                	jalr	a5
        intr_enable();
ffffffffc0202ce4:	cc5fd0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0202ce8:	b33d                	j	ffffffffc0202a16 <pmm_init+0x3b0>
ffffffffc0202cea:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202cec:	cc3fd0ef          	jal	ra,ffffffffc02009ae <intr_disable>
ffffffffc0202cf0:	000b3783          	ld	a5,0(s6)
ffffffffc0202cf4:	6522                	ld	a0,8(sp)
ffffffffc0202cf6:	4585                	li	a1,1
ffffffffc0202cf8:	739c                	ld	a5,32(a5)
ffffffffc0202cfa:	9782                	jalr	a5
        intr_enable();
ffffffffc0202cfc:	cadfd0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0202d00:	b1dd                	j	ffffffffc02029e6 <pmm_init+0x380>
        intr_disable();
ffffffffc0202d02:	cadfd0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202d06:	000b3783          	ld	a5,0(s6)
ffffffffc0202d0a:	4505                	li	a0,1
ffffffffc0202d0c:	6f9c                	ld	a5,24(a5)
ffffffffc0202d0e:	9782                	jalr	a5
ffffffffc0202d10:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202d12:	c97fd0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0202d16:	b36d                	j	ffffffffc0202ac0 <pmm_init+0x45a>
        intr_disable();
ffffffffc0202d18:	c97fd0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202d1c:	000b3783          	ld	a5,0(s6)
ffffffffc0202d20:	779c                	ld	a5,40(a5)
ffffffffc0202d22:	9782                	jalr	a5
ffffffffc0202d24:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202d26:	c83fd0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0202d2a:	bdf9                	j	ffffffffc0202c08 <pmm_init+0x5a2>
ffffffffc0202d2c:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202d2e:	c81fd0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202d32:	000b3783          	ld	a5,0(s6)
ffffffffc0202d36:	6522                	ld	a0,8(sp)
ffffffffc0202d38:	4585                	li	a1,1
ffffffffc0202d3a:	739c                	ld	a5,32(a5)
ffffffffc0202d3c:	9782                	jalr	a5
        intr_enable();
ffffffffc0202d3e:	c6bfd0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0202d42:	b55d                	j	ffffffffc0202be8 <pmm_init+0x582>
ffffffffc0202d44:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202d46:	c69fd0ef          	jal	ra,ffffffffc02009ae <intr_disable>
ffffffffc0202d4a:	000b3783          	ld	a5,0(s6)
ffffffffc0202d4e:	6522                	ld	a0,8(sp)
ffffffffc0202d50:	4585                	li	a1,1
ffffffffc0202d52:	739c                	ld	a5,32(a5)
ffffffffc0202d54:	9782                	jalr	a5
        intr_enable();
ffffffffc0202d56:	c53fd0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0202d5a:	bdb9                	j	ffffffffc0202bb8 <pmm_init+0x552>
        intr_disable();
ffffffffc0202d5c:	c53fd0ef          	jal	ra,ffffffffc02009ae <intr_disable>
ffffffffc0202d60:	000b3783          	ld	a5,0(s6)
ffffffffc0202d64:	4585                	li	a1,1
ffffffffc0202d66:	8552                	mv	a0,s4
ffffffffc0202d68:	739c                	ld	a5,32(a5)
ffffffffc0202d6a:	9782                	jalr	a5
        intr_enable();
ffffffffc0202d6c:	c3dfd0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0202d70:	bd29                	j	ffffffffc0202b8a <pmm_init+0x524>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202d72:	86a2                	mv	a3,s0
ffffffffc0202d74:	00004617          	auipc	a2,0x4
ffffffffc0202d78:	95460613          	addi	a2,a2,-1708 # ffffffffc02066c8 <default_pmm_manager+0x38>
ffffffffc0202d7c:	23c00593          	li	a1,572
ffffffffc0202d80:	00004517          	auipc	a0,0x4
ffffffffc0202d84:	a6050513          	addi	a0,a0,-1440 # ffffffffc02067e0 <default_pmm_manager+0x150>
ffffffffc0202d88:	f0afd0ef          	jal	ra,ffffffffc0200492 <__panic>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202d8c:	00004697          	auipc	a3,0x4
ffffffffc0202d90:	ec468693          	addi	a3,a3,-316 # ffffffffc0206c50 <default_pmm_manager+0x5c0>
ffffffffc0202d94:	00003617          	auipc	a2,0x3
ffffffffc0202d98:	54c60613          	addi	a2,a2,1356 # ffffffffc02062e0 <commands+0x828>
ffffffffc0202d9c:	23d00593          	li	a1,573
ffffffffc0202da0:	00004517          	auipc	a0,0x4
ffffffffc0202da4:	a4050513          	addi	a0,a0,-1472 # ffffffffc02067e0 <default_pmm_manager+0x150>
ffffffffc0202da8:	eeafd0ef          	jal	ra,ffffffffc0200492 <__panic>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202dac:	00004697          	auipc	a3,0x4
ffffffffc0202db0:	e6468693          	addi	a3,a3,-412 # ffffffffc0206c10 <default_pmm_manager+0x580>
ffffffffc0202db4:	00003617          	auipc	a2,0x3
ffffffffc0202db8:	52c60613          	addi	a2,a2,1324 # ffffffffc02062e0 <commands+0x828>
ffffffffc0202dbc:	23c00593          	li	a1,572
ffffffffc0202dc0:	00004517          	auipc	a0,0x4
ffffffffc0202dc4:	a2050513          	addi	a0,a0,-1504 # ffffffffc02067e0 <default_pmm_manager+0x150>
ffffffffc0202dc8:	ecafd0ef          	jal	ra,ffffffffc0200492 <__panic>
ffffffffc0202dcc:	fc5fe0ef          	jal	ra,ffffffffc0201d90 <pa2page.part.0>
ffffffffc0202dd0:	fddfe0ef          	jal	ra,ffffffffc0201dac <pte2page.part.0>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202dd4:	00004697          	auipc	a3,0x4
ffffffffc0202dd8:	c3468693          	addi	a3,a3,-972 # ffffffffc0206a08 <default_pmm_manager+0x378>
ffffffffc0202ddc:	00003617          	auipc	a2,0x3
ffffffffc0202de0:	50460613          	addi	a2,a2,1284 # ffffffffc02062e0 <commands+0x828>
ffffffffc0202de4:	20c00593          	li	a1,524
ffffffffc0202de8:	00004517          	auipc	a0,0x4
ffffffffc0202dec:	9f850513          	addi	a0,a0,-1544 # ffffffffc02067e0 <default_pmm_manager+0x150>
ffffffffc0202df0:	ea2fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc0202df4:	00004697          	auipc	a3,0x4
ffffffffc0202df8:	b5468693          	addi	a3,a3,-1196 # ffffffffc0206948 <default_pmm_manager+0x2b8>
ffffffffc0202dfc:	00003617          	auipc	a2,0x3
ffffffffc0202e00:	4e460613          	addi	a2,a2,1252 # ffffffffc02062e0 <commands+0x828>
ffffffffc0202e04:	1ff00593          	li	a1,511
ffffffffc0202e08:	00004517          	auipc	a0,0x4
ffffffffc0202e0c:	9d850513          	addi	a0,a0,-1576 # ffffffffc02067e0 <default_pmm_manager+0x150>
ffffffffc0202e10:	e82fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc0202e14:	00004697          	auipc	a3,0x4
ffffffffc0202e18:	af468693          	addi	a3,a3,-1292 # ffffffffc0206908 <default_pmm_manager+0x278>
ffffffffc0202e1c:	00003617          	auipc	a2,0x3
ffffffffc0202e20:	4c460613          	addi	a2,a2,1220 # ffffffffc02062e0 <commands+0x828>
ffffffffc0202e24:	1fe00593          	li	a1,510
ffffffffc0202e28:	00004517          	auipc	a0,0x4
ffffffffc0202e2c:	9b850513          	addi	a0,a0,-1608 # ffffffffc02067e0 <default_pmm_manager+0x150>
ffffffffc0202e30:	e62fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(npage <= KERNTOP / PGSIZE);
ffffffffc0202e34:	00004697          	auipc	a3,0x4
ffffffffc0202e38:	ab468693          	addi	a3,a3,-1356 # ffffffffc02068e8 <default_pmm_manager+0x258>
ffffffffc0202e3c:	00003617          	auipc	a2,0x3
ffffffffc0202e40:	4a460613          	addi	a2,a2,1188 # ffffffffc02062e0 <commands+0x828>
ffffffffc0202e44:	1fd00593          	li	a1,509
ffffffffc0202e48:	00004517          	auipc	a0,0x4
ffffffffc0202e4c:	99850513          	addi	a0,a0,-1640 # ffffffffc02067e0 <default_pmm_manager+0x150>
ffffffffc0202e50:	e42fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    return KADDR(page2pa(page));
ffffffffc0202e54:	00004617          	auipc	a2,0x4
ffffffffc0202e58:	87460613          	addi	a2,a2,-1932 # ffffffffc02066c8 <default_pmm_manager+0x38>
ffffffffc0202e5c:	07100593          	li	a1,113
ffffffffc0202e60:	00004517          	auipc	a0,0x4
ffffffffc0202e64:	89050513          	addi	a0,a0,-1904 # ffffffffc02066f0 <default_pmm_manager+0x60>
ffffffffc0202e68:	e2afd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc0202e6c:	00004697          	auipc	a3,0x4
ffffffffc0202e70:	d2c68693          	addi	a3,a3,-724 # ffffffffc0206b98 <default_pmm_manager+0x508>
ffffffffc0202e74:	00003617          	auipc	a2,0x3
ffffffffc0202e78:	46c60613          	addi	a2,a2,1132 # ffffffffc02062e0 <commands+0x828>
ffffffffc0202e7c:	22500593          	li	a1,549
ffffffffc0202e80:	00004517          	auipc	a0,0x4
ffffffffc0202e84:	96050513          	addi	a0,a0,-1696 # ffffffffc02067e0 <default_pmm_manager+0x150>
ffffffffc0202e88:	e0afd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0202e8c:	00004697          	auipc	a3,0x4
ffffffffc0202e90:	cc468693          	addi	a3,a3,-828 # ffffffffc0206b50 <default_pmm_manager+0x4c0>
ffffffffc0202e94:	00003617          	auipc	a2,0x3
ffffffffc0202e98:	44c60613          	addi	a2,a2,1100 # ffffffffc02062e0 <commands+0x828>
ffffffffc0202e9c:	22300593          	li	a1,547
ffffffffc0202ea0:	00004517          	auipc	a0,0x4
ffffffffc0202ea4:	94050513          	addi	a0,a0,-1728 # ffffffffc02067e0 <default_pmm_manager+0x150>
ffffffffc0202ea8:	deafd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_ref(p1) == 0);
ffffffffc0202eac:	00004697          	auipc	a3,0x4
ffffffffc0202eb0:	cd468693          	addi	a3,a3,-812 # ffffffffc0206b80 <default_pmm_manager+0x4f0>
ffffffffc0202eb4:	00003617          	auipc	a2,0x3
ffffffffc0202eb8:	42c60613          	addi	a2,a2,1068 # ffffffffc02062e0 <commands+0x828>
ffffffffc0202ebc:	22200593          	li	a1,546
ffffffffc0202ec0:	00004517          	auipc	a0,0x4
ffffffffc0202ec4:	92050513          	addi	a0,a0,-1760 # ffffffffc02067e0 <default_pmm_manager+0x150>
ffffffffc0202ec8:	dcafd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(boot_pgdir_va[0] == 0);
ffffffffc0202ecc:	00004697          	auipc	a3,0x4
ffffffffc0202ed0:	d9c68693          	addi	a3,a3,-612 # ffffffffc0206c68 <default_pmm_manager+0x5d8>
ffffffffc0202ed4:	00003617          	auipc	a2,0x3
ffffffffc0202ed8:	40c60613          	addi	a2,a2,1036 # ffffffffc02062e0 <commands+0x828>
ffffffffc0202edc:	24000593          	li	a1,576
ffffffffc0202ee0:	00004517          	auipc	a0,0x4
ffffffffc0202ee4:	90050513          	addi	a0,a0,-1792 # ffffffffc02067e0 <default_pmm_manager+0x150>
ffffffffc0202ee8:	daafd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc0202eec:	00004697          	auipc	a3,0x4
ffffffffc0202ef0:	cdc68693          	addi	a3,a3,-804 # ffffffffc0206bc8 <default_pmm_manager+0x538>
ffffffffc0202ef4:	00003617          	auipc	a2,0x3
ffffffffc0202ef8:	3ec60613          	addi	a2,a2,1004 # ffffffffc02062e0 <commands+0x828>
ffffffffc0202efc:	22d00593          	li	a1,557
ffffffffc0202f00:	00004517          	auipc	a0,0x4
ffffffffc0202f04:	8e050513          	addi	a0,a0,-1824 # ffffffffc02067e0 <default_pmm_manager+0x150>
ffffffffc0202f08:	d8afd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_ref(p) == 1);
ffffffffc0202f0c:	00004697          	auipc	a3,0x4
ffffffffc0202f10:	db468693          	addi	a3,a3,-588 # ffffffffc0206cc0 <default_pmm_manager+0x630>
ffffffffc0202f14:	00003617          	auipc	a2,0x3
ffffffffc0202f18:	3cc60613          	addi	a2,a2,972 # ffffffffc02062e0 <commands+0x828>
ffffffffc0202f1c:	24500593          	li	a1,581
ffffffffc0202f20:	00004517          	auipc	a0,0x4
ffffffffc0202f24:	8c050513          	addi	a0,a0,-1856 # ffffffffc02067e0 <default_pmm_manager+0x150>
ffffffffc0202f28:	d6afd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0202f2c:	00004697          	auipc	a3,0x4
ffffffffc0202f30:	d5468693          	addi	a3,a3,-684 # ffffffffc0206c80 <default_pmm_manager+0x5f0>
ffffffffc0202f34:	00003617          	auipc	a2,0x3
ffffffffc0202f38:	3ac60613          	addi	a2,a2,940 # ffffffffc02062e0 <commands+0x828>
ffffffffc0202f3c:	24400593          	li	a1,580
ffffffffc0202f40:	00004517          	auipc	a0,0x4
ffffffffc0202f44:	8a050513          	addi	a0,a0,-1888 # ffffffffc02067e0 <default_pmm_manager+0x150>
ffffffffc0202f48:	d4afd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0202f4c:	00004697          	auipc	a3,0x4
ffffffffc0202f50:	c0468693          	addi	a3,a3,-1020 # ffffffffc0206b50 <default_pmm_manager+0x4c0>
ffffffffc0202f54:	00003617          	auipc	a2,0x3
ffffffffc0202f58:	38c60613          	addi	a2,a2,908 # ffffffffc02062e0 <commands+0x828>
ffffffffc0202f5c:	21f00593          	li	a1,543
ffffffffc0202f60:	00004517          	auipc	a0,0x4
ffffffffc0202f64:	88050513          	addi	a0,a0,-1920 # ffffffffc02067e0 <default_pmm_manager+0x150>
ffffffffc0202f68:	d2afd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_ref(p1) == 1);
ffffffffc0202f6c:	00004697          	auipc	a3,0x4
ffffffffc0202f70:	a8468693          	addi	a3,a3,-1404 # ffffffffc02069f0 <default_pmm_manager+0x360>
ffffffffc0202f74:	00003617          	auipc	a2,0x3
ffffffffc0202f78:	36c60613          	addi	a2,a2,876 # ffffffffc02062e0 <commands+0x828>
ffffffffc0202f7c:	21e00593          	li	a1,542
ffffffffc0202f80:	00004517          	auipc	a0,0x4
ffffffffc0202f84:	86050513          	addi	a0,a0,-1952 # ffffffffc02067e0 <default_pmm_manager+0x150>
ffffffffc0202f88:	d0afd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((*ptep & PTE_U) == 0);
ffffffffc0202f8c:	00004697          	auipc	a3,0x4
ffffffffc0202f90:	bdc68693          	addi	a3,a3,-1060 # ffffffffc0206b68 <default_pmm_manager+0x4d8>
ffffffffc0202f94:	00003617          	auipc	a2,0x3
ffffffffc0202f98:	34c60613          	addi	a2,a2,844 # ffffffffc02062e0 <commands+0x828>
ffffffffc0202f9c:	21b00593          	li	a1,539
ffffffffc0202fa0:	00004517          	auipc	a0,0x4
ffffffffc0202fa4:	84050513          	addi	a0,a0,-1984 # ffffffffc02067e0 <default_pmm_manager+0x150>
ffffffffc0202fa8:	ceafd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc0202fac:	00004697          	auipc	a3,0x4
ffffffffc0202fb0:	a2c68693          	addi	a3,a3,-1492 # ffffffffc02069d8 <default_pmm_manager+0x348>
ffffffffc0202fb4:	00003617          	auipc	a2,0x3
ffffffffc0202fb8:	32c60613          	addi	a2,a2,812 # ffffffffc02062e0 <commands+0x828>
ffffffffc0202fbc:	21a00593          	li	a1,538
ffffffffc0202fc0:	00004517          	auipc	a0,0x4
ffffffffc0202fc4:	82050513          	addi	a0,a0,-2016 # ffffffffc02067e0 <default_pmm_manager+0x150>
ffffffffc0202fc8:	ccafd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0202fcc:	00004697          	auipc	a3,0x4
ffffffffc0202fd0:	aac68693          	addi	a3,a3,-1364 # ffffffffc0206a78 <default_pmm_manager+0x3e8>
ffffffffc0202fd4:	00003617          	auipc	a2,0x3
ffffffffc0202fd8:	30c60613          	addi	a2,a2,780 # ffffffffc02062e0 <commands+0x828>
ffffffffc0202fdc:	21900593          	li	a1,537
ffffffffc0202fe0:	00004517          	auipc	a0,0x4
ffffffffc0202fe4:	80050513          	addi	a0,a0,-2048 # ffffffffc02067e0 <default_pmm_manager+0x150>
ffffffffc0202fe8:	caafd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0202fec:	00004697          	auipc	a3,0x4
ffffffffc0202ff0:	b6468693          	addi	a3,a3,-1180 # ffffffffc0206b50 <default_pmm_manager+0x4c0>
ffffffffc0202ff4:	00003617          	auipc	a2,0x3
ffffffffc0202ff8:	2ec60613          	addi	a2,a2,748 # ffffffffc02062e0 <commands+0x828>
ffffffffc0202ffc:	21800593          	li	a1,536
ffffffffc0203000:	00003517          	auipc	a0,0x3
ffffffffc0203004:	7e050513          	addi	a0,a0,2016 # ffffffffc02067e0 <default_pmm_manager+0x150>
ffffffffc0203008:	c8afd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_ref(p1) == 2);
ffffffffc020300c:	00004697          	auipc	a3,0x4
ffffffffc0203010:	b2c68693          	addi	a3,a3,-1236 # ffffffffc0206b38 <default_pmm_manager+0x4a8>
ffffffffc0203014:	00003617          	auipc	a2,0x3
ffffffffc0203018:	2cc60613          	addi	a2,a2,716 # ffffffffc02062e0 <commands+0x828>
ffffffffc020301c:	21700593          	li	a1,535
ffffffffc0203020:	00003517          	auipc	a0,0x3
ffffffffc0203024:	7c050513          	addi	a0,a0,1984 # ffffffffc02067e0 <default_pmm_manager+0x150>
ffffffffc0203028:	c6afd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc020302c:	00004697          	auipc	a3,0x4
ffffffffc0203030:	adc68693          	addi	a3,a3,-1316 # ffffffffc0206b08 <default_pmm_manager+0x478>
ffffffffc0203034:	00003617          	auipc	a2,0x3
ffffffffc0203038:	2ac60613          	addi	a2,a2,684 # ffffffffc02062e0 <commands+0x828>
ffffffffc020303c:	21600593          	li	a1,534
ffffffffc0203040:	00003517          	auipc	a0,0x3
ffffffffc0203044:	7a050513          	addi	a0,a0,1952 # ffffffffc02067e0 <default_pmm_manager+0x150>
ffffffffc0203048:	c4afd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_ref(p2) == 1);
ffffffffc020304c:	00004697          	auipc	a3,0x4
ffffffffc0203050:	aa468693          	addi	a3,a3,-1372 # ffffffffc0206af0 <default_pmm_manager+0x460>
ffffffffc0203054:	00003617          	auipc	a2,0x3
ffffffffc0203058:	28c60613          	addi	a2,a2,652 # ffffffffc02062e0 <commands+0x828>
ffffffffc020305c:	21400593          	li	a1,532
ffffffffc0203060:	00003517          	auipc	a0,0x3
ffffffffc0203064:	78050513          	addi	a0,a0,1920 # ffffffffc02067e0 <default_pmm_manager+0x150>
ffffffffc0203068:	c2afd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc020306c:	00004697          	auipc	a3,0x4
ffffffffc0203070:	a6468693          	addi	a3,a3,-1436 # ffffffffc0206ad0 <default_pmm_manager+0x440>
ffffffffc0203074:	00003617          	auipc	a2,0x3
ffffffffc0203078:	26c60613          	addi	a2,a2,620 # ffffffffc02062e0 <commands+0x828>
ffffffffc020307c:	21300593          	li	a1,531
ffffffffc0203080:	00003517          	auipc	a0,0x3
ffffffffc0203084:	76050513          	addi	a0,a0,1888 # ffffffffc02067e0 <default_pmm_manager+0x150>
ffffffffc0203088:	c0afd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(*ptep & PTE_W);
ffffffffc020308c:	00004697          	auipc	a3,0x4
ffffffffc0203090:	a3468693          	addi	a3,a3,-1484 # ffffffffc0206ac0 <default_pmm_manager+0x430>
ffffffffc0203094:	00003617          	auipc	a2,0x3
ffffffffc0203098:	24c60613          	addi	a2,a2,588 # ffffffffc02062e0 <commands+0x828>
ffffffffc020309c:	21200593          	li	a1,530
ffffffffc02030a0:	00003517          	auipc	a0,0x3
ffffffffc02030a4:	74050513          	addi	a0,a0,1856 # ffffffffc02067e0 <default_pmm_manager+0x150>
ffffffffc02030a8:	beafd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(*ptep & PTE_U);
ffffffffc02030ac:	00004697          	auipc	a3,0x4
ffffffffc02030b0:	a0468693          	addi	a3,a3,-1532 # ffffffffc0206ab0 <default_pmm_manager+0x420>
ffffffffc02030b4:	00003617          	auipc	a2,0x3
ffffffffc02030b8:	22c60613          	addi	a2,a2,556 # ffffffffc02062e0 <commands+0x828>
ffffffffc02030bc:	21100593          	li	a1,529
ffffffffc02030c0:	00003517          	auipc	a0,0x3
ffffffffc02030c4:	72050513          	addi	a0,a0,1824 # ffffffffc02067e0 <default_pmm_manager+0x150>
ffffffffc02030c8:	bcafd0ef          	jal	ra,ffffffffc0200492 <__panic>
        panic("DTB memory info not available");
ffffffffc02030cc:	00003617          	auipc	a2,0x3
ffffffffc02030d0:	78460613          	addi	a2,a2,1924 # ffffffffc0206850 <default_pmm_manager+0x1c0>
ffffffffc02030d4:	06500593          	li	a1,101
ffffffffc02030d8:	00003517          	auipc	a0,0x3
ffffffffc02030dc:	70850513          	addi	a0,a0,1800 # ffffffffc02067e0 <default_pmm_manager+0x150>
ffffffffc02030e0:	bb2fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc02030e4:	00004697          	auipc	a3,0x4
ffffffffc02030e8:	ae468693          	addi	a3,a3,-1308 # ffffffffc0206bc8 <default_pmm_manager+0x538>
ffffffffc02030ec:	00003617          	auipc	a2,0x3
ffffffffc02030f0:	1f460613          	addi	a2,a2,500 # ffffffffc02062e0 <commands+0x828>
ffffffffc02030f4:	25700593          	li	a1,599
ffffffffc02030f8:	00003517          	auipc	a0,0x3
ffffffffc02030fc:	6e850513          	addi	a0,a0,1768 # ffffffffc02067e0 <default_pmm_manager+0x150>
ffffffffc0203100:	b92fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0203104:	00004697          	auipc	a3,0x4
ffffffffc0203108:	97468693          	addi	a3,a3,-1676 # ffffffffc0206a78 <default_pmm_manager+0x3e8>
ffffffffc020310c:	00003617          	auipc	a2,0x3
ffffffffc0203110:	1d460613          	addi	a2,a2,468 # ffffffffc02062e0 <commands+0x828>
ffffffffc0203114:	21000593          	li	a1,528
ffffffffc0203118:	00003517          	auipc	a0,0x3
ffffffffc020311c:	6c850513          	addi	a0,a0,1736 # ffffffffc02067e0 <default_pmm_manager+0x150>
ffffffffc0203120:	b72fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc0203124:	00004697          	auipc	a3,0x4
ffffffffc0203128:	91468693          	addi	a3,a3,-1772 # ffffffffc0206a38 <default_pmm_manager+0x3a8>
ffffffffc020312c:	00003617          	auipc	a2,0x3
ffffffffc0203130:	1b460613          	addi	a2,a2,436 # ffffffffc02062e0 <commands+0x828>
ffffffffc0203134:	20f00593          	li	a1,527
ffffffffc0203138:	00003517          	auipc	a0,0x3
ffffffffc020313c:	6a850513          	addi	a0,a0,1704 # ffffffffc02067e0 <default_pmm_manager+0x150>
ffffffffc0203140:	b52fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0203144:	86d6                	mv	a3,s5
ffffffffc0203146:	00003617          	auipc	a2,0x3
ffffffffc020314a:	58260613          	addi	a2,a2,1410 # ffffffffc02066c8 <default_pmm_manager+0x38>
ffffffffc020314e:	20b00593          	li	a1,523
ffffffffc0203152:	00003517          	auipc	a0,0x3
ffffffffc0203156:	68e50513          	addi	a0,a0,1678 # ffffffffc02067e0 <default_pmm_manager+0x150>
ffffffffc020315a:	b38fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc020315e:	00003617          	auipc	a2,0x3
ffffffffc0203162:	56a60613          	addi	a2,a2,1386 # ffffffffc02066c8 <default_pmm_manager+0x38>
ffffffffc0203166:	20a00593          	li	a1,522
ffffffffc020316a:	00003517          	auipc	a0,0x3
ffffffffc020316e:	67650513          	addi	a0,a0,1654 # ffffffffc02067e0 <default_pmm_manager+0x150>
ffffffffc0203172:	b20fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_ref(p1) == 1);
ffffffffc0203176:	00004697          	auipc	a3,0x4
ffffffffc020317a:	87a68693          	addi	a3,a3,-1926 # ffffffffc02069f0 <default_pmm_manager+0x360>
ffffffffc020317e:	00003617          	auipc	a2,0x3
ffffffffc0203182:	16260613          	addi	a2,a2,354 # ffffffffc02062e0 <commands+0x828>
ffffffffc0203186:	20800593          	li	a1,520
ffffffffc020318a:	00003517          	auipc	a0,0x3
ffffffffc020318e:	65650513          	addi	a0,a0,1622 # ffffffffc02067e0 <default_pmm_manager+0x150>
ffffffffc0203192:	b00fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc0203196:	00004697          	auipc	a3,0x4
ffffffffc020319a:	84268693          	addi	a3,a3,-1982 # ffffffffc02069d8 <default_pmm_manager+0x348>
ffffffffc020319e:	00003617          	auipc	a2,0x3
ffffffffc02031a2:	14260613          	addi	a2,a2,322 # ffffffffc02062e0 <commands+0x828>
ffffffffc02031a6:	20700593          	li	a1,519
ffffffffc02031aa:	00003517          	auipc	a0,0x3
ffffffffc02031ae:	63650513          	addi	a0,a0,1590 # ffffffffc02067e0 <default_pmm_manager+0x150>
ffffffffc02031b2:	ae0fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(strlen((const char *)0x100) == 0);
ffffffffc02031b6:	00004697          	auipc	a3,0x4
ffffffffc02031ba:	bd268693          	addi	a3,a3,-1070 # ffffffffc0206d88 <default_pmm_manager+0x6f8>
ffffffffc02031be:	00003617          	auipc	a2,0x3
ffffffffc02031c2:	12260613          	addi	a2,a2,290 # ffffffffc02062e0 <commands+0x828>
ffffffffc02031c6:	24e00593          	li	a1,590
ffffffffc02031ca:	00003517          	auipc	a0,0x3
ffffffffc02031ce:	61650513          	addi	a0,a0,1558 # ffffffffc02067e0 <default_pmm_manager+0x150>
ffffffffc02031d2:	ac0fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc02031d6:	00004697          	auipc	a3,0x4
ffffffffc02031da:	b7a68693          	addi	a3,a3,-1158 # ffffffffc0206d50 <default_pmm_manager+0x6c0>
ffffffffc02031de:	00003617          	auipc	a2,0x3
ffffffffc02031e2:	10260613          	addi	a2,a2,258 # ffffffffc02062e0 <commands+0x828>
ffffffffc02031e6:	24b00593          	li	a1,587
ffffffffc02031ea:	00003517          	auipc	a0,0x3
ffffffffc02031ee:	5f650513          	addi	a0,a0,1526 # ffffffffc02067e0 <default_pmm_manager+0x150>
ffffffffc02031f2:	aa0fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_ref(p) == 2);
ffffffffc02031f6:	00004697          	auipc	a3,0x4
ffffffffc02031fa:	b2a68693          	addi	a3,a3,-1238 # ffffffffc0206d20 <default_pmm_manager+0x690>
ffffffffc02031fe:	00003617          	auipc	a2,0x3
ffffffffc0203202:	0e260613          	addi	a2,a2,226 # ffffffffc02062e0 <commands+0x828>
ffffffffc0203206:	24700593          	li	a1,583
ffffffffc020320a:	00003517          	auipc	a0,0x3
ffffffffc020320e:	5d650513          	addi	a0,a0,1494 # ffffffffc02067e0 <default_pmm_manager+0x150>
ffffffffc0203212:	a80fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc0203216:	00004697          	auipc	a3,0x4
ffffffffc020321a:	ac268693          	addi	a3,a3,-1342 # ffffffffc0206cd8 <default_pmm_manager+0x648>
ffffffffc020321e:	00003617          	auipc	a2,0x3
ffffffffc0203222:	0c260613          	addi	a2,a2,194 # ffffffffc02062e0 <commands+0x828>
ffffffffc0203226:	24600593          	li	a1,582
ffffffffc020322a:	00003517          	auipc	a0,0x3
ffffffffc020322e:	5b650513          	addi	a0,a0,1462 # ffffffffc02067e0 <default_pmm_manager+0x150>
ffffffffc0203232:	a60fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc0203236:	00003617          	auipc	a2,0x3
ffffffffc020323a:	53a60613          	addi	a2,a2,1338 # ffffffffc0206770 <default_pmm_manager+0xe0>
ffffffffc020323e:	0c900593          	li	a1,201
ffffffffc0203242:	00003517          	auipc	a0,0x3
ffffffffc0203246:	59e50513          	addi	a0,a0,1438 # ffffffffc02067e0 <default_pmm_manager+0x150>
ffffffffc020324a:	a48fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc020324e:	00003617          	auipc	a2,0x3
ffffffffc0203252:	52260613          	addi	a2,a2,1314 # ffffffffc0206770 <default_pmm_manager+0xe0>
ffffffffc0203256:	08100593          	li	a1,129
ffffffffc020325a:	00003517          	auipc	a0,0x3
ffffffffc020325e:	58650513          	addi	a0,a0,1414 # ffffffffc02067e0 <default_pmm_manager+0x150>
ffffffffc0203262:	a30fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc0203266:	00003697          	auipc	a3,0x3
ffffffffc020326a:	74268693          	addi	a3,a3,1858 # ffffffffc02069a8 <default_pmm_manager+0x318>
ffffffffc020326e:	00003617          	auipc	a2,0x3
ffffffffc0203272:	07260613          	addi	a2,a2,114 # ffffffffc02062e0 <commands+0x828>
ffffffffc0203276:	20600593          	li	a1,518
ffffffffc020327a:	00003517          	auipc	a0,0x3
ffffffffc020327e:	56650513          	addi	a0,a0,1382 # ffffffffc02067e0 <default_pmm_manager+0x150>
ffffffffc0203282:	a10fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc0203286:	00003697          	auipc	a3,0x3
ffffffffc020328a:	6f268693          	addi	a3,a3,1778 # ffffffffc0206978 <default_pmm_manager+0x2e8>
ffffffffc020328e:	00003617          	auipc	a2,0x3
ffffffffc0203292:	05260613          	addi	a2,a2,82 # ffffffffc02062e0 <commands+0x828>
ffffffffc0203296:	20300593          	li	a1,515
ffffffffc020329a:	00003517          	auipc	a0,0x3
ffffffffc020329e:	54650513          	addi	a0,a0,1350 # ffffffffc02067e0 <default_pmm_manager+0x150>
ffffffffc02032a2:	9f0fd0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc02032a6 <copy_range>:
{
ffffffffc02032a6:	7119                	addi	sp,sp,-128
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02032a8:	00d667b3          	or	a5,a2,a3
{
ffffffffc02032ac:	fc86                	sd	ra,120(sp)
ffffffffc02032ae:	f8a2                	sd	s0,112(sp)
ffffffffc02032b0:	f4a6                	sd	s1,104(sp)
ffffffffc02032b2:	f0ca                	sd	s2,96(sp)
ffffffffc02032b4:	ecce                	sd	s3,88(sp)
ffffffffc02032b6:	e8d2                	sd	s4,80(sp)
ffffffffc02032b8:	e4d6                	sd	s5,72(sp)
ffffffffc02032ba:	e0da                	sd	s6,64(sp)
ffffffffc02032bc:	fc5e                	sd	s7,56(sp)
ffffffffc02032be:	f862                	sd	s8,48(sp)
ffffffffc02032c0:	f466                	sd	s9,40(sp)
ffffffffc02032c2:	f06a                	sd	s10,32(sp)
ffffffffc02032c4:	ec6e                	sd	s11,24(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02032c6:	17d2                	slli	a5,a5,0x34
ffffffffc02032c8:	24079063          	bnez	a5,ffffffffc0203508 <copy_range+0x262>
    assert(USER_ACCESS(start, end));
ffffffffc02032cc:	002007b7          	lui	a5,0x200
ffffffffc02032d0:	8432                	mv	s0,a2
ffffffffc02032d2:	1cf66363          	bltu	a2,a5,ffffffffc0203498 <copy_range+0x1f2>
ffffffffc02032d6:	8936                	mv	s2,a3
ffffffffc02032d8:	1cd67063          	bgeu	a2,a3,ffffffffc0203498 <copy_range+0x1f2>
ffffffffc02032dc:	4785                	li	a5,1
ffffffffc02032de:	07fe                	slli	a5,a5,0x1f
ffffffffc02032e0:	1ad7ec63          	bltu	a5,a3,ffffffffc0203498 <copy_range+0x1f2>
ffffffffc02032e4:	5b7d                	li	s6,-1
ffffffffc02032e6:	8aaa                	mv	s5,a0
ffffffffc02032e8:	89ae                	mv	s3,a1
        start += PGSIZE;
ffffffffc02032ea:	6a05                	lui	s4,0x1
    if (PPN(pa) >= npage)
ffffffffc02032ec:	000c4c17          	auipc	s8,0xc4
ffffffffc02032f0:	9ccc0c13          	addi	s8,s8,-1588 # ffffffffc02c6cb8 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc02032f4:	000c4b97          	auipc	s7,0xc4
ffffffffc02032f8:	9ccb8b93          	addi	s7,s7,-1588 # ffffffffc02c6cc0 <pages>
    return KADDR(page2pa(page));
ffffffffc02032fc:	00cb5b13          	srli	s6,s6,0xc
        page = pmm_manager->alloc_pages(n);
ffffffffc0203300:	000c4c97          	auipc	s9,0xc4
ffffffffc0203304:	9c8c8c93          	addi	s9,s9,-1592 # ffffffffc02c6cc8 <pmm_manager>
        pte_t *ptep = get_pte(from, start, 0), *nptep;
ffffffffc0203308:	4601                	li	a2,0
ffffffffc020330a:	85a2                	mv	a1,s0
ffffffffc020330c:	854e                	mv	a0,s3
ffffffffc020330e:	b73fe0ef          	jal	ra,ffffffffc0201e80 <get_pte>
ffffffffc0203312:	84aa                	mv	s1,a0
        if (ptep == NULL) {
ffffffffc0203314:	10050163          	beqz	a0,ffffffffc0203416 <copy_range+0x170>
        if (*ptep & PTE_V) {
ffffffffc0203318:	611c                	ld	a5,0(a0)
ffffffffc020331a:	8b85                	andi	a5,a5,1
ffffffffc020331c:	e785                	bnez	a5,ffffffffc0203344 <copy_range+0x9e>
        start += PGSIZE;
ffffffffc020331e:	9452                	add	s0,s0,s4
    } while (start != 0 && start < end);
ffffffffc0203320:	ff2464e3          	bltu	s0,s2,ffffffffc0203308 <copy_range+0x62>
    return 0;
ffffffffc0203324:	4501                	li	a0,0
}
ffffffffc0203326:	70e6                	ld	ra,120(sp)
ffffffffc0203328:	7446                	ld	s0,112(sp)
ffffffffc020332a:	74a6                	ld	s1,104(sp)
ffffffffc020332c:	7906                	ld	s2,96(sp)
ffffffffc020332e:	69e6                	ld	s3,88(sp)
ffffffffc0203330:	6a46                	ld	s4,80(sp)
ffffffffc0203332:	6aa6                	ld	s5,72(sp)
ffffffffc0203334:	6b06                	ld	s6,64(sp)
ffffffffc0203336:	7be2                	ld	s7,56(sp)
ffffffffc0203338:	7c42                	ld	s8,48(sp)
ffffffffc020333a:	7ca2                	ld	s9,40(sp)
ffffffffc020333c:	7d02                	ld	s10,32(sp)
ffffffffc020333e:	6de2                	ld	s11,24(sp)
ffffffffc0203340:	6109                	addi	sp,sp,128
ffffffffc0203342:	8082                	ret
            if ((nptep = get_pte(to, start, 1)) == NULL) {
ffffffffc0203344:	4605                	li	a2,1
ffffffffc0203346:	85a2                	mv	a1,s0
ffffffffc0203348:	8556                	mv	a0,s5
ffffffffc020334a:	b37fe0ef          	jal	ra,ffffffffc0201e80 <get_pte>
ffffffffc020334e:	10050663          	beqz	a0,ffffffffc020345a <copy_range+0x1b4>
            uint32_t perm = (*ptep & PTE_USER);
ffffffffc0203352:	609c                	ld	a5,0(s1)
    if (!(pte & PTE_V))
ffffffffc0203354:	0017f713          	andi	a4,a5,1
ffffffffc0203358:	01f7f493          	andi	s1,a5,31
ffffffffc020335c:	18070a63          	beqz	a4,ffffffffc02034f0 <copy_range+0x24a>
    if (PPN(pa) >= npage)
ffffffffc0203360:	000c3683          	ld	a3,0(s8)
    return pa2page(PTE_ADDR(pte));
ffffffffc0203364:	078a                	slli	a5,a5,0x2
ffffffffc0203366:	00c7d713          	srli	a4,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc020336a:	16d77763          	bgeu	a4,a3,ffffffffc02034d8 <copy_range+0x232>
    return &pages[PPN(pa) - nbase];
ffffffffc020336e:	000bb783          	ld	a5,0(s7)
ffffffffc0203372:	fff806b7          	lui	a3,0xfff80
ffffffffc0203376:	9736                	add	a4,a4,a3
ffffffffc0203378:	071a                	slli	a4,a4,0x6
ffffffffc020337a:	00e78db3          	add	s11,a5,a4
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020337e:	10002773          	csrr	a4,sstatus
ffffffffc0203382:	8b09                	andi	a4,a4,2
ffffffffc0203384:	e745                	bnez	a4,ffffffffc020342c <copy_range+0x186>
        page = pmm_manager->alloc_pages(n);
ffffffffc0203386:	000cb703          	ld	a4,0(s9)
ffffffffc020338a:	4505                	li	a0,1
ffffffffc020338c:	6f18                	ld	a4,24(a4)
ffffffffc020338e:	9702                	jalr	a4
ffffffffc0203390:	8d2a                	mv	s10,a0
            assert(page != NULL);
ffffffffc0203392:	0e0d8363          	beqz	s11,ffffffffc0203478 <copy_range+0x1d2>
            assert(npage != NULL);
ffffffffc0203396:	120d0163          	beqz	s10,ffffffffc02034b8 <copy_range+0x212>
    return page - pages + nbase;
ffffffffc020339a:	000bb703          	ld	a4,0(s7)
ffffffffc020339e:	000805b7          	lui	a1,0x80
    return KADDR(page2pa(page));
ffffffffc02033a2:	000c3603          	ld	a2,0(s8)
    return page - pages + nbase;
ffffffffc02033a6:	40ed86b3          	sub	a3,s11,a4
ffffffffc02033aa:	8699                	srai	a3,a3,0x6
ffffffffc02033ac:	96ae                	add	a3,a3,a1
    return KADDR(page2pa(page));
ffffffffc02033ae:	0166f7b3          	and	a5,a3,s6
    return page2ppn(page) << PGSHIFT;
ffffffffc02033b2:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02033b4:	0ac7f663          	bgeu	a5,a2,ffffffffc0203460 <copy_range+0x1ba>
    return page - pages + nbase;
ffffffffc02033b8:	40ed07b3          	sub	a5,s10,a4
    return KADDR(page2pa(page));
ffffffffc02033bc:	000c4717          	auipc	a4,0xc4
ffffffffc02033c0:	91470713          	addi	a4,a4,-1772 # ffffffffc02c6cd0 <va_pa_offset>
ffffffffc02033c4:	6308                	ld	a0,0(a4)
    return page - pages + nbase;
ffffffffc02033c6:	8799                	srai	a5,a5,0x6
ffffffffc02033c8:	97ae                	add	a5,a5,a1
    return KADDR(page2pa(page));
ffffffffc02033ca:	0167f733          	and	a4,a5,s6
ffffffffc02033ce:	00a685b3          	add	a1,a3,a0
    return page2ppn(page) << PGSHIFT;
ffffffffc02033d2:	07b2                	slli	a5,a5,0xc
    return KADDR(page2pa(page));
ffffffffc02033d4:	08c77563          	bgeu	a4,a2,ffffffffc020345e <copy_range+0x1b8>
ffffffffc02033d8:	953e                	add	a0,a0,a5
ffffffffc02033da:	100027f3          	csrr	a5,sstatus
ffffffffc02033de:	8b89                	andi	a5,a5,2
ffffffffc02033e0:	e3ad                	bnez	a5,ffffffffc0203442 <copy_range+0x19c>
            memcpy(dst_kvaddr, src_kvaddr, PGSIZE);
ffffffffc02033e2:	6605                	lui	a2,0x1
ffffffffc02033e4:	452020ef          	jal	ra,ffffffffc0205836 <memcpy>
            int ret = page_insert(to, npage, start, perm);
ffffffffc02033e8:	86a6                	mv	a3,s1
ffffffffc02033ea:	8622                	mv	a2,s0
ffffffffc02033ec:	85ea                	mv	a1,s10
ffffffffc02033ee:	8556                	mv	a0,s5
ffffffffc02033f0:	980ff0ef          	jal	ra,ffffffffc0202570 <page_insert>
            assert(ret == 0);
ffffffffc02033f4:	d50d                	beqz	a0,ffffffffc020331e <copy_range+0x78>
ffffffffc02033f6:	00004697          	auipc	a3,0x4
ffffffffc02033fa:	9fa68693          	addi	a3,a3,-1542 # ffffffffc0206df0 <default_pmm_manager+0x760>
ffffffffc02033fe:	00003617          	auipc	a2,0x3
ffffffffc0203402:	ee260613          	addi	a2,a2,-286 # ffffffffc02062e0 <commands+0x828>
ffffffffc0203406:	19a00593          	li	a1,410
ffffffffc020340a:	00003517          	auipc	a0,0x3
ffffffffc020340e:	3d650513          	addi	a0,a0,982 # ffffffffc02067e0 <default_pmm_manager+0x150>
ffffffffc0203412:	880fd0ef          	jal	ra,ffffffffc0200492 <__panic>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc0203416:	00200637          	lui	a2,0x200
ffffffffc020341a:	9432                	add	s0,s0,a2
ffffffffc020341c:	ffe00637          	lui	a2,0xffe00
ffffffffc0203420:	8c71                	and	s0,s0,a2
    } while (start != 0 && start < end);
ffffffffc0203422:	f00401e3          	beqz	s0,ffffffffc0203324 <copy_range+0x7e>
ffffffffc0203426:	ef2461e3          	bltu	s0,s2,ffffffffc0203308 <copy_range+0x62>
ffffffffc020342a:	bded                	j	ffffffffc0203324 <copy_range+0x7e>
        intr_disable();
ffffffffc020342c:	d82fd0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0203430:	000cb703          	ld	a4,0(s9)
ffffffffc0203434:	4505                	li	a0,1
ffffffffc0203436:	6f18                	ld	a4,24(a4)
ffffffffc0203438:	9702                	jalr	a4
ffffffffc020343a:	8d2a                	mv	s10,a0
        intr_enable();
ffffffffc020343c:	d6cfd0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0203440:	bf89                	j	ffffffffc0203392 <copy_range+0xec>
ffffffffc0203442:	e42e                	sd	a1,8(sp)
ffffffffc0203444:	e02a                	sd	a0,0(sp)
        intr_disable();
ffffffffc0203446:	d68fd0ef          	jal	ra,ffffffffc02009ae <intr_disable>
            memcpy(dst_kvaddr, src_kvaddr, PGSIZE);
ffffffffc020344a:	65a2                	ld	a1,8(sp)
ffffffffc020344c:	6502                	ld	a0,0(sp)
ffffffffc020344e:	6605                	lui	a2,0x1
ffffffffc0203450:	3e6020ef          	jal	ra,ffffffffc0205836 <memcpy>
        intr_enable();
ffffffffc0203454:	d54fd0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0203458:	bf41                	j	ffffffffc02033e8 <copy_range+0x142>
                return -E_NO_MEM;
ffffffffc020345a:	5571                	li	a0,-4
ffffffffc020345c:	b5e9                	j	ffffffffc0203326 <copy_range+0x80>
ffffffffc020345e:	86be                	mv	a3,a5
ffffffffc0203460:	00003617          	auipc	a2,0x3
ffffffffc0203464:	26860613          	addi	a2,a2,616 # ffffffffc02066c8 <default_pmm_manager+0x38>
ffffffffc0203468:	07100593          	li	a1,113
ffffffffc020346c:	00003517          	auipc	a0,0x3
ffffffffc0203470:	28450513          	addi	a0,a0,644 # ffffffffc02066f0 <default_pmm_manager+0x60>
ffffffffc0203474:	81efd0ef          	jal	ra,ffffffffc0200492 <__panic>
            assert(page != NULL);
ffffffffc0203478:	00004697          	auipc	a3,0x4
ffffffffc020347c:	95868693          	addi	a3,a3,-1704 # ffffffffc0206dd0 <default_pmm_manager+0x740>
ffffffffc0203480:	00003617          	auipc	a2,0x3
ffffffffc0203484:	e6060613          	addi	a2,a2,-416 # ffffffffc02062e0 <commands+0x828>
ffffffffc0203488:	18d00593          	li	a1,397
ffffffffc020348c:	00003517          	auipc	a0,0x3
ffffffffc0203490:	35450513          	addi	a0,a0,852 # ffffffffc02067e0 <default_pmm_manager+0x150>
ffffffffc0203494:	ffffc0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(USER_ACCESS(start, end));
ffffffffc0203498:	00003697          	auipc	a3,0x3
ffffffffc020349c:	38868693          	addi	a3,a3,904 # ffffffffc0206820 <default_pmm_manager+0x190>
ffffffffc02034a0:	00003617          	auipc	a2,0x3
ffffffffc02034a4:	e4060613          	addi	a2,a2,-448 # ffffffffc02062e0 <commands+0x828>
ffffffffc02034a8:	17e00593          	li	a1,382
ffffffffc02034ac:	00003517          	auipc	a0,0x3
ffffffffc02034b0:	33450513          	addi	a0,a0,820 # ffffffffc02067e0 <default_pmm_manager+0x150>
ffffffffc02034b4:	fdffc0ef          	jal	ra,ffffffffc0200492 <__panic>
            assert(npage != NULL);
ffffffffc02034b8:	00004697          	auipc	a3,0x4
ffffffffc02034bc:	92868693          	addi	a3,a3,-1752 # ffffffffc0206de0 <default_pmm_manager+0x750>
ffffffffc02034c0:	00003617          	auipc	a2,0x3
ffffffffc02034c4:	e2060613          	addi	a2,a2,-480 # ffffffffc02062e0 <commands+0x828>
ffffffffc02034c8:	18e00593          	li	a1,398
ffffffffc02034cc:	00003517          	auipc	a0,0x3
ffffffffc02034d0:	31450513          	addi	a0,a0,788 # ffffffffc02067e0 <default_pmm_manager+0x150>
ffffffffc02034d4:	fbffc0ef          	jal	ra,ffffffffc0200492 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc02034d8:	00003617          	auipc	a2,0x3
ffffffffc02034dc:	2c060613          	addi	a2,a2,704 # ffffffffc0206798 <default_pmm_manager+0x108>
ffffffffc02034e0:	06900593          	li	a1,105
ffffffffc02034e4:	00003517          	auipc	a0,0x3
ffffffffc02034e8:	20c50513          	addi	a0,a0,524 # ffffffffc02066f0 <default_pmm_manager+0x60>
ffffffffc02034ec:	fa7fc0ef          	jal	ra,ffffffffc0200492 <__panic>
        panic("pte2page called with invalid pte");
ffffffffc02034f0:	00003617          	auipc	a2,0x3
ffffffffc02034f4:	2c860613          	addi	a2,a2,712 # ffffffffc02067b8 <default_pmm_manager+0x128>
ffffffffc02034f8:	07f00593          	li	a1,127
ffffffffc02034fc:	00003517          	auipc	a0,0x3
ffffffffc0203500:	1f450513          	addi	a0,a0,500 # ffffffffc02066f0 <default_pmm_manager+0x60>
ffffffffc0203504:	f8ffc0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0203508:	00003697          	auipc	a3,0x3
ffffffffc020350c:	2e868693          	addi	a3,a3,744 # ffffffffc02067f0 <default_pmm_manager+0x160>
ffffffffc0203510:	00003617          	auipc	a2,0x3
ffffffffc0203514:	dd060613          	addi	a2,a2,-560 # ffffffffc02062e0 <commands+0x828>
ffffffffc0203518:	17d00593          	li	a1,381
ffffffffc020351c:	00003517          	auipc	a0,0x3
ffffffffc0203520:	2c450513          	addi	a0,a0,708 # ffffffffc02067e0 <default_pmm_manager+0x150>
ffffffffc0203524:	f6ffc0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0203528 <pgdir_alloc_page>:
{
ffffffffc0203528:	7179                	addi	sp,sp,-48
ffffffffc020352a:	ec26                	sd	s1,24(sp)
ffffffffc020352c:	e84a                	sd	s2,16(sp)
ffffffffc020352e:	e052                	sd	s4,0(sp)
ffffffffc0203530:	f406                	sd	ra,40(sp)
ffffffffc0203532:	f022                	sd	s0,32(sp)
ffffffffc0203534:	e44e                	sd	s3,8(sp)
ffffffffc0203536:	8a2a                	mv	s4,a0
ffffffffc0203538:	84ae                	mv	s1,a1
ffffffffc020353a:	8932                	mv	s2,a2
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020353c:	100027f3          	csrr	a5,sstatus
ffffffffc0203540:	8b89                	andi	a5,a5,2
        page = pmm_manager->alloc_pages(n);
ffffffffc0203542:	000c3997          	auipc	s3,0xc3
ffffffffc0203546:	78698993          	addi	s3,s3,1926 # ffffffffc02c6cc8 <pmm_manager>
ffffffffc020354a:	ef8d                	bnez	a5,ffffffffc0203584 <pgdir_alloc_page+0x5c>
ffffffffc020354c:	0009b783          	ld	a5,0(s3)
ffffffffc0203550:	4505                	li	a0,1
ffffffffc0203552:	6f9c                	ld	a5,24(a5)
ffffffffc0203554:	9782                	jalr	a5
ffffffffc0203556:	842a                	mv	s0,a0
    if (page != NULL)
ffffffffc0203558:	cc09                	beqz	s0,ffffffffc0203572 <pgdir_alloc_page+0x4a>
        if (page_insert(pgdir, page, la, perm) != 0)
ffffffffc020355a:	86ca                	mv	a3,s2
ffffffffc020355c:	8626                	mv	a2,s1
ffffffffc020355e:	85a2                	mv	a1,s0
ffffffffc0203560:	8552                	mv	a0,s4
ffffffffc0203562:	80eff0ef          	jal	ra,ffffffffc0202570 <page_insert>
ffffffffc0203566:	e915                	bnez	a0,ffffffffc020359a <pgdir_alloc_page+0x72>
        assert(page_ref(page) == 1);
ffffffffc0203568:	4018                	lw	a4,0(s0)
        page->pra_vaddr = la;
ffffffffc020356a:	fc04                	sd	s1,56(s0)
        assert(page_ref(page) == 1);
ffffffffc020356c:	4785                	li	a5,1
ffffffffc020356e:	04f71e63          	bne	a4,a5,ffffffffc02035ca <pgdir_alloc_page+0xa2>
}
ffffffffc0203572:	70a2                	ld	ra,40(sp)
ffffffffc0203574:	8522                	mv	a0,s0
ffffffffc0203576:	7402                	ld	s0,32(sp)
ffffffffc0203578:	64e2                	ld	s1,24(sp)
ffffffffc020357a:	6942                	ld	s2,16(sp)
ffffffffc020357c:	69a2                	ld	s3,8(sp)
ffffffffc020357e:	6a02                	ld	s4,0(sp)
ffffffffc0203580:	6145                	addi	sp,sp,48
ffffffffc0203582:	8082                	ret
        intr_disable();
ffffffffc0203584:	c2afd0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0203588:	0009b783          	ld	a5,0(s3)
ffffffffc020358c:	4505                	li	a0,1
ffffffffc020358e:	6f9c                	ld	a5,24(a5)
ffffffffc0203590:	9782                	jalr	a5
ffffffffc0203592:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0203594:	c14fd0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc0203598:	b7c1                	j	ffffffffc0203558 <pgdir_alloc_page+0x30>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020359a:	100027f3          	csrr	a5,sstatus
ffffffffc020359e:	8b89                	andi	a5,a5,2
ffffffffc02035a0:	eb89                	bnez	a5,ffffffffc02035b2 <pgdir_alloc_page+0x8a>
        pmm_manager->free_pages(base, n);
ffffffffc02035a2:	0009b783          	ld	a5,0(s3)
ffffffffc02035a6:	8522                	mv	a0,s0
ffffffffc02035a8:	4585                	li	a1,1
ffffffffc02035aa:	739c                	ld	a5,32(a5)
            return NULL;
ffffffffc02035ac:	4401                	li	s0,0
        pmm_manager->free_pages(base, n);
ffffffffc02035ae:	9782                	jalr	a5
    if (flag)
ffffffffc02035b0:	b7c9                	j	ffffffffc0203572 <pgdir_alloc_page+0x4a>
        intr_disable();
ffffffffc02035b2:	bfcfd0ef          	jal	ra,ffffffffc02009ae <intr_disable>
ffffffffc02035b6:	0009b783          	ld	a5,0(s3)
ffffffffc02035ba:	8522                	mv	a0,s0
ffffffffc02035bc:	4585                	li	a1,1
ffffffffc02035be:	739c                	ld	a5,32(a5)
            return NULL;
ffffffffc02035c0:	4401                	li	s0,0
        pmm_manager->free_pages(base, n);
ffffffffc02035c2:	9782                	jalr	a5
        intr_enable();
ffffffffc02035c4:	be4fd0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc02035c8:	b76d                	j	ffffffffc0203572 <pgdir_alloc_page+0x4a>
        assert(page_ref(page) == 1);
ffffffffc02035ca:	00004697          	auipc	a3,0x4
ffffffffc02035ce:	83668693          	addi	a3,a3,-1994 # ffffffffc0206e00 <default_pmm_manager+0x770>
ffffffffc02035d2:	00003617          	auipc	a2,0x3
ffffffffc02035d6:	d0e60613          	addi	a2,a2,-754 # ffffffffc02062e0 <commands+0x828>
ffffffffc02035da:	1e400593          	li	a1,484
ffffffffc02035de:	00003517          	auipc	a0,0x3
ffffffffc02035e2:	20250513          	addi	a0,a0,514 # ffffffffc02067e0 <default_pmm_manager+0x150>
ffffffffc02035e6:	eadfc0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc02035ea <check_vma_overlap.part.0>:
    return vma;
}

// check_vma_overlap - check if vma1 overlaps vma2 ?
static inline void
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc02035ea:	1141                	addi	sp,sp,-16
{
    assert(prev->vm_start < prev->vm_end);
    assert(prev->vm_end <= next->vm_start);
    assert(next->vm_start < next->vm_end);
ffffffffc02035ec:	00004697          	auipc	a3,0x4
ffffffffc02035f0:	82c68693          	addi	a3,a3,-2004 # ffffffffc0206e18 <default_pmm_manager+0x788>
ffffffffc02035f4:	00003617          	auipc	a2,0x3
ffffffffc02035f8:	cec60613          	addi	a2,a2,-788 # ffffffffc02062e0 <commands+0x828>
ffffffffc02035fc:	07400593          	li	a1,116
ffffffffc0203600:	00004517          	auipc	a0,0x4
ffffffffc0203604:	83850513          	addi	a0,a0,-1992 # ffffffffc0206e38 <default_pmm_manager+0x7a8>
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc0203608:	e406                	sd	ra,8(sp)
    assert(next->vm_start < next->vm_end);
ffffffffc020360a:	e89fc0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc020360e <mm_create>:
{
ffffffffc020360e:	1141                	addi	sp,sp,-16
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0203610:	04000513          	li	a0,64
{
ffffffffc0203614:	e406                	sd	ra,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0203616:	dd4fe0ef          	jal	ra,ffffffffc0201bea <kmalloc>
    if (mm != NULL)
ffffffffc020361a:	cd19                	beqz	a0,ffffffffc0203638 <mm_create+0x2a>
    elm->prev = elm->next = elm;
ffffffffc020361c:	e508                	sd	a0,8(a0)
ffffffffc020361e:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc0203620:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc0203624:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc0203628:	02052023          	sw	zero,32(a0)
        mm->sm_priv = NULL;
ffffffffc020362c:	02053423          	sd	zero,40(a0)
}

static inline void
set_mm_count(struct mm_struct *mm, int val)
{
    mm->mm_count = val;
ffffffffc0203630:	02052823          	sw	zero,48(a0)
typedef volatile bool lock_t;

static inline void
lock_init(lock_t *lock)
{
    *lock = 0;
ffffffffc0203634:	02053c23          	sd	zero,56(a0)
}
ffffffffc0203638:	60a2                	ld	ra,8(sp)
ffffffffc020363a:	0141                	addi	sp,sp,16
ffffffffc020363c:	8082                	ret

ffffffffc020363e <find_vma>:
{
ffffffffc020363e:	86aa                	mv	a3,a0
    if (mm != NULL)
ffffffffc0203640:	c505                	beqz	a0,ffffffffc0203668 <find_vma+0x2a>
        vma = mm->mmap_cache;
ffffffffc0203642:	6908                	ld	a0,16(a0)
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc0203644:	c501                	beqz	a0,ffffffffc020364c <find_vma+0xe>
ffffffffc0203646:	651c                	ld	a5,8(a0)
ffffffffc0203648:	02f5f263          	bgeu	a1,a5,ffffffffc020366c <find_vma+0x2e>
    return listelm->next;
ffffffffc020364c:	669c                	ld	a5,8(a3)
            while ((le = list_next(le)) != list)
ffffffffc020364e:	00f68d63          	beq	a3,a5,ffffffffc0203668 <find_vma+0x2a>
                if (vma->vm_start <= addr && addr < vma->vm_end)
ffffffffc0203652:	fe87b703          	ld	a4,-24(a5) # 1fffe8 <_binary_obj___user_matrix_out_size+0x1f38c8>
ffffffffc0203656:	00e5e663          	bltu	a1,a4,ffffffffc0203662 <find_vma+0x24>
ffffffffc020365a:	ff07b703          	ld	a4,-16(a5)
ffffffffc020365e:	00e5ec63          	bltu	a1,a4,ffffffffc0203676 <find_vma+0x38>
ffffffffc0203662:	679c                	ld	a5,8(a5)
            while ((le = list_next(le)) != list)
ffffffffc0203664:	fef697e3          	bne	a3,a5,ffffffffc0203652 <find_vma+0x14>
    struct vma_struct *vma = NULL;
ffffffffc0203668:	4501                	li	a0,0
}
ffffffffc020366a:	8082                	ret
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc020366c:	691c                	ld	a5,16(a0)
ffffffffc020366e:	fcf5ffe3          	bgeu	a1,a5,ffffffffc020364c <find_vma+0xe>
            mm->mmap_cache = vma;
ffffffffc0203672:	ea88                	sd	a0,16(a3)
ffffffffc0203674:	8082                	ret
                vma = le2vma(le, list_link);
ffffffffc0203676:	fe078513          	addi	a0,a5,-32
            mm->mmap_cache = vma;
ffffffffc020367a:	ea88                	sd	a0,16(a3)
ffffffffc020367c:	8082                	ret

ffffffffc020367e <insert_vma_struct>:
}

// insert_vma_struct -insert vma in mm's list link
void insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma)
{
    assert(vma->vm_start < vma->vm_end);
ffffffffc020367e:	6590                	ld	a2,8(a1)
ffffffffc0203680:	0105b803          	ld	a6,16(a1) # 80010 <_binary_obj___user_matrix_out_size+0x738f0>
{
ffffffffc0203684:	1141                	addi	sp,sp,-16
ffffffffc0203686:	e406                	sd	ra,8(sp)
ffffffffc0203688:	87aa                	mv	a5,a0
    assert(vma->vm_start < vma->vm_end);
ffffffffc020368a:	01066763          	bltu	a2,a6,ffffffffc0203698 <insert_vma_struct+0x1a>
ffffffffc020368e:	a085                	j	ffffffffc02036ee <insert_vma_struct+0x70>

    list_entry_t *le = list;
    while ((le = list_next(le)) != list)
    {
        struct vma_struct *mmap_prev = le2vma(le, list_link);
        if (mmap_prev->vm_start > vma->vm_start)
ffffffffc0203690:	fe87b703          	ld	a4,-24(a5)
ffffffffc0203694:	04e66863          	bltu	a2,a4,ffffffffc02036e4 <insert_vma_struct+0x66>
ffffffffc0203698:	86be                	mv	a3,a5
ffffffffc020369a:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != list)
ffffffffc020369c:	fef51ae3          	bne	a0,a5,ffffffffc0203690 <insert_vma_struct+0x12>
    }

    le_next = list_next(le_prev);

    /* check overlap */
    if (le_prev != list)
ffffffffc02036a0:	02a68463          	beq	a3,a0,ffffffffc02036c8 <insert_vma_struct+0x4a>
    {
        check_vma_overlap(le2vma(le_prev, list_link), vma);
ffffffffc02036a4:	ff06b703          	ld	a4,-16(a3)
    assert(prev->vm_start < prev->vm_end);
ffffffffc02036a8:	fe86b883          	ld	a7,-24(a3)
ffffffffc02036ac:	08e8f163          	bgeu	a7,a4,ffffffffc020372e <insert_vma_struct+0xb0>
    assert(prev->vm_end <= next->vm_start);
ffffffffc02036b0:	04e66f63          	bltu	a2,a4,ffffffffc020370e <insert_vma_struct+0x90>
    }
    if (le_next != list)
ffffffffc02036b4:	00f50a63          	beq	a0,a5,ffffffffc02036c8 <insert_vma_struct+0x4a>
        if (mmap_prev->vm_start > vma->vm_start)
ffffffffc02036b8:	fe87b703          	ld	a4,-24(a5)
    assert(prev->vm_end <= next->vm_start);
ffffffffc02036bc:	05076963          	bltu	a4,a6,ffffffffc020370e <insert_vma_struct+0x90>
    assert(next->vm_start < next->vm_end);
ffffffffc02036c0:	ff07b603          	ld	a2,-16(a5)
ffffffffc02036c4:	02c77363          	bgeu	a4,a2,ffffffffc02036ea <insert_vma_struct+0x6c>
    }

    vma->vm_mm = mm;
    list_add_after(le_prev, &(vma->list_link));

    mm->map_count++;
ffffffffc02036c8:	5118                	lw	a4,32(a0)
    vma->vm_mm = mm;
ffffffffc02036ca:	e188                	sd	a0,0(a1)
    list_add_after(le_prev, &(vma->list_link));
ffffffffc02036cc:	02058613          	addi	a2,a1,32
    prev->next = next->prev = elm;
ffffffffc02036d0:	e390                	sd	a2,0(a5)
ffffffffc02036d2:	e690                	sd	a2,8(a3)
}
ffffffffc02036d4:	60a2                	ld	ra,8(sp)
    elm->next = next;
ffffffffc02036d6:	f59c                	sd	a5,40(a1)
    elm->prev = prev;
ffffffffc02036d8:	f194                	sd	a3,32(a1)
    mm->map_count++;
ffffffffc02036da:	0017079b          	addiw	a5,a4,1
ffffffffc02036de:	d11c                	sw	a5,32(a0)
}
ffffffffc02036e0:	0141                	addi	sp,sp,16
ffffffffc02036e2:	8082                	ret
    if (le_prev != list)
ffffffffc02036e4:	fca690e3          	bne	a3,a0,ffffffffc02036a4 <insert_vma_struct+0x26>
ffffffffc02036e8:	bfd1                	j	ffffffffc02036bc <insert_vma_struct+0x3e>
ffffffffc02036ea:	f01ff0ef          	jal	ra,ffffffffc02035ea <check_vma_overlap.part.0>
    assert(vma->vm_start < vma->vm_end);
ffffffffc02036ee:	00003697          	auipc	a3,0x3
ffffffffc02036f2:	75a68693          	addi	a3,a3,1882 # ffffffffc0206e48 <default_pmm_manager+0x7b8>
ffffffffc02036f6:	00003617          	auipc	a2,0x3
ffffffffc02036fa:	bea60613          	addi	a2,a2,-1046 # ffffffffc02062e0 <commands+0x828>
ffffffffc02036fe:	07a00593          	li	a1,122
ffffffffc0203702:	00003517          	auipc	a0,0x3
ffffffffc0203706:	73650513          	addi	a0,a0,1846 # ffffffffc0206e38 <default_pmm_manager+0x7a8>
ffffffffc020370a:	d89fc0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(prev->vm_end <= next->vm_start);
ffffffffc020370e:	00003697          	auipc	a3,0x3
ffffffffc0203712:	77a68693          	addi	a3,a3,1914 # ffffffffc0206e88 <default_pmm_manager+0x7f8>
ffffffffc0203716:	00003617          	auipc	a2,0x3
ffffffffc020371a:	bca60613          	addi	a2,a2,-1078 # ffffffffc02062e0 <commands+0x828>
ffffffffc020371e:	07300593          	li	a1,115
ffffffffc0203722:	00003517          	auipc	a0,0x3
ffffffffc0203726:	71650513          	addi	a0,a0,1814 # ffffffffc0206e38 <default_pmm_manager+0x7a8>
ffffffffc020372a:	d69fc0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(prev->vm_start < prev->vm_end);
ffffffffc020372e:	00003697          	auipc	a3,0x3
ffffffffc0203732:	73a68693          	addi	a3,a3,1850 # ffffffffc0206e68 <default_pmm_manager+0x7d8>
ffffffffc0203736:	00003617          	auipc	a2,0x3
ffffffffc020373a:	baa60613          	addi	a2,a2,-1110 # ffffffffc02062e0 <commands+0x828>
ffffffffc020373e:	07200593          	li	a1,114
ffffffffc0203742:	00003517          	auipc	a0,0x3
ffffffffc0203746:	6f650513          	addi	a0,a0,1782 # ffffffffc0206e38 <default_pmm_manager+0x7a8>
ffffffffc020374a:	d49fc0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc020374e <mm_destroy>:

// mm_destroy - free mm and mm internal fields
void mm_destroy(struct mm_struct *mm)
{
    assert(mm_count(mm) == 0);
ffffffffc020374e:	591c                	lw	a5,48(a0)
{
ffffffffc0203750:	1141                	addi	sp,sp,-16
ffffffffc0203752:	e406                	sd	ra,8(sp)
ffffffffc0203754:	e022                	sd	s0,0(sp)
    assert(mm_count(mm) == 0);
ffffffffc0203756:	e78d                	bnez	a5,ffffffffc0203780 <mm_destroy+0x32>
ffffffffc0203758:	842a                	mv	s0,a0
    return listelm->next;
ffffffffc020375a:	6508                	ld	a0,8(a0)

    list_entry_t *list = &(mm->mmap_list), *le;
    while ((le = list_next(list)) != list)
ffffffffc020375c:	00a40c63          	beq	s0,a0,ffffffffc0203774 <mm_destroy+0x26>
    __list_del(listelm->prev, listelm->next);
ffffffffc0203760:	6118                	ld	a4,0(a0)
ffffffffc0203762:	651c                	ld	a5,8(a0)
    {
        list_del(le);
        kfree(le2vma(le, list_link)); // kfree vma
ffffffffc0203764:	1501                	addi	a0,a0,-32
    prev->next = next;
ffffffffc0203766:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0203768:	e398                	sd	a4,0(a5)
ffffffffc020376a:	d30fe0ef          	jal	ra,ffffffffc0201c9a <kfree>
    return listelm->next;
ffffffffc020376e:	6408                	ld	a0,8(s0)
    while ((le = list_next(list)) != list)
ffffffffc0203770:	fea418e3          	bne	s0,a0,ffffffffc0203760 <mm_destroy+0x12>
    }
    kfree(mm); // kfree mm
ffffffffc0203774:	8522                	mv	a0,s0
    mm = NULL;
}
ffffffffc0203776:	6402                	ld	s0,0(sp)
ffffffffc0203778:	60a2                	ld	ra,8(sp)
ffffffffc020377a:	0141                	addi	sp,sp,16
    kfree(mm); // kfree mm
ffffffffc020377c:	d1efe06f          	j	ffffffffc0201c9a <kfree>
    assert(mm_count(mm) == 0);
ffffffffc0203780:	00003697          	auipc	a3,0x3
ffffffffc0203784:	72868693          	addi	a3,a3,1832 # ffffffffc0206ea8 <default_pmm_manager+0x818>
ffffffffc0203788:	00003617          	auipc	a2,0x3
ffffffffc020378c:	b5860613          	addi	a2,a2,-1192 # ffffffffc02062e0 <commands+0x828>
ffffffffc0203790:	09e00593          	li	a1,158
ffffffffc0203794:	00003517          	auipc	a0,0x3
ffffffffc0203798:	6a450513          	addi	a0,a0,1700 # ffffffffc0206e38 <default_pmm_manager+0x7a8>
ffffffffc020379c:	cf7fc0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc02037a0 <mm_map>:

int mm_map(struct mm_struct *mm, uintptr_t addr, size_t len, uint32_t vm_flags,
           struct vma_struct **vma_store)
{
ffffffffc02037a0:	7139                	addi	sp,sp,-64
ffffffffc02037a2:	f822                	sd	s0,48(sp)
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc02037a4:	6405                	lui	s0,0x1
ffffffffc02037a6:	147d                	addi	s0,s0,-1
ffffffffc02037a8:	77fd                	lui	a5,0xfffff
ffffffffc02037aa:	9622                	add	a2,a2,s0
ffffffffc02037ac:	962e                	add	a2,a2,a1
{
ffffffffc02037ae:	f426                	sd	s1,40(sp)
ffffffffc02037b0:	fc06                	sd	ra,56(sp)
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc02037b2:	00f5f4b3          	and	s1,a1,a5
{
ffffffffc02037b6:	f04a                	sd	s2,32(sp)
ffffffffc02037b8:	ec4e                	sd	s3,24(sp)
ffffffffc02037ba:	e852                	sd	s4,16(sp)
ffffffffc02037bc:	e456                	sd	s5,8(sp)
    if (!USER_ACCESS(start, end))
ffffffffc02037be:	002005b7          	lui	a1,0x200
ffffffffc02037c2:	00f67433          	and	s0,a2,a5
ffffffffc02037c6:	06b4e363          	bltu	s1,a1,ffffffffc020382c <mm_map+0x8c>
ffffffffc02037ca:	0684f163          	bgeu	s1,s0,ffffffffc020382c <mm_map+0x8c>
ffffffffc02037ce:	4785                	li	a5,1
ffffffffc02037d0:	07fe                	slli	a5,a5,0x1f
ffffffffc02037d2:	0487ed63          	bltu	a5,s0,ffffffffc020382c <mm_map+0x8c>
ffffffffc02037d6:	89aa                	mv	s3,a0
    {
        return -E_INVAL;
    }

    assert(mm != NULL);
ffffffffc02037d8:	cd21                	beqz	a0,ffffffffc0203830 <mm_map+0x90>

    int ret = -E_INVAL;

    struct vma_struct *vma;
    if ((vma = find_vma(mm, start)) != NULL && end > vma->vm_start)
ffffffffc02037da:	85a6                	mv	a1,s1
ffffffffc02037dc:	8ab6                	mv	s5,a3
ffffffffc02037de:	8a3a                	mv	s4,a4
ffffffffc02037e0:	e5fff0ef          	jal	ra,ffffffffc020363e <find_vma>
ffffffffc02037e4:	c501                	beqz	a0,ffffffffc02037ec <mm_map+0x4c>
ffffffffc02037e6:	651c                	ld	a5,8(a0)
ffffffffc02037e8:	0487e263          	bltu	a5,s0,ffffffffc020382c <mm_map+0x8c>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc02037ec:	03000513          	li	a0,48
ffffffffc02037f0:	bfafe0ef          	jal	ra,ffffffffc0201bea <kmalloc>
ffffffffc02037f4:	892a                	mv	s2,a0
    {
        goto out;
    }
    ret = -E_NO_MEM;
ffffffffc02037f6:	5571                	li	a0,-4
    if (vma != NULL)
ffffffffc02037f8:	02090163          	beqz	s2,ffffffffc020381a <mm_map+0x7a>

    if ((vma = vma_create(start, end, vm_flags)) == NULL)
    {
        goto out;
    }
    insert_vma_struct(mm, vma);
ffffffffc02037fc:	854e                	mv	a0,s3
        vma->vm_start = vm_start;
ffffffffc02037fe:	00993423          	sd	s1,8(s2)
        vma->vm_end = vm_end;
ffffffffc0203802:	00893823          	sd	s0,16(s2)
        vma->vm_flags = vm_flags;
ffffffffc0203806:	01592c23          	sw	s5,24(s2)
    insert_vma_struct(mm, vma);
ffffffffc020380a:	85ca                	mv	a1,s2
ffffffffc020380c:	e73ff0ef          	jal	ra,ffffffffc020367e <insert_vma_struct>
    if (vma_store != NULL)
    {
        *vma_store = vma;
    }
    ret = 0;
ffffffffc0203810:	4501                	li	a0,0
    if (vma_store != NULL)
ffffffffc0203812:	000a0463          	beqz	s4,ffffffffc020381a <mm_map+0x7a>
        *vma_store = vma;
ffffffffc0203816:	012a3023          	sd	s2,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8f48>

out:
    return ret;
}
ffffffffc020381a:	70e2                	ld	ra,56(sp)
ffffffffc020381c:	7442                	ld	s0,48(sp)
ffffffffc020381e:	74a2                	ld	s1,40(sp)
ffffffffc0203820:	7902                	ld	s2,32(sp)
ffffffffc0203822:	69e2                	ld	s3,24(sp)
ffffffffc0203824:	6a42                	ld	s4,16(sp)
ffffffffc0203826:	6aa2                	ld	s5,8(sp)
ffffffffc0203828:	6121                	addi	sp,sp,64
ffffffffc020382a:	8082                	ret
        return -E_INVAL;
ffffffffc020382c:	5575                	li	a0,-3
ffffffffc020382e:	b7f5                	j	ffffffffc020381a <mm_map+0x7a>
    assert(mm != NULL);
ffffffffc0203830:	00003697          	auipc	a3,0x3
ffffffffc0203834:	69068693          	addi	a3,a3,1680 # ffffffffc0206ec0 <default_pmm_manager+0x830>
ffffffffc0203838:	00003617          	auipc	a2,0x3
ffffffffc020383c:	aa860613          	addi	a2,a2,-1368 # ffffffffc02062e0 <commands+0x828>
ffffffffc0203840:	0b300593          	li	a1,179
ffffffffc0203844:	00003517          	auipc	a0,0x3
ffffffffc0203848:	5f450513          	addi	a0,a0,1524 # ffffffffc0206e38 <default_pmm_manager+0x7a8>
ffffffffc020384c:	c47fc0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0203850 <dup_mmap>:

int dup_mmap(struct mm_struct *to, struct mm_struct *from)
{
ffffffffc0203850:	7139                	addi	sp,sp,-64
ffffffffc0203852:	fc06                	sd	ra,56(sp)
ffffffffc0203854:	f822                	sd	s0,48(sp)
ffffffffc0203856:	f426                	sd	s1,40(sp)
ffffffffc0203858:	f04a                	sd	s2,32(sp)
ffffffffc020385a:	ec4e                	sd	s3,24(sp)
ffffffffc020385c:	e852                	sd	s4,16(sp)
ffffffffc020385e:	e456                	sd	s5,8(sp)
    assert(to != NULL && from != NULL);
ffffffffc0203860:	c52d                	beqz	a0,ffffffffc02038ca <dup_mmap+0x7a>
ffffffffc0203862:	892a                	mv	s2,a0
ffffffffc0203864:	84ae                	mv	s1,a1
    list_entry_t *list = &(from->mmap_list), *le = list;
ffffffffc0203866:	842e                	mv	s0,a1
    assert(to != NULL && from != NULL);
ffffffffc0203868:	e595                	bnez	a1,ffffffffc0203894 <dup_mmap+0x44>
ffffffffc020386a:	a085                	j	ffffffffc02038ca <dup_mmap+0x7a>
        if (nvma == NULL)
        {
            return -E_NO_MEM;
        }

        insert_vma_struct(to, nvma);
ffffffffc020386c:	854a                	mv	a0,s2
        vma->vm_start = vm_start;
ffffffffc020386e:	0155b423          	sd	s5,8(a1) # 200008 <_binary_obj___user_matrix_out_size+0x1f38e8>
        vma->vm_end = vm_end;
ffffffffc0203872:	0145b823          	sd	s4,16(a1)
        vma->vm_flags = vm_flags;
ffffffffc0203876:	0135ac23          	sw	s3,24(a1)
        insert_vma_struct(to, nvma);
ffffffffc020387a:	e05ff0ef          	jal	ra,ffffffffc020367e <insert_vma_struct>

        bool share = 0;
        if (copy_range(to->pgdir, from->pgdir, vma->vm_start, vma->vm_end, share) != 0)
ffffffffc020387e:	ff043683          	ld	a3,-16(s0) # ff0 <_binary_obj___user_faultread_out_size-0x8f58>
ffffffffc0203882:	fe843603          	ld	a2,-24(s0)
ffffffffc0203886:	6c8c                	ld	a1,24(s1)
ffffffffc0203888:	01893503          	ld	a0,24(s2)
ffffffffc020388c:	4701                	li	a4,0
ffffffffc020388e:	a19ff0ef          	jal	ra,ffffffffc02032a6 <copy_range>
ffffffffc0203892:	e105                	bnez	a0,ffffffffc02038b2 <dup_mmap+0x62>
    return listelm->prev;
ffffffffc0203894:	6000                	ld	s0,0(s0)
    while ((le = list_prev(le)) != list)
ffffffffc0203896:	02848863          	beq	s1,s0,ffffffffc02038c6 <dup_mmap+0x76>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc020389a:	03000513          	li	a0,48
        nvma = vma_create(vma->vm_start, vma->vm_end, vma->vm_flags);
ffffffffc020389e:	fe843a83          	ld	s5,-24(s0)
ffffffffc02038a2:	ff043a03          	ld	s4,-16(s0)
ffffffffc02038a6:	ff842983          	lw	s3,-8(s0)
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc02038aa:	b40fe0ef          	jal	ra,ffffffffc0201bea <kmalloc>
ffffffffc02038ae:	85aa                	mv	a1,a0
    if (vma != NULL)
ffffffffc02038b0:	fd55                	bnez	a0,ffffffffc020386c <dup_mmap+0x1c>
            return -E_NO_MEM;
ffffffffc02038b2:	5571                	li	a0,-4
        {
            return -E_NO_MEM;
        }
    }
    return 0;
}
ffffffffc02038b4:	70e2                	ld	ra,56(sp)
ffffffffc02038b6:	7442                	ld	s0,48(sp)
ffffffffc02038b8:	74a2                	ld	s1,40(sp)
ffffffffc02038ba:	7902                	ld	s2,32(sp)
ffffffffc02038bc:	69e2                	ld	s3,24(sp)
ffffffffc02038be:	6a42                	ld	s4,16(sp)
ffffffffc02038c0:	6aa2                	ld	s5,8(sp)
ffffffffc02038c2:	6121                	addi	sp,sp,64
ffffffffc02038c4:	8082                	ret
    return 0;
ffffffffc02038c6:	4501                	li	a0,0
ffffffffc02038c8:	b7f5                	j	ffffffffc02038b4 <dup_mmap+0x64>
    assert(to != NULL && from != NULL);
ffffffffc02038ca:	00003697          	auipc	a3,0x3
ffffffffc02038ce:	60668693          	addi	a3,a3,1542 # ffffffffc0206ed0 <default_pmm_manager+0x840>
ffffffffc02038d2:	00003617          	auipc	a2,0x3
ffffffffc02038d6:	a0e60613          	addi	a2,a2,-1522 # ffffffffc02062e0 <commands+0x828>
ffffffffc02038da:	0cf00593          	li	a1,207
ffffffffc02038de:	00003517          	auipc	a0,0x3
ffffffffc02038e2:	55a50513          	addi	a0,a0,1370 # ffffffffc0206e38 <default_pmm_manager+0x7a8>
ffffffffc02038e6:	badfc0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc02038ea <exit_mmap>:

void exit_mmap(struct mm_struct *mm)
{
ffffffffc02038ea:	1101                	addi	sp,sp,-32
ffffffffc02038ec:	ec06                	sd	ra,24(sp)
ffffffffc02038ee:	e822                	sd	s0,16(sp)
ffffffffc02038f0:	e426                	sd	s1,8(sp)
ffffffffc02038f2:	e04a                	sd	s2,0(sp)
    assert(mm != NULL && mm_count(mm) == 0);
ffffffffc02038f4:	c531                	beqz	a0,ffffffffc0203940 <exit_mmap+0x56>
ffffffffc02038f6:	591c                	lw	a5,48(a0)
ffffffffc02038f8:	84aa                	mv	s1,a0
ffffffffc02038fa:	e3b9                	bnez	a5,ffffffffc0203940 <exit_mmap+0x56>
    return listelm->next;
ffffffffc02038fc:	6500                	ld	s0,8(a0)
    pde_t *pgdir = mm->pgdir;
ffffffffc02038fe:	01853903          	ld	s2,24(a0)
    list_entry_t *list = &(mm->mmap_list), *le = list;
    while ((le = list_next(le)) != list)
ffffffffc0203902:	02850663          	beq	a0,s0,ffffffffc020392e <exit_mmap+0x44>
    {
        struct vma_struct *vma = le2vma(le, list_link);
        unmap_range(pgdir, vma->vm_start, vma->vm_end);
ffffffffc0203906:	ff043603          	ld	a2,-16(s0)
ffffffffc020390a:	fe843583          	ld	a1,-24(s0)
ffffffffc020390e:	854a                	mv	a0,s2
ffffffffc0203910:	fecfe0ef          	jal	ra,ffffffffc02020fc <unmap_range>
ffffffffc0203914:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != list)
ffffffffc0203916:	fe8498e3          	bne	s1,s0,ffffffffc0203906 <exit_mmap+0x1c>
ffffffffc020391a:	6400                	ld	s0,8(s0)
    }
    while ((le = list_next(le)) != list)
ffffffffc020391c:	00848c63          	beq	s1,s0,ffffffffc0203934 <exit_mmap+0x4a>
    {
        struct vma_struct *vma = le2vma(le, list_link);
        exit_range(pgdir, vma->vm_start, vma->vm_end);
ffffffffc0203920:	ff043603          	ld	a2,-16(s0)
ffffffffc0203924:	fe843583          	ld	a1,-24(s0)
ffffffffc0203928:	854a                	mv	a0,s2
ffffffffc020392a:	919fe0ef          	jal	ra,ffffffffc0202242 <exit_range>
ffffffffc020392e:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != list)
ffffffffc0203930:	fe8498e3          	bne	s1,s0,ffffffffc0203920 <exit_mmap+0x36>
    }
}
ffffffffc0203934:	60e2                	ld	ra,24(sp)
ffffffffc0203936:	6442                	ld	s0,16(sp)
ffffffffc0203938:	64a2                	ld	s1,8(sp)
ffffffffc020393a:	6902                	ld	s2,0(sp)
ffffffffc020393c:	6105                	addi	sp,sp,32
ffffffffc020393e:	8082                	ret
    assert(mm != NULL && mm_count(mm) == 0);
ffffffffc0203940:	00003697          	auipc	a3,0x3
ffffffffc0203944:	5b068693          	addi	a3,a3,1456 # ffffffffc0206ef0 <default_pmm_manager+0x860>
ffffffffc0203948:	00003617          	auipc	a2,0x3
ffffffffc020394c:	99860613          	addi	a2,a2,-1640 # ffffffffc02062e0 <commands+0x828>
ffffffffc0203950:	0e800593          	li	a1,232
ffffffffc0203954:	00003517          	auipc	a0,0x3
ffffffffc0203958:	4e450513          	addi	a0,a0,1252 # ffffffffc0206e38 <default_pmm_manager+0x7a8>
ffffffffc020395c:	b37fc0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0203960 <vmm_init>:
}

// vmm_init - initialize virtual memory management
//          - now just call check_vmm to check correctness of vmm
void vmm_init(void)
{
ffffffffc0203960:	7139                	addi	sp,sp,-64
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0203962:	04000513          	li	a0,64
{
ffffffffc0203966:	fc06                	sd	ra,56(sp)
ffffffffc0203968:	f822                	sd	s0,48(sp)
ffffffffc020396a:	f426                	sd	s1,40(sp)
ffffffffc020396c:	f04a                	sd	s2,32(sp)
ffffffffc020396e:	ec4e                	sd	s3,24(sp)
ffffffffc0203970:	e852                	sd	s4,16(sp)
ffffffffc0203972:	e456                	sd	s5,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0203974:	a76fe0ef          	jal	ra,ffffffffc0201bea <kmalloc>
    if (mm != NULL)
ffffffffc0203978:	2e050663          	beqz	a0,ffffffffc0203c64 <vmm_init+0x304>
ffffffffc020397c:	84aa                	mv	s1,a0
    elm->prev = elm->next = elm;
ffffffffc020397e:	e508                	sd	a0,8(a0)
ffffffffc0203980:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc0203982:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc0203986:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc020398a:	02052023          	sw	zero,32(a0)
        mm->sm_priv = NULL;
ffffffffc020398e:	02053423          	sd	zero,40(a0)
ffffffffc0203992:	02052823          	sw	zero,48(a0)
ffffffffc0203996:	02053c23          	sd	zero,56(a0)
ffffffffc020399a:	03200413          	li	s0,50
ffffffffc020399e:	a811                	j	ffffffffc02039b2 <vmm_init+0x52>
        vma->vm_start = vm_start;
ffffffffc02039a0:	e500                	sd	s0,8(a0)
        vma->vm_end = vm_end;
ffffffffc02039a2:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc02039a4:	00052c23          	sw	zero,24(a0)
    assert(mm != NULL);

    int step1 = 10, step2 = step1 * 10;

    int i;
    for (i = step1; i >= 1; i--)
ffffffffc02039a8:	146d                	addi	s0,s0,-5
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc02039aa:	8526                	mv	a0,s1
ffffffffc02039ac:	cd3ff0ef          	jal	ra,ffffffffc020367e <insert_vma_struct>
    for (i = step1; i >= 1; i--)
ffffffffc02039b0:	c80d                	beqz	s0,ffffffffc02039e2 <vmm_init+0x82>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc02039b2:	03000513          	li	a0,48
ffffffffc02039b6:	a34fe0ef          	jal	ra,ffffffffc0201bea <kmalloc>
ffffffffc02039ba:	85aa                	mv	a1,a0
ffffffffc02039bc:	00240793          	addi	a5,s0,2
    if (vma != NULL)
ffffffffc02039c0:	f165                	bnez	a0,ffffffffc02039a0 <vmm_init+0x40>
        assert(vma != NULL);
ffffffffc02039c2:	00003697          	auipc	a3,0x3
ffffffffc02039c6:	6c668693          	addi	a3,a3,1734 # ffffffffc0207088 <default_pmm_manager+0x9f8>
ffffffffc02039ca:	00003617          	auipc	a2,0x3
ffffffffc02039ce:	91660613          	addi	a2,a2,-1770 # ffffffffc02062e0 <commands+0x828>
ffffffffc02039d2:	12c00593          	li	a1,300
ffffffffc02039d6:	00003517          	auipc	a0,0x3
ffffffffc02039da:	46250513          	addi	a0,a0,1122 # ffffffffc0206e38 <default_pmm_manager+0x7a8>
ffffffffc02039de:	ab5fc0ef          	jal	ra,ffffffffc0200492 <__panic>
ffffffffc02039e2:	03700413          	li	s0,55
    }

    for (i = step1 + 1; i <= step2; i++)
ffffffffc02039e6:	1f900913          	li	s2,505
ffffffffc02039ea:	a819                	j	ffffffffc0203a00 <vmm_init+0xa0>
        vma->vm_start = vm_start;
ffffffffc02039ec:	e500                	sd	s0,8(a0)
        vma->vm_end = vm_end;
ffffffffc02039ee:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc02039f0:	00052c23          	sw	zero,24(a0)
    for (i = step1 + 1; i <= step2; i++)
ffffffffc02039f4:	0415                	addi	s0,s0,5
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc02039f6:	8526                	mv	a0,s1
ffffffffc02039f8:	c87ff0ef          	jal	ra,ffffffffc020367e <insert_vma_struct>
    for (i = step1 + 1; i <= step2; i++)
ffffffffc02039fc:	03240a63          	beq	s0,s2,ffffffffc0203a30 <vmm_init+0xd0>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203a00:	03000513          	li	a0,48
ffffffffc0203a04:	9e6fe0ef          	jal	ra,ffffffffc0201bea <kmalloc>
ffffffffc0203a08:	85aa                	mv	a1,a0
ffffffffc0203a0a:	00240793          	addi	a5,s0,2
    if (vma != NULL)
ffffffffc0203a0e:	fd79                	bnez	a0,ffffffffc02039ec <vmm_init+0x8c>
        assert(vma != NULL);
ffffffffc0203a10:	00003697          	auipc	a3,0x3
ffffffffc0203a14:	67868693          	addi	a3,a3,1656 # ffffffffc0207088 <default_pmm_manager+0x9f8>
ffffffffc0203a18:	00003617          	auipc	a2,0x3
ffffffffc0203a1c:	8c860613          	addi	a2,a2,-1848 # ffffffffc02062e0 <commands+0x828>
ffffffffc0203a20:	13300593          	li	a1,307
ffffffffc0203a24:	00003517          	auipc	a0,0x3
ffffffffc0203a28:	41450513          	addi	a0,a0,1044 # ffffffffc0206e38 <default_pmm_manager+0x7a8>
ffffffffc0203a2c:	a67fc0ef          	jal	ra,ffffffffc0200492 <__panic>
    return listelm->next;
ffffffffc0203a30:	649c                	ld	a5,8(s1)
ffffffffc0203a32:	471d                	li	a4,7
    }

    list_entry_t *le = list_next(&(mm->mmap_list));

    for (i = 1; i <= step2; i++)
ffffffffc0203a34:	1fb00593          	li	a1,507
    {
        assert(le != &(mm->mmap_list));
ffffffffc0203a38:	16f48663          	beq	s1,a5,ffffffffc0203ba4 <vmm_init+0x244>
        struct vma_struct *mmap = le2vma(le, list_link);
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0203a3c:	fe87b603          	ld	a2,-24(a5) # ffffffffffffefe8 <end+0x3fd382e0>
ffffffffc0203a40:	ffe70693          	addi	a3,a4,-2
ffffffffc0203a44:	10d61063          	bne	a2,a3,ffffffffc0203b44 <vmm_init+0x1e4>
ffffffffc0203a48:	ff07b683          	ld	a3,-16(a5)
ffffffffc0203a4c:	0ed71c63          	bne	a4,a3,ffffffffc0203b44 <vmm_init+0x1e4>
    for (i = 1; i <= step2; i++)
ffffffffc0203a50:	0715                	addi	a4,a4,5
ffffffffc0203a52:	679c                	ld	a5,8(a5)
ffffffffc0203a54:	feb712e3          	bne	a4,a1,ffffffffc0203a38 <vmm_init+0xd8>
ffffffffc0203a58:	4a1d                	li	s4,7
ffffffffc0203a5a:	4415                	li	s0,5
        le = list_next(le);
    }

    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc0203a5c:	1f900a93          	li	s5,505
    {
        struct vma_struct *vma1 = find_vma(mm, i);
ffffffffc0203a60:	85a2                	mv	a1,s0
ffffffffc0203a62:	8526                	mv	a0,s1
ffffffffc0203a64:	bdbff0ef          	jal	ra,ffffffffc020363e <find_vma>
ffffffffc0203a68:	892a                	mv	s2,a0
        assert(vma1 != NULL);
ffffffffc0203a6a:	16050d63          	beqz	a0,ffffffffc0203be4 <vmm_init+0x284>
        struct vma_struct *vma2 = find_vma(mm, i + 1);
ffffffffc0203a6e:	00140593          	addi	a1,s0,1
ffffffffc0203a72:	8526                	mv	a0,s1
ffffffffc0203a74:	bcbff0ef          	jal	ra,ffffffffc020363e <find_vma>
ffffffffc0203a78:	89aa                	mv	s3,a0
        assert(vma2 != NULL);
ffffffffc0203a7a:	14050563          	beqz	a0,ffffffffc0203bc4 <vmm_init+0x264>
        struct vma_struct *vma3 = find_vma(mm, i + 2);
ffffffffc0203a7e:	85d2                	mv	a1,s4
ffffffffc0203a80:	8526                	mv	a0,s1
ffffffffc0203a82:	bbdff0ef          	jal	ra,ffffffffc020363e <find_vma>
        assert(vma3 == NULL);
ffffffffc0203a86:	16051f63          	bnez	a0,ffffffffc0203c04 <vmm_init+0x2a4>
        struct vma_struct *vma4 = find_vma(mm, i + 3);
ffffffffc0203a8a:	00340593          	addi	a1,s0,3
ffffffffc0203a8e:	8526                	mv	a0,s1
ffffffffc0203a90:	bafff0ef          	jal	ra,ffffffffc020363e <find_vma>
        assert(vma4 == NULL);
ffffffffc0203a94:	1a051863          	bnez	a0,ffffffffc0203c44 <vmm_init+0x2e4>
        struct vma_struct *vma5 = find_vma(mm, i + 4);
ffffffffc0203a98:	00440593          	addi	a1,s0,4
ffffffffc0203a9c:	8526                	mv	a0,s1
ffffffffc0203a9e:	ba1ff0ef          	jal	ra,ffffffffc020363e <find_vma>
        assert(vma5 == NULL);
ffffffffc0203aa2:	18051163          	bnez	a0,ffffffffc0203c24 <vmm_init+0x2c4>

        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc0203aa6:	00893783          	ld	a5,8(s2)
ffffffffc0203aaa:	0a879d63          	bne	a5,s0,ffffffffc0203b64 <vmm_init+0x204>
ffffffffc0203aae:	01093783          	ld	a5,16(s2)
ffffffffc0203ab2:	0b479963          	bne	a5,s4,ffffffffc0203b64 <vmm_init+0x204>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc0203ab6:	0089b783          	ld	a5,8(s3)
ffffffffc0203aba:	0c879563          	bne	a5,s0,ffffffffc0203b84 <vmm_init+0x224>
ffffffffc0203abe:	0109b783          	ld	a5,16(s3)
ffffffffc0203ac2:	0d479163          	bne	a5,s4,ffffffffc0203b84 <vmm_init+0x224>
    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc0203ac6:	0415                	addi	s0,s0,5
ffffffffc0203ac8:	0a15                	addi	s4,s4,5
ffffffffc0203aca:	f9541be3          	bne	s0,s5,ffffffffc0203a60 <vmm_init+0x100>
ffffffffc0203ace:	4411                	li	s0,4
    }

    for (i = 4; i >= 0; i--)
ffffffffc0203ad0:	597d                	li	s2,-1
    {
        struct vma_struct *vma_below_5 = find_vma(mm, i);
ffffffffc0203ad2:	85a2                	mv	a1,s0
ffffffffc0203ad4:	8526                	mv	a0,s1
ffffffffc0203ad6:	b69ff0ef          	jal	ra,ffffffffc020363e <find_vma>
ffffffffc0203ada:	0004059b          	sext.w	a1,s0
        if (vma_below_5 != NULL)
ffffffffc0203ade:	c90d                	beqz	a0,ffffffffc0203b10 <vmm_init+0x1b0>
        {
            cprintf("vma_below_5: i %x, start %x, end %x\n", i, vma_below_5->vm_start, vma_below_5->vm_end);
ffffffffc0203ae0:	6914                	ld	a3,16(a0)
ffffffffc0203ae2:	6510                	ld	a2,8(a0)
ffffffffc0203ae4:	00003517          	auipc	a0,0x3
ffffffffc0203ae8:	52c50513          	addi	a0,a0,1324 # ffffffffc0207010 <default_pmm_manager+0x980>
ffffffffc0203aec:	eacfc0ef          	jal	ra,ffffffffc0200198 <cprintf>
        }
        assert(vma_below_5 == NULL);
ffffffffc0203af0:	00003697          	auipc	a3,0x3
ffffffffc0203af4:	54868693          	addi	a3,a3,1352 # ffffffffc0207038 <default_pmm_manager+0x9a8>
ffffffffc0203af8:	00002617          	auipc	a2,0x2
ffffffffc0203afc:	7e860613          	addi	a2,a2,2024 # ffffffffc02062e0 <commands+0x828>
ffffffffc0203b00:	15900593          	li	a1,345
ffffffffc0203b04:	00003517          	auipc	a0,0x3
ffffffffc0203b08:	33450513          	addi	a0,a0,820 # ffffffffc0206e38 <default_pmm_manager+0x7a8>
ffffffffc0203b0c:	987fc0ef          	jal	ra,ffffffffc0200492 <__panic>
    for (i = 4; i >= 0; i--)
ffffffffc0203b10:	147d                	addi	s0,s0,-1
ffffffffc0203b12:	fd2410e3          	bne	s0,s2,ffffffffc0203ad2 <vmm_init+0x172>
    }

    mm_destroy(mm);
ffffffffc0203b16:	8526                	mv	a0,s1
ffffffffc0203b18:	c37ff0ef          	jal	ra,ffffffffc020374e <mm_destroy>

    cprintf("check_vma_struct() succeeded!\n");
ffffffffc0203b1c:	00003517          	auipc	a0,0x3
ffffffffc0203b20:	53450513          	addi	a0,a0,1332 # ffffffffc0207050 <default_pmm_manager+0x9c0>
ffffffffc0203b24:	e74fc0ef          	jal	ra,ffffffffc0200198 <cprintf>
}
ffffffffc0203b28:	7442                	ld	s0,48(sp)
ffffffffc0203b2a:	70e2                	ld	ra,56(sp)
ffffffffc0203b2c:	74a2                	ld	s1,40(sp)
ffffffffc0203b2e:	7902                	ld	s2,32(sp)
ffffffffc0203b30:	69e2                	ld	s3,24(sp)
ffffffffc0203b32:	6a42                	ld	s4,16(sp)
ffffffffc0203b34:	6aa2                	ld	s5,8(sp)
    cprintf("check_vmm() succeeded.\n");
ffffffffc0203b36:	00003517          	auipc	a0,0x3
ffffffffc0203b3a:	53a50513          	addi	a0,a0,1338 # ffffffffc0207070 <default_pmm_manager+0x9e0>
}
ffffffffc0203b3e:	6121                	addi	sp,sp,64
    cprintf("check_vmm() succeeded.\n");
ffffffffc0203b40:	e58fc06f          	j	ffffffffc0200198 <cprintf>
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0203b44:	00003697          	auipc	a3,0x3
ffffffffc0203b48:	3e468693          	addi	a3,a3,996 # ffffffffc0206f28 <default_pmm_manager+0x898>
ffffffffc0203b4c:	00002617          	auipc	a2,0x2
ffffffffc0203b50:	79460613          	addi	a2,a2,1940 # ffffffffc02062e0 <commands+0x828>
ffffffffc0203b54:	13d00593          	li	a1,317
ffffffffc0203b58:	00003517          	auipc	a0,0x3
ffffffffc0203b5c:	2e050513          	addi	a0,a0,736 # ffffffffc0206e38 <default_pmm_manager+0x7a8>
ffffffffc0203b60:	933fc0ef          	jal	ra,ffffffffc0200492 <__panic>
        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc0203b64:	00003697          	auipc	a3,0x3
ffffffffc0203b68:	44c68693          	addi	a3,a3,1100 # ffffffffc0206fb0 <default_pmm_manager+0x920>
ffffffffc0203b6c:	00002617          	auipc	a2,0x2
ffffffffc0203b70:	77460613          	addi	a2,a2,1908 # ffffffffc02062e0 <commands+0x828>
ffffffffc0203b74:	14e00593          	li	a1,334
ffffffffc0203b78:	00003517          	auipc	a0,0x3
ffffffffc0203b7c:	2c050513          	addi	a0,a0,704 # ffffffffc0206e38 <default_pmm_manager+0x7a8>
ffffffffc0203b80:	913fc0ef          	jal	ra,ffffffffc0200492 <__panic>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc0203b84:	00003697          	auipc	a3,0x3
ffffffffc0203b88:	45c68693          	addi	a3,a3,1116 # ffffffffc0206fe0 <default_pmm_manager+0x950>
ffffffffc0203b8c:	00002617          	auipc	a2,0x2
ffffffffc0203b90:	75460613          	addi	a2,a2,1876 # ffffffffc02062e0 <commands+0x828>
ffffffffc0203b94:	14f00593          	li	a1,335
ffffffffc0203b98:	00003517          	auipc	a0,0x3
ffffffffc0203b9c:	2a050513          	addi	a0,a0,672 # ffffffffc0206e38 <default_pmm_manager+0x7a8>
ffffffffc0203ba0:	8f3fc0ef          	jal	ra,ffffffffc0200492 <__panic>
        assert(le != &(mm->mmap_list));
ffffffffc0203ba4:	00003697          	auipc	a3,0x3
ffffffffc0203ba8:	36c68693          	addi	a3,a3,876 # ffffffffc0206f10 <default_pmm_manager+0x880>
ffffffffc0203bac:	00002617          	auipc	a2,0x2
ffffffffc0203bb0:	73460613          	addi	a2,a2,1844 # ffffffffc02062e0 <commands+0x828>
ffffffffc0203bb4:	13b00593          	li	a1,315
ffffffffc0203bb8:	00003517          	auipc	a0,0x3
ffffffffc0203bbc:	28050513          	addi	a0,a0,640 # ffffffffc0206e38 <default_pmm_manager+0x7a8>
ffffffffc0203bc0:	8d3fc0ef          	jal	ra,ffffffffc0200492 <__panic>
        assert(vma2 != NULL);
ffffffffc0203bc4:	00003697          	auipc	a3,0x3
ffffffffc0203bc8:	3ac68693          	addi	a3,a3,940 # ffffffffc0206f70 <default_pmm_manager+0x8e0>
ffffffffc0203bcc:	00002617          	auipc	a2,0x2
ffffffffc0203bd0:	71460613          	addi	a2,a2,1812 # ffffffffc02062e0 <commands+0x828>
ffffffffc0203bd4:	14600593          	li	a1,326
ffffffffc0203bd8:	00003517          	auipc	a0,0x3
ffffffffc0203bdc:	26050513          	addi	a0,a0,608 # ffffffffc0206e38 <default_pmm_manager+0x7a8>
ffffffffc0203be0:	8b3fc0ef          	jal	ra,ffffffffc0200492 <__panic>
        assert(vma1 != NULL);
ffffffffc0203be4:	00003697          	auipc	a3,0x3
ffffffffc0203be8:	37c68693          	addi	a3,a3,892 # ffffffffc0206f60 <default_pmm_manager+0x8d0>
ffffffffc0203bec:	00002617          	auipc	a2,0x2
ffffffffc0203bf0:	6f460613          	addi	a2,a2,1780 # ffffffffc02062e0 <commands+0x828>
ffffffffc0203bf4:	14400593          	li	a1,324
ffffffffc0203bf8:	00003517          	auipc	a0,0x3
ffffffffc0203bfc:	24050513          	addi	a0,a0,576 # ffffffffc0206e38 <default_pmm_manager+0x7a8>
ffffffffc0203c00:	893fc0ef          	jal	ra,ffffffffc0200492 <__panic>
        assert(vma3 == NULL);
ffffffffc0203c04:	00003697          	auipc	a3,0x3
ffffffffc0203c08:	37c68693          	addi	a3,a3,892 # ffffffffc0206f80 <default_pmm_manager+0x8f0>
ffffffffc0203c0c:	00002617          	auipc	a2,0x2
ffffffffc0203c10:	6d460613          	addi	a2,a2,1748 # ffffffffc02062e0 <commands+0x828>
ffffffffc0203c14:	14800593          	li	a1,328
ffffffffc0203c18:	00003517          	auipc	a0,0x3
ffffffffc0203c1c:	22050513          	addi	a0,a0,544 # ffffffffc0206e38 <default_pmm_manager+0x7a8>
ffffffffc0203c20:	873fc0ef          	jal	ra,ffffffffc0200492 <__panic>
        assert(vma5 == NULL);
ffffffffc0203c24:	00003697          	auipc	a3,0x3
ffffffffc0203c28:	37c68693          	addi	a3,a3,892 # ffffffffc0206fa0 <default_pmm_manager+0x910>
ffffffffc0203c2c:	00002617          	auipc	a2,0x2
ffffffffc0203c30:	6b460613          	addi	a2,a2,1716 # ffffffffc02062e0 <commands+0x828>
ffffffffc0203c34:	14c00593          	li	a1,332
ffffffffc0203c38:	00003517          	auipc	a0,0x3
ffffffffc0203c3c:	20050513          	addi	a0,a0,512 # ffffffffc0206e38 <default_pmm_manager+0x7a8>
ffffffffc0203c40:	853fc0ef          	jal	ra,ffffffffc0200492 <__panic>
        assert(vma4 == NULL);
ffffffffc0203c44:	00003697          	auipc	a3,0x3
ffffffffc0203c48:	34c68693          	addi	a3,a3,844 # ffffffffc0206f90 <default_pmm_manager+0x900>
ffffffffc0203c4c:	00002617          	auipc	a2,0x2
ffffffffc0203c50:	69460613          	addi	a2,a2,1684 # ffffffffc02062e0 <commands+0x828>
ffffffffc0203c54:	14a00593          	li	a1,330
ffffffffc0203c58:	00003517          	auipc	a0,0x3
ffffffffc0203c5c:	1e050513          	addi	a0,a0,480 # ffffffffc0206e38 <default_pmm_manager+0x7a8>
ffffffffc0203c60:	833fc0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(mm != NULL);
ffffffffc0203c64:	00003697          	auipc	a3,0x3
ffffffffc0203c68:	25c68693          	addi	a3,a3,604 # ffffffffc0206ec0 <default_pmm_manager+0x830>
ffffffffc0203c6c:	00002617          	auipc	a2,0x2
ffffffffc0203c70:	67460613          	addi	a2,a2,1652 # ffffffffc02062e0 <commands+0x828>
ffffffffc0203c74:	12400593          	li	a1,292
ffffffffc0203c78:	00003517          	auipc	a0,0x3
ffffffffc0203c7c:	1c050513          	addi	a0,a0,448 # ffffffffc0206e38 <default_pmm_manager+0x7a8>
ffffffffc0203c80:	813fc0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0203c84 <user_mem_check>:
}
bool user_mem_check(struct mm_struct *mm, uintptr_t addr, size_t len, bool write)
{
ffffffffc0203c84:	7179                	addi	sp,sp,-48
ffffffffc0203c86:	f022                	sd	s0,32(sp)
ffffffffc0203c88:	f406                	sd	ra,40(sp)
ffffffffc0203c8a:	ec26                	sd	s1,24(sp)
ffffffffc0203c8c:	e84a                	sd	s2,16(sp)
ffffffffc0203c8e:	e44e                	sd	s3,8(sp)
ffffffffc0203c90:	e052                	sd	s4,0(sp)
ffffffffc0203c92:	842e                	mv	s0,a1
    if (mm != NULL)
ffffffffc0203c94:	c135                	beqz	a0,ffffffffc0203cf8 <user_mem_check+0x74>
    {
        if (!USER_ACCESS(addr, addr + len))
ffffffffc0203c96:	002007b7          	lui	a5,0x200
ffffffffc0203c9a:	04f5e663          	bltu	a1,a5,ffffffffc0203ce6 <user_mem_check+0x62>
ffffffffc0203c9e:	00c584b3          	add	s1,a1,a2
ffffffffc0203ca2:	0495f263          	bgeu	a1,s1,ffffffffc0203ce6 <user_mem_check+0x62>
ffffffffc0203ca6:	4785                	li	a5,1
ffffffffc0203ca8:	07fe                	slli	a5,a5,0x1f
ffffffffc0203caa:	0297ee63          	bltu	a5,s1,ffffffffc0203ce6 <user_mem_check+0x62>
ffffffffc0203cae:	892a                	mv	s2,a0
ffffffffc0203cb0:	89b6                	mv	s3,a3
            {
                return 0;
            }
            if (write && (vma->vm_flags & VM_STACK))
            {
                if (start < vma->vm_start + PGSIZE)
ffffffffc0203cb2:	6a05                	lui	s4,0x1
ffffffffc0203cb4:	a821                	j	ffffffffc0203ccc <user_mem_check+0x48>
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203cb6:	0027f693          	andi	a3,a5,2
                if (start < vma->vm_start + PGSIZE)
ffffffffc0203cba:	9752                	add	a4,a4,s4
            if (write && (vma->vm_flags & VM_STACK))
ffffffffc0203cbc:	8ba1                	andi	a5,a5,8
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203cbe:	c685                	beqz	a3,ffffffffc0203ce6 <user_mem_check+0x62>
            if (write && (vma->vm_flags & VM_STACK))
ffffffffc0203cc0:	c399                	beqz	a5,ffffffffc0203cc6 <user_mem_check+0x42>
                if (start < vma->vm_start + PGSIZE)
ffffffffc0203cc2:	02e46263          	bltu	s0,a4,ffffffffc0203ce6 <user_mem_check+0x62>
                { // check stack start & size
                    return 0;
                }
            }
            start = vma->vm_end;
ffffffffc0203cc6:	6900                	ld	s0,16(a0)
        while (start < end)
ffffffffc0203cc8:	04947663          	bgeu	s0,s1,ffffffffc0203d14 <user_mem_check+0x90>
            if ((vma = find_vma(mm, start)) == NULL || start < vma->vm_start)
ffffffffc0203ccc:	85a2                	mv	a1,s0
ffffffffc0203cce:	854a                	mv	a0,s2
ffffffffc0203cd0:	96fff0ef          	jal	ra,ffffffffc020363e <find_vma>
ffffffffc0203cd4:	c909                	beqz	a0,ffffffffc0203ce6 <user_mem_check+0x62>
ffffffffc0203cd6:	6518                	ld	a4,8(a0)
ffffffffc0203cd8:	00e46763          	bltu	s0,a4,ffffffffc0203ce6 <user_mem_check+0x62>
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203cdc:	4d1c                	lw	a5,24(a0)
ffffffffc0203cde:	fc099ce3          	bnez	s3,ffffffffc0203cb6 <user_mem_check+0x32>
ffffffffc0203ce2:	8b85                	andi	a5,a5,1
ffffffffc0203ce4:	f3ed                	bnez	a5,ffffffffc0203cc6 <user_mem_check+0x42>
            return 0;
ffffffffc0203ce6:	4501                	li	a0,0
        }
        return 1;
    }
    return KERN_ACCESS(addr, addr + len);
}
ffffffffc0203ce8:	70a2                	ld	ra,40(sp)
ffffffffc0203cea:	7402                	ld	s0,32(sp)
ffffffffc0203cec:	64e2                	ld	s1,24(sp)
ffffffffc0203cee:	6942                	ld	s2,16(sp)
ffffffffc0203cf0:	69a2                	ld	s3,8(sp)
ffffffffc0203cf2:	6a02                	ld	s4,0(sp)
ffffffffc0203cf4:	6145                	addi	sp,sp,48
ffffffffc0203cf6:	8082                	ret
    return KERN_ACCESS(addr, addr + len);
ffffffffc0203cf8:	c02007b7          	lui	a5,0xc0200
ffffffffc0203cfc:	4501                	li	a0,0
ffffffffc0203cfe:	fef5e5e3          	bltu	a1,a5,ffffffffc0203ce8 <user_mem_check+0x64>
ffffffffc0203d02:	962e                	add	a2,a2,a1
ffffffffc0203d04:	fec5f2e3          	bgeu	a1,a2,ffffffffc0203ce8 <user_mem_check+0x64>
ffffffffc0203d08:	c8000537          	lui	a0,0xc8000
ffffffffc0203d0c:	0505                	addi	a0,a0,1
ffffffffc0203d0e:	00a63533          	sltu	a0,a2,a0
ffffffffc0203d12:	bfd9                	j	ffffffffc0203ce8 <user_mem_check+0x64>
        return 1;
ffffffffc0203d14:	4505                	li	a0,1
ffffffffc0203d16:	bfc9                	j	ffffffffc0203ce8 <user_mem_check+0x64>

ffffffffc0203d18 <kernel_thread_entry>:
.text
.globl kernel_thread_entry
kernel_thread_entry:        # void kernel_thread(void)
	move a0, s1
ffffffffc0203d18:	8526                	mv	a0,s1
	jalr s0
ffffffffc0203d1a:	9402                	jalr	s0

	jal do_exit
ffffffffc0203d1c:	5c6000ef          	jal	ra,ffffffffc02042e2 <do_exit>

ffffffffc0203d20 <alloc_proc>:
void switch_to(struct context *from, struct context *to);

// alloc_proc - alloc a proc_struct and init all fields of proc_struct
static struct proc_struct *
alloc_proc(void)
{
ffffffffc0203d20:	1141                	addi	sp,sp,-16
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0203d22:	14800513          	li	a0,328
{
ffffffffc0203d26:	e022                	sd	s0,0(sp)
ffffffffc0203d28:	e406                	sd	ra,8(sp)
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0203d2a:	ec1fd0ef          	jal	ra,ffffffffc0201bea <kmalloc>
ffffffffc0203d2e:	842a                	mv	s0,a0
    if (proc != NULL)
ffffffffc0203d30:	c941                	beqz	a0,ffffffffc0203dc0 <alloc_proc+0xa0>
    {
        // LAB4原有
        proc->state = PROC_UNINIT;                  // 初始化进程状态为未初始化
ffffffffc0203d32:	57fd                	li	a5,-1
ffffffffc0203d34:	1782                	slli	a5,a5,0x20
ffffffffc0203d36:	e11c                	sd	a5,0(a0)
        proc->runs = 0;                             // 初始化运行次数为0
        proc->kstack = 0;                           // 初始化内核栈为0（空指针），后续通过setup_kstack()为进程分配实际的内核栈空间
        proc->need_resched = 0;                     // 初始化不需要重新调度
        proc->parent = NULL;                        // 初始化父进程指针为NULL
        proc->mm = NULL;                            // 初始化内存管理结构指针为NULL
        memset(&(proc->context), 0, sizeof(struct context)); // 初始化上下文结构体，全部设为0，为后续保存现场做准备
ffffffffc0203d38:	07000613          	li	a2,112
ffffffffc0203d3c:	4581                	li	a1,0
        proc->runs = 0;                             // 初始化运行次数为0
ffffffffc0203d3e:	00052423          	sw	zero,8(a0) # ffffffffc8000008 <end+0x7d39300>
        proc->kstack = 0;                           // 初始化内核栈为0（空指针），后续通过setup_kstack()为进程分配实际的内核栈空间
ffffffffc0203d42:	00053823          	sd	zero,16(a0)
        proc->need_resched = 0;                     // 初始化不需要重新调度
ffffffffc0203d46:	00053c23          	sd	zero,24(a0)
        proc->parent = NULL;                        // 初始化父进程指针为NULL
ffffffffc0203d4a:	02053023          	sd	zero,32(a0)
        proc->mm = NULL;                            // 初始化内存管理结构指针为NULL
ffffffffc0203d4e:	02053423          	sd	zero,40(a0)
        memset(&(proc->context), 0, sizeof(struct context)); // 初始化上下文结构体，全部设为0，为后续保存现场做准备
ffffffffc0203d52:	03050513          	addi	a0,a0,48
ffffffffc0203d56:	2cf010ef          	jal	ra,ffffffffc0205824 <memset>
        proc->tf = NULL;                            // 初始化陷阱帧为NULL
        proc->pgdir = boot_pgdir_pa;                // 初始化页目录表基址为boot_pgdir_pa
ffffffffc0203d5a:	000c3797          	auipc	a5,0xc3
ffffffffc0203d5e:	f4e7b783          	ld	a5,-178(a5) # ffffffffc02c6ca8 <boot_pgdir_pa>
ffffffffc0203d62:	f45c                	sd	a5,168(s0)
        proc->tf = NULL;                            // 初始化陷阱帧为NULL
ffffffffc0203d64:	0a043023          	sd	zero,160(s0)
        proc->flags = 0;                            // 初始化进程标志为0
ffffffffc0203d68:	0a042823          	sw	zero,176(s0)
        memset(proc->name, 0, PROC_NAME_LEN + 1);   // 初始化进程名称数组全部清零，后续通过set_proc_name()设置具体的进程名称
ffffffffc0203d6c:	4641                	li	a2,16
ffffffffc0203d6e:	4581                	li	a1,0
ffffffffc0203d70:	0b440513          	addi	a0,s0,180
ffffffffc0203d74:	2b1010ef          	jal	ra,ffffffffc0205824 <memset>
         *       skew_heap_entry_t lab6_run_pool;            // entry in the run pool (lab6 stride)
         *       uint32_t lab6_stride;                       // stride value (lab6 stride)
         *       uint32_t lab6_priority;                     // priority value (lab6 stride)
         */
        proc->rq = NULL;                    // 初始化运行队列指针为NULL
        list_init(&(proc->run_link));       // 初始化运行队列链表节点
ffffffffc0203d78:	11040793          	addi	a5,s0,272
    elm->prev = elm->next = elm;
ffffffffc0203d7c:	10f43c23          	sd	a5,280(s0)
ffffffffc0203d80:	10f43823          	sd	a5,272(s0)
        proc->time_slice = 0;               // 初始化时间片为0，后续由调度器设置
        proc->lab6_run_pool.left = NULL;    // 初始化斜堆的左子树指针
        proc->lab6_run_pool.right = NULL;   // 初始化斜堆的右子树指针
        proc->lab6_run_pool.parent = NULL;  // 初始化斜堆的父节点指针
        proc->lab6_stride = 0;              // 初始化stride值为0
ffffffffc0203d84:	4785                	li	a5,1
        list_init(&(proc->list_link));
ffffffffc0203d86:	0c840693          	addi	a3,s0,200
        list_init(&(proc->hash_link));
ffffffffc0203d8a:	0d840713          	addi	a4,s0,216
        proc->lab6_stride = 0;              // 初始化stride值为0
ffffffffc0203d8e:	1782                	slli	a5,a5,0x20
ffffffffc0203d90:	e874                	sd	a3,208(s0)
ffffffffc0203d92:	e474                	sd	a3,200(s0)
ffffffffc0203d94:	f078                	sd	a4,224(s0)
ffffffffc0203d96:	ec78                	sd	a4,216(s0)
        proc->wait_state = 0;      // 设置进程的等待状态为0，表示进程当前不在等待状态
ffffffffc0203d98:	0e042623          	sw	zero,236(s0)
        proc->cptr = NULL;         // 初始化子进程指针为NULL
ffffffffc0203d9c:	0e043823          	sd	zero,240(s0)
        proc->optr = NULL;         // 初始化较年长兄弟进程(older sibling pointer)指针为NULL
ffffffffc0203da0:	10043023          	sd	zero,256(s0)
        proc->yptr = NULL;         // 初始化较年轻兄弟进程(younger sibling pointer)指针为NULL
ffffffffc0203da4:	0e043c23          	sd	zero,248(s0)
        proc->rq = NULL;                    // 初始化运行队列指针为NULL
ffffffffc0203da8:	10043423          	sd	zero,264(s0)
        proc->time_slice = 0;               // 初始化时间片为0，后续由调度器设置
ffffffffc0203dac:	12042023          	sw	zero,288(s0)
        proc->lab6_run_pool.parent = NULL;  // 初始化斜堆的父节点指针
ffffffffc0203db0:	12043423          	sd	zero,296(s0)
        proc->lab6_run_pool.left = NULL;    // 初始化斜堆的左子树指针
ffffffffc0203db4:	12043823          	sd	zero,304(s0)
        proc->lab6_run_pool.right = NULL;   // 初始化斜堆的右子树指针
ffffffffc0203db8:	12043c23          	sd	zero,312(s0)
        proc->lab6_stride = 0;              // 初始化stride值为0
ffffffffc0203dbc:	14f43023          	sd	a5,320(s0)
        proc->lab6_priority = 1;            // 初始化优先级为1（最小的优先级值，确保所有进程都有默认优先级）
    }
    return proc;
}
ffffffffc0203dc0:	60a2                	ld	ra,8(sp)
ffffffffc0203dc2:	8522                	mv	a0,s0
ffffffffc0203dc4:	6402                	ld	s0,0(sp)
ffffffffc0203dc6:	0141                	addi	sp,sp,16
ffffffffc0203dc8:	8082                	ret

ffffffffc0203dca <forkret>:
// NOTE: the addr of forkret is setted in copy_thread function
//       after switch_to, the current proc will execute here.
static void
forkret(void)
{
    forkrets(current->tf);
ffffffffc0203dca:	000c3797          	auipc	a5,0xc3
ffffffffc0203dce:	f0e7b783          	ld	a5,-242(a5) # ffffffffc02c6cd8 <current>
ffffffffc0203dd2:	73c8                	ld	a0,160(a5)
ffffffffc0203dd4:	932fd06f          	j	ffffffffc0200f06 <forkrets>

ffffffffc0203dd8 <put_pgdir>:
    return pa2page(PADDR(kva));
ffffffffc0203dd8:	6d14                	ld	a3,24(a0)
}

// put_pgdir - free the memory space of PDT
static void
put_pgdir(struct mm_struct *mm)
{
ffffffffc0203dda:	1141                	addi	sp,sp,-16
ffffffffc0203ddc:	e406                	sd	ra,8(sp)
ffffffffc0203dde:	c02007b7          	lui	a5,0xc0200
ffffffffc0203de2:	02f6ee63          	bltu	a3,a5,ffffffffc0203e1e <put_pgdir+0x46>
ffffffffc0203de6:	000c3517          	auipc	a0,0xc3
ffffffffc0203dea:	eea53503          	ld	a0,-278(a0) # ffffffffc02c6cd0 <va_pa_offset>
ffffffffc0203dee:	8e89                	sub	a3,a3,a0
    if (PPN(pa) >= npage)
ffffffffc0203df0:	82b1                	srli	a3,a3,0xc
ffffffffc0203df2:	000c3797          	auipc	a5,0xc3
ffffffffc0203df6:	ec67b783          	ld	a5,-314(a5) # ffffffffc02c6cb8 <npage>
ffffffffc0203dfa:	02f6fe63          	bgeu	a3,a5,ffffffffc0203e36 <put_pgdir+0x5e>
    return &pages[PPN(pa) - nbase];
ffffffffc0203dfe:	00004517          	auipc	a0,0x4
ffffffffc0203e02:	2ca53503          	ld	a0,714(a0) # ffffffffc02080c8 <nbase>
    free_page(kva2page(mm->pgdir));
}
ffffffffc0203e06:	60a2                	ld	ra,8(sp)
ffffffffc0203e08:	8e89                	sub	a3,a3,a0
ffffffffc0203e0a:	069a                	slli	a3,a3,0x6
    free_page(kva2page(mm->pgdir));
ffffffffc0203e0c:	000c3517          	auipc	a0,0xc3
ffffffffc0203e10:	eb453503          	ld	a0,-332(a0) # ffffffffc02c6cc0 <pages>
ffffffffc0203e14:	4585                	li	a1,1
ffffffffc0203e16:	9536                	add	a0,a0,a3
}
ffffffffc0203e18:	0141                	addi	sp,sp,16
    free_page(kva2page(mm->pgdir));
ffffffffc0203e1a:	fedfd06f          	j	ffffffffc0201e06 <free_pages>
    return pa2page(PADDR(kva));
ffffffffc0203e1e:	00003617          	auipc	a2,0x3
ffffffffc0203e22:	95260613          	addi	a2,a2,-1710 # ffffffffc0206770 <default_pmm_manager+0xe0>
ffffffffc0203e26:	07700593          	li	a1,119
ffffffffc0203e2a:	00003517          	auipc	a0,0x3
ffffffffc0203e2e:	8c650513          	addi	a0,a0,-1850 # ffffffffc02066f0 <default_pmm_manager+0x60>
ffffffffc0203e32:	e60fc0ef          	jal	ra,ffffffffc0200492 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0203e36:	00003617          	auipc	a2,0x3
ffffffffc0203e3a:	96260613          	addi	a2,a2,-1694 # ffffffffc0206798 <default_pmm_manager+0x108>
ffffffffc0203e3e:	06900593          	li	a1,105
ffffffffc0203e42:	00003517          	auipc	a0,0x3
ffffffffc0203e46:	8ae50513          	addi	a0,a0,-1874 # ffffffffc02066f0 <default_pmm_manager+0x60>
ffffffffc0203e4a:	e48fc0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0203e4e <proc_run>:
{
ffffffffc0203e4e:	7179                	addi	sp,sp,-48
ffffffffc0203e50:	f026                	sd	s1,32(sp)
    if (proc != current)
ffffffffc0203e52:	000c3497          	auipc	s1,0xc3
ffffffffc0203e56:	e8648493          	addi	s1,s1,-378 # ffffffffc02c6cd8 <current>
ffffffffc0203e5a:	6098                	ld	a4,0(s1)
{
ffffffffc0203e5c:	f406                	sd	ra,40(sp)
ffffffffc0203e5e:	ec4a                	sd	s2,24(sp)
    if (proc != current)
ffffffffc0203e60:	02a70a63          	beq	a4,a0,ffffffffc0203e94 <proc_run+0x46>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0203e64:	100027f3          	csrr	a5,sstatus
ffffffffc0203e68:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0203e6a:	4901                	li	s2,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0203e6c:	ef9d                	bnez	a5,ffffffffc0203eaa <proc_run+0x5c>
        current->runs++;
ffffffffc0203e6e:	4514                	lw	a3,8(a0)
#define barrier() __asm__ __volatile__("fence" ::: "memory")

static inline void
lsatp(unsigned long pgdir)
{
  write_csr(satp, 0x8000000000000000 | (pgdir >> RISCV_PGSHIFT));
ffffffffc0203e70:	755c                	ld	a5,168(a0)
        current = proc;
ffffffffc0203e72:	e088                	sd	a0,0(s1)
        current->runs++;
ffffffffc0203e74:	2685                	addiw	a3,a3,1
ffffffffc0203e76:	c514                	sw	a3,8(a0)
ffffffffc0203e78:	56fd                	li	a3,-1
ffffffffc0203e7a:	16fe                	slli	a3,a3,0x3f
ffffffffc0203e7c:	83b1                	srli	a5,a5,0xc
ffffffffc0203e7e:	8fd5                	or	a5,a5,a3
ffffffffc0203e80:	18079073          	csrw	satp,a5
        switch_to(&prev->context, &current->context);
ffffffffc0203e84:	03050593          	addi	a1,a0,48
ffffffffc0203e88:	03070513          	addi	a0,a4,48
ffffffffc0203e8c:	0fa010ef          	jal	ra,ffffffffc0204f86 <switch_to>
    if (flag)
ffffffffc0203e90:	00091763          	bnez	s2,ffffffffc0203e9e <proc_run+0x50>
}
ffffffffc0203e94:	70a2                	ld	ra,40(sp)
ffffffffc0203e96:	7482                	ld	s1,32(sp)
ffffffffc0203e98:	6962                	ld	s2,24(sp)
ffffffffc0203e9a:	6145                	addi	sp,sp,48
ffffffffc0203e9c:	8082                	ret
ffffffffc0203e9e:	70a2                	ld	ra,40(sp)
ffffffffc0203ea0:	7482                	ld	s1,32(sp)
ffffffffc0203ea2:	6962                	ld	s2,24(sp)
ffffffffc0203ea4:	6145                	addi	sp,sp,48
        intr_enable();
ffffffffc0203ea6:	b03fc06f          	j	ffffffffc02009a8 <intr_enable>
ffffffffc0203eaa:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0203eac:	b03fc0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        struct proc_struct *prev = current;
ffffffffc0203eb0:	6098                	ld	a4,0(s1)
        return 1;
ffffffffc0203eb2:	6522                	ld	a0,8(sp)
ffffffffc0203eb4:	4905                	li	s2,1
ffffffffc0203eb6:	bf65                	j	ffffffffc0203e6e <proc_run+0x20>

ffffffffc0203eb8 <do_fork>:
 * @clone_flags: used to guide how to clone the child process
 * @stack:       the parent's user stack pointer. if stack==0, It means to fork a kernel thread.
 * @tf:          the trapframe info, which will be copied to child process's proc->tf
 */
int do_fork(uint32_t clone_flags, uintptr_t stack, struct trapframe *tf)
{
ffffffffc0203eb8:	7119                	addi	sp,sp,-128
ffffffffc0203eba:	f0ca                	sd	s2,96(sp)
    int ret = -E_NO_FREE_PROC;
    struct proc_struct *proc;
    if (nr_process >= MAX_PROCESS)
ffffffffc0203ebc:	000c3917          	auipc	s2,0xc3
ffffffffc0203ec0:	e3490913          	addi	s2,s2,-460 # ffffffffc02c6cf0 <nr_process>
ffffffffc0203ec4:	00092703          	lw	a4,0(s2)
{
ffffffffc0203ec8:	fc86                	sd	ra,120(sp)
ffffffffc0203eca:	f8a2                	sd	s0,112(sp)
ffffffffc0203ecc:	f4a6                	sd	s1,104(sp)
ffffffffc0203ece:	ecce                	sd	s3,88(sp)
ffffffffc0203ed0:	e8d2                	sd	s4,80(sp)
ffffffffc0203ed2:	e4d6                	sd	s5,72(sp)
ffffffffc0203ed4:	e0da                	sd	s6,64(sp)
ffffffffc0203ed6:	fc5e                	sd	s7,56(sp)
ffffffffc0203ed8:	f862                	sd	s8,48(sp)
ffffffffc0203eda:	f466                	sd	s9,40(sp)
ffffffffc0203edc:	f06a                	sd	s10,32(sp)
ffffffffc0203ede:	ec6e                	sd	s11,24(sp)
    if (nr_process >= MAX_PROCESS)
ffffffffc0203ee0:	6785                	lui	a5,0x1
ffffffffc0203ee2:	32f75663          	bge	a4,a5,ffffffffc020420e <do_fork+0x356>
ffffffffc0203ee6:	8a2a                	mv	s4,a0
ffffffffc0203ee8:	89ae                	mv	s3,a1
ffffffffc0203eea:	8432                	mv	s0,a2
     *    -------------------
     *    update step 1: set child proc's parent to current process, make sure current process's wait_state is 0
     *    update step 5: insert proc_struct into hash_list && proc_list, set the relation links of process
     */
    // 1) 分配进程控制块
    if ((proc = alloc_proc()) == NULL) {
ffffffffc0203eec:	e35ff0ef          	jal	ra,ffffffffc0203d20 <alloc_proc>
ffffffffc0203ef0:	84aa                	mv	s1,a0
ffffffffc0203ef2:	2e050f63          	beqz	a0,ffffffffc02041f0 <do_fork+0x338>
        goto fork_out;
    }
    
    // LAB5: 设置父进程，并确保父进程的 wait_state 为 
    proc->parent = current;
ffffffffc0203ef6:	000c3c17          	auipc	s8,0xc3
ffffffffc0203efa:	de2c0c13          	addi	s8,s8,-542 # ffffffffc02c6cd8 <current>
ffffffffc0203efe:	000c3783          	ld	a5,0(s8)
    struct Page *page = alloc_pages(KSTACKPAGE);
ffffffffc0203f02:	4509                	li	a0,2
    proc->parent = current;
ffffffffc0203f04:	f09c                	sd	a5,32(s1)
    struct Page *page = alloc_pages(KSTACKPAGE);
ffffffffc0203f06:	ec3fd0ef          	jal	ra,ffffffffc0201dc8 <alloc_pages>
    if (page != NULL)
ffffffffc0203f0a:	2e050063          	beqz	a0,ffffffffc02041ea <do_fork+0x332>
    return page - pages + nbase;
ffffffffc0203f0e:	000c3a97          	auipc	s5,0xc3
ffffffffc0203f12:	db2a8a93          	addi	s5,s5,-590 # ffffffffc02c6cc0 <pages>
ffffffffc0203f16:	000ab683          	ld	a3,0(s5)
ffffffffc0203f1a:	00004b17          	auipc	s6,0x4
ffffffffc0203f1e:	1aeb0b13          	addi	s6,s6,430 # ffffffffc02080c8 <nbase>
ffffffffc0203f22:	000b3783          	ld	a5,0(s6)
ffffffffc0203f26:	40d506b3          	sub	a3,a0,a3
    return KADDR(page2pa(page));
ffffffffc0203f2a:	000c3b97          	auipc	s7,0xc3
ffffffffc0203f2e:	d8eb8b93          	addi	s7,s7,-626 # ffffffffc02c6cb8 <npage>
    return page - pages + nbase;
ffffffffc0203f32:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0203f34:	5dfd                	li	s11,-1
ffffffffc0203f36:	000bb703          	ld	a4,0(s7)
    return page - pages + nbase;
ffffffffc0203f3a:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0203f3c:	00cddd93          	srli	s11,s11,0xc
ffffffffc0203f40:	01b6f633          	and	a2,a3,s11
    return page2ppn(page) << PGSHIFT;
ffffffffc0203f44:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0203f46:	32e67a63          	bgeu	a2,a4,ffffffffc020427a <do_fork+0x3c2>
    struct mm_struct *mm, *oldmm = current->mm;
ffffffffc0203f4a:	000c3603          	ld	a2,0(s8)
ffffffffc0203f4e:	000c3c17          	auipc	s8,0xc3
ffffffffc0203f52:	d82c0c13          	addi	s8,s8,-638 # ffffffffc02c6cd0 <va_pa_offset>
ffffffffc0203f56:	000c3703          	ld	a4,0(s8)
ffffffffc0203f5a:	02863d03          	ld	s10,40(a2)
ffffffffc0203f5e:	e43e                	sd	a5,8(sp)
ffffffffc0203f60:	96ba                	add	a3,a3,a4
        proc->kstack = (uintptr_t)page2kva(page);
ffffffffc0203f62:	e894                	sd	a3,16(s1)
    if (oldmm == NULL)
ffffffffc0203f64:	020d0863          	beqz	s10,ffffffffc0203f94 <do_fork+0xdc>
    if (clone_flags & CLONE_VM)
ffffffffc0203f68:	100a7a13          	andi	s4,s4,256
ffffffffc0203f6c:	1c0a0163          	beqz	s4,ffffffffc020412e <do_fork+0x276>
}

static inline int
mm_count_inc(struct mm_struct *mm)
{
    mm->mm_count += 1;
ffffffffc0203f70:	030d2703          	lw	a4,48(s10)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc0203f74:	018d3783          	ld	a5,24(s10)
ffffffffc0203f78:	c02006b7          	lui	a3,0xc0200
ffffffffc0203f7c:	2705                	addiw	a4,a4,1
ffffffffc0203f7e:	02ed2823          	sw	a4,48(s10)
    proc->mm = mm;
ffffffffc0203f82:	03a4b423          	sd	s10,40(s1)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc0203f86:	2cd7e163          	bltu	a5,a3,ffffffffc0204248 <do_fork+0x390>
ffffffffc0203f8a:	000c3703          	ld	a4,0(s8)
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc0203f8e:	6894                	ld	a3,16(s1)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc0203f90:	8f99                	sub	a5,a5,a4
ffffffffc0203f92:	f4dc                	sd	a5,168(s1)
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc0203f94:	6789                	lui	a5,0x2
ffffffffc0203f96:	ee078793          	addi	a5,a5,-288 # 1ee0 <_binary_obj___user_faultread_out_size-0x8068>
ffffffffc0203f9a:	96be                	add	a3,a3,a5
    *(proc->tf) = *tf;
ffffffffc0203f9c:	8622                	mv	a2,s0
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc0203f9e:	f0d4                	sd	a3,160(s1)
    *(proc->tf) = *tf;
ffffffffc0203fa0:	87b6                	mv	a5,a3
ffffffffc0203fa2:	12040893          	addi	a7,s0,288
ffffffffc0203fa6:	00063803          	ld	a6,0(a2)
ffffffffc0203faa:	6608                	ld	a0,8(a2)
ffffffffc0203fac:	6a0c                	ld	a1,16(a2)
ffffffffc0203fae:	6e18                	ld	a4,24(a2)
ffffffffc0203fb0:	0107b023          	sd	a6,0(a5)
ffffffffc0203fb4:	e788                	sd	a0,8(a5)
ffffffffc0203fb6:	eb8c                	sd	a1,16(a5)
ffffffffc0203fb8:	ef98                	sd	a4,24(a5)
ffffffffc0203fba:	02060613          	addi	a2,a2,32
ffffffffc0203fbe:	02078793          	addi	a5,a5,32
ffffffffc0203fc2:	ff1612e3          	bne	a2,a7,ffffffffc0203fa6 <do_fork+0xee>
    proc->tf->gpr.a0 = 0;
ffffffffc0203fc6:	0406b823          	sd	zero,80(a3) # ffffffffc0200050 <kern_init+0x6>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc0203fca:	12098f63          	beqz	s3,ffffffffc0204108 <do_fork+0x250>
ffffffffc0203fce:	0136b823          	sd	s3,16(a3)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc0203fd2:	00000797          	auipc	a5,0x0
ffffffffc0203fd6:	df878793          	addi	a5,a5,-520 # ffffffffc0203dca <forkret>
ffffffffc0203fda:	f89c                	sd	a5,48(s1)
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc0203fdc:	fc94                	sd	a3,56(s1)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0203fde:	100027f3          	csrr	a5,sstatus
ffffffffc0203fe2:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0203fe4:	4981                	li	s3,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0203fe6:	14079063          	bnez	a5,ffffffffc0204126 <do_fork+0x26e>
    if (++last_pid >= MAX_PID)
ffffffffc0203fea:	000bf817          	auipc	a6,0xbf
ffffffffc0203fee:	82e80813          	addi	a6,a6,-2002 # ffffffffc02c2818 <last_pid.1>
ffffffffc0203ff2:	00082783          	lw	a5,0(a6)
ffffffffc0203ff6:	6709                	lui	a4,0x2
ffffffffc0203ff8:	0017851b          	addiw	a0,a5,1
ffffffffc0203ffc:	00a82023          	sw	a0,0(a6)
ffffffffc0204000:	08e55d63          	bge	a0,a4,ffffffffc020409a <do_fork+0x1e2>
    if (last_pid >= next_safe)
ffffffffc0204004:	000bf317          	auipc	t1,0xbf
ffffffffc0204008:	81830313          	addi	t1,t1,-2024 # ffffffffc02c281c <next_safe.0>
ffffffffc020400c:	00032783          	lw	a5,0(t1)
ffffffffc0204010:	000c3417          	auipc	s0,0xc3
ffffffffc0204014:	c2840413          	addi	s0,s0,-984 # ffffffffc02c6c38 <proc_list>
ffffffffc0204018:	08f55963          	bge	a0,a5,ffffffffc02040aa <do_fork+0x1f2>

    // 5) 分配唯一 pid
    bool intr_flag;
    local_intr_save(intr_flag);  // 关中断，保证原子性
    {
        proc->pid = get_pid();
ffffffffc020401c:	c0c8                	sw	a0,4(s1)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc020401e:	45a9                	li	a1,10
ffffffffc0204020:	2501                	sext.w	a0,a0
ffffffffc0204022:	35c010ef          	jal	ra,ffffffffc020537e <hash32>
ffffffffc0204026:	02051793          	slli	a5,a0,0x20
ffffffffc020402a:	01c7d513          	srli	a0,a5,0x1c
ffffffffc020402e:	000bf797          	auipc	a5,0xbf
ffffffffc0204032:	c0a78793          	addi	a5,a5,-1014 # ffffffffc02c2c38 <hash_list>
ffffffffc0204036:	953e                	add	a0,a0,a5
    __list_add(elm, listelm, listelm->next);
ffffffffc0204038:	650c                	ld	a1,8(a0)
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc020403a:	7094                	ld	a3,32(s1)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc020403c:	0d848793          	addi	a5,s1,216
    prev->next = next->prev = elm;
ffffffffc0204040:	e19c                	sd	a5,0(a1)
    __list_add(elm, listelm, listelm->next);
ffffffffc0204042:	6410                	ld	a2,8(s0)
    prev->next = next->prev = elm;
ffffffffc0204044:	e51c                	sd	a5,8(a0)
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc0204046:	7af8                	ld	a4,240(a3)
    list_add(&proc_list, &(proc->list_link));
ffffffffc0204048:	0c848793          	addi	a5,s1,200
    elm->next = next;
ffffffffc020404c:	f0ec                	sd	a1,224(s1)
    elm->prev = prev;
ffffffffc020404e:	ece8                	sd	a0,216(s1)
    prev->next = next->prev = elm;
ffffffffc0204050:	e21c                	sd	a5,0(a2)
ffffffffc0204052:	e41c                	sd	a5,8(s0)
    elm->next = next;
ffffffffc0204054:	e8f0                	sd	a2,208(s1)
    elm->prev = prev;
ffffffffc0204056:	e4e0                	sd	s0,200(s1)
    proc->yptr = NULL;
ffffffffc0204058:	0e04bc23          	sd	zero,248(s1)
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc020405c:	10e4b023          	sd	a4,256(s1)
ffffffffc0204060:	c311                	beqz	a4,ffffffffc0204064 <do_fork+0x1ac>
        proc->optr->yptr = proc;
ffffffffc0204062:	ff64                	sd	s1,248(a4)
    nr_process++;
ffffffffc0204064:	00092783          	lw	a5,0(s2)
    proc->parent->cptr = proc;
ffffffffc0204068:	fae4                	sd	s1,240(a3)
    nr_process++;
ffffffffc020406a:	2785                	addiw	a5,a5,1
ffffffffc020406c:	00f92023          	sw	a5,0(s2)
    if (flag)
ffffffffc0204070:	18099263          	bnez	s3,ffffffffc02041f4 <do_fork+0x33c>
        set_links(proc);
    }
    local_intr_restore(intr_flag);  // 恢复中断

    // 6) 唤醒子进程，使其可调度（会把 state 置为 PROC_RUNNABLE）
    wakeup_proc(proc);
ffffffffc0204074:	8526                	mv	a0,s1
ffffffffc0204076:	096010ef          	jal	ra,ffffffffc020510c <wakeup_proc>

    // 7) 父进程得到子进程的 pid 作为返回值
    ret = proc->pid;
ffffffffc020407a:	40c8                	lw	a0,4(s1)
bad_fork_cleanup_kstack:
    put_kstack(proc);
bad_fork_cleanup_proc:
    kfree(proc);
    goto fork_out;
}
ffffffffc020407c:	70e6                	ld	ra,120(sp)
ffffffffc020407e:	7446                	ld	s0,112(sp)
ffffffffc0204080:	74a6                	ld	s1,104(sp)
ffffffffc0204082:	7906                	ld	s2,96(sp)
ffffffffc0204084:	69e6                	ld	s3,88(sp)
ffffffffc0204086:	6a46                	ld	s4,80(sp)
ffffffffc0204088:	6aa6                	ld	s5,72(sp)
ffffffffc020408a:	6b06                	ld	s6,64(sp)
ffffffffc020408c:	7be2                	ld	s7,56(sp)
ffffffffc020408e:	7c42                	ld	s8,48(sp)
ffffffffc0204090:	7ca2                	ld	s9,40(sp)
ffffffffc0204092:	7d02                	ld	s10,32(sp)
ffffffffc0204094:	6de2                	ld	s11,24(sp)
ffffffffc0204096:	6109                	addi	sp,sp,128
ffffffffc0204098:	8082                	ret
        last_pid = 1;
ffffffffc020409a:	4785                	li	a5,1
ffffffffc020409c:	00f82023          	sw	a5,0(a6)
        goto inside;
ffffffffc02040a0:	4505                	li	a0,1
ffffffffc02040a2:	000be317          	auipc	t1,0xbe
ffffffffc02040a6:	77a30313          	addi	t1,t1,1914 # ffffffffc02c281c <next_safe.0>
    return listelm->next;
ffffffffc02040aa:	000c3417          	auipc	s0,0xc3
ffffffffc02040ae:	b8e40413          	addi	s0,s0,-1138 # ffffffffc02c6c38 <proc_list>
ffffffffc02040b2:	00843e03          	ld	t3,8(s0)
        next_safe = MAX_PID;
ffffffffc02040b6:	6789                	lui	a5,0x2
ffffffffc02040b8:	00f32023          	sw	a5,0(t1)
ffffffffc02040bc:	86aa                	mv	a3,a0
ffffffffc02040be:	4581                	li	a1,0
        while ((le = list_next(le)) != list)
ffffffffc02040c0:	6e89                	lui	t4,0x2
ffffffffc02040c2:	148e0163          	beq	t3,s0,ffffffffc0204204 <do_fork+0x34c>
ffffffffc02040c6:	88ae                	mv	a7,a1
ffffffffc02040c8:	87f2                	mv	a5,t3
ffffffffc02040ca:	6609                	lui	a2,0x2
ffffffffc02040cc:	a811                	j	ffffffffc02040e0 <do_fork+0x228>
            else if (proc->pid > last_pid && next_safe > proc->pid)
ffffffffc02040ce:	00e6d663          	bge	a3,a4,ffffffffc02040da <do_fork+0x222>
ffffffffc02040d2:	00c75463          	bge	a4,a2,ffffffffc02040da <do_fork+0x222>
ffffffffc02040d6:	863a                	mv	a2,a4
ffffffffc02040d8:	4885                	li	a7,1
ffffffffc02040da:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc02040dc:	00878d63          	beq	a5,s0,ffffffffc02040f6 <do_fork+0x23e>
            if (proc->pid == last_pid)
ffffffffc02040e0:	f3c7a703          	lw	a4,-196(a5) # 1f3c <_binary_obj___user_faultread_out_size-0x800c>
ffffffffc02040e4:	fed715e3          	bne	a4,a3,ffffffffc02040ce <do_fork+0x216>
                if (++last_pid >= next_safe)
ffffffffc02040e8:	2685                	addiw	a3,a3,1
ffffffffc02040ea:	10c6d863          	bge	a3,a2,ffffffffc02041fa <do_fork+0x342>
ffffffffc02040ee:	679c                	ld	a5,8(a5)
ffffffffc02040f0:	4585                	li	a1,1
        while ((le = list_next(le)) != list)
ffffffffc02040f2:	fe8797e3          	bne	a5,s0,ffffffffc02040e0 <do_fork+0x228>
ffffffffc02040f6:	c581                	beqz	a1,ffffffffc02040fe <do_fork+0x246>
ffffffffc02040f8:	00d82023          	sw	a3,0(a6)
ffffffffc02040fc:	8536                	mv	a0,a3
ffffffffc02040fe:	f0088fe3          	beqz	a7,ffffffffc020401c <do_fork+0x164>
ffffffffc0204102:	00c32023          	sw	a2,0(t1)
ffffffffc0204106:	bf19                	j	ffffffffc020401c <do_fork+0x164>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc0204108:	89b6                	mv	s3,a3
ffffffffc020410a:	0136b823          	sd	s3,16(a3)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc020410e:	00000797          	auipc	a5,0x0
ffffffffc0204112:	cbc78793          	addi	a5,a5,-836 # ffffffffc0203dca <forkret>
ffffffffc0204116:	f89c                	sd	a5,48(s1)
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc0204118:	fc94                	sd	a3,56(s1)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020411a:	100027f3          	csrr	a5,sstatus
ffffffffc020411e:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0204120:	4981                	li	s3,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204122:	ec0784e3          	beqz	a5,ffffffffc0203fea <do_fork+0x132>
        intr_disable();
ffffffffc0204126:	889fc0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        return 1;
ffffffffc020412a:	4985                	li	s3,1
ffffffffc020412c:	bd7d                	j	ffffffffc0203fea <do_fork+0x132>
    if ((mm = mm_create()) == NULL)
ffffffffc020412e:	ce0ff0ef          	jal	ra,ffffffffc020360e <mm_create>
ffffffffc0204132:	8caa                	mv	s9,a0
ffffffffc0204134:	c159                	beqz	a0,ffffffffc02041ba <do_fork+0x302>
    if ((page = alloc_page()) == NULL)
ffffffffc0204136:	4505                	li	a0,1
ffffffffc0204138:	c91fd0ef          	jal	ra,ffffffffc0201dc8 <alloc_pages>
ffffffffc020413c:	cd25                	beqz	a0,ffffffffc02041b4 <do_fork+0x2fc>
    return page - pages + nbase;
ffffffffc020413e:	000ab683          	ld	a3,0(s5)
ffffffffc0204142:	67a2                	ld	a5,8(sp)
    return KADDR(page2pa(page));
ffffffffc0204144:	000bb703          	ld	a4,0(s7)
    return page - pages + nbase;
ffffffffc0204148:	40d506b3          	sub	a3,a0,a3
ffffffffc020414c:	8699                	srai	a3,a3,0x6
ffffffffc020414e:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0204150:	01b6fdb3          	and	s11,a3,s11
    return page2ppn(page) << PGSHIFT;
ffffffffc0204154:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204156:	12edf263          	bgeu	s11,a4,ffffffffc020427a <do_fork+0x3c2>
ffffffffc020415a:	000c3a03          	ld	s4,0(s8)
    memcpy(pgdir, boot_pgdir_va, PGSIZE);
ffffffffc020415e:	6605                	lui	a2,0x1
ffffffffc0204160:	000c3597          	auipc	a1,0xc3
ffffffffc0204164:	b505b583          	ld	a1,-1200(a1) # ffffffffc02c6cb0 <boot_pgdir_va>
ffffffffc0204168:	9a36                	add	s4,s4,a3
ffffffffc020416a:	8552                	mv	a0,s4
ffffffffc020416c:	6ca010ef          	jal	ra,ffffffffc0205836 <memcpy>
static inline void
lock_mm(struct mm_struct *mm)
{
    if (mm != NULL)
    {
        lock(&(mm->mm_lock));
ffffffffc0204170:	038d0d93          	addi	s11,s10,56
    mm->pgdir = pgdir;
ffffffffc0204174:	014cbc23          	sd	s4,24(s9)
 * test_and_set_bit - Atomically set a bit and return its old value
 * @nr:     the bit to set
 * @addr:   the address to count from
 * */
static inline bool test_and_set_bit(int nr, volatile void *addr) {
    return __test_and_op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0204178:	4785                	li	a5,1
ffffffffc020417a:	40fdb7af          	amoor.d	a5,a5,(s11)
}

static inline void
lock(lock_t *lock)
{
    while (!try_lock(lock))
ffffffffc020417e:	8b85                	andi	a5,a5,1
ffffffffc0204180:	4a05                	li	s4,1
ffffffffc0204182:	c799                	beqz	a5,ffffffffc0204190 <do_fork+0x2d8>
    {
        schedule();
ffffffffc0204184:	03a010ef          	jal	ra,ffffffffc02051be <schedule>
ffffffffc0204188:	414db7af          	amoor.d	a5,s4,(s11)
    while (!try_lock(lock))
ffffffffc020418c:	8b85                	andi	a5,a5,1
ffffffffc020418e:	fbfd                	bnez	a5,ffffffffc0204184 <do_fork+0x2cc>
        ret = dup_mmap(mm, oldmm);
ffffffffc0204190:	85ea                	mv	a1,s10
ffffffffc0204192:	8566                	mv	a0,s9
ffffffffc0204194:	ebcff0ef          	jal	ra,ffffffffc0203850 <dup_mmap>
 * test_and_clear_bit - Atomically clear a bit and return its old value
 * @nr:     the bit to clear
 * @addr:   the address to count from
 * */
static inline bool test_and_clear_bit(int nr, volatile void *addr) {
    return __test_and_op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0204198:	57f9                	li	a5,-2
ffffffffc020419a:	60fdb7af          	amoand.d	a5,a5,(s11)
ffffffffc020419e:	8b85                	andi	a5,a5,1
}

static inline void
unlock(lock_t *lock)
{
    if (!test_and_clear_bit(0, lock))
ffffffffc02041a0:	cfa5                	beqz	a5,ffffffffc0204218 <do_fork+0x360>
good_mm:
ffffffffc02041a2:	8d66                	mv	s10,s9
    if (ret != 0)
ffffffffc02041a4:	dc0506e3          	beqz	a0,ffffffffc0203f70 <do_fork+0xb8>
    exit_mmap(mm);
ffffffffc02041a8:	8566                	mv	a0,s9
ffffffffc02041aa:	f40ff0ef          	jal	ra,ffffffffc02038ea <exit_mmap>
    put_pgdir(mm);
ffffffffc02041ae:	8566                	mv	a0,s9
ffffffffc02041b0:	c29ff0ef          	jal	ra,ffffffffc0203dd8 <put_pgdir>
    mm_destroy(mm);
ffffffffc02041b4:	8566                	mv	a0,s9
ffffffffc02041b6:	d98ff0ef          	jal	ra,ffffffffc020374e <mm_destroy>
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
ffffffffc02041ba:	6894                	ld	a3,16(s1)
    return pa2page(PADDR(kva));
ffffffffc02041bc:	c02007b7          	lui	a5,0xc0200
ffffffffc02041c0:	0af6e163          	bltu	a3,a5,ffffffffc0204262 <do_fork+0x3aa>
ffffffffc02041c4:	000c3783          	ld	a5,0(s8)
    if (PPN(pa) >= npage)
ffffffffc02041c8:	000bb703          	ld	a4,0(s7)
    return pa2page(PADDR(kva));
ffffffffc02041cc:	40f687b3          	sub	a5,a3,a5
    if (PPN(pa) >= npage)
ffffffffc02041d0:	83b1                	srli	a5,a5,0xc
ffffffffc02041d2:	04e7ff63          	bgeu	a5,a4,ffffffffc0204230 <do_fork+0x378>
    return &pages[PPN(pa) - nbase];
ffffffffc02041d6:	000b3703          	ld	a4,0(s6)
ffffffffc02041da:	000ab503          	ld	a0,0(s5)
ffffffffc02041de:	4589                	li	a1,2
ffffffffc02041e0:	8f99                	sub	a5,a5,a4
ffffffffc02041e2:	079a                	slli	a5,a5,0x6
ffffffffc02041e4:	953e                	add	a0,a0,a5
ffffffffc02041e6:	c21fd0ef          	jal	ra,ffffffffc0201e06 <free_pages>
    kfree(proc);
ffffffffc02041ea:	8526                	mv	a0,s1
ffffffffc02041ec:	aaffd0ef          	jal	ra,ffffffffc0201c9a <kfree>
    ret = -E_NO_MEM;
ffffffffc02041f0:	5571                	li	a0,-4
    return ret;
ffffffffc02041f2:	b569                	j	ffffffffc020407c <do_fork+0x1c4>
        intr_enable();
ffffffffc02041f4:	fb4fc0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc02041f8:	bdb5                	j	ffffffffc0204074 <do_fork+0x1bc>
                    if (last_pid >= MAX_PID)
ffffffffc02041fa:	01d6c363          	blt	a3,t4,ffffffffc0204200 <do_fork+0x348>
                        last_pid = 1;
ffffffffc02041fe:	4685                	li	a3,1
                    goto repeat;
ffffffffc0204200:	4585                	li	a1,1
ffffffffc0204202:	b5c1                	j	ffffffffc02040c2 <do_fork+0x20a>
ffffffffc0204204:	c599                	beqz	a1,ffffffffc0204212 <do_fork+0x35a>
ffffffffc0204206:	00d82023          	sw	a3,0(a6)
    return last_pid;
ffffffffc020420a:	8536                	mv	a0,a3
ffffffffc020420c:	bd01                	j	ffffffffc020401c <do_fork+0x164>
    int ret = -E_NO_FREE_PROC;
ffffffffc020420e:	556d                	li	a0,-5
ffffffffc0204210:	b5b5                	j	ffffffffc020407c <do_fork+0x1c4>
    return last_pid;
ffffffffc0204212:	00082503          	lw	a0,0(a6)
ffffffffc0204216:	b519                	j	ffffffffc020401c <do_fork+0x164>
    {
        panic("Unlock failed.\n");
ffffffffc0204218:	00003617          	auipc	a2,0x3
ffffffffc020421c:	e8060613          	addi	a2,a2,-384 # ffffffffc0207098 <default_pmm_manager+0xa08>
ffffffffc0204220:	04000593          	li	a1,64
ffffffffc0204224:	00003517          	auipc	a0,0x3
ffffffffc0204228:	e8450513          	addi	a0,a0,-380 # ffffffffc02070a8 <default_pmm_manager+0xa18>
ffffffffc020422c:	a66fc0ef          	jal	ra,ffffffffc0200492 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0204230:	00002617          	auipc	a2,0x2
ffffffffc0204234:	56860613          	addi	a2,a2,1384 # ffffffffc0206798 <default_pmm_manager+0x108>
ffffffffc0204238:	06900593          	li	a1,105
ffffffffc020423c:	00002517          	auipc	a0,0x2
ffffffffc0204240:	4b450513          	addi	a0,a0,1204 # ffffffffc02066f0 <default_pmm_manager+0x60>
ffffffffc0204244:	a4efc0ef          	jal	ra,ffffffffc0200492 <__panic>
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc0204248:	86be                	mv	a3,a5
ffffffffc020424a:	00002617          	auipc	a2,0x2
ffffffffc020424e:	52660613          	addi	a2,a2,1318 # ffffffffc0206770 <default_pmm_manager+0xe0>
ffffffffc0204252:	19a00593          	li	a1,410
ffffffffc0204256:	00003517          	auipc	a0,0x3
ffffffffc020425a:	e6a50513          	addi	a0,a0,-406 # ffffffffc02070c0 <default_pmm_manager+0xa30>
ffffffffc020425e:	a34fc0ef          	jal	ra,ffffffffc0200492 <__panic>
    return pa2page(PADDR(kva));
ffffffffc0204262:	00002617          	auipc	a2,0x2
ffffffffc0204266:	50e60613          	addi	a2,a2,1294 # ffffffffc0206770 <default_pmm_manager+0xe0>
ffffffffc020426a:	07700593          	li	a1,119
ffffffffc020426e:	00002517          	auipc	a0,0x2
ffffffffc0204272:	48250513          	addi	a0,a0,1154 # ffffffffc02066f0 <default_pmm_manager+0x60>
ffffffffc0204276:	a1cfc0ef          	jal	ra,ffffffffc0200492 <__panic>
    return KADDR(page2pa(page));
ffffffffc020427a:	00002617          	auipc	a2,0x2
ffffffffc020427e:	44e60613          	addi	a2,a2,1102 # ffffffffc02066c8 <default_pmm_manager+0x38>
ffffffffc0204282:	07100593          	li	a1,113
ffffffffc0204286:	00002517          	auipc	a0,0x2
ffffffffc020428a:	46a50513          	addi	a0,a0,1130 # ffffffffc02066f0 <default_pmm_manager+0x60>
ffffffffc020428e:	a04fc0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0204292 <kernel_thread>:
{
ffffffffc0204292:	7129                	addi	sp,sp,-320
ffffffffc0204294:	fa22                	sd	s0,304(sp)
ffffffffc0204296:	f626                	sd	s1,296(sp)
ffffffffc0204298:	f24a                	sd	s2,288(sp)
ffffffffc020429a:	84ae                	mv	s1,a1
ffffffffc020429c:	892a                	mv	s2,a0
ffffffffc020429e:	8432                	mv	s0,a2
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc02042a0:	4581                	li	a1,0
ffffffffc02042a2:	12000613          	li	a2,288
ffffffffc02042a6:	850a                	mv	a0,sp
{
ffffffffc02042a8:	fe06                	sd	ra,312(sp)
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc02042aa:	57a010ef          	jal	ra,ffffffffc0205824 <memset>
    tf.gpr.s0 = (uintptr_t)fn;
ffffffffc02042ae:	e0ca                	sd	s2,64(sp)
    tf.gpr.s1 = (uintptr_t)arg;
ffffffffc02042b0:	e4a6                	sd	s1,72(sp)
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE;
ffffffffc02042b2:	100027f3          	csrr	a5,sstatus
ffffffffc02042b6:	edd7f793          	andi	a5,a5,-291
ffffffffc02042ba:	1207e793          	ori	a5,a5,288
ffffffffc02042be:	e23e                	sd	a5,256(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc02042c0:	860a                	mv	a2,sp
ffffffffc02042c2:	10046513          	ori	a0,s0,256
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc02042c6:	00000797          	auipc	a5,0x0
ffffffffc02042ca:	a5278793          	addi	a5,a5,-1454 # ffffffffc0203d18 <kernel_thread_entry>
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc02042ce:	4581                	li	a1,0
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc02042d0:	e63e                	sd	a5,264(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc02042d2:	be7ff0ef          	jal	ra,ffffffffc0203eb8 <do_fork>
}
ffffffffc02042d6:	70f2                	ld	ra,312(sp)
ffffffffc02042d8:	7452                	ld	s0,304(sp)
ffffffffc02042da:	74b2                	ld	s1,296(sp)
ffffffffc02042dc:	7912                	ld	s2,288(sp)
ffffffffc02042de:	6131                	addi	sp,sp,320
ffffffffc02042e0:	8082                	ret

ffffffffc02042e2 <do_exit>:
// do_exit - called by sys_exit
//   1. call exit_mmap & put_pgdir & mm_destroy to free the almost all memory space of process
//   2. set process' state as PROC_ZOMBIE, then call wakeup_proc(parent) to ask parent reclaim itself.
//   3. call scheduler to switch to other process
int do_exit(int error_code)
{
ffffffffc02042e2:	7179                	addi	sp,sp,-48
ffffffffc02042e4:	f022                	sd	s0,32(sp)
    if (current == idleproc)
ffffffffc02042e6:	000c3417          	auipc	s0,0xc3
ffffffffc02042ea:	9f240413          	addi	s0,s0,-1550 # ffffffffc02c6cd8 <current>
ffffffffc02042ee:	601c                	ld	a5,0(s0)
{
ffffffffc02042f0:	f406                	sd	ra,40(sp)
ffffffffc02042f2:	ec26                	sd	s1,24(sp)
ffffffffc02042f4:	e84a                	sd	s2,16(sp)
ffffffffc02042f6:	e44e                	sd	s3,8(sp)
ffffffffc02042f8:	e052                	sd	s4,0(sp)
    if (current == idleproc)
ffffffffc02042fa:	000c3717          	auipc	a4,0xc3
ffffffffc02042fe:	9e673703          	ld	a4,-1562(a4) # ffffffffc02c6ce0 <idleproc>
ffffffffc0204302:	0ce78c63          	beq	a5,a4,ffffffffc02043da <do_exit+0xf8>
    {
        panic("idleproc exit.\n");
    }
    if (current == initproc)
ffffffffc0204306:	000c3497          	auipc	s1,0xc3
ffffffffc020430a:	9e248493          	addi	s1,s1,-1566 # ffffffffc02c6ce8 <initproc>
ffffffffc020430e:	6098                	ld	a4,0(s1)
ffffffffc0204310:	0ee78b63          	beq	a5,a4,ffffffffc0204406 <do_exit+0x124>
    {
        panic("initproc exit.\n");
    }
    struct mm_struct *mm = current->mm;
ffffffffc0204314:	0287b983          	ld	s3,40(a5)
ffffffffc0204318:	892a                	mv	s2,a0
    if (mm != NULL)
ffffffffc020431a:	02098663          	beqz	s3,ffffffffc0204346 <do_exit+0x64>
ffffffffc020431e:	000c3797          	auipc	a5,0xc3
ffffffffc0204322:	98a7b783          	ld	a5,-1654(a5) # ffffffffc02c6ca8 <boot_pgdir_pa>
ffffffffc0204326:	577d                	li	a4,-1
ffffffffc0204328:	177e                	slli	a4,a4,0x3f
ffffffffc020432a:	83b1                	srli	a5,a5,0xc
ffffffffc020432c:	8fd9                	or	a5,a5,a4
ffffffffc020432e:	18079073          	csrw	satp,a5
    mm->mm_count -= 1;
ffffffffc0204332:	0309a783          	lw	a5,48(s3)
ffffffffc0204336:	fff7871b          	addiw	a4,a5,-1
ffffffffc020433a:	02e9a823          	sw	a4,48(s3)
    {
        lsatp(boot_pgdir_pa);
        if (mm_count_dec(mm) == 0)
ffffffffc020433e:	cb55                	beqz	a4,ffffffffc02043f2 <do_exit+0x110>
        {
            exit_mmap(mm);
            put_pgdir(mm);
            mm_destroy(mm);
        }
        current->mm = NULL;
ffffffffc0204340:	601c                	ld	a5,0(s0)
ffffffffc0204342:	0207b423          	sd	zero,40(a5)
    }
    current->state = PROC_ZOMBIE;
ffffffffc0204346:	601c                	ld	a5,0(s0)
ffffffffc0204348:	470d                	li	a4,3
ffffffffc020434a:	c398                	sw	a4,0(a5)
    current->exit_code = error_code;
ffffffffc020434c:	0f27a423          	sw	s2,232(a5)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204350:	100027f3          	csrr	a5,sstatus
ffffffffc0204354:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0204356:	4a01                	li	s4,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204358:	e3f9                	bnez	a5,ffffffffc020441e <do_exit+0x13c>
    bool intr_flag;
    struct proc_struct *proc;
    local_intr_save(intr_flag);
    {
        proc = current->parent;
ffffffffc020435a:	6018                	ld	a4,0(s0)
        if (proc->wait_state == WT_CHILD)
ffffffffc020435c:	800007b7          	lui	a5,0x80000
ffffffffc0204360:	0785                	addi	a5,a5,1
        proc = current->parent;
ffffffffc0204362:	7308                	ld	a0,32(a4)
        if (proc->wait_state == WT_CHILD)
ffffffffc0204364:	0ec52703          	lw	a4,236(a0)
ffffffffc0204368:	0af70f63          	beq	a4,a5,ffffffffc0204426 <do_exit+0x144>
        {
            wakeup_proc(proc);
        }
        while (current->cptr != NULL)
ffffffffc020436c:	6018                	ld	a4,0(s0)
ffffffffc020436e:	7b7c                	ld	a5,240(a4)
ffffffffc0204370:	c3a1                	beqz	a5,ffffffffc02043b0 <do_exit+0xce>
            }
            proc->parent = initproc;
            initproc->cptr = proc;
            if (proc->state == PROC_ZOMBIE)
            {
                if (initproc->wait_state == WT_CHILD)
ffffffffc0204372:	800009b7          	lui	s3,0x80000
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204376:	490d                	li	s2,3
                if (initproc->wait_state == WT_CHILD)
ffffffffc0204378:	0985                	addi	s3,s3,1
ffffffffc020437a:	a021                	j	ffffffffc0204382 <do_exit+0xa0>
        while (current->cptr != NULL)
ffffffffc020437c:	6018                	ld	a4,0(s0)
ffffffffc020437e:	7b7c                	ld	a5,240(a4)
ffffffffc0204380:	cb85                	beqz	a5,ffffffffc02043b0 <do_exit+0xce>
            current->cptr = proc->optr;
ffffffffc0204382:	1007b683          	ld	a3,256(a5) # ffffffff80000100 <_binary_obj___user_matrix_out_size+0xffffffff7fff39e0>
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc0204386:	6088                	ld	a0,0(s1)
            current->cptr = proc->optr;
ffffffffc0204388:	fb74                	sd	a3,240(a4)
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc020438a:	7978                	ld	a4,240(a0)
            proc->yptr = NULL;
ffffffffc020438c:	0e07bc23          	sd	zero,248(a5)
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc0204390:	10e7b023          	sd	a4,256(a5)
ffffffffc0204394:	c311                	beqz	a4,ffffffffc0204398 <do_exit+0xb6>
                initproc->cptr->yptr = proc;
ffffffffc0204396:	ff7c                	sd	a5,248(a4)
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204398:	4398                	lw	a4,0(a5)
            proc->parent = initproc;
ffffffffc020439a:	f388                	sd	a0,32(a5)
            initproc->cptr = proc;
ffffffffc020439c:	f97c                	sd	a5,240(a0)
            if (proc->state == PROC_ZOMBIE)
ffffffffc020439e:	fd271fe3          	bne	a4,s2,ffffffffc020437c <do_exit+0x9a>
                if (initproc->wait_state == WT_CHILD)
ffffffffc02043a2:	0ec52783          	lw	a5,236(a0)
ffffffffc02043a6:	fd379be3          	bne	a5,s3,ffffffffc020437c <do_exit+0x9a>
                {
                    wakeup_proc(initproc);
ffffffffc02043aa:	563000ef          	jal	ra,ffffffffc020510c <wakeup_proc>
ffffffffc02043ae:	b7f9                	j	ffffffffc020437c <do_exit+0x9a>
    if (flag)
ffffffffc02043b0:	020a1263          	bnez	s4,ffffffffc02043d4 <do_exit+0xf2>
                }
            }
        }
    }
    local_intr_restore(intr_flag);
    schedule();
ffffffffc02043b4:	60b000ef          	jal	ra,ffffffffc02051be <schedule>
    panic("do_exit will not return!! %d.\n", current->pid);
ffffffffc02043b8:	601c                	ld	a5,0(s0)
ffffffffc02043ba:	00003617          	auipc	a2,0x3
ffffffffc02043be:	d3e60613          	addi	a2,a2,-706 # ffffffffc02070f8 <default_pmm_manager+0xa68>
ffffffffc02043c2:	25600593          	li	a1,598
ffffffffc02043c6:	43d4                	lw	a3,4(a5)
ffffffffc02043c8:	00003517          	auipc	a0,0x3
ffffffffc02043cc:	cf850513          	addi	a0,a0,-776 # ffffffffc02070c0 <default_pmm_manager+0xa30>
ffffffffc02043d0:	8c2fc0ef          	jal	ra,ffffffffc0200492 <__panic>
        intr_enable();
ffffffffc02043d4:	dd4fc0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc02043d8:	bff1                	j	ffffffffc02043b4 <do_exit+0xd2>
        panic("idleproc exit.\n");
ffffffffc02043da:	00003617          	auipc	a2,0x3
ffffffffc02043de:	cfe60613          	addi	a2,a2,-770 # ffffffffc02070d8 <default_pmm_manager+0xa48>
ffffffffc02043e2:	22200593          	li	a1,546
ffffffffc02043e6:	00003517          	auipc	a0,0x3
ffffffffc02043ea:	cda50513          	addi	a0,a0,-806 # ffffffffc02070c0 <default_pmm_manager+0xa30>
ffffffffc02043ee:	8a4fc0ef          	jal	ra,ffffffffc0200492 <__panic>
            exit_mmap(mm);
ffffffffc02043f2:	854e                	mv	a0,s3
ffffffffc02043f4:	cf6ff0ef          	jal	ra,ffffffffc02038ea <exit_mmap>
            put_pgdir(mm);
ffffffffc02043f8:	854e                	mv	a0,s3
ffffffffc02043fa:	9dfff0ef          	jal	ra,ffffffffc0203dd8 <put_pgdir>
            mm_destroy(mm);
ffffffffc02043fe:	854e                	mv	a0,s3
ffffffffc0204400:	b4eff0ef          	jal	ra,ffffffffc020374e <mm_destroy>
ffffffffc0204404:	bf35                	j	ffffffffc0204340 <do_exit+0x5e>
        panic("initproc exit.\n");
ffffffffc0204406:	00003617          	auipc	a2,0x3
ffffffffc020440a:	ce260613          	addi	a2,a2,-798 # ffffffffc02070e8 <default_pmm_manager+0xa58>
ffffffffc020440e:	22600593          	li	a1,550
ffffffffc0204412:	00003517          	auipc	a0,0x3
ffffffffc0204416:	cae50513          	addi	a0,a0,-850 # ffffffffc02070c0 <default_pmm_manager+0xa30>
ffffffffc020441a:	878fc0ef          	jal	ra,ffffffffc0200492 <__panic>
        intr_disable();
ffffffffc020441e:	d90fc0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        return 1;
ffffffffc0204422:	4a05                	li	s4,1
ffffffffc0204424:	bf1d                	j	ffffffffc020435a <do_exit+0x78>
            wakeup_proc(proc);
ffffffffc0204426:	4e7000ef          	jal	ra,ffffffffc020510c <wakeup_proc>
ffffffffc020442a:	b789                	j	ffffffffc020436c <do_exit+0x8a>

ffffffffc020442c <do_wait.part.0>:
}

// do_wait - wait one OR any children with PROC_ZOMBIE state, and free memory space of kernel stack
//         - proc struct of this child.
// NOTE: only after do_wait function, all resources of the child proces are free.
int do_wait(int pid, int *code_store)
ffffffffc020442c:	715d                	addi	sp,sp,-80
ffffffffc020442e:	f84a                	sd	s2,48(sp)
ffffffffc0204430:	f44e                	sd	s3,40(sp)
        }
    }
    if (haskid)
    {
        current->state = PROC_SLEEPING;
        current->wait_state = WT_CHILD;
ffffffffc0204432:	80000937          	lui	s2,0x80000
    if (0 < pid && pid < MAX_PID)
ffffffffc0204436:	6989                	lui	s3,0x2
int do_wait(int pid, int *code_store)
ffffffffc0204438:	fc26                	sd	s1,56(sp)
ffffffffc020443a:	f052                	sd	s4,32(sp)
ffffffffc020443c:	ec56                	sd	s5,24(sp)
ffffffffc020443e:	e85a                	sd	s6,16(sp)
ffffffffc0204440:	e45e                	sd	s7,8(sp)
ffffffffc0204442:	e486                	sd	ra,72(sp)
ffffffffc0204444:	e0a2                	sd	s0,64(sp)
ffffffffc0204446:	84aa                	mv	s1,a0
ffffffffc0204448:	8a2e                	mv	s4,a1
        proc = current->cptr;
ffffffffc020444a:	000c3b97          	auipc	s7,0xc3
ffffffffc020444e:	88eb8b93          	addi	s7,s7,-1906 # ffffffffc02c6cd8 <current>
    if (0 < pid && pid < MAX_PID)
ffffffffc0204452:	00050b1b          	sext.w	s6,a0
ffffffffc0204456:	fff50a9b          	addiw	s5,a0,-1
ffffffffc020445a:	19f9                	addi	s3,s3,-2
        current->wait_state = WT_CHILD;
ffffffffc020445c:	0905                	addi	s2,s2,1
    if (pid != 0)
ffffffffc020445e:	ccbd                	beqz	s1,ffffffffc02044dc <do_wait.part.0+0xb0>
    if (0 < pid && pid < MAX_PID)
ffffffffc0204460:	0359e863          	bltu	s3,s5,ffffffffc0204490 <do_wait.part.0+0x64>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204464:	45a9                	li	a1,10
ffffffffc0204466:	855a                	mv	a0,s6
ffffffffc0204468:	717000ef          	jal	ra,ffffffffc020537e <hash32>
ffffffffc020446c:	02051793          	slli	a5,a0,0x20
ffffffffc0204470:	01c7d513          	srli	a0,a5,0x1c
ffffffffc0204474:	000be797          	auipc	a5,0xbe
ffffffffc0204478:	7c478793          	addi	a5,a5,1988 # ffffffffc02c2c38 <hash_list>
ffffffffc020447c:	953e                	add	a0,a0,a5
ffffffffc020447e:	842a                	mv	s0,a0
        while ((le = list_next(le)) != list)
ffffffffc0204480:	a029                	j	ffffffffc020448a <do_wait.part.0+0x5e>
            if (proc->pid == pid)
ffffffffc0204482:	f2c42783          	lw	a5,-212(s0)
ffffffffc0204486:	02978163          	beq	a5,s1,ffffffffc02044a8 <do_wait.part.0+0x7c>
ffffffffc020448a:	6400                	ld	s0,8(s0)
        while ((le = list_next(le)) != list)
ffffffffc020448c:	fe851be3          	bne	a0,s0,ffffffffc0204482 <do_wait.part.0+0x56>
        {
            do_exit(-E_KILLED);
        }
        goto repeat;
    }
    return -E_BAD_PROC;
ffffffffc0204490:	5579                	li	a0,-2
    }
    local_intr_restore(intr_flag);
    put_kstack(proc);
    kfree(proc);
    return 0;
}
ffffffffc0204492:	60a6                	ld	ra,72(sp)
ffffffffc0204494:	6406                	ld	s0,64(sp)
ffffffffc0204496:	74e2                	ld	s1,56(sp)
ffffffffc0204498:	7942                	ld	s2,48(sp)
ffffffffc020449a:	79a2                	ld	s3,40(sp)
ffffffffc020449c:	7a02                	ld	s4,32(sp)
ffffffffc020449e:	6ae2                	ld	s5,24(sp)
ffffffffc02044a0:	6b42                	ld	s6,16(sp)
ffffffffc02044a2:	6ba2                	ld	s7,8(sp)
ffffffffc02044a4:	6161                	addi	sp,sp,80
ffffffffc02044a6:	8082                	ret
        if (proc != NULL && proc->parent == current)
ffffffffc02044a8:	000bb683          	ld	a3,0(s7)
ffffffffc02044ac:	f4843783          	ld	a5,-184(s0)
ffffffffc02044b0:	fed790e3          	bne	a5,a3,ffffffffc0204490 <do_wait.part.0+0x64>
            if (proc->state == PROC_ZOMBIE)
ffffffffc02044b4:	f2842703          	lw	a4,-216(s0)
ffffffffc02044b8:	478d                	li	a5,3
ffffffffc02044ba:	0ef70b63          	beq	a4,a5,ffffffffc02045b0 <do_wait.part.0+0x184>
        current->state = PROC_SLEEPING;
ffffffffc02044be:	4785                	li	a5,1
ffffffffc02044c0:	c29c                	sw	a5,0(a3)
        current->wait_state = WT_CHILD;
ffffffffc02044c2:	0f26a623          	sw	s2,236(a3)
        schedule();
ffffffffc02044c6:	4f9000ef          	jal	ra,ffffffffc02051be <schedule>
        if (current->flags & PF_EXITING)
ffffffffc02044ca:	000bb783          	ld	a5,0(s7)
ffffffffc02044ce:	0b07a783          	lw	a5,176(a5)
ffffffffc02044d2:	8b85                	andi	a5,a5,1
ffffffffc02044d4:	d7c9                	beqz	a5,ffffffffc020445e <do_wait.part.0+0x32>
            do_exit(-E_KILLED);
ffffffffc02044d6:	555d                	li	a0,-9
ffffffffc02044d8:	e0bff0ef          	jal	ra,ffffffffc02042e2 <do_exit>
        proc = current->cptr;
ffffffffc02044dc:	000bb683          	ld	a3,0(s7)
ffffffffc02044e0:	7ae0                	ld	s0,240(a3)
        for (; proc != NULL; proc = proc->optr)
ffffffffc02044e2:	d45d                	beqz	s0,ffffffffc0204490 <do_wait.part.0+0x64>
            if (proc->state == PROC_ZOMBIE)
ffffffffc02044e4:	470d                	li	a4,3
ffffffffc02044e6:	a021                	j	ffffffffc02044ee <do_wait.part.0+0xc2>
        for (; proc != NULL; proc = proc->optr)
ffffffffc02044e8:	10043403          	ld	s0,256(s0)
ffffffffc02044ec:	d869                	beqz	s0,ffffffffc02044be <do_wait.part.0+0x92>
            if (proc->state == PROC_ZOMBIE)
ffffffffc02044ee:	401c                	lw	a5,0(s0)
ffffffffc02044f0:	fee79ce3          	bne	a5,a4,ffffffffc02044e8 <do_wait.part.0+0xbc>
    if (proc == idleproc || proc == initproc)
ffffffffc02044f4:	000c2797          	auipc	a5,0xc2
ffffffffc02044f8:	7ec7b783          	ld	a5,2028(a5) # ffffffffc02c6ce0 <idleproc>
ffffffffc02044fc:	0c878963          	beq	a5,s0,ffffffffc02045ce <do_wait.part.0+0x1a2>
ffffffffc0204500:	000c2797          	auipc	a5,0xc2
ffffffffc0204504:	7e87b783          	ld	a5,2024(a5) # ffffffffc02c6ce8 <initproc>
ffffffffc0204508:	0cf40363          	beq	s0,a5,ffffffffc02045ce <do_wait.part.0+0x1a2>
    if (code_store != NULL)
ffffffffc020450c:	000a0663          	beqz	s4,ffffffffc0204518 <do_wait.part.0+0xec>
        *code_store = proc->exit_code;
ffffffffc0204510:	0e842783          	lw	a5,232(s0)
ffffffffc0204514:	00fa2023          	sw	a5,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8f48>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204518:	100027f3          	csrr	a5,sstatus
ffffffffc020451c:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc020451e:	4581                	li	a1,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204520:	e7c1                	bnez	a5,ffffffffc02045a8 <do_wait.part.0+0x17c>
    __list_del(listelm->prev, listelm->next);
ffffffffc0204522:	6c70                	ld	a2,216(s0)
ffffffffc0204524:	7074                	ld	a3,224(s0)
    if (proc->optr != NULL)
ffffffffc0204526:	10043703          	ld	a4,256(s0)
        proc->optr->yptr = proc->yptr;
ffffffffc020452a:	7c7c                	ld	a5,248(s0)
    prev->next = next;
ffffffffc020452c:	e614                	sd	a3,8(a2)
    next->prev = prev;
ffffffffc020452e:	e290                	sd	a2,0(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc0204530:	6470                	ld	a2,200(s0)
ffffffffc0204532:	6874                	ld	a3,208(s0)
    prev->next = next;
ffffffffc0204534:	e614                	sd	a3,8(a2)
    next->prev = prev;
ffffffffc0204536:	e290                	sd	a2,0(a3)
    if (proc->optr != NULL)
ffffffffc0204538:	c319                	beqz	a4,ffffffffc020453e <do_wait.part.0+0x112>
        proc->optr->yptr = proc->yptr;
ffffffffc020453a:	ff7c                	sd	a5,248(a4)
    if (proc->yptr != NULL)
ffffffffc020453c:	7c7c                	ld	a5,248(s0)
ffffffffc020453e:	c3b5                	beqz	a5,ffffffffc02045a2 <do_wait.part.0+0x176>
        proc->yptr->optr = proc->optr;
ffffffffc0204540:	10e7b023          	sd	a4,256(a5)
    nr_process--;
ffffffffc0204544:	000c2717          	auipc	a4,0xc2
ffffffffc0204548:	7ac70713          	addi	a4,a4,1964 # ffffffffc02c6cf0 <nr_process>
ffffffffc020454c:	431c                	lw	a5,0(a4)
ffffffffc020454e:	37fd                	addiw	a5,a5,-1
ffffffffc0204550:	c31c                	sw	a5,0(a4)
    if (flag)
ffffffffc0204552:	e5a9                	bnez	a1,ffffffffc020459c <do_wait.part.0+0x170>
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
ffffffffc0204554:	6814                	ld	a3,16(s0)
    return pa2page(PADDR(kva));
ffffffffc0204556:	c02007b7          	lui	a5,0xc0200
ffffffffc020455a:	04f6ee63          	bltu	a3,a5,ffffffffc02045b6 <do_wait.part.0+0x18a>
ffffffffc020455e:	000c2797          	auipc	a5,0xc2
ffffffffc0204562:	7727b783          	ld	a5,1906(a5) # ffffffffc02c6cd0 <va_pa_offset>
ffffffffc0204566:	8e9d                	sub	a3,a3,a5
    if (PPN(pa) >= npage)
ffffffffc0204568:	82b1                	srli	a3,a3,0xc
ffffffffc020456a:	000c2797          	auipc	a5,0xc2
ffffffffc020456e:	74e7b783          	ld	a5,1870(a5) # ffffffffc02c6cb8 <npage>
ffffffffc0204572:	06f6fa63          	bgeu	a3,a5,ffffffffc02045e6 <do_wait.part.0+0x1ba>
    return &pages[PPN(pa) - nbase];
ffffffffc0204576:	00004517          	auipc	a0,0x4
ffffffffc020457a:	b5253503          	ld	a0,-1198(a0) # ffffffffc02080c8 <nbase>
ffffffffc020457e:	8e89                	sub	a3,a3,a0
ffffffffc0204580:	069a                	slli	a3,a3,0x6
ffffffffc0204582:	000c2517          	auipc	a0,0xc2
ffffffffc0204586:	73e53503          	ld	a0,1854(a0) # ffffffffc02c6cc0 <pages>
ffffffffc020458a:	9536                	add	a0,a0,a3
ffffffffc020458c:	4589                	li	a1,2
ffffffffc020458e:	879fd0ef          	jal	ra,ffffffffc0201e06 <free_pages>
    kfree(proc);
ffffffffc0204592:	8522                	mv	a0,s0
ffffffffc0204594:	f06fd0ef          	jal	ra,ffffffffc0201c9a <kfree>
    return 0;
ffffffffc0204598:	4501                	li	a0,0
ffffffffc020459a:	bde5                	j	ffffffffc0204492 <do_wait.part.0+0x66>
        intr_enable();
ffffffffc020459c:	c0cfc0ef          	jal	ra,ffffffffc02009a8 <intr_enable>
ffffffffc02045a0:	bf55                	j	ffffffffc0204554 <do_wait.part.0+0x128>
        proc->parent->cptr = proc->optr;
ffffffffc02045a2:	701c                	ld	a5,32(s0)
ffffffffc02045a4:	fbf8                	sd	a4,240(a5)
ffffffffc02045a6:	bf79                	j	ffffffffc0204544 <do_wait.part.0+0x118>
        intr_disable();
ffffffffc02045a8:	c06fc0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        return 1;
ffffffffc02045ac:	4585                	li	a1,1
ffffffffc02045ae:	bf95                	j	ffffffffc0204522 <do_wait.part.0+0xf6>
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc02045b0:	f2840413          	addi	s0,s0,-216
ffffffffc02045b4:	b781                	j	ffffffffc02044f4 <do_wait.part.0+0xc8>
    return pa2page(PADDR(kva));
ffffffffc02045b6:	00002617          	auipc	a2,0x2
ffffffffc02045ba:	1ba60613          	addi	a2,a2,442 # ffffffffc0206770 <default_pmm_manager+0xe0>
ffffffffc02045be:	07700593          	li	a1,119
ffffffffc02045c2:	00002517          	auipc	a0,0x2
ffffffffc02045c6:	12e50513          	addi	a0,a0,302 # ffffffffc02066f0 <default_pmm_manager+0x60>
ffffffffc02045ca:	ec9fb0ef          	jal	ra,ffffffffc0200492 <__panic>
        panic("wait idleproc or initproc.\n");
ffffffffc02045ce:	00003617          	auipc	a2,0x3
ffffffffc02045d2:	b4a60613          	addi	a2,a2,-1206 # ffffffffc0207118 <default_pmm_manager+0xa88>
ffffffffc02045d6:	37f00593          	li	a1,895
ffffffffc02045da:	00003517          	auipc	a0,0x3
ffffffffc02045de:	ae650513          	addi	a0,a0,-1306 # ffffffffc02070c0 <default_pmm_manager+0xa30>
ffffffffc02045e2:	eb1fb0ef          	jal	ra,ffffffffc0200492 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc02045e6:	00002617          	auipc	a2,0x2
ffffffffc02045ea:	1b260613          	addi	a2,a2,434 # ffffffffc0206798 <default_pmm_manager+0x108>
ffffffffc02045ee:	06900593          	li	a1,105
ffffffffc02045f2:	00002517          	auipc	a0,0x2
ffffffffc02045f6:	0fe50513          	addi	a0,a0,254 # ffffffffc02066f0 <default_pmm_manager+0x60>
ffffffffc02045fa:	e99fb0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc02045fe <init_main>:
}

// init_main - the second kernel thread used to create user_main kernel threads
static int
init_main(void *arg)
{
ffffffffc02045fe:	1141                	addi	sp,sp,-16
ffffffffc0204600:	e406                	sd	ra,8(sp)
    size_t nr_free_pages_store = nr_free_pages();
ffffffffc0204602:	845fd0ef          	jal	ra,ffffffffc0201e46 <nr_free_pages>
    size_t kernel_allocated_store = kallocated();
ffffffffc0204606:	de0fd0ef          	jal	ra,ffffffffc0201be6 <kallocated>

    int pid = kernel_thread(user_main, NULL, 0);
ffffffffc020460a:	4601                	li	a2,0
ffffffffc020460c:	4581                	li	a1,0
ffffffffc020460e:	00000517          	auipc	a0,0x0
ffffffffc0204612:	62c50513          	addi	a0,a0,1580 # ffffffffc0204c3a <user_main>
ffffffffc0204616:	c7dff0ef          	jal	ra,ffffffffc0204292 <kernel_thread>
    if (pid <= 0)
ffffffffc020461a:	00a04563          	bgtz	a0,ffffffffc0204624 <init_main+0x26>
ffffffffc020461e:	a071                	j	ffffffffc02046aa <init_main+0xac>
        panic("create user_main failed.\n");
    }

    while (do_wait(0, NULL) == 0)
    {
        schedule();
ffffffffc0204620:	39f000ef          	jal	ra,ffffffffc02051be <schedule>
    if (code_store != NULL)
ffffffffc0204624:	4581                	li	a1,0
ffffffffc0204626:	4501                	li	a0,0
ffffffffc0204628:	e05ff0ef          	jal	ra,ffffffffc020442c <do_wait.part.0>
    while (do_wait(0, NULL) == 0)
ffffffffc020462c:	d975                	beqz	a0,ffffffffc0204620 <init_main+0x22>
    }

    cprintf("all user-mode processes have quit.\n");
ffffffffc020462e:	00003517          	auipc	a0,0x3
ffffffffc0204632:	b2a50513          	addi	a0,a0,-1238 # ffffffffc0207158 <default_pmm_manager+0xac8>
ffffffffc0204636:	b63fb0ef          	jal	ra,ffffffffc0200198 <cprintf>
    assert(initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL);
ffffffffc020463a:	000c2797          	auipc	a5,0xc2
ffffffffc020463e:	6ae7b783          	ld	a5,1710(a5) # ffffffffc02c6ce8 <initproc>
ffffffffc0204642:	7bf8                	ld	a4,240(a5)
ffffffffc0204644:	e339                	bnez	a4,ffffffffc020468a <init_main+0x8c>
ffffffffc0204646:	7ff8                	ld	a4,248(a5)
ffffffffc0204648:	e329                	bnez	a4,ffffffffc020468a <init_main+0x8c>
ffffffffc020464a:	1007b703          	ld	a4,256(a5)
ffffffffc020464e:	ef15                	bnez	a4,ffffffffc020468a <init_main+0x8c>
    assert(nr_process == 2);
ffffffffc0204650:	000c2697          	auipc	a3,0xc2
ffffffffc0204654:	6a06a683          	lw	a3,1696(a3) # ffffffffc02c6cf0 <nr_process>
ffffffffc0204658:	4709                	li	a4,2
ffffffffc020465a:	0ae69463          	bne	a3,a4,ffffffffc0204702 <init_main+0x104>
    return listelm->next;
ffffffffc020465e:	000c2697          	auipc	a3,0xc2
ffffffffc0204662:	5da68693          	addi	a3,a3,1498 # ffffffffc02c6c38 <proc_list>
    assert(list_next(&proc_list) == &(initproc->list_link));
ffffffffc0204666:	6698                	ld	a4,8(a3)
ffffffffc0204668:	0c878793          	addi	a5,a5,200
ffffffffc020466c:	06f71b63          	bne	a4,a5,ffffffffc02046e2 <init_main+0xe4>
    assert(list_prev(&proc_list) == &(initproc->list_link));
ffffffffc0204670:	629c                	ld	a5,0(a3)
ffffffffc0204672:	04f71863          	bne	a4,a5,ffffffffc02046c2 <init_main+0xc4>

    cprintf("init check memory pass.\n");
ffffffffc0204676:	00003517          	auipc	a0,0x3
ffffffffc020467a:	bca50513          	addi	a0,a0,-1078 # ffffffffc0207240 <default_pmm_manager+0xbb0>
ffffffffc020467e:	b1bfb0ef          	jal	ra,ffffffffc0200198 <cprintf>
    return 0;
}
ffffffffc0204682:	60a2                	ld	ra,8(sp)
ffffffffc0204684:	4501                	li	a0,0
ffffffffc0204686:	0141                	addi	sp,sp,16
ffffffffc0204688:	8082                	ret
    assert(initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL);
ffffffffc020468a:	00003697          	auipc	a3,0x3
ffffffffc020468e:	af668693          	addi	a3,a3,-1290 # ffffffffc0207180 <default_pmm_manager+0xaf0>
ffffffffc0204692:	00002617          	auipc	a2,0x2
ffffffffc0204696:	c4e60613          	addi	a2,a2,-946 # ffffffffc02062e0 <commands+0x828>
ffffffffc020469a:	3eb00593          	li	a1,1003
ffffffffc020469e:	00003517          	auipc	a0,0x3
ffffffffc02046a2:	a2250513          	addi	a0,a0,-1502 # ffffffffc02070c0 <default_pmm_manager+0xa30>
ffffffffc02046a6:	dedfb0ef          	jal	ra,ffffffffc0200492 <__panic>
        panic("create user_main failed.\n");
ffffffffc02046aa:	00003617          	auipc	a2,0x3
ffffffffc02046ae:	a8e60613          	addi	a2,a2,-1394 # ffffffffc0207138 <default_pmm_manager+0xaa8>
ffffffffc02046b2:	3e200593          	li	a1,994
ffffffffc02046b6:	00003517          	auipc	a0,0x3
ffffffffc02046ba:	a0a50513          	addi	a0,a0,-1526 # ffffffffc02070c0 <default_pmm_manager+0xa30>
ffffffffc02046be:	dd5fb0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(list_prev(&proc_list) == &(initproc->list_link));
ffffffffc02046c2:	00003697          	auipc	a3,0x3
ffffffffc02046c6:	b4e68693          	addi	a3,a3,-1202 # ffffffffc0207210 <default_pmm_manager+0xb80>
ffffffffc02046ca:	00002617          	auipc	a2,0x2
ffffffffc02046ce:	c1660613          	addi	a2,a2,-1002 # ffffffffc02062e0 <commands+0x828>
ffffffffc02046d2:	3ee00593          	li	a1,1006
ffffffffc02046d6:	00003517          	auipc	a0,0x3
ffffffffc02046da:	9ea50513          	addi	a0,a0,-1558 # ffffffffc02070c0 <default_pmm_manager+0xa30>
ffffffffc02046de:	db5fb0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(list_next(&proc_list) == &(initproc->list_link));
ffffffffc02046e2:	00003697          	auipc	a3,0x3
ffffffffc02046e6:	afe68693          	addi	a3,a3,-1282 # ffffffffc02071e0 <default_pmm_manager+0xb50>
ffffffffc02046ea:	00002617          	auipc	a2,0x2
ffffffffc02046ee:	bf660613          	addi	a2,a2,-1034 # ffffffffc02062e0 <commands+0x828>
ffffffffc02046f2:	3ed00593          	li	a1,1005
ffffffffc02046f6:	00003517          	auipc	a0,0x3
ffffffffc02046fa:	9ca50513          	addi	a0,a0,-1590 # ffffffffc02070c0 <default_pmm_manager+0xa30>
ffffffffc02046fe:	d95fb0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(nr_process == 2);
ffffffffc0204702:	00003697          	auipc	a3,0x3
ffffffffc0204706:	ace68693          	addi	a3,a3,-1330 # ffffffffc02071d0 <default_pmm_manager+0xb40>
ffffffffc020470a:	00002617          	auipc	a2,0x2
ffffffffc020470e:	bd660613          	addi	a2,a2,-1066 # ffffffffc02062e0 <commands+0x828>
ffffffffc0204712:	3ec00593          	li	a1,1004
ffffffffc0204716:	00003517          	auipc	a0,0x3
ffffffffc020471a:	9aa50513          	addi	a0,a0,-1622 # ffffffffc02070c0 <default_pmm_manager+0xa30>
ffffffffc020471e:	d75fb0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0204722 <do_execve>:
{
ffffffffc0204722:	7171                	addi	sp,sp,-176
ffffffffc0204724:	e4ee                	sd	s11,72(sp)
    struct mm_struct *mm = current->mm;
ffffffffc0204726:	000c2d97          	auipc	s11,0xc2
ffffffffc020472a:	5b2d8d93          	addi	s11,s11,1458 # ffffffffc02c6cd8 <current>
ffffffffc020472e:	000db783          	ld	a5,0(s11)
{
ffffffffc0204732:	e54e                	sd	s3,136(sp)
ffffffffc0204734:	ed26                	sd	s1,152(sp)
    struct mm_struct *mm = current->mm;
ffffffffc0204736:	0287b983          	ld	s3,40(a5)
{
ffffffffc020473a:	e94a                	sd	s2,144(sp)
ffffffffc020473c:	f4de                	sd	s7,104(sp)
ffffffffc020473e:	892a                	mv	s2,a0
ffffffffc0204740:	8bb2                	mv	s7,a2
ffffffffc0204742:	84ae                	mv	s1,a1
    if (!user_mem_check(mm, (uintptr_t)name, len, 0))
ffffffffc0204744:	862e                	mv	a2,a1
ffffffffc0204746:	4681                	li	a3,0
ffffffffc0204748:	85aa                	mv	a1,a0
ffffffffc020474a:	854e                	mv	a0,s3
{
ffffffffc020474c:	f506                	sd	ra,168(sp)
ffffffffc020474e:	f122                	sd	s0,160(sp)
ffffffffc0204750:	e152                	sd	s4,128(sp)
ffffffffc0204752:	fcd6                	sd	s5,120(sp)
ffffffffc0204754:	f8da                	sd	s6,112(sp)
ffffffffc0204756:	f0e2                	sd	s8,96(sp)
ffffffffc0204758:	ece6                	sd	s9,88(sp)
ffffffffc020475a:	e8ea                	sd	s10,80(sp)
ffffffffc020475c:	f05e                	sd	s7,32(sp)
    if (!user_mem_check(mm, (uintptr_t)name, len, 0))
ffffffffc020475e:	d26ff0ef          	jal	ra,ffffffffc0203c84 <user_mem_check>
ffffffffc0204762:	40050c63          	beqz	a0,ffffffffc0204b7a <do_execve+0x458>
    memset(local_name, 0, sizeof(local_name));
ffffffffc0204766:	4641                	li	a2,16
ffffffffc0204768:	4581                	li	a1,0
ffffffffc020476a:	1808                	addi	a0,sp,48
ffffffffc020476c:	0b8010ef          	jal	ra,ffffffffc0205824 <memset>
    memcpy(local_name, name, len);
ffffffffc0204770:	47bd                	li	a5,15
ffffffffc0204772:	8626                	mv	a2,s1
ffffffffc0204774:	1e97e463          	bltu	a5,s1,ffffffffc020495c <do_execve+0x23a>
ffffffffc0204778:	85ca                	mv	a1,s2
ffffffffc020477a:	1808                	addi	a0,sp,48
ffffffffc020477c:	0ba010ef          	jal	ra,ffffffffc0205836 <memcpy>
    if (mm != NULL)
ffffffffc0204780:	1e098563          	beqz	s3,ffffffffc020496a <do_execve+0x248>
        cputs("mm != NULL");
ffffffffc0204784:	00002517          	auipc	a0,0x2
ffffffffc0204788:	73c50513          	addi	a0,a0,1852 # ffffffffc0206ec0 <default_pmm_manager+0x830>
ffffffffc020478c:	a45fb0ef          	jal	ra,ffffffffc02001d0 <cputs>
ffffffffc0204790:	000c2797          	auipc	a5,0xc2
ffffffffc0204794:	5187b783          	ld	a5,1304(a5) # ffffffffc02c6ca8 <boot_pgdir_pa>
ffffffffc0204798:	577d                	li	a4,-1
ffffffffc020479a:	177e                	slli	a4,a4,0x3f
ffffffffc020479c:	83b1                	srli	a5,a5,0xc
ffffffffc020479e:	8fd9                	or	a5,a5,a4
ffffffffc02047a0:	18079073          	csrw	satp,a5
ffffffffc02047a4:	0309a783          	lw	a5,48(s3) # 2030 <_binary_obj___user_faultread_out_size-0x7f18>
ffffffffc02047a8:	fff7871b          	addiw	a4,a5,-1
ffffffffc02047ac:	02e9a823          	sw	a4,48(s3)
        if (mm_count_dec(mm) == 0)
ffffffffc02047b0:	2c070663          	beqz	a4,ffffffffc0204a7c <do_execve+0x35a>
        current->mm = NULL;
ffffffffc02047b4:	000db783          	ld	a5,0(s11)
ffffffffc02047b8:	0207b423          	sd	zero,40(a5)
    if ((mm = mm_create()) == NULL)
ffffffffc02047bc:	e53fe0ef          	jal	ra,ffffffffc020360e <mm_create>
ffffffffc02047c0:	84aa                	mv	s1,a0
ffffffffc02047c2:	1c050f63          	beqz	a0,ffffffffc02049a0 <do_execve+0x27e>
    if ((page = alloc_page()) == NULL)
ffffffffc02047c6:	4505                	li	a0,1
ffffffffc02047c8:	e00fd0ef          	jal	ra,ffffffffc0201dc8 <alloc_pages>
ffffffffc02047cc:	3a050b63          	beqz	a0,ffffffffc0204b82 <do_execve+0x460>
    return page - pages + nbase;
ffffffffc02047d0:	000c2c97          	auipc	s9,0xc2
ffffffffc02047d4:	4f0c8c93          	addi	s9,s9,1264 # ffffffffc02c6cc0 <pages>
ffffffffc02047d8:	000cb683          	ld	a3,0(s9)
    return KADDR(page2pa(page));
ffffffffc02047dc:	000c2c17          	auipc	s8,0xc2
ffffffffc02047e0:	4dcc0c13          	addi	s8,s8,1244 # ffffffffc02c6cb8 <npage>
    return page - pages + nbase;
ffffffffc02047e4:	00004717          	auipc	a4,0x4
ffffffffc02047e8:	8e473703          	ld	a4,-1820(a4) # ffffffffc02080c8 <nbase>
ffffffffc02047ec:	40d506b3          	sub	a3,a0,a3
ffffffffc02047f0:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc02047f2:	5afd                	li	s5,-1
ffffffffc02047f4:	000c3783          	ld	a5,0(s8)
    return page - pages + nbase;
ffffffffc02047f8:	96ba                	add	a3,a3,a4
ffffffffc02047fa:	e83a                	sd	a4,16(sp)
    return KADDR(page2pa(page));
ffffffffc02047fc:	00cad713          	srli	a4,s5,0xc
ffffffffc0204800:	ec3a                	sd	a4,24(sp)
ffffffffc0204802:	8f75                	and	a4,a4,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc0204804:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204806:	38f77263          	bgeu	a4,a5,ffffffffc0204b8a <do_execve+0x468>
ffffffffc020480a:	000c2b17          	auipc	s6,0xc2
ffffffffc020480e:	4c6b0b13          	addi	s6,s6,1222 # ffffffffc02c6cd0 <va_pa_offset>
ffffffffc0204812:	000b3903          	ld	s2,0(s6)
    memcpy(pgdir, boot_pgdir_va, PGSIZE);
ffffffffc0204816:	6605                	lui	a2,0x1
ffffffffc0204818:	000c2597          	auipc	a1,0xc2
ffffffffc020481c:	4985b583          	ld	a1,1176(a1) # ffffffffc02c6cb0 <boot_pgdir_va>
ffffffffc0204820:	9936                	add	s2,s2,a3
ffffffffc0204822:	854a                	mv	a0,s2
ffffffffc0204824:	012010ef          	jal	ra,ffffffffc0205836 <memcpy>
    if (elf->e_magic != ELF_MAGIC)
ffffffffc0204828:	7782                	ld	a5,32(sp)
ffffffffc020482a:	4398                	lw	a4,0(a5)
ffffffffc020482c:	464c47b7          	lui	a5,0x464c4
    mm->pgdir = pgdir;
ffffffffc0204830:	0124bc23          	sd	s2,24(s1)
    if (elf->e_magic != ELF_MAGIC)
ffffffffc0204834:	57f78793          	addi	a5,a5,1407 # 464c457f <_binary_obj___user_matrix_out_size+0x464b7e5f>
ffffffffc0204838:	14f71a63          	bne	a4,a5,ffffffffc020498c <do_execve+0x26a>
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc020483c:	7682                	ld	a3,32(sp)
ffffffffc020483e:	0386d703          	lhu	a4,56(a3)
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
ffffffffc0204842:	0206b983          	ld	s3,32(a3)
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc0204846:	00371793          	slli	a5,a4,0x3
ffffffffc020484a:	8f99                	sub	a5,a5,a4
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
ffffffffc020484c:	99b6                	add	s3,s3,a3
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc020484e:	078e                	slli	a5,a5,0x3
ffffffffc0204850:	97ce                	add	a5,a5,s3
ffffffffc0204852:	f43e                	sd	a5,40(sp)
    for (; ph < ph_end; ph++)
ffffffffc0204854:	00f9fc63          	bgeu	s3,a5,ffffffffc020486c <do_execve+0x14a>
        if (ph->p_type != ELF_PT_LOAD)
ffffffffc0204858:	0009a783          	lw	a5,0(s3)
ffffffffc020485c:	4705                	li	a4,1
ffffffffc020485e:	14e78363          	beq	a5,a4,ffffffffc02049a4 <do_execve+0x282>
    for (; ph < ph_end; ph++)
ffffffffc0204862:	77a2                	ld	a5,40(sp)
ffffffffc0204864:	03898993          	addi	s3,s3,56
ffffffffc0204868:	fef9e8e3          	bltu	s3,a5,ffffffffc0204858 <do_execve+0x136>
    if ((ret = mm_map(mm, USTACKTOP - USTACKSIZE, USTACKSIZE, vm_flags, NULL)) != 0)
ffffffffc020486c:	4701                	li	a4,0
ffffffffc020486e:	46ad                	li	a3,11
ffffffffc0204870:	00100637          	lui	a2,0x100
ffffffffc0204874:	7ff005b7          	lui	a1,0x7ff00
ffffffffc0204878:	8526                	mv	a0,s1
ffffffffc020487a:	f27fe0ef          	jal	ra,ffffffffc02037a0 <mm_map>
ffffffffc020487e:	8a2a                	mv	s4,a0
ffffffffc0204880:	1e051463          	bnez	a0,ffffffffc0204a68 <do_execve+0x346>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - PGSIZE, PTE_USER) != NULL);
ffffffffc0204884:	6c88                	ld	a0,24(s1)
ffffffffc0204886:	467d                	li	a2,31
ffffffffc0204888:	7ffff5b7          	lui	a1,0x7ffff
ffffffffc020488c:	c9dfe0ef          	jal	ra,ffffffffc0203528 <pgdir_alloc_page>
ffffffffc0204890:	38050563          	beqz	a0,ffffffffc0204c1a <do_execve+0x4f8>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 2 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204894:	6c88                	ld	a0,24(s1)
ffffffffc0204896:	467d                	li	a2,31
ffffffffc0204898:	7fffe5b7          	lui	a1,0x7fffe
ffffffffc020489c:	c8dfe0ef          	jal	ra,ffffffffc0203528 <pgdir_alloc_page>
ffffffffc02048a0:	34050d63          	beqz	a0,ffffffffc0204bfa <do_execve+0x4d8>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 3 * PGSIZE, PTE_USER) != NULL);
ffffffffc02048a4:	6c88                	ld	a0,24(s1)
ffffffffc02048a6:	467d                	li	a2,31
ffffffffc02048a8:	7fffd5b7          	lui	a1,0x7fffd
ffffffffc02048ac:	c7dfe0ef          	jal	ra,ffffffffc0203528 <pgdir_alloc_page>
ffffffffc02048b0:	32050563          	beqz	a0,ffffffffc0204bda <do_execve+0x4b8>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 4 * PGSIZE, PTE_USER) != NULL);
ffffffffc02048b4:	6c88                	ld	a0,24(s1)
ffffffffc02048b6:	467d                	li	a2,31
ffffffffc02048b8:	7fffc5b7          	lui	a1,0x7fffc
ffffffffc02048bc:	c6dfe0ef          	jal	ra,ffffffffc0203528 <pgdir_alloc_page>
ffffffffc02048c0:	2e050d63          	beqz	a0,ffffffffc0204bba <do_execve+0x498>
    mm->mm_count += 1;
ffffffffc02048c4:	589c                	lw	a5,48(s1)
    current->mm = mm;
ffffffffc02048c6:	000db603          	ld	a2,0(s11)
    current->pgdir = PADDR(mm->pgdir);
ffffffffc02048ca:	6c94                	ld	a3,24(s1)
ffffffffc02048cc:	2785                	addiw	a5,a5,1
ffffffffc02048ce:	d89c                	sw	a5,48(s1)
    current->mm = mm;
ffffffffc02048d0:	f604                	sd	s1,40(a2)
    current->pgdir = PADDR(mm->pgdir);
ffffffffc02048d2:	c02007b7          	lui	a5,0xc0200
ffffffffc02048d6:	2cf6e663          	bltu	a3,a5,ffffffffc0204ba2 <do_execve+0x480>
ffffffffc02048da:	000b3783          	ld	a5,0(s6)
ffffffffc02048de:	577d                	li	a4,-1
ffffffffc02048e0:	177e                	slli	a4,a4,0x3f
ffffffffc02048e2:	8e9d                	sub	a3,a3,a5
ffffffffc02048e4:	00c6d793          	srli	a5,a3,0xc
ffffffffc02048e8:	f654                	sd	a3,168(a2)
ffffffffc02048ea:	8fd9                	or	a5,a5,a4
ffffffffc02048ec:	18079073          	csrw	satp,a5
    struct trapframe *tf = current->tf;
ffffffffc02048f0:	7240                	ld	s0,160(a2)
    memset(tf, 0, sizeof(struct trapframe));
ffffffffc02048f2:	4581                	li	a1,0
ffffffffc02048f4:	12000613          	li	a2,288
ffffffffc02048f8:	8522                	mv	a0,s0
    uintptr_t sstatus = tf->status;
ffffffffc02048fa:	10043483          	ld	s1,256(s0)
    memset(tf, 0, sizeof(struct trapframe));
ffffffffc02048fe:	727000ef          	jal	ra,ffffffffc0205824 <memset>
    tf->epc = (uintptr_t)elf->e_entry;
ffffffffc0204902:	7782                	ld	a5,32(sp)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204904:	000db903          	ld	s2,0(s11)
    tf->status = (sstatus & ~SSTATUS_SPP) | SSTATUS_SPIE;
ffffffffc0204908:	edf4f493          	andi	s1,s1,-289
    tf->epc = (uintptr_t)elf->e_entry;
ffffffffc020490c:	6f98                	ld	a4,24(a5)
    tf->gpr.sp = (uintptr_t)USTACKTOP;
ffffffffc020490e:	4785                	li	a5,1
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204910:	0b490913          	addi	s2,s2,180 # ffffffff800000b4 <_binary_obj___user_matrix_out_size+0xffffffff7fff3994>
    tf->gpr.sp = (uintptr_t)USTACKTOP;
ffffffffc0204914:	07fe                	slli	a5,a5,0x1f
    tf->status = (sstatus & ~SSTATUS_SPP) | SSTATUS_SPIE;
ffffffffc0204916:	0204e493          	ori	s1,s1,32
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc020491a:	4641                	li	a2,16
ffffffffc020491c:	4581                	li	a1,0
    tf->gpr.sp = (uintptr_t)USTACKTOP;
ffffffffc020491e:	e81c                	sd	a5,16(s0)
    tf->epc = (uintptr_t)elf->e_entry;
ffffffffc0204920:	10e43423          	sd	a4,264(s0)
    tf->gpr.a0 = 0;  // 把 SSTATUS_SPP 设置为0，使得 sret 的时候能回到 U mode
ffffffffc0204924:	04043823          	sd	zero,80(s0)
    tf->status = (sstatus & ~SSTATUS_SPP) | SSTATUS_SPIE;
ffffffffc0204928:	10943023          	sd	s1,256(s0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc020492c:	854a                	mv	a0,s2
ffffffffc020492e:	6f7000ef          	jal	ra,ffffffffc0205824 <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0204932:	463d                	li	a2,15
ffffffffc0204934:	180c                	addi	a1,sp,48
ffffffffc0204936:	854a                	mv	a0,s2
ffffffffc0204938:	6ff000ef          	jal	ra,ffffffffc0205836 <memcpy>
}
ffffffffc020493c:	70aa                	ld	ra,168(sp)
ffffffffc020493e:	740a                	ld	s0,160(sp)
ffffffffc0204940:	64ea                	ld	s1,152(sp)
ffffffffc0204942:	694a                	ld	s2,144(sp)
ffffffffc0204944:	69aa                	ld	s3,136(sp)
ffffffffc0204946:	7ae6                	ld	s5,120(sp)
ffffffffc0204948:	7b46                	ld	s6,112(sp)
ffffffffc020494a:	7ba6                	ld	s7,104(sp)
ffffffffc020494c:	7c06                	ld	s8,96(sp)
ffffffffc020494e:	6ce6                	ld	s9,88(sp)
ffffffffc0204950:	6d46                	ld	s10,80(sp)
ffffffffc0204952:	6da6                	ld	s11,72(sp)
ffffffffc0204954:	8552                	mv	a0,s4
ffffffffc0204956:	6a0a                	ld	s4,128(sp)
ffffffffc0204958:	614d                	addi	sp,sp,176
ffffffffc020495a:	8082                	ret
    memcpy(local_name, name, len);
ffffffffc020495c:	463d                	li	a2,15
ffffffffc020495e:	85ca                	mv	a1,s2
ffffffffc0204960:	1808                	addi	a0,sp,48
ffffffffc0204962:	6d5000ef          	jal	ra,ffffffffc0205836 <memcpy>
    if (mm != NULL)
ffffffffc0204966:	e0099fe3          	bnez	s3,ffffffffc0204784 <do_execve+0x62>
    if (current->mm != NULL)
ffffffffc020496a:	000db783          	ld	a5,0(s11)
ffffffffc020496e:	779c                	ld	a5,40(a5)
ffffffffc0204970:	e40786e3          	beqz	a5,ffffffffc02047bc <do_execve+0x9a>
        panic("load_icode: current->mm must be empty.\n");
ffffffffc0204974:	00003617          	auipc	a2,0x3
ffffffffc0204978:	8ec60613          	addi	a2,a2,-1812 # ffffffffc0207260 <default_pmm_manager+0xbd0>
ffffffffc020497c:	26200593          	li	a1,610
ffffffffc0204980:	00002517          	auipc	a0,0x2
ffffffffc0204984:	74050513          	addi	a0,a0,1856 # ffffffffc02070c0 <default_pmm_manager+0xa30>
ffffffffc0204988:	b0bfb0ef          	jal	ra,ffffffffc0200492 <__panic>
    put_pgdir(mm);
ffffffffc020498c:	8526                	mv	a0,s1
ffffffffc020498e:	c4aff0ef          	jal	ra,ffffffffc0203dd8 <put_pgdir>
    mm_destroy(mm);
ffffffffc0204992:	8526                	mv	a0,s1
ffffffffc0204994:	dbbfe0ef          	jal	ra,ffffffffc020374e <mm_destroy>
        ret = -E_INVAL_ELF;
ffffffffc0204998:	5a61                	li	s4,-8
    do_exit(ret);
ffffffffc020499a:	8552                	mv	a0,s4
ffffffffc020499c:	947ff0ef          	jal	ra,ffffffffc02042e2 <do_exit>
    int ret = -E_NO_MEM;
ffffffffc02049a0:	5a71                	li	s4,-4
ffffffffc02049a2:	bfe5                	j	ffffffffc020499a <do_execve+0x278>
        if (ph->p_filesz > ph->p_memsz)
ffffffffc02049a4:	0289b603          	ld	a2,40(s3)
ffffffffc02049a8:	0209b783          	ld	a5,32(s3)
ffffffffc02049ac:	1cf66d63          	bltu	a2,a5,ffffffffc0204b86 <do_execve+0x464>
        if (ph->p_flags & ELF_PF_X)
ffffffffc02049b0:	0049a783          	lw	a5,4(s3)
ffffffffc02049b4:	0017f693          	andi	a3,a5,1
ffffffffc02049b8:	c291                	beqz	a3,ffffffffc02049bc <do_execve+0x29a>
            vm_flags |= VM_EXEC;
ffffffffc02049ba:	4691                	li	a3,4
        if (ph->p_flags & ELF_PF_W)
ffffffffc02049bc:	0027f713          	andi	a4,a5,2
        if (ph->p_flags & ELF_PF_R)
ffffffffc02049c0:	8b91                	andi	a5,a5,4
        if (ph->p_flags & ELF_PF_W)
ffffffffc02049c2:	e779                	bnez	a4,ffffffffc0204a90 <do_execve+0x36e>
        vm_flags = 0, perm = PTE_U | PTE_V;
ffffffffc02049c4:	4d45                	li	s10,17
        if (ph->p_flags & ELF_PF_R)
ffffffffc02049c6:	c781                	beqz	a5,ffffffffc02049ce <do_execve+0x2ac>
            vm_flags |= VM_READ;
ffffffffc02049c8:	0016e693          	ori	a3,a3,1
            perm |= PTE_R;
ffffffffc02049cc:	4d4d                	li	s10,19
        if (vm_flags & VM_WRITE)
ffffffffc02049ce:	0026f793          	andi	a5,a3,2
ffffffffc02049d2:	e3f1                	bnez	a5,ffffffffc0204a96 <do_execve+0x374>
        if (vm_flags & VM_EXEC)
ffffffffc02049d4:	0046f793          	andi	a5,a3,4
ffffffffc02049d8:	c399                	beqz	a5,ffffffffc02049de <do_execve+0x2bc>
            perm |= PTE_X;
ffffffffc02049da:	008d6d13          	ori	s10,s10,8
        if ((ret = mm_map(mm, ph->p_va, ph->p_memsz, vm_flags, NULL)) != 0)
ffffffffc02049de:	0109b583          	ld	a1,16(s3)
ffffffffc02049e2:	4701                	li	a4,0
ffffffffc02049e4:	8526                	mv	a0,s1
ffffffffc02049e6:	dbbfe0ef          	jal	ra,ffffffffc02037a0 <mm_map>
ffffffffc02049ea:	8a2a                	mv	s4,a0
ffffffffc02049ec:	ed35                	bnez	a0,ffffffffc0204a68 <do_execve+0x346>
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc02049ee:	0109bb83          	ld	s7,16(s3)
ffffffffc02049f2:	77fd                	lui	a5,0xfffff
        end = ph->p_va + ph->p_filesz;
ffffffffc02049f4:	0209ba03          	ld	s4,32(s3)
        unsigned char *from = binary + ph->p_offset;
ffffffffc02049f8:	0089b903          	ld	s2,8(s3)
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc02049fc:	00fbfab3          	and	s5,s7,a5
        unsigned char *from = binary + ph->p_offset;
ffffffffc0204a00:	7782                	ld	a5,32(sp)
        end = ph->p_va + ph->p_filesz;
ffffffffc0204a02:	9a5e                	add	s4,s4,s7
        unsigned char *from = binary + ph->p_offset;
ffffffffc0204a04:	993e                	add	s2,s2,a5
        while (start < end)
ffffffffc0204a06:	054be963          	bltu	s7,s4,ffffffffc0204a58 <do_execve+0x336>
ffffffffc0204a0a:	aa95                	j	ffffffffc0204b7e <do_execve+0x45c>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0204a0c:	6785                	lui	a5,0x1
ffffffffc0204a0e:	415b8533          	sub	a0,s7,s5
ffffffffc0204a12:	9abe                	add	s5,s5,a5
ffffffffc0204a14:	417a8633          	sub	a2,s5,s7
            if (end < la)
ffffffffc0204a18:	015a7463          	bgeu	s4,s5,ffffffffc0204a20 <do_execve+0x2fe>
                size -= la - end;
ffffffffc0204a1c:	417a0633          	sub	a2,s4,s7
    return page - pages + nbase;
ffffffffc0204a20:	000cb683          	ld	a3,0(s9)
ffffffffc0204a24:	67c2                	ld	a5,16(sp)
    return KADDR(page2pa(page));
ffffffffc0204a26:	000c3583          	ld	a1,0(s8)
    return page - pages + nbase;
ffffffffc0204a2a:	40d406b3          	sub	a3,s0,a3
ffffffffc0204a2e:	8699                	srai	a3,a3,0x6
ffffffffc0204a30:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0204a32:	67e2                	ld	a5,24(sp)
ffffffffc0204a34:	00f6f833          	and	a6,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0204a38:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204a3a:	14b87863          	bgeu	a6,a1,ffffffffc0204b8a <do_execve+0x468>
ffffffffc0204a3e:	000b3803          	ld	a6,0(s6)
            memcpy(page2kva(page) + off, from, size);
ffffffffc0204a42:	85ca                	mv	a1,s2
            start += size, from += size;
ffffffffc0204a44:	9bb2                	add	s7,s7,a2
ffffffffc0204a46:	96c2                	add	a3,a3,a6
            memcpy(page2kva(page) + off, from, size);
ffffffffc0204a48:	9536                	add	a0,a0,a3
            start += size, from += size;
ffffffffc0204a4a:	e432                	sd	a2,8(sp)
            memcpy(page2kva(page) + off, from, size);
ffffffffc0204a4c:	5eb000ef          	jal	ra,ffffffffc0205836 <memcpy>
            start += size, from += size;
ffffffffc0204a50:	6622                	ld	a2,8(sp)
ffffffffc0204a52:	9932                	add	s2,s2,a2
        while (start < end)
ffffffffc0204a54:	054bf363          	bgeu	s7,s4,ffffffffc0204a9a <do_execve+0x378>
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL)
ffffffffc0204a58:	6c88                	ld	a0,24(s1)
ffffffffc0204a5a:	866a                	mv	a2,s10
ffffffffc0204a5c:	85d6                	mv	a1,s5
ffffffffc0204a5e:	acbfe0ef          	jal	ra,ffffffffc0203528 <pgdir_alloc_page>
ffffffffc0204a62:	842a                	mv	s0,a0
ffffffffc0204a64:	f545                	bnez	a0,ffffffffc0204a0c <do_execve+0x2ea>
        ret = -E_NO_MEM;
ffffffffc0204a66:	5a71                	li	s4,-4
    exit_mmap(mm);
ffffffffc0204a68:	8526                	mv	a0,s1
ffffffffc0204a6a:	e81fe0ef          	jal	ra,ffffffffc02038ea <exit_mmap>
    put_pgdir(mm);
ffffffffc0204a6e:	8526                	mv	a0,s1
ffffffffc0204a70:	b68ff0ef          	jal	ra,ffffffffc0203dd8 <put_pgdir>
    mm_destroy(mm);
ffffffffc0204a74:	8526                	mv	a0,s1
ffffffffc0204a76:	cd9fe0ef          	jal	ra,ffffffffc020374e <mm_destroy>
    return ret;
ffffffffc0204a7a:	b705                	j	ffffffffc020499a <do_execve+0x278>
            exit_mmap(mm);
ffffffffc0204a7c:	854e                	mv	a0,s3
ffffffffc0204a7e:	e6dfe0ef          	jal	ra,ffffffffc02038ea <exit_mmap>
            put_pgdir(mm);
ffffffffc0204a82:	854e                	mv	a0,s3
ffffffffc0204a84:	b54ff0ef          	jal	ra,ffffffffc0203dd8 <put_pgdir>
            mm_destroy(mm);
ffffffffc0204a88:	854e                	mv	a0,s3
ffffffffc0204a8a:	cc5fe0ef          	jal	ra,ffffffffc020374e <mm_destroy>
ffffffffc0204a8e:	b31d                	j	ffffffffc02047b4 <do_execve+0x92>
            vm_flags |= VM_WRITE;
ffffffffc0204a90:	0026e693          	ori	a3,a3,2
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204a94:	fb95                	bnez	a5,ffffffffc02049c8 <do_execve+0x2a6>
            perm |= (PTE_W | PTE_R);
ffffffffc0204a96:	4d5d                	li	s10,23
ffffffffc0204a98:	bf35                	j	ffffffffc02049d4 <do_execve+0x2b2>
        end = ph->p_va + ph->p_memsz;
ffffffffc0204a9a:	0109b683          	ld	a3,16(s3)
ffffffffc0204a9e:	0289b903          	ld	s2,40(s3)
ffffffffc0204aa2:	9936                	add	s2,s2,a3
        if (start < la)
ffffffffc0204aa4:	075bfd63          	bgeu	s7,s5,ffffffffc0204b1e <do_execve+0x3fc>
            if (start == end)
ffffffffc0204aa8:	db790de3          	beq	s2,s7,ffffffffc0204862 <do_execve+0x140>
            off = start + PGSIZE - la, size = PGSIZE - off;
ffffffffc0204aac:	6785                	lui	a5,0x1
ffffffffc0204aae:	00fb8533          	add	a0,s7,a5
ffffffffc0204ab2:	41550533          	sub	a0,a0,s5
                size -= la - end;
ffffffffc0204ab6:	41790a33          	sub	s4,s2,s7
            if (end < la)
ffffffffc0204aba:	0b597d63          	bgeu	s2,s5,ffffffffc0204b74 <do_execve+0x452>
    return page - pages + nbase;
ffffffffc0204abe:	000cb683          	ld	a3,0(s9)
ffffffffc0204ac2:	67c2                	ld	a5,16(sp)
    return KADDR(page2pa(page));
ffffffffc0204ac4:	000c3603          	ld	a2,0(s8)
    return page - pages + nbase;
ffffffffc0204ac8:	40d406b3          	sub	a3,s0,a3
ffffffffc0204acc:	8699                	srai	a3,a3,0x6
ffffffffc0204ace:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0204ad0:	67e2                	ld	a5,24(sp)
ffffffffc0204ad2:	00f6f5b3          	and	a1,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0204ad6:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204ad8:	0ac5f963          	bgeu	a1,a2,ffffffffc0204b8a <do_execve+0x468>
ffffffffc0204adc:	000b3803          	ld	a6,0(s6)
            memset(page2kva(page) + off, 0, size);
ffffffffc0204ae0:	8652                	mv	a2,s4
ffffffffc0204ae2:	4581                	li	a1,0
ffffffffc0204ae4:	96c2                	add	a3,a3,a6
ffffffffc0204ae6:	9536                	add	a0,a0,a3
ffffffffc0204ae8:	53d000ef          	jal	ra,ffffffffc0205824 <memset>
            start += size;
ffffffffc0204aec:	017a0733          	add	a4,s4,s7
            assert((end < la && start == end) || (end >= la && start == la));
ffffffffc0204af0:	03597463          	bgeu	s2,s5,ffffffffc0204b18 <do_execve+0x3f6>
ffffffffc0204af4:	d6e907e3          	beq	s2,a4,ffffffffc0204862 <do_execve+0x140>
ffffffffc0204af8:	00002697          	auipc	a3,0x2
ffffffffc0204afc:	79068693          	addi	a3,a3,1936 # ffffffffc0207288 <default_pmm_manager+0xbf8>
ffffffffc0204b00:	00001617          	auipc	a2,0x1
ffffffffc0204b04:	7e060613          	addi	a2,a2,2016 # ffffffffc02062e0 <commands+0x828>
ffffffffc0204b08:	2cb00593          	li	a1,715
ffffffffc0204b0c:	00002517          	auipc	a0,0x2
ffffffffc0204b10:	5b450513          	addi	a0,a0,1460 # ffffffffc02070c0 <default_pmm_manager+0xa30>
ffffffffc0204b14:	97ffb0ef          	jal	ra,ffffffffc0200492 <__panic>
ffffffffc0204b18:	ff5710e3          	bne	a4,s5,ffffffffc0204af8 <do_execve+0x3d6>
ffffffffc0204b1c:	8bd6                	mv	s7,s5
        while (start < end)
ffffffffc0204b1e:	d52bf2e3          	bgeu	s7,s2,ffffffffc0204862 <do_execve+0x140>
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL)
ffffffffc0204b22:	6c88                	ld	a0,24(s1)
ffffffffc0204b24:	866a                	mv	a2,s10
ffffffffc0204b26:	85d6                	mv	a1,s5
ffffffffc0204b28:	a01fe0ef          	jal	ra,ffffffffc0203528 <pgdir_alloc_page>
ffffffffc0204b2c:	842a                	mv	s0,a0
ffffffffc0204b2e:	dd05                	beqz	a0,ffffffffc0204a66 <do_execve+0x344>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0204b30:	6785                	lui	a5,0x1
ffffffffc0204b32:	415b8533          	sub	a0,s7,s5
ffffffffc0204b36:	9abe                	add	s5,s5,a5
ffffffffc0204b38:	417a8633          	sub	a2,s5,s7
            if (end < la)
ffffffffc0204b3c:	01597463          	bgeu	s2,s5,ffffffffc0204b44 <do_execve+0x422>
                size -= la - end;
ffffffffc0204b40:	41790633          	sub	a2,s2,s7
    return page - pages + nbase;
ffffffffc0204b44:	000cb683          	ld	a3,0(s9)
ffffffffc0204b48:	67c2                	ld	a5,16(sp)
    return KADDR(page2pa(page));
ffffffffc0204b4a:	000c3583          	ld	a1,0(s8)
    return page - pages + nbase;
ffffffffc0204b4e:	40d406b3          	sub	a3,s0,a3
ffffffffc0204b52:	8699                	srai	a3,a3,0x6
ffffffffc0204b54:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0204b56:	67e2                	ld	a5,24(sp)
ffffffffc0204b58:	00f6f833          	and	a6,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0204b5c:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204b5e:	02b87663          	bgeu	a6,a1,ffffffffc0204b8a <do_execve+0x468>
ffffffffc0204b62:	000b3803          	ld	a6,0(s6)
            memset(page2kva(page) + off, 0, size);
ffffffffc0204b66:	4581                	li	a1,0
            start += size;
ffffffffc0204b68:	9bb2                	add	s7,s7,a2
ffffffffc0204b6a:	96c2                	add	a3,a3,a6
            memset(page2kva(page) + off, 0, size);
ffffffffc0204b6c:	9536                	add	a0,a0,a3
ffffffffc0204b6e:	4b7000ef          	jal	ra,ffffffffc0205824 <memset>
ffffffffc0204b72:	b775                	j	ffffffffc0204b1e <do_execve+0x3fc>
            off = start + PGSIZE - la, size = PGSIZE - off;
ffffffffc0204b74:	417a8a33          	sub	s4,s5,s7
ffffffffc0204b78:	b799                	j	ffffffffc0204abe <do_execve+0x39c>
        return -E_INVAL;
ffffffffc0204b7a:	5a75                	li	s4,-3
ffffffffc0204b7c:	b3c1                	j	ffffffffc020493c <do_execve+0x21a>
        while (start < end)
ffffffffc0204b7e:	86de                	mv	a3,s7
ffffffffc0204b80:	bf39                	j	ffffffffc0204a9e <do_execve+0x37c>
    int ret = -E_NO_MEM;
ffffffffc0204b82:	5a71                	li	s4,-4
ffffffffc0204b84:	bdc5                	j	ffffffffc0204a74 <do_execve+0x352>
            ret = -E_INVAL_ELF;
ffffffffc0204b86:	5a61                	li	s4,-8
ffffffffc0204b88:	b5c5                	j	ffffffffc0204a68 <do_execve+0x346>
ffffffffc0204b8a:	00002617          	auipc	a2,0x2
ffffffffc0204b8e:	b3e60613          	addi	a2,a2,-1218 # ffffffffc02066c8 <default_pmm_manager+0x38>
ffffffffc0204b92:	07100593          	li	a1,113
ffffffffc0204b96:	00002517          	auipc	a0,0x2
ffffffffc0204b9a:	b5a50513          	addi	a0,a0,-1190 # ffffffffc02066f0 <default_pmm_manager+0x60>
ffffffffc0204b9e:	8f5fb0ef          	jal	ra,ffffffffc0200492 <__panic>
    current->pgdir = PADDR(mm->pgdir);
ffffffffc0204ba2:	00002617          	auipc	a2,0x2
ffffffffc0204ba6:	bce60613          	addi	a2,a2,-1074 # ffffffffc0206770 <default_pmm_manager+0xe0>
ffffffffc0204baa:	2ea00593          	li	a1,746
ffffffffc0204bae:	00002517          	auipc	a0,0x2
ffffffffc0204bb2:	51250513          	addi	a0,a0,1298 # ffffffffc02070c0 <default_pmm_manager+0xa30>
ffffffffc0204bb6:	8ddfb0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 4 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204bba:	00002697          	auipc	a3,0x2
ffffffffc0204bbe:	7e668693          	addi	a3,a3,2022 # ffffffffc02073a0 <default_pmm_manager+0xd10>
ffffffffc0204bc2:	00001617          	auipc	a2,0x1
ffffffffc0204bc6:	71e60613          	addi	a2,a2,1822 # ffffffffc02062e0 <commands+0x828>
ffffffffc0204bca:	2e500593          	li	a1,741
ffffffffc0204bce:	00002517          	auipc	a0,0x2
ffffffffc0204bd2:	4f250513          	addi	a0,a0,1266 # ffffffffc02070c0 <default_pmm_manager+0xa30>
ffffffffc0204bd6:	8bdfb0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 3 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204bda:	00002697          	auipc	a3,0x2
ffffffffc0204bde:	77e68693          	addi	a3,a3,1918 # ffffffffc0207358 <default_pmm_manager+0xcc8>
ffffffffc0204be2:	00001617          	auipc	a2,0x1
ffffffffc0204be6:	6fe60613          	addi	a2,a2,1790 # ffffffffc02062e0 <commands+0x828>
ffffffffc0204bea:	2e400593          	li	a1,740
ffffffffc0204bee:	00002517          	auipc	a0,0x2
ffffffffc0204bf2:	4d250513          	addi	a0,a0,1234 # ffffffffc02070c0 <default_pmm_manager+0xa30>
ffffffffc0204bf6:	89dfb0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 2 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204bfa:	00002697          	auipc	a3,0x2
ffffffffc0204bfe:	71668693          	addi	a3,a3,1814 # ffffffffc0207310 <default_pmm_manager+0xc80>
ffffffffc0204c02:	00001617          	auipc	a2,0x1
ffffffffc0204c06:	6de60613          	addi	a2,a2,1758 # ffffffffc02062e0 <commands+0x828>
ffffffffc0204c0a:	2e300593          	li	a1,739
ffffffffc0204c0e:	00002517          	auipc	a0,0x2
ffffffffc0204c12:	4b250513          	addi	a0,a0,1202 # ffffffffc02070c0 <default_pmm_manager+0xa30>
ffffffffc0204c16:	87dfb0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - PGSIZE, PTE_USER) != NULL);
ffffffffc0204c1a:	00002697          	auipc	a3,0x2
ffffffffc0204c1e:	6ae68693          	addi	a3,a3,1710 # ffffffffc02072c8 <default_pmm_manager+0xc38>
ffffffffc0204c22:	00001617          	auipc	a2,0x1
ffffffffc0204c26:	6be60613          	addi	a2,a2,1726 # ffffffffc02062e0 <commands+0x828>
ffffffffc0204c2a:	2e200593          	li	a1,738
ffffffffc0204c2e:	00002517          	auipc	a0,0x2
ffffffffc0204c32:	49250513          	addi	a0,a0,1170 # ffffffffc02070c0 <default_pmm_manager+0xa30>
ffffffffc0204c36:	85dfb0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0204c3a <user_main>:
{
ffffffffc0204c3a:	1101                	addi	sp,sp,-32
ffffffffc0204c3c:	e04a                	sd	s2,0(sp)
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc0204c3e:	000c2917          	auipc	s2,0xc2
ffffffffc0204c42:	09a90913          	addi	s2,s2,154 # ffffffffc02c6cd8 <current>
ffffffffc0204c46:	00093783          	ld	a5,0(s2)
ffffffffc0204c4a:	00002617          	auipc	a2,0x2
ffffffffc0204c4e:	79e60613          	addi	a2,a2,1950 # ffffffffc02073e8 <default_pmm_manager+0xd58>
ffffffffc0204c52:	00002517          	auipc	a0,0x2
ffffffffc0204c56:	7a650513          	addi	a0,a0,1958 # ffffffffc02073f8 <default_pmm_manager+0xd68>
ffffffffc0204c5a:	43cc                	lw	a1,4(a5)
{
ffffffffc0204c5c:	ec06                	sd	ra,24(sp)
ffffffffc0204c5e:	e822                	sd	s0,16(sp)
ffffffffc0204c60:	e426                	sd	s1,8(sp)
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc0204c62:	d36fb0ef          	jal	ra,ffffffffc0200198 <cprintf>
    size_t len = strlen(name);
ffffffffc0204c66:	00002517          	auipc	a0,0x2
ffffffffc0204c6a:	78250513          	addi	a0,a0,1922 # ffffffffc02073e8 <default_pmm_manager+0xd58>
ffffffffc0204c6e:	315000ef          	jal	ra,ffffffffc0205782 <strlen>
    struct trapframe *old_tf = current->tf;
ffffffffc0204c72:	00093783          	ld	a5,0(s2)
    size_t len = strlen(name);
ffffffffc0204c76:	84aa                	mv	s1,a0
    memcpy(new_tf, old_tf, sizeof(struct trapframe));
ffffffffc0204c78:	12000613          	li	a2,288
    struct trapframe *new_tf = (struct trapframe *)(current->kstack + KSTACKSIZE - sizeof(struct trapframe));
ffffffffc0204c7c:	6b80                	ld	s0,16(a5)
    memcpy(new_tf, old_tf, sizeof(struct trapframe));
ffffffffc0204c7e:	73cc                	ld	a1,160(a5)
    struct trapframe *new_tf = (struct trapframe *)(current->kstack + KSTACKSIZE - sizeof(struct trapframe));
ffffffffc0204c80:	6789                	lui	a5,0x2
ffffffffc0204c82:	ee078793          	addi	a5,a5,-288 # 1ee0 <_binary_obj___user_faultread_out_size-0x8068>
ffffffffc0204c86:	943e                	add	s0,s0,a5
    memcpy(new_tf, old_tf, sizeof(struct trapframe));
ffffffffc0204c88:	8522                	mv	a0,s0
ffffffffc0204c8a:	3ad000ef          	jal	ra,ffffffffc0205836 <memcpy>
    current->tf = new_tf;
ffffffffc0204c8e:	00093783          	ld	a5,0(s2)
    ret = do_execve(name, len, binary, size);
ffffffffc0204c92:	3fe07697          	auipc	a3,0x3fe07
ffffffffc0204c96:	abe68693          	addi	a3,a3,-1346 # b750 <_binary_obj___user_priority_out_size>
ffffffffc0204c9a:	0007d617          	auipc	a2,0x7d
ffffffffc0204c9e:	11e60613          	addi	a2,a2,286 # ffffffffc0281db8 <_binary_obj___user_priority_out_start>
    current->tf = new_tf;
ffffffffc0204ca2:	f3c0                	sd	s0,160(a5)
    ret = do_execve(name, len, binary, size);
ffffffffc0204ca4:	85a6                	mv	a1,s1
ffffffffc0204ca6:	00002517          	auipc	a0,0x2
ffffffffc0204caa:	74250513          	addi	a0,a0,1858 # ffffffffc02073e8 <default_pmm_manager+0xd58>
ffffffffc0204cae:	a75ff0ef          	jal	ra,ffffffffc0204722 <do_execve>
    asm volatile(
ffffffffc0204cb2:	8122                	mv	sp,s0
ffffffffc0204cb4:	9f8fc06f          	j	ffffffffc0200eac <__trapret>
    panic("user_main execve failed.\n");
ffffffffc0204cb8:	00002617          	auipc	a2,0x2
ffffffffc0204cbc:	76860613          	addi	a2,a2,1896 # ffffffffc0207420 <default_pmm_manager+0xd90>
ffffffffc0204cc0:	3d500593          	li	a1,981
ffffffffc0204cc4:	00002517          	auipc	a0,0x2
ffffffffc0204cc8:	3fc50513          	addi	a0,a0,1020 # ffffffffc02070c0 <default_pmm_manager+0xa30>
ffffffffc0204ccc:	fc6fb0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0204cd0 <do_yield>:
    current->need_resched = 1;
ffffffffc0204cd0:	000c2797          	auipc	a5,0xc2
ffffffffc0204cd4:	0087b783          	ld	a5,8(a5) # ffffffffc02c6cd8 <current>
ffffffffc0204cd8:	4705                	li	a4,1
ffffffffc0204cda:	ef98                	sd	a4,24(a5)
}
ffffffffc0204cdc:	4501                	li	a0,0
ffffffffc0204cde:	8082                	ret

ffffffffc0204ce0 <do_wait>:
{
ffffffffc0204ce0:	1101                	addi	sp,sp,-32
ffffffffc0204ce2:	e822                	sd	s0,16(sp)
ffffffffc0204ce4:	e426                	sd	s1,8(sp)
ffffffffc0204ce6:	ec06                	sd	ra,24(sp)
ffffffffc0204ce8:	842e                	mv	s0,a1
ffffffffc0204cea:	84aa                	mv	s1,a0
    if (code_store != NULL)
ffffffffc0204cec:	c999                	beqz	a1,ffffffffc0204d02 <do_wait+0x22>
    struct mm_struct *mm = current->mm;
ffffffffc0204cee:	000c2797          	auipc	a5,0xc2
ffffffffc0204cf2:	fea7b783          	ld	a5,-22(a5) # ffffffffc02c6cd8 <current>
        if (!user_mem_check(mm, (uintptr_t)code_store, sizeof(int), 1))
ffffffffc0204cf6:	7788                	ld	a0,40(a5)
ffffffffc0204cf8:	4685                	li	a3,1
ffffffffc0204cfa:	4611                	li	a2,4
ffffffffc0204cfc:	f89fe0ef          	jal	ra,ffffffffc0203c84 <user_mem_check>
ffffffffc0204d00:	c909                	beqz	a0,ffffffffc0204d12 <do_wait+0x32>
ffffffffc0204d02:	85a2                	mv	a1,s0
}
ffffffffc0204d04:	6442                	ld	s0,16(sp)
ffffffffc0204d06:	60e2                	ld	ra,24(sp)
ffffffffc0204d08:	8526                	mv	a0,s1
ffffffffc0204d0a:	64a2                	ld	s1,8(sp)
ffffffffc0204d0c:	6105                	addi	sp,sp,32
ffffffffc0204d0e:	f1eff06f          	j	ffffffffc020442c <do_wait.part.0>
ffffffffc0204d12:	60e2                	ld	ra,24(sp)
ffffffffc0204d14:	6442                	ld	s0,16(sp)
ffffffffc0204d16:	64a2                	ld	s1,8(sp)
ffffffffc0204d18:	5575                	li	a0,-3
ffffffffc0204d1a:	6105                	addi	sp,sp,32
ffffffffc0204d1c:	8082                	ret

ffffffffc0204d1e <do_kill>:
{
ffffffffc0204d1e:	1141                	addi	sp,sp,-16
    if (0 < pid && pid < MAX_PID)
ffffffffc0204d20:	6789                	lui	a5,0x2
{
ffffffffc0204d22:	e406                	sd	ra,8(sp)
ffffffffc0204d24:	e022                	sd	s0,0(sp)
    if (0 < pid && pid < MAX_PID)
ffffffffc0204d26:	fff5071b          	addiw	a4,a0,-1
ffffffffc0204d2a:	17f9                	addi	a5,a5,-2
ffffffffc0204d2c:	02e7e963          	bltu	a5,a4,ffffffffc0204d5e <do_kill+0x40>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204d30:	842a                	mv	s0,a0
ffffffffc0204d32:	45a9                	li	a1,10
ffffffffc0204d34:	2501                	sext.w	a0,a0
ffffffffc0204d36:	648000ef          	jal	ra,ffffffffc020537e <hash32>
ffffffffc0204d3a:	02051793          	slli	a5,a0,0x20
ffffffffc0204d3e:	01c7d513          	srli	a0,a5,0x1c
ffffffffc0204d42:	000be797          	auipc	a5,0xbe
ffffffffc0204d46:	ef678793          	addi	a5,a5,-266 # ffffffffc02c2c38 <hash_list>
ffffffffc0204d4a:	953e                	add	a0,a0,a5
ffffffffc0204d4c:	87aa                	mv	a5,a0
        while ((le = list_next(le)) != list)
ffffffffc0204d4e:	a029                	j	ffffffffc0204d58 <do_kill+0x3a>
            if (proc->pid == pid)
ffffffffc0204d50:	f2c7a703          	lw	a4,-212(a5)
ffffffffc0204d54:	00870b63          	beq	a4,s0,ffffffffc0204d6a <do_kill+0x4c>
ffffffffc0204d58:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc0204d5a:	fef51be3          	bne	a0,a5,ffffffffc0204d50 <do_kill+0x32>
    return -E_INVAL;
ffffffffc0204d5e:	5475                	li	s0,-3
}
ffffffffc0204d60:	60a2                	ld	ra,8(sp)
ffffffffc0204d62:	8522                	mv	a0,s0
ffffffffc0204d64:	6402                	ld	s0,0(sp)
ffffffffc0204d66:	0141                	addi	sp,sp,16
ffffffffc0204d68:	8082                	ret
        if (!(proc->flags & PF_EXITING))
ffffffffc0204d6a:	fd87a703          	lw	a4,-40(a5)
ffffffffc0204d6e:	00177693          	andi	a3,a4,1
ffffffffc0204d72:	e295                	bnez	a3,ffffffffc0204d96 <do_kill+0x78>
            if (proc->wait_state & WT_INTERRUPTED)
ffffffffc0204d74:	4bd4                	lw	a3,20(a5)
            proc->flags |= PF_EXITING;
ffffffffc0204d76:	00176713          	ori	a4,a4,1
ffffffffc0204d7a:	fce7ac23          	sw	a4,-40(a5)
            return 0;
ffffffffc0204d7e:	4401                	li	s0,0
            if (proc->wait_state & WT_INTERRUPTED)
ffffffffc0204d80:	fe06d0e3          	bgez	a3,ffffffffc0204d60 <do_kill+0x42>
                wakeup_proc(proc);
ffffffffc0204d84:	f2878513          	addi	a0,a5,-216
ffffffffc0204d88:	384000ef          	jal	ra,ffffffffc020510c <wakeup_proc>
}
ffffffffc0204d8c:	60a2                	ld	ra,8(sp)
ffffffffc0204d8e:	8522                	mv	a0,s0
ffffffffc0204d90:	6402                	ld	s0,0(sp)
ffffffffc0204d92:	0141                	addi	sp,sp,16
ffffffffc0204d94:	8082                	ret
        return -E_KILLED;
ffffffffc0204d96:	545d                	li	s0,-9
ffffffffc0204d98:	b7e1                	j	ffffffffc0204d60 <do_kill+0x42>

ffffffffc0204d9a <proc_init>:

// proc_init - set up the first kernel thread idleproc "idle" by itself and
//           - create the second kernel thread init_main
void proc_init(void)
{
ffffffffc0204d9a:	1101                	addi	sp,sp,-32
ffffffffc0204d9c:	e426                	sd	s1,8(sp)
    elm->prev = elm->next = elm;
ffffffffc0204d9e:	000c2797          	auipc	a5,0xc2
ffffffffc0204da2:	e9a78793          	addi	a5,a5,-358 # ffffffffc02c6c38 <proc_list>
ffffffffc0204da6:	ec06                	sd	ra,24(sp)
ffffffffc0204da8:	e822                	sd	s0,16(sp)
ffffffffc0204daa:	e04a                	sd	s2,0(sp)
ffffffffc0204dac:	000be497          	auipc	s1,0xbe
ffffffffc0204db0:	e8c48493          	addi	s1,s1,-372 # ffffffffc02c2c38 <hash_list>
ffffffffc0204db4:	e79c                	sd	a5,8(a5)
ffffffffc0204db6:	e39c                	sd	a5,0(a5)
    int i;

    list_init(&proc_list);
    for (i = 0; i < HASH_LIST_SIZE; i++)
ffffffffc0204db8:	000c2717          	auipc	a4,0xc2
ffffffffc0204dbc:	e8070713          	addi	a4,a4,-384 # ffffffffc02c6c38 <proc_list>
ffffffffc0204dc0:	87a6                	mv	a5,s1
ffffffffc0204dc2:	e79c                	sd	a5,8(a5)
ffffffffc0204dc4:	e39c                	sd	a5,0(a5)
ffffffffc0204dc6:	07c1                	addi	a5,a5,16
ffffffffc0204dc8:	fef71de3          	bne	a4,a5,ffffffffc0204dc2 <proc_init+0x28>
    {
        list_init(hash_list + i);
    }

    if ((idleproc = alloc_proc()) == NULL)
ffffffffc0204dcc:	f55fe0ef          	jal	ra,ffffffffc0203d20 <alloc_proc>
ffffffffc0204dd0:	000c2917          	auipc	s2,0xc2
ffffffffc0204dd4:	f1090913          	addi	s2,s2,-240 # ffffffffc02c6ce0 <idleproc>
ffffffffc0204dd8:	00a93023          	sd	a0,0(s2)
ffffffffc0204ddc:	0e050f63          	beqz	a0,ffffffffc0204eda <proc_init+0x140>
    {
        panic("cannot alloc idleproc.\n");
    }

    idleproc->pid = 0;
    idleproc->state = PROC_RUNNABLE;
ffffffffc0204de0:	4789                	li	a5,2
ffffffffc0204de2:	e11c                	sd	a5,0(a0)
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc0204de4:	00004797          	auipc	a5,0x4
ffffffffc0204de8:	21c78793          	addi	a5,a5,540 # ffffffffc0209000 <bootstack>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204dec:	0b450413          	addi	s0,a0,180
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc0204df0:	e91c                	sd	a5,16(a0)
    idleproc->need_resched = 1;
ffffffffc0204df2:	4785                	li	a5,1
ffffffffc0204df4:	ed1c                	sd	a5,24(a0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204df6:	4641                	li	a2,16
ffffffffc0204df8:	4581                	li	a1,0
ffffffffc0204dfa:	8522                	mv	a0,s0
ffffffffc0204dfc:	229000ef          	jal	ra,ffffffffc0205824 <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0204e00:	463d                	li	a2,15
ffffffffc0204e02:	00002597          	auipc	a1,0x2
ffffffffc0204e06:	65658593          	addi	a1,a1,1622 # ffffffffc0207458 <default_pmm_manager+0xdc8>
ffffffffc0204e0a:	8522                	mv	a0,s0
ffffffffc0204e0c:	22b000ef          	jal	ra,ffffffffc0205836 <memcpy>
    set_proc_name(idleproc, "idle");
    nr_process++;
ffffffffc0204e10:	000c2717          	auipc	a4,0xc2
ffffffffc0204e14:	ee070713          	addi	a4,a4,-288 # ffffffffc02c6cf0 <nr_process>
ffffffffc0204e18:	431c                	lw	a5,0(a4)

    current = idleproc;
ffffffffc0204e1a:	00093683          	ld	a3,0(s2)

    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0204e1e:	4601                	li	a2,0
    nr_process++;
ffffffffc0204e20:	2785                	addiw	a5,a5,1
    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0204e22:	4581                	li	a1,0
ffffffffc0204e24:	fffff517          	auipc	a0,0xfffff
ffffffffc0204e28:	7da50513          	addi	a0,a0,2010 # ffffffffc02045fe <init_main>
    nr_process++;
ffffffffc0204e2c:	c31c                	sw	a5,0(a4)
    current = idleproc;
ffffffffc0204e2e:	000c2797          	auipc	a5,0xc2
ffffffffc0204e32:	ead7b523          	sd	a3,-342(a5) # ffffffffc02c6cd8 <current>
    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0204e36:	c5cff0ef          	jal	ra,ffffffffc0204292 <kernel_thread>
ffffffffc0204e3a:	842a                	mv	s0,a0
    if (pid <= 0)
ffffffffc0204e3c:	08a05363          	blez	a0,ffffffffc0204ec2 <proc_init+0x128>
    if (0 < pid && pid < MAX_PID)
ffffffffc0204e40:	6789                	lui	a5,0x2
ffffffffc0204e42:	fff5071b          	addiw	a4,a0,-1
ffffffffc0204e46:	17f9                	addi	a5,a5,-2
ffffffffc0204e48:	2501                	sext.w	a0,a0
ffffffffc0204e4a:	02e7e363          	bltu	a5,a4,ffffffffc0204e70 <proc_init+0xd6>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204e4e:	45a9                	li	a1,10
ffffffffc0204e50:	52e000ef          	jal	ra,ffffffffc020537e <hash32>
ffffffffc0204e54:	02051793          	slli	a5,a0,0x20
ffffffffc0204e58:	01c7d693          	srli	a3,a5,0x1c
ffffffffc0204e5c:	96a6                	add	a3,a3,s1
ffffffffc0204e5e:	87b6                	mv	a5,a3
        while ((le = list_next(le)) != list)
ffffffffc0204e60:	a029                	j	ffffffffc0204e6a <proc_init+0xd0>
            if (proc->pid == pid)
ffffffffc0204e62:	f2c7a703          	lw	a4,-212(a5) # 1f2c <_binary_obj___user_faultread_out_size-0x801c>
ffffffffc0204e66:	04870b63          	beq	a4,s0,ffffffffc0204ebc <proc_init+0x122>
    return listelm->next;
ffffffffc0204e6a:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc0204e6c:	fef69be3          	bne	a3,a5,ffffffffc0204e62 <proc_init+0xc8>
    return NULL;
ffffffffc0204e70:	4781                	li	a5,0
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204e72:	0b478493          	addi	s1,a5,180
ffffffffc0204e76:	4641                	li	a2,16
ffffffffc0204e78:	4581                	li	a1,0
    {
        panic("create init_main failed.\n");
    }

    initproc = find_proc(pid);
ffffffffc0204e7a:	000c2417          	auipc	s0,0xc2
ffffffffc0204e7e:	e6e40413          	addi	s0,s0,-402 # ffffffffc02c6ce8 <initproc>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204e82:	8526                	mv	a0,s1
    initproc = find_proc(pid);
ffffffffc0204e84:	e01c                	sd	a5,0(s0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204e86:	19f000ef          	jal	ra,ffffffffc0205824 <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0204e8a:	463d                	li	a2,15
ffffffffc0204e8c:	00002597          	auipc	a1,0x2
ffffffffc0204e90:	5f458593          	addi	a1,a1,1524 # ffffffffc0207480 <default_pmm_manager+0xdf0>
ffffffffc0204e94:	8526                	mv	a0,s1
ffffffffc0204e96:	1a1000ef          	jal	ra,ffffffffc0205836 <memcpy>
    set_proc_name(initproc, "init");

    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc0204e9a:	00093783          	ld	a5,0(s2)
ffffffffc0204e9e:	cbb5                	beqz	a5,ffffffffc0204f12 <proc_init+0x178>
ffffffffc0204ea0:	43dc                	lw	a5,4(a5)
ffffffffc0204ea2:	eba5                	bnez	a5,ffffffffc0204f12 <proc_init+0x178>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc0204ea4:	601c                	ld	a5,0(s0)
ffffffffc0204ea6:	c7b1                	beqz	a5,ffffffffc0204ef2 <proc_init+0x158>
ffffffffc0204ea8:	43d8                	lw	a4,4(a5)
ffffffffc0204eaa:	4785                	li	a5,1
ffffffffc0204eac:	04f71363          	bne	a4,a5,ffffffffc0204ef2 <proc_init+0x158>
}
ffffffffc0204eb0:	60e2                	ld	ra,24(sp)
ffffffffc0204eb2:	6442                	ld	s0,16(sp)
ffffffffc0204eb4:	64a2                	ld	s1,8(sp)
ffffffffc0204eb6:	6902                	ld	s2,0(sp)
ffffffffc0204eb8:	6105                	addi	sp,sp,32
ffffffffc0204eba:	8082                	ret
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc0204ebc:	f2878793          	addi	a5,a5,-216
ffffffffc0204ec0:	bf4d                	j	ffffffffc0204e72 <proc_init+0xd8>
        panic("create init_main failed.\n");
ffffffffc0204ec2:	00002617          	auipc	a2,0x2
ffffffffc0204ec6:	59e60613          	addi	a2,a2,1438 # ffffffffc0207460 <default_pmm_manager+0xdd0>
ffffffffc0204eca:	41100593          	li	a1,1041
ffffffffc0204ece:	00002517          	auipc	a0,0x2
ffffffffc0204ed2:	1f250513          	addi	a0,a0,498 # ffffffffc02070c0 <default_pmm_manager+0xa30>
ffffffffc0204ed6:	dbcfb0ef          	jal	ra,ffffffffc0200492 <__panic>
        panic("cannot alloc idleproc.\n");
ffffffffc0204eda:	00002617          	auipc	a2,0x2
ffffffffc0204ede:	56660613          	addi	a2,a2,1382 # ffffffffc0207440 <default_pmm_manager+0xdb0>
ffffffffc0204ee2:	40200593          	li	a1,1026
ffffffffc0204ee6:	00002517          	auipc	a0,0x2
ffffffffc0204eea:	1da50513          	addi	a0,a0,474 # ffffffffc02070c0 <default_pmm_manager+0xa30>
ffffffffc0204eee:	da4fb0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc0204ef2:	00002697          	auipc	a3,0x2
ffffffffc0204ef6:	5be68693          	addi	a3,a3,1470 # ffffffffc02074b0 <default_pmm_manager+0xe20>
ffffffffc0204efa:	00001617          	auipc	a2,0x1
ffffffffc0204efe:	3e660613          	addi	a2,a2,998 # ffffffffc02062e0 <commands+0x828>
ffffffffc0204f02:	41800593          	li	a1,1048
ffffffffc0204f06:	00002517          	auipc	a0,0x2
ffffffffc0204f0a:	1ba50513          	addi	a0,a0,442 # ffffffffc02070c0 <default_pmm_manager+0xa30>
ffffffffc0204f0e:	d84fb0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc0204f12:	00002697          	auipc	a3,0x2
ffffffffc0204f16:	57668693          	addi	a3,a3,1398 # ffffffffc0207488 <default_pmm_manager+0xdf8>
ffffffffc0204f1a:	00001617          	auipc	a2,0x1
ffffffffc0204f1e:	3c660613          	addi	a2,a2,966 # ffffffffc02062e0 <commands+0x828>
ffffffffc0204f22:	41700593          	li	a1,1047
ffffffffc0204f26:	00002517          	auipc	a0,0x2
ffffffffc0204f2a:	19a50513          	addi	a0,a0,410 # ffffffffc02070c0 <default_pmm_manager+0xa30>
ffffffffc0204f2e:	d64fb0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0204f32 <cpu_idle>:

// cpu_idle - at the end of kern_init, the first kernel thread idleproc will do below works
void cpu_idle(void)
{
ffffffffc0204f32:	1141                	addi	sp,sp,-16
ffffffffc0204f34:	e022                	sd	s0,0(sp)
ffffffffc0204f36:	e406                	sd	ra,8(sp)
ffffffffc0204f38:	000c2417          	auipc	s0,0xc2
ffffffffc0204f3c:	da040413          	addi	s0,s0,-608 # ffffffffc02c6cd8 <current>
    while (1)
    {
        if (current->need_resched)
ffffffffc0204f40:	6018                	ld	a4,0(s0)
ffffffffc0204f42:	6f1c                	ld	a5,24(a4)
ffffffffc0204f44:	dffd                	beqz	a5,ffffffffc0204f42 <cpu_idle+0x10>
        {
            schedule();
ffffffffc0204f46:	278000ef          	jal	ra,ffffffffc02051be <schedule>
ffffffffc0204f4a:	bfdd                	j	ffffffffc0204f40 <cpu_idle+0xe>

ffffffffc0204f4c <lab6_set_priority>:
        }
    }
}
// FOR LAB6, set the process's priority (bigger value will get more CPU time)
void lab6_set_priority(uint32_t priority)
{
ffffffffc0204f4c:	1141                	addi	sp,sp,-16
ffffffffc0204f4e:	e022                	sd	s0,0(sp)
    cprintf("set priority to %d\n", priority);
ffffffffc0204f50:	85aa                	mv	a1,a0
{
ffffffffc0204f52:	842a                	mv	s0,a0
    cprintf("set priority to %d\n", priority);
ffffffffc0204f54:	00002517          	auipc	a0,0x2
ffffffffc0204f58:	58450513          	addi	a0,a0,1412 # ffffffffc02074d8 <default_pmm_manager+0xe48>
{
ffffffffc0204f5c:	e406                	sd	ra,8(sp)
    cprintf("set priority to %d\n", priority);
ffffffffc0204f5e:	a3afb0ef          	jal	ra,ffffffffc0200198 <cprintf>
    if (priority == 0)
        current->lab6_priority = 1;
ffffffffc0204f62:	000c2797          	auipc	a5,0xc2
ffffffffc0204f66:	d767b783          	ld	a5,-650(a5) # ffffffffc02c6cd8 <current>
    if (priority == 0)
ffffffffc0204f6a:	e801                	bnez	s0,ffffffffc0204f7a <lab6_set_priority+0x2e>
    else
        current->lab6_priority = priority;
}
ffffffffc0204f6c:	60a2                	ld	ra,8(sp)
ffffffffc0204f6e:	6402                	ld	s0,0(sp)
        current->lab6_priority = 1;
ffffffffc0204f70:	4705                	li	a4,1
ffffffffc0204f72:	14e7a223          	sw	a4,324(a5)
}
ffffffffc0204f76:	0141                	addi	sp,sp,16
ffffffffc0204f78:	8082                	ret
ffffffffc0204f7a:	60a2                	ld	ra,8(sp)
        current->lab6_priority = priority;
ffffffffc0204f7c:	1487a223          	sw	s0,324(a5)
}
ffffffffc0204f80:	6402                	ld	s0,0(sp)
ffffffffc0204f82:	0141                	addi	sp,sp,16
ffffffffc0204f84:	8082                	ret

ffffffffc0204f86 <switch_to>:
.text
# void switch_to(struct proc_struct* from, struct proc_struct* to)
.globl switch_to
switch_to:
    # save from's registers
    STORE ra, 0*REGBYTES(a0)
ffffffffc0204f86:	00153023          	sd	ra,0(a0)
    STORE sp, 1*REGBYTES(a0)
ffffffffc0204f8a:	00253423          	sd	sp,8(a0)
    STORE s0, 2*REGBYTES(a0)
ffffffffc0204f8e:	e900                	sd	s0,16(a0)
    STORE s1, 3*REGBYTES(a0)
ffffffffc0204f90:	ed04                	sd	s1,24(a0)
    STORE s2, 4*REGBYTES(a0)
ffffffffc0204f92:	03253023          	sd	s2,32(a0)
    STORE s3, 5*REGBYTES(a0)
ffffffffc0204f96:	03353423          	sd	s3,40(a0)
    STORE s4, 6*REGBYTES(a0)
ffffffffc0204f9a:	03453823          	sd	s4,48(a0)
    STORE s5, 7*REGBYTES(a0)
ffffffffc0204f9e:	03553c23          	sd	s5,56(a0)
    STORE s6, 8*REGBYTES(a0)
ffffffffc0204fa2:	05653023          	sd	s6,64(a0)
    STORE s7, 9*REGBYTES(a0)
ffffffffc0204fa6:	05753423          	sd	s7,72(a0)
    STORE s8, 10*REGBYTES(a0)
ffffffffc0204faa:	05853823          	sd	s8,80(a0)
    STORE s9, 11*REGBYTES(a0)
ffffffffc0204fae:	05953c23          	sd	s9,88(a0)
    STORE s10, 12*REGBYTES(a0)
ffffffffc0204fb2:	07a53023          	sd	s10,96(a0)
    STORE s11, 13*REGBYTES(a0)
ffffffffc0204fb6:	07b53423          	sd	s11,104(a0)

    # restore to's registers
    LOAD ra, 0*REGBYTES(a1)
ffffffffc0204fba:	0005b083          	ld	ra,0(a1)
    LOAD sp, 1*REGBYTES(a1)
ffffffffc0204fbe:	0085b103          	ld	sp,8(a1)
    LOAD s0, 2*REGBYTES(a1)
ffffffffc0204fc2:	6980                	ld	s0,16(a1)
    LOAD s1, 3*REGBYTES(a1)
ffffffffc0204fc4:	6d84                	ld	s1,24(a1)
    LOAD s2, 4*REGBYTES(a1)
ffffffffc0204fc6:	0205b903          	ld	s2,32(a1)
    LOAD s3, 5*REGBYTES(a1)
ffffffffc0204fca:	0285b983          	ld	s3,40(a1)
    LOAD s4, 6*REGBYTES(a1)
ffffffffc0204fce:	0305ba03          	ld	s4,48(a1)
    LOAD s5, 7*REGBYTES(a1)
ffffffffc0204fd2:	0385ba83          	ld	s5,56(a1)
    LOAD s6, 8*REGBYTES(a1)
ffffffffc0204fd6:	0405bb03          	ld	s6,64(a1)
    LOAD s7, 9*REGBYTES(a1)
ffffffffc0204fda:	0485bb83          	ld	s7,72(a1)
    LOAD s8, 10*REGBYTES(a1)
ffffffffc0204fde:	0505bc03          	ld	s8,80(a1)
    LOAD s9, 11*REGBYTES(a1)
ffffffffc0204fe2:	0585bc83          	ld	s9,88(a1)
    LOAD s10, 12*REGBYTES(a1)
ffffffffc0204fe6:	0605bd03          	ld	s10,96(a1)
    LOAD s11, 13*REGBYTES(a1)
ffffffffc0204fea:	0685bd83          	ld	s11,104(a1)

    ret
ffffffffc0204fee:	8082                	ret

ffffffffc0204ff0 <RR_init>:
    elm->prev = elm->next = elm;
ffffffffc0204ff0:	e508                	sd	a0,8(a0)
ffffffffc0204ff2:	e108                	sd	a0,0(a0)
static void
RR_init(struct run_queue *rq)
{
    // LAB6: YOUR CODE
    list_init(&(rq->run_list));        // 初始化运行队列链表
    rq->proc_num = 0;                  // 进程数量初始为0
ffffffffc0204ff4:	00052823          	sw	zero,16(a0)
}
ffffffffc0204ff8:	8082                	ret

ffffffffc0204ffa <RR_enqueue>:
    // 注意：list_add_before(&head, node) 将节点添加到链表头部（head之前）
    // 要实现FIFO队列，应该使用list_add_after或list_add_tail
    // 但根据ucore的list实现，使用list_add_before(&head, node)实际上是添加到尾部
    
    // 检查进程是否已经在队列中
    if (list_empty(&(proc->run_link))) {
ffffffffc0204ffa:	1185b703          	ld	a4,280(a1)
ffffffffc0204ffe:	11058793          	addi	a5,a1,272
ffffffffc0205002:	00e78363          	beq	a5,a4,ffffffffc0205008 <RR_enqueue+0xe>
        proc->rq = rq;
        
        // 增加运行队列中的进程计数
        rq->proc_num++;
    }
}
ffffffffc0205006:	8082                	ret
    __list_add(elm, listelm->prev, listelm);
ffffffffc0205008:	6118                	ld	a4,0(a0)
        if (proc->time_slice == 0 || proc->time_slice > rq->max_time_slice) {
ffffffffc020500a:	1205a683          	lw	a3,288(a1)
    prev->next = next->prev = elm;
ffffffffc020500e:	e11c                	sd	a5,0(a0)
ffffffffc0205010:	e71c                	sd	a5,8(a4)
    elm->next = next;
ffffffffc0205012:	10a5bc23          	sd	a0,280(a1)
    elm->prev = prev;
ffffffffc0205016:	10e5b823          	sd	a4,272(a1)
ffffffffc020501a:	495c                	lw	a5,20(a0)
ffffffffc020501c:	ea89                	bnez	a3,ffffffffc020502e <RR_enqueue+0x34>
            proc->time_slice = rq->max_time_slice;
ffffffffc020501e:	12f5a023          	sw	a5,288(a1)
        rq->proc_num++;
ffffffffc0205022:	491c                	lw	a5,16(a0)
        proc->rq = rq;
ffffffffc0205024:	10a5b423          	sd	a0,264(a1)
        rq->proc_num++;
ffffffffc0205028:	2785                	addiw	a5,a5,1
ffffffffc020502a:	c91c                	sw	a5,16(a0)
}
ffffffffc020502c:	8082                	ret
        if (proc->time_slice == 0 || proc->time_slice > rq->max_time_slice) {
ffffffffc020502e:	fed7dae3          	bge	a5,a3,ffffffffc0205022 <RR_enqueue+0x28>
ffffffffc0205032:	b7f5                	j	ffffffffc020501e <RR_enqueue+0x24>

ffffffffc0205034 <RR_dequeue>:
    return list->next == list;
ffffffffc0205034:	1185b703          	ld	a4,280(a1)
static void
RR_dequeue(struct run_queue *rq, struct proc_struct *proc)
{
    // LAB6: YOUR CODE
    // 从运行队列中移除进程
    if (!list_empty(&(proc->run_link))) {
ffffffffc0205038:	11058793          	addi	a5,a1,272
ffffffffc020503c:	02e78063          	beq	a5,a4,ffffffffc020505c <RR_dequeue+0x28>
    __list_del(listelm->prev, listelm->next);
ffffffffc0205040:	1105b603          	ld	a2,272(a1)
        list_del_init(&(proc->run_link));
        
        // 减少运行队列中的进程计数
        rq->proc_num--;
ffffffffc0205044:	4914                	lw	a3,16(a0)
    prev->next = next;
ffffffffc0205046:	e618                	sd	a4,8(a2)
    next->prev = prev;
ffffffffc0205048:	e310                	sd	a2,0(a4)
    elm->prev = elm->next = elm;
ffffffffc020504a:	10f5bc23          	sd	a5,280(a1)
ffffffffc020504e:	10f5b823          	sd	a5,272(a1)
ffffffffc0205052:	fff6879b          	addiw	a5,a3,-1
ffffffffc0205056:	c91c                	sw	a5,16(a0)
        
        // 清除进程的运行队列指针
        proc->rq = NULL;
ffffffffc0205058:	1005b423          	sd	zero,264(a1)
    }
}
ffffffffc020505c:	8082                	ret

ffffffffc020505e <RR_pick_next>:
    return listelm->next;
ffffffffc020505e:	651c                	ld	a5,8(a0)
{
    // LAB6: YOUR CODE
    list_entry_t *le = list_next(&(rq->run_list));
    
    // 如果运行队列为空，返回NULL
    if (le == &(rq->run_list)) {
ffffffffc0205060:	00f50c63          	beq	a0,a5,ffffffffc0205078 <RR_pick_next+0x1a>
    
    // 返回运行队列中的第一个进程（FIFO）
    struct proc_struct *proc = le2proc(le, run_link);
    
    // 确保进程状态是可运行的
    if (proc->state == PROC_RUNNABLE) {
ffffffffc0205064:	ef07a683          	lw	a3,-272(a5)
ffffffffc0205068:	4709                	li	a4,2
        return NULL;
ffffffffc020506a:	4501                	li	a0,0
    if (proc->state == PROC_RUNNABLE) {
ffffffffc020506c:	00e68363          	beq	a3,a4,ffffffffc0205072 <RR_pick_next+0x14>
        return proc;
    }
    
    return NULL;
}
ffffffffc0205070:	8082                	ret
    struct proc_struct *proc = le2proc(le, run_link);
ffffffffc0205072:	ef078513          	addi	a0,a5,-272
        return proc;
ffffffffc0205076:	8082                	ret
        return NULL;
ffffffffc0205078:	4501                	li	a0,0
}
ffffffffc020507a:	8082                	ret

ffffffffc020507c <RR_proc_tick>:
 */
static void
RR_proc_tick(struct run_queue *rq, struct proc_struct *proc)
{
    // LAB6: YOUR CODE
    if (proc->time_slice > 0) {
ffffffffc020507c:	1205a783          	lw	a5,288(a1)
ffffffffc0205080:	00f05563          	blez	a5,ffffffffc020508a <RR_proc_tick+0xe>
        proc->time_slice--;
ffffffffc0205084:	37fd                	addiw	a5,a5,-1
ffffffffc0205086:	12f5a023          	sw	a5,288(a1)
    }
    
    // 当时间片用完时，设置需要重新调度的标志
    if (proc->time_slice == 0) {
ffffffffc020508a:	e399                	bnez	a5,ffffffffc0205090 <RR_proc_tick+0x14>
        proc->need_resched = 1;
ffffffffc020508c:	4785                	li	a5,1
ffffffffc020508e:	ed9c                	sd	a5,24(a1)
    }
}
ffffffffc0205090:	8082                	ret

ffffffffc0205092 <sched_class_proc_tick>:
    return sched_class->pick_next(rq);
}

void sched_class_proc_tick(struct proc_struct *proc)
{
    if (proc != idleproc)
ffffffffc0205092:	000c2797          	auipc	a5,0xc2
ffffffffc0205096:	c4e7b783          	ld	a5,-946(a5) # ffffffffc02c6ce0 <idleproc>
{
ffffffffc020509a:	85aa                	mv	a1,a0
    if (proc != idleproc)
ffffffffc020509c:	00a78c63          	beq	a5,a0,ffffffffc02050b4 <sched_class_proc_tick+0x22>
    {
        sched_class->proc_tick(rq, proc);
ffffffffc02050a0:	000c2797          	auipc	a5,0xc2
ffffffffc02050a4:	c607b783          	ld	a5,-928(a5) # ffffffffc02c6d00 <sched_class>
ffffffffc02050a8:	779c                	ld	a5,40(a5)
ffffffffc02050aa:	000c2517          	auipc	a0,0xc2
ffffffffc02050ae:	c4e53503          	ld	a0,-946(a0) # ffffffffc02c6cf8 <rq>
ffffffffc02050b2:	8782                	jr	a5
    }
    else
    {
        proc->need_resched = 1;
ffffffffc02050b4:	4705                	li	a4,1
ffffffffc02050b6:	ef98                	sd	a4,24(a5)
    }
}
ffffffffc02050b8:	8082                	ret

ffffffffc02050ba <sched_init>:

static struct run_queue __rq;

void sched_init(void)
{
ffffffffc02050ba:	1141                	addi	sp,sp,-16
    list_init(&timer_list);

    sched_class = &default_sched_class;
ffffffffc02050bc:	000bd717          	auipc	a4,0xbd
ffffffffc02050c0:	72470713          	addi	a4,a4,1828 # ffffffffc02c27e0 <default_sched_class>
{
ffffffffc02050c4:	e022                	sd	s0,0(sp)
ffffffffc02050c6:	e406                	sd	ra,8(sp)
    elm->prev = elm->next = elm;
ffffffffc02050c8:	000c2797          	auipc	a5,0xc2
ffffffffc02050cc:	ba078793          	addi	a5,a5,-1120 # ffffffffc02c6c68 <timer_list>

    rq = &__rq;
    rq->max_time_slice = MAX_TIME_SLICE;
    sched_class->init(rq);
ffffffffc02050d0:	6714                	ld	a3,8(a4)
    rq = &__rq;
ffffffffc02050d2:	000c2517          	auipc	a0,0xc2
ffffffffc02050d6:	b7650513          	addi	a0,a0,-1162 # ffffffffc02c6c48 <__rq>
ffffffffc02050da:	e79c                	sd	a5,8(a5)
ffffffffc02050dc:	e39c                	sd	a5,0(a5)
    rq->max_time_slice = MAX_TIME_SLICE;
ffffffffc02050de:	4795                	li	a5,5
ffffffffc02050e0:	c95c                	sw	a5,20(a0)
    sched_class = &default_sched_class;
ffffffffc02050e2:	000c2417          	auipc	s0,0xc2
ffffffffc02050e6:	c1e40413          	addi	s0,s0,-994 # ffffffffc02c6d00 <sched_class>
    rq = &__rq;
ffffffffc02050ea:	000c2797          	auipc	a5,0xc2
ffffffffc02050ee:	c0a7b723          	sd	a0,-1010(a5) # ffffffffc02c6cf8 <rq>
    sched_class = &default_sched_class;
ffffffffc02050f2:	e018                	sd	a4,0(s0)
    sched_class->init(rq);
ffffffffc02050f4:	9682                	jalr	a3

    cprintf("sched class: %s\n", sched_class->name);
ffffffffc02050f6:	601c                	ld	a5,0(s0)
}
ffffffffc02050f8:	6402                	ld	s0,0(sp)
ffffffffc02050fa:	60a2                	ld	ra,8(sp)
    cprintf("sched class: %s\n", sched_class->name);
ffffffffc02050fc:	638c                	ld	a1,0(a5)
ffffffffc02050fe:	00002517          	auipc	a0,0x2
ffffffffc0205102:	40250513          	addi	a0,a0,1026 # ffffffffc0207500 <default_pmm_manager+0xe70>
}
ffffffffc0205106:	0141                	addi	sp,sp,16
    cprintf("sched class: %s\n", sched_class->name);
ffffffffc0205108:	890fb06f          	j	ffffffffc0200198 <cprintf>

ffffffffc020510c <wakeup_proc>:

void wakeup_proc(struct proc_struct *proc)
{
    assert(proc->state != PROC_ZOMBIE);
ffffffffc020510c:	4118                	lw	a4,0(a0)
{
ffffffffc020510e:	1101                	addi	sp,sp,-32
ffffffffc0205110:	ec06                	sd	ra,24(sp)
ffffffffc0205112:	e822                	sd	s0,16(sp)
ffffffffc0205114:	e426                	sd	s1,8(sp)
    assert(proc->state != PROC_ZOMBIE);
ffffffffc0205116:	478d                	li	a5,3
ffffffffc0205118:	08f70363          	beq	a4,a5,ffffffffc020519e <wakeup_proc+0x92>
ffffffffc020511c:	842a                	mv	s0,a0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020511e:	100027f3          	csrr	a5,sstatus
ffffffffc0205122:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0205124:	4481                	li	s1,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0205126:	e7bd                	bnez	a5,ffffffffc0205194 <wakeup_proc+0x88>
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        if (proc->state != PROC_RUNNABLE)
ffffffffc0205128:	4789                	li	a5,2
ffffffffc020512a:	04f70863          	beq	a4,a5,ffffffffc020517a <wakeup_proc+0x6e>
        {
            proc->state = PROC_RUNNABLE;
ffffffffc020512e:	c01c                	sw	a5,0(s0)
            proc->wait_state = 0;
ffffffffc0205130:	0e042623          	sw	zero,236(s0)
            if (proc != current)
ffffffffc0205134:	000c2797          	auipc	a5,0xc2
ffffffffc0205138:	ba47b783          	ld	a5,-1116(a5) # ffffffffc02c6cd8 <current>
ffffffffc020513c:	02878363          	beq	a5,s0,ffffffffc0205162 <wakeup_proc+0x56>
    if (proc != idleproc)
ffffffffc0205140:	000c2797          	auipc	a5,0xc2
ffffffffc0205144:	ba07b783          	ld	a5,-1120(a5) # ffffffffc02c6ce0 <idleproc>
ffffffffc0205148:	00f40d63          	beq	s0,a5,ffffffffc0205162 <wakeup_proc+0x56>
        sched_class->enqueue(rq, proc);
ffffffffc020514c:	000c2797          	auipc	a5,0xc2
ffffffffc0205150:	bb47b783          	ld	a5,-1100(a5) # ffffffffc02c6d00 <sched_class>
ffffffffc0205154:	6b9c                	ld	a5,16(a5)
ffffffffc0205156:	85a2                	mv	a1,s0
ffffffffc0205158:	000c2517          	auipc	a0,0xc2
ffffffffc020515c:	ba053503          	ld	a0,-1120(a0) # ffffffffc02c6cf8 <rq>
ffffffffc0205160:	9782                	jalr	a5
    if (flag)
ffffffffc0205162:	e491                	bnez	s1,ffffffffc020516e <wakeup_proc+0x62>
        {
            warn("wakeup runnable process.\n");
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc0205164:	60e2                	ld	ra,24(sp)
ffffffffc0205166:	6442                	ld	s0,16(sp)
ffffffffc0205168:	64a2                	ld	s1,8(sp)
ffffffffc020516a:	6105                	addi	sp,sp,32
ffffffffc020516c:	8082                	ret
ffffffffc020516e:	6442                	ld	s0,16(sp)
ffffffffc0205170:	60e2                	ld	ra,24(sp)
ffffffffc0205172:	64a2                	ld	s1,8(sp)
ffffffffc0205174:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0205176:	833fb06f          	j	ffffffffc02009a8 <intr_enable>
            warn("wakeup runnable process.\n");
ffffffffc020517a:	00002617          	auipc	a2,0x2
ffffffffc020517e:	3d660613          	addi	a2,a2,982 # ffffffffc0207550 <default_pmm_manager+0xec0>
ffffffffc0205182:	05100593          	li	a1,81
ffffffffc0205186:	00002517          	auipc	a0,0x2
ffffffffc020518a:	3b250513          	addi	a0,a0,946 # ffffffffc0207538 <default_pmm_manager+0xea8>
ffffffffc020518e:	b6cfb0ef          	jal	ra,ffffffffc02004fa <__warn>
ffffffffc0205192:	bfc1                	j	ffffffffc0205162 <wakeup_proc+0x56>
        intr_disable();
ffffffffc0205194:	81bfb0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        if (proc->state != PROC_RUNNABLE)
ffffffffc0205198:	4018                	lw	a4,0(s0)
        return 1;
ffffffffc020519a:	4485                	li	s1,1
ffffffffc020519c:	b771                	j	ffffffffc0205128 <wakeup_proc+0x1c>
    assert(proc->state != PROC_ZOMBIE);
ffffffffc020519e:	00002697          	auipc	a3,0x2
ffffffffc02051a2:	37a68693          	addi	a3,a3,890 # ffffffffc0207518 <default_pmm_manager+0xe88>
ffffffffc02051a6:	00001617          	auipc	a2,0x1
ffffffffc02051aa:	13a60613          	addi	a2,a2,314 # ffffffffc02062e0 <commands+0x828>
ffffffffc02051ae:	04200593          	li	a1,66
ffffffffc02051b2:	00002517          	auipc	a0,0x2
ffffffffc02051b6:	38650513          	addi	a0,a0,902 # ffffffffc0207538 <default_pmm_manager+0xea8>
ffffffffc02051ba:	ad8fb0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc02051be <schedule>:

void schedule(void)
{
ffffffffc02051be:	7179                	addi	sp,sp,-48
ffffffffc02051c0:	f406                	sd	ra,40(sp)
ffffffffc02051c2:	f022                	sd	s0,32(sp)
ffffffffc02051c4:	ec26                	sd	s1,24(sp)
ffffffffc02051c6:	e84a                	sd	s2,16(sp)
ffffffffc02051c8:	e44e                	sd	s3,8(sp)
ffffffffc02051ca:	e052                	sd	s4,0(sp)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02051cc:	100027f3          	csrr	a5,sstatus
ffffffffc02051d0:	8b89                	andi	a5,a5,2
ffffffffc02051d2:	4a01                	li	s4,0
ffffffffc02051d4:	e3cd                	bnez	a5,ffffffffc0205276 <schedule+0xb8>
    bool intr_flag;
    struct proc_struct *next;
    local_intr_save(intr_flag);
    {
        current->need_resched = 0;
ffffffffc02051d6:	000c2497          	auipc	s1,0xc2
ffffffffc02051da:	b0248493          	addi	s1,s1,-1278 # ffffffffc02c6cd8 <current>
ffffffffc02051de:	608c                	ld	a1,0(s1)
        sched_class->enqueue(rq, proc);
ffffffffc02051e0:	000c2997          	auipc	s3,0xc2
ffffffffc02051e4:	b2098993          	addi	s3,s3,-1248 # ffffffffc02c6d00 <sched_class>
ffffffffc02051e8:	000c2917          	auipc	s2,0xc2
ffffffffc02051ec:	b1090913          	addi	s2,s2,-1264 # ffffffffc02c6cf8 <rq>
        if (current->state == PROC_RUNNABLE)
ffffffffc02051f0:	4194                	lw	a3,0(a1)
        current->need_resched = 0;
ffffffffc02051f2:	0005bc23          	sd	zero,24(a1)
        if (current->state == PROC_RUNNABLE)
ffffffffc02051f6:	4709                	li	a4,2
        sched_class->enqueue(rq, proc);
ffffffffc02051f8:	0009b783          	ld	a5,0(s3)
ffffffffc02051fc:	00093503          	ld	a0,0(s2)
        if (current->state == PROC_RUNNABLE)
ffffffffc0205200:	04e68e63          	beq	a3,a4,ffffffffc020525c <schedule+0x9e>
    return sched_class->pick_next(rq);
ffffffffc0205204:	739c                	ld	a5,32(a5)
ffffffffc0205206:	9782                	jalr	a5
ffffffffc0205208:	842a                	mv	s0,a0
        {
            sched_class_enqueue(current);
        }
        if ((next = sched_class_pick_next()) != NULL)
ffffffffc020520a:	c521                	beqz	a0,ffffffffc0205252 <schedule+0x94>
    sched_class->dequeue(rq, proc);
ffffffffc020520c:	0009b783          	ld	a5,0(s3)
ffffffffc0205210:	00093503          	ld	a0,0(s2)
ffffffffc0205214:	85a2                	mv	a1,s0
ffffffffc0205216:	6f9c                	ld	a5,24(a5)
ffffffffc0205218:	9782                	jalr	a5
        }
        if (next == NULL)
        {
            next = idleproc;
        }
        next->runs++;
ffffffffc020521a:	441c                	lw	a5,8(s0)
        if (next != current)
ffffffffc020521c:	6098                	ld	a4,0(s1)
        next->runs++;
ffffffffc020521e:	2785                	addiw	a5,a5,1
ffffffffc0205220:	c41c                	sw	a5,8(s0)
        if (next != current)
ffffffffc0205222:	00870563          	beq	a4,s0,ffffffffc020522c <schedule+0x6e>
        {
            proc_run(next);
ffffffffc0205226:	8522                	mv	a0,s0
ffffffffc0205228:	c27fe0ef          	jal	ra,ffffffffc0203e4e <proc_run>
    if (flag)
ffffffffc020522c:	000a1a63          	bnez	s4,ffffffffc0205240 <schedule+0x82>
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc0205230:	70a2                	ld	ra,40(sp)
ffffffffc0205232:	7402                	ld	s0,32(sp)
ffffffffc0205234:	64e2                	ld	s1,24(sp)
ffffffffc0205236:	6942                	ld	s2,16(sp)
ffffffffc0205238:	69a2                	ld	s3,8(sp)
ffffffffc020523a:	6a02                	ld	s4,0(sp)
ffffffffc020523c:	6145                	addi	sp,sp,48
ffffffffc020523e:	8082                	ret
ffffffffc0205240:	7402                	ld	s0,32(sp)
ffffffffc0205242:	70a2                	ld	ra,40(sp)
ffffffffc0205244:	64e2                	ld	s1,24(sp)
ffffffffc0205246:	6942                	ld	s2,16(sp)
ffffffffc0205248:	69a2                	ld	s3,8(sp)
ffffffffc020524a:	6a02                	ld	s4,0(sp)
ffffffffc020524c:	6145                	addi	sp,sp,48
        intr_enable();
ffffffffc020524e:	f5afb06f          	j	ffffffffc02009a8 <intr_enable>
            next = idleproc;
ffffffffc0205252:	000c2417          	auipc	s0,0xc2
ffffffffc0205256:	a8e43403          	ld	s0,-1394(s0) # ffffffffc02c6ce0 <idleproc>
ffffffffc020525a:	b7c1                	j	ffffffffc020521a <schedule+0x5c>
    if (proc != idleproc)
ffffffffc020525c:	000c2717          	auipc	a4,0xc2
ffffffffc0205260:	a8473703          	ld	a4,-1404(a4) # ffffffffc02c6ce0 <idleproc>
ffffffffc0205264:	fae580e3          	beq	a1,a4,ffffffffc0205204 <schedule+0x46>
        sched_class->enqueue(rq, proc);
ffffffffc0205268:	6b9c                	ld	a5,16(a5)
ffffffffc020526a:	9782                	jalr	a5
    return sched_class->pick_next(rq);
ffffffffc020526c:	0009b783          	ld	a5,0(s3)
ffffffffc0205270:	00093503          	ld	a0,0(s2)
ffffffffc0205274:	bf41                	j	ffffffffc0205204 <schedule+0x46>
        intr_disable();
ffffffffc0205276:	f38fb0ef          	jal	ra,ffffffffc02009ae <intr_disable>
        return 1;
ffffffffc020527a:	4a05                	li	s4,1
ffffffffc020527c:	bfa9                	j	ffffffffc02051d6 <schedule+0x18>

ffffffffc020527e <sys_getpid>:
    return do_kill(pid);
}

static int
sys_getpid(uint64_t arg[]) {
    return current->pid;
ffffffffc020527e:	000c2797          	auipc	a5,0xc2
ffffffffc0205282:	a5a7b783          	ld	a5,-1446(a5) # ffffffffc02c6cd8 <current>
}
ffffffffc0205286:	43c8                	lw	a0,4(a5)
ffffffffc0205288:	8082                	ret

ffffffffc020528a <sys_pgdir>:

static int
sys_pgdir(uint64_t arg[]) {
    //print_pgdir();
    return 0;
}
ffffffffc020528a:	4501                	li	a0,0
ffffffffc020528c:	8082                	ret

ffffffffc020528e <sys_gettime>:
static int sys_gettime(uint64_t arg[]){
    return (int)ticks*10;
ffffffffc020528e:	000c2797          	auipc	a5,0xc2
ffffffffc0205292:	9f27b783          	ld	a5,-1550(a5) # ffffffffc02c6c80 <ticks>
ffffffffc0205296:	0027951b          	slliw	a0,a5,0x2
ffffffffc020529a:	9d3d                	addw	a0,a0,a5
}
ffffffffc020529c:	0015151b          	slliw	a0,a0,0x1
ffffffffc02052a0:	8082                	ret

ffffffffc02052a2 <sys_lab6_set_priority>:
static int sys_lab6_set_priority(uint64_t arg[]){
    uint64_t priority = (uint64_t)arg[0];
    lab6_set_priority(priority);
ffffffffc02052a2:	4108                	lw	a0,0(a0)
static int sys_lab6_set_priority(uint64_t arg[]){
ffffffffc02052a4:	1141                	addi	sp,sp,-16
ffffffffc02052a6:	e406                	sd	ra,8(sp)
    lab6_set_priority(priority);
ffffffffc02052a8:	ca5ff0ef          	jal	ra,ffffffffc0204f4c <lab6_set_priority>
    return 0;
}
ffffffffc02052ac:	60a2                	ld	ra,8(sp)
ffffffffc02052ae:	4501                	li	a0,0
ffffffffc02052b0:	0141                	addi	sp,sp,16
ffffffffc02052b2:	8082                	ret

ffffffffc02052b4 <sys_putc>:
    cputchar(c);
ffffffffc02052b4:	4108                	lw	a0,0(a0)
sys_putc(uint64_t arg[]) {
ffffffffc02052b6:	1141                	addi	sp,sp,-16
ffffffffc02052b8:	e406                	sd	ra,8(sp)
    cputchar(c);
ffffffffc02052ba:	f15fa0ef          	jal	ra,ffffffffc02001ce <cputchar>
}
ffffffffc02052be:	60a2                	ld	ra,8(sp)
ffffffffc02052c0:	4501                	li	a0,0
ffffffffc02052c2:	0141                	addi	sp,sp,16
ffffffffc02052c4:	8082                	ret

ffffffffc02052c6 <sys_kill>:
    return do_kill(pid);
ffffffffc02052c6:	4108                	lw	a0,0(a0)
ffffffffc02052c8:	a57ff06f          	j	ffffffffc0204d1e <do_kill>

ffffffffc02052cc <sys_yield>:
    return do_yield();
ffffffffc02052cc:	a05ff06f          	j	ffffffffc0204cd0 <do_yield>

ffffffffc02052d0 <sys_exec>:
    return do_execve(name, len, binary, size);
ffffffffc02052d0:	6d14                	ld	a3,24(a0)
ffffffffc02052d2:	6910                	ld	a2,16(a0)
ffffffffc02052d4:	650c                	ld	a1,8(a0)
ffffffffc02052d6:	6108                	ld	a0,0(a0)
ffffffffc02052d8:	c4aff06f          	j	ffffffffc0204722 <do_execve>

ffffffffc02052dc <sys_wait>:
    return do_wait(pid, store);
ffffffffc02052dc:	650c                	ld	a1,8(a0)
ffffffffc02052de:	4108                	lw	a0,0(a0)
ffffffffc02052e0:	a01ff06f          	j	ffffffffc0204ce0 <do_wait>

ffffffffc02052e4 <sys_fork>:
    struct trapframe *tf = current->tf;
ffffffffc02052e4:	000c2797          	auipc	a5,0xc2
ffffffffc02052e8:	9f47b783          	ld	a5,-1548(a5) # ffffffffc02c6cd8 <current>
ffffffffc02052ec:	73d0                	ld	a2,160(a5)
    return do_fork(0, stack, tf);
ffffffffc02052ee:	4501                	li	a0,0
ffffffffc02052f0:	6a0c                	ld	a1,16(a2)
ffffffffc02052f2:	bc7fe06f          	j	ffffffffc0203eb8 <do_fork>

ffffffffc02052f6 <sys_exit>:
    return do_exit(error_code);
ffffffffc02052f6:	4108                	lw	a0,0(a0)
ffffffffc02052f8:	febfe06f          	j	ffffffffc02042e2 <do_exit>

ffffffffc02052fc <syscall>:
};

#define NUM_SYSCALLS        ((sizeof(syscalls)) / (sizeof(syscalls[0])))

void
syscall(void) {
ffffffffc02052fc:	715d                	addi	sp,sp,-80
ffffffffc02052fe:	fc26                	sd	s1,56(sp)
    struct trapframe *tf = current->tf;
ffffffffc0205300:	000c2497          	auipc	s1,0xc2
ffffffffc0205304:	9d848493          	addi	s1,s1,-1576 # ffffffffc02c6cd8 <current>
ffffffffc0205308:	6098                	ld	a4,0(s1)
syscall(void) {
ffffffffc020530a:	e0a2                	sd	s0,64(sp)
ffffffffc020530c:	f84a                	sd	s2,48(sp)
    struct trapframe *tf = current->tf;
ffffffffc020530e:	7340                	ld	s0,160(a4)
syscall(void) {
ffffffffc0205310:	e486                	sd	ra,72(sp)
    uint64_t arg[5];
    int num = tf->gpr.a0;
    if (num >= 0 && num < NUM_SYSCALLS) {
ffffffffc0205312:	0ff00793          	li	a5,255
    int num = tf->gpr.a0;
ffffffffc0205316:	05042903          	lw	s2,80(s0)
    if (num >= 0 && num < NUM_SYSCALLS) {
ffffffffc020531a:	0327ee63          	bltu	a5,s2,ffffffffc0205356 <syscall+0x5a>
        if (syscalls[num] != NULL) {
ffffffffc020531e:	00391713          	slli	a4,s2,0x3
ffffffffc0205322:	00002797          	auipc	a5,0x2
ffffffffc0205326:	29678793          	addi	a5,a5,662 # ffffffffc02075b8 <syscalls>
ffffffffc020532a:	97ba                	add	a5,a5,a4
ffffffffc020532c:	639c                	ld	a5,0(a5)
ffffffffc020532e:	c785                	beqz	a5,ffffffffc0205356 <syscall+0x5a>
            arg[0] = tf->gpr.a1;
ffffffffc0205330:	6c28                	ld	a0,88(s0)
            arg[1] = tf->gpr.a2;
ffffffffc0205332:	702c                	ld	a1,96(s0)
            arg[2] = tf->gpr.a3;
ffffffffc0205334:	7430                	ld	a2,104(s0)
            arg[3] = tf->gpr.a4;
ffffffffc0205336:	7834                	ld	a3,112(s0)
            arg[4] = tf->gpr.a5;
ffffffffc0205338:	7c38                	ld	a4,120(s0)
            arg[0] = tf->gpr.a1;
ffffffffc020533a:	e42a                	sd	a0,8(sp)
            arg[1] = tf->gpr.a2;
ffffffffc020533c:	e82e                	sd	a1,16(sp)
            arg[2] = tf->gpr.a3;
ffffffffc020533e:	ec32                	sd	a2,24(sp)
            arg[3] = tf->gpr.a4;
ffffffffc0205340:	f036                	sd	a3,32(sp)
            arg[4] = tf->gpr.a5;
ffffffffc0205342:	f43a                	sd	a4,40(sp)
            tf->gpr.a0 = syscalls[num](arg);
ffffffffc0205344:	0028                	addi	a0,sp,8
ffffffffc0205346:	9782                	jalr	a5
        }
    }
    print_trapframe(tf);
    panic("undefined syscall %d, pid = %d, name = %s.\n",
            num, current->pid, current->name);
}
ffffffffc0205348:	60a6                	ld	ra,72(sp)
            tf->gpr.a0 = syscalls[num](arg);
ffffffffc020534a:	e828                	sd	a0,80(s0)
}
ffffffffc020534c:	6406                	ld	s0,64(sp)
ffffffffc020534e:	74e2                	ld	s1,56(sp)
ffffffffc0205350:	7942                	ld	s2,48(sp)
ffffffffc0205352:	6161                	addi	sp,sp,80
ffffffffc0205354:	8082                	ret
    print_trapframe(tf);
ffffffffc0205356:	8522                	mv	a0,s0
ffffffffc0205358:	847fb0ef          	jal	ra,ffffffffc0200b9e <print_trapframe>
    panic("undefined syscall %d, pid = %d, name = %s.\n",
ffffffffc020535c:	609c                	ld	a5,0(s1)
ffffffffc020535e:	86ca                	mv	a3,s2
ffffffffc0205360:	00002617          	auipc	a2,0x2
ffffffffc0205364:	21060613          	addi	a2,a2,528 # ffffffffc0207570 <default_pmm_manager+0xee0>
ffffffffc0205368:	43d8                	lw	a4,4(a5)
ffffffffc020536a:	06c00593          	li	a1,108
ffffffffc020536e:	0b478793          	addi	a5,a5,180
ffffffffc0205372:	00002517          	auipc	a0,0x2
ffffffffc0205376:	22e50513          	addi	a0,a0,558 # ffffffffc02075a0 <default_pmm_manager+0xf10>
ffffffffc020537a:	918fb0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc020537e <hash32>:
 *
 * High bits are more random, so we use them.
 * */
uint32_t
hash32(uint32_t val, unsigned int bits) {
    uint32_t hash = val * GOLDEN_RATIO_PRIME_32;
ffffffffc020537e:	9e3707b7          	lui	a5,0x9e370
ffffffffc0205382:	2785                	addiw	a5,a5,1
ffffffffc0205384:	02a7853b          	mulw	a0,a5,a0
    return (hash >> (32 - bits));
ffffffffc0205388:	02000793          	li	a5,32
ffffffffc020538c:	9f8d                	subw	a5,a5,a1
}
ffffffffc020538e:	00f5553b          	srlw	a0,a0,a5
ffffffffc0205392:	8082                	ret

ffffffffc0205394 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0205394:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0205398:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc020539a:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc020539e:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc02053a0:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02053a4:	f022                	sd	s0,32(sp)
ffffffffc02053a6:	ec26                	sd	s1,24(sp)
ffffffffc02053a8:	e84a                	sd	s2,16(sp)
ffffffffc02053aa:	f406                	sd	ra,40(sp)
ffffffffc02053ac:	e44e                	sd	s3,8(sp)
ffffffffc02053ae:	84aa                	mv	s1,a0
ffffffffc02053b0:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc02053b2:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc02053b6:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc02053b8:	03067e63          	bgeu	a2,a6,ffffffffc02053f4 <printnum+0x60>
ffffffffc02053bc:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc02053be:	00805763          	blez	s0,ffffffffc02053cc <printnum+0x38>
ffffffffc02053c2:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc02053c4:	85ca                	mv	a1,s2
ffffffffc02053c6:	854e                	mv	a0,s3
ffffffffc02053c8:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc02053ca:	fc65                	bnez	s0,ffffffffc02053c2 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02053cc:	1a02                	slli	s4,s4,0x20
ffffffffc02053ce:	00003797          	auipc	a5,0x3
ffffffffc02053d2:	9ea78793          	addi	a5,a5,-1558 # ffffffffc0207db8 <syscalls+0x800>
ffffffffc02053d6:	020a5a13          	srli	s4,s4,0x20
ffffffffc02053da:	9a3e                	add	s4,s4,a5
    // Crashes if num >= base. No idea what going on here
    // Here is a quick fix
    // update: Stack grows downward and destory the SBI
    // sbi_console_putchar("0123456789abcdef"[mod]);
    // (*(int *)putdat)++;
}
ffffffffc02053dc:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02053de:	000a4503          	lbu	a0,0(s4)
}
ffffffffc02053e2:	70a2                	ld	ra,40(sp)
ffffffffc02053e4:	69a2                	ld	s3,8(sp)
ffffffffc02053e6:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02053e8:	85ca                	mv	a1,s2
ffffffffc02053ea:	87a6                	mv	a5,s1
}
ffffffffc02053ec:	6942                	ld	s2,16(sp)
ffffffffc02053ee:	64e2                	ld	s1,24(sp)
ffffffffc02053f0:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02053f2:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc02053f4:	03065633          	divu	a2,a2,a6
ffffffffc02053f8:	8722                	mv	a4,s0
ffffffffc02053fa:	f9bff0ef          	jal	ra,ffffffffc0205394 <printnum>
ffffffffc02053fe:	b7f9                	j	ffffffffc02053cc <printnum+0x38>

ffffffffc0205400 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0205400:	7119                	addi	sp,sp,-128
ffffffffc0205402:	f4a6                	sd	s1,104(sp)
ffffffffc0205404:	f0ca                	sd	s2,96(sp)
ffffffffc0205406:	ecce                	sd	s3,88(sp)
ffffffffc0205408:	e8d2                	sd	s4,80(sp)
ffffffffc020540a:	e4d6                	sd	s5,72(sp)
ffffffffc020540c:	e0da                	sd	s6,64(sp)
ffffffffc020540e:	fc5e                	sd	s7,56(sp)
ffffffffc0205410:	f06a                	sd	s10,32(sp)
ffffffffc0205412:	fc86                	sd	ra,120(sp)
ffffffffc0205414:	f8a2                	sd	s0,112(sp)
ffffffffc0205416:	f862                	sd	s8,48(sp)
ffffffffc0205418:	f466                	sd	s9,40(sp)
ffffffffc020541a:	ec6e                	sd	s11,24(sp)
ffffffffc020541c:	892a                	mv	s2,a0
ffffffffc020541e:	84ae                	mv	s1,a1
ffffffffc0205420:	8d32                	mv	s10,a2
ffffffffc0205422:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0205424:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc0205428:	5b7d                	li	s6,-1
ffffffffc020542a:	00003a97          	auipc	s5,0x3
ffffffffc020542e:	9baa8a93          	addi	s5,s5,-1606 # ffffffffc0207de4 <syscalls+0x82c>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0205432:	00003b97          	auipc	s7,0x3
ffffffffc0205436:	bceb8b93          	addi	s7,s7,-1074 # ffffffffc0208000 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc020543a:	000d4503          	lbu	a0,0(s10)
ffffffffc020543e:	001d0413          	addi	s0,s10,1
ffffffffc0205442:	01350a63          	beq	a0,s3,ffffffffc0205456 <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc0205446:	c121                	beqz	a0,ffffffffc0205486 <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc0205448:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc020544a:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc020544c:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc020544e:	fff44503          	lbu	a0,-1(s0)
ffffffffc0205452:	ff351ae3          	bne	a0,s3,ffffffffc0205446 <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205456:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc020545a:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc020545e:	4c81                	li	s9,0
ffffffffc0205460:	4881                	li	a7,0
        width = precision = -1;
ffffffffc0205462:	5c7d                	li	s8,-1
ffffffffc0205464:	5dfd                	li	s11,-1
ffffffffc0205466:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc020546a:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020546c:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0205470:	0ff5f593          	zext.b	a1,a1
ffffffffc0205474:	00140d13          	addi	s10,s0,1
ffffffffc0205478:	04b56263          	bltu	a0,a1,ffffffffc02054bc <vprintfmt+0xbc>
ffffffffc020547c:	058a                	slli	a1,a1,0x2
ffffffffc020547e:	95d6                	add	a1,a1,s5
ffffffffc0205480:	4194                	lw	a3,0(a1)
ffffffffc0205482:	96d6                	add	a3,a3,s5
ffffffffc0205484:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0205486:	70e6                	ld	ra,120(sp)
ffffffffc0205488:	7446                	ld	s0,112(sp)
ffffffffc020548a:	74a6                	ld	s1,104(sp)
ffffffffc020548c:	7906                	ld	s2,96(sp)
ffffffffc020548e:	69e6                	ld	s3,88(sp)
ffffffffc0205490:	6a46                	ld	s4,80(sp)
ffffffffc0205492:	6aa6                	ld	s5,72(sp)
ffffffffc0205494:	6b06                	ld	s6,64(sp)
ffffffffc0205496:	7be2                	ld	s7,56(sp)
ffffffffc0205498:	7c42                	ld	s8,48(sp)
ffffffffc020549a:	7ca2                	ld	s9,40(sp)
ffffffffc020549c:	7d02                	ld	s10,32(sp)
ffffffffc020549e:	6de2                	ld	s11,24(sp)
ffffffffc02054a0:	6109                	addi	sp,sp,128
ffffffffc02054a2:	8082                	ret
            padc = '0';
ffffffffc02054a4:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc02054a6:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02054aa:	846a                	mv	s0,s10
ffffffffc02054ac:	00140d13          	addi	s10,s0,1
ffffffffc02054b0:	fdd6059b          	addiw	a1,a2,-35
ffffffffc02054b4:	0ff5f593          	zext.b	a1,a1
ffffffffc02054b8:	fcb572e3          	bgeu	a0,a1,ffffffffc020547c <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc02054bc:	85a6                	mv	a1,s1
ffffffffc02054be:	02500513          	li	a0,37
ffffffffc02054c2:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc02054c4:	fff44783          	lbu	a5,-1(s0)
ffffffffc02054c8:	8d22                	mv	s10,s0
ffffffffc02054ca:	f73788e3          	beq	a5,s3,ffffffffc020543a <vprintfmt+0x3a>
ffffffffc02054ce:	ffed4783          	lbu	a5,-2(s10)
ffffffffc02054d2:	1d7d                	addi	s10,s10,-1
ffffffffc02054d4:	ff379de3          	bne	a5,s3,ffffffffc02054ce <vprintfmt+0xce>
ffffffffc02054d8:	b78d                	j	ffffffffc020543a <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc02054da:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc02054de:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02054e2:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc02054e4:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc02054e8:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc02054ec:	02d86463          	bltu	a6,a3,ffffffffc0205514 <vprintfmt+0x114>
                ch = *fmt;
ffffffffc02054f0:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc02054f4:	002c169b          	slliw	a3,s8,0x2
ffffffffc02054f8:	0186873b          	addw	a4,a3,s8
ffffffffc02054fc:	0017171b          	slliw	a4,a4,0x1
ffffffffc0205500:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc0205502:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc0205506:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0205508:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc020550c:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0205510:	fed870e3          	bgeu	a6,a3,ffffffffc02054f0 <vprintfmt+0xf0>
            if (width < 0)
ffffffffc0205514:	f40ddce3          	bgez	s11,ffffffffc020546c <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc0205518:	8de2                	mv	s11,s8
ffffffffc020551a:	5c7d                	li	s8,-1
ffffffffc020551c:	bf81                	j	ffffffffc020546c <vprintfmt+0x6c>
            if (width < 0)
ffffffffc020551e:	fffdc693          	not	a3,s11
ffffffffc0205522:	96fd                	srai	a3,a3,0x3f
ffffffffc0205524:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205528:	00144603          	lbu	a2,1(s0)
ffffffffc020552c:	2d81                	sext.w	s11,s11
ffffffffc020552e:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0205530:	bf35                	j	ffffffffc020546c <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc0205532:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205536:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc020553a:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020553c:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc020553e:	bfd9                	j	ffffffffc0205514 <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc0205540:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0205542:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0205546:	01174463          	blt	a4,a7,ffffffffc020554e <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc020554a:	1a088e63          	beqz	a7,ffffffffc0205706 <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc020554e:	000a3603          	ld	a2,0(s4)
ffffffffc0205552:	46c1                	li	a3,16
ffffffffc0205554:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0205556:	2781                	sext.w	a5,a5
ffffffffc0205558:	876e                	mv	a4,s11
ffffffffc020555a:	85a6                	mv	a1,s1
ffffffffc020555c:	854a                	mv	a0,s2
ffffffffc020555e:	e37ff0ef          	jal	ra,ffffffffc0205394 <printnum>
            break;
ffffffffc0205562:	bde1                	j	ffffffffc020543a <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc0205564:	000a2503          	lw	a0,0(s4)
ffffffffc0205568:	85a6                	mv	a1,s1
ffffffffc020556a:	0a21                	addi	s4,s4,8
ffffffffc020556c:	9902                	jalr	s2
            break;
ffffffffc020556e:	b5f1                	j	ffffffffc020543a <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0205570:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0205572:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0205576:	01174463          	blt	a4,a7,ffffffffc020557e <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc020557a:	18088163          	beqz	a7,ffffffffc02056fc <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc020557e:	000a3603          	ld	a2,0(s4)
ffffffffc0205582:	46a9                	li	a3,10
ffffffffc0205584:	8a2e                	mv	s4,a1
ffffffffc0205586:	bfc1                	j	ffffffffc0205556 <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205588:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc020558c:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020558e:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0205590:	bdf1                	j	ffffffffc020546c <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc0205592:	85a6                	mv	a1,s1
ffffffffc0205594:	02500513          	li	a0,37
ffffffffc0205598:	9902                	jalr	s2
            break;
ffffffffc020559a:	b545                	j	ffffffffc020543a <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020559c:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc02055a0:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02055a2:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02055a4:	b5e1                	j	ffffffffc020546c <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc02055a6:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02055a8:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc02055ac:	01174463          	blt	a4,a7,ffffffffc02055b4 <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc02055b0:	14088163          	beqz	a7,ffffffffc02056f2 <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc02055b4:	000a3603          	ld	a2,0(s4)
ffffffffc02055b8:	46a1                	li	a3,8
ffffffffc02055ba:	8a2e                	mv	s4,a1
ffffffffc02055bc:	bf69                	j	ffffffffc0205556 <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc02055be:	03000513          	li	a0,48
ffffffffc02055c2:	85a6                	mv	a1,s1
ffffffffc02055c4:	e03e                	sd	a5,0(sp)
ffffffffc02055c6:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc02055c8:	85a6                	mv	a1,s1
ffffffffc02055ca:	07800513          	li	a0,120
ffffffffc02055ce:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc02055d0:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc02055d2:	6782                	ld	a5,0(sp)
ffffffffc02055d4:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc02055d6:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc02055da:	bfb5                	j	ffffffffc0205556 <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc02055dc:	000a3403          	ld	s0,0(s4)
ffffffffc02055e0:	008a0713          	addi	a4,s4,8
ffffffffc02055e4:	e03a                	sd	a4,0(sp)
ffffffffc02055e6:	14040263          	beqz	s0,ffffffffc020572a <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc02055ea:	0fb05763          	blez	s11,ffffffffc02056d8 <vprintfmt+0x2d8>
ffffffffc02055ee:	02d00693          	li	a3,45
ffffffffc02055f2:	0cd79163          	bne	a5,a3,ffffffffc02056b4 <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02055f6:	00044783          	lbu	a5,0(s0)
ffffffffc02055fa:	0007851b          	sext.w	a0,a5
ffffffffc02055fe:	cf85                	beqz	a5,ffffffffc0205636 <vprintfmt+0x236>
ffffffffc0205600:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0205604:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205608:	000c4563          	bltz	s8,ffffffffc0205612 <vprintfmt+0x212>
ffffffffc020560c:	3c7d                	addiw	s8,s8,-1
ffffffffc020560e:	036c0263          	beq	s8,s6,ffffffffc0205632 <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc0205612:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0205614:	0e0c8e63          	beqz	s9,ffffffffc0205710 <vprintfmt+0x310>
ffffffffc0205618:	3781                	addiw	a5,a5,-32
ffffffffc020561a:	0ef47b63          	bgeu	s0,a5,ffffffffc0205710 <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc020561e:	03f00513          	li	a0,63
ffffffffc0205622:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205624:	000a4783          	lbu	a5,0(s4)
ffffffffc0205628:	3dfd                	addiw	s11,s11,-1
ffffffffc020562a:	0a05                	addi	s4,s4,1
ffffffffc020562c:	0007851b          	sext.w	a0,a5
ffffffffc0205630:	ffe1                	bnez	a5,ffffffffc0205608 <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc0205632:	01b05963          	blez	s11,ffffffffc0205644 <vprintfmt+0x244>
ffffffffc0205636:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0205638:	85a6                	mv	a1,s1
ffffffffc020563a:	02000513          	li	a0,32
ffffffffc020563e:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0205640:	fe0d9be3          	bnez	s11,ffffffffc0205636 <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0205644:	6a02                	ld	s4,0(sp)
ffffffffc0205646:	bbd5                	j	ffffffffc020543a <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0205648:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc020564a:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc020564e:	01174463          	blt	a4,a7,ffffffffc0205656 <vprintfmt+0x256>
    else if (lflag) {
ffffffffc0205652:	08088d63          	beqz	a7,ffffffffc02056ec <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc0205656:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc020565a:	0a044d63          	bltz	s0,ffffffffc0205714 <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc020565e:	8622                	mv	a2,s0
ffffffffc0205660:	8a66                	mv	s4,s9
ffffffffc0205662:	46a9                	li	a3,10
ffffffffc0205664:	bdcd                	j	ffffffffc0205556 <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc0205666:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc020566a:	4761                	li	a4,24
            err = va_arg(ap, int);
ffffffffc020566c:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc020566e:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc0205672:	8fb5                	xor	a5,a5,a3
ffffffffc0205674:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0205678:	02d74163          	blt	a4,a3,ffffffffc020569a <vprintfmt+0x29a>
ffffffffc020567c:	00369793          	slli	a5,a3,0x3
ffffffffc0205680:	97de                	add	a5,a5,s7
ffffffffc0205682:	639c                	ld	a5,0(a5)
ffffffffc0205684:	cb99                	beqz	a5,ffffffffc020569a <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc0205686:	86be                	mv	a3,a5
ffffffffc0205688:	00000617          	auipc	a2,0x0
ffffffffc020568c:	1f060613          	addi	a2,a2,496 # ffffffffc0205878 <etext+0x2a>
ffffffffc0205690:	85a6                	mv	a1,s1
ffffffffc0205692:	854a                	mv	a0,s2
ffffffffc0205694:	0ce000ef          	jal	ra,ffffffffc0205762 <printfmt>
ffffffffc0205698:	b34d                	j	ffffffffc020543a <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc020569a:	00002617          	auipc	a2,0x2
ffffffffc020569e:	73e60613          	addi	a2,a2,1854 # ffffffffc0207dd8 <syscalls+0x820>
ffffffffc02056a2:	85a6                	mv	a1,s1
ffffffffc02056a4:	854a                	mv	a0,s2
ffffffffc02056a6:	0bc000ef          	jal	ra,ffffffffc0205762 <printfmt>
ffffffffc02056aa:	bb41                	j	ffffffffc020543a <vprintfmt+0x3a>
                p = "(null)";
ffffffffc02056ac:	00002417          	auipc	s0,0x2
ffffffffc02056b0:	72440413          	addi	s0,s0,1828 # ffffffffc0207dd0 <syscalls+0x818>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02056b4:	85e2                	mv	a1,s8
ffffffffc02056b6:	8522                	mv	a0,s0
ffffffffc02056b8:	e43e                	sd	a5,8(sp)
ffffffffc02056ba:	0e2000ef          	jal	ra,ffffffffc020579c <strnlen>
ffffffffc02056be:	40ad8dbb          	subw	s11,s11,a0
ffffffffc02056c2:	01b05b63          	blez	s11,ffffffffc02056d8 <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc02056c6:	67a2                	ld	a5,8(sp)
ffffffffc02056c8:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02056cc:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc02056ce:	85a6                	mv	a1,s1
ffffffffc02056d0:	8552                	mv	a0,s4
ffffffffc02056d2:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02056d4:	fe0d9ce3          	bnez	s11,ffffffffc02056cc <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02056d8:	00044783          	lbu	a5,0(s0)
ffffffffc02056dc:	00140a13          	addi	s4,s0,1
ffffffffc02056e0:	0007851b          	sext.w	a0,a5
ffffffffc02056e4:	d3a5                	beqz	a5,ffffffffc0205644 <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02056e6:	05e00413          	li	s0,94
ffffffffc02056ea:	bf39                	j	ffffffffc0205608 <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc02056ec:	000a2403          	lw	s0,0(s4)
ffffffffc02056f0:	b7ad                	j	ffffffffc020565a <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc02056f2:	000a6603          	lwu	a2,0(s4)
ffffffffc02056f6:	46a1                	li	a3,8
ffffffffc02056f8:	8a2e                	mv	s4,a1
ffffffffc02056fa:	bdb1                	j	ffffffffc0205556 <vprintfmt+0x156>
ffffffffc02056fc:	000a6603          	lwu	a2,0(s4)
ffffffffc0205700:	46a9                	li	a3,10
ffffffffc0205702:	8a2e                	mv	s4,a1
ffffffffc0205704:	bd89                	j	ffffffffc0205556 <vprintfmt+0x156>
ffffffffc0205706:	000a6603          	lwu	a2,0(s4)
ffffffffc020570a:	46c1                	li	a3,16
ffffffffc020570c:	8a2e                	mv	s4,a1
ffffffffc020570e:	b5a1                	j	ffffffffc0205556 <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc0205710:	9902                	jalr	s2
ffffffffc0205712:	bf09                	j	ffffffffc0205624 <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc0205714:	85a6                	mv	a1,s1
ffffffffc0205716:	02d00513          	li	a0,45
ffffffffc020571a:	e03e                	sd	a5,0(sp)
ffffffffc020571c:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc020571e:	6782                	ld	a5,0(sp)
ffffffffc0205720:	8a66                	mv	s4,s9
ffffffffc0205722:	40800633          	neg	a2,s0
ffffffffc0205726:	46a9                	li	a3,10
ffffffffc0205728:	b53d                	j	ffffffffc0205556 <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc020572a:	03b05163          	blez	s11,ffffffffc020574c <vprintfmt+0x34c>
ffffffffc020572e:	02d00693          	li	a3,45
ffffffffc0205732:	f6d79de3          	bne	a5,a3,ffffffffc02056ac <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc0205736:	00002417          	auipc	s0,0x2
ffffffffc020573a:	69a40413          	addi	s0,s0,1690 # ffffffffc0207dd0 <syscalls+0x818>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020573e:	02800793          	li	a5,40
ffffffffc0205742:	02800513          	li	a0,40
ffffffffc0205746:	00140a13          	addi	s4,s0,1
ffffffffc020574a:	bd6d                	j	ffffffffc0205604 <vprintfmt+0x204>
ffffffffc020574c:	00002a17          	auipc	s4,0x2
ffffffffc0205750:	685a0a13          	addi	s4,s4,1669 # ffffffffc0207dd1 <syscalls+0x819>
ffffffffc0205754:	02800513          	li	a0,40
ffffffffc0205758:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc020575c:	05e00413          	li	s0,94
ffffffffc0205760:	b565                	j	ffffffffc0205608 <vprintfmt+0x208>

ffffffffc0205762 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0205762:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0205764:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0205768:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc020576a:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc020576c:	ec06                	sd	ra,24(sp)
ffffffffc020576e:	f83a                	sd	a4,48(sp)
ffffffffc0205770:	fc3e                	sd	a5,56(sp)
ffffffffc0205772:	e0c2                	sd	a6,64(sp)
ffffffffc0205774:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0205776:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0205778:	c89ff0ef          	jal	ra,ffffffffc0205400 <vprintfmt>
}
ffffffffc020577c:	60e2                	ld	ra,24(sp)
ffffffffc020577e:	6161                	addi	sp,sp,80
ffffffffc0205780:	8082                	ret

ffffffffc0205782 <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0205782:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc0205786:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc0205788:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc020578a:	cb81                	beqz	a5,ffffffffc020579a <strlen+0x18>
        cnt ++;
ffffffffc020578c:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc020578e:	00a707b3          	add	a5,a4,a0
ffffffffc0205792:	0007c783          	lbu	a5,0(a5)
ffffffffc0205796:	fbfd                	bnez	a5,ffffffffc020578c <strlen+0xa>
ffffffffc0205798:	8082                	ret
    }
    return cnt;
}
ffffffffc020579a:	8082                	ret

ffffffffc020579c <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc020579c:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc020579e:	e589                	bnez	a1,ffffffffc02057a8 <strnlen+0xc>
ffffffffc02057a0:	a811                	j	ffffffffc02057b4 <strnlen+0x18>
        cnt ++;
ffffffffc02057a2:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc02057a4:	00f58863          	beq	a1,a5,ffffffffc02057b4 <strnlen+0x18>
ffffffffc02057a8:	00f50733          	add	a4,a0,a5
ffffffffc02057ac:	00074703          	lbu	a4,0(a4)
ffffffffc02057b0:	fb6d                	bnez	a4,ffffffffc02057a2 <strnlen+0x6>
ffffffffc02057b2:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc02057b4:	852e                	mv	a0,a1
ffffffffc02057b6:	8082                	ret

ffffffffc02057b8 <strcpy>:
char *
strcpy(char *dst, const char *src) {
#ifdef __HAVE_ARCH_STRCPY
    return __strcpy(dst, src);
#else
    char *p = dst;
ffffffffc02057b8:	87aa                	mv	a5,a0
    while ((*p ++ = *src ++) != '\0')
ffffffffc02057ba:	0005c703          	lbu	a4,0(a1)
ffffffffc02057be:	0785                	addi	a5,a5,1
ffffffffc02057c0:	0585                	addi	a1,a1,1
ffffffffc02057c2:	fee78fa3          	sb	a4,-1(a5)
ffffffffc02057c6:	fb75                	bnez	a4,ffffffffc02057ba <strcpy+0x2>
        /* nothing */;
    return dst;
#endif /* __HAVE_ARCH_STRCPY */
}
ffffffffc02057c8:	8082                	ret

ffffffffc02057ca <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02057ca:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02057ce:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02057d2:	cb89                	beqz	a5,ffffffffc02057e4 <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc02057d4:	0505                	addi	a0,a0,1
ffffffffc02057d6:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02057d8:	fee789e3          	beq	a5,a4,ffffffffc02057ca <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02057dc:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc02057e0:	9d19                	subw	a0,a0,a4
ffffffffc02057e2:	8082                	ret
ffffffffc02057e4:	4501                	li	a0,0
ffffffffc02057e6:	bfed                	j	ffffffffc02057e0 <strcmp+0x16>

ffffffffc02057e8 <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc02057e8:	c20d                	beqz	a2,ffffffffc020580a <strncmp+0x22>
ffffffffc02057ea:	962e                	add	a2,a2,a1
ffffffffc02057ec:	a031                	j	ffffffffc02057f8 <strncmp+0x10>
        n --, s1 ++, s2 ++;
ffffffffc02057ee:	0505                	addi	a0,a0,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc02057f0:	00e79a63          	bne	a5,a4,ffffffffc0205804 <strncmp+0x1c>
ffffffffc02057f4:	00b60b63          	beq	a2,a1,ffffffffc020580a <strncmp+0x22>
ffffffffc02057f8:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc02057fc:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc02057fe:	fff5c703          	lbu	a4,-1(a1)
ffffffffc0205802:	f7f5                	bnez	a5,ffffffffc02057ee <strncmp+0x6>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0205804:	40e7853b          	subw	a0,a5,a4
}
ffffffffc0205808:	8082                	ret
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc020580a:	4501                	li	a0,0
ffffffffc020580c:	8082                	ret

ffffffffc020580e <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc020580e:	00054783          	lbu	a5,0(a0)
ffffffffc0205812:	c799                	beqz	a5,ffffffffc0205820 <strchr+0x12>
        if (*s == c) {
ffffffffc0205814:	00f58763          	beq	a1,a5,ffffffffc0205822 <strchr+0x14>
    while (*s != '\0') {
ffffffffc0205818:	00154783          	lbu	a5,1(a0)
            return (char *)s;
        }
        s ++;
ffffffffc020581c:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc020581e:	fbfd                	bnez	a5,ffffffffc0205814 <strchr+0x6>
    }
    return NULL;
ffffffffc0205820:	4501                	li	a0,0
}
ffffffffc0205822:	8082                	ret

ffffffffc0205824 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0205824:	ca01                	beqz	a2,ffffffffc0205834 <memset+0x10>
ffffffffc0205826:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0205828:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc020582a:	0785                	addi	a5,a5,1
ffffffffc020582c:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0205830:	fec79de3          	bne	a5,a2,ffffffffc020582a <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0205834:	8082                	ret

ffffffffc0205836 <memcpy>:
#ifdef __HAVE_ARCH_MEMCPY
    return __memcpy(dst, src, n);
#else
    const char *s = src;
    char *d = dst;
    while (n -- > 0) {
ffffffffc0205836:	ca19                	beqz	a2,ffffffffc020584c <memcpy+0x16>
ffffffffc0205838:	962e                	add	a2,a2,a1
    char *d = dst;
ffffffffc020583a:	87aa                	mv	a5,a0
        *d ++ = *s ++;
ffffffffc020583c:	0005c703          	lbu	a4,0(a1)
ffffffffc0205840:	0585                	addi	a1,a1,1
ffffffffc0205842:	0785                	addi	a5,a5,1
ffffffffc0205844:	fee78fa3          	sb	a4,-1(a5)
    while (n -- > 0) {
ffffffffc0205848:	fec59ae3          	bne	a1,a2,ffffffffc020583c <memcpy+0x6>
    }
    return dst;
#endif /* __HAVE_ARCH_MEMCPY */
}
ffffffffc020584c:	8082                	ret
