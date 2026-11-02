# Run the Servant Verilator sim and require the documented PASS markers.
#
#   cmake -DEXE=/path/to/sim_servant
#         -DFIRMWARE=/path/to/hello.hex
#         -DEXPECT=Hello, SERV!
#         -DUART_BAUDRATE=57600
#         -DTIMEOUT=200000000
#         -P cmake/ExpectPass.cmake

if(NOT EXE)
  message(FATAL_ERROR "ExpectPass.cmake requires -DEXE=<path>")
endif()
if(NOT FIRMWARE)
  message(FATAL_ERROR "ExpectPass.cmake requires -DFIRMWARE=<hex>")
endif()
if(NOT EXPECT)
  message(FATAL_ERROR "ExpectPass.cmake requires -DEXPECT=<uart string>")
endif()
if(NOT UART_BAUDRATE)
  set(UART_BAUDRATE 57600)
endif()
if(NOT TIMEOUT)
  set(TIMEOUT 200000000)
endif()

if(NOT EXISTS "${EXE}")
  message(FATAL_ERROR "ExpectPass.cmake: EXE not found: ${EXE}")
endif()
if(NOT EXISTS "${FIRMWARE}")
  message(FATAL_ERROR "ExpectPass.cmake: firmware not found: ${FIRMWARE}")
endif()

execute_process(
  COMMAND "${EXE}"
          "+firmware=${FIRMWARE}"
          "+uart_baudrate=${UART_BAUDRATE}"
          "+timeout=${TIMEOUT}"
  RESULT_VARIABLE rc
  OUTPUT_VARIABLE out
  ERROR_VARIABLE err
)
set(_all "${out}\n${err}")
message(STATUS "sim stdout:\n${out}")
if(err)
  message(STATUS "sim stderr:\n${err}")
endif()

if(NOT rc EQUAL 0)
  message(FATAL_ERROR "ExpectPass: sim exited ${rc} (expected 0)")
endif()
if(NOT _all MATCHES "${EXPECT}")
  message(FATAL_ERROR "ExpectPass: output missing '${EXPECT}'")
endif()
if(NOT _all MATCHES "Test complete")
  message(FATAL_ERROR "ExpectPass: output missing 'Test complete'")
endif()
if(NOT _all MATCHES "verilator_exit=0")
  message(FATAL_ERROR "ExpectPass: output missing 'verilator_exit=0'")
endif()
if(NOT _all MATCHES "ALL TESTS PASSED")
  message(FATAL_ERROR "ExpectPass: output missing 'ALL TESTS PASSED'")
endif()
message(STATUS "ExpectPass: PASS (${EXPECT})")
