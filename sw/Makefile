# Make's default CC is the host compiler; do not use CC?=.
TOOLCHAIN_PREFIX ?= riscv64-unknown-elf-
CC = $(TOOLCHAIN_PREFIX)gcc
OBJCOPY = $(TOOLCHAIN_PREFIX)objcopy
MARCH?=rv32i_zicsr
CFLAGS?=-nostartfiles -nostdlib -ffreestanding -march=$(MARCH) -mabi=ilp32 -Os

%.elf: %.S link.ld
	$(CC) $(CFLAGS) -Tlink.ld -o$@ $<
%.bin: %.elf
	$(OBJCOPY) -O binary $< $@
%.hex: %.bin
	python3 makehex.py $< > $@

# C hello: crt0 + uart bitbang + main. Not matched by the %.S pattern above.
# Pad to 8 KiB / 4 so Icarus $readmemh does not warn about a short image.
hello.elf: crt0.S uart.S hello.c link.ld
	$(CC) $(CFLAGS) -Tlink.ld -o$@ crt0.S uart.S hello.c
hello.bin: hello.elf
	$(OBJCOPY) -O binary $< $@
hello.hex: hello.bin
	python3 makehex.py $< 2048 > $@

.PHONY: hello toolchain-info clean
hello: hello.hex

toolchain-info:
	@echo "TOOLCHAIN_PREFIX=$(TOOLCHAIN_PREFIX)"
	@echo "CC=$(CC)"
	@echo "MARCH=$(MARCH)"
	@command -v $(CC) >/dev/null && $(CC) --version | head -n 1 || echo "gcc not found"

clean:
	rm -f hello.elf hello.bin hello.hex
	rm -f blinky.elf blinky.bin hello_uart.elf hello_uart.bin
