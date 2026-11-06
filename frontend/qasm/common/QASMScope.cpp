//===---- QASMScope.cpp -  OpenQASM Register Scope ----------------------===//
//
// @author  Lars Schütze (lars.schuetze@tu-dresden.de)
//===----------------------------------------------------------------------===//

#include "QASMScope.h"

#include "quantum-mlir/Dialect/Quantum/IR/QuantumOps.h"
#include "quantum-mlir/Dialect/Quantum/IR/QuantumTypes.h"

#include <cassert>
#include <llvm/ADT/StringSet.h>
#include <mlir/Dialect/Tensor/IR/Tensor.h>
#include <utility>

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

QASMScope::QASMScope() { enterScope({}, LexicalScope::Kind::Global); }

QASMScope::Position QASMScope::getPosition() const
{ return {currentScope, currentScope->lastDeclaration}; }

QASMScope::LexicalScope &
QASMScope::enterScope(Position enclosingPosition, LexicalScope::Kind kind)
{
    // Scope objects must not move: positions retain their addresses.
    auto scope = std::unique_ptr<LexicalScope>(
        new LexicalScope(kind, enclosingPosition));
    currentScope = scope.get();
    lexicalScopes.push_back(std::move(scope));
    return *currentScope;
}

QASMScope::LexicalScope &QASMScope::enterScope(LexicalScope::Kind kind)
{ return enterScope(getPosition(), kind); }

void QASMScope::setCurrentScope(LexicalScope &scope) { currentScope = &scope; }

QASMScope::Declaration* QASMScope::lookupLocal(llvm::StringRef name)
{
    auto it = currentScope->declarations.find(name);
    return it == currentScope->declarations.end() ? nullptr : &it->second;
}

const QASMScope::Declaration* QASMScope::lookupLocal(llvm::StringRef name) const
{
    auto it = currentScope->declarations.find(name);
    return it == currentScope->declarations.end() ? nullptr : &it->second;
}

const QASMScope::Declaration*
QASMScope::lookup(Position position, llvm::StringRef name) const
{
    bool restrictCapture = false;
    while (position.scope) {
        for (auto* declaration = position.declaration; declaration;
             declaration = declaration->previous) {
            if (declaration->name != name) continue;
            // An inaccessible declaration still hides declarations of the same
            // name further out; never fall through to a different binding.
            if (restrictCapture
                && !std::holds_alternative<Constant>(declaration->payload)
                && !std::holds_alternative<Gate>(declaration->payload))
                return nullptr;
            return declaration;
        }
        const auto kind = position.scope->kind;
        restrictCapture |= kind == LexicalScope::Kind::Gate
                           || kind == LexicalScope::Kind::Subroutine;
        position = position.scope->enclosingPosition;
    }
    return nullptr;
}

QASMScope::Declaration*
QASMScope::lookup(Position position, llvm::StringRef name)
{
    return const_cast<Declaration*>(
        std::as_const(*this).lookup(position, name));
}

QASMScope::Declaration* QASMScope::lookup(llvm::StringRef name)
{ return lookup(getPosition(), name); }

const QASMScope::Declaration* QASMScope::lookup(llvm::StringRef name) const
{ return lookup(getPosition(), name); }

llvm::SmallVector<QASMScope::QuantumRegister*>
QASMScope::getVisibleQRegs() const
{
    llvm::SmallVector<QuantumRegister*> registers;
    llvm::StringSet<> seen;
    for (auto position = getPosition(); position.scope;
         position = position.scope->enclosingPosition) {
        for (auto* declaration = position.declaration; declaration;
             declaration = declaration->previous) {
            if (!seen.insert(declaration->name).second) continue;
            if (auto* reg =
                    std::get_if<QuantumRegister*>(&declaration->payload))
                registers.push_back(*reg);
        }
        const auto kind = position.scope->kind;
        if (kind == LexicalScope::Kind::Gate
            || kind == LexicalScope::Kind::Subroutine)
            break;
    }
    return registers;
}

QASMScope::Declaration* QASMScope::declare(
    llvm::StringRef name,
    Declaration::Payload payload,
    mlir::LocationAttr location)
{
    auto [it, inserted] = currentScope->declarations.try_emplace(
        name,
        Declaration{std::move(payload), location, {}, nullptr});
    if (!inserted) return nullptr;
    auto &declaration = it->second;
    declaration.name = it->getKey();
    declaration.previous = currentScope->lastDeclaration;
    currentScope->lastDeclaration = &declaration;
    return &declaration;
}

QASMScope::QuantumRegister* QASMScope::lookupQReg(llvm::StringRef name)
{
    auto* declaration = lookup(name);
    if (!declaration) return nullptr;
    auto* reg = std::get_if<QuantumRegister*>(&declaration->payload);
    return reg ? *reg : nullptr;
}

QASMScope::ClassicalRegister* QASMScope::lookupCReg(llvm::StringRef name)
{
    auto* declaration = lookup(name);
    if (!declaration) return nullptr;
    auto* reg = std::get_if<ClassicalRegister*>(&declaration->payload);
    return reg ? *reg : nullptr;
}

bool QASMScope::contains(llvm::StringRef name) const
{ return lookupLocal(name) != nullptr; }

QASMScope::Variable* QASMScope::declareVariable(
    llvm::StringRef name,
    mlir::Value value,
    mlir::LocationAttr location)
{
    assert(value && "variable must have an initial SSA value");
    auto* declaration = declare(name, Variable{value}, location);
    return declaration ? &std::get<Variable>(declaration->payload) : nullptr;
}

QASMScope::Constant* QASMScope::declareConstant(
    llvm::StringRef name,
    mlir::TypedAttr value,
    mlir::LocationAttr location)
{
    assert(value && "constant must have an evaluated value");
    auto* declaration = declare(name, Constant{value}, location);
    return declaration ? &std::get<Constant>(declaration->payload) : nullptr;
}

QASMScope::Gate*
QASMScope::declareGate(llvm::StringRef name, mlir::LocationAttr location)
{
    auto* declaration = declare(name, Gate{}, location);
    return declaration ? &std::get<Gate>(declaration->payload) : nullptr;
}

QASMScope::ClassicalRegister* QASMScope::declareCReg(
    llvm::StringRef name,
    unsigned size,
    mlir::Value initialValue,
    mlir::LocationAttr location)
{
    if (contains(name)) return nullptr;
    auto [it, inserted] = currentScope->cregs.try_emplace(name);
    if (!inserted) return nullptr;

    auto &reg = it->second;
    reg.size = size;
    reg.value = initialValue;
    declare(name, &reg, location);
    return &reg;
}

QASMScope::QuantumRegister* QASMScope::declareQReg(
    llvm::StringRef name,
    unsigned size,
    mlir::Value initialValue,
    bool isScalar,
    mlir::LocationAttr location)
{
    assert(
        (!isScalar || size == 1) && "scalar quantum registers have one qubit");
    if (contains(name)) return nullptr;
    auto [it, inserted] = currentScope->qregs.try_emplace(name);
    if (!inserted) return nullptr;

    auto &reg = it->second;
    reg.size = size;
    reg.isScalar = isScalar;
    reg.updateWholeRegister(initialValue);
    declare(name, &reg, location);
    return &reg;
}

mlir::Value QASMScope::materializeQubit(
    QASMScope::QuantumRegister &reg,
    unsigned index,
    mlir::OpBuilder &builder,
    mlir::Location loc)
{
    assert(index < reg.size && "qubit index is outside the register");
    auto &interval = reg.intervals.lookup(index);
    assert(
        interval.contains(index) && interval.end <= reg.size
        && "qubit interval must cover the index within the register bounds");
    assert(
        interval.value
        && interval.value.getType()
               == mlir::quantum::QubitType::get(
                   builder.getContext(),
                   interval.size())
        && "interval value must match its width and the builder's context");

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

void QASMScope::splitAt(
    QuantumRegister &reg,
    unsigned boundary,
    mlir::OpBuilder &builder,
    mlir::Location loc)
{
    assert(boundary <= reg.size && "split boundary is outside the register");
    if (boundary == 0 || boundary == reg.size) return;
    auto interval = reg.intervals.lookup(boundary);
    if (interval.start == boundary) return;
    auto split = mlir::quantum::SplitOp::create(
        builder,
        loc,
        llvm::SmallVector<mlir::Type>{
            mlir::quantum::QubitType::get(
                builder.getContext(),
                boundary - interval.start),
            mlir::quantum::QubitType::get(
                builder.getContext(),
                interval.end - boundary)},
        interval.value);
    reg.intervals.replace(
        interval,
        llvm::SmallVector<QubitInterval>{
            {interval.start,     boundary, split->getResult(0)},
            {      boundary, interval.end, split->getResult(1)}
    });
}

void QASMScope::refineSlice(
    QuantumRegister &reg,
    const RegisterSlice &slice,
    mlir::OpBuilder &builder,
    mlir::Location loc)
{
    assert(slice.isValid(reg.size) && "invalid register slice");
    if (slice.count == 1) {
        materializeQubit(reg, slice.offset, builder, loc);
        return;
    }
    if (slice.step == 1) {
        splitAt(reg, slice.offset, builder, loc);
        splitAt(reg, slice.offset + slice.count, builder, loc);
        return;
    }
    for (unsigned i = 0; i < slice.count; ++i)
        materializeQubit(reg, slice.getIndex(i), builder, loc);
}

llvm::SmallVector<QubitInterval> QASMScope::collectPartitions(
    const QuantumRegister &reg,
    const RegisterSlice &slice) const
{
    assert(slice.isValid(reg.size) && "invalid register slice");
    llvm::SmallVector<QubitInterval> partitions;
    if (slice.step == 1) {
        const unsigned end = slice.offset + slice.count;
        for (unsigned start = slice.offset; start < end;) {
            const auto &interval = reg.intervals.lookup(start);
            assert(
                interval.start == start && interval.end <= end
                && "selection boundaries must be refined first");
            partitions.push_back(interval);
            start = interval.end;
        }
    } else {
        for (unsigned i = 0; i < slice.count; ++i) {
            const auto &interval = reg.intervals.lookup(slice.getIndex(i));
            assert(
                interval.size() == 1
                && "stepped selections must be isolated first");
            partitions.push_back(interval);
        }
    }
    return partitions;
}

QASMScope::QuantumSelection QASMScope::materializeRegister(
    QuantumRegister &reg,
    const RegisterSlice &slice,
    mlir::OpBuilder &builder,
    mlir::Location loc)
{
    refineSlice(reg, slice, builder, loc);
    auto partitions = collectPartitions(reg, slice);
    if (partitions.size() == 1) return {partitions.front().value, slice};
    llvm::SmallVector<mlir::Value> values;
    for (const auto &partition : partitions) values.push_back(partition.value);
    auto merged = mlir::quantum::MergeOp::create(
        builder,
        loc,
        mlir::quantum::QubitType::get(builder.getContext(), slice.count),
        values);
    if (slice.step == 1) {
        // A contiguous selection can remain assembled in the register map.
        reg.intervals.coalesce(
            slice.offset,
            slice.offset + slice.count,
            merged.getResult());
    }
    return {merged.getResult(), slice};
}

void QASMScope::updateRegister(
    QuantumRegister &reg,
    const QuantumSelection &selection,
    mlir::Value result,
    mlir::OpBuilder &builder,
    mlir::Location loc)
{
    const auto &slice = selection.slice;
    assert(slice.isValid(reg.size) && "invalid register slice");
    assert(result && result.getType() == selection.value.getType());
    if (slice.step == 1 || slice.count == 1) {
        reg.updateInterval(slice.offset, result);
        return;
    }
    // Scatter the operation's result back into the original register layout.
    llvm::SmallVector<mlir::Type> types(
        slice.count,
        mlir::quantum::QubitType::get(builder.getContext(), 1));
    auto split = mlir::quantum::SplitOp::create(builder, loc, types, result);
    for (unsigned i = 0; i < slice.count; ++i)
        reg.updateQubit(slice.getIndex(i), split->getResult(i));
}

namespace {

mlir::RankedTensorType getRegisterType(
    const QASMScope::ClassicalRegister &reg,
    mlir::OpBuilder &builder)
{
    assert(reg.value && "classical register must be initialized");
    auto type = mlir::dyn_cast<mlir::RankedTensorType>(reg.value.getType());
    assert(
        type && type.getRank() == 1 && type.getDimSize(0) == reg.size
        && type.getContext() == builder.getContext()
        && "expected a register tensor in the builder's context");
    return type;
}

mlir::Value extractBits(
    mlir::Value value,
    unsigned offset,
    unsigned count,
    int64_t step,
    mlir::OpBuilder &builder,
    mlir::Location loc)
{
    return mlir::tensor::ExtractSliceOp::create(
               builder,
               loc,
               value,
               llvm::ArrayRef<mlir::OpFoldResult>{builder.getIndexAttr(offset)},
               llvm::ArrayRef<mlir::OpFoldResult>{builder.getIndexAttr(count)},
               llvm::ArrayRef<mlir::OpFoldResult>{builder.getIndexAttr(step)})
        .getResult();
}

mlir::Value insertBits(
    mlir::Value source,
    mlir::Value destination,
    unsigned offset,
    unsigned count,
    int64_t step,
    mlir::OpBuilder &builder,
    mlir::Location loc)
{
    return mlir::tensor::InsertSliceOp::create(
               builder,
               loc,
               source,
               destination,
               llvm::ArrayRef<mlir::OpFoldResult>{builder.getIndexAttr(offset)},
               llvm::ArrayRef<mlir::OpFoldResult>{builder.getIndexAttr(count)},
               llvm::ArrayRef<mlir::OpFoldResult>{builder.getIndexAttr(step)})
        .getResult();
}

} // namespace

mlir::Value QASMScope::materializeRegister(
    const ClassicalRegister &reg,
    const RegisterSlice &slice,
    mlir::OpBuilder &builder,
    mlir::Location loc)
{
    assert(slice.isValid(reg.size) && "invalid classical selection");
    auto type = getRegisterType(reg, builder);
    if (slice.offset == 0 && slice.count == reg.size && slice.step == 1)
        return reg.value;
    if (slice.step > 0)
        return extractBits(
            reg.value,
            slice.offset,
            slice.count,
            slice.step,
            builder,
            loc);
    mlir::Value result = mlir::tensor::EmptyOp::create(
        builder,
        loc,
        llvm::ArrayRef<int64_t>{slice.count},
        type.getElementType());
    for (unsigned i = 0; i < slice.count; ++i) {
        auto bit =
            extractBits(reg.value, slice.getIndex(i), 1, 1, builder, loc);
        result = insertBits(bit, result, i, 1, 1, builder, loc);
    }
    return result;
}

void QASMScope::updateRegister(
    ClassicalRegister &reg,
    const RegisterSlice &slice,
    mlir::Value result,
    mlir::OpBuilder &builder,
    mlir::Location loc)
{
    assert(slice.isValid(reg.size) && result && reg.value);
    [[maybe_unused]] auto type = getRegisterType(reg, builder);
    assert(
        result.getType()
        == mlir::RankedTensorType::get({slice.count}, type.getElementType()));
    if (slice.offset == 0 && slice.count == reg.size && slice.step == 1) {
        reg.value = result;
        return;
    }
    if (slice.step > 0) {
        reg.value = insertBits(
            result,
            reg.value,
            slice.offset,
            slice.count,
            slice.step,
            builder,
            loc);
        return;
    }
    for (unsigned i = 0; i < slice.count; ++i) {
        auto bit = extractBits(result, i, 1, 1, builder, loc);
        reg.value =
            insertBits(bit, reg.value, slice.getIndex(i), 1, 1, builder, loc);
    }
}

} // namespace quantum::frontend
