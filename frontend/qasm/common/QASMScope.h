//===---- QASMScope.h -  OpenQASM Register Scope ------------------------===//
//
// @author  Lars Schütze (lars.schuetze@tu-dresden.de)
//===----------------------------------------------------------------------===//

#ifndef QUANTUM_MLIR_FRONTEND_QASM_COMMON_QASMSCOPE_H
#define QUANTUM_MLIR_FRONTEND_QASM_COMMON_QASMSCOPE_H

#include "IntervalMap.h"

#include <llvm/ADT/StringMap.h>
#include <mlir/IR/Builders.h>
#include <mlir/IR/Value.h>

namespace quantum::frontend {

class QASMScope {
public:
    struct QuantumRegister {
        unsigned size;

        // Returns a null value when the register has been split.
        mlir::Value getWholeRegisterValue() const;

        // The indexed qubit must already have been materialized.
        mlir::Value getQubitValue(unsigned index) const;
        void updateQubit(unsigned index, mlir::Value value);

        // Replaces the value of an existing interval without changing its
        // range.
        void updateInterval(unsigned start, mlir::Value value);

        // Replaces all intervals with one value covering the entire register.
        void updateWholeRegister(mlir::Value value);

        auto getIntervals() const { return intervals.intervals(); }

    private:
        friend class QASMScope;
        IntervalMap intervals;
    };

    struct ClassicalRegister {
        unsigned size;
        mlir::Value value;
    };

    QuantumRegister* lookupQReg(llvm::StringRef name);
    ClassicalRegister* lookupCReg(llvm::StringRef name);

    bool contains(llvm::StringRef name) const;

    const llvm::StringMap<QuantumRegister> &getQRegs() const { return qregs_; }

    const llvm::StringMap<ClassicalRegister> &getCRegs() const
    { return cregs_; }

    // Declarations return null on a name collision with either register kind
    // and leave the existing register unchanged.
    [[nodiscard]] QuantumRegister*
    declareQReg(llvm::StringRef name, unsigned size, mlir::Value initialValue);

    [[nodiscard]] ClassicalRegister*
    declareCReg(llvm::StringRef name, unsigned size, mlir::Value initialValue);

    /// @brief Materializes a single qubit, splitting its register interval if
    /// needed.
    ///
    /// @param reg Quantum register whose intervals are updated after a split.
    /// @param index Zero-based index of the qubit within the register.
    /// @param builder Builder used to emit a split at its current insertion
    /// point.
    /// @param loc Source location assigned to the emitted split operation.
    /// @return The single-qubit value at index, reusing an existing value when
    /// already isolated.
    /// @pre index must be covered by an interval in reg.
    mlir::Value materializeQubit(
        QASMScope::QuantumRegister &reg,
        unsigned index,
        mlir::OpBuilder &builder,
        mlir::Location loc);

private:
    llvm::StringMap<QuantumRegister> qregs_;
    llvm::StringMap<ClassicalRegister> cregs_;
};

} // namespace quantum::frontend

#endif // QUANTUM_MLIR_FRONTEND_QASM_COMMON_QASMSCOPE_H
