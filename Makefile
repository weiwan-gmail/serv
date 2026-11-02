# Teaching / learning path for this SERV fork.
# Upstream FPGA / FuseSoC / Zephyr / RISCOF flows are unchanged.
#
#   make test_verilator   # documented green command (C hello)
#   make test_icarus      # same hex on Icarus (no FuseSoC cores library)
#   make test_verilator_asm  # official sw/hello_uart.S image

SERV      := $(abspath .)
# pip install --user fusesoc lands here on Ubuntu.
export PATH := $(HOME)/.local/bin:$(PATH)
FUSESOC   ?= fusesoc
IVERILOG  ?= iverilog
VVP       ?= vvp
VERILATOR ?= verilator

BUILD_ROOT := $(SERV)/sim/fusesoc-build
ICARUS_DIR := $(SERV)/sim/icarus
LOG_DIR    := $(SERV)/sim/logs

UART_BAUD ?= 57600
# servant_tb.cpp compares this to main_time (≈ ns). 200 ms of sim time.
TIMEOUT   ?= 200000000

FIRMWARE_C   := $(SERV)/sw/hello.hex
FIRMWARE_ASM := $(SERV)/sw/hello_uart.hex
EXPECT_C     := Hello, SERV!
EXPECT_ASM   := Hi, I'm Servant!

FUSESOC_RUN = $(FUSESOC) --cores-root=$(SERV) run \
	--target=verilator_tb --build-root=$(BUILD_ROOT) servant \
	--uart_baudrate=$(UART_BAUD) --timeout=$(TIMEOUT)

.PHONY: all toolchain-info hello test_verilator test_verilator_asm \
	test_icarus test_icarus_asm lint clean

all: test_verilator

toolchain-info:
	$(MAKE) -C sw toolchain-info
	@echo -n "fusesoc "; command -v $(FUSESOC) >/dev/null && $(FUSESOC) --version || echo "not found"
	@command -v $(VERILATOR) >/dev/null && $(VERILATOR) --version || echo "verilator not found"
	@command -v $(IVERILOG) >/dev/null && $(IVERILOG) -V 2>&1 | head -n 1 || echo "iverilog not found"

hello:
	$(MAKE) -C sw hello

test_verilator: hello
	@mkdir -p $(LOG_DIR) $(dir $(BUILD_ROOT))
	$(FUSESOC_RUN) --firmware=$(FIRMWARE_C) 2>&1 | tee $(LOG_DIR)/verilator-hello.log
	@grep -F -q "$(EXPECT_C)" $(LOG_DIR)/verilator-hello.log
	@grep -q "Test complete" $(LOG_DIR)/verilator-hello.log
	@grep -q "verilator_exit=0" $(LOG_DIR)/verilator-hello.log
	@grep -q "ALL TESTS PASSED." $(LOG_DIR)/verilator-hello.log
	@echo "ALL TESTS PASSED."

test_verilator_asm:
	@mkdir -p $(LOG_DIR) $(dir $(BUILD_ROOT))
	$(FUSESOC_RUN) --firmware=$(FIRMWARE_ASM) 2>&1 | tee $(LOG_DIR)/verilator-hello_uart.log
	@grep -F -q "$(EXPECT_ASM)" $(LOG_DIR)/verilator-hello_uart.log
	@grep -q "Test complete" $(LOG_DIR)/verilator-hello_uart.log
	@grep -q "verilator_exit=0" $(LOG_DIR)/verilator-hello_uart.log
	@grep -q "ALL TESTS PASSED." $(LOG_DIR)/verilator-hello_uart.log
	@echo "ALL TESTS PASSED."

$(ICARUS_DIR)/servant_tb.vvp: sim/rtl.f sim/icarus/servant_tb_lite.v bench/servant_sim.v bench/uart_decoder.v
	@mkdir -p $(ICARUS_DIR) $(LOG_DIR)
	$(IVERILOG) -o $@ -c sim/rtl.f

test_icarus: hello $(ICARUS_DIR)/servant_tb.vvp
	@mkdir -p $(LOG_DIR)
	$(VVP) $(ICARUS_DIR)/servant_tb.vvp +firmware=$(FIRMWARE_C) 2>&1 | tee $(LOG_DIR)/icarus-hello.log
	@grep -F -q "$(EXPECT_C)" $(LOG_DIR)/icarus-hello.log
	@grep -q "Test complete" $(LOG_DIR)/icarus-hello.log
	@echo "ALL TESTS PASSED."

test_icarus_asm: $(ICARUS_DIR)/servant_tb.vvp
	@mkdir -p $(LOG_DIR)
	$(VVP) $(ICARUS_DIR)/servant_tb.vvp +firmware=$(FIRMWARE_ASM) 2>&1 | tee $(LOG_DIR)/icarus-hello_uart.log
	@grep -F -q "$(EXPECT_ASM)" $(LOG_DIR)/icarus-hello_uart.log
	@grep -q "Test complete" $(LOG_DIR)/icarus-hello_uart.log
	@echo "ALL TESTS PASSED."

lint:
	$(FUSESOC) --cores-root=$(SERV) run --target=lint --build-root=$(BUILD_ROOT) serv
	$(FUSESOC) --cores-root=$(SERV) run --target=lint --build-root=$(BUILD_ROOT) servant

clean:
	$(MAKE) -C sw clean
	rm -rf $(BUILD_ROOT) $(LOG_DIR) $(ICARUS_DIR)/servant_tb.vvp
	rm -f fusesoc.conf
