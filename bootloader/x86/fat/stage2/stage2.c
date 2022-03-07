// note this example will always write to the top
// line of the screen
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
	write_string(0x0F, "Hello from Stage 2 - 32 bit C");

	__asm__ __volatile__("cli; hlt");

    return 0;
}
