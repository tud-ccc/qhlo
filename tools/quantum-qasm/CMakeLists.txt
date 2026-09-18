################################################################################
# quantum-qasm
#
# The quantum-mlir QASM frontend driver.
################################################################################

project(quantum-qasm)

add_executable(${PROJECT_NAME}
    quantum-qasm.cpp
)

# Compile the driver with the same RTTI/EH configuration as LLVM.
llvm_update_compile_flags(${PROJECT_NAME})

target_link_libraries(${PROJECT_NAME}
    PRIVATE
        QuantumQASMFrontend
)
