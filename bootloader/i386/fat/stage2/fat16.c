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

    puts("Calculating FAT16 information...\n");

    uint32_t root_directory_start = (fat16->reserved_sector_count) + (fat16->table_count * fat16->table_size_16);

    uint32_t root_directory_size = (((fat16->root_entry_count * 32) + (fat16->bytes_per_sector - 1)) / fat16->bytes_per_sector);

    uint32_t data_sector_start = root_directory_start + root_directory_size;

    puts("Root Directory Start: %d (LBA Sector)\n", root_directory_start);
    puts("Root Directory Size: %d (Sectors)\n", root_directory_size);

    puts("Data Sector Start: %d (LBA Sector)\n", data_sector_start);

    uint8_t m_sect[512];

    // Read one entry for now
    for (int i = 0; i < fat16->root_entry_count; i++)
    {
        atapio24_read((uint32_t *) &m_sect, root_directory_start, 1);
        //memcmp
    }
}

