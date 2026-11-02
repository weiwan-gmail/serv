# Proven logs

Captured on Ubuntu with Icarus 12.0, Verilator 5.020, FuseSoC 2.4.7,
`riscv64-unknown-elf-gcc` 13.2.0. These are real terminal transcripts, not
sketches.

| File | Command | What to look for |
|------|---------|------------------|
| [01-inspect.txt](01-inspect.txt) | `make toolchain-info` | tool versions; `verilator_tb` target |
| [02-build-firmware.txt](02-build-firmware.txt) | `make -C sw hello` | C → `sw/hello.hex` |
| [03-verilator-build.txt](03-verilator-build.txt) | start of `make test_verilator` | FuseSoC + `verilator` compile |
| [04-iverilog-hello.txt](04-iverilog-hello.txt) | `make test_icarus` | `Hello, SERV!` / `Test complete` |
| [05-verilator-hello.txt](05-verilator-hello.txt) | `make test_verilator` | documented demo PASS |
| [06-verilator-hello_uart.txt](06-verilator-hello_uart.txt) | `make test_verilator_asm` | official `Hi, I'm Servant!` |
