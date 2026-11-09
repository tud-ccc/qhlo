/// Implements the control-flow optimization.
///
/// @file
/// @author     Lars Schütze (lars.schuetze@tu-dresden.de)

#include "mlir/IR/PatternMatch.h"
#include "mlir/Pass/Pass.h"
#include "quantum-mlir/Dialect/Quantum/IR/Quantum.h"
#include "quantum-mlir/Dialect/RVSDG/IR/RVSDG.h"
#include "quantum-mlir/Dialect/RVSDG/IR/RVSDGOps.h"
#include "quantum-mlir/Dialect/RVSDG/IR/RVSDGTypes.h"

#include <llvm/ADT/MapVector.h>
#include <llvm/ADT/STLExtras.h>
#include <llvm/ADT/SetVector.h>
#include <llvm/ADT/SmallPtrSet.h>
#include <llvm/ADT/SmallVector.h>
#include <llvm/Support/Casting.h>
#include <llvm/Support/LogicalResult.h>
#include <mlir/IR/Block.h>
#include <mlir/IR/IRMapping.h>
#include <mlir/IR/OperationSupport.h>
#include <mlir/IR/Region.h>
#include <mlir/IR/Value.h>
#include <mlir/IR/ValueRange.h>
#include <mlir/Support/LLVM.h>
#include <utility>

using namespace mlir;
using namespace mlir::rvsdg;
using namespace mlir::quantum;

//===- Generated includes -------------------------------------------------===//

namespace mlir::rvsdg {

#define GEN_PASS_DEF_CONTROLFLOWHOISTING
#include "quantum-mlir/Dialect/RVSDG/Transforms/Passes.h.inc"

} // namespace mlir::rvsdg

//===----------------------------------------------------------------------===//

namespace {

struct ControlFlowHoistingPass
        : mlir::rvsdg::impl::ControlFlowHoistingBase<ControlFlowHoistingPass> {
    using ControlFlowHoistingBase::ControlFlowHoistingBase;

    void runOnOperation() override;

    void
    checkAndMarkEquivalentOperations(Operation* op, Region &lhs, Region &rhs);

private:
    /// markedEquivs maps GammaOp -> (Move, Delete)
    llvm::DenseMap<
        Operation*,
        llvm::SmallSetVector<std::pair<Operation*, Operation*>, 8>>
        markedEquivs;
};

} // namespace

void ControlFlowHoistingPass::checkAndMarkEquivalentOperations(
    Operation* op,
    Region &lhs,
    Region &rhs)
{
    DenseMap<Value, Value> equivalentValues;
    for (auto [lArg, rArg] :
         llvm::zip(lhs.getArguments(), rhs.getArguments())) {
        for (auto [lOp, rOp] : llvm::zip(lArg.getUsers(), rArg.getUsers())) {
            // Potentially this will leave a gamma node that directly yields all
            // incoming values. Such a GammaNode should be removed by
            // canonicalization
            if (llvm::isa<mlir::rvsdg::YieldOp>(lOp)
                || llvm::isa<mlir::rvsdg::YieldOp>(rOp))
                continue;

            if (OperationEquivalence::isEquivalentTo(
                    lOp,
                    rOp,
                    [&](Value lhsValue, Value rhsValue) -> LogicalResult {
                        if (llvm::isa<BlockArgument>(lhsValue)
                            && llvm::isa<BlockArgument>(rhsValue)) {
                            auto lhsArg =
                                llvm::dyn_cast<BlockArgument>(lhsValue);
                            auto rhsArg =
                                llvm::dyn_cast<BlockArgument>(rhsValue);

                            if (lhsArg.getArgNumber() == rhsArg.getArgNumber())
                                return success();
                        }
                        return success(
                            lhsValue == rhsValue
                            || equivalentValues.lookup(lhsValue) == rhsValue);
                        // The arguments either are region args or the
                        // operands are known to be equivalent
                    },
                    [&](Value lhsResult, Value rhsResult) {
                        auto insertion =
                            equivalentValues.insert({lhsResult, rhsResult});
                        // Make sure that the value was not already marked
                        // equivalent to some other value.
                        (void)insertion;
                        assert(
                            insertion.first->second == rhsResult
                            && "inconsistent state");
                    },
                    OperationEquivalence::Flags::IgnoreLocations)) {
                // TODO: Operands must be BlockArguments OR the result of an
                // operation that is already marked equivalent
                markedEquivs[op].insert(std::make_pair(lOp, rOp));
            }
        }
    }
}

void ControlFlowHoistingPass::runOnOperation()
{
    mlir::OpBuilder builder(&getContext());

    auto module = getOperation();
    module->walk([&](rvsdg::GammaNode op) {
        checkAndMarkEquivalentOperations(op, op->getRegion(0), op.getRegion(1));
    });

    module->walk([&](rvsdg::GammaNode op) {
        IRMapping mapping;
        // GammaNode has Conditional + Arguments
        for (auto operand : llvm::zip(
                 op->getOperands().drop_front(),
                 op->getRegion(0).getArguments())) {
            auto from = std::get<0>(operand);
            auto to = std::get<1>(operand);
            mapping.map(to, from);
        }

        builder.setInsertionPoint(op);
        for (auto [moveOp, delOp] : markedEquivs.lookup(op)) {
            // Outline operation in front of Gamma op
            auto outlinedOp = builder.clone(*moveOp, mapping);

            // Remap Gamma operands to results of outlined operation
            moveOp->replaceAllUsesWith(moveOp->getOperands());
            delOp->replaceAllUsesWith(delOp->getOperands());
            for (auto [operand, result] : llvm::zip(
                     outlinedOp->getOperands(),
                     outlinedOp->getResults())) {
                op->replaceUsesOfWith(operand, result);
            }
        }
    });

    for (const auto &entry : markedEquivs) {
        const auto &pairs = entry.second;
        for (const auto [moveOp, delOp] : pairs) {
            moveOp->erase();
            delOp->erase();
        }
    }
    // markedEquivs.clear();
}

std::unique_ptr<Pass> mlir::rvsdg::createControlFlowHoistingPass()
{ return std::make_unique<ControlFlowHoistingPass>(); }
