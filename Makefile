all:
	make clean
	make bootstrap

bootstrap:
	i686-elf-as bootstrap.S -o bootstrap.o --32
	i686-elf-as boot.S -o boot.o --32
	i686-elf-ld -o bootstrap.bin bootstrap.o -T linkstrap.ld -m elf_i386
	i686-elf-ld -o boot.bin boot.o -T linkboot.ld -m elf_i386
	dd if=/dev/zero of=floppy.img bs=512 count=100
	dd if=bootstrap.bin of=floppy.img bs=512 count=1 conv=notrunc
	dd if=boot.bin of=floppy.img bs=512 seek=1 count=512 conv=notrunc

clean:
	-@rm *.o
	-@rm *.bin
	-@rm *.img

$(V).SILENT: