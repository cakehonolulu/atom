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
page_directory_t *arch_mmu_kernel_directory;

size_t num_frames = 0, num_frames_aligned = 0;
FRAME_BITMAP_TYPE* frame_bitmaps = NULL;

void page_fault(struct regs * regs)
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

#ifdef FOUR_MB_PAGE_SIZE
uint32_t log2_floor(uint32_t n) {
    #define S(k) if (n >= (UINT32_C(1) << k)) { i += k; n >>= k; }
    int i = -(n == 0); S(16); S(8); S(4); S(2); S(1); return i;
    #undef S
}
#endif

void paging_set_frame(uint32_t frame) {
#ifdef FOUR_MB_PAGE_SIZE
    if(frame < num_frames) SET_FRAME(BITMAP_FOR_FRAME(frame), BIT_OFFSET(frame));
#endif
}

// Mark continuous frames as allocated, from phys_start up to phys_end
void paging_set_frames(uint32_t phys_start, uint32_t phys_end) {
#ifdef FOUR_MB_PAGE_SIZE
    phys_start = ALIGN_DOWN(phys_start);
    for (uint32_t frame = FRAME_FOR(phys_start); frame < FRAME_FOR(phys_end); ++frame) paging_set_frame(frame);
#endif
}

// Mark a frame as free
void paging_clear_frame(uint32_t frame) {
#ifdef FOUR_MB_PAGE_SIZE
    if(frame < num_frames) CLEAR_FRAME(BITMAP_FOR_FRAME(frame), BIT_OFFSET(frame));
#endif
}

// Mark contiguous frames as free, from phys_start up to phys_end
void paging_clear_frames(uint32_t phys_start, uint32_t phys_end) {
#ifdef FOUR_MB_PAGE_SIZE
    phys_start = ALIGN_DOWN(phys_start);
    for (uint32_t frame = FRAME_FOR(phys_start); frame < FRAME_FOR(phys_end); ++frame) paging_clear_frame(frame);
#endif
}

int paging_get_free_frame() {
#ifdef FOUR_MB_PAGE_SIZE
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
#endif
}

physaddr_t paging_alloc_frame() {
#ifdef FOUR_MB_PAGE_SIZE
    // Search for a free frame
    int free_frame = paging_get_free_frame();
    if(free_frame >= 0) {
        paging_set_frame((uint32_t) free_frame);
        return (physaddr_t) (free_frame * PAGE_SIZE);
    }
    return 0;
#endif
}

void paging_free_frame(physaddr_t addr) {
#ifdef FOUR_MB_PAGE_SIZE
    uint32_t frame = FRAME_FOR(addr);
    if(!FRAME_IS_SET(frame))
    {
      printk("Attempting to free unallocated frame %d (0x%x)\n", frame, addr);
      asm volatile ("cli; hlt");
    } else {
      paging_clear_frame(frame);
    }
#endif
}


#ifdef FOUR_MB_PAGE_SIZE
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
      memset(arch_mmu_kernel_directory, 0, sizeof(page_directory_t));
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
#endif

void arch_set_page_directory(page_directory_t* page_dir)
{
  asm volatile("mov %0, %%cr3":: "r"((physaddr_t) page_dir));
}

page_frame_t *get_page(uint32_t address, int make, page_directory_t *dir){
  // Turn the address into an index.
  uint32_t table_idx = PAGE_DIRECTORY_INDEX(address);
  uint32_t page_idx = PAGE_TABLE_INDEX(address);
  printk("\nget_page: t: %d, p: %d %x, %x, %x", table_idx, page_idx,  address, make, dir->tables[table_idx]);

  uint32_t *table = (uint32_t *) &(dir->tables[table_idx]);

  bool table_exist = false;

  if(table != NULL && dir->physical[table_idx].present != 0){// If this table is already assigned *(uint32_t *)(&dir->tables[table_idx])!=0
    table_exist = true;
    page_frame_t* page = &(dir->tables[table_idx]->pages[page_idx]);
    printk("\nTable exist: %x : %x ", dir->physical[table_idx], page);
    if (page != NULL && page->present != 0) {
      printk("\nAddress %x Already: 0x%x ", address, *page);
      return page;
    }
  }

  if(make){
    page_table_t * page_table;
    if (!table_exist) {
      // Obtenemos un bloque (4kb) para alojar una nueva tabla de páginas
      uint32_t pt_phy;
      page_table = (page_table_t *) kmalloc_ap(sizeof(page_table_t), &pt_phy); // Reemplazar con una gestion real
      // Limpiamos el area que nos han dado
      memset((uint32_t *) page_table, 0, sizeof(page_table_t));
      dir->physical[table_idx].frame = pt_phy >> 12;
      dir->physical[table_idx].present = 1;
      dir->physical[table_idx].rw = 1;
      dir->physical[table_idx].user = 1;
      dir->tables[table_idx] = page_table;
      printk("\nNew Table: %x : %x", dir->physical[table_idx], dir->tables[table_idx]);
    } else {
      page_table = dir->tables[table_idx];
    }
    // Ahora creamos la pagina en si
    page_frame_t * page = &page_table->pages[page_idx];
    alloc_frame_int(page, true, true, true, true, false, NULL);
    printk("\nReturn %x : %x : %x", page_table, page, (page->frame << 12));
    return page;
  }

  return NULL;
}

/*
 TODO: arch_usable_memory is only the available memory from the portion passed to the function by the mmap routines (Which, FOR NOW
 only support one memory region that is available and is larger than 1MB, in future, make a list of available regions and concatenate them for
 use in this function).
 */

void arch_mmu_init_paging(size_t arch_usable_memory, uintptr_t arch_mmu_virtual_base_ptr, uintptr_t arch_mmu_virtual_top_ptr, 
  uintptr_t arch_mmu_physical_base_ptr, uintptr_t arch_mmu_physical_top_ptr)
{
  // Check if there is usable memory!
	if (!arch_usable_memory)
	{
		printk("No memory available for paging! Halting...");
   		__asm__ __volatile__ ("cli; hlt");
	}

  register_interrupt_handler(14, page_fault);

#ifdef DEBUG
    //printk("Available memory size: %d B, %d KB, %d MB\n", arch_usable_memory, arch_usable_memory/1024, arch_usable_memory/1024/1024);
#endif

#ifdef FOUR_KB_PAGE_SIZE
    uintptr_t phys;
    uint32_t *new_pagedir = kmalloc_ap(sizeof(page_directory_t));
    memset(new_pagedir, 0, sizeof(page_directory_t));
    arch_mmu_kernel_directory = (page_directory_t *) new_pagedir;
    uint32_t kernel_space_end = ((uint32_t) new_pagedir) + sizeof(page_directory_t);

    for(uint32_t i = KERNEL_VIRTUAL_BASE; i <= kernel_space_end; i += PAGE_SIZE)
    {
      page_frame_t *pg = get_page(i, 1, arch_mmu_kernel_directory);
      free_frame(pg);
      alloc_frame_int(pg, true, true, true, true, true, i - KERNEL_VIRTUAL_BASE);
    }

    arch_set_page_directory((page_directory_t *) (uintptr_t) VIRTUAL_TO_PHYSICAL((uintptr_t) arch_mmu_kernel_directory));
#endif

#ifdef FOUR_MB_PAGE_SIZE
  // We can allocate the structure needed for paging since we now have the MMU in a well-known state
  arch_mmu_kernel_directory = kmalloc_a(sizeof(page_directory_t));

  paging_map_4mb_dir(arch_mmu_kernel_directory, ALIGN_DOWN(arch_mmu_physical_base_ptr), ALIGN_UP(arch_mmu_physical_top_ptr),
   ALIGN_DOWN(arch_mmu_virtual_base_ptr), ALIGN_UP(arch_mmu_virtual_top_ptr));
#endif

#ifdef DEBUG
  printk("arch_mmu_pd_phys_addr: 0x%x, kern_dir: 0x%x\n", VIRTUAL_TO_PHYSICAL((uintptr_t) arch_mmu_kernel_directory), (uintptr_t) arch_mmu_kernel_directory);
#endif

#ifdef FOUR_MB_PAGE_SIZE
  num_frames = (ALIGN_UP(arch_usable_memory)/* Align Up the total memory segment */) / PAGE_SIZE;

#ifdef DEBUG
  printk("num_frames: %d, usable_memory: %d\n", num_frames, arch_usable_memory);
#endif

  // Align so as not to lose frames that fall between bitmap boundaries
  num_frames_aligned = num_frames % FRAMES_PER_BITMAP != 0 ? num_frames - (num_frames % FRAMES_PER_BITMAP) + FRAMES_PER_BITMAP : num_frames;

  size_t bitmap_size = (size_t) (num_frames_aligned / FRAMES_PER_BITMAP) * sizeof(FRAME_BITMAP_TYPE);

  frame_bitmaps = kmalloc(bitmap_size);

  if(frame_bitmaps)
  {
    memset(frame_bitmaps, 0, bitmap_size);
    paging_set_frames(ALIGN_DOWN(arch_mmu_physical_base_ptr), ALIGN_UP(arch_mmu_physical_top_ptr));
        
  }

  arch_set_page_directory((page_directory_t *) (uintptr_t) VIRTUAL_TO_PHYSICAL((uintptr_t) arch_mmu_kernel_directory));

#endif
}
