[SECTION .kernel_discard]

global I386_KERNEL_SIZE
I386_KERNEL_SIZE equ (kernel_end-kernel_start+511) / 512
                                ; Number of 512 byte sectors kernel uses.

kernel_start:
    ; Insert kernel binary here. It is done this way since we
    ; can determine the size(and number of sectors) to load since
    ;     Size = kernel_end-kernel_start
    incbin "../../kernel/arch/x86/kernel.bin"

; End of stage2. Make sure this label is LAST in this file!
kernel_end: