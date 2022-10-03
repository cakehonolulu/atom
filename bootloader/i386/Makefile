.DEFAULT_GOAL := boot

ifeq ($(FILESYSTEM), FAT16)
boot:
	-@make -C fat/ all FILESYSTEM=FAT16 --no-print-directory

clean:
	-@make -C fat/ clean FILESYSTEM=FAT16 --no-print-directory
else ifeq ($(FILESYSTEM), EXT2)
boot:
	-@make -C ext2/ all FILESYSTEM=EXT2 --no-print-directory

clean:
	-@make -C ext2/ clean FILESYSTEM=EXT2 --no-print-directory
endif

