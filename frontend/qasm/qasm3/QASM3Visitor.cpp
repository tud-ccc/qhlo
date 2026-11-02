//===---- QASM3Visitor.cpp -  OpenQASM 3 Visitor ------------------------===//
//
// @author  Lars Schütze (lars.schuetze@tu-dresden.de)
//===----------------------------------------------------------------------===//

#include "QASM3Visitor.h"

#include "QASMScope.h"
#include "quantum-mlir/Dialect/QPU/IR/QPUOps.h"
#include "quantum-mlir/Dialect/Quantum/IR/QuantumOps.h"
#include "quantum-mlir/Dialect/Quantum/IR/QuantumTypes.h"

#include <any>
#include <charconv>
#include <llvm/ADT/STLExtras.h>
#include <llvm/ADT/SmallVector.h>
#include <llvm/ADT/Twine.h>
#include <llvm/Support/LogicalResult.h>
#include <mlir/Dialect/Arith/IR/Arith.h>
#include <mlir/Dialect/Math/IR/Math.h>
#include <mlir/Dialect/SCF/IR/SCF.h>
#include <mlir/Dialect/Tensor/IR/Tensor.h>
#include <mlir/IR/Builders.h>
#include <mlir/IR/BuiltinTypeInterfaces.h>
#include <mlir/IR/BuiltinTypes.h>
#include <mlir/IR/Diagnostics.h>
#include <mlir/IR/Location.h>
#include <mlir/IR/MLIRContext.h>
#include <mlir/IR/TypeRange.h>
#include <mlir/IR/Value.h>
#include <mlir/IR/ValueRange.h>
#include <mlir/Support/LLVM.h>

namespace quantum::frontend::qasm3 {

QASM3Visitor::QASM3Visitor(
    mlir::MLIRContext &context,
    mlir::ModuleOp module,
    mlir::qpu::QPUModuleOp qpuModule,
    mlir::qpu::CircuitOp mainCircuit,
    llvm::StringRef filename,
    QASMScope &scope)
        : context(context),
          module(module),
          qpuModule(qpuModule),
          builder(&context),
          mainCircuit(mainCircuit),
          filename(filename.str()),
          scope(scope)
{
    context.loadDialect<mlir::arith::ArithDialect, mlir::math::MathDialect>();
    builder.setInsertionPointToEnd(&mainCircuit.getBody().front());
}

// ################################################################################
// # Simple Helpers
// ################################################################################

mlir::Location QASM3Visitor::getLocation(antlr4::ParserRuleContext* ctx) const
{
    const antlr4::Token* token = ctx->getStart();

    return mlir::FileLineColLoc::get(
        &context,
        filename,
        token->getLine(),
        token->getCharPositionInLine() + 1);
}

void QASM3Visitor::error(
    antlr4::ParserRuleContext* ctx,
    const llvm::Twine &message)
{
    hadError = true;
    mlir::emitError(getLocation(ctx)) << message;
}

namespace {

llvm::FailureOr<mlir::Type>
getMlirType(mlir::MLIRContext &context, qasm3Parser::ScalarTypeContext* type)
{
    if (type->ANGLE()) return llvm::failure();
    if (type->BIT()) return mlir::Builder(&context).getI1Type();
}

} // namespace

// ################################################################################
// # Generate Quantum MLIR gates
// ################################################################################

// ################################################################################
// # Program and Version
// ################################################################################

std::any QASM3Visitor::visitProgram(qasm3Parser::ProgramContext* ctx)
{ return visitChildren(ctx); }

std::any QASM3Visitor::visitVersion(qasm3Parser::VersionContext* ctx)
{
    // The version string is optional
    // We currently do not care
    return visitChildren(ctx);
}

// ################################################################################
// # Expressions
// ################################################################################

std::any QASM3Visitor::visitParenthesisExpression(
    qasm3Parser::ParenthesisExpressionContext* ctx)
{ return ctx->expression()->accept(this); }

std::any
QASM3Visitor::visitLiteralExpression(qasm3Parser::LiteralExpressionContext* ctx)
{
    // Identifier
    if (auto node = ctx->Identifier()) {
        auto id = node->getText();
        // search for identifier
        error(ctx, "unknown parameter '" + id + "'");
        return {};
    }
    // antlr4::tree::TerminalNode* BinaryIntegerLiteral();
    // antlr4::tree::TerminalNode* OctalIntegerLiteral();
    if (auto node = ctx->DecimalIntegerLiteral()) {
        const std::string text = node->getText();
        int64_t value;
        const auto [end, ec] =
            std::from_chars(text.data(), text.data() + text.size(), value);
        if (ec != std::errc{} || end != text.data() + text.size()) {
            error(ctx, "invalid numeric literal '" + text + "'");
            return {};
        }
        return value;
    }
    // antlr4::tree::TerminalNode* HexIntegerLiteral();
    // antlr4::tree::TerminalNode* FloatLiteral();
    // antlr4::tree::TerminalNode* ImaginaryLiteral();
    // antlr4::tree::TerminalNode* BooleanLiteral();
    // antlr4::tree::TerminalNode* BitstringLiteral();
    // antlr4::tree::TerminalNode* TimingLiteral();
    // antlr4::tree::TerminalNode* HardwareQubit();
    return {};
}

// ################################################################################
// # Declarations
// ################################################################################

std::any QASM3Visitor::visitQuantumDeclarationStatement(
    qasm3Parser::QuantumDeclarationStatementContext* ctx)
{
    int64_t size = 1;
    // Check if single qubit or register
    if (auto des = ctx->qubitType()->designator()) {
        if (auto expr = des->expression()) {
            auto value = expr->accept(this);
            // expression must be 1) integer literal, 2) const integer variable
            if (value.type() == typeid(int64_t))
                size = std::any_cast<int64_t>(value);
            else
                error(ctx, "Expected const quantum register length expression");
            // Extract constant value into variable size
        } else {
            error(ctx, "Expected expression inside designator");
        }
    }

    auto type = mlir::quantum::QubitType::get(&context, size);
    auto alloc = mlir::quantum::AllocOp::create(
        builder,
        getLocation(ctx),
        type,
        mlir::IntegerAttr{});

    // Add the qubit to the scope
    auto id = ctx->Identifier()->getText();
    scope.declareQReg(id, size, alloc.getResult());

    return {};
}

std::any QASM3Visitor::visitClassicalDeclarationStatement(
    qasm3Parser::ClassicalDeclarationStatementContext* ctx)
{
    const auto id = ctx->Identifier()->getText();

    if (auto ty = ctx->arrayType()) {
        error(ctx, "Array declarations not implemented yet for '" + id + "'");
        return {};
    }

    // Check if the statement declares an array or scalar type
    if (auto ty = ctx->scalarType()) {
        auto mlirTy = getMlirType(context, ty);
        if (llvm::failed(mlirTy)) {
            error(ctx, "Could not infer the MLIR type for '" + id + "'");
            return {};
        }

        int64_t size = 1;
        // Check if single qubit or register
        if (auto des = ty->designator()) {
            if (auto expr = des->expression()) {
                auto value = expr->accept(this);
                // Expression must be "integer literal" or "const integer"
                if (value.type() == typeid(int64_t)) {
                    size = std::any_cast<int64_t>(value);
                } else {
                    error(ctx, "Expected const scalar array length expression");
                    return {};
                }
            } else {
                error(ctx, "Expected expression inside designator");
                return {};
            }
        }

        auto rankedTy = mlir::RankedTensorType::get({size}, *mlirTy);
        auto op = mlir::arith::ConstantOp::create(
            builder,
            getLocation(ctx),
            rankedTy,
            mlir::DenseElementsAttr::get(rankedTy, builder.getBoolAttr(false)));

        scope.declareCReg(id, size, op.getResult());
        return {};
    }
    error(ctx, "Semantic problem with the classical declaration statement");
    return {};
}

std::any QASM3Visitor::visitConstDeclarationStatement(
    qasm3Parser::ConstDeclarationStatementContext* ctx)
{
    error(ctx, "ConstDeclarationStatementContext not implemented yet.");
    return {};
}

// ################################################################################
// # Operand resolution
// ################################################################################

// ################################################################################
// # Statements
// ################################################################################

std::any
QASM3Visitor::visitResetStatement(qasm3Parser::ResetStatementContext* ctx)
{
    auto operand = ctx->gateOperand();
    auto idnode = operand ? operand->indexedIdentifier() : nullptr;

    if (!idnode || !idnode->Identifier()) {
        error(ctx, "Expected a quantum register operand for reset");
        return {};
    }

    if (!idnode->indexOperator().empty()) {
        error(ctx, "Indexed reset operands are not implemented yet");
        return {};
    }

    auto id = idnode->Identifier()->getText();
    auto qreg = scope.lookupQReg(id);

    if (!qreg) {
        error(ctx, "Unknown quantum register '" + id + "'");
        return {};
    }

    for (const auto &interval : qreg->intervals.intervals()) {
        auto reset = mlir::quantum::ResetOp::create(
            builder,
            getLocation(ctx),
            interval.value.getType(),
            interval.value);
        qreg->intervals.lookup(interval.start).value = reset.getResult();
    }
    return {};
}

} // namespace quantum::frontend::qasm3
