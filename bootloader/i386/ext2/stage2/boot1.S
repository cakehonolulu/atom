
.section .text

.global boot1
boot1:
    movl $0xb8000,%ebx
    movb $'!', %al
    movb $0x0F,%ah
    movw %ax,(%ebx)
    cli
    hlt
