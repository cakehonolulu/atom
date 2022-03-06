#include <io.h>

/*
	inb

	Function information:
	Returns a byte from the Port I/O

	Parameters:
	m_address -> 16-bit immediate address
	containing the port to read from

	Return:
	Byte read at m_address
*/
inline uint8_t inb(uint16_t m_address)
{
	// Value readed
	uint8_t m_value;

	/*
		=a specifies where it should put the return value
		Nd specifies %dx register or 8-bit immediate addr. for inb
	*/
	asm volatile ("inb %0, %1"
				: "=a" (m_value)
				: "Nd" (m_address));

	// Return the value readed
	return m_value;
}

/*
	outb

	Function information:
	Sends a byte to the Port I/O

	Parameters:
	m_address -> 16-bit immediate address
	containing the port to write to

	m_data -> 8-bit value to write

	Return:
	none
*/
inline void outb(uint16_t m_address, uint8_t m_data)
{
	/*
		a specifies the 'a' register
		Nd specifies %dx register or 8-bit immediate addr. for outb
	*/
	asm volatile ("outb %0, %1"
				:
				: "a" (m_data), "Nd" (m_address));
}
