ENTRY(boot1)

OUTPUT_FORMAT(elf32-i386)

OUTPUT_ARCH(i386)

SECTIONS {

    . = 0x1000;

    .text : AT(0x1000)
    {
        *(.text)
    }

    .rodata :
    {
        *(.rodata)
        *(.rodata.*)
    }

    .data :
    {
        *(.data)
    }

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