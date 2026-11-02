//===---- QASM3Frontend.cpp -  OpenQASM 3 Frontend ----------------------===//
//
// @author  Lars Schütze (lars.schuetze@tu-dresden.de)
//===----------------------------------------------------------------------===//

#include "QASM3Frontend.h"

#include "QASM3TranslationUnit.h"
#include "QASM3Visitor.h"
#include "quantum-mlir/Dialect/QPU/IR/QPUOps.h"
#include "quantum-mlir/Dialect/Quantum/IR/QuantumOps.h"

#include <antlr4-runtime.h>
#include <llvm/ADT/SmallVector.h>
#include <llvm/Support/Path.h>
#include <mlir/Dialect/Arith/IR/Arith.h>
#include <mlir/Dialect/Func/IR/FuncOps.h>
#include <mlir/Dialect/SCF/IR/SCF.h>
#include <mlir/Dialect/Tensor/IR/Tensor.h>
#include <mlir/IR/Builders.h>
#include <mlir/IR/BuiltinTypes.h>
#include <mlir/IR/Diagnostics.h>
#include <mlir/IR/Location.h>

namespace quantum::frontend::qasm3 {

mlir::OwningOpRef<mlir::ModuleOp> parseQASM3(
    llvm::StringRef source,
    llvm::StringRef filename,
    mlir::MLIRContext &context)
{
    QASM3TranslationUnit translationUnit;
    auto &rootSource = translationUnit.addSource(context, source, filename);
    if (rootSource.failed()) return {};

    auto* program = rootSource.parseProgram();
    if (!program || rootSource.failed()) return {};

    auto moduleLoc = mlir::FileLineColLoc::get(&context, filename, 1, 1);

    mlir::OwningOpRef<mlir::ModuleOp> module =
        mlir::ModuleOp::create(moduleLoc);

    mlir::OpBuilder builder(&context);
    builder.setInsertionPointToEnd(module->getBody());
    auto qpuModule = mlir::qpu::QPUModuleOp::create(
        builder,
        moduleLoc,
        {},
        llvm::sys::path::stem(filename),
        mlir::ArrayAttr{});
    qpuModule.getBodyRegion().emplaceBlock();

    builder.setInsertionPointToEnd(qpuModule.getBody());
    auto ty = mlir::FunctionType::get(&context, {}, {});
    auto mainCircuit = mlir::qpu::CircuitOp::create(
        builder,
        moduleLoc,
        "main",
        ty,
        mlir::ArrayRef<mlir::NamedAttribute>{});
    mainCircuit.getBody().emplaceBlock();

    // Shared state for this QASM translation unit.
    QASMScope scope;

    QASM3Visitor
        visitor(context, *module, qpuModule, mainCircuit, filename, scope);

    visitor.visit(program);

    if (visitor.failed()) return {};

    return module;
}

} // namespace quantum::frontend::qasm3
