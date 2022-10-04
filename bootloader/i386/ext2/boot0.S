.code16

.global init0_ext2

init0_ext2: 
	xor %ax, %ax
	mov %ax, %ds
	mov %ax, %es
	mov $0x0900, %bx
	cli
	mov %bx, %ss
	mov %ax, %sp
	mov %sp, %bx
	sti
	cld
	
	mov $0x1, %ax
	mov $0x4, %cx
	mov $0x7E00, %bx
	call read_sectors
   
	# EXT2 Magic
	mov (ext2_superblock + 56) , %ax

	# Check if matches
	cmpw $0xEF53, %ax
	je bootstrap

.disk_read_error:
	mov $0x0e, %ah
	# Read Failed, Exit
	mov $'E', %al
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
   mov $0x80, %dl
   mov $dap, %si
   int $0x13
   # xchg %bx, %bx
   jnc .read_ok

   mov $0x0e, %ah
   mov $'R', %al # Read Failed, Retrying
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


.align 4
dap:
dap_size:		.byte 0x10		# Size of the data address packet.
dap_reserved:		.byte 0x00		# Reserved. Should be 0
dap_block_count:	.word 0x04		# Number of blocks to read
dap_offset:		.word 0x7E00	# Offset. (Already set with default)
dap_segment:		.word 0x00		# Segment
dap_sector_low:		.int 0x01		# Lower 32 bits of sector number
dap_sector_high:	.int 0x00		# Upper 32 bits of sector number

.fill 510-(.-init0_ext2), 1, 0						# Preprocessor directive from GNU as that fills 'x'
													# count of bytes, with a 'y' size that has 'z' value.
													# args: count, size, value

.word 0xAA55										# BIOS 2-byte magic number that enables the proper
													# booting of this bootloader

bootstrap:
	mov $0x0e, %ah
	mov $'!', %al
	int $0x10

	cli
	hlt
	
.fill 1024 - (.-init0_ext2), 1, 0
ext2_superblock:
