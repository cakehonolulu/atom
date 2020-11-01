.code16												# Produce 16-Bit Code (For Real Mode).

.extern I386_BOOT1_SIZE

.section .text										# Text section.

.set BOOT1_STARTING_SECTOR, 0x2						# This is a constant! It will always be the same!

.global init0										# Make our function globally available.
.global boot0										# Make our function globally available.
init0:												# init0 function
	ljmp $0, $boot0									# [CS : IP] We long jump to CS=0x0 and IP=boot0,
													# where our bootloader starts. That way, we don't assume
													# segments which, on some computers can result in strange errors,
													# as BIOSes might set CS=0x7C00 and IP=0x0000 [ 0x7C00 = 0x0000 ]
													# and cause undefined behaviours on our code.
													# Starting our code with a jump instruction, also
													# makes it compatible with very old Compaq computers
													# that instead of searching for 0x55AA MBR signature
													# at the end of the first sector of the bootable media,
													# looks for a jump instruction on the first bytes of it.
													# All of this, effectively sets Code Segment and Instruction Pointer
													# to the expected values by this bootloader that way it doesn't error out
													# on strange BIOS configurations that our code assumptions don't have in mind.

boot0:												# boot0 function
													# Note: We'll be avoiding FS and GS registers in order to
													# make our bootloader as compatible as we can until we
													# reach 32-bits, where they are used and that, makes them uncompatible
													# with pre-80386+ processors.
													# Thoose 2 registers were added to 80386+ CPU's.
	xor %ax, %ax									# Xor'ing ax to ax, results in a 0, as xor'ing two registers with
													# the same value always results in 0.
	mov %ax, %ds									# Move 0x0 to the data segment register.
													# We null the data segment, because if we don't, it can overlap
													# with the code segment.
	mov %ax, %es									# Null extra segment too.
	mov $0x5C00, %bx								# Move 0x5C00 to bx.
	cli												# Disable interrupts to circumvent a bug present on
													# early 8088 CPU's.
	mov %bx, %ss									# Move ax (Which now is 0) to the stack segment register.
													# registers that contain the same, will always result in 0.
	mov %ax, %sp									# Set the stack pointer register with 0x7C00.
													# Stack Dissasembly:
													# Top stack adress:		-> 0x7C00
	mov %sp, %bp									# Move sp (Which now is 0x7C00) to the base pointer register.
	sti												# Re-enable interrupts
	cld												# CLD sets EFLAG's register DF flag to 0, this way, string
													# operations increment the segment registers (Such as SI & DI).
													# Invoking a CLD instruction, also makes us aware of the DF's flag
													# contents, in order to make 0 assumptions on how the BIOS leaves this value.
	mov $0x3, %ax									# Use VGA Text Mode
	int $0x10										# Call BIOS interrupt 13.

	mov $boot0LoadedMessage, %bx
	call boot0print
	call boot0printnl

	mov %dl, boot0bootdrive							# Store BIOS dl value containing the boot drive number.


boot0ResetDrive:									# Function to reset floppy drive in order to ensure it's working correctly.
	mov	$0x00, %ah									# Set ah to 0 (AH=0x00 -> Reset Disk Function).
	mov boot0bootdrive, %dl							# Move boot0bootdrive value back into dl.
	int	$0x13										# Call BIOS interrupt 13.
	jc boot0ResetDrive								# If Carry Flag is set (CF=1) an error has ocurred, run the function again.

													# On this part we'll load our stage 2 bootloader onto 0x7E00 and jump to it.
	mov boot0bootdrive, %dl							# Move boot0bootdrive value back into dl in case INT13 messes with it.
	mov $0x2, %ah									# Set ah to 2 (AH=0x02 -> Disk Read Function).
	mov $I386_BOOT1_SIZE, %al						# Set al to I386_BOOT1_SIZE (AL=$I386_BOOT1_SIZE) -> Sectors to be readed.
													# Where I386_BOOT1_SIZE equals to the number of sectors occupied by the boot1 binary rounded 1 sector up.
	mov $0x0, %ch									# Set ch to 0 (CH=0x00) -> Track 0 of the drive.
	mov $BOOT1_STARTING_SECTOR, %cl					# Set CL to 2, this is hardcoded, because we're always going to start reading
													# from the sector next to the one that contains the MBR signature (Sector 1 Physically).
	mov $0x00, %dh									# Set dh to 0 (DH=0x00) -> Head 0 of the drive.
	xor %bx, %bx									# Set bx to 0.
	mov %bx, %es									# Move bx onto our extra segment register to prepare the jump.
	mov $0x7E00, %bx								# Set our bx register with the adress we'll jump to.
	int $0x13										# Call BIOS interrupt 13.
	jc boot0diskerror

	mov boot0bootdrive, %bx
	push %bx
	ljmp $0x0, $0x7E00								# Long jump into our stage 2 bootloader. [0x7E00:0x0] -> CS=0x7E00; IP=0x0
	cli
.hlt:
	hlt
	jmp .hlt

boot0print:
	pusha
.boot0printchar:
	mov (%bx), %al
	cmp $0x0, %al
	je .boot0printdone
	mov $0x0E, %ah
	int $0x10
	add $0x1, %bx
	jmp .boot0printchar
.boot0printdone:
	popa
	ret

boot0printnl:
    pusha
    mov $0x0E, %ah
    mov $0x0A, %al
    int $0x10
    mov $0x0D, %al
    int $0x10
    popa
    ret

boot0diskerror:
	mov $boot0DiskErrorMessage, %bx
	call boot0print
	call boot0printnl
	mov %ah, %dh 									# TODO: Print in hex what kind of error we've got.
	jmp .hlt

boot0bootdrive: .byte 0
boot0LoadedMessage: .asciz "Entered 1st Stage"
boot0DiskErrorMessage: .asciz "Disk Read Error!"

.fill 510-(.-init0), 1, 0							# Preprocessor directive from GNU as that fills 'x'
													# count of bytes, with a 'y' size that has 'z' value.
													# args: count, size, value

.word 0xAA55										# BIOS 2-byte magic number that enables the proper
													# booting of this bootloader
