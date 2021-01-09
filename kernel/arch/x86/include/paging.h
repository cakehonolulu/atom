#include <isr.h>
#include <stdint.h>
#include <stddef.h>


#define KERNEL_VIRTUAL_BASE 0xC0000000
#define KERNEL_DIRECTORIES_BASE 0xF0000000
#define KERNEL_PAGE (KERNEL_VIRTUAL_BASE >> 22)
#define PAGE_TAM 0x1000
#define PAGE_TAM_4MB 0x400000
#define PAGE_MASK_L (PAGE_TAM - 1)
#define PAGE_MASK_H ~PAGE_MASK_L
#define PAGE_MASK_4MB (PAGE_TAM_4MB - 1)
#define PAGE_DEFAULT_VALUE 0x00000003
#define END_RESERVED_MEMORY 0x400000

#define KD_MAX_TAM 0X100000

// Macros used in the bitset algorithms.
#define INDEX_FROM_BIT(a) (a/(8*4))
#define OFFSET_FROM_BIT(a) (a%(8*4))

#define PAGE_SIZE_4MB 0x400000
#define PAGE_SIZE_4KB 0x1000
#define PAGE_SIZE PAGE_SIZE_4KB

#define ALIGN_DOWN(addr) ((addr) - ((addr) % PAGE_SIZE))
#define ALIGN_UP(addr) (ALIGN_DOWN(addr) + PAGE_SIZE)

#define PAGE_PRESENT 0x1
#define PAGE_WRITE 0x2
#define PAGE_USER 0x4

#define PAGE_DIRECTORY_INDEX(x) (((x) >> 22) & 0x3ff)
#define PAGE_TABLE_INDEX(x) (((x) >> 12) & 0x3ff)
#define PAGE_FRAME_ADDRESS(x) (x & ~0xfff)

#define PAGE_TABLE_ENTRIES_PER_DIRECTORY 1024
#define AMOUNT_OF_PAGES_PER_TABLE 1024


#define KERNEL_ADDR_OFFSET 0xC0000000
#define KERNEL_VIRTUAL_BASE 0xC0000000

#define VIRTUAL_TO_PHYSICAL(addr) ((addr) - KERNEL_ADDR_OFFSET)

#define IS_PAGE_ALIGNED(addr) ((addr % PAGE_SIZE) == 0)

#define FRAMES_PER_BITMAP 32
#define FRAME_BITMAP_TYPE uint32_t
#define FRAME_FULL UINT32_MAX
#define FRAME_FOR(addr) (ALIGN_DOWN(addr) / PAGE_SIZE)
#define BITMAP_FOR_FRAME(frame) frame_bitmaps[frame / FRAMES_PER_BITMAP]
#define SET_FRAME(bitmap, offset) (bitmap |= (1 << offset))
#define CLEAR_FRAME(bitmap, offset) (bitmap &= ~(1 << offset))
#define BIT_OFFSET(frame) (frame % FRAMES_PER_BITMAP)
#define NUM_BITMAPS (num_frames_aligned / FRAMES_PER_BITMAP)
#define FRAME_IS_SET(frame) ((BITMAP_FOR_FRAME(frame) & (1 << BIT_OFFSET(frame))) != 0 ? true : false)


typedef uint32_t physaddr_t;

#ifdef FOUR_MB_PAGE_SIZE

typedef struct page
{
   uint32_t present    : 1;   // Page present in memory
   uint32_t rw         : 1;   // Read-only if clear, readwrite if set
   uint32_t user       : 1;   // Supervisor level only if clear
   uint32_t accessed   : 1;   // Has the page been accessed since last refresh?
   uint32_t dirty      : 1;   // Has the page been written to since last refresh?
   uint32_t unused     : 7;   // Amalgamation of unused and reserved bits
   uint32_t frame      : 20;  // Frame address (shifted right 12 bits)
} page_t;

typedef struct page_table
{
  page_t pages[AMOUNT_OF_PAGES_PER_TABLE];
} page_table_t;

typedef struct {
    uint8_t present : 1;
    uint8_t writable : 1;
    uint8_t user_level : 1;
    uint8_t write_through : 1;
    uint8_t caching_disabled : 1;
    uint8_t accessed : 1;
    uint8_t zero : 1;
    uint8_t four_megabyte_pages : 1;
    uint8_t ignored : 1;
    // Free for use by kernel
    uint8_t available : 3;
    uint16_t reserved : 10;
    // Free for use by kernel when present == 0. Could use to store address in swap space
    uint32_t page_physical_addr : 10;
} __attribute__((packed)) page_dir_entry_t;

typedef struct {
    page_dir_entry_t entries[PAGE_TABLE_ENTRIES_PER_DIRECTORY];
    // At the end of struct so should be ignored by MMU
    page_table_t *tables[PAGE_TABLE_ENTRIES_PER_DIRECTORY];
    uint32_t      physicalAddress;
} __attribute__((packed)) page_directory_t;

#endif

#ifdef FOUR_KB_PAGE_SIZE

// A page is a 4KB physical memory division
typedef struct page_frame {
  uint32_t present  : 1;   // Page present in memory
  uint32_t rw   : 1;   // Read-only if clear, readwrite if set
  uint32_t user   : 1;   // Supervisor level only if clear
  uint32_t pwt    : 1;   // CPU Page write through
  uint32_t pcd    : 1;   // CPU Page cache disabled
  uint32_t accessed : 1;   // Has the page been accessed since last refresh?
  uint32_t dirty    : 1;   // Has the page been written to since last refresh?
  uint32_t ps   : 1;   // Is 4MB page
  uint32_t unused   : 1;  // Amalgamation of unused and reserved bits
  uint32_t avail  :3; // Available for kernel
  uint32_t frame  : 20;  // Frame address (shifted right 12 bits)
} __attribute__ ((packed)) page_frame_t;

// A page table is an array that contains 1024 pages (1024 * 4KB = Roughly 4MB)
typedef struct page_table
{
  page_frame_t pages[1024];
} __attribute__ ((packed)) page_table_t;

typedef struct {
  uint32_t present  : 1;   // Page present in memory
  uint32_t rw   : 1;   // Read-only if clear, readwrite if set
  uint32_t user   : 1;   // Supervisor level only if clear
  uint32_t pwt    : 1;   // CPU Page write through
  uint32_t pcd    : 1;   // CPU Page cache disabled
  uint32_t accessed : 1;   // Has the page been accessed since last refresh?
  uint32_t dirty    : 1;   // Has the page been written to since last refresh?
  uint32_t ps   : 1;   // Is 4MB page
  uint32_t global   : 1;  // Global Page (Ignored)
  uint32_t avail  :3; // Available for kernel
  uint32_t frame  : 20;  // Frame address (shifted right 12 bits)
} __attribute__ ((packed)) page_dte_t;

// A page directory is an array that contains 1024 page tables (1024 * 4MB = Roughly 4GB)
// By duplicating the pagetables array we add an extra 4KB overhead per page directory
typedef struct page_directory
{
  // Same as above, but it gives their PHYSICAL addreses (CR3-compatible)
  // This are the ones we are going to write to using virtual memory
  page_dte_t physical[1024];

  // Array of pointers to the page tables
  page_table_t* tables[1024];

} __attribute__ ((packed)) page_directory_t;

#endif
