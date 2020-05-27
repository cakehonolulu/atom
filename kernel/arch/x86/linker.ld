ENTRY(_bootstrap)

OUTPUT_FORMAT(elf32-i386)

OUTPUT_ARCH(i386)

SECTIONS {

	. = 1M;

	kernel_start = .;

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

    .bss : SUBALIGN(4) {
        __bss_start = .;
        *(COMMON)            /* all COMMON sections from all files */
        *(.bss)              /* all BSS sections from all files */
    }
    . = ALIGN(4);
    __bss_end = .;
    __bss_sizeb = __bss_end - __bss_start;       /* BSS size in bytes */
    __bss_sizel = (__bss_end - __bss_start) / 4; /* BSS size in longs/DWORDs */


    kernel_end = .;
}