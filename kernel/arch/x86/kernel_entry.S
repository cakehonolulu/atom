# This just acts kind of a wrapper between the boot1 second stage bootloader

# Make the Stack Size
#define STACK_SIZE 8192

.set KERNEL_VIRTUAL_BASE, 0xC0000000
.set KERNEL_PAGE_NUMBER, (KERNEL_VIRTUAL_BASE >> 22)

.global arch_higher_half_pd

.section .kernel.entry.data

.align 4096

arch_higher_half_pd:
    # Setup a Page Directory entry to Identity Map the first 4 MB of the 32
    # bit physical address space. We do this so that when we enable
    # paging, we don't crash due to the kernel still being executing 
    # instructions that are being fetched still from the physical address space. 
    # BIT 7: PS 4MB Page Size
    # BIT 1: RW Read/Write BIT
    # BIT 0: P  Page Present BIT
    # TLDR: The bits set are 4MB Pages, Read/Write and Present.
	.long 0x00000083

    # This are the pages before the Kernel Space Pages
	.rept (KERNEL_PAGE_NUMBER - 1)
    .long 0 
    .endr

    # Setup the Higher-Half Pages for Kernel to use
    # TODO: If Kernel someday grows more than 4MB, we MAY have to map
    # more pages!
    # One of many ways to do it:
    #.long 0x00000083 <- Original Kernel Page Directoy
    #.long 0x00000083 | (1 << 22)
    #.long 0x00000083 | (2 << 22)
    #.long 0x00000083 | (3 << 22)
    #.long 0x00000083 | (4 << 22)
    #.long 0x00000083 | (5 << 22)
    #.long 0x00000083 | (6 << 22)
    # And so on...
    .long 0x00000083

     # Fill all the rest of the pages with null pages after the Kernel Space Pages
    .rept (1024 - KERNEL_PAGE_NUMBER - 1)
    .long 0
    .endr

.section .kernel.entry.text,"axw",@progbits
.align 16

.global _kernel_entry
_kernel_entry:
	cli # We're going to deal with paging, let's disable interrupts

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
	# Nullify the page directory that contains the kernel identity map
    movl $0, (arch_higher_half_pd)

    # Invalidate the page containing the identity map of the kernel
    invlpg (0)

    # Clear direction flag just for sanity pruposes
    cld

	# Setup the kernel stack
	mov $stack_top, %esp

    # Zero out the bss section
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

# Declare a stack for C, mark it as allocatable (a) and writable (w);
# use the nobits typing to declare the section as non-data containing
# so that it knows it only occupies space
.section .bss, "aw", @nobits
# Stack is 16 byte aligned to ensure proper SystemV ABI compliance
.align 16
stack_bottom:
.skip STACK_SIZE # 16 KiB // TODO: Let the user change bootstrap stack (Maybe it's trying to run Atom on a machine with more limited resources where 16KB makes a world of a difference)
stack_top: