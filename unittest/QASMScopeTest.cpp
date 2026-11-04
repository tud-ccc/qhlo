//===---- QASMScopeTest.cpp - Register selection tests ------------------===//
//
// @author  Lars Schütze (lars.schuetze@tu-dresden.de)
//===----------------------------------------------------------------------===//

#include "QASMScope.h"

#include "RegisterSlice.h"
#include "quantum-mlir/Dialect/Quantum/IR/QuantumOps.h"

#include <doctest/doctest.h>
#include <limits>
#include <mlir/Dialect/Arith/IR/Arith.h>
#include <mlir/Dialect/Tensor/IR/Tensor.h>
#include <mlir/IR/BuiltinOps.h>
#include <mlir/IR/Verifier.h>

namespace {

struct ScopeFixture {
    mlir::MLIRContext context;
    mlir::OpBuilder builder{&context};
    mlir::Location loc = builder.getUnknownLoc();
    mlir::OwningOpRef<mlir::ModuleOp> module;
    quantum::frontend::QASMScope scope;

    ScopeFixture()
    {
        context.loadDialect<
            mlir::quantum::QuantumDialect,
            mlir::arith::ArithDialect,
            mlir::tensor::TensorDialect>();
        module = mlir::ModuleOp::create(loc);
        builder.setInsertionPointToEnd(module->getBody());
    }

    quantum::frontend::QASMScope::QuantumRegister &allocate(unsigned size)
    {
        auto alloc = mlir::quantum::AllocOp::create(
            builder,
            loc,
            mlir::quantum::QubitType::get(&context, size),
            mlir::IntegerAttr{});
        auto* reg = scope.declareQReg("q", size, alloc.getResult());
        REQUIRE(reg);
        return *reg;
    }
};

TEST_CASE("Contiguous selections preserve and then coalesce partitions")
{
    ScopeFixture f;
    auto &reg = f.allocate(8);
    f.scope.splitAt(reg, 4, f.builder, f.loc);
    quantum::frontend::RegisterSlice slice{2, 4, 1};
    f.scope.refineSlice(reg, slice, f.builder, f.loc);
    auto partitions = f.scope.materializePartitions(reg, slice);
    REQUIRE(partitions.size() == 2);
    CHECK(partitions[0].start == 2);
    CHECK(partitions[0].end == 4);
    CHECK(partitions[1].start == 4);
    CHECK(partitions[1].end == 6);
    CHECK(
        std::distance(reg.getIntervals().begin(), reg.getIntervals().end())
        == 4);

    auto selection = f.scope.materializeRegister(reg, slice, f.builder, f.loc);
    CHECK(
        std::distance(reg.getIntervals().begin(), reg.getIntervals().end())
        == 3);
    CHECK(
        std::distance(
            f.module->getOps<mlir::quantum::SplitOp>().begin(),
            f.module->getOps<mlir::quantum::SplitOp>().end())
        == 3);
    auto reset = mlir::quantum::ResetOp::create(
        f.builder,
        f.loc,
        selection.value.getType(),
        selection.value);
    f.scope.updateRegister(reg, selection, reset.getResult(), f.builder, f.loc);
    auto restored = f.scope.materializePartitions(reg, slice);
    REQUIRE(restored.size() == 1);
    CHECK(restored[0].start == 2);
    CHECK(restored[0].end == 6);
    CHECK(restored[0].value == reset.getResult());
    CHECK(mlir::succeeded(mlir::verify(*f.module)));
}

TEST_CASE("Existing boundaries and repeated materialization require no splits")
{
    ScopeFixture f;
    auto &reg = f.allocate(8);
    quantum::frontend::RegisterSlice all{0, 8, 1};
    f.scope.refineSlice(reg, all, f.builder, f.loc);
    auto first = f.scope.materializeRegister(reg, all, f.builder, f.loc);
    auto second = f.scope.materializeRegister(reg, all, f.builder, f.loc);
    CHECK(first.value == second.value);
    CHECK(f.module->getOps<mlir::quantum::SplitOp>().empty());
    CHECK(f.module->getOps<mlir::quantum::MergeOp>().empty());
}

TEST_CASE("Descending selections restore results to original qubit positions")
{
    ScopeFixture f;
    auto &reg = f.allocate(7);
    quantum::frontend::RegisterSlice slice{5, 3, -2};
    f.scope.refineSlice(reg, slice, f.builder, f.loc);
    const auto partitions = f.scope.materializePartitions(reg, slice);
    REQUIRE(partitions.size() == 3);
    auto selection = f.scope.materializeRegister(reg, slice, f.builder, f.loc);
    auto merged = selection.value.getDefiningOp<mlir::quantum::MergeOp>();
    REQUIRE(merged);
    REQUIRE(merged->getNumOperands() == 3);
    CHECK(merged->getOperand(0) == partitions[0].value);
    CHECK(merged->getOperand(1) == partitions[1].value);
    CHECK(merged->getOperand(2) == partitions[2].value);
    auto reset = mlir::quantum::ResetOp::create(
        f.builder,
        f.loc,
        selection.value.getType(),
        selection.value);
    f.scope.updateRegister(reg, selection, reset.getResult(), f.builder, f.loc);
    auto split = reg.getQubitValue(5).getDefiningOp<mlir::quantum::SplitOp>();
    REQUIRE(split);
    CHECK(split.getInput() == reset.getResult());
    CHECK(reg.getQubitValue(5) == split->getResult(0));
    CHECK(reg.getQubitValue(3) == split->getResult(1));
    CHECK(reg.getQubitValue(1) == split->getResult(2));
    CHECK(mlir::succeeded(mlir::verify(*f.module)));
}

TEST_CASE("One-element selections with non-unit steps restore one qubit")
{
    for (int64_t step :
         {int64_t{2}, int64_t{-2}, std::numeric_limits<int64_t>::min()}) {
        ScopeFixture f;
        auto &reg = f.allocate(3);
        quantum::frontend::RegisterSlice slice{1, 1, step};
        auto selection =
            f.scope.materializeRegister(reg, slice, f.builder, f.loc);
        auto reset = mlir::quantum::ResetOp::create(
            f.builder,
            f.loc,
            selection.value.getType(),
            selection.value);
        f.scope.updateRegister(
            reg,
            selection,
            reset.getResult(),
            f.builder,
            f.loc);
        CHECK(reg.getQubitValue(1) == reset.getResult());
        CHECK(
            std::distance(
                f.module->getOps<mlir::quantum::SplitOp>().begin(),
                f.module->getOps<mlir::quantum::SplitOp>().end())
            == 1);
        CHECK(mlir::succeeded(mlir::verify(*f.module)));
    }
}

TEST_CASE("Classical selections use tensors and preserve reversed order")
{
    ScopeFixture f;
    auto type = mlir::RankedTensorType::get({6}, f.builder.getI1Type());
    auto initial = mlir::arith::ConstantOp::create(
        f.builder,
        f.loc,
        type,
        mlir::DenseElementsAttr::get(type, f.builder.getBoolAttr(false)));
    auto* reg = f.scope.declareCReg("c", 6, initial.getResult());
    REQUIRE(reg);
    auto forward =
        f.scope.materializeRegister(*reg, {1, 3, 2}, f.builder, f.loc);
    auto extract = forward.getDefiningOp<mlir::tensor::ExtractSliceOp>();
    REQUIRE(extract);
    CHECK(extract.getStaticOffsets()[0] == 1);
    CHECK(extract.getStaticSizes()[0] == 3);
    CHECK(extract.getStaticStrides()[0] == 2);
    auto reverse =
        f.scope.materializeRegister(*reg, {5, 3, -2}, f.builder, f.loc);
    f.scope.updateRegister(*reg, {0, 3, 2}, reverse, f.builder, f.loc);
    auto insert = reg->value.getDefiningOp<mlir::tensor::InsertSliceOp>();
    REQUIRE(insert);
    CHECK(insert.getSource() == reverse);
    CHECK(insert.getStaticStrides()[0] == 2);
    f.scope.updateRegister(*reg, {5, 3, -2}, forward, f.builder, f.loc);
    insert = reg->value.getDefiningOp<mlir::tensor::InsertSliceOp>();
    CHECK(insert.getStaticOffsets()[0] == 1);
    auto lastBit =
        insert.getSource().getDefiningOp<mlir::tensor::ExtractSliceOp>();
    REQUIRE(lastBit);
    CHECK(lastBit.getSource() == forward);
    CHECK(lastBit.getStaticOffsets()[0] == 2);
    CHECK(f.module->getOps<mlir::quantum::SplitOp>().empty());
    CHECK(mlir::succeeded(mlir::verify(*f.module)));
}

TEST_CASE("Selection validation avoids overflowing index arithmetic")
{
    using quantum::frontend::RegisterSlice;
    CHECK((RegisterSlice{0, 3, 2}.isValid(5)));
    CHECK((RegisterSlice{4, 3, -2}.isValid(5)));
    CHECK_FALSE((RegisterSlice{0, 4, 2}.isValid(5)));
    CHECK_FALSE((RegisterSlice{0, 1, 0}.isValid(5)));
    CHECK_FALSE((RegisterSlice{0, 0, 1}.isValid(5)));
    CHECK_FALSE(
        (RegisterSlice{0, 2, std::numeric_limits<int64_t>::max()}.isValid(5)));
    CHECK_FALSE(
        (RegisterSlice{4, 2, std::numeric_limits<int64_t>::min()}.isValid(5)));
    CHECK(
        (RegisterSlice{4, 1, std::numeric_limits<int64_t>::min()}.isValid(5)));
}

} // namespace
