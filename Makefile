# Target Architecture (Currently supports i386)
ARCH ?= i386

# Default Filesystem, can be changed w/make parameters
FILESYSTEM ?= EXT2

# For building a FAT16 or EXT2 Disk Image
ifeq ($(FILESYSTEM),$(filter $(FILESYSTEM),FAT16 EXT2))
HDD_MBR_SECTOR = 0
endif

all: disk_image

.PHONY: bootloader

disk_image: clean bootloader
	-@echo " \033[0;34mDD \033[0mimage"
	-@dd if=/dev/zero of=hdd.img bs=1 count=0 seek=10M status=none # 10485760 Bytes = 10 Mega Bytes
ifeq ($(FILESYSTEM), FAT16)
	-@mkfs.fat -F 16 hdd.img >/dev/null
	-@cp bootloader/$(ARCH)/stage2/stage2.bin STAGE2
	-@cp bootloader/$(ARCH)/stage2/fat/test.bin TEST
	-@mcopy -i hdd.img TEST ::/
	-@mcopy -i hdd.img STAGE2 ::/
	-@dd conv=notrunc if=bootloader/$(ARCH)/fat/boot0.bin of=hdd.img bs=512 seek=$(HDD_MBR_SECTOR) status=none
	-@rm STAGE2
	-@rm TEST
endif
ifeq ($(FILESYSTEM), EXT2)
	-@mkfs.ext2 -I 128 -b 1024 -F hdd.img >/dev/null
	-@dd if=bootloader/$(ARCH)/ext2/boot0.bin of=hdd.img bs=512 count=1 conv=notrunc status=none
	-@e2cp -v bootloader/$(ARCH)/ext2/boot1.bin hdd.img:/loader.bin
	-@e2cp -v bootloader/$(ARCH)/stage2/stage2.elf hdd.img:/stage2.elf
endif
	-@echo " \033[0;32mOK \033[0mhdd.img"

bootloader:
	-@make -C bootloader/$(ARCH) FILESYSTEM=$(FILESYSTEM) --no-print-directory

clean:
	-@make -C bootloader/$(ARCH) FILESYSTEM=$(FILESYSTEM) clean --no-print-directory
	-@rm -f hdd.img

qemu:
	-@qemu-system-i386 -drive file=hdd.img,format=raw

debug_qemu:
	-@qemu-system-i386 -s -S -drive file=hdd.img,format=raw &
ifeq ($(FILESYSTEM), FAT16)
	-@gdb -x scripts/gdb_debug_fat16
endif
ifeq ($(FILESYSTEM), EXT2)
	-@gdb -x scripts/gdb_debug_ext2
endif
	-@pkill -9 "qemu-system-*"

bochs:
	-@bochs -rc scripts/bochsrun.txt -f bochsrc.bxrc -q -unlock

debug_bochs:
	-@bochs -f bochsrc_dbg.bxrc -q -unlock
