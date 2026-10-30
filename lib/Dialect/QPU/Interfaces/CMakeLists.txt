add_mlir_library(QPUInterfaces
    MeasurementSourceInterface.cpp

    DEPENDS
        QPUMeasurementSourceInterfaceInterfaceIncGen

    LINK_LIBS PUBLIC
        MLIRIR
)
