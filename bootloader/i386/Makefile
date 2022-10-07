.DEFAULT_GOAL := boot

.PHONY: stage2

ifeq ($(FILESYSTEM), FAT16)
FS_DIR = fat
endif
ifeq ($(FILESYSTEM), EXT2)
FS_DIR = ext2
endif

boot: stage2 loader

stage2:
	-@make -C stage2/ all FILESYSTEM=$(FILESYSTEM) --no-print-directory

loader:
	-@make -C $(FS_DIR)/ all FILESYSTEM=$(FILESYSTEM) --no-print-directory

clean:
	-@make -C $(FS_DIR)/ clean FILESYSTEM=$(FILESYSTEM) --no-print-directory
	-@make -C stage2/ clean FILESYSTEM=$(FILESYSTEM) --no-print-directory

