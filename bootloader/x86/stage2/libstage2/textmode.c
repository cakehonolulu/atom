#include <textmode.h>

/*
	get_cur_pos

	Function information:
	Returns a 16-bit value containing the high and
	low current cursor location register results 

	Parameters:
	None

	Return:
	16-bit value containing the result
*/
uint16_t get_cur_pos()
{
	/*
		Current position is formed by 2 8-bit
		fields that yield both a low and high
		current cursor location

				High Cursor Location	|	Low Cursor Location
		bits	[15      ...      8]		[7       ...     0]

		Thus we represent this with a 16-bit combined value
	*/

	// Feed CRTC Address Register with 0x0E Subregister
	outb(CRTC_ADDR_REG, CUR_LOC_HI_REG);

	// After feeding, result comes from reading CRTC Data Register
	uint8_t m_high = inb(CRTC_DATA_REG);

	// Feed CRTC Address Register with 0x0F Subregister
	outb(CRTC_ADDR_REG, CUR_LOC_LO_REG);

	// After feeding, result comes from reading CRTC Data Register
	uint8_t m_low = inb(CRTC_DATA_REG);

	// Craft a 16-bit position using both values
	return (uint16_t) (((uint16_t) m_high << 8) | m_low);
}