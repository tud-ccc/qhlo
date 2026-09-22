//===---- QASM2Frontend.h -  OpenQASM 2.0 Quantum Frontend ----------------===//
//
// @author  Lars Schütze (lars.schuetze@tu-dresden.de)
//===----------------------------------------------------------------------===//

#include "QASM2Frontend.h"

#include "QASM2Visitor.h"
#include "QELib1.h"
#include "quantum-mlir/Dialect/QPU/IR/QPUOps.h"

#include <antlr4-runtime.h>
#include <llvm/ADT/SmallVector.h>
#include <mlir/Dialect/Arith/IR/Arith.h>
#include <mlir/Dialect/Func/IR/FuncOps.h>
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

    llvm::SmallVector<mlir::Value> returnValues;
    llvm::SmallVector<mlir::Type> returnTypes;
    for (const auto &entry : scope.getCRegs()) {
        auto value = entry.getValue().value;
        if (!value) continue;
        returnValues.push_back(value);
        returnTypes.push_back(value.getType());
    }

    builder.setInsertionPointToEnd(&mainCircuit.getBody().front());
    mlir::qpu::ReturnOp::create(builder, moduleLoc, returnValues);
    mainCircuit.setFunctionType(
        mlir::FunctionType::get(&context, {}, returnTypes));

    builder.setInsertionPointToEnd(module->getBody());
    auto entryPoint = mlir::func::FuncOp::create(
        builder,
        moduleLoc,
        "qasm_main",
        mlir::FunctionType::get(&context, {}, returnTypes));
    builder.setInsertionPointToStart(entryPoint.addEntryBlock());

    llvm::SmallVector<mlir::Value> outputs;
    outputs.reserve(returnTypes.size());
    for (auto type : returnTypes) {
        auto tensorType = mlir::cast<mlir::RankedTensorType>(type);
        outputs.push_back(
            mlir::tensor::EmptyOp::create(
                builder,
                moduleLoc,
                tensorType.getShape(),
                tensorType.getElementType()));
    }

    auto circuitRef = mlir::SymbolRefAttr::get(
        &context,
        qpuModule.getSymName(),
        {mlir::FlatSymbolRefAttr::get(&context, mainCircuit.getSymName())});
    auto execution = mlir::qpu::ExecuteOp::create(
        builder,
        moduleLoc,
        returnTypes,
        circuitRef,
        mlir::ValueRange{},
        outputs);
    mlir::func::ReturnOp::create(builder, moduleLoc, execution.getResults());

    return module;
}

} // namespace quantum::frontend
