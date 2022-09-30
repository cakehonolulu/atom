#include <fat16.h>

void fat16_file_info(fat16_entry_t *fat16_entry) {
    // Based on file's name
    switch(fat16_entry->filename[0])
    {
        case 0x2E:
            puts("Directory: ");

            for (int i = 0; i < 8; i++)
            {
                puts("%c", fat16_entry->filename[i]);
            }

            puts(".");

            for (int i = 0; i < 3; i++)
            {
                puts("%c", fat16_entry->ext[i]);
            }

            puts("\n");

            break;
        default:
            puts("Found File: ");
            for (int i = 0; i < 8; i++)
            {
                puts("%c", fat16_entry->filename[i]);
            }

            puts(".");

            for (int i = 0; i < 3; i++)
            {
                puts("%c", fat16_entry->ext[i]);
            }

            puts("\n");

            break;
    }
    
}

void fat16_parse(uint8_t *m_bpb)
{
    fat16_bpb_t* fat16 = (fat16_bpb_t*)m_bpb;

    uint32_t rootdir_size;

    puts("BPB OEM name: ");

    for (int i = 0; i <= 8; i++)
    {
        puts("%c", fat16->oem_name[i]);
    }   

    puts("\nBPB Sectors Long: %d", fat16->total_sectors_32);

    puts("\nBPB Filesystem: ");

    for (int i = 0; i < BPB_FSTYPELEN; i++)
    {
        puts("%c", m_bpb[BPB_FILESYS + i]);
    }

    puts("\nBPB Media Type: 0x%X\n", fat16->media_type);

    rootdir_size = (((fat16->root_entry_count * 32) + (fat16->bytes_per_sector - 1)) / fat16->bytes_per_sector);

    puts("Root Directory Size: %d (Sectors)\n", rootdir_size);

    uint8_t m_sect[512];
    uint32_t first_data_sector;

    first_data_sector = (fat16->table_count * fat16->table_size_16) + fat16->reserved_sector_count + fat16->hidden_sector_count;

    puts("First Data Sector: %d\n", first_data_sector);

    puts("Number of FAT Tables: %d\n", fat16->table_count);
    puts("Sectors per FAT: %d\n", fat16->table_size_16);

    // Read one entry for now
    atapio24_read((uint32_t *) &m_sect, first_data_sector, 1);
    fat16_file_info((fat16_entry_t *) &m_sect);
}

