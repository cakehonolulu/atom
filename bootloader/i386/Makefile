.DEFAULT_GOAL := boot

ifeq ($(FILESYSTEM), FAT16)
FS_DIR = fat
endif
ifeq ($(FILESYSTEM), EXT2)
FS_DIR = ext2
endif

boot: loader

loader:
	-@make -C $(FS_DIR)/ all FILESYSTEM=$(FILESYSTEM) --no-print-directory

clean:
	-@make -C $(FS_DIR)/ clean FILESYSTEM=$(FILESYSTEM) --no-print-directory
