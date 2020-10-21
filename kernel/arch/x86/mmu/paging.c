#include <paging.h>
#include <stdint.h>

// The kernel's page directory
page_directory_t *kernel_directory=0;
uint32_t page_directory[1024] __attribute__((aligned(4096)));


// The current page directory;
page_directory_t *current_directory=0;

extern uint32_t *frames;
extern uint32_t nframes;

void page_fault(registers_t *regs)
{
   // A page fault has occurred.
   // The faulting address is stored in the CR2 register.
   uint32_t faulting_address;
   __asm__ __volatile__("mov %%cr2, %0" : "=r" (faulting_address));

   // The error code gives us details of what happened.
   int present   = !(regs->err_code & 0x1); // Page not present
   int rw = regs->err_code & 0x2;           // Write operation?
   int us = regs->err_code & 0x4;           // Processor was in user-mode?
   int reserved = regs->err_code & 0x8;     // Overwritten CPU-reserved bits of page entry?
   int id = regs->err_code & 0x10;          // Caused by an instruction fetch?

   // Output an error message.
   printk("Page fault! ( ");
   if (present) {printk("present ");}
   if (rw) {printk("read-only ");}
   if (us) {printk("user-mode ");}
   if (reserved) {printk("reserved ");}
   printk(") at 0x%x\n", faulting_address);
   __asm__ __volatile__ ("cli; hlt");
   // PANIC!
}

uint32_t read_cr0() {
    uint32_t value;
    __asm__ __volatile__("mov %%cr0, %%eax" : "=a"(value));
    return value;
}

uint32_t read_cr3() {
    uint32_t value;
    __asm__ __volatile__("mov %%cr3, %%eax" : "=a"(value));
    return value;
}

void print_control_registers()
{
	printk("cr0: 0x%x, cr3: 0x%x\n", read_cr0(),read_cr3());
}

void initialise_paging(size_t memsize, uintptr_t mem_start)
{
	if (!memsize)
	{
		printk("No memory available for paging! Halting...");
   		__asm__ __volatile__ ("cli; hlt");
	}

	printk("Available memory size: %d MB\n", memsize);

  unsigned int mem_end_page = 0x1000000;

for (int i = 0; i < 1024; i++) {
        page_directory[i] = 0x00000002;
    }

page_directory[768] = 0x83 | 3;
    page_directory[0] = 0x83 | 3;
    page_directory[1] = mem_start | 3;

	nframes = memsize / 0x1000;
   frames = (uint32_t*)kmalloc_a(INDEX_FROM_BIT(nframes), 1);
   frames = (unsigned int *) ( frames + 0xC0000010);

   memset(frames, 0, INDEX_FROM_BIT(nframes));
    for (int i = 0; i < 1024; i++) {
        set_frame(i * 0xC0000000);
        set_frame(i * 0xC0000000 + mem_start /*KHEAP_START*/);
    }
    
    unsigned int addr = (unsigned int) page_directory - 0xC0000000;    

    printk("page_directory_address: 0x%x\n", addr);

    loadPageDirectory(addr);
    switch_page_directory(addr);
   // Before we enable paging, we must register our page fault handler.
   register_interrupt_handler(14, page_fault);
}

void switch_page_directory(page_directory_t *dir)
{
   current_directory = dir;
    page_directory_t * newDir = dir;
    newDir -= 0xC0000000;
    //loadPageDirectory((unsigned int * )newDir->tables);
    enablePaging();
}

page_t *get_page(uint32_t address, int make, page_directory_t *dir)
{
   // Turn the address into an index.
   address /= 0x1000;
   // Find the page table containing this address.
   uint32_t table_idx = address / 1024;
   if (dir->tables[table_idx]) // If this table is already assigned
   {
       return &dir->tables[table_idx]->pages[address%1024];
   }
   else if(make)
   {
       uint32_t tmp;
       dir->tables[table_idx] = (page_table_t*)kmalloc_ap(sizeof(page_table_t), &tmp);
       // Check if is higher halfhttps://github.com/JoniSuominen/PolarOS/blob/master/segmentation/pages.c
       memset(dir->tables[table_idx] + 0xC0000000, 0, 0x1000);
       dir->tablesPhysical[table_idx] = tmp | 0x7; // PRESENT, RW, US.
       return &dir->tables[table_idx]->pages[address%1024];
   }
   else
   {
       return 0;
   }
}
