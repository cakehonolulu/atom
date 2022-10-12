#include <stage2.h>

int stage2()
{
	// Disable interrupts
	__asm__ __volatile__ ("cli");

	init_text_mode();

    puts("atom: stage2 initialized!\n");

    puts("atom: Built with ");
    cputs(
#if defined(__GNUC__) && !defined(__clang__)
    "gcc "
#else
    "clang "
#endif
        , 0x0E
    );

    cputs(
#if defined(__GNUC__) && !defined(__clang__)
    VER_STRING(__GNUC__, __GNUC_MINOR__, __GNUC_PATCHLEVEL__)
#else
    VER_STRING(__clang_major__, __clang_minor__, __clang_patchlevel__)
#endif
        , 0x0E
    );

    puts(" stdc ver. %d\n", __STDC_VERSION__);

    puts("atom: Compiled %s %s, commit %s\n", __DATE__, __TIME__, COMMIT);

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
    fat16_parse(&m_sect[0]);
#endif

	__asm__ __volatile__("cli; hlt");

    return 0;
}
