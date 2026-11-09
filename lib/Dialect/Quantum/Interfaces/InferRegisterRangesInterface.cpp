//===- InferRegisterRangesInterface.cpp -  Register inference interface ---===//
//
// @author  Lars Schütze (lars.schuetze@tu-dresden.de)
//===----------------------------------------------------------------------===//

#include "quantum-mlir/Dialect/Quantum/Interfaces/InferRegisterRangesInterface.h"

#include "quantum-mlir/Dialect/Quantum/IR/QuantumTypes.h"
#include "quantum-mlir/Dialect/Quantum/Interfaces/InferRegisterRangesInterface.cpp.inc"

#include <llvm/ADT/APInt.h>
#include <llvm/ADT/STLExtras.h>
#include <llvm/ADT/SmallVector.h>
#include <mlir/Interfaces/InferIntRangeInterface.h>

using namespace mlir;
using namespace mlir::quantum;

void mlir::quantum::registerrange::detail::defaultInferResultRanges(
    InferRegisterRangesInterface interface,
    ArrayRef<RegisterRanges> argRanges,
    SetRangeFn setResultRanges)
{
    // Standard implementation passes for each input operand its analysis result
    // to the corresponding result value
    for (auto &&[result, range] : llvm::zip(interface->getResults(), argRanges))
        if (llvm::isa<QubitType>(result.getType()))
            setResultRanges(result, range);
}

bool ConstantRegisterRanges::operator==(
    const ConstantRegisterRanges &other) const
{
    return getRegisterValue() == other.getRegisterValue()
           && getRanges() == other.getRanges();
}

const Value ConstantRegisterRanges::getRegisterValue() const { return value; }

const ConstantIntRanges ConstantRegisterRanges::getRanges() const
{ return ranges; }

raw_ostream &
mlir::quantum::operator<<(raw_ostream &os, const ConstantRegisterRanges &range)
{ return os << range.getRegisterValue() << " -> " << range.getRanges(); }

raw_ostream &
mlir::quantum::operator<<(raw_ostream &os, const RegisterRanges &range)
{
    range.print(os);
    return os;
}

/// Return a copy of *this with only the first \p N elements.
RegisterRanges RegisterRanges::take_front(size_t N) const
{
    llvm::APInt n(64, N);
    llvm::APInt zero(64, 0);
    size_t i = 0;
    llvm::SmallVector<ConstantRegisterRanges, 4> values;
    // While n > 0 extract elements
    while (n.ugt(zero)) {
        ConstantIntRanges range = this->getValue()[i].getRanges();
        llvm::APInt min = range.umin();
        llvm::APInt max = range.umax();
        ConstantIntRanges intersect =
            range.intersection({min, min + n, min, min + n});
        ConstantRegisterRanges extracted = ConstantRegisterRanges(
            this->getValue()[i].getRegisterValue(),
            intersect);
        values.push_back(extracted);
        // Update index values
        i++;
        // Decrease by amount of elements inside the intersection
        n -= intersect.umax() - intersect.umin();
    }
    RegisterRanges result(values);
    return result;
}

/// Return a copy of *this with only the last \p size() \p - \p N elements.
RegisterRanges RegisterRanges::drop_front(size_t N) const
{
    llvm::APInt n(64, N);
    size_t i = 0;
    llvm::SmallVector<ConstantRegisterRanges, 4> values;
    // While n > 0 extract elements
    while (n.ugt(0)) {
        // Access the current register ranges
        const ConstantRegisterRanges current = this->getValue()[i];
        // Access the int range
        const ConstantIntRanges range = current.getRanges();
        llvm::APInt min = range.umin();
        llvm::APInt max = range.umax();
        // Intersect the current range (min, max) with (min, min+n)
        ConstantIntRanges intersect =
            range.intersection({min, min + n, min, min + n});
        llvm::APInt diff = intersect.umax() - intersect.umin();
        // Decrease by amount of elements inside the intersection
        n -= diff;
        // Check the following cases:
        // 1. Is n > 0 and max == intersect.max? Next please! We need to
        // go deeper
        if (n.ugt(0) && max == intersect.umax()) {
            i++;
        }
        // 2. Is n == 0? Then we reached the end.
        else if (n == 0) {
            // 2.1. Is diff = max - min? Then we start assembling from the next
            // range
            if (diff == (max - min)) {
                ++i;
                break;
            } else {
                // 2.2. Is diff < max - min? Then we need to store
                // (min+diff, max) and do the rest
                llvm::APInt restMin = min + diff;
                ConstantRegisterRanges rest(
                    current.getRegisterValue(),
                    {restMin, max, restMin, max});
                values.push_back(rest);
                ++i;
                break;
            }
        }
    }
    // add all remaining values
    auto rest = this->getValue().slice(i);
    values.append(rest.begin(), rest.end());
    return RegisterRanges(values);
}
