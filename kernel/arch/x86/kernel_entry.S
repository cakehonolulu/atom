# This just acts kind of a wrapper between the boot1 second stage bootloader

.set KERNEL_VIRTUAL_BASE, 0xC0000000
.set KERNEL_PAGE_NUMBER, (KERNEL_VIRTUAL_BASE >> 22)
.set KERNEL_NUM_UPPER_PAGES, 7

.global arch_higher_half_pd

.section .kernel.entry.data

.align 4096

# Temporary page directory entry to identity-map the first 4 MiB of the 32
# bit physical address space. We have this here so that when we enable
# paging, we don't crash. Add more page tables as needed if kernel is too big
# to fit (more than 3 MiB). The bits set are 4MiB, read-write and present.
arch_higher_half_pd:
	.long 0x00000083
	.fill (KERNEL_PAGE_NUMBER - 1), 4
    # Set higher half pages, starting from 0 and increasing by 4MiB
    .long 0x00000083
    .long 0x00000083 | (1 << 22)
    .long 0x00000083 | (2 << 22)
    .long 0x00000083 | (3 << 22)
    .long 0x00000083 | (4 << 22)
    .long 0x00000083 | (5 << 22)
    .long 0x00000083 | (6 << 22)
     # Fill all succeeding pages with 4 bytes
    .fill (1024 - KERNEL_PAGE_NUMBER - KERNEL_NUM_UPPER_PAGES), 4

.section .kernel.entry.text,"axw",@progbits
.align 16

.global _kernel_entry
_kernel_entry:
	cli

    mov $arch_higher_half_pd, %ecx
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
    movl $0, (arch_higher_half_pd)

    # Invalidate the page
    invlpg (0)

	# Setup the kernel stack
	mov $stack_top, %esp

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

.section .bss
# Stack is 16 byte aligned
.align 16
stack_bottom:
.skip 16384 # 16 KiB
stack_top: