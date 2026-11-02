OUTPUT_ARCH( "riscv" )
ENTRY(_start)

SECTIONS
{
  . = 0x00000000;
  .text : { *(.text .text.*) }
  .rodata : { *(.rodata .rodata.*) }
  .data : { *(.data .data.*) }
  .bss : { *(.bss .bss.*) }
  _end = .;
  /* Default servant memsize is 8 KiB; stack grows down from the top. */
  . = 0x00002000;
  _stack = .;
}
