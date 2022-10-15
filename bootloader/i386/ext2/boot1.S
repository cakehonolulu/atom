.code16

.global init1

init1:
    jmp bootstrap

.set Loader_Base, 0x9000		 
.set Loader_Offset, 0x0
.set Loader_Phy_Address, Loader_Base * 0x10 + Loader_Offset
.set Stage2_File_Base, 0x7000
.set Stage2_File_Offset, 0
.set Stage2_File_Phy_Addr, Stage2_File_Base * 0x10
.set Stage2_Enter_point, 0x1000
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

.set Stage2_File_Name_Length, 10

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


gdt_start:
gdt_null:
	.long 0
	.long 0
gdt_code:
	.word 0xFFFF
	.word 0x0
	.byte 0x0
	.byte 0b10011010
	.byte 0b11001111
	.byte 0x0

gdt_data:
	.word 0xffff
	.word 0x0
	.byte 0x0
	.byte 0b10010010
	.byte 0b11001111
	.byte 0x0

gdt_end:
.set GDT_CODE_SEGMENT, gdt_code - gdt_start
.set GDT_DATA_SEGMENT, gdt_data - gdt_start

gdt:
	.word ((gdt_end) - (gdt_start) - 1)
	.long (gdt_start)

    Stage2_File_Name: .ascii "stage2.elf"


.set Disk_Address_Packet, Loader_Phy_Address + _Disk_Address_Packet
.set Disp_Pos, Loader_Phy_Address + _Disp_Pos
.set Test_message, Loader_Phy_Address + _Test_message
.set Char_Return, Loader_Phy_Address + _Char_Return
.set Mem_Info_Title, Loader_Phy_Address + _Mem_Info_Title
.set RAM_Size_Title, Loader_Phy_Address + _Mem_Size_Title
.set Mem_Size, Loader_Phy_Address + _Mem_Size
.set Page_Init_Success, Loader_Phy_Address + _Page_Init_Success
.set Init_Stage2_Success, Loader_Phy_Address + _Init_Stage2_Success

#define MEMORY_MAP 0x0500

bootstrap:
    movw $0, %ax
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


    mov $MEMORY_MAP + 8, %di // Destination Location (Add 8 to MEMORY_MAP else int15 will freeze after adding entries)
0:
    movl $1, %es:20(%di)
    mov $0x534d4150, %edx
    mov $24, %ecx
    mov $0xe820, %eax
    int $0x15
    jc mmap_err
    cmp $0x534d4150, %eax
    jne mmap_err
1:
    jcxz 3f                 // ignore if bytes=0
    cmp $20, %cl            // or "ignore" ACPI 3.x attribute is 1
    jbe 2f
    testb $1, %es:20(%di)
    jz 3f
2:
    mov %es:8(%di), %ecx    // ignore if length=0
    or %es:12(%di), %ecx
    jz 3f
    inc %bp
    add $24, %di
3:
    test %ebx, %ebx         // ebx=0 if end of list
    jnz 0b
    mov %bp, (MEMORY_MAP)
    clc


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
	je stage2_not_found
	call read_sector
	decw %cx

	addw $4,%bx
	movl %es:(%bx), %eax
	addl %eax,%eax
	mov %eax, (_Disk_Address_Packet + 8)
root_dir_search:
    pusha
    movw $Stage2_File_Name, %si
    movl $RootDir_Base, %eax
    movl %eax,%es

    movw $RootDir_Offset, %bx
root_file_match:
file_length_cmp: 
    xorw %cx,%cx
    movb $Stage2_File_Name_Length, %cl

    cmp %es:Name_Len_Offset(%bx), %cl
    jnz file_not_match

    movw $Stage2_File_Name, %si
    pushw %bx
file_name_cmp: 
    lodsb
    cmp %es:File_Name_Offset(%bx), %al
    jnz file_name_cmp_end
    decb %cl
    jz file_name_cmp_end
    incw %bx
    jmp file_name_cmp

file_name_cmp_end: 
    popw %bx
    cmpb $0,%cl
    jnz file_not_match
    jmp stage2_found

file_not_match:
    add  %es:Record_Length_Offset(%bx), %bx
    cmpw $1024,%bx
    jl root_file_match
    popa

    jmp root_dir_read

mmap_err:
    mov $0x0e, %ah
	mov $'M', %al
	int $0x10
	cli
    hlt

stage2_not_found:
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

stage2_found:
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

    mov  %es:Inode_Number_Offset(%bx), %eax
	
	call get_inode
	
	movw $Stage2_File_Offset, (_Disk_Address_Packet + 4)
	movw $Stage2_File_Base, (_Disk_Address_Packet + 6)
	
	call loade_file

    mov $0x0e, %ah
    int $0x10
    mov $0x0D, %al
    int $0x10
    mov $0x0A, %al
    int $0x10

    call stage2_loaded

    in $0x92, %al
    test $2, %al
    jnz after
    or $2, %al
    and $0xFE, %al
    out %al, $0x92
    jmp after

    
after:
    lgdt gdt
	mov %cr0, %eax
	or $0x1, %al
	mov %eax, %cr0

	ljmpl $GDT_CODE_SEGMENT, $(boot1ProtectedMode)

.code32
.global boot1ProtectedMode

boot1ProtectedMode:
	mov $GDT_DATA_SEGMENT, %ax
	mov %ax, %ds
	mov %ax, %es
	mov %ax, %ss
	mov %ax, %es
    
    mov $0x7C00, %esp

    call parseStage2Elf

    ljmpl $GDT_CODE_SEGMENT, $Stage2_Enter_point
	cli
    hlt

MemCpy:
    pushl   %ebp
    movl    %esp,%ebp

    pushl   %esi
    pushl   %edi
    pushl   %ecx

    movl    8(%ebp),%edi                                     # Destination
    movl    12(%ebp),%esi                           # Source
    movl    16(%ebp),%ecx                              # Counter
transfer: 
    cmpl    $0,%ecx
    jz      transfer_end

    mov  %ds:(%esi), %al
    incl    %esi
    movb  %al, %es:(%edi)
    incl    %edi

    decl    %ecx
    jmp     transfer

transfer_end: 
    movl    8(%ebp),%eax

    popl    %ecx
    popl    %edi
    popl    %esi
    movl    %ebp,%esp
    popl    %ebp

    ret

parseStage2Elf:
    xor %esi, %esi
    mov (Stage2_File_Phy_Addr+ELF_Header_e_phnum), %cx
    movzx %cx, %ecx
    mov (Stage2_File_Phy_Addr+ELF_Header_e_phoff), %esi
    add $Stage2_File_Phy_Addr, %esi
deal_with_one_program_header_table_entry:
    mov  (%esi), %eax
    cmpl    $0,%eax

    jz      init_next_section
    pushl ELF_Program_Header_p_size(%esi)
    mov  ELF_Program_Header_p_offset(%esi), %eax
    add $Stage2_File_Phy_Addr, %eax
    push %eax
    pushl ELF_Program_Header_p_vaddr(%esi)
    call MemCpy
    addl    $12,%esp

init_next_section: 
    addl    $0x20,%esi
    decl    %ecx
    jnz     deal_with_one_program_header_table_entry
    ret

.code16
stage2_loaded:
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
    mov $'L', %al
	int $0x10
    mov $'o', %al
	int $0x10
    mov $'a', %al
	int $0x10
    mov $'d', %al
	int $0x10
    mov $'e', %al
	int $0x10
    mov $'d', %al
	int $0x10
    mov $'!', %al
	int $0x10
    ret

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
	// 5 tries
	mov $5, %cx
.extended_read:
	xorl %ebx,%ebx
	movb $0x42,%ah
	movb $0x80,%dl
	movw $_Disk_Address_Packet, %si
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

printchar:
	mov $0x0e, %ah
	int $0x10
	ret

halt:
    cli
    hlt

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

	movw $InodeTable_Base, %bx
	movw %bx,%es
	mov %cl, %al
	movw $Inode_Length, %cx
	mul %cx
	movw %ax,%bx

	ret


loade_file:
    push %bx
    mov  %es:Inode_Blocks(%bx), %ecx
    cmpl $24,%ecx
    jbe     direct_block
    movl    $24,%ecx

direct_block:
    movb $0x2, (_Disk_Address_Packet + 2)

read_direct_block:
    mov  %es:Inode_Block(%bx), %eax
    addw $4,%bx
    addl %eax,%eax
    movl %eax, (_Disk_Address_Packet + 8)
	
	call read_sector
    addw $0x400, (_Disk_Address_Packet + 4)

    subl $2,%ecx
    ja      read_direct_block
    movw %bx,%ax

    popw %bx
    mov  %es:Inode_Blocks(%bx), %ecx
    cmpl $24,%ecx
    jbe     loade_file_end
    subl $24,%ecx

    movw %ax,%bx

    push (_Disk_Address_Packet + 4)
    push (_Disk_Address_Packet + 6)
    mov  %es:Inode_Block(%bx), %eax
    add %eax, %eax

    movl %eax, (_Disk_Address_Packet + 8)
    movw $First_Index_Block_Offset, (_Disk_Address_Packet + 4)
    movw $First_Index_Block_Base, (_Disk_Address_Packet + 6)
	call read_sector

    movw $First_Index_Block_Base, %ax
    movw %ax,%es

    movw $First_Index_Block_Offset, %bx
    pop (_Disk_Address_Packet + 6)
    pop (_Disk_Address_Packet + 4)

read_first_index_block:
    mov %es:(%bx), %eax
    addw $4,%bx

    addl %eax,%eax
    movl %eax, (_Disk_Address_Packet + 8)
    call read_sector
    addw $0x400, (_Disk_Address_Packet + 4)
    subl $2,%ecx
    ja      read_first_index_block

loade_file_end: 
    ret
