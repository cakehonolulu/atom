#include <stdarg.h>
#include <stddef.h>
#include <stdint.h>

void * memcpy(void * restrict dest, const void * restrict src, size_t n) {
    asm volatile("cld; rep movsb"
                : "=c"((int){0})
                : "D"(dest), "S"(src), "c"(n)
                : "flags", "memory");
    return dest;
}

void *memmove(void *dest, const void *src, size_t n)
{
    unsigned char tmp[n];
    memcpy(tmp,src,n);
    memcpy(dest,tmp,n);
    return dest;
}

void memset(unsigned char *dest, unsigned char val, unsigned int len) {
    unsigned char *temp = (unsigned char *)dest;
    for ( ; len != 0; len--) *temp++ = val;
}

void itoa(int n, char str[]) {
    int i, sign;
    if ((sign = n) < 0) n = -n;
    i = 0;
    do {
        str[i++] = n % 10 + '0';
    } while ((n /= 10) > 0);

    if (sign < 0) str[i++] = '-';
    str[i] = '\0';

    reverse(str);
}

/* K&R */
void reverse(char s[]) {
    int c, i, j;
    for (i = 0, j = strlen(s)-1; i < j; i++, j--) {
        c = s[i];
        s[i] = s[j];
        s[j] = c;
    }
}

/* K&R */
int strlen(char s[]) {
    int i = 0;
    while (s[i] != '\0') ++i;
    return i;
}

void append(char s[], char n) {
    int len = strlen(s);
    s[len] = n;
    s[len+1] = '\0';
}

void backspace(char s[]) {
    int len = strlen(s);
    s[len-1] = '\0';
}

/* K&R 
 * Returns <0 if s1<s2, 0 if s1==s2, >0 if s1>s2 */
int strcmp(char s1[], char s2[]) {
    int i;
    for (i = 0; s1[i] == s2[i]; i++) {
        if (s1[i] == '\0') return 0;
    }
    return s1[i] - s2[i];
}

static void hextoa(char* buffer, uint32_t value) {
    static const char hex[] = "0123456789abcdef";
    const char* x = (const char*)&value;

    for(int i = 3; i >= 0; i--) {
        char ch = x[i];
        *buffer++ = hex[(ch >> 4) & 0xf];
        *buffer++ = hex[ch & 0xf];
    }

    *buffer = 0;
}


static const long hextable[] = {
   [0 ... 255] = -1, // bit aligned access into this table is considerably
   ['0'] = 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, // faster for most modern processors,
   ['A'] = 10, 11, 12, 13, 14, 15,       // for the space conscious, reduce to
   ['a'] = 10, 11, 12, 13, 14, 15        // signed char.
};

/** 
 * @brief convert a hexidecimal string to a signed long
 * will not produce or process negative numbers except 
 * to signal error.
 * 
 * @param hex without decoration, case insensitive. 
 * 
 * @return -1 on error, or result (max (sizeof(long)*8)-1 bits)
 */
long hexdec(unsigned const char *hex) {
   long ret = 0; 
   while (*hex && ret >= 0) {
      ret = (ret << 4) | hextable[*hex++];
   }
   return ret; 
}

void printk(char* fmt, ...)
{
    if (fmt)
    {
        va_list list;
        va_start(list, fmt);

        char* ch;

        for (ch = fmt; *ch; ch++)
        {
            if (*ch != '%')
            {
                putch(*ch);
            }
            else
            {
                int signed_integer;
                unsigned int unsigned_integer;
                char* signed_string;
                ch++;

                switch (*ch)
                {
                    case 'c':
                        signed_integer = va_arg(list, int);
                        putch(signed_integer);
                        break;
                    case 'd':
                        signed_integer = va_arg(list, int);
                        printkint(signed_integer);
                        break;
                    case 's':
                        signed_string = va_arg(list, char*);
                        print(signed_string);
                        break;
                    case 'u':
                        unsigned_integer = va_arg(list, unsigned int);
                        printkuint(unsigned_integer);
                        break;
                    case 'x':
                        unsigned_integer = va_arg(list, unsigned int);
                        printkhex(unsigned_integer);
                        break;
                    default:
                        putch('%');
                        putch(*ch);
                        break;
                }
            }
        }
    }
}