#include <libc.h>

/*
	reverse

	Function information:
	Reverses a nullbyte-terminated C string

	Parameters:
	m_string -> string to reverse
    m_length -> length of the string

	Return:
	None
*/
void reverse(char *m_string, int m_length)
{
    // Reverse only positive-length stringh and strings w/more than 1 character
    if (m_length >= 2)
    {
        // Starting point
        unsigned int m_start = 0;
        
        // End point (Minus '\0' byte)
        unsigned int m_end = m_length - 1;

        // Simple loop that exchanges each character of the string in a reversing pattern
        do
        {
            // Call to the swapping macro
            swap(char, *(m_string + m_start), *(m_string + m_end));

        } while (m_start++ < m_end--);
    }
}
