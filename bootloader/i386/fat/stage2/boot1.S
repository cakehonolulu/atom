# Thanks to Octocontrabass, Combuster and MichaelPetch for the help @ forum.osdev.org
.global boot1

.code32

.extern stage2

.set GDT_DATA_SEGMENT, 0x10

boot1:
	mov $GDT_DATA_SEGMENT, %ax
	mov %ax, %ds
	mov %ax, %es
	mov %ax, %ss
	mov %ax, %es
	mov $0x1000, %ebp                 		# Set up a new stack pointer. Ferrum places it conveniently
	mov %ebp, %esp
													# below the EBDA area.
	call stage2
