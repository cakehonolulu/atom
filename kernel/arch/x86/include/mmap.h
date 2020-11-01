#include <stddef.h>
#include <stdint.h>

#define ARCH_KERNEL_VIRT_BASE 0xC0000000
#define ARCH_MEMORY_MAP_LOCATION (ARCH_KERNEL_VIRT_BASE + 0x00000500)

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
    uint64_t arch_e820_entry_base_address;
    uint64_t arch_e820_entry_size;
    uint32_t arch_e820_entry_type;
    uint32_t arch_e820_entry_attribute;
};

static const char* arch_e820_type_string[] = {
    "Unknown",
    "Usable", // Usable
    "Reserved", // Unusable
    "ACPI Reclaimable",
    "ACPI NVS Memory",
    "Bad Memory"
};

struct arch_e820_mmap_available_entries {
   uintptr_t base_address;
   uintptr_t end_address;
};  
