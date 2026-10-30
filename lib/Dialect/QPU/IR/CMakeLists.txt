add_mlir_dialect_library(QPUIR
        QPUBase.cpp
        QPUAttributes.cpp
        QPUTypes.cpp
        QPUOps.cpp
        
    DEPENDS
        QPUIncGen

    LINK_LIBS PUBLIC
        QPUInterfaces
        MLIRIR
        MLIRParser
        MLIRSideEffectInterfaces
        QPUTransforms
        MLIRArithDialect
        MLIRArithTransforms
)
