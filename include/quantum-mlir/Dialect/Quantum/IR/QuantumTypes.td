//===- Types.td - Quantum dialect types ------------------*- tablegen -*-===//
//
// This is the definitions file for the Quantum dialect types.
//
//===----------------------------------------------------------------------===//

#ifndef QUANTUM_TYPES
#define QUANTUM_TYPES

include "quantum-mlir/Dialect/Quantum/IR/QuantumAttributes.td"
include "mlir/IR/EnumAttr.td"
include "mlir/IR/BuiltinTypeInterfaces.td"
include "quantum-mlir/Dialect/QPU/Interfaces/MeasurementSourceInterface.td"

def Quantum_QubitType : Quantum_Type<"Qubit"> {
  let mnemonic = "qubit";
  let summary = "Multi-qubit register type";
  
  let parameters = (ins
    "int64_t":$size
  );

  let assemblyFormat = "`<` $size `>`";

  let extraClassDeclaration = [{
    bool isSingleQubit() const;
  }];

  let genVerifyDecl = 1;
}

class QubitSizePred<int N> : CPred<"$_self.cast<QubitType>().getSize() == " # N>;

class QubitArrayOfSize<int N>
  : Type<And<[Quantum_QubitType.predicate, QubitSizePred<N>]>,
         "Quantum " # N # "-Qubit Type">,
    BuildableType<"QubitType::get($_builder.getContext(), " # N # ")">;

def Quantum_SingleQubitType : QubitArrayOfSize<1>;

def Quantum_MeasurementType : Quantum_Type<"Measurement", [
  QPU_MeasurementSourceInterface
]> {
  let extraClassDeclaration = [{
    bool isMutable() const { return false; }
  }];
  let mnemonic = "measurement";
  let summary = "Multi-dimensional measure type";
  let parameters = (ins "int64_t":$size);
  let assemblyFormat = "`<` $size `>`";
}

#endif
