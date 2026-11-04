//===---- QASM3Visitor.cpp -  OpenQASM 3 Visitor ------------------------===//
//
// @author  Lars Schütze (lars.schuetze@tu-dresden.de)
//===----------------------------------------------------------------------===//

#include "QASM3Visitor.h"

#include "NativeQuantumGate.h"
#include "QASMScope.h"
#include "quantum-mlir/Dialect/QPU/IR/QPUOps.h"
#include "quantum-mlir/Dialect/Quantum/IR/QuantumOps.h"
#include "quantum-mlir/Dialect/Quantum/IR/QuantumTypes.h"

#include <any>
#include <charconv>
#include <limits>
#include <llvm/ADT/STLExtras.h>
#include <llvm/ADT/SmallVector.h>
#include <llvm/ADT/Twine.h>
#include <llvm/Support/ErrorHandling.h>
#include <llvm/Support/LogicalResult.h>
#include <llvm/Support/MathExtras.h>
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
    QASMScope &scope,
    GateLibrary &gateLibrary)
        : context(context),
          module(module),
          qpuModule(qpuModule),
          builder(&context),
          mainCircuit(mainCircuit),
          filename(filename.str()),
          scope(scope),
          gateLibrary(gateLibrary)
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

mlir::LogicalResult
QASM3Visitor::ensureGateDefinition(GateDefinition &gate, mlir::Location loc)
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
    for (auto [index, name] : llvm::enumerate(gate.parameters)) {
        if (!gateScope.declareCReg(
                name,
                1,
                gateBlock.getArgument(gate.qubits.size() + index))) {
            mlir::emitError(loc) << "redefinition of '" << name << "'";
            hadError = true;
            return mlir::failure();
        }
    }
    for (auto [index, name] : llvm::enumerate(gate.qubits)) {
        if (!gateScope
                 .declareQReg(name, 1, gateBlock.getArgument(index), true)) {
            mlir::emitError(loc) << "redefinition of '" << name << "'";
            hadError = true;
            return mlir::failure();
        }
    }

    QASM3Visitor gateBodyVisitor{
        context,
        module,
        qpuModule,
        mainCircuit,
        gate.filename,
        gateScope,
        gateLibrary};

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
            gateScope.lookupQReg(name)->getWholeRegisterValue());
    mlir::quantum::ReturnOp::create(gateBodyVisitor.builder, loc, returnValues);

    return mlir::success();
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

llvm::FailureOr<mlir::Type>
getMlirType(mlir::MLIRContext &context, qasm3Parser::ScalarTypeContext* type)
{
    if (type->BIT()) return mlir::Builder(&context).getI1Type();
    return llvm::failure();
}

} // namespace

mlir::FailureOr<int64_t> QASM3Visitor::evaluateBinaryInteger(
    qasm3Parser::ExpressionContext* expression,
    size_t op,
    qasm3Parser::ExpressionContext* lhs,
    qasm3Parser::ExpressionContext* rhs)
{
    auto left = evaluateConstantInteger(lhs);
    if (mlir::failed(left)) return mlir::failure();
    auto right = evaluateConstantInteger(rhs);
    if (mlir::failed(right)) return mlir::failure();

    int64_t result;
    bool overflow = false;
    switch (op) {
    case qasm3Parser::PLUS:
        overflow = llvm::AddOverflow(*left, *right, result);
        break;
    case qasm3Parser::MINUS:
        overflow = llvm::SubOverflow(*left, *right, result);
        break;
    case qasm3Parser::ASTERISK:
        overflow = llvm::MulOverflow(*left, *right, result);
        break;
    case qasm3Parser::SLASH:
    case qasm3Parser::PERCENT:
        if (*right == 0) {
            error(
                expression,
                "division by zero in constant integer expression");
            return mlir::failure();
        }
        // Both division and remainder overflow for INT64_MIN and -1 in C++.
        overflow = *left == std::numeric_limits<int64_t>::min() && *right == -1;
        if (!overflow)
            return op == qasm3Parser::SLASH ? *left / *right : *left % *right;
        break;
    default: llvm_unreachable("unsupported binary integer operator");
    }
    if (!overflow) return result;
    error(expression, "constant integer expression overflows int64");
    return mlir::failure();
}

mlir::FailureOr<int64_t> QASM3Visitor::evaluateConstantInteger(
    qasm3Parser::ExpressionContext* expression)
{
    if (auto* parens = dynamic_cast<qasm3Parser::ParenthesisExpressionContext*>(
            expression))
        return evaluateConstantInteger(parens->expression());
    if (auto* literal =
            dynamic_cast<qasm3Parser::LiteralExpressionContext*>(expression)) {
        auto value = literal->accept(this);
        if (hadError) return mlir::failure();
        if (auto* integer = std::any_cast<int64_t>(&value)) return *integer;
    }
    if (auto* unary =
            dynamic_cast<qasm3Parser::UnaryExpressionContext*>(expression)) {
        if (unary->op->getType() == qasm3Parser::MINUS) {
            auto value = evaluateConstantInteger(unary->expression());
            if (mlir::failed(value)) return mlir::failure();
            if (*value != std::numeric_limits<int64_t>::min()) return -*value;
            error(expression, "constant integer expression overflows int64");
            return mlir::failure();
        }
    }
    if (auto* add =
            dynamic_cast<qasm3Parser::AdditiveExpressionContext*>(expression))
        return evaluateBinaryInteger(
            expression,
            add->op->getType(),
            add->expression(0),
            add->expression(1));
    if (auto* mul = dynamic_cast<qasm3Parser::MultiplicativeExpressionContext*>(
            expression))
        return evaluateBinaryInteger(
            expression,
            mul->op->getType(),
            mul->expression(0),
            mul->expression(1));

    error(expression, "expected a constant integer expression");
    return mlir::failure();
}

mlir::FailureOr<QASM3Visitor::RegisterSelection>
QASM3Visitor::resolveRegisterSelection(
    qasm3Parser::IndexedIdentifierContext* operand,
    unsigned registerSize,
    llvm::StringRef indexKind)
{
    const auto indices = operand->indexOperator();
    if (indices.empty())
        return RegisterSelection{
            RegisterSelection::Kind::WholeRegister,
            {0, registerSize, 1}
        };

    if (indices.size() != 1 || indices[0]->setExpression()
        || indices[0]->expression().size()
                   + indices[0]->rangeExpression().size()
               != 1) {
        error(
            operand,
            "expected a single constant " + indexKind + " index or range");
        return mlir::failure();
    }
    auto normalizeIndex = [registerSize](int64_t index) {
        return index < 0 ? index + static_cast<int64_t>(registerSize) : index;
    };
    if (indices[0]->rangeExpression().empty()) {
        auto index = evaluateConstantInteger(indices[0]->expression(0));
        if (mlir::failed(index)) return mlir::failure();
        const int64_t normalized = normalizeIndex(*index);
        if (normalized < 0 || normalized >= registerSize) {
            error(
                operand,
                "expected a constant " + indexKind
                    + " index within the register");
            return mlir::failure();
        }
        return RegisterSelection{
            RegisterSelection::Kind::Index,
            {static_cast<unsigned>(normalized), 1, 1}
        };
    }

    auto* range = indices[0]->rangeExpression(0);
    const bool hasStep = range->COLON().size() == 2;
    int64_t step = 1;
    if (hasStep) {
        if (!range->stepOrStop) {
            error(range, "expected a constant range step");
            return mlir::failure();
        }
        auto value = evaluateConstantInteger(range->stepOrStop);
        if (mlir::failed(value)) return mlir::failure();
        step = *value;
        if (!step) {
            error(range, "range step must not be zero");
            return mlir::failure();
        }
    }
    int64_t start = step > 0 ? 0 : registerSize - 1;
    int64_t stop = step > 0 ? registerSize - 1 : 0;
    if (range->start) {
        auto value = evaluateConstantInteger(range->start);
        if (mlir::failed(value)) return mlir::failure();
        start = normalizeIndex(*value);
    }
    auto* stopExpression = hasStep ? range->stop : range->stepOrStop;
    if (stopExpression) {
        auto value = evaluateConstantInteger(stopExpression);
        if (mlir::failed(value)) return mlir::failure();
        stop = normalizeIndex(*value);
    }
    if (start < 0 || stop < 0 || start >= registerSize
        || stop >= registerSize) {
        error(range, "range endpoints must be within the register");
        return mlir::failure();
    }
    if ((step > 0 && start > stop) || (step < 0 && start < stop)) {
        error(range, "register selection must not be empty");
        return mlir::failure();
    }
    const uint64_t distance = start > stop ? start - stop : stop - start;
    const uint64_t magnitude = step > 0
                                   ? static_cast<uint64_t>(step)
                                   : static_cast<uint64_t>(-(step + 1)) + 1;
    const unsigned count = static_cast<unsigned>(distance / magnitude + 1);
    return RegisterSelection{
        RegisterSelection::Kind::Range,
        {static_cast<unsigned>(start), count, step}
    };
}

mlir::FailureOr<QASM3Visitor::ResolvedQuantumOperand>
QASM3Visitor::resolveQuantumOperand(
    qasm3Parser::GateOperandContext &operand,
    llvm::StringRef indexKind)
{
    auto* indexed = operand.indexedIdentifier();
    if (!indexed) {
        error(&operand, "hardware qubit operands are not supported");
        return mlir::failure();
    }
    const auto name = indexed->Identifier()->getText();
    auto* reg = scope.lookupQReg(name);
    if (!reg) {
        error(&operand, "unknown quantum register '" + name + "'");
        return mlir::failure();
    }
    auto selection = resolveRegisterSelection(indexed, reg->size, indexKind);
    if (mlir::failed(selection)) return mlir::failure();
    const bool isScalar =
        selection->kind == RegisterSelection::Kind::Index
        || (selection->kind == RegisterSelection::Kind::WholeRegister
            && reg->isScalar);
    return ResolvedQuantumOperand{reg, selection->slice, isScalar};
}

// ################################################################################
// # Generate Quantum MLIR gates
// ################################################################################

std::any
QASM3Visitor::visitGateStatement(qasm3Parser::GateStatementContext* ctx)
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

std::any
QASM3Visitor::visitGateCallStatement(qasm3Parser::GateCallStatementContext* ctx)
{
    if (!ctx->Identifier() || !ctx->gateModifier().empty()
        || ctx->designator()) {
        error(ctx, "gate modifiers, durations and gphase are not supported");
        return {};
    }

    /// Gate name for emission
    const auto name = ctx->Identifier()->getText();

    llvm::SmallVector<mlir::Value> parameterValues;
    if (auto* classicOperands = ctx->expressionList()) {
        const auto expressions = classicOperands->expression();
        parameterValues.reserve(expressions.size());
        for (auto* expression : expressions) {
            auto resolved = expression->accept(this);
            if (hadError) return {};

            mlir::Value value;
            if (auto* operand = std::any_cast<mlir::Value>(&resolved)) {
                value = *operand;
            } else if (auto* integer = std::any_cast<int64_t>(&resolved)) {
                value = mlir::arith::ConstantOp::create(
                    builder,
                    getLocation(expression),
                    builder.getF64FloatAttr(static_cast<double>(*integer)));
            } else if (auto* real = std::any_cast<double>(&resolved)) {
                value = mlir::arith::ConstantOp::create(
                    builder,
                    getLocation(expression),
                    builder.getF64FloatAttr(*real));
            }

            if (!value || !value.getType().isF64()) {
                error(expression, "gate parameters must have type f64");
                return {};
            }
            parameterValues.push_back(value);
        }
    }

    llvm::SmallVector<ResolvedQuantumOperand> requests;
    for (auto* operand : ctx->gateOperandList()->gateOperand()) {
        auto resolved = resolveQuantumOperand(*operand, "qubit");
        if (mlir::failed(resolved)) return {};
        requests.push_back(*resolved);
    }

    const auto loc = getLocation(ctx);
    auto native = lookupNativeQuantumGate(name);
    auto* gate = native ? nullptr : gateLibrary.lookup(name);
    if (!native && !gate) {
        error(ctx, "gate '" + name + "' cannot be resolved");
        return {};
    }
    const auto qubitCount = native ? native->qubitCount : gate->qubits.size();
    const auto parameterCount =
        native ? native->parameterCount : gate->parameters.size();
    if (requests.size() != qubitCount
        || parameterValues.size() != parameterCount) {
        error(
            ctx,
            "expected " + llvm::Twine(qubitCount) + " qubit operands and "
                + llvm::Twine(parameterCount) + " parameters, got "
                + llvm::Twine(requests.size()) + " and "
                + llvm::Twine(parameterValues.size()));
        return {};
    }
    if (gate && mlir::failed(ensureGateDefinition(*gate, loc))) return {};

    // Unary native gates accept register values, so retain contiguous blocks
    // and assemble a stepped selection only for the duration of the operation.
    if (native && qubitCount == 1) {
        const auto &request = requests.front();
        auto selection = scope.materializeRegister(
            *request.reg,
            request.slice,
            builder,
            loc);
        auto results = emitNativeGate(
            *native,
            loc,
            builder,
            mlir::ValueRange{selection.value},
            parameterValues);
        if (mlir::failed(results)) {
            hadError = true;
            return {};
        }
        scope.updateRegister(
            *request.reg,
            selection,
            results->front(),
            builder,
            loc);
        return {};
    }

    std::optional<unsigned> broadcastSize;
    for (const auto &request : requests) {
        if (request.isScalar) continue;
        if (broadcastSize && *broadcastSize != request.slice.count) {
            error(ctx, "broadcast register operands must have equal lengths");
            return {};
        }
        broadcastSize = request.slice.count;
    }
    const unsigned iterations = broadcastSize.value_or(1);
    auto operandIndex = [&](const ResolvedQuantumOperand &request,
                            unsigned position) {
        return request.slice.getIndex(request.isScalar ? 0 : position);
    };
    // Reject duplicate operands before emitting or consuming any qubit values.
    for (unsigned position = 0; position < iterations; ++position) {
        for (unsigned i = 0; i < requests.size(); ++i) {
            for (unsigned j = 0; j < i; ++j) {
                if (requests[i].reg == requests[j].reg
                    && operandIndex(requests[i], position)
                           == operandIndex(requests[j], position)) {
                    error(ctx, "gate operands must refer to distinct qubits");
                    return {};
                }
            }
        }
    }
    // Complete every split before capturing values; later operands can refine
    // the same register. Read each iteration afresh after earlier gate results.
    for (const auto &request : requests)
        for (unsigned i = 0; i < request.slice.count; ++i)
            scope.materializeQubit(
                *request.reg,
                request.slice.getIndex(i),
                builder,
                loc);

    for (unsigned position = 0; position < iterations; ++position) {
        llvm::SmallVector<mlir::Value> qubits;
        for (const auto &request : requests)
            qubits.push_back(
                request.reg->getQubitValue(operandIndex(request, position)));
        llvm::SmallVector<mlir::Value> results;
        if (native) {
            auto emitted =
                emitNativeGate(*native, loc, builder, qubits, parameterValues);
            if (mlir::failed(emitted)) {
                hadError = true;
                return {};
            }
            results = std::move(*emitted);
        } else {
            results =
                emitGateCall(*gate, loc, builder, qubits, parameterValues);
        }
        for (auto [request, result] : llvm::zip_equal(requests, results))
            request.reg->updateQubit(operandIndex(request, position), result);
    }

    return {};
}

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
        if (auto* parameter = scope.lookupCReg(id)) return parameter->value;
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

std::any
QASM3Visitor::visitMeasureExpression(qasm3Parser::MeasureExpressionContext* ctx)
{
    error(ctx, "Measurement Expression not implemented");
    return {};
}

// ################################################################################
// # Declarations
// ################################################################################

mlir::FailureOr<unsigned>
QASM3Visitor::resolveRegisterSize(qasm3Parser::DesignatorContext* designator)
{
    if (!designator) return 1u;

    auto* expression = designator->expression();
    if (!expression) {
        error(designator, "expected expression inside designator");
        return mlir::failure();
    }

    while (auto* parentheses =
               dynamic_cast<qasm3Parser::ParenthesisExpressionContext*>(
                   expression))
        expression = parentheses->expression();

    // The default visitor returns child values for unsupported expressions,
    // which would otherwise interpret expressions such as -1 as positive sizes.
    if (!dynamic_cast<qasm3Parser::LiteralExpressionContext*>(expression)) {
        error(designator, "expected a constant integer register length");
        return mlir::failure();
    }

    auto resolved = expression->accept(this);
    if (hadError) return mlir::failure();

    auto* size = std::any_cast<int64_t>(&resolved);
    if (!size) {
        error(designator, "expected a constant integer register length");
        return mlir::failure();
    }
    if (*size <= 0 || *size > std::numeric_limits<unsigned>::max()) {
        error(
            designator,
            "register length must be a positive unsigned integer");
        return mlir::failure();
    }

    return static_cast<unsigned>(*size);
}

std::any QASM3Visitor::visitQuantumDeclarationStatement(
    qasm3Parser::QuantumDeclarationStatementContext* ctx)
{
    const auto id = ctx->Identifier()->getText();
    if (scope.contains(id)) {
        error(ctx, "redefinition of '" + id + "'");
        return {};
    }

    auto size = resolveRegisterSize(ctx->qubitType()->designator());
    if (mlir::failed(size)) return {};

    auto type = mlir::quantum::QubitType::get(&context, *size);
    auto alloc = mlir::quantum::AllocOp::create(
        builder,
        getLocation(ctx),
        type,
        mlir::IntegerAttr{});

    if (!scope.declareQReg(
            id,
            *size,
            alloc.getResult(),
            !ctx->qubitType()->designator()))
        error(ctx, "redefinition of '" + id + "'");

    return {};
}

std::any QASM3Visitor::visitClassicalDeclarationStatement(
    qasm3Parser::ClassicalDeclarationStatementContext* ctx)
{
    const auto id = ctx->Identifier()->getText();
    if (scope.contains(id)) {
        error(ctx, "redefinition of '" + id + "'");
        return {};
    }

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

        auto size = resolveRegisterSize(ty->designator());
        if (mlir::failed(size)) return {};

        auto rankedTy = mlir::RankedTensorType::get({*size}, *mlirTy);
        auto op = mlir::arith::ConstantOp::create(
            builder,
            getLocation(ctx),
            rankedTy,
            mlir::DenseElementsAttr::get(rankedTy, builder.getBoolAttr(false)));

        if (!scope.declareCReg(id, *size, op.getResult()))
            error(ctx, "redefinition of '" + id + "'");
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

mlir::LogicalResult QASM3Visitor::emitMeasurement(
    qasm3Parser::MeasureExpressionContext &measurement,
    qasm3Parser::IndexedIdentifierContext* destination)
{
    auto source =
        resolveQuantumOperand(*measurement.gateOperand(), "measurement");
    if (mlir::failed(source)) return mlir::failure();
    auto* qreg = source->reg;
    QASMScope::ClassicalRegister* creg = nullptr;
    if (destination) {
        const auto classicalName = destination->Identifier()->getText();
        creg = scope.lookupCReg(classicalName);
        if (!creg) {
            error(
                &measurement,
                "unknown classical register '" + classicalName + "'");
            return mlir::failure();
        }
        auto type =
            mlir::dyn_cast<mlir::RankedTensorType>(creg->value.getType());
        if (!type || type.getRank() != 1 || !type.getElementType().isInteger(1)
            || type.getDimSize(0) != creg->size) {
            error(
                destination,
                "measurement destination must be a bit register");
            return mlir::failure();
        }
    }

    const auto &quantumSlice = source->slice;
    std::optional<RegisterSlice> classicalSlice;
    if (destination) {
        auto selection =
            resolveRegisterSelection(destination, creg->size, "measurement");
        if (mlir::failed(selection)) return mlir::failure();
        classicalSlice = selection->slice;
    }
    if (classicalSlice && quantumSlice.count != classicalSlice->count) {
        error(
            &measurement,
            "measurement source and destination sizes must match");
        return mlir::failure();
    }
    const auto loc = getLocation(&measurement);
    auto selected =
        scope.materializeRegister(*qreg, quantumSlice, builder, loc);
    auto measured = mlir::quantum::MeasureOp::create(
        builder,
        loc,
        mlir::quantum::MeasurementType::get(&context, quantumSlice.count),
        selected.value.getType(),
        selected.value);
    scope.updateRegister(*qreg, selected, measured.getResult(), builder, loc);
    if (classicalSlice) {
        auto bits = mlir::qpu::ToBitsOp::create(
            builder,
            loc,
            mlir::RankedTensorType::get(
                {quantumSlice.count},
                builder.getI1Type()),
            measured.getMeasurement());
        scope.updateRegister(
            *creg,
            *classicalSlice,
            bits.getResult(),
            builder,
            loc);
    }
    return mlir::success();
}

std::any QASM3Visitor::visitAssignmentStatement(
    qasm3Parser::AssignmentStatementContext* ctx)
{
    if (ctx->CompoundAssignmentOperator()) {
        error(ctx, "compound assignment operators are not supported");
        return {};
    }
    if (auto* measurement = ctx->measureExpression()) {
        if (llvm::failed(
                emitMeasurement(*measurement, ctx->indexedIdentifier()))) {
            return {};
        }
        return {};
    }
    if (ctx->quantumCallExpression()) {
        error(ctx, "quantum call assignments are not supported");
        return {};
    }
    error(ctx, "classical expression assignments are not supported");
    return {};
}

std::any QASM3Visitor::visitMeasureArrowAssignmentStatement(
    qasm3Parser::MeasureArrowAssignmentStatementContext* ctx)
{
    auto* measurement = ctx->measureExpression();
    if (!measurement) {
        error(ctx, "quantum call statements are not supported");
        return {};
    }
    if (llvm::failed(emitMeasurement(*measurement, ctx->indexedIdentifier())))
        return {};
    return {};
}

std::any
QASM3Visitor::visitResetStatement(qasm3Parser::ResetStatementContext* ctx)
{
    auto operand = resolveQuantumOperand(*ctx->gateOperand(), "qubit");
    if (mlir::failed(operand)) return {};
    auto* qreg = operand->reg;
    const auto slice = operand->slice.inAscendingOrder();
    const auto loc = getLocation(ctx);
    scope.refineSlice(*qreg, slice, builder, loc);
    for (const auto &interval : scope.collectPartitions(*qreg, slice)) {
        auto reset = mlir::quantum::ResetOp::create(
            builder,
            loc,
            interval.value.getType(),
            interval.value);
        qreg->updateInterval(interval.start, reset.getResult());
    }
    return {};
}

std::any
QASM3Visitor::visitBarrierStatement(qasm3Parser::BarrierStatementContext* ctx)
{
    const auto loc = getLocation(ctx);
    llvm::SmallVector<ResolvedQuantumOperand> requests;
    if (auto* list = ctx->gateOperandList()) {
        for (auto* operand : list->gateOperand()) {
            auto resolved = resolveQuantumOperand(*operand, "qubit");
            if (mlir::failed(resolved)) return {};
            resolved->slice = resolved->slice.inAscendingOrder();
            requests.push_back(*resolved);
        }
    } else {
        for (const auto &entry : scope.getQRegs())
            requests.push_back({
                scope.lookupQReg(entry.getKey()),
                {0, entry.getValue().size, 1},
                entry.getValue().isScalar
            });
    }
    for (const auto &request : requests)
        scope.refineSlice(*request.reg, request.slice, builder, loc);

    // Collect only after every selection has refined the interval partition.
    llvm::SmallVector<QuantumOperand> operands;
    llvm::SmallVector<mlir::Value> values;
    llvm::SmallVector<mlir::Type> types;
    for (const auto &request : requests) {
        for (const auto &interval :
             scope.collectPartitions(*request.reg, request.slice)) {
            if (llvm::any_of(operands, [&](const QuantumOperand &existing) {
                    return existing.reg == request.reg
                           && existing.index == interval.start;
                }))
                continue;
            operands.push_back({request.reg, interval.start, interval.value});
            values.push_back(interval.value);
            types.push_back(interval.value.getType());
        }
    }
    auto barrier =
        mlir::quantum::BarrierOp::create(builder, loc, types, values);
    for (auto [operand, result] : llvm::zip(operands, barrier->getResults()))
        operand.reg->updateInterval(*operand.index, result);
    return {};
}

} // namespace quantum::frontend::qasm3
