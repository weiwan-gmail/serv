# Simulation helpers (this fork)

The documented green command is still **from the repository root**:

```bash
make test_verilator
```

That wraps the **upstream** FuseSoC target `verilator_tb` on Servant:

```bash
fusesoc --cores-root=. run --target=verilator_tb --build-root=sim/fusesoc-build \
  servant --uart_baudrate=57600 --timeout=200000000 --firmware=sw/hello.hex
```

| Path | Role |
|------|------|
| `rtl.f` | File list for the Icarus teaching path (`make test_icarus`) |
| `icarus/servant_tb_lite.v` | Same DUT as `bench/servant_tb.v`, without `vlog_tb_utils` |
| `fusesoc-build/` | Gitignored FuseSoC work root |

`bench/servant_tb.cpp` is the official Verilator driver (clock, UART decode, timeout). It was only extended so a timeout exits non-zero and a `$finish` prints `ALL TESTS PASSED.`

Optional CMake (same TB/RTL, no FuseSoC): [`../CMAKE.md`](../CMAKE.md).
