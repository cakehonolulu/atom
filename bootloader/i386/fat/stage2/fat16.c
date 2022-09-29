#include <fat16.h>

void fat16_parse(uint8_t *m_bpb)
{
    fat16_bpb_t* fat16 = (fat16_bpb_t*)m_bpb;

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

}
