#include <fat16.h>

void fat16_parse(uint8_t *m_bpb)
{
    puts("BPB OEM name: ");

    for (int i = 0; i <= BPB_OEMSTRNLEN; i++)
    {
        puts("%c", m_bpb[BPB_OEMSTRN + i]);
    }

    puts("\nBPB Sectors Long: %d", m_bpb[BPB_TOTSECT]);

    puts("\nBPB Filesystem: ");

    for (int i = 0; i < BPB_FSTYPELEN; i++)
    {
        puts("%c", m_bpb[BPB_FILESYS + i]);
    }
}
