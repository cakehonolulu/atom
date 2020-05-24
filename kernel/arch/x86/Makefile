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
CFLAGS += -Iinclude

ASFLAGS = --32
LDSCRIPT = linker.ld

ifeq ($(DEBUG), 1)
    CFLAGS += -O0 -DHAVE_DEBUG
    ASFLAGS =
endif

ARCH_C_SOURCE_FILES=$(shell find . -name '*.c')
ARCH_S_SOURCE_FILES=$(shell find . -name '*.S')

ARCH_OBJECT_FILES=$(patsubst %.S,%.o,$(ARCH_S_SOURCE_FILES))
ARCH_OBJECT_FILES+=$(patsubst %.c,%.o,$(ARCH_C_SOURCE_FILES))

ARCH_OFILES_NOENTRY := $(filter-out ./init/kernel_entry.o,$(ARCH_OBJECT_FILES))
ARCH_FINAL_OFILES := $(filter-out ./init/kernel.o,$(ARCH_OFILES_NOENTRY))

KERNEL_IMAGE = nucleus.elf

.PHONY: x86 clean

x86: $(KERNEL_IMAGE)
	$(OBJCOPY) --only-keep-debug nucleus.elf kernel.sym
	$(OBJCOPY) --strip-debug nucleus.elf
	$(OBJCOPY) -O binary nucleus.elf kernel.bin

# We should probably switch to nostdlib soon
$(KERNEL_IMAGE): $(ARCH_OBJECT_FILES)
	@echo " \033[0;36mLD \033[0mnucleus.elf"
	$(LD) $(LDFLAGS) -T $(LDSCRIPT) -o $@ init/kernel_entry.o init/kernel.o $(ARCH_FINAL_OFILES)
	
%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@
	@echo " \033[0;35mCC\033[0m $<"

%.o: %.S
	$(AS) $(ASFLAGS) -c $< -o $@
	@echo " \033[0;33mAS\033[0m $<"

clean:
	rm -f $(ARCH_OBJECT_FILES)
	rm -f *.elf
	rm -f *.bin
	rm -f *.sym
