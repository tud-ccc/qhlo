//===---- QASM3Frontend.h -  OpenQASM 3.x Quantum Frontend ----------------===//
//
// @author  Lars Schütze (lars.schuetze@tu-dresden.de)
//===----------------------------------------------------------------------===//

#ifndef QUANTUM_MLIR_FRONTEND_QASM_QASM3_QASM3FRONTEND_H
#define QUANTUM_MLIR_FRONTEND_QASM_QASM3_QASM3FRONTEND_H

#include <llvm/ADT/StringRef.h>
#include <mlir/IR/BuiltinOps.h>
#include <mlir/IR/OwningOpRef.h>

namespace quantum::frontend::qasm3 {

mlir::OwningOpRef<mlir::ModuleOp> parseQASM3(
    llvm::StringRef source,
    llvm::StringRef filename,
    mlir::MLIRContext &context);

} // namespace quantum::frontend::qasm3

#endif // QUANTUM_MLIR_FRONTEND_QASM_QASM3_QASM3FRONTEND_H
