.code16

.global boot

boot:
	movb $'H' , %al
	movb $0x0e, %ah
	int  $0x10
	hlt