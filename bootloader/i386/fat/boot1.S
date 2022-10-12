#define BPB_BASE 0x7C00

// 8 bytes
#define BPB_NAME (BPB_BASE + 3)
// 2 bytes
#define BPB_SECTSZ (BPB_NAME + 8)
// 1 byte
#define BPB_SECTPC (BPB_SECTSZ + 2)
// 2 bytes
#define BPB_RESSCT (BPB_SECTPC + 1)
// 1 byte
#define BPB_NUMFAT (BPB_RESSCT + 2)
// 2 bytes
#define BPB_FATDIR (BPB_NUMFAT + 1)
// 2 bytes
#define BPB_SECPFT (BPB_FATDIR + 5)
// 1 byte
#define BPB_BOOTDR (BPB_SECPFT + 14)

.code16

.global init1


init1:
    jmp real_init

sector_size:
  .space 2
sectors_per_cluster:
  .space 1
reserved_sectors:
  .space 2
number_of_fats:
  .space 1
total_fat_directory_entries:
  .space 2
sectors_per_fat:
  .space 2
bios_boot_drive:
  .space 1

real_init:

    // Get sector size
    mov $BPB_SECTSZ, %bx
    mov (%bx), %bx
    movw %bx, sector_size

    // Get sectors per cluster
    mov $BPB_SECTPC, %bx
    movb (%bx), %bl
    movb %bl, sectors_per_cluster

    // Get reserved sectors
    mov $BPB_RESSCT, %bx
    mov (%bx), %bx
    movw %bx, reserved_sectors

    // Get the number of FATs
    mov $BPB_NUMFAT, %bx
    movb (%bx), %bl
    movb %bl, number_of_fats

    // Get the total number of fat dir. entries
    mov $BPB_FATDIR, %bx
    mov (%bx), %bx
    movw %bx, total_fat_directory_entries

    // Get sectors per fat
    mov $BPB_SECPFT, %bx
    mov (%bx), %bx
    movw %bx, sectors_per_fat

    // Get the boot drive
    mov $BPB_BOOTDR, %bx
    movb (%bx), %bl
    movb %bl, bios_boot_drive

	xor %edx, %edx
	xor %eax, %eax
	
	mov bios_boot_drive, %dl
	
	mov number_of_fats, %ax
	mulw sectors_per_fat
	add reserved_sectors, %ax
	mov %ax, root_dir_offset

	xchg %bx, %ax

	mov sector_size, %ax
	mov $0x20, %cx
	xor %dx, %dx
	div %cx

	xchg %cx, %ax
	mov total_fat_directory_entries, %ax
	xor %dx, %dx
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
   # xchg %bx, %bx
   call read_sectors

   # xchg %bx, %bx

   mov $0x0600, %bx
   mov %bx, %ax
   add sector_size, %ax

.loop_dir_entries:
	# xchg %bx, %bx
   mov $stage2_name, %di
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
   # Get the file size

   # File size is at offset 0x1C of the FAT Entry
   # 4 byte long, we'll get the 2 MSBs
   movw 0x1C(%bx), %ax
   
   # Divisor is 512 bytes
   mov $0x200, %cx
 
   # 16-bit integer division:
   # ax: dividend
   # cx: divisor
   # result -> ax; remainder -> dx
   div %cx

   # Add 1 sector to wrap the (possible) remainder
   add $1, %ax

   # Move the sectors value to %cx
   mov %ax, %cx

	movw 0x1A(%bx),%ax
	sub $0x02, %ax
	mulb sectors_per_cluster
	add data_cluster_offset, %ax
	mov $0x9000, %bx
	call read_sectors
   call bootstrap

/* Basic GDT. set-up for Unreal Mode, change descriptor 1 & 2 alongside 16->32 bit segment mode later on */
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
	.word (gdt_end - gdt_start - 1)
	.long gdt_start

bootstrap:
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

	cli

	mov %cr0, %eax
	or $1, %eax
	mov %eax, %cr0

	lgdt gdt
	
	ljmpl $GDT_CODE_SEGMENT, $0x9000


error:
	mov $0x0e, %ah
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
   mov bios_boot_drive, %dl
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


root_dir_offset: .word 0x0000	# Address of root directory
data_cluster_offset: .word 0x0000	# offset of the first cluster
stage2_name: 	.ascii "STAGE2"	# name of stage2 loader in root directory
stage2_cur_offset: .word 0x0000	# Current offset in memory
stage2_cur_segment: .word 0x0000	# Current segment in memory

.align 4
dap:
dap_size:		.byte 0x10		# Size of the data address packet.
dap_reserved:		.byte 0x00		# Reserved. Should be 0
dap_block_count:	.word 0x01		# Number of blocks to read
dap_offset:		.word 0x1000	# Offset. (Already set with default)
dap_segment:		.word 0x00		# Segment
dap_sector_low:		.int 0x01		# Lower 32 bits of sector number
dap_sector_high:	.int 0x00		# Upper 32 bits of sector number
