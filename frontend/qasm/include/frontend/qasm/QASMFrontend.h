//===---- QASMFrontend.h -  OpenQASM 2.0 / 3.x Quantum Frontend -----------===//
//
// @author  Lars Schütze (lars.schuetze@tu-dresden.de)
//===----------------------------------------------------------------------===//

#ifndef QUANTUM_MLIR_FRONTEND_QASM_QASMFRONTEND_H
#define QUANTUM_MLIR_FRONTEND_QASM_QASMFRONTEND_H

#include <llvm/ADT/StringRef.h>
#include <mlir/IR/BuiltinOps.h>
#include <mlir/IR/OwningOpRef.h>

namespace quantum::frontend {

mlir::OwningOpRef<mlir::ModuleOp> parseQASM(
    llvm::StringRef source,
    llvm::StringRef filename,
    mlir::MLIRContext &context);

} // namespace quantum::frontend

#endif // QUANTUM_MLIR_FRONTEND_QASM_QASMFRONTEND_H
