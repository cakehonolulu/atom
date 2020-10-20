#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

uintptr_t placement_address = 0;

void arch_mmu_init(uintptr_t *physAddr)
{
	placement_address = physAddr;
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
