
.section .text

.extern stage2

.code32

.global boot1
boot1:
    call stage2
    cli
    hlt
