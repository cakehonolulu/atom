#include "gdt.h"
#include <stddef.h>
#include <stdint.h>

#define MEMORY_MAP 0x9000

enum bios_memmap_type
{
    MEMORY_TYPE_USABLE = 1,
    MEMORY_TYPE_RESERVED = 2,
    MEMORY_TYPE_ACPI_RECLAMIABLE = 3,
    MEMORY_TYPE_ACPI_NON_VOLATILE = 4,
    MEMORY_TYPE_BAD_AREA = 5,
};

struct bios_memmap_entry
{
    uint64_t base;
    uint64_t size;
    uint32_t type;
    uint32_t attrib;
};

void mem_init(void)
{
    static const char* strtype[] = {
        "Unknown",
        "Usable", // Usable
        "Reserved", // Unusable
        "ACPI Reclaimable",
        "ACPI NVS Memory",
        "Bad Memory"
    };

    uint32_t len = *(uint32_t*)MEMORY_MAP;
    uint32_t size = 0;
    uint32_t base = 0;
    uint32_t end = 0;
    const struct bios_memmap_entry* entry = (const struct bios_memmap_entry*)(MEMORY_MAP + 8);

    uint32_t possible_locations = 0;

#ifdef DEBUG
    printk("Memory map report: %d entries\n", len);
#endif
    while (len-- != 0)
    {
        size = entry->size & 0xFFFFFFFF;
        base = entry->base & 0xFFFFFFFF;
        end = base + size;
        const char* t = entry->type <= 5 ? strtype[entry->type] : strtype[0];
        if (entry->type == 1)
        {
            // Usable memory region!
            // We should keep track of it.
            // Later on, we should also check the size and see if it fits our needs.
#ifdef DEBUG
            printk("Found an usable memory portion!\n");
#endif
            possible_locations++;
        }

#ifdef DEBUG
        printk("Start: 0x%x; End: 0x%x Size: %d bytes; Type: %s\n", base, end, size, t);
#endif
        ++entry;
    }

    uint32_t memory_locations[possible_locations];

    uint32_t first_run = 1;

    uint32_t counter = 0;

    len = *(uint32_t*)MEMORY_MAP;
    const struct bios_memmap_entry* entry2 = (const struct bios_memmap_entry*)(MEMORY_MAP + 8);
    size = 0;
    base = 0;
    end = 0;

    while (len-- != 0)
    {
        size = entry2->size & 0xFFFFFFFF;
        base = entry2->base & 0xFFFFFFFF;
        end = base + size;
        const char* t = entry2->type <= 5 ? strtype[entry2->type] : strtype[0];
        if (entry2->type == 1)
        {
            if (first_run == 1)
            {
                memory_locations[0] = base;
                first_run = 0;
#ifdef DEBUG
                printk("Usable Memory Locations: 0x%x\n", memory_locations[0]);
#endif
                counter++;
            } else if (first_run == 0) {
                memory_locations[counter] = base;
#ifdef DEBUG
                printk("Usable Memory Locations: 0x%x\n", memory_locations[counter]);
#endif
                counter++;
            }
        }

        ++entry2;
    }
}

void _start(unsigned int ferrum_signature, unsigned int ferrum_low_mem)
{
	i386_setup_vga_text_mode();

	int initial_vga_offset = vga_get_cursor_offset();

    /* VGA 'cells' consist of the character and its control data
     * e.g. 'white on black background', 'red text on white bg', etc */

	// Check if we booted using Ferrum's bootloader, if not, stop execution.
	// 0xFEB0516C = Ferrum (FE) Bootloader (B0) Signature (516) Check (C)
	if (ferrum_signature == 0xFEB0516C)
	{
		unsigned char* vga = (unsigned char*) 0xb8000;
		unsigned char bootedfromferrum[] = "Ferrum detected!";

		for (int i = 0; i < (sizeof(bootedfromferrum) - 1); i++)
		{
				vga[initial_vga_offset] = bootedfromferrum[i];
				vga[initial_vga_offset + 1] = 0x0F;
				initial_vga_offset += 2;
		}
	} else {
		unsigned char* vga = (unsigned char*) 0xb8000;
		unsigned char notbootedfromferrum[] = "Ferrum not detected!";

		for (int i = 0; i < (sizeof(notbootedfromferrum) - 1); i++)
		{
				vga[initial_vga_offset] = notbootedfromferrum[i];
				vga[initial_vga_offset + 1] = 0x4F;
				initial_vga_offset += 2;
		}
		// TODO: Do we really have to abort? If we got here, maybe another user booted
		// our kernel using a compatible bootloader, even if this doesn't gain
		// popularity, someone might want to try their bootloader's capabilities using
		// a random kernel (Mine in this case), so let's not prohibit them from booting the kernel
		// if they already got this far.
		/* for(;;); */
	}
    
    printk("\n");
    
    printkok("Booted to kernel mode!");

    mem_init();

	if (i386_gdt_install() == 1)
	{
		printkok("Re-initialized GDT");
	} else {
		printkfail("Failed to re-initialize GDT");
	}

	if (isr_install() == 1)
	{
		printkok("Initialized ISRs");
	} else {
		printkfail("Failed to initialize ISRs");
	}

	if (irq_install() == 1)
	{
		printkok("Initialized IRQs");
	} else {
		printkfail("Failed to initialize IRQs");
	}

    /* IRQ0: timer */
    init_timer(50);
    /* IRQ1: keyboard */
    init_keyboard();
    
	for(;;);
}

void user_input(char *input)
{
    if (strcmp(input, "end") == 0) {
        printk("Stopping the CPU. Bye!\n");
        __asm__ __volatile__("hlt");
    } else if (strcmp(input, "int") == 0) {
    	/* Test the interrupts */
    	__asm__ __volatile__("int $2");
    	__asm__ __volatile__("int $3");
    } else if (strcmp(input, "tick") == 0) {
    	extern unsigned int tick;
    	printk("Ticks: %u\n", tick);    
    } else if (strcmp(input, "memloc") == 0) {
        /*for (unsigned int i = 0; i < possible_locations; i++)
        {
            printk("Usable Memory Locations: 0x%x\n", memory_locations[i]);
        }*/
    } else {
    	printk("Unknown Command: ");
    	printk(input);
    }
    printk("\n> ");
}