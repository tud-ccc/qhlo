################################################################################
# quantum-qasm
#
# The quantum-mlir QASM frontend driver.
################################################################################

project(quantum-qasm)

add_executable(${PROJECT_NAME}
    quantum-qasm.cpp
)

target_link_libraries(${PROJECT_NAME}
    PRIVATE
        QuantumQASMFrontend
)
