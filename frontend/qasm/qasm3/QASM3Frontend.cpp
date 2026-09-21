//===---- QASM3Frontend.cpp -  OpenQASM 3 Frontend ----------------------===//
//
// @author  Lars Schütze (lars.schuetze@tu-dresden.de)
//===----------------------------------------------------------------------===//

#include "QASM3Frontend.h"

mlir::OwningOpRef<mlir::ModuleOp> quantum::frontend::parseQASM3(
    llvm::StringRef,
    llvm::StringRef filename,
    mlir::MLIRContext &context)
{
    mlir::emitError(mlir::FileLineColLoc::get(&context, filename, 1, 1))
        << "OpenQASM 3 frontend is not implemented";
    return {};
}
