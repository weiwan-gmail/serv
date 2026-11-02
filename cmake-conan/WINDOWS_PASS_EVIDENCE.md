# cmake-conan Windows PASS evidence

Linux gcc is proven in [`PASS_EVIDENCE.md`](PASS_EVIDENCE.md). Same
`bench/servant_tb.cpp` MSVC guards as cmake-system (C1083 `unistd.h` fixed
in source). Full PC2023 `--target sim` (Conan 2.34 + withlimon
`verilator_bin.exe`) remains a follow-up: [`../cmake-system/WINDOWS.md`](../cmake-system/WINDOWS.md).

```bat
cd /d D:\CursorWorker\serv\cmake-conan
powershell -File .\build_sim.ps1
```
