#include <textmode.h>
#include <ata.h>
#include <libc.h>

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

    puts("Disk Volume Name: %c%c%c%c%c%c%c%c\n", (char) m_sect[3], (char) m_sect[4], (char) m_sect[5], (char) m_sect[6],
                             (char) m_sect[7], (char) m_sect[8], (char) m_sect[9], (char) m_sect[10]);

    puts("Filesystem: %c%c%c%c%c%c%c%c\n", (char) m_sect[0x36], (char) m_sect[0x37], (char) m_sect[0x38], (char) m_sect[0x39],
                             (char) m_sect[0x3A], (char) m_sect[0x3B], (char) m_sect[0x3C], (char) m_sect[0x3D]);

	__asm__ __volatile__("cli; hlt");

    return 0;
}
