# Thin Servant Verilator sim used by cmake-system/ and cmake-conan/.
# Reuses existing RTL + bench/servant_tb.cpp (FuseSoC verilator_tb sources).
# Does not call FuseSoC. Does not copy RTL.

include_guard(GLOBAL)
include("${CMAKE_CURRENT_LIST_DIR}/FindVerilatorKit.cmake")

set(SERV_UART_BAUD 57600)
set(SERV_TIMEOUT 200000000)

# FuseSoC servant.core verilator_tb filesets: core + servile + soc + TB.
# Same as sim/rtl.f minus the Icarus-only lite TB / uart_decoder.
set(SERV_V_SOURCES
  "${SERV_REPO_ROOT}/data/verilator_waiver.vlt"
  "${SERV_REPO_ROOT}/rtl/serv_bufreg.v"
  "${SERV_REPO_ROOT}/rtl/serv_bufreg2.v"
  "${SERV_REPO_ROOT}/rtl/serv_alu.v"
  "${SERV_REPO_ROOT}/rtl/serv_csr.v"
  "${SERV_REPO_ROOT}/rtl/serv_ctrl.v"
  "${SERV_REPO_ROOT}/rtl/serv_decode.v"
  "${SERV_REPO_ROOT}/rtl/serv_immdec.v"
  "${SERV_REPO_ROOT}/rtl/serv_mem_if.v"
  "${SERV_REPO_ROOT}/rtl/serv_rf_if.v"
  "${SERV_REPO_ROOT}/rtl/serv_rf_ram_if.v"
  "${SERV_REPO_ROOT}/rtl/serv_rf_ram.v"
  "${SERV_REPO_ROOT}/rtl/serv_state.v"
  "${SERV_REPO_ROOT}/rtl/serv_debug.v"
  "${SERV_REPO_ROOT}/rtl/serv_top.v"
  "${SERV_REPO_ROOT}/rtl/serv_rf_top.v"
  "${SERV_REPO_ROOT}/rtl/serv_aligner.v"
  "${SERV_REPO_ROOT}/rtl/serv_compdec.v"
  "${SERV_REPO_ROOT}/servile/servile_rf_mem_if.v"
  "${SERV_REPO_ROOT}/servile/servile_mux.v"
  "${SERV_REPO_ROOT}/servile/servile_arbiter.v"
  "${SERV_REPO_ROOT}/servile/servile.v"
  "${SERV_REPO_ROOT}/servant/servant_timer.v"
  "${SERV_REPO_ROOT}/servant/servant_gpio.v"
  "${SERV_REPO_ROOT}/servant/servant_mux.v"
  "${SERV_REPO_ROOT}/servant/servant_ram.v"
  "${SERV_REPO_ROOT}/servant/servant.v"
  "${SERV_REPO_ROOT}/bench/servant_sim.v"
)

function(serv_add_hello_hex)
  set(_hex "${SERV_REPO_ROOT}/sw/hello.hex")
  find_program(SERV_RISCV_GCC NAMES riscv64-unknown-elf-gcc)
  find_program(SERV_MAKE NAMES gmake make)
  if(NOT SERV_RISCV_GCC)
    message(WARNING
      "riscv64-unknown-elf-gcc not found; C hello hex will not be rebuilt. "
      "sim falls back to committed sw/hello_uart.hex")
    set(SERV_HELLO_HEX "" PARENT_SCOPE)
    return()
  endif()
  if(NOT SERV_MAKE)
    message(FATAL_ERROR "make not found (needed to run sw/Makefile hello)")
  endif()
  add_custom_command(
    OUTPUT "${_hex}"
    COMMAND "${SERV_MAKE}" hello
    WORKING_DIRECTORY "${SERV_REPO_ROOT}/sw"
    DEPENDS
      "${SERV_REPO_ROOT}/sw/hello.c"
      "${SERV_REPO_ROOT}/sw/crt0.S"
      "${SERV_REPO_ROOT}/sw/uart.S"
      "${SERV_REPO_ROOT}/sw/link.ld"
      "${SERV_REPO_ROOT}/sw/makehex.py"
      "${SERV_REPO_ROOT}/sw/Makefile"
    COMMENT "Build sw/hello.hex (bare-metal C UART demo)"
    VERBATIM)
  add_custom_target(hello_hex DEPENDS "${_hex}")
  set(SERV_HELLO_HEX "${_hex}" PARENT_SCOPE)
endfunction()

function(serv_add_sim_exe name)
  # PREFIX Vservant_sim matches bench/servant_tb.cpp #include "Vservant_sim.h".
  # TRACE is required: the existing TB includes verilated_vcd_c.h.
  # sc_time_stamp is already defined in that TB — do not link the stub.
  add_executable(${name} "${SERV_REPO_ROOT}/bench/servant_tb.cpp")
  target_compile_features(${name} PRIVATE cxx_std_17)

  include(CheckCXXCompilerFlag)
  verilate(${name}
    TRACE
    PREFIX Vservant_sim
    TOP_MODULE servant_sim
    SOURCES ${SERV_V_SOURCES}
    VERILATOR_ARGS
      -Wno-fatal --timescale 1ns/1ps
  )
  serv_strip_msvc_gcc_flags(${name})
endfunction()

function(serv_add_pass_test name exe firmware expect)
  add_test(NAME ${name}
    COMMAND ${CMAKE_COMMAND}
            "-DEXE=$<TARGET_FILE:${exe}>"
            "-DFIRMWARE=${firmware}"
            "-DEXPECT=${expect}"
            "-DUART_BAUDRATE=${SERV_UART_BAUD}"
            "-DTIMEOUT=${SERV_TIMEOUT}"
            -P ${SERV_CMAKE_DIR}/ExpectPass.cmake)
endfunction()

function(serv_sim_setup)
  if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
    set(CMAKE_BUILD_TYPE Release CACHE STRING "Build type" FORCE)
  endif()
  set(CMAKE_CXX_STANDARD 17)
  set(CMAKE_CXX_STANDARD_REQUIRED ON)

  serv_find_verilator()
  include(CheckCXXCompilerFlag)

  foreach(_s IN LISTS SERV_V_SOURCES)
    if(NOT EXISTS "${_s}")
      message(FATAL_ERROR "ServSim: missing source ${_s}")
    endif()
  endforeach()
  if(NOT EXISTS "${SERV_REPO_ROOT}/bench/servant_tb.cpp")
    message(FATAL_ERROR "ServSim: missing bench/servant_tb.cpp")
  endif()

  serv_add_sim_exe(sim_servant)
  serv_add_hello_hex()

  set(_asm_hex "${SERV_REPO_ROOT}/sw/hello_uart.hex")
  if(NOT EXISTS "${_asm_hex}")
    message(FATAL_ERROR "ServSim: committed ${_asm_hex} missing")
  endif()

  if(SERV_HELLO_HEX)
    set(_sim_fw "${SERV_HELLO_HEX}")
    set(_sim_expect "Hello, SERV!")
    add_dependencies(sim_servant hello_hex)
    serv_add_pass_test(sim_servant sim_servant "${_sim_fw}" "${_sim_expect}")
  else()
    set(_sim_fw "${_asm_hex}")
    set(_sim_expect "Hi, I'm Servant!")
    serv_add_pass_test(sim_servant sim_servant "${_sim_fw}" "${_sim_expect}")
  endif()

  serv_add_pass_test(sim_servant_asm sim_servant "${_asm_hex}" "Hi, I'm Servant!")

  add_custom_target(sim
    DEPENDS sim_servant
    COMMAND ${CMAKE_COMMAND}
            "-DEXE=$<TARGET_FILE:sim_servant>"
            "-DFIRMWARE=${_sim_fw}"
            "-DEXPECT=${_sim_expect}"
            "-DUART_BAUDRATE=${SERV_UART_BAUD}"
            "-DTIMEOUT=${SERV_TIMEOUT}"
            -P ${SERV_CMAKE_DIR}/ExpectPass.cmake
    COMMENT "Run Servant Verilator sim (${_sim_expect})"
    VERBATIM)

  message(STATUS "ServSim: primary firmware=${_sim_fw}")
  message(STATUS "ServSim: primary expect=${_sim_expect}")
endfunction()
