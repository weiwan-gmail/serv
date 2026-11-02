# cmake-conan — Conan 2 + local Verilator recipe

Optional dual-tree half. Same `sim_servant` as `cmake-system/` via [`../cmake/ServantSim.cmake`](../cmake/ServantSim.cmake). Commands: **[`../CMAKE.md`](../CMAKE.md)**.

Needs Conan 2 (`pip install conan`; proven **2.34.0**) and a system Verilator kit on Linux. The local recipe **packages the system kit** (does not rebuild Verilator from source).

```bash
export PATH="$HOME/.local/bin:$PATH"   # if pip --user
conan profile detect --force
cmake -S cmake-conan -B build-conan -DCMAKE_BUILD_TYPE=Release
cmake --build build-conan --target sim
ctest --test-dir build-conan --output-on-failure
```

If Conan is missing, use `cmake-system/` instead. `conan install` uses `--no-remote`.

Windows: [withlimon](https://github.com/withlimon/verilator-windows) **`verilator_bin.exe`**, `.\build_sim.ps1`. MSVC: `CheckCXXCompilerFlag` before `verilate()`, then strip `-fcoroutines*`.
