################################################################################
# qasm3_frontend
#
# The QASM 2.0 to quantum-mlir frontend project.
################################################################################

set(QASM3_GENERATED_DIR
    "${CMAKE_CURRENT_BINARY_DIR}/generated"
)

antlr_target(
    QASM3Lexer
    "${CMAKE_CURRENT_SOURCE_DIR}/qasm3Lexer.g4"

    LEXER

    PACKAGE
        qasm3

    OUTPUT_DIRECTORY
        "${QASM3_GENERATED_DIR}"
)

antlr_target(
    QASM3Parser
    "${CMAKE_CURRENT_SOURCE_DIR}/qasm3Parser.g4"

    PARSER
    VISITOR

    PACKAGE
        qasm3

    OUTPUT_DIRECTORY
        "${QASM3_GENERATED_DIR}"

    DEPENDS_ANTLR
        QASM3Lexer

    COMPILE_FLAGS
        -lib "${ANTLR_QASM3Lexer_OUTPUT_DIR}"
)

################################################################################
# Generated ANTLR Parser
################################################################################

add_library(QuantumQASM3Parser
    ${ANTLR_QASM3Lexer_CXX_OUTPUTS}
    ${ANTLR_QASM3Parser_CXX_OUTPUTS}
)

target_include_directories(QuantumQASM3Parser
    PUBLIC
        "${ANTLR_QASM3Lexer_OUTPUT_DIR}"
        "${ANTLR_QASM3Parser_OUTPUT_DIR}"
)

target_link_libraries(QuantumQASM3Parser
    PUBLIC
        antlr4_static
)

################################################################################
# The QASM 3.x frontend
################################################################################

set(LLVM_REQUIRES_RTTI ON)
set(LLVM_REQUIRES_EH ON)

add_mlir_library(QuantumQASM3Frontend
    QASM3Frontend.cpp
    QASM3Visitor.cpp

    EXCLUDE_FROM_LIBMLIR

    LINK_LIBS
    PRIVATE
        QuantumQASM3Parser

    PUBLIC
        QuantumQASMCommon
        MLIRIR
        MLIRSupport
)

target_include_directories(QuantumQASM3Frontend
    PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
)
