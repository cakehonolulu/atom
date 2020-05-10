#define VGA_VIDEO_ADDRESS 0xb8000
#define VGA_MAXIMUM_ROWS 25
#define VGA_MAXIMUM_COLUMNS 80
#define VGA_WHITE_ON_BLACK 0x0f
#define VGA_RED_ON_WHITE 0xf4
#define VGA_SCREEN_CONTROL_REGISTER 0x3d4
#define VGA_SCREEN_DATA_REGISTER 0x3d5

void i386_setup_vga();
void vga_printk_at(char *message, int vga_column, int vga_row);
int vga_get_cursor_offset();
void vga_set_cursor_offset(int vga_offset);
int vga_print_char(char character, int vga_column, int vga_row, char vga_attributes);
int vga_get_offset(int vga_column, int vga_row) { return 2 * (vga_row * VGA_MAXIMUM_COLUMNS + vga_column); }
int vga_get_offset_row(int vga_offset) { return vga_offset / (2 * VGA_MAXIMUM_COLUMNS); }
int vga_get_offset_col(int vga_offset) { return (vga_offset - (vga_get_offset_row(vga_offset) * 2 * VGA_MAXIMUM_COLUMNS)) / 2; }
void vga_clear_screen();