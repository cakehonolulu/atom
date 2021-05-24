.code16												# Compile 16-Bit Code (Targetting Real Mode)

.extern I386_BOOT1_SIZE								# This constant is calculated at compile-time, the size
													# is measured in sectors (Each, 512 byte wide)

.set BOOT1_STARTING_SECTOR, 0x2						# This is a constant! It will always be the same!

.global boot0										# Make our functions globally available

#ifdef I_FS_FAT16
.global init0_fat16
#endif

#ifdef I_FS_NONE
.global init0_nofs
#endif

.section .text										# Text section

#ifdef I_FS_FAT16
# init0_fat16 function
init0_fat16:	
# TODO/HACK: Do we really need: .intel_syntax noprefix and .att_syntax prefix in jmp short boot0 ?
.intel_syntax noprefix
	jmp short boot0
.att_syntax prefix
	nop

# Boot Parameter Block (BPB)
bpb:
  oem_string:				.ascii	"INITIUM1"		# OEM String, 8 char wide, INITIUM for the bootloader name, number 1 for the version
  sector_size:				.word	0x200			# How many bytes per sector (512 is the default)
  sectors_per_cluster:				.byte	4				# How many sectors per cluster
  reserved_sectors:			.word	4				# How many reserved sectors
  number_of_fats:				.byte	2				# How many F(ile) A(llocation) T(ables) we need
  total_fat_directory_entries:			.word	512				# Size of FAT's Root Directory
  total_sectors:			.word	20160			# Total number of sectors
  media_descriptor_type:			.byte	0xF8			# Media Descriptor Value
  sectors_per_fat:					.word	20				# Size of each FAT
  spt:						.word	32				# Sectors per track
  heads_count:				.word	2				# Number of heads
  hidden_sector_count:		.int	0				# Number of hidden sectors
  high_sector_count:		.int	0				# Sectors over 32MB mark
  bios_boot_drive:			.byte	0x80				# BIOS-provided boot drive
  reserved:					.byte	0				# Reserved, set to 0
  extended_bpb_signature:	.byte	0x29			# Extended BPB signature
  volumeid_name:			.int	0xd7450e5		# Disk serial
  volume_label:				.ascii	"BOOTLOAD   "	# Volume label
  fs_type:					.ascii	"FAT16   "		# File system type
#endif

#ifdef I_FS_NONE
# init0_nofs function
init0_nofs:
	cld												# Clear direction flag, we're going to mess with string operations so we want to
													# be sure that we're on a good environment to start with (Sanitize)
	
	xor %ax, %ax									# Fix %ax register (Set to 0)

	mov $0x7C00, %si								# Input the source memory location
	mov $0x500, %di									# Input the destination memory location
	movw $256, %cx									# 256 Words = 512 Bytes (Exact MBR size)
	rep	movsb										# Relocation!

	jmp ((init0_nofs_sanitize-0x7C00)+0x500)		# This computes the value for IP after the relocation (Subtracting 0x7C00 and then adding the
													# the corresponding destination's memory location)	
init0_nofs_sanitize:
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

boot0:												# boot0 function
#ifdef I_FS_NONE
	cli
													# Note: We'll try avoiding FS and GS registers in order to
													# make our bootloader as compatible with every machine possible until we
													# reach 32-bits, where they will be used, but this bootloader might be used on non-x86_32 PC's
													# so using them would make it instantaneously uncompatible with pre-80386+ processors.
													# Thoose 2 registers were added to 80386+ CPU's.
													# TODO: Make device-tree like structures to enable specific compile options
													# that target specific CPUs so that we can divide the bootloader better.
	xor %ax, %ax									# Xor'ing ax to ax, results in a 0, as xor'ing two registers with
													# the same value always results in 0.
	mov %ax, %ss									# Move 0x0 to the data segment register.
													# We null the data segment, because if we don't, it can overlap
													# with the code segment.
	mov $0x7C00, %sp								# Move 0x0900 to bx.
													# Disable interrupts to circumvent a bug present on
													# early 8088 CPU's.
													# Even though that was the main concern primarly, disabling interrupts when messing with
													# the stack is a good thing as of now, to avoid stack corruption if an interrupt is caught in
													# the middle of the stack change!
	mov %0x07C0, %ax									# Move ax (Which now is 0) to the stack segment register.
													# registers that contain the same, will always result in 0.
	mov %ax, %ds									# Set the stack pointer register with 0x7C00.
													# Stack Dissasembly:
													# Top stack adress:		-> 0x0900
	mov %ax, %es									# Move sp (Which now is 0x0900) to the base pointer register.
	sti												# Re-enable interrupts
	cld												# CLD sets EFLAG's register DF flag to 0, this way, string
													# operations increment the segment registers (Such as SI & DI).
													# Invoking a CLD instruction, also makes us aware of the DF's flag
													# contents, in order to make 0 assumptions on how the BIOS leaves this value.

	mov $0x3, %ax									# Use VGA Text Mode
	int $0x10										# Call BIOS interrupt 13.
#endif

#ifdef I_FS_FAT16
													# Note: We'll try avoiding FS and GS registers in order to
													# make our bootloader as compatible with every machine possible until we
													# reach 32-bits, where they will be used, but this bootloader might be used on non-x86_32 PC's
													# so using them would make it instantaneously uncompatible with pre-80386+ processors.
													# Thoose 2 registers were added to 80386+ CPU's.
													# TODO: Make device-tree like structures to enable specific compile options
													# that target specific CPUs so that we can divide the bootloader better.
	xor %ax, %ax									# Xor'ing ax to ax, results in a 0, as xor'ing two registers with
													# the same value always results in 0.
	mov %ax, %ds									# Move 0x0 to the data segment register.
													# We null the data segment, because if we don't, it can overlap
													# with the code segment.
	mov %ax, %es
	mov $0x0900, %bx								# Move 0x0900 to bx.
													# Disable interrupts to circumvent a bug present on
													# early 8088 CPU's.
													# Even though that was the main concern primarly, disabling interrupts when messing with
													# the stack is a good thing as of now, to avoid stack corruption if an interrupt is caught in
													# the middle of the stack change!
	cli
	mov %bx, %ss									# Move ax (Which now is 0) to the stack segment register.
													# registers that contain the same, will always result in 0.
	mov %ax, %sp									# Set the stack pointer register with 0x7C00.
													# Stack Dissasembly:
													# Top stack adress:		-> 0x0900
	mov %sp, %bp									# Move sp (Which now is 0x0900) to the base pointer register.
	sti												# Re-enable interrupts
	cld												# CLD sets EFLAG's register DF flag to 0, this way, string
													# operations increment the segment registers (Such as SI & DI).
													# Invoking a CLD instruction, also makes us aware of the DF's flag
													# contents, in order to make 0 assumptions on how the BIOS leaves this value.



	mov %dl, bios_boot_drive

	xor %dx, %dx
	xor %ax, %ax
	
	mov bios_boot_drive, %dl
	
	mov number_of_fats, %ax
	mulw sectors_per_fat
	add reserved_sectors, %ax
	mov %ax, root_dir_offset

	xchg %bx, %ax

	mov sector_size, %ax
	mov $0x20, %cx
	div %cx

	xchg %cx, %ax
	mov total_fat_directory_entries, %ax
	div %cx
	add %bx, %ax
	mov %ax, data_cluster_offset

	xor %dx, %dx

.loop:
   mov root_dir_offset, %ax
   add %dx, %ax
   mov $0x0600, %bx
   mov $0x01, %cx
   push %dx
   xchg %bx, %bx
   call read_sectors
   xchg %bx, %bx

   mov $0x200, %bx
   mov %bx, %ax
   add sector_size, %ax

.loop_dir_entries:
   mov stage2_name, %di
   mov $0x06, %cx
   mov %bx, %si
   rep cmpsb
   je .match

   add $0x20, %bx
   cmp %bx, %ax
   jne .loop_dir_entries

   pop %dx
   inc %dx
   cmp $0x80, %dx
   jne .loop
   jmp error

.match:
	# xchg %bx, %bx
	movw 0x1A(%bx),%ax
	sub $0x02, %ax
	mulb sectors_per_cluster
	add data_cluster_offset, %ax
	mov $1, %cx # STAGE 2 Size
	mov $0x0600, %bx
	call read_sectors
	xchg %bx, %bx
	jmp $0x0, $0x1000

error:
	mov $0x0e, %ah
	mov $0x45, %al # E
	int $0x10
   cli
   hlt

read_sectors:
   pusha
   mov %eax, dap_sector_low
   mov %es, dap_segment
   mov %bx, dap_offset
.extended_read:
   mov $0x42, %ah
   mov bios_boot_drive, %dl
   mov $dap, %si
   int $0x13
   # xchg %bx, %bx
   jnc .read_ok

   mov $0x0e, %ah
   mov $0x52, %al # Read Failed, Retrying
   int $0x10

   xor %ax, %ax
   int $0x13
   jmp .extended_read

.read_ok:
   popa
   inc %eax
   add $0x200, %bx
   jnc .no_carry

   mov %es, %dx
   add $0x10, %dh
   mov %dx, %es

.no_carry:
   dec %cx
   jz read_sectors_exit
   jmp read_sectors

read_sectors_exit:
   ret

#endif

#ifdef I_FS_NONE
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
	mov $0x1000, %bx								# Set our bx register with the adress we'll jump to.
	int $0x13										# Call BIOS interrupt 13.
	jc diskError

	mov diskDrive, %bx
	push %bx 
	ljmp $0x0, $0x0600								# Long jump into our stage 2 bootloader. [0x7E00:0x0] -> CS=0x7E00; IP=0x0
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

#endif

root_dir_offset: .word 0x0000	# Address of root directory
data_cluster_offset: .word 0x0000	# offset of the first cluster
stage2_name: 	.ascii "STAGE2"	# name of stage2 loader in root directory
stage2_cur_offset: .word 0x0000	# Current offset in memory
stage2_cur_segment: .word 0x0000	# Current segment in memory

.byte 41
.byte 41

.align 4
dap:
dap_size:		.byte 0x10		# Size of the data address packet.
dap_reserved:		.byte 0x00		# Reserved. Should be 0
dap_block_count:	.word 0x01		# Number of blocks to read
dap_offset:		.word 0x1000	# Offset. (Already set with default)
dap_segment:		.word 0x00		# Segment
dap_sector_low:		.int 0x01		# Lower 32 bits of sector number
dap_sector_high:	.int 0x00		# Upper 32 bits of sector number

.byte 41
.byte 41

#ifdef I_FS_FAT16
.fill 510-(.-init0_fat16), 1, 0						# Preprocessor directive from GNU as that fills 'x'
													# count of bytes, with a 'y' size that has 'z' value.
													# args: count, size, value

.word 0xAA55										# BIOS 2-byte magic number that enables the proper
													# booting of this bootloader
#endif

#ifdef I_FS_NONE
.fill 510-(.-init0_nofs), 1, 0						# Preprocessor directive from GNU as that fills 'x'
													# count of bytes, with a 'y' size that has 'z' value.
													# args: count, size, value

.word 0xAA55										# BIOS 2-byte magic number that enables the proper
													# booting of this bootloader
#endif
