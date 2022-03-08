#include <textmode.h>

// Current VGA Text Mode Matrix 'x'
uint8_t m_x = 0;

// Current VGA Text Mode Matrix 'y'
uint8_t m_y = 0;

/*
	update_cur

	Function information:
	Updates the cursor position taking x and y params.
	and returns a 16-bit value containing the current
	text mode cursor offset.

	Parameters:
	m_x -> Base of the screen (I Matrix)
	m_y -> Height of the screen (J Matrix)

	Return:
	16-bit value containing the calculated offset
*/
uint16_t update_cur(uint8_t m_x, uint8_t m_y)
{
	uint16_t m_offset = ((m_y * TEXT_MODE_WIDTH) + m_x);

	// Feed CRTC Address Register with 0x0E Subregister
	outb(CRTC_ADDR_REG, CUR_LOC_HI_REG);

	// Get high byte of m_offset and send it using Port I/O
	outb(CRTC_DATA_REG, (uint8_t) ((m_offset >> 8) & 0xFF));

	// Feed CRTC Address Register with 0x0F Subregister
	outb(CRTC_ADDR_REG, CUR_LOC_LO_REG);

	// Get low byte of m_offset and send it using Port I/O
	outb(CRTC_DATA_REG, (uint8_t) (m_offset & 0xFF));

	// Return the calculated offset
	return m_offset;
}

/*
	enable_cur

	Function information:
	Enables the cursor.

	Parameters:
	m_cur_start -> Cursor Start Line
	m_cur_end -> Cursor End Line

	Return:
	None
*/
void enable_cur(uint8_t m_cur_start, uint8_t m_cur_end)
{
	outb(CRTC_ADDR_REG, CUR_START_REG);
	outb(CRTC_DATA_REG, m_cur_start);

	outb(CRTC_ADDR_REG, CUR_END_REG);
	outb(CRTC_DATA_REG, m_cur_end);
}

/*
	init_text_mode

	Function information:
	Cleanly initializes VGA Mode 3 (Text Mode 80x25)

	Parameters:
	None

	Return:
	None
*/
void init_text_mode()
{
	// Set current X to 0
	m_x = 0;

	// Set current Y to 0
	m_y = 0;

	// Disable cursor
	disable_cur();

	// Update current cursor position
	update_cur(0, 0);

	// Enable cursor again
	enable_cur(14, 15);
}

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

/*
	disable_cur

	Function information:
	Disables Text Mode Cursor

	Parameters:
	None

	Return:
	None
*/
void disable_cur()
{
	// Feed CRTC Address Register with 0x0A Subregister
	outb(CRTC_ADDR_REG, CUR_START_REG);

	/*
		Cursor Start Register
		| 7	| 6 | 5 | 4 | 3 | 2 | 1 | 0 |
				|*CD| C. Scanline Start |

		* CD -> Cursor (Dis)enable Bit (Bit 5)
	*/
	outb(CRTC_DATA_REG, (1 << 5));
}

/*
	putc

	Function information:
	Puts a character into the current Text Mode Buffer Offset

	Parameters:
	m_char -> character to display

	Return:
	None

	Quirk [!]
	Only accessible from within text mode functions
*/
static void putc(char m_char)
{
	// Calculate the offset to write to
	uint16_t m_offset = ((m_x + (m_y * TEXT_MODE_WIDTH)) * 2);

	//
	volatile char *m_text_mode_buffer = (volatile char*)0xB8000;

	m_text_mode_buffer [m_offset] = m_char;
	m_text_mode_buffer [m_offset + 1] = 0x0F;

	// Check if we've finished the text mode column (80)
	if (m_x > 80)
	{
		// Set x back to 0 (Leftmost of the screen)
		m_x = 0;

		// Increase the row
		m_y++;
	}
	else
	{
		// Increase x by 1
		m_x++;	
	}

	// Check if we've got to the last row (25)
	if (m_y > 25)
	{
		// Move the buffer n-1 to accomodate a new clean row
	}
}

/*
	puts

	Function information:
	Puts a string into the current Text Mode Buffer Offset
	Updates cursor position accordingly

	Parameters:
	m_string -> string to display

	Return:
	None
*/
void puts(const char *m_string)
{
	uint32_t i = 0;

	while (m_string[i] != '\0')
	{
		putc(m_string[i]);
		i++;
	}

	update_cur(m_x + 2, m_y);
}
