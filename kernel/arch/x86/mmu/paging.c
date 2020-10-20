#include "isr.h"
#include <stdint.h>

void page_fault(registers_t *regs)
{
   // A page fault has occurred.
   // The faulting address is stored in the CR2 register.
   uint32_t faulting_address;
   __asm__ __volatile__("mov %%cr2, %0" : "=r" (faulting_address));

   // The error code gives us details of what happened.
   int present   = !(regs->err_code & 0x1); // Page not present
   int rw = regs->err_code & 0x2;           // Write operation?
   int us = regs->err_code & 0x4;           // Processor was in user-mode?
   int reserved = regs->err_code & 0x8;     // Overwritten CPU-reserved bits of page entry?
   int id = regs->err_code & 0x10;          // Caused by an instruction fetch?

   // Output an error message.
   printk("Page fault! ( ");
   if (present) {printk("present ");}
   if (rw) {printk("read-only ");}
   if (us) {printk("user-mode ");}
   if (reserved) {printk("reserved ");}
   printk(") at 0x%x\n", faulting_address);
   __asm__ __volatile__ ("cli");
   __asm__ __volatile__ ("hlt");
   // PANIC!
}

void initialise_paging()
{
	register_interrupt_handler(14, page_fault);
}
