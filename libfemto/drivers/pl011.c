// See LICENSE for license details.

#include "femto.h"

#define UART01x_DR		0x00	/* Data read or written from the interface. */

#define UART01x_FR		0x18	/* Flag register (Read only). */
#define UART01x_FR_TXFF		0x020
#define UART01x_FR_RXFE		0x010
#define UART01x_FR_BUSY		0x008

static volatile uint32_t *uart;

static void pl011_init()
{
	uart = (uint8_t *)(void *)getauxval(PL011_UART0_CTRL_ADDR);
#if 0
	uint32_t uart_freq = getauxval(UART0_CLOCK_FREQ);
	uint32_t baud_rate = getauxval(UART0_BAUD_RATE);
	uint32_t divisor = uart_freq / (16 * baud_rate);
	uart[UART_LCR] = UART_LCR_DLAB;
	uart[UART_DLL] = divisor & 0xff;
	uart[UART_DLM] = (divisor >> 8) & 0xff;
	uart[UART_LCR] = UART_LCR_PODD | UART_LCR_8BIT;
#endif
}

static int pl011_getchar()
{
	while (uart[UART01x_FR] & UART01x_FR_RXFE);

	return uart[UART01x_DR];
}

static int pl011_putchar(int ch)
{
	while ((uart[UART01x_FR] & UART01x_FR_TXFF));
	uart[UART01x_DR] = ch & 0xff;
	//while ((uart[UART01x_FR] & UART01x_FR_BUSY));
	return 0;
}

console_device_t console_pl011 = {
	pl011_init,
	pl011_getchar,
	pl011_putchar
};
