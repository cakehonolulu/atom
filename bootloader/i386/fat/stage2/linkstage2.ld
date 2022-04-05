ENTRY(init1)

OUTPUT_FORMAT(elf32-i386)

OUTPUT_ARCH(i386)

SECTIONS {

	. = 0x7E00;

    .text.init :
    {
        *(.text.init)
    }

    .data.init :
    {
        *(.data.init)
    }

    .text :
    {
        *(.text)
    }

    .rodata :
    {
        *(.rodata)
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
      *(.kernel_discard)
    }

}