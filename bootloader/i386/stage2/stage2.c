#include <textmode.h>
#include <ata.h>
#include <libc.h>
#include <fat16.h>
#include <mmap.h>

int stage2()
{
	// Disable interrupts
	__asm__ __volatile__ ("cli");

	init_text_mode();

    puts("atom: stage2 initialized!\n");

    puts("atom: Booted from ");
    cputs(
#ifdef FAT16
        "FAT16"
#endif
#ifdef EXT2
        "EXT2"
#endif
        , 0x0A
    );

    puts(" filesystem\n"); 

    uint8_t m_sect[512];

    uint8_t m_ata_ident[512];

    atapio24_identify((uint32_t *) m_ata_ident);

    atapio24_read((uint32_t *) m_sect, 0x0, 1);

    parse_mmap();

#ifdef FAT16
    //fat16_parse(&m_sect[0]);
#endif

	__asm__ __volatile__("cli; hlt");

    return 0;
}
