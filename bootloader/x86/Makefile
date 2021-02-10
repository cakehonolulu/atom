AR = i786-elf-ar
AS = i786-elf-as
CC = i786-elf-gcc
LD = i786-elf-ld
NASM = nasm
OBJCOPY = i786-elf-objcopy

.PHONY: bootloader

bootloader:
	$(NASM) -f elf boot1helper.asm -o boot1helper.o 
	$(AS) boot1.S -o boot1.o --32 -Iinitium
	$(LD) -T linkboot1.ld -o boot1.elf boot1.o boot1helper.o
	$(OBJCOPY) --only-keep-debug boot1.elf boot1.sym
	$(OBJCOPY) --strip-debug boot1.elf
	$(OBJCOPY) -O binary boot1.elf boot1.bin
	$(AS) boot0.S -o boot0.o --32 -Iinitium
	$(NASM) -f elf boot0helper.asm -o boot0helper.o 
	$(LD) -T linkboot0.ld -o boot0.elf boot0.o boot0helper.o
	$(OBJCOPY) --only-keep-debug boot0.elf boot0.sym
	$(OBJCOPY) --strip-debug boot0.elf
	$(OBJCOPY) -O binary boot0.elf boot0.bin

clean:
	rm -f *.o
	rm -f *.bin
	rm -f *.sym
	rm -f *.bin
	rm -f *.elf