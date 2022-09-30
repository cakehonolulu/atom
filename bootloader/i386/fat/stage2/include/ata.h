#ifndef ATA_H
#define ATA_H

#include <stdint.h>

/* Defines */

/* ATA Status Flags */
#define BSY (1 << 7)
#define RDY (1 << 6)
#define DF	(1 << 5)
#define DRQ (1 << 3)
#define ERR (1 << 0)

/* ATA Buses */
#define ATA_PRIMARY 0x1F0
#define ATA_SECONDARY 0x170

#define ATA_DEFAULT ATA_PRIMARY

/* ATA Registers */
#define ATA_DATA_REG		(ATA_DEFAULT + 0)
#define ATA_SECT_CNT_REG	(ATA_DEFAULT + 2)
#define ATA_SECT_NUM_REG	(ATA_DEFAULT + 3)
#define ATA_CYL_LO_REG		(ATA_DEFAULT + 4)
#define ATA_CYL_HI_REG		(ATA_DEFAULT + 5)
#define ATA_DRIVE_HEAD_REG	(ATA_DEFAULT + 6)
#define ATA_CMD_STA_REG		(ATA_DEFAULT + 7)

/* ATA Commands */
#define ATA_READ_CMD		0x20
#define ATA_WRITE_CMD		0x30
#define ATA_IDENTIFY_CMD	0xEC

/* Typedefs */
typedef enum {clear, set} m_bit_status;

/* Functions */
void ata_check_bsy(m_bit_status m_bit);
void ata_check_rdy(m_bit_status m_bit);
void ata_check_err(m_bit_status m_bit);
void ata_check_drq(m_bit_status m_bit);
void atapio24_identify(uint32_t *m_dst);
void atapio24_read(uint32_t *m_dst, uint32_t m_lba, uint8_t m_sectsz);
void atapio24_write(uint32_t *m_data, uint32_t m_lba, uint8_t m_sectsz);

#endif /* ATA_H */
