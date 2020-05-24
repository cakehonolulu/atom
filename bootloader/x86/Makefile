AR = i686-elf-ar
AS = i686-elf-as
CC = i686-elf-gcc
LD = i686-elf-ld
OBJCOPY = i686-elf-objcopy

.PHONY: bootloader

bootloader:
	$(AS) boot1.S -o boot1.o --32 -Iinitium
	$(LD) -T linkboot1.ld -o boot1.elf boot1.o
	i686-elf-objcopy --only-keep-debug boot1.elf boot1.sym
	i686-elf-objcopy --strip-debug boot1.elf
	i686-elf-objcopy -O binary boot1.elf boot1.bin
	$(AS) boot0.S -o boot0.o --32 -Iinitium
	$(LD) -T linkboot0.ld -o boot0.elf boot0.o
	i686-elf-objcopy --only-keep-debug boot0.elf boot0.sym
	i686-elf-objcopy --strip-debug boot0.elf
	i686-elf-objcopy -O binary boot0.elf boot0.bin

clean:
	rm -f *.o
	rm -f *.sym
	rm -f *.bin
	rm -f *.elf