ARCH ?= x86

QEMU = qemu-system-i386

# Tools.
CC = i686-elf-gcc
LD = i686-elf-gcc
AS = i686-elf-gcc

# Check that we have the required software.
ifeq (, $(shell which $(CC)))
    $(error "$(CC) not found. Is the toolchain compiler enabled?")
endif
ifeq (, $(shell which $(LD)))
    $(error "$(LD) not found. Is the toolchain compiler enabled?")
endif
ifeq (, $(shell which $(AS)))
    $(error "$(AS) not found. Is the toolchain compiler enabled?")
endif

QEMUARGS =
QEMU_DEBUGARGS = -s -S & gdb --eval-command="target remote localhost:1234"

BOCHS = bochs

# 1.44 MB Floppy for now
FLOPPY_DISK = floppy.img

# Looks like DD considers floppy's physical Sector 1 as 0, use this variable to avoid confusion.
FLOPPY_SECTOR1 = 0
# Do the same for Sector 2, then, we will calculate the size of the second stage bootloader (boot1)
# and dynamically assign the starting (Kernel-containing) sector using that.
FLOPPY_SECTOR2 = 1
# Hardcoded to 3 for now! Find a way to find this variable dynamically using Second Stage Bootloader's
# (boot1) size.
FLOPPY_KERNEL_STARTING_SECTOR = 3

LDSCRIPT = kernel/arch/$(ARCH)/linker.ld
LDFLAGS =

.PHONY: clean bochs qemu qemu-debug

all: clean floppy.img

floppy.img: arch bloader
	-@mkfs.msdos -C floppy.img 1440 >/dev/null
	-@dd conv=notrunc if=bootloader/$(ARCH)/boot0.bin of=floppy.img bs=512 seek=$(FLOPPY_SECTOR1) status=none
	-@dd conv=notrunc if=bootloader/$(ARCH)/boot1.bin of=floppy.img bs=512 seek=$(FLOPPY_SECTOR2) status=none
	-@dd conv=notrunc if=kernel/arch/$(ARCH)/kernel.bin of=floppy.img bs=512 seek=$(FLOPPY_KERNEL_STARTING_SECTOR) status=none

arch:
	make -C kernel/arch/$(ARCH)

bloader:
	make -C bootloader/$(ARCH)

clean:
	make -C kernel/arch/$(ARCH) clean
	make -C bootloader/$(ARCH) clean
	-@rm floppy.img

bochs:
	$(BOCHS) -q -f bochsrc.bxrc 'floppya: type=1_44, 1_44=floppy.img, status=inserted, write_protected=0'

qemu: $(FLOPPY_DISK)
	$(QEMU) -fda $^ $(QEMU_ARGUMENTS)

qemu-debug: $(FLOPPY_DISK)
	$(QEMU) -fda $^ $(QEMU_DEBUG_ARGUMENTS)

$(V).SILENT:
