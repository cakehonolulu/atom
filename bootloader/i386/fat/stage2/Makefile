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
	CFILES := $(notdir $(wildcard *.c))
	SFILES := $(notdir $(wildcard *.S))
	COBJECTS := $(CFILES:.c=.o)
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

CFLAGS := -Wall -Wextra -pedantic -std=c2x -ffreestanding -fno-builtin -nostdlib -m32 -Iinclude -g

LDFLAGS = -z noexecstack

ifeq ($(ARCH), i386)
CFLAGS += --target=i686-pc-none-elf -march=i686
endif

BINARY := stage2.elf

all: $(BINARY)

$(BINARY): $(COBJECTS) $(SOBJECTS)
	@echo " \033[0;36mLD \033[0mstage2.elf"
	@$(CC) -T linkstage2.ld -o $@ $(COBJECTS) $(SOBJECTS) $(CFLAGS) $(LDFLAGS)
	@echo " \033[0;37mOC\033[0m stage2.bin"
	@$(OBJCOPY) --only-keep-debug stage2.elf stage2.sym
	@$(OBJCOPY) --strip-debug stage2.elf
	@$(OBJCOPY) -O binary stage2.elf stage2.bin

%.o: %.c
	@$(CC) $(CFLAGS) -c $< -o $@
	@echo " \033[0;35mCC\033[0m $<"

%.o: %.S
	@$(CC) $(CFLAGS) -c $< -o $@
	@echo " \033[0;35mAS\033[0m $<"

clean:
	@echo " 🧹 Cleaning Stage 2 Bootloader Objects..."
	-@rm -rf $(BINARY) ||:
	-@rm -rf $(COBJECTS) ||:
	-@rm -rf $(SOBJECTS) ||:
	-@rm -rf *.sym
	-@rm -rf *.bin