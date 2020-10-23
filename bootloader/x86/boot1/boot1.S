# Thanks to Octocontrabass, Combuster and MichaelPetch for the help @ forum.osdev.org

.global init1

.section .data

/* Static Bootloader Values */
.set BOOT1_PROTECTED_MODE_STACK_ADDRESS, 0x9C000
.set VGA_MEMORY_LOCATION, 0xB8000
.set VGA_MEMORY_ATTRIBUTES, 0x0F
.set MEMORY_MAP, 0x9000

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
	.byte 0b10001111
	.byte 0x0

gdt_data:
	.word 0xffff
	.word 0x0
	.byte 0x0
	.byte 0b10010010
	.byte 0b10001111
	.byte 0x0

gdt_end:
.set GDT_CODE_SEGMENT, gdt_code - gdt_start
.set GDT_DATA_SEGMENT, gdt_data - gdt_start

gdt:
	.word (gdt_end - gdt_start - 1)
	.long gdt_start

.set PAGING_BIT, 0x80000000
.set NO_PAGING_BIT, 0x7FFFFFFF
.set PAGE_TABLE_START, 0
.set PAGE_TABLE_SIZE, 0x1000 /* Combined size of all page tables divided by 4 */
.set PAGE_SIZE, 0x1000 /* Size of a memory page. Also the size of a single page table */
.set PAE_BIT, 0x20
.set EFER_MSR, 0xC0000080 /* Extended Feature Enable Register Model Specific Register */
.set LONG_MODE, 0x100

/* Address of first table of a type OR'd with 3
   (3 indicates present and readable) */
.set PDPT, 0x1003	/* Page Directory Pointer Table */
.set PDT, 0x2003	/* Page Directory Table */
.set PT, 0x3003		/* Page Table */

/* These parameter will identity map the first 2 Megabytes */
.set MEM_START, 3		/* Address (OR'd with 3) of first mapped physical memory */
.set NUM_PAGES, 0x200	/* Number of memory pages */


/* Bootloader Strings */
A20AlreadyEnabledMessage: .asciz "A20 Line is already enabled, skipping..." // Bochs for example, enables it regardless the OS
A20EnabledMessage: .asciz "A20 Line enabled Successfully!"
Stage2LoadedMessage: .asciz "Entered 2nd Stage"

ProtectedModeGDTLoadedMessage: .asciz "Protected Mode GDT Loaded"
UnrealModeGDTLoadedMessage: .asciz "Unreal Mode GDT Loaded"

EnteredProtectedModeMessage: .asciz "Entered Protected Mode"
EnteredUnrealModeMessage: .asciz "Entered Unreal Mode"

ResettingFloppyMessage: .asciz "Resetting Floppy..."
ResettedFloppyMessage: .asciz "Resetted Floppy!"

ReadingKernelMessage: .asciz "Reading Kernel from Disk..."
ReadedKernelMessage: .asciz "Readed Kernel from Disk!"
ReadKernelFailMessage: .asciz "Failed to Read the Kernel!"
DiskErrorMessage: .asciz "Disk Read Error!"

RelocatingKernelMessage: .asciz "Relocating Kernel at Address: 0x10000 (1MB Mark)..."
RelocatedKernelMessage: .asciz "Relocated Successfully!"
RelocateKernelFailMessage: .asciz "Kernel Relocation Went Wrong, Halting!"

LoadingKernelMessage: .asciz "Loading Kernel..."
LoadedKernelMessage: .asciz "Loaded Kernel!"


BootModeText: .asciz "Which Mode you want Atom to work? (PMode = P, Long Mode = L)"
LMOBitText: .asciz "64 Bit Mode Selected"
PMOBitText: .asciz "32 Bit Mode Selected"

/* Bootloader Variables */
VGA_TEXT_MODE_CURRENT_ROW: .long 0x00
VGA_TEXT_MODE_CURRENT_COLUMN: .long 0x00
VGA_TEXT_MODE_SCREEN_WIDTH: .long 0x00
VGA_TEXT_MODE_SCREEN_HEIGHT: .long 0x00

BOOT_DRIVE_NUMBER: .byte 0

Load64Bit: .byte 0

.extern I386_KERNEL_SIZE
.extern main

.section .text

.code16

init1:
	pop %bx														# Get the boot drive value from stack.
	mov %bx, BOOT_DRIVE_NUMBER									# Place the boot drive value on a temporal buffer.
	xor %bx, %bx												# Set bx to 0.
	xor %ax, %ax												# Set ax to 0.
	mov %ax, %ds												# Set ds to 0.
	mov %ax, %ss												# Set up stack segment.
	mov $0x7C00, %sp											# Set the stack pointer register with 0x7C00.
																# Stack Dissasembly:
																# Top stack adress:		-> 0x7C00
	mov %sp, %bp												# Move sp (Which now is 0x7C00) to the base pointer register.
	mov $Stage2LoadedMessage, %bx								# Print a message that tells we're currently on second stage bootloader.

	call boot1print
	call boot1printnl
.ifdef LONGMODE
AskBootMode:
	mov $BootModeText, %bx								# Print a message that tells we're currently on second stage bootloader.

	call boot1print
	call boot1printnl
	xor %ax, %ax
	int  $0x16
	cmp $0x6c, %al
	je .LMO

	cmp $0x70, %al
	je .PMO

	jmp AskBootMode
.endif
.PMO:
.ifdef LONGMODE
	# xchg %bx, %bx	# DEBUG!
	xor %ax, %ax
	mov $0, %ax
	mov %ax, Load64Bit
.endif
	call .Continue

.LMO:
	# xchg %bx, %bx	# DEBUG!
	xor %ax, %ax
	mov $1, %ax
	mov %ax, Load64Bit
	call .Continue
	
.Continue:								
	call boot1EnableA20

	cli															# Disable interrupts.
	cld															# CLD sets EFLAG's register DF flag to 0, this way, string
																# operations increment the segment registers (Such as SI & DI).
																# Invoking a CLD instruction, also makes us aware of the DF's flag
																# contents, in order to make 0 assumptions on how the BIOS leaves this value. 
	lgdt gdt													# Load the Unreal Mode GDT.
	mov $UnrealModeGDTLoadedMessage, %bx						# Print a message that tells that the Unreal Mode GDT has been loaded.
	call boot1print
	call boot1printnl
	mov %cr0, %eax												# Move CR0 to EAX.
	or $0x1, %al												# Set the Protected Mode Bit of EAX.
	mov %eax, %cr0												# Move back EAX to CR0, enabling Protected Mode.

	ljmp $GDT_CODE_SEGMENT, $boot1TemporalProtectedMode			# Enable Protected Mode by Long-Jumping (This changes the Instruction
																# Pointer Register alongside the Code Segment).
																# After jumping to Protected Mode (32-BIT) and setting the 4GiB Code/Data
																# Segments, we'll quickly switch back to Real Mode (16-BIT) but this will
																# maintain the Protected Mode's Segments (Which are larger than the limit
																# Real Mode offers, which is 64KiB) and this will result on a variation
																# of Real Mode called Unreal Mode where we will be able to load the Kernel
																# over the 1MiB mark due to the fact that we have 4GiB Code & Data Segments.

boot1TemporalProtectedMode:
	mov $GDT_DATA_SEGMENT, %bx									# Set bx to use the "higher-than-64KiB" segment...
	mov %bx, %ds												# ...and set the remaining segments with this value.
	mov %bx, %es												# The extra segment...
	mov %bx, %ss												# ...and the stack segment.
	and $0xFE, %al												# Now, disable the Protected Mode Bit...
	mov %eax, %cr0												# ...and make the change effective by loading the result back to CR0.
	ljmp $0x0, $boot1HugeUnrealMode								# We Long-Jump again so that Real Mode (Now Unreal) gets "enabled" back.

boot1HugeUnrealMode:
	xor %ax, %ax
	mov %ax, %es
	mov %ax, %ds
	mov $0x9000, %sp											# Set the stack pointer register with 0x9000.
																# Stack Dissasembly:
																# Top stack adress:		-> 0x9000
	mov %ax, %ss												# Set up stack segment
	mov %sp, %bp												# Move sp (Which now is 0x9000) to the base pointer register.
	mov $EnteredUnrealModeMessage, %bx
	call boot1print
	call boot1printnl
	call boot1UnrealModePrepareKernel
	cmp $0, %ax
	jnz boot1UnrealModeRelocateKernelFail

	call boot1UMRelocatedKernel

    xor %ebx, %ebx
    xor %bp, %bp
    
    mov $MEMORY_MAP + 8, %di // Destination Location (Add 8 to MEMORY_MAP else int15 will freeze after adding entries)
0:
    movl $1, %es:20(%di)
    mov $0x534d4150, %edx
    mov $24, %ecx
    mov $0xe820, %eax
    int $0x15
    jc boot1UnrealModeLoadKernelFail
    cmp $0x534d4150, %eax
    jne boot1UnrealModeLoadKernelFail
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
	mov %cr0, %eax
	or $1, %eax
	mov %eax, %cr0
	mov $0b11001111, %al
	mov %al, (gdt_code + 6)										# We dynamically modify the GDT structure to try optimizing
	mov %al, (gdt_data + 6)										# the size, change both segment's bitmode to 32-bit.
	cli
	lgdt gdt
	ljmpl $GDT_CODE_SEGMENT, $boot1Start32
	cli
	jmp boot1Halt

boot1UnrealModePrepareKernel:
	call boot1UnrealModeLoadKernel
	call boot1UMRelocatingKernel
	mov $0x1000, %esi
	mov $0x100000, %edi
	mov $0x200, %cx
	mov $0x3d, %bx // Relocate more sectors
.loop:
	addr32 rep movsb
	dec %bx
	jnz .loop
	mov $0, %ax
	jc .done
.done: ret

boot1UnrealModeLoadKernel:
	call boot1UMLoadingKernel

	call boot1UMResettingFloppy
	boot1ResetDrive:									# Function to reset floppy drive in order to ensure it's working correctly.
		mov	$0x00, %ah									# Set ah to 0 (AH=0x00 -> Reset Disk Function).
		mov BOOT_DRIVE_NUMBER, %dl						# Move BOOT_DRIVE_NUMBER value back into dl.
		int	$0x13										# Call BIOS interrupt 13.
		jc boot1ResetDrive

	call boot1UMResettedFloppy

	call boot1UMReadingKernel
	xchg %bx, %bx
	mov $0x02, %ah									# Set ah to 2 (AH=0x02 -> Disk Read Function).
	# Sectors per track on a 1.44 MB floppy disk is 18. Since 18*4 = 72 (Which is the max theoretical sectors we can read)
	mov $I386_KERNEL_SIZE, %al						# Set al to I386_KERNEL_SIZE (AL=$I386_KERNEL_SIZE0h) -> Sectors to be readed.
													# Where I386_KERNEL_SIZE equals to the number of sectors occupied by the kernel binary rounded 1 sector up.
	mov $0x0, %ch									# Set ch to 0 (CH=0x00) -> Track 0 of the drive.
													# TODO: Get boot1 size at runtime! For now, hardcode the size.
	mov $0x7, %cl									# FLOPPY_KERNEL_STARTING_SECTOR + 1
													# Which is sector of the drive from which we start reading the kernel from.
	mov $0x0, %dh									# Set dh to 0 (DH=0x00) -> Head 0 of the drive.
	xor %bx, %bx									# Set bx to 0.
	mov %bx, %es									# Move bx onto our extra segment register to prepare the jump.
	mov $0x1000, %bx								# Set our bx register with the adress we'll jump to.
	int $0x13										# Call BIOS interrupt 13.
	jc boot1UnrealModeReadKernelFail

	call boot1UMReadedKernel

	ret

boot1UnrealModeReadKernelFail:
	mov $ReadKernelFailMessage, %bx
	call boot1print
	call boot1printnl
	cli
	jmp boot1Halt

boot1UnrealModeRelocateKernelFail:
	mov $RelocateKernelFailMessage, %bx
	call boot1print
	call boot1printnl
	cli
	jmp boot1Halt

boot1DiskErrorMessage:
	mov $DiskErrorMessage, %bx
	call boot1print
	call boot1printnl
	cli
	jmp boot1Halt

boot1EnableA20:
	call boot1CheckA20LineState								# Check if A20 Line is enabled.
	jnz boot1A20HasAlreadyBeenEnabled						# Jump if condition is met.

	movw $0x2401, %ax										# Enable A20 Line using the BIOS Method.
	stc														# Set carry flag.
	int	$0x15												# Call BIOS interrupt 15 (Enable A20 Line).
	jc 1f													# BIOS Method failed.
	testb %ah, %ah											# Compares both registers.
	jne 1f													# Jumps if they're not equal.
	call boot1CheckA20LineState								# Check if A20 Line is enabled.
	jnz boot1A20HasBeenEnabled								# Jump if condition is met.
1:															# Enable A20 Line using Intel's 8042 Controller Method.
	call .boot1_8042_wait									# Wait for Intel's 8042 controller to be ready.
	movb $0xd1, %al											# Prepare the 8042 port write.
	outb %al, $0x64											# Write to the 8042 port.
	call .boot1_8042_wait									# Wait for Intel's 8042 controller to be ready.
	movb $0xdf, %al											# Prepare the 8042 port write.
	outb %al, $0x60											# Enable A20 Line.
	call .boot1_8042_wait									# Wait for Intel's 8042 controller to be ready.
	call boot1CheckA20LineState								# Check if A20 Line is enabled.
	jnz	boot1A20HasBeenEnabled								# Jump if condition is met.
															# Enable A20 Line using the 'Fast' Method.
	inb $0x92, %al											# Try the computer's Fast A20 Gate.
	testb $0x02, %al 										# Compare both values.
	jnz 1f													# Don't enable A20 if it's already set.
	orb $0x02, %al											# Check wether the A20 Gate Enable Bit...
	andb $0xfe, %al											# ...is set or not.
	outb %al, $0x92											# Enable the A20 Line using the Fast Gate.
1:
	call boot1CheckA20LineState								# Check if A20 Line is enabled.
	jnz boot1A20HasBeenEnabled								# Jump if condition is met.
	jmp 1b													# Check until A20 Line is set.

.boot1_8042_wait:											# Function that waits for Intel's 8042 controller to be ready.
	inb	$0x64, %al											# Read 8042's status.
	testb $0x02, %al										# Test if bit 1 is zero.
	jnz .boot1_8042_wait									# Jump if condition is met.
	ret														# Return to parent function.

boot1CheckA20LineState:
	pushw %ds
	pushw %es
	xorw %ax, %ax
	movw %ax, %ds
	movw $0x200, %si
	decw %ax
	movw %ax, %es
	movw $0x210, %di
	movw %ax, %cx
	movw (%si), %ax
	pushw %ax
1:
	incw %ax
	movw %ax, %es:(%di)
	cmpw %ax, (%si)
	loope 1b
	popw (%si)
	popw %es
	popw %ds
	ret

boot1UnrealModeLoadKernelFail:
	cli
	hlt

boot1A20HasBeenEnabled:
	mov $A20EnabledMessage, %bx
	call boot1print
	call boot1printnl
	ret

boot1UMLK:
	mov $LoadedKernelMessage, %bx
	call boot1print
	call boot1printnl
	ret

boot1A20HasAlreadyBeenEnabled:
	mov $A20AlreadyEnabledMessage, %bx
	call boot1print
	call boot1printnl
	ret

boot1LandedUnrealMode: 
	mov $EnteredUnrealModeMessage, %bx
	call boot1print
	call boot1printnl
	ret

boot1UMLoadingKernel:
	mov $LoadingKernelMessage, %bx
	call boot1print
	call boot1printnl
	ret

boot1UMResettingFloppy:
	mov $ResettingFloppyMessage, %bx
	call boot1print
	call boot1printnl
	ret

boot1UMResettedFloppy:
	mov $ResettedFloppyMessage, %bx
	call boot1print
	call boot1printnl
	ret

boot1UMReadingKernel:
	mov $ReadingKernelMessage, %bx
	call boot1print
	call boot1printnl
	ret

boot1UMReadedKernel:
	mov $ReadedKernelMessage, %bx
	call boot1print
	call boot1printnl
	ret

boot1UMRelocatingKernel:
	mov $RelocatingKernelMessage, %bx
	call boot1print
	call boot1printnl
	ret

boot1UMRelocatedKernel:
	mov $RelocatedKernelMessage, %bx
	call boot1print
	call boot1printnl
	ret

boot1print:
	pusha
.boot1printchar:
	mov (%bx), %al
	cmp $0x0, %al
	je .boot1printdone
	mov $0x0E, %ah
	int $0x10
	add $0x1, %bx
	jmp .boot1printchar
.boot1printdone:
	popa
	ret

boot1printnl:
    pusha
    mov $0x0E, %ah
    mov $0x0A, %al
    int $0x10
    mov $0x0D, %al
    int $0x10
    popa
    ret

boot1Halt:
	hlt
	jmp boot1Halt

.code32

boot1Start32:
	mov $GDT_DATA_SEGMENT, %eax
	mov %eax, %ds
	mov %eax, %es
	mov %eax, %fs
	mov %eax, %gs
	mov %eax, %ss
	mov $BOOT1_PROTECTED_MODE_STACK_ADDRESS, %esp                 		# Set up a new stack pointer. Ferrum places it conveniently
													# below the EBDA area.
	mov $EnteredProtectedModeMessage, %ebx				# We've landed correctly onto Protected Mode, using a new
	call boot1pmprintstring							# function that doesn't rely on BIOS Interrupts (Since we are
													# on Protected Mode, print to the screen to inform the user.
	
.ifdef LONGMODE
	# xchg %bx, %bx # DEBUG!
	xor %eax, %eax
	mov Load64Bit, %ax
	cmp $0, %ax
	je .Continue32

	call DetectCPUID
	call DetectLongMode
	
		/* Disable old paging */
	movl %cr0, %eax
	andl $NO_PAGING_BIT, %eax
	movl %eax, %cr0

	/* Clear page tables */
	movl $PAGE_TABLE_START, %edi	/* Set destination */
	xorl %eax, %eax					/* clear eax */
	movl $PAGE_TABLE_SIZE, %ecx		/* Set number of iterations */
	movl %edi, %cr3					/* Set cr3 to page table start */
	rep stosl						/* Set memory */
	movl %cr3, %edi					/* Reset destination */

	/* Populate first entry of each table */
	movl $PDPT, (%edi)
	addl $PAGE_SIZE, %edi
	movl $PDT, (%edi)
	addl $PAGE_SIZE, %edi
	movl $PT, (%edi)

	/* Map virtual to physical memory using the first page table */
	addl $PAGE_SIZE, %edi
	movl $MEM_START, %ebx
	movl $NUM_PAGES, %ecx
setEntry:
	movl %ebx, (%edi)
	addl $PAGE_SIZE, %ebx	/* Address of next page */
	addl $8, %edi			/* Address of next entry */
	loop setEntry
	
	/* Enable PAE paging */
	movl %cr4, %eax
	orl $PAE_BIT, %eax
	movl %eax, %cr4

	/* Switch to long mode */
	movl $EFER_MSR, %ecx
	rdmsr
	orl $LONG_MODE, %eax
	wrmsr

	/* Enable Paging */
	movl %cr0, %eax
	orl $PAGING_BIT, %eax
	movl %eax, %cr0

	mov $0b10101111, %al
	mov %al, (gdt_code + 6)										# We dynamically modify the GDT structure to try optimizing
	mov %al, (gdt_data + 6)										# the size, change both segment's bitmode to 32-bit.

	ljmpl $GDT_CODE_SEGMENT, $boot1Start64
	cli
	hlt
.endif
.Continue32:
	ljmp $GDT_CODE_SEGMENT, $0x100000
	cli
	hlt

.boot1pmendloop:
	hlt
	jmp .boot1pmendloop


DetectCPUID:
	pushfl
	pop %eax
	mov %eax, %ecx
	xor $(1 << 21), %eax
	push %eax
	popfl
	pushfl
	pop %eax
	push %ecx
	popfl
	xor %ecx, %eax
	jz NoCPUID
	ret

NoCPUID:
	hlt

DetectLongMode:
	mov $0x80000001, %eax
	cpuid
	test $(1 << 29), %edx
	jz NoLongMode
	ret

NoLongMode:
	hlt


boot1pmgetbioscurpos:
    xor %eax, %eax									# Set EAX to 0.
    mov 0x450, %al									# Move the bytes contained at adress 0x450 to a AL.
    mov %eax, VGA_TEXT_MODE_CURRENT_COLUMN							# Store EAX into our temporal VGA_TEXT_MODE_CURRENT_COLUMN 'buffer'.
    mov 0x451, %al									# Move the bytes contained at adress 0x451 to a AL.
    mov %eax, VGA_TEXT_MODE_CURRENT_ROW							# Store EAX into our temporal VGA_TEXT_MODE_CURRENT_ROW 'buffer'.
    mov 0x484, %al 									# Move the bytes contained at adress 0x484 to a AL.
    mov %eax, VGA_TEXT_MODE_SCREEN_HEIGHT					# Store EAX into our temporal VGA_TEXT_MODE_SCREEN_HEIGHT 'buffer'.
    mov 0x44A, %ax									# Move the bytes contained at adress 0x44A to a AX.
    mov %eax, VGA_TEXT_MODE_SCREEN_WIDTH						# Store EAX into our temporal VGA_TEXT_MODE_SCREEN_WIDTH 'buffer'.
    ret												# Return to where this function was called from.

boot1pmsetcursor: 
    mov VGA_TEXT_MODE_CURRENT_ROW, %ecx
    imul VGA_TEXT_MODE_SCREEN_WIDTH, %ecx
    add VGA_TEXT_MODE_CURRENT_COLUMN, %ecx
    mov $0x3d4, %edx
    mov $0x0f, %al
    out %al, %dx
    inc %edx
    mov %cl, %al
    out %al, %dx
    dec %edx
    mov $0x0e, %al
    out %al, %dx
    inc %edx
    mov %ch, %al
    out %al, %dx
    ret

boot1pmprintstring:
	pusha
	push %ebx
	call boot1pmgetbioscurpos
	xor %eax, %eax
	xor %ecx, %ecx
	mov VGA_TEXT_MODE_CURRENT_ROW, %eax
	mov VGA_TEXT_MODE_SCREEN_WIDTH, %ecx
	mul %ecx 		# eax*ecx=eax modded
	xor %ecx, %ecx
	mov VGA_TEXT_MODE_CURRENT_COLUMN, %ecx
	add %eax, %ecx 		# eax+ecx=ecx modded
	mov %ecx, %eax
	mov $2, %ecx
	mul %ecx 		# eax*ecx=eax modded
	mov $VGA_MEMORY_LOCATION, %ecx
	add %eax, %ecx 		# eax+ecx=ecx modded
	mov %ecx, %ebx
	mov %ebx, %edx
	pop %ebx
.boot1pmprintstringloop:
	mov (%ebx), %al
	mov $VGA_MEMORY_ATTRIBUTES, %ah
	cmp $0x0, %al
	je .boot1pmprintstringdone
	mov %ax, (%edx)
	add $0x1, %ebx
	add $0x2, %edx
	push %ecx
	mov VGA_TEXT_MODE_CURRENT_COLUMN, %ecx
	inc %ecx
	mov %ecx, VGA_TEXT_MODE_CURRENT_COLUMN
	pop %ecx
	jmp .boot1pmprintstringloop
.boot1pmprintstringdone:
	call boot1pmsetcursor
	popa
	ret

.code64

boot1Start64:
	mov $0xb8000, %edi
	mov $0x1f201f201f201f20, %rax
	mov $500, %ecx
	rep stosq

	mov $0xb8000, %edi

	mov $0x1F651F741F6e1F45, %rax    
    mov %rax, (%edi)
 
    mov $0x1F201F641F651F72, %rax
    mov %rax, 8(%edi) 
 
    mov $0x1F671F6e1F6f1F4c, %rax
    mov %rax, 16(%edi)

    mov $0x1F641F6f1F4d1F20, %rax
    mov %rax, 24(%edi)

    mov $0x1f001f001F211F65, %rax
    mov %rax, 32(%edi)

	hlt
