#define BootMessage_Length 12
#define Loader_Name_Length 10

#define Loader_Base 0x7E00
#define Loader_Offset 0x0
#define SuperBlock_LBA_L 0x2
#define SuperBlock_LBA_H 0x0

#define Stack_Base 0x7c00

#define GroupDescriptors_Base 0x90
#define GroupDescriptors_Offset 0x0
#define GroupDescriptors_LBA_L 0x4
#define GroupDescriptors_LBA_H 0x0

#define RootDir_Base 0x110
#define RootDir_Offset 0x0

#define InodeTable_Base 0xd0
#define InodeTable_Offset 0x0


#define Inode_Blocks 28
#define Inode_Block 40

#define SuperBlock_Base 0x70		
#define SuperBlock_Offset 0x0

#define Name_Len_Offset 6
#define File_Type_Offset 7
#define File_Name_Offset 8

#define Inode_Number_Offset 0

#define Record_Length_Offset 4

#define Inode_Length 128

.global init0
.code16
.section .text
init0:
	ljmp $0, $bootstrap

bootstrap:
	xor %eax, %eax
	movw %ax,%ds
	movw %ax,%es
	movw %ax,%ss
	movw $Stack_Base, %sp

	mov $0x41, %ah
	mov $0x55AA, %bx
	mov $0x80, %dl
	int $0x13
	jc extensions_not_supported

	movb $1, int13_ext_support

	xor %ebx, %ebx
    xor %bp, %bp
    
	call read_sector

	movl $2,%eax
	call get_inode
	

	movw $RootDir_Offset, dap_offset
	movw $RootDir_Base, dap_segment

	mov  %es:Inode_Block(%bx), %eax


	add %eax, %eax
	movl %eax, dap_sector_low
	movl $0x0, dap_sector_high

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
	movl %eax, dap_sector_low

root_dir_search:
	pusha
	movw $Loader_Name, %si
	movl $RootDir_Base, %eax
	movl %eax,%es

	movw $RootDir_Offset, %bx

root_file_match:

file_length_cmp:
	xorw %cx,%cx
	movb $Loader_Name_Length, %cl

	cmpb  %es:Name_Len_Offset(%bx), %cl
	
	jnz file_not_match

	movw $Loader_Name, %si
	pushw %bx
file_name_cmp:
	lodsb
	
	cmpb  %es:File_Name_Offset(%bx), %al


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
	add  %es:Record_Length_Offset(%bx), %bx


	cmpw $1024,%bx
	jl root_file_match
	popa

	jmp root_dir_read


loader_not_found:
	mov $'L', %al
	call printchar
	jmp halt

extensions_not_supported:
	mov $'X', %al
	call printchar
	jmp halt

halt:
	cli
	hlt


loader_found:

	mov  %es:Inode_Number_Offset(%bx), %eax
	
	call get_inode
	
	movw $Loader_Base, dap_offset
	movw $Loader_Offset, dap_segment
	
	call loade_file

	mov $'J', %al
	call printchar

	xchg %bx, %bx

	ljmp $Loader_Offset, $Loader_Base


printchar:
	mov $0x0e, %ah
	int $0x10
	ret

read_sector:
	pusha
	// 5 tries
	mov $5, %cx
.extended_read:
	xorl %ebx,%ebx
	movb $0x42,%ah
	movb $0x80,%dl
	movw $disk_address_packet, %si
	int $0x13
	jnc .read_ok

	dec %cx
	mov $'R', %al
	call printchar
	cmp $0, %cx
	je halt

	xor %ax, %ax
	int $0x13
	jmp .extended_read

.read_ok:
	popa
	
	ret


get_inode:
	movw $InodeTable_Offset, dap_offset
	movw $InodeTable_Base, dap_segment

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
	movl %eax, dap_sector_low

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
	movb $2, dap_block_count

read_block:
	mov  %es:Inode_Block(%bx), %eax

	addw $4,%bx

	addl %eax,%eax
	movl %eax, dap_sector_low
	
	
	call read_sector
	addw $0x400, dap_offset

	subl $2,%ecx
	ja read_block

	ret

disk_address_packet:
dap_size:			.byte	0x10
dap_reserved:		.byte	0
dap_block_count:	.word	0x02
dap_offset:			.word	GroupDescriptors_Offset
dap_segment:		.word	GroupDescriptors_Base
dap_sector_low:		.int	GroupDescriptors_LBA_L
dap_sector_high:	.int	GroupDescriptors_LBA_H

Loader_Name:		.ascii	"stage1.bin"
int13_ext_support:	.byte 0
