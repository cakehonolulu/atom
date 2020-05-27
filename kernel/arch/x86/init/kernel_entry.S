.code32	# This just acts kind of a wrapper between the boot1 second stage bootloader
.section .kernel.entry
	call _bootstrap		# and just calls another assembly file where we can do a bunch more things.
	cli
	hlt

.section .text

.extern _kmain
.extern __bss_start
.extern __bss_sizel

.global _bootstrap

.type _bootstrap, @function
_bootstrap:
	movl $stack_top, %esp
	and $-8, %esp
    pushl %esp
    pushl $0
    popf

	xor %eax, %eax
	mov $__bss_sizel, %ecx
	mov $__bss_start, %edi
	rep stosl

	mov $0xA1B0516C, %eax
	push %eax
	
	call _kmain

	# If for some reason _kmain returns, hang indefinitely
	cli
1:	hlt
	jmp 1b

.section .bss
.align 8
stack_bottom:
.skip 8192 # 8 KiB
stack_top: