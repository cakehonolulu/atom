[SECTION .stage2_discard]

global I386_BOOT1_SIZE
I386_BOOT1_SIZE equ (stage2_end-stage2_start+511) / 512
                                ; Number of 512 byte sectors stage2 uses.

stage2_start:
    ; Insert stage2 binary here. It is done this way since we
    ; can determine the size(and number of sectors) to load since
    ;     Size = stage2_end-stage2_start
    incbin "boot1.bin"

; End of stage2. Make sure this label is LAST in this file!
stage2_end:
