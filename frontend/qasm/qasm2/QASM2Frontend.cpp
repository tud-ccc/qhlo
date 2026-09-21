//===---- QASM2Frontend.h -  OpenQASM 2.0 Quantum Frontend ----------------===//
//
// @author  Lars Schütze (lars.schuetze@tu-dresden.de)
//===----------------------------------------------------------------------===//

#include "QASM2Frontend.h"

#include "QASM2Visitor.h"
#include "QELib1.h"
#include "quantum-mlir/Dialect/QPU/IR/QPUOps.h"

#include <antlr4-runtime.h>
#include <mlir/Dialect/Arith/IR/Arith.h>
#include <mlir/Dialect/SCF/IR/SCF.h>
#include <mlir/Dialect/Tensor/IR/Tensor.h>
#include <mlir/IR/Builders.h>
#include <mlir/IR/BuiltinTypes.h>
#include <mlir/IR/Diagnostics.h>
#include <mlir/IR/Location.h>

namespace quantum::frontend {

mlir::OwningOpRef<mlir::ModuleOp> parseQASM2(
    llvm::StringRef source,
    llvm::StringRef filename,
    mlir::MLIRContext &context)
{
    auto moduleLoc = mlir::FileLineColLoc::get(&context, filename, 1, 1);

    mlir::OwningOpRef<mlir::ModuleOp> module =
        mlir::ModuleOp::create(moduleLoc);

    mlir::OpBuilder builder(&context);
    builder.setInsertionPointToEnd(module->getBody());
    auto qpuModule = mlir::qpu::QPUModuleOp::create(
        builder,
        moduleLoc,
        {},
        "qasm_generated",
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
    GateLibrary gateLibrary;
    QASMIncludeResolver includeResolver;
    qasm2::QASM2TranslationUnit translationUnit;

    includeResolver.addBuiltin(
        "qelib1.inc",
        qasm2::getQELib1Source(),
        "<qelib1.inc>");

    auto &rootSource = translationUnit.addSource(context, source, filename);
    if (rootSource.failed()) return {};

    auto* program = rootSource.parseProgram();

    if (rootSource.failed()) return {};

    QASM2Visitor visitor(
        context,
        *module,
        qpuModule,
        mainCircuit,
        filename,
        scope,
        gateLibrary,
        includeResolver,
        translationUnit);

    visitor.visit(program);

    if (visitor.failed()) return {};

    return module;
}

} // namespace quantum::frontend
