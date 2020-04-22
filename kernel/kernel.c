#include "gdt.h"
#include <stddef.h>

extern void print();

void _start(size_t bootloader_info)
{

	// Check if we booted using Ferrum's bootloader, if not, stop execution.
	if (bootloader_info =! 0xFE)
	{
		unsigned char* vga = (unsigned char*) 0xb8000;
		vga[0] = 'X';
		vga[1] = 0x09;
		for(;;);
	}

	print();
	i386_gdt_install();
	for(;;);
}