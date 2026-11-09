/// Eliminates repeated QPU reads of QILLR result storage.
///
/// @file
/// @author     Lars Schuetze (lars.schuetze@tu-dresden.de)

#include "mlir/IR/PatternMatch.h"
#include "mlir/Pass/Pass.h"
#include "mlir/Transforms/GreedyPatternRewriteDriver.h"
#include "quantum-mlir/Dialect/QILLR/IR/QILLROps.h"
#include "quantum-mlir/Dialect/QILLR/Transforms/Passes.h"
#include "quantum-mlir/Dialect/QPU/IR/QPUOps.h"

#include <cstddef>
#include <llvm/Support/Casting.h>
#include <llvm/Support/LogicalResult.h>
#include <mlir/Dialect/Arith/IR/Arith.h>
#include <mlir/Dialect/SCF/IR/SCF.h>
#include <mlir/Dialect/Tensor/IR/Tensor.h>
#include <mlir/IR/BuiltinAttributes.h>
#include <mlir/IR/BuiltinTypes.h>
#include <mlir/IR/Dominance.h>
#include <mlir/IR/MLIRContext.h>
#include <mlir/Transforms/DialectConversion.h>

using namespace mlir;
using namespace mlir::qillr;

//===- Generated includes -------------------------------------------------===//

namespace mlir::qillr {

#define GEN_PASS_DEF_REPLACEREPEATEDMEASUREMENTREADS
#include "quantum-mlir/Dialect/QILLR/Transforms/Passes.h.inc"

} // namespace mlir::qillr

//===----------------------------------------------------------------------===//

namespace {

// Only reuse a snapshot when no intervening operation can change storage.
static bool canReuseRead(qpu::ToBitsOp previous, qpu::ToBitsOp current)
{
    Operation* cursor = current;
    while (cursor) {
        if (auto* preceding = cursor->getPrevNode()) {
            if (preceding == previous.getOperation()) return true;
            if (!isMemoryEffectFree(preceding)) return false;
            cursor = preceding;
        } else {
            auto* parent = cursor->getParentOp();
            // Do not cross loops: later iterations may observe intervening
            // writes.
            if (!llvm::isa_and_nonnull<scf::IfOp>(parent)) return false;
            cursor = parent;
        }
    }
    return false;
}

struct ReplaceRepeatedMeasurementReadsPass
        : mlir::qillr::impl::ReplaceRepeatedMeasurementReadsBase<
              ReplaceRepeatedMeasurementReadsPass> {
    using ReplaceRepeatedMeasurementReadsBase::
        ReplaceRepeatedMeasurementReadsBase;

    void runOnOperation() override;
};

struct ReplaceRepeatedReads : public OpRewritePattern<qpu::ToBitsOp> {
    DominanceInfo &domInfo;

    ReplaceRepeatedReads(MLIRContext* context, DominanceInfo &domInfo)
            : OpRewritePattern<qpu::ToBitsOp>(context),
              domInfo(domInfo)
    {}

    LogicalResult
    matchAndRewrite(qpu::ToBitsOp op, PatternRewriter &rewriter) const override
    {
        if (!llvm::isa<qillr::ResultType>(op.getSrc().getType())
            || !llvm::isa<RankedTensorType>(op.getDst().getType()))
            return failure();

        for (auto* user : op.getSrc().getUsers()) {
            auto read = llvm::dyn_cast<qpu::ToBitsOp>(user);
            if (!read || read == op || read.getType() != op.getType()) continue;
            if (domInfo.properlyDominates(
                    read.getOperation(),
                    op.getOperation())
                && canReuseRead(read, op)) {
                rewriter.replaceOp(op, read.getDst());
                return success();
            }
        }
        return failure();
    }
};

} // namespace

void ReplaceRepeatedMeasurementReadsPass::runOnOperation()
{
    auto context = &getContext();
    RewritePatternSet patterns(context);

    auto &domInfo = getAnalysis<DominanceInfo>();

    // Fully qualify the function call
    populateReplaceRepeatedMeasurementReadsPatterns(patterns, domInfo);

    if (failed(applyPatternsGreedily(getOperation(), std::move(patterns))))
        signalPassFailure();

    return markAnalysesPreserved<DominanceInfo>();
}

void mlir::qillr::populateReplaceRepeatedMeasurementReadsPatterns(
    RewritePatternSet &patterns,
    DominanceInfo &domInfo)
{ patterns.add<ReplaceRepeatedReads>(patterns.getContext(), domInfo); }

std::unique_ptr<Pass> mlir::qillr::createReplaceRepeatedMeasurementReadsPass()
{ return std::make_unique<ReplaceRepeatedMeasurementReadsPass>(); }
