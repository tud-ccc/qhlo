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
        IntervalMap intervals;
    };

    struct ClassicalRegister {
        unsigned size;
        mlir::Value value;
    };

    QuantumRegister* lookupQReg(llvm::StringRef name);
    ClassicalRegister* lookupCReg(llvm::StringRef name);

    QuantumRegister &
    declareQReg(llvm::StringRef name, unsigned size, mlir::Value initialValue);

    ClassicalRegister &
    declareCReg(llvm::StringRef name, unsigned size, mlir::Value initialValue);

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
