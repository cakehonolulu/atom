# Thanks to Octocontrabass, Combuster and MichaelPetch for the help @ forum.osdev.org
.global init1

.code16

.section .data.init
/* Basic GDT. set-up for Unreal Mode, change descriptor 1 & 2 alongside 16->32 bit segment mode later on */
gdt_start:
gdt_null:
	.long 0
	.long 0
gdt_code:
	.word 0xFFFF
	.word 0x0
	.byte 0x0
	.byte 0b10011010
	.byte 0b10001111
	.byte 0x0

gdt_data:
	.word 0xffff
	.word 0x0
	.byte 0x0
	.byte 0b10010010
	.byte 0b10001111
	.byte 0x0

gdt_end:
.set GDT_CODE_SEGMENT, gdt_code - gdt_start
.set GDT_DATA_SEGMENT, gdt_data - gdt_start

gdt:
	.word (gdt_end - gdt_start - 1)
	.long gdt_start

.section .text.init

init1:
	mov $0x0600, %ax
	mov $0x0F, %bh
	
	mov $0x0000, %cx
	mov $0X184F, %dx
	
	int $0x10

	clc

	cli

	mov %cr0, %eax
	or $1, %eax
	mov %eax, %cr0

	mov $0b11001111, %al
	mov %al, (gdt_code + 6)										# We dynamically modify the GDT structure to try optimizing
	mov %al, (gdt_data + 6)										# the size, change both segment's bitmode to 32-bit.
	
	lgdt gdt
	
	ljmpl $GDT_CODE_SEGMENT, $boot1Start32

.code32

.extern stage2

boot1Start32:
	mov $GDT_DATA_SEGMENT, %ax
	mov %ax, %ds
	mov %ax, %es
	mov %ax, %ss
	mov $0x4000, %esp                 		# Set up a new stack pointer. Ferrum places it conveniently
	mov %esp, %ebp
													# below the EBDA area.
	call stage2
