# Atom

- What is Atom?

Atom is an ambicious project that holds both, a bootloader that supports Legacy Boot Protocols (BIOS with MBR or UEFI/EFI with Compatibility Mode, CSM) or
UEFI Boot Protocol; alongside a kernel that covers a Legacy PC or a more newer one.

It is designed for being used on x86 (i386+) processors using BIOS (Or UEFI's Legacy-Compatible's Mode, CSM) and/or x86-64 (AMD64) with BIOS/UEFI (Although UEFI is preferred as the bootstrap is much cleaner).

The aim is to provide compatibility both, with the oldest family of PCs and with the cutting-edge family of PCs (Thus we support both Legacy and UEFI, even though Legacy is discontinued in favour of UEFI so that we try pushing the standards).
It runs on x86 (BIOS/EFI/UEFI/CSM) and x86-64 (Again, BIOS/EFI/UEFI/CSM).

We're starting to migrate our work to x86-64 (aarch64 coming later on) and UEFI, based on my philosophy of running always on the latest standards/as the industry moves.

-----------------

- Compiling Atom (Legacy)

#### a - Prerequisites:
Compiling Atom only depends on:

	* i[3-7]86-elf Cross Compiler Toolchain
	* nasm
	* make
	* dosfstools

#### b - Downloading from GIT:

	git clone https://github.com/5HT-2A/Atom

#### c - Compiling:
Assuming you have the toolchain binaries on your environment path, everything should compile without problems:

	cd Atom/
	make

This will result in a hard disk image called hdd.img accordingly that can be used on bochs (If you're emulating).

- Running Atom (Legacy)

#### a - Prerequisites:

If emulating:

	* bochs

#### b - Running on bochs:

	make bochs

For now, Atom hasn't been tested on real hardware, if you choose to do so, do it at your own risk!
When we manage to make it a bit more stable, we will update the README with a way to try it on real hardware.

-----------------

- Atom components

#### initium (Legacy)

initium is Atom's 2 stage bootloader

Features:

	* Two stage bootloader
	* A20 Line Enabling (If not enabled on boot)
	* Basic VGA Memory Handling (Printing to screen) on Real and Protected Mode
	* Protected Mode
	* Huge Unreal Mode (32-bit segment registers on Real Mode)
	* Kernel Loading from Floppy/HDD using INT13
	* Relocation of the kernel above 1MB memory mark from Unreal Mode
	* Error checking of all the possible things (So no we don't get caught on unexpected errors)
	* Jumping to the relocated kernel binary while landing on 32-bit mode
	
#### nucleus (Legacy)

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

	* Switch from 1.44MB Floppy to HDD (DONE)
	* Paging (DONE)
	* Memory Allocation (DONE)
	* Add more support for the basic x86 components (APIC, ATA, ATAPIO, CMOS...)
	* Enter Long Mode (64-Bit) (DONE, not enabled by default)
	* Switch to UEFI (But preserving the Legacy code)
	* Separate Arch Init and Kernel Init
	* For legacy, try differentiating the toolchain (Pre-Pentium, Max Compat, Use i386; Post-Pentium, MMX, SSE, Use i686+)
-----------------