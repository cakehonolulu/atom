#include <mmap.h>

static const char* e820_type_string[] = {
    "Unknown",
    "Usable", // Usable
    "Reserved", // Unusable
    "ACPI Reclaimable",
    "ACPI NVS Memory",
    "Bad Memory"
};

uint32_t parse_mmap()
{
    // Defined in the linker file
    extern char mmap[];

    size_t e820_mmap_total_entries_for_counting = *(uintptr_t*)MEMORY_MAP_LOCATION;
    const struct bios_memmap_entry* entry = (const struct bios_memmap_entry*)(MEMORY_MAP_LOCATION + 8);

    uintptr_t e820_entry_base_address = 0, e820_entry_end_address = 0;
    size_t e820_entry_size = 0, e820_counted_entries = 0, e820_mmap_total_entries;

    const char* t;

    // Count total available entries
    while (--e820_mmap_total_entries_for_counting != 0)
    {
        e820_counted_entries++;
    }

    puts("mmap: %d entries\n", e820_counted_entries);

    e820_mmap_total_entries = *(uintptr_t*)MEMORY_MAP_LOCATION;

    cputs("Start", 0x0B);
    puts("     ");
    cputs("|", 0x0B);
    puts(" ");
    cputs("End", 0x0B);
    puts("       ");
    cputs("|", 0x0B);
    puts(" ");
    cputs("Size", 0x0B);
    puts("      ");
    cputs("|", 0x0B);
    puts(" ");
    cputs("Type", 0x0B);
    puts("\n");

    // Cast the symbol location to a variable
    uint32_t *mmap_loc = &mmap;

    while (--e820_mmap_total_entries != 0)
    {
        e820_entry_size = entry->e820_entry_size & 0xFFFFFFFF;

        e820_entry_base_address = entry->e820_entry_base_address & 0xFFFFFFFF;
        e820_entry_end_address = e820_entry_base_address + e820_entry_size;

        t = entry->e820_entry_type <= MEMORY_TYPE_BAD_AREA ? e820_type_string[entry->e820_entry_type] : e820_type_string[0];

		puts("0x%08x  0x%08x  0x%08x  %s\n", e820_entry_base_address, e820_entry_end_address, e820_entry_size, t);

        /*
            From here onwards, perform a simple conversion from E820 layout to a multiboot 1 compatible layout,
            to do so, we only need to perform subtle memory manipulation operations to store the values in the
            correct order and spanning for multiboot-compatible kernels to use.
            
            The fields are defined like this:
            multiboot_uint32_t size;
            multiboot_uint64_t addr;
            multiboot_uint64_t len;
            multiboot_uint32_t type;

            TODO/FIX?:
            We store the values right after stage 2 binary ending, that area should not give problems; if it does,
            maybe reserving some space for the converted MMAP on the linker could help considering the system
            it'll run on is not memory constrained
        */
        // Handle multiboot_uint32_t size
        *mmap_loc = 20;
        mmap_loc += 1;

        // Handle multiboot_uint32_t addr
        *mmap_loc = e820_entry_base_address;
        mmap_loc += 2;

        // Handle multiboot_uint32_t len
        *mmap_loc = e820_entry_size;
        mmap_loc += 2;

        // Handle multiboot_uint32_t type
        *mmap_loc = entry->e820_entry_type;
        mmap_loc += 1;

        // Next entry
        entry++;
    }

    return e820_counted_entries;
}
