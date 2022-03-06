CC = clang
OBJCOPY = objcopy

CFLAGS := -ffreestanding -fno-builtin -nostdlib -Iinitium -Istage2/libstage2/include

ifeq ($(ARCH),x86)
CFLAGS += --target=i686-pc-none-elf -march=i686
endif

REALMODE = -m16

.PHONY: bootloader

ifeq ($(I_FS_FAT16), 1)
bootloader:
	$(CC) -T linker/linkboot1_fat16.ld boot1_fat16.S stage2/stage2.c stage2/libstage2/io.c -o boot1.elf -DI_FS_FAT16 $(CFLAGS) -m32
	$(OBJCOPY) --only-keep-debug boot1.elf boot1.sym
	$(OBJCOPY) --strip-debug boot1.elf
	$(OBJCOPY) -O binary boot1.elf boot1.bin
	$(CC) -T linker/linkboot0_fat16.ld boot0_fat16.S -o boot0.elf -DI_FS_FAT16 $(CFLAGS) $(REALMODE)
	$(OBJCOPY) --only-keep-debug boot0.elf boot0.sym
	$(OBJCOPY) --strip-debug boot0.elf
	$(OBJCOPY) -O binary boot0.elf boot0.bin
endif

ifeq ($(I_FS_NONE), 1)
bootloader:
	$(CC) -T linker/linkboot1.ld boot1.S -o boot1.elf -DI_FS_NONE $(CFLAGS) $(REALMODE)
	$(OBJCOPY) --only-keep-debug boot1.elf boot1.sym
	$(OBJCOPY) --strip-debug boot1.elf
	$(OBJCOPY) -O binary boot1.elf boot1.bin
	$(CC) -T linker/linkboot0.ld boot0.S -o boot0.elf -DI_FS_NONE $(CFLAGS) $(REALMODE)
	$(OBJCOPY) --only-keep-debug boot0.elf boot0.sym
	$(OBJCOPY) --strip-debug boot0.elf
	$(OBJCOPY) -O binary boot0.elf boot0.bin
endif

%.o: %.c
	@$(CC) $(CFLAGS) $(SDLCFLAGS) -c $< -o $@
	@echo " \033[0;35mCC\033[0m $<"

clean:
	rm -f *.o
	rm -f *.bin
	rm -f *.sym
	rm -f *.bin
	rm -f *.elf