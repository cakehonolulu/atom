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

ifdef USE_CLANG
# Use LLVM's frontend CLANG
CC = clang
else
# Use GNU's GCC Compiler
CC = i686-elf-gcc
endif

OBJCOPY = objcopy

CFLAGS := -Wall -Wextra -pedantic -std=c2x -ffreestanding -fno-builtin -nostdlib -m32 -I$(dir $(lastword $(MAKEFILE_LIST)))include -g -fno-pic -fno-pie -D$(FILESYSTEM)

ifeq ($(ARCH), clang)
CFLAGS += --target=i686-pc-none-elf -march=i686
endif

BINARY := stage2.elf

BUILDDIR := $(dir $(lastword $(MAKEFILE_LIST)))build

LDFLAGS := -z noexecstack -no-pie -nostdlib -static

ifeq ($(CC), clang)
LDFLAGS += -fuse-ld=lld
endif
