/* How every interrupt gate (handler) is defined */
struct i386_idt_entry {
    unsigned short offset0_15; /* Lower 16 bits of handler function address */
    unsigned short selector; /* Kernel segment selector */
    unsigned char zero;
    /* First byte
     * Bit 7: "Interrupt is present"
     * Bits 6-5: Privilege level of caller (0=kernel..3=user)
     * Bit 4: Set to 0 for interrupt gates
     * Bits 3-0: bits 1110 = decimal 14 = "32 bit interrupt gate" */
    unsigned char type_attr; 
    unsigned short offset16_31; /* Higher 16 bits of handler function address */
} __attribute__((packed));

/* A pointer to the array of interrupt handlers.
 * Assembly instruction 'lidt' will read it */
struct i386_idt_descriptor {
    unsigned short limit;
    unsigned int base;
} __attribute__((packed));

#define IDT_ENTRIES 256
struct i386_idt_entry i386_idt[IDT_ENTRIES];
struct i386_idt_descriptor i386_idt_pointer;

/* Functions implemented in idt.c */
void set_idt_gate(int i386_idt_entry_num, unsigned int i386_idt_handler);
void set_idt();