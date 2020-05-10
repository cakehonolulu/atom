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
int i386_gdt_install();

// Flags! TODO!
#define SEG_SIZE(x)      ((x) << 0x0E) // Size (0 for 16-bit, 1 for 32)
#define SEG_GRAN(x)      ((x) << 0x0F) // Granularity (0 for 1B - 1MB, 1 for 4KB - 4GB)

// Access
#define I386_GDT_ACCESS_BIT(x)              (x)
#define I386_GDT_READ_WRITE_BIT(x)          ((x) << 0x01)           // i386 GDT Read/Write Bit (0: Code, 1: Data)
                                                                    /*
                                                                        In code segments, if bit is raised (1) the
                                                                        memory contents can be read, else, not.
                                                                        [!] Normally we don't let the code segments
                                                                        be writable!

                                                                        In data segments, if bit is raised (1) the
                                                                        memory contents can be written, else, not.
                                                                        not raised, segment grows upwards.
                                                                        [!] Normally, we are always able to write
                                                                        to the data segments.
                                                                    */
#define I386_GDT_DIRECTION_BIT(x)           ((x) << 0x02)           // i386 GDT Direction Bit
                                                                    /* 
                                                                        In code segments, if bit is raised (1) the
                                                                        code can be executed on a lower privilege
                                                                        level, else if bit is not raised (0),
                                                                        the code can only be executed on the
                                                                        privilege level specified on the "Privl" 
                                                                        bit (I386_GDT_PRIVILEGE_LEVEL_BIT)

                                                                        In data segments, if bit is raised (1) the
                                                                        segment grows downwards, else, if bit is
                                                                        not raised, segment grows upwards.
                                                                        [!] If data segment grows downwards, offset
                                                                        must be greater than the base!
                                                                    */
#define I386_GDT_EXECUTABLE_BIT(x)          ((x) << 0x03)           // i386 GDT Executable Bit (0: Data, 1: Code)
#define I386_GDT_DESCRIPTORT_TYPE_BIT(x)    ((x) << 0x04)           // i386 GDT Descriptor Type Bit (0: System, 1: Code/Data)
#define I386_GDT_PRIVILEGE_LEVEL_BIT(x)     (((x) &  0x03) << 0x05) // i386 GDT Privilege Level Bit (Ring 0 - 3)
#define I386_GDT_PRESENT_BIT(x)             ((x) << 0x07)           // i386 GDT Present Bit (0: Segment can't be used, 1: "" can be used)

#define I386_GDT_CODE_RING0_ACCESS I386_GDT_ACCESS_BIT(0)        | I386_GDT_READ_WRITE_BIT(0)        | I386_GDT_DIRECTION_BIT(0)         | \
                                   I386_GDT_EXECUTABLE_BIT(1)    | I386_GDT_DESCRIPTORT_TYPE_BIT(1)  | I386_GDT_PRIVILEGE_LEVEL_BIT(0)   | \
                                   I386_GDT_PRESENT_BIT(1)

#define I386_GDT_DATA_RING0_ACCESS I386_GDT_ACCESS_BIT(0)        | I386_GDT_READ_WRITE_BIT(1)        | I386_GDT_DIRECTION_BIT(0)         | \
                                   I386_GDT_EXECUTABLE_BIT(0)    | I386_GDT_DESCRIPTORT_TYPE_BIT(1)  | I386_GDT_PRIVILEGE_LEVEL_BIT(0)   | \
                                   I386_GDT_PRESENT_BIT(1)

#define I386_GDT_CODE_RING3_ACCESS I386_GDT_ACCESS_BIT(0)        | I386_GDT_READ_WRITE_BIT(0)        | I386_GDT_DIRECTION_BIT(0)         | \
                                   I386_GDT_EXECUTABLE_BIT(1)    | I386_GDT_DESCRIPTORT_TYPE_BIT(1)  | I386_GDT_PRIVILEGE_LEVEL_BIT(3)   | \
                                   I386_GDT_PRESENT_BIT(1)

#define I386_GDT_DATA_RING3_ACCESS I386_GDT_ACCESS_BIT(0)        | I386_GDT_READ_WRITE_BIT(1)        | I386_GDT_DIRECTION_BIT(0)         | \
                                   I386_GDT_EXECUTABLE_BIT(0)    | I386_GDT_DESCRIPTORT_TYPE_BIT(1)  | I386_GDT_PRIVILEGE_LEVEL_BIT(3)   | \
                                   I386_GDT_PRESENT_BIT(1)
