################################################################################
# qasm-quantum-frontend
#
# The QASM to quantum-mlir frontend project.
################################################################################

add_subdirectory(common)
add_subdirectory(qasm2)
add_subdirectory(qasm3)

################################################################################
# QASM frontend library
################################################################################

add_mlir_library(QuantumQASMFrontend
    QASMFrontend.cpp

    EXCLUDE_FROM_LIBMLIR

    LINK_LIBS
    PRIVATE
        QuantumQASMCommon
        QuantumQASM2Frontend
        QuantumQASM3Frontend
        MLIRIR
        MLIRSupport
)

target_include_directories(QuantumQASMFrontend
    PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
)
