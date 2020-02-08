.code32
.set BOOT1PMVMEM, 0xb8000
.set BOOT1PMVMEMC, 0x0f

.align 4
boot1_currow: .long 0x00
boot1_curcol: .long 0x00
boot1_screenwidth: .long 0x00
boot1_screenheight:.long 0x00
.section .text

.global main
main:
	mov $.kernelLandedMessage, %ebx
	call boot1pmprintstring
	cli
	hlt

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

.kernelLandedMessage: .asciz "Landed on Kernel!"
