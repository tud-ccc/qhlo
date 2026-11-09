################################################################################
# quantum-mlir-tests
#
# The quantum-mlir unit test project.
################################################################################

find_package(doctest REQUIRED CONFIG)
include(doctest)

add_executable(quantum-mlir-tests
  QuantumOpsTest.cpp
  main.cpp
)

target_link_libraries(quantum-mlir-tests
  PRIVATE
    doctest::doctest
    MLIRIR
    MLIRSupport
    QuantumIR
)

doctest_discover_tests(quantum-mlir-tests)

if(FRONTEND_QASM)
  target_sources(quantum-mlir-tests PRIVATE QASMScopeTest.cpp)
  target_link_libraries(quantum-mlir-tests PRIVATE QuantumQASMCommon MLIRArithDialect)
endif()
