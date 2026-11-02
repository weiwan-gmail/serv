# Windows CMake (PC2023 follow-up — copy-paste)

FuseSoC / `Makefile` / `verif/` are **unchanged**. This file is only for `cmake-system/` / `cmake-conan/` on Wei’s worker.

Linux is proven in [`PASS_EVIDENCE.md`](PASS_EVIDENCE.md). A PC2023 re-run is a **follow-up** (do not treat this file as a green Windows log).

## Machine notes

| Item | Value |
|------|--------|
| Worker workspace | `D:\CursorWorker` |
| Conan | **2.34** (cmake-conan tree only) |
| Verilator | **[withlimon/verilator-windows](https://github.com/withlimon/verilator-windows)** |
| Engine | **`verilator_bin.exe`** (PE32+). Never the extensionless Perl `verilator` (Explorer/CMD “Open with…” trap). |

## withlimon layout

Extract to a **short path without spaces** (withlimon’s example is `D:\verilator`):

```
D:\verilator\
  bin\verilator_bin.exe     PE32+ engine  ← CMake/PowerShell drive this
  bin\verilator.exe         same PE, renamed copy
  bin\verilator.bat         sets VERILATOR_ROOT, then verilator.exe
  bin\verilator             Perl driver, **no extension** — do not invoke
  include\
```

The withlimon tarball does **not** ship `verilator-config.cmake`. Shared helper `cmake/FindVerilatorKit.cmake` uses bundled `cmake/verilator-config.fallback.cmake` in that case.

MSYS2 unpack: `C:\msys64\mingw64\bin\verilator_bin.exe`. Do **not** run `C:\msys64\mingw64\share\verilator\bin\verilator_bin.exe` (Perl wrapper with a `.exe` suffix). CMake, `build_sim.ps1`, and the Conan recipe MZ-check `verilator_bin.exe`.

## POSIX / MSVC TB

`bench/servant_tb.cpp` is the existing FuseSoC Verilator driver. Host I/O is
`#if defined(_WIN32)` / `_MSC_VER` guarded:

| API | Linux gcc | Windows MSVC |
|-----|-----------|----------------|
| headers | `<unistd.h>` | `<io.h>` + `<windows.h>` — **no** `<unistd.h>` (C1083) |
| open/write/close | `open` / `write` / `close` | `_open` / `_write` / `_close` (do **not** `#define open`; that rewrites `VerilatedVcdC::open`) |
| dprintf | GNU `dprintf` replacement `tb_dprintf` | `vsnprintf` + `_write` |
| sleep | `sleep()` (unused in this TB) | `Sleep()` |

CMake MSVC: `CheckCXXCompilerFlag` then drop `-fcoroutines*`, plus `/bigobj` and `/Zc:__cplusplus`. Engine is still **`verilator_bin.exe`**.

## cmake-system

```bat
cd /d D:\CursorWorker\serv
cd cmake-system
powershell -File .\build_sim.ps1
```

## cmake-conan

```bat
cd /d D:\CursorWorker\serv\cmake-conan
conan profile detect --force
powershell -File .\build_sim.ps1
```

`conan install` uses `--no-remote`. RISC-V `gcc` is needed to rebuild `sw/hello.hex`; otherwise CMake falls back to committed `sw/hello_uart.hex`.
