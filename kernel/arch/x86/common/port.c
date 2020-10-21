unsigned char inb(unsigned short port)
{
    unsigned char result;
    __asm__ __volatile__ ("inb %1, %0" : "=a" (result) : "dN" (port));
    return result;
}

void outb(unsigned short port, unsigned char data)
{
    __asm__ __volatile__("outb %1, %0" : : "dN" (port), "a" (data));
}

unsigned short inw(unsigned short port)
{
    unsigned short result;
    __asm__ __volatile__("inw %w1, %w0" : "=a"(result) : "Nd" (port));
    return result;
}

void outw(unsigned short port, unsigned short data)
{
    __asm__ __volatile__("outw %w0, %w1" : : "a" (data), "Nd" (port));
}

void invlpg(void* m)
{
    /* Clobber memory to avoid optimizer re-ordering access before invlpg, which may cause nasty bugs. */
    __asm__ __volatile__ ( "invlpg (%0)" : : "b"(m) : "memory" );
}