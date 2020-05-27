.code32				# This just acts kind of a wrapper between the boot1 second stage bootloader
.section .kernel.entry
	call _bootstrap	
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
	and $-16, %esp

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

.section .stack, "aw", @nobits
stack_bottom:
.skip 32768 # 32 KiB
stack_top: