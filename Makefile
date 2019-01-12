all:
	make clean
	make bootstrap

bootstrap:
	i686-elf-as boot0.S -o boot0.o --32 -mtune=i8086
	i686-elf-as boot1.S -o boot1.o --32 -mtune=i8086
	i686-elf-ld -o boot0.bin boot0.o -T linkboot0.ld -m elf_i386
	i686-elf-ld -o boot1.bin boot1.o -T linkboot1.ld -m elf_i386
	cat boot0.bin boot1.bin > floppy.img

clean:
	-@rm *.o
	-@rm *.bin
	-@rm *.img

$(V).SILENT: