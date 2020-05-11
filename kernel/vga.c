#include <stddef.h>
#include "vga.h"

char vga_default_colour = 0;

// Code snippet taken from osdev.org Wiki
unsigned char vga_set_color(enum vga_color vga_foreground_colour, enum vga_color vga_background_colour) 
{
    return vga_foreground_colour | vga_background_colour << 4;
}

void i386_setup_vga()
{
    vga_default_colour = vga_set_color(VGA_COLOR_WHITE, VGA_COLOR_BLACK);
    int initial_vga_offset = vga_get_cursor_offset();
    int initial_vga_row = vga_get_offset_row(initial_vga_offset);
    initial_vga_row = vga_get_offset_row(initial_vga_offset);
    // Add 1 to the initial vga row so that it jumps to a new line right after we give control to the kernel
    initial_vga_offset = vga_get_offset(0, initial_vga_row + 1);
    vga_set_cursor_offset(initial_vga_offset);
}

/**
 * Using VGA, this is a function that prints characters on screen
 * given a column, a row and an array of characters.
 * If the column and/or row are negative, use the current VGA offset.
 */
void vga_printk_at(char *message, int vga_column, int vga_row)
{
    // Set vga offset to 0
    int vga_offset;
    if (vga_column >= 0 && vga_row >= 0)
    {
        vga_offset = vga_get_offset(vga_column, vga_row);
    }
        else
    {
        vga_offset = vga_get_cursor_offset();
        vga_row = vga_get_offset_row(vga_offset);
        vga_column = vga_get_offset_col(vga_offset);
    }

    // Simple while loop that iterates through the entire character array and prints letter by letter
    // and stops when it finds a null character
    int i = 0;
    while (message[i] != 0)
    {
        vga_offset = vga_print_char(message[i++], vga_column, vga_row, vga_default_colour);
        // Find VGA location for the next character of the array
        vga_row = vga_get_offset_row(vga_offset);
        vga_column = vga_get_offset_col(vga_offset);
    }
}

void vga_printk(char *message)
{
    vga_printk_at(message, -1, -1);
}

void vga_printkok(char *message)
{
    vga_printk_at("[ ", -1, -1);
    vga_default_colour = vga_set_color(VGA_COLOR_GREEN, VGA_COLOR_BLACK);
    vga_printk_at("OK", -1, -1);
    vga_default_colour = vga_set_color(VGA_COLOR_WHITE, VGA_COLOR_BLACK);
    vga_printk_at(" ] ", -1, -1);
    vga_printk_at(message, -1, -1);
    vga_printk_at("\n", -1, -1);
}

void vga_printkfail(char *message)
{
    vga_printk_at("[", -1, -1);
    vga_default_colour = vga_set_color(VGA_COLOR_RED, VGA_COLOR_BLACK);
    vga_printk_at("FAIL", -1, -1);
    vga_default_colour = vga_set_color(VGA_COLOR_WHITE, VGA_COLOR_BLACK);
    vga_printk_at("] ", -1, -1);
    vga_printk_at(message, -1, -1);
    vga_printk_at("\n", -1, -1);
}

int vga_print_char(char c, int vga_column, int vga_row, char vga_colour_attributes)
{
    unsigned char *vga_video_memory = (unsigned char*) VGA_VIDEO_ADDRESS;

    if (!vga_colour_attributes)
    {
        vga_colour_attributes = vga_set_color(VGA_COLOR_WHITE, VGA_COLOR_BLACK);
    }

    if (vga_column >= VGA_MAXIMUM_COLUMNS || vga_row >= VGA_MAXIMUM_ROWS)
    {
        vga_video_memory[2*(VGA_MAXIMUM_COLUMNS)*(VGA_MAXIMUM_ROWS)-2] = 'E';
        vga_video_memory[2*(VGA_MAXIMUM_COLUMNS)*(VGA_MAXIMUM_ROWS)-1] = vga_set_color(VGA_COLOR_RED, VGA_COLOR_WHITE);
        return vga_get_offset(vga_column, vga_row);
    }

    int vga_offset;

    if (vga_column >= 0 && vga_row >= 0)
    {
        vga_offset = vga_get_offset(vga_column, vga_row);
    }
        else
    {
        vga_offset = vga_get_cursor_offset();
    }

    if (c == '\n') {
        vga_row = vga_get_offset_row(vga_offset);
        vga_offset = vga_get_offset(0, vga_row+1);
    } else {
        vga_video_memory[vga_offset] = c;
        vga_video_memory[vga_offset+1] = vga_colour_attributes;
        vga_offset += 2;
    }

    if (vga_offset >= VGA_MAXIMUM_ROWS * VGA_MAXIMUM_COLUMNS * 2)
    {
        int i;
        for (i = 1; i < VGA_MAXIMUM_ROWS; i++)
        {
            memcpy(vga_get_offset(0, i) + VGA_VIDEO_ADDRESS, vga_get_offset(0, i-1) + VGA_VIDEO_ADDRESS, VGA_MAXIMUM_COLUMNS * 2);
        }

        char *last_line = vga_get_offset(0, VGA_MAXIMUM_ROWS-1) + VGA_VIDEO_ADDRESS;

        for (i = 0; i < VGA_MAXIMUM_COLUMNS * 2; i++)
        {
            last_line[i] = 0;
        }

        vga_offset -= 2 * VGA_MAXIMUM_COLUMNS;
    }

    vga_set_cursor_offset(vga_offset);
    return vga_offset;
}

int vga_get_cursor_offset()
{
    outb(VGA_SCREEN_CONTROL_REGISTER, 14);
    int vga_offset = inb(VGA_SCREEN_DATA_REGISTER) << 8;
    outb(VGA_SCREEN_CONTROL_REGISTER, 15);
    vga_offset += inb(VGA_SCREEN_DATA_REGISTER);
    return vga_offset * 2;
}

void vga_set_cursor_offset(int vga_offset)
{
    vga_offset /= 2;
    outb(VGA_SCREEN_CONTROL_REGISTER, 14);
    outb(VGA_SCREEN_DATA_REGISTER, (unsigned char)(vga_offset >> 8));
    outb(VGA_SCREEN_CONTROL_REGISTER, 15);
    outb(VGA_SCREEN_DATA_REGISTER, (unsigned char)(vga_offset & 0xff));
}

void vga_clear_screen()
{
    int vga_screen_size = VGA_MAXIMUM_COLUMNS * VGA_MAXIMUM_ROWS;
    int i;
    char *vga_video_memory = VGA_VIDEO_ADDRESS;

    for (i = 0; i < vga_screen_size; i++)
    {
        vga_video_memory[i*2] = ' ';
        vga_video_memory[i*2+1] = vga_set_color(VGA_COLOR_WHITE, VGA_COLOR_BLACK);
    }

    vga_set_cursor_offset(vga_get_offset(0, 0));
}


char *convert(unsigned int num, int base) 
{ 
    static char Representation[]= "0123456789ABCDEF";
    static char buffer[50]; 
    char *ptr; 

    ptr = &buffer[49]; 
    *ptr = '\0'; 

    do 
    { 
        *--ptr = Representation[num%base]; 
        num /= base; 
    } while(num != 0); 

    return(ptr); 
}

void vga_printkhex(unsigned int num)
{
    const char* message = convert(num, 16);
    vga_printk("0x");
    vga_printk(message);
}

int vga_get_offset(int vga_column, int vga_row)
{
    return 2 * (vga_row * VGA_MAXIMUM_COLUMNS + vga_column);
}

int vga_get_offset_row(int vga_offset)
{
    return vga_offset / (2 * VGA_MAXIMUM_COLUMNS);
}

int vga_get_offset_col(int vga_offset)
{
    return (vga_offset - (vga_get_offset_row(vga_offset)*2*VGA_MAXIMUM_COLUMNS))/2;
}