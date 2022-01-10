.code32

.section .data
ARCH_GDT_KERNEL_CODE_SEGMENT_SELECTOR: .long 0x00

.section .text

.global arch_idt_update
arch_idt_update:
    mov 4(%esp), %eax       # IDT Pointer ()
    lidt (%eax)             # Update the IDT with IDT record pointer passed as 1st argument.
    ret

.global set_page_directory
set_page_directory:
    push %ebp
    mov %esp, %ebp
    mov 8(%ebp), %eax
    mov %eax, %cr3
    pop %ebp
    ret

.global arch_gdt_update
arch_gdt_update:
	/* Load GDT */
	// Found this solution on StackOverflow, thanks MichaelPetch again!
	# So before landing here, we pushed 3 arguments to the stack:
	# arg[0]: struct i386_gdt_descriptor *i386_gdt_pointer
	# Which holds a pointer to the crafted GDT structure that lgdt will use lo update
	# the GDT-related stuff.
	# arg[1]: unsigned int i386_gdt_code_segment
	# Which holds the value of the GDT's Code Segment Selector.
	# arg[2]: unsigned int i386_gdt_data_segment
	# Which holds the value of the GDT's Data Segment Selector.

    mov 4(%esp), %edx		# GDT Pointer ()
    mov 12(%esp), %eax		# We'll place the Data Segment Selector (3rd Argument) on EAX...
    mov %eax, ARCH_GDT_KERNEL_CODE_SEGMENT_SELECTOR # ...and we'll also save it for future use.
    lgdt (%edx)				# Update the GDT with GDT record pointer passed as 1st argument.
    mov %eax, %ds			# Reload all the segment descriptors with EAX (Now containing
    						# Data Segment Selector, the 3rd Argument).
    mov %eax, %es
    mov %eax, %gs
    mov %eax, %fs
    mov %eax, %ss

    pushl 8(%esp)								# We will now push Code Segment Selector (3rd Argument) to the stack.
    											# NOTE: This will act as a Far Jump Pointer.
    push $.i386_gdt_update_set_code_segment		# The offset for the Far Jump's Function will be i386_gdt_update_set_code_segment
    											# label below, which is a specially crafted function that "clears out" the stack
    											# after using the argument's values. 
    ljmp *(%esp)								# Actually Far Jump to set the Code Segment Selector and the Instruction Pointer to
    											# the offset of i386_gdt_update_set_code_segment
.i386_gdt_update_set_code_segment:				# "Restore Stack" Subroutine:
    add $8, %esp								# We will remove both pushed stack values that contain the Segment Registers Information
												# that were used to craft the Pointers used in the Far Jump.
    ret											# Return to C

# Defined in isr.c
.extern arch_isr_handler
.extern arch_irq_handler

# Common ISR code
isr_common_stub: 
   /* Push all registers */
    pusha

    /* Save segment registers */
    push %ds
    push %es
    push %fs
    push %gs
    mov ARCH_GDT_KERNEL_CODE_SEGMENT_SELECTOR, %ax
    mov %ax, %ds
    mov %ax, %es
    mov %ax, %fs
    mov %ax, %gs
    cld

    /* Call fault handler */
    push %esp
    call arch_isr_handler
    add $4, %esp

    /* Restore segment registers */
    pop %gs
    pop %fs
    pop %es
    pop %ds

    /* Restore registers */
    popa
    /* Cleanup error code and ISR # */
    add $8, %esp
    /* pop CS, EIP, EFLAGS, SS and ESP */
    iret

# Common IRQ code. Identical to ISR code except for the 'call' 
# and the 'pop ebx'
irq_common_stub: 
    /* Save all registers */
    pusha

    /* Save segment registers */
    push %ds
    push %es
    push %fs
    push %gs
    mov ARCH_GDT_KERNEL_CODE_SEGMENT_SELECTOR, %ax
    mov %ax, %ds
    mov %ax, %es
    mov %ax, %fs
    mov %ax, %gs
    cld

    /* Call interrupt handler */
    push %esp
    call arch_irq_handler
    add $4, %esp

    /* Restore segment registers */
    pop %gs
    pop %fs
    pop %es
    pop %ds

    /* Restore all registers */
    popa
    /* Cleanup error code and IRQ # */
    add $8, %esp
    /* pop CS, EIP, EFLAGS, SS and ESP */
    iret

# We don't get information about which interrupt was caller
# when the handler is run, so we will need to have a different handler
# for every interrupt.
# Furthermore, some interrupts push an error code onto the stack but others
# don't, so we will push a dummy error code for those which don't, so that
# we have a consistent stack for all of them.

# First make the ISRs global
.global isr0
.global isr1
.global isr2
.global isr3
.global isr4
.global isr5
.global isr6
.global isr7
.global isr8
.global isr9
.global isr10
.global isr11
.global isr12
.global isr13
.global isr14
.global isr15
.global isr16
.global isr17
.global isr18
.global isr19
.global isr20
.global isr21
.global isr22
.global isr23
.global isr24
.global isr25
.global isr26
.global isr27
.global isr28
.global isr29
.global isr30
.global isr31
# IRQs
.global irq0
.global irq1
.global irq2
.global irq3
.global irq4
.global irq5
.global irq6
.global irq7
.global irq8
.global irq9
.global irq10
.global irq11
.global irq12
.global irq13
.global irq14
.global irq15

# 0: Divide By Zero Exception
isr0: 
    push $0
    push $0
    jmp isr_common_stub

# 1: Debug Exception
isr1: 
    push $0
    push $1
    jmp isr_common_stub

# 2: Non Maskable Interrupt Exception
isr2: 
    push $0
    push $2
    jmp isr_common_stub

# 3: Int 3 Exception
isr3: 
    push $0
    push $3
    jmp isr_common_stub

# 4: INTO Exception
isr4: 
    push $0
    push $4
    jmp isr_common_stub

# 5: Out of Bounds Exception
isr5: 
    push $0
    push $5
    jmp isr_common_stub

# 6: Invalid Opcode Exception
isr6: 
    push $0
    push $6
    jmp isr_common_stub

# 7: Coprocessor Not Available Exception
isr7: 
    push $0
    push $7
    jmp isr_common_stub

# 8: Double Fault Exception (With Error Code!)
isr8: 
    push $8
    jmp isr_common_stub

# 9: Coprocessor Segment Overrun Exception
isr9: 
    push $0
    push $9
    jmp isr_common_stub

# 10: Bad TSS Exception (With Error Code!)
isr10: 
    push $10
    jmp isr_common_stub

# 11: Segment Not Present Exception (With Error Code!)
isr11: 
    push $11
    jmp isr_common_stub

# 12: Stack Fault Exception (With Error Code!)
isr12: 
    push $12
    jmp isr_common_stub

# 13: General Protection Fault Exception (With Error Code!)
isr13: 
    push $13
    jmp isr_common_stub

# 14: Page Fault Exception (With Error Code!)
isr14: 
    push $14
    jmp isr_common_stub

# 15: Reserved Exception
isr15: 
    push $0
    push $15
    jmp isr_common_stub

# 16: Floating Point Exception
isr16: 
    push $0
    push $16
    jmp isr_common_stub

# 17: Alignment Check Exception
isr17: 
    push $0
    push $17
    jmp isr_common_stub

# 18: Machine Check Exception
isr18: 
    push $0
    push $18
    jmp isr_common_stub

# 19: Reserved
isr19: 
    push $0
    push $19
    jmp isr_common_stub

# 20: Reserved
isr20: 
    push $0
    push $20
    jmp isr_common_stub

# 21: Reserved
isr21: 
    push $0
    push $21
    jmp isr_common_stub

# 22: Reserved
isr22: 
    push $0
    push $22
    jmp isr_common_stub

# 23: Reserved
isr23: 
    push $0
    push $23
    jmp isr_common_stub

# 24: Reserved
isr24: 
    push $0
    push $24
    jmp isr_common_stub

# 25: Reserved
isr25: 
    push $0
    push $25
    jmp isr_common_stub

# 26: Reserved
isr26: 
    push $0
    push $26
    jmp isr_common_stub

# 27: Reserved
isr27: 
    push $0
    push $27
    jmp isr_common_stub

# 28: Reserved
isr28: 
    push $0
    push $28
    jmp isr_common_stub

# 29: Reserved
isr29: 
    push $0
    push $29
    jmp isr_common_stub

# 30: Reserved
isr30: 
    push $0
    push $30
    jmp isr_common_stub

# 31: Reserved
isr31: 
    push $0
    push $31
    jmp isr_common_stub

# IRQ handlers
irq0: 
        push $0
        push $32
        jmp irq_common_stub

irq1: 
        push $1
        push $33
        jmp irq_common_stub

irq2: 
        push $2
        push $34
        jmp irq_common_stub

irq3: 
        push $3
        push $35
        jmp irq_common_stub

irq4: 
        push $4
        push $36
        jmp irq_common_stub

irq5: 
        push $5
        push $37
        jmp irq_common_stub

irq6: 
        push $6
        push $38
        jmp irq_common_stub

irq7: 
        push $7
        push $39
        jmp irq_common_stub

irq8: 
        push $8
        push $40
        jmp irq_common_stub

irq9: 
        push $9
        push $41
        jmp irq_common_stub

irq10: 
        push $10
        push $42
        jmp irq_common_stub

irq11: 
        push $11
        push $43
        jmp irq_common_stub

irq12: 
        push $12
        push $44
        jmp irq_common_stub

irq13: 
        push $13
        push $45
        jmp irq_common_stub

irq14: 
        push $14
        push $46
        jmp irq_common_stub

irq15: 
        push $15
        push $47
        jmp irq_common_stub

.global tss_flush
.type tss_flush, @function

tss_flush:
    mov $0x2B, %ax
    ltr %ax
    ret

.global tlb_flush
.type tlb_flush, @function
tlb_flush:
    movl %cr3, %ecx
    movl %ecx, %cr3
    ret

.global arch_switch_task
arch_switch_task:
    # Disable interrupts to avoid being interrupted mid-switch
    cli
    # Push current values so that they are popped off when we switch back to the current task
    # The other general purpose registers are pushed by the C calling convention
    push %ebx
    push %esi
    push %ebp
    push %edi
    # Get the current proc's state
    mov 20(%esp), %edi
    # Get the next proc's state
    mov 24(%esp), %esi
    # Changes to arch_cpu_state_t may require adjustments to the offset here
    # Save the stack pointer into the current proc's state at arch_cpu_state_t.esp
    mov %esp, 28(%edi)
    # Restore the stack pointer from the next proc's state from arch_cpu_state_t.esp
    mov 28(%esi), %esp
    # From now on we are using the next proc's stack

    # Pop off saved values from next proc's stack
    # The other general purpose registers are popped by the C calling convention
    pop %edi
    pop %ebp
    pop %esi
    pop %ebx
    # Re-enable interrupts
    sti
    # Return to return address stored at start of next proc's stack
    ret

.global arch_get_stack_pointer
arch_get_stack_pointer:
    mov %esp, %eax
    ret
