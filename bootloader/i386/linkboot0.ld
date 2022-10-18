ENTRY(init0)

OUTPUT_FORMAT(elf32-i386)

OUTPUT_ARCH(i386)

SECTIONS {

    . = 0x7C00;

    .text : AT(0x7C00)
    {
        *(.text)
    }

    .rodata (ALIGN(4K)) :
    {
        *(.rodata)
    }

    .data (ALIGN(4K)) :
    {
        *(.data)
    }

    .bss (ALIGN(4K)) :
    {
        *(.bss)
    }

    .sig : AT(0x7DFE)
    {
        SHORT(0xaa55);
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
