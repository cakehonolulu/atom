#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>
#include <kernel.h>

uintptr_t arch_mmu_tmp_base_address = 0;

void arch_mmu_init(uintptr_t arch_mmu_kernel_base_ptr, uintptr_t arch_mmu_kernel_top_ptr)
{
	// HACK: Memory region provided by arch_mmap_init is
	// ensured to be AT LEAST, 1MB in size, which is probably more
	// than enough for now, but this is hacky and should probably be avoided.

	// TODO: Return more information (Maybe a struct?) such as
	// top address and/or size just to name a few bits of stuff.

	// TODO: Whenever I manage to implement a menuconfig-like
	// config scheme, let the user decide if it should be compiled
	// using the Higher-Half memory scheme.

	// BUG?: If we have 1MB into address space as start address free, we might
	// have a bug where we overwrite kernel parts!
	// Kernel Pos after PADDR -> VADDR 0xC0100000;
	
	printk("arch_mmu_kernel_base_ptr: 0x%x, arch_mmu_kernel_top_ptr: 0x%x\n", arch_mmu_kernel_base_ptr, arch_mmu_kernel_top_ptr);
	
	arch_mmu_tmp_base_address = (arch_mmap_init(arch_mmu_kernel_base_ptr, arch_mmu_kernel_top_ptr) + 0xC0000000);

	printk("Placeholder base address: 0x%x\n", arch_mmu_tmp_base_address);

	if (!arch_mmu_tmp_base_address)
	{
		printk("No placement address! Halting...");
		asm volatile ("cli;hlt");
	}
}

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

size_t kmalloc_s(size_t size, bool align, uintptr_t *physAddr)
{
	if (align == true && (arch_mmu_tmp_base_address & 0x00000FFF))
	{
		arch_mmu_tmp_base_address &= 0xFFFFF000;
		arch_mmu_tmp_base_address += 0x1000;
	}

	if (physAddr)
	{
		*physAddr = arch_mmu_tmp_base_address;
	}

	uintptr_t tmp = arch_mmu_tmp_base_address;
	arch_mmu_tmp_base_address += size;
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
