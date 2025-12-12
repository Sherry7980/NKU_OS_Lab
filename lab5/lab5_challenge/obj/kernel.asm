
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	0000b297          	auipc	t0,0xb
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc020b000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	0000b297          	auipc	t0,0xb
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc020b008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)
    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c020a2b7          	lui	t0,0xc020a
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
ffffffffc020003c:	c020a137          	lui	sp,0xc020a

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
ffffffffc020004a:	000bb517          	auipc	a0,0xbb
ffffffffc020004e:	72e50513          	addi	a0,a0,1838 # ffffffffc02bb778 <buf>
ffffffffc0200052:	000c0617          	auipc	a2,0xc0
ffffffffc0200056:	bca60613          	addi	a2,a2,-1078 # ffffffffc02bfc1c <end>
{
ffffffffc020005a:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc020005c:	8e09                	sub	a2,a2,a0
ffffffffc020005e:	4581                	li	a1,0
{
ffffffffc0200060:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc0200062:	7da050ef          	jal	ra,ffffffffc020583c <memset>
    dtb_init();
ffffffffc0200066:	598000ef          	jal	ra,ffffffffc02005fe <dtb_init>
    cons_init(); // init the console
ffffffffc020006a:	522000ef          	jal	ra,ffffffffc020058c <cons_init>

    const char *message = "(THU.CST) os is loading ...";
    cprintf("%s\n\n", message);
ffffffffc020006e:	00005597          	auipc	a1,0x5
ffffffffc0200072:	7fa58593          	addi	a1,a1,2042 # ffffffffc0205868 <etext+0x2>
ffffffffc0200076:	00006517          	auipc	a0,0x6
ffffffffc020007a:	81250513          	addi	a0,a0,-2030 # ffffffffc0205888 <etext+0x22>
ffffffffc020007e:	116000ef          	jal	ra,ffffffffc0200194 <cprintf>

    print_kerninfo();
ffffffffc0200082:	19a000ef          	jal	ra,ffffffffc020021c <print_kerninfo>

    // grade_backtrace();

    pmm_init(); // init physical memory management
ffffffffc0200086:	297020ef          	jal	ra,ffffffffc0202b1c <pmm_init>

    pic_init(); // init interrupt controller
ffffffffc020008a:	131000ef          	jal	ra,ffffffffc02009ba <pic_init>
    idt_init(); // init interrupt descriptor table
ffffffffc020008e:	12f000ef          	jal	ra,ffffffffc02009bc <idt_init>

    vmm_init();  // init virtual memory management
ffffffffc0200092:	303030ef          	jal	ra,ffffffffc0203b94 <vmm_init>
    proc_init(); // init process table
ffffffffc0200096:	6f9040ef          	jal	ra,ffffffffc0204f8e <proc_init>

    clock_init();  // init clock interrupt
ffffffffc020009a:	4a0000ef          	jal	ra,ffffffffc020053a <clock_init>
    intr_enable(); // enable irq interrupt
ffffffffc020009e:	111000ef          	jal	ra,ffffffffc02009ae <intr_enable>

    cpu_idle(); // run idle process
ffffffffc02000a2:	084050ef          	jal	ra,ffffffffc0205126 <cpu_idle>

ffffffffc02000a6 <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc02000a6:	715d                	addi	sp,sp,-80
ffffffffc02000a8:	e486                	sd	ra,72(sp)
ffffffffc02000aa:	e0a6                	sd	s1,64(sp)
ffffffffc02000ac:	fc4a                	sd	s2,56(sp)
ffffffffc02000ae:	f84e                	sd	s3,48(sp)
ffffffffc02000b0:	f452                	sd	s4,40(sp)
ffffffffc02000b2:	f056                	sd	s5,32(sp)
ffffffffc02000b4:	ec5a                	sd	s6,24(sp)
ffffffffc02000b6:	e85e                	sd	s7,16(sp)
    if (prompt != NULL) {
ffffffffc02000b8:	c901                	beqz	a0,ffffffffc02000c8 <readline+0x22>
ffffffffc02000ba:	85aa                	mv	a1,a0
        cprintf("%s", prompt);
ffffffffc02000bc:	00005517          	auipc	a0,0x5
ffffffffc02000c0:	7d450513          	addi	a0,a0,2004 # ffffffffc0205890 <etext+0x2a>
ffffffffc02000c4:	0d0000ef          	jal	ra,ffffffffc0200194 <cprintf>
readline(const char *prompt) {
ffffffffc02000c8:	4481                	li	s1,0
    while (1) {
        c = getchar();
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000ca:	497d                	li	s2,31
            cputchar(c);
            buf[i ++] = c;
        }
        else if (c == '\b' && i > 0) {
ffffffffc02000cc:	49a1                	li	s3,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc02000ce:	4aa9                	li	s5,10
ffffffffc02000d0:	4b35                	li	s6,13
            buf[i ++] = c;
ffffffffc02000d2:	000bbb97          	auipc	s7,0xbb
ffffffffc02000d6:	6a6b8b93          	addi	s7,s7,1702 # ffffffffc02bb778 <buf>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000da:	3fe00a13          	li	s4,1022
        c = getchar();
ffffffffc02000de:	12e000ef          	jal	ra,ffffffffc020020c <getchar>
        if (c < 0) {
ffffffffc02000e2:	00054a63          	bltz	a0,ffffffffc02000f6 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000e6:	00a95a63          	bge	s2,a0,ffffffffc02000fa <readline+0x54>
ffffffffc02000ea:	029a5263          	bge	s4,s1,ffffffffc020010e <readline+0x68>
        c = getchar();
ffffffffc02000ee:	11e000ef          	jal	ra,ffffffffc020020c <getchar>
        if (c < 0) {
ffffffffc02000f2:	fe055ae3          	bgez	a0,ffffffffc02000e6 <readline+0x40>
            return NULL;
ffffffffc02000f6:	4501                	li	a0,0
ffffffffc02000f8:	a091                	j	ffffffffc020013c <readline+0x96>
        else if (c == '\b' && i > 0) {
ffffffffc02000fa:	03351463          	bne	a0,s3,ffffffffc0200122 <readline+0x7c>
ffffffffc02000fe:	e8a9                	bnez	s1,ffffffffc0200150 <readline+0xaa>
        c = getchar();
ffffffffc0200100:	10c000ef          	jal	ra,ffffffffc020020c <getchar>
        if (c < 0) {
ffffffffc0200104:	fe0549e3          	bltz	a0,ffffffffc02000f6 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0200108:	fea959e3          	bge	s2,a0,ffffffffc02000fa <readline+0x54>
ffffffffc020010c:	4481                	li	s1,0
            cputchar(c);
ffffffffc020010e:	e42a                	sd	a0,8(sp)
ffffffffc0200110:	0ba000ef          	jal	ra,ffffffffc02001ca <cputchar>
            buf[i ++] = c;
ffffffffc0200114:	6522                	ld	a0,8(sp)
ffffffffc0200116:	009b87b3          	add	a5,s7,s1
ffffffffc020011a:	2485                	addiw	s1,s1,1
ffffffffc020011c:	00a78023          	sb	a0,0(a5)
ffffffffc0200120:	bf7d                	j	ffffffffc02000de <readline+0x38>
        else if (c == '\n' || c == '\r') {
ffffffffc0200122:	01550463          	beq	a0,s5,ffffffffc020012a <readline+0x84>
ffffffffc0200126:	fb651ce3          	bne	a0,s6,ffffffffc02000de <readline+0x38>
            cputchar(c);
ffffffffc020012a:	0a0000ef          	jal	ra,ffffffffc02001ca <cputchar>
            buf[i] = '\0';
ffffffffc020012e:	000bb517          	auipc	a0,0xbb
ffffffffc0200132:	64a50513          	addi	a0,a0,1610 # ffffffffc02bb778 <buf>
ffffffffc0200136:	94aa                	add	s1,s1,a0
ffffffffc0200138:	00048023          	sb	zero,0(s1)
            return buf;
        }
    }
}
ffffffffc020013c:	60a6                	ld	ra,72(sp)
ffffffffc020013e:	6486                	ld	s1,64(sp)
ffffffffc0200140:	7962                	ld	s2,56(sp)
ffffffffc0200142:	79c2                	ld	s3,48(sp)
ffffffffc0200144:	7a22                	ld	s4,40(sp)
ffffffffc0200146:	7a82                	ld	s5,32(sp)
ffffffffc0200148:	6b62                	ld	s6,24(sp)
ffffffffc020014a:	6bc2                	ld	s7,16(sp)
ffffffffc020014c:	6161                	addi	sp,sp,80
ffffffffc020014e:	8082                	ret
            cputchar(c);
ffffffffc0200150:	4521                	li	a0,8
ffffffffc0200152:	078000ef          	jal	ra,ffffffffc02001ca <cputchar>
            i --;
ffffffffc0200156:	34fd                	addiw	s1,s1,-1
ffffffffc0200158:	b759                	j	ffffffffc02000de <readline+0x38>

ffffffffc020015a <cputch>:
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt)
{
ffffffffc020015a:	1141                	addi	sp,sp,-16
ffffffffc020015c:	e022                	sd	s0,0(sp)
ffffffffc020015e:	e406                	sd	ra,8(sp)
ffffffffc0200160:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc0200162:	42c000ef          	jal	ra,ffffffffc020058e <cons_putc>
    (*cnt)++;
ffffffffc0200166:	401c                	lw	a5,0(s0)
}
ffffffffc0200168:	60a2                	ld	ra,8(sp)
    (*cnt)++;
ffffffffc020016a:	2785                	addiw	a5,a5,1
ffffffffc020016c:	c01c                	sw	a5,0(s0)
}
ffffffffc020016e:	6402                	ld	s0,0(sp)
ffffffffc0200170:	0141                	addi	sp,sp,16
ffffffffc0200172:	8082                	ret

ffffffffc0200174 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int vcprintf(const char *fmt, va_list ap)
{
ffffffffc0200174:	1101                	addi	sp,sp,-32
ffffffffc0200176:	862a                	mv	a2,a0
ffffffffc0200178:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc020017a:	00000517          	auipc	a0,0x0
ffffffffc020017e:	fe050513          	addi	a0,a0,-32 # ffffffffc020015a <cputch>
ffffffffc0200182:	006c                	addi	a1,sp,12
{
ffffffffc0200184:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc0200186:	c602                	sw	zero,12(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc0200188:	290050ef          	jal	ra,ffffffffc0205418 <vprintfmt>
    return cnt;
}
ffffffffc020018c:	60e2                	ld	ra,24(sp)
ffffffffc020018e:	4532                	lw	a0,12(sp)
ffffffffc0200190:	6105                	addi	sp,sp,32
ffffffffc0200192:	8082                	ret

ffffffffc0200194 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int cprintf(const char *fmt, ...)
{
ffffffffc0200194:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc0200196:	02810313          	addi	t1,sp,40 # ffffffffc020a028 <boot_page_table_sv39+0x28>
{
ffffffffc020019a:	8e2a                	mv	t3,a0
ffffffffc020019c:	f42e                	sd	a1,40(sp)
ffffffffc020019e:	f832                	sd	a2,48(sp)
ffffffffc02001a0:	fc36                	sd	a3,56(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc02001a2:	00000517          	auipc	a0,0x0
ffffffffc02001a6:	fb850513          	addi	a0,a0,-72 # ffffffffc020015a <cputch>
ffffffffc02001aa:	004c                	addi	a1,sp,4
ffffffffc02001ac:	869a                	mv	a3,t1
ffffffffc02001ae:	8672                	mv	a2,t3
{
ffffffffc02001b0:	ec06                	sd	ra,24(sp)
ffffffffc02001b2:	e0ba                	sd	a4,64(sp)
ffffffffc02001b4:	e4be                	sd	a5,72(sp)
ffffffffc02001b6:	e8c2                	sd	a6,80(sp)
ffffffffc02001b8:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc02001ba:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc02001bc:	c202                	sw	zero,4(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc02001be:	25a050ef          	jal	ra,ffffffffc0205418 <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc02001c2:	60e2                	ld	ra,24(sp)
ffffffffc02001c4:	4512                	lw	a0,4(sp)
ffffffffc02001c6:	6125                	addi	sp,sp,96
ffffffffc02001c8:	8082                	ret

ffffffffc02001ca <cputchar>:

/* cputchar - writes a single character to stdout */
void cputchar(int c)
{
    cons_putc(c);
ffffffffc02001ca:	a6d1                	j	ffffffffc020058e <cons_putc>

ffffffffc02001cc <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int cputs(const char *str)
{
ffffffffc02001cc:	1101                	addi	sp,sp,-32
ffffffffc02001ce:	e822                	sd	s0,16(sp)
ffffffffc02001d0:	ec06                	sd	ra,24(sp)
ffffffffc02001d2:	e426                	sd	s1,8(sp)
ffffffffc02001d4:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str++) != '\0')
ffffffffc02001d6:	00054503          	lbu	a0,0(a0)
ffffffffc02001da:	c51d                	beqz	a0,ffffffffc0200208 <cputs+0x3c>
ffffffffc02001dc:	0405                	addi	s0,s0,1
ffffffffc02001de:	4485                	li	s1,1
ffffffffc02001e0:	9c81                	subw	s1,s1,s0
    cons_putc(c);
ffffffffc02001e2:	3ac000ef          	jal	ra,ffffffffc020058e <cons_putc>
    while ((c = *str++) != '\0')
ffffffffc02001e6:	00044503          	lbu	a0,0(s0)
ffffffffc02001ea:	008487bb          	addw	a5,s1,s0
ffffffffc02001ee:	0405                	addi	s0,s0,1
ffffffffc02001f0:	f96d                	bnez	a0,ffffffffc02001e2 <cputs+0x16>
    (*cnt)++;
ffffffffc02001f2:	0017841b          	addiw	s0,a5,1
    cons_putc(c);
ffffffffc02001f6:	4529                	li	a0,10
ffffffffc02001f8:	396000ef          	jal	ra,ffffffffc020058e <cons_putc>
    {
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc02001fc:	60e2                	ld	ra,24(sp)
ffffffffc02001fe:	8522                	mv	a0,s0
ffffffffc0200200:	6442                	ld	s0,16(sp)
ffffffffc0200202:	64a2                	ld	s1,8(sp)
ffffffffc0200204:	6105                	addi	sp,sp,32
ffffffffc0200206:	8082                	ret
    while ((c = *str++) != '\0')
ffffffffc0200208:	4405                	li	s0,1
ffffffffc020020a:	b7f5                	j	ffffffffc02001f6 <cputs+0x2a>

ffffffffc020020c <getchar>:

/* getchar - reads a single non-zero character from stdin */
int getchar(void)
{
ffffffffc020020c:	1141                	addi	sp,sp,-16
ffffffffc020020e:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc0200210:	3b2000ef          	jal	ra,ffffffffc02005c2 <cons_getc>
ffffffffc0200214:	dd75                	beqz	a0,ffffffffc0200210 <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc0200216:	60a2                	ld	ra,8(sp)
ffffffffc0200218:	0141                	addi	sp,sp,16
ffffffffc020021a:	8082                	ret

ffffffffc020021c <print_kerninfo>:
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void)
{
ffffffffc020021c:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc020021e:	00005517          	auipc	a0,0x5
ffffffffc0200222:	67a50513          	addi	a0,a0,1658 # ffffffffc0205898 <etext+0x32>
{
ffffffffc0200226:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200228:	f6dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  entry  0x%08x (virtual)\n", kern_init);
ffffffffc020022c:	00000597          	auipc	a1,0x0
ffffffffc0200230:	e1e58593          	addi	a1,a1,-482 # ffffffffc020004a <kern_init>
ffffffffc0200234:	00005517          	auipc	a0,0x5
ffffffffc0200238:	68450513          	addi	a0,a0,1668 # ffffffffc02058b8 <etext+0x52>
ffffffffc020023c:	f59ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  etext  0x%08x (virtual)\n", etext);
ffffffffc0200240:	00005597          	auipc	a1,0x5
ffffffffc0200244:	62658593          	addi	a1,a1,1574 # ffffffffc0205866 <etext>
ffffffffc0200248:	00005517          	auipc	a0,0x5
ffffffffc020024c:	69050513          	addi	a0,a0,1680 # ffffffffc02058d8 <etext+0x72>
ffffffffc0200250:	f45ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  edata  0x%08x (virtual)\n", edata);
ffffffffc0200254:	000bb597          	auipc	a1,0xbb
ffffffffc0200258:	52458593          	addi	a1,a1,1316 # ffffffffc02bb778 <buf>
ffffffffc020025c:	00005517          	auipc	a0,0x5
ffffffffc0200260:	69c50513          	addi	a0,a0,1692 # ffffffffc02058f8 <etext+0x92>
ffffffffc0200264:	f31ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  end    0x%08x (virtual)\n", end);
ffffffffc0200268:	000c0597          	auipc	a1,0xc0
ffffffffc020026c:	9b458593          	addi	a1,a1,-1612 # ffffffffc02bfc1c <end>
ffffffffc0200270:	00005517          	auipc	a0,0x5
ffffffffc0200274:	6a850513          	addi	a0,a0,1704 # ffffffffc0205918 <etext+0xb2>
ffffffffc0200278:	f1dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc020027c:	000c0597          	auipc	a1,0xc0
ffffffffc0200280:	d9f58593          	addi	a1,a1,-609 # ffffffffc02c001b <end+0x3ff>
ffffffffc0200284:	00000797          	auipc	a5,0x0
ffffffffc0200288:	dc678793          	addi	a5,a5,-570 # ffffffffc020004a <kern_init>
ffffffffc020028c:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200290:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc0200294:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200296:	3ff5f593          	andi	a1,a1,1023
ffffffffc020029a:	95be                	add	a1,a1,a5
ffffffffc020029c:	85a9                	srai	a1,a1,0xa
ffffffffc020029e:	00005517          	auipc	a0,0x5
ffffffffc02002a2:	69a50513          	addi	a0,a0,1690 # ffffffffc0205938 <etext+0xd2>
}
ffffffffc02002a6:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02002a8:	b5f5                	j	ffffffffc0200194 <cprintf>

ffffffffc02002aa <print_stackframe>:
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void)
{
ffffffffc02002aa:	1141                	addi	sp,sp,-16
    panic("Not Implemented!");
ffffffffc02002ac:	00005617          	auipc	a2,0x5
ffffffffc02002b0:	6bc60613          	addi	a2,a2,1724 # ffffffffc0205968 <etext+0x102>
ffffffffc02002b4:	04f00593          	li	a1,79
ffffffffc02002b8:	00005517          	auipc	a0,0x5
ffffffffc02002bc:	6c850513          	addi	a0,a0,1736 # ffffffffc0205980 <etext+0x11a>
{
ffffffffc02002c0:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc02002c2:	1cc000ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02002c6 <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int mon_help(int argc, char **argv, struct trapframe *tf)
{
ffffffffc02002c6:	1141                	addi	sp,sp,-16
    int i;
    for (i = 0; i < NCOMMANDS; i++)
    {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02002c8:	00005617          	auipc	a2,0x5
ffffffffc02002cc:	6d060613          	addi	a2,a2,1744 # ffffffffc0205998 <etext+0x132>
ffffffffc02002d0:	00005597          	auipc	a1,0x5
ffffffffc02002d4:	6e858593          	addi	a1,a1,1768 # ffffffffc02059b8 <etext+0x152>
ffffffffc02002d8:	00005517          	auipc	a0,0x5
ffffffffc02002dc:	6e850513          	addi	a0,a0,1768 # ffffffffc02059c0 <etext+0x15a>
{
ffffffffc02002e0:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02002e2:	eb3ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc02002e6:	00005617          	auipc	a2,0x5
ffffffffc02002ea:	6ea60613          	addi	a2,a2,1770 # ffffffffc02059d0 <etext+0x16a>
ffffffffc02002ee:	00005597          	auipc	a1,0x5
ffffffffc02002f2:	70a58593          	addi	a1,a1,1802 # ffffffffc02059f8 <etext+0x192>
ffffffffc02002f6:	00005517          	auipc	a0,0x5
ffffffffc02002fa:	6ca50513          	addi	a0,a0,1738 # ffffffffc02059c0 <etext+0x15a>
ffffffffc02002fe:	e97ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc0200302:	00005617          	auipc	a2,0x5
ffffffffc0200306:	70660613          	addi	a2,a2,1798 # ffffffffc0205a08 <etext+0x1a2>
ffffffffc020030a:	00005597          	auipc	a1,0x5
ffffffffc020030e:	71e58593          	addi	a1,a1,1822 # ffffffffc0205a28 <etext+0x1c2>
ffffffffc0200312:	00005517          	auipc	a0,0x5
ffffffffc0200316:	6ae50513          	addi	a0,a0,1710 # ffffffffc02059c0 <etext+0x15a>
ffffffffc020031a:	e7bff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    }
    return 0;
}
ffffffffc020031e:	60a2                	ld	ra,8(sp)
ffffffffc0200320:	4501                	li	a0,0
ffffffffc0200322:	0141                	addi	sp,sp,16
ffffffffc0200324:	8082                	ret

ffffffffc0200326 <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int mon_kerninfo(int argc, char **argv, struct trapframe *tf)
{
ffffffffc0200326:	1141                	addi	sp,sp,-16
ffffffffc0200328:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc020032a:	ef3ff0ef          	jal	ra,ffffffffc020021c <print_kerninfo>
    return 0;
}
ffffffffc020032e:	60a2                	ld	ra,8(sp)
ffffffffc0200330:	4501                	li	a0,0
ffffffffc0200332:	0141                	addi	sp,sp,16
ffffffffc0200334:	8082                	ret

ffffffffc0200336 <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int mon_backtrace(int argc, char **argv, struct trapframe *tf)
{
ffffffffc0200336:	1141                	addi	sp,sp,-16
ffffffffc0200338:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc020033a:	f71ff0ef          	jal	ra,ffffffffc02002aa <print_stackframe>
    return 0;
}
ffffffffc020033e:	60a2                	ld	ra,8(sp)
ffffffffc0200340:	4501                	li	a0,0
ffffffffc0200342:	0141                	addi	sp,sp,16
ffffffffc0200344:	8082                	ret

ffffffffc0200346 <kmonitor>:
{
ffffffffc0200346:	7115                	addi	sp,sp,-224
ffffffffc0200348:	ed5e                	sd	s7,152(sp)
ffffffffc020034a:	8baa                	mv	s7,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc020034c:	00005517          	auipc	a0,0x5
ffffffffc0200350:	6ec50513          	addi	a0,a0,1772 # ffffffffc0205a38 <etext+0x1d2>
{
ffffffffc0200354:	ed86                	sd	ra,216(sp)
ffffffffc0200356:	e9a2                	sd	s0,208(sp)
ffffffffc0200358:	e5a6                	sd	s1,200(sp)
ffffffffc020035a:	e1ca                	sd	s2,192(sp)
ffffffffc020035c:	fd4e                	sd	s3,184(sp)
ffffffffc020035e:	f952                	sd	s4,176(sp)
ffffffffc0200360:	f556                	sd	s5,168(sp)
ffffffffc0200362:	f15a                	sd	s6,160(sp)
ffffffffc0200364:	e962                	sd	s8,144(sp)
ffffffffc0200366:	e566                	sd	s9,136(sp)
ffffffffc0200368:	e16a                	sd	s10,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc020036a:	e2bff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc020036e:	00005517          	auipc	a0,0x5
ffffffffc0200372:	6f250513          	addi	a0,a0,1778 # ffffffffc0205a60 <etext+0x1fa>
ffffffffc0200376:	e1fff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    if (tf != NULL)
ffffffffc020037a:	000b8563          	beqz	s7,ffffffffc0200384 <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc020037e:	855e                	mv	a0,s7
ffffffffc0200380:	025000ef          	jal	ra,ffffffffc0200ba4 <print_trapframe>
ffffffffc0200384:	00005c17          	auipc	s8,0x5
ffffffffc0200388:	74cc0c13          	addi	s8,s8,1868 # ffffffffc0205ad0 <commands>
        if ((buf = readline("K> ")) != NULL)
ffffffffc020038c:	00005917          	auipc	s2,0x5
ffffffffc0200390:	6fc90913          	addi	s2,s2,1788 # ffffffffc0205a88 <etext+0x222>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc0200394:	00005497          	auipc	s1,0x5
ffffffffc0200398:	6fc48493          	addi	s1,s1,1788 # ffffffffc0205a90 <etext+0x22a>
        if (argc == MAXARGS - 1)
ffffffffc020039c:	49bd                	li	s3,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc020039e:	00005b17          	auipc	s6,0x5
ffffffffc02003a2:	6fab0b13          	addi	s6,s6,1786 # ffffffffc0205a98 <etext+0x232>
        argv[argc++] = buf;
ffffffffc02003a6:	00005a17          	auipc	s4,0x5
ffffffffc02003aa:	612a0a13          	addi	s4,s4,1554 # ffffffffc02059b8 <etext+0x152>
    for (i = 0; i < NCOMMANDS; i++)
ffffffffc02003ae:	4a8d                	li	s5,3
        if ((buf = readline("K> ")) != NULL)
ffffffffc02003b0:	854a                	mv	a0,s2
ffffffffc02003b2:	cf5ff0ef          	jal	ra,ffffffffc02000a6 <readline>
ffffffffc02003b6:	842a                	mv	s0,a0
ffffffffc02003b8:	dd65                	beqz	a0,ffffffffc02003b0 <kmonitor+0x6a>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc02003ba:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc02003be:	4c81                	li	s9,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc02003c0:	e1bd                	bnez	a1,ffffffffc0200426 <kmonitor+0xe0>
    if (argc == 0)
ffffffffc02003c2:	fe0c87e3          	beqz	s9,ffffffffc02003b0 <kmonitor+0x6a>
        if (strcmp(commands[i].name, argv[0]) == 0)
ffffffffc02003c6:	6582                	ld	a1,0(sp)
ffffffffc02003c8:	00005d17          	auipc	s10,0x5
ffffffffc02003cc:	708d0d13          	addi	s10,s10,1800 # ffffffffc0205ad0 <commands>
        argv[argc++] = buf;
ffffffffc02003d0:	8552                	mv	a0,s4
    for (i = 0; i < NCOMMANDS; i++)
ffffffffc02003d2:	4401                	li	s0,0
ffffffffc02003d4:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0)
ffffffffc02003d6:	40c050ef          	jal	ra,ffffffffc02057e2 <strcmp>
ffffffffc02003da:	c919                	beqz	a0,ffffffffc02003f0 <kmonitor+0xaa>
    for (i = 0; i < NCOMMANDS; i++)
ffffffffc02003dc:	2405                	addiw	s0,s0,1
ffffffffc02003de:	0b540063          	beq	s0,s5,ffffffffc020047e <kmonitor+0x138>
        if (strcmp(commands[i].name, argv[0]) == 0)
ffffffffc02003e2:	000d3503          	ld	a0,0(s10)
ffffffffc02003e6:	6582                	ld	a1,0(sp)
    for (i = 0; i < NCOMMANDS; i++)
ffffffffc02003e8:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0)
ffffffffc02003ea:	3f8050ef          	jal	ra,ffffffffc02057e2 <strcmp>
ffffffffc02003ee:	f57d                	bnez	a0,ffffffffc02003dc <kmonitor+0x96>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc02003f0:	00141793          	slli	a5,s0,0x1
ffffffffc02003f4:	97a2                	add	a5,a5,s0
ffffffffc02003f6:	078e                	slli	a5,a5,0x3
ffffffffc02003f8:	97e2                	add	a5,a5,s8
ffffffffc02003fa:	6b9c                	ld	a5,16(a5)
ffffffffc02003fc:	865e                	mv	a2,s7
ffffffffc02003fe:	002c                	addi	a1,sp,8
ffffffffc0200400:	fffc851b          	addiw	a0,s9,-1
ffffffffc0200404:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0)
ffffffffc0200406:	fa0555e3          	bgez	a0,ffffffffc02003b0 <kmonitor+0x6a>
}
ffffffffc020040a:	60ee                	ld	ra,216(sp)
ffffffffc020040c:	644e                	ld	s0,208(sp)
ffffffffc020040e:	64ae                	ld	s1,200(sp)
ffffffffc0200410:	690e                	ld	s2,192(sp)
ffffffffc0200412:	79ea                	ld	s3,184(sp)
ffffffffc0200414:	7a4a                	ld	s4,176(sp)
ffffffffc0200416:	7aaa                	ld	s5,168(sp)
ffffffffc0200418:	7b0a                	ld	s6,160(sp)
ffffffffc020041a:	6bea                	ld	s7,152(sp)
ffffffffc020041c:	6c4a                	ld	s8,144(sp)
ffffffffc020041e:	6caa                	ld	s9,136(sp)
ffffffffc0200420:	6d0a                	ld	s10,128(sp)
ffffffffc0200422:	612d                	addi	sp,sp,224
ffffffffc0200424:	8082                	ret
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc0200426:	8526                	mv	a0,s1
ffffffffc0200428:	3fe050ef          	jal	ra,ffffffffc0205826 <strchr>
ffffffffc020042c:	c901                	beqz	a0,ffffffffc020043c <kmonitor+0xf6>
ffffffffc020042e:	00144583          	lbu	a1,1(s0)
            *buf++ = '\0';
ffffffffc0200432:	00040023          	sb	zero,0(s0)
ffffffffc0200436:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc0200438:	d5c9                	beqz	a1,ffffffffc02003c2 <kmonitor+0x7c>
ffffffffc020043a:	b7f5                	j	ffffffffc0200426 <kmonitor+0xe0>
        if (*buf == '\0')
ffffffffc020043c:	00044783          	lbu	a5,0(s0)
ffffffffc0200440:	d3c9                	beqz	a5,ffffffffc02003c2 <kmonitor+0x7c>
        if (argc == MAXARGS - 1)
ffffffffc0200442:	033c8963          	beq	s9,s3,ffffffffc0200474 <kmonitor+0x12e>
        argv[argc++] = buf;
ffffffffc0200446:	003c9793          	slli	a5,s9,0x3
ffffffffc020044a:	0118                	addi	a4,sp,128
ffffffffc020044c:	97ba                	add	a5,a5,a4
ffffffffc020044e:	f887b023          	sd	s0,-128(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL)
ffffffffc0200452:	00044583          	lbu	a1,0(s0)
        argv[argc++] = buf;
ffffffffc0200456:	2c85                	addiw	s9,s9,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL)
ffffffffc0200458:	e591                	bnez	a1,ffffffffc0200464 <kmonitor+0x11e>
ffffffffc020045a:	b7b5                	j	ffffffffc02003c6 <kmonitor+0x80>
ffffffffc020045c:	00144583          	lbu	a1,1(s0)
            buf++;
ffffffffc0200460:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL)
ffffffffc0200462:	d1a5                	beqz	a1,ffffffffc02003c2 <kmonitor+0x7c>
ffffffffc0200464:	8526                	mv	a0,s1
ffffffffc0200466:	3c0050ef          	jal	ra,ffffffffc0205826 <strchr>
ffffffffc020046a:	d96d                	beqz	a0,ffffffffc020045c <kmonitor+0x116>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc020046c:	00044583          	lbu	a1,0(s0)
ffffffffc0200470:	d9a9                	beqz	a1,ffffffffc02003c2 <kmonitor+0x7c>
ffffffffc0200472:	bf55                	j	ffffffffc0200426 <kmonitor+0xe0>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc0200474:	45c1                	li	a1,16
ffffffffc0200476:	855a                	mv	a0,s6
ffffffffc0200478:	d1dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc020047c:	b7e9                	j	ffffffffc0200446 <kmonitor+0x100>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc020047e:	6582                	ld	a1,0(sp)
ffffffffc0200480:	00005517          	auipc	a0,0x5
ffffffffc0200484:	63850513          	addi	a0,a0,1592 # ffffffffc0205ab8 <etext+0x252>
ffffffffc0200488:	d0dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    return 0;
ffffffffc020048c:	b715                	j	ffffffffc02003b0 <kmonitor+0x6a>

ffffffffc020048e <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void __panic(const char *file, int line, const char *fmt, ...)
{
    if (is_panic)
ffffffffc020048e:	000bf317          	auipc	t1,0xbf
ffffffffc0200492:	71230313          	addi	t1,t1,1810 # ffffffffc02bfba0 <is_panic>
ffffffffc0200496:	00033e03          	ld	t3,0(t1)
{
ffffffffc020049a:	715d                	addi	sp,sp,-80
ffffffffc020049c:	ec06                	sd	ra,24(sp)
ffffffffc020049e:	e822                	sd	s0,16(sp)
ffffffffc02004a0:	f436                	sd	a3,40(sp)
ffffffffc02004a2:	f83a                	sd	a4,48(sp)
ffffffffc02004a4:	fc3e                	sd	a5,56(sp)
ffffffffc02004a6:	e0c2                	sd	a6,64(sp)
ffffffffc02004a8:	e4c6                	sd	a7,72(sp)
    if (is_panic)
ffffffffc02004aa:	020e1a63          	bnez	t3,ffffffffc02004de <__panic+0x50>
    {
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc02004ae:	4785                	li	a5,1
ffffffffc02004b0:	00f33023          	sd	a5,0(t1)

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
ffffffffc02004b4:	8432                	mv	s0,a2
ffffffffc02004b6:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02004b8:	862e                	mv	a2,a1
ffffffffc02004ba:	85aa                	mv	a1,a0
ffffffffc02004bc:	00005517          	auipc	a0,0x5
ffffffffc02004c0:	65c50513          	addi	a0,a0,1628 # ffffffffc0205b18 <commands+0x48>
    va_start(ap, fmt);
ffffffffc02004c4:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02004c6:	ccfff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    vcprintf(fmt, ap);
ffffffffc02004ca:	65a2                	ld	a1,8(sp)
ffffffffc02004cc:	8522                	mv	a0,s0
ffffffffc02004ce:	ca7ff0ef          	jal	ra,ffffffffc0200174 <vcprintf>
    cprintf("\n");
ffffffffc02004d2:	00006517          	auipc	a0,0x6
ffffffffc02004d6:	7ae50513          	addi	a0,a0,1966 # ffffffffc0206c80 <default_pmm_manager+0x520>
ffffffffc02004da:	cbbff0ef          	jal	ra,ffffffffc0200194 <cprintf>
#endif
}

static inline void sbi_shutdown(void)
{
	SBI_CALL_0(SBI_SHUTDOWN);
ffffffffc02004de:	4501                	li	a0,0
ffffffffc02004e0:	4581                	li	a1,0
ffffffffc02004e2:	4601                	li	a2,0
ffffffffc02004e4:	48a1                	li	a7,8
ffffffffc02004e6:	00000073          	ecall
    va_end(ap);

panic_dead:
    // No debug monitor here
    sbi_shutdown();
    intr_disable();
ffffffffc02004ea:	4ca000ef          	jal	ra,ffffffffc02009b4 <intr_disable>
    while (1)
    {
        kmonitor(NULL);
ffffffffc02004ee:	4501                	li	a0,0
ffffffffc02004f0:	e57ff0ef          	jal	ra,ffffffffc0200346 <kmonitor>
    while (1)
ffffffffc02004f4:	bfed                	j	ffffffffc02004ee <__panic+0x60>

ffffffffc02004f6 <__warn>:
    }
}

/* __warn - like panic, but don't */
void __warn(const char *file, int line, const char *fmt, ...)
{
ffffffffc02004f6:	715d                	addi	sp,sp,-80
ffffffffc02004f8:	832e                	mv	t1,a1
ffffffffc02004fa:	e822                	sd	s0,16(sp)
    va_list ap;
    va_start(ap, fmt);
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc02004fc:	85aa                	mv	a1,a0
{
ffffffffc02004fe:	8432                	mv	s0,a2
ffffffffc0200500:	fc3e                	sd	a5,56(sp)
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc0200502:	861a                	mv	a2,t1
    va_start(ap, fmt);
ffffffffc0200504:	103c                	addi	a5,sp,40
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc0200506:	00005517          	auipc	a0,0x5
ffffffffc020050a:	63250513          	addi	a0,a0,1586 # ffffffffc0205b38 <commands+0x68>
{
ffffffffc020050e:	ec06                	sd	ra,24(sp)
ffffffffc0200510:	f436                	sd	a3,40(sp)
ffffffffc0200512:	f83a                	sd	a4,48(sp)
ffffffffc0200514:	e0c2                	sd	a6,64(sp)
ffffffffc0200516:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0200518:	e43e                	sd	a5,8(sp)
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc020051a:	c7bff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    vcprintf(fmt, ap);
ffffffffc020051e:	65a2                	ld	a1,8(sp)
ffffffffc0200520:	8522                	mv	a0,s0
ffffffffc0200522:	c53ff0ef          	jal	ra,ffffffffc0200174 <vcprintf>
    cprintf("\n");
ffffffffc0200526:	00006517          	auipc	a0,0x6
ffffffffc020052a:	75a50513          	addi	a0,a0,1882 # ffffffffc0206c80 <default_pmm_manager+0x520>
ffffffffc020052e:	c67ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    va_end(ap);
}
ffffffffc0200532:	60e2                	ld	ra,24(sp)
ffffffffc0200534:	6442                	ld	s0,16(sp)
ffffffffc0200536:	6161                	addi	sp,sp,80
ffffffffc0200538:	8082                	ret

ffffffffc020053a <clock_init>:
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
    // divided by 500 when using Spike(2MHz)
    // divided by 100 when using QEMU(10MHz)
    timebase = 1e7 / 100;
ffffffffc020053a:	67e1                	lui	a5,0x18
ffffffffc020053c:	6a078793          	addi	a5,a5,1696 # 186a0 <_binary_obj___user_exit_out_size+0xd560>
ffffffffc0200540:	000bf717          	auipc	a4,0xbf
ffffffffc0200544:	66f73823          	sd	a5,1648(a4) # ffffffffc02bfbb0 <timebase>
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200548:	c0102573          	rdtime	a0
	SBI_CALL_1(SBI_SET_TIMER, stime_value);
ffffffffc020054c:	4581                	li	a1,0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc020054e:	953e                	add	a0,a0,a5
ffffffffc0200550:	4601                	li	a2,0
ffffffffc0200552:	4881                	li	a7,0
ffffffffc0200554:	00000073          	ecall
    set_csr(sie, MIP_STIP);
ffffffffc0200558:	02000793          	li	a5,32
ffffffffc020055c:	1047a7f3          	csrrs	a5,sie,a5
    cprintf("++ setup timer interrupts\n");
ffffffffc0200560:	00005517          	auipc	a0,0x5
ffffffffc0200564:	5f850513          	addi	a0,a0,1528 # ffffffffc0205b58 <commands+0x88>
    ticks = 0;
ffffffffc0200568:	000bf797          	auipc	a5,0xbf
ffffffffc020056c:	6407b023          	sd	zero,1600(a5) # ffffffffc02bfba8 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc0200570:	b115                	j	ffffffffc0200194 <cprintf>

ffffffffc0200572 <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200572:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200576:	000bf797          	auipc	a5,0xbf
ffffffffc020057a:	63a7b783          	ld	a5,1594(a5) # ffffffffc02bfbb0 <timebase>
ffffffffc020057e:	953e                	add	a0,a0,a5
ffffffffc0200580:	4581                	li	a1,0
ffffffffc0200582:	4601                	li	a2,0
ffffffffc0200584:	4881                	li	a7,0
ffffffffc0200586:	00000073          	ecall
ffffffffc020058a:	8082                	ret

ffffffffc020058c <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc020058c:	8082                	ret

ffffffffc020058e <cons_putc>:
#include <riscv.h>
#include <assert.h>

static inline bool __intr_save(void)
{
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020058e:	100027f3          	csrr	a5,sstatus
ffffffffc0200592:	8b89                	andi	a5,a5,2
	SBI_CALL_1(SBI_CONSOLE_PUTCHAR, ch);
ffffffffc0200594:	0ff57513          	zext.b	a0,a0
ffffffffc0200598:	e799                	bnez	a5,ffffffffc02005a6 <cons_putc+0x18>
ffffffffc020059a:	4581                	li	a1,0
ffffffffc020059c:	4601                	li	a2,0
ffffffffc020059e:	4885                	li	a7,1
ffffffffc02005a0:	00000073          	ecall
    return 0;
}

static inline void __intr_restore(bool flag)
{
    if (flag)
ffffffffc02005a4:	8082                	ret

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) {
ffffffffc02005a6:	1101                	addi	sp,sp,-32
ffffffffc02005a8:	ec06                	sd	ra,24(sp)
ffffffffc02005aa:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc02005ac:	408000ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc02005b0:	6522                	ld	a0,8(sp)
ffffffffc02005b2:	4581                	li	a1,0
ffffffffc02005b4:	4601                	li	a2,0
ffffffffc02005b6:	4885                	li	a7,1
ffffffffc02005b8:	00000073          	ecall
    local_intr_save(intr_flag);
    {
        sbi_console_putchar((unsigned char)c);
    }
    local_intr_restore(intr_flag);
}
ffffffffc02005bc:	60e2                	ld	ra,24(sp)
ffffffffc02005be:	6105                	addi	sp,sp,32
    {
        intr_enable();
ffffffffc02005c0:	a6fd                	j	ffffffffc02009ae <intr_enable>

ffffffffc02005c2 <cons_getc>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02005c2:	100027f3          	csrr	a5,sstatus
ffffffffc02005c6:	8b89                	andi	a5,a5,2
ffffffffc02005c8:	eb89                	bnez	a5,ffffffffc02005da <cons_getc+0x18>
	return SBI_CALL_0(SBI_CONSOLE_GETCHAR);
ffffffffc02005ca:	4501                	li	a0,0
ffffffffc02005cc:	4581                	li	a1,0
ffffffffc02005ce:	4601                	li	a2,0
ffffffffc02005d0:	4889                	li	a7,2
ffffffffc02005d2:	00000073          	ecall
ffffffffc02005d6:	2501                	sext.w	a0,a0
    {
        c = sbi_console_getchar();
    }
    local_intr_restore(intr_flag);
    return c;
}
ffffffffc02005d8:	8082                	ret
int cons_getc(void) {
ffffffffc02005da:	1101                	addi	sp,sp,-32
ffffffffc02005dc:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc02005de:	3d6000ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc02005e2:	4501                	li	a0,0
ffffffffc02005e4:	4581                	li	a1,0
ffffffffc02005e6:	4601                	li	a2,0
ffffffffc02005e8:	4889                	li	a7,2
ffffffffc02005ea:	00000073          	ecall
ffffffffc02005ee:	2501                	sext.w	a0,a0
ffffffffc02005f0:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc02005f2:	3bc000ef          	jal	ra,ffffffffc02009ae <intr_enable>
}
ffffffffc02005f6:	60e2                	ld	ra,24(sp)
ffffffffc02005f8:	6522                	ld	a0,8(sp)
ffffffffc02005fa:	6105                	addi	sp,sp,32
ffffffffc02005fc:	8082                	ret

ffffffffc02005fe <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc02005fe:	7119                	addi	sp,sp,-128
    cprintf("DTB Init\n");
ffffffffc0200600:	00005517          	auipc	a0,0x5
ffffffffc0200604:	57850513          	addi	a0,a0,1400 # ffffffffc0205b78 <commands+0xa8>
void dtb_init(void) {
ffffffffc0200608:	fc86                	sd	ra,120(sp)
ffffffffc020060a:	f8a2                	sd	s0,112(sp)
ffffffffc020060c:	e8d2                	sd	s4,80(sp)
ffffffffc020060e:	f4a6                	sd	s1,104(sp)
ffffffffc0200610:	f0ca                	sd	s2,96(sp)
ffffffffc0200612:	ecce                	sd	s3,88(sp)
ffffffffc0200614:	e4d6                	sd	s5,72(sp)
ffffffffc0200616:	e0da                	sd	s6,64(sp)
ffffffffc0200618:	fc5e                	sd	s7,56(sp)
ffffffffc020061a:	f862                	sd	s8,48(sp)
ffffffffc020061c:	f466                	sd	s9,40(sp)
ffffffffc020061e:	f06a                	sd	s10,32(sp)
ffffffffc0200620:	ec6e                	sd	s11,24(sp)
    cprintf("DTB Init\n");
ffffffffc0200622:	b73ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc0200626:	0000b597          	auipc	a1,0xb
ffffffffc020062a:	9da5b583          	ld	a1,-1574(a1) # ffffffffc020b000 <boot_hartid>
ffffffffc020062e:	00005517          	auipc	a0,0x5
ffffffffc0200632:	55a50513          	addi	a0,a0,1370 # ffffffffc0205b88 <commands+0xb8>
ffffffffc0200636:	b5fff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc020063a:	0000b417          	auipc	s0,0xb
ffffffffc020063e:	9ce40413          	addi	s0,s0,-1586 # ffffffffc020b008 <boot_dtb>
ffffffffc0200642:	600c                	ld	a1,0(s0)
ffffffffc0200644:	00005517          	auipc	a0,0x5
ffffffffc0200648:	55450513          	addi	a0,a0,1364 # ffffffffc0205b98 <commands+0xc8>
ffffffffc020064c:	b49ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc0200650:	00043a03          	ld	s4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc0200654:	00005517          	auipc	a0,0x5
ffffffffc0200658:	55c50513          	addi	a0,a0,1372 # ffffffffc0205bb0 <commands+0xe0>
    if (boot_dtb == 0) {
ffffffffc020065c:	120a0463          	beqz	s4,ffffffffc0200784 <dtb_init+0x186>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc0200660:	57f5                	li	a5,-3
ffffffffc0200662:	07fa                	slli	a5,a5,0x1e
ffffffffc0200664:	00fa0733          	add	a4,s4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc0200668:	431c                	lw	a5,0(a4)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020066a:	00ff0637          	lui	a2,0xff0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020066e:	6b41                	lui	s6,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200670:	0087d59b          	srliw	a1,a5,0x8
ffffffffc0200674:	0187969b          	slliw	a3,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200678:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020067c:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200680:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200684:	8df1                	and	a1,a1,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200686:	8ec9                	or	a3,a3,a0
ffffffffc0200688:	0087979b          	slliw	a5,a5,0x8
ffffffffc020068c:	1b7d                	addi	s6,s6,-1
ffffffffc020068e:	0167f7b3          	and	a5,a5,s6
ffffffffc0200692:	8dd5                	or	a1,a1,a3
ffffffffc0200694:	8ddd                	or	a1,a1,a5
    if (magic != 0xd00dfeed) {
ffffffffc0200696:	d00e07b7          	lui	a5,0xd00e0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020069a:	2581                	sext.w	a1,a1
    if (magic != 0xd00dfeed) {
ffffffffc020069c:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <end+0xfe202d1>
ffffffffc02006a0:	10f59163          	bne	a1,a5,ffffffffc02007a2 <dtb_init+0x1a4>
        return;
    }
    
    // 提取内存信息
    uint64_t mem_base, mem_size;
    if (extract_memory_info(dtb_vaddr, header, &mem_base, &mem_size) == 0) {
ffffffffc02006a4:	471c                	lw	a5,8(a4)
ffffffffc02006a6:	4754                	lw	a3,12(a4)
    int in_memory_node = 0;
ffffffffc02006a8:	4c81                	li	s9,0
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006aa:	0087d59b          	srliw	a1,a5,0x8
ffffffffc02006ae:	0086d51b          	srliw	a0,a3,0x8
ffffffffc02006b2:	0186941b          	slliw	s0,a3,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006b6:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006ba:	01879a1b          	slliw	s4,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006be:	0187d81b          	srliw	a6,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006c2:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006c6:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006ca:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006ce:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006d2:	8d71                	and	a0,a0,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006d4:	01146433          	or	s0,s0,a7
ffffffffc02006d8:	0086969b          	slliw	a3,a3,0x8
ffffffffc02006dc:	010a6a33          	or	s4,s4,a6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006e0:	8e6d                	and	a2,a2,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006e2:	0087979b          	slliw	a5,a5,0x8
ffffffffc02006e6:	8c49                	or	s0,s0,a0
ffffffffc02006e8:	0166f6b3          	and	a3,a3,s6
ffffffffc02006ec:	00ca6a33          	or	s4,s4,a2
ffffffffc02006f0:	0167f7b3          	and	a5,a5,s6
ffffffffc02006f4:	8c55                	or	s0,s0,a3
ffffffffc02006f6:	00fa6a33          	or	s4,s4,a5
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc02006fa:	1402                	slli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc02006fc:	1a02                	slli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc02006fe:	9001                	srli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200700:	020a5a13          	srli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200704:	943a                	add	s0,s0,a4
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200706:	9a3a                	add	s4,s4,a4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200708:	00ff0c37          	lui	s8,0xff0
        switch (token) {
ffffffffc020070c:	4b8d                	li	s7,3
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020070e:	00005917          	auipc	s2,0x5
ffffffffc0200712:	4f290913          	addi	s2,s2,1266 # ffffffffc0205c00 <commands+0x130>
ffffffffc0200716:	49bd                	li	s3,15
        switch (token) {
ffffffffc0200718:	4d91                	li	s11,4
ffffffffc020071a:	4d05                	li	s10,1
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc020071c:	00005497          	auipc	s1,0x5
ffffffffc0200720:	4dc48493          	addi	s1,s1,1244 # ffffffffc0205bf8 <commands+0x128>
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200724:	000a2703          	lw	a4,0(s4)
ffffffffc0200728:	004a0a93          	addi	s5,s4,4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020072c:	0087569b          	srliw	a3,a4,0x8
ffffffffc0200730:	0187179b          	slliw	a5,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200734:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200738:	0106969b          	slliw	a3,a3,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020073c:	0107571b          	srliw	a4,a4,0x10
ffffffffc0200740:	8fd1                	or	a5,a5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200742:	0186f6b3          	and	a3,a3,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200746:	0087171b          	slliw	a4,a4,0x8
ffffffffc020074a:	8fd5                	or	a5,a5,a3
ffffffffc020074c:	00eb7733          	and	a4,s6,a4
ffffffffc0200750:	8fd9                	or	a5,a5,a4
ffffffffc0200752:	2781                	sext.w	a5,a5
        switch (token) {
ffffffffc0200754:	09778c63          	beq	a5,s7,ffffffffc02007ec <dtb_init+0x1ee>
ffffffffc0200758:	00fbea63          	bltu	s7,a5,ffffffffc020076c <dtb_init+0x16e>
ffffffffc020075c:	07a78663          	beq	a5,s10,ffffffffc02007c8 <dtb_init+0x1ca>
ffffffffc0200760:	4709                	li	a4,2
ffffffffc0200762:	00e79763          	bne	a5,a4,ffffffffc0200770 <dtb_init+0x172>
ffffffffc0200766:	4c81                	li	s9,0
ffffffffc0200768:	8a56                	mv	s4,s5
ffffffffc020076a:	bf6d                	j	ffffffffc0200724 <dtb_init+0x126>
ffffffffc020076c:	ffb78ee3          	beq	a5,s11,ffffffffc0200768 <dtb_init+0x16a>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc0200770:	00005517          	auipc	a0,0x5
ffffffffc0200774:	50850513          	addi	a0,a0,1288 # ffffffffc0205c78 <commands+0x1a8>
ffffffffc0200778:	a1dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc020077c:	00005517          	auipc	a0,0x5
ffffffffc0200780:	53450513          	addi	a0,a0,1332 # ffffffffc0205cb0 <commands+0x1e0>
}
ffffffffc0200784:	7446                	ld	s0,112(sp)
ffffffffc0200786:	70e6                	ld	ra,120(sp)
ffffffffc0200788:	74a6                	ld	s1,104(sp)
ffffffffc020078a:	7906                	ld	s2,96(sp)
ffffffffc020078c:	69e6                	ld	s3,88(sp)
ffffffffc020078e:	6a46                	ld	s4,80(sp)
ffffffffc0200790:	6aa6                	ld	s5,72(sp)
ffffffffc0200792:	6b06                	ld	s6,64(sp)
ffffffffc0200794:	7be2                	ld	s7,56(sp)
ffffffffc0200796:	7c42                	ld	s8,48(sp)
ffffffffc0200798:	7ca2                	ld	s9,40(sp)
ffffffffc020079a:	7d02                	ld	s10,32(sp)
ffffffffc020079c:	6de2                	ld	s11,24(sp)
ffffffffc020079e:	6109                	addi	sp,sp,128
    cprintf("DTB init completed\n");
ffffffffc02007a0:	bad5                	j	ffffffffc0200194 <cprintf>
}
ffffffffc02007a2:	7446                	ld	s0,112(sp)
ffffffffc02007a4:	70e6                	ld	ra,120(sp)
ffffffffc02007a6:	74a6                	ld	s1,104(sp)
ffffffffc02007a8:	7906                	ld	s2,96(sp)
ffffffffc02007aa:	69e6                	ld	s3,88(sp)
ffffffffc02007ac:	6a46                	ld	s4,80(sp)
ffffffffc02007ae:	6aa6                	ld	s5,72(sp)
ffffffffc02007b0:	6b06                	ld	s6,64(sp)
ffffffffc02007b2:	7be2                	ld	s7,56(sp)
ffffffffc02007b4:	7c42                	ld	s8,48(sp)
ffffffffc02007b6:	7ca2                	ld	s9,40(sp)
ffffffffc02007b8:	7d02                	ld	s10,32(sp)
ffffffffc02007ba:	6de2                	ld	s11,24(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02007bc:	00005517          	auipc	a0,0x5
ffffffffc02007c0:	41450513          	addi	a0,a0,1044 # ffffffffc0205bd0 <commands+0x100>
}
ffffffffc02007c4:	6109                	addi	sp,sp,128
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02007c6:	b2f9                	j	ffffffffc0200194 <cprintf>
                int name_len = strlen(name);
ffffffffc02007c8:	8556                	mv	a0,s5
ffffffffc02007ca:	7d1040ef          	jal	ra,ffffffffc020579a <strlen>
ffffffffc02007ce:	8a2a                	mv	s4,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02007d0:	4619                	li	a2,6
ffffffffc02007d2:	85a6                	mv	a1,s1
ffffffffc02007d4:	8556                	mv	a0,s5
                int name_len = strlen(name);
ffffffffc02007d6:	2a01                	sext.w	s4,s4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02007d8:	028050ef          	jal	ra,ffffffffc0205800 <strncmp>
ffffffffc02007dc:	e111                	bnez	a0,ffffffffc02007e0 <dtb_init+0x1e2>
                    in_memory_node = 1;
ffffffffc02007de:	4c85                	li	s9,1
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc02007e0:	0a91                	addi	s5,s5,4
ffffffffc02007e2:	9ad2                	add	s5,s5,s4
ffffffffc02007e4:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc02007e8:	8a56                	mv	s4,s5
ffffffffc02007ea:	bf2d                	j	ffffffffc0200724 <dtb_init+0x126>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc02007ec:	004a2783          	lw	a5,4(s4)
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc02007f0:	00ca0693          	addi	a3,s4,12
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007f4:	0087d71b          	srliw	a4,a5,0x8
ffffffffc02007f8:	01879a9b          	slliw	s5,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007fc:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200800:	0107171b          	slliw	a4,a4,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200804:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200808:	00caeab3          	or	s5,s5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020080c:	01877733          	and	a4,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200810:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200814:	00eaeab3          	or	s5,s5,a4
ffffffffc0200818:	00fb77b3          	and	a5,s6,a5
ffffffffc020081c:	00faeab3          	or	s5,s5,a5
ffffffffc0200820:	2a81                	sext.w	s5,s5
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200822:	000c9c63          	bnez	s9,ffffffffc020083a <dtb_init+0x23c>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc0200826:	1a82                	slli	s5,s5,0x20
ffffffffc0200828:	00368793          	addi	a5,a3,3
ffffffffc020082c:	020ada93          	srli	s5,s5,0x20
ffffffffc0200830:	9abe                	add	s5,s5,a5
ffffffffc0200832:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc0200836:	8a56                	mv	s4,s5
ffffffffc0200838:	b5f5                	j	ffffffffc0200724 <dtb_init+0x126>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc020083a:	008a2783          	lw	a5,8(s4)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020083e:	85ca                	mv	a1,s2
ffffffffc0200840:	e436                	sd	a3,8(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200842:	0087d51b          	srliw	a0,a5,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200846:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020084a:	0187971b          	slliw	a4,a5,0x18
ffffffffc020084e:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200852:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200856:	8f51                	or	a4,a4,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200858:	01857533          	and	a0,a0,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020085c:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200860:	8d59                	or	a0,a0,a4
ffffffffc0200862:	00fb77b3          	and	a5,s6,a5
ffffffffc0200866:	8d5d                	or	a0,a0,a5
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc0200868:	1502                	slli	a0,a0,0x20
ffffffffc020086a:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020086c:	9522                	add	a0,a0,s0
ffffffffc020086e:	775040ef          	jal	ra,ffffffffc02057e2 <strcmp>
ffffffffc0200872:	66a2                	ld	a3,8(sp)
ffffffffc0200874:	f94d                	bnez	a0,ffffffffc0200826 <dtb_init+0x228>
ffffffffc0200876:	fb59f8e3          	bgeu	s3,s5,ffffffffc0200826 <dtb_init+0x228>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc020087a:	00ca3783          	ld	a5,12(s4)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc020087e:	014a3703          	ld	a4,20(s4)
        cprintf("Physical Memory from DTB:\n");
ffffffffc0200882:	00005517          	auipc	a0,0x5
ffffffffc0200886:	38650513          	addi	a0,a0,902 # ffffffffc0205c08 <commands+0x138>
           fdt32_to_cpu(x >> 32);
ffffffffc020088a:	4207d613          	srai	a2,a5,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020088e:	0087d31b          	srliw	t1,a5,0x8
           fdt32_to_cpu(x >> 32);
ffffffffc0200892:	42075593          	srai	a1,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200896:	0187de1b          	srliw	t3,a5,0x18
ffffffffc020089a:	0186581b          	srliw	a6,a2,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020089e:	0187941b          	slliw	s0,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02008a2:	0107d89b          	srliw	a7,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02008a6:	0187d693          	srli	a3,a5,0x18
ffffffffc02008aa:	01861f1b          	slliw	t5,a2,0x18
ffffffffc02008ae:	0087579b          	srliw	a5,a4,0x8
ffffffffc02008b2:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02008b6:	0106561b          	srliw	a2,a2,0x10
ffffffffc02008ba:	010f6f33          	or	t5,t5,a6
ffffffffc02008be:	0187529b          	srliw	t0,a4,0x18
ffffffffc02008c2:	0185df9b          	srliw	t6,a1,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02008c6:	01837333          	and	t1,t1,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02008ca:	01c46433          	or	s0,s0,t3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02008ce:	0186f6b3          	and	a3,a3,s8
ffffffffc02008d2:	01859e1b          	slliw	t3,a1,0x18
ffffffffc02008d6:	01871e9b          	slliw	t4,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02008da:	0107581b          	srliw	a6,a4,0x10
ffffffffc02008de:	0086161b          	slliw	a2,a2,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02008e2:	8361                	srli	a4,a4,0x18
ffffffffc02008e4:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02008e8:	0105d59b          	srliw	a1,a1,0x10
ffffffffc02008ec:	01e6e6b3          	or	a3,a3,t5
ffffffffc02008f0:	00cb7633          	and	a2,s6,a2
ffffffffc02008f4:	0088181b          	slliw	a6,a6,0x8
ffffffffc02008f8:	0085959b          	slliw	a1,a1,0x8
ffffffffc02008fc:	00646433          	or	s0,s0,t1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200900:	0187f7b3          	and	a5,a5,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200904:	01fe6333          	or	t1,t3,t6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200908:	01877c33          	and	s8,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020090c:	0088989b          	slliw	a7,a7,0x8
ffffffffc0200910:	011b78b3          	and	a7,s6,a7
ffffffffc0200914:	005eeeb3          	or	t4,t4,t0
ffffffffc0200918:	00c6e733          	or	a4,a3,a2
ffffffffc020091c:	006c6c33          	or	s8,s8,t1
ffffffffc0200920:	010b76b3          	and	a3,s6,a6
ffffffffc0200924:	00bb7b33          	and	s6,s6,a1
ffffffffc0200928:	01d7e7b3          	or	a5,a5,t4
ffffffffc020092c:	016c6b33          	or	s6,s8,s6
ffffffffc0200930:	01146433          	or	s0,s0,a7
ffffffffc0200934:	8fd5                	or	a5,a5,a3
           fdt32_to_cpu(x >> 32);
ffffffffc0200936:	1702                	slli	a4,a4,0x20
ffffffffc0200938:	1b02                	slli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc020093a:	1782                	slli	a5,a5,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc020093c:	9301                	srli	a4,a4,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc020093e:	1402                	slli	s0,s0,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc0200940:	020b5b13          	srli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200944:	0167eb33          	or	s6,a5,s6
ffffffffc0200948:	8c59                	or	s0,s0,a4
        cprintf("Physical Memory from DTB:\n");
ffffffffc020094a:	84bff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc020094e:	85a2                	mv	a1,s0
ffffffffc0200950:	00005517          	auipc	a0,0x5
ffffffffc0200954:	2d850513          	addi	a0,a0,728 # ffffffffc0205c28 <commands+0x158>
ffffffffc0200958:	83dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc020095c:	014b5613          	srli	a2,s6,0x14
ffffffffc0200960:	85da                	mv	a1,s6
ffffffffc0200962:	00005517          	auipc	a0,0x5
ffffffffc0200966:	2de50513          	addi	a0,a0,734 # ffffffffc0205c40 <commands+0x170>
ffffffffc020096a:	82bff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc020096e:	008b05b3          	add	a1,s6,s0
ffffffffc0200972:	15fd                	addi	a1,a1,-1
ffffffffc0200974:	00005517          	auipc	a0,0x5
ffffffffc0200978:	2ec50513          	addi	a0,a0,748 # ffffffffc0205c60 <commands+0x190>
ffffffffc020097c:	819ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("DTB init completed\n");
ffffffffc0200980:	00005517          	auipc	a0,0x5
ffffffffc0200984:	33050513          	addi	a0,a0,816 # ffffffffc0205cb0 <commands+0x1e0>
        memory_base = mem_base;
ffffffffc0200988:	000bf797          	auipc	a5,0xbf
ffffffffc020098c:	2287b823          	sd	s0,560(a5) # ffffffffc02bfbb8 <memory_base>
        memory_size = mem_size;
ffffffffc0200990:	000bf797          	auipc	a5,0xbf
ffffffffc0200994:	2367b823          	sd	s6,560(a5) # ffffffffc02bfbc0 <memory_size>
    cprintf("DTB init completed\n");
ffffffffc0200998:	b3f5                	j	ffffffffc0200784 <dtb_init+0x186>

ffffffffc020099a <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc020099a:	000bf517          	auipc	a0,0xbf
ffffffffc020099e:	21e53503          	ld	a0,542(a0) # ffffffffc02bfbb8 <memory_base>
ffffffffc02009a2:	8082                	ret

ffffffffc02009a4 <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
}
ffffffffc02009a4:	000bf517          	auipc	a0,0xbf
ffffffffc02009a8:	21c53503          	ld	a0,540(a0) # ffffffffc02bfbc0 <memory_size>
ffffffffc02009ac:	8082                	ret

ffffffffc02009ae <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc02009ae:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc02009b2:	8082                	ret

ffffffffc02009b4 <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc02009b4:	100177f3          	csrrci	a5,sstatus,2
ffffffffc02009b8:	8082                	ret

ffffffffc02009ba <pic_init>:
#include <picirq.h>

void pic_enable(unsigned int irq) {}

/* pic_init - initialize the 8259A interrupt controllers */
void pic_init(void) {}
ffffffffc02009ba:	8082                	ret

ffffffffc02009bc <idt_init>:
void idt_init(void)
{
    extern void __alltraps(void);
    /* Set sscratch register to 0, indicating to exception vector that we are
     * presently executing in the kernel */
    write_csr(sscratch, 0);
ffffffffc02009bc:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
ffffffffc02009c0:	00000797          	auipc	a5,0x0
ffffffffc02009c4:	72078793          	addi	a5,a5,1824 # ffffffffc02010e0 <__alltraps>
ffffffffc02009c8:	10579073          	csrw	stvec,a5
    /* Allow kernel to access user memory */
    set_csr(sstatus, SSTATUS_SUM);
ffffffffc02009cc:	000407b7          	lui	a5,0x40
ffffffffc02009d0:	1007a7f3          	csrrs	a5,sstatus,a5
}
ffffffffc02009d4:	8082                	ret

ffffffffc02009d6 <print_regs>:
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr)
{
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc02009d6:	610c                	ld	a1,0(a0)
{
ffffffffc02009d8:	1141                	addi	sp,sp,-16
ffffffffc02009da:	e022                	sd	s0,0(sp)
ffffffffc02009dc:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc02009de:	00005517          	auipc	a0,0x5
ffffffffc02009e2:	2ea50513          	addi	a0,a0,746 # ffffffffc0205cc8 <commands+0x1f8>
{
ffffffffc02009e6:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc02009e8:	facff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc02009ec:	640c                	ld	a1,8(s0)
ffffffffc02009ee:	00005517          	auipc	a0,0x5
ffffffffc02009f2:	2f250513          	addi	a0,a0,754 # ffffffffc0205ce0 <commands+0x210>
ffffffffc02009f6:	f9eff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc02009fa:	680c                	ld	a1,16(s0)
ffffffffc02009fc:	00005517          	auipc	a0,0x5
ffffffffc0200a00:	2fc50513          	addi	a0,a0,764 # ffffffffc0205cf8 <commands+0x228>
ffffffffc0200a04:	f90ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc0200a08:	6c0c                	ld	a1,24(s0)
ffffffffc0200a0a:	00005517          	auipc	a0,0x5
ffffffffc0200a0e:	30650513          	addi	a0,a0,774 # ffffffffc0205d10 <commands+0x240>
ffffffffc0200a12:	f82ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc0200a16:	700c                	ld	a1,32(s0)
ffffffffc0200a18:	00005517          	auipc	a0,0x5
ffffffffc0200a1c:	31050513          	addi	a0,a0,784 # ffffffffc0205d28 <commands+0x258>
ffffffffc0200a20:	f74ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc0200a24:	740c                	ld	a1,40(s0)
ffffffffc0200a26:	00005517          	auipc	a0,0x5
ffffffffc0200a2a:	31a50513          	addi	a0,a0,794 # ffffffffc0205d40 <commands+0x270>
ffffffffc0200a2e:	f66ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc0200a32:	780c                	ld	a1,48(s0)
ffffffffc0200a34:	00005517          	auipc	a0,0x5
ffffffffc0200a38:	32450513          	addi	a0,a0,804 # ffffffffc0205d58 <commands+0x288>
ffffffffc0200a3c:	f58ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc0200a40:	7c0c                	ld	a1,56(s0)
ffffffffc0200a42:	00005517          	auipc	a0,0x5
ffffffffc0200a46:	32e50513          	addi	a0,a0,814 # ffffffffc0205d70 <commands+0x2a0>
ffffffffc0200a4a:	f4aff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc0200a4e:	602c                	ld	a1,64(s0)
ffffffffc0200a50:	00005517          	auipc	a0,0x5
ffffffffc0200a54:	33850513          	addi	a0,a0,824 # ffffffffc0205d88 <commands+0x2b8>
ffffffffc0200a58:	f3cff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc0200a5c:	642c                	ld	a1,72(s0)
ffffffffc0200a5e:	00005517          	auipc	a0,0x5
ffffffffc0200a62:	34250513          	addi	a0,a0,834 # ffffffffc0205da0 <commands+0x2d0>
ffffffffc0200a66:	f2eff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc0200a6a:	682c                	ld	a1,80(s0)
ffffffffc0200a6c:	00005517          	auipc	a0,0x5
ffffffffc0200a70:	34c50513          	addi	a0,a0,844 # ffffffffc0205db8 <commands+0x2e8>
ffffffffc0200a74:	f20ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc0200a78:	6c2c                	ld	a1,88(s0)
ffffffffc0200a7a:	00005517          	auipc	a0,0x5
ffffffffc0200a7e:	35650513          	addi	a0,a0,854 # ffffffffc0205dd0 <commands+0x300>
ffffffffc0200a82:	f12ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc0200a86:	702c                	ld	a1,96(s0)
ffffffffc0200a88:	00005517          	auipc	a0,0x5
ffffffffc0200a8c:	36050513          	addi	a0,a0,864 # ffffffffc0205de8 <commands+0x318>
ffffffffc0200a90:	f04ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc0200a94:	742c                	ld	a1,104(s0)
ffffffffc0200a96:	00005517          	auipc	a0,0x5
ffffffffc0200a9a:	36a50513          	addi	a0,a0,874 # ffffffffc0205e00 <commands+0x330>
ffffffffc0200a9e:	ef6ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc0200aa2:	782c                	ld	a1,112(s0)
ffffffffc0200aa4:	00005517          	auipc	a0,0x5
ffffffffc0200aa8:	37450513          	addi	a0,a0,884 # ffffffffc0205e18 <commands+0x348>
ffffffffc0200aac:	ee8ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200ab0:	7c2c                	ld	a1,120(s0)
ffffffffc0200ab2:	00005517          	auipc	a0,0x5
ffffffffc0200ab6:	37e50513          	addi	a0,a0,894 # ffffffffc0205e30 <commands+0x360>
ffffffffc0200aba:	edaff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc0200abe:	604c                	ld	a1,128(s0)
ffffffffc0200ac0:	00005517          	auipc	a0,0x5
ffffffffc0200ac4:	38850513          	addi	a0,a0,904 # ffffffffc0205e48 <commands+0x378>
ffffffffc0200ac8:	eccff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200acc:	644c                	ld	a1,136(s0)
ffffffffc0200ace:	00005517          	auipc	a0,0x5
ffffffffc0200ad2:	39250513          	addi	a0,a0,914 # ffffffffc0205e60 <commands+0x390>
ffffffffc0200ad6:	ebeff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200ada:	684c                	ld	a1,144(s0)
ffffffffc0200adc:	00005517          	auipc	a0,0x5
ffffffffc0200ae0:	39c50513          	addi	a0,a0,924 # ffffffffc0205e78 <commands+0x3a8>
ffffffffc0200ae4:	eb0ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc0200ae8:	6c4c                	ld	a1,152(s0)
ffffffffc0200aea:	00005517          	auipc	a0,0x5
ffffffffc0200aee:	3a650513          	addi	a0,a0,934 # ffffffffc0205e90 <commands+0x3c0>
ffffffffc0200af2:	ea2ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc0200af6:	704c                	ld	a1,160(s0)
ffffffffc0200af8:	00005517          	auipc	a0,0x5
ffffffffc0200afc:	3b050513          	addi	a0,a0,944 # ffffffffc0205ea8 <commands+0x3d8>
ffffffffc0200b00:	e94ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc0200b04:	744c                	ld	a1,168(s0)
ffffffffc0200b06:	00005517          	auipc	a0,0x5
ffffffffc0200b0a:	3ba50513          	addi	a0,a0,954 # ffffffffc0205ec0 <commands+0x3f0>
ffffffffc0200b0e:	e86ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc0200b12:	784c                	ld	a1,176(s0)
ffffffffc0200b14:	00005517          	auipc	a0,0x5
ffffffffc0200b18:	3c450513          	addi	a0,a0,964 # ffffffffc0205ed8 <commands+0x408>
ffffffffc0200b1c:	e78ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc0200b20:	7c4c                	ld	a1,184(s0)
ffffffffc0200b22:	00005517          	auipc	a0,0x5
ffffffffc0200b26:	3ce50513          	addi	a0,a0,974 # ffffffffc0205ef0 <commands+0x420>
ffffffffc0200b2a:	e6aff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc0200b2e:	606c                	ld	a1,192(s0)
ffffffffc0200b30:	00005517          	auipc	a0,0x5
ffffffffc0200b34:	3d850513          	addi	a0,a0,984 # ffffffffc0205f08 <commands+0x438>
ffffffffc0200b38:	e5cff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc0200b3c:	646c                	ld	a1,200(s0)
ffffffffc0200b3e:	00005517          	auipc	a0,0x5
ffffffffc0200b42:	3e250513          	addi	a0,a0,994 # ffffffffc0205f20 <commands+0x450>
ffffffffc0200b46:	e4eff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc0200b4a:	686c                	ld	a1,208(s0)
ffffffffc0200b4c:	00005517          	auipc	a0,0x5
ffffffffc0200b50:	3ec50513          	addi	a0,a0,1004 # ffffffffc0205f38 <commands+0x468>
ffffffffc0200b54:	e40ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc0200b58:	6c6c                	ld	a1,216(s0)
ffffffffc0200b5a:	00005517          	auipc	a0,0x5
ffffffffc0200b5e:	3f650513          	addi	a0,a0,1014 # ffffffffc0205f50 <commands+0x480>
ffffffffc0200b62:	e32ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc0200b66:	706c                	ld	a1,224(s0)
ffffffffc0200b68:	00005517          	auipc	a0,0x5
ffffffffc0200b6c:	40050513          	addi	a0,a0,1024 # ffffffffc0205f68 <commands+0x498>
ffffffffc0200b70:	e24ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc0200b74:	746c                	ld	a1,232(s0)
ffffffffc0200b76:	00005517          	auipc	a0,0x5
ffffffffc0200b7a:	40a50513          	addi	a0,a0,1034 # ffffffffc0205f80 <commands+0x4b0>
ffffffffc0200b7e:	e16ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200b82:	786c                	ld	a1,240(s0)
ffffffffc0200b84:	00005517          	auipc	a0,0x5
ffffffffc0200b88:	41450513          	addi	a0,a0,1044 # ffffffffc0205f98 <commands+0x4c8>
ffffffffc0200b8c:	e08ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200b90:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200b92:	6402                	ld	s0,0(sp)
ffffffffc0200b94:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200b96:	00005517          	auipc	a0,0x5
ffffffffc0200b9a:	41a50513          	addi	a0,a0,1050 # ffffffffc0205fb0 <commands+0x4e0>
}
ffffffffc0200b9e:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200ba0:	df4ff06f          	j	ffffffffc0200194 <cprintf>

ffffffffc0200ba4 <print_trapframe>:
{
ffffffffc0200ba4:	1141                	addi	sp,sp,-16
ffffffffc0200ba6:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200ba8:	85aa                	mv	a1,a0
{
ffffffffc0200baa:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc0200bac:	00005517          	auipc	a0,0x5
ffffffffc0200bb0:	41c50513          	addi	a0,a0,1052 # ffffffffc0205fc8 <commands+0x4f8>
{
ffffffffc0200bb4:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200bb6:	ddeff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200bba:	8522                	mv	a0,s0
ffffffffc0200bbc:	e1bff0ef          	jal	ra,ffffffffc02009d6 <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc0200bc0:	10043583          	ld	a1,256(s0)
ffffffffc0200bc4:	00005517          	auipc	a0,0x5
ffffffffc0200bc8:	41c50513          	addi	a0,a0,1052 # ffffffffc0205fe0 <commands+0x510>
ffffffffc0200bcc:	dc8ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200bd0:	10843583          	ld	a1,264(s0)
ffffffffc0200bd4:	00005517          	auipc	a0,0x5
ffffffffc0200bd8:	42450513          	addi	a0,a0,1060 # ffffffffc0205ff8 <commands+0x528>
ffffffffc0200bdc:	db8ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  tval 0x%08x\n", tf->tval);
ffffffffc0200be0:	11043583          	ld	a1,272(s0)
ffffffffc0200be4:	00005517          	auipc	a0,0x5
ffffffffc0200be8:	42c50513          	addi	a0,a0,1068 # ffffffffc0206010 <commands+0x540>
ffffffffc0200bec:	da8ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200bf0:	11843583          	ld	a1,280(s0)
}
ffffffffc0200bf4:	6402                	ld	s0,0(sp)
ffffffffc0200bf6:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200bf8:	00005517          	auipc	a0,0x5
ffffffffc0200bfc:	42850513          	addi	a0,a0,1064 # ffffffffc0206020 <commands+0x550>
}
ffffffffc0200c00:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200c02:	d92ff06f          	j	ffffffffc0200194 <cprintf>

ffffffffc0200c06 <pgfault_handler>:
static int pgfault_handler(struct trapframe *tf) { 
ffffffffc0200c06:	715d                	addi	sp,sp,-80
ffffffffc0200c08:	f84a                	sd	s2,48(sp)
    if (current == NULL) { //表示内核线程缺页（不可能啊！）所以直接panic
ffffffffc0200c0a:	000bf917          	auipc	s2,0xbf
ffffffffc0200c0e:	ff690913          	addi	s2,s2,-10 # ffffffffc02bfc00 <current>
ffffffffc0200c12:	00093783          	ld	a5,0(s2)
static int pgfault_handler(struct trapframe *tf) { 
ffffffffc0200c16:	fc26                	sd	s1,56(sp)
ffffffffc0200c18:	f44e                	sd	s3,40(sp)
ffffffffc0200c1a:	e486                	sd	ra,72(sp)
ffffffffc0200c1c:	e0a2                	sd	s0,64(sp)
ffffffffc0200c1e:	f052                	sd	s4,32(sp)
ffffffffc0200c20:	ec56                	sd	s5,24(sp)
ffffffffc0200c22:	e85a                	sd	s6,16(sp)
ffffffffc0200c24:	e45e                	sd	s7,8(sp)
    uintptr_t addr = tf->tval;         // 发生错误的虚拟地址
ffffffffc0200c26:	11053483          	ld	s1,272(a0)
    uint32_t error_code = tf->cause;   // 错误原因
ffffffffc0200c2a:	11852983          	lw	s3,280(a0)
    if (current == NULL) { //表示内核线程缺页（不可能啊！）所以直接panic
ffffffffc0200c2e:	16078963          	beqz	a5,ffffffffc0200da0 <pgfault_handler+0x19a>
    if (current->mm == NULL) { //表示内核线程缺页（不可能啊！）所以直接panic
ffffffffc0200c32:	779c                	ld	a5,40(a5)
ffffffffc0200c34:	14078863          	beqz	a5,ffffffffc0200d84 <pgfault_handler+0x17e>
    pte_t *ptep = get_pte(pgdir_va, addr, 0);  // 获取页表项
ffffffffc0200c38:	842a                	mv	s0,a0
ffffffffc0200c3a:	6f88                	ld	a0,24(a5)
ffffffffc0200c3c:	4601                	li	a2,0
ffffffffc0200c3e:	85a6                	mv	a1,s1
ffffffffc0200c40:	58c010ef          	jal	ra,ffffffffc02021cc <get_pte>
    if (ptep != NULL && (*ptep & PTE_V)) {     // 页表项存在且有效
ffffffffc0200c44:	10050363          	beqz	a0,ffffffffc0200d4a <pgfault_handler+0x144>
        if ((*ptep & PTE_COW) && (error_code == CAUSE_STORE_PAGE_FAULT)) {
ffffffffc0200c48:	611c                	ld	a5,0(a0)
ffffffffc0200c4a:	20100713          	li	a4,513
ffffffffc0200c4e:	2017f793          	andi	a5,a5,513
ffffffffc0200c52:	0ee79c63          	bne	a5,a4,ffffffffc0200d4a <pgfault_handler+0x144>
ffffffffc0200c56:	47bd                	li	a5,15
ffffffffc0200c58:	0ef99963          	bne	s3,a5,ffffffffc0200d4a <pgfault_handler+0x144>
            int ret = do_cow_page_fault(current->mm, error_code, addr);
ffffffffc0200c5c:	00093783          	ld	a5,0(s2)
    uintptr_t la = ROUNDDOWN(addr, PGSIZE);   // la = 页面对齐的地址
ffffffffc0200c60:	75fd                	lui	a1,0xfffff
ffffffffc0200c62:	8ced                	and	s1,s1,a1
    ptep = get_pte(mm->pgdir, la, 0);         // ptep是指向虚拟地址 la 对应的页表项的指针
ffffffffc0200c64:	779c                	ld	a5,40(a5)
ffffffffc0200c66:	4601                	li	a2,0
ffffffffc0200c68:	85a6                	mv	a1,s1
ffffffffc0200c6a:	6f88                	ld	a0,24(a5)
ffffffffc0200c6c:	560010ef          	jal	ra,ffffffffc02021cc <get_pte>
ffffffffc0200c70:	892a                	mv	s2,a0
    if (ptep == NULL || !(*ptep & PTE_V)) {
ffffffffc0200c72:	10050563          	beqz	a0,ffffffffc0200d7c <pgfault_handler+0x176>
ffffffffc0200c76:	6100                	ld	s0,0(a0)
ffffffffc0200c78:	00147793          	andi	a5,s0,1
ffffffffc0200c7c:	10078063          	beqz	a5,ffffffffc0200d7c <pgfault_handler+0x176>
}

static inline struct Page *
pa2page(uintptr_t pa)
{
    if (PPN(pa) >= npage)
ffffffffc0200c80:	000bfb97          	auipc	s7,0xbf
ffffffffc0200c84:	f60b8b93          	addi	s7,s7,-160 # ffffffffc02bfbe0 <npage>
ffffffffc0200c88:	000bb783          	ld	a5,0(s7)
{
    if (!(pte & PTE_V))
    {
        panic("pte2page called with invalid pte");
    }
    return pa2page(PTE_ADDR(pte));
ffffffffc0200c8c:	00241713          	slli	a4,s0,0x2
ffffffffc0200c90:	8331                	srli	a4,a4,0xc
    if (PPN(pa) >= npage)
ffffffffc0200c92:	14f77163          	bgeu	a4,a5,ffffffffc0200dd4 <pgfault_handler+0x1ce>
    return &pages[PPN(pa) - nbase];
ffffffffc0200c96:	000bfb17          	auipc	s6,0xbf
ffffffffc0200c9a:	f52b0b13          	addi	s6,s6,-174 # ffffffffc02bfbe8 <pages>
ffffffffc0200c9e:	000b3a03          	ld	s4,0(s6)
ffffffffc0200ca2:	00007a97          	auipc	s5,0x7
ffffffffc0200ca6:	d3eaba83          	ld	s5,-706(s5) # ffffffffc02079e0 <nbase>
ffffffffc0200caa:	41570733          	sub	a4,a4,s5
ffffffffc0200cae:	071a                	slli	a4,a4,0x6
    struct Page *new_page = alloc_page();   // 分配新物理页
ffffffffc0200cb0:	4505                	li	a0,1
ffffffffc0200cb2:	9a3a                	add	s4,s4,a4
ffffffffc0200cb4:	460010ef          	jal	ra,ffffffffc0202114 <alloc_pages>
ffffffffc0200cb8:	89aa                	mv	s3,a0
    if (new_page == NULL) {                 
ffffffffc0200cba:	c179                	beqz	a0,ffffffffc0200d80 <pgfault_handler+0x17a>
    return page - pages + nbase;
ffffffffc0200cbc:	000b3783          	ld	a5,0(s6)
    return KADDR(page2pa(page));
ffffffffc0200cc0:	000bb603          	ld	a2,0(s7)
    return page - pages + nbase;
ffffffffc0200cc4:	40fa06b3          	sub	a3,s4,a5
ffffffffc0200cc8:	8699                	srai	a3,a3,0x6
ffffffffc0200cca:	96d6                	add	a3,a3,s5
    return KADDR(page2pa(page));
ffffffffc0200ccc:	00c69713          	slli	a4,a3,0xc
ffffffffc0200cd0:	8331                	srli	a4,a4,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0200cd2:	00c69593          	slli	a1,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0200cd6:	10c77b63          	bgeu	a4,a2,ffffffffc0200dec <pgfault_handler+0x1e6>
    return page - pages + nbase;
ffffffffc0200cda:	40f506b3          	sub	a3,a0,a5
ffffffffc0200cde:	8699                	srai	a3,a3,0x6
ffffffffc0200ce0:	96d6                	add	a3,a3,s5
    return KADDR(page2pa(page));
ffffffffc0200ce2:	00c69793          	slli	a5,a3,0xc
ffffffffc0200ce6:	000bf517          	auipc	a0,0xbf
ffffffffc0200cea:	f1253503          	ld	a0,-238(a0) # ffffffffc02bfbf8 <va_pa_offset>
ffffffffc0200cee:	83b1                	srli	a5,a5,0xc
ffffffffc0200cf0:	95aa                	add	a1,a1,a0
    return page2ppn(page) << PGSHIFT;
ffffffffc0200cf2:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0200cf4:	0cc7f463          	bgeu	a5,a2,ffffffffc0200dbc <pgfault_handler+0x1b6>
    memcpy((void*)dst_kva, (void*)src_kva, PGSIZE); // 复制4KB数据
ffffffffc0200cf8:	6605                	lui	a2,0x1
ffffffffc0200cfa:	9536                	add	a0,a0,a3
ffffffffc0200cfc:	353040ef          	jal	ra,ffffffffc020584e <memcpy>
    return page - pages + nbase;
ffffffffc0200d00:	000b3783          	ld	a5,0(s6)
}

static inline int
page_ref_dec(struct Page *page)
{
    page->ref -= 1;
ffffffffc0200d04:	000a2703          	lw	a4,0(s4)
    uint32_t perm = (old_pte_value & (PTE_U | PTE_R | PTE_X)) | PTE_W; // 计算新权限
ffffffffc0200d08:	8869                	andi	s0,s0,26
    return page - pages + nbase;
ffffffffc0200d0a:	40f987b3          	sub	a5,s3,a5
ffffffffc0200d0e:	8799                	srai	a5,a5,0x6
ffffffffc0200d10:	97d6                	add	a5,a5,s5
    page->ref -= 1;
ffffffffc0200d12:	377d                	addiw	a4,a4,-1
}

// construct PTE from a page and permission bits
static inline pte_t pte_create(uintptr_t ppn, int type)
{
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0200d14:	07aa                	slli	a5,a5,0xa
    page->ref -= 1;
ffffffffc0200d16:	00ea2023          	sw	a4,0(s4)
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0200d1a:	8c5d                	or	s0,s0,a5
    page->ref = val;
ffffffffc0200d1c:	4785                	li	a5,1
ffffffffc0200d1e:	00f9a023          	sw	a5,0(s3)
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0200d22:	00546413          	ori	s0,s0,5
    *ptep = pte_create(page2ppn(new_page), PTE_V | perm);
ffffffffc0200d26:	00893023          	sd	s0,0(s2)
    asm volatile("sfence.vma zero, %0" :: "r"(la) : "memory");
ffffffffc0200d2a:	12900073          	sfence.vma	zero,s1
    asm volatile("fence" ::: "memory");
ffffffffc0200d2e:	0ff0000f          	fence
    return 0;
ffffffffc0200d32:	4501                	li	a0,0
}
ffffffffc0200d34:	60a6                	ld	ra,72(sp)
ffffffffc0200d36:	6406                	ld	s0,64(sp)
ffffffffc0200d38:	74e2                	ld	s1,56(sp)
ffffffffc0200d3a:	7942                	ld	s2,48(sp)
ffffffffc0200d3c:	79a2                	ld	s3,40(sp)
ffffffffc0200d3e:	7a02                	ld	s4,32(sp)
ffffffffc0200d40:	6ae2                	ld	s5,24(sp)
ffffffffc0200d42:	6b42                	ld	s6,16(sp)
ffffffffc0200d44:	6ba2                	ld	s7,8(sp)
ffffffffc0200d46:	6161                	addi	sp,sp,80
ffffffffc0200d48:	8082                	ret
    cprintf("page fault at 0x%08x: %c/%c\n", addr,
ffffffffc0200d4a:	47b5                	li	a5,13
ffffffffc0200d4c:	05200613          	li	a2,82
ffffffffc0200d50:	00f98463          	beq	s3,a5,ffffffffc0200d58 <pgfault_handler+0x152>
ffffffffc0200d54:	05700613          	li	a2,87
            (tf->status & SSTATUS_SPP) ? 'K' : 'U');
ffffffffc0200d58:	10043783          	ld	a5,256(s0)
    cprintf("page fault at 0x%08x: %c/%c\n", addr,
ffffffffc0200d5c:	04b00693          	li	a3,75
            (tf->status & SSTATUS_SPP) ? 'K' : 'U');
ffffffffc0200d60:	1007f793          	andi	a5,a5,256
    cprintf("page fault at 0x%08x: %c/%c\n", addr,
ffffffffc0200d64:	e399                	bnez	a5,ffffffffc0200d6a <pgfault_handler+0x164>
ffffffffc0200d66:	05500693          	li	a3,85
ffffffffc0200d6a:	85a6                	mv	a1,s1
ffffffffc0200d6c:	00005517          	auipc	a0,0x5
ffffffffc0200d70:	37450513          	addi	a0,a0,884 # ffffffffc02060e0 <commands+0x610>
ffffffffc0200d74:	c20ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    return -E_INVAL; // 不是COW错误，返回无效参数错误
ffffffffc0200d78:	5575                	li	a0,-3
ffffffffc0200d7a:	bf6d                	j	ffffffffc0200d34 <pgfault_handler+0x12e>
        return -E_INVAL;
ffffffffc0200d7c:	5575                	li	a0,-3
ffffffffc0200d7e:	bf5d                	j	ffffffffc0200d34 <pgfault_handler+0x12e>
        return -E_NO_MEM; 
ffffffffc0200d80:	5571                	li	a0,-4
ffffffffc0200d82:	bf4d                	j	ffffffffc0200d34 <pgfault_handler+0x12e>
        print_trapframe(tf);
ffffffffc0200d84:	e21ff0ef          	jal	ra,ffffffffc0200ba4 <print_trapframe>
        panic("page fault in kernel thread!"); // current->mm是进程的内存管理结构
ffffffffc0200d88:	00005617          	auipc	a2,0x5
ffffffffc0200d8c:	2e060613          	addi	a2,a2,736 # ffffffffc0206068 <commands+0x598>
ffffffffc0200d90:	02e00593          	li	a1,46
ffffffffc0200d94:	00005517          	auipc	a0,0x5
ffffffffc0200d98:	2bc50513          	addi	a0,a0,700 # ffffffffc0206050 <commands+0x580>
ffffffffc0200d9c:	ef2ff0ef          	jal	ra,ffffffffc020048e <__panic>
        print_trapframe(tf);
ffffffffc0200da0:	e05ff0ef          	jal	ra,ffffffffc0200ba4 <print_trapframe>
        panic("page fault in kernel!"); // current是当前运行进程的PCB指针
ffffffffc0200da4:	00005617          	auipc	a2,0x5
ffffffffc0200da8:	29460613          	addi	a2,a2,660 # ffffffffc0206038 <commands+0x568>
ffffffffc0200dac:	02900593          	li	a1,41
ffffffffc0200db0:	00005517          	auipc	a0,0x5
ffffffffc0200db4:	2a050513          	addi	a0,a0,672 # ffffffffc0206050 <commands+0x580>
ffffffffc0200db8:	ed6ff0ef          	jal	ra,ffffffffc020048e <__panic>
    return KADDR(page2pa(page));
ffffffffc0200dbc:	00005617          	auipc	a2,0x5
ffffffffc0200dc0:	2fc60613          	addi	a2,a2,764 # ffffffffc02060b8 <commands+0x5e8>
ffffffffc0200dc4:	07100593          	li	a1,113
ffffffffc0200dc8:	00005517          	auipc	a0,0x5
ffffffffc0200dcc:	2e050513          	addi	a0,a0,736 # ffffffffc02060a8 <commands+0x5d8>
ffffffffc0200dd0:	ebeff0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0200dd4:	00005617          	auipc	a2,0x5
ffffffffc0200dd8:	2b460613          	addi	a2,a2,692 # ffffffffc0206088 <commands+0x5b8>
ffffffffc0200ddc:	06900593          	li	a1,105
ffffffffc0200de0:	00005517          	auipc	a0,0x5
ffffffffc0200de4:	2c850513          	addi	a0,a0,712 # ffffffffc02060a8 <commands+0x5d8>
ffffffffc0200de8:	ea6ff0ef          	jal	ra,ffffffffc020048e <__panic>
    return KADDR(page2pa(page));
ffffffffc0200dec:	86ae                	mv	a3,a1
ffffffffc0200dee:	00005617          	auipc	a2,0x5
ffffffffc0200df2:	2ca60613          	addi	a2,a2,714 # ffffffffc02060b8 <commands+0x5e8>
ffffffffc0200df6:	07100593          	li	a1,113
ffffffffc0200dfa:	00005517          	auipc	a0,0x5
ffffffffc0200dfe:	2ae50513          	addi	a0,a0,686 # ffffffffc02060a8 <commands+0x5d8>
ffffffffc0200e02:	e8cff0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0200e06 <interrupt_handler>:

extern struct mm_struct *check_mm_struct;

void interrupt_handler(struct trapframe *tf)
{
    intptr_t cause = (tf->cause << 1) >> 1;
ffffffffc0200e06:	11853783          	ld	a5,280(a0)
ffffffffc0200e0a:	472d                	li	a4,11
ffffffffc0200e0c:	0786                	slli	a5,a5,0x1
ffffffffc0200e0e:	8385                	srli	a5,a5,0x1
ffffffffc0200e10:	08f76463          	bltu	a4,a5,ffffffffc0200e98 <interrupt_handler+0x92>
ffffffffc0200e14:	00005717          	auipc	a4,0x5
ffffffffc0200e18:	38c70713          	addi	a4,a4,908 # ffffffffc02061a0 <commands+0x6d0>
ffffffffc0200e1c:	078a                	slli	a5,a5,0x2
ffffffffc0200e1e:	97ba                	add	a5,a5,a4
ffffffffc0200e20:	439c                	lw	a5,0(a5)
ffffffffc0200e22:	97ba                	add	a5,a5,a4
ffffffffc0200e24:	8782                	jr	a5
        break;
    case IRQ_H_SOFT:
        cprintf("Hypervisor software interrupt\n");
        break;
    case IRQ_M_SOFT:
        cprintf("Machine software interrupt\n");
ffffffffc0200e26:	00005517          	auipc	a0,0x5
ffffffffc0200e2a:	33a50513          	addi	a0,a0,826 # ffffffffc0206160 <commands+0x690>
ffffffffc0200e2e:	b66ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Hypervisor software interrupt\n");
ffffffffc0200e32:	00005517          	auipc	a0,0x5
ffffffffc0200e36:	30e50513          	addi	a0,a0,782 # ffffffffc0206140 <commands+0x670>
ffffffffc0200e3a:	b5aff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("User software interrupt\n");
ffffffffc0200e3e:	00005517          	auipc	a0,0x5
ffffffffc0200e42:	2c250513          	addi	a0,a0,706 # ffffffffc0206100 <commands+0x630>
ffffffffc0200e46:	b4eff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Supervisor software interrupt\n");
ffffffffc0200e4a:	00005517          	auipc	a0,0x5
ffffffffc0200e4e:	2d650513          	addi	a0,a0,726 # ffffffffc0206120 <commands+0x650>
ffffffffc0200e52:	b42ff06f          	j	ffffffffc0200194 <cprintf>
{
ffffffffc0200e56:	1141                	addi	sp,sp,-16
ffffffffc0200e58:	e406                	sd	ra,8(sp)
        *(1) 设置下一次时钟中断（clock_set_next_event）
        *(2) ticks 计数器自增
        *(3) 每 TICK_NUM 次中断（如 100 次），进行判断当前是否有进程正在运行，如果有则标记该进程需要被重新调度（current->need_resched）
        */
        // (1) 设置下一次时钟中断
        clock_set_next_event();
ffffffffc0200e5a:	f18ff0ef          	jal	ra,ffffffffc0200572 <clock_set_next_event>
        
        // (2) ticks 计数器自增
        ticks++;
ffffffffc0200e5e:	000bf797          	auipc	a5,0xbf
ffffffffc0200e62:	d4a78793          	addi	a5,a5,-694 # ffffffffc02bfba8 <ticks>
ffffffffc0200e66:	6398                	ld	a4,0(a5)
ffffffffc0200e68:	0705                	addi	a4,a4,1
ffffffffc0200e6a:	e398                	sd	a4,0(a5)
        
        // (3) 每 TICK_NUM 次中断，标记进程需要重新调度
        if (ticks % TICK_NUM == 0) {
ffffffffc0200e6c:	639c                	ld	a5,0(a5)
ffffffffc0200e6e:	06400713          	li	a4,100
ffffffffc0200e72:	02e7f7b3          	remu	a5,a5,a4
ffffffffc0200e76:	eb81                	bnez	a5,ffffffffc0200e86 <interrupt_handler+0x80>
            if (current != NULL) {
ffffffffc0200e78:	000bf797          	auipc	a5,0xbf
ffffffffc0200e7c:	d887b783          	ld	a5,-632(a5) # ffffffffc02bfc00 <current>
ffffffffc0200e80:	c399                	beqz	a5,ffffffffc0200e86 <interrupt_handler+0x80>
                current->need_resched = 1;
ffffffffc0200e82:	4705                	li	a4,1
ffffffffc0200e84:	ef98                	sd	a4,24(a5)
        break;
    default:
        print_trapframe(tf);
        break;
    }
}
ffffffffc0200e86:	60a2                	ld	ra,8(sp)
ffffffffc0200e88:	0141                	addi	sp,sp,16
ffffffffc0200e8a:	8082                	ret
        cprintf("Supervisor external interrupt\n");
ffffffffc0200e8c:	00005517          	auipc	a0,0x5
ffffffffc0200e90:	2f450513          	addi	a0,a0,756 # ffffffffc0206180 <commands+0x6b0>
ffffffffc0200e94:	b00ff06f          	j	ffffffffc0200194 <cprintf>
        print_trapframe(tf);
ffffffffc0200e98:	b331                	j	ffffffffc0200ba4 <print_trapframe>

ffffffffc0200e9a <exception_handler>:
void kernel_execve_ret(struct trapframe *tf, uintptr_t kstacktop);
void exception_handler(struct trapframe *tf)
{
    int ret;
    switch (tf->cause)
ffffffffc0200e9a:	11853783          	ld	a5,280(a0)
{
ffffffffc0200e9e:	1141                	addi	sp,sp,-16
ffffffffc0200ea0:	e022                	sd	s0,0(sp)
ffffffffc0200ea2:	e406                	sd	ra,8(sp)
ffffffffc0200ea4:	473d                	li	a4,15
ffffffffc0200ea6:	842a                	mv	s0,a0
ffffffffc0200ea8:	14f76763          	bltu	a4,a5,ffffffffc0200ff6 <exception_handler+0x15c>
ffffffffc0200eac:	00005717          	auipc	a4,0x5
ffffffffc0200eb0:	4b470713          	addi	a4,a4,1204 # ffffffffc0206360 <commands+0x890>
ffffffffc0200eb4:	078a                	slli	a5,a5,0x2
ffffffffc0200eb6:	97ba                	add	a5,a5,a4
ffffffffc0200eb8:	439c                	lw	a5,0(a5)
ffffffffc0200eba:	97ba                	add	a5,a5,a4
ffffffffc0200ebc:	8782                	jr	a5
        // cprintf("Environment call from U-mode\n");
        tf->epc += 4;
        syscall();
        break;
    case CAUSE_SUPERVISOR_ECALL:
        cprintf("Environment call from S-mode\n");
ffffffffc0200ebe:	00005517          	auipc	a0,0x5
ffffffffc0200ec2:	3e250513          	addi	a0,a0,994 # ffffffffc02062a0 <commands+0x7d0>
ffffffffc0200ec6:	aceff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        tf->epc += 4;
ffffffffc0200eca:	10843783          	ld	a5,264(s0)
        break;
    default:
        print_trapframe(tf);
        break;
    }
}
ffffffffc0200ece:	60a2                	ld	ra,8(sp)
        tf->epc += 4;
ffffffffc0200ed0:	0791                	addi	a5,a5,4
ffffffffc0200ed2:	10f43423          	sd	a5,264(s0)
}
ffffffffc0200ed6:	6402                	ld	s0,0(sp)
ffffffffc0200ed8:	0141                	addi	sp,sp,16
        syscall();
ffffffffc0200eda:	43c0406f          	j	ffffffffc0205316 <syscall>
        cprintf("Environment call from H-mode\n");
ffffffffc0200ede:	00005517          	auipc	a0,0x5
ffffffffc0200ee2:	3e250513          	addi	a0,a0,994 # ffffffffc02062c0 <commands+0x7f0>
}
ffffffffc0200ee6:	6402                	ld	s0,0(sp)
ffffffffc0200ee8:	60a2                	ld	ra,8(sp)
ffffffffc0200eea:	0141                	addi	sp,sp,16
        cprintf("Instruction access fault\n");
ffffffffc0200eec:	aa8ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Environment call from M-mode\n");
ffffffffc0200ef0:	00005517          	auipc	a0,0x5
ffffffffc0200ef4:	3f050513          	addi	a0,a0,1008 # ffffffffc02062e0 <commands+0x810>
ffffffffc0200ef8:	b7fd                	j	ffffffffc0200ee6 <exception_handler+0x4c>
        if ((ret = pgfault_handler(tf)) != 0) {
ffffffffc0200efa:	d0dff0ef          	jal	ra,ffffffffc0200c06 <pgfault_handler>
ffffffffc0200efe:	0c050963          	beqz	a0,ffffffffc0200fd0 <exception_handler+0x136>
            cprintf("Instruction page fault\n");
ffffffffc0200f02:	00005517          	auipc	a0,0x5
ffffffffc0200f06:	3fe50513          	addi	a0,a0,1022 # ffffffffc0206300 <commands+0x830>
ffffffffc0200f0a:	a8aff0ef          	jal	ra,ffffffffc0200194 <cprintf>
            print_trapframe(tf);
ffffffffc0200f0e:	8522                	mv	a0,s0
ffffffffc0200f10:	c95ff0ef          	jal	ra,ffffffffc0200ba4 <print_trapframe>
            if (current != NULL) {
ffffffffc0200f14:	000bf797          	auipc	a5,0xbf
ffffffffc0200f18:	cec7b783          	ld	a5,-788(a5) # ffffffffc02bfc00 <current>
ffffffffc0200f1c:	ebbd                	bnez	a5,ffffffffc0200f92 <exception_handler+0xf8>
                panic("kernel page fault");
ffffffffc0200f1e:	00005617          	auipc	a2,0x5
ffffffffc0200f22:	3fa60613          	addi	a2,a2,1018 # ffffffffc0206318 <commands+0x848>
ffffffffc0200f26:	13100593          	li	a1,305
ffffffffc0200f2a:	00005517          	auipc	a0,0x5
ffffffffc0200f2e:	12650513          	addi	a0,a0,294 # ffffffffc0206050 <commands+0x580>
ffffffffc0200f32:	d5cff0ef          	jal	ra,ffffffffc020048e <__panic>
        if ((ret = pgfault_handler(tf)) != 0) {
ffffffffc0200f36:	cd1ff0ef          	jal	ra,ffffffffc0200c06 <pgfault_handler>
ffffffffc0200f3a:	c959                	beqz	a0,ffffffffc0200fd0 <exception_handler+0x136>
            cprintf("Load page fault\n");
ffffffffc0200f3c:	00005517          	auipc	a0,0x5
ffffffffc0200f40:	3f450513          	addi	a0,a0,1012 # ffffffffc0206330 <commands+0x860>
ffffffffc0200f44:	a50ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
            print_trapframe(tf);
ffffffffc0200f48:	8522                	mv	a0,s0
ffffffffc0200f4a:	c5bff0ef          	jal	ra,ffffffffc0200ba4 <print_trapframe>
            if (current != NULL) {
ffffffffc0200f4e:	000bf797          	auipc	a5,0xbf
ffffffffc0200f52:	cb27b783          	ld	a5,-846(a5) # ffffffffc02bfc00 <current>
ffffffffc0200f56:	ef95                	bnez	a5,ffffffffc0200f92 <exception_handler+0xf8>
                panic("kernel page fault");
ffffffffc0200f58:	00005617          	auipc	a2,0x5
ffffffffc0200f5c:	3c060613          	addi	a2,a2,960 # ffffffffc0206318 <commands+0x848>
ffffffffc0200f60:	13d00593          	li	a1,317
ffffffffc0200f64:	00005517          	auipc	a0,0x5
ffffffffc0200f68:	0ec50513          	addi	a0,a0,236 # ffffffffc0206050 <commands+0x580>
ffffffffc0200f6c:	d22ff0ef          	jal	ra,ffffffffc020048e <__panic>
        if ((ret = pgfault_handler(tf)) != 0) {
ffffffffc0200f70:	c97ff0ef          	jal	ra,ffffffffc0200c06 <pgfault_handler>
ffffffffc0200f74:	cd31                	beqz	a0,ffffffffc0200fd0 <exception_handler+0x136>
            cprintf("Store/AMO page fault\n");
ffffffffc0200f76:	00005517          	auipc	a0,0x5
ffffffffc0200f7a:	3d250513          	addi	a0,a0,978 # ffffffffc0206348 <commands+0x878>
ffffffffc0200f7e:	a16ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
            print_trapframe(tf);
ffffffffc0200f82:	8522                	mv	a0,s0
ffffffffc0200f84:	c21ff0ef          	jal	ra,ffffffffc0200ba4 <print_trapframe>
            if (current != NULL) {
ffffffffc0200f88:	000bf797          	auipc	a5,0xbf
ffffffffc0200f8c:	c787b783          	ld	a5,-904(a5) # ffffffffc02bfc00 <current>
ffffffffc0200f90:	c7dd                	beqz	a5,ffffffffc020103e <exception_handler+0x1a4>
}
ffffffffc0200f92:	6402                	ld	s0,0(sp)
ffffffffc0200f94:	60a2                	ld	ra,8(sp)
                do_exit(-E_KILLED);
ffffffffc0200f96:	555d                	li	a0,-9
}
ffffffffc0200f98:	0141                	addi	sp,sp,16
                do_exit(-E_KILLED);
ffffffffc0200f9a:	5d20306f          	j	ffffffffc020456c <do_exit>
        cprintf("Instruction address misaligned\n");
ffffffffc0200f9e:	00005517          	auipc	a0,0x5
ffffffffc0200fa2:	23250513          	addi	a0,a0,562 # ffffffffc02061d0 <commands+0x700>
ffffffffc0200fa6:	b781                	j	ffffffffc0200ee6 <exception_handler+0x4c>
        cprintf("Instruction access fault\n");
ffffffffc0200fa8:	00005517          	auipc	a0,0x5
ffffffffc0200fac:	24850513          	addi	a0,a0,584 # ffffffffc02061f0 <commands+0x720>
ffffffffc0200fb0:	bf1d                	j	ffffffffc0200ee6 <exception_handler+0x4c>
        cprintf("Illegal instruction\n");
ffffffffc0200fb2:	00005517          	auipc	a0,0x5
ffffffffc0200fb6:	25e50513          	addi	a0,a0,606 # ffffffffc0206210 <commands+0x740>
ffffffffc0200fba:	b735                	j	ffffffffc0200ee6 <exception_handler+0x4c>
        cprintf("Breakpoint\n");
ffffffffc0200fbc:	00005517          	auipc	a0,0x5
ffffffffc0200fc0:	26c50513          	addi	a0,a0,620 # ffffffffc0206228 <commands+0x758>
ffffffffc0200fc4:	9d0ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        if (tf->gpr.a7 == 10)
ffffffffc0200fc8:	6458                	ld	a4,136(s0)
ffffffffc0200fca:	47a9                	li	a5,10
ffffffffc0200fcc:	04f70663          	beq	a4,a5,ffffffffc0201018 <exception_handler+0x17e>
}
ffffffffc0200fd0:	60a2                	ld	ra,8(sp)
ffffffffc0200fd2:	6402                	ld	s0,0(sp)
ffffffffc0200fd4:	0141                	addi	sp,sp,16
ffffffffc0200fd6:	8082                	ret
        cprintf("Load address misaligned\n");
ffffffffc0200fd8:	00005517          	auipc	a0,0x5
ffffffffc0200fdc:	26050513          	addi	a0,a0,608 # ffffffffc0206238 <commands+0x768>
ffffffffc0200fe0:	b719                	j	ffffffffc0200ee6 <exception_handler+0x4c>
        cprintf("Load access fault\n");
ffffffffc0200fe2:	00005517          	auipc	a0,0x5
ffffffffc0200fe6:	27650513          	addi	a0,a0,630 # ffffffffc0206258 <commands+0x788>
ffffffffc0200fea:	bdf5                	j	ffffffffc0200ee6 <exception_handler+0x4c>
        cprintf("Store/AMO access fault\n");
ffffffffc0200fec:	00005517          	auipc	a0,0x5
ffffffffc0200ff0:	29c50513          	addi	a0,a0,668 # ffffffffc0206288 <commands+0x7b8>
ffffffffc0200ff4:	bdcd                	j	ffffffffc0200ee6 <exception_handler+0x4c>
        print_trapframe(tf);
ffffffffc0200ff6:	8522                	mv	a0,s0
}
ffffffffc0200ff8:	6402                	ld	s0,0(sp)
ffffffffc0200ffa:	60a2                	ld	ra,8(sp)
ffffffffc0200ffc:	0141                	addi	sp,sp,16
        print_trapframe(tf);
ffffffffc0200ffe:	b65d                	j	ffffffffc0200ba4 <print_trapframe>
        panic("AMO address misaligned\n");
ffffffffc0201000:	00005617          	auipc	a2,0x5
ffffffffc0201004:	27060613          	addi	a2,a2,624 # ffffffffc0206270 <commands+0x7a0>
ffffffffc0201008:	11400593          	li	a1,276
ffffffffc020100c:	00005517          	auipc	a0,0x5
ffffffffc0201010:	04450513          	addi	a0,a0,68 # ffffffffc0206050 <commands+0x580>
ffffffffc0201014:	c7aff0ef          	jal	ra,ffffffffc020048e <__panic>
            tf->epc += 4;
ffffffffc0201018:	10843783          	ld	a5,264(s0)
ffffffffc020101c:	0791                	addi	a5,a5,4
ffffffffc020101e:	10f43423          	sd	a5,264(s0)
            syscall();
ffffffffc0201022:	2f4040ef          	jal	ra,ffffffffc0205316 <syscall>
            kernel_execve_ret(tf, current->kstack + KSTACKSIZE);
ffffffffc0201026:	000bf797          	auipc	a5,0xbf
ffffffffc020102a:	bda7b783          	ld	a5,-1062(a5) # ffffffffc02bfc00 <current>
ffffffffc020102e:	6b9c                	ld	a5,16(a5)
ffffffffc0201030:	8522                	mv	a0,s0
}
ffffffffc0201032:	6402                	ld	s0,0(sp)
ffffffffc0201034:	60a2                	ld	ra,8(sp)
            kernel_execve_ret(tf, current->kstack + KSTACKSIZE);
ffffffffc0201036:	6589                	lui	a1,0x2
ffffffffc0201038:	95be                	add	a1,a1,a5
}
ffffffffc020103a:	0141                	addi	sp,sp,16
            kernel_execve_ret(tf, current->kstack + KSTACKSIZE);
ffffffffc020103c:	aa8d                	j	ffffffffc02011ae <kernel_execve_ret>
                panic("kernel page fault");
ffffffffc020103e:	00005617          	auipc	a2,0x5
ffffffffc0201042:	2da60613          	addi	a2,a2,730 # ffffffffc0206318 <commands+0x848>
ffffffffc0201046:	14900593          	li	a1,329
ffffffffc020104a:	00005517          	auipc	a0,0x5
ffffffffc020104e:	00650513          	addi	a0,a0,6 # ffffffffc0206050 <commands+0x580>
ffffffffc0201052:	c3cff0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201056 <trap>:
 * trap - handles or dispatches an exception/interrupt. if and when trap() returns,
 * the code in kern/trap/trapentry.S restores the old CPU state saved in the
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void trap(struct trapframe *tf)
{
ffffffffc0201056:	1101                	addi	sp,sp,-32
ffffffffc0201058:	e822                	sd	s0,16(sp)
    // dispatch based on what type of trap occurred
    //    cputs("some trap");
    if (current == NULL)
ffffffffc020105a:	000bf417          	auipc	s0,0xbf
ffffffffc020105e:	ba640413          	addi	s0,s0,-1114 # ffffffffc02bfc00 <current>
ffffffffc0201062:	6018                	ld	a4,0(s0)
{
ffffffffc0201064:	ec06                	sd	ra,24(sp)
ffffffffc0201066:	e426                	sd	s1,8(sp)
ffffffffc0201068:	e04a                	sd	s2,0(sp)
    if ((intptr_t)tf->cause < 0)
ffffffffc020106a:	11853683          	ld	a3,280(a0)
    if (current == NULL)
ffffffffc020106e:	cf1d                	beqz	a4,ffffffffc02010ac <trap+0x56>
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0201070:	10053483          	ld	s1,256(a0)
    {
        trap_dispatch(tf);
    }
    else
    {
        struct trapframe *otf = current->tf;
ffffffffc0201074:	0a073903          	ld	s2,160(a4)
        current->tf = tf;
ffffffffc0201078:	f348                	sd	a0,160(a4)
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc020107a:	1004f493          	andi	s1,s1,256
    if ((intptr_t)tf->cause < 0)
ffffffffc020107e:	0206c463          	bltz	a3,ffffffffc02010a6 <trap+0x50>
        exception_handler(tf);
ffffffffc0201082:	e19ff0ef          	jal	ra,ffffffffc0200e9a <exception_handler>

        bool in_kernel = trap_in_kernel(tf);

        trap_dispatch(tf);

        current->tf = otf;
ffffffffc0201086:	601c                	ld	a5,0(s0)
ffffffffc0201088:	0b27b023          	sd	s2,160(a5)
        if (!in_kernel)
ffffffffc020108c:	e499                	bnez	s1,ffffffffc020109a <trap+0x44>
        {
            if (current->flags & PF_EXITING)
ffffffffc020108e:	0b07a703          	lw	a4,176(a5)
ffffffffc0201092:	8b05                	andi	a4,a4,1
ffffffffc0201094:	e329                	bnez	a4,ffffffffc02010d6 <trap+0x80>
            {
                do_exit(-E_KILLED);
            }
            if (current->need_resched)
ffffffffc0201096:	6f9c                	ld	a5,24(a5)
ffffffffc0201098:	eb85                	bnez	a5,ffffffffc02010c8 <trap+0x72>
            {
                schedule();
            }
        }
    }
}
ffffffffc020109a:	60e2                	ld	ra,24(sp)
ffffffffc020109c:	6442                	ld	s0,16(sp)
ffffffffc020109e:	64a2                	ld	s1,8(sp)
ffffffffc02010a0:	6902                	ld	s2,0(sp)
ffffffffc02010a2:	6105                	addi	sp,sp,32
ffffffffc02010a4:	8082                	ret
        interrupt_handler(tf);
ffffffffc02010a6:	d61ff0ef          	jal	ra,ffffffffc0200e06 <interrupt_handler>
ffffffffc02010aa:	bff1                	j	ffffffffc0201086 <trap+0x30>
    if ((intptr_t)tf->cause < 0)
ffffffffc02010ac:	0006c863          	bltz	a3,ffffffffc02010bc <trap+0x66>
}
ffffffffc02010b0:	6442                	ld	s0,16(sp)
ffffffffc02010b2:	60e2                	ld	ra,24(sp)
ffffffffc02010b4:	64a2                	ld	s1,8(sp)
ffffffffc02010b6:	6902                	ld	s2,0(sp)
ffffffffc02010b8:	6105                	addi	sp,sp,32
        exception_handler(tf);
ffffffffc02010ba:	b3c5                	j	ffffffffc0200e9a <exception_handler>
}
ffffffffc02010bc:	6442                	ld	s0,16(sp)
ffffffffc02010be:	60e2                	ld	ra,24(sp)
ffffffffc02010c0:	64a2                	ld	s1,8(sp)
ffffffffc02010c2:	6902                	ld	s2,0(sp)
ffffffffc02010c4:	6105                	addi	sp,sp,32
        interrupt_handler(tf);
ffffffffc02010c6:	b381                	j	ffffffffc0200e06 <interrupt_handler>
}
ffffffffc02010c8:	6442                	ld	s0,16(sp)
ffffffffc02010ca:	60e2                	ld	ra,24(sp)
ffffffffc02010cc:	64a2                	ld	s1,8(sp)
ffffffffc02010ce:	6902                	ld	s2,0(sp)
ffffffffc02010d0:	6105                	addi	sp,sp,32
                schedule();
ffffffffc02010d2:	1580406f          	j	ffffffffc020522a <schedule>
                do_exit(-E_KILLED);
ffffffffc02010d6:	555d                	li	a0,-9
ffffffffc02010d8:	494030ef          	jal	ra,ffffffffc020456c <do_exit>
            if (current->need_resched)
ffffffffc02010dc:	601c                	ld	a5,0(s0)
ffffffffc02010de:	bf65                	j	ffffffffc0201096 <trap+0x40>

ffffffffc02010e0 <__alltraps>:
    LOAD x2, 2*REGBYTES(sp)
    .endm

    .globl __alltraps
__alltraps:
    SAVE_ALL
ffffffffc02010e0:	14011173          	csrrw	sp,sscratch,sp
ffffffffc02010e4:	00011463          	bnez	sp,ffffffffc02010ec <__alltraps+0xc>
ffffffffc02010e8:	14002173          	csrr	sp,sscratch
ffffffffc02010ec:	712d                	addi	sp,sp,-288
ffffffffc02010ee:	e002                	sd	zero,0(sp)
ffffffffc02010f0:	e406                	sd	ra,8(sp)
ffffffffc02010f2:	ec0e                	sd	gp,24(sp)
ffffffffc02010f4:	f012                	sd	tp,32(sp)
ffffffffc02010f6:	f416                	sd	t0,40(sp)
ffffffffc02010f8:	f81a                	sd	t1,48(sp)
ffffffffc02010fa:	fc1e                	sd	t2,56(sp)
ffffffffc02010fc:	e0a2                	sd	s0,64(sp)
ffffffffc02010fe:	e4a6                	sd	s1,72(sp)
ffffffffc0201100:	e8aa                	sd	a0,80(sp)
ffffffffc0201102:	ecae                	sd	a1,88(sp)
ffffffffc0201104:	f0b2                	sd	a2,96(sp)
ffffffffc0201106:	f4b6                	sd	a3,104(sp)
ffffffffc0201108:	f8ba                	sd	a4,112(sp)
ffffffffc020110a:	fcbe                	sd	a5,120(sp)
ffffffffc020110c:	e142                	sd	a6,128(sp)
ffffffffc020110e:	e546                	sd	a7,136(sp)
ffffffffc0201110:	e94a                	sd	s2,144(sp)
ffffffffc0201112:	ed4e                	sd	s3,152(sp)
ffffffffc0201114:	f152                	sd	s4,160(sp)
ffffffffc0201116:	f556                	sd	s5,168(sp)
ffffffffc0201118:	f95a                	sd	s6,176(sp)
ffffffffc020111a:	fd5e                	sd	s7,184(sp)
ffffffffc020111c:	e1e2                	sd	s8,192(sp)
ffffffffc020111e:	e5e6                	sd	s9,200(sp)
ffffffffc0201120:	e9ea                	sd	s10,208(sp)
ffffffffc0201122:	edee                	sd	s11,216(sp)
ffffffffc0201124:	f1f2                	sd	t3,224(sp)
ffffffffc0201126:	f5f6                	sd	t4,232(sp)
ffffffffc0201128:	f9fa                	sd	t5,240(sp)
ffffffffc020112a:	fdfe                	sd	t6,248(sp)
ffffffffc020112c:	14001473          	csrrw	s0,sscratch,zero
ffffffffc0201130:	100024f3          	csrr	s1,sstatus
ffffffffc0201134:	14102973          	csrr	s2,sepc
ffffffffc0201138:	143029f3          	csrr	s3,stval
ffffffffc020113c:	14202a73          	csrr	s4,scause
ffffffffc0201140:	e822                	sd	s0,16(sp)
ffffffffc0201142:	e226                	sd	s1,256(sp)
ffffffffc0201144:	e64a                	sd	s2,264(sp)
ffffffffc0201146:	ea4e                	sd	s3,272(sp)
ffffffffc0201148:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc020114a:	850a                	mv	a0,sp
    jal trap
ffffffffc020114c:	f0bff0ef          	jal	ra,ffffffffc0201056 <trap>

ffffffffc0201150 <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0201150:	6492                	ld	s1,256(sp)
ffffffffc0201152:	6932                	ld	s2,264(sp)
ffffffffc0201154:	1004f413          	andi	s0,s1,256
ffffffffc0201158:	e401                	bnez	s0,ffffffffc0201160 <__trapret+0x10>
ffffffffc020115a:	1200                	addi	s0,sp,288
ffffffffc020115c:	14041073          	csrw	sscratch,s0
ffffffffc0201160:	10049073          	csrw	sstatus,s1
ffffffffc0201164:	14191073          	csrw	sepc,s2
ffffffffc0201168:	60a2                	ld	ra,8(sp)
ffffffffc020116a:	61e2                	ld	gp,24(sp)
ffffffffc020116c:	7202                	ld	tp,32(sp)
ffffffffc020116e:	72a2                	ld	t0,40(sp)
ffffffffc0201170:	7342                	ld	t1,48(sp)
ffffffffc0201172:	73e2                	ld	t2,56(sp)
ffffffffc0201174:	6406                	ld	s0,64(sp)
ffffffffc0201176:	64a6                	ld	s1,72(sp)
ffffffffc0201178:	6546                	ld	a0,80(sp)
ffffffffc020117a:	65e6                	ld	a1,88(sp)
ffffffffc020117c:	7606                	ld	a2,96(sp)
ffffffffc020117e:	76a6                	ld	a3,104(sp)
ffffffffc0201180:	7746                	ld	a4,112(sp)
ffffffffc0201182:	77e6                	ld	a5,120(sp)
ffffffffc0201184:	680a                	ld	a6,128(sp)
ffffffffc0201186:	68aa                	ld	a7,136(sp)
ffffffffc0201188:	694a                	ld	s2,144(sp)
ffffffffc020118a:	69ea                	ld	s3,152(sp)
ffffffffc020118c:	7a0a                	ld	s4,160(sp)
ffffffffc020118e:	7aaa                	ld	s5,168(sp)
ffffffffc0201190:	7b4a                	ld	s6,176(sp)
ffffffffc0201192:	7bea                	ld	s7,184(sp)
ffffffffc0201194:	6c0e                	ld	s8,192(sp)
ffffffffc0201196:	6cae                	ld	s9,200(sp)
ffffffffc0201198:	6d4e                	ld	s10,208(sp)
ffffffffc020119a:	6dee                	ld	s11,216(sp)
ffffffffc020119c:	7e0e                	ld	t3,224(sp)
ffffffffc020119e:	7eae                	ld	t4,232(sp)
ffffffffc02011a0:	7f4e                	ld	t5,240(sp)
ffffffffc02011a2:	7fee                	ld	t6,248(sp)
ffffffffc02011a4:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
ffffffffc02011a6:	10200073          	sret

ffffffffc02011aa <forkrets>:
 
    .globl forkrets
forkrets:
    # set stack to this new process's trapframe
    move sp, a0
ffffffffc02011aa:	812a                	mv	sp,a0
    j __trapret
ffffffffc02011ac:	b755                	j	ffffffffc0201150 <__trapret>

ffffffffc02011ae <kernel_execve_ret>:

    .global kernel_execve_ret
kernel_execve_ret:
    // adjust sp to beneath kstacktop of current process
    addi a1, a1, -36*REGBYTES
ffffffffc02011ae:	ee058593          	addi	a1,a1,-288 # 1ee0 <_binary_obj___user_faultread_out_size-0x7cf0>

    // copy from previous trapframe to new trapframe
    LOAD s1, 35*REGBYTES(a0)
ffffffffc02011b2:	11853483          	ld	s1,280(a0)
    STORE s1, 35*REGBYTES(a1)
ffffffffc02011b6:	1095bc23          	sd	s1,280(a1)
    LOAD s1, 34*REGBYTES(a0)
ffffffffc02011ba:	11053483          	ld	s1,272(a0)
    STORE s1, 34*REGBYTES(a1)
ffffffffc02011be:	1095b823          	sd	s1,272(a1)
    LOAD s1, 33*REGBYTES(a0)
ffffffffc02011c2:	10853483          	ld	s1,264(a0)
    STORE s1, 33*REGBYTES(a1)
ffffffffc02011c6:	1095b423          	sd	s1,264(a1)
    LOAD s1, 32*REGBYTES(a0)
ffffffffc02011ca:	10053483          	ld	s1,256(a0)
    STORE s1, 32*REGBYTES(a1)
ffffffffc02011ce:	1095b023          	sd	s1,256(a1)
    LOAD s1, 31*REGBYTES(a0)
ffffffffc02011d2:	7d64                	ld	s1,248(a0)
    STORE s1, 31*REGBYTES(a1)
ffffffffc02011d4:	fde4                	sd	s1,248(a1)
    LOAD s1, 30*REGBYTES(a0)
ffffffffc02011d6:	7964                	ld	s1,240(a0)
    STORE s1, 30*REGBYTES(a1)
ffffffffc02011d8:	f9e4                	sd	s1,240(a1)
    LOAD s1, 29*REGBYTES(a0)
ffffffffc02011da:	7564                	ld	s1,232(a0)
    STORE s1, 29*REGBYTES(a1)
ffffffffc02011dc:	f5e4                	sd	s1,232(a1)
    LOAD s1, 28*REGBYTES(a0)
ffffffffc02011de:	7164                	ld	s1,224(a0)
    STORE s1, 28*REGBYTES(a1)
ffffffffc02011e0:	f1e4                	sd	s1,224(a1)
    LOAD s1, 27*REGBYTES(a0)
ffffffffc02011e2:	6d64                	ld	s1,216(a0)
    STORE s1, 27*REGBYTES(a1)
ffffffffc02011e4:	ede4                	sd	s1,216(a1)
    LOAD s1, 26*REGBYTES(a0)
ffffffffc02011e6:	6964                	ld	s1,208(a0)
    STORE s1, 26*REGBYTES(a1)
ffffffffc02011e8:	e9e4                	sd	s1,208(a1)
    LOAD s1, 25*REGBYTES(a0)
ffffffffc02011ea:	6564                	ld	s1,200(a0)
    STORE s1, 25*REGBYTES(a1)
ffffffffc02011ec:	e5e4                	sd	s1,200(a1)
    LOAD s1, 24*REGBYTES(a0)
ffffffffc02011ee:	6164                	ld	s1,192(a0)
    STORE s1, 24*REGBYTES(a1)
ffffffffc02011f0:	e1e4                	sd	s1,192(a1)
    LOAD s1, 23*REGBYTES(a0)
ffffffffc02011f2:	7d44                	ld	s1,184(a0)
    STORE s1, 23*REGBYTES(a1)
ffffffffc02011f4:	fdc4                	sd	s1,184(a1)
    LOAD s1, 22*REGBYTES(a0)
ffffffffc02011f6:	7944                	ld	s1,176(a0)
    STORE s1, 22*REGBYTES(a1)
ffffffffc02011f8:	f9c4                	sd	s1,176(a1)
    LOAD s1, 21*REGBYTES(a0)
ffffffffc02011fa:	7544                	ld	s1,168(a0)
    STORE s1, 21*REGBYTES(a1)
ffffffffc02011fc:	f5c4                	sd	s1,168(a1)
    LOAD s1, 20*REGBYTES(a0)
ffffffffc02011fe:	7144                	ld	s1,160(a0)
    STORE s1, 20*REGBYTES(a1)
ffffffffc0201200:	f1c4                	sd	s1,160(a1)
    LOAD s1, 19*REGBYTES(a0)
ffffffffc0201202:	6d44                	ld	s1,152(a0)
    STORE s1, 19*REGBYTES(a1)
ffffffffc0201204:	edc4                	sd	s1,152(a1)
    LOAD s1, 18*REGBYTES(a0)
ffffffffc0201206:	6944                	ld	s1,144(a0)
    STORE s1, 18*REGBYTES(a1)
ffffffffc0201208:	e9c4                	sd	s1,144(a1)
    LOAD s1, 17*REGBYTES(a0)
ffffffffc020120a:	6544                	ld	s1,136(a0)
    STORE s1, 17*REGBYTES(a1)
ffffffffc020120c:	e5c4                	sd	s1,136(a1)
    LOAD s1, 16*REGBYTES(a0)
ffffffffc020120e:	6144                	ld	s1,128(a0)
    STORE s1, 16*REGBYTES(a1)
ffffffffc0201210:	e1c4                	sd	s1,128(a1)
    LOAD s1, 15*REGBYTES(a0)
ffffffffc0201212:	7d24                	ld	s1,120(a0)
    STORE s1, 15*REGBYTES(a1)
ffffffffc0201214:	fda4                	sd	s1,120(a1)
    LOAD s1, 14*REGBYTES(a0)
ffffffffc0201216:	7924                	ld	s1,112(a0)
    STORE s1, 14*REGBYTES(a1)
ffffffffc0201218:	f9a4                	sd	s1,112(a1)
    LOAD s1, 13*REGBYTES(a0)
ffffffffc020121a:	7524                	ld	s1,104(a0)
    STORE s1, 13*REGBYTES(a1)
ffffffffc020121c:	f5a4                	sd	s1,104(a1)
    LOAD s1, 12*REGBYTES(a0)
ffffffffc020121e:	7124                	ld	s1,96(a0)
    STORE s1, 12*REGBYTES(a1)
ffffffffc0201220:	f1a4                	sd	s1,96(a1)
    LOAD s1, 11*REGBYTES(a0)
ffffffffc0201222:	6d24                	ld	s1,88(a0)
    STORE s1, 11*REGBYTES(a1)
ffffffffc0201224:	eda4                	sd	s1,88(a1)
    LOAD s1, 10*REGBYTES(a0)
ffffffffc0201226:	6924                	ld	s1,80(a0)
    STORE s1, 10*REGBYTES(a1)
ffffffffc0201228:	e9a4                	sd	s1,80(a1)
    LOAD s1, 9*REGBYTES(a0)
ffffffffc020122a:	6524                	ld	s1,72(a0)
    STORE s1, 9*REGBYTES(a1)
ffffffffc020122c:	e5a4                	sd	s1,72(a1)
    LOAD s1, 8*REGBYTES(a0)
ffffffffc020122e:	6124                	ld	s1,64(a0)
    STORE s1, 8*REGBYTES(a1)
ffffffffc0201230:	e1a4                	sd	s1,64(a1)
    LOAD s1, 7*REGBYTES(a0)
ffffffffc0201232:	7d04                	ld	s1,56(a0)
    STORE s1, 7*REGBYTES(a1)
ffffffffc0201234:	fd84                	sd	s1,56(a1)
    LOAD s1, 6*REGBYTES(a0)
ffffffffc0201236:	7904                	ld	s1,48(a0)
    STORE s1, 6*REGBYTES(a1)
ffffffffc0201238:	f984                	sd	s1,48(a1)
    LOAD s1, 5*REGBYTES(a0)
ffffffffc020123a:	7504                	ld	s1,40(a0)
    STORE s1, 5*REGBYTES(a1)
ffffffffc020123c:	f584                	sd	s1,40(a1)
    LOAD s1, 4*REGBYTES(a0)
ffffffffc020123e:	7104                	ld	s1,32(a0)
    STORE s1, 4*REGBYTES(a1)
ffffffffc0201240:	f184                	sd	s1,32(a1)
    LOAD s1, 3*REGBYTES(a0)
ffffffffc0201242:	6d04                	ld	s1,24(a0)
    STORE s1, 3*REGBYTES(a1)
ffffffffc0201244:	ed84                	sd	s1,24(a1)
    LOAD s1, 2*REGBYTES(a0)
ffffffffc0201246:	6904                	ld	s1,16(a0)
    STORE s1, 2*REGBYTES(a1)
ffffffffc0201248:	e984                	sd	s1,16(a1)
    LOAD s1, 1*REGBYTES(a0)
ffffffffc020124a:	6504                	ld	s1,8(a0)
    STORE s1, 1*REGBYTES(a1)
ffffffffc020124c:	e584                	sd	s1,8(a1)
    LOAD s1, 0*REGBYTES(a0)
ffffffffc020124e:	6104                	ld	s1,0(a0)
    STORE s1, 0*REGBYTES(a1)
ffffffffc0201250:	e184                	sd	s1,0(a1)

    // acutually adjust sp
    move sp, a1
ffffffffc0201252:	812e                	mv	sp,a1
ffffffffc0201254:	bdf5                	j	ffffffffc0201150 <__trapret>

ffffffffc0201256 <default_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0201256:	000bb797          	auipc	a5,0xbb
ffffffffc020125a:	92278793          	addi	a5,a5,-1758 # ffffffffc02bbb78 <free_area>
ffffffffc020125e:	e79c                	sd	a5,8(a5)
ffffffffc0201260:	e39c                	sd	a5,0(a5)

static void
default_init(void)
{
    list_init(&free_list);
    nr_free = 0;
ffffffffc0201262:	0007a823          	sw	zero,16(a5)
}
ffffffffc0201266:	8082                	ret

ffffffffc0201268 <default_nr_free_pages>:

static size_t
default_nr_free_pages(void)
{
    return nr_free;
}
ffffffffc0201268:	000bb517          	auipc	a0,0xbb
ffffffffc020126c:	92056503          	lwu	a0,-1760(a0) # ffffffffc02bbb88 <free_area+0x10>
ffffffffc0201270:	8082                	ret

ffffffffc0201272 <default_check>:

// LAB2: below code is used to check the first fit allocation algorithm (your EXERCISE 1)
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void)
{
ffffffffc0201272:	715d                	addi	sp,sp,-80
ffffffffc0201274:	e0a2                	sd	s0,64(sp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0201276:	000bb417          	auipc	s0,0xbb
ffffffffc020127a:	90240413          	addi	s0,s0,-1790 # ffffffffc02bbb78 <free_area>
ffffffffc020127e:	641c                	ld	a5,8(s0)
ffffffffc0201280:	e486                	sd	ra,72(sp)
ffffffffc0201282:	fc26                	sd	s1,56(sp)
ffffffffc0201284:	f84a                	sd	s2,48(sp)
ffffffffc0201286:	f44e                	sd	s3,40(sp)
ffffffffc0201288:	f052                	sd	s4,32(sp)
ffffffffc020128a:	ec56                	sd	s5,24(sp)
ffffffffc020128c:	e85a                	sd	s6,16(sp)
ffffffffc020128e:	e45e                	sd	s7,8(sp)
ffffffffc0201290:	e062                	sd	s8,0(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list)
ffffffffc0201292:	2a878d63          	beq	a5,s0,ffffffffc020154c <default_check+0x2da>
    int count = 0, total = 0;
ffffffffc0201296:	4481                	li	s1,0
ffffffffc0201298:	4901                	li	s2,0
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc020129a:	ff07b703          	ld	a4,-16(a5)
    {
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc020129e:	8b09                	andi	a4,a4,2
ffffffffc02012a0:	2a070a63          	beqz	a4,ffffffffc0201554 <default_check+0x2e2>
        count++, total += p->property;
ffffffffc02012a4:	ff87a703          	lw	a4,-8(a5)
ffffffffc02012a8:	679c                	ld	a5,8(a5)
ffffffffc02012aa:	2905                	addiw	s2,s2,1
ffffffffc02012ac:	9cb9                	addw	s1,s1,a4
    while ((le = list_next(le)) != &free_list)
ffffffffc02012ae:	fe8796e3          	bne	a5,s0,ffffffffc020129a <default_check+0x28>
    }
    assert(total == nr_free_pages());
ffffffffc02012b2:	89a6                	mv	s3,s1
ffffffffc02012b4:	6df000ef          	jal	ra,ffffffffc0202192 <nr_free_pages>
ffffffffc02012b8:	6f351e63          	bne	a0,s3,ffffffffc02019b4 <default_check+0x742>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02012bc:	4505                	li	a0,1
ffffffffc02012be:	657000ef          	jal	ra,ffffffffc0202114 <alloc_pages>
ffffffffc02012c2:	8aaa                	mv	s5,a0
ffffffffc02012c4:	42050863          	beqz	a0,ffffffffc02016f4 <default_check+0x482>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02012c8:	4505                	li	a0,1
ffffffffc02012ca:	64b000ef          	jal	ra,ffffffffc0202114 <alloc_pages>
ffffffffc02012ce:	89aa                	mv	s3,a0
ffffffffc02012d0:	70050263          	beqz	a0,ffffffffc02019d4 <default_check+0x762>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02012d4:	4505                	li	a0,1
ffffffffc02012d6:	63f000ef          	jal	ra,ffffffffc0202114 <alloc_pages>
ffffffffc02012da:	8a2a                	mv	s4,a0
ffffffffc02012dc:	48050c63          	beqz	a0,ffffffffc0201774 <default_check+0x502>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc02012e0:	293a8a63          	beq	s5,s3,ffffffffc0201574 <default_check+0x302>
ffffffffc02012e4:	28aa8863          	beq	s5,a0,ffffffffc0201574 <default_check+0x302>
ffffffffc02012e8:	28a98663          	beq	s3,a0,ffffffffc0201574 <default_check+0x302>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc02012ec:	000aa783          	lw	a5,0(s5)
ffffffffc02012f0:	2a079263          	bnez	a5,ffffffffc0201594 <default_check+0x322>
ffffffffc02012f4:	0009a783          	lw	a5,0(s3)
ffffffffc02012f8:	28079e63          	bnez	a5,ffffffffc0201594 <default_check+0x322>
ffffffffc02012fc:	411c                	lw	a5,0(a0)
ffffffffc02012fe:	28079b63          	bnez	a5,ffffffffc0201594 <default_check+0x322>
    return page - pages + nbase;
ffffffffc0201302:	000bf797          	auipc	a5,0xbf
ffffffffc0201306:	8e67b783          	ld	a5,-1818(a5) # ffffffffc02bfbe8 <pages>
ffffffffc020130a:	40fa8733          	sub	a4,s5,a5
ffffffffc020130e:	00006617          	auipc	a2,0x6
ffffffffc0201312:	6d263603          	ld	a2,1746(a2) # ffffffffc02079e0 <nbase>
ffffffffc0201316:	8719                	srai	a4,a4,0x6
ffffffffc0201318:	9732                	add	a4,a4,a2
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc020131a:	000bf697          	auipc	a3,0xbf
ffffffffc020131e:	8c66b683          	ld	a3,-1850(a3) # ffffffffc02bfbe0 <npage>
ffffffffc0201322:	06b2                	slli	a3,a3,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0201324:	0732                	slli	a4,a4,0xc
ffffffffc0201326:	28d77763          	bgeu	a4,a3,ffffffffc02015b4 <default_check+0x342>
    return page - pages + nbase;
ffffffffc020132a:	40f98733          	sub	a4,s3,a5
ffffffffc020132e:	8719                	srai	a4,a4,0x6
ffffffffc0201330:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0201332:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0201334:	4cd77063          	bgeu	a4,a3,ffffffffc02017f4 <default_check+0x582>
    return page - pages + nbase;
ffffffffc0201338:	40f507b3          	sub	a5,a0,a5
ffffffffc020133c:	8799                	srai	a5,a5,0x6
ffffffffc020133e:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0201340:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0201342:	30d7f963          	bgeu	a5,a3,ffffffffc0201654 <default_check+0x3e2>
    assert(alloc_page() == NULL);
ffffffffc0201346:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0201348:	00043c03          	ld	s8,0(s0)
ffffffffc020134c:	00843b83          	ld	s7,8(s0)
    unsigned int nr_free_store = nr_free;
ffffffffc0201350:	01042b03          	lw	s6,16(s0)
    elm->prev = elm->next = elm;
ffffffffc0201354:	e400                	sd	s0,8(s0)
ffffffffc0201356:	e000                	sd	s0,0(s0)
    nr_free = 0;
ffffffffc0201358:	000bb797          	auipc	a5,0xbb
ffffffffc020135c:	8207a823          	sw	zero,-2000(a5) # ffffffffc02bbb88 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc0201360:	5b5000ef          	jal	ra,ffffffffc0202114 <alloc_pages>
ffffffffc0201364:	2c051863          	bnez	a0,ffffffffc0201634 <default_check+0x3c2>
    free_page(p0);
ffffffffc0201368:	4585                	li	a1,1
ffffffffc020136a:	8556                	mv	a0,s5
ffffffffc020136c:	5e7000ef          	jal	ra,ffffffffc0202152 <free_pages>
    free_page(p1);
ffffffffc0201370:	4585                	li	a1,1
ffffffffc0201372:	854e                	mv	a0,s3
ffffffffc0201374:	5df000ef          	jal	ra,ffffffffc0202152 <free_pages>
    free_page(p2);
ffffffffc0201378:	4585                	li	a1,1
ffffffffc020137a:	8552                	mv	a0,s4
ffffffffc020137c:	5d7000ef          	jal	ra,ffffffffc0202152 <free_pages>
    assert(nr_free == 3);
ffffffffc0201380:	4818                	lw	a4,16(s0)
ffffffffc0201382:	478d                	li	a5,3
ffffffffc0201384:	28f71863          	bne	a4,a5,ffffffffc0201614 <default_check+0x3a2>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201388:	4505                	li	a0,1
ffffffffc020138a:	58b000ef          	jal	ra,ffffffffc0202114 <alloc_pages>
ffffffffc020138e:	89aa                	mv	s3,a0
ffffffffc0201390:	26050263          	beqz	a0,ffffffffc02015f4 <default_check+0x382>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201394:	4505                	li	a0,1
ffffffffc0201396:	57f000ef          	jal	ra,ffffffffc0202114 <alloc_pages>
ffffffffc020139a:	8aaa                	mv	s5,a0
ffffffffc020139c:	3a050c63          	beqz	a0,ffffffffc0201754 <default_check+0x4e2>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02013a0:	4505                	li	a0,1
ffffffffc02013a2:	573000ef          	jal	ra,ffffffffc0202114 <alloc_pages>
ffffffffc02013a6:	8a2a                	mv	s4,a0
ffffffffc02013a8:	38050663          	beqz	a0,ffffffffc0201734 <default_check+0x4c2>
    assert(alloc_page() == NULL);
ffffffffc02013ac:	4505                	li	a0,1
ffffffffc02013ae:	567000ef          	jal	ra,ffffffffc0202114 <alloc_pages>
ffffffffc02013b2:	36051163          	bnez	a0,ffffffffc0201714 <default_check+0x4a2>
    free_page(p0);
ffffffffc02013b6:	4585                	li	a1,1
ffffffffc02013b8:	854e                	mv	a0,s3
ffffffffc02013ba:	599000ef          	jal	ra,ffffffffc0202152 <free_pages>
    assert(!list_empty(&free_list));
ffffffffc02013be:	641c                	ld	a5,8(s0)
ffffffffc02013c0:	20878a63          	beq	a5,s0,ffffffffc02015d4 <default_check+0x362>
    assert((p = alloc_page()) == p0);
ffffffffc02013c4:	4505                	li	a0,1
ffffffffc02013c6:	54f000ef          	jal	ra,ffffffffc0202114 <alloc_pages>
ffffffffc02013ca:	30a99563          	bne	s3,a0,ffffffffc02016d4 <default_check+0x462>
    assert(alloc_page() == NULL);
ffffffffc02013ce:	4505                	li	a0,1
ffffffffc02013d0:	545000ef          	jal	ra,ffffffffc0202114 <alloc_pages>
ffffffffc02013d4:	2e051063          	bnez	a0,ffffffffc02016b4 <default_check+0x442>
    assert(nr_free == 0);
ffffffffc02013d8:	481c                	lw	a5,16(s0)
ffffffffc02013da:	2a079d63          	bnez	a5,ffffffffc0201694 <default_check+0x422>
    free_page(p);
ffffffffc02013de:	854e                	mv	a0,s3
ffffffffc02013e0:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc02013e2:	01843023          	sd	s8,0(s0)
ffffffffc02013e6:	01743423          	sd	s7,8(s0)
    nr_free = nr_free_store;
ffffffffc02013ea:	01642823          	sw	s6,16(s0)
    free_page(p);
ffffffffc02013ee:	565000ef          	jal	ra,ffffffffc0202152 <free_pages>
    free_page(p1);
ffffffffc02013f2:	4585                	li	a1,1
ffffffffc02013f4:	8556                	mv	a0,s5
ffffffffc02013f6:	55d000ef          	jal	ra,ffffffffc0202152 <free_pages>
    free_page(p2);
ffffffffc02013fa:	4585                	li	a1,1
ffffffffc02013fc:	8552                	mv	a0,s4
ffffffffc02013fe:	555000ef          	jal	ra,ffffffffc0202152 <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0201402:	4515                	li	a0,5
ffffffffc0201404:	511000ef          	jal	ra,ffffffffc0202114 <alloc_pages>
ffffffffc0201408:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc020140a:	26050563          	beqz	a0,ffffffffc0201674 <default_check+0x402>
ffffffffc020140e:	651c                	ld	a5,8(a0)
ffffffffc0201410:	8385                	srli	a5,a5,0x1
ffffffffc0201412:	8b85                	andi	a5,a5,1
    assert(!PageProperty(p0));
ffffffffc0201414:	54079063          	bnez	a5,ffffffffc0201954 <default_check+0x6e2>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0201418:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc020141a:	00043b03          	ld	s6,0(s0)
ffffffffc020141e:	00843a83          	ld	s5,8(s0)
ffffffffc0201422:	e000                	sd	s0,0(s0)
ffffffffc0201424:	e400                	sd	s0,8(s0)
    assert(alloc_page() == NULL);
ffffffffc0201426:	4ef000ef          	jal	ra,ffffffffc0202114 <alloc_pages>
ffffffffc020142a:	50051563          	bnez	a0,ffffffffc0201934 <default_check+0x6c2>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc020142e:	08098a13          	addi	s4,s3,128
ffffffffc0201432:	8552                	mv	a0,s4
ffffffffc0201434:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc0201436:	01042b83          	lw	s7,16(s0)
    nr_free = 0;
ffffffffc020143a:	000ba797          	auipc	a5,0xba
ffffffffc020143e:	7407a723          	sw	zero,1870(a5) # ffffffffc02bbb88 <free_area+0x10>
    free_pages(p0 + 2, 3);
ffffffffc0201442:	511000ef          	jal	ra,ffffffffc0202152 <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc0201446:	4511                	li	a0,4
ffffffffc0201448:	4cd000ef          	jal	ra,ffffffffc0202114 <alloc_pages>
ffffffffc020144c:	4c051463          	bnez	a0,ffffffffc0201914 <default_check+0x6a2>
ffffffffc0201450:	0889b783          	ld	a5,136(s3)
ffffffffc0201454:	8385                	srli	a5,a5,0x1
ffffffffc0201456:	8b85                	andi	a5,a5,1
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0201458:	48078e63          	beqz	a5,ffffffffc02018f4 <default_check+0x682>
ffffffffc020145c:	0909a703          	lw	a4,144(s3)
ffffffffc0201460:	478d                	li	a5,3
ffffffffc0201462:	48f71963          	bne	a4,a5,ffffffffc02018f4 <default_check+0x682>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0201466:	450d                	li	a0,3
ffffffffc0201468:	4ad000ef          	jal	ra,ffffffffc0202114 <alloc_pages>
ffffffffc020146c:	8c2a                	mv	s8,a0
ffffffffc020146e:	46050363          	beqz	a0,ffffffffc02018d4 <default_check+0x662>
    assert(alloc_page() == NULL);
ffffffffc0201472:	4505                	li	a0,1
ffffffffc0201474:	4a1000ef          	jal	ra,ffffffffc0202114 <alloc_pages>
ffffffffc0201478:	42051e63          	bnez	a0,ffffffffc02018b4 <default_check+0x642>
    assert(p0 + 2 == p1);
ffffffffc020147c:	418a1c63          	bne	s4,s8,ffffffffc0201894 <default_check+0x622>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc0201480:	4585                	li	a1,1
ffffffffc0201482:	854e                	mv	a0,s3
ffffffffc0201484:	4cf000ef          	jal	ra,ffffffffc0202152 <free_pages>
    free_pages(p1, 3);
ffffffffc0201488:	458d                	li	a1,3
ffffffffc020148a:	8552                	mv	a0,s4
ffffffffc020148c:	4c7000ef          	jal	ra,ffffffffc0202152 <free_pages>
ffffffffc0201490:	0089b783          	ld	a5,8(s3)
    p2 = p0 + 1;
ffffffffc0201494:	04098c13          	addi	s8,s3,64
ffffffffc0201498:	8385                	srli	a5,a5,0x1
ffffffffc020149a:	8b85                	andi	a5,a5,1
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc020149c:	3c078c63          	beqz	a5,ffffffffc0201874 <default_check+0x602>
ffffffffc02014a0:	0109a703          	lw	a4,16(s3)
ffffffffc02014a4:	4785                	li	a5,1
ffffffffc02014a6:	3cf71763          	bne	a4,a5,ffffffffc0201874 <default_check+0x602>
ffffffffc02014aa:	008a3783          	ld	a5,8(s4)
ffffffffc02014ae:	8385                	srli	a5,a5,0x1
ffffffffc02014b0:	8b85                	andi	a5,a5,1
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc02014b2:	3a078163          	beqz	a5,ffffffffc0201854 <default_check+0x5e2>
ffffffffc02014b6:	010a2703          	lw	a4,16(s4)
ffffffffc02014ba:	478d                	li	a5,3
ffffffffc02014bc:	38f71c63          	bne	a4,a5,ffffffffc0201854 <default_check+0x5e2>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc02014c0:	4505                	li	a0,1
ffffffffc02014c2:	453000ef          	jal	ra,ffffffffc0202114 <alloc_pages>
ffffffffc02014c6:	36a99763          	bne	s3,a0,ffffffffc0201834 <default_check+0x5c2>
    free_page(p0);
ffffffffc02014ca:	4585                	li	a1,1
ffffffffc02014cc:	487000ef          	jal	ra,ffffffffc0202152 <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc02014d0:	4509                	li	a0,2
ffffffffc02014d2:	443000ef          	jal	ra,ffffffffc0202114 <alloc_pages>
ffffffffc02014d6:	32aa1f63          	bne	s4,a0,ffffffffc0201814 <default_check+0x5a2>

    free_pages(p0, 2);
ffffffffc02014da:	4589                	li	a1,2
ffffffffc02014dc:	477000ef          	jal	ra,ffffffffc0202152 <free_pages>
    free_page(p2);
ffffffffc02014e0:	4585                	li	a1,1
ffffffffc02014e2:	8562                	mv	a0,s8
ffffffffc02014e4:	46f000ef          	jal	ra,ffffffffc0202152 <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc02014e8:	4515                	li	a0,5
ffffffffc02014ea:	42b000ef          	jal	ra,ffffffffc0202114 <alloc_pages>
ffffffffc02014ee:	89aa                	mv	s3,a0
ffffffffc02014f0:	48050263          	beqz	a0,ffffffffc0201974 <default_check+0x702>
    assert(alloc_page() == NULL);
ffffffffc02014f4:	4505                	li	a0,1
ffffffffc02014f6:	41f000ef          	jal	ra,ffffffffc0202114 <alloc_pages>
ffffffffc02014fa:	2c051d63          	bnez	a0,ffffffffc02017d4 <default_check+0x562>

    assert(nr_free == 0);
ffffffffc02014fe:	481c                	lw	a5,16(s0)
ffffffffc0201500:	2a079a63          	bnez	a5,ffffffffc02017b4 <default_check+0x542>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc0201504:	4595                	li	a1,5
ffffffffc0201506:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc0201508:	01742823          	sw	s7,16(s0)
    free_list = free_list_store;
ffffffffc020150c:	01643023          	sd	s6,0(s0)
ffffffffc0201510:	01543423          	sd	s5,8(s0)
    free_pages(p0, 5);
ffffffffc0201514:	43f000ef          	jal	ra,ffffffffc0202152 <free_pages>
    return listelm->next;
ffffffffc0201518:	641c                	ld	a5,8(s0)

    le = &free_list;
    while ((le = list_next(le)) != &free_list)
ffffffffc020151a:	00878963          	beq	a5,s0,ffffffffc020152c <default_check+0x2ba>
    {
        struct Page *p = le2page(le, page_link);
        count--, total -= p->property;
ffffffffc020151e:	ff87a703          	lw	a4,-8(a5)
ffffffffc0201522:	679c                	ld	a5,8(a5)
ffffffffc0201524:	397d                	addiw	s2,s2,-1
ffffffffc0201526:	9c99                	subw	s1,s1,a4
    while ((le = list_next(le)) != &free_list)
ffffffffc0201528:	fe879be3          	bne	a5,s0,ffffffffc020151e <default_check+0x2ac>
    }
    assert(count == 0);
ffffffffc020152c:	26091463          	bnez	s2,ffffffffc0201794 <default_check+0x522>
    assert(total == 0);
ffffffffc0201530:	46049263          	bnez	s1,ffffffffc0201994 <default_check+0x722>
}
ffffffffc0201534:	60a6                	ld	ra,72(sp)
ffffffffc0201536:	6406                	ld	s0,64(sp)
ffffffffc0201538:	74e2                	ld	s1,56(sp)
ffffffffc020153a:	7942                	ld	s2,48(sp)
ffffffffc020153c:	79a2                	ld	s3,40(sp)
ffffffffc020153e:	7a02                	ld	s4,32(sp)
ffffffffc0201540:	6ae2                	ld	s5,24(sp)
ffffffffc0201542:	6b42                	ld	s6,16(sp)
ffffffffc0201544:	6ba2                	ld	s7,8(sp)
ffffffffc0201546:	6c02                	ld	s8,0(sp)
ffffffffc0201548:	6161                	addi	sp,sp,80
ffffffffc020154a:	8082                	ret
    while ((le = list_next(le)) != &free_list)
ffffffffc020154c:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc020154e:	4481                	li	s1,0
ffffffffc0201550:	4901                	li	s2,0
ffffffffc0201552:	b38d                	j	ffffffffc02012b4 <default_check+0x42>
        assert(PageProperty(p));
ffffffffc0201554:	00005697          	auipc	a3,0x5
ffffffffc0201558:	e4c68693          	addi	a3,a3,-436 # ffffffffc02063a0 <commands+0x8d0>
ffffffffc020155c:	00005617          	auipc	a2,0x5
ffffffffc0201560:	e5460613          	addi	a2,a2,-428 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc0201564:	11000593          	li	a1,272
ffffffffc0201568:	00005517          	auipc	a0,0x5
ffffffffc020156c:	e6050513          	addi	a0,a0,-416 # ffffffffc02063c8 <commands+0x8f8>
ffffffffc0201570:	f1ffe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0201574:	00005697          	auipc	a3,0x5
ffffffffc0201578:	eec68693          	addi	a3,a3,-276 # ffffffffc0206460 <commands+0x990>
ffffffffc020157c:	00005617          	auipc	a2,0x5
ffffffffc0201580:	e3460613          	addi	a2,a2,-460 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc0201584:	0db00593          	li	a1,219
ffffffffc0201588:	00005517          	auipc	a0,0x5
ffffffffc020158c:	e4050513          	addi	a0,a0,-448 # ffffffffc02063c8 <commands+0x8f8>
ffffffffc0201590:	efffe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0201594:	00005697          	auipc	a3,0x5
ffffffffc0201598:	ef468693          	addi	a3,a3,-268 # ffffffffc0206488 <commands+0x9b8>
ffffffffc020159c:	00005617          	auipc	a2,0x5
ffffffffc02015a0:	e1460613          	addi	a2,a2,-492 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc02015a4:	0dc00593          	li	a1,220
ffffffffc02015a8:	00005517          	auipc	a0,0x5
ffffffffc02015ac:	e2050513          	addi	a0,a0,-480 # ffffffffc02063c8 <commands+0x8f8>
ffffffffc02015b0:	edffe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc02015b4:	00005697          	auipc	a3,0x5
ffffffffc02015b8:	f1468693          	addi	a3,a3,-236 # ffffffffc02064c8 <commands+0x9f8>
ffffffffc02015bc:	00005617          	auipc	a2,0x5
ffffffffc02015c0:	df460613          	addi	a2,a2,-524 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc02015c4:	0de00593          	li	a1,222
ffffffffc02015c8:	00005517          	auipc	a0,0x5
ffffffffc02015cc:	e0050513          	addi	a0,a0,-512 # ffffffffc02063c8 <commands+0x8f8>
ffffffffc02015d0:	ebffe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(!list_empty(&free_list));
ffffffffc02015d4:	00005697          	auipc	a3,0x5
ffffffffc02015d8:	f7c68693          	addi	a3,a3,-132 # ffffffffc0206550 <commands+0xa80>
ffffffffc02015dc:	00005617          	auipc	a2,0x5
ffffffffc02015e0:	dd460613          	addi	a2,a2,-556 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc02015e4:	0f700593          	li	a1,247
ffffffffc02015e8:	00005517          	auipc	a0,0x5
ffffffffc02015ec:	de050513          	addi	a0,a0,-544 # ffffffffc02063c8 <commands+0x8f8>
ffffffffc02015f0:	e9ffe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02015f4:	00005697          	auipc	a3,0x5
ffffffffc02015f8:	e0c68693          	addi	a3,a3,-500 # ffffffffc0206400 <commands+0x930>
ffffffffc02015fc:	00005617          	auipc	a2,0x5
ffffffffc0201600:	db460613          	addi	a2,a2,-588 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc0201604:	0f000593          	li	a1,240
ffffffffc0201608:	00005517          	auipc	a0,0x5
ffffffffc020160c:	dc050513          	addi	a0,a0,-576 # ffffffffc02063c8 <commands+0x8f8>
ffffffffc0201610:	e7ffe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_free == 3);
ffffffffc0201614:	00005697          	auipc	a3,0x5
ffffffffc0201618:	f2c68693          	addi	a3,a3,-212 # ffffffffc0206540 <commands+0xa70>
ffffffffc020161c:	00005617          	auipc	a2,0x5
ffffffffc0201620:	d9460613          	addi	a2,a2,-620 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc0201624:	0ee00593          	li	a1,238
ffffffffc0201628:	00005517          	auipc	a0,0x5
ffffffffc020162c:	da050513          	addi	a0,a0,-608 # ffffffffc02063c8 <commands+0x8f8>
ffffffffc0201630:	e5ffe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201634:	00005697          	auipc	a3,0x5
ffffffffc0201638:	ef468693          	addi	a3,a3,-268 # ffffffffc0206528 <commands+0xa58>
ffffffffc020163c:	00005617          	auipc	a2,0x5
ffffffffc0201640:	d7460613          	addi	a2,a2,-652 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc0201644:	0e900593          	li	a1,233
ffffffffc0201648:	00005517          	auipc	a0,0x5
ffffffffc020164c:	d8050513          	addi	a0,a0,-640 # ffffffffc02063c8 <commands+0x8f8>
ffffffffc0201650:	e3ffe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0201654:	00005697          	auipc	a3,0x5
ffffffffc0201658:	eb468693          	addi	a3,a3,-332 # ffffffffc0206508 <commands+0xa38>
ffffffffc020165c:	00005617          	auipc	a2,0x5
ffffffffc0201660:	d5460613          	addi	a2,a2,-684 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc0201664:	0e000593          	li	a1,224
ffffffffc0201668:	00005517          	auipc	a0,0x5
ffffffffc020166c:	d6050513          	addi	a0,a0,-672 # ffffffffc02063c8 <commands+0x8f8>
ffffffffc0201670:	e1ffe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(p0 != NULL);
ffffffffc0201674:	00005697          	auipc	a3,0x5
ffffffffc0201678:	f2468693          	addi	a3,a3,-220 # ffffffffc0206598 <commands+0xac8>
ffffffffc020167c:	00005617          	auipc	a2,0x5
ffffffffc0201680:	d3460613          	addi	a2,a2,-716 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc0201684:	11800593          	li	a1,280
ffffffffc0201688:	00005517          	auipc	a0,0x5
ffffffffc020168c:	d4050513          	addi	a0,a0,-704 # ffffffffc02063c8 <commands+0x8f8>
ffffffffc0201690:	dfffe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_free == 0);
ffffffffc0201694:	00005697          	auipc	a3,0x5
ffffffffc0201698:	ef468693          	addi	a3,a3,-268 # ffffffffc0206588 <commands+0xab8>
ffffffffc020169c:	00005617          	auipc	a2,0x5
ffffffffc02016a0:	d1460613          	addi	a2,a2,-748 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc02016a4:	0fd00593          	li	a1,253
ffffffffc02016a8:	00005517          	auipc	a0,0x5
ffffffffc02016ac:	d2050513          	addi	a0,a0,-736 # ffffffffc02063c8 <commands+0x8f8>
ffffffffc02016b0:	ddffe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc02016b4:	00005697          	auipc	a3,0x5
ffffffffc02016b8:	e7468693          	addi	a3,a3,-396 # ffffffffc0206528 <commands+0xa58>
ffffffffc02016bc:	00005617          	auipc	a2,0x5
ffffffffc02016c0:	cf460613          	addi	a2,a2,-780 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc02016c4:	0fb00593          	li	a1,251
ffffffffc02016c8:	00005517          	auipc	a0,0x5
ffffffffc02016cc:	d0050513          	addi	a0,a0,-768 # ffffffffc02063c8 <commands+0x8f8>
ffffffffc02016d0:	dbffe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc02016d4:	00005697          	auipc	a3,0x5
ffffffffc02016d8:	e9468693          	addi	a3,a3,-364 # ffffffffc0206568 <commands+0xa98>
ffffffffc02016dc:	00005617          	auipc	a2,0x5
ffffffffc02016e0:	cd460613          	addi	a2,a2,-812 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc02016e4:	0fa00593          	li	a1,250
ffffffffc02016e8:	00005517          	auipc	a0,0x5
ffffffffc02016ec:	ce050513          	addi	a0,a0,-800 # ffffffffc02063c8 <commands+0x8f8>
ffffffffc02016f0:	d9ffe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02016f4:	00005697          	auipc	a3,0x5
ffffffffc02016f8:	d0c68693          	addi	a3,a3,-756 # ffffffffc0206400 <commands+0x930>
ffffffffc02016fc:	00005617          	auipc	a2,0x5
ffffffffc0201700:	cb460613          	addi	a2,a2,-844 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc0201704:	0d700593          	li	a1,215
ffffffffc0201708:	00005517          	auipc	a0,0x5
ffffffffc020170c:	cc050513          	addi	a0,a0,-832 # ffffffffc02063c8 <commands+0x8f8>
ffffffffc0201710:	d7ffe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201714:	00005697          	auipc	a3,0x5
ffffffffc0201718:	e1468693          	addi	a3,a3,-492 # ffffffffc0206528 <commands+0xa58>
ffffffffc020171c:	00005617          	auipc	a2,0x5
ffffffffc0201720:	c9460613          	addi	a2,a2,-876 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc0201724:	0f400593          	li	a1,244
ffffffffc0201728:	00005517          	auipc	a0,0x5
ffffffffc020172c:	ca050513          	addi	a0,a0,-864 # ffffffffc02063c8 <commands+0x8f8>
ffffffffc0201730:	d5ffe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201734:	00005697          	auipc	a3,0x5
ffffffffc0201738:	d0c68693          	addi	a3,a3,-756 # ffffffffc0206440 <commands+0x970>
ffffffffc020173c:	00005617          	auipc	a2,0x5
ffffffffc0201740:	c7460613          	addi	a2,a2,-908 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc0201744:	0f200593          	li	a1,242
ffffffffc0201748:	00005517          	auipc	a0,0x5
ffffffffc020174c:	c8050513          	addi	a0,a0,-896 # ffffffffc02063c8 <commands+0x8f8>
ffffffffc0201750:	d3ffe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201754:	00005697          	auipc	a3,0x5
ffffffffc0201758:	ccc68693          	addi	a3,a3,-820 # ffffffffc0206420 <commands+0x950>
ffffffffc020175c:	00005617          	auipc	a2,0x5
ffffffffc0201760:	c5460613          	addi	a2,a2,-940 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc0201764:	0f100593          	li	a1,241
ffffffffc0201768:	00005517          	auipc	a0,0x5
ffffffffc020176c:	c6050513          	addi	a0,a0,-928 # ffffffffc02063c8 <commands+0x8f8>
ffffffffc0201770:	d1ffe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201774:	00005697          	auipc	a3,0x5
ffffffffc0201778:	ccc68693          	addi	a3,a3,-820 # ffffffffc0206440 <commands+0x970>
ffffffffc020177c:	00005617          	auipc	a2,0x5
ffffffffc0201780:	c3460613          	addi	a2,a2,-972 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc0201784:	0d900593          	li	a1,217
ffffffffc0201788:	00005517          	auipc	a0,0x5
ffffffffc020178c:	c4050513          	addi	a0,a0,-960 # ffffffffc02063c8 <commands+0x8f8>
ffffffffc0201790:	cfffe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(count == 0);
ffffffffc0201794:	00005697          	auipc	a3,0x5
ffffffffc0201798:	f5468693          	addi	a3,a3,-172 # ffffffffc02066e8 <commands+0xc18>
ffffffffc020179c:	00005617          	auipc	a2,0x5
ffffffffc02017a0:	c1460613          	addi	a2,a2,-1004 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc02017a4:	14600593          	li	a1,326
ffffffffc02017a8:	00005517          	auipc	a0,0x5
ffffffffc02017ac:	c2050513          	addi	a0,a0,-992 # ffffffffc02063c8 <commands+0x8f8>
ffffffffc02017b0:	cdffe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_free == 0);
ffffffffc02017b4:	00005697          	auipc	a3,0x5
ffffffffc02017b8:	dd468693          	addi	a3,a3,-556 # ffffffffc0206588 <commands+0xab8>
ffffffffc02017bc:	00005617          	auipc	a2,0x5
ffffffffc02017c0:	bf460613          	addi	a2,a2,-1036 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc02017c4:	13a00593          	li	a1,314
ffffffffc02017c8:	00005517          	auipc	a0,0x5
ffffffffc02017cc:	c0050513          	addi	a0,a0,-1024 # ffffffffc02063c8 <commands+0x8f8>
ffffffffc02017d0:	cbffe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc02017d4:	00005697          	auipc	a3,0x5
ffffffffc02017d8:	d5468693          	addi	a3,a3,-684 # ffffffffc0206528 <commands+0xa58>
ffffffffc02017dc:	00005617          	auipc	a2,0x5
ffffffffc02017e0:	bd460613          	addi	a2,a2,-1068 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc02017e4:	13800593          	li	a1,312
ffffffffc02017e8:	00005517          	auipc	a0,0x5
ffffffffc02017ec:	be050513          	addi	a0,a0,-1056 # ffffffffc02063c8 <commands+0x8f8>
ffffffffc02017f0:	c9ffe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc02017f4:	00005697          	auipc	a3,0x5
ffffffffc02017f8:	cf468693          	addi	a3,a3,-780 # ffffffffc02064e8 <commands+0xa18>
ffffffffc02017fc:	00005617          	auipc	a2,0x5
ffffffffc0201800:	bb460613          	addi	a2,a2,-1100 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc0201804:	0df00593          	li	a1,223
ffffffffc0201808:	00005517          	auipc	a0,0x5
ffffffffc020180c:	bc050513          	addi	a0,a0,-1088 # ffffffffc02063c8 <commands+0x8f8>
ffffffffc0201810:	c7ffe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0201814:	00005697          	auipc	a3,0x5
ffffffffc0201818:	e9468693          	addi	a3,a3,-364 # ffffffffc02066a8 <commands+0xbd8>
ffffffffc020181c:	00005617          	auipc	a2,0x5
ffffffffc0201820:	b9460613          	addi	a2,a2,-1132 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc0201824:	13200593          	li	a1,306
ffffffffc0201828:	00005517          	auipc	a0,0x5
ffffffffc020182c:	ba050513          	addi	a0,a0,-1120 # ffffffffc02063c8 <commands+0x8f8>
ffffffffc0201830:	c5ffe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0201834:	00005697          	auipc	a3,0x5
ffffffffc0201838:	e5468693          	addi	a3,a3,-428 # ffffffffc0206688 <commands+0xbb8>
ffffffffc020183c:	00005617          	auipc	a2,0x5
ffffffffc0201840:	b7460613          	addi	a2,a2,-1164 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc0201844:	13000593          	li	a1,304
ffffffffc0201848:	00005517          	auipc	a0,0x5
ffffffffc020184c:	b8050513          	addi	a0,a0,-1152 # ffffffffc02063c8 <commands+0x8f8>
ffffffffc0201850:	c3ffe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0201854:	00005697          	auipc	a3,0x5
ffffffffc0201858:	e0c68693          	addi	a3,a3,-500 # ffffffffc0206660 <commands+0xb90>
ffffffffc020185c:	00005617          	auipc	a2,0x5
ffffffffc0201860:	b5460613          	addi	a2,a2,-1196 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc0201864:	12e00593          	li	a1,302
ffffffffc0201868:	00005517          	auipc	a0,0x5
ffffffffc020186c:	b6050513          	addi	a0,a0,-1184 # ffffffffc02063c8 <commands+0x8f8>
ffffffffc0201870:	c1ffe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0201874:	00005697          	auipc	a3,0x5
ffffffffc0201878:	dc468693          	addi	a3,a3,-572 # ffffffffc0206638 <commands+0xb68>
ffffffffc020187c:	00005617          	auipc	a2,0x5
ffffffffc0201880:	b3460613          	addi	a2,a2,-1228 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc0201884:	12d00593          	li	a1,301
ffffffffc0201888:	00005517          	auipc	a0,0x5
ffffffffc020188c:	b4050513          	addi	a0,a0,-1216 # ffffffffc02063c8 <commands+0x8f8>
ffffffffc0201890:	bfffe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(p0 + 2 == p1);
ffffffffc0201894:	00005697          	auipc	a3,0x5
ffffffffc0201898:	d9468693          	addi	a3,a3,-620 # ffffffffc0206628 <commands+0xb58>
ffffffffc020189c:	00005617          	auipc	a2,0x5
ffffffffc02018a0:	b1460613          	addi	a2,a2,-1260 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc02018a4:	12800593          	li	a1,296
ffffffffc02018a8:	00005517          	auipc	a0,0x5
ffffffffc02018ac:	b2050513          	addi	a0,a0,-1248 # ffffffffc02063c8 <commands+0x8f8>
ffffffffc02018b0:	bdffe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc02018b4:	00005697          	auipc	a3,0x5
ffffffffc02018b8:	c7468693          	addi	a3,a3,-908 # ffffffffc0206528 <commands+0xa58>
ffffffffc02018bc:	00005617          	auipc	a2,0x5
ffffffffc02018c0:	af460613          	addi	a2,a2,-1292 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc02018c4:	12700593          	li	a1,295
ffffffffc02018c8:	00005517          	auipc	a0,0x5
ffffffffc02018cc:	b0050513          	addi	a0,a0,-1280 # ffffffffc02063c8 <commands+0x8f8>
ffffffffc02018d0:	bbffe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc02018d4:	00005697          	auipc	a3,0x5
ffffffffc02018d8:	d3468693          	addi	a3,a3,-716 # ffffffffc0206608 <commands+0xb38>
ffffffffc02018dc:	00005617          	auipc	a2,0x5
ffffffffc02018e0:	ad460613          	addi	a2,a2,-1324 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc02018e4:	12600593          	li	a1,294
ffffffffc02018e8:	00005517          	auipc	a0,0x5
ffffffffc02018ec:	ae050513          	addi	a0,a0,-1312 # ffffffffc02063c8 <commands+0x8f8>
ffffffffc02018f0:	b9ffe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc02018f4:	00005697          	auipc	a3,0x5
ffffffffc02018f8:	ce468693          	addi	a3,a3,-796 # ffffffffc02065d8 <commands+0xb08>
ffffffffc02018fc:	00005617          	auipc	a2,0x5
ffffffffc0201900:	ab460613          	addi	a2,a2,-1356 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc0201904:	12500593          	li	a1,293
ffffffffc0201908:	00005517          	auipc	a0,0x5
ffffffffc020190c:	ac050513          	addi	a0,a0,-1344 # ffffffffc02063c8 <commands+0x8f8>
ffffffffc0201910:	b7ffe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc0201914:	00005697          	auipc	a3,0x5
ffffffffc0201918:	cac68693          	addi	a3,a3,-852 # ffffffffc02065c0 <commands+0xaf0>
ffffffffc020191c:	00005617          	auipc	a2,0x5
ffffffffc0201920:	a9460613          	addi	a2,a2,-1388 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc0201924:	12400593          	li	a1,292
ffffffffc0201928:	00005517          	auipc	a0,0x5
ffffffffc020192c:	aa050513          	addi	a0,a0,-1376 # ffffffffc02063c8 <commands+0x8f8>
ffffffffc0201930:	b5ffe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201934:	00005697          	auipc	a3,0x5
ffffffffc0201938:	bf468693          	addi	a3,a3,-1036 # ffffffffc0206528 <commands+0xa58>
ffffffffc020193c:	00005617          	auipc	a2,0x5
ffffffffc0201940:	a7460613          	addi	a2,a2,-1420 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc0201944:	11e00593          	li	a1,286
ffffffffc0201948:	00005517          	auipc	a0,0x5
ffffffffc020194c:	a8050513          	addi	a0,a0,-1408 # ffffffffc02063c8 <commands+0x8f8>
ffffffffc0201950:	b3ffe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(!PageProperty(p0));
ffffffffc0201954:	00005697          	auipc	a3,0x5
ffffffffc0201958:	c5468693          	addi	a3,a3,-940 # ffffffffc02065a8 <commands+0xad8>
ffffffffc020195c:	00005617          	auipc	a2,0x5
ffffffffc0201960:	a5460613          	addi	a2,a2,-1452 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc0201964:	11900593          	li	a1,281
ffffffffc0201968:	00005517          	auipc	a0,0x5
ffffffffc020196c:	a6050513          	addi	a0,a0,-1440 # ffffffffc02063c8 <commands+0x8f8>
ffffffffc0201970:	b1ffe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0201974:	00005697          	auipc	a3,0x5
ffffffffc0201978:	d5468693          	addi	a3,a3,-684 # ffffffffc02066c8 <commands+0xbf8>
ffffffffc020197c:	00005617          	auipc	a2,0x5
ffffffffc0201980:	a3460613          	addi	a2,a2,-1484 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc0201984:	13700593          	li	a1,311
ffffffffc0201988:	00005517          	auipc	a0,0x5
ffffffffc020198c:	a4050513          	addi	a0,a0,-1472 # ffffffffc02063c8 <commands+0x8f8>
ffffffffc0201990:	afffe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(total == 0);
ffffffffc0201994:	00005697          	auipc	a3,0x5
ffffffffc0201998:	d6468693          	addi	a3,a3,-668 # ffffffffc02066f8 <commands+0xc28>
ffffffffc020199c:	00005617          	auipc	a2,0x5
ffffffffc02019a0:	a1460613          	addi	a2,a2,-1516 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc02019a4:	14700593          	li	a1,327
ffffffffc02019a8:	00005517          	auipc	a0,0x5
ffffffffc02019ac:	a2050513          	addi	a0,a0,-1504 # ffffffffc02063c8 <commands+0x8f8>
ffffffffc02019b0:	adffe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(total == nr_free_pages());
ffffffffc02019b4:	00005697          	auipc	a3,0x5
ffffffffc02019b8:	a2c68693          	addi	a3,a3,-1492 # ffffffffc02063e0 <commands+0x910>
ffffffffc02019bc:	00005617          	auipc	a2,0x5
ffffffffc02019c0:	9f460613          	addi	a2,a2,-1548 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc02019c4:	11300593          	li	a1,275
ffffffffc02019c8:	00005517          	auipc	a0,0x5
ffffffffc02019cc:	a0050513          	addi	a0,a0,-1536 # ffffffffc02063c8 <commands+0x8f8>
ffffffffc02019d0:	abffe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02019d4:	00005697          	auipc	a3,0x5
ffffffffc02019d8:	a4c68693          	addi	a3,a3,-1460 # ffffffffc0206420 <commands+0x950>
ffffffffc02019dc:	00005617          	auipc	a2,0x5
ffffffffc02019e0:	9d460613          	addi	a2,a2,-1580 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc02019e4:	0d800593          	li	a1,216
ffffffffc02019e8:	00005517          	auipc	a0,0x5
ffffffffc02019ec:	9e050513          	addi	a0,a0,-1568 # ffffffffc02063c8 <commands+0x8f8>
ffffffffc02019f0:	a9ffe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02019f4 <default_free_pages>:
{
ffffffffc02019f4:	1141                	addi	sp,sp,-16
ffffffffc02019f6:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02019f8:	14058463          	beqz	a1,ffffffffc0201b40 <default_free_pages+0x14c>
    for (; p != base + n; p++)
ffffffffc02019fc:	00659693          	slli	a3,a1,0x6
ffffffffc0201a00:	96aa                	add	a3,a3,a0
ffffffffc0201a02:	87aa                	mv	a5,a0
ffffffffc0201a04:	02d50263          	beq	a0,a3,ffffffffc0201a28 <default_free_pages+0x34>
ffffffffc0201a08:	6798                	ld	a4,8(a5)
ffffffffc0201a0a:	8b05                	andi	a4,a4,1
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0201a0c:	10071a63          	bnez	a4,ffffffffc0201b20 <default_free_pages+0x12c>
ffffffffc0201a10:	6798                	ld	a4,8(a5)
ffffffffc0201a12:	8b09                	andi	a4,a4,2
ffffffffc0201a14:	10071663          	bnez	a4,ffffffffc0201b20 <default_free_pages+0x12c>
        p->flags = 0;
ffffffffc0201a18:	0007b423          	sd	zero,8(a5)
    page->ref = val;
ffffffffc0201a1c:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p++)
ffffffffc0201a20:	04078793          	addi	a5,a5,64
ffffffffc0201a24:	fed792e3          	bne	a5,a3,ffffffffc0201a08 <default_free_pages+0x14>
    base->property = n;
ffffffffc0201a28:	2581                	sext.w	a1,a1
ffffffffc0201a2a:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc0201a2c:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201a30:	4789                	li	a5,2
ffffffffc0201a32:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc0201a36:	000ba697          	auipc	a3,0xba
ffffffffc0201a3a:	14268693          	addi	a3,a3,322 # ffffffffc02bbb78 <free_area>
ffffffffc0201a3e:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc0201a40:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc0201a42:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc0201a46:	9db9                	addw	a1,a1,a4
ffffffffc0201a48:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list))
ffffffffc0201a4a:	0ad78463          	beq	a5,a3,ffffffffc0201af2 <default_free_pages+0xfe>
            struct Page *page = le2page(le, page_link);
ffffffffc0201a4e:	fe878713          	addi	a4,a5,-24
ffffffffc0201a52:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list))
ffffffffc0201a56:	4581                	li	a1,0
            if (base < page)
ffffffffc0201a58:	00e56a63          	bltu	a0,a4,ffffffffc0201a6c <default_free_pages+0x78>
    return listelm->next;
ffffffffc0201a5c:	6798                	ld	a4,8(a5)
            else if (list_next(le) == &free_list)
ffffffffc0201a5e:	04d70c63          	beq	a4,a3,ffffffffc0201ab6 <default_free_pages+0xc2>
    for (; p != base + n; p++)
ffffffffc0201a62:	87ba                	mv	a5,a4
            struct Page *page = le2page(le, page_link);
ffffffffc0201a64:	fe878713          	addi	a4,a5,-24
            if (base < page)
ffffffffc0201a68:	fee57ae3          	bgeu	a0,a4,ffffffffc0201a5c <default_free_pages+0x68>
ffffffffc0201a6c:	c199                	beqz	a1,ffffffffc0201a72 <default_free_pages+0x7e>
ffffffffc0201a6e:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0201a72:	6398                	ld	a4,0(a5)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc0201a74:	e390                	sd	a2,0(a5)
ffffffffc0201a76:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc0201a78:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201a7a:	ed18                	sd	a4,24(a0)
    if (le != &free_list)
ffffffffc0201a7c:	00d70d63          	beq	a4,a3,ffffffffc0201a96 <default_free_pages+0xa2>
        if (p + p->property == base)
ffffffffc0201a80:	ff872583          	lw	a1,-8(a4)
        p = le2page(le, page_link);
ffffffffc0201a84:	fe870613          	addi	a2,a4,-24
        if (p + p->property == base)
ffffffffc0201a88:	02059813          	slli	a6,a1,0x20
ffffffffc0201a8c:	01a85793          	srli	a5,a6,0x1a
ffffffffc0201a90:	97b2                	add	a5,a5,a2
ffffffffc0201a92:	02f50c63          	beq	a0,a5,ffffffffc0201aca <default_free_pages+0xd6>
    return listelm->next;
ffffffffc0201a96:	711c                	ld	a5,32(a0)
    if (le != &free_list)
ffffffffc0201a98:	00d78c63          	beq	a5,a3,ffffffffc0201ab0 <default_free_pages+0xbc>
        if (base + base->property == p)
ffffffffc0201a9c:	4910                	lw	a2,16(a0)
        p = le2page(le, page_link);
ffffffffc0201a9e:	fe878693          	addi	a3,a5,-24
        if (base + base->property == p)
ffffffffc0201aa2:	02061593          	slli	a1,a2,0x20
ffffffffc0201aa6:	01a5d713          	srli	a4,a1,0x1a
ffffffffc0201aaa:	972a                	add	a4,a4,a0
ffffffffc0201aac:	04e68a63          	beq	a3,a4,ffffffffc0201b00 <default_free_pages+0x10c>
}
ffffffffc0201ab0:	60a2                	ld	ra,8(sp)
ffffffffc0201ab2:	0141                	addi	sp,sp,16
ffffffffc0201ab4:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0201ab6:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201ab8:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0201aba:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0201abc:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list)
ffffffffc0201abe:	02d70763          	beq	a4,a3,ffffffffc0201aec <default_free_pages+0xf8>
    prev->next = next->prev = elm;
ffffffffc0201ac2:	8832                	mv	a6,a2
ffffffffc0201ac4:	4585                	li	a1,1
    for (; p != base + n; p++)
ffffffffc0201ac6:	87ba                	mv	a5,a4
ffffffffc0201ac8:	bf71                	j	ffffffffc0201a64 <default_free_pages+0x70>
            p->property += base->property;
ffffffffc0201aca:	491c                	lw	a5,16(a0)
ffffffffc0201acc:	9dbd                	addw	a1,a1,a5
ffffffffc0201ace:	feb72c23          	sw	a1,-8(a4)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0201ad2:	57f5                	li	a5,-3
ffffffffc0201ad4:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201ad8:	01853803          	ld	a6,24(a0)
ffffffffc0201adc:	710c                	ld	a1,32(a0)
            base = p;
ffffffffc0201ade:	8532                	mv	a0,a2
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0201ae0:	00b83423          	sd	a1,8(a6)
    return listelm->next;
ffffffffc0201ae4:	671c                	ld	a5,8(a4)
    next->prev = prev;
ffffffffc0201ae6:	0105b023          	sd	a6,0(a1)
ffffffffc0201aea:	b77d                	j	ffffffffc0201a98 <default_free_pages+0xa4>
ffffffffc0201aec:	e290                	sd	a2,0(a3)
        while ((le = list_next(le)) != &free_list)
ffffffffc0201aee:	873e                	mv	a4,a5
ffffffffc0201af0:	bf41                	j	ffffffffc0201a80 <default_free_pages+0x8c>
}
ffffffffc0201af2:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0201af4:	e390                	sd	a2,0(a5)
ffffffffc0201af6:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201af8:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201afa:	ed1c                	sd	a5,24(a0)
ffffffffc0201afc:	0141                	addi	sp,sp,16
ffffffffc0201afe:	8082                	ret
            base->property += p->property;
ffffffffc0201b00:	ff87a703          	lw	a4,-8(a5)
ffffffffc0201b04:	ff078693          	addi	a3,a5,-16
ffffffffc0201b08:	9e39                	addw	a2,a2,a4
ffffffffc0201b0a:	c910                	sw	a2,16(a0)
ffffffffc0201b0c:	5775                	li	a4,-3
ffffffffc0201b0e:	60e6b02f          	amoand.d	zero,a4,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201b12:	6398                	ld	a4,0(a5)
ffffffffc0201b14:	679c                	ld	a5,8(a5)
}
ffffffffc0201b16:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc0201b18:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0201b1a:	e398                	sd	a4,0(a5)
ffffffffc0201b1c:	0141                	addi	sp,sp,16
ffffffffc0201b1e:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0201b20:	00005697          	auipc	a3,0x5
ffffffffc0201b24:	bf068693          	addi	a3,a3,-1040 # ffffffffc0206710 <commands+0xc40>
ffffffffc0201b28:	00005617          	auipc	a2,0x5
ffffffffc0201b2c:	88860613          	addi	a2,a2,-1912 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc0201b30:	09400593          	li	a1,148
ffffffffc0201b34:	00005517          	auipc	a0,0x5
ffffffffc0201b38:	89450513          	addi	a0,a0,-1900 # ffffffffc02063c8 <commands+0x8f8>
ffffffffc0201b3c:	953fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(n > 0);
ffffffffc0201b40:	00005697          	auipc	a3,0x5
ffffffffc0201b44:	bc868693          	addi	a3,a3,-1080 # ffffffffc0206708 <commands+0xc38>
ffffffffc0201b48:	00005617          	auipc	a2,0x5
ffffffffc0201b4c:	86860613          	addi	a2,a2,-1944 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc0201b50:	09000593          	li	a1,144
ffffffffc0201b54:	00005517          	auipc	a0,0x5
ffffffffc0201b58:	87450513          	addi	a0,a0,-1932 # ffffffffc02063c8 <commands+0x8f8>
ffffffffc0201b5c:	933fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201b60 <default_alloc_pages>:
    assert(n > 0);
ffffffffc0201b60:	c941                	beqz	a0,ffffffffc0201bf0 <default_alloc_pages+0x90>
    if (n > nr_free)
ffffffffc0201b62:	000ba597          	auipc	a1,0xba
ffffffffc0201b66:	01658593          	addi	a1,a1,22 # ffffffffc02bbb78 <free_area>
ffffffffc0201b6a:	0105a803          	lw	a6,16(a1)
ffffffffc0201b6e:	872a                	mv	a4,a0
ffffffffc0201b70:	02081793          	slli	a5,a6,0x20
ffffffffc0201b74:	9381                	srli	a5,a5,0x20
ffffffffc0201b76:	00a7ee63          	bltu	a5,a0,ffffffffc0201b92 <default_alloc_pages+0x32>
    list_entry_t *le = &free_list;
ffffffffc0201b7a:	87ae                	mv	a5,a1
ffffffffc0201b7c:	a801                	j	ffffffffc0201b8c <default_alloc_pages+0x2c>
        if (p->property >= n)
ffffffffc0201b7e:	ff87a683          	lw	a3,-8(a5)
ffffffffc0201b82:	02069613          	slli	a2,a3,0x20
ffffffffc0201b86:	9201                	srli	a2,a2,0x20
ffffffffc0201b88:	00e67763          	bgeu	a2,a4,ffffffffc0201b96 <default_alloc_pages+0x36>
    return listelm->next;
ffffffffc0201b8c:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list)
ffffffffc0201b8e:	feb798e3          	bne	a5,a1,ffffffffc0201b7e <default_alloc_pages+0x1e>
        return NULL;
ffffffffc0201b92:	4501                	li	a0,0
}
ffffffffc0201b94:	8082                	ret
    return listelm->prev;
ffffffffc0201b96:	0007b883          	ld	a7,0(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201b9a:	0087b303          	ld	t1,8(a5)
        struct Page *p = le2page(le, page_link);
ffffffffc0201b9e:	fe878513          	addi	a0,a5,-24
            p->property = page->property - n;
ffffffffc0201ba2:	00070e1b          	sext.w	t3,a4
    prev->next = next;
ffffffffc0201ba6:	0068b423          	sd	t1,8(a7)
    next->prev = prev;
ffffffffc0201baa:	01133023          	sd	a7,0(t1)
        if (page->property > n)
ffffffffc0201bae:	02c77863          	bgeu	a4,a2,ffffffffc0201bde <default_alloc_pages+0x7e>
            struct Page *p = page + n;
ffffffffc0201bb2:	071a                	slli	a4,a4,0x6
ffffffffc0201bb4:	972a                	add	a4,a4,a0
            p->property = page->property - n;
ffffffffc0201bb6:	41c686bb          	subw	a3,a3,t3
ffffffffc0201bba:	cb14                	sw	a3,16(a4)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201bbc:	00870613          	addi	a2,a4,8
ffffffffc0201bc0:	4689                	li	a3,2
ffffffffc0201bc2:	40d6302f          	amoor.d	zero,a3,(a2)
    __list_add(elm, listelm, listelm->next);
ffffffffc0201bc6:	0088b683          	ld	a3,8(a7)
            list_add(prev, &(p->page_link));
ffffffffc0201bca:	01870613          	addi	a2,a4,24
        nr_free -= n;
ffffffffc0201bce:	0105a803          	lw	a6,16(a1)
    prev->next = next->prev = elm;
ffffffffc0201bd2:	e290                	sd	a2,0(a3)
ffffffffc0201bd4:	00c8b423          	sd	a2,8(a7)
    elm->next = next;
ffffffffc0201bd8:	f314                	sd	a3,32(a4)
    elm->prev = prev;
ffffffffc0201bda:	01173c23          	sd	a7,24(a4)
ffffffffc0201bde:	41c8083b          	subw	a6,a6,t3
ffffffffc0201be2:	0105a823          	sw	a6,16(a1)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0201be6:	5775                	li	a4,-3
ffffffffc0201be8:	17c1                	addi	a5,a5,-16
ffffffffc0201bea:	60e7b02f          	amoand.d	zero,a4,(a5)
}
ffffffffc0201bee:	8082                	ret
{
ffffffffc0201bf0:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc0201bf2:	00005697          	auipc	a3,0x5
ffffffffc0201bf6:	b1668693          	addi	a3,a3,-1258 # ffffffffc0206708 <commands+0xc38>
ffffffffc0201bfa:	00004617          	auipc	a2,0x4
ffffffffc0201bfe:	7b660613          	addi	a2,a2,1974 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc0201c02:	06c00593          	li	a1,108
ffffffffc0201c06:	00004517          	auipc	a0,0x4
ffffffffc0201c0a:	7c250513          	addi	a0,a0,1986 # ffffffffc02063c8 <commands+0x8f8>
{
ffffffffc0201c0e:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201c10:	87ffe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201c14 <default_init_memmap>:
{
ffffffffc0201c14:	1141                	addi	sp,sp,-16
ffffffffc0201c16:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201c18:	c5f1                	beqz	a1,ffffffffc0201ce4 <default_init_memmap+0xd0>
    for (; p != base + n; p++)
ffffffffc0201c1a:	00659693          	slli	a3,a1,0x6
ffffffffc0201c1e:	96aa                	add	a3,a3,a0
ffffffffc0201c20:	87aa                	mv	a5,a0
ffffffffc0201c22:	00d50f63          	beq	a0,a3,ffffffffc0201c40 <default_init_memmap+0x2c>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0201c26:	6798                	ld	a4,8(a5)
ffffffffc0201c28:	8b05                	andi	a4,a4,1
        assert(PageReserved(p));
ffffffffc0201c2a:	cf49                	beqz	a4,ffffffffc0201cc4 <default_init_memmap+0xb0>
        p->flags = p->property = 0;
ffffffffc0201c2c:	0007a823          	sw	zero,16(a5)
ffffffffc0201c30:	0007b423          	sd	zero,8(a5)
ffffffffc0201c34:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p++)
ffffffffc0201c38:	04078793          	addi	a5,a5,64
ffffffffc0201c3c:	fed795e3          	bne	a5,a3,ffffffffc0201c26 <default_init_memmap+0x12>
    base->property = n;
ffffffffc0201c40:	2581                	sext.w	a1,a1
ffffffffc0201c42:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201c44:	4789                	li	a5,2
ffffffffc0201c46:	00850713          	addi	a4,a0,8
ffffffffc0201c4a:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc0201c4e:	000ba697          	auipc	a3,0xba
ffffffffc0201c52:	f2a68693          	addi	a3,a3,-214 # ffffffffc02bbb78 <free_area>
ffffffffc0201c56:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc0201c58:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc0201c5a:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc0201c5e:	9db9                	addw	a1,a1,a4
ffffffffc0201c60:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list))
ffffffffc0201c62:	04d78a63          	beq	a5,a3,ffffffffc0201cb6 <default_init_memmap+0xa2>
            struct Page *page = le2page(le, page_link);
ffffffffc0201c66:	fe878713          	addi	a4,a5,-24
ffffffffc0201c6a:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list))
ffffffffc0201c6e:	4581                	li	a1,0
            if (base < page)
ffffffffc0201c70:	00e56a63          	bltu	a0,a4,ffffffffc0201c84 <default_init_memmap+0x70>
    return listelm->next;
ffffffffc0201c74:	6798                	ld	a4,8(a5)
            else if (list_next(le) == &free_list)
ffffffffc0201c76:	02d70263          	beq	a4,a3,ffffffffc0201c9a <default_init_memmap+0x86>
    for (; p != base + n; p++)
ffffffffc0201c7a:	87ba                	mv	a5,a4
            struct Page *page = le2page(le, page_link);
ffffffffc0201c7c:	fe878713          	addi	a4,a5,-24
            if (base < page)
ffffffffc0201c80:	fee57ae3          	bgeu	a0,a4,ffffffffc0201c74 <default_init_memmap+0x60>
ffffffffc0201c84:	c199                	beqz	a1,ffffffffc0201c8a <default_init_memmap+0x76>
ffffffffc0201c86:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0201c8a:	6398                	ld	a4,0(a5)
}
ffffffffc0201c8c:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0201c8e:	e390                	sd	a2,0(a5)
ffffffffc0201c90:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc0201c92:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201c94:	ed18                	sd	a4,24(a0)
ffffffffc0201c96:	0141                	addi	sp,sp,16
ffffffffc0201c98:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0201c9a:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201c9c:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0201c9e:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0201ca0:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list)
ffffffffc0201ca2:	00d70663          	beq	a4,a3,ffffffffc0201cae <default_init_memmap+0x9a>
    prev->next = next->prev = elm;
ffffffffc0201ca6:	8832                	mv	a6,a2
ffffffffc0201ca8:	4585                	li	a1,1
    for (; p != base + n; p++)
ffffffffc0201caa:	87ba                	mv	a5,a4
ffffffffc0201cac:	bfc1                	j	ffffffffc0201c7c <default_init_memmap+0x68>
}
ffffffffc0201cae:	60a2                	ld	ra,8(sp)
ffffffffc0201cb0:	e290                	sd	a2,0(a3)
ffffffffc0201cb2:	0141                	addi	sp,sp,16
ffffffffc0201cb4:	8082                	ret
ffffffffc0201cb6:	60a2                	ld	ra,8(sp)
ffffffffc0201cb8:	e390                	sd	a2,0(a5)
ffffffffc0201cba:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201cbc:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201cbe:	ed1c                	sd	a5,24(a0)
ffffffffc0201cc0:	0141                	addi	sp,sp,16
ffffffffc0201cc2:	8082                	ret
        assert(PageReserved(p));
ffffffffc0201cc4:	00005697          	auipc	a3,0x5
ffffffffc0201cc8:	a7468693          	addi	a3,a3,-1420 # ffffffffc0206738 <commands+0xc68>
ffffffffc0201ccc:	00004617          	auipc	a2,0x4
ffffffffc0201cd0:	6e460613          	addi	a2,a2,1764 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc0201cd4:	04b00593          	li	a1,75
ffffffffc0201cd8:	00004517          	auipc	a0,0x4
ffffffffc0201cdc:	6f050513          	addi	a0,a0,1776 # ffffffffc02063c8 <commands+0x8f8>
ffffffffc0201ce0:	faefe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(n > 0);
ffffffffc0201ce4:	00005697          	auipc	a3,0x5
ffffffffc0201ce8:	a2468693          	addi	a3,a3,-1500 # ffffffffc0206708 <commands+0xc38>
ffffffffc0201cec:	00004617          	auipc	a2,0x4
ffffffffc0201cf0:	6c460613          	addi	a2,a2,1732 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc0201cf4:	04700593          	li	a1,71
ffffffffc0201cf8:	00004517          	auipc	a0,0x4
ffffffffc0201cfc:	6d050513          	addi	a0,a0,1744 # ffffffffc02063c8 <commands+0x8f8>
ffffffffc0201d00:	f8efe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201d04 <slob_free>:
static void slob_free(void *block, int size)
{
	slob_t *cur, *b = (slob_t *)block;
	unsigned long flags;

	if (!block)
ffffffffc0201d04:	c94d                	beqz	a0,ffffffffc0201db6 <slob_free+0xb2>
{
ffffffffc0201d06:	1141                	addi	sp,sp,-16
ffffffffc0201d08:	e022                	sd	s0,0(sp)
ffffffffc0201d0a:	e406                	sd	ra,8(sp)
ffffffffc0201d0c:	842a                	mv	s0,a0
		return;

	if (size)
ffffffffc0201d0e:	e9c1                	bnez	a1,ffffffffc0201d9e <slob_free+0x9a>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201d10:	100027f3          	csrr	a5,sstatus
ffffffffc0201d14:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0201d16:	4501                	li	a0,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201d18:	ebd9                	bnez	a5,ffffffffc0201dae <slob_free+0xaa>
		b->units = SLOB_UNITS(size);

	/* Find reinsertion point */
	spin_lock_irqsave(&slob_lock, flags);
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201d1a:	000ba617          	auipc	a2,0xba
ffffffffc0201d1e:	a4e60613          	addi	a2,a2,-1458 # ffffffffc02bb768 <slobfree>
ffffffffc0201d22:	621c                	ld	a5,0(a2)
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201d24:	873e                	mv	a4,a5
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201d26:	679c                	ld	a5,8(a5)
ffffffffc0201d28:	02877a63          	bgeu	a4,s0,ffffffffc0201d5c <slob_free+0x58>
ffffffffc0201d2c:	00f46463          	bltu	s0,a5,ffffffffc0201d34 <slob_free+0x30>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201d30:	fef76ae3          	bltu	a4,a5,ffffffffc0201d24 <slob_free+0x20>
			break;

	if (b + b->units == cur->next)
ffffffffc0201d34:	400c                	lw	a1,0(s0)
ffffffffc0201d36:	00459693          	slli	a3,a1,0x4
ffffffffc0201d3a:	96a2                	add	a3,a3,s0
ffffffffc0201d3c:	02d78a63          	beq	a5,a3,ffffffffc0201d70 <slob_free+0x6c>
		b->next = cur->next->next;
	}
	else
		b->next = cur->next;

	if (cur + cur->units == b)
ffffffffc0201d40:	4314                	lw	a3,0(a4)
		b->next = cur->next;
ffffffffc0201d42:	e41c                	sd	a5,8(s0)
	if (cur + cur->units == b)
ffffffffc0201d44:	00469793          	slli	a5,a3,0x4
ffffffffc0201d48:	97ba                	add	a5,a5,a4
ffffffffc0201d4a:	02f40e63          	beq	s0,a5,ffffffffc0201d86 <slob_free+0x82>
	{
		cur->units += b->units;
		cur->next = b->next;
	}
	else
		cur->next = b;
ffffffffc0201d4e:	e700                	sd	s0,8(a4)

	slobfree = cur;
ffffffffc0201d50:	e218                	sd	a4,0(a2)
    if (flag)
ffffffffc0201d52:	e129                	bnez	a0,ffffffffc0201d94 <slob_free+0x90>

	spin_unlock_irqrestore(&slob_lock, flags);
}
ffffffffc0201d54:	60a2                	ld	ra,8(sp)
ffffffffc0201d56:	6402                	ld	s0,0(sp)
ffffffffc0201d58:	0141                	addi	sp,sp,16
ffffffffc0201d5a:	8082                	ret
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201d5c:	fcf764e3          	bltu	a4,a5,ffffffffc0201d24 <slob_free+0x20>
ffffffffc0201d60:	fcf472e3          	bgeu	s0,a5,ffffffffc0201d24 <slob_free+0x20>
	if (b + b->units == cur->next)
ffffffffc0201d64:	400c                	lw	a1,0(s0)
ffffffffc0201d66:	00459693          	slli	a3,a1,0x4
ffffffffc0201d6a:	96a2                	add	a3,a3,s0
ffffffffc0201d6c:	fcd79ae3          	bne	a5,a3,ffffffffc0201d40 <slob_free+0x3c>
		b->units += cur->next->units;
ffffffffc0201d70:	4394                	lw	a3,0(a5)
		b->next = cur->next->next;
ffffffffc0201d72:	679c                	ld	a5,8(a5)
		b->units += cur->next->units;
ffffffffc0201d74:	9db5                	addw	a1,a1,a3
ffffffffc0201d76:	c00c                	sw	a1,0(s0)
	if (cur + cur->units == b)
ffffffffc0201d78:	4314                	lw	a3,0(a4)
		b->next = cur->next->next;
ffffffffc0201d7a:	e41c                	sd	a5,8(s0)
	if (cur + cur->units == b)
ffffffffc0201d7c:	00469793          	slli	a5,a3,0x4
ffffffffc0201d80:	97ba                	add	a5,a5,a4
ffffffffc0201d82:	fcf416e3          	bne	s0,a5,ffffffffc0201d4e <slob_free+0x4a>
		cur->units += b->units;
ffffffffc0201d86:	401c                	lw	a5,0(s0)
		cur->next = b->next;
ffffffffc0201d88:	640c                	ld	a1,8(s0)
	slobfree = cur;
ffffffffc0201d8a:	e218                	sd	a4,0(a2)
		cur->units += b->units;
ffffffffc0201d8c:	9ebd                	addw	a3,a3,a5
ffffffffc0201d8e:	c314                	sw	a3,0(a4)
		cur->next = b->next;
ffffffffc0201d90:	e70c                	sd	a1,8(a4)
ffffffffc0201d92:	d169                	beqz	a0,ffffffffc0201d54 <slob_free+0x50>
}
ffffffffc0201d94:	6402                	ld	s0,0(sp)
ffffffffc0201d96:	60a2                	ld	ra,8(sp)
ffffffffc0201d98:	0141                	addi	sp,sp,16
        intr_enable();
ffffffffc0201d9a:	c15fe06f          	j	ffffffffc02009ae <intr_enable>
		b->units = SLOB_UNITS(size);
ffffffffc0201d9e:	25bd                	addiw	a1,a1,15
ffffffffc0201da0:	8191                	srli	a1,a1,0x4
ffffffffc0201da2:	c10c                	sw	a1,0(a0)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201da4:	100027f3          	csrr	a5,sstatus
ffffffffc0201da8:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0201daa:	4501                	li	a0,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201dac:	d7bd                	beqz	a5,ffffffffc0201d1a <slob_free+0x16>
        intr_disable();
ffffffffc0201dae:	c07fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc0201db2:	4505                	li	a0,1
ffffffffc0201db4:	b79d                	j	ffffffffc0201d1a <slob_free+0x16>
ffffffffc0201db6:	8082                	ret

ffffffffc0201db8 <__slob_get_free_pages.constprop.0>:
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201db8:	4785                	li	a5,1
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0201dba:	1141                	addi	sp,sp,-16
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201dbc:	00a7953b          	sllw	a0,a5,a0
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0201dc0:	e406                	sd	ra,8(sp)
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201dc2:	352000ef          	jal	ra,ffffffffc0202114 <alloc_pages>
	if (!page)
ffffffffc0201dc6:	c91d                	beqz	a0,ffffffffc0201dfc <__slob_get_free_pages.constprop.0+0x44>
    return page - pages + nbase;
ffffffffc0201dc8:	000be697          	auipc	a3,0xbe
ffffffffc0201dcc:	e206b683          	ld	a3,-480(a3) # ffffffffc02bfbe8 <pages>
ffffffffc0201dd0:	8d15                	sub	a0,a0,a3
ffffffffc0201dd2:	8519                	srai	a0,a0,0x6
ffffffffc0201dd4:	00006697          	auipc	a3,0x6
ffffffffc0201dd8:	c0c6b683          	ld	a3,-1012(a3) # ffffffffc02079e0 <nbase>
ffffffffc0201ddc:	9536                	add	a0,a0,a3
    return KADDR(page2pa(page));
ffffffffc0201dde:	00c51793          	slli	a5,a0,0xc
ffffffffc0201de2:	83b1                	srli	a5,a5,0xc
ffffffffc0201de4:	000be717          	auipc	a4,0xbe
ffffffffc0201de8:	dfc73703          	ld	a4,-516(a4) # ffffffffc02bfbe0 <npage>
    return page2ppn(page) << PGSHIFT;
ffffffffc0201dec:	0532                	slli	a0,a0,0xc
    return KADDR(page2pa(page));
ffffffffc0201dee:	00e7fa63          	bgeu	a5,a4,ffffffffc0201e02 <__slob_get_free_pages.constprop.0+0x4a>
ffffffffc0201df2:	000be697          	auipc	a3,0xbe
ffffffffc0201df6:	e066b683          	ld	a3,-506(a3) # ffffffffc02bfbf8 <va_pa_offset>
ffffffffc0201dfa:	9536                	add	a0,a0,a3
}
ffffffffc0201dfc:	60a2                	ld	ra,8(sp)
ffffffffc0201dfe:	0141                	addi	sp,sp,16
ffffffffc0201e00:	8082                	ret
ffffffffc0201e02:	86aa                	mv	a3,a0
ffffffffc0201e04:	00004617          	auipc	a2,0x4
ffffffffc0201e08:	2b460613          	addi	a2,a2,692 # ffffffffc02060b8 <commands+0x5e8>
ffffffffc0201e0c:	07100593          	li	a1,113
ffffffffc0201e10:	00004517          	auipc	a0,0x4
ffffffffc0201e14:	29850513          	addi	a0,a0,664 # ffffffffc02060a8 <commands+0x5d8>
ffffffffc0201e18:	e76fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201e1c <slob_alloc.constprop.0>:
static void *slob_alloc(size_t size, gfp_t gfp, int align)
ffffffffc0201e1c:	1101                	addi	sp,sp,-32
ffffffffc0201e1e:	ec06                	sd	ra,24(sp)
ffffffffc0201e20:	e822                	sd	s0,16(sp)
ffffffffc0201e22:	e426                	sd	s1,8(sp)
ffffffffc0201e24:	e04a                	sd	s2,0(sp)
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc0201e26:	01050713          	addi	a4,a0,16
ffffffffc0201e2a:	6785                	lui	a5,0x1
ffffffffc0201e2c:	0cf77363          	bgeu	a4,a5,ffffffffc0201ef2 <slob_alloc.constprop.0+0xd6>
	int delta = 0, units = SLOB_UNITS(size);
ffffffffc0201e30:	00f50493          	addi	s1,a0,15
ffffffffc0201e34:	8091                	srli	s1,s1,0x4
ffffffffc0201e36:	2481                	sext.w	s1,s1
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201e38:	10002673          	csrr	a2,sstatus
ffffffffc0201e3c:	8a09                	andi	a2,a2,2
ffffffffc0201e3e:	e25d                	bnez	a2,ffffffffc0201ee4 <slob_alloc.constprop.0+0xc8>
	prev = slobfree;
ffffffffc0201e40:	000ba917          	auipc	s2,0xba
ffffffffc0201e44:	92890913          	addi	s2,s2,-1752 # ffffffffc02bb768 <slobfree>
ffffffffc0201e48:	00093683          	ld	a3,0(s2)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201e4c:	669c                	ld	a5,8(a3)
		if (cur->units >= units + delta)
ffffffffc0201e4e:	4398                	lw	a4,0(a5)
ffffffffc0201e50:	08975e63          	bge	a4,s1,ffffffffc0201eec <slob_alloc.constprop.0+0xd0>
		if (cur == slobfree)
ffffffffc0201e54:	00f68b63          	beq	a3,a5,ffffffffc0201e6a <slob_alloc.constprop.0+0x4e>
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201e58:	6780                	ld	s0,8(a5)
		if (cur->units >= units + delta)
ffffffffc0201e5a:	4018                	lw	a4,0(s0)
ffffffffc0201e5c:	02975a63          	bge	a4,s1,ffffffffc0201e90 <slob_alloc.constprop.0+0x74>
		if (cur == slobfree)
ffffffffc0201e60:	00093683          	ld	a3,0(s2)
ffffffffc0201e64:	87a2                	mv	a5,s0
ffffffffc0201e66:	fef699e3          	bne	a3,a5,ffffffffc0201e58 <slob_alloc.constprop.0+0x3c>
    if (flag)
ffffffffc0201e6a:	ee31                	bnez	a2,ffffffffc0201ec6 <slob_alloc.constprop.0+0xaa>
			cur = (slob_t *)__slob_get_free_page(gfp);
ffffffffc0201e6c:	4501                	li	a0,0
ffffffffc0201e6e:	f4bff0ef          	jal	ra,ffffffffc0201db8 <__slob_get_free_pages.constprop.0>
ffffffffc0201e72:	842a                	mv	s0,a0
			if (!cur)
ffffffffc0201e74:	cd05                	beqz	a0,ffffffffc0201eac <slob_alloc.constprop.0+0x90>
			slob_free(cur, PAGE_SIZE);
ffffffffc0201e76:	6585                	lui	a1,0x1
ffffffffc0201e78:	e8dff0ef          	jal	ra,ffffffffc0201d04 <slob_free>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201e7c:	10002673          	csrr	a2,sstatus
ffffffffc0201e80:	8a09                	andi	a2,a2,2
ffffffffc0201e82:	ee05                	bnez	a2,ffffffffc0201eba <slob_alloc.constprop.0+0x9e>
			cur = slobfree;
ffffffffc0201e84:	00093783          	ld	a5,0(s2)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201e88:	6780                	ld	s0,8(a5)
		if (cur->units >= units + delta)
ffffffffc0201e8a:	4018                	lw	a4,0(s0)
ffffffffc0201e8c:	fc974ae3          	blt	a4,s1,ffffffffc0201e60 <slob_alloc.constprop.0+0x44>
			if (cur->units == units)	/* exact fit? */
ffffffffc0201e90:	04e48763          	beq	s1,a4,ffffffffc0201ede <slob_alloc.constprop.0+0xc2>
				prev->next = cur + units;
ffffffffc0201e94:	00449693          	slli	a3,s1,0x4
ffffffffc0201e98:	96a2                	add	a3,a3,s0
ffffffffc0201e9a:	e794                	sd	a3,8(a5)
				prev->next->next = cur->next;
ffffffffc0201e9c:	640c                	ld	a1,8(s0)
				prev->next->units = cur->units - units;
ffffffffc0201e9e:	9f05                	subw	a4,a4,s1
ffffffffc0201ea0:	c298                	sw	a4,0(a3)
				prev->next->next = cur->next;
ffffffffc0201ea2:	e68c                	sd	a1,8(a3)
				cur->units = units;
ffffffffc0201ea4:	c004                	sw	s1,0(s0)
			slobfree = prev;
ffffffffc0201ea6:	00f93023          	sd	a5,0(s2)
    if (flag)
ffffffffc0201eaa:	e20d                	bnez	a2,ffffffffc0201ecc <slob_alloc.constprop.0+0xb0>
}
ffffffffc0201eac:	60e2                	ld	ra,24(sp)
ffffffffc0201eae:	8522                	mv	a0,s0
ffffffffc0201eb0:	6442                	ld	s0,16(sp)
ffffffffc0201eb2:	64a2                	ld	s1,8(sp)
ffffffffc0201eb4:	6902                	ld	s2,0(sp)
ffffffffc0201eb6:	6105                	addi	sp,sp,32
ffffffffc0201eb8:	8082                	ret
        intr_disable();
ffffffffc0201eba:	afbfe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
			cur = slobfree;
ffffffffc0201ebe:	00093783          	ld	a5,0(s2)
        return 1;
ffffffffc0201ec2:	4605                	li	a2,1
ffffffffc0201ec4:	b7d1                	j	ffffffffc0201e88 <slob_alloc.constprop.0+0x6c>
        intr_enable();
ffffffffc0201ec6:	ae9fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0201eca:	b74d                	j	ffffffffc0201e6c <slob_alloc.constprop.0+0x50>
ffffffffc0201ecc:	ae3fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
}
ffffffffc0201ed0:	60e2                	ld	ra,24(sp)
ffffffffc0201ed2:	8522                	mv	a0,s0
ffffffffc0201ed4:	6442                	ld	s0,16(sp)
ffffffffc0201ed6:	64a2                	ld	s1,8(sp)
ffffffffc0201ed8:	6902                	ld	s2,0(sp)
ffffffffc0201eda:	6105                	addi	sp,sp,32
ffffffffc0201edc:	8082                	ret
				prev->next = cur->next; /* unlink */
ffffffffc0201ede:	6418                	ld	a4,8(s0)
ffffffffc0201ee0:	e798                	sd	a4,8(a5)
ffffffffc0201ee2:	b7d1                	j	ffffffffc0201ea6 <slob_alloc.constprop.0+0x8a>
        intr_disable();
ffffffffc0201ee4:	ad1fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc0201ee8:	4605                	li	a2,1
ffffffffc0201eea:	bf99                	j	ffffffffc0201e40 <slob_alloc.constprop.0+0x24>
		if (cur->units >= units + delta)
ffffffffc0201eec:	843e                	mv	s0,a5
ffffffffc0201eee:	87b6                	mv	a5,a3
ffffffffc0201ef0:	b745                	j	ffffffffc0201e90 <slob_alloc.constprop.0+0x74>
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc0201ef2:	00005697          	auipc	a3,0x5
ffffffffc0201ef6:	8a668693          	addi	a3,a3,-1882 # ffffffffc0206798 <default_pmm_manager+0x38>
ffffffffc0201efa:	00004617          	auipc	a2,0x4
ffffffffc0201efe:	4b660613          	addi	a2,a2,1206 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc0201f02:	06300593          	li	a1,99
ffffffffc0201f06:	00005517          	auipc	a0,0x5
ffffffffc0201f0a:	8b250513          	addi	a0,a0,-1870 # ffffffffc02067b8 <default_pmm_manager+0x58>
ffffffffc0201f0e:	d80fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201f12 <kmalloc_init>:
	cprintf("use SLOB allocator\n");
}

inline void
kmalloc_init(void)
{
ffffffffc0201f12:	1141                	addi	sp,sp,-16
	cprintf("use SLOB allocator\n");
ffffffffc0201f14:	00005517          	auipc	a0,0x5
ffffffffc0201f18:	8bc50513          	addi	a0,a0,-1860 # ffffffffc02067d0 <default_pmm_manager+0x70>
{
ffffffffc0201f1c:	e406                	sd	ra,8(sp)
	cprintf("use SLOB allocator\n");
ffffffffc0201f1e:	a76fe0ef          	jal	ra,ffffffffc0200194 <cprintf>
	slob_init();
	cprintf("kmalloc_init() succeeded!\n");
}
ffffffffc0201f22:	60a2                	ld	ra,8(sp)
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201f24:	00005517          	auipc	a0,0x5
ffffffffc0201f28:	8c450513          	addi	a0,a0,-1852 # ffffffffc02067e8 <default_pmm_manager+0x88>
}
ffffffffc0201f2c:	0141                	addi	sp,sp,16
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201f2e:	a66fe06f          	j	ffffffffc0200194 <cprintf>

ffffffffc0201f32 <kallocated>:

size_t
kallocated(void)
{
	return slob_allocated();
}
ffffffffc0201f32:	4501                	li	a0,0
ffffffffc0201f34:	8082                	ret

ffffffffc0201f36 <kmalloc>:
	return 0;
}

void *
kmalloc(size_t size)
{
ffffffffc0201f36:	1101                	addi	sp,sp,-32
ffffffffc0201f38:	e04a                	sd	s2,0(sp)
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201f3a:	6905                	lui	s2,0x1
{
ffffffffc0201f3c:	e822                	sd	s0,16(sp)
ffffffffc0201f3e:	ec06                	sd	ra,24(sp)
ffffffffc0201f40:	e426                	sd	s1,8(sp)
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201f42:	fef90793          	addi	a5,s2,-17 # fef <_binary_obj___user_faultread_out_size-0x8be1>
{
ffffffffc0201f46:	842a                	mv	s0,a0
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201f48:	04a7f963          	bgeu	a5,a0,ffffffffc0201f9a <kmalloc+0x64>
	bb = slob_alloc(sizeof(bigblock_t), gfp, 0);
ffffffffc0201f4c:	4561                	li	a0,24
ffffffffc0201f4e:	ecfff0ef          	jal	ra,ffffffffc0201e1c <slob_alloc.constprop.0>
ffffffffc0201f52:	84aa                	mv	s1,a0
	if (!bb)
ffffffffc0201f54:	c929                	beqz	a0,ffffffffc0201fa6 <kmalloc+0x70>
	bb->order = find_order(size);
ffffffffc0201f56:	0004079b          	sext.w	a5,s0
	int order = 0;
ffffffffc0201f5a:	4501                	li	a0,0
	for (; size > 4096; size >>= 1)
ffffffffc0201f5c:	00f95763          	bge	s2,a5,ffffffffc0201f6a <kmalloc+0x34>
ffffffffc0201f60:	6705                	lui	a4,0x1
ffffffffc0201f62:	8785                	srai	a5,a5,0x1
		order++;
ffffffffc0201f64:	2505                	addiw	a0,a0,1
	for (; size > 4096; size >>= 1)
ffffffffc0201f66:	fef74ee3          	blt	a4,a5,ffffffffc0201f62 <kmalloc+0x2c>
	bb->order = find_order(size);
ffffffffc0201f6a:	c088                	sw	a0,0(s1)
	bb->pages = (void *)__slob_get_free_pages(gfp, bb->order);
ffffffffc0201f6c:	e4dff0ef          	jal	ra,ffffffffc0201db8 <__slob_get_free_pages.constprop.0>
ffffffffc0201f70:	e488                	sd	a0,8(s1)
ffffffffc0201f72:	842a                	mv	s0,a0
	if (bb->pages)
ffffffffc0201f74:	c525                	beqz	a0,ffffffffc0201fdc <kmalloc+0xa6>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201f76:	100027f3          	csrr	a5,sstatus
ffffffffc0201f7a:	8b89                	andi	a5,a5,2
ffffffffc0201f7c:	ef8d                	bnez	a5,ffffffffc0201fb6 <kmalloc+0x80>
		bb->next = bigblocks;
ffffffffc0201f7e:	000be797          	auipc	a5,0xbe
ffffffffc0201f82:	c4a78793          	addi	a5,a5,-950 # ffffffffc02bfbc8 <bigblocks>
ffffffffc0201f86:	6398                	ld	a4,0(a5)
		bigblocks = bb;
ffffffffc0201f88:	e384                	sd	s1,0(a5)
		bb->next = bigblocks;
ffffffffc0201f8a:	e898                	sd	a4,16(s1)
	return __kmalloc(size, 0);
}
ffffffffc0201f8c:	60e2                	ld	ra,24(sp)
ffffffffc0201f8e:	8522                	mv	a0,s0
ffffffffc0201f90:	6442                	ld	s0,16(sp)
ffffffffc0201f92:	64a2                	ld	s1,8(sp)
ffffffffc0201f94:	6902                	ld	s2,0(sp)
ffffffffc0201f96:	6105                	addi	sp,sp,32
ffffffffc0201f98:	8082                	ret
		m = slob_alloc(size + SLOB_UNIT, gfp, 0);
ffffffffc0201f9a:	0541                	addi	a0,a0,16
ffffffffc0201f9c:	e81ff0ef          	jal	ra,ffffffffc0201e1c <slob_alloc.constprop.0>
		return m ? (void *)(m + 1) : 0;
ffffffffc0201fa0:	01050413          	addi	s0,a0,16
ffffffffc0201fa4:	f565                	bnez	a0,ffffffffc0201f8c <kmalloc+0x56>
ffffffffc0201fa6:	4401                	li	s0,0
}
ffffffffc0201fa8:	60e2                	ld	ra,24(sp)
ffffffffc0201faa:	8522                	mv	a0,s0
ffffffffc0201fac:	6442                	ld	s0,16(sp)
ffffffffc0201fae:	64a2                	ld	s1,8(sp)
ffffffffc0201fb0:	6902                	ld	s2,0(sp)
ffffffffc0201fb2:	6105                	addi	sp,sp,32
ffffffffc0201fb4:	8082                	ret
        intr_disable();
ffffffffc0201fb6:	9fffe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
		bb->next = bigblocks;
ffffffffc0201fba:	000be797          	auipc	a5,0xbe
ffffffffc0201fbe:	c0e78793          	addi	a5,a5,-1010 # ffffffffc02bfbc8 <bigblocks>
ffffffffc0201fc2:	6398                	ld	a4,0(a5)
		bigblocks = bb;
ffffffffc0201fc4:	e384                	sd	s1,0(a5)
		bb->next = bigblocks;
ffffffffc0201fc6:	e898                	sd	a4,16(s1)
        intr_enable();
ffffffffc0201fc8:	9e7fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
		return bb->pages;
ffffffffc0201fcc:	6480                	ld	s0,8(s1)
}
ffffffffc0201fce:	60e2                	ld	ra,24(sp)
ffffffffc0201fd0:	64a2                	ld	s1,8(sp)
ffffffffc0201fd2:	8522                	mv	a0,s0
ffffffffc0201fd4:	6442                	ld	s0,16(sp)
ffffffffc0201fd6:	6902                	ld	s2,0(sp)
ffffffffc0201fd8:	6105                	addi	sp,sp,32
ffffffffc0201fda:	8082                	ret
	slob_free(bb, sizeof(bigblock_t));
ffffffffc0201fdc:	45e1                	li	a1,24
ffffffffc0201fde:	8526                	mv	a0,s1
ffffffffc0201fe0:	d25ff0ef          	jal	ra,ffffffffc0201d04 <slob_free>
	return __kmalloc(size, 0);
ffffffffc0201fe4:	b765                	j	ffffffffc0201f8c <kmalloc+0x56>

ffffffffc0201fe6 <kfree>:
void kfree(void *block)
{
	bigblock_t *bb, **last = &bigblocks;
	unsigned long flags;

	if (!block)
ffffffffc0201fe6:	c169                	beqz	a0,ffffffffc02020a8 <kfree+0xc2>
{
ffffffffc0201fe8:	1101                	addi	sp,sp,-32
ffffffffc0201fea:	e822                	sd	s0,16(sp)
ffffffffc0201fec:	ec06                	sd	ra,24(sp)
ffffffffc0201fee:	e426                	sd	s1,8(sp)
		return;

	if (!((unsigned long)block & (PAGE_SIZE - 1)))
ffffffffc0201ff0:	03451793          	slli	a5,a0,0x34
ffffffffc0201ff4:	842a                	mv	s0,a0
ffffffffc0201ff6:	e3d9                	bnez	a5,ffffffffc020207c <kfree+0x96>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201ff8:	100027f3          	csrr	a5,sstatus
ffffffffc0201ffc:	8b89                	andi	a5,a5,2
ffffffffc0201ffe:	e7d9                	bnez	a5,ffffffffc020208c <kfree+0xa6>
	{
		/* might be on the big block list */
		spin_lock_irqsave(&block_lock, flags);
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0202000:	000be797          	auipc	a5,0xbe
ffffffffc0202004:	bc87b783          	ld	a5,-1080(a5) # ffffffffc02bfbc8 <bigblocks>
    return 0;
ffffffffc0202008:	4601                	li	a2,0
ffffffffc020200a:	cbad                	beqz	a5,ffffffffc020207c <kfree+0x96>
	bigblock_t *bb, **last = &bigblocks;
ffffffffc020200c:	000be697          	auipc	a3,0xbe
ffffffffc0202010:	bbc68693          	addi	a3,a3,-1092 # ffffffffc02bfbc8 <bigblocks>
ffffffffc0202014:	a021                	j	ffffffffc020201c <kfree+0x36>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0202016:	01048693          	addi	a3,s1,16
ffffffffc020201a:	c3a5                	beqz	a5,ffffffffc020207a <kfree+0x94>
		{
			if (bb->pages == block)
ffffffffc020201c:	6798                	ld	a4,8(a5)
ffffffffc020201e:	84be                	mv	s1,a5
			{
				*last = bb->next;
ffffffffc0202020:	6b9c                	ld	a5,16(a5)
			if (bb->pages == block)
ffffffffc0202022:	fe871ae3          	bne	a4,s0,ffffffffc0202016 <kfree+0x30>
				*last = bb->next;
ffffffffc0202026:	e29c                	sd	a5,0(a3)
    if (flag)
ffffffffc0202028:	ee2d                	bnez	a2,ffffffffc02020a2 <kfree+0xbc>
    return pa2page(PADDR(kva));
ffffffffc020202a:	c02007b7          	lui	a5,0xc0200
				spin_unlock_irqrestore(&block_lock, flags);
				__slob_free_pages((unsigned long)block, bb->order);
ffffffffc020202e:	4098                	lw	a4,0(s1)
ffffffffc0202030:	08f46963          	bltu	s0,a5,ffffffffc02020c2 <kfree+0xdc>
ffffffffc0202034:	000be697          	auipc	a3,0xbe
ffffffffc0202038:	bc46b683          	ld	a3,-1084(a3) # ffffffffc02bfbf8 <va_pa_offset>
ffffffffc020203c:	8c15                	sub	s0,s0,a3
    if (PPN(pa) >= npage)
ffffffffc020203e:	8031                	srli	s0,s0,0xc
ffffffffc0202040:	000be797          	auipc	a5,0xbe
ffffffffc0202044:	ba07b783          	ld	a5,-1120(a5) # ffffffffc02bfbe0 <npage>
ffffffffc0202048:	06f47163          	bgeu	s0,a5,ffffffffc02020aa <kfree+0xc4>
    return &pages[PPN(pa) - nbase];
ffffffffc020204c:	00006517          	auipc	a0,0x6
ffffffffc0202050:	99453503          	ld	a0,-1644(a0) # ffffffffc02079e0 <nbase>
ffffffffc0202054:	8c09                	sub	s0,s0,a0
ffffffffc0202056:	041a                	slli	s0,s0,0x6
	free_pages(kva2page(kva), 1 << order);
ffffffffc0202058:	000be517          	auipc	a0,0xbe
ffffffffc020205c:	b9053503          	ld	a0,-1136(a0) # ffffffffc02bfbe8 <pages>
ffffffffc0202060:	4585                	li	a1,1
ffffffffc0202062:	9522                	add	a0,a0,s0
ffffffffc0202064:	00e595bb          	sllw	a1,a1,a4
ffffffffc0202068:	0ea000ef          	jal	ra,ffffffffc0202152 <free_pages>
		spin_unlock_irqrestore(&block_lock, flags);
	}

	slob_free((slob_t *)block - 1, 0);
	return;
}
ffffffffc020206c:	6442                	ld	s0,16(sp)
ffffffffc020206e:	60e2                	ld	ra,24(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0202070:	8526                	mv	a0,s1
}
ffffffffc0202072:	64a2                	ld	s1,8(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0202074:	45e1                	li	a1,24
}
ffffffffc0202076:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0202078:	b171                	j	ffffffffc0201d04 <slob_free>
ffffffffc020207a:	e20d                	bnez	a2,ffffffffc020209c <kfree+0xb6>
ffffffffc020207c:	ff040513          	addi	a0,s0,-16
}
ffffffffc0202080:	6442                	ld	s0,16(sp)
ffffffffc0202082:	60e2                	ld	ra,24(sp)
ffffffffc0202084:	64a2                	ld	s1,8(sp)
	slob_free((slob_t *)block - 1, 0);
ffffffffc0202086:	4581                	li	a1,0
}
ffffffffc0202088:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc020208a:	b9ad                	j	ffffffffc0201d04 <slob_free>
        intr_disable();
ffffffffc020208c:	929fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0202090:	000be797          	auipc	a5,0xbe
ffffffffc0202094:	b387b783          	ld	a5,-1224(a5) # ffffffffc02bfbc8 <bigblocks>
        return 1;
ffffffffc0202098:	4605                	li	a2,1
ffffffffc020209a:	fbad                	bnez	a5,ffffffffc020200c <kfree+0x26>
        intr_enable();
ffffffffc020209c:	913fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02020a0:	bff1                	j	ffffffffc020207c <kfree+0x96>
ffffffffc02020a2:	90dfe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02020a6:	b751                	j	ffffffffc020202a <kfree+0x44>
ffffffffc02020a8:	8082                	ret
        panic("pa2page called with invalid pa");
ffffffffc02020aa:	00004617          	auipc	a2,0x4
ffffffffc02020ae:	fde60613          	addi	a2,a2,-34 # ffffffffc0206088 <commands+0x5b8>
ffffffffc02020b2:	06900593          	li	a1,105
ffffffffc02020b6:	00004517          	auipc	a0,0x4
ffffffffc02020ba:	ff250513          	addi	a0,a0,-14 # ffffffffc02060a8 <commands+0x5d8>
ffffffffc02020be:	bd0fe0ef          	jal	ra,ffffffffc020048e <__panic>
    return pa2page(PADDR(kva));
ffffffffc02020c2:	86a2                	mv	a3,s0
ffffffffc02020c4:	00004617          	auipc	a2,0x4
ffffffffc02020c8:	74460613          	addi	a2,a2,1860 # ffffffffc0206808 <default_pmm_manager+0xa8>
ffffffffc02020cc:	07700593          	li	a1,119
ffffffffc02020d0:	00004517          	auipc	a0,0x4
ffffffffc02020d4:	fd850513          	addi	a0,a0,-40 # ffffffffc02060a8 <commands+0x5d8>
ffffffffc02020d8:	bb6fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02020dc <pa2page.part.0>:
pa2page(uintptr_t pa)
ffffffffc02020dc:	1141                	addi	sp,sp,-16
        panic("pa2page called with invalid pa");
ffffffffc02020de:	00004617          	auipc	a2,0x4
ffffffffc02020e2:	faa60613          	addi	a2,a2,-86 # ffffffffc0206088 <commands+0x5b8>
ffffffffc02020e6:	06900593          	li	a1,105
ffffffffc02020ea:	00004517          	auipc	a0,0x4
ffffffffc02020ee:	fbe50513          	addi	a0,a0,-66 # ffffffffc02060a8 <commands+0x5d8>
pa2page(uintptr_t pa)
ffffffffc02020f2:	e406                	sd	ra,8(sp)
        panic("pa2page called with invalid pa");
ffffffffc02020f4:	b9afe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02020f8 <pte2page.part.0>:
pte2page(pte_t pte)
ffffffffc02020f8:	1141                	addi	sp,sp,-16
        panic("pte2page called with invalid pte");
ffffffffc02020fa:	00004617          	auipc	a2,0x4
ffffffffc02020fe:	73660613          	addi	a2,a2,1846 # ffffffffc0206830 <default_pmm_manager+0xd0>
ffffffffc0202102:	07f00593          	li	a1,127
ffffffffc0202106:	00004517          	auipc	a0,0x4
ffffffffc020210a:	fa250513          	addi	a0,a0,-94 # ffffffffc02060a8 <commands+0x5d8>
pte2page(pte_t pte)
ffffffffc020210e:	e406                	sd	ra,8(sp)
        panic("pte2page called with invalid pte");
ffffffffc0202110:	b7efe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0202114 <alloc_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0202114:	100027f3          	csrr	a5,sstatus
ffffffffc0202118:	8b89                	andi	a5,a5,2
ffffffffc020211a:	e799                	bnez	a5,ffffffffc0202128 <alloc_pages+0x14>
{
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc020211c:	000be797          	auipc	a5,0xbe
ffffffffc0202120:	ad47b783          	ld	a5,-1324(a5) # ffffffffc02bfbf0 <pmm_manager>
ffffffffc0202124:	6f9c                	ld	a5,24(a5)
ffffffffc0202126:	8782                	jr	a5
{
ffffffffc0202128:	1141                	addi	sp,sp,-16
ffffffffc020212a:	e406                	sd	ra,8(sp)
ffffffffc020212c:	e022                	sd	s0,0(sp)
ffffffffc020212e:	842a                	mv	s0,a0
        intr_disable();
ffffffffc0202130:	885fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202134:	000be797          	auipc	a5,0xbe
ffffffffc0202138:	abc7b783          	ld	a5,-1348(a5) # ffffffffc02bfbf0 <pmm_manager>
ffffffffc020213c:	6f9c                	ld	a5,24(a5)
ffffffffc020213e:	8522                	mv	a0,s0
ffffffffc0202140:	9782                	jalr	a5
ffffffffc0202142:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202144:	86bfe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc0202148:	60a2                	ld	ra,8(sp)
ffffffffc020214a:	8522                	mv	a0,s0
ffffffffc020214c:	6402                	ld	s0,0(sp)
ffffffffc020214e:	0141                	addi	sp,sp,16
ffffffffc0202150:	8082                	ret

ffffffffc0202152 <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0202152:	100027f3          	csrr	a5,sstatus
ffffffffc0202156:	8b89                	andi	a5,a5,2
ffffffffc0202158:	e799                	bnez	a5,ffffffffc0202166 <free_pages+0x14>
void free_pages(struct Page *base, size_t n)
{
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc020215a:	000be797          	auipc	a5,0xbe
ffffffffc020215e:	a967b783          	ld	a5,-1386(a5) # ffffffffc02bfbf0 <pmm_manager>
ffffffffc0202162:	739c                	ld	a5,32(a5)
ffffffffc0202164:	8782                	jr	a5
{
ffffffffc0202166:	1101                	addi	sp,sp,-32
ffffffffc0202168:	ec06                	sd	ra,24(sp)
ffffffffc020216a:	e822                	sd	s0,16(sp)
ffffffffc020216c:	e426                	sd	s1,8(sp)
ffffffffc020216e:	842a                	mv	s0,a0
ffffffffc0202170:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc0202172:	843fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202176:	000be797          	auipc	a5,0xbe
ffffffffc020217a:	a7a7b783          	ld	a5,-1414(a5) # ffffffffc02bfbf0 <pmm_manager>
ffffffffc020217e:	739c                	ld	a5,32(a5)
ffffffffc0202180:	85a6                	mv	a1,s1
ffffffffc0202182:	8522                	mv	a0,s0
ffffffffc0202184:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc0202186:	6442                	ld	s0,16(sp)
ffffffffc0202188:	60e2                	ld	ra,24(sp)
ffffffffc020218a:	64a2                	ld	s1,8(sp)
ffffffffc020218c:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc020218e:	821fe06f          	j	ffffffffc02009ae <intr_enable>

ffffffffc0202192 <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0202192:	100027f3          	csrr	a5,sstatus
ffffffffc0202196:	8b89                	andi	a5,a5,2
ffffffffc0202198:	e799                	bnez	a5,ffffffffc02021a6 <nr_free_pages+0x14>
{
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc020219a:	000be797          	auipc	a5,0xbe
ffffffffc020219e:	a567b783          	ld	a5,-1450(a5) # ffffffffc02bfbf0 <pmm_manager>
ffffffffc02021a2:	779c                	ld	a5,40(a5)
ffffffffc02021a4:	8782                	jr	a5
{
ffffffffc02021a6:	1141                	addi	sp,sp,-16
ffffffffc02021a8:	e406                	sd	ra,8(sp)
ffffffffc02021aa:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc02021ac:	809fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc02021b0:	000be797          	auipc	a5,0xbe
ffffffffc02021b4:	a407b783          	ld	a5,-1472(a5) # ffffffffc02bfbf0 <pmm_manager>
ffffffffc02021b8:	779c                	ld	a5,40(a5)
ffffffffc02021ba:	9782                	jalr	a5
ffffffffc02021bc:	842a                	mv	s0,a0
        intr_enable();
ffffffffc02021be:	ff0fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc02021c2:	60a2                	ld	ra,8(sp)
ffffffffc02021c4:	8522                	mv	a0,s0
ffffffffc02021c6:	6402                	ld	s0,0(sp)
ffffffffc02021c8:	0141                	addi	sp,sp,16
ffffffffc02021ca:	8082                	ret

ffffffffc02021cc <get_pte>:
//  la:     the linear address need to map
//  create: a logical value to decide if alloc a page for PT
// return vaule: the kernel virtual address of this pte
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create)
{
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc02021cc:	01e5d793          	srli	a5,a1,0x1e
ffffffffc02021d0:	1ff7f793          	andi	a5,a5,511
{
ffffffffc02021d4:	7139                	addi	sp,sp,-64
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc02021d6:	078e                	slli	a5,a5,0x3
{
ffffffffc02021d8:	f426                	sd	s1,40(sp)
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc02021da:	00f504b3          	add	s1,a0,a5
    if (!(*pdep1 & PTE_V))
ffffffffc02021de:	6094                	ld	a3,0(s1)
{
ffffffffc02021e0:	f04a                	sd	s2,32(sp)
ffffffffc02021e2:	ec4e                	sd	s3,24(sp)
ffffffffc02021e4:	e852                	sd	s4,16(sp)
ffffffffc02021e6:	fc06                	sd	ra,56(sp)
ffffffffc02021e8:	f822                	sd	s0,48(sp)
ffffffffc02021ea:	e456                	sd	s5,8(sp)
ffffffffc02021ec:	e05a                	sd	s6,0(sp)
    if (!(*pdep1 & PTE_V))
ffffffffc02021ee:	0016f793          	andi	a5,a3,1
{
ffffffffc02021f2:	892e                	mv	s2,a1
ffffffffc02021f4:	8a32                	mv	s4,a2
ffffffffc02021f6:	000be997          	auipc	s3,0xbe
ffffffffc02021fa:	9ea98993          	addi	s3,s3,-1558 # ffffffffc02bfbe0 <npage>
    if (!(*pdep1 & PTE_V))
ffffffffc02021fe:	efbd                	bnez	a5,ffffffffc020227c <get_pte+0xb0>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0202200:	14060c63          	beqz	a2,ffffffffc0202358 <get_pte+0x18c>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0202204:	100027f3          	csrr	a5,sstatus
ffffffffc0202208:	8b89                	andi	a5,a5,2
ffffffffc020220a:	14079963          	bnez	a5,ffffffffc020235c <get_pte+0x190>
        page = pmm_manager->alloc_pages(n);
ffffffffc020220e:	000be797          	auipc	a5,0xbe
ffffffffc0202212:	9e27b783          	ld	a5,-1566(a5) # ffffffffc02bfbf0 <pmm_manager>
ffffffffc0202216:	6f9c                	ld	a5,24(a5)
ffffffffc0202218:	4505                	li	a0,1
ffffffffc020221a:	9782                	jalr	a5
ffffffffc020221c:	842a                	mv	s0,a0
        if (!create || (page = alloc_page()) == NULL)
ffffffffc020221e:	12040d63          	beqz	s0,ffffffffc0202358 <get_pte+0x18c>
    return page - pages + nbase;
ffffffffc0202222:	000beb17          	auipc	s6,0xbe
ffffffffc0202226:	9c6b0b13          	addi	s6,s6,-1594 # ffffffffc02bfbe8 <pages>
ffffffffc020222a:	000b3503          	ld	a0,0(s6)
ffffffffc020222e:	00080ab7          	lui	s5,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0202232:	000be997          	auipc	s3,0xbe
ffffffffc0202236:	9ae98993          	addi	s3,s3,-1618 # ffffffffc02bfbe0 <npage>
ffffffffc020223a:	40a40533          	sub	a0,s0,a0
ffffffffc020223e:	8519                	srai	a0,a0,0x6
ffffffffc0202240:	9556                	add	a0,a0,s5
ffffffffc0202242:	0009b703          	ld	a4,0(s3)
ffffffffc0202246:	00c51793          	slli	a5,a0,0xc
    page->ref = val;
ffffffffc020224a:	4685                	li	a3,1
ffffffffc020224c:	c014                	sw	a3,0(s0)
ffffffffc020224e:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0202250:	0532                	slli	a0,a0,0xc
ffffffffc0202252:	16e7f763          	bgeu	a5,a4,ffffffffc02023c0 <get_pte+0x1f4>
ffffffffc0202256:	000be797          	auipc	a5,0xbe
ffffffffc020225a:	9a27b783          	ld	a5,-1630(a5) # ffffffffc02bfbf8 <va_pa_offset>
ffffffffc020225e:	6605                	lui	a2,0x1
ffffffffc0202260:	4581                	li	a1,0
ffffffffc0202262:	953e                	add	a0,a0,a5
ffffffffc0202264:	5d8030ef          	jal	ra,ffffffffc020583c <memset>
    return page - pages + nbase;
ffffffffc0202268:	000b3683          	ld	a3,0(s6)
ffffffffc020226c:	40d406b3          	sub	a3,s0,a3
ffffffffc0202270:	8699                	srai	a3,a3,0x6
ffffffffc0202272:	96d6                	add	a3,a3,s5
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0202274:	06aa                	slli	a3,a3,0xa
ffffffffc0202276:	0116e693          	ori	a3,a3,17
        *pdep1 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc020227a:	e094                	sd	a3,0(s1)
    }

    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc020227c:	77fd                	lui	a5,0xfffff
ffffffffc020227e:	068a                	slli	a3,a3,0x2
ffffffffc0202280:	0009b703          	ld	a4,0(s3)
ffffffffc0202284:	8efd                	and	a3,a3,a5
ffffffffc0202286:	00c6d793          	srli	a5,a3,0xc
ffffffffc020228a:	10e7ff63          	bgeu	a5,a4,ffffffffc02023a8 <get_pte+0x1dc>
ffffffffc020228e:	000bea97          	auipc	s5,0xbe
ffffffffc0202292:	96aa8a93          	addi	s5,s5,-1686 # ffffffffc02bfbf8 <va_pa_offset>
ffffffffc0202296:	000ab403          	ld	s0,0(s5)
ffffffffc020229a:	01595793          	srli	a5,s2,0x15
ffffffffc020229e:	1ff7f793          	andi	a5,a5,511
ffffffffc02022a2:	96a2                	add	a3,a3,s0
ffffffffc02022a4:	00379413          	slli	s0,a5,0x3
ffffffffc02022a8:	9436                	add	s0,s0,a3
    if (!(*pdep0 & PTE_V))
ffffffffc02022aa:	6014                	ld	a3,0(s0)
ffffffffc02022ac:	0016f793          	andi	a5,a3,1
ffffffffc02022b0:	ebad                	bnez	a5,ffffffffc0202322 <get_pte+0x156>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc02022b2:	0a0a0363          	beqz	s4,ffffffffc0202358 <get_pte+0x18c>
ffffffffc02022b6:	100027f3          	csrr	a5,sstatus
ffffffffc02022ba:	8b89                	andi	a5,a5,2
ffffffffc02022bc:	efcd                	bnez	a5,ffffffffc0202376 <get_pte+0x1aa>
        page = pmm_manager->alloc_pages(n);
ffffffffc02022be:	000be797          	auipc	a5,0xbe
ffffffffc02022c2:	9327b783          	ld	a5,-1742(a5) # ffffffffc02bfbf0 <pmm_manager>
ffffffffc02022c6:	6f9c                	ld	a5,24(a5)
ffffffffc02022c8:	4505                	li	a0,1
ffffffffc02022ca:	9782                	jalr	a5
ffffffffc02022cc:	84aa                	mv	s1,a0
        if (!create || (page = alloc_page()) == NULL)
ffffffffc02022ce:	c4c9                	beqz	s1,ffffffffc0202358 <get_pte+0x18c>
    return page - pages + nbase;
ffffffffc02022d0:	000beb17          	auipc	s6,0xbe
ffffffffc02022d4:	918b0b13          	addi	s6,s6,-1768 # ffffffffc02bfbe8 <pages>
ffffffffc02022d8:	000b3503          	ld	a0,0(s6)
ffffffffc02022dc:	00080a37          	lui	s4,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc02022e0:	0009b703          	ld	a4,0(s3)
ffffffffc02022e4:	40a48533          	sub	a0,s1,a0
ffffffffc02022e8:	8519                	srai	a0,a0,0x6
ffffffffc02022ea:	9552                	add	a0,a0,s4
ffffffffc02022ec:	00c51793          	slli	a5,a0,0xc
    page->ref = val;
ffffffffc02022f0:	4685                	li	a3,1
ffffffffc02022f2:	c094                	sw	a3,0(s1)
ffffffffc02022f4:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc02022f6:	0532                	slli	a0,a0,0xc
ffffffffc02022f8:	0ee7f163          	bgeu	a5,a4,ffffffffc02023da <get_pte+0x20e>
ffffffffc02022fc:	000ab783          	ld	a5,0(s5)
ffffffffc0202300:	6605                	lui	a2,0x1
ffffffffc0202302:	4581                	li	a1,0
ffffffffc0202304:	953e                	add	a0,a0,a5
ffffffffc0202306:	536030ef          	jal	ra,ffffffffc020583c <memset>
    return page - pages + nbase;
ffffffffc020230a:	000b3683          	ld	a3,0(s6)
ffffffffc020230e:	40d486b3          	sub	a3,s1,a3
ffffffffc0202312:	8699                	srai	a3,a3,0x6
ffffffffc0202314:	96d2                	add	a3,a3,s4
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0202316:	06aa                	slli	a3,a3,0xa
ffffffffc0202318:	0116e693          	ori	a3,a3,17
        *pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc020231c:	e014                	sd	a3,0(s0)
    }
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc020231e:	0009b703          	ld	a4,0(s3)
ffffffffc0202322:	068a                	slli	a3,a3,0x2
ffffffffc0202324:	757d                	lui	a0,0xfffff
ffffffffc0202326:	8ee9                	and	a3,a3,a0
ffffffffc0202328:	00c6d793          	srli	a5,a3,0xc
ffffffffc020232c:	06e7f263          	bgeu	a5,a4,ffffffffc0202390 <get_pte+0x1c4>
ffffffffc0202330:	000ab503          	ld	a0,0(s5)
ffffffffc0202334:	00c95913          	srli	s2,s2,0xc
ffffffffc0202338:	1ff97913          	andi	s2,s2,511
ffffffffc020233c:	96aa                	add	a3,a3,a0
ffffffffc020233e:	00391513          	slli	a0,s2,0x3
ffffffffc0202342:	9536                	add	a0,a0,a3
}
ffffffffc0202344:	70e2                	ld	ra,56(sp)
ffffffffc0202346:	7442                	ld	s0,48(sp)
ffffffffc0202348:	74a2                	ld	s1,40(sp)
ffffffffc020234a:	7902                	ld	s2,32(sp)
ffffffffc020234c:	69e2                	ld	s3,24(sp)
ffffffffc020234e:	6a42                	ld	s4,16(sp)
ffffffffc0202350:	6aa2                	ld	s5,8(sp)
ffffffffc0202352:	6b02                	ld	s6,0(sp)
ffffffffc0202354:	6121                	addi	sp,sp,64
ffffffffc0202356:	8082                	ret
            return NULL;
ffffffffc0202358:	4501                	li	a0,0
ffffffffc020235a:	b7ed                	j	ffffffffc0202344 <get_pte+0x178>
        intr_disable();
ffffffffc020235c:	e58fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202360:	000be797          	auipc	a5,0xbe
ffffffffc0202364:	8907b783          	ld	a5,-1904(a5) # ffffffffc02bfbf0 <pmm_manager>
ffffffffc0202368:	6f9c                	ld	a5,24(a5)
ffffffffc020236a:	4505                	li	a0,1
ffffffffc020236c:	9782                	jalr	a5
ffffffffc020236e:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202370:	e3efe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202374:	b56d                	j	ffffffffc020221e <get_pte+0x52>
        intr_disable();
ffffffffc0202376:	e3efe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc020237a:	000be797          	auipc	a5,0xbe
ffffffffc020237e:	8767b783          	ld	a5,-1930(a5) # ffffffffc02bfbf0 <pmm_manager>
ffffffffc0202382:	6f9c                	ld	a5,24(a5)
ffffffffc0202384:	4505                	li	a0,1
ffffffffc0202386:	9782                	jalr	a5
ffffffffc0202388:	84aa                	mv	s1,a0
        intr_enable();
ffffffffc020238a:	e24fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc020238e:	b781                	j	ffffffffc02022ce <get_pte+0x102>
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0202390:	00004617          	auipc	a2,0x4
ffffffffc0202394:	d2860613          	addi	a2,a2,-728 # ffffffffc02060b8 <commands+0x5e8>
ffffffffc0202398:	0fa00593          	li	a1,250
ffffffffc020239c:	00004517          	auipc	a0,0x4
ffffffffc02023a0:	4bc50513          	addi	a0,a0,1212 # ffffffffc0206858 <default_pmm_manager+0xf8>
ffffffffc02023a4:	8eafe0ef          	jal	ra,ffffffffc020048e <__panic>
    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc02023a8:	00004617          	auipc	a2,0x4
ffffffffc02023ac:	d1060613          	addi	a2,a2,-752 # ffffffffc02060b8 <commands+0x5e8>
ffffffffc02023b0:	0ed00593          	li	a1,237
ffffffffc02023b4:	00004517          	auipc	a0,0x4
ffffffffc02023b8:	4a450513          	addi	a0,a0,1188 # ffffffffc0206858 <default_pmm_manager+0xf8>
ffffffffc02023bc:	8d2fe0ef          	jal	ra,ffffffffc020048e <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc02023c0:	86aa                	mv	a3,a0
ffffffffc02023c2:	00004617          	auipc	a2,0x4
ffffffffc02023c6:	cf660613          	addi	a2,a2,-778 # ffffffffc02060b8 <commands+0x5e8>
ffffffffc02023ca:	0e900593          	li	a1,233
ffffffffc02023ce:	00004517          	auipc	a0,0x4
ffffffffc02023d2:	48a50513          	addi	a0,a0,1162 # ffffffffc0206858 <default_pmm_manager+0xf8>
ffffffffc02023d6:	8b8fe0ef          	jal	ra,ffffffffc020048e <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc02023da:	86aa                	mv	a3,a0
ffffffffc02023dc:	00004617          	auipc	a2,0x4
ffffffffc02023e0:	cdc60613          	addi	a2,a2,-804 # ffffffffc02060b8 <commands+0x5e8>
ffffffffc02023e4:	0f700593          	li	a1,247
ffffffffc02023e8:	00004517          	auipc	a0,0x4
ffffffffc02023ec:	47050513          	addi	a0,a0,1136 # ffffffffc0206858 <default_pmm_manager+0xf8>
ffffffffc02023f0:	89efe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02023f4 <get_page>:

// get_page - get related Page struct for linear address la using PDT pgdir
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store)
{
ffffffffc02023f4:	1141                	addi	sp,sp,-16
ffffffffc02023f6:	e022                	sd	s0,0(sp)
ffffffffc02023f8:	8432                	mv	s0,a2
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc02023fa:	4601                	li	a2,0
{
ffffffffc02023fc:	e406                	sd	ra,8(sp)
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc02023fe:	dcfff0ef          	jal	ra,ffffffffc02021cc <get_pte>
    if (ptep_store != NULL)
ffffffffc0202402:	c011                	beqz	s0,ffffffffc0202406 <get_page+0x12>
    {
        *ptep_store = ptep;
ffffffffc0202404:	e008                	sd	a0,0(s0)
    }
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc0202406:	c511                	beqz	a0,ffffffffc0202412 <get_page+0x1e>
ffffffffc0202408:	611c                	ld	a5,0(a0)
    {
        return pte2page(*ptep);
    }
    return NULL;
ffffffffc020240a:	4501                	li	a0,0
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc020240c:	0017f713          	andi	a4,a5,1
ffffffffc0202410:	e709                	bnez	a4,ffffffffc020241a <get_page+0x26>
}
ffffffffc0202412:	60a2                	ld	ra,8(sp)
ffffffffc0202414:	6402                	ld	s0,0(sp)
ffffffffc0202416:	0141                	addi	sp,sp,16
ffffffffc0202418:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc020241a:	078a                	slli	a5,a5,0x2
ffffffffc020241c:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc020241e:	000bd717          	auipc	a4,0xbd
ffffffffc0202422:	7c273703          	ld	a4,1986(a4) # ffffffffc02bfbe0 <npage>
ffffffffc0202426:	00e7ff63          	bgeu	a5,a4,ffffffffc0202444 <get_page+0x50>
ffffffffc020242a:	60a2                	ld	ra,8(sp)
ffffffffc020242c:	6402                	ld	s0,0(sp)
    return &pages[PPN(pa) - nbase];
ffffffffc020242e:	fff80537          	lui	a0,0xfff80
ffffffffc0202432:	97aa                	add	a5,a5,a0
ffffffffc0202434:	079a                	slli	a5,a5,0x6
ffffffffc0202436:	000bd517          	auipc	a0,0xbd
ffffffffc020243a:	7b253503          	ld	a0,1970(a0) # ffffffffc02bfbe8 <pages>
ffffffffc020243e:	953e                	add	a0,a0,a5
ffffffffc0202440:	0141                	addi	sp,sp,16
ffffffffc0202442:	8082                	ret
ffffffffc0202444:	c99ff0ef          	jal	ra,ffffffffc02020dc <pa2page.part.0>

ffffffffc0202448 <unmap_range>:
        tlb_invalidate(pgdir, la);
    }
}

void unmap_range(pde_t *pgdir, uintptr_t start, uintptr_t end)
{
ffffffffc0202448:	7159                	addi	sp,sp,-112
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc020244a:	00c5e7b3          	or	a5,a1,a2
{
ffffffffc020244e:	f486                	sd	ra,104(sp)
ffffffffc0202450:	f0a2                	sd	s0,96(sp)
ffffffffc0202452:	eca6                	sd	s1,88(sp)
ffffffffc0202454:	e8ca                	sd	s2,80(sp)
ffffffffc0202456:	e4ce                	sd	s3,72(sp)
ffffffffc0202458:	e0d2                	sd	s4,64(sp)
ffffffffc020245a:	fc56                	sd	s5,56(sp)
ffffffffc020245c:	f85a                	sd	s6,48(sp)
ffffffffc020245e:	f45e                	sd	s7,40(sp)
ffffffffc0202460:	f062                	sd	s8,32(sp)
ffffffffc0202462:	ec66                	sd	s9,24(sp)
ffffffffc0202464:	e86a                	sd	s10,16(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202466:	17d2                	slli	a5,a5,0x34
ffffffffc0202468:	e3ed                	bnez	a5,ffffffffc020254a <unmap_range+0x102>
    assert(USER_ACCESS(start, end));
ffffffffc020246a:	002007b7          	lui	a5,0x200
ffffffffc020246e:	842e                	mv	s0,a1
ffffffffc0202470:	0ef5ed63          	bltu	a1,a5,ffffffffc020256a <unmap_range+0x122>
ffffffffc0202474:	8932                	mv	s2,a2
ffffffffc0202476:	0ec5fa63          	bgeu	a1,a2,ffffffffc020256a <unmap_range+0x122>
ffffffffc020247a:	4785                	li	a5,1
ffffffffc020247c:	07fe                	slli	a5,a5,0x1f
ffffffffc020247e:	0ec7e663          	bltu	a5,a2,ffffffffc020256a <unmap_range+0x122>
ffffffffc0202482:	89aa                	mv	s3,a0
        }
        if (*ptep != 0)
        {
            page_remove_pte(pgdir, start, ptep);
        }
        start += PGSIZE;
ffffffffc0202484:	6a05                	lui	s4,0x1
    if (PPN(pa) >= npage)
ffffffffc0202486:	000bdc97          	auipc	s9,0xbd
ffffffffc020248a:	75ac8c93          	addi	s9,s9,1882 # ffffffffc02bfbe0 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc020248e:	000bdc17          	auipc	s8,0xbd
ffffffffc0202492:	75ac0c13          	addi	s8,s8,1882 # ffffffffc02bfbe8 <pages>
ffffffffc0202496:	fff80bb7          	lui	s7,0xfff80
        pmm_manager->free_pages(base, n);
ffffffffc020249a:	000bdd17          	auipc	s10,0xbd
ffffffffc020249e:	756d0d13          	addi	s10,s10,1878 # ffffffffc02bfbf0 <pmm_manager>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc02024a2:	00200b37          	lui	s6,0x200
ffffffffc02024a6:	ffe00ab7          	lui	s5,0xffe00
        pte_t *ptep = get_pte(pgdir, start, 0);
ffffffffc02024aa:	4601                	li	a2,0
ffffffffc02024ac:	85a2                	mv	a1,s0
ffffffffc02024ae:	854e                	mv	a0,s3
ffffffffc02024b0:	d1dff0ef          	jal	ra,ffffffffc02021cc <get_pte>
ffffffffc02024b4:	84aa                	mv	s1,a0
        if (ptep == NULL)
ffffffffc02024b6:	cd29                	beqz	a0,ffffffffc0202510 <unmap_range+0xc8>
        if (*ptep != 0)
ffffffffc02024b8:	611c                	ld	a5,0(a0)
ffffffffc02024ba:	e395                	bnez	a5,ffffffffc02024de <unmap_range+0x96>
        start += PGSIZE;
ffffffffc02024bc:	9452                	add	s0,s0,s4
    } while (start != 0 && start < end);
ffffffffc02024be:	ff2466e3          	bltu	s0,s2,ffffffffc02024aa <unmap_range+0x62>
}
ffffffffc02024c2:	70a6                	ld	ra,104(sp)
ffffffffc02024c4:	7406                	ld	s0,96(sp)
ffffffffc02024c6:	64e6                	ld	s1,88(sp)
ffffffffc02024c8:	6946                	ld	s2,80(sp)
ffffffffc02024ca:	69a6                	ld	s3,72(sp)
ffffffffc02024cc:	6a06                	ld	s4,64(sp)
ffffffffc02024ce:	7ae2                	ld	s5,56(sp)
ffffffffc02024d0:	7b42                	ld	s6,48(sp)
ffffffffc02024d2:	7ba2                	ld	s7,40(sp)
ffffffffc02024d4:	7c02                	ld	s8,32(sp)
ffffffffc02024d6:	6ce2                	ld	s9,24(sp)
ffffffffc02024d8:	6d42                	ld	s10,16(sp)
ffffffffc02024da:	6165                	addi	sp,sp,112
ffffffffc02024dc:	8082                	ret
    if (*ptep & PTE_V)
ffffffffc02024de:	0017f713          	andi	a4,a5,1
ffffffffc02024e2:	df69                	beqz	a4,ffffffffc02024bc <unmap_range+0x74>
    if (PPN(pa) >= npage)
ffffffffc02024e4:	000cb703          	ld	a4,0(s9)
    return pa2page(PTE_ADDR(pte));
ffffffffc02024e8:	078a                	slli	a5,a5,0x2
ffffffffc02024ea:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02024ec:	08e7ff63          	bgeu	a5,a4,ffffffffc020258a <unmap_range+0x142>
    return &pages[PPN(pa) - nbase];
ffffffffc02024f0:	000c3503          	ld	a0,0(s8)
ffffffffc02024f4:	97de                	add	a5,a5,s7
ffffffffc02024f6:	079a                	slli	a5,a5,0x6
ffffffffc02024f8:	953e                	add	a0,a0,a5
    page->ref -= 1;
ffffffffc02024fa:	411c                	lw	a5,0(a0)
ffffffffc02024fc:	fff7871b          	addiw	a4,a5,-1
ffffffffc0202500:	c118                	sw	a4,0(a0)
        if (page_ref(page) == 0)
ffffffffc0202502:	cf11                	beqz	a4,ffffffffc020251e <unmap_range+0xd6>
        *ptep = 0;
ffffffffc0202504:	0004b023          	sd	zero,0(s1)

// invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
void tlb_invalidate(pde_t *pgdir, uintptr_t la)
{
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202508:	12040073          	sfence.vma	s0
        start += PGSIZE;
ffffffffc020250c:	9452                	add	s0,s0,s4
    } while (start != 0 && start < end);
ffffffffc020250e:	bf45                	j	ffffffffc02024be <unmap_range+0x76>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc0202510:	945a                	add	s0,s0,s6
ffffffffc0202512:	01547433          	and	s0,s0,s5
    } while (start != 0 && start < end);
ffffffffc0202516:	d455                	beqz	s0,ffffffffc02024c2 <unmap_range+0x7a>
ffffffffc0202518:	f92469e3          	bltu	s0,s2,ffffffffc02024aa <unmap_range+0x62>
ffffffffc020251c:	b75d                	j	ffffffffc02024c2 <unmap_range+0x7a>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020251e:	100027f3          	csrr	a5,sstatus
ffffffffc0202522:	8b89                	andi	a5,a5,2
ffffffffc0202524:	e799                	bnez	a5,ffffffffc0202532 <unmap_range+0xea>
        pmm_manager->free_pages(base, n);
ffffffffc0202526:	000d3783          	ld	a5,0(s10)
ffffffffc020252a:	4585                	li	a1,1
ffffffffc020252c:	739c                	ld	a5,32(a5)
ffffffffc020252e:	9782                	jalr	a5
    if (flag)
ffffffffc0202530:	bfd1                	j	ffffffffc0202504 <unmap_range+0xbc>
ffffffffc0202532:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202534:	c80fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0202538:	000d3783          	ld	a5,0(s10)
ffffffffc020253c:	6522                	ld	a0,8(sp)
ffffffffc020253e:	4585                	li	a1,1
ffffffffc0202540:	739c                	ld	a5,32(a5)
ffffffffc0202542:	9782                	jalr	a5
        intr_enable();
ffffffffc0202544:	c6afe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202548:	bf75                	j	ffffffffc0202504 <unmap_range+0xbc>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc020254a:	00004697          	auipc	a3,0x4
ffffffffc020254e:	31e68693          	addi	a3,a3,798 # ffffffffc0206868 <default_pmm_manager+0x108>
ffffffffc0202552:	00004617          	auipc	a2,0x4
ffffffffc0202556:	e5e60613          	addi	a2,a2,-418 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc020255a:	12000593          	li	a1,288
ffffffffc020255e:	00004517          	auipc	a0,0x4
ffffffffc0202562:	2fa50513          	addi	a0,a0,762 # ffffffffc0206858 <default_pmm_manager+0xf8>
ffffffffc0202566:	f29fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(USER_ACCESS(start, end));
ffffffffc020256a:	00004697          	auipc	a3,0x4
ffffffffc020256e:	32e68693          	addi	a3,a3,814 # ffffffffc0206898 <default_pmm_manager+0x138>
ffffffffc0202572:	00004617          	auipc	a2,0x4
ffffffffc0202576:	e3e60613          	addi	a2,a2,-450 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc020257a:	12100593          	li	a1,289
ffffffffc020257e:	00004517          	auipc	a0,0x4
ffffffffc0202582:	2da50513          	addi	a0,a0,730 # ffffffffc0206858 <default_pmm_manager+0xf8>
ffffffffc0202586:	f09fd0ef          	jal	ra,ffffffffc020048e <__panic>
ffffffffc020258a:	b53ff0ef          	jal	ra,ffffffffc02020dc <pa2page.part.0>

ffffffffc020258e <exit_range>:
{
ffffffffc020258e:	7119                	addi	sp,sp,-128
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202590:	00c5e7b3          	or	a5,a1,a2
{
ffffffffc0202594:	fc86                	sd	ra,120(sp)
ffffffffc0202596:	f8a2                	sd	s0,112(sp)
ffffffffc0202598:	f4a6                	sd	s1,104(sp)
ffffffffc020259a:	f0ca                	sd	s2,96(sp)
ffffffffc020259c:	ecce                	sd	s3,88(sp)
ffffffffc020259e:	e8d2                	sd	s4,80(sp)
ffffffffc02025a0:	e4d6                	sd	s5,72(sp)
ffffffffc02025a2:	e0da                	sd	s6,64(sp)
ffffffffc02025a4:	fc5e                	sd	s7,56(sp)
ffffffffc02025a6:	f862                	sd	s8,48(sp)
ffffffffc02025a8:	f466                	sd	s9,40(sp)
ffffffffc02025aa:	f06a                	sd	s10,32(sp)
ffffffffc02025ac:	ec6e                	sd	s11,24(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02025ae:	17d2                	slli	a5,a5,0x34
ffffffffc02025b0:	20079a63          	bnez	a5,ffffffffc02027c4 <exit_range+0x236>
    assert(USER_ACCESS(start, end));
ffffffffc02025b4:	002007b7          	lui	a5,0x200
ffffffffc02025b8:	24f5e463          	bltu	a1,a5,ffffffffc0202800 <exit_range+0x272>
ffffffffc02025bc:	8ab2                	mv	s5,a2
ffffffffc02025be:	24c5f163          	bgeu	a1,a2,ffffffffc0202800 <exit_range+0x272>
ffffffffc02025c2:	4785                	li	a5,1
ffffffffc02025c4:	07fe                	slli	a5,a5,0x1f
ffffffffc02025c6:	22c7ed63          	bltu	a5,a2,ffffffffc0202800 <exit_range+0x272>
    d1start = ROUNDDOWN(start, PDSIZE);
ffffffffc02025ca:	c00009b7          	lui	s3,0xc0000
ffffffffc02025ce:	0135f9b3          	and	s3,a1,s3
    d0start = ROUNDDOWN(start, PTSIZE);
ffffffffc02025d2:	ffe00937          	lui	s2,0xffe00
ffffffffc02025d6:	400007b7          	lui	a5,0x40000
    return KADDR(page2pa(page));
ffffffffc02025da:	5cfd                	li	s9,-1
ffffffffc02025dc:	8c2a                	mv	s8,a0
ffffffffc02025de:	0125f933          	and	s2,a1,s2
ffffffffc02025e2:	99be                	add	s3,s3,a5
    if (PPN(pa) >= npage)
ffffffffc02025e4:	000bdd17          	auipc	s10,0xbd
ffffffffc02025e8:	5fcd0d13          	addi	s10,s10,1532 # ffffffffc02bfbe0 <npage>
    return KADDR(page2pa(page));
ffffffffc02025ec:	00ccdc93          	srli	s9,s9,0xc
    return &pages[PPN(pa) - nbase];
ffffffffc02025f0:	000bd717          	auipc	a4,0xbd
ffffffffc02025f4:	5f870713          	addi	a4,a4,1528 # ffffffffc02bfbe8 <pages>
        pmm_manager->free_pages(base, n);
ffffffffc02025f8:	000bdd97          	auipc	s11,0xbd
ffffffffc02025fc:	5f8d8d93          	addi	s11,s11,1528 # ffffffffc02bfbf0 <pmm_manager>
        pde1 = pgdir[PDX1(d1start)];
ffffffffc0202600:	c0000437          	lui	s0,0xc0000
ffffffffc0202604:	944e                	add	s0,s0,s3
ffffffffc0202606:	8079                	srli	s0,s0,0x1e
ffffffffc0202608:	1ff47413          	andi	s0,s0,511
ffffffffc020260c:	040e                	slli	s0,s0,0x3
ffffffffc020260e:	9462                	add	s0,s0,s8
ffffffffc0202610:	00043a03          	ld	s4,0(s0) # ffffffffc0000000 <_binary_obj___user_exit_out_size+0xffffffffbfff4ec0>
        if (pde1 & PTE_V)
ffffffffc0202614:	001a7793          	andi	a5,s4,1
ffffffffc0202618:	eb99                	bnez	a5,ffffffffc020262e <exit_range+0xa0>
    } while (d1start != 0 && d1start < end);
ffffffffc020261a:	12098463          	beqz	s3,ffffffffc0202742 <exit_range+0x1b4>
ffffffffc020261e:	400007b7          	lui	a5,0x40000
ffffffffc0202622:	97ce                	add	a5,a5,s3
ffffffffc0202624:	894e                	mv	s2,s3
ffffffffc0202626:	1159fe63          	bgeu	s3,s5,ffffffffc0202742 <exit_range+0x1b4>
ffffffffc020262a:	89be                	mv	s3,a5
ffffffffc020262c:	bfd1                	j	ffffffffc0202600 <exit_range+0x72>
    if (PPN(pa) >= npage)
ffffffffc020262e:	000d3783          	ld	a5,0(s10)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202632:	0a0a                	slli	s4,s4,0x2
ffffffffc0202634:	00ca5a13          	srli	s4,s4,0xc
    if (PPN(pa) >= npage)
ffffffffc0202638:	1cfa7263          	bgeu	s4,a5,ffffffffc02027fc <exit_range+0x26e>
    return &pages[PPN(pa) - nbase];
ffffffffc020263c:	fff80637          	lui	a2,0xfff80
ffffffffc0202640:	9652                	add	a2,a2,s4
    return page - pages + nbase;
ffffffffc0202642:	000806b7          	lui	a3,0x80
ffffffffc0202646:	96b2                	add	a3,a3,a2
    return KADDR(page2pa(page));
ffffffffc0202648:	0196f5b3          	and	a1,a3,s9
    return &pages[PPN(pa) - nbase];
ffffffffc020264c:	061a                	slli	a2,a2,0x6
    return page2ppn(page) << PGSHIFT;
ffffffffc020264e:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202650:	18f5fa63          	bgeu	a1,a5,ffffffffc02027e4 <exit_range+0x256>
ffffffffc0202654:	000bd817          	auipc	a6,0xbd
ffffffffc0202658:	5a480813          	addi	a6,a6,1444 # ffffffffc02bfbf8 <va_pa_offset>
ffffffffc020265c:	00083b03          	ld	s6,0(a6)
            free_pd0 = 1;
ffffffffc0202660:	4b85                	li	s7,1
    return &pages[PPN(pa) - nbase];
ffffffffc0202662:	fff80e37          	lui	t3,0xfff80
    return KADDR(page2pa(page));
ffffffffc0202666:	9b36                	add	s6,s6,a3
    return page - pages + nbase;
ffffffffc0202668:	00080337          	lui	t1,0x80
ffffffffc020266c:	6885                	lui	a7,0x1
ffffffffc020266e:	a819                	j	ffffffffc0202684 <exit_range+0xf6>
                    free_pd0 = 0;
ffffffffc0202670:	4b81                	li	s7,0
                d0start += PTSIZE;
ffffffffc0202672:	002007b7          	lui	a5,0x200
ffffffffc0202676:	993e                	add	s2,s2,a5
            } while (d0start != 0 && d0start < d1start + PDSIZE && d0start < end);
ffffffffc0202678:	08090c63          	beqz	s2,ffffffffc0202710 <exit_range+0x182>
ffffffffc020267c:	09397a63          	bgeu	s2,s3,ffffffffc0202710 <exit_range+0x182>
ffffffffc0202680:	0f597063          	bgeu	s2,s5,ffffffffc0202760 <exit_range+0x1d2>
                pde0 = pd0[PDX0(d0start)];
ffffffffc0202684:	01595493          	srli	s1,s2,0x15
ffffffffc0202688:	1ff4f493          	andi	s1,s1,511
ffffffffc020268c:	048e                	slli	s1,s1,0x3
ffffffffc020268e:	94da                	add	s1,s1,s6
ffffffffc0202690:	609c                	ld	a5,0(s1)
                if (pde0 & PTE_V)
ffffffffc0202692:	0017f693          	andi	a3,a5,1
ffffffffc0202696:	dee9                	beqz	a3,ffffffffc0202670 <exit_range+0xe2>
    if (PPN(pa) >= npage)
ffffffffc0202698:	000d3583          	ld	a1,0(s10)
    return pa2page(PDE_ADDR(pde));
ffffffffc020269c:	078a                	slli	a5,a5,0x2
ffffffffc020269e:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02026a0:	14b7fe63          	bgeu	a5,a1,ffffffffc02027fc <exit_range+0x26e>
    return &pages[PPN(pa) - nbase];
ffffffffc02026a4:	97f2                	add	a5,a5,t3
    return page - pages + nbase;
ffffffffc02026a6:	006786b3          	add	a3,a5,t1
    return KADDR(page2pa(page));
ffffffffc02026aa:	0196feb3          	and	t4,a3,s9
    return &pages[PPN(pa) - nbase];
ffffffffc02026ae:	00679513          	slli	a0,a5,0x6
    return page2ppn(page) << PGSHIFT;
ffffffffc02026b2:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02026b4:	12bef863          	bgeu	t4,a1,ffffffffc02027e4 <exit_range+0x256>
ffffffffc02026b8:	00083783          	ld	a5,0(a6)
ffffffffc02026bc:	96be                	add	a3,a3,a5
                    for (int i = 0; i < NPTEENTRY; i++)
ffffffffc02026be:	011685b3          	add	a1,a3,a7
                        if (pt[i] & PTE_V)
ffffffffc02026c2:	629c                	ld	a5,0(a3)
ffffffffc02026c4:	8b85                	andi	a5,a5,1
ffffffffc02026c6:	f7d5                	bnez	a5,ffffffffc0202672 <exit_range+0xe4>
                    for (int i = 0; i < NPTEENTRY; i++)
ffffffffc02026c8:	06a1                	addi	a3,a3,8
ffffffffc02026ca:	fed59ce3          	bne	a1,a3,ffffffffc02026c2 <exit_range+0x134>
    return &pages[PPN(pa) - nbase];
ffffffffc02026ce:	631c                	ld	a5,0(a4)
ffffffffc02026d0:	953e                	add	a0,a0,a5
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02026d2:	100027f3          	csrr	a5,sstatus
ffffffffc02026d6:	8b89                	andi	a5,a5,2
ffffffffc02026d8:	e7d9                	bnez	a5,ffffffffc0202766 <exit_range+0x1d8>
        pmm_manager->free_pages(base, n);
ffffffffc02026da:	000db783          	ld	a5,0(s11)
ffffffffc02026de:	4585                	li	a1,1
ffffffffc02026e0:	e032                	sd	a2,0(sp)
ffffffffc02026e2:	739c                	ld	a5,32(a5)
ffffffffc02026e4:	9782                	jalr	a5
    if (flag)
ffffffffc02026e6:	6602                	ld	a2,0(sp)
ffffffffc02026e8:	000bd817          	auipc	a6,0xbd
ffffffffc02026ec:	51080813          	addi	a6,a6,1296 # ffffffffc02bfbf8 <va_pa_offset>
ffffffffc02026f0:	fff80e37          	lui	t3,0xfff80
ffffffffc02026f4:	00080337          	lui	t1,0x80
ffffffffc02026f8:	6885                	lui	a7,0x1
ffffffffc02026fa:	000bd717          	auipc	a4,0xbd
ffffffffc02026fe:	4ee70713          	addi	a4,a4,1262 # ffffffffc02bfbe8 <pages>
                        pd0[PDX0(d0start)] = 0;
ffffffffc0202702:	0004b023          	sd	zero,0(s1)
                d0start += PTSIZE;
ffffffffc0202706:	002007b7          	lui	a5,0x200
ffffffffc020270a:	993e                	add	s2,s2,a5
            } while (d0start != 0 && d0start < d1start + PDSIZE && d0start < end);
ffffffffc020270c:	f60918e3          	bnez	s2,ffffffffc020267c <exit_range+0xee>
            if (free_pd0)
ffffffffc0202710:	f00b85e3          	beqz	s7,ffffffffc020261a <exit_range+0x8c>
    if (PPN(pa) >= npage)
ffffffffc0202714:	000d3783          	ld	a5,0(s10)
ffffffffc0202718:	0efa7263          	bgeu	s4,a5,ffffffffc02027fc <exit_range+0x26e>
    return &pages[PPN(pa) - nbase];
ffffffffc020271c:	6308                	ld	a0,0(a4)
ffffffffc020271e:	9532                	add	a0,a0,a2
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0202720:	100027f3          	csrr	a5,sstatus
ffffffffc0202724:	8b89                	andi	a5,a5,2
ffffffffc0202726:	efad                	bnez	a5,ffffffffc02027a0 <exit_range+0x212>
        pmm_manager->free_pages(base, n);
ffffffffc0202728:	000db783          	ld	a5,0(s11)
ffffffffc020272c:	4585                	li	a1,1
ffffffffc020272e:	739c                	ld	a5,32(a5)
ffffffffc0202730:	9782                	jalr	a5
ffffffffc0202732:	000bd717          	auipc	a4,0xbd
ffffffffc0202736:	4b670713          	addi	a4,a4,1206 # ffffffffc02bfbe8 <pages>
                pgdir[PDX1(d1start)] = 0;
ffffffffc020273a:	00043023          	sd	zero,0(s0)
    } while (d1start != 0 && d1start < end);
ffffffffc020273e:	ee0990e3          	bnez	s3,ffffffffc020261e <exit_range+0x90>
}
ffffffffc0202742:	70e6                	ld	ra,120(sp)
ffffffffc0202744:	7446                	ld	s0,112(sp)
ffffffffc0202746:	74a6                	ld	s1,104(sp)
ffffffffc0202748:	7906                	ld	s2,96(sp)
ffffffffc020274a:	69e6                	ld	s3,88(sp)
ffffffffc020274c:	6a46                	ld	s4,80(sp)
ffffffffc020274e:	6aa6                	ld	s5,72(sp)
ffffffffc0202750:	6b06                	ld	s6,64(sp)
ffffffffc0202752:	7be2                	ld	s7,56(sp)
ffffffffc0202754:	7c42                	ld	s8,48(sp)
ffffffffc0202756:	7ca2                	ld	s9,40(sp)
ffffffffc0202758:	7d02                	ld	s10,32(sp)
ffffffffc020275a:	6de2                	ld	s11,24(sp)
ffffffffc020275c:	6109                	addi	sp,sp,128
ffffffffc020275e:	8082                	ret
            if (free_pd0)
ffffffffc0202760:	ea0b8fe3          	beqz	s7,ffffffffc020261e <exit_range+0x90>
ffffffffc0202764:	bf45                	j	ffffffffc0202714 <exit_range+0x186>
ffffffffc0202766:	e032                	sd	a2,0(sp)
        intr_disable();
ffffffffc0202768:	e42a                	sd	a0,8(sp)
ffffffffc020276a:	a4afe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc020276e:	000db783          	ld	a5,0(s11)
ffffffffc0202772:	6522                	ld	a0,8(sp)
ffffffffc0202774:	4585                	li	a1,1
ffffffffc0202776:	739c                	ld	a5,32(a5)
ffffffffc0202778:	9782                	jalr	a5
        intr_enable();
ffffffffc020277a:	a34fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc020277e:	6602                	ld	a2,0(sp)
ffffffffc0202780:	000bd717          	auipc	a4,0xbd
ffffffffc0202784:	46870713          	addi	a4,a4,1128 # ffffffffc02bfbe8 <pages>
ffffffffc0202788:	6885                	lui	a7,0x1
ffffffffc020278a:	00080337          	lui	t1,0x80
ffffffffc020278e:	fff80e37          	lui	t3,0xfff80
ffffffffc0202792:	000bd817          	auipc	a6,0xbd
ffffffffc0202796:	46680813          	addi	a6,a6,1126 # ffffffffc02bfbf8 <va_pa_offset>
                        pd0[PDX0(d0start)] = 0;
ffffffffc020279a:	0004b023          	sd	zero,0(s1)
ffffffffc020279e:	b7a5                	j	ffffffffc0202706 <exit_range+0x178>
ffffffffc02027a0:	e02a                	sd	a0,0(sp)
        intr_disable();
ffffffffc02027a2:	a12fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc02027a6:	000db783          	ld	a5,0(s11)
ffffffffc02027aa:	6502                	ld	a0,0(sp)
ffffffffc02027ac:	4585                	li	a1,1
ffffffffc02027ae:	739c                	ld	a5,32(a5)
ffffffffc02027b0:	9782                	jalr	a5
        intr_enable();
ffffffffc02027b2:	9fcfe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02027b6:	000bd717          	auipc	a4,0xbd
ffffffffc02027ba:	43270713          	addi	a4,a4,1074 # ffffffffc02bfbe8 <pages>
                pgdir[PDX1(d1start)] = 0;
ffffffffc02027be:	00043023          	sd	zero,0(s0)
ffffffffc02027c2:	bfb5                	j	ffffffffc020273e <exit_range+0x1b0>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02027c4:	00004697          	auipc	a3,0x4
ffffffffc02027c8:	0a468693          	addi	a3,a3,164 # ffffffffc0206868 <default_pmm_manager+0x108>
ffffffffc02027cc:	00004617          	auipc	a2,0x4
ffffffffc02027d0:	be460613          	addi	a2,a2,-1052 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc02027d4:	13500593          	li	a1,309
ffffffffc02027d8:	00004517          	auipc	a0,0x4
ffffffffc02027dc:	08050513          	addi	a0,a0,128 # ffffffffc0206858 <default_pmm_manager+0xf8>
ffffffffc02027e0:	caffd0ef          	jal	ra,ffffffffc020048e <__panic>
    return KADDR(page2pa(page));
ffffffffc02027e4:	00004617          	auipc	a2,0x4
ffffffffc02027e8:	8d460613          	addi	a2,a2,-1836 # ffffffffc02060b8 <commands+0x5e8>
ffffffffc02027ec:	07100593          	li	a1,113
ffffffffc02027f0:	00004517          	auipc	a0,0x4
ffffffffc02027f4:	8b850513          	addi	a0,a0,-1864 # ffffffffc02060a8 <commands+0x5d8>
ffffffffc02027f8:	c97fd0ef          	jal	ra,ffffffffc020048e <__panic>
ffffffffc02027fc:	8e1ff0ef          	jal	ra,ffffffffc02020dc <pa2page.part.0>
    assert(USER_ACCESS(start, end));
ffffffffc0202800:	00004697          	auipc	a3,0x4
ffffffffc0202804:	09868693          	addi	a3,a3,152 # ffffffffc0206898 <default_pmm_manager+0x138>
ffffffffc0202808:	00004617          	auipc	a2,0x4
ffffffffc020280c:	ba860613          	addi	a2,a2,-1112 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc0202810:	13600593          	li	a1,310
ffffffffc0202814:	00004517          	auipc	a0,0x4
ffffffffc0202818:	04450513          	addi	a0,a0,68 # ffffffffc0206858 <default_pmm_manager+0xf8>
ffffffffc020281c:	c73fd0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0202820 <copy_range>:
{
ffffffffc0202820:	711d                	addi	sp,sp,-96
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202822:	00d667b3          	or	a5,a2,a3
{
ffffffffc0202826:	ec86                	sd	ra,88(sp)
ffffffffc0202828:	e8a2                	sd	s0,80(sp)
ffffffffc020282a:	e4a6                	sd	s1,72(sp)
ffffffffc020282c:	e0ca                	sd	s2,64(sp)
ffffffffc020282e:	fc4e                	sd	s3,56(sp)
ffffffffc0202830:	f852                	sd	s4,48(sp)
ffffffffc0202832:	f456                	sd	s5,40(sp)
ffffffffc0202834:	f05a                	sd	s6,32(sp)
ffffffffc0202836:	ec5e                	sd	s7,24(sp)
ffffffffc0202838:	e862                	sd	s8,16(sp)
ffffffffc020283a:	e466                	sd	s9,8(sp)
ffffffffc020283c:	e06a                	sd	s10,0(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc020283e:	17d2                	slli	a5,a5,0x34
ffffffffc0202840:	10079963          	bnez	a5,ffffffffc0202952 <copy_range+0x132>
    assert(USER_ACCESS(start, end));
ffffffffc0202844:	002007b7          	lui	a5,0x200
ffffffffc0202848:	8432                	mv	s0,a2
ffffffffc020284a:	0ef66463          	bltu	a2,a5,ffffffffc0202932 <copy_range+0x112>
ffffffffc020284e:	8936                	mv	s2,a3
ffffffffc0202850:	0ed67163          	bgeu	a2,a3,ffffffffc0202932 <copy_range+0x112>
ffffffffc0202854:	4785                	li	a5,1
ffffffffc0202856:	07fe                	slli	a5,a5,0x1f
ffffffffc0202858:	0cd7ed63          	bltu	a5,a3,ffffffffc0202932 <copy_range+0x112>
ffffffffc020285c:	8aaa                	mv	s5,a0
ffffffffc020285e:	89ae                	mv	s3,a1
        start += PGSIZE; //页对齐的地址递增
ffffffffc0202860:	6a05                	lui	s4,0x1
    if (PPN(pa) >= npage)
ffffffffc0202862:	000bdc17          	auipc	s8,0xbd
ffffffffc0202866:	37ec0c13          	addi	s8,s8,894 # ffffffffc02bfbe0 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc020286a:	000bdb97          	auipc	s7,0xbd
ffffffffc020286e:	37eb8b93          	addi	s7,s7,894 # ffffffffc02bfbe8 <pages>
ffffffffc0202872:	fff80b37          	lui	s6,0xfff80
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc0202876:	00200d37          	lui	s10,0x200
ffffffffc020287a:	ffe00cb7          	lui	s9,0xffe00
        pte_t *ptep = get_pte(from, start, 0), *nptep; //ptep和nptep都是指向页表项的指针
ffffffffc020287e:	4601                	li	a2,0
ffffffffc0202880:	85a2                	mv	a1,s0
ffffffffc0202882:	854e                	mv	a0,s3
ffffffffc0202884:	949ff0ef          	jal	ra,ffffffffc02021cc <get_pte>
ffffffffc0202888:	84aa                	mv	s1,a0
        if (ptep == NULL) {
ffffffffc020288a:	c93d                	beqz	a0,ffffffffc0202900 <copy_range+0xe0>
        if (*ptep & PTE_V) { //检查父进程页面是否有效
ffffffffc020288c:	611c                	ld	a5,0(a0)
ffffffffc020288e:	8b85                	andi	a5,a5,1
ffffffffc0202890:	e39d                	bnez	a5,ffffffffc02028b6 <copy_range+0x96>
        start += PGSIZE; //页对齐的地址递增
ffffffffc0202892:	9452                	add	s0,s0,s4
    } while (start != 0 && start < end);
ffffffffc0202894:	ff2465e3          	bltu	s0,s2,ffffffffc020287e <copy_range+0x5e>
    return 0;
ffffffffc0202898:	4501                	li	a0,0
}
ffffffffc020289a:	60e6                	ld	ra,88(sp)
ffffffffc020289c:	6446                	ld	s0,80(sp)
ffffffffc020289e:	64a6                	ld	s1,72(sp)
ffffffffc02028a0:	6906                	ld	s2,64(sp)
ffffffffc02028a2:	79e2                	ld	s3,56(sp)
ffffffffc02028a4:	7a42                	ld	s4,48(sp)
ffffffffc02028a6:	7aa2                	ld	s5,40(sp)
ffffffffc02028a8:	7b02                	ld	s6,32(sp)
ffffffffc02028aa:	6be2                	ld	s7,24(sp)
ffffffffc02028ac:	6c42                	ld	s8,16(sp)
ffffffffc02028ae:	6ca2                	ld	s9,8(sp)
ffffffffc02028b0:	6d02                	ld	s10,0(sp)
ffffffffc02028b2:	6125                	addi	sp,sp,96
ffffffffc02028b4:	8082                	ret
            if ((nptep = get_pte(to, start, 1)) == NULL) { //为子进程创建页表项（参数1表示如不存在则创建）
ffffffffc02028b6:	4605                	li	a2,1
ffffffffc02028b8:	85a2                	mv	a1,s0
ffffffffc02028ba:	8556                	mv	a0,s5
ffffffffc02028bc:	911ff0ef          	jal	ra,ffffffffc02021cc <get_pte>
ffffffffc02028c0:	c939                	beqz	a0,ffffffffc0202916 <copy_range+0xf6>
            struct Page *page = pte2page(*ptep); //从页表项指针获取对应的物理页管理结构
ffffffffc02028c2:	6098                	ld	a4,0(s1)
    if (!(pte & PTE_V))
ffffffffc02028c4:	00177793          	andi	a5,a4,1
ffffffffc02028c8:	cba9                	beqz	a5,ffffffffc020291a <copy_range+0xfa>
    if (PPN(pa) >= npage)
ffffffffc02028ca:	000c3683          	ld	a3,0(s8)
    return pa2page(PTE_ADDR(pte));
ffffffffc02028ce:	00271793          	slli	a5,a4,0x2
ffffffffc02028d2:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02028d4:	08d7ff63          	bgeu	a5,a3,ffffffffc0202972 <copy_range+0x152>
    return &pages[PPN(pa) - nbase];
ffffffffc02028d8:	000bb683          	ld	a3,0(s7)
ffffffffc02028dc:	97da                	add	a5,a5,s6
ffffffffc02028de:	079a                	slli	a5,a5,0x6
ffffffffc02028e0:	97b6                	add	a5,a5,a3
    page->ref += 1;
ffffffffc02028e2:	4394                	lw	a3,0(a5)
            if (*ptep & PTE_W) {
ffffffffc02028e4:	00477613          	andi	a2,a4,4
ffffffffc02028e8:	2685                	addiw	a3,a3,1
ffffffffc02028ea:	c215                	beqz	a2,ffffffffc020290e <copy_range+0xee>
                pte_t new_pte = ((*ptep) & ~((pte_t)0x3FF)) |  // 保留高位的物理页号（PPN）
ffffffffc02028ec:	dfb77713          	andi	a4,a4,-517
ffffffffc02028f0:	c394                	sw	a3,0(a5)
ffffffffc02028f2:	20076713          	ori	a4,a4,512
                *nptep = new_pte; //只设置子进程的页表项，父进程的页表项保持不变，仍保持写权限
ffffffffc02028f6:	e118                	sd	a4,0(a0)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02028f8:	12040073          	sfence.vma	s0
        start += PGSIZE; //页对齐的地址递增
ffffffffc02028fc:	9452                	add	s0,s0,s4
    } while (start != 0 && start < end);
ffffffffc02028fe:	bf59                	j	ffffffffc0202894 <copy_range+0x74>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc0202900:	946a                	add	s0,s0,s10
ffffffffc0202902:	01947433          	and	s0,s0,s9
    } while (start != 0 && start < end);
ffffffffc0202906:	d849                	beqz	s0,ffffffffc0202898 <copy_range+0x78>
ffffffffc0202908:	f7246be3          	bltu	s0,s2,ffffffffc020287e <copy_range+0x5e>
ffffffffc020290c:	b771                	j	ffffffffc0202898 <copy_range+0x78>
ffffffffc020290e:	c394                	sw	a3,0(a5)
                *nptep = *ptep; // 子进程的页表项指针就等同于父进程的
ffffffffc0202910:	e118                	sd	a4,0(a0)
        start += PGSIZE; //页对齐的地址递增
ffffffffc0202912:	9452                	add	s0,s0,s4
    } while (start != 0 && start < end);
ffffffffc0202914:	b741                	j	ffffffffc0202894 <copy_range+0x74>
                return -E_NO_MEM; //error_没内存
ffffffffc0202916:	5571                	li	a0,-4
ffffffffc0202918:	b749                	j	ffffffffc020289a <copy_range+0x7a>
        panic("pte2page called with invalid pte");
ffffffffc020291a:	00004617          	auipc	a2,0x4
ffffffffc020291e:	f1660613          	addi	a2,a2,-234 # ffffffffc0206830 <default_pmm_manager+0xd0>
ffffffffc0202922:	07f00593          	li	a1,127
ffffffffc0202926:	00003517          	auipc	a0,0x3
ffffffffc020292a:	78250513          	addi	a0,a0,1922 # ffffffffc02060a8 <commands+0x5d8>
ffffffffc020292e:	b61fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(USER_ACCESS(start, end));
ffffffffc0202932:	00004697          	auipc	a3,0x4
ffffffffc0202936:	f6668693          	addi	a3,a3,-154 # ffffffffc0206898 <default_pmm_manager+0x138>
ffffffffc020293a:	00004617          	auipc	a2,0x4
ffffffffc020293e:	a7660613          	addi	a2,a2,-1418 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc0202942:	18300593          	li	a1,387
ffffffffc0202946:	00004517          	auipc	a0,0x4
ffffffffc020294a:	f1250513          	addi	a0,a0,-238 # ffffffffc0206858 <default_pmm_manager+0xf8>
ffffffffc020294e:	b41fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202952:	00004697          	auipc	a3,0x4
ffffffffc0202956:	f1668693          	addi	a3,a3,-234 # ffffffffc0206868 <default_pmm_manager+0x108>
ffffffffc020295a:	00004617          	auipc	a2,0x4
ffffffffc020295e:	a5660613          	addi	a2,a2,-1450 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc0202962:	18200593          	li	a1,386
ffffffffc0202966:	00004517          	auipc	a0,0x4
ffffffffc020296a:	ef250513          	addi	a0,a0,-270 # ffffffffc0206858 <default_pmm_manager+0xf8>
ffffffffc020296e:	b21fd0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0202972:	00003617          	auipc	a2,0x3
ffffffffc0202976:	71660613          	addi	a2,a2,1814 # ffffffffc0206088 <commands+0x5b8>
ffffffffc020297a:	06900593          	li	a1,105
ffffffffc020297e:	00003517          	auipc	a0,0x3
ffffffffc0202982:	72a50513          	addi	a0,a0,1834 # ffffffffc02060a8 <commands+0x5d8>
ffffffffc0202986:	b09fd0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc020298a <page_remove>:
{
ffffffffc020298a:	7179                	addi	sp,sp,-48
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc020298c:	4601                	li	a2,0
{
ffffffffc020298e:	ec26                	sd	s1,24(sp)
ffffffffc0202990:	f406                	sd	ra,40(sp)
ffffffffc0202992:	f022                	sd	s0,32(sp)
ffffffffc0202994:	84ae                	mv	s1,a1
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0202996:	837ff0ef          	jal	ra,ffffffffc02021cc <get_pte>
    if (ptep != NULL)
ffffffffc020299a:	c511                	beqz	a0,ffffffffc02029a6 <page_remove+0x1c>
    if (*ptep & PTE_V)
ffffffffc020299c:	611c                	ld	a5,0(a0)
ffffffffc020299e:	842a                	mv	s0,a0
ffffffffc02029a0:	0017f713          	andi	a4,a5,1
ffffffffc02029a4:	e711                	bnez	a4,ffffffffc02029b0 <page_remove+0x26>
}
ffffffffc02029a6:	70a2                	ld	ra,40(sp)
ffffffffc02029a8:	7402                	ld	s0,32(sp)
ffffffffc02029aa:	64e2                	ld	s1,24(sp)
ffffffffc02029ac:	6145                	addi	sp,sp,48
ffffffffc02029ae:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc02029b0:	078a                	slli	a5,a5,0x2
ffffffffc02029b2:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02029b4:	000bd717          	auipc	a4,0xbd
ffffffffc02029b8:	22c73703          	ld	a4,556(a4) # ffffffffc02bfbe0 <npage>
ffffffffc02029bc:	06e7f363          	bgeu	a5,a4,ffffffffc0202a22 <page_remove+0x98>
    return &pages[PPN(pa) - nbase];
ffffffffc02029c0:	fff80537          	lui	a0,0xfff80
ffffffffc02029c4:	97aa                	add	a5,a5,a0
ffffffffc02029c6:	079a                	slli	a5,a5,0x6
ffffffffc02029c8:	000bd517          	auipc	a0,0xbd
ffffffffc02029cc:	22053503          	ld	a0,544(a0) # ffffffffc02bfbe8 <pages>
ffffffffc02029d0:	953e                	add	a0,a0,a5
    page->ref -= 1;
ffffffffc02029d2:	411c                	lw	a5,0(a0)
ffffffffc02029d4:	fff7871b          	addiw	a4,a5,-1
ffffffffc02029d8:	c118                	sw	a4,0(a0)
        if (page_ref(page) == 0)
ffffffffc02029da:	cb11                	beqz	a4,ffffffffc02029ee <page_remove+0x64>
        *ptep = 0;
ffffffffc02029dc:	00043023          	sd	zero,0(s0)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02029e0:	12048073          	sfence.vma	s1
}
ffffffffc02029e4:	70a2                	ld	ra,40(sp)
ffffffffc02029e6:	7402                	ld	s0,32(sp)
ffffffffc02029e8:	64e2                	ld	s1,24(sp)
ffffffffc02029ea:	6145                	addi	sp,sp,48
ffffffffc02029ec:	8082                	ret
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02029ee:	100027f3          	csrr	a5,sstatus
ffffffffc02029f2:	8b89                	andi	a5,a5,2
ffffffffc02029f4:	eb89                	bnez	a5,ffffffffc0202a06 <page_remove+0x7c>
        pmm_manager->free_pages(base, n);
ffffffffc02029f6:	000bd797          	auipc	a5,0xbd
ffffffffc02029fa:	1fa7b783          	ld	a5,506(a5) # ffffffffc02bfbf0 <pmm_manager>
ffffffffc02029fe:	739c                	ld	a5,32(a5)
ffffffffc0202a00:	4585                	li	a1,1
ffffffffc0202a02:	9782                	jalr	a5
    if (flag)
ffffffffc0202a04:	bfe1                	j	ffffffffc02029dc <page_remove+0x52>
        intr_disable();
ffffffffc0202a06:	e42a                	sd	a0,8(sp)
ffffffffc0202a08:	fadfd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0202a0c:	000bd797          	auipc	a5,0xbd
ffffffffc0202a10:	1e47b783          	ld	a5,484(a5) # ffffffffc02bfbf0 <pmm_manager>
ffffffffc0202a14:	739c                	ld	a5,32(a5)
ffffffffc0202a16:	6522                	ld	a0,8(sp)
ffffffffc0202a18:	4585                	li	a1,1
ffffffffc0202a1a:	9782                	jalr	a5
        intr_enable();
ffffffffc0202a1c:	f93fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202a20:	bf75                	j	ffffffffc02029dc <page_remove+0x52>
ffffffffc0202a22:	ebaff0ef          	jal	ra,ffffffffc02020dc <pa2page.part.0>

ffffffffc0202a26 <page_insert>:
{
ffffffffc0202a26:	7139                	addi	sp,sp,-64
ffffffffc0202a28:	e852                	sd	s4,16(sp)
ffffffffc0202a2a:	8a32                	mv	s4,a2
ffffffffc0202a2c:	f822                	sd	s0,48(sp)
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0202a2e:	4605                	li	a2,1
{
ffffffffc0202a30:	842e                	mv	s0,a1
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0202a32:	85d2                	mv	a1,s4
{
ffffffffc0202a34:	f426                	sd	s1,40(sp)
ffffffffc0202a36:	fc06                	sd	ra,56(sp)
ffffffffc0202a38:	f04a                	sd	s2,32(sp)
ffffffffc0202a3a:	ec4e                	sd	s3,24(sp)
ffffffffc0202a3c:	e456                	sd	s5,8(sp)
ffffffffc0202a3e:	84b6                	mv	s1,a3
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0202a40:	f8cff0ef          	jal	ra,ffffffffc02021cc <get_pte>
    if (ptep == NULL)
ffffffffc0202a44:	c961                	beqz	a0,ffffffffc0202b14 <page_insert+0xee>
    page->ref += 1;
ffffffffc0202a46:	4014                	lw	a3,0(s0)
    if (*ptep & PTE_V)
ffffffffc0202a48:	611c                	ld	a5,0(a0)
ffffffffc0202a4a:	89aa                	mv	s3,a0
ffffffffc0202a4c:	0016871b          	addiw	a4,a3,1
ffffffffc0202a50:	c018                	sw	a4,0(s0)
ffffffffc0202a52:	0017f713          	andi	a4,a5,1
ffffffffc0202a56:	ef05                	bnez	a4,ffffffffc0202a8e <page_insert+0x68>
    return page - pages + nbase;
ffffffffc0202a58:	000bd717          	auipc	a4,0xbd
ffffffffc0202a5c:	19073703          	ld	a4,400(a4) # ffffffffc02bfbe8 <pages>
ffffffffc0202a60:	8c19                	sub	s0,s0,a4
ffffffffc0202a62:	000807b7          	lui	a5,0x80
ffffffffc0202a66:	8419                	srai	s0,s0,0x6
ffffffffc0202a68:	943e                	add	s0,s0,a5
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0202a6a:	042a                	slli	s0,s0,0xa
ffffffffc0202a6c:	8cc1                	or	s1,s1,s0
ffffffffc0202a6e:	0014e493          	ori	s1,s1,1
    *ptep = pte_create(page2ppn(page), PTE_V | perm); 
ffffffffc0202a72:	0099b023          	sd	s1,0(s3) # ffffffffc0000000 <_binary_obj___user_exit_out_size+0xffffffffbfff4ec0>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202a76:	120a0073          	sfence.vma	s4
    return 0;
ffffffffc0202a7a:	4501                	li	a0,0
}
ffffffffc0202a7c:	70e2                	ld	ra,56(sp)
ffffffffc0202a7e:	7442                	ld	s0,48(sp)
ffffffffc0202a80:	74a2                	ld	s1,40(sp)
ffffffffc0202a82:	7902                	ld	s2,32(sp)
ffffffffc0202a84:	69e2                	ld	s3,24(sp)
ffffffffc0202a86:	6a42                	ld	s4,16(sp)
ffffffffc0202a88:	6aa2                	ld	s5,8(sp)
ffffffffc0202a8a:	6121                	addi	sp,sp,64
ffffffffc0202a8c:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc0202a8e:	078a                	slli	a5,a5,0x2
ffffffffc0202a90:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202a92:	000bd717          	auipc	a4,0xbd
ffffffffc0202a96:	14e73703          	ld	a4,334(a4) # ffffffffc02bfbe0 <npage>
ffffffffc0202a9a:	06e7ff63          	bgeu	a5,a4,ffffffffc0202b18 <page_insert+0xf2>
    return &pages[PPN(pa) - nbase];
ffffffffc0202a9e:	000bda97          	auipc	s5,0xbd
ffffffffc0202aa2:	14aa8a93          	addi	s5,s5,330 # ffffffffc02bfbe8 <pages>
ffffffffc0202aa6:	000ab703          	ld	a4,0(s5)
ffffffffc0202aaa:	fff80937          	lui	s2,0xfff80
ffffffffc0202aae:	993e                	add	s2,s2,a5
ffffffffc0202ab0:	091a                	slli	s2,s2,0x6
ffffffffc0202ab2:	993a                	add	s2,s2,a4
        if (p == page)
ffffffffc0202ab4:	01240c63          	beq	s0,s2,ffffffffc0202acc <page_insert+0xa6>
    page->ref -= 1;
ffffffffc0202ab8:	00092783          	lw	a5,0(s2) # fffffffffff80000 <end+0x3fcc03e4>
ffffffffc0202abc:	fff7869b          	addiw	a3,a5,-1
ffffffffc0202ac0:	00d92023          	sw	a3,0(s2)
        if (page_ref(page) == 0)
ffffffffc0202ac4:	c691                	beqz	a3,ffffffffc0202ad0 <page_insert+0xaa>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202ac6:	120a0073          	sfence.vma	s4
}
ffffffffc0202aca:	bf59                	j	ffffffffc0202a60 <page_insert+0x3a>
ffffffffc0202acc:	c014                	sw	a3,0(s0)
    return page->ref;
ffffffffc0202ace:	bf49                	j	ffffffffc0202a60 <page_insert+0x3a>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0202ad0:	100027f3          	csrr	a5,sstatus
ffffffffc0202ad4:	8b89                	andi	a5,a5,2
ffffffffc0202ad6:	ef91                	bnez	a5,ffffffffc0202af2 <page_insert+0xcc>
        pmm_manager->free_pages(base, n);
ffffffffc0202ad8:	000bd797          	auipc	a5,0xbd
ffffffffc0202adc:	1187b783          	ld	a5,280(a5) # ffffffffc02bfbf0 <pmm_manager>
ffffffffc0202ae0:	739c                	ld	a5,32(a5)
ffffffffc0202ae2:	4585                	li	a1,1
ffffffffc0202ae4:	854a                	mv	a0,s2
ffffffffc0202ae6:	9782                	jalr	a5
    return page - pages + nbase;
ffffffffc0202ae8:	000ab703          	ld	a4,0(s5)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202aec:	120a0073          	sfence.vma	s4
ffffffffc0202af0:	bf85                	j	ffffffffc0202a60 <page_insert+0x3a>
        intr_disable();
ffffffffc0202af2:	ec3fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202af6:	000bd797          	auipc	a5,0xbd
ffffffffc0202afa:	0fa7b783          	ld	a5,250(a5) # ffffffffc02bfbf0 <pmm_manager>
ffffffffc0202afe:	739c                	ld	a5,32(a5)
ffffffffc0202b00:	4585                	li	a1,1
ffffffffc0202b02:	854a                	mv	a0,s2
ffffffffc0202b04:	9782                	jalr	a5
        intr_enable();
ffffffffc0202b06:	ea9fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202b0a:	000ab703          	ld	a4,0(s5)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202b0e:	120a0073          	sfence.vma	s4
ffffffffc0202b12:	b7b9                	j	ffffffffc0202a60 <page_insert+0x3a>
        return -E_NO_MEM;
ffffffffc0202b14:	5571                	li	a0,-4
ffffffffc0202b16:	b79d                	j	ffffffffc0202a7c <page_insert+0x56>
ffffffffc0202b18:	dc4ff0ef          	jal	ra,ffffffffc02020dc <pa2page.part.0>

ffffffffc0202b1c <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc0202b1c:	00004797          	auipc	a5,0x4
ffffffffc0202b20:	c4478793          	addi	a5,a5,-956 # ffffffffc0206760 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0202b24:	638c                	ld	a1,0(a5)
{
ffffffffc0202b26:	7159                	addi	sp,sp,-112
ffffffffc0202b28:	f85a                	sd	s6,48(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0202b2a:	00004517          	auipc	a0,0x4
ffffffffc0202b2e:	d8650513          	addi	a0,a0,-634 # ffffffffc02068b0 <default_pmm_manager+0x150>
    pmm_manager = &default_pmm_manager;
ffffffffc0202b32:	000bdb17          	auipc	s6,0xbd
ffffffffc0202b36:	0beb0b13          	addi	s6,s6,190 # ffffffffc02bfbf0 <pmm_manager>
{
ffffffffc0202b3a:	f486                	sd	ra,104(sp)
ffffffffc0202b3c:	e8ca                	sd	s2,80(sp)
ffffffffc0202b3e:	e4ce                	sd	s3,72(sp)
ffffffffc0202b40:	f0a2                	sd	s0,96(sp)
ffffffffc0202b42:	eca6                	sd	s1,88(sp)
ffffffffc0202b44:	e0d2                	sd	s4,64(sp)
ffffffffc0202b46:	fc56                	sd	s5,56(sp)
ffffffffc0202b48:	f45e                	sd	s7,40(sp)
ffffffffc0202b4a:	f062                	sd	s8,32(sp)
ffffffffc0202b4c:	ec66                	sd	s9,24(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc0202b4e:	00fb3023          	sd	a5,0(s6)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0202b52:	e42fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    pmm_manager->init();
ffffffffc0202b56:	000b3783          	ld	a5,0(s6)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0202b5a:	000bd997          	auipc	s3,0xbd
ffffffffc0202b5e:	09e98993          	addi	s3,s3,158 # ffffffffc02bfbf8 <va_pa_offset>
    pmm_manager->init();
ffffffffc0202b62:	679c                	ld	a5,8(a5)
ffffffffc0202b64:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0202b66:	57f5                	li	a5,-3
ffffffffc0202b68:	07fa                	slli	a5,a5,0x1e
ffffffffc0202b6a:	00f9b023          	sd	a5,0(s3)
    uint64_t mem_begin = get_memory_base();
ffffffffc0202b6e:	e2dfd0ef          	jal	ra,ffffffffc020099a <get_memory_base>
ffffffffc0202b72:	892a                	mv	s2,a0
    uint64_t mem_size = get_memory_size();
ffffffffc0202b74:	e31fd0ef          	jal	ra,ffffffffc02009a4 <get_memory_size>
    if (mem_size == 0)
ffffffffc0202b78:	200505e3          	beqz	a0,ffffffffc0203582 <pmm_init+0xa66>
    uint64_t mem_end = mem_begin + mem_size;
ffffffffc0202b7c:	84aa                	mv	s1,a0
    cprintf("physcial memory map:\n");
ffffffffc0202b7e:	00004517          	auipc	a0,0x4
ffffffffc0202b82:	d6a50513          	addi	a0,a0,-662 # ffffffffc02068e8 <default_pmm_manager+0x188>
ffffffffc0202b86:	e0efd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    uint64_t mem_end = mem_begin + mem_size;
ffffffffc0202b8a:	00990433          	add	s0,s2,s1
    cprintf("  memory: 0x%08lx, [0x%08lx, 0x%08lx].\n", mem_size, mem_begin,
ffffffffc0202b8e:	fff40693          	addi	a3,s0,-1
ffffffffc0202b92:	864a                	mv	a2,s2
ffffffffc0202b94:	85a6                	mv	a1,s1
ffffffffc0202b96:	00004517          	auipc	a0,0x4
ffffffffc0202b9a:	d6a50513          	addi	a0,a0,-662 # ffffffffc0206900 <default_pmm_manager+0x1a0>
ffffffffc0202b9e:	df6fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc0202ba2:	c8000737          	lui	a4,0xc8000
ffffffffc0202ba6:	87a2                	mv	a5,s0
ffffffffc0202ba8:	54876163          	bltu	a4,s0,ffffffffc02030ea <pmm_init+0x5ce>
ffffffffc0202bac:	757d                	lui	a0,0xfffff
ffffffffc0202bae:	000be617          	auipc	a2,0xbe
ffffffffc0202bb2:	06d60613          	addi	a2,a2,109 # ffffffffc02c0c1b <end+0xfff>
ffffffffc0202bb6:	8e69                	and	a2,a2,a0
ffffffffc0202bb8:	000bd497          	auipc	s1,0xbd
ffffffffc0202bbc:	02848493          	addi	s1,s1,40 # ffffffffc02bfbe0 <npage>
ffffffffc0202bc0:	00c7d513          	srli	a0,a5,0xc
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0202bc4:	000bdb97          	auipc	s7,0xbd
ffffffffc0202bc8:	024b8b93          	addi	s7,s7,36 # ffffffffc02bfbe8 <pages>
    npage = maxpa / PGSIZE;
ffffffffc0202bcc:	e088                	sd	a0,0(s1)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0202bce:	00cbb023          	sd	a2,0(s7)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0202bd2:	000807b7          	lui	a5,0x80
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0202bd6:	86b2                	mv	a3,a2
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0202bd8:	02f50863          	beq	a0,a5,ffffffffc0202c08 <pmm_init+0xec>
ffffffffc0202bdc:	4781                	li	a5,0
ffffffffc0202bde:	4585                	li	a1,1
ffffffffc0202be0:	fff806b7          	lui	a3,0xfff80
        SetPageReserved(pages + i);
ffffffffc0202be4:	00679513          	slli	a0,a5,0x6
ffffffffc0202be8:	9532                	add	a0,a0,a2
ffffffffc0202bea:	00850713          	addi	a4,a0,8 # fffffffffffff008 <end+0x3fd3f3ec>
ffffffffc0202bee:	40b7302f          	amoor.d	zero,a1,(a4)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0202bf2:	6088                	ld	a0,0(s1)
ffffffffc0202bf4:	0785                	addi	a5,a5,1
        SetPageReserved(pages + i);
ffffffffc0202bf6:	000bb603          	ld	a2,0(s7)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0202bfa:	00d50733          	add	a4,a0,a3
ffffffffc0202bfe:	fee7e3e3          	bltu	a5,a4,ffffffffc0202be4 <pmm_init+0xc8>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0202c02:	071a                	slli	a4,a4,0x6
ffffffffc0202c04:	00e606b3          	add	a3,a2,a4
ffffffffc0202c08:	c02007b7          	lui	a5,0xc0200
ffffffffc0202c0c:	2ef6ece3          	bltu	a3,a5,ffffffffc0203704 <pmm_init+0xbe8>
ffffffffc0202c10:	0009b583          	ld	a1,0(s3)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc0202c14:	77fd                	lui	a5,0xfffff
ffffffffc0202c16:	8c7d                	and	s0,s0,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0202c18:	8e8d                	sub	a3,a3,a1
    if (freemem < mem_end)
ffffffffc0202c1a:	5086eb63          	bltu	a3,s0,ffffffffc0203130 <pmm_init+0x614>
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc0202c1e:	00004517          	auipc	a0,0x4
ffffffffc0202c22:	d0a50513          	addi	a0,a0,-758 # ffffffffc0206928 <default_pmm_manager+0x1c8>
ffffffffc0202c26:	d6efd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    return page;
}

static void check_alloc_page(void)
{
    pmm_manager->check();
ffffffffc0202c2a:	000b3783          	ld	a5,0(s6)
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc0202c2e:	000bd917          	auipc	s2,0xbd
ffffffffc0202c32:	faa90913          	addi	s2,s2,-86 # ffffffffc02bfbd8 <boot_pgdir_va>
    pmm_manager->check();
ffffffffc0202c36:	7b9c                	ld	a5,48(a5)
ffffffffc0202c38:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0202c3a:	00004517          	auipc	a0,0x4
ffffffffc0202c3e:	d0650513          	addi	a0,a0,-762 # ffffffffc0206940 <default_pmm_manager+0x1e0>
ffffffffc0202c42:	d52fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc0202c46:	00007697          	auipc	a3,0x7
ffffffffc0202c4a:	3ba68693          	addi	a3,a3,954 # ffffffffc020a000 <boot_page_table_sv39>
ffffffffc0202c4e:	00d93023          	sd	a3,0(s2)
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc0202c52:	c02007b7          	lui	a5,0xc0200
ffffffffc0202c56:	28f6ebe3          	bltu	a3,a5,ffffffffc02036ec <pmm_init+0xbd0>
ffffffffc0202c5a:	0009b783          	ld	a5,0(s3)
ffffffffc0202c5e:	8e9d                	sub	a3,a3,a5
ffffffffc0202c60:	000bd797          	auipc	a5,0xbd
ffffffffc0202c64:	f6d7b823          	sd	a3,-144(a5) # ffffffffc02bfbd0 <boot_pgdir_pa>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0202c68:	100027f3          	csrr	a5,sstatus
ffffffffc0202c6c:	8b89                	andi	a5,a5,2
ffffffffc0202c6e:	4a079763          	bnez	a5,ffffffffc020311c <pmm_init+0x600>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202c72:	000b3783          	ld	a5,0(s6)
ffffffffc0202c76:	779c                	ld	a5,40(a5)
ffffffffc0202c78:	9782                	jalr	a5
ffffffffc0202c7a:	842a                	mv	s0,a0
    // so npage is always larger than KMEMSIZE / PGSIZE
    size_t nr_free_store;

    nr_free_store = nr_free_pages();

    assert(npage <= KERNTOP / PGSIZE);
ffffffffc0202c7c:	6098                	ld	a4,0(s1)
ffffffffc0202c7e:	c80007b7          	lui	a5,0xc8000
ffffffffc0202c82:	83b1                	srli	a5,a5,0xc
ffffffffc0202c84:	66e7e363          	bltu	a5,a4,ffffffffc02032ea <pmm_init+0x7ce>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc0202c88:	00093503          	ld	a0,0(s2)
ffffffffc0202c8c:	62050f63          	beqz	a0,ffffffffc02032ca <pmm_init+0x7ae>
ffffffffc0202c90:	03451793          	slli	a5,a0,0x34
ffffffffc0202c94:	62079b63          	bnez	a5,ffffffffc02032ca <pmm_init+0x7ae>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc0202c98:	4601                	li	a2,0
ffffffffc0202c9a:	4581                	li	a1,0
ffffffffc0202c9c:	f58ff0ef          	jal	ra,ffffffffc02023f4 <get_page>
ffffffffc0202ca0:	60051563          	bnez	a0,ffffffffc02032aa <pmm_init+0x78e>
ffffffffc0202ca4:	100027f3          	csrr	a5,sstatus
ffffffffc0202ca8:	8b89                	andi	a5,a5,2
ffffffffc0202caa:	44079e63          	bnez	a5,ffffffffc0203106 <pmm_init+0x5ea>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202cae:	000b3783          	ld	a5,0(s6)
ffffffffc0202cb2:	4505                	li	a0,1
ffffffffc0202cb4:	6f9c                	ld	a5,24(a5)
ffffffffc0202cb6:	9782                	jalr	a5
ffffffffc0202cb8:	8a2a                	mv	s4,a0

    struct Page *p1, *p2;
    p1 = alloc_page();
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc0202cba:	00093503          	ld	a0,0(s2)
ffffffffc0202cbe:	4681                	li	a3,0
ffffffffc0202cc0:	4601                	li	a2,0
ffffffffc0202cc2:	85d2                	mv	a1,s4
ffffffffc0202cc4:	d63ff0ef          	jal	ra,ffffffffc0202a26 <page_insert>
ffffffffc0202cc8:	26051ae3          	bnez	a0,ffffffffc020373c <pmm_init+0xc20>

    pte_t *ptep;
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc0202ccc:	00093503          	ld	a0,0(s2)
ffffffffc0202cd0:	4601                	li	a2,0
ffffffffc0202cd2:	4581                	li	a1,0
ffffffffc0202cd4:	cf8ff0ef          	jal	ra,ffffffffc02021cc <get_pte>
ffffffffc0202cd8:	240502e3          	beqz	a0,ffffffffc020371c <pmm_init+0xc00>
    assert(pte2page(*ptep) == p1);
ffffffffc0202cdc:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V))
ffffffffc0202cde:	0017f713          	andi	a4,a5,1
ffffffffc0202ce2:	5a070263          	beqz	a4,ffffffffc0203286 <pmm_init+0x76a>
    if (PPN(pa) >= npage)
ffffffffc0202ce6:	6098                	ld	a4,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc0202ce8:	078a                	slli	a5,a5,0x2
ffffffffc0202cea:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202cec:	58e7fb63          	bgeu	a5,a4,ffffffffc0203282 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202cf0:	000bb683          	ld	a3,0(s7)
ffffffffc0202cf4:	fff80637          	lui	a2,0xfff80
ffffffffc0202cf8:	97b2                	add	a5,a5,a2
ffffffffc0202cfa:	079a                	slli	a5,a5,0x6
ffffffffc0202cfc:	97b6                	add	a5,a5,a3
ffffffffc0202cfe:	14fa17e3          	bne	s4,a5,ffffffffc020364c <pmm_init+0xb30>
    assert(page_ref(p1) == 1);
ffffffffc0202d02:	000a2683          	lw	a3,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8bd0>
ffffffffc0202d06:	4785                	li	a5,1
ffffffffc0202d08:	12f692e3          	bne	a3,a5,ffffffffc020362c <pmm_init+0xb10>

    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc0202d0c:	00093503          	ld	a0,0(s2)
ffffffffc0202d10:	77fd                	lui	a5,0xfffff
ffffffffc0202d12:	6114                	ld	a3,0(a0)
ffffffffc0202d14:	068a                	slli	a3,a3,0x2
ffffffffc0202d16:	8efd                	and	a3,a3,a5
ffffffffc0202d18:	00c6d613          	srli	a2,a3,0xc
ffffffffc0202d1c:	0ee67ce3          	bgeu	a2,a4,ffffffffc0203614 <pmm_init+0xaf8>
ffffffffc0202d20:	0009bc03          	ld	s8,0(s3)
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202d24:	96e2                	add	a3,a3,s8
ffffffffc0202d26:	0006ba83          	ld	s5,0(a3)
ffffffffc0202d2a:	0a8a                	slli	s5,s5,0x2
ffffffffc0202d2c:	00fafab3          	and	s5,s5,a5
ffffffffc0202d30:	00cad793          	srli	a5,s5,0xc
ffffffffc0202d34:	0ce7f3e3          	bgeu	a5,a4,ffffffffc02035fa <pmm_init+0xade>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202d38:	4601                	li	a2,0
ffffffffc0202d3a:	6585                	lui	a1,0x1
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202d3c:	9ae2                	add	s5,s5,s8
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202d3e:	c8eff0ef          	jal	ra,ffffffffc02021cc <get_pte>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202d42:	0aa1                	addi	s5,s5,8
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202d44:	55551363          	bne	a0,s5,ffffffffc020328a <pmm_init+0x76e>
ffffffffc0202d48:	100027f3          	csrr	a5,sstatus
ffffffffc0202d4c:	8b89                	andi	a5,a5,2
ffffffffc0202d4e:	3a079163          	bnez	a5,ffffffffc02030f0 <pmm_init+0x5d4>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202d52:	000b3783          	ld	a5,0(s6)
ffffffffc0202d56:	4505                	li	a0,1
ffffffffc0202d58:	6f9c                	ld	a5,24(a5)
ffffffffc0202d5a:	9782                	jalr	a5
ffffffffc0202d5c:	8c2a                	mv	s8,a0

    p2 = alloc_page();
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc0202d5e:	00093503          	ld	a0,0(s2)
ffffffffc0202d62:	46d1                	li	a3,20
ffffffffc0202d64:	6605                	lui	a2,0x1
ffffffffc0202d66:	85e2                	mv	a1,s8
ffffffffc0202d68:	cbfff0ef          	jal	ra,ffffffffc0202a26 <page_insert>
ffffffffc0202d6c:	060517e3          	bnez	a0,ffffffffc02035da <pmm_init+0xabe>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0202d70:	00093503          	ld	a0,0(s2)
ffffffffc0202d74:	4601                	li	a2,0
ffffffffc0202d76:	6585                	lui	a1,0x1
ffffffffc0202d78:	c54ff0ef          	jal	ra,ffffffffc02021cc <get_pte>
ffffffffc0202d7c:	02050fe3          	beqz	a0,ffffffffc02035ba <pmm_init+0xa9e>
    assert(*ptep & PTE_U);
ffffffffc0202d80:	611c                	ld	a5,0(a0)
ffffffffc0202d82:	0107f713          	andi	a4,a5,16
ffffffffc0202d86:	7c070e63          	beqz	a4,ffffffffc0203562 <pmm_init+0xa46>
    assert(*ptep & PTE_W);
ffffffffc0202d8a:	8b91                	andi	a5,a5,4
ffffffffc0202d8c:	7a078b63          	beqz	a5,ffffffffc0203542 <pmm_init+0xa26>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc0202d90:	00093503          	ld	a0,0(s2)
ffffffffc0202d94:	611c                	ld	a5,0(a0)
ffffffffc0202d96:	8bc1                	andi	a5,a5,16
ffffffffc0202d98:	78078563          	beqz	a5,ffffffffc0203522 <pmm_init+0xa06>
    assert(page_ref(p2) == 1);
ffffffffc0202d9c:	000c2703          	lw	a4,0(s8)
ffffffffc0202da0:	4785                	li	a5,1
ffffffffc0202da2:	76f71063          	bne	a4,a5,ffffffffc0203502 <pmm_init+0x9e6>

    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc0202da6:	4681                	li	a3,0
ffffffffc0202da8:	6605                	lui	a2,0x1
ffffffffc0202daa:	85d2                	mv	a1,s4
ffffffffc0202dac:	c7bff0ef          	jal	ra,ffffffffc0202a26 <page_insert>
ffffffffc0202db0:	72051963          	bnez	a0,ffffffffc02034e2 <pmm_init+0x9c6>
    assert(page_ref(p1) == 2);
ffffffffc0202db4:	000a2703          	lw	a4,0(s4)
ffffffffc0202db8:	4789                	li	a5,2
ffffffffc0202dba:	70f71463          	bne	a4,a5,ffffffffc02034c2 <pmm_init+0x9a6>
    assert(page_ref(p2) == 0);
ffffffffc0202dbe:	000c2783          	lw	a5,0(s8)
ffffffffc0202dc2:	6e079063          	bnez	a5,ffffffffc02034a2 <pmm_init+0x986>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0202dc6:	00093503          	ld	a0,0(s2)
ffffffffc0202dca:	4601                	li	a2,0
ffffffffc0202dcc:	6585                	lui	a1,0x1
ffffffffc0202dce:	bfeff0ef          	jal	ra,ffffffffc02021cc <get_pte>
ffffffffc0202dd2:	6a050863          	beqz	a0,ffffffffc0203482 <pmm_init+0x966>
    assert(pte2page(*ptep) == p1);
ffffffffc0202dd6:	6118                	ld	a4,0(a0)
    if (!(pte & PTE_V))
ffffffffc0202dd8:	00177793          	andi	a5,a4,1
ffffffffc0202ddc:	4a078563          	beqz	a5,ffffffffc0203286 <pmm_init+0x76a>
    if (PPN(pa) >= npage)
ffffffffc0202de0:	6094                	ld	a3,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc0202de2:	00271793          	slli	a5,a4,0x2
ffffffffc0202de6:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202de8:	48d7fd63          	bgeu	a5,a3,ffffffffc0203282 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202dec:	000bb683          	ld	a3,0(s7)
ffffffffc0202df0:	fff80ab7          	lui	s5,0xfff80
ffffffffc0202df4:	97d6                	add	a5,a5,s5
ffffffffc0202df6:	079a                	slli	a5,a5,0x6
ffffffffc0202df8:	97b6                	add	a5,a5,a3
ffffffffc0202dfa:	66fa1463          	bne	s4,a5,ffffffffc0203462 <pmm_init+0x946>
    assert((*ptep & PTE_U) == 0);
ffffffffc0202dfe:	8b41                	andi	a4,a4,16
ffffffffc0202e00:	64071163          	bnez	a4,ffffffffc0203442 <pmm_init+0x926>

    page_remove(boot_pgdir_va, 0x0);
ffffffffc0202e04:	00093503          	ld	a0,0(s2)
ffffffffc0202e08:	4581                	li	a1,0
ffffffffc0202e0a:	b81ff0ef          	jal	ra,ffffffffc020298a <page_remove>
    assert(page_ref(p1) == 1);
ffffffffc0202e0e:	000a2c83          	lw	s9,0(s4)
ffffffffc0202e12:	4785                	li	a5,1
ffffffffc0202e14:	60fc9763          	bne	s9,a5,ffffffffc0203422 <pmm_init+0x906>
    assert(page_ref(p2) == 0);
ffffffffc0202e18:	000c2783          	lw	a5,0(s8)
ffffffffc0202e1c:	5e079363          	bnez	a5,ffffffffc0203402 <pmm_init+0x8e6>

    page_remove(boot_pgdir_va, PGSIZE);
ffffffffc0202e20:	00093503          	ld	a0,0(s2)
ffffffffc0202e24:	6585                	lui	a1,0x1
ffffffffc0202e26:	b65ff0ef          	jal	ra,ffffffffc020298a <page_remove>
    assert(page_ref(p1) == 0);
ffffffffc0202e2a:	000a2783          	lw	a5,0(s4)
ffffffffc0202e2e:	52079a63          	bnez	a5,ffffffffc0203362 <pmm_init+0x846>
    assert(page_ref(p2) == 0);
ffffffffc0202e32:	000c2783          	lw	a5,0(s8)
ffffffffc0202e36:	50079663          	bnez	a5,ffffffffc0203342 <pmm_init+0x826>

    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc0202e3a:	00093a03          	ld	s4,0(s2)
    if (PPN(pa) >= npage)
ffffffffc0202e3e:	608c                	ld	a1,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202e40:	000a3683          	ld	a3,0(s4)
ffffffffc0202e44:	068a                	slli	a3,a3,0x2
ffffffffc0202e46:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage)
ffffffffc0202e48:	42b6fd63          	bgeu	a3,a1,ffffffffc0203282 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202e4c:	000bb503          	ld	a0,0(s7)
ffffffffc0202e50:	96d6                	add	a3,a3,s5
ffffffffc0202e52:	069a                	slli	a3,a3,0x6
    return page->ref;
ffffffffc0202e54:	00d507b3          	add	a5,a0,a3
ffffffffc0202e58:	439c                	lw	a5,0(a5)
ffffffffc0202e5a:	4d979463          	bne	a5,s9,ffffffffc0203322 <pmm_init+0x806>
    return page - pages + nbase;
ffffffffc0202e5e:	8699                	srai	a3,a3,0x6
ffffffffc0202e60:	00080637          	lui	a2,0x80
ffffffffc0202e64:	96b2                	add	a3,a3,a2
    return KADDR(page2pa(page));
ffffffffc0202e66:	00c69713          	slli	a4,a3,0xc
ffffffffc0202e6a:	8331                	srli	a4,a4,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0202e6c:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202e6e:	48b77e63          	bgeu	a4,a1,ffffffffc020330a <pmm_init+0x7ee>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
    free_page(pde2page(pd0[0]));
ffffffffc0202e72:	0009b703          	ld	a4,0(s3)
ffffffffc0202e76:	96ba                	add	a3,a3,a4
    return pa2page(PDE_ADDR(pde));
ffffffffc0202e78:	629c                	ld	a5,0(a3)
ffffffffc0202e7a:	078a                	slli	a5,a5,0x2
ffffffffc0202e7c:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202e7e:	40b7f263          	bgeu	a5,a1,ffffffffc0203282 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202e82:	8f91                	sub	a5,a5,a2
ffffffffc0202e84:	079a                	slli	a5,a5,0x6
ffffffffc0202e86:	953e                	add	a0,a0,a5
ffffffffc0202e88:	100027f3          	csrr	a5,sstatus
ffffffffc0202e8c:	8b89                	andi	a5,a5,2
ffffffffc0202e8e:	30079963          	bnez	a5,ffffffffc02031a0 <pmm_init+0x684>
        pmm_manager->free_pages(base, n);
ffffffffc0202e92:	000b3783          	ld	a5,0(s6)
ffffffffc0202e96:	4585                	li	a1,1
ffffffffc0202e98:	739c                	ld	a5,32(a5)
ffffffffc0202e9a:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202e9c:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage)
ffffffffc0202ea0:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202ea2:	078a                	slli	a5,a5,0x2
ffffffffc0202ea4:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202ea6:	3ce7fe63          	bgeu	a5,a4,ffffffffc0203282 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202eaa:	000bb503          	ld	a0,0(s7)
ffffffffc0202eae:	fff80737          	lui	a4,0xfff80
ffffffffc0202eb2:	97ba                	add	a5,a5,a4
ffffffffc0202eb4:	079a                	slli	a5,a5,0x6
ffffffffc0202eb6:	953e                	add	a0,a0,a5
ffffffffc0202eb8:	100027f3          	csrr	a5,sstatus
ffffffffc0202ebc:	8b89                	andi	a5,a5,2
ffffffffc0202ebe:	2c079563          	bnez	a5,ffffffffc0203188 <pmm_init+0x66c>
ffffffffc0202ec2:	000b3783          	ld	a5,0(s6)
ffffffffc0202ec6:	4585                	li	a1,1
ffffffffc0202ec8:	739c                	ld	a5,32(a5)
ffffffffc0202eca:	9782                	jalr	a5
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc0202ecc:	00093783          	ld	a5,0(s2)
ffffffffc0202ed0:	0007b023          	sd	zero,0(a5) # fffffffffffff000 <end+0x3fd3f3e4>
    asm volatile("sfence.vma");
ffffffffc0202ed4:	12000073          	sfence.vma
ffffffffc0202ed8:	100027f3          	csrr	a5,sstatus
ffffffffc0202edc:	8b89                	andi	a5,a5,2
ffffffffc0202ede:	28079b63          	bnez	a5,ffffffffc0203174 <pmm_init+0x658>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202ee2:	000b3783          	ld	a5,0(s6)
ffffffffc0202ee6:	779c                	ld	a5,40(a5)
ffffffffc0202ee8:	9782                	jalr	a5
ffffffffc0202eea:	8a2a                	mv	s4,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc0202eec:	4b441b63          	bne	s0,s4,ffffffffc02033a2 <pmm_init+0x886>

    cprintf("check_pgdir() succeeded!\n");
ffffffffc0202ef0:	00004517          	auipc	a0,0x4
ffffffffc0202ef4:	d7850513          	addi	a0,a0,-648 # ffffffffc0206c68 <default_pmm_manager+0x508>
ffffffffc0202ef8:	a9cfd0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc0202efc:	100027f3          	csrr	a5,sstatus
ffffffffc0202f00:	8b89                	andi	a5,a5,2
ffffffffc0202f02:	24079f63          	bnez	a5,ffffffffc0203160 <pmm_init+0x644>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202f06:	000b3783          	ld	a5,0(s6)
ffffffffc0202f0a:	779c                	ld	a5,40(a5)
ffffffffc0202f0c:	9782                	jalr	a5
ffffffffc0202f0e:	8c2a                	mv	s8,a0
    pte_t *ptep;
    int i;

    nr_free_store = nr_free_pages();

    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202f10:	6098                	ld	a4,0(s1)
ffffffffc0202f12:	c0200437          	lui	s0,0xc0200
    {
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202f16:	7afd                	lui	s5,0xfffff
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202f18:	00c71793          	slli	a5,a4,0xc
ffffffffc0202f1c:	6a05                	lui	s4,0x1
ffffffffc0202f1e:	02f47c63          	bgeu	s0,a5,ffffffffc0202f56 <pmm_init+0x43a>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202f22:	00c45793          	srli	a5,s0,0xc
ffffffffc0202f26:	00093503          	ld	a0,0(s2)
ffffffffc0202f2a:	2ee7ff63          	bgeu	a5,a4,ffffffffc0203228 <pmm_init+0x70c>
ffffffffc0202f2e:	0009b583          	ld	a1,0(s3)
ffffffffc0202f32:	4601                	li	a2,0
ffffffffc0202f34:	95a2                	add	a1,a1,s0
ffffffffc0202f36:	a96ff0ef          	jal	ra,ffffffffc02021cc <get_pte>
ffffffffc0202f3a:	32050463          	beqz	a0,ffffffffc0203262 <pmm_init+0x746>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202f3e:	611c                	ld	a5,0(a0)
ffffffffc0202f40:	078a                	slli	a5,a5,0x2
ffffffffc0202f42:	0157f7b3          	and	a5,a5,s5
ffffffffc0202f46:	2e879e63          	bne	a5,s0,ffffffffc0203242 <pmm_init+0x726>
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202f4a:	6098                	ld	a4,0(s1)
ffffffffc0202f4c:	9452                	add	s0,s0,s4
ffffffffc0202f4e:	00c71793          	slli	a5,a4,0xc
ffffffffc0202f52:	fcf468e3          	bltu	s0,a5,ffffffffc0202f22 <pmm_init+0x406>
    }

    assert(boot_pgdir_va[0] == 0);
ffffffffc0202f56:	00093783          	ld	a5,0(s2)
ffffffffc0202f5a:	639c                	ld	a5,0(a5)
ffffffffc0202f5c:	42079363          	bnez	a5,ffffffffc0203382 <pmm_init+0x866>
ffffffffc0202f60:	100027f3          	csrr	a5,sstatus
ffffffffc0202f64:	8b89                	andi	a5,a5,2
ffffffffc0202f66:	24079963          	bnez	a5,ffffffffc02031b8 <pmm_init+0x69c>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202f6a:	000b3783          	ld	a5,0(s6)
ffffffffc0202f6e:	4505                	li	a0,1
ffffffffc0202f70:	6f9c                	ld	a5,24(a5)
ffffffffc0202f72:	9782                	jalr	a5
ffffffffc0202f74:	8a2a                	mv	s4,a0

    struct Page *p;
    p = alloc_page();
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0202f76:	00093503          	ld	a0,0(s2)
ffffffffc0202f7a:	4699                	li	a3,6
ffffffffc0202f7c:	10000613          	li	a2,256
ffffffffc0202f80:	85d2                	mv	a1,s4
ffffffffc0202f82:	aa5ff0ef          	jal	ra,ffffffffc0202a26 <page_insert>
ffffffffc0202f86:	44051e63          	bnez	a0,ffffffffc02033e2 <pmm_init+0x8c6>
    assert(page_ref(p) == 1);
ffffffffc0202f8a:	000a2703          	lw	a4,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8bd0>
ffffffffc0202f8e:	4785                	li	a5,1
ffffffffc0202f90:	42f71963          	bne	a4,a5,ffffffffc02033c2 <pmm_init+0x8a6>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc0202f94:	00093503          	ld	a0,0(s2)
ffffffffc0202f98:	6405                	lui	s0,0x1
ffffffffc0202f9a:	4699                	li	a3,6
ffffffffc0202f9c:	10040613          	addi	a2,s0,256 # 1100 <_binary_obj___user_faultread_out_size-0x8ad0>
ffffffffc0202fa0:	85d2                	mv	a1,s4
ffffffffc0202fa2:	a85ff0ef          	jal	ra,ffffffffc0202a26 <page_insert>
ffffffffc0202fa6:	72051363          	bnez	a0,ffffffffc02036cc <pmm_init+0xbb0>
    assert(page_ref(p) == 2);
ffffffffc0202faa:	000a2703          	lw	a4,0(s4)
ffffffffc0202fae:	4789                	li	a5,2
ffffffffc0202fb0:	6ef71e63          	bne	a4,a5,ffffffffc02036ac <pmm_init+0xb90>

    const char *str = "ucore: Hello world!!";
    strcpy((void *)0x100, str);
ffffffffc0202fb4:	00004597          	auipc	a1,0x4
ffffffffc0202fb8:	dfc58593          	addi	a1,a1,-516 # ffffffffc0206db0 <default_pmm_manager+0x650>
ffffffffc0202fbc:	10000513          	li	a0,256
ffffffffc0202fc0:	011020ef          	jal	ra,ffffffffc02057d0 <strcpy>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc0202fc4:	10040593          	addi	a1,s0,256
ffffffffc0202fc8:	10000513          	li	a0,256
ffffffffc0202fcc:	017020ef          	jal	ra,ffffffffc02057e2 <strcmp>
ffffffffc0202fd0:	6a051e63          	bnez	a0,ffffffffc020368c <pmm_init+0xb70>
    return page - pages + nbase;
ffffffffc0202fd4:	000bb683          	ld	a3,0(s7)
ffffffffc0202fd8:	00080737          	lui	a4,0x80
    return KADDR(page2pa(page));
ffffffffc0202fdc:	547d                	li	s0,-1
    return page - pages + nbase;
ffffffffc0202fde:	40da06b3          	sub	a3,s4,a3
ffffffffc0202fe2:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0202fe4:	609c                	ld	a5,0(s1)
    return page - pages + nbase;
ffffffffc0202fe6:	96ba                	add	a3,a3,a4
    return KADDR(page2pa(page));
ffffffffc0202fe8:	8031                	srli	s0,s0,0xc
ffffffffc0202fea:	0086f733          	and	a4,a3,s0
    return page2ppn(page) << PGSHIFT;
ffffffffc0202fee:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202ff0:	30f77d63          	bgeu	a4,a5,ffffffffc020330a <pmm_init+0x7ee>

    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0202ff4:	0009b783          	ld	a5,0(s3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202ff8:	10000513          	li	a0,256
    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0202ffc:	96be                	add	a3,a3,a5
ffffffffc0202ffe:	10068023          	sb	zero,256(a3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc0203002:	798020ef          	jal	ra,ffffffffc020579a <strlen>
ffffffffc0203006:	66051363          	bnez	a0,ffffffffc020366c <pmm_init+0xb50>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
ffffffffc020300a:	00093a83          	ld	s5,0(s2)
    if (PPN(pa) >= npage)
ffffffffc020300e:	609c                	ld	a5,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0203010:	000ab683          	ld	a3,0(s5) # fffffffffffff000 <end+0x3fd3f3e4>
ffffffffc0203014:	068a                	slli	a3,a3,0x2
ffffffffc0203016:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage)
ffffffffc0203018:	26f6f563          	bgeu	a3,a5,ffffffffc0203282 <pmm_init+0x766>
    return KADDR(page2pa(page));
ffffffffc020301c:	8c75                	and	s0,s0,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc020301e:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0203020:	2ef47563          	bgeu	s0,a5,ffffffffc020330a <pmm_init+0x7ee>
ffffffffc0203024:	0009b403          	ld	s0,0(s3)
ffffffffc0203028:	9436                	add	s0,s0,a3
ffffffffc020302a:	100027f3          	csrr	a5,sstatus
ffffffffc020302e:	8b89                	andi	a5,a5,2
ffffffffc0203030:	1e079163          	bnez	a5,ffffffffc0203212 <pmm_init+0x6f6>
        pmm_manager->free_pages(base, n);
ffffffffc0203034:	000b3783          	ld	a5,0(s6)
ffffffffc0203038:	4585                	li	a1,1
ffffffffc020303a:	8552                	mv	a0,s4
ffffffffc020303c:	739c                	ld	a5,32(a5)
ffffffffc020303e:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0203040:	601c                	ld	a5,0(s0)
    if (PPN(pa) >= npage)
ffffffffc0203042:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0203044:	078a                	slli	a5,a5,0x2
ffffffffc0203046:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0203048:	22e7fd63          	bgeu	a5,a4,ffffffffc0203282 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc020304c:	000bb503          	ld	a0,0(s7)
ffffffffc0203050:	fff80737          	lui	a4,0xfff80
ffffffffc0203054:	97ba                	add	a5,a5,a4
ffffffffc0203056:	079a                	slli	a5,a5,0x6
ffffffffc0203058:	953e                	add	a0,a0,a5
ffffffffc020305a:	100027f3          	csrr	a5,sstatus
ffffffffc020305e:	8b89                	andi	a5,a5,2
ffffffffc0203060:	18079d63          	bnez	a5,ffffffffc02031fa <pmm_init+0x6de>
ffffffffc0203064:	000b3783          	ld	a5,0(s6)
ffffffffc0203068:	4585                	li	a1,1
ffffffffc020306a:	739c                	ld	a5,32(a5)
ffffffffc020306c:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc020306e:	000ab783          	ld	a5,0(s5)
    if (PPN(pa) >= npage)
ffffffffc0203072:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0203074:	078a                	slli	a5,a5,0x2
ffffffffc0203076:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0203078:	20e7f563          	bgeu	a5,a4,ffffffffc0203282 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc020307c:	000bb503          	ld	a0,0(s7)
ffffffffc0203080:	fff80737          	lui	a4,0xfff80
ffffffffc0203084:	97ba                	add	a5,a5,a4
ffffffffc0203086:	079a                	slli	a5,a5,0x6
ffffffffc0203088:	953e                	add	a0,a0,a5
ffffffffc020308a:	100027f3          	csrr	a5,sstatus
ffffffffc020308e:	8b89                	andi	a5,a5,2
ffffffffc0203090:	14079963          	bnez	a5,ffffffffc02031e2 <pmm_init+0x6c6>
ffffffffc0203094:	000b3783          	ld	a5,0(s6)
ffffffffc0203098:	4585                	li	a1,1
ffffffffc020309a:	739c                	ld	a5,32(a5)
ffffffffc020309c:	9782                	jalr	a5
    free_page(p);
    free_page(pde2page(pd0[0]));
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc020309e:	00093783          	ld	a5,0(s2)
ffffffffc02030a2:	0007b023          	sd	zero,0(a5)
    asm volatile("sfence.vma");
ffffffffc02030a6:	12000073          	sfence.vma
ffffffffc02030aa:	100027f3          	csrr	a5,sstatus
ffffffffc02030ae:	8b89                	andi	a5,a5,2
ffffffffc02030b0:	10079f63          	bnez	a5,ffffffffc02031ce <pmm_init+0x6b2>
        ret = pmm_manager->nr_free_pages();
ffffffffc02030b4:	000b3783          	ld	a5,0(s6)
ffffffffc02030b8:	779c                	ld	a5,40(a5)
ffffffffc02030ba:	9782                	jalr	a5
ffffffffc02030bc:	842a                	mv	s0,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc02030be:	4c8c1e63          	bne	s8,s0,ffffffffc020359a <pmm_init+0xa7e>

    cprintf("check_boot_pgdir() succeeded!\n");
ffffffffc02030c2:	00004517          	auipc	a0,0x4
ffffffffc02030c6:	d6650513          	addi	a0,a0,-666 # ffffffffc0206e28 <default_pmm_manager+0x6c8>
ffffffffc02030ca:	8cafd0ef          	jal	ra,ffffffffc0200194 <cprintf>
}
ffffffffc02030ce:	7406                	ld	s0,96(sp)
ffffffffc02030d0:	70a6                	ld	ra,104(sp)
ffffffffc02030d2:	64e6                	ld	s1,88(sp)
ffffffffc02030d4:	6946                	ld	s2,80(sp)
ffffffffc02030d6:	69a6                	ld	s3,72(sp)
ffffffffc02030d8:	6a06                	ld	s4,64(sp)
ffffffffc02030da:	7ae2                	ld	s5,56(sp)
ffffffffc02030dc:	7b42                	ld	s6,48(sp)
ffffffffc02030de:	7ba2                	ld	s7,40(sp)
ffffffffc02030e0:	7c02                	ld	s8,32(sp)
ffffffffc02030e2:	6ce2                	ld	s9,24(sp)
ffffffffc02030e4:	6165                	addi	sp,sp,112
    kmalloc_init();
ffffffffc02030e6:	e2dfe06f          	j	ffffffffc0201f12 <kmalloc_init>
    npage = maxpa / PGSIZE;
ffffffffc02030ea:	c80007b7          	lui	a5,0xc8000
ffffffffc02030ee:	bc7d                	j	ffffffffc0202bac <pmm_init+0x90>
        intr_disable();
ffffffffc02030f0:	8c5fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc02030f4:	000b3783          	ld	a5,0(s6)
ffffffffc02030f8:	4505                	li	a0,1
ffffffffc02030fa:	6f9c                	ld	a5,24(a5)
ffffffffc02030fc:	9782                	jalr	a5
ffffffffc02030fe:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc0203100:	8affd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0203104:	b9a9                	j	ffffffffc0202d5e <pmm_init+0x242>
        intr_disable();
ffffffffc0203106:	8affd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc020310a:	000b3783          	ld	a5,0(s6)
ffffffffc020310e:	4505                	li	a0,1
ffffffffc0203110:	6f9c                	ld	a5,24(a5)
ffffffffc0203112:	9782                	jalr	a5
ffffffffc0203114:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0203116:	899fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc020311a:	b645                	j	ffffffffc0202cba <pmm_init+0x19e>
        intr_disable();
ffffffffc020311c:	899fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0203120:	000b3783          	ld	a5,0(s6)
ffffffffc0203124:	779c                	ld	a5,40(a5)
ffffffffc0203126:	9782                	jalr	a5
ffffffffc0203128:	842a                	mv	s0,a0
        intr_enable();
ffffffffc020312a:	885fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc020312e:	b6b9                	j	ffffffffc0202c7c <pmm_init+0x160>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0203130:	6705                	lui	a4,0x1
ffffffffc0203132:	177d                	addi	a4,a4,-1
ffffffffc0203134:	96ba                	add	a3,a3,a4
ffffffffc0203136:	8ff5                	and	a5,a5,a3
    if (PPN(pa) >= npage)
ffffffffc0203138:	00c7d713          	srli	a4,a5,0xc
ffffffffc020313c:	14a77363          	bgeu	a4,a0,ffffffffc0203282 <pmm_init+0x766>
    pmm_manager->init_memmap(base, n);
ffffffffc0203140:	000b3683          	ld	a3,0(s6)
    return &pages[PPN(pa) - nbase];
ffffffffc0203144:	fff80537          	lui	a0,0xfff80
ffffffffc0203148:	972a                	add	a4,a4,a0
ffffffffc020314a:	6a94                	ld	a3,16(a3)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc020314c:	8c1d                	sub	s0,s0,a5
ffffffffc020314e:	00671513          	slli	a0,a4,0x6
    pmm_manager->init_memmap(base, n);
ffffffffc0203152:	00c45593          	srli	a1,s0,0xc
ffffffffc0203156:	9532                	add	a0,a0,a2
ffffffffc0203158:	9682                	jalr	a3
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc020315a:	0009b583          	ld	a1,0(s3)
}
ffffffffc020315e:	b4c1                	j	ffffffffc0202c1e <pmm_init+0x102>
        intr_disable();
ffffffffc0203160:	855fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0203164:	000b3783          	ld	a5,0(s6)
ffffffffc0203168:	779c                	ld	a5,40(a5)
ffffffffc020316a:	9782                	jalr	a5
ffffffffc020316c:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc020316e:	841fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0203172:	bb79                	j	ffffffffc0202f10 <pmm_init+0x3f4>
        intr_disable();
ffffffffc0203174:	841fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0203178:	000b3783          	ld	a5,0(s6)
ffffffffc020317c:	779c                	ld	a5,40(a5)
ffffffffc020317e:	9782                	jalr	a5
ffffffffc0203180:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0203182:	82dfd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0203186:	b39d                	j	ffffffffc0202eec <pmm_init+0x3d0>
ffffffffc0203188:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc020318a:	82bfd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc020318e:	000b3783          	ld	a5,0(s6)
ffffffffc0203192:	6522                	ld	a0,8(sp)
ffffffffc0203194:	4585                	li	a1,1
ffffffffc0203196:	739c                	ld	a5,32(a5)
ffffffffc0203198:	9782                	jalr	a5
        intr_enable();
ffffffffc020319a:	815fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc020319e:	b33d                	j	ffffffffc0202ecc <pmm_init+0x3b0>
ffffffffc02031a0:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc02031a2:	813fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc02031a6:	000b3783          	ld	a5,0(s6)
ffffffffc02031aa:	6522                	ld	a0,8(sp)
ffffffffc02031ac:	4585                	li	a1,1
ffffffffc02031ae:	739c                	ld	a5,32(a5)
ffffffffc02031b0:	9782                	jalr	a5
        intr_enable();
ffffffffc02031b2:	ffcfd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02031b6:	b1dd                	j	ffffffffc0202e9c <pmm_init+0x380>
        intr_disable();
ffffffffc02031b8:	ffcfd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc02031bc:	000b3783          	ld	a5,0(s6)
ffffffffc02031c0:	4505                	li	a0,1
ffffffffc02031c2:	6f9c                	ld	a5,24(a5)
ffffffffc02031c4:	9782                	jalr	a5
ffffffffc02031c6:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc02031c8:	fe6fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02031cc:	b36d                	j	ffffffffc0202f76 <pmm_init+0x45a>
        intr_disable();
ffffffffc02031ce:	fe6fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc02031d2:	000b3783          	ld	a5,0(s6)
ffffffffc02031d6:	779c                	ld	a5,40(a5)
ffffffffc02031d8:	9782                	jalr	a5
ffffffffc02031da:	842a                	mv	s0,a0
        intr_enable();
ffffffffc02031dc:	fd2fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02031e0:	bdf9                	j	ffffffffc02030be <pmm_init+0x5a2>
ffffffffc02031e2:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc02031e4:	fd0fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc02031e8:	000b3783          	ld	a5,0(s6)
ffffffffc02031ec:	6522                	ld	a0,8(sp)
ffffffffc02031ee:	4585                	li	a1,1
ffffffffc02031f0:	739c                	ld	a5,32(a5)
ffffffffc02031f2:	9782                	jalr	a5
        intr_enable();
ffffffffc02031f4:	fbafd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02031f8:	b55d                	j	ffffffffc020309e <pmm_init+0x582>
ffffffffc02031fa:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc02031fc:	fb8fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0203200:	000b3783          	ld	a5,0(s6)
ffffffffc0203204:	6522                	ld	a0,8(sp)
ffffffffc0203206:	4585                	li	a1,1
ffffffffc0203208:	739c                	ld	a5,32(a5)
ffffffffc020320a:	9782                	jalr	a5
        intr_enable();
ffffffffc020320c:	fa2fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0203210:	bdb9                	j	ffffffffc020306e <pmm_init+0x552>
        intr_disable();
ffffffffc0203212:	fa2fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0203216:	000b3783          	ld	a5,0(s6)
ffffffffc020321a:	4585                	li	a1,1
ffffffffc020321c:	8552                	mv	a0,s4
ffffffffc020321e:	739c                	ld	a5,32(a5)
ffffffffc0203220:	9782                	jalr	a5
        intr_enable();
ffffffffc0203222:	f8cfd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0203226:	bd29                	j	ffffffffc0203040 <pmm_init+0x524>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0203228:	86a2                	mv	a3,s0
ffffffffc020322a:	00003617          	auipc	a2,0x3
ffffffffc020322e:	e8e60613          	addi	a2,a2,-370 # ffffffffc02060b8 <commands+0x5e8>
ffffffffc0203232:	24f00593          	li	a1,591
ffffffffc0203236:	00003517          	auipc	a0,0x3
ffffffffc020323a:	62250513          	addi	a0,a0,1570 # ffffffffc0206858 <default_pmm_manager+0xf8>
ffffffffc020323e:	a50fd0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0203242:	00004697          	auipc	a3,0x4
ffffffffc0203246:	a8668693          	addi	a3,a3,-1402 # ffffffffc0206cc8 <default_pmm_manager+0x568>
ffffffffc020324a:	00003617          	auipc	a2,0x3
ffffffffc020324e:	16660613          	addi	a2,a2,358 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc0203252:	25000593          	li	a1,592
ffffffffc0203256:	00003517          	auipc	a0,0x3
ffffffffc020325a:	60250513          	addi	a0,a0,1538 # ffffffffc0206858 <default_pmm_manager+0xf8>
ffffffffc020325e:	a30fd0ef          	jal	ra,ffffffffc020048e <__panic>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0203262:	00004697          	auipc	a3,0x4
ffffffffc0203266:	a2668693          	addi	a3,a3,-1498 # ffffffffc0206c88 <default_pmm_manager+0x528>
ffffffffc020326a:	00003617          	auipc	a2,0x3
ffffffffc020326e:	14660613          	addi	a2,a2,326 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc0203272:	24f00593          	li	a1,591
ffffffffc0203276:	00003517          	auipc	a0,0x3
ffffffffc020327a:	5e250513          	addi	a0,a0,1506 # ffffffffc0206858 <default_pmm_manager+0xf8>
ffffffffc020327e:	a10fd0ef          	jal	ra,ffffffffc020048e <__panic>
ffffffffc0203282:	e5bfe0ef          	jal	ra,ffffffffc02020dc <pa2page.part.0>
ffffffffc0203286:	e73fe0ef          	jal	ra,ffffffffc02020f8 <pte2page.part.0>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc020328a:	00003697          	auipc	a3,0x3
ffffffffc020328e:	7f668693          	addi	a3,a3,2038 # ffffffffc0206a80 <default_pmm_manager+0x320>
ffffffffc0203292:	00003617          	auipc	a2,0x3
ffffffffc0203296:	11e60613          	addi	a2,a2,286 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc020329a:	21f00593          	li	a1,543
ffffffffc020329e:	00003517          	auipc	a0,0x3
ffffffffc02032a2:	5ba50513          	addi	a0,a0,1466 # ffffffffc0206858 <default_pmm_manager+0xf8>
ffffffffc02032a6:	9e8fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc02032aa:	00003697          	auipc	a3,0x3
ffffffffc02032ae:	71668693          	addi	a3,a3,1814 # ffffffffc02069c0 <default_pmm_manager+0x260>
ffffffffc02032b2:	00003617          	auipc	a2,0x3
ffffffffc02032b6:	0fe60613          	addi	a2,a2,254 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc02032ba:	21200593          	li	a1,530
ffffffffc02032be:	00003517          	auipc	a0,0x3
ffffffffc02032c2:	59a50513          	addi	a0,a0,1434 # ffffffffc0206858 <default_pmm_manager+0xf8>
ffffffffc02032c6:	9c8fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc02032ca:	00003697          	auipc	a3,0x3
ffffffffc02032ce:	6b668693          	addi	a3,a3,1718 # ffffffffc0206980 <default_pmm_manager+0x220>
ffffffffc02032d2:	00003617          	auipc	a2,0x3
ffffffffc02032d6:	0de60613          	addi	a2,a2,222 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc02032da:	21100593          	li	a1,529
ffffffffc02032de:	00003517          	auipc	a0,0x3
ffffffffc02032e2:	57a50513          	addi	a0,a0,1402 # ffffffffc0206858 <default_pmm_manager+0xf8>
ffffffffc02032e6:	9a8fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(npage <= KERNTOP / PGSIZE);
ffffffffc02032ea:	00003697          	auipc	a3,0x3
ffffffffc02032ee:	67668693          	addi	a3,a3,1654 # ffffffffc0206960 <default_pmm_manager+0x200>
ffffffffc02032f2:	00003617          	auipc	a2,0x3
ffffffffc02032f6:	0be60613          	addi	a2,a2,190 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc02032fa:	21000593          	li	a1,528
ffffffffc02032fe:	00003517          	auipc	a0,0x3
ffffffffc0203302:	55a50513          	addi	a0,a0,1370 # ffffffffc0206858 <default_pmm_manager+0xf8>
ffffffffc0203306:	988fd0ef          	jal	ra,ffffffffc020048e <__panic>
    return KADDR(page2pa(page));
ffffffffc020330a:	00003617          	auipc	a2,0x3
ffffffffc020330e:	dae60613          	addi	a2,a2,-594 # ffffffffc02060b8 <commands+0x5e8>
ffffffffc0203312:	07100593          	li	a1,113
ffffffffc0203316:	00003517          	auipc	a0,0x3
ffffffffc020331a:	d9250513          	addi	a0,a0,-622 # ffffffffc02060a8 <commands+0x5d8>
ffffffffc020331e:	970fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc0203322:	00004697          	auipc	a3,0x4
ffffffffc0203326:	8ee68693          	addi	a3,a3,-1810 # ffffffffc0206c10 <default_pmm_manager+0x4b0>
ffffffffc020332a:	00003617          	auipc	a2,0x3
ffffffffc020332e:	08660613          	addi	a2,a2,134 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc0203332:	23800593          	li	a1,568
ffffffffc0203336:	00003517          	auipc	a0,0x3
ffffffffc020333a:	52250513          	addi	a0,a0,1314 # ffffffffc0206858 <default_pmm_manager+0xf8>
ffffffffc020333e:	950fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0203342:	00004697          	auipc	a3,0x4
ffffffffc0203346:	88668693          	addi	a3,a3,-1914 # ffffffffc0206bc8 <default_pmm_manager+0x468>
ffffffffc020334a:	00003617          	auipc	a2,0x3
ffffffffc020334e:	06660613          	addi	a2,a2,102 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc0203352:	23600593          	li	a1,566
ffffffffc0203356:	00003517          	auipc	a0,0x3
ffffffffc020335a:	50250513          	addi	a0,a0,1282 # ffffffffc0206858 <default_pmm_manager+0xf8>
ffffffffc020335e:	930fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p1) == 0);
ffffffffc0203362:	00004697          	auipc	a3,0x4
ffffffffc0203366:	89668693          	addi	a3,a3,-1898 # ffffffffc0206bf8 <default_pmm_manager+0x498>
ffffffffc020336a:	00003617          	auipc	a2,0x3
ffffffffc020336e:	04660613          	addi	a2,a2,70 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc0203372:	23500593          	li	a1,565
ffffffffc0203376:	00003517          	auipc	a0,0x3
ffffffffc020337a:	4e250513          	addi	a0,a0,1250 # ffffffffc0206858 <default_pmm_manager+0xf8>
ffffffffc020337e:	910fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(boot_pgdir_va[0] == 0);
ffffffffc0203382:	00004697          	auipc	a3,0x4
ffffffffc0203386:	95e68693          	addi	a3,a3,-1698 # ffffffffc0206ce0 <default_pmm_manager+0x580>
ffffffffc020338a:	00003617          	auipc	a2,0x3
ffffffffc020338e:	02660613          	addi	a2,a2,38 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc0203392:	25300593          	li	a1,595
ffffffffc0203396:	00003517          	auipc	a0,0x3
ffffffffc020339a:	4c250513          	addi	a0,a0,1218 # ffffffffc0206858 <default_pmm_manager+0xf8>
ffffffffc020339e:	8f0fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc02033a2:	00004697          	auipc	a3,0x4
ffffffffc02033a6:	89e68693          	addi	a3,a3,-1890 # ffffffffc0206c40 <default_pmm_manager+0x4e0>
ffffffffc02033aa:	00003617          	auipc	a2,0x3
ffffffffc02033ae:	00660613          	addi	a2,a2,6 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc02033b2:	24000593          	li	a1,576
ffffffffc02033b6:	00003517          	auipc	a0,0x3
ffffffffc02033ba:	4a250513          	addi	a0,a0,1186 # ffffffffc0206858 <default_pmm_manager+0xf8>
ffffffffc02033be:	8d0fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p) == 1);
ffffffffc02033c2:	00004697          	auipc	a3,0x4
ffffffffc02033c6:	97668693          	addi	a3,a3,-1674 # ffffffffc0206d38 <default_pmm_manager+0x5d8>
ffffffffc02033ca:	00003617          	auipc	a2,0x3
ffffffffc02033ce:	fe660613          	addi	a2,a2,-26 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc02033d2:	25800593          	li	a1,600
ffffffffc02033d6:	00003517          	auipc	a0,0x3
ffffffffc02033da:	48250513          	addi	a0,a0,1154 # ffffffffc0206858 <default_pmm_manager+0xf8>
ffffffffc02033de:	8b0fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc02033e2:	00004697          	auipc	a3,0x4
ffffffffc02033e6:	91668693          	addi	a3,a3,-1770 # ffffffffc0206cf8 <default_pmm_manager+0x598>
ffffffffc02033ea:	00003617          	auipc	a2,0x3
ffffffffc02033ee:	fc660613          	addi	a2,a2,-58 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc02033f2:	25700593          	li	a1,599
ffffffffc02033f6:	00003517          	auipc	a0,0x3
ffffffffc02033fa:	46250513          	addi	a0,a0,1122 # ffffffffc0206858 <default_pmm_manager+0xf8>
ffffffffc02033fe:	890fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0203402:	00003697          	auipc	a3,0x3
ffffffffc0203406:	7c668693          	addi	a3,a3,1990 # ffffffffc0206bc8 <default_pmm_manager+0x468>
ffffffffc020340a:	00003617          	auipc	a2,0x3
ffffffffc020340e:	fa660613          	addi	a2,a2,-90 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc0203412:	23200593          	li	a1,562
ffffffffc0203416:	00003517          	auipc	a0,0x3
ffffffffc020341a:	44250513          	addi	a0,a0,1090 # ffffffffc0206858 <default_pmm_manager+0xf8>
ffffffffc020341e:	870fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p1) == 1);
ffffffffc0203422:	00003697          	auipc	a3,0x3
ffffffffc0203426:	64668693          	addi	a3,a3,1606 # ffffffffc0206a68 <default_pmm_manager+0x308>
ffffffffc020342a:	00003617          	auipc	a2,0x3
ffffffffc020342e:	f8660613          	addi	a2,a2,-122 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc0203432:	23100593          	li	a1,561
ffffffffc0203436:	00003517          	auipc	a0,0x3
ffffffffc020343a:	42250513          	addi	a0,a0,1058 # ffffffffc0206858 <default_pmm_manager+0xf8>
ffffffffc020343e:	850fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((*ptep & PTE_U) == 0);
ffffffffc0203442:	00003697          	auipc	a3,0x3
ffffffffc0203446:	79e68693          	addi	a3,a3,1950 # ffffffffc0206be0 <default_pmm_manager+0x480>
ffffffffc020344a:	00003617          	auipc	a2,0x3
ffffffffc020344e:	f6660613          	addi	a2,a2,-154 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc0203452:	22e00593          	li	a1,558
ffffffffc0203456:	00003517          	auipc	a0,0x3
ffffffffc020345a:	40250513          	addi	a0,a0,1026 # ffffffffc0206858 <default_pmm_manager+0xf8>
ffffffffc020345e:	830fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc0203462:	00003697          	auipc	a3,0x3
ffffffffc0203466:	5ee68693          	addi	a3,a3,1518 # ffffffffc0206a50 <default_pmm_manager+0x2f0>
ffffffffc020346a:	00003617          	auipc	a2,0x3
ffffffffc020346e:	f4660613          	addi	a2,a2,-186 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc0203472:	22d00593          	li	a1,557
ffffffffc0203476:	00003517          	auipc	a0,0x3
ffffffffc020347a:	3e250513          	addi	a0,a0,994 # ffffffffc0206858 <default_pmm_manager+0xf8>
ffffffffc020347e:	810fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0203482:	00003697          	auipc	a3,0x3
ffffffffc0203486:	66e68693          	addi	a3,a3,1646 # ffffffffc0206af0 <default_pmm_manager+0x390>
ffffffffc020348a:	00003617          	auipc	a2,0x3
ffffffffc020348e:	f2660613          	addi	a2,a2,-218 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc0203492:	22c00593          	li	a1,556
ffffffffc0203496:	00003517          	auipc	a0,0x3
ffffffffc020349a:	3c250513          	addi	a0,a0,962 # ffffffffc0206858 <default_pmm_manager+0xf8>
ffffffffc020349e:	ff1fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p2) == 0);
ffffffffc02034a2:	00003697          	auipc	a3,0x3
ffffffffc02034a6:	72668693          	addi	a3,a3,1830 # ffffffffc0206bc8 <default_pmm_manager+0x468>
ffffffffc02034aa:	00003617          	auipc	a2,0x3
ffffffffc02034ae:	f0660613          	addi	a2,a2,-250 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc02034b2:	22b00593          	li	a1,555
ffffffffc02034b6:	00003517          	auipc	a0,0x3
ffffffffc02034ba:	3a250513          	addi	a0,a0,930 # ffffffffc0206858 <default_pmm_manager+0xf8>
ffffffffc02034be:	fd1fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p1) == 2);
ffffffffc02034c2:	00003697          	auipc	a3,0x3
ffffffffc02034c6:	6ee68693          	addi	a3,a3,1774 # ffffffffc0206bb0 <default_pmm_manager+0x450>
ffffffffc02034ca:	00003617          	auipc	a2,0x3
ffffffffc02034ce:	ee660613          	addi	a2,a2,-282 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc02034d2:	22a00593          	li	a1,554
ffffffffc02034d6:	00003517          	auipc	a0,0x3
ffffffffc02034da:	38250513          	addi	a0,a0,898 # ffffffffc0206858 <default_pmm_manager+0xf8>
ffffffffc02034de:	fb1fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc02034e2:	00003697          	auipc	a3,0x3
ffffffffc02034e6:	69e68693          	addi	a3,a3,1694 # ffffffffc0206b80 <default_pmm_manager+0x420>
ffffffffc02034ea:	00003617          	auipc	a2,0x3
ffffffffc02034ee:	ec660613          	addi	a2,a2,-314 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc02034f2:	22900593          	li	a1,553
ffffffffc02034f6:	00003517          	auipc	a0,0x3
ffffffffc02034fa:	36250513          	addi	a0,a0,866 # ffffffffc0206858 <default_pmm_manager+0xf8>
ffffffffc02034fe:	f91fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p2) == 1);
ffffffffc0203502:	00003697          	auipc	a3,0x3
ffffffffc0203506:	66668693          	addi	a3,a3,1638 # ffffffffc0206b68 <default_pmm_manager+0x408>
ffffffffc020350a:	00003617          	auipc	a2,0x3
ffffffffc020350e:	ea660613          	addi	a2,a2,-346 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc0203512:	22700593          	li	a1,551
ffffffffc0203516:	00003517          	auipc	a0,0x3
ffffffffc020351a:	34250513          	addi	a0,a0,834 # ffffffffc0206858 <default_pmm_manager+0xf8>
ffffffffc020351e:	f71fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc0203522:	00003697          	auipc	a3,0x3
ffffffffc0203526:	62668693          	addi	a3,a3,1574 # ffffffffc0206b48 <default_pmm_manager+0x3e8>
ffffffffc020352a:	00003617          	auipc	a2,0x3
ffffffffc020352e:	e8660613          	addi	a2,a2,-378 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc0203532:	22600593          	li	a1,550
ffffffffc0203536:	00003517          	auipc	a0,0x3
ffffffffc020353a:	32250513          	addi	a0,a0,802 # ffffffffc0206858 <default_pmm_manager+0xf8>
ffffffffc020353e:	f51fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(*ptep & PTE_W);
ffffffffc0203542:	00003697          	auipc	a3,0x3
ffffffffc0203546:	5f668693          	addi	a3,a3,1526 # ffffffffc0206b38 <default_pmm_manager+0x3d8>
ffffffffc020354a:	00003617          	auipc	a2,0x3
ffffffffc020354e:	e6660613          	addi	a2,a2,-410 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc0203552:	22500593          	li	a1,549
ffffffffc0203556:	00003517          	auipc	a0,0x3
ffffffffc020355a:	30250513          	addi	a0,a0,770 # ffffffffc0206858 <default_pmm_manager+0xf8>
ffffffffc020355e:	f31fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(*ptep & PTE_U);
ffffffffc0203562:	00003697          	auipc	a3,0x3
ffffffffc0203566:	5c668693          	addi	a3,a3,1478 # ffffffffc0206b28 <default_pmm_manager+0x3c8>
ffffffffc020356a:	00003617          	auipc	a2,0x3
ffffffffc020356e:	e4660613          	addi	a2,a2,-442 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc0203572:	22400593          	li	a1,548
ffffffffc0203576:	00003517          	auipc	a0,0x3
ffffffffc020357a:	2e250513          	addi	a0,a0,738 # ffffffffc0206858 <default_pmm_manager+0xf8>
ffffffffc020357e:	f11fc0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("DTB memory info not available");
ffffffffc0203582:	00003617          	auipc	a2,0x3
ffffffffc0203586:	34660613          	addi	a2,a2,838 # ffffffffc02068c8 <default_pmm_manager+0x168>
ffffffffc020358a:	06500593          	li	a1,101
ffffffffc020358e:	00003517          	auipc	a0,0x3
ffffffffc0203592:	2ca50513          	addi	a0,a0,714 # ffffffffc0206858 <default_pmm_manager+0xf8>
ffffffffc0203596:	ef9fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc020359a:	00003697          	auipc	a3,0x3
ffffffffc020359e:	6a668693          	addi	a3,a3,1702 # ffffffffc0206c40 <default_pmm_manager+0x4e0>
ffffffffc02035a2:	00003617          	auipc	a2,0x3
ffffffffc02035a6:	e0e60613          	addi	a2,a2,-498 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc02035aa:	26a00593          	li	a1,618
ffffffffc02035ae:	00003517          	auipc	a0,0x3
ffffffffc02035b2:	2aa50513          	addi	a0,a0,682 # ffffffffc0206858 <default_pmm_manager+0xf8>
ffffffffc02035b6:	ed9fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc02035ba:	00003697          	auipc	a3,0x3
ffffffffc02035be:	53668693          	addi	a3,a3,1334 # ffffffffc0206af0 <default_pmm_manager+0x390>
ffffffffc02035c2:	00003617          	auipc	a2,0x3
ffffffffc02035c6:	dee60613          	addi	a2,a2,-530 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc02035ca:	22300593          	li	a1,547
ffffffffc02035ce:	00003517          	auipc	a0,0x3
ffffffffc02035d2:	28a50513          	addi	a0,a0,650 # ffffffffc0206858 <default_pmm_manager+0xf8>
ffffffffc02035d6:	eb9fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc02035da:	00003697          	auipc	a3,0x3
ffffffffc02035de:	4d668693          	addi	a3,a3,1238 # ffffffffc0206ab0 <default_pmm_manager+0x350>
ffffffffc02035e2:	00003617          	auipc	a2,0x3
ffffffffc02035e6:	dce60613          	addi	a2,a2,-562 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc02035ea:	22200593          	li	a1,546
ffffffffc02035ee:	00003517          	auipc	a0,0x3
ffffffffc02035f2:	26a50513          	addi	a0,a0,618 # ffffffffc0206858 <default_pmm_manager+0xf8>
ffffffffc02035f6:	e99fc0ef          	jal	ra,ffffffffc020048e <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc02035fa:	86d6                	mv	a3,s5
ffffffffc02035fc:	00003617          	auipc	a2,0x3
ffffffffc0203600:	abc60613          	addi	a2,a2,-1348 # ffffffffc02060b8 <commands+0x5e8>
ffffffffc0203604:	21e00593          	li	a1,542
ffffffffc0203608:	00003517          	auipc	a0,0x3
ffffffffc020360c:	25050513          	addi	a0,a0,592 # ffffffffc0206858 <default_pmm_manager+0xf8>
ffffffffc0203610:	e7ffc0ef          	jal	ra,ffffffffc020048e <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc0203614:	00003617          	auipc	a2,0x3
ffffffffc0203618:	aa460613          	addi	a2,a2,-1372 # ffffffffc02060b8 <commands+0x5e8>
ffffffffc020361c:	21d00593          	li	a1,541
ffffffffc0203620:	00003517          	auipc	a0,0x3
ffffffffc0203624:	23850513          	addi	a0,a0,568 # ffffffffc0206858 <default_pmm_manager+0xf8>
ffffffffc0203628:	e67fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p1) == 1);
ffffffffc020362c:	00003697          	auipc	a3,0x3
ffffffffc0203630:	43c68693          	addi	a3,a3,1084 # ffffffffc0206a68 <default_pmm_manager+0x308>
ffffffffc0203634:	00003617          	auipc	a2,0x3
ffffffffc0203638:	d7c60613          	addi	a2,a2,-644 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc020363c:	21b00593          	li	a1,539
ffffffffc0203640:	00003517          	auipc	a0,0x3
ffffffffc0203644:	21850513          	addi	a0,a0,536 # ffffffffc0206858 <default_pmm_manager+0xf8>
ffffffffc0203648:	e47fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc020364c:	00003697          	auipc	a3,0x3
ffffffffc0203650:	40468693          	addi	a3,a3,1028 # ffffffffc0206a50 <default_pmm_manager+0x2f0>
ffffffffc0203654:	00003617          	auipc	a2,0x3
ffffffffc0203658:	d5c60613          	addi	a2,a2,-676 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc020365c:	21a00593          	li	a1,538
ffffffffc0203660:	00003517          	auipc	a0,0x3
ffffffffc0203664:	1f850513          	addi	a0,a0,504 # ffffffffc0206858 <default_pmm_manager+0xf8>
ffffffffc0203668:	e27fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(strlen((const char *)0x100) == 0);
ffffffffc020366c:	00003697          	auipc	a3,0x3
ffffffffc0203670:	79468693          	addi	a3,a3,1940 # ffffffffc0206e00 <default_pmm_manager+0x6a0>
ffffffffc0203674:	00003617          	auipc	a2,0x3
ffffffffc0203678:	d3c60613          	addi	a2,a2,-708 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc020367c:	26100593          	li	a1,609
ffffffffc0203680:	00003517          	auipc	a0,0x3
ffffffffc0203684:	1d850513          	addi	a0,a0,472 # ffffffffc0206858 <default_pmm_manager+0xf8>
ffffffffc0203688:	e07fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc020368c:	00003697          	auipc	a3,0x3
ffffffffc0203690:	73c68693          	addi	a3,a3,1852 # ffffffffc0206dc8 <default_pmm_manager+0x668>
ffffffffc0203694:	00003617          	auipc	a2,0x3
ffffffffc0203698:	d1c60613          	addi	a2,a2,-740 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc020369c:	25e00593          	li	a1,606
ffffffffc02036a0:	00003517          	auipc	a0,0x3
ffffffffc02036a4:	1b850513          	addi	a0,a0,440 # ffffffffc0206858 <default_pmm_manager+0xf8>
ffffffffc02036a8:	de7fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p) == 2);
ffffffffc02036ac:	00003697          	auipc	a3,0x3
ffffffffc02036b0:	6ec68693          	addi	a3,a3,1772 # ffffffffc0206d98 <default_pmm_manager+0x638>
ffffffffc02036b4:	00003617          	auipc	a2,0x3
ffffffffc02036b8:	cfc60613          	addi	a2,a2,-772 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc02036bc:	25a00593          	li	a1,602
ffffffffc02036c0:	00003517          	auipc	a0,0x3
ffffffffc02036c4:	19850513          	addi	a0,a0,408 # ffffffffc0206858 <default_pmm_manager+0xf8>
ffffffffc02036c8:	dc7fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc02036cc:	00003697          	auipc	a3,0x3
ffffffffc02036d0:	68468693          	addi	a3,a3,1668 # ffffffffc0206d50 <default_pmm_manager+0x5f0>
ffffffffc02036d4:	00003617          	auipc	a2,0x3
ffffffffc02036d8:	cdc60613          	addi	a2,a2,-804 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc02036dc:	25900593          	li	a1,601
ffffffffc02036e0:	00003517          	auipc	a0,0x3
ffffffffc02036e4:	17850513          	addi	a0,a0,376 # ffffffffc0206858 <default_pmm_manager+0xf8>
ffffffffc02036e8:	da7fc0ef          	jal	ra,ffffffffc020048e <__panic>
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc02036ec:	00003617          	auipc	a2,0x3
ffffffffc02036f0:	11c60613          	addi	a2,a2,284 # ffffffffc0206808 <default_pmm_manager+0xa8>
ffffffffc02036f4:	0c900593          	li	a1,201
ffffffffc02036f8:	00003517          	auipc	a0,0x3
ffffffffc02036fc:	16050513          	addi	a0,a0,352 # ffffffffc0206858 <default_pmm_manager+0xf8>
ffffffffc0203700:	d8ffc0ef          	jal	ra,ffffffffc020048e <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0203704:	00003617          	auipc	a2,0x3
ffffffffc0203708:	10460613          	addi	a2,a2,260 # ffffffffc0206808 <default_pmm_manager+0xa8>
ffffffffc020370c:	08100593          	li	a1,129
ffffffffc0203710:	00003517          	auipc	a0,0x3
ffffffffc0203714:	14850513          	addi	a0,a0,328 # ffffffffc0206858 <default_pmm_manager+0xf8>
ffffffffc0203718:	d77fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc020371c:	00003697          	auipc	a3,0x3
ffffffffc0203720:	30468693          	addi	a3,a3,772 # ffffffffc0206a20 <default_pmm_manager+0x2c0>
ffffffffc0203724:	00003617          	auipc	a2,0x3
ffffffffc0203728:	c8c60613          	addi	a2,a2,-884 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc020372c:	21900593          	li	a1,537
ffffffffc0203730:	00003517          	auipc	a0,0x3
ffffffffc0203734:	12850513          	addi	a0,a0,296 # ffffffffc0206858 <default_pmm_manager+0xf8>
ffffffffc0203738:	d57fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc020373c:	00003697          	auipc	a3,0x3
ffffffffc0203740:	2b468693          	addi	a3,a3,692 # ffffffffc02069f0 <default_pmm_manager+0x290>
ffffffffc0203744:	00003617          	auipc	a2,0x3
ffffffffc0203748:	c6c60613          	addi	a2,a2,-916 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc020374c:	21600593          	li	a1,534
ffffffffc0203750:	00003517          	auipc	a0,0x3
ffffffffc0203754:	10850513          	addi	a0,a0,264 # ffffffffc0206858 <default_pmm_manager+0xf8>
ffffffffc0203758:	d37fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc020375c <pgdir_alloc_page>:
{
ffffffffc020375c:	7179                	addi	sp,sp,-48
ffffffffc020375e:	ec26                	sd	s1,24(sp)
ffffffffc0203760:	e84a                	sd	s2,16(sp)
ffffffffc0203762:	e052                	sd	s4,0(sp)
ffffffffc0203764:	f406                	sd	ra,40(sp)
ffffffffc0203766:	f022                	sd	s0,32(sp)
ffffffffc0203768:	e44e                	sd	s3,8(sp)
ffffffffc020376a:	8a2a                	mv	s4,a0
ffffffffc020376c:	84ae                	mv	s1,a1
ffffffffc020376e:	8932                	mv	s2,a2
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0203770:	100027f3          	csrr	a5,sstatus
ffffffffc0203774:	8b89                	andi	a5,a5,2
        page = pmm_manager->alloc_pages(n);
ffffffffc0203776:	000bc997          	auipc	s3,0xbc
ffffffffc020377a:	47a98993          	addi	s3,s3,1146 # ffffffffc02bfbf0 <pmm_manager>
ffffffffc020377e:	ef8d                	bnez	a5,ffffffffc02037b8 <pgdir_alloc_page+0x5c>
ffffffffc0203780:	0009b783          	ld	a5,0(s3)
ffffffffc0203784:	4505                	li	a0,1
ffffffffc0203786:	6f9c                	ld	a5,24(a5)
ffffffffc0203788:	9782                	jalr	a5
ffffffffc020378a:	842a                	mv	s0,a0
    if (page != NULL)
ffffffffc020378c:	cc09                	beqz	s0,ffffffffc02037a6 <pgdir_alloc_page+0x4a>
        if (page_insert(pgdir, page, la, perm) != 0)
ffffffffc020378e:	86ca                	mv	a3,s2
ffffffffc0203790:	8626                	mv	a2,s1
ffffffffc0203792:	85a2                	mv	a1,s0
ffffffffc0203794:	8552                	mv	a0,s4
ffffffffc0203796:	a90ff0ef          	jal	ra,ffffffffc0202a26 <page_insert>
ffffffffc020379a:	e915                	bnez	a0,ffffffffc02037ce <pgdir_alloc_page+0x72>
        assert(page_ref(page) == 1);
ffffffffc020379c:	4018                	lw	a4,0(s0)
        page->pra_vaddr = la;
ffffffffc020379e:	fc04                	sd	s1,56(s0)
        assert(page_ref(page) == 1);
ffffffffc02037a0:	4785                	li	a5,1
ffffffffc02037a2:	04f71e63          	bne	a4,a5,ffffffffc02037fe <pgdir_alloc_page+0xa2>
}
ffffffffc02037a6:	70a2                	ld	ra,40(sp)
ffffffffc02037a8:	8522                	mv	a0,s0
ffffffffc02037aa:	7402                	ld	s0,32(sp)
ffffffffc02037ac:	64e2                	ld	s1,24(sp)
ffffffffc02037ae:	6942                	ld	s2,16(sp)
ffffffffc02037b0:	69a2                	ld	s3,8(sp)
ffffffffc02037b2:	6a02                	ld	s4,0(sp)
ffffffffc02037b4:	6145                	addi	sp,sp,48
ffffffffc02037b6:	8082                	ret
        intr_disable();
ffffffffc02037b8:	9fcfd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc02037bc:	0009b783          	ld	a5,0(s3)
ffffffffc02037c0:	4505                	li	a0,1
ffffffffc02037c2:	6f9c                	ld	a5,24(a5)
ffffffffc02037c4:	9782                	jalr	a5
ffffffffc02037c6:	842a                	mv	s0,a0
        intr_enable();
ffffffffc02037c8:	9e6fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02037cc:	b7c1                	j	ffffffffc020378c <pgdir_alloc_page+0x30>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02037ce:	100027f3          	csrr	a5,sstatus
ffffffffc02037d2:	8b89                	andi	a5,a5,2
ffffffffc02037d4:	eb89                	bnez	a5,ffffffffc02037e6 <pgdir_alloc_page+0x8a>
        pmm_manager->free_pages(base, n);
ffffffffc02037d6:	0009b783          	ld	a5,0(s3)
ffffffffc02037da:	8522                	mv	a0,s0
ffffffffc02037dc:	4585                	li	a1,1
ffffffffc02037de:	739c                	ld	a5,32(a5)
            return NULL;
ffffffffc02037e0:	4401                	li	s0,0
        pmm_manager->free_pages(base, n);
ffffffffc02037e2:	9782                	jalr	a5
    if (flag)
ffffffffc02037e4:	b7c9                	j	ffffffffc02037a6 <pgdir_alloc_page+0x4a>
        intr_disable();
ffffffffc02037e6:	9cefd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc02037ea:	0009b783          	ld	a5,0(s3)
ffffffffc02037ee:	8522                	mv	a0,s0
ffffffffc02037f0:	4585                	li	a1,1
ffffffffc02037f2:	739c                	ld	a5,32(a5)
            return NULL;
ffffffffc02037f4:	4401                	li	s0,0
        pmm_manager->free_pages(base, n);
ffffffffc02037f6:	9782                	jalr	a5
        intr_enable();
ffffffffc02037f8:	9b6fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02037fc:	b76d                	j	ffffffffc02037a6 <pgdir_alloc_page+0x4a>
        assert(page_ref(page) == 1);
ffffffffc02037fe:	00003697          	auipc	a3,0x3
ffffffffc0203802:	64a68693          	addi	a3,a3,1610 # ffffffffc0206e48 <default_pmm_manager+0x6e8>
ffffffffc0203806:	00003617          	auipc	a2,0x3
ffffffffc020380a:	baa60613          	addi	a2,a2,-1110 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc020380e:	1f700593          	li	a1,503
ffffffffc0203812:	00003517          	auipc	a0,0x3
ffffffffc0203816:	04650513          	addi	a0,a0,70 # ffffffffc0206858 <default_pmm_manager+0xf8>
ffffffffc020381a:	c75fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc020381e <check_vma_overlap.part.0>:
    return vma;
}

// check_vma_overlap - check if vma1 overlaps vma2 ?
static inline void
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc020381e:	1141                	addi	sp,sp,-16
{
    assert(prev->vm_start < prev->vm_end);
    assert(prev->vm_end <= next->vm_start);
    assert(next->vm_start < next->vm_end);
ffffffffc0203820:	00003697          	auipc	a3,0x3
ffffffffc0203824:	64068693          	addi	a3,a3,1600 # ffffffffc0206e60 <default_pmm_manager+0x700>
ffffffffc0203828:	00003617          	auipc	a2,0x3
ffffffffc020382c:	b8860613          	addi	a2,a2,-1144 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc0203830:	07400593          	li	a1,116
ffffffffc0203834:	00003517          	auipc	a0,0x3
ffffffffc0203838:	64c50513          	addi	a0,a0,1612 # ffffffffc0206e80 <default_pmm_manager+0x720>
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc020383c:	e406                	sd	ra,8(sp)
    assert(next->vm_start < next->vm_end);
ffffffffc020383e:	c51fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203842 <mm_create>:
{
ffffffffc0203842:	1141                	addi	sp,sp,-16
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0203844:	04000513          	li	a0,64
{
ffffffffc0203848:	e406                	sd	ra,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc020384a:	eecfe0ef          	jal	ra,ffffffffc0201f36 <kmalloc>
    if (mm != NULL)
ffffffffc020384e:	cd19                	beqz	a0,ffffffffc020386c <mm_create+0x2a>
    elm->prev = elm->next = elm;
ffffffffc0203850:	e508                	sd	a0,8(a0)
ffffffffc0203852:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc0203854:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc0203858:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc020385c:	02052023          	sw	zero,32(a0)
        mm->sm_priv = NULL;
ffffffffc0203860:	02053423          	sd	zero,40(a0)
}

static inline void
set_mm_count(struct mm_struct *mm, int val)
{
    mm->mm_count = val;
ffffffffc0203864:	02052823          	sw	zero,48(a0)
typedef volatile bool lock_t;

static inline void
lock_init(lock_t *lock)
{
    *lock = 0;
ffffffffc0203868:	02053c23          	sd	zero,56(a0)
}
ffffffffc020386c:	60a2                	ld	ra,8(sp)
ffffffffc020386e:	0141                	addi	sp,sp,16
ffffffffc0203870:	8082                	ret

ffffffffc0203872 <find_vma>:
{
ffffffffc0203872:	86aa                	mv	a3,a0
    if (mm != NULL)
ffffffffc0203874:	c505                	beqz	a0,ffffffffc020389c <find_vma+0x2a>
        vma = mm->mmap_cache;
ffffffffc0203876:	6908                	ld	a0,16(a0)
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc0203878:	c501                	beqz	a0,ffffffffc0203880 <find_vma+0xe>
ffffffffc020387a:	651c                	ld	a5,8(a0)
ffffffffc020387c:	02f5f263          	bgeu	a1,a5,ffffffffc02038a0 <find_vma+0x2e>
    return listelm->next;
ffffffffc0203880:	669c                	ld	a5,8(a3)
            while ((le = list_next(le)) != list)
ffffffffc0203882:	00f68d63          	beq	a3,a5,ffffffffc020389c <find_vma+0x2a>
                if (vma->vm_start <= addr && addr < vma->vm_end)
ffffffffc0203886:	fe87b703          	ld	a4,-24(a5) # ffffffffc7ffffe8 <end+0x7d403cc>
ffffffffc020388a:	00e5e663          	bltu	a1,a4,ffffffffc0203896 <find_vma+0x24>
ffffffffc020388e:	ff07b703          	ld	a4,-16(a5)
ffffffffc0203892:	00e5ec63          	bltu	a1,a4,ffffffffc02038aa <find_vma+0x38>
ffffffffc0203896:	679c                	ld	a5,8(a5)
            while ((le = list_next(le)) != list)
ffffffffc0203898:	fef697e3          	bne	a3,a5,ffffffffc0203886 <find_vma+0x14>
    struct vma_struct *vma = NULL;
ffffffffc020389c:	4501                	li	a0,0
}
ffffffffc020389e:	8082                	ret
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc02038a0:	691c                	ld	a5,16(a0)
ffffffffc02038a2:	fcf5ffe3          	bgeu	a1,a5,ffffffffc0203880 <find_vma+0xe>
            mm->mmap_cache = vma;
ffffffffc02038a6:	ea88                	sd	a0,16(a3)
ffffffffc02038a8:	8082                	ret
                vma = le2vma(le, list_link);
ffffffffc02038aa:	fe078513          	addi	a0,a5,-32
            mm->mmap_cache = vma;
ffffffffc02038ae:	ea88                	sd	a0,16(a3)
ffffffffc02038b0:	8082                	ret

ffffffffc02038b2 <insert_vma_struct>:
}

// insert_vma_struct -insert vma in mm's list link
void insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma)
{
    assert(vma->vm_start < vma->vm_end);
ffffffffc02038b2:	6590                	ld	a2,8(a1)
ffffffffc02038b4:	0105b803          	ld	a6,16(a1)
{
ffffffffc02038b8:	1141                	addi	sp,sp,-16
ffffffffc02038ba:	e406                	sd	ra,8(sp)
ffffffffc02038bc:	87aa                	mv	a5,a0
    assert(vma->vm_start < vma->vm_end);
ffffffffc02038be:	01066763          	bltu	a2,a6,ffffffffc02038cc <insert_vma_struct+0x1a>
ffffffffc02038c2:	a085                	j	ffffffffc0203922 <insert_vma_struct+0x70>

    list_entry_t *le = list;
    while ((le = list_next(le)) != list)
    {
        struct vma_struct *mmap_prev = le2vma(le, list_link);
        if (mmap_prev->vm_start > vma->vm_start)
ffffffffc02038c4:	fe87b703          	ld	a4,-24(a5)
ffffffffc02038c8:	04e66863          	bltu	a2,a4,ffffffffc0203918 <insert_vma_struct+0x66>
ffffffffc02038cc:	86be                	mv	a3,a5
ffffffffc02038ce:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != list)
ffffffffc02038d0:	fef51ae3          	bne	a0,a5,ffffffffc02038c4 <insert_vma_struct+0x12>
    }

    le_next = list_next(le_prev);

    /* check overlap */
    if (le_prev != list)
ffffffffc02038d4:	02a68463          	beq	a3,a0,ffffffffc02038fc <insert_vma_struct+0x4a>
    {
        check_vma_overlap(le2vma(le_prev, list_link), vma);
ffffffffc02038d8:	ff06b703          	ld	a4,-16(a3)
    assert(prev->vm_start < prev->vm_end);
ffffffffc02038dc:	fe86b883          	ld	a7,-24(a3)
ffffffffc02038e0:	08e8f163          	bgeu	a7,a4,ffffffffc0203962 <insert_vma_struct+0xb0>
    assert(prev->vm_end <= next->vm_start);
ffffffffc02038e4:	04e66f63          	bltu	a2,a4,ffffffffc0203942 <insert_vma_struct+0x90>
    }
    if (le_next != list)
ffffffffc02038e8:	00f50a63          	beq	a0,a5,ffffffffc02038fc <insert_vma_struct+0x4a>
        if (mmap_prev->vm_start > vma->vm_start)
ffffffffc02038ec:	fe87b703          	ld	a4,-24(a5)
    assert(prev->vm_end <= next->vm_start);
ffffffffc02038f0:	05076963          	bltu	a4,a6,ffffffffc0203942 <insert_vma_struct+0x90>
    assert(next->vm_start < next->vm_end);
ffffffffc02038f4:	ff07b603          	ld	a2,-16(a5)
ffffffffc02038f8:	02c77363          	bgeu	a4,a2,ffffffffc020391e <insert_vma_struct+0x6c>
    }

    vma->vm_mm = mm;
    list_add_after(le_prev, &(vma->list_link));

    mm->map_count++;
ffffffffc02038fc:	5118                	lw	a4,32(a0)
    vma->vm_mm = mm;
ffffffffc02038fe:	e188                	sd	a0,0(a1)
    list_add_after(le_prev, &(vma->list_link));
ffffffffc0203900:	02058613          	addi	a2,a1,32
    prev->next = next->prev = elm;
ffffffffc0203904:	e390                	sd	a2,0(a5)
ffffffffc0203906:	e690                	sd	a2,8(a3)
}
ffffffffc0203908:	60a2                	ld	ra,8(sp)
    elm->next = next;
ffffffffc020390a:	f59c                	sd	a5,40(a1)
    elm->prev = prev;
ffffffffc020390c:	f194                	sd	a3,32(a1)
    mm->map_count++;
ffffffffc020390e:	0017079b          	addiw	a5,a4,1
ffffffffc0203912:	d11c                	sw	a5,32(a0)
}
ffffffffc0203914:	0141                	addi	sp,sp,16
ffffffffc0203916:	8082                	ret
    if (le_prev != list)
ffffffffc0203918:	fca690e3          	bne	a3,a0,ffffffffc02038d8 <insert_vma_struct+0x26>
ffffffffc020391c:	bfd1                	j	ffffffffc02038f0 <insert_vma_struct+0x3e>
ffffffffc020391e:	f01ff0ef          	jal	ra,ffffffffc020381e <check_vma_overlap.part.0>
    assert(vma->vm_start < vma->vm_end);
ffffffffc0203922:	00003697          	auipc	a3,0x3
ffffffffc0203926:	56e68693          	addi	a3,a3,1390 # ffffffffc0206e90 <default_pmm_manager+0x730>
ffffffffc020392a:	00003617          	auipc	a2,0x3
ffffffffc020392e:	a8660613          	addi	a2,a2,-1402 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc0203932:	07a00593          	li	a1,122
ffffffffc0203936:	00003517          	auipc	a0,0x3
ffffffffc020393a:	54a50513          	addi	a0,a0,1354 # ffffffffc0206e80 <default_pmm_manager+0x720>
ffffffffc020393e:	b51fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(prev->vm_end <= next->vm_start);
ffffffffc0203942:	00003697          	auipc	a3,0x3
ffffffffc0203946:	58e68693          	addi	a3,a3,1422 # ffffffffc0206ed0 <default_pmm_manager+0x770>
ffffffffc020394a:	00003617          	auipc	a2,0x3
ffffffffc020394e:	a6660613          	addi	a2,a2,-1434 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc0203952:	07300593          	li	a1,115
ffffffffc0203956:	00003517          	auipc	a0,0x3
ffffffffc020395a:	52a50513          	addi	a0,a0,1322 # ffffffffc0206e80 <default_pmm_manager+0x720>
ffffffffc020395e:	b31fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(prev->vm_start < prev->vm_end);
ffffffffc0203962:	00003697          	auipc	a3,0x3
ffffffffc0203966:	54e68693          	addi	a3,a3,1358 # ffffffffc0206eb0 <default_pmm_manager+0x750>
ffffffffc020396a:	00003617          	auipc	a2,0x3
ffffffffc020396e:	a4660613          	addi	a2,a2,-1466 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc0203972:	07200593          	li	a1,114
ffffffffc0203976:	00003517          	auipc	a0,0x3
ffffffffc020397a:	50a50513          	addi	a0,a0,1290 # ffffffffc0206e80 <default_pmm_manager+0x720>
ffffffffc020397e:	b11fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203982 <mm_destroy>:

// mm_destroy - free mm and mm internal fields
void mm_destroy(struct mm_struct *mm)
{
    assert(mm_count(mm) == 0);
ffffffffc0203982:	591c                	lw	a5,48(a0)
{
ffffffffc0203984:	1141                	addi	sp,sp,-16
ffffffffc0203986:	e406                	sd	ra,8(sp)
ffffffffc0203988:	e022                	sd	s0,0(sp)
    assert(mm_count(mm) == 0);
ffffffffc020398a:	e78d                	bnez	a5,ffffffffc02039b4 <mm_destroy+0x32>
ffffffffc020398c:	842a                	mv	s0,a0
    return listelm->next;
ffffffffc020398e:	6508                	ld	a0,8(a0)

    list_entry_t *list = &(mm->mmap_list), *le;
    while ((le = list_next(list)) != list)
ffffffffc0203990:	00a40c63          	beq	s0,a0,ffffffffc02039a8 <mm_destroy+0x26>
    __list_del(listelm->prev, listelm->next);
ffffffffc0203994:	6118                	ld	a4,0(a0)
ffffffffc0203996:	651c                	ld	a5,8(a0)
    {
        list_del(le);
        kfree(le2vma(le, list_link)); // kfree vma
ffffffffc0203998:	1501                	addi	a0,a0,-32
    prev->next = next;
ffffffffc020399a:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc020399c:	e398                	sd	a4,0(a5)
ffffffffc020399e:	e48fe0ef          	jal	ra,ffffffffc0201fe6 <kfree>
    return listelm->next;
ffffffffc02039a2:	6408                	ld	a0,8(s0)
    while ((le = list_next(list)) != list)
ffffffffc02039a4:	fea418e3          	bne	s0,a0,ffffffffc0203994 <mm_destroy+0x12>
    }
    kfree(mm); // kfree mm
ffffffffc02039a8:	8522                	mv	a0,s0
    mm = NULL;
}
ffffffffc02039aa:	6402                	ld	s0,0(sp)
ffffffffc02039ac:	60a2                	ld	ra,8(sp)
ffffffffc02039ae:	0141                	addi	sp,sp,16
    kfree(mm); // kfree mm
ffffffffc02039b0:	e36fe06f          	j	ffffffffc0201fe6 <kfree>
    assert(mm_count(mm) == 0);
ffffffffc02039b4:	00003697          	auipc	a3,0x3
ffffffffc02039b8:	53c68693          	addi	a3,a3,1340 # ffffffffc0206ef0 <default_pmm_manager+0x790>
ffffffffc02039bc:	00003617          	auipc	a2,0x3
ffffffffc02039c0:	9f460613          	addi	a2,a2,-1548 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc02039c4:	09e00593          	li	a1,158
ffffffffc02039c8:	00003517          	auipc	a0,0x3
ffffffffc02039cc:	4b850513          	addi	a0,a0,1208 # ffffffffc0206e80 <default_pmm_manager+0x720>
ffffffffc02039d0:	abffc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02039d4 <mm_map>:

int mm_map(struct mm_struct *mm, uintptr_t addr, size_t len, uint32_t vm_flags,
           struct vma_struct **vma_store)
{
ffffffffc02039d4:	7139                	addi	sp,sp,-64
ffffffffc02039d6:	f822                	sd	s0,48(sp)
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc02039d8:	6405                	lui	s0,0x1
ffffffffc02039da:	147d                	addi	s0,s0,-1
ffffffffc02039dc:	77fd                	lui	a5,0xfffff
ffffffffc02039de:	9622                	add	a2,a2,s0
ffffffffc02039e0:	962e                	add	a2,a2,a1
{
ffffffffc02039e2:	f426                	sd	s1,40(sp)
ffffffffc02039e4:	fc06                	sd	ra,56(sp)
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc02039e6:	00f5f4b3          	and	s1,a1,a5
{
ffffffffc02039ea:	f04a                	sd	s2,32(sp)
ffffffffc02039ec:	ec4e                	sd	s3,24(sp)
ffffffffc02039ee:	e852                	sd	s4,16(sp)
ffffffffc02039f0:	e456                	sd	s5,8(sp)
    if (!USER_ACCESS(start, end))
ffffffffc02039f2:	002005b7          	lui	a1,0x200
ffffffffc02039f6:	00f67433          	and	s0,a2,a5
ffffffffc02039fa:	06b4e363          	bltu	s1,a1,ffffffffc0203a60 <mm_map+0x8c>
ffffffffc02039fe:	0684f163          	bgeu	s1,s0,ffffffffc0203a60 <mm_map+0x8c>
ffffffffc0203a02:	4785                	li	a5,1
ffffffffc0203a04:	07fe                	slli	a5,a5,0x1f
ffffffffc0203a06:	0487ed63          	bltu	a5,s0,ffffffffc0203a60 <mm_map+0x8c>
ffffffffc0203a0a:	89aa                	mv	s3,a0
    {
        return -E_INVAL;
    }

    assert(mm != NULL);
ffffffffc0203a0c:	cd21                	beqz	a0,ffffffffc0203a64 <mm_map+0x90>

    int ret = -E_INVAL;

    struct vma_struct *vma;
    if ((vma = find_vma(mm, start)) != NULL && end > vma->vm_start)
ffffffffc0203a0e:	85a6                	mv	a1,s1
ffffffffc0203a10:	8ab6                	mv	s5,a3
ffffffffc0203a12:	8a3a                	mv	s4,a4
ffffffffc0203a14:	e5fff0ef          	jal	ra,ffffffffc0203872 <find_vma>
ffffffffc0203a18:	c501                	beqz	a0,ffffffffc0203a20 <mm_map+0x4c>
ffffffffc0203a1a:	651c                	ld	a5,8(a0)
ffffffffc0203a1c:	0487e263          	bltu	a5,s0,ffffffffc0203a60 <mm_map+0x8c>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203a20:	03000513          	li	a0,48
ffffffffc0203a24:	d12fe0ef          	jal	ra,ffffffffc0201f36 <kmalloc>
ffffffffc0203a28:	892a                	mv	s2,a0
    {
        goto out;
    }
    ret = -E_NO_MEM;
ffffffffc0203a2a:	5571                	li	a0,-4
    if (vma != NULL)
ffffffffc0203a2c:	02090163          	beqz	s2,ffffffffc0203a4e <mm_map+0x7a>

    if ((vma = vma_create(start, end, vm_flags)) == NULL)
    {
        goto out;
    }
    insert_vma_struct(mm, vma);
ffffffffc0203a30:	854e                	mv	a0,s3
        vma->vm_start = vm_start;
ffffffffc0203a32:	00993423          	sd	s1,8(s2)
        vma->vm_end = vm_end;
ffffffffc0203a36:	00893823          	sd	s0,16(s2)
        vma->vm_flags = vm_flags;
ffffffffc0203a3a:	01592c23          	sw	s5,24(s2)
    insert_vma_struct(mm, vma);
ffffffffc0203a3e:	85ca                	mv	a1,s2
ffffffffc0203a40:	e73ff0ef          	jal	ra,ffffffffc02038b2 <insert_vma_struct>
    if (vma_store != NULL)
    {
        *vma_store = vma;
    }
    ret = 0;
ffffffffc0203a44:	4501                	li	a0,0
    if (vma_store != NULL)
ffffffffc0203a46:	000a0463          	beqz	s4,ffffffffc0203a4e <mm_map+0x7a>
        *vma_store = vma;
ffffffffc0203a4a:	012a3023          	sd	s2,0(s4)

out:
    return ret;
}
ffffffffc0203a4e:	70e2                	ld	ra,56(sp)
ffffffffc0203a50:	7442                	ld	s0,48(sp)
ffffffffc0203a52:	74a2                	ld	s1,40(sp)
ffffffffc0203a54:	7902                	ld	s2,32(sp)
ffffffffc0203a56:	69e2                	ld	s3,24(sp)
ffffffffc0203a58:	6a42                	ld	s4,16(sp)
ffffffffc0203a5a:	6aa2                	ld	s5,8(sp)
ffffffffc0203a5c:	6121                	addi	sp,sp,64
ffffffffc0203a5e:	8082                	ret
        return -E_INVAL;
ffffffffc0203a60:	5575                	li	a0,-3
ffffffffc0203a62:	b7f5                	j	ffffffffc0203a4e <mm_map+0x7a>
    assert(mm != NULL);
ffffffffc0203a64:	00003697          	auipc	a3,0x3
ffffffffc0203a68:	4a468693          	addi	a3,a3,1188 # ffffffffc0206f08 <default_pmm_manager+0x7a8>
ffffffffc0203a6c:	00003617          	auipc	a2,0x3
ffffffffc0203a70:	94460613          	addi	a2,a2,-1724 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc0203a74:	0b300593          	li	a1,179
ffffffffc0203a78:	00003517          	auipc	a0,0x3
ffffffffc0203a7c:	40850513          	addi	a0,a0,1032 # ffffffffc0206e80 <default_pmm_manager+0x720>
ffffffffc0203a80:	a0ffc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203a84 <dup_mmap>:

int dup_mmap(struct mm_struct *to, struct mm_struct *from)
{
ffffffffc0203a84:	7139                	addi	sp,sp,-64
ffffffffc0203a86:	fc06                	sd	ra,56(sp)
ffffffffc0203a88:	f822                	sd	s0,48(sp)
ffffffffc0203a8a:	f426                	sd	s1,40(sp)
ffffffffc0203a8c:	f04a                	sd	s2,32(sp)
ffffffffc0203a8e:	ec4e                	sd	s3,24(sp)
ffffffffc0203a90:	e852                	sd	s4,16(sp)
ffffffffc0203a92:	e456                	sd	s5,8(sp)
    assert(to != NULL && from != NULL);
ffffffffc0203a94:	c52d                	beqz	a0,ffffffffc0203afe <dup_mmap+0x7a>
ffffffffc0203a96:	892a                	mv	s2,a0
ffffffffc0203a98:	84ae                	mv	s1,a1
    list_entry_t *list = &(from->mmap_list), *le = list;
ffffffffc0203a9a:	842e                	mv	s0,a1
    assert(to != NULL && from != NULL);
ffffffffc0203a9c:	e595                	bnez	a1,ffffffffc0203ac8 <dup_mmap+0x44>
ffffffffc0203a9e:	a085                	j	ffffffffc0203afe <dup_mmap+0x7a>
        if (nvma == NULL)
        {
            return -E_NO_MEM;
        }

        insert_vma_struct(to, nvma);
ffffffffc0203aa0:	854a                	mv	a0,s2
        vma->vm_start = vm_start;
ffffffffc0203aa2:	0155b423          	sd	s5,8(a1) # 200008 <_binary_obj___user_exit_out_size+0x1f4ec8>
        vma->vm_end = vm_end;
ffffffffc0203aa6:	0145b823          	sd	s4,16(a1)
        vma->vm_flags = vm_flags;
ffffffffc0203aaa:	0135ac23          	sw	s3,24(a1)
        insert_vma_struct(to, nvma);
ffffffffc0203aae:	e05ff0ef          	jal	ra,ffffffffc02038b2 <insert_vma_struct>

        bool share = 0;
        if (copy_range(to->pgdir, from->pgdir, vma->vm_start, vma->vm_end, share) != 0)
ffffffffc0203ab2:	ff043683          	ld	a3,-16(s0) # ff0 <_binary_obj___user_faultread_out_size-0x8be0>
ffffffffc0203ab6:	fe843603          	ld	a2,-24(s0)
ffffffffc0203aba:	6c8c                	ld	a1,24(s1)
ffffffffc0203abc:	01893503          	ld	a0,24(s2)
ffffffffc0203ac0:	4701                	li	a4,0
ffffffffc0203ac2:	d5ffe0ef          	jal	ra,ffffffffc0202820 <copy_range>
ffffffffc0203ac6:	e105                	bnez	a0,ffffffffc0203ae6 <dup_mmap+0x62>
    return listelm->prev;
ffffffffc0203ac8:	6000                	ld	s0,0(s0)
    while ((le = list_prev(le)) != list)
ffffffffc0203aca:	02848863          	beq	s1,s0,ffffffffc0203afa <dup_mmap+0x76>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203ace:	03000513          	li	a0,48
        nvma = vma_create(vma->vm_start, vma->vm_end, vma->vm_flags);
ffffffffc0203ad2:	fe843a83          	ld	s5,-24(s0)
ffffffffc0203ad6:	ff043a03          	ld	s4,-16(s0)
ffffffffc0203ada:	ff842983          	lw	s3,-8(s0)
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203ade:	c58fe0ef          	jal	ra,ffffffffc0201f36 <kmalloc>
ffffffffc0203ae2:	85aa                	mv	a1,a0
    if (vma != NULL)
ffffffffc0203ae4:	fd55                	bnez	a0,ffffffffc0203aa0 <dup_mmap+0x1c>
            return -E_NO_MEM;
ffffffffc0203ae6:	5571                	li	a0,-4
        {
            return -E_NO_MEM;
        }
    }
    return 0;
}
ffffffffc0203ae8:	70e2                	ld	ra,56(sp)
ffffffffc0203aea:	7442                	ld	s0,48(sp)
ffffffffc0203aec:	74a2                	ld	s1,40(sp)
ffffffffc0203aee:	7902                	ld	s2,32(sp)
ffffffffc0203af0:	69e2                	ld	s3,24(sp)
ffffffffc0203af2:	6a42                	ld	s4,16(sp)
ffffffffc0203af4:	6aa2                	ld	s5,8(sp)
ffffffffc0203af6:	6121                	addi	sp,sp,64
ffffffffc0203af8:	8082                	ret
    return 0;
ffffffffc0203afa:	4501                	li	a0,0
ffffffffc0203afc:	b7f5                	j	ffffffffc0203ae8 <dup_mmap+0x64>
    assert(to != NULL && from != NULL);
ffffffffc0203afe:	00003697          	auipc	a3,0x3
ffffffffc0203b02:	41a68693          	addi	a3,a3,1050 # ffffffffc0206f18 <default_pmm_manager+0x7b8>
ffffffffc0203b06:	00003617          	auipc	a2,0x3
ffffffffc0203b0a:	8aa60613          	addi	a2,a2,-1878 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc0203b0e:	0cf00593          	li	a1,207
ffffffffc0203b12:	00003517          	auipc	a0,0x3
ffffffffc0203b16:	36e50513          	addi	a0,a0,878 # ffffffffc0206e80 <default_pmm_manager+0x720>
ffffffffc0203b1a:	975fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203b1e <exit_mmap>:

void exit_mmap(struct mm_struct *mm)
{
ffffffffc0203b1e:	1101                	addi	sp,sp,-32
ffffffffc0203b20:	ec06                	sd	ra,24(sp)
ffffffffc0203b22:	e822                	sd	s0,16(sp)
ffffffffc0203b24:	e426                	sd	s1,8(sp)
ffffffffc0203b26:	e04a                	sd	s2,0(sp)
    assert(mm != NULL && mm_count(mm) == 0);
ffffffffc0203b28:	c531                	beqz	a0,ffffffffc0203b74 <exit_mmap+0x56>
ffffffffc0203b2a:	591c                	lw	a5,48(a0)
ffffffffc0203b2c:	84aa                	mv	s1,a0
ffffffffc0203b2e:	e3b9                	bnez	a5,ffffffffc0203b74 <exit_mmap+0x56>
    return listelm->next;
ffffffffc0203b30:	6500                	ld	s0,8(a0)
    pde_t *pgdir = mm->pgdir;
ffffffffc0203b32:	01853903          	ld	s2,24(a0)
    list_entry_t *list = &(mm->mmap_list), *le = list;
    while ((le = list_next(le)) != list)
ffffffffc0203b36:	02850663          	beq	a0,s0,ffffffffc0203b62 <exit_mmap+0x44>
    {
        struct vma_struct *vma = le2vma(le, list_link);
        unmap_range(pgdir, vma->vm_start, vma->vm_end);
ffffffffc0203b3a:	ff043603          	ld	a2,-16(s0)
ffffffffc0203b3e:	fe843583          	ld	a1,-24(s0)
ffffffffc0203b42:	854a                	mv	a0,s2
ffffffffc0203b44:	905fe0ef          	jal	ra,ffffffffc0202448 <unmap_range>
ffffffffc0203b48:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != list)
ffffffffc0203b4a:	fe8498e3          	bne	s1,s0,ffffffffc0203b3a <exit_mmap+0x1c>
ffffffffc0203b4e:	6400                	ld	s0,8(s0)
    }
    while ((le = list_next(le)) != list)
ffffffffc0203b50:	00848c63          	beq	s1,s0,ffffffffc0203b68 <exit_mmap+0x4a>
    {
        struct vma_struct *vma = le2vma(le, list_link);
        exit_range(pgdir, vma->vm_start, vma->vm_end);
ffffffffc0203b54:	ff043603          	ld	a2,-16(s0)
ffffffffc0203b58:	fe843583          	ld	a1,-24(s0)
ffffffffc0203b5c:	854a                	mv	a0,s2
ffffffffc0203b5e:	a31fe0ef          	jal	ra,ffffffffc020258e <exit_range>
ffffffffc0203b62:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != list)
ffffffffc0203b64:	fe8498e3          	bne	s1,s0,ffffffffc0203b54 <exit_mmap+0x36>
    }
}
ffffffffc0203b68:	60e2                	ld	ra,24(sp)
ffffffffc0203b6a:	6442                	ld	s0,16(sp)
ffffffffc0203b6c:	64a2                	ld	s1,8(sp)
ffffffffc0203b6e:	6902                	ld	s2,0(sp)
ffffffffc0203b70:	6105                	addi	sp,sp,32
ffffffffc0203b72:	8082                	ret
    assert(mm != NULL && mm_count(mm) == 0);
ffffffffc0203b74:	00003697          	auipc	a3,0x3
ffffffffc0203b78:	3c468693          	addi	a3,a3,964 # ffffffffc0206f38 <default_pmm_manager+0x7d8>
ffffffffc0203b7c:	00003617          	auipc	a2,0x3
ffffffffc0203b80:	83460613          	addi	a2,a2,-1996 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc0203b84:	0e800593          	li	a1,232
ffffffffc0203b88:	00003517          	auipc	a0,0x3
ffffffffc0203b8c:	2f850513          	addi	a0,a0,760 # ffffffffc0206e80 <default_pmm_manager+0x720>
ffffffffc0203b90:	8fffc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203b94 <vmm_init>:
}

// vmm_init - initialize virtual memory management
//          - now just call check_vmm to check correctness of vmm
void vmm_init(void)
{
ffffffffc0203b94:	7139                	addi	sp,sp,-64
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0203b96:	04000513          	li	a0,64
{
ffffffffc0203b9a:	fc06                	sd	ra,56(sp)
ffffffffc0203b9c:	f822                	sd	s0,48(sp)
ffffffffc0203b9e:	f426                	sd	s1,40(sp)
ffffffffc0203ba0:	f04a                	sd	s2,32(sp)
ffffffffc0203ba2:	ec4e                	sd	s3,24(sp)
ffffffffc0203ba4:	e852                	sd	s4,16(sp)
ffffffffc0203ba6:	e456                	sd	s5,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0203ba8:	b8efe0ef          	jal	ra,ffffffffc0201f36 <kmalloc>
    if (mm != NULL)
ffffffffc0203bac:	2e050663          	beqz	a0,ffffffffc0203e98 <vmm_init+0x304>
ffffffffc0203bb0:	84aa                	mv	s1,a0
    elm->prev = elm->next = elm;
ffffffffc0203bb2:	e508                	sd	a0,8(a0)
ffffffffc0203bb4:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc0203bb6:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc0203bba:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc0203bbe:	02052023          	sw	zero,32(a0)
        mm->sm_priv = NULL;
ffffffffc0203bc2:	02053423          	sd	zero,40(a0)
ffffffffc0203bc6:	02052823          	sw	zero,48(a0)
ffffffffc0203bca:	02053c23          	sd	zero,56(a0)
ffffffffc0203bce:	03200413          	li	s0,50
ffffffffc0203bd2:	a811                	j	ffffffffc0203be6 <vmm_init+0x52>
        vma->vm_start = vm_start;
ffffffffc0203bd4:	e500                	sd	s0,8(a0)
        vma->vm_end = vm_end;
ffffffffc0203bd6:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0203bd8:	00052c23          	sw	zero,24(a0)
    assert(mm != NULL);

    int step1 = 10, step2 = step1 * 10;

    int i;
    for (i = step1; i >= 1; i--)
ffffffffc0203bdc:	146d                	addi	s0,s0,-5
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0203bde:	8526                	mv	a0,s1
ffffffffc0203be0:	cd3ff0ef          	jal	ra,ffffffffc02038b2 <insert_vma_struct>
    for (i = step1; i >= 1; i--)
ffffffffc0203be4:	c80d                	beqz	s0,ffffffffc0203c16 <vmm_init+0x82>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203be6:	03000513          	li	a0,48
ffffffffc0203bea:	b4cfe0ef          	jal	ra,ffffffffc0201f36 <kmalloc>
ffffffffc0203bee:	85aa                	mv	a1,a0
ffffffffc0203bf0:	00240793          	addi	a5,s0,2
    if (vma != NULL)
ffffffffc0203bf4:	f165                	bnez	a0,ffffffffc0203bd4 <vmm_init+0x40>
        assert(vma != NULL);
ffffffffc0203bf6:	00003697          	auipc	a3,0x3
ffffffffc0203bfa:	4da68693          	addi	a3,a3,1242 # ffffffffc02070d0 <default_pmm_manager+0x970>
ffffffffc0203bfe:	00002617          	auipc	a2,0x2
ffffffffc0203c02:	7b260613          	addi	a2,a2,1970 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc0203c06:	12c00593          	li	a1,300
ffffffffc0203c0a:	00003517          	auipc	a0,0x3
ffffffffc0203c0e:	27650513          	addi	a0,a0,630 # ffffffffc0206e80 <default_pmm_manager+0x720>
ffffffffc0203c12:	87dfc0ef          	jal	ra,ffffffffc020048e <__panic>
ffffffffc0203c16:	03700413          	li	s0,55
    }

    for (i = step1 + 1; i <= step2; i++)
ffffffffc0203c1a:	1f900913          	li	s2,505
ffffffffc0203c1e:	a819                	j	ffffffffc0203c34 <vmm_init+0xa0>
        vma->vm_start = vm_start;
ffffffffc0203c20:	e500                	sd	s0,8(a0)
        vma->vm_end = vm_end;
ffffffffc0203c22:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0203c24:	00052c23          	sw	zero,24(a0)
    for (i = step1 + 1; i <= step2; i++)
ffffffffc0203c28:	0415                	addi	s0,s0,5
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0203c2a:	8526                	mv	a0,s1
ffffffffc0203c2c:	c87ff0ef          	jal	ra,ffffffffc02038b2 <insert_vma_struct>
    for (i = step1 + 1; i <= step2; i++)
ffffffffc0203c30:	03240a63          	beq	s0,s2,ffffffffc0203c64 <vmm_init+0xd0>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203c34:	03000513          	li	a0,48
ffffffffc0203c38:	afefe0ef          	jal	ra,ffffffffc0201f36 <kmalloc>
ffffffffc0203c3c:	85aa                	mv	a1,a0
ffffffffc0203c3e:	00240793          	addi	a5,s0,2
    if (vma != NULL)
ffffffffc0203c42:	fd79                	bnez	a0,ffffffffc0203c20 <vmm_init+0x8c>
        assert(vma != NULL);
ffffffffc0203c44:	00003697          	auipc	a3,0x3
ffffffffc0203c48:	48c68693          	addi	a3,a3,1164 # ffffffffc02070d0 <default_pmm_manager+0x970>
ffffffffc0203c4c:	00002617          	auipc	a2,0x2
ffffffffc0203c50:	76460613          	addi	a2,a2,1892 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc0203c54:	13300593          	li	a1,307
ffffffffc0203c58:	00003517          	auipc	a0,0x3
ffffffffc0203c5c:	22850513          	addi	a0,a0,552 # ffffffffc0206e80 <default_pmm_manager+0x720>
ffffffffc0203c60:	82ffc0ef          	jal	ra,ffffffffc020048e <__panic>
    return listelm->next;
ffffffffc0203c64:	649c                	ld	a5,8(s1)
ffffffffc0203c66:	471d                	li	a4,7
    }

    list_entry_t *le = list_next(&(mm->mmap_list));

    for (i = 1; i <= step2; i++)
ffffffffc0203c68:	1fb00593          	li	a1,507
    {
        assert(le != &(mm->mmap_list));
ffffffffc0203c6c:	16f48663          	beq	s1,a5,ffffffffc0203dd8 <vmm_init+0x244>
        struct vma_struct *mmap = le2vma(le, list_link);
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0203c70:	fe87b603          	ld	a2,-24(a5) # ffffffffffffefe8 <end+0x3fd3f3cc>
ffffffffc0203c74:	ffe70693          	addi	a3,a4,-2 # ffe <_binary_obj___user_faultread_out_size-0x8bd2>
ffffffffc0203c78:	10d61063          	bne	a2,a3,ffffffffc0203d78 <vmm_init+0x1e4>
ffffffffc0203c7c:	ff07b683          	ld	a3,-16(a5)
ffffffffc0203c80:	0ed71c63          	bne	a4,a3,ffffffffc0203d78 <vmm_init+0x1e4>
    for (i = 1; i <= step2; i++)
ffffffffc0203c84:	0715                	addi	a4,a4,5
ffffffffc0203c86:	679c                	ld	a5,8(a5)
ffffffffc0203c88:	feb712e3          	bne	a4,a1,ffffffffc0203c6c <vmm_init+0xd8>
ffffffffc0203c8c:	4a1d                	li	s4,7
ffffffffc0203c8e:	4415                	li	s0,5
        le = list_next(le);
    }

    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc0203c90:	1f900a93          	li	s5,505
    {
        struct vma_struct *vma1 = find_vma(mm, i);
ffffffffc0203c94:	85a2                	mv	a1,s0
ffffffffc0203c96:	8526                	mv	a0,s1
ffffffffc0203c98:	bdbff0ef          	jal	ra,ffffffffc0203872 <find_vma>
ffffffffc0203c9c:	892a                	mv	s2,a0
        assert(vma1 != NULL);
ffffffffc0203c9e:	16050d63          	beqz	a0,ffffffffc0203e18 <vmm_init+0x284>
        struct vma_struct *vma2 = find_vma(mm, i + 1);
ffffffffc0203ca2:	00140593          	addi	a1,s0,1
ffffffffc0203ca6:	8526                	mv	a0,s1
ffffffffc0203ca8:	bcbff0ef          	jal	ra,ffffffffc0203872 <find_vma>
ffffffffc0203cac:	89aa                	mv	s3,a0
        assert(vma2 != NULL);
ffffffffc0203cae:	14050563          	beqz	a0,ffffffffc0203df8 <vmm_init+0x264>
        struct vma_struct *vma3 = find_vma(mm, i + 2);
ffffffffc0203cb2:	85d2                	mv	a1,s4
ffffffffc0203cb4:	8526                	mv	a0,s1
ffffffffc0203cb6:	bbdff0ef          	jal	ra,ffffffffc0203872 <find_vma>
        assert(vma3 == NULL);
ffffffffc0203cba:	16051f63          	bnez	a0,ffffffffc0203e38 <vmm_init+0x2a4>
        struct vma_struct *vma4 = find_vma(mm, i + 3);
ffffffffc0203cbe:	00340593          	addi	a1,s0,3
ffffffffc0203cc2:	8526                	mv	a0,s1
ffffffffc0203cc4:	bafff0ef          	jal	ra,ffffffffc0203872 <find_vma>
        assert(vma4 == NULL);
ffffffffc0203cc8:	1a051863          	bnez	a0,ffffffffc0203e78 <vmm_init+0x2e4>
        struct vma_struct *vma5 = find_vma(mm, i + 4);
ffffffffc0203ccc:	00440593          	addi	a1,s0,4
ffffffffc0203cd0:	8526                	mv	a0,s1
ffffffffc0203cd2:	ba1ff0ef          	jal	ra,ffffffffc0203872 <find_vma>
        assert(vma5 == NULL);
ffffffffc0203cd6:	18051163          	bnez	a0,ffffffffc0203e58 <vmm_init+0x2c4>

        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc0203cda:	00893783          	ld	a5,8(s2)
ffffffffc0203cde:	0a879d63          	bne	a5,s0,ffffffffc0203d98 <vmm_init+0x204>
ffffffffc0203ce2:	01093783          	ld	a5,16(s2)
ffffffffc0203ce6:	0b479963          	bne	a5,s4,ffffffffc0203d98 <vmm_init+0x204>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc0203cea:	0089b783          	ld	a5,8(s3)
ffffffffc0203cee:	0c879563          	bne	a5,s0,ffffffffc0203db8 <vmm_init+0x224>
ffffffffc0203cf2:	0109b783          	ld	a5,16(s3)
ffffffffc0203cf6:	0d479163          	bne	a5,s4,ffffffffc0203db8 <vmm_init+0x224>
    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc0203cfa:	0415                	addi	s0,s0,5
ffffffffc0203cfc:	0a15                	addi	s4,s4,5
ffffffffc0203cfe:	f9541be3          	bne	s0,s5,ffffffffc0203c94 <vmm_init+0x100>
ffffffffc0203d02:	4411                	li	s0,4
    }

    for (i = 4; i >= 0; i--)
ffffffffc0203d04:	597d                	li	s2,-1
    {
        struct vma_struct *vma_below_5 = find_vma(mm, i);
ffffffffc0203d06:	85a2                	mv	a1,s0
ffffffffc0203d08:	8526                	mv	a0,s1
ffffffffc0203d0a:	b69ff0ef          	jal	ra,ffffffffc0203872 <find_vma>
ffffffffc0203d0e:	0004059b          	sext.w	a1,s0
        if (vma_below_5 != NULL)
ffffffffc0203d12:	c90d                	beqz	a0,ffffffffc0203d44 <vmm_init+0x1b0>
        {
            cprintf("vma_below_5: i %x, start %x, end %x\n", i, vma_below_5->vm_start, vma_below_5->vm_end);
ffffffffc0203d14:	6914                	ld	a3,16(a0)
ffffffffc0203d16:	6510                	ld	a2,8(a0)
ffffffffc0203d18:	00003517          	auipc	a0,0x3
ffffffffc0203d1c:	34050513          	addi	a0,a0,832 # ffffffffc0207058 <default_pmm_manager+0x8f8>
ffffffffc0203d20:	c74fc0ef          	jal	ra,ffffffffc0200194 <cprintf>
        }
        assert(vma_below_5 == NULL);
ffffffffc0203d24:	00003697          	auipc	a3,0x3
ffffffffc0203d28:	35c68693          	addi	a3,a3,860 # ffffffffc0207080 <default_pmm_manager+0x920>
ffffffffc0203d2c:	00002617          	auipc	a2,0x2
ffffffffc0203d30:	68460613          	addi	a2,a2,1668 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc0203d34:	15900593          	li	a1,345
ffffffffc0203d38:	00003517          	auipc	a0,0x3
ffffffffc0203d3c:	14850513          	addi	a0,a0,328 # ffffffffc0206e80 <default_pmm_manager+0x720>
ffffffffc0203d40:	f4efc0ef          	jal	ra,ffffffffc020048e <__panic>
    for (i = 4; i >= 0; i--)
ffffffffc0203d44:	147d                	addi	s0,s0,-1
ffffffffc0203d46:	fd2410e3          	bne	s0,s2,ffffffffc0203d06 <vmm_init+0x172>
    }

    mm_destroy(mm);
ffffffffc0203d4a:	8526                	mv	a0,s1
ffffffffc0203d4c:	c37ff0ef          	jal	ra,ffffffffc0203982 <mm_destroy>

    cprintf("check_vma_struct() succeeded!\n");
ffffffffc0203d50:	00003517          	auipc	a0,0x3
ffffffffc0203d54:	34850513          	addi	a0,a0,840 # ffffffffc0207098 <default_pmm_manager+0x938>
ffffffffc0203d58:	c3cfc0ef          	jal	ra,ffffffffc0200194 <cprintf>
}
ffffffffc0203d5c:	7442                	ld	s0,48(sp)
ffffffffc0203d5e:	70e2                	ld	ra,56(sp)
ffffffffc0203d60:	74a2                	ld	s1,40(sp)
ffffffffc0203d62:	7902                	ld	s2,32(sp)
ffffffffc0203d64:	69e2                	ld	s3,24(sp)
ffffffffc0203d66:	6a42                	ld	s4,16(sp)
ffffffffc0203d68:	6aa2                	ld	s5,8(sp)
    cprintf("check_vmm() succeeded.\n");
ffffffffc0203d6a:	00003517          	auipc	a0,0x3
ffffffffc0203d6e:	34e50513          	addi	a0,a0,846 # ffffffffc02070b8 <default_pmm_manager+0x958>
}
ffffffffc0203d72:	6121                	addi	sp,sp,64
    cprintf("check_vmm() succeeded.\n");
ffffffffc0203d74:	c20fc06f          	j	ffffffffc0200194 <cprintf>
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0203d78:	00003697          	auipc	a3,0x3
ffffffffc0203d7c:	1f868693          	addi	a3,a3,504 # ffffffffc0206f70 <default_pmm_manager+0x810>
ffffffffc0203d80:	00002617          	auipc	a2,0x2
ffffffffc0203d84:	63060613          	addi	a2,a2,1584 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc0203d88:	13d00593          	li	a1,317
ffffffffc0203d8c:	00003517          	auipc	a0,0x3
ffffffffc0203d90:	0f450513          	addi	a0,a0,244 # ffffffffc0206e80 <default_pmm_manager+0x720>
ffffffffc0203d94:	efafc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc0203d98:	00003697          	auipc	a3,0x3
ffffffffc0203d9c:	26068693          	addi	a3,a3,608 # ffffffffc0206ff8 <default_pmm_manager+0x898>
ffffffffc0203da0:	00002617          	auipc	a2,0x2
ffffffffc0203da4:	61060613          	addi	a2,a2,1552 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc0203da8:	14e00593          	li	a1,334
ffffffffc0203dac:	00003517          	auipc	a0,0x3
ffffffffc0203db0:	0d450513          	addi	a0,a0,212 # ffffffffc0206e80 <default_pmm_manager+0x720>
ffffffffc0203db4:	edafc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc0203db8:	00003697          	auipc	a3,0x3
ffffffffc0203dbc:	27068693          	addi	a3,a3,624 # ffffffffc0207028 <default_pmm_manager+0x8c8>
ffffffffc0203dc0:	00002617          	auipc	a2,0x2
ffffffffc0203dc4:	5f060613          	addi	a2,a2,1520 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc0203dc8:	14f00593          	li	a1,335
ffffffffc0203dcc:	00003517          	auipc	a0,0x3
ffffffffc0203dd0:	0b450513          	addi	a0,a0,180 # ffffffffc0206e80 <default_pmm_manager+0x720>
ffffffffc0203dd4:	ebafc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(le != &(mm->mmap_list));
ffffffffc0203dd8:	00003697          	auipc	a3,0x3
ffffffffc0203ddc:	18068693          	addi	a3,a3,384 # ffffffffc0206f58 <default_pmm_manager+0x7f8>
ffffffffc0203de0:	00002617          	auipc	a2,0x2
ffffffffc0203de4:	5d060613          	addi	a2,a2,1488 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc0203de8:	13b00593          	li	a1,315
ffffffffc0203dec:	00003517          	auipc	a0,0x3
ffffffffc0203df0:	09450513          	addi	a0,a0,148 # ffffffffc0206e80 <default_pmm_manager+0x720>
ffffffffc0203df4:	e9afc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma2 != NULL);
ffffffffc0203df8:	00003697          	auipc	a3,0x3
ffffffffc0203dfc:	1c068693          	addi	a3,a3,448 # ffffffffc0206fb8 <default_pmm_manager+0x858>
ffffffffc0203e00:	00002617          	auipc	a2,0x2
ffffffffc0203e04:	5b060613          	addi	a2,a2,1456 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc0203e08:	14600593          	li	a1,326
ffffffffc0203e0c:	00003517          	auipc	a0,0x3
ffffffffc0203e10:	07450513          	addi	a0,a0,116 # ffffffffc0206e80 <default_pmm_manager+0x720>
ffffffffc0203e14:	e7afc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma1 != NULL);
ffffffffc0203e18:	00003697          	auipc	a3,0x3
ffffffffc0203e1c:	19068693          	addi	a3,a3,400 # ffffffffc0206fa8 <default_pmm_manager+0x848>
ffffffffc0203e20:	00002617          	auipc	a2,0x2
ffffffffc0203e24:	59060613          	addi	a2,a2,1424 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc0203e28:	14400593          	li	a1,324
ffffffffc0203e2c:	00003517          	auipc	a0,0x3
ffffffffc0203e30:	05450513          	addi	a0,a0,84 # ffffffffc0206e80 <default_pmm_manager+0x720>
ffffffffc0203e34:	e5afc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma3 == NULL);
ffffffffc0203e38:	00003697          	auipc	a3,0x3
ffffffffc0203e3c:	19068693          	addi	a3,a3,400 # ffffffffc0206fc8 <default_pmm_manager+0x868>
ffffffffc0203e40:	00002617          	auipc	a2,0x2
ffffffffc0203e44:	57060613          	addi	a2,a2,1392 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc0203e48:	14800593          	li	a1,328
ffffffffc0203e4c:	00003517          	auipc	a0,0x3
ffffffffc0203e50:	03450513          	addi	a0,a0,52 # ffffffffc0206e80 <default_pmm_manager+0x720>
ffffffffc0203e54:	e3afc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma5 == NULL);
ffffffffc0203e58:	00003697          	auipc	a3,0x3
ffffffffc0203e5c:	19068693          	addi	a3,a3,400 # ffffffffc0206fe8 <default_pmm_manager+0x888>
ffffffffc0203e60:	00002617          	auipc	a2,0x2
ffffffffc0203e64:	55060613          	addi	a2,a2,1360 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc0203e68:	14c00593          	li	a1,332
ffffffffc0203e6c:	00003517          	auipc	a0,0x3
ffffffffc0203e70:	01450513          	addi	a0,a0,20 # ffffffffc0206e80 <default_pmm_manager+0x720>
ffffffffc0203e74:	e1afc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma4 == NULL);
ffffffffc0203e78:	00003697          	auipc	a3,0x3
ffffffffc0203e7c:	16068693          	addi	a3,a3,352 # ffffffffc0206fd8 <default_pmm_manager+0x878>
ffffffffc0203e80:	00002617          	auipc	a2,0x2
ffffffffc0203e84:	53060613          	addi	a2,a2,1328 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc0203e88:	14a00593          	li	a1,330
ffffffffc0203e8c:	00003517          	auipc	a0,0x3
ffffffffc0203e90:	ff450513          	addi	a0,a0,-12 # ffffffffc0206e80 <default_pmm_manager+0x720>
ffffffffc0203e94:	dfafc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(mm != NULL);
ffffffffc0203e98:	00003697          	auipc	a3,0x3
ffffffffc0203e9c:	07068693          	addi	a3,a3,112 # ffffffffc0206f08 <default_pmm_manager+0x7a8>
ffffffffc0203ea0:	00002617          	auipc	a2,0x2
ffffffffc0203ea4:	51060613          	addi	a2,a2,1296 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc0203ea8:	12400593          	li	a1,292
ffffffffc0203eac:	00003517          	auipc	a0,0x3
ffffffffc0203eb0:	fd450513          	addi	a0,a0,-44 # ffffffffc0206e80 <default_pmm_manager+0x720>
ffffffffc0203eb4:	ddafc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203eb8 <user_mem_check>:
}
bool user_mem_check(struct mm_struct *mm, uintptr_t addr, size_t len, bool write)
{
ffffffffc0203eb8:	7179                	addi	sp,sp,-48
ffffffffc0203eba:	f022                	sd	s0,32(sp)
ffffffffc0203ebc:	f406                	sd	ra,40(sp)
ffffffffc0203ebe:	ec26                	sd	s1,24(sp)
ffffffffc0203ec0:	e84a                	sd	s2,16(sp)
ffffffffc0203ec2:	e44e                	sd	s3,8(sp)
ffffffffc0203ec4:	e052                	sd	s4,0(sp)
ffffffffc0203ec6:	842e                	mv	s0,a1
    if (mm != NULL)
ffffffffc0203ec8:	c135                	beqz	a0,ffffffffc0203f2c <user_mem_check+0x74>
    {
        if (!USER_ACCESS(addr, addr + len))
ffffffffc0203eca:	002007b7          	lui	a5,0x200
ffffffffc0203ece:	04f5e663          	bltu	a1,a5,ffffffffc0203f1a <user_mem_check+0x62>
ffffffffc0203ed2:	00c584b3          	add	s1,a1,a2
ffffffffc0203ed6:	0495f263          	bgeu	a1,s1,ffffffffc0203f1a <user_mem_check+0x62>
ffffffffc0203eda:	4785                	li	a5,1
ffffffffc0203edc:	07fe                	slli	a5,a5,0x1f
ffffffffc0203ede:	0297ee63          	bltu	a5,s1,ffffffffc0203f1a <user_mem_check+0x62>
ffffffffc0203ee2:	892a                	mv	s2,a0
ffffffffc0203ee4:	89b6                	mv	s3,a3
            {
                return 0;
            }
            if (write && (vma->vm_flags & VM_STACK))
            {
                if (start < vma->vm_start + PGSIZE)
ffffffffc0203ee6:	6a05                	lui	s4,0x1
ffffffffc0203ee8:	a821                	j	ffffffffc0203f00 <user_mem_check+0x48>
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203eea:	0027f693          	andi	a3,a5,2
                if (start < vma->vm_start + PGSIZE)
ffffffffc0203eee:	9752                	add	a4,a4,s4
            if (write && (vma->vm_flags & VM_STACK))
ffffffffc0203ef0:	8ba1                	andi	a5,a5,8
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203ef2:	c685                	beqz	a3,ffffffffc0203f1a <user_mem_check+0x62>
            if (write && (vma->vm_flags & VM_STACK))
ffffffffc0203ef4:	c399                	beqz	a5,ffffffffc0203efa <user_mem_check+0x42>
                if (start < vma->vm_start + PGSIZE)
ffffffffc0203ef6:	02e46263          	bltu	s0,a4,ffffffffc0203f1a <user_mem_check+0x62>
                { // check stack start & size
                    return 0;
                }
            }
            start = vma->vm_end;
ffffffffc0203efa:	6900                	ld	s0,16(a0)
        while (start < end)
ffffffffc0203efc:	04947663          	bgeu	s0,s1,ffffffffc0203f48 <user_mem_check+0x90>
            if ((vma = find_vma(mm, start)) == NULL || start < vma->vm_start)
ffffffffc0203f00:	85a2                	mv	a1,s0
ffffffffc0203f02:	854a                	mv	a0,s2
ffffffffc0203f04:	96fff0ef          	jal	ra,ffffffffc0203872 <find_vma>
ffffffffc0203f08:	c909                	beqz	a0,ffffffffc0203f1a <user_mem_check+0x62>
ffffffffc0203f0a:	6518                	ld	a4,8(a0)
ffffffffc0203f0c:	00e46763          	bltu	s0,a4,ffffffffc0203f1a <user_mem_check+0x62>
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203f10:	4d1c                	lw	a5,24(a0)
ffffffffc0203f12:	fc099ce3          	bnez	s3,ffffffffc0203eea <user_mem_check+0x32>
ffffffffc0203f16:	8b85                	andi	a5,a5,1
ffffffffc0203f18:	f3ed                	bnez	a5,ffffffffc0203efa <user_mem_check+0x42>
            return 0;
ffffffffc0203f1a:	4501                	li	a0,0
        }
        return 1;
    }
    return KERN_ACCESS(addr, addr + len);
ffffffffc0203f1c:	70a2                	ld	ra,40(sp)
ffffffffc0203f1e:	7402                	ld	s0,32(sp)
ffffffffc0203f20:	64e2                	ld	s1,24(sp)
ffffffffc0203f22:	6942                	ld	s2,16(sp)
ffffffffc0203f24:	69a2                	ld	s3,8(sp)
ffffffffc0203f26:	6a02                	ld	s4,0(sp)
ffffffffc0203f28:	6145                	addi	sp,sp,48
ffffffffc0203f2a:	8082                	ret
    return KERN_ACCESS(addr, addr + len);
ffffffffc0203f2c:	c02007b7          	lui	a5,0xc0200
ffffffffc0203f30:	4501                	li	a0,0
ffffffffc0203f32:	fef5e5e3          	bltu	a1,a5,ffffffffc0203f1c <user_mem_check+0x64>
ffffffffc0203f36:	962e                	add	a2,a2,a1
ffffffffc0203f38:	fec5f2e3          	bgeu	a1,a2,ffffffffc0203f1c <user_mem_check+0x64>
ffffffffc0203f3c:	c8000537          	lui	a0,0xc8000
ffffffffc0203f40:	0505                	addi	a0,a0,1
ffffffffc0203f42:	00a63533          	sltu	a0,a2,a0
ffffffffc0203f46:	bfd9                	j	ffffffffc0203f1c <user_mem_check+0x64>
        return 1;
ffffffffc0203f48:	4505                	li	a0,1
ffffffffc0203f4a:	bfc9                	j	ffffffffc0203f1c <user_mem_check+0x64>

ffffffffc0203f4c <kernel_thread_entry>:
.text
.globl kernel_thread_entry
kernel_thread_entry:        # void kernel_thread(void)
	move a0, s1
ffffffffc0203f4c:	8526                	mv	a0,s1
	jalr s0
ffffffffc0203f4e:	9402                	jalr	s0

	jal do_exit
ffffffffc0203f50:	61c000ef          	jal	ra,ffffffffc020456c <do_exit>

ffffffffc0203f54 <alloc_proc>:
void switch_to(struct context *from, struct context *to);

// alloc_proc - alloc a proc_struct and init all fields of proc_struct
static struct proc_struct *
alloc_proc(void)
{
ffffffffc0203f54:	1141                	addi	sp,sp,-16
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0203f56:	10800513          	li	a0,264
{
ffffffffc0203f5a:	e022                	sd	s0,0(sp)
ffffffffc0203f5c:	e406                	sd	ra,8(sp)
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0203f5e:	fd9fd0ef          	jal	ra,ffffffffc0201f36 <kmalloc>
ffffffffc0203f62:	842a                	mv	s0,a0
    if (proc != NULL)
ffffffffc0203f64:	c525                	beqz	a0,ffffffffc0203fcc <alloc_proc+0x78>
         * below fields(add in LAB5) in proc_struct need to be initialized
         *       uint32_t wait_state;                        // waiting state
         *       struct proc_struct *cptr, *yptr, *optr;     // relations between processes
         */
        // LAB4原有
        proc->state = PROC_UNINIT;                  // 初始化进程状态为未初始化
ffffffffc0203f66:	57fd                	li	a5,-1
ffffffffc0203f68:	1782                	slli	a5,a5,0x20
ffffffffc0203f6a:	e11c                	sd	a5,0(a0)
        proc->runs = 0;                             // 初始化运行次数为0
        proc->kstack = 0;                           // 初始化内核栈为0（空指针），后续通过setup_kstack()为进程分配实际的内核栈空间
        proc->need_resched = 0;                     // 初始化不需要重新调度
        proc->parent = NULL;                        // 初始化父进程指针为NULL
        proc->mm = NULL;                            // 初始化内存管理结构指针为NULL
        memset(&(proc->context), 0, sizeof(struct context)); // 初始化上下文结构体，全部设为0，为后续保存现场做准备
ffffffffc0203f6c:	07000613          	li	a2,112
ffffffffc0203f70:	4581                	li	a1,0
        proc->runs = 0;                             // 初始化运行次数为0
ffffffffc0203f72:	00052423          	sw	zero,8(a0) # ffffffffc8000008 <end+0x7d403ec>
        proc->kstack = 0;                           // 初始化内核栈为0（空指针），后续通过setup_kstack()为进程分配实际的内核栈空间
ffffffffc0203f76:	00053823          	sd	zero,16(a0)
        proc->need_resched = 0;                     // 初始化不需要重新调度
ffffffffc0203f7a:	00053c23          	sd	zero,24(a0)
        proc->parent = NULL;                        // 初始化父进程指针为NULL
ffffffffc0203f7e:	02053023          	sd	zero,32(a0)
        proc->mm = NULL;                            // 初始化内存管理结构指针为NULL
ffffffffc0203f82:	02053423          	sd	zero,40(a0)
        memset(&(proc->context), 0, sizeof(struct context)); // 初始化上下文结构体，全部设为0，为后续保存现场做准备
ffffffffc0203f86:	03050513          	addi	a0,a0,48
ffffffffc0203f8a:	0b3010ef          	jal	ra,ffffffffc020583c <memset>
        proc->tf = NULL;                            // 初始化陷阱帧为NULL
        proc->pgdir = boot_pgdir_pa;                // 初始化页目录表基址为boot_pgdir_pa
ffffffffc0203f8e:	000bc797          	auipc	a5,0xbc
ffffffffc0203f92:	c427b783          	ld	a5,-958(a5) # ffffffffc02bfbd0 <boot_pgdir_pa>
ffffffffc0203f96:	f45c                	sd	a5,168(s0)
        proc->tf = NULL;                            // 初始化陷阱帧为NULL
ffffffffc0203f98:	0a043023          	sd	zero,160(s0)
        proc->flags = 0;                            // 初始化进程标志为0
ffffffffc0203f9c:	0a042823          	sw	zero,176(s0)
        memset(proc->name, 0, PROC_NAME_LEN + 1);   // 初始化进程名称数组全部清零，后续通过set_proc_name()设置具体的进程名称
ffffffffc0203fa0:	4641                	li	a2,16
ffffffffc0203fa2:	4581                	li	a1,0
ffffffffc0203fa4:	0b440513          	addi	a0,s0,180
ffffffffc0203fa8:	095010ef          	jal	ra,ffffffffc020583c <memset>
        list_init(&(proc->list_link));
ffffffffc0203fac:	0c840713          	addi	a4,s0,200
        list_init(&(proc->hash_link));
ffffffffc0203fb0:	0d840793          	addi	a5,s0,216
    elm->prev = elm->next = elm;
ffffffffc0203fb4:	e878                	sd	a4,208(s0)
ffffffffc0203fb6:	e478                	sd	a4,200(s0)
ffffffffc0203fb8:	f07c                	sd	a5,224(s0)
ffffffffc0203fba:	ec7c                	sd	a5,216(s0)
     
        // LAB5新增     
        proc->wait_state = 0;      // 设置进程的等待状态为0，表示进程当前不在等待状态
ffffffffc0203fbc:	0e042623          	sw	zero,236(s0)
        proc->cptr = NULL;         // 初始化子进程指针为NULL
ffffffffc0203fc0:	0e043823          	sd	zero,240(s0)
        proc->optr = NULL;         // 初始化较年长兄弟进程(older sibling pointer)指针为NULL
ffffffffc0203fc4:	10043023          	sd	zero,256(s0)
        proc->yptr = NULL;         // 初始化较年轻兄弟进程(younger sibling pointer)指针为NULL
ffffffffc0203fc8:	0e043c23          	sd	zero,248(s0)
    }
    return proc;
}
ffffffffc0203fcc:	60a2                	ld	ra,8(sp)
ffffffffc0203fce:	8522                	mv	a0,s0
ffffffffc0203fd0:	6402                	ld	s0,0(sp)
ffffffffc0203fd2:	0141                	addi	sp,sp,16
ffffffffc0203fd4:	8082                	ret

ffffffffc0203fd6 <forkret>:
// NOTE: the addr of forkret is setted in copy_thread function
//       after switch_to, the current proc will execute here.
static void
forkret(void)
{
    forkrets(current->tf);
ffffffffc0203fd6:	000bc797          	auipc	a5,0xbc
ffffffffc0203fda:	c2a7b783          	ld	a5,-982(a5) # ffffffffc02bfc00 <current>
ffffffffc0203fde:	73c8                	ld	a0,160(a5)
ffffffffc0203fe0:	9cafd06f          	j	ffffffffc02011aa <forkrets>

ffffffffc0203fe4 <user_main>:
// user_main - kernel thread used to exec a user program
static int
user_main(void *arg)
{
#ifdef TEST
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc0203fe4:	000bc797          	auipc	a5,0xbc
ffffffffc0203fe8:	c1c7b783          	ld	a5,-996(a5) # ffffffffc02bfc00 <current>
ffffffffc0203fec:	43cc                	lw	a1,4(a5)
{
ffffffffc0203fee:	7139                	addi	sp,sp,-64
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc0203ff0:	00003617          	auipc	a2,0x3
ffffffffc0203ff4:	0f060613          	addi	a2,a2,240 # ffffffffc02070e0 <default_pmm_manager+0x980>
ffffffffc0203ff8:	00003517          	auipc	a0,0x3
ffffffffc0203ffc:	0f850513          	addi	a0,a0,248 # ffffffffc02070f0 <default_pmm_manager+0x990>
{
ffffffffc0204000:	fc06                	sd	ra,56(sp)
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc0204002:	992fc0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc0204006:	3fe06797          	auipc	a5,0x3fe06
ffffffffc020400a:	53278793          	addi	a5,a5,1330 # a538 <_binary_obj___user_dirtycow_test_out_size>
ffffffffc020400e:	e43e                	sd	a5,8(sp)
ffffffffc0204010:	00003517          	auipc	a0,0x3
ffffffffc0204014:	0d050513          	addi	a0,a0,208 # ffffffffc02070e0 <default_pmm_manager+0x980>
ffffffffc0204018:	00027797          	auipc	a5,0x27
ffffffffc020401c:	d4878793          	addi	a5,a5,-696 # ffffffffc022ad60 <_binary_obj___user_dirtycow_test_out_start>
ffffffffc0204020:	f03e                	sd	a5,32(sp)
ffffffffc0204022:	f42a                	sd	a0,40(sp)
    int64_t ret = 0, len = strlen(name);
ffffffffc0204024:	e802                	sd	zero,16(sp)
ffffffffc0204026:	774010ef          	jal	ra,ffffffffc020579a <strlen>
ffffffffc020402a:	ec2a                	sd	a0,24(sp)
    asm volatile(
ffffffffc020402c:	4511                	li	a0,4
ffffffffc020402e:	55a2                	lw	a1,40(sp)
ffffffffc0204030:	4662                	lw	a2,24(sp)
ffffffffc0204032:	5682                	lw	a3,32(sp)
ffffffffc0204034:	4722                	lw	a4,8(sp)
ffffffffc0204036:	48a9                	li	a7,10
ffffffffc0204038:	9002                	ebreak
ffffffffc020403a:	c82a                	sw	a0,16(sp)
    cprintf("ret = %d\n", ret);
ffffffffc020403c:	65c2                	ld	a1,16(sp)
ffffffffc020403e:	00003517          	auipc	a0,0x3
ffffffffc0204042:	0da50513          	addi	a0,a0,218 # ffffffffc0207118 <default_pmm_manager+0x9b8>
ffffffffc0204046:	94efc0ef          	jal	ra,ffffffffc0200194 <cprintf>
#else
    KERNEL_EXECVE(exit);
#endif
    panic("user_main execve failed.\n");
ffffffffc020404a:	00003617          	auipc	a2,0x3
ffffffffc020404e:	0de60613          	addi	a2,a2,222 # ffffffffc0207128 <default_pmm_manager+0x9c8>
ffffffffc0204052:	3db00593          	li	a1,987
ffffffffc0204056:	00003517          	auipc	a0,0x3
ffffffffc020405a:	0f250513          	addi	a0,a0,242 # ffffffffc0207148 <default_pmm_manager+0x9e8>
ffffffffc020405e:	c30fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0204062 <put_pgdir>:
    return pa2page(PADDR(kva));
ffffffffc0204062:	6d14                	ld	a3,24(a0)
{
ffffffffc0204064:	1141                	addi	sp,sp,-16
ffffffffc0204066:	e406                	sd	ra,8(sp)
ffffffffc0204068:	c02007b7          	lui	a5,0xc0200
ffffffffc020406c:	02f6ee63          	bltu	a3,a5,ffffffffc02040a8 <put_pgdir+0x46>
ffffffffc0204070:	000bc517          	auipc	a0,0xbc
ffffffffc0204074:	b8853503          	ld	a0,-1144(a0) # ffffffffc02bfbf8 <va_pa_offset>
ffffffffc0204078:	8e89                	sub	a3,a3,a0
    if (PPN(pa) >= npage)
ffffffffc020407a:	82b1                	srli	a3,a3,0xc
ffffffffc020407c:	000bc797          	auipc	a5,0xbc
ffffffffc0204080:	b647b783          	ld	a5,-1180(a5) # ffffffffc02bfbe0 <npage>
ffffffffc0204084:	02f6fe63          	bgeu	a3,a5,ffffffffc02040c0 <put_pgdir+0x5e>
    return &pages[PPN(pa) - nbase];
ffffffffc0204088:	00004517          	auipc	a0,0x4
ffffffffc020408c:	95853503          	ld	a0,-1704(a0) # ffffffffc02079e0 <nbase>
}
ffffffffc0204090:	60a2                	ld	ra,8(sp)
ffffffffc0204092:	8e89                	sub	a3,a3,a0
ffffffffc0204094:	069a                	slli	a3,a3,0x6
    free_page(kva2page(mm->pgdir));
ffffffffc0204096:	000bc517          	auipc	a0,0xbc
ffffffffc020409a:	b5253503          	ld	a0,-1198(a0) # ffffffffc02bfbe8 <pages>
ffffffffc020409e:	4585                	li	a1,1
ffffffffc02040a0:	9536                	add	a0,a0,a3
}
ffffffffc02040a2:	0141                	addi	sp,sp,16
    free_page(kva2page(mm->pgdir));
ffffffffc02040a4:	8aefe06f          	j	ffffffffc0202152 <free_pages>
    return pa2page(PADDR(kva));
ffffffffc02040a8:	00002617          	auipc	a2,0x2
ffffffffc02040ac:	76060613          	addi	a2,a2,1888 # ffffffffc0206808 <default_pmm_manager+0xa8>
ffffffffc02040b0:	07700593          	li	a1,119
ffffffffc02040b4:	00002517          	auipc	a0,0x2
ffffffffc02040b8:	ff450513          	addi	a0,a0,-12 # ffffffffc02060a8 <commands+0x5d8>
ffffffffc02040bc:	bd2fc0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("pa2page called with invalid pa");
ffffffffc02040c0:	00002617          	auipc	a2,0x2
ffffffffc02040c4:	fc860613          	addi	a2,a2,-56 # ffffffffc0206088 <commands+0x5b8>
ffffffffc02040c8:	06900593          	li	a1,105
ffffffffc02040cc:	00002517          	auipc	a0,0x2
ffffffffc02040d0:	fdc50513          	addi	a0,a0,-36 # ffffffffc02060a8 <commands+0x5d8>
ffffffffc02040d4:	bbafc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02040d8 <proc_run>:
{
ffffffffc02040d8:	7179                	addi	sp,sp,-48
ffffffffc02040da:	f026                	sd	s1,32(sp)
    if (proc != current)
ffffffffc02040dc:	000bc497          	auipc	s1,0xbc
ffffffffc02040e0:	b2448493          	addi	s1,s1,-1244 # ffffffffc02bfc00 <current>
ffffffffc02040e4:	6098                	ld	a4,0(s1)
{
ffffffffc02040e6:	f406                	sd	ra,40(sp)
ffffffffc02040e8:	ec4a                	sd	s2,24(sp)
    if (proc != current)
ffffffffc02040ea:	02a70a63          	beq	a4,a0,ffffffffc020411e <proc_run+0x46>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02040ee:	100027f3          	csrr	a5,sstatus
ffffffffc02040f2:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02040f4:	4901                	li	s2,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02040f6:	ef9d                	bnez	a5,ffffffffc0204134 <proc_run+0x5c>
        current->runs++;
ffffffffc02040f8:	4514                	lw	a3,8(a0)
#define barrier() __asm__ __volatile__("fence" ::: "memory")

static inline void
lsatp(unsigned long pgdir)
{
  write_csr(satp, 0x8000000000000000 | (pgdir >> RISCV_PGSHIFT));
ffffffffc02040fa:	755c                	ld	a5,168(a0)
        current = proc;
ffffffffc02040fc:	e088                	sd	a0,0(s1)
        current->runs++;
ffffffffc02040fe:	2685                	addiw	a3,a3,1
ffffffffc0204100:	c514                	sw	a3,8(a0)
ffffffffc0204102:	56fd                	li	a3,-1
ffffffffc0204104:	16fe                	slli	a3,a3,0x3f
ffffffffc0204106:	83b1                	srli	a5,a5,0xc
ffffffffc0204108:	8fd5                	or	a5,a5,a3
ffffffffc020410a:	18079073          	csrw	satp,a5
        switch_to(&prev->context, &current->context);
ffffffffc020410e:	03050593          	addi	a1,a0,48
ffffffffc0204112:	03070513          	addi	a0,a4,48
ffffffffc0204116:	02a010ef          	jal	ra,ffffffffc0205140 <switch_to>
    if (flag)
ffffffffc020411a:	00091763          	bnez	s2,ffffffffc0204128 <proc_run+0x50>
}
ffffffffc020411e:	70a2                	ld	ra,40(sp)
ffffffffc0204120:	7482                	ld	s1,32(sp)
ffffffffc0204122:	6962                	ld	s2,24(sp)
ffffffffc0204124:	6145                	addi	sp,sp,48
ffffffffc0204126:	8082                	ret
ffffffffc0204128:	70a2                	ld	ra,40(sp)
ffffffffc020412a:	7482                	ld	s1,32(sp)
ffffffffc020412c:	6962                	ld	s2,24(sp)
ffffffffc020412e:	6145                	addi	sp,sp,48
        intr_enable();
ffffffffc0204130:	87ffc06f          	j	ffffffffc02009ae <intr_enable>
ffffffffc0204134:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0204136:	87ffc0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        struct proc_struct *prev = current;
ffffffffc020413a:	6098                	ld	a4,0(s1)
        return 1;
ffffffffc020413c:	6522                	ld	a0,8(sp)
ffffffffc020413e:	4905                	li	s2,1
ffffffffc0204140:	bf65                	j	ffffffffc02040f8 <proc_run+0x20>

ffffffffc0204142 <do_fork>:
{
ffffffffc0204142:	7119                	addi	sp,sp,-128
ffffffffc0204144:	f0ca                	sd	s2,96(sp)
    if (nr_process >= MAX_PROCESS)
ffffffffc0204146:	000bc917          	auipc	s2,0xbc
ffffffffc020414a:	ad290913          	addi	s2,s2,-1326 # ffffffffc02bfc18 <nr_process>
ffffffffc020414e:	00092703          	lw	a4,0(s2)
{
ffffffffc0204152:	fc86                	sd	ra,120(sp)
ffffffffc0204154:	f8a2                	sd	s0,112(sp)
ffffffffc0204156:	f4a6                	sd	s1,104(sp)
ffffffffc0204158:	ecce                	sd	s3,88(sp)
ffffffffc020415a:	e8d2                	sd	s4,80(sp)
ffffffffc020415c:	e4d6                	sd	s5,72(sp)
ffffffffc020415e:	e0da                	sd	s6,64(sp)
ffffffffc0204160:	fc5e                	sd	s7,56(sp)
ffffffffc0204162:	f862                	sd	s8,48(sp)
ffffffffc0204164:	f466                	sd	s9,40(sp)
ffffffffc0204166:	f06a                	sd	s10,32(sp)
ffffffffc0204168:	ec6e                	sd	s11,24(sp)
    if (nr_process >= MAX_PROCESS)
ffffffffc020416a:	6785                	lui	a5,0x1
ffffffffc020416c:	32f75663          	bge	a4,a5,ffffffffc0204498 <do_fork+0x356>
ffffffffc0204170:	8a2a                	mv	s4,a0
ffffffffc0204172:	89ae                	mv	s3,a1
ffffffffc0204174:	8432                	mv	s0,a2
    if ((proc = alloc_proc()) == NULL) {
ffffffffc0204176:	ddfff0ef          	jal	ra,ffffffffc0203f54 <alloc_proc>
ffffffffc020417a:	84aa                	mv	s1,a0
ffffffffc020417c:	2e050f63          	beqz	a0,ffffffffc020447a <do_fork+0x338>
    proc->parent = current;
ffffffffc0204180:	000bcc17          	auipc	s8,0xbc
ffffffffc0204184:	a80c0c13          	addi	s8,s8,-1408 # ffffffffc02bfc00 <current>
ffffffffc0204188:	000c3783          	ld	a5,0(s8)
    struct Page *page = alloc_pages(KSTACKPAGE);
ffffffffc020418c:	4509                	li	a0,2
    proc->parent = current;
ffffffffc020418e:	f09c                	sd	a5,32(s1)
    struct Page *page = alloc_pages(KSTACKPAGE);
ffffffffc0204190:	f85fd0ef          	jal	ra,ffffffffc0202114 <alloc_pages>
    if (page != NULL)
ffffffffc0204194:	2e050063          	beqz	a0,ffffffffc0204474 <do_fork+0x332>
    return page - pages + nbase;
ffffffffc0204198:	000bca97          	auipc	s5,0xbc
ffffffffc020419c:	a50a8a93          	addi	s5,s5,-1456 # ffffffffc02bfbe8 <pages>
ffffffffc02041a0:	000ab683          	ld	a3,0(s5)
ffffffffc02041a4:	00004b17          	auipc	s6,0x4
ffffffffc02041a8:	83cb0b13          	addi	s6,s6,-1988 # ffffffffc02079e0 <nbase>
ffffffffc02041ac:	000b3783          	ld	a5,0(s6)
ffffffffc02041b0:	40d506b3          	sub	a3,a0,a3
    return KADDR(page2pa(page));
ffffffffc02041b4:	000bcb97          	auipc	s7,0xbc
ffffffffc02041b8:	a2cb8b93          	addi	s7,s7,-1492 # ffffffffc02bfbe0 <npage>
    return page - pages + nbase;
ffffffffc02041bc:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc02041be:	5dfd                	li	s11,-1
ffffffffc02041c0:	000bb703          	ld	a4,0(s7)
    return page - pages + nbase;
ffffffffc02041c4:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc02041c6:	00cddd93          	srli	s11,s11,0xc
ffffffffc02041ca:	01b6f633          	and	a2,a3,s11
    return page2ppn(page) << PGSHIFT;
ffffffffc02041ce:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02041d0:	32e67a63          	bgeu	a2,a4,ffffffffc0204504 <do_fork+0x3c2>
    struct mm_struct *mm, *oldmm = current->mm;
ffffffffc02041d4:	000c3603          	ld	a2,0(s8)
ffffffffc02041d8:	000bcc17          	auipc	s8,0xbc
ffffffffc02041dc:	a20c0c13          	addi	s8,s8,-1504 # ffffffffc02bfbf8 <va_pa_offset>
ffffffffc02041e0:	000c3703          	ld	a4,0(s8)
ffffffffc02041e4:	02863d03          	ld	s10,40(a2)
ffffffffc02041e8:	e43e                	sd	a5,8(sp)
ffffffffc02041ea:	96ba                	add	a3,a3,a4
        proc->kstack = (uintptr_t)page2kva(page);
ffffffffc02041ec:	e894                	sd	a3,16(s1)
    if (oldmm == NULL)
ffffffffc02041ee:	020d0863          	beqz	s10,ffffffffc020421e <do_fork+0xdc>
    if (clone_flags & CLONE_VM)
ffffffffc02041f2:	100a7a13          	andi	s4,s4,256
ffffffffc02041f6:	1c0a0163          	beqz	s4,ffffffffc02043b8 <do_fork+0x276>
}

static inline int
mm_count_inc(struct mm_struct *mm)
{
    mm->mm_count += 1;
ffffffffc02041fa:	030d2703          	lw	a4,48(s10) # 200030 <_binary_obj___user_exit_out_size+0x1f4ef0>
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc02041fe:	018d3783          	ld	a5,24(s10)
ffffffffc0204202:	c02006b7          	lui	a3,0xc0200
ffffffffc0204206:	2705                	addiw	a4,a4,1
ffffffffc0204208:	02ed2823          	sw	a4,48(s10)
    proc->mm = mm;
ffffffffc020420c:	03a4b423          	sd	s10,40(s1)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc0204210:	2cd7e163          	bltu	a5,a3,ffffffffc02044d2 <do_fork+0x390>
ffffffffc0204214:	000c3703          	ld	a4,0(s8)
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc0204218:	6894                	ld	a3,16(s1)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc020421a:	8f99                	sub	a5,a5,a4
ffffffffc020421c:	f4dc                	sd	a5,168(s1)
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc020421e:	6789                	lui	a5,0x2
ffffffffc0204220:	ee078793          	addi	a5,a5,-288 # 1ee0 <_binary_obj___user_faultread_out_size-0x7cf0>
ffffffffc0204224:	96be                	add	a3,a3,a5
    *(proc->tf) = *tf;
ffffffffc0204226:	8622                	mv	a2,s0
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc0204228:	f0d4                	sd	a3,160(s1)
    *(proc->tf) = *tf;
ffffffffc020422a:	87b6                	mv	a5,a3
ffffffffc020422c:	12040893          	addi	a7,s0,288
ffffffffc0204230:	00063803          	ld	a6,0(a2)
ffffffffc0204234:	6608                	ld	a0,8(a2)
ffffffffc0204236:	6a0c                	ld	a1,16(a2)
ffffffffc0204238:	6e18                	ld	a4,24(a2)
ffffffffc020423a:	0107b023          	sd	a6,0(a5)
ffffffffc020423e:	e788                	sd	a0,8(a5)
ffffffffc0204240:	eb8c                	sd	a1,16(a5)
ffffffffc0204242:	ef98                	sd	a4,24(a5)
ffffffffc0204244:	02060613          	addi	a2,a2,32
ffffffffc0204248:	02078793          	addi	a5,a5,32
ffffffffc020424c:	ff1612e3          	bne	a2,a7,ffffffffc0204230 <do_fork+0xee>
    proc->tf->gpr.a0 = 0;
ffffffffc0204250:	0406b823          	sd	zero,80(a3) # ffffffffc0200050 <kern_init+0x6>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc0204254:	12098f63          	beqz	s3,ffffffffc0204392 <do_fork+0x250>
ffffffffc0204258:	0136b823          	sd	s3,16(a3)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc020425c:	00000797          	auipc	a5,0x0
ffffffffc0204260:	d7a78793          	addi	a5,a5,-646 # ffffffffc0203fd6 <forkret>
ffffffffc0204264:	f89c                	sd	a5,48(s1)
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc0204266:	fc94                	sd	a3,56(s1)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204268:	100027f3          	csrr	a5,sstatus
ffffffffc020426c:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc020426e:	4981                	li	s3,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204270:	14079063          	bnez	a5,ffffffffc02043b0 <do_fork+0x26e>
    if (++last_pid >= MAX_PID)
ffffffffc0204274:	000b7817          	auipc	a6,0xb7
ffffffffc0204278:	4fc80813          	addi	a6,a6,1276 # ffffffffc02bb770 <last_pid.1>
ffffffffc020427c:	00082783          	lw	a5,0(a6)
ffffffffc0204280:	6709                	lui	a4,0x2
ffffffffc0204282:	0017851b          	addiw	a0,a5,1
ffffffffc0204286:	00a82023          	sw	a0,0(a6)
ffffffffc020428a:	08e55d63          	bge	a0,a4,ffffffffc0204324 <do_fork+0x1e2>
    if (last_pid >= next_safe)
ffffffffc020428e:	000b7317          	auipc	t1,0xb7
ffffffffc0204292:	4e630313          	addi	t1,t1,1254 # ffffffffc02bb774 <next_safe.0>
ffffffffc0204296:	00032783          	lw	a5,0(t1)
ffffffffc020429a:	000bc417          	auipc	s0,0xbc
ffffffffc020429e:	8f640413          	addi	s0,s0,-1802 # ffffffffc02bfb90 <proc_list>
ffffffffc02042a2:	08f55963          	bge	a0,a5,ffffffffc0204334 <do_fork+0x1f2>
        proc->pid = get_pid();
ffffffffc02042a6:	c0c8                	sw	a0,4(s1)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc02042a8:	45a9                	li	a1,10
ffffffffc02042aa:	2501                	sext.w	a0,a0
ffffffffc02042ac:	0ea010ef          	jal	ra,ffffffffc0205396 <hash32>
ffffffffc02042b0:	02051793          	slli	a5,a0,0x20
ffffffffc02042b4:	01c7d513          	srli	a0,a5,0x1c
ffffffffc02042b8:	000b8797          	auipc	a5,0xb8
ffffffffc02042bc:	8d878793          	addi	a5,a5,-1832 # ffffffffc02bbb90 <hash_list>
ffffffffc02042c0:	953e                	add	a0,a0,a5
    __list_add(elm, listelm, listelm->next);
ffffffffc02042c2:	650c                	ld	a1,8(a0)
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc02042c4:	7094                	ld	a3,32(s1)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc02042c6:	0d848793          	addi	a5,s1,216
    prev->next = next->prev = elm;
ffffffffc02042ca:	e19c                	sd	a5,0(a1)
    __list_add(elm, listelm, listelm->next);
ffffffffc02042cc:	6410                	ld	a2,8(s0)
    prev->next = next->prev = elm;
ffffffffc02042ce:	e51c                	sd	a5,8(a0)
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc02042d0:	7af8                	ld	a4,240(a3)
    list_add(&proc_list, &(proc->list_link));
ffffffffc02042d2:	0c848793          	addi	a5,s1,200
    elm->next = next;
ffffffffc02042d6:	f0ec                	sd	a1,224(s1)
    elm->prev = prev;
ffffffffc02042d8:	ece8                	sd	a0,216(s1)
    prev->next = next->prev = elm;
ffffffffc02042da:	e21c                	sd	a5,0(a2)
ffffffffc02042dc:	e41c                	sd	a5,8(s0)
    elm->next = next;
ffffffffc02042de:	e8f0                	sd	a2,208(s1)
    elm->prev = prev;
ffffffffc02042e0:	e4e0                	sd	s0,200(s1)
    proc->yptr = NULL;
ffffffffc02042e2:	0e04bc23          	sd	zero,248(s1)
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc02042e6:	10e4b023          	sd	a4,256(s1)
ffffffffc02042ea:	c311                	beqz	a4,ffffffffc02042ee <do_fork+0x1ac>
        proc->optr->yptr = proc;
ffffffffc02042ec:	ff64                	sd	s1,248(a4)
    nr_process++;
ffffffffc02042ee:	00092783          	lw	a5,0(s2)
    proc->parent->cptr = proc;
ffffffffc02042f2:	fae4                	sd	s1,240(a3)
    nr_process++;
ffffffffc02042f4:	2785                	addiw	a5,a5,1
ffffffffc02042f6:	00f92023          	sw	a5,0(s2)
    if (flag)
ffffffffc02042fa:	18099263          	bnez	s3,ffffffffc020447e <do_fork+0x33c>
    wakeup_proc(proc);
ffffffffc02042fe:	8526                	mv	a0,s1
ffffffffc0204300:	6ab000ef          	jal	ra,ffffffffc02051aa <wakeup_proc>
    ret = proc->pid;
ffffffffc0204304:	40c8                	lw	a0,4(s1)
}
ffffffffc0204306:	70e6                	ld	ra,120(sp)
ffffffffc0204308:	7446                	ld	s0,112(sp)
ffffffffc020430a:	74a6                	ld	s1,104(sp)
ffffffffc020430c:	7906                	ld	s2,96(sp)
ffffffffc020430e:	69e6                	ld	s3,88(sp)
ffffffffc0204310:	6a46                	ld	s4,80(sp)
ffffffffc0204312:	6aa6                	ld	s5,72(sp)
ffffffffc0204314:	6b06                	ld	s6,64(sp)
ffffffffc0204316:	7be2                	ld	s7,56(sp)
ffffffffc0204318:	7c42                	ld	s8,48(sp)
ffffffffc020431a:	7ca2                	ld	s9,40(sp)
ffffffffc020431c:	7d02                	ld	s10,32(sp)
ffffffffc020431e:	6de2                	ld	s11,24(sp)
ffffffffc0204320:	6109                	addi	sp,sp,128
ffffffffc0204322:	8082                	ret
        last_pid = 1;
ffffffffc0204324:	4785                	li	a5,1
ffffffffc0204326:	00f82023          	sw	a5,0(a6)
        goto inside;
ffffffffc020432a:	4505                	li	a0,1
ffffffffc020432c:	000b7317          	auipc	t1,0xb7
ffffffffc0204330:	44830313          	addi	t1,t1,1096 # ffffffffc02bb774 <next_safe.0>
    return listelm->next;
ffffffffc0204334:	000bc417          	auipc	s0,0xbc
ffffffffc0204338:	85c40413          	addi	s0,s0,-1956 # ffffffffc02bfb90 <proc_list>
ffffffffc020433c:	00843e03          	ld	t3,8(s0)
        next_safe = MAX_PID;
ffffffffc0204340:	6789                	lui	a5,0x2
ffffffffc0204342:	00f32023          	sw	a5,0(t1)
ffffffffc0204346:	86aa                	mv	a3,a0
ffffffffc0204348:	4581                	li	a1,0
        while ((le = list_next(le)) != list)
ffffffffc020434a:	6e89                	lui	t4,0x2
ffffffffc020434c:	148e0163          	beq	t3,s0,ffffffffc020448e <do_fork+0x34c>
ffffffffc0204350:	88ae                	mv	a7,a1
ffffffffc0204352:	87f2                	mv	a5,t3
ffffffffc0204354:	6609                	lui	a2,0x2
ffffffffc0204356:	a811                	j	ffffffffc020436a <do_fork+0x228>
            else if (proc->pid > last_pid && next_safe > proc->pid)
ffffffffc0204358:	00e6d663          	bge	a3,a4,ffffffffc0204364 <do_fork+0x222>
ffffffffc020435c:	00c75463          	bge	a4,a2,ffffffffc0204364 <do_fork+0x222>
ffffffffc0204360:	863a                	mv	a2,a4
ffffffffc0204362:	4885                	li	a7,1
ffffffffc0204364:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc0204366:	00878d63          	beq	a5,s0,ffffffffc0204380 <do_fork+0x23e>
            if (proc->pid == last_pid)
ffffffffc020436a:	f3c7a703          	lw	a4,-196(a5) # 1f3c <_binary_obj___user_faultread_out_size-0x7c94>
ffffffffc020436e:	fed715e3          	bne	a4,a3,ffffffffc0204358 <do_fork+0x216>
                if (++last_pid >= next_safe)
ffffffffc0204372:	2685                	addiw	a3,a3,1
ffffffffc0204374:	10c6d863          	bge	a3,a2,ffffffffc0204484 <do_fork+0x342>
ffffffffc0204378:	679c                	ld	a5,8(a5)
ffffffffc020437a:	4585                	li	a1,1
        while ((le = list_next(le)) != list)
ffffffffc020437c:	fe8797e3          	bne	a5,s0,ffffffffc020436a <do_fork+0x228>
ffffffffc0204380:	c581                	beqz	a1,ffffffffc0204388 <do_fork+0x246>
ffffffffc0204382:	00d82023          	sw	a3,0(a6)
ffffffffc0204386:	8536                	mv	a0,a3
ffffffffc0204388:	f0088fe3          	beqz	a7,ffffffffc02042a6 <do_fork+0x164>
ffffffffc020438c:	00c32023          	sw	a2,0(t1)
ffffffffc0204390:	bf19                	j	ffffffffc02042a6 <do_fork+0x164>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc0204392:	89b6                	mv	s3,a3
ffffffffc0204394:	0136b823          	sd	s3,16(a3)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc0204398:	00000797          	auipc	a5,0x0
ffffffffc020439c:	c3e78793          	addi	a5,a5,-962 # ffffffffc0203fd6 <forkret>
ffffffffc02043a0:	f89c                	sd	a5,48(s1)
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc02043a2:	fc94                	sd	a3,56(s1)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02043a4:	100027f3          	csrr	a5,sstatus
ffffffffc02043a8:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02043aa:	4981                	li	s3,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02043ac:	ec0784e3          	beqz	a5,ffffffffc0204274 <do_fork+0x132>
        intr_disable();
ffffffffc02043b0:	e04fc0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc02043b4:	4985                	li	s3,1
ffffffffc02043b6:	bd7d                	j	ffffffffc0204274 <do_fork+0x132>
    if ((mm = mm_create()) == NULL)
ffffffffc02043b8:	c8aff0ef          	jal	ra,ffffffffc0203842 <mm_create>
ffffffffc02043bc:	8caa                	mv	s9,a0
ffffffffc02043be:	c159                	beqz	a0,ffffffffc0204444 <do_fork+0x302>
    if ((page = alloc_page()) == NULL)
ffffffffc02043c0:	4505                	li	a0,1
ffffffffc02043c2:	d53fd0ef          	jal	ra,ffffffffc0202114 <alloc_pages>
ffffffffc02043c6:	cd25                	beqz	a0,ffffffffc020443e <do_fork+0x2fc>
    return page - pages + nbase;
ffffffffc02043c8:	000ab683          	ld	a3,0(s5)
ffffffffc02043cc:	67a2                	ld	a5,8(sp)
    return KADDR(page2pa(page));
ffffffffc02043ce:	000bb703          	ld	a4,0(s7)
    return page - pages + nbase;
ffffffffc02043d2:	40d506b3          	sub	a3,a0,a3
ffffffffc02043d6:	8699                	srai	a3,a3,0x6
ffffffffc02043d8:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc02043da:	01b6fdb3          	and	s11,a3,s11
    return page2ppn(page) << PGSHIFT;
ffffffffc02043de:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02043e0:	12edf263          	bgeu	s11,a4,ffffffffc0204504 <do_fork+0x3c2>
ffffffffc02043e4:	000c3a03          	ld	s4,0(s8)
    memcpy(pgdir, boot_pgdir_va, PGSIZE);
ffffffffc02043e8:	6605                	lui	a2,0x1
ffffffffc02043ea:	000bb597          	auipc	a1,0xbb
ffffffffc02043ee:	7ee5b583          	ld	a1,2030(a1) # ffffffffc02bfbd8 <boot_pgdir_va>
ffffffffc02043f2:	9a36                	add	s4,s4,a3
ffffffffc02043f4:	8552                	mv	a0,s4
ffffffffc02043f6:	458010ef          	jal	ra,ffffffffc020584e <memcpy>
static inline void
lock_mm(struct mm_struct *mm)
{
    if (mm != NULL)
    {
        lock(&(mm->mm_lock));
ffffffffc02043fa:	038d0d93          	addi	s11,s10,56
    mm->pgdir = pgdir;
ffffffffc02043fe:	014cbc23          	sd	s4,24(s9) # ffffffffffe00018 <end+0x3fb403fc>
 * test_and_set_bit - Atomically set a bit and return its old value
 * @nr:     the bit to set
 * @addr:   the address to count from
 * */
static inline bool test_and_set_bit(int nr, volatile void *addr) {
    return __test_and_op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0204402:	4785                	li	a5,1
ffffffffc0204404:	40fdb7af          	amoor.d	a5,a5,(s11)
}

static inline void
lock(lock_t *lock)
{
    while (!try_lock(lock))
ffffffffc0204408:	8b85                	andi	a5,a5,1
ffffffffc020440a:	4a05                	li	s4,1
ffffffffc020440c:	c799                	beqz	a5,ffffffffc020441a <do_fork+0x2d8>
    {
        schedule();
ffffffffc020440e:	61d000ef          	jal	ra,ffffffffc020522a <schedule>
ffffffffc0204412:	414db7af          	amoor.d	a5,s4,(s11)
    while (!try_lock(lock))
ffffffffc0204416:	8b85                	andi	a5,a5,1
ffffffffc0204418:	fbfd                	bnez	a5,ffffffffc020440e <do_fork+0x2cc>
        ret = dup_mmap(mm, oldmm);
ffffffffc020441a:	85ea                	mv	a1,s10
ffffffffc020441c:	8566                	mv	a0,s9
ffffffffc020441e:	e66ff0ef          	jal	ra,ffffffffc0203a84 <dup_mmap>
 * test_and_clear_bit - Atomically clear a bit and return its old value
 * @nr:     the bit to clear
 * @addr:   the address to count from
 * */
static inline bool test_and_clear_bit(int nr, volatile void *addr) {
    return __test_and_op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0204422:	57f9                	li	a5,-2
ffffffffc0204424:	60fdb7af          	amoand.d	a5,a5,(s11)
ffffffffc0204428:	8b85                	andi	a5,a5,1
}

static inline void
unlock(lock_t *lock)
{
    if (!test_and_clear_bit(0, lock))
ffffffffc020442a:	cfa5                	beqz	a5,ffffffffc02044a2 <do_fork+0x360>
good_mm:
ffffffffc020442c:	8d66                	mv	s10,s9
    if (ret != 0)
ffffffffc020442e:	dc0506e3          	beqz	a0,ffffffffc02041fa <do_fork+0xb8>
    exit_mmap(mm);
ffffffffc0204432:	8566                	mv	a0,s9
ffffffffc0204434:	eeaff0ef          	jal	ra,ffffffffc0203b1e <exit_mmap>
    put_pgdir(mm);
ffffffffc0204438:	8566                	mv	a0,s9
ffffffffc020443a:	c29ff0ef          	jal	ra,ffffffffc0204062 <put_pgdir>
    mm_destroy(mm);
ffffffffc020443e:	8566                	mv	a0,s9
ffffffffc0204440:	d42ff0ef          	jal	ra,ffffffffc0203982 <mm_destroy>
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
ffffffffc0204444:	6894                	ld	a3,16(s1)
    return pa2page(PADDR(kva));
ffffffffc0204446:	c02007b7          	lui	a5,0xc0200
ffffffffc020444a:	0af6e163          	bltu	a3,a5,ffffffffc02044ec <do_fork+0x3aa>
ffffffffc020444e:	000c3783          	ld	a5,0(s8)
    if (PPN(pa) >= npage)
ffffffffc0204452:	000bb703          	ld	a4,0(s7)
    return pa2page(PADDR(kva));
ffffffffc0204456:	40f687b3          	sub	a5,a3,a5
    if (PPN(pa) >= npage)
ffffffffc020445a:	83b1                	srli	a5,a5,0xc
ffffffffc020445c:	04e7ff63          	bgeu	a5,a4,ffffffffc02044ba <do_fork+0x378>
    return &pages[PPN(pa) - nbase];
ffffffffc0204460:	000b3703          	ld	a4,0(s6)
ffffffffc0204464:	000ab503          	ld	a0,0(s5)
ffffffffc0204468:	4589                	li	a1,2
ffffffffc020446a:	8f99                	sub	a5,a5,a4
ffffffffc020446c:	079a                	slli	a5,a5,0x6
ffffffffc020446e:	953e                	add	a0,a0,a5
ffffffffc0204470:	ce3fd0ef          	jal	ra,ffffffffc0202152 <free_pages>
    kfree(proc);
ffffffffc0204474:	8526                	mv	a0,s1
ffffffffc0204476:	b71fd0ef          	jal	ra,ffffffffc0201fe6 <kfree>
    ret = -E_NO_MEM;
ffffffffc020447a:	5571                	li	a0,-4
    return ret;
ffffffffc020447c:	b569                	j	ffffffffc0204306 <do_fork+0x1c4>
        intr_enable();
ffffffffc020447e:	d30fc0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0204482:	bdb5                	j	ffffffffc02042fe <do_fork+0x1bc>
                    if (last_pid >= MAX_PID)
ffffffffc0204484:	01d6c363          	blt	a3,t4,ffffffffc020448a <do_fork+0x348>
                        last_pid = 1;
ffffffffc0204488:	4685                	li	a3,1
                    goto repeat;
ffffffffc020448a:	4585                	li	a1,1
ffffffffc020448c:	b5c1                	j	ffffffffc020434c <do_fork+0x20a>
ffffffffc020448e:	c599                	beqz	a1,ffffffffc020449c <do_fork+0x35a>
ffffffffc0204490:	00d82023          	sw	a3,0(a6)
    return last_pid;
ffffffffc0204494:	8536                	mv	a0,a3
ffffffffc0204496:	bd01                	j	ffffffffc02042a6 <do_fork+0x164>
    int ret = -E_NO_FREE_PROC;
ffffffffc0204498:	556d                	li	a0,-5
ffffffffc020449a:	b5b5                	j	ffffffffc0204306 <do_fork+0x1c4>
    return last_pid;
ffffffffc020449c:	00082503          	lw	a0,0(a6)
ffffffffc02044a0:	b519                	j	ffffffffc02042a6 <do_fork+0x164>
    {
        panic("Unlock failed.\n");
ffffffffc02044a2:	00003617          	auipc	a2,0x3
ffffffffc02044a6:	cbe60613          	addi	a2,a2,-834 # ffffffffc0207160 <default_pmm_manager+0xa00>
ffffffffc02044aa:	03f00593          	li	a1,63
ffffffffc02044ae:	00003517          	auipc	a0,0x3
ffffffffc02044b2:	cc250513          	addi	a0,a0,-830 # ffffffffc0207170 <default_pmm_manager+0xa10>
ffffffffc02044b6:	fd9fb0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("pa2page called with invalid pa");
ffffffffc02044ba:	00002617          	auipc	a2,0x2
ffffffffc02044be:	bce60613          	addi	a2,a2,-1074 # ffffffffc0206088 <commands+0x5b8>
ffffffffc02044c2:	06900593          	li	a1,105
ffffffffc02044c6:	00002517          	auipc	a0,0x2
ffffffffc02044ca:	be250513          	addi	a0,a0,-1054 # ffffffffc02060a8 <commands+0x5d8>
ffffffffc02044ce:	fc1fb0ef          	jal	ra,ffffffffc020048e <__panic>
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc02044d2:	86be                	mv	a3,a5
ffffffffc02044d4:	00002617          	auipc	a2,0x2
ffffffffc02044d8:	33460613          	addi	a2,a2,820 # ffffffffc0206808 <default_pmm_manager+0xa8>
ffffffffc02044dc:	19e00593          	li	a1,414
ffffffffc02044e0:	00003517          	auipc	a0,0x3
ffffffffc02044e4:	c6850513          	addi	a0,a0,-920 # ffffffffc0207148 <default_pmm_manager+0x9e8>
ffffffffc02044e8:	fa7fb0ef          	jal	ra,ffffffffc020048e <__panic>
    return pa2page(PADDR(kva));
ffffffffc02044ec:	00002617          	auipc	a2,0x2
ffffffffc02044f0:	31c60613          	addi	a2,a2,796 # ffffffffc0206808 <default_pmm_manager+0xa8>
ffffffffc02044f4:	07700593          	li	a1,119
ffffffffc02044f8:	00002517          	auipc	a0,0x2
ffffffffc02044fc:	bb050513          	addi	a0,a0,-1104 # ffffffffc02060a8 <commands+0x5d8>
ffffffffc0204500:	f8ffb0ef          	jal	ra,ffffffffc020048e <__panic>
    return KADDR(page2pa(page));
ffffffffc0204504:	00002617          	auipc	a2,0x2
ffffffffc0204508:	bb460613          	addi	a2,a2,-1100 # ffffffffc02060b8 <commands+0x5e8>
ffffffffc020450c:	07100593          	li	a1,113
ffffffffc0204510:	00002517          	auipc	a0,0x2
ffffffffc0204514:	b9850513          	addi	a0,a0,-1128 # ffffffffc02060a8 <commands+0x5d8>
ffffffffc0204518:	f77fb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc020451c <kernel_thread>:
{
ffffffffc020451c:	7129                	addi	sp,sp,-320
ffffffffc020451e:	fa22                	sd	s0,304(sp)
ffffffffc0204520:	f626                	sd	s1,296(sp)
ffffffffc0204522:	f24a                	sd	s2,288(sp)
ffffffffc0204524:	84ae                	mv	s1,a1
ffffffffc0204526:	892a                	mv	s2,a0
ffffffffc0204528:	8432                	mv	s0,a2
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc020452a:	4581                	li	a1,0
ffffffffc020452c:	12000613          	li	a2,288
ffffffffc0204530:	850a                	mv	a0,sp
{
ffffffffc0204532:	fe06                	sd	ra,312(sp)
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc0204534:	308010ef          	jal	ra,ffffffffc020583c <memset>
    tf.gpr.s0 = (uintptr_t)fn;
ffffffffc0204538:	e0ca                	sd	s2,64(sp)
    tf.gpr.s1 = (uintptr_t)arg;
ffffffffc020453a:	e4a6                	sd	s1,72(sp)
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE;
ffffffffc020453c:	100027f3          	csrr	a5,sstatus
ffffffffc0204540:	edd7f793          	andi	a5,a5,-291
ffffffffc0204544:	1207e793          	ori	a5,a5,288
ffffffffc0204548:	e23e                	sd	a5,256(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc020454a:	860a                	mv	a2,sp
ffffffffc020454c:	10046513          	ori	a0,s0,256
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc0204550:	00000797          	auipc	a5,0x0
ffffffffc0204554:	9fc78793          	addi	a5,a5,-1540 # ffffffffc0203f4c <kernel_thread_entry>
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc0204558:	4581                	li	a1,0
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc020455a:	e63e                	sd	a5,264(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc020455c:	be7ff0ef          	jal	ra,ffffffffc0204142 <do_fork>
}
ffffffffc0204560:	70f2                	ld	ra,312(sp)
ffffffffc0204562:	7452                	ld	s0,304(sp)
ffffffffc0204564:	74b2                	ld	s1,296(sp)
ffffffffc0204566:	7912                	ld	s2,288(sp)
ffffffffc0204568:	6131                	addi	sp,sp,320
ffffffffc020456a:	8082                	ret

ffffffffc020456c <do_exit>:
{
ffffffffc020456c:	7179                	addi	sp,sp,-48
ffffffffc020456e:	f022                	sd	s0,32(sp)
    if (current == idleproc)
ffffffffc0204570:	000bb417          	auipc	s0,0xbb
ffffffffc0204574:	69040413          	addi	s0,s0,1680 # ffffffffc02bfc00 <current>
ffffffffc0204578:	601c                	ld	a5,0(s0)
{
ffffffffc020457a:	f406                	sd	ra,40(sp)
ffffffffc020457c:	ec26                	sd	s1,24(sp)
ffffffffc020457e:	e84a                	sd	s2,16(sp)
ffffffffc0204580:	e44e                	sd	s3,8(sp)
ffffffffc0204582:	e052                	sd	s4,0(sp)
    if (current == idleproc)
ffffffffc0204584:	000bb717          	auipc	a4,0xbb
ffffffffc0204588:	68473703          	ld	a4,1668(a4) # ffffffffc02bfc08 <idleproc>
ffffffffc020458c:	0ce78c63          	beq	a5,a4,ffffffffc0204664 <do_exit+0xf8>
    if (current == initproc)
ffffffffc0204590:	000bb497          	auipc	s1,0xbb
ffffffffc0204594:	68048493          	addi	s1,s1,1664 # ffffffffc02bfc10 <initproc>
ffffffffc0204598:	6098                	ld	a4,0(s1)
ffffffffc020459a:	0ee78b63          	beq	a5,a4,ffffffffc0204690 <do_exit+0x124>
    struct mm_struct *mm = current->mm;
ffffffffc020459e:	0287b983          	ld	s3,40(a5)
ffffffffc02045a2:	892a                	mv	s2,a0
    if (mm != NULL)
ffffffffc02045a4:	02098663          	beqz	s3,ffffffffc02045d0 <do_exit+0x64>
ffffffffc02045a8:	000bb797          	auipc	a5,0xbb
ffffffffc02045ac:	6287b783          	ld	a5,1576(a5) # ffffffffc02bfbd0 <boot_pgdir_pa>
ffffffffc02045b0:	577d                	li	a4,-1
ffffffffc02045b2:	177e                	slli	a4,a4,0x3f
ffffffffc02045b4:	83b1                	srli	a5,a5,0xc
ffffffffc02045b6:	8fd9                	or	a5,a5,a4
ffffffffc02045b8:	18079073          	csrw	satp,a5
    mm->mm_count -= 1;
ffffffffc02045bc:	0309a783          	lw	a5,48(s3)
ffffffffc02045c0:	fff7871b          	addiw	a4,a5,-1
ffffffffc02045c4:	02e9a823          	sw	a4,48(s3)
        if (mm_count_dec(mm) == 0)
ffffffffc02045c8:	cb55                	beqz	a4,ffffffffc020467c <do_exit+0x110>
        current->mm = NULL;
ffffffffc02045ca:	601c                	ld	a5,0(s0)
ffffffffc02045cc:	0207b423          	sd	zero,40(a5)
    current->state = PROC_ZOMBIE;
ffffffffc02045d0:	601c                	ld	a5,0(s0)
ffffffffc02045d2:	470d                	li	a4,3
ffffffffc02045d4:	c398                	sw	a4,0(a5)
    current->exit_code = error_code;
ffffffffc02045d6:	0f27a423          	sw	s2,232(a5)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02045da:	100027f3          	csrr	a5,sstatus
ffffffffc02045de:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02045e0:	4a01                	li	s4,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02045e2:	e3f9                	bnez	a5,ffffffffc02046a8 <do_exit+0x13c>
        proc = current->parent;
ffffffffc02045e4:	6018                	ld	a4,0(s0)
        if (proc->wait_state == WT_CHILD)
ffffffffc02045e6:	800007b7          	lui	a5,0x80000
ffffffffc02045ea:	0785                	addi	a5,a5,1
        proc = current->parent;
ffffffffc02045ec:	7308                	ld	a0,32(a4)
        if (proc->wait_state == WT_CHILD)
ffffffffc02045ee:	0ec52703          	lw	a4,236(a0)
ffffffffc02045f2:	0af70f63          	beq	a4,a5,ffffffffc02046b0 <do_exit+0x144>
        while (current->cptr != NULL)
ffffffffc02045f6:	6018                	ld	a4,0(s0)
ffffffffc02045f8:	7b7c                	ld	a5,240(a4)
ffffffffc02045fa:	c3a1                	beqz	a5,ffffffffc020463a <do_exit+0xce>
                if (initproc->wait_state == WT_CHILD)
ffffffffc02045fc:	800009b7          	lui	s3,0x80000
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204600:	490d                	li	s2,3
                if (initproc->wait_state == WT_CHILD)
ffffffffc0204602:	0985                	addi	s3,s3,1
ffffffffc0204604:	a021                	j	ffffffffc020460c <do_exit+0xa0>
        while (current->cptr != NULL)
ffffffffc0204606:	6018                	ld	a4,0(s0)
ffffffffc0204608:	7b7c                	ld	a5,240(a4)
ffffffffc020460a:	cb85                	beqz	a5,ffffffffc020463a <do_exit+0xce>
            current->cptr = proc->optr;
ffffffffc020460c:	1007b683          	ld	a3,256(a5) # ffffffff80000100 <_binary_obj___user_exit_out_size+0xffffffff7fff4fc0>
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc0204610:	6088                	ld	a0,0(s1)
            current->cptr = proc->optr;
ffffffffc0204612:	fb74                	sd	a3,240(a4)
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc0204614:	7978                	ld	a4,240(a0)
            proc->yptr = NULL;
ffffffffc0204616:	0e07bc23          	sd	zero,248(a5)
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc020461a:	10e7b023          	sd	a4,256(a5)
ffffffffc020461e:	c311                	beqz	a4,ffffffffc0204622 <do_exit+0xb6>
                initproc->cptr->yptr = proc;
ffffffffc0204620:	ff7c                	sd	a5,248(a4)
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204622:	4398                	lw	a4,0(a5)
            proc->parent = initproc;
ffffffffc0204624:	f388                	sd	a0,32(a5)
            initproc->cptr = proc;
ffffffffc0204626:	f97c                	sd	a5,240(a0)
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204628:	fd271fe3          	bne	a4,s2,ffffffffc0204606 <do_exit+0x9a>
                if (initproc->wait_state == WT_CHILD)
ffffffffc020462c:	0ec52783          	lw	a5,236(a0)
ffffffffc0204630:	fd379be3          	bne	a5,s3,ffffffffc0204606 <do_exit+0x9a>
                    wakeup_proc(initproc);
ffffffffc0204634:	377000ef          	jal	ra,ffffffffc02051aa <wakeup_proc>
ffffffffc0204638:	b7f9                	j	ffffffffc0204606 <do_exit+0x9a>
    if (flag)
ffffffffc020463a:	020a1263          	bnez	s4,ffffffffc020465e <do_exit+0xf2>
    schedule();
ffffffffc020463e:	3ed000ef          	jal	ra,ffffffffc020522a <schedule>
    panic("do_exit will not return!! %d.\n", current->pid);
ffffffffc0204642:	601c                	ld	a5,0(s0)
ffffffffc0204644:	00003617          	auipc	a2,0x3
ffffffffc0204648:	b6460613          	addi	a2,a2,-1180 # ffffffffc02071a8 <default_pmm_manager+0xa48>
ffffffffc020464c:	25a00593          	li	a1,602
ffffffffc0204650:	43d4                	lw	a3,4(a5)
ffffffffc0204652:	00003517          	auipc	a0,0x3
ffffffffc0204656:	af650513          	addi	a0,a0,-1290 # ffffffffc0207148 <default_pmm_manager+0x9e8>
ffffffffc020465a:	e35fb0ef          	jal	ra,ffffffffc020048e <__panic>
        intr_enable();
ffffffffc020465e:	b50fc0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0204662:	bff1                	j	ffffffffc020463e <do_exit+0xd2>
        panic("idleproc exit.\n");
ffffffffc0204664:	00003617          	auipc	a2,0x3
ffffffffc0204668:	b2460613          	addi	a2,a2,-1244 # ffffffffc0207188 <default_pmm_manager+0xa28>
ffffffffc020466c:	22600593          	li	a1,550
ffffffffc0204670:	00003517          	auipc	a0,0x3
ffffffffc0204674:	ad850513          	addi	a0,a0,-1320 # ffffffffc0207148 <default_pmm_manager+0x9e8>
ffffffffc0204678:	e17fb0ef          	jal	ra,ffffffffc020048e <__panic>
            exit_mmap(mm);
ffffffffc020467c:	854e                	mv	a0,s3
ffffffffc020467e:	ca0ff0ef          	jal	ra,ffffffffc0203b1e <exit_mmap>
            put_pgdir(mm);
ffffffffc0204682:	854e                	mv	a0,s3
ffffffffc0204684:	9dfff0ef          	jal	ra,ffffffffc0204062 <put_pgdir>
            mm_destroy(mm);
ffffffffc0204688:	854e                	mv	a0,s3
ffffffffc020468a:	af8ff0ef          	jal	ra,ffffffffc0203982 <mm_destroy>
ffffffffc020468e:	bf35                	j	ffffffffc02045ca <do_exit+0x5e>
        panic("initproc exit.\n");
ffffffffc0204690:	00003617          	auipc	a2,0x3
ffffffffc0204694:	b0860613          	addi	a2,a2,-1272 # ffffffffc0207198 <default_pmm_manager+0xa38>
ffffffffc0204698:	22a00593          	li	a1,554
ffffffffc020469c:	00003517          	auipc	a0,0x3
ffffffffc02046a0:	aac50513          	addi	a0,a0,-1364 # ffffffffc0207148 <default_pmm_manager+0x9e8>
ffffffffc02046a4:	debfb0ef          	jal	ra,ffffffffc020048e <__panic>
        intr_disable();
ffffffffc02046a8:	b0cfc0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc02046ac:	4a05                	li	s4,1
ffffffffc02046ae:	bf1d                	j	ffffffffc02045e4 <do_exit+0x78>
            wakeup_proc(proc);
ffffffffc02046b0:	2fb000ef          	jal	ra,ffffffffc02051aa <wakeup_proc>
ffffffffc02046b4:	b789                	j	ffffffffc02045f6 <do_exit+0x8a>

ffffffffc02046b6 <do_wait.part.0>:
int do_wait(int pid, int *code_store)
ffffffffc02046b6:	715d                	addi	sp,sp,-80
ffffffffc02046b8:	f84a                	sd	s2,48(sp)
ffffffffc02046ba:	f44e                	sd	s3,40(sp)
        current->wait_state = WT_CHILD;
ffffffffc02046bc:	80000937          	lui	s2,0x80000
    if (0 < pid && pid < MAX_PID)
ffffffffc02046c0:	6989                	lui	s3,0x2
int do_wait(int pid, int *code_store)
ffffffffc02046c2:	fc26                	sd	s1,56(sp)
ffffffffc02046c4:	f052                	sd	s4,32(sp)
ffffffffc02046c6:	ec56                	sd	s5,24(sp)
ffffffffc02046c8:	e85a                	sd	s6,16(sp)
ffffffffc02046ca:	e45e                	sd	s7,8(sp)
ffffffffc02046cc:	e486                	sd	ra,72(sp)
ffffffffc02046ce:	e0a2                	sd	s0,64(sp)
ffffffffc02046d0:	84aa                	mv	s1,a0
ffffffffc02046d2:	8a2e                	mv	s4,a1
        proc = current->cptr;
ffffffffc02046d4:	000bbb97          	auipc	s7,0xbb
ffffffffc02046d8:	52cb8b93          	addi	s7,s7,1324 # ffffffffc02bfc00 <current>
    if (0 < pid && pid < MAX_PID)
ffffffffc02046dc:	00050b1b          	sext.w	s6,a0
ffffffffc02046e0:	fff50a9b          	addiw	s5,a0,-1
ffffffffc02046e4:	19f9                	addi	s3,s3,-2
        current->wait_state = WT_CHILD;
ffffffffc02046e6:	0905                	addi	s2,s2,1
    if (pid != 0)
ffffffffc02046e8:	ccbd                	beqz	s1,ffffffffc0204766 <do_wait.part.0+0xb0>
    if (0 < pid && pid < MAX_PID)
ffffffffc02046ea:	0359e863          	bltu	s3,s5,ffffffffc020471a <do_wait.part.0+0x64>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc02046ee:	45a9                	li	a1,10
ffffffffc02046f0:	855a                	mv	a0,s6
ffffffffc02046f2:	4a5000ef          	jal	ra,ffffffffc0205396 <hash32>
ffffffffc02046f6:	02051793          	slli	a5,a0,0x20
ffffffffc02046fa:	01c7d513          	srli	a0,a5,0x1c
ffffffffc02046fe:	000b7797          	auipc	a5,0xb7
ffffffffc0204702:	49278793          	addi	a5,a5,1170 # ffffffffc02bbb90 <hash_list>
ffffffffc0204706:	953e                	add	a0,a0,a5
ffffffffc0204708:	842a                	mv	s0,a0
        while ((le = list_next(le)) != list)
ffffffffc020470a:	a029                	j	ffffffffc0204714 <do_wait.part.0+0x5e>
            if (proc->pid == pid)
ffffffffc020470c:	f2c42783          	lw	a5,-212(s0)
ffffffffc0204710:	02978163          	beq	a5,s1,ffffffffc0204732 <do_wait.part.0+0x7c>
ffffffffc0204714:	6400                	ld	s0,8(s0)
        while ((le = list_next(le)) != list)
ffffffffc0204716:	fe851be3          	bne	a0,s0,ffffffffc020470c <do_wait.part.0+0x56>
    return -E_BAD_PROC;
ffffffffc020471a:	5579                	li	a0,-2
}
ffffffffc020471c:	60a6                	ld	ra,72(sp)
ffffffffc020471e:	6406                	ld	s0,64(sp)
ffffffffc0204720:	74e2                	ld	s1,56(sp)
ffffffffc0204722:	7942                	ld	s2,48(sp)
ffffffffc0204724:	79a2                	ld	s3,40(sp)
ffffffffc0204726:	7a02                	ld	s4,32(sp)
ffffffffc0204728:	6ae2                	ld	s5,24(sp)
ffffffffc020472a:	6b42                	ld	s6,16(sp)
ffffffffc020472c:	6ba2                	ld	s7,8(sp)
ffffffffc020472e:	6161                	addi	sp,sp,80
ffffffffc0204730:	8082                	ret
        if (proc != NULL && proc->parent == current)
ffffffffc0204732:	000bb683          	ld	a3,0(s7)
ffffffffc0204736:	f4843783          	ld	a5,-184(s0)
ffffffffc020473a:	fed790e3          	bne	a5,a3,ffffffffc020471a <do_wait.part.0+0x64>
            if (proc->state == PROC_ZOMBIE)
ffffffffc020473e:	f2842703          	lw	a4,-216(s0)
ffffffffc0204742:	478d                	li	a5,3
ffffffffc0204744:	0ef70b63          	beq	a4,a5,ffffffffc020483a <do_wait.part.0+0x184>
        current->state = PROC_SLEEPING;
ffffffffc0204748:	4785                	li	a5,1
ffffffffc020474a:	c29c                	sw	a5,0(a3)
        current->wait_state = WT_CHILD;
ffffffffc020474c:	0f26a623          	sw	s2,236(a3)
        schedule();
ffffffffc0204750:	2db000ef          	jal	ra,ffffffffc020522a <schedule>
        if (current->flags & PF_EXITING)
ffffffffc0204754:	000bb783          	ld	a5,0(s7)
ffffffffc0204758:	0b07a783          	lw	a5,176(a5)
ffffffffc020475c:	8b85                	andi	a5,a5,1
ffffffffc020475e:	d7c9                	beqz	a5,ffffffffc02046e8 <do_wait.part.0+0x32>
            do_exit(-E_KILLED);
ffffffffc0204760:	555d                	li	a0,-9
ffffffffc0204762:	e0bff0ef          	jal	ra,ffffffffc020456c <do_exit>
        proc = current->cptr;
ffffffffc0204766:	000bb683          	ld	a3,0(s7)
ffffffffc020476a:	7ae0                	ld	s0,240(a3)
        for (; proc != NULL; proc = proc->optr)
ffffffffc020476c:	d45d                	beqz	s0,ffffffffc020471a <do_wait.part.0+0x64>
            if (proc->state == PROC_ZOMBIE)
ffffffffc020476e:	470d                	li	a4,3
ffffffffc0204770:	a021                	j	ffffffffc0204778 <do_wait.part.0+0xc2>
        for (; proc != NULL; proc = proc->optr)
ffffffffc0204772:	10043403          	ld	s0,256(s0)
ffffffffc0204776:	d869                	beqz	s0,ffffffffc0204748 <do_wait.part.0+0x92>
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204778:	401c                	lw	a5,0(s0)
ffffffffc020477a:	fee79ce3          	bne	a5,a4,ffffffffc0204772 <do_wait.part.0+0xbc>
    if (proc == idleproc || proc == initproc)
ffffffffc020477e:	000bb797          	auipc	a5,0xbb
ffffffffc0204782:	48a7b783          	ld	a5,1162(a5) # ffffffffc02bfc08 <idleproc>
ffffffffc0204786:	0c878963          	beq	a5,s0,ffffffffc0204858 <do_wait.part.0+0x1a2>
ffffffffc020478a:	000bb797          	auipc	a5,0xbb
ffffffffc020478e:	4867b783          	ld	a5,1158(a5) # ffffffffc02bfc10 <initproc>
ffffffffc0204792:	0cf40363          	beq	s0,a5,ffffffffc0204858 <do_wait.part.0+0x1a2>
    if (code_store != NULL)
ffffffffc0204796:	000a0663          	beqz	s4,ffffffffc02047a2 <do_wait.part.0+0xec>
        *code_store = proc->exit_code;
ffffffffc020479a:	0e842783          	lw	a5,232(s0)
ffffffffc020479e:	00fa2023          	sw	a5,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8bd0>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02047a2:	100027f3          	csrr	a5,sstatus
ffffffffc02047a6:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02047a8:	4581                	li	a1,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02047aa:	e7c1                	bnez	a5,ffffffffc0204832 <do_wait.part.0+0x17c>
    __list_del(listelm->prev, listelm->next);
ffffffffc02047ac:	6c70                	ld	a2,216(s0)
ffffffffc02047ae:	7074                	ld	a3,224(s0)
    if (proc->optr != NULL)
ffffffffc02047b0:	10043703          	ld	a4,256(s0)
        proc->optr->yptr = proc->yptr;
ffffffffc02047b4:	7c7c                	ld	a5,248(s0)
    prev->next = next;
ffffffffc02047b6:	e614                	sd	a3,8(a2)
    next->prev = prev;
ffffffffc02047b8:	e290                	sd	a2,0(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc02047ba:	6470                	ld	a2,200(s0)
ffffffffc02047bc:	6874                	ld	a3,208(s0)
    prev->next = next;
ffffffffc02047be:	e614                	sd	a3,8(a2)
    next->prev = prev;
ffffffffc02047c0:	e290                	sd	a2,0(a3)
    if (proc->optr != NULL)
ffffffffc02047c2:	c319                	beqz	a4,ffffffffc02047c8 <do_wait.part.0+0x112>
        proc->optr->yptr = proc->yptr;
ffffffffc02047c4:	ff7c                	sd	a5,248(a4)
    if (proc->yptr != NULL)
ffffffffc02047c6:	7c7c                	ld	a5,248(s0)
ffffffffc02047c8:	c3b5                	beqz	a5,ffffffffc020482c <do_wait.part.0+0x176>
        proc->yptr->optr = proc->optr;
ffffffffc02047ca:	10e7b023          	sd	a4,256(a5)
    nr_process--;
ffffffffc02047ce:	000bb717          	auipc	a4,0xbb
ffffffffc02047d2:	44a70713          	addi	a4,a4,1098 # ffffffffc02bfc18 <nr_process>
ffffffffc02047d6:	431c                	lw	a5,0(a4)
ffffffffc02047d8:	37fd                	addiw	a5,a5,-1
ffffffffc02047da:	c31c                	sw	a5,0(a4)
    if (flag)
ffffffffc02047dc:	e5a9                	bnez	a1,ffffffffc0204826 <do_wait.part.0+0x170>
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
ffffffffc02047de:	6814                	ld	a3,16(s0)
    return pa2page(PADDR(kva));
ffffffffc02047e0:	c02007b7          	lui	a5,0xc0200
ffffffffc02047e4:	04f6ee63          	bltu	a3,a5,ffffffffc0204840 <do_wait.part.0+0x18a>
ffffffffc02047e8:	000bb797          	auipc	a5,0xbb
ffffffffc02047ec:	4107b783          	ld	a5,1040(a5) # ffffffffc02bfbf8 <va_pa_offset>
ffffffffc02047f0:	8e9d                	sub	a3,a3,a5
    if (PPN(pa) >= npage)
ffffffffc02047f2:	82b1                	srli	a3,a3,0xc
ffffffffc02047f4:	000bb797          	auipc	a5,0xbb
ffffffffc02047f8:	3ec7b783          	ld	a5,1004(a5) # ffffffffc02bfbe0 <npage>
ffffffffc02047fc:	06f6fa63          	bgeu	a3,a5,ffffffffc0204870 <do_wait.part.0+0x1ba>
    return &pages[PPN(pa) - nbase];
ffffffffc0204800:	00003517          	auipc	a0,0x3
ffffffffc0204804:	1e053503          	ld	a0,480(a0) # ffffffffc02079e0 <nbase>
ffffffffc0204808:	8e89                	sub	a3,a3,a0
ffffffffc020480a:	069a                	slli	a3,a3,0x6
ffffffffc020480c:	000bb517          	auipc	a0,0xbb
ffffffffc0204810:	3dc53503          	ld	a0,988(a0) # ffffffffc02bfbe8 <pages>
ffffffffc0204814:	9536                	add	a0,a0,a3
ffffffffc0204816:	4589                	li	a1,2
ffffffffc0204818:	93bfd0ef          	jal	ra,ffffffffc0202152 <free_pages>
    kfree(proc);
ffffffffc020481c:	8522                	mv	a0,s0
ffffffffc020481e:	fc8fd0ef          	jal	ra,ffffffffc0201fe6 <kfree>
    return 0;
ffffffffc0204822:	4501                	li	a0,0
ffffffffc0204824:	bde5                	j	ffffffffc020471c <do_wait.part.0+0x66>
        intr_enable();
ffffffffc0204826:	988fc0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc020482a:	bf55                	j	ffffffffc02047de <do_wait.part.0+0x128>
        proc->parent->cptr = proc->optr;
ffffffffc020482c:	701c                	ld	a5,32(s0)
ffffffffc020482e:	fbf8                	sd	a4,240(a5)
ffffffffc0204830:	bf79                	j	ffffffffc02047ce <do_wait.part.0+0x118>
        intr_disable();
ffffffffc0204832:	982fc0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc0204836:	4585                	li	a1,1
ffffffffc0204838:	bf95                	j	ffffffffc02047ac <do_wait.part.0+0xf6>
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc020483a:	f2840413          	addi	s0,s0,-216
ffffffffc020483e:	b781                	j	ffffffffc020477e <do_wait.part.0+0xc8>
    return pa2page(PADDR(kva));
ffffffffc0204840:	00002617          	auipc	a2,0x2
ffffffffc0204844:	fc860613          	addi	a2,a2,-56 # ffffffffc0206808 <default_pmm_manager+0xa8>
ffffffffc0204848:	07700593          	li	a1,119
ffffffffc020484c:	00002517          	auipc	a0,0x2
ffffffffc0204850:	85c50513          	addi	a0,a0,-1956 # ffffffffc02060a8 <commands+0x5d8>
ffffffffc0204854:	c3bfb0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("wait idleproc or initproc.\n");
ffffffffc0204858:	00003617          	auipc	a2,0x3
ffffffffc020485c:	97060613          	addi	a2,a2,-1680 # ffffffffc02071c8 <default_pmm_manager+0xa68>
ffffffffc0204860:	38300593          	li	a1,899
ffffffffc0204864:	00003517          	auipc	a0,0x3
ffffffffc0204868:	8e450513          	addi	a0,a0,-1820 # ffffffffc0207148 <default_pmm_manager+0x9e8>
ffffffffc020486c:	c23fb0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0204870:	00002617          	auipc	a2,0x2
ffffffffc0204874:	81860613          	addi	a2,a2,-2024 # ffffffffc0206088 <commands+0x5b8>
ffffffffc0204878:	06900593          	li	a1,105
ffffffffc020487c:	00002517          	auipc	a0,0x2
ffffffffc0204880:	82c50513          	addi	a0,a0,-2004 # ffffffffc02060a8 <commands+0x5d8>
ffffffffc0204884:	c0bfb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0204888 <init_main>:
}

// init_main - the second kernel thread used to create user_main kernel threads
static int
init_main(void *arg)
{
ffffffffc0204888:	1141                	addi	sp,sp,-16
ffffffffc020488a:	e406                	sd	ra,8(sp)
    size_t nr_free_pages_store = nr_free_pages();
ffffffffc020488c:	907fd0ef          	jal	ra,ffffffffc0202192 <nr_free_pages>
    size_t kernel_allocated_store = kallocated();
ffffffffc0204890:	ea2fd0ef          	jal	ra,ffffffffc0201f32 <kallocated>

    int pid = kernel_thread(user_main, NULL, 0);
ffffffffc0204894:	4601                	li	a2,0
ffffffffc0204896:	4581                	li	a1,0
ffffffffc0204898:	fffff517          	auipc	a0,0xfffff
ffffffffc020489c:	74c50513          	addi	a0,a0,1868 # ffffffffc0203fe4 <user_main>
ffffffffc02048a0:	c7dff0ef          	jal	ra,ffffffffc020451c <kernel_thread>
    if (pid <= 0)
ffffffffc02048a4:	00a04563          	bgtz	a0,ffffffffc02048ae <init_main+0x26>
ffffffffc02048a8:	a071                	j	ffffffffc0204934 <init_main+0xac>
        panic("create user_main failed.\n");
    }

    while (do_wait(0, NULL) == 0)
    {
        schedule();
ffffffffc02048aa:	181000ef          	jal	ra,ffffffffc020522a <schedule>
    if (code_store != NULL)
ffffffffc02048ae:	4581                	li	a1,0
ffffffffc02048b0:	4501                	li	a0,0
ffffffffc02048b2:	e05ff0ef          	jal	ra,ffffffffc02046b6 <do_wait.part.0>
    while (do_wait(0, NULL) == 0)
ffffffffc02048b6:	d975                	beqz	a0,ffffffffc02048aa <init_main+0x22>
    }

    cprintf("all user-mode processes have quit.\n");
ffffffffc02048b8:	00003517          	auipc	a0,0x3
ffffffffc02048bc:	95050513          	addi	a0,a0,-1712 # ffffffffc0207208 <default_pmm_manager+0xaa8>
ffffffffc02048c0:	8d5fb0ef          	jal	ra,ffffffffc0200194 <cprintf>
    assert(initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL);
ffffffffc02048c4:	000bb797          	auipc	a5,0xbb
ffffffffc02048c8:	34c7b783          	ld	a5,844(a5) # ffffffffc02bfc10 <initproc>
ffffffffc02048cc:	7bf8                	ld	a4,240(a5)
ffffffffc02048ce:	e339                	bnez	a4,ffffffffc0204914 <init_main+0x8c>
ffffffffc02048d0:	7ff8                	ld	a4,248(a5)
ffffffffc02048d2:	e329                	bnez	a4,ffffffffc0204914 <init_main+0x8c>
ffffffffc02048d4:	1007b703          	ld	a4,256(a5)
ffffffffc02048d8:	ef15                	bnez	a4,ffffffffc0204914 <init_main+0x8c>
    assert(nr_process == 2);
ffffffffc02048da:	000bb697          	auipc	a3,0xbb
ffffffffc02048de:	33e6a683          	lw	a3,830(a3) # ffffffffc02bfc18 <nr_process>
ffffffffc02048e2:	4709                	li	a4,2
ffffffffc02048e4:	0ae69463          	bne	a3,a4,ffffffffc020498c <init_main+0x104>
    return listelm->next;
ffffffffc02048e8:	000bb697          	auipc	a3,0xbb
ffffffffc02048ec:	2a868693          	addi	a3,a3,680 # ffffffffc02bfb90 <proc_list>
    assert(list_next(&proc_list) == &(initproc->list_link));
ffffffffc02048f0:	6698                	ld	a4,8(a3)
ffffffffc02048f2:	0c878793          	addi	a5,a5,200
ffffffffc02048f6:	06f71b63          	bne	a4,a5,ffffffffc020496c <init_main+0xe4>
    assert(list_prev(&proc_list) == &(initproc->list_link));
ffffffffc02048fa:	629c                	ld	a5,0(a3)
ffffffffc02048fc:	04f71863          	bne	a4,a5,ffffffffc020494c <init_main+0xc4>

    cprintf("init check memory pass.\n");
ffffffffc0204900:	00003517          	auipc	a0,0x3
ffffffffc0204904:	9f050513          	addi	a0,a0,-1552 # ffffffffc02072f0 <default_pmm_manager+0xb90>
ffffffffc0204908:	88dfb0ef          	jal	ra,ffffffffc0200194 <cprintf>
    return 0;
}
ffffffffc020490c:	60a2                	ld	ra,8(sp)
ffffffffc020490e:	4501                	li	a0,0
ffffffffc0204910:	0141                	addi	sp,sp,16
ffffffffc0204912:	8082                	ret
    assert(initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL);
ffffffffc0204914:	00003697          	auipc	a3,0x3
ffffffffc0204918:	91c68693          	addi	a3,a3,-1764 # ffffffffc0207230 <default_pmm_manager+0xad0>
ffffffffc020491c:	00002617          	auipc	a2,0x2
ffffffffc0204920:	a9460613          	addi	a2,a2,-1388 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc0204924:	3f100593          	li	a1,1009
ffffffffc0204928:	00003517          	auipc	a0,0x3
ffffffffc020492c:	82050513          	addi	a0,a0,-2016 # ffffffffc0207148 <default_pmm_manager+0x9e8>
ffffffffc0204930:	b5ffb0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("create user_main failed.\n");
ffffffffc0204934:	00003617          	auipc	a2,0x3
ffffffffc0204938:	8b460613          	addi	a2,a2,-1868 # ffffffffc02071e8 <default_pmm_manager+0xa88>
ffffffffc020493c:	3e800593          	li	a1,1000
ffffffffc0204940:	00003517          	auipc	a0,0x3
ffffffffc0204944:	80850513          	addi	a0,a0,-2040 # ffffffffc0207148 <default_pmm_manager+0x9e8>
ffffffffc0204948:	b47fb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(list_prev(&proc_list) == &(initproc->list_link));
ffffffffc020494c:	00003697          	auipc	a3,0x3
ffffffffc0204950:	97468693          	addi	a3,a3,-1676 # ffffffffc02072c0 <default_pmm_manager+0xb60>
ffffffffc0204954:	00002617          	auipc	a2,0x2
ffffffffc0204958:	a5c60613          	addi	a2,a2,-1444 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc020495c:	3f400593          	li	a1,1012
ffffffffc0204960:	00002517          	auipc	a0,0x2
ffffffffc0204964:	7e850513          	addi	a0,a0,2024 # ffffffffc0207148 <default_pmm_manager+0x9e8>
ffffffffc0204968:	b27fb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(list_next(&proc_list) == &(initproc->list_link));
ffffffffc020496c:	00003697          	auipc	a3,0x3
ffffffffc0204970:	92468693          	addi	a3,a3,-1756 # ffffffffc0207290 <default_pmm_manager+0xb30>
ffffffffc0204974:	00002617          	auipc	a2,0x2
ffffffffc0204978:	a3c60613          	addi	a2,a2,-1476 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc020497c:	3f300593          	li	a1,1011
ffffffffc0204980:	00002517          	auipc	a0,0x2
ffffffffc0204984:	7c850513          	addi	a0,a0,1992 # ffffffffc0207148 <default_pmm_manager+0x9e8>
ffffffffc0204988:	b07fb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_process == 2);
ffffffffc020498c:	00003697          	auipc	a3,0x3
ffffffffc0204990:	8f468693          	addi	a3,a3,-1804 # ffffffffc0207280 <default_pmm_manager+0xb20>
ffffffffc0204994:	00002617          	auipc	a2,0x2
ffffffffc0204998:	a1c60613          	addi	a2,a2,-1508 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc020499c:	3f200593          	li	a1,1010
ffffffffc02049a0:	00002517          	auipc	a0,0x2
ffffffffc02049a4:	7a850513          	addi	a0,a0,1960 # ffffffffc0207148 <default_pmm_manager+0x9e8>
ffffffffc02049a8:	ae7fb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02049ac <do_execve>:
{
ffffffffc02049ac:	7171                	addi	sp,sp,-176
ffffffffc02049ae:	e4ee                	sd	s11,72(sp)
    struct mm_struct *mm = current->mm;
ffffffffc02049b0:	000bbd97          	auipc	s11,0xbb
ffffffffc02049b4:	250d8d93          	addi	s11,s11,592 # ffffffffc02bfc00 <current>
ffffffffc02049b8:	000db783          	ld	a5,0(s11)
{
ffffffffc02049bc:	e54e                	sd	s3,136(sp)
ffffffffc02049be:	ed26                	sd	s1,152(sp)
    struct mm_struct *mm = current->mm;
ffffffffc02049c0:	0287b983          	ld	s3,40(a5)
{
ffffffffc02049c4:	e94a                	sd	s2,144(sp)
ffffffffc02049c6:	f4de                	sd	s7,104(sp)
ffffffffc02049c8:	892a                	mv	s2,a0
ffffffffc02049ca:	8bb2                	mv	s7,a2
ffffffffc02049cc:	84ae                	mv	s1,a1
    if (!user_mem_check(mm, (uintptr_t)name, len, 0))
ffffffffc02049ce:	862e                	mv	a2,a1
ffffffffc02049d0:	4681                	li	a3,0
ffffffffc02049d2:	85aa                	mv	a1,a0
ffffffffc02049d4:	854e                	mv	a0,s3
{
ffffffffc02049d6:	f506                	sd	ra,168(sp)
ffffffffc02049d8:	f122                	sd	s0,160(sp)
ffffffffc02049da:	e152                	sd	s4,128(sp)
ffffffffc02049dc:	fcd6                	sd	s5,120(sp)
ffffffffc02049de:	f8da                	sd	s6,112(sp)
ffffffffc02049e0:	f0e2                	sd	s8,96(sp)
ffffffffc02049e2:	ece6                	sd	s9,88(sp)
ffffffffc02049e4:	e8ea                	sd	s10,80(sp)
ffffffffc02049e6:	f05e                	sd	s7,32(sp)
    if (!user_mem_check(mm, (uintptr_t)name, len, 0))
ffffffffc02049e8:	cd0ff0ef          	jal	ra,ffffffffc0203eb8 <user_mem_check>
ffffffffc02049ec:	40050c63          	beqz	a0,ffffffffc0204e04 <do_execve+0x458>
    memset(local_name, 0, sizeof(local_name));
ffffffffc02049f0:	4641                	li	a2,16
ffffffffc02049f2:	4581                	li	a1,0
ffffffffc02049f4:	1808                	addi	a0,sp,48
ffffffffc02049f6:	647000ef          	jal	ra,ffffffffc020583c <memset>
    memcpy(local_name, name, len);
ffffffffc02049fa:	47bd                	li	a5,15
ffffffffc02049fc:	8626                	mv	a2,s1
ffffffffc02049fe:	1e97e463          	bltu	a5,s1,ffffffffc0204be6 <do_execve+0x23a>
ffffffffc0204a02:	85ca                	mv	a1,s2
ffffffffc0204a04:	1808                	addi	a0,sp,48
ffffffffc0204a06:	649000ef          	jal	ra,ffffffffc020584e <memcpy>
    if (mm != NULL)
ffffffffc0204a0a:	1e098563          	beqz	s3,ffffffffc0204bf4 <do_execve+0x248>
        cputs("mm != NULL");
ffffffffc0204a0e:	00002517          	auipc	a0,0x2
ffffffffc0204a12:	4fa50513          	addi	a0,a0,1274 # ffffffffc0206f08 <default_pmm_manager+0x7a8>
ffffffffc0204a16:	fb6fb0ef          	jal	ra,ffffffffc02001cc <cputs>
ffffffffc0204a1a:	000bb797          	auipc	a5,0xbb
ffffffffc0204a1e:	1b67b783          	ld	a5,438(a5) # ffffffffc02bfbd0 <boot_pgdir_pa>
ffffffffc0204a22:	577d                	li	a4,-1
ffffffffc0204a24:	177e                	slli	a4,a4,0x3f
ffffffffc0204a26:	83b1                	srli	a5,a5,0xc
ffffffffc0204a28:	8fd9                	or	a5,a5,a4
ffffffffc0204a2a:	18079073          	csrw	satp,a5
ffffffffc0204a2e:	0309a783          	lw	a5,48(s3) # 2030 <_binary_obj___user_faultread_out_size-0x7ba0>
ffffffffc0204a32:	fff7871b          	addiw	a4,a5,-1
ffffffffc0204a36:	02e9a823          	sw	a4,48(s3)
        if (mm_count_dec(mm) == 0)
ffffffffc0204a3a:	2c070663          	beqz	a4,ffffffffc0204d06 <do_execve+0x35a>
        current->mm = NULL;
ffffffffc0204a3e:	000db783          	ld	a5,0(s11)
ffffffffc0204a42:	0207b423          	sd	zero,40(a5)
    if ((mm = mm_create()) == NULL)
ffffffffc0204a46:	dfdfe0ef          	jal	ra,ffffffffc0203842 <mm_create>
ffffffffc0204a4a:	84aa                	mv	s1,a0
ffffffffc0204a4c:	1c050f63          	beqz	a0,ffffffffc0204c2a <do_execve+0x27e>
    if ((page = alloc_page()) == NULL)
ffffffffc0204a50:	4505                	li	a0,1
ffffffffc0204a52:	ec2fd0ef          	jal	ra,ffffffffc0202114 <alloc_pages>
ffffffffc0204a56:	3a050b63          	beqz	a0,ffffffffc0204e0c <do_execve+0x460>
    return page - pages + nbase;
ffffffffc0204a5a:	000bbc97          	auipc	s9,0xbb
ffffffffc0204a5e:	18ec8c93          	addi	s9,s9,398 # ffffffffc02bfbe8 <pages>
ffffffffc0204a62:	000cb683          	ld	a3,0(s9)
    return KADDR(page2pa(page));
ffffffffc0204a66:	000bbc17          	auipc	s8,0xbb
ffffffffc0204a6a:	17ac0c13          	addi	s8,s8,378 # ffffffffc02bfbe0 <npage>
    return page - pages + nbase;
ffffffffc0204a6e:	00003717          	auipc	a4,0x3
ffffffffc0204a72:	f7273703          	ld	a4,-142(a4) # ffffffffc02079e0 <nbase>
ffffffffc0204a76:	40d506b3          	sub	a3,a0,a3
ffffffffc0204a7a:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0204a7c:	5afd                	li	s5,-1
ffffffffc0204a7e:	000c3783          	ld	a5,0(s8)
    return page - pages + nbase;
ffffffffc0204a82:	96ba                	add	a3,a3,a4
ffffffffc0204a84:	e83a                	sd	a4,16(sp)
    return KADDR(page2pa(page));
ffffffffc0204a86:	00cad713          	srli	a4,s5,0xc
ffffffffc0204a8a:	ec3a                	sd	a4,24(sp)
ffffffffc0204a8c:	8f75                	and	a4,a4,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc0204a8e:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204a90:	38f77263          	bgeu	a4,a5,ffffffffc0204e14 <do_execve+0x468>
ffffffffc0204a94:	000bbb17          	auipc	s6,0xbb
ffffffffc0204a98:	164b0b13          	addi	s6,s6,356 # ffffffffc02bfbf8 <va_pa_offset>
ffffffffc0204a9c:	000b3903          	ld	s2,0(s6)
    memcpy(pgdir, boot_pgdir_va, PGSIZE);
ffffffffc0204aa0:	6605                	lui	a2,0x1
ffffffffc0204aa2:	000bb597          	auipc	a1,0xbb
ffffffffc0204aa6:	1365b583          	ld	a1,310(a1) # ffffffffc02bfbd8 <boot_pgdir_va>
ffffffffc0204aaa:	9936                	add	s2,s2,a3
ffffffffc0204aac:	854a                	mv	a0,s2
ffffffffc0204aae:	5a1000ef          	jal	ra,ffffffffc020584e <memcpy>
    if (elf->e_magic != ELF_MAGIC)
ffffffffc0204ab2:	7782                	ld	a5,32(sp)
ffffffffc0204ab4:	4398                	lw	a4,0(a5)
ffffffffc0204ab6:	464c47b7          	lui	a5,0x464c4
    mm->pgdir = pgdir;
ffffffffc0204aba:	0124bc23          	sd	s2,24(s1)
    if (elf->e_magic != ELF_MAGIC)
ffffffffc0204abe:	57f78793          	addi	a5,a5,1407 # 464c457f <_binary_obj___user_exit_out_size+0x464b943f>
ffffffffc0204ac2:	14f71a63          	bne	a4,a5,ffffffffc0204c16 <do_execve+0x26a>
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc0204ac6:	7682                	ld	a3,32(sp)
ffffffffc0204ac8:	0386d703          	lhu	a4,56(a3)
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
ffffffffc0204acc:	0206b983          	ld	s3,32(a3)
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc0204ad0:	00371793          	slli	a5,a4,0x3
ffffffffc0204ad4:	8f99                	sub	a5,a5,a4
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
ffffffffc0204ad6:	99b6                	add	s3,s3,a3
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc0204ad8:	078e                	slli	a5,a5,0x3
ffffffffc0204ada:	97ce                	add	a5,a5,s3
ffffffffc0204adc:	f43e                	sd	a5,40(sp)
    for (; ph < ph_end; ph++)
ffffffffc0204ade:	00f9fc63          	bgeu	s3,a5,ffffffffc0204af6 <do_execve+0x14a>
        if (ph->p_type != ELF_PT_LOAD)
ffffffffc0204ae2:	0009a783          	lw	a5,0(s3)
ffffffffc0204ae6:	4705                	li	a4,1
ffffffffc0204ae8:	14e78363          	beq	a5,a4,ffffffffc0204c2e <do_execve+0x282>
    for (; ph < ph_end; ph++)
ffffffffc0204aec:	77a2                	ld	a5,40(sp)
ffffffffc0204aee:	03898993          	addi	s3,s3,56
ffffffffc0204af2:	fef9e8e3          	bltu	s3,a5,ffffffffc0204ae2 <do_execve+0x136>
    if ((ret = mm_map(mm, USTACKTOP - USTACKSIZE, USTACKSIZE, vm_flags, NULL)) != 0)
ffffffffc0204af6:	4701                	li	a4,0
ffffffffc0204af8:	46ad                	li	a3,11
ffffffffc0204afa:	00100637          	lui	a2,0x100
ffffffffc0204afe:	7ff005b7          	lui	a1,0x7ff00
ffffffffc0204b02:	8526                	mv	a0,s1
ffffffffc0204b04:	ed1fe0ef          	jal	ra,ffffffffc02039d4 <mm_map>
ffffffffc0204b08:	8a2a                	mv	s4,a0
ffffffffc0204b0a:	1e051463          	bnez	a0,ffffffffc0204cf2 <do_execve+0x346>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - PGSIZE, PTE_USER) != NULL);
ffffffffc0204b0e:	6c88                	ld	a0,24(s1)
ffffffffc0204b10:	467d                	li	a2,31
ffffffffc0204b12:	7ffff5b7          	lui	a1,0x7ffff
ffffffffc0204b16:	c47fe0ef          	jal	ra,ffffffffc020375c <pgdir_alloc_page>
ffffffffc0204b1a:	38050563          	beqz	a0,ffffffffc0204ea4 <do_execve+0x4f8>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 2 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204b1e:	6c88                	ld	a0,24(s1)
ffffffffc0204b20:	467d                	li	a2,31
ffffffffc0204b22:	7fffe5b7          	lui	a1,0x7fffe
ffffffffc0204b26:	c37fe0ef          	jal	ra,ffffffffc020375c <pgdir_alloc_page>
ffffffffc0204b2a:	34050d63          	beqz	a0,ffffffffc0204e84 <do_execve+0x4d8>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 3 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204b2e:	6c88                	ld	a0,24(s1)
ffffffffc0204b30:	467d                	li	a2,31
ffffffffc0204b32:	7fffd5b7          	lui	a1,0x7fffd
ffffffffc0204b36:	c27fe0ef          	jal	ra,ffffffffc020375c <pgdir_alloc_page>
ffffffffc0204b3a:	32050563          	beqz	a0,ffffffffc0204e64 <do_execve+0x4b8>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 4 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204b3e:	6c88                	ld	a0,24(s1)
ffffffffc0204b40:	467d                	li	a2,31
ffffffffc0204b42:	7fffc5b7          	lui	a1,0x7fffc
ffffffffc0204b46:	c17fe0ef          	jal	ra,ffffffffc020375c <pgdir_alloc_page>
ffffffffc0204b4a:	2e050d63          	beqz	a0,ffffffffc0204e44 <do_execve+0x498>
    mm->mm_count += 1;
ffffffffc0204b4e:	589c                	lw	a5,48(s1)
    current->mm = mm;
ffffffffc0204b50:	000db603          	ld	a2,0(s11)
    current->pgdir = PADDR(mm->pgdir);
ffffffffc0204b54:	6c94                	ld	a3,24(s1)
ffffffffc0204b56:	2785                	addiw	a5,a5,1
ffffffffc0204b58:	d89c                	sw	a5,48(s1)
    current->mm = mm;
ffffffffc0204b5a:	f604                	sd	s1,40(a2)
    current->pgdir = PADDR(mm->pgdir);
ffffffffc0204b5c:	c02007b7          	lui	a5,0xc0200
ffffffffc0204b60:	2cf6e663          	bltu	a3,a5,ffffffffc0204e2c <do_execve+0x480>
ffffffffc0204b64:	000b3783          	ld	a5,0(s6)
ffffffffc0204b68:	577d                	li	a4,-1
ffffffffc0204b6a:	177e                	slli	a4,a4,0x3f
ffffffffc0204b6c:	8e9d                	sub	a3,a3,a5
ffffffffc0204b6e:	00c6d793          	srli	a5,a3,0xc
ffffffffc0204b72:	f654                	sd	a3,168(a2)
ffffffffc0204b74:	8fd9                	or	a5,a5,a4
ffffffffc0204b76:	18079073          	csrw	satp,a5
    struct trapframe *tf = current->tf;
ffffffffc0204b7a:	7240                	ld	s0,160(a2)
    memset(tf, 0, sizeof(struct trapframe));
ffffffffc0204b7c:	4581                	li	a1,0
ffffffffc0204b7e:	12000613          	li	a2,288
ffffffffc0204b82:	8522                	mv	a0,s0
    uintptr_t sstatus = tf->status;
ffffffffc0204b84:	10043483          	ld	s1,256(s0)
    memset(tf, 0, sizeof(struct trapframe));
ffffffffc0204b88:	4b5000ef          	jal	ra,ffffffffc020583c <memset>
    tf->epc = (uintptr_t)elf->e_entry;
ffffffffc0204b8c:	7782                	ld	a5,32(sp)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204b8e:	000db903          	ld	s2,0(s11)
    tf->status = (sstatus & ~SSTATUS_SPP) | SSTATUS_SPIE;
ffffffffc0204b92:	edf4f493          	andi	s1,s1,-289
    tf->epc = (uintptr_t)elf->e_entry;
ffffffffc0204b96:	6f98                	ld	a4,24(a5)
    tf->gpr.sp = (uintptr_t)USTACKTOP;
ffffffffc0204b98:	4785                	li	a5,1
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204b9a:	0b490913          	addi	s2,s2,180 # ffffffff800000b4 <_binary_obj___user_exit_out_size+0xffffffff7fff4f74>
    tf->gpr.sp = (uintptr_t)USTACKTOP;
ffffffffc0204b9e:	07fe                	slli	a5,a5,0x1f
    tf->status = (sstatus & ~SSTATUS_SPP) | SSTATUS_SPIE;
ffffffffc0204ba0:	0204e493          	ori	s1,s1,32
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204ba4:	4641                	li	a2,16
ffffffffc0204ba6:	4581                	li	a1,0
    tf->gpr.sp = (uintptr_t)USTACKTOP;
ffffffffc0204ba8:	e81c                	sd	a5,16(s0)
    tf->epc = (uintptr_t)elf->e_entry;
ffffffffc0204baa:	10e43423          	sd	a4,264(s0)
    tf->gpr.a0 = 0;
ffffffffc0204bae:	04043823          	sd	zero,80(s0)
    tf->status = (sstatus & ~SSTATUS_SPP) | SSTATUS_SPIE;
ffffffffc0204bb2:	10943023          	sd	s1,256(s0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204bb6:	854a                	mv	a0,s2
ffffffffc0204bb8:	485000ef          	jal	ra,ffffffffc020583c <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0204bbc:	463d                	li	a2,15
ffffffffc0204bbe:	180c                	addi	a1,sp,48
ffffffffc0204bc0:	854a                	mv	a0,s2
ffffffffc0204bc2:	48d000ef          	jal	ra,ffffffffc020584e <memcpy>
}
ffffffffc0204bc6:	70aa                	ld	ra,168(sp)
ffffffffc0204bc8:	740a                	ld	s0,160(sp)
ffffffffc0204bca:	64ea                	ld	s1,152(sp)
ffffffffc0204bcc:	694a                	ld	s2,144(sp)
ffffffffc0204bce:	69aa                	ld	s3,136(sp)
ffffffffc0204bd0:	7ae6                	ld	s5,120(sp)
ffffffffc0204bd2:	7b46                	ld	s6,112(sp)
ffffffffc0204bd4:	7ba6                	ld	s7,104(sp)
ffffffffc0204bd6:	7c06                	ld	s8,96(sp)
ffffffffc0204bd8:	6ce6                	ld	s9,88(sp)
ffffffffc0204bda:	6d46                	ld	s10,80(sp)
ffffffffc0204bdc:	6da6                	ld	s11,72(sp)
ffffffffc0204bde:	8552                	mv	a0,s4
ffffffffc0204be0:	6a0a                	ld	s4,128(sp)
ffffffffc0204be2:	614d                	addi	sp,sp,176
ffffffffc0204be4:	8082                	ret
    memcpy(local_name, name, len);
ffffffffc0204be6:	463d                	li	a2,15
ffffffffc0204be8:	85ca                	mv	a1,s2
ffffffffc0204bea:	1808                	addi	a0,sp,48
ffffffffc0204bec:	463000ef          	jal	ra,ffffffffc020584e <memcpy>
    if (mm != NULL)
ffffffffc0204bf0:	e0099fe3          	bnez	s3,ffffffffc0204a0e <do_execve+0x62>
    if (current->mm != NULL)
ffffffffc0204bf4:	000db783          	ld	a5,0(s11)
ffffffffc0204bf8:	779c                	ld	a5,40(a5)
ffffffffc0204bfa:	e40786e3          	beqz	a5,ffffffffc0204a46 <do_execve+0x9a>
        panic("load_icode: current->mm must be empty.\n");
ffffffffc0204bfe:	00002617          	auipc	a2,0x2
ffffffffc0204c02:	71260613          	addi	a2,a2,1810 # ffffffffc0207310 <default_pmm_manager+0xbb0>
ffffffffc0204c06:	26600593          	li	a1,614
ffffffffc0204c0a:	00002517          	auipc	a0,0x2
ffffffffc0204c0e:	53e50513          	addi	a0,a0,1342 # ffffffffc0207148 <default_pmm_manager+0x9e8>
ffffffffc0204c12:	87dfb0ef          	jal	ra,ffffffffc020048e <__panic>
    put_pgdir(mm);
ffffffffc0204c16:	8526                	mv	a0,s1
ffffffffc0204c18:	c4aff0ef          	jal	ra,ffffffffc0204062 <put_pgdir>
    mm_destroy(mm);
ffffffffc0204c1c:	8526                	mv	a0,s1
ffffffffc0204c1e:	d65fe0ef          	jal	ra,ffffffffc0203982 <mm_destroy>
        ret = -E_INVAL_ELF;
ffffffffc0204c22:	5a61                	li	s4,-8
    do_exit(ret);
ffffffffc0204c24:	8552                	mv	a0,s4
ffffffffc0204c26:	947ff0ef          	jal	ra,ffffffffc020456c <do_exit>
    int ret = -E_NO_MEM;
ffffffffc0204c2a:	5a71                	li	s4,-4
ffffffffc0204c2c:	bfe5                	j	ffffffffc0204c24 <do_execve+0x278>
        if (ph->p_filesz > ph->p_memsz)
ffffffffc0204c2e:	0289b603          	ld	a2,40(s3)
ffffffffc0204c32:	0209b783          	ld	a5,32(s3)
ffffffffc0204c36:	1cf66d63          	bltu	a2,a5,ffffffffc0204e10 <do_execve+0x464>
        if (ph->p_flags & ELF_PF_X)
ffffffffc0204c3a:	0049a783          	lw	a5,4(s3)
ffffffffc0204c3e:	0017f693          	andi	a3,a5,1
ffffffffc0204c42:	c291                	beqz	a3,ffffffffc0204c46 <do_execve+0x29a>
            vm_flags |= VM_EXEC;
ffffffffc0204c44:	4691                	li	a3,4
        if (ph->p_flags & ELF_PF_W)
ffffffffc0204c46:	0027f713          	andi	a4,a5,2
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204c4a:	8b91                	andi	a5,a5,4
        if (ph->p_flags & ELF_PF_W)
ffffffffc0204c4c:	e779                	bnez	a4,ffffffffc0204d1a <do_execve+0x36e>
        vm_flags = 0, perm = PTE_U | PTE_V;
ffffffffc0204c4e:	4d45                	li	s10,17
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204c50:	c781                	beqz	a5,ffffffffc0204c58 <do_execve+0x2ac>
            vm_flags |= VM_READ;
ffffffffc0204c52:	0016e693          	ori	a3,a3,1
            perm |= PTE_R;
ffffffffc0204c56:	4d4d                	li	s10,19
        if (vm_flags & VM_WRITE)
ffffffffc0204c58:	0026f793          	andi	a5,a3,2
ffffffffc0204c5c:	e3f1                	bnez	a5,ffffffffc0204d20 <do_execve+0x374>
        if (vm_flags & VM_EXEC)
ffffffffc0204c5e:	0046f793          	andi	a5,a3,4
ffffffffc0204c62:	c399                	beqz	a5,ffffffffc0204c68 <do_execve+0x2bc>
            perm |= PTE_X;
ffffffffc0204c64:	008d6d13          	ori	s10,s10,8
        if ((ret = mm_map(mm, ph->p_va, ph->p_memsz, vm_flags, NULL)) != 0)
ffffffffc0204c68:	0109b583          	ld	a1,16(s3)
ffffffffc0204c6c:	4701                	li	a4,0
ffffffffc0204c6e:	8526                	mv	a0,s1
ffffffffc0204c70:	d65fe0ef          	jal	ra,ffffffffc02039d4 <mm_map>
ffffffffc0204c74:	8a2a                	mv	s4,a0
ffffffffc0204c76:	ed35                	bnez	a0,ffffffffc0204cf2 <do_execve+0x346>
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc0204c78:	0109bb83          	ld	s7,16(s3)
ffffffffc0204c7c:	77fd                	lui	a5,0xfffff
        end = ph->p_va + ph->p_filesz;
ffffffffc0204c7e:	0209ba03          	ld	s4,32(s3)
        unsigned char *from = binary + ph->p_offset;
ffffffffc0204c82:	0089b903          	ld	s2,8(s3)
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc0204c86:	00fbfab3          	and	s5,s7,a5
        unsigned char *from = binary + ph->p_offset;
ffffffffc0204c8a:	7782                	ld	a5,32(sp)
        end = ph->p_va + ph->p_filesz;
ffffffffc0204c8c:	9a5e                	add	s4,s4,s7
        unsigned char *from = binary + ph->p_offset;
ffffffffc0204c8e:	993e                	add	s2,s2,a5
        while (start < end)
ffffffffc0204c90:	054be963          	bltu	s7,s4,ffffffffc0204ce2 <do_execve+0x336>
ffffffffc0204c94:	aa95                	j	ffffffffc0204e08 <do_execve+0x45c>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0204c96:	6785                	lui	a5,0x1
ffffffffc0204c98:	415b8533          	sub	a0,s7,s5
ffffffffc0204c9c:	9abe                	add	s5,s5,a5
ffffffffc0204c9e:	417a8633          	sub	a2,s5,s7
            if (end < la)
ffffffffc0204ca2:	015a7463          	bgeu	s4,s5,ffffffffc0204caa <do_execve+0x2fe>
                size -= la - end;
ffffffffc0204ca6:	417a0633          	sub	a2,s4,s7
    return page - pages + nbase;
ffffffffc0204caa:	000cb683          	ld	a3,0(s9)
ffffffffc0204cae:	67c2                	ld	a5,16(sp)
    return KADDR(page2pa(page));
ffffffffc0204cb0:	000c3583          	ld	a1,0(s8)
    return page - pages + nbase;
ffffffffc0204cb4:	40d406b3          	sub	a3,s0,a3
ffffffffc0204cb8:	8699                	srai	a3,a3,0x6
ffffffffc0204cba:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0204cbc:	67e2                	ld	a5,24(sp)
ffffffffc0204cbe:	00f6f833          	and	a6,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0204cc2:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204cc4:	14b87863          	bgeu	a6,a1,ffffffffc0204e14 <do_execve+0x468>
ffffffffc0204cc8:	000b3803          	ld	a6,0(s6)
            memcpy(page2kva(page) + off, from, size);
ffffffffc0204ccc:	85ca                	mv	a1,s2
            start += size, from += size;
ffffffffc0204cce:	9bb2                	add	s7,s7,a2
ffffffffc0204cd0:	96c2                	add	a3,a3,a6
            memcpy(page2kva(page) + off, from, size);
ffffffffc0204cd2:	9536                	add	a0,a0,a3
            start += size, from += size;
ffffffffc0204cd4:	e432                	sd	a2,8(sp)
            memcpy(page2kva(page) + off, from, size);
ffffffffc0204cd6:	379000ef          	jal	ra,ffffffffc020584e <memcpy>
            start += size, from += size;
ffffffffc0204cda:	6622                	ld	a2,8(sp)
ffffffffc0204cdc:	9932                	add	s2,s2,a2
        while (start < end)
ffffffffc0204cde:	054bf363          	bgeu	s7,s4,ffffffffc0204d24 <do_execve+0x378>
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL)
ffffffffc0204ce2:	6c88                	ld	a0,24(s1)
ffffffffc0204ce4:	866a                	mv	a2,s10
ffffffffc0204ce6:	85d6                	mv	a1,s5
ffffffffc0204ce8:	a75fe0ef          	jal	ra,ffffffffc020375c <pgdir_alloc_page>
ffffffffc0204cec:	842a                	mv	s0,a0
ffffffffc0204cee:	f545                	bnez	a0,ffffffffc0204c96 <do_execve+0x2ea>
        ret = -E_NO_MEM;
ffffffffc0204cf0:	5a71                	li	s4,-4
    exit_mmap(mm);
ffffffffc0204cf2:	8526                	mv	a0,s1
ffffffffc0204cf4:	e2bfe0ef          	jal	ra,ffffffffc0203b1e <exit_mmap>
    put_pgdir(mm);
ffffffffc0204cf8:	8526                	mv	a0,s1
ffffffffc0204cfa:	b68ff0ef          	jal	ra,ffffffffc0204062 <put_pgdir>
    mm_destroy(mm);
ffffffffc0204cfe:	8526                	mv	a0,s1
ffffffffc0204d00:	c83fe0ef          	jal	ra,ffffffffc0203982 <mm_destroy>
    return ret;
ffffffffc0204d04:	b705                	j	ffffffffc0204c24 <do_execve+0x278>
            exit_mmap(mm);
ffffffffc0204d06:	854e                	mv	a0,s3
ffffffffc0204d08:	e17fe0ef          	jal	ra,ffffffffc0203b1e <exit_mmap>
            put_pgdir(mm);
ffffffffc0204d0c:	854e                	mv	a0,s3
ffffffffc0204d0e:	b54ff0ef          	jal	ra,ffffffffc0204062 <put_pgdir>
            mm_destroy(mm);
ffffffffc0204d12:	854e                	mv	a0,s3
ffffffffc0204d14:	c6ffe0ef          	jal	ra,ffffffffc0203982 <mm_destroy>
ffffffffc0204d18:	b31d                	j	ffffffffc0204a3e <do_execve+0x92>
            vm_flags |= VM_WRITE;
ffffffffc0204d1a:	0026e693          	ori	a3,a3,2
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204d1e:	fb95                	bnez	a5,ffffffffc0204c52 <do_execve+0x2a6>
            perm |= (PTE_W | PTE_R);
ffffffffc0204d20:	4d5d                	li	s10,23
ffffffffc0204d22:	bf35                	j	ffffffffc0204c5e <do_execve+0x2b2>
        end = ph->p_va + ph->p_memsz;
ffffffffc0204d24:	0109b683          	ld	a3,16(s3)
ffffffffc0204d28:	0289b903          	ld	s2,40(s3)
ffffffffc0204d2c:	9936                	add	s2,s2,a3
        if (start < la)
ffffffffc0204d2e:	075bfd63          	bgeu	s7,s5,ffffffffc0204da8 <do_execve+0x3fc>
            if (start == end)
ffffffffc0204d32:	db790de3          	beq	s2,s7,ffffffffc0204aec <do_execve+0x140>
            off = start + PGSIZE - la, size = PGSIZE - off;
ffffffffc0204d36:	6785                	lui	a5,0x1
ffffffffc0204d38:	00fb8533          	add	a0,s7,a5
ffffffffc0204d3c:	41550533          	sub	a0,a0,s5
                size -= la - end;
ffffffffc0204d40:	41790a33          	sub	s4,s2,s7
            if (end < la)
ffffffffc0204d44:	0b597d63          	bgeu	s2,s5,ffffffffc0204dfe <do_execve+0x452>
    return page - pages + nbase;
ffffffffc0204d48:	000cb683          	ld	a3,0(s9)
ffffffffc0204d4c:	67c2                	ld	a5,16(sp)
    return KADDR(page2pa(page));
ffffffffc0204d4e:	000c3603          	ld	a2,0(s8)
    return page - pages + nbase;
ffffffffc0204d52:	40d406b3          	sub	a3,s0,a3
ffffffffc0204d56:	8699                	srai	a3,a3,0x6
ffffffffc0204d58:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0204d5a:	67e2                	ld	a5,24(sp)
ffffffffc0204d5c:	00f6f5b3          	and	a1,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0204d60:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204d62:	0ac5f963          	bgeu	a1,a2,ffffffffc0204e14 <do_execve+0x468>
ffffffffc0204d66:	000b3803          	ld	a6,0(s6)
            memset(page2kva(page) + off, 0, size);
ffffffffc0204d6a:	8652                	mv	a2,s4
ffffffffc0204d6c:	4581                	li	a1,0
ffffffffc0204d6e:	96c2                	add	a3,a3,a6
ffffffffc0204d70:	9536                	add	a0,a0,a3
ffffffffc0204d72:	2cb000ef          	jal	ra,ffffffffc020583c <memset>
            start += size;
ffffffffc0204d76:	017a0733          	add	a4,s4,s7
            assert((end < la && start == end) || (end >= la && start == la));
ffffffffc0204d7a:	03597463          	bgeu	s2,s5,ffffffffc0204da2 <do_execve+0x3f6>
ffffffffc0204d7e:	d6e907e3          	beq	s2,a4,ffffffffc0204aec <do_execve+0x140>
ffffffffc0204d82:	00002697          	auipc	a3,0x2
ffffffffc0204d86:	5b668693          	addi	a3,a3,1462 # ffffffffc0207338 <default_pmm_manager+0xbd8>
ffffffffc0204d8a:	00001617          	auipc	a2,0x1
ffffffffc0204d8e:	62660613          	addi	a2,a2,1574 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc0204d92:	2cf00593          	li	a1,719
ffffffffc0204d96:	00002517          	auipc	a0,0x2
ffffffffc0204d9a:	3b250513          	addi	a0,a0,946 # ffffffffc0207148 <default_pmm_manager+0x9e8>
ffffffffc0204d9e:	ef0fb0ef          	jal	ra,ffffffffc020048e <__panic>
ffffffffc0204da2:	ff5710e3          	bne	a4,s5,ffffffffc0204d82 <do_execve+0x3d6>
ffffffffc0204da6:	8bd6                	mv	s7,s5
        while (start < end)
ffffffffc0204da8:	d52bf2e3          	bgeu	s7,s2,ffffffffc0204aec <do_execve+0x140>
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL)
ffffffffc0204dac:	6c88                	ld	a0,24(s1)
ffffffffc0204dae:	866a                	mv	a2,s10
ffffffffc0204db0:	85d6                	mv	a1,s5
ffffffffc0204db2:	9abfe0ef          	jal	ra,ffffffffc020375c <pgdir_alloc_page>
ffffffffc0204db6:	842a                	mv	s0,a0
ffffffffc0204db8:	dd05                	beqz	a0,ffffffffc0204cf0 <do_execve+0x344>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0204dba:	6785                	lui	a5,0x1
ffffffffc0204dbc:	415b8533          	sub	a0,s7,s5
ffffffffc0204dc0:	9abe                	add	s5,s5,a5
ffffffffc0204dc2:	417a8633          	sub	a2,s5,s7
            if (end < la)
ffffffffc0204dc6:	01597463          	bgeu	s2,s5,ffffffffc0204dce <do_execve+0x422>
                size -= la - end;
ffffffffc0204dca:	41790633          	sub	a2,s2,s7
    return page - pages + nbase;
ffffffffc0204dce:	000cb683          	ld	a3,0(s9)
ffffffffc0204dd2:	67c2                	ld	a5,16(sp)
    return KADDR(page2pa(page));
ffffffffc0204dd4:	000c3583          	ld	a1,0(s8)
    return page - pages + nbase;
ffffffffc0204dd8:	40d406b3          	sub	a3,s0,a3
ffffffffc0204ddc:	8699                	srai	a3,a3,0x6
ffffffffc0204dde:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0204de0:	67e2                	ld	a5,24(sp)
ffffffffc0204de2:	00f6f833          	and	a6,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0204de6:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204de8:	02b87663          	bgeu	a6,a1,ffffffffc0204e14 <do_execve+0x468>
ffffffffc0204dec:	000b3803          	ld	a6,0(s6)
            memset(page2kva(page) + off, 0, size);
ffffffffc0204df0:	4581                	li	a1,0
            start += size;
ffffffffc0204df2:	9bb2                	add	s7,s7,a2
ffffffffc0204df4:	96c2                	add	a3,a3,a6
            memset(page2kva(page) + off, 0, size);
ffffffffc0204df6:	9536                	add	a0,a0,a3
ffffffffc0204df8:	245000ef          	jal	ra,ffffffffc020583c <memset>
ffffffffc0204dfc:	b775                	j	ffffffffc0204da8 <do_execve+0x3fc>
            off = start + PGSIZE - la, size = PGSIZE - off;
ffffffffc0204dfe:	417a8a33          	sub	s4,s5,s7
ffffffffc0204e02:	b799                	j	ffffffffc0204d48 <do_execve+0x39c>
        return -E_INVAL;
ffffffffc0204e04:	5a75                	li	s4,-3
ffffffffc0204e06:	b3c1                	j	ffffffffc0204bc6 <do_execve+0x21a>
        while (start < end)
ffffffffc0204e08:	86de                	mv	a3,s7
ffffffffc0204e0a:	bf39                	j	ffffffffc0204d28 <do_execve+0x37c>
    int ret = -E_NO_MEM;
ffffffffc0204e0c:	5a71                	li	s4,-4
ffffffffc0204e0e:	bdc5                	j	ffffffffc0204cfe <do_execve+0x352>
            ret = -E_INVAL_ELF;
ffffffffc0204e10:	5a61                	li	s4,-8
ffffffffc0204e12:	b5c5                	j	ffffffffc0204cf2 <do_execve+0x346>
ffffffffc0204e14:	00001617          	auipc	a2,0x1
ffffffffc0204e18:	2a460613          	addi	a2,a2,676 # ffffffffc02060b8 <commands+0x5e8>
ffffffffc0204e1c:	07100593          	li	a1,113
ffffffffc0204e20:	00001517          	auipc	a0,0x1
ffffffffc0204e24:	28850513          	addi	a0,a0,648 # ffffffffc02060a8 <commands+0x5d8>
ffffffffc0204e28:	e66fb0ef          	jal	ra,ffffffffc020048e <__panic>
    current->pgdir = PADDR(mm->pgdir);
ffffffffc0204e2c:	00002617          	auipc	a2,0x2
ffffffffc0204e30:	9dc60613          	addi	a2,a2,-1572 # ffffffffc0206808 <default_pmm_manager+0xa8>
ffffffffc0204e34:	2ee00593          	li	a1,750
ffffffffc0204e38:	00002517          	auipc	a0,0x2
ffffffffc0204e3c:	31050513          	addi	a0,a0,784 # ffffffffc0207148 <default_pmm_manager+0x9e8>
ffffffffc0204e40:	e4efb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 4 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204e44:	00002697          	auipc	a3,0x2
ffffffffc0204e48:	60c68693          	addi	a3,a3,1548 # ffffffffc0207450 <default_pmm_manager+0xcf0>
ffffffffc0204e4c:	00001617          	auipc	a2,0x1
ffffffffc0204e50:	56460613          	addi	a2,a2,1380 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc0204e54:	2e900593          	li	a1,745
ffffffffc0204e58:	00002517          	auipc	a0,0x2
ffffffffc0204e5c:	2f050513          	addi	a0,a0,752 # ffffffffc0207148 <default_pmm_manager+0x9e8>
ffffffffc0204e60:	e2efb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 3 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204e64:	00002697          	auipc	a3,0x2
ffffffffc0204e68:	5a468693          	addi	a3,a3,1444 # ffffffffc0207408 <default_pmm_manager+0xca8>
ffffffffc0204e6c:	00001617          	auipc	a2,0x1
ffffffffc0204e70:	54460613          	addi	a2,a2,1348 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc0204e74:	2e800593          	li	a1,744
ffffffffc0204e78:	00002517          	auipc	a0,0x2
ffffffffc0204e7c:	2d050513          	addi	a0,a0,720 # ffffffffc0207148 <default_pmm_manager+0x9e8>
ffffffffc0204e80:	e0efb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 2 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204e84:	00002697          	auipc	a3,0x2
ffffffffc0204e88:	53c68693          	addi	a3,a3,1340 # ffffffffc02073c0 <default_pmm_manager+0xc60>
ffffffffc0204e8c:	00001617          	auipc	a2,0x1
ffffffffc0204e90:	52460613          	addi	a2,a2,1316 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc0204e94:	2e700593          	li	a1,743
ffffffffc0204e98:	00002517          	auipc	a0,0x2
ffffffffc0204e9c:	2b050513          	addi	a0,a0,688 # ffffffffc0207148 <default_pmm_manager+0x9e8>
ffffffffc0204ea0:	deefb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - PGSIZE, PTE_USER) != NULL);
ffffffffc0204ea4:	00002697          	auipc	a3,0x2
ffffffffc0204ea8:	4d468693          	addi	a3,a3,1236 # ffffffffc0207378 <default_pmm_manager+0xc18>
ffffffffc0204eac:	00001617          	auipc	a2,0x1
ffffffffc0204eb0:	50460613          	addi	a2,a2,1284 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc0204eb4:	2e600593          	li	a1,742
ffffffffc0204eb8:	00002517          	auipc	a0,0x2
ffffffffc0204ebc:	29050513          	addi	a0,a0,656 # ffffffffc0207148 <default_pmm_manager+0x9e8>
ffffffffc0204ec0:	dcefb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0204ec4 <do_yield>:
    current->need_resched = 1;
ffffffffc0204ec4:	000bb797          	auipc	a5,0xbb
ffffffffc0204ec8:	d3c7b783          	ld	a5,-708(a5) # ffffffffc02bfc00 <current>
ffffffffc0204ecc:	4705                	li	a4,1
ffffffffc0204ece:	ef98                	sd	a4,24(a5)
}
ffffffffc0204ed0:	4501                	li	a0,0
ffffffffc0204ed2:	8082                	ret

ffffffffc0204ed4 <do_wait>:
{
ffffffffc0204ed4:	1101                	addi	sp,sp,-32
ffffffffc0204ed6:	e822                	sd	s0,16(sp)
ffffffffc0204ed8:	e426                	sd	s1,8(sp)
ffffffffc0204eda:	ec06                	sd	ra,24(sp)
ffffffffc0204edc:	842e                	mv	s0,a1
ffffffffc0204ede:	84aa                	mv	s1,a0
    if (code_store != NULL)
ffffffffc0204ee0:	c999                	beqz	a1,ffffffffc0204ef6 <do_wait+0x22>
    struct mm_struct *mm = current->mm;
ffffffffc0204ee2:	000bb797          	auipc	a5,0xbb
ffffffffc0204ee6:	d1e7b783          	ld	a5,-738(a5) # ffffffffc02bfc00 <current>
        if (!user_mem_check(mm, (uintptr_t)code_store, sizeof(int), 1))
ffffffffc0204eea:	7788                	ld	a0,40(a5)
ffffffffc0204eec:	4685                	li	a3,1
ffffffffc0204eee:	4611                	li	a2,4
ffffffffc0204ef0:	fc9fe0ef          	jal	ra,ffffffffc0203eb8 <user_mem_check>
ffffffffc0204ef4:	c909                	beqz	a0,ffffffffc0204f06 <do_wait+0x32>
ffffffffc0204ef6:	85a2                	mv	a1,s0
}
ffffffffc0204ef8:	6442                	ld	s0,16(sp)
ffffffffc0204efa:	60e2                	ld	ra,24(sp)
ffffffffc0204efc:	8526                	mv	a0,s1
ffffffffc0204efe:	64a2                	ld	s1,8(sp)
ffffffffc0204f00:	6105                	addi	sp,sp,32
ffffffffc0204f02:	fb4ff06f          	j	ffffffffc02046b6 <do_wait.part.0>
ffffffffc0204f06:	60e2                	ld	ra,24(sp)
ffffffffc0204f08:	6442                	ld	s0,16(sp)
ffffffffc0204f0a:	64a2                	ld	s1,8(sp)
ffffffffc0204f0c:	5575                	li	a0,-3
ffffffffc0204f0e:	6105                	addi	sp,sp,32
ffffffffc0204f10:	8082                	ret

ffffffffc0204f12 <do_kill>:
{
ffffffffc0204f12:	1141                	addi	sp,sp,-16
    if (0 < pid && pid < MAX_PID)
ffffffffc0204f14:	6789                	lui	a5,0x2
{
ffffffffc0204f16:	e406                	sd	ra,8(sp)
ffffffffc0204f18:	e022                	sd	s0,0(sp)
    if (0 < pid && pid < MAX_PID)
ffffffffc0204f1a:	fff5071b          	addiw	a4,a0,-1
ffffffffc0204f1e:	17f9                	addi	a5,a5,-2
ffffffffc0204f20:	02e7e963          	bltu	a5,a4,ffffffffc0204f52 <do_kill+0x40>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204f24:	842a                	mv	s0,a0
ffffffffc0204f26:	45a9                	li	a1,10
ffffffffc0204f28:	2501                	sext.w	a0,a0
ffffffffc0204f2a:	46c000ef          	jal	ra,ffffffffc0205396 <hash32>
ffffffffc0204f2e:	02051793          	slli	a5,a0,0x20
ffffffffc0204f32:	01c7d513          	srli	a0,a5,0x1c
ffffffffc0204f36:	000b7797          	auipc	a5,0xb7
ffffffffc0204f3a:	c5a78793          	addi	a5,a5,-934 # ffffffffc02bbb90 <hash_list>
ffffffffc0204f3e:	953e                	add	a0,a0,a5
ffffffffc0204f40:	87aa                	mv	a5,a0
        while ((le = list_next(le)) != list)
ffffffffc0204f42:	a029                	j	ffffffffc0204f4c <do_kill+0x3a>
            if (proc->pid == pid)
ffffffffc0204f44:	f2c7a703          	lw	a4,-212(a5)
ffffffffc0204f48:	00870b63          	beq	a4,s0,ffffffffc0204f5e <do_kill+0x4c>
ffffffffc0204f4c:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc0204f4e:	fef51be3          	bne	a0,a5,ffffffffc0204f44 <do_kill+0x32>
    return -E_INVAL;
ffffffffc0204f52:	5475                	li	s0,-3
}
ffffffffc0204f54:	60a2                	ld	ra,8(sp)
ffffffffc0204f56:	8522                	mv	a0,s0
ffffffffc0204f58:	6402                	ld	s0,0(sp)
ffffffffc0204f5a:	0141                	addi	sp,sp,16
ffffffffc0204f5c:	8082                	ret
        if (!(proc->flags & PF_EXITING))
ffffffffc0204f5e:	fd87a703          	lw	a4,-40(a5)
ffffffffc0204f62:	00177693          	andi	a3,a4,1
ffffffffc0204f66:	e295                	bnez	a3,ffffffffc0204f8a <do_kill+0x78>
            if (proc->wait_state & WT_INTERRUPTED)
ffffffffc0204f68:	4bd4                	lw	a3,20(a5)
            proc->flags |= PF_EXITING;
ffffffffc0204f6a:	00176713          	ori	a4,a4,1
ffffffffc0204f6e:	fce7ac23          	sw	a4,-40(a5)
            return 0;
ffffffffc0204f72:	4401                	li	s0,0
            if (proc->wait_state & WT_INTERRUPTED)
ffffffffc0204f74:	fe06d0e3          	bgez	a3,ffffffffc0204f54 <do_kill+0x42>
                wakeup_proc(proc);
ffffffffc0204f78:	f2878513          	addi	a0,a5,-216
ffffffffc0204f7c:	22e000ef          	jal	ra,ffffffffc02051aa <wakeup_proc>
}
ffffffffc0204f80:	60a2                	ld	ra,8(sp)
ffffffffc0204f82:	8522                	mv	a0,s0
ffffffffc0204f84:	6402                	ld	s0,0(sp)
ffffffffc0204f86:	0141                	addi	sp,sp,16
ffffffffc0204f88:	8082                	ret
        return -E_KILLED;
ffffffffc0204f8a:	545d                	li	s0,-9
ffffffffc0204f8c:	b7e1                	j	ffffffffc0204f54 <do_kill+0x42>

ffffffffc0204f8e <proc_init>:

// proc_init - set up the first kernel thread idleproc "idle" by itself and
//           - create the second kernel thread init_main
void proc_init(void)
{
ffffffffc0204f8e:	1101                	addi	sp,sp,-32
ffffffffc0204f90:	e426                	sd	s1,8(sp)
    elm->prev = elm->next = elm;
ffffffffc0204f92:	000bb797          	auipc	a5,0xbb
ffffffffc0204f96:	bfe78793          	addi	a5,a5,-1026 # ffffffffc02bfb90 <proc_list>
ffffffffc0204f9a:	ec06                	sd	ra,24(sp)
ffffffffc0204f9c:	e822                	sd	s0,16(sp)
ffffffffc0204f9e:	e04a                	sd	s2,0(sp)
ffffffffc0204fa0:	000b7497          	auipc	s1,0xb7
ffffffffc0204fa4:	bf048493          	addi	s1,s1,-1040 # ffffffffc02bbb90 <hash_list>
ffffffffc0204fa8:	e79c                	sd	a5,8(a5)
ffffffffc0204faa:	e39c                	sd	a5,0(a5)
    int i;

    list_init(&proc_list);
    for (i = 0; i < HASH_LIST_SIZE; i++)
ffffffffc0204fac:	000bb717          	auipc	a4,0xbb
ffffffffc0204fb0:	be470713          	addi	a4,a4,-1052 # ffffffffc02bfb90 <proc_list>
ffffffffc0204fb4:	87a6                	mv	a5,s1
ffffffffc0204fb6:	e79c                	sd	a5,8(a5)
ffffffffc0204fb8:	e39c                	sd	a5,0(a5)
ffffffffc0204fba:	07c1                	addi	a5,a5,16
ffffffffc0204fbc:	fef71de3          	bne	a4,a5,ffffffffc0204fb6 <proc_init+0x28>
    {
        list_init(hash_list + i);
    }

    if ((idleproc = alloc_proc()) == NULL)
ffffffffc0204fc0:	f95fe0ef          	jal	ra,ffffffffc0203f54 <alloc_proc>
ffffffffc0204fc4:	000bb917          	auipc	s2,0xbb
ffffffffc0204fc8:	c4490913          	addi	s2,s2,-956 # ffffffffc02bfc08 <idleproc>
ffffffffc0204fcc:	00a93023          	sd	a0,0(s2)
ffffffffc0204fd0:	0e050f63          	beqz	a0,ffffffffc02050ce <proc_init+0x140>
    {
        panic("cannot alloc idleproc.\n");
    }

    idleproc->pid = 0;
    idleproc->state = PROC_RUNNABLE;
ffffffffc0204fd4:	4789                	li	a5,2
ffffffffc0204fd6:	e11c                	sd	a5,0(a0)
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc0204fd8:	00003797          	auipc	a5,0x3
ffffffffc0204fdc:	02878793          	addi	a5,a5,40 # ffffffffc0208000 <bootstack>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204fe0:	0b450413          	addi	s0,a0,180
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc0204fe4:	e91c                	sd	a5,16(a0)
    idleproc->need_resched = 1;
ffffffffc0204fe6:	4785                	li	a5,1
ffffffffc0204fe8:	ed1c                	sd	a5,24(a0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204fea:	4641                	li	a2,16
ffffffffc0204fec:	4581                	li	a1,0
ffffffffc0204fee:	8522                	mv	a0,s0
ffffffffc0204ff0:	04d000ef          	jal	ra,ffffffffc020583c <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0204ff4:	463d                	li	a2,15
ffffffffc0204ff6:	00002597          	auipc	a1,0x2
ffffffffc0204ffa:	4ba58593          	addi	a1,a1,1210 # ffffffffc02074b0 <default_pmm_manager+0xd50>
ffffffffc0204ffe:	8522                	mv	a0,s0
ffffffffc0205000:	04f000ef          	jal	ra,ffffffffc020584e <memcpy>
    set_proc_name(idleproc, "idle");
    nr_process++;
ffffffffc0205004:	000bb717          	auipc	a4,0xbb
ffffffffc0205008:	c1470713          	addi	a4,a4,-1004 # ffffffffc02bfc18 <nr_process>
ffffffffc020500c:	431c                	lw	a5,0(a4)

    current = idleproc;
ffffffffc020500e:	00093683          	ld	a3,0(s2)

    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0205012:	4601                	li	a2,0
    nr_process++;
ffffffffc0205014:	2785                	addiw	a5,a5,1
    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0205016:	4581                	li	a1,0
ffffffffc0205018:	00000517          	auipc	a0,0x0
ffffffffc020501c:	87050513          	addi	a0,a0,-1936 # ffffffffc0204888 <init_main>
    nr_process++;
ffffffffc0205020:	c31c                	sw	a5,0(a4)
    current = idleproc;
ffffffffc0205022:	000bb797          	auipc	a5,0xbb
ffffffffc0205026:	bcd7bf23          	sd	a3,-1058(a5) # ffffffffc02bfc00 <current>
    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc020502a:	cf2ff0ef          	jal	ra,ffffffffc020451c <kernel_thread>
ffffffffc020502e:	842a                	mv	s0,a0
    if (pid <= 0)
ffffffffc0205030:	08a05363          	blez	a0,ffffffffc02050b6 <proc_init+0x128>
    if (0 < pid && pid < MAX_PID)
ffffffffc0205034:	6789                	lui	a5,0x2
ffffffffc0205036:	fff5071b          	addiw	a4,a0,-1
ffffffffc020503a:	17f9                	addi	a5,a5,-2
ffffffffc020503c:	2501                	sext.w	a0,a0
ffffffffc020503e:	02e7e363          	bltu	a5,a4,ffffffffc0205064 <proc_init+0xd6>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0205042:	45a9                	li	a1,10
ffffffffc0205044:	352000ef          	jal	ra,ffffffffc0205396 <hash32>
ffffffffc0205048:	02051793          	slli	a5,a0,0x20
ffffffffc020504c:	01c7d693          	srli	a3,a5,0x1c
ffffffffc0205050:	96a6                	add	a3,a3,s1
ffffffffc0205052:	87b6                	mv	a5,a3
        while ((le = list_next(le)) != list)
ffffffffc0205054:	a029                	j	ffffffffc020505e <proc_init+0xd0>
            if (proc->pid == pid)
ffffffffc0205056:	f2c7a703          	lw	a4,-212(a5) # 1f2c <_binary_obj___user_faultread_out_size-0x7ca4>
ffffffffc020505a:	04870b63          	beq	a4,s0,ffffffffc02050b0 <proc_init+0x122>
    return listelm->next;
ffffffffc020505e:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc0205060:	fef69be3          	bne	a3,a5,ffffffffc0205056 <proc_init+0xc8>
    return NULL;
ffffffffc0205064:	4781                	li	a5,0
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0205066:	0b478493          	addi	s1,a5,180
ffffffffc020506a:	4641                	li	a2,16
ffffffffc020506c:	4581                	li	a1,0
    {
        panic("create init_main failed.\n");
    }

    initproc = find_proc(pid);
ffffffffc020506e:	000bb417          	auipc	s0,0xbb
ffffffffc0205072:	ba240413          	addi	s0,s0,-1118 # ffffffffc02bfc10 <initproc>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0205076:	8526                	mv	a0,s1
    initproc = find_proc(pid);
ffffffffc0205078:	e01c                	sd	a5,0(s0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc020507a:	7c2000ef          	jal	ra,ffffffffc020583c <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc020507e:	463d                	li	a2,15
ffffffffc0205080:	00002597          	auipc	a1,0x2
ffffffffc0205084:	45858593          	addi	a1,a1,1112 # ffffffffc02074d8 <default_pmm_manager+0xd78>
ffffffffc0205088:	8526                	mv	a0,s1
ffffffffc020508a:	7c4000ef          	jal	ra,ffffffffc020584e <memcpy>
    set_proc_name(initproc, "init");

    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc020508e:	00093783          	ld	a5,0(s2)
ffffffffc0205092:	cbb5                	beqz	a5,ffffffffc0205106 <proc_init+0x178>
ffffffffc0205094:	43dc                	lw	a5,4(a5)
ffffffffc0205096:	eba5                	bnez	a5,ffffffffc0205106 <proc_init+0x178>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc0205098:	601c                	ld	a5,0(s0)
ffffffffc020509a:	c7b1                	beqz	a5,ffffffffc02050e6 <proc_init+0x158>
ffffffffc020509c:	43d8                	lw	a4,4(a5)
ffffffffc020509e:	4785                	li	a5,1
ffffffffc02050a0:	04f71363          	bne	a4,a5,ffffffffc02050e6 <proc_init+0x158>
}
ffffffffc02050a4:	60e2                	ld	ra,24(sp)
ffffffffc02050a6:	6442                	ld	s0,16(sp)
ffffffffc02050a8:	64a2                	ld	s1,8(sp)
ffffffffc02050aa:	6902                	ld	s2,0(sp)
ffffffffc02050ac:	6105                	addi	sp,sp,32
ffffffffc02050ae:	8082                	ret
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc02050b0:	f2878793          	addi	a5,a5,-216
ffffffffc02050b4:	bf4d                	j	ffffffffc0205066 <proc_init+0xd8>
        panic("create init_main failed.\n");
ffffffffc02050b6:	00002617          	auipc	a2,0x2
ffffffffc02050ba:	40260613          	addi	a2,a2,1026 # ffffffffc02074b8 <default_pmm_manager+0xd58>
ffffffffc02050be:	41700593          	li	a1,1047
ffffffffc02050c2:	00002517          	auipc	a0,0x2
ffffffffc02050c6:	08650513          	addi	a0,a0,134 # ffffffffc0207148 <default_pmm_manager+0x9e8>
ffffffffc02050ca:	bc4fb0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("cannot alloc idleproc.\n");
ffffffffc02050ce:	00002617          	auipc	a2,0x2
ffffffffc02050d2:	3ca60613          	addi	a2,a2,970 # ffffffffc0207498 <default_pmm_manager+0xd38>
ffffffffc02050d6:	40800593          	li	a1,1032
ffffffffc02050da:	00002517          	auipc	a0,0x2
ffffffffc02050de:	06e50513          	addi	a0,a0,110 # ffffffffc0207148 <default_pmm_manager+0x9e8>
ffffffffc02050e2:	bacfb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc02050e6:	00002697          	auipc	a3,0x2
ffffffffc02050ea:	42268693          	addi	a3,a3,1058 # ffffffffc0207508 <default_pmm_manager+0xda8>
ffffffffc02050ee:	00001617          	auipc	a2,0x1
ffffffffc02050f2:	2c260613          	addi	a2,a2,706 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc02050f6:	41e00593          	li	a1,1054
ffffffffc02050fa:	00002517          	auipc	a0,0x2
ffffffffc02050fe:	04e50513          	addi	a0,a0,78 # ffffffffc0207148 <default_pmm_manager+0x9e8>
ffffffffc0205102:	b8cfb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc0205106:	00002697          	auipc	a3,0x2
ffffffffc020510a:	3da68693          	addi	a3,a3,986 # ffffffffc02074e0 <default_pmm_manager+0xd80>
ffffffffc020510e:	00001617          	auipc	a2,0x1
ffffffffc0205112:	2a260613          	addi	a2,a2,674 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc0205116:	41d00593          	li	a1,1053
ffffffffc020511a:	00002517          	auipc	a0,0x2
ffffffffc020511e:	02e50513          	addi	a0,a0,46 # ffffffffc0207148 <default_pmm_manager+0x9e8>
ffffffffc0205122:	b6cfb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0205126 <cpu_idle>:

// cpu_idle - at the end of kern_init, the first kernel thread idleproc will do below works
void cpu_idle(void)
{
ffffffffc0205126:	1141                	addi	sp,sp,-16
ffffffffc0205128:	e022                	sd	s0,0(sp)
ffffffffc020512a:	e406                	sd	ra,8(sp)
ffffffffc020512c:	000bb417          	auipc	s0,0xbb
ffffffffc0205130:	ad440413          	addi	s0,s0,-1324 # ffffffffc02bfc00 <current>
    while (1)
    {
        if (current->need_resched)
ffffffffc0205134:	6018                	ld	a4,0(s0)
ffffffffc0205136:	6f1c                	ld	a5,24(a4)
ffffffffc0205138:	dffd                	beqz	a5,ffffffffc0205136 <cpu_idle+0x10>
        {
            schedule();
ffffffffc020513a:	0f0000ef          	jal	ra,ffffffffc020522a <schedule>
ffffffffc020513e:	bfdd                	j	ffffffffc0205134 <cpu_idle+0xe>

ffffffffc0205140 <switch_to>:
.text
# void switch_to(struct proc_struct* from, struct proc_struct* to)
.globl switch_to
switch_to:
    # save from's registers
    STORE ra, 0*REGBYTES(a0)
ffffffffc0205140:	00153023          	sd	ra,0(a0)
    STORE sp, 1*REGBYTES(a0)
ffffffffc0205144:	00253423          	sd	sp,8(a0)
    STORE s0, 2*REGBYTES(a0)
ffffffffc0205148:	e900                	sd	s0,16(a0)
    STORE s1, 3*REGBYTES(a0)
ffffffffc020514a:	ed04                	sd	s1,24(a0)
    STORE s2, 4*REGBYTES(a0)
ffffffffc020514c:	03253023          	sd	s2,32(a0)
    STORE s3, 5*REGBYTES(a0)
ffffffffc0205150:	03353423          	sd	s3,40(a0)
    STORE s4, 6*REGBYTES(a0)
ffffffffc0205154:	03453823          	sd	s4,48(a0)
    STORE s5, 7*REGBYTES(a0)
ffffffffc0205158:	03553c23          	sd	s5,56(a0)
    STORE s6, 8*REGBYTES(a0)
ffffffffc020515c:	05653023          	sd	s6,64(a0)
    STORE s7, 9*REGBYTES(a0)
ffffffffc0205160:	05753423          	sd	s7,72(a0)
    STORE s8, 10*REGBYTES(a0)
ffffffffc0205164:	05853823          	sd	s8,80(a0)
    STORE s9, 11*REGBYTES(a0)
ffffffffc0205168:	05953c23          	sd	s9,88(a0)
    STORE s10, 12*REGBYTES(a0)
ffffffffc020516c:	07a53023          	sd	s10,96(a0)
    STORE s11, 13*REGBYTES(a0)
ffffffffc0205170:	07b53423          	sd	s11,104(a0)

    # restore to's registers
    LOAD ra, 0*REGBYTES(a1)
ffffffffc0205174:	0005b083          	ld	ra,0(a1)
    LOAD sp, 1*REGBYTES(a1)
ffffffffc0205178:	0085b103          	ld	sp,8(a1)
    LOAD s0, 2*REGBYTES(a1)
ffffffffc020517c:	6980                	ld	s0,16(a1)
    LOAD s1, 3*REGBYTES(a1)
ffffffffc020517e:	6d84                	ld	s1,24(a1)
    LOAD s2, 4*REGBYTES(a1)
ffffffffc0205180:	0205b903          	ld	s2,32(a1)
    LOAD s3, 5*REGBYTES(a1)
ffffffffc0205184:	0285b983          	ld	s3,40(a1)
    LOAD s4, 6*REGBYTES(a1)
ffffffffc0205188:	0305ba03          	ld	s4,48(a1)
    LOAD s5, 7*REGBYTES(a1)
ffffffffc020518c:	0385ba83          	ld	s5,56(a1)
    LOAD s6, 8*REGBYTES(a1)
ffffffffc0205190:	0405bb03          	ld	s6,64(a1)
    LOAD s7, 9*REGBYTES(a1)
ffffffffc0205194:	0485bb83          	ld	s7,72(a1)
    LOAD s8, 10*REGBYTES(a1)
ffffffffc0205198:	0505bc03          	ld	s8,80(a1)
    LOAD s9, 11*REGBYTES(a1)
ffffffffc020519c:	0585bc83          	ld	s9,88(a1)
    LOAD s10, 12*REGBYTES(a1)
ffffffffc02051a0:	0605bd03          	ld	s10,96(a1)
    LOAD s11, 13*REGBYTES(a1)
ffffffffc02051a4:	0685bd83          	ld	s11,104(a1)

    ret
ffffffffc02051a8:	8082                	ret

ffffffffc02051aa <wakeup_proc>:
#include <sched.h>
#include <assert.h>

void wakeup_proc(struct proc_struct *proc)
{
    assert(proc->state != PROC_ZOMBIE);
ffffffffc02051aa:	4118                	lw	a4,0(a0)
{
ffffffffc02051ac:	1101                	addi	sp,sp,-32
ffffffffc02051ae:	ec06                	sd	ra,24(sp)
ffffffffc02051b0:	e822                	sd	s0,16(sp)
ffffffffc02051b2:	e426                	sd	s1,8(sp)
    assert(proc->state != PROC_ZOMBIE);
ffffffffc02051b4:	478d                	li	a5,3
ffffffffc02051b6:	04f70b63          	beq	a4,a5,ffffffffc020520c <wakeup_proc+0x62>
ffffffffc02051ba:	842a                	mv	s0,a0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02051bc:	100027f3          	csrr	a5,sstatus
ffffffffc02051c0:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02051c2:	4481                	li	s1,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02051c4:	ef9d                	bnez	a5,ffffffffc0205202 <wakeup_proc+0x58>
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        if (proc->state != PROC_RUNNABLE)
ffffffffc02051c6:	4789                	li	a5,2
ffffffffc02051c8:	02f70163          	beq	a4,a5,ffffffffc02051ea <wakeup_proc+0x40>
        {
            proc->state = PROC_RUNNABLE;
ffffffffc02051cc:	c01c                	sw	a5,0(s0)
            proc->wait_state = 0;
ffffffffc02051ce:	0e042623          	sw	zero,236(s0)
    if (flag)
ffffffffc02051d2:	e491                	bnez	s1,ffffffffc02051de <wakeup_proc+0x34>
        {
            warn("wakeup runnable process.\n");
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc02051d4:	60e2                	ld	ra,24(sp)
ffffffffc02051d6:	6442                	ld	s0,16(sp)
ffffffffc02051d8:	64a2                	ld	s1,8(sp)
ffffffffc02051da:	6105                	addi	sp,sp,32
ffffffffc02051dc:	8082                	ret
ffffffffc02051de:	6442                	ld	s0,16(sp)
ffffffffc02051e0:	60e2                	ld	ra,24(sp)
ffffffffc02051e2:	64a2                	ld	s1,8(sp)
ffffffffc02051e4:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc02051e6:	fc8fb06f          	j	ffffffffc02009ae <intr_enable>
            warn("wakeup runnable process.\n");
ffffffffc02051ea:	00002617          	auipc	a2,0x2
ffffffffc02051ee:	37e60613          	addi	a2,a2,894 # ffffffffc0207568 <default_pmm_manager+0xe08>
ffffffffc02051f2:	45d1                	li	a1,20
ffffffffc02051f4:	00002517          	auipc	a0,0x2
ffffffffc02051f8:	35c50513          	addi	a0,a0,860 # ffffffffc0207550 <default_pmm_manager+0xdf0>
ffffffffc02051fc:	afafb0ef          	jal	ra,ffffffffc02004f6 <__warn>
ffffffffc0205200:	bfc9                	j	ffffffffc02051d2 <wakeup_proc+0x28>
        intr_disable();
ffffffffc0205202:	fb2fb0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        if (proc->state != PROC_RUNNABLE)
ffffffffc0205206:	4018                	lw	a4,0(s0)
        return 1;
ffffffffc0205208:	4485                	li	s1,1
ffffffffc020520a:	bf75                	j	ffffffffc02051c6 <wakeup_proc+0x1c>
    assert(proc->state != PROC_ZOMBIE);
ffffffffc020520c:	00002697          	auipc	a3,0x2
ffffffffc0205210:	32468693          	addi	a3,a3,804 # ffffffffc0207530 <default_pmm_manager+0xdd0>
ffffffffc0205214:	00001617          	auipc	a2,0x1
ffffffffc0205218:	19c60613          	addi	a2,a2,412 # ffffffffc02063b0 <commands+0x8e0>
ffffffffc020521c:	45a5                	li	a1,9
ffffffffc020521e:	00002517          	auipc	a0,0x2
ffffffffc0205222:	33250513          	addi	a0,a0,818 # ffffffffc0207550 <default_pmm_manager+0xdf0>
ffffffffc0205226:	a68fb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc020522a <schedule>:

void schedule(void)
{
ffffffffc020522a:	1141                	addi	sp,sp,-16
ffffffffc020522c:	e406                	sd	ra,8(sp)
ffffffffc020522e:	e022                	sd	s0,0(sp)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0205230:	100027f3          	csrr	a5,sstatus
ffffffffc0205234:	8b89                	andi	a5,a5,2
ffffffffc0205236:	4401                	li	s0,0
ffffffffc0205238:	efbd                	bnez	a5,ffffffffc02052b6 <schedule+0x8c>
    bool intr_flag;
    list_entry_t *le, *last;
    struct proc_struct *next = NULL;
    local_intr_save(intr_flag);
    {
        current->need_resched = 0;
ffffffffc020523a:	000bb897          	auipc	a7,0xbb
ffffffffc020523e:	9c68b883          	ld	a7,-1594(a7) # ffffffffc02bfc00 <current>
ffffffffc0205242:	0008bc23          	sd	zero,24(a7)
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc0205246:	000bb517          	auipc	a0,0xbb
ffffffffc020524a:	9c253503          	ld	a0,-1598(a0) # ffffffffc02bfc08 <idleproc>
ffffffffc020524e:	04a88e63          	beq	a7,a0,ffffffffc02052aa <schedule+0x80>
ffffffffc0205252:	0c888693          	addi	a3,a7,200
ffffffffc0205256:	000bb617          	auipc	a2,0xbb
ffffffffc020525a:	93a60613          	addi	a2,a2,-1734 # ffffffffc02bfb90 <proc_list>
        le = last;
ffffffffc020525e:	87b6                	mv	a5,a3
    struct proc_struct *next = NULL;
ffffffffc0205260:	4581                	li	a1,0
        do
        {
            if ((le = list_next(le)) != &proc_list)
            {
                next = le2proc(le, list_link);
                if (next->state == PROC_RUNNABLE)
ffffffffc0205262:	4809                	li	a6,2
ffffffffc0205264:	679c                	ld	a5,8(a5)
            if ((le = list_next(le)) != &proc_list)
ffffffffc0205266:	00c78863          	beq	a5,a2,ffffffffc0205276 <schedule+0x4c>
                if (next->state == PROC_RUNNABLE)
ffffffffc020526a:	f387a703          	lw	a4,-200(a5)
                next = le2proc(le, list_link);
ffffffffc020526e:	f3878593          	addi	a1,a5,-200
                if (next->state == PROC_RUNNABLE)
ffffffffc0205272:	03070163          	beq	a4,a6,ffffffffc0205294 <schedule+0x6a>
                {
                    break;
                }
            }
        } while (le != last);
ffffffffc0205276:	fef697e3          	bne	a3,a5,ffffffffc0205264 <schedule+0x3a>
        if (next == NULL || next->state != PROC_RUNNABLE)
ffffffffc020527a:	ed89                	bnez	a1,ffffffffc0205294 <schedule+0x6a>
        {
            next = idleproc;
        }
        next->runs++;
ffffffffc020527c:	451c                	lw	a5,8(a0)
ffffffffc020527e:	2785                	addiw	a5,a5,1
ffffffffc0205280:	c51c                	sw	a5,8(a0)
        if (next != current)
ffffffffc0205282:	00a88463          	beq	a7,a0,ffffffffc020528a <schedule+0x60>
        {
            proc_run(next);
ffffffffc0205286:	e53fe0ef          	jal	ra,ffffffffc02040d8 <proc_run>
    if (flag)
ffffffffc020528a:	e819                	bnez	s0,ffffffffc02052a0 <schedule+0x76>
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc020528c:	60a2                	ld	ra,8(sp)
ffffffffc020528e:	6402                	ld	s0,0(sp)
ffffffffc0205290:	0141                	addi	sp,sp,16
ffffffffc0205292:	8082                	ret
        if (next == NULL || next->state != PROC_RUNNABLE)
ffffffffc0205294:	4198                	lw	a4,0(a1)
ffffffffc0205296:	4789                	li	a5,2
ffffffffc0205298:	fef712e3          	bne	a4,a5,ffffffffc020527c <schedule+0x52>
ffffffffc020529c:	852e                	mv	a0,a1
ffffffffc020529e:	bff9                	j	ffffffffc020527c <schedule+0x52>
}
ffffffffc02052a0:	6402                	ld	s0,0(sp)
ffffffffc02052a2:	60a2                	ld	ra,8(sp)
ffffffffc02052a4:	0141                	addi	sp,sp,16
        intr_enable();
ffffffffc02052a6:	f08fb06f          	j	ffffffffc02009ae <intr_enable>
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc02052aa:	000bb617          	auipc	a2,0xbb
ffffffffc02052ae:	8e660613          	addi	a2,a2,-1818 # ffffffffc02bfb90 <proc_list>
ffffffffc02052b2:	86b2                	mv	a3,a2
ffffffffc02052b4:	b76d                	j	ffffffffc020525e <schedule+0x34>
        intr_disable();
ffffffffc02052b6:	efefb0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc02052ba:	4405                	li	s0,1
ffffffffc02052bc:	bfbd                	j	ffffffffc020523a <schedule+0x10>

ffffffffc02052be <sys_getpid>:
    return do_kill(pid);
}

static int
sys_getpid(uint64_t arg[]) {
    return current->pid;
ffffffffc02052be:	000bb797          	auipc	a5,0xbb
ffffffffc02052c2:	9427b783          	ld	a5,-1726(a5) # ffffffffc02bfc00 <current>
}
ffffffffc02052c6:	43c8                	lw	a0,4(a5)
ffffffffc02052c8:	8082                	ret

ffffffffc02052ca <sys_pgdir>:

static int
sys_pgdir(uint64_t arg[]) {
    //print_pgdir();
    return 0;
}
ffffffffc02052ca:	4501                	li	a0,0
ffffffffc02052cc:	8082                	ret

ffffffffc02052ce <sys_putc>:
    cputchar(c);
ffffffffc02052ce:	4108                	lw	a0,0(a0)
sys_putc(uint64_t arg[]) {
ffffffffc02052d0:	1141                	addi	sp,sp,-16
ffffffffc02052d2:	e406                	sd	ra,8(sp)
    cputchar(c);
ffffffffc02052d4:	ef7fa0ef          	jal	ra,ffffffffc02001ca <cputchar>
}
ffffffffc02052d8:	60a2                	ld	ra,8(sp)
ffffffffc02052da:	4501                	li	a0,0
ffffffffc02052dc:	0141                	addi	sp,sp,16
ffffffffc02052de:	8082                	ret

ffffffffc02052e0 <sys_kill>:
    return do_kill(pid);
ffffffffc02052e0:	4108                	lw	a0,0(a0)
ffffffffc02052e2:	c31ff06f          	j	ffffffffc0204f12 <do_kill>

ffffffffc02052e6 <sys_yield>:
    return do_yield();
ffffffffc02052e6:	bdfff06f          	j	ffffffffc0204ec4 <do_yield>

ffffffffc02052ea <sys_exec>:
    return do_execve(name, len, binary, size);
ffffffffc02052ea:	6d14                	ld	a3,24(a0)
ffffffffc02052ec:	6910                	ld	a2,16(a0)
ffffffffc02052ee:	650c                	ld	a1,8(a0)
ffffffffc02052f0:	6108                	ld	a0,0(a0)
ffffffffc02052f2:	ebaff06f          	j	ffffffffc02049ac <do_execve>

ffffffffc02052f6 <sys_wait>:
    return do_wait(pid, store);
ffffffffc02052f6:	650c                	ld	a1,8(a0)
ffffffffc02052f8:	4108                	lw	a0,0(a0)
ffffffffc02052fa:	bdbff06f          	j	ffffffffc0204ed4 <do_wait>

ffffffffc02052fe <sys_fork>:
    struct trapframe *tf = current->tf;
ffffffffc02052fe:	000bb797          	auipc	a5,0xbb
ffffffffc0205302:	9027b783          	ld	a5,-1790(a5) # ffffffffc02bfc00 <current>
ffffffffc0205306:	73d0                	ld	a2,160(a5)
    return do_fork(0, stack, tf);
ffffffffc0205308:	4501                	li	a0,0
ffffffffc020530a:	6a0c                	ld	a1,16(a2)
ffffffffc020530c:	e37fe06f          	j	ffffffffc0204142 <do_fork>

ffffffffc0205310 <sys_exit>:
    return do_exit(error_code);
ffffffffc0205310:	4108                	lw	a0,0(a0)
ffffffffc0205312:	a5aff06f          	j	ffffffffc020456c <do_exit>

ffffffffc0205316 <syscall>:
};

#define NUM_SYSCALLS        ((sizeof(syscalls)) / (sizeof(syscalls[0])))

void
syscall(void) {
ffffffffc0205316:	715d                	addi	sp,sp,-80
ffffffffc0205318:	fc26                	sd	s1,56(sp)
    struct trapframe *tf = current->tf;
ffffffffc020531a:	000bb497          	auipc	s1,0xbb
ffffffffc020531e:	8e648493          	addi	s1,s1,-1818 # ffffffffc02bfc00 <current>
ffffffffc0205322:	6098                	ld	a4,0(s1)
syscall(void) {
ffffffffc0205324:	e0a2                	sd	s0,64(sp)
ffffffffc0205326:	f84a                	sd	s2,48(sp)
    struct trapframe *tf = current->tf;
ffffffffc0205328:	7340                	ld	s0,160(a4)
syscall(void) {
ffffffffc020532a:	e486                	sd	ra,72(sp)
    uint64_t arg[5];
    int num = tf->gpr.a0;
    if (num >= 0 && num < NUM_SYSCALLS) {
ffffffffc020532c:	47fd                	li	a5,31
    int num = tf->gpr.a0;
ffffffffc020532e:	05042903          	lw	s2,80(s0)
    if (num >= 0 && num < NUM_SYSCALLS) {
ffffffffc0205332:	0327ee63          	bltu	a5,s2,ffffffffc020536e <syscall+0x58>
        if (syscalls[num] != NULL) {
ffffffffc0205336:	00391713          	slli	a4,s2,0x3
ffffffffc020533a:	00002797          	auipc	a5,0x2
ffffffffc020533e:	29678793          	addi	a5,a5,662 # ffffffffc02075d0 <syscalls>
ffffffffc0205342:	97ba                	add	a5,a5,a4
ffffffffc0205344:	639c                	ld	a5,0(a5)
ffffffffc0205346:	c785                	beqz	a5,ffffffffc020536e <syscall+0x58>
            arg[0] = tf->gpr.a1;
ffffffffc0205348:	6c28                	ld	a0,88(s0)
            arg[1] = tf->gpr.a2;
ffffffffc020534a:	702c                	ld	a1,96(s0)
            arg[2] = tf->gpr.a3;
ffffffffc020534c:	7430                	ld	a2,104(s0)
            arg[3] = tf->gpr.a4;
ffffffffc020534e:	7834                	ld	a3,112(s0)
            arg[4] = tf->gpr.a5;
ffffffffc0205350:	7c38                	ld	a4,120(s0)
            arg[0] = tf->gpr.a1;
ffffffffc0205352:	e42a                	sd	a0,8(sp)
            arg[1] = tf->gpr.a2;
ffffffffc0205354:	e82e                	sd	a1,16(sp)
            arg[2] = tf->gpr.a3;
ffffffffc0205356:	ec32                	sd	a2,24(sp)
            arg[3] = tf->gpr.a4;
ffffffffc0205358:	f036                	sd	a3,32(sp)
            arg[4] = tf->gpr.a5;
ffffffffc020535a:	f43a                	sd	a4,40(sp)
            tf->gpr.a0 = syscalls[num](arg);
ffffffffc020535c:	0028                	addi	a0,sp,8
ffffffffc020535e:	9782                	jalr	a5
        }
    }
    print_trapframe(tf);
    panic("undefined syscall %d, pid = %d, name = %s.\n",
            num, current->pid, current->name);
}
ffffffffc0205360:	60a6                	ld	ra,72(sp)
            tf->gpr.a0 = syscalls[num](arg);
ffffffffc0205362:	e828                	sd	a0,80(s0)
}
ffffffffc0205364:	6406                	ld	s0,64(sp)
ffffffffc0205366:	74e2                	ld	s1,56(sp)
ffffffffc0205368:	7942                	ld	s2,48(sp)
ffffffffc020536a:	6161                	addi	sp,sp,80
ffffffffc020536c:	8082                	ret
    print_trapframe(tf);
ffffffffc020536e:	8522                	mv	a0,s0
ffffffffc0205370:	835fb0ef          	jal	ra,ffffffffc0200ba4 <print_trapframe>
    panic("undefined syscall %d, pid = %d, name = %s.\n",
ffffffffc0205374:	609c                	ld	a5,0(s1)
ffffffffc0205376:	86ca                	mv	a3,s2
ffffffffc0205378:	00002617          	auipc	a2,0x2
ffffffffc020537c:	21060613          	addi	a2,a2,528 # ffffffffc0207588 <default_pmm_manager+0xe28>
ffffffffc0205380:	43d8                	lw	a4,4(a5)
ffffffffc0205382:	06200593          	li	a1,98
ffffffffc0205386:	0b478793          	addi	a5,a5,180
ffffffffc020538a:	00002517          	auipc	a0,0x2
ffffffffc020538e:	22e50513          	addi	a0,a0,558 # ffffffffc02075b8 <default_pmm_manager+0xe58>
ffffffffc0205392:	8fcfb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0205396 <hash32>:
 *
 * High bits are more random, so we use them.
 * */
uint32_t
hash32(uint32_t val, unsigned int bits) {
    uint32_t hash = val * GOLDEN_RATIO_PRIME_32;
ffffffffc0205396:	9e3707b7          	lui	a5,0x9e370
ffffffffc020539a:	2785                	addiw	a5,a5,1
ffffffffc020539c:	02a7853b          	mulw	a0,a5,a0
    return (hash >> (32 - bits));
ffffffffc02053a0:	02000793          	li	a5,32
ffffffffc02053a4:	9f8d                	subw	a5,a5,a1
}
ffffffffc02053a6:	00f5553b          	srlw	a0,a0,a5
ffffffffc02053aa:	8082                	ret

ffffffffc02053ac <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc02053ac:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02053b0:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc02053b2:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02053b6:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc02053b8:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02053bc:	f022                	sd	s0,32(sp)
ffffffffc02053be:	ec26                	sd	s1,24(sp)
ffffffffc02053c0:	e84a                	sd	s2,16(sp)
ffffffffc02053c2:	f406                	sd	ra,40(sp)
ffffffffc02053c4:	e44e                	sd	s3,8(sp)
ffffffffc02053c6:	84aa                	mv	s1,a0
ffffffffc02053c8:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc02053ca:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc02053ce:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc02053d0:	03067e63          	bgeu	a2,a6,ffffffffc020540c <printnum+0x60>
ffffffffc02053d4:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc02053d6:	00805763          	blez	s0,ffffffffc02053e4 <printnum+0x38>
ffffffffc02053da:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc02053dc:	85ca                	mv	a1,s2
ffffffffc02053de:	854e                	mv	a0,s3
ffffffffc02053e0:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc02053e2:	fc65                	bnez	s0,ffffffffc02053da <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02053e4:	1a02                	slli	s4,s4,0x20
ffffffffc02053e6:	00002797          	auipc	a5,0x2
ffffffffc02053ea:	2ea78793          	addi	a5,a5,746 # ffffffffc02076d0 <syscalls+0x100>
ffffffffc02053ee:	020a5a13          	srli	s4,s4,0x20
ffffffffc02053f2:	9a3e                	add	s4,s4,a5
    // Crashes if num >= base. No idea what going on here
    // Here is a quick fix
    // update: Stack grows downward and destory the SBI
    // sbi_console_putchar("0123456789abcdef"[mod]);
    // (*(int *)putdat)++;
}
ffffffffc02053f4:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02053f6:	000a4503          	lbu	a0,0(s4)
}
ffffffffc02053fa:	70a2                	ld	ra,40(sp)
ffffffffc02053fc:	69a2                	ld	s3,8(sp)
ffffffffc02053fe:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0205400:	85ca                	mv	a1,s2
ffffffffc0205402:	87a6                	mv	a5,s1
}
ffffffffc0205404:	6942                	ld	s2,16(sp)
ffffffffc0205406:	64e2                	ld	s1,24(sp)
ffffffffc0205408:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020540a:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc020540c:	03065633          	divu	a2,a2,a6
ffffffffc0205410:	8722                	mv	a4,s0
ffffffffc0205412:	f9bff0ef          	jal	ra,ffffffffc02053ac <printnum>
ffffffffc0205416:	b7f9                	j	ffffffffc02053e4 <printnum+0x38>

ffffffffc0205418 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0205418:	7119                	addi	sp,sp,-128
ffffffffc020541a:	f4a6                	sd	s1,104(sp)
ffffffffc020541c:	f0ca                	sd	s2,96(sp)
ffffffffc020541e:	ecce                	sd	s3,88(sp)
ffffffffc0205420:	e8d2                	sd	s4,80(sp)
ffffffffc0205422:	e4d6                	sd	s5,72(sp)
ffffffffc0205424:	e0da                	sd	s6,64(sp)
ffffffffc0205426:	fc5e                	sd	s7,56(sp)
ffffffffc0205428:	f06a                	sd	s10,32(sp)
ffffffffc020542a:	fc86                	sd	ra,120(sp)
ffffffffc020542c:	f8a2                	sd	s0,112(sp)
ffffffffc020542e:	f862                	sd	s8,48(sp)
ffffffffc0205430:	f466                	sd	s9,40(sp)
ffffffffc0205432:	ec6e                	sd	s11,24(sp)
ffffffffc0205434:	892a                	mv	s2,a0
ffffffffc0205436:	84ae                	mv	s1,a1
ffffffffc0205438:	8d32                	mv	s10,a2
ffffffffc020543a:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc020543c:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc0205440:	5b7d                	li	s6,-1
ffffffffc0205442:	00002a97          	auipc	s5,0x2
ffffffffc0205446:	2baa8a93          	addi	s5,s5,698 # ffffffffc02076fc <syscalls+0x12c>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc020544a:	00002b97          	auipc	s7,0x2
ffffffffc020544e:	4ceb8b93          	addi	s7,s7,1230 # ffffffffc0207918 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0205452:	000d4503          	lbu	a0,0(s10)
ffffffffc0205456:	001d0413          	addi	s0,s10,1
ffffffffc020545a:	01350a63          	beq	a0,s3,ffffffffc020546e <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc020545e:	c121                	beqz	a0,ffffffffc020549e <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc0205460:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0205462:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc0205464:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0205466:	fff44503          	lbu	a0,-1(s0)
ffffffffc020546a:	ff351ae3          	bne	a0,s3,ffffffffc020545e <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020546e:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc0205472:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc0205476:	4c81                	li	s9,0
ffffffffc0205478:	4881                	li	a7,0
        width = precision = -1;
ffffffffc020547a:	5c7d                	li	s8,-1
ffffffffc020547c:	5dfd                	li	s11,-1
ffffffffc020547e:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc0205482:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205484:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0205488:	0ff5f593          	zext.b	a1,a1
ffffffffc020548c:	00140d13          	addi	s10,s0,1
ffffffffc0205490:	04b56263          	bltu	a0,a1,ffffffffc02054d4 <vprintfmt+0xbc>
ffffffffc0205494:	058a                	slli	a1,a1,0x2
ffffffffc0205496:	95d6                	add	a1,a1,s5
ffffffffc0205498:	4194                	lw	a3,0(a1)
ffffffffc020549a:	96d6                	add	a3,a3,s5
ffffffffc020549c:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc020549e:	70e6                	ld	ra,120(sp)
ffffffffc02054a0:	7446                	ld	s0,112(sp)
ffffffffc02054a2:	74a6                	ld	s1,104(sp)
ffffffffc02054a4:	7906                	ld	s2,96(sp)
ffffffffc02054a6:	69e6                	ld	s3,88(sp)
ffffffffc02054a8:	6a46                	ld	s4,80(sp)
ffffffffc02054aa:	6aa6                	ld	s5,72(sp)
ffffffffc02054ac:	6b06                	ld	s6,64(sp)
ffffffffc02054ae:	7be2                	ld	s7,56(sp)
ffffffffc02054b0:	7c42                	ld	s8,48(sp)
ffffffffc02054b2:	7ca2                	ld	s9,40(sp)
ffffffffc02054b4:	7d02                	ld	s10,32(sp)
ffffffffc02054b6:	6de2                	ld	s11,24(sp)
ffffffffc02054b8:	6109                	addi	sp,sp,128
ffffffffc02054ba:	8082                	ret
            padc = '0';
ffffffffc02054bc:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc02054be:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02054c2:	846a                	mv	s0,s10
ffffffffc02054c4:	00140d13          	addi	s10,s0,1
ffffffffc02054c8:	fdd6059b          	addiw	a1,a2,-35
ffffffffc02054cc:	0ff5f593          	zext.b	a1,a1
ffffffffc02054d0:	fcb572e3          	bgeu	a0,a1,ffffffffc0205494 <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc02054d4:	85a6                	mv	a1,s1
ffffffffc02054d6:	02500513          	li	a0,37
ffffffffc02054da:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc02054dc:	fff44783          	lbu	a5,-1(s0)
ffffffffc02054e0:	8d22                	mv	s10,s0
ffffffffc02054e2:	f73788e3          	beq	a5,s3,ffffffffc0205452 <vprintfmt+0x3a>
ffffffffc02054e6:	ffed4783          	lbu	a5,-2(s10)
ffffffffc02054ea:	1d7d                	addi	s10,s10,-1
ffffffffc02054ec:	ff379de3          	bne	a5,s3,ffffffffc02054e6 <vprintfmt+0xce>
ffffffffc02054f0:	b78d                	j	ffffffffc0205452 <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc02054f2:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc02054f6:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02054fa:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc02054fc:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc0205500:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0205504:	02d86463          	bltu	a6,a3,ffffffffc020552c <vprintfmt+0x114>
                ch = *fmt;
ffffffffc0205508:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc020550c:	002c169b          	slliw	a3,s8,0x2
ffffffffc0205510:	0186873b          	addw	a4,a3,s8
ffffffffc0205514:	0017171b          	slliw	a4,a4,0x1
ffffffffc0205518:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc020551a:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc020551e:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0205520:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc0205524:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0205528:	fed870e3          	bgeu	a6,a3,ffffffffc0205508 <vprintfmt+0xf0>
            if (width < 0)
ffffffffc020552c:	f40ddce3          	bgez	s11,ffffffffc0205484 <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc0205530:	8de2                	mv	s11,s8
ffffffffc0205532:	5c7d                	li	s8,-1
ffffffffc0205534:	bf81                	j	ffffffffc0205484 <vprintfmt+0x6c>
            if (width < 0)
ffffffffc0205536:	fffdc693          	not	a3,s11
ffffffffc020553a:	96fd                	srai	a3,a3,0x3f
ffffffffc020553c:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205540:	00144603          	lbu	a2,1(s0)
ffffffffc0205544:	2d81                	sext.w	s11,s11
ffffffffc0205546:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0205548:	bf35                	j	ffffffffc0205484 <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc020554a:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020554e:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc0205552:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205554:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc0205556:	bfd9                	j	ffffffffc020552c <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc0205558:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc020555a:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc020555e:	01174463          	blt	a4,a7,ffffffffc0205566 <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc0205562:	1a088e63          	beqz	a7,ffffffffc020571e <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc0205566:	000a3603          	ld	a2,0(s4)
ffffffffc020556a:	46c1                	li	a3,16
ffffffffc020556c:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc020556e:	2781                	sext.w	a5,a5
ffffffffc0205570:	876e                	mv	a4,s11
ffffffffc0205572:	85a6                	mv	a1,s1
ffffffffc0205574:	854a                	mv	a0,s2
ffffffffc0205576:	e37ff0ef          	jal	ra,ffffffffc02053ac <printnum>
            break;
ffffffffc020557a:	bde1                	j	ffffffffc0205452 <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc020557c:	000a2503          	lw	a0,0(s4)
ffffffffc0205580:	85a6                	mv	a1,s1
ffffffffc0205582:	0a21                	addi	s4,s4,8
ffffffffc0205584:	9902                	jalr	s2
            break;
ffffffffc0205586:	b5f1                	j	ffffffffc0205452 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0205588:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc020558a:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc020558e:	01174463          	blt	a4,a7,ffffffffc0205596 <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc0205592:	18088163          	beqz	a7,ffffffffc0205714 <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc0205596:	000a3603          	ld	a2,0(s4)
ffffffffc020559a:	46a9                	li	a3,10
ffffffffc020559c:	8a2e                	mv	s4,a1
ffffffffc020559e:	bfc1                	j	ffffffffc020556e <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02055a0:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc02055a4:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02055a6:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02055a8:	bdf1                	j	ffffffffc0205484 <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc02055aa:	85a6                	mv	a1,s1
ffffffffc02055ac:	02500513          	li	a0,37
ffffffffc02055b0:	9902                	jalr	s2
            break;
ffffffffc02055b2:	b545                	j	ffffffffc0205452 <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02055b4:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc02055b8:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02055ba:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02055bc:	b5e1                	j	ffffffffc0205484 <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc02055be:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02055c0:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc02055c4:	01174463          	blt	a4,a7,ffffffffc02055cc <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc02055c8:	14088163          	beqz	a7,ffffffffc020570a <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc02055cc:	000a3603          	ld	a2,0(s4)
ffffffffc02055d0:	46a1                	li	a3,8
ffffffffc02055d2:	8a2e                	mv	s4,a1
ffffffffc02055d4:	bf69                	j	ffffffffc020556e <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc02055d6:	03000513          	li	a0,48
ffffffffc02055da:	85a6                	mv	a1,s1
ffffffffc02055dc:	e03e                	sd	a5,0(sp)
ffffffffc02055de:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc02055e0:	85a6                	mv	a1,s1
ffffffffc02055e2:	07800513          	li	a0,120
ffffffffc02055e6:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc02055e8:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc02055ea:	6782                	ld	a5,0(sp)
ffffffffc02055ec:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc02055ee:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc02055f2:	bfb5                	j	ffffffffc020556e <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc02055f4:	000a3403          	ld	s0,0(s4)
ffffffffc02055f8:	008a0713          	addi	a4,s4,8
ffffffffc02055fc:	e03a                	sd	a4,0(sp)
ffffffffc02055fe:	14040263          	beqz	s0,ffffffffc0205742 <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc0205602:	0fb05763          	blez	s11,ffffffffc02056f0 <vprintfmt+0x2d8>
ffffffffc0205606:	02d00693          	li	a3,45
ffffffffc020560a:	0cd79163          	bne	a5,a3,ffffffffc02056cc <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020560e:	00044783          	lbu	a5,0(s0)
ffffffffc0205612:	0007851b          	sext.w	a0,a5
ffffffffc0205616:	cf85                	beqz	a5,ffffffffc020564e <vprintfmt+0x236>
ffffffffc0205618:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc020561c:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205620:	000c4563          	bltz	s8,ffffffffc020562a <vprintfmt+0x212>
ffffffffc0205624:	3c7d                	addiw	s8,s8,-1
ffffffffc0205626:	036c0263          	beq	s8,s6,ffffffffc020564a <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc020562a:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc020562c:	0e0c8e63          	beqz	s9,ffffffffc0205728 <vprintfmt+0x310>
ffffffffc0205630:	3781                	addiw	a5,a5,-32
ffffffffc0205632:	0ef47b63          	bgeu	s0,a5,ffffffffc0205728 <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc0205636:	03f00513          	li	a0,63
ffffffffc020563a:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020563c:	000a4783          	lbu	a5,0(s4)
ffffffffc0205640:	3dfd                	addiw	s11,s11,-1
ffffffffc0205642:	0a05                	addi	s4,s4,1
ffffffffc0205644:	0007851b          	sext.w	a0,a5
ffffffffc0205648:	ffe1                	bnez	a5,ffffffffc0205620 <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc020564a:	01b05963          	blez	s11,ffffffffc020565c <vprintfmt+0x244>
ffffffffc020564e:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0205650:	85a6                	mv	a1,s1
ffffffffc0205652:	02000513          	li	a0,32
ffffffffc0205656:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0205658:	fe0d9be3          	bnez	s11,ffffffffc020564e <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc020565c:	6a02                	ld	s4,0(sp)
ffffffffc020565e:	bbd5                	j	ffffffffc0205452 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0205660:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0205662:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc0205666:	01174463          	blt	a4,a7,ffffffffc020566e <vprintfmt+0x256>
    else if (lflag) {
ffffffffc020566a:	08088d63          	beqz	a7,ffffffffc0205704 <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc020566e:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0205672:	0a044d63          	bltz	s0,ffffffffc020572c <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc0205676:	8622                	mv	a2,s0
ffffffffc0205678:	8a66                	mv	s4,s9
ffffffffc020567a:	46a9                	li	a3,10
ffffffffc020567c:	bdcd                	j	ffffffffc020556e <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc020567e:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0205682:	4761                	li	a4,24
            err = va_arg(ap, int);
ffffffffc0205684:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc0205686:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc020568a:	8fb5                	xor	a5,a5,a3
ffffffffc020568c:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0205690:	02d74163          	blt	a4,a3,ffffffffc02056b2 <vprintfmt+0x29a>
ffffffffc0205694:	00369793          	slli	a5,a3,0x3
ffffffffc0205698:	97de                	add	a5,a5,s7
ffffffffc020569a:	639c                	ld	a5,0(a5)
ffffffffc020569c:	cb99                	beqz	a5,ffffffffc02056b2 <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc020569e:	86be                	mv	a3,a5
ffffffffc02056a0:	00000617          	auipc	a2,0x0
ffffffffc02056a4:	1f060613          	addi	a2,a2,496 # ffffffffc0205890 <etext+0x2a>
ffffffffc02056a8:	85a6                	mv	a1,s1
ffffffffc02056aa:	854a                	mv	a0,s2
ffffffffc02056ac:	0ce000ef          	jal	ra,ffffffffc020577a <printfmt>
ffffffffc02056b0:	b34d                	j	ffffffffc0205452 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc02056b2:	00002617          	auipc	a2,0x2
ffffffffc02056b6:	03e60613          	addi	a2,a2,62 # ffffffffc02076f0 <syscalls+0x120>
ffffffffc02056ba:	85a6                	mv	a1,s1
ffffffffc02056bc:	854a                	mv	a0,s2
ffffffffc02056be:	0bc000ef          	jal	ra,ffffffffc020577a <printfmt>
ffffffffc02056c2:	bb41                	j	ffffffffc0205452 <vprintfmt+0x3a>
                p = "(null)";
ffffffffc02056c4:	00002417          	auipc	s0,0x2
ffffffffc02056c8:	02440413          	addi	s0,s0,36 # ffffffffc02076e8 <syscalls+0x118>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02056cc:	85e2                	mv	a1,s8
ffffffffc02056ce:	8522                	mv	a0,s0
ffffffffc02056d0:	e43e                	sd	a5,8(sp)
ffffffffc02056d2:	0e2000ef          	jal	ra,ffffffffc02057b4 <strnlen>
ffffffffc02056d6:	40ad8dbb          	subw	s11,s11,a0
ffffffffc02056da:	01b05b63          	blez	s11,ffffffffc02056f0 <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc02056de:	67a2                	ld	a5,8(sp)
ffffffffc02056e0:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02056e4:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc02056e6:	85a6                	mv	a1,s1
ffffffffc02056e8:	8552                	mv	a0,s4
ffffffffc02056ea:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02056ec:	fe0d9ce3          	bnez	s11,ffffffffc02056e4 <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02056f0:	00044783          	lbu	a5,0(s0)
ffffffffc02056f4:	00140a13          	addi	s4,s0,1
ffffffffc02056f8:	0007851b          	sext.w	a0,a5
ffffffffc02056fc:	d3a5                	beqz	a5,ffffffffc020565c <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02056fe:	05e00413          	li	s0,94
ffffffffc0205702:	bf39                	j	ffffffffc0205620 <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc0205704:	000a2403          	lw	s0,0(s4)
ffffffffc0205708:	b7ad                	j	ffffffffc0205672 <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc020570a:	000a6603          	lwu	a2,0(s4)
ffffffffc020570e:	46a1                	li	a3,8
ffffffffc0205710:	8a2e                	mv	s4,a1
ffffffffc0205712:	bdb1                	j	ffffffffc020556e <vprintfmt+0x156>
ffffffffc0205714:	000a6603          	lwu	a2,0(s4)
ffffffffc0205718:	46a9                	li	a3,10
ffffffffc020571a:	8a2e                	mv	s4,a1
ffffffffc020571c:	bd89                	j	ffffffffc020556e <vprintfmt+0x156>
ffffffffc020571e:	000a6603          	lwu	a2,0(s4)
ffffffffc0205722:	46c1                	li	a3,16
ffffffffc0205724:	8a2e                	mv	s4,a1
ffffffffc0205726:	b5a1                	j	ffffffffc020556e <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc0205728:	9902                	jalr	s2
ffffffffc020572a:	bf09                	j	ffffffffc020563c <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc020572c:	85a6                	mv	a1,s1
ffffffffc020572e:	02d00513          	li	a0,45
ffffffffc0205732:	e03e                	sd	a5,0(sp)
ffffffffc0205734:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0205736:	6782                	ld	a5,0(sp)
ffffffffc0205738:	8a66                	mv	s4,s9
ffffffffc020573a:	40800633          	neg	a2,s0
ffffffffc020573e:	46a9                	li	a3,10
ffffffffc0205740:	b53d                	j	ffffffffc020556e <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc0205742:	03b05163          	blez	s11,ffffffffc0205764 <vprintfmt+0x34c>
ffffffffc0205746:	02d00693          	li	a3,45
ffffffffc020574a:	f6d79de3          	bne	a5,a3,ffffffffc02056c4 <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc020574e:	00002417          	auipc	s0,0x2
ffffffffc0205752:	f9a40413          	addi	s0,s0,-102 # ffffffffc02076e8 <syscalls+0x118>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205756:	02800793          	li	a5,40
ffffffffc020575a:	02800513          	li	a0,40
ffffffffc020575e:	00140a13          	addi	s4,s0,1
ffffffffc0205762:	bd6d                	j	ffffffffc020561c <vprintfmt+0x204>
ffffffffc0205764:	00002a17          	auipc	s4,0x2
ffffffffc0205768:	f85a0a13          	addi	s4,s4,-123 # ffffffffc02076e9 <syscalls+0x119>
ffffffffc020576c:	02800513          	li	a0,40
ffffffffc0205770:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0205774:	05e00413          	li	s0,94
ffffffffc0205778:	b565                	j	ffffffffc0205620 <vprintfmt+0x208>

ffffffffc020577a <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc020577a:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc020577c:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0205780:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0205782:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0205784:	ec06                	sd	ra,24(sp)
ffffffffc0205786:	f83a                	sd	a4,48(sp)
ffffffffc0205788:	fc3e                	sd	a5,56(sp)
ffffffffc020578a:	e0c2                	sd	a6,64(sp)
ffffffffc020578c:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc020578e:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0205790:	c89ff0ef          	jal	ra,ffffffffc0205418 <vprintfmt>
}
ffffffffc0205794:	60e2                	ld	ra,24(sp)
ffffffffc0205796:	6161                	addi	sp,sp,80
ffffffffc0205798:	8082                	ret

ffffffffc020579a <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc020579a:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc020579e:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc02057a0:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc02057a2:	cb81                	beqz	a5,ffffffffc02057b2 <strlen+0x18>
        cnt ++;
ffffffffc02057a4:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc02057a6:	00a707b3          	add	a5,a4,a0
ffffffffc02057aa:	0007c783          	lbu	a5,0(a5)
ffffffffc02057ae:	fbfd                	bnez	a5,ffffffffc02057a4 <strlen+0xa>
ffffffffc02057b0:	8082                	ret
    }
    return cnt;
}
ffffffffc02057b2:	8082                	ret

ffffffffc02057b4 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc02057b4:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc02057b6:	e589                	bnez	a1,ffffffffc02057c0 <strnlen+0xc>
ffffffffc02057b8:	a811                	j	ffffffffc02057cc <strnlen+0x18>
        cnt ++;
ffffffffc02057ba:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc02057bc:	00f58863          	beq	a1,a5,ffffffffc02057cc <strnlen+0x18>
ffffffffc02057c0:	00f50733          	add	a4,a0,a5
ffffffffc02057c4:	00074703          	lbu	a4,0(a4)
ffffffffc02057c8:	fb6d                	bnez	a4,ffffffffc02057ba <strnlen+0x6>
ffffffffc02057ca:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc02057cc:	852e                	mv	a0,a1
ffffffffc02057ce:	8082                	ret

ffffffffc02057d0 <strcpy>:
char *
strcpy(char *dst, const char *src) {
#ifdef __HAVE_ARCH_STRCPY
    return __strcpy(dst, src);
#else
    char *p = dst;
ffffffffc02057d0:	87aa                	mv	a5,a0
    while ((*p ++ = *src ++) != '\0')
ffffffffc02057d2:	0005c703          	lbu	a4,0(a1)
ffffffffc02057d6:	0785                	addi	a5,a5,1
ffffffffc02057d8:	0585                	addi	a1,a1,1
ffffffffc02057da:	fee78fa3          	sb	a4,-1(a5)
ffffffffc02057de:	fb75                	bnez	a4,ffffffffc02057d2 <strcpy+0x2>
        /* nothing */;
    return dst;
#endif /* __HAVE_ARCH_STRCPY */
}
ffffffffc02057e0:	8082                	ret

ffffffffc02057e2 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02057e2:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02057e6:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02057ea:	cb89                	beqz	a5,ffffffffc02057fc <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc02057ec:	0505                	addi	a0,a0,1
ffffffffc02057ee:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02057f0:	fee789e3          	beq	a5,a4,ffffffffc02057e2 <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02057f4:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc02057f8:	9d19                	subw	a0,a0,a4
ffffffffc02057fa:	8082                	ret
ffffffffc02057fc:	4501                	li	a0,0
ffffffffc02057fe:	bfed                	j	ffffffffc02057f8 <strcmp+0x16>

ffffffffc0205800 <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0205800:	c20d                	beqz	a2,ffffffffc0205822 <strncmp+0x22>
ffffffffc0205802:	962e                	add	a2,a2,a1
ffffffffc0205804:	a031                	j	ffffffffc0205810 <strncmp+0x10>
        n --, s1 ++, s2 ++;
ffffffffc0205806:	0505                	addi	a0,a0,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0205808:	00e79a63          	bne	a5,a4,ffffffffc020581c <strncmp+0x1c>
ffffffffc020580c:	00b60b63          	beq	a2,a1,ffffffffc0205822 <strncmp+0x22>
ffffffffc0205810:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc0205814:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0205816:	fff5c703          	lbu	a4,-1(a1)
ffffffffc020581a:	f7f5                	bnez	a5,ffffffffc0205806 <strncmp+0x6>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc020581c:	40e7853b          	subw	a0,a5,a4
}
ffffffffc0205820:	8082                	ret
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0205822:	4501                	li	a0,0
ffffffffc0205824:	8082                	ret

ffffffffc0205826 <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc0205826:	00054783          	lbu	a5,0(a0)
ffffffffc020582a:	c799                	beqz	a5,ffffffffc0205838 <strchr+0x12>
        if (*s == c) {
ffffffffc020582c:	00f58763          	beq	a1,a5,ffffffffc020583a <strchr+0x14>
    while (*s != '\0') {
ffffffffc0205830:	00154783          	lbu	a5,1(a0)
            return (char *)s;
        }
        s ++;
ffffffffc0205834:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc0205836:	fbfd                	bnez	a5,ffffffffc020582c <strchr+0x6>
    }
    return NULL;
ffffffffc0205838:	4501                	li	a0,0
}
ffffffffc020583a:	8082                	ret

ffffffffc020583c <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc020583c:	ca01                	beqz	a2,ffffffffc020584c <memset+0x10>
ffffffffc020583e:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0205840:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0205842:	0785                	addi	a5,a5,1
ffffffffc0205844:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0205848:	fec79de3          	bne	a5,a2,ffffffffc0205842 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc020584c:	8082                	ret

ffffffffc020584e <memcpy>:
#ifdef __HAVE_ARCH_MEMCPY
    return __memcpy(dst, src, n);
#else
    const char *s = src;
    char *d = dst;
    while (n -- > 0) {
ffffffffc020584e:	ca19                	beqz	a2,ffffffffc0205864 <memcpy+0x16>
ffffffffc0205850:	962e                	add	a2,a2,a1
    char *d = dst;
ffffffffc0205852:	87aa                	mv	a5,a0
        *d ++ = *s ++;
ffffffffc0205854:	0005c703          	lbu	a4,0(a1)
ffffffffc0205858:	0585                	addi	a1,a1,1
ffffffffc020585a:	0785                	addi	a5,a5,1
ffffffffc020585c:	fee78fa3          	sb	a4,-1(a5)
    while (n -- > 0) {
ffffffffc0205860:	fec59ae3          	bne	a1,a2,ffffffffc0205854 <memcpy+0x6>
    }
    return dst;
#endif /* __HAVE_ARCH_MEMCPY */
}
ffffffffc0205864:	8082                	ret
