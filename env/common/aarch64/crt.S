.include "macros.s"
.include "constants.s"

	/*
	 * mov_q - move an immediate constant into a 64-bit register using
	 *         between 2 and 4 movz/movk instructions (depending on the
	 *         magnitude and sign of the operand)
	 */
	.macro	mov_q, reg, val
	.if (((\val) >> 31) == 0 || ((\val) >> 31) == 0x1ffffffff)
	movz	\reg, :abs_g1_s:\val
	.else
	.if (((\val) >> 47) == 0 || ((\val) >> 47) == 0x1ffff)
	movz	\reg, :abs_g2_s:\val
	.else
	movz	\reg, :abs_g3:\val
	movk	\reg, :abs_g2_nc:\val
	.endif
	movk	\reg, :abs_g1_nc:\val
	.endif
	movk	\reg, :abs_g0_nc:\val
	.endm

#define BOOT_CPU_MODE_EL1	(0xe11)
#define BOOT_CPU_MODE_EL2	(0xe12)

/*
 * PSR bits
 */
#define PSR_MODE_EL0t	0x00000000
#define PSR_MODE_EL1t	0x00000004
#define PSR_MODE_EL1h	0x00000005
#define PSR_MODE_EL2t	0x00000008
#define PSR_MODE_EL2h	0x00000009
#define PSR_MODE_EL3t	0x0000000c
#define PSR_MODE_EL3h	0x0000000d
#define PSR_MODE_MASK	0x0000000f


/* AArch64 SPSR bits */
#define PSR_F_BIT	0x00000040
#define PSR_I_BIT	0x00000080
#define PSR_A_BIT	0x00000100
#define PSR_D_BIT	0x00000200
#define PSR_BTYPE_MASK	0x00000c00
#define PSR_SSBS_BIT	0x00001000
#define PSR_PAN_BIT	0x00400000
#define PSR_UAO_BIT	0x00800000
#define PSR_DIT_BIT	0x01000000
#define PSR_TCO_BIT	0x02000000
#define PSR_V_BIT	0x10000000
#define PSR_C_BIT	0x20000000
#define PSR_Z_BIT	0x40000000
#define PSR_N_BIT	0x80000000


/* Current Exception Level values, as contained in CurrentEL */
#define CurrentEL_EL1		(1 << 2)
#define CurrentEL_EL2		(2 << 2)

#define INIT_PSTATE_EL1 (PSR_D_BIT | PSR_A_BIT | PSR_I_BIT | PSR_F_BIT | PSR_MODE_EL1h)

#define BIT(nr)			(1 << (nr))

#define SCTLR_EL1_RES1	((BIT(11)) | (BIT(20)) | (BIT(22)) | (BIT(28)) | (BIT(29)))


#define INIT_SCTLR_EL1_MMU_OFF SCTLR_EL1_RES1

//#define QEMU_RAM_START		0x40000000
#define QEMU_RAM_START		0x00000000

#define R_AARCH64_RELATIV	0x403

	.macro	adr_l, dst, sym
	adrp	\dst, \sym
	add	\dst, \dst, :lo12:\sym
	.endm

#
# start of trap handler
#

	.section .text.init,"ax",@progbits
	.globl _start

_start:
	b	1f		// branch to kernel start, magic
	.long	0		// reserved
	.quad	0		// Image load offset from start of RAM, little-endian
	.quad	_bss_end - _start	// Effective size of kernel image, little-endian
	.quad	0		// Informative flags, little-endian
	.quad	0		// reserved
	.quad	0		// reserved
	.quad	0		// reserved
	.ascii	"ARM\x64"	// Magic number
	.long	0		// reserved
	1:	//b 1b
#if 0
	mrs	x21, CurrentEL
	cmp	x21, CurrentEL_EL1
	b.eq	1b
#endif

	//bl init_el1

	// etup trap vector

	// setup stack
	mov x0, xzr
	lsl x0, x0, STACK_SHIFT
	adr_l x1, stacks + STACK_SIZE
	msr sp_el0, x1
	msr spsel, 0

	bl relocate

	//bl uart_out

	// jump to libfemto_start_main
	b libfemto_start_main

park:
	wfi
	b       park

init_el1:
	mov_q	x0, INIT_SCTLR_EL1_MMU_OFF
	msr	sctlr_el1, x0
	isb
	mov_q	x0, INIT_PSTATE_EL1
	msr	spsr_el1, x0
	msr	elr_el1, lr
	mov	w0, #BOOT_CPU_MODE_EL1
	eret

relocate:
#if defined (__pic__) || defined (__pie__)
	/* Apply relocations */
	adr	x0, _rela_start
	adr	x1, _rela_end
	adr	x2, _text_start
	mov_q 	x3, QEMU_RAM_START
	sub	x2, x2, x3
0:
	cmp	x0, x1
	beq	1f
	ldp	x3, x4, [x0], #24
	ldr	x5, [x0, #-8]
	cmp	x4, #R_AARCH64_RELATIV
	bne	0b
	add	x5, x2, x5
	str	x5, [x2, x3]
	b	0b
1:
#endif
	ret

uart_out:
	mov x21, 0xfe660000
	mov w22, 'A'
	mov x19, 8
1:
	ldr w20, [x21, 20]
	tbz w20, 5, 1b
	str w22, [x21]
	sub x19, x19, 1
	cmp x19, 0
	b.ne 1b
	ret

	.bss
	.align 4
	.global stacks
stacks:
	.skip STACK_SIZE * MAX_HARTS
