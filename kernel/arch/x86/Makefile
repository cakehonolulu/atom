DEBUG ?= 0
FOUR_MB_PAGE_SIZE ?= 0
FOUR_KB_PAGE_SIZE ?= 0

# Tools
# If we need Floating Point instructions, build Atom with i486+
ifdef TRUEX86
AR = i686-elf-ar
AS = i686-elf-as
CC = i686-elf-gcc
LD = i686-elf-ld
OBJCOPY = i686-elf-objcopy
endif

AR = i386-elf-ar
AS = i386-elf-as
CC = clang
LD = i386-elf-ld
OBJCOPY = objcopy

NASM = nasm

# Tool flags
# We should switch to -nostdlib --freestanding -fno-builtin
CFLAGS :=  -ffreestanding -fno-builtin -nostdlib -Iinitium
CFLAGS += -Iinclude --target=i686-pc-none-elf -march=i686

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
	clang $(CFLAGS) -T $(LDSCRIPT) -o $@ $(ARCH_OBJECT_FILES)
	
%.o: %.c
	clang $(CFLAGS) -c $< -o $@
	@echo " \033[0;35mCC\033[0m $<"

%.o: %.asm
	$(NASM) -f elf $< -o $@
	@echo " \033[0;35mAS\033[0m $<"

%.o: %.S
	clang $(ASFLAGS) -c $< -o $@
	@echo " \033[0;33mAS\033[0m $<"

clean:
	rm -f $(ARCH_OBJECT_FILES)
	rm -f *.elf
	rm -f *.bin
	rm -f *.sym
