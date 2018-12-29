.code16

.global init1

.section .text

init1:
	mov $0x2, %ah
	mov $0x1, %dh
	mov $0x0, %dl
	mov $0x0, %bh
	int $0x10
	cli
	hlt
