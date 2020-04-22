#include <stddef.h>

void print()
{
	unsigned char* vga = (unsigned char*) 0xb8000;
	vga[0] = 'Y';
	vga[1] = 0x09;
}