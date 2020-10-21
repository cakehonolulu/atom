.set KERNEL_VIRTUAL_BASE, 0xC0000000
.set KERNEL_PAGE_NUMBER, (KERNEL_VIRTUAL_BASE >> 22)

.code32				# This just acts kind of a wrapper between the boot1 second stage bootloader

.section .kernel.entry.data

.align 0x1000
BootPageDirectory:
.int 0x00000083
.fill KERNEL_PAGE_NUMBER - 1, 4, 0    
.int 0x00000083
.fill 0x400 - KERNEL_PAGE_NUMBER - 1, 4, 0

.section .kernel.entry.text,"axw",@progbits
.global _kernel_entry
_kernel_entry:
	cli

    mov $BootPageDirectory, %ecx
    mov %ecx, %cr3

    mov %cr4, %ecx
    or $0x00000010, %ecx
    mov %ecx, %cr4

    mov %cr0, %ecx
    or $0x80000000, %ecx
    mov %ecx, %cr0

    jmp _bootstrap

.section .text
.extern _kmain
.extern __bss_start
.extern __bss_sizel

.global _bootstrap

.type _bootstrap, @function
_bootstrap:
	# Null-ify the first kernel location at 1MB
    //movl $0, (BootPageDirectory)

    # Invalidate the page
    //invlpg (0)

	# Setup the kernel stack
	mov $stack_top, %esp

	# Stack is 16 byte aligned
	and $-16, %esp

	xor %eax, %eax
	mov $__bss_sizel, %ecx
	mov $__bss_start, %edi
	rep stosl

	mov $0xA1B0516C, %eax

	pushl %esp
	pushl %eax
	
	call _kmain

	# If for some reason _kmain returns, hang indefinitely
	cli
1:	hlt
	jmp 1b

.section .stack, "aw", @nobits
stack_bottom:
.skip 32768 # 32 KiB
stack_top: