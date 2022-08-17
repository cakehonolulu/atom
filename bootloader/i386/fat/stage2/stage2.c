#include <textmode.h>
#include <ata.h>

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

    puts("Data read successfully\n");

    puts("%c%c%c%c%c%c%c\n", (char) m_sect[3], (char) m_sect[4], (char) m_sect[5], (char) m_sect[6],
                             (char) m_sect[7], (char) m_sect[8], (char) m_sect[9]);

	__asm__ __volatile__("cli; hlt");

    return 0;
}
