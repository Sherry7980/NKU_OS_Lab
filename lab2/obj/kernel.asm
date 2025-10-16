
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	00005297          	auipc	t0,0x5
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc0205000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	00005297          	auipc	t0,0x5
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc0205008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)

    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c02042b7          	lui	t0,0xc0204
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
ffffffffc020003c:	c0204137          	lui	sp,0xc0204

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
ffffffffc020004c:	00001517          	auipc	a0,0x1
ffffffffc0200050:	60450513          	addi	a0,a0,1540 # ffffffffc0201650 <etext+0x4>
void print_kerninfo(void) {
ffffffffc0200054:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200056:	0f6000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", (uintptr_t)kern_init);
ffffffffc020005a:	00000597          	auipc	a1,0x0
ffffffffc020005e:	07e58593          	addi	a1,a1,126 # ffffffffc02000d8 <kern_init>
ffffffffc0200062:	00001517          	auipc	a0,0x1
ffffffffc0200066:	60e50513          	addi	a0,a0,1550 # ffffffffc0201670 <etext+0x24>
ffffffffc020006a:	0e2000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc020006e:	00001597          	auipc	a1,0x1
ffffffffc0200072:	5de58593          	addi	a1,a1,1502 # ffffffffc020164c <etext>
ffffffffc0200076:	00001517          	auipc	a0,0x1
ffffffffc020007a:	61a50513          	addi	a0,a0,1562 # ffffffffc0201690 <etext+0x44>
ffffffffc020007e:	0ce000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc0200082:	00005597          	auipc	a1,0x5
ffffffffc0200086:	f9658593          	addi	a1,a1,-106 # ffffffffc0205018 <free_area>
ffffffffc020008a:	00001517          	auipc	a0,0x1
ffffffffc020008e:	62650513          	addi	a0,a0,1574 # ffffffffc02016b0 <etext+0x64>
ffffffffc0200092:	0ba000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc0200096:	00005597          	auipc	a1,0x5
ffffffffc020009a:	fe258593          	addi	a1,a1,-30 # ffffffffc0205078 <end>
ffffffffc020009e:	00001517          	auipc	a0,0x1
ffffffffc02000a2:	63250513          	addi	a0,a0,1586 # ffffffffc02016d0 <etext+0x84>
ffffffffc02000a6:	0a6000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - (char*)kern_init + 1023) / 1024);
ffffffffc02000aa:	00005597          	auipc	a1,0x5
ffffffffc02000ae:	3cd58593          	addi	a1,a1,973 # ffffffffc0205477 <end+0x3ff>
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
ffffffffc02000cc:	00001517          	auipc	a0,0x1
ffffffffc02000d0:	62450513          	addi	a0,a0,1572 # ffffffffc02016f0 <etext+0xa4>
}
ffffffffc02000d4:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000d6:	a89d                	j	ffffffffc020014c <cprintf>

ffffffffc02000d8 <kern_init>:

int kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc02000d8:	00005517          	auipc	a0,0x5
ffffffffc02000dc:	f4050513          	addi	a0,a0,-192 # ffffffffc0205018 <free_area>
ffffffffc02000e0:	00005617          	auipc	a2,0x5
ffffffffc02000e4:	f9860613          	addi	a2,a2,-104 # ffffffffc0205078 <end>
int kern_init(void) {
ffffffffc02000e8:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc02000ea:	8e09                	sub	a2,a2,a0
ffffffffc02000ec:	4581                	li	a1,0
int kern_init(void) {
ffffffffc02000ee:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc02000f0:	54a010ef          	jal	ra,ffffffffc020163a <memset>
    dtb_init();
ffffffffc02000f4:	12c000ef          	jal	ra,ffffffffc0200220 <dtb_init>
    cons_init();  // init the console
ffffffffc02000f8:	11e000ef          	jal	ra,ffffffffc0200216 <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);
ffffffffc02000fc:	00001517          	auipc	a0,0x1
ffffffffc0200100:	62450513          	addi	a0,a0,1572 # ffffffffc0201720 <etext+0xd4>
ffffffffc0200104:	07e000ef          	jal	ra,ffffffffc0200182 <cputs>

    print_kerninfo();
ffffffffc0200108:	f43ff0ef          	jal	ra,ffffffffc020004a <print_kerninfo>

    // grade_backtrace();
    pmm_init();  // init physical memory management
ffffffffc020010c:	6d5000ef          	jal	ra,ffffffffc0200fe0 <pmm_init>

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
ffffffffc0200140:	0e4010ef          	jal	ra,ffffffffc0201224 <vprintfmt>
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
ffffffffc020014e:	02810313          	addi	t1,sp,40 # ffffffffc0204028 <boot_page_table_sv39+0x28>
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
ffffffffc0200176:	0ae010ef          	jal	ra,ffffffffc0201224 <vprintfmt>
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
ffffffffc02001c2:	00005317          	auipc	t1,0x5
ffffffffc02001c6:	e6e30313          	addi	t1,t1,-402 # ffffffffc0205030 <is_panic>
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
ffffffffc02001f2:	00001517          	auipc	a0,0x1
ffffffffc02001f6:	54e50513          	addi	a0,a0,1358 # ffffffffc0201740 <etext+0xf4>
    va_start(ap, fmt);
ffffffffc02001fa:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02001fc:	f51ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    vcprintf(fmt, ap);
ffffffffc0200200:	65a2                	ld	a1,8(sp)
ffffffffc0200202:	8522                	mv	a0,s0
ffffffffc0200204:	f29ff0ef          	jal	ra,ffffffffc020012c <vcprintf>
    cprintf("\n");
ffffffffc0200208:	00001517          	auipc	a0,0x1
ffffffffc020020c:	51050513          	addi	a0,a0,1296 # ffffffffc0201718 <etext+0xcc>
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
ffffffffc020021c:	38a0106f          	j	ffffffffc02015a6 <sbi_console_putchar>

ffffffffc0200220 <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc0200220:	7119                	addi	sp,sp,-128
    cprintf("DTB Init\n");
ffffffffc0200222:	00001517          	auipc	a0,0x1
ffffffffc0200226:	53e50513          	addi	a0,a0,1342 # ffffffffc0201760 <etext+0x114>
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
ffffffffc0200248:	00005597          	auipc	a1,0x5
ffffffffc020024c:	db85b583          	ld	a1,-584(a1) # ffffffffc0205000 <boot_hartid>
ffffffffc0200250:	00001517          	auipc	a0,0x1
ffffffffc0200254:	52050513          	addi	a0,a0,1312 # ffffffffc0201770 <etext+0x124>
ffffffffc0200258:	ef5ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc020025c:	00005417          	auipc	s0,0x5
ffffffffc0200260:	dac40413          	addi	s0,s0,-596 # ffffffffc0205008 <boot_dtb>
ffffffffc0200264:	600c                	ld	a1,0(s0)
ffffffffc0200266:	00001517          	auipc	a0,0x1
ffffffffc020026a:	51a50513          	addi	a0,a0,1306 # ffffffffc0201780 <etext+0x134>
ffffffffc020026e:	edfff0ef          	jal	ra,ffffffffc020014c <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc0200272:	00043a03          	ld	s4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc0200276:	00001517          	auipc	a0,0x1
ffffffffc020027a:	52250513          	addi	a0,a0,1314 # ffffffffc0201798 <etext+0x14c>
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
ffffffffc02002be:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <end+0xfedae75>
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
ffffffffc0200330:	00001917          	auipc	s2,0x1
ffffffffc0200334:	4b890913          	addi	s2,s2,1208 # ffffffffc02017e8 <etext+0x19c>
ffffffffc0200338:	49bd                	li	s3,15
        switch (token) {
ffffffffc020033a:	4d91                	li	s11,4
ffffffffc020033c:	4d05                	li	s10,1
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc020033e:	00001497          	auipc	s1,0x1
ffffffffc0200342:	4a248493          	addi	s1,s1,1186 # ffffffffc02017e0 <etext+0x194>
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
ffffffffc0200392:	00001517          	auipc	a0,0x1
ffffffffc0200396:	4ce50513          	addi	a0,a0,1230 # ffffffffc0201860 <etext+0x214>
ffffffffc020039a:	db3ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc020039e:	00001517          	auipc	a0,0x1
ffffffffc02003a2:	4fa50513          	addi	a0,a0,1274 # ffffffffc0201898 <etext+0x24c>
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
ffffffffc02003de:	00001517          	auipc	a0,0x1
ffffffffc02003e2:	3da50513          	addi	a0,a0,986 # ffffffffc02017b8 <etext+0x16c>
}
ffffffffc02003e6:	6109                	addi	sp,sp,128
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02003e8:	b395                	j	ffffffffc020014c <cprintf>
                int name_len = strlen(name);
ffffffffc02003ea:	8556                	mv	a0,s5
ffffffffc02003ec:	1d4010ef          	jal	ra,ffffffffc02015c0 <strlen>
ffffffffc02003f0:	8a2a                	mv	s4,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02003f2:	4619                	li	a2,6
ffffffffc02003f4:	85a6                	mv	a1,s1
ffffffffc02003f6:	8556                	mv	a0,s5
                int name_len = strlen(name);
ffffffffc02003f8:	2a01                	sext.w	s4,s4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02003fa:	21a010ef          	jal	ra,ffffffffc0201614 <strncmp>
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
ffffffffc0200490:	166010ef          	jal	ra,ffffffffc02015f6 <strcmp>
ffffffffc0200494:	66a2                	ld	a3,8(sp)
ffffffffc0200496:	f94d                	bnez	a0,ffffffffc0200448 <dtb_init+0x228>
ffffffffc0200498:	fb59f8e3          	bgeu	s3,s5,ffffffffc0200448 <dtb_init+0x228>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc020049c:	00ca3783          	ld	a5,12(s4)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc02004a0:	014a3703          	ld	a4,20(s4)
        cprintf("Physical Memory from DTB:\n");
ffffffffc02004a4:	00001517          	auipc	a0,0x1
ffffffffc02004a8:	34c50513          	addi	a0,a0,844 # ffffffffc02017f0 <etext+0x1a4>
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
ffffffffc0200572:	00001517          	auipc	a0,0x1
ffffffffc0200576:	29e50513          	addi	a0,a0,670 # ffffffffc0201810 <etext+0x1c4>
ffffffffc020057a:	bd3ff0ef          	jal	ra,ffffffffc020014c <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc020057e:	014b5613          	srli	a2,s6,0x14
ffffffffc0200582:	85da                	mv	a1,s6
ffffffffc0200584:	00001517          	auipc	a0,0x1
ffffffffc0200588:	2a450513          	addi	a0,a0,676 # ffffffffc0201828 <etext+0x1dc>
ffffffffc020058c:	bc1ff0ef          	jal	ra,ffffffffc020014c <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc0200590:	008b05b3          	add	a1,s6,s0
ffffffffc0200594:	15fd                	addi	a1,a1,-1
ffffffffc0200596:	00001517          	auipc	a0,0x1
ffffffffc020059a:	2b250513          	addi	a0,a0,690 # ffffffffc0201848 <etext+0x1fc>
ffffffffc020059e:	bafff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("DTB init completed\n");
ffffffffc02005a2:	00001517          	auipc	a0,0x1
ffffffffc02005a6:	2f650513          	addi	a0,a0,758 # ffffffffc0201898 <etext+0x24c>
        memory_base = mem_base;
ffffffffc02005aa:	00005797          	auipc	a5,0x5
ffffffffc02005ae:	a887b723          	sd	s0,-1394(a5) # ffffffffc0205038 <memory_base>
        memory_size = mem_size;
ffffffffc02005b2:	00005797          	auipc	a5,0x5
ffffffffc02005b6:	a967b723          	sd	s6,-1394(a5) # ffffffffc0205040 <memory_size>
    cprintf("DTB init completed\n");
ffffffffc02005ba:	b3f5                	j	ffffffffc02003a6 <dtb_init+0x186>

ffffffffc02005bc <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc02005bc:	00005517          	auipc	a0,0x5
ffffffffc02005c0:	a7c53503          	ld	a0,-1412(a0) # ffffffffc0205038 <memory_base>
ffffffffc02005c4:	8082                	ret

ffffffffc02005c6 <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
ffffffffc02005c6:	00005517          	auipc	a0,0x5
ffffffffc02005ca:	a7a53503          	ld	a0,-1414(a0) # ffffffffc0205040 <memory_size>
ffffffffc02005ce:	8082                	ret

ffffffffc02005d0 <best_fit_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc02005d0:	00005797          	auipc	a5,0x5
ffffffffc02005d4:	a4878793          	addi	a5,a5,-1464 # ffffffffc0205018 <free_area>
ffffffffc02005d8:	e79c                	sd	a5,8(a5)
ffffffffc02005da:	e39c                	sd	a5,0(a5)
#define nr_free (free_area.nr_free)

static void
best_fit_init(void) {
    list_init(&free_list);
    nr_free = 0;
ffffffffc02005dc:	0007a823          	sw	zero,16(a5)
}
ffffffffc02005e0:	8082                	ret

ffffffffc02005e2 <best_fit_nr_free_pages>:
}

static size_t
best_fit_nr_free_pages(void) {
    return nr_free;
}
ffffffffc02005e2:	00005517          	auipc	a0,0x5
ffffffffc02005e6:	a4656503          	lwu	a0,-1466(a0) # ffffffffc0205028 <free_area+0x10>
ffffffffc02005ea:	8082                	ret

ffffffffc02005ec <best_fit_alloc_pages>:
    assert(n > 0);
ffffffffc02005ec:	cd49                	beqz	a0,ffffffffc0200686 <best_fit_alloc_pages+0x9a>
    if (n > nr_free) {
ffffffffc02005ee:	00005617          	auipc	a2,0x5
ffffffffc02005f2:	a2a60613          	addi	a2,a2,-1494 # ffffffffc0205018 <free_area>
ffffffffc02005f6:	01062803          	lw	a6,16(a2)
ffffffffc02005fa:	86aa                	mv	a3,a0
ffffffffc02005fc:	02081793          	slli	a5,a6,0x20
ffffffffc0200600:	9381                	srli	a5,a5,0x20
ffffffffc0200602:	08a7e063          	bltu	a5,a0,ffffffffc0200682 <best_fit_alloc_pages+0x96>
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200606:	661c                	ld	a5,8(a2)
    size_t min_size = nr_free + 1;
ffffffffc0200608:	0018059b          	addiw	a1,a6,1
ffffffffc020060c:	1582                	slli	a1,a1,0x20
ffffffffc020060e:	9181                	srli	a1,a1,0x20
    struct Page* page = NULL;
ffffffffc0200610:	4501                	li	a0,0
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200612:	06c78763          	beq	a5,a2,ffffffffc0200680 <best_fit_alloc_pages+0x94>
        if (p->property >= n && p->property < min_size) {
ffffffffc0200616:	ff87e703          	lwu	a4,-8(a5)
ffffffffc020061a:	00d76763          	bltu	a4,a3,ffffffffc0200628 <best_fit_alloc_pages+0x3c>
ffffffffc020061e:	00b77563          	bgeu	a4,a1,ffffffffc0200628 <best_fit_alloc_pages+0x3c>
        struct Page* p = le2page(le, page_link);
ffffffffc0200622:	fe878513          	addi	a0,a5,-24
ffffffffc0200626:	85ba                	mv	a1,a4
ffffffffc0200628:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc020062a:	fec796e3          	bne	a5,a2,ffffffffc0200616 <best_fit_alloc_pages+0x2a>
    if (page != NULL) {
ffffffffc020062e:	c929                	beqz	a0,ffffffffc0200680 <best_fit_alloc_pages+0x94>
        if (page->property > n) {
ffffffffc0200630:	01052883          	lw	a7,16(a0)
 * list_prev - get the previous entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_prev(list_entry_t *listelm) {
    return listelm->prev;
ffffffffc0200634:	6d18                	ld	a4,24(a0)
    __list_del(listelm->prev, listelm->next);
ffffffffc0200636:	710c                	ld	a1,32(a0)
ffffffffc0200638:	02089793          	slli	a5,a7,0x20
ffffffffc020063c:	9381                	srli	a5,a5,0x20
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc020063e:	e70c                	sd	a1,8(a4)
    next->prev = prev;
ffffffffc0200640:	e198                	sd	a4,0(a1)
            p->property = page->property - n;
ffffffffc0200642:	0006831b          	sext.w	t1,a3
        if (page->property > n) {
ffffffffc0200646:	02f6f563          	bgeu	a3,a5,ffffffffc0200670 <best_fit_alloc_pages+0x84>
            struct Page* p = page + n;
ffffffffc020064a:	00269793          	slli	a5,a3,0x2
ffffffffc020064e:	97b6                	add	a5,a5,a3
ffffffffc0200650:	078e                	slli	a5,a5,0x3
ffffffffc0200652:	97aa                	add	a5,a5,a0
            SetPageProperty(p);
ffffffffc0200654:	6794                	ld	a3,8(a5)
            p->property = page->property - n;
ffffffffc0200656:	406888bb          	subw	a7,a7,t1
ffffffffc020065a:	0117a823          	sw	a7,16(a5)
            SetPageProperty(p);
ffffffffc020065e:	0026e693          	ori	a3,a3,2
ffffffffc0200662:	e794                	sd	a3,8(a5)
            list_add(prev, &(p->page_link));
ffffffffc0200664:	01878693          	addi	a3,a5,24
    prev->next = next->prev = elm;
ffffffffc0200668:	e194                	sd	a3,0(a1)
ffffffffc020066a:	e714                	sd	a3,8(a4)
    elm->next = next;
ffffffffc020066c:	f38c                	sd	a1,32(a5)
    elm->prev = prev;
ffffffffc020066e:	ef98                	sd	a4,24(a5)
        ClearPageProperty(page);
ffffffffc0200670:	651c                	ld	a5,8(a0)
        nr_free -= n;
ffffffffc0200672:	4068083b          	subw	a6,a6,t1
ffffffffc0200676:	01062823          	sw	a6,16(a2)
        ClearPageProperty(page);
ffffffffc020067a:	9bf5                	andi	a5,a5,-3
ffffffffc020067c:	e51c                	sd	a5,8(a0)
ffffffffc020067e:	8082                	ret
}
ffffffffc0200680:	8082                	ret
        return NULL;
ffffffffc0200682:	4501                	li	a0,0
ffffffffc0200684:	8082                	ret
best_fit_alloc_pages(size_t n) {
ffffffffc0200686:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc0200688:	00001697          	auipc	a3,0x1
ffffffffc020068c:	22868693          	addi	a3,a3,552 # ffffffffc02018b0 <etext+0x264>
ffffffffc0200690:	00001617          	auipc	a2,0x1
ffffffffc0200694:	22860613          	addi	a2,a2,552 # ffffffffc02018b8 <etext+0x26c>
ffffffffc0200698:	06f00593          	li	a1,111
ffffffffc020069c:	00001517          	auipc	a0,0x1
ffffffffc02006a0:	23450513          	addi	a0,a0,564 # ffffffffc02018d0 <etext+0x284>
best_fit_alloc_pages(size_t n) {
ffffffffc02006a4:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02006a6:	b1dff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc02006aa <best_fit_check>:
}

// LAB2: below code is used to check the best fit allocation algorithm (your EXERCISE 1) 
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
best_fit_check(void) {
ffffffffc02006aa:	715d                	addi	sp,sp,-80
ffffffffc02006ac:	e0a2                	sd	s0,64(sp)
    return listelm->next;
ffffffffc02006ae:	00005417          	auipc	s0,0x5
ffffffffc02006b2:	96a40413          	addi	s0,s0,-1686 # ffffffffc0205018 <free_area>
ffffffffc02006b6:	641c                	ld	a5,8(s0)
ffffffffc02006b8:	e486                	sd	ra,72(sp)
ffffffffc02006ba:	fc26                	sd	s1,56(sp)
ffffffffc02006bc:	f84a                	sd	s2,48(sp)
ffffffffc02006be:	f44e                	sd	s3,40(sp)
ffffffffc02006c0:	f052                	sd	s4,32(sp)
ffffffffc02006c2:	ec56                	sd	s5,24(sp)
ffffffffc02006c4:	e85a                	sd	s6,16(sp)
ffffffffc02006c6:	e45e                	sd	s7,8(sp)
ffffffffc02006c8:	e062                	sd	s8,0(sp)
    int score = 0, sumscore = 6;
    int count = 0, total = 0;
    list_entry_t* le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc02006ca:	26878963          	beq	a5,s0,ffffffffc020093c <best_fit_check+0x292>
    int count = 0, total = 0;
ffffffffc02006ce:	4481                	li	s1,0
ffffffffc02006d0:	4901                	li	s2,0
        struct Page* p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc02006d2:	ff07b703          	ld	a4,-16(a5)
ffffffffc02006d6:	8b09                	andi	a4,a4,2
ffffffffc02006d8:	26070663          	beqz	a4,ffffffffc0200944 <best_fit_check+0x29a>
        count++, total += p->property;
ffffffffc02006dc:	ff87a703          	lw	a4,-8(a5)
ffffffffc02006e0:	679c                	ld	a5,8(a5)
ffffffffc02006e2:	2905                	addiw	s2,s2,1
ffffffffc02006e4:	9cb9                	addw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc02006e6:	fe8796e3          	bne	a5,s0,ffffffffc02006d2 <best_fit_check+0x28>
    }
    assert(total == nr_free_pages());
ffffffffc02006ea:	89a6                	mv	s3,s1
ffffffffc02006ec:	0e9000ef          	jal	ra,ffffffffc0200fd4 <nr_free_pages>
ffffffffc02006f0:	33351a63          	bne	a0,s3,ffffffffc0200a24 <best_fit_check+0x37a>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02006f4:	4505                	li	a0,1
ffffffffc02006f6:	0c7000ef          	jal	ra,ffffffffc0200fbc <alloc_pages>
ffffffffc02006fa:	8a2a                	mv	s4,a0
ffffffffc02006fc:	36050463          	beqz	a0,ffffffffc0200a64 <best_fit_check+0x3ba>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200700:	4505                	li	a0,1
ffffffffc0200702:	0bb000ef          	jal	ra,ffffffffc0200fbc <alloc_pages>
ffffffffc0200706:	89aa                	mv	s3,a0
ffffffffc0200708:	32050e63          	beqz	a0,ffffffffc0200a44 <best_fit_check+0x39a>
    assert((p2 = alloc_page()) != NULL);
ffffffffc020070c:	4505                	li	a0,1
ffffffffc020070e:	0af000ef          	jal	ra,ffffffffc0200fbc <alloc_pages>
ffffffffc0200712:	8aaa                	mv	s5,a0
ffffffffc0200714:	2c050863          	beqz	a0,ffffffffc02009e4 <best_fit_check+0x33a>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200718:	253a0663          	beq	s4,s3,ffffffffc0200964 <best_fit_check+0x2ba>
ffffffffc020071c:	24aa0463          	beq	s4,a0,ffffffffc0200964 <best_fit_check+0x2ba>
ffffffffc0200720:	24a98263          	beq	s3,a0,ffffffffc0200964 <best_fit_check+0x2ba>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200724:	000a2783          	lw	a5,0(s4)
ffffffffc0200728:	24079e63          	bnez	a5,ffffffffc0200984 <best_fit_check+0x2da>
ffffffffc020072c:	0009a783          	lw	a5,0(s3)
ffffffffc0200730:	24079a63          	bnez	a5,ffffffffc0200984 <best_fit_check+0x2da>
ffffffffc0200734:	411c                	lw	a5,0(a0)
ffffffffc0200736:	24079763          	bnez	a5,ffffffffc0200984 <best_fit_check+0x2da>
extern struct Page *pages;
extern size_t npage;
extern const size_t nbase;
extern uint64_t va_pa_offset;

static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc020073a:	00005797          	auipc	a5,0x5
ffffffffc020073e:	9167b783          	ld	a5,-1770(a5) # ffffffffc0205050 <pages>
ffffffffc0200742:	40fa0733          	sub	a4,s4,a5
ffffffffc0200746:	870d                	srai	a4,a4,0x3
ffffffffc0200748:	00002597          	auipc	a1,0x2
ffffffffc020074c:	8785b583          	ld	a1,-1928(a1) # ffffffffc0201fc0 <error_string+0x38>
ffffffffc0200750:	02b70733          	mul	a4,a4,a1
ffffffffc0200754:	00002617          	auipc	a2,0x2
ffffffffc0200758:	87463603          	ld	a2,-1932(a2) # ffffffffc0201fc8 <nbase>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc020075c:	00005697          	auipc	a3,0x5
ffffffffc0200760:	8ec6b683          	ld	a3,-1812(a3) # ffffffffc0205048 <npage>
ffffffffc0200764:	06b2                	slli	a3,a3,0xc
ffffffffc0200766:	9732                	add	a4,a4,a2

static inline uintptr_t page2pa(struct Page *page) {
    return page2ppn(page) << PGSHIFT;
ffffffffc0200768:	0732                	slli	a4,a4,0xc
ffffffffc020076a:	22d77d63          	bgeu	a4,a3,ffffffffc02009a4 <best_fit_check+0x2fa>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc020076e:	40f98733          	sub	a4,s3,a5
ffffffffc0200772:	870d                	srai	a4,a4,0x3
ffffffffc0200774:	02b70733          	mul	a4,a4,a1
ffffffffc0200778:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc020077a:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc020077c:	3ed77463          	bgeu	a4,a3,ffffffffc0200b64 <best_fit_check+0x4ba>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200780:	40f507b3          	sub	a5,a0,a5
ffffffffc0200784:	878d                	srai	a5,a5,0x3
ffffffffc0200786:	02b787b3          	mul	a5,a5,a1
ffffffffc020078a:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc020078c:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc020078e:	3ad7fb63          	bgeu	a5,a3,ffffffffc0200b44 <best_fit_check+0x49a>
    assert(alloc_page() == NULL);
ffffffffc0200792:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200794:	00043c03          	ld	s8,0(s0)
ffffffffc0200798:	00843b83          	ld	s7,8(s0)
    unsigned int nr_free_store = nr_free;
ffffffffc020079c:	01042b03          	lw	s6,16(s0)
    elm->prev = elm->next = elm;
ffffffffc02007a0:	e400                	sd	s0,8(s0)
ffffffffc02007a2:	e000                	sd	s0,0(s0)
    nr_free = 0;
ffffffffc02007a4:	00005797          	auipc	a5,0x5
ffffffffc02007a8:	8807a223          	sw	zero,-1916(a5) # ffffffffc0205028 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc02007ac:	011000ef          	jal	ra,ffffffffc0200fbc <alloc_pages>
ffffffffc02007b0:	36051a63          	bnez	a0,ffffffffc0200b24 <best_fit_check+0x47a>
    free_page(p0);
ffffffffc02007b4:	4585                	li	a1,1
ffffffffc02007b6:	8552                	mv	a0,s4
ffffffffc02007b8:	011000ef          	jal	ra,ffffffffc0200fc8 <free_pages>
    free_page(p1);
ffffffffc02007bc:	4585                	li	a1,1
ffffffffc02007be:	854e                	mv	a0,s3
ffffffffc02007c0:	009000ef          	jal	ra,ffffffffc0200fc8 <free_pages>
    free_page(p2);
ffffffffc02007c4:	4585                	li	a1,1
ffffffffc02007c6:	8556                	mv	a0,s5
ffffffffc02007c8:	001000ef          	jal	ra,ffffffffc0200fc8 <free_pages>
    assert(nr_free == 3);
ffffffffc02007cc:	4818                	lw	a4,16(s0)
ffffffffc02007ce:	478d                	li	a5,3
ffffffffc02007d0:	32f71a63          	bne	a4,a5,ffffffffc0200b04 <best_fit_check+0x45a>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02007d4:	4505                	li	a0,1
ffffffffc02007d6:	7e6000ef          	jal	ra,ffffffffc0200fbc <alloc_pages>
ffffffffc02007da:	89aa                	mv	s3,a0
ffffffffc02007dc:	30050463          	beqz	a0,ffffffffc0200ae4 <best_fit_check+0x43a>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02007e0:	4505                	li	a0,1
ffffffffc02007e2:	7da000ef          	jal	ra,ffffffffc0200fbc <alloc_pages>
ffffffffc02007e6:	8aaa                	mv	s5,a0
ffffffffc02007e8:	2c050e63          	beqz	a0,ffffffffc0200ac4 <best_fit_check+0x41a>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02007ec:	4505                	li	a0,1
ffffffffc02007ee:	7ce000ef          	jal	ra,ffffffffc0200fbc <alloc_pages>
ffffffffc02007f2:	8a2a                	mv	s4,a0
ffffffffc02007f4:	2a050863          	beqz	a0,ffffffffc0200aa4 <best_fit_check+0x3fa>
    assert(alloc_page() == NULL);
ffffffffc02007f8:	4505                	li	a0,1
ffffffffc02007fa:	7c2000ef          	jal	ra,ffffffffc0200fbc <alloc_pages>
ffffffffc02007fe:	28051363          	bnez	a0,ffffffffc0200a84 <best_fit_check+0x3da>
    free_page(p0);
ffffffffc0200802:	4585                	li	a1,1
ffffffffc0200804:	854e                	mv	a0,s3
ffffffffc0200806:	7c2000ef          	jal	ra,ffffffffc0200fc8 <free_pages>
    assert(!list_empty(&free_list));
ffffffffc020080a:	641c                	ld	a5,8(s0)
ffffffffc020080c:	1a878c63          	beq	a5,s0,ffffffffc02009c4 <best_fit_check+0x31a>
    assert((p = alloc_page()) == p0);
ffffffffc0200810:	4505                	li	a0,1
ffffffffc0200812:	7aa000ef          	jal	ra,ffffffffc0200fbc <alloc_pages>
ffffffffc0200816:	52a99763          	bne	s3,a0,ffffffffc0200d44 <best_fit_check+0x69a>
    assert(alloc_page() == NULL);
ffffffffc020081a:	4505                	li	a0,1
ffffffffc020081c:	7a0000ef          	jal	ra,ffffffffc0200fbc <alloc_pages>
ffffffffc0200820:	50051263          	bnez	a0,ffffffffc0200d24 <best_fit_check+0x67a>
    assert(nr_free == 0);
ffffffffc0200824:	481c                	lw	a5,16(s0)
ffffffffc0200826:	4c079f63          	bnez	a5,ffffffffc0200d04 <best_fit_check+0x65a>
    free_page(p);
ffffffffc020082a:	854e                	mv	a0,s3
ffffffffc020082c:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc020082e:	01843023          	sd	s8,0(s0)
ffffffffc0200832:	01743423          	sd	s7,8(s0)
    nr_free = nr_free_store;
ffffffffc0200836:	01642823          	sw	s6,16(s0)
    free_page(p);
ffffffffc020083a:	78e000ef          	jal	ra,ffffffffc0200fc8 <free_pages>
    free_page(p1);
ffffffffc020083e:	4585                	li	a1,1
ffffffffc0200840:	8556                	mv	a0,s5
ffffffffc0200842:	786000ef          	jal	ra,ffffffffc0200fc8 <free_pages>
    free_page(p2);
ffffffffc0200846:	4585                	li	a1,1
ffffffffc0200848:	8552                	mv	a0,s4
ffffffffc020084a:	77e000ef          	jal	ra,ffffffffc0200fc8 <free_pages>

#ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n", score, sumscore);
#endif
    struct Page* p0 = alloc_pages(5), * p1, * p2;
ffffffffc020084e:	4515                	li	a0,5
ffffffffc0200850:	76c000ef          	jal	ra,ffffffffc0200fbc <alloc_pages>
ffffffffc0200854:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0200856:	48050763          	beqz	a0,ffffffffc0200ce4 <best_fit_check+0x63a>
    assert(!PageProperty(p0));
ffffffffc020085a:	651c                	ld	a5,8(a0)
ffffffffc020085c:	8b89                	andi	a5,a5,2
ffffffffc020085e:	46079363          	bnez	a5,ffffffffc0200cc4 <best_fit_check+0x61a>
    cprintf("grading: %d / %d points\n", score, sumscore);
#endif
    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0200862:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200864:	00043b03          	ld	s6,0(s0)
ffffffffc0200868:	00843a83          	ld	s5,8(s0)
ffffffffc020086c:	e000                	sd	s0,0(s0)
ffffffffc020086e:	e400                	sd	s0,8(s0)
    assert(alloc_page() == NULL);
ffffffffc0200870:	74c000ef          	jal	ra,ffffffffc0200fbc <alloc_pages>
ffffffffc0200874:	42051863          	bnez	a0,ffffffffc0200ca4 <best_fit_check+0x5fa>
#endif
    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    // * - - * -
    free_pages(p0 + 1, 2);
ffffffffc0200878:	4589                	li	a1,2
ffffffffc020087a:	02898513          	addi	a0,s3,40
    unsigned int nr_free_store = nr_free;
ffffffffc020087e:	01042b83          	lw	s7,16(s0)
    free_pages(p0 + 4, 1);
ffffffffc0200882:	0a098c13          	addi	s8,s3,160
    nr_free = 0;
ffffffffc0200886:	00004797          	auipc	a5,0x4
ffffffffc020088a:	7a07a123          	sw	zero,1954(a5) # ffffffffc0205028 <free_area+0x10>
    free_pages(p0 + 1, 2);
ffffffffc020088e:	73a000ef          	jal	ra,ffffffffc0200fc8 <free_pages>
    free_pages(p0 + 4, 1);
ffffffffc0200892:	8562                	mv	a0,s8
ffffffffc0200894:	4585                	li	a1,1
ffffffffc0200896:	732000ef          	jal	ra,ffffffffc0200fc8 <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc020089a:	4511                	li	a0,4
ffffffffc020089c:	720000ef          	jal	ra,ffffffffc0200fbc <alloc_pages>
ffffffffc02008a0:	3e051263          	bnez	a0,ffffffffc0200c84 <best_fit_check+0x5da>
    assert(PageProperty(p0 + 1) && p0[1].property == 2);
ffffffffc02008a4:	0309b783          	ld	a5,48(s3)
ffffffffc02008a8:	8b89                	andi	a5,a5,2
ffffffffc02008aa:	3a078d63          	beqz	a5,ffffffffc0200c64 <best_fit_check+0x5ba>
ffffffffc02008ae:	0389a703          	lw	a4,56(s3)
ffffffffc02008b2:	4789                	li	a5,2
ffffffffc02008b4:	3af71863          	bne	a4,a5,ffffffffc0200c64 <best_fit_check+0x5ba>
    // * - - * *
    assert((p1 = alloc_pages(1)) != NULL);
ffffffffc02008b8:	4505                	li	a0,1
ffffffffc02008ba:	702000ef          	jal	ra,ffffffffc0200fbc <alloc_pages>
ffffffffc02008be:	8a2a                	mv	s4,a0
ffffffffc02008c0:	38050263          	beqz	a0,ffffffffc0200c44 <best_fit_check+0x59a>
    assert(alloc_pages(2) != NULL);      // best fit feature
ffffffffc02008c4:	4509                	li	a0,2
ffffffffc02008c6:	6f6000ef          	jal	ra,ffffffffc0200fbc <alloc_pages>
ffffffffc02008ca:	34050d63          	beqz	a0,ffffffffc0200c24 <best_fit_check+0x57a>
    assert(p0 + 4 == p1);
ffffffffc02008ce:	334c1b63          	bne	s8,s4,ffffffffc0200c04 <best_fit_check+0x55a>
#ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n", score, sumscore);
#endif
    p2 = p0 + 1;
    free_pages(p0, 5);
ffffffffc02008d2:	854e                	mv	a0,s3
ffffffffc02008d4:	4595                	li	a1,5
ffffffffc02008d6:	6f2000ef          	jal	ra,ffffffffc0200fc8 <free_pages>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc02008da:	4515                	li	a0,5
ffffffffc02008dc:	6e0000ef          	jal	ra,ffffffffc0200fbc <alloc_pages>
ffffffffc02008e0:	89aa                	mv	s3,a0
ffffffffc02008e2:	30050163          	beqz	a0,ffffffffc0200be4 <best_fit_check+0x53a>
    assert(alloc_page() == NULL);
ffffffffc02008e6:	4505                	li	a0,1
ffffffffc02008e8:	6d4000ef          	jal	ra,ffffffffc0200fbc <alloc_pages>
ffffffffc02008ec:	2c051c63          	bnez	a0,ffffffffc0200bc4 <best_fit_check+0x51a>

#ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n", score, sumscore);
#endif
    assert(nr_free == 0);
ffffffffc02008f0:	481c                	lw	a5,16(s0)
ffffffffc02008f2:	2a079963          	bnez	a5,ffffffffc0200ba4 <best_fit_check+0x4fa>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc02008f6:	4595                	li	a1,5
ffffffffc02008f8:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc02008fa:	01742823          	sw	s7,16(s0)
    free_list = free_list_store;
ffffffffc02008fe:	01643023          	sd	s6,0(s0)
ffffffffc0200902:	01543423          	sd	s5,8(s0)
    free_pages(p0, 5);
ffffffffc0200906:	6c2000ef          	jal	ra,ffffffffc0200fc8 <free_pages>
    return listelm->next;
ffffffffc020090a:	641c                	ld	a5,8(s0)

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc020090c:	00878963          	beq	a5,s0,ffffffffc020091e <best_fit_check+0x274>
        struct Page* p = le2page(le, page_link);
        count--, total -= p->property;
ffffffffc0200910:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200914:	679c                	ld	a5,8(a5)
ffffffffc0200916:	397d                	addiw	s2,s2,-1
ffffffffc0200918:	9c99                	subw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc020091a:	fe879be3          	bne	a5,s0,ffffffffc0200910 <best_fit_check+0x266>
    }
    assert(count == 0);
ffffffffc020091e:	26091363          	bnez	s2,ffffffffc0200b84 <best_fit_check+0x4da>
    assert(total == 0);
ffffffffc0200922:	e0ed                	bnez	s1,ffffffffc0200a04 <best_fit_check+0x35a>
#ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n", score, sumscore);
#endif
}
ffffffffc0200924:	60a6                	ld	ra,72(sp)
ffffffffc0200926:	6406                	ld	s0,64(sp)
ffffffffc0200928:	74e2                	ld	s1,56(sp)
ffffffffc020092a:	7942                	ld	s2,48(sp)
ffffffffc020092c:	79a2                	ld	s3,40(sp)
ffffffffc020092e:	7a02                	ld	s4,32(sp)
ffffffffc0200930:	6ae2                	ld	s5,24(sp)
ffffffffc0200932:	6b42                	ld	s6,16(sp)
ffffffffc0200934:	6ba2                	ld	s7,8(sp)
ffffffffc0200936:	6c02                	ld	s8,0(sp)
ffffffffc0200938:	6161                	addi	sp,sp,80
ffffffffc020093a:	8082                	ret
    while ((le = list_next(le)) != &free_list) {
ffffffffc020093c:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc020093e:	4481                	li	s1,0
ffffffffc0200940:	4901                	li	s2,0
ffffffffc0200942:	b36d                	j	ffffffffc02006ec <best_fit_check+0x42>
        assert(PageProperty(p));
ffffffffc0200944:	00001697          	auipc	a3,0x1
ffffffffc0200948:	fa468693          	addi	a3,a3,-92 # ffffffffc02018e8 <etext+0x29c>
ffffffffc020094c:	00001617          	auipc	a2,0x1
ffffffffc0200950:	f6c60613          	addi	a2,a2,-148 # ffffffffc02018b8 <etext+0x26c>
ffffffffc0200954:	11c00593          	li	a1,284
ffffffffc0200958:	00001517          	auipc	a0,0x1
ffffffffc020095c:	f7850513          	addi	a0,a0,-136 # ffffffffc02018d0 <etext+0x284>
ffffffffc0200960:	863ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200964:	00001697          	auipc	a3,0x1
ffffffffc0200968:	01468693          	addi	a3,a3,20 # ffffffffc0201978 <etext+0x32c>
ffffffffc020096c:	00001617          	auipc	a2,0x1
ffffffffc0200970:	f4c60613          	addi	a2,a2,-180 # ffffffffc02018b8 <etext+0x26c>
ffffffffc0200974:	0e800593          	li	a1,232
ffffffffc0200978:	00001517          	auipc	a0,0x1
ffffffffc020097c:	f5850513          	addi	a0,a0,-168 # ffffffffc02018d0 <etext+0x284>
ffffffffc0200980:	843ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200984:	00001697          	auipc	a3,0x1
ffffffffc0200988:	01c68693          	addi	a3,a3,28 # ffffffffc02019a0 <etext+0x354>
ffffffffc020098c:	00001617          	auipc	a2,0x1
ffffffffc0200990:	f2c60613          	addi	a2,a2,-212 # ffffffffc02018b8 <etext+0x26c>
ffffffffc0200994:	0e900593          	li	a1,233
ffffffffc0200998:	00001517          	auipc	a0,0x1
ffffffffc020099c:	f3850513          	addi	a0,a0,-200 # ffffffffc02018d0 <etext+0x284>
ffffffffc02009a0:	823ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc02009a4:	00001697          	auipc	a3,0x1
ffffffffc02009a8:	03c68693          	addi	a3,a3,60 # ffffffffc02019e0 <etext+0x394>
ffffffffc02009ac:	00001617          	auipc	a2,0x1
ffffffffc02009b0:	f0c60613          	addi	a2,a2,-244 # ffffffffc02018b8 <etext+0x26c>
ffffffffc02009b4:	0eb00593          	li	a1,235
ffffffffc02009b8:	00001517          	auipc	a0,0x1
ffffffffc02009bc:	f1850513          	addi	a0,a0,-232 # ffffffffc02018d0 <etext+0x284>
ffffffffc02009c0:	803ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(!list_empty(&free_list));
ffffffffc02009c4:	00001697          	auipc	a3,0x1
ffffffffc02009c8:	0a468693          	addi	a3,a3,164 # ffffffffc0201a68 <etext+0x41c>
ffffffffc02009cc:	00001617          	auipc	a2,0x1
ffffffffc02009d0:	eec60613          	addi	a2,a2,-276 # ffffffffc02018b8 <etext+0x26c>
ffffffffc02009d4:	10400593          	li	a1,260
ffffffffc02009d8:	00001517          	auipc	a0,0x1
ffffffffc02009dc:	ef850513          	addi	a0,a0,-264 # ffffffffc02018d0 <etext+0x284>
ffffffffc02009e0:	fe2ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02009e4:	00001697          	auipc	a3,0x1
ffffffffc02009e8:	f7468693          	addi	a3,a3,-140 # ffffffffc0201958 <etext+0x30c>
ffffffffc02009ec:	00001617          	auipc	a2,0x1
ffffffffc02009f0:	ecc60613          	addi	a2,a2,-308 # ffffffffc02018b8 <etext+0x26c>
ffffffffc02009f4:	0e600593          	li	a1,230
ffffffffc02009f8:	00001517          	auipc	a0,0x1
ffffffffc02009fc:	ed850513          	addi	a0,a0,-296 # ffffffffc02018d0 <etext+0x284>
ffffffffc0200a00:	fc2ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(total == 0);
ffffffffc0200a04:	00001697          	auipc	a3,0x1
ffffffffc0200a08:	19468693          	addi	a3,a3,404 # ffffffffc0201b98 <etext+0x54c>
ffffffffc0200a0c:	00001617          	auipc	a2,0x1
ffffffffc0200a10:	eac60613          	addi	a2,a2,-340 # ffffffffc02018b8 <etext+0x26c>
ffffffffc0200a14:	15e00593          	li	a1,350
ffffffffc0200a18:	00001517          	auipc	a0,0x1
ffffffffc0200a1c:	eb850513          	addi	a0,a0,-328 # ffffffffc02018d0 <etext+0x284>
ffffffffc0200a20:	fa2ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(total == nr_free_pages());
ffffffffc0200a24:	00001697          	auipc	a3,0x1
ffffffffc0200a28:	ed468693          	addi	a3,a3,-300 # ffffffffc02018f8 <etext+0x2ac>
ffffffffc0200a2c:	00001617          	auipc	a2,0x1
ffffffffc0200a30:	e8c60613          	addi	a2,a2,-372 # ffffffffc02018b8 <etext+0x26c>
ffffffffc0200a34:	11f00593          	li	a1,287
ffffffffc0200a38:	00001517          	auipc	a0,0x1
ffffffffc0200a3c:	e9850513          	addi	a0,a0,-360 # ffffffffc02018d0 <etext+0x284>
ffffffffc0200a40:	f82ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200a44:	00001697          	auipc	a3,0x1
ffffffffc0200a48:	ef468693          	addi	a3,a3,-268 # ffffffffc0201938 <etext+0x2ec>
ffffffffc0200a4c:	00001617          	auipc	a2,0x1
ffffffffc0200a50:	e6c60613          	addi	a2,a2,-404 # ffffffffc02018b8 <etext+0x26c>
ffffffffc0200a54:	0e500593          	li	a1,229
ffffffffc0200a58:	00001517          	auipc	a0,0x1
ffffffffc0200a5c:	e7850513          	addi	a0,a0,-392 # ffffffffc02018d0 <etext+0x284>
ffffffffc0200a60:	f62ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200a64:	00001697          	auipc	a3,0x1
ffffffffc0200a68:	eb468693          	addi	a3,a3,-332 # ffffffffc0201918 <etext+0x2cc>
ffffffffc0200a6c:	00001617          	auipc	a2,0x1
ffffffffc0200a70:	e4c60613          	addi	a2,a2,-436 # ffffffffc02018b8 <etext+0x26c>
ffffffffc0200a74:	0e400593          	li	a1,228
ffffffffc0200a78:	00001517          	auipc	a0,0x1
ffffffffc0200a7c:	e5850513          	addi	a0,a0,-424 # ffffffffc02018d0 <etext+0x284>
ffffffffc0200a80:	f42ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200a84:	00001697          	auipc	a3,0x1
ffffffffc0200a88:	fbc68693          	addi	a3,a3,-68 # ffffffffc0201a40 <etext+0x3f4>
ffffffffc0200a8c:	00001617          	auipc	a2,0x1
ffffffffc0200a90:	e2c60613          	addi	a2,a2,-468 # ffffffffc02018b8 <etext+0x26c>
ffffffffc0200a94:	10100593          	li	a1,257
ffffffffc0200a98:	00001517          	auipc	a0,0x1
ffffffffc0200a9c:	e3850513          	addi	a0,a0,-456 # ffffffffc02018d0 <etext+0x284>
ffffffffc0200aa0:	f22ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200aa4:	00001697          	auipc	a3,0x1
ffffffffc0200aa8:	eb468693          	addi	a3,a3,-332 # ffffffffc0201958 <etext+0x30c>
ffffffffc0200aac:	00001617          	auipc	a2,0x1
ffffffffc0200ab0:	e0c60613          	addi	a2,a2,-500 # ffffffffc02018b8 <etext+0x26c>
ffffffffc0200ab4:	0ff00593          	li	a1,255
ffffffffc0200ab8:	00001517          	auipc	a0,0x1
ffffffffc0200abc:	e1850513          	addi	a0,a0,-488 # ffffffffc02018d0 <etext+0x284>
ffffffffc0200ac0:	f02ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200ac4:	00001697          	auipc	a3,0x1
ffffffffc0200ac8:	e7468693          	addi	a3,a3,-396 # ffffffffc0201938 <etext+0x2ec>
ffffffffc0200acc:	00001617          	auipc	a2,0x1
ffffffffc0200ad0:	dec60613          	addi	a2,a2,-532 # ffffffffc02018b8 <etext+0x26c>
ffffffffc0200ad4:	0fe00593          	li	a1,254
ffffffffc0200ad8:	00001517          	auipc	a0,0x1
ffffffffc0200adc:	df850513          	addi	a0,a0,-520 # ffffffffc02018d0 <etext+0x284>
ffffffffc0200ae0:	ee2ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200ae4:	00001697          	auipc	a3,0x1
ffffffffc0200ae8:	e3468693          	addi	a3,a3,-460 # ffffffffc0201918 <etext+0x2cc>
ffffffffc0200aec:	00001617          	auipc	a2,0x1
ffffffffc0200af0:	dcc60613          	addi	a2,a2,-564 # ffffffffc02018b8 <etext+0x26c>
ffffffffc0200af4:	0fd00593          	li	a1,253
ffffffffc0200af8:	00001517          	auipc	a0,0x1
ffffffffc0200afc:	dd850513          	addi	a0,a0,-552 # ffffffffc02018d0 <etext+0x284>
ffffffffc0200b00:	ec2ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(nr_free == 3);
ffffffffc0200b04:	00001697          	auipc	a3,0x1
ffffffffc0200b08:	f5468693          	addi	a3,a3,-172 # ffffffffc0201a58 <etext+0x40c>
ffffffffc0200b0c:	00001617          	auipc	a2,0x1
ffffffffc0200b10:	dac60613          	addi	a2,a2,-596 # ffffffffc02018b8 <etext+0x26c>
ffffffffc0200b14:	0fb00593          	li	a1,251
ffffffffc0200b18:	00001517          	auipc	a0,0x1
ffffffffc0200b1c:	db850513          	addi	a0,a0,-584 # ffffffffc02018d0 <etext+0x284>
ffffffffc0200b20:	ea2ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200b24:	00001697          	auipc	a3,0x1
ffffffffc0200b28:	f1c68693          	addi	a3,a3,-228 # ffffffffc0201a40 <etext+0x3f4>
ffffffffc0200b2c:	00001617          	auipc	a2,0x1
ffffffffc0200b30:	d8c60613          	addi	a2,a2,-628 # ffffffffc02018b8 <etext+0x26c>
ffffffffc0200b34:	0f600593          	li	a1,246
ffffffffc0200b38:	00001517          	auipc	a0,0x1
ffffffffc0200b3c:	d9850513          	addi	a0,a0,-616 # ffffffffc02018d0 <etext+0x284>
ffffffffc0200b40:	e82ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200b44:	00001697          	auipc	a3,0x1
ffffffffc0200b48:	edc68693          	addi	a3,a3,-292 # ffffffffc0201a20 <etext+0x3d4>
ffffffffc0200b4c:	00001617          	auipc	a2,0x1
ffffffffc0200b50:	d6c60613          	addi	a2,a2,-660 # ffffffffc02018b8 <etext+0x26c>
ffffffffc0200b54:	0ed00593          	li	a1,237
ffffffffc0200b58:	00001517          	auipc	a0,0x1
ffffffffc0200b5c:	d7850513          	addi	a0,a0,-648 # ffffffffc02018d0 <etext+0x284>
ffffffffc0200b60:	e62ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200b64:	00001697          	auipc	a3,0x1
ffffffffc0200b68:	e9c68693          	addi	a3,a3,-356 # ffffffffc0201a00 <etext+0x3b4>
ffffffffc0200b6c:	00001617          	auipc	a2,0x1
ffffffffc0200b70:	d4c60613          	addi	a2,a2,-692 # ffffffffc02018b8 <etext+0x26c>
ffffffffc0200b74:	0ec00593          	li	a1,236
ffffffffc0200b78:	00001517          	auipc	a0,0x1
ffffffffc0200b7c:	d5850513          	addi	a0,a0,-680 # ffffffffc02018d0 <etext+0x284>
ffffffffc0200b80:	e42ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(count == 0);
ffffffffc0200b84:	00001697          	auipc	a3,0x1
ffffffffc0200b88:	00468693          	addi	a3,a3,4 # ffffffffc0201b88 <etext+0x53c>
ffffffffc0200b8c:	00001617          	auipc	a2,0x1
ffffffffc0200b90:	d2c60613          	addi	a2,a2,-724 # ffffffffc02018b8 <etext+0x26c>
ffffffffc0200b94:	15d00593          	li	a1,349
ffffffffc0200b98:	00001517          	auipc	a0,0x1
ffffffffc0200b9c:	d3850513          	addi	a0,a0,-712 # ffffffffc02018d0 <etext+0x284>
ffffffffc0200ba0:	e22ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(nr_free == 0);
ffffffffc0200ba4:	00001697          	auipc	a3,0x1
ffffffffc0200ba8:	efc68693          	addi	a3,a3,-260 # ffffffffc0201aa0 <etext+0x454>
ffffffffc0200bac:	00001617          	auipc	a2,0x1
ffffffffc0200bb0:	d0c60613          	addi	a2,a2,-756 # ffffffffc02018b8 <etext+0x26c>
ffffffffc0200bb4:	15200593          	li	a1,338
ffffffffc0200bb8:	00001517          	auipc	a0,0x1
ffffffffc0200bbc:	d1850513          	addi	a0,a0,-744 # ffffffffc02018d0 <etext+0x284>
ffffffffc0200bc0:	e02ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200bc4:	00001697          	auipc	a3,0x1
ffffffffc0200bc8:	e7c68693          	addi	a3,a3,-388 # ffffffffc0201a40 <etext+0x3f4>
ffffffffc0200bcc:	00001617          	auipc	a2,0x1
ffffffffc0200bd0:	cec60613          	addi	a2,a2,-788 # ffffffffc02018b8 <etext+0x26c>
ffffffffc0200bd4:	14c00593          	li	a1,332
ffffffffc0200bd8:	00001517          	auipc	a0,0x1
ffffffffc0200bdc:	cf850513          	addi	a0,a0,-776 # ffffffffc02018d0 <etext+0x284>
ffffffffc0200be0:	de2ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0200be4:	00001697          	auipc	a3,0x1
ffffffffc0200be8:	f8468693          	addi	a3,a3,-124 # ffffffffc0201b68 <etext+0x51c>
ffffffffc0200bec:	00001617          	auipc	a2,0x1
ffffffffc0200bf0:	ccc60613          	addi	a2,a2,-820 # ffffffffc02018b8 <etext+0x26c>
ffffffffc0200bf4:	14b00593          	li	a1,331
ffffffffc0200bf8:	00001517          	auipc	a0,0x1
ffffffffc0200bfc:	cd850513          	addi	a0,a0,-808 # ffffffffc02018d0 <etext+0x284>
ffffffffc0200c00:	dc2ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(p0 + 4 == p1);
ffffffffc0200c04:	00001697          	auipc	a3,0x1
ffffffffc0200c08:	f5468693          	addi	a3,a3,-172 # ffffffffc0201b58 <etext+0x50c>
ffffffffc0200c0c:	00001617          	auipc	a2,0x1
ffffffffc0200c10:	cac60613          	addi	a2,a2,-852 # ffffffffc02018b8 <etext+0x26c>
ffffffffc0200c14:	14300593          	li	a1,323
ffffffffc0200c18:	00001517          	auipc	a0,0x1
ffffffffc0200c1c:	cb850513          	addi	a0,a0,-840 # ffffffffc02018d0 <etext+0x284>
ffffffffc0200c20:	da2ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(alloc_pages(2) != NULL);      // best fit feature
ffffffffc0200c24:	00001697          	auipc	a3,0x1
ffffffffc0200c28:	f1c68693          	addi	a3,a3,-228 # ffffffffc0201b40 <etext+0x4f4>
ffffffffc0200c2c:	00001617          	auipc	a2,0x1
ffffffffc0200c30:	c8c60613          	addi	a2,a2,-884 # ffffffffc02018b8 <etext+0x26c>
ffffffffc0200c34:	14200593          	li	a1,322
ffffffffc0200c38:	00001517          	auipc	a0,0x1
ffffffffc0200c3c:	c9850513          	addi	a0,a0,-872 # ffffffffc02018d0 <etext+0x284>
ffffffffc0200c40:	d82ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert((p1 = alloc_pages(1)) != NULL);
ffffffffc0200c44:	00001697          	auipc	a3,0x1
ffffffffc0200c48:	edc68693          	addi	a3,a3,-292 # ffffffffc0201b20 <etext+0x4d4>
ffffffffc0200c4c:	00001617          	auipc	a2,0x1
ffffffffc0200c50:	c6c60613          	addi	a2,a2,-916 # ffffffffc02018b8 <etext+0x26c>
ffffffffc0200c54:	14100593          	li	a1,321
ffffffffc0200c58:	00001517          	auipc	a0,0x1
ffffffffc0200c5c:	c7850513          	addi	a0,a0,-904 # ffffffffc02018d0 <etext+0x284>
ffffffffc0200c60:	d62ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(PageProperty(p0 + 1) && p0[1].property == 2);
ffffffffc0200c64:	00001697          	auipc	a3,0x1
ffffffffc0200c68:	e8c68693          	addi	a3,a3,-372 # ffffffffc0201af0 <etext+0x4a4>
ffffffffc0200c6c:	00001617          	auipc	a2,0x1
ffffffffc0200c70:	c4c60613          	addi	a2,a2,-948 # ffffffffc02018b8 <etext+0x26c>
ffffffffc0200c74:	13f00593          	li	a1,319
ffffffffc0200c78:	00001517          	auipc	a0,0x1
ffffffffc0200c7c:	c5850513          	addi	a0,a0,-936 # ffffffffc02018d0 <etext+0x284>
ffffffffc0200c80:	d42ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc0200c84:	00001697          	auipc	a3,0x1
ffffffffc0200c88:	e5468693          	addi	a3,a3,-428 # ffffffffc0201ad8 <etext+0x48c>
ffffffffc0200c8c:	00001617          	auipc	a2,0x1
ffffffffc0200c90:	c2c60613          	addi	a2,a2,-980 # ffffffffc02018b8 <etext+0x26c>
ffffffffc0200c94:	13e00593          	li	a1,318
ffffffffc0200c98:	00001517          	auipc	a0,0x1
ffffffffc0200c9c:	c3850513          	addi	a0,a0,-968 # ffffffffc02018d0 <etext+0x284>
ffffffffc0200ca0:	d22ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200ca4:	00001697          	auipc	a3,0x1
ffffffffc0200ca8:	d9c68693          	addi	a3,a3,-612 # ffffffffc0201a40 <etext+0x3f4>
ffffffffc0200cac:	00001617          	auipc	a2,0x1
ffffffffc0200cb0:	c0c60613          	addi	a2,a2,-1012 # ffffffffc02018b8 <etext+0x26c>
ffffffffc0200cb4:	13200593          	li	a1,306
ffffffffc0200cb8:	00001517          	auipc	a0,0x1
ffffffffc0200cbc:	c1850513          	addi	a0,a0,-1000 # ffffffffc02018d0 <etext+0x284>
ffffffffc0200cc0:	d02ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(!PageProperty(p0));
ffffffffc0200cc4:	00001697          	auipc	a3,0x1
ffffffffc0200cc8:	dfc68693          	addi	a3,a3,-516 # ffffffffc0201ac0 <etext+0x474>
ffffffffc0200ccc:	00001617          	auipc	a2,0x1
ffffffffc0200cd0:	bec60613          	addi	a2,a2,-1044 # ffffffffc02018b8 <etext+0x26c>
ffffffffc0200cd4:	12900593          	li	a1,297
ffffffffc0200cd8:	00001517          	auipc	a0,0x1
ffffffffc0200cdc:	bf850513          	addi	a0,a0,-1032 # ffffffffc02018d0 <etext+0x284>
ffffffffc0200ce0:	ce2ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(p0 != NULL);
ffffffffc0200ce4:	00001697          	auipc	a3,0x1
ffffffffc0200ce8:	dcc68693          	addi	a3,a3,-564 # ffffffffc0201ab0 <etext+0x464>
ffffffffc0200cec:	00001617          	auipc	a2,0x1
ffffffffc0200cf0:	bcc60613          	addi	a2,a2,-1076 # ffffffffc02018b8 <etext+0x26c>
ffffffffc0200cf4:	12800593          	li	a1,296
ffffffffc0200cf8:	00001517          	auipc	a0,0x1
ffffffffc0200cfc:	bd850513          	addi	a0,a0,-1064 # ffffffffc02018d0 <etext+0x284>
ffffffffc0200d00:	cc2ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(nr_free == 0);
ffffffffc0200d04:	00001697          	auipc	a3,0x1
ffffffffc0200d08:	d9c68693          	addi	a3,a3,-612 # ffffffffc0201aa0 <etext+0x454>
ffffffffc0200d0c:	00001617          	auipc	a2,0x1
ffffffffc0200d10:	bac60613          	addi	a2,a2,-1108 # ffffffffc02018b8 <etext+0x26c>
ffffffffc0200d14:	10a00593          	li	a1,266
ffffffffc0200d18:	00001517          	auipc	a0,0x1
ffffffffc0200d1c:	bb850513          	addi	a0,a0,-1096 # ffffffffc02018d0 <etext+0x284>
ffffffffc0200d20:	ca2ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200d24:	00001697          	auipc	a3,0x1
ffffffffc0200d28:	d1c68693          	addi	a3,a3,-740 # ffffffffc0201a40 <etext+0x3f4>
ffffffffc0200d2c:	00001617          	auipc	a2,0x1
ffffffffc0200d30:	b8c60613          	addi	a2,a2,-1140 # ffffffffc02018b8 <etext+0x26c>
ffffffffc0200d34:	10800593          	li	a1,264
ffffffffc0200d38:	00001517          	auipc	a0,0x1
ffffffffc0200d3c:	b9850513          	addi	a0,a0,-1128 # ffffffffc02018d0 <etext+0x284>
ffffffffc0200d40:	c82ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc0200d44:	00001697          	auipc	a3,0x1
ffffffffc0200d48:	d3c68693          	addi	a3,a3,-708 # ffffffffc0201a80 <etext+0x434>
ffffffffc0200d4c:	00001617          	auipc	a2,0x1
ffffffffc0200d50:	b6c60613          	addi	a2,a2,-1172 # ffffffffc02018b8 <etext+0x26c>
ffffffffc0200d54:	10700593          	li	a1,263
ffffffffc0200d58:	00001517          	auipc	a0,0x1
ffffffffc0200d5c:	b7850513          	addi	a0,a0,-1160 # ffffffffc02018d0 <etext+0x284>
ffffffffc0200d60:	c62ff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc0200d64 <best_fit_free_pages>:
best_fit_free_pages(struct Page* base, size_t n) {
ffffffffc0200d64:	1141                	addi	sp,sp,-16
ffffffffc0200d66:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0200d68:	14058d63          	beqz	a1,ffffffffc0200ec2 <best_fit_free_pages+0x15e>
    for (; p != base + n; p++) {
ffffffffc0200d6c:	00259693          	slli	a3,a1,0x2
ffffffffc0200d70:	96ae                	add	a3,a3,a1
ffffffffc0200d72:	068e                	slli	a3,a3,0x3
ffffffffc0200d74:	96aa                	add	a3,a3,a0
ffffffffc0200d76:	87aa                	mv	a5,a0
ffffffffc0200d78:	00d50e63          	beq	a0,a3,ffffffffc0200d94 <best_fit_free_pages+0x30>
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0200d7c:	6798                	ld	a4,8(a5)
ffffffffc0200d7e:	8b0d                	andi	a4,a4,3
ffffffffc0200d80:	12071163          	bnez	a4,ffffffffc0200ea2 <best_fit_free_pages+0x13e>
        p->flags = 0;
ffffffffc0200d84:	0007b423          	sd	zero,8(a5)



static inline int page_ref(struct Page *page) { return page->ref; }

static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0200d88:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p++) {
ffffffffc0200d8c:	02878793          	addi	a5,a5,40
ffffffffc0200d90:	fed796e3          	bne	a5,a3,ffffffffc0200d7c <best_fit_free_pages+0x18>
    SetPageProperty(base);
ffffffffc0200d94:	00853883          	ld	a7,8(a0)
    nr_free += n;
ffffffffc0200d98:	00004617          	auipc	a2,0x4
ffffffffc0200d9c:	28060613          	addi	a2,a2,640 # ffffffffc0205018 <free_area>
ffffffffc0200da0:	4a18                	lw	a4,16(a2)
    base->property = n;
ffffffffc0200da2:	2581                	sext.w	a1,a1
    return list->next == list;
ffffffffc0200da4:	661c                	ld	a5,8(a2)
    SetPageProperty(base);
ffffffffc0200da6:	0028e693          	ori	a3,a7,2
    base->property = n;
ffffffffc0200daa:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc0200dac:	e514                	sd	a3,8(a0)
    nr_free += n;
ffffffffc0200dae:	9f2d                	addw	a4,a4,a1
ffffffffc0200db0:	ca18                	sw	a4,16(a2)
    if (list_empty(&free_list)) {
ffffffffc0200db2:	00c79763          	bne	a5,a2,ffffffffc0200dc0 <best_fit_free_pages+0x5c>
ffffffffc0200db6:	a0bd                	j	ffffffffc0200e24 <best_fit_free_pages+0xc0>
    return listelm->next;
ffffffffc0200db8:	6794                	ld	a3,8(a5)
            else if (list_next(le) == &free_list) {
ffffffffc0200dba:	06c68e63          	beq	a3,a2,ffffffffc0200e36 <best_fit_free_pages+0xd2>
ffffffffc0200dbe:	87b6                	mv	a5,a3
            struct Page* page = le2page(le, page_link);
ffffffffc0200dc0:	fe878713          	addi	a4,a5,-24
ffffffffc0200dc4:	86ba                	mv	a3,a4
            if (base < page) {
ffffffffc0200dc6:	fee579e3          	bgeu	a0,a4,ffffffffc0200db8 <best_fit_free_pages+0x54>
    __list_add(elm, listelm->prev, listelm);
ffffffffc0200dca:	0007b803          	ld	a6,0(a5)
                list_add_before(le, &(base->page_link));
ffffffffc0200dce:	01850713          	addi	a4,a0,24
    prev->next = next->prev = elm;
ffffffffc0200dd2:	e398                	sd	a4,0(a5)
ffffffffc0200dd4:	00e83423          	sd	a4,8(a6)
    elm->next = next;
ffffffffc0200dd8:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0200dda:	01053c23          	sd	a6,24(a0)
    if (le != &free_list) {
ffffffffc0200dde:	02c80563          	beq	a6,a2,ffffffffc0200e08 <best_fit_free_pages+0xa4>
        if (p + p->property == base) {
ffffffffc0200de2:	ff882e03          	lw	t3,-8(a6)
        p = le2page(le, page_link);
ffffffffc0200de6:	fe880713          	addi	a4,a6,-24
        if (p + p->property == base) {
ffffffffc0200dea:	020e1313          	slli	t1,t3,0x20
ffffffffc0200dee:	02035313          	srli	t1,t1,0x20
ffffffffc0200df2:	00231693          	slli	a3,t1,0x2
ffffffffc0200df6:	969a                	add	a3,a3,t1
ffffffffc0200df8:	068e                	slli	a3,a3,0x3
ffffffffc0200dfa:	96ba                	add	a3,a3,a4
ffffffffc0200dfc:	06d50263          	beq	a0,a3,ffffffffc0200e60 <best_fit_free_pages+0xfc>
    if (le != &free_list) {
ffffffffc0200e00:	fe878693          	addi	a3,a5,-24
ffffffffc0200e04:	00c78d63          	beq	a5,a2,ffffffffc0200e1e <best_fit_free_pages+0xba>
        if (base + base->property == p) {
ffffffffc0200e08:	490c                	lw	a1,16(a0)
ffffffffc0200e0a:	02059613          	slli	a2,a1,0x20
ffffffffc0200e0e:	9201                	srli	a2,a2,0x20
ffffffffc0200e10:	00261713          	slli	a4,a2,0x2
ffffffffc0200e14:	9732                	add	a4,a4,a2
ffffffffc0200e16:	070e                	slli	a4,a4,0x3
ffffffffc0200e18:	972a                	add	a4,a4,a0
ffffffffc0200e1a:	06e68163          	beq	a3,a4,ffffffffc0200e7c <best_fit_free_pages+0x118>
}
ffffffffc0200e1e:	60a2                	ld	ra,8(sp)
ffffffffc0200e20:	0141                	addi	sp,sp,16
ffffffffc0200e22:	8082                	ret
ffffffffc0200e24:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc0200e26:	01850713          	addi	a4,a0,24
    prev->next = next->prev = elm;
ffffffffc0200e2a:	e398                	sd	a4,0(a5)
ffffffffc0200e2c:	e798                	sd	a4,8(a5)
    elm->next = next;
ffffffffc0200e2e:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0200e30:	ed1c                	sd	a5,24(a0)
}
ffffffffc0200e32:	0141                	addi	sp,sp,16
ffffffffc0200e34:	8082                	ret
ffffffffc0200e36:	883e                	mv	a6,a5
        if (p + p->property == base) {
ffffffffc0200e38:	ff882e03          	lw	t3,-8(a6)
                list_add(le, &(base->page_link));
ffffffffc0200e3c:	01850693          	addi	a3,a0,24
    prev->next = next->prev = elm;
ffffffffc0200e40:	e794                	sd	a3,8(a5)
        if (p + p->property == base) {
ffffffffc0200e42:	020e1313          	slli	t1,t3,0x20
ffffffffc0200e46:	02035313          	srli	t1,t1,0x20
ffffffffc0200e4a:	e214                	sd	a3,0(a2)
ffffffffc0200e4c:	00231693          	slli	a3,t1,0x2
ffffffffc0200e50:	969a                	add	a3,a3,t1
ffffffffc0200e52:	068e                	slli	a3,a3,0x3
    elm->prev = prev;
ffffffffc0200e54:	ed1c                	sd	a5,24(a0)
    elm->next = next;
ffffffffc0200e56:	f110                	sd	a2,32(a0)
ffffffffc0200e58:	96ba                	add	a3,a3,a4
    elm->prev = prev;
ffffffffc0200e5a:	87b2                	mv	a5,a2
ffffffffc0200e5c:	fad512e3          	bne	a0,a3,ffffffffc0200e00 <best_fit_free_pages+0x9c>
            p->property += base->property;
ffffffffc0200e60:	01c585bb          	addw	a1,a1,t3
ffffffffc0200e64:	feb82c23          	sw	a1,-8(a6)
            ClearPageProperty(base);
ffffffffc0200e68:	ffd8f893          	andi	a7,a7,-3
ffffffffc0200e6c:	01153423          	sd	a7,8(a0)
    prev->next = next;
ffffffffc0200e70:	00f83423          	sd	a5,8(a6)
    next->prev = prev;
ffffffffc0200e74:	0107b023          	sd	a6,0(a5)
            base = p; // 归并后用更大的前块继续尝试与后块合并
ffffffffc0200e78:	853a                	mv	a0,a4
ffffffffc0200e7a:	b759                	j	ffffffffc0200e00 <best_fit_free_pages+0x9c>
            base->property += p->property;
ffffffffc0200e7c:	ff87a683          	lw	a3,-8(a5)
            ClearPageProperty(p);
ffffffffc0200e80:	ff07b703          	ld	a4,-16(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc0200e84:	0007b803          	ld	a6,0(a5)
ffffffffc0200e88:	6790                	ld	a2,8(a5)
            base->property += p->property;
ffffffffc0200e8a:	9db5                	addw	a1,a1,a3
ffffffffc0200e8c:	c90c                	sw	a1,16(a0)
            ClearPageProperty(p);
ffffffffc0200e8e:	9b75                	andi	a4,a4,-3
ffffffffc0200e90:	fee7b823          	sd	a4,-16(a5)
}
ffffffffc0200e94:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc0200e96:	00c83423          	sd	a2,8(a6)
    next->prev = prev;
ffffffffc0200e9a:	01063023          	sd	a6,0(a2)
ffffffffc0200e9e:	0141                	addi	sp,sp,16
ffffffffc0200ea0:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0200ea2:	00001697          	auipc	a3,0x1
ffffffffc0200ea6:	d0668693          	addi	a3,a3,-762 # ffffffffc0201ba8 <etext+0x55c>
ffffffffc0200eaa:	00001617          	auipc	a2,0x1
ffffffffc0200eae:	a0e60613          	addi	a2,a2,-1522 # ffffffffc02018b8 <etext+0x26c>
ffffffffc0200eb2:	0a100593          	li	a1,161
ffffffffc0200eb6:	00001517          	auipc	a0,0x1
ffffffffc0200eba:	a1a50513          	addi	a0,a0,-1510 # ffffffffc02018d0 <etext+0x284>
ffffffffc0200ebe:	b04ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(n > 0);
ffffffffc0200ec2:	00001697          	auipc	a3,0x1
ffffffffc0200ec6:	9ee68693          	addi	a3,a3,-1554 # ffffffffc02018b0 <etext+0x264>
ffffffffc0200eca:	00001617          	auipc	a2,0x1
ffffffffc0200ece:	9ee60613          	addi	a2,a2,-1554 # ffffffffc02018b8 <etext+0x26c>
ffffffffc0200ed2:	09e00593          	li	a1,158
ffffffffc0200ed6:	00001517          	auipc	a0,0x1
ffffffffc0200eda:	9fa50513          	addi	a0,a0,-1542 # ffffffffc02018d0 <etext+0x284>
ffffffffc0200ede:	ae4ff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc0200ee2 <best_fit_init_memmap>:
best_fit_init_memmap(struct Page* base, size_t n) {
ffffffffc0200ee2:	1141                	addi	sp,sp,-16
ffffffffc0200ee4:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0200ee6:	c9dd                	beqz	a1,ffffffffc0200f9c <best_fit_init_memmap+0xba>
    for (; p != base + n; p++) {
ffffffffc0200ee8:	00259693          	slli	a3,a1,0x2
ffffffffc0200eec:	96ae                	add	a3,a3,a1
ffffffffc0200eee:	068e                	slli	a3,a3,0x3
ffffffffc0200ef0:	96aa                	add	a3,a3,a0
ffffffffc0200ef2:	87aa                	mv	a5,a0
ffffffffc0200ef4:	00d50f63          	beq	a0,a3,ffffffffc0200f12 <best_fit_init_memmap+0x30>
        assert(PageReserved(p));
ffffffffc0200ef8:	6798                	ld	a4,8(a5)
ffffffffc0200efa:	8b05                	andi	a4,a4,1
ffffffffc0200efc:	c341                	beqz	a4,ffffffffc0200f7c <best_fit_init_memmap+0x9a>
        p->flags = 0;
ffffffffc0200efe:	0007b423          	sd	zero,8(a5)
        p->property = 0;
ffffffffc0200f02:	0007a823          	sw	zero,16(a5)
ffffffffc0200f06:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p++) {
ffffffffc0200f0a:	02878793          	addi	a5,a5,40
ffffffffc0200f0e:	fed795e3          	bne	a5,a3,ffffffffc0200ef8 <best_fit_init_memmap+0x16>
    SetPageProperty(base);
ffffffffc0200f12:	6510                	ld	a2,8(a0)
    nr_free += n;
ffffffffc0200f14:	00004697          	auipc	a3,0x4
ffffffffc0200f18:	10468693          	addi	a3,a3,260 # ffffffffc0205018 <free_area>
ffffffffc0200f1c:	4a98                	lw	a4,16(a3)
    base->property = n;
ffffffffc0200f1e:	2581                	sext.w	a1,a1
    return list->next == list;
ffffffffc0200f20:	669c                	ld	a5,8(a3)
    SetPageProperty(base);
ffffffffc0200f22:	00266613          	ori	a2,a2,2
    base->property = n;
ffffffffc0200f26:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc0200f28:	e510                	sd	a2,8(a0)
    nr_free += n;
ffffffffc0200f2a:	9db9                	addw	a1,a1,a4
ffffffffc0200f2c:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list)) {
ffffffffc0200f2e:	00d79763          	bne	a5,a3,ffffffffc0200f3c <best_fit_init_memmap+0x5a>
ffffffffc0200f32:	a01d                	j	ffffffffc0200f58 <best_fit_init_memmap+0x76>
    return listelm->next;
ffffffffc0200f34:	6798                	ld	a4,8(a5)
            if (list_next(le) == &free_list) {
ffffffffc0200f36:	02d70a63          	beq	a4,a3,ffffffffc0200f6a <best_fit_init_memmap+0x88>
ffffffffc0200f3a:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc0200f3c:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc0200f40:	fee57ae3          	bgeu	a0,a4,ffffffffc0200f34 <best_fit_init_memmap+0x52>
    __list_add(elm, listelm->prev, listelm);
ffffffffc0200f44:	6398                	ld	a4,0(a5)
                list_add_before(le, &(base->page_link));
ffffffffc0200f46:	01850693          	addi	a3,a0,24
    prev->next = next->prev = elm;
ffffffffc0200f4a:	e394                	sd	a3,0(a5)
}
ffffffffc0200f4c:	60a2                	ld	ra,8(sp)
ffffffffc0200f4e:	e714                	sd	a3,8(a4)
    elm->next = next;
ffffffffc0200f50:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0200f52:	ed18                	sd	a4,24(a0)
ffffffffc0200f54:	0141                	addi	sp,sp,16
ffffffffc0200f56:	8082                	ret
ffffffffc0200f58:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc0200f5a:	01850713          	addi	a4,a0,24
    prev->next = next->prev = elm;
ffffffffc0200f5e:	e398                	sd	a4,0(a5)
ffffffffc0200f60:	e798                	sd	a4,8(a5)
    elm->next = next;
ffffffffc0200f62:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0200f64:	ed1c                	sd	a5,24(a0)
}
ffffffffc0200f66:	0141                	addi	sp,sp,16
ffffffffc0200f68:	8082                	ret
ffffffffc0200f6a:	60a2                	ld	ra,8(sp)
                list_add(le, &(base->page_link));
ffffffffc0200f6c:	01850713          	addi	a4,a0,24
    prev->next = next->prev = elm;
ffffffffc0200f70:	e798                	sd	a4,8(a5)
ffffffffc0200f72:	e298                	sd	a4,0(a3)
    elm->next = next;
ffffffffc0200f74:	f114                	sd	a3,32(a0)
    elm->prev = prev;
ffffffffc0200f76:	ed1c                	sd	a5,24(a0)
}
ffffffffc0200f78:	0141                	addi	sp,sp,16
ffffffffc0200f7a:	8082                	ret
        assert(PageReserved(p));
ffffffffc0200f7c:	00001697          	auipc	a3,0x1
ffffffffc0200f80:	c5468693          	addi	a3,a3,-940 # ffffffffc0201bd0 <etext+0x584>
ffffffffc0200f84:	00001617          	auipc	a2,0x1
ffffffffc0200f88:	93460613          	addi	a2,a2,-1740 # ffffffffc02018b8 <etext+0x26c>
ffffffffc0200f8c:	04a00593          	li	a1,74
ffffffffc0200f90:	00001517          	auipc	a0,0x1
ffffffffc0200f94:	94050513          	addi	a0,a0,-1728 # ffffffffc02018d0 <etext+0x284>
ffffffffc0200f98:	a2aff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(n > 0);
ffffffffc0200f9c:	00001697          	auipc	a3,0x1
ffffffffc0200fa0:	91468693          	addi	a3,a3,-1772 # ffffffffc02018b0 <etext+0x264>
ffffffffc0200fa4:	00001617          	auipc	a2,0x1
ffffffffc0200fa8:	91460613          	addi	a2,a2,-1772 # ffffffffc02018b8 <etext+0x26c>
ffffffffc0200fac:	04700593          	li	a1,71
ffffffffc0200fb0:	00001517          	auipc	a0,0x1
ffffffffc0200fb4:	92050513          	addi	a0,a0,-1760 # ffffffffc02018d0 <etext+0x284>
ffffffffc0200fb8:	a0aff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc0200fbc <alloc_pages>:
}

// alloc_pages - call pmm->alloc_pages to allocate a continuous n*PAGESIZE
// memory
struct Page *alloc_pages(size_t n) {
    return pmm_manager->alloc_pages(n);
ffffffffc0200fbc:	00004797          	auipc	a5,0x4
ffffffffc0200fc0:	09c7b783          	ld	a5,156(a5) # ffffffffc0205058 <pmm_manager>
ffffffffc0200fc4:	6f9c                	ld	a5,24(a5)
ffffffffc0200fc6:	8782                	jr	a5

ffffffffc0200fc8 <free_pages>:
}

// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    pmm_manager->free_pages(base, n);
ffffffffc0200fc8:	00004797          	auipc	a5,0x4
ffffffffc0200fcc:	0907b783          	ld	a5,144(a5) # ffffffffc0205058 <pmm_manager>
ffffffffc0200fd0:	739c                	ld	a5,32(a5)
ffffffffc0200fd2:	8782                	jr	a5

ffffffffc0200fd4 <nr_free_pages>:
}

// nr_free_pages - call pmm->nr_free_pages to get the size (nr*PAGESIZE)
// of current free memory
size_t nr_free_pages(void) {
    return pmm_manager->nr_free_pages();
ffffffffc0200fd4:	00004797          	auipc	a5,0x4
ffffffffc0200fd8:	0847b783          	ld	a5,132(a5) # ffffffffc0205058 <pmm_manager>
ffffffffc0200fdc:	779c                	ld	a5,40(a5)
ffffffffc0200fde:	8782                	jr	a5

ffffffffc0200fe0 <pmm_init>:
    pmm_manager = &best_fit_pmm_manager;
ffffffffc0200fe0:	00001797          	auipc	a5,0x1
ffffffffc0200fe4:	c1878793          	addi	a5,a5,-1000 # ffffffffc0201bf8 <best_fit_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0200fe8:	638c                	ld	a1,0(a5)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
    }
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
ffffffffc0200fea:	7179                	addi	sp,sp,-48
ffffffffc0200fec:	f022                	sd	s0,32(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0200fee:	00001517          	auipc	a0,0x1
ffffffffc0200ff2:	c4250513          	addi	a0,a0,-958 # ffffffffc0201c30 <best_fit_pmm_manager+0x38>
    pmm_manager = &best_fit_pmm_manager;
ffffffffc0200ff6:	00004417          	auipc	s0,0x4
ffffffffc0200ffa:	06240413          	addi	s0,s0,98 # ffffffffc0205058 <pmm_manager>
void pmm_init(void) {
ffffffffc0200ffe:	f406                	sd	ra,40(sp)
ffffffffc0201000:	ec26                	sd	s1,24(sp)
ffffffffc0201002:	e44e                	sd	s3,8(sp)
ffffffffc0201004:	e84a                	sd	s2,16(sp)
ffffffffc0201006:	e052                	sd	s4,0(sp)
    pmm_manager = &best_fit_pmm_manager;
ffffffffc0201008:	e01c                	sd	a5,0(s0)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc020100a:	942ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    pmm_manager->init();
ffffffffc020100e:	601c                	ld	a5,0(s0)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0201010:	00004497          	auipc	s1,0x4
ffffffffc0201014:	06048493          	addi	s1,s1,96 # ffffffffc0205070 <va_pa_offset>
    pmm_manager->init();
ffffffffc0201018:	679c                	ld	a5,8(a5)
ffffffffc020101a:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc020101c:	57f5                	li	a5,-3
ffffffffc020101e:	07fa                	slli	a5,a5,0x1e
ffffffffc0201020:	e09c                	sd	a5,0(s1)
    uint64_t mem_begin = get_memory_base();
ffffffffc0201022:	d9aff0ef          	jal	ra,ffffffffc02005bc <get_memory_base>
ffffffffc0201026:	89aa                	mv	s3,a0
    uint64_t mem_size  = get_memory_size();
ffffffffc0201028:	d9eff0ef          	jal	ra,ffffffffc02005c6 <get_memory_size>
    if (mem_size == 0) {
ffffffffc020102c:	14050d63          	beqz	a0,ffffffffc0201186 <pmm_init+0x1a6>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc0201030:	892a                	mv	s2,a0
    cprintf("physcial memory map:\n");
ffffffffc0201032:	00001517          	auipc	a0,0x1
ffffffffc0201036:	c4650513          	addi	a0,a0,-954 # ffffffffc0201c78 <best_fit_pmm_manager+0x80>
ffffffffc020103a:	912ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc020103e:	01298a33          	add	s4,s3,s2
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin,
ffffffffc0201042:	864e                	mv	a2,s3
ffffffffc0201044:	fffa0693          	addi	a3,s4,-1
ffffffffc0201048:	85ca                	mv	a1,s2
ffffffffc020104a:	00001517          	auipc	a0,0x1
ffffffffc020104e:	c4650513          	addi	a0,a0,-954 # ffffffffc0201c90 <best_fit_pmm_manager+0x98>
ffffffffc0201052:	8faff0ef          	jal	ra,ffffffffc020014c <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc0201056:	c80007b7          	lui	a5,0xc8000
ffffffffc020105a:	8652                	mv	a2,s4
ffffffffc020105c:	0d47e463          	bltu	a5,s4,ffffffffc0201124 <pmm_init+0x144>
ffffffffc0201060:	00005797          	auipc	a5,0x5
ffffffffc0201064:	01778793          	addi	a5,a5,23 # ffffffffc0206077 <end+0xfff>
ffffffffc0201068:	757d                	lui	a0,0xfffff
ffffffffc020106a:	8d7d                	and	a0,a0,a5
ffffffffc020106c:	8231                	srli	a2,a2,0xc
ffffffffc020106e:	00004797          	auipc	a5,0x4
ffffffffc0201072:	fcc7bd23          	sd	a2,-38(a5) # ffffffffc0205048 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0201076:	00004797          	auipc	a5,0x4
ffffffffc020107a:	fca7bd23          	sd	a0,-38(a5) # ffffffffc0205050 <pages>
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc020107e:	000807b7          	lui	a5,0x80
ffffffffc0201082:	002005b7          	lui	a1,0x200
ffffffffc0201086:	02f60563          	beq	a2,a5,ffffffffc02010b0 <pmm_init+0xd0>
ffffffffc020108a:	00261593          	slli	a1,a2,0x2
ffffffffc020108e:	00c586b3          	add	a3,a1,a2
ffffffffc0201092:	fec007b7          	lui	a5,0xfec00
ffffffffc0201096:	97aa                	add	a5,a5,a0
ffffffffc0201098:	068e                	slli	a3,a3,0x3
ffffffffc020109a:	96be                	add	a3,a3,a5
ffffffffc020109c:	87aa                	mv	a5,a0
        SetPageReserved(pages + i);
ffffffffc020109e:	6798                	ld	a4,8(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc02010a0:	02878793          	addi	a5,a5,40 # fffffffffec00028 <end+0x3e9fafb0>
        SetPageReserved(pages + i);
ffffffffc02010a4:	00176713          	ori	a4,a4,1
ffffffffc02010a8:	fee7b023          	sd	a4,-32(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc02010ac:	fef699e3          	bne	a3,a5,ffffffffc020109e <pmm_init+0xbe>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02010b0:	95b2                	add	a1,a1,a2
ffffffffc02010b2:	fec006b7          	lui	a3,0xfec00
ffffffffc02010b6:	96aa                	add	a3,a3,a0
ffffffffc02010b8:	058e                	slli	a1,a1,0x3
ffffffffc02010ba:	96ae                	add	a3,a3,a1
ffffffffc02010bc:	c02007b7          	lui	a5,0xc0200
ffffffffc02010c0:	0af6e763          	bltu	a3,a5,ffffffffc020116e <pmm_init+0x18e>
ffffffffc02010c4:	6098                	ld	a4,0(s1)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc02010c6:	77fd                	lui	a5,0xfffff
ffffffffc02010c8:	00fa75b3          	and	a1,s4,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02010cc:	8e99                	sub	a3,a3,a4
    if (freemem < mem_end) {
ffffffffc02010ce:	04b6ee63          	bltu	a3,a1,ffffffffc020112a <pmm_init+0x14a>
    satp_physical = PADDR(satp_virtual);
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc02010d2:	601c                	ld	a5,0(s0)
ffffffffc02010d4:	7b9c                	ld	a5,48(a5)
ffffffffc02010d6:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc02010d8:	00001517          	auipc	a0,0x1
ffffffffc02010dc:	c4050513          	addi	a0,a0,-960 # ffffffffc0201d18 <best_fit_pmm_manager+0x120>
ffffffffc02010e0:	86cff0ef          	jal	ra,ffffffffc020014c <cprintf>
    satp_virtual = (pte_t*)boot_page_table_sv39;
ffffffffc02010e4:	00003597          	auipc	a1,0x3
ffffffffc02010e8:	f1c58593          	addi	a1,a1,-228 # ffffffffc0204000 <boot_page_table_sv39>
ffffffffc02010ec:	00004797          	auipc	a5,0x4
ffffffffc02010f0:	f6b7be23          	sd	a1,-132(a5) # ffffffffc0205068 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc02010f4:	c02007b7          	lui	a5,0xc0200
ffffffffc02010f8:	0af5e363          	bltu	a1,a5,ffffffffc020119e <pmm_init+0x1be>
ffffffffc02010fc:	6090                	ld	a2,0(s1)
}
ffffffffc02010fe:	7402                	ld	s0,32(sp)
ffffffffc0201100:	70a2                	ld	ra,40(sp)
ffffffffc0201102:	64e2                	ld	s1,24(sp)
ffffffffc0201104:	6942                	ld	s2,16(sp)
ffffffffc0201106:	69a2                	ld	s3,8(sp)
ffffffffc0201108:	6a02                	ld	s4,0(sp)
    satp_physical = PADDR(satp_virtual);
ffffffffc020110a:	40c58633          	sub	a2,a1,a2
ffffffffc020110e:	00004797          	auipc	a5,0x4
ffffffffc0201112:	f4c7b923          	sd	a2,-174(a5) # ffffffffc0205060 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0201116:	00001517          	auipc	a0,0x1
ffffffffc020111a:	c2250513          	addi	a0,a0,-990 # ffffffffc0201d38 <best_fit_pmm_manager+0x140>
}
ffffffffc020111e:	6145                	addi	sp,sp,48
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0201120:	82cff06f          	j	ffffffffc020014c <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc0201124:	c8000637          	lui	a2,0xc8000
ffffffffc0201128:	bf25                	j	ffffffffc0201060 <pmm_init+0x80>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc020112a:	6705                	lui	a4,0x1
ffffffffc020112c:	177d                	addi	a4,a4,-1
ffffffffc020112e:	96ba                	add	a3,a3,a4
ffffffffc0201130:	8efd                	and	a3,a3,a5
static inline int page_ref_dec(struct Page *page) {
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa) {
    if (PPN(pa) >= npage) {
ffffffffc0201132:	00c6d793          	srli	a5,a3,0xc
ffffffffc0201136:	02c7f063          	bgeu	a5,a2,ffffffffc0201156 <pmm_init+0x176>
    pmm_manager->init_memmap(base, n);
ffffffffc020113a:	6010                	ld	a2,0(s0)
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
ffffffffc020113c:	fff80737          	lui	a4,0xfff80
ffffffffc0201140:	973e                	add	a4,a4,a5
ffffffffc0201142:	00271793          	slli	a5,a4,0x2
ffffffffc0201146:	97ba                	add	a5,a5,a4
ffffffffc0201148:	6a18                	ld	a4,16(a2)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc020114a:	8d95                	sub	a1,a1,a3
ffffffffc020114c:	078e                	slli	a5,a5,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc020114e:	81b1                	srli	a1,a1,0xc
ffffffffc0201150:	953e                	add	a0,a0,a5
ffffffffc0201152:	9702                	jalr	a4
}
ffffffffc0201154:	bfbd                	j	ffffffffc02010d2 <pmm_init+0xf2>
        panic("pa2page called with invalid pa");
ffffffffc0201156:	00001617          	auipc	a2,0x1
ffffffffc020115a:	b9260613          	addi	a2,a2,-1134 # ffffffffc0201ce8 <best_fit_pmm_manager+0xf0>
ffffffffc020115e:	06a00593          	li	a1,106
ffffffffc0201162:	00001517          	auipc	a0,0x1
ffffffffc0201166:	ba650513          	addi	a0,a0,-1114 # ffffffffc0201d08 <best_fit_pmm_manager+0x110>
ffffffffc020116a:	858ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc020116e:	00001617          	auipc	a2,0x1
ffffffffc0201172:	b5260613          	addi	a2,a2,-1198 # ffffffffc0201cc0 <best_fit_pmm_manager+0xc8>
ffffffffc0201176:	05e00593          	li	a1,94
ffffffffc020117a:	00001517          	auipc	a0,0x1
ffffffffc020117e:	aee50513          	addi	a0,a0,-1298 # ffffffffc0201c68 <best_fit_pmm_manager+0x70>
ffffffffc0201182:	840ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
        panic("DTB memory info not available");
ffffffffc0201186:	00001617          	auipc	a2,0x1
ffffffffc020118a:	ac260613          	addi	a2,a2,-1342 # ffffffffc0201c48 <best_fit_pmm_manager+0x50>
ffffffffc020118e:	04600593          	li	a1,70
ffffffffc0201192:	00001517          	auipc	a0,0x1
ffffffffc0201196:	ad650513          	addi	a0,a0,-1322 # ffffffffc0201c68 <best_fit_pmm_manager+0x70>
ffffffffc020119a:	828ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc020119e:	86ae                	mv	a3,a1
ffffffffc02011a0:	00001617          	auipc	a2,0x1
ffffffffc02011a4:	b2060613          	addi	a2,a2,-1248 # ffffffffc0201cc0 <best_fit_pmm_manager+0xc8>
ffffffffc02011a8:	07900593          	li	a1,121
ffffffffc02011ac:	00001517          	auipc	a0,0x1
ffffffffc02011b0:	abc50513          	addi	a0,a0,-1348 # ffffffffc0201c68 <best_fit_pmm_manager+0x70>
ffffffffc02011b4:	80eff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc02011b8 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc02011b8:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02011bc:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc02011be:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02011c2:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc02011c4:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02011c8:	f022                	sd	s0,32(sp)
ffffffffc02011ca:	ec26                	sd	s1,24(sp)
ffffffffc02011cc:	e84a                	sd	s2,16(sp)
ffffffffc02011ce:	f406                	sd	ra,40(sp)
ffffffffc02011d0:	e44e                	sd	s3,8(sp)
ffffffffc02011d2:	84aa                	mv	s1,a0
ffffffffc02011d4:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc02011d6:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc02011da:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc02011dc:	03067e63          	bgeu	a2,a6,ffffffffc0201218 <printnum+0x60>
ffffffffc02011e0:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc02011e2:	00805763          	blez	s0,ffffffffc02011f0 <printnum+0x38>
ffffffffc02011e6:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc02011e8:	85ca                	mv	a1,s2
ffffffffc02011ea:	854e                	mv	a0,s3
ffffffffc02011ec:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc02011ee:	fc65                	bnez	s0,ffffffffc02011e6 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02011f0:	1a02                	slli	s4,s4,0x20
ffffffffc02011f2:	00001797          	auipc	a5,0x1
ffffffffc02011f6:	b8678793          	addi	a5,a5,-1146 # ffffffffc0201d78 <best_fit_pmm_manager+0x180>
ffffffffc02011fa:	020a5a13          	srli	s4,s4,0x20
ffffffffc02011fe:	9a3e                	add	s4,s4,a5
}
ffffffffc0201200:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201202:	000a4503          	lbu	a0,0(s4)
}
ffffffffc0201206:	70a2                	ld	ra,40(sp)
ffffffffc0201208:	69a2                	ld	s3,8(sp)
ffffffffc020120a:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020120c:	85ca                	mv	a1,s2
ffffffffc020120e:	87a6                	mv	a5,s1
}
ffffffffc0201210:	6942                	ld	s2,16(sp)
ffffffffc0201212:	64e2                	ld	s1,24(sp)
ffffffffc0201214:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201216:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0201218:	03065633          	divu	a2,a2,a6
ffffffffc020121c:	8722                	mv	a4,s0
ffffffffc020121e:	f9bff0ef          	jal	ra,ffffffffc02011b8 <printnum>
ffffffffc0201222:	b7f9                	j	ffffffffc02011f0 <printnum+0x38>

ffffffffc0201224 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0201224:	7119                	addi	sp,sp,-128
ffffffffc0201226:	f4a6                	sd	s1,104(sp)
ffffffffc0201228:	f0ca                	sd	s2,96(sp)
ffffffffc020122a:	ecce                	sd	s3,88(sp)
ffffffffc020122c:	e8d2                	sd	s4,80(sp)
ffffffffc020122e:	e4d6                	sd	s5,72(sp)
ffffffffc0201230:	e0da                	sd	s6,64(sp)
ffffffffc0201232:	fc5e                	sd	s7,56(sp)
ffffffffc0201234:	f06a                	sd	s10,32(sp)
ffffffffc0201236:	fc86                	sd	ra,120(sp)
ffffffffc0201238:	f8a2                	sd	s0,112(sp)
ffffffffc020123a:	f862                	sd	s8,48(sp)
ffffffffc020123c:	f466                	sd	s9,40(sp)
ffffffffc020123e:	ec6e                	sd	s11,24(sp)
ffffffffc0201240:	892a                	mv	s2,a0
ffffffffc0201242:	84ae                	mv	s1,a1
ffffffffc0201244:	8d32                	mv	s10,a2
ffffffffc0201246:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201248:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc020124c:	5b7d                	li	s6,-1
ffffffffc020124e:	00001a97          	auipc	s5,0x1
ffffffffc0201252:	b5ea8a93          	addi	s5,s5,-1186 # ffffffffc0201dac <best_fit_pmm_manager+0x1b4>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201256:	00001b97          	auipc	s7,0x1
ffffffffc020125a:	d32b8b93          	addi	s7,s7,-718 # ffffffffc0201f88 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc020125e:	000d4503          	lbu	a0,0(s10)
ffffffffc0201262:	001d0413          	addi	s0,s10,1
ffffffffc0201266:	01350a63          	beq	a0,s3,ffffffffc020127a <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc020126a:	c121                	beqz	a0,ffffffffc02012aa <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc020126c:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc020126e:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc0201270:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201272:	fff44503          	lbu	a0,-1(s0)
ffffffffc0201276:	ff351ae3          	bne	a0,s3,ffffffffc020126a <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020127a:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc020127e:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc0201282:	4c81                	li	s9,0
ffffffffc0201284:	4881                	li	a7,0
        width = precision = -1;
ffffffffc0201286:	5c7d                	li	s8,-1
ffffffffc0201288:	5dfd                	li	s11,-1
ffffffffc020128a:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc020128e:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201290:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0201294:	0ff5f593          	zext.b	a1,a1
ffffffffc0201298:	00140d13          	addi	s10,s0,1
ffffffffc020129c:	04b56263          	bltu	a0,a1,ffffffffc02012e0 <vprintfmt+0xbc>
ffffffffc02012a0:	058a                	slli	a1,a1,0x2
ffffffffc02012a2:	95d6                	add	a1,a1,s5
ffffffffc02012a4:	4194                	lw	a3,0(a1)
ffffffffc02012a6:	96d6                	add	a3,a3,s5
ffffffffc02012a8:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc02012aa:	70e6                	ld	ra,120(sp)
ffffffffc02012ac:	7446                	ld	s0,112(sp)
ffffffffc02012ae:	74a6                	ld	s1,104(sp)
ffffffffc02012b0:	7906                	ld	s2,96(sp)
ffffffffc02012b2:	69e6                	ld	s3,88(sp)
ffffffffc02012b4:	6a46                	ld	s4,80(sp)
ffffffffc02012b6:	6aa6                	ld	s5,72(sp)
ffffffffc02012b8:	6b06                	ld	s6,64(sp)
ffffffffc02012ba:	7be2                	ld	s7,56(sp)
ffffffffc02012bc:	7c42                	ld	s8,48(sp)
ffffffffc02012be:	7ca2                	ld	s9,40(sp)
ffffffffc02012c0:	7d02                	ld	s10,32(sp)
ffffffffc02012c2:	6de2                	ld	s11,24(sp)
ffffffffc02012c4:	6109                	addi	sp,sp,128
ffffffffc02012c6:	8082                	ret
            padc = '0';
ffffffffc02012c8:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc02012ca:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02012ce:	846a                	mv	s0,s10
ffffffffc02012d0:	00140d13          	addi	s10,s0,1
ffffffffc02012d4:	fdd6059b          	addiw	a1,a2,-35
ffffffffc02012d8:	0ff5f593          	zext.b	a1,a1
ffffffffc02012dc:	fcb572e3          	bgeu	a0,a1,ffffffffc02012a0 <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc02012e0:	85a6                	mv	a1,s1
ffffffffc02012e2:	02500513          	li	a0,37
ffffffffc02012e6:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc02012e8:	fff44783          	lbu	a5,-1(s0)
ffffffffc02012ec:	8d22                	mv	s10,s0
ffffffffc02012ee:	f73788e3          	beq	a5,s3,ffffffffc020125e <vprintfmt+0x3a>
ffffffffc02012f2:	ffed4783          	lbu	a5,-2(s10)
ffffffffc02012f6:	1d7d                	addi	s10,s10,-1
ffffffffc02012f8:	ff379de3          	bne	a5,s3,ffffffffc02012f2 <vprintfmt+0xce>
ffffffffc02012fc:	b78d                	j	ffffffffc020125e <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc02012fe:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc0201302:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201306:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc0201308:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc020130c:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0201310:	02d86463          	bltu	a6,a3,ffffffffc0201338 <vprintfmt+0x114>
                ch = *fmt;
ffffffffc0201314:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0201318:	002c169b          	slliw	a3,s8,0x2
ffffffffc020131c:	0186873b          	addw	a4,a3,s8
ffffffffc0201320:	0017171b          	slliw	a4,a4,0x1
ffffffffc0201324:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc0201326:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc020132a:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc020132c:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc0201330:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0201334:	fed870e3          	bgeu	a6,a3,ffffffffc0201314 <vprintfmt+0xf0>
            if (width < 0)
ffffffffc0201338:	f40ddce3          	bgez	s11,ffffffffc0201290 <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc020133c:	8de2                	mv	s11,s8
ffffffffc020133e:	5c7d                	li	s8,-1
ffffffffc0201340:	bf81                	j	ffffffffc0201290 <vprintfmt+0x6c>
            if (width < 0)
ffffffffc0201342:	fffdc693          	not	a3,s11
ffffffffc0201346:	96fd                	srai	a3,a3,0x3f
ffffffffc0201348:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020134c:	00144603          	lbu	a2,1(s0)
ffffffffc0201350:	2d81                	sext.w	s11,s11
ffffffffc0201352:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201354:	bf35                	j	ffffffffc0201290 <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc0201356:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020135a:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc020135e:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201360:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc0201362:	bfd9                	j	ffffffffc0201338 <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc0201364:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201366:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc020136a:	01174463          	blt	a4,a7,ffffffffc0201372 <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc020136e:	1a088e63          	beqz	a7,ffffffffc020152a <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc0201372:	000a3603          	ld	a2,0(s4)
ffffffffc0201376:	46c1                	li	a3,16
ffffffffc0201378:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc020137a:	2781                	sext.w	a5,a5
ffffffffc020137c:	876e                	mv	a4,s11
ffffffffc020137e:	85a6                	mv	a1,s1
ffffffffc0201380:	854a                	mv	a0,s2
ffffffffc0201382:	e37ff0ef          	jal	ra,ffffffffc02011b8 <printnum>
            break;
ffffffffc0201386:	bde1                	j	ffffffffc020125e <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc0201388:	000a2503          	lw	a0,0(s4)
ffffffffc020138c:	85a6                	mv	a1,s1
ffffffffc020138e:	0a21                	addi	s4,s4,8
ffffffffc0201390:	9902                	jalr	s2
            break;
ffffffffc0201392:	b5f1                	j	ffffffffc020125e <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0201394:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201396:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc020139a:	01174463          	blt	a4,a7,ffffffffc02013a2 <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc020139e:	18088163          	beqz	a7,ffffffffc0201520 <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc02013a2:	000a3603          	ld	a2,0(s4)
ffffffffc02013a6:	46a9                	li	a3,10
ffffffffc02013a8:	8a2e                	mv	s4,a1
ffffffffc02013aa:	bfc1                	j	ffffffffc020137a <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02013ac:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc02013b0:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02013b2:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02013b4:	bdf1                	j	ffffffffc0201290 <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc02013b6:	85a6                	mv	a1,s1
ffffffffc02013b8:	02500513          	li	a0,37
ffffffffc02013bc:	9902                	jalr	s2
            break;
ffffffffc02013be:	b545                	j	ffffffffc020125e <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02013c0:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc02013c4:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02013c6:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02013c8:	b5e1                	j	ffffffffc0201290 <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc02013ca:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02013cc:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc02013d0:	01174463          	blt	a4,a7,ffffffffc02013d8 <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc02013d4:	14088163          	beqz	a7,ffffffffc0201516 <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc02013d8:	000a3603          	ld	a2,0(s4)
ffffffffc02013dc:	46a1                	li	a3,8
ffffffffc02013de:	8a2e                	mv	s4,a1
ffffffffc02013e0:	bf69                	j	ffffffffc020137a <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc02013e2:	03000513          	li	a0,48
ffffffffc02013e6:	85a6                	mv	a1,s1
ffffffffc02013e8:	e03e                	sd	a5,0(sp)
ffffffffc02013ea:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc02013ec:	85a6                	mv	a1,s1
ffffffffc02013ee:	07800513          	li	a0,120
ffffffffc02013f2:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc02013f4:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc02013f6:	6782                	ld	a5,0(sp)
ffffffffc02013f8:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc02013fa:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc02013fe:	bfb5                	j	ffffffffc020137a <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201400:	000a3403          	ld	s0,0(s4)
ffffffffc0201404:	008a0713          	addi	a4,s4,8
ffffffffc0201408:	e03a                	sd	a4,0(sp)
ffffffffc020140a:	14040263          	beqz	s0,ffffffffc020154e <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc020140e:	0fb05763          	blez	s11,ffffffffc02014fc <vprintfmt+0x2d8>
ffffffffc0201412:	02d00693          	li	a3,45
ffffffffc0201416:	0cd79163          	bne	a5,a3,ffffffffc02014d8 <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020141a:	00044783          	lbu	a5,0(s0)
ffffffffc020141e:	0007851b          	sext.w	a0,a5
ffffffffc0201422:	cf85                	beqz	a5,ffffffffc020145a <vprintfmt+0x236>
ffffffffc0201424:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201428:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020142c:	000c4563          	bltz	s8,ffffffffc0201436 <vprintfmt+0x212>
ffffffffc0201430:	3c7d                	addiw	s8,s8,-1
ffffffffc0201432:	036c0263          	beq	s8,s6,ffffffffc0201456 <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc0201436:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201438:	0e0c8e63          	beqz	s9,ffffffffc0201534 <vprintfmt+0x310>
ffffffffc020143c:	3781                	addiw	a5,a5,-32
ffffffffc020143e:	0ef47b63          	bgeu	s0,a5,ffffffffc0201534 <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc0201442:	03f00513          	li	a0,63
ffffffffc0201446:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201448:	000a4783          	lbu	a5,0(s4)
ffffffffc020144c:	3dfd                	addiw	s11,s11,-1
ffffffffc020144e:	0a05                	addi	s4,s4,1
ffffffffc0201450:	0007851b          	sext.w	a0,a5
ffffffffc0201454:	ffe1                	bnez	a5,ffffffffc020142c <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc0201456:	01b05963          	blez	s11,ffffffffc0201468 <vprintfmt+0x244>
ffffffffc020145a:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc020145c:	85a6                	mv	a1,s1
ffffffffc020145e:	02000513          	li	a0,32
ffffffffc0201462:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0201464:	fe0d9be3          	bnez	s11,ffffffffc020145a <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201468:	6a02                	ld	s4,0(sp)
ffffffffc020146a:	bbd5                	j	ffffffffc020125e <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc020146c:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc020146e:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc0201472:	01174463          	blt	a4,a7,ffffffffc020147a <vprintfmt+0x256>
    else if (lflag) {
ffffffffc0201476:	08088d63          	beqz	a7,ffffffffc0201510 <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc020147a:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc020147e:	0a044d63          	bltz	s0,ffffffffc0201538 <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc0201482:	8622                	mv	a2,s0
ffffffffc0201484:	8a66                	mv	s4,s9
ffffffffc0201486:	46a9                	li	a3,10
ffffffffc0201488:	bdcd                	j	ffffffffc020137a <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc020148a:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc020148e:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc0201490:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc0201492:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc0201496:	8fb5                	xor	a5,a5,a3
ffffffffc0201498:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc020149c:	02d74163          	blt	a4,a3,ffffffffc02014be <vprintfmt+0x29a>
ffffffffc02014a0:	00369793          	slli	a5,a3,0x3
ffffffffc02014a4:	97de                	add	a5,a5,s7
ffffffffc02014a6:	639c                	ld	a5,0(a5)
ffffffffc02014a8:	cb99                	beqz	a5,ffffffffc02014be <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc02014aa:	86be                	mv	a3,a5
ffffffffc02014ac:	00001617          	auipc	a2,0x1
ffffffffc02014b0:	8fc60613          	addi	a2,a2,-1796 # ffffffffc0201da8 <best_fit_pmm_manager+0x1b0>
ffffffffc02014b4:	85a6                	mv	a1,s1
ffffffffc02014b6:	854a                	mv	a0,s2
ffffffffc02014b8:	0ce000ef          	jal	ra,ffffffffc0201586 <printfmt>
ffffffffc02014bc:	b34d                	j	ffffffffc020125e <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc02014be:	00001617          	auipc	a2,0x1
ffffffffc02014c2:	8da60613          	addi	a2,a2,-1830 # ffffffffc0201d98 <best_fit_pmm_manager+0x1a0>
ffffffffc02014c6:	85a6                	mv	a1,s1
ffffffffc02014c8:	854a                	mv	a0,s2
ffffffffc02014ca:	0bc000ef          	jal	ra,ffffffffc0201586 <printfmt>
ffffffffc02014ce:	bb41                	j	ffffffffc020125e <vprintfmt+0x3a>
                p = "(null)";
ffffffffc02014d0:	00001417          	auipc	s0,0x1
ffffffffc02014d4:	8c040413          	addi	s0,s0,-1856 # ffffffffc0201d90 <best_fit_pmm_manager+0x198>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02014d8:	85e2                	mv	a1,s8
ffffffffc02014da:	8522                	mv	a0,s0
ffffffffc02014dc:	e43e                	sd	a5,8(sp)
ffffffffc02014de:	0fc000ef          	jal	ra,ffffffffc02015da <strnlen>
ffffffffc02014e2:	40ad8dbb          	subw	s11,s11,a0
ffffffffc02014e6:	01b05b63          	blez	s11,ffffffffc02014fc <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc02014ea:	67a2                	ld	a5,8(sp)
ffffffffc02014ec:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02014f0:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc02014f2:	85a6                	mv	a1,s1
ffffffffc02014f4:	8552                	mv	a0,s4
ffffffffc02014f6:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02014f8:	fe0d9ce3          	bnez	s11,ffffffffc02014f0 <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02014fc:	00044783          	lbu	a5,0(s0)
ffffffffc0201500:	00140a13          	addi	s4,s0,1
ffffffffc0201504:	0007851b          	sext.w	a0,a5
ffffffffc0201508:	d3a5                	beqz	a5,ffffffffc0201468 <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc020150a:	05e00413          	li	s0,94
ffffffffc020150e:	bf39                	j	ffffffffc020142c <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc0201510:	000a2403          	lw	s0,0(s4)
ffffffffc0201514:	b7ad                	j	ffffffffc020147e <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc0201516:	000a6603          	lwu	a2,0(s4)
ffffffffc020151a:	46a1                	li	a3,8
ffffffffc020151c:	8a2e                	mv	s4,a1
ffffffffc020151e:	bdb1                	j	ffffffffc020137a <vprintfmt+0x156>
ffffffffc0201520:	000a6603          	lwu	a2,0(s4)
ffffffffc0201524:	46a9                	li	a3,10
ffffffffc0201526:	8a2e                	mv	s4,a1
ffffffffc0201528:	bd89                	j	ffffffffc020137a <vprintfmt+0x156>
ffffffffc020152a:	000a6603          	lwu	a2,0(s4)
ffffffffc020152e:	46c1                	li	a3,16
ffffffffc0201530:	8a2e                	mv	s4,a1
ffffffffc0201532:	b5a1                	j	ffffffffc020137a <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc0201534:	9902                	jalr	s2
ffffffffc0201536:	bf09                	j	ffffffffc0201448 <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc0201538:	85a6                	mv	a1,s1
ffffffffc020153a:	02d00513          	li	a0,45
ffffffffc020153e:	e03e                	sd	a5,0(sp)
ffffffffc0201540:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0201542:	6782                	ld	a5,0(sp)
ffffffffc0201544:	8a66                	mv	s4,s9
ffffffffc0201546:	40800633          	neg	a2,s0
ffffffffc020154a:	46a9                	li	a3,10
ffffffffc020154c:	b53d                	j	ffffffffc020137a <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc020154e:	03b05163          	blez	s11,ffffffffc0201570 <vprintfmt+0x34c>
ffffffffc0201552:	02d00693          	li	a3,45
ffffffffc0201556:	f6d79de3          	bne	a5,a3,ffffffffc02014d0 <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc020155a:	00001417          	auipc	s0,0x1
ffffffffc020155e:	83640413          	addi	s0,s0,-1994 # ffffffffc0201d90 <best_fit_pmm_manager+0x198>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201562:	02800793          	li	a5,40
ffffffffc0201566:	02800513          	li	a0,40
ffffffffc020156a:	00140a13          	addi	s4,s0,1
ffffffffc020156e:	bd6d                	j	ffffffffc0201428 <vprintfmt+0x204>
ffffffffc0201570:	00001a17          	auipc	s4,0x1
ffffffffc0201574:	821a0a13          	addi	s4,s4,-2015 # ffffffffc0201d91 <best_fit_pmm_manager+0x199>
ffffffffc0201578:	02800513          	li	a0,40
ffffffffc020157c:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201580:	05e00413          	li	s0,94
ffffffffc0201584:	b565                	j	ffffffffc020142c <vprintfmt+0x208>

ffffffffc0201586 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201586:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0201588:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc020158c:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc020158e:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201590:	ec06                	sd	ra,24(sp)
ffffffffc0201592:	f83a                	sd	a4,48(sp)
ffffffffc0201594:	fc3e                	sd	a5,56(sp)
ffffffffc0201596:	e0c2                	sd	a6,64(sp)
ffffffffc0201598:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc020159a:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc020159c:	c89ff0ef          	jal	ra,ffffffffc0201224 <vprintfmt>
}
ffffffffc02015a0:	60e2                	ld	ra,24(sp)
ffffffffc02015a2:	6161                	addi	sp,sp,80
ffffffffc02015a4:	8082                	ret

ffffffffc02015a6 <sbi_console_putchar>:
uint64_t SBI_REMOTE_SFENCE_VMA_ASID = 7;
uint64_t SBI_SHUTDOWN = 8;

uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
    uint64_t ret_val;
    __asm__ volatile (
ffffffffc02015a6:	4781                	li	a5,0
ffffffffc02015a8:	00004717          	auipc	a4,0x4
ffffffffc02015ac:	a6873703          	ld	a4,-1432(a4) # ffffffffc0205010 <SBI_CONSOLE_PUTCHAR>
ffffffffc02015b0:	88ba                	mv	a7,a4
ffffffffc02015b2:	852a                	mv	a0,a0
ffffffffc02015b4:	85be                	mv	a1,a5
ffffffffc02015b6:	863e                	mv	a2,a5
ffffffffc02015b8:	00000073          	ecall
ffffffffc02015bc:	87aa                	mv	a5,a0
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}
ffffffffc02015be:	8082                	ret

ffffffffc02015c0 <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc02015c0:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc02015c4:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc02015c6:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc02015c8:	cb81                	beqz	a5,ffffffffc02015d8 <strlen+0x18>
        cnt ++;
ffffffffc02015ca:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc02015cc:	00a707b3          	add	a5,a4,a0
ffffffffc02015d0:	0007c783          	lbu	a5,0(a5)
ffffffffc02015d4:	fbfd                	bnez	a5,ffffffffc02015ca <strlen+0xa>
ffffffffc02015d6:	8082                	ret
    }
    return cnt;
}
ffffffffc02015d8:	8082                	ret

ffffffffc02015da <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc02015da:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc02015dc:	e589                	bnez	a1,ffffffffc02015e6 <strnlen+0xc>
ffffffffc02015de:	a811                	j	ffffffffc02015f2 <strnlen+0x18>
        cnt ++;
ffffffffc02015e0:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc02015e2:	00f58863          	beq	a1,a5,ffffffffc02015f2 <strnlen+0x18>
ffffffffc02015e6:	00f50733          	add	a4,a0,a5
ffffffffc02015ea:	00074703          	lbu	a4,0(a4)
ffffffffc02015ee:	fb6d                	bnez	a4,ffffffffc02015e0 <strnlen+0x6>
ffffffffc02015f0:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc02015f2:	852e                	mv	a0,a1
ffffffffc02015f4:	8082                	ret

ffffffffc02015f6 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02015f6:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02015fa:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02015fe:	cb89                	beqz	a5,ffffffffc0201610 <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc0201600:	0505                	addi	a0,a0,1
ffffffffc0201602:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201604:	fee789e3          	beq	a5,a4,ffffffffc02015f6 <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201608:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc020160c:	9d19                	subw	a0,a0,a4
ffffffffc020160e:	8082                	ret
ffffffffc0201610:	4501                	li	a0,0
ffffffffc0201612:	bfed                	j	ffffffffc020160c <strcmp+0x16>

ffffffffc0201614 <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201614:	c20d                	beqz	a2,ffffffffc0201636 <strncmp+0x22>
ffffffffc0201616:	962e                	add	a2,a2,a1
ffffffffc0201618:	a031                	j	ffffffffc0201624 <strncmp+0x10>
        n --, s1 ++, s2 ++;
ffffffffc020161a:	0505                	addi	a0,a0,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc020161c:	00e79a63          	bne	a5,a4,ffffffffc0201630 <strncmp+0x1c>
ffffffffc0201620:	00b60b63          	beq	a2,a1,ffffffffc0201636 <strncmp+0x22>
ffffffffc0201624:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc0201628:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc020162a:	fff5c703          	lbu	a4,-1(a1)
ffffffffc020162e:	f7f5                	bnez	a5,ffffffffc020161a <strncmp+0x6>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201630:	40e7853b          	subw	a0,a5,a4
}
ffffffffc0201634:	8082                	ret
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201636:	4501                	li	a0,0
ffffffffc0201638:	8082                	ret

ffffffffc020163a <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc020163a:	ca01                	beqz	a2,ffffffffc020164a <memset+0x10>
ffffffffc020163c:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc020163e:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0201640:	0785                	addi	a5,a5,1
ffffffffc0201642:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0201646:	fec79de3          	bne	a5,a2,ffffffffc0201640 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc020164a:	8082                	ret
