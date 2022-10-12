ENTRY(bootstrap)

OUTPUT_FORMAT(elf32-i386)

OUTPUT_ARCH(i386)

INCLUDE "link_header.h"

SECTIONS {

	. = LOCATION;
    
    .text : AT(LOCATION)
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