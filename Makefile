all:
	make clean
	make bootstrap

bootstrap:
	i686-elf-as boot0.S -o boot0.o --32
	i686-elf-as boot1.S -o boot1.o --32
	i686-elf-as kernel_entry.S -o kernel_entry.o --32
	i686-elf-as kernel.S -o kernel.o --32
	i686-elf-ld -o boot0.bin boot0.o -T linkboot0.ld -m elf_i386
	i686-elf-ld -o boot1.bin boot1.o -T linkboot1.ld -m elf_i386
	i686-elf-ld -o kernel.bin kernel_entry.o kernel.o -T linkkernel.ld -m elf_i386
	mkfs.msdos -C floppy.img 1440
	dd conv=notrunc if=boot0.bin of=floppy.img bs=512 seek=0
	dd conv=notrunc if=boot1.bin of=floppy.img bs=512 seek=1
	dd conv=notrunc if=kernel.bin of=floppy.img bs=512 seek=3

clean:
	-@rm *.o
	-@rm *.bin
	-@rm *.img

$(V).SILENT: