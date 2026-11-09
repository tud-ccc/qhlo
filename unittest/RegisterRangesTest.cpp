//===---- RegisterRangesTest.cpp - Register range slicing tests -----------===//
//
// @author  Lars Schütze (lars.schuetze@tu-dresden.de)
//===----------------------------------------------------------------------===//

#include "quantum-mlir/Dialect/Quantum/IR/QuantumOps.h"
#include "quantum-mlir/Dialect/Quantum/Interfaces/InferRegisterRangesInterface.h"

#include <doctest/doctest.h>
#include <mlir/IR/Block.h>
#include <mlir/IR/Builders.h>

TEST_CASE("Register range slicing removes consumed intervals")
{
    mlir::MLIRContext context;
    context.loadDialect<mlir::quantum::QuantumDialect>();
    mlir::OpBuilder builder(&context);
    mlir::Block block;
    auto reg = block.addArgument(
        mlir::quantum::QubitType::get(&context, 6),
        builder.getUnknownLoc());
    auto range = [&](unsigned start, unsigned end) {
        llvm::APInt lower(64, start);
        llvm::APInt upper(64, end);
        return mlir::quantum::ConstantRegisterRanges(
            reg,
            {lower, upper, lower, upper});
    };
    const mlir::quantum::RegisterRanges ranges(
        llvm::ArrayRef<mlir::quantum::ConstantRegisterRanges>{
            range(0, 2),
            range(2, 6)});

    CHECK(ranges.drop_front(0) == ranges);
    CHECK(
        ranges.drop_front(1)
        == mlir::quantum::RegisterRanges(
            llvm::ArrayRef<mlir::quantum::ConstantRegisterRanges>{
                range(1, 2),
                range(2, 6)}));
    CHECK(ranges.drop_front(2) == mlir::quantum::RegisterRanges(range(2, 6)));
    CHECK(ranges.drop_front(3) == mlir::quantum::RegisterRanges(range(3, 6)));
    CHECK(ranges.drop_front(6).isUninitialized());
    CHECK(
        ranges.drop_front(2).take_front(2)
        == mlir::quantum::RegisterRanges(range(2, 4)));
}
