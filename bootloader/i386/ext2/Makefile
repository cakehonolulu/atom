include ../make.mk

.DEFAULT_GOAL := all

all: $(SOBJECTS)

%.o: %.S
	@$(CC) $(CFLAGS) -c $< -o $(BUILDDIR)/$@
	@echo " \033[0;35mAS\033[0m $<"

clean:
	@echo " 🧹 Cleaning EXT2 Bootloader Objects..."
	-@rm -rf *.elf ||:
	-@rm -rf *.sym ||:
	-@rm -rf *.bin ||:
	-@rm -rf *.o ||:
	-@rm -f boot1.h
