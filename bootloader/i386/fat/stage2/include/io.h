#include <stdint.h>

/* Function definitions */

// INx
uint8_t inb(uint16_t m_address);
uint16_t inw(uint16_t m_address);
uint32_t inl(uint16_t m_address);

// OUTx
void outb(uint16_t m_address, uint8_t m_data);
void outw(uint16_t m_address, uint16_t m_data);
void outl(uint16_t m_address, uint32_t m_data);
