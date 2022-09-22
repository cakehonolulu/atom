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

CFLAGS := -ffreestanding -fno-builtin -nostdlib -Iinitium -Istage2/libstage2/include -g

ifeq ($(ARCH), i386)
CFLAGS += --target=i686-pc-none-elf -march=i686
endif

REALMODE = -m16

BINARY := boot0.elf

LDFLAGS :=

ifdef USE_LLDB
LDFLAGS += -fuse-ld=lld
endif

.PHONY: stage2

all: stage2 headers $(BINARY)

stage2:
	-@make -C stage2/ --no-print-directory

headers:
	$(eval SIZE = $(shell sh -c "stat --printf="%s" stage2/stage2.bin"))
	-@echo $$((( $(SIZE) + 511) / 512))
	-@echo ".global boot1_size\nboot1_size:\n.int $(SIZE)" > boot1.h

$(BINARY): $(SOBJECTS)
	@echo " \033[0;36mLD \033[0mboot0.elf"
	@$(CC) -T linkboot0.ld -o $@ $(SOBJECTS) $(CFLAGS) $(LDFLAGS) $(REALMODE)  -fuse.
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
	-@rm -f boot1.h
	-@make -C stage2/ clean --no-print-directory