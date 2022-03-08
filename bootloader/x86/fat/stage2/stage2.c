#include <textmode.h>

void write_string( int colour, const char *string )
{
    volatile char *video = (volatile char*)0xB8000;
    while( *string != 0 )
    {
        *video++ = *string++;
        *video++ = colour;
    }
}

int stage2()
{
	init_text_mode();

    putchar('H');
    putchar('e');
    putchar('l');
    putchar('l');
    putchar('o');
    putchar(' ');
    putchar('f');
    putchar('r');
    putchar('o');
    putchar('m');
    putchar(' ');
    putchar('S');
    putchar('t');
    putchar('a');
    putchar('g');
    putchar('e');
    putchar(' ');
    putchar('2');
    putchar('!');

	__asm__ __volatile__("cli; hlt");

    return 0;
}
