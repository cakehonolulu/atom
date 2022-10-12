
.section .text.bootstrap

.extern stage2

.code32

.global bootstrap
bootstrap:
    call stage2
    cli
    hlt
