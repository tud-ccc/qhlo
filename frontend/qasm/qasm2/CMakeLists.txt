################################################################################
# qasm2_frontend
#
# The QASM 2.0 to quantum-mlir frontend project.
################################################################################

set(QASM2_GENERATED_DIR
    "${CMAKE_CURRENT_BINARY_DIR}/generated"
)

antlr_target(
    QASM2Lexer
    "${CMAKE_CURRENT_SOURCE_DIR}/qasm2Lexer.g4"

    LEXER

    PACKAGE
        qasm2

    OUTPUT_DIRECTORY
        "${QASM2_GENERATED_DIR}"
)

antlr_target(
    QASM2Parser
    "${CMAKE_CURRENT_SOURCE_DIR}/qasm2Parser.g4"

    PARSER
    VISITOR

    PACKAGE
        qasm2

    OUTPUT_DIRECTORY
        "${QASM2_GENERATED_DIR}"

    DEPENDS_ANTLR
        QASM2Lexer

    COMPILE_FLAGS
        -lib "${ANTLR_QASM2Lexer_OUTPUT_DIR}"
)

################################################################################
# Generated ANTLR Parser
################################################################################

add_library(QuantumQASM2Parser
    ${ANTLR_QASM2Lexer_CXX_OUTPUTS}
    ${ANTLR_QASM2Parser_CXX_OUTPUTS}
)

target_include_directories(QuantumQASM2Parser
    PUBLIC
        "${ANTLR_QASM2Lexer_OUTPUT_DIR}"
        "${ANTLR_QASM2Parser_OUTPUT_DIR}"
)

target_link_libraries(QuantumQASM2Parser
    PUBLIC
        antlr4_static
)

################################################################################
# The QASM 2.0 frontend
################################################################################

set(LLVM_REQUIRES_RTTI ON)
set(LLVM_REQUIRES_EH ON)

add_mlir_library(QuantumQASM2Frontend
    QASM2Frontend.cpp
    QASM2Visitor.cpp

    EXCLUDE_FROM_LIBMLIR

    LINK_LIBS
    PRIVATE
        QuantumQASM2Parser

    PUBLIC
        QuantumQASMCommon
        MLIRIR
        MLIRSupport
)

target_include_directories(QuantumQASM2Frontend
    PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
)
