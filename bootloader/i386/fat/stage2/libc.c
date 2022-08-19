#include <libc.h>

/*
	strlen

	Function information:
	Calculates the number of characters (Length) in a nullbyte-terminated C string

	Parameters:
	m_string -> string to calculate the length of

	Return:
	Number of characters (Length) in that string
*/
unsigned int strlen(const char *m_string)
{
    unsigned int m_length = 0;

    while (*m_string != '\0')
    {
        m_length++;
        m_string++;
    }

    return m_length;
}

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
void reverse(char *m_string)
{
    unsigned int m_length = strlen(m_string);
    
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
