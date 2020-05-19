#include "gdt.h"
#include <stddef.h>

void _start(unsigned int ferrum_signature, unsigned int ferrum_low_mem)
{
	i386_setup_vga_text_mode();

	int initial_vga_offset = vga_get_cursor_offset();

    /* VGA 'cells' consist of the character and its control data
     * e.g. 'white on black background', 'red text on white bg', etc */

	// Check if we booted using Ferrum's bootloader, if not, stop execution.
	// 0xFEB0516C = Ferrum (FE) Bootloader (B0) Signature (516) Check (C)
	if (ferrum_signature == 0xFEB0516C)
	{
		unsigned char* vga = (unsigned char*) 0xb8000;
		unsigned char bootedfromferrum[] = "Ferrum detected!";

		for (int i = 0; i < (sizeof(bootedfromferrum) - 1); i++)
		{
				vga[initial_vga_offset] = bootedfromferrum[i];
				vga[initial_vga_offset + 1] = 0x0F;
				initial_vga_offset += 2;
		}
	} else {
		unsigned char* vga = (unsigned char*) 0xb8000;
		unsigned char notbootedfromferrum[] = "Ferrum not detected!";

		for (int i = 0; i < (sizeof(notbootedfromferrum) - 1); i++)
		{
				vga[initial_vga_offset] = notbootedfromferrum[i];
				vga[initial_vga_offset + 1] = 0x4F;
				initial_vga_offset += 2;
		}
		// TODO: Do we really have to abort? If we got here, maybe another user booted
		// our kernel using a compatible bootloader, even if this doesn't gain
		// popularity, someone might want to try their bootloader's capabilities using
		// a random kernel (Mine in this case), so let's not prohibit them from booting the kernel
		// if they already got this far.
		/* for(;;); */
	}
    
    printk("\n");
    
    printkok("Booted to kernel mode!");

	if (i386_gdt_install() == 1)
	{
		printkok("Re-initialized GDT");
	} else {
		printkfail("Failed to re-initialize GDT");
	}

	if (isr_install() == 1)
	{
		printkok("Initialized ISRs");
	} else {
		printkfail("Failed to initialize ISRs");
	}

	if (irq_install() == 1)
	{
		printkok("Initialized IRQs");
	} else {
		printkfail("Failed to initialize IRQs");
	}

    /* IRQ0: timer */
    init_timer(50);
    /* IRQ1: keyboard */
    init_keyboard();
    
	for(;;);
}

void user_input(char *input)
{
    if (strcmp(input, "end") == 0) {
        printk("Stopping the CPU. Bye!\n");
        __asm__ __volatile__("hlt");
    } else if (strcmp(input, "int") == 0) {
    	/* Test the interrupts */
    	__asm__ __volatile__("int $2");
    	__asm__ __volatile__("int $3");
    } else if (strcmp(input, "tick") == 0) {
    	extern unsigned int tick;
    	printk("Ticks: %u\n", tick);
    } else {
    	printk("Unknown Command: ");
    	printk(input);
    }
    printk("\n> ");
}