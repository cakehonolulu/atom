#include <mmap.h>

static const char* e820_type_string[] = {
    "Unknown",
    "Usable", // Usable
    "Reserved", // Unusable
    "ACPI Reclaimable",
    "ACPI NVS Memory",
    "Bad Memory"
};

void parse_mmap()
{
    size_t e820_mmap_total_entries_for_counting = *(uintptr_t*)MEMORY_MAP_LOCATION;
    const struct bios_memmap_entry* entry = (const struct bios_memmap_entry*)(MEMORY_MAP_LOCATION + 8);

    uintptr_t e820_entry_base_address = 0, e820_entry_end_address = 0;
    size_t e820_entry_size = 0, e820_counted_entries = 0, e820_mmap_total_entries;

    const char* t;

    // Count total available entries
    while (e820_mmap_total_entries_for_counting-- != 0)
    {
        e820_counted_entries++;
    }

    puts("mmap: %d entries\n", e820_counted_entries);

    e820_mmap_total_entries = *(uintptr_t*)MEMORY_MAP_LOCATION;

    puts("Start     | End       | Size      | Type\n");

    while (--e820_mmap_total_entries != 0)
    {

        e820_entry_size = entry->e820_entry_size & 0xFFFFFFFF;
        e820_entry_base_address = entry->e820_entry_base_address & 0xFFFFFFFF;
        e820_entry_end_address = e820_entry_base_address + e820_entry_size;

        t = entry->e820_entry_type <= MEMORY_TYPE_BAD_AREA ? e820_type_string[entry->e820_entry_type] : e820_type_string[0];

		puts("0x%08x  0x%08x  0x%08x  %s\n", e820_entry_base_address, e820_entry_end_address, e820_entry_size, t);

        entry++;
    }
}
