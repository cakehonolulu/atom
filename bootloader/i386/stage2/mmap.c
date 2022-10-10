#include <stddef.h>
#include <stdint.h>

#ifdef EXT2
#define MEMORY_MAP_LOCATION (0x00000500)
#else
#ifdef FAT16
#define MEMORY_MAP_LOCATION (0x00000500)
#endif
#endif

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
    uint64_t e820_entry_base_address;
    uint64_t e820_entry_size;
    uint32_t e820_entry_type;
    uint32_t e820_entry_attribute;
};

static const char* e820_type_string[] = {
    "Unknown",
    "Usable", // Usable
    "Reserved", // Unusable
    "ACPI Reclaimable",
    "ACPI NVS Memory",
    "Bad Memory"
};

struct e820_mmap_available_entries {
   uintptr_t base_address;
   uintptr_t end_address;
};  

void parse_mmap()
{
    size_t e820_mmap_total_entries_for_counting = *(uintptr_t*)MEMORY_MAP_LOCATION;
    const struct bios_memmap_entry* entry = (const struct bios_memmap_entry*)(MEMORY_MAP_LOCATION + 8);

    uintptr_t e820_entry_base_address = 0;
    uintptr_t e820_entry_end_address = 0;
    size_t e820_entry_size = 0;

    size_t e820_counted_entries = 0;

    // Count total available entries
    while (e820_mmap_total_entries_for_counting-- != 0)
    {
        e820_counted_entries++;
    }


    puts("Memory map report: %d entries\n", e820_counted_entries);

    size_t e820_mmap_total_entries = *(uintptr_t*)MEMORY_MAP_LOCATION;

    while (--e820_mmap_total_entries != 0)
    {

        e820_entry_size = entry->e820_entry_size & 0xFFFFFFFF;
        e820_entry_base_address = entry->e820_entry_base_address & 0xFFFFFFFF;
        e820_entry_end_address = e820_entry_base_address + e820_entry_size;

        const char* t = entry->e820_entry_type <= MEMORY_TYPE_BAD_AREA ?
        e820_type_string[entry->e820_entry_type] : e820_type_string[0];

		if (((e820_entry_size / 1024) / 1024) != 0) {
			puts("Start: 0x%x; End: 0x%x Size: %d bytes (%d MB); Type: %s\n", e820_entry_base_address, e820_entry_end_address, e820_entry_size, ((e820_entry_size / 1024) / 1024), t);
		} else {
			puts("Start: 0x%x; End: 0x%x Size: %d bytes; Type: %s\n", e820_entry_base_address, e820_entry_end_address, e820_entry_size, t);
		}

        ++entry;
    }
}
