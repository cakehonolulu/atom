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
uint8_t inb(uint16_t m_address)
{
	// Value readed
	uint8_t m_value;

	/*
		=a specifies where it should put the return value
		Nd specifies %dx register or 8-bit immediate addr. for inb
	*/
	__asm__ __volatile__ ("inb %1, %0"
						: "=a" (m_value)
						: "Nd" (m_address));

	// Return the value readed
	return m_value;
}

/*
	inw

	Function information:
	Returns a word (2 bytes) from the Port I/O

	Parameters:
	m_address -> 16-bit immediate address
	containing the m_address to read from

	Return:
	Word read at m_address
*/
uint16_t inw(uint16_t m_address)
{
	// Value readed
    uint16_t m_value;

	/*
		=a specifies where it should put the return value
		Nd specifies %dx register or 16-bit immediate addr. for inw
	*/
    __asm__ __volatile__ ("inw %1, %0"
    					: "=a" (m_value)
    					: "Nd" (m_address));
    return m_value;
}

/*
	inl

	Function information:
	Returns a dword (4 bytes) from the Port I/O

	Parameters:
	m_address -> 16-bit immediate address
	containing the m_address to read from

	Return:
	Dword read at m_address
*/
uint32_t inl(uint16_t m_address)
{
	// Value readed
    uint32_t m_value;

	/*
		=a specifies where it should put the return value
		d specifies %edx register or 32-bit immediate addr. for inl
	*/
    __asm__ __volatile__ ("inl %1, %0"
    					: "=a" (m_value)
    					: "d" (m_address));
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
void outb(uint16_t m_address, uint8_t m_data)
{
	/*
		a specifies the 'a' register
		Nd specifies %dx register or 8-bit immediate addr. for outb
	*/
	__asm__ __volatile__ ("outb %0, %1"
						:
						: "a" (m_data), "Nd" (m_address));
}

/*
	outw

	Function information:
	Sends a byte to the Port I/O

	Parameters:
	m_address -> 16-bit immediate address
	containing the port to write to

	m_data -> 16-bit value to write

	Return:
	none
*/
void outw(uint16_t m_address, uint16_t m_data)
{
	/*
		a specifies the 'a' register
		Nd specifies %dx register or 16-bit immediate addr. for outw
	*/
    __asm__ __volatile__ ("outw %0, %1"
    					:
    					: "a" (m_data), "d" (m_address));
}

/*
	outl

	Function information:
	Sends a byte to the Port I/O

	Parameters:
	m_address -> 16-bit immediate address
	containing the port to write to

	m_data -> 16-bit value to write

	Return:
	none
*/
void outl(uint16_t m_address, uint32_t m_data)
{
	/*
		a specifies the 'a' register
		Nd specifies %dx register or 32-bit immediate addr. for outw
	*/
    __asm__ __volatile__ ("outl %0, %1"
    					:
    					: "a" (m_data), "d" (m_address));
}

/*
	insw

	Function information:
	Sends a string to the desired port

	Parameters:
	m_address -> 16-bit immediate address
	containing the port to write from

	m_dst -> 32-bit address to start writing to

	m_size -> size of the data to copy

	Return:
	none
*/
void insw(uint16_t m_address, uint32_t *m_dst, uint32_t m_size)
{
    __asm__ __volatile__ ("rep insw"
        				: "+D" (m_dst), "+c" (m_size), "=m" (*m_dst)
        				: "d" (m_address)
        				: "memory");
}
