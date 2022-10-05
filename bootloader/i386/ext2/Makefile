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

CFLAGS := -ffreestanding -fno-builtin -nostdlib -Iinitium -Istage2/libstage2/include -g -fno-pic -fno-pie

ifeq ($(CC), clang)
CFLAGS += --target=i686-pc-none-elf -march=i686
endif

REALMODE = -m16

BINARY := boot0.elf

LDFLAGS := -z noexecstack -no-pie -nostdlib -static

ifeq ($(CC), clang)
LDFLAGS += -fuse-ld=lld
endif

.PHONY: stage2

all: stage2 $(BINARY)

stage2:
	-@make -C stage2/ --no-print-directory

$(BINARY): $(SOBJECTS)
	@echo " \033[0;36mLD \033[0mboot0.elf"
	@$(CC) -T linkboot0.ld -o boot0.elf boot0.o $(CFLAGS) $(LDFLAGS) $(REALMODE)
	@echo " \033[0;37mOC\033[0m boot0.bin"
	@$(OBJCOPY) --only-keep-debug boot0.elf boot0.sym
	@$(OBJCOPY) --strip-debug boot0.elf
	@$(OBJCOPY) -O binary --only-section=.text boot0.elf boot0.bin

	@echo " \033[0;36mLD \033[0mboot1.elf"
	@$(CC) -T linkboot1.ld -o boot1.elf boot1.o $(CFLAGS) $(LDFLAGS) $(REALMODE)
	@echo " \033[0;37mOC\033[0m boot1.bin"
	@$(OBJCOPY) --only-keep-debug boot1.elf boot1.sym
	@$(OBJCOPY) --strip-debug boot1.elf
	@$(OBJCOPY) -O binary --only-section=.text boot1.elf boot1.bin

%.o: %.S
	@$(CC) $(CFLAGS) -c $< -o $@
	@echo " \033[0;35mAS\033[0m $<"

clean:
	@echo " 🧹 Cleaning EXT2 Bootloader Objects..."
	-@rm -rf *.elf ||:
	-@rm -rf *.sym ||:
	-@rm -rf *.bin ||:
	-@rm -rf *.o ||:
	-@rm -f boot1.h
	-@make -C stage2/ clean --no-print-directory