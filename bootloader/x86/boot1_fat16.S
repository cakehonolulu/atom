# Thanks to Octocontrabass, Combuster and MichaelPetch for the help @ forum.osdev.org
.global init1

.code16

.section .kernel_discard

.global I386_KERNEL_SIZE
kernel_start:
    # Insert kernel binary here. It is done this way since we
    # can determine the size(and number of sectors) to load since
    #     Size = kernel_end-kernel_start
    .incbin "../../kernel/arch/x86/kernel.bin"

# End of stage2. Make sure this label is LAST in this file!
kernel_end:
.set I386_KERNEL_SIZE, (kernel_end - kernel_start + 511) / 512

.section .text

init1:
	mov $StageTwoLoaded, %bx								# Print a message that tells we're currently on second stage bootloader.

	call boot1print
	call boot1printnl

	call boot1EnableA20

	cli
	hlt


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

boot1A20HasBeenEnabled:
	mov $A20EnabledMessage, %bx
	call boot1print
	call boot1printnl
	ret

boot1A20HasAlreadyBeenEnabled:
	mov $A20AlreadyEnabledMessage, %bx
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

.section .data
/* Bootloader Strings */
A20AlreadyEnabledMessage: .asciz "A20 Line is already enabled, skipping..." // Bochs for example, enables it regardless the OS
A20EnabledMessage: .asciz "A20 Line enabled Successfully!"

StageTwoLoaded: .asciz "[IF16] Entered Stage 2"
