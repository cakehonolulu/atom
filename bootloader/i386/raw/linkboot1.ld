ENTRY(init1)

OUTPUT_FORMAT(elf32-i386)

OUTPUT_ARCH(i386)

SECTIONS {

	. = 0x1000;

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