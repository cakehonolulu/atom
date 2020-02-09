#include "gdt.h"

void _start() {
	unsigned char* vga = (unsigned char*) 0xb8000;
	vga[0] = 'X';
	vga[1] = 0x09;
	i386_gdt_install();
	for(;;);
}