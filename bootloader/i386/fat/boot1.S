#define BPB_BASE 0x7C00

// 8 bytes
#define BPB_NAME (BPB_BASE + 3)
// 2 bytes
#define BPB_SECTSZ (BPB_NAME + 8)
// 1 byte
#define BPB_SECTPC (BPB_SECTSZ + 2)
// 2 bytes
#define BPB_RESSCT (BPB_SECTPC + 1)
// 1 byte
#define BPB_NUMFAT (BPB_RESSCT + 2)
// 2 bytes
#define BPB_FATDIR (BPB_NUMFAT + 1)
// 2 bytes
#define BPB_SECPFT (BPB_FATDIR + 5)
// 1 byte
#define BPB_BOOTDR (BPB_SECPFT + 14)

.code16

.global init1


init1:
    jmp bootstrap

sector_size:
  .space 2
sectors_per_cluster:
  .space 1
reserved_sectors:
  .space 2
number_of_fats:
  .space 1
total_fat_directory_entries:
  .space 2
sectors_per_fat:
  .space 2
bios_boot_drive:
  .space 1

bootstrap:

    // Get sector size
    mov $BPB_SECTSZ, %bx
    mov (%bx), %bx
    movw %bx, sector_size

    // Get sectors per cluster
    mov $BPB_SECTPC, %bx
    movb (%bx), %bl
    movb %bl, sectors_per_cluster

    // Get reserved sectors
    mov $BPB_RESSCT, %bx
    mov (%bx), %bx
    movw %bx, reserved_sectors

    // Get the number of FATs
    mov $BPB_NUMFAT, %bx
    movb (%bx), %bl
    movb %bl, number_of_fats

    // Get the total number of fat dir. entries
    mov $BPB_FATDIR, %bx
    mov (%bx), %bx
    movw %bx, total_fat_directory_entries

    // Get sectors per fat
    mov $BPB_SECPFT, %bx
    mov (%bx), %bx
    movw %bx, sectors_per_fat

    // Get the boot drive
    mov $BPB_BOOTDR, %bx
    movb (%bx), %bl
    movb %bl, bios_boot_drive
    xchg %bx, %bx
    cli
    hlt
