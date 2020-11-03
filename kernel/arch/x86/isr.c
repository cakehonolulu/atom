#include "isr.h"

isr_t interrupt_handlers[256];

unsigned int arch_isr_install() {
    arch_set_idt_gate(0, (unsigned int)isr0);
    arch_set_idt_gate(1, (unsigned int)isr1);
    arch_set_idt_gate(2, (unsigned int)isr2);
    arch_set_idt_gate(3, (unsigned int)isr3);
    arch_set_idt_gate(4, (unsigned int)isr4);
    arch_set_idt_gate(5, (unsigned int)isr5);
    arch_set_idt_gate(6, (unsigned int)isr6);
    arch_set_idt_gate(7, (unsigned int)isr7);
    arch_set_idt_gate(8, (unsigned int)isr8);
    arch_set_idt_gate(9, (unsigned int)isr9);
    arch_set_idt_gate(10, (unsigned int)isr10);
    arch_set_idt_gate(11, (unsigned int)isr11);
    arch_set_idt_gate(12, (unsigned int)isr12);
    arch_set_idt_gate(13, (unsigned int)isr13);
    arch_set_idt_gate(14, (unsigned int)isr14);
    arch_set_idt_gate(15, (unsigned int)isr15);
    arch_set_idt_gate(16, (unsigned int)isr16);
    arch_set_idt_gate(17, (unsigned int)isr17);
    arch_set_idt_gate(18, (unsigned int)isr18);
    arch_set_idt_gate(19, (unsigned int)isr19);
    arch_set_idt_gate(20, (unsigned int)isr20);
    arch_set_idt_gate(21, (unsigned int)isr21);
    arch_set_idt_gate(22, (unsigned int)isr22);
    arch_set_idt_gate(23, (unsigned int)isr23);
    arch_set_idt_gate(24, (unsigned int)isr24);
    arch_set_idt_gate(25, (unsigned int)isr25);
    arch_set_idt_gate(26, (unsigned int)isr26);
    arch_set_idt_gate(27, (unsigned int)isr27);
    arch_set_idt_gate(28, (unsigned int)isr28);
    arch_set_idt_gate(29, (unsigned int)isr29);
    arch_set_idt_gate(30, (unsigned int)isr30);
    arch_set_idt_gate(31, (unsigned int)isr31);

    return 1;
}

/* To print the message which defines every exception */
char *exception_messages[] = {
    "Division By Zero",
    "Debug",
    "Non Maskable Interrupt",
    "Breakpoint",
    "Into Detected Overflow",
    "Out of Bounds",
    "Invalid Opcode",
    "No Coprocessor",

    "Double Fault",
    "Coprocessor Segment Overrun",
    "Bad TSS",
    "Segment Not Present",
    "Stack Fault",
    "General Protection Fault",
    "Page Fault",
    "Unknown Interrupt",

    "Coprocessor Fault",
    "Alignment Check",
    "Machine Check",
    "Reserved",
    "Reserved",
    "Reserved",
    "Reserved",
    "Reserved",

    "Reserved",
    "Reserved",
    "Reserved",
    "Reserved",
    "Reserved",
    "Reserved",
    "Reserved",
    "Reserved"
};

void isr_handler(registers_t *r) {
    if (interrupt_handlers[r->int_no] != 0)
    {
        isr_t handler = interrupt_handlers[r->int_no];
        handler(&r);
    }
    else
    {
        printk("Unhandled Interrupt: 0x%x\n", r->int_no);
    }
}

void register_interrupt_handler(unsigned char n, isr_t handler) {
    interrupt_handlers[n] = handler;
}
