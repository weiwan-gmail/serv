# cmake-system Windows PASS evidence

Linux gcc is proven in [`PASS_EVIDENCE.md`](PASS_EVIDENCE.md).

## MSVC TB compile (this PR)

PC2023 `develop` tip `60c2088` failed `--target sim` with:

```
D:\CursorWorker\serv\bench\servant_tb.cpp(6,10): error C1083:
Cannot open include file: "unistd.h": No such file or directory
```

`bench/servant_tb.cpp` now skips `<unistd.h>` under `#if defined(_WIN32)` /
`_MSC_VER` and uses `_open` / `_write` / `_close` / `tb_dprintf` / `Sleep`.
CMake MSVC flags: `/bigobj` `/Zc:__cplusplus`, plus the existing
`-fcoroutines*` strip. Engine remains **`verilator_bin.exe`** (never
extensionless Perl `verilator`).

This Cloud Agent VM has no `cl.exe` and no withlimon kit, so a full
`cmake --build --target sim` MSVC log is still a PC2023 follow-up. The
MSVC `#if` helpers were syntax-checked here with `g++ -D_WIN32
-D_MSC_VER=1930` against stub `_open`/`Sleep` declarations (not a
substitute for `cl.exe`). On PC2023 (MSVC +
`D:\verilator\bin\verilator_bin.exe`):

```bat
cd /d D:\CursorWorker\serv
cd cmake-system
powershell -File .\build_sim.ps1
```

Configure must print `ServSim: VERILATOR_BIN=...\verilator_bin.exe` (MZ PE).
`--target sim` must compile `servant_tb.cpp` **without C1083**. UART markers
are the same as Linux: `Hello, SERV!` / `Test complete` / `verilator_exit=0`
/ `ALL TESTS PASSED.`

Notes: [`WINDOWS.md`](WINDOWS.md).
