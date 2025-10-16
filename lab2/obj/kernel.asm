
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	00007297          	auipc	t0,0x7
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc0207000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	00007297          	auipc	t0,0x7
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc0207008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)

    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c02062b7          	lui	t0,0xc0206
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
ffffffffc020003c:	c0206137          	lui	sp,0xc0206

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc0200040:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc0200044:	0d828293          	addi	t0,t0,216 # ffffffffc02000d8 <kern_init>
    jr t0
ffffffffc0200048:	8282                	jr	t0

ffffffffc020004a <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc020004a:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[];
    cprintf("Special kernel symbols:\n");
ffffffffc020004c:	00002517          	auipc	a0,0x2
ffffffffc0200050:	e1c50513          	addi	a0,a0,-484 # ffffffffc0201e68 <etext+0x2>
void print_kerninfo(void) {
ffffffffc0200054:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200056:	0f6000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", (uintptr_t)kern_init);
ffffffffc020005a:	00000597          	auipc	a1,0x0
ffffffffc020005e:	07e58593          	addi	a1,a1,126 # ffffffffc02000d8 <kern_init>
ffffffffc0200062:	00002517          	auipc	a0,0x2
ffffffffc0200066:	e2650513          	addi	a0,a0,-474 # ffffffffc0201e88 <etext+0x22>
ffffffffc020006a:	0e2000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc020006e:	00002597          	auipc	a1,0x2
ffffffffc0200072:	df858593          	addi	a1,a1,-520 # ffffffffc0201e66 <etext>
ffffffffc0200076:	00002517          	auipc	a0,0x2
ffffffffc020007a:	e3250513          	addi	a0,a0,-462 # ffffffffc0201ea8 <etext+0x42>
ffffffffc020007e:	0ce000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc0200082:	00007597          	auipc	a1,0x7
ffffffffc0200086:	f9658593          	addi	a1,a1,-106 # ffffffffc0207018 <buddy_sys>
ffffffffc020008a:	00002517          	auipc	a0,0x2
ffffffffc020008e:	e3e50513          	addi	a0,a0,-450 # ffffffffc0201ec8 <etext+0x62>
ffffffffc0200092:	0ba000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc0200096:	00007597          	auipc	a1,0x7
ffffffffc020009a:	0da58593          	addi	a1,a1,218 # ffffffffc0207170 <end>
ffffffffc020009e:	00002517          	auipc	a0,0x2
ffffffffc02000a2:	e4a50513          	addi	a0,a0,-438 # ffffffffc0201ee8 <etext+0x82>
ffffffffc02000a6:	0a6000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - (char*)kern_init + 1023) / 1024);
ffffffffc02000aa:	00007597          	auipc	a1,0x7
ffffffffc02000ae:	4c558593          	addi	a1,a1,1221 # ffffffffc020756f <end+0x3ff>
ffffffffc02000b2:	00000797          	auipc	a5,0x0
ffffffffc02000b6:	02678793          	addi	a5,a5,38 # ffffffffc02000d8 <kern_init>
ffffffffc02000ba:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000be:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc02000c2:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000c4:	3ff5f593          	andi	a1,a1,1023
ffffffffc02000c8:	95be                	add	a1,a1,a5
ffffffffc02000ca:	85a9                	srai	a1,a1,0xa
ffffffffc02000cc:	00002517          	auipc	a0,0x2
ffffffffc02000d0:	e3c50513          	addi	a0,a0,-452 # ffffffffc0201f08 <etext+0xa2>
}
ffffffffc02000d4:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000d6:	a89d                	j	ffffffffc020014c <cprintf>

ffffffffc02000d8 <kern_init>:

int kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc02000d8:	00007517          	auipc	a0,0x7
ffffffffc02000dc:	f4050513          	addi	a0,a0,-192 # ffffffffc0207018 <buddy_sys>
ffffffffc02000e0:	00007617          	auipc	a2,0x7
ffffffffc02000e4:	09060613          	addi	a2,a2,144 # ffffffffc0207170 <end>
int kern_init(void) {
ffffffffc02000e8:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc02000ea:	8e09                	sub	a2,a2,a0
ffffffffc02000ec:	4581                	li	a1,0
int kern_init(void) {
ffffffffc02000ee:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc02000f0:	565010ef          	jal	ra,ffffffffc0201e54 <memset>
    dtb_init();
ffffffffc02000f4:	12c000ef          	jal	ra,ffffffffc0200220 <dtb_init>
    cons_init();  // init the console
ffffffffc02000f8:	11e000ef          	jal	ra,ffffffffc0200216 <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);
ffffffffc02000fc:	00002517          	auipc	a0,0x2
ffffffffc0200100:	e3c50513          	addi	a0,a0,-452 # ffffffffc0201f38 <etext+0xd2>
ffffffffc0200104:	07e000ef          	jal	ra,ffffffffc0200182 <cputs>

    print_kerninfo();
ffffffffc0200108:	f43ff0ef          	jal	ra,ffffffffc020004a <print_kerninfo>

    // grade_backtrace();
    pmm_init();  // init physical memory management
ffffffffc020010c:	6ee010ef          	jal	ra,ffffffffc02017fa <pmm_init>

    /* do nothing */
    while (1)
ffffffffc0200110:	a001                	j	ffffffffc0200110 <kern_init+0x38>

ffffffffc0200112 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc0200112:	1141                	addi	sp,sp,-16
ffffffffc0200114:	e022                	sd	s0,0(sp)
ffffffffc0200116:	e406                	sd	ra,8(sp)
ffffffffc0200118:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc020011a:	0fe000ef          	jal	ra,ffffffffc0200218 <cons_putc>
    (*cnt) ++;
ffffffffc020011e:	401c                	lw	a5,0(s0)
}
ffffffffc0200120:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
ffffffffc0200122:	2785                	addiw	a5,a5,1
ffffffffc0200124:	c01c                	sw	a5,0(s0)
}
ffffffffc0200126:	6402                	ld	s0,0(sp)
ffffffffc0200128:	0141                	addi	sp,sp,16
ffffffffc020012a:	8082                	ret

ffffffffc020012c <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc020012c:	1101                	addi	sp,sp,-32
ffffffffc020012e:	862a                	mv	a2,a0
ffffffffc0200130:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200132:	00000517          	auipc	a0,0x0
ffffffffc0200136:	fe050513          	addi	a0,a0,-32 # ffffffffc0200112 <cputch>
ffffffffc020013a:	006c                	addi	a1,sp,12
vcprintf(const char *fmt, va_list ap) {
ffffffffc020013c:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc020013e:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200140:	0ff010ef          	jal	ra,ffffffffc0201a3e <vprintfmt>
    return cnt;
}
ffffffffc0200144:	60e2                	ld	ra,24(sp)
ffffffffc0200146:	4532                	lw	a0,12(sp)
ffffffffc0200148:	6105                	addi	sp,sp,32
ffffffffc020014a:	8082                	ret

ffffffffc020014c <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc020014c:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc020014e:	02810313          	addi	t1,sp,40 # ffffffffc0206028 <boot_page_table_sv39+0x28>
cprintf(const char *fmt, ...) {
ffffffffc0200152:	8e2a                	mv	t3,a0
ffffffffc0200154:	f42e                	sd	a1,40(sp)
ffffffffc0200156:	f832                	sd	a2,48(sp)
ffffffffc0200158:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc020015a:	00000517          	auipc	a0,0x0
ffffffffc020015e:	fb850513          	addi	a0,a0,-72 # ffffffffc0200112 <cputch>
ffffffffc0200162:	004c                	addi	a1,sp,4
ffffffffc0200164:	869a                	mv	a3,t1
ffffffffc0200166:	8672                	mv	a2,t3
cprintf(const char *fmt, ...) {
ffffffffc0200168:	ec06                	sd	ra,24(sp)
ffffffffc020016a:	e0ba                	sd	a4,64(sp)
ffffffffc020016c:	e4be                	sd	a5,72(sp)
ffffffffc020016e:	e8c2                	sd	a6,80(sp)
ffffffffc0200170:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc0200172:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc0200174:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200176:	0c9010ef          	jal	ra,ffffffffc0201a3e <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc020017a:	60e2                	ld	ra,24(sp)
ffffffffc020017c:	4512                	lw	a0,4(sp)
ffffffffc020017e:	6125                	addi	sp,sp,96
ffffffffc0200180:	8082                	ret

ffffffffc0200182 <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
ffffffffc0200182:	1101                	addi	sp,sp,-32
ffffffffc0200184:	e822                	sd	s0,16(sp)
ffffffffc0200186:	ec06                	sd	ra,24(sp)
ffffffffc0200188:	e426                	sd	s1,8(sp)
ffffffffc020018a:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
ffffffffc020018c:	00054503          	lbu	a0,0(a0)
ffffffffc0200190:	c51d                	beqz	a0,ffffffffc02001be <cputs+0x3c>
ffffffffc0200192:	0405                	addi	s0,s0,1
ffffffffc0200194:	4485                	li	s1,1
ffffffffc0200196:	9c81                	subw	s1,s1,s0
    cons_putc(c);
ffffffffc0200198:	080000ef          	jal	ra,ffffffffc0200218 <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc020019c:	00044503          	lbu	a0,0(s0)
ffffffffc02001a0:	008487bb          	addw	a5,s1,s0
ffffffffc02001a4:	0405                	addi	s0,s0,1
ffffffffc02001a6:	f96d                	bnez	a0,ffffffffc0200198 <cputs+0x16>
    (*cnt) ++;
ffffffffc02001a8:	0017841b          	addiw	s0,a5,1
    cons_putc(c);
ffffffffc02001ac:	4529                	li	a0,10
ffffffffc02001ae:	06a000ef          	jal	ra,ffffffffc0200218 <cons_putc>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc02001b2:	60e2                	ld	ra,24(sp)
ffffffffc02001b4:	8522                	mv	a0,s0
ffffffffc02001b6:	6442                	ld	s0,16(sp)
ffffffffc02001b8:	64a2                	ld	s1,8(sp)
ffffffffc02001ba:	6105                	addi	sp,sp,32
ffffffffc02001bc:	8082                	ret
    while ((c = *str ++) != '\0') {
ffffffffc02001be:	4405                	li	s0,1
ffffffffc02001c0:	b7f5                	j	ffffffffc02001ac <cputs+0x2a>

ffffffffc02001c2 <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc02001c2:	00007317          	auipc	t1,0x7
ffffffffc02001c6:	f6630313          	addi	t1,t1,-154 # ffffffffc0207128 <is_panic>
ffffffffc02001ca:	00032e03          	lw	t3,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc02001ce:	715d                	addi	sp,sp,-80
ffffffffc02001d0:	ec06                	sd	ra,24(sp)
ffffffffc02001d2:	e822                	sd	s0,16(sp)
ffffffffc02001d4:	f436                	sd	a3,40(sp)
ffffffffc02001d6:	f83a                	sd	a4,48(sp)
ffffffffc02001d8:	fc3e                	sd	a5,56(sp)
ffffffffc02001da:	e0c2                	sd	a6,64(sp)
ffffffffc02001dc:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc02001de:	000e0363          	beqz	t3,ffffffffc02001e4 <__panic+0x22>
    vcprintf(fmt, ap);
    cprintf("\n");
    va_end(ap);

panic_dead:
    while (1) {
ffffffffc02001e2:	a001                	j	ffffffffc02001e2 <__panic+0x20>
    is_panic = 1;
ffffffffc02001e4:	4785                	li	a5,1
ffffffffc02001e6:	00f32023          	sw	a5,0(t1)
    va_start(ap, fmt);
ffffffffc02001ea:	8432                	mv	s0,a2
ffffffffc02001ec:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02001ee:	862e                	mv	a2,a1
ffffffffc02001f0:	85aa                	mv	a1,a0
ffffffffc02001f2:	00002517          	auipc	a0,0x2
ffffffffc02001f6:	d6650513          	addi	a0,a0,-666 # ffffffffc0201f58 <etext+0xf2>
    va_start(ap, fmt);
ffffffffc02001fa:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02001fc:	f51ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    vcprintf(fmt, ap);
ffffffffc0200200:	65a2                	ld	a1,8(sp)
ffffffffc0200202:	8522                	mv	a0,s0
ffffffffc0200204:	f29ff0ef          	jal	ra,ffffffffc020012c <vcprintf>
    cprintf("\n");
ffffffffc0200208:	00002517          	auipc	a0,0x2
ffffffffc020020c:	62050513          	addi	a0,a0,1568 # ffffffffc0202828 <etext+0x9c2>
ffffffffc0200210:	f3dff0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc0200214:	b7f9                	j	ffffffffc02001e2 <__panic+0x20>

ffffffffc0200216 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc0200216:	8082                	ret

ffffffffc0200218 <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }
ffffffffc0200218:	0ff57513          	zext.b	a0,a0
ffffffffc020021c:	3a50106f          	j	ffffffffc0201dc0 <sbi_console_putchar>

ffffffffc0200220 <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc0200220:	7119                	addi	sp,sp,-128
    cprintf("DTB Init\n");
ffffffffc0200222:	00002517          	auipc	a0,0x2
ffffffffc0200226:	d5650513          	addi	a0,a0,-682 # ffffffffc0201f78 <etext+0x112>
void dtb_init(void) {
ffffffffc020022a:	fc86                	sd	ra,120(sp)
ffffffffc020022c:	f8a2                	sd	s0,112(sp)
ffffffffc020022e:	e8d2                	sd	s4,80(sp)
ffffffffc0200230:	f4a6                	sd	s1,104(sp)
ffffffffc0200232:	f0ca                	sd	s2,96(sp)
ffffffffc0200234:	ecce                	sd	s3,88(sp)
ffffffffc0200236:	e4d6                	sd	s5,72(sp)
ffffffffc0200238:	e0da                	sd	s6,64(sp)
ffffffffc020023a:	fc5e                	sd	s7,56(sp)
ffffffffc020023c:	f862                	sd	s8,48(sp)
ffffffffc020023e:	f466                	sd	s9,40(sp)
ffffffffc0200240:	f06a                	sd	s10,32(sp)
ffffffffc0200242:	ec6e                	sd	s11,24(sp)
    cprintf("DTB Init\n");
ffffffffc0200244:	f09ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc0200248:	00007597          	auipc	a1,0x7
ffffffffc020024c:	db85b583          	ld	a1,-584(a1) # ffffffffc0207000 <boot_hartid>
ffffffffc0200250:	00002517          	auipc	a0,0x2
ffffffffc0200254:	d3850513          	addi	a0,a0,-712 # ffffffffc0201f88 <etext+0x122>
ffffffffc0200258:	ef5ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc020025c:	00007417          	auipc	s0,0x7
ffffffffc0200260:	dac40413          	addi	s0,s0,-596 # ffffffffc0207008 <boot_dtb>
ffffffffc0200264:	600c                	ld	a1,0(s0)
ffffffffc0200266:	00002517          	auipc	a0,0x2
ffffffffc020026a:	d3250513          	addi	a0,a0,-718 # ffffffffc0201f98 <etext+0x132>
ffffffffc020026e:	edfff0ef          	jal	ra,ffffffffc020014c <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc0200272:	00043a03          	ld	s4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc0200276:	00002517          	auipc	a0,0x2
ffffffffc020027a:	d3a50513          	addi	a0,a0,-710 # ffffffffc0201fb0 <etext+0x14a>
    if (boot_dtb == 0) {
ffffffffc020027e:	120a0463          	beqz	s4,ffffffffc02003a6 <dtb_init+0x186>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc0200282:	57f5                	li	a5,-3
ffffffffc0200284:	07fa                	slli	a5,a5,0x1e
ffffffffc0200286:	00fa0733          	add	a4,s4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc020028a:	431c                	lw	a5,0(a4)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020028c:	00ff0637          	lui	a2,0xff0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200290:	6b41                	lui	s6,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200292:	0087d59b          	srliw	a1,a5,0x8
ffffffffc0200296:	0187969b          	slliw	a3,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020029a:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020029e:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002a2:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002a6:	8df1                	and	a1,a1,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002a8:	8ec9                	or	a3,a3,a0
ffffffffc02002aa:	0087979b          	slliw	a5,a5,0x8
ffffffffc02002ae:	1b7d                	addi	s6,s6,-1
ffffffffc02002b0:	0167f7b3          	and	a5,a5,s6
ffffffffc02002b4:	8dd5                	or	a1,a1,a3
ffffffffc02002b6:	8ddd                	or	a1,a1,a5
    if (magic != 0xd00dfeed) {
ffffffffc02002b8:	d00e07b7          	lui	a5,0xd00e0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002bc:	2581                	sext.w	a1,a1
    if (magic != 0xd00dfeed) {
ffffffffc02002be:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <end+0xfed8d7d>
ffffffffc02002c2:	10f59163          	bne	a1,a5,ffffffffc02003c4 <dtb_init+0x1a4>
        return;
    }
    
    // 提取内存信息
    uint64_t mem_base, mem_size;
    if (extract_memory_info(dtb_vaddr, header, &mem_base, &mem_size) == 0) {
ffffffffc02002c6:	471c                	lw	a5,8(a4)
ffffffffc02002c8:	4754                	lw	a3,12(a4)
    int in_memory_node = 0;
ffffffffc02002ca:	4c81                	li	s9,0
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002cc:	0087d59b          	srliw	a1,a5,0x8
ffffffffc02002d0:	0086d51b          	srliw	a0,a3,0x8
ffffffffc02002d4:	0186941b          	slliw	s0,a3,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002d8:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002dc:	01879a1b          	slliw	s4,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002e0:	0187d81b          	srliw	a6,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002e4:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002e8:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002ec:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002f0:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002f4:	8d71                	and	a0,a0,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002f6:	01146433          	or	s0,s0,a7
ffffffffc02002fa:	0086969b          	slliw	a3,a3,0x8
ffffffffc02002fe:	010a6a33          	or	s4,s4,a6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200302:	8e6d                	and	a2,a2,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200304:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200308:	8c49                	or	s0,s0,a0
ffffffffc020030a:	0166f6b3          	and	a3,a3,s6
ffffffffc020030e:	00ca6a33          	or	s4,s4,a2
ffffffffc0200312:	0167f7b3          	and	a5,a5,s6
ffffffffc0200316:	8c55                	or	s0,s0,a3
ffffffffc0200318:	00fa6a33          	or	s4,s4,a5
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc020031c:	1402                	slli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc020031e:	1a02                	slli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200320:	9001                	srli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200322:	020a5a13          	srli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200326:	943a                	add	s0,s0,a4
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200328:	9a3a                	add	s4,s4,a4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020032a:	00ff0c37          	lui	s8,0xff0
        switch (token) {
ffffffffc020032e:	4b8d                	li	s7,3
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200330:	00002917          	auipc	s2,0x2
ffffffffc0200334:	cd090913          	addi	s2,s2,-816 # ffffffffc0202000 <etext+0x19a>
ffffffffc0200338:	49bd                	li	s3,15
        switch (token) {
ffffffffc020033a:	4d91                	li	s11,4
ffffffffc020033c:	4d05                	li	s10,1
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc020033e:	00002497          	auipc	s1,0x2
ffffffffc0200342:	cba48493          	addi	s1,s1,-838 # ffffffffc0201ff8 <etext+0x192>
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200346:	000a2703          	lw	a4,0(s4)
ffffffffc020034a:	004a0a93          	addi	s5,s4,4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020034e:	0087569b          	srliw	a3,a4,0x8
ffffffffc0200352:	0187179b          	slliw	a5,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200356:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020035a:	0106969b          	slliw	a3,a3,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020035e:	0107571b          	srliw	a4,a4,0x10
ffffffffc0200362:	8fd1                	or	a5,a5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200364:	0186f6b3          	and	a3,a3,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200368:	0087171b          	slliw	a4,a4,0x8
ffffffffc020036c:	8fd5                	or	a5,a5,a3
ffffffffc020036e:	00eb7733          	and	a4,s6,a4
ffffffffc0200372:	8fd9                	or	a5,a5,a4
ffffffffc0200374:	2781                	sext.w	a5,a5
        switch (token) {
ffffffffc0200376:	09778c63          	beq	a5,s7,ffffffffc020040e <dtb_init+0x1ee>
ffffffffc020037a:	00fbea63          	bltu	s7,a5,ffffffffc020038e <dtb_init+0x16e>
ffffffffc020037e:	07a78663          	beq	a5,s10,ffffffffc02003ea <dtb_init+0x1ca>
ffffffffc0200382:	4709                	li	a4,2
ffffffffc0200384:	00e79763          	bne	a5,a4,ffffffffc0200392 <dtb_init+0x172>
ffffffffc0200388:	4c81                	li	s9,0
ffffffffc020038a:	8a56                	mv	s4,s5
ffffffffc020038c:	bf6d                	j	ffffffffc0200346 <dtb_init+0x126>
ffffffffc020038e:	ffb78ee3          	beq	a5,s11,ffffffffc020038a <dtb_init+0x16a>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc0200392:	00002517          	auipc	a0,0x2
ffffffffc0200396:	ce650513          	addi	a0,a0,-794 # ffffffffc0202078 <etext+0x212>
ffffffffc020039a:	db3ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc020039e:	00002517          	auipc	a0,0x2
ffffffffc02003a2:	d1250513          	addi	a0,a0,-750 # ffffffffc02020b0 <etext+0x24a>
}
ffffffffc02003a6:	7446                	ld	s0,112(sp)
ffffffffc02003a8:	70e6                	ld	ra,120(sp)
ffffffffc02003aa:	74a6                	ld	s1,104(sp)
ffffffffc02003ac:	7906                	ld	s2,96(sp)
ffffffffc02003ae:	69e6                	ld	s3,88(sp)
ffffffffc02003b0:	6a46                	ld	s4,80(sp)
ffffffffc02003b2:	6aa6                	ld	s5,72(sp)
ffffffffc02003b4:	6b06                	ld	s6,64(sp)
ffffffffc02003b6:	7be2                	ld	s7,56(sp)
ffffffffc02003b8:	7c42                	ld	s8,48(sp)
ffffffffc02003ba:	7ca2                	ld	s9,40(sp)
ffffffffc02003bc:	7d02                	ld	s10,32(sp)
ffffffffc02003be:	6de2                	ld	s11,24(sp)
ffffffffc02003c0:	6109                	addi	sp,sp,128
    cprintf("DTB init completed\n");
ffffffffc02003c2:	b369                	j	ffffffffc020014c <cprintf>
}
ffffffffc02003c4:	7446                	ld	s0,112(sp)
ffffffffc02003c6:	70e6                	ld	ra,120(sp)
ffffffffc02003c8:	74a6                	ld	s1,104(sp)
ffffffffc02003ca:	7906                	ld	s2,96(sp)
ffffffffc02003cc:	69e6                	ld	s3,88(sp)
ffffffffc02003ce:	6a46                	ld	s4,80(sp)
ffffffffc02003d0:	6aa6                	ld	s5,72(sp)
ffffffffc02003d2:	6b06                	ld	s6,64(sp)
ffffffffc02003d4:	7be2                	ld	s7,56(sp)
ffffffffc02003d6:	7c42                	ld	s8,48(sp)
ffffffffc02003d8:	7ca2                	ld	s9,40(sp)
ffffffffc02003da:	7d02                	ld	s10,32(sp)
ffffffffc02003dc:	6de2                	ld	s11,24(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02003de:	00002517          	auipc	a0,0x2
ffffffffc02003e2:	bf250513          	addi	a0,a0,-1038 # ffffffffc0201fd0 <etext+0x16a>
}
ffffffffc02003e6:	6109                	addi	sp,sp,128
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02003e8:	b395                	j	ffffffffc020014c <cprintf>
                int name_len = strlen(name);
ffffffffc02003ea:	8556                	mv	a0,s5
ffffffffc02003ec:	1ef010ef          	jal	ra,ffffffffc0201dda <strlen>
ffffffffc02003f0:	8a2a                	mv	s4,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02003f2:	4619                	li	a2,6
ffffffffc02003f4:	85a6                	mv	a1,s1
ffffffffc02003f6:	8556                	mv	a0,s5
                int name_len = strlen(name);
ffffffffc02003f8:	2a01                	sext.w	s4,s4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02003fa:	235010ef          	jal	ra,ffffffffc0201e2e <strncmp>
ffffffffc02003fe:	e111                	bnez	a0,ffffffffc0200402 <dtb_init+0x1e2>
                    in_memory_node = 1;
ffffffffc0200400:	4c85                	li	s9,1
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc0200402:	0a91                	addi	s5,s5,4
ffffffffc0200404:	9ad2                	add	s5,s5,s4
ffffffffc0200406:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc020040a:	8a56                	mv	s4,s5
ffffffffc020040c:	bf2d                	j	ffffffffc0200346 <dtb_init+0x126>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc020040e:	004a2783          	lw	a5,4(s4)
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200412:	00ca0693          	addi	a3,s4,12
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200416:	0087d71b          	srliw	a4,a5,0x8
ffffffffc020041a:	01879a9b          	slliw	s5,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020041e:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200422:	0107171b          	slliw	a4,a4,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200426:	0107d79b          	srliw	a5,a5,0x10
ffffffffc020042a:	00caeab3          	or	s5,s5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020042e:	01877733          	and	a4,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200432:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200436:	00eaeab3          	or	s5,s5,a4
ffffffffc020043a:	00fb77b3          	and	a5,s6,a5
ffffffffc020043e:	00faeab3          	or	s5,s5,a5
ffffffffc0200442:	2a81                	sext.w	s5,s5
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200444:	000c9c63          	bnez	s9,ffffffffc020045c <dtb_init+0x23c>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc0200448:	1a82                	slli	s5,s5,0x20
ffffffffc020044a:	00368793          	addi	a5,a3,3
ffffffffc020044e:	020ada93          	srli	s5,s5,0x20
ffffffffc0200452:	9abe                	add	s5,s5,a5
ffffffffc0200454:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc0200458:	8a56                	mv	s4,s5
ffffffffc020045a:	b5f5                	j	ffffffffc0200346 <dtb_init+0x126>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc020045c:	008a2783          	lw	a5,8(s4)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200460:	85ca                	mv	a1,s2
ffffffffc0200462:	e436                	sd	a3,8(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200464:	0087d51b          	srliw	a0,a5,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200468:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020046c:	0187971b          	slliw	a4,a5,0x18
ffffffffc0200470:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200474:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200478:	8f51                	or	a4,a4,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020047a:	01857533          	and	a0,a0,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020047e:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200482:	8d59                	or	a0,a0,a4
ffffffffc0200484:	00fb77b3          	and	a5,s6,a5
ffffffffc0200488:	8d5d                	or	a0,a0,a5
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc020048a:	1502                	slli	a0,a0,0x20
ffffffffc020048c:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020048e:	9522                	add	a0,a0,s0
ffffffffc0200490:	181010ef          	jal	ra,ffffffffc0201e10 <strcmp>
ffffffffc0200494:	66a2                	ld	a3,8(sp)
ffffffffc0200496:	f94d                	bnez	a0,ffffffffc0200448 <dtb_init+0x228>
ffffffffc0200498:	fb59f8e3          	bgeu	s3,s5,ffffffffc0200448 <dtb_init+0x228>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc020049c:	00ca3783          	ld	a5,12(s4)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc02004a0:	014a3703          	ld	a4,20(s4)
        cprintf("Physical Memory from DTB:\n");
ffffffffc02004a4:	00002517          	auipc	a0,0x2
ffffffffc02004a8:	b6450513          	addi	a0,a0,-1180 # ffffffffc0202008 <etext+0x1a2>
           fdt32_to_cpu(x >> 32);
ffffffffc02004ac:	4207d613          	srai	a2,a5,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004b0:	0087d31b          	srliw	t1,a5,0x8
           fdt32_to_cpu(x >> 32);
ffffffffc02004b4:	42075593          	srai	a1,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004b8:	0187de1b          	srliw	t3,a5,0x18
ffffffffc02004bc:	0186581b          	srliw	a6,a2,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004c0:	0187941b          	slliw	s0,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004c4:	0107d89b          	srliw	a7,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004c8:	0187d693          	srli	a3,a5,0x18
ffffffffc02004cc:	01861f1b          	slliw	t5,a2,0x18
ffffffffc02004d0:	0087579b          	srliw	a5,a4,0x8
ffffffffc02004d4:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004d8:	0106561b          	srliw	a2,a2,0x10
ffffffffc02004dc:	010f6f33          	or	t5,t5,a6
ffffffffc02004e0:	0187529b          	srliw	t0,a4,0x18
ffffffffc02004e4:	0185df9b          	srliw	t6,a1,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004e8:	01837333          	and	t1,t1,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004ec:	01c46433          	or	s0,s0,t3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004f0:	0186f6b3          	and	a3,a3,s8
ffffffffc02004f4:	01859e1b          	slliw	t3,a1,0x18
ffffffffc02004f8:	01871e9b          	slliw	t4,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004fc:	0107581b          	srliw	a6,a4,0x10
ffffffffc0200500:	0086161b          	slliw	a2,a2,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200504:	8361                	srli	a4,a4,0x18
ffffffffc0200506:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020050a:	0105d59b          	srliw	a1,a1,0x10
ffffffffc020050e:	01e6e6b3          	or	a3,a3,t5
ffffffffc0200512:	00cb7633          	and	a2,s6,a2
ffffffffc0200516:	0088181b          	slliw	a6,a6,0x8
ffffffffc020051a:	0085959b          	slliw	a1,a1,0x8
ffffffffc020051e:	00646433          	or	s0,s0,t1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200522:	0187f7b3          	and	a5,a5,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200526:	01fe6333          	or	t1,t3,t6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020052a:	01877c33          	and	s8,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020052e:	0088989b          	slliw	a7,a7,0x8
ffffffffc0200532:	011b78b3          	and	a7,s6,a7
ffffffffc0200536:	005eeeb3          	or	t4,t4,t0
ffffffffc020053a:	00c6e733          	or	a4,a3,a2
ffffffffc020053e:	006c6c33          	or	s8,s8,t1
ffffffffc0200542:	010b76b3          	and	a3,s6,a6
ffffffffc0200546:	00bb7b33          	and	s6,s6,a1
ffffffffc020054a:	01d7e7b3          	or	a5,a5,t4
ffffffffc020054e:	016c6b33          	or	s6,s8,s6
ffffffffc0200552:	01146433          	or	s0,s0,a7
ffffffffc0200556:	8fd5                	or	a5,a5,a3
           fdt32_to_cpu(x >> 32);
ffffffffc0200558:	1702                	slli	a4,a4,0x20
ffffffffc020055a:	1b02                	slli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc020055c:	1782                	slli	a5,a5,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc020055e:	9301                	srli	a4,a4,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200560:	1402                	slli	s0,s0,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc0200562:	020b5b13          	srli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200566:	0167eb33          	or	s6,a5,s6
ffffffffc020056a:	8c59                	or	s0,s0,a4
        cprintf("Physical Memory from DTB:\n");
ffffffffc020056c:	be1ff0ef          	jal	ra,ffffffffc020014c <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc0200570:	85a2                	mv	a1,s0
ffffffffc0200572:	00002517          	auipc	a0,0x2
ffffffffc0200576:	ab650513          	addi	a0,a0,-1354 # ffffffffc0202028 <etext+0x1c2>
ffffffffc020057a:	bd3ff0ef          	jal	ra,ffffffffc020014c <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc020057e:	014b5613          	srli	a2,s6,0x14
ffffffffc0200582:	85da                	mv	a1,s6
ffffffffc0200584:	00002517          	auipc	a0,0x2
ffffffffc0200588:	abc50513          	addi	a0,a0,-1348 # ffffffffc0202040 <etext+0x1da>
ffffffffc020058c:	bc1ff0ef          	jal	ra,ffffffffc020014c <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc0200590:	008b05b3          	add	a1,s6,s0
ffffffffc0200594:	15fd                	addi	a1,a1,-1
ffffffffc0200596:	00002517          	auipc	a0,0x2
ffffffffc020059a:	aca50513          	addi	a0,a0,-1334 # ffffffffc0202060 <etext+0x1fa>
ffffffffc020059e:	bafff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("DTB init completed\n");
ffffffffc02005a2:	00002517          	auipc	a0,0x2
ffffffffc02005a6:	b0e50513          	addi	a0,a0,-1266 # ffffffffc02020b0 <etext+0x24a>
        memory_base = mem_base;
ffffffffc02005aa:	00007797          	auipc	a5,0x7
ffffffffc02005ae:	b887b323          	sd	s0,-1146(a5) # ffffffffc0207130 <memory_base>
        memory_size = mem_size;
ffffffffc02005b2:	00007797          	auipc	a5,0x7
ffffffffc02005b6:	b967b323          	sd	s6,-1146(a5) # ffffffffc0207138 <memory_size>
    cprintf("DTB init completed\n");
ffffffffc02005ba:	b3f5                	j	ffffffffc02003a6 <dtb_init+0x186>

ffffffffc02005bc <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc02005bc:	00007517          	auipc	a0,0x7
ffffffffc02005c0:	b7453503          	ld	a0,-1164(a0) # ffffffffc0207130 <memory_base>
ffffffffc02005c4:	8082                	ret

ffffffffc02005c6 <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
ffffffffc02005c6:	00007517          	auipc	a0,0x7
ffffffffc02005ca:	b7253503          	ld	a0,-1166(a0) # ffffffffc0207138 <memory_size>
ffffffffc02005ce:	8082                	ret

ffffffffc02005d0 <buddy_system_nr_free_pages>:
}

// 获取空闲页面数量
static size_t buddy_system_nr_free_pages(void) {
    return buddy_sys.nr_free;
}
ffffffffc02005d0:	00007517          	auipc	a0,0x7
ffffffffc02005d4:	b5056503          	lwu	a0,-1200(a0) # ffffffffc0207120 <buddy_sys+0x108>
ffffffffc02005d8:	8082                	ret

ffffffffc02005da <buddy_system_init>:
    buddy_sys.max_order = 0;
ffffffffc02005da:	00007797          	auipc	a5,0x7
ffffffffc02005de:	a207af23          	sw	zero,-1474(a5) # ffffffffc0207018 <buddy_sys>
    buddy_sys.nr_free = 0;
ffffffffc02005e2:	00007797          	auipc	a5,0x7
ffffffffc02005e6:	b207af23          	sw	zero,-1218(a5) # ffffffffc0207120 <buddy_sys+0x108>
    for (unsigned int i = 0; i <= MAX_ORDER; i++) {
ffffffffc02005ea:	00007797          	auipc	a5,0x7
ffffffffc02005ee:	a3678793          	addi	a5,a5,-1482 # ffffffffc0207020 <buddy_sys+0x8>
ffffffffc02005f2:	00007717          	auipc	a4,0x7
ffffffffc02005f6:	b2e70713          	addi	a4,a4,-1234 # ffffffffc0207120 <buddy_sys+0x108>
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc02005fa:	e79c                	sd	a5,8(a5)
ffffffffc02005fc:	e39c                	sd	a5,0(a5)
ffffffffc02005fe:	07c1                	addi	a5,a5,16
ffffffffc0200600:	fee79de3          	bne	a5,a4,ffffffffc02005fa <buddy_system_init+0x20>
    cprintf("buddy_system: initialized with max_order=%d\n", MAX_ORDER);
ffffffffc0200604:	45bd                	li	a1,15
ffffffffc0200606:	00002517          	auipc	a0,0x2
ffffffffc020060a:	ac250513          	addi	a0,a0,-1342 # ffffffffc02020c8 <etext+0x262>
ffffffffc020060e:	be3d                	j	ffffffffc020014c <cprintf>

ffffffffc0200610 <buddy_system_free_pages.part.0>:
buddy_system_free_pages(struct Page* base, size_t n) {
ffffffffc0200610:	7175                	addi	sp,sp,-144
ffffffffc0200612:	f8ca                	sd	s2,112(sp)
        (unsigned int)n, order, base - pages);
ffffffffc0200614:	00007917          	auipc	s2,0x7
ffffffffc0200618:	b3490913          	addi	s2,s2,-1228 # ffffffffc0207148 <pages>
ffffffffc020061c:	00093783          	ld	a5,0(s2)
    SetPageReserved(current);
ffffffffc0200620:	6510                	ld	a2,8(a0)
buddy_system_free_pages(struct Page* base, size_t n) {
ffffffffc0200622:	f4ce                	sd	s3,104(sp)
        (unsigned int)n, order, base - pages);
ffffffffc0200624:	40f507b3          	sub	a5,a0,a5
buddy_system_free_pages(struct Page* base, size_t n) {
ffffffffc0200628:	fc66                	sd	s9,56(sp)
ffffffffc020062a:	872e                	mv	a4,a1
ffffffffc020062c:	8caa                	mv	s9,a0
    cprintf("buddy_system: freeing %u pages (order %u) at page %ld\n",
ffffffffc020062e:	878d                	srai	a5,a5,0x3
ffffffffc0200630:	00003997          	auipc	s3,0x3
ffffffffc0200634:	e109b983          	ld	s3,-496(s3) # ffffffffc0203440 <error_string+0x38>
buddy_system_free_pages(struct Page* base, size_t n) {
ffffffffc0200638:	e506                	sd	ra,136(sp)
ffffffffc020063a:	e122                	sd	s0,128(sp)
ffffffffc020063c:	fca6                	sd	s1,120(sp)
ffffffffc020063e:	f0d2                	sd	s4,96(sp)
ffffffffc0200640:	ecd6                	sd	s5,88(sp)
ffffffffc0200642:	e8da                	sd	s6,80(sp)
ffffffffc0200644:	e4de                	sd	s7,72(sp)
ffffffffc0200646:	e0e2                	sd	s8,64(sp)
ffffffffc0200648:	f86a                	sd	s10,48(sp)
ffffffffc020064a:	f46e                	sd	s11,40(sp)
    while (power < n) {
ffffffffc020064c:	4505                	li	a0,1
    cprintf("buddy_system: freeing %u pages (order %u) at page %ld\n",
ffffffffc020064e:	033786b3          	mul	a3,a5,s3
ffffffffc0200652:	2581                	sext.w	a1,a1
    SetPageReserved(current);
ffffffffc0200654:	00366613          	ori	a2,a2,3
    while (power < n) {
ffffffffc0200658:	1ae57b63          	bgeu	a0,a4,ffffffffc020080e <buddy_system_free_pages.part.0+0x1fe>
    size_t power = 1;
ffffffffc020065c:	4785                	li	a5,1
        power <<= 1;
ffffffffc020065e:	0786                	slli	a5,a5,0x1
    while (power < n) {
ffffffffc0200660:	fee7efe3          	bltu	a5,a4,ffffffffc020065e <buddy_system_free_pages.part.0+0x4e>
    unsigned int order = 0;
ffffffffc0200664:	4401                	li	s0,0
    while (n > 1) {
ffffffffc0200666:	4705                	li	a4,1
        n >>= 1;
ffffffffc0200668:	8385                	srli	a5,a5,0x1
        order++;
ffffffffc020066a:	2405                	addiw	s0,s0,1
    while (n > 1) {
ffffffffc020066c:	fee79ee3          	bne	a5,a4,ffffffffc0200668 <buddy_system_free_pages.part.0+0x58>
    if (order > MAX_ORDER) {
ffffffffc0200670:	47bd                	li	a5,15
ffffffffc0200672:	84a2                	mv	s1,s0
ffffffffc0200674:	1687ee63          	bltu	a5,s0,ffffffffc02007f0 <buddy_system_free_pages.part.0+0x1e0>
ffffffffc0200678:	00048a1b          	sext.w	s4,s1
    SetPageReserved(current);
ffffffffc020067c:	00ccb423          	sd	a2,8(s9)
    current->property = order;
ffffffffc0200680:	009ca823          	sw	s1,16(s9)
    cprintf("buddy_system: freeing %u pages (order %u) at page %ld\n",
ffffffffc0200684:	8652                	mv	a2,s4
ffffffffc0200686:	00002517          	auipc	a0,0x2
ffffffffc020068a:	a7250513          	addi	a0,a0,-1422 # ffffffffc02020f8 <etext+0x292>
ffffffffc020068e:	abfff0ef          	jal	ra,ffffffffc020014c <cprintf>
    while (order < MAX_ORDER && merge_count < MAX_ORDER) {
ffffffffc0200692:	47b9                	li	a5,14
ffffffffc0200694:	1887ec63          	bltu	a5,s0,ffffffffc020082c <buddy_system_free_pages.part.0+0x21c>
ffffffffc0200698:	020a1793          	slli	a5,s4,0x20
ffffffffc020069c:	001a049b          	addiw	s1,s4,1
ffffffffc02006a0:	9381                	srli	a5,a5,0x20
ffffffffc02006a2:	1482                	slli	s1,s1,0x20
ffffffffc02006a4:	00479413          	slli	s0,a5,0x4
ffffffffc02006a8:	9081                	srli	s1,s1,0x20
ffffffffc02006aa:	00007d97          	auipc	s11,0x7
ffffffffc02006ae:	96ed8d93          	addi	s11,s11,-1682 # ffffffffc0207018 <buddy_sys>
ffffffffc02006b2:	0421                	addi	s0,s0,8
ffffffffc02006b4:	8c9d                	sub	s1,s1,a5
ffffffffc02006b6:	4b05                	li	s6,1
    cprintf("buddy_system: freeing %u pages (order %u) at page %ld\n",
ffffffffc02006b8:	85d2                	mv	a1,s4
ffffffffc02006ba:	946e                	add	s0,s0,s11
ffffffffc02006bc:	0492                	slli	s1,s1,0x4
ffffffffc02006be:	00007a97          	auipc	s5,0x7
ffffffffc02006c2:	a82a8a93          	addi	s5,s5,-1406 # ffffffffc0207140 <npage>
ffffffffc02006c6:	414b0a3b          	subw	s4,s6,s4
        cprintf("buddy_system: merged two order %u blocks -> one order %u block\n",
ffffffffc02006ca:	00002c17          	auipc	s8,0x2
ffffffffc02006ce:	adec0c13          	addi	s8,s8,-1314 # ffffffffc02021a8 <etext+0x342>
    size_t page_idx = page - pages;
ffffffffc02006d2:	00093683          	ld	a3,0(s2)
    if (buddy_idx >= npage) {
ffffffffc02006d6:	000ab503          	ld	a0,0(s5)
    size_t buddy_idx = page_idx ^ (1 << order);
ffffffffc02006da:	00bb163b          	sllw	a2,s6,a1
    size_t page_idx = page - pages;
ffffffffc02006de:	40dc87b3          	sub	a5,s9,a3
ffffffffc02006e2:	878d                	srai	a5,a5,0x3
ffffffffc02006e4:	033787b3          	mul	a5,a5,s3
ffffffffc02006e8:	00ba073b          	addw	a4,s4,a1
ffffffffc02006ec:	e43a                	sd	a4,8(sp)
    size_t buddy_idx = page_idx ^ (1 << order);
ffffffffc02006ee:	8d32                	mv	s10,a2
        list_entry_t* le = &buddy_sys.free_array[order];
ffffffffc02006f0:	88a2                	mv	a7,s0
    size_t buddy_idx = page_idx ^ (1 << order);
ffffffffc02006f2:	8fb1                	xor	a5,a5,a2
    if (buddy_idx >= npage) {
ffffffffc02006f4:	04a7fc63          	bgeu	a5,a0,ffffffffc020074c <buddy_system_free_pages.part.0+0x13c>
    return &pages[buddy_idx];
ffffffffc02006f8:	00279713          	slli	a4,a5,0x2
ffffffffc02006fc:	973e                	add	a4,a4,a5
ffffffffc02006fe:	070e                	slli	a4,a4,0x3
ffffffffc0200700:	9736                	add	a4,a4,a3
        if (!buddy) break;
ffffffffc0200702:	c729                	beqz	a4,ffffffffc020074c <buddy_system_free_pages.part.0+0x13c>
        if (!PageProperty(buddy)) break;
ffffffffc0200704:	00873303          	ld	t1,8(a4)
ffffffffc0200708:	00237793          	andi	a5,t1,2
ffffffffc020070c:	c3a1                	beqz	a5,ffffffffc020074c <buddy_system_free_pages.part.0+0x13c>
        if (buddy->property != order) break;
ffffffffc020070e:	4b1c                	lw	a5,16(a4)
ffffffffc0200710:	02b79e63          	bne	a5,a1,ffffffffc020074c <buddy_system_free_pages.part.0+0x13c>
        if (buddy < pages || buddy >= pages + npage) break;
ffffffffc0200714:	02d76c63          	bltu	a4,a3,ffffffffc020074c <buddy_system_free_pages.part.0+0x13c>
ffffffffc0200718:	00251793          	slli	a5,a0,0x2
ffffffffc020071c:	97aa                	add	a5,a5,a0
ffffffffc020071e:	078e                	slli	a5,a5,0x3
ffffffffc0200720:	97b6                	add	a5,a5,a3
ffffffffc0200722:	02f77563          	bgeu	a4,a5,ffffffffc020074c <buddy_system_free_pages.part.0+0x13c>
        if (!PageReserved(buddy)) break;
ffffffffc0200726:	00137313          	andi	t1,t1,1
ffffffffc020072a:	02030163          	beqz	t1,ffffffffc020074c <buddy_system_free_pages.part.0+0x13c>
        list_entry_t* temp = le->next;
ffffffffc020072e:	641c                	ld	a5,8(s0)
        while (temp != le) {
ffffffffc0200730:	00878e63          	beq	a5,s0,ffffffffc020074c <buddy_system_free_pages.part.0+0x13c>
            if (le2page(temp, page_link) == buddy) {
ffffffffc0200734:	fe878693          	addi	a3,a5,-24
ffffffffc0200738:	00d71563          	bne	a4,a3,ffffffffc0200742 <buddy_system_free_pages.part.0+0x132>
ffffffffc020073c:	a0ad                	j	ffffffffc02007a6 <buddy_system_free_pages.part.0+0x196>
ffffffffc020073e:	06d70463          	beq	a4,a3,ffffffffc02007a6 <buddy_system_free_pages.part.0+0x196>
            temp = temp->next;
ffffffffc0200742:	679c                	ld	a5,8(a5)
            if (le2page(temp, page_link) == buddy) {
ffffffffc0200744:	fe878693          	addi	a3,a5,-24
        while (temp != le) {
ffffffffc0200748:	fe879be3          	bne	a5,s0,ffffffffc020073e <buddy_system_free_pages.part.0+0x12e>
    buddy_sys.nr_free += (1 << order);
ffffffffc020074c:	0006079b          	sext.w	a5,a2
    if (merge_count >= MAX_ORDER) {
ffffffffc0200750:	66a2                	ld	a3,8(sp)
ffffffffc0200752:	473d                	li	a4,15
ffffffffc0200754:	0ae68063          	beq	a3,a4,ffffffffc02007f4 <buddy_system_free_pages.part.0+0x1e4>
 * Insert the new element @elm *after* the element @listelm which
 * is already in the list.
 * */
static inline void
list_add_after(list_entry_t *listelm, list_entry_t *elm) {
    __list_add(elm, listelm, listelm->next);
ffffffffc0200758:	02059713          	slli	a4,a1,0x20
ffffffffc020075c:	01c75593          	srli	a1,a4,0x1c
ffffffffc0200760:	95ee                	add	a1,a1,s11
ffffffffc0200762:	6998                	ld	a4,16(a1)
    buddy_sys.nr_free += (1 << order);
ffffffffc0200764:	108da603          	lw	a2,264(s11)
    list_add(&buddy_sys.free_array[order], &(current->page_link));
ffffffffc0200768:	018c8693          	addi	a3,s9,24
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc020076c:	e314                	sd	a3,0(a4)
ffffffffc020076e:	e994                	sd	a3,16(a1)
    elm->next = next;
ffffffffc0200770:	02ecb023          	sd	a4,32(s9)
    elm->prev = prev;
ffffffffc0200774:	011cbc23          	sd	a7,24(s9)
}
ffffffffc0200778:	640a                	ld	s0,128(sp)
    buddy_sys.nr_free += (1 << order);
ffffffffc020077a:	00f605bb          	addw	a1,a2,a5
}
ffffffffc020077e:	60aa                	ld	ra,136(sp)
ffffffffc0200780:	74e6                	ld	s1,120(sp)
ffffffffc0200782:	7946                	ld	s2,112(sp)
ffffffffc0200784:	79a6                	ld	s3,104(sp)
ffffffffc0200786:	7a06                	ld	s4,96(sp)
ffffffffc0200788:	6ae6                	ld	s5,88(sp)
ffffffffc020078a:	6b46                	ld	s6,80(sp)
ffffffffc020078c:	6ba6                	ld	s7,72(sp)
ffffffffc020078e:	6c06                	ld	s8,64(sp)
ffffffffc0200790:	7ce2                	ld	s9,56(sp)
ffffffffc0200792:	7d42                	ld	s10,48(sp)
    buddy_sys.nr_free += (1 << order);
ffffffffc0200794:	10bda423          	sw	a1,264(s11)
}
ffffffffc0200798:	7da2                	ld	s11,40(sp)
    cprintf("buddy_system: freed successfully, total free: %u pages\n", buddy_sys.nr_free);
ffffffffc020079a:	00002517          	auipc	a0,0x2
ffffffffc020079e:	9d650513          	addi	a0,a0,-1578 # ffffffffc0202170 <etext+0x30a>
}
ffffffffc02007a2:	6149                	addi	sp,sp,144
    cprintf("buddy_system: freed successfully, total free: %u pages\n", buddy_sys.nr_free);
ffffffffc02007a4:	b265                	j	ffffffffc020014c <cprintf>
    __list_del(listelm->prev, listelm->next);
ffffffffc02007a6:	6f14                	ld	a3,24(a4)
ffffffffc02007a8:	731c                	ld	a5,32(a4)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc02007aa:	e69c                	sd	a5,8(a3)
    next->prev = prev;
ffffffffc02007ac:	e394                	sd	a3,0(a5)
        if (current > buddy) {
ffffffffc02007ae:	01977363          	bgeu	a4,s9,ffffffffc02007b4 <buddy_system_free_pages.part.0+0x1a4>
ffffffffc02007b2:	8cba                	mv	s9,a4
        SetPageReserved(current);
ffffffffc02007b4:	008cb783          	ld	a5,8(s9)
        order++;
ffffffffc02007b8:	00158b9b          	addiw	s7,a1,1
        current->property = order;
ffffffffc02007bc:	017ca823          	sw	s7,16(s9)
        SetPageReserved(current);
ffffffffc02007c0:	0017e793          	ori	a5,a5,1
ffffffffc02007c4:	00fcb423          	sd	a5,8(s9)
        cprintf("buddy_system: merged two order %u blocks -> one order %u block\n",
ffffffffc02007c8:	865e                	mv	a2,s7
ffffffffc02007ca:	8562                	mv	a0,s8
ffffffffc02007cc:	981ff0ef          	jal	ra,ffffffffc020014c <cprintf>
        buddy_sys.nr_free -= (1 << (order - 1)); // 移除被合并的块
ffffffffc02007d0:	108da703          	lw	a4,264(s11)
    buddy_sys.nr_free += (1 << order);
ffffffffc02007d4:	017b17bb          	sllw	a5,s6,s7
ffffffffc02007d8:	008488b3          	add	a7,s1,s0
        buddy_sys.nr_free -= (1 << (order - 1)); // 移除被合并的块
ffffffffc02007dc:	41a70d3b          	subw	s10,a4,s10
ffffffffc02007e0:	11ada423          	sw	s10,264(s11)
    while (order < MAX_ORDER && merge_count < MAX_ORDER) {
ffffffffc02007e4:	4739                	li	a4,14
ffffffffc02007e6:	05776163          	bltu	a4,s7,ffffffffc0200828 <buddy_system_free_pages.part.0+0x218>
ffffffffc02007ea:	0441                	addi	s0,s0,16
ffffffffc02007ec:	85de                	mv	a1,s7
ffffffffc02007ee:	b5d5                	j	ffffffffc02006d2 <buddy_system_free_pages.part.0+0xc2>
ffffffffc02007f0:	44bd                	li	s1,15
ffffffffc02007f2:	b559                	j	ffffffffc0200678 <buddy_system_free_pages.part.0+0x68>
        cprintf("buddy_system: warning, merge loop reached maximum iterations\n");
ffffffffc02007f4:	00002517          	auipc	a0,0x2
ffffffffc02007f8:	93c50513          	addi	a0,a0,-1732 # ffffffffc0202130 <etext+0x2ca>
ffffffffc02007fc:	ec3e                	sd	a5,24(sp)
ffffffffc02007fe:	e846                	sd	a7,16(sp)
ffffffffc0200800:	e42e                	sd	a1,8(sp)
ffffffffc0200802:	94bff0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc0200806:	67e2                	ld	a5,24(sp)
ffffffffc0200808:	68c2                	ld	a7,16(sp)
ffffffffc020080a:	65a2                	ld	a1,8(sp)
ffffffffc020080c:	b7b1                	j	ffffffffc0200758 <buddy_system_free_pages.part.0+0x148>
    SetPageReserved(current);
ffffffffc020080e:	00ccb423          	sd	a2,8(s9)
    current->property = order;
ffffffffc0200812:	000ca823          	sw	zero,16(s9)
    cprintf("buddy_system: freeing %u pages (order %u) at page %ld\n",
ffffffffc0200816:	4601                	li	a2,0
ffffffffc0200818:	00002517          	auipc	a0,0x2
ffffffffc020081c:	8e050513          	addi	a0,a0,-1824 # ffffffffc02020f8 <etext+0x292>
ffffffffc0200820:	92dff0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc0200824:	4a01                	li	s4,0
ffffffffc0200826:	bd8d                	j	ffffffffc0200698 <buddy_system_free_pages.part.0+0x88>
ffffffffc0200828:	85de                	mv	a1,s7
ffffffffc020082a:	b71d                	j	ffffffffc0200750 <buddy_system_free_pages.part.0+0x140>
        list_entry_t* le = &buddy_sys.free_array[order];
ffffffffc020082c:	02049793          	slli	a5,s1,0x20
ffffffffc0200830:	01c7d893          	srli	a7,a5,0x1c
ffffffffc0200834:	00006d97          	auipc	s11,0x6
ffffffffc0200838:	7e4d8d93          	addi	s11,s11,2020 # ffffffffc0207018 <buddy_sys>
ffffffffc020083c:	08a1                	addi	a7,a7,8
        buddy_sys.nr_free -= (1 << (order - 1)); // 移除被合并的块
ffffffffc020083e:	4785                	li	a5,1
        list_entry_t* le = &buddy_sys.free_array[order];
ffffffffc0200840:	98ee                	add	a7,a7,s11
        buddy_sys.nr_free -= (1 << (order - 1)); // 移除被合并的块
ffffffffc0200842:	014797bb          	sllw	a5,a5,s4
ffffffffc0200846:	85d2                	mv	a1,s4
ffffffffc0200848:	bf01                	j	ffffffffc0200758 <buddy_system_free_pages.part.0+0x148>

ffffffffc020084a <buddy_system_free_pages>:
    assert(n > 0);
ffffffffc020084a:	c191                	beqz	a1,ffffffffc020084e <buddy_system_free_pages+0x4>
ffffffffc020084c:	b3d1                	j	ffffffffc0200610 <buddy_system_free_pages.part.0>
buddy_system_free_pages(struct Page* base, size_t n) {
ffffffffc020084e:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc0200850:	00002697          	auipc	a3,0x2
ffffffffc0200854:	99868693          	addi	a3,a3,-1640 # ffffffffc02021e8 <etext+0x382>
ffffffffc0200858:	00002617          	auipc	a2,0x2
ffffffffc020085c:	99860613          	addi	a2,a2,-1640 # ffffffffc02021f0 <etext+0x38a>
ffffffffc0200860:	0ee00593          	li	a1,238
ffffffffc0200864:	00002517          	auipc	a0,0x2
ffffffffc0200868:	9a450513          	addi	a0,a0,-1628 # ffffffffc0202208 <etext+0x3a2>
buddy_system_free_pages(struct Page* base, size_t n) {
ffffffffc020086c:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc020086e:	955ff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc0200872 <buddy_system_alloc_pages.part.0>:
static struct Page* buddy_system_alloc_pages(size_t n) {
ffffffffc0200872:	711d                	addi	sp,sp,-96
ffffffffc0200874:	f05a                	sd	s6,32(sp)
ffffffffc0200876:	ec86                	sd	ra,88(sp)
ffffffffc0200878:	e8a2                	sd	s0,80(sp)
ffffffffc020087a:	e4a6                	sd	s1,72(sp)
ffffffffc020087c:	e0ca                	sd	s2,64(sp)
ffffffffc020087e:	fc4e                	sd	s3,56(sp)
ffffffffc0200880:	f852                	sd	s4,48(sp)
ffffffffc0200882:	f456                	sd	s5,40(sp)
ffffffffc0200884:	ec5e                	sd	s7,24(sp)
ffffffffc0200886:	e862                	sd	s8,16(sp)
ffffffffc0200888:	e466                	sd	s9,8(sp)
    while (power < n) {
ffffffffc020088a:	4785                	li	a5,1
static struct Page* buddy_system_alloc_pages(size_t n) {
ffffffffc020088c:	8b2a                	mv	s6,a0
    while (power < n) {
ffffffffc020088e:	1aa7fd63          	bgeu	a5,a0,ffffffffc0200a48 <buddy_system_alloc_pages.part.0+0x1d6>
        power <<= 1;
ffffffffc0200892:	0786                	slli	a5,a5,0x1
    while (power < n) {
ffffffffc0200894:	ff67efe3          	bltu	a5,s6,ffffffffc0200892 <buddy_system_alloc_pages.part.0+0x20>
    unsigned int order = 0;
ffffffffc0200898:	4a81                	li	s5,0
    while (n > 1) {
ffffffffc020089a:	4705                	li	a4,1
        n >>= 1;
ffffffffc020089c:	8385                	srli	a5,a5,0x1
        order++;
ffffffffc020089e:	2a85                	addiw	s5,s5,1
    while (n > 1) {
ffffffffc02008a0:	fee79ee3          	bne	a5,a4,ffffffffc020089c <buddy_system_alloc_pages.part.0+0x2a>
    if (required_order > MAX_ORDER) {
ffffffffc02008a4:	47bd                	li	a5,15
ffffffffc02008a6:	1b57e363          	bltu	a5,s5,ffffffffc0200a4c <buddy_system_alloc_pages.part.0+0x1da>
ffffffffc02008aa:	020a9913          	slli	s2,s5,0x20
ffffffffc02008ae:	02095913          	srli	s2,s2,0x20
ffffffffc02008b2:	00491693          	slli	a3,s2,0x4
ffffffffc02008b6:	00006b97          	auipc	s7,0x6
ffffffffc02008ba:	762b8b93          	addi	s7,s7,1890 # ffffffffc0207018 <buddy_sys>
ffffffffc02008be:	06a1                	addi	a3,a3,8
ffffffffc02008c0:	96de                	add	a3,a3,s7
    unsigned int order = 0;
ffffffffc02008c2:	85d6                	mv	a1,s5
    while (current_order <= MAX_ORDER) {
ffffffffc02008c4:	4641                	li	a2,16
    return list->next == list;
ffffffffc02008c6:	02059993          	slli	s3,a1,0x20
ffffffffc02008ca:	0209d993          	srli	s3,s3,0x20
ffffffffc02008ce:	00499793          	slli	a5,s3,0x4
ffffffffc02008d2:	97de                	add	a5,a5,s7
ffffffffc02008d4:	6b98                	ld	a4,16(a5)
        if (!list_empty(&buddy_sys.free_array[current_order])) {
ffffffffc02008d6:	00d71e63          	bne	a4,a3,ffffffffc02008f2 <buddy_system_alloc_pages.part.0+0x80>
        current_order++;
ffffffffc02008da:	2585                	addiw	a1,a1,1
    while (current_order <= MAX_ORDER) {
ffffffffc02008dc:	06c1                	addi	a3,a3,16
ffffffffc02008de:	fec594e3          	bne	a1,a2,ffffffffc02008c6 <buddy_system_alloc_pages.part.0+0x54>
        cprintf("buddy_system: allocation failed, no suitable block found\n");
ffffffffc02008e2:	00002517          	auipc	a0,0x2
ffffffffc02008e6:	a0e50513          	addi	a0,a0,-1522 # ffffffffc02022f0 <etext+0x48a>
ffffffffc02008ea:	863ff0ef          	jal	ra,ffffffffc020014c <cprintf>
        return NULL;
ffffffffc02008ee:	4401                	li	s0,0
ffffffffc02008f0:	aa35                	j	ffffffffc0200a2c <buddy_system_alloc_pages.part.0+0x1ba>
    buddy_sys.nr_free -= (1 << order);
ffffffffc02008f2:	108ba303          	lw	t1,264(s7)
    while (current_order > required_order) {
ffffffffc02008f6:	0cbafb63          	bgeu	s5,a1,ffffffffc02009cc <buddy_system_alloc_pages.part.0+0x15a>
ffffffffc02008fa:	fff5889b          	addiw	a7,a1,-1
ffffffffc02008fe:	02089793          	slli	a5,a7,0x20
ffffffffc0200902:	9381                	srli	a5,a5,0x20
ffffffffc0200904:	00479413          	slli	s0,a5,0x4
ffffffffc0200908:	0421                	addi	s0,s0,8
ffffffffc020090a:	40f989b3          	sub	s3,s3,a5
ffffffffc020090e:	945e                	add	s0,s0,s7
ffffffffc0200910:	0992                	slli	s3,s3,0x4
    size_t block_size = 1 << new_order;
ffffffffc0200912:	4c05                	li	s8,1
    buddy_sys.nr_free += (2 << new_order);  // 添加两个块
ffffffffc0200914:	4a09                	li	s4,2
    cprintf("buddy_system: split order %u -> two order %u blocks\n", order, new_order);
ffffffffc0200916:	00002c97          	auipc	s9,0x2
ffffffffc020091a:	962c8c93          	addi	s9,s9,-1694 # ffffffffc0202278 <etext+0x412>
ffffffffc020091e:	a021                	j	ffffffffc0200926 <buddy_system_alloc_pages.part.0+0xb4>
ffffffffc0200920:	6c18                	ld	a4,24(s0)
ffffffffc0200922:	fff4889b          	addiw	a7,s1,-1
    assert(order > 0 && order <= MAX_ORDER);
ffffffffc0200926:	0008849b          	sext.w	s1,a7
    size_t block_size = 1 << new_order;
ffffffffc020092a:	009c183b          	sllw	a6,s8,s1
    struct Page* right = page + block_size;
ffffffffc020092e:	00281793          	slli	a5,a6,0x2
ffffffffc0200932:	97c2                	add	a5,a5,a6
ffffffffc0200934:	078e                	slli	a5,a5,0x3
    buddy_sys.nr_free -= (1 << order);
ffffffffc0200936:	00bc1ebb          	sllw	t4,s8,a1
    struct Page* right = page + block_size;
ffffffffc020093a:	17a1                	addi	a5,a5,-24
    buddy_sys.nr_free += (2 << new_order);  // 添加两个块
ffffffffc020093c:	009a163b          	sllw	a2,s4,s1
ffffffffc0200940:	41d6063b          	subw	a2,a2,t4
    struct Page* right = page + block_size;
ffffffffc0200944:	97ba                	add	a5,a5,a4
    if (list_empty(&buddy_sys.free_array[order])) {
ffffffffc0200946:	008986b3          	add	a3,s3,s0
    buddy_sys.nr_free += (2 << new_order);  // 添加两个块
ffffffffc020094a:	0066083b          	addw	a6,a2,t1
    cprintf("buddy_system: split order %u -> two order %u blocks\n", order, new_order);
ffffffffc020094e:	8566                	mv	a0,s9
    list_add(&buddy_sys.free_array[new_order], &(right->page_link));
ffffffffc0200950:	01878e13          	addi	t3,a5,24
    cprintf("buddy_system: split order %u -> two order %u blocks\n", order, new_order);
ffffffffc0200954:	8626                	mv	a2,s1
    if (list_empty(&buddy_sys.free_array[order])) {
ffffffffc0200956:	06d70763          	beq	a4,a3,ffffffffc02009c4 <buddy_system_alloc_pages.part.0+0x152>
    __list_del(listelm->prev, listelm->next);
ffffffffc020095a:	00073e83          	ld	t4,0(a4)
ffffffffc020095e:	00873303          	ld	t1,8(a4)
    SetPageProperty(left);
ffffffffc0200962:	ff073683          	ld	a3,-16(a4)
    prev->next = next;
ffffffffc0200966:	006eb423          	sd	t1,8(t4)
    next->prev = prev;
ffffffffc020096a:	01d33023          	sd	t4,0(t1)
    left->property = new_order;
ffffffffc020096e:	ff172c23          	sw	a7,-8(a4)
    right->property = new_order;
ffffffffc0200972:	0117a823          	sw	a7,16(a5)
    SetPageProperty(left);
ffffffffc0200976:	0026e693          	ori	a3,a3,2
ffffffffc020097a:	fed73823          	sd	a3,-16(a4)
    SetPageProperty(right);
ffffffffc020097e:	6794                	ld	a3,8(a5)
    __list_add(elm, listelm, listelm->next);
ffffffffc0200980:	00843883          	ld	a7,8(s0)
ffffffffc0200984:	0026e693          	ori	a3,a3,2
ffffffffc0200988:	e794                	sd	a3,8(a5)
    SetPageReserved(left);
ffffffffc020098a:	ff073683          	ld	a3,-16(a4)
ffffffffc020098e:	0016e693          	ori	a3,a3,1
ffffffffc0200992:	fed73823          	sd	a3,-16(a4)
    SetPageReserved(right);
ffffffffc0200996:	6794                	ld	a3,8(a5)
ffffffffc0200998:	0016e693          	ori	a3,a3,1
ffffffffc020099c:	e794                	sd	a3,8(a5)
    prev->next = next->prev = elm;
ffffffffc020099e:	00e8b023          	sd	a4,0(a7)
ffffffffc02009a2:	e418                	sd	a4,8(s0)
    elm->prev = prev;
ffffffffc02009a4:	e300                	sd	s0,0(a4)
    elm->next = next;
ffffffffc02009a6:	01173423          	sd	a7,8(a4)
    __list_add(elm, listelm, listelm->next);
ffffffffc02009aa:	6418                	ld	a4,8(s0)
    prev->next = next->prev = elm;
ffffffffc02009ac:	01c73023          	sd	t3,0(a4)
ffffffffc02009b0:	01c43423          	sd	t3,8(s0)
    elm->prev = prev;
ffffffffc02009b4:	ef80                	sd	s0,24(a5)
    elm->next = next;
ffffffffc02009b6:	f398                	sd	a4,32(a5)
    buddy_sys.nr_free += (2 << new_order);  // 添加两个块
ffffffffc02009b8:	110ba423          	sw	a6,264(s7)
    cprintf("buddy_system: split order %u -> two order %u blocks\n", order, new_order);
ffffffffc02009bc:	f90ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    buddy_sys.nr_free -= (1 << required_order);
ffffffffc02009c0:	108ba303          	lw	t1,264(s7)
    return list->next == list;
ffffffffc02009c4:	85a6                	mv	a1,s1
    while (current_order > required_order) {
ffffffffc02009c6:	1441                	addi	s0,s0,-16
ffffffffc02009c8:	f49a9ce3          	bne	s5,s1,ffffffffc0200920 <buddy_system_alloc_pages.part.0+0xae>
    return listelm->next;
ffffffffc02009cc:	0912                	slli	s2,s2,0x4
ffffffffc02009ce:	995e                	add	s2,s2,s7
ffffffffc02009d0:	01093783          	ld	a5,16(s2)
        (unsigned int)n, required_order, page - pages);
ffffffffc02009d4:	00006717          	auipc	a4,0x6
ffffffffc02009d8:	77473703          	ld	a4,1908(a4) # ffffffffc0207148 <pages>
    cprintf("buddy_system: allocated %u pages (order %u) at page %ld\n",
ffffffffc02009dc:	00003697          	auipc	a3,0x3
ffffffffc02009e0:	a646b683          	ld	a3,-1436(a3) # ffffffffc0203440 <error_string+0x38>
    struct Page* page = le2page(le, page_link);
ffffffffc02009e4:	fe878413          	addi	s0,a5,-24
        (unsigned int)n, required_order, page - pages);
ffffffffc02009e8:	40e40733          	sub	a4,s0,a4
    cprintf("buddy_system: allocated %u pages (order %u) at page %ld\n",
ffffffffc02009ec:	870d                	srai	a4,a4,0x3
ffffffffc02009ee:	02d706b3          	mul	a3,a4,a3
    __list_del(listelm->prev, listelm->next);
ffffffffc02009f2:	6388                	ld	a0,0(a5)
ffffffffc02009f4:	678c                	ld	a1,8(a5)
    ClearPageProperty(page);
ffffffffc02009f6:	ff07b703          	ld	a4,-16(a5)
    buddy_sys.nr_free -= (1 << required_order);
ffffffffc02009fa:	4605                	li	a2,1
    prev->next = next;
ffffffffc02009fc:	e50c                	sd	a1,8(a0)
ffffffffc02009fe:	0156163b          	sllw	a2,a2,s5
    next->prev = prev;
ffffffffc0200a02:	e188                	sd	a0,0(a1)
ffffffffc0200a04:	40c3033b          	subw	t1,t1,a2
    ClearPageProperty(page);
ffffffffc0200a08:	9b75                	andi	a4,a4,-3
    buddy_sys.nr_free -= (1 << required_order);
ffffffffc0200a0a:	106ba423          	sw	t1,264(s7)
    SetPageReserved(page);
ffffffffc0200a0e:	00176713          	ori	a4,a4,1
    page->property = 0;
ffffffffc0200a12:	fe07ac23          	sw	zero,-8(a5)
    SetPageReserved(page);
ffffffffc0200a16:	fee7b823          	sd	a4,-16(a5)
    cprintf("buddy_system: allocated %u pages (order %u) at page %ld\n",
ffffffffc0200a1a:	8656                	mv	a2,s5
ffffffffc0200a1c:	000b059b          	sext.w	a1,s6
ffffffffc0200a20:	00002517          	auipc	a0,0x2
ffffffffc0200a24:	89050513          	addi	a0,a0,-1904 # ffffffffc02022b0 <etext+0x44a>
ffffffffc0200a28:	f24ff0ef          	jal	ra,ffffffffc020014c <cprintf>
}
ffffffffc0200a2c:	60e6                	ld	ra,88(sp)
ffffffffc0200a2e:	8522                	mv	a0,s0
ffffffffc0200a30:	6446                	ld	s0,80(sp)
ffffffffc0200a32:	64a6                	ld	s1,72(sp)
ffffffffc0200a34:	6906                	ld	s2,64(sp)
ffffffffc0200a36:	79e2                	ld	s3,56(sp)
ffffffffc0200a38:	7a42                	ld	s4,48(sp)
ffffffffc0200a3a:	7aa2                	ld	s5,40(sp)
ffffffffc0200a3c:	7b02                	ld	s6,32(sp)
ffffffffc0200a3e:	6be2                	ld	s7,24(sp)
ffffffffc0200a40:	6c42                	ld	s8,16(sp)
ffffffffc0200a42:	6ca2                	ld	s9,8(sp)
ffffffffc0200a44:	6125                	addi	sp,sp,96
ffffffffc0200a46:	8082                	ret
    unsigned int order = 0;
ffffffffc0200a48:	4a81                	li	s5,0
ffffffffc0200a4a:	b585                	j	ffffffffc02008aa <buddy_system_alloc_pages.part.0+0x38>
        cprintf("buddy_system: allocation failed, required order %u exceeds max order %u\n",
ffffffffc0200a4c:	463d                	li	a2,15
ffffffffc0200a4e:	85d6                	mv	a1,s5
ffffffffc0200a50:	00001517          	auipc	a0,0x1
ffffffffc0200a54:	7d850513          	addi	a0,a0,2008 # ffffffffc0202228 <etext+0x3c2>
ffffffffc0200a58:	ef4ff0ef          	jal	ra,ffffffffc020014c <cprintf>
        return NULL;
ffffffffc0200a5c:	4401                	li	s0,0
ffffffffc0200a5e:	b7f9                	j	ffffffffc0200a2c <buddy_system_alloc_pages.part.0+0x1ba>

ffffffffc0200a60 <buddy_system_alloc_pages>:
static struct Page* buddy_system_alloc_pages(size_t n) {
ffffffffc0200a60:	1141                	addi	sp,sp,-16
ffffffffc0200a62:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0200a64:	c90d                	beqz	a0,ffffffffc0200a96 <buddy_system_alloc_pages+0x36>
    if (n > buddy_sys.nr_free) {
ffffffffc0200a66:	00006617          	auipc	a2,0x6
ffffffffc0200a6a:	6ba62603          	lw	a2,1722(a2) # ffffffffc0207120 <buddy_sys+0x108>
ffffffffc0200a6e:	02061793          	slli	a5,a2,0x20
ffffffffc0200a72:	9381                	srli	a5,a5,0x20
ffffffffc0200a74:	00a7e563          	bltu	a5,a0,ffffffffc0200a7e <buddy_system_alloc_pages+0x1e>
}
ffffffffc0200a78:	60a2                	ld	ra,8(sp)
ffffffffc0200a7a:	0141                	addi	sp,sp,16
ffffffffc0200a7c:	bbdd                	j	ffffffffc0200872 <buddy_system_alloc_pages.part.0>
        cprintf("buddy_system: allocation failed, request %u pages, but only %u free\n",
ffffffffc0200a7e:	0005059b          	sext.w	a1,a0
ffffffffc0200a82:	00002517          	auipc	a0,0x2
ffffffffc0200a86:	8ae50513          	addi	a0,a0,-1874 # ffffffffc0202330 <etext+0x4ca>
ffffffffc0200a8a:	ec2ff0ef          	jal	ra,ffffffffc020014c <cprintf>
}
ffffffffc0200a8e:	60a2                	ld	ra,8(sp)
ffffffffc0200a90:	4501                	li	a0,0
ffffffffc0200a92:	0141                	addi	sp,sp,16
ffffffffc0200a94:	8082                	ret
    assert(n > 0);
ffffffffc0200a96:	00001697          	auipc	a3,0x1
ffffffffc0200a9a:	75268693          	addi	a3,a3,1874 # ffffffffc02021e8 <etext+0x382>
ffffffffc0200a9e:	00001617          	auipc	a2,0x1
ffffffffc0200aa2:	75260613          	addi	a2,a2,1874 # ffffffffc02021f0 <etext+0x38a>
ffffffffc0200aa6:	0b100593          	li	a1,177
ffffffffc0200aaa:	00001517          	auipc	a0,0x1
ffffffffc0200aae:	75e50513          	addi	a0,a0,1886 # ffffffffc0202208 <etext+0x3a2>
ffffffffc0200ab2:	f10ff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc0200ab6 <buddy_system_init_memmap>:
static void buddy_system_init_memmap(struct Page* base, size_t n) {
ffffffffc0200ab6:	1101                	addi	sp,sp,-32
ffffffffc0200ab8:	ec06                	sd	ra,24(sp)
ffffffffc0200aba:	e822                	sd	s0,16(sp)
ffffffffc0200abc:	e426                	sd	s1,8(sp)
    assert(n > 0);
ffffffffc0200abe:	c5fd                	beqz	a1,ffffffffc0200bac <buddy_system_init_memmap+0xf6>
    cprintf("buddy_system_init_memmap: base=%p, n=%u\n", base, (unsigned int)n);
ffffffffc0200ac0:	842e                	mv	s0,a1
ffffffffc0200ac2:	84aa                	mv	s1,a0
ffffffffc0200ac4:	0005861b          	sext.w	a2,a1
ffffffffc0200ac8:	85aa                	mv	a1,a0
ffffffffc0200aca:	00002517          	auipc	a0,0x2
ffffffffc0200ace:	8ae50513          	addi	a0,a0,-1874 # ffffffffc0202378 <etext+0x512>
ffffffffc0200ad2:	e7aff0ef          	jal	ra,ffffffffc020014c <cprintf>
    for (struct Page* p = base; p != base + n; p++) {
ffffffffc0200ad6:	00241693          	slli	a3,s0,0x2
ffffffffc0200ada:	96a2                	add	a3,a3,s0
ffffffffc0200adc:	068e                	slli	a3,a3,0x3
ffffffffc0200ade:	96a6                	add	a3,a3,s1
ffffffffc0200ae0:	87a6                	mv	a5,s1
        SetPageReserved(p);
ffffffffc0200ae2:	460d                	li	a2,3
    for (struct Page* p = base; p != base + n; p++) {
ffffffffc0200ae4:	00d48e63          	beq	s1,a3,ffffffffc0200b00 <buddy_system_init_memmap+0x4a>
        assert(PageReserved(p));
ffffffffc0200ae8:	6798                	ld	a4,8(a5)
ffffffffc0200aea:	8b05                	andi	a4,a4,1
ffffffffc0200aec:	c345                	beqz	a4,ffffffffc0200b8c <buddy_system_init_memmap+0xd6>
        p->flags = p->property = 0;
ffffffffc0200aee:	0007a823          	sw	zero,16(a5)



static inline int page_ref(struct Page *page) { return page->ref; }

static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0200af2:	0007a023          	sw	zero,0(a5)
        SetPageReserved(p);
ffffffffc0200af6:	e790                	sd	a2,8(a5)
    for (struct Page* p = base; p != base + n; p++) {
ffffffffc0200af8:	02878793          	addi	a5,a5,40
ffffffffc0200afc:	fed796e3          	bne	a5,a3,ffffffffc0200ae8 <buddy_system_init_memmap+0x32>
    size_t block_size = 1;
ffffffffc0200b00:	4605                	li	a2,1
    unsigned int order = 0;
ffffffffc0200b02:	4581                	li	a1,0
    while (order < MAX_ORDER && (block_size << 1) <= total_pages) {
ffffffffc0200b04:	47bd                	li	a5,15
ffffffffc0200b06:	8732                	mv	a4,a2
ffffffffc0200b08:	0606                	slli	a2,a2,0x1
ffffffffc0200b0a:	06c46863          	bltu	s0,a2,ffffffffc0200b7a <buddy_system_init_memmap+0xc4>
        order++;
ffffffffc0200b0e:	2585                	addiw	a1,a1,1
    while (order < MAX_ORDER && (block_size << 1) <= total_pages) {
ffffffffc0200b10:	fef59be3          	bne	a1,a5,ffffffffc0200b06 <buddy_system_init_memmap+0x50>
ffffffffc0200b14:	02059793          	slli	a5,a1,0x20
ffffffffc0200b18:	0f800513          	li	a0,248
ffffffffc0200b1c:	9381                	srli	a5,a5,0x20
    SetPageProperty(base);
ffffffffc0200b1e:	0084b803          	ld	a6,8(s1)
    buddy_sys.max_order = order;
ffffffffc0200b22:	00006717          	auipc	a4,0x6
ffffffffc0200b26:	4f670713          	addi	a4,a4,1270 # ffffffffc0207018 <buddy_sys>
    __list_add(elm, listelm, listelm->next);
ffffffffc0200b2a:	0792                	slli	a5,a5,0x4
ffffffffc0200b2c:	97ba                	add	a5,a5,a4
ffffffffc0200b2e:	0107b883          	ld	a7,16(a5)
    buddy_sys.nr_free += block_size;
ffffffffc0200b32:	10872683          	lw	a3,264(a4)
    SetPageProperty(base);
ffffffffc0200b36:	00286813          	ori	a6,a6,2
ffffffffc0200b3a:	0104b423          	sd	a6,8(s1)
    base->property = order;
ffffffffc0200b3e:	c88c                	sw	a1,16(s1)
    list_add(&buddy_sys.free_array[order], &(base->page_link));
ffffffffc0200b40:	01848813          	addi	a6,s1,24
    buddy_sys.max_order = order;
ffffffffc0200b44:	c30c                	sw	a1,0(a4)
    prev->next = next->prev = elm;
ffffffffc0200b46:	0108b023          	sd	a6,0(a7)
ffffffffc0200b4a:	0107b823          	sd	a6,16(a5)
}
ffffffffc0200b4e:	6442                	ld	s0,16(sp)
    buddy_sys.nr_free += block_size;
ffffffffc0200b50:	00c687bb          	addw	a5,a3,a2
    list_add(&buddy_sys.free_array[order], &(base->page_link));
ffffffffc0200b54:	00a706b3          	add	a3,a4,a0
    elm->prev = prev;
ffffffffc0200b58:	ec94                	sd	a3,24(s1)
    elm->next = next;
ffffffffc0200b5a:	0314b023          	sd	a7,32(s1)
}
ffffffffc0200b5e:	60e2                	ld	ra,24(sp)
ffffffffc0200b60:	64a2                	ld	s1,8(sp)
    buddy_sys.nr_free += block_size;
ffffffffc0200b62:	10f72423          	sw	a5,264(a4)
    cprintf("buddy_system: added memory block of order %u (%u pages), total free: %u\n",
ffffffffc0200b66:	0007869b          	sext.w	a3,a5
ffffffffc0200b6a:	2601                	sext.w	a2,a2
ffffffffc0200b6c:	00002517          	auipc	a0,0x2
ffffffffc0200b70:	84c50513          	addi	a0,a0,-1972 # ffffffffc02023b8 <etext+0x552>
}
ffffffffc0200b74:	6105                	addi	sp,sp,32
    cprintf("buddy_system: added memory block of order %u (%u pages), total free: %u\n",
ffffffffc0200b76:	dd6ff06f          	j	ffffffffc020014c <cprintf>
ffffffffc0200b7a:	02059793          	slli	a5,a1,0x20
ffffffffc0200b7e:	9381                	srli	a5,a5,0x20
ffffffffc0200b80:	00479693          	slli	a3,a5,0x4
ffffffffc0200b84:	00868513          	addi	a0,a3,8
    while (order < MAX_ORDER && (block_size << 1) <= total_pages) {
ffffffffc0200b88:	863a                	mv	a2,a4
ffffffffc0200b8a:	bf51                	j	ffffffffc0200b1e <buddy_system_init_memmap+0x68>
        assert(PageReserved(p));
ffffffffc0200b8c:	00002697          	auipc	a3,0x2
ffffffffc0200b90:	81c68693          	addi	a3,a3,-2020 # ffffffffc02023a8 <etext+0x542>
ffffffffc0200b94:	00001617          	auipc	a2,0x1
ffffffffc0200b98:	65c60613          	addi	a2,a2,1628 # ffffffffc02021f0 <etext+0x38a>
ffffffffc0200b9c:	06800593          	li	a1,104
ffffffffc0200ba0:	00001517          	auipc	a0,0x1
ffffffffc0200ba4:	66850513          	addi	a0,a0,1640 # ffffffffc0202208 <etext+0x3a2>
ffffffffc0200ba8:	e1aff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(n > 0);
ffffffffc0200bac:	00001697          	auipc	a3,0x1
ffffffffc0200bb0:	63c68693          	addi	a3,a3,1596 # ffffffffc02021e8 <etext+0x382>
ffffffffc0200bb4:	00001617          	auipc	a2,0x1
ffffffffc0200bb8:	63c60613          	addi	a2,a2,1596 # ffffffffc02021f0 <etext+0x38a>
ffffffffc0200bbc:	06300593          	li	a1,99
ffffffffc0200bc0:	00001517          	auipc	a0,0x1
ffffffffc0200bc4:	64850513          	addi	a0,a0,1608 # ffffffffc0202208 <etext+0x3a2>
ffffffffc0200bc8:	dfaff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc0200bcc <show_buddy_array.constprop.0>:
static void show_buddy_array(unsigned int start_order, unsigned int end_order) {
ffffffffc0200bcc:	7139                	addi	sp,sp,-64
    cprintf("Buddy System Status (Total free: %u pages):\n", buddy_sys.nr_free);
ffffffffc0200bce:	00006597          	auipc	a1,0x6
ffffffffc0200bd2:	5525a583          	lw	a1,1362(a1) # ffffffffc0207120 <buddy_sys+0x108>
ffffffffc0200bd6:	00002517          	auipc	a0,0x2
ffffffffc0200bda:	83250513          	addi	a0,a0,-1998 # ffffffffc0202408 <etext+0x5a2>
static void show_buddy_array(unsigned int start_order, unsigned int end_order) {
ffffffffc0200bde:	f822                	sd	s0,48(sp)
ffffffffc0200be0:	f426                	sd	s1,40(sp)
ffffffffc0200be2:	f04a                	sd	s2,32(sp)
ffffffffc0200be4:	ec4e                	sd	s3,24(sp)
ffffffffc0200be6:	e852                	sd	s4,16(sp)
ffffffffc0200be8:	e456                	sd	s5,8(sp)
ffffffffc0200bea:	e05a                	sd	s6,0(sp)
ffffffffc0200bec:	fc06                	sd	ra,56(sp)
ffffffffc0200bee:	00006417          	auipc	s0,0x6
ffffffffc0200bf2:	43240413          	addi	s0,s0,1074 # ffffffffc0207020 <buddy_sys+0x8>
    cprintf("Buddy System Status (Total free: %u pages):\n", buddy_sys.nr_free);
ffffffffc0200bf6:	d56ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    for (unsigned int i = start_order; i <= end_order && i <= MAX_ORDER; i++) {
ffffffffc0200bfa:	4481                	li	s1,0
        cprintf("Order %2d (size: %5u pages): ", i, (1u << i));
ffffffffc0200bfc:	4a05                	li	s4,1
ffffffffc0200bfe:	00002997          	auipc	s3,0x2
ffffffffc0200c02:	83a98993          	addi	s3,s3,-1990 # ffffffffc0202438 <etext+0x5d2>
            cprintf("%d blocks\n", count);
ffffffffc0200c06:	00002a97          	auipc	s5,0x2
ffffffffc0200c0a:	85aa8a93          	addi	s5,s5,-1958 # ffffffffc0202460 <etext+0x5fa>
            cprintf("empty\n");
ffffffffc0200c0e:	00002b17          	auipc	s6,0x2
ffffffffc0200c12:	84ab0b13          	addi	s6,s6,-1974 # ffffffffc0202458 <etext+0x5f2>
    for (unsigned int i = start_order; i <= end_order && i <= MAX_ORDER; i++) {
ffffffffc0200c16:	4941                	li	s2,16
        cprintf("Order %2d (size: %5u pages): ", i, (1u << i));
ffffffffc0200c18:	85a6                	mv	a1,s1
ffffffffc0200c1a:	009a163b          	sllw	a2,s4,s1
ffffffffc0200c1e:	854e                	mv	a0,s3
ffffffffc0200c20:	d2cff0ef          	jal	ra,ffffffffc020014c <cprintf>
    return list->next == list;
ffffffffc0200c24:	641c                	ld	a5,8(s0)
            int count = 0;
ffffffffc0200c26:	4581                	li	a1,0
        if (list_empty(&buddy_sys.free_array[i])) {
ffffffffc0200c28:	02878763          	beq	a5,s0,ffffffffc0200c56 <show_buddy_array.constprop.0+0x8a>
                temp = temp->next;
ffffffffc0200c2c:	679c                	ld	a5,8(a5)
                count++;
ffffffffc0200c2e:	2585                	addiw	a1,a1,1
            while (temp != le) {
ffffffffc0200c30:	fe879ee3          	bne	a5,s0,ffffffffc0200c2c <show_buddy_array.constprop.0+0x60>
            cprintf("%d blocks\n", count);
ffffffffc0200c34:	8556                	mv	a0,s5
ffffffffc0200c36:	d16ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    for (unsigned int i = start_order; i <= end_order && i <= MAX_ORDER; i++) {
ffffffffc0200c3a:	2485                	addiw	s1,s1,1
ffffffffc0200c3c:	0441                	addi	s0,s0,16
ffffffffc0200c3e:	fd249de3          	bne	s1,s2,ffffffffc0200c18 <show_buddy_array.constprop.0+0x4c>
}
ffffffffc0200c42:	70e2                	ld	ra,56(sp)
ffffffffc0200c44:	7442                	ld	s0,48(sp)
ffffffffc0200c46:	74a2                	ld	s1,40(sp)
ffffffffc0200c48:	7902                	ld	s2,32(sp)
ffffffffc0200c4a:	69e2                	ld	s3,24(sp)
ffffffffc0200c4c:	6a42                	ld	s4,16(sp)
ffffffffc0200c4e:	6aa2                	ld	s5,8(sp)
ffffffffc0200c50:	6b02                	ld	s6,0(sp)
ffffffffc0200c52:	6121                	addi	sp,sp,64
ffffffffc0200c54:	8082                	ret
            cprintf("empty\n");
ffffffffc0200c56:	855a                	mv	a0,s6
ffffffffc0200c58:	cf4ff0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc0200c5c:	bff9                	j	ffffffffc0200c3a <show_buddy_array.constprop.0+0x6e>

ffffffffc0200c5e <buddy_system_comprehensive_check>:

/*
 * 综合测试函数：运行所有测试
 */
static void
buddy_system_comprehensive_check(void) {
ffffffffc0200c5e:	7175                	addi	sp,sp,-144
    cprintf("\n");
ffffffffc0200c60:	00002517          	auipc	a0,0x2
ffffffffc0200c64:	bc850513          	addi	a0,a0,-1080 # ffffffffc0202828 <etext+0x9c2>
buddy_system_comprehensive_check(void) {
ffffffffc0200c68:	e506                	sd	ra,136(sp)
ffffffffc0200c6a:	fca6                	sd	s1,120(sp)
ffffffffc0200c6c:	f4ce                	sd	s3,104(sp)
ffffffffc0200c6e:	fc66                	sd	s9,56(sp)
ffffffffc0200c70:	e122                	sd	s0,128(sp)
ffffffffc0200c72:	f8ca                	sd	s2,112(sp)
ffffffffc0200c74:	f0d2                	sd	s4,96(sp)
ffffffffc0200c76:	ecd6                	sd	s5,88(sp)
ffffffffc0200c78:	e8da                	sd	s6,80(sp)
ffffffffc0200c7a:	e4de                	sd	s7,72(sp)
ffffffffc0200c7c:	e0e2                	sd	s8,64(sp)
    cprintf("\n");
ffffffffc0200c7e:	cceff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("**************************************************\n");
ffffffffc0200c82:	00001517          	auipc	a0,0x1
ffffffffc0200c86:	7ee50513          	addi	a0,a0,2030 # ffffffffc0202470 <etext+0x60a>
ffffffffc0200c8a:	cc2ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("***        BEGIN BUDDY SYSTEM COMPREHENSIVE TEST       ***\n");
ffffffffc0200c8e:	00002517          	auipc	a0,0x2
ffffffffc0200c92:	81a50513          	addi	a0,a0,-2022 # ffffffffc02024a8 <etext+0x642>
ffffffffc0200c96:	cb6ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("**************************************************\n\n");

    // 保存初始状态
    size_t initial_free = buddy_sys.nr_free;
ffffffffc0200c9a:	00006497          	auipc	s1,0x6
ffffffffc0200c9e:	37e48493          	addi	s1,s1,894 # ffffffffc0207018 <buddy_sys>
    cprintf("**************************************************\n\n");
ffffffffc0200ca2:	00002517          	auipc	a0,0x2
ffffffffc0200ca6:	84650513          	addi	a0,a0,-1978 # ffffffffc02024e8 <etext+0x682>
ffffffffc0200caa:	ca2ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    size_t initial_free = buddy_sys.nr_free;
ffffffffc0200cae:	1084ac83          	lw	s9,264(s1)
    cprintf("初始空闲页数: %u\n", (unsigned int)initial_free);
ffffffffc0200cb2:	00002517          	auipc	a0,0x2
ffffffffc0200cb6:	86e50513          	addi	a0,a0,-1938 # ffffffffc0202520 <etext+0x6ba>
    if (n > buddy_sys.nr_free) {
ffffffffc0200cba:	49a5                	li	s3,9
    cprintf("初始空闲页数: %u\n", (unsigned int)initial_free);
ffffffffc0200cbc:	85e6                	mv	a1,s9
ffffffffc0200cbe:	c8eff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("=== BEGIN TEST: EASY ALLOC AND FREE CONDITION ===\n");
ffffffffc0200cc2:	00002517          	auipc	a0,0x2
ffffffffc0200cc6:	87650513          	addi	a0,a0,-1930 # ffffffffc0202538 <etext+0x6d2>
ffffffffc0200cca:	c82ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("当前总的空闲块的数量为：%u\n", buddy_sys.nr_free);
ffffffffc0200cce:	1084a583          	lw	a1,264(s1)
ffffffffc0200cd2:	00002517          	auipc	a0,0x2
ffffffffc0200cd6:	89e50513          	addi	a0,a0,-1890 # ffffffffc0202570 <etext+0x70a>
ffffffffc0200cda:	c72ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("1. p0请求10页\n");
ffffffffc0200cde:	00002517          	auipc	a0,0x2
ffffffffc0200ce2:	8ba50513          	addi	a0,a0,-1862 # ffffffffc0202598 <etext+0x732>
ffffffffc0200ce6:	c66ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    if (n > buddy_sys.nr_free) {
ffffffffc0200cea:	1084a603          	lw	a2,264(s1)
ffffffffc0200cee:	76c9fb63          	bgeu	s3,a2,ffffffffc0201464 <buddy_system_comprehensive_check+0x806>
ffffffffc0200cf2:	4529                	li	a0,10
ffffffffc0200cf4:	b7fff0ef          	jal	ra,ffffffffc0200872 <buddy_system_alloc_pages.part.0>
ffffffffc0200cf8:	892a                	mv	s2,a0
    assert(p0 != NULL);
ffffffffc0200cfa:	76050c63          	beqz	a0,ffffffffc0201472 <buddy_system_comprehensive_check+0x814>
    show_buddy_array(0, MAX_ORDER);
ffffffffc0200cfe:	ecfff0ef          	jal	ra,ffffffffc0200bcc <show_buddy_array.constprop.0>
    cprintf("2. p1请求10页\n");
ffffffffc0200d02:	00002517          	auipc	a0,0x2
ffffffffc0200d06:	8be50513          	addi	a0,a0,-1858 # ffffffffc02025c0 <etext+0x75a>
ffffffffc0200d0a:	c42ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    if (n > buddy_sys.nr_free) {
ffffffffc0200d0e:	1084a603          	lw	a2,264(s1)
ffffffffc0200d12:	78c9f063          	bgeu	s3,a2,ffffffffc0201492 <buddy_system_comprehensive_check+0x834>
ffffffffc0200d16:	4529                	li	a0,10
ffffffffc0200d18:	b5bff0ef          	jal	ra,ffffffffc0200872 <buddy_system_alloc_pages.part.0>
ffffffffc0200d1c:	842a                	mv	s0,a0
    assert(p1 != NULL);
ffffffffc0200d1e:	78050163          	beqz	a0,ffffffffc02014a0 <buddy_system_comprehensive_check+0x842>
    show_buddy_array(0, MAX_ORDER);
ffffffffc0200d22:	eabff0ef          	jal	ra,ffffffffc0200bcc <show_buddy_array.constprop.0>
    cprintf("3. p2请求10页\n");
ffffffffc0200d26:	00002517          	auipc	a0,0x2
ffffffffc0200d2a:	8c250513          	addi	a0,a0,-1854 # ffffffffc02025e8 <etext+0x782>
ffffffffc0200d2e:	c1eff0ef          	jal	ra,ffffffffc020014c <cprintf>
    if (n > buddy_sys.nr_free) {
ffffffffc0200d32:	1084a603          	lw	a2,264(s1)
ffffffffc0200d36:	70c9f063          	bgeu	s3,a2,ffffffffc0201436 <buddy_system_comprehensive_check+0x7d8>
ffffffffc0200d3a:	4529                	li	a0,10
ffffffffc0200d3c:	b37ff0ef          	jal	ra,ffffffffc0200872 <buddy_system_alloc_pages.part.0>
ffffffffc0200d40:	8a2a                	mv	s4,a0
    assert(p2 != NULL);
ffffffffc0200d42:	70050163          	beqz	a0,ffffffffc0201444 <buddy_system_comprehensive_check+0x7e6>
    show_buddy_array(0, MAX_ORDER);
ffffffffc0200d46:	e87ff0ef          	jal	ra,ffffffffc0200bcc <show_buddy_array.constprop.0>
    cprintf("p0的虚拟地址为: 0x%016lx\n", (unsigned long)p0);
ffffffffc0200d4a:	85ca                	mv	a1,s2
ffffffffc0200d4c:	00002517          	auipc	a0,0x2
ffffffffc0200d50:	8c450513          	addi	a0,a0,-1852 # ffffffffc0202610 <etext+0x7aa>
ffffffffc0200d54:	bf8ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("p1的虚拟地址为: 0x%016lx\n", (unsigned long)p1);
ffffffffc0200d58:	85a2                	mv	a1,s0
ffffffffc0200d5a:	00002517          	auipc	a0,0x2
ffffffffc0200d5e:	8d650513          	addi	a0,a0,-1834 # ffffffffc0202630 <etext+0x7ca>
ffffffffc0200d62:	beaff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("p2的虚拟地址为: 0x%016lx\n", (unsigned long)p2);
ffffffffc0200d66:	85d2                	mv	a1,s4
ffffffffc0200d68:	00002517          	auipc	a0,0x2
ffffffffc0200d6c:	8e850513          	addi	a0,a0,-1816 # ffffffffc0202650 <etext+0x7ea>
ffffffffc0200d70:	bdcff0ef          	jal	ra,ffffffffc020014c <cprintf>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200d74:	0e8903e3          	beq	s2,s0,ffffffffc020165a <buddy_system_comprehensive_check+0x9fc>
ffffffffc0200d78:	0f4901e3          	beq	s2,s4,ffffffffc020165a <buddy_system_comprehensive_check+0x9fc>
ffffffffc0200d7c:	0d440fe3          	beq	s0,s4,ffffffffc020165a <buddy_system_comprehensive_check+0x9fc>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200d80:	00092783          	lw	a5,0(s2)
ffffffffc0200d84:	12079be3          	bnez	a5,ffffffffc02016ba <buddy_system_comprehensive_check+0xa5c>
ffffffffc0200d88:	401c                	lw	a5,0(s0)
ffffffffc0200d8a:	120798e3          	bnez	a5,ffffffffc02016ba <buddy_system_comprehensive_check+0xa5c>
static inline int page_ref(struct Page *page) { return page->ref; }
ffffffffc0200d8e:	000a2983          	lw	s3,0(s4)
ffffffffc0200d92:	120994e3          	bnez	s3,ffffffffc02016ba <buddy_system_comprehensive_check+0xa5c>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200d96:	00006797          	auipc	a5,0x6
ffffffffc0200d9a:	3b27b783          	ld	a5,946(a5) # ffffffffc0207148 <pages>
ffffffffc0200d9e:	40f90733          	sub	a4,s2,a5
ffffffffc0200da2:	870d                	srai	a4,a4,0x3
ffffffffc0200da4:	00002597          	auipc	a1,0x2
ffffffffc0200da8:	69c5b583          	ld	a1,1692(a1) # ffffffffc0203440 <error_string+0x38>
ffffffffc0200dac:	02b70733          	mul	a4,a4,a1
ffffffffc0200db0:	00002617          	auipc	a2,0x2
ffffffffc0200db4:	69863603          	ld	a2,1688(a2) # ffffffffc0203448 <nbase>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200db8:	00006697          	auipc	a3,0x6
ffffffffc0200dbc:	3886b683          	ld	a3,904(a3) # ffffffffc0207140 <npage>
ffffffffc0200dc0:	06b2                	slli	a3,a3,0xc
ffffffffc0200dc2:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200dc4:	0732                	slli	a4,a4,0xc
ffffffffc0200dc6:	10d77ae3          	bgeu	a4,a3,ffffffffc02016da <buddy_system_comprehensive_check+0xa7c>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200dca:	40f40733          	sub	a4,s0,a5
ffffffffc0200dce:	870d                	srai	a4,a4,0x3
ffffffffc0200dd0:	02b70733          	mul	a4,a4,a1
ffffffffc0200dd4:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200dd6:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200dd8:	1cd771e3          	bgeu	a4,a3,ffffffffc020179a <buddy_system_comprehensive_check+0xb3c>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200ddc:	40fa07b3          	sub	a5,s4,a5
ffffffffc0200de0:	878d                	srai	a5,a5,0x3
ffffffffc0200de2:	02b787b3          	mul	a5,a5,a1
ffffffffc0200de6:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200de8:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200dea:	14d7f8e3          	bgeu	a5,a3,ffffffffc020173a <buddy_system_comprehensive_check+0xadc>
    cprintf("4. 释放p0...\n");
ffffffffc0200dee:	00002517          	auipc	a0,0x2
ffffffffc0200df2:	94a50513          	addi	a0,a0,-1718 # ffffffffc0202738 <etext+0x8d2>
ffffffffc0200df6:	b56ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    assert(n > 0);
ffffffffc0200dfa:	45a9                	li	a1,10
ffffffffc0200dfc:	854a                	mv	a0,s2
ffffffffc0200dfe:	813ff0ef          	jal	ra,ffffffffc0200610 <buddy_system_free_pages.part.0>
    cprintf("释放p0后，总空闲块数目为: %u\n", buddy_sys.nr_free);
ffffffffc0200e02:	1084a583          	lw	a1,264(s1)
ffffffffc0200e06:	00002517          	auipc	a0,0x2
ffffffffc0200e0a:	94250513          	addi	a0,a0,-1726 # ffffffffc0202748 <etext+0x8e2>
ffffffffc0200e0e:	b3eff0ef          	jal	ra,ffffffffc020014c <cprintf>
    show_buddy_array(0, MAX_ORDER);
ffffffffc0200e12:	dbbff0ef          	jal	ra,ffffffffc0200bcc <show_buddy_array.constprop.0>
    cprintf("5. 释放p1...\n");
ffffffffc0200e16:	00002517          	auipc	a0,0x2
ffffffffc0200e1a:	96250513          	addi	a0,a0,-1694 # ffffffffc0202778 <etext+0x912>
ffffffffc0200e1e:	b2eff0ef          	jal	ra,ffffffffc020014c <cprintf>
    assert(n > 0);
ffffffffc0200e22:	45a9                	li	a1,10
ffffffffc0200e24:	8522                	mv	a0,s0
ffffffffc0200e26:	feaff0ef          	jal	ra,ffffffffc0200610 <buddy_system_free_pages.part.0>
    cprintf("释放p1后，总空闲块数目为: %u\n", buddy_sys.nr_free);
ffffffffc0200e2a:	1084a583          	lw	a1,264(s1)
ffffffffc0200e2e:	00002517          	auipc	a0,0x2
ffffffffc0200e32:	95a50513          	addi	a0,a0,-1702 # ffffffffc0202788 <etext+0x922>
ffffffffc0200e36:	b16ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    show_buddy_array(0, MAX_ORDER);
ffffffffc0200e3a:	d93ff0ef          	jal	ra,ffffffffc0200bcc <show_buddy_array.constprop.0>
    cprintf("6. 释放p2...\n");
ffffffffc0200e3e:	00002517          	auipc	a0,0x2
ffffffffc0200e42:	97a50513          	addi	a0,a0,-1670 # ffffffffc02027b8 <etext+0x952>
ffffffffc0200e46:	b06ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    assert(n > 0);
ffffffffc0200e4a:	45a9                	li	a1,10
ffffffffc0200e4c:	8552                	mv	a0,s4
ffffffffc0200e4e:	fc2ff0ef          	jal	ra,ffffffffc0200610 <buddy_system_free_pages.part.0>
    cprintf("释放p2后，总空闲块数目为: %u\n", buddy_sys.nr_free);
ffffffffc0200e52:	1084a583          	lw	a1,264(s1)
ffffffffc0200e56:	00002517          	auipc	a0,0x2
ffffffffc0200e5a:	97250513          	addi	a0,a0,-1678 # ffffffffc02027c8 <etext+0x962>
ffffffffc0200e5e:	aeeff0ef          	jal	ra,ffffffffc020014c <cprintf>
    show_buddy_array(0, MAX_ORDER);
ffffffffc0200e62:	d6bff0ef          	jal	ra,ffffffffc0200bcc <show_buddy_array.constprop.0>
    cprintf("=== END TEST: EASY ALLOC AND FREE CONDITION ===\n\n");
ffffffffc0200e66:	00002517          	auipc	a0,0x2
ffffffffc0200e6a:	99250513          	addi	a0,a0,-1646 # ffffffffc02027f8 <etext+0x992>
ffffffffc0200e6e:	adeff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("=== BEGIN TEST: COMPLEX ALLOC AND FREE CONDITION ===\n");
ffffffffc0200e72:	00002517          	auipc	a0,0x2
ffffffffc0200e76:	9be50513          	addi	a0,a0,-1602 # ffffffffc0202830 <etext+0x9ca>
ffffffffc0200e7a:	ad2ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("1. p0请求10页\n");
ffffffffc0200e7e:	00001517          	auipc	a0,0x1
ffffffffc0200e82:	71a50513          	addi	a0,a0,1818 # ffffffffc0202598 <etext+0x732>
ffffffffc0200e86:	ac6ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    if (n > buddy_sys.nr_free) {
ffffffffc0200e8a:	1084a603          	lw	a2,264(s1)
ffffffffc0200e8e:	47a5                	li	a5,9
ffffffffc0200e90:	66c7f063          	bgeu	a5,a2,ffffffffc02014f0 <buddy_system_comprehensive_check+0x892>
ffffffffc0200e94:	4529                	li	a0,10
ffffffffc0200e96:	9ddff0ef          	jal	ra,ffffffffc0200872 <buddy_system_alloc_pages.part.0>
ffffffffc0200e9a:	842a                	mv	s0,a0
    assert(p0 != NULL);
ffffffffc0200e9c:	66050163          	beqz	a0,ffffffffc02014fe <buddy_system_comprehensive_check+0x8a0>
    show_buddy_array(0, MAX_ORDER);
ffffffffc0200ea0:	d2dff0ef          	jal	ra,ffffffffc0200bcc <show_buddy_array.constprop.0>
    cprintf("2. p1请求50页\n");
ffffffffc0200ea4:	00002517          	auipc	a0,0x2
ffffffffc0200ea8:	9c450513          	addi	a0,a0,-1596 # ffffffffc0202868 <etext+0xa02>
ffffffffc0200eac:	aa0ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    if (n > buddy_sys.nr_free) {
ffffffffc0200eb0:	1084a603          	lw	a2,264(s1)
ffffffffc0200eb4:	03100793          	li	a5,49
ffffffffc0200eb8:	6cc7f363          	bgeu	a5,a2,ffffffffc020157e <buddy_system_comprehensive_check+0x920>
ffffffffc0200ebc:	03200513          	li	a0,50
ffffffffc0200ec0:	9b3ff0ef          	jal	ra,ffffffffc0200872 <buddy_system_alloc_pages.part.0>
ffffffffc0200ec4:	892a                	mv	s2,a0
    assert(p1 != NULL);
ffffffffc0200ec6:	6c050463          	beqz	a0,ffffffffc020158e <buddy_system_comprehensive_check+0x930>
    show_buddy_array(0, MAX_ORDER);
ffffffffc0200eca:	d03ff0ef          	jal	ra,ffffffffc0200bcc <show_buddy_array.constprop.0>
    cprintf("3. p2请求100页\n");
ffffffffc0200ece:	00002517          	auipc	a0,0x2
ffffffffc0200ed2:	9b250513          	addi	a0,a0,-1614 # ffffffffc0202880 <etext+0xa1a>
ffffffffc0200ed6:	a76ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    if (n > buddy_sys.nr_free) {
ffffffffc0200eda:	1084a603          	lw	a2,264(s1)
ffffffffc0200ede:	06300793          	li	a5,99
ffffffffc0200ee2:	62c7fe63          	bgeu	a5,a2,ffffffffc020151e <buddy_system_comprehensive_check+0x8c0>
ffffffffc0200ee6:	06400513          	li	a0,100
ffffffffc0200eea:	989ff0ef          	jal	ra,ffffffffc0200872 <buddy_system_alloc_pages.part.0>
ffffffffc0200eee:	8a2a                	mv	s4,a0
    assert(p2 != NULL);
ffffffffc0200ef0:	62050f63          	beqz	a0,ffffffffc020152e <buddy_system_comprehensive_check+0x8d0>
    show_buddy_array(0, MAX_ORDER);
ffffffffc0200ef4:	cd9ff0ef          	jal	ra,ffffffffc0200bcc <show_buddy_array.constprop.0>
    cprintf("4. p3请求200页\n");
ffffffffc0200ef8:	00002517          	auipc	a0,0x2
ffffffffc0200efc:	9a050513          	addi	a0,a0,-1632 # ffffffffc0202898 <etext+0xa32>
ffffffffc0200f00:	a4cff0ef          	jal	ra,ffffffffc020014c <cprintf>
    if (n > buddy_sys.nr_free) {
ffffffffc0200f04:	1084a603          	lw	a2,264(s1)
ffffffffc0200f08:	0c700793          	li	a5,199
ffffffffc0200f0c:	64c7f163          	bgeu	a5,a2,ffffffffc020154e <buddy_system_comprehensive_check+0x8f0>
ffffffffc0200f10:	0c800513          	li	a0,200
ffffffffc0200f14:	95fff0ef          	jal	ra,ffffffffc0200872 <buddy_system_alloc_pages.part.0>
ffffffffc0200f18:	8aaa                	mv	s5,a0
    assert(p3 != NULL);
ffffffffc0200f1a:	64050263          	beqz	a0,ffffffffc020155e <buddy_system_comprehensive_check+0x900>
    show_buddy_array(0, MAX_ORDER);
ffffffffc0200f1e:	cafff0ef          	jal	ra,ffffffffc0200bcc <show_buddy_array.constprop.0>
    assert(p0 != p1 && p0 != p2 && p0 != p3);
ffffffffc0200f22:	75240c63          	beq	s0,s2,ffffffffc020167a <buddy_system_comprehensive_check+0xa1c>
ffffffffc0200f26:	75440a63          	beq	s0,s4,ffffffffc020167a <buddy_system_comprehensive_check+0xa1c>
ffffffffc0200f2a:	75540863          	beq	s0,s5,ffffffffc020167a <buddy_system_comprehensive_check+0xa1c>
    assert(p1 != p2 && p1 != p3 && p2 != p3);
ffffffffc0200f2e:	77490663          	beq	s2,s4,ffffffffc020169a <buddy_system_comprehensive_check+0xa3c>
ffffffffc0200f32:	77590463          	beq	s2,s5,ffffffffc020169a <buddy_system_comprehensive_check+0xa3c>
ffffffffc0200f36:	775a0263          	beq	s4,s5,ffffffffc020169a <buddy_system_comprehensive_check+0xa3c>
    cprintf("5. 先释放p2(100页)...\n");
ffffffffc0200f3a:	00002517          	auipc	a0,0x2
ffffffffc0200f3e:	9d650513          	addi	a0,a0,-1578 # ffffffffc0202910 <etext+0xaaa>
ffffffffc0200f42:	a0aff0ef          	jal	ra,ffffffffc020014c <cprintf>
    assert(n > 0);
ffffffffc0200f46:	06400593          	li	a1,100
ffffffffc0200f4a:	8552                	mv	a0,s4
ffffffffc0200f4c:	ec4ff0ef          	jal	ra,ffffffffc0200610 <buddy_system_free_pages.part.0>
    show_buddy_array(0, MAX_ORDER);
ffffffffc0200f50:	c7dff0ef          	jal	ra,ffffffffc0200bcc <show_buddy_array.constprop.0>
    cprintf("6. 再释放p1(50页)...\n");
ffffffffc0200f54:	00002517          	auipc	a0,0x2
ffffffffc0200f58:	9dc50513          	addi	a0,a0,-1572 # ffffffffc0202930 <etext+0xaca>
ffffffffc0200f5c:	9f0ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    assert(n > 0);
ffffffffc0200f60:	03200593          	li	a1,50
ffffffffc0200f64:	854a                	mv	a0,s2
ffffffffc0200f66:	eaaff0ef          	jal	ra,ffffffffc0200610 <buddy_system_free_pages.part.0>
    show_buddy_array(0, MAX_ORDER);
ffffffffc0200f6a:	c63ff0ef          	jal	ra,ffffffffc0200bcc <show_buddy_array.constprop.0>
    cprintf("7. 释放p0(10页)...\n");
ffffffffc0200f6e:	00002517          	auipc	a0,0x2
ffffffffc0200f72:	9e250513          	addi	a0,a0,-1566 # ffffffffc0202950 <etext+0xaea>
ffffffffc0200f76:	9d6ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    assert(n > 0);
ffffffffc0200f7a:	45a9                	li	a1,10
ffffffffc0200f7c:	8522                	mv	a0,s0
ffffffffc0200f7e:	e92ff0ef          	jal	ra,ffffffffc0200610 <buddy_system_free_pages.part.0>
    show_buddy_array(0, MAX_ORDER);
ffffffffc0200f82:	c4bff0ef          	jal	ra,ffffffffc0200bcc <show_buddy_array.constprop.0>
    cprintf("8. 最后释放p3(200页)...\n");
ffffffffc0200f86:	00002517          	auipc	a0,0x2
ffffffffc0200f8a:	9e250513          	addi	a0,a0,-1566 # ffffffffc0202968 <etext+0xb02>
ffffffffc0200f8e:	9beff0ef          	jal	ra,ffffffffc020014c <cprintf>
    assert(n > 0);
ffffffffc0200f92:	0c800593          	li	a1,200
ffffffffc0200f96:	8556                	mv	a0,s5
ffffffffc0200f98:	e78ff0ef          	jal	ra,ffffffffc0200610 <buddy_system_free_pages.part.0>
    show_buddy_array(0, MAX_ORDER);
ffffffffc0200f9c:	c31ff0ef          	jal	ra,ffffffffc0200bcc <show_buddy_array.constprop.0>
    cprintf("=== END TEST: COMPLEX ALLOC AND FREE CONDITION ===\n\n");
ffffffffc0200fa0:	00002517          	auipc	a0,0x2
ffffffffc0200fa4:	9e850513          	addi	a0,a0,-1560 # ffffffffc0202988 <etext+0xb22>
ffffffffc0200fa8:	9a4ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("=== BEGIN TEST: BOUNDARY ALLOC AND FREE CONDITION ===\n");
ffffffffc0200fac:	00002517          	auipc	a0,0x2
ffffffffc0200fb0:	a1450513          	addi	a0,a0,-1516 # ffffffffc02029c0 <etext+0xb5a>
ffffffffc0200fb4:	998ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("1. 分配最小单位(1页)...\n");
ffffffffc0200fb8:	00002517          	auipc	a0,0x2
ffffffffc0200fbc:	a4050513          	addi	a0,a0,-1472 # ffffffffc02029f8 <etext+0xb92>
ffffffffc0200fc0:	98cff0ef          	jal	ra,ffffffffc020014c <cprintf>
    if (n > buddy_sys.nr_free) {
ffffffffc0200fc4:	1084a783          	lw	a5,264(s1)
ffffffffc0200fc8:	4e078c63          	beqz	a5,ffffffffc02014c0 <buddy_system_comprehensive_check+0x862>
ffffffffc0200fcc:	4505                	li	a0,1
ffffffffc0200fce:	8a5ff0ef          	jal	ra,ffffffffc0200872 <buddy_system_alloc_pages.part.0>
ffffffffc0200fd2:	842a                	mv	s0,a0
    assert(p_min != NULL);
ffffffffc0200fd4:	4e050e63          	beqz	a0,ffffffffc02014d0 <buddy_system_comprehensive_check+0x872>
    show_buddy_array(0, MAX_ORDER);
ffffffffc0200fd8:	bf5ff0ef          	jal	ra,ffffffffc0200bcc <show_buddy_array.constprop.0>
    cprintf("2. 释放最小单位(1页)...\n");
ffffffffc0200fdc:	00002517          	auipc	a0,0x2
ffffffffc0200fe0:	a4c50513          	addi	a0,a0,-1460 # ffffffffc0202a28 <etext+0xbc2>
ffffffffc0200fe4:	968ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    assert(n > 0);
ffffffffc0200fe8:	4585                	li	a1,1
ffffffffc0200fea:	8522                	mv	a0,s0
ffffffffc0200fec:	e24ff0ef          	jal	ra,ffffffffc0200610 <buddy_system_free_pages.part.0>
    show_buddy_array(0, MAX_ORDER);
ffffffffc0200ff0:	bddff0ef          	jal	ra,ffffffffc0200bcc <show_buddy_array.constprop.0>
    cprintf("3. 分配最大单位(%u页)...\n", (1 << MAX_ORDER));
ffffffffc0200ff4:	65a1                	lui	a1,0x8
ffffffffc0200ff6:	00002517          	auipc	a0,0x2
ffffffffc0200ffa:	a5250513          	addi	a0,a0,-1454 # ffffffffc0202a48 <etext+0xbe2>
ffffffffc0200ffe:	94eff0ef          	jal	ra,ffffffffc020014c <cprintf>
    if (n > buddy_sys.nr_free) {
ffffffffc0201002:	1084a603          	lw	a2,264(s1)
ffffffffc0201006:	67a1                	lui	a5,0x8
ffffffffc0201008:	3cf66b63          	bltu	a2,a5,ffffffffc02013de <buddy_system_comprehensive_check+0x780>
ffffffffc020100c:	6521                	lui	a0,0x8
ffffffffc020100e:	865ff0ef          	jal	ra,ffffffffc0200872 <buddy_system_alloc_pages.part.0>
ffffffffc0201012:	842a                	mv	s0,a0
    if (p_max != NULL) {
ffffffffc0201014:	3c050c63          	beqz	a0,ffffffffc02013ec <buddy_system_comprehensive_check+0x78e>
        show_buddy_array(0, MAX_ORDER);
ffffffffc0201018:	bb5ff0ef          	jal	ra,ffffffffc0200bcc <show_buddy_array.constprop.0>
        cprintf("4. 释放最大单位(%u页)...\n", (1 << MAX_ORDER));
ffffffffc020101c:	65a1                	lui	a1,0x8
ffffffffc020101e:	00002517          	auipc	a0,0x2
ffffffffc0201022:	a5250513          	addi	a0,a0,-1454 # ffffffffc0202a70 <etext+0xc0a>
ffffffffc0201026:	926ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    assert(n > 0);
ffffffffc020102a:	65a1                	lui	a1,0x8
ffffffffc020102c:	8522                	mv	a0,s0
ffffffffc020102e:	de2ff0ef          	jal	ra,ffffffffc0200610 <buddy_system_free_pages.part.0>
        show_buddy_array(0, MAX_ORDER);
ffffffffc0201032:	b9bff0ef          	jal	ra,ffffffffc0200bcc <show_buddy_array.constprop.0>
    cprintf("5. 尝试分配超过最大限制(%u + 1页)...\n", (1 << MAX_ORDER));
ffffffffc0201036:	65a1                	lui	a1,0x8
ffffffffc0201038:	00002517          	auipc	a0,0x2
ffffffffc020103c:	a8850513          	addi	a0,a0,-1400 # ffffffffc0202ac0 <etext+0xc5a>
ffffffffc0201040:	90cff0ef          	jal	ra,ffffffffc020014c <cprintf>
    if (n > buddy_sys.nr_free) {
ffffffffc0201044:	1084a603          	lw	a2,264(s1)
ffffffffc0201048:	6521                	lui	a0,0x8
ffffffffc020104a:	56c57263          	bgeu	a0,a2,ffffffffc02015ae <buddy_system_comprehensive_check+0x950>
ffffffffc020104e:	0505                	addi	a0,a0,1
ffffffffc0201050:	823ff0ef          	jal	ra,ffffffffc0200872 <buddy_system_alloc_pages.part.0>
    assert(p_overflow == NULL);
ffffffffc0201054:	70051363          	bnez	a0,ffffffffc020175a <buddy_system_comprehensive_check+0xafc>
    cprintf("   分配失败，符合预期\n");
ffffffffc0201058:	00002517          	auipc	a0,0x2
ffffffffc020105c:	ab850513          	addi	a0,a0,-1352 # ffffffffc0202b10 <etext+0xcaa>
ffffffffc0201060:	8ecff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("=== END TEST: BOUNDARY ALLOC AND FREE CONDITION ===\n\n");
ffffffffc0201064:	00002517          	auipc	a0,0x2
ffffffffc0201068:	acc50513          	addi	a0,a0,-1332 # ffffffffc0202b30 <etext+0xcca>
ffffffffc020106c:	8e0ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("=== BEGIN TEST: STRESS CONDITION ===\n");
ffffffffc0201070:	00002517          	auipc	a0,0x2
ffffffffc0201074:	af850513          	addi	a0,a0,-1288 # ffffffffc0202b68 <etext+0xd02>
ffffffffc0201078:	8d4ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("1. 连续分配%d个不同大小的块...\n", STRESS_TEST_COUNT);
ffffffffc020107c:	4599                	li	a1,6
ffffffffc020107e:	00002517          	auipc	a0,0x2
ffffffffc0201082:	b1250513          	addi	a0,a0,-1262 # ffffffffc0202b90 <etext+0xd2a>
ffffffffc0201086:	8a0a                	mv	s4,sp
ffffffffc0201088:	8c4ff0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc020108c:	8ad2                	mv	s5,s4
    for (int i = 0; i < STRESS_TEST_COUNT; i++) {
ffffffffc020108e:	4901                	li	s2,0
        size_t size = 1 << (i % 4); // 不同大小: 1, 2, 4, 8页
ffffffffc0201090:	4b05                	li	s6,1
        cprintf("   分配第%d个块: %u页\n", i + 1, (unsigned int)size);
ffffffffc0201092:	00002c17          	auipc	s8,0x2
ffffffffc0201096:	b46c0c13          	addi	s8,s8,-1210 # ffffffffc0202bd8 <etext+0xd72>
    for (int i = 0; i < STRESS_TEST_COUNT; i++) {
ffffffffc020109a:	4b99                	li	s7,6
    if (n > buddy_sys.nr_free) {
ffffffffc020109c:	1084a603          	lw	a2,264(s1)
        size_t size = 1 << (i % 4); // 不同大小: 1, 2, 4, 8页
ffffffffc02010a0:	00397413          	andi	s0,s2,3
ffffffffc02010a4:	008b143b          	sllw	s0,s6,s0
    if (n > buddy_sys.nr_free) {
ffffffffc02010a8:	02061793          	slli	a5,a2,0x20
ffffffffc02010ac:	9381                	srli	a5,a5,0x20
ffffffffc02010ae:	3087e163          	bltu	a5,s0,ffffffffc02013b0 <buddy_system_comprehensive_check+0x752>
ffffffffc02010b2:	8522                	mv	a0,s0
ffffffffc02010b4:	fbeff0ef          	jal	ra,ffffffffc0200872 <buddy_system_alloc_pages.part.0>
        pages[i] = buddy_system_alloc_pages(size);
ffffffffc02010b8:	00aab023          	sd	a0,0(s5)
        assert(pages[i] != NULL);
ffffffffc02010bc:	30050163          	beqz	a0,ffffffffc02013be <buddy_system_comprehensive_check+0x760>
        cprintf("   分配第%d个块: %u页\n", i + 1, (unsigned int)size);
ffffffffc02010c0:	2905                	addiw	s2,s2,1
ffffffffc02010c2:	8622                	mv	a2,s0
ffffffffc02010c4:	85ca                	mv	a1,s2
ffffffffc02010c6:	8562                	mv	a0,s8
ffffffffc02010c8:	884ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    for (int i = 0; i < STRESS_TEST_COUNT; i++) {
ffffffffc02010cc:	0aa1                	addi	s5,s5,8
ffffffffc02010ce:	fd7917e3          	bne	s2,s7,ffffffffc020109c <buddy_system_comprehensive_check+0x43e>
    show_buddy_array(0, MAX_ORDER);
ffffffffc02010d2:	afbff0ef          	jal	ra,ffffffffc0200bcc <show_buddy_array.constprop.0>
    cprintf("2. 随机释放部分块...\n");
ffffffffc02010d6:	00002517          	auipc	a0,0x2
ffffffffc02010da:	b2250513          	addi	a0,a0,-1246 # ffffffffc0202bf8 <etext+0xd92>
ffffffffc02010de:	86eff0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc02010e2:	8952                	mv	s2,s4
    for (int i = 1; i < STRESS_TEST_COUNT; i += 2) {
ffffffffc02010e4:	4405                	li	s0,1
            size_t size = 1 << (i % 4);
ffffffffc02010e6:	4b05                	li	s6,1
    for (int i = 1; i < STRESS_TEST_COUNT; i += 2) {
ffffffffc02010e8:	4a9d                	li	s5,7
        if (pages[i] != NULL) {
ffffffffc02010ea:	00893503          	ld	a0,8(s2)
ffffffffc02010ee:	c909                	beqz	a0,ffffffffc0201100 <buddy_system_comprehensive_check+0x4a2>
            size_t size = 1 << (i % 4);
ffffffffc02010f0:	00347593          	andi	a1,s0,3
ffffffffc02010f4:	00bb15bb          	sllw	a1,s6,a1
ffffffffc02010f8:	d18ff0ef          	jal	ra,ffffffffc0200610 <buddy_system_free_pages.part.0>
            pages[i] = NULL;
ffffffffc02010fc:	00093423          	sd	zero,8(s2)
    for (int i = 1; i < STRESS_TEST_COUNT; i += 2) {
ffffffffc0201100:	2409                	addiw	s0,s0,2
ffffffffc0201102:	0941                	addi	s2,s2,16
ffffffffc0201104:	ff5413e3          	bne	s0,s5,ffffffffc02010ea <buddy_system_comprehensive_check+0x48c>
    show_buddy_array(0, MAX_ORDER);
ffffffffc0201108:	ac5ff0ef          	jal	ra,ffffffffc0200bcc <show_buddy_array.constprop.0>
    cprintf("3. 再次分配填补空缺...\n");
ffffffffc020110c:	00002517          	auipc	a0,0x2
ffffffffc0201110:	b0c50513          	addi	a0,a0,-1268 # ffffffffc0202c18 <etext+0xdb2>
ffffffffc0201114:	838ff0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc0201118:	8952                	mv	s2,s4
    for (int i = 1; i < STRESS_TEST_COUNT; i += 2) {
ffffffffc020111a:	4405                	li	s0,1
        size_t size = 1 << (i % 4);
ffffffffc020111c:	4b05                	li	s6,1
    for (int i = 1; i < STRESS_TEST_COUNT; i += 2) {
ffffffffc020111e:	4a9d                	li	s5,7
    if (n > buddy_sys.nr_free) {
ffffffffc0201120:	1084a603          	lw	a2,264(s1)
        size_t size = 1 << (i % 4);
ffffffffc0201124:	00347513          	andi	a0,s0,3
ffffffffc0201128:	00ab153b          	sllw	a0,s6,a0
    if (n > buddy_sys.nr_free) {
ffffffffc020112c:	02061793          	slli	a5,a2,0x20
ffffffffc0201130:	9381                	srli	a5,a5,0x20
ffffffffc0201132:	2ca7eb63          	bltu	a5,a0,ffffffffc0201408 <buddy_system_comprehensive_check+0x7aa>
ffffffffc0201136:	f3cff0ef          	jal	ra,ffffffffc0200872 <buddy_system_alloc_pages.part.0>
        pages[i] = buddy_system_alloc_pages(size);
ffffffffc020113a:	00a93423          	sd	a0,8(s2)
        assert(pages[i] != NULL);
ffffffffc020113e:	2c050c63          	beqz	a0,ffffffffc0201416 <buddy_system_comprehensive_check+0x7b8>
    for (int i = 1; i < STRESS_TEST_COUNT; i += 2) {
ffffffffc0201142:	2409                	addiw	s0,s0,2
ffffffffc0201144:	0941                	addi	s2,s2,16
ffffffffc0201146:	fd541de3          	bne	s0,s5,ffffffffc0201120 <buddy_system_comprehensive_check+0x4c2>
    show_buddy_array(0, MAX_ORDER);
ffffffffc020114a:	a83ff0ef          	jal	ra,ffffffffc0200bcc <show_buddy_array.constprop.0>
    cprintf("4. 全部释放...\n");
ffffffffc020114e:	00002517          	auipc	a0,0x2
ffffffffc0201152:	aea50513          	addi	a0,a0,-1302 # ffffffffc0202c38 <etext+0xdd2>
ffffffffc0201156:	ff7fe0ef          	jal	ra,ffffffffc020014c <cprintf>
            size_t size = 1 << (i % 4);
ffffffffc020115a:	4905                	li	s2,1
    for (int i = 0; i < STRESS_TEST_COUNT; i++) {
ffffffffc020115c:	4419                	li	s0,6
        if (pages[i] != NULL) {
ffffffffc020115e:	000a3503          	ld	a0,0(s4)
ffffffffc0201162:	c519                	beqz	a0,ffffffffc0201170 <buddy_system_comprehensive_check+0x512>
            size_t size = 1 << (i % 4);
ffffffffc0201164:	0039f593          	andi	a1,s3,3
ffffffffc0201168:	00b915bb          	sllw	a1,s2,a1
ffffffffc020116c:	ca4ff0ef          	jal	ra,ffffffffc0200610 <buddy_system_free_pages.part.0>
    for (int i = 0; i < STRESS_TEST_COUNT; i++) {
ffffffffc0201170:	2985                	addiw	s3,s3,1
ffffffffc0201172:	0a21                	addi	s4,s4,8
ffffffffc0201174:	fe8995e3          	bne	s3,s0,ffffffffc020115e <buddy_system_comprehensive_check+0x500>
    show_buddy_array(0, MAX_ORDER);
ffffffffc0201178:	a55ff0ef          	jal	ra,ffffffffc0200bcc <show_buddy_array.constprop.0>
    cprintf("=== END TEST: STRESS CONDITION ===\n\n");
ffffffffc020117c:	00002517          	auipc	a0,0x2
ffffffffc0201180:	ad450513          	addi	a0,a0,-1324 # ffffffffc0202c50 <etext+0xdea>
ffffffffc0201184:	fc9fe0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("=== BEGIN TEST: MERGE CONDITION ===\n");
ffffffffc0201188:	00002517          	auipc	a0,0x2
ffffffffc020118c:	af050513          	addi	a0,a0,-1296 # ffffffffc0202c78 <etext+0xe12>
ffffffffc0201190:	fbdfe0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("1. 分配4个16页的块...\n");
ffffffffc0201194:	00002517          	auipc	a0,0x2
ffffffffc0201198:	b0c50513          	addi	a0,a0,-1268 # ffffffffc0202ca0 <etext+0xe3a>
ffffffffc020119c:	fb1fe0ef          	jal	ra,ffffffffc020014c <cprintf>
    if (n > buddy_sys.nr_free) {
ffffffffc02011a0:	1084a603          	lw	a2,264(s1)
ffffffffc02011a4:	47bd                	li	a5,15
ffffffffc02011a6:	44c7fd63          	bgeu	a5,a2,ffffffffc0201600 <buddy_system_comprehensive_check+0x9a2>
ffffffffc02011aa:	4541                	li	a0,16
ffffffffc02011ac:	ec6ff0ef          	jal	ra,ffffffffc0200872 <buddy_system_alloc_pages.part.0>
ffffffffc02011b0:	89aa                	mv	s3,a0
ffffffffc02011b2:	1084a603          	lw	a2,264(s1)
ffffffffc02011b6:	47bd                	li	a5,15
ffffffffc02011b8:	40c7f463          	bgeu	a5,a2,ffffffffc02015c0 <buddy_system_comprehensive_check+0x962>
ffffffffc02011bc:	4541                	li	a0,16
ffffffffc02011be:	eb4ff0ef          	jal	ra,ffffffffc0200872 <buddy_system_alloc_pages.part.0>
ffffffffc02011c2:	892a                	mv	s2,a0
ffffffffc02011c4:	1084a603          	lw	a2,264(s1)
ffffffffc02011c8:	47bd                	li	a5,15
ffffffffc02011ca:	44c7f463          	bgeu	a5,a2,ffffffffc0201612 <buddy_system_comprehensive_check+0x9b4>
ffffffffc02011ce:	4541                	li	a0,16
ffffffffc02011d0:	ea2ff0ef          	jal	ra,ffffffffc0200872 <buddy_system_alloc_pages.part.0>
ffffffffc02011d4:	842a                	mv	s0,a0
ffffffffc02011d6:	1084a603          	lw	a2,264(s1)
ffffffffc02011da:	47bd                	li	a5,15
ffffffffc02011dc:	3ec7fb63          	bgeu	a5,a2,ffffffffc02015d2 <buddy_system_comprehensive_check+0x974>
ffffffffc02011e0:	4541                	li	a0,16
ffffffffc02011e2:	e90ff0ef          	jal	ra,ffffffffc0200872 <buddy_system_alloc_pages.part.0>
ffffffffc02011e6:	8a2a                	mv	s4,a0
    assert(p0 != NULL && p1 != NULL && p2 != NULL && p3 != NULL);
ffffffffc02011e8:	3e098c63          	beqz	s3,ffffffffc02015e0 <buddy_system_comprehensive_check+0x982>
ffffffffc02011ec:	3e090a63          	beqz	s2,ffffffffc02015e0 <buddy_system_comprehensive_check+0x982>
ffffffffc02011f0:	3e040863          	beqz	s0,ffffffffc02015e0 <buddy_system_comprehensive_check+0x982>
ffffffffc02011f4:	3e050663          	beqz	a0,ffffffffc02015e0 <buddy_system_comprehensive_check+0x982>
    show_buddy_array(0, MAX_ORDER);
ffffffffc02011f8:	9d5ff0ef          	jal	ra,ffffffffc0200bcc <show_buddy_array.constprop.0>
    cprintf("2. 按合并友好顺序释放...\n");
ffffffffc02011fc:	00002517          	auipc	a0,0x2
ffffffffc0201200:	afc50513          	addi	a0,a0,-1284 # ffffffffc0202cf8 <etext+0xe92>
ffffffffc0201204:	f49fe0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("   释放p0和p1(应该合并为32页块)...\n");
ffffffffc0201208:	00002517          	auipc	a0,0x2
ffffffffc020120c:	b1850513          	addi	a0,a0,-1256 # ffffffffc0202d20 <etext+0xeba>
ffffffffc0201210:	f3dfe0ef          	jal	ra,ffffffffc020014c <cprintf>
    assert(n > 0);
ffffffffc0201214:	45c1                	li	a1,16
ffffffffc0201216:	854e                	mv	a0,s3
ffffffffc0201218:	bf8ff0ef          	jal	ra,ffffffffc0200610 <buddy_system_free_pages.part.0>
ffffffffc020121c:	45c1                	li	a1,16
ffffffffc020121e:	854a                	mv	a0,s2
ffffffffc0201220:	bf0ff0ef          	jal	ra,ffffffffc0200610 <buddy_system_free_pages.part.0>
    show_buddy_array(0, MAX_ORDER);
ffffffffc0201224:	9a9ff0ef          	jal	ra,ffffffffc0200bcc <show_buddy_array.constprop.0>
    cprintf("   释放p2和p3(应该合并为另一个32页块)...\n");
ffffffffc0201228:	00002517          	auipc	a0,0x2
ffffffffc020122c:	b2850513          	addi	a0,a0,-1240 # ffffffffc0202d50 <etext+0xeea>
ffffffffc0201230:	f1dfe0ef          	jal	ra,ffffffffc020014c <cprintf>
    assert(n > 0);
ffffffffc0201234:	45c1                	li	a1,16
ffffffffc0201236:	8522                	mv	a0,s0
ffffffffc0201238:	bd8ff0ef          	jal	ra,ffffffffc0200610 <buddy_system_free_pages.part.0>
ffffffffc020123c:	45c1                	li	a1,16
ffffffffc020123e:	8552                	mv	a0,s4
ffffffffc0201240:	bd0ff0ef          	jal	ra,ffffffffc0200610 <buddy_system_free_pages.part.0>
    show_buddy_array(0, MAX_ORDER);
ffffffffc0201244:	989ff0ef          	jal	ra,ffffffffc0200bcc <show_buddy_array.constprop.0>
    cprintf("3. 验证最终合并结果...\n");
ffffffffc0201248:	00002517          	auipc	a0,0x2
ffffffffc020124c:	b4050513          	addi	a0,a0,-1216 # ffffffffc0202d88 <etext+0xf22>
ffffffffc0201250:	efdfe0ef          	jal	ra,ffffffffc020014c <cprintf>
    show_buddy_array(0, MAX_ORDER);
ffffffffc0201254:	979ff0ef          	jal	ra,ffffffffc0200bcc <show_buddy_array.constprop.0>
    cprintf("=== END TEST: MERGE CONDITION ===\n\n");
ffffffffc0201258:	00002517          	auipc	a0,0x2
ffffffffc020125c:	b5050513          	addi	a0,a0,-1200 # ffffffffc0202da8 <etext+0xf42>
ffffffffc0201260:	eedfe0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("=== BEGIN TEST: ERROR CONDITION ===\n");
ffffffffc0201264:	00002517          	auipc	a0,0x2
ffffffffc0201268:	b6c50513          	addi	a0,a0,-1172 # ffffffffc0202dd0 <etext+0xf6a>
ffffffffc020126c:	ee1fe0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("1. 测试分配0页...\n");
ffffffffc0201270:	00002517          	auipc	a0,0x2
ffffffffc0201274:	b8850513          	addi	a0,a0,-1144 # ffffffffc0202df8 <etext+0xf92>
ffffffffc0201278:	ed5fe0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("   预期行为：触发断言失败，跳过此测试\n");
ffffffffc020127c:	00002517          	auipc	a0,0x2
ffffffffc0201280:	b9450513          	addi	a0,a0,-1132 # ffffffffc0202e10 <etext+0xfaa>
ffffffffc0201284:	ec9fe0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("2. 测试分配极大值...\n");
ffffffffc0201288:	00002517          	auipc	a0,0x2
ffffffffc020128c:	bc050513          	addi	a0,a0,-1088 # ffffffffc0202e48 <etext+0xfe2>
ffffffffc0201290:	ebdfe0ef          	jal	ra,ffffffffc020014c <cprintf>
    if (n > buddy_sys.nr_free) {
ffffffffc0201294:	1084a603          	lw	a2,264(s1)
ffffffffc0201298:	400007b7          	lui	a5,0x40000
ffffffffc020129c:	38f66463          	bltu	a2,a5,ffffffffc0201624 <buddy_system_comprehensive_check+0x9c6>
ffffffffc02012a0:	40000537          	lui	a0,0x40000
ffffffffc02012a4:	dceff0ef          	jal	ra,ffffffffc0200872 <buddy_system_alloc_pages.part.0>
    assert(p_huge == NULL);
ffffffffc02012a8:	50051963          	bnez	a0,ffffffffc02017ba <buddy_system_comprehensive_check+0xb5c>
    cprintf("   分配失败，符合预期\n");
ffffffffc02012ac:	00002517          	auipc	a0,0x2
ffffffffc02012b0:	86450513          	addi	a0,a0,-1948 # ffffffffc0202b10 <etext+0xcaa>
ffffffffc02012b4:	e99fe0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("3. 测试边界值分配...\n");
ffffffffc02012b8:	00002517          	auipc	a0,0x2
ffffffffc02012bc:	bc050513          	addi	a0,a0,-1088 # ffffffffc0202e78 <etext+0x1012>
ffffffffc02012c0:	e8dfe0ef          	jal	ra,ffffffffc020014c <cprintf>
    if (n > buddy_sys.nr_free) {
ffffffffc02012c4:	1084a603          	lw	a2,264(s1)
ffffffffc02012c8:	6521                	lui	a0,0x8
ffffffffc02012ca:	36c57663          	bgeu	a0,a2,ffffffffc0201636 <buddy_system_comprehensive_check+0x9d8>
ffffffffc02012ce:	0505                	addi	a0,a0,1
ffffffffc02012d0:	da2ff0ef          	jal	ra,ffffffffc0200872 <buddy_system_alloc_pages.part.0>
    assert(p_overflow == NULL);
ffffffffc02012d4:	4a051363          	bnez	a0,ffffffffc020177a <buddy_system_comprehensive_check+0xb1c>
    cprintf("   分配 %u 页失败，符合预期\n", (1 << MAX_ORDER) + 1);
ffffffffc02012d8:	65a1                	lui	a1,0x8
ffffffffc02012da:	0585                	addi	a1,a1,1
ffffffffc02012dc:	00002517          	auipc	a0,0x2
ffffffffc02012e0:	bbc50513          	addi	a0,a0,-1092 # ffffffffc0202e98 <etext+0x1032>
ffffffffc02012e4:	e69fe0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("4. 测试内存耗尽情况...\n");
ffffffffc02012e8:	00002517          	auipc	a0,0x2
ffffffffc02012ec:	bd850513          	addi	a0,a0,-1064 # ffffffffc0202ec0 <etext+0x105a>
ffffffffc02012f0:	e5dfe0ef          	jal	ra,ffffffffc020014c <cprintf>
    size_t free_pages = buddy_sys.nr_free;
ffffffffc02012f4:	1084a983          	lw	s3,264(s1)
ffffffffc02012f8:	02099913          	slli	s2,s3,0x20
ffffffffc02012fc:	02095913          	srli	s2,s2,0x20
    assert(n > 0);
ffffffffc0201300:	40090d63          	beqz	s2,ffffffffc020171a <buddy_system_comprehensive_check+0xabc>
    if (n > buddy_sys.nr_free) {
ffffffffc0201304:	854a                	mv	a0,s2
ffffffffc0201306:	d6cff0ef          	jal	ra,ffffffffc0200872 <buddy_system_alloc_pages.part.0>
ffffffffc020130a:	842a                	mv	s0,a0
    if (p_max != NULL) {
ffffffffc020130c:	0e050763          	beqz	a0,ffffffffc02013fa <buddy_system_comprehensive_check+0x79c>
        cprintf("   成功分配所有内存: %u 页\n", (unsigned int)free_pages);
ffffffffc0201310:	85ce                	mv	a1,s3
ffffffffc0201312:	00002517          	auipc	a0,0x2
ffffffffc0201316:	bce50513          	addi	a0,a0,-1074 # ffffffffc0202ee0 <etext+0x107a>
ffffffffc020131a:	e33fe0ef          	jal	ra,ffffffffc020014c <cprintf>
    if (n > buddy_sys.nr_free) {
ffffffffc020131e:	1084a783          	lw	a5,264(s1)
ffffffffc0201322:	32078363          	beqz	a5,ffffffffc0201648 <buddy_system_comprehensive_check+0x9ea>
ffffffffc0201326:	4505                	li	a0,1
ffffffffc0201328:	d4aff0ef          	jal	ra,ffffffffc0200872 <buddy_system_alloc_pages.part.0>
        assert(p_no_memory == NULL);
ffffffffc020132c:	4a051763          	bnez	a0,ffffffffc02017da <buddy_system_comprehensive_check+0xb7c>
        cprintf("   内存耗尽时分配失败，符合预期\n");
ffffffffc0201330:	00002517          	auipc	a0,0x2
ffffffffc0201334:	bf050513          	addi	a0,a0,-1040 # ffffffffc0202f20 <etext+0x10ba>
ffffffffc0201338:	e15fe0ef          	jal	ra,ffffffffc020014c <cprintf>
    assert(n > 0);
ffffffffc020133c:	85ca                	mv	a1,s2
ffffffffc020133e:	8522                	mv	a0,s0
ffffffffc0201340:	ad0ff0ef          	jal	ra,ffffffffc0200610 <buddy_system_free_pages.part.0>
    cprintf("=== END TEST: ERROR CONDITION ===\n\n");
ffffffffc0201344:	00002517          	auipc	a0,0x2
ffffffffc0201348:	c5450513          	addi	a0,a0,-940 # ffffffffc0202f98 <etext+0x1132>
ffffffffc020134c:	e01fe0ef          	jal	ra,ffffffffc020014c <cprintf>
    buddy_system_check_stress_condition();
    buddy_system_check_merge_condition();
    buddy_system_check_error_condition();

    // 验证最终状态
    cprintf("最终空闲页数: %u\n", buddy_sys.nr_free);
ffffffffc0201350:	1084a583          	lw	a1,264(s1)
ffffffffc0201354:	00002517          	auipc	a0,0x2
ffffffffc0201358:	c6c50513          	addi	a0,a0,-916 # ffffffffc0202fc0 <etext+0x115a>
ffffffffc020135c:	df1fe0ef          	jal	ra,ffffffffc020014c <cprintf>
    assert(buddy_sys.nr_free == initial_free);
ffffffffc0201360:	1084a783          	lw	a5,264(s1)
ffffffffc0201364:	39979b63          	bne	a5,s9,ffffffffc02016fa <buddy_system_comprehensive_check+0xa9c>
    cprintf("✓ 内存泄漏检查通过\n");
ffffffffc0201368:	00002517          	auipc	a0,0x2
ffffffffc020136c:	c9850513          	addi	a0,a0,-872 # ffffffffc0203000 <etext+0x119a>
ffffffffc0201370:	dddfe0ef          	jal	ra,ffffffffc020014c <cprintf>

    cprintf("**************************************************\n");
ffffffffc0201374:	00001517          	auipc	a0,0x1
ffffffffc0201378:	0fc50513          	addi	a0,a0,252 # ffffffffc0202470 <etext+0x60a>
ffffffffc020137c:	dd1fe0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("***         ALL TESTS PASSED SUCCESSFULLY!         ***\n");
ffffffffc0201380:	00002517          	auipc	a0,0x2
ffffffffc0201384:	ca050513          	addi	a0,a0,-864 # ffffffffc0203020 <etext+0x11ba>
ffffffffc0201388:	dc5fe0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("**************************************************\n");
}
ffffffffc020138c:	640a                	ld	s0,128(sp)
ffffffffc020138e:	60aa                	ld	ra,136(sp)
ffffffffc0201390:	74e6                	ld	s1,120(sp)
ffffffffc0201392:	7946                	ld	s2,112(sp)
ffffffffc0201394:	79a6                	ld	s3,104(sp)
ffffffffc0201396:	7a06                	ld	s4,96(sp)
ffffffffc0201398:	6ae6                	ld	s5,88(sp)
ffffffffc020139a:	6b46                	ld	s6,80(sp)
ffffffffc020139c:	6ba6                	ld	s7,72(sp)
ffffffffc020139e:	6c06                	ld	s8,64(sp)
ffffffffc02013a0:	7ce2                	ld	s9,56(sp)
    cprintf("**************************************************\n");
ffffffffc02013a2:	00001517          	auipc	a0,0x1
ffffffffc02013a6:	0ce50513          	addi	a0,a0,206 # ffffffffc0202470 <etext+0x60a>
}
ffffffffc02013aa:	6149                	addi	sp,sp,144
    cprintf("**************************************************\n");
ffffffffc02013ac:	da1fe06f          	j	ffffffffc020014c <cprintf>
        cprintf("buddy_system: allocation failed, request %u pages, but only %u free\n",
ffffffffc02013b0:	85a2                	mv	a1,s0
ffffffffc02013b2:	00001517          	auipc	a0,0x1
ffffffffc02013b6:	f7e50513          	addi	a0,a0,-130 # ffffffffc0202330 <etext+0x4ca>
ffffffffc02013ba:	d93fe0ef          	jal	ra,ffffffffc020014c <cprintf>
        assert(pages[i] != NULL);
ffffffffc02013be:	00002697          	auipc	a3,0x2
ffffffffc02013c2:	80268693          	addi	a3,a3,-2046 # ffffffffc0202bc0 <etext+0xd5a>
ffffffffc02013c6:	00001617          	auipc	a2,0x1
ffffffffc02013ca:	e2a60613          	addi	a2,a2,-470 # ffffffffc02021f0 <etext+0x38a>
ffffffffc02013ce:	1ff00593          	li	a1,511
ffffffffc02013d2:	00001517          	auipc	a0,0x1
ffffffffc02013d6:	e3650513          	addi	a0,a0,-458 # ffffffffc0202208 <etext+0x3a2>
ffffffffc02013da:	de9fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
        cprintf("buddy_system: allocation failed, request %u pages, but only %u free\n",
ffffffffc02013de:	65a1                	lui	a1,0x8
ffffffffc02013e0:	00001517          	auipc	a0,0x1
ffffffffc02013e4:	f5050513          	addi	a0,a0,-176 # ffffffffc0202330 <etext+0x4ca>
ffffffffc02013e8:	d65fe0ef          	jal	ra,ffffffffc020014c <cprintf>
        cprintf("4. 最大分配失败，内存不足\n");
ffffffffc02013ec:	00001517          	auipc	a0,0x1
ffffffffc02013f0:	6ac50513          	addi	a0,a0,1708 # ffffffffc0202a98 <etext+0xc32>
ffffffffc02013f4:	d59fe0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc02013f8:	b93d                	j	ffffffffc0201036 <buddy_system_comprehensive_check+0x3d8>
        cprintf("   无法一次性分配所有内存，跳过内存耗尽测试\n");
ffffffffc02013fa:	00002517          	auipc	a0,0x2
ffffffffc02013fe:	b5650513          	addi	a0,a0,-1194 # ffffffffc0202f50 <etext+0x10ea>
ffffffffc0201402:	d4bfe0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc0201406:	bf3d                	j	ffffffffc0201344 <buddy_system_comprehensive_check+0x6e6>
        cprintf("buddy_system: allocation failed, request %u pages, but only %u free\n",
ffffffffc0201408:	85aa                	mv	a1,a0
ffffffffc020140a:	00001517          	auipc	a0,0x1
ffffffffc020140e:	f2650513          	addi	a0,a0,-218 # ffffffffc0202330 <etext+0x4ca>
ffffffffc0201412:	d3bfe0ef          	jal	ra,ffffffffc020014c <cprintf>
        assert(pages[i] != NULL);
ffffffffc0201416:	00001697          	auipc	a3,0x1
ffffffffc020141a:	7aa68693          	addi	a3,a3,1962 # ffffffffc0202bc0 <etext+0xd5a>
ffffffffc020141e:	00001617          	auipc	a2,0x1
ffffffffc0201422:	dd260613          	addi	a2,a2,-558 # ffffffffc02021f0 <etext+0x38a>
ffffffffc0201426:	21300593          	li	a1,531
ffffffffc020142a:	00001517          	auipc	a0,0x1
ffffffffc020142e:	dde50513          	addi	a0,a0,-546 # ffffffffc0202208 <etext+0x3a2>
ffffffffc0201432:	d91fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
        cprintf("buddy_system: allocation failed, request %u pages, but only %u free\n",
ffffffffc0201436:	45a9                	li	a1,10
ffffffffc0201438:	00001517          	auipc	a0,0x1
ffffffffc020143c:	ef850513          	addi	a0,a0,-264 # ffffffffc0202330 <etext+0x4ca>
ffffffffc0201440:	d0dfe0ef          	jal	ra,ffffffffc020014c <cprintf>
    assert(p2 != NULL);
ffffffffc0201444:	00001697          	auipc	a3,0x1
ffffffffc0201448:	1bc68693          	addi	a3,a3,444 # ffffffffc0202600 <etext+0x79a>
ffffffffc020144c:	00001617          	auipc	a2,0x1
ffffffffc0201450:	da460613          	addi	a2,a2,-604 # ffffffffc02021f0 <etext+0x38a>
ffffffffc0201454:	16100593          	li	a1,353
ffffffffc0201458:	00001517          	auipc	a0,0x1
ffffffffc020145c:	db050513          	addi	a0,a0,-592 # ffffffffc0202208 <etext+0x3a2>
ffffffffc0201460:	d63fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
        cprintf("buddy_system: allocation failed, request %u pages, but only %u free\n",
ffffffffc0201464:	45a9                	li	a1,10
ffffffffc0201466:	00001517          	auipc	a0,0x1
ffffffffc020146a:	eca50513          	addi	a0,a0,-310 # ffffffffc0202330 <etext+0x4ca>
ffffffffc020146e:	cdffe0ef          	jal	ra,ffffffffc020014c <cprintf>
    assert(p0 != NULL);
ffffffffc0201472:	00001697          	auipc	a3,0x1
ffffffffc0201476:	13e68693          	addi	a3,a3,318 # ffffffffc02025b0 <etext+0x74a>
ffffffffc020147a:	00001617          	auipc	a2,0x1
ffffffffc020147e:	d7660613          	addi	a2,a2,-650 # ffffffffc02021f0 <etext+0x38a>
ffffffffc0201482:	15700593          	li	a1,343
ffffffffc0201486:	00001517          	auipc	a0,0x1
ffffffffc020148a:	d8250513          	addi	a0,a0,-638 # ffffffffc0202208 <etext+0x3a2>
ffffffffc020148e:	d35fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
        cprintf("buddy_system: allocation failed, request %u pages, but only %u free\n",
ffffffffc0201492:	45a9                	li	a1,10
ffffffffc0201494:	00001517          	auipc	a0,0x1
ffffffffc0201498:	e9c50513          	addi	a0,a0,-356 # ffffffffc0202330 <etext+0x4ca>
ffffffffc020149c:	cb1fe0ef          	jal	ra,ffffffffc020014c <cprintf>
    assert(p1 != NULL);
ffffffffc02014a0:	00001697          	auipc	a3,0x1
ffffffffc02014a4:	13868693          	addi	a3,a3,312 # ffffffffc02025d8 <etext+0x772>
ffffffffc02014a8:	00001617          	auipc	a2,0x1
ffffffffc02014ac:	d4860613          	addi	a2,a2,-696 # ffffffffc02021f0 <etext+0x38a>
ffffffffc02014b0:	15c00593          	li	a1,348
ffffffffc02014b4:	00001517          	auipc	a0,0x1
ffffffffc02014b8:	d5450513          	addi	a0,a0,-684 # ffffffffc0202208 <etext+0x3a2>
ffffffffc02014bc:	d07fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
        cprintf("buddy_system: allocation failed, request %u pages, but only %u free\n",
ffffffffc02014c0:	4601                	li	a2,0
ffffffffc02014c2:	4585                	li	a1,1
ffffffffc02014c4:	00001517          	auipc	a0,0x1
ffffffffc02014c8:	e6c50513          	addi	a0,a0,-404 # ffffffffc0202330 <etext+0x4ca>
ffffffffc02014cc:	c81fe0ef          	jal	ra,ffffffffc020014c <cprintf>
    assert(p_min != NULL);
ffffffffc02014d0:	00001697          	auipc	a3,0x1
ffffffffc02014d4:	54868693          	addi	a3,a3,1352 # ffffffffc0202a18 <etext+0xbb2>
ffffffffc02014d8:	00001617          	auipc	a2,0x1
ffffffffc02014dc:	d1860613          	addi	a2,a2,-744 # ffffffffc02021f0 <etext+0x38a>
ffffffffc02014e0:	1cf00593          	li	a1,463
ffffffffc02014e4:	00001517          	auipc	a0,0x1
ffffffffc02014e8:	d2450513          	addi	a0,a0,-732 # ffffffffc0202208 <etext+0x3a2>
ffffffffc02014ec:	cd7fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
        cprintf("buddy_system: allocation failed, request %u pages, but only %u free\n",
ffffffffc02014f0:	45a9                	li	a1,10
ffffffffc02014f2:	00001517          	auipc	a0,0x1
ffffffffc02014f6:	e3e50513          	addi	a0,a0,-450 # ffffffffc0202330 <etext+0x4ca>
ffffffffc02014fa:	c53fe0ef          	jal	ra,ffffffffc020014c <cprintf>
    assert(p0 != NULL);
ffffffffc02014fe:	00001697          	auipc	a3,0x1
ffffffffc0201502:	0b268693          	addi	a3,a3,178 # ffffffffc02025b0 <etext+0x74a>
ffffffffc0201506:	00001617          	auipc	a2,0x1
ffffffffc020150a:	cea60613          	addi	a2,a2,-790 # ffffffffc02021f0 <etext+0x38a>
ffffffffc020150e:	19600593          	li	a1,406
ffffffffc0201512:	00001517          	auipc	a0,0x1
ffffffffc0201516:	cf650513          	addi	a0,a0,-778 # ffffffffc0202208 <etext+0x3a2>
ffffffffc020151a:	ca9fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
        cprintf("buddy_system: allocation failed, request %u pages, but only %u free\n",
ffffffffc020151e:	06400593          	li	a1,100
ffffffffc0201522:	00001517          	auipc	a0,0x1
ffffffffc0201526:	e0e50513          	addi	a0,a0,-498 # ffffffffc0202330 <etext+0x4ca>
ffffffffc020152a:	c23fe0ef          	jal	ra,ffffffffc020014c <cprintf>
    assert(p2 != NULL);
ffffffffc020152e:	00001697          	auipc	a3,0x1
ffffffffc0201532:	0d268693          	addi	a3,a3,210 # ffffffffc0202600 <etext+0x79a>
ffffffffc0201536:	00001617          	auipc	a2,0x1
ffffffffc020153a:	cba60613          	addi	a2,a2,-838 # ffffffffc02021f0 <etext+0x38a>
ffffffffc020153e:	1a000593          	li	a1,416
ffffffffc0201542:	00001517          	auipc	a0,0x1
ffffffffc0201546:	cc650513          	addi	a0,a0,-826 # ffffffffc0202208 <etext+0x3a2>
ffffffffc020154a:	c79fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
        cprintf("buddy_system: allocation failed, request %u pages, but only %u free\n",
ffffffffc020154e:	0c800593          	li	a1,200
ffffffffc0201552:	00001517          	auipc	a0,0x1
ffffffffc0201556:	dde50513          	addi	a0,a0,-546 # ffffffffc0202330 <etext+0x4ca>
ffffffffc020155a:	bf3fe0ef          	jal	ra,ffffffffc020014c <cprintf>
    assert(p3 != NULL);
ffffffffc020155e:	00001697          	auipc	a3,0x1
ffffffffc0201562:	35268693          	addi	a3,a3,850 # ffffffffc02028b0 <etext+0xa4a>
ffffffffc0201566:	00001617          	auipc	a2,0x1
ffffffffc020156a:	c8a60613          	addi	a2,a2,-886 # ffffffffc02021f0 <etext+0x38a>
ffffffffc020156e:	1a500593          	li	a1,421
ffffffffc0201572:	00001517          	auipc	a0,0x1
ffffffffc0201576:	c9650513          	addi	a0,a0,-874 # ffffffffc0202208 <etext+0x3a2>
ffffffffc020157a:	c49fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
        cprintf("buddy_system: allocation failed, request %u pages, but only %u free\n",
ffffffffc020157e:	03200593          	li	a1,50
ffffffffc0201582:	00001517          	auipc	a0,0x1
ffffffffc0201586:	dae50513          	addi	a0,a0,-594 # ffffffffc0202330 <etext+0x4ca>
ffffffffc020158a:	bc3fe0ef          	jal	ra,ffffffffc020014c <cprintf>
    assert(p1 != NULL);
ffffffffc020158e:	00001697          	auipc	a3,0x1
ffffffffc0201592:	04a68693          	addi	a3,a3,74 # ffffffffc02025d8 <etext+0x772>
ffffffffc0201596:	00001617          	auipc	a2,0x1
ffffffffc020159a:	c5a60613          	addi	a2,a2,-934 # ffffffffc02021f0 <etext+0x38a>
ffffffffc020159e:	19b00593          	li	a1,411
ffffffffc02015a2:	00001517          	auipc	a0,0x1
ffffffffc02015a6:	c6650513          	addi	a0,a0,-922 # ffffffffc0202208 <etext+0x3a2>
ffffffffc02015aa:	c19fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
        cprintf("buddy_system: allocation failed, request %u pages, but only %u free\n",
ffffffffc02015ae:	00150593          	addi	a1,a0,1
ffffffffc02015b2:	00001517          	auipc	a0,0x1
ffffffffc02015b6:	d7e50513          	addi	a0,a0,-642 # ffffffffc0202330 <etext+0x4ca>
ffffffffc02015ba:	b93fe0ef          	jal	ra,ffffffffc020014c <cprintf>
    assert(p_overflow == NULL);
ffffffffc02015be:	bc69                	j	ffffffffc0201058 <buddy_system_comprehensive_check+0x3fa>
        cprintf("buddy_system: allocation failed, request %u pages, but only %u free\n",
ffffffffc02015c0:	45c1                	li	a1,16
ffffffffc02015c2:	00001517          	auipc	a0,0x1
ffffffffc02015c6:	d6e50513          	addi	a0,a0,-658 # ffffffffc0202330 <etext+0x4ca>
ffffffffc02015ca:	b83fe0ef          	jal	ra,ffffffffc020014c <cprintf>
        return NULL;
ffffffffc02015ce:	4901                	li	s2,0
ffffffffc02015d0:	bed5                	j	ffffffffc02011c4 <buddy_system_comprehensive_check+0x566>
        cprintf("buddy_system: allocation failed, request %u pages, but only %u free\n",
ffffffffc02015d2:	45c1                	li	a1,16
ffffffffc02015d4:	00001517          	auipc	a0,0x1
ffffffffc02015d8:	d5c50513          	addi	a0,a0,-676 # ffffffffc0202330 <etext+0x4ca>
ffffffffc02015dc:	b71fe0ef          	jal	ra,ffffffffc020014c <cprintf>
    assert(p0 != NULL && p1 != NULL && p2 != NULL && p3 != NULL);
ffffffffc02015e0:	00001697          	auipc	a3,0x1
ffffffffc02015e4:	6e068693          	addi	a3,a3,1760 # ffffffffc0202cc0 <etext+0xe5a>
ffffffffc02015e8:	00001617          	auipc	a2,0x1
ffffffffc02015ec:	c0860613          	addi	a2,a2,-1016 # ffffffffc02021f0 <etext+0x38a>
ffffffffc02015f0:	23400593          	li	a1,564
ffffffffc02015f4:	00001517          	auipc	a0,0x1
ffffffffc02015f8:	c1450513          	addi	a0,a0,-1004 # ffffffffc0202208 <etext+0x3a2>
ffffffffc02015fc:	bc7fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
        cprintf("buddy_system: allocation failed, request %u pages, but only %u free\n",
ffffffffc0201600:	45c1                	li	a1,16
ffffffffc0201602:	00001517          	auipc	a0,0x1
ffffffffc0201606:	d2e50513          	addi	a0,a0,-722 # ffffffffc0202330 <etext+0x4ca>
ffffffffc020160a:	b43fe0ef          	jal	ra,ffffffffc020014c <cprintf>
        return NULL;
ffffffffc020160e:	4981                	li	s3,0
ffffffffc0201610:	b64d                	j	ffffffffc02011b2 <buddy_system_comprehensive_check+0x554>
        cprintf("buddy_system: allocation failed, request %u pages, but only %u free\n",
ffffffffc0201612:	45c1                	li	a1,16
ffffffffc0201614:	00001517          	auipc	a0,0x1
ffffffffc0201618:	d1c50513          	addi	a0,a0,-740 # ffffffffc0202330 <etext+0x4ca>
ffffffffc020161c:	b31fe0ef          	jal	ra,ffffffffc020014c <cprintf>
        return NULL;
ffffffffc0201620:	4401                	li	s0,0
ffffffffc0201622:	be55                	j	ffffffffc02011d6 <buddy_system_comprehensive_check+0x578>
        cprintf("buddy_system: allocation failed, request %u pages, but only %u free\n",
ffffffffc0201624:	400005b7          	lui	a1,0x40000
ffffffffc0201628:	00001517          	auipc	a0,0x1
ffffffffc020162c:	d0850513          	addi	a0,a0,-760 # ffffffffc0202330 <etext+0x4ca>
ffffffffc0201630:	b1dfe0ef          	jal	ra,ffffffffc020014c <cprintf>
    assert(p_huge == NULL);
ffffffffc0201634:	b9a5                	j	ffffffffc02012ac <buddy_system_comprehensive_check+0x64e>
        cprintf("buddy_system: allocation failed, request %u pages, but only %u free\n",
ffffffffc0201636:	00150593          	addi	a1,a0,1
ffffffffc020163a:	00001517          	auipc	a0,0x1
ffffffffc020163e:	cf650513          	addi	a0,a0,-778 # ffffffffc0202330 <etext+0x4ca>
ffffffffc0201642:	b0bfe0ef          	jal	ra,ffffffffc020014c <cprintf>
    assert(p_overflow == NULL);
ffffffffc0201646:	b949                	j	ffffffffc02012d8 <buddy_system_comprehensive_check+0x67a>
        cprintf("buddy_system: allocation failed, request %u pages, but only %u free\n",
ffffffffc0201648:	4601                	li	a2,0
ffffffffc020164a:	4585                	li	a1,1
ffffffffc020164c:	00001517          	auipc	a0,0x1
ffffffffc0201650:	ce450513          	addi	a0,a0,-796 # ffffffffc0202330 <etext+0x4ca>
ffffffffc0201654:	af9fe0ef          	jal	ra,ffffffffc020014c <cprintf>
        assert(p_no_memory == NULL);
ffffffffc0201658:	b9e1                	j	ffffffffc0201330 <buddy_system_comprehensive_check+0x6d2>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc020165a:	00001697          	auipc	a3,0x1
ffffffffc020165e:	01668693          	addi	a3,a3,22 # ffffffffc0202670 <etext+0x80a>
ffffffffc0201662:	00001617          	auipc	a2,0x1
ffffffffc0201666:	b8e60613          	addi	a2,a2,-1138 # ffffffffc02021f0 <etext+0x38a>
ffffffffc020166a:	16a00593          	li	a1,362
ffffffffc020166e:	00001517          	auipc	a0,0x1
ffffffffc0201672:	b9a50513          	addi	a0,a0,-1126 # ffffffffc0202208 <etext+0x3a2>
ffffffffc0201676:	b4dfe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(p0 != p1 && p0 != p2 && p0 != p3);
ffffffffc020167a:	00001697          	auipc	a3,0x1
ffffffffc020167e:	24668693          	addi	a3,a3,582 # ffffffffc02028c0 <etext+0xa5a>
ffffffffc0201682:	00001617          	auipc	a2,0x1
ffffffffc0201686:	b6e60613          	addi	a2,a2,-1170 # ffffffffc02021f0 <etext+0x38a>
ffffffffc020168a:	1aa00593          	li	a1,426
ffffffffc020168e:	00001517          	auipc	a0,0x1
ffffffffc0201692:	b7a50513          	addi	a0,a0,-1158 # ffffffffc0202208 <etext+0x3a2>
ffffffffc0201696:	b2dfe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(p1 != p2 && p1 != p3 && p2 != p3);
ffffffffc020169a:	00001697          	auipc	a3,0x1
ffffffffc020169e:	24e68693          	addi	a3,a3,590 # ffffffffc02028e8 <etext+0xa82>
ffffffffc02016a2:	00001617          	auipc	a2,0x1
ffffffffc02016a6:	b4e60613          	addi	a2,a2,-1202 # ffffffffc02021f0 <etext+0x38a>
ffffffffc02016aa:	1ab00593          	li	a1,427
ffffffffc02016ae:	00001517          	auipc	a0,0x1
ffffffffc02016b2:	b5a50513          	addi	a0,a0,-1190 # ffffffffc0202208 <etext+0x3a2>
ffffffffc02016b6:	b0dfe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc02016ba:	00001697          	auipc	a3,0x1
ffffffffc02016be:	fde68693          	addi	a3,a3,-34 # ffffffffc0202698 <etext+0x832>
ffffffffc02016c2:	00001617          	auipc	a2,0x1
ffffffffc02016c6:	b2e60613          	addi	a2,a2,-1234 # ffffffffc02021f0 <etext+0x38a>
ffffffffc02016ca:	16c00593          	li	a1,364
ffffffffc02016ce:	00001517          	auipc	a0,0x1
ffffffffc02016d2:	b3a50513          	addi	a0,a0,-1222 # ffffffffc0202208 <etext+0x3a2>
ffffffffc02016d6:	aedfe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc02016da:	00001697          	auipc	a3,0x1
ffffffffc02016de:	ffe68693          	addi	a3,a3,-2 # ffffffffc02026d8 <etext+0x872>
ffffffffc02016e2:	00001617          	auipc	a2,0x1
ffffffffc02016e6:	b0e60613          	addi	a2,a2,-1266 # ffffffffc02021f0 <etext+0x38a>
ffffffffc02016ea:	16e00593          	li	a1,366
ffffffffc02016ee:	00001517          	auipc	a0,0x1
ffffffffc02016f2:	b1a50513          	addi	a0,a0,-1254 # ffffffffc0202208 <etext+0x3a2>
ffffffffc02016f6:	acdfe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(buddy_sys.nr_free == initial_free);
ffffffffc02016fa:	00002697          	auipc	a3,0x2
ffffffffc02016fe:	8de68693          	addi	a3,a3,-1826 # ffffffffc0202fd8 <etext+0x1172>
ffffffffc0201702:	00001617          	auipc	a2,0x1
ffffffffc0201706:	aee60613          	addi	a2,a2,-1298 # ffffffffc02021f0 <etext+0x38a>
ffffffffc020170a:	29200593          	li	a1,658
ffffffffc020170e:	00001517          	auipc	a0,0x1
ffffffffc0201712:	afa50513          	addi	a0,a0,-1286 # ffffffffc0202208 <etext+0x3a2>
ffffffffc0201716:	aadfe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(n > 0);
ffffffffc020171a:	00001697          	auipc	a3,0x1
ffffffffc020171e:	ace68693          	addi	a3,a3,-1330 # ffffffffc02021e8 <etext+0x382>
ffffffffc0201722:	00001617          	auipc	a2,0x1
ffffffffc0201726:	ace60613          	addi	a2,a2,-1330 # ffffffffc02021f0 <etext+0x38a>
ffffffffc020172a:	0b100593          	li	a1,177
ffffffffc020172e:	00001517          	auipc	a0,0x1
ffffffffc0201732:	ada50513          	addi	a0,a0,-1318 # ffffffffc0202208 <etext+0x3a2>
ffffffffc0201736:	a8dfe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc020173a:	00001697          	auipc	a3,0x1
ffffffffc020173e:	fde68693          	addi	a3,a3,-34 # ffffffffc0202718 <etext+0x8b2>
ffffffffc0201742:	00001617          	auipc	a2,0x1
ffffffffc0201746:	aae60613          	addi	a2,a2,-1362 # ffffffffc02021f0 <etext+0x38a>
ffffffffc020174a:	17000593          	li	a1,368
ffffffffc020174e:	00001517          	auipc	a0,0x1
ffffffffc0201752:	aba50513          	addi	a0,a0,-1350 # ffffffffc0202208 <etext+0x3a2>
ffffffffc0201756:	a6dfe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(p_overflow == NULL);
ffffffffc020175a:	00001697          	auipc	a3,0x1
ffffffffc020175e:	39e68693          	addi	a3,a3,926 # ffffffffc0202af8 <etext+0xc92>
ffffffffc0201762:	00001617          	auipc	a2,0x1
ffffffffc0201766:	a8e60613          	addi	a2,a2,-1394 # ffffffffc02021f0 <etext+0x38a>
ffffffffc020176a:	1e700593          	li	a1,487
ffffffffc020176e:	00001517          	auipc	a0,0x1
ffffffffc0201772:	a9a50513          	addi	a0,a0,-1382 # ffffffffc0202208 <etext+0x3a2>
ffffffffc0201776:	a4dfe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(p_overflow == NULL);
ffffffffc020177a:	00001697          	auipc	a3,0x1
ffffffffc020177e:	37e68693          	addi	a3,a3,894 # ffffffffc0202af8 <etext+0xc92>
ffffffffc0201782:	00001617          	auipc	a2,0x1
ffffffffc0201786:	a6e60613          	addi	a2,a2,-1426 # ffffffffc02021f0 <etext+0x38a>
ffffffffc020178a:	26100593          	li	a1,609
ffffffffc020178e:	00001517          	auipc	a0,0x1
ffffffffc0201792:	a7a50513          	addi	a0,a0,-1414 # ffffffffc0202208 <etext+0x3a2>
ffffffffc0201796:	a2dfe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc020179a:	00001697          	auipc	a3,0x1
ffffffffc020179e:	f5e68693          	addi	a3,a3,-162 # ffffffffc02026f8 <etext+0x892>
ffffffffc02017a2:	00001617          	auipc	a2,0x1
ffffffffc02017a6:	a4e60613          	addi	a2,a2,-1458 # ffffffffc02021f0 <etext+0x38a>
ffffffffc02017aa:	16f00593          	li	a1,367
ffffffffc02017ae:	00001517          	auipc	a0,0x1
ffffffffc02017b2:	a5a50513          	addi	a0,a0,-1446 # ffffffffc0202208 <etext+0x3a2>
ffffffffc02017b6:	a0dfe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(p_huge == NULL);
ffffffffc02017ba:	00001697          	auipc	a3,0x1
ffffffffc02017be:	6ae68693          	addi	a3,a3,1710 # ffffffffc0202e68 <etext+0x1002>
ffffffffc02017c2:	00001617          	auipc	a2,0x1
ffffffffc02017c6:	a2e60613          	addi	a2,a2,-1490 # ffffffffc02021f0 <etext+0x38a>
ffffffffc02017ca:	25b00593          	li	a1,603
ffffffffc02017ce:	00001517          	auipc	a0,0x1
ffffffffc02017d2:	a3a50513          	addi	a0,a0,-1478 # ffffffffc0202208 <etext+0x3a2>
ffffffffc02017d6:	9edfe0ef          	jal	ra,ffffffffc02001c2 <__panic>
        assert(p_no_memory == NULL);
ffffffffc02017da:	00001697          	auipc	a3,0x1
ffffffffc02017de:	72e68693          	addi	a3,a3,1838 # ffffffffc0202f08 <etext+0x10a2>
ffffffffc02017e2:	00001617          	auipc	a2,0x1
ffffffffc02017e6:	a0e60613          	addi	a2,a2,-1522 # ffffffffc02021f0 <etext+0x38a>
ffffffffc02017ea:	26d00593          	li	a1,621
ffffffffc02017ee:	00001517          	auipc	a0,0x1
ffffffffc02017f2:	a1a50513          	addi	a0,a0,-1510 # ffffffffc0202208 <etext+0x3a2>
ffffffffc02017f6:	9cdfe0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc02017fa <pmm_init>:

static void check_alloc_page(void);

// init_pmm_manager - initialize a pmm_manager instance
static void init_pmm_manager(void) {
    pmm_manager = &buddy_system_pmm_manager; //默认是default，这里要改成相应的
ffffffffc02017fa:	00002797          	auipc	a5,0x2
ffffffffc02017fe:	87e78793          	addi	a5,a5,-1922 # ffffffffc0203078 <buddy_system_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201802:	638c                	ld	a1,0(a5)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
    }
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
ffffffffc0201804:	7179                	addi	sp,sp,-48
ffffffffc0201806:	f022                	sd	s0,32(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201808:	00002517          	auipc	a0,0x2
ffffffffc020180c:	8a850513          	addi	a0,a0,-1880 # ffffffffc02030b0 <buddy_system_pmm_manager+0x38>
    pmm_manager = &buddy_system_pmm_manager; //默认是default，这里要改成相应的
ffffffffc0201810:	00006417          	auipc	s0,0x6
ffffffffc0201814:	94040413          	addi	s0,s0,-1728 # ffffffffc0207150 <pmm_manager>
void pmm_init(void) {
ffffffffc0201818:	f406                	sd	ra,40(sp)
ffffffffc020181a:	ec26                	sd	s1,24(sp)
ffffffffc020181c:	e44e                	sd	s3,8(sp)
ffffffffc020181e:	e84a                	sd	s2,16(sp)
ffffffffc0201820:	e052                	sd	s4,0(sp)
    pmm_manager = &buddy_system_pmm_manager; //默认是default，这里要改成相应的
ffffffffc0201822:	e01c                	sd	a5,0(s0)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201824:	929fe0ef          	jal	ra,ffffffffc020014c <cprintf>
    pmm_manager->init();
ffffffffc0201828:	601c                	ld	a5,0(s0)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc020182a:	00006497          	auipc	s1,0x6
ffffffffc020182e:	93e48493          	addi	s1,s1,-1730 # ffffffffc0207168 <va_pa_offset>
    pmm_manager->init();
ffffffffc0201832:	679c                	ld	a5,8(a5)
ffffffffc0201834:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0201836:	57f5                	li	a5,-3
ffffffffc0201838:	07fa                	slli	a5,a5,0x1e
ffffffffc020183a:	e09c                	sd	a5,0(s1)
    uint64_t mem_begin = get_memory_base();
ffffffffc020183c:	d81fe0ef          	jal	ra,ffffffffc02005bc <get_memory_base>
ffffffffc0201840:	89aa                	mv	s3,a0
    uint64_t mem_size  = get_memory_size();
ffffffffc0201842:	d85fe0ef          	jal	ra,ffffffffc02005c6 <get_memory_size>
    if (mem_size == 0) {
ffffffffc0201846:	14050d63          	beqz	a0,ffffffffc02019a0 <pmm_init+0x1a6>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc020184a:	892a                	mv	s2,a0
    cprintf("physcial memory map:\n");
ffffffffc020184c:	00002517          	auipc	a0,0x2
ffffffffc0201850:	8ac50513          	addi	a0,a0,-1876 # ffffffffc02030f8 <buddy_system_pmm_manager+0x80>
ffffffffc0201854:	8f9fe0ef          	jal	ra,ffffffffc020014c <cprintf>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc0201858:	01298a33          	add	s4,s3,s2
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin,
ffffffffc020185c:	864e                	mv	a2,s3
ffffffffc020185e:	fffa0693          	addi	a3,s4,-1
ffffffffc0201862:	85ca                	mv	a1,s2
ffffffffc0201864:	00002517          	auipc	a0,0x2
ffffffffc0201868:	8ac50513          	addi	a0,a0,-1876 # ffffffffc0203110 <buddy_system_pmm_manager+0x98>
ffffffffc020186c:	8e1fe0ef          	jal	ra,ffffffffc020014c <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc0201870:	c80007b7          	lui	a5,0xc8000
ffffffffc0201874:	8652                	mv	a2,s4
ffffffffc0201876:	0d47e463          	bltu	a5,s4,ffffffffc020193e <pmm_init+0x144>
ffffffffc020187a:	00007797          	auipc	a5,0x7
ffffffffc020187e:	8f578793          	addi	a5,a5,-1803 # ffffffffc020816f <end+0xfff>
ffffffffc0201882:	757d                	lui	a0,0xfffff
ffffffffc0201884:	8d7d                	and	a0,a0,a5
ffffffffc0201886:	8231                	srli	a2,a2,0xc
ffffffffc0201888:	00006797          	auipc	a5,0x6
ffffffffc020188c:	8ac7bc23          	sd	a2,-1864(a5) # ffffffffc0207140 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0201890:	00006797          	auipc	a5,0x6
ffffffffc0201894:	8aa7bc23          	sd	a0,-1864(a5) # ffffffffc0207148 <pages>
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0201898:	000807b7          	lui	a5,0x80
ffffffffc020189c:	002005b7          	lui	a1,0x200
ffffffffc02018a0:	02f60563          	beq	a2,a5,ffffffffc02018ca <pmm_init+0xd0>
ffffffffc02018a4:	00261593          	slli	a1,a2,0x2
ffffffffc02018a8:	00c586b3          	add	a3,a1,a2
ffffffffc02018ac:	fec007b7          	lui	a5,0xfec00
ffffffffc02018b0:	97aa                	add	a5,a5,a0
ffffffffc02018b2:	068e                	slli	a3,a3,0x3
ffffffffc02018b4:	96be                	add	a3,a3,a5
ffffffffc02018b6:	87aa                	mv	a5,a0
        SetPageReserved(pages + i);
ffffffffc02018b8:	6798                	ld	a4,8(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc02018ba:	02878793          	addi	a5,a5,40 # fffffffffec00028 <end+0x3e9f8eb8>
        SetPageReserved(pages + i);
ffffffffc02018be:	00176713          	ori	a4,a4,1
ffffffffc02018c2:	fee7b023          	sd	a4,-32(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc02018c6:	fef699e3          	bne	a3,a5,ffffffffc02018b8 <pmm_init+0xbe>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02018ca:	95b2                	add	a1,a1,a2
ffffffffc02018cc:	fec006b7          	lui	a3,0xfec00
ffffffffc02018d0:	96aa                	add	a3,a3,a0
ffffffffc02018d2:	058e                	slli	a1,a1,0x3
ffffffffc02018d4:	96ae                	add	a3,a3,a1
ffffffffc02018d6:	c02007b7          	lui	a5,0xc0200
ffffffffc02018da:	0af6e763          	bltu	a3,a5,ffffffffc0201988 <pmm_init+0x18e>
ffffffffc02018de:	6098                	ld	a4,0(s1)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc02018e0:	77fd                	lui	a5,0xfffff
ffffffffc02018e2:	00fa75b3          	and	a1,s4,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02018e6:	8e99                	sub	a3,a3,a4
    if (freemem < mem_end) {
ffffffffc02018e8:	04b6ee63          	bltu	a3,a1,ffffffffc0201944 <pmm_init+0x14a>
    satp_physical = PADDR(satp_virtual);
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc02018ec:	601c                	ld	a5,0(s0)
ffffffffc02018ee:	7b9c                	ld	a5,48(a5)
ffffffffc02018f0:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc02018f2:	00002517          	auipc	a0,0x2
ffffffffc02018f6:	8a650513          	addi	a0,a0,-1882 # ffffffffc0203198 <buddy_system_pmm_manager+0x120>
ffffffffc02018fa:	853fe0ef          	jal	ra,ffffffffc020014c <cprintf>
    satp_virtual = (pte_t*)boot_page_table_sv39;
ffffffffc02018fe:	00004597          	auipc	a1,0x4
ffffffffc0201902:	70258593          	addi	a1,a1,1794 # ffffffffc0206000 <boot_page_table_sv39>
ffffffffc0201906:	00006797          	auipc	a5,0x6
ffffffffc020190a:	84b7bd23          	sd	a1,-1958(a5) # ffffffffc0207160 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc020190e:	c02007b7          	lui	a5,0xc0200
ffffffffc0201912:	0af5e363          	bltu	a1,a5,ffffffffc02019b8 <pmm_init+0x1be>
ffffffffc0201916:	6090                	ld	a2,0(s1)
}
ffffffffc0201918:	7402                	ld	s0,32(sp)
ffffffffc020191a:	70a2                	ld	ra,40(sp)
ffffffffc020191c:	64e2                	ld	s1,24(sp)
ffffffffc020191e:	6942                	ld	s2,16(sp)
ffffffffc0201920:	69a2                	ld	s3,8(sp)
ffffffffc0201922:	6a02                	ld	s4,0(sp)
    satp_physical = PADDR(satp_virtual);
ffffffffc0201924:	40c58633          	sub	a2,a1,a2
ffffffffc0201928:	00006797          	auipc	a5,0x6
ffffffffc020192c:	82c7b823          	sd	a2,-2000(a5) # ffffffffc0207158 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0201930:	00002517          	auipc	a0,0x2
ffffffffc0201934:	88850513          	addi	a0,a0,-1912 # ffffffffc02031b8 <buddy_system_pmm_manager+0x140>
}
ffffffffc0201938:	6145                	addi	sp,sp,48
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc020193a:	813fe06f          	j	ffffffffc020014c <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc020193e:	c8000637          	lui	a2,0xc8000
ffffffffc0201942:	bf25                	j	ffffffffc020187a <pmm_init+0x80>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0201944:	6705                	lui	a4,0x1
ffffffffc0201946:	177d                	addi	a4,a4,-1
ffffffffc0201948:	96ba                	add	a3,a3,a4
ffffffffc020194a:	8efd                	and	a3,a3,a5
static inline int page_ref_dec(struct Page *page) {
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa) {
    if (PPN(pa) >= npage) {
ffffffffc020194c:	00c6d793          	srli	a5,a3,0xc
ffffffffc0201950:	02c7f063          	bgeu	a5,a2,ffffffffc0201970 <pmm_init+0x176>
    pmm_manager->init_memmap(base, n);
ffffffffc0201954:	6010                	ld	a2,0(s0)
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
ffffffffc0201956:	fff80737          	lui	a4,0xfff80
ffffffffc020195a:	973e                	add	a4,a4,a5
ffffffffc020195c:	00271793          	slli	a5,a4,0x2
ffffffffc0201960:	97ba                	add	a5,a5,a4
ffffffffc0201962:	6a18                	ld	a4,16(a2)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0201964:	8d95                	sub	a1,a1,a3
ffffffffc0201966:	078e                	slli	a5,a5,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc0201968:	81b1                	srli	a1,a1,0xc
ffffffffc020196a:	953e                	add	a0,a0,a5
ffffffffc020196c:	9702                	jalr	a4
}
ffffffffc020196e:	bfbd                	j	ffffffffc02018ec <pmm_init+0xf2>
        panic("pa2page called with invalid pa");
ffffffffc0201970:	00001617          	auipc	a2,0x1
ffffffffc0201974:	7f860613          	addi	a2,a2,2040 # ffffffffc0203168 <buddy_system_pmm_manager+0xf0>
ffffffffc0201978:	06a00593          	li	a1,106
ffffffffc020197c:	00002517          	auipc	a0,0x2
ffffffffc0201980:	80c50513          	addi	a0,a0,-2036 # ffffffffc0203188 <buddy_system_pmm_manager+0x110>
ffffffffc0201984:	83ffe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201988:	00001617          	auipc	a2,0x1
ffffffffc020198c:	7b860613          	addi	a2,a2,1976 # ffffffffc0203140 <buddy_system_pmm_manager+0xc8>
ffffffffc0201990:	05f00593          	li	a1,95
ffffffffc0201994:	00001517          	auipc	a0,0x1
ffffffffc0201998:	75450513          	addi	a0,a0,1876 # ffffffffc02030e8 <buddy_system_pmm_manager+0x70>
ffffffffc020199c:	827fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
        panic("DTB memory info not available");
ffffffffc02019a0:	00001617          	auipc	a2,0x1
ffffffffc02019a4:	72860613          	addi	a2,a2,1832 # ffffffffc02030c8 <buddy_system_pmm_manager+0x50>
ffffffffc02019a8:	04700593          	li	a1,71
ffffffffc02019ac:	00001517          	auipc	a0,0x1
ffffffffc02019b0:	73c50513          	addi	a0,a0,1852 # ffffffffc02030e8 <buddy_system_pmm_manager+0x70>
ffffffffc02019b4:	80ffe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc02019b8:	86ae                	mv	a3,a1
ffffffffc02019ba:	00001617          	auipc	a2,0x1
ffffffffc02019be:	78660613          	addi	a2,a2,1926 # ffffffffc0203140 <buddy_system_pmm_manager+0xc8>
ffffffffc02019c2:	07a00593          	li	a1,122
ffffffffc02019c6:	00001517          	auipc	a0,0x1
ffffffffc02019ca:	72250513          	addi	a0,a0,1826 # ffffffffc02030e8 <buddy_system_pmm_manager+0x70>
ffffffffc02019ce:	ff4fe0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc02019d2 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc02019d2:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02019d6:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc02019d8:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02019dc:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc02019de:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02019e2:	f022                	sd	s0,32(sp)
ffffffffc02019e4:	ec26                	sd	s1,24(sp)
ffffffffc02019e6:	e84a                	sd	s2,16(sp)
ffffffffc02019e8:	f406                	sd	ra,40(sp)
ffffffffc02019ea:	e44e                	sd	s3,8(sp)
ffffffffc02019ec:	84aa                	mv	s1,a0
ffffffffc02019ee:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc02019f0:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc02019f4:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc02019f6:	03067e63          	bgeu	a2,a6,ffffffffc0201a32 <printnum+0x60>
ffffffffc02019fa:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc02019fc:	00805763          	blez	s0,ffffffffc0201a0a <printnum+0x38>
ffffffffc0201a00:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0201a02:	85ca                	mv	a1,s2
ffffffffc0201a04:	854e                	mv	a0,s3
ffffffffc0201a06:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0201a08:	fc65                	bnez	s0,ffffffffc0201a00 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201a0a:	1a02                	slli	s4,s4,0x20
ffffffffc0201a0c:	00001797          	auipc	a5,0x1
ffffffffc0201a10:	7ec78793          	addi	a5,a5,2028 # ffffffffc02031f8 <buddy_system_pmm_manager+0x180>
ffffffffc0201a14:	020a5a13          	srli	s4,s4,0x20
ffffffffc0201a18:	9a3e                	add	s4,s4,a5
}
ffffffffc0201a1a:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201a1c:	000a4503          	lbu	a0,0(s4)
}
ffffffffc0201a20:	70a2                	ld	ra,40(sp)
ffffffffc0201a22:	69a2                	ld	s3,8(sp)
ffffffffc0201a24:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201a26:	85ca                	mv	a1,s2
ffffffffc0201a28:	87a6                	mv	a5,s1
}
ffffffffc0201a2a:	6942                	ld	s2,16(sp)
ffffffffc0201a2c:	64e2                	ld	s1,24(sp)
ffffffffc0201a2e:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201a30:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0201a32:	03065633          	divu	a2,a2,a6
ffffffffc0201a36:	8722                	mv	a4,s0
ffffffffc0201a38:	f9bff0ef          	jal	ra,ffffffffc02019d2 <printnum>
ffffffffc0201a3c:	b7f9                	j	ffffffffc0201a0a <printnum+0x38>

ffffffffc0201a3e <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0201a3e:	7119                	addi	sp,sp,-128
ffffffffc0201a40:	f4a6                	sd	s1,104(sp)
ffffffffc0201a42:	f0ca                	sd	s2,96(sp)
ffffffffc0201a44:	ecce                	sd	s3,88(sp)
ffffffffc0201a46:	e8d2                	sd	s4,80(sp)
ffffffffc0201a48:	e4d6                	sd	s5,72(sp)
ffffffffc0201a4a:	e0da                	sd	s6,64(sp)
ffffffffc0201a4c:	fc5e                	sd	s7,56(sp)
ffffffffc0201a4e:	f06a                	sd	s10,32(sp)
ffffffffc0201a50:	fc86                	sd	ra,120(sp)
ffffffffc0201a52:	f8a2                	sd	s0,112(sp)
ffffffffc0201a54:	f862                	sd	s8,48(sp)
ffffffffc0201a56:	f466                	sd	s9,40(sp)
ffffffffc0201a58:	ec6e                	sd	s11,24(sp)
ffffffffc0201a5a:	892a                	mv	s2,a0
ffffffffc0201a5c:	84ae                	mv	s1,a1
ffffffffc0201a5e:	8d32                	mv	s10,a2
ffffffffc0201a60:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201a62:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc0201a66:	5b7d                	li	s6,-1
ffffffffc0201a68:	00001a97          	auipc	s5,0x1
ffffffffc0201a6c:	7c4a8a93          	addi	s5,s5,1988 # ffffffffc020322c <buddy_system_pmm_manager+0x1b4>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201a70:	00002b97          	auipc	s7,0x2
ffffffffc0201a74:	998b8b93          	addi	s7,s7,-1640 # ffffffffc0203408 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201a78:	000d4503          	lbu	a0,0(s10)
ffffffffc0201a7c:	001d0413          	addi	s0,s10,1
ffffffffc0201a80:	01350a63          	beq	a0,s3,ffffffffc0201a94 <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc0201a84:	c121                	beqz	a0,ffffffffc0201ac4 <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc0201a86:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201a88:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc0201a8a:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201a8c:	fff44503          	lbu	a0,-1(s0)
ffffffffc0201a90:	ff351ae3          	bne	a0,s3,ffffffffc0201a84 <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201a94:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc0201a98:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc0201a9c:	4c81                	li	s9,0
ffffffffc0201a9e:	4881                	li	a7,0
        width = precision = -1;
ffffffffc0201aa0:	5c7d                	li	s8,-1
ffffffffc0201aa2:	5dfd                	li	s11,-1
ffffffffc0201aa4:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc0201aa8:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201aaa:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0201aae:	0ff5f593          	zext.b	a1,a1
ffffffffc0201ab2:	00140d13          	addi	s10,s0,1
ffffffffc0201ab6:	04b56263          	bltu	a0,a1,ffffffffc0201afa <vprintfmt+0xbc>
ffffffffc0201aba:	058a                	slli	a1,a1,0x2
ffffffffc0201abc:	95d6                	add	a1,a1,s5
ffffffffc0201abe:	4194                	lw	a3,0(a1)
ffffffffc0201ac0:	96d6                	add	a3,a3,s5
ffffffffc0201ac2:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0201ac4:	70e6                	ld	ra,120(sp)
ffffffffc0201ac6:	7446                	ld	s0,112(sp)
ffffffffc0201ac8:	74a6                	ld	s1,104(sp)
ffffffffc0201aca:	7906                	ld	s2,96(sp)
ffffffffc0201acc:	69e6                	ld	s3,88(sp)
ffffffffc0201ace:	6a46                	ld	s4,80(sp)
ffffffffc0201ad0:	6aa6                	ld	s5,72(sp)
ffffffffc0201ad2:	6b06                	ld	s6,64(sp)
ffffffffc0201ad4:	7be2                	ld	s7,56(sp)
ffffffffc0201ad6:	7c42                	ld	s8,48(sp)
ffffffffc0201ad8:	7ca2                	ld	s9,40(sp)
ffffffffc0201ada:	7d02                	ld	s10,32(sp)
ffffffffc0201adc:	6de2                	ld	s11,24(sp)
ffffffffc0201ade:	6109                	addi	sp,sp,128
ffffffffc0201ae0:	8082                	ret
            padc = '0';
ffffffffc0201ae2:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc0201ae4:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201ae8:	846a                	mv	s0,s10
ffffffffc0201aea:	00140d13          	addi	s10,s0,1
ffffffffc0201aee:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0201af2:	0ff5f593          	zext.b	a1,a1
ffffffffc0201af6:	fcb572e3          	bgeu	a0,a1,ffffffffc0201aba <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc0201afa:	85a6                	mv	a1,s1
ffffffffc0201afc:	02500513          	li	a0,37
ffffffffc0201b00:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0201b02:	fff44783          	lbu	a5,-1(s0)
ffffffffc0201b06:	8d22                	mv	s10,s0
ffffffffc0201b08:	f73788e3          	beq	a5,s3,ffffffffc0201a78 <vprintfmt+0x3a>
ffffffffc0201b0c:	ffed4783          	lbu	a5,-2(s10)
ffffffffc0201b10:	1d7d                	addi	s10,s10,-1
ffffffffc0201b12:	ff379de3          	bne	a5,s3,ffffffffc0201b0c <vprintfmt+0xce>
ffffffffc0201b16:	b78d                	j	ffffffffc0201a78 <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc0201b18:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc0201b1c:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201b20:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc0201b22:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc0201b26:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0201b2a:	02d86463          	bltu	a6,a3,ffffffffc0201b52 <vprintfmt+0x114>
                ch = *fmt;
ffffffffc0201b2e:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0201b32:	002c169b          	slliw	a3,s8,0x2
ffffffffc0201b36:	0186873b          	addw	a4,a3,s8
ffffffffc0201b3a:	0017171b          	slliw	a4,a4,0x1
ffffffffc0201b3e:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc0201b40:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc0201b44:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0201b46:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc0201b4a:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0201b4e:	fed870e3          	bgeu	a6,a3,ffffffffc0201b2e <vprintfmt+0xf0>
            if (width < 0)
ffffffffc0201b52:	f40ddce3          	bgez	s11,ffffffffc0201aaa <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc0201b56:	8de2                	mv	s11,s8
ffffffffc0201b58:	5c7d                	li	s8,-1
ffffffffc0201b5a:	bf81                	j	ffffffffc0201aaa <vprintfmt+0x6c>
            if (width < 0)
ffffffffc0201b5c:	fffdc693          	not	a3,s11
ffffffffc0201b60:	96fd                	srai	a3,a3,0x3f
ffffffffc0201b62:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201b66:	00144603          	lbu	a2,1(s0)
ffffffffc0201b6a:	2d81                	sext.w	s11,s11
ffffffffc0201b6c:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201b6e:	bf35                	j	ffffffffc0201aaa <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc0201b70:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201b74:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc0201b78:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201b7a:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc0201b7c:	bfd9                	j	ffffffffc0201b52 <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc0201b7e:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201b80:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201b84:	01174463          	blt	a4,a7,ffffffffc0201b8c <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc0201b88:	1a088e63          	beqz	a7,ffffffffc0201d44 <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc0201b8c:	000a3603          	ld	a2,0(s4)
ffffffffc0201b90:	46c1                	li	a3,16
ffffffffc0201b92:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0201b94:	2781                	sext.w	a5,a5
ffffffffc0201b96:	876e                	mv	a4,s11
ffffffffc0201b98:	85a6                	mv	a1,s1
ffffffffc0201b9a:	854a                	mv	a0,s2
ffffffffc0201b9c:	e37ff0ef          	jal	ra,ffffffffc02019d2 <printnum>
            break;
ffffffffc0201ba0:	bde1                	j	ffffffffc0201a78 <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc0201ba2:	000a2503          	lw	a0,0(s4)
ffffffffc0201ba6:	85a6                	mv	a1,s1
ffffffffc0201ba8:	0a21                	addi	s4,s4,8
ffffffffc0201baa:	9902                	jalr	s2
            break;
ffffffffc0201bac:	b5f1                	j	ffffffffc0201a78 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0201bae:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201bb0:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201bb4:	01174463          	blt	a4,a7,ffffffffc0201bbc <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc0201bb8:	18088163          	beqz	a7,ffffffffc0201d3a <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc0201bbc:	000a3603          	ld	a2,0(s4)
ffffffffc0201bc0:	46a9                	li	a3,10
ffffffffc0201bc2:	8a2e                	mv	s4,a1
ffffffffc0201bc4:	bfc1                	j	ffffffffc0201b94 <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201bc6:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc0201bca:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201bcc:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201bce:	bdf1                	j	ffffffffc0201aaa <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc0201bd0:	85a6                	mv	a1,s1
ffffffffc0201bd2:	02500513          	li	a0,37
ffffffffc0201bd6:	9902                	jalr	s2
            break;
ffffffffc0201bd8:	b545                	j	ffffffffc0201a78 <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201bda:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc0201bde:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201be0:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201be2:	b5e1                	j	ffffffffc0201aaa <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc0201be4:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201be6:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201bea:	01174463          	blt	a4,a7,ffffffffc0201bf2 <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc0201bee:	14088163          	beqz	a7,ffffffffc0201d30 <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc0201bf2:	000a3603          	ld	a2,0(s4)
ffffffffc0201bf6:	46a1                	li	a3,8
ffffffffc0201bf8:	8a2e                	mv	s4,a1
ffffffffc0201bfa:	bf69                	j	ffffffffc0201b94 <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc0201bfc:	03000513          	li	a0,48
ffffffffc0201c00:	85a6                	mv	a1,s1
ffffffffc0201c02:	e03e                	sd	a5,0(sp)
ffffffffc0201c04:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0201c06:	85a6                	mv	a1,s1
ffffffffc0201c08:	07800513          	li	a0,120
ffffffffc0201c0c:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201c0e:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0201c10:	6782                	ld	a5,0(sp)
ffffffffc0201c12:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201c14:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc0201c18:	bfb5                	j	ffffffffc0201b94 <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201c1a:	000a3403          	ld	s0,0(s4)
ffffffffc0201c1e:	008a0713          	addi	a4,s4,8
ffffffffc0201c22:	e03a                	sd	a4,0(sp)
ffffffffc0201c24:	14040263          	beqz	s0,ffffffffc0201d68 <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc0201c28:	0fb05763          	blez	s11,ffffffffc0201d16 <vprintfmt+0x2d8>
ffffffffc0201c2c:	02d00693          	li	a3,45
ffffffffc0201c30:	0cd79163          	bne	a5,a3,ffffffffc0201cf2 <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201c34:	00044783          	lbu	a5,0(s0)
ffffffffc0201c38:	0007851b          	sext.w	a0,a5
ffffffffc0201c3c:	cf85                	beqz	a5,ffffffffc0201c74 <vprintfmt+0x236>
ffffffffc0201c3e:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201c42:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201c46:	000c4563          	bltz	s8,ffffffffc0201c50 <vprintfmt+0x212>
ffffffffc0201c4a:	3c7d                	addiw	s8,s8,-1
ffffffffc0201c4c:	036c0263          	beq	s8,s6,ffffffffc0201c70 <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc0201c50:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201c52:	0e0c8e63          	beqz	s9,ffffffffc0201d4e <vprintfmt+0x310>
ffffffffc0201c56:	3781                	addiw	a5,a5,-32
ffffffffc0201c58:	0ef47b63          	bgeu	s0,a5,ffffffffc0201d4e <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc0201c5c:	03f00513          	li	a0,63
ffffffffc0201c60:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201c62:	000a4783          	lbu	a5,0(s4)
ffffffffc0201c66:	3dfd                	addiw	s11,s11,-1
ffffffffc0201c68:	0a05                	addi	s4,s4,1
ffffffffc0201c6a:	0007851b          	sext.w	a0,a5
ffffffffc0201c6e:	ffe1                	bnez	a5,ffffffffc0201c46 <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc0201c70:	01b05963          	blez	s11,ffffffffc0201c82 <vprintfmt+0x244>
ffffffffc0201c74:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0201c76:	85a6                	mv	a1,s1
ffffffffc0201c78:	02000513          	li	a0,32
ffffffffc0201c7c:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0201c7e:	fe0d9be3          	bnez	s11,ffffffffc0201c74 <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201c82:	6a02                	ld	s4,0(sp)
ffffffffc0201c84:	bbd5                	j	ffffffffc0201a78 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0201c86:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201c88:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc0201c8c:	01174463          	blt	a4,a7,ffffffffc0201c94 <vprintfmt+0x256>
    else if (lflag) {
ffffffffc0201c90:	08088d63          	beqz	a7,ffffffffc0201d2a <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc0201c94:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0201c98:	0a044d63          	bltz	s0,ffffffffc0201d52 <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc0201c9c:	8622                	mv	a2,s0
ffffffffc0201c9e:	8a66                	mv	s4,s9
ffffffffc0201ca0:	46a9                	li	a3,10
ffffffffc0201ca2:	bdcd                	j	ffffffffc0201b94 <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc0201ca4:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201ca8:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc0201caa:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc0201cac:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc0201cb0:	8fb5                	xor	a5,a5,a3
ffffffffc0201cb2:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201cb6:	02d74163          	blt	a4,a3,ffffffffc0201cd8 <vprintfmt+0x29a>
ffffffffc0201cba:	00369793          	slli	a5,a3,0x3
ffffffffc0201cbe:	97de                	add	a5,a5,s7
ffffffffc0201cc0:	639c                	ld	a5,0(a5)
ffffffffc0201cc2:	cb99                	beqz	a5,ffffffffc0201cd8 <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc0201cc4:	86be                	mv	a3,a5
ffffffffc0201cc6:	00001617          	auipc	a2,0x1
ffffffffc0201cca:	56260613          	addi	a2,a2,1378 # ffffffffc0203228 <buddy_system_pmm_manager+0x1b0>
ffffffffc0201cce:	85a6                	mv	a1,s1
ffffffffc0201cd0:	854a                	mv	a0,s2
ffffffffc0201cd2:	0ce000ef          	jal	ra,ffffffffc0201da0 <printfmt>
ffffffffc0201cd6:	b34d                	j	ffffffffc0201a78 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0201cd8:	00001617          	auipc	a2,0x1
ffffffffc0201cdc:	54060613          	addi	a2,a2,1344 # ffffffffc0203218 <buddy_system_pmm_manager+0x1a0>
ffffffffc0201ce0:	85a6                	mv	a1,s1
ffffffffc0201ce2:	854a                	mv	a0,s2
ffffffffc0201ce4:	0bc000ef          	jal	ra,ffffffffc0201da0 <printfmt>
ffffffffc0201ce8:	bb41                	j	ffffffffc0201a78 <vprintfmt+0x3a>
                p = "(null)";
ffffffffc0201cea:	00001417          	auipc	s0,0x1
ffffffffc0201cee:	52640413          	addi	s0,s0,1318 # ffffffffc0203210 <buddy_system_pmm_manager+0x198>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201cf2:	85e2                	mv	a1,s8
ffffffffc0201cf4:	8522                	mv	a0,s0
ffffffffc0201cf6:	e43e                	sd	a5,8(sp)
ffffffffc0201cf8:	0fc000ef          	jal	ra,ffffffffc0201df4 <strnlen>
ffffffffc0201cfc:	40ad8dbb          	subw	s11,s11,a0
ffffffffc0201d00:	01b05b63          	blez	s11,ffffffffc0201d16 <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc0201d04:	67a2                	ld	a5,8(sp)
ffffffffc0201d06:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201d0a:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc0201d0c:	85a6                	mv	a1,s1
ffffffffc0201d0e:	8552                	mv	a0,s4
ffffffffc0201d10:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201d12:	fe0d9ce3          	bnez	s11,ffffffffc0201d0a <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201d16:	00044783          	lbu	a5,0(s0)
ffffffffc0201d1a:	00140a13          	addi	s4,s0,1
ffffffffc0201d1e:	0007851b          	sext.w	a0,a5
ffffffffc0201d22:	d3a5                	beqz	a5,ffffffffc0201c82 <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201d24:	05e00413          	li	s0,94
ffffffffc0201d28:	bf39                	j	ffffffffc0201c46 <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc0201d2a:	000a2403          	lw	s0,0(s4)
ffffffffc0201d2e:	b7ad                	j	ffffffffc0201c98 <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc0201d30:	000a6603          	lwu	a2,0(s4)
ffffffffc0201d34:	46a1                	li	a3,8
ffffffffc0201d36:	8a2e                	mv	s4,a1
ffffffffc0201d38:	bdb1                	j	ffffffffc0201b94 <vprintfmt+0x156>
ffffffffc0201d3a:	000a6603          	lwu	a2,0(s4)
ffffffffc0201d3e:	46a9                	li	a3,10
ffffffffc0201d40:	8a2e                	mv	s4,a1
ffffffffc0201d42:	bd89                	j	ffffffffc0201b94 <vprintfmt+0x156>
ffffffffc0201d44:	000a6603          	lwu	a2,0(s4)
ffffffffc0201d48:	46c1                	li	a3,16
ffffffffc0201d4a:	8a2e                	mv	s4,a1
ffffffffc0201d4c:	b5a1                	j	ffffffffc0201b94 <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc0201d4e:	9902                	jalr	s2
ffffffffc0201d50:	bf09                	j	ffffffffc0201c62 <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc0201d52:	85a6                	mv	a1,s1
ffffffffc0201d54:	02d00513          	li	a0,45
ffffffffc0201d58:	e03e                	sd	a5,0(sp)
ffffffffc0201d5a:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0201d5c:	6782                	ld	a5,0(sp)
ffffffffc0201d5e:	8a66                	mv	s4,s9
ffffffffc0201d60:	40800633          	neg	a2,s0
ffffffffc0201d64:	46a9                	li	a3,10
ffffffffc0201d66:	b53d                	j	ffffffffc0201b94 <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc0201d68:	03b05163          	blez	s11,ffffffffc0201d8a <vprintfmt+0x34c>
ffffffffc0201d6c:	02d00693          	li	a3,45
ffffffffc0201d70:	f6d79de3          	bne	a5,a3,ffffffffc0201cea <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc0201d74:	00001417          	auipc	s0,0x1
ffffffffc0201d78:	49c40413          	addi	s0,s0,1180 # ffffffffc0203210 <buddy_system_pmm_manager+0x198>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201d7c:	02800793          	li	a5,40
ffffffffc0201d80:	02800513          	li	a0,40
ffffffffc0201d84:	00140a13          	addi	s4,s0,1
ffffffffc0201d88:	bd6d                	j	ffffffffc0201c42 <vprintfmt+0x204>
ffffffffc0201d8a:	00001a17          	auipc	s4,0x1
ffffffffc0201d8e:	487a0a13          	addi	s4,s4,1159 # ffffffffc0203211 <buddy_system_pmm_manager+0x199>
ffffffffc0201d92:	02800513          	li	a0,40
ffffffffc0201d96:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201d9a:	05e00413          	li	s0,94
ffffffffc0201d9e:	b565                	j	ffffffffc0201c46 <vprintfmt+0x208>

ffffffffc0201da0 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201da0:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0201da2:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201da6:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201da8:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201daa:	ec06                	sd	ra,24(sp)
ffffffffc0201dac:	f83a                	sd	a4,48(sp)
ffffffffc0201dae:	fc3e                	sd	a5,56(sp)
ffffffffc0201db0:	e0c2                	sd	a6,64(sp)
ffffffffc0201db2:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0201db4:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201db6:	c89ff0ef          	jal	ra,ffffffffc0201a3e <vprintfmt>
}
ffffffffc0201dba:	60e2                	ld	ra,24(sp)
ffffffffc0201dbc:	6161                	addi	sp,sp,80
ffffffffc0201dbe:	8082                	ret

ffffffffc0201dc0 <sbi_console_putchar>:
uint64_t SBI_REMOTE_SFENCE_VMA_ASID = 7;
uint64_t SBI_SHUTDOWN = 8;

uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
    uint64_t ret_val;
    __asm__ volatile (
ffffffffc0201dc0:	4781                	li	a5,0
ffffffffc0201dc2:	00005717          	auipc	a4,0x5
ffffffffc0201dc6:	24e73703          	ld	a4,590(a4) # ffffffffc0207010 <SBI_CONSOLE_PUTCHAR>
ffffffffc0201dca:	88ba                	mv	a7,a4
ffffffffc0201dcc:	852a                	mv	a0,a0
ffffffffc0201dce:	85be                	mv	a1,a5
ffffffffc0201dd0:	863e                	mv	a2,a5
ffffffffc0201dd2:	00000073          	ecall
ffffffffc0201dd6:	87aa                	mv	a5,a0
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}
ffffffffc0201dd8:	8082                	ret

ffffffffc0201dda <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0201dda:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc0201dde:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc0201de0:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc0201de2:	cb81                	beqz	a5,ffffffffc0201df2 <strlen+0x18>
        cnt ++;
ffffffffc0201de4:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc0201de6:	00a707b3          	add	a5,a4,a0
ffffffffc0201dea:	0007c783          	lbu	a5,0(a5)
ffffffffc0201dee:	fbfd                	bnez	a5,ffffffffc0201de4 <strlen+0xa>
ffffffffc0201df0:	8082                	ret
    }
    return cnt;
}
ffffffffc0201df2:	8082                	ret

ffffffffc0201df4 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc0201df4:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201df6:	e589                	bnez	a1,ffffffffc0201e00 <strnlen+0xc>
ffffffffc0201df8:	a811                	j	ffffffffc0201e0c <strnlen+0x18>
        cnt ++;
ffffffffc0201dfa:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201dfc:	00f58863          	beq	a1,a5,ffffffffc0201e0c <strnlen+0x18>
ffffffffc0201e00:	00f50733          	add	a4,a0,a5
ffffffffc0201e04:	00074703          	lbu	a4,0(a4)
ffffffffc0201e08:	fb6d                	bnez	a4,ffffffffc0201dfa <strnlen+0x6>
ffffffffc0201e0a:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0201e0c:	852e                	mv	a0,a1
ffffffffc0201e0e:	8082                	ret

ffffffffc0201e10 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201e10:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201e14:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201e18:	cb89                	beqz	a5,ffffffffc0201e2a <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc0201e1a:	0505                	addi	a0,a0,1
ffffffffc0201e1c:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201e1e:	fee789e3          	beq	a5,a4,ffffffffc0201e10 <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201e22:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0201e26:	9d19                	subw	a0,a0,a4
ffffffffc0201e28:	8082                	ret
ffffffffc0201e2a:	4501                	li	a0,0
ffffffffc0201e2c:	bfed                	j	ffffffffc0201e26 <strcmp+0x16>

ffffffffc0201e2e <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201e2e:	c20d                	beqz	a2,ffffffffc0201e50 <strncmp+0x22>
ffffffffc0201e30:	962e                	add	a2,a2,a1
ffffffffc0201e32:	a031                	j	ffffffffc0201e3e <strncmp+0x10>
        n --, s1 ++, s2 ++;
ffffffffc0201e34:	0505                	addi	a0,a0,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201e36:	00e79a63          	bne	a5,a4,ffffffffc0201e4a <strncmp+0x1c>
ffffffffc0201e3a:	00b60b63          	beq	a2,a1,ffffffffc0201e50 <strncmp+0x22>
ffffffffc0201e3e:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc0201e42:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201e44:	fff5c703          	lbu	a4,-1(a1)
ffffffffc0201e48:	f7f5                	bnez	a5,ffffffffc0201e34 <strncmp+0x6>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201e4a:	40e7853b          	subw	a0,a5,a4
}
ffffffffc0201e4e:	8082                	ret
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201e50:	4501                	li	a0,0
ffffffffc0201e52:	8082                	ret

ffffffffc0201e54 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0201e54:	ca01                	beqz	a2,ffffffffc0201e64 <memset+0x10>
ffffffffc0201e56:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0201e58:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0201e5a:	0785                	addi	a5,a5,1
ffffffffc0201e5c:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0201e60:	fec79de3          	bne	a5,a2,ffffffffc0201e5a <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0201e64:	8082                	ret
