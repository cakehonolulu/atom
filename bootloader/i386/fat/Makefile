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


ifdef USE_CLANG
# Use LLVM's frontend CLANG
CC = clang
else
# Use GNU's GCC Compiler
CC = i686-elf-gcc
endif

OBJCOPY = objcopy

CFLAGS := -ffreestanding -fno-builtin -nostdlib -Iinitium -g -fno-pic -fno-pie

ifeq ($(CC), clang)
CFLAGS += --target=i686-pc-none-elf -march=i686
endif

REALMODE = -m16

BINARY := boot0.elf

LDFLAGS := -z noexecstack -no-pie -nostdlib -static

ifeq ($(CC), clang)
LDFLAGS += -fuse-ld=lld
endif

all: headers $(BINARY)

headers:
	$(eval SIZE = $(shell sh -c "stat --printf="%s" ../stage2/stage2.bin"))
	-@echo " \033[0;34m** \033[0mStage 2 Size: $$((( $(SIZE) + 511) / 512)) (Sectors)"
	-@echo ".set STAGE2_SIZE, $$((( $(SIZE) + 511) / 512))" > boot1.h

$(BINARY): $(SOBJECTS)
	@echo " \033[0;36mLD \033[0mboot0.elf"
	@$(CC) -T linkboot0.ld -o $@ $(SOBJECTS) $(CFLAGS) $(LDFLAGS) $(REALMODE)
	@echo " \033[0;37mOC\033[0m boot0.bin"
	@$(OBJCOPY) --only-keep-debug boot0.elf boot0.sym
	@$(OBJCOPY) --strip-debug boot0.elf
	@$(OBJCOPY) -O binary boot0.elf boot0.bin

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
