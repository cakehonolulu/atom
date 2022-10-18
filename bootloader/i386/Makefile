include make.mk

ifeq ($(FILESYSTEM), FAT16)
FS_DIR = fat
endif
ifeq ($(FILESYSTEM), EXT2)
FS_DIR = ext2
endif

all: filesystem $(SOBJECTS)
	@echo " \033[0;37mLD\033[0m boot0.elf"
	@$(CC) -T linkboot0.ld -o $(BUILDDIR)/boot0.elf $(BUILDDIR)/boot0.o $(CFLAGS) $(LDFLAGS)

	@echo " \033[0;36mOC \033[0mboot0.bin"
	@$(OBJCOPY) --only-keep-debug $(BUILDDIR)/boot0.elf $(BUILDDIR)/boot0.sym
	@$(OBJCOPY) --strip-debug $(BUILDDIR)/boot0.elf
	@$(OBJCOPY) -O binary $(BUILDDIR)/boot0.elf $(BUILDDIR)/boot0.bin

	@echo " \033[0;37mLD\033[0m boot1.elf"
	@$(CC) -T linkboot1.ld -o $(BUILDDIR)/boot1.elf $(BUILDDIR)/boot1.o $(BUILDDIR)/mmap.o $(CFLAGS) $(LDFLAGS)

	@echo " \033[0;36mOC \033[0mboot1.bin"
	@$(OBJCOPY) --only-keep-debug $(BUILDDIR)/boot1.elf $(BUILDDIR)/boot1.sym
	@$(OBJCOPY) --strip-debug $(BUILDDIR)/boot1.elf
	@$(OBJCOPY) -O binary $(BUILDDIR)/boot1.elf $(BUILDDIR)/boot1.bin

filesystem:
	-@mkdir -p build/
ifeq ($(FILESYSTEM), FAT16)
	-@make -C $(FS_DIR)/
endif
ifeq ($(FILESYSTEM), EXT2)
	-@make -C $(FS_DIR)/
endif

clean:
	-@rm -rf $(BUILDDIR) ||:

%.o: %.S
	@$(CC) $(CFLAGS) -c $< -o $(BUILDDIR)/$@
	@echo " \033[0;35mAS\033[0m $<"
