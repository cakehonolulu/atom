.section .text:
loader_start:
    mov $0x0e, %ah
	mov $'H', %al
	int $0x10
	mov $'i', %al
	int $0x10
	mov $'!', %al
	int $0x10
	cli
	hlt
    

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

Kernel_File_Name: .ascii	"kernel.bin"
.set Kernel_File_Name_Length, 10

.set Message_Length, 13
Message:
		.ascii	"Loading      "
		.ascii	"kernel found "
		.ascii	"kernel loaded"
		.ascii	"kernel jump  "
		.ascii	"No kernel    "

.set Stack_Base, 0x2000
.set Stack_Top, 0x400

.section .data:
.align 32
Data_Section:

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


.set Disk_Address_Packet, Loader_Phy_Address + _Disk_Address_Packet
.set Disp_Pos, Loader_Phy_Address + _Disp_Pos
.set Test_message, Loader_Phy_Address + _Test_message
.set Char_Return, Loader_Phy_Address + _Char_Return
.set Mem_Info_Title, Loader_Phy_Address + _Mem_Info_Title
.set RAM_Size_Title, Loader_Phy_Address + _Mem_Size_Title
.set Mem_Size, Loader_Phy_Address + _Mem_Size
.set Page_Init_Success, Loader_Phy_Address + _Page_Init_Success
.set Init_Kernel_Success, Loader_Phy_Address + _Init_Kernel_Success


