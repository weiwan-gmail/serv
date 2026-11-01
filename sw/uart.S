#define GPIO_ADDR 0x40000000

	/*
	 * Bit-banged UART TX on Servant's 1-bit GPIO (q).
	 * Same timing as hello_uart.S: ~57600 baud at 16 MHz SERV.
	 * a0 = character (low 8 bits). Caller must idle the line high first.
	 */
	.section .text
	.globl uart_putc
uart_putc:
	li	t1, GPIO_ADDR
	andi	t0, a0, 0xff
	ori	t0, t0, 0x100
	slli	t0, t0, 1
1:	sb	t0, 0(t1)
	srli	t0, t0, 1
	nop
	nop
	bnez	t0, 1b
	ret
