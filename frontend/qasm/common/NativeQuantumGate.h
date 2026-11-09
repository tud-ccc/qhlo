//===---- NativeQuantumGate.h - Shared native QASM gates ----------------===//
//
// @author  Lars Schütze (lars.schuetze@tu-dresden.de)
//===----------------------------------------------------------------------===//

#ifndef QUANTUM_MLIR_FRONTEND_QASM_COMMON_NATIVEQUANTUMGATE_H
#define QUANTUM_MLIR_FRONTEND_QASM_COMMON_NATIVEQUANTUMGATE_H

#include <llvm/ADT/SmallVector.h>
#include <llvm/ADT/StringRef.h>
#include <mlir/IR/Builders.h>
#include <mlir/IR/ValueRange.h>
#include <mlir/Support/LogicalResult.h>
#include <optional>

namespace quantum::frontend {

/// These gates are natively supported by the MLIR Quantum dialect
enum class QuantumNativeGate {
    H,
    X,
    Y,
    Z,
    S,
    SX,
    T,
    Sdg,
    Tdg,
    CZ,
    CX,
    SWAP,
    RX,
    RY,
    RZ,
    P,
    U1,
    U2,
    U3,
    CRZ,
    CRY,
    CU1,
    CCX,
    CSWAP
};

struct NativeGateSpec {
    QuantumNativeGate kind;
    unsigned qubitCount;
    unsigned parameterCount;
};

std::optional<NativeGateSpec> lookupNativeQuantumGate(llvm::StringRef name);

mlir::FailureOr<llvm::SmallVector<mlir::Value>> emitNativeGate(
    const NativeGateSpec &spec,
    mlir::Location loc,
    mlir::OpBuilder &builder,
    mlir::ValueRange qubits,
    mlir::ValueRange parameters);

} // namespace quantum::frontend

#endif // QUANTUM_MLIR_FRONTEND_QASM_COMMON_NATIVEQUANTUMGATE_H
