################################################################################
# check-quantum-mlir
#
# The quantum-mlir regression test project.
################################################################################

project(check-quantum-mlir)

llvm_canonicalize_cmake_booleans(
        MLIR_ENABLE_BINDINGS_PYTHON
)

if(BACKEND_QIR)
    # Explicitly set the variable for substitution
    set(QIR_SHLIBS "${QIR_DIR}/libqir_backend${CMAKE_SHARED_LIBRARY_SUFFIX},${QIR_DIR}/libqir_stdlib${CMAKE_SHARED_LIBRARY_SUFFIX}" CACHE STRING "Libraries required by cpu-runner to load QIR")

    message(STATUS "Using backend QIR libs in: ${QIR_DIR}")
    message(STATUS "Using libraries: ${QIR_SHLIBS}")
endif()

# Configure the testing site configuration.
configure_lit_site_cfg(
        ${CMAKE_CURRENT_SOURCE_DIR}/lit.site.cfg.py.in
        ${CMAKE_CURRENT_BINARY_DIR}/lit.site.cfg.py
    MAIN_CONFIG
        ${CMAKE_CURRENT_SOURCE_DIR}/lit.cfg.py
)

set(TEST_DEPENDS
    FileCheck count not
    mlir-runner
    quantum-opt
    quantum-translate
    quantum-qasm
    MLIRCAPIQILLR
    MLIRCAPIRVSDG
    MLIRCAPIQUANTUM
    MLIRCAPIQPU
)

if(MLIR_ENABLE_BINDINGS_PYTHON)
  list(APPEND TEST_DEPENDS QuantumPythonModules)
endif()

# Create the test suite.
add_lit_testsuite(${PROJECT_NAME}
    "Running the quantum-mlir regression tests"
    ${CMAKE_CURRENT_BINARY_DIR}
    DEPENDS
        ${TEST_DEPENDS}
)
# add_lit_testsuites(QUANTUMMLIR
#     ${CMAKE_CURRENT_SOURCE_DIR}
#     DEPENDS
#         ${TEST_DEPENDS}
# )
