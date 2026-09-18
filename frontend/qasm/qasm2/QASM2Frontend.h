//===---- QASM2Frontend.h -  OpenQASM 2.0 Quantum Frontend ----------------===//
//
// @author  Lars Schütze (lars.schuetze@tu-dresden.de)
//===----------------------------------------------------------------------===//

#pragma once

#include "mlir/IR/BuiltinOps.h"
#include "mlir/IR/OwningOpRef.h"

#include "llvm/ADT/StringRef.h"

namespace quantum::frontend {

mlir::OwningOpRef<mlir::ModuleOp> parseQASM2(
    llvm::StringRef source,
    llvm::StringRef filename,
    mlir::MLIRContext &context);

} // namespace quantum::frontend
