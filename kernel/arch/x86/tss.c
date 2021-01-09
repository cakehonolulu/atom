#include <stdint.h>
#include <gdt.h>
#include <tss.h>

tss_entry_t tss;

void write_tss(int32_t num, uint16_t ss0, uint32_t esp0)
{
	uint32_t base = (uint32_t) &tss;
	uint32_t limit = (base + sizeof(tss));

	/* Add the TSS descriptor to the GDT */
	arch_gdt_add_entry(num, base, limit, 0xE9, 0x00);

	memset(&tss, 0x0, sizeof (tss_entry_t));

	tss.ss0 = ss0;
	tss.esp0 = esp0;
	tss.cs = 0x0b;
	tss.ss = 0x13;
	tss.ds = 0x13;
	tss.es = 0x13;
	tss.fs = 0x13;
	tss.gs = 0x13;

	tss.iomap_base = sizeof (tss_entry_t);
}

void set_kernel_stack(uintptr_t stack) {
	/* Set the kernel stack */
	tss.esp0 = stack;
}