//===---- QASMScope.h -  OpenQASM Register Scope ------------------------===//
//
// @author  Lars Schütze (lars.schuetze@tu-dresden.de)
//===----------------------------------------------------------------------===//

#ifndef QUANTUM_MLIR_FRONTEND_QASM_COMMON_QASMSCOPE_H
#define QUANTUM_MLIR_FRONTEND_QASM_COMMON_QASMSCOPE_H

#include "IntervalMap.h"
#include "RegisterSlice.h"

#include <llvm/ADT/SmallVector.h>
#include <llvm/ADT/StringMap.h>
#include <mlir/IR/Builders.h>
#include <mlir/IR/BuiltinAttributes.h>
#include <mlir/IR/Value.h>
#include <variant>

namespace quantum::frontend {

class QASMScope {
public:
    explicit QASMScope(QASMScope* parent = nullptr) : parent(parent) {}
    QASMScope(const QASMScope &) = delete;
    QASMScope &operator=(const QASMScope &) = delete;

    struct QuantumRegister {
        unsigned size;
        // Scalar qubits broadcast differently from one-element registers.
        bool isScalar = false;

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

    struct Variable {
        mlir::Value value;
    };

    struct Constant {
        mlir::TypedAttr value;
    };

    // Gate bodies remain owned by the translation unit and GateLibrary.
    struct Gate {};

    struct Declaration {
        using Payload = std::variant<
            QuantumRegister*,
            ClassicalRegister*,
            Variable,
            Constant,
            Gate>;
        Payload payload;
        mlir::LocationAttr location;
    };

    // The declaration map is the sole authority for name lookup and collisions.
    const llvm::StringMap<Declaration> &getDeclarations() const
    { return declarations; }

    Declaration* lookupLocal(llvm::StringRef name);
    const Declaration* lookupLocal(llvm::StringRef name) const;
    Declaration* lookup(llvm::StringRef name);
    const Declaration* lookup(llvm::StringRef name) const;

    [[nodiscard]] Variable* declareVariable(
        llvm::StringRef name,
        mlir::Value value,
        mlir::LocationAttr location = {});
    [[nodiscard]] Constant* declareConstant(
        llvm::StringRef name,
        mlir::TypedAttr value,
        mlir::LocationAttr location = {});
    [[nodiscard]] Gate*
    declareGate(llvm::StringRef name, mlir::LocationAttr location = {});

    // Describes an assembled quantum operand and its original selection.
    // After assembly, callers must restore its result before accessing the
    // selected intervals again. Other operands must select disjoint qubits.
    struct QuantumSelection {
        mlir::Value value;
        RegisterSlice slice;
    };

    void splitAt(
        QuantumRegister &reg,
        unsigned boundary,
        mlir::OpBuilder &builder,
        mlir::Location loc);

    // Slice operations require a nonempty selection validated against reg.size.
    // Introduces only selection boundaries, retaining existing partitions.
    void refineSlice(
        QuantumRegister &reg,
        const RegisterSlice &slice,
        mlir::OpBuilder &builder,
        mlir::Location loc);

    // Call after refining every operand; returned partitions follow selection
    // order and contain only current SSA values.
    llvm::SmallVector<QubitInterval> collectPartitions(
        const QuantumRegister &reg,
        const RegisterSlice &slice) const;

    // Refine all disjoint operands before assembling any of their values.
    QuantumSelection materializeRegister(
        QuantumRegister &reg,
        const RegisterSlice &slice,
        mlir::OpBuilder &builder,
        mlir::Location loc);

    void updateRegister(
        QuantumRegister &reg,
        const QuantumSelection &selection,
        mlir::Value result,
        mlir::OpBuilder &builder,
        mlir::Location loc);

    // Classical selections require an initialized rank-one register tensor.
    mlir::Value materializeRegister(
        const ClassicalRegister &reg,
        const RegisterSlice &slice,
        mlir::OpBuilder &builder,
        mlir::Location loc);

    void updateRegister(
        ClassicalRegister &reg,
        const RegisterSlice &slice,
        mlir::Value result,
        mlir::OpBuilder &builder,
        mlir::Location loc);

    QuantumRegister* lookupQReg(llvm::StringRef name);
    ClassicalRegister* lookupCReg(llvm::StringRef name);

    // Checks the current scope so declarations may shadow outer bindings.
    bool contains(llvm::StringRef name) const;

    const llvm::StringMap<QuantumRegister> &getQRegs() const { return qregs_; }

    const llvm::StringMap<ClassicalRegister> &getCRegs() const
    { return cregs_; }

    // Declarations return null on a name collision with any declaration kind
    // and leave the existing register unchanged.
    [[nodiscard]] QuantumRegister* declareQReg(
        llvm::StringRef name,
        unsigned size,
        mlir::Value initialValue,
        bool isScalar = false,
        mlir::LocationAttr location = {});

    [[nodiscard]] ClassicalRegister* declareCReg(
        llvm::StringRef name,
        unsigned size,
        mlir::Value initialValue,
        mlir::LocationAttr location = {});

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
    /// @pre index must be less than reg.size.
    /// @pre An interval within the register bounds must cover index.
    /// @pre The interval must hold a non-null qubit value whose width matches
    /// the interval size and whose context matches the builder's context.
    mlir::Value materializeQubit(
        QASMScope::QuantumRegister &reg,
        unsigned index,
        mlir::OpBuilder &builder,
        mlir::Location loc);

private:
    QASMScope* parent;
    llvm::StringMap<Declaration> declarations;
    // Register maps own lowering state and support register-only iteration.
    llvm::StringMap<QuantumRegister> qregs_;
    llvm::StringMap<ClassicalRegister> cregs_;
};

} // namespace quantum::frontend

#endif // QUANTUM_MLIR_FRONTEND_QASM_COMMON_QASMSCOPE_H
