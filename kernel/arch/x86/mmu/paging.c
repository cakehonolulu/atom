#include <paging.h>
#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

#define PAGE_FAULT_PROTECTION (1 << 0)
#define PAGE_FAULT_WRITE (1 << 1)
#define PAGE_FAULT_USER (1 << 2)
#define PAGE_FAULT_RESERVED (1 << 3)
#define PAGE_FAULT_EXEC (1 << 4)

// The kernel's page directory
page_directory_t* kernel_directory = NULL;

uint32_t num_frames = 0, num_frames_aligned = 0;
FRAME_BITMAP_TYPE* frame_bitmaps = NULL;

uint32_t log2_floor(uint32_t n) {
    #define S(k) if (n >= (UINT32_C(1) << k)) { i += k; n >>= k; }
    int i = -(n == 0); S(16); S(8); S(4); S(2); S(1); return i;
    #undef S
}

void page_fault(registers_t *regs)
{
    uint32_t err_code = regs->err_code;
    bool protection_err = (bool)(err_code & PAGE_FAULT_PROTECTION), write_err = (bool)(err_code & PAGE_FAULT_WRITE),
        user_err = (bool)(err_code & PAGE_FAULT_USER), reserved_err = (bool)(err_code & PAGE_FAULT_RESERVED),
        exec_err = (bool)(err_code & PAGE_FAULT_EXEC);
    uint32_t bad_addr;
    asm volatile("mov %%cr2, %0": "=r"(bad_addr));
    printk("Page fault for address 0x%x: %s%s%s, %s, %s\n", bad_addr, reserved_err ? "reserved, " : "", exec_err ? "execution, " : "",
            protection_err ? "protection" : "non-present", write_err ? "write" : "read", user_err ? "user" : "supervisor");
    asm volatile("cli; hlt");
}

void paging_set_frame(uint32_t frame) {
    if(frame < num_frames) SET_FRAME(BITMAP_FOR_FRAME(frame), BIT_OFFSET(frame));
}

// Mark continuous frames as allocated, from phys_start up to phys_end
void paging_set_frames(uint32_t phys_start, uint32_t phys_end) {
    phys_start = ALIGN_DOWN(phys_start);
    for (uint32_t frame = FRAME_FOR(phys_start); frame < FRAME_FOR(phys_end); ++frame) paging_set_frame(frame);
}

// Mark a frame as free
void paging_clear_frame(uint32_t frame) {
    if(frame < num_frames) CLEAR_FRAME(BITMAP_FOR_FRAME(frame), BIT_OFFSET(frame));
}

// Mark contiguous frames as free, from phys_start up to phys_end
void paging_clear_frames(uint32_t phys_start, uint32_t phys_end) {
    phys_start = ALIGN_DOWN(phys_start);
    for (uint32_t frame = FRAME_FOR(phys_start); frame < FRAME_FOR(phys_end); ++frame) paging_clear_frame(frame);
}

int paging_get_free_frame() {
    for (uint32_t i = 0; i < NUM_BITMAPS; ++i) {
        FRAME_BITMAP_TYPE bitmap = frame_bitmaps[i];
        // If at least one bit in the bitmap is clear
        if(bitmap != FRAME_FULL) {
            uint32_t frame = 0;
            // If it's zero then bit 1 is the first one free
            if(bitmap == 0) frame = 0;
            else {
                // The bit corresponding to the free page
                FRAME_BITMAP_TYPE mask = 0;
                mask = ~bitmap & (bitmap + 1);
                // Log in order to get the bit's position in the bitmap
                frame = log2_floor(mask);
            }
            return frame + i * FRAMES_PER_BITMAP;
        }
    }
    return -1;
}

physaddr_t paging_alloc_frame() {
    // Search for a free frame
    int free_frame = paging_get_free_frame();
    if(free_frame >= 0) {
        paging_set_frame((uint32_t) free_frame);
        return (physaddr_t) (free_frame * PAGE_SIZE);
    }
    return 0;
}

void paging_free_frame(physaddr_t addr) {
    uint32_t frame = FRAME_FOR(addr);
    if(!FRAME_IS_SET(frame))
    {
      printk("Attempting to free unallocated frame %d (0x%x)\n", frame, addr);
      asm volatile ("cli; hlt");
    } else {
      paging_clear_frame(frame);
    }
}


void paging_map_4mb_page(page_directory_t* dir, uint32_t page, uint32_t phys_addr) {
    page_dir_entry_t* dir_entry = &dir->entries[page];
    dir_entry->accessed = 0;
    dir_entry->caching_disabled = 0;
    dir_entry->four_megabyte_pages = 1;
    dir_entry->available = 0;
    dir_entry->present = 1;
    dir_entry->user_level = 0;
    dir_entry->writable = 1;
    dir_entry->write_through = 1;
    //ASSERT_PAGE_ALIGNED("table physical alignment", phys_addr);
    // Shift to isolate the top 10 bits (the 4MiB aligned physical address)
    dir_entry->page_physical_addr = phys_addr >> 22;
}

void paging_map_4mb_dir(page_directory_t* dir, uint32_t phys_start, uint32_t phys_end, uint32_t virtual_start, uint32_t virtual_end) {
    if (phys_start > phys_end)
    {
      //PANIC("Improper start and end physical addresses");
      printk("Improper start and end physical addresses");
      asm volatile("cli; hlt");
    }

    if(!IS_PAGE_ALIGNED(phys_start) || !IS_PAGE_ALIGNED(phys_end))
    {
      //PANIC("Physical addresses are not page aligned");
      printk("Physical addresses are not page aligned");
      asm volatile("cli; hlt");
    }

    if (virtual_start > virtual_end)
    {
      //PANIC("Improper start and end virtual addresses");
      printk("Improper start and end virtual addresses");
      asm volatile("cli; hlt");
    }

    if(!IS_PAGE_ALIGNED(virtual_start) || !IS_PAGE_ALIGNED(virtual_end))
    {
      //PANIC("Virtual addresses are not page aligned");
      printk("Virtual addresses are not page aligned");
      asm volatile("cli; hlt");
    }

    if(virtual_end - virtual_start != phys_end - phys_start)
    {
      //PANIC("Virtual space is not equal to physical space");
      printk("Virtual space is not equal to physical space");
      asm volatile("cli; hlt");
    }

    if (dir) {
        memset(dir, 0, sizeof(page_directory_t));
        uint32_t virtual_addr = virtual_start, phys_addr = phys_start;
        uint32_t page = virtual_addr / PAGE_SIZE;

        while (page < PAGE_TABLE_ENTRIES_PER_DIRECTORY && virtual_addr <= virtual_end) {
            paging_map_4mb_page(dir, page, phys_addr);
            phys_addr += PAGE_SIZE;
            virtual_addr += PAGE_SIZE;
            page++;
        }
    }
}

void arch_set_page_directory(page_directory_t* page_dir) {
    asm volatile("mov %0, %%cr3":: "r"((physaddr_t)page_dir));
}

void initialise_paging(size_t memsize, uint32_t virtual_start, uint32_t virtual_end, uint32_t phys_start, uint32_t phys_end)
{
	if (!memsize)
	{
		printk("No memory available for paging! Halting...");
   		__asm__ __volatile__ ("cli; hlt");
	}

#ifdef DEBUG
    printk("Available memory size: %d B, %d KB, %d MB\n", memsize, memsize/1024, memsize/1024/1024);

#endif

  uint32_t mem_aligned = ALIGN_UP(memsize);

#ifdef DEBUG
    printk("Aligned memory: %d\n", mem_aligned);
#endif

  uint32_t code_phys_start = phys_start;
  uint32_t code_phys_end = phys_end;
  uint32_t code_virt_start = virtual_start;
  uint32_t code_virt_end = virtual_end;

  uint32_t map_phys_start = ALIGN_DOWN(code_phys_start);
  uint32_t map_phys_end = ALIGN_UP(code_phys_end);
  uint32_t map_virt_start = ALIGN_DOWN(code_virt_start);
  uint32_t map_virt_end = ALIGN_UP(code_virt_end);

  kernel_directory = kmalloc_a(sizeof(page_directory_t));

  paging_map_4mb_dir(kernel_directory, map_phys_start, map_phys_end, map_virt_start, map_virt_end);

  uint32_t dir_physaddr = VIRTUAL_TO_PHYSICAL((uint32_t) kernel_directory);
#ifdef DEBUG
  printk("dir_physaddr: 0x%x, kern_dir: 0x%x\n", dir_physaddr, (uint32_t) kernel_directory);
#endif
  arch_set_page_directory((page_directory_t *) (uint32_t) dir_physaddr);


    num_frames = mem_aligned / PAGE_SIZE;
    //printk("f ");
    // Align so as not to lose frames that fall between bitmap boundaries
    num_frames_aligned = num_frames % FRAMES_PER_BITMAP != 0 ? num_frames - (num_frames % FRAMES_PER_BITMAP) + FRAMES_PER_BITMAP : num_frames;
    //printk("g ");
    size_t bitmap_size = (size_t) (num_frames_aligned / FRAMES_PER_BITMAP) * sizeof(FRAME_BITMAP_TYPE);
    //printk("h ");
    frame_bitmaps = kmalloc(bitmap_size);
    //printk("i ");
    if(frame_bitmaps) {
      //printk("j ");
        memset(frame_bitmaps, 0, bitmap_size);
        //printk("k ");
        paging_set_frames(map_phys_start, map_phys_end);
        
    }


  register_interrupt_handler(14, page_fault);
}
