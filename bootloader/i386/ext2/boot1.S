.code16

.global init1

init1:
    jmp bootstrap

.set Loader_Base, 0x9000		 
.set Loader_Offset, 0x0
.set Loader_Phy_Address, Loader_Base * 0x10 + Loader_Offset
.set Kernel_File_Base, 0x7000
.set Kernel_File_Offset, 0
.set Kernel_File_Phy_Addr, Kernel_File_Base * 0x10
.set Kernel_Enter_point, 0x1000
.set SuperBlock_Base, 0x70		
.set SuperBlock_Offset, 0x0
.set GroupDescriptors_Base, 0x90
.set GroupDescriptors_Offset, 0x0
.set InodeTable_Base, 0xd0		
.set InodeTable_Offset, 0x0
.set RootDir_Base, 0x110
.set RootDir_Offset, 0x0
.set First_Index_Block_Base, 0x150
.set First_Index_Block_Offset, 0x0
.set Inode_Length, 128
.set Inode_Blocks, 28
.set Inode_Block, 40
.set Inode_Number_Offset, 0
.set Record_Length_Offset, 4
.set Name_Len_Offset, 6
.set File_Type_Offset, 7
.set File_Name_Offset, 8
.set Page_Dir_Base, 0x100000
.set Page_Table_BASE, 0x101000
.set ELF_Header_e_phnum, 0x2c
.set ELF_Header_e_phoff, 0x1c
.set ELF_Program_Header_p_size, 0x10
.set ELF_Program_Header_p_offset, 0x4
.set ELF_Program_Header_p_vaddr, 0x8

.set Kernel_File_Name, "kernel.bin"
.set Kernel_File_Name_Length, 10

.set Message_Length, 13

.set Stack_Base, 0x2000
.set Stack_Top, 0x400

.align 32
	_Disk_Address_Packet:
			.byte 0x10
			.byte 0
			.byte 2
			.byte 0
			.word RootDir_Offset
			.word RootDir_Base
			.int 0
			.int 0

	_Disp_Pos: .int (80 * 6 + 0) * 2

	_Char_Return: .byte 0xA, 0
	_Test_message: .asciz "jojo!  Protect Mode !!!"
	_Page_Init_Success: .asciz "jojo! Page init successfully !!!"
	_Init_Kernel_Success: .asciz "jojo! kernel is ready !!!"
	_Mem_Info_Title: .asciz "BaseAddrL BaseAddrH LengthLow LengthHigh   Type"
	_Mem_Size_Title: .asciz "Memory size: "
    Kernel_File_Name: .ascii "stage2.elf"


.set Disk_Address_Packet, Loader_Phy_Address + _Disk_Address_Packet
.set Disp_Pos, Loader_Phy_Address + _Disp_Pos
.set Test_message, Loader_Phy_Address + _Test_message
.set Char_Return, Loader_Phy_Address + _Char_Return
.set Mem_Info_Title, Loader_Phy_Address + _Mem_Info_Title
.set RAM_Size_Title, Loader_Phy_Address + _Mem_Size_Title
.set Mem_Size, Loader_Phy_Address + _Mem_Size
.set Page_Init_Success, Loader_Phy_Address + _Page_Init_Success
.set Init_Kernel_Success, Loader_Phy_Address + _Init_Kernel_Success

bootstrap:
    movw %cs,%ax
    movw %ax,%ds
    movw %ax,%es
    movw $Stack_Base, %ax
    movw %ax,%ss

    movw $Stack_Top, %sp
	
    # Set video mode, cursor location and bg/fg attr.
    mov $0x0600, %ax
	mov $0x0F, %bh
    xor %cx, %cx
    mov $0x184F, %dx
	int $0x10

    mov $0, %dl
    mov $0, %dh
    mov $0, %bx
    mov $0x02, %ah
    int $0x10

    mov $0x2, %eax
	call get_inode

  
	movw $RootDir_Offset, (_Disk_Address_Packet + 4)
	movw $RootDir_Base, (_Disk_Address_Packet + 6)
    
    
    mov  %es:Inode_Block(%bx), %eax

	add %eax, %eax

    movl %eax, (_Disk_Address_Packet + 8)

	movw $0, (_Disk_Address_Packet + 12)

    
	mov %es:Inode_Blocks(%bx), %eax

	shrl %eax
    movw %ax,%cx
    cmpw $12,%cx
      
    jle root_dir_read

    movw $12,%cx

root_dir_read:
	cmpw $0, %cx
	je kernel_not_found
	call read_sector
	decw %cx

	addw $4,%bx
	movl %es:(%bx), %eax
	addl %eax,%eax
	mov %eax, (_Disk_Address_Packet + 8)
root_dir_search:
    pusha
    movw $Kernel_File_Name, %si
    movl $RootDir_Base, %eax
    movl %eax,%gs

    movw $RootDir_Offset, %bx
root_file_match:
file_length_cmp: 
    xorw %cx,%cx
    movb $Kernel_File_Name_Length, %cl

    cmp %gs:Name_Len_Offset(%bx), %cl
    jnz file_not_match

    movw $Kernel_File_Name, %si
    pushw %bx
file_name_cmp: 
    lodsb
    cmp %gs:File_Name_Offset(%bx), %al
    jnz file_name_cmp_end
    decb %cl
    jz file_name_cmp_end
    incw %bx
    jmp file_name_cmp

file_name_cmp_end: 
    popw %bx
    cmpb $0,%cl
    jnz file_not_match
    jmp kernel_found

file_not_match:
    add  %gs:Record_Length_Offset(%bx), %bx
    cmpw $1024,%bx
    jl root_file_match
    popa

    jmp root_dir_read

kernel_not_found:
	mov $0x0e, %ah
	mov $'S', %al
	int $0x10
    mov $'t', %al
	int $0x10
    mov $'a', %al
	int $0x10
    mov $'g', %al
	int $0x10
    mov $'e', %al
	int $0x10
    mov $' ', %al
	int $0x10
    mov $'2', %al
	int $0x10
    mov $' ', %al
    int $0x10
    mov $'n', %al
	int $0x10
    mov $'o', %al
	int $0x10
    mov $'t', %al
	int $0x10
    mov $' ', %al
	int $0x10
	mov $'F', %al
	int $0x10
    mov $'o', %al
	int $0x10
    mov $'u', %al
	int $0x10
    mov $'n', %al
	int $0x10
    mov $'d', %al
	int $0x10
    mov $'!', %al
	int $0x10
    mov $0x0D, %al
    int $0x10
    mov $0x0A, %al
    int $0x10
	cli
    hlt

kernel_found:
	mov $0x0e, %ah
	mov $'S', %al
	int $0x10
    mov $'t', %al
	int $0x10
    mov $'a', %al
	int $0x10
    mov $'g', %al
	int $0x10
    mov $'e', %al
	int $0x10
    mov $' ', %al
	int $0x10
    mov $'2', %al
	int $0x10
    mov $' ', %al
	int $0x10
	mov $'F', %al
	int $0x10
    mov $'o', %al
	int $0x10
    mov $'u', %al
	int $0x10
    mov $'n', %al
	int $0x10
    mov $'d', %al
	int $0x10
    mov $'!', %al
	int $0x10
    mov $0x0D, %al
    int $0x10
    mov $0x0A, %al
    int $0x10
    cli
    hlt


disk_error:
	mov $0x0e, %ah
	mov $'D', %al
	int $0x10
    mov $'i', %al
	int $0x10
    mov $'s', %al
	int $0x10
    mov $'k', %al
	int $0x10
    mov $' ', %al
	int $0x10
	mov $'E', %al
	int $0x10
    mov $'r', %al
	int $0x10
    mov $'r', %al
	int $0x10
    cli
    hlt

read_sector:
	pusha
    xorl %ebx,%ebx
    movb $0x42,%ah
    movb $0x80,%dl
    movw $_Disk_Address_Packet, %si
    int $0x13
    jc disk_error
    popa
    ret

get_inode:
	movw $InodeTable_Offset, (_Disk_Address_Packet + 4)
	movw $InodeTable_Base, (_Disk_Address_Packet + 6)

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
	mov %eax, (_Disk_Address_Packet + 8)

	call read_sector

	# movw $InodeTable_Base, %bx
	# movw %bx,%es
	# movb %cl,%al
	# movb $Inode_Length, %bl
	# mulb %bl
	# movw %ax,%bx

	# Set ax to 0
	# Fill the low half of cx with cl's value

	movw $InodeTable_Base, %bx
	movw %bx,%es
	mov %cl, %al
	movw $Inode_Length, %cx
	mul %cx
	movw %ax,%bx

	ret








