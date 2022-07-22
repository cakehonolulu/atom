#include <textmode.h>
#include <ata.h>

int stage2()
{
	// Disable interrupts
	__asm__ __volatile__ ("cli");

	init_text_mode();

    puts("Hello from Stage 2!\n");

    //atapio24_identify();

    uint8_t m_sect[512];

    atapio24_read((uint32_t *) m_sect, 0x0, 1);

    puts("Data read successfully\n");

    putc((char) m_sect[3]);
    putc((char) m_sect[4]);
    putc((char) m_sect[5]);
    putc((char) m_sect[6]);
    putc((char) m_sect[7]);
    putc((char) m_sect[8]);
    putc((char) m_sect[9]);

	__asm__ __volatile__("cli; hlt");

    return 0;
}
