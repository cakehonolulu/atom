#include <stdint.h>
#include <stdbool.h>

#define swap(T, a, b) do { T tmp = a; a = b; b = tmp; } while (0)

unsigned int strlen(const char *m_string);
void reverse(char *m_string);
char *itoa(char *m_string, int m_number, unsigned char m_base);
void toupper(char *m_string);
