ENTRY(_kernel_entry)

OUTPUT_FORMAT(elf32-i386)

OUTPUT_ARCH(i386)

SECTIONS {

	. = 1M;

    kernel_entry_start = .; _kernel_entry_start = .; __kernel_entry_start = .;

    .kernel.entry BLOCK(4K) : ALIGN(4K)
    {
        *(.kernel.entry.text)
        *(.kernel.entry.data)
    }

    kernel_entry_end = .; _kernel_entry_end = .; __kernel_entry_end = .;

    . += 0xC0000000;

    kernel_start = .; _kernel_start = .; __kernel_start = .;

    .text ALIGN (0x1000) : AT(ADDR(.text) - 0xC0000000)
    {
        *(.text)
    }

    .rodata ALIGN (0x1000) : AT(ADDR(.rodata) - 0xC0000000)
    {
        *(.rodata)
    }

    .data ALIGN (0x1000) : AT(ADDR(.data) - 0xC0000000)
    {
        *(.data)
    }

    .bss : AT(ADDR(.bss) - 0xC0000000)
    {
        __bss_start = .;
        *(COMMON)            /* all COMMON sections from all files */
        *(.bss)              /* all BSS sections from all files */
        *(.stack)
    }
    . = ALIGN(4);
    __bss_end = .;
    __bss_sizeb = __bss_end - __bss_start;       /* BSS size in bytes */
    __bss_sizel = (__bss_end - __bss_start) / 4; /* BSS size in longs/DWORDs */

    /DISCARD/ : {            /* Remove Unneeded sections */
        *(.eh_frame);
        *(.comment);
    }

    kernel_end = .; _kernel_end = .; __kernel_end = .;
}