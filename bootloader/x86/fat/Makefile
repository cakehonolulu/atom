# Host variable
HOST =

# Check if we're compiling under Windows or UNIX
ifeq ($(OS), Windows_NT)
	HOST = Windows
else
	UNAME := $(shell uname -s)
	ifeq ($(UNAME), Linux)
		HOST = Linux
	endif
endif

ifeq ($(HOST), Linux)
	SFILES := $(notdir $(wildcard *.S))
	SOBJECTS := $(SFILES:.S=.o)
endif


ifdef USE_GCC
# Use GNU's GCC Compiler
CC = i686-elf-gcc
else
# Use LLVM's frontend CLANG
CC = clang
endif

OBJCOPY = objcopy

CFLAGS := -ffreestanding -fno-builtin -nostdlib -Iinitium -Istage2/libstage2/include

ifeq ($(ARCH), x86)
CFLAGS += --target=i686-pc-none-elf -march=i686
endif

REALMODE = -m16

BINARY := boot0.elf

.PHONY: all stage2

all: stage2 $(BINARY)

stage2:
	-@make -C stage2/ --no-print-directory

$(BINARY): $(SOBJECTS)
	@echo " \033[0;36mLD \033[0mboot0.elf"
	@$(CC) -T linkboot0.ld -o $@ -DI_FS_FAT16 $(SOBJECTS) $(CFLAGS) $(REALMODE)
	@echo " \033[0;37mOC\033[0m boot0.bin"
	@$(OBJCOPY) --only-keep-debug boot0.elf boot0.sym
	@$(OBJCOPY) --strip-debug boot0.elf
	@$(OBJCOPY) -O binary --only-section=.text boot0.elf boot0.bin

%.o: %.S
	@$(CC) $(CFLAGS) $(REALMODE) -c $< -o $@
	@echo " \033[0;35mAS\033[0m $<"

clean:
	@echo " 🧹 Cleaning FAT Bootloader Objects..."
	-@rm -rf *.elf ||:
	-@rm -rf *.sym ||:
	-@rm -rf *.bin ||:
	-@rm -rf *.o ||:
	-@make -C stage2/ clean --no-print-directory