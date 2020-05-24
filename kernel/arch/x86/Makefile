DEBUG ?= 0

# Tools
AR = i686-elf-ar
AS = i686-elf-as
CC = i686-elf-gcc
LD = i686-elf-ld
OBJCOPY = i686-elf-objcopy

# Tool flags
# We should switch to -nostdlib --freestanding -fno-builtin
CFLAGS =  -ffreestanding -Wall -Wextra -g
CFLAGS += -Iinclude -Wl,--no-as-needed

ASFLAGS = --32
LDSCRIPT = linker.ld

ifeq ($(DEBUG), 1)
    CFLAGS += -O0 -DHAVE_DEBUG
    ASFLAGS =
endif

ARCH_C_OBJECTS=$(shell find . -name '*.c')
ARCH_S_OBJECTS=$(shell find . -name '*.S')

ARCH_K_OBJECTS=$(patsubst %.S,%.o,$(ARCH_S_OBJECTS))
ARCH_K_OBJECTS+=$(patsubst %.c,%.o,$(ARCH_C_OBJECTS))

KERNEL_IMAGE = nucleus.elf

.PHONY: x86 clean

x86: $(KERNEL_IMAGE)
	$(OBJCOPY) --only-keep-debug nucleus.elf kernel.sym
	$(OBJCOPY) --strip-debug nucleus.elf
	$(OBJCOPY) -O binary nucleus.elf kernel.bin

# We should probably switch to nostdlib soon
$(KERNEL_IMAGE): $(ARCH_K_OBJECTS)
	$(LD) $(LDFLAGS) -T $(LDSCRIPT) -o $@ init/kernel_entry.o init/kernel.o asm.o klibc/string.o drivers/vga.o drivers/keyboard.o gdt.o idt.o isr.o common/port.o timer.o
	
%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

%.o: %.S
	$(AS) $(ASFLAGS) -c $< -o $@

clean:
	rm -f $(ARCH_K_OBJECTS)