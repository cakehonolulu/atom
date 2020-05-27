#include "gdt.h"
#include <stddef.h>
#include <stdint.h>

extern void *kernel_end;
extern void *kernel_hh_start;

#define KERNEL_START (uint32_t)(&kernel_hh_start)
#define KERNEL_END (uint32_t)(&kernel_end)
#define KERNEL_SIZE KERNEL_END - KERNEL_START

#define MEMORY_MAP 0xC0009000

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

// FIXME: For now, we'll just use 1 memory region, later
// on we'll keep track of all of them, order them and use
// them accordingly.
uint32_t memory_management_region_start = 0;
uint32_t memory_management_region_end = 0;

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

    size_t possible_locations = 0;

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
		if (((size / 1024) / 1024) != 0) {
			printk("Start: 0x%x; End: 0x%x Size: %d bytes (%d MB); Type: %s\n", base, end, size, ((size / 1024) / 1024), t);
		} else {
			printk("Start: 0x%x; End: 0x%x Size: %d bytes; Type: %s\n", base, end, size, t);
		}
#endif
        ++entry;
    }

#ifdef DEBUG
    printk("possible_locations: %d, memory_locations_max[%d]\n", possible_locations, ((possible_locations * 2) - 1));
#endif

    // Each possible location holds base address and end address, so multiply the array by 2 and
    // substract 1 due to the fact that we have to count 0 (As it's an array)
    uint32_t memory_locations[((possible_locations * 2) - 1)];

    size_t first_run = 1;

    size_t counter = 0;

    len = *(uint32_t*)MEMORY_MAP;
    const struct bios_memmap_entry* entry2 = (const struct bios_memmap_entry*)(MEMORY_MAP + 8);
    size = 0;
    base = 0;
    end = 0;

#ifdef DEBUG
    printk("Usable Memory Locations (Start - End):\n");
#endif

    while (len-- != 0)
    {
        size = entry2->size & 0xFFFFFFFF;
        base = entry2->base & 0xFFFFFFFF;
        end = base + size;
        const char* t = entry2->type <= 5 ? strtype[entry2->type] : strtype[0];

        // Check if Usable
        if (entry2->type == 1)
        {
            if (first_run == 1)
            {
                memory_locations[0] = base;
                memory_locations[1] = end;
                first_run = 0;
#ifdef DEBUG
                printk("0x%x - 0x%x\n", memory_locations[0], memory_locations[1]);
#endif
                counter++; // counter = 1
            } else {
                memory_locations[counter + 1] = base;
                memory_locations[counter + 2] = end;
#ifdef DEBUG
                printk("0x%x - 0x%x\n", memory_locations[counter + 1], memory_locations[counter + 2]);
#endif
                counter += 2;
            }
        }
        ++entry2;
    }
#ifdef DEBUG
        printk("counter[%d], counter non array: %d\n", counter, counter+1);
#endif
        // Now we should decide which regions are large enough to satisfy our needs
        // and we will mark them appropiately for the memory management related functions
        for (size_t i = 0; counter > i; i += 2)
        {
#ifdef DEBUG
        	printk("Current i: %d\n", i);
#endif
        	if ((memory_locations[i + 1] + memory_locations[i]) > 0x100000) // Check if bigger than 1MB
        	{
        		printk("Big region found, Start: 0x%x, End: 0x%x, Size: %d Megabytes\n", memory_locations[i], memory_locations[i + 1],
        		(((memory_locations[i + 1] - memory_locations[i]) / 1024) / 1024));
        		memory_management_region_start = memory_locations[i];
        		memory_management_region_end = memory_locations[i + 1];
        	}

#ifdef DEBUG
            printk("Counter: %d\n", i);
#endif
        }
}

void _kmain(unsigned int initium_signature)
{
	i386_setup_vga_text_mode();

	int initial_vga_offset = vga_get_cursor_offset();

    /* VGA 'cells' consist of the character and its control data
     * e.g. 'white on black background', 'red text on white bg', etc */

	// Check if we booted using Atom's Initium bootloader, if not, stop execution.
	// 0xA1B0516C =  Atom (A) Initium (I) Bootloader (B0) Signature (516) Check (C)
	if (initium_signature == 0xA1B0516C)
	{
		unsigned char* vga = (unsigned char*) 0xC00B8000;
		unsigned char bootedfrominitium[] = "[ATOM] Initium Bootloader detected!";

		for (int i = 0; i < (sizeof(bootedfrominitium) - 1); i++)
		{
				vga[initial_vga_offset] = bootedfrominitium[i];
				vga[initial_vga_offset + 1] = 0x0F;
				initial_vga_offset += 2;
		}
	} else {
		unsigned char* vga = (unsigned char*) 0xC00B8000;
		unsigned char notbootedfrominitium[] = "[ATOM] Initium Bootloader not detected!";

		for (int i = 0; i < (sizeof(notbootedfrominitium) - 1); i++)
		{
				vga[initial_vga_offset] = notbootedfrominitium[i];
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

    printk("Kernel Start: 0x%x, Kernel End: 0x%x, Kernel Size: %d bytes (%d KB)\n", KERNEL_START, KERNEL_END, KERNEL_SIZE, ((KERNEL_END - KERNEL_START) / 1024));

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
        printk("Memory management is using a %d MB region located \nfrom 0x%x to 0x%x\n", (((memory_management_region_end - memory_management_region_start) / 1024) / 1024),
        memory_management_region_start, memory_management_region_end);
    } else {
    	printk("Unknown Command: ");
    	printk(input);
    }
    printk("\n> ");
}