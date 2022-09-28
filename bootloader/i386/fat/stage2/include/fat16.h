#include <stdint.h>
#include <textmode.h>

/* Defines */

#define BPB_JMPNOPS 0x00
#define BPB_OEMSTRN 0x03
#define BPB_BYTESPS 0x0B
#define BPB_SECSTPC 0x0D
#define BPB_RESVSEC 0x0E
#define BPB_NUMFATS 0x10
#define BPB_TOTALST 0x11
#define BPB_MEDIATP 0x15
#define BPB_FATSIZE 0x16
#define BPB_SECTPTR 0x18
#define BPB_NUMHEAD 0x1A
#define BPB_HIDSECT 0x1C
#define BPB_TOTSECT 0x20

#define BPB_DRVNUMB 0x24
#define BPB_CURHEAD 0x25
#define BPB_BOOTSIG 0x26
#define BPB_VOLUMID 0x27
#define BPB_VOLUMLB 0x2B
#define BPB_FILESYS 0x36

#define BPB_JMPNOPSLEN (BPB_OEMSTRN)
#define BPB_OEMSTRNLEN (BPB_BYTESPS - BPB_OEMSTRN)
#define BPB_VOLUMEIDLEN (BPB_VOLUMLB - BPB_VOLUMID)
#define BPB_VOLUMELABELLEN (BPB_FILESYS - BPB_VOLUMLB)
#define BPB_FSTYPELEN 0x08


/* Functions */
void fat16_parse(uint8_t *m_bpb);
