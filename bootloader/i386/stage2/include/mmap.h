#pragma once

#include <textmode.h>
#include <stddef.h>
#include <stdint.h>

#define MEMORY_MAP_LOCATION 0x00000500

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

struct e820_mmap_available_entries {
   uintptr_t base_address;
   uintptr_t end_address;
};  

/* Functions */
void parse_mmap();
