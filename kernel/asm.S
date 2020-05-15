.code32
.section .data
i386_GDT_KERNEL_CODE_SEGMENT_SELECTOR: .long 0x00
.section .text
.global i386_gdt_update
i386_gdt_update:
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
    mov %eax, i386_GDT_KERNEL_CODE_SEGMENT_SELECTOR # ...and we'll also save it for future use.
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
