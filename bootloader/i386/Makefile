.DEFAULT_GOAL := boot

ifeq ($(FILESYSTEM), FAT16)
boot:
	-@make -C fat/ all FILESYSTEM=FAT16 --no-print-directory

clean:
	-@make -C fat/ clean FILESYSTEM=FAT16 --no-print-directory
endif
