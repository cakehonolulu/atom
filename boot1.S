.code16

.global init1

.section .text

init1:
	mov $0x2, %ah
	mov $0x1, %dh
	mov $0x0, %dl
	mov $0x0, %bh
	int $0x10
	call boot1LoadedMessage
	mov $0x2, %ah
	mov $0x2, %dh
	mov $0x0, %dl
	mov $0x0, %bh
	int $0x10
	call boot1EnableA20
	mov $0x2, %ah
	mov $0x3, %dh
	mov $0x0, %dl
	mov $0x0, %bh
	int $0x10
	call boot1LoadGDT
	cli
	mov %cr0, %eax
	or $1, %eax
	mov %eax, %cr0
	hlt

boot1EnableA20:
	call boot1CheckA20LineState			# Check if A20 Line is enabled.
	jnz .boot1A20HasBeenEnabled			# Jump if condition is met.

	movw $0x2401, %ax					# Enable A20 Line using the BIOS Method.
	stc									# Set carry flag.
	int	$0x15							# Call BIOS interrupt 15 (Enable A20 Line).
	jc 1f								# BIOS Method failed.
	testb %ah, %ah						# Compares both registers.
	jne 1f								# Jumps if they're not equal.
	call boot1CheckA20LineState			# Check if A20 Line is enabled.
	jnz .boot1A20HasBeenEnabled			# Jump if condition is met.
1:										# Enable A20 Line using Intel's 8042 Controller Method.
	call .boot1_8042_wait				# Wait for Intel's 8042 controller to be ready.
	movb $0xd1, %al						# Prepare the 8042 port write.
	outb %al, $0x64						# Write to the 8042 port.
	call .boot1_8042_wait				# Wait for Intel's 8042 controller to be ready.
	movb $0xdf, %al						# Prepare the 8042 port write.
	outb %al, $0x60						# Enable A20 Line.
	call .boot1_8042_wait				# Wait for Intel's 8042 controller to be ready.
	call boot1CheckA20LineState			# Check if A20 Line is enabled.
	jnz	.boot1A20HasBeenEnabled			# Jump if condition is met.
										# Enable A20 Line using the 'Fast' Method.
	inb $0x92, %al						# Try the computer's Fast A20 Gate.
	testb $0x02, %al 					# Compare both values.
	jnz 1f								# Don't enable A20 if it's already set.
	orb $0x02, %al						# Check wether the A20 Gate Enable Bit...
	andb $0xfe, %al						# ...is set or not.
	outb %al, $0x92						# Enable the A20 Line using the Fast Gate.
1:
	call boot1CheckA20LineState			# Check if A20 Line is enabled.
	jnz .boot1A20HasBeenEnabled			# Jump if condition is met.
	jmp 1b								# Check until A20 Line is set.

.boot1_8042_wait:						# Function that waits for Intel's 8042 controller to be ready.
	inb	$0x64, %al						# Read 8042's status.
	testb $0x02, %al					# Test if bit 1 is zero.
	jnz .boot1_8042_wait				# Jump if condition is met.
	ret									# Return to parent function.

boot1CheckA20LineState:
	pushw %ds
	pushw %es
	xorw %ax, %ax
	movw %ax, %ds
	movw $0x200, %si
	decw %ax
	movw %ax, %es
	movw $0x210, %di
	movw %ax, %cx
	movw (%si), %ax
	pushw %ax
1:
	incw %ax
	movw %ax, %es:(%di)
	cmpw %ax, (%si)
	loope 1b
	popw (%si)
	popw %es
	popw %ds
	ret

boot1LoadGDT:
	cli
	pusha
	lgdt gdt
	sti
	popa
	call boot1LoadedGDTMessage
	ret

#define	CODE_SEG	gdt_code - gdt_start
#define	DATA_SEG	gdt_data - gdt_start

gdt_start:

gdt_null:
	.long 0
	.long 0

gdt_code:
	.word 0xffff
	.word 0x0
	.byte 0x0
	.byte 0b10011010
	.byte 0b11001111
	.byte 0x0

gdt_data:
	.word 0xffff
	.word 0x0
	.byte 0x0
	.byte 0b10010010
	.byte 0b11001111
	.byte 0x0

gdt_end:

gdt:
	.word (gdt_end - gdt_start - 1)
	.long gdt_start

.boot1A20HasBeenEnabled:
	movb $'A', %al
	movb $0x0e, %ah
	int  $0x10
	movb $'2', %al
	movb $0x0e, %ah
	int  $0x10
	movb $'0', %al
	movb $0x0e, %ah
	int  $0x10
	movb $' ', %al
	movb $0x0e, %ah
	int  $0x10
	movb $'L', %al
	movb $0x0e, %ah
	int  $0x10
	movb $'i', %al
	movb $0x0e, %ah
	int  $0x10
	movb $'n', %al
	movb $0x0e, %ah
	int  $0x10
	movb $'e', %al
	movb $0x0e, %ah
	int  $0x10
	movb $' ', %al
	movb $0x0e, %ah
	int  $0x10
	movb $'E', %al
	movb $0x0e, %ah
	int  $0x10
	movb $'n', %al
	movb $0x0e, %ah
	int  $0x10
	movb $'a', %al
	movb $0x0e, %ah
	int  $0x10
	movb $'b', %al
	movb $0x0e, %ah
	int  $0x10
	movb $'l', %al
	movb $0x0e, %ah
	int  $0x10
	movb $'e', %al
	movb $0x0e, %ah
	int  $0x10
	movb $'d', %al
	movb $0x0e, %ah
	int  $0x10
	movb $'\n', %al
	ret

boot1LoadedMessage:
	movb $'E', %al
	movb $0x0e, %ah
	int  $0x10
	movb $'n', %al
	movb $0x0e, %ah
	int  $0x10
	movb $'t', %al
	movb $0x0e, %ah
	int  $0x10
	movb $'e', %al
	movb $0x0e, %ah
	int  $0x10
	movb $'r', %al
	movb $0x0e, %ah
	int  $0x10
	movb $'e', %al
	movb $0x0e, %ah
	int  $0x10
	movb $'d', %al
	movb $0x0e, %ah
	int  $0x10
	movb $' ', %al
	movb $0x0e, %ah
	int  $0x10
	movb $'2', %al
	movb $0x0e, %ah
	int  $0x10
	movb $'n', %al
	movb $0x0e, %ah
	int  $0x10
	movb $'d', %al
	movb $0x0e, %ah
	int  $0x10
	movb $' ', %al
	movb $0x0e, %ah
	int  $0x10
	movb $'s', %al
	movb $0x0e, %ah
	int  $0x10
	movb $'t', %al
	movb $0x0e, %ah
	int  $0x10
	movb $'a', %al
	movb $0x0e, %ah
	int  $0x10
	movb $'g', %al
	movb $0x0e, %ah
	int  $0x10
	movb $'e', %al
	movb $0x0e, %ah
	int  $0x10
	movb $'\n', %al
	movb $0x0e, %ah
	int  $0x10
	ret

boot1LoadedGDTMessage:
	movb $'G', %al
	movb $0x0e, %ah
	int  $0x10
	movb $'D', %al
	movb $0x0e, %ah
	int  $0x10
	movb $'T', %al
	movb $0x0e, %ah
	int  $0x10
	movb $' ', %al
	movb $0x0e, %ah
	int  $0x10
	movb $'L', %al
	movb $0x0e, %ah
	int  $0x10
	movb $'o', %al
	movb $0x0e, %ah
	int  $0x10
	movb $'a', %al
	movb $0x0e, %ah
	int  $0x10
	movb $'d', %al
	movb $0x0e, %ah
	int  $0x10
	movb $'e', %al
	movb $0x0e, %ah
	int  $0x10
	movb $'d', %al
	movb $0x0e, %ah
	int  $0x10
	ret
