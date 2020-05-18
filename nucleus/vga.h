#define VGA_VIDEO_ADDRESS 0xb8000
#define VGA_MAXIMUM_ROWS 25
#define VGA_MAXIMUM_COLUMNS 80

#define VGA_SCREEN_CONTROL_REGISTER 0x3d4
#define VGA_SCREEN_DATA_REGISTER 0x3d5

enum vga_color {
    VGA_COLOR_BLACK = 0,
    VGA_COLOR_BLUE = 1,
    VGA_COLOR_GREEN = 2,
    VGA_COLOR_CYAN = 3,
    VGA_COLOR_RED = 4,
    VGA_COLOR_MAGENTA = 5,
    VGA_COLOR_BROWN = 6,
    VGA_COLOR_LIGHT_GREY = 7,
    VGA_COLOR_DARK_GREY = 8,
    VGA_COLOR_LIGHT_BLUE = 9,
    VGA_COLOR_LIGHT_GREEN = 10,
    VGA_COLOR_LIGHT_CYAN = 11,
    VGA_COLOR_LIGHT_RED = 12,
    VGA_COLOR_LIGHT_MAGENTA = 13,
    VGA_COLOR_LIGHT_BROWN = 14,
    VGA_COLOR_WHITE = 15,
};

int vga_get_cursor_offset();
void vga_set_cursor_offset(int vga_offset);
int vga_print_char(char c, int vga_column, int vga_row, char vga_colour_attributes);
int vga_get_offset(int vga_column, int vga_row);
int vga_get_offset_row(int vga_offset);
int vga_get_offset_col(int vga_offset);
void vga_clear_screen();
void vga_printk_at(char *message, int vga_column, int vga_row);
void vga_printk(char *message);