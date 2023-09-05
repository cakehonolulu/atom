# Target Architecture (Currently supports i386)
ARCH ?= i386

# Default Filesystem, can be changed w/make parameters
FILESYSTEM ?= EXT2

# For building a FAT16 or EXT2 Disk Image
ifeq ($(FILESYSTEM),$(filter $(FILESYSTEM),FAT16 EXT2))
HDD_MBR_SECTOR = 0
endif

all: disk_image

.PHONY: bootloader stage2

disk_image: clean stage2 bootloader
	-@echo " \033[0;34mDD \033[0mimage"
	-@dd if=/dev/zero of=hdd.img bs=1 count=0 seek=10M status=none # 10485760 Bytes = 10 Mega Bytes
ifeq ($(FILESYSTEM), FAT16)
	-@mkfs.fat -F 16 hdd.img >/dev/null
	-@cp bootloader/$(ARCH)/build/boot1.bin STAGE1.BIN
	-@cp stage2/build/stage2.elf STAGE2.ELF
	-@cp stage2/build/test.bin KERNEL.BIN
	-@mcopy -i hdd.img KERNEL.BIN ::/
	-@mcopy -i hdd.img STAGE2.ELF ::/
	-@mcopy -i hdd.img STAGE1.BIN ::/
	-@dd conv=notrunc if=bootloader/$(ARCH)/build/boot0.bin of=hdd.img bs=512 seek=$(HDD_MBR_SECTOR) status=none
	-@rm STAGE1.BIN
	-@rm STAGE2.ELF
	-@rm KERNEL.BIN
endif
ifeq ($(FILESYSTEM), EXT2)
	-@mkfs.ext2 -I 128 -b 1024 -F hdd.img >/dev/null
	-@dd if=bootloader/$(ARCH)/build/boot0.bin of=hdd.img bs=512 count=1 conv=notrunc status=none
	-@e2cp -v bootloader/$(ARCH)/build/boot1.bin hdd.img:/stage1.bin
	-@e2cp -v stage2/build/stage2.elf hdd.img:/stage2.elf
endif
	-@echo " \033[0;32mOK \033[0mhdd.img"

bootloader:
	-@make -C bootloader/$(ARCH) FILESYSTEM=$(FILESYSTEM) --no-print-directory

stage2:
	-@make -C stage2/ all FILESYSTEM=$(FILESYSTEM) --no-print-directory

clean:
	-@make -C bootloader/$(ARCH) FILESYSTEM=$(FILESYSTEM) clean --no-print-directory
	-@make -C stage2/ clean FILESYSTEM=$(FILESYSTEM) --no-print-directory
	-@rm -f hdd.img

qemu:
	-@qemu-system-i386 -drive file=hdd.img,format=raw -serial stdio

debug_qemu:
	-@qemu-system-i386 -s -S -drive file=hdd.img,format=raw &
	-@gdb -x scripts/gdb_debug
	-@pkill -9 "qemu-system-*"

bochs:
	-@bochs -rc scripts/bochsrun.txt -f bochsrc.bxrc -q -unlock

debug_bochs:
	-@bochs -f bochsrc_dbg.bxrc -q -unlock
