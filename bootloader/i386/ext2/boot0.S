
.set BootMessage_Length, 12
.set Loader_Name_Length, 10

.set Loader_Base, 0x9000
.set Loader_Offset, 0x0
.set SuperBlock_LBA_L, 0x2
.set SuperBlock_LBA_H, 0x0

.set Stack_Base, 0x7c00

.set GroupDescriptors_Base, 0x90
.set GroupDescriptors_Offset, 0x0
.set GroupDescriptors_LBA_L, 0x4
.set GroupDescriptors_LBA_H, 0x0

.set RootDir_Base, 0x110
.set RootDir_Offset, 0x0

.set InodeTable_Base, 0xd0
.set InodeTable_Offset, 0x0


.set Inode_Blocks, 28
.set Inode_Block, 40

.set SuperBlock_Base, 0x70		
.set SuperBlock_Offset, 0x0

.set Name_Len_Offset, 6
.set File_Type_Offset, 7
.set File_Name_Offset, 8

.set Inode_Number_Offset, 0

.set Record_Length_Offset, 4

.set Inode_Length, 128

.global init0_ext2
.code16
.section .text
init0_ext2:
	jmp boot_start
	
disk_address_packet:
				.byte	0x10
				.byte	0
				.byte	2
				.byte	0
				.word	SuperBlock_Offset
				.word	SuperBlock_Base
				.int	SuperBlock_LBA_L
				.int	SuperBlock_LBA_H

	Loader_Name:	.ascii	"loader.bin"

boot_start:
	movw %cs,%ax
	movw %ax,%ds
	movw %ax,%es
	movw %ax,%ss
	movw $Stack_Base, %sp

	call read_sector

	movw $GroupDescriptors_Offset, (disk_address_packet + 4)
	movw $GroupDescriptors_Base, (disk_address_packet + 6)
	movl $GroupDescriptors_LBA_L, (disk_address_packet + 8)
	movl $GroupDescriptors_LBA_H, (disk_address_packet + 12)

	call read_sector

	movl $2,%eax
	call get_inode
	

	movw $RootDir_Offset, (disk_address_packet + 4)
	movw $RootDir_Base, (disk_address_packet + 6)

	mov  %es:Inode_Block(%bx), %eax


	add %eax, %eax
	movl %eax, (disk_address_packet + 8)
	movl $0x0, (disk_address_packet + 12)

	mov  %es:Inode_Blocks(%bx), %eax


	shrl %eax
	movw %ax,%cx
	cmpw $12,%cx
	jle root_dir_read
	movw $12,%cx

root_dir_read:
	cmpw $0, %cx
	je loader_not_found
	call read_sector
	decw %cx

	addw $4,%bx
	movl %es:(%bx), %eax
	addl %eax,%eax
	mov %eax, (disk_address_packet + 8)

root_dir_search:
	pusha
	movw $Loader_Name, %si
	movl $RootDir_Base, %eax
	movl %eax,%gs

	movw $RootDir_Offset, %bx

root_file_match:

file_length_cmp:
	xorw %cx,%cx
	movb $Loader_Name_Length, %cl

	cmpb  %gs:Name_Len_Offset(%bx), %cl
	
	jnz file_not_match

	movw $Loader_Name, %si
	pushw %bx
file_name_cmp:
	lodsb
	
	cmpb  %gs:File_Name_Offset(%bx), %al


	jnz file_name_cmp_end
	decb %cl
	jz file_name_cmp_end
	incw %bx
	jmp file_name_cmp

file_name_cmp_end:
	popw %bx
	cmpb $0,%cl
	jnz file_not_match

	jmp loader_found

file_not_match:
	add  %gs:Record_Length_Offset(%bx), %bx


	cmpw $1024,%bx
	jl root_file_match
	popa

	jmp root_dir_read


loader_not_found:
	mov $0x0e, %ah
	mov $'L', %al
	int $0x10
	mov $' ', %al
	int $0x10
	mov $'N', %al
	int $0x10
	mov $'F', %al
	int $0x10
	cli
	hlt

loader_found:

	mov  %gs:Inode_Number_Offset(%bx), %eax
	
	call get_inode
	
	movw $Loader_Offset, (disk_address_packet + 4)
	movw $Loader_Base, (disk_address_packet + 6)
	
	call loade_file

	mov $0x0e, %ah
	mov $'J', %al
	int $0x10

	ljmp $Loader_Base, $Loader_Offset


read_sector:
	pusha
	xorl %ebx,%ebx
	movb $0x42,%ah
	movb $0x80,%dl
	movw $disk_address_packet, %si
	int $0x13
	popa
	
	ret


get_inode:
	movw $InodeTable_Offset, (disk_address_packet + 4)
	movw $InodeTable_Base, (disk_address_packet + 6)

	decl %eax
	movb $8,%bl
	divb %bl
	movb %ah,%cl
	xorb %ah,%ah

	movw $GroupDescriptors_Base, %bx
	movw %bx,%es
	movw $GroupDescriptors_Offset, %bx
	mov  %es:0x8(%bx), %ebx
	addl %ebx,%eax
	addl %eax,%eax
	mov %eax, (disk_address_packet + 8)

	call read_sector

	movw $InodeTable_Base, %bx
	movw %bx,%es
	mov %cl, %al
	movw $Inode_Length, %cx
	mul %cx
	movw %ax,%bx

	ret

loade_file:
	mov  %es:Inode_Blocks(%bx), %ecx
	cmpl $24,%ecx
	jbe valid_size

	movl $24,%ecx
valid_size:
	movb $2, (disk_address_packet + 2)

read_block:
	mov  %es:Inode_Block(%bx), %eax

	addw $4,%bx

	addl %eax,%eax
	movl %eax, (disk_address_packet + 8)
	
	
	call read_sector
	addw $0x400, (disk_address_packet + 4)

	subl $2,%ecx
	ja read_block

	ret

.fill 510-(.-init0_ext2), 1, 0

.word 0xAA55
