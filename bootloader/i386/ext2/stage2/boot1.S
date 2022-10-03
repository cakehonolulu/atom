.global boot1

.code32
boot1:
    movw $0x621,0xb866A
	cli
    hlt
