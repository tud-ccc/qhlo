//===---- QASM2Visitor.cpp -  OpenQASM 2.0 Quantum Visitor ----------------===//
//
// @author  Lars Schütze (lars.schuetze@tu-dresden.de)
//===----------------------------------------------------------------------===//

#include "QASM2Visitor.h"

#include "mlir/IR/Diagnostics.h"
#include "mlir/IR/Location.h"

#include "llvm/ADT/Twine.h"

#include <charconv>

namespace quantum::frontend {

QASM2Visitor::QASM2Visitor(
    mlir::MLIRContext &context,
    mlir::ModuleOp module,
    llvm::StringRef filename)
        : context(context),
          module(module),
          builder(&context),
          filename(filename.str())
{ builder.setInsertionPointToEnd(module.getBody()); }

mlir::Location QASM2Visitor::location(antlr4::ParserRuleContext* ctx) const
{
    const antlr4::Token* token = ctx->getStart();

    return mlir::FileLineColLoc::get(
        &context,
        filename,
        token->getLine(),
        token->getCharPositionInLine() + 1);
}

void QASM2Visitor::error(
    antlr4::ParserRuleContext* ctx,
    const llvm::Twine &message)
{
    hadError = true;
    mlir::emitError(location(ctx)) << message;
}

std::any QASM2Visitor::visitProgram(qasm2::qasm2Parser::ProgramContext* ctx)
{ return visitChildren(ctx); }

std::any QASM2Visitor::visitVersion(qasm2::qasm2Parser::VersionContext* ctx)
{
    if (ctx->VersionSpecifier()->getText() != "2.0")
        error(ctx, "expected OpenQASM version 2.0");

    return {};
}

// ################################################################################
// # Declarations
// ################################################################################

std::any QASM2Visitor::visitOldStyleDeclarationStatement(
    qasm2::qasm2Parser::OldStyleDeclarationStatementContext* ctx)
{

    const std::string name = ctx->Identifier()->getText();

    unsigned size = 0;
    const std::string sizeText =
        ctx->designator()->DecimalIntegerLiteral()->getText();

    auto [ptr, ec] = std::from_chars(
        sizeText.data(),
        sizeText.data() + sizeText.size(),
        size);

    if (ec != std::errc{} || size == 0) {
        error(ctx, "register size must be a positive integer");
        return {};
    }

    if (qregs.contains(name) || cregs.contains(name)) {
        error(ctx, "redefinition of '" + name + "'");
        return {};
    }

    if (ctx->QREG()) {
        //
        // Replace this with your generated Quantum dialect builder.
        //
        // For example conceptually:
        //
        //   auto type = quantum::QubitType::get(&context, size);
        //   auto alloc =
        //       builder.create<quantum::AllocOp>(location(ctx), type);
        //
        //   qregs[name] = { alloc.getResult(), size };
        //

        return {};
    }

    if (ctx->CREG()) {
        //
        // Create whatever representation you use for classical QASM registers.
        //
        // cregs[name] = { ..., size };
        //

        return {};
    }

    llvm_unreachable("QASM2 declaration must be qreg or creg");
}

// ################################################################################
// # Operand resolution
// ################################################################################

std::optional<QASM2Visitor::QuantumOperand>
QASM2Visitor::resolveQuantumOperand(qasm2::qasm2Parser::GateOperandContext* ctx)
{

    auto* indexed = ctx->indexedIdentifier();

    const std::string name = indexed->Identifier()->getText();

    auto it = qregs.find(name);
    if (it == qregs.end()) {
        error(ctx, "unknown quantum register '" + name + "'");
        return std::nullopt;
    }

    QuantumOperand operand{
        .reg = &it->second,
        .index = std::nullopt,
    };

    if (!indexed->designator()) return operand;

    unsigned index = 0;

    const std::string indexText =
        indexed->designator()->DecimalIntegerLiteral()->getText();

    auto [ptr, ec] = std::from_chars(
        indexText.data(),
        indexText.data() + indexText.size(),
        index);

    if (ec != std::errc{}) {
        error(ctx, "invalid qubit index");
        return std::nullopt;
    }

    if (index >= it->second.size) {
        error(
            ctx,
            "qubit index " + llvm::Twine(index)
                + " is out of range for register '" + name + "'");
        return std::nullopt;
    }

    operand.index = index;
    return operand;
}

// ################################################################################
// # Gate calls
// ################################################################################

std::any QASM2Visitor::visitGateCallStatement(
    qasm2::qasm2Parser::GateCallStatementContext* ctx)
{

    if (ctx->U()) {
        // Built-in U gate.
        //
        // 1. Evaluate three expressions.
        // 2. Resolve operand.
        // 3. Broadcast if operand is a whole register.
        // 4. Emit quantum IR.
        //
        return {};
    }

    if (ctx->CX()) {
        const auto operands = ctx->gateOperand();

        assert(operands.size() == 2);

        auto control = resolveQuantumOperand(operands[0]);
        auto target = resolveQuantumOperand(operands[1]);

        if (!control || !target) return {};

        //
        // Handle:
        //
        // CX q[0], r[0];
        // CX q[0], r;
        // CX q,    r[0];
        // CX q,    r;
        //
        // here.
        //

        return {};
    }

    const std::string gateName = ctx->Identifier()->getText();

    //
    // Look up user-defined gate declaration.
    // Check arity.
    // Resolve operands.
    // Perform broadcasting.
    // Emit a call / inline gate body.
    //

    return {};
}

} // namespace quantum::frontend
