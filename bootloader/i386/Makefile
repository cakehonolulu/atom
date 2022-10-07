.DEFAULT_GOAL := boot

.PHONY: stage2

ifeq ($(FILESYSTEM), FAT16)
boot: stage2 loader

stage2:
	-@make -C stage2/ all FILESYSTEM=FAT16 --no-print-directory

loader:
	-@make -C fat/ all FILESYSTEM=FAT16 --no-print-directory

clean:
	-@make -C fat/ clean FILESYSTEM=FAT16 --no-print-directory
	-@make -C stage2/ clean FILESYSTEM=FAT16 --no-print-directory
else ifeq ($(FILESYSTEM), EXT2)
boot: stage2 loader

stage2:
	-@make -C stage2/ all FILESYSTEM=EXT2 --no-print-directory

loader:
	-@make -C ext2/ all FILESYSTEM=EXT2 --no-print-directory

clean:
	-@make -C ext2/ clean FILESYSTEM=EXT2 --no-print-directory
	-@make -C stage2/ clean FILESYSTEM=EXT2 --no-print-directory
endif

