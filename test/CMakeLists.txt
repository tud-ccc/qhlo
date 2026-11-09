################################################################################
# check-quantum-mlir
#
# The quantum-mlir regression test project.
################################################################################

project(check-quantum-mlir)

llvm_canonicalize_cmake_booleans(
        MLIR_ENABLE_BINDINGS_PYTHON
        BACKEND_QIR
        FRONTEND_QASM
)

if(BACKEND_QIR)
    # Explicitly set the variable for substitution
    set(QIR_SHLIBS "${QIR_DIR}/libqir_backend${CMAKE_SHARED_LIBRARY_SUFFIX},${QIR_DIR}/libqir_stdlib${CMAKE_SHARED_LIBRARY_SUFFIX}" CACHE STRING "Libraries required by cpu-runner to load QIR")

    message(STATUS "Using backend QIR libs in: ${QIR_DIR}")
    message(STATUS "Using libraries: ${QIR_SHLIBS}")
else()
    set(QIR_SHLIBS "")
endif()

# Configure the testing site configuration.
configure_lit_site_cfg(
        ${CMAKE_CURRENT_SOURCE_DIR}/lit.site.cfg.py.in
        ${CMAKE_CURRENT_BINARY_DIR}/lit.site.cfg.py
    MAIN_CONFIG
        ${CMAKE_CURRENT_SOURCE_DIR}/lit.cfg.py
)

# Discover suites through the build tree so lit loads the configured site file.
foreach(TEST_DIR IN ITEMS Conversion Dialect quantum-opt python Target
        quantum-qasm Integration/QIR-Runner Integration/OpenQASM2)
    file(MAKE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/${TEST_DIR}")
endforeach()

set(COMPILER_TEST_DEPENDS
    FileCheck count not
    quantum-opt
    MLIRCAPIQILLR
    MLIRCAPIRVSDG
    MLIRCAPIQUANTUM
    MLIRCAPIQPU
)

if(MLIR_ENABLE_BINDINGS_PYTHON)
    list(APPEND COMPILER_TEST_DEPENDS QuantumPythonModules)
endif()

add_lit_testsuite(check-quantum-mlir-compiler
    "Running the quantum-mlir compiler tests"
    ${CMAKE_CURRENT_BINARY_DIR}/Conversion
    ${CMAKE_CURRENT_BINARY_DIR}/Dialect
    ${CMAKE_CURRENT_BINARY_DIR}/quantum-opt
    ${CMAKE_CURRENT_BINARY_DIR}/python
    DEPENDS ${COMPILER_TEST_DEPENDS}
)

# Keep the existing target as the compiler regression entry point.
add_custom_target(check-quantum-mlir DEPENDS check-quantum-mlir-compiler)

set(BACKEND_TEST_DIRS ${CMAKE_CURRENT_BINARY_DIR}/Target)
set(BACKEND_TEST_DEPENDS FileCheck count not quantum-translate)
add_lit_testsuite(check-quantum-mlir-backend
    "Running the quantum-mlir backend tests"
    ${BACKEND_TEST_DIRS}
    DEPENDS ${BACKEND_TEST_DEPENDS}
)

set(FRONTEND_TEST_DIRS)
set(INTEGRATION_TEST_DIRS)
set(FRONTEND_TEST_DEPENDS)
set(INTEGRATION_TEST_DEPENDS)
if(BACKEND_QIR)
    list(APPEND INTEGRATION_TEST_DIRS
        ${CMAKE_CURRENT_BINARY_DIR}/Integration/QIR-Runner)
    list(APPEND INTEGRATION_TEST_DEPENDS
        FileCheck count not quantum-opt mlir-runner)
endif()

if(FRONTEND_QASM)
    list(APPEND FRONTEND_TEST_DIRS
        ${CMAKE_CURRENT_BINARY_DIR}/quantum-qasm)
    list(APPEND INTEGRATION_TEST_DIRS
        ${CMAKE_CURRENT_BINARY_DIR}/Integration/frontend/qasm2
        ${CMAKE_CURRENT_BINARY_DIR}/Integration/frontend/qasm3)
    list(APPEND FRONTEND_TEST_DEPENDS
        FileCheck count not split-file quantum-qasm quantum-opt)
    list(APPEND INTEGRATION_TEST_DEPENDS
        FileCheck count not quantum-qasm quantum-opt)
endif()

add_lit_testsuite(check-quantum-mlir-frontend
    "Running the quantum-mlir frontend tests"
    ${FRONTEND_TEST_DIRS}
    DEPENDS ${FRONTEND_TEST_DEPENDS}
)

add_lit_testsuite(check-quantum-mlir-integration
    "Running the quantum-mlir integration tests"
    ${INTEGRATION_TEST_DIRS}
    DEPENDS ${INTEGRATION_TEST_DEPENDS}
)

add_custom_target(check-quantum-mlir-all
    DEPENDS
        check-quantum-mlir-compiler
        check-quantum-mlir-backend
        check-quantum-mlir-frontend
        check-quantum-mlir-integration
)
