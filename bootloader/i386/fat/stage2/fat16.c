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
    bool m_cond = true;

    int i = 0;

    uint8_t m_sect[512];

    uint32_t root_directory_start, root_directory_size, data_sector_start;

    fat16_bpb_t* fat16 = (fat16_bpb_t*)m_bpb;

    puts("Calculating FAT16 information...\n");

    root_directory_start = (fat16->reserved_sector_count) + (fat16->table_count * fat16->table_size_16);

    root_directory_size = (((fat16->root_entry_count * 32) + (fat16->bytes_per_sector - 1)) / fat16->bytes_per_sector);

    data_sector_start = (root_directory_start + root_directory_size);

    puts("# of Root Directory Entries: %d\n", fat16->root_entry_count);

    puts("Root Directory Start: %d (LBA Sector), Offset: 0x%X\n", root_directory_start, (512 * root_directory_start));
    puts("Root Directory Size: %d (Sectors) (%d bytes)\n", root_directory_size, (root_directory_size * 512));

    puts("Data Sector Start: %d (LBA Sector), Offset: 0x%X\n", data_sector_start, (512 * data_sector_start));

    do
    {
        atapio24_read((uint32_t *) m_sect, root_directory_start + i, 1);
        
        if (memcmp("TEST       ", ((char *) (((fat16_entry_t *) m_sect)->filename)), 11) == 0)
        {
            puts("Found TEST @ %d (LBA), FAT Cluster: %d\n", (((data_sector_start) + ((((fat16_entry_t *) m_sect)->starting_cluster) - 2))), (((fat16_entry_t *) m_sect)->starting_cluster));

            puts("Reading from 0x%X...\n", ((((data_sector_start) + ((((fat16_entry_t *) m_sect)->starting_cluster) - 2)) )) * 512 );


            atapio24_read((uint32_t *) m_sect, (data_sector_start + ((((fat16_entry_t *) m_sect)->starting_cluster) - 2)), 1);

            puts("File read successful, jumping to entrypoint @ 0x%X\n", &m_sect[0]);


            ((void(*)())m_sect)();

            m_cond = false;
        }

        if (i >= (fat16->root_entry_count - 1))
        {
            puts("i: %d\n", i);
            m_cond = false;
        }
        else
        {
            i++;
        }
    
    } while (m_cond == true);
}

