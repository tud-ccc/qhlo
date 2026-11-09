//===- Types.td - QPU dialect types -------------------------*- tablegen -*-===//
//
// This is the definitions file for the QPU dialect types.
//
//===----------------------------------------------------------------------===//

#ifndef QPU_TYPES
#define QPU_TYPES

include "quantum-mlir/Dialect/QPU/IR/QPUAttributes.td"
include "mlir/IR/BuiltinTypeInterfaces.td"

def QPU_BitSequence : AnyTypeOf<[
    1DTensorOf<[I1]>,
    MemRefRankOf<[I1], [1]>
  ], "rank-one tensor or memref of i1", "::mlir::ShapedType">;

def QPU_MeasurementSource : Type<
    CPred<"::llvm::isa<::mlir::qpu::MeasurementSourceInterface>($_self)">,
    "measurement source">;

#endif // QPU_TYPES
