CHECKFILE = \
    if [ ! -f "kernel/kernel.bin" ]; then \
        echo "file does not exist" ; exit 1 ; \
    fi; \
    FSIZE=$$(du -b "kernel/kernel.bin" | cut -f 1 | xargs > bootloader/boot0.h) ; \
    

all:
	make clean
	make bootstrap

bootstrap:
	i686-elf-as bootloader/boot1.S -o bootloader/boot1.o --32
	i686-elf-as kernel/kernel_entry.S -o kernel/kernel_entry.o --32
	i686-elf-as kernel/asm.S -o kernel/asm.o --32
	i686-elf-gcc -ffreestanding -Wall -Wextra -g -c kernel/gdt.c -o kernel/gdt.o
	i686-elf-gcc -ffreestanding -Wall -Wextra -g -c kernel/vga.c -o kernel/vga.o
	i686-elf-gcc -ffreestanding -Wall -Wextra -g -c kernel/port.c -o kernel/port.o
	i686-elf-gcc -ffreestanding -Wall -Wextra -g -c kernel/kernel.c -o kernel/kernel.o
	i686-elf-ld -T bootloader/linkboot1.ld -o bootloader/boot1.bin bootloader/boot1.o
	i686-elf-ld kernel/kernel_entry.o kernel/kernel.o kernel/asm.o kernel/vga.o kernel/gdt.o kernel/port.o -o kernel/kernel.bin -T kernel/linkkernel.ld
	@$(CHECKFILE)
	bash -c "sed -i '1s/^/.define I386_KERNEL_SIZE /' bootloader/boot0.h"
	i686-elf-as bootloader/boot0.S -o bootloader/boot0.o --32
	i686-elf-ld -T bootloader/linkboot0.ld -o bootloader/boot0.bin bootloader/boot0.o
	-@mkfs.msdos -C floppy.img 1440 >/dev/null
	-@dd conv=notrunc if=bootloader/boot0.bin of=floppy.img bs=512 seek=0 status=none
	-@dd conv=notrunc if=bootloader/boot1.bin of=floppy.img bs=512 seek=1 status=none
	-@dd conv=notrunc if=kernel/kernel.bin of=floppy.img bs=512 seek=3 status=none

clean:
	-@rm bootloader/*.o
	-@rm kernel/*.o
	-@rm bootloader/*.bin
	-@rm kernel/*.bin
	-@rm bootloader/*.img
	-@rm kernel/*.img
	-@rm *.img

bochs:
	$(BOCHS) -q -f bochsrc.bxrc 'floppya: type=1_44, 1_44=floppy.img, status=inserted, write_protected=0'

$(V).SILENT:
