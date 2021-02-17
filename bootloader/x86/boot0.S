.code16												# Produce 16-Bit Code (For Real Mode).

.extern I386_BOOT1_SIZE

.set BOOT1_STARTING_SECTOR, 0x2						# This is a constant! It will always be the same!

.global boot0										# Make our functions globally available.

#ifdef I_FS_FAT16
.global init0_fat16
.global init0_fat16_start
#endif

#ifdef I_FS_NONE
.global init0
#endif

.section .text										# Text section.

#ifdef I_FS_FAT16
# init0_fat16 function
init0_fat16:	
# TODO/HACK: Do we really need: .intel_syntax noprefix and .att_syntax prefix in jmp short init0_fat16_start ?
	jmp init0_fat16_start
	nop

# Boot Parameter Block (BPB)
bootsector:
  iOEM:          .ascii "INITIUM1"    # OEM String
  iSectSize:     .word  0x200         # bytes per sector
  iClustSize:    .byte  1             # sectors per cluster
  iResSect:      .word  1             # #of reserved sectors
  iFatCnt:       .byte  2             # #of FAT copies
  iRootSize:     .word  224           # size of root directory
  iTotalSect:    .word  2880          # total # of sectors if over 32 MB
  iMedia:        .byte  0xF0          # media Descriptor
  iFatSize:      .word  9             # size of each FAT
  iTrackSect:    .word  9             # sectors per track
  iHeadCnt:      .word  2             # number of read-write heads
  iHiddenSect:   .int   0             # number of hidden sectors
  iSect32:       .int   0             # # sectors for over 32 MB
  iBootDrive:    .byte  0             # holds drive that the boot sector came from
  iReserved:     .byte  0             # reserved, empty
  iBootSign:     .byte  0x29          # extended boot sector signature
  iVolID:        .ascii "seri"        # disk serial
  acVolumeLabel: .ascii "BOOTLOAD   " # volume label
  acFSType:      .ascii "FAT16   "    # file system type

#endif

#ifdef I_FS_NONE
# init0 function
init0:												
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
#endif

#ifdef I_FS_FAT16
init0_fat16_start:
	cld												# Clear direction flag, we're going to mess with string operations so we want to
													# be sure that we're on a good environment to start with (Sanitize)
	
	xor %ax, %ax									# Fix %ax register (Set to 0)
	
	mov $0x7C00, %si								# Input the source memory location
	mov $0x500, %di									# Input the destination memory location
	movw $256, %cx									# 256 Words = 512 Bytes (Exact MBR size)
	rep	movsb										# Relocation!

	movb $512, %cl									# After relocating, we're going to zero-out the MBR at the original location (0x7C00)
	rep	stosb										# This is handled by rep stosb pointing the buffer at 0x7C00:0 and setting the size to 512 bytes
	
	jmp ((init0_fat16_sanitize-0x7C00)+0x500)		# This computes the value for IP after the relocation (Subtracting 0x7C00 and then adding the
													# the corresponding destination's memory location)	
init0_fat16_sanitize:
	ljmp $0, $boot0									# Make sure we also compute the new IP value
#endif

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

#ifdef I_FS_FAT16
	mov $0xB800, %ax								# Don't bother printing text, an "L" at the leftmost column at the top will suffice
	mov %ax, %ds 									# TODO: Add why we do this in the bootloader's documentation (Document each error code),
	movb $'L', 0 									# L stands for Loaded for example, D for error... etc
	movb $0x0F, 1
#endif

	xor %ax, %ax
	mov %ax, %ds

	mov %dl, diskDrive								# Store BIOS dl value containing the boot drive number.


diskReset:											# Function to reset floppy drive in order to ensure it's working correctly.
	mov	$0x00, %ah									# Set ah to 0 (AH=0x00 -> Reset Disk Function).
	mov diskDrive, %dl								# Move diskDrive value back into dl.
	int	$0x13										# Call BIOS interrupt 13.
	jc diskReset									# If Carry Flag is set (CF=1) an error has ocurred, run the function again.

													# On this part we'll load our stage 2 bootloader onto 0x7E00 and jump to it.
	mov diskDrive, %dl								# Move diskDrive value back into dl in case INT13 messes with it.
	mov $0x2, %ah									# Set ah to 2 (AH=0x02 -> Disk Read Function).
	mov $I386_BOOT1_SIZE, %al						# Set al to I386_BOOT1_SIZE (AL=$I386_BOOT1_SIZE) -> Sectors to be readed.
													# Where I386_BOOT1_SIZE equals to the number of sectors occupied by the boot1 binary rounded 1 sector up.
	mov $0x0, %ch									# Set ch to 0 (CH=0x00) -> Track 0 of the drive.
	mov $BOOT1_STARTING_SECTOR, %cl					# Set CL to 2, this is hardcoded, because we're always going to start reading
													# from the sector next to the one that contains the MBR signature (Sector 1 Physically).
	mov $0x00, %dh									# Set dh to 0 (DH=0x00) -> Head 0 of the drive.
	xor %bx, %bx									# Set bx to 0.
	mov %bx, %es									# Move bx onto our extra segment register to prepare the jump.
	mov $0x7C00, %bx								# Set our bx register with the adress we'll jump to.
	int $0x13										# Call BIOS interrupt 13.
	jc diskError

	mov diskDrive, %bx
	push %bx
	ljmp $0x0, $0x7C00								# Long jump into our stage 2 bootloader. [0x7E00:0x0] -> CS=0x7E00; IP=0x0
	cli
.hlt:
	hlt
	jmp .hlt

diskError:
	mov $0xB800, %ax
	mov %ax, %ds
	movb $'D', 0
	movb $0x4F, 1
	jmp .hlt

diskDrive: .byte 0

#ifdef I_FS_FAT16
.fill 510-(.-init0_fat16), 1, 0						# Preprocessor directive from GNU as that fills 'x'
													# count of bytes, with a 'y' size that has 'z' value.
													# args: count, size, value

.word 0xAA55										# BIOS 2-byte magic number that enables the proper
													# booting of this bootloader
#endif

#ifdef I_FS_NONE
.fill 510-(.-init0), 1, 0							# Preprocessor directive from GNU as that fills 'x'
													# count of bytes, with a 'y' size that has 'z' value.
													# args: count, size, value

.word 0xAA55										# BIOS 2-byte magic number that enables the proper
													# booting of this bootloader
#endif
