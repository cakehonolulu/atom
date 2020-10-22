#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>
#include <kernel.h>

uintptr_t placement_address = 0;

size_t arch_mmu_get_max_phys_mem(bool inKiloBytes)
{
	if (inKiloBytes == true)
	{
		return (((memory_management_region_end - memory_management_region_start) / 1024));
	}
	else
	{
		return (memory_management_region_end - memory_management_region_start);
	}
} 

void arch_mmu_init()
{
	placement_address = arch_mmap_init();

	if (!placement_address)
	{
		printk("No placement address! Halting...");
		asm volatile ("cli;hlt");
	}
}

size_t kmalloc_s(size_t size, bool align, uintptr_t *physAddr)
{
	if (align == true && (placement_address & 0x00000FFF))
	{
		placement_address &= 0xFFFFF000;
		placement_address += 0x1000;
	}

	if (physAddr)
	{
		*physAddr = placement_address;
	}

	uintptr_t tmp = placement_address;
	placement_address += size;
	return tmp;
}

size_t kmalloc_a(size_t size) // Aligned
{
    return kmalloc_s(size, true, NULL);
}

size_t kmalloc_p(size_t size, uintptr_t *physAddr) // Return physical address
{
    return kmalloc_s(size, false, physAddr);
}

size_t kmalloc_ap(size_t size, uintptr_t *physAddr) // Mix from the two before iterations
{
    return kmalloc_s(size, true, physAddr);
}

size_t kmalloc(size_t size) // Regular kmalloc
{
    return kmalloc_s(size, false, NULL);
}
