# Target Architecture (Currently supports i386)
ARCH ?= i386

FILESYSTEM ?= EXT2

# For building a FAT16 Disk Image
ifeq ($(FILESYSTEM), FAT16)
# Constants
HDD_MBR_SECTOR = 0
endif

all: disk_image

.PHONY: bootloader

ifeq ($(FILESYSTEM), FAT16)
disk_image: clean bootloader
	-@echo " \033[0;34mDD \033[0mimage"
	-@dd if=/dev/zero of=hdd.img bs=1 count=0 seek=10M status=none # 10485760 Bytes = 10 Mega Bytes
	-@mkfs.fat -F 16 hdd.img >/dev/null
	-@cp bootloader/$(ARCH)/fat/stage2/stage2.bin STAGE2
	-@cp bootloader/$(ARCH)/fat/stage2/test.bin TEST
	-@mcopy -i hdd.img TEST ::/
	-@mcopy -i hdd.img STAGE2 ::/
	-@dd conv=notrunc if=bootloader/$(ARCH)/fat/boot0.bin of=hdd.img bs=512 seek=$(HDD_MBR_SECTOR) status=none
	-@rm STAGE2
	-@rm TEST
	-@echo " \033[0;32mOK \033[0mhdd.img"

bootloader:
	-@make -C bootloader/$(ARCH) FILESYSTEM=FAT16 --no-print-directory

clean:
	-@make -C bootloader/$(ARCH) FILESYSTEM=FAT16 clean --no-print-directory
	-@rm hdd.img
endif

ifeq ($(FILESYSTEM), EXT2)
disk_image: clean bootloader
	-@echo " \033[0;34mDD \033[0mimage"
	-@dd if=/dev/zero of=hdd.img bs=1 count=0 seek=10M status=none # 10485760 Bytes = 10 Mega Bytes
	-@mkfs -t ext2 hdd.img >/dev/null
	-@fuseext2 hdd.img tmp/ -o rw+
	-@umount tmp/
	-@echo " \033[0;32mOK \033[0mhdd.img"

bootloader:
	-@make -C bootloader/$(ARCH) FILESYSTEM=EXT2 --no-print-directory

clean:
	-@make -C bootloader/$(ARCH) FILESYSTEM=EXT2 clean --no-print-directory
	-@rm hdd.img
endif

debug:
	-@qemu-system-i386 -s -S -drive file=hdd.img,format=raw &
	-@gdb -x scripts/gdb_debug
	-@pkill -9 qemu-system-i38
