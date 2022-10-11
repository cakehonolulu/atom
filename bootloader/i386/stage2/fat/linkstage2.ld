ENTRY(boot1)

OUTPUT_FORMAT(elf32-i386)

OUTPUT_ARCH(i386)

SECTIONS {

	. = 0x7E00;
    
    .text : AT(0x7E00)
    {
        *(.text)
    }

    . = ALIGN (4K);

    .rodata :
    {
        *(.rodata)
        *(.rodata.*)
    }

    . = ALIGN (4K);

    .data :
    {
        *(.data)
    }

    . = ALIGN (4K);

    .bss :
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