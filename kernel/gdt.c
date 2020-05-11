#include "gdt.h"

/* GDT structure */
struct i386_gdt_entry i386_gdt[5];
/* GDT pointer */
struct i386_gdt_descriptor i386_gdt_pointer;

/* Function to craft a descriptor for the Global Descriptor Table */
void i386_gdt_add_entry(unsigned int i386_gdt_entry_num, unsigned long i386_gdt_entry_base, unsigned long i386_gdt_entry_limit, unsigned char i386_gdt_access, unsigned char i386_gdt_flags)
{
	if ((i386_gdt_entry_limit > sizeof(unsigned char)) && (i386_gdt_entry_limit & 0xFFF) != 0xFFF)
	{
		// TODO: Inform the user that it has exceeded maximum
		// number of GDT entries or that the GDT size equals to 0
		vga_printk("Can't encode a GDT entry with a that size!\n");
		vga_printk("Halting...\n");
		__asm__ __volatile__ ("cli");
		__asm__ __volatile__ ("hlt");
	}

	if (i386_gdt_entry_limit > sizeof(unsigned char))
	{
		i386_gdt[i386_gdt_entry_num].limitandflags = i386_gdt[i386_gdt_entry_num].limitandflags >> 12;
		i386_gdt[i386_gdt_entry_num].limitandflags = 0xC0;
	} else {
		i386_gdt[i386_gdt_entry_num].limitandflags = 0x40;
	}

	// 1 byte = 8 bits [!]
	// 1 byte to hex = 0xFF
	i386_gdt[i386_gdt_entry_num].limit0_15 = (i386_gdt_entry_limit & 0xFFFF);			// If i386_gdt_entry_limit = 0x41424344, & 0xFFFF ('AND') will result in 0x4344 (2 bytes)
	i386_gdt[i386_gdt_entry_num].base0_15 = (i386_gdt_entry_base & 0xFFFF);				// If i386_gdt_entry_base = 0x41424344, & 0xFFFF ('AND') will result in 0x4344 (2 bytes)
	i386_gdt[i386_gdt_entry_num].base16_23 = ((i386_gdt_entry_base >> 16) & 0xFF);		// If i386_gdt_entry_base = 0x41424344, Right bitshifting (16 bits) will result in 0x4142,
																						// 'AND'-ing 0xFF to that will result in the 0x42
	i386_gdt[i386_gdt_entry_num].access = i386_gdt_access;								// Both variables have the same byte size, no operations needed
	
	// Difficult part!
	// We're going to first craft the limit and then the flags
	// Limit:
	i386_gdt[i386_gdt_entry_num].limitandflags = ((i386_gdt_entry_limit >> 16) & 0x0F);	// If i386_gdt_entry_base = 0x41424344, Right bitshifting (16 bits) will result in 0x4142,
																						// 'AND'-ing 0x0F to that will result in the 0x2 (Half byte)

	// Flags:
	i386_gdt[i386_gdt_entry_num].limitandflags |= (i386_gdt_flags & 0xF0);

	i386_gdt[i386_gdt_entry_num].base24_31 = ((i386_gdt_entry_base >> 24) & 0xFF); 		// If i386_gdt_entry_base = 0x41424344, Right bitshifting (24 bits) will result in 0x41,
																						// 'AND'-ing 0xFF to that will result in the 0x41
}

/* Called on architecture init.
   Setups the first 3 GDT entries
   and switches the resulting crafted
   GDT to the processor and updates
   the segment registers */
int i386_gdt_install()
{
	/* Setup GDT limit */
    i386_gdt_pointer.gdt_entry_size = (sizeof(struct i386_gdt_entry) * 5) - 1;

    /* Setup GDT pointer */
    i386_gdt_pointer.gdt_entry_offset = (unsigned int) &i386_gdt;

    /* GDT Null Descriptor */
    i386_gdt_add_entry(0, 0, 0, 0, 0);

    /* GDT Code Segment */
    // Segment Type: Code
    // Base adress: 0
    // High adress: 4 Gigabytes
    // Granularity: 4 Kilobyte
    // Opcode: 32-bit
    i386_gdt_add_entry(1, 0, 0xFFFFFFFF, I386_GDT_CODE_RING0_ACCESS, 0xCF);

    /* GDT Data Segment */
    // Segment Type: Data
    // Rest is same as Code Segment
    i386_gdt_add_entry(2, 0, 0xFFFFFFFF, I386_GDT_DATA_RING0_ACCESS, 0xCF);

    /* GDT Code Segment */
    // Segment Type: Code
    i386_gdt_add_entry(3, 0, 0xFFFFFFFF, I386_GDT_CODE_RING3_ACCESS, 0xCF);

    /* GDT Code Segment */
    // Segment Type: Code
    i386_gdt_add_entry(4, 0, 0xFFFFFFFF, I386_GDT_DATA_RING3_ACCESS, 0xCF);

    /* TODO: Write TSS Info on the GDT Table */

    /* Replace old GDT with the new one by 
       flushing all the changes */
    i386_gdt_update((unsigned int)&i386_gdt_pointer);

    /* TODO: Update Task State Segment */
    return 1;
}