# Atom

- What is Atom?

Atom is a project that holds both a 2 Stage Bootloader and a (Very rudimentary) kernel.
It is designed for being used on i386+ processors using BIOS (Or UEFI's Legacy-Compatible's Mode).
-----------------

- Compiling Atom

#### a - Compile Prerequisites:
Compiling Atom only depends on:

	* i[3-6]86-elf Cross Compiler Toolchain 
	* make
	* dosfstools

#### b - Running Prerequisites:

If emulating:

	* bochs

For now, Atom hasn't been tested on real hardware, if you choose to do so, do it at your own risk!
When we manage to make it a bit more stable, we will update the README with a way to try it on real hardware.

#### c - Downloading from GIT:

	git clone https://github.com/5HT-2A/Atom

#### d - Compiling:
Assuming you have the toolchain binaries on your environment path, everything should compile without problems:

	cd Atom/
	make

This will result in a floppy image called floppy.img accordingly that can be used on bochs.

#### e - Running on bochs:

	make bochs
-----------------

- Atom components

#### initium

initium is Atom's 2 stage bootloader

Features:

	* Two stage bootloader
	* A20 Line Enabling (If not enabled on boot)
	* Basic VGA Memory Handling (Printing to screen) on Real and Protected Mode
	* Protected Mode
	* Huge Unreal Mode (32-bit segment registers on Real Mode)
	* Kernel loading (nucleus)
	* Relocation of the kernel above 1MiB memory mark from Unreal Mode
	* Error checking of all the possible things (So no we don't get caught on unexpected errors)
	* Jumping to the relocated kernel binary from 32-bit mode
	
#### nucleus

nucleus is Atom's kernel

Features:
	
	* VGA Memory Handling (80x25 VGA Text Mode) (On-screen printing...)
	* Global Descriptor Tables (GDT) Encoding and Updating
	* Interrupt Descriptor Tables (IDT) Encoding and Updating
	* Interrupt Service Routines (ISR) Handling
	* PIC Handling (8259)
	* Interrupt Routing Queue (IRQ) Handling and Registering
	* PIT Handling (8253/825354)
	* PS/2 Keyboard Handling (8042)

- Atom roadmaps

#### initium && nucleus

	* Switch from 1.44MB Floppy to HDD
	* Paging
	* Memory Allocation
	* Add more support for the basic x86 components (APIC, ATA, ATAPIO, CMOS...)
	* Enter Long Mode (64-Bit)
	* Switch to UEFI (But preserving the Legacy code)

-----------------