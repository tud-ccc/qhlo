//===- MeasurementSourceInterface.td ----------------------*- tablegen -*-===//
#ifndef QPU_MEASUREMENT_SOURCE_INTERFACE
#define QPU_MEASUREMENT_SOURCE_INTERFACE

include "mlir/IR/Interfaces.td"

def QPU_MeasurementSourceInterface : TypeInterface<"MeasurementSourceInterface"> {
  let cppNamespace = "::mlir::qpu";
  let description = [{
    A source of classical measurement bits. Immutable sources represent an
    SSA snapshot; mutable sources refer to result storage whose contents can
    change when a measurement writes to it.
  }];
  let methods = [
    InterfaceMethod<"Whether reading bits accesses mutable result storage.",
                    "bool", "isMutable", (ins)>
  ];
}

#endif // QPU_MEASUREMENT_SOURCE_INTERFACE
