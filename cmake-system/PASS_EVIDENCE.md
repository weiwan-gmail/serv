# cmake-system PASS evidence (Linux Cursor VM)

Recorded **2026-11-02** on this Cloud Agent Linux VM (`cursor`, Ubuntu, x86_64). Self-contained Servant Verilator sim (existing `bench/servant_tb.cpp` + `servant_sim` RTL). FuseSoC / `Makefile` / `verif/` were **not** used and were **not** edited.

| Tool | Version |
|------|---------|
| CMake | 3.28.3 |
| g++ | 13.3.0 (`PreferUnixGcc`) |
| Verilator | 5.020 (Debian 5.020-1), `verilator_bin` at `/bin/verilator_bin`, kit `/usr/share/verilator` |
| RISC-V GCC | `riscv64-unknown-elf-gcc` 13.2.0 (builds `sw/hello.hex`) |
| Conan | not used in this tree |

Windows PC2023 (withlimon `verilator_bin.exe`, worker `D:\CursorWorker`) is a **follow-up**: [`WINDOWS.md`](WINDOWS.md), [`WINDOWS_PASS_EVIDENCE.md`](WINDOWS_PASS_EVIDENCE.md).

Make path spot-check (unchanged): `make test_icarus` still prints `Hello, SERV!` / `Test complete` / `ALL TESTS PASSED.`

## Commands

```bash
cmake -S cmake-system -B build-system -DCMAKE_BUILD_TYPE=Release
cmake --build build-system --target sim
ctest --test-dir build-system --output-on-failure
```

This VM used `-G Ninja` in addition; the same targets apply to the default generator.

## Configure

```
-- PreferUnixGcc: CMAKE_CXX_COMPILER=/usr/bin/g++
-- ServSim: VERILATOR_BIN=/bin/verilator_bin
-- ServSim: VERILATOR_ROOT=/usr/share/verilator
-- Executing Verilator...
-- ServSim: primary firmware=/workspace/sw/hello.hex
-- ServSim: primary expect=Hello, SERV!
-- Configuring done
```

## `--target sim`

```
Loading RAM from /workspace/sw/hello.hex
Hello, SERV!
Test complete
- /workspace/servile/servile_mux.v:87: Verilog $finish
SIM DONE after 44423 clock cycles
verilator_exit=0
ALL TESTS PASSED.
-- ExpectPass: PASS (Hello, SERV!)
```

## ctest

```
Test project /workspace/build-system
    Start 1: sim_servant
1/2 Test #1: sim_servant ......................   Passed    0.01 sec
    Start 2: sim_servant_asm
2/2 Test #2: sim_servant_asm ..................   Passed    0.01 sec

100% tests passed, 0 tests failed out of 2
```

`sim_servant_asm` (committed `sw/hello_uart.hex`):

```
Loading RAM from /workspace/sw/hello_uart.hex
Hi, I'm Servant!
Test complete
- /workspace/servile/servile_mux.v:87: Verilog $finish
SIM DONE after 53739 clock cycles
verilator_exit=0
ALL TESTS PASSED.
```
