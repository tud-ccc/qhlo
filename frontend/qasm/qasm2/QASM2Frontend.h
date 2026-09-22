//===---- QASM2Frontend.h -  OpenQASM 2.0 Quantum Frontend ----------------===//
//
// @author  Lars Schütze (lars.schuetze@tu-dresden.de)
//===----------------------------------------------------------------------===//

#ifndef QUANTUM_MLIR_FRONTEND_QASM_QASM2_QASM2FRONTEND_H
#define QUANTUM_MLIR_FRONTEND_QASM_QASM2_QASM2FRONTEND_H

#include <llvm/ADT/StringRef.h>
#include <mlir/IR/BuiltinOps.h>
#include <mlir/IR/OwningOpRef.h>

namespace quantum::frontend {

mlir::OwningOpRef<mlir::ModuleOp> parseQASM2(
    llvm::StringRef source,
    llvm::StringRef filename,
    mlir::MLIRContext &context);

} // namespace quantum::frontend

#endif // QUANTUM_MLIR_FRONTEND_QASM_QASM2_QASM2FRONTEND_H
