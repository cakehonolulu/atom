# Thanks to Octocontrabass, Combuster and MichaelPetch for the help @ forum.osdev.org
.code16

.global init1

.set BOOT1CODESEGMENT, 0x7E00
.set BOOT1PMSTACK, 0x9c000
.set BOOT1PMVMEM, 0xb8000
.set BOOT1PMVMEMC, 0x0f

.section .data
unreal_mode_gdt_start:
unreal_mode_gdt_null:
	.long 0
	.long 0
unreal_mode_gdt_code:
	.word 0xFFFF
	.word 0x0
	.byte 0x0
	.byte 0b10011010
	.byte 0b10001111
	.byte 0x0

unreal_mode_gdt_data:
	.word 0xffff
	.word 0x0
	.byte 0x0
	.byte 0b10010010
	.byte 0b10001111
	.byte 0x0

unreal_mode_gdt_end:
.set UNREAL_MODE_CODE_SEG, unreal_mode_gdt_code - unreal_mode_gdt_start
.set UNREAL_MODE_DATA_SEG, unreal_mode_gdt_data - unreal_mode_gdt_start

unreal_mode_gdt:
        .word (unreal_mode_gdt_end - unreal_mode_gdt_start - 1)
        .long unreal_mode_gdt_start

protected_mode_gdt_start:
protected_mode_gdt_null:
	.long 0
	.long 0

protected_mode_gdt_code:
	.word 0xFFFF
	.word 0x0
	.byte 0x0
	.byte 0b10011010
	.byte 0b11001111
	.byte 0x0

protected_mode_gdt_data:
	.word 0xffff
	.word 0x0
	.byte 0x0
	.byte 0b10010010
	.byte 0b11001111
	.byte 0x0

protected_mode_gdt_end:
.set PROTECTED_MODE_CODE_SEG, protected_mode_gdt_code - protected_mode_gdt_start
.set PROTECTED_MODE_DATA_SEG, protected_mode_gdt_data - protected_mode_gdt_start

protected_mode_gdt:
        .word (protected_mode_gdt_end - protected_mode_gdt_start - 1)
        .long protected_mode_gdt_start

.boot1A20HasAlreadyBeenEnabled: .asciz "A20 Line has already been enabled"
.boot1A20HasBeenEnabled: .asciz "A20 Line Enabled"
.boot1LoadedMessage: .asciz "Entered 2nd Stage"
.boot1LoadedProtectedModeGDTMessage: .asciz "Protected Mode GDT Loaded"
.boot1LoadedUnrealModeGDTMessage: .asciz "Unreal Mode GDT Loaded"
.boot1LoadedPMMessage: .asciz "Entered Protected Mode"
.boot1LoadedUMMessage: .asciz "Entered Unreal Mode"
.boot1UMLoadingKernelMessage: .asciz "Loading Kernel..."
.boot1DiskErrorMessage: .asciz "Disk Read Error!"
.boot1UMLKMsg: .asciz "Loaded Kernel"

.align 4
boot1_currow: .long 0x00
boot1_curcol: .long 0x00
boot1_screenwidth: .long 0x00
boot1_screenheight:.long 0x00
.section .text

init1:
	xor %ax, %ax
	mov %ax, %ds
	call boot1LoadedMessage
	call boot1EnableA20
	call boot1LoadUnrealModeGDT
	cli
	mov %cr0, %eax
	or $1, %eax
	mov %eax, %cr0
	ljmpl $UNREAL_MODE_CODE_SEG, $.boot1TemporalProtected
.hlt:
	hlt
	jmp .hlt

.boot1TemporalProtected:				# Now in protected mode
	mov $0x10, %ax
	mov %ax, %ds
	mov %ax, %es
	mov %ax, %fs
	mov %ax, %gs
	mov %ax, %ss
	mov %cr0, %eax						# Exit protected mode
	and $0b11111110, %eax
	mov %eax, %cr0
	jmp $0x0000, $.boot1UnrealMode
.boot1UnrealMode:						# Now in Unreal Mode
	xor %ax, %ax
	mov %ax, %ds
	mov %ax, %es
	mov %ax, %fs
	mov %ax, %gs
	mov %ax, %ss
	mov $0x7BF0, %sp
	sti									# Enable interrupts
	call boot1LandedUnrealMode
	call boot1UMLoadingKernel

boot1UMLoadKernel:
	mov $0x02, %ah									# Set ah to 2 (AH=0x02 -> Disk Read Function).
	mov $0x12, %al						# Set al to I386_KERNEL_SIZE (AL=$I386_KERNEL_SIZE0h) -> Sectors to be readed.
													# Where I386_KERNEL_SIZE equals to the number of sectors occupied by the kernel binary rounded 1 sector up.
	mov $0x0, %ch									# Set ch to 0 (CH=0x00) -> Track 0 of the drive.
	mov $0x4, %cl			# Set cl to I386_KERNEL_STARTING_LOCATION (CL=I386_KERNEL_STARTING_LOCATION)
													# Which is sector of the drive from which we start reading the kernel from.
	mov $0x00, %dh									# Set dh to 0 (DH=0x00) -> Head 0 of the drive.
	xor %bx, %bx									# Set bx to 0.
	mov %bx, %es									# Move bx onto our extra segment register to prepare the jump.
	mov $0x1000, %bx								# Set our bx register with the adress we'll jump to.
	int $0x13										# Call BIOS interrupt 13.


	mov $0x1000, %esi
	mov $0x100000, %edi
	mov $0x200, %cx
	mov $0x14, %bx
.loop:
	xchg %bx, %bx
	addr32 rep movsb
	dec %bx
	jnz .loop
	mov $0, %ax
.done:
	call boot1UMLK

	call boot1LoadProtectedModeGDT
	cli
	mov %cr0, %eax
	or $1, %eax
	mov %eax, %cr0
	cli
	ljmpl $PROTECTED_MODE_CODE_SEG, $boot1Start32
.hltu:
	hlt
	jmp .hltu



boot1EnableA20:
	call boot1CheckA20LineState			# Check if A20 Line is enabled.
	jnz boot1A20HasAlreadyBeenEnabled	# Jump if condition is met.

	movw $0x2401, %ax					# Enable A20 Line using the BIOS Method.
	stc									# Set carry flag.
	int	$0x15							# Call BIOS interrupt 15 (Enable A20 Line).
	jc 1f								# BIOS Method failed.
	testb %ah, %ah						# Compares both registers.
	jne 1f								# Jumps if they're not equal.
	call boot1CheckA20LineState			# Check if A20 Line is enabled.
	jnz boot1A20HasBeenEnabled			# Jump if condition is met.
1:										# Enable A20 Line using Intel's 8042 Controller Method.
	call .boot1_8042_wait				# Wait for Intel's 8042 controller to be ready.
	movb $0xd1, %al						# Prepare the 8042 port write.
	outb %al, $0x64						# Write to the 8042 port.
	call .boot1_8042_wait				# Wait for Intel's 8042 controller to be ready.
	movb $0xdf, %al						# Prepare the 8042 port write.
	outb %al, $0x60						# Enable A20 Line.
	call .boot1_8042_wait				# Wait for Intel's 8042 controller to be ready.
	call boot1CheckA20LineState			# Check if A20 Line is enabled.
	jnz	boot1A20HasBeenEnabled			# Jump if condition is met.
										# Enable A20 Line using the 'Fast' Method.
	inb $0x92, %al						# Try the computer's Fast A20 Gate.
	testb $0x02, %al 					# Compare both values.
	jnz 1f								# Don't enable A20 if it's already set.
	orb $0x02, %al						# Check wether the A20 Gate Enable Bit...
	andb $0xfe, %al						# ...is set or not.
	outb %al, $0x92						# Enable the A20 Line using the Fast Gate.
1:
	call boot1CheckA20LineState			# Check if A20 Line is enabled.
	jnz boot1A20HasBeenEnabled			# Jump if condition is met.
	jmp 1b								# Check until A20 Line is set.

.boot1_8042_wait:						# Function that waits for Intel's 8042 controller to be ready.
	inb	$0x64, %al						# Read 8042's status.
	testb $0x02, %al					# Test if bit 1 is zero.
	jnz .boot1_8042_wait				# Jump if condition is met.
	ret									# Return to parent function.

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

boot1LoadProtectedModeGDT:
	cli
	pusha
	lgdt protected_mode_gdt
	sti
	popa
	call boot1LoadedProtectedModeGDTMessage
	ret

boot1LoadUnrealModeGDT:
	cli
	pusha
	lgdt unreal_mode_gdt
	sti
	popa
	call boot1LoadedUnrealModeGDTMessage
	ret

boot1A20HasBeenEnabled:
	mov $.boot1A20HasBeenEnabled, %bx
	call boot1print
	call boot1printnl
	ret

boot1UMLK:
	mov $.boot1UMLKMsg, %bx
	call boot1print
	call boot1printnl
	ret

boot1A20HasAlreadyBeenEnabled:
	mov $.boot1A20HasAlreadyBeenEnabled, %bx
	call boot1print
	call boot1printnl
	ret

boot1LoadedMessage:
	mov $.boot1LoadedMessage, %bx
	call boot1print
	call boot1printnl
	ret

boot1LoadedProtectedModeGDTMessage: 
	mov $.boot1LoadedProtectedModeGDTMessage, %bx
	call boot1print
	call boot1printnl
	ret

boot1LoadedUnrealModeGDTMessage: 
	mov $.boot1LoadedUnrealModeGDTMessage, %bx
	call boot1print
	call boot1printnl
	ret

boot1LandedUnrealMode: 
	mov $.boot1LoadedUMMessage, %bx
	call boot1print
	call boot1printnl
	ret

boot1UMLoadingKernel:
	mov $.boot1UMLoadingKernelMessage, %bx
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

.code32
.extern main

boot1Start32:
	mov $PROTECTED_MODE_DATA_SEG, %eax
	mov %eax, %ds
	mov %eax, %es
	mov %eax, %fs
	mov %eax, %gs
	mov %eax, %ss
	mov $BOOT1PMSTACK, %esp                 # Set up a new stack pointer. Ferrum places it conveniently
											# below the EBDA area.
	mov $.boot1LoadedPMMessage, %ebx		# We've landed correctly onto Protected Mode, using a new
	call boot1pmprintstring					# function that doesn't rely on BIOS Interrupts (Since we are
											# on Protected Mode, print to the screen to inform the user.
	xor %eax, %eax
	mov $0xFEB0516C, %eax
	push %eax
	jmp 0x100000

.boot1pmendloop:
        hlt
        jmp .boot1pmendloop

boot1pmgetbioscurpos:
    xor %eax, %eax							# Set EAX to 0.
    mov 0x450, %al							# Move the bytes contained at adress 0x450 to a AL.
    mov %eax, boot1_curcol					# Store EAX into our temporal boot1_curcol 'buffer'.
    mov 0x451, %al							# Move the bytes contained at adress 0x451 to a AL.
    mov %eax, boot1_currow					# Store EAX into our temporal boot1_currow 'buffer'.
    mov 0x484, %al 							# Move the bytes contained at adress 0x484 to a AL.
    mov %eax, boot1_screenheight			# Store EAX into our temporal boot1_screenheight 'buffer'.
    mov 0x44A, %ax							# Move the bytes contained at adress 0x44A to a AX.
    mov %eax, boot1_screenwidth				# Store EAX into our temporal boot1_screenwidth 'buffer'.
    ret										# Return to where this function was called from.

boot1pmsetcursor: 
    mov boot1_currow, %ecx
    imul boot1_screenwidth, %ecx
    add boot1_curcol, %ecx
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
	mov boot1_currow, %eax
	mov boot1_screenwidth, %ecx
	mul %ecx # eax*ecx=eax modded
	xor %ecx, %ecx
	mov boot1_curcol, %ecx
	add %eax, %ecx # eax+ecx=ecx modded
	mov %ecx, %eax
	mov $2, %ecx
	mul %ecx # eax*ecx=eax modded
	mov $BOOT1PMVMEM, %ecx
	add %eax, %ecx # eax+ecx=ecx modded
	mov %ecx, %ebx
	mov %ebx, %edx
	pop %ebx
.boot1pmprintstringloop:
	mov (%ebx), %al
	mov $BOOT1PMVMEMC, %ah
	cmp $0x0, %al
	je .boot1pmprintstringdone
	mov %ax, (%edx)
	add $0x1, %ebx
	add $0x2, %edx
	push %ecx
	mov boot1_curcol, %ecx
	inc %ecx
	mov %ecx, boot1_curcol
	pop %ecx
	jmp .boot1pmprintstringloop
.boot1pmprintstringdone:
	call boot1pmsetcursor
	popa
	ret
