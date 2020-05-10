ENTRY(_start)

OUTPUT_FORMAT("binary")

OUTPUT_ARCH(i386)

SECTIONS {

	. = 0x100000;

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
}