include make.mk

all: $(BINARY)

filesystem:
	-@mkdir -p build/
ifeq ($(FILESYSTEM), FAT16)
	@$(MAKE) -C fat/
endif
ifeq ($(FILESYSTEM), EXT2)
	@$(MAKE) -C ext2/
endif

$(BINARY): filesystem $(COBJECTS) $(SOBJECTS)
	@echo " \033[0;36mLD \033[0mstage2.elf"
ifeq ($(FILESYSTEM), FAT16)
	@$(OBJCOPY) --strip-debug build/test.o
	@$(OBJCOPY) -O binary build/test.o build/test.bin
	-@echo LOCATION = 0x7E00\; > link_header.h
	@$(CC) -T linkstage2.ld -o $@ $(shell find build/ -name '*.o' ! -iname "test.o") $(CFLAGS) $(LDFLAGS)
endif
ifeq ($(FILESYSTEM), EXT2)
	-@echo LOCATION = 0x1000\; > link_header.h
	@$(CC) -T linkstage2.ld -o $@ $(shell find build/ -name '*.o') $(CFLAGS) $(LDFLAGS)
endif
	@echo " \033[0;37mOC\033[0m stage2.bin"
	@$(OBJCOPY) --only-keep-debug stage2.elf stage2.sym
	@$(OBJCOPY) --strip-debug stage2.elf
	@$(OBJCOPY) -O binary stage2.elf stage2.bin
	
%.o: %.c
	@$(CC) $(CFLAGS) -c $< -o $(BUILDDIR)/$@
	@echo " \033[0;35mCC\033[0m $<"

%.o: %.S
	@$(CC) $(CFLAGS) -c $< -o $(BUILDDIR)/$@
	@echo " \033[0;35mAS\033[0m $<"

clean:
	@echo " 🧹 Cleaning Stage 2 Bootloader Objects..."
	-@rm -rf link_header.h ||:
	-@rm -rf $(BUILDDIR) ||:
	-@rm -rf $(BINARY) ||:
	-@rm -rf $(COBJECTS) ||:
	-@rm -rf $(SOBJECTS) ||:
	-@rm -rf *.sym
	-@rm -rf *.bin
