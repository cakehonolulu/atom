#include <textmode.h>
#include <ata.h>

int stage2()
{
	// Disable interrupts
	__asm__ __volatile__ ("cli");

	init_text_mode();

    puts("Hello from Stage 2!\n");

    atapio24_identify();

    uint8_t m_sect[512];

    atapio24_read(m_sect, 0x0, 1);

    puts("Data read successfully\n");

	__asm__ __volatile__("cli; hlt");

    return 0;
}
