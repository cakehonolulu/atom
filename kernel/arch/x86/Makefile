DEBUG ?= 0
FOUR_MB_PAGE_SIZE ?= 0
FOUR_KB_PAGE_SIZE ?= 0

# Tools
AR = i786-elf-ar
AS = i786-elf-as
CC = i786-elf-gcc
LD = i786-elf-ld
NASM = nasm
OBJCOPY = i786-elf-objcopy

# Tool flags
# We should switch to -nostdlib --freestanding -fno-builtin
CFLAGS =  -ffreestanding -Wall -Wextra -g
CFLAGS += -Iinclude

ASFLAGS = -m32
LDSCRIPT = linker.ld

ifeq ($(DEBUG), 1)
    CFLAGS += -DDEBUG
    ASFLAGS =
endif

ifeq ($(FOUR_MB_PAGE_SIZE), 1)
    CFLAGS += -DFOUR_MB_PAGE_SIZE
    ASFLAGS =
endif

ifeq ($(FOUR_KB_PAGE_SIZE), 1)
    CFLAGS += -DFOUR_KB_PAGE_SIZE
    ASFLAGS =
endif

ARCH_C_SOURCE_FILES=$(shell find . -name '*.c')
ARCH_S_SOURCE_FILES=$(shell find . -name '*.S')
ARCH_ASM_SOURCE_FILES=$(shell find . -name '*.asm')

ARCH_OBJECT_FILES=$(patsubst %.S,%.o,$(ARCH_S_SOURCE_FILES))
ARCH_OBJECT_FILES+=$(patsubst %.c,%.o,$(ARCH_C_SOURCE_FILES))
ARCH_OBJECT_FILES+=$(patsubst %.asm,%.o,$(ARCH_ASM_SOURCE_FILES))

KERNEL_IMAGE = nucleus.elf

.PHONY: x86 clean

x86: $(KERNEL_IMAGE)
	$(OBJCOPY) --only-keep-debug nucleus.elf kernel.sym
	$(OBJCOPY) --strip-debug nucleus.elf
	$(OBJCOPY) -O binary nucleus.elf kernel.bin

# We should probably switch to nostdlib soon
$(KERNEL_IMAGE): $(ARCH_OBJECT_FILES)
	@echo " \033[0;36mLD \033[0mnucleus.elf"
	$(LD) $(LDFLAGS) -T $(LDSCRIPT) -o $@ $(ARCH_OBJECT_FILES)
	
%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@
	@echo " \033[0;35mCC\033[0m $<"

%.o: %.asm
	$(NASM) -f elf $< -o $@
	@echo " \033[0;35mAS\033[0m $<"

%.o: %.S
	$(CC) $(ASFLAGS) -c $< -o $@
	@echo " \033[0;33mAS\033[0m $<"

clean:
	rm -f $(ARCH_OBJECT_FILES)
	rm -f *.elf
	rm -f *.bin
	rm -f *.sym
