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
    for (auto [index, name] : llvm::enumerate(gate.parameters))
        gateScope.declareCReg(
            name,
            1,
            gateBlock.getArgument(gate.qubits.size() + index));
    for (auto [index, name] : llvm::enumerate(gate.qubits))
        gateScope.declareQReg(name, 1, gateBlock.getArgument(index));

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
            gateScope.lookupQReg(name)->intervals.lookup(0).value);
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

    llvm::SmallVector<QuantumOperand> qubitValues;
    // In QASM3 a gate has at least one qubit operand
    auto qubitOperands = ctx->gateOperandList();
    const auto operands = qubitOperands->gateOperand();
    qubitValues.reserve(operands.size());
    for (auto* operand : operands) {
        auto* indexed = operand->indexedIdentifier();
        if (!indexed) {
            error(operand, "hardware qubit operands are not supported");
            return {};
        }

        const auto id = indexed->Identifier()->getText();
        auto* reg = scope.lookupQReg(id);
        if (!reg) {
            error(operand, "unknown quantum register '" + id + "'");
            return {};
        }

        const auto indices = indexed->indexOperator();
        if (indices.empty()) {
            auto &interval = reg->intervals.lookup(0);
            if (interval.size() != reg->size) {
                error(
                    operand,
                    "whole-register operands after qubit splitting are "
                    "unsupported");
                return {};
            }
            qubitValues.push_back({reg, std::nullopt, interval.value});
            continue;
        }

        if (indices.size() != 1 || indices[0]->setExpression()
            || !indices[0]->rangeExpression().empty()
            || indices[0]->expression().size() != 1) {
            error(operand, "expected a single constant qubit index");
            return {};
        }

        auto resolved = indices[0]->expression(0)->accept(this);
        if (hadError) return {};
        auto* index = std::any_cast<int64_t>(&resolved);
        if (!index || *index < 0 || *index >= reg->size) {
            error(
                operand,
                "expected a constant qubit index within the register");
            return {};
        }

        const auto qubitIndex = static_cast<unsigned>(*index);
        qubitValues.push_back(
            {reg,
             qubitIndex,
             scope.materializeQubit(
                 *reg,
                 qubitIndex,
                 builder,
                 getLocation(operand))});
    }

    llvm::SmallVector<mlir::Value> qubits;
    qubits.reserve(qubitValues.size());
    for (const auto &operand : qubitValues) qubits.push_back(operand.value);

    llvm::SmallVector<mlir::Value> results;
    if (auto spec = lookupNativeQuantumGate(name)) {
        auto emitted = emitNativeGate(
            *spec,
            getLocation(ctx),
            builder,
            qubits,
            parameterValues);
        if (mlir::failed(emitted)) {
            hadError = true;
            return {};
        }
        results = std::move(*emitted);
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

    for (auto [operand, result] : llvm::zip_equal(qubitValues, results))
        if (operand.index)
            operand.reg->intervals.lookup(*operand.index).value = result;
        else
            operand.reg->intervals.set(0, operand.reg->size, result);

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
    auto size = resolveRegisterSize(ctx->qubitType()->designator());
    if (mlir::failed(size)) return {};

    auto type = mlir::quantum::QubitType::get(&context, *size);
    auto alloc = mlir::quantum::AllocOp::create(
        builder,
        getLocation(ctx),
        type,
        mlir::IntegerAttr{});

    // Add the qubit to the scope
    auto id = ctx->Identifier()->getText();
    scope.declareQReg(id, *size, alloc.getResult());

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

        auto size = resolveRegisterSize(ty->designator());
        if (mlir::failed(size)) return {};

        auto rankedTy = mlir::RankedTensorType::get({*size}, *mlirTy);
        auto op = mlir::arith::ConstantOp::create(
            builder,
            getLocation(ctx),
            rankedTy,
            mlir::DenseElementsAttr::get(rankedTy, builder.getBoolAttr(false)));

        scope.declareCReg(id, *size, op.getResult());
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
    auto* source = measurement.gateOperand()->indexedIdentifier();
    if (!source) {
        error(&measurement, "hardware qubit operands are not supported");
        return mlir::failure();
    }
    const std::string quantumName = source->Identifier()->getText();
    auto* qreg = scope.lookupQReg(quantumName);
    if (!qreg) {
        error(&measurement, "unknown quantum register '" + quantumName + "'");
        return mlir::failure();
    }
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

    auto resolveIndex = [&](qasm3Parser::IndexedIdentifierContext* operand,
                            unsigned size,
                            unsigned &offset,
                            unsigned &count) {
        const auto indices = operand->indexOperator();
        if (indices.empty()) return true;
        if (indices.size() != 1 || indices[0]->setExpression()
            || !indices[0]->rangeExpression().empty()
            || indices[0]->expression().size() != 1) {
            error(operand, "expected a single constant measurement index");
            return false;
        }
        auto resolved = indices[0]->expression(0)->accept(this);
        if (hadError) return false;
        auto* index = std::any_cast<int64_t>(&resolved);
        if (!index || *index < 0 || *index >= size) {
            error(
                operand,
                "expected a constant measurement index within the register");
            return false;
        }
        offset = static_cast<unsigned>(*index);
        count = 1;
        return true;
    };

    unsigned quantumOffset = 0, classicalOffset = 0;
    unsigned quantumSize = qreg->size;
    unsigned classicalSize = creg ? creg->size : 0;
    if (!resolveIndex(source, qreg->size, quantumOffset, quantumSize))
        return mlir::failure();
    if (destination
        && !resolveIndex(
            destination,
            creg->size,
            classicalOffset,
            classicalSize))
        return mlir::failure();
    if (creg && quantumSize != classicalSize) {
        error(
            &measurement,
            "measurement source and destination sizes must match");
        return mlir::failure();
    }

    const auto loc = getLocation(&measurement);
    auto bitType = builder.getI1Type();

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
        if (!creg) continue;
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

    // Earlier indexed accesses may have split the register into intervals with
    // separate SSA values, so resetting the whole register must cover each one.
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

std::any
QASM3Visitor::visitBarrierStatement(qasm3Parser::BarrierStatementContext* ctx)
{
    const auto loc = getLocation(ctx);
    llvm::SmallVector<QuantumOperand> requests;
    if (auto* list = ctx->gateOperandList()) {
        for (auto* operand : list->gateOperand()) {
            auto* indexed = operand->indexedIdentifier();
            if (!indexed) {
                error(operand, "hardware qubit operands are not supported");
                return {};
            }
            const auto name = indexed->Identifier()->getText();
            auto* reg = scope.lookupQReg(name);
            if (!reg) {
                error(operand, "unknown quantum register '" + name + "'");
                return {};
            }

            std::optional<unsigned> index;
            const auto indices = indexed->indexOperator();
            if (!indices.empty()) {
                if (indices.size() != 1 || indices[0]->setExpression()
                    || !indices[0]->rangeExpression().empty()
                    || indices[0]->expression().size() != 1) {
                    error(operand, "expected a single constant qubit index");
                    return {};
                }
                auto resolved = indices[0]->expression(0)->accept(this);
                if (hadError) return {};
                auto* value = std::any_cast<int64_t>(&resolved);
                if (!value || *value < 0 || *value >= reg->size) {
                    error(
                        operand,
                        "expected a constant qubit index within the register");
                    return {};
                }
                index = static_cast<unsigned>(*value);
                scope.materializeQubit(*reg, *index, builder, loc);
            }
            requests.push_back({reg, index, {}});
        }
    } else {
        for (const auto &entry : scope.getQRegs())
            requests.push_back(
                {scope.lookupQReg(entry.getKey()), std::nullopt, {}});
    }

    // Resolve intervals after all indexed operands have split their registers.
    llvm::SmallVector<QuantumOperand> operands;
    llvm::SmallVector<mlir::Value> values;
    llvm::SmallVector<mlir::Type> types;
    for (const auto &request : requests) {
        for (const auto &interval : request.reg->intervals.intervals()) {
            if (request.index && interval.start != *request.index) continue;
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
        operand.reg->intervals.lookup(*operand.index).value = result;
    return {};
}

} // namespace quantum::frontend::qasm3
