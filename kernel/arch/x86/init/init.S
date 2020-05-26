.code32
.section .text
.extern _kmain
.global _bootstrap
.type _bootstrap, @function
_bootstrap:
	movl $stack_top, %esp
	call _kmain
	cli
	hlt

.section .bss
.align 16
stack_bottom:
.skip 16384 # 16 KiB
stack_top: