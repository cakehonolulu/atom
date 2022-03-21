#include <textmode.h>

int stage2()
{
	init_text_mode();

    puts("Hello from Stage 2!\n");

	__asm__ __volatile__("cli; hlt");

    return 0;
}
