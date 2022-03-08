.PHONY: bootloader

ifeq ($(I_FS_FAT16), 1)
bootloader:
	-@make -C fat/ --no-print-directory

clean:
	-@make -C fat/ clean --no-print-directory
endif

CFLAGS := -Wall -Wextra -pedantic -std=c2x -ffreestanding -fno-builtin -nostdlib
CFLAGS += --target=i686-pc-none-elf -march=i686

ifeq ($(I_FS_NONE), 1)
bootloader:
	clang -T raw/linkboot1.ld raw/boot1.S -o boot1.elf -DI_FS_NONE $(CFLAGS) -m16
	objcopy --only-keep-debug boot1.elf boot1.sym
	objcopy --strip-debug boot1.elf
	objcopy -O binary boot1.elf boot1.bin
	clang -T raw/linkboot0.ld raw/boot0.S -o boot0.elf -DI_FS_NONE $(CFLAGS) -m16
	objcopy --only-keep-debug boot0.elf boot0.sym
	objcopy --strip-debug boot0.elf
	objcopy -O binary boot0.elf boot0.bin
endif
