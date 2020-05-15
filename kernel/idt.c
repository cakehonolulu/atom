#include "idt.h"
#include "gdt.h"
#include "utils.h"

void set_idt_gate(int i386_idt_entry_num, unsigned int i386_idt_handler)
{
    i386_idt[i386_idt_entry_num].offset0_15 = low_16(i386_idt_handler);
    i386_idt[i386_idt_entry_num].selector = i386_GDT_KERNEL_CODE_SEGMENT_SELECTOR;
    i386_idt[i386_idt_entry_num].zero = 0;
    i386_idt[i386_idt_entry_num].type_attr = 0x8E; 
    i386_idt[i386_idt_entry_num].offset16_31 = high_16(i386_idt_handler);
}

void set_idt()
{
    i386_idt_pointer.base = (unsigned int) &i386_idt;
    i386_idt_pointer.limit = IDT_ENTRIES * sizeof(struct i386_idt_entry) - 1;
    /* Don't make the mistake of loading &idt -- always load &idt_reg */
    __asm__ __volatile__("lidtl (%0)" : : "r" (&i386_idt_pointer));
}