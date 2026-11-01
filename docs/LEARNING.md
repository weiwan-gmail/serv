# SERV learning index / 学习入口

Primary tutorial (Chinese, for Wei): **[TUTORIAL_zh.md](TUTORIAL_zh.md)**
Shorter English summary: **[TUTORIAL.md](TUTORIAL.md)**
Proven command logs: **[logs/](logs/)**

This fork (`weiwan-gmail/serv`, work on **develop**, parent
[olofk/serv](https://github.com/olofk/serv)) keeps the original FuseSoC /
Servant / Zephyr / RISCOF flows and wraps the **already-present**
`verilator_tb` target so a modern Linux box has one green command. CPU RTL
under `rtl/` is not rewritten.

**Why hex + Verilator, not a new C ISS:** Servant already loads a Verilog hex
image with `$readmemh`, bit-bangs UART on GPIO `q`, and `$finish`es on a
store to `0x90000000`. `bench/servant_tb.cpp` only toggles `wb_clk` /
`wb_rst` and decodes UART. That *is* C firmware co-sim for this core. A
separate instruction-set simulator would be a second CPU.

Zephyr hello (prebuilt `sw/zephyr_hello.hex`) is also C, but it needs a
Ctrl-C stop and is not a self-checking PASS. The documented demo is a small
bare-metal C `hello` that uses the same UART + halt protocol as
`sw/hello_uart.S`.

## Exact commands (reproduced in `docs/logs/`)

Install tools (Ubuntu/Debian):

```bash
sudo apt-get install -y iverilog verilator gcc-riscv64-unknown-elf python3 python3-pip build-essential
pip3 install --user fusesoc
export PATH="$HOME/.local/bin:$PATH"
make toolchain-info
```

### 1) Small C hello (documented demo)

```bash
make test_verilator
# expect: Hello, SERV! / Test complete / SIM DONE / verilator_exit=0 / ALL TESTS PASSED.
```

Icarus (same hex, no FuseSoC `vlog_tb_utils` library):

```bash
make test_icarus
# expect: Hello, SERV! / Test complete / ALL TESTS PASSED.
```

### 2) Official assembly image (unchanged hex)

```bash
make test_verilator_asm
# expect: Hi, I'm Servant! / Test complete / ALL TESTS PASSED.
```

Upstream FuseSoC, still valid:

```bash
fusesoc --cores-root=. run --target=verilator_tb servant \
  --uart_baudrate=57600 --firmware=$PWD/sw/hello.hex --timeout=200000000
fusesoc --cores-root=. run --target=lint serv
```

## How to read PASS / FAIL

| Check | Meaning |
|-------|---------|
| stdout `Hello, SERV!` | C `main` bit-banged UART on GPIO `0x40000000` |
| stdout `Test complete` | store to `0x90000000` hit `servile_mux` `$finish` |
| `SIM DONE after N clock cycles` | Verilator saw `$finish`, not timeout |
| `verilator_exit=0` / `ALL TESTS PASSED.` | Makefile grepped the log |
| `TIMEOUT` / `verilator_exit=2` | no `$finish` before `--timeout` (blinky loops) |

## Ladder

This is the last RISC-V fork on the ladder:

**tinyriscv → picorv32 → FemtoRV (`learn-fpga`) → darkriscv → SERV**

Optional next (Wei's `rtl-learning-plan`): **PWM P6** and/or **Track B DSP**.

See the last section of [TUTORIAL_zh.md](TUTORIAL_zh.md).
