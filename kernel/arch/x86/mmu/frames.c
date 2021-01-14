#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>
#include <paging.h>
#include <kernel.h>

extern uint32_t *__KERNEL_END;
// A bitset of frames - used or free.
static uint32_t max_frames = NULL; //Max number of frames for installed memory
static uint32_t *frames_Array; //Pointer to array with the frames status (0 FREE, 1 USED)

uint32_t first_free_frame_index();
bool test_frame(uint32_t frame_addr);

// Function to allocate a frame.
void alloc_frame_int(page_frame_t *page, bool is_kernel, bool is_writeable, bool is_accessed, bool is_dirty, bool map_frame, uint32_t frameAddr){
  uint32_t idx;
  if(map_frame){
    idx = frameAddr >> 12;
  }else if(page->frame == 0){
    idx = first_free_frame_index(); // idx is now the index of the first free frame.
  } else {
    idx = page->frame;
  }
  
  set_frame(idx << 12); // this frame is now ours!
  page->ps = 0; //We are using 4KB pages
  page->present = 1; // Mark it as present.
  is_writeable = true;
  page->rw = (is_writeable == true) ? 1 : 0; // Should the page be writeable?
  is_kernel = false;
  page->user = (is_kernel == true) ? 0 : 1; // Should the page be user-mode?
  page->accessed = (is_accessed == true)?1:0;
  page->dirty = (is_dirty == true)?1:0;
  page->frame = idx;
}

void alloc_frame(page_frame_t *page, bool is_kernel, bool is_writeable){
  alloc_frame_int(page, is_kernel, is_writeable, false, false, false, NULL);
}

// Function to deallocate a frame.
void free_frame(page_frame_t *page){
  if(page == NULL){
    return;
  }
  if (!test_frame((page->frame) << 12)){
    return; // The given page didn't actually have an allocated frame!
  }else{
    clear_frame((page->frame) << 12); // Frame is now free again.
    *((uint32_t *)page) = 0;
  }
}

// Static function to set a bit in the frames bitset
void set_frame(uint32_t frame_addr){
  uint32_t frame = frame_addr/PAGE_SIZE;
  uint32_t idx = INDEX_FROM_BIT(frame);
  uint32_t off = OFFSET_FROM_BIT(frame);
  frames_Array[idx] |= (0x1 << off);
}


// Static function to clear a bit in the frames bitset
void clear_frame(uint32_t frame_addr){
  uint32_t frame = frame_addr/PAGE_SIZE;
  uint32_t idx = INDEX_FROM_BIT(frame);
  uint32_t off = OFFSET_FROM_BIT(frame);
  frames_Array[idx] &= ~(0x1 << off);
}

// Static function to test if a bit is set.
bool test_frame(uint32_t frame_addr){
  uint32_t frame = frame_addr/PAGE_SIZE;
  uint32_t idx = INDEX_FROM_BIT(frame);
  uint32_t off = OFFSET_FROM_BIT(frame);
  return (frames_Array[idx] & (0x1 << off)) != 0;
}

// Static function to find the first free frame.
uint32_t first_free_frame_index(){
  uint32_t i, j;
  for (i = 0; i < INDEX_FROM_BIT(max_frames); i++){
    if (frames_Array[i] != 0xFFFFFFFF){ // nothing free, exit early.
      // at least one bit is free here.
      for (j = 0; j < 32; j++){
        uint32_t toTest = 0x1 << j;
        if ( !(frames_Array[i]&toTest) ){
          return j+(i*8*4);
        }
      }
    }
  }
  //PANIC("No free frames!");
  printk("\nNo free frames!");
  asm("cli;hlt");
}

uint32_t first_frame() {
    uint32_t idx = first_free_frame_index(); // idx is now the index of the first free frame.
    set_frame(idx << 12);
    return (idx << 12);
}


void init_mmu(uintptr_t kernel_base_ptr, uintptr_t kernel_top_ptr)
{
  // HACK: Memory region provided by mmap_init is
  // ensured to be AT LEAST, 1MB in size, which is probably more
  // than enough for now, but this is hacky and should probably be avoided.

  // TODO: Return more information (Maybe a struct?) such as
  // top address and/or size just to name a few bits of stuff.

  // TODO: Whenever I manage to implement a menuconfig-like
  // config scheme, let the user decide if it should be compiled
  // using the Higher-Half memory scheme.

  // BUG?: If we have 1MB into address space as start address free, we might
  // have a bug where we overwrite kernel parts!
  // Kernel Pos after PADDR -> VADDR 0xC0100000;
  
  printk("kernel_base_ptr: 0x%x, kernel_top_ptr: 0x%x\n", kernel_base_ptr, kernel_top_ptr);
  
  init_mmap(kernel_base_ptr, kernel_top_ptr);

  uint32_t mem_tam = (memory_management_region_end - memory_management_region_start);
  printk("end: 0x%x; start: 0x%x; mem_tam = %d\n", memory_management_region_end, memory_management_region_start, mem_tam);
  max_frames = mem_tam / PAGE_SIZE;
  
  //Direccion para el bitmap despues del kernel
  uint32_t next_v_addr = (uint32_t)(((uint32_t) &__KERNEL_END) + 4);
  printk("next_v_addr 0x%x\n", next_v_addr);
  frames_Array = next_v_addr;
  //Obtenemos el tamaño del array
  uint32_t array_tam = INDEX_FROM_BIT(max_frames);
  if(array_tam % 32 != 0){
    array_tam += 1;
  }
  //Limpiamos el contenido de la memoria
  memset(frames_Array, 0, (sizeof(uint32_t) * array_tam));
  // Iniciamos el kd
  kmalloc_init(next_v_addr, KERNEL_VIRTUAL_BASE);

  // Le pedimos una direccion, esta garantizado que reserva el espacio del array
  uint32_t array_reserved = (uint32_t *) kmalloc (sizeof(uint32_t) * array_tam);
  printk("Frames Array: 0x%x : 0x%x\n", frames_Array, array_reserved);

  printk("Max num frames: %d; TAM: %d bytes\n", max_frames, mem_tam);
  if(max_frames <= 4){
    //PANIC("INSTALLED MEMORY BELOW 16MB");
    printk("INSTALLED MEMORY BELOW 16MB");
    asm("cli;hlt");
  }
}