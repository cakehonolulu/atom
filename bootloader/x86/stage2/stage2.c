int stage2()
{
	asm volatile("	mov $0xb800, %ax\n\t"
				" 	mov %ax, %es\n\t"
				"	mov $0x4020, %ax\n\t"
				"	mov $2000, %cx\n\t"
				"	xor %di, %di\n\t"
				"	rep stosw");
	
	asm volatile("cli; hlt");
}