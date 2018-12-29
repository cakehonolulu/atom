.code16

.global boot1

boot1:
	movb $'X' , %al
	movb $0x0e, %ah
	int  $0x10
	cli
	hlt

