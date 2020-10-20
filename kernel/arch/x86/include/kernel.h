#include <stddef.h>
#include <stdint.h>
#include <gdt.h>

/* Defines */
#define KERNEL_START (uint32_t)(&kernel_start)
#define KERNEL_END (uint32_t)(&kernel_end)
#define KERNEL_SIZE KERNEL_END - KERNEL_START

/* Externs */
extern void *kernel_end;
extern void *kernel_start;

extern uintptr_t memory_management_region_start, memory_management_region_end;