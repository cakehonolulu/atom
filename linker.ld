ENTRY(bootstrap)

OUTPUT_FORMAT("binary")

OUTPUT_ARCH(i386)

SECTIONS {

    . = 0x7c00;

    .text :
    {
        *(.bootstrap)
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