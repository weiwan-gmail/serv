/*
 * Minimal C hello for the Servant SoC.
 *
 * Prints "Hello, SERV!\n" on the bit-banged UART (GPIO 0x40000000), then
 * returns to crt0.S which writes 0x90000000 to $finish the simulation.
 *
 * SPDX-License-Identifier: ISC
 */

#define GPIO_ADDR 0x40000000

void uart_putc(int c);

static void uart_puts(const char *s)
{
	while (*s)
		uart_putc(*s++);
}

int main(void)
{
	/* UART idle is high; the Verilator TB waits for that before start bits. */
	*(volatile unsigned char *)GPIO_ADDR = 1;
	uart_puts("Hello, SERV!\n");
	return 0;
}
