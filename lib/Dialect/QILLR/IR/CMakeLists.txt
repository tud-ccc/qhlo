add_mlir_dialect_library(QILLRIR
        QILLRAttributes.cpp
        QILLRBase.cpp
        QILLROps.cpp
        QILLRTypes.cpp

    DEPENDS
        QILLRIncGen

    LINK_LIBS PUBLIC
        QPUInterfaces
        MLIRCallInterfaces
        MLIRFunctionInterfaces
        MLIRInferTypeOpInterface
        MLIRIR
        QuantumIR
        MLIRParser
        MLIRSideEffectInterfaces
        MLIRControlFlowInterfaces
)
