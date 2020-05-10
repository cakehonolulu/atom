#include <stddef.h>
#include "vga.h"

void i386_setup_vga()
{
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
    int vga_offset = 0;
    // Check if positions are valid, else, get them from the current vga position
    if (vga_column >= 0 && vga_row >= 0)
    {
        vga_offset = vga_get_offset(vga_column, vga_row);
    } else {
        vga_offset = vga_get_cursor_offset();
        vga_row = vga_get_offset_row(vga_offset);
        vga_column = vga_get_offset_col(vga_offset);
    }

    // Simple while loop that iterates through the entire character array and prints letter by letter
    int i = 0;
    while (message[i] != 0)
    {
        vga_offset = vga_print_char(message[i++], vga_column, vga_row, VGA_WHITE_ON_BLACK);
        // Find VGA location for the next character of the array
        vga_row = vga_get_offset_row(vga_offset);
        vga_column = vga_get_offset_col(vga_offset);
    }
}

void vga_printk(char *message)
{
    vga_printk_at(message, -1, -1);
}

/**
 * If 'col' and 'row' are negative, we will print at current cursor location
 * If 'attr' is zero it will use 'white on black' as default
 * Returns the offset of the next character
 * Sets the video cursor to the returned offset
 */
int vga_print_char(char character, int vga_column, int vga_row, char vga_attributes)
{
    unsigned char *vga_video_location = (unsigned char*) VGA_VIDEO_ADDRESS;

    if (!vga_attributes)
    {
        vga_attributes = VGA_WHITE_ON_BLACK;
    }

    /* Error control: print a red 'E' if the coords aren't right */
    if (vga_column >= VGA_MAX_COLS || vga_row >= VGA_WHITE_ON_BLACK)
    {
        vga_video_location[2 * (VGA_MAX_COLS) * (VGA_WHITE_ON_BLACK) - 2] = 'E';
        vga_video_location[2 * (VGA_MAX_COLS) * (VGA_WHITE_ON_BLACK) - 1] = VGA_RED_ON_WHITE;
        return vga_get_offset(vga_column, vga_row);
    }

    int vga_offset;
    if (vga_column >= 0 && vga_row >= 0) vga_offset = vga_get_offset(vga_column, vga_row);
    else vga_offset = vga_get_cursor_offset();

    if (character == '\n')
    {
        vga_row = vga_get_offset_row(vga_offset);
        vga_offset = vga_get_offset(0, vga_row+1);
    } else {
        vga_video_location[vga_offset] = character;
        vga_video_location[vga_offset + 1] = vga_attributes;
        vga_offset += 2;
    }
    vga_set_cursor_offset(vga_offset);
    return vga_offset;
}

int vga_get_cursor_offset()
{
    /* Use the VGA ports to get the current cursor position
     * 1. Ask for high byte of the cursor offset (data 14)
     * 2. Ask for low byte (data 15)
     */
    outb(VGA_SCREEN_CONTROL_REGISTER, 14);
    int vga_offset = inb(VGA_SCREEN_DATA_REGISTER) << 8; /* High byte: << 8 */
    outb(VGA_SCREEN_CONTROL_REGISTER, 15);
    vga_offset += inb(VGA_SCREEN_DATA_REGISTER);
    return vga_offset * 2; /* Position * size of character cell */
}

void vga_set_cursor_offset(int vga_offset)
{
    /* Similar to vga_get_cursor_offset, but instead of reading we write data */
    vga_offset /= 2;
    outb(VGA_SCREEN_CONTROL_REGISTER, 14);
    outb(VGA_SCREEN_DATA_REGISTER, (unsigned char) (vga_offset >> 8));
    outb(VGA_SCREEN_CONTROL_REGISTER, 15);
    outb(VGA_SCREEN_DATA_REGISTER, (unsigned char) (vga_offset & 0xff));
}

void vga_clear_screen()
{
    int screen_size = VGA_MAX_COLS * VGA_WHITE_ON_BLACK;
    int i;
    char *screen = VGA_VIDEO_ADDRESS;

    for (i = 0; i < screen_size; i++)
    {
        screen[i*2] = ' ';
        screen[i*2 + 1] = VGA_WHITE_ON_BLACK;
    }
    vga_set_cursor_offset(vga_get_offset(0, 0));
}
