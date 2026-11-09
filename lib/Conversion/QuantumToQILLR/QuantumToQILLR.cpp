/// Implements the ConvertQuantumToQILLRPass.
///
/// @file
/// @author     Lars Schütze (lars.schuetze@tu-dresden.de)

#include "quantum-mlir/Conversion/QuantumToQILLR/QuantumToQILLR.h"

#include "quantum-mlir/Dialect/QILLR/IR/QILLROps.h"
#include "quantum-mlir/Dialect/QILLR/IR/QILLRTypes.h"
#include "quantum-mlir/Dialect/QPU/IR/QPUBase.h"
#include "quantum-mlir/Dialect/QPU/IR/QPUOps.h"
#include "quantum-mlir/Dialect/Quantum/Analysis/RegisterRangesAnalysis.h"
#include "quantum-mlir/Dialect/Quantum/IR/QuantumOps.h"
#include "quantum-mlir/Dialect/Quantum/IR/QuantumTypes.h"
#include "quantum-mlir/Dialect/Quantum/Interfaces/InferRegisterRangesInterface.h"

#include <cstddef>
#include <llvm/ADT/DenseMap.h>
#include <llvm/ADT/STLExtras.h>
#include <llvm/ADT/SmallVector.h>
#include <llvm/ADT/SmallVectorExtras.h>
#include <llvm/Support/Casting.h>
#include <llvm/Support/Debug.h>
#include <llvm/Support/LogicalResult.h>
#include <mlir/Analysis/DataFlow/ConstantPropagationAnalysis.h>
#include <mlir/Analysis/DataFlow/DeadCodeAnalysis.h>
#include <mlir/Analysis/DataFlow/SparseAnalysis.h>
#include <mlir/Dialect/Func/IR/FuncOps.h>
#include <mlir/Dialect/Func/Transforms/FuncConversions.h>
#include <mlir/Dialect/SCF/IR/SCF.h>
#include <mlir/Dialect/SCF/Transforms/Patterns.h>
#include <mlir/Dialect/Tensor/IR/Tensor.h>
#include <mlir/IR/BuiltinAttributeInterfaces.h>
#include <mlir/IR/BuiltinAttributes.h>
#include <mlir/IR/BuiltinTypeInterfaces.h>
#include <mlir/IR/BuiltinTypes.h>
#include <mlir/IR/IRMapping.h>
#include <mlir/IR/PatternMatch.h>
#include <mlir/IR/Value.h>
#include <mlir/Interfaces/InferIntRangeInterface.h>
#include <mlir/Pass/Pass.h>
#include <mlir/Transforms/DialectConversion.h>
#include <utility>

#define DEBUG_TYPE "quantum-qillr-conversion"

using namespace mlir;
using namespace mlir::quantum;
using namespace quantum::dataflow;

//===- Generated includes
//-------------------------------------------------===//

namespace mlir {

#define GEN_PASS_DEF_CONVERTQUANTUMTOQILLR
#include "quantum-mlir/Conversion/Passes.h.inc"

} // namespace mlir

//===----------------------------------------------------------------------===//

namespace {

struct ConvertQuantumToQILLRPass
        : mlir::impl::ConvertQuantumToQILLRBase<ConvertQuantumToQILLRPass> {
    using ConvertQuantumToQILLRBase::ConvertQuantumToQILLRBase;

    void runOnOperation() override;
};

template<typename OpT>
struct IndexTrackingOpConversionPattern : public OpConversionPattern<OpT> {
public:
    IndexTrackingOpConversionPattern(
        mlir::DataFlowSolver &solver,
        IRMapping &cregs,
        const TypeConverter &typeConverter,
        MLIRContext* context,
        PatternBenefit benefit = 1)
            : OpConversionPattern<OpT>(typeConverter, context, benefit),
              solver(solver),
              cregs(cregs)
    {}

    LogicalResult lookupSingle(
        Value value,
        std::optional<uint64_t> &result,
        ConversionPatternRewriter &rewriter) const;

protected:
    mlir::DataFlowSolver &solver;
    IRMapping &cregs;

}; // struct IndexTrackingOpConversionPattern

template<typename OpT>
LogicalResult IndexTrackingOpConversionPattern<OpT>::lookupSingle(
    Value value,
    std::optional<uint64_t> &result,
    ConversionPatternRewriter &rewriter) const
{
    const RegisterRangesLattice* lattice =
        this->solver.lookupState<RegisterRangesLattice>(value);
    if (!lattice)
        return rewriter.notifyMatchFailure(
            value.getDefiningOp(),
            "Lattice value not found");

    const auto latticeValue = lattice->getValue();
    const auto indices = latticeValue.getValue();

    ConstantIntRanges range(indices[0].getRanges());
    for (size_t i = 0; i < indices.size(); ++i) {
        if (indices[i].getRegisterValue() != indices[0].getRegisterValue()) {
            return rewriter.notifyMatchFailure(
                value.getDefiningOp(),
                "Lattice value depends on unequal register values");
        }
        range = range.rangeUnion(indices[i].getRanges());
    }
    bool isConstant = (range.umax() - 1 == range.umin());
    if (isConstant) {
        result = range.umin().trySExtValue();
        return success();
    }

    if (auto valTy = llvm::dyn_cast<quantum::QubitType>(
            indices[0].getRegisterValue().getType()))
        if (valTy.getSize() == range.umax() - range.umin()) return success();
    return failure();
}

struct ConvertAlloc
        : public IndexTrackingOpConversionPattern<quantum::AllocOp> {
    using IndexTrackingOpConversionPattern::IndexTrackingOpConversionPattern;

    LogicalResult matchAndRewrite(
        AllocOp op,
        AllocOpAdaptor,
        ConversionPatternRewriter &rewriter) const override
    {
        auto opType = op.getResult().getType();
        auto size = opType.getSize();

        LLVM_DEBUG(llvm::dbgs() << "Create alloc with size " << size << "\n");

        rewriter.replaceOpWithNewOp<qillr::AllocOp>(
            op,
            qillr::QubitType::get(getContext()),
            size);
        return success();
    }
}; // struct ConvertAlloc

struct ConvertSplit
        : public IndexTrackingOpConversionPattern<quantum::SplitOp> {
    using IndexTrackingOpConversionPattern::IndexTrackingOpConversionPattern;

    LogicalResult matchAndRewrite(
        SplitOp op,
        SplitOpAdaptor adaptor,
        ConversionPatternRewriter &rewriter) const override
    {
        LLVM_DEBUG(llvm::dbgs() << "Convert op " << op << "\n");
        SmallVector<ValueRange, 4> replace;
        for (unsigned i = 0; i < op->getNumResults(); ++i) {
            LLVM_DEBUG(
                llvm::dbgs() << "Replace result " << i << "with "
                             << adaptor.getInput() << "\n");
            replace.push_back(adaptor.getInput());
        }
        rewriter.replaceOpWithMultiple(op, replace);
        return success();
    }
}; // struct ConvertSplit

struct ConvertMerge
        : public IndexTrackingOpConversionPattern<quantum::MergeOp> {
    using IndexTrackingOpConversionPattern::IndexTrackingOpConversionPattern;

    LogicalResult matchAndRewrite(
        MergeOp op,
        MergeOpAdaptor adaptor,
        ConversionPatternRewriter &rewriter) const override
    {
        Value reg = adaptor.getInput()[0];
        LLVM_DEBUG(llvm::dbgs() << "Replace result with " << reg << "\n");

        for (size_t i = 0; i < adaptor.getInput().size(); ++i)
            assert(
                reg == adaptor.getInput()[i]
                && "Must merge access to same register.");

        rewriter.replaceOp(op, reg);
        return success();
    }
}; // struct ConvertMerge

struct ConvertMeasure
        : public IndexTrackingOpConversionPattern<quantum::MeasureOp> {
    using IndexTrackingOpConversionPattern::IndexTrackingOpConversionPattern;

    LogicalResult rewriteToBits(
        MeasureOp op,
        MeasureOpAdaptor adaptor,
        qpu::ToBitsOp toBitsOp,
        ConversionPatternRewriter &rewriter) const
    {
        TypedValue<ShapedType> creg = toBitsOp.getResult();

        assert(creg.getType().getRank() == 1 && "Only support tensor<?x_>");
        TypedValue<::mlir::qillr::ResultType> resultAlloc;
        if (!cregs.contains(creg)) {
            // We have not seen any tensor representing results yet
            const int64_t length = creg.getType().getDimSize(0);
            resultAlloc = qillr::AllocResultOp::create(
                              rewriter,
                              op->getLoc(),
                              qillr::ResultType::get(op.getContext()),
                              length)
                              .getResult();
        } else {
            // Get the last stored tensor -> result mapping
            resultAlloc =
                llvm::dyn_cast_if_present<TypedValue<qillr::ResultType>>(
                    cregs.lookupOrNull(creg));
            // We do not need creg anymore.
            cregs.erase(creg);
        }
        // Update the mapping to the newly created value.
        cregs.map(creg, resultAlloc);

        std::optional<uint64_t> qubitIndex;
        auto result = this->lookupSingle(op.getInput(), qubitIndex, rewriter);
        if (failed(result)) return result;

        qillr::MeasureOp::create(
            rewriter,
            op->getLoc(),
            adaptor.getInput(),
            resultAlloc,
            qubitIndex,
            0);

        auto readMeasurement = qpu::ToBitsOp::create(
            rewriter,
            op->getLoc(),
            creg.getType(),
            resultAlloc);

        rewriter.replaceOp(toBitsOp, readMeasurement);
        rewriter.replaceOp(op, {resultAlloc, adaptor.getInput()});

        return success();
    }

    LogicalResult rewriteInsertSlice(
        MeasureOp op,
        MeasureOpAdaptor adaptor,
        tensor::InsertSliceOp insertSliceOp,
        qpu::ToBitsOp toBitsOp,
        ConversionPatternRewriter &rewriter) const
    {
        auto creg = insertSliceOp.getDest();
        assert(creg.getType().getRank() == 1 && "Only support tensor<?x_>");

        TypedValue<::mlir::qillr::ResultType> resultAlloc;
        if (!cregs.contains(creg)) {
            // We have not seen any tensor representing results yet
            const int64_t length = creg.getType().getDimSize(0);
            resultAlloc = qillr::AllocResultOp::create(
                              rewriter,
                              op->getLoc(),
                              qillr::ResultType::get(op->getContext()),
                              length)
                              .getResult();
        } else {
            // Get the last stored tensor -> result mapping
            resultAlloc =
                llvm::dyn_cast_if_present<TypedValue<qillr::ResultType>>(
                    cregs.lookupOrNull(creg));
            // We do not need creg anymore.
            cregs.erase(creg);
        }
        // Update the mapping to the newly created value.
        cregs.map(insertSliceOp.getResult(), resultAlloc);

        std::optional<uint64_t> qubitIndex;
        auto result = this->lookupSingle(op.getInput(), qubitIndex, rewriter);
        if (failed(result)) return result;

        int64_t staticOffset = insertSliceOp.getStaticOffset(0);
        qillr::MeasureOp::create(
            rewriter,
            op->getLoc(),
            adaptor.getInput(),
            resultAlloc,
            qubitIndex,
            staticOffset);

        auto readMeasurement = qpu::ToBitsOp::create(
            rewriter,
            op->getLoc(),
            creg.getType(),
            resultAlloc);

        rewriter.replaceOp(insertSliceOp, readMeasurement);
        rewriter.replaceOp(op, {resultAlloc, adaptor.getInput()});
        rewriter.eraseOp(toBitsOp);
        return success();
    }

    LogicalResult matchAndRewrite(
        MeasureOp op,
        MeasureOpAdaptor adaptor,
        ConversionPatternRewriter &rewriter) const override
    {
        // The quantum measurement looks like follows:
        // %c = ... tensor<jxi1> with j > i
        // %m, %q1 = measure(%q) : qubit<1> -> measurement<1>, qubit<1>
        // %t = qpu.to_bits(%m) -> tensor<1xi1>
        // if the dimension of %t and %c are equal insert_slice is omitted
        // %cnew = insert_slice(%t, %c) {i} -> tensor<1xi1>
        LLVM_DEBUG(llvm::dbgs() << "Lower measurement and results \n");
        auto m = op.getMeasurement();
        auto toBitsOp = llvm::filter_to_vector(m.getUsers(), [](Operation* op) {
            return llvm::isa<qpu::ToBitsOp>(op);
        });
        if (toBitsOp.size() != 1 || !m.hasOneUse())
            return rewriter.notifyMatchFailure(
                op,
                "requires exactly one to_bits user");
        auto insertSliceOpV = llvm::filter_to_vector(
            toBitsOp.front()->getResult(0).getUsers(),
            [](Operation* op) { return llvm::isa<tensor::InsertSliceOp>(op); });

        if (insertSliceOpV.size() == 0) {
            if (failed(rewriteToBits(
                    op,
                    adaptor,
                    llvm::cast<qpu::ToBitsOp>(toBitsOp.front()),
                    rewriter)))
                return failure();
        } else if (insertSliceOpV.size() == 1) {
            if (failed(rewriteInsertSlice(
                    op,
                    adaptor,
                    llvm::cast<tensor::InsertSliceOp>(insertSliceOpV.front()),
                    llvm::cast<qpu::ToBitsOp>(toBitsOp.front()),
                    rewriter)))
                return failure();
        } else {
            LLVM_DEBUG(
                llvm::dbgs()
                << "toBitsOp is used " << insertSliceOpV.size() << " times\n");
            return rewriter.notifyMatchFailure(
                op,
                "to_bits has unsupported multiple insert_slice users");
        }
        return success();
    } // namespace
}; // struct ConvertMeasure

struct ConvertFunc : public IndexTrackingOpConversionPattern<func::FuncOp> {
    using IndexTrackingOpConversionPattern::IndexTrackingOpConversionPattern;

    LogicalResult matchAndRewrite(
        func::FuncOp op,
        func::FuncOpAdaptor adaptor,
        ConversionPatternRewriter &rewriter) const override
    {
        auto ftype = op.getFunctionType();

        auto genFuncTy = typeConverter->convertType(ftype);
        auto genFunc = func::FuncOp::create(
            rewriter,
            op->getLoc(),
            op.getSymName(),
            llvm::dyn_cast<FunctionType>(genFuncTy));

        if (!op.isExternal()) {
            rewriter.inlineRegionBefore(
                adaptor.getBody(),
                genFunc.getBody(),
                genFunc.end());
        }
        rewriter.replaceOp(op, genFunc);

        return success();
    }
}; // struct ConvertFunc

template<typename SourceOp, typename TargetOp>
struct ConvertUnaryOp : public IndexTrackingOpConversionPattern<SourceOp> {
    using IndexTrackingOpConversionPattern<
        SourceOp>::IndexTrackingOpConversionPattern;

    LogicalResult matchAndRewrite(
        SourceOp op,
        OpConversionPattern<SourceOp>::OpAdaptor adaptor,
        ConversionPatternRewriter &rewriter) const override
    {
        LLVM_DEBUG(llvm::dbgs() << "Convert " << op << "\n");
        std::optional<uint64_t> index;
        auto result = this->lookupSingle(op.getInput(), index, rewriter);
        if (failed(result)) return result;
        LLVM_DEBUG(llvm::dbgs() << "Inferred index " << index << "\n");

        LLVM_DEBUG(
            llvm::dbgs()
            << "Create new op with argument: " << adaptor.getInput() << "\n");
        TargetOp::create(rewriter, op.getLoc(), adaptor.getInput(), index);
        if (op->getNumResults() > 0)
            rewriter.replaceOp(op, adaptor.getInput());
        else
            rewriter.eraseOp(op);
        return success();
    }
}; // struct ConvertUnaryOp

template<typename SourceOp, typename TargetOp>
struct ConvertControlledUnaryOp
        : public IndexTrackingOpConversionPattern<SourceOp> {
    using IndexTrackingOpConversionPattern<
        SourceOp>::IndexTrackingOpConversionPattern;

    LogicalResult matchAndRewrite(
        SourceOp op,
        OpConversionPattern<SourceOp>::OpAdaptor adaptor,
        ConversionPatternRewriter &rewriter) const override
    {
        std::optional<uint64_t> controlIndex;
        auto result =
            this->lookupSingle(op.getControl(), controlIndex, rewriter);
        if (failed(result)) return result;

        std::optional<uint64_t> targetIndex;
        result = this->lookupSingle(op.getTarget(), targetIndex, rewriter);
        if (failed(result)) return result;

        TargetOp::create(
            rewriter,
            op.getLoc(),
            adaptor.getControl(),
            adaptor.getTarget(),
            controlIndex,
            targetIndex);

        if (op->getNumResults() > 0)
            rewriter.replaceOp(op, adaptor.getOperands());
        else
            rewriter.eraseOp(op);
        return success();
    }
}; // struct ConvertControlledUnaryOp

template<typename SourceOp, typename TargetOp>
struct ConvertRotationOp : public IndexTrackingOpConversionPattern<SourceOp> {
    using IndexTrackingOpConversionPattern<
        SourceOp>::IndexTrackingOpConversionPattern;

    LogicalResult matchAndRewrite(
        SourceOp op,
        OpConversionPattern<SourceOp>::OpAdaptor adaptor,
        ConversionPatternRewriter &rewriter) const override
    {
        std::optional<uint64_t> index;
        auto result = this->lookupSingle(op.getInput(), index, rewriter);
        if (failed(result)) return result;

        TargetOp::create(
            rewriter,
            op.getLoc(),
            adaptor.getInput(),
            adaptor.getTheta(),
            index);
        rewriter.replaceOp(op, adaptor.getInput());
        return success();
    }
}; // struct ConvertRotationOp

template<typename SourceOp, typename TargetOp>
struct ConvertControlledRotationOp
        : public IndexTrackingOpConversionPattern<SourceOp> {
    using IndexTrackingOpConversionPattern<
        SourceOp>::IndexTrackingOpConversionPattern;

    LogicalResult matchAndRewrite(
        SourceOp op,
        OpConversionPattern<SourceOp>::OpAdaptor adaptor,
        ConversionPatternRewriter &rewriter) const override
    {
        std::optional<uint64_t> controlIndex;
        auto result =
            this->lookupSingle(op.getControl(), controlIndex, rewriter);
        if (failed(result)) return result;

        std::optional<uint64_t> targetIndex;
        result = this->lookupSingle(op.getTarget(), targetIndex, rewriter);
        if (failed(result)) return result;

        TargetOp::create(
            rewriter,
            op.getLoc(),
            adaptor.getControl(),
            adaptor.getTarget(),
            adaptor.getAngle(),
            controlIndex,
            targetIndex);
        rewriter.replaceOp(op, {adaptor.getControl(), adaptor.getTarget()});
        return success();
    }
}; // struct ConvertControlledRotationOp

struct ConvertSwap : public IndexTrackingOpConversionPattern<quantum::SWAPOp> {
    using IndexTrackingOpConversionPattern::IndexTrackingOpConversionPattern;

    LogicalResult matchAndRewrite(
        SWAPOp op,
        SWAPOpAdaptor adaptor,
        ConversionPatternRewriter &rewriter) const override
    {
        std::optional<uint64_t> indexLhs;
        std::optional<uint64_t> indexRhs;
        LogicalResult result = LogicalResult::success();
        result = this->lookupSingle(op.getLhs(), indexLhs, rewriter);
        if (failed(result)) return result;
        result = this->lookupSingle(op.getRhs(), indexRhs, rewriter);
        if (failed(result)) return result;

        // Retrieve the two input qubits from the adaptor.
        Value qubit1 = adaptor.getLhs();
        Value qubit2 = adaptor.getRhs();
        qillr::SwapOp::create(
            rewriter,
            op.getLoc(),
            qubit1,
            qubit2,
            indexLhs,
            indexRhs);
        rewriter.replaceOp(op, {qubit1, qubit2});
        return success();
    }
}; // struct ConvertSwap

struct ConvertCSwap
        : public IndexTrackingOpConversionPattern<quantum::CSWAPOp> {
    using IndexTrackingOpConversionPattern::IndexTrackingOpConversionPattern;

    LogicalResult matchAndRewrite(
        CSWAPOp op,
        CSWAPOpAdaptor adaptor,
        ConversionPatternRewriter &rewriter) const override
    {
        LogicalResult result = LogicalResult::success();
        std::optional<uint64_t> indexCtrl;
        std::optional<uint64_t> indexLhs;
        std::optional<uint64_t> indexRhs;
        result = this->lookupSingle(op.getLhs(), indexCtrl, rewriter);
        if (failed(result)) return result;
        result = this->lookupSingle(op.getLhs(), indexLhs, rewriter);
        if (failed(result)) return result;
        result = this->lookupSingle(op.getLhs(), indexRhs, rewriter);
        if (failed(result)) return result;

        Value control = adaptor.getControl();
        Value lhs = adaptor.getLhs();
        Value rhs = adaptor.getRhs();
        qillr::CSwapOp::create(
            rewriter,
            op.getLoc(),
            control,
            lhs,
            rhs,
            indexCtrl,
            indexLhs,
            indexRhs);
        rewriter.replaceOp(op, {control, lhs, rhs});
        return success();
    }
}; // struct ConvertCSwap

struct ConvertBarrier
        : public IndexTrackingOpConversionPattern<quantum::BarrierOp> {
    using IndexTrackingOpConversionPattern::IndexTrackingOpConversionPattern;

    LogicalResult matchAndRewrite(
        BarrierOp op,
        BarrierOpAdaptor adaptor,
        ConversionPatternRewriter &rewriter) const override
    {
        llvm::SmallVector<int64_t> indices;
        LogicalResult result = LogicalResult::success();
        for (auto input : op.getInput()) {
            std::optional<uint64_t> index;
            result = this->lookupSingle(input, index, rewriter);
            if (failed(result)) return result;
            indices.push_back(index.value());
        }

        auto attr = rewriter.getI64ArrayAttr(indices);
        qillr::BarrierOp::create(
            rewriter,
            op->getLoc(),
            adaptor.getInput(),
            attr);

        rewriter.replaceOp(op, adaptor.getInput());
        return success();
    }
}; // struct ConvertBarrier

struct ConvertCNOT : public IndexTrackingOpConversionPattern<quantum::CNOTOp> {
    using IndexTrackingOpConversionPattern::IndexTrackingOpConversionPattern;

    LogicalResult matchAndRewrite(
        CNOTOp op,
        CNOTOpAdaptor adaptor,
        ConversionPatternRewriter &rewriter) const override
    {
        LogicalResult result = LogicalResult::success();
        std::optional<uint64_t> controlIndex;
        result = this->lookupSingle(op.getInput(), controlIndex, rewriter);
        if (failed(result)) return result;

        std::optional<uint64_t> targetIndex;
        result = this->lookupSingle(op.getTarget(), targetIndex, rewriter);
        if (failed(result)) return result;

        qillr::CNOTOp::create(
            rewriter,
            op->getLoc(),
            adaptor.getInput(),
            adaptor.getTarget(),
            controlIndex,
            targetIndex);

        rewriter.replaceOp(op, {adaptor.getInput(), adaptor.getTarget()});
        return success();
    }
}; // struct ConvertCNOT

struct ConvertU1 : public IndexTrackingOpConversionPattern<quantum::U1Op> {
    using IndexTrackingOpConversionPattern::IndexTrackingOpConversionPattern;

    LogicalResult matchAndRewrite(
        U1Op op,
        U1OpAdaptor adaptor,
        ConversionPatternRewriter &rewriter) const override
    {
        LogicalResult result = LogicalResult::success();
        std::optional<uint64_t> index;
        result = this->lookupSingle(op.getInput(), index, rewriter);
        if (failed(result)) return result;

        qillr::U1Op::create(
            rewriter,
            op->getLoc(),
            adaptor.getInput(),
            adaptor.getLambda(),
            index);

        rewriter.replaceOp(op, adaptor.getInput());
        return success();
    }
}; // struct ConvertU1

struct ConvertU2 : public IndexTrackingOpConversionPattern<quantum::U2Op> {
    using IndexTrackingOpConversionPattern::IndexTrackingOpConversionPattern;

    LogicalResult matchAndRewrite(
        U2Op op,
        U2OpAdaptor adaptor,
        ConversionPatternRewriter &rewriter) const override
    {
        LogicalResult result = LogicalResult::success();
        std::optional<uint64_t> index;
        result = this->lookupSingle(op.getInput(), index, rewriter);
        if (failed(result)) return result;

        qillr::U2Op::create(
            rewriter,
            op->getLoc(),
            adaptor.getInput(),
            adaptor.getPhi(),
            adaptor.getLambda(),
            index);

        rewriter.replaceOp(op, adaptor.getInput());
        return success();
    }
}; // struct ConvertU2

struct ConvertU3 : public IndexTrackingOpConversionPattern<quantum::U3Op> {
    using IndexTrackingOpConversionPattern::IndexTrackingOpConversionPattern;

    LogicalResult matchAndRewrite(
        U3Op op,
        U3OpAdaptor adaptor,
        ConversionPatternRewriter &rewriter) const override
    {
        LogicalResult result = LogicalResult::success();
        std::optional<uint64_t> index;
        result = this->lookupSingle(op.getInput(), index, rewriter);
        if (failed(result)) return result;

        qillr::U3Op::create(
            rewriter,
            op->getLoc(),
            adaptor.getInput(),
            adaptor.getTheta(),
            adaptor.getPhi(),
            adaptor.getLambda(),
            index);

        rewriter.replaceOp(op, adaptor.getInput());
        return success();
    }
}; // struct ConvertU3

struct ConvertToffoli
        : public IndexTrackingOpConversionPattern<quantum::CCXOp> {
    using IndexTrackingOpConversionPattern::IndexTrackingOpConversionPattern;

    LogicalResult matchAndRewrite(
        CCXOp op,
        CCXOpAdaptor adaptor,
        ConversionPatternRewriter &rewriter) const override
    {
        LogicalResult result = LogicalResult::success();

        std::optional<uint64_t> control1Index;
        result = this->lookupSingle(op.getControl1(), control1Index, rewriter);
        if (failed(result)) return result;

        std::optional<uint64_t> control2Index;
        result = this->lookupSingle(op.getControl2(), control2Index, rewriter);
        if (failed(result)) return result;

        std::optional<uint64_t> targetIndex;
        result = this->lookupSingle(op.getTarget(), targetIndex, rewriter);
        if (failed(result)) return result;

        qillr::CCXOp::create(
            rewriter,
            op->getLoc(),
            adaptor.getControl1(),
            adaptor.getControl2(),
            adaptor.getTarget(),
            control1Index,
            control2Index,
            targetIndex);

        rewriter.replaceOp(
            op,
            {adaptor.getControl1(),
             adaptor.getControl2(),
             adaptor.getTarget()});
        return success();
    }
}; // struct ConvertToffoli

} // namespace

void ConvertQuantumToQILLRPass::runOnOperation()
{
    TypeConverter typeConverter;
    auto context = &getContext();
    ConversionTarget target(*context);
    RewritePatternSet patterns(context);
    IRMapping mapping;

    typeConverter.addConversion([](Type ty) { return ty; });
    typeConverter.addConversion([](quantum::QubitType ty) {
        return qillr::QubitType::get(ty.getContext());
    });

    mlir::DataFlowSolver solver;
    solver.load<mlir::dataflow::DeadCodeAnalysis>();
    solver.load<mlir::dataflow::SparseConstantPropagation>();
    solver.load<quantum::dataflow::RegisterRangesAnalysis>();
    if (failed(solver.initializeAndRun(getOperation())))
        return signalPassFailure();

    quantum::populateConvertQuantumToQILLRPatterns(
        solver,
        mapping,
        typeConverter,
        patterns);
    // Populate conversions from `func` dialect
    populateFunctionOpInterfaceTypeConversionPattern<func::FuncOp>(
        patterns,
        typeConverter);
    populateCallOpTypeConversionPattern(patterns, typeConverter);
    populateReturnOpTypeConversionPattern(patterns, typeConverter);
    scf::populateSCFStructuralTypeConversionsAndLegality(
        typeConverter,
        patterns,
        target);

    target.addLegalDialect<qillr::QILLRDialect>();
    target.addLegalDialect<qpu::QPUDialect>();
    target.addIllegalDialect<quantum::QuantumDialect>();
    target.addDynamicallyLegalOp<func::FuncOp>([&](func::FuncOp op) {
        return typeConverter.isSignatureLegal(op.getFunctionType());
    });

    if (failed(applyPartialConversion(
            getOperation(),
            target,
            std::move(patterns))))
        return signalPassFailure();
}

void mlir::quantum::populateConvertQuantumToQILLRPatterns(
    mlir::DataFlowSolver &solver,
    IRMapping &mapping,
    TypeConverter &typeConverter,
    RewritePatternSet &patterns)
{
    patterns.add<
        ConvertAlloc,
        ConvertMeasure,
        ConvertUnaryOp<quantum::ResetOp, qillr::ResetOp>,
        ConvertUnaryOp<quantum::DeallocateOp, qillr::DeallocateOp>,
        ConvertUnaryOp<quantum::HOp, qillr::HOp>,
        ConvertUnaryOp<quantum::XOp, qillr::XOp>,
        ConvertUnaryOp<quantum::YOp, qillr::YOp>,
        ConvertUnaryOp<quantum::ZOp, qillr::ZOp>,
        ConvertUnaryOp<quantum::IdOp, qillr::IdOp>,
        ConvertUnaryOp<quantum::SXOp, qillr::SXOp>,
        ConvertUnaryOp<quantum::SdgOp, qillr::SdgOp>,
        ConvertUnaryOp<quantum::TOp, qillr::TOp>,
        ConvertUnaryOp<quantum::TdgOp, qillr::TdgOp>,
        ConvertUnaryOp<quantum::SOp, qillr::SOp>,
        ConvertRotationOp<quantum::RxOp, qillr::RxOp>,
        ConvertRotationOp<quantum::RyOp, qillr::RyOp>,
        ConvertRotationOp<quantum::RzOp, qillr::RzOp>,
        ConvertRotationOp<quantum::PhaseOp, qillr::PhaseOp>,
        ConvertControlledUnaryOp<quantum::CZOp, qillr::CZOp>,
        ConvertControlledRotationOp<quantum::CRyOp, qillr::CRyOp>,
        ConvertControlledRotationOp<quantum::CRzOp, qillr::CRzOp>,
        ConvertControlledRotationOp<quantum::CU1Op, qillr::CU1Op>,
        ConvertCSwap,
        ConvertSwap,
        ConvertSplit,
        ConvertMerge,
        ConvertBarrier,
        ConvertCNOT,
        ConvertU1,
        ConvertU2,
        ConvertU3,
        ConvertToffoli>(
        solver,
        mapping,
        typeConverter,
        patterns.getContext(),
        /* benefit*/ 1);
}

std::unique_ptr<Pass> mlir::createConvertQuantumToQILLRPass()
{ return std::make_unique<ConvertQuantumToQILLRPass>(); }
