//===---- RegisterSlice.h - Register selections -----------------------===//
//
// @author  Lars Schütze (lars.schuetze@tu-dresden.de)
//===----------------------------------------------------------------------===//

#ifndef QUANTUM_MLIR_FRONTEND_QASM_COMMON_REGISTERSLICE_H
#define QUANTUM_MLIR_FRONTEND_QASM_COMMON_REGISTERSLICE_H

#include <cassert>
#include <cstdint>

namespace quantum::frontend {

// A nonempty selection in register order or reverse order. Consumers must
// validate it against the register size before accessing its indices.
struct RegisterSlice {
    unsigned offset;
    unsigned count;
    int64_t step;

    bool isValid(unsigned registerSize) const
    {
        if (!count || !step || offset >= registerSize) return false;
        if (count == 1) return true;
        if (step > 0)
            return static_cast<uint64_t>(step)
                   <= (registerSize - 1 - offset) / (count - 1);
        const uint64_t magnitude = static_cast<uint64_t>(-(step + 1)) + 1;
        return magnitude <= offset / (count - 1);
    }

    unsigned getIndex(unsigned position) const
    {
        assert(position < count && "register slice position is out of bounds");
        return static_cast<unsigned>(
            static_cast<int64_t>(offset)
            + static_cast<int64_t>(position) * step);
    }

    RegisterSlice inAscendingOrder() const
    {
        assert(count && step && "expected a nonempty register slice");
        if (step > 0) return *this;
        return {getIndex(count - 1), count, count == 1 ? 1 : -step};
    }
};

} // namespace quantum::frontend

#endif // QUANTUM_MLIR_FRONTEND_QASM_COMMON_REGISTERSLICE_H
