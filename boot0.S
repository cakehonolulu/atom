.code16								# Produce 16-Bit Code (For Real Mode).

.section .text						# Text section.

.global init0						# Make our function globally available.
.global boot0						# Make our function globally available.

init0:								# init0 function
	ljmp $0, $(boot0-init0+0x7c00)	# [CS : IP] We long jump to CS=0x0 and IP=boot0-init0+0x7c00,
									# where our bootloader starts. That way, we don't assume
									# segments which, on some computers can result in strange errors,
									# as BIOSes might set CS=0x7C00 and IP=0x0000 [ 0x7C00 = 0x0000 ]
									# and cause undefined behaviours on our code.
									# Starting our code with a jump instruction, also
									# makes it compatible with very old Compaq computers
									# that instead of searching for 0x55AA MBR signature
									# at the end of the first sector of the bootable media,
									# looks for a jump instruction on the first bytes of it.

boot0:								# boot0 function
									# Note: We'll be avoiding FS and GS registers in order to
									# make our bootloader as compatible as we can until we
									# reach 32-bits, where they are used and that, makes them uncompatible
									# with pre-80386+ processors.
									# Thoose 2 registers were added to 80386+ CPU's.
	xor %ax, %ax					# Xor'ing ax to ax, results in a 0, as xor'ing two registers with
									# the same value always results in 0.
	mov %ax, %ds					# Move 0x0 to the data segment register.
									# We null the data segment, because if we don't, it can overlap
									# with the code segment.
	mov %ax, %es					# Null extra segment too.
	mov $0x7C00, %bx				# Move 0x7C00 to bx.
	cli								# Disable interrupts to circumvent a bug present on
									# early 8088 CPU's.
	mov %ax, %ss					# Move ax (Which now is 0) to the stack segment register.
									# registers that contain the same, will always result in 0.
	mov %bx, %sp					# Set the stack pointer register with 0x7C00.
									# Stack Dissasembly:
									# Top stack adress:		-> 0x7C00
	mov %sp, %bp					# Move sp (Which now is 0x7C00) to the base pointer register.
	sti								# Re-enable interrupts
	cld								# CLD sets EFLAG's register DF flag to 0, this way, string
									# operations increment the segment registers (Such as SI & DI).
									# Invoking a CLD instruction, also makes us aware of the DF's flag
									# contents, in order to make 0 assumptions on how the BIOS leaves this value.
	mov $0x3, %ax					# Use VGA Text Mode
	int $0x10						# Call BIOS interrupt 13.

	call .boot0Loaded				# Call a function that displays a message on-screen.

	mov %dl, boot0bootdrive			# Store BIOS dl value containing the boot drive number.

boot0ResetDrive:					# Function to reset floppy drive in order to ensure it's working correctly.
	mov	$0x00, %ah					# Set ah to 0 (AH=0x00 -> Reset Disk Function).
	mov boot0bootdrive, %dl			# Move boot0bootdrive value back into dl.
	int	$0x13						# Call BIOS interrupt 13.
	jc boot0ResetDrive				# If Carry Flag is set (CF=1) an error has ocurred, run the function again.

									# On this part we'll load our stage 2 bootloader onto 0x1000 and jump to it.
	mov boot0bootdrive, %dl			# Move boot0bootdrive value back into dl in case INT13 messes with it.
	mov $0x02, %ah					# Set ah to 2 (AH=0x02 -> Disk Read Function).
	mov $0x14, %al					# Set al to 14 (AL=0x14) -> Sectors to be readed.
	mov $0x00, %ch					# Set ch to 0 (CH=0x00) -> Track 0 of the drive.
	mov $0x02, %cl					# Set cl to 2 (CL=0x02) -> Sector of the drive from which we start reading from.
	mov $0x00, %dh					# Set dh to 0 (DH=0x00) -> Head 0 of the drive.
	mov $0x1000, %bx				# Set our bx register with the adress we'll jump to.
	mov %bx, %es					# Move bx onto our extra segment register to prepare the jump.
	int $0x13						# Call BIOS interrupt 13.
	ljmp $0x1000, $0x0 				# Long jump into our stage 2 bootloader. [0x1000:0x0] -> CS=0x1000; IP=0x0
	cli
.hlt:
	hlt
	jmp .hlt

boot0print:
	mov $0x0E, %ah
.boot0printchar:
	lodsb
	cmp $0, %al
	je .boot0printdone
	int $0x10
	jmp .boot0printchar
.boot0printdone:
	ret

.boot0Loaded:
	mov $boot0LoadedMessage, %si
	call boot0print
	ret

boot0bootdrive: .byte 0
boot0LoadedMessage: .asciz "Entered 1st Stage"

.fill 510-(.-init0), 1, 0			# Preprocessor directive from GNU as that fills 'x'
									# count of bytes, with a 'y' size that has 'z' value.
									# args: count, size, value

.word 0xAA55						# BIOS 2-byte magic number that enables the proper
									# booting of this bootloader
