.global test

.code32

test:
    movw $0x741,0xb8000
	cli
    hlt
