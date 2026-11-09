//===---- QuantumOpsTest.cpp - Quantum operation builder tests -----------===//
//
// @author  Lars Schütze (lars.schuetze@tu-dresden.de)
//===----------------------------------------------------------------------===//

#include "quantum-mlir/Dialect/Quantum/IR/QuantumOps.h"

#include <doctest/doctest.h>
#include <llvm/ADT/SmallVector.h>
#include <mlir/IR/BuiltinOps.h>
#include <mlir/IR/Verifier.h>

TEST_CASE(
    "Controlled-region builder derives the signature from controls and targets")
{
    for (unsigned controlCount : {1u, 2u}) {
        for (bool hasTargets : {false, true}) {
            mlir::MLIRContext context;
            context.loadDialect<mlir::quantum::QuantumDialect>();
            mlir::OpBuilder builder(&context);
            const auto loc = builder.getUnknownLoc();
            mlir::OwningOpRef<mlir::ModuleOp> module =
                mlir::ModuleOp::create(loc);
            builder.setInsertionPointToEnd(module->getBody());
            auto allocate = [&](unsigned width) -> mlir::Value {
                return mlir::quantum::AllocOp::create(
                           builder,
                           loc,
                           mlir::quantum::QubitType::get(&context, width),
                           mlir::IntegerAttr{})
                    .getResult();
            };
            llvm::SmallVector<mlir::Value> controls;
            for (unsigned i = 0; i < controlCount; ++i)
                controls.push_back(allocate(1));
            llvm::SmallVector<mlir::Value> targets;
            if (hasTargets) targets = {allocate(1), allocate(3)};

            auto* insertionBlock = builder.getInsertionBlock();
            auto control =
                mlir::quantum::CtrlOp::create(builder, loc, controls, targets);
            CHECK(builder.getInsertionBlock() == insertionBlock);
            CHECK(builder.getInsertionPoint() == insertionBlock->end());
            CHECK(control.getNctrls().getZExtValue() == controlCount);
            REQUIRE(
                control.getNumOperands() == controls.size() + targets.size());
            REQUIRE(control.getNumResults() == control.getNumOperands());
            for (unsigned i = 0; i < controls.size(); ++i)
                CHECK(control.getOperand(i) == controls[i]);
            for (unsigned i = 0; i < targets.size(); ++i)
                CHECK(control.getOperand(controlCount + i) == targets[i]);
            for (unsigned i = 0; i < control.getNumResults(); ++i)
                CHECK(
                    control->getResult(i).getType()
                    == control.getOperand(i).getType());
            REQUIRE(control.getBody().hasOneBlock());
            auto &block = control.getBody().front();
            REQUIRE(block.getNumArguments() == targets.size());
            CHECK(block.empty());
            for (unsigned i = 0; i < targets.size(); ++i) {
                CHECK(block.getArgument(i).getType() == targets[i].getType());
                CHECK(block.getArgument(i).getLoc() == loc);
            }
            {
                mlir::OpBuilder::InsertionGuard guard(builder);
                builder.setInsertionPointToEnd(&block);
                mlir::quantum::YieldOp::create(
                    builder,
                    loc,
                    block.getArguments());
            }
            for (mlir::Value result : control.getResults())
                mlir::quantum::DeallocateOp::create(builder, loc, result);
            CHECK(mlir::succeeded(mlir::verify(*module)));
        }
    }
}
