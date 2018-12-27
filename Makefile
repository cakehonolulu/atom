all:
	make clean
	make bootstrap

bootstrap:
	i686-elf-as bootstrap.S -o bootstrap.o --32
	ld -o boot.bin bootstrap.o -T link.ld -m elf_i386

clean:
	-@rm *.o
	-@rm *.bin

$(V).SILENT: