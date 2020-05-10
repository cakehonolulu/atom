#include "gdt.h"
#include <stddef.h>

void _start(unsigned int ferrum_signature, unsigned int ferrum_info)
{
	// unsigned int = 4 Bytes (0x41424344)
	// We get the low 2 bytes (0x4344) to an unsigned sort that can hold 2 byte in total
	unsigned short boot1_ferrum_info_high = (ferrum_info & 0xFFFF);
	// 0x4344 -> 0x43 and 0x44
	// lastrow is at bh
	// lastcol is at bl
	// Row should be 10
	// Col should be 11
	unsigned char boot1_lastrow = (boot1_ferrum_info_high >> 8); // 10
	unsigned char boot1_lastcol = (boot1_ferrum_info_high & 0xFF); // 11
	unsigned short boot1_vga_position = (boot1_lastrow << 8) + 0;
	unsigned int boot1_vga_offset = boot1_vga_position * 2;

	outb(0x3d4, 14); /* Requesting byte 14: high byte of cursor pos */
    /* Data is returned in VGA data register (0x3d5) */
    int position = inb(0x3d5);
    position = position << 8; /* high byte */

    outb(0x3d4, 15); /* requesting low byte */
    position += inb(0x3d5);

    /* VGA 'cells' consist of the character and its control data
     * e.g. 'white on black background', 'red text on white bg', etc */
    int offset_from_vga = position * 2;


	// Check if we booted using Ferrum's bootloader, if not, stop execution.
	// 0xFEB0516C = Ferrum (FE) Bootloader (B0) Signature (516) Check (C)
	if (ferrum_signature == 0xFEB0516C)
	{
		unsigned char* vga = (unsigned char*) 0xb8000;
		vga[0] = 'O';
		vga[1] = 0x2F;
		/*vga[boot1_vga_offset + 1] = 0x09;
		vga[boot1_vga_offset + 2] = ' ';
		vga[boot1_vga_offset + 3] = 0x09;
		vga[boot1_vga_offset + 4] = 'O';
		vga[boot1_vga_offset + 5] = 0x09;
		vga[boot1_vga_offset + 6] = 'K';
		vga[boot1_vga_offset + 7] = 0x09;
		vga[boot1_vga_offset + 8] = ' ';
		vga[boot1_vga_offset + 9] = 0x09;
		vga[boot1_vga_offset + 10] = ']';
		vga[boot1_vga_offset + 11] = 0x09;*/
	} else {
		unsigned char* vga = (unsigned char*) 0xb8000;
		vga[0] = 'F';
		vga[1] = 0x4F;
		/*vga[boot1_vga_offset + 1] = 0x09;
		vga[boot1_vga_offset + 2] = ' ';
		vga[boot1_vga_offset + 3] = 0x09;
		vga[boot1_vga_offset + 4] = 'O';
		vga[boot1_vga_offset + 5] = 0x09;
		vga[boot1_vga_offset + 6] = 'K';
		vga[boot1_vga_offset + 7] = 0x09;
		vga[boot1_vga_offset + 8] = ' ';
		vga[boot1_vga_offset + 9] = 0x09;
		vga[boot1_vga_offset + 10] = ']';
		vga[boot1_vga_offset + 11] = 0x09;*/
		for(;;);
	}

	i386_setup_vga();
	if (i386_gdt_install() == 1)
	{
		vga_printkok("Re-initialized GDT");
	} else {
		vga_printkfail("Failed to re-initialize GDT");
	}

    vga_printkhex(ferrum_info);
    vga_printk(" : Ferrum Info\n");
    vga_printkhex(boot1_ferrum_info_high);
    vga_printk(" : Ferrum Info High\n");
    vga_printkhex(boot1_lastrow);
    vga_printk(" : boot1_lastrow\n");
    vga_printkhex(boot1_lastcol);
    vga_printk(" : boot1_lastcol\n");
    vga_printkhex(boot1_vga_position);
    vga_printk(" : boot1_vga_position\n");
    vga_printkhex(boot1_vga_offset);
    vga_printk(" : boot1_vga_offset\n");
    vga_printkhex(offset_from_vga);
    vga_printk(" : offset_from_vga\n");
    vga_printkhex(position);
    vga_printk(" : position\n");

	vga_printkok("Booted to kernel mode!");
	for(;;);
}