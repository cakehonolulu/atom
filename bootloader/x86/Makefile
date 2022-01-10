# If we need Floating Point instructions, build Initium with i486+
ifdef TRUEX86
AR = i686-elf-ar
AS = i686-elf-as
CC = i686-elf-gcc
CPP = i686-elf-cpp
LD = i686-elf-ld
OBJCOPY = i686-elf-objcopy
endif

AR = i386-elf-ar
AS = i386-elf-as
CC = i386-elf-gcc
CPP = i386-elf-cpp
LD = i386-elf-ld
OBJCOPY = i386-elf-objcopy

NASM = nasm

.PHONY: bootloader

ifeq ($(I_FS_FAT16), 1)
bootloader:
	$(NASM) -f elf boot1helper.asm -o boot1helper.o 
	$(CPP) boot1.S -o boot1p.S -DI_FS_FAT16 -m32 -Iinitium
	$(AS) boot1p.S -o boot1.o -DI_FS_FAT16 --32 -Iinitium
	$(LD) -T linker/linkboot1_fat16.ld -o boot1.elf boot1.o boot1helper.o
	$(OBJCOPY) --only-keep-debug boot1.elf boot1.sym
	$(OBJCOPY) --strip-debug boot1.elf
	$(OBJCOPY) -O binary boot1.elf boot1.bin
	$(CPP) boot0_fat16.S -o boot0p.S -DI_FS_FAT16 -m32 -Iinitium
	$(AS) boot0p.S -o boot0.o -DI_FS_FAT16 --32 -Iinitium
	$(NASM) -f elf boot0helper.asm -o boot0helper.o
	$(LD) -T linker/linkboot0_fat16.ld -o boot0.elf boot0.o boot0helper.o
	$(OBJCOPY) --only-keep-debug boot0.elf boot0.sym
	$(OBJCOPY) --strip-debug boot0.elf
	$(OBJCOPY) -O binary boot0.elf boot0.bin
endif

ifeq ($(I_FS_NONE), 1)
bootloader:
	$(NASM) -f elf boot1helper.asm -o boot1helper.o 
	$(CPP) boot1.S -o boot1p.S -DI_FS_NONE -m32 -Iinitium
	$(AS) boot1p.S -o boot1.o -DI_FS_NONE --32 -Iinitium
	$(LD) -T linker/linkboot1.ld -o boot1.elf boot1.o boot1helper.o
	$(OBJCOPY) --only-keep-debug boot1.elf boot1.sym
	$(OBJCOPY) --strip-debug boot1.elf
	$(OBJCOPY) -O binary boot1.elf boot1.bin
	$(CPP) boot0.S -o boot0p.S -DI_FS_NONE -m32 -Iinitium
	$(AS) boot0p.S -o boot0.o -DI_FS_NONE --32 -Iinitium
	$(NASM) -f elf boot0helper.asm -o boot0helper.o
	$(LD) -T linker/linkboot0.ld -o boot0.elf boot0.o boot0helper.o
	$(OBJCOPY) --only-keep-debug boot0.elf boot0.sym
	$(OBJCOPY) --strip-debug boot0.elf
	$(OBJCOPY) -O binary boot0.elf boot0.bin
endif

clean:
	rm -f *.o
	rm -f *.bin
	rm -f *.sym
	rm -f *.bin
	rm -f *.elf
	-rm boot0p.S
	-rm boot1p.S