.code16						# Produce 16-Bit Code (For Real Mode).

.section .text				# Text section.

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
	xor %ax, %ax			# Xor'ing ax to ax, results in a 0, as xor'ing two registers with
							# the same value always results in 0.
	mov %ax, %ds			# Move 0x0 to the data segment register.
							# We null the data segment, because if we don't, it can overlap
							# with the code segment.
	mov %ax, %es			# Null extra segment too.
	mov $0x8000, %bx		# Move 0x8000 to bx.
	cli						# Disable interrupts to circumvent a bug present on
							# early 8088 CPU's.
	mov %bx, %ss			# Move 0x8000 to the stack segment.
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
boot0resetdrive:			# Function to reset floppy drive in order to ensure it's working correctly.
	mov		$0x00, %ah		# Set ah to 0 (AH=0x00 -> Reset Disk Function).
	mov		$0x00, %dl		# Set dl to 0 (DL=0x00 -> Disk Drive Number).
	int		$0x13			# Call BIOS interrupt 13.
	jc		boot0resetdrive	# If Carry Flag is set (CF=1) an error has ocurred, run the function again.

							# On this part we'll load our stage 2 bootloader onto 0x1000 and jump to it.
	mov $0x02, %ah			# Set ah to 2 (AH=0x02 -> Disk Read Function).
	mov $0x14, %al			# Set al to 14 (AL=0x14) -> Sectors to be readed.
	mov $0x00, %ch			# Set ch to 0 (CH=0x00) -> Track 0 of the drive.
	mov $0x02, %cl			# Set cl to 2 (CL=0x02) -> Sector of the drive from which we start reading from.
	mov $0x00, %dh			# Set dh to 0 (DH=0x00) -> Head 0 of the drive.
	mov $0x1000, %bx		# Set our bx register with the adress we'll jump to.
	mov %bx, %es			# Move bx onto our extra segment register to prepare the jump.
	int $0x13				# Call BIOS interrupt 13.
	ljmp $0x1000, $0x0 		# Long jump into our stage 2 bootloader. [0x1000:0x0] -> CS=0x1000; IP=0x0

.fill 510-(.-init0), 1, 0	# Preprocessor directive from GNU as that fills 'x'
							# count of bytes, with a 'y' size that has 'z' value.
							# args: count, size, value

.word 0xAA55				# BIOS 2-byte magic number that enables the proper
							# booting of this bootloader
