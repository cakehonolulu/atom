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

/*
	itoa

	Function information:
	Converts a (Decimal, hexadecimal) number to a string

	Parameters:
	m_string -> string buffer
    m_number -> decimal to put into the string
    m_base   -> base of the number (Hexa, Deca...)

	Return:
	The numbered string
*/
char *itoa(char *m_string, int m_number, unsigned char m_base)
{
    unsigned int i = 0;
    bool m_negative = false;
 
    if (m_number == 0)
    {
        m_string[i++] = '0';
        m_string[i] = '\0';
        return m_string;
    }

    if (m_number < 0 && m_base == 10)
    {
        m_negative = true;
        m_number = -m_number;
    }

    while (m_number != 0)
    {
        int m_remainder = m_number % m_base;
        m_string[i++] = (m_remainder > 9) ? (m_remainder - 10) + 'a' : m_remainder + '0';
        m_number = m_number / m_base;
    }
 
    if (m_negative)
    {
        m_string[i++] = '-';
    }

    m_string[i] = '\0';

    reverse(m_string);
 
    return m_string;
}

/*
	toupper

	Function information:
	Converts the lowercase characters in a string to uppercase

	Parameters:
	m_string -> string to convert

	Return:
	None
*/
void toupper(char *m_string)
{
    while (*m_string != '\0')
    {
        if ((((char) *m_string) >= 'a') && (((char) *m_string) <= 'z'))
        {
			*m_string -= 32;
		}

        m_string++;
    }
}

/*
	tolower

	Function information:
	Converts the uppercase characters in a string to lowercase

	Parameters:
	m_string -> string to convert

	Return:
	None
*/
void tolower(char *m_string)
{
    while (*m_string != '\0')
    {
        if ((((char) *m_string) >= 'A') && (((char) *m_string) <= 'Z'))
        {
			*m_string += 32;
		}

        m_string++;
    }
}
