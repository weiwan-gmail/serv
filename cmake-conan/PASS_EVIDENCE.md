# cmake-conan PASS evidence (Linux Cursor VM)

Recorded **2026-11-02** on this Cloud Agent Linux VM (`cursor`, Ubuntu, x86_64). Same `sim_servant` as cmake-system via [`../cmake/ServantSim.cmake`](../cmake/ServantSim.cmake). FuseSoC / `Makefile` / `verif/` were **not** used and were **not** edited.

| Tool | Version |
|------|---------|
| CMake | 3.28.3 |
| g++ | 13.3.0 (PreferUnixGcc; `conan profile detect` guessed clang, provider used **auto-cmake → gcc 13**) |
| Verilator | local recipe `verilator/5.052` **packaged the system 5.020 kit** (did not rebuild from source) |
| Conan | **2.34.0** (`pip install --user conan`) |
| RISC-V GCC | `riscv64-unknown-elf-gcc` 13.2.0 |

Windows PC2023 (Conan 2.34 + withlimon `verilator_bin.exe`) is a **follow-up**: [`../cmake-system/WINDOWS.md`](../cmake-system/WINDOWS.md), [`WINDOWS_PASS_EVIDENCE.md`](WINDOWS_PASS_EVIDENCE.md).

## Configure

```bash
export PATH="$HOME/.local/bin:$PATH"
conan profile detect --force
cmake -S cmake-conan -B build-conan -DCMAKE_BUILD_TYPE=Release
```

```
======== Installing packages ========
-------- Installing package verilator/5.052 ...
Calling package()
package(): Packaged 1 '.cmake' file: verilator-config.cmake
...
Install finished successfully
-- ServSim: Conan package folder /home/ubuntu/.conan2/p/b/veril.../p
-- ServSim: VERILATOR_BIN=.../p/bin/verilator_bin
-- ServSim: VERILATOR_ROOT=.../p
-- Executing Verilator...
-- ServSim: primary firmware=/workspace/sw/hello.hex
-- Configuring done
```

`conan install` used `--no-remote` and in-tree `recipes/verilator`.

## sim / ctest

```bash
cmake --build build-conan --target sim
ctest --test-dir build-conan --output-on-failure
```

`--target sim`:

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

```
Test project /workspace/build-conan
    Start 1: sim_servant
1/2 Test #1: sim_servant ......................   Passed    0.01 sec
    Start 2: sim_servant_asm
2/2 Test #2: sim_servant_asm ..................   Passed    0.01 sec

100% tests passed, 0 tests failed out of 2
```
