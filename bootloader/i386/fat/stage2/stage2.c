#include <textmode.h>
#include <ata.h>

int stage2()
{
	// Disable interrupts
	__asm__ __volatile__ ("cli");

	init_text_mode();

    puts("Hello from Stage 2!\n");
    
	__asm__ __volatile__("cli; hlt");

    return 0;
}
