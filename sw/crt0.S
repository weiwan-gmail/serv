#define HALT_ADDR 0x90000000

	/*
	 * Bare-metal start for Servant C firmware.
	 * Stack is at the top of the default 8 KiB RAM (see link.ld).
	 * Writing HALT_ADDR ends the simulation (servile_mux $finish).
	 */
	.section .text
	.globl _start
_start:
	la	sp, _stack
	call	main
	li	t0, HALT_ADDR
	sw	zero, 0(t0)
1:	j	1b
