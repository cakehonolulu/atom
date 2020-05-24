#include <stdarg.h>
#include <stdint.h>

void memcpy(unsigned char *source, unsigned char *dest, int nbytes) {
    int i;
    for (i = 0; i < nbytes; i++) {
        *(dest + i) = *(source + i);
    }
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
                int d_num;
                uint16_t u_num;
                char* d_str;
                ch++;

                switch (*ch)
                {
                    case 'c':
                        d_num = va_arg(list, int);
                        putch(d_num);
                        break;
                    case 'd':
                        d_num = va_arg(list, int);
                        printkint(d_num);
                        break;
                    case 's':
                        d_str = va_arg(list, char*);
                        print(d_str);
                        break;
                    case 'u':
                        u_num = va_arg(list, unsigned int);
                        printkuint(u_num);
                        break;
                    case 'x':
                        u_num = va_arg(list, unsigned int);
                        printkhex(u_num);
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