ENTRY(bootstrap)

OUTPUT_FORMAT(elf32-i386)

OUTPUT_ARCH(i386)

SECTIONS {

	. = 0x1000;
    
    .text : AT(0x1000)
    {
        *(.text.bootstrap)
        *(.text)
    }

    .rodata (ALIGN(4K)) :
    {
        *(.rodata)
        *(.rodata.*)
    }

    .data (ALIGN(4K)) :
    {
        *(.data)
    }

    .bss (ALIGN(4K)) :
    {
        *(.bss)
    }

    /DISCARD/ :
    {
        *(.note*);
        *(.iplt*);
        *(.igot*);
        *(.rel*);
        *(.comment);
    }
}