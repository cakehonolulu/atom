#include "gdt.h"
#include <stddef.h>

void _start(unsigned long bootloader_info)
{
	// Check if we booted using Ferrum's bootloader, if not, stop execution.
	// 0xFEB0516C = Ferrum (FE) Bootloader (B0) Signature (516) Check (C)
	if (bootloader_info =! 0xFEB0516C)
	{
		unsigned char* vga = (unsigned char*) 0xb8000;
		vga[0] = 'E';
		vga[1] = 0x09;
		vga[2] = 'r';
		vga[3] = 0x09;
		vga[4] = 'r';
		vga[5] = 0x09;
		vga[6] = 'o';
		vga[7] = 0x09;
		vga[8] = 'r';
		vga[9] = 0x09;
		vga[10] = '!';
		vga[11] = 0x09;
		for(;;);
	}

	i386_setup_vga();
	i386_gdt_install();
	for(;;);
}