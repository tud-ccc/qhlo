add_library(QuantumQASMCommon
    QASMIncludeResolver.cpp
    QASMDiagnostics.cpp
)

target_include_directories(QuantumQASMCommon
    PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
)

target_link_libraries(QuantumQASMCommon
    PUBLIC
        MLIRIR
        MLIRSupport
)
