#include <stdint.h>

#define swap(T, a, b) do { T tmp = a; a = b; b = tmp; } while (0)

unsigned int strlen(const char *m_string);
void reverse(char *m_string);
