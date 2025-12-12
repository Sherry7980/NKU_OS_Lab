
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
ffffffffc020004a:	000a6517          	auipc	a0,0xa6
ffffffffc020004e:	42650513          	addi	a0,a0,1062 # ffffffffc02a6470 <buf>
ffffffffc0200052:	000ab617          	auipc	a2,0xab
ffffffffc0200056:	8c260613          	addi	a2,a2,-1854 # ffffffffc02aa914 <end>
{
ffffffffc020005a:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc020005c:	8e09                	sub	a2,a2,a0
ffffffffc020005e:	4581                	li	a1,0
{
ffffffffc0200060:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc0200062:	71e050ef          	jal	ra,ffffffffc0205780 <memset>
    dtb_init();
ffffffffc0200066:	598000ef          	jal	ra,ffffffffc02005fe <dtb_init>
    cons_init(); // init the console
ffffffffc020006a:	522000ef          	jal	ra,ffffffffc020058c <cons_init>

    const char *message = "(THU.CST) os is loading ...";
    cprintf("%s\n\n", message);
ffffffffc020006e:	00005597          	auipc	a1,0x5
ffffffffc0200072:	74258593          	addi	a1,a1,1858 # ffffffffc02057b0 <etext+0x6>
ffffffffc0200076:	00005517          	auipc	a0,0x5
ffffffffc020007a:	75a50513          	addi	a0,a0,1882 # ffffffffc02057d0 <etext+0x26>
ffffffffc020007e:	116000ef          	jal	ra,ffffffffc0200194 <cprintf>

    print_kerninfo();
ffffffffc0200082:	19a000ef          	jal	ra,ffffffffc020021c <print_kerninfo>

    // grade_backtrace();

    pmm_init(); // init physical memory management
ffffffffc0200086:	758020ef          	jal	ra,ffffffffc02027de <pmm_init>

    pic_init(); // init interrupt controller
ffffffffc020008a:	131000ef          	jal	ra,ffffffffc02009ba <pic_init>
    idt_init(); // init interrupt descriptor table
ffffffffc020008e:	12f000ef          	jal	ra,ffffffffc02009bc <idt_init>

    vmm_init();  // init virtual memory management
ffffffffc0200092:	247030ef          	jal	ra,ffffffffc0203ad8 <vmm_init>
    proc_init(); // init process table
ffffffffc0200096:	63d040ef          	jal	ra,ffffffffc0204ed2 <proc_init>

    clock_init();  // init clock interrupt
ffffffffc020009a:	4a0000ef          	jal	ra,ffffffffc020053a <clock_init>
    intr_enable(); // enable irq interrupt
ffffffffc020009e:	111000ef          	jal	ra,ffffffffc02009ae <intr_enable>

    cpu_idle(); // run idle process
ffffffffc02000a2:	7c9040ef          	jal	ra,ffffffffc020506a <cpu_idle>

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
ffffffffc02000c0:	71c50513          	addi	a0,a0,1820 # ffffffffc02057d8 <etext+0x2e>
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
ffffffffc02000d2:	000a6b97          	auipc	s7,0xa6
ffffffffc02000d6:	39eb8b93          	addi	s7,s7,926 # ffffffffc02a6470 <buf>
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
ffffffffc020012e:	000a6517          	auipc	a0,0xa6
ffffffffc0200132:	34250513          	addi	a0,a0,834 # ffffffffc02a6470 <buf>
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
ffffffffc0200188:	1d4050ef          	jal	ra,ffffffffc020535c <vprintfmt>
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
ffffffffc02001be:	19e050ef          	jal	ra,ffffffffc020535c <vprintfmt>
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
ffffffffc0200222:	5c250513          	addi	a0,a0,1474 # ffffffffc02057e0 <etext+0x36>
{
ffffffffc0200226:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200228:	f6dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  entry  0x%08x (virtual)\n", kern_init);
ffffffffc020022c:	00000597          	auipc	a1,0x0
ffffffffc0200230:	e1e58593          	addi	a1,a1,-482 # ffffffffc020004a <kern_init>
ffffffffc0200234:	00005517          	auipc	a0,0x5
ffffffffc0200238:	5cc50513          	addi	a0,a0,1484 # ffffffffc0205800 <etext+0x56>
ffffffffc020023c:	f59ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  etext  0x%08x (virtual)\n", etext);
ffffffffc0200240:	00005597          	auipc	a1,0x5
ffffffffc0200244:	56a58593          	addi	a1,a1,1386 # ffffffffc02057aa <etext>
ffffffffc0200248:	00005517          	auipc	a0,0x5
ffffffffc020024c:	5d850513          	addi	a0,a0,1496 # ffffffffc0205820 <etext+0x76>
ffffffffc0200250:	f45ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  edata  0x%08x (virtual)\n", edata);
ffffffffc0200254:	000a6597          	auipc	a1,0xa6
ffffffffc0200258:	21c58593          	addi	a1,a1,540 # ffffffffc02a6470 <buf>
ffffffffc020025c:	00005517          	auipc	a0,0x5
ffffffffc0200260:	5e450513          	addi	a0,a0,1508 # ffffffffc0205840 <etext+0x96>
ffffffffc0200264:	f31ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  end    0x%08x (virtual)\n", end);
ffffffffc0200268:	000aa597          	auipc	a1,0xaa
ffffffffc020026c:	6ac58593          	addi	a1,a1,1708 # ffffffffc02aa914 <end>
ffffffffc0200270:	00005517          	auipc	a0,0x5
ffffffffc0200274:	5f050513          	addi	a0,a0,1520 # ffffffffc0205860 <etext+0xb6>
ffffffffc0200278:	f1dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc020027c:	000ab597          	auipc	a1,0xab
ffffffffc0200280:	a9758593          	addi	a1,a1,-1385 # ffffffffc02aad13 <end+0x3ff>
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
ffffffffc02002a2:	5e250513          	addi	a0,a0,1506 # ffffffffc0205880 <etext+0xd6>
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
ffffffffc02002b0:	60460613          	addi	a2,a2,1540 # ffffffffc02058b0 <etext+0x106>
ffffffffc02002b4:	04f00593          	li	a1,79
ffffffffc02002b8:	00005517          	auipc	a0,0x5
ffffffffc02002bc:	61050513          	addi	a0,a0,1552 # ffffffffc02058c8 <etext+0x11e>
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
ffffffffc02002cc:	61860613          	addi	a2,a2,1560 # ffffffffc02058e0 <etext+0x136>
ffffffffc02002d0:	00005597          	auipc	a1,0x5
ffffffffc02002d4:	63058593          	addi	a1,a1,1584 # ffffffffc0205900 <etext+0x156>
ffffffffc02002d8:	00005517          	auipc	a0,0x5
ffffffffc02002dc:	63050513          	addi	a0,a0,1584 # ffffffffc0205908 <etext+0x15e>
{
ffffffffc02002e0:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02002e2:	eb3ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc02002e6:	00005617          	auipc	a2,0x5
ffffffffc02002ea:	63260613          	addi	a2,a2,1586 # ffffffffc0205918 <etext+0x16e>
ffffffffc02002ee:	00005597          	auipc	a1,0x5
ffffffffc02002f2:	65258593          	addi	a1,a1,1618 # ffffffffc0205940 <etext+0x196>
ffffffffc02002f6:	00005517          	auipc	a0,0x5
ffffffffc02002fa:	61250513          	addi	a0,a0,1554 # ffffffffc0205908 <etext+0x15e>
ffffffffc02002fe:	e97ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc0200302:	00005617          	auipc	a2,0x5
ffffffffc0200306:	64e60613          	addi	a2,a2,1614 # ffffffffc0205950 <etext+0x1a6>
ffffffffc020030a:	00005597          	auipc	a1,0x5
ffffffffc020030e:	66658593          	addi	a1,a1,1638 # ffffffffc0205970 <etext+0x1c6>
ffffffffc0200312:	00005517          	auipc	a0,0x5
ffffffffc0200316:	5f650513          	addi	a0,a0,1526 # ffffffffc0205908 <etext+0x15e>
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
ffffffffc0200350:	63450513          	addi	a0,a0,1588 # ffffffffc0205980 <etext+0x1d6>
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
ffffffffc0200372:	63a50513          	addi	a0,a0,1594 # ffffffffc02059a8 <etext+0x1fe>
ffffffffc0200376:	e1fff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    if (tf != NULL)
ffffffffc020037a:	000b8563          	beqz	s7,ffffffffc0200384 <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc020037e:	855e                	mv	a0,s7
ffffffffc0200380:	025000ef          	jal	ra,ffffffffc0200ba4 <print_trapframe>
ffffffffc0200384:	00005c17          	auipc	s8,0x5
ffffffffc0200388:	694c0c13          	addi	s8,s8,1684 # ffffffffc0205a18 <commands>
        if ((buf = readline("K> ")) != NULL)
ffffffffc020038c:	00005917          	auipc	s2,0x5
ffffffffc0200390:	64490913          	addi	s2,s2,1604 # ffffffffc02059d0 <etext+0x226>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc0200394:	00005497          	auipc	s1,0x5
ffffffffc0200398:	64448493          	addi	s1,s1,1604 # ffffffffc02059d8 <etext+0x22e>
        if (argc == MAXARGS - 1)
ffffffffc020039c:	49bd                	li	s3,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc020039e:	00005b17          	auipc	s6,0x5
ffffffffc02003a2:	642b0b13          	addi	s6,s6,1602 # ffffffffc02059e0 <etext+0x236>
        argv[argc++] = buf;
ffffffffc02003a6:	00005a17          	auipc	s4,0x5
ffffffffc02003aa:	55aa0a13          	addi	s4,s4,1370 # ffffffffc0205900 <etext+0x156>
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
ffffffffc02003cc:	650d0d13          	addi	s10,s10,1616 # ffffffffc0205a18 <commands>
        argv[argc++] = buf;
ffffffffc02003d0:	8552                	mv	a0,s4
    for (i = 0; i < NCOMMANDS; i++)
ffffffffc02003d2:	4401                	li	s0,0
ffffffffc02003d4:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0)
ffffffffc02003d6:	350050ef          	jal	ra,ffffffffc0205726 <strcmp>
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
ffffffffc02003ea:	33c050ef          	jal	ra,ffffffffc0205726 <strcmp>
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
ffffffffc0200428:	342050ef          	jal	ra,ffffffffc020576a <strchr>
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
ffffffffc0200466:	304050ef          	jal	ra,ffffffffc020576a <strchr>
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
ffffffffc0200484:	58050513          	addi	a0,a0,1408 # ffffffffc0205a00 <etext+0x256>
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
ffffffffc020048e:	000aa317          	auipc	t1,0xaa
ffffffffc0200492:	40a30313          	addi	t1,t1,1034 # ffffffffc02aa898 <is_panic>
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
ffffffffc02004c0:	5a450513          	addi	a0,a0,1444 # ffffffffc0205a60 <commands+0x48>
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
ffffffffc02004d6:	6d650513          	addi	a0,a0,1750 # ffffffffc0206ba8 <default_pmm_manager+0x578>
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
ffffffffc020050a:	57a50513          	addi	a0,a0,1402 # ffffffffc0205a80 <commands+0x68>
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
ffffffffc020052a:	68250513          	addi	a0,a0,1666 # ffffffffc0206ba8 <default_pmm_manager+0x578>
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
ffffffffc0200540:	000aa717          	auipc	a4,0xaa
ffffffffc0200544:	36f73423          	sd	a5,872(a4) # ffffffffc02aa8a8 <timebase>
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
ffffffffc0200564:	54050513          	addi	a0,a0,1344 # ffffffffc0205aa0 <commands+0x88>
    ticks = 0;
ffffffffc0200568:	000aa797          	auipc	a5,0xaa
ffffffffc020056c:	3207bc23          	sd	zero,824(a5) # ffffffffc02aa8a0 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc0200570:	b115                	j	ffffffffc0200194 <cprintf>

ffffffffc0200572 <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200572:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200576:	000aa797          	auipc	a5,0xaa
ffffffffc020057a:	3327b783          	ld	a5,818(a5) # ffffffffc02aa8a8 <timebase>
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
ffffffffc0200604:	4c050513          	addi	a0,a0,1216 # ffffffffc0205ac0 <commands+0xa8>
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
ffffffffc0200632:	4a250513          	addi	a0,a0,1186 # ffffffffc0205ad0 <commands+0xb8>
ffffffffc0200636:	b5fff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc020063a:	0000b417          	auipc	s0,0xb
ffffffffc020063e:	9ce40413          	addi	s0,s0,-1586 # ffffffffc020b008 <boot_dtb>
ffffffffc0200642:	600c                	ld	a1,0(s0)
ffffffffc0200644:	00005517          	auipc	a0,0x5
ffffffffc0200648:	49c50513          	addi	a0,a0,1180 # ffffffffc0205ae0 <commands+0xc8>
ffffffffc020064c:	b49ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc0200650:	00043a03          	ld	s4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc0200654:	00005517          	auipc	a0,0x5
ffffffffc0200658:	4a450513          	addi	a0,a0,1188 # ffffffffc0205af8 <commands+0xe0>
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
ffffffffc020069c:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <end+0xfe355d9>
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
ffffffffc0200712:	43a90913          	addi	s2,s2,1082 # ffffffffc0205b48 <commands+0x130>
ffffffffc0200716:	49bd                	li	s3,15
        switch (token) {
ffffffffc0200718:	4d91                	li	s11,4
ffffffffc020071a:	4d05                	li	s10,1
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc020071c:	00005497          	auipc	s1,0x5
ffffffffc0200720:	42448493          	addi	s1,s1,1060 # ffffffffc0205b40 <commands+0x128>
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
ffffffffc0200774:	45050513          	addi	a0,a0,1104 # ffffffffc0205bc0 <commands+0x1a8>
ffffffffc0200778:	a1dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc020077c:	00005517          	auipc	a0,0x5
ffffffffc0200780:	47c50513          	addi	a0,a0,1148 # ffffffffc0205bf8 <commands+0x1e0>
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
ffffffffc02007c0:	35c50513          	addi	a0,a0,860 # ffffffffc0205b18 <commands+0x100>
}
ffffffffc02007c4:	6109                	addi	sp,sp,128
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02007c6:	b2f9                	j	ffffffffc0200194 <cprintf>
                int name_len = strlen(name);
ffffffffc02007c8:	8556                	mv	a0,s5
ffffffffc02007ca:	715040ef          	jal	ra,ffffffffc02056de <strlen>
ffffffffc02007ce:	8a2a                	mv	s4,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02007d0:	4619                	li	a2,6
ffffffffc02007d2:	85a6                	mv	a1,s1
ffffffffc02007d4:	8556                	mv	a0,s5
                int name_len = strlen(name);
ffffffffc02007d6:	2a01                	sext.w	s4,s4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02007d8:	76d040ef          	jal	ra,ffffffffc0205744 <strncmp>
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
ffffffffc020086e:	6b9040ef          	jal	ra,ffffffffc0205726 <strcmp>
ffffffffc0200872:	66a2                	ld	a3,8(sp)
ffffffffc0200874:	f94d                	bnez	a0,ffffffffc0200826 <dtb_init+0x228>
ffffffffc0200876:	fb59f8e3          	bgeu	s3,s5,ffffffffc0200826 <dtb_init+0x228>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc020087a:	00ca3783          	ld	a5,12(s4)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc020087e:	014a3703          	ld	a4,20(s4)
        cprintf("Physical Memory from DTB:\n");
ffffffffc0200882:	00005517          	auipc	a0,0x5
ffffffffc0200886:	2ce50513          	addi	a0,a0,718 # ffffffffc0205b50 <commands+0x138>
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
ffffffffc0200954:	22050513          	addi	a0,a0,544 # ffffffffc0205b70 <commands+0x158>
ffffffffc0200958:	83dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc020095c:	014b5613          	srli	a2,s6,0x14
ffffffffc0200960:	85da                	mv	a1,s6
ffffffffc0200962:	00005517          	auipc	a0,0x5
ffffffffc0200966:	22650513          	addi	a0,a0,550 # ffffffffc0205b88 <commands+0x170>
ffffffffc020096a:	82bff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc020096e:	008b05b3          	add	a1,s6,s0
ffffffffc0200972:	15fd                	addi	a1,a1,-1
ffffffffc0200974:	00005517          	auipc	a0,0x5
ffffffffc0200978:	23450513          	addi	a0,a0,564 # ffffffffc0205ba8 <commands+0x190>
ffffffffc020097c:	819ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("DTB init completed\n");
ffffffffc0200980:	00005517          	auipc	a0,0x5
ffffffffc0200984:	27850513          	addi	a0,a0,632 # ffffffffc0205bf8 <commands+0x1e0>
        memory_base = mem_base;
ffffffffc0200988:	000aa797          	auipc	a5,0xaa
ffffffffc020098c:	f287b423          	sd	s0,-216(a5) # ffffffffc02aa8b0 <memory_base>
        memory_size = mem_size;
ffffffffc0200990:	000aa797          	auipc	a5,0xaa
ffffffffc0200994:	f367b423          	sd	s6,-216(a5) # ffffffffc02aa8b8 <memory_size>
    cprintf("DTB init completed\n");
ffffffffc0200998:	b3f5                	j	ffffffffc0200784 <dtb_init+0x186>

ffffffffc020099a <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc020099a:	000aa517          	auipc	a0,0xaa
ffffffffc020099e:	f1653503          	ld	a0,-234(a0) # ffffffffc02aa8b0 <memory_base>
ffffffffc02009a2:	8082                	ret

ffffffffc02009a4 <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
}
ffffffffc02009a4:	000aa517          	auipc	a0,0xaa
ffffffffc02009a8:	f1453503          	ld	a0,-236(a0) # ffffffffc02aa8b8 <memory_size>
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
ffffffffc02009c4:	54c78793          	addi	a5,a5,1356 # ffffffffc0200f0c <__alltraps>
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
ffffffffc02009e2:	23250513          	addi	a0,a0,562 # ffffffffc0205c10 <commands+0x1f8>
{
ffffffffc02009e6:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc02009e8:	facff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc02009ec:	640c                	ld	a1,8(s0)
ffffffffc02009ee:	00005517          	auipc	a0,0x5
ffffffffc02009f2:	23a50513          	addi	a0,a0,570 # ffffffffc0205c28 <commands+0x210>
ffffffffc02009f6:	f9eff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc02009fa:	680c                	ld	a1,16(s0)
ffffffffc02009fc:	00005517          	auipc	a0,0x5
ffffffffc0200a00:	24450513          	addi	a0,a0,580 # ffffffffc0205c40 <commands+0x228>
ffffffffc0200a04:	f90ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc0200a08:	6c0c                	ld	a1,24(s0)
ffffffffc0200a0a:	00005517          	auipc	a0,0x5
ffffffffc0200a0e:	24e50513          	addi	a0,a0,590 # ffffffffc0205c58 <commands+0x240>
ffffffffc0200a12:	f82ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc0200a16:	700c                	ld	a1,32(s0)
ffffffffc0200a18:	00005517          	auipc	a0,0x5
ffffffffc0200a1c:	25850513          	addi	a0,a0,600 # ffffffffc0205c70 <commands+0x258>
ffffffffc0200a20:	f74ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc0200a24:	740c                	ld	a1,40(s0)
ffffffffc0200a26:	00005517          	auipc	a0,0x5
ffffffffc0200a2a:	26250513          	addi	a0,a0,610 # ffffffffc0205c88 <commands+0x270>
ffffffffc0200a2e:	f66ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc0200a32:	780c                	ld	a1,48(s0)
ffffffffc0200a34:	00005517          	auipc	a0,0x5
ffffffffc0200a38:	26c50513          	addi	a0,a0,620 # ffffffffc0205ca0 <commands+0x288>
ffffffffc0200a3c:	f58ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc0200a40:	7c0c                	ld	a1,56(s0)
ffffffffc0200a42:	00005517          	auipc	a0,0x5
ffffffffc0200a46:	27650513          	addi	a0,a0,630 # ffffffffc0205cb8 <commands+0x2a0>
ffffffffc0200a4a:	f4aff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc0200a4e:	602c                	ld	a1,64(s0)
ffffffffc0200a50:	00005517          	auipc	a0,0x5
ffffffffc0200a54:	28050513          	addi	a0,a0,640 # ffffffffc0205cd0 <commands+0x2b8>
ffffffffc0200a58:	f3cff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc0200a5c:	642c                	ld	a1,72(s0)
ffffffffc0200a5e:	00005517          	auipc	a0,0x5
ffffffffc0200a62:	28a50513          	addi	a0,a0,650 # ffffffffc0205ce8 <commands+0x2d0>
ffffffffc0200a66:	f2eff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc0200a6a:	682c                	ld	a1,80(s0)
ffffffffc0200a6c:	00005517          	auipc	a0,0x5
ffffffffc0200a70:	29450513          	addi	a0,a0,660 # ffffffffc0205d00 <commands+0x2e8>
ffffffffc0200a74:	f20ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc0200a78:	6c2c                	ld	a1,88(s0)
ffffffffc0200a7a:	00005517          	auipc	a0,0x5
ffffffffc0200a7e:	29e50513          	addi	a0,a0,670 # ffffffffc0205d18 <commands+0x300>
ffffffffc0200a82:	f12ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc0200a86:	702c                	ld	a1,96(s0)
ffffffffc0200a88:	00005517          	auipc	a0,0x5
ffffffffc0200a8c:	2a850513          	addi	a0,a0,680 # ffffffffc0205d30 <commands+0x318>
ffffffffc0200a90:	f04ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc0200a94:	742c                	ld	a1,104(s0)
ffffffffc0200a96:	00005517          	auipc	a0,0x5
ffffffffc0200a9a:	2b250513          	addi	a0,a0,690 # ffffffffc0205d48 <commands+0x330>
ffffffffc0200a9e:	ef6ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc0200aa2:	782c                	ld	a1,112(s0)
ffffffffc0200aa4:	00005517          	auipc	a0,0x5
ffffffffc0200aa8:	2bc50513          	addi	a0,a0,700 # ffffffffc0205d60 <commands+0x348>
ffffffffc0200aac:	ee8ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200ab0:	7c2c                	ld	a1,120(s0)
ffffffffc0200ab2:	00005517          	auipc	a0,0x5
ffffffffc0200ab6:	2c650513          	addi	a0,a0,710 # ffffffffc0205d78 <commands+0x360>
ffffffffc0200aba:	edaff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc0200abe:	604c                	ld	a1,128(s0)
ffffffffc0200ac0:	00005517          	auipc	a0,0x5
ffffffffc0200ac4:	2d050513          	addi	a0,a0,720 # ffffffffc0205d90 <commands+0x378>
ffffffffc0200ac8:	eccff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200acc:	644c                	ld	a1,136(s0)
ffffffffc0200ace:	00005517          	auipc	a0,0x5
ffffffffc0200ad2:	2da50513          	addi	a0,a0,730 # ffffffffc0205da8 <commands+0x390>
ffffffffc0200ad6:	ebeff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200ada:	684c                	ld	a1,144(s0)
ffffffffc0200adc:	00005517          	auipc	a0,0x5
ffffffffc0200ae0:	2e450513          	addi	a0,a0,740 # ffffffffc0205dc0 <commands+0x3a8>
ffffffffc0200ae4:	eb0ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc0200ae8:	6c4c                	ld	a1,152(s0)
ffffffffc0200aea:	00005517          	auipc	a0,0x5
ffffffffc0200aee:	2ee50513          	addi	a0,a0,750 # ffffffffc0205dd8 <commands+0x3c0>
ffffffffc0200af2:	ea2ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc0200af6:	704c                	ld	a1,160(s0)
ffffffffc0200af8:	00005517          	auipc	a0,0x5
ffffffffc0200afc:	2f850513          	addi	a0,a0,760 # ffffffffc0205df0 <commands+0x3d8>
ffffffffc0200b00:	e94ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc0200b04:	744c                	ld	a1,168(s0)
ffffffffc0200b06:	00005517          	auipc	a0,0x5
ffffffffc0200b0a:	30250513          	addi	a0,a0,770 # ffffffffc0205e08 <commands+0x3f0>
ffffffffc0200b0e:	e86ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc0200b12:	784c                	ld	a1,176(s0)
ffffffffc0200b14:	00005517          	auipc	a0,0x5
ffffffffc0200b18:	30c50513          	addi	a0,a0,780 # ffffffffc0205e20 <commands+0x408>
ffffffffc0200b1c:	e78ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc0200b20:	7c4c                	ld	a1,184(s0)
ffffffffc0200b22:	00005517          	auipc	a0,0x5
ffffffffc0200b26:	31650513          	addi	a0,a0,790 # ffffffffc0205e38 <commands+0x420>
ffffffffc0200b2a:	e6aff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc0200b2e:	606c                	ld	a1,192(s0)
ffffffffc0200b30:	00005517          	auipc	a0,0x5
ffffffffc0200b34:	32050513          	addi	a0,a0,800 # ffffffffc0205e50 <commands+0x438>
ffffffffc0200b38:	e5cff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc0200b3c:	646c                	ld	a1,200(s0)
ffffffffc0200b3e:	00005517          	auipc	a0,0x5
ffffffffc0200b42:	32a50513          	addi	a0,a0,810 # ffffffffc0205e68 <commands+0x450>
ffffffffc0200b46:	e4eff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc0200b4a:	686c                	ld	a1,208(s0)
ffffffffc0200b4c:	00005517          	auipc	a0,0x5
ffffffffc0200b50:	33450513          	addi	a0,a0,820 # ffffffffc0205e80 <commands+0x468>
ffffffffc0200b54:	e40ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc0200b58:	6c6c                	ld	a1,216(s0)
ffffffffc0200b5a:	00005517          	auipc	a0,0x5
ffffffffc0200b5e:	33e50513          	addi	a0,a0,830 # ffffffffc0205e98 <commands+0x480>
ffffffffc0200b62:	e32ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc0200b66:	706c                	ld	a1,224(s0)
ffffffffc0200b68:	00005517          	auipc	a0,0x5
ffffffffc0200b6c:	34850513          	addi	a0,a0,840 # ffffffffc0205eb0 <commands+0x498>
ffffffffc0200b70:	e24ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc0200b74:	746c                	ld	a1,232(s0)
ffffffffc0200b76:	00005517          	auipc	a0,0x5
ffffffffc0200b7a:	35250513          	addi	a0,a0,850 # ffffffffc0205ec8 <commands+0x4b0>
ffffffffc0200b7e:	e16ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200b82:	786c                	ld	a1,240(s0)
ffffffffc0200b84:	00005517          	auipc	a0,0x5
ffffffffc0200b88:	35c50513          	addi	a0,a0,860 # ffffffffc0205ee0 <commands+0x4c8>
ffffffffc0200b8c:	e08ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200b90:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200b92:	6402                	ld	s0,0(sp)
ffffffffc0200b94:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200b96:	00005517          	auipc	a0,0x5
ffffffffc0200b9a:	36250513          	addi	a0,a0,866 # ffffffffc0205ef8 <commands+0x4e0>
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
ffffffffc0200bb0:	36450513          	addi	a0,a0,868 # ffffffffc0205f10 <commands+0x4f8>
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
ffffffffc0200bc8:	36450513          	addi	a0,a0,868 # ffffffffc0205f28 <commands+0x510>
ffffffffc0200bcc:	dc8ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200bd0:	10843583          	ld	a1,264(s0)
ffffffffc0200bd4:	00005517          	auipc	a0,0x5
ffffffffc0200bd8:	36c50513          	addi	a0,a0,876 # ffffffffc0205f40 <commands+0x528>
ffffffffc0200bdc:	db8ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  tval 0x%08x\n", tf->tval);
ffffffffc0200be0:	11043583          	ld	a1,272(s0)
ffffffffc0200be4:	00005517          	auipc	a0,0x5
ffffffffc0200be8:	37450513          	addi	a0,a0,884 # ffffffffc0205f58 <commands+0x540>
ffffffffc0200bec:	da8ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200bf0:	11843583          	ld	a1,280(s0)
}
ffffffffc0200bf4:	6402                	ld	s0,0(sp)
ffffffffc0200bf6:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200bf8:	00005517          	auipc	a0,0x5
ffffffffc0200bfc:	37050513          	addi	a0,a0,880 # ffffffffc0205f68 <commands+0x550>
}
ffffffffc0200c00:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200c02:	d92ff06f          	j	ffffffffc0200194 <cprintf>

ffffffffc0200c06 <pgfault_handler>:
pgfault_handler(struct trapframe *tf) {
ffffffffc0200c06:	1141                	addi	sp,sp,-16
ffffffffc0200c08:	e406                	sd	ra,8(sp)
    if (current == NULL) {
ffffffffc0200c0a:	000aa797          	auipc	a5,0xaa
ffffffffc0200c0e:	cee7b783          	ld	a5,-786(a5) # ffffffffc02aa8f8 <current>
ffffffffc0200c12:	c799                	beqz	a5,ffffffffc0200c20 <pgfault_handler+0x1a>
    if (current->mm == NULL) {
ffffffffc0200c14:	779c                	ld	a5,40(a5)
ffffffffc0200c16:	c39d                	beqz	a5,ffffffffc0200c3c <pgfault_handler+0x36>
}
ffffffffc0200c18:	60a2                	ld	ra,8(sp)
ffffffffc0200c1a:	5575                	li	a0,-3
ffffffffc0200c1c:	0141                	addi	sp,sp,16
ffffffffc0200c1e:	8082                	ret
        print_trapframe(tf);
ffffffffc0200c20:	f85ff0ef          	jal	ra,ffffffffc0200ba4 <print_trapframe>
        panic("page fault in kernel!");
ffffffffc0200c24:	00005617          	auipc	a2,0x5
ffffffffc0200c28:	35c60613          	addi	a2,a2,860 # ffffffffc0205f80 <commands+0x568>
ffffffffc0200c2c:	02500593          	li	a1,37
ffffffffc0200c30:	00005517          	auipc	a0,0x5
ffffffffc0200c34:	36850513          	addi	a0,a0,872 # ffffffffc0205f98 <commands+0x580>
ffffffffc0200c38:	857ff0ef          	jal	ra,ffffffffc020048e <__panic>
        print_trapframe(tf);
ffffffffc0200c3c:	f69ff0ef          	jal	ra,ffffffffc0200ba4 <print_trapframe>
        panic("page fault in kernel thread!");
ffffffffc0200c40:	00005617          	auipc	a2,0x5
ffffffffc0200c44:	37060613          	addi	a2,a2,880 # ffffffffc0205fb0 <commands+0x598>
ffffffffc0200c48:	02b00593          	li	a1,43
ffffffffc0200c4c:	00005517          	auipc	a0,0x5
ffffffffc0200c50:	34c50513          	addi	a0,a0,844 # ffffffffc0205f98 <commands+0x580>
ffffffffc0200c54:	83bff0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0200c58 <interrupt_handler>:

extern struct mm_struct *check_mm_struct;

void interrupt_handler(struct trapframe *tf)
{
    intptr_t cause = (tf->cause << 1) >> 1;
ffffffffc0200c58:	11853783          	ld	a5,280(a0)
ffffffffc0200c5c:	472d                	li	a4,11
ffffffffc0200c5e:	0786                	slli	a5,a5,0x1
ffffffffc0200c60:	8385                	srli	a5,a5,0x1
ffffffffc0200c62:	08f76463          	bltu	a4,a5,ffffffffc0200cea <interrupt_handler+0x92>
ffffffffc0200c66:	00005717          	auipc	a4,0x5
ffffffffc0200c6a:	40a70713          	addi	a4,a4,1034 # ffffffffc0206070 <commands+0x658>
ffffffffc0200c6e:	078a                	slli	a5,a5,0x2
ffffffffc0200c70:	97ba                	add	a5,a5,a4
ffffffffc0200c72:	439c                	lw	a5,0(a5)
ffffffffc0200c74:	97ba                	add	a5,a5,a4
ffffffffc0200c76:	8782                	jr	a5
        break;
    case IRQ_H_SOFT:
        cprintf("Hypervisor software interrupt\n");
        break;
    case IRQ_M_SOFT:
        cprintf("Machine software interrupt\n");
ffffffffc0200c78:	00005517          	auipc	a0,0x5
ffffffffc0200c7c:	3b850513          	addi	a0,a0,952 # ffffffffc0206030 <commands+0x618>
ffffffffc0200c80:	d14ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Hypervisor software interrupt\n");
ffffffffc0200c84:	00005517          	auipc	a0,0x5
ffffffffc0200c88:	38c50513          	addi	a0,a0,908 # ffffffffc0206010 <commands+0x5f8>
ffffffffc0200c8c:	d08ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("User software interrupt\n");
ffffffffc0200c90:	00005517          	auipc	a0,0x5
ffffffffc0200c94:	34050513          	addi	a0,a0,832 # ffffffffc0205fd0 <commands+0x5b8>
ffffffffc0200c98:	cfcff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Supervisor software interrupt\n");
ffffffffc0200c9c:	00005517          	auipc	a0,0x5
ffffffffc0200ca0:	35450513          	addi	a0,a0,852 # ffffffffc0205ff0 <commands+0x5d8>
ffffffffc0200ca4:	cf0ff06f          	j	ffffffffc0200194 <cprintf>
{
ffffffffc0200ca8:	1141                	addi	sp,sp,-16
ffffffffc0200caa:	e406                	sd	ra,8(sp)
        *(1) 设置下一次时钟中断（clock_set_next_event）
        *(2) ticks 计数器自增
        *(3) 每 TICK_NUM 次中断（如 100 次），进行判断当前是否有进程正在运行，如果有则标记该进程需要被重新调度（current->need_resched）
        */
        // (1) 设置下一次时钟中断
        clock_set_next_event();
ffffffffc0200cac:	8c7ff0ef          	jal	ra,ffffffffc0200572 <clock_set_next_event>
        
        // (2) ticks 计数器自增
        ticks++;
ffffffffc0200cb0:	000aa797          	auipc	a5,0xaa
ffffffffc0200cb4:	bf078793          	addi	a5,a5,-1040 # ffffffffc02aa8a0 <ticks>
ffffffffc0200cb8:	6398                	ld	a4,0(a5)
ffffffffc0200cba:	0705                	addi	a4,a4,1
ffffffffc0200cbc:	e398                	sd	a4,0(a5)
        
        // (3) 每 TICK_NUM 次中断，标记进程需要重新调度
        if (ticks % TICK_NUM == 0) {
ffffffffc0200cbe:	639c                	ld	a5,0(a5)
ffffffffc0200cc0:	06400713          	li	a4,100
ffffffffc0200cc4:	02e7f7b3          	remu	a5,a5,a4
ffffffffc0200cc8:	eb81                	bnez	a5,ffffffffc0200cd8 <interrupt_handler+0x80>
            if (current != NULL) {
ffffffffc0200cca:	000aa797          	auipc	a5,0xaa
ffffffffc0200cce:	c2e7b783          	ld	a5,-978(a5) # ffffffffc02aa8f8 <current>
ffffffffc0200cd2:	c399                	beqz	a5,ffffffffc0200cd8 <interrupt_handler+0x80>
                current->need_resched = 1;
ffffffffc0200cd4:	4705                	li	a4,1
ffffffffc0200cd6:	ef98                	sd	a4,24(a5)
        break;
    default:
        print_trapframe(tf);
        break;
    }
}
ffffffffc0200cd8:	60a2                	ld	ra,8(sp)
ffffffffc0200cda:	0141                	addi	sp,sp,16
ffffffffc0200cdc:	8082                	ret
        cprintf("Supervisor external interrupt\n");
ffffffffc0200cde:	00005517          	auipc	a0,0x5
ffffffffc0200ce2:	37250513          	addi	a0,a0,882 # ffffffffc0206050 <commands+0x638>
ffffffffc0200ce6:	caeff06f          	j	ffffffffc0200194 <cprintf>
        print_trapframe(tf);
ffffffffc0200cea:	bd6d                	j	ffffffffc0200ba4 <print_trapframe>

ffffffffc0200cec <exception_handler>:
void kernel_execve_ret(struct trapframe *tf, uintptr_t kstacktop);
void exception_handler(struct trapframe *tf)
{
    int ret;
    switch (tf->cause)
ffffffffc0200cec:	11853783          	ld	a5,280(a0)
{
ffffffffc0200cf0:	1141                	addi	sp,sp,-16
ffffffffc0200cf2:	e022                	sd	s0,0(sp)
ffffffffc0200cf4:	e406                	sd	ra,8(sp)
ffffffffc0200cf6:	473d                	li	a4,15
ffffffffc0200cf8:	842a                	mv	s0,a0
ffffffffc0200cfa:	14f76763          	bltu	a4,a5,ffffffffc0200e48 <exception_handler+0x15c>
ffffffffc0200cfe:	00005717          	auipc	a4,0x5
ffffffffc0200d02:	53270713          	addi	a4,a4,1330 # ffffffffc0206230 <commands+0x818>
ffffffffc0200d06:	078a                	slli	a5,a5,0x2
ffffffffc0200d08:	97ba                	add	a5,a5,a4
ffffffffc0200d0a:	439c                	lw	a5,0(a5)
ffffffffc0200d0c:	97ba                	add	a5,a5,a4
ffffffffc0200d0e:	8782                	jr	a5
        // cprintf("Environment call from U-mode\n");
        tf->epc += 4;
        syscall();
        break;
    case CAUSE_SUPERVISOR_ECALL:
        cprintf("Environment call from S-mode\n");
ffffffffc0200d10:	00005517          	auipc	a0,0x5
ffffffffc0200d14:	46050513          	addi	a0,a0,1120 # ffffffffc0206170 <commands+0x758>
ffffffffc0200d18:	c7cff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        tf->epc += 4;
ffffffffc0200d1c:	10843783          	ld	a5,264(s0)
        break;
    default:
        print_trapframe(tf);
        break;
    }
}
ffffffffc0200d20:	60a2                	ld	ra,8(sp)
        tf->epc += 4;
ffffffffc0200d22:	0791                	addi	a5,a5,4
ffffffffc0200d24:	10f43423          	sd	a5,264(s0)
}
ffffffffc0200d28:	6402                	ld	s0,0(sp)
ffffffffc0200d2a:	0141                	addi	sp,sp,16
        syscall();
ffffffffc0200d2c:	52e0406f          	j	ffffffffc020525a <syscall>
        cprintf("Environment call from H-mode\n");
ffffffffc0200d30:	00005517          	auipc	a0,0x5
ffffffffc0200d34:	46050513          	addi	a0,a0,1120 # ffffffffc0206190 <commands+0x778>
}
ffffffffc0200d38:	6402                	ld	s0,0(sp)
ffffffffc0200d3a:	60a2                	ld	ra,8(sp)
ffffffffc0200d3c:	0141                	addi	sp,sp,16
        cprintf("Instruction access fault\n");
ffffffffc0200d3e:	c56ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Environment call from M-mode\n");
ffffffffc0200d42:	00005517          	auipc	a0,0x5
ffffffffc0200d46:	46e50513          	addi	a0,a0,1134 # ffffffffc02061b0 <commands+0x798>
ffffffffc0200d4a:	b7fd                	j	ffffffffc0200d38 <exception_handler+0x4c>
        if ((ret = pgfault_handler(tf)) != 0) {
ffffffffc0200d4c:	ebbff0ef          	jal	ra,ffffffffc0200c06 <pgfault_handler>
ffffffffc0200d50:	0c050963          	beqz	a0,ffffffffc0200e22 <exception_handler+0x136>
            cprintf("Instruction page fault\n");  // 打印缺页类型
ffffffffc0200d54:	00005517          	auipc	a0,0x5
ffffffffc0200d58:	47c50513          	addi	a0,a0,1148 # ffffffffc02061d0 <commands+0x7b8>
ffffffffc0200d5c:	c38ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
            print_trapframe(tf);                  // 打印异常时的CPU状态
ffffffffc0200d60:	8522                	mv	a0,s0
ffffffffc0200d62:	e43ff0ef          	jal	ra,ffffffffc0200ba4 <print_trapframe>
            if (current != NULL) {
ffffffffc0200d66:	000aa797          	auipc	a5,0xaa
ffffffffc0200d6a:	b927b783          	ld	a5,-1134(a5) # ffffffffc02aa8f8 <current>
ffffffffc0200d6e:	ebbd                	bnez	a5,ffffffffc0200de4 <exception_handler+0xf8>
                panic("kernel page fault");       // 否则就触发内核panic
ffffffffc0200d70:	00005617          	auipc	a2,0x5
ffffffffc0200d74:	47860613          	addi	a2,a2,1144 # ffffffffc02061e8 <commands+0x7d0>
ffffffffc0200d78:	0f700593          	li	a1,247
ffffffffc0200d7c:	00005517          	auipc	a0,0x5
ffffffffc0200d80:	21c50513          	addi	a0,a0,540 # ffffffffc0205f98 <commands+0x580>
ffffffffc0200d84:	f0aff0ef          	jal	ra,ffffffffc020048e <__panic>
        if ((ret = pgfault_handler(tf)) != 0) {
ffffffffc0200d88:	e7fff0ef          	jal	ra,ffffffffc0200c06 <pgfault_handler>
ffffffffc0200d8c:	c959                	beqz	a0,ffffffffc0200e22 <exception_handler+0x136>
            cprintf("Load page fault\n");
ffffffffc0200d8e:	00005517          	auipc	a0,0x5
ffffffffc0200d92:	47250513          	addi	a0,a0,1138 # ffffffffc0206200 <commands+0x7e8>
ffffffffc0200d96:	bfeff0ef          	jal	ra,ffffffffc0200194 <cprintf>
            print_trapframe(tf);
ffffffffc0200d9a:	8522                	mv	a0,s0
ffffffffc0200d9c:	e09ff0ef          	jal	ra,ffffffffc0200ba4 <print_trapframe>
            if (current != NULL) {
ffffffffc0200da0:	000aa797          	auipc	a5,0xaa
ffffffffc0200da4:	b587b783          	ld	a5,-1192(a5) # ffffffffc02aa8f8 <current>
ffffffffc0200da8:	ef95                	bnez	a5,ffffffffc0200de4 <exception_handler+0xf8>
                panic("kernel page fault");
ffffffffc0200daa:	00005617          	auipc	a2,0x5
ffffffffc0200dae:	43e60613          	addi	a2,a2,1086 # ffffffffc02061e8 <commands+0x7d0>
ffffffffc0200db2:	10200593          	li	a1,258
ffffffffc0200db6:	00005517          	auipc	a0,0x5
ffffffffc0200dba:	1e250513          	addi	a0,a0,482 # ffffffffc0205f98 <commands+0x580>
ffffffffc0200dbe:	ed0ff0ef          	jal	ra,ffffffffc020048e <__panic>
        if ((ret = pgfault_handler(tf)) != 0) {
ffffffffc0200dc2:	e45ff0ef          	jal	ra,ffffffffc0200c06 <pgfault_handler>
ffffffffc0200dc6:	cd31                	beqz	a0,ffffffffc0200e22 <exception_handler+0x136>
            cprintf("Store/AMO page fault\n");
ffffffffc0200dc8:	00005517          	auipc	a0,0x5
ffffffffc0200dcc:	45050513          	addi	a0,a0,1104 # ffffffffc0206218 <commands+0x800>
ffffffffc0200dd0:	bc4ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
            print_trapframe(tf);
ffffffffc0200dd4:	8522                	mv	a0,s0
ffffffffc0200dd6:	dcfff0ef          	jal	ra,ffffffffc0200ba4 <print_trapframe>
            if (current != NULL) {
ffffffffc0200dda:	000aa797          	auipc	a5,0xaa
ffffffffc0200dde:	b1e7b783          	ld	a5,-1250(a5) # ffffffffc02aa8f8 <current>
ffffffffc0200de2:	c7c1                	beqz	a5,ffffffffc0200e6a <exception_handler+0x17e>
}
ffffffffc0200de4:	6402                	ld	s0,0(sp)
ffffffffc0200de6:	60a2                	ld	ra,8(sp)
                do_exit(-E_KILLED);               // 终止当前的用户态进程
ffffffffc0200de8:	555d                	li	a0,-9
}
ffffffffc0200dea:	0141                	addi	sp,sp,16
                do_exit(-E_KILLED);               // 终止当前的用户态进程
ffffffffc0200dec:	6c40306f          	j	ffffffffc02044b0 <do_exit>
        cprintf("Instruction address misaligned\n");
ffffffffc0200df0:	00005517          	auipc	a0,0x5
ffffffffc0200df4:	2b050513          	addi	a0,a0,688 # ffffffffc02060a0 <commands+0x688>
ffffffffc0200df8:	b781                	j	ffffffffc0200d38 <exception_handler+0x4c>
        cprintf("Instruction access fault\n");
ffffffffc0200dfa:	00005517          	auipc	a0,0x5
ffffffffc0200dfe:	2c650513          	addi	a0,a0,710 # ffffffffc02060c0 <commands+0x6a8>
ffffffffc0200e02:	bf1d                	j	ffffffffc0200d38 <exception_handler+0x4c>
        cprintf("Illegal instruction\n");
ffffffffc0200e04:	00005517          	auipc	a0,0x5
ffffffffc0200e08:	2dc50513          	addi	a0,a0,732 # ffffffffc02060e0 <commands+0x6c8>
ffffffffc0200e0c:	b735                	j	ffffffffc0200d38 <exception_handler+0x4c>
        cprintf("Breakpoint\n");
ffffffffc0200e0e:	00005517          	auipc	a0,0x5
ffffffffc0200e12:	2ea50513          	addi	a0,a0,746 # ffffffffc02060f8 <commands+0x6e0>
ffffffffc0200e16:	b7eff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        if (tf->gpr.a7 == 10)  // 通过设置 a7 寄存器的值为10说明这不是一个普通的断点中断，而是要转发到 syscall()，从而产生中断
ffffffffc0200e1a:	6458                	ld	a4,136(s0)
ffffffffc0200e1c:	47a9                	li	a5,10
ffffffffc0200e1e:	eef70fe3          	beq	a4,a5,ffffffffc0200d1c <exception_handler+0x30>
}
ffffffffc0200e22:	60a2                	ld	ra,8(sp)
ffffffffc0200e24:	6402                	ld	s0,0(sp)
ffffffffc0200e26:	0141                	addi	sp,sp,16
ffffffffc0200e28:	8082                	ret
        cprintf("Load address misaligned\n");
ffffffffc0200e2a:	00005517          	auipc	a0,0x5
ffffffffc0200e2e:	2de50513          	addi	a0,a0,734 # ffffffffc0206108 <commands+0x6f0>
ffffffffc0200e32:	b719                	j	ffffffffc0200d38 <exception_handler+0x4c>
        cprintf("Load access fault\n");
ffffffffc0200e34:	00005517          	auipc	a0,0x5
ffffffffc0200e38:	2f450513          	addi	a0,a0,756 # ffffffffc0206128 <commands+0x710>
ffffffffc0200e3c:	bdf5                	j	ffffffffc0200d38 <exception_handler+0x4c>
        cprintf("Store/AMO access fault\n");
ffffffffc0200e3e:	00005517          	auipc	a0,0x5
ffffffffc0200e42:	31a50513          	addi	a0,a0,794 # ffffffffc0206158 <commands+0x740>
ffffffffc0200e46:	bdcd                	j	ffffffffc0200d38 <exception_handler+0x4c>
        print_trapframe(tf);
ffffffffc0200e48:	8522                	mv	a0,s0
}
ffffffffc0200e4a:	6402                	ld	s0,0(sp)
ffffffffc0200e4c:	60a2                	ld	ra,8(sp)
ffffffffc0200e4e:	0141                	addi	sp,sp,16
        print_trapframe(tf);
ffffffffc0200e50:	bb91                	j	ffffffffc0200ba4 <print_trapframe>
        panic("AMO address misaligned\n");
ffffffffc0200e52:	00005617          	auipc	a2,0x5
ffffffffc0200e56:	2ee60613          	addi	a2,a2,750 # ffffffffc0206140 <commands+0x728>
ffffffffc0200e5a:	0db00593          	li	a1,219
ffffffffc0200e5e:	00005517          	auipc	a0,0x5
ffffffffc0200e62:	13a50513          	addi	a0,a0,314 # ffffffffc0205f98 <commands+0x580>
ffffffffc0200e66:	e28ff0ef          	jal	ra,ffffffffc020048e <__panic>
                panic("kernel page fault");
ffffffffc0200e6a:	00005617          	auipc	a2,0x5
ffffffffc0200e6e:	37e60613          	addi	a2,a2,894 # ffffffffc02061e8 <commands+0x7d0>
ffffffffc0200e72:	10d00593          	li	a1,269
ffffffffc0200e76:	00005517          	auipc	a0,0x5
ffffffffc0200e7a:	12250513          	addi	a0,a0,290 # ffffffffc0205f98 <commands+0x580>
ffffffffc0200e7e:	e10ff0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0200e82 <trap>:
 * trap - handles or dispatches an exception/interrupt. if and when trap() returns,
 * the code in kern/trap/trapentry.S restores the old CPU state saved in the
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void trap(struct trapframe *tf)
{
ffffffffc0200e82:	1101                	addi	sp,sp,-32
ffffffffc0200e84:	e822                	sd	s0,16(sp)
    // dispatch based on what type of trap occurred
    //    cputs("some trap");
    if (current == NULL)
ffffffffc0200e86:	000aa417          	auipc	s0,0xaa
ffffffffc0200e8a:	a7240413          	addi	s0,s0,-1422 # ffffffffc02aa8f8 <current>
ffffffffc0200e8e:	6018                	ld	a4,0(s0)
{
ffffffffc0200e90:	ec06                	sd	ra,24(sp)
ffffffffc0200e92:	e426                	sd	s1,8(sp)
ffffffffc0200e94:	e04a                	sd	s2,0(sp)
    if ((intptr_t)tf->cause < 0)
ffffffffc0200e96:	11853683          	ld	a3,280(a0)
    if (current == NULL)
ffffffffc0200e9a:	cf1d                	beqz	a4,ffffffffc0200ed8 <trap+0x56>
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200e9c:	10053483          	ld	s1,256(a0)
    {
        trap_dispatch(tf);
    }
    else
    {
        struct trapframe *otf = current->tf;
ffffffffc0200ea0:	0a073903          	ld	s2,160(a4)
        current->tf = tf;
ffffffffc0200ea4:	f348                	sd	a0,160(a4)
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200ea6:	1004f493          	andi	s1,s1,256
    if ((intptr_t)tf->cause < 0)
ffffffffc0200eaa:	0206c463          	bltz	a3,ffffffffc0200ed2 <trap+0x50>
        exception_handler(tf);
ffffffffc0200eae:	e3fff0ef          	jal	ra,ffffffffc0200cec <exception_handler>

        bool in_kernel = trap_in_kernel(tf);

        trap_dispatch(tf);

        current->tf = otf;
ffffffffc0200eb2:	601c                	ld	a5,0(s0)
ffffffffc0200eb4:	0b27b023          	sd	s2,160(a5)
        if (!in_kernel)
ffffffffc0200eb8:	e499                	bnez	s1,ffffffffc0200ec6 <trap+0x44>
        {
            if (current->flags & PF_EXITING)
ffffffffc0200eba:	0b07a703          	lw	a4,176(a5)
ffffffffc0200ebe:	8b05                	andi	a4,a4,1
ffffffffc0200ec0:	e329                	bnez	a4,ffffffffc0200f02 <trap+0x80>
            {
                do_exit(-E_KILLED);
            }
            if (current->need_resched)
ffffffffc0200ec2:	6f9c                	ld	a5,24(a5)
ffffffffc0200ec4:	eb85                	bnez	a5,ffffffffc0200ef4 <trap+0x72>
            {
                schedule();
            }
        }
    }
}
ffffffffc0200ec6:	60e2                	ld	ra,24(sp)
ffffffffc0200ec8:	6442                	ld	s0,16(sp)
ffffffffc0200eca:	64a2                	ld	s1,8(sp)
ffffffffc0200ecc:	6902                	ld	s2,0(sp)
ffffffffc0200ece:	6105                	addi	sp,sp,32
ffffffffc0200ed0:	8082                	ret
        interrupt_handler(tf);
ffffffffc0200ed2:	d87ff0ef          	jal	ra,ffffffffc0200c58 <interrupt_handler>
ffffffffc0200ed6:	bff1                	j	ffffffffc0200eb2 <trap+0x30>
    if ((intptr_t)tf->cause < 0)
ffffffffc0200ed8:	0006c863          	bltz	a3,ffffffffc0200ee8 <trap+0x66>
}
ffffffffc0200edc:	6442                	ld	s0,16(sp)
ffffffffc0200ede:	60e2                	ld	ra,24(sp)
ffffffffc0200ee0:	64a2                	ld	s1,8(sp)
ffffffffc0200ee2:	6902                	ld	s2,0(sp)
ffffffffc0200ee4:	6105                	addi	sp,sp,32
        exception_handler(tf);
ffffffffc0200ee6:	b519                	j	ffffffffc0200cec <exception_handler>
}
ffffffffc0200ee8:	6442                	ld	s0,16(sp)
ffffffffc0200eea:	60e2                	ld	ra,24(sp)
ffffffffc0200eec:	64a2                	ld	s1,8(sp)
ffffffffc0200eee:	6902                	ld	s2,0(sp)
ffffffffc0200ef0:	6105                	addi	sp,sp,32
        interrupt_handler(tf);
ffffffffc0200ef2:	b39d                	j	ffffffffc0200c58 <interrupt_handler>
}
ffffffffc0200ef4:	6442                	ld	s0,16(sp)
ffffffffc0200ef6:	60e2                	ld	ra,24(sp)
ffffffffc0200ef8:	64a2                	ld	s1,8(sp)
ffffffffc0200efa:	6902                	ld	s2,0(sp)
ffffffffc0200efc:	6105                	addi	sp,sp,32
                schedule();
ffffffffc0200efe:	2700406f          	j	ffffffffc020516e <schedule>
                do_exit(-E_KILLED);
ffffffffc0200f02:	555d                	li	a0,-9
ffffffffc0200f04:	5ac030ef          	jal	ra,ffffffffc02044b0 <do_exit>
            if (current->need_resched)
ffffffffc0200f08:	601c                	ld	a5,0(s0)
ffffffffc0200f0a:	bf65                	j	ffffffffc0200ec2 <trap+0x40>

ffffffffc0200f0c <__alltraps>:
    LOAD x2, 2*REGBYTES(sp)
    .endm

    .globl __alltraps
__alltraps:
    SAVE_ALL
ffffffffc0200f0c:	14011173          	csrrw	sp,sscratch,sp
ffffffffc0200f10:	00011463          	bnez	sp,ffffffffc0200f18 <__alltraps+0xc>
ffffffffc0200f14:	14002173          	csrr	sp,sscratch
ffffffffc0200f18:	712d                	addi	sp,sp,-288
ffffffffc0200f1a:	e002                	sd	zero,0(sp)
ffffffffc0200f1c:	e406                	sd	ra,8(sp)
ffffffffc0200f1e:	ec0e                	sd	gp,24(sp)
ffffffffc0200f20:	f012                	sd	tp,32(sp)
ffffffffc0200f22:	f416                	sd	t0,40(sp)
ffffffffc0200f24:	f81a                	sd	t1,48(sp)
ffffffffc0200f26:	fc1e                	sd	t2,56(sp)
ffffffffc0200f28:	e0a2                	sd	s0,64(sp)
ffffffffc0200f2a:	e4a6                	sd	s1,72(sp)
ffffffffc0200f2c:	e8aa                	sd	a0,80(sp)
ffffffffc0200f2e:	ecae                	sd	a1,88(sp)
ffffffffc0200f30:	f0b2                	sd	a2,96(sp)
ffffffffc0200f32:	f4b6                	sd	a3,104(sp)
ffffffffc0200f34:	f8ba                	sd	a4,112(sp)
ffffffffc0200f36:	fcbe                	sd	a5,120(sp)
ffffffffc0200f38:	e142                	sd	a6,128(sp)
ffffffffc0200f3a:	e546                	sd	a7,136(sp)
ffffffffc0200f3c:	e94a                	sd	s2,144(sp)
ffffffffc0200f3e:	ed4e                	sd	s3,152(sp)
ffffffffc0200f40:	f152                	sd	s4,160(sp)
ffffffffc0200f42:	f556                	sd	s5,168(sp)
ffffffffc0200f44:	f95a                	sd	s6,176(sp)
ffffffffc0200f46:	fd5e                	sd	s7,184(sp)
ffffffffc0200f48:	e1e2                	sd	s8,192(sp)
ffffffffc0200f4a:	e5e6                	sd	s9,200(sp)
ffffffffc0200f4c:	e9ea                	sd	s10,208(sp)
ffffffffc0200f4e:	edee                	sd	s11,216(sp)
ffffffffc0200f50:	f1f2                	sd	t3,224(sp)
ffffffffc0200f52:	f5f6                	sd	t4,232(sp)
ffffffffc0200f54:	f9fa                	sd	t5,240(sp)
ffffffffc0200f56:	fdfe                	sd	t6,248(sp)
ffffffffc0200f58:	14001473          	csrrw	s0,sscratch,zero
ffffffffc0200f5c:	100024f3          	csrr	s1,sstatus
ffffffffc0200f60:	14102973          	csrr	s2,sepc
ffffffffc0200f64:	143029f3          	csrr	s3,stval
ffffffffc0200f68:	14202a73          	csrr	s4,scause
ffffffffc0200f6c:	e822                	sd	s0,16(sp)
ffffffffc0200f6e:	e226                	sd	s1,256(sp)
ffffffffc0200f70:	e64a                	sd	s2,264(sp)
ffffffffc0200f72:	ea4e                	sd	s3,272(sp)
ffffffffc0200f74:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200f76:	850a                	mv	a0,sp
    jal trap
ffffffffc0200f78:	f0bff0ef          	jal	ra,ffffffffc0200e82 <trap>

ffffffffc0200f7c <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200f7c:	6492                	ld	s1,256(sp)
ffffffffc0200f7e:	6932                	ld	s2,264(sp)
ffffffffc0200f80:	1004f413          	andi	s0,s1,256
ffffffffc0200f84:	e401                	bnez	s0,ffffffffc0200f8c <__trapret+0x10>
ffffffffc0200f86:	1200                	addi	s0,sp,288
ffffffffc0200f88:	14041073          	csrw	sscratch,s0
ffffffffc0200f8c:	10049073          	csrw	sstatus,s1
ffffffffc0200f90:	14191073          	csrw	sepc,s2
ffffffffc0200f94:	60a2                	ld	ra,8(sp)
ffffffffc0200f96:	61e2                	ld	gp,24(sp)
ffffffffc0200f98:	7202                	ld	tp,32(sp)
ffffffffc0200f9a:	72a2                	ld	t0,40(sp)
ffffffffc0200f9c:	7342                	ld	t1,48(sp)
ffffffffc0200f9e:	73e2                	ld	t2,56(sp)
ffffffffc0200fa0:	6406                	ld	s0,64(sp)
ffffffffc0200fa2:	64a6                	ld	s1,72(sp)
ffffffffc0200fa4:	6546                	ld	a0,80(sp)
ffffffffc0200fa6:	65e6                	ld	a1,88(sp)
ffffffffc0200fa8:	7606                	ld	a2,96(sp)
ffffffffc0200faa:	76a6                	ld	a3,104(sp)
ffffffffc0200fac:	7746                	ld	a4,112(sp)
ffffffffc0200fae:	77e6                	ld	a5,120(sp)
ffffffffc0200fb0:	680a                	ld	a6,128(sp)
ffffffffc0200fb2:	68aa                	ld	a7,136(sp)
ffffffffc0200fb4:	694a                	ld	s2,144(sp)
ffffffffc0200fb6:	69ea                	ld	s3,152(sp)
ffffffffc0200fb8:	7a0a                	ld	s4,160(sp)
ffffffffc0200fba:	7aaa                	ld	s5,168(sp)
ffffffffc0200fbc:	7b4a                	ld	s6,176(sp)
ffffffffc0200fbe:	7bea                	ld	s7,184(sp)
ffffffffc0200fc0:	6c0e                	ld	s8,192(sp)
ffffffffc0200fc2:	6cae                	ld	s9,200(sp)
ffffffffc0200fc4:	6d4e                	ld	s10,208(sp)
ffffffffc0200fc6:	6dee                	ld	s11,216(sp)
ffffffffc0200fc8:	7e0e                	ld	t3,224(sp)
ffffffffc0200fca:	7eae                	ld	t4,232(sp)
ffffffffc0200fcc:	7f4e                	ld	t5,240(sp)
ffffffffc0200fce:	7fee                	ld	t6,248(sp)
ffffffffc0200fd0:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
ffffffffc0200fd2:	10200073          	sret

ffffffffc0200fd6 <forkrets>:
 
    .globl forkrets
forkrets:
    # set stack to this new process's trapframe
    move sp, a0
ffffffffc0200fd6:	812a                	mv	sp,a0
    j __trapret
ffffffffc0200fd8:	b755                	j	ffffffffc0200f7c <__trapret>

ffffffffc0200fda <kernel_execve_ret>:

    .global kernel_execve_ret
kernel_execve_ret:
    // adjust sp to beneath kstacktop of current process
    addi a1, a1, -36*REGBYTES
ffffffffc0200fda:	ee058593          	addi	a1,a1,-288

    // copy from previous trapframe to new trapframe
    LOAD s1, 35*REGBYTES(a0)
ffffffffc0200fde:	11853483          	ld	s1,280(a0)
    STORE s1, 35*REGBYTES(a1)
ffffffffc0200fe2:	1095bc23          	sd	s1,280(a1)
    LOAD s1, 34*REGBYTES(a0)
ffffffffc0200fe6:	11053483          	ld	s1,272(a0)
    STORE s1, 34*REGBYTES(a1)
ffffffffc0200fea:	1095b823          	sd	s1,272(a1)
    LOAD s1, 33*REGBYTES(a0)
ffffffffc0200fee:	10853483          	ld	s1,264(a0)
    STORE s1, 33*REGBYTES(a1)
ffffffffc0200ff2:	1095b423          	sd	s1,264(a1)
    LOAD s1, 32*REGBYTES(a0)
ffffffffc0200ff6:	10053483          	ld	s1,256(a0)
    STORE s1, 32*REGBYTES(a1)
ffffffffc0200ffa:	1095b023          	sd	s1,256(a1)
    LOAD s1, 31*REGBYTES(a0)
ffffffffc0200ffe:	7d64                	ld	s1,248(a0)
    STORE s1, 31*REGBYTES(a1)
ffffffffc0201000:	fde4                	sd	s1,248(a1)
    LOAD s1, 30*REGBYTES(a0)
ffffffffc0201002:	7964                	ld	s1,240(a0)
    STORE s1, 30*REGBYTES(a1)
ffffffffc0201004:	f9e4                	sd	s1,240(a1)
    LOAD s1, 29*REGBYTES(a0)
ffffffffc0201006:	7564                	ld	s1,232(a0)
    STORE s1, 29*REGBYTES(a1)
ffffffffc0201008:	f5e4                	sd	s1,232(a1)
    LOAD s1, 28*REGBYTES(a0)
ffffffffc020100a:	7164                	ld	s1,224(a0)
    STORE s1, 28*REGBYTES(a1)
ffffffffc020100c:	f1e4                	sd	s1,224(a1)
    LOAD s1, 27*REGBYTES(a0)
ffffffffc020100e:	6d64                	ld	s1,216(a0)
    STORE s1, 27*REGBYTES(a1)
ffffffffc0201010:	ede4                	sd	s1,216(a1)
    LOAD s1, 26*REGBYTES(a0)
ffffffffc0201012:	6964                	ld	s1,208(a0)
    STORE s1, 26*REGBYTES(a1)
ffffffffc0201014:	e9e4                	sd	s1,208(a1)
    LOAD s1, 25*REGBYTES(a0)
ffffffffc0201016:	6564                	ld	s1,200(a0)
    STORE s1, 25*REGBYTES(a1)
ffffffffc0201018:	e5e4                	sd	s1,200(a1)
    LOAD s1, 24*REGBYTES(a0)
ffffffffc020101a:	6164                	ld	s1,192(a0)
    STORE s1, 24*REGBYTES(a1)
ffffffffc020101c:	e1e4                	sd	s1,192(a1)
    LOAD s1, 23*REGBYTES(a0)
ffffffffc020101e:	7d44                	ld	s1,184(a0)
    STORE s1, 23*REGBYTES(a1)
ffffffffc0201020:	fdc4                	sd	s1,184(a1)
    LOAD s1, 22*REGBYTES(a0)
ffffffffc0201022:	7944                	ld	s1,176(a0)
    STORE s1, 22*REGBYTES(a1)
ffffffffc0201024:	f9c4                	sd	s1,176(a1)
    LOAD s1, 21*REGBYTES(a0)
ffffffffc0201026:	7544                	ld	s1,168(a0)
    STORE s1, 21*REGBYTES(a1)
ffffffffc0201028:	f5c4                	sd	s1,168(a1)
    LOAD s1, 20*REGBYTES(a0)
ffffffffc020102a:	7144                	ld	s1,160(a0)
    STORE s1, 20*REGBYTES(a1)
ffffffffc020102c:	f1c4                	sd	s1,160(a1)
    LOAD s1, 19*REGBYTES(a0)
ffffffffc020102e:	6d44                	ld	s1,152(a0)
    STORE s1, 19*REGBYTES(a1)
ffffffffc0201030:	edc4                	sd	s1,152(a1)
    LOAD s1, 18*REGBYTES(a0)
ffffffffc0201032:	6944                	ld	s1,144(a0)
    STORE s1, 18*REGBYTES(a1)
ffffffffc0201034:	e9c4                	sd	s1,144(a1)
    LOAD s1, 17*REGBYTES(a0)
ffffffffc0201036:	6544                	ld	s1,136(a0)
    STORE s1, 17*REGBYTES(a1)
ffffffffc0201038:	e5c4                	sd	s1,136(a1)
    LOAD s1, 16*REGBYTES(a0)
ffffffffc020103a:	6144                	ld	s1,128(a0)
    STORE s1, 16*REGBYTES(a1)
ffffffffc020103c:	e1c4                	sd	s1,128(a1)
    LOAD s1, 15*REGBYTES(a0)
ffffffffc020103e:	7d24                	ld	s1,120(a0)
    STORE s1, 15*REGBYTES(a1)
ffffffffc0201040:	fda4                	sd	s1,120(a1)
    LOAD s1, 14*REGBYTES(a0)
ffffffffc0201042:	7924                	ld	s1,112(a0)
    STORE s1, 14*REGBYTES(a1)
ffffffffc0201044:	f9a4                	sd	s1,112(a1)
    LOAD s1, 13*REGBYTES(a0)
ffffffffc0201046:	7524                	ld	s1,104(a0)
    STORE s1, 13*REGBYTES(a1)
ffffffffc0201048:	f5a4                	sd	s1,104(a1)
    LOAD s1, 12*REGBYTES(a0)
ffffffffc020104a:	7124                	ld	s1,96(a0)
    STORE s1, 12*REGBYTES(a1)
ffffffffc020104c:	f1a4                	sd	s1,96(a1)
    LOAD s1, 11*REGBYTES(a0)
ffffffffc020104e:	6d24                	ld	s1,88(a0)
    STORE s1, 11*REGBYTES(a1)
ffffffffc0201050:	eda4                	sd	s1,88(a1)
    LOAD s1, 10*REGBYTES(a0)
ffffffffc0201052:	6924                	ld	s1,80(a0)
    STORE s1, 10*REGBYTES(a1)
ffffffffc0201054:	e9a4                	sd	s1,80(a1)
    LOAD s1, 9*REGBYTES(a0)
ffffffffc0201056:	6524                	ld	s1,72(a0)
    STORE s1, 9*REGBYTES(a1)
ffffffffc0201058:	e5a4                	sd	s1,72(a1)
    LOAD s1, 8*REGBYTES(a0)
ffffffffc020105a:	6124                	ld	s1,64(a0)
    STORE s1, 8*REGBYTES(a1)
ffffffffc020105c:	e1a4                	sd	s1,64(a1)
    LOAD s1, 7*REGBYTES(a0)
ffffffffc020105e:	7d04                	ld	s1,56(a0)
    STORE s1, 7*REGBYTES(a1)
ffffffffc0201060:	fd84                	sd	s1,56(a1)
    LOAD s1, 6*REGBYTES(a0)
ffffffffc0201062:	7904                	ld	s1,48(a0)
    STORE s1, 6*REGBYTES(a1)
ffffffffc0201064:	f984                	sd	s1,48(a1)
    LOAD s1, 5*REGBYTES(a0)
ffffffffc0201066:	7504                	ld	s1,40(a0)
    STORE s1, 5*REGBYTES(a1)
ffffffffc0201068:	f584                	sd	s1,40(a1)
    LOAD s1, 4*REGBYTES(a0)
ffffffffc020106a:	7104                	ld	s1,32(a0)
    STORE s1, 4*REGBYTES(a1)
ffffffffc020106c:	f184                	sd	s1,32(a1)
    LOAD s1, 3*REGBYTES(a0)
ffffffffc020106e:	6d04                	ld	s1,24(a0)
    STORE s1, 3*REGBYTES(a1)
ffffffffc0201070:	ed84                	sd	s1,24(a1)
    LOAD s1, 2*REGBYTES(a0)
ffffffffc0201072:	6904                	ld	s1,16(a0)
    STORE s1, 2*REGBYTES(a1)
ffffffffc0201074:	e984                	sd	s1,16(a1)
    LOAD s1, 1*REGBYTES(a0)
ffffffffc0201076:	6504                	ld	s1,8(a0)
    STORE s1, 1*REGBYTES(a1)
ffffffffc0201078:	e584                	sd	s1,8(a1)
    LOAD s1, 0*REGBYTES(a0)
ffffffffc020107a:	6104                	ld	s1,0(a0)
    STORE s1, 0*REGBYTES(a1)
ffffffffc020107c:	e184                	sd	s1,0(a1)

    // acutually adjust sp
    move sp, a1
ffffffffc020107e:	812e                	mv	sp,a1
ffffffffc0201080:	bdf5                	j	ffffffffc0200f7c <__trapret>

ffffffffc0201082 <default_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0201082:	000a5797          	auipc	a5,0xa5
ffffffffc0201086:	7ee78793          	addi	a5,a5,2030 # ffffffffc02a6870 <free_area>
ffffffffc020108a:	e79c                	sd	a5,8(a5)
ffffffffc020108c:	e39c                	sd	a5,0(a5)

static void
default_init(void)
{
    list_init(&free_list);
    nr_free = 0;
ffffffffc020108e:	0007a823          	sw	zero,16(a5)
}
ffffffffc0201092:	8082                	ret

ffffffffc0201094 <default_nr_free_pages>:

static size_t
default_nr_free_pages(void)
{
    return nr_free;
}
ffffffffc0201094:	000a5517          	auipc	a0,0xa5
ffffffffc0201098:	7ec56503          	lwu	a0,2028(a0) # ffffffffc02a6880 <free_area+0x10>
ffffffffc020109c:	8082                	ret

ffffffffc020109e <default_check>:

// LAB2: below code is used to check the first fit allocation algorithm (your EXERCISE 1)
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void)
{
ffffffffc020109e:	715d                	addi	sp,sp,-80
ffffffffc02010a0:	e0a2                	sd	s0,64(sp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc02010a2:	000a5417          	auipc	s0,0xa5
ffffffffc02010a6:	7ce40413          	addi	s0,s0,1998 # ffffffffc02a6870 <free_area>
ffffffffc02010aa:	641c                	ld	a5,8(s0)
ffffffffc02010ac:	e486                	sd	ra,72(sp)
ffffffffc02010ae:	fc26                	sd	s1,56(sp)
ffffffffc02010b0:	f84a                	sd	s2,48(sp)
ffffffffc02010b2:	f44e                	sd	s3,40(sp)
ffffffffc02010b4:	f052                	sd	s4,32(sp)
ffffffffc02010b6:	ec56                	sd	s5,24(sp)
ffffffffc02010b8:	e85a                	sd	s6,16(sp)
ffffffffc02010ba:	e45e                	sd	s7,8(sp)
ffffffffc02010bc:	e062                	sd	s8,0(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list)
ffffffffc02010be:	2a878d63          	beq	a5,s0,ffffffffc0201378 <default_check+0x2da>
    int count = 0, total = 0;
ffffffffc02010c2:	4481                	li	s1,0
ffffffffc02010c4:	4901                	li	s2,0
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc02010c6:	ff07b703          	ld	a4,-16(a5)
    {
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc02010ca:	8b09                	andi	a4,a4,2
ffffffffc02010cc:	2a070a63          	beqz	a4,ffffffffc0201380 <default_check+0x2e2>
        count++, total += p->property;
ffffffffc02010d0:	ff87a703          	lw	a4,-8(a5)
ffffffffc02010d4:	679c                	ld	a5,8(a5)
ffffffffc02010d6:	2905                	addiw	s2,s2,1
ffffffffc02010d8:	9cb9                	addw	s1,s1,a4
    while ((le = list_next(le)) != &free_list)
ffffffffc02010da:	fe8796e3          	bne	a5,s0,ffffffffc02010c6 <default_check+0x28>
    }
    assert(total == nr_free_pages());
ffffffffc02010de:	89a6                	mv	s3,s1
ffffffffc02010e0:	6df000ef          	jal	ra,ffffffffc0201fbe <nr_free_pages>
ffffffffc02010e4:	6f351e63          	bne	a0,s3,ffffffffc02017e0 <default_check+0x742>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02010e8:	4505                	li	a0,1
ffffffffc02010ea:	657000ef          	jal	ra,ffffffffc0201f40 <alloc_pages>
ffffffffc02010ee:	8aaa                	mv	s5,a0
ffffffffc02010f0:	42050863          	beqz	a0,ffffffffc0201520 <default_check+0x482>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02010f4:	4505                	li	a0,1
ffffffffc02010f6:	64b000ef          	jal	ra,ffffffffc0201f40 <alloc_pages>
ffffffffc02010fa:	89aa                	mv	s3,a0
ffffffffc02010fc:	70050263          	beqz	a0,ffffffffc0201800 <default_check+0x762>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201100:	4505                	li	a0,1
ffffffffc0201102:	63f000ef          	jal	ra,ffffffffc0201f40 <alloc_pages>
ffffffffc0201106:	8a2a                	mv	s4,a0
ffffffffc0201108:	48050c63          	beqz	a0,ffffffffc02015a0 <default_check+0x502>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc020110c:	293a8a63          	beq	s5,s3,ffffffffc02013a0 <default_check+0x302>
ffffffffc0201110:	28aa8863          	beq	s5,a0,ffffffffc02013a0 <default_check+0x302>
ffffffffc0201114:	28a98663          	beq	s3,a0,ffffffffc02013a0 <default_check+0x302>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0201118:	000aa783          	lw	a5,0(s5)
ffffffffc020111c:	2a079263          	bnez	a5,ffffffffc02013c0 <default_check+0x322>
ffffffffc0201120:	0009a783          	lw	a5,0(s3)
ffffffffc0201124:	28079e63          	bnez	a5,ffffffffc02013c0 <default_check+0x322>
ffffffffc0201128:	411c                	lw	a5,0(a0)
ffffffffc020112a:	28079b63          	bnez	a5,ffffffffc02013c0 <default_check+0x322>
extern uint_t va_pa_offset;

static inline ppn_t
page2ppn(struct Page *page)
{
    return page - pages + nbase;
ffffffffc020112e:	000a9797          	auipc	a5,0xa9
ffffffffc0201132:	7b27b783          	ld	a5,1970(a5) # ffffffffc02aa8e0 <pages>
ffffffffc0201136:	40fa8733          	sub	a4,s5,a5
ffffffffc020113a:	00006617          	auipc	a2,0x6
ffffffffc020113e:	7fe63603          	ld	a2,2046(a2) # ffffffffc0207938 <nbase>
ffffffffc0201142:	8719                	srai	a4,a4,0x6
ffffffffc0201144:	9732                	add	a4,a4,a2
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0201146:	000a9697          	auipc	a3,0xa9
ffffffffc020114a:	7926b683          	ld	a3,1938(a3) # ffffffffc02aa8d8 <npage>
ffffffffc020114e:	06b2                	slli	a3,a3,0xc
}

static inline uintptr_t
page2pa(struct Page *page)
{
    return page2ppn(page) << PGSHIFT;
ffffffffc0201150:	0732                	slli	a4,a4,0xc
ffffffffc0201152:	28d77763          	bgeu	a4,a3,ffffffffc02013e0 <default_check+0x342>
    return page - pages + nbase;
ffffffffc0201156:	40f98733          	sub	a4,s3,a5
ffffffffc020115a:	8719                	srai	a4,a4,0x6
ffffffffc020115c:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc020115e:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0201160:	4cd77063          	bgeu	a4,a3,ffffffffc0201620 <default_check+0x582>
    return page - pages + nbase;
ffffffffc0201164:	40f507b3          	sub	a5,a0,a5
ffffffffc0201168:	8799                	srai	a5,a5,0x6
ffffffffc020116a:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc020116c:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc020116e:	30d7f963          	bgeu	a5,a3,ffffffffc0201480 <default_check+0x3e2>
    assert(alloc_page() == NULL);
ffffffffc0201172:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0201174:	00043c03          	ld	s8,0(s0)
ffffffffc0201178:	00843b83          	ld	s7,8(s0)
    unsigned int nr_free_store = nr_free;
ffffffffc020117c:	01042b03          	lw	s6,16(s0)
    elm->prev = elm->next = elm;
ffffffffc0201180:	e400                	sd	s0,8(s0)
ffffffffc0201182:	e000                	sd	s0,0(s0)
    nr_free = 0;
ffffffffc0201184:	000a5797          	auipc	a5,0xa5
ffffffffc0201188:	6e07ae23          	sw	zero,1788(a5) # ffffffffc02a6880 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc020118c:	5b5000ef          	jal	ra,ffffffffc0201f40 <alloc_pages>
ffffffffc0201190:	2c051863          	bnez	a0,ffffffffc0201460 <default_check+0x3c2>
    free_page(p0);
ffffffffc0201194:	4585                	li	a1,1
ffffffffc0201196:	8556                	mv	a0,s5
ffffffffc0201198:	5e7000ef          	jal	ra,ffffffffc0201f7e <free_pages>
    free_page(p1);
ffffffffc020119c:	4585                	li	a1,1
ffffffffc020119e:	854e                	mv	a0,s3
ffffffffc02011a0:	5df000ef          	jal	ra,ffffffffc0201f7e <free_pages>
    free_page(p2);
ffffffffc02011a4:	4585                	li	a1,1
ffffffffc02011a6:	8552                	mv	a0,s4
ffffffffc02011a8:	5d7000ef          	jal	ra,ffffffffc0201f7e <free_pages>
    assert(nr_free == 3);
ffffffffc02011ac:	4818                	lw	a4,16(s0)
ffffffffc02011ae:	478d                	li	a5,3
ffffffffc02011b0:	28f71863          	bne	a4,a5,ffffffffc0201440 <default_check+0x3a2>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02011b4:	4505                	li	a0,1
ffffffffc02011b6:	58b000ef          	jal	ra,ffffffffc0201f40 <alloc_pages>
ffffffffc02011ba:	89aa                	mv	s3,a0
ffffffffc02011bc:	26050263          	beqz	a0,ffffffffc0201420 <default_check+0x382>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02011c0:	4505                	li	a0,1
ffffffffc02011c2:	57f000ef          	jal	ra,ffffffffc0201f40 <alloc_pages>
ffffffffc02011c6:	8aaa                	mv	s5,a0
ffffffffc02011c8:	3a050c63          	beqz	a0,ffffffffc0201580 <default_check+0x4e2>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02011cc:	4505                	li	a0,1
ffffffffc02011ce:	573000ef          	jal	ra,ffffffffc0201f40 <alloc_pages>
ffffffffc02011d2:	8a2a                	mv	s4,a0
ffffffffc02011d4:	38050663          	beqz	a0,ffffffffc0201560 <default_check+0x4c2>
    assert(alloc_page() == NULL);
ffffffffc02011d8:	4505                	li	a0,1
ffffffffc02011da:	567000ef          	jal	ra,ffffffffc0201f40 <alloc_pages>
ffffffffc02011de:	36051163          	bnez	a0,ffffffffc0201540 <default_check+0x4a2>
    free_page(p0);
ffffffffc02011e2:	4585                	li	a1,1
ffffffffc02011e4:	854e                	mv	a0,s3
ffffffffc02011e6:	599000ef          	jal	ra,ffffffffc0201f7e <free_pages>
    assert(!list_empty(&free_list));
ffffffffc02011ea:	641c                	ld	a5,8(s0)
ffffffffc02011ec:	20878a63          	beq	a5,s0,ffffffffc0201400 <default_check+0x362>
    assert((p = alloc_page()) == p0);
ffffffffc02011f0:	4505                	li	a0,1
ffffffffc02011f2:	54f000ef          	jal	ra,ffffffffc0201f40 <alloc_pages>
ffffffffc02011f6:	30a99563          	bne	s3,a0,ffffffffc0201500 <default_check+0x462>
    assert(alloc_page() == NULL);
ffffffffc02011fa:	4505                	li	a0,1
ffffffffc02011fc:	545000ef          	jal	ra,ffffffffc0201f40 <alloc_pages>
ffffffffc0201200:	2e051063          	bnez	a0,ffffffffc02014e0 <default_check+0x442>
    assert(nr_free == 0);
ffffffffc0201204:	481c                	lw	a5,16(s0)
ffffffffc0201206:	2a079d63          	bnez	a5,ffffffffc02014c0 <default_check+0x422>
    free_page(p);
ffffffffc020120a:	854e                	mv	a0,s3
ffffffffc020120c:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc020120e:	01843023          	sd	s8,0(s0)
ffffffffc0201212:	01743423          	sd	s7,8(s0)
    nr_free = nr_free_store;
ffffffffc0201216:	01642823          	sw	s6,16(s0)
    free_page(p);
ffffffffc020121a:	565000ef          	jal	ra,ffffffffc0201f7e <free_pages>
    free_page(p1);
ffffffffc020121e:	4585                	li	a1,1
ffffffffc0201220:	8556                	mv	a0,s5
ffffffffc0201222:	55d000ef          	jal	ra,ffffffffc0201f7e <free_pages>
    free_page(p2);
ffffffffc0201226:	4585                	li	a1,1
ffffffffc0201228:	8552                	mv	a0,s4
ffffffffc020122a:	555000ef          	jal	ra,ffffffffc0201f7e <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc020122e:	4515                	li	a0,5
ffffffffc0201230:	511000ef          	jal	ra,ffffffffc0201f40 <alloc_pages>
ffffffffc0201234:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0201236:	26050563          	beqz	a0,ffffffffc02014a0 <default_check+0x402>
ffffffffc020123a:	651c                	ld	a5,8(a0)
ffffffffc020123c:	8385                	srli	a5,a5,0x1
ffffffffc020123e:	8b85                	andi	a5,a5,1
    assert(!PageProperty(p0));
ffffffffc0201240:	54079063          	bnez	a5,ffffffffc0201780 <default_check+0x6e2>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0201244:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0201246:	00043b03          	ld	s6,0(s0)
ffffffffc020124a:	00843a83          	ld	s5,8(s0)
ffffffffc020124e:	e000                	sd	s0,0(s0)
ffffffffc0201250:	e400                	sd	s0,8(s0)
    assert(alloc_page() == NULL);
ffffffffc0201252:	4ef000ef          	jal	ra,ffffffffc0201f40 <alloc_pages>
ffffffffc0201256:	50051563          	bnez	a0,ffffffffc0201760 <default_check+0x6c2>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc020125a:	08098a13          	addi	s4,s3,128
ffffffffc020125e:	8552                	mv	a0,s4
ffffffffc0201260:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc0201262:	01042b83          	lw	s7,16(s0)
    nr_free = 0;
ffffffffc0201266:	000a5797          	auipc	a5,0xa5
ffffffffc020126a:	6007ad23          	sw	zero,1562(a5) # ffffffffc02a6880 <free_area+0x10>
    free_pages(p0 + 2, 3);
ffffffffc020126e:	511000ef          	jal	ra,ffffffffc0201f7e <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc0201272:	4511                	li	a0,4
ffffffffc0201274:	4cd000ef          	jal	ra,ffffffffc0201f40 <alloc_pages>
ffffffffc0201278:	4c051463          	bnez	a0,ffffffffc0201740 <default_check+0x6a2>
ffffffffc020127c:	0889b783          	ld	a5,136(s3)
ffffffffc0201280:	8385                	srli	a5,a5,0x1
ffffffffc0201282:	8b85                	andi	a5,a5,1
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0201284:	48078e63          	beqz	a5,ffffffffc0201720 <default_check+0x682>
ffffffffc0201288:	0909a703          	lw	a4,144(s3)
ffffffffc020128c:	478d                	li	a5,3
ffffffffc020128e:	48f71963          	bne	a4,a5,ffffffffc0201720 <default_check+0x682>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0201292:	450d                	li	a0,3
ffffffffc0201294:	4ad000ef          	jal	ra,ffffffffc0201f40 <alloc_pages>
ffffffffc0201298:	8c2a                	mv	s8,a0
ffffffffc020129a:	46050363          	beqz	a0,ffffffffc0201700 <default_check+0x662>
    assert(alloc_page() == NULL);
ffffffffc020129e:	4505                	li	a0,1
ffffffffc02012a0:	4a1000ef          	jal	ra,ffffffffc0201f40 <alloc_pages>
ffffffffc02012a4:	42051e63          	bnez	a0,ffffffffc02016e0 <default_check+0x642>
    assert(p0 + 2 == p1);
ffffffffc02012a8:	418a1c63          	bne	s4,s8,ffffffffc02016c0 <default_check+0x622>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc02012ac:	4585                	li	a1,1
ffffffffc02012ae:	854e                	mv	a0,s3
ffffffffc02012b0:	4cf000ef          	jal	ra,ffffffffc0201f7e <free_pages>
    free_pages(p1, 3);
ffffffffc02012b4:	458d                	li	a1,3
ffffffffc02012b6:	8552                	mv	a0,s4
ffffffffc02012b8:	4c7000ef          	jal	ra,ffffffffc0201f7e <free_pages>
ffffffffc02012bc:	0089b783          	ld	a5,8(s3)
    p2 = p0 + 1;
ffffffffc02012c0:	04098c13          	addi	s8,s3,64
ffffffffc02012c4:	8385                	srli	a5,a5,0x1
ffffffffc02012c6:	8b85                	andi	a5,a5,1
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc02012c8:	3c078c63          	beqz	a5,ffffffffc02016a0 <default_check+0x602>
ffffffffc02012cc:	0109a703          	lw	a4,16(s3)
ffffffffc02012d0:	4785                	li	a5,1
ffffffffc02012d2:	3cf71763          	bne	a4,a5,ffffffffc02016a0 <default_check+0x602>
ffffffffc02012d6:	008a3783          	ld	a5,8(s4)
ffffffffc02012da:	8385                	srli	a5,a5,0x1
ffffffffc02012dc:	8b85                	andi	a5,a5,1
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc02012de:	3a078163          	beqz	a5,ffffffffc0201680 <default_check+0x5e2>
ffffffffc02012e2:	010a2703          	lw	a4,16(s4)
ffffffffc02012e6:	478d                	li	a5,3
ffffffffc02012e8:	38f71c63          	bne	a4,a5,ffffffffc0201680 <default_check+0x5e2>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc02012ec:	4505                	li	a0,1
ffffffffc02012ee:	453000ef          	jal	ra,ffffffffc0201f40 <alloc_pages>
ffffffffc02012f2:	36a99763          	bne	s3,a0,ffffffffc0201660 <default_check+0x5c2>
    free_page(p0);
ffffffffc02012f6:	4585                	li	a1,1
ffffffffc02012f8:	487000ef          	jal	ra,ffffffffc0201f7e <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc02012fc:	4509                	li	a0,2
ffffffffc02012fe:	443000ef          	jal	ra,ffffffffc0201f40 <alloc_pages>
ffffffffc0201302:	32aa1f63          	bne	s4,a0,ffffffffc0201640 <default_check+0x5a2>

    free_pages(p0, 2);
ffffffffc0201306:	4589                	li	a1,2
ffffffffc0201308:	477000ef          	jal	ra,ffffffffc0201f7e <free_pages>
    free_page(p2);
ffffffffc020130c:	4585                	li	a1,1
ffffffffc020130e:	8562                	mv	a0,s8
ffffffffc0201310:	46f000ef          	jal	ra,ffffffffc0201f7e <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0201314:	4515                	li	a0,5
ffffffffc0201316:	42b000ef          	jal	ra,ffffffffc0201f40 <alloc_pages>
ffffffffc020131a:	89aa                	mv	s3,a0
ffffffffc020131c:	48050263          	beqz	a0,ffffffffc02017a0 <default_check+0x702>
    assert(alloc_page() == NULL);
ffffffffc0201320:	4505                	li	a0,1
ffffffffc0201322:	41f000ef          	jal	ra,ffffffffc0201f40 <alloc_pages>
ffffffffc0201326:	2c051d63          	bnez	a0,ffffffffc0201600 <default_check+0x562>

    assert(nr_free == 0);
ffffffffc020132a:	481c                	lw	a5,16(s0)
ffffffffc020132c:	2a079a63          	bnez	a5,ffffffffc02015e0 <default_check+0x542>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc0201330:	4595                	li	a1,5
ffffffffc0201332:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc0201334:	01742823          	sw	s7,16(s0)
    free_list = free_list_store;
ffffffffc0201338:	01643023          	sd	s6,0(s0)
ffffffffc020133c:	01543423          	sd	s5,8(s0)
    free_pages(p0, 5);
ffffffffc0201340:	43f000ef          	jal	ra,ffffffffc0201f7e <free_pages>
    return listelm->next;
ffffffffc0201344:	641c                	ld	a5,8(s0)

    le = &free_list;
    while ((le = list_next(le)) != &free_list)
ffffffffc0201346:	00878963          	beq	a5,s0,ffffffffc0201358 <default_check+0x2ba>
    {
        struct Page *p = le2page(le, page_link);
        count--, total -= p->property;
ffffffffc020134a:	ff87a703          	lw	a4,-8(a5)
ffffffffc020134e:	679c                	ld	a5,8(a5)
ffffffffc0201350:	397d                	addiw	s2,s2,-1
ffffffffc0201352:	9c99                	subw	s1,s1,a4
    while ((le = list_next(le)) != &free_list)
ffffffffc0201354:	fe879be3          	bne	a5,s0,ffffffffc020134a <default_check+0x2ac>
    }
    assert(count == 0);
ffffffffc0201358:	26091463          	bnez	s2,ffffffffc02015c0 <default_check+0x522>
    assert(total == 0);
ffffffffc020135c:	46049263          	bnez	s1,ffffffffc02017c0 <default_check+0x722>
}
ffffffffc0201360:	60a6                	ld	ra,72(sp)
ffffffffc0201362:	6406                	ld	s0,64(sp)
ffffffffc0201364:	74e2                	ld	s1,56(sp)
ffffffffc0201366:	7942                	ld	s2,48(sp)
ffffffffc0201368:	79a2                	ld	s3,40(sp)
ffffffffc020136a:	7a02                	ld	s4,32(sp)
ffffffffc020136c:	6ae2                	ld	s5,24(sp)
ffffffffc020136e:	6b42                	ld	s6,16(sp)
ffffffffc0201370:	6ba2                	ld	s7,8(sp)
ffffffffc0201372:	6c02                	ld	s8,0(sp)
ffffffffc0201374:	6161                	addi	sp,sp,80
ffffffffc0201376:	8082                	ret
    while ((le = list_next(le)) != &free_list)
ffffffffc0201378:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc020137a:	4481                	li	s1,0
ffffffffc020137c:	4901                	li	s2,0
ffffffffc020137e:	b38d                	j	ffffffffc02010e0 <default_check+0x42>
        assert(PageProperty(p));
ffffffffc0201380:	00005697          	auipc	a3,0x5
ffffffffc0201384:	ef068693          	addi	a3,a3,-272 # ffffffffc0206270 <commands+0x858>
ffffffffc0201388:	00005617          	auipc	a2,0x5
ffffffffc020138c:	ef860613          	addi	a2,a2,-264 # ffffffffc0206280 <commands+0x868>
ffffffffc0201390:	11000593          	li	a1,272
ffffffffc0201394:	00005517          	auipc	a0,0x5
ffffffffc0201398:	f0450513          	addi	a0,a0,-252 # ffffffffc0206298 <commands+0x880>
ffffffffc020139c:	8f2ff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc02013a0:	00005697          	auipc	a3,0x5
ffffffffc02013a4:	f9068693          	addi	a3,a3,-112 # ffffffffc0206330 <commands+0x918>
ffffffffc02013a8:	00005617          	auipc	a2,0x5
ffffffffc02013ac:	ed860613          	addi	a2,a2,-296 # ffffffffc0206280 <commands+0x868>
ffffffffc02013b0:	0db00593          	li	a1,219
ffffffffc02013b4:	00005517          	auipc	a0,0x5
ffffffffc02013b8:	ee450513          	addi	a0,a0,-284 # ffffffffc0206298 <commands+0x880>
ffffffffc02013bc:	8d2ff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc02013c0:	00005697          	auipc	a3,0x5
ffffffffc02013c4:	f9868693          	addi	a3,a3,-104 # ffffffffc0206358 <commands+0x940>
ffffffffc02013c8:	00005617          	auipc	a2,0x5
ffffffffc02013cc:	eb860613          	addi	a2,a2,-328 # ffffffffc0206280 <commands+0x868>
ffffffffc02013d0:	0dc00593          	li	a1,220
ffffffffc02013d4:	00005517          	auipc	a0,0x5
ffffffffc02013d8:	ec450513          	addi	a0,a0,-316 # ffffffffc0206298 <commands+0x880>
ffffffffc02013dc:	8b2ff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc02013e0:	00005697          	auipc	a3,0x5
ffffffffc02013e4:	fb868693          	addi	a3,a3,-72 # ffffffffc0206398 <commands+0x980>
ffffffffc02013e8:	00005617          	auipc	a2,0x5
ffffffffc02013ec:	e9860613          	addi	a2,a2,-360 # ffffffffc0206280 <commands+0x868>
ffffffffc02013f0:	0de00593          	li	a1,222
ffffffffc02013f4:	00005517          	auipc	a0,0x5
ffffffffc02013f8:	ea450513          	addi	a0,a0,-348 # ffffffffc0206298 <commands+0x880>
ffffffffc02013fc:	892ff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(!list_empty(&free_list));
ffffffffc0201400:	00005697          	auipc	a3,0x5
ffffffffc0201404:	02068693          	addi	a3,a3,32 # ffffffffc0206420 <commands+0xa08>
ffffffffc0201408:	00005617          	auipc	a2,0x5
ffffffffc020140c:	e7860613          	addi	a2,a2,-392 # ffffffffc0206280 <commands+0x868>
ffffffffc0201410:	0f700593          	li	a1,247
ffffffffc0201414:	00005517          	auipc	a0,0x5
ffffffffc0201418:	e8450513          	addi	a0,a0,-380 # ffffffffc0206298 <commands+0x880>
ffffffffc020141c:	872ff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201420:	00005697          	auipc	a3,0x5
ffffffffc0201424:	eb068693          	addi	a3,a3,-336 # ffffffffc02062d0 <commands+0x8b8>
ffffffffc0201428:	00005617          	auipc	a2,0x5
ffffffffc020142c:	e5860613          	addi	a2,a2,-424 # ffffffffc0206280 <commands+0x868>
ffffffffc0201430:	0f000593          	li	a1,240
ffffffffc0201434:	00005517          	auipc	a0,0x5
ffffffffc0201438:	e6450513          	addi	a0,a0,-412 # ffffffffc0206298 <commands+0x880>
ffffffffc020143c:	852ff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_free == 3);
ffffffffc0201440:	00005697          	auipc	a3,0x5
ffffffffc0201444:	fd068693          	addi	a3,a3,-48 # ffffffffc0206410 <commands+0x9f8>
ffffffffc0201448:	00005617          	auipc	a2,0x5
ffffffffc020144c:	e3860613          	addi	a2,a2,-456 # ffffffffc0206280 <commands+0x868>
ffffffffc0201450:	0ee00593          	li	a1,238
ffffffffc0201454:	00005517          	auipc	a0,0x5
ffffffffc0201458:	e4450513          	addi	a0,a0,-444 # ffffffffc0206298 <commands+0x880>
ffffffffc020145c:	832ff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201460:	00005697          	auipc	a3,0x5
ffffffffc0201464:	f9868693          	addi	a3,a3,-104 # ffffffffc02063f8 <commands+0x9e0>
ffffffffc0201468:	00005617          	auipc	a2,0x5
ffffffffc020146c:	e1860613          	addi	a2,a2,-488 # ffffffffc0206280 <commands+0x868>
ffffffffc0201470:	0e900593          	li	a1,233
ffffffffc0201474:	00005517          	auipc	a0,0x5
ffffffffc0201478:	e2450513          	addi	a0,a0,-476 # ffffffffc0206298 <commands+0x880>
ffffffffc020147c:	812ff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0201480:	00005697          	auipc	a3,0x5
ffffffffc0201484:	f5868693          	addi	a3,a3,-168 # ffffffffc02063d8 <commands+0x9c0>
ffffffffc0201488:	00005617          	auipc	a2,0x5
ffffffffc020148c:	df860613          	addi	a2,a2,-520 # ffffffffc0206280 <commands+0x868>
ffffffffc0201490:	0e000593          	li	a1,224
ffffffffc0201494:	00005517          	auipc	a0,0x5
ffffffffc0201498:	e0450513          	addi	a0,a0,-508 # ffffffffc0206298 <commands+0x880>
ffffffffc020149c:	ff3fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(p0 != NULL);
ffffffffc02014a0:	00005697          	auipc	a3,0x5
ffffffffc02014a4:	fc868693          	addi	a3,a3,-56 # ffffffffc0206468 <commands+0xa50>
ffffffffc02014a8:	00005617          	auipc	a2,0x5
ffffffffc02014ac:	dd860613          	addi	a2,a2,-552 # ffffffffc0206280 <commands+0x868>
ffffffffc02014b0:	11800593          	li	a1,280
ffffffffc02014b4:	00005517          	auipc	a0,0x5
ffffffffc02014b8:	de450513          	addi	a0,a0,-540 # ffffffffc0206298 <commands+0x880>
ffffffffc02014bc:	fd3fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_free == 0);
ffffffffc02014c0:	00005697          	auipc	a3,0x5
ffffffffc02014c4:	f9868693          	addi	a3,a3,-104 # ffffffffc0206458 <commands+0xa40>
ffffffffc02014c8:	00005617          	auipc	a2,0x5
ffffffffc02014cc:	db860613          	addi	a2,a2,-584 # ffffffffc0206280 <commands+0x868>
ffffffffc02014d0:	0fd00593          	li	a1,253
ffffffffc02014d4:	00005517          	auipc	a0,0x5
ffffffffc02014d8:	dc450513          	addi	a0,a0,-572 # ffffffffc0206298 <commands+0x880>
ffffffffc02014dc:	fb3fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc02014e0:	00005697          	auipc	a3,0x5
ffffffffc02014e4:	f1868693          	addi	a3,a3,-232 # ffffffffc02063f8 <commands+0x9e0>
ffffffffc02014e8:	00005617          	auipc	a2,0x5
ffffffffc02014ec:	d9860613          	addi	a2,a2,-616 # ffffffffc0206280 <commands+0x868>
ffffffffc02014f0:	0fb00593          	li	a1,251
ffffffffc02014f4:	00005517          	auipc	a0,0x5
ffffffffc02014f8:	da450513          	addi	a0,a0,-604 # ffffffffc0206298 <commands+0x880>
ffffffffc02014fc:	f93fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc0201500:	00005697          	auipc	a3,0x5
ffffffffc0201504:	f3868693          	addi	a3,a3,-200 # ffffffffc0206438 <commands+0xa20>
ffffffffc0201508:	00005617          	auipc	a2,0x5
ffffffffc020150c:	d7860613          	addi	a2,a2,-648 # ffffffffc0206280 <commands+0x868>
ffffffffc0201510:	0fa00593          	li	a1,250
ffffffffc0201514:	00005517          	auipc	a0,0x5
ffffffffc0201518:	d8450513          	addi	a0,a0,-636 # ffffffffc0206298 <commands+0x880>
ffffffffc020151c:	f73fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201520:	00005697          	auipc	a3,0x5
ffffffffc0201524:	db068693          	addi	a3,a3,-592 # ffffffffc02062d0 <commands+0x8b8>
ffffffffc0201528:	00005617          	auipc	a2,0x5
ffffffffc020152c:	d5860613          	addi	a2,a2,-680 # ffffffffc0206280 <commands+0x868>
ffffffffc0201530:	0d700593          	li	a1,215
ffffffffc0201534:	00005517          	auipc	a0,0x5
ffffffffc0201538:	d6450513          	addi	a0,a0,-668 # ffffffffc0206298 <commands+0x880>
ffffffffc020153c:	f53fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201540:	00005697          	auipc	a3,0x5
ffffffffc0201544:	eb868693          	addi	a3,a3,-328 # ffffffffc02063f8 <commands+0x9e0>
ffffffffc0201548:	00005617          	auipc	a2,0x5
ffffffffc020154c:	d3860613          	addi	a2,a2,-712 # ffffffffc0206280 <commands+0x868>
ffffffffc0201550:	0f400593          	li	a1,244
ffffffffc0201554:	00005517          	auipc	a0,0x5
ffffffffc0201558:	d4450513          	addi	a0,a0,-700 # ffffffffc0206298 <commands+0x880>
ffffffffc020155c:	f33fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201560:	00005697          	auipc	a3,0x5
ffffffffc0201564:	db068693          	addi	a3,a3,-592 # ffffffffc0206310 <commands+0x8f8>
ffffffffc0201568:	00005617          	auipc	a2,0x5
ffffffffc020156c:	d1860613          	addi	a2,a2,-744 # ffffffffc0206280 <commands+0x868>
ffffffffc0201570:	0f200593          	li	a1,242
ffffffffc0201574:	00005517          	auipc	a0,0x5
ffffffffc0201578:	d2450513          	addi	a0,a0,-732 # ffffffffc0206298 <commands+0x880>
ffffffffc020157c:	f13fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201580:	00005697          	auipc	a3,0x5
ffffffffc0201584:	d7068693          	addi	a3,a3,-656 # ffffffffc02062f0 <commands+0x8d8>
ffffffffc0201588:	00005617          	auipc	a2,0x5
ffffffffc020158c:	cf860613          	addi	a2,a2,-776 # ffffffffc0206280 <commands+0x868>
ffffffffc0201590:	0f100593          	li	a1,241
ffffffffc0201594:	00005517          	auipc	a0,0x5
ffffffffc0201598:	d0450513          	addi	a0,a0,-764 # ffffffffc0206298 <commands+0x880>
ffffffffc020159c:	ef3fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02015a0:	00005697          	auipc	a3,0x5
ffffffffc02015a4:	d7068693          	addi	a3,a3,-656 # ffffffffc0206310 <commands+0x8f8>
ffffffffc02015a8:	00005617          	auipc	a2,0x5
ffffffffc02015ac:	cd860613          	addi	a2,a2,-808 # ffffffffc0206280 <commands+0x868>
ffffffffc02015b0:	0d900593          	li	a1,217
ffffffffc02015b4:	00005517          	auipc	a0,0x5
ffffffffc02015b8:	ce450513          	addi	a0,a0,-796 # ffffffffc0206298 <commands+0x880>
ffffffffc02015bc:	ed3fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(count == 0);
ffffffffc02015c0:	00005697          	auipc	a3,0x5
ffffffffc02015c4:	ff868693          	addi	a3,a3,-8 # ffffffffc02065b8 <commands+0xba0>
ffffffffc02015c8:	00005617          	auipc	a2,0x5
ffffffffc02015cc:	cb860613          	addi	a2,a2,-840 # ffffffffc0206280 <commands+0x868>
ffffffffc02015d0:	14600593          	li	a1,326
ffffffffc02015d4:	00005517          	auipc	a0,0x5
ffffffffc02015d8:	cc450513          	addi	a0,a0,-828 # ffffffffc0206298 <commands+0x880>
ffffffffc02015dc:	eb3fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_free == 0);
ffffffffc02015e0:	00005697          	auipc	a3,0x5
ffffffffc02015e4:	e7868693          	addi	a3,a3,-392 # ffffffffc0206458 <commands+0xa40>
ffffffffc02015e8:	00005617          	auipc	a2,0x5
ffffffffc02015ec:	c9860613          	addi	a2,a2,-872 # ffffffffc0206280 <commands+0x868>
ffffffffc02015f0:	13a00593          	li	a1,314
ffffffffc02015f4:	00005517          	auipc	a0,0x5
ffffffffc02015f8:	ca450513          	addi	a0,a0,-860 # ffffffffc0206298 <commands+0x880>
ffffffffc02015fc:	e93fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201600:	00005697          	auipc	a3,0x5
ffffffffc0201604:	df868693          	addi	a3,a3,-520 # ffffffffc02063f8 <commands+0x9e0>
ffffffffc0201608:	00005617          	auipc	a2,0x5
ffffffffc020160c:	c7860613          	addi	a2,a2,-904 # ffffffffc0206280 <commands+0x868>
ffffffffc0201610:	13800593          	li	a1,312
ffffffffc0201614:	00005517          	auipc	a0,0x5
ffffffffc0201618:	c8450513          	addi	a0,a0,-892 # ffffffffc0206298 <commands+0x880>
ffffffffc020161c:	e73fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0201620:	00005697          	auipc	a3,0x5
ffffffffc0201624:	d9868693          	addi	a3,a3,-616 # ffffffffc02063b8 <commands+0x9a0>
ffffffffc0201628:	00005617          	auipc	a2,0x5
ffffffffc020162c:	c5860613          	addi	a2,a2,-936 # ffffffffc0206280 <commands+0x868>
ffffffffc0201630:	0df00593          	li	a1,223
ffffffffc0201634:	00005517          	auipc	a0,0x5
ffffffffc0201638:	c6450513          	addi	a0,a0,-924 # ffffffffc0206298 <commands+0x880>
ffffffffc020163c:	e53fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0201640:	00005697          	auipc	a3,0x5
ffffffffc0201644:	f3868693          	addi	a3,a3,-200 # ffffffffc0206578 <commands+0xb60>
ffffffffc0201648:	00005617          	auipc	a2,0x5
ffffffffc020164c:	c3860613          	addi	a2,a2,-968 # ffffffffc0206280 <commands+0x868>
ffffffffc0201650:	13200593          	li	a1,306
ffffffffc0201654:	00005517          	auipc	a0,0x5
ffffffffc0201658:	c4450513          	addi	a0,a0,-956 # ffffffffc0206298 <commands+0x880>
ffffffffc020165c:	e33fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0201660:	00005697          	auipc	a3,0x5
ffffffffc0201664:	ef868693          	addi	a3,a3,-264 # ffffffffc0206558 <commands+0xb40>
ffffffffc0201668:	00005617          	auipc	a2,0x5
ffffffffc020166c:	c1860613          	addi	a2,a2,-1000 # ffffffffc0206280 <commands+0x868>
ffffffffc0201670:	13000593          	li	a1,304
ffffffffc0201674:	00005517          	auipc	a0,0x5
ffffffffc0201678:	c2450513          	addi	a0,a0,-988 # ffffffffc0206298 <commands+0x880>
ffffffffc020167c:	e13fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0201680:	00005697          	auipc	a3,0x5
ffffffffc0201684:	eb068693          	addi	a3,a3,-336 # ffffffffc0206530 <commands+0xb18>
ffffffffc0201688:	00005617          	auipc	a2,0x5
ffffffffc020168c:	bf860613          	addi	a2,a2,-1032 # ffffffffc0206280 <commands+0x868>
ffffffffc0201690:	12e00593          	li	a1,302
ffffffffc0201694:	00005517          	auipc	a0,0x5
ffffffffc0201698:	c0450513          	addi	a0,a0,-1020 # ffffffffc0206298 <commands+0x880>
ffffffffc020169c:	df3fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc02016a0:	00005697          	auipc	a3,0x5
ffffffffc02016a4:	e6868693          	addi	a3,a3,-408 # ffffffffc0206508 <commands+0xaf0>
ffffffffc02016a8:	00005617          	auipc	a2,0x5
ffffffffc02016ac:	bd860613          	addi	a2,a2,-1064 # ffffffffc0206280 <commands+0x868>
ffffffffc02016b0:	12d00593          	li	a1,301
ffffffffc02016b4:	00005517          	auipc	a0,0x5
ffffffffc02016b8:	be450513          	addi	a0,a0,-1052 # ffffffffc0206298 <commands+0x880>
ffffffffc02016bc:	dd3fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(p0 + 2 == p1);
ffffffffc02016c0:	00005697          	auipc	a3,0x5
ffffffffc02016c4:	e3868693          	addi	a3,a3,-456 # ffffffffc02064f8 <commands+0xae0>
ffffffffc02016c8:	00005617          	auipc	a2,0x5
ffffffffc02016cc:	bb860613          	addi	a2,a2,-1096 # ffffffffc0206280 <commands+0x868>
ffffffffc02016d0:	12800593          	li	a1,296
ffffffffc02016d4:	00005517          	auipc	a0,0x5
ffffffffc02016d8:	bc450513          	addi	a0,a0,-1084 # ffffffffc0206298 <commands+0x880>
ffffffffc02016dc:	db3fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc02016e0:	00005697          	auipc	a3,0x5
ffffffffc02016e4:	d1868693          	addi	a3,a3,-744 # ffffffffc02063f8 <commands+0x9e0>
ffffffffc02016e8:	00005617          	auipc	a2,0x5
ffffffffc02016ec:	b9860613          	addi	a2,a2,-1128 # ffffffffc0206280 <commands+0x868>
ffffffffc02016f0:	12700593          	li	a1,295
ffffffffc02016f4:	00005517          	auipc	a0,0x5
ffffffffc02016f8:	ba450513          	addi	a0,a0,-1116 # ffffffffc0206298 <commands+0x880>
ffffffffc02016fc:	d93fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0201700:	00005697          	auipc	a3,0x5
ffffffffc0201704:	dd868693          	addi	a3,a3,-552 # ffffffffc02064d8 <commands+0xac0>
ffffffffc0201708:	00005617          	auipc	a2,0x5
ffffffffc020170c:	b7860613          	addi	a2,a2,-1160 # ffffffffc0206280 <commands+0x868>
ffffffffc0201710:	12600593          	li	a1,294
ffffffffc0201714:	00005517          	auipc	a0,0x5
ffffffffc0201718:	b8450513          	addi	a0,a0,-1148 # ffffffffc0206298 <commands+0x880>
ffffffffc020171c:	d73fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0201720:	00005697          	auipc	a3,0x5
ffffffffc0201724:	d8868693          	addi	a3,a3,-632 # ffffffffc02064a8 <commands+0xa90>
ffffffffc0201728:	00005617          	auipc	a2,0x5
ffffffffc020172c:	b5860613          	addi	a2,a2,-1192 # ffffffffc0206280 <commands+0x868>
ffffffffc0201730:	12500593          	li	a1,293
ffffffffc0201734:	00005517          	auipc	a0,0x5
ffffffffc0201738:	b6450513          	addi	a0,a0,-1180 # ffffffffc0206298 <commands+0x880>
ffffffffc020173c:	d53fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc0201740:	00005697          	auipc	a3,0x5
ffffffffc0201744:	d5068693          	addi	a3,a3,-688 # ffffffffc0206490 <commands+0xa78>
ffffffffc0201748:	00005617          	auipc	a2,0x5
ffffffffc020174c:	b3860613          	addi	a2,a2,-1224 # ffffffffc0206280 <commands+0x868>
ffffffffc0201750:	12400593          	li	a1,292
ffffffffc0201754:	00005517          	auipc	a0,0x5
ffffffffc0201758:	b4450513          	addi	a0,a0,-1212 # ffffffffc0206298 <commands+0x880>
ffffffffc020175c:	d33fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201760:	00005697          	auipc	a3,0x5
ffffffffc0201764:	c9868693          	addi	a3,a3,-872 # ffffffffc02063f8 <commands+0x9e0>
ffffffffc0201768:	00005617          	auipc	a2,0x5
ffffffffc020176c:	b1860613          	addi	a2,a2,-1256 # ffffffffc0206280 <commands+0x868>
ffffffffc0201770:	11e00593          	li	a1,286
ffffffffc0201774:	00005517          	auipc	a0,0x5
ffffffffc0201778:	b2450513          	addi	a0,a0,-1244 # ffffffffc0206298 <commands+0x880>
ffffffffc020177c:	d13fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(!PageProperty(p0));
ffffffffc0201780:	00005697          	auipc	a3,0x5
ffffffffc0201784:	cf868693          	addi	a3,a3,-776 # ffffffffc0206478 <commands+0xa60>
ffffffffc0201788:	00005617          	auipc	a2,0x5
ffffffffc020178c:	af860613          	addi	a2,a2,-1288 # ffffffffc0206280 <commands+0x868>
ffffffffc0201790:	11900593          	li	a1,281
ffffffffc0201794:	00005517          	auipc	a0,0x5
ffffffffc0201798:	b0450513          	addi	a0,a0,-1276 # ffffffffc0206298 <commands+0x880>
ffffffffc020179c:	cf3fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc02017a0:	00005697          	auipc	a3,0x5
ffffffffc02017a4:	df868693          	addi	a3,a3,-520 # ffffffffc0206598 <commands+0xb80>
ffffffffc02017a8:	00005617          	auipc	a2,0x5
ffffffffc02017ac:	ad860613          	addi	a2,a2,-1320 # ffffffffc0206280 <commands+0x868>
ffffffffc02017b0:	13700593          	li	a1,311
ffffffffc02017b4:	00005517          	auipc	a0,0x5
ffffffffc02017b8:	ae450513          	addi	a0,a0,-1308 # ffffffffc0206298 <commands+0x880>
ffffffffc02017bc:	cd3fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(total == 0);
ffffffffc02017c0:	00005697          	auipc	a3,0x5
ffffffffc02017c4:	e0868693          	addi	a3,a3,-504 # ffffffffc02065c8 <commands+0xbb0>
ffffffffc02017c8:	00005617          	auipc	a2,0x5
ffffffffc02017cc:	ab860613          	addi	a2,a2,-1352 # ffffffffc0206280 <commands+0x868>
ffffffffc02017d0:	14700593          	li	a1,327
ffffffffc02017d4:	00005517          	auipc	a0,0x5
ffffffffc02017d8:	ac450513          	addi	a0,a0,-1340 # ffffffffc0206298 <commands+0x880>
ffffffffc02017dc:	cb3fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(total == nr_free_pages());
ffffffffc02017e0:	00005697          	auipc	a3,0x5
ffffffffc02017e4:	ad068693          	addi	a3,a3,-1328 # ffffffffc02062b0 <commands+0x898>
ffffffffc02017e8:	00005617          	auipc	a2,0x5
ffffffffc02017ec:	a9860613          	addi	a2,a2,-1384 # ffffffffc0206280 <commands+0x868>
ffffffffc02017f0:	11300593          	li	a1,275
ffffffffc02017f4:	00005517          	auipc	a0,0x5
ffffffffc02017f8:	aa450513          	addi	a0,a0,-1372 # ffffffffc0206298 <commands+0x880>
ffffffffc02017fc:	c93fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201800:	00005697          	auipc	a3,0x5
ffffffffc0201804:	af068693          	addi	a3,a3,-1296 # ffffffffc02062f0 <commands+0x8d8>
ffffffffc0201808:	00005617          	auipc	a2,0x5
ffffffffc020180c:	a7860613          	addi	a2,a2,-1416 # ffffffffc0206280 <commands+0x868>
ffffffffc0201810:	0d800593          	li	a1,216
ffffffffc0201814:	00005517          	auipc	a0,0x5
ffffffffc0201818:	a8450513          	addi	a0,a0,-1404 # ffffffffc0206298 <commands+0x880>
ffffffffc020181c:	c73fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201820 <default_free_pages>:
{
ffffffffc0201820:	1141                	addi	sp,sp,-16
ffffffffc0201822:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201824:	14058463          	beqz	a1,ffffffffc020196c <default_free_pages+0x14c>
    for (; p != base + n; p++)
ffffffffc0201828:	00659693          	slli	a3,a1,0x6
ffffffffc020182c:	96aa                	add	a3,a3,a0
ffffffffc020182e:	87aa                	mv	a5,a0
ffffffffc0201830:	02d50263          	beq	a0,a3,ffffffffc0201854 <default_free_pages+0x34>
ffffffffc0201834:	6798                	ld	a4,8(a5)
ffffffffc0201836:	8b05                	andi	a4,a4,1
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0201838:	10071a63          	bnez	a4,ffffffffc020194c <default_free_pages+0x12c>
ffffffffc020183c:	6798                	ld	a4,8(a5)
ffffffffc020183e:	8b09                	andi	a4,a4,2
ffffffffc0201840:	10071663          	bnez	a4,ffffffffc020194c <default_free_pages+0x12c>
        p->flags = 0;
ffffffffc0201844:	0007b423          	sd	zero,8(a5)
}

static inline void
set_page_ref(struct Page *page, int val)
{
    page->ref = val;
ffffffffc0201848:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p++)
ffffffffc020184c:	04078793          	addi	a5,a5,64
ffffffffc0201850:	fed792e3          	bne	a5,a3,ffffffffc0201834 <default_free_pages+0x14>
    base->property = n;
ffffffffc0201854:	2581                	sext.w	a1,a1
ffffffffc0201856:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc0201858:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc020185c:	4789                	li	a5,2
ffffffffc020185e:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc0201862:	000a5697          	auipc	a3,0xa5
ffffffffc0201866:	00e68693          	addi	a3,a3,14 # ffffffffc02a6870 <free_area>
ffffffffc020186a:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc020186c:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc020186e:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc0201872:	9db9                	addw	a1,a1,a4
ffffffffc0201874:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list))
ffffffffc0201876:	0ad78463          	beq	a5,a3,ffffffffc020191e <default_free_pages+0xfe>
            struct Page *page = le2page(le, page_link);
ffffffffc020187a:	fe878713          	addi	a4,a5,-24
ffffffffc020187e:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list))
ffffffffc0201882:	4581                	li	a1,0
            if (base < page)
ffffffffc0201884:	00e56a63          	bltu	a0,a4,ffffffffc0201898 <default_free_pages+0x78>
    return listelm->next;
ffffffffc0201888:	6798                	ld	a4,8(a5)
            else if (list_next(le) == &free_list)
ffffffffc020188a:	04d70c63          	beq	a4,a3,ffffffffc02018e2 <default_free_pages+0xc2>
    for (; p != base + n; p++)
ffffffffc020188e:	87ba                	mv	a5,a4
            struct Page *page = le2page(le, page_link);
ffffffffc0201890:	fe878713          	addi	a4,a5,-24
            if (base < page)
ffffffffc0201894:	fee57ae3          	bgeu	a0,a4,ffffffffc0201888 <default_free_pages+0x68>
ffffffffc0201898:	c199                	beqz	a1,ffffffffc020189e <default_free_pages+0x7e>
ffffffffc020189a:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc020189e:	6398                	ld	a4,0(a5)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc02018a0:	e390                	sd	a2,0(a5)
ffffffffc02018a2:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc02018a4:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02018a6:	ed18                	sd	a4,24(a0)
    if (le != &free_list)
ffffffffc02018a8:	00d70d63          	beq	a4,a3,ffffffffc02018c2 <default_free_pages+0xa2>
        if (p + p->property == base)
ffffffffc02018ac:	ff872583          	lw	a1,-8(a4)
        p = le2page(le, page_link);
ffffffffc02018b0:	fe870613          	addi	a2,a4,-24
        if (p + p->property == base)
ffffffffc02018b4:	02059813          	slli	a6,a1,0x20
ffffffffc02018b8:	01a85793          	srli	a5,a6,0x1a
ffffffffc02018bc:	97b2                	add	a5,a5,a2
ffffffffc02018be:	02f50c63          	beq	a0,a5,ffffffffc02018f6 <default_free_pages+0xd6>
    return listelm->next;
ffffffffc02018c2:	711c                	ld	a5,32(a0)
    if (le != &free_list)
ffffffffc02018c4:	00d78c63          	beq	a5,a3,ffffffffc02018dc <default_free_pages+0xbc>
        if (base + base->property == p)
ffffffffc02018c8:	4910                	lw	a2,16(a0)
        p = le2page(le, page_link);
ffffffffc02018ca:	fe878693          	addi	a3,a5,-24
        if (base + base->property == p)
ffffffffc02018ce:	02061593          	slli	a1,a2,0x20
ffffffffc02018d2:	01a5d713          	srli	a4,a1,0x1a
ffffffffc02018d6:	972a                	add	a4,a4,a0
ffffffffc02018d8:	04e68a63          	beq	a3,a4,ffffffffc020192c <default_free_pages+0x10c>
}
ffffffffc02018dc:	60a2                	ld	ra,8(sp)
ffffffffc02018de:	0141                	addi	sp,sp,16
ffffffffc02018e0:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc02018e2:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02018e4:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc02018e6:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc02018e8:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list)
ffffffffc02018ea:	02d70763          	beq	a4,a3,ffffffffc0201918 <default_free_pages+0xf8>
    prev->next = next->prev = elm;
ffffffffc02018ee:	8832                	mv	a6,a2
ffffffffc02018f0:	4585                	li	a1,1
    for (; p != base + n; p++)
ffffffffc02018f2:	87ba                	mv	a5,a4
ffffffffc02018f4:	bf71                	j	ffffffffc0201890 <default_free_pages+0x70>
            p->property += base->property;
ffffffffc02018f6:	491c                	lw	a5,16(a0)
ffffffffc02018f8:	9dbd                	addw	a1,a1,a5
ffffffffc02018fa:	feb72c23          	sw	a1,-8(a4)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc02018fe:	57f5                	li	a5,-3
ffffffffc0201900:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201904:	01853803          	ld	a6,24(a0)
ffffffffc0201908:	710c                	ld	a1,32(a0)
            base = p;
ffffffffc020190a:	8532                	mv	a0,a2
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc020190c:	00b83423          	sd	a1,8(a6)
    return listelm->next;
ffffffffc0201910:	671c                	ld	a5,8(a4)
    next->prev = prev;
ffffffffc0201912:	0105b023          	sd	a6,0(a1)
ffffffffc0201916:	b77d                	j	ffffffffc02018c4 <default_free_pages+0xa4>
ffffffffc0201918:	e290                	sd	a2,0(a3)
        while ((le = list_next(le)) != &free_list)
ffffffffc020191a:	873e                	mv	a4,a5
ffffffffc020191c:	bf41                	j	ffffffffc02018ac <default_free_pages+0x8c>
}
ffffffffc020191e:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0201920:	e390                	sd	a2,0(a5)
ffffffffc0201922:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201924:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201926:	ed1c                	sd	a5,24(a0)
ffffffffc0201928:	0141                	addi	sp,sp,16
ffffffffc020192a:	8082                	ret
            base->property += p->property;
ffffffffc020192c:	ff87a703          	lw	a4,-8(a5)
ffffffffc0201930:	ff078693          	addi	a3,a5,-16
ffffffffc0201934:	9e39                	addw	a2,a2,a4
ffffffffc0201936:	c910                	sw	a2,16(a0)
ffffffffc0201938:	5775                	li	a4,-3
ffffffffc020193a:	60e6b02f          	amoand.d	zero,a4,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc020193e:	6398                	ld	a4,0(a5)
ffffffffc0201940:	679c                	ld	a5,8(a5)
}
ffffffffc0201942:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc0201944:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0201946:	e398                	sd	a4,0(a5)
ffffffffc0201948:	0141                	addi	sp,sp,16
ffffffffc020194a:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc020194c:	00005697          	auipc	a3,0x5
ffffffffc0201950:	c9468693          	addi	a3,a3,-876 # ffffffffc02065e0 <commands+0xbc8>
ffffffffc0201954:	00005617          	auipc	a2,0x5
ffffffffc0201958:	92c60613          	addi	a2,a2,-1748 # ffffffffc0206280 <commands+0x868>
ffffffffc020195c:	09400593          	li	a1,148
ffffffffc0201960:	00005517          	auipc	a0,0x5
ffffffffc0201964:	93850513          	addi	a0,a0,-1736 # ffffffffc0206298 <commands+0x880>
ffffffffc0201968:	b27fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(n > 0);
ffffffffc020196c:	00005697          	auipc	a3,0x5
ffffffffc0201970:	c6c68693          	addi	a3,a3,-916 # ffffffffc02065d8 <commands+0xbc0>
ffffffffc0201974:	00005617          	auipc	a2,0x5
ffffffffc0201978:	90c60613          	addi	a2,a2,-1780 # ffffffffc0206280 <commands+0x868>
ffffffffc020197c:	09000593          	li	a1,144
ffffffffc0201980:	00005517          	auipc	a0,0x5
ffffffffc0201984:	91850513          	addi	a0,a0,-1768 # ffffffffc0206298 <commands+0x880>
ffffffffc0201988:	b07fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc020198c <default_alloc_pages>:
    assert(n > 0);
ffffffffc020198c:	c941                	beqz	a0,ffffffffc0201a1c <default_alloc_pages+0x90>
    if (n > nr_free)
ffffffffc020198e:	000a5597          	auipc	a1,0xa5
ffffffffc0201992:	ee258593          	addi	a1,a1,-286 # ffffffffc02a6870 <free_area>
ffffffffc0201996:	0105a803          	lw	a6,16(a1)
ffffffffc020199a:	872a                	mv	a4,a0
ffffffffc020199c:	02081793          	slli	a5,a6,0x20
ffffffffc02019a0:	9381                	srli	a5,a5,0x20
ffffffffc02019a2:	00a7ee63          	bltu	a5,a0,ffffffffc02019be <default_alloc_pages+0x32>
    list_entry_t *le = &free_list;
ffffffffc02019a6:	87ae                	mv	a5,a1
ffffffffc02019a8:	a801                	j	ffffffffc02019b8 <default_alloc_pages+0x2c>
        if (p->property >= n)
ffffffffc02019aa:	ff87a683          	lw	a3,-8(a5)
ffffffffc02019ae:	02069613          	slli	a2,a3,0x20
ffffffffc02019b2:	9201                	srli	a2,a2,0x20
ffffffffc02019b4:	00e67763          	bgeu	a2,a4,ffffffffc02019c2 <default_alloc_pages+0x36>
    return listelm->next;
ffffffffc02019b8:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list)
ffffffffc02019ba:	feb798e3          	bne	a5,a1,ffffffffc02019aa <default_alloc_pages+0x1e>
        return NULL;
ffffffffc02019be:	4501                	li	a0,0
}
ffffffffc02019c0:	8082                	ret
    return listelm->prev;
ffffffffc02019c2:	0007b883          	ld	a7,0(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc02019c6:	0087b303          	ld	t1,8(a5)
        struct Page *p = le2page(le, page_link);
ffffffffc02019ca:	fe878513          	addi	a0,a5,-24
            p->property = page->property - n;
ffffffffc02019ce:	00070e1b          	sext.w	t3,a4
    prev->next = next;
ffffffffc02019d2:	0068b423          	sd	t1,8(a7)
    next->prev = prev;
ffffffffc02019d6:	01133023          	sd	a7,0(t1)
        if (page->property > n)
ffffffffc02019da:	02c77863          	bgeu	a4,a2,ffffffffc0201a0a <default_alloc_pages+0x7e>
            struct Page *p = page + n;
ffffffffc02019de:	071a                	slli	a4,a4,0x6
ffffffffc02019e0:	972a                	add	a4,a4,a0
            p->property = page->property - n;
ffffffffc02019e2:	41c686bb          	subw	a3,a3,t3
ffffffffc02019e6:	cb14                	sw	a3,16(a4)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02019e8:	00870613          	addi	a2,a4,8
ffffffffc02019ec:	4689                	li	a3,2
ffffffffc02019ee:	40d6302f          	amoor.d	zero,a3,(a2)
    __list_add(elm, listelm, listelm->next);
ffffffffc02019f2:	0088b683          	ld	a3,8(a7)
            list_add(prev, &(p->page_link));
ffffffffc02019f6:	01870613          	addi	a2,a4,24
        nr_free -= n;
ffffffffc02019fa:	0105a803          	lw	a6,16(a1)
    prev->next = next->prev = elm;
ffffffffc02019fe:	e290                	sd	a2,0(a3)
ffffffffc0201a00:	00c8b423          	sd	a2,8(a7)
    elm->next = next;
ffffffffc0201a04:	f314                	sd	a3,32(a4)
    elm->prev = prev;
ffffffffc0201a06:	01173c23          	sd	a7,24(a4)
ffffffffc0201a0a:	41c8083b          	subw	a6,a6,t3
ffffffffc0201a0e:	0105a823          	sw	a6,16(a1)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0201a12:	5775                	li	a4,-3
ffffffffc0201a14:	17c1                	addi	a5,a5,-16
ffffffffc0201a16:	60e7b02f          	amoand.d	zero,a4,(a5)
}
ffffffffc0201a1a:	8082                	ret
{
ffffffffc0201a1c:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc0201a1e:	00005697          	auipc	a3,0x5
ffffffffc0201a22:	bba68693          	addi	a3,a3,-1094 # ffffffffc02065d8 <commands+0xbc0>
ffffffffc0201a26:	00005617          	auipc	a2,0x5
ffffffffc0201a2a:	85a60613          	addi	a2,a2,-1958 # ffffffffc0206280 <commands+0x868>
ffffffffc0201a2e:	06c00593          	li	a1,108
ffffffffc0201a32:	00005517          	auipc	a0,0x5
ffffffffc0201a36:	86650513          	addi	a0,a0,-1946 # ffffffffc0206298 <commands+0x880>
{
ffffffffc0201a3a:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201a3c:	a53fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201a40 <default_init_memmap>:
{
ffffffffc0201a40:	1141                	addi	sp,sp,-16
ffffffffc0201a42:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201a44:	c5f1                	beqz	a1,ffffffffc0201b10 <default_init_memmap+0xd0>
    for (; p != base + n; p++)
ffffffffc0201a46:	00659693          	slli	a3,a1,0x6
ffffffffc0201a4a:	96aa                	add	a3,a3,a0
ffffffffc0201a4c:	87aa                	mv	a5,a0
ffffffffc0201a4e:	00d50f63          	beq	a0,a3,ffffffffc0201a6c <default_init_memmap+0x2c>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0201a52:	6798                	ld	a4,8(a5)
ffffffffc0201a54:	8b05                	andi	a4,a4,1
        assert(PageReserved(p));
ffffffffc0201a56:	cf49                	beqz	a4,ffffffffc0201af0 <default_init_memmap+0xb0>
        p->flags = p->property = 0;
ffffffffc0201a58:	0007a823          	sw	zero,16(a5)
ffffffffc0201a5c:	0007b423          	sd	zero,8(a5)
ffffffffc0201a60:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p++)
ffffffffc0201a64:	04078793          	addi	a5,a5,64
ffffffffc0201a68:	fed795e3          	bne	a5,a3,ffffffffc0201a52 <default_init_memmap+0x12>
    base->property = n;
ffffffffc0201a6c:	2581                	sext.w	a1,a1
ffffffffc0201a6e:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201a70:	4789                	li	a5,2
ffffffffc0201a72:	00850713          	addi	a4,a0,8
ffffffffc0201a76:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc0201a7a:	000a5697          	auipc	a3,0xa5
ffffffffc0201a7e:	df668693          	addi	a3,a3,-522 # ffffffffc02a6870 <free_area>
ffffffffc0201a82:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc0201a84:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc0201a86:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc0201a8a:	9db9                	addw	a1,a1,a4
ffffffffc0201a8c:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list))
ffffffffc0201a8e:	04d78a63          	beq	a5,a3,ffffffffc0201ae2 <default_init_memmap+0xa2>
            struct Page *page = le2page(le, page_link);
ffffffffc0201a92:	fe878713          	addi	a4,a5,-24
ffffffffc0201a96:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list))
ffffffffc0201a9a:	4581                	li	a1,0
            if (base < page)
ffffffffc0201a9c:	00e56a63          	bltu	a0,a4,ffffffffc0201ab0 <default_init_memmap+0x70>
    return listelm->next;
ffffffffc0201aa0:	6798                	ld	a4,8(a5)
            else if (list_next(le) == &free_list)
ffffffffc0201aa2:	02d70263          	beq	a4,a3,ffffffffc0201ac6 <default_init_memmap+0x86>
    for (; p != base + n; p++)
ffffffffc0201aa6:	87ba                	mv	a5,a4
            struct Page *page = le2page(le, page_link);
ffffffffc0201aa8:	fe878713          	addi	a4,a5,-24
            if (base < page)
ffffffffc0201aac:	fee57ae3          	bgeu	a0,a4,ffffffffc0201aa0 <default_init_memmap+0x60>
ffffffffc0201ab0:	c199                	beqz	a1,ffffffffc0201ab6 <default_init_memmap+0x76>
ffffffffc0201ab2:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0201ab6:	6398                	ld	a4,0(a5)
}
ffffffffc0201ab8:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0201aba:	e390                	sd	a2,0(a5)
ffffffffc0201abc:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc0201abe:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201ac0:	ed18                	sd	a4,24(a0)
ffffffffc0201ac2:	0141                	addi	sp,sp,16
ffffffffc0201ac4:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0201ac6:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201ac8:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0201aca:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0201acc:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list)
ffffffffc0201ace:	00d70663          	beq	a4,a3,ffffffffc0201ada <default_init_memmap+0x9a>
    prev->next = next->prev = elm;
ffffffffc0201ad2:	8832                	mv	a6,a2
ffffffffc0201ad4:	4585                	li	a1,1
    for (; p != base + n; p++)
ffffffffc0201ad6:	87ba                	mv	a5,a4
ffffffffc0201ad8:	bfc1                	j	ffffffffc0201aa8 <default_init_memmap+0x68>
}
ffffffffc0201ada:	60a2                	ld	ra,8(sp)
ffffffffc0201adc:	e290                	sd	a2,0(a3)
ffffffffc0201ade:	0141                	addi	sp,sp,16
ffffffffc0201ae0:	8082                	ret
ffffffffc0201ae2:	60a2                	ld	ra,8(sp)
ffffffffc0201ae4:	e390                	sd	a2,0(a5)
ffffffffc0201ae6:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201ae8:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201aea:	ed1c                	sd	a5,24(a0)
ffffffffc0201aec:	0141                	addi	sp,sp,16
ffffffffc0201aee:	8082                	ret
        assert(PageReserved(p));
ffffffffc0201af0:	00005697          	auipc	a3,0x5
ffffffffc0201af4:	b1868693          	addi	a3,a3,-1256 # ffffffffc0206608 <commands+0xbf0>
ffffffffc0201af8:	00004617          	auipc	a2,0x4
ffffffffc0201afc:	78860613          	addi	a2,a2,1928 # ffffffffc0206280 <commands+0x868>
ffffffffc0201b00:	04b00593          	li	a1,75
ffffffffc0201b04:	00004517          	auipc	a0,0x4
ffffffffc0201b08:	79450513          	addi	a0,a0,1940 # ffffffffc0206298 <commands+0x880>
ffffffffc0201b0c:	983fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(n > 0);
ffffffffc0201b10:	00005697          	auipc	a3,0x5
ffffffffc0201b14:	ac868693          	addi	a3,a3,-1336 # ffffffffc02065d8 <commands+0xbc0>
ffffffffc0201b18:	00004617          	auipc	a2,0x4
ffffffffc0201b1c:	76860613          	addi	a2,a2,1896 # ffffffffc0206280 <commands+0x868>
ffffffffc0201b20:	04700593          	li	a1,71
ffffffffc0201b24:	00004517          	auipc	a0,0x4
ffffffffc0201b28:	77450513          	addi	a0,a0,1908 # ffffffffc0206298 <commands+0x880>
ffffffffc0201b2c:	963fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201b30 <slob_free>:
static void slob_free(void *block, int size)
{
	slob_t *cur, *b = (slob_t *)block;
	unsigned long flags;

	if (!block)
ffffffffc0201b30:	c94d                	beqz	a0,ffffffffc0201be2 <slob_free+0xb2>
{
ffffffffc0201b32:	1141                	addi	sp,sp,-16
ffffffffc0201b34:	e022                	sd	s0,0(sp)
ffffffffc0201b36:	e406                	sd	ra,8(sp)
ffffffffc0201b38:	842a                	mv	s0,a0
		return;

	if (size)
ffffffffc0201b3a:	e9c1                	bnez	a1,ffffffffc0201bca <slob_free+0x9a>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201b3c:	100027f3          	csrr	a5,sstatus
ffffffffc0201b40:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0201b42:	4501                	li	a0,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201b44:	ebd9                	bnez	a5,ffffffffc0201bda <slob_free+0xaa>
		b->units = SLOB_UNITS(size);

	/* Find reinsertion point */
	spin_lock_irqsave(&slob_lock, flags);
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201b46:	000a5617          	auipc	a2,0xa5
ffffffffc0201b4a:	91a60613          	addi	a2,a2,-1766 # ffffffffc02a6460 <slobfree>
ffffffffc0201b4e:	621c                	ld	a5,0(a2)
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201b50:	873e                	mv	a4,a5
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201b52:	679c                	ld	a5,8(a5)
ffffffffc0201b54:	02877a63          	bgeu	a4,s0,ffffffffc0201b88 <slob_free+0x58>
ffffffffc0201b58:	00f46463          	bltu	s0,a5,ffffffffc0201b60 <slob_free+0x30>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201b5c:	fef76ae3          	bltu	a4,a5,ffffffffc0201b50 <slob_free+0x20>
			break;

	if (b + b->units == cur->next)
ffffffffc0201b60:	400c                	lw	a1,0(s0)
ffffffffc0201b62:	00459693          	slli	a3,a1,0x4
ffffffffc0201b66:	96a2                	add	a3,a3,s0
ffffffffc0201b68:	02d78a63          	beq	a5,a3,ffffffffc0201b9c <slob_free+0x6c>
		b->next = cur->next->next;
	}
	else
		b->next = cur->next;

	if (cur + cur->units == b)
ffffffffc0201b6c:	4314                	lw	a3,0(a4)
		b->next = cur->next;
ffffffffc0201b6e:	e41c                	sd	a5,8(s0)
	if (cur + cur->units == b)
ffffffffc0201b70:	00469793          	slli	a5,a3,0x4
ffffffffc0201b74:	97ba                	add	a5,a5,a4
ffffffffc0201b76:	02f40e63          	beq	s0,a5,ffffffffc0201bb2 <slob_free+0x82>
	{
		cur->units += b->units;
		cur->next = b->next;
	}
	else
		cur->next = b;
ffffffffc0201b7a:	e700                	sd	s0,8(a4)

	slobfree = cur;
ffffffffc0201b7c:	e218                	sd	a4,0(a2)
    if (flag)
ffffffffc0201b7e:	e129                	bnez	a0,ffffffffc0201bc0 <slob_free+0x90>

	spin_unlock_irqrestore(&slob_lock, flags);
}
ffffffffc0201b80:	60a2                	ld	ra,8(sp)
ffffffffc0201b82:	6402                	ld	s0,0(sp)
ffffffffc0201b84:	0141                	addi	sp,sp,16
ffffffffc0201b86:	8082                	ret
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201b88:	fcf764e3          	bltu	a4,a5,ffffffffc0201b50 <slob_free+0x20>
ffffffffc0201b8c:	fcf472e3          	bgeu	s0,a5,ffffffffc0201b50 <slob_free+0x20>
	if (b + b->units == cur->next)
ffffffffc0201b90:	400c                	lw	a1,0(s0)
ffffffffc0201b92:	00459693          	slli	a3,a1,0x4
ffffffffc0201b96:	96a2                	add	a3,a3,s0
ffffffffc0201b98:	fcd79ae3          	bne	a5,a3,ffffffffc0201b6c <slob_free+0x3c>
		b->units += cur->next->units;
ffffffffc0201b9c:	4394                	lw	a3,0(a5)
		b->next = cur->next->next;
ffffffffc0201b9e:	679c                	ld	a5,8(a5)
		b->units += cur->next->units;
ffffffffc0201ba0:	9db5                	addw	a1,a1,a3
ffffffffc0201ba2:	c00c                	sw	a1,0(s0)
	if (cur + cur->units == b)
ffffffffc0201ba4:	4314                	lw	a3,0(a4)
		b->next = cur->next->next;
ffffffffc0201ba6:	e41c                	sd	a5,8(s0)
	if (cur + cur->units == b)
ffffffffc0201ba8:	00469793          	slli	a5,a3,0x4
ffffffffc0201bac:	97ba                	add	a5,a5,a4
ffffffffc0201bae:	fcf416e3          	bne	s0,a5,ffffffffc0201b7a <slob_free+0x4a>
		cur->units += b->units;
ffffffffc0201bb2:	401c                	lw	a5,0(s0)
		cur->next = b->next;
ffffffffc0201bb4:	640c                	ld	a1,8(s0)
	slobfree = cur;
ffffffffc0201bb6:	e218                	sd	a4,0(a2)
		cur->units += b->units;
ffffffffc0201bb8:	9ebd                	addw	a3,a3,a5
ffffffffc0201bba:	c314                	sw	a3,0(a4)
		cur->next = b->next;
ffffffffc0201bbc:	e70c                	sd	a1,8(a4)
ffffffffc0201bbe:	d169                	beqz	a0,ffffffffc0201b80 <slob_free+0x50>
}
ffffffffc0201bc0:	6402                	ld	s0,0(sp)
ffffffffc0201bc2:	60a2                	ld	ra,8(sp)
ffffffffc0201bc4:	0141                	addi	sp,sp,16
        intr_enable();
ffffffffc0201bc6:	de9fe06f          	j	ffffffffc02009ae <intr_enable>
		b->units = SLOB_UNITS(size);
ffffffffc0201bca:	25bd                	addiw	a1,a1,15
ffffffffc0201bcc:	8191                	srli	a1,a1,0x4
ffffffffc0201bce:	c10c                	sw	a1,0(a0)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201bd0:	100027f3          	csrr	a5,sstatus
ffffffffc0201bd4:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0201bd6:	4501                	li	a0,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201bd8:	d7bd                	beqz	a5,ffffffffc0201b46 <slob_free+0x16>
        intr_disable();
ffffffffc0201bda:	ddbfe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc0201bde:	4505                	li	a0,1
ffffffffc0201be0:	b79d                	j	ffffffffc0201b46 <slob_free+0x16>
ffffffffc0201be2:	8082                	ret

ffffffffc0201be4 <__slob_get_free_pages.constprop.0>:
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201be4:	4785                	li	a5,1
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0201be6:	1141                	addi	sp,sp,-16
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201be8:	00a7953b          	sllw	a0,a5,a0
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0201bec:	e406                	sd	ra,8(sp)
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201bee:	352000ef          	jal	ra,ffffffffc0201f40 <alloc_pages>
	if (!page)
ffffffffc0201bf2:	c91d                	beqz	a0,ffffffffc0201c28 <__slob_get_free_pages.constprop.0+0x44>
    return page - pages + nbase;
ffffffffc0201bf4:	000a9697          	auipc	a3,0xa9
ffffffffc0201bf8:	cec6b683          	ld	a3,-788(a3) # ffffffffc02aa8e0 <pages>
ffffffffc0201bfc:	8d15                	sub	a0,a0,a3
ffffffffc0201bfe:	8519                	srai	a0,a0,0x6
ffffffffc0201c00:	00006697          	auipc	a3,0x6
ffffffffc0201c04:	d386b683          	ld	a3,-712(a3) # ffffffffc0207938 <nbase>
ffffffffc0201c08:	9536                	add	a0,a0,a3
    return KADDR(page2pa(page));
ffffffffc0201c0a:	00c51793          	slli	a5,a0,0xc
ffffffffc0201c0e:	83b1                	srli	a5,a5,0xc
ffffffffc0201c10:	000a9717          	auipc	a4,0xa9
ffffffffc0201c14:	cc873703          	ld	a4,-824(a4) # ffffffffc02aa8d8 <npage>
    return page2ppn(page) << PGSHIFT;
ffffffffc0201c18:	0532                	slli	a0,a0,0xc
    return KADDR(page2pa(page));
ffffffffc0201c1a:	00e7fa63          	bgeu	a5,a4,ffffffffc0201c2e <__slob_get_free_pages.constprop.0+0x4a>
ffffffffc0201c1e:	000a9697          	auipc	a3,0xa9
ffffffffc0201c22:	cd26b683          	ld	a3,-814(a3) # ffffffffc02aa8f0 <va_pa_offset>
ffffffffc0201c26:	9536                	add	a0,a0,a3
}
ffffffffc0201c28:	60a2                	ld	ra,8(sp)
ffffffffc0201c2a:	0141                	addi	sp,sp,16
ffffffffc0201c2c:	8082                	ret
ffffffffc0201c2e:	86aa                	mv	a3,a0
ffffffffc0201c30:	00005617          	auipc	a2,0x5
ffffffffc0201c34:	a3860613          	addi	a2,a2,-1480 # ffffffffc0206668 <default_pmm_manager+0x38>
ffffffffc0201c38:	07100593          	li	a1,113
ffffffffc0201c3c:	00005517          	auipc	a0,0x5
ffffffffc0201c40:	a5450513          	addi	a0,a0,-1452 # ffffffffc0206690 <default_pmm_manager+0x60>
ffffffffc0201c44:	84bfe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201c48 <slob_alloc.constprop.0>:
static void *slob_alloc(size_t size, gfp_t gfp, int align)
ffffffffc0201c48:	1101                	addi	sp,sp,-32
ffffffffc0201c4a:	ec06                	sd	ra,24(sp)
ffffffffc0201c4c:	e822                	sd	s0,16(sp)
ffffffffc0201c4e:	e426                	sd	s1,8(sp)
ffffffffc0201c50:	e04a                	sd	s2,0(sp)
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc0201c52:	01050713          	addi	a4,a0,16
ffffffffc0201c56:	6785                	lui	a5,0x1
ffffffffc0201c58:	0cf77363          	bgeu	a4,a5,ffffffffc0201d1e <slob_alloc.constprop.0+0xd6>
	int delta = 0, units = SLOB_UNITS(size);
ffffffffc0201c5c:	00f50493          	addi	s1,a0,15
ffffffffc0201c60:	8091                	srli	s1,s1,0x4
ffffffffc0201c62:	2481                	sext.w	s1,s1
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201c64:	10002673          	csrr	a2,sstatus
ffffffffc0201c68:	8a09                	andi	a2,a2,2
ffffffffc0201c6a:	e25d                	bnez	a2,ffffffffc0201d10 <slob_alloc.constprop.0+0xc8>
	prev = slobfree;
ffffffffc0201c6c:	000a4917          	auipc	s2,0xa4
ffffffffc0201c70:	7f490913          	addi	s2,s2,2036 # ffffffffc02a6460 <slobfree>
ffffffffc0201c74:	00093683          	ld	a3,0(s2)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201c78:	669c                	ld	a5,8(a3)
		if (cur->units >= units + delta)
ffffffffc0201c7a:	4398                	lw	a4,0(a5)
ffffffffc0201c7c:	08975e63          	bge	a4,s1,ffffffffc0201d18 <slob_alloc.constprop.0+0xd0>
		if (cur == slobfree)
ffffffffc0201c80:	00f68b63          	beq	a3,a5,ffffffffc0201c96 <slob_alloc.constprop.0+0x4e>
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201c84:	6780                	ld	s0,8(a5)
		if (cur->units >= units + delta)
ffffffffc0201c86:	4018                	lw	a4,0(s0)
ffffffffc0201c88:	02975a63          	bge	a4,s1,ffffffffc0201cbc <slob_alloc.constprop.0+0x74>
		if (cur == slobfree)
ffffffffc0201c8c:	00093683          	ld	a3,0(s2)
ffffffffc0201c90:	87a2                	mv	a5,s0
ffffffffc0201c92:	fef699e3          	bne	a3,a5,ffffffffc0201c84 <slob_alloc.constprop.0+0x3c>
    if (flag)
ffffffffc0201c96:	ee31                	bnez	a2,ffffffffc0201cf2 <slob_alloc.constprop.0+0xaa>
			cur = (slob_t *)__slob_get_free_page(gfp);
ffffffffc0201c98:	4501                	li	a0,0
ffffffffc0201c9a:	f4bff0ef          	jal	ra,ffffffffc0201be4 <__slob_get_free_pages.constprop.0>
ffffffffc0201c9e:	842a                	mv	s0,a0
			if (!cur)
ffffffffc0201ca0:	cd05                	beqz	a0,ffffffffc0201cd8 <slob_alloc.constprop.0+0x90>
			slob_free(cur, PAGE_SIZE);
ffffffffc0201ca2:	6585                	lui	a1,0x1
ffffffffc0201ca4:	e8dff0ef          	jal	ra,ffffffffc0201b30 <slob_free>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201ca8:	10002673          	csrr	a2,sstatus
ffffffffc0201cac:	8a09                	andi	a2,a2,2
ffffffffc0201cae:	ee05                	bnez	a2,ffffffffc0201ce6 <slob_alloc.constprop.0+0x9e>
			cur = slobfree;
ffffffffc0201cb0:	00093783          	ld	a5,0(s2)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201cb4:	6780                	ld	s0,8(a5)
		if (cur->units >= units + delta)
ffffffffc0201cb6:	4018                	lw	a4,0(s0)
ffffffffc0201cb8:	fc974ae3          	blt	a4,s1,ffffffffc0201c8c <slob_alloc.constprop.0+0x44>
			if (cur->units == units)	/* exact fit? */
ffffffffc0201cbc:	04e48763          	beq	s1,a4,ffffffffc0201d0a <slob_alloc.constprop.0+0xc2>
				prev->next = cur + units;
ffffffffc0201cc0:	00449693          	slli	a3,s1,0x4
ffffffffc0201cc4:	96a2                	add	a3,a3,s0
ffffffffc0201cc6:	e794                	sd	a3,8(a5)
				prev->next->next = cur->next;
ffffffffc0201cc8:	640c                	ld	a1,8(s0)
				prev->next->units = cur->units - units;
ffffffffc0201cca:	9f05                	subw	a4,a4,s1
ffffffffc0201ccc:	c298                	sw	a4,0(a3)
				prev->next->next = cur->next;
ffffffffc0201cce:	e68c                	sd	a1,8(a3)
				cur->units = units;
ffffffffc0201cd0:	c004                	sw	s1,0(s0)
			slobfree = prev;
ffffffffc0201cd2:	00f93023          	sd	a5,0(s2)
    if (flag)
ffffffffc0201cd6:	e20d                	bnez	a2,ffffffffc0201cf8 <slob_alloc.constprop.0+0xb0>
}
ffffffffc0201cd8:	60e2                	ld	ra,24(sp)
ffffffffc0201cda:	8522                	mv	a0,s0
ffffffffc0201cdc:	6442                	ld	s0,16(sp)
ffffffffc0201cde:	64a2                	ld	s1,8(sp)
ffffffffc0201ce0:	6902                	ld	s2,0(sp)
ffffffffc0201ce2:	6105                	addi	sp,sp,32
ffffffffc0201ce4:	8082                	ret
        intr_disable();
ffffffffc0201ce6:	ccffe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
			cur = slobfree;
ffffffffc0201cea:	00093783          	ld	a5,0(s2)
        return 1;
ffffffffc0201cee:	4605                	li	a2,1
ffffffffc0201cf0:	b7d1                	j	ffffffffc0201cb4 <slob_alloc.constprop.0+0x6c>
        intr_enable();
ffffffffc0201cf2:	cbdfe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0201cf6:	b74d                	j	ffffffffc0201c98 <slob_alloc.constprop.0+0x50>
ffffffffc0201cf8:	cb7fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
}
ffffffffc0201cfc:	60e2                	ld	ra,24(sp)
ffffffffc0201cfe:	8522                	mv	a0,s0
ffffffffc0201d00:	6442                	ld	s0,16(sp)
ffffffffc0201d02:	64a2                	ld	s1,8(sp)
ffffffffc0201d04:	6902                	ld	s2,0(sp)
ffffffffc0201d06:	6105                	addi	sp,sp,32
ffffffffc0201d08:	8082                	ret
				prev->next = cur->next; /* unlink */
ffffffffc0201d0a:	6418                	ld	a4,8(s0)
ffffffffc0201d0c:	e798                	sd	a4,8(a5)
ffffffffc0201d0e:	b7d1                	j	ffffffffc0201cd2 <slob_alloc.constprop.0+0x8a>
        intr_disable();
ffffffffc0201d10:	ca5fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc0201d14:	4605                	li	a2,1
ffffffffc0201d16:	bf99                	j	ffffffffc0201c6c <slob_alloc.constprop.0+0x24>
		if (cur->units >= units + delta)
ffffffffc0201d18:	843e                	mv	s0,a5
ffffffffc0201d1a:	87b6                	mv	a5,a3
ffffffffc0201d1c:	b745                	j	ffffffffc0201cbc <slob_alloc.constprop.0+0x74>
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc0201d1e:	00005697          	auipc	a3,0x5
ffffffffc0201d22:	98268693          	addi	a3,a3,-1662 # ffffffffc02066a0 <default_pmm_manager+0x70>
ffffffffc0201d26:	00004617          	auipc	a2,0x4
ffffffffc0201d2a:	55a60613          	addi	a2,a2,1370 # ffffffffc0206280 <commands+0x868>
ffffffffc0201d2e:	06300593          	li	a1,99
ffffffffc0201d32:	00005517          	auipc	a0,0x5
ffffffffc0201d36:	98e50513          	addi	a0,a0,-1650 # ffffffffc02066c0 <default_pmm_manager+0x90>
ffffffffc0201d3a:	f54fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201d3e <kmalloc_init>:
	cprintf("use SLOB allocator\n");
}

inline void
kmalloc_init(void)
{
ffffffffc0201d3e:	1141                	addi	sp,sp,-16
	cprintf("use SLOB allocator\n");
ffffffffc0201d40:	00005517          	auipc	a0,0x5
ffffffffc0201d44:	99850513          	addi	a0,a0,-1640 # ffffffffc02066d8 <default_pmm_manager+0xa8>
{
ffffffffc0201d48:	e406                	sd	ra,8(sp)
	cprintf("use SLOB allocator\n");
ffffffffc0201d4a:	c4afe0ef          	jal	ra,ffffffffc0200194 <cprintf>
	slob_init();
	cprintf("kmalloc_init() succeeded!\n");
}
ffffffffc0201d4e:	60a2                	ld	ra,8(sp)
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201d50:	00005517          	auipc	a0,0x5
ffffffffc0201d54:	9a050513          	addi	a0,a0,-1632 # ffffffffc02066f0 <default_pmm_manager+0xc0>
}
ffffffffc0201d58:	0141                	addi	sp,sp,16
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201d5a:	c3afe06f          	j	ffffffffc0200194 <cprintf>

ffffffffc0201d5e <kallocated>:

size_t
kallocated(void)
{
	return slob_allocated();
}
ffffffffc0201d5e:	4501                	li	a0,0
ffffffffc0201d60:	8082                	ret

ffffffffc0201d62 <kmalloc>:
	return 0;
}

void *
kmalloc(size_t size)
{
ffffffffc0201d62:	1101                	addi	sp,sp,-32
ffffffffc0201d64:	e04a                	sd	s2,0(sp)
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201d66:	6905                	lui	s2,0x1
{
ffffffffc0201d68:	e822                	sd	s0,16(sp)
ffffffffc0201d6a:	ec06                	sd	ra,24(sp)
ffffffffc0201d6c:	e426                	sd	s1,8(sp)
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201d6e:	fef90793          	addi	a5,s2,-17 # fef <_binary_obj___user_faultread_out_size-0x8bd9>
{
ffffffffc0201d72:	842a                	mv	s0,a0
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201d74:	04a7f963          	bgeu	a5,a0,ffffffffc0201dc6 <kmalloc+0x64>
	bb = slob_alloc(sizeof(bigblock_t), gfp, 0);
ffffffffc0201d78:	4561                	li	a0,24
ffffffffc0201d7a:	ecfff0ef          	jal	ra,ffffffffc0201c48 <slob_alloc.constprop.0>
ffffffffc0201d7e:	84aa                	mv	s1,a0
	if (!bb)
ffffffffc0201d80:	c929                	beqz	a0,ffffffffc0201dd2 <kmalloc+0x70>
	bb->order = find_order(size);
ffffffffc0201d82:	0004079b          	sext.w	a5,s0
	int order = 0;
ffffffffc0201d86:	4501                	li	a0,0
	for (; size > 4096; size >>= 1)
ffffffffc0201d88:	00f95763          	bge	s2,a5,ffffffffc0201d96 <kmalloc+0x34>
ffffffffc0201d8c:	6705                	lui	a4,0x1
ffffffffc0201d8e:	8785                	srai	a5,a5,0x1
		order++;
ffffffffc0201d90:	2505                	addiw	a0,a0,1
	for (; size > 4096; size >>= 1)
ffffffffc0201d92:	fef74ee3          	blt	a4,a5,ffffffffc0201d8e <kmalloc+0x2c>
	bb->order = find_order(size);
ffffffffc0201d96:	c088                	sw	a0,0(s1)
	bb->pages = (void *)__slob_get_free_pages(gfp, bb->order);
ffffffffc0201d98:	e4dff0ef          	jal	ra,ffffffffc0201be4 <__slob_get_free_pages.constprop.0>
ffffffffc0201d9c:	e488                	sd	a0,8(s1)
ffffffffc0201d9e:	842a                	mv	s0,a0
	if (bb->pages)
ffffffffc0201da0:	c525                	beqz	a0,ffffffffc0201e08 <kmalloc+0xa6>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201da2:	100027f3          	csrr	a5,sstatus
ffffffffc0201da6:	8b89                	andi	a5,a5,2
ffffffffc0201da8:	ef8d                	bnez	a5,ffffffffc0201de2 <kmalloc+0x80>
		bb->next = bigblocks;
ffffffffc0201daa:	000a9797          	auipc	a5,0xa9
ffffffffc0201dae:	b1678793          	addi	a5,a5,-1258 # ffffffffc02aa8c0 <bigblocks>
ffffffffc0201db2:	6398                	ld	a4,0(a5)
		bigblocks = bb;
ffffffffc0201db4:	e384                	sd	s1,0(a5)
		bb->next = bigblocks;
ffffffffc0201db6:	e898                	sd	a4,16(s1)
	return __kmalloc(size, 0);
}
ffffffffc0201db8:	60e2                	ld	ra,24(sp)
ffffffffc0201dba:	8522                	mv	a0,s0
ffffffffc0201dbc:	6442                	ld	s0,16(sp)
ffffffffc0201dbe:	64a2                	ld	s1,8(sp)
ffffffffc0201dc0:	6902                	ld	s2,0(sp)
ffffffffc0201dc2:	6105                	addi	sp,sp,32
ffffffffc0201dc4:	8082                	ret
		m = slob_alloc(size + SLOB_UNIT, gfp, 0);
ffffffffc0201dc6:	0541                	addi	a0,a0,16
ffffffffc0201dc8:	e81ff0ef          	jal	ra,ffffffffc0201c48 <slob_alloc.constprop.0>
		return m ? (void *)(m + 1) : 0;
ffffffffc0201dcc:	01050413          	addi	s0,a0,16
ffffffffc0201dd0:	f565                	bnez	a0,ffffffffc0201db8 <kmalloc+0x56>
ffffffffc0201dd2:	4401                	li	s0,0
}
ffffffffc0201dd4:	60e2                	ld	ra,24(sp)
ffffffffc0201dd6:	8522                	mv	a0,s0
ffffffffc0201dd8:	6442                	ld	s0,16(sp)
ffffffffc0201dda:	64a2                	ld	s1,8(sp)
ffffffffc0201ddc:	6902                	ld	s2,0(sp)
ffffffffc0201dde:	6105                	addi	sp,sp,32
ffffffffc0201de0:	8082                	ret
        intr_disable();
ffffffffc0201de2:	bd3fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
		bb->next = bigblocks;
ffffffffc0201de6:	000a9797          	auipc	a5,0xa9
ffffffffc0201dea:	ada78793          	addi	a5,a5,-1318 # ffffffffc02aa8c0 <bigblocks>
ffffffffc0201dee:	6398                	ld	a4,0(a5)
		bigblocks = bb;
ffffffffc0201df0:	e384                	sd	s1,0(a5)
		bb->next = bigblocks;
ffffffffc0201df2:	e898                	sd	a4,16(s1)
        intr_enable();
ffffffffc0201df4:	bbbfe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
		return bb->pages;
ffffffffc0201df8:	6480                	ld	s0,8(s1)
}
ffffffffc0201dfa:	60e2                	ld	ra,24(sp)
ffffffffc0201dfc:	64a2                	ld	s1,8(sp)
ffffffffc0201dfe:	8522                	mv	a0,s0
ffffffffc0201e00:	6442                	ld	s0,16(sp)
ffffffffc0201e02:	6902                	ld	s2,0(sp)
ffffffffc0201e04:	6105                	addi	sp,sp,32
ffffffffc0201e06:	8082                	ret
	slob_free(bb, sizeof(bigblock_t));
ffffffffc0201e08:	45e1                	li	a1,24
ffffffffc0201e0a:	8526                	mv	a0,s1
ffffffffc0201e0c:	d25ff0ef          	jal	ra,ffffffffc0201b30 <slob_free>
	return __kmalloc(size, 0);
ffffffffc0201e10:	b765                	j	ffffffffc0201db8 <kmalloc+0x56>

ffffffffc0201e12 <kfree>:
void kfree(void *block)
{
	bigblock_t *bb, **last = &bigblocks;
	unsigned long flags;

	if (!block)
ffffffffc0201e12:	c169                	beqz	a0,ffffffffc0201ed4 <kfree+0xc2>
{
ffffffffc0201e14:	1101                	addi	sp,sp,-32
ffffffffc0201e16:	e822                	sd	s0,16(sp)
ffffffffc0201e18:	ec06                	sd	ra,24(sp)
ffffffffc0201e1a:	e426                	sd	s1,8(sp)
		return;

	if (!((unsigned long)block & (PAGE_SIZE - 1)))
ffffffffc0201e1c:	03451793          	slli	a5,a0,0x34
ffffffffc0201e20:	842a                	mv	s0,a0
ffffffffc0201e22:	e3d9                	bnez	a5,ffffffffc0201ea8 <kfree+0x96>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201e24:	100027f3          	csrr	a5,sstatus
ffffffffc0201e28:	8b89                	andi	a5,a5,2
ffffffffc0201e2a:	e7d9                	bnez	a5,ffffffffc0201eb8 <kfree+0xa6>
	{
		/* might be on the big block list */
		spin_lock_irqsave(&block_lock, flags);
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201e2c:	000a9797          	auipc	a5,0xa9
ffffffffc0201e30:	a947b783          	ld	a5,-1388(a5) # ffffffffc02aa8c0 <bigblocks>
    return 0;
ffffffffc0201e34:	4601                	li	a2,0
ffffffffc0201e36:	cbad                	beqz	a5,ffffffffc0201ea8 <kfree+0x96>
	bigblock_t *bb, **last = &bigblocks;
ffffffffc0201e38:	000a9697          	auipc	a3,0xa9
ffffffffc0201e3c:	a8868693          	addi	a3,a3,-1400 # ffffffffc02aa8c0 <bigblocks>
ffffffffc0201e40:	a021                	j	ffffffffc0201e48 <kfree+0x36>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201e42:	01048693          	addi	a3,s1,16
ffffffffc0201e46:	c3a5                	beqz	a5,ffffffffc0201ea6 <kfree+0x94>
		{
			if (bb->pages == block)
ffffffffc0201e48:	6798                	ld	a4,8(a5)
ffffffffc0201e4a:	84be                	mv	s1,a5
			{
				*last = bb->next;
ffffffffc0201e4c:	6b9c                	ld	a5,16(a5)
			if (bb->pages == block)
ffffffffc0201e4e:	fe871ae3          	bne	a4,s0,ffffffffc0201e42 <kfree+0x30>
				*last = bb->next;
ffffffffc0201e52:	e29c                	sd	a5,0(a3)
    if (flag)
ffffffffc0201e54:	ee2d                	bnez	a2,ffffffffc0201ece <kfree+0xbc>
    return pa2page(PADDR(kva));
ffffffffc0201e56:	c02007b7          	lui	a5,0xc0200
				spin_unlock_irqrestore(&block_lock, flags);
				__slob_free_pages((unsigned long)block, bb->order);
ffffffffc0201e5a:	4098                	lw	a4,0(s1)
ffffffffc0201e5c:	08f46963          	bltu	s0,a5,ffffffffc0201eee <kfree+0xdc>
ffffffffc0201e60:	000a9697          	auipc	a3,0xa9
ffffffffc0201e64:	a906b683          	ld	a3,-1392(a3) # ffffffffc02aa8f0 <va_pa_offset>
ffffffffc0201e68:	8c15                	sub	s0,s0,a3
    if (PPN(pa) >= npage)
ffffffffc0201e6a:	8031                	srli	s0,s0,0xc
ffffffffc0201e6c:	000a9797          	auipc	a5,0xa9
ffffffffc0201e70:	a6c7b783          	ld	a5,-1428(a5) # ffffffffc02aa8d8 <npage>
ffffffffc0201e74:	06f47163          	bgeu	s0,a5,ffffffffc0201ed6 <kfree+0xc4>
    return &pages[PPN(pa) - nbase];
ffffffffc0201e78:	00006517          	auipc	a0,0x6
ffffffffc0201e7c:	ac053503          	ld	a0,-1344(a0) # ffffffffc0207938 <nbase>
ffffffffc0201e80:	8c09                	sub	s0,s0,a0
ffffffffc0201e82:	041a                	slli	s0,s0,0x6
	free_pages(kva2page(kva), 1 << order);
ffffffffc0201e84:	000a9517          	auipc	a0,0xa9
ffffffffc0201e88:	a5c53503          	ld	a0,-1444(a0) # ffffffffc02aa8e0 <pages>
ffffffffc0201e8c:	4585                	li	a1,1
ffffffffc0201e8e:	9522                	add	a0,a0,s0
ffffffffc0201e90:	00e595bb          	sllw	a1,a1,a4
ffffffffc0201e94:	0ea000ef          	jal	ra,ffffffffc0201f7e <free_pages>
		spin_unlock_irqrestore(&block_lock, flags);
	}

	slob_free((slob_t *)block - 1, 0);
	return;
}
ffffffffc0201e98:	6442                	ld	s0,16(sp)
ffffffffc0201e9a:	60e2                	ld	ra,24(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201e9c:	8526                	mv	a0,s1
}
ffffffffc0201e9e:	64a2                	ld	s1,8(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201ea0:	45e1                	li	a1,24
}
ffffffffc0201ea2:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201ea4:	b171                	j	ffffffffc0201b30 <slob_free>
ffffffffc0201ea6:	e20d                	bnez	a2,ffffffffc0201ec8 <kfree+0xb6>
ffffffffc0201ea8:	ff040513          	addi	a0,s0,-16
}
ffffffffc0201eac:	6442                	ld	s0,16(sp)
ffffffffc0201eae:	60e2                	ld	ra,24(sp)
ffffffffc0201eb0:	64a2                	ld	s1,8(sp)
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201eb2:	4581                	li	a1,0
}
ffffffffc0201eb4:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201eb6:	b9ad                	j	ffffffffc0201b30 <slob_free>
        intr_disable();
ffffffffc0201eb8:	afdfe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201ebc:	000a9797          	auipc	a5,0xa9
ffffffffc0201ec0:	a047b783          	ld	a5,-1532(a5) # ffffffffc02aa8c0 <bigblocks>
        return 1;
ffffffffc0201ec4:	4605                	li	a2,1
ffffffffc0201ec6:	fbad                	bnez	a5,ffffffffc0201e38 <kfree+0x26>
        intr_enable();
ffffffffc0201ec8:	ae7fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0201ecc:	bff1                	j	ffffffffc0201ea8 <kfree+0x96>
ffffffffc0201ece:	ae1fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0201ed2:	b751                	j	ffffffffc0201e56 <kfree+0x44>
ffffffffc0201ed4:	8082                	ret
        panic("pa2page called with invalid pa");
ffffffffc0201ed6:	00005617          	auipc	a2,0x5
ffffffffc0201eda:	86260613          	addi	a2,a2,-1950 # ffffffffc0206738 <default_pmm_manager+0x108>
ffffffffc0201ede:	06900593          	li	a1,105
ffffffffc0201ee2:	00004517          	auipc	a0,0x4
ffffffffc0201ee6:	7ae50513          	addi	a0,a0,1966 # ffffffffc0206690 <default_pmm_manager+0x60>
ffffffffc0201eea:	da4fe0ef          	jal	ra,ffffffffc020048e <__panic>
    return pa2page(PADDR(kva));
ffffffffc0201eee:	86a2                	mv	a3,s0
ffffffffc0201ef0:	00005617          	auipc	a2,0x5
ffffffffc0201ef4:	82060613          	addi	a2,a2,-2016 # ffffffffc0206710 <default_pmm_manager+0xe0>
ffffffffc0201ef8:	07700593          	li	a1,119
ffffffffc0201efc:	00004517          	auipc	a0,0x4
ffffffffc0201f00:	79450513          	addi	a0,a0,1940 # ffffffffc0206690 <default_pmm_manager+0x60>
ffffffffc0201f04:	d8afe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201f08 <pa2page.part.0>:
pa2page(uintptr_t pa)
ffffffffc0201f08:	1141                	addi	sp,sp,-16
        panic("pa2page called with invalid pa");
ffffffffc0201f0a:	00005617          	auipc	a2,0x5
ffffffffc0201f0e:	82e60613          	addi	a2,a2,-2002 # ffffffffc0206738 <default_pmm_manager+0x108>
ffffffffc0201f12:	06900593          	li	a1,105
ffffffffc0201f16:	00004517          	auipc	a0,0x4
ffffffffc0201f1a:	77a50513          	addi	a0,a0,1914 # ffffffffc0206690 <default_pmm_manager+0x60>
pa2page(uintptr_t pa)
ffffffffc0201f1e:	e406                	sd	ra,8(sp)
        panic("pa2page called with invalid pa");
ffffffffc0201f20:	d6efe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201f24 <pte2page.part.0>:
pte2page(pte_t pte)
ffffffffc0201f24:	1141                	addi	sp,sp,-16
        panic("pte2page called with invalid pte");
ffffffffc0201f26:	00005617          	auipc	a2,0x5
ffffffffc0201f2a:	83260613          	addi	a2,a2,-1998 # ffffffffc0206758 <default_pmm_manager+0x128>
ffffffffc0201f2e:	07f00593          	li	a1,127
ffffffffc0201f32:	00004517          	auipc	a0,0x4
ffffffffc0201f36:	75e50513          	addi	a0,a0,1886 # ffffffffc0206690 <default_pmm_manager+0x60>
pte2page(pte_t pte)
ffffffffc0201f3a:	e406                	sd	ra,8(sp)
        panic("pte2page called with invalid pte");
ffffffffc0201f3c:	d52fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201f40 <alloc_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201f40:	100027f3          	csrr	a5,sstatus
ffffffffc0201f44:	8b89                	andi	a5,a5,2
ffffffffc0201f46:	e799                	bnez	a5,ffffffffc0201f54 <alloc_pages+0x14>
{
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc0201f48:	000a9797          	auipc	a5,0xa9
ffffffffc0201f4c:	9a07b783          	ld	a5,-1632(a5) # ffffffffc02aa8e8 <pmm_manager>
ffffffffc0201f50:	6f9c                	ld	a5,24(a5)
ffffffffc0201f52:	8782                	jr	a5
{
ffffffffc0201f54:	1141                	addi	sp,sp,-16
ffffffffc0201f56:	e406                	sd	ra,8(sp)
ffffffffc0201f58:	e022                	sd	s0,0(sp)
ffffffffc0201f5a:	842a                	mv	s0,a0
        intr_disable();
ffffffffc0201f5c:	a59fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201f60:	000a9797          	auipc	a5,0xa9
ffffffffc0201f64:	9887b783          	ld	a5,-1656(a5) # ffffffffc02aa8e8 <pmm_manager>
ffffffffc0201f68:	6f9c                	ld	a5,24(a5)
ffffffffc0201f6a:	8522                	mv	a0,s0
ffffffffc0201f6c:	9782                	jalr	a5
ffffffffc0201f6e:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201f70:	a3ffe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc0201f74:	60a2                	ld	ra,8(sp)
ffffffffc0201f76:	8522                	mv	a0,s0
ffffffffc0201f78:	6402                	ld	s0,0(sp)
ffffffffc0201f7a:	0141                	addi	sp,sp,16
ffffffffc0201f7c:	8082                	ret

ffffffffc0201f7e <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201f7e:	100027f3          	csrr	a5,sstatus
ffffffffc0201f82:	8b89                	andi	a5,a5,2
ffffffffc0201f84:	e799                	bnez	a5,ffffffffc0201f92 <free_pages+0x14>
void free_pages(struct Page *base, size_t n)
{
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc0201f86:	000a9797          	auipc	a5,0xa9
ffffffffc0201f8a:	9627b783          	ld	a5,-1694(a5) # ffffffffc02aa8e8 <pmm_manager>
ffffffffc0201f8e:	739c                	ld	a5,32(a5)
ffffffffc0201f90:	8782                	jr	a5
{
ffffffffc0201f92:	1101                	addi	sp,sp,-32
ffffffffc0201f94:	ec06                	sd	ra,24(sp)
ffffffffc0201f96:	e822                	sd	s0,16(sp)
ffffffffc0201f98:	e426                	sd	s1,8(sp)
ffffffffc0201f9a:	842a                	mv	s0,a0
ffffffffc0201f9c:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc0201f9e:	a17fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0201fa2:	000a9797          	auipc	a5,0xa9
ffffffffc0201fa6:	9467b783          	ld	a5,-1722(a5) # ffffffffc02aa8e8 <pmm_manager>
ffffffffc0201faa:	739c                	ld	a5,32(a5)
ffffffffc0201fac:	85a6                	mv	a1,s1
ffffffffc0201fae:	8522                	mv	a0,s0
ffffffffc0201fb0:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc0201fb2:	6442                	ld	s0,16(sp)
ffffffffc0201fb4:	60e2                	ld	ra,24(sp)
ffffffffc0201fb6:	64a2                	ld	s1,8(sp)
ffffffffc0201fb8:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0201fba:	9f5fe06f          	j	ffffffffc02009ae <intr_enable>

ffffffffc0201fbe <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201fbe:	100027f3          	csrr	a5,sstatus
ffffffffc0201fc2:	8b89                	andi	a5,a5,2
ffffffffc0201fc4:	e799                	bnez	a5,ffffffffc0201fd2 <nr_free_pages+0x14>
{
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc0201fc6:	000a9797          	auipc	a5,0xa9
ffffffffc0201fca:	9227b783          	ld	a5,-1758(a5) # ffffffffc02aa8e8 <pmm_manager>
ffffffffc0201fce:	779c                	ld	a5,40(a5)
ffffffffc0201fd0:	8782                	jr	a5
{
ffffffffc0201fd2:	1141                	addi	sp,sp,-16
ffffffffc0201fd4:	e406                	sd	ra,8(sp)
ffffffffc0201fd6:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc0201fd8:	9ddfe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0201fdc:	000a9797          	auipc	a5,0xa9
ffffffffc0201fe0:	90c7b783          	ld	a5,-1780(a5) # ffffffffc02aa8e8 <pmm_manager>
ffffffffc0201fe4:	779c                	ld	a5,40(a5)
ffffffffc0201fe6:	9782                	jalr	a5
ffffffffc0201fe8:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201fea:	9c5fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc0201fee:	60a2                	ld	ra,8(sp)
ffffffffc0201ff0:	8522                	mv	a0,s0
ffffffffc0201ff2:	6402                	ld	s0,0(sp)
ffffffffc0201ff4:	0141                	addi	sp,sp,16
ffffffffc0201ff6:	8082                	ret

ffffffffc0201ff8 <get_pte>:
//  la:     the linear address need to map
//  create: a logical value to decide if alloc a page for PT
// return vaule: the kernel virtual address of this pte
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create)
{
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201ff8:	01e5d793          	srli	a5,a1,0x1e
ffffffffc0201ffc:	1ff7f793          	andi	a5,a5,511
{
ffffffffc0202000:	7139                	addi	sp,sp,-64
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0202002:	078e                	slli	a5,a5,0x3
{
ffffffffc0202004:	f426                	sd	s1,40(sp)
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0202006:	00f504b3          	add	s1,a0,a5
    if (!(*pdep1 & PTE_V))
ffffffffc020200a:	6094                	ld	a3,0(s1)
{
ffffffffc020200c:	f04a                	sd	s2,32(sp)
ffffffffc020200e:	ec4e                	sd	s3,24(sp)
ffffffffc0202010:	e852                	sd	s4,16(sp)
ffffffffc0202012:	fc06                	sd	ra,56(sp)
ffffffffc0202014:	f822                	sd	s0,48(sp)
ffffffffc0202016:	e456                	sd	s5,8(sp)
ffffffffc0202018:	e05a                	sd	s6,0(sp)
    if (!(*pdep1 & PTE_V))
ffffffffc020201a:	0016f793          	andi	a5,a3,1
{
ffffffffc020201e:	892e                	mv	s2,a1
ffffffffc0202020:	8a32                	mv	s4,a2
ffffffffc0202022:	000a9997          	auipc	s3,0xa9
ffffffffc0202026:	8b698993          	addi	s3,s3,-1866 # ffffffffc02aa8d8 <npage>
    if (!(*pdep1 & PTE_V))
ffffffffc020202a:	efbd                	bnez	a5,ffffffffc02020a8 <get_pte+0xb0>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc020202c:	14060c63          	beqz	a2,ffffffffc0202184 <get_pte+0x18c>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0202030:	100027f3          	csrr	a5,sstatus
ffffffffc0202034:	8b89                	andi	a5,a5,2
ffffffffc0202036:	14079963          	bnez	a5,ffffffffc0202188 <get_pte+0x190>
        page = pmm_manager->alloc_pages(n);
ffffffffc020203a:	000a9797          	auipc	a5,0xa9
ffffffffc020203e:	8ae7b783          	ld	a5,-1874(a5) # ffffffffc02aa8e8 <pmm_manager>
ffffffffc0202042:	6f9c                	ld	a5,24(a5)
ffffffffc0202044:	4505                	li	a0,1
ffffffffc0202046:	9782                	jalr	a5
ffffffffc0202048:	842a                	mv	s0,a0
        if (!create || (page = alloc_page()) == NULL)
ffffffffc020204a:	12040d63          	beqz	s0,ffffffffc0202184 <get_pte+0x18c>
    return page - pages + nbase;
ffffffffc020204e:	000a9b17          	auipc	s6,0xa9
ffffffffc0202052:	892b0b13          	addi	s6,s6,-1902 # ffffffffc02aa8e0 <pages>
ffffffffc0202056:	000b3503          	ld	a0,0(s6)
ffffffffc020205a:	00080ab7          	lui	s5,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc020205e:	000a9997          	auipc	s3,0xa9
ffffffffc0202062:	87a98993          	addi	s3,s3,-1926 # ffffffffc02aa8d8 <npage>
ffffffffc0202066:	40a40533          	sub	a0,s0,a0
ffffffffc020206a:	8519                	srai	a0,a0,0x6
ffffffffc020206c:	9556                	add	a0,a0,s5
ffffffffc020206e:	0009b703          	ld	a4,0(s3)
ffffffffc0202072:	00c51793          	slli	a5,a0,0xc
    page->ref = val;
ffffffffc0202076:	4685                	li	a3,1
ffffffffc0202078:	c014                	sw	a3,0(s0)
ffffffffc020207a:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc020207c:	0532                	slli	a0,a0,0xc
ffffffffc020207e:	16e7f763          	bgeu	a5,a4,ffffffffc02021ec <get_pte+0x1f4>
ffffffffc0202082:	000a9797          	auipc	a5,0xa9
ffffffffc0202086:	86e7b783          	ld	a5,-1938(a5) # ffffffffc02aa8f0 <va_pa_offset>
ffffffffc020208a:	6605                	lui	a2,0x1
ffffffffc020208c:	4581                	li	a1,0
ffffffffc020208e:	953e                	add	a0,a0,a5
ffffffffc0202090:	6f0030ef          	jal	ra,ffffffffc0205780 <memset>
    return page - pages + nbase;
ffffffffc0202094:	000b3683          	ld	a3,0(s6)
ffffffffc0202098:	40d406b3          	sub	a3,s0,a3
ffffffffc020209c:	8699                	srai	a3,a3,0x6
ffffffffc020209e:	96d6                	add	a3,a3,s5
}

// construct PTE from a page and permission bits
static inline pte_t pte_create(uintptr_t ppn, int type)
{
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc02020a0:	06aa                	slli	a3,a3,0xa
ffffffffc02020a2:	0116e693          	ori	a3,a3,17
        *pdep1 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc02020a6:	e094                	sd	a3,0(s1)
    }

    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc02020a8:	77fd                	lui	a5,0xfffff
ffffffffc02020aa:	068a                	slli	a3,a3,0x2
ffffffffc02020ac:	0009b703          	ld	a4,0(s3)
ffffffffc02020b0:	8efd                	and	a3,a3,a5
ffffffffc02020b2:	00c6d793          	srli	a5,a3,0xc
ffffffffc02020b6:	10e7ff63          	bgeu	a5,a4,ffffffffc02021d4 <get_pte+0x1dc>
ffffffffc02020ba:	000a9a97          	auipc	s5,0xa9
ffffffffc02020be:	836a8a93          	addi	s5,s5,-1994 # ffffffffc02aa8f0 <va_pa_offset>
ffffffffc02020c2:	000ab403          	ld	s0,0(s5)
ffffffffc02020c6:	01595793          	srli	a5,s2,0x15
ffffffffc02020ca:	1ff7f793          	andi	a5,a5,511
ffffffffc02020ce:	96a2                	add	a3,a3,s0
ffffffffc02020d0:	00379413          	slli	s0,a5,0x3
ffffffffc02020d4:	9436                	add	s0,s0,a3
    if (!(*pdep0 & PTE_V))
ffffffffc02020d6:	6014                	ld	a3,0(s0)
ffffffffc02020d8:	0016f793          	andi	a5,a3,1
ffffffffc02020dc:	ebad                	bnez	a5,ffffffffc020214e <get_pte+0x156>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc02020de:	0a0a0363          	beqz	s4,ffffffffc0202184 <get_pte+0x18c>
ffffffffc02020e2:	100027f3          	csrr	a5,sstatus
ffffffffc02020e6:	8b89                	andi	a5,a5,2
ffffffffc02020e8:	efcd                	bnez	a5,ffffffffc02021a2 <get_pte+0x1aa>
        page = pmm_manager->alloc_pages(n);
ffffffffc02020ea:	000a8797          	auipc	a5,0xa8
ffffffffc02020ee:	7fe7b783          	ld	a5,2046(a5) # ffffffffc02aa8e8 <pmm_manager>
ffffffffc02020f2:	6f9c                	ld	a5,24(a5)
ffffffffc02020f4:	4505                	li	a0,1
ffffffffc02020f6:	9782                	jalr	a5
ffffffffc02020f8:	84aa                	mv	s1,a0
        if (!create || (page = alloc_page()) == NULL)
ffffffffc02020fa:	c4c9                	beqz	s1,ffffffffc0202184 <get_pte+0x18c>
    return page - pages + nbase;
ffffffffc02020fc:	000a8b17          	auipc	s6,0xa8
ffffffffc0202100:	7e4b0b13          	addi	s6,s6,2020 # ffffffffc02aa8e0 <pages>
ffffffffc0202104:	000b3503          	ld	a0,0(s6)
ffffffffc0202108:	00080a37          	lui	s4,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc020210c:	0009b703          	ld	a4,0(s3)
ffffffffc0202110:	40a48533          	sub	a0,s1,a0
ffffffffc0202114:	8519                	srai	a0,a0,0x6
ffffffffc0202116:	9552                	add	a0,a0,s4
ffffffffc0202118:	00c51793          	slli	a5,a0,0xc
    page->ref = val;
ffffffffc020211c:	4685                	li	a3,1
ffffffffc020211e:	c094                	sw	a3,0(s1)
ffffffffc0202120:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0202122:	0532                	slli	a0,a0,0xc
ffffffffc0202124:	0ee7f163          	bgeu	a5,a4,ffffffffc0202206 <get_pte+0x20e>
ffffffffc0202128:	000ab783          	ld	a5,0(s5)
ffffffffc020212c:	6605                	lui	a2,0x1
ffffffffc020212e:	4581                	li	a1,0
ffffffffc0202130:	953e                	add	a0,a0,a5
ffffffffc0202132:	64e030ef          	jal	ra,ffffffffc0205780 <memset>
    return page - pages + nbase;
ffffffffc0202136:	000b3683          	ld	a3,0(s6)
ffffffffc020213a:	40d486b3          	sub	a3,s1,a3
ffffffffc020213e:	8699                	srai	a3,a3,0x6
ffffffffc0202140:	96d2                	add	a3,a3,s4
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0202142:	06aa                	slli	a3,a3,0xa
ffffffffc0202144:	0116e693          	ori	a3,a3,17
        *pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0202148:	e014                	sd	a3,0(s0)
    }
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc020214a:	0009b703          	ld	a4,0(s3)
ffffffffc020214e:	068a                	slli	a3,a3,0x2
ffffffffc0202150:	757d                	lui	a0,0xfffff
ffffffffc0202152:	8ee9                	and	a3,a3,a0
ffffffffc0202154:	00c6d793          	srli	a5,a3,0xc
ffffffffc0202158:	06e7f263          	bgeu	a5,a4,ffffffffc02021bc <get_pte+0x1c4>
ffffffffc020215c:	000ab503          	ld	a0,0(s5)
ffffffffc0202160:	00c95913          	srli	s2,s2,0xc
ffffffffc0202164:	1ff97913          	andi	s2,s2,511
ffffffffc0202168:	96aa                	add	a3,a3,a0
ffffffffc020216a:	00391513          	slli	a0,s2,0x3
ffffffffc020216e:	9536                	add	a0,a0,a3
}
ffffffffc0202170:	70e2                	ld	ra,56(sp)
ffffffffc0202172:	7442                	ld	s0,48(sp)
ffffffffc0202174:	74a2                	ld	s1,40(sp)
ffffffffc0202176:	7902                	ld	s2,32(sp)
ffffffffc0202178:	69e2                	ld	s3,24(sp)
ffffffffc020217a:	6a42                	ld	s4,16(sp)
ffffffffc020217c:	6aa2                	ld	s5,8(sp)
ffffffffc020217e:	6b02                	ld	s6,0(sp)
ffffffffc0202180:	6121                	addi	sp,sp,64
ffffffffc0202182:	8082                	ret
            return NULL;
ffffffffc0202184:	4501                	li	a0,0
ffffffffc0202186:	b7ed                	j	ffffffffc0202170 <get_pte+0x178>
        intr_disable();
ffffffffc0202188:	82dfe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc020218c:	000a8797          	auipc	a5,0xa8
ffffffffc0202190:	75c7b783          	ld	a5,1884(a5) # ffffffffc02aa8e8 <pmm_manager>
ffffffffc0202194:	6f9c                	ld	a5,24(a5)
ffffffffc0202196:	4505                	li	a0,1
ffffffffc0202198:	9782                	jalr	a5
ffffffffc020219a:	842a                	mv	s0,a0
        intr_enable();
ffffffffc020219c:	813fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02021a0:	b56d                	j	ffffffffc020204a <get_pte+0x52>
        intr_disable();
ffffffffc02021a2:	813fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc02021a6:	000a8797          	auipc	a5,0xa8
ffffffffc02021aa:	7427b783          	ld	a5,1858(a5) # ffffffffc02aa8e8 <pmm_manager>
ffffffffc02021ae:	6f9c                	ld	a5,24(a5)
ffffffffc02021b0:	4505                	li	a0,1
ffffffffc02021b2:	9782                	jalr	a5
ffffffffc02021b4:	84aa                	mv	s1,a0
        intr_enable();
ffffffffc02021b6:	ff8fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02021ba:	b781                	j	ffffffffc02020fa <get_pte+0x102>
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc02021bc:	00004617          	auipc	a2,0x4
ffffffffc02021c0:	4ac60613          	addi	a2,a2,1196 # ffffffffc0206668 <default_pmm_manager+0x38>
ffffffffc02021c4:	0fa00593          	li	a1,250
ffffffffc02021c8:	00004517          	auipc	a0,0x4
ffffffffc02021cc:	5b850513          	addi	a0,a0,1464 # ffffffffc0206780 <default_pmm_manager+0x150>
ffffffffc02021d0:	abefe0ef          	jal	ra,ffffffffc020048e <__panic>
    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc02021d4:	00004617          	auipc	a2,0x4
ffffffffc02021d8:	49460613          	addi	a2,a2,1172 # ffffffffc0206668 <default_pmm_manager+0x38>
ffffffffc02021dc:	0ed00593          	li	a1,237
ffffffffc02021e0:	00004517          	auipc	a0,0x4
ffffffffc02021e4:	5a050513          	addi	a0,a0,1440 # ffffffffc0206780 <default_pmm_manager+0x150>
ffffffffc02021e8:	aa6fe0ef          	jal	ra,ffffffffc020048e <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc02021ec:	86aa                	mv	a3,a0
ffffffffc02021ee:	00004617          	auipc	a2,0x4
ffffffffc02021f2:	47a60613          	addi	a2,a2,1146 # ffffffffc0206668 <default_pmm_manager+0x38>
ffffffffc02021f6:	0e900593          	li	a1,233
ffffffffc02021fa:	00004517          	auipc	a0,0x4
ffffffffc02021fe:	58650513          	addi	a0,a0,1414 # ffffffffc0206780 <default_pmm_manager+0x150>
ffffffffc0202202:	a8cfe0ef          	jal	ra,ffffffffc020048e <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0202206:	86aa                	mv	a3,a0
ffffffffc0202208:	00004617          	auipc	a2,0x4
ffffffffc020220c:	46060613          	addi	a2,a2,1120 # ffffffffc0206668 <default_pmm_manager+0x38>
ffffffffc0202210:	0f700593          	li	a1,247
ffffffffc0202214:	00004517          	auipc	a0,0x4
ffffffffc0202218:	56c50513          	addi	a0,a0,1388 # ffffffffc0206780 <default_pmm_manager+0x150>
ffffffffc020221c:	a72fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0202220 <get_page>:

// get_page - get related Page struct for linear address la using PDT pgdir
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store)
{
ffffffffc0202220:	1141                	addi	sp,sp,-16
ffffffffc0202222:	e022                	sd	s0,0(sp)
ffffffffc0202224:	8432                	mv	s0,a2
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0202226:	4601                	li	a2,0
{
ffffffffc0202228:	e406                	sd	ra,8(sp)
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc020222a:	dcfff0ef          	jal	ra,ffffffffc0201ff8 <get_pte>
    if (ptep_store != NULL)
ffffffffc020222e:	c011                	beqz	s0,ffffffffc0202232 <get_page+0x12>
    {
        *ptep_store = ptep;
ffffffffc0202230:	e008                	sd	a0,0(s0)
    }
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc0202232:	c511                	beqz	a0,ffffffffc020223e <get_page+0x1e>
ffffffffc0202234:	611c                	ld	a5,0(a0)
    {
        return pte2page(*ptep);
    }
    return NULL;
ffffffffc0202236:	4501                	li	a0,0
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc0202238:	0017f713          	andi	a4,a5,1
ffffffffc020223c:	e709                	bnez	a4,ffffffffc0202246 <get_page+0x26>
}
ffffffffc020223e:	60a2                	ld	ra,8(sp)
ffffffffc0202240:	6402                	ld	s0,0(sp)
ffffffffc0202242:	0141                	addi	sp,sp,16
ffffffffc0202244:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc0202246:	078a                	slli	a5,a5,0x2
ffffffffc0202248:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc020224a:	000a8717          	auipc	a4,0xa8
ffffffffc020224e:	68e73703          	ld	a4,1678(a4) # ffffffffc02aa8d8 <npage>
ffffffffc0202252:	00e7ff63          	bgeu	a5,a4,ffffffffc0202270 <get_page+0x50>
ffffffffc0202256:	60a2                	ld	ra,8(sp)
ffffffffc0202258:	6402                	ld	s0,0(sp)
    return &pages[PPN(pa) - nbase];
ffffffffc020225a:	fff80537          	lui	a0,0xfff80
ffffffffc020225e:	97aa                	add	a5,a5,a0
ffffffffc0202260:	079a                	slli	a5,a5,0x6
ffffffffc0202262:	000a8517          	auipc	a0,0xa8
ffffffffc0202266:	67e53503          	ld	a0,1662(a0) # ffffffffc02aa8e0 <pages>
ffffffffc020226a:	953e                	add	a0,a0,a5
ffffffffc020226c:	0141                	addi	sp,sp,16
ffffffffc020226e:	8082                	ret
ffffffffc0202270:	c99ff0ef          	jal	ra,ffffffffc0201f08 <pa2page.part.0>

ffffffffc0202274 <unmap_range>:
        tlb_invalidate(pgdir, la);
    }
}

void unmap_range(pde_t *pgdir, uintptr_t start, uintptr_t end)
{
ffffffffc0202274:	7159                	addi	sp,sp,-112
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202276:	00c5e7b3          	or	a5,a1,a2
{
ffffffffc020227a:	f486                	sd	ra,104(sp)
ffffffffc020227c:	f0a2                	sd	s0,96(sp)
ffffffffc020227e:	eca6                	sd	s1,88(sp)
ffffffffc0202280:	e8ca                	sd	s2,80(sp)
ffffffffc0202282:	e4ce                	sd	s3,72(sp)
ffffffffc0202284:	e0d2                	sd	s4,64(sp)
ffffffffc0202286:	fc56                	sd	s5,56(sp)
ffffffffc0202288:	f85a                	sd	s6,48(sp)
ffffffffc020228a:	f45e                	sd	s7,40(sp)
ffffffffc020228c:	f062                	sd	s8,32(sp)
ffffffffc020228e:	ec66                	sd	s9,24(sp)
ffffffffc0202290:	e86a                	sd	s10,16(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202292:	17d2                	slli	a5,a5,0x34
ffffffffc0202294:	e3ed                	bnez	a5,ffffffffc0202376 <unmap_range+0x102>
    assert(USER_ACCESS(start, end));
ffffffffc0202296:	002007b7          	lui	a5,0x200
ffffffffc020229a:	842e                	mv	s0,a1
ffffffffc020229c:	0ef5ed63          	bltu	a1,a5,ffffffffc0202396 <unmap_range+0x122>
ffffffffc02022a0:	8932                	mv	s2,a2
ffffffffc02022a2:	0ec5fa63          	bgeu	a1,a2,ffffffffc0202396 <unmap_range+0x122>
ffffffffc02022a6:	4785                	li	a5,1
ffffffffc02022a8:	07fe                	slli	a5,a5,0x1f
ffffffffc02022aa:	0ec7e663          	bltu	a5,a2,ffffffffc0202396 <unmap_range+0x122>
ffffffffc02022ae:	89aa                	mv	s3,a0
        }
        if (*ptep != 0)
        {
            page_remove_pte(pgdir, start, ptep);
        }
        start += PGSIZE;
ffffffffc02022b0:	6a05                	lui	s4,0x1
    if (PPN(pa) >= npage)
ffffffffc02022b2:	000a8c97          	auipc	s9,0xa8
ffffffffc02022b6:	626c8c93          	addi	s9,s9,1574 # ffffffffc02aa8d8 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc02022ba:	000a8c17          	auipc	s8,0xa8
ffffffffc02022be:	626c0c13          	addi	s8,s8,1574 # ffffffffc02aa8e0 <pages>
ffffffffc02022c2:	fff80bb7          	lui	s7,0xfff80
        pmm_manager->free_pages(base, n);
ffffffffc02022c6:	000a8d17          	auipc	s10,0xa8
ffffffffc02022ca:	622d0d13          	addi	s10,s10,1570 # ffffffffc02aa8e8 <pmm_manager>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc02022ce:	00200b37          	lui	s6,0x200
ffffffffc02022d2:	ffe00ab7          	lui	s5,0xffe00
        pte_t *ptep = get_pte(pgdir, start, 0);
ffffffffc02022d6:	4601                	li	a2,0
ffffffffc02022d8:	85a2                	mv	a1,s0
ffffffffc02022da:	854e                	mv	a0,s3
ffffffffc02022dc:	d1dff0ef          	jal	ra,ffffffffc0201ff8 <get_pte>
ffffffffc02022e0:	84aa                	mv	s1,a0
        if (ptep == NULL)
ffffffffc02022e2:	cd29                	beqz	a0,ffffffffc020233c <unmap_range+0xc8>
        if (*ptep != 0)
ffffffffc02022e4:	611c                	ld	a5,0(a0)
ffffffffc02022e6:	e395                	bnez	a5,ffffffffc020230a <unmap_range+0x96>
        start += PGSIZE;
ffffffffc02022e8:	9452                	add	s0,s0,s4
    } while (start != 0 && start < end);
ffffffffc02022ea:	ff2466e3          	bltu	s0,s2,ffffffffc02022d6 <unmap_range+0x62>
}
ffffffffc02022ee:	70a6                	ld	ra,104(sp)
ffffffffc02022f0:	7406                	ld	s0,96(sp)
ffffffffc02022f2:	64e6                	ld	s1,88(sp)
ffffffffc02022f4:	6946                	ld	s2,80(sp)
ffffffffc02022f6:	69a6                	ld	s3,72(sp)
ffffffffc02022f8:	6a06                	ld	s4,64(sp)
ffffffffc02022fa:	7ae2                	ld	s5,56(sp)
ffffffffc02022fc:	7b42                	ld	s6,48(sp)
ffffffffc02022fe:	7ba2                	ld	s7,40(sp)
ffffffffc0202300:	7c02                	ld	s8,32(sp)
ffffffffc0202302:	6ce2                	ld	s9,24(sp)
ffffffffc0202304:	6d42                	ld	s10,16(sp)
ffffffffc0202306:	6165                	addi	sp,sp,112
ffffffffc0202308:	8082                	ret
    if (*ptep & PTE_V)
ffffffffc020230a:	0017f713          	andi	a4,a5,1
ffffffffc020230e:	df69                	beqz	a4,ffffffffc02022e8 <unmap_range+0x74>
    if (PPN(pa) >= npage)
ffffffffc0202310:	000cb703          	ld	a4,0(s9)
    return pa2page(PTE_ADDR(pte));
ffffffffc0202314:	078a                	slli	a5,a5,0x2
ffffffffc0202316:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202318:	08e7ff63          	bgeu	a5,a4,ffffffffc02023b6 <unmap_range+0x142>
    return &pages[PPN(pa) - nbase];
ffffffffc020231c:	000c3503          	ld	a0,0(s8)
ffffffffc0202320:	97de                	add	a5,a5,s7
ffffffffc0202322:	079a                	slli	a5,a5,0x6
ffffffffc0202324:	953e                	add	a0,a0,a5
    page->ref -= 1;
ffffffffc0202326:	411c                	lw	a5,0(a0)
ffffffffc0202328:	fff7871b          	addiw	a4,a5,-1
ffffffffc020232c:	c118                	sw	a4,0(a0)
        if (page_ref(page) == 0)
ffffffffc020232e:	cf11                	beqz	a4,ffffffffc020234a <unmap_range+0xd6>
        *ptep = 0;
ffffffffc0202330:	0004b023          	sd	zero,0(s1)

// invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
void tlb_invalidate(pde_t *pgdir, uintptr_t la)
{
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202334:	12040073          	sfence.vma	s0
        start += PGSIZE;
ffffffffc0202338:	9452                	add	s0,s0,s4
    } while (start != 0 && start < end);
ffffffffc020233a:	bf45                	j	ffffffffc02022ea <unmap_range+0x76>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc020233c:	945a                	add	s0,s0,s6
ffffffffc020233e:	01547433          	and	s0,s0,s5
    } while (start != 0 && start < end);
ffffffffc0202342:	d455                	beqz	s0,ffffffffc02022ee <unmap_range+0x7a>
ffffffffc0202344:	f92469e3          	bltu	s0,s2,ffffffffc02022d6 <unmap_range+0x62>
ffffffffc0202348:	b75d                	j	ffffffffc02022ee <unmap_range+0x7a>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020234a:	100027f3          	csrr	a5,sstatus
ffffffffc020234e:	8b89                	andi	a5,a5,2
ffffffffc0202350:	e799                	bnez	a5,ffffffffc020235e <unmap_range+0xea>
        pmm_manager->free_pages(base, n);
ffffffffc0202352:	000d3783          	ld	a5,0(s10)
ffffffffc0202356:	4585                	li	a1,1
ffffffffc0202358:	739c                	ld	a5,32(a5)
ffffffffc020235a:	9782                	jalr	a5
    if (flag)
ffffffffc020235c:	bfd1                	j	ffffffffc0202330 <unmap_range+0xbc>
ffffffffc020235e:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202360:	e54fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0202364:	000d3783          	ld	a5,0(s10)
ffffffffc0202368:	6522                	ld	a0,8(sp)
ffffffffc020236a:	4585                	li	a1,1
ffffffffc020236c:	739c                	ld	a5,32(a5)
ffffffffc020236e:	9782                	jalr	a5
        intr_enable();
ffffffffc0202370:	e3efe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202374:	bf75                	j	ffffffffc0202330 <unmap_range+0xbc>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202376:	00004697          	auipc	a3,0x4
ffffffffc020237a:	41a68693          	addi	a3,a3,1050 # ffffffffc0206790 <default_pmm_manager+0x160>
ffffffffc020237e:	00004617          	auipc	a2,0x4
ffffffffc0202382:	f0260613          	addi	a2,a2,-254 # ffffffffc0206280 <commands+0x868>
ffffffffc0202386:	12000593          	li	a1,288
ffffffffc020238a:	00004517          	auipc	a0,0x4
ffffffffc020238e:	3f650513          	addi	a0,a0,1014 # ffffffffc0206780 <default_pmm_manager+0x150>
ffffffffc0202392:	8fcfe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(USER_ACCESS(start, end));
ffffffffc0202396:	00004697          	auipc	a3,0x4
ffffffffc020239a:	42a68693          	addi	a3,a3,1066 # ffffffffc02067c0 <default_pmm_manager+0x190>
ffffffffc020239e:	00004617          	auipc	a2,0x4
ffffffffc02023a2:	ee260613          	addi	a2,a2,-286 # ffffffffc0206280 <commands+0x868>
ffffffffc02023a6:	12100593          	li	a1,289
ffffffffc02023aa:	00004517          	auipc	a0,0x4
ffffffffc02023ae:	3d650513          	addi	a0,a0,982 # ffffffffc0206780 <default_pmm_manager+0x150>
ffffffffc02023b2:	8dcfe0ef          	jal	ra,ffffffffc020048e <__panic>
ffffffffc02023b6:	b53ff0ef          	jal	ra,ffffffffc0201f08 <pa2page.part.0>

ffffffffc02023ba <exit_range>:
{
ffffffffc02023ba:	7119                	addi	sp,sp,-128
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02023bc:	00c5e7b3          	or	a5,a1,a2
{
ffffffffc02023c0:	fc86                	sd	ra,120(sp)
ffffffffc02023c2:	f8a2                	sd	s0,112(sp)
ffffffffc02023c4:	f4a6                	sd	s1,104(sp)
ffffffffc02023c6:	f0ca                	sd	s2,96(sp)
ffffffffc02023c8:	ecce                	sd	s3,88(sp)
ffffffffc02023ca:	e8d2                	sd	s4,80(sp)
ffffffffc02023cc:	e4d6                	sd	s5,72(sp)
ffffffffc02023ce:	e0da                	sd	s6,64(sp)
ffffffffc02023d0:	fc5e                	sd	s7,56(sp)
ffffffffc02023d2:	f862                	sd	s8,48(sp)
ffffffffc02023d4:	f466                	sd	s9,40(sp)
ffffffffc02023d6:	f06a                	sd	s10,32(sp)
ffffffffc02023d8:	ec6e                	sd	s11,24(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02023da:	17d2                	slli	a5,a5,0x34
ffffffffc02023dc:	20079a63          	bnez	a5,ffffffffc02025f0 <exit_range+0x236>
    assert(USER_ACCESS(start, end));
ffffffffc02023e0:	002007b7          	lui	a5,0x200
ffffffffc02023e4:	24f5e463          	bltu	a1,a5,ffffffffc020262c <exit_range+0x272>
ffffffffc02023e8:	8ab2                	mv	s5,a2
ffffffffc02023ea:	24c5f163          	bgeu	a1,a2,ffffffffc020262c <exit_range+0x272>
ffffffffc02023ee:	4785                	li	a5,1
ffffffffc02023f0:	07fe                	slli	a5,a5,0x1f
ffffffffc02023f2:	22c7ed63          	bltu	a5,a2,ffffffffc020262c <exit_range+0x272>
    d1start = ROUNDDOWN(start, PDSIZE);
ffffffffc02023f6:	c00009b7          	lui	s3,0xc0000
ffffffffc02023fa:	0135f9b3          	and	s3,a1,s3
    d0start = ROUNDDOWN(start, PTSIZE);
ffffffffc02023fe:	ffe00937          	lui	s2,0xffe00
ffffffffc0202402:	400007b7          	lui	a5,0x40000
    return KADDR(page2pa(page));
ffffffffc0202406:	5cfd                	li	s9,-1
ffffffffc0202408:	8c2a                	mv	s8,a0
ffffffffc020240a:	0125f933          	and	s2,a1,s2
ffffffffc020240e:	99be                	add	s3,s3,a5
    if (PPN(pa) >= npage)
ffffffffc0202410:	000a8d17          	auipc	s10,0xa8
ffffffffc0202414:	4c8d0d13          	addi	s10,s10,1224 # ffffffffc02aa8d8 <npage>
    return KADDR(page2pa(page));
ffffffffc0202418:	00ccdc93          	srli	s9,s9,0xc
    return &pages[PPN(pa) - nbase];
ffffffffc020241c:	000a8717          	auipc	a4,0xa8
ffffffffc0202420:	4c470713          	addi	a4,a4,1220 # ffffffffc02aa8e0 <pages>
        pmm_manager->free_pages(base, n);
ffffffffc0202424:	000a8d97          	auipc	s11,0xa8
ffffffffc0202428:	4c4d8d93          	addi	s11,s11,1220 # ffffffffc02aa8e8 <pmm_manager>
        pde1 = pgdir[PDX1(d1start)];
ffffffffc020242c:	c0000437          	lui	s0,0xc0000
ffffffffc0202430:	944e                	add	s0,s0,s3
ffffffffc0202432:	8079                	srli	s0,s0,0x1e
ffffffffc0202434:	1ff47413          	andi	s0,s0,511
ffffffffc0202438:	040e                	slli	s0,s0,0x3
ffffffffc020243a:	9462                	add	s0,s0,s8
ffffffffc020243c:	00043a03          	ld	s4,0(s0) # ffffffffc0000000 <_binary_obj___user_exit_out_size+0xffffffffbfff4ec0>
        if (pde1 & PTE_V)
ffffffffc0202440:	001a7793          	andi	a5,s4,1
ffffffffc0202444:	eb99                	bnez	a5,ffffffffc020245a <exit_range+0xa0>
    } while (d1start != 0 && d1start < end);
ffffffffc0202446:	12098463          	beqz	s3,ffffffffc020256e <exit_range+0x1b4>
ffffffffc020244a:	400007b7          	lui	a5,0x40000
ffffffffc020244e:	97ce                	add	a5,a5,s3
ffffffffc0202450:	894e                	mv	s2,s3
ffffffffc0202452:	1159fe63          	bgeu	s3,s5,ffffffffc020256e <exit_range+0x1b4>
ffffffffc0202456:	89be                	mv	s3,a5
ffffffffc0202458:	bfd1                	j	ffffffffc020242c <exit_range+0x72>
    if (PPN(pa) >= npage)
ffffffffc020245a:	000d3783          	ld	a5,0(s10)
    return pa2page(PDE_ADDR(pde));
ffffffffc020245e:	0a0a                	slli	s4,s4,0x2
ffffffffc0202460:	00ca5a13          	srli	s4,s4,0xc
    if (PPN(pa) >= npage)
ffffffffc0202464:	1cfa7263          	bgeu	s4,a5,ffffffffc0202628 <exit_range+0x26e>
    return &pages[PPN(pa) - nbase];
ffffffffc0202468:	fff80637          	lui	a2,0xfff80
ffffffffc020246c:	9652                	add	a2,a2,s4
    return page - pages + nbase;
ffffffffc020246e:	000806b7          	lui	a3,0x80
ffffffffc0202472:	96b2                	add	a3,a3,a2
    return KADDR(page2pa(page));
ffffffffc0202474:	0196f5b3          	and	a1,a3,s9
    return &pages[PPN(pa) - nbase];
ffffffffc0202478:	061a                	slli	a2,a2,0x6
    return page2ppn(page) << PGSHIFT;
ffffffffc020247a:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc020247c:	18f5fa63          	bgeu	a1,a5,ffffffffc0202610 <exit_range+0x256>
ffffffffc0202480:	000a8817          	auipc	a6,0xa8
ffffffffc0202484:	47080813          	addi	a6,a6,1136 # ffffffffc02aa8f0 <va_pa_offset>
ffffffffc0202488:	00083b03          	ld	s6,0(a6)
            free_pd0 = 1;
ffffffffc020248c:	4b85                	li	s7,1
    return &pages[PPN(pa) - nbase];
ffffffffc020248e:	fff80e37          	lui	t3,0xfff80
    return KADDR(page2pa(page));
ffffffffc0202492:	9b36                	add	s6,s6,a3
    return page - pages + nbase;
ffffffffc0202494:	00080337          	lui	t1,0x80
ffffffffc0202498:	6885                	lui	a7,0x1
ffffffffc020249a:	a819                	j	ffffffffc02024b0 <exit_range+0xf6>
                    free_pd0 = 0;
ffffffffc020249c:	4b81                	li	s7,0
                d0start += PTSIZE;
ffffffffc020249e:	002007b7          	lui	a5,0x200
ffffffffc02024a2:	993e                	add	s2,s2,a5
            } while (d0start != 0 && d0start < d1start + PDSIZE && d0start < end);
ffffffffc02024a4:	08090c63          	beqz	s2,ffffffffc020253c <exit_range+0x182>
ffffffffc02024a8:	09397a63          	bgeu	s2,s3,ffffffffc020253c <exit_range+0x182>
ffffffffc02024ac:	0f597063          	bgeu	s2,s5,ffffffffc020258c <exit_range+0x1d2>
                pde0 = pd0[PDX0(d0start)];
ffffffffc02024b0:	01595493          	srli	s1,s2,0x15
ffffffffc02024b4:	1ff4f493          	andi	s1,s1,511
ffffffffc02024b8:	048e                	slli	s1,s1,0x3
ffffffffc02024ba:	94da                	add	s1,s1,s6
ffffffffc02024bc:	609c                	ld	a5,0(s1)
                if (pde0 & PTE_V)
ffffffffc02024be:	0017f693          	andi	a3,a5,1
ffffffffc02024c2:	dee9                	beqz	a3,ffffffffc020249c <exit_range+0xe2>
    if (PPN(pa) >= npage)
ffffffffc02024c4:	000d3583          	ld	a1,0(s10)
    return pa2page(PDE_ADDR(pde));
ffffffffc02024c8:	078a                	slli	a5,a5,0x2
ffffffffc02024ca:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02024cc:	14b7fe63          	bgeu	a5,a1,ffffffffc0202628 <exit_range+0x26e>
    return &pages[PPN(pa) - nbase];
ffffffffc02024d0:	97f2                	add	a5,a5,t3
    return page - pages + nbase;
ffffffffc02024d2:	006786b3          	add	a3,a5,t1
    return KADDR(page2pa(page));
ffffffffc02024d6:	0196feb3          	and	t4,a3,s9
    return &pages[PPN(pa) - nbase];
ffffffffc02024da:	00679513          	slli	a0,a5,0x6
    return page2ppn(page) << PGSHIFT;
ffffffffc02024de:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02024e0:	12bef863          	bgeu	t4,a1,ffffffffc0202610 <exit_range+0x256>
ffffffffc02024e4:	00083783          	ld	a5,0(a6)
ffffffffc02024e8:	96be                	add	a3,a3,a5
                    for (int i = 0; i < NPTEENTRY; i++)
ffffffffc02024ea:	011685b3          	add	a1,a3,a7
                        if (pt[i] & PTE_V)
ffffffffc02024ee:	629c                	ld	a5,0(a3)
ffffffffc02024f0:	8b85                	andi	a5,a5,1
ffffffffc02024f2:	f7d5                	bnez	a5,ffffffffc020249e <exit_range+0xe4>
                    for (int i = 0; i < NPTEENTRY; i++)
ffffffffc02024f4:	06a1                	addi	a3,a3,8
ffffffffc02024f6:	fed59ce3          	bne	a1,a3,ffffffffc02024ee <exit_range+0x134>
    return &pages[PPN(pa) - nbase];
ffffffffc02024fa:	631c                	ld	a5,0(a4)
ffffffffc02024fc:	953e                	add	a0,a0,a5
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02024fe:	100027f3          	csrr	a5,sstatus
ffffffffc0202502:	8b89                	andi	a5,a5,2
ffffffffc0202504:	e7d9                	bnez	a5,ffffffffc0202592 <exit_range+0x1d8>
        pmm_manager->free_pages(base, n);
ffffffffc0202506:	000db783          	ld	a5,0(s11)
ffffffffc020250a:	4585                	li	a1,1
ffffffffc020250c:	e032                	sd	a2,0(sp)
ffffffffc020250e:	739c                	ld	a5,32(a5)
ffffffffc0202510:	9782                	jalr	a5
    if (flag)
ffffffffc0202512:	6602                	ld	a2,0(sp)
ffffffffc0202514:	000a8817          	auipc	a6,0xa8
ffffffffc0202518:	3dc80813          	addi	a6,a6,988 # ffffffffc02aa8f0 <va_pa_offset>
ffffffffc020251c:	fff80e37          	lui	t3,0xfff80
ffffffffc0202520:	00080337          	lui	t1,0x80
ffffffffc0202524:	6885                	lui	a7,0x1
ffffffffc0202526:	000a8717          	auipc	a4,0xa8
ffffffffc020252a:	3ba70713          	addi	a4,a4,954 # ffffffffc02aa8e0 <pages>
                        pd0[PDX0(d0start)] = 0;
ffffffffc020252e:	0004b023          	sd	zero,0(s1)
                d0start += PTSIZE;
ffffffffc0202532:	002007b7          	lui	a5,0x200
ffffffffc0202536:	993e                	add	s2,s2,a5
            } while (d0start != 0 && d0start < d1start + PDSIZE && d0start < end);
ffffffffc0202538:	f60918e3          	bnez	s2,ffffffffc02024a8 <exit_range+0xee>
            if (free_pd0)
ffffffffc020253c:	f00b85e3          	beqz	s7,ffffffffc0202446 <exit_range+0x8c>
    if (PPN(pa) >= npage)
ffffffffc0202540:	000d3783          	ld	a5,0(s10)
ffffffffc0202544:	0efa7263          	bgeu	s4,a5,ffffffffc0202628 <exit_range+0x26e>
    return &pages[PPN(pa) - nbase];
ffffffffc0202548:	6308                	ld	a0,0(a4)
ffffffffc020254a:	9532                	add	a0,a0,a2
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020254c:	100027f3          	csrr	a5,sstatus
ffffffffc0202550:	8b89                	andi	a5,a5,2
ffffffffc0202552:	efad                	bnez	a5,ffffffffc02025cc <exit_range+0x212>
        pmm_manager->free_pages(base, n);
ffffffffc0202554:	000db783          	ld	a5,0(s11)
ffffffffc0202558:	4585                	li	a1,1
ffffffffc020255a:	739c                	ld	a5,32(a5)
ffffffffc020255c:	9782                	jalr	a5
ffffffffc020255e:	000a8717          	auipc	a4,0xa8
ffffffffc0202562:	38270713          	addi	a4,a4,898 # ffffffffc02aa8e0 <pages>
                pgdir[PDX1(d1start)] = 0;
ffffffffc0202566:	00043023          	sd	zero,0(s0)
    } while (d1start != 0 && d1start < end);
ffffffffc020256a:	ee0990e3          	bnez	s3,ffffffffc020244a <exit_range+0x90>
}
ffffffffc020256e:	70e6                	ld	ra,120(sp)
ffffffffc0202570:	7446                	ld	s0,112(sp)
ffffffffc0202572:	74a6                	ld	s1,104(sp)
ffffffffc0202574:	7906                	ld	s2,96(sp)
ffffffffc0202576:	69e6                	ld	s3,88(sp)
ffffffffc0202578:	6a46                	ld	s4,80(sp)
ffffffffc020257a:	6aa6                	ld	s5,72(sp)
ffffffffc020257c:	6b06                	ld	s6,64(sp)
ffffffffc020257e:	7be2                	ld	s7,56(sp)
ffffffffc0202580:	7c42                	ld	s8,48(sp)
ffffffffc0202582:	7ca2                	ld	s9,40(sp)
ffffffffc0202584:	7d02                	ld	s10,32(sp)
ffffffffc0202586:	6de2                	ld	s11,24(sp)
ffffffffc0202588:	6109                	addi	sp,sp,128
ffffffffc020258a:	8082                	ret
            if (free_pd0)
ffffffffc020258c:	ea0b8fe3          	beqz	s7,ffffffffc020244a <exit_range+0x90>
ffffffffc0202590:	bf45                	j	ffffffffc0202540 <exit_range+0x186>
ffffffffc0202592:	e032                	sd	a2,0(sp)
        intr_disable();
ffffffffc0202594:	e42a                	sd	a0,8(sp)
ffffffffc0202596:	c1efe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc020259a:	000db783          	ld	a5,0(s11)
ffffffffc020259e:	6522                	ld	a0,8(sp)
ffffffffc02025a0:	4585                	li	a1,1
ffffffffc02025a2:	739c                	ld	a5,32(a5)
ffffffffc02025a4:	9782                	jalr	a5
        intr_enable();
ffffffffc02025a6:	c08fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02025aa:	6602                	ld	a2,0(sp)
ffffffffc02025ac:	000a8717          	auipc	a4,0xa8
ffffffffc02025b0:	33470713          	addi	a4,a4,820 # ffffffffc02aa8e0 <pages>
ffffffffc02025b4:	6885                	lui	a7,0x1
ffffffffc02025b6:	00080337          	lui	t1,0x80
ffffffffc02025ba:	fff80e37          	lui	t3,0xfff80
ffffffffc02025be:	000a8817          	auipc	a6,0xa8
ffffffffc02025c2:	33280813          	addi	a6,a6,818 # ffffffffc02aa8f0 <va_pa_offset>
                        pd0[PDX0(d0start)] = 0;
ffffffffc02025c6:	0004b023          	sd	zero,0(s1)
ffffffffc02025ca:	b7a5                	j	ffffffffc0202532 <exit_range+0x178>
ffffffffc02025cc:	e02a                	sd	a0,0(sp)
        intr_disable();
ffffffffc02025ce:	be6fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc02025d2:	000db783          	ld	a5,0(s11)
ffffffffc02025d6:	6502                	ld	a0,0(sp)
ffffffffc02025d8:	4585                	li	a1,1
ffffffffc02025da:	739c                	ld	a5,32(a5)
ffffffffc02025dc:	9782                	jalr	a5
        intr_enable();
ffffffffc02025de:	bd0fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02025e2:	000a8717          	auipc	a4,0xa8
ffffffffc02025e6:	2fe70713          	addi	a4,a4,766 # ffffffffc02aa8e0 <pages>
                pgdir[PDX1(d1start)] = 0;
ffffffffc02025ea:	00043023          	sd	zero,0(s0)
ffffffffc02025ee:	bfb5                	j	ffffffffc020256a <exit_range+0x1b0>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02025f0:	00004697          	auipc	a3,0x4
ffffffffc02025f4:	1a068693          	addi	a3,a3,416 # ffffffffc0206790 <default_pmm_manager+0x160>
ffffffffc02025f8:	00004617          	auipc	a2,0x4
ffffffffc02025fc:	c8860613          	addi	a2,a2,-888 # ffffffffc0206280 <commands+0x868>
ffffffffc0202600:	13500593          	li	a1,309
ffffffffc0202604:	00004517          	auipc	a0,0x4
ffffffffc0202608:	17c50513          	addi	a0,a0,380 # ffffffffc0206780 <default_pmm_manager+0x150>
ffffffffc020260c:	e83fd0ef          	jal	ra,ffffffffc020048e <__panic>
    return KADDR(page2pa(page));
ffffffffc0202610:	00004617          	auipc	a2,0x4
ffffffffc0202614:	05860613          	addi	a2,a2,88 # ffffffffc0206668 <default_pmm_manager+0x38>
ffffffffc0202618:	07100593          	li	a1,113
ffffffffc020261c:	00004517          	auipc	a0,0x4
ffffffffc0202620:	07450513          	addi	a0,a0,116 # ffffffffc0206690 <default_pmm_manager+0x60>
ffffffffc0202624:	e6bfd0ef          	jal	ra,ffffffffc020048e <__panic>
ffffffffc0202628:	8e1ff0ef          	jal	ra,ffffffffc0201f08 <pa2page.part.0>
    assert(USER_ACCESS(start, end));
ffffffffc020262c:	00004697          	auipc	a3,0x4
ffffffffc0202630:	19468693          	addi	a3,a3,404 # ffffffffc02067c0 <default_pmm_manager+0x190>
ffffffffc0202634:	00004617          	auipc	a2,0x4
ffffffffc0202638:	c4c60613          	addi	a2,a2,-948 # ffffffffc0206280 <commands+0x868>
ffffffffc020263c:	13600593          	li	a1,310
ffffffffc0202640:	00004517          	auipc	a0,0x4
ffffffffc0202644:	14050513          	addi	a0,a0,320 # ffffffffc0206780 <default_pmm_manager+0x150>
ffffffffc0202648:	e47fd0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc020264c <page_remove>:
{
ffffffffc020264c:	7179                	addi	sp,sp,-48
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc020264e:	4601                	li	a2,0
{
ffffffffc0202650:	ec26                	sd	s1,24(sp)
ffffffffc0202652:	f406                	sd	ra,40(sp)
ffffffffc0202654:	f022                	sd	s0,32(sp)
ffffffffc0202656:	84ae                	mv	s1,a1
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0202658:	9a1ff0ef          	jal	ra,ffffffffc0201ff8 <get_pte>
    if (ptep != NULL)
ffffffffc020265c:	c511                	beqz	a0,ffffffffc0202668 <page_remove+0x1c>
    if (*ptep & PTE_V)
ffffffffc020265e:	611c                	ld	a5,0(a0)
ffffffffc0202660:	842a                	mv	s0,a0
ffffffffc0202662:	0017f713          	andi	a4,a5,1
ffffffffc0202666:	e711                	bnez	a4,ffffffffc0202672 <page_remove+0x26>
}
ffffffffc0202668:	70a2                	ld	ra,40(sp)
ffffffffc020266a:	7402                	ld	s0,32(sp)
ffffffffc020266c:	64e2                	ld	s1,24(sp)
ffffffffc020266e:	6145                	addi	sp,sp,48
ffffffffc0202670:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc0202672:	078a                	slli	a5,a5,0x2
ffffffffc0202674:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202676:	000a8717          	auipc	a4,0xa8
ffffffffc020267a:	26273703          	ld	a4,610(a4) # ffffffffc02aa8d8 <npage>
ffffffffc020267e:	06e7f363          	bgeu	a5,a4,ffffffffc02026e4 <page_remove+0x98>
    return &pages[PPN(pa) - nbase];
ffffffffc0202682:	fff80537          	lui	a0,0xfff80
ffffffffc0202686:	97aa                	add	a5,a5,a0
ffffffffc0202688:	079a                	slli	a5,a5,0x6
ffffffffc020268a:	000a8517          	auipc	a0,0xa8
ffffffffc020268e:	25653503          	ld	a0,598(a0) # ffffffffc02aa8e0 <pages>
ffffffffc0202692:	953e                	add	a0,a0,a5
    page->ref -= 1;
ffffffffc0202694:	411c                	lw	a5,0(a0)
ffffffffc0202696:	fff7871b          	addiw	a4,a5,-1
ffffffffc020269a:	c118                	sw	a4,0(a0)
        if (page_ref(page) == 0)
ffffffffc020269c:	cb11                	beqz	a4,ffffffffc02026b0 <page_remove+0x64>
        *ptep = 0;
ffffffffc020269e:	00043023          	sd	zero,0(s0)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02026a2:	12048073          	sfence.vma	s1
}
ffffffffc02026a6:	70a2                	ld	ra,40(sp)
ffffffffc02026a8:	7402                	ld	s0,32(sp)
ffffffffc02026aa:	64e2                	ld	s1,24(sp)
ffffffffc02026ac:	6145                	addi	sp,sp,48
ffffffffc02026ae:	8082                	ret
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02026b0:	100027f3          	csrr	a5,sstatus
ffffffffc02026b4:	8b89                	andi	a5,a5,2
ffffffffc02026b6:	eb89                	bnez	a5,ffffffffc02026c8 <page_remove+0x7c>
        pmm_manager->free_pages(base, n);
ffffffffc02026b8:	000a8797          	auipc	a5,0xa8
ffffffffc02026bc:	2307b783          	ld	a5,560(a5) # ffffffffc02aa8e8 <pmm_manager>
ffffffffc02026c0:	739c                	ld	a5,32(a5)
ffffffffc02026c2:	4585                	li	a1,1
ffffffffc02026c4:	9782                	jalr	a5
    if (flag)
ffffffffc02026c6:	bfe1                	j	ffffffffc020269e <page_remove+0x52>
        intr_disable();
ffffffffc02026c8:	e42a                	sd	a0,8(sp)
ffffffffc02026ca:	aeafe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc02026ce:	000a8797          	auipc	a5,0xa8
ffffffffc02026d2:	21a7b783          	ld	a5,538(a5) # ffffffffc02aa8e8 <pmm_manager>
ffffffffc02026d6:	739c                	ld	a5,32(a5)
ffffffffc02026d8:	6522                	ld	a0,8(sp)
ffffffffc02026da:	4585                	li	a1,1
ffffffffc02026dc:	9782                	jalr	a5
        intr_enable();
ffffffffc02026de:	ad0fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02026e2:	bf75                	j	ffffffffc020269e <page_remove+0x52>
ffffffffc02026e4:	825ff0ef          	jal	ra,ffffffffc0201f08 <pa2page.part.0>

ffffffffc02026e8 <page_insert>:
{
ffffffffc02026e8:	7139                	addi	sp,sp,-64
ffffffffc02026ea:	e852                	sd	s4,16(sp)
ffffffffc02026ec:	8a32                	mv	s4,a2
ffffffffc02026ee:	f822                	sd	s0,48(sp)
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc02026f0:	4605                	li	a2,1
{
ffffffffc02026f2:	842e                	mv	s0,a1
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc02026f4:	85d2                	mv	a1,s4
{
ffffffffc02026f6:	f426                	sd	s1,40(sp)
ffffffffc02026f8:	fc06                	sd	ra,56(sp)
ffffffffc02026fa:	f04a                	sd	s2,32(sp)
ffffffffc02026fc:	ec4e                	sd	s3,24(sp)
ffffffffc02026fe:	e456                	sd	s5,8(sp)
ffffffffc0202700:	84b6                	mv	s1,a3
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0202702:	8f7ff0ef          	jal	ra,ffffffffc0201ff8 <get_pte>
    if (ptep == NULL)
ffffffffc0202706:	c961                	beqz	a0,ffffffffc02027d6 <page_insert+0xee>
    page->ref += 1;
ffffffffc0202708:	4014                	lw	a3,0(s0)
    if (*ptep & PTE_V)
ffffffffc020270a:	611c                	ld	a5,0(a0)
ffffffffc020270c:	89aa                	mv	s3,a0
ffffffffc020270e:	0016871b          	addiw	a4,a3,1
ffffffffc0202712:	c018                	sw	a4,0(s0)
ffffffffc0202714:	0017f713          	andi	a4,a5,1
ffffffffc0202718:	ef05                	bnez	a4,ffffffffc0202750 <page_insert+0x68>
    return page - pages + nbase;
ffffffffc020271a:	000a8717          	auipc	a4,0xa8
ffffffffc020271e:	1c673703          	ld	a4,454(a4) # ffffffffc02aa8e0 <pages>
ffffffffc0202722:	8c19                	sub	s0,s0,a4
ffffffffc0202724:	000807b7          	lui	a5,0x80
ffffffffc0202728:	8419                	srai	s0,s0,0x6
ffffffffc020272a:	943e                	add	s0,s0,a5
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc020272c:	042a                	slli	s0,s0,0xa
ffffffffc020272e:	8cc1                	or	s1,s1,s0
ffffffffc0202730:	0014e493          	ori	s1,s1,1
    *ptep = pte_create(page2ppn(page), PTE_V | perm);
ffffffffc0202734:	0099b023          	sd	s1,0(s3) # ffffffffc0000000 <_binary_obj___user_exit_out_size+0xffffffffbfff4ec0>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202738:	120a0073          	sfence.vma	s4
    return 0;
ffffffffc020273c:	4501                	li	a0,0
}
ffffffffc020273e:	70e2                	ld	ra,56(sp)
ffffffffc0202740:	7442                	ld	s0,48(sp)
ffffffffc0202742:	74a2                	ld	s1,40(sp)
ffffffffc0202744:	7902                	ld	s2,32(sp)
ffffffffc0202746:	69e2                	ld	s3,24(sp)
ffffffffc0202748:	6a42                	ld	s4,16(sp)
ffffffffc020274a:	6aa2                	ld	s5,8(sp)
ffffffffc020274c:	6121                	addi	sp,sp,64
ffffffffc020274e:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc0202750:	078a                	slli	a5,a5,0x2
ffffffffc0202752:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202754:	000a8717          	auipc	a4,0xa8
ffffffffc0202758:	18473703          	ld	a4,388(a4) # ffffffffc02aa8d8 <npage>
ffffffffc020275c:	06e7ff63          	bgeu	a5,a4,ffffffffc02027da <page_insert+0xf2>
    return &pages[PPN(pa) - nbase];
ffffffffc0202760:	000a8a97          	auipc	s5,0xa8
ffffffffc0202764:	180a8a93          	addi	s5,s5,384 # ffffffffc02aa8e0 <pages>
ffffffffc0202768:	000ab703          	ld	a4,0(s5)
ffffffffc020276c:	fff80937          	lui	s2,0xfff80
ffffffffc0202770:	993e                	add	s2,s2,a5
ffffffffc0202772:	091a                	slli	s2,s2,0x6
ffffffffc0202774:	993a                	add	s2,s2,a4
        if (p == page)
ffffffffc0202776:	01240c63          	beq	s0,s2,ffffffffc020278e <page_insert+0xa6>
    page->ref -= 1;
ffffffffc020277a:	00092783          	lw	a5,0(s2) # fffffffffff80000 <end+0x3fcd56ec>
ffffffffc020277e:	fff7869b          	addiw	a3,a5,-1
ffffffffc0202782:	00d92023          	sw	a3,0(s2)
        if (page_ref(page) == 0)
ffffffffc0202786:	c691                	beqz	a3,ffffffffc0202792 <page_insert+0xaa>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202788:	120a0073          	sfence.vma	s4
}
ffffffffc020278c:	bf59                	j	ffffffffc0202722 <page_insert+0x3a>
ffffffffc020278e:	c014                	sw	a3,0(s0)
    return page->ref;
ffffffffc0202790:	bf49                	j	ffffffffc0202722 <page_insert+0x3a>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0202792:	100027f3          	csrr	a5,sstatus
ffffffffc0202796:	8b89                	andi	a5,a5,2
ffffffffc0202798:	ef91                	bnez	a5,ffffffffc02027b4 <page_insert+0xcc>
        pmm_manager->free_pages(base, n);
ffffffffc020279a:	000a8797          	auipc	a5,0xa8
ffffffffc020279e:	14e7b783          	ld	a5,334(a5) # ffffffffc02aa8e8 <pmm_manager>
ffffffffc02027a2:	739c                	ld	a5,32(a5)
ffffffffc02027a4:	4585                	li	a1,1
ffffffffc02027a6:	854a                	mv	a0,s2
ffffffffc02027a8:	9782                	jalr	a5
    return page - pages + nbase;
ffffffffc02027aa:	000ab703          	ld	a4,0(s5)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02027ae:	120a0073          	sfence.vma	s4
ffffffffc02027b2:	bf85                	j	ffffffffc0202722 <page_insert+0x3a>
        intr_disable();
ffffffffc02027b4:	a00fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc02027b8:	000a8797          	auipc	a5,0xa8
ffffffffc02027bc:	1307b783          	ld	a5,304(a5) # ffffffffc02aa8e8 <pmm_manager>
ffffffffc02027c0:	739c                	ld	a5,32(a5)
ffffffffc02027c2:	4585                	li	a1,1
ffffffffc02027c4:	854a                	mv	a0,s2
ffffffffc02027c6:	9782                	jalr	a5
        intr_enable();
ffffffffc02027c8:	9e6fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02027cc:	000ab703          	ld	a4,0(s5)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02027d0:	120a0073          	sfence.vma	s4
ffffffffc02027d4:	b7b9                	j	ffffffffc0202722 <page_insert+0x3a>
        return -E_NO_MEM;
ffffffffc02027d6:	5571                	li	a0,-4
ffffffffc02027d8:	b79d                	j	ffffffffc020273e <page_insert+0x56>
ffffffffc02027da:	f2eff0ef          	jal	ra,ffffffffc0201f08 <pa2page.part.0>

ffffffffc02027de <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc02027de:	00004797          	auipc	a5,0x4
ffffffffc02027e2:	e5278793          	addi	a5,a5,-430 # ffffffffc0206630 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02027e6:	638c                	ld	a1,0(a5)
{
ffffffffc02027e8:	7159                	addi	sp,sp,-112
ffffffffc02027ea:	f85a                	sd	s6,48(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02027ec:	00004517          	auipc	a0,0x4
ffffffffc02027f0:	fec50513          	addi	a0,a0,-20 # ffffffffc02067d8 <default_pmm_manager+0x1a8>
    pmm_manager = &default_pmm_manager;
ffffffffc02027f4:	000a8b17          	auipc	s6,0xa8
ffffffffc02027f8:	0f4b0b13          	addi	s6,s6,244 # ffffffffc02aa8e8 <pmm_manager>
{
ffffffffc02027fc:	f486                	sd	ra,104(sp)
ffffffffc02027fe:	e8ca                	sd	s2,80(sp)
ffffffffc0202800:	e4ce                	sd	s3,72(sp)
ffffffffc0202802:	f0a2                	sd	s0,96(sp)
ffffffffc0202804:	eca6                	sd	s1,88(sp)
ffffffffc0202806:	e0d2                	sd	s4,64(sp)
ffffffffc0202808:	fc56                	sd	s5,56(sp)
ffffffffc020280a:	f45e                	sd	s7,40(sp)
ffffffffc020280c:	f062                	sd	s8,32(sp)
ffffffffc020280e:	ec66                	sd	s9,24(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc0202810:	00fb3023          	sd	a5,0(s6)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0202814:	981fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    pmm_manager->init();
ffffffffc0202818:	000b3783          	ld	a5,0(s6)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc020281c:	000a8997          	auipc	s3,0xa8
ffffffffc0202820:	0d498993          	addi	s3,s3,212 # ffffffffc02aa8f0 <va_pa_offset>
    pmm_manager->init();
ffffffffc0202824:	679c                	ld	a5,8(a5)
ffffffffc0202826:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0202828:	57f5                	li	a5,-3
ffffffffc020282a:	07fa                	slli	a5,a5,0x1e
ffffffffc020282c:	00f9b023          	sd	a5,0(s3)
    uint64_t mem_begin = get_memory_base();
ffffffffc0202830:	96afe0ef          	jal	ra,ffffffffc020099a <get_memory_base>
ffffffffc0202834:	892a                	mv	s2,a0
    uint64_t mem_size = get_memory_size();
ffffffffc0202836:	96efe0ef          	jal	ra,ffffffffc02009a4 <get_memory_size>
    if (mem_size == 0)
ffffffffc020283a:	200505e3          	beqz	a0,ffffffffc0203244 <pmm_init+0xa66>
    uint64_t mem_end = mem_begin + mem_size;
ffffffffc020283e:	84aa                	mv	s1,a0
    cprintf("physcial memory map:\n");
ffffffffc0202840:	00004517          	auipc	a0,0x4
ffffffffc0202844:	fd050513          	addi	a0,a0,-48 # ffffffffc0206810 <default_pmm_manager+0x1e0>
ffffffffc0202848:	94dfd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    uint64_t mem_end = mem_begin + mem_size;
ffffffffc020284c:	00990433          	add	s0,s2,s1
    cprintf("  memory: 0x%08lx, [0x%08lx, 0x%08lx].\n", mem_size, mem_begin,
ffffffffc0202850:	fff40693          	addi	a3,s0,-1
ffffffffc0202854:	864a                	mv	a2,s2
ffffffffc0202856:	85a6                	mv	a1,s1
ffffffffc0202858:	00004517          	auipc	a0,0x4
ffffffffc020285c:	fd050513          	addi	a0,a0,-48 # ffffffffc0206828 <default_pmm_manager+0x1f8>
ffffffffc0202860:	935fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc0202864:	c8000737          	lui	a4,0xc8000
ffffffffc0202868:	87a2                	mv	a5,s0
ffffffffc020286a:	54876163          	bltu	a4,s0,ffffffffc0202dac <pmm_init+0x5ce>
ffffffffc020286e:	757d                	lui	a0,0xfffff
ffffffffc0202870:	000a9617          	auipc	a2,0xa9
ffffffffc0202874:	0a360613          	addi	a2,a2,163 # ffffffffc02ab913 <end+0xfff>
ffffffffc0202878:	8e69                	and	a2,a2,a0
ffffffffc020287a:	000a8497          	auipc	s1,0xa8
ffffffffc020287e:	05e48493          	addi	s1,s1,94 # ffffffffc02aa8d8 <npage>
ffffffffc0202882:	00c7d513          	srli	a0,a5,0xc
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0202886:	000a8b97          	auipc	s7,0xa8
ffffffffc020288a:	05ab8b93          	addi	s7,s7,90 # ffffffffc02aa8e0 <pages>
    npage = maxpa / PGSIZE;
ffffffffc020288e:	e088                	sd	a0,0(s1)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0202890:	00cbb023          	sd	a2,0(s7)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0202894:	000807b7          	lui	a5,0x80
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0202898:	86b2                	mv	a3,a2
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc020289a:	02f50863          	beq	a0,a5,ffffffffc02028ca <pmm_init+0xec>
ffffffffc020289e:	4781                	li	a5,0
ffffffffc02028a0:	4585                	li	a1,1
ffffffffc02028a2:	fff806b7          	lui	a3,0xfff80
        SetPageReserved(pages + i);
ffffffffc02028a6:	00679513          	slli	a0,a5,0x6
ffffffffc02028aa:	9532                	add	a0,a0,a2
ffffffffc02028ac:	00850713          	addi	a4,a0,8 # fffffffffffff008 <end+0x3fd546f4>
ffffffffc02028b0:	40b7302f          	amoor.d	zero,a1,(a4)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc02028b4:	6088                	ld	a0,0(s1)
ffffffffc02028b6:	0785                	addi	a5,a5,1
        SetPageReserved(pages + i);
ffffffffc02028b8:	000bb603          	ld	a2,0(s7)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc02028bc:	00d50733          	add	a4,a0,a3
ffffffffc02028c0:	fee7e3e3          	bltu	a5,a4,ffffffffc02028a6 <pmm_init+0xc8>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02028c4:	071a                	slli	a4,a4,0x6
ffffffffc02028c6:	00e606b3          	add	a3,a2,a4
ffffffffc02028ca:	c02007b7          	lui	a5,0xc0200
ffffffffc02028ce:	2ef6ece3          	bltu	a3,a5,ffffffffc02033c6 <pmm_init+0xbe8>
ffffffffc02028d2:	0009b583          	ld	a1,0(s3)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc02028d6:	77fd                	lui	a5,0xfffff
ffffffffc02028d8:	8c7d                	and	s0,s0,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02028da:	8e8d                	sub	a3,a3,a1
    if (freemem < mem_end)
ffffffffc02028dc:	5086eb63          	bltu	a3,s0,ffffffffc0202df2 <pmm_init+0x614>
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc02028e0:	00004517          	auipc	a0,0x4
ffffffffc02028e4:	f7050513          	addi	a0,a0,-144 # ffffffffc0206850 <default_pmm_manager+0x220>
ffffffffc02028e8:	8adfd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    return page;
}

static void check_alloc_page(void)
{
    pmm_manager->check();
ffffffffc02028ec:	000b3783          	ld	a5,0(s6)
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc02028f0:	000a8917          	auipc	s2,0xa8
ffffffffc02028f4:	fe090913          	addi	s2,s2,-32 # ffffffffc02aa8d0 <boot_pgdir_va>
    pmm_manager->check();
ffffffffc02028f8:	7b9c                	ld	a5,48(a5)
ffffffffc02028fa:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc02028fc:	00004517          	auipc	a0,0x4
ffffffffc0202900:	f6c50513          	addi	a0,a0,-148 # ffffffffc0206868 <default_pmm_manager+0x238>
ffffffffc0202904:	891fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc0202908:	00007697          	auipc	a3,0x7
ffffffffc020290c:	6f868693          	addi	a3,a3,1784 # ffffffffc020a000 <boot_page_table_sv39>
ffffffffc0202910:	00d93023          	sd	a3,0(s2)
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc0202914:	c02007b7          	lui	a5,0xc0200
ffffffffc0202918:	28f6ebe3          	bltu	a3,a5,ffffffffc02033ae <pmm_init+0xbd0>
ffffffffc020291c:	0009b783          	ld	a5,0(s3)
ffffffffc0202920:	8e9d                	sub	a3,a3,a5
ffffffffc0202922:	000a8797          	auipc	a5,0xa8
ffffffffc0202926:	fad7b323          	sd	a3,-90(a5) # ffffffffc02aa8c8 <boot_pgdir_pa>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020292a:	100027f3          	csrr	a5,sstatus
ffffffffc020292e:	8b89                	andi	a5,a5,2
ffffffffc0202930:	4a079763          	bnez	a5,ffffffffc0202dde <pmm_init+0x600>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202934:	000b3783          	ld	a5,0(s6)
ffffffffc0202938:	779c                	ld	a5,40(a5)
ffffffffc020293a:	9782                	jalr	a5
ffffffffc020293c:	842a                	mv	s0,a0
    // so npage is always larger than KMEMSIZE / PGSIZE
    size_t nr_free_store;

    nr_free_store = nr_free_pages();

    assert(npage <= KERNTOP / PGSIZE);
ffffffffc020293e:	6098                	ld	a4,0(s1)
ffffffffc0202940:	c80007b7          	lui	a5,0xc8000
ffffffffc0202944:	83b1                	srli	a5,a5,0xc
ffffffffc0202946:	66e7e363          	bltu	a5,a4,ffffffffc0202fac <pmm_init+0x7ce>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc020294a:	00093503          	ld	a0,0(s2)
ffffffffc020294e:	62050f63          	beqz	a0,ffffffffc0202f8c <pmm_init+0x7ae>
ffffffffc0202952:	03451793          	slli	a5,a0,0x34
ffffffffc0202956:	62079b63          	bnez	a5,ffffffffc0202f8c <pmm_init+0x7ae>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc020295a:	4601                	li	a2,0
ffffffffc020295c:	4581                	li	a1,0
ffffffffc020295e:	8c3ff0ef          	jal	ra,ffffffffc0202220 <get_page>
ffffffffc0202962:	60051563          	bnez	a0,ffffffffc0202f6c <pmm_init+0x78e>
ffffffffc0202966:	100027f3          	csrr	a5,sstatus
ffffffffc020296a:	8b89                	andi	a5,a5,2
ffffffffc020296c:	44079e63          	bnez	a5,ffffffffc0202dc8 <pmm_init+0x5ea>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202970:	000b3783          	ld	a5,0(s6)
ffffffffc0202974:	4505                	li	a0,1
ffffffffc0202976:	6f9c                	ld	a5,24(a5)
ffffffffc0202978:	9782                	jalr	a5
ffffffffc020297a:	8a2a                	mv	s4,a0

    struct Page *p1, *p2;
    p1 = alloc_page();
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc020297c:	00093503          	ld	a0,0(s2)
ffffffffc0202980:	4681                	li	a3,0
ffffffffc0202982:	4601                	li	a2,0
ffffffffc0202984:	85d2                	mv	a1,s4
ffffffffc0202986:	d63ff0ef          	jal	ra,ffffffffc02026e8 <page_insert>
ffffffffc020298a:	26051ae3          	bnez	a0,ffffffffc02033fe <pmm_init+0xc20>

    pte_t *ptep;
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc020298e:	00093503          	ld	a0,0(s2)
ffffffffc0202992:	4601                	li	a2,0
ffffffffc0202994:	4581                	li	a1,0
ffffffffc0202996:	e62ff0ef          	jal	ra,ffffffffc0201ff8 <get_pte>
ffffffffc020299a:	240502e3          	beqz	a0,ffffffffc02033de <pmm_init+0xc00>
    assert(pte2page(*ptep) == p1);
ffffffffc020299e:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V))
ffffffffc02029a0:	0017f713          	andi	a4,a5,1
ffffffffc02029a4:	5a070263          	beqz	a4,ffffffffc0202f48 <pmm_init+0x76a>
    if (PPN(pa) >= npage)
ffffffffc02029a8:	6098                	ld	a4,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc02029aa:	078a                	slli	a5,a5,0x2
ffffffffc02029ac:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02029ae:	58e7fb63          	bgeu	a5,a4,ffffffffc0202f44 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc02029b2:	000bb683          	ld	a3,0(s7)
ffffffffc02029b6:	fff80637          	lui	a2,0xfff80
ffffffffc02029ba:	97b2                	add	a5,a5,a2
ffffffffc02029bc:	079a                	slli	a5,a5,0x6
ffffffffc02029be:	97b6                	add	a5,a5,a3
ffffffffc02029c0:	14fa17e3          	bne	s4,a5,ffffffffc020330e <pmm_init+0xb30>
    assert(page_ref(p1) == 1);
ffffffffc02029c4:	000a2683          	lw	a3,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8bc8>
ffffffffc02029c8:	4785                	li	a5,1
ffffffffc02029ca:	12f692e3          	bne	a3,a5,ffffffffc02032ee <pmm_init+0xb10>

    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc02029ce:	00093503          	ld	a0,0(s2)
ffffffffc02029d2:	77fd                	lui	a5,0xfffff
ffffffffc02029d4:	6114                	ld	a3,0(a0)
ffffffffc02029d6:	068a                	slli	a3,a3,0x2
ffffffffc02029d8:	8efd                	and	a3,a3,a5
ffffffffc02029da:	00c6d613          	srli	a2,a3,0xc
ffffffffc02029de:	0ee67ce3          	bgeu	a2,a4,ffffffffc02032d6 <pmm_init+0xaf8>
ffffffffc02029e2:	0009bc03          	ld	s8,0(s3)
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc02029e6:	96e2                	add	a3,a3,s8
ffffffffc02029e8:	0006ba83          	ld	s5,0(a3)
ffffffffc02029ec:	0a8a                	slli	s5,s5,0x2
ffffffffc02029ee:	00fafab3          	and	s5,s5,a5
ffffffffc02029f2:	00cad793          	srli	a5,s5,0xc
ffffffffc02029f6:	0ce7f3e3          	bgeu	a5,a4,ffffffffc02032bc <pmm_init+0xade>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc02029fa:	4601                	li	a2,0
ffffffffc02029fc:	6585                	lui	a1,0x1
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc02029fe:	9ae2                	add	s5,s5,s8
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202a00:	df8ff0ef          	jal	ra,ffffffffc0201ff8 <get_pte>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202a04:	0aa1                	addi	s5,s5,8
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202a06:	55551363          	bne	a0,s5,ffffffffc0202f4c <pmm_init+0x76e>
ffffffffc0202a0a:	100027f3          	csrr	a5,sstatus
ffffffffc0202a0e:	8b89                	andi	a5,a5,2
ffffffffc0202a10:	3a079163          	bnez	a5,ffffffffc0202db2 <pmm_init+0x5d4>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202a14:	000b3783          	ld	a5,0(s6)
ffffffffc0202a18:	4505                	li	a0,1
ffffffffc0202a1a:	6f9c                	ld	a5,24(a5)
ffffffffc0202a1c:	9782                	jalr	a5
ffffffffc0202a1e:	8c2a                	mv	s8,a0

    p2 = alloc_page();
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc0202a20:	00093503          	ld	a0,0(s2)
ffffffffc0202a24:	46d1                	li	a3,20
ffffffffc0202a26:	6605                	lui	a2,0x1
ffffffffc0202a28:	85e2                	mv	a1,s8
ffffffffc0202a2a:	cbfff0ef          	jal	ra,ffffffffc02026e8 <page_insert>
ffffffffc0202a2e:	060517e3          	bnez	a0,ffffffffc020329c <pmm_init+0xabe>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0202a32:	00093503          	ld	a0,0(s2)
ffffffffc0202a36:	4601                	li	a2,0
ffffffffc0202a38:	6585                	lui	a1,0x1
ffffffffc0202a3a:	dbeff0ef          	jal	ra,ffffffffc0201ff8 <get_pte>
ffffffffc0202a3e:	02050fe3          	beqz	a0,ffffffffc020327c <pmm_init+0xa9e>
    assert(*ptep & PTE_U);
ffffffffc0202a42:	611c                	ld	a5,0(a0)
ffffffffc0202a44:	0107f713          	andi	a4,a5,16
ffffffffc0202a48:	7c070e63          	beqz	a4,ffffffffc0203224 <pmm_init+0xa46>
    assert(*ptep & PTE_W);
ffffffffc0202a4c:	8b91                	andi	a5,a5,4
ffffffffc0202a4e:	7a078b63          	beqz	a5,ffffffffc0203204 <pmm_init+0xa26>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc0202a52:	00093503          	ld	a0,0(s2)
ffffffffc0202a56:	611c                	ld	a5,0(a0)
ffffffffc0202a58:	8bc1                	andi	a5,a5,16
ffffffffc0202a5a:	78078563          	beqz	a5,ffffffffc02031e4 <pmm_init+0xa06>
    assert(page_ref(p2) == 1);
ffffffffc0202a5e:	000c2703          	lw	a4,0(s8)
ffffffffc0202a62:	4785                	li	a5,1
ffffffffc0202a64:	76f71063          	bne	a4,a5,ffffffffc02031c4 <pmm_init+0x9e6>

    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc0202a68:	4681                	li	a3,0
ffffffffc0202a6a:	6605                	lui	a2,0x1
ffffffffc0202a6c:	85d2                	mv	a1,s4
ffffffffc0202a6e:	c7bff0ef          	jal	ra,ffffffffc02026e8 <page_insert>
ffffffffc0202a72:	72051963          	bnez	a0,ffffffffc02031a4 <pmm_init+0x9c6>
    assert(page_ref(p1) == 2);
ffffffffc0202a76:	000a2703          	lw	a4,0(s4)
ffffffffc0202a7a:	4789                	li	a5,2
ffffffffc0202a7c:	70f71463          	bne	a4,a5,ffffffffc0203184 <pmm_init+0x9a6>
    assert(page_ref(p2) == 0);
ffffffffc0202a80:	000c2783          	lw	a5,0(s8)
ffffffffc0202a84:	6e079063          	bnez	a5,ffffffffc0203164 <pmm_init+0x986>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0202a88:	00093503          	ld	a0,0(s2)
ffffffffc0202a8c:	4601                	li	a2,0
ffffffffc0202a8e:	6585                	lui	a1,0x1
ffffffffc0202a90:	d68ff0ef          	jal	ra,ffffffffc0201ff8 <get_pte>
ffffffffc0202a94:	6a050863          	beqz	a0,ffffffffc0203144 <pmm_init+0x966>
    assert(pte2page(*ptep) == p1);
ffffffffc0202a98:	6118                	ld	a4,0(a0)
    if (!(pte & PTE_V))
ffffffffc0202a9a:	00177793          	andi	a5,a4,1
ffffffffc0202a9e:	4a078563          	beqz	a5,ffffffffc0202f48 <pmm_init+0x76a>
    if (PPN(pa) >= npage)
ffffffffc0202aa2:	6094                	ld	a3,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc0202aa4:	00271793          	slli	a5,a4,0x2
ffffffffc0202aa8:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202aaa:	48d7fd63          	bgeu	a5,a3,ffffffffc0202f44 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202aae:	000bb683          	ld	a3,0(s7)
ffffffffc0202ab2:	fff80ab7          	lui	s5,0xfff80
ffffffffc0202ab6:	97d6                	add	a5,a5,s5
ffffffffc0202ab8:	079a                	slli	a5,a5,0x6
ffffffffc0202aba:	97b6                	add	a5,a5,a3
ffffffffc0202abc:	66fa1463          	bne	s4,a5,ffffffffc0203124 <pmm_init+0x946>
    assert((*ptep & PTE_U) == 0);
ffffffffc0202ac0:	8b41                	andi	a4,a4,16
ffffffffc0202ac2:	64071163          	bnez	a4,ffffffffc0203104 <pmm_init+0x926>

    page_remove(boot_pgdir_va, 0x0);
ffffffffc0202ac6:	00093503          	ld	a0,0(s2)
ffffffffc0202aca:	4581                	li	a1,0
ffffffffc0202acc:	b81ff0ef          	jal	ra,ffffffffc020264c <page_remove>
    assert(page_ref(p1) == 1);
ffffffffc0202ad0:	000a2c83          	lw	s9,0(s4)
ffffffffc0202ad4:	4785                	li	a5,1
ffffffffc0202ad6:	60fc9763          	bne	s9,a5,ffffffffc02030e4 <pmm_init+0x906>
    assert(page_ref(p2) == 0);
ffffffffc0202ada:	000c2783          	lw	a5,0(s8)
ffffffffc0202ade:	5e079363          	bnez	a5,ffffffffc02030c4 <pmm_init+0x8e6>

    page_remove(boot_pgdir_va, PGSIZE);
ffffffffc0202ae2:	00093503          	ld	a0,0(s2)
ffffffffc0202ae6:	6585                	lui	a1,0x1
ffffffffc0202ae8:	b65ff0ef          	jal	ra,ffffffffc020264c <page_remove>
    assert(page_ref(p1) == 0);
ffffffffc0202aec:	000a2783          	lw	a5,0(s4)
ffffffffc0202af0:	52079a63          	bnez	a5,ffffffffc0203024 <pmm_init+0x846>
    assert(page_ref(p2) == 0);
ffffffffc0202af4:	000c2783          	lw	a5,0(s8)
ffffffffc0202af8:	50079663          	bnez	a5,ffffffffc0203004 <pmm_init+0x826>

    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc0202afc:	00093a03          	ld	s4,0(s2)
    if (PPN(pa) >= npage)
ffffffffc0202b00:	608c                	ld	a1,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202b02:	000a3683          	ld	a3,0(s4)
ffffffffc0202b06:	068a                	slli	a3,a3,0x2
ffffffffc0202b08:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage)
ffffffffc0202b0a:	42b6fd63          	bgeu	a3,a1,ffffffffc0202f44 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202b0e:	000bb503          	ld	a0,0(s7)
ffffffffc0202b12:	96d6                	add	a3,a3,s5
ffffffffc0202b14:	069a                	slli	a3,a3,0x6
    return page->ref;
ffffffffc0202b16:	00d507b3          	add	a5,a0,a3
ffffffffc0202b1a:	439c                	lw	a5,0(a5)
ffffffffc0202b1c:	4d979463          	bne	a5,s9,ffffffffc0202fe4 <pmm_init+0x806>
    return page - pages + nbase;
ffffffffc0202b20:	8699                	srai	a3,a3,0x6
ffffffffc0202b22:	00080637          	lui	a2,0x80
ffffffffc0202b26:	96b2                	add	a3,a3,a2
    return KADDR(page2pa(page));
ffffffffc0202b28:	00c69713          	slli	a4,a3,0xc
ffffffffc0202b2c:	8331                	srli	a4,a4,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0202b2e:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202b30:	48b77e63          	bgeu	a4,a1,ffffffffc0202fcc <pmm_init+0x7ee>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
    free_page(pde2page(pd0[0]));
ffffffffc0202b34:	0009b703          	ld	a4,0(s3)
ffffffffc0202b38:	96ba                	add	a3,a3,a4
    return pa2page(PDE_ADDR(pde));
ffffffffc0202b3a:	629c                	ld	a5,0(a3)
ffffffffc0202b3c:	078a                	slli	a5,a5,0x2
ffffffffc0202b3e:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202b40:	40b7f263          	bgeu	a5,a1,ffffffffc0202f44 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202b44:	8f91                	sub	a5,a5,a2
ffffffffc0202b46:	079a                	slli	a5,a5,0x6
ffffffffc0202b48:	953e                	add	a0,a0,a5
ffffffffc0202b4a:	100027f3          	csrr	a5,sstatus
ffffffffc0202b4e:	8b89                	andi	a5,a5,2
ffffffffc0202b50:	30079963          	bnez	a5,ffffffffc0202e62 <pmm_init+0x684>
        pmm_manager->free_pages(base, n);
ffffffffc0202b54:	000b3783          	ld	a5,0(s6)
ffffffffc0202b58:	4585                	li	a1,1
ffffffffc0202b5a:	739c                	ld	a5,32(a5)
ffffffffc0202b5c:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202b5e:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage)
ffffffffc0202b62:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202b64:	078a                	slli	a5,a5,0x2
ffffffffc0202b66:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202b68:	3ce7fe63          	bgeu	a5,a4,ffffffffc0202f44 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202b6c:	000bb503          	ld	a0,0(s7)
ffffffffc0202b70:	fff80737          	lui	a4,0xfff80
ffffffffc0202b74:	97ba                	add	a5,a5,a4
ffffffffc0202b76:	079a                	slli	a5,a5,0x6
ffffffffc0202b78:	953e                	add	a0,a0,a5
ffffffffc0202b7a:	100027f3          	csrr	a5,sstatus
ffffffffc0202b7e:	8b89                	andi	a5,a5,2
ffffffffc0202b80:	2c079563          	bnez	a5,ffffffffc0202e4a <pmm_init+0x66c>
ffffffffc0202b84:	000b3783          	ld	a5,0(s6)
ffffffffc0202b88:	4585                	li	a1,1
ffffffffc0202b8a:	739c                	ld	a5,32(a5)
ffffffffc0202b8c:	9782                	jalr	a5
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc0202b8e:	00093783          	ld	a5,0(s2)
ffffffffc0202b92:	0007b023          	sd	zero,0(a5) # fffffffffffff000 <end+0x3fd546ec>
    asm volatile("sfence.vma");
ffffffffc0202b96:	12000073          	sfence.vma
ffffffffc0202b9a:	100027f3          	csrr	a5,sstatus
ffffffffc0202b9e:	8b89                	andi	a5,a5,2
ffffffffc0202ba0:	28079b63          	bnez	a5,ffffffffc0202e36 <pmm_init+0x658>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202ba4:	000b3783          	ld	a5,0(s6)
ffffffffc0202ba8:	779c                	ld	a5,40(a5)
ffffffffc0202baa:	9782                	jalr	a5
ffffffffc0202bac:	8a2a                	mv	s4,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc0202bae:	4b441b63          	bne	s0,s4,ffffffffc0203064 <pmm_init+0x886>

    cprintf("check_pgdir() succeeded!\n");
ffffffffc0202bb2:	00004517          	auipc	a0,0x4
ffffffffc0202bb6:	fde50513          	addi	a0,a0,-34 # ffffffffc0206b90 <default_pmm_manager+0x560>
ffffffffc0202bba:	ddafd0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc0202bbe:	100027f3          	csrr	a5,sstatus
ffffffffc0202bc2:	8b89                	andi	a5,a5,2
ffffffffc0202bc4:	24079f63          	bnez	a5,ffffffffc0202e22 <pmm_init+0x644>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202bc8:	000b3783          	ld	a5,0(s6)
ffffffffc0202bcc:	779c                	ld	a5,40(a5)
ffffffffc0202bce:	9782                	jalr	a5
ffffffffc0202bd0:	8c2a                	mv	s8,a0
    pte_t *ptep;
    int i;

    nr_free_store = nr_free_pages();

    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202bd2:	6098                	ld	a4,0(s1)
ffffffffc0202bd4:	c0200437          	lui	s0,0xc0200
    {
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202bd8:	7afd                	lui	s5,0xfffff
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202bda:	00c71793          	slli	a5,a4,0xc
ffffffffc0202bde:	6a05                	lui	s4,0x1
ffffffffc0202be0:	02f47c63          	bgeu	s0,a5,ffffffffc0202c18 <pmm_init+0x43a>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202be4:	00c45793          	srli	a5,s0,0xc
ffffffffc0202be8:	00093503          	ld	a0,0(s2)
ffffffffc0202bec:	2ee7ff63          	bgeu	a5,a4,ffffffffc0202eea <pmm_init+0x70c>
ffffffffc0202bf0:	0009b583          	ld	a1,0(s3)
ffffffffc0202bf4:	4601                	li	a2,0
ffffffffc0202bf6:	95a2                	add	a1,a1,s0
ffffffffc0202bf8:	c00ff0ef          	jal	ra,ffffffffc0201ff8 <get_pte>
ffffffffc0202bfc:	32050463          	beqz	a0,ffffffffc0202f24 <pmm_init+0x746>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202c00:	611c                	ld	a5,0(a0)
ffffffffc0202c02:	078a                	slli	a5,a5,0x2
ffffffffc0202c04:	0157f7b3          	and	a5,a5,s5
ffffffffc0202c08:	2e879e63          	bne	a5,s0,ffffffffc0202f04 <pmm_init+0x726>
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202c0c:	6098                	ld	a4,0(s1)
ffffffffc0202c0e:	9452                	add	s0,s0,s4
ffffffffc0202c10:	00c71793          	slli	a5,a4,0xc
ffffffffc0202c14:	fcf468e3          	bltu	s0,a5,ffffffffc0202be4 <pmm_init+0x406>
    }

    assert(boot_pgdir_va[0] == 0);
ffffffffc0202c18:	00093783          	ld	a5,0(s2)
ffffffffc0202c1c:	639c                	ld	a5,0(a5)
ffffffffc0202c1e:	42079363          	bnez	a5,ffffffffc0203044 <pmm_init+0x866>
ffffffffc0202c22:	100027f3          	csrr	a5,sstatus
ffffffffc0202c26:	8b89                	andi	a5,a5,2
ffffffffc0202c28:	24079963          	bnez	a5,ffffffffc0202e7a <pmm_init+0x69c>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202c2c:	000b3783          	ld	a5,0(s6)
ffffffffc0202c30:	4505                	li	a0,1
ffffffffc0202c32:	6f9c                	ld	a5,24(a5)
ffffffffc0202c34:	9782                	jalr	a5
ffffffffc0202c36:	8a2a                	mv	s4,a0

    struct Page *p;
    p = alloc_page();
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0202c38:	00093503          	ld	a0,0(s2)
ffffffffc0202c3c:	4699                	li	a3,6
ffffffffc0202c3e:	10000613          	li	a2,256
ffffffffc0202c42:	85d2                	mv	a1,s4
ffffffffc0202c44:	aa5ff0ef          	jal	ra,ffffffffc02026e8 <page_insert>
ffffffffc0202c48:	44051e63          	bnez	a0,ffffffffc02030a4 <pmm_init+0x8c6>
    assert(page_ref(p) == 1);
ffffffffc0202c4c:	000a2703          	lw	a4,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8bc8>
ffffffffc0202c50:	4785                	li	a5,1
ffffffffc0202c52:	42f71963          	bne	a4,a5,ffffffffc0203084 <pmm_init+0x8a6>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc0202c56:	00093503          	ld	a0,0(s2)
ffffffffc0202c5a:	6405                	lui	s0,0x1
ffffffffc0202c5c:	4699                	li	a3,6
ffffffffc0202c5e:	10040613          	addi	a2,s0,256 # 1100 <_binary_obj___user_faultread_out_size-0x8ac8>
ffffffffc0202c62:	85d2                	mv	a1,s4
ffffffffc0202c64:	a85ff0ef          	jal	ra,ffffffffc02026e8 <page_insert>
ffffffffc0202c68:	72051363          	bnez	a0,ffffffffc020338e <pmm_init+0xbb0>
    assert(page_ref(p) == 2);
ffffffffc0202c6c:	000a2703          	lw	a4,0(s4)
ffffffffc0202c70:	4789                	li	a5,2
ffffffffc0202c72:	6ef71e63          	bne	a4,a5,ffffffffc020336e <pmm_init+0xb90>

    const char *str = "ucore: Hello world!!";
    strcpy((void *)0x100, str);
ffffffffc0202c76:	00004597          	auipc	a1,0x4
ffffffffc0202c7a:	06258593          	addi	a1,a1,98 # ffffffffc0206cd8 <default_pmm_manager+0x6a8>
ffffffffc0202c7e:	10000513          	li	a0,256
ffffffffc0202c82:	293020ef          	jal	ra,ffffffffc0205714 <strcpy>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc0202c86:	10040593          	addi	a1,s0,256
ffffffffc0202c8a:	10000513          	li	a0,256
ffffffffc0202c8e:	299020ef          	jal	ra,ffffffffc0205726 <strcmp>
ffffffffc0202c92:	6a051e63          	bnez	a0,ffffffffc020334e <pmm_init+0xb70>
    return page - pages + nbase;
ffffffffc0202c96:	000bb683          	ld	a3,0(s7)
ffffffffc0202c9a:	00080737          	lui	a4,0x80
    return KADDR(page2pa(page));
ffffffffc0202c9e:	547d                	li	s0,-1
    return page - pages + nbase;
ffffffffc0202ca0:	40da06b3          	sub	a3,s4,a3
ffffffffc0202ca4:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0202ca6:	609c                	ld	a5,0(s1)
    return page - pages + nbase;
ffffffffc0202ca8:	96ba                	add	a3,a3,a4
    return KADDR(page2pa(page));
ffffffffc0202caa:	8031                	srli	s0,s0,0xc
ffffffffc0202cac:	0086f733          	and	a4,a3,s0
    return page2ppn(page) << PGSHIFT;
ffffffffc0202cb0:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202cb2:	30f77d63          	bgeu	a4,a5,ffffffffc0202fcc <pmm_init+0x7ee>

    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0202cb6:	0009b783          	ld	a5,0(s3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202cba:	10000513          	li	a0,256
    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0202cbe:	96be                	add	a3,a3,a5
ffffffffc0202cc0:	10068023          	sb	zero,256(a3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202cc4:	21b020ef          	jal	ra,ffffffffc02056de <strlen>
ffffffffc0202cc8:	66051363          	bnez	a0,ffffffffc020332e <pmm_init+0xb50>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
ffffffffc0202ccc:	00093a83          	ld	s5,0(s2)
    if (PPN(pa) >= npage)
ffffffffc0202cd0:	609c                	ld	a5,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202cd2:	000ab683          	ld	a3,0(s5) # fffffffffffff000 <end+0x3fd546ec>
ffffffffc0202cd6:	068a                	slli	a3,a3,0x2
ffffffffc0202cd8:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage)
ffffffffc0202cda:	26f6f563          	bgeu	a3,a5,ffffffffc0202f44 <pmm_init+0x766>
    return KADDR(page2pa(page));
ffffffffc0202cde:	8c75                	and	s0,s0,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc0202ce0:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202ce2:	2ef47563          	bgeu	s0,a5,ffffffffc0202fcc <pmm_init+0x7ee>
ffffffffc0202ce6:	0009b403          	ld	s0,0(s3)
ffffffffc0202cea:	9436                	add	s0,s0,a3
ffffffffc0202cec:	100027f3          	csrr	a5,sstatus
ffffffffc0202cf0:	8b89                	andi	a5,a5,2
ffffffffc0202cf2:	1e079163          	bnez	a5,ffffffffc0202ed4 <pmm_init+0x6f6>
        pmm_manager->free_pages(base, n);
ffffffffc0202cf6:	000b3783          	ld	a5,0(s6)
ffffffffc0202cfa:	4585                	li	a1,1
ffffffffc0202cfc:	8552                	mv	a0,s4
ffffffffc0202cfe:	739c                	ld	a5,32(a5)
ffffffffc0202d00:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202d02:	601c                	ld	a5,0(s0)
    if (PPN(pa) >= npage)
ffffffffc0202d04:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202d06:	078a                	slli	a5,a5,0x2
ffffffffc0202d08:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202d0a:	22e7fd63          	bgeu	a5,a4,ffffffffc0202f44 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202d0e:	000bb503          	ld	a0,0(s7)
ffffffffc0202d12:	fff80737          	lui	a4,0xfff80
ffffffffc0202d16:	97ba                	add	a5,a5,a4
ffffffffc0202d18:	079a                	slli	a5,a5,0x6
ffffffffc0202d1a:	953e                	add	a0,a0,a5
ffffffffc0202d1c:	100027f3          	csrr	a5,sstatus
ffffffffc0202d20:	8b89                	andi	a5,a5,2
ffffffffc0202d22:	18079d63          	bnez	a5,ffffffffc0202ebc <pmm_init+0x6de>
ffffffffc0202d26:	000b3783          	ld	a5,0(s6)
ffffffffc0202d2a:	4585                	li	a1,1
ffffffffc0202d2c:	739c                	ld	a5,32(a5)
ffffffffc0202d2e:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202d30:	000ab783          	ld	a5,0(s5)
    if (PPN(pa) >= npage)
ffffffffc0202d34:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202d36:	078a                	slli	a5,a5,0x2
ffffffffc0202d38:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202d3a:	20e7f563          	bgeu	a5,a4,ffffffffc0202f44 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202d3e:	000bb503          	ld	a0,0(s7)
ffffffffc0202d42:	fff80737          	lui	a4,0xfff80
ffffffffc0202d46:	97ba                	add	a5,a5,a4
ffffffffc0202d48:	079a                	slli	a5,a5,0x6
ffffffffc0202d4a:	953e                	add	a0,a0,a5
ffffffffc0202d4c:	100027f3          	csrr	a5,sstatus
ffffffffc0202d50:	8b89                	andi	a5,a5,2
ffffffffc0202d52:	14079963          	bnez	a5,ffffffffc0202ea4 <pmm_init+0x6c6>
ffffffffc0202d56:	000b3783          	ld	a5,0(s6)
ffffffffc0202d5a:	4585                	li	a1,1
ffffffffc0202d5c:	739c                	ld	a5,32(a5)
ffffffffc0202d5e:	9782                	jalr	a5
    free_page(p);
    free_page(pde2page(pd0[0]));
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc0202d60:	00093783          	ld	a5,0(s2)
ffffffffc0202d64:	0007b023          	sd	zero,0(a5)
    asm volatile("sfence.vma");
ffffffffc0202d68:	12000073          	sfence.vma
ffffffffc0202d6c:	100027f3          	csrr	a5,sstatus
ffffffffc0202d70:	8b89                	andi	a5,a5,2
ffffffffc0202d72:	10079f63          	bnez	a5,ffffffffc0202e90 <pmm_init+0x6b2>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202d76:	000b3783          	ld	a5,0(s6)
ffffffffc0202d7a:	779c                	ld	a5,40(a5)
ffffffffc0202d7c:	9782                	jalr	a5
ffffffffc0202d7e:	842a                	mv	s0,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc0202d80:	4c8c1e63          	bne	s8,s0,ffffffffc020325c <pmm_init+0xa7e>

    cprintf("check_boot_pgdir() succeeded!\n");
ffffffffc0202d84:	00004517          	auipc	a0,0x4
ffffffffc0202d88:	fcc50513          	addi	a0,a0,-52 # ffffffffc0206d50 <default_pmm_manager+0x720>
ffffffffc0202d8c:	c08fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
}
ffffffffc0202d90:	7406                	ld	s0,96(sp)
ffffffffc0202d92:	70a6                	ld	ra,104(sp)
ffffffffc0202d94:	64e6                	ld	s1,88(sp)
ffffffffc0202d96:	6946                	ld	s2,80(sp)
ffffffffc0202d98:	69a6                	ld	s3,72(sp)
ffffffffc0202d9a:	6a06                	ld	s4,64(sp)
ffffffffc0202d9c:	7ae2                	ld	s5,56(sp)
ffffffffc0202d9e:	7b42                	ld	s6,48(sp)
ffffffffc0202da0:	7ba2                	ld	s7,40(sp)
ffffffffc0202da2:	7c02                	ld	s8,32(sp)
ffffffffc0202da4:	6ce2                	ld	s9,24(sp)
ffffffffc0202da6:	6165                	addi	sp,sp,112
    kmalloc_init();
ffffffffc0202da8:	f97fe06f          	j	ffffffffc0201d3e <kmalloc_init>
    npage = maxpa / PGSIZE;
ffffffffc0202dac:	c80007b7          	lui	a5,0xc8000
ffffffffc0202db0:	bc7d                	j	ffffffffc020286e <pmm_init+0x90>
        intr_disable();
ffffffffc0202db2:	c03fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202db6:	000b3783          	ld	a5,0(s6)
ffffffffc0202dba:	4505                	li	a0,1
ffffffffc0202dbc:	6f9c                	ld	a5,24(a5)
ffffffffc0202dbe:	9782                	jalr	a5
ffffffffc0202dc0:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc0202dc2:	bedfd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202dc6:	b9a9                	j	ffffffffc0202a20 <pmm_init+0x242>
        intr_disable();
ffffffffc0202dc8:	bedfd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0202dcc:	000b3783          	ld	a5,0(s6)
ffffffffc0202dd0:	4505                	li	a0,1
ffffffffc0202dd2:	6f9c                	ld	a5,24(a5)
ffffffffc0202dd4:	9782                	jalr	a5
ffffffffc0202dd6:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202dd8:	bd7fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202ddc:	b645                	j	ffffffffc020297c <pmm_init+0x19e>
        intr_disable();
ffffffffc0202dde:	bd7fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202de2:	000b3783          	ld	a5,0(s6)
ffffffffc0202de6:	779c                	ld	a5,40(a5)
ffffffffc0202de8:	9782                	jalr	a5
ffffffffc0202dea:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202dec:	bc3fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202df0:	b6b9                	j	ffffffffc020293e <pmm_init+0x160>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0202df2:	6705                	lui	a4,0x1
ffffffffc0202df4:	177d                	addi	a4,a4,-1
ffffffffc0202df6:	96ba                	add	a3,a3,a4
ffffffffc0202df8:	8ff5                	and	a5,a5,a3
    if (PPN(pa) >= npage)
ffffffffc0202dfa:	00c7d713          	srli	a4,a5,0xc
ffffffffc0202dfe:	14a77363          	bgeu	a4,a0,ffffffffc0202f44 <pmm_init+0x766>
    pmm_manager->init_memmap(base, n);
ffffffffc0202e02:	000b3683          	ld	a3,0(s6)
    return &pages[PPN(pa) - nbase];
ffffffffc0202e06:	fff80537          	lui	a0,0xfff80
ffffffffc0202e0a:	972a                	add	a4,a4,a0
ffffffffc0202e0c:	6a94                	ld	a3,16(a3)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0202e0e:	8c1d                	sub	s0,s0,a5
ffffffffc0202e10:	00671513          	slli	a0,a4,0x6
    pmm_manager->init_memmap(base, n);
ffffffffc0202e14:	00c45593          	srli	a1,s0,0xc
ffffffffc0202e18:	9532                	add	a0,a0,a2
ffffffffc0202e1a:	9682                	jalr	a3
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc0202e1c:	0009b583          	ld	a1,0(s3)
}
ffffffffc0202e20:	b4c1                	j	ffffffffc02028e0 <pmm_init+0x102>
        intr_disable();
ffffffffc0202e22:	b93fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202e26:	000b3783          	ld	a5,0(s6)
ffffffffc0202e2a:	779c                	ld	a5,40(a5)
ffffffffc0202e2c:	9782                	jalr	a5
ffffffffc0202e2e:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc0202e30:	b7ffd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202e34:	bb79                	j	ffffffffc0202bd2 <pmm_init+0x3f4>
        intr_disable();
ffffffffc0202e36:	b7ffd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0202e3a:	000b3783          	ld	a5,0(s6)
ffffffffc0202e3e:	779c                	ld	a5,40(a5)
ffffffffc0202e40:	9782                	jalr	a5
ffffffffc0202e42:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202e44:	b6bfd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202e48:	b39d                	j	ffffffffc0202bae <pmm_init+0x3d0>
ffffffffc0202e4a:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202e4c:	b69fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202e50:	000b3783          	ld	a5,0(s6)
ffffffffc0202e54:	6522                	ld	a0,8(sp)
ffffffffc0202e56:	4585                	li	a1,1
ffffffffc0202e58:	739c                	ld	a5,32(a5)
ffffffffc0202e5a:	9782                	jalr	a5
        intr_enable();
ffffffffc0202e5c:	b53fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202e60:	b33d                	j	ffffffffc0202b8e <pmm_init+0x3b0>
ffffffffc0202e62:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202e64:	b51fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0202e68:	000b3783          	ld	a5,0(s6)
ffffffffc0202e6c:	6522                	ld	a0,8(sp)
ffffffffc0202e6e:	4585                	li	a1,1
ffffffffc0202e70:	739c                	ld	a5,32(a5)
ffffffffc0202e72:	9782                	jalr	a5
        intr_enable();
ffffffffc0202e74:	b3bfd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202e78:	b1dd                	j	ffffffffc0202b5e <pmm_init+0x380>
        intr_disable();
ffffffffc0202e7a:	b3bfd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202e7e:	000b3783          	ld	a5,0(s6)
ffffffffc0202e82:	4505                	li	a0,1
ffffffffc0202e84:	6f9c                	ld	a5,24(a5)
ffffffffc0202e86:	9782                	jalr	a5
ffffffffc0202e88:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202e8a:	b25fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202e8e:	b36d                	j	ffffffffc0202c38 <pmm_init+0x45a>
        intr_disable();
ffffffffc0202e90:	b25fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202e94:	000b3783          	ld	a5,0(s6)
ffffffffc0202e98:	779c                	ld	a5,40(a5)
ffffffffc0202e9a:	9782                	jalr	a5
ffffffffc0202e9c:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202e9e:	b11fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202ea2:	bdf9                	j	ffffffffc0202d80 <pmm_init+0x5a2>
ffffffffc0202ea4:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202ea6:	b0ffd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202eaa:	000b3783          	ld	a5,0(s6)
ffffffffc0202eae:	6522                	ld	a0,8(sp)
ffffffffc0202eb0:	4585                	li	a1,1
ffffffffc0202eb2:	739c                	ld	a5,32(a5)
ffffffffc0202eb4:	9782                	jalr	a5
        intr_enable();
ffffffffc0202eb6:	af9fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202eba:	b55d                	j	ffffffffc0202d60 <pmm_init+0x582>
ffffffffc0202ebc:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202ebe:	af7fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0202ec2:	000b3783          	ld	a5,0(s6)
ffffffffc0202ec6:	6522                	ld	a0,8(sp)
ffffffffc0202ec8:	4585                	li	a1,1
ffffffffc0202eca:	739c                	ld	a5,32(a5)
ffffffffc0202ecc:	9782                	jalr	a5
        intr_enable();
ffffffffc0202ece:	ae1fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202ed2:	bdb9                	j	ffffffffc0202d30 <pmm_init+0x552>
        intr_disable();
ffffffffc0202ed4:	ae1fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0202ed8:	000b3783          	ld	a5,0(s6)
ffffffffc0202edc:	4585                	li	a1,1
ffffffffc0202ede:	8552                	mv	a0,s4
ffffffffc0202ee0:	739c                	ld	a5,32(a5)
ffffffffc0202ee2:	9782                	jalr	a5
        intr_enable();
ffffffffc0202ee4:	acbfd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202ee8:	bd29                	j	ffffffffc0202d02 <pmm_init+0x524>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202eea:	86a2                	mv	a3,s0
ffffffffc0202eec:	00003617          	auipc	a2,0x3
ffffffffc0202ef0:	77c60613          	addi	a2,a2,1916 # ffffffffc0206668 <default_pmm_manager+0x38>
ffffffffc0202ef4:	23900593          	li	a1,569
ffffffffc0202ef8:	00004517          	auipc	a0,0x4
ffffffffc0202efc:	88850513          	addi	a0,a0,-1912 # ffffffffc0206780 <default_pmm_manager+0x150>
ffffffffc0202f00:	d8efd0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202f04:	00004697          	auipc	a3,0x4
ffffffffc0202f08:	cec68693          	addi	a3,a3,-788 # ffffffffc0206bf0 <default_pmm_manager+0x5c0>
ffffffffc0202f0c:	00003617          	auipc	a2,0x3
ffffffffc0202f10:	37460613          	addi	a2,a2,884 # ffffffffc0206280 <commands+0x868>
ffffffffc0202f14:	23a00593          	li	a1,570
ffffffffc0202f18:	00004517          	auipc	a0,0x4
ffffffffc0202f1c:	86850513          	addi	a0,a0,-1944 # ffffffffc0206780 <default_pmm_manager+0x150>
ffffffffc0202f20:	d6efd0ef          	jal	ra,ffffffffc020048e <__panic>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202f24:	00004697          	auipc	a3,0x4
ffffffffc0202f28:	c8c68693          	addi	a3,a3,-884 # ffffffffc0206bb0 <default_pmm_manager+0x580>
ffffffffc0202f2c:	00003617          	auipc	a2,0x3
ffffffffc0202f30:	35460613          	addi	a2,a2,852 # ffffffffc0206280 <commands+0x868>
ffffffffc0202f34:	23900593          	li	a1,569
ffffffffc0202f38:	00004517          	auipc	a0,0x4
ffffffffc0202f3c:	84850513          	addi	a0,a0,-1976 # ffffffffc0206780 <default_pmm_manager+0x150>
ffffffffc0202f40:	d4efd0ef          	jal	ra,ffffffffc020048e <__panic>
ffffffffc0202f44:	fc5fe0ef          	jal	ra,ffffffffc0201f08 <pa2page.part.0>
ffffffffc0202f48:	fddfe0ef          	jal	ra,ffffffffc0201f24 <pte2page.part.0>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202f4c:	00004697          	auipc	a3,0x4
ffffffffc0202f50:	a5c68693          	addi	a3,a3,-1444 # ffffffffc02069a8 <default_pmm_manager+0x378>
ffffffffc0202f54:	00003617          	auipc	a2,0x3
ffffffffc0202f58:	32c60613          	addi	a2,a2,812 # ffffffffc0206280 <commands+0x868>
ffffffffc0202f5c:	20900593          	li	a1,521
ffffffffc0202f60:	00004517          	auipc	a0,0x4
ffffffffc0202f64:	82050513          	addi	a0,a0,-2016 # ffffffffc0206780 <default_pmm_manager+0x150>
ffffffffc0202f68:	d26fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc0202f6c:	00004697          	auipc	a3,0x4
ffffffffc0202f70:	97c68693          	addi	a3,a3,-1668 # ffffffffc02068e8 <default_pmm_manager+0x2b8>
ffffffffc0202f74:	00003617          	auipc	a2,0x3
ffffffffc0202f78:	30c60613          	addi	a2,a2,780 # ffffffffc0206280 <commands+0x868>
ffffffffc0202f7c:	1fc00593          	li	a1,508
ffffffffc0202f80:	00004517          	auipc	a0,0x4
ffffffffc0202f84:	80050513          	addi	a0,a0,-2048 # ffffffffc0206780 <default_pmm_manager+0x150>
ffffffffc0202f88:	d06fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc0202f8c:	00004697          	auipc	a3,0x4
ffffffffc0202f90:	91c68693          	addi	a3,a3,-1764 # ffffffffc02068a8 <default_pmm_manager+0x278>
ffffffffc0202f94:	00003617          	auipc	a2,0x3
ffffffffc0202f98:	2ec60613          	addi	a2,a2,748 # ffffffffc0206280 <commands+0x868>
ffffffffc0202f9c:	1fb00593          	li	a1,507
ffffffffc0202fa0:	00003517          	auipc	a0,0x3
ffffffffc0202fa4:	7e050513          	addi	a0,a0,2016 # ffffffffc0206780 <default_pmm_manager+0x150>
ffffffffc0202fa8:	ce6fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(npage <= KERNTOP / PGSIZE);
ffffffffc0202fac:	00004697          	auipc	a3,0x4
ffffffffc0202fb0:	8dc68693          	addi	a3,a3,-1828 # ffffffffc0206888 <default_pmm_manager+0x258>
ffffffffc0202fb4:	00003617          	auipc	a2,0x3
ffffffffc0202fb8:	2cc60613          	addi	a2,a2,716 # ffffffffc0206280 <commands+0x868>
ffffffffc0202fbc:	1fa00593          	li	a1,506
ffffffffc0202fc0:	00003517          	auipc	a0,0x3
ffffffffc0202fc4:	7c050513          	addi	a0,a0,1984 # ffffffffc0206780 <default_pmm_manager+0x150>
ffffffffc0202fc8:	cc6fd0ef          	jal	ra,ffffffffc020048e <__panic>
    return KADDR(page2pa(page));
ffffffffc0202fcc:	00003617          	auipc	a2,0x3
ffffffffc0202fd0:	69c60613          	addi	a2,a2,1692 # ffffffffc0206668 <default_pmm_manager+0x38>
ffffffffc0202fd4:	07100593          	li	a1,113
ffffffffc0202fd8:	00003517          	auipc	a0,0x3
ffffffffc0202fdc:	6b850513          	addi	a0,a0,1720 # ffffffffc0206690 <default_pmm_manager+0x60>
ffffffffc0202fe0:	caefd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc0202fe4:	00004697          	auipc	a3,0x4
ffffffffc0202fe8:	b5468693          	addi	a3,a3,-1196 # ffffffffc0206b38 <default_pmm_manager+0x508>
ffffffffc0202fec:	00003617          	auipc	a2,0x3
ffffffffc0202ff0:	29460613          	addi	a2,a2,660 # ffffffffc0206280 <commands+0x868>
ffffffffc0202ff4:	22200593          	li	a1,546
ffffffffc0202ff8:	00003517          	auipc	a0,0x3
ffffffffc0202ffc:	78850513          	addi	a0,a0,1928 # ffffffffc0206780 <default_pmm_manager+0x150>
ffffffffc0203000:	c8efd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0203004:	00004697          	auipc	a3,0x4
ffffffffc0203008:	aec68693          	addi	a3,a3,-1300 # ffffffffc0206af0 <default_pmm_manager+0x4c0>
ffffffffc020300c:	00003617          	auipc	a2,0x3
ffffffffc0203010:	27460613          	addi	a2,a2,628 # ffffffffc0206280 <commands+0x868>
ffffffffc0203014:	22000593          	li	a1,544
ffffffffc0203018:	00003517          	auipc	a0,0x3
ffffffffc020301c:	76850513          	addi	a0,a0,1896 # ffffffffc0206780 <default_pmm_manager+0x150>
ffffffffc0203020:	c6efd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p1) == 0);
ffffffffc0203024:	00004697          	auipc	a3,0x4
ffffffffc0203028:	afc68693          	addi	a3,a3,-1284 # ffffffffc0206b20 <default_pmm_manager+0x4f0>
ffffffffc020302c:	00003617          	auipc	a2,0x3
ffffffffc0203030:	25460613          	addi	a2,a2,596 # ffffffffc0206280 <commands+0x868>
ffffffffc0203034:	21f00593          	li	a1,543
ffffffffc0203038:	00003517          	auipc	a0,0x3
ffffffffc020303c:	74850513          	addi	a0,a0,1864 # ffffffffc0206780 <default_pmm_manager+0x150>
ffffffffc0203040:	c4efd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(boot_pgdir_va[0] == 0);
ffffffffc0203044:	00004697          	auipc	a3,0x4
ffffffffc0203048:	bc468693          	addi	a3,a3,-1084 # ffffffffc0206c08 <default_pmm_manager+0x5d8>
ffffffffc020304c:	00003617          	auipc	a2,0x3
ffffffffc0203050:	23460613          	addi	a2,a2,564 # ffffffffc0206280 <commands+0x868>
ffffffffc0203054:	23d00593          	li	a1,573
ffffffffc0203058:	00003517          	auipc	a0,0x3
ffffffffc020305c:	72850513          	addi	a0,a0,1832 # ffffffffc0206780 <default_pmm_manager+0x150>
ffffffffc0203060:	c2efd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc0203064:	00004697          	auipc	a3,0x4
ffffffffc0203068:	b0468693          	addi	a3,a3,-1276 # ffffffffc0206b68 <default_pmm_manager+0x538>
ffffffffc020306c:	00003617          	auipc	a2,0x3
ffffffffc0203070:	21460613          	addi	a2,a2,532 # ffffffffc0206280 <commands+0x868>
ffffffffc0203074:	22a00593          	li	a1,554
ffffffffc0203078:	00003517          	auipc	a0,0x3
ffffffffc020307c:	70850513          	addi	a0,a0,1800 # ffffffffc0206780 <default_pmm_manager+0x150>
ffffffffc0203080:	c0efd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p) == 1);
ffffffffc0203084:	00004697          	auipc	a3,0x4
ffffffffc0203088:	bdc68693          	addi	a3,a3,-1060 # ffffffffc0206c60 <default_pmm_manager+0x630>
ffffffffc020308c:	00003617          	auipc	a2,0x3
ffffffffc0203090:	1f460613          	addi	a2,a2,500 # ffffffffc0206280 <commands+0x868>
ffffffffc0203094:	24200593          	li	a1,578
ffffffffc0203098:	00003517          	auipc	a0,0x3
ffffffffc020309c:	6e850513          	addi	a0,a0,1768 # ffffffffc0206780 <default_pmm_manager+0x150>
ffffffffc02030a0:	beefd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc02030a4:	00004697          	auipc	a3,0x4
ffffffffc02030a8:	b7c68693          	addi	a3,a3,-1156 # ffffffffc0206c20 <default_pmm_manager+0x5f0>
ffffffffc02030ac:	00003617          	auipc	a2,0x3
ffffffffc02030b0:	1d460613          	addi	a2,a2,468 # ffffffffc0206280 <commands+0x868>
ffffffffc02030b4:	24100593          	li	a1,577
ffffffffc02030b8:	00003517          	auipc	a0,0x3
ffffffffc02030bc:	6c850513          	addi	a0,a0,1736 # ffffffffc0206780 <default_pmm_manager+0x150>
ffffffffc02030c0:	bcefd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p2) == 0);
ffffffffc02030c4:	00004697          	auipc	a3,0x4
ffffffffc02030c8:	a2c68693          	addi	a3,a3,-1492 # ffffffffc0206af0 <default_pmm_manager+0x4c0>
ffffffffc02030cc:	00003617          	auipc	a2,0x3
ffffffffc02030d0:	1b460613          	addi	a2,a2,436 # ffffffffc0206280 <commands+0x868>
ffffffffc02030d4:	21c00593          	li	a1,540
ffffffffc02030d8:	00003517          	auipc	a0,0x3
ffffffffc02030dc:	6a850513          	addi	a0,a0,1704 # ffffffffc0206780 <default_pmm_manager+0x150>
ffffffffc02030e0:	baefd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p1) == 1);
ffffffffc02030e4:	00004697          	auipc	a3,0x4
ffffffffc02030e8:	8ac68693          	addi	a3,a3,-1876 # ffffffffc0206990 <default_pmm_manager+0x360>
ffffffffc02030ec:	00003617          	auipc	a2,0x3
ffffffffc02030f0:	19460613          	addi	a2,a2,404 # ffffffffc0206280 <commands+0x868>
ffffffffc02030f4:	21b00593          	li	a1,539
ffffffffc02030f8:	00003517          	auipc	a0,0x3
ffffffffc02030fc:	68850513          	addi	a0,a0,1672 # ffffffffc0206780 <default_pmm_manager+0x150>
ffffffffc0203100:	b8efd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((*ptep & PTE_U) == 0);
ffffffffc0203104:	00004697          	auipc	a3,0x4
ffffffffc0203108:	a0468693          	addi	a3,a3,-1532 # ffffffffc0206b08 <default_pmm_manager+0x4d8>
ffffffffc020310c:	00003617          	auipc	a2,0x3
ffffffffc0203110:	17460613          	addi	a2,a2,372 # ffffffffc0206280 <commands+0x868>
ffffffffc0203114:	21800593          	li	a1,536
ffffffffc0203118:	00003517          	auipc	a0,0x3
ffffffffc020311c:	66850513          	addi	a0,a0,1640 # ffffffffc0206780 <default_pmm_manager+0x150>
ffffffffc0203120:	b6efd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc0203124:	00004697          	auipc	a3,0x4
ffffffffc0203128:	85468693          	addi	a3,a3,-1964 # ffffffffc0206978 <default_pmm_manager+0x348>
ffffffffc020312c:	00003617          	auipc	a2,0x3
ffffffffc0203130:	15460613          	addi	a2,a2,340 # ffffffffc0206280 <commands+0x868>
ffffffffc0203134:	21700593          	li	a1,535
ffffffffc0203138:	00003517          	auipc	a0,0x3
ffffffffc020313c:	64850513          	addi	a0,a0,1608 # ffffffffc0206780 <default_pmm_manager+0x150>
ffffffffc0203140:	b4efd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0203144:	00004697          	auipc	a3,0x4
ffffffffc0203148:	8d468693          	addi	a3,a3,-1836 # ffffffffc0206a18 <default_pmm_manager+0x3e8>
ffffffffc020314c:	00003617          	auipc	a2,0x3
ffffffffc0203150:	13460613          	addi	a2,a2,308 # ffffffffc0206280 <commands+0x868>
ffffffffc0203154:	21600593          	li	a1,534
ffffffffc0203158:	00003517          	auipc	a0,0x3
ffffffffc020315c:	62850513          	addi	a0,a0,1576 # ffffffffc0206780 <default_pmm_manager+0x150>
ffffffffc0203160:	b2efd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0203164:	00004697          	auipc	a3,0x4
ffffffffc0203168:	98c68693          	addi	a3,a3,-1652 # ffffffffc0206af0 <default_pmm_manager+0x4c0>
ffffffffc020316c:	00003617          	auipc	a2,0x3
ffffffffc0203170:	11460613          	addi	a2,a2,276 # ffffffffc0206280 <commands+0x868>
ffffffffc0203174:	21500593          	li	a1,533
ffffffffc0203178:	00003517          	auipc	a0,0x3
ffffffffc020317c:	60850513          	addi	a0,a0,1544 # ffffffffc0206780 <default_pmm_manager+0x150>
ffffffffc0203180:	b0efd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p1) == 2);
ffffffffc0203184:	00004697          	auipc	a3,0x4
ffffffffc0203188:	95468693          	addi	a3,a3,-1708 # ffffffffc0206ad8 <default_pmm_manager+0x4a8>
ffffffffc020318c:	00003617          	auipc	a2,0x3
ffffffffc0203190:	0f460613          	addi	a2,a2,244 # ffffffffc0206280 <commands+0x868>
ffffffffc0203194:	21400593          	li	a1,532
ffffffffc0203198:	00003517          	auipc	a0,0x3
ffffffffc020319c:	5e850513          	addi	a0,a0,1512 # ffffffffc0206780 <default_pmm_manager+0x150>
ffffffffc02031a0:	aeefd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc02031a4:	00004697          	auipc	a3,0x4
ffffffffc02031a8:	90468693          	addi	a3,a3,-1788 # ffffffffc0206aa8 <default_pmm_manager+0x478>
ffffffffc02031ac:	00003617          	auipc	a2,0x3
ffffffffc02031b0:	0d460613          	addi	a2,a2,212 # ffffffffc0206280 <commands+0x868>
ffffffffc02031b4:	21300593          	li	a1,531
ffffffffc02031b8:	00003517          	auipc	a0,0x3
ffffffffc02031bc:	5c850513          	addi	a0,a0,1480 # ffffffffc0206780 <default_pmm_manager+0x150>
ffffffffc02031c0:	acefd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p2) == 1);
ffffffffc02031c4:	00004697          	auipc	a3,0x4
ffffffffc02031c8:	8cc68693          	addi	a3,a3,-1844 # ffffffffc0206a90 <default_pmm_manager+0x460>
ffffffffc02031cc:	00003617          	auipc	a2,0x3
ffffffffc02031d0:	0b460613          	addi	a2,a2,180 # ffffffffc0206280 <commands+0x868>
ffffffffc02031d4:	21100593          	li	a1,529
ffffffffc02031d8:	00003517          	auipc	a0,0x3
ffffffffc02031dc:	5a850513          	addi	a0,a0,1448 # ffffffffc0206780 <default_pmm_manager+0x150>
ffffffffc02031e0:	aaefd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc02031e4:	00004697          	auipc	a3,0x4
ffffffffc02031e8:	88c68693          	addi	a3,a3,-1908 # ffffffffc0206a70 <default_pmm_manager+0x440>
ffffffffc02031ec:	00003617          	auipc	a2,0x3
ffffffffc02031f0:	09460613          	addi	a2,a2,148 # ffffffffc0206280 <commands+0x868>
ffffffffc02031f4:	21000593          	li	a1,528
ffffffffc02031f8:	00003517          	auipc	a0,0x3
ffffffffc02031fc:	58850513          	addi	a0,a0,1416 # ffffffffc0206780 <default_pmm_manager+0x150>
ffffffffc0203200:	a8efd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(*ptep & PTE_W);
ffffffffc0203204:	00004697          	auipc	a3,0x4
ffffffffc0203208:	85c68693          	addi	a3,a3,-1956 # ffffffffc0206a60 <default_pmm_manager+0x430>
ffffffffc020320c:	00003617          	auipc	a2,0x3
ffffffffc0203210:	07460613          	addi	a2,a2,116 # ffffffffc0206280 <commands+0x868>
ffffffffc0203214:	20f00593          	li	a1,527
ffffffffc0203218:	00003517          	auipc	a0,0x3
ffffffffc020321c:	56850513          	addi	a0,a0,1384 # ffffffffc0206780 <default_pmm_manager+0x150>
ffffffffc0203220:	a6efd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(*ptep & PTE_U);
ffffffffc0203224:	00004697          	auipc	a3,0x4
ffffffffc0203228:	82c68693          	addi	a3,a3,-2004 # ffffffffc0206a50 <default_pmm_manager+0x420>
ffffffffc020322c:	00003617          	auipc	a2,0x3
ffffffffc0203230:	05460613          	addi	a2,a2,84 # ffffffffc0206280 <commands+0x868>
ffffffffc0203234:	20e00593          	li	a1,526
ffffffffc0203238:	00003517          	auipc	a0,0x3
ffffffffc020323c:	54850513          	addi	a0,a0,1352 # ffffffffc0206780 <default_pmm_manager+0x150>
ffffffffc0203240:	a4efd0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("DTB memory info not available");
ffffffffc0203244:	00003617          	auipc	a2,0x3
ffffffffc0203248:	5ac60613          	addi	a2,a2,1452 # ffffffffc02067f0 <default_pmm_manager+0x1c0>
ffffffffc020324c:	06500593          	li	a1,101
ffffffffc0203250:	00003517          	auipc	a0,0x3
ffffffffc0203254:	53050513          	addi	a0,a0,1328 # ffffffffc0206780 <default_pmm_manager+0x150>
ffffffffc0203258:	a36fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc020325c:	00004697          	auipc	a3,0x4
ffffffffc0203260:	90c68693          	addi	a3,a3,-1780 # ffffffffc0206b68 <default_pmm_manager+0x538>
ffffffffc0203264:	00003617          	auipc	a2,0x3
ffffffffc0203268:	01c60613          	addi	a2,a2,28 # ffffffffc0206280 <commands+0x868>
ffffffffc020326c:	25400593          	li	a1,596
ffffffffc0203270:	00003517          	auipc	a0,0x3
ffffffffc0203274:	51050513          	addi	a0,a0,1296 # ffffffffc0206780 <default_pmm_manager+0x150>
ffffffffc0203278:	a16fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc020327c:	00003697          	auipc	a3,0x3
ffffffffc0203280:	79c68693          	addi	a3,a3,1948 # ffffffffc0206a18 <default_pmm_manager+0x3e8>
ffffffffc0203284:	00003617          	auipc	a2,0x3
ffffffffc0203288:	ffc60613          	addi	a2,a2,-4 # ffffffffc0206280 <commands+0x868>
ffffffffc020328c:	20d00593          	li	a1,525
ffffffffc0203290:	00003517          	auipc	a0,0x3
ffffffffc0203294:	4f050513          	addi	a0,a0,1264 # ffffffffc0206780 <default_pmm_manager+0x150>
ffffffffc0203298:	9f6fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc020329c:	00003697          	auipc	a3,0x3
ffffffffc02032a0:	73c68693          	addi	a3,a3,1852 # ffffffffc02069d8 <default_pmm_manager+0x3a8>
ffffffffc02032a4:	00003617          	auipc	a2,0x3
ffffffffc02032a8:	fdc60613          	addi	a2,a2,-36 # ffffffffc0206280 <commands+0x868>
ffffffffc02032ac:	20c00593          	li	a1,524
ffffffffc02032b0:	00003517          	auipc	a0,0x3
ffffffffc02032b4:	4d050513          	addi	a0,a0,1232 # ffffffffc0206780 <default_pmm_manager+0x150>
ffffffffc02032b8:	9d6fd0ef          	jal	ra,ffffffffc020048e <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc02032bc:	86d6                	mv	a3,s5
ffffffffc02032be:	00003617          	auipc	a2,0x3
ffffffffc02032c2:	3aa60613          	addi	a2,a2,938 # ffffffffc0206668 <default_pmm_manager+0x38>
ffffffffc02032c6:	20800593          	li	a1,520
ffffffffc02032ca:	00003517          	auipc	a0,0x3
ffffffffc02032ce:	4b650513          	addi	a0,a0,1206 # ffffffffc0206780 <default_pmm_manager+0x150>
ffffffffc02032d2:	9bcfd0ef          	jal	ra,ffffffffc020048e <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc02032d6:	00003617          	auipc	a2,0x3
ffffffffc02032da:	39260613          	addi	a2,a2,914 # ffffffffc0206668 <default_pmm_manager+0x38>
ffffffffc02032de:	20700593          	li	a1,519
ffffffffc02032e2:	00003517          	auipc	a0,0x3
ffffffffc02032e6:	49e50513          	addi	a0,a0,1182 # ffffffffc0206780 <default_pmm_manager+0x150>
ffffffffc02032ea:	9a4fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p1) == 1);
ffffffffc02032ee:	00003697          	auipc	a3,0x3
ffffffffc02032f2:	6a268693          	addi	a3,a3,1698 # ffffffffc0206990 <default_pmm_manager+0x360>
ffffffffc02032f6:	00003617          	auipc	a2,0x3
ffffffffc02032fa:	f8a60613          	addi	a2,a2,-118 # ffffffffc0206280 <commands+0x868>
ffffffffc02032fe:	20500593          	li	a1,517
ffffffffc0203302:	00003517          	auipc	a0,0x3
ffffffffc0203306:	47e50513          	addi	a0,a0,1150 # ffffffffc0206780 <default_pmm_manager+0x150>
ffffffffc020330a:	984fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc020330e:	00003697          	auipc	a3,0x3
ffffffffc0203312:	66a68693          	addi	a3,a3,1642 # ffffffffc0206978 <default_pmm_manager+0x348>
ffffffffc0203316:	00003617          	auipc	a2,0x3
ffffffffc020331a:	f6a60613          	addi	a2,a2,-150 # ffffffffc0206280 <commands+0x868>
ffffffffc020331e:	20400593          	li	a1,516
ffffffffc0203322:	00003517          	auipc	a0,0x3
ffffffffc0203326:	45e50513          	addi	a0,a0,1118 # ffffffffc0206780 <default_pmm_manager+0x150>
ffffffffc020332a:	964fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(strlen((const char *)0x100) == 0);
ffffffffc020332e:	00004697          	auipc	a3,0x4
ffffffffc0203332:	9fa68693          	addi	a3,a3,-1542 # ffffffffc0206d28 <default_pmm_manager+0x6f8>
ffffffffc0203336:	00003617          	auipc	a2,0x3
ffffffffc020333a:	f4a60613          	addi	a2,a2,-182 # ffffffffc0206280 <commands+0x868>
ffffffffc020333e:	24b00593          	li	a1,587
ffffffffc0203342:	00003517          	auipc	a0,0x3
ffffffffc0203346:	43e50513          	addi	a0,a0,1086 # ffffffffc0206780 <default_pmm_manager+0x150>
ffffffffc020334a:	944fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc020334e:	00004697          	auipc	a3,0x4
ffffffffc0203352:	9a268693          	addi	a3,a3,-1630 # ffffffffc0206cf0 <default_pmm_manager+0x6c0>
ffffffffc0203356:	00003617          	auipc	a2,0x3
ffffffffc020335a:	f2a60613          	addi	a2,a2,-214 # ffffffffc0206280 <commands+0x868>
ffffffffc020335e:	24800593          	li	a1,584
ffffffffc0203362:	00003517          	auipc	a0,0x3
ffffffffc0203366:	41e50513          	addi	a0,a0,1054 # ffffffffc0206780 <default_pmm_manager+0x150>
ffffffffc020336a:	924fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p) == 2);
ffffffffc020336e:	00004697          	auipc	a3,0x4
ffffffffc0203372:	95268693          	addi	a3,a3,-1710 # ffffffffc0206cc0 <default_pmm_manager+0x690>
ffffffffc0203376:	00003617          	auipc	a2,0x3
ffffffffc020337a:	f0a60613          	addi	a2,a2,-246 # ffffffffc0206280 <commands+0x868>
ffffffffc020337e:	24400593          	li	a1,580
ffffffffc0203382:	00003517          	auipc	a0,0x3
ffffffffc0203386:	3fe50513          	addi	a0,a0,1022 # ffffffffc0206780 <default_pmm_manager+0x150>
ffffffffc020338a:	904fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc020338e:	00004697          	auipc	a3,0x4
ffffffffc0203392:	8ea68693          	addi	a3,a3,-1814 # ffffffffc0206c78 <default_pmm_manager+0x648>
ffffffffc0203396:	00003617          	auipc	a2,0x3
ffffffffc020339a:	eea60613          	addi	a2,a2,-278 # ffffffffc0206280 <commands+0x868>
ffffffffc020339e:	24300593          	li	a1,579
ffffffffc02033a2:	00003517          	auipc	a0,0x3
ffffffffc02033a6:	3de50513          	addi	a0,a0,990 # ffffffffc0206780 <default_pmm_manager+0x150>
ffffffffc02033aa:	8e4fd0ef          	jal	ra,ffffffffc020048e <__panic>
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc02033ae:	00003617          	auipc	a2,0x3
ffffffffc02033b2:	36260613          	addi	a2,a2,866 # ffffffffc0206710 <default_pmm_manager+0xe0>
ffffffffc02033b6:	0c900593          	li	a1,201
ffffffffc02033ba:	00003517          	auipc	a0,0x3
ffffffffc02033be:	3c650513          	addi	a0,a0,966 # ffffffffc0206780 <default_pmm_manager+0x150>
ffffffffc02033c2:	8ccfd0ef          	jal	ra,ffffffffc020048e <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02033c6:	00003617          	auipc	a2,0x3
ffffffffc02033ca:	34a60613          	addi	a2,a2,842 # ffffffffc0206710 <default_pmm_manager+0xe0>
ffffffffc02033ce:	08100593          	li	a1,129
ffffffffc02033d2:	00003517          	auipc	a0,0x3
ffffffffc02033d6:	3ae50513          	addi	a0,a0,942 # ffffffffc0206780 <default_pmm_manager+0x150>
ffffffffc02033da:	8b4fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc02033de:	00003697          	auipc	a3,0x3
ffffffffc02033e2:	56a68693          	addi	a3,a3,1386 # ffffffffc0206948 <default_pmm_manager+0x318>
ffffffffc02033e6:	00003617          	auipc	a2,0x3
ffffffffc02033ea:	e9a60613          	addi	a2,a2,-358 # ffffffffc0206280 <commands+0x868>
ffffffffc02033ee:	20300593          	li	a1,515
ffffffffc02033f2:	00003517          	auipc	a0,0x3
ffffffffc02033f6:	38e50513          	addi	a0,a0,910 # ffffffffc0206780 <default_pmm_manager+0x150>
ffffffffc02033fa:	894fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc02033fe:	00003697          	auipc	a3,0x3
ffffffffc0203402:	51a68693          	addi	a3,a3,1306 # ffffffffc0206918 <default_pmm_manager+0x2e8>
ffffffffc0203406:	00003617          	auipc	a2,0x3
ffffffffc020340a:	e7a60613          	addi	a2,a2,-390 # ffffffffc0206280 <commands+0x868>
ffffffffc020340e:	20000593          	li	a1,512
ffffffffc0203412:	00003517          	auipc	a0,0x3
ffffffffc0203416:	36e50513          	addi	a0,a0,878 # ffffffffc0206780 <default_pmm_manager+0x150>
ffffffffc020341a:	874fd0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc020341e <copy_range>:
{
ffffffffc020341e:	7119                	addi	sp,sp,-128
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0203420:	00d667b3          	or	a5,a2,a3
{
ffffffffc0203424:	fc86                	sd	ra,120(sp)
ffffffffc0203426:	f8a2                	sd	s0,112(sp)
ffffffffc0203428:	f4a6                	sd	s1,104(sp)
ffffffffc020342a:	f0ca                	sd	s2,96(sp)
ffffffffc020342c:	ecce                	sd	s3,88(sp)
ffffffffc020342e:	e8d2                	sd	s4,80(sp)
ffffffffc0203430:	e4d6                	sd	s5,72(sp)
ffffffffc0203432:	e0da                	sd	s6,64(sp)
ffffffffc0203434:	fc5e                	sd	s7,56(sp)
ffffffffc0203436:	f862                	sd	s8,48(sp)
ffffffffc0203438:	f466                	sd	s9,40(sp)
ffffffffc020343a:	f06a                	sd	s10,32(sp)
ffffffffc020343c:	ec6e                	sd	s11,24(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc020343e:	17d2                	slli	a5,a5,0x34
ffffffffc0203440:	24079063          	bnez	a5,ffffffffc0203680 <copy_range+0x262>
    assert(USER_ACCESS(start, end));
ffffffffc0203444:	002007b7          	lui	a5,0x200
ffffffffc0203448:	8432                	mv	s0,a2
ffffffffc020344a:	1cf66363          	bltu	a2,a5,ffffffffc0203610 <copy_range+0x1f2>
ffffffffc020344e:	8936                	mv	s2,a3
ffffffffc0203450:	1cd67063          	bgeu	a2,a3,ffffffffc0203610 <copy_range+0x1f2>
ffffffffc0203454:	4785                	li	a5,1
ffffffffc0203456:	07fe                	slli	a5,a5,0x1f
ffffffffc0203458:	1ad7ec63          	bltu	a5,a3,ffffffffc0203610 <copy_range+0x1f2>
ffffffffc020345c:	5b7d                	li	s6,-1
ffffffffc020345e:	8aaa                	mv	s5,a0
ffffffffc0203460:	89ae                	mv	s3,a1
        start += PGSIZE;
ffffffffc0203462:	6a05                	lui	s4,0x1
    if (PPN(pa) >= npage)
ffffffffc0203464:	000a7c17          	auipc	s8,0xa7
ffffffffc0203468:	474c0c13          	addi	s8,s8,1140 # ffffffffc02aa8d8 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc020346c:	000a7b97          	auipc	s7,0xa7
ffffffffc0203470:	474b8b93          	addi	s7,s7,1140 # ffffffffc02aa8e0 <pages>
    return KADDR(page2pa(page));
ffffffffc0203474:	00cb5b13          	srli	s6,s6,0xc
        page = pmm_manager->alloc_pages(n);
ffffffffc0203478:	000a7c97          	auipc	s9,0xa7
ffffffffc020347c:	470c8c93          	addi	s9,s9,1136 # ffffffffc02aa8e8 <pmm_manager>
        pte_t *ptep = get_pte(from, start, 0), *nptep;
ffffffffc0203480:	4601                	li	a2,0
ffffffffc0203482:	85a2                	mv	a1,s0
ffffffffc0203484:	854e                	mv	a0,s3
ffffffffc0203486:	b73fe0ef          	jal	ra,ffffffffc0201ff8 <get_pte>
ffffffffc020348a:	84aa                	mv	s1,a0
        if (ptep == NULL) {
ffffffffc020348c:	10050163          	beqz	a0,ffffffffc020358e <copy_range+0x170>
        if (*ptep & PTE_V) {
ffffffffc0203490:	611c                	ld	a5,0(a0)
ffffffffc0203492:	8b85                	andi	a5,a5,1
ffffffffc0203494:	e785                	bnez	a5,ffffffffc02034bc <copy_range+0x9e>
        start += PGSIZE;
ffffffffc0203496:	9452                	add	s0,s0,s4
    } while (start != 0 && start < end);
ffffffffc0203498:	ff2464e3          	bltu	s0,s2,ffffffffc0203480 <copy_range+0x62>
    return 0;
ffffffffc020349c:	4501                	li	a0,0
}
ffffffffc020349e:	70e6                	ld	ra,120(sp)
ffffffffc02034a0:	7446                	ld	s0,112(sp)
ffffffffc02034a2:	74a6                	ld	s1,104(sp)
ffffffffc02034a4:	7906                	ld	s2,96(sp)
ffffffffc02034a6:	69e6                	ld	s3,88(sp)
ffffffffc02034a8:	6a46                	ld	s4,80(sp)
ffffffffc02034aa:	6aa6                	ld	s5,72(sp)
ffffffffc02034ac:	6b06                	ld	s6,64(sp)
ffffffffc02034ae:	7be2                	ld	s7,56(sp)
ffffffffc02034b0:	7c42                	ld	s8,48(sp)
ffffffffc02034b2:	7ca2                	ld	s9,40(sp)
ffffffffc02034b4:	7d02                	ld	s10,32(sp)
ffffffffc02034b6:	6de2                	ld	s11,24(sp)
ffffffffc02034b8:	6109                	addi	sp,sp,128
ffffffffc02034ba:	8082                	ret
            if ((nptep = get_pte(to, start, 1)) == NULL) {
ffffffffc02034bc:	4605                	li	a2,1
ffffffffc02034be:	85a2                	mv	a1,s0
ffffffffc02034c0:	8556                	mv	a0,s5
ffffffffc02034c2:	b37fe0ef          	jal	ra,ffffffffc0201ff8 <get_pte>
ffffffffc02034c6:	10050663          	beqz	a0,ffffffffc02035d2 <copy_range+0x1b4>
            uint32_t perm = (*ptep & PTE_USER);
ffffffffc02034ca:	609c                	ld	a5,0(s1)
    if (!(pte & PTE_V))
ffffffffc02034cc:	0017f713          	andi	a4,a5,1
ffffffffc02034d0:	01f7f493          	andi	s1,a5,31
ffffffffc02034d4:	18070a63          	beqz	a4,ffffffffc0203668 <copy_range+0x24a>
    if (PPN(pa) >= npage)
ffffffffc02034d8:	000c3683          	ld	a3,0(s8)
    return pa2page(PTE_ADDR(pte));
ffffffffc02034dc:	078a                	slli	a5,a5,0x2
ffffffffc02034de:	00c7d713          	srli	a4,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02034e2:	16d77763          	bgeu	a4,a3,ffffffffc0203650 <copy_range+0x232>
    return &pages[PPN(pa) - nbase];
ffffffffc02034e6:	000bb783          	ld	a5,0(s7)
ffffffffc02034ea:	fff806b7          	lui	a3,0xfff80
ffffffffc02034ee:	9736                	add	a4,a4,a3
ffffffffc02034f0:	071a                	slli	a4,a4,0x6
ffffffffc02034f2:	00e78db3          	add	s11,a5,a4
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02034f6:	10002773          	csrr	a4,sstatus
ffffffffc02034fa:	8b09                	andi	a4,a4,2
ffffffffc02034fc:	e745                	bnez	a4,ffffffffc02035a4 <copy_range+0x186>
        page = pmm_manager->alloc_pages(n);
ffffffffc02034fe:	000cb703          	ld	a4,0(s9)
ffffffffc0203502:	4505                	li	a0,1
ffffffffc0203504:	6f18                	ld	a4,24(a4)
ffffffffc0203506:	9702                	jalr	a4
ffffffffc0203508:	8d2a                	mv	s10,a0
            assert(page != NULL);
ffffffffc020350a:	0e0d8363          	beqz	s11,ffffffffc02035f0 <copy_range+0x1d2>
            assert(npage != NULL);
ffffffffc020350e:	120d0163          	beqz	s10,ffffffffc0203630 <copy_range+0x212>
    return page - pages + nbase;
ffffffffc0203512:	000bb703          	ld	a4,0(s7)
ffffffffc0203516:	000805b7          	lui	a1,0x80
    return KADDR(page2pa(page));
ffffffffc020351a:	000c3603          	ld	a2,0(s8)
    return page - pages + nbase;
ffffffffc020351e:	40ed86b3          	sub	a3,s11,a4
ffffffffc0203522:	8699                	srai	a3,a3,0x6
ffffffffc0203524:	96ae                	add	a3,a3,a1
    return KADDR(page2pa(page));
ffffffffc0203526:	0166f7b3          	and	a5,a3,s6
    return page2ppn(page) << PGSHIFT;
ffffffffc020352a:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc020352c:	0ac7f663          	bgeu	a5,a2,ffffffffc02035d8 <copy_range+0x1ba>
    return page - pages + nbase;
ffffffffc0203530:	40ed07b3          	sub	a5,s10,a4
    return KADDR(page2pa(page));
ffffffffc0203534:	000a7717          	auipc	a4,0xa7
ffffffffc0203538:	3bc70713          	addi	a4,a4,956 # ffffffffc02aa8f0 <va_pa_offset>
ffffffffc020353c:	6308                	ld	a0,0(a4)
    return page - pages + nbase;
ffffffffc020353e:	8799                	srai	a5,a5,0x6
ffffffffc0203540:	97ae                	add	a5,a5,a1
    return KADDR(page2pa(page));
ffffffffc0203542:	0167f733          	and	a4,a5,s6
ffffffffc0203546:	00a685b3          	add	a1,a3,a0
    return page2ppn(page) << PGSHIFT;
ffffffffc020354a:	07b2                	slli	a5,a5,0xc
    return KADDR(page2pa(page));
ffffffffc020354c:	08c77563          	bgeu	a4,a2,ffffffffc02035d6 <copy_range+0x1b8>
ffffffffc0203550:	953e                	add	a0,a0,a5
ffffffffc0203552:	100027f3          	csrr	a5,sstatus
ffffffffc0203556:	8b89                	andi	a5,a5,2
ffffffffc0203558:	e3ad                	bnez	a5,ffffffffc02035ba <copy_range+0x19c>
            memcpy(dst_kvaddr, src_kvaddr, PGSIZE);
ffffffffc020355a:	6605                	lui	a2,0x1
ffffffffc020355c:	236020ef          	jal	ra,ffffffffc0205792 <memcpy>
            int ret = page_insert(to, npage, start, perm);
ffffffffc0203560:	86a6                	mv	a3,s1
ffffffffc0203562:	8622                	mv	a2,s0
ffffffffc0203564:	85ea                	mv	a1,s10
ffffffffc0203566:	8556                	mv	a0,s5
ffffffffc0203568:	980ff0ef          	jal	ra,ffffffffc02026e8 <page_insert>
            assert(ret == 0);
ffffffffc020356c:	d50d                	beqz	a0,ffffffffc0203496 <copy_range+0x78>
ffffffffc020356e:	00004697          	auipc	a3,0x4
ffffffffc0203572:	82268693          	addi	a3,a3,-2014 # ffffffffc0206d90 <default_pmm_manager+0x760>
ffffffffc0203576:	00003617          	auipc	a2,0x3
ffffffffc020357a:	d0a60613          	addi	a2,a2,-758 # ffffffffc0206280 <commands+0x868>
ffffffffc020357e:	19700593          	li	a1,407
ffffffffc0203582:	00003517          	auipc	a0,0x3
ffffffffc0203586:	1fe50513          	addi	a0,a0,510 # ffffffffc0206780 <default_pmm_manager+0x150>
ffffffffc020358a:	f05fc0ef          	jal	ra,ffffffffc020048e <__panic>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc020358e:	00200637          	lui	a2,0x200
ffffffffc0203592:	9432                	add	s0,s0,a2
ffffffffc0203594:	ffe00637          	lui	a2,0xffe00
ffffffffc0203598:	8c71                	and	s0,s0,a2
    } while (start != 0 && start < end);
ffffffffc020359a:	f00401e3          	beqz	s0,ffffffffc020349c <copy_range+0x7e>
ffffffffc020359e:	ef2461e3          	bltu	s0,s2,ffffffffc0203480 <copy_range+0x62>
ffffffffc02035a2:	bded                	j	ffffffffc020349c <copy_range+0x7e>
        intr_disable();
ffffffffc02035a4:	c10fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc02035a8:	000cb703          	ld	a4,0(s9)
ffffffffc02035ac:	4505                	li	a0,1
ffffffffc02035ae:	6f18                	ld	a4,24(a4)
ffffffffc02035b0:	9702                	jalr	a4
ffffffffc02035b2:	8d2a                	mv	s10,a0
        intr_enable();
ffffffffc02035b4:	bfafd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02035b8:	bf89                	j	ffffffffc020350a <copy_range+0xec>
ffffffffc02035ba:	e42e                	sd	a1,8(sp)
ffffffffc02035bc:	e02a                	sd	a0,0(sp)
        intr_disable();
ffffffffc02035be:	bf6fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
            memcpy(dst_kvaddr, src_kvaddr, PGSIZE);
ffffffffc02035c2:	65a2                	ld	a1,8(sp)
ffffffffc02035c4:	6502                	ld	a0,0(sp)
ffffffffc02035c6:	6605                	lui	a2,0x1
ffffffffc02035c8:	1ca020ef          	jal	ra,ffffffffc0205792 <memcpy>
        intr_enable();
ffffffffc02035cc:	be2fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02035d0:	bf41                	j	ffffffffc0203560 <copy_range+0x142>
                return -E_NO_MEM;
ffffffffc02035d2:	5571                	li	a0,-4
ffffffffc02035d4:	b5e9                	j	ffffffffc020349e <copy_range+0x80>
ffffffffc02035d6:	86be                	mv	a3,a5
ffffffffc02035d8:	00003617          	auipc	a2,0x3
ffffffffc02035dc:	09060613          	addi	a2,a2,144 # ffffffffc0206668 <default_pmm_manager+0x38>
ffffffffc02035e0:	07100593          	li	a1,113
ffffffffc02035e4:	00003517          	auipc	a0,0x3
ffffffffc02035e8:	0ac50513          	addi	a0,a0,172 # ffffffffc0206690 <default_pmm_manager+0x60>
ffffffffc02035ec:	ea3fc0ef          	jal	ra,ffffffffc020048e <__panic>
            assert(page != NULL);
ffffffffc02035f0:	00003697          	auipc	a3,0x3
ffffffffc02035f4:	78068693          	addi	a3,a3,1920 # ffffffffc0206d70 <default_pmm_manager+0x740>
ffffffffc02035f8:	00003617          	auipc	a2,0x3
ffffffffc02035fc:	c8860613          	addi	a2,a2,-888 # ffffffffc0206280 <commands+0x868>
ffffffffc0203600:	18a00593          	li	a1,394
ffffffffc0203604:	00003517          	auipc	a0,0x3
ffffffffc0203608:	17c50513          	addi	a0,a0,380 # ffffffffc0206780 <default_pmm_manager+0x150>
ffffffffc020360c:	e83fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(USER_ACCESS(start, end));
ffffffffc0203610:	00003697          	auipc	a3,0x3
ffffffffc0203614:	1b068693          	addi	a3,a3,432 # ffffffffc02067c0 <default_pmm_manager+0x190>
ffffffffc0203618:	00003617          	auipc	a2,0x3
ffffffffc020361c:	c6860613          	addi	a2,a2,-920 # ffffffffc0206280 <commands+0x868>
ffffffffc0203620:	17b00593          	li	a1,379
ffffffffc0203624:	00003517          	auipc	a0,0x3
ffffffffc0203628:	15c50513          	addi	a0,a0,348 # ffffffffc0206780 <default_pmm_manager+0x150>
ffffffffc020362c:	e63fc0ef          	jal	ra,ffffffffc020048e <__panic>
            assert(npage != NULL);
ffffffffc0203630:	00003697          	auipc	a3,0x3
ffffffffc0203634:	75068693          	addi	a3,a3,1872 # ffffffffc0206d80 <default_pmm_manager+0x750>
ffffffffc0203638:	00003617          	auipc	a2,0x3
ffffffffc020363c:	c4860613          	addi	a2,a2,-952 # ffffffffc0206280 <commands+0x868>
ffffffffc0203640:	18b00593          	li	a1,395
ffffffffc0203644:	00003517          	auipc	a0,0x3
ffffffffc0203648:	13c50513          	addi	a0,a0,316 # ffffffffc0206780 <default_pmm_manager+0x150>
ffffffffc020364c:	e43fc0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0203650:	00003617          	auipc	a2,0x3
ffffffffc0203654:	0e860613          	addi	a2,a2,232 # ffffffffc0206738 <default_pmm_manager+0x108>
ffffffffc0203658:	06900593          	li	a1,105
ffffffffc020365c:	00003517          	auipc	a0,0x3
ffffffffc0203660:	03450513          	addi	a0,a0,52 # ffffffffc0206690 <default_pmm_manager+0x60>
ffffffffc0203664:	e2bfc0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("pte2page called with invalid pte");
ffffffffc0203668:	00003617          	auipc	a2,0x3
ffffffffc020366c:	0f060613          	addi	a2,a2,240 # ffffffffc0206758 <default_pmm_manager+0x128>
ffffffffc0203670:	07f00593          	li	a1,127
ffffffffc0203674:	00003517          	auipc	a0,0x3
ffffffffc0203678:	01c50513          	addi	a0,a0,28 # ffffffffc0206690 <default_pmm_manager+0x60>
ffffffffc020367c:	e13fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0203680:	00003697          	auipc	a3,0x3
ffffffffc0203684:	11068693          	addi	a3,a3,272 # ffffffffc0206790 <default_pmm_manager+0x160>
ffffffffc0203688:	00003617          	auipc	a2,0x3
ffffffffc020368c:	bf860613          	addi	a2,a2,-1032 # ffffffffc0206280 <commands+0x868>
ffffffffc0203690:	17a00593          	li	a1,378
ffffffffc0203694:	00003517          	auipc	a0,0x3
ffffffffc0203698:	0ec50513          	addi	a0,a0,236 # ffffffffc0206780 <default_pmm_manager+0x150>
ffffffffc020369c:	df3fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02036a0 <pgdir_alloc_page>:
{
ffffffffc02036a0:	7179                	addi	sp,sp,-48
ffffffffc02036a2:	ec26                	sd	s1,24(sp)
ffffffffc02036a4:	e84a                	sd	s2,16(sp)
ffffffffc02036a6:	e052                	sd	s4,0(sp)
ffffffffc02036a8:	f406                	sd	ra,40(sp)
ffffffffc02036aa:	f022                	sd	s0,32(sp)
ffffffffc02036ac:	e44e                	sd	s3,8(sp)
ffffffffc02036ae:	8a2a                	mv	s4,a0
ffffffffc02036b0:	84ae                	mv	s1,a1
ffffffffc02036b2:	8932                	mv	s2,a2
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02036b4:	100027f3          	csrr	a5,sstatus
ffffffffc02036b8:	8b89                	andi	a5,a5,2
        page = pmm_manager->alloc_pages(n);
ffffffffc02036ba:	000a7997          	auipc	s3,0xa7
ffffffffc02036be:	22e98993          	addi	s3,s3,558 # ffffffffc02aa8e8 <pmm_manager>
ffffffffc02036c2:	ef8d                	bnez	a5,ffffffffc02036fc <pgdir_alloc_page+0x5c>
ffffffffc02036c4:	0009b783          	ld	a5,0(s3)
ffffffffc02036c8:	4505                	li	a0,1
ffffffffc02036ca:	6f9c                	ld	a5,24(a5)
ffffffffc02036cc:	9782                	jalr	a5
ffffffffc02036ce:	842a                	mv	s0,a0
    if (page != NULL)
ffffffffc02036d0:	cc09                	beqz	s0,ffffffffc02036ea <pgdir_alloc_page+0x4a>
        if (page_insert(pgdir, page, la, perm) != 0)
ffffffffc02036d2:	86ca                	mv	a3,s2
ffffffffc02036d4:	8626                	mv	a2,s1
ffffffffc02036d6:	85a2                	mv	a1,s0
ffffffffc02036d8:	8552                	mv	a0,s4
ffffffffc02036da:	80eff0ef          	jal	ra,ffffffffc02026e8 <page_insert>
ffffffffc02036de:	e915                	bnez	a0,ffffffffc0203712 <pgdir_alloc_page+0x72>
        assert(page_ref(page) == 1);
ffffffffc02036e0:	4018                	lw	a4,0(s0)
        page->pra_vaddr = la;
ffffffffc02036e2:	fc04                	sd	s1,56(s0)
        assert(page_ref(page) == 1);
ffffffffc02036e4:	4785                	li	a5,1
ffffffffc02036e6:	04f71e63          	bne	a4,a5,ffffffffc0203742 <pgdir_alloc_page+0xa2>
}
ffffffffc02036ea:	70a2                	ld	ra,40(sp)
ffffffffc02036ec:	8522                	mv	a0,s0
ffffffffc02036ee:	7402                	ld	s0,32(sp)
ffffffffc02036f0:	64e2                	ld	s1,24(sp)
ffffffffc02036f2:	6942                	ld	s2,16(sp)
ffffffffc02036f4:	69a2                	ld	s3,8(sp)
ffffffffc02036f6:	6a02                	ld	s4,0(sp)
ffffffffc02036f8:	6145                	addi	sp,sp,48
ffffffffc02036fa:	8082                	ret
        intr_disable();
ffffffffc02036fc:	ab8fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0203700:	0009b783          	ld	a5,0(s3)
ffffffffc0203704:	4505                	li	a0,1
ffffffffc0203706:	6f9c                	ld	a5,24(a5)
ffffffffc0203708:	9782                	jalr	a5
ffffffffc020370a:	842a                	mv	s0,a0
        intr_enable();
ffffffffc020370c:	aa2fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0203710:	b7c1                	j	ffffffffc02036d0 <pgdir_alloc_page+0x30>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0203712:	100027f3          	csrr	a5,sstatus
ffffffffc0203716:	8b89                	andi	a5,a5,2
ffffffffc0203718:	eb89                	bnez	a5,ffffffffc020372a <pgdir_alloc_page+0x8a>
        pmm_manager->free_pages(base, n);
ffffffffc020371a:	0009b783          	ld	a5,0(s3)
ffffffffc020371e:	8522                	mv	a0,s0
ffffffffc0203720:	4585                	li	a1,1
ffffffffc0203722:	739c                	ld	a5,32(a5)
            return NULL;
ffffffffc0203724:	4401                	li	s0,0
        pmm_manager->free_pages(base, n);
ffffffffc0203726:	9782                	jalr	a5
    if (flag)
ffffffffc0203728:	b7c9                	j	ffffffffc02036ea <pgdir_alloc_page+0x4a>
        intr_disable();
ffffffffc020372a:	a8afd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc020372e:	0009b783          	ld	a5,0(s3)
ffffffffc0203732:	8522                	mv	a0,s0
ffffffffc0203734:	4585                	li	a1,1
ffffffffc0203736:	739c                	ld	a5,32(a5)
            return NULL;
ffffffffc0203738:	4401                	li	s0,0
        pmm_manager->free_pages(base, n);
ffffffffc020373a:	9782                	jalr	a5
        intr_enable();
ffffffffc020373c:	a72fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0203740:	b76d                	j	ffffffffc02036ea <pgdir_alloc_page+0x4a>
        assert(page_ref(page) == 1);
ffffffffc0203742:	00003697          	auipc	a3,0x3
ffffffffc0203746:	65e68693          	addi	a3,a3,1630 # ffffffffc0206da0 <default_pmm_manager+0x770>
ffffffffc020374a:	00003617          	auipc	a2,0x3
ffffffffc020374e:	b3660613          	addi	a2,a2,-1226 # ffffffffc0206280 <commands+0x868>
ffffffffc0203752:	1e100593          	li	a1,481
ffffffffc0203756:	00003517          	auipc	a0,0x3
ffffffffc020375a:	02a50513          	addi	a0,a0,42 # ffffffffc0206780 <default_pmm_manager+0x150>
ffffffffc020375e:	d31fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203762 <check_vma_overlap.part.0>:
    return vma;
}

// check_vma_overlap - check if vma1 overlaps vma2 ?
static inline void
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc0203762:	1141                	addi	sp,sp,-16
{
    assert(prev->vm_start < prev->vm_end);
    assert(prev->vm_end <= next->vm_start);
    assert(next->vm_start < next->vm_end);
ffffffffc0203764:	00003697          	auipc	a3,0x3
ffffffffc0203768:	65468693          	addi	a3,a3,1620 # ffffffffc0206db8 <default_pmm_manager+0x788>
ffffffffc020376c:	00003617          	auipc	a2,0x3
ffffffffc0203770:	b1460613          	addi	a2,a2,-1260 # ffffffffc0206280 <commands+0x868>
ffffffffc0203774:	07400593          	li	a1,116
ffffffffc0203778:	00003517          	auipc	a0,0x3
ffffffffc020377c:	66050513          	addi	a0,a0,1632 # ffffffffc0206dd8 <default_pmm_manager+0x7a8>
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc0203780:	e406                	sd	ra,8(sp)
    assert(next->vm_start < next->vm_end);
ffffffffc0203782:	d0dfc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203786 <mm_create>:
{
ffffffffc0203786:	1141                	addi	sp,sp,-16
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0203788:	04000513          	li	a0,64
{
ffffffffc020378c:	e406                	sd	ra,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc020378e:	dd4fe0ef          	jal	ra,ffffffffc0201d62 <kmalloc>
    if (mm != NULL)
ffffffffc0203792:	cd19                	beqz	a0,ffffffffc02037b0 <mm_create+0x2a>
    elm->prev = elm->next = elm;
ffffffffc0203794:	e508                	sd	a0,8(a0)
ffffffffc0203796:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc0203798:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc020379c:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc02037a0:	02052023          	sw	zero,32(a0)
        mm->sm_priv = NULL;
ffffffffc02037a4:	02053423          	sd	zero,40(a0)
}

static inline void
set_mm_count(struct mm_struct *mm, int val)
{
    mm->mm_count = val;
ffffffffc02037a8:	02052823          	sw	zero,48(a0)
typedef volatile bool lock_t;

static inline void
lock_init(lock_t *lock)
{
    *lock = 0;
ffffffffc02037ac:	02053c23          	sd	zero,56(a0)
}
ffffffffc02037b0:	60a2                	ld	ra,8(sp)
ffffffffc02037b2:	0141                	addi	sp,sp,16
ffffffffc02037b4:	8082                	ret

ffffffffc02037b6 <find_vma>:
{
ffffffffc02037b6:	86aa                	mv	a3,a0
    if (mm != NULL)
ffffffffc02037b8:	c505                	beqz	a0,ffffffffc02037e0 <find_vma+0x2a>
        vma = mm->mmap_cache;
ffffffffc02037ba:	6908                	ld	a0,16(a0)
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc02037bc:	c501                	beqz	a0,ffffffffc02037c4 <find_vma+0xe>
ffffffffc02037be:	651c                	ld	a5,8(a0)
ffffffffc02037c0:	02f5f263          	bgeu	a1,a5,ffffffffc02037e4 <find_vma+0x2e>
    return listelm->next;
ffffffffc02037c4:	669c                	ld	a5,8(a3)
            while ((le = list_next(le)) != list)
ffffffffc02037c6:	00f68d63          	beq	a3,a5,ffffffffc02037e0 <find_vma+0x2a>
                if (vma->vm_start <= addr && addr < vma->vm_end)
ffffffffc02037ca:	fe87b703          	ld	a4,-24(a5) # 1fffe8 <_binary_obj___user_exit_out_size+0x1f4ea8>
ffffffffc02037ce:	00e5e663          	bltu	a1,a4,ffffffffc02037da <find_vma+0x24>
ffffffffc02037d2:	ff07b703          	ld	a4,-16(a5)
ffffffffc02037d6:	00e5ec63          	bltu	a1,a4,ffffffffc02037ee <find_vma+0x38>
ffffffffc02037da:	679c                	ld	a5,8(a5)
            while ((le = list_next(le)) != list)
ffffffffc02037dc:	fef697e3          	bne	a3,a5,ffffffffc02037ca <find_vma+0x14>
    struct vma_struct *vma = NULL;
ffffffffc02037e0:	4501                	li	a0,0
}
ffffffffc02037e2:	8082                	ret
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc02037e4:	691c                	ld	a5,16(a0)
ffffffffc02037e6:	fcf5ffe3          	bgeu	a1,a5,ffffffffc02037c4 <find_vma+0xe>
            mm->mmap_cache = vma;
ffffffffc02037ea:	ea88                	sd	a0,16(a3)
ffffffffc02037ec:	8082                	ret
                vma = le2vma(le, list_link);
ffffffffc02037ee:	fe078513          	addi	a0,a5,-32
            mm->mmap_cache = vma;
ffffffffc02037f2:	ea88                	sd	a0,16(a3)
ffffffffc02037f4:	8082                	ret

ffffffffc02037f6 <insert_vma_struct>:
}

// insert_vma_struct -insert vma in mm's list link
void insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma)
{
    assert(vma->vm_start < vma->vm_end);
ffffffffc02037f6:	6590                	ld	a2,8(a1)
ffffffffc02037f8:	0105b803          	ld	a6,16(a1) # 80010 <_binary_obj___user_exit_out_size+0x74ed0>
{
ffffffffc02037fc:	1141                	addi	sp,sp,-16
ffffffffc02037fe:	e406                	sd	ra,8(sp)
ffffffffc0203800:	87aa                	mv	a5,a0
    assert(vma->vm_start < vma->vm_end);
ffffffffc0203802:	01066763          	bltu	a2,a6,ffffffffc0203810 <insert_vma_struct+0x1a>
ffffffffc0203806:	a085                	j	ffffffffc0203866 <insert_vma_struct+0x70>

    list_entry_t *le = list;
    while ((le = list_next(le)) != list)
    {
        struct vma_struct *mmap_prev = le2vma(le, list_link);
        if (mmap_prev->vm_start > vma->vm_start)
ffffffffc0203808:	fe87b703          	ld	a4,-24(a5)
ffffffffc020380c:	04e66863          	bltu	a2,a4,ffffffffc020385c <insert_vma_struct+0x66>
ffffffffc0203810:	86be                	mv	a3,a5
ffffffffc0203812:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != list)
ffffffffc0203814:	fef51ae3          	bne	a0,a5,ffffffffc0203808 <insert_vma_struct+0x12>
    }

    le_next = list_next(le_prev);

    /* check overlap */
    if (le_prev != list)
ffffffffc0203818:	02a68463          	beq	a3,a0,ffffffffc0203840 <insert_vma_struct+0x4a>
    {
        check_vma_overlap(le2vma(le_prev, list_link), vma);
ffffffffc020381c:	ff06b703          	ld	a4,-16(a3)
    assert(prev->vm_start < prev->vm_end);
ffffffffc0203820:	fe86b883          	ld	a7,-24(a3)
ffffffffc0203824:	08e8f163          	bgeu	a7,a4,ffffffffc02038a6 <insert_vma_struct+0xb0>
    assert(prev->vm_end <= next->vm_start);
ffffffffc0203828:	04e66f63          	bltu	a2,a4,ffffffffc0203886 <insert_vma_struct+0x90>
    }
    if (le_next != list)
ffffffffc020382c:	00f50a63          	beq	a0,a5,ffffffffc0203840 <insert_vma_struct+0x4a>
        if (mmap_prev->vm_start > vma->vm_start)
ffffffffc0203830:	fe87b703          	ld	a4,-24(a5)
    assert(prev->vm_end <= next->vm_start);
ffffffffc0203834:	05076963          	bltu	a4,a6,ffffffffc0203886 <insert_vma_struct+0x90>
    assert(next->vm_start < next->vm_end);
ffffffffc0203838:	ff07b603          	ld	a2,-16(a5)
ffffffffc020383c:	02c77363          	bgeu	a4,a2,ffffffffc0203862 <insert_vma_struct+0x6c>
    }

    vma->vm_mm = mm;
    list_add_after(le_prev, &(vma->list_link));

    mm->map_count++;
ffffffffc0203840:	5118                	lw	a4,32(a0)
    vma->vm_mm = mm;
ffffffffc0203842:	e188                	sd	a0,0(a1)
    list_add_after(le_prev, &(vma->list_link));
ffffffffc0203844:	02058613          	addi	a2,a1,32
    prev->next = next->prev = elm;
ffffffffc0203848:	e390                	sd	a2,0(a5)
ffffffffc020384a:	e690                	sd	a2,8(a3)
}
ffffffffc020384c:	60a2                	ld	ra,8(sp)
    elm->next = next;
ffffffffc020384e:	f59c                	sd	a5,40(a1)
    elm->prev = prev;
ffffffffc0203850:	f194                	sd	a3,32(a1)
    mm->map_count++;
ffffffffc0203852:	0017079b          	addiw	a5,a4,1
ffffffffc0203856:	d11c                	sw	a5,32(a0)
}
ffffffffc0203858:	0141                	addi	sp,sp,16
ffffffffc020385a:	8082                	ret
    if (le_prev != list)
ffffffffc020385c:	fca690e3          	bne	a3,a0,ffffffffc020381c <insert_vma_struct+0x26>
ffffffffc0203860:	bfd1                	j	ffffffffc0203834 <insert_vma_struct+0x3e>
ffffffffc0203862:	f01ff0ef          	jal	ra,ffffffffc0203762 <check_vma_overlap.part.0>
    assert(vma->vm_start < vma->vm_end);
ffffffffc0203866:	00003697          	auipc	a3,0x3
ffffffffc020386a:	58268693          	addi	a3,a3,1410 # ffffffffc0206de8 <default_pmm_manager+0x7b8>
ffffffffc020386e:	00003617          	auipc	a2,0x3
ffffffffc0203872:	a1260613          	addi	a2,a2,-1518 # ffffffffc0206280 <commands+0x868>
ffffffffc0203876:	07a00593          	li	a1,122
ffffffffc020387a:	00003517          	auipc	a0,0x3
ffffffffc020387e:	55e50513          	addi	a0,a0,1374 # ffffffffc0206dd8 <default_pmm_manager+0x7a8>
ffffffffc0203882:	c0dfc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(prev->vm_end <= next->vm_start);
ffffffffc0203886:	00003697          	auipc	a3,0x3
ffffffffc020388a:	5a268693          	addi	a3,a3,1442 # ffffffffc0206e28 <default_pmm_manager+0x7f8>
ffffffffc020388e:	00003617          	auipc	a2,0x3
ffffffffc0203892:	9f260613          	addi	a2,a2,-1550 # ffffffffc0206280 <commands+0x868>
ffffffffc0203896:	07300593          	li	a1,115
ffffffffc020389a:	00003517          	auipc	a0,0x3
ffffffffc020389e:	53e50513          	addi	a0,a0,1342 # ffffffffc0206dd8 <default_pmm_manager+0x7a8>
ffffffffc02038a2:	bedfc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(prev->vm_start < prev->vm_end);
ffffffffc02038a6:	00003697          	auipc	a3,0x3
ffffffffc02038aa:	56268693          	addi	a3,a3,1378 # ffffffffc0206e08 <default_pmm_manager+0x7d8>
ffffffffc02038ae:	00003617          	auipc	a2,0x3
ffffffffc02038b2:	9d260613          	addi	a2,a2,-1582 # ffffffffc0206280 <commands+0x868>
ffffffffc02038b6:	07200593          	li	a1,114
ffffffffc02038ba:	00003517          	auipc	a0,0x3
ffffffffc02038be:	51e50513          	addi	a0,a0,1310 # ffffffffc0206dd8 <default_pmm_manager+0x7a8>
ffffffffc02038c2:	bcdfc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02038c6 <mm_destroy>:

// mm_destroy - free mm and mm internal fields
void mm_destroy(struct mm_struct *mm)
{
    assert(mm_count(mm) == 0);
ffffffffc02038c6:	591c                	lw	a5,48(a0)
{
ffffffffc02038c8:	1141                	addi	sp,sp,-16
ffffffffc02038ca:	e406                	sd	ra,8(sp)
ffffffffc02038cc:	e022                	sd	s0,0(sp)
    assert(mm_count(mm) == 0);
ffffffffc02038ce:	e78d                	bnez	a5,ffffffffc02038f8 <mm_destroy+0x32>
ffffffffc02038d0:	842a                	mv	s0,a0
    return listelm->next;
ffffffffc02038d2:	6508                	ld	a0,8(a0)

    list_entry_t *list = &(mm->mmap_list), *le;
    while ((le = list_next(list)) != list)
ffffffffc02038d4:	00a40c63          	beq	s0,a0,ffffffffc02038ec <mm_destroy+0x26>
    __list_del(listelm->prev, listelm->next);
ffffffffc02038d8:	6118                	ld	a4,0(a0)
ffffffffc02038da:	651c                	ld	a5,8(a0)
    {
        list_del(le);
        kfree(le2vma(le, list_link)); // kfree vma
ffffffffc02038dc:	1501                	addi	a0,a0,-32
    prev->next = next;
ffffffffc02038de:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc02038e0:	e398                	sd	a4,0(a5)
ffffffffc02038e2:	d30fe0ef          	jal	ra,ffffffffc0201e12 <kfree>
    return listelm->next;
ffffffffc02038e6:	6408                	ld	a0,8(s0)
    while ((le = list_next(list)) != list)
ffffffffc02038e8:	fea418e3          	bne	s0,a0,ffffffffc02038d8 <mm_destroy+0x12>
    }
    kfree(mm); // kfree mm
ffffffffc02038ec:	8522                	mv	a0,s0
    mm = NULL;
}
ffffffffc02038ee:	6402                	ld	s0,0(sp)
ffffffffc02038f0:	60a2                	ld	ra,8(sp)
ffffffffc02038f2:	0141                	addi	sp,sp,16
    kfree(mm); // kfree mm
ffffffffc02038f4:	d1efe06f          	j	ffffffffc0201e12 <kfree>
    assert(mm_count(mm) == 0);
ffffffffc02038f8:	00003697          	auipc	a3,0x3
ffffffffc02038fc:	55068693          	addi	a3,a3,1360 # ffffffffc0206e48 <default_pmm_manager+0x818>
ffffffffc0203900:	00003617          	auipc	a2,0x3
ffffffffc0203904:	98060613          	addi	a2,a2,-1664 # ffffffffc0206280 <commands+0x868>
ffffffffc0203908:	09e00593          	li	a1,158
ffffffffc020390c:	00003517          	auipc	a0,0x3
ffffffffc0203910:	4cc50513          	addi	a0,a0,1228 # ffffffffc0206dd8 <default_pmm_manager+0x7a8>
ffffffffc0203914:	b7bfc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203918 <mm_map>:

int mm_map(struct mm_struct *mm, uintptr_t addr, size_t len, uint32_t vm_flags,
           struct vma_struct **vma_store)
{
ffffffffc0203918:	7139                	addi	sp,sp,-64
ffffffffc020391a:	f822                	sd	s0,48(sp)
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc020391c:	6405                	lui	s0,0x1
ffffffffc020391e:	147d                	addi	s0,s0,-1
ffffffffc0203920:	77fd                	lui	a5,0xfffff
ffffffffc0203922:	9622                	add	a2,a2,s0
ffffffffc0203924:	962e                	add	a2,a2,a1
{
ffffffffc0203926:	f426                	sd	s1,40(sp)
ffffffffc0203928:	fc06                	sd	ra,56(sp)
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc020392a:	00f5f4b3          	and	s1,a1,a5
{
ffffffffc020392e:	f04a                	sd	s2,32(sp)
ffffffffc0203930:	ec4e                	sd	s3,24(sp)
ffffffffc0203932:	e852                	sd	s4,16(sp)
ffffffffc0203934:	e456                	sd	s5,8(sp)
    if (!USER_ACCESS(start, end))
ffffffffc0203936:	002005b7          	lui	a1,0x200
ffffffffc020393a:	00f67433          	and	s0,a2,a5
ffffffffc020393e:	06b4e363          	bltu	s1,a1,ffffffffc02039a4 <mm_map+0x8c>
ffffffffc0203942:	0684f163          	bgeu	s1,s0,ffffffffc02039a4 <mm_map+0x8c>
ffffffffc0203946:	4785                	li	a5,1
ffffffffc0203948:	07fe                	slli	a5,a5,0x1f
ffffffffc020394a:	0487ed63          	bltu	a5,s0,ffffffffc02039a4 <mm_map+0x8c>
ffffffffc020394e:	89aa                	mv	s3,a0
    {
        return -E_INVAL;
    }

    assert(mm != NULL);
ffffffffc0203950:	cd21                	beqz	a0,ffffffffc02039a8 <mm_map+0x90>

    int ret = -E_INVAL;

    struct vma_struct *vma;
    if ((vma = find_vma(mm, start)) != NULL && end > vma->vm_start)
ffffffffc0203952:	85a6                	mv	a1,s1
ffffffffc0203954:	8ab6                	mv	s5,a3
ffffffffc0203956:	8a3a                	mv	s4,a4
ffffffffc0203958:	e5fff0ef          	jal	ra,ffffffffc02037b6 <find_vma>
ffffffffc020395c:	c501                	beqz	a0,ffffffffc0203964 <mm_map+0x4c>
ffffffffc020395e:	651c                	ld	a5,8(a0)
ffffffffc0203960:	0487e263          	bltu	a5,s0,ffffffffc02039a4 <mm_map+0x8c>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203964:	03000513          	li	a0,48
ffffffffc0203968:	bfafe0ef          	jal	ra,ffffffffc0201d62 <kmalloc>
ffffffffc020396c:	892a                	mv	s2,a0
    {
        goto out;
    }
    ret = -E_NO_MEM;
ffffffffc020396e:	5571                	li	a0,-4
    if (vma != NULL)
ffffffffc0203970:	02090163          	beqz	s2,ffffffffc0203992 <mm_map+0x7a>

    if ((vma = vma_create(start, end, vm_flags)) == NULL)
    {
        goto out;
    }
    insert_vma_struct(mm, vma);
ffffffffc0203974:	854e                	mv	a0,s3
        vma->vm_start = vm_start;
ffffffffc0203976:	00993423          	sd	s1,8(s2)
        vma->vm_end = vm_end;
ffffffffc020397a:	00893823          	sd	s0,16(s2)
        vma->vm_flags = vm_flags;
ffffffffc020397e:	01592c23          	sw	s5,24(s2)
    insert_vma_struct(mm, vma);
ffffffffc0203982:	85ca                	mv	a1,s2
ffffffffc0203984:	e73ff0ef          	jal	ra,ffffffffc02037f6 <insert_vma_struct>
    if (vma_store != NULL)
    {
        *vma_store = vma;
    }
    ret = 0;
ffffffffc0203988:	4501                	li	a0,0
    if (vma_store != NULL)
ffffffffc020398a:	000a0463          	beqz	s4,ffffffffc0203992 <mm_map+0x7a>
        *vma_store = vma;
ffffffffc020398e:	012a3023          	sd	s2,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8bc8>

out:
    return ret;
}
ffffffffc0203992:	70e2                	ld	ra,56(sp)
ffffffffc0203994:	7442                	ld	s0,48(sp)
ffffffffc0203996:	74a2                	ld	s1,40(sp)
ffffffffc0203998:	7902                	ld	s2,32(sp)
ffffffffc020399a:	69e2                	ld	s3,24(sp)
ffffffffc020399c:	6a42                	ld	s4,16(sp)
ffffffffc020399e:	6aa2                	ld	s5,8(sp)
ffffffffc02039a0:	6121                	addi	sp,sp,64
ffffffffc02039a2:	8082                	ret
        return -E_INVAL;
ffffffffc02039a4:	5575                	li	a0,-3
ffffffffc02039a6:	b7f5                	j	ffffffffc0203992 <mm_map+0x7a>
    assert(mm != NULL);
ffffffffc02039a8:	00003697          	auipc	a3,0x3
ffffffffc02039ac:	4b868693          	addi	a3,a3,1208 # ffffffffc0206e60 <default_pmm_manager+0x830>
ffffffffc02039b0:	00003617          	auipc	a2,0x3
ffffffffc02039b4:	8d060613          	addi	a2,a2,-1840 # ffffffffc0206280 <commands+0x868>
ffffffffc02039b8:	0b300593          	li	a1,179
ffffffffc02039bc:	00003517          	auipc	a0,0x3
ffffffffc02039c0:	41c50513          	addi	a0,a0,1052 # ffffffffc0206dd8 <default_pmm_manager+0x7a8>
ffffffffc02039c4:	acbfc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02039c8 <dup_mmap>:

int dup_mmap(struct mm_struct *to, struct mm_struct *from)
{
ffffffffc02039c8:	7139                	addi	sp,sp,-64
ffffffffc02039ca:	fc06                	sd	ra,56(sp)
ffffffffc02039cc:	f822                	sd	s0,48(sp)
ffffffffc02039ce:	f426                	sd	s1,40(sp)
ffffffffc02039d0:	f04a                	sd	s2,32(sp)
ffffffffc02039d2:	ec4e                	sd	s3,24(sp)
ffffffffc02039d4:	e852                	sd	s4,16(sp)
ffffffffc02039d6:	e456                	sd	s5,8(sp)
    assert(to != NULL && from != NULL);
ffffffffc02039d8:	c52d                	beqz	a0,ffffffffc0203a42 <dup_mmap+0x7a>
ffffffffc02039da:	892a                	mv	s2,a0
ffffffffc02039dc:	84ae                	mv	s1,a1
    list_entry_t *list = &(from->mmap_list), *le = list;
ffffffffc02039de:	842e                	mv	s0,a1
    assert(to != NULL && from != NULL);
ffffffffc02039e0:	e595                	bnez	a1,ffffffffc0203a0c <dup_mmap+0x44>
ffffffffc02039e2:	a085                	j	ffffffffc0203a42 <dup_mmap+0x7a>
        if (nvma == NULL)
        {
            return -E_NO_MEM;
        }

        insert_vma_struct(to, nvma);
ffffffffc02039e4:	854a                	mv	a0,s2
        vma->vm_start = vm_start;
ffffffffc02039e6:	0155b423          	sd	s5,8(a1) # 200008 <_binary_obj___user_exit_out_size+0x1f4ec8>
        vma->vm_end = vm_end;
ffffffffc02039ea:	0145b823          	sd	s4,16(a1)
        vma->vm_flags = vm_flags;
ffffffffc02039ee:	0135ac23          	sw	s3,24(a1)
        insert_vma_struct(to, nvma);
ffffffffc02039f2:	e05ff0ef          	jal	ra,ffffffffc02037f6 <insert_vma_struct>

        bool share = 0;
        if (copy_range(to->pgdir, from->pgdir, vma->vm_start, vma->vm_end, share) != 0)
ffffffffc02039f6:	ff043683          	ld	a3,-16(s0) # ff0 <_binary_obj___user_faultread_out_size-0x8bd8>
ffffffffc02039fa:	fe843603          	ld	a2,-24(s0)
ffffffffc02039fe:	6c8c                	ld	a1,24(s1)
ffffffffc0203a00:	01893503          	ld	a0,24(s2)
ffffffffc0203a04:	4701                	li	a4,0
ffffffffc0203a06:	a19ff0ef          	jal	ra,ffffffffc020341e <copy_range>
ffffffffc0203a0a:	e105                	bnez	a0,ffffffffc0203a2a <dup_mmap+0x62>
    return listelm->prev;
ffffffffc0203a0c:	6000                	ld	s0,0(s0)
    while ((le = list_prev(le)) != list)
ffffffffc0203a0e:	02848863          	beq	s1,s0,ffffffffc0203a3e <dup_mmap+0x76>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203a12:	03000513          	li	a0,48
        nvma = vma_create(vma->vm_start, vma->vm_end, vma->vm_flags);
ffffffffc0203a16:	fe843a83          	ld	s5,-24(s0)
ffffffffc0203a1a:	ff043a03          	ld	s4,-16(s0)
ffffffffc0203a1e:	ff842983          	lw	s3,-8(s0)
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203a22:	b40fe0ef          	jal	ra,ffffffffc0201d62 <kmalloc>
ffffffffc0203a26:	85aa                	mv	a1,a0
    if (vma != NULL)
ffffffffc0203a28:	fd55                	bnez	a0,ffffffffc02039e4 <dup_mmap+0x1c>
            return -E_NO_MEM;
ffffffffc0203a2a:	5571                	li	a0,-4
        {
            return -E_NO_MEM;
        }
    }
    return 0;
}
ffffffffc0203a2c:	70e2                	ld	ra,56(sp)
ffffffffc0203a2e:	7442                	ld	s0,48(sp)
ffffffffc0203a30:	74a2                	ld	s1,40(sp)
ffffffffc0203a32:	7902                	ld	s2,32(sp)
ffffffffc0203a34:	69e2                	ld	s3,24(sp)
ffffffffc0203a36:	6a42                	ld	s4,16(sp)
ffffffffc0203a38:	6aa2                	ld	s5,8(sp)
ffffffffc0203a3a:	6121                	addi	sp,sp,64
ffffffffc0203a3c:	8082                	ret
    return 0;
ffffffffc0203a3e:	4501                	li	a0,0
ffffffffc0203a40:	b7f5                	j	ffffffffc0203a2c <dup_mmap+0x64>
    assert(to != NULL && from != NULL);
ffffffffc0203a42:	00003697          	auipc	a3,0x3
ffffffffc0203a46:	42e68693          	addi	a3,a3,1070 # ffffffffc0206e70 <default_pmm_manager+0x840>
ffffffffc0203a4a:	00003617          	auipc	a2,0x3
ffffffffc0203a4e:	83660613          	addi	a2,a2,-1994 # ffffffffc0206280 <commands+0x868>
ffffffffc0203a52:	0cf00593          	li	a1,207
ffffffffc0203a56:	00003517          	auipc	a0,0x3
ffffffffc0203a5a:	38250513          	addi	a0,a0,898 # ffffffffc0206dd8 <default_pmm_manager+0x7a8>
ffffffffc0203a5e:	a31fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203a62 <exit_mmap>:

void exit_mmap(struct mm_struct *mm)
{
ffffffffc0203a62:	1101                	addi	sp,sp,-32
ffffffffc0203a64:	ec06                	sd	ra,24(sp)
ffffffffc0203a66:	e822                	sd	s0,16(sp)
ffffffffc0203a68:	e426                	sd	s1,8(sp)
ffffffffc0203a6a:	e04a                	sd	s2,0(sp)
    assert(mm != NULL && mm_count(mm) == 0);
ffffffffc0203a6c:	c531                	beqz	a0,ffffffffc0203ab8 <exit_mmap+0x56>
ffffffffc0203a6e:	591c                	lw	a5,48(a0)
ffffffffc0203a70:	84aa                	mv	s1,a0
ffffffffc0203a72:	e3b9                	bnez	a5,ffffffffc0203ab8 <exit_mmap+0x56>
    return listelm->next;
ffffffffc0203a74:	6500                	ld	s0,8(a0)
    pde_t *pgdir = mm->pgdir;
ffffffffc0203a76:	01853903          	ld	s2,24(a0)
    list_entry_t *list = &(mm->mmap_list), *le = list;
    while ((le = list_next(le)) != list)
ffffffffc0203a7a:	02850663          	beq	a0,s0,ffffffffc0203aa6 <exit_mmap+0x44>
    {
        struct vma_struct *vma = le2vma(le, list_link);
        unmap_range(pgdir, vma->vm_start, vma->vm_end);
ffffffffc0203a7e:	ff043603          	ld	a2,-16(s0)
ffffffffc0203a82:	fe843583          	ld	a1,-24(s0)
ffffffffc0203a86:	854a                	mv	a0,s2
ffffffffc0203a88:	fecfe0ef          	jal	ra,ffffffffc0202274 <unmap_range>
ffffffffc0203a8c:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != list)
ffffffffc0203a8e:	fe8498e3          	bne	s1,s0,ffffffffc0203a7e <exit_mmap+0x1c>
ffffffffc0203a92:	6400                	ld	s0,8(s0)
    }
    while ((le = list_next(le)) != list)
ffffffffc0203a94:	00848c63          	beq	s1,s0,ffffffffc0203aac <exit_mmap+0x4a>
    {
        struct vma_struct *vma = le2vma(le, list_link);
        exit_range(pgdir, vma->vm_start, vma->vm_end);
ffffffffc0203a98:	ff043603          	ld	a2,-16(s0)
ffffffffc0203a9c:	fe843583          	ld	a1,-24(s0)
ffffffffc0203aa0:	854a                	mv	a0,s2
ffffffffc0203aa2:	919fe0ef          	jal	ra,ffffffffc02023ba <exit_range>
ffffffffc0203aa6:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != list)
ffffffffc0203aa8:	fe8498e3          	bne	s1,s0,ffffffffc0203a98 <exit_mmap+0x36>
    }
}
ffffffffc0203aac:	60e2                	ld	ra,24(sp)
ffffffffc0203aae:	6442                	ld	s0,16(sp)
ffffffffc0203ab0:	64a2                	ld	s1,8(sp)
ffffffffc0203ab2:	6902                	ld	s2,0(sp)
ffffffffc0203ab4:	6105                	addi	sp,sp,32
ffffffffc0203ab6:	8082                	ret
    assert(mm != NULL && mm_count(mm) == 0);
ffffffffc0203ab8:	00003697          	auipc	a3,0x3
ffffffffc0203abc:	3d868693          	addi	a3,a3,984 # ffffffffc0206e90 <default_pmm_manager+0x860>
ffffffffc0203ac0:	00002617          	auipc	a2,0x2
ffffffffc0203ac4:	7c060613          	addi	a2,a2,1984 # ffffffffc0206280 <commands+0x868>
ffffffffc0203ac8:	0e800593          	li	a1,232
ffffffffc0203acc:	00003517          	auipc	a0,0x3
ffffffffc0203ad0:	30c50513          	addi	a0,a0,780 # ffffffffc0206dd8 <default_pmm_manager+0x7a8>
ffffffffc0203ad4:	9bbfc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203ad8 <vmm_init>:
}

// vmm_init - initialize virtual memory management
//          - now just call check_vmm to check correctness of vmm
void vmm_init(void)
{
ffffffffc0203ad8:	7139                	addi	sp,sp,-64
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0203ada:	04000513          	li	a0,64
{
ffffffffc0203ade:	fc06                	sd	ra,56(sp)
ffffffffc0203ae0:	f822                	sd	s0,48(sp)
ffffffffc0203ae2:	f426                	sd	s1,40(sp)
ffffffffc0203ae4:	f04a                	sd	s2,32(sp)
ffffffffc0203ae6:	ec4e                	sd	s3,24(sp)
ffffffffc0203ae8:	e852                	sd	s4,16(sp)
ffffffffc0203aea:	e456                	sd	s5,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0203aec:	a76fe0ef          	jal	ra,ffffffffc0201d62 <kmalloc>
    if (mm != NULL)
ffffffffc0203af0:	2e050663          	beqz	a0,ffffffffc0203ddc <vmm_init+0x304>
ffffffffc0203af4:	84aa                	mv	s1,a0
    elm->prev = elm->next = elm;
ffffffffc0203af6:	e508                	sd	a0,8(a0)
ffffffffc0203af8:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc0203afa:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc0203afe:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc0203b02:	02052023          	sw	zero,32(a0)
        mm->sm_priv = NULL;
ffffffffc0203b06:	02053423          	sd	zero,40(a0)
ffffffffc0203b0a:	02052823          	sw	zero,48(a0)
ffffffffc0203b0e:	02053c23          	sd	zero,56(a0)
ffffffffc0203b12:	03200413          	li	s0,50
ffffffffc0203b16:	a811                	j	ffffffffc0203b2a <vmm_init+0x52>
        vma->vm_start = vm_start;
ffffffffc0203b18:	e500                	sd	s0,8(a0)
        vma->vm_end = vm_end;
ffffffffc0203b1a:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0203b1c:	00052c23          	sw	zero,24(a0)
    assert(mm != NULL);

    int step1 = 10, step2 = step1 * 10;

    int i;
    for (i = step1; i >= 1; i--)
ffffffffc0203b20:	146d                	addi	s0,s0,-5
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0203b22:	8526                	mv	a0,s1
ffffffffc0203b24:	cd3ff0ef          	jal	ra,ffffffffc02037f6 <insert_vma_struct>
    for (i = step1; i >= 1; i--)
ffffffffc0203b28:	c80d                	beqz	s0,ffffffffc0203b5a <vmm_init+0x82>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203b2a:	03000513          	li	a0,48
ffffffffc0203b2e:	a34fe0ef          	jal	ra,ffffffffc0201d62 <kmalloc>
ffffffffc0203b32:	85aa                	mv	a1,a0
ffffffffc0203b34:	00240793          	addi	a5,s0,2
    if (vma != NULL)
ffffffffc0203b38:	f165                	bnez	a0,ffffffffc0203b18 <vmm_init+0x40>
        assert(vma != NULL);
ffffffffc0203b3a:	00003697          	auipc	a3,0x3
ffffffffc0203b3e:	4ee68693          	addi	a3,a3,1262 # ffffffffc0207028 <default_pmm_manager+0x9f8>
ffffffffc0203b42:	00002617          	auipc	a2,0x2
ffffffffc0203b46:	73e60613          	addi	a2,a2,1854 # ffffffffc0206280 <commands+0x868>
ffffffffc0203b4a:	12c00593          	li	a1,300
ffffffffc0203b4e:	00003517          	auipc	a0,0x3
ffffffffc0203b52:	28a50513          	addi	a0,a0,650 # ffffffffc0206dd8 <default_pmm_manager+0x7a8>
ffffffffc0203b56:	939fc0ef          	jal	ra,ffffffffc020048e <__panic>
ffffffffc0203b5a:	03700413          	li	s0,55
    }

    for (i = step1 + 1; i <= step2; i++)
ffffffffc0203b5e:	1f900913          	li	s2,505
ffffffffc0203b62:	a819                	j	ffffffffc0203b78 <vmm_init+0xa0>
        vma->vm_start = vm_start;
ffffffffc0203b64:	e500                	sd	s0,8(a0)
        vma->vm_end = vm_end;
ffffffffc0203b66:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0203b68:	00052c23          	sw	zero,24(a0)
    for (i = step1 + 1; i <= step2; i++)
ffffffffc0203b6c:	0415                	addi	s0,s0,5
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0203b6e:	8526                	mv	a0,s1
ffffffffc0203b70:	c87ff0ef          	jal	ra,ffffffffc02037f6 <insert_vma_struct>
    for (i = step1 + 1; i <= step2; i++)
ffffffffc0203b74:	03240a63          	beq	s0,s2,ffffffffc0203ba8 <vmm_init+0xd0>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203b78:	03000513          	li	a0,48
ffffffffc0203b7c:	9e6fe0ef          	jal	ra,ffffffffc0201d62 <kmalloc>
ffffffffc0203b80:	85aa                	mv	a1,a0
ffffffffc0203b82:	00240793          	addi	a5,s0,2
    if (vma != NULL)
ffffffffc0203b86:	fd79                	bnez	a0,ffffffffc0203b64 <vmm_init+0x8c>
        assert(vma != NULL);
ffffffffc0203b88:	00003697          	auipc	a3,0x3
ffffffffc0203b8c:	4a068693          	addi	a3,a3,1184 # ffffffffc0207028 <default_pmm_manager+0x9f8>
ffffffffc0203b90:	00002617          	auipc	a2,0x2
ffffffffc0203b94:	6f060613          	addi	a2,a2,1776 # ffffffffc0206280 <commands+0x868>
ffffffffc0203b98:	13300593          	li	a1,307
ffffffffc0203b9c:	00003517          	auipc	a0,0x3
ffffffffc0203ba0:	23c50513          	addi	a0,a0,572 # ffffffffc0206dd8 <default_pmm_manager+0x7a8>
ffffffffc0203ba4:	8ebfc0ef          	jal	ra,ffffffffc020048e <__panic>
    return listelm->next;
ffffffffc0203ba8:	649c                	ld	a5,8(s1)
ffffffffc0203baa:	471d                	li	a4,7
    }

    list_entry_t *le = list_next(&(mm->mmap_list));

    for (i = 1; i <= step2; i++)
ffffffffc0203bac:	1fb00593          	li	a1,507
    {
        assert(le != &(mm->mmap_list));
ffffffffc0203bb0:	16f48663          	beq	s1,a5,ffffffffc0203d1c <vmm_init+0x244>
        struct vma_struct *mmap = le2vma(le, list_link);
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0203bb4:	fe87b603          	ld	a2,-24(a5) # ffffffffffffefe8 <end+0x3fd546d4>
ffffffffc0203bb8:	ffe70693          	addi	a3,a4,-2
ffffffffc0203bbc:	10d61063          	bne	a2,a3,ffffffffc0203cbc <vmm_init+0x1e4>
ffffffffc0203bc0:	ff07b683          	ld	a3,-16(a5)
ffffffffc0203bc4:	0ed71c63          	bne	a4,a3,ffffffffc0203cbc <vmm_init+0x1e4>
    for (i = 1; i <= step2; i++)
ffffffffc0203bc8:	0715                	addi	a4,a4,5
ffffffffc0203bca:	679c                	ld	a5,8(a5)
ffffffffc0203bcc:	feb712e3          	bne	a4,a1,ffffffffc0203bb0 <vmm_init+0xd8>
ffffffffc0203bd0:	4a1d                	li	s4,7
ffffffffc0203bd2:	4415                	li	s0,5
        le = list_next(le);
    }

    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc0203bd4:	1f900a93          	li	s5,505
    {
        struct vma_struct *vma1 = find_vma(mm, i);
ffffffffc0203bd8:	85a2                	mv	a1,s0
ffffffffc0203bda:	8526                	mv	a0,s1
ffffffffc0203bdc:	bdbff0ef          	jal	ra,ffffffffc02037b6 <find_vma>
ffffffffc0203be0:	892a                	mv	s2,a0
        assert(vma1 != NULL);
ffffffffc0203be2:	16050d63          	beqz	a0,ffffffffc0203d5c <vmm_init+0x284>
        struct vma_struct *vma2 = find_vma(mm, i + 1);
ffffffffc0203be6:	00140593          	addi	a1,s0,1
ffffffffc0203bea:	8526                	mv	a0,s1
ffffffffc0203bec:	bcbff0ef          	jal	ra,ffffffffc02037b6 <find_vma>
ffffffffc0203bf0:	89aa                	mv	s3,a0
        assert(vma2 != NULL);
ffffffffc0203bf2:	14050563          	beqz	a0,ffffffffc0203d3c <vmm_init+0x264>
        struct vma_struct *vma3 = find_vma(mm, i + 2);
ffffffffc0203bf6:	85d2                	mv	a1,s4
ffffffffc0203bf8:	8526                	mv	a0,s1
ffffffffc0203bfa:	bbdff0ef          	jal	ra,ffffffffc02037b6 <find_vma>
        assert(vma3 == NULL);
ffffffffc0203bfe:	16051f63          	bnez	a0,ffffffffc0203d7c <vmm_init+0x2a4>
        struct vma_struct *vma4 = find_vma(mm, i + 3);
ffffffffc0203c02:	00340593          	addi	a1,s0,3
ffffffffc0203c06:	8526                	mv	a0,s1
ffffffffc0203c08:	bafff0ef          	jal	ra,ffffffffc02037b6 <find_vma>
        assert(vma4 == NULL);
ffffffffc0203c0c:	1a051863          	bnez	a0,ffffffffc0203dbc <vmm_init+0x2e4>
        struct vma_struct *vma5 = find_vma(mm, i + 4);
ffffffffc0203c10:	00440593          	addi	a1,s0,4
ffffffffc0203c14:	8526                	mv	a0,s1
ffffffffc0203c16:	ba1ff0ef          	jal	ra,ffffffffc02037b6 <find_vma>
        assert(vma5 == NULL);
ffffffffc0203c1a:	18051163          	bnez	a0,ffffffffc0203d9c <vmm_init+0x2c4>

        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc0203c1e:	00893783          	ld	a5,8(s2)
ffffffffc0203c22:	0a879d63          	bne	a5,s0,ffffffffc0203cdc <vmm_init+0x204>
ffffffffc0203c26:	01093783          	ld	a5,16(s2)
ffffffffc0203c2a:	0b479963          	bne	a5,s4,ffffffffc0203cdc <vmm_init+0x204>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc0203c2e:	0089b783          	ld	a5,8(s3)
ffffffffc0203c32:	0c879563          	bne	a5,s0,ffffffffc0203cfc <vmm_init+0x224>
ffffffffc0203c36:	0109b783          	ld	a5,16(s3)
ffffffffc0203c3a:	0d479163          	bne	a5,s4,ffffffffc0203cfc <vmm_init+0x224>
    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc0203c3e:	0415                	addi	s0,s0,5
ffffffffc0203c40:	0a15                	addi	s4,s4,5
ffffffffc0203c42:	f9541be3          	bne	s0,s5,ffffffffc0203bd8 <vmm_init+0x100>
ffffffffc0203c46:	4411                	li	s0,4
    }

    for (i = 4; i >= 0; i--)
ffffffffc0203c48:	597d                	li	s2,-1
    {
        struct vma_struct *vma_below_5 = find_vma(mm, i);
ffffffffc0203c4a:	85a2                	mv	a1,s0
ffffffffc0203c4c:	8526                	mv	a0,s1
ffffffffc0203c4e:	b69ff0ef          	jal	ra,ffffffffc02037b6 <find_vma>
ffffffffc0203c52:	0004059b          	sext.w	a1,s0
        if (vma_below_5 != NULL)
ffffffffc0203c56:	c90d                	beqz	a0,ffffffffc0203c88 <vmm_init+0x1b0>
        {
            cprintf("vma_below_5: i %x, start %x, end %x\n", i, vma_below_5->vm_start, vma_below_5->vm_end);
ffffffffc0203c58:	6914                	ld	a3,16(a0)
ffffffffc0203c5a:	6510                	ld	a2,8(a0)
ffffffffc0203c5c:	00003517          	auipc	a0,0x3
ffffffffc0203c60:	35450513          	addi	a0,a0,852 # ffffffffc0206fb0 <default_pmm_manager+0x980>
ffffffffc0203c64:	d30fc0ef          	jal	ra,ffffffffc0200194 <cprintf>
        }
        assert(vma_below_5 == NULL);
ffffffffc0203c68:	00003697          	auipc	a3,0x3
ffffffffc0203c6c:	37068693          	addi	a3,a3,880 # ffffffffc0206fd8 <default_pmm_manager+0x9a8>
ffffffffc0203c70:	00002617          	auipc	a2,0x2
ffffffffc0203c74:	61060613          	addi	a2,a2,1552 # ffffffffc0206280 <commands+0x868>
ffffffffc0203c78:	15900593          	li	a1,345
ffffffffc0203c7c:	00003517          	auipc	a0,0x3
ffffffffc0203c80:	15c50513          	addi	a0,a0,348 # ffffffffc0206dd8 <default_pmm_manager+0x7a8>
ffffffffc0203c84:	80bfc0ef          	jal	ra,ffffffffc020048e <__panic>
    for (i = 4; i >= 0; i--)
ffffffffc0203c88:	147d                	addi	s0,s0,-1
ffffffffc0203c8a:	fd2410e3          	bne	s0,s2,ffffffffc0203c4a <vmm_init+0x172>
    }

    mm_destroy(mm);
ffffffffc0203c8e:	8526                	mv	a0,s1
ffffffffc0203c90:	c37ff0ef          	jal	ra,ffffffffc02038c6 <mm_destroy>

    cprintf("check_vma_struct() succeeded!\n");
ffffffffc0203c94:	00003517          	auipc	a0,0x3
ffffffffc0203c98:	35c50513          	addi	a0,a0,860 # ffffffffc0206ff0 <default_pmm_manager+0x9c0>
ffffffffc0203c9c:	cf8fc0ef          	jal	ra,ffffffffc0200194 <cprintf>
}
ffffffffc0203ca0:	7442                	ld	s0,48(sp)
ffffffffc0203ca2:	70e2                	ld	ra,56(sp)
ffffffffc0203ca4:	74a2                	ld	s1,40(sp)
ffffffffc0203ca6:	7902                	ld	s2,32(sp)
ffffffffc0203ca8:	69e2                	ld	s3,24(sp)
ffffffffc0203caa:	6a42                	ld	s4,16(sp)
ffffffffc0203cac:	6aa2                	ld	s5,8(sp)
    cprintf("check_vmm() succeeded.\n");
ffffffffc0203cae:	00003517          	auipc	a0,0x3
ffffffffc0203cb2:	36250513          	addi	a0,a0,866 # ffffffffc0207010 <default_pmm_manager+0x9e0>
}
ffffffffc0203cb6:	6121                	addi	sp,sp,64
    cprintf("check_vmm() succeeded.\n");
ffffffffc0203cb8:	cdcfc06f          	j	ffffffffc0200194 <cprintf>
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0203cbc:	00003697          	auipc	a3,0x3
ffffffffc0203cc0:	20c68693          	addi	a3,a3,524 # ffffffffc0206ec8 <default_pmm_manager+0x898>
ffffffffc0203cc4:	00002617          	auipc	a2,0x2
ffffffffc0203cc8:	5bc60613          	addi	a2,a2,1468 # ffffffffc0206280 <commands+0x868>
ffffffffc0203ccc:	13d00593          	li	a1,317
ffffffffc0203cd0:	00003517          	auipc	a0,0x3
ffffffffc0203cd4:	10850513          	addi	a0,a0,264 # ffffffffc0206dd8 <default_pmm_manager+0x7a8>
ffffffffc0203cd8:	fb6fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc0203cdc:	00003697          	auipc	a3,0x3
ffffffffc0203ce0:	27468693          	addi	a3,a3,628 # ffffffffc0206f50 <default_pmm_manager+0x920>
ffffffffc0203ce4:	00002617          	auipc	a2,0x2
ffffffffc0203ce8:	59c60613          	addi	a2,a2,1436 # ffffffffc0206280 <commands+0x868>
ffffffffc0203cec:	14e00593          	li	a1,334
ffffffffc0203cf0:	00003517          	auipc	a0,0x3
ffffffffc0203cf4:	0e850513          	addi	a0,a0,232 # ffffffffc0206dd8 <default_pmm_manager+0x7a8>
ffffffffc0203cf8:	f96fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc0203cfc:	00003697          	auipc	a3,0x3
ffffffffc0203d00:	28468693          	addi	a3,a3,644 # ffffffffc0206f80 <default_pmm_manager+0x950>
ffffffffc0203d04:	00002617          	auipc	a2,0x2
ffffffffc0203d08:	57c60613          	addi	a2,a2,1404 # ffffffffc0206280 <commands+0x868>
ffffffffc0203d0c:	14f00593          	li	a1,335
ffffffffc0203d10:	00003517          	auipc	a0,0x3
ffffffffc0203d14:	0c850513          	addi	a0,a0,200 # ffffffffc0206dd8 <default_pmm_manager+0x7a8>
ffffffffc0203d18:	f76fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(le != &(mm->mmap_list));
ffffffffc0203d1c:	00003697          	auipc	a3,0x3
ffffffffc0203d20:	19468693          	addi	a3,a3,404 # ffffffffc0206eb0 <default_pmm_manager+0x880>
ffffffffc0203d24:	00002617          	auipc	a2,0x2
ffffffffc0203d28:	55c60613          	addi	a2,a2,1372 # ffffffffc0206280 <commands+0x868>
ffffffffc0203d2c:	13b00593          	li	a1,315
ffffffffc0203d30:	00003517          	auipc	a0,0x3
ffffffffc0203d34:	0a850513          	addi	a0,a0,168 # ffffffffc0206dd8 <default_pmm_manager+0x7a8>
ffffffffc0203d38:	f56fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma2 != NULL);
ffffffffc0203d3c:	00003697          	auipc	a3,0x3
ffffffffc0203d40:	1d468693          	addi	a3,a3,468 # ffffffffc0206f10 <default_pmm_manager+0x8e0>
ffffffffc0203d44:	00002617          	auipc	a2,0x2
ffffffffc0203d48:	53c60613          	addi	a2,a2,1340 # ffffffffc0206280 <commands+0x868>
ffffffffc0203d4c:	14600593          	li	a1,326
ffffffffc0203d50:	00003517          	auipc	a0,0x3
ffffffffc0203d54:	08850513          	addi	a0,a0,136 # ffffffffc0206dd8 <default_pmm_manager+0x7a8>
ffffffffc0203d58:	f36fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma1 != NULL);
ffffffffc0203d5c:	00003697          	auipc	a3,0x3
ffffffffc0203d60:	1a468693          	addi	a3,a3,420 # ffffffffc0206f00 <default_pmm_manager+0x8d0>
ffffffffc0203d64:	00002617          	auipc	a2,0x2
ffffffffc0203d68:	51c60613          	addi	a2,a2,1308 # ffffffffc0206280 <commands+0x868>
ffffffffc0203d6c:	14400593          	li	a1,324
ffffffffc0203d70:	00003517          	auipc	a0,0x3
ffffffffc0203d74:	06850513          	addi	a0,a0,104 # ffffffffc0206dd8 <default_pmm_manager+0x7a8>
ffffffffc0203d78:	f16fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma3 == NULL);
ffffffffc0203d7c:	00003697          	auipc	a3,0x3
ffffffffc0203d80:	1a468693          	addi	a3,a3,420 # ffffffffc0206f20 <default_pmm_manager+0x8f0>
ffffffffc0203d84:	00002617          	auipc	a2,0x2
ffffffffc0203d88:	4fc60613          	addi	a2,a2,1276 # ffffffffc0206280 <commands+0x868>
ffffffffc0203d8c:	14800593          	li	a1,328
ffffffffc0203d90:	00003517          	auipc	a0,0x3
ffffffffc0203d94:	04850513          	addi	a0,a0,72 # ffffffffc0206dd8 <default_pmm_manager+0x7a8>
ffffffffc0203d98:	ef6fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma5 == NULL);
ffffffffc0203d9c:	00003697          	auipc	a3,0x3
ffffffffc0203da0:	1a468693          	addi	a3,a3,420 # ffffffffc0206f40 <default_pmm_manager+0x910>
ffffffffc0203da4:	00002617          	auipc	a2,0x2
ffffffffc0203da8:	4dc60613          	addi	a2,a2,1244 # ffffffffc0206280 <commands+0x868>
ffffffffc0203dac:	14c00593          	li	a1,332
ffffffffc0203db0:	00003517          	auipc	a0,0x3
ffffffffc0203db4:	02850513          	addi	a0,a0,40 # ffffffffc0206dd8 <default_pmm_manager+0x7a8>
ffffffffc0203db8:	ed6fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma4 == NULL);
ffffffffc0203dbc:	00003697          	auipc	a3,0x3
ffffffffc0203dc0:	17468693          	addi	a3,a3,372 # ffffffffc0206f30 <default_pmm_manager+0x900>
ffffffffc0203dc4:	00002617          	auipc	a2,0x2
ffffffffc0203dc8:	4bc60613          	addi	a2,a2,1212 # ffffffffc0206280 <commands+0x868>
ffffffffc0203dcc:	14a00593          	li	a1,330
ffffffffc0203dd0:	00003517          	auipc	a0,0x3
ffffffffc0203dd4:	00850513          	addi	a0,a0,8 # ffffffffc0206dd8 <default_pmm_manager+0x7a8>
ffffffffc0203dd8:	eb6fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(mm != NULL);
ffffffffc0203ddc:	00003697          	auipc	a3,0x3
ffffffffc0203de0:	08468693          	addi	a3,a3,132 # ffffffffc0206e60 <default_pmm_manager+0x830>
ffffffffc0203de4:	00002617          	auipc	a2,0x2
ffffffffc0203de8:	49c60613          	addi	a2,a2,1180 # ffffffffc0206280 <commands+0x868>
ffffffffc0203dec:	12400593          	li	a1,292
ffffffffc0203df0:	00003517          	auipc	a0,0x3
ffffffffc0203df4:	fe850513          	addi	a0,a0,-24 # ffffffffc0206dd8 <default_pmm_manager+0x7a8>
ffffffffc0203df8:	e96fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203dfc <user_mem_check>:
}
bool user_mem_check(struct mm_struct *mm, uintptr_t addr, size_t len, bool write)
{
ffffffffc0203dfc:	7179                	addi	sp,sp,-48
ffffffffc0203dfe:	f022                	sd	s0,32(sp)
ffffffffc0203e00:	f406                	sd	ra,40(sp)
ffffffffc0203e02:	ec26                	sd	s1,24(sp)
ffffffffc0203e04:	e84a                	sd	s2,16(sp)
ffffffffc0203e06:	e44e                	sd	s3,8(sp)
ffffffffc0203e08:	e052                	sd	s4,0(sp)
ffffffffc0203e0a:	842e                	mv	s0,a1
    if (mm != NULL)
ffffffffc0203e0c:	c135                	beqz	a0,ffffffffc0203e70 <user_mem_check+0x74>
    {
        if (!USER_ACCESS(addr, addr + len))
ffffffffc0203e0e:	002007b7          	lui	a5,0x200
ffffffffc0203e12:	04f5e663          	bltu	a1,a5,ffffffffc0203e5e <user_mem_check+0x62>
ffffffffc0203e16:	00c584b3          	add	s1,a1,a2
ffffffffc0203e1a:	0495f263          	bgeu	a1,s1,ffffffffc0203e5e <user_mem_check+0x62>
ffffffffc0203e1e:	4785                	li	a5,1
ffffffffc0203e20:	07fe                	slli	a5,a5,0x1f
ffffffffc0203e22:	0297ee63          	bltu	a5,s1,ffffffffc0203e5e <user_mem_check+0x62>
ffffffffc0203e26:	892a                	mv	s2,a0
ffffffffc0203e28:	89b6                	mv	s3,a3
            {
                return 0;
            }
            if (write && (vma->vm_flags & VM_STACK))
            {
                if (start < vma->vm_start + PGSIZE)
ffffffffc0203e2a:	6a05                	lui	s4,0x1
ffffffffc0203e2c:	a821                	j	ffffffffc0203e44 <user_mem_check+0x48>
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203e2e:	0027f693          	andi	a3,a5,2
                if (start < vma->vm_start + PGSIZE)
ffffffffc0203e32:	9752                	add	a4,a4,s4
            if (write && (vma->vm_flags & VM_STACK))
ffffffffc0203e34:	8ba1                	andi	a5,a5,8
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203e36:	c685                	beqz	a3,ffffffffc0203e5e <user_mem_check+0x62>
            if (write && (vma->vm_flags & VM_STACK))
ffffffffc0203e38:	c399                	beqz	a5,ffffffffc0203e3e <user_mem_check+0x42>
                if (start < vma->vm_start + PGSIZE)
ffffffffc0203e3a:	02e46263          	bltu	s0,a4,ffffffffc0203e5e <user_mem_check+0x62>
                { // check stack start & size
                    return 0;
                }
            }
            start = vma->vm_end;
ffffffffc0203e3e:	6900                	ld	s0,16(a0)
        while (start < end)
ffffffffc0203e40:	04947663          	bgeu	s0,s1,ffffffffc0203e8c <user_mem_check+0x90>
            if ((vma = find_vma(mm, start)) == NULL || start < vma->vm_start)
ffffffffc0203e44:	85a2                	mv	a1,s0
ffffffffc0203e46:	854a                	mv	a0,s2
ffffffffc0203e48:	96fff0ef          	jal	ra,ffffffffc02037b6 <find_vma>
ffffffffc0203e4c:	c909                	beqz	a0,ffffffffc0203e5e <user_mem_check+0x62>
ffffffffc0203e4e:	6518                	ld	a4,8(a0)
ffffffffc0203e50:	00e46763          	bltu	s0,a4,ffffffffc0203e5e <user_mem_check+0x62>
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203e54:	4d1c                	lw	a5,24(a0)
ffffffffc0203e56:	fc099ce3          	bnez	s3,ffffffffc0203e2e <user_mem_check+0x32>
ffffffffc0203e5a:	8b85                	andi	a5,a5,1
ffffffffc0203e5c:	f3ed                	bnez	a5,ffffffffc0203e3e <user_mem_check+0x42>
            return 0;
ffffffffc0203e5e:	4501                	li	a0,0
        }
        return 1;
    }
    return KERN_ACCESS(addr, addr + len);
ffffffffc0203e60:	70a2                	ld	ra,40(sp)
ffffffffc0203e62:	7402                	ld	s0,32(sp)
ffffffffc0203e64:	64e2                	ld	s1,24(sp)
ffffffffc0203e66:	6942                	ld	s2,16(sp)
ffffffffc0203e68:	69a2                	ld	s3,8(sp)
ffffffffc0203e6a:	6a02                	ld	s4,0(sp)
ffffffffc0203e6c:	6145                	addi	sp,sp,48
ffffffffc0203e6e:	8082                	ret
    return KERN_ACCESS(addr, addr + len);
ffffffffc0203e70:	c02007b7          	lui	a5,0xc0200
ffffffffc0203e74:	4501                	li	a0,0
ffffffffc0203e76:	fef5e5e3          	bltu	a1,a5,ffffffffc0203e60 <user_mem_check+0x64>
ffffffffc0203e7a:	962e                	add	a2,a2,a1
ffffffffc0203e7c:	fec5f2e3          	bgeu	a1,a2,ffffffffc0203e60 <user_mem_check+0x64>
ffffffffc0203e80:	c8000537          	lui	a0,0xc8000
ffffffffc0203e84:	0505                	addi	a0,a0,1
ffffffffc0203e86:	00a63533          	sltu	a0,a2,a0
ffffffffc0203e8a:	bfd9                	j	ffffffffc0203e60 <user_mem_check+0x64>
        return 1;
ffffffffc0203e8c:	4505                	li	a0,1
ffffffffc0203e8e:	bfc9                	j	ffffffffc0203e60 <user_mem_check+0x64>

ffffffffc0203e90 <kernel_thread_entry>:
.text
.globl kernel_thread_entry
kernel_thread_entry:        # void kernel_thread(void)
	move a0, s1
ffffffffc0203e90:	8526                	mv	a0,s1
	jalr s0
ffffffffc0203e92:	9402                	jalr	s0

	jal do_exit
ffffffffc0203e94:	61c000ef          	jal	ra,ffffffffc02044b0 <do_exit>

ffffffffc0203e98 <alloc_proc>:
void switch_to(struct context *from, struct context *to);

// alloc_proc - alloc a proc_struct and init all fields of proc_struct
static struct proc_struct *
alloc_proc(void)
{
ffffffffc0203e98:	1141                	addi	sp,sp,-16
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0203e9a:	10800513          	li	a0,264
{
ffffffffc0203e9e:	e022                	sd	s0,0(sp)
ffffffffc0203ea0:	e406                	sd	ra,8(sp)
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0203ea2:	ec1fd0ef          	jal	ra,ffffffffc0201d62 <kmalloc>
ffffffffc0203ea6:	842a                	mv	s0,a0
    if (proc != NULL)
ffffffffc0203ea8:	c525                	beqz	a0,ffffffffc0203f10 <alloc_proc+0x78>
         * below fields(add in LAB5) in proc_struct need to be initialized
         *       uint32_t wait_state;                        // waiting state
         *       struct proc_struct *cptr, *yptr, *optr;     // relations between processes
         */
        // LAB4原有
        proc->state = PROC_UNINIT;                  // 初始化进程状态为未初始化
ffffffffc0203eaa:	57fd                	li	a5,-1
ffffffffc0203eac:	1782                	slli	a5,a5,0x20
ffffffffc0203eae:	e11c                	sd	a5,0(a0)
        proc->runs = 0;                             // 初始化运行次数为0
        proc->kstack = 0;                           // 初始化内核栈为0（空指针），后续通过setup_kstack()为进程分配实际的内核栈空间
        proc->need_resched = 0;                     // 初始化不需要重新调度
        proc->parent = NULL;                        // 初始化父进程指针为NULL
        proc->mm = NULL;                            // 初始化内存管理结构指针为NULL
        memset(&(proc->context), 0, sizeof(struct context)); // 初始化上下文结构体，全部设为0，为后续保存现场做准备
ffffffffc0203eb0:	07000613          	li	a2,112
ffffffffc0203eb4:	4581                	li	a1,0
        proc->runs = 0;                             // 初始化运行次数为0
ffffffffc0203eb6:	00052423          	sw	zero,8(a0) # ffffffffc8000008 <end+0x7d556f4>
        proc->kstack = 0;                           // 初始化内核栈为0（空指针），后续通过setup_kstack()为进程分配实际的内核栈空间
ffffffffc0203eba:	00053823          	sd	zero,16(a0)
        proc->need_resched = 0;                     // 初始化不需要重新调度
ffffffffc0203ebe:	00053c23          	sd	zero,24(a0)
        proc->parent = NULL;                        // 初始化父进程指针为NULL
ffffffffc0203ec2:	02053023          	sd	zero,32(a0)
        proc->mm = NULL;                            // 初始化内存管理结构指针为NULL
ffffffffc0203ec6:	02053423          	sd	zero,40(a0)
        memset(&(proc->context), 0, sizeof(struct context)); // 初始化上下文结构体，全部设为0，为后续保存现场做准备
ffffffffc0203eca:	03050513          	addi	a0,a0,48
ffffffffc0203ece:	0b3010ef          	jal	ra,ffffffffc0205780 <memset>
        proc->tf = NULL;                            // 初始化陷阱帧为NULL
        proc->pgdir = boot_pgdir_pa;                // 初始化页目录表基址为boot_pgdir_pa
ffffffffc0203ed2:	000a7797          	auipc	a5,0xa7
ffffffffc0203ed6:	9f67b783          	ld	a5,-1546(a5) # ffffffffc02aa8c8 <boot_pgdir_pa>
ffffffffc0203eda:	f45c                	sd	a5,168(s0)
        proc->tf = NULL;                            // 初始化陷阱帧为NULL
ffffffffc0203edc:	0a043023          	sd	zero,160(s0)
        proc->flags = 0;                            // 初始化进程标志为0
ffffffffc0203ee0:	0a042823          	sw	zero,176(s0)
        memset(proc->name, 0, PROC_NAME_LEN + 1);   // 初始化进程名称数组全部清零，后续通过set_proc_name()设置具体的进程名称
ffffffffc0203ee4:	4641                	li	a2,16
ffffffffc0203ee6:	4581                	li	a1,0
ffffffffc0203ee8:	0b440513          	addi	a0,s0,180
ffffffffc0203eec:	095010ef          	jal	ra,ffffffffc0205780 <memset>
        list_init(&(proc->list_link));
ffffffffc0203ef0:	0c840713          	addi	a4,s0,200
        list_init(&(proc->hash_link));
ffffffffc0203ef4:	0d840793          	addi	a5,s0,216
    elm->prev = elm->next = elm;
ffffffffc0203ef8:	e878                	sd	a4,208(s0)
ffffffffc0203efa:	e478                	sd	a4,200(s0)
ffffffffc0203efc:	f07c                	sd	a5,224(s0)
ffffffffc0203efe:	ec7c                	sd	a5,216(s0)
     
        // LAB5新增     
        proc->wait_state = 0;      // 设置进程的等待状态为0，表示进程当前不在等待状态
ffffffffc0203f00:	0e042623          	sw	zero,236(s0)
        proc->cptr = NULL;         // 初始化子进程指针为NULL
ffffffffc0203f04:	0e043823          	sd	zero,240(s0)
        proc->optr = NULL;         // 初始化较年长兄弟进程(older sibling pointer)指针为NULL
ffffffffc0203f08:	10043023          	sd	zero,256(s0)
        proc->yptr = NULL;         // 初始化较年轻兄弟进程(younger sibling pointer)指针为NULL
ffffffffc0203f0c:	0e043c23          	sd	zero,248(s0)
    }
    return proc;
}
ffffffffc0203f10:	60a2                	ld	ra,8(sp)
ffffffffc0203f12:	8522                	mv	a0,s0
ffffffffc0203f14:	6402                	ld	s0,0(sp)
ffffffffc0203f16:	0141                	addi	sp,sp,16
ffffffffc0203f18:	8082                	ret

ffffffffc0203f1a <forkret>:
// NOTE: the addr of forkret is setted in copy_thread function
//       after switch_to, the current proc will execute here.
static void
forkret(void)
{
    forkrets(current->tf);
ffffffffc0203f1a:	000a7797          	auipc	a5,0xa7
ffffffffc0203f1e:	9de7b783          	ld	a5,-1570(a5) # ffffffffc02aa8f8 <current>
ffffffffc0203f22:	73c8                	ld	a0,160(a5)
ffffffffc0203f24:	8b2fd06f          	j	ffffffffc0200fd6 <forkrets>

ffffffffc0203f28 <user_main>:
// user_main - kernel thread used to exec a user program
static int
user_main(void *arg)
{
#ifdef TEST
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc0203f28:	000a7797          	auipc	a5,0xa7
ffffffffc0203f2c:	9d07b783          	ld	a5,-1584(a5) # ffffffffc02aa8f8 <current>
ffffffffc0203f30:	43cc                	lw	a1,4(a5)
{
ffffffffc0203f32:	7139                	addi	sp,sp,-64
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc0203f34:	00003617          	auipc	a2,0x3
ffffffffc0203f38:	10460613          	addi	a2,a2,260 # ffffffffc0207038 <default_pmm_manager+0xa08>
ffffffffc0203f3c:	00003517          	auipc	a0,0x3
ffffffffc0203f40:	10c50513          	addi	a0,a0,268 # ffffffffc0207048 <default_pmm_manager+0xa18>
{
ffffffffc0203f44:	fc06                	sd	ra,56(sp)
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc0203f46:	a4efc0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc0203f4a:	3fe07797          	auipc	a5,0x3fe07
ffffffffc0203f4e:	a3678793          	addi	a5,a5,-1482 # a980 <_binary_obj___user_forktest_out_size>
ffffffffc0203f52:	e43e                	sd	a5,8(sp)
ffffffffc0203f54:	00003517          	auipc	a0,0x3
ffffffffc0203f58:	0e450513          	addi	a0,a0,228 # ffffffffc0207038 <default_pmm_manager+0xa08>
ffffffffc0203f5c:	00046797          	auipc	a5,0x46
ffffffffc0203f60:	85478793          	addi	a5,a5,-1964 # ffffffffc02497b0 <_binary_obj___user_forktest_out_start>
ffffffffc0203f64:	f03e                	sd	a5,32(sp)
ffffffffc0203f66:	f42a                	sd	a0,40(sp)
    int64_t ret = 0, len = strlen(name);
ffffffffc0203f68:	e802                	sd	zero,16(sp)
ffffffffc0203f6a:	774010ef          	jal	ra,ffffffffc02056de <strlen>
ffffffffc0203f6e:	ec2a                	sd	a0,24(sp)
    asm volatile(
ffffffffc0203f70:	4511                	li	a0,4
ffffffffc0203f72:	55a2                	lw	a1,40(sp)
ffffffffc0203f74:	4662                	lw	a2,24(sp)
ffffffffc0203f76:	5682                	lw	a3,32(sp)
ffffffffc0203f78:	4722                	lw	a4,8(sp)
ffffffffc0203f7a:	48a9                	li	a7,10
ffffffffc0203f7c:	9002                	ebreak
ffffffffc0203f7e:	c82a                	sw	a0,16(sp)
    cprintf("ret = %d\n", ret);
ffffffffc0203f80:	65c2                	ld	a1,16(sp)
ffffffffc0203f82:	00003517          	auipc	a0,0x3
ffffffffc0203f86:	0ee50513          	addi	a0,a0,238 # ffffffffc0207070 <default_pmm_manager+0xa40>
ffffffffc0203f8a:	a0afc0ef          	jal	ra,ffffffffc0200194 <cprintf>
#else
    KERNEL_EXECVE(exit);
#endif
    panic("user_main execve failed.\n");
ffffffffc0203f8e:	00003617          	auipc	a2,0x3
ffffffffc0203f92:	0f260613          	addi	a2,a2,242 # ffffffffc0207080 <default_pmm_manager+0xa50>
ffffffffc0203f96:	3e900593          	li	a1,1001
ffffffffc0203f9a:	00003517          	auipc	a0,0x3
ffffffffc0203f9e:	10650513          	addi	a0,a0,262 # ffffffffc02070a0 <default_pmm_manager+0xa70>
ffffffffc0203fa2:	cecfc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203fa6 <put_pgdir>:
    return pa2page(PADDR(kva));
ffffffffc0203fa6:	6d14                	ld	a3,24(a0)
{
ffffffffc0203fa8:	1141                	addi	sp,sp,-16
ffffffffc0203faa:	e406                	sd	ra,8(sp)
ffffffffc0203fac:	c02007b7          	lui	a5,0xc0200
ffffffffc0203fb0:	02f6ee63          	bltu	a3,a5,ffffffffc0203fec <put_pgdir+0x46>
ffffffffc0203fb4:	000a7517          	auipc	a0,0xa7
ffffffffc0203fb8:	93c53503          	ld	a0,-1732(a0) # ffffffffc02aa8f0 <va_pa_offset>
ffffffffc0203fbc:	8e89                	sub	a3,a3,a0
    if (PPN(pa) >= npage)
ffffffffc0203fbe:	82b1                	srli	a3,a3,0xc
ffffffffc0203fc0:	000a7797          	auipc	a5,0xa7
ffffffffc0203fc4:	9187b783          	ld	a5,-1768(a5) # ffffffffc02aa8d8 <npage>
ffffffffc0203fc8:	02f6fe63          	bgeu	a3,a5,ffffffffc0204004 <put_pgdir+0x5e>
    return &pages[PPN(pa) - nbase];
ffffffffc0203fcc:	00004517          	auipc	a0,0x4
ffffffffc0203fd0:	96c53503          	ld	a0,-1684(a0) # ffffffffc0207938 <nbase>
}
ffffffffc0203fd4:	60a2                	ld	ra,8(sp)
ffffffffc0203fd6:	8e89                	sub	a3,a3,a0
ffffffffc0203fd8:	069a                	slli	a3,a3,0x6
    free_page(kva2page(mm->pgdir));
ffffffffc0203fda:	000a7517          	auipc	a0,0xa7
ffffffffc0203fde:	90653503          	ld	a0,-1786(a0) # ffffffffc02aa8e0 <pages>
ffffffffc0203fe2:	4585                	li	a1,1
ffffffffc0203fe4:	9536                	add	a0,a0,a3
}
ffffffffc0203fe6:	0141                	addi	sp,sp,16
    free_page(kva2page(mm->pgdir));
ffffffffc0203fe8:	f97fd06f          	j	ffffffffc0201f7e <free_pages>
    return pa2page(PADDR(kva));
ffffffffc0203fec:	00002617          	auipc	a2,0x2
ffffffffc0203ff0:	72460613          	addi	a2,a2,1828 # ffffffffc0206710 <default_pmm_manager+0xe0>
ffffffffc0203ff4:	07700593          	li	a1,119
ffffffffc0203ff8:	00002517          	auipc	a0,0x2
ffffffffc0203ffc:	69850513          	addi	a0,a0,1688 # ffffffffc0206690 <default_pmm_manager+0x60>
ffffffffc0204000:	c8efc0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0204004:	00002617          	auipc	a2,0x2
ffffffffc0204008:	73460613          	addi	a2,a2,1844 # ffffffffc0206738 <default_pmm_manager+0x108>
ffffffffc020400c:	06900593          	li	a1,105
ffffffffc0204010:	00002517          	auipc	a0,0x2
ffffffffc0204014:	68050513          	addi	a0,a0,1664 # ffffffffc0206690 <default_pmm_manager+0x60>
ffffffffc0204018:	c76fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc020401c <proc_run>:
{
ffffffffc020401c:	7179                	addi	sp,sp,-48
ffffffffc020401e:	f026                	sd	s1,32(sp)
    if (proc != current)
ffffffffc0204020:	000a7497          	auipc	s1,0xa7
ffffffffc0204024:	8d848493          	addi	s1,s1,-1832 # ffffffffc02aa8f8 <current>
ffffffffc0204028:	6098                	ld	a4,0(s1)
{
ffffffffc020402a:	f406                	sd	ra,40(sp)
ffffffffc020402c:	ec4a                	sd	s2,24(sp)
    if (proc != current)
ffffffffc020402e:	02a70a63          	beq	a4,a0,ffffffffc0204062 <proc_run+0x46>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204032:	100027f3          	csrr	a5,sstatus
ffffffffc0204036:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0204038:	4901                	li	s2,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020403a:	ef9d                	bnez	a5,ffffffffc0204078 <proc_run+0x5c>
        current->runs++;
ffffffffc020403c:	4514                	lw	a3,8(a0)
#define barrier() __asm__ __volatile__("fence" ::: "memory")

static inline void
lsatp(unsigned long pgdir)
{
  write_csr(satp, 0x8000000000000000 | (pgdir >> RISCV_PGSHIFT));
ffffffffc020403e:	755c                	ld	a5,168(a0)
        current = proc;
ffffffffc0204040:	e088                	sd	a0,0(s1)
        current->runs++;
ffffffffc0204042:	2685                	addiw	a3,a3,1
ffffffffc0204044:	c514                	sw	a3,8(a0)
ffffffffc0204046:	56fd                	li	a3,-1
ffffffffc0204048:	16fe                	slli	a3,a3,0x3f
ffffffffc020404a:	83b1                	srli	a5,a5,0xc
ffffffffc020404c:	8fd5                	or	a5,a5,a3
ffffffffc020404e:	18079073          	csrw	satp,a5
        switch_to(&prev->context, &current->context);
ffffffffc0204052:	03050593          	addi	a1,a0,48
ffffffffc0204056:	03070513          	addi	a0,a4,48
ffffffffc020405a:	02a010ef          	jal	ra,ffffffffc0205084 <switch_to>
    if (flag)
ffffffffc020405e:	00091763          	bnez	s2,ffffffffc020406c <proc_run+0x50>
}
ffffffffc0204062:	70a2                	ld	ra,40(sp)
ffffffffc0204064:	7482                	ld	s1,32(sp)
ffffffffc0204066:	6962                	ld	s2,24(sp)
ffffffffc0204068:	6145                	addi	sp,sp,48
ffffffffc020406a:	8082                	ret
ffffffffc020406c:	70a2                	ld	ra,40(sp)
ffffffffc020406e:	7482                	ld	s1,32(sp)
ffffffffc0204070:	6962                	ld	s2,24(sp)
ffffffffc0204072:	6145                	addi	sp,sp,48
        intr_enable();
ffffffffc0204074:	93bfc06f          	j	ffffffffc02009ae <intr_enable>
ffffffffc0204078:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc020407a:	93bfc0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        struct proc_struct *prev = current;
ffffffffc020407e:	6098                	ld	a4,0(s1)
        return 1;
ffffffffc0204080:	6522                	ld	a0,8(sp)
ffffffffc0204082:	4905                	li	s2,1
ffffffffc0204084:	bf65                	j	ffffffffc020403c <proc_run+0x20>

ffffffffc0204086 <do_fork>:
{
ffffffffc0204086:	7119                	addi	sp,sp,-128
ffffffffc0204088:	f0ca                	sd	s2,96(sp)
    if (nr_process >= MAX_PROCESS)
ffffffffc020408a:	000a7917          	auipc	s2,0xa7
ffffffffc020408e:	88690913          	addi	s2,s2,-1914 # ffffffffc02aa910 <nr_process>
ffffffffc0204092:	00092703          	lw	a4,0(s2)
{
ffffffffc0204096:	fc86                	sd	ra,120(sp)
ffffffffc0204098:	f8a2                	sd	s0,112(sp)
ffffffffc020409a:	f4a6                	sd	s1,104(sp)
ffffffffc020409c:	ecce                	sd	s3,88(sp)
ffffffffc020409e:	e8d2                	sd	s4,80(sp)
ffffffffc02040a0:	e4d6                	sd	s5,72(sp)
ffffffffc02040a2:	e0da                	sd	s6,64(sp)
ffffffffc02040a4:	fc5e                	sd	s7,56(sp)
ffffffffc02040a6:	f862                	sd	s8,48(sp)
ffffffffc02040a8:	f466                	sd	s9,40(sp)
ffffffffc02040aa:	f06a                	sd	s10,32(sp)
ffffffffc02040ac:	ec6e                	sd	s11,24(sp)
    if (nr_process >= MAX_PROCESS)
ffffffffc02040ae:	6785                	lui	a5,0x1
ffffffffc02040b0:	32f75663          	bge	a4,a5,ffffffffc02043dc <do_fork+0x356>
ffffffffc02040b4:	8a2a                	mv	s4,a0
ffffffffc02040b6:	89ae                	mv	s3,a1
ffffffffc02040b8:	8432                	mv	s0,a2
    if ((proc = alloc_proc()) == NULL) {
ffffffffc02040ba:	ddfff0ef          	jal	ra,ffffffffc0203e98 <alloc_proc>
ffffffffc02040be:	84aa                	mv	s1,a0
ffffffffc02040c0:	2e050f63          	beqz	a0,ffffffffc02043be <do_fork+0x338>
    proc->parent = current;
ffffffffc02040c4:	000a7c17          	auipc	s8,0xa7
ffffffffc02040c8:	834c0c13          	addi	s8,s8,-1996 # ffffffffc02aa8f8 <current>
ffffffffc02040cc:	000c3783          	ld	a5,0(s8)
    struct Page *page = alloc_pages(KSTACKPAGE);
ffffffffc02040d0:	4509                	li	a0,2
    proc->parent = current;
ffffffffc02040d2:	f09c                	sd	a5,32(s1)
    struct Page *page = alloc_pages(KSTACKPAGE);
ffffffffc02040d4:	e6dfd0ef          	jal	ra,ffffffffc0201f40 <alloc_pages>
    if (page != NULL)
ffffffffc02040d8:	2e050063          	beqz	a0,ffffffffc02043b8 <do_fork+0x332>
    return page - pages + nbase;
ffffffffc02040dc:	000a7a97          	auipc	s5,0xa7
ffffffffc02040e0:	804a8a93          	addi	s5,s5,-2044 # ffffffffc02aa8e0 <pages>
ffffffffc02040e4:	000ab683          	ld	a3,0(s5)
ffffffffc02040e8:	00004b17          	auipc	s6,0x4
ffffffffc02040ec:	850b0b13          	addi	s6,s6,-1968 # ffffffffc0207938 <nbase>
ffffffffc02040f0:	000b3783          	ld	a5,0(s6)
ffffffffc02040f4:	40d506b3          	sub	a3,a0,a3
    return KADDR(page2pa(page));
ffffffffc02040f8:	000a6b97          	auipc	s7,0xa6
ffffffffc02040fc:	7e0b8b93          	addi	s7,s7,2016 # ffffffffc02aa8d8 <npage>
    return page - pages + nbase;
ffffffffc0204100:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0204102:	5dfd                	li	s11,-1
ffffffffc0204104:	000bb703          	ld	a4,0(s7)
    return page - pages + nbase;
ffffffffc0204108:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc020410a:	00cddd93          	srli	s11,s11,0xc
ffffffffc020410e:	01b6f633          	and	a2,a3,s11
    return page2ppn(page) << PGSHIFT;
ffffffffc0204112:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204114:	32e67a63          	bgeu	a2,a4,ffffffffc0204448 <do_fork+0x3c2>
    struct mm_struct *mm, *oldmm = current->mm;
ffffffffc0204118:	000c3603          	ld	a2,0(s8)
ffffffffc020411c:	000a6c17          	auipc	s8,0xa6
ffffffffc0204120:	7d4c0c13          	addi	s8,s8,2004 # ffffffffc02aa8f0 <va_pa_offset>
ffffffffc0204124:	000c3703          	ld	a4,0(s8)
ffffffffc0204128:	02863d03          	ld	s10,40(a2)
ffffffffc020412c:	e43e                	sd	a5,8(sp)
ffffffffc020412e:	96ba                	add	a3,a3,a4
        proc->kstack = (uintptr_t)page2kva(page);
ffffffffc0204130:	e894                	sd	a3,16(s1)
    if (oldmm == NULL)
ffffffffc0204132:	020d0863          	beqz	s10,ffffffffc0204162 <do_fork+0xdc>
    if (clone_flags & CLONE_VM)
ffffffffc0204136:	100a7a13          	andi	s4,s4,256
ffffffffc020413a:	1c0a0163          	beqz	s4,ffffffffc02042fc <do_fork+0x276>
}

static inline int
mm_count_inc(struct mm_struct *mm)
{
    mm->mm_count += 1;
ffffffffc020413e:	030d2703          	lw	a4,48(s10)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc0204142:	018d3783          	ld	a5,24(s10)
ffffffffc0204146:	c02006b7          	lui	a3,0xc0200
ffffffffc020414a:	2705                	addiw	a4,a4,1
ffffffffc020414c:	02ed2823          	sw	a4,48(s10)
    proc->mm = mm;
ffffffffc0204150:	03a4b423          	sd	s10,40(s1)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc0204154:	2cd7e163          	bltu	a5,a3,ffffffffc0204416 <do_fork+0x390>
ffffffffc0204158:	000c3703          	ld	a4,0(s8)
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc020415c:	6894                	ld	a3,16(s1)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc020415e:	8f99                	sub	a5,a5,a4
ffffffffc0204160:	f4dc                	sd	a5,168(s1)
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc0204162:	6789                	lui	a5,0x2
ffffffffc0204164:	ee078793          	addi	a5,a5,-288 # 1ee0 <_binary_obj___user_faultread_out_size-0x7ce8>
ffffffffc0204168:	96be                	add	a3,a3,a5
    *(proc->tf) = *tf;
ffffffffc020416a:	8622                	mv	a2,s0
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc020416c:	f0d4                	sd	a3,160(s1)
    *(proc->tf) = *tf;
ffffffffc020416e:	87b6                	mv	a5,a3
ffffffffc0204170:	12040893          	addi	a7,s0,288
ffffffffc0204174:	00063803          	ld	a6,0(a2)
ffffffffc0204178:	6608                	ld	a0,8(a2)
ffffffffc020417a:	6a0c                	ld	a1,16(a2)
ffffffffc020417c:	6e18                	ld	a4,24(a2)
ffffffffc020417e:	0107b023          	sd	a6,0(a5)
ffffffffc0204182:	e788                	sd	a0,8(a5)
ffffffffc0204184:	eb8c                	sd	a1,16(a5)
ffffffffc0204186:	ef98                	sd	a4,24(a5)
ffffffffc0204188:	02060613          	addi	a2,a2,32
ffffffffc020418c:	02078793          	addi	a5,a5,32
ffffffffc0204190:	ff1612e3          	bne	a2,a7,ffffffffc0204174 <do_fork+0xee>
    proc->tf->gpr.a0 = 0;
ffffffffc0204194:	0406b823          	sd	zero,80(a3) # ffffffffc0200050 <kern_init+0x6>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc0204198:	12098f63          	beqz	s3,ffffffffc02042d6 <do_fork+0x250>
ffffffffc020419c:	0136b823          	sd	s3,16(a3)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc02041a0:	00000797          	auipc	a5,0x0
ffffffffc02041a4:	d7a78793          	addi	a5,a5,-646 # ffffffffc0203f1a <forkret>
ffffffffc02041a8:	f89c                	sd	a5,48(s1)
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc02041aa:	fc94                	sd	a3,56(s1)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02041ac:	100027f3          	csrr	a5,sstatus
ffffffffc02041b0:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02041b2:	4981                	li	s3,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02041b4:	14079063          	bnez	a5,ffffffffc02042f4 <do_fork+0x26e>
    if (++last_pid >= MAX_PID)
ffffffffc02041b8:	000a2817          	auipc	a6,0xa2
ffffffffc02041bc:	2b080813          	addi	a6,a6,688 # ffffffffc02a6468 <last_pid.1>
ffffffffc02041c0:	00082783          	lw	a5,0(a6)
ffffffffc02041c4:	6709                	lui	a4,0x2
ffffffffc02041c6:	0017851b          	addiw	a0,a5,1
ffffffffc02041ca:	00a82023          	sw	a0,0(a6)
ffffffffc02041ce:	08e55d63          	bge	a0,a4,ffffffffc0204268 <do_fork+0x1e2>
    if (last_pid >= next_safe)
ffffffffc02041d2:	000a2317          	auipc	t1,0xa2
ffffffffc02041d6:	29a30313          	addi	t1,t1,666 # ffffffffc02a646c <next_safe.0>
ffffffffc02041da:	00032783          	lw	a5,0(t1)
ffffffffc02041de:	000a6417          	auipc	s0,0xa6
ffffffffc02041e2:	6aa40413          	addi	s0,s0,1706 # ffffffffc02aa888 <proc_list>
ffffffffc02041e6:	08f55963          	bge	a0,a5,ffffffffc0204278 <do_fork+0x1f2>
        proc->pid = get_pid();
ffffffffc02041ea:	c0c8                	sw	a0,4(s1)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc02041ec:	45a9                	li	a1,10
ffffffffc02041ee:	2501                	sext.w	a0,a0
ffffffffc02041f0:	0ea010ef          	jal	ra,ffffffffc02052da <hash32>
ffffffffc02041f4:	02051793          	slli	a5,a0,0x20
ffffffffc02041f8:	01c7d513          	srli	a0,a5,0x1c
ffffffffc02041fc:	000a2797          	auipc	a5,0xa2
ffffffffc0204200:	68c78793          	addi	a5,a5,1676 # ffffffffc02a6888 <hash_list>
ffffffffc0204204:	953e                	add	a0,a0,a5
    __list_add(elm, listelm, listelm->next);
ffffffffc0204206:	650c                	ld	a1,8(a0)
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc0204208:	7094                	ld	a3,32(s1)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc020420a:	0d848793          	addi	a5,s1,216
    prev->next = next->prev = elm;
ffffffffc020420e:	e19c                	sd	a5,0(a1)
    __list_add(elm, listelm, listelm->next);
ffffffffc0204210:	6410                	ld	a2,8(s0)
    prev->next = next->prev = elm;
ffffffffc0204212:	e51c                	sd	a5,8(a0)
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc0204214:	7af8                	ld	a4,240(a3)
    list_add(&proc_list, &(proc->list_link));
ffffffffc0204216:	0c848793          	addi	a5,s1,200
    elm->next = next;
ffffffffc020421a:	f0ec                	sd	a1,224(s1)
    elm->prev = prev;
ffffffffc020421c:	ece8                	sd	a0,216(s1)
    prev->next = next->prev = elm;
ffffffffc020421e:	e21c                	sd	a5,0(a2)
ffffffffc0204220:	e41c                	sd	a5,8(s0)
    elm->next = next;
ffffffffc0204222:	e8f0                	sd	a2,208(s1)
    elm->prev = prev;
ffffffffc0204224:	e4e0                	sd	s0,200(s1)
    proc->yptr = NULL;
ffffffffc0204226:	0e04bc23          	sd	zero,248(s1)
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc020422a:	10e4b023          	sd	a4,256(s1)
ffffffffc020422e:	c311                	beqz	a4,ffffffffc0204232 <do_fork+0x1ac>
        proc->optr->yptr = proc;
ffffffffc0204230:	ff64                	sd	s1,248(a4)
    nr_process++;
ffffffffc0204232:	00092783          	lw	a5,0(s2)
    proc->parent->cptr = proc;
ffffffffc0204236:	fae4                	sd	s1,240(a3)
    nr_process++;
ffffffffc0204238:	2785                	addiw	a5,a5,1
ffffffffc020423a:	00f92023          	sw	a5,0(s2)
    if (flag)
ffffffffc020423e:	18099263          	bnez	s3,ffffffffc02043c2 <do_fork+0x33c>
    wakeup_proc(proc);
ffffffffc0204242:	8526                	mv	a0,s1
ffffffffc0204244:	6ab000ef          	jal	ra,ffffffffc02050ee <wakeup_proc>
    ret = proc->pid;
ffffffffc0204248:	40c8                	lw	a0,4(s1)
}
ffffffffc020424a:	70e6                	ld	ra,120(sp)
ffffffffc020424c:	7446                	ld	s0,112(sp)
ffffffffc020424e:	74a6                	ld	s1,104(sp)
ffffffffc0204250:	7906                	ld	s2,96(sp)
ffffffffc0204252:	69e6                	ld	s3,88(sp)
ffffffffc0204254:	6a46                	ld	s4,80(sp)
ffffffffc0204256:	6aa6                	ld	s5,72(sp)
ffffffffc0204258:	6b06                	ld	s6,64(sp)
ffffffffc020425a:	7be2                	ld	s7,56(sp)
ffffffffc020425c:	7c42                	ld	s8,48(sp)
ffffffffc020425e:	7ca2                	ld	s9,40(sp)
ffffffffc0204260:	7d02                	ld	s10,32(sp)
ffffffffc0204262:	6de2                	ld	s11,24(sp)
ffffffffc0204264:	6109                	addi	sp,sp,128
ffffffffc0204266:	8082                	ret
        last_pid = 1;
ffffffffc0204268:	4785                	li	a5,1
ffffffffc020426a:	00f82023          	sw	a5,0(a6)
        goto inside;
ffffffffc020426e:	4505                	li	a0,1
ffffffffc0204270:	000a2317          	auipc	t1,0xa2
ffffffffc0204274:	1fc30313          	addi	t1,t1,508 # ffffffffc02a646c <next_safe.0>
    return listelm->next;
ffffffffc0204278:	000a6417          	auipc	s0,0xa6
ffffffffc020427c:	61040413          	addi	s0,s0,1552 # ffffffffc02aa888 <proc_list>
ffffffffc0204280:	00843e03          	ld	t3,8(s0)
        next_safe = MAX_PID;
ffffffffc0204284:	6789                	lui	a5,0x2
ffffffffc0204286:	00f32023          	sw	a5,0(t1)
ffffffffc020428a:	86aa                	mv	a3,a0
ffffffffc020428c:	4581                	li	a1,0
        while ((le = list_next(le)) != list)
ffffffffc020428e:	6e89                	lui	t4,0x2
ffffffffc0204290:	148e0163          	beq	t3,s0,ffffffffc02043d2 <do_fork+0x34c>
ffffffffc0204294:	88ae                	mv	a7,a1
ffffffffc0204296:	87f2                	mv	a5,t3
ffffffffc0204298:	6609                	lui	a2,0x2
ffffffffc020429a:	a811                	j	ffffffffc02042ae <do_fork+0x228>
            else if (proc->pid > last_pid && next_safe > proc->pid)
ffffffffc020429c:	00e6d663          	bge	a3,a4,ffffffffc02042a8 <do_fork+0x222>
ffffffffc02042a0:	00c75463          	bge	a4,a2,ffffffffc02042a8 <do_fork+0x222>
ffffffffc02042a4:	863a                	mv	a2,a4
ffffffffc02042a6:	4885                	li	a7,1
ffffffffc02042a8:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc02042aa:	00878d63          	beq	a5,s0,ffffffffc02042c4 <do_fork+0x23e>
            if (proc->pid == last_pid)
ffffffffc02042ae:	f3c7a703          	lw	a4,-196(a5) # 1f3c <_binary_obj___user_faultread_out_size-0x7c8c>
ffffffffc02042b2:	fed715e3          	bne	a4,a3,ffffffffc020429c <do_fork+0x216>
                if (++last_pid >= next_safe)
ffffffffc02042b6:	2685                	addiw	a3,a3,1
ffffffffc02042b8:	10c6d863          	bge	a3,a2,ffffffffc02043c8 <do_fork+0x342>
ffffffffc02042bc:	679c                	ld	a5,8(a5)
ffffffffc02042be:	4585                	li	a1,1
        while ((le = list_next(le)) != list)
ffffffffc02042c0:	fe8797e3          	bne	a5,s0,ffffffffc02042ae <do_fork+0x228>
ffffffffc02042c4:	c581                	beqz	a1,ffffffffc02042cc <do_fork+0x246>
ffffffffc02042c6:	00d82023          	sw	a3,0(a6)
ffffffffc02042ca:	8536                	mv	a0,a3
ffffffffc02042cc:	f0088fe3          	beqz	a7,ffffffffc02041ea <do_fork+0x164>
ffffffffc02042d0:	00c32023          	sw	a2,0(t1)
ffffffffc02042d4:	bf19                	j	ffffffffc02041ea <do_fork+0x164>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc02042d6:	89b6                	mv	s3,a3
ffffffffc02042d8:	0136b823          	sd	s3,16(a3)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc02042dc:	00000797          	auipc	a5,0x0
ffffffffc02042e0:	c3e78793          	addi	a5,a5,-962 # ffffffffc0203f1a <forkret>
ffffffffc02042e4:	f89c                	sd	a5,48(s1)
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc02042e6:	fc94                	sd	a3,56(s1)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02042e8:	100027f3          	csrr	a5,sstatus
ffffffffc02042ec:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02042ee:	4981                	li	s3,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02042f0:	ec0784e3          	beqz	a5,ffffffffc02041b8 <do_fork+0x132>
        intr_disable();
ffffffffc02042f4:	ec0fc0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc02042f8:	4985                	li	s3,1
ffffffffc02042fa:	bd7d                	j	ffffffffc02041b8 <do_fork+0x132>
    if ((mm = mm_create()) == NULL)
ffffffffc02042fc:	c8aff0ef          	jal	ra,ffffffffc0203786 <mm_create>
ffffffffc0204300:	8caa                	mv	s9,a0
ffffffffc0204302:	c159                	beqz	a0,ffffffffc0204388 <do_fork+0x302>
    if ((page = alloc_page()) == NULL)
ffffffffc0204304:	4505                	li	a0,1
ffffffffc0204306:	c3bfd0ef          	jal	ra,ffffffffc0201f40 <alloc_pages>
ffffffffc020430a:	cd25                	beqz	a0,ffffffffc0204382 <do_fork+0x2fc>
    return page - pages + nbase;
ffffffffc020430c:	000ab683          	ld	a3,0(s5)
ffffffffc0204310:	67a2                	ld	a5,8(sp)
    return KADDR(page2pa(page));
ffffffffc0204312:	000bb703          	ld	a4,0(s7)
    return page - pages + nbase;
ffffffffc0204316:	40d506b3          	sub	a3,a0,a3
ffffffffc020431a:	8699                	srai	a3,a3,0x6
ffffffffc020431c:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc020431e:	01b6fdb3          	and	s11,a3,s11
    return page2ppn(page) << PGSHIFT;
ffffffffc0204322:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204324:	12edf263          	bgeu	s11,a4,ffffffffc0204448 <do_fork+0x3c2>
ffffffffc0204328:	000c3a03          	ld	s4,0(s8)
    memcpy(pgdir, boot_pgdir_va, PGSIZE);
ffffffffc020432c:	6605                	lui	a2,0x1
ffffffffc020432e:	000a6597          	auipc	a1,0xa6
ffffffffc0204332:	5a25b583          	ld	a1,1442(a1) # ffffffffc02aa8d0 <boot_pgdir_va>
ffffffffc0204336:	9a36                	add	s4,s4,a3
ffffffffc0204338:	8552                	mv	a0,s4
ffffffffc020433a:	458010ef          	jal	ra,ffffffffc0205792 <memcpy>
static inline void
lock_mm(struct mm_struct *mm)
{
    if (mm != NULL)
    {
        lock(&(mm->mm_lock));
ffffffffc020433e:	038d0d93          	addi	s11,s10,56
    mm->pgdir = pgdir;
ffffffffc0204342:	014cbc23          	sd	s4,24(s9)
 * test_and_set_bit - Atomically set a bit and return its old value
 * @nr:     the bit to set
 * @addr:   the address to count from
 * */
static inline bool test_and_set_bit(int nr, volatile void *addr) {
    return __test_and_op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0204346:	4785                	li	a5,1
ffffffffc0204348:	40fdb7af          	amoor.d	a5,a5,(s11)
}

static inline void
lock(lock_t *lock)
{
    while (!try_lock(lock))
ffffffffc020434c:	8b85                	andi	a5,a5,1
ffffffffc020434e:	4a05                	li	s4,1
ffffffffc0204350:	c799                	beqz	a5,ffffffffc020435e <do_fork+0x2d8>
    {
        schedule();
ffffffffc0204352:	61d000ef          	jal	ra,ffffffffc020516e <schedule>
ffffffffc0204356:	414db7af          	amoor.d	a5,s4,(s11)
    while (!try_lock(lock))
ffffffffc020435a:	8b85                	andi	a5,a5,1
ffffffffc020435c:	fbfd                	bnez	a5,ffffffffc0204352 <do_fork+0x2cc>
        ret = dup_mmap(mm, oldmm);
ffffffffc020435e:	85ea                	mv	a1,s10
ffffffffc0204360:	8566                	mv	a0,s9
ffffffffc0204362:	e66ff0ef          	jal	ra,ffffffffc02039c8 <dup_mmap>
 * test_and_clear_bit - Atomically clear a bit and return its old value
 * @nr:     the bit to clear
 * @addr:   the address to count from
 * */
static inline bool test_and_clear_bit(int nr, volatile void *addr) {
    return __test_and_op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0204366:	57f9                	li	a5,-2
ffffffffc0204368:	60fdb7af          	amoand.d	a5,a5,(s11)
ffffffffc020436c:	8b85                	andi	a5,a5,1
}

static inline void
unlock(lock_t *lock)
{
    if (!test_and_clear_bit(0, lock))
ffffffffc020436e:	cfa5                	beqz	a5,ffffffffc02043e6 <do_fork+0x360>
good_mm:
ffffffffc0204370:	8d66                	mv	s10,s9
    if (ret != 0)
ffffffffc0204372:	dc0506e3          	beqz	a0,ffffffffc020413e <do_fork+0xb8>
    exit_mmap(mm);
ffffffffc0204376:	8566                	mv	a0,s9
ffffffffc0204378:	eeaff0ef          	jal	ra,ffffffffc0203a62 <exit_mmap>
    put_pgdir(mm);
ffffffffc020437c:	8566                	mv	a0,s9
ffffffffc020437e:	c29ff0ef          	jal	ra,ffffffffc0203fa6 <put_pgdir>
    mm_destroy(mm);
ffffffffc0204382:	8566                	mv	a0,s9
ffffffffc0204384:	d42ff0ef          	jal	ra,ffffffffc02038c6 <mm_destroy>
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
ffffffffc0204388:	6894                	ld	a3,16(s1)
    return pa2page(PADDR(kva));
ffffffffc020438a:	c02007b7          	lui	a5,0xc0200
ffffffffc020438e:	0af6e163          	bltu	a3,a5,ffffffffc0204430 <do_fork+0x3aa>
ffffffffc0204392:	000c3783          	ld	a5,0(s8)
    if (PPN(pa) >= npage)
ffffffffc0204396:	000bb703          	ld	a4,0(s7)
    return pa2page(PADDR(kva));
ffffffffc020439a:	40f687b3          	sub	a5,a3,a5
    if (PPN(pa) >= npage)
ffffffffc020439e:	83b1                	srli	a5,a5,0xc
ffffffffc02043a0:	04e7ff63          	bgeu	a5,a4,ffffffffc02043fe <do_fork+0x378>
    return &pages[PPN(pa) - nbase];
ffffffffc02043a4:	000b3703          	ld	a4,0(s6)
ffffffffc02043a8:	000ab503          	ld	a0,0(s5)
ffffffffc02043ac:	4589                	li	a1,2
ffffffffc02043ae:	8f99                	sub	a5,a5,a4
ffffffffc02043b0:	079a                	slli	a5,a5,0x6
ffffffffc02043b2:	953e                	add	a0,a0,a5
ffffffffc02043b4:	bcbfd0ef          	jal	ra,ffffffffc0201f7e <free_pages>
    kfree(proc);
ffffffffc02043b8:	8526                	mv	a0,s1
ffffffffc02043ba:	a59fd0ef          	jal	ra,ffffffffc0201e12 <kfree>
    ret = -E_NO_MEM;
ffffffffc02043be:	5571                	li	a0,-4
    return ret;
ffffffffc02043c0:	b569                	j	ffffffffc020424a <do_fork+0x1c4>
        intr_enable();
ffffffffc02043c2:	decfc0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02043c6:	bdb5                	j	ffffffffc0204242 <do_fork+0x1bc>
                    if (last_pid >= MAX_PID)
ffffffffc02043c8:	01d6c363          	blt	a3,t4,ffffffffc02043ce <do_fork+0x348>
                        last_pid = 1;
ffffffffc02043cc:	4685                	li	a3,1
                    goto repeat;
ffffffffc02043ce:	4585                	li	a1,1
ffffffffc02043d0:	b5c1                	j	ffffffffc0204290 <do_fork+0x20a>
ffffffffc02043d2:	c599                	beqz	a1,ffffffffc02043e0 <do_fork+0x35a>
ffffffffc02043d4:	00d82023          	sw	a3,0(a6)
    return last_pid;
ffffffffc02043d8:	8536                	mv	a0,a3
ffffffffc02043da:	bd01                	j	ffffffffc02041ea <do_fork+0x164>
    int ret = -E_NO_FREE_PROC;
ffffffffc02043dc:	556d                	li	a0,-5
ffffffffc02043de:	b5b5                	j	ffffffffc020424a <do_fork+0x1c4>
    return last_pid;
ffffffffc02043e0:	00082503          	lw	a0,0(a6)
ffffffffc02043e4:	b519                	j	ffffffffc02041ea <do_fork+0x164>
    {
        panic("Unlock failed.\n");
ffffffffc02043e6:	00003617          	auipc	a2,0x3
ffffffffc02043ea:	cd260613          	addi	a2,a2,-814 # ffffffffc02070b8 <default_pmm_manager+0xa88>
ffffffffc02043ee:	03f00593          	li	a1,63
ffffffffc02043f2:	00003517          	auipc	a0,0x3
ffffffffc02043f6:	cd650513          	addi	a0,a0,-810 # ffffffffc02070c8 <default_pmm_manager+0xa98>
ffffffffc02043fa:	894fc0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("pa2page called with invalid pa");
ffffffffc02043fe:	00002617          	auipc	a2,0x2
ffffffffc0204402:	33a60613          	addi	a2,a2,826 # ffffffffc0206738 <default_pmm_manager+0x108>
ffffffffc0204406:	06900593          	li	a1,105
ffffffffc020440a:	00002517          	auipc	a0,0x2
ffffffffc020440e:	28650513          	addi	a0,a0,646 # ffffffffc0206690 <default_pmm_manager+0x60>
ffffffffc0204412:	87cfc0ef          	jal	ra,ffffffffc020048e <__panic>
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc0204416:	86be                	mv	a3,a5
ffffffffc0204418:	00002617          	auipc	a2,0x2
ffffffffc020441c:	2f860613          	addi	a2,a2,760 # ffffffffc0206710 <default_pmm_manager+0xe0>
ffffffffc0204420:	19e00593          	li	a1,414
ffffffffc0204424:	00003517          	auipc	a0,0x3
ffffffffc0204428:	c7c50513          	addi	a0,a0,-900 # ffffffffc02070a0 <default_pmm_manager+0xa70>
ffffffffc020442c:	862fc0ef          	jal	ra,ffffffffc020048e <__panic>
    return pa2page(PADDR(kva));
ffffffffc0204430:	00002617          	auipc	a2,0x2
ffffffffc0204434:	2e060613          	addi	a2,a2,736 # ffffffffc0206710 <default_pmm_manager+0xe0>
ffffffffc0204438:	07700593          	li	a1,119
ffffffffc020443c:	00002517          	auipc	a0,0x2
ffffffffc0204440:	25450513          	addi	a0,a0,596 # ffffffffc0206690 <default_pmm_manager+0x60>
ffffffffc0204444:	84afc0ef          	jal	ra,ffffffffc020048e <__panic>
    return KADDR(page2pa(page));
ffffffffc0204448:	00002617          	auipc	a2,0x2
ffffffffc020444c:	22060613          	addi	a2,a2,544 # ffffffffc0206668 <default_pmm_manager+0x38>
ffffffffc0204450:	07100593          	li	a1,113
ffffffffc0204454:	00002517          	auipc	a0,0x2
ffffffffc0204458:	23c50513          	addi	a0,a0,572 # ffffffffc0206690 <default_pmm_manager+0x60>
ffffffffc020445c:	832fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0204460 <kernel_thread>:
{
ffffffffc0204460:	7129                	addi	sp,sp,-320
ffffffffc0204462:	fa22                	sd	s0,304(sp)
ffffffffc0204464:	f626                	sd	s1,296(sp)
ffffffffc0204466:	f24a                	sd	s2,288(sp)
ffffffffc0204468:	84ae                	mv	s1,a1
ffffffffc020446a:	892a                	mv	s2,a0
ffffffffc020446c:	8432                	mv	s0,a2
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc020446e:	4581                	li	a1,0
ffffffffc0204470:	12000613          	li	a2,288
ffffffffc0204474:	850a                	mv	a0,sp
{
ffffffffc0204476:	fe06                	sd	ra,312(sp)
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc0204478:	308010ef          	jal	ra,ffffffffc0205780 <memset>
    tf.gpr.s0 = (uintptr_t)fn;
ffffffffc020447c:	e0ca                	sd	s2,64(sp)
    tf.gpr.s1 = (uintptr_t)arg;
ffffffffc020447e:	e4a6                	sd	s1,72(sp)
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE;
ffffffffc0204480:	100027f3          	csrr	a5,sstatus
ffffffffc0204484:	edd7f793          	andi	a5,a5,-291
ffffffffc0204488:	1207e793          	ori	a5,a5,288
ffffffffc020448c:	e23e                	sd	a5,256(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc020448e:	860a                	mv	a2,sp
ffffffffc0204490:	10046513          	ori	a0,s0,256
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc0204494:	00000797          	auipc	a5,0x0
ffffffffc0204498:	9fc78793          	addi	a5,a5,-1540 # ffffffffc0203e90 <kernel_thread_entry>
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc020449c:	4581                	li	a1,0
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc020449e:	e63e                	sd	a5,264(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc02044a0:	be7ff0ef          	jal	ra,ffffffffc0204086 <do_fork>
}
ffffffffc02044a4:	70f2                	ld	ra,312(sp)
ffffffffc02044a6:	7452                	ld	s0,304(sp)
ffffffffc02044a8:	74b2                	ld	s1,296(sp)
ffffffffc02044aa:	7912                	ld	s2,288(sp)
ffffffffc02044ac:	6131                	addi	sp,sp,320
ffffffffc02044ae:	8082                	ret

ffffffffc02044b0 <do_exit>:
{
ffffffffc02044b0:	7179                	addi	sp,sp,-48
ffffffffc02044b2:	f022                	sd	s0,32(sp)
    if (current == idleproc)  
ffffffffc02044b4:	000a6417          	auipc	s0,0xa6
ffffffffc02044b8:	44440413          	addi	s0,s0,1092 # ffffffffc02aa8f8 <current>
ffffffffc02044bc:	601c                	ld	a5,0(s0)
{
ffffffffc02044be:	f406                	sd	ra,40(sp)
ffffffffc02044c0:	ec26                	sd	s1,24(sp)
ffffffffc02044c2:	e84a                	sd	s2,16(sp)
ffffffffc02044c4:	e44e                	sd	s3,8(sp)
ffffffffc02044c6:	e052                	sd	s4,0(sp)
    if (current == idleproc)  
ffffffffc02044c8:	000a6717          	auipc	a4,0xa6
ffffffffc02044cc:	43873703          	ld	a4,1080(a4) # ffffffffc02aa900 <idleproc>
ffffffffc02044d0:	0ce78c63          	beq	a5,a4,ffffffffc02045a8 <do_exit+0xf8>
    if (current == initproc)
ffffffffc02044d4:	000a6497          	auipc	s1,0xa6
ffffffffc02044d8:	43448493          	addi	s1,s1,1076 # ffffffffc02aa908 <initproc>
ffffffffc02044dc:	6098                	ld	a4,0(s1)
ffffffffc02044de:	0ee78b63          	beq	a5,a4,ffffffffc02045d4 <do_exit+0x124>
    struct mm_struct *mm = current->mm;
ffffffffc02044e2:	0287b983          	ld	s3,40(a5)
ffffffffc02044e6:	892a                	mv	s2,a0
    if (mm != NULL)      // 用户进程才有mm
ffffffffc02044e8:	02098663          	beqz	s3,ffffffffc0204514 <do_exit+0x64>
ffffffffc02044ec:	000a6797          	auipc	a5,0xa6
ffffffffc02044f0:	3dc7b783          	ld	a5,988(a5) # ffffffffc02aa8c8 <boot_pgdir_pa>
ffffffffc02044f4:	577d                	li	a4,-1
ffffffffc02044f6:	177e                	slli	a4,a4,0x3f
ffffffffc02044f8:	83b1                	srli	a5,a5,0xc
ffffffffc02044fa:	8fd9                	or	a5,a5,a4
ffffffffc02044fc:	18079073          	csrw	satp,a5
    mm->mm_count -= 1;
ffffffffc0204500:	0309a783          	lw	a5,48(s3)
ffffffffc0204504:	fff7871b          	addiw	a4,a5,-1
ffffffffc0204508:	02e9a823          	sw	a4,48(s3)
        if (mm_count_dec(mm) == 0)  // 引用计数减1
ffffffffc020450c:	cb55                	beqz	a4,ffffffffc02045c0 <do_exit+0x110>
        current->mm = NULL;   // 标记mm已释放
ffffffffc020450e:	601c                	ld	a5,0(s0)
ffffffffc0204510:	0207b423          	sd	zero,40(a5)
    current->state = PROC_ZOMBIE;     // 设置僵尸状态（进程已死但资源未完全释放）
ffffffffc0204514:	601c                	ld	a5,0(s0)
ffffffffc0204516:	470d                	li	a4,3
ffffffffc0204518:	c398                	sw	a4,0(a5)
    current->exit_code = error_code;  // 保存退出码（供父进程通过wait()获取）
ffffffffc020451a:	0f27a423          	sw	s2,232(a5)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020451e:	100027f3          	csrr	a5,sstatus
ffffffffc0204522:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0204524:	4a01                	li	s4,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204526:	e3f9                	bnez	a5,ffffffffc02045ec <do_exit+0x13c>
        proc = current->parent;
ffffffffc0204528:	6018                	ld	a4,0(s0)
        if (proc->wait_state == WT_CHILD)
ffffffffc020452a:	800007b7          	lui	a5,0x80000
ffffffffc020452e:	0785                	addi	a5,a5,1
        proc = current->parent;
ffffffffc0204530:	7308                	ld	a0,32(a4)
        if (proc->wait_state == WT_CHILD)
ffffffffc0204532:	0ec52703          	lw	a4,236(a0)
ffffffffc0204536:	0af70f63          	beq	a4,a5,ffffffffc02045f4 <do_exit+0x144>
        while (current->cptr != NULL)
ffffffffc020453a:	6018                	ld	a4,0(s0)
ffffffffc020453c:	7b7c                	ld	a5,240(a4)
ffffffffc020453e:	c3a1                	beqz	a5,ffffffffc020457e <do_exit+0xce>
                if (initproc->wait_state == WT_CHILD)
ffffffffc0204540:	800009b7          	lui	s3,0x80000
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204544:	490d                	li	s2,3
                if (initproc->wait_state == WT_CHILD)
ffffffffc0204546:	0985                	addi	s3,s3,1
ffffffffc0204548:	a021                	j	ffffffffc0204550 <do_exit+0xa0>
        while (current->cptr != NULL)
ffffffffc020454a:	6018                	ld	a4,0(s0)
ffffffffc020454c:	7b7c                	ld	a5,240(a4)
ffffffffc020454e:	cb85                	beqz	a5,ffffffffc020457e <do_exit+0xce>
            current->cptr = proc->optr;
ffffffffc0204550:	1007b683          	ld	a3,256(a5) # ffffffff80000100 <_binary_obj___user_exit_out_size+0xffffffff7fff4fc0>
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc0204554:	6088                	ld	a0,0(s1)
            current->cptr = proc->optr;
ffffffffc0204556:	fb74                	sd	a3,240(a4)
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc0204558:	7978                	ld	a4,240(a0)
            proc->yptr = NULL;
ffffffffc020455a:	0e07bc23          	sd	zero,248(a5)
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc020455e:	10e7b023          	sd	a4,256(a5)
ffffffffc0204562:	c311                	beqz	a4,ffffffffc0204566 <do_exit+0xb6>
                initproc->cptr->yptr = proc;
ffffffffc0204564:	ff7c                	sd	a5,248(a4)
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204566:	4398                	lw	a4,0(a5)
            proc->parent = initproc;
ffffffffc0204568:	f388                	sd	a0,32(a5)
            initproc->cptr = proc;
ffffffffc020456a:	f97c                	sd	a5,240(a0)
            if (proc->state == PROC_ZOMBIE)
ffffffffc020456c:	fd271fe3          	bne	a4,s2,ffffffffc020454a <do_exit+0x9a>
                if (initproc->wait_state == WT_CHILD)
ffffffffc0204570:	0ec52783          	lw	a5,236(a0)
ffffffffc0204574:	fd379be3          	bne	a5,s3,ffffffffc020454a <do_exit+0x9a>
                    wakeup_proc(initproc);
ffffffffc0204578:	377000ef          	jal	ra,ffffffffc02050ee <wakeup_proc>
ffffffffc020457c:	b7f9                	j	ffffffffc020454a <do_exit+0x9a>
    if (flag)
ffffffffc020457e:	020a1263          	bnez	s4,ffffffffc02045a2 <do_exit+0xf2>
    schedule();  // 选择新进程运行
ffffffffc0204582:	3ed000ef          	jal	ra,ffffffffc020516e <schedule>
    panic("do_exit will not return!! %d.\n", current->pid);
ffffffffc0204586:	601c                	ld	a5,0(s0)
ffffffffc0204588:	00003617          	auipc	a2,0x3
ffffffffc020458c:	b7860613          	addi	a2,a2,-1160 # ffffffffc0207100 <default_pmm_manager+0xad0>
ffffffffc0204590:	26700593          	li	a1,615
ffffffffc0204594:	43d4                	lw	a3,4(a5)
ffffffffc0204596:	00003517          	auipc	a0,0x3
ffffffffc020459a:	b0a50513          	addi	a0,a0,-1270 # ffffffffc02070a0 <default_pmm_manager+0xa70>
ffffffffc020459e:	ef1fb0ef          	jal	ra,ffffffffc020048e <__panic>
        intr_enable();
ffffffffc02045a2:	c0cfc0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02045a6:	bff1                	j	ffffffffc0204582 <do_exit+0xd2>
        panic("idleproc exit.\n");
ffffffffc02045a8:	00003617          	auipc	a2,0x3
ffffffffc02045ac:	b3860613          	addi	a2,a2,-1224 # ffffffffc02070e0 <default_pmm_manager+0xab0>
ffffffffc02045b0:	22700593          	li	a1,551
ffffffffc02045b4:	00003517          	auipc	a0,0x3
ffffffffc02045b8:	aec50513          	addi	a0,a0,-1300 # ffffffffc02070a0 <default_pmm_manager+0xa70>
ffffffffc02045bc:	ed3fb0ef          	jal	ra,ffffffffc020048e <__panic>
            exit_mmap(mm);    // 释放虚拟内存映射
ffffffffc02045c0:	854e                	mv	a0,s3
ffffffffc02045c2:	ca0ff0ef          	jal	ra,ffffffffc0203a62 <exit_mmap>
            put_pgdir(mm);    // 释放页目录
ffffffffc02045c6:	854e                	mv	a0,s3
ffffffffc02045c8:	9dfff0ef          	jal	ra,ffffffffc0203fa6 <put_pgdir>
            mm_destroy(mm);   // 销毁mm_struct
ffffffffc02045cc:	854e                	mv	a0,s3
ffffffffc02045ce:	af8ff0ef          	jal	ra,ffffffffc02038c6 <mm_destroy>
ffffffffc02045d2:	bf35                	j	ffffffffc020450e <do_exit+0x5e>
        panic("initproc exit.\n");
ffffffffc02045d4:	00003617          	auipc	a2,0x3
ffffffffc02045d8:	b1c60613          	addi	a2,a2,-1252 # ffffffffc02070f0 <default_pmm_manager+0xac0>
ffffffffc02045dc:	22b00593          	li	a1,555
ffffffffc02045e0:	00003517          	auipc	a0,0x3
ffffffffc02045e4:	ac050513          	addi	a0,a0,-1344 # ffffffffc02070a0 <default_pmm_manager+0xa70>
ffffffffc02045e8:	ea7fb0ef          	jal	ra,ffffffffc020048e <__panic>
        intr_disable();
ffffffffc02045ec:	bc8fc0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc02045f0:	4a05                	li	s4,1
ffffffffc02045f2:	bf1d                	j	ffffffffc0204528 <do_exit+0x78>
            wakeup_proc(proc);
ffffffffc02045f4:	2fb000ef          	jal	ra,ffffffffc02050ee <wakeup_proc>
ffffffffc02045f8:	b789                	j	ffffffffc020453a <do_exit+0x8a>

ffffffffc02045fa <do_wait.part.0>:
int do_wait(int pid, int *code_store)
ffffffffc02045fa:	715d                	addi	sp,sp,-80
ffffffffc02045fc:	f84a                	sd	s2,48(sp)
ffffffffc02045fe:	f44e                	sd	s3,40(sp)
        current->wait_state = WT_CHILD;
ffffffffc0204600:	80000937          	lui	s2,0x80000
    if (0 < pid && pid < MAX_PID)
ffffffffc0204604:	6989                	lui	s3,0x2
int do_wait(int pid, int *code_store)
ffffffffc0204606:	fc26                	sd	s1,56(sp)
ffffffffc0204608:	f052                	sd	s4,32(sp)
ffffffffc020460a:	ec56                	sd	s5,24(sp)
ffffffffc020460c:	e85a                	sd	s6,16(sp)
ffffffffc020460e:	e45e                	sd	s7,8(sp)
ffffffffc0204610:	e486                	sd	ra,72(sp)
ffffffffc0204612:	e0a2                	sd	s0,64(sp)
ffffffffc0204614:	84aa                	mv	s1,a0
ffffffffc0204616:	8a2e                	mv	s4,a1
        proc = current->cptr;
ffffffffc0204618:	000a6b97          	auipc	s7,0xa6
ffffffffc020461c:	2e0b8b93          	addi	s7,s7,736 # ffffffffc02aa8f8 <current>
    if (0 < pid && pid < MAX_PID)
ffffffffc0204620:	00050b1b          	sext.w	s6,a0
ffffffffc0204624:	fff50a9b          	addiw	s5,a0,-1
ffffffffc0204628:	19f9                	addi	s3,s3,-2
        current->wait_state = WT_CHILD;
ffffffffc020462a:	0905                	addi	s2,s2,1
    if (pid != 0)
ffffffffc020462c:	ccbd                	beqz	s1,ffffffffc02046aa <do_wait.part.0+0xb0>
    if (0 < pid && pid < MAX_PID)
ffffffffc020462e:	0359e863          	bltu	s3,s5,ffffffffc020465e <do_wait.part.0+0x64>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204632:	45a9                	li	a1,10
ffffffffc0204634:	855a                	mv	a0,s6
ffffffffc0204636:	4a5000ef          	jal	ra,ffffffffc02052da <hash32>
ffffffffc020463a:	02051793          	slli	a5,a0,0x20
ffffffffc020463e:	01c7d513          	srli	a0,a5,0x1c
ffffffffc0204642:	000a2797          	auipc	a5,0xa2
ffffffffc0204646:	24678793          	addi	a5,a5,582 # ffffffffc02a6888 <hash_list>
ffffffffc020464a:	953e                	add	a0,a0,a5
ffffffffc020464c:	842a                	mv	s0,a0
        while ((le = list_next(le)) != list)
ffffffffc020464e:	a029                	j	ffffffffc0204658 <do_wait.part.0+0x5e>
            if (proc->pid == pid)
ffffffffc0204650:	f2c42783          	lw	a5,-212(s0)
ffffffffc0204654:	02978163          	beq	a5,s1,ffffffffc0204676 <do_wait.part.0+0x7c>
ffffffffc0204658:	6400                	ld	s0,8(s0)
        while ((le = list_next(le)) != list)
ffffffffc020465a:	fe851be3          	bne	a0,s0,ffffffffc0204650 <do_wait.part.0+0x56>
    return -E_BAD_PROC;
ffffffffc020465e:	5579                	li	a0,-2
}
ffffffffc0204660:	60a6                	ld	ra,72(sp)
ffffffffc0204662:	6406                	ld	s0,64(sp)
ffffffffc0204664:	74e2                	ld	s1,56(sp)
ffffffffc0204666:	7942                	ld	s2,48(sp)
ffffffffc0204668:	79a2                	ld	s3,40(sp)
ffffffffc020466a:	7a02                	ld	s4,32(sp)
ffffffffc020466c:	6ae2                	ld	s5,24(sp)
ffffffffc020466e:	6b42                	ld	s6,16(sp)
ffffffffc0204670:	6ba2                	ld	s7,8(sp)
ffffffffc0204672:	6161                	addi	sp,sp,80
ffffffffc0204674:	8082                	ret
        if (proc != NULL && proc->parent == current)
ffffffffc0204676:	000bb683          	ld	a3,0(s7)
ffffffffc020467a:	f4843783          	ld	a5,-184(s0)
ffffffffc020467e:	fed790e3          	bne	a5,a3,ffffffffc020465e <do_wait.part.0+0x64>
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204682:	f2842703          	lw	a4,-216(s0)
ffffffffc0204686:	478d                	li	a5,3
ffffffffc0204688:	0ef70b63          	beq	a4,a5,ffffffffc020477e <do_wait.part.0+0x184>
        current->state = PROC_SLEEPING;
ffffffffc020468c:	4785                	li	a5,1
ffffffffc020468e:	c29c                	sw	a5,0(a3)
        current->wait_state = WT_CHILD;
ffffffffc0204690:	0f26a623          	sw	s2,236(a3)
        schedule();
ffffffffc0204694:	2db000ef          	jal	ra,ffffffffc020516e <schedule>
        if (current->flags & PF_EXITING)
ffffffffc0204698:	000bb783          	ld	a5,0(s7)
ffffffffc020469c:	0b07a783          	lw	a5,176(a5)
ffffffffc02046a0:	8b85                	andi	a5,a5,1
ffffffffc02046a2:	d7c9                	beqz	a5,ffffffffc020462c <do_wait.part.0+0x32>
            do_exit(-E_KILLED);
ffffffffc02046a4:	555d                	li	a0,-9
ffffffffc02046a6:	e0bff0ef          	jal	ra,ffffffffc02044b0 <do_exit>
        proc = current->cptr;
ffffffffc02046aa:	000bb683          	ld	a3,0(s7)
ffffffffc02046ae:	7ae0                	ld	s0,240(a3)
        for (; proc != NULL; proc = proc->optr)
ffffffffc02046b0:	d45d                	beqz	s0,ffffffffc020465e <do_wait.part.0+0x64>
            if (proc->state == PROC_ZOMBIE)
ffffffffc02046b2:	470d                	li	a4,3
ffffffffc02046b4:	a021                	j	ffffffffc02046bc <do_wait.part.0+0xc2>
        for (; proc != NULL; proc = proc->optr)
ffffffffc02046b6:	10043403          	ld	s0,256(s0)
ffffffffc02046ba:	d869                	beqz	s0,ffffffffc020468c <do_wait.part.0+0x92>
            if (proc->state == PROC_ZOMBIE)
ffffffffc02046bc:	401c                	lw	a5,0(s0)
ffffffffc02046be:	fee79ce3          	bne	a5,a4,ffffffffc02046b6 <do_wait.part.0+0xbc>
    if (proc == idleproc || proc == initproc)
ffffffffc02046c2:	000a6797          	auipc	a5,0xa6
ffffffffc02046c6:	23e7b783          	ld	a5,574(a5) # ffffffffc02aa900 <idleproc>
ffffffffc02046ca:	0c878963          	beq	a5,s0,ffffffffc020479c <do_wait.part.0+0x1a2>
ffffffffc02046ce:	000a6797          	auipc	a5,0xa6
ffffffffc02046d2:	23a7b783          	ld	a5,570(a5) # ffffffffc02aa908 <initproc>
ffffffffc02046d6:	0cf40363          	beq	s0,a5,ffffffffc020479c <do_wait.part.0+0x1a2>
    if (code_store != NULL)
ffffffffc02046da:	000a0663          	beqz	s4,ffffffffc02046e6 <do_wait.part.0+0xec>
        *code_store = proc->exit_code;
ffffffffc02046de:	0e842783          	lw	a5,232(s0)
ffffffffc02046e2:	00fa2023          	sw	a5,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8bc8>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02046e6:	100027f3          	csrr	a5,sstatus
ffffffffc02046ea:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02046ec:	4581                	li	a1,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02046ee:	e7c1                	bnez	a5,ffffffffc0204776 <do_wait.part.0+0x17c>
    __list_del(listelm->prev, listelm->next);
ffffffffc02046f0:	6c70                	ld	a2,216(s0)
ffffffffc02046f2:	7074                	ld	a3,224(s0)
    if (proc->optr != NULL)
ffffffffc02046f4:	10043703          	ld	a4,256(s0)
        proc->optr->yptr = proc->yptr;
ffffffffc02046f8:	7c7c                	ld	a5,248(s0)
    prev->next = next;
ffffffffc02046fa:	e614                	sd	a3,8(a2)
    next->prev = prev;
ffffffffc02046fc:	e290                	sd	a2,0(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc02046fe:	6470                	ld	a2,200(s0)
ffffffffc0204700:	6874                	ld	a3,208(s0)
    prev->next = next;
ffffffffc0204702:	e614                	sd	a3,8(a2)
    next->prev = prev;
ffffffffc0204704:	e290                	sd	a2,0(a3)
    if (proc->optr != NULL)
ffffffffc0204706:	c319                	beqz	a4,ffffffffc020470c <do_wait.part.0+0x112>
        proc->optr->yptr = proc->yptr;
ffffffffc0204708:	ff7c                	sd	a5,248(a4)
    if (proc->yptr != NULL)
ffffffffc020470a:	7c7c                	ld	a5,248(s0)
ffffffffc020470c:	c3b5                	beqz	a5,ffffffffc0204770 <do_wait.part.0+0x176>
        proc->yptr->optr = proc->optr;
ffffffffc020470e:	10e7b023          	sd	a4,256(a5)
    nr_process--;
ffffffffc0204712:	000a6717          	auipc	a4,0xa6
ffffffffc0204716:	1fe70713          	addi	a4,a4,510 # ffffffffc02aa910 <nr_process>
ffffffffc020471a:	431c                	lw	a5,0(a4)
ffffffffc020471c:	37fd                	addiw	a5,a5,-1
ffffffffc020471e:	c31c                	sw	a5,0(a4)
    if (flag)
ffffffffc0204720:	e5a9                	bnez	a1,ffffffffc020476a <do_wait.part.0+0x170>
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
ffffffffc0204722:	6814                	ld	a3,16(s0)
    return pa2page(PADDR(kva));
ffffffffc0204724:	c02007b7          	lui	a5,0xc0200
ffffffffc0204728:	04f6ee63          	bltu	a3,a5,ffffffffc0204784 <do_wait.part.0+0x18a>
ffffffffc020472c:	000a6797          	auipc	a5,0xa6
ffffffffc0204730:	1c47b783          	ld	a5,452(a5) # ffffffffc02aa8f0 <va_pa_offset>
ffffffffc0204734:	8e9d                	sub	a3,a3,a5
    if (PPN(pa) >= npage)
ffffffffc0204736:	82b1                	srli	a3,a3,0xc
ffffffffc0204738:	000a6797          	auipc	a5,0xa6
ffffffffc020473c:	1a07b783          	ld	a5,416(a5) # ffffffffc02aa8d8 <npage>
ffffffffc0204740:	06f6fa63          	bgeu	a3,a5,ffffffffc02047b4 <do_wait.part.0+0x1ba>
    return &pages[PPN(pa) - nbase];
ffffffffc0204744:	00003517          	auipc	a0,0x3
ffffffffc0204748:	1f453503          	ld	a0,500(a0) # ffffffffc0207938 <nbase>
ffffffffc020474c:	8e89                	sub	a3,a3,a0
ffffffffc020474e:	069a                	slli	a3,a3,0x6
ffffffffc0204750:	000a6517          	auipc	a0,0xa6
ffffffffc0204754:	19053503          	ld	a0,400(a0) # ffffffffc02aa8e0 <pages>
ffffffffc0204758:	9536                	add	a0,a0,a3
ffffffffc020475a:	4589                	li	a1,2
ffffffffc020475c:	823fd0ef          	jal	ra,ffffffffc0201f7e <free_pages>
    kfree(proc);
ffffffffc0204760:	8522                	mv	a0,s0
ffffffffc0204762:	eb0fd0ef          	jal	ra,ffffffffc0201e12 <kfree>
    return 0;
ffffffffc0204766:	4501                	li	a0,0
ffffffffc0204768:	bde5                	j	ffffffffc0204660 <do_wait.part.0+0x66>
        intr_enable();
ffffffffc020476a:	a44fc0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc020476e:	bf55                	j	ffffffffc0204722 <do_wait.part.0+0x128>
        proc->parent->cptr = proc->optr;
ffffffffc0204770:	701c                	ld	a5,32(s0)
ffffffffc0204772:	fbf8                	sd	a4,240(a5)
ffffffffc0204774:	bf79                	j	ffffffffc0204712 <do_wait.part.0+0x118>
        intr_disable();
ffffffffc0204776:	a3efc0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc020477a:	4585                	li	a1,1
ffffffffc020477c:	bf95                	j	ffffffffc02046f0 <do_wait.part.0+0xf6>
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc020477e:	f2840413          	addi	s0,s0,-216
ffffffffc0204782:	b781                	j	ffffffffc02046c2 <do_wait.part.0+0xc8>
    return pa2page(PADDR(kva));
ffffffffc0204784:	00002617          	auipc	a2,0x2
ffffffffc0204788:	f8c60613          	addi	a2,a2,-116 # ffffffffc0206710 <default_pmm_manager+0xe0>
ffffffffc020478c:	07700593          	li	a1,119
ffffffffc0204790:	00002517          	auipc	a0,0x2
ffffffffc0204794:	f0050513          	addi	a0,a0,-256 # ffffffffc0206690 <default_pmm_manager+0x60>
ffffffffc0204798:	cf7fb0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("wait idleproc or initproc.\n");
ffffffffc020479c:	00003617          	auipc	a2,0x3
ffffffffc02047a0:	98460613          	addi	a2,a2,-1660 # ffffffffc0207120 <default_pmm_manager+0xaf0>
ffffffffc02047a4:	39100593          	li	a1,913
ffffffffc02047a8:	00003517          	auipc	a0,0x3
ffffffffc02047ac:	8f850513          	addi	a0,a0,-1800 # ffffffffc02070a0 <default_pmm_manager+0xa70>
ffffffffc02047b0:	cdffb0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("pa2page called with invalid pa");
ffffffffc02047b4:	00002617          	auipc	a2,0x2
ffffffffc02047b8:	f8460613          	addi	a2,a2,-124 # ffffffffc0206738 <default_pmm_manager+0x108>
ffffffffc02047bc:	06900593          	li	a1,105
ffffffffc02047c0:	00002517          	auipc	a0,0x2
ffffffffc02047c4:	ed050513          	addi	a0,a0,-304 # ffffffffc0206690 <default_pmm_manager+0x60>
ffffffffc02047c8:	cc7fb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02047cc <init_main>:
}

// init_main - the second kernel thread used to create user_main kernel threads
static int
init_main(void *arg)
{
ffffffffc02047cc:	1141                	addi	sp,sp,-16
ffffffffc02047ce:	e406                	sd	ra,8(sp)
    size_t nr_free_pages_store = nr_free_pages();
ffffffffc02047d0:	feefd0ef          	jal	ra,ffffffffc0201fbe <nr_free_pages>
    size_t kernel_allocated_store = kallocated();
ffffffffc02047d4:	d8afd0ef          	jal	ra,ffffffffc0201d5e <kallocated>

    int pid = kernel_thread(user_main, NULL, 0);
ffffffffc02047d8:	4601                	li	a2,0
ffffffffc02047da:	4581                	li	a1,0
ffffffffc02047dc:	fffff517          	auipc	a0,0xfffff
ffffffffc02047e0:	74c50513          	addi	a0,a0,1868 # ffffffffc0203f28 <user_main>
ffffffffc02047e4:	c7dff0ef          	jal	ra,ffffffffc0204460 <kernel_thread>
    if (pid <= 0)
ffffffffc02047e8:	00a04563          	bgtz	a0,ffffffffc02047f2 <init_main+0x26>
ffffffffc02047ec:	a071                	j	ffffffffc0204878 <init_main+0xac>
        panic("create user_main failed.\n");
    }

    while (do_wait(0, NULL) == 0)
    {
        schedule();
ffffffffc02047ee:	181000ef          	jal	ra,ffffffffc020516e <schedule>
    if (code_store != NULL)
ffffffffc02047f2:	4581                	li	a1,0
ffffffffc02047f4:	4501                	li	a0,0
ffffffffc02047f6:	e05ff0ef          	jal	ra,ffffffffc02045fa <do_wait.part.0>
    while (do_wait(0, NULL) == 0)
ffffffffc02047fa:	d975                	beqz	a0,ffffffffc02047ee <init_main+0x22>
    }

    cprintf("all user-mode processes have quit.\n");
ffffffffc02047fc:	00003517          	auipc	a0,0x3
ffffffffc0204800:	96450513          	addi	a0,a0,-1692 # ffffffffc0207160 <default_pmm_manager+0xb30>
ffffffffc0204804:	991fb0ef          	jal	ra,ffffffffc0200194 <cprintf>
    assert(initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL);
ffffffffc0204808:	000a6797          	auipc	a5,0xa6
ffffffffc020480c:	1007b783          	ld	a5,256(a5) # ffffffffc02aa908 <initproc>
ffffffffc0204810:	7bf8                	ld	a4,240(a5)
ffffffffc0204812:	e339                	bnez	a4,ffffffffc0204858 <init_main+0x8c>
ffffffffc0204814:	7ff8                	ld	a4,248(a5)
ffffffffc0204816:	e329                	bnez	a4,ffffffffc0204858 <init_main+0x8c>
ffffffffc0204818:	1007b703          	ld	a4,256(a5)
ffffffffc020481c:	ef15                	bnez	a4,ffffffffc0204858 <init_main+0x8c>
    assert(nr_process == 2);
ffffffffc020481e:	000a6697          	auipc	a3,0xa6
ffffffffc0204822:	0f26a683          	lw	a3,242(a3) # ffffffffc02aa910 <nr_process>
ffffffffc0204826:	4709                	li	a4,2
ffffffffc0204828:	0ae69463          	bne	a3,a4,ffffffffc02048d0 <init_main+0x104>
    return listelm->next;
ffffffffc020482c:	000a6697          	auipc	a3,0xa6
ffffffffc0204830:	05c68693          	addi	a3,a3,92 # ffffffffc02aa888 <proc_list>
    assert(list_next(&proc_list) == &(initproc->list_link));
ffffffffc0204834:	6698                	ld	a4,8(a3)
ffffffffc0204836:	0c878793          	addi	a5,a5,200
ffffffffc020483a:	06f71b63          	bne	a4,a5,ffffffffc02048b0 <init_main+0xe4>
    assert(list_prev(&proc_list) == &(initproc->list_link));
ffffffffc020483e:	629c                	ld	a5,0(a3)
ffffffffc0204840:	04f71863          	bne	a4,a5,ffffffffc0204890 <init_main+0xc4>

    cprintf("init check memory pass.\n");
ffffffffc0204844:	00003517          	auipc	a0,0x3
ffffffffc0204848:	a0450513          	addi	a0,a0,-1532 # ffffffffc0207248 <default_pmm_manager+0xc18>
ffffffffc020484c:	949fb0ef          	jal	ra,ffffffffc0200194 <cprintf>
    return 0;
}
ffffffffc0204850:	60a2                	ld	ra,8(sp)
ffffffffc0204852:	4501                	li	a0,0
ffffffffc0204854:	0141                	addi	sp,sp,16
ffffffffc0204856:	8082                	ret
    assert(initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL);
ffffffffc0204858:	00003697          	auipc	a3,0x3
ffffffffc020485c:	93068693          	addi	a3,a3,-1744 # ffffffffc0207188 <default_pmm_manager+0xb58>
ffffffffc0204860:	00002617          	auipc	a2,0x2
ffffffffc0204864:	a2060613          	addi	a2,a2,-1504 # ffffffffc0206280 <commands+0x868>
ffffffffc0204868:	3ff00593          	li	a1,1023
ffffffffc020486c:	00003517          	auipc	a0,0x3
ffffffffc0204870:	83450513          	addi	a0,a0,-1996 # ffffffffc02070a0 <default_pmm_manager+0xa70>
ffffffffc0204874:	c1bfb0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("create user_main failed.\n");
ffffffffc0204878:	00003617          	auipc	a2,0x3
ffffffffc020487c:	8c860613          	addi	a2,a2,-1848 # ffffffffc0207140 <default_pmm_manager+0xb10>
ffffffffc0204880:	3f600593          	li	a1,1014
ffffffffc0204884:	00003517          	auipc	a0,0x3
ffffffffc0204888:	81c50513          	addi	a0,a0,-2020 # ffffffffc02070a0 <default_pmm_manager+0xa70>
ffffffffc020488c:	c03fb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(list_prev(&proc_list) == &(initproc->list_link));
ffffffffc0204890:	00003697          	auipc	a3,0x3
ffffffffc0204894:	98868693          	addi	a3,a3,-1656 # ffffffffc0207218 <default_pmm_manager+0xbe8>
ffffffffc0204898:	00002617          	auipc	a2,0x2
ffffffffc020489c:	9e860613          	addi	a2,a2,-1560 # ffffffffc0206280 <commands+0x868>
ffffffffc02048a0:	40200593          	li	a1,1026
ffffffffc02048a4:	00002517          	auipc	a0,0x2
ffffffffc02048a8:	7fc50513          	addi	a0,a0,2044 # ffffffffc02070a0 <default_pmm_manager+0xa70>
ffffffffc02048ac:	be3fb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(list_next(&proc_list) == &(initproc->list_link));
ffffffffc02048b0:	00003697          	auipc	a3,0x3
ffffffffc02048b4:	93868693          	addi	a3,a3,-1736 # ffffffffc02071e8 <default_pmm_manager+0xbb8>
ffffffffc02048b8:	00002617          	auipc	a2,0x2
ffffffffc02048bc:	9c860613          	addi	a2,a2,-1592 # ffffffffc0206280 <commands+0x868>
ffffffffc02048c0:	40100593          	li	a1,1025
ffffffffc02048c4:	00002517          	auipc	a0,0x2
ffffffffc02048c8:	7dc50513          	addi	a0,a0,2012 # ffffffffc02070a0 <default_pmm_manager+0xa70>
ffffffffc02048cc:	bc3fb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_process == 2);
ffffffffc02048d0:	00003697          	auipc	a3,0x3
ffffffffc02048d4:	90868693          	addi	a3,a3,-1784 # ffffffffc02071d8 <default_pmm_manager+0xba8>
ffffffffc02048d8:	00002617          	auipc	a2,0x2
ffffffffc02048dc:	9a860613          	addi	a2,a2,-1624 # ffffffffc0206280 <commands+0x868>
ffffffffc02048e0:	40000593          	li	a1,1024
ffffffffc02048e4:	00002517          	auipc	a0,0x2
ffffffffc02048e8:	7bc50513          	addi	a0,a0,1980 # ffffffffc02070a0 <default_pmm_manager+0xa70>
ffffffffc02048ec:	ba3fb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02048f0 <do_execve>:
{
ffffffffc02048f0:	7171                	addi	sp,sp,-176
ffffffffc02048f2:	e4ee                	sd	s11,72(sp)
    struct mm_struct *mm = current->mm;
ffffffffc02048f4:	000a6d97          	auipc	s11,0xa6
ffffffffc02048f8:	004d8d93          	addi	s11,s11,4 # ffffffffc02aa8f8 <current>
ffffffffc02048fc:	000db783          	ld	a5,0(s11)
{
ffffffffc0204900:	e54e                	sd	s3,136(sp)
ffffffffc0204902:	ed26                	sd	s1,152(sp)
    struct mm_struct *mm = current->mm;
ffffffffc0204904:	0287b983          	ld	s3,40(a5)
{
ffffffffc0204908:	e94a                	sd	s2,144(sp)
ffffffffc020490a:	f4de                	sd	s7,104(sp)
ffffffffc020490c:	892a                	mv	s2,a0
ffffffffc020490e:	8bb2                	mv	s7,a2
ffffffffc0204910:	84ae                	mv	s1,a1
    if (!user_mem_check(mm, (uintptr_t)name, len, 0)) //检查name的内存空间能否被访问
ffffffffc0204912:	862e                	mv	a2,a1
ffffffffc0204914:	4681                	li	a3,0
ffffffffc0204916:	85aa                	mv	a1,a0
ffffffffc0204918:	854e                	mv	a0,s3
{
ffffffffc020491a:	f506                	sd	ra,168(sp)
ffffffffc020491c:	f122                	sd	s0,160(sp)
ffffffffc020491e:	e152                	sd	s4,128(sp)
ffffffffc0204920:	fcd6                	sd	s5,120(sp)
ffffffffc0204922:	f8da                	sd	s6,112(sp)
ffffffffc0204924:	f0e2                	sd	s8,96(sp)
ffffffffc0204926:	ece6                	sd	s9,88(sp)
ffffffffc0204928:	e8ea                	sd	s10,80(sp)
ffffffffc020492a:	f05e                	sd	s7,32(sp)
    if (!user_mem_check(mm, (uintptr_t)name, len, 0)) //检查name的内存空间能否被访问
ffffffffc020492c:	cd0ff0ef          	jal	ra,ffffffffc0203dfc <user_mem_check>
ffffffffc0204930:	40050c63          	beqz	a0,ffffffffc0204d48 <do_execve+0x458>
    memset(local_name, 0, sizeof(local_name));
ffffffffc0204934:	4641                	li	a2,16
ffffffffc0204936:	4581                	li	a1,0
ffffffffc0204938:	1808                	addi	a0,sp,48
ffffffffc020493a:	647000ef          	jal	ra,ffffffffc0205780 <memset>
    memcpy(local_name, name, len);
ffffffffc020493e:	47bd                	li	a5,15
ffffffffc0204940:	8626                	mv	a2,s1
ffffffffc0204942:	1e97e463          	bltu	a5,s1,ffffffffc0204b2a <do_execve+0x23a>
ffffffffc0204946:	85ca                	mv	a1,s2
ffffffffc0204948:	1808                	addi	a0,sp,48
ffffffffc020494a:	649000ef          	jal	ra,ffffffffc0205792 <memcpy>
    if (mm != NULL)
ffffffffc020494e:	1e098563          	beqz	s3,ffffffffc0204b38 <do_execve+0x248>
        cputs("mm != NULL");
ffffffffc0204952:	00002517          	auipc	a0,0x2
ffffffffc0204956:	50e50513          	addi	a0,a0,1294 # ffffffffc0206e60 <default_pmm_manager+0x830>
ffffffffc020495a:	873fb0ef          	jal	ra,ffffffffc02001cc <cputs>
ffffffffc020495e:	000a6797          	auipc	a5,0xa6
ffffffffc0204962:	f6a7b783          	ld	a5,-150(a5) # ffffffffc02aa8c8 <boot_pgdir_pa>
ffffffffc0204966:	577d                	li	a4,-1
ffffffffc0204968:	177e                	slli	a4,a4,0x3f
ffffffffc020496a:	83b1                	srli	a5,a5,0xc
ffffffffc020496c:	8fd9                	or	a5,a5,a4
ffffffffc020496e:	18079073          	csrw	satp,a5
ffffffffc0204972:	0309a783          	lw	a5,48(s3) # 2030 <_binary_obj___user_faultread_out_size-0x7b98>
ffffffffc0204976:	fff7871b          	addiw	a4,a5,-1
ffffffffc020497a:	02e9a823          	sw	a4,48(s3)
        if (mm_count_dec(mm) == 0)
ffffffffc020497e:	2c070663          	beqz	a4,ffffffffc0204c4a <do_execve+0x35a>
        current->mm = NULL;
ffffffffc0204982:	000db783          	ld	a5,0(s11)
ffffffffc0204986:	0207b423          	sd	zero,40(a5)
    if ((mm = mm_create()) == NULL)
ffffffffc020498a:	dfdfe0ef          	jal	ra,ffffffffc0203786 <mm_create>
ffffffffc020498e:	84aa                	mv	s1,a0
ffffffffc0204990:	1c050f63          	beqz	a0,ffffffffc0204b6e <do_execve+0x27e>
    if ((page = alloc_page()) == NULL)
ffffffffc0204994:	4505                	li	a0,1
ffffffffc0204996:	daafd0ef          	jal	ra,ffffffffc0201f40 <alloc_pages>
ffffffffc020499a:	3a050b63          	beqz	a0,ffffffffc0204d50 <do_execve+0x460>
    return page - pages + nbase;
ffffffffc020499e:	000a6c97          	auipc	s9,0xa6
ffffffffc02049a2:	f42c8c93          	addi	s9,s9,-190 # ffffffffc02aa8e0 <pages>
ffffffffc02049a6:	000cb683          	ld	a3,0(s9)
    return KADDR(page2pa(page));
ffffffffc02049aa:	000a6c17          	auipc	s8,0xa6
ffffffffc02049ae:	f2ec0c13          	addi	s8,s8,-210 # ffffffffc02aa8d8 <npage>
    return page - pages + nbase;
ffffffffc02049b2:	00003717          	auipc	a4,0x3
ffffffffc02049b6:	f8673703          	ld	a4,-122(a4) # ffffffffc0207938 <nbase>
ffffffffc02049ba:	40d506b3          	sub	a3,a0,a3
ffffffffc02049be:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc02049c0:	5afd                	li	s5,-1
ffffffffc02049c2:	000c3783          	ld	a5,0(s8)
    return page - pages + nbase;
ffffffffc02049c6:	96ba                	add	a3,a3,a4
ffffffffc02049c8:	e83a                	sd	a4,16(sp)
    return KADDR(page2pa(page));
ffffffffc02049ca:	00cad713          	srli	a4,s5,0xc
ffffffffc02049ce:	ec3a                	sd	a4,24(sp)
ffffffffc02049d0:	8f75                	and	a4,a4,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc02049d2:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02049d4:	38f77263          	bgeu	a4,a5,ffffffffc0204d58 <do_execve+0x468>
ffffffffc02049d8:	000a6b17          	auipc	s6,0xa6
ffffffffc02049dc:	f18b0b13          	addi	s6,s6,-232 # ffffffffc02aa8f0 <va_pa_offset>
ffffffffc02049e0:	000b3903          	ld	s2,0(s6)
    memcpy(pgdir, boot_pgdir_va, PGSIZE);
ffffffffc02049e4:	6605                	lui	a2,0x1
ffffffffc02049e6:	000a6597          	auipc	a1,0xa6
ffffffffc02049ea:	eea5b583          	ld	a1,-278(a1) # ffffffffc02aa8d0 <boot_pgdir_va>
ffffffffc02049ee:	9936                	add	s2,s2,a3
ffffffffc02049f0:	854a                	mv	a0,s2
ffffffffc02049f2:	5a1000ef          	jal	ra,ffffffffc0205792 <memcpy>
    if (elf->e_magic != ELF_MAGIC)
ffffffffc02049f6:	7782                	ld	a5,32(sp)
ffffffffc02049f8:	4398                	lw	a4,0(a5)
ffffffffc02049fa:	464c47b7          	lui	a5,0x464c4
    mm->pgdir = pgdir;
ffffffffc02049fe:	0124bc23          	sd	s2,24(s1)
    if (elf->e_magic != ELF_MAGIC)
ffffffffc0204a02:	57f78793          	addi	a5,a5,1407 # 464c457f <_binary_obj___user_exit_out_size+0x464b943f>
ffffffffc0204a06:	14f71a63          	bne	a4,a5,ffffffffc0204b5a <do_execve+0x26a>
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc0204a0a:	7682                	ld	a3,32(sp)
ffffffffc0204a0c:	0386d703          	lhu	a4,56(a3)
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
ffffffffc0204a10:	0206b983          	ld	s3,32(a3)
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc0204a14:	00371793          	slli	a5,a4,0x3
ffffffffc0204a18:	8f99                	sub	a5,a5,a4
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
ffffffffc0204a1a:	99b6                	add	s3,s3,a3
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc0204a1c:	078e                	slli	a5,a5,0x3
ffffffffc0204a1e:	97ce                	add	a5,a5,s3
ffffffffc0204a20:	f43e                	sd	a5,40(sp)
    for (; ph < ph_end; ph++)
ffffffffc0204a22:	00f9fc63          	bgeu	s3,a5,ffffffffc0204a3a <do_execve+0x14a>
        if (ph->p_type != ELF_PT_LOAD)
ffffffffc0204a26:	0009a783          	lw	a5,0(s3)
ffffffffc0204a2a:	4705                	li	a4,1
ffffffffc0204a2c:	14e78363          	beq	a5,a4,ffffffffc0204b72 <do_execve+0x282>
    for (; ph < ph_end; ph++)
ffffffffc0204a30:	77a2                	ld	a5,40(sp)
ffffffffc0204a32:	03898993          	addi	s3,s3,56
ffffffffc0204a36:	fef9e8e3          	bltu	s3,a5,ffffffffc0204a26 <do_execve+0x136>
    if ((ret = mm_map(mm, USTACKTOP - USTACKSIZE, USTACKSIZE, vm_flags, NULL)) != 0)
ffffffffc0204a3a:	4701                	li	a4,0
ffffffffc0204a3c:	46ad                	li	a3,11
ffffffffc0204a3e:	00100637          	lui	a2,0x100
ffffffffc0204a42:	7ff005b7          	lui	a1,0x7ff00
ffffffffc0204a46:	8526                	mv	a0,s1
ffffffffc0204a48:	ed1fe0ef          	jal	ra,ffffffffc0203918 <mm_map>
ffffffffc0204a4c:	8a2a                	mv	s4,a0
ffffffffc0204a4e:	1e051463          	bnez	a0,ffffffffc0204c36 <do_execve+0x346>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - PGSIZE, PTE_USER) != NULL);
ffffffffc0204a52:	6c88                	ld	a0,24(s1)
ffffffffc0204a54:	467d                	li	a2,31
ffffffffc0204a56:	7ffff5b7          	lui	a1,0x7ffff
ffffffffc0204a5a:	c47fe0ef          	jal	ra,ffffffffc02036a0 <pgdir_alloc_page>
ffffffffc0204a5e:	38050563          	beqz	a0,ffffffffc0204de8 <do_execve+0x4f8>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 2 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204a62:	6c88                	ld	a0,24(s1)
ffffffffc0204a64:	467d                	li	a2,31
ffffffffc0204a66:	7fffe5b7          	lui	a1,0x7fffe
ffffffffc0204a6a:	c37fe0ef          	jal	ra,ffffffffc02036a0 <pgdir_alloc_page>
ffffffffc0204a6e:	34050d63          	beqz	a0,ffffffffc0204dc8 <do_execve+0x4d8>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 3 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204a72:	6c88                	ld	a0,24(s1)
ffffffffc0204a74:	467d                	li	a2,31
ffffffffc0204a76:	7fffd5b7          	lui	a1,0x7fffd
ffffffffc0204a7a:	c27fe0ef          	jal	ra,ffffffffc02036a0 <pgdir_alloc_page>
ffffffffc0204a7e:	32050563          	beqz	a0,ffffffffc0204da8 <do_execve+0x4b8>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 4 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204a82:	6c88                	ld	a0,24(s1)
ffffffffc0204a84:	467d                	li	a2,31
ffffffffc0204a86:	7fffc5b7          	lui	a1,0x7fffc
ffffffffc0204a8a:	c17fe0ef          	jal	ra,ffffffffc02036a0 <pgdir_alloc_page>
ffffffffc0204a8e:	2e050d63          	beqz	a0,ffffffffc0204d88 <do_execve+0x498>
    mm->mm_count += 1;
ffffffffc0204a92:	589c                	lw	a5,48(s1)
    current->mm = mm;
ffffffffc0204a94:	000db603          	ld	a2,0(s11)
    current->pgdir = PADDR(mm->pgdir);
ffffffffc0204a98:	6c94                	ld	a3,24(s1)
ffffffffc0204a9a:	2785                	addiw	a5,a5,1
ffffffffc0204a9c:	d89c                	sw	a5,48(s1)
    current->mm = mm;
ffffffffc0204a9e:	f604                	sd	s1,40(a2)
    current->pgdir = PADDR(mm->pgdir);
ffffffffc0204aa0:	c02007b7          	lui	a5,0xc0200
ffffffffc0204aa4:	2cf6e663          	bltu	a3,a5,ffffffffc0204d70 <do_execve+0x480>
ffffffffc0204aa8:	000b3783          	ld	a5,0(s6)
ffffffffc0204aac:	577d                	li	a4,-1
ffffffffc0204aae:	177e                	slli	a4,a4,0x3f
ffffffffc0204ab0:	8e9d                	sub	a3,a3,a5
ffffffffc0204ab2:	00c6d793          	srli	a5,a3,0xc
ffffffffc0204ab6:	f654                	sd	a3,168(a2)
ffffffffc0204ab8:	8fd9                	or	a5,a5,a4
ffffffffc0204aba:	18079073          	csrw	satp,a5
    struct trapframe *tf = current->tf;
ffffffffc0204abe:	7240                	ld	s0,160(a2)
    memset(tf, 0, sizeof(struct trapframe));
ffffffffc0204ac0:	4581                	li	a1,0
ffffffffc0204ac2:	12000613          	li	a2,288
ffffffffc0204ac6:	8522                	mv	a0,s0
    uintptr_t sstatus = tf->status;
ffffffffc0204ac8:	10043483          	ld	s1,256(s0)
    memset(tf, 0, sizeof(struct trapframe));
ffffffffc0204acc:	4b5000ef          	jal	ra,ffffffffc0205780 <memset>
    tf->epc = (uintptr_t)elf->e_entry;
ffffffffc0204ad0:	7782                	ld	a5,32(sp)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204ad2:	000db903          	ld	s2,0(s11)
    tf->status = (sstatus & ~SSTATUS_SPP) | SSTATUS_SPIE;
ffffffffc0204ad6:	edf4f493          	andi	s1,s1,-289
    tf->epc = (uintptr_t)elf->e_entry;
ffffffffc0204ada:	6f98                	ld	a4,24(a5)
    tf->gpr.sp = (uintptr_t)USTACKTOP;
ffffffffc0204adc:	4785                	li	a5,1
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204ade:	0b490913          	addi	s2,s2,180 # ffffffff800000b4 <_binary_obj___user_exit_out_size+0xffffffff7fff4f74>
    tf->gpr.sp = (uintptr_t)USTACKTOP;
ffffffffc0204ae2:	07fe                	slli	a5,a5,0x1f
    tf->status = (sstatus & ~SSTATUS_SPP) | SSTATUS_SPIE;
ffffffffc0204ae4:	0204e493          	ori	s1,s1,32
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204ae8:	4641                	li	a2,16
ffffffffc0204aea:	4581                	li	a1,0
    tf->gpr.sp = (uintptr_t)USTACKTOP;
ffffffffc0204aec:	e81c                	sd	a5,16(s0)
    tf->epc = (uintptr_t)elf->e_entry;
ffffffffc0204aee:	10e43423          	sd	a4,264(s0)
    tf->gpr.a0 = 0;  // 把 SSTATUS_SPP 设置为0，使得 sret 的时候能回到 U mode
ffffffffc0204af2:	04043823          	sd	zero,80(s0)
    tf->status = (sstatus & ~SSTATUS_SPP) | SSTATUS_SPIE;
ffffffffc0204af6:	10943023          	sd	s1,256(s0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204afa:	854a                	mv	a0,s2
ffffffffc0204afc:	485000ef          	jal	ra,ffffffffc0205780 <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0204b00:	463d                	li	a2,15
ffffffffc0204b02:	180c                	addi	a1,sp,48
ffffffffc0204b04:	854a                	mv	a0,s2
ffffffffc0204b06:	48d000ef          	jal	ra,ffffffffc0205792 <memcpy>
}
ffffffffc0204b0a:	70aa                	ld	ra,168(sp)
ffffffffc0204b0c:	740a                	ld	s0,160(sp)
ffffffffc0204b0e:	64ea                	ld	s1,152(sp)
ffffffffc0204b10:	694a                	ld	s2,144(sp)
ffffffffc0204b12:	69aa                	ld	s3,136(sp)
ffffffffc0204b14:	7ae6                	ld	s5,120(sp)
ffffffffc0204b16:	7b46                	ld	s6,112(sp)
ffffffffc0204b18:	7ba6                	ld	s7,104(sp)
ffffffffc0204b1a:	7c06                	ld	s8,96(sp)
ffffffffc0204b1c:	6ce6                	ld	s9,88(sp)
ffffffffc0204b1e:	6d46                	ld	s10,80(sp)
ffffffffc0204b20:	6da6                	ld	s11,72(sp)
ffffffffc0204b22:	8552                	mv	a0,s4
ffffffffc0204b24:	6a0a                	ld	s4,128(sp)
ffffffffc0204b26:	614d                	addi	sp,sp,176
ffffffffc0204b28:	8082                	ret
    memcpy(local_name, name, len);
ffffffffc0204b2a:	463d                	li	a2,15
ffffffffc0204b2c:	85ca                	mv	a1,s2
ffffffffc0204b2e:	1808                	addi	a0,sp,48
ffffffffc0204b30:	463000ef          	jal	ra,ffffffffc0205792 <memcpy>
    if (mm != NULL)
ffffffffc0204b34:	e0099fe3          	bnez	s3,ffffffffc0204952 <do_execve+0x62>
    if (current->mm != NULL)
ffffffffc0204b38:	000db783          	ld	a5,0(s11)
ffffffffc0204b3c:	779c                	ld	a5,40(a5)
ffffffffc0204b3e:	e40786e3          	beqz	a5,ffffffffc020498a <do_execve+0x9a>
        panic("load_icode: current->mm must be empty.\n");
ffffffffc0204b42:	00002617          	auipc	a2,0x2
ffffffffc0204b46:	72660613          	addi	a2,a2,1830 # ffffffffc0207268 <default_pmm_manager+0xc38>
ffffffffc0204b4a:	27300593          	li	a1,627
ffffffffc0204b4e:	00002517          	auipc	a0,0x2
ffffffffc0204b52:	55250513          	addi	a0,a0,1362 # ffffffffc02070a0 <default_pmm_manager+0xa70>
ffffffffc0204b56:	939fb0ef          	jal	ra,ffffffffc020048e <__panic>
    put_pgdir(mm);
ffffffffc0204b5a:	8526                	mv	a0,s1
ffffffffc0204b5c:	c4aff0ef          	jal	ra,ffffffffc0203fa6 <put_pgdir>
    mm_destroy(mm);
ffffffffc0204b60:	8526                	mv	a0,s1
ffffffffc0204b62:	d65fe0ef          	jal	ra,ffffffffc02038c6 <mm_destroy>
        ret = -E_INVAL_ELF;
ffffffffc0204b66:	5a61                	li	s4,-8
    do_exit(ret);
ffffffffc0204b68:	8552                	mv	a0,s4
ffffffffc0204b6a:	947ff0ef          	jal	ra,ffffffffc02044b0 <do_exit>
    int ret = -E_NO_MEM;
ffffffffc0204b6e:	5a71                	li	s4,-4
ffffffffc0204b70:	bfe5                	j	ffffffffc0204b68 <do_execve+0x278>
        if (ph->p_filesz > ph->p_memsz)
ffffffffc0204b72:	0289b603          	ld	a2,40(s3)
ffffffffc0204b76:	0209b783          	ld	a5,32(s3)
ffffffffc0204b7a:	1cf66d63          	bltu	a2,a5,ffffffffc0204d54 <do_execve+0x464>
        if (ph->p_flags & ELF_PF_X)
ffffffffc0204b7e:	0049a783          	lw	a5,4(s3)
ffffffffc0204b82:	0017f693          	andi	a3,a5,1
ffffffffc0204b86:	c291                	beqz	a3,ffffffffc0204b8a <do_execve+0x29a>
            vm_flags |= VM_EXEC;
ffffffffc0204b88:	4691                	li	a3,4
        if (ph->p_flags & ELF_PF_W)
ffffffffc0204b8a:	0027f713          	andi	a4,a5,2
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204b8e:	8b91                	andi	a5,a5,4
        if (ph->p_flags & ELF_PF_W)
ffffffffc0204b90:	e779                	bnez	a4,ffffffffc0204c5e <do_execve+0x36e>
        vm_flags = 0, perm = PTE_U | PTE_V;
ffffffffc0204b92:	4d45                	li	s10,17
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204b94:	c781                	beqz	a5,ffffffffc0204b9c <do_execve+0x2ac>
            vm_flags |= VM_READ;
ffffffffc0204b96:	0016e693          	ori	a3,a3,1
            perm |= PTE_R;
ffffffffc0204b9a:	4d4d                	li	s10,19
        if (vm_flags & VM_WRITE)
ffffffffc0204b9c:	0026f793          	andi	a5,a3,2
ffffffffc0204ba0:	e3f1                	bnez	a5,ffffffffc0204c64 <do_execve+0x374>
        if (vm_flags & VM_EXEC)
ffffffffc0204ba2:	0046f793          	andi	a5,a3,4
ffffffffc0204ba6:	c399                	beqz	a5,ffffffffc0204bac <do_execve+0x2bc>
            perm |= PTE_X;
ffffffffc0204ba8:	008d6d13          	ori	s10,s10,8
        if ((ret = mm_map(mm, ph->p_va, ph->p_memsz, vm_flags, NULL)) != 0)
ffffffffc0204bac:	0109b583          	ld	a1,16(s3)
ffffffffc0204bb0:	4701                	li	a4,0
ffffffffc0204bb2:	8526                	mv	a0,s1
ffffffffc0204bb4:	d65fe0ef          	jal	ra,ffffffffc0203918 <mm_map>
ffffffffc0204bb8:	8a2a                	mv	s4,a0
ffffffffc0204bba:	ed35                	bnez	a0,ffffffffc0204c36 <do_execve+0x346>
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc0204bbc:	0109bb83          	ld	s7,16(s3)
ffffffffc0204bc0:	77fd                	lui	a5,0xfffff
        end = ph->p_va + ph->p_filesz;
ffffffffc0204bc2:	0209ba03          	ld	s4,32(s3)
        unsigned char *from = binary + ph->p_offset;
ffffffffc0204bc6:	0089b903          	ld	s2,8(s3)
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc0204bca:	00fbfab3          	and	s5,s7,a5
        unsigned char *from = binary + ph->p_offset;
ffffffffc0204bce:	7782                	ld	a5,32(sp)
        end = ph->p_va + ph->p_filesz;
ffffffffc0204bd0:	9a5e                	add	s4,s4,s7
        unsigned char *from = binary + ph->p_offset;
ffffffffc0204bd2:	993e                	add	s2,s2,a5
        while (start < end)
ffffffffc0204bd4:	054be963          	bltu	s7,s4,ffffffffc0204c26 <do_execve+0x336>
ffffffffc0204bd8:	aa95                	j	ffffffffc0204d4c <do_execve+0x45c>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0204bda:	6785                	lui	a5,0x1
ffffffffc0204bdc:	415b8533          	sub	a0,s7,s5
ffffffffc0204be0:	9abe                	add	s5,s5,a5
ffffffffc0204be2:	417a8633          	sub	a2,s5,s7
            if (end < la)
ffffffffc0204be6:	015a7463          	bgeu	s4,s5,ffffffffc0204bee <do_execve+0x2fe>
                size -= la - end;
ffffffffc0204bea:	417a0633          	sub	a2,s4,s7
    return page - pages + nbase;
ffffffffc0204bee:	000cb683          	ld	a3,0(s9)
ffffffffc0204bf2:	67c2                	ld	a5,16(sp)
    return KADDR(page2pa(page));
ffffffffc0204bf4:	000c3583          	ld	a1,0(s8)
    return page - pages + nbase;
ffffffffc0204bf8:	40d406b3          	sub	a3,s0,a3
ffffffffc0204bfc:	8699                	srai	a3,a3,0x6
ffffffffc0204bfe:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0204c00:	67e2                	ld	a5,24(sp)
ffffffffc0204c02:	00f6f833          	and	a6,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0204c06:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204c08:	14b87863          	bgeu	a6,a1,ffffffffc0204d58 <do_execve+0x468>
ffffffffc0204c0c:	000b3803          	ld	a6,0(s6)
            memcpy(page2kva(page) + off, from, size);
ffffffffc0204c10:	85ca                	mv	a1,s2
            start += size, from += size;
ffffffffc0204c12:	9bb2                	add	s7,s7,a2
ffffffffc0204c14:	96c2                	add	a3,a3,a6
            memcpy(page2kva(page) + off, from, size);
ffffffffc0204c16:	9536                	add	a0,a0,a3
            start += size, from += size;
ffffffffc0204c18:	e432                	sd	a2,8(sp)
            memcpy(page2kva(page) + off, from, size);
ffffffffc0204c1a:	379000ef          	jal	ra,ffffffffc0205792 <memcpy>
            start += size, from += size;
ffffffffc0204c1e:	6622                	ld	a2,8(sp)
ffffffffc0204c20:	9932                	add	s2,s2,a2
        while (start < end)
ffffffffc0204c22:	054bf363          	bgeu	s7,s4,ffffffffc0204c68 <do_execve+0x378>
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL)
ffffffffc0204c26:	6c88                	ld	a0,24(s1)
ffffffffc0204c28:	866a                	mv	a2,s10
ffffffffc0204c2a:	85d6                	mv	a1,s5
ffffffffc0204c2c:	a75fe0ef          	jal	ra,ffffffffc02036a0 <pgdir_alloc_page>
ffffffffc0204c30:	842a                	mv	s0,a0
ffffffffc0204c32:	f545                	bnez	a0,ffffffffc0204bda <do_execve+0x2ea>
        ret = -E_NO_MEM;
ffffffffc0204c34:	5a71                	li	s4,-4
    exit_mmap(mm);
ffffffffc0204c36:	8526                	mv	a0,s1
ffffffffc0204c38:	e2bfe0ef          	jal	ra,ffffffffc0203a62 <exit_mmap>
    put_pgdir(mm);
ffffffffc0204c3c:	8526                	mv	a0,s1
ffffffffc0204c3e:	b68ff0ef          	jal	ra,ffffffffc0203fa6 <put_pgdir>
    mm_destroy(mm);
ffffffffc0204c42:	8526                	mv	a0,s1
ffffffffc0204c44:	c83fe0ef          	jal	ra,ffffffffc02038c6 <mm_destroy>
    return ret;
ffffffffc0204c48:	b705                	j	ffffffffc0204b68 <do_execve+0x278>
            exit_mmap(mm);
ffffffffc0204c4a:	854e                	mv	a0,s3
ffffffffc0204c4c:	e17fe0ef          	jal	ra,ffffffffc0203a62 <exit_mmap>
            put_pgdir(mm);
ffffffffc0204c50:	854e                	mv	a0,s3
ffffffffc0204c52:	b54ff0ef          	jal	ra,ffffffffc0203fa6 <put_pgdir>
            mm_destroy(mm); //把进程当前占用的内存释放，之后重新分配内存
ffffffffc0204c56:	854e                	mv	a0,s3
ffffffffc0204c58:	c6ffe0ef          	jal	ra,ffffffffc02038c6 <mm_destroy>
ffffffffc0204c5c:	b31d                	j	ffffffffc0204982 <do_execve+0x92>
            vm_flags |= VM_WRITE;
ffffffffc0204c5e:	0026e693          	ori	a3,a3,2
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204c62:	fb95                	bnez	a5,ffffffffc0204b96 <do_execve+0x2a6>
            perm |= (PTE_W | PTE_R);
ffffffffc0204c64:	4d5d                	li	s10,23
ffffffffc0204c66:	bf35                	j	ffffffffc0204ba2 <do_execve+0x2b2>
        end = ph->p_va + ph->p_memsz;
ffffffffc0204c68:	0109b683          	ld	a3,16(s3)
ffffffffc0204c6c:	0289b903          	ld	s2,40(s3)
ffffffffc0204c70:	9936                	add	s2,s2,a3
        if (start < la)
ffffffffc0204c72:	075bfd63          	bgeu	s7,s5,ffffffffc0204cec <do_execve+0x3fc>
            if (start == end)
ffffffffc0204c76:	db790de3          	beq	s2,s7,ffffffffc0204a30 <do_execve+0x140>
            off = start + PGSIZE - la, size = PGSIZE - off;
ffffffffc0204c7a:	6785                	lui	a5,0x1
ffffffffc0204c7c:	00fb8533          	add	a0,s7,a5
ffffffffc0204c80:	41550533          	sub	a0,a0,s5
                size -= la - end;
ffffffffc0204c84:	41790a33          	sub	s4,s2,s7
            if (end < la)
ffffffffc0204c88:	0b597d63          	bgeu	s2,s5,ffffffffc0204d42 <do_execve+0x452>
    return page - pages + nbase;
ffffffffc0204c8c:	000cb683          	ld	a3,0(s9)
ffffffffc0204c90:	67c2                	ld	a5,16(sp)
    return KADDR(page2pa(page));
ffffffffc0204c92:	000c3603          	ld	a2,0(s8)
    return page - pages + nbase;
ffffffffc0204c96:	40d406b3          	sub	a3,s0,a3
ffffffffc0204c9a:	8699                	srai	a3,a3,0x6
ffffffffc0204c9c:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0204c9e:	67e2                	ld	a5,24(sp)
ffffffffc0204ca0:	00f6f5b3          	and	a1,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0204ca4:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204ca6:	0ac5f963          	bgeu	a1,a2,ffffffffc0204d58 <do_execve+0x468>
ffffffffc0204caa:	000b3803          	ld	a6,0(s6)
            memset(page2kva(page) + off, 0, size);
ffffffffc0204cae:	8652                	mv	a2,s4
ffffffffc0204cb0:	4581                	li	a1,0
ffffffffc0204cb2:	96c2                	add	a3,a3,a6
ffffffffc0204cb4:	9536                	add	a0,a0,a3
ffffffffc0204cb6:	2cb000ef          	jal	ra,ffffffffc0205780 <memset>
            start += size;
ffffffffc0204cba:	017a0733          	add	a4,s4,s7
            assert((end < la && start == end) || (end >= la && start == la));
ffffffffc0204cbe:	03597463          	bgeu	s2,s5,ffffffffc0204ce6 <do_execve+0x3f6>
ffffffffc0204cc2:	d6e907e3          	beq	s2,a4,ffffffffc0204a30 <do_execve+0x140>
ffffffffc0204cc6:	00002697          	auipc	a3,0x2
ffffffffc0204cca:	5ca68693          	addi	a3,a3,1482 # ffffffffc0207290 <default_pmm_manager+0xc60>
ffffffffc0204cce:	00001617          	auipc	a2,0x1
ffffffffc0204cd2:	5b260613          	addi	a2,a2,1458 # ffffffffc0206280 <commands+0x868>
ffffffffc0204cd6:	2dc00593          	li	a1,732
ffffffffc0204cda:	00002517          	auipc	a0,0x2
ffffffffc0204cde:	3c650513          	addi	a0,a0,966 # ffffffffc02070a0 <default_pmm_manager+0xa70>
ffffffffc0204ce2:	facfb0ef          	jal	ra,ffffffffc020048e <__panic>
ffffffffc0204ce6:	ff5710e3          	bne	a4,s5,ffffffffc0204cc6 <do_execve+0x3d6>
ffffffffc0204cea:	8bd6                	mv	s7,s5
        while (start < end)
ffffffffc0204cec:	d52bf2e3          	bgeu	s7,s2,ffffffffc0204a30 <do_execve+0x140>
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL)
ffffffffc0204cf0:	6c88                	ld	a0,24(s1)
ffffffffc0204cf2:	866a                	mv	a2,s10
ffffffffc0204cf4:	85d6                	mv	a1,s5
ffffffffc0204cf6:	9abfe0ef          	jal	ra,ffffffffc02036a0 <pgdir_alloc_page>
ffffffffc0204cfa:	842a                	mv	s0,a0
ffffffffc0204cfc:	dd05                	beqz	a0,ffffffffc0204c34 <do_execve+0x344>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0204cfe:	6785                	lui	a5,0x1
ffffffffc0204d00:	415b8533          	sub	a0,s7,s5
ffffffffc0204d04:	9abe                	add	s5,s5,a5
ffffffffc0204d06:	417a8633          	sub	a2,s5,s7
            if (end < la)
ffffffffc0204d0a:	01597463          	bgeu	s2,s5,ffffffffc0204d12 <do_execve+0x422>
                size -= la - end;
ffffffffc0204d0e:	41790633          	sub	a2,s2,s7
    return page - pages + nbase;
ffffffffc0204d12:	000cb683          	ld	a3,0(s9)
ffffffffc0204d16:	67c2                	ld	a5,16(sp)
    return KADDR(page2pa(page));
ffffffffc0204d18:	000c3583          	ld	a1,0(s8)
    return page - pages + nbase;
ffffffffc0204d1c:	40d406b3          	sub	a3,s0,a3
ffffffffc0204d20:	8699                	srai	a3,a3,0x6
ffffffffc0204d22:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0204d24:	67e2                	ld	a5,24(sp)
ffffffffc0204d26:	00f6f833          	and	a6,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0204d2a:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204d2c:	02b87663          	bgeu	a6,a1,ffffffffc0204d58 <do_execve+0x468>
ffffffffc0204d30:	000b3803          	ld	a6,0(s6)
            memset(page2kva(page) + off, 0, size);
ffffffffc0204d34:	4581                	li	a1,0
            start += size;
ffffffffc0204d36:	9bb2                	add	s7,s7,a2
ffffffffc0204d38:	96c2                	add	a3,a3,a6
            memset(page2kva(page) + off, 0, size);
ffffffffc0204d3a:	9536                	add	a0,a0,a3
ffffffffc0204d3c:	245000ef          	jal	ra,ffffffffc0205780 <memset>
ffffffffc0204d40:	b775                	j	ffffffffc0204cec <do_execve+0x3fc>
            off = start + PGSIZE - la, size = PGSIZE - off;
ffffffffc0204d42:	417a8a33          	sub	s4,s5,s7
ffffffffc0204d46:	b799                	j	ffffffffc0204c8c <do_execve+0x39c>
        return -E_INVAL;
ffffffffc0204d48:	5a75                	li	s4,-3
ffffffffc0204d4a:	b3c1                	j	ffffffffc0204b0a <do_execve+0x21a>
        while (start < end)
ffffffffc0204d4c:	86de                	mv	a3,s7
ffffffffc0204d4e:	bf39                	j	ffffffffc0204c6c <do_execve+0x37c>
    int ret = -E_NO_MEM;
ffffffffc0204d50:	5a71                	li	s4,-4
ffffffffc0204d52:	bdc5                	j	ffffffffc0204c42 <do_execve+0x352>
            ret = -E_INVAL_ELF;
ffffffffc0204d54:	5a61                	li	s4,-8
ffffffffc0204d56:	b5c5                	j	ffffffffc0204c36 <do_execve+0x346>
ffffffffc0204d58:	00002617          	auipc	a2,0x2
ffffffffc0204d5c:	91060613          	addi	a2,a2,-1776 # ffffffffc0206668 <default_pmm_manager+0x38>
ffffffffc0204d60:	07100593          	li	a1,113
ffffffffc0204d64:	00002517          	auipc	a0,0x2
ffffffffc0204d68:	92c50513          	addi	a0,a0,-1748 # ffffffffc0206690 <default_pmm_manager+0x60>
ffffffffc0204d6c:	f22fb0ef          	jal	ra,ffffffffc020048e <__panic>
    current->pgdir = PADDR(mm->pgdir);
ffffffffc0204d70:	00002617          	auipc	a2,0x2
ffffffffc0204d74:	9a060613          	addi	a2,a2,-1632 # ffffffffc0206710 <default_pmm_manager+0xe0>
ffffffffc0204d78:	2fb00593          	li	a1,763
ffffffffc0204d7c:	00002517          	auipc	a0,0x2
ffffffffc0204d80:	32450513          	addi	a0,a0,804 # ffffffffc02070a0 <default_pmm_manager+0xa70>
ffffffffc0204d84:	f0afb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 4 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204d88:	00002697          	auipc	a3,0x2
ffffffffc0204d8c:	62068693          	addi	a3,a3,1568 # ffffffffc02073a8 <default_pmm_manager+0xd78>
ffffffffc0204d90:	00001617          	auipc	a2,0x1
ffffffffc0204d94:	4f060613          	addi	a2,a2,1264 # ffffffffc0206280 <commands+0x868>
ffffffffc0204d98:	2f600593          	li	a1,758
ffffffffc0204d9c:	00002517          	auipc	a0,0x2
ffffffffc0204da0:	30450513          	addi	a0,a0,772 # ffffffffc02070a0 <default_pmm_manager+0xa70>
ffffffffc0204da4:	eeafb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 3 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204da8:	00002697          	auipc	a3,0x2
ffffffffc0204dac:	5b868693          	addi	a3,a3,1464 # ffffffffc0207360 <default_pmm_manager+0xd30>
ffffffffc0204db0:	00001617          	auipc	a2,0x1
ffffffffc0204db4:	4d060613          	addi	a2,a2,1232 # ffffffffc0206280 <commands+0x868>
ffffffffc0204db8:	2f500593          	li	a1,757
ffffffffc0204dbc:	00002517          	auipc	a0,0x2
ffffffffc0204dc0:	2e450513          	addi	a0,a0,740 # ffffffffc02070a0 <default_pmm_manager+0xa70>
ffffffffc0204dc4:	ecafb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 2 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204dc8:	00002697          	auipc	a3,0x2
ffffffffc0204dcc:	55068693          	addi	a3,a3,1360 # ffffffffc0207318 <default_pmm_manager+0xce8>
ffffffffc0204dd0:	00001617          	auipc	a2,0x1
ffffffffc0204dd4:	4b060613          	addi	a2,a2,1200 # ffffffffc0206280 <commands+0x868>
ffffffffc0204dd8:	2f400593          	li	a1,756
ffffffffc0204ddc:	00002517          	auipc	a0,0x2
ffffffffc0204de0:	2c450513          	addi	a0,a0,708 # ffffffffc02070a0 <default_pmm_manager+0xa70>
ffffffffc0204de4:	eaafb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - PGSIZE, PTE_USER) != NULL);
ffffffffc0204de8:	00002697          	auipc	a3,0x2
ffffffffc0204dec:	4e868693          	addi	a3,a3,1256 # ffffffffc02072d0 <default_pmm_manager+0xca0>
ffffffffc0204df0:	00001617          	auipc	a2,0x1
ffffffffc0204df4:	49060613          	addi	a2,a2,1168 # ffffffffc0206280 <commands+0x868>
ffffffffc0204df8:	2f300593          	li	a1,755
ffffffffc0204dfc:	00002517          	auipc	a0,0x2
ffffffffc0204e00:	2a450513          	addi	a0,a0,676 # ffffffffc02070a0 <default_pmm_manager+0xa70>
ffffffffc0204e04:	e8afb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0204e08 <do_yield>:
    current->need_resched = 1;
ffffffffc0204e08:	000a6797          	auipc	a5,0xa6
ffffffffc0204e0c:	af07b783          	ld	a5,-1296(a5) # ffffffffc02aa8f8 <current>
ffffffffc0204e10:	4705                	li	a4,1
ffffffffc0204e12:	ef98                	sd	a4,24(a5)
}
ffffffffc0204e14:	4501                	li	a0,0
ffffffffc0204e16:	8082                	ret

ffffffffc0204e18 <do_wait>:
{
ffffffffc0204e18:	1101                	addi	sp,sp,-32
ffffffffc0204e1a:	e822                	sd	s0,16(sp)
ffffffffc0204e1c:	e426                	sd	s1,8(sp)
ffffffffc0204e1e:	ec06                	sd	ra,24(sp)
ffffffffc0204e20:	842e                	mv	s0,a1
ffffffffc0204e22:	84aa                	mv	s1,a0
    if (code_store != NULL)
ffffffffc0204e24:	c999                	beqz	a1,ffffffffc0204e3a <do_wait+0x22>
    struct mm_struct *mm = current->mm;
ffffffffc0204e26:	000a6797          	auipc	a5,0xa6
ffffffffc0204e2a:	ad27b783          	ld	a5,-1326(a5) # ffffffffc02aa8f8 <current>
        if (!user_mem_check(mm, (uintptr_t)code_store, sizeof(int), 1))
ffffffffc0204e2e:	7788                	ld	a0,40(a5)
ffffffffc0204e30:	4685                	li	a3,1
ffffffffc0204e32:	4611                	li	a2,4
ffffffffc0204e34:	fc9fe0ef          	jal	ra,ffffffffc0203dfc <user_mem_check>
ffffffffc0204e38:	c909                	beqz	a0,ffffffffc0204e4a <do_wait+0x32>
ffffffffc0204e3a:	85a2                	mv	a1,s0
}
ffffffffc0204e3c:	6442                	ld	s0,16(sp)
ffffffffc0204e3e:	60e2                	ld	ra,24(sp)
ffffffffc0204e40:	8526                	mv	a0,s1
ffffffffc0204e42:	64a2                	ld	s1,8(sp)
ffffffffc0204e44:	6105                	addi	sp,sp,32
ffffffffc0204e46:	fb4ff06f          	j	ffffffffc02045fa <do_wait.part.0>
ffffffffc0204e4a:	60e2                	ld	ra,24(sp)
ffffffffc0204e4c:	6442                	ld	s0,16(sp)
ffffffffc0204e4e:	64a2                	ld	s1,8(sp)
ffffffffc0204e50:	5575                	li	a0,-3
ffffffffc0204e52:	6105                	addi	sp,sp,32
ffffffffc0204e54:	8082                	ret

ffffffffc0204e56 <do_kill>:
{
ffffffffc0204e56:	1141                	addi	sp,sp,-16
    if (0 < pid && pid < MAX_PID)
ffffffffc0204e58:	6789                	lui	a5,0x2
{
ffffffffc0204e5a:	e406                	sd	ra,8(sp)
ffffffffc0204e5c:	e022                	sd	s0,0(sp)
    if (0 < pid && pid < MAX_PID)
ffffffffc0204e5e:	fff5071b          	addiw	a4,a0,-1
ffffffffc0204e62:	17f9                	addi	a5,a5,-2
ffffffffc0204e64:	02e7e963          	bltu	a5,a4,ffffffffc0204e96 <do_kill+0x40>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204e68:	842a                	mv	s0,a0
ffffffffc0204e6a:	45a9                	li	a1,10
ffffffffc0204e6c:	2501                	sext.w	a0,a0
ffffffffc0204e6e:	46c000ef          	jal	ra,ffffffffc02052da <hash32>
ffffffffc0204e72:	02051793          	slli	a5,a0,0x20
ffffffffc0204e76:	01c7d513          	srli	a0,a5,0x1c
ffffffffc0204e7a:	000a2797          	auipc	a5,0xa2
ffffffffc0204e7e:	a0e78793          	addi	a5,a5,-1522 # ffffffffc02a6888 <hash_list>
ffffffffc0204e82:	953e                	add	a0,a0,a5
ffffffffc0204e84:	87aa                	mv	a5,a0
        while ((le = list_next(le)) != list)
ffffffffc0204e86:	a029                	j	ffffffffc0204e90 <do_kill+0x3a>
            if (proc->pid == pid)
ffffffffc0204e88:	f2c7a703          	lw	a4,-212(a5)
ffffffffc0204e8c:	00870b63          	beq	a4,s0,ffffffffc0204ea2 <do_kill+0x4c>
ffffffffc0204e90:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc0204e92:	fef51be3          	bne	a0,a5,ffffffffc0204e88 <do_kill+0x32>
    return -E_INVAL;
ffffffffc0204e96:	5475                	li	s0,-3
}
ffffffffc0204e98:	60a2                	ld	ra,8(sp)
ffffffffc0204e9a:	8522                	mv	a0,s0
ffffffffc0204e9c:	6402                	ld	s0,0(sp)
ffffffffc0204e9e:	0141                	addi	sp,sp,16
ffffffffc0204ea0:	8082                	ret
        if (!(proc->flags & PF_EXITING))
ffffffffc0204ea2:	fd87a703          	lw	a4,-40(a5)
ffffffffc0204ea6:	00177693          	andi	a3,a4,1
ffffffffc0204eaa:	e295                	bnez	a3,ffffffffc0204ece <do_kill+0x78>
            if (proc->wait_state & WT_INTERRUPTED)
ffffffffc0204eac:	4bd4                	lw	a3,20(a5)
            proc->flags |= PF_EXITING;
ffffffffc0204eae:	00176713          	ori	a4,a4,1
ffffffffc0204eb2:	fce7ac23          	sw	a4,-40(a5)
            return 0;
ffffffffc0204eb6:	4401                	li	s0,0
            if (proc->wait_state & WT_INTERRUPTED)
ffffffffc0204eb8:	fe06d0e3          	bgez	a3,ffffffffc0204e98 <do_kill+0x42>
                wakeup_proc(proc);
ffffffffc0204ebc:	f2878513          	addi	a0,a5,-216
ffffffffc0204ec0:	22e000ef          	jal	ra,ffffffffc02050ee <wakeup_proc>
}
ffffffffc0204ec4:	60a2                	ld	ra,8(sp)
ffffffffc0204ec6:	8522                	mv	a0,s0
ffffffffc0204ec8:	6402                	ld	s0,0(sp)
ffffffffc0204eca:	0141                	addi	sp,sp,16
ffffffffc0204ecc:	8082                	ret
        return -E_KILLED;
ffffffffc0204ece:	545d                	li	s0,-9
ffffffffc0204ed0:	b7e1                	j	ffffffffc0204e98 <do_kill+0x42>

ffffffffc0204ed2 <proc_init>:

// proc_init - set up the first kernel thread idleproc "idle" by itself and
//           - create the second kernel thread init_main
void proc_init(void)
{
ffffffffc0204ed2:	1101                	addi	sp,sp,-32
ffffffffc0204ed4:	e426                	sd	s1,8(sp)
    elm->prev = elm->next = elm;
ffffffffc0204ed6:	000a6797          	auipc	a5,0xa6
ffffffffc0204eda:	9b278793          	addi	a5,a5,-1614 # ffffffffc02aa888 <proc_list>
ffffffffc0204ede:	ec06                	sd	ra,24(sp)
ffffffffc0204ee0:	e822                	sd	s0,16(sp)
ffffffffc0204ee2:	e04a                	sd	s2,0(sp)
ffffffffc0204ee4:	000a2497          	auipc	s1,0xa2
ffffffffc0204ee8:	9a448493          	addi	s1,s1,-1628 # ffffffffc02a6888 <hash_list>
ffffffffc0204eec:	e79c                	sd	a5,8(a5)
ffffffffc0204eee:	e39c                	sd	a5,0(a5)
    int i;

    list_init(&proc_list);
    for (i = 0; i < HASH_LIST_SIZE; i++)
ffffffffc0204ef0:	000a6717          	auipc	a4,0xa6
ffffffffc0204ef4:	99870713          	addi	a4,a4,-1640 # ffffffffc02aa888 <proc_list>
ffffffffc0204ef8:	87a6                	mv	a5,s1
ffffffffc0204efa:	e79c                	sd	a5,8(a5)
ffffffffc0204efc:	e39c                	sd	a5,0(a5)
ffffffffc0204efe:	07c1                	addi	a5,a5,16
ffffffffc0204f00:	fef71de3          	bne	a4,a5,ffffffffc0204efa <proc_init+0x28>
    {
        list_init(hash_list + i);
    }

    if ((idleproc = alloc_proc()) == NULL)
ffffffffc0204f04:	f95fe0ef          	jal	ra,ffffffffc0203e98 <alloc_proc>
ffffffffc0204f08:	000a6917          	auipc	s2,0xa6
ffffffffc0204f0c:	9f890913          	addi	s2,s2,-1544 # ffffffffc02aa900 <idleproc>
ffffffffc0204f10:	00a93023          	sd	a0,0(s2)
ffffffffc0204f14:	0e050f63          	beqz	a0,ffffffffc0205012 <proc_init+0x140>
    {
        panic("cannot alloc idleproc.\n");
    }

    idleproc->pid = 0;
    idleproc->state = PROC_RUNNABLE;
ffffffffc0204f18:	4789                	li	a5,2
ffffffffc0204f1a:	e11c                	sd	a5,0(a0)
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc0204f1c:	00003797          	auipc	a5,0x3
ffffffffc0204f20:	0e478793          	addi	a5,a5,228 # ffffffffc0208000 <bootstack>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204f24:	0b450413          	addi	s0,a0,180
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc0204f28:	e91c                	sd	a5,16(a0)
    idleproc->need_resched = 1;
ffffffffc0204f2a:	4785                	li	a5,1
ffffffffc0204f2c:	ed1c                	sd	a5,24(a0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204f2e:	4641                	li	a2,16
ffffffffc0204f30:	4581                	li	a1,0
ffffffffc0204f32:	8522                	mv	a0,s0
ffffffffc0204f34:	04d000ef          	jal	ra,ffffffffc0205780 <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0204f38:	463d                	li	a2,15
ffffffffc0204f3a:	00002597          	auipc	a1,0x2
ffffffffc0204f3e:	4ce58593          	addi	a1,a1,1230 # ffffffffc0207408 <default_pmm_manager+0xdd8>
ffffffffc0204f42:	8522                	mv	a0,s0
ffffffffc0204f44:	04f000ef          	jal	ra,ffffffffc0205792 <memcpy>
    set_proc_name(idleproc, "idle");
    nr_process++;
ffffffffc0204f48:	000a6717          	auipc	a4,0xa6
ffffffffc0204f4c:	9c870713          	addi	a4,a4,-1592 # ffffffffc02aa910 <nr_process>
ffffffffc0204f50:	431c                	lw	a5,0(a4)

    current = idleproc;
ffffffffc0204f52:	00093683          	ld	a3,0(s2)

    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0204f56:	4601                	li	a2,0
    nr_process++;
ffffffffc0204f58:	2785                	addiw	a5,a5,1
    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0204f5a:	4581                	li	a1,0
ffffffffc0204f5c:	00000517          	auipc	a0,0x0
ffffffffc0204f60:	87050513          	addi	a0,a0,-1936 # ffffffffc02047cc <init_main>
    nr_process++;
ffffffffc0204f64:	c31c                	sw	a5,0(a4)
    current = idleproc;
ffffffffc0204f66:	000a6797          	auipc	a5,0xa6
ffffffffc0204f6a:	98d7b923          	sd	a3,-1646(a5) # ffffffffc02aa8f8 <current>
    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0204f6e:	cf2ff0ef          	jal	ra,ffffffffc0204460 <kernel_thread>
ffffffffc0204f72:	842a                	mv	s0,a0
    if (pid <= 0)
ffffffffc0204f74:	08a05363          	blez	a0,ffffffffc0204ffa <proc_init+0x128>
    if (0 < pid && pid < MAX_PID)
ffffffffc0204f78:	6789                	lui	a5,0x2
ffffffffc0204f7a:	fff5071b          	addiw	a4,a0,-1
ffffffffc0204f7e:	17f9                	addi	a5,a5,-2
ffffffffc0204f80:	2501                	sext.w	a0,a0
ffffffffc0204f82:	02e7e363          	bltu	a5,a4,ffffffffc0204fa8 <proc_init+0xd6>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204f86:	45a9                	li	a1,10
ffffffffc0204f88:	352000ef          	jal	ra,ffffffffc02052da <hash32>
ffffffffc0204f8c:	02051793          	slli	a5,a0,0x20
ffffffffc0204f90:	01c7d693          	srli	a3,a5,0x1c
ffffffffc0204f94:	96a6                	add	a3,a3,s1
ffffffffc0204f96:	87b6                	mv	a5,a3
        while ((le = list_next(le)) != list)
ffffffffc0204f98:	a029                	j	ffffffffc0204fa2 <proc_init+0xd0>
            if (proc->pid == pid)
ffffffffc0204f9a:	f2c7a703          	lw	a4,-212(a5) # 1f2c <_binary_obj___user_faultread_out_size-0x7c9c>
ffffffffc0204f9e:	04870b63          	beq	a4,s0,ffffffffc0204ff4 <proc_init+0x122>
    return listelm->next;
ffffffffc0204fa2:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc0204fa4:	fef69be3          	bne	a3,a5,ffffffffc0204f9a <proc_init+0xc8>
    return NULL;
ffffffffc0204fa8:	4781                	li	a5,0
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204faa:	0b478493          	addi	s1,a5,180
ffffffffc0204fae:	4641                	li	a2,16
ffffffffc0204fb0:	4581                	li	a1,0
    {
        panic("create init_main failed.\n");
    }

    initproc = find_proc(pid);
ffffffffc0204fb2:	000a6417          	auipc	s0,0xa6
ffffffffc0204fb6:	95640413          	addi	s0,s0,-1706 # ffffffffc02aa908 <initproc>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204fba:	8526                	mv	a0,s1
    initproc = find_proc(pid);
ffffffffc0204fbc:	e01c                	sd	a5,0(s0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204fbe:	7c2000ef          	jal	ra,ffffffffc0205780 <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0204fc2:	463d                	li	a2,15
ffffffffc0204fc4:	00002597          	auipc	a1,0x2
ffffffffc0204fc8:	46c58593          	addi	a1,a1,1132 # ffffffffc0207430 <default_pmm_manager+0xe00>
ffffffffc0204fcc:	8526                	mv	a0,s1
ffffffffc0204fce:	7c4000ef          	jal	ra,ffffffffc0205792 <memcpy>
    set_proc_name(initproc, "init");

    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc0204fd2:	00093783          	ld	a5,0(s2)
ffffffffc0204fd6:	cbb5                	beqz	a5,ffffffffc020504a <proc_init+0x178>
ffffffffc0204fd8:	43dc                	lw	a5,4(a5)
ffffffffc0204fda:	eba5                	bnez	a5,ffffffffc020504a <proc_init+0x178>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc0204fdc:	601c                	ld	a5,0(s0)
ffffffffc0204fde:	c7b1                	beqz	a5,ffffffffc020502a <proc_init+0x158>
ffffffffc0204fe0:	43d8                	lw	a4,4(a5)
ffffffffc0204fe2:	4785                	li	a5,1
ffffffffc0204fe4:	04f71363          	bne	a4,a5,ffffffffc020502a <proc_init+0x158>
}
ffffffffc0204fe8:	60e2                	ld	ra,24(sp)
ffffffffc0204fea:	6442                	ld	s0,16(sp)
ffffffffc0204fec:	64a2                	ld	s1,8(sp)
ffffffffc0204fee:	6902                	ld	s2,0(sp)
ffffffffc0204ff0:	6105                	addi	sp,sp,32
ffffffffc0204ff2:	8082                	ret
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc0204ff4:	f2878793          	addi	a5,a5,-216
ffffffffc0204ff8:	bf4d                	j	ffffffffc0204faa <proc_init+0xd8>
        panic("create init_main failed.\n");
ffffffffc0204ffa:	00002617          	auipc	a2,0x2
ffffffffc0204ffe:	41660613          	addi	a2,a2,1046 # ffffffffc0207410 <default_pmm_manager+0xde0>
ffffffffc0205002:	42500593          	li	a1,1061
ffffffffc0205006:	00002517          	auipc	a0,0x2
ffffffffc020500a:	09a50513          	addi	a0,a0,154 # ffffffffc02070a0 <default_pmm_manager+0xa70>
ffffffffc020500e:	c80fb0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("cannot alloc idleproc.\n");
ffffffffc0205012:	00002617          	auipc	a2,0x2
ffffffffc0205016:	3de60613          	addi	a2,a2,990 # ffffffffc02073f0 <default_pmm_manager+0xdc0>
ffffffffc020501a:	41600593          	li	a1,1046
ffffffffc020501e:	00002517          	auipc	a0,0x2
ffffffffc0205022:	08250513          	addi	a0,a0,130 # ffffffffc02070a0 <default_pmm_manager+0xa70>
ffffffffc0205026:	c68fb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc020502a:	00002697          	auipc	a3,0x2
ffffffffc020502e:	43668693          	addi	a3,a3,1078 # ffffffffc0207460 <default_pmm_manager+0xe30>
ffffffffc0205032:	00001617          	auipc	a2,0x1
ffffffffc0205036:	24e60613          	addi	a2,a2,590 # ffffffffc0206280 <commands+0x868>
ffffffffc020503a:	42c00593          	li	a1,1068
ffffffffc020503e:	00002517          	auipc	a0,0x2
ffffffffc0205042:	06250513          	addi	a0,a0,98 # ffffffffc02070a0 <default_pmm_manager+0xa70>
ffffffffc0205046:	c48fb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc020504a:	00002697          	auipc	a3,0x2
ffffffffc020504e:	3ee68693          	addi	a3,a3,1006 # ffffffffc0207438 <default_pmm_manager+0xe08>
ffffffffc0205052:	00001617          	auipc	a2,0x1
ffffffffc0205056:	22e60613          	addi	a2,a2,558 # ffffffffc0206280 <commands+0x868>
ffffffffc020505a:	42b00593          	li	a1,1067
ffffffffc020505e:	00002517          	auipc	a0,0x2
ffffffffc0205062:	04250513          	addi	a0,a0,66 # ffffffffc02070a0 <default_pmm_manager+0xa70>
ffffffffc0205066:	c28fb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc020506a <cpu_idle>:

// cpu_idle - at the end of kern_init, the first kernel thread idleproc will do below works
void cpu_idle(void)
{
ffffffffc020506a:	1141                	addi	sp,sp,-16
ffffffffc020506c:	e022                	sd	s0,0(sp)
ffffffffc020506e:	e406                	sd	ra,8(sp)
ffffffffc0205070:	000a6417          	auipc	s0,0xa6
ffffffffc0205074:	88840413          	addi	s0,s0,-1912 # ffffffffc02aa8f8 <current>
    while (1)
    {
        if (current->need_resched)
ffffffffc0205078:	6018                	ld	a4,0(s0)
ffffffffc020507a:	6f1c                	ld	a5,24(a4)
ffffffffc020507c:	dffd                	beqz	a5,ffffffffc020507a <cpu_idle+0x10>
        {
            schedule();
ffffffffc020507e:	0f0000ef          	jal	ra,ffffffffc020516e <schedule>
ffffffffc0205082:	bfdd                	j	ffffffffc0205078 <cpu_idle+0xe>

ffffffffc0205084 <switch_to>:
.text
# void switch_to(struct proc_struct* from, struct proc_struct* to)
.globl switch_to
switch_to:
    # save from's registers
    STORE ra, 0*REGBYTES(a0)
ffffffffc0205084:	00153023          	sd	ra,0(a0)
    STORE sp, 1*REGBYTES(a0)
ffffffffc0205088:	00253423          	sd	sp,8(a0)
    STORE s0, 2*REGBYTES(a0)
ffffffffc020508c:	e900                	sd	s0,16(a0)
    STORE s1, 3*REGBYTES(a0)
ffffffffc020508e:	ed04                	sd	s1,24(a0)
    STORE s2, 4*REGBYTES(a0)
ffffffffc0205090:	03253023          	sd	s2,32(a0)
    STORE s3, 5*REGBYTES(a0)
ffffffffc0205094:	03353423          	sd	s3,40(a0)
    STORE s4, 6*REGBYTES(a0)
ffffffffc0205098:	03453823          	sd	s4,48(a0)
    STORE s5, 7*REGBYTES(a0)
ffffffffc020509c:	03553c23          	sd	s5,56(a0)
    STORE s6, 8*REGBYTES(a0)
ffffffffc02050a0:	05653023          	sd	s6,64(a0)
    STORE s7, 9*REGBYTES(a0)
ffffffffc02050a4:	05753423          	sd	s7,72(a0)
    STORE s8, 10*REGBYTES(a0)
ffffffffc02050a8:	05853823          	sd	s8,80(a0)
    STORE s9, 11*REGBYTES(a0)
ffffffffc02050ac:	05953c23          	sd	s9,88(a0)
    STORE s10, 12*REGBYTES(a0)
ffffffffc02050b0:	07a53023          	sd	s10,96(a0)
    STORE s11, 13*REGBYTES(a0)
ffffffffc02050b4:	07b53423          	sd	s11,104(a0)

    # restore to's registers
    LOAD ra, 0*REGBYTES(a1)
ffffffffc02050b8:	0005b083          	ld	ra,0(a1)
    LOAD sp, 1*REGBYTES(a1)
ffffffffc02050bc:	0085b103          	ld	sp,8(a1)
    LOAD s0, 2*REGBYTES(a1)
ffffffffc02050c0:	6980                	ld	s0,16(a1)
    LOAD s1, 3*REGBYTES(a1)
ffffffffc02050c2:	6d84                	ld	s1,24(a1)
    LOAD s2, 4*REGBYTES(a1)
ffffffffc02050c4:	0205b903          	ld	s2,32(a1)
    LOAD s3, 5*REGBYTES(a1)
ffffffffc02050c8:	0285b983          	ld	s3,40(a1)
    LOAD s4, 6*REGBYTES(a1)
ffffffffc02050cc:	0305ba03          	ld	s4,48(a1)
    LOAD s5, 7*REGBYTES(a1)
ffffffffc02050d0:	0385ba83          	ld	s5,56(a1)
    LOAD s6, 8*REGBYTES(a1)
ffffffffc02050d4:	0405bb03          	ld	s6,64(a1)
    LOAD s7, 9*REGBYTES(a1)
ffffffffc02050d8:	0485bb83          	ld	s7,72(a1)
    LOAD s8, 10*REGBYTES(a1)
ffffffffc02050dc:	0505bc03          	ld	s8,80(a1)
    LOAD s9, 11*REGBYTES(a1)
ffffffffc02050e0:	0585bc83          	ld	s9,88(a1)
    LOAD s10, 12*REGBYTES(a1)
ffffffffc02050e4:	0605bd03          	ld	s10,96(a1)
    LOAD s11, 13*REGBYTES(a1)
ffffffffc02050e8:	0685bd83          	ld	s11,104(a1)

    ret
ffffffffc02050ec:	8082                	ret

ffffffffc02050ee <wakeup_proc>:
#include <sched.h>
#include <assert.h>

void wakeup_proc(struct proc_struct *proc)
{
    assert(proc->state != PROC_ZOMBIE);
ffffffffc02050ee:	4118                	lw	a4,0(a0)
{
ffffffffc02050f0:	1101                	addi	sp,sp,-32
ffffffffc02050f2:	ec06                	sd	ra,24(sp)
ffffffffc02050f4:	e822                	sd	s0,16(sp)
ffffffffc02050f6:	e426                	sd	s1,8(sp)
    assert(proc->state != PROC_ZOMBIE);
ffffffffc02050f8:	478d                	li	a5,3
ffffffffc02050fa:	04f70b63          	beq	a4,a5,ffffffffc0205150 <wakeup_proc+0x62>
ffffffffc02050fe:	842a                	mv	s0,a0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0205100:	100027f3          	csrr	a5,sstatus
ffffffffc0205104:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0205106:	4481                	li	s1,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0205108:	ef9d                	bnez	a5,ffffffffc0205146 <wakeup_proc+0x58>
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        if (proc->state != PROC_RUNNABLE)
ffffffffc020510a:	4789                	li	a5,2
ffffffffc020510c:	02f70163          	beq	a4,a5,ffffffffc020512e <wakeup_proc+0x40>
        {
            proc->state = PROC_RUNNABLE;
ffffffffc0205110:	c01c                	sw	a5,0(s0)
            proc->wait_state = 0;
ffffffffc0205112:	0e042623          	sw	zero,236(s0)
    if (flag)
ffffffffc0205116:	e491                	bnez	s1,ffffffffc0205122 <wakeup_proc+0x34>
        {
            warn("wakeup runnable process.\n");
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc0205118:	60e2                	ld	ra,24(sp)
ffffffffc020511a:	6442                	ld	s0,16(sp)
ffffffffc020511c:	64a2                	ld	s1,8(sp)
ffffffffc020511e:	6105                	addi	sp,sp,32
ffffffffc0205120:	8082                	ret
ffffffffc0205122:	6442                	ld	s0,16(sp)
ffffffffc0205124:	60e2                	ld	ra,24(sp)
ffffffffc0205126:	64a2                	ld	s1,8(sp)
ffffffffc0205128:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc020512a:	885fb06f          	j	ffffffffc02009ae <intr_enable>
            warn("wakeup runnable process.\n");
ffffffffc020512e:	00002617          	auipc	a2,0x2
ffffffffc0205132:	39260613          	addi	a2,a2,914 # ffffffffc02074c0 <default_pmm_manager+0xe90>
ffffffffc0205136:	45d1                	li	a1,20
ffffffffc0205138:	00002517          	auipc	a0,0x2
ffffffffc020513c:	37050513          	addi	a0,a0,880 # ffffffffc02074a8 <default_pmm_manager+0xe78>
ffffffffc0205140:	bb6fb0ef          	jal	ra,ffffffffc02004f6 <__warn>
ffffffffc0205144:	bfc9                	j	ffffffffc0205116 <wakeup_proc+0x28>
        intr_disable();
ffffffffc0205146:	86ffb0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        if (proc->state != PROC_RUNNABLE)
ffffffffc020514a:	4018                	lw	a4,0(s0)
        return 1;
ffffffffc020514c:	4485                	li	s1,1
ffffffffc020514e:	bf75                	j	ffffffffc020510a <wakeup_proc+0x1c>
    assert(proc->state != PROC_ZOMBIE);
ffffffffc0205150:	00002697          	auipc	a3,0x2
ffffffffc0205154:	33868693          	addi	a3,a3,824 # ffffffffc0207488 <default_pmm_manager+0xe58>
ffffffffc0205158:	00001617          	auipc	a2,0x1
ffffffffc020515c:	12860613          	addi	a2,a2,296 # ffffffffc0206280 <commands+0x868>
ffffffffc0205160:	45a5                	li	a1,9
ffffffffc0205162:	00002517          	auipc	a0,0x2
ffffffffc0205166:	34650513          	addi	a0,a0,838 # ffffffffc02074a8 <default_pmm_manager+0xe78>
ffffffffc020516a:	b24fb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc020516e <schedule>:

void schedule(void)
{
ffffffffc020516e:	1141                	addi	sp,sp,-16
ffffffffc0205170:	e406                	sd	ra,8(sp)
ffffffffc0205172:	e022                	sd	s0,0(sp)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0205174:	100027f3          	csrr	a5,sstatus
ffffffffc0205178:	8b89                	andi	a5,a5,2
ffffffffc020517a:	4401                	li	s0,0
ffffffffc020517c:	efbd                	bnez	a5,ffffffffc02051fa <schedule+0x8c>
    bool intr_flag;
    list_entry_t *le, *last;
    struct proc_struct *next = NULL;
    local_intr_save(intr_flag);
    {
        current->need_resched = 0;
ffffffffc020517e:	000a5897          	auipc	a7,0xa5
ffffffffc0205182:	77a8b883          	ld	a7,1914(a7) # ffffffffc02aa8f8 <current>
ffffffffc0205186:	0008bc23          	sd	zero,24(a7)
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc020518a:	000a5517          	auipc	a0,0xa5
ffffffffc020518e:	77653503          	ld	a0,1910(a0) # ffffffffc02aa900 <idleproc>
ffffffffc0205192:	04a88e63          	beq	a7,a0,ffffffffc02051ee <schedule+0x80>
ffffffffc0205196:	0c888693          	addi	a3,a7,200
ffffffffc020519a:	000a5617          	auipc	a2,0xa5
ffffffffc020519e:	6ee60613          	addi	a2,a2,1774 # ffffffffc02aa888 <proc_list>
        le = last;
ffffffffc02051a2:	87b6                	mv	a5,a3
    struct proc_struct *next = NULL;
ffffffffc02051a4:	4581                	li	a1,0
        do
        {
            if ((le = list_next(le)) != &proc_list)
            {
                next = le2proc(le, list_link);
                if (next->state == PROC_RUNNABLE)
ffffffffc02051a6:	4809                	li	a6,2
ffffffffc02051a8:	679c                	ld	a5,8(a5)
            if ((le = list_next(le)) != &proc_list)
ffffffffc02051aa:	00c78863          	beq	a5,a2,ffffffffc02051ba <schedule+0x4c>
                if (next->state == PROC_RUNNABLE)
ffffffffc02051ae:	f387a703          	lw	a4,-200(a5)
                next = le2proc(le, list_link);
ffffffffc02051b2:	f3878593          	addi	a1,a5,-200
                if (next->state == PROC_RUNNABLE)
ffffffffc02051b6:	03070163          	beq	a4,a6,ffffffffc02051d8 <schedule+0x6a>
                {
                    break;
                }
            }
        } while (le != last);
ffffffffc02051ba:	fef697e3          	bne	a3,a5,ffffffffc02051a8 <schedule+0x3a>
        if (next == NULL || next->state != PROC_RUNNABLE)
ffffffffc02051be:	ed89                	bnez	a1,ffffffffc02051d8 <schedule+0x6a>
        {
            next = idleproc;
        }
        next->runs++;
ffffffffc02051c0:	451c                	lw	a5,8(a0)
ffffffffc02051c2:	2785                	addiw	a5,a5,1
ffffffffc02051c4:	c51c                	sw	a5,8(a0)
        if (next != current)
ffffffffc02051c6:	00a88463          	beq	a7,a0,ffffffffc02051ce <schedule+0x60>
        {
            proc_run(next);
ffffffffc02051ca:	e53fe0ef          	jal	ra,ffffffffc020401c <proc_run>
    if (flag)
ffffffffc02051ce:	e819                	bnez	s0,ffffffffc02051e4 <schedule+0x76>
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc02051d0:	60a2                	ld	ra,8(sp)
ffffffffc02051d2:	6402                	ld	s0,0(sp)
ffffffffc02051d4:	0141                	addi	sp,sp,16
ffffffffc02051d6:	8082                	ret
        if (next == NULL || next->state != PROC_RUNNABLE)
ffffffffc02051d8:	4198                	lw	a4,0(a1)
ffffffffc02051da:	4789                	li	a5,2
ffffffffc02051dc:	fef712e3          	bne	a4,a5,ffffffffc02051c0 <schedule+0x52>
ffffffffc02051e0:	852e                	mv	a0,a1
ffffffffc02051e2:	bff9                	j	ffffffffc02051c0 <schedule+0x52>
}
ffffffffc02051e4:	6402                	ld	s0,0(sp)
ffffffffc02051e6:	60a2                	ld	ra,8(sp)
ffffffffc02051e8:	0141                	addi	sp,sp,16
        intr_enable();
ffffffffc02051ea:	fc4fb06f          	j	ffffffffc02009ae <intr_enable>
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc02051ee:	000a5617          	auipc	a2,0xa5
ffffffffc02051f2:	69a60613          	addi	a2,a2,1690 # ffffffffc02aa888 <proc_list>
ffffffffc02051f6:	86b2                	mv	a3,a2
ffffffffc02051f8:	b76d                	j	ffffffffc02051a2 <schedule+0x34>
        intr_disable();
ffffffffc02051fa:	fbafb0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc02051fe:	4405                	li	s0,1
ffffffffc0205200:	bfbd                	j	ffffffffc020517e <schedule+0x10>

ffffffffc0205202 <sys_getpid>:
    return do_kill(pid);
}

static int
sys_getpid(uint64_t arg[]) {
    return current->pid;
ffffffffc0205202:	000a5797          	auipc	a5,0xa5
ffffffffc0205206:	6f67b783          	ld	a5,1782(a5) # ffffffffc02aa8f8 <current>
}
ffffffffc020520a:	43c8                	lw	a0,4(a5)
ffffffffc020520c:	8082                	ret

ffffffffc020520e <sys_pgdir>:

static int
sys_pgdir(uint64_t arg[]) {
    //print_pgdir();
    return 0;
}
ffffffffc020520e:	4501                	li	a0,0
ffffffffc0205210:	8082                	ret

ffffffffc0205212 <sys_putc>:
    cputchar(c);
ffffffffc0205212:	4108                	lw	a0,0(a0)
sys_putc(uint64_t arg[]) {
ffffffffc0205214:	1141                	addi	sp,sp,-16
ffffffffc0205216:	e406                	sd	ra,8(sp)
    cputchar(c);
ffffffffc0205218:	fb3fa0ef          	jal	ra,ffffffffc02001ca <cputchar>
}
ffffffffc020521c:	60a2                	ld	ra,8(sp)
ffffffffc020521e:	4501                	li	a0,0
ffffffffc0205220:	0141                	addi	sp,sp,16
ffffffffc0205222:	8082                	ret

ffffffffc0205224 <sys_kill>:
    return do_kill(pid);
ffffffffc0205224:	4108                	lw	a0,0(a0)
ffffffffc0205226:	c31ff06f          	j	ffffffffc0204e56 <do_kill>

ffffffffc020522a <sys_yield>:
    return do_yield();
ffffffffc020522a:	bdfff06f          	j	ffffffffc0204e08 <do_yield>

ffffffffc020522e <sys_exec>:
    return do_execve(name, len, binary, size);
ffffffffc020522e:	6d14                	ld	a3,24(a0)
ffffffffc0205230:	6910                	ld	a2,16(a0)
ffffffffc0205232:	650c                	ld	a1,8(a0)
ffffffffc0205234:	6108                	ld	a0,0(a0)
ffffffffc0205236:	ebaff06f          	j	ffffffffc02048f0 <do_execve>

ffffffffc020523a <sys_wait>:
    return do_wait(pid, store);
ffffffffc020523a:	650c                	ld	a1,8(a0)
ffffffffc020523c:	4108                	lw	a0,0(a0)
ffffffffc020523e:	bdbff06f          	j	ffffffffc0204e18 <do_wait>

ffffffffc0205242 <sys_fork>:
    struct trapframe *tf = current->tf;
ffffffffc0205242:	000a5797          	auipc	a5,0xa5
ffffffffc0205246:	6b67b783          	ld	a5,1718(a5) # ffffffffc02aa8f8 <current>
ffffffffc020524a:	73d0                	ld	a2,160(a5)
    return do_fork(0, stack, tf);
ffffffffc020524c:	4501                	li	a0,0
ffffffffc020524e:	6a0c                	ld	a1,16(a2)
ffffffffc0205250:	e37fe06f          	j	ffffffffc0204086 <do_fork>

ffffffffc0205254 <sys_exit>:
    return do_exit(error_code);
ffffffffc0205254:	4108                	lw	a0,0(a0)
ffffffffc0205256:	a5aff06f          	j	ffffffffc02044b0 <do_exit>

ffffffffc020525a <syscall>:
};

#define NUM_SYSCALLS        ((sizeof(syscalls)) / (sizeof(syscalls[0])))

void
syscall(void) {
ffffffffc020525a:	715d                	addi	sp,sp,-80
ffffffffc020525c:	fc26                	sd	s1,56(sp)
    struct trapframe *tf = current->tf;
ffffffffc020525e:	000a5497          	auipc	s1,0xa5
ffffffffc0205262:	69a48493          	addi	s1,s1,1690 # ffffffffc02aa8f8 <current>
ffffffffc0205266:	6098                	ld	a4,0(s1)
syscall(void) {
ffffffffc0205268:	e0a2                	sd	s0,64(sp)
ffffffffc020526a:	f84a                	sd	s2,48(sp)
    struct trapframe *tf = current->tf;
ffffffffc020526c:	7340                	ld	s0,160(a4)
syscall(void) {
ffffffffc020526e:	e486                	sd	ra,72(sp)
    uint64_t arg[5];
    int num = tf->gpr.a0;  //a0寄存器保存了系统调用编号
    if (num >= 0 && num < NUM_SYSCALLS) {  //防止syscalls[num]下标越界
ffffffffc0205270:	47fd                	li	a5,31
    int num = tf->gpr.a0;  //a0寄存器保存了系统调用编号
ffffffffc0205272:	05042903          	lw	s2,80(s0)
    if (num >= 0 && num < NUM_SYSCALLS) {  //防止syscalls[num]下标越界
ffffffffc0205276:	0327ee63          	bltu	a5,s2,ffffffffc02052b2 <syscall+0x58>
        if (syscalls[num] != NULL) {
ffffffffc020527a:	00391713          	slli	a4,s2,0x3
ffffffffc020527e:	00002797          	auipc	a5,0x2
ffffffffc0205282:	2aa78793          	addi	a5,a5,682 # ffffffffc0207528 <syscalls>
ffffffffc0205286:	97ba                	add	a5,a5,a4
ffffffffc0205288:	639c                	ld	a5,0(a5)
ffffffffc020528a:	c785                	beqz	a5,ffffffffc02052b2 <syscall+0x58>
            arg[0] = tf->gpr.a1;
ffffffffc020528c:	6c28                	ld	a0,88(s0)
            arg[1] = tf->gpr.a2;
ffffffffc020528e:	702c                	ld	a1,96(s0)
            arg[2] = tf->gpr.a3;
ffffffffc0205290:	7430                	ld	a2,104(s0)
            arg[3] = tf->gpr.a4;
ffffffffc0205292:	7834                	ld	a3,112(s0)
            arg[4] = tf->gpr.a5;
ffffffffc0205294:	7c38                	ld	a4,120(s0)
            arg[0] = tf->gpr.a1;
ffffffffc0205296:	e42a                	sd	a0,8(sp)
            arg[1] = tf->gpr.a2;
ffffffffc0205298:	e82e                	sd	a1,16(sp)
            arg[2] = tf->gpr.a3;
ffffffffc020529a:	ec32                	sd	a2,24(sp)
            arg[3] = tf->gpr.a4;
ffffffffc020529c:	f036                	sd	a3,32(sp)
            arg[4] = tf->gpr.a5;
ffffffffc020529e:	f43a                	sd	a4,40(sp)
            tf->gpr.a0 = syscalls[num](arg);
ffffffffc02052a0:	0028                	addi	a0,sp,8
ffffffffc02052a2:	9782                	jalr	a5
    }
    //如果执行到这里，说明传入的系统调用编号还没有被实现，就崩掉了。
    print_trapframe(tf);
    panic("undefined syscall %d, pid = %d, name = %s.\n",
            num, current->pid, current->name);
}
ffffffffc02052a4:	60a6                	ld	ra,72(sp)
            tf->gpr.a0 = syscalls[num](arg);
ffffffffc02052a6:	e828                	sd	a0,80(s0)
}
ffffffffc02052a8:	6406                	ld	s0,64(sp)
ffffffffc02052aa:	74e2                	ld	s1,56(sp)
ffffffffc02052ac:	7942                	ld	s2,48(sp)
ffffffffc02052ae:	6161                	addi	sp,sp,80
ffffffffc02052b0:	8082                	ret
    print_trapframe(tf);
ffffffffc02052b2:	8522                	mv	a0,s0
ffffffffc02052b4:	8f1fb0ef          	jal	ra,ffffffffc0200ba4 <print_trapframe>
    panic("undefined syscall %d, pid = %d, name = %s.\n",
ffffffffc02052b8:	609c                	ld	a5,0(s1)
ffffffffc02052ba:	86ca                	mv	a3,s2
ffffffffc02052bc:	00002617          	auipc	a2,0x2
ffffffffc02052c0:	22460613          	addi	a2,a2,548 # ffffffffc02074e0 <default_pmm_manager+0xeb0>
ffffffffc02052c4:	43d8                	lw	a4,4(a5)
ffffffffc02052c6:	06600593          	li	a1,102
ffffffffc02052ca:	0b478793          	addi	a5,a5,180
ffffffffc02052ce:	00002517          	auipc	a0,0x2
ffffffffc02052d2:	24250513          	addi	a0,a0,578 # ffffffffc0207510 <default_pmm_manager+0xee0>
ffffffffc02052d6:	9b8fb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02052da <hash32>:
 *
 * High bits are more random, so we use them.
 * */
uint32_t
hash32(uint32_t val, unsigned int bits) {
    uint32_t hash = val * GOLDEN_RATIO_PRIME_32;
ffffffffc02052da:	9e3707b7          	lui	a5,0x9e370
ffffffffc02052de:	2785                	addiw	a5,a5,1
ffffffffc02052e0:	02a7853b          	mulw	a0,a5,a0
    return (hash >> (32 - bits));
ffffffffc02052e4:	02000793          	li	a5,32
ffffffffc02052e8:	9f8d                	subw	a5,a5,a1
}
ffffffffc02052ea:	00f5553b          	srlw	a0,a0,a5
ffffffffc02052ee:	8082                	ret

ffffffffc02052f0 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc02052f0:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02052f4:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc02052f6:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02052fa:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc02052fc:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0205300:	f022                	sd	s0,32(sp)
ffffffffc0205302:	ec26                	sd	s1,24(sp)
ffffffffc0205304:	e84a                	sd	s2,16(sp)
ffffffffc0205306:	f406                	sd	ra,40(sp)
ffffffffc0205308:	e44e                	sd	s3,8(sp)
ffffffffc020530a:	84aa                	mv	s1,a0
ffffffffc020530c:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc020530e:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc0205312:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc0205314:	03067e63          	bgeu	a2,a6,ffffffffc0205350 <printnum+0x60>
ffffffffc0205318:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc020531a:	00805763          	blez	s0,ffffffffc0205328 <printnum+0x38>
ffffffffc020531e:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0205320:	85ca                	mv	a1,s2
ffffffffc0205322:	854e                	mv	a0,s3
ffffffffc0205324:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0205326:	fc65                	bnez	s0,ffffffffc020531e <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0205328:	1a02                	slli	s4,s4,0x20
ffffffffc020532a:	00002797          	auipc	a5,0x2
ffffffffc020532e:	2fe78793          	addi	a5,a5,766 # ffffffffc0207628 <syscalls+0x100>
ffffffffc0205332:	020a5a13          	srli	s4,s4,0x20
ffffffffc0205336:	9a3e                	add	s4,s4,a5
    // Crashes if num >= base. No idea what going on here
    // Here is a quick fix
    // update: Stack grows downward and destory the SBI
    // sbi_console_putchar("0123456789abcdef"[mod]);
    // (*(int *)putdat)++;
}
ffffffffc0205338:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020533a:	000a4503          	lbu	a0,0(s4)
}
ffffffffc020533e:	70a2                	ld	ra,40(sp)
ffffffffc0205340:	69a2                	ld	s3,8(sp)
ffffffffc0205342:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0205344:	85ca                	mv	a1,s2
ffffffffc0205346:	87a6                	mv	a5,s1
}
ffffffffc0205348:	6942                	ld	s2,16(sp)
ffffffffc020534a:	64e2                	ld	s1,24(sp)
ffffffffc020534c:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020534e:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0205350:	03065633          	divu	a2,a2,a6
ffffffffc0205354:	8722                	mv	a4,s0
ffffffffc0205356:	f9bff0ef          	jal	ra,ffffffffc02052f0 <printnum>
ffffffffc020535a:	b7f9                	j	ffffffffc0205328 <printnum+0x38>

ffffffffc020535c <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc020535c:	7119                	addi	sp,sp,-128
ffffffffc020535e:	f4a6                	sd	s1,104(sp)
ffffffffc0205360:	f0ca                	sd	s2,96(sp)
ffffffffc0205362:	ecce                	sd	s3,88(sp)
ffffffffc0205364:	e8d2                	sd	s4,80(sp)
ffffffffc0205366:	e4d6                	sd	s5,72(sp)
ffffffffc0205368:	e0da                	sd	s6,64(sp)
ffffffffc020536a:	fc5e                	sd	s7,56(sp)
ffffffffc020536c:	f06a                	sd	s10,32(sp)
ffffffffc020536e:	fc86                	sd	ra,120(sp)
ffffffffc0205370:	f8a2                	sd	s0,112(sp)
ffffffffc0205372:	f862                	sd	s8,48(sp)
ffffffffc0205374:	f466                	sd	s9,40(sp)
ffffffffc0205376:	ec6e                	sd	s11,24(sp)
ffffffffc0205378:	892a                	mv	s2,a0
ffffffffc020537a:	84ae                	mv	s1,a1
ffffffffc020537c:	8d32                	mv	s10,a2
ffffffffc020537e:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0205380:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc0205384:	5b7d                	li	s6,-1
ffffffffc0205386:	00002a97          	auipc	s5,0x2
ffffffffc020538a:	2cea8a93          	addi	s5,s5,718 # ffffffffc0207654 <syscalls+0x12c>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc020538e:	00002b97          	auipc	s7,0x2
ffffffffc0205392:	4e2b8b93          	addi	s7,s7,1250 # ffffffffc0207870 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0205396:	000d4503          	lbu	a0,0(s10)
ffffffffc020539a:	001d0413          	addi	s0,s10,1
ffffffffc020539e:	01350a63          	beq	a0,s3,ffffffffc02053b2 <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc02053a2:	c121                	beqz	a0,ffffffffc02053e2 <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc02053a4:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02053a6:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc02053a8:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02053aa:	fff44503          	lbu	a0,-1(s0)
ffffffffc02053ae:	ff351ae3          	bne	a0,s3,ffffffffc02053a2 <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02053b2:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc02053b6:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc02053ba:	4c81                	li	s9,0
ffffffffc02053bc:	4881                	li	a7,0
        width = precision = -1;
ffffffffc02053be:	5c7d                	li	s8,-1
ffffffffc02053c0:	5dfd                	li	s11,-1
ffffffffc02053c2:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc02053c6:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02053c8:	fdd6059b          	addiw	a1,a2,-35
ffffffffc02053cc:	0ff5f593          	zext.b	a1,a1
ffffffffc02053d0:	00140d13          	addi	s10,s0,1
ffffffffc02053d4:	04b56263          	bltu	a0,a1,ffffffffc0205418 <vprintfmt+0xbc>
ffffffffc02053d8:	058a                	slli	a1,a1,0x2
ffffffffc02053da:	95d6                	add	a1,a1,s5
ffffffffc02053dc:	4194                	lw	a3,0(a1)
ffffffffc02053de:	96d6                	add	a3,a3,s5
ffffffffc02053e0:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc02053e2:	70e6                	ld	ra,120(sp)
ffffffffc02053e4:	7446                	ld	s0,112(sp)
ffffffffc02053e6:	74a6                	ld	s1,104(sp)
ffffffffc02053e8:	7906                	ld	s2,96(sp)
ffffffffc02053ea:	69e6                	ld	s3,88(sp)
ffffffffc02053ec:	6a46                	ld	s4,80(sp)
ffffffffc02053ee:	6aa6                	ld	s5,72(sp)
ffffffffc02053f0:	6b06                	ld	s6,64(sp)
ffffffffc02053f2:	7be2                	ld	s7,56(sp)
ffffffffc02053f4:	7c42                	ld	s8,48(sp)
ffffffffc02053f6:	7ca2                	ld	s9,40(sp)
ffffffffc02053f8:	7d02                	ld	s10,32(sp)
ffffffffc02053fa:	6de2                	ld	s11,24(sp)
ffffffffc02053fc:	6109                	addi	sp,sp,128
ffffffffc02053fe:	8082                	ret
            padc = '0';
ffffffffc0205400:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc0205402:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205406:	846a                	mv	s0,s10
ffffffffc0205408:	00140d13          	addi	s10,s0,1
ffffffffc020540c:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0205410:	0ff5f593          	zext.b	a1,a1
ffffffffc0205414:	fcb572e3          	bgeu	a0,a1,ffffffffc02053d8 <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc0205418:	85a6                	mv	a1,s1
ffffffffc020541a:	02500513          	li	a0,37
ffffffffc020541e:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0205420:	fff44783          	lbu	a5,-1(s0)
ffffffffc0205424:	8d22                	mv	s10,s0
ffffffffc0205426:	f73788e3          	beq	a5,s3,ffffffffc0205396 <vprintfmt+0x3a>
ffffffffc020542a:	ffed4783          	lbu	a5,-2(s10)
ffffffffc020542e:	1d7d                	addi	s10,s10,-1
ffffffffc0205430:	ff379de3          	bne	a5,s3,ffffffffc020542a <vprintfmt+0xce>
ffffffffc0205434:	b78d                	j	ffffffffc0205396 <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc0205436:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc020543a:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020543e:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc0205440:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc0205444:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0205448:	02d86463          	bltu	a6,a3,ffffffffc0205470 <vprintfmt+0x114>
                ch = *fmt;
ffffffffc020544c:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0205450:	002c169b          	slliw	a3,s8,0x2
ffffffffc0205454:	0186873b          	addw	a4,a3,s8
ffffffffc0205458:	0017171b          	slliw	a4,a4,0x1
ffffffffc020545c:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc020545e:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc0205462:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0205464:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc0205468:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc020546c:	fed870e3          	bgeu	a6,a3,ffffffffc020544c <vprintfmt+0xf0>
            if (width < 0)
ffffffffc0205470:	f40ddce3          	bgez	s11,ffffffffc02053c8 <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc0205474:	8de2                	mv	s11,s8
ffffffffc0205476:	5c7d                	li	s8,-1
ffffffffc0205478:	bf81                	j	ffffffffc02053c8 <vprintfmt+0x6c>
            if (width < 0)
ffffffffc020547a:	fffdc693          	not	a3,s11
ffffffffc020547e:	96fd                	srai	a3,a3,0x3f
ffffffffc0205480:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205484:	00144603          	lbu	a2,1(s0)
ffffffffc0205488:	2d81                	sext.w	s11,s11
ffffffffc020548a:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc020548c:	bf35                	j	ffffffffc02053c8 <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc020548e:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205492:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc0205496:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205498:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc020549a:	bfd9                	j	ffffffffc0205470 <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc020549c:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc020549e:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc02054a2:	01174463          	blt	a4,a7,ffffffffc02054aa <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc02054a6:	1a088e63          	beqz	a7,ffffffffc0205662 <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc02054aa:	000a3603          	ld	a2,0(s4)
ffffffffc02054ae:	46c1                	li	a3,16
ffffffffc02054b0:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc02054b2:	2781                	sext.w	a5,a5
ffffffffc02054b4:	876e                	mv	a4,s11
ffffffffc02054b6:	85a6                	mv	a1,s1
ffffffffc02054b8:	854a                	mv	a0,s2
ffffffffc02054ba:	e37ff0ef          	jal	ra,ffffffffc02052f0 <printnum>
            break;
ffffffffc02054be:	bde1                	j	ffffffffc0205396 <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc02054c0:	000a2503          	lw	a0,0(s4)
ffffffffc02054c4:	85a6                	mv	a1,s1
ffffffffc02054c6:	0a21                	addi	s4,s4,8
ffffffffc02054c8:	9902                	jalr	s2
            break;
ffffffffc02054ca:	b5f1                	j	ffffffffc0205396 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc02054cc:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02054ce:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc02054d2:	01174463          	blt	a4,a7,ffffffffc02054da <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc02054d6:	18088163          	beqz	a7,ffffffffc0205658 <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc02054da:	000a3603          	ld	a2,0(s4)
ffffffffc02054de:	46a9                	li	a3,10
ffffffffc02054e0:	8a2e                	mv	s4,a1
ffffffffc02054e2:	bfc1                	j	ffffffffc02054b2 <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02054e4:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc02054e8:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02054ea:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02054ec:	bdf1                	j	ffffffffc02053c8 <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc02054ee:	85a6                	mv	a1,s1
ffffffffc02054f0:	02500513          	li	a0,37
ffffffffc02054f4:	9902                	jalr	s2
            break;
ffffffffc02054f6:	b545                	j	ffffffffc0205396 <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02054f8:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc02054fc:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02054fe:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0205500:	b5e1                	j	ffffffffc02053c8 <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc0205502:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0205504:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0205508:	01174463          	blt	a4,a7,ffffffffc0205510 <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc020550c:	14088163          	beqz	a7,ffffffffc020564e <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc0205510:	000a3603          	ld	a2,0(s4)
ffffffffc0205514:	46a1                	li	a3,8
ffffffffc0205516:	8a2e                	mv	s4,a1
ffffffffc0205518:	bf69                	j	ffffffffc02054b2 <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc020551a:	03000513          	li	a0,48
ffffffffc020551e:	85a6                	mv	a1,s1
ffffffffc0205520:	e03e                	sd	a5,0(sp)
ffffffffc0205522:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0205524:	85a6                	mv	a1,s1
ffffffffc0205526:	07800513          	li	a0,120
ffffffffc020552a:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc020552c:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc020552e:	6782                	ld	a5,0(sp)
ffffffffc0205530:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0205532:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc0205536:	bfb5                	j	ffffffffc02054b2 <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0205538:	000a3403          	ld	s0,0(s4)
ffffffffc020553c:	008a0713          	addi	a4,s4,8
ffffffffc0205540:	e03a                	sd	a4,0(sp)
ffffffffc0205542:	14040263          	beqz	s0,ffffffffc0205686 <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc0205546:	0fb05763          	blez	s11,ffffffffc0205634 <vprintfmt+0x2d8>
ffffffffc020554a:	02d00693          	li	a3,45
ffffffffc020554e:	0cd79163          	bne	a5,a3,ffffffffc0205610 <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205552:	00044783          	lbu	a5,0(s0)
ffffffffc0205556:	0007851b          	sext.w	a0,a5
ffffffffc020555a:	cf85                	beqz	a5,ffffffffc0205592 <vprintfmt+0x236>
ffffffffc020555c:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0205560:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205564:	000c4563          	bltz	s8,ffffffffc020556e <vprintfmt+0x212>
ffffffffc0205568:	3c7d                	addiw	s8,s8,-1
ffffffffc020556a:	036c0263          	beq	s8,s6,ffffffffc020558e <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc020556e:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0205570:	0e0c8e63          	beqz	s9,ffffffffc020566c <vprintfmt+0x310>
ffffffffc0205574:	3781                	addiw	a5,a5,-32
ffffffffc0205576:	0ef47b63          	bgeu	s0,a5,ffffffffc020566c <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc020557a:	03f00513          	li	a0,63
ffffffffc020557e:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205580:	000a4783          	lbu	a5,0(s4)
ffffffffc0205584:	3dfd                	addiw	s11,s11,-1
ffffffffc0205586:	0a05                	addi	s4,s4,1
ffffffffc0205588:	0007851b          	sext.w	a0,a5
ffffffffc020558c:	ffe1                	bnez	a5,ffffffffc0205564 <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc020558e:	01b05963          	blez	s11,ffffffffc02055a0 <vprintfmt+0x244>
ffffffffc0205592:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0205594:	85a6                	mv	a1,s1
ffffffffc0205596:	02000513          	li	a0,32
ffffffffc020559a:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc020559c:	fe0d9be3          	bnez	s11,ffffffffc0205592 <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc02055a0:	6a02                	ld	s4,0(sp)
ffffffffc02055a2:	bbd5                	j	ffffffffc0205396 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc02055a4:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02055a6:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc02055aa:	01174463          	blt	a4,a7,ffffffffc02055b2 <vprintfmt+0x256>
    else if (lflag) {
ffffffffc02055ae:	08088d63          	beqz	a7,ffffffffc0205648 <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc02055b2:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc02055b6:	0a044d63          	bltz	s0,ffffffffc0205670 <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc02055ba:	8622                	mv	a2,s0
ffffffffc02055bc:	8a66                	mv	s4,s9
ffffffffc02055be:	46a9                	li	a3,10
ffffffffc02055c0:	bdcd                	j	ffffffffc02054b2 <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc02055c2:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02055c6:	4761                	li	a4,24
            err = va_arg(ap, int);
ffffffffc02055c8:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc02055ca:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc02055ce:	8fb5                	xor	a5,a5,a3
ffffffffc02055d0:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02055d4:	02d74163          	blt	a4,a3,ffffffffc02055f6 <vprintfmt+0x29a>
ffffffffc02055d8:	00369793          	slli	a5,a3,0x3
ffffffffc02055dc:	97de                	add	a5,a5,s7
ffffffffc02055de:	639c                	ld	a5,0(a5)
ffffffffc02055e0:	cb99                	beqz	a5,ffffffffc02055f6 <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc02055e2:	86be                	mv	a3,a5
ffffffffc02055e4:	00000617          	auipc	a2,0x0
ffffffffc02055e8:	1f460613          	addi	a2,a2,500 # ffffffffc02057d8 <etext+0x2e>
ffffffffc02055ec:	85a6                	mv	a1,s1
ffffffffc02055ee:	854a                	mv	a0,s2
ffffffffc02055f0:	0ce000ef          	jal	ra,ffffffffc02056be <printfmt>
ffffffffc02055f4:	b34d                	j	ffffffffc0205396 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc02055f6:	00002617          	auipc	a2,0x2
ffffffffc02055fa:	05260613          	addi	a2,a2,82 # ffffffffc0207648 <syscalls+0x120>
ffffffffc02055fe:	85a6                	mv	a1,s1
ffffffffc0205600:	854a                	mv	a0,s2
ffffffffc0205602:	0bc000ef          	jal	ra,ffffffffc02056be <printfmt>
ffffffffc0205606:	bb41                	j	ffffffffc0205396 <vprintfmt+0x3a>
                p = "(null)";
ffffffffc0205608:	00002417          	auipc	s0,0x2
ffffffffc020560c:	03840413          	addi	s0,s0,56 # ffffffffc0207640 <syscalls+0x118>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0205610:	85e2                	mv	a1,s8
ffffffffc0205612:	8522                	mv	a0,s0
ffffffffc0205614:	e43e                	sd	a5,8(sp)
ffffffffc0205616:	0e2000ef          	jal	ra,ffffffffc02056f8 <strnlen>
ffffffffc020561a:	40ad8dbb          	subw	s11,s11,a0
ffffffffc020561e:	01b05b63          	blez	s11,ffffffffc0205634 <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc0205622:	67a2                	ld	a5,8(sp)
ffffffffc0205624:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0205628:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc020562a:	85a6                	mv	a1,s1
ffffffffc020562c:	8552                	mv	a0,s4
ffffffffc020562e:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0205630:	fe0d9ce3          	bnez	s11,ffffffffc0205628 <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205634:	00044783          	lbu	a5,0(s0)
ffffffffc0205638:	00140a13          	addi	s4,s0,1
ffffffffc020563c:	0007851b          	sext.w	a0,a5
ffffffffc0205640:	d3a5                	beqz	a5,ffffffffc02055a0 <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0205642:	05e00413          	li	s0,94
ffffffffc0205646:	bf39                	j	ffffffffc0205564 <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc0205648:	000a2403          	lw	s0,0(s4)
ffffffffc020564c:	b7ad                	j	ffffffffc02055b6 <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc020564e:	000a6603          	lwu	a2,0(s4)
ffffffffc0205652:	46a1                	li	a3,8
ffffffffc0205654:	8a2e                	mv	s4,a1
ffffffffc0205656:	bdb1                	j	ffffffffc02054b2 <vprintfmt+0x156>
ffffffffc0205658:	000a6603          	lwu	a2,0(s4)
ffffffffc020565c:	46a9                	li	a3,10
ffffffffc020565e:	8a2e                	mv	s4,a1
ffffffffc0205660:	bd89                	j	ffffffffc02054b2 <vprintfmt+0x156>
ffffffffc0205662:	000a6603          	lwu	a2,0(s4)
ffffffffc0205666:	46c1                	li	a3,16
ffffffffc0205668:	8a2e                	mv	s4,a1
ffffffffc020566a:	b5a1                	j	ffffffffc02054b2 <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc020566c:	9902                	jalr	s2
ffffffffc020566e:	bf09                	j	ffffffffc0205580 <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc0205670:	85a6                	mv	a1,s1
ffffffffc0205672:	02d00513          	li	a0,45
ffffffffc0205676:	e03e                	sd	a5,0(sp)
ffffffffc0205678:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc020567a:	6782                	ld	a5,0(sp)
ffffffffc020567c:	8a66                	mv	s4,s9
ffffffffc020567e:	40800633          	neg	a2,s0
ffffffffc0205682:	46a9                	li	a3,10
ffffffffc0205684:	b53d                	j	ffffffffc02054b2 <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc0205686:	03b05163          	blez	s11,ffffffffc02056a8 <vprintfmt+0x34c>
ffffffffc020568a:	02d00693          	li	a3,45
ffffffffc020568e:	f6d79de3          	bne	a5,a3,ffffffffc0205608 <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc0205692:	00002417          	auipc	s0,0x2
ffffffffc0205696:	fae40413          	addi	s0,s0,-82 # ffffffffc0207640 <syscalls+0x118>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020569a:	02800793          	li	a5,40
ffffffffc020569e:	02800513          	li	a0,40
ffffffffc02056a2:	00140a13          	addi	s4,s0,1
ffffffffc02056a6:	bd6d                	j	ffffffffc0205560 <vprintfmt+0x204>
ffffffffc02056a8:	00002a17          	auipc	s4,0x2
ffffffffc02056ac:	f99a0a13          	addi	s4,s4,-103 # ffffffffc0207641 <syscalls+0x119>
ffffffffc02056b0:	02800513          	li	a0,40
ffffffffc02056b4:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02056b8:	05e00413          	li	s0,94
ffffffffc02056bc:	b565                	j	ffffffffc0205564 <vprintfmt+0x208>

ffffffffc02056be <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02056be:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc02056c0:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02056c4:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc02056c6:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02056c8:	ec06                	sd	ra,24(sp)
ffffffffc02056ca:	f83a                	sd	a4,48(sp)
ffffffffc02056cc:	fc3e                	sd	a5,56(sp)
ffffffffc02056ce:	e0c2                	sd	a6,64(sp)
ffffffffc02056d0:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc02056d2:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc02056d4:	c89ff0ef          	jal	ra,ffffffffc020535c <vprintfmt>
}
ffffffffc02056d8:	60e2                	ld	ra,24(sp)
ffffffffc02056da:	6161                	addi	sp,sp,80
ffffffffc02056dc:	8082                	ret

ffffffffc02056de <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc02056de:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc02056e2:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc02056e4:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc02056e6:	cb81                	beqz	a5,ffffffffc02056f6 <strlen+0x18>
        cnt ++;
ffffffffc02056e8:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc02056ea:	00a707b3          	add	a5,a4,a0
ffffffffc02056ee:	0007c783          	lbu	a5,0(a5)
ffffffffc02056f2:	fbfd                	bnez	a5,ffffffffc02056e8 <strlen+0xa>
ffffffffc02056f4:	8082                	ret
    }
    return cnt;
}
ffffffffc02056f6:	8082                	ret

ffffffffc02056f8 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc02056f8:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc02056fa:	e589                	bnez	a1,ffffffffc0205704 <strnlen+0xc>
ffffffffc02056fc:	a811                	j	ffffffffc0205710 <strnlen+0x18>
        cnt ++;
ffffffffc02056fe:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0205700:	00f58863          	beq	a1,a5,ffffffffc0205710 <strnlen+0x18>
ffffffffc0205704:	00f50733          	add	a4,a0,a5
ffffffffc0205708:	00074703          	lbu	a4,0(a4)
ffffffffc020570c:	fb6d                	bnez	a4,ffffffffc02056fe <strnlen+0x6>
ffffffffc020570e:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0205710:	852e                	mv	a0,a1
ffffffffc0205712:	8082                	ret

ffffffffc0205714 <strcpy>:
char *
strcpy(char *dst, const char *src) {
#ifdef __HAVE_ARCH_STRCPY
    return __strcpy(dst, src);
#else
    char *p = dst;
ffffffffc0205714:	87aa                	mv	a5,a0
    while ((*p ++ = *src ++) != '\0')
ffffffffc0205716:	0005c703          	lbu	a4,0(a1)
ffffffffc020571a:	0785                	addi	a5,a5,1
ffffffffc020571c:	0585                	addi	a1,a1,1
ffffffffc020571e:	fee78fa3          	sb	a4,-1(a5)
ffffffffc0205722:	fb75                	bnez	a4,ffffffffc0205716 <strcpy+0x2>
        /* nothing */;
    return dst;
#endif /* __HAVE_ARCH_STRCPY */
}
ffffffffc0205724:	8082                	ret

ffffffffc0205726 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0205726:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc020572a:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc020572e:	cb89                	beqz	a5,ffffffffc0205740 <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc0205730:	0505                	addi	a0,a0,1
ffffffffc0205732:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0205734:	fee789e3          	beq	a5,a4,ffffffffc0205726 <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0205738:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc020573c:	9d19                	subw	a0,a0,a4
ffffffffc020573e:	8082                	ret
ffffffffc0205740:	4501                	li	a0,0
ffffffffc0205742:	bfed                	j	ffffffffc020573c <strcmp+0x16>

ffffffffc0205744 <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0205744:	c20d                	beqz	a2,ffffffffc0205766 <strncmp+0x22>
ffffffffc0205746:	962e                	add	a2,a2,a1
ffffffffc0205748:	a031                	j	ffffffffc0205754 <strncmp+0x10>
        n --, s1 ++, s2 ++;
ffffffffc020574a:	0505                	addi	a0,a0,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc020574c:	00e79a63          	bne	a5,a4,ffffffffc0205760 <strncmp+0x1c>
ffffffffc0205750:	00b60b63          	beq	a2,a1,ffffffffc0205766 <strncmp+0x22>
ffffffffc0205754:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc0205758:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc020575a:	fff5c703          	lbu	a4,-1(a1)
ffffffffc020575e:	f7f5                	bnez	a5,ffffffffc020574a <strncmp+0x6>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0205760:	40e7853b          	subw	a0,a5,a4
}
ffffffffc0205764:	8082                	ret
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0205766:	4501                	li	a0,0
ffffffffc0205768:	8082                	ret

ffffffffc020576a <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc020576a:	00054783          	lbu	a5,0(a0)
ffffffffc020576e:	c799                	beqz	a5,ffffffffc020577c <strchr+0x12>
        if (*s == c) {
ffffffffc0205770:	00f58763          	beq	a1,a5,ffffffffc020577e <strchr+0x14>
    while (*s != '\0') {
ffffffffc0205774:	00154783          	lbu	a5,1(a0)
            return (char *)s;
        }
        s ++;
ffffffffc0205778:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc020577a:	fbfd                	bnez	a5,ffffffffc0205770 <strchr+0x6>
    }
    return NULL;
ffffffffc020577c:	4501                	li	a0,0
}
ffffffffc020577e:	8082                	ret

ffffffffc0205780 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0205780:	ca01                	beqz	a2,ffffffffc0205790 <memset+0x10>
ffffffffc0205782:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0205784:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0205786:	0785                	addi	a5,a5,1
ffffffffc0205788:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc020578c:	fec79de3          	bne	a5,a2,ffffffffc0205786 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0205790:	8082                	ret

ffffffffc0205792 <memcpy>:
#ifdef __HAVE_ARCH_MEMCPY
    return __memcpy(dst, src, n);
#else
    const char *s = src;
    char *d = dst;
    while (n -- > 0) {
ffffffffc0205792:	ca19                	beqz	a2,ffffffffc02057a8 <memcpy+0x16>
ffffffffc0205794:	962e                	add	a2,a2,a1
    char *d = dst;
ffffffffc0205796:	87aa                	mv	a5,a0
        *d ++ = *s ++;
ffffffffc0205798:	0005c703          	lbu	a4,0(a1)
ffffffffc020579c:	0585                	addi	a1,a1,1
ffffffffc020579e:	0785                	addi	a5,a5,1
ffffffffc02057a0:	fee78fa3          	sb	a4,-1(a5)
    while (n -- > 0) {
ffffffffc02057a4:	fec59ae3          	bne	a1,a2,ffffffffc0205798 <memcpy+0x6>
    }
    return dst;
#endif /* __HAVE_ARCH_MEMCPY */
}
ffffffffc02057a8:	8082                	ret
