/// Implements the Quantum dialect ops.
///
/// @file
/// @author     Lars Schütze (lars.schuetze@tu-dresden.de)

#include "quantum-mlir/Dialect/QPU/IR/QPUOps.h"

#include "mlir/Interfaces/FunctionImplementation.h"
#include "mlir/Transforms/InliningUtils.h"
#include "quantum-mlir/Dialect/QPU/IR/QPUAttributes.h"
#include "quantum-mlir/Dialect/QPU/IR/QPUTypes.h"

#include <algorithm>
#include <cstddef>
#include <iterator>
#include <llvm/ADT/STLExtras.h>
#include <llvm/ADT/SmallVector.h>
#include <llvm/ADT/StringRef.h>
#include <llvm/Support/Casting.h>
#include <llvm/Support/Error.h>
#include <llvm/Support/Format.h>
#include <llvm/Support/LogicalResult.h>
#include <llvm/Support/raw_ostream.h>
#include <llvm/TableGen/Record.h>
#include <mlir/Dialect/Arith/IR/Arith.h>
#include <mlir/IR/Diagnostics.h>
#include <mlir/IR/OpDefinition.h>
#include <mlir/IR/PatternMatch.h>
#include <mlir/IR/Region.h>
#include <mlir/IR/Value.h>
#include <mlir/Support/LLVM.h>
#include <mlir/Support/LogicalResult.h>
#include <optional>

#define DEBUG_TYPE "qpu-ops"

using namespace mlir;
using namespace mlir::qpu;

//===----------------------------------------------------------------------===//
// QPUDialect Interfaces
//===----------------------------------------------------------------------===//

namespace {
/// This class defines the interface for handling inlining with gate operations.
struct QPUInlinerInterface : public DialectInlinerInterface {
    using DialectInlinerInterface::DialectInlinerInterface;

    //===--------------------------------------------------------------------===//
    // Analysis Hooks
    //===--------------------------------------------------------------------===//

    /// Call operations can always be inlined
    bool isLegalToInline(
        Operation* call,
        Operation* callable,
        bool wouldBeCloned) const final
    { return true; }

    /// All operations can be inlined.
    bool isLegalToInline(Operation*, Region*, bool, IRMapping &) const final
    { return true; }

    /// All gate bodies can be inlined.
    bool isLegalToInline(Region*, Region*, bool, IRMapping &) const final
    { return true; }

    //===--------------------------------------------------------------------===//
    // Transformation Hooks
    //===--------------------------------------------------------------------===//

    /// Handle the given inlined terminator by replacing it with a new operation
    /// as necessary.
    void handleTerminator(Operation* op, Block* newDest) const final {};

    /// Handle the given inlined terminator by replacing its operands
    void handleTerminator(Operation* op, ValueRange valuesToRepl) const final {
    };
};
} // namespace

//===----------------------------------------------------------------------===//
// ExecuteOp Parser / Printer
//===----------------------------------------------------------------------===//

static ParseResult parseExecuteOperandList(
    OpAsmParser &parser,
    SmallVectorImpl<OpAsmParser::UnresolvedOperand> &operandNames,
    SmallVectorImpl<Type> &operandTypes)
{
    auto parseElement = [&]() -> ParseResult {
        OpAsmParser::UnresolvedOperand operand;
        Type type;

        if (parser.parseOperand(operand) || parser.parseColonType(type))
            return failure();

        operandNames.push_back(operand);
        operandTypes.push_back(type);
        return success();
    };

    return parser.parseCommaSeparatedList(
        OpAsmParser::Delimiter::Paren,
        parseElement,
        "in argument list");
}

static void printExecuteOperandList(
    OpAsmPrinter &printer,
    Operation*,
    OperandRange operands,
    TypeRange types)
{
    printer << "(";
    llvm::interleaveComma(
        llvm::zip_equal(operands, types),
        printer,
        [&](const auto &pair) {
            auto [operand, type] = pair;
            printer << operand << " : " << type;
        });
    printer << ")";
}

//===- Generated implementation -------------------------------------------===//

#define GET_OP_CLASSES
#include "quantum-mlir/Dialect/QPU/IR/QPUOps.cpp.inc"

//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
// CircuitOp
//===----------------------------------------------------------------------===//
CircuitOp CircuitOp::create(
    Location location,
    StringRef name,
    FunctionType type,
    ArrayRef<NamedAttribute> attrs)
{
    OpBuilder builder(location->getContext());
    OperationState state(location, getOperationName());
    CircuitOp::build(builder, state, name, type, attrs);
    return cast<CircuitOp>(Operation::create(state));
}

void CircuitOp::build(
    OpBuilder &builder,
    OperationState &state,
    StringRef name,
    FunctionType type,
    ArrayRef<NamedAttribute> attrs,
    ArrayRef<DictionaryAttr> argAttrs)
{
    state.addAttribute(
        SymbolTable::getSymbolAttrName(),
        builder.getStringAttr(name));
    state.addAttribute(
        getFunctionTypeAttrName(state.name),
        TypeAttr::get(type));
    state.attributes.append(attrs.begin(), attrs.end());
    state.addRegion();

    if (argAttrs.empty()) return;
    assert(type.getNumInputs() == argAttrs.size());
    // call_interface_impl
    call_interface_impl::addArgAndResultAttrs(
        builder,
        state,
        argAttrs,
        /*resultAttrs=*/{},
        getArgAttrsAttrName(state.name),
        getResAttrsAttrName(state.name));
}

//===----------------------------------------------------------------------===//
// BitsEqOp
//===----------------------------------------------------------------------===//

mlir::LogicalResult BitsEqOp::verify()
{
    auto bitsType = mlir::cast<mlir::ShapedType>(getBits().getType());
    auto cmpType = mlir::cast<mlir::IntegerType>(getCmp().getType());

    if (bitsType.isDynamicDim(0))
        return emitOpError("requires a statically sized bit sequence");

    if (bitsType.getDimSize(0) != cmpType.getWidth())
        return emitOpError(
            "requires the bit sequence length to equal "
            "the comparison integer bit width");

    return mlir::success();
}

void BitsEqOp::getEffects(
    llvm::SmallVectorImpl<mlir::MemoryEffects::EffectInstance> &effects)
{
    if (llvm::isa<mlir::MemRefType>(getBits().getType()))
        effects.emplace_back(
            mlir::MemoryEffects::Read::get(),
            &getBitsMutable());
}

//===----------------------------------------------------------------------===//
// ToBitsOp
//===----------------------------------------------------------------------===//

void ToBitsOp::getEffects(
    llvm::SmallVectorImpl<mlir::MemoryEffects::EffectInstance> &effects)
{
    auto source = llvm::cast<MeasurementSourceInterface>(getSrc().getType());
    if (source.isMutable())
        effects.emplace_back(
            mlir::MemoryEffects::Read::get(),
            &getSrcMutable());

    auto dst = mlir::cast<mlir::OpResult>(getDst());
    if (!llvm::isa<mlir::MemRefType>(dst.getType())) return;

    effects.emplace_back(mlir::MemoryEffects::Allocate::get(), dst);
    effects.emplace_back(mlir::MemoryEffects::Write::get(), dst);
}

//===----------------------------------------------------------------------===//
// QPUDialect
//===----------------------------------------------------------------------===//

void QPUDialect::registerOps()
{
    addOperations<
#define GET_OP_LIST
#include "quantum-mlir/Dialect/QPU/IR/QPUOps.cpp.inc"
        >();
    addInterfaces<QPUInlinerInterface>();
}
