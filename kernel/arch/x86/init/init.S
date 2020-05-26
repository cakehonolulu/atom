.code32
.section .text
.extern _kmain
.global _bootstrap
.type _bootstrap, @function
_bootstrap:
	movl $stack_top, %esp
	and $-8, %esp
    pushl %esp
    pushl $0
    popf

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