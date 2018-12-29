.code16						# Produce 16-Bit Code (For Real Mode).

.section .text				# Make our function globally available.

.global init0				# Make our function globally available.
.global boot0				# Make our function globally available.

init0:						# init0 function
	ljmp $0x07C0, $boot0    # [CS : IP] Set CS to 0x07C0, the adress
							# where BIOSes interrupt 0x19 puts the first
							# sector of the bootable media and jumps to
							# it. We make a jmp instruction right at the
							# start of our bootloader code in order to fix
							# strange BIOS behaviours that imply strange
							# CS : IP patterns, such as an inverted one
							# 0 : 0x07C0; that way, we're not making any
							# assumptions that could result in some undefined
							# errors on some picky computers that have those
							# types of patterns.
							# Starting our code with a jump instruction, also
							# makes it compatible with very old Compaq computers
							# that instead of searching for 0xAA55 MBR signature
							# at the end of the first sector of the bootable media,
							# looks for a jump instruction on the first bytes of it.

boot0:						# boot0 function
							# Note: We'll be avoiding FS and GS registers in order to
							# make our bootloader as compatible as we can.
							# Thoose 2 registers were added to 80386+ CPU's.
	mov $0x07C0, %ax		# Move 0x07C0 to ax.
	mov %ax, %ds			# Move 0x07C0 to the data segment register.
	mov $0x8000, %bx		# Move 0x8000 to bx.
	cli						# Disable interrupts to circumvent a bug present on
							# early 8088 CPU's.
	mov %bx, %ss			# Move 0x8000 to the stack segment.
	xor %ax, %ax			# Xor'ing ax to ax, results in a 0, as xor'ing two
							# registers that contain the same, will always result in 0.
	mov %ax, %sp			# Move ax (Which now is 0) to the stack pointer register.
							# Stack Dissasembly:
							# Top stack adress:		-> 0x8000
							# Bottom stack adress:	-> 0x8FFF
	sti						# Re-enable interrupts
	cld						# CLD sets EFLAG's register DF flag to 0, this way, string
							# operations increment the segment registers (Such as SI & DI).
							# Invoking a CLD instruction, also makes us aware of the DF's flag
							# contents, in order to make 0 assumptions on how the BIOS leaves this value.
	mov $0, %dl
	mov $2, %ah
	mov $1, %al
	mov $0, %ch
	mov $0, %dh
	mov $2, %cl
	mov $0, %dl
	mov $0x1000, %bx
	mov %bx, %es
	mov $0x0, %bx
	int $0x13
	ljmp $0x1000, $0x0

.fill 510-(.-init0), 1, 0	# Preprocessor directive from GNU as that fills 'x'
								# count of bytes, with a 'y' size that has 'z' value.
								# args: count, size, value

.word 0xaa55					# BIOS 2-byte magic number that enables the proper
								# booting of this bootloader
