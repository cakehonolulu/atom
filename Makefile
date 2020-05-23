all:
	make clean
	make bootstrap

# We should probably switch to nostdlib soon
bootstrap:
	i686-elf-as nucleus/kernel_entry.S -o nucleus/kernel_entry.o --32
	i686-elf-as nucleus/asm.S -o nucleus/asm.o --32
	i686-elf-gcc -ffreestanding -Wall -Wextra -g -c nucleus/gdt.c -o nucleus/gdt.o
	i686-elf-gcc -ffreestanding -Wall -Wextra -g -c nucleus/vga.c -o nucleus/vga.o
	i686-elf-gcc -ffreestanding -Wall -Wextra -g -c nucleus/port.c -o nucleus/port.o
	i686-elf-gcc -ffreestanding -Wall -Wextra -g -c nucleus/idt.c -o nucleus/idt.o
	i686-elf-gcc -ffreestanding -Wall -Wextra -g -c nucleus/isr.c -o nucleus/isr.o
	i686-elf-gcc -ffreestanding -Wall -Wextra -g -c nucleus/timer.c -o nucleus/timer.o
	i686-elf-gcc -ffreestanding -Wall -Wextra -g -c nucleus/keyboard.c -o nucleus/keyboard.o
	i686-elf-gcc -ffreestanding -Wall -Wextra -g -c nucleus/string.c -o nucleus/string.o
	i686-elf-gcc -ffreestanding -Wall -Wextra -g -c nucleus/kernel.c -o nucleus/kernel.o
	i686-elf-ld nucleus/kernel_entry.o nucleus/kernel.o nucleus/asm.o nucleus/string.o nucleus/vga.o nucleus/gdt.o nucleus/idt.o nucleus/isr.o nucleus/port.o nucleus/timer.o nucleus/keyboard.o -o nucleus/kernel.elf -T nucleus/linkkernel.ld
	i686-elf-objcopy --only-keep-debug nucleus/kernel.elf nucleus/kernel.sym
	i686-elf-objcopy --strip-debug nucleus/kernel.elf
	i686-elf-objcopy -O binary nucleus/kernel.elf nucleus/kernel.bin
	bash -c "./scripts/kernel.sh"
	i686-elf-as initium/boot1.S -o initium/boot1.o --32 -Iinitium
	i686-elf-ld -T initium/linkboot1.ld -o initium/boot1.elf initium/boot1.o
	i686-elf-objcopy --only-keep-debug initium/boot1.elf initium/boot1.sym
	i686-elf-objcopy --strip-debug initium/boot1.elf
	i686-elf-objcopy -O binary initium/boot1.elf initium/boot1.bin
	bash -c "./scripts/boot.sh"
	i686-elf-as initium/boot0.S -o initium/boot0.o --32 -Iinitium
	i686-elf-ld -T initium/linkboot0.ld -o initium/boot0.elf initium/boot0.o
	i686-elf-objcopy --only-keep-debug initium/boot0.elf initium/boot0.sym
	i686-elf-objcopy --strip-debug initium/boot0.elf
	i686-elf-objcopy -O binary initium/boot0.elf initium/boot0.bin
	-@mkfs.msdos -C floppy.img 1440 >/dev/null
	-@dd conv=notrunc if=initium/boot0.bin of=floppy.img bs=512 seek=0 status=none
	-@dd conv=notrunc if=initium/boot1.bin of=floppy.img bs=512 seek=1 status=none
	-@dd conv=notrunc if=nucleus/kernel.bin of=floppy.img bs=512 seek=3 status=none

clean:
	-@rm initium/*.h
	-@rm initium/*.o
	-@rm initium/*.elf
	-@rm initium/*.sym
	-@rm initium/*.bin
	-@rm initium/*.img
	-@rm nucleus/*.o
	-@rm nucleus/*.elf
	-@rm nucleus/*.sym
	-@rm nucleus/*.bin
	-@rm nucleus/*.img
	-@rm *.img

bochs:
	bochs -q -f bochsrc.bxrc 'floppya: type=1_44, 1_44=floppy.img, status=inserted, write_protected=0'

qemu:
	qemu-system-i386 -fda floppy.img

qemu-debug:
	qemu-system-i386 -fda floppy.img -s -S &
	gdb --eval-command="target remote localhost:1234"

$(V).SILENT:
