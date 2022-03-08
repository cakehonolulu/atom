.include "boot1.S"

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


arch_x86_setup_long_mode:
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
	jz NO_LONG_MODE
	ret

NO_LONG_MODE:
	hlt


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

