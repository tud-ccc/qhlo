//===---- IntervalMap.h -  Qubit Interval Mapping -----------------------===//
//
// @author  Lars Schütze (lars.schuetze@tu-dresden.de)
//===----------------------------------------------------------------------===//

#ifndef QUANTUM_MLIR_FRONTEND_QASM_COMMON_INTERVALMAP_H
#define QUANTUM_MLIR_FRONTEND_QASM_COMMON_INTERVALMAP_H

#include <llvm/ADT/ArrayRef.h>
#include <llvm/ADT/STLExtras.h>
#include <llvm/Support/ErrorHandling.h>
#include <map>
#include <mlir/IR/Value.h>

namespace quantum::frontend {

struct QubitInterval {
    unsigned start;
    unsigned end; // exclusive
    mlir::Value value;

    unsigned size() const { return end - start; }

    bool contains(unsigned index) const
    { return start <= index && index < end; }
};

// Stores MLIR values in half-open qubit intervals [start, end), ordered and
// keyed by their start index in a map.
class IntervalMap {
public:
    QubitInterval &lookup(unsigned index)
    {
        auto it = intervals_.upper_bound(index);
        if (it != intervals_.begin() && (--it)->second.contains(index))
            return it->second;
        llvm_unreachable("qubit index is outside the interval partition");
    }

    auto intervals() const
    {
        return llvm::map_range(
            intervals_,
            [](const auto &entry) -> const QubitInterval & {
                return entry.second;
            });
    }

    void replace(
        const QubitInterval &oldInterval,
        llvm::ArrayRef<QubitInterval> newIntervals)
    {
        auto it = intervals_.upper_bound(oldInterval.start);
        if (it == intervals_.begin()
            || !(--it)->second.contains(oldInterval.start))
            llvm_unreachable("qubit index is outside the interval partition");
        auto hint = intervals_.erase(it);
        for (auto interval = newIntervals.rbegin();
             interval != newIntervals.rend();
             ++interval)
            hint = intervals_.emplace_hint(hint, interval->start, *interval);
    }

    void set(unsigned start, unsigned end, mlir::Value value)
    {
        intervals_.clear();
        intervals_.emplace(start, QubitInterval{start, end, value});
    }

private:
    std::map<unsigned, QubitInterval> intervals_;
};

} // namespace quantum::frontend

#endif // QUANTUM_MLIR_FRONTEND_QASM_COMMON_INTERVALMAP_H
