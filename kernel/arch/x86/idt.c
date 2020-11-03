#include "idt.h"
#include "gdt.h"
#include "utils.h"

void arch_set_idt_gate(int i386_idt_entry_num, unsigned int i386_idt_handler)
{
    i386_idt[i386_idt_entry_num].offset0_15 = low_16(i386_idt_handler);
    i386_idt[i386_idt_entry_num].selector = ARCH_GDT_KERNEL_CODE_SEGMENT_SELECTOR;
    i386_idt[i386_idt_entry_num].zero = 0;
    i386_idt[i386_idt_entry_num].type_attr = 0x8E; 
    i386_idt[i386_idt_entry_num].offset16_31 = high_16(i386_idt_handler);
}

unsigned int arch_idt_install()
{
    i386_idt_pointer.base = (unsigned int) &i386_idt;
    i386_idt_pointer.limit = IDT_ENTRIES * sizeof(struct i386_idt_entry) - 1;

    return 1;
}

unsigned int arch_update_idt()
{
    /* Don't make the mistake of loading &idt -- always load &idt_reg */
    arch_idt_update((unsigned int)&i386_idt_pointer);

    return 1;
}
