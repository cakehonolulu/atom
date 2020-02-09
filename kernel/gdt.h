/*	Useful GDT information [!]
	No GDT can be size 0	
	GDT entries contain a total of 64 bits (8 bytes)
	GDT can hold a total of 8192 entries (gdt_entry_size/i386_gdt_entry = 65535/8 = 8192)
	Limit (0:15)	  | Base (0:15)		  | Base (16:23)	| Access Byte	  | Limit (16:19)	  | Flags			  | Base (24:31)
	16 bits	(2 bytes) | 16 bits (2 bytes) | 8 bits (1 byte) | 8 bits (1 byte) | 4 bits (1/2 byte) | 4 bits (1/2 byte) | 8 bits (1 byte)
	0-15			  | 16-31			  | 32-39			| 40-47			  | 48-51			  | 52-55			  | 56-63
*/
struct i386_gdt_entry // (8 bytes total)
{
    unsigned short limit0_15; // 2 bytes
    unsigned short base0_15; // 2 bytes
    unsigned char base16_23; // 1 byte
    unsigned char access; // 1 byte
    unsigned char limitandflags; // 1/2 byte limit (16:19) and 1/2 byte containing flags
    unsigned char base24_31; // 1 byte
} __attribute__((packed));

/* GDT's pointer scheme */
struct i386_gdt_descriptor
{
    unsigned short gdt_entry_size; // 2 bytes (0 -> 65535) -> i386_gdt_entry minus 1 [!]
    unsigned int gdt_entry_offset; // 4 bytes (0 -> 4294967295) -> Up to 4 GiB descriptors (4294967295)
} __attribute__ ((packed));

/* cake: Function declared on another file
   to reload the segment registers and swap
   out CPU's GDT table with ours */
extern void i386_gdt_update(unsigned int);
void i386_gdt_install();
