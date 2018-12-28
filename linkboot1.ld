ENTRY(boot)

OUTPUT_FORMAT("binary")

OUTPUT_ARCH(i386)

SECTIONS {

    . = 0x1000;

    .text :
    {
        *(.boot)
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