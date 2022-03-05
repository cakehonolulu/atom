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
	asm volatile ("inb %1, %0"
				: "=a" (m_value)
				: "Nd" (m_address));

	// Return the value readed
	return m_value;
}
