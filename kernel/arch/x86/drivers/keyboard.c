#include "isr.h"

#define BACKSPACE 0x0E
#define ENTER 0x1C

static char key_buffer[256];
#define SC_MAX 57
const char *sc_name[] = { "ERROR", "Esc", "1", "2", "3", "4", "5", "6", 
    "7", "8", "9", "0", "-", "=", "Backspace", "Tab", "q", "w", "e", 
        "r", "t", "y", "u", "i", "o", "p", "[", "]", "Enter", "Lctrl", 
        "a", "s", "d", "f", "g", "h", "j", "k", "l", ";", "'", "`", 
        "LShift", "\\", "z", "x", "c", "v", "b", "n", "m", ",", ".", 
        "/", "RShift", "Keypad *", "LAlt", "Spacebar"};
const char sc_ascii[] = { '?', '?', '1', '2', '3', '4', '5', '6',     
    '7', '8', '9', '0', '-', '=', '?', '?', 'q', 'w', 'e', 'r', 't', 'y', 
        'u', 'i', 'o', 'p', '[', ']', '?', '?', 'a', 's', 'd', 'f', 'g', 
        'h', 'j', 'k', 'l', ';', '\'', '`', '?', '\\', 'z', 'x', 'c', 'v', 
        'b', 'n', 'm', ',', '.', '/', '?', '?', '?', ' '};

static void keyboard_callback(registers_t regs) {
    /* The PIC leaves us the scancode in port 0x60 */
    unsigned char scancode = inb(0x60);
    
    if (scancode > SC_MAX) return;
    if (scancode == BACKSPACE) {
        backspace(key_buffer);
        delete_last();
    } else if (scancode == ENTER) {
        printk("\n");
        user_input(key_buffer); /* kernel-controlled function */
        key_buffer[0] = '\0';
    } else {
        char letter = sc_ascii[(int)scancode];
        /* Remember that kprint only accepts char[] */
        char str[2] = {letter, '\0'};
        append(key_buffer, letter);
        printk(str);
    }
}

void init_keyboard()
{
    printk("\n> ");
    register_interrupt_handler(IRQ1, keyboard_callback);
}