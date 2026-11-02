# cmake-system — system Verilator (no Conan)

Optional dual-tree half. Commands and layout: **[`../CMAKE.md`](../CMAKE.md)**. Does **not** change FuseSoC / `Makefile` / `verif/`.

```bash
cmake -S cmake-system -B build-system -DCMAKE_BUILD_TYPE=Release
cmake --build build-system --target sim
ctest --test-dir build-system --output-on-failure
```

Linux evidence: [`PASS_EVIDENCE.md`](PASS_EVIDENCE.md). Windows MSVC: [`WINDOWS.md`](WINDOWS.md), `.\build_sim.ps1` (TB is `#if` guarded; engine is `verilator_bin.exe`).
