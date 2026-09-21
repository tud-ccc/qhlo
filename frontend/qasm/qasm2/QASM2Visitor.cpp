//===---- QASM2Visitor.cpp -  OpenQASM 2.0 Quantum Visitor ----------------===//
//
// @author  Lars Schütze (lars.schuetze@tu-dresden.de)
//===----------------------------------------------------------------------===//

#include "QASM2Visitor.h"

#include "GateLibrary.h"
#include "quantum-mlir/Dialect/QPU/IR/QPUOps.h"
#include "quantum-mlir/Dialect/Quantum/IR/QuantumOps.h"
#include "quantum-mlir/Dialect/Quantum/IR/QuantumTypes.h"

#include <charconv>
#include <cstddef>
#include <llvm/ADT/STLExtras.h>
#include <llvm/ADT/SmallVector.h>
#include <llvm/ADT/Twine.h>
#include <llvm/Support/LogicalResult.h>
#include <mlir/Dialect/Arith/IR/Arith.h>
#include <mlir/Dialect/Math/IR/Math.h>
#include <mlir/IR/Builders.h>
#include <mlir/IR/BuiltinTypes.h>
#include <mlir/IR/Diagnostics.h>
#include <mlir/IR/Location.h>
#include <mlir/IR/TypeRange.h>
#include <mlir/IR/ValueRange.h>
#include <mlir/Support/LLVM.h>
#include <numbers>
#include <optional>
#include <vector>

using namespace qasm2;

namespace quantum::frontend {

QASM2Visitor::QASM2Visitor(
    mlir::MLIRContext &context,
    mlir::ModuleOp module,
    mlir::qpu::QPUModuleOp qpuModule,
    mlir::qpu::CircuitOp mainCircuit,
    llvm::StringRef filename,
    QASMScope &scope,
    GateLibrary &gateLibrary,
    QASMIncludeResolver &includeResolver,
    qasm2::QASM2TranslationUnit &translationUnit)
        : context(context),
          module(module),
          qpuModule(qpuModule),
          builder(&context),
          mainCircuit(mainCircuit),
          filename(filename.str()),
          scope(scope),
          gateLibrary(gateLibrary),
          includeResolver(includeResolver),
          translationUnit(translationUnit)
{
    context.loadDialect<mlir::arith::ArithDialect, mlir::math::MathDialect>();
    builder.setInsertionPointToEnd(&mainCircuit.getBody().front());
}

// ################################################################################
// # Simple Helpers
// ################################################################################

mlir::Location QASM2Visitor::getLocation(antlr4::ParserRuleContext* ctx) const
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
    mlir::emitError(getLocation(ctx)) << message;
}

std::optional<unsigned> QASM2Visitor::parseUnsigned(
    antlr4::tree::TerminalNode* node,
    antlr4::ParserRuleContext* ctx)
{
    const std::string text = node->getText();

    unsigned value = 0;

    auto result =
        std::from_chars(text.data(), text.data() + text.size(), value);

    if (result.ec != std::errc{}) {
        mlir::emitError(
            getLocation(ctx),
            "invalid integer literal '" + text + "'");
        return std::nullopt;
    }

    return value;
}

namespace {

/// These gates are natively supported by the MLIR Quantum dialect
enum class QuantumNativeGate {
    H,
    X,
    Y,
    Z,
    S,
    SX,
    T,
    Sdg,
    Tdg,
    CZ,
    CX,
    SWAP,
    RX,
    RY,
    RZ,
    P,
    U,
    U1,
    U2,
    U3,
    CRZ,
    CRY,
    CU1,
    CCX,
    CSWAP
};

struct NativeGateSpec {
    QuantumNativeGate kind;
    unsigned qubitCount;
    unsigned parameterCount;
};

std::optional<NativeGateSpec> lookupNativeQuantumGate(llvm::StringRef name)
{
    return llvm::StringSwitch<std::optional<NativeGateSpec>>(name)
        // Unary operations
        .Case("x", NativeGateSpec{QuantumNativeGate::X, 1, 0})
        .Case("y", NativeGateSpec{QuantumNativeGate::Y, 1, 0})
        .Case("z", NativeGateSpec{QuantumNativeGate::Z, 1, 0})
        .Case("h", NativeGateSpec{QuantumNativeGate::H, 1, 0})
        .Case("p", NativeGateSpec{QuantumNativeGate::P, 1, 0})
        .Case("s", NativeGateSpec{QuantumNativeGate::S, 1, 0})
        .Case("sx", NativeGateSpec{QuantumNativeGate::SX, 1, 0})
        .Case("sdg", NativeGateSpec{QuantumNativeGate::Sdg, 1, 0})
        .Case("t", NativeGateSpec{QuantumNativeGate::T, 1, 0})
        .Case("tdg", NativeGateSpec{QuantumNativeGate::Tdg, 1, 0})
        // Unary operations with operand
        .Case("rx", NativeGateSpec{QuantumNativeGate::RX, 1, 1})
        .Case("ry", NativeGateSpec{QuantumNativeGate::RY, 1, 1})
        .Case("rz", NativeGateSpec{QuantumNativeGate::RZ, 1, 1})
        // Controlled gates (2 qubits)
        .Case("cz", NativeGateSpec{QuantumNativeGate::CZ, 2, 0})
        .Case("cx", NativeGateSpec{QuantumNativeGate::CX, 2, 0})
        .Case("swap", NativeGateSpec{QuantumNativeGate::SWAP, 2, 0})
        // Controlled rotations
        .Case("crz", NativeGateSpec{QuantumNativeGate::CRZ, 2, 1})
        .Case("cry", NativeGateSpec{QuantumNativeGate::CRY, 2, 1})
        .Case("cu1", NativeGateSpec{QuantumNativeGate::CU1, 2, 1})
        // 3 Qubit gates
        .Case("ccx", NativeGateSpec{QuantumNativeGate::CCX, 3, 0})
        .Case("cswap", NativeGateSpec{QuantumNativeGate::CSWAP, 3, 0})
        // U gates
        .Case("u1", NativeGateSpec{QuantumNativeGate::U1, 1, 1})
        .Case("u2", NativeGateSpec{QuantumNativeGate::U2, 1, 2})
        .Case("u3", NativeGateSpec{QuantumNativeGate::U3, 1, 3})
        .Case("u", NativeGateSpec{QuantumNativeGate::U3, 1, 3})
        .Default(std::nullopt);
}

// ################################################################################
// # Generate Quantum MLIR gates
// ################################################################################

template<typename Op>
llvm::SmallVector<mlir::Value> createNativeGate(
    mlir::Location loc,
    mlir::OpBuilder &builder,
    mlir::ValueRange qubits,
    mlir::ValueRange parameters)
{
    llvm::SmallVector<mlir::Type> resultTypes;
    for (mlir::Value qubit : qubits) resultTypes.push_back(qubit.getType());

    llvm::SmallVector<mlir::Value> operands(qubits.begin(), qubits.end());
    operands.append(parameters.begin(), parameters.end());

    auto op = Op::create(
        builder,
        loc,
        mlir::TypeRange(resultTypes),
        mlir::ValueRange(operands));

    auto results = op->getResults();
    return llvm::SmallVector<mlir::Value>(results.begin(), results.end());
}

mlir::FailureOr<llvm::SmallVector<mlir::Value>> emitNativeGate(
    const NativeGateSpec &spec,
    mlir::Location loc,
    mlir::OpBuilder &builder,
    mlir::ValueRange qubits,
    mlir::ValueRange parameters)
{
    if (qubits.size() != spec.qubitCount
        || parameters.size() != spec.parameterCount) {
        mlir::emitError(loc)
            << "expected " << spec.qubitCount << " qubit operands and "
            << spec.parameterCount << " parameters, got " << qubits.size()
            << " and " << parameters.size();
        return mlir::failure();
    }

    // Capture the common arguments once.
    auto emit = [&]<typename Op>() {
        return createNativeGate<Op>(loc, builder, qubits, parameters);
    };

    using namespace mlir::quantum;

    switch (spec.kind) {
    case QuantumNativeGate::H: return emit.operator()<HOp>();
    case QuantumNativeGate::X: return emit.operator()<XOp>();
    case QuantumNativeGate::Y: return emit.operator()<YOp>();
    case QuantumNativeGate::Z: return emit.operator()<ZOp>();
    case QuantumNativeGate::S: return emit.operator()<SOp>();
    case QuantumNativeGate::SX: return emit.operator()<SXOp>();
    case QuantumNativeGate::T: return emit.operator()<TOp>();
    case QuantumNativeGate::Sdg: return emit.operator()<SdgOp>();
    case QuantumNativeGate::Tdg: return emit.operator()<TdgOp>();
    case QuantumNativeGate::CX: return emit.operator()<CNOTOp>();
    case QuantumNativeGate::CZ: return emit.operator()<CZOp>();
    case QuantumNativeGate::SWAP: return emit.operator()<SWAPOp>();
    case QuantumNativeGate::RX: return emit.operator()<RxOp>();
    case QuantumNativeGate::RY: return emit.operator()<RyOp>();
    case QuantumNativeGate::RZ: return emit.operator()<RzOp>();
    case QuantumNativeGate::P: return emit.operator()<PhaseOp>();
    case QuantumNativeGate::U1: return emit.operator()<U1Op>();
    case QuantumNativeGate::U2: return emit.operator()<U2Op>();
    case QuantumNativeGate::U:
    case QuantumNativeGate::U3: return emit.operator()<U3Op>();
    case QuantumNativeGate::CRZ: return emit.operator()<CRzOp>();
    case QuantumNativeGate::CRY: return emit.operator()<CRyOp>();
    case QuantumNativeGate::CU1: return emit.operator()<CU1Op>();
    case QuantumNativeGate::CCX: return emit.operator()<CCXOp>();
    case QuantumNativeGate::CSWAP: return emit.operator()<CSWAPOp>();
    }

    mlir::emitError(loc) << "unsupported native gate";
    return mlir::failure();
}

llvm::LogicalResult emitGateDefition(
    GateDefinition &gate,
    mlir::Location loc,
    mlir::OpBuilder &builder)
{
    // Input types
    llvm::SmallVector<mlir::Type> inputTys;
    inputTys.reserve(gate.qubits.size() + gate.parameters.size());
    inputTys.append(
        gate.qubits.size(),
        mlir::quantum::QubitType::get(builder.getContext(), 1));
    inputTys.append(gate.parameters.size(), builder.getF64Type());

    // Output types
    llvm::SmallVector<mlir::Type> outputTys;
    outputTys.reserve(gate.qubits.size());
    outputTys.append(
        gate.qubits.size(),
        mlir::quantum::QubitType::get(builder.getContext(), 1));

    auto ty = mlir::FunctionType::get(
        builder.getContext(),
        mlir::TypeRange(inputTys),
        mlir::TypeRange(outputTys));

    auto op = mlir::quantum::GateOp::create(
        builder,
        loc,
        gate.name,
        ty,
        mlir::ArrayRef<mlir::NamedAttribute>{});

    gate.gateOp = op;
    gate.realized = true;

    return llvm::success();
}

mlir::FailureOr<llvm::SmallVector<mlir::Value>> emitGateCall(
    const GateDefinition &gate,
    mlir::Location loc,
    mlir::OpBuilder &builder,
    mlir::ValueRange qubits,
    mlir::ValueRange parameters)
{
    llvm::SmallVector<mlir::Value> operands;
    operands.reserve(qubits.size() + parameters.size());
    operands.append(qubits.begin(), qubits.end());
    operands.append(parameters.begin(), parameters.end());

    auto op = mlir::quantum::GateCallOp::create(
        builder,
        loc,
        gate.gateOp,
        mlir::ValueRange(operands));

    auto results = op->getResults();
    return llvm::SmallVector<mlir::Value>(results.begin(), results.end());
}

} // namespace

// ################################################################################
// # Program and Version
// ################################################################################

std::any QASM2Visitor::visitProgram(qasm2Parser::ProgramContext* ctx)
{ return visitChildren(ctx); }

std::any QASM2Visitor::visitVersion(qasm2Parser::VersionContext* ctx)
{
    if (ctx->VersionSpecifier()->getText() != "2.0")
        error(ctx, "expected OpenQASM version 2.0");

    return {};
}

// ################################################################################
// # Declarations
// ################################################################################

std::any QASM2Visitor::visitOldStyleDeclarationStatement(
    qasm2Parser::OldStyleDeclarationStatementContext* ctx)
{
    const std::string name = ctx->Identifier()->getText();

    if (scope.lookupQReg(name) || scope.lookupCReg(name)) {
        error(ctx, "redefinition of '" + name + "'");
        return {};
    }

    auto size = parseUnsigned(ctx->designator()->DecimalIntegerLiteral(), ctx);

    if (!size || *size == 0) {
        mlir::emitError(
            getLocation(ctx),
            "register size must be greater than zero");
        return {};
    }

    if (ctx->QREG()) {
        auto type = mlir::quantum::QubitType::get(&context, *size);
        auto alloc = mlir::quantum::AllocOp::create(
            builder,
            getLocation(ctx),
            type,
            mlir::IntegerAttr{});

        scope.declareQReg(name, *size, alloc.getResult());

        return {};
    }

    assert(ctx->CREG());

    scope.declareCReg(name, *size, mlir::Value{});

    return {};
}

// ################################################################################
// # Operand resolution
// ################################################################################

void writeQuantumResult(
    const llvm::SmallVector<QuantumOperand> &operands,
    mlir::ValueRange results)
{
    for (auto [operand, result] : llvm::zip_equal(operands, results)) {
        assert(operand.reg);
        if (operand.index) {
            auto &interval = operand.reg->intervals.lookup(*operand.index);
            interval.value = result;
        } else {
            operand.reg->intervals.set(0, operand.reg->size, result);
        }
    }
}

std::optional<QuantumOperand>
QASM2Visitor::resolveQuantumOperand(qasm2Parser::GateOperandContext* ctx)
{
    // Whether it is an indexed expression, e.g., q[1]
    auto* indexed = ctx->indexedIdentifier();
    // Check if the identifier is defined
    const std::string name = indexed->Identifier()->getText();

    auto* reg = scope.lookupQReg(name);
    if (!reg) {
        error(ctx, "unknown quantum register '" + name + "'");
        return std::nullopt;
    }

    QuantumOperand operand{
        .reg = reg,
        .index = std::nullopt,
        .value = {},
    };

    if (!indexed->designator()) {
        auto &interval = reg->intervals.lookup(0);
        if (interval.size() != reg->size) {
            error(
                ctx,
                "whole-register operands after qubit splitting are "
                "unsupported");
            return std::nullopt;
        }
        operand.value = interval.value;
        return operand;
    }

    // Get the index the quantum register is accessed at
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

    if (index >= reg->size) {
        error(
            ctx,
            "qubit index " + llvm::Twine(index)
                + " is out of range for register '" + name + "'");
        return std::nullopt;
    }

    operand.index = index;
    operand.value =
        scope.materializeQubit(*reg, index, builder, getLocation(ctx));
    return operand;
}

// ################################################################################
// # Inclusion Statement
// #################################################################################

std::any
QASM2Visitor::visitIncludeStatement(qasm2Parser::IncludeStatementContext* ctx)
{
    const std::string text = ctx->StringLiteral()->getText();

    const auto firstQuote = text.find('"');
    const auto lastQuote = text.rfind('"');

    if (firstQuote == std::string::npos || lastQuote == std::string::npos
        || firstQuote == lastQuote) {
        emitError(getLocation(ctx), "malformed include statement");
        return {};
    }

    const std::string includeName =
        text.substr(firstQuote + 1, lastQuote - firstQuote - 1);

    auto resolved = includeResolver.resolve(includeName, filename);
    if (!resolved) {
        emitError(
            getLocation(ctx),
            llvm::Twine("failed to resolve include '") + includeName
                + "': " + llvm::toString(resolved.takeError()));
        return {};
    }

    auto &source = translationUnit.addSource(
        context,
        resolved->source,
        resolved->filename);

    auto* includedSource = source.parseInclude();

    if (source.failed()) {
        hadError = true;
        return {};
    }

    QASM2Visitor includeVisitor{
        context,
        module,
        qpuModule,
        mainCircuit,
        resolved->filename,
        scope,
        gateLibrary,
        includeResolver,
        translationUnit};

    includeVisitor.visit(includedSource);

    if (includeVisitor.failed()) hadError = true;

    return {};
}

// ################################################################################
// # Classic Expressions
// #################################################################################

mlir::Value
QASM2Visitor::resolveClassicExpression(qasm2Parser::ExpressionContext* ctx)
{
    using Parser = qasm2Parser;
    const auto loc = getLocation(ctx);

    // Literal Expressions

    if (auto* literal = dynamic_cast<Parser::LiteralExpressionContext*>(ctx)) {
        if (literal->Identifier()) {
            error(
                ctx,
                "unknown parameter '" + literal->Identifier()->getText() + "'");
            return {};
        }

        double value = std::numbers::pi;
        if (!literal->PI()) {
            const std::string text = literal->getText();
            const auto [end, ec] =
                std::from_chars(text.data(), text.data() + text.size(), value);
            if (ec != std::errc{} || end != text.data() + text.size()) {
                error(ctx, "invalid numeric literal '" + text + "'");
                return {};
            }
        }
        return mlir::arith::ConstantFloatOp::create(
            builder,
            loc,
            builder.getF64Type(),
            llvm::APFloat(value));
    }

    // Parenthesized Expressions

    if (auto* parens = dynamic_cast<Parser::ParenthesisExpressionContext*>(ctx))
        return resolveClassicExpression(parens->expression());

    // Unary Expressions

    if (auto* unary = dynamic_cast<Parser::UnaryExpressionContext*>(ctx)) {
        auto value = resolveClassicExpression(unary->expression());
        if (!value) return {};
        return mlir::arith::NegFOp::create(builder, loc, value);
    }

    // STD function Expressions
    // Directly mapped to math expressions
    if (auto* call = dynamic_cast<Parser::CallExpressionContext*>(ctx)) {
        auto value = resolveClassicExpression(call->expression());
        if (!value) return {};
        auto* op = call->unaryOperator();
        if (op->SIN()) return mlir::math::SinOp::create(builder, loc, value);
        if (op->COS()) return mlir::math::CosOp::create(builder, loc, value);
        if (op->TAN()) return mlir::math::TanOp::create(builder, loc, value);
        if (op->EXP()) return mlir::math::ExpOp::create(builder, loc, value);
        if (op->LN()) return mlir::math::LogOp::create(builder, loc, value);
        if (op->SQRT()) return mlir::math::SqrtOp::create(builder, loc, value);
    }

    // Binary Expressions
    Parser::ExpressionContext* left = nullptr;
    Parser::ExpressionContext* right = nullptr;
    size_t op = 0;
    if (auto* power = dynamic_cast<Parser::PowerExpressionContext*>(ctx)) {
        left = power->expression(0);
        right = power->expression(1);
        op = Parser::CARET;
    } else if (
        auto* mul =
            dynamic_cast<Parser::MultiplicativeExpressionContext*>(ctx)) {
        left = mul->expression(0);
        right = mul->expression(1);
        op = mul->op->getType();
    } else if (
        auto* add = dynamic_cast<Parser::AdditiveExpressionContext*>(ctx)) {
        left = add->expression(0);
        right = add->expression(1);
        op = add->op->getType();
    }
    if (left && right) {
        auto lhs = resolveClassicExpression(left);
        if (!lhs) return {};
        auto rhs = resolveClassicExpression(right);
        if (!rhs) return {};
        switch (op) {
        case Parser::CARET:
            return mlir::math::PowFOp::create(builder, loc, lhs, rhs);
        case Parser::ASTERISK:
            return mlir::arith::MulFOp::create(builder, loc, lhs, rhs);
        case Parser::SLASH:
            return mlir::arith::DivFOp::create(builder, loc, lhs, rhs);
        case Parser::PLUS:
            return mlir::arith::AddFOp::create(builder, loc, lhs, rhs);
        case Parser::MINUS:
            return mlir::arith::SubFOp::create(builder, loc, lhs, rhs);
        }
    }
    error(ctx, "unsupported expression");
    return {};
}

// ################################################################################
// # Gate calls
// #################################################################################

std::any
QASM2Visitor::visitGateCallStatement(qasm2Parser::GateCallStatementContext* ctx)
{
    // Visit and resolve qubit operands
    const auto operands = ctx->gateOperandList()
                              ? ctx->gateOperandList()->gateOperand()
                              : ctx->gateOperand();

    llvm::SmallVector<QuantumOperand> qubitValues;
    qubitValues.reserve(operands.size());
    llvm::SmallVector<mlir::Value> qubits;
    qubits.reserve(qubitValues.size());

    for (auto* operand : operands) {
        auto resolved = resolveQuantumOperand(operand);
        if (!resolved) {
            emitError(
                getLocation(ctx),
                llvm::Twine("gate operand'") + operand->getText()
                    + "' cannot be resolved");
            return {};
        }
        qubitValues.push_back(*resolved);
        qubits.push_back(resolved->value);
    }

    // Visit and resolve parameter expressions
    std::optional<std::vector<qasm2Parser::ExpressionContext*>>
        parameterExpressions;

    if (auto* list = ctx->expressionList())
        parameterExpressions = list->expression();

    llvm::SmallVector<mlir::Value> parameterValues;
    if (parameterExpressions) {
        parameterValues.reserve(parameterExpressions->size());
        for (auto* exprCtx : *parameterExpressions) {
            auto resolved = resolveClassicExpression(exprCtx);
            if (!resolved) {
                emitError(
                    getLocation(ctx),
                    llvm::Twine("gate operand'") + exprCtx->getText()
                        + "' cannot be resolved");
                return {};
            }
            parameterValues.push_back(resolved);
        }
    }

    /// Store the gate name for emission. U3 and CX are special QASM2 gates.
    std::string name;
    if (auto* identifier = ctx->Identifier())
        name = identifier->getText();
    else if (ctx->U())
        name = "u3";
    else if (ctx->CX())
        name = "cx";

    llvm::SmallVector<mlir::Value> results;
    if (auto spec = lookupNativeQuantumGate(name)) {

        auto result = emitNativeGate(
            *spec,
            getLocation(ctx),
            builder,
            qubits,
            parameterValues);

        if (mlir::failed(result)) {
            hadError = true;
            return {};
        }
        results = std::move(*result);
    } else {
        // Lookup gate definition
        auto gate = gateLibrary.lookup(name);
        // Gate was not visited and registered
        if (!gate) {
            emitError(
                getLocation(ctx),
                llvm::Twine("gate operand'") + name + "' cannot be resolved");
            hadError = true;
            return {};
        }
        // Emit defintion if the gate is used the first time
        if (!gate->realized) {
            mlir::OpBuilder::InsertionGuard guard(builder);
            builder.setInsertionPoint(mainCircuit.getOperation());
            auto result = emitGateDefition(*gate, getLocation(ctx), builder);
            if (mlir::failed(result)) {
                hadError = true;
                return {};
            }
            // Visit gate body
            auto &gateBlock = gate->gateOp.getBody().emplaceBlock();
            for (auto type : gate->gateOp.getArgumentTypes())
                gateBlock.addArgument(type, getLocation(ctx));

            QASMScope gateScope;
            for (auto [index, name] : llvm::enumerate(gate->qubits))
                gateScope.declareQReg(name, 1, gateBlock.getArgument(index));

            QASM2Visitor gateBodyVisitor{
                context,
                module,
                qpuModule,
                mainCircuit,
                gate->filename,
                gateScope,
                gateLibrary,
                includeResolver,
                translationUnit};

            gateBodyVisitor.builder.setInsertionPointToEnd(&gateBlock);
            gateBodyVisitor.visitScope(gate->body);
            if (gateBodyVisitor.failed()) {
                hadError = true;
                return {};
            }

            llvm::SmallVector<mlir::Value> returnValues;
            returnValues.reserve(gate->qubits.size());
            for (const auto &name : gate->qubits)
                returnValues.push_back(
                    gateScope.lookupQReg(name)->intervals.lookup(0).value);
            mlir::quantum::ReturnOp::create(
                gateBodyVisitor.builder,
                getLocation(ctx),
                returnValues);

            builder.setInsertionPointToEnd(mainCircuit->getBlock());
        }
        // Call a previously visited GateDefinition
        auto result = emitGateCall(
            *gate,
            getLocation(ctx),
            builder,
            qubits,
            parameterValues);
        if (mlir::failed(result)) {
            hadError = true;
            return {};
        }
        results = std::move(*result);
    }

    // Write result qubit values back
    writeQuantumResult(qubitValues, results);

    return {};
}

// ################################################################################
// # Gate Definition
// #################################################################################

std::any
QASM2Visitor::visitGateStatement(qasm2Parser::GateStatementContext* ctx)
{
    const std::string name = ctx->Identifier()->getText();

    llvm::SmallVector<std::string> parameters;
    llvm::SmallVector<std::string> qubits;

    const auto identifierLists = ctx->identifierList();
    std::size_t qubitListIndex = 0;
    if (ctx->LPAREN() && identifierLists.size() == 2) {
        for (auto* identifier : identifierLists[0]->Identifier())
            parameters.push_back(identifier->getText());

        qubitListIndex = 1;
    }

    for (auto* identifier : identifierLists[qubitListIndex]->Identifier())
        qubits.push_back(identifier->getText());

    GateDefinition definition{
        .name = ctx->Identifier()->getText(),
        .parameters = parameters,
        .qubits = qubits,
        .body = ctx->scope(),
        .filename = filename,
    };

    if (!gateLibrary.insert(std::move(definition))) {
        emitError(
            getLocation(ctx),
            llvm::Twine("gate '") + name + "' already defined");
    }
    return {};
}

// ################################################################################
// # Measurement
// #################################################################################

std::any QASM2Visitor::visitMeasureArrowAssignmentStatement(
    qasm2Parser::MeasureArrowAssignmentStatementContext* ctx)
{ return visitChildren(ctx); }

std::any
QASM2Visitor::visitResetStatement(qasm2Parser::ResetStatementContext* ctx)
{
    auto operand = ctx->gateOperand();
    auto resolved = resolveQuantumOperand(operand);
    if (!resolved) {
        emitError(
            getLocation(ctx),
            llvm::Twine("gate operand'") + operand->getText()
                + "' cannot be resolved");
        return {};
    }
    auto qubit = resolved->value;
    auto result = mlir::quantum::ResetOp::create(
        builder,
        getLocation(ctx),
        qubit.getType(),
        qubit);
    writeQuantumResult(
        llvm::SmallVector<QuantumOperand>{*resolved},
        result->getResults());
    return {};
}

std::any
QASM2Visitor::visitBarrierStatement(qasm2Parser::BarrierStatementContext* ctx)
{ return visitChildren(ctx); }

std::any QASM2Visitor::visitOpaqueDeclarationStatement(
    qasm2Parser::OpaqueDeclarationStatementContext* ctx)
{ return visitChildren(ctx); }

// ################################################################################
// # Controlflow
// #################################################################################

std::any QASM2Visitor::visitIfStatement(qasm2Parser::IfStatementContext* ctx)
{ return visitChildren(ctx); }

} // namespace quantum::frontend
