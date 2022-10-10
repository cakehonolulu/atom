#include <ata.h>
#include <textmode.h>
#include <io.h>

/*
	ata_check_bsy

	Function information:
	Waits for ATA to be ready to send/recieve data

	Parameters:
	m_bit -> set for 1, clear for 0

	Return:
	none
*/
void ata_check_bsy(m_bit_status m_bit)
{
	if (m_bit == set)
	{
		while(inb(ATA_CMD_STA_REG) & BSY);
	}
	else
	{
		while(!(inb(ATA_CMD_STA_REG) & BSY));
	}
}

/*
	ata_check_rdy

	Function information:
	Waits for ATA to be operative again (Not spinning)

	Parameters:
	m_bit -> set for 1, clear for 0

	Return:
	none
*/
void ata_check_rdy(m_bit_status m_bit)
{
	if (m_bit == set)
	{
		while(inb(ATA_CMD_STA_REG) & RDY);
	}
	else
	{
		while(!(inb(ATA_CMD_STA_REG) & RDY));
	}
}

/*
	ata_check_ready

	Function information:
	Waits for ATA to have ERR bit toggled

	Parameters:
	m_bit -> set for 1, clear for 0

	Return:
	none
*/
void ata_check_err(m_bit_status m_bit)
{
	if (m_bit == set)
	{
		while(inb(ATA_CMD_STA_REG) & ERR);
	}
	else
	{
		while(!(inb(ATA_CMD_STA_REG) & ERR));
	}
}

/*
	ata_check_drq

	Function information:
	Waits for ATA to have PIO data to transfer or accept

	Parameters:
	m_bit -> set for 1, clear for 0

	Return:
	none
*/
void ata_check_drq(m_bit_status m_bit)
{
	if (m_bit == set)
	{
		while(inb(ATA_CMD_STA_REG) & DRQ);
	}
	else
	{
		while(!(inb(ATA_CMD_STA_REG) & DRQ));
	}
}

/*
	atapio24_identify

	Function information:
	Runs an ATA IDENTIFY command targetting a bus

	Parameters:
	m_dst -> pointer to a 512-byte memory area where the IDENTIFY
	command will read the data to

	Return:
	none
*/
void atapio24_identify(uint32_t *m_dst)
{
	// Function's variables
	uint8_t m_status, m_lba_mi, m_lba_hi;

	// Check if drive is busy and if it's ready to process any new command queues
	ata_check_bsy(set);
	ata_check_drq(set);

	/*
		TODO:

		Check for slave bit and send the corresponding value automatically.
	
		For now, use a define'd comparison.
	*/
	if (ATA_DEFAULT == ATA_PRIMARY)
	{
		// Sends the command to the master drive
		outb(ATA_DRIVE_HEAD_REG, 0xA0);
	}
	else
	{
		// Sends the command to the slave drive
		outb(ATA_DRIVE_HEAD_REG, 0xB0);
	}

	// Send the sector count size to the register
	outb(ATA_SECT_CNT_REG, 0);
	
	// Sends bits [0:7] of the LBA value to the register
	outb(ATA_SECT_NUM_REG, 0);
	
	// Sends bits [8:15] of the LBA value to the register
	outb(ATA_CYL_LO_REG, 0);
	
	// Sends bits [16:23] of the LBA value to the register
	outb(ATA_CYL_HI_REG, 0); 

	// Send the identify command to the register
	outb(ATA_CMD_STA_REG, ATA_IDENTIFY_CMD);

	// Wait until Busy Bit is set
	do {
		m_status = inb(ATA_CMD_STA_REG);
	} while (m_status & BSY);

	// Check if status is different to 0, that would mean no drive is attached to that bus
	if (m_status != 0)
	{
		// Check if ATA is Busy processing commands
		ata_check_bsy(set);

		// LBA Mid and High values must be _both_ 0, else; drive isn't ATA
		m_lba_mi = inb(ATA_CYL_LO_REG);
		m_lba_hi = inb(ATA_CYL_HI_REG);

		// Check for it
		if (m_lba_mi == 0 && m_lba_hi == 0)
		{
			// Wait while ERR Bit is set
			ata_check_err(set);
			
			// Fill using Port I/O each memory location's contents
			insw(ATA_DATA_REG, (uint32_t *) m_dst, 256);

			puts("ata : Drive init successful!\n");
		}
		else
		{
			puts("ata : Drive isn't ATA-compatible!\n");
		}
	}
	else
	{
		puts("ata : Drive doesn't exist!\n");
	}
}

/*
	atapio24_read

	Function information:
	Reads sectors from ATA (24 Bit LBA) to a destination address.

	Parameters:
	m_dst -> 32 bit memory address to read to
	m_lba -> 24 bit LBA addressing value to interact with the disk
	m_sectsz -> sectors to read

	Return:
	none
*/
void atapio24_read(uint32_t *m_dst, uint32_t m_lba, uint8_t m_sectsz)
{
	// Needed for the loop
	unsigned int i;

	/*
		TODO:

		Check for slave bit and send the corresponding value automatically.
	
		For now, use a define'd comparison.
	*/
	if (ATA_DEFAULT == ATA_PRIMARY)
	{
		// Sends the command to the master drive
		outb(ATA_DRIVE_HEAD_REG, 0xE0 | ((m_lba >> 24) & 0xF));
	}
	else
	{
		// Sends the command to the slave drive
		outb(ATA_DRIVE_HEAD_REG, 0xF0 | ((m_lba >> 24) & 0xF));
	}

	// Send the sector count size to the register
	outb(ATA_SECT_CNT_REG, m_sectsz);
	
	// Sends bits [0:7] of the LBA value to the register
	outb(ATA_SECT_NUM_REG, (uint8_t) m_lba);
	
	// Sends bits [8:15] of the LBA value to the register
	outb(ATA_CYL_LO_REG, (uint8_t) (m_lba >> 8));
	
	// Sends bits [16:23] of the LBA value to the register
	outb(ATA_CYL_HI_REG, (uint8_t) (m_lba >> 16)); 
	
	// Send the read command to the register
	outb(ATA_CMD_STA_REG, ATA_READ_CMD);

	// Do this for all the sectors needed
	for (i = 0; i < m_sectsz; i++)
	{
		// This is painfully slow, we should avoid ATA PIO
		ata_check_bsy(set);
		
		/*
			TODO:
			Regular sector size is 512 bytes, that doesn't mean
			that all drives will default to that so better check
			in the future for that

			For now:
			256 words (inw) = 512 bytes (Sector size)
		*/

		// Fill using Port I/O each memory location's contents
		insw(ATA_DATA_REG, m_dst, 256);

		// Point to the next 512 bytes
		m_dst += 256;
	}
}

/*
	atapio24_write

	Function information:
	Reads sectors from ATA (24 Bit LBA) to a destination address.

	Parameters:
	m_dst -> 32 bit memory address to read to
	m_lba -> 24 bit LBA addressing value to interact with the disk
	m_sectsz -> sectors to read

	Return:
	none
*/
void atapio24_write(uint32_t *m_data, uint32_t m_lba, uint8_t m_sectsz)
{
	// For the nested loops
	unsigned int i, j;

	/*
		TODO:

		Check for slave bit and send the corresponding value automatically.
	
		For now, use a define'd comparison.
	*/
	if (ATA_DEFAULT == ATA_PRIMARY)
	{
		// Sends the command to the master drive
		outb(ATA_DRIVE_HEAD_REG, 0xE0 | ((m_lba >> 24) & 0xF));
	}
	else
	{
		// Sends the command to the slave drive
		outb(ATA_DRIVE_HEAD_REG, 0xF0 | ((m_lba >> 24) & 0xF));
	}

	// Send the sector count size to the register
	outb(ATA_SECT_CNT_REG, m_sectsz);
	
	// Sends bits [0:7] of the LBA value to the register
	outb(ATA_SECT_NUM_REG, (uint8_t) m_lba);
	
	// Sends bits [8:15] of the LBA value to the register
	outb(ATA_CYL_LO_REG, (uint8_t) (m_lba >> 8));
	
	// Sends bits [16:23] of the LBA value to the register
	outb(ATA_CYL_HI_REG, (uint8_t) (m_lba >> 16)); 

	// Send the write command to the register
	outb(ATA_CMD_STA_REG, ATA_WRITE_CMD);

	// Do this for all the sectors needed
	for (i = 0; i < m_sectsz; i++)
	{
		// This is painfully slow, we should avoid ATA PIO
		ata_check_bsy(set);

		/*
			TODO:
			Regular sector size is 512 bytes, that doesn't mean
			that all drives will default to that so better check
			in the future for that

			For now:
			256 words (inw) = 512 bytes (Sector size)
		*/
		for (j = 0; j < 0x100; j++)
		{
			// Write using Port I/O the data to the disk
			outl(ATA_DATA_REG, m_data[j]);
		}
	}
}
