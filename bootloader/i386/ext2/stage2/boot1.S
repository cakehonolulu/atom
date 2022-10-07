
.section .text

.code32

.global boot1
boot1:
    movl $0xb8140,%ebx
    movb $'H', %al
    movb $0x2F,%ah
    movw %ax,(%ebx)

    movl $0xb8142,%ebx
    movb $'i', %al
    movb $0x2F,%ah
    movw %ax,(%ebx)
    
    movl $0xb8144,%ebx
    movb $' ', %al
    movb $0x2F,%ah
    movw %ax,(%ebx)

    movl $0xb8146,%ebx
    movb $'f', %al
    movb $0x2F,%ah
    movw %ax,(%ebx)
    movl $0xb8148,%ebx
    movb $'r', %al
    movb $0x2F,%ah
    movw %ax,(%ebx)
    movl $0xb814A,%ebx
    movb $'o', %al
    movb $0x2F,%ah
    movw %ax,(%ebx)
    movl $0xb814C,%ebx
    movb $'m', %al
    movb $0x2F,%ah
    movw %ax,(%ebx)

    movl $0xb814E,%ebx
    movb $' ', %al
    movb $0x2F,%ah
    movw %ax,(%ebx)

    movl $0xb8150,%ebx
    movb $'E', %al
    movb $0x2F,%ah
    movw %ax,(%ebx)
    movl $0xb8152,%ebx
    movb $'X', %al
    movb $0x2F,%ah
    movw %ax,(%ebx)
    movl $0xb8154,%ebx
    movb $'T', %al
    movb $0x2F,%ah
    movw %ax,(%ebx)
    movl $0xb8156,%ebx
    movb $'2', %al
    movb $0x2F,%ah
    movw %ax,(%ebx)
    movl $0xb8158,%ebx
    movb $''', %al
    movb $0x2F,%ah
    movw %ax,(%ebx)
    movl $0xb815A,%ebx
    movb $'s', %al
    movb $0x2F,%ah
    movw %ax,(%ebx)

    movl $0xb815C,%ebx
    movb $' ', %al
    movb $0x2F,%ah
    movw %ax,(%ebx)

    movl $0xb815E,%ebx
    movb $'S', %al
    movb $0x2F,%ah
    movw %ax,(%ebx)
    movl $0xb8160,%ebx
    movb $'t', %al
    movb $0x2F,%ah
    movw %ax,(%ebx)
    movl $0xb8162,%ebx
    movb $'a', %al
    movb $0x2F,%ah
    movw %ax,(%ebx)
    movl $0xb8164,%ebx
    movb $'g', %al
    movb $0x2F,%ah
    movw %ax,(%ebx)
    movl $0xb8166,%ebx
    movb $'e', %al
    movb $0x2F,%ah
    movw %ax,(%ebx)

    movl $0xb8168,%ebx
    movb $' ', %al
    movb $0x2F,%ah
    movw %ax,(%ebx)

    movl $0xb816A,%ebx
    movb $'2', %al
    movb $0x2F,%ah
    movw %ax,(%ebx)
    movl $0xb816C,%ebx
    movb $'!', %al
    movb $0x2F,%ah
    movw %ax,(%ebx)

    cli
    hlt
