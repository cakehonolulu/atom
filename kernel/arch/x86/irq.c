#include "isr.h"

extern isr_handler_t interrupt_handlers[256];

unsigned int arch_pic_remap()
{
    // Remap the PIC
    outb(0x20, 0x11);
    outb(0xA0, 0x11);
    outb(0x21, 0x20);
    outb(0xA1, 0x28);
    outb(0x21, 0x04);
    outb(0xA1, 0x02);
    outb(0x21, 0x01);
    outb(0xA1, 0x01);
    outb(0x21, 0x0);
    outb(0xA1, 0x0);

    return 1;
}

unsigned int arch_enable_interrupts() {
    /* Enable interruptions */
    __asm__ __volatile__("sti");

    return 1;
}

unsigned int arch_irq_install()
{
    if (arch_pic_remap() == 1)
    {
        printkok("Remapped PIC");
    } else {
        printkfail("Failed to remap PIC");
    }

    // Install the IRQs
    arch_set_idt_gate(32, (unsigned int)irq0);
    arch_set_idt_gate(33, (unsigned int)irq1);
    arch_set_idt_gate(34, (unsigned int)irq2);
    arch_set_idt_gate(35, (unsigned int)irq3);
    arch_set_idt_gate(36, (unsigned int)irq4);
    arch_set_idt_gate(37, (unsigned int)irq5);
    arch_set_idt_gate(38, (unsigned int)irq6);
    arch_set_idt_gate(39, (unsigned int)irq7);
    arch_set_idt_gate(40, (unsigned int)irq8);
    arch_set_idt_gate(41, (unsigned int)irq9);
    arch_set_idt_gate(42, (unsigned int)irq10);
    arch_set_idt_gate(43, (unsigned int)irq11);
    arch_set_idt_gate(44, (unsigned int)irq12);
    arch_set_idt_gate(45, (unsigned int)irq13);
    arch_set_idt_gate(46, (unsigned int)irq14);
    arch_set_idt_gate(47, (unsigned int)irq15);

    return 1;
}

void irq_handler(registers_t *r) {
    /* After every interrupt we need to send an EOI to the PICs
     * or they will not send another interrupt again */
    if (r->int_no >= 40) outb(0xA0, 0x20); /* slave */
    outb(0x20, 0x20); /* master */

    /* Handle the interrupt in a more modular way */
    if (interrupt_handlers[r->int_no] != 0) {
        isr_handler_t handler = interrupt_handlers[r->int_no];
        handler(&r);
    }
}
