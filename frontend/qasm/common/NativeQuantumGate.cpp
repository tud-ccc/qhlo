//===---- NativeQuantumGate.cpp - Shared native QASM gates --------------===//
//
// @author  Lars Schütze (lars.schuetze@tu-dresden.de)
//===----------------------------------------------------------------------===//

#include "NativeQuantumGate.h"

#include "quantum-mlir/Dialect/Quantum/IR/QuantumOps.h"

#include <llvm/ADT/StringSwitch.h>
#include <mlir/IR/Diagnostics.h>
#include <mlir/IR/TypeRange.h>

namespace quantum::frontend {

std::optional<NativeGateSpec> lookupNativeQuantumGate(llvm::StringRef name)
{
    return llvm::StringSwitch<std::optional<NativeGateSpec>>(name)
        // Unary operations
        .Case("x", NativeGateSpec{QuantumNativeGate::X, 1, 0})
        .Case("y", NativeGateSpec{QuantumNativeGate::Y, 1, 0})
        .Case("z", NativeGateSpec{QuantumNativeGate::Z, 1, 0})
        .Case("h", NativeGateSpec{QuantumNativeGate::H, 1, 0})
        .Cases({"p", "phase"}, NativeGateSpec{QuantumNativeGate::P, 1, 1})
        .Case("s", NativeGateSpec{QuantumNativeGate::S, 1, 0})
        .Case("sx", NativeGateSpec{QuantumNativeGate::SX, 1, 0})
        .Case("sdg", NativeGateSpec{QuantumNativeGate::Sdg, 1, 0})
        .Case("t", NativeGateSpec{QuantumNativeGate::T, 1, 0})
        .Case("tdg", NativeGateSpec{QuantumNativeGate::Tdg, 1, 0})
        // Unary operations with operand
        .Case("rx", NativeGateSpec{QuantumNativeGate::RX, 1, 1})
        .Case("ry", NativeGateSpec{QuantumNativeGate::RY, 1, 1})
        .Case("rz", NativeGateSpec{QuantumNativeGate::RZ, 1, 1})
        // Controlled gates (2 qubits)
        .Case("cz", NativeGateSpec{QuantumNativeGate::CZ, 2, 0})
        .Cases({"cx", "CX"}, NativeGateSpec{QuantumNativeGate::CX, 2, 0})
        .Case("swap", NativeGateSpec{QuantumNativeGate::SWAP, 2, 0})
        // Controlled rotations
        .Case("crz", NativeGateSpec{QuantumNativeGate::CRZ, 2, 1})
        .Case("cry", NativeGateSpec{QuantumNativeGate::CRY, 2, 1})
        .Cases({"cu1", "cp"}, NativeGateSpec{QuantumNativeGate::CU1, 2, 1})
        // 3 Qubit gates
        .Case("ccx", NativeGateSpec{QuantumNativeGate::CCX, 3, 0})
        .Case("cswap", NativeGateSpec{QuantumNativeGate::CSWAP, 3, 0})
        // U gates
        .Case("u1", NativeGateSpec{QuantumNativeGate::U1, 1, 1})
        .Case("u2", NativeGateSpec{QuantumNativeGate::U2, 1, 2})
        .Case("u3", NativeGateSpec{QuantumNativeGate::U3, 1, 3})
        .Cases({"u", "U"}, NativeGateSpec{QuantumNativeGate::U3, 1, 3})
        .Default(std::nullopt);
}

// ################################################################################
// # Generate Quantum MLIR gates
// ################################################################################

namespace {

template<typename Op>
llvm::SmallVector<mlir::Value> createNativeGate(
    mlir::Location loc,
    mlir::OpBuilder &builder,
    mlir::ValueRange qubits,
    mlir::ValueRange parameters)
{
    llvm::SmallVector<mlir::Type> resultTypes;
    for (mlir::Value qubit : qubits) resultTypes.push_back(qubit.getType());

    llvm::SmallVector<mlir::Value> operands(qubits.begin(), qubits.end());
    operands.append(parameters.begin(), parameters.end());

    auto op = Op::create(
        builder,
        loc,
        mlir::TypeRange(resultTypes),
        mlir::ValueRange(operands));

    auto results = op->getResults();
    return llvm::SmallVector<mlir::Value>(results.begin(), results.end());
}

} // namespace

mlir::FailureOr<llvm::SmallVector<mlir::Value>> emitNativeGate(
    const NativeGateSpec &spec,
    mlir::Location loc,
    mlir::OpBuilder &builder,
    mlir::ValueRange qubits,
    mlir::ValueRange parameters)
{
    if (qubits.size() != spec.qubitCount
        || parameters.size() != spec.parameterCount) {
        mlir::emitError(loc)
            << "expected " << spec.qubitCount << " qubit operands and "
            << spec.parameterCount << " parameters, got " << qubits.size()
            << " and " << parameters.size();
        return mlir::failure();
    }

    // Capture the common arguments once.
    auto emit = [&]<typename Op>() {
        return createNativeGate<Op>(loc, builder, qubits, parameters);
    };

    switch (spec.kind) {
    case QuantumNativeGate::H: return emit.operator()<mlir::quantum::HOp>();
    case QuantumNativeGate::X: return emit.operator()<mlir::quantum::XOp>();
    case QuantumNativeGate::Y: return emit.operator()<mlir::quantum::YOp>();
    case QuantumNativeGate::Z: return emit.operator()<mlir::quantum::ZOp>();
    case QuantumNativeGate::S: return emit.operator()<mlir::quantum::SOp>();
    case QuantumNativeGate::SX: return emit.operator()<mlir::quantum::SXOp>();
    case QuantumNativeGate::T: return emit.operator()<mlir::quantum::TOp>();
    case QuantumNativeGate::Sdg: return emit.operator()<mlir::quantum::SdgOp>();
    case QuantumNativeGate::Tdg: return emit.operator()<mlir::quantum::TdgOp>();
    case QuantumNativeGate::CX: return emit.operator()<mlir::quantum::CNOTOp>();
    case QuantumNativeGate::CZ: return emit.operator()<mlir::quantum::CZOp>();
    case QuantumNativeGate::SWAP:
        return emit.operator()<mlir::quantum::SWAPOp>();
    case QuantumNativeGate::RX: return emit.operator()<mlir::quantum::RxOp>();
    case QuantumNativeGate::RY: return emit.operator()<mlir::quantum::RyOp>();
    case QuantumNativeGate::RZ: return emit.operator()<mlir::quantum::RzOp>();
    case QuantumNativeGate::P: return emit.operator()<mlir::quantum::PhaseOp>();
    case QuantumNativeGate::U1: return emit.operator()<mlir::quantum::U1Op>();
    case QuantumNativeGate::U2: return emit.operator()<mlir::quantum::U2Op>();
    case QuantumNativeGate::U3: return emit.operator()<mlir::quantum::U3Op>();
    case QuantumNativeGate::CRZ: return emit.operator()<mlir::quantum::CRzOp>();
    case QuantumNativeGate::CRY: return emit.operator()<mlir::quantum::CRyOp>();
    case QuantumNativeGate::CU1: return emit.operator()<mlir::quantum::CU1Op>();
    case QuantumNativeGate::CCX: return emit.operator()<mlir::quantum::CCXOp>();
    case QuantumNativeGate::CSWAP:
        return emit.operator()<mlir::quantum::CSWAPOp>();
    }

    mlir::emitError(loc) << "unsupported native gate";
    return mlir::failure();
}

} // namespace quantum::frontend
