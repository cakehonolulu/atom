#include "gdt.h"
#include "utils.h"

/* GDT structure */
struct i386_gdt_entry arch_gdt[ARCH_MAX_GDT_ENTRIES];
/* GDT pointer */
struct i386_gdt_descriptor arch_gdt_pointer;

/* Function to craft a descriptor for the Global Descriptor Table */
void arch_gdt_add_entry(unsigned int arch_gdt_entry_num, unsigned long arch_gdt_entry_base, unsigned long arch_gdt_entry_limit, unsigned char arch_gdt_access, unsigned char arch_gdt_flags)
{
	if ((arch_gdt_entry_limit > sizeof(unsigned char)) && (arch_gdt_entry_limit & 0xFFF) != 0xFFF)
	{
		// TODO: Inform the user that it has exceeded maximum
		// number of GDT entries or that the GDT size equals to 0
		printk("Can't encode a GDT entry with a that size!\nHalting...\n");
		__asm__ __volatile__ ("cli");
		__asm__ __volatile__ ("hlt");
	}

	if (arch_gdt_entry_limit > sizeof(unsigned char))
	{
		arch_gdt[arch_gdt_entry_num].limitandflags = arch_gdt[arch_gdt_entry_num].limitandflags >> 12;
		arch_gdt[arch_gdt_entry_num].limitandflags = 0xC0;
	} else {
		arch_gdt[arch_gdt_entry_num].limitandflags = 0x40;
	}

	// 1 byte = 8 bits [!]
	// 1 byte to hex = 0xFF
	arch_gdt[arch_gdt_entry_num].base0_15 = low_16(arch_gdt_entry_base);				// If arch_gdt_entry_base = 0x41424344, & 0xFFFF ('AND') will result in 0x4344 (2 bytes)
	arch_gdt[arch_gdt_entry_num].base16_23 = ((arch_gdt_entry_base >> 16) & 0xFF);		// If arch_gdt_entry_base = 0x41424344, Right bitshifting (16 bits) will result in 0x4142,
																						// 'AND'-ing 0xFF to that will result in the 0x42
	arch_gdt[arch_gdt_entry_num].base24_31 = ((arch_gdt_entry_base >> 24) & 0xFF); 		// If arch_gdt_entry_base = 0x41424344, Right bitshifting (24 bits) will result in 0x41,
																						// 'AND'-ing 0xFF to that will result in the 0x41

	// Difficult part!
	// We're going to first craft the limit and then the flags
	// Limit:
	arch_gdt[arch_gdt_entry_num].limit0_15 = low_16(arch_gdt_entry_limit);			// If arch_gdt_entry_limit = 0x41424344, & 0xFFFF ('AND') will result in 0x4344 (2 bytes)
	arch_gdt[arch_gdt_entry_num].limitandflags = ((arch_gdt_entry_limit >> 16) & 0x0F);	// If arch_gdt_entry_base = 0x41424344, Right bitshifting (16 bits) will result in 0x4142,
																						// 'AND'-ing 0x0F to that will result in the 0x2 (Half byte)

	// Flags:
	arch_gdt[arch_gdt_entry_num].limitandflags |= (arch_gdt_flags & 0xF0);

	arch_gdt[arch_gdt_entry_num].access = arch_gdt_access;								// Both variables have the same byte size, no operations needed
}

/* Called on architecture init.
   Setups the first 3 GDT entries
   and switches the resulting crafted
   GDT to the processor and updates
   the segment registers */
int arch_gdt_install()
{
	/* Setup GDT limit */
    arch_gdt_pointer.gdt_entry_size = (sizeof(struct i386_gdt_entry) * 5) - 1;

#ifdef DEBUG
    printk("GDT Debugging:\nGDT Entry: 0x%x\n", arch_gdt_pointer.gdt_entry_size);
    printk("GDT Code Segment Selector: 0x%x\n", (unsigned int)ARCH_GDT_KERNEL_CODE_SEGMENT_SELECTOR);
    printk("GDT Data Segment Selector: 0x%x\n", (unsigned int)ARCH_GDT_KERNEL_DATA_SEGMENT_SELECTOR);
#endif

    /* Setup GDT pointer */
    arch_gdt_pointer.gdt_entry_offset = (unsigned int) &arch_gdt;

    /* GDT Null Descriptor */
    arch_gdt_add_entry(0, 0, 0, 0, 0);

    /* GDT Code Segment */
    // Segment Type: Code
    // Base adress: 0
    // High adress: 4 Gigabytes
    // Granularity: 4 Kilobyte
    // Opcode: 32-bit
    arch_gdt_add_entry(1, 0, 0xFFFFFFFF, I386_GDT_CODE_RING0_ACCESS, I386_GDT_FLAGS);

    /* GDT Data Segment */
    // Segment Type: Data
    // Rest is same as Code Segment
    arch_gdt_add_entry(2, 0, 0xFFFFFFFF, I386_GDT_DATA_RING0_ACCESS, I386_GDT_FLAGS);

    /* GDT Code Segment */
    // Segment Type: Code
    arch_gdt_add_entry(3, 0, 0xFFFFFFFF, I386_GDT_CODE_RING3_ACCESS, I386_GDT_FLAGS);

    /* GDT Code Segment */
    // Segment Type: Code
    arch_gdt_add_entry(4, 0, 0xFFFFFFFF, I386_GDT_DATA_RING3_ACCESS, I386_GDT_FLAGS);

    /* TODO: Write TSS Info on the GDT Table */

    /* Replace old GDT with the new one by 
       flushing all the changes */
    arch_gdt_update((unsigned int)&arch_gdt_pointer, ARCH_GDT_KERNEL_CODE_SEGMENT_SELECTOR, ARCH_GDT_KERNEL_DATA_SEGMENT_SELECTOR);

    /* TODO: Update Task State Segment */
    return 1;
}