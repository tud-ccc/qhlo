//===---- QASM2Visitor.cpp -  OpenQASM 2.0 Quantum Visitor ----------------===//
//
// @author  Lars Schütze (lars.schuetze@tu-dresden.de)
//===----------------------------------------------------------------------===//

#include "QASM2Visitor.h"

#include "GateLibrary.h"
#include "NativeQuantumGate.h"
#include "quantum-mlir/Dialect/QPU/IR/QPUOps.h"
#include "quantum-mlir/Dialect/Quantum/IR/QuantumOps.h"
#include "quantum-mlir/Dialect/Quantum/IR/QuantumTypes.h"

#include <charconv>
#include <cstddef>
#include <llvm/ADT/APInt.h>
#include <llvm/ADT/ArrayRef.h>
#include <llvm/ADT/STLExtras.h>
#include <llvm/ADT/SmallVector.h>
#include <llvm/ADT/Twine.h>
#include <llvm/Support/LogicalResult.h>
#include <mlir/Dialect/Arith/IR/Arith.h>
#include <mlir/Dialect/Math/IR/Math.h>
#include <mlir/Dialect/SCF/IR/SCF.h>
#include <mlir/Dialect/Tensor/IR/Tensor.h>
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

namespace quantum::frontend::qasm2 {

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

namespace {

std::vector<qasm2Parser::GateOperandContext*>
getGateOperands(qasm2Parser::GateCallStatementContext* call)
{
    return call->gateOperandList() ? call->gateOperandList()->gateOperand()
                                   : call->gateOperand();
}

} // namespace

mlir::LogicalResult
QASM2Visitor::ensureGateDefinition(GateDefinition &gate, mlir::Location loc)
{
    if (gate.realized) return mlir::success();

    mlir::OpBuilder::InsertionGuard guard(builder);
    builder.setInsertionPoint(mainCircuit.getOperation());
    // Input types
    llvm::SmallVector<mlir::Type> inputTys;
    inputTys.reserve(gate.qubits.size() + gate.parameters.size());
    inputTys.append(
        gate.qubits.size(),
        mlir::quantum::QubitType::get(&context, 1));
    inputTys.append(gate.parameters.size(), builder.getF64Type());

    // Output types
    llvm::SmallVector<mlir::Type> outputTys;
    outputTys.reserve(gate.qubits.size());
    outputTys.append(
        gate.qubits.size(),
        mlir::quantum::QubitType::get(&context, 1));

    auto ty = mlir::FunctionType::get(
        &context,
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

    // Visit gate body
    auto &gateBlock = gate.gateOp.getBody().emplaceBlock();
    for (auto type : gate.gateOp.getArgumentTypes())
        gateBlock.addArgument(type, loc);

    QASMScope gateScope;
    for (auto [index, name] : llvm::enumerate(gate.parameters))
        gateScope.declareCReg(
            name,
            1,
            gateBlock.getArgument(gate.qubits.size() + index));
    for (auto [index, name] : llvm::enumerate(gate.qubits))
        gateScope.declareQReg(name, 1, gateBlock.getArgument(index));

    QASM2Visitor gateBodyVisitor{
        context,
        module,
        qpuModule,
        mainCircuit,
        gate.filename,
        gateScope,
        gateLibrary,
        includeResolver,
        translationUnit};

    gateBodyVisitor.builder.setInsertionPointToEnd(&gateBlock);
    gateBodyVisitor.visitScope(gate.body);
    if (gateBodyVisitor.failed()) {
        hadError = true;
        return mlir::failure();
    }

    llvm::SmallVector<mlir::Value> returnValues;
    returnValues.reserve(gate.qubits.size());
    for (const auto &name : gate.qubits)
        returnValues.push_back(
            gateScope.lookupQReg(name)->intervals.lookup(0).value);
    mlir::quantum::ReturnOp::create(gateBodyVisitor.builder, loc, returnValues);

    return mlir::success();
}

mlir::Value QASM2Visitor::getOrInitializeClassicalRegister(
    QASMScope::ClassicalRegister &reg,
    mlir::Location loc)
{
    if (!reg.value) {
        auto type =
            mlir::RankedTensorType::get({reg.size}, builder.getI1Type());
        reg.value = mlir::arith::ConstantOp::create(
            builder,
            loc,
            type,
            mlir::DenseElementsAttr::get(type, builder.getBoolAttr(false)));
    }
    return reg.value;
}

mlir::FailureOr<llvm::SmallVector<QuantumOperand>>
QASM2Visitor::prepareConditionalQubits(
    qasm2Parser::QuantumOperationContext* operation)
{
    llvm::SmallVector<qasm2Parser::GateOperandContext*> operands;
    auto* measurement = operation->measureArrowAssignmentStatement();
    if (auto* call = operation->gateCallStatement())
        llvm::append_range(operands, getGateOperands(call));
    else if (auto* reset = operation->resetStatement())
        operands.push_back(reset->gateOperand());
    else
        operands.push_back(measurement->gateOperand(0));

    llvm::SmallVector<QuantumOperand> qubits;
    for (auto* operand : operands) {
        auto* identifier = operand->indexedIdentifier();
        if (measurement && !identifier->designator()) {
            auto* reg = scope.lookupQReg(identifier->Identifier()->getText());
            if (!reg) {
                error(operand, "unknown measurement source register");
                return mlir::failure();
            }
            // Measurement lowers each qubit separately, so split before the if.
            for (unsigned i = 0; i < reg->size; ++i) {
                auto value = scope.materializeQubit(
                    *reg,
                    i,
                    builder,
                    getLocation(operation));
                qubits.push_back({reg, i, value});
            }
        } else {
            auto resolved = resolveQuantumOperand(operand);
            if (!resolved) return mlir::failure();
            qubits.push_back(*resolved);
        }
    }
    return qubits;
}

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

    if (result.ec != std::errc{} || result.ptr != text.data() + text.size()) {
        error(ctx, "invalid integer literal '" + text + "'");
        return std::nullopt;
    }

    return value;
}

namespace {

llvm::SmallVector<mlir::Value> emitGateCall(
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
    if (!size) return {};
    if (*size == 0) {
        error(ctx, "register size must be greater than zero");
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

    if (ctx->CREG()) {
        // TODO: Create an tensor::empty op
        scope.declareCReg(name, *size, mlir::Value{});
        return {};
    }

    error(ctx, "Expected declaration of QREG or CREG");

    return {};
}

// ################################################################################
// # Operand resolution
// ################################################################################

namespace {

void writeQuantumResult(
    llvm::ArrayRef<QuantumOperand> operands,
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

} // namespace

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

    auto parsedIndex =
        parseUnsigned(indexed->designator()->DecimalIntegerLiteral(), ctx);
    if (!parsedIndex) {
        error(ctx, "Could not validate operand index");
        return std::nullopt;
    }
    const unsigned index = *parsedIndex;
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
        error(ctx, "malformed include statement");
        return {};
    }

    const std::string includeName =
        text.substr(firstQuote + 1, lastQuote - firstQuote - 1);

    auto resolved = includeResolver.resolve(includeName, filename);
    if (!resolved) {
        error(
            ctx,
            "failed to resolve include '" + includeName
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
            if (auto* parameter =
                    scope.lookupCReg(literal->Identifier()->getText())) {
                if (!parameter->value || !parameter->value.getType().isF64()) {
                    error(ctx, "gate parameters must have type f64");
                    return {};
                }
                return parameter->value;
            }
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
    const auto operands = getGateOperands(ctx);

    llvm::SmallVector<QuantumOperand> qubitValues;
    qubitValues.reserve(operands.size());
    llvm::SmallVector<mlir::Value> qubits;
    qubits.reserve(operands.size());

    for (auto* operand : operands) {
        auto resolved = resolveQuantumOperand(operand);
        if (!resolved) return {};
        qubitValues.push_back(*resolved);
        qubits.push_back(resolved->value);
    }

    llvm::SmallVector<mlir::Value> parameterValues;
    if (auto* list = ctx->expressionList()) {
        const auto expressions = list->expression();
        parameterValues.reserve(expressions.size());
        for (auto* expression : expressions) {
            auto value = resolveClassicExpression(expression);
            if (!value) return {};
            if (!value.getType().isF64()) {
                error(ctx, "gate parameters must have type f64");
                return {};
            }
            parameterValues.push_back(value);
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
            error(
                ctx,
                llvm::Twine("gate operand'") + name + "' cannot be resolved");
            return {};
        }
        if (qubits.size() != gate->qubits.size()
            || parameterValues.size() != gate->parameters.size()) {
            error(
                ctx,
                "gate '" + name + "' expects "
                    + llvm::Twine(gate->qubits.size()) + " qubit operands and "
                    + llvm::Twine(gate->parameters.size()) + " parameters");
            return {};
        }
        for (mlir::Value qubit : qubits) {
            if (qubit.getType() != mlir::quantum::QubitType::get(&context, 1)) {
                error(ctx, "custom gate operands must be individual qubits");
                return {};
            }
        }
        if (mlir::failed(ensureGateDefinition(*gate, getLocation(ctx)))) {
            hadError = true;
            return {};
        }
        results = emitGateCall(
            *gate,
            getLocation(ctx),
            builder,
            qubits,
            parameterValues);
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

    if (!gateLibrary.insert(std::move(definition)))
        error(ctx, llvm::Twine("gate '") + name + "' already defined");
    return {};
}

// ################################################################################
// # Measurement
// #################################################################################

std::any QASM2Visitor::visitMeasureArrowAssignmentStatement(
    qasm2Parser::MeasureArrowAssignmentStatementContext* ctx)
{
    auto* source = ctx->gateOperand(0)->indexedIdentifier();
    auto* destination = ctx->gateOperand(1)->indexedIdentifier();
    const std::string quantumName = source->Identifier()->getText();
    const std::string classicalName = destination->Identifier()->getText();
    auto* qreg = scope.lookupQReg(quantumName);
    auto* creg = scope.lookupCReg(classicalName);
    if (!qreg) {
        error(ctx, "unknown quantum register '" + quantumName + "'");
        return {};
    }
    if (!creg) {
        error(ctx, "unknown classical register '" + classicalName + "'");
        return {};
    }

    unsigned quantumOffset = 0, classicalOffset = 0;
    unsigned quantumSize = qreg->size, classicalSize = creg->size;
    if (auto* designator = source->designator()) {
        auto index = parseUnsigned(designator->DecimalIntegerLiteral(), ctx);
        if (!index) return {};
        if (*index >= qreg->size) {
            error(ctx, "invalid or out-of-range qubit index");
            return {};
        }
        quantumOffset = *index;
        quantumSize = 1;
    }
    if (auto* designator = destination->designator()) {
        auto index = parseUnsigned(designator->DecimalIntegerLiteral(), ctx);
        if (!index) return {};
        if (*index >= creg->size) {
            error(ctx, "invalid or out-of-range classical bit index");
            return {};
        }
        classicalOffset = *index;
        classicalSize = 1;
    }
    if (quantumSize != classicalSize) {
        error(ctx, "measurement source and destination sizes must match");
        return {};
    }

    const auto loc = getLocation(ctx);
    auto bitType = builder.getI1Type();
    getOrInitializeClassicalRegister(*creg, loc);

    auto measurementType = mlir::quantum::MeasurementType::get(&context, 1);
    auto tensorType = mlir::RankedTensorType::get({1}, bitType);
    for (unsigned i = 0; i < quantumSize; ++i) {
        const unsigned index = quantumOffset + i;
        auto qubit = scope.materializeQubit(*qreg, index, builder, loc);
        auto measurement = mlir::quantum::MeasureOp::create(
            builder,
            loc,
            measurementType,
            qubit.getType(),
            qubit);
        qreg->intervals.lookup(index).value = measurement.getResult();
        auto result = mlir::qpu::ToBitsOp::create(
            builder,
            loc,
            tensorType,
            measurement.getMeasurement());
        creg->value = mlir::tensor::InsertSliceOp::create(
            builder,
            loc,
            result.getResult(),
            creg->value,
            llvm::ArrayRef<mlir::OpFoldResult>{
                builder.getIndexAttr(classicalOffset + i)},
            llvm::ArrayRef<mlir::OpFoldResult>{builder.getIndexAttr(1)},
            llvm::ArrayRef<mlir::OpFoldResult>{builder.getIndexAttr(1)});
    }
    return {};
}

// ################################################################################
// # Reset and Barrier
// #################################################################################

std::any
QASM2Visitor::visitResetStatement(qasm2Parser::ResetStatementContext* ctx)
{
    auto operand = ctx->gateOperand();
    auto resolved = resolveQuantumOperand(operand);
    if (!resolved) return {};
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
{
    llvm::SmallVector<QuantumOperand> requests;
    const auto loc = getLocation(ctx);
    for (auto* operand : ctx->gateOperandList()->gateOperand()) {
        auto* indexed = operand->indexedIdentifier();
        const auto name = indexed->Identifier()->getText();
        auto* reg = scope.lookupQReg(name);
        if (!reg) {
            error(ctx, "unknown quantum register '" + name + "'");
            return {};
        }

        std::optional<unsigned> index;
        if (auto* designator = indexed->designator()) {
            index = parseUnsigned(designator->DecimalIntegerLiteral(), ctx);
            if (!index) return {};
            if (*index >= reg->size) {
                error(ctx, "invalid or out-of-range qubit index");
                return {};
            }
            scope.materializeQubit(*reg, *index, builder, loc);
        }
        requests.push_back({reg, index, {}});
    }

    // Collect values after all indexed operands have split their registers.
    // Keep existing register intervals intact and include overlapping operands
    // only once so each qubit has a single input and output at the barrier.
    llvm::SmallVector<QuantumOperand> operands;
    for (const auto &request : requests) {
        for (const auto &interval : request.reg->intervals.intervals()) {
            if (request.index && interval.start != *request.index) continue;
            if (llvm::any_of(operands, [&](const QuantumOperand &existing) {
                    return existing.reg == request.reg
                           && existing.index == interval.start;
                }))
                continue;
            operands.push_back({request.reg, interval.start, interval.value});
        }
    }

    llvm::SmallVector<mlir::Value> values;
    llvm::SmallVector<mlir::Type> types;
    for (const auto &operand : operands) {
        values.push_back(operand.value);
        types.push_back(operand.value.getType());
    }
    auto barrier =
        mlir::quantum::BarrierOp::create(builder, loc, types, values);
    writeQuantumResult(operands, barrier->getResults());
    return {};
}

// ################################################################################
// # Opaque (currently not supported)
// #################################################################################

std::any QASM2Visitor::visitOpaqueDeclarationStatement(
    qasm2Parser::OpaqueDeclarationStatementContext* ctx)
{
    error(ctx, "opaque gate declarations are unsupported");
    return {};
}

// ################################################################################
// # Controlflow
// #################################################################################

std::any QASM2Visitor::visitIfStatement(qasm2Parser::IfStatementContext* ctx)
{
    // OpenQASM 2 conditionals guard a single gate call, measurement, or reset.
    auto* operation = ctx->quantumOperation();
    if (!operation
        || (!operation->gateCallStatement()
            && !operation->measureArrowAssignmentStatement()
            && !operation->resetStatement())) {
        error(ctx, "an if body must be a gate call, measurement, or reset");
        return {};
    }

    // Evaluate the condition using the classical register's current value.
    auto* creg = scope.lookupCReg(ctx->Identifier()->getText());
    if (!creg) {
        error(
            ctx,
            "unknown classical register '" + ctx->Identifier()->getText()
                + "'");
        return {};
    }

    // Match the comparison integer's width to the number of classical bits.
    const auto literal = ctx->DecimalIntegerLiteral()->getText();

    if (llvm::APInt::getBitsNeeded(literal, 10) > creg->size) {
        error(ctx, "comparison literal does not fit in the classical register");
        return {};
    }

    auto constant = mlir::arith::ConstantOp::create(
        builder,
        getLocation(ctx),
        builder.getIntegerAttr(
            builder.getIntegerType(creg->size),
            llvm::APInt(creg->size, literal, 10)));

    if (!creg->value) {
        error(ctx, "Cannot compare to a non-existing value");
        return {};
    }

    auto eq = mlir::qpu::BitsEqOp::create(
        builder,
        getLocation(ctx),
        builder.getI1Type(),
        creg->value,
        constant);

    // Split qubits before entering either branch so both paths share the same
    // interval layout and no split results escape their defining region.
    auto preparedQubits = prepareConditionalQubits(operation);
    if (mlir::failed(preparedQubits)) return {};
    const auto &qubits = *preparedQubits;

    // A conditional measurement also updates classical state. Ensure that the
    // false path has a destination value to preserve if measurement is skipped.
    QASMScope::ClassicalRegister* destination = nullptr;
    if (auto* measurement = operation->measureArrowAssignmentStatement()) {
        auto* identifier = measurement->gateOperand(1)->indexedIdentifier();
        destination = scope.lookupCReg(identifier->Identifier()->getText());
        if (!destination) {
            error(ctx, "unknown measurement destination register");
            return {};
        }
        getOrInitializeClassicalRegister(*destination, getLocation(ctx));
    }

    // Keep the incoming state for the false path. Both branches yield qubits
    // first, followed by the full destination tensor for a measurement.
    llvm::SmallVector<mlir::Value> originalValues;
    for (const auto &qubit : qubits)
        originalValues.push_back(
            qubit.reg->intervals.lookup(qubit.index.value_or(0)).value);
    if (destination) originalValues.push_back(destination->value);

    auto ifOp = mlir::scf::IfOp::create(
        builder,
        getLocation(ctx),
        eq.getResult(),
        [&](mlir::OpBuilder &bodyBuilder, mlir::Location loc) {
            // Lowering updates the scope with branch-local values. Yield them
            // so the conditional can expose the updated state to later code.
            operation->accept(this);
            llvm::SmallVector<mlir::Value> updatedValues;
            for (const auto &qubit : qubits)
                updatedValues.push_back(
                    qubit.reg->intervals.lookup(qubit.index.value_or(0)).value);
            if (destination) updatedValues.push_back(destination->value);
            mlir::scf::YieldOp::create(bodyBuilder, loc, updatedValues);
        },
        [&](mlir::OpBuilder &bodyBuilder, mlir::Location loc) {
            // Skipping the operation preserves the incoming register state.
            mlir::scf::YieldOp::create(bodyBuilder, loc, originalValues);
        });

    // Replace branch-local scope values with the merged conditional results,
    // which are visible to operations following the if.
    writeQuantumResult(qubits, ifOp.getResults().take_front(qubits.size()));
    if (destination) destination->value = ifOp.getResults().back();

    return {};
}

} // namespace quantum::frontend::qasm2
