//===---- QASMScope.cpp -  OpenQASM Register Scope ----------------------===//
//
// @author  Lars Schütze (lars.schuetze@tu-dresden.de)
//===----------------------------------------------------------------------===//

#include "QASMScope.h"

#include "quantum-mlir/Dialect/Quantum/IR/QuantumOps.h"

namespace quantum::frontend {

QASMScope::QuantumRegister* QASMScope::lookupQReg(llvm::StringRef name)
{
    auto it = qregs_.find(name);
    return it == qregs_.end() ? nullptr : &it->second;
}

QASMScope::ClassicalRegister* QASMScope::lookupCReg(llvm::StringRef name)
{
    auto it = cregs_.find(name);
    return it == cregs_.end() ? nullptr : &it->second;
}

QASMScope::ClassicalRegister &QASMScope::declareCReg(
    llvm::StringRef name,
    unsigned size,
    mlir::Value initialValue)
{
    auto &reg = cregs_[name];
    reg.size = size;
    reg.value = initialValue;
    return reg;
}

QASMScope::QuantumRegister &QASMScope::declareQReg(
    llvm::StringRef name,
    unsigned size,
    mlir::Value initialValue)
{
    auto &reg = qregs_[name];
    reg.size = size;
    reg.intervals.set(0, size, initialValue);
    return reg;
}

mlir::Value QASMScope::materializeQubit(
    QASMScope::QuantumRegister &reg,
    unsigned index,
    mlir::OpBuilder &builder,
    mlir::Location loc)
{
    auto &interval = reg.intervals.lookup(index);

    if (interval.size() == 1) return interval.value;

    const unsigned leftSize = index - interval.start;
    const unsigned rightSize = interval.end - index - 1;

    llvm::SmallVector<mlir::Type> resultTypes;

    if (leftSize != 0)
        resultTypes.push_back(
            mlir::quantum::QubitType::get(builder.getContext(), leftSize));

    resultTypes.push_back(
        mlir::quantum::QubitType::get(builder.getContext(), 1));

    if (rightSize != 0)
        resultTypes.push_back(
            mlir::quantum::QubitType::get(builder.getContext(), rightSize));

    auto split = mlir::quantum::SplitOp::create(
        builder,
        loc,
        resultTypes,
        interval.value);

    llvm::SmallVector<QubitInterval, 3> intervals;
    unsigned resultIndex = 0;
    if (leftSize != 0)
        intervals.push_back(
            {interval.start, index, split->getResult(resultIndex++)});
    auto qubit = split->getResult(resultIndex++);
    intervals.push_back({index, index + 1, qubit});
    if (rightSize != 0)
        intervals.push_back(
            {index + 1, interval.end, split->getResult(resultIndex)});
    reg.intervals.replace(interval, intervals);
    return qubit;
}

} // namespace quantum::frontend
