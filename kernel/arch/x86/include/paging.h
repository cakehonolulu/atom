#include <isr.h>
#include <stdint.h>
#include <stddef.h>

// Macros used in the bitset algorithms.
#define INDEX_FROM_BIT(a) (a/(8*4))
#define OFFSET_FROM_BIT(a) (a%(8*4))

#define PAGE_SIZE_4MB 0x400000
#define PAGE_SIZE_4KB 0x1000
#define PAGE_SIZE PAGE_SIZE_4MB

#define ALIGN_DOWN(addr) ((addr) - ((addr) % PAGE_SIZE))
#define ALIGN_UP(addr) (ALIGN_DOWN(addr) + PAGE_SIZE)

#define PAGE_TABLE_ENTRIES_PER_DIRECTORY 1024
#define AMOUNT_OF_PAGES_PER_TABLE 1024

#define KERNEL_ADDR_OFFSET 0xC0000000

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


void initialise_paging(size_t memsize, uint32_t virtual_start, uint32_t virtual_end, uint32_t phys_start, uint32_t phys_end);
void switch_page_directory(page_directory_t *new);
page_t *get_page(uint32_t address, int make, page_directory_t *dir);