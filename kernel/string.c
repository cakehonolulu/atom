void memcpy(char *src, char *dst, int bytes)
{
	int i = 0;
    for (i = 0; i < bytes; i++)
    {
        *(dst + i) = *(src + i);
    }
}