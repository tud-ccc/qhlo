//===---- QASMScope.cpp -  OpenQASM Register Scope ----------------------===//
//
// @author  Lars Schütze (lars.schuetze@tu-dresden.de)
//===----------------------------------------------------------------------===//

#include "QASMScope.h"

#include "quantum-mlir/Dialect/Quantum/IR/QuantumOps.h"
#include "quantum-mlir/Dialect/Quantum/IR/QuantumTypes.h"

#include <cassert>

namespace quantum::frontend {

mlir::Value QASMScope::QuantumRegister::getWholeRegisterValue() const
{
    const auto &interval = intervals.lookup(0);
    return interval.size() == size ? interval.value : mlir::Value{};
}

mlir::Value QASMScope::QuantumRegister::getQubitValue(unsigned index) const
{
    assert(index < size && "qubit index is outside the register");
    const auto &interval = intervals.lookup(index);
    assert(interval.size() == 1 && "qubit must be materialized before access");
    return interval.value;
}

void QASMScope::QuantumRegister::updateInterval(
    unsigned start,
    mlir::Value value)
{
    assert(start < size && "interval start is outside the register");
    auto &interval = intervals.lookup(start);
    assert(interval.start == start && "expected the start of an interval");
    assert(
        value && value.getType() == interval.value.getType()
        && "replacement must preserve the interval's qubit type");
    interval.value = value;
}

void QASMScope::QuantumRegister::updateQubit(unsigned index, mlir::Value value)
{
    assert(index < size && "qubit index is outside the register");
    assert(
        intervals.lookup(index).size() == 1
        && "qubit must be materialized before update");
    updateInterval(index, value);
}

void QASMScope::QuantumRegister::updateWholeRegister(mlir::Value value)
{
    assert(
        value
        && value.getType()
               == mlir::quantum::QubitType::get(value.getContext(), size)
        && "replacement must match the register's qubit type");
    intervals.set(0, size, value);
}

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
    reg.updateWholeRegister(initialValue);
    return reg;
}

mlir::Value QASMScope::materializeQubit(
    QASMScope::QuantumRegister &reg,
    unsigned index,
    mlir::OpBuilder &builder,
    mlir::Location loc)
{
    auto &interval = reg.intervals.lookup(index);

    // Reuse an already isolated qubit to avoid emitting a redundant split.
    if (interval.size() == 1) return interval.value;

    const unsigned leftSize = index - interval.start;
    const unsigned rightSize = interval.end - index - 1;

    // Preserve register order: left remainder, selected qubit, right remainder.
    // Omit empty remainders when the qubit lies at an interval boundary.
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

    // Associate each split result with its half-open register range so later
    // accesses use the new values instead of the consumed interval value.
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
