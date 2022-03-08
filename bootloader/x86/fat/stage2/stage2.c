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

	__asm__ __volatile__("cli; hlt");

    return 0;
}
