add_library(QuantumQASMCommon
    QASMIncludeResolver.cpp
    QASMDiagnostics.cpp
    QASMScope.cpp
)

llvm_update_compile_flags(QuantumQASMCommon)

target_include_directories(QuantumQASMCommon
    PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
)

target_link_libraries(QuantumQASMCommon
    PUBLIC
        MLIRIR
        MLIRSupport
        LLVMSupport
)
