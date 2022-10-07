#include <textmode.h>
#include <ata.h>
#include <libc.h>
#include <fat16.h>

int stage2()
{
	// Disable interrupts
	__asm__ __volatile__ ("cli");

	init_text_mode();

    puts("Hello from Stage 2!\n");

    uint8_t m_sect[512];

    uint8_t m_ata_ident[512];

    atapio24_identify((uint32_t *) m_ata_ident);

    atapio24_read((uint32_t *) m_sect, 0x0, 1);

#ifdef FAT16
    fat16_parse(&m_sect[0]);
#endif

	__asm__ __volatile__("cli; hlt");

    return 0;
}
