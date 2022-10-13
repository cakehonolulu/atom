
.section .text.bootstrap

.extern stage2

.code32

.set GDT_DATA_SEGMENT, 0x10

.global bootstrap
bootstrap:
	mov $GDT_DATA_SEGMENT, %ax
	mov %ax, %ds
	mov %ax, %es
	mov %ax, %ss
	mov %ax, %es
	mov $0x1000, %ebp
	mov %ebp, %esp
    call stage2
