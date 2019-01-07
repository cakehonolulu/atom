all:
	make clean
	make bootstrap

bootstrap:
	i686-elf-as boot0.S -o boot0.o --32 -mtune=i8086
	i686-elf-as boot1.S -o boot1.o --32 -mtune=i8086
	i686-elf-ld -o boot0.bin boot0.o -T linkboot0.ld -m elf_i386
	i686-elf-ld -o boot1.bin boot1.o -T linkboot1.ld -m elf_i386
	dd if=/dev/zero of=floppy.img bs=512 count=100 status=none
	dd if=boot0.bin of=floppy.img bs=512 count=1 conv=notrunc status=none
	dd if=boot1.bin of=floppy.img bs=512 seek=1 count=512 conv=notrunc status=none

clean:
	-@rm *.o
	-@rm *.bin
	-@rm *.img

$(V).SILENT: