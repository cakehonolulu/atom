#include <mmap.h>

// FIXME: For now, we'll just use 1 memory region, later
// on we'll keep track of all of them, order them and use
// them accordingly.
uintptr_t memory_management_region_start = 0;
uintptr_t memory_management_region_end = 0;

size_t arch_e820_usable_memory_regions = 0;

// HACK: Returns ONLY the usable memory region base address if it has a MB or more
// TODO: Clean up the code, optimize it and return more information!
// TODO: Maybe reconfigure the memory map location as a argument so that it can be changed?
uintptr_t arch_mmap_init(uintptr_t arch_mmu_kernel_base_ptr, uintptr_t arch_mmu_kernel_top_ptr)
{
    size_t arch_e820_mmap_total_entries_for_counting = *(uintptr_t*)ARCH_MEMORY_MAP_LOCATION;
    const struct bios_memmap_entry* entry = (const struct bios_memmap_entry*)(ARCH_MEMORY_MAP_LOCATION + 8);

    uintptr_t arch_e820_entry_base_address = 0;
    uintptr_t arch_e820_entry_end_address = 0;
    size_t arch_e820_entry_size = 0;

    size_t arch_e820_counted_entries = 0;

    // Count total available entries
    while (arch_e820_mmap_total_entries_for_counting-- != 0)
    {
        arch_e820_counted_entries++;
    }

#ifdef DEBUG
    printk("Memory map report: %d entries\n", arch_e820_counted_entries);
#endif

    // Only allocate as much entries as needed (Same as total mmap entries)
    // FIXME: Could be more optimal!
    struct arch_e820_mmap_available_entries arch_memory_map[arch_e820_counted_entries];

    for (int i = 0; i <= arch_e820_counted_entries; i++)
    {
        arch_memory_map[arch_e820_counted_entries].base_address = 0;
        arch_memory_map[arch_e820_counted_entries].end_address = 0;
#ifdef DEBUG
        printk("%d base: %d end %d\n", i, arch_memory_map[arch_e820_counted_entries].base_address, arch_memory_map[arch_e820_counted_entries].end_address);
#endif  
    }

    size_t arch_e820_mmap_total_entries = *(uintptr_t*)ARCH_MEMORY_MAP_LOCATION;

    while (arch_e820_mmap_total_entries-- != 0)
    {

        arch_e820_entry_size = entry->arch_e820_entry_size & 0xFFFFFFFF;
        arch_e820_entry_base_address = entry->arch_e820_entry_base_address & 0xFFFFFFFF;
        arch_e820_entry_end_address = arch_e820_entry_base_address + arch_e820_entry_size;

        const char* t = entry->arch_e820_entry_type <= MEMORY_TYPE_BAD_AREA ?
        arch_e820_type_string[entry->arch_e820_entry_type] : arch_e820_type_string[0];

        if (entry->arch_e820_entry_type == MEMORY_TYPE_USABLE)
        {

            /*
                    Access arch_e820_mmap_available_entries[x] (1 as an example):
                    arch_e820_mmap_available_entries[1] -> Start Address:   0xAAAAAAAA
                                                        -> End Address:     0xBBBBBBBB
                
            */
            arch_memory_map[arch_e820_usable_memory_regions].base_address = arch_e820_entry_base_address;
            arch_memory_map[arch_e820_usable_memory_regions].end_address = arch_e820_entry_end_address;
            // Usable memory region!
            // We should keep track of it.
            // Later on, we should also check the size and see if it fits our needs.

#ifdef DEBUG
            printk("Found an usable memory portion! -> 0x%x -> 0x%x\n", arch_memory_map[arch_e820_usable_memory_regions].base_address, arch_memory_map[arch_e820_usable_memory_regions].end_address);
#endif

            arch_e820_usable_memory_regions++; // This spans the real number, not the array describing it's base & end address!
        }

#ifdef DEBUG
		if (((arch_e820_entry_size / 1024) / 1024) != 0) {
			printk("Start: 0x%x; End: 0x%x Size: %d bytes (%d MB); Type: %s\n", arch_e820_entry_base_address, arch_e820_entry_end_address, arch_e820_entry_size, ((arch_e820_entry_size / 1024) / 1024), t);
		} else {
			printk("Start: 0x%x; End: 0x%x Size: %d bytes; Type: %s\n", arch_e820_entry_base_address, arch_e820_entry_end_address, arch_e820_entry_size, t);
		}
#endif

        ++entry;
    }

#ifdef DEBUG
    printk("arch_e820_usable_memory_regions: %d, memory_locations_max[%d]\n", arch_e820_usable_memory_regions, ((arch_e820_usable_memory_regions * 2) - 1));
#endif

    //printk("MMAP total entries: %d\n", arch_e820_counted_entries);

    size_t size = 0;

    for (int i = 0; i <= (arch_e820_usable_memory_regions - 1); i++)
    {
        if (arch_memory_map[i].end_address != 0) // For now use end!
        {
#ifdef DEBUG
            printk("MMAP i: %d\n", i);
#endif
            size = (arch_memory_map[i].end_address - arch_memory_map[i].base_address);
#ifdef DEBUG
            printk("MMAP baddr: 0x%x endaddr: 0x%x, size: %d\n", arch_memory_map[i].base_address, arch_memory_map[i].end_address, size);
#endif

            if (size >= 0x100000) // 1MB
            {
#ifdef DEBUG
                printk("HEY!, we got start: 0x%x, end: 0x%x\n", arch_memory_map[i].base_address, arch_memory_map[i].end_address);
#endif

                memory_management_region_start = arch_memory_map[i].base_address;
                memory_management_region_end = arch_memory_map[i].end_address;
            }
        }
    }

    printk("memory_management_region_start: 0x%x\n", memory_management_region_start);

    // Check if they collide!
    // TODO: Revise the logic, there are many other possible cases where memory corruption might happen!
    if (memory_management_region_start == arch_mmu_kernel_base_ptr)
    {
        printk("Masking the kernel portion of the first free memory hole as non-usable...\n");
        memory_management_region_start = (memory_management_region_start + ((arch_mmu_kernel_top_ptr - arch_mmu_kernel_base_ptr) + 1));
        return (memory_management_region_start + ((arch_mmu_kernel_top_ptr - arch_mmu_kernel_base_ptr) + 1));
    } else {
        return memory_management_region_start;
    }
}
