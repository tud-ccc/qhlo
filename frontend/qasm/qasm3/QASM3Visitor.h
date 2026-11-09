//===---- QASM3Visitor.h -  OpenQASM 3 Visitor ----------------------------===//
//
// @author  Lars Schütze (lars.schuetze@tu-dresden.de)
//===----------------------------------------------------------------------===//

#ifndef QUANTUM_MLIR_FRONTEND_QASM_QASM3_QASM3VISITOR_H
#define QUANTUM_MLIR_FRONTEND_QASM_QASM3_QASM3VISITOR_H

#include "GateLibrary.h"
#include "QASM3TranslationUnit.h"
#include "QASMIncludeResolver.h"
#include "QASMScope.h"
#include "qasm3Parser.h"
#include "qasm3ParserBaseVisitor.h"
#include "quantum-mlir/Dialect/QPU/IR/QPUOps.h"

#include <any>
#include <cstddef>
#include <cstdint>
#include <llvm/ADT/SmallVector.h>
#include <llvm/ADT/StringRef.h>
#include <mlir/IR/Builders.h>
#include <mlir/IR/BuiltinOps.h>
#include <mlir/IR/Value.h>
#include <optional>
#include <string>

namespace quantum::frontend::qasm3 {
struct QuantumOperand {
    QASMScope::QuantumRegister* reg;
    std::optional<unsigned> index;
    mlir::Value value;
};

class QASM3Visitor final : public qasm3ParserBaseVisitor {
public:
    QASM3Visitor(
        mlir::MLIRContext &context,
        mlir::ModuleOp module,
        mlir::qpu::QPUModuleOp qpuModule,
        mlir::qpu::CircuitOp mainCircuit,
        llvm::StringRef filename,
        QASMScope &scope,
        GateLibrary &gateLibrary,
        QASMIncludeResolver &includeResolver,
        QASM3TranslationUnit &translationUnit);

    bool failed() const { return hadError; }

    std::any visitProgram(qasm3Parser::ProgramContext* ctx) override;

    std::any visitScope(qasm3Parser::ScopeContext* ctx) override;

    std::any visitIfStatement(qasm3Parser::IfStatementContext* ctx) override;

    std::any
    visitWhileStatement(qasm3Parser::WhileStatementContext* ctx) override;

    std::any visitStatement(qasm3Parser::StatementContext* ctx) override;

    std::any
    visitIncludeStatement(qasm3Parser::IncludeStatementContext* ctx) override;

    std::any visitVersion(qasm3Parser::VersionContext* ctx) override;

    std::any visitQuantumDeclarationStatement(
        qasm3Parser::QuantumDeclarationStatementContext* ctx) override;

    std::any visitClassicalDeclarationStatement(
        qasm3Parser::ClassicalDeclarationStatementContext* ctx) override;

    std::any visitParenthesisExpression(
        qasm3Parser::ParenthesisExpressionContext* ctx) override;

    std::any
    visitLiteralExpression(qasm3Parser::LiteralExpressionContext* ctx) override;

    std::any
    visitMeasureExpression(qasm3Parser::MeasureExpressionContext* ctx) override;

    std::any visitMeasureArrowAssignmentStatement(
        qasm3Parser::MeasureArrowAssignmentStatementContext* ctx) override;

    std::any visitAssignmentStatement(
        qasm3Parser::AssignmentStatementContext* ctx) override;

    std::any visitConstDeclarationStatement(
        qasm3Parser::ConstDeclarationStatementContext* ctx) override;

    std::any
    visitResetStatement(qasm3Parser::ResetStatementContext* ctx) override;

    std::any
    visitGateStatement(qasm3Parser::GateStatementContext* ctx) override;

    std::any
    visitGateCallStatement(qasm3Parser::GateCallStatementContext* ctx) override;

    std::any
    visitBarrierStatement(qasm3Parser::BarrierStatementContext* ctx) override;

private:
    struct ControlFlowState {
        llvm::SmallVector<QASMScope::QuantumRegister*> qubits;
        llvm::SmallVector<mlir::Value*> classical;
    };

    ControlFlowState captureControlFlowState();

    llvm::SmallVector<mlir::Value>
    readControlFlowState(const ControlFlowState &state, mlir::Location loc);

    void writeControlFlowState(
        const ControlFlowState &state,
        mlir::ValueRange values);

    struct RegisterSelection {
        enum class Kind { WholeRegister, Index, Range };
        Kind kind;
        RegisterSlice slice;
    };

    struct ResolvedQuantumOperand {
        QASMScope::QuantumRegister* reg;
        RegisterSlice slice;
        bool isScalar;
    };

    mlir::FailureOr<QASMScope::Declaration*>
    resolveIdentifier(llvm::StringRef name, antlr4::ParserRuleContext* ctx);

    mlir::FailureOr<mlir::TypedAttr>
    evaluateConstant(qasm3Parser::ExpressionContext* expression);

    mlir::FailureOr<mlir::TypedAttr> convertConstant(
        mlir::TypedAttr value,
        mlir::Type type,
        antlr4::ParserRuleContext* ctx);

    mlir::FailureOr<mlir::Type>
    resolveScalarType(qasm3Parser::ScalarTypeContext* type);

    mlir::FailureOr<mlir::Value> emitRValue(
        QASMScope::Declaration &declaration,
        antlr4::ParserRuleContext* ctx);

    mlir::FailureOr<mlir::Value> emitExpression(
        qasm3Parser::ExpressionContext* expression,
        mlir::Type expectedType = {});

    mlir::FailureOr<mlir::Value>
    emitCondition(qasm3Parser::ExpressionContext* expression);

    mlir::FailureOr<mlir::Value> emitComparison(
        qasm3Parser::ExpressionContext* expression,
        llvm::StringRef predicate,
        qasm3Parser::ExpressionContext* lhs,
        qasm3Parser::ExpressionContext* rhs);

    mlir::FailureOr<mlir::Value> convertValue(
        mlir::Value value,
        mlir::Type type,
        antlr4::ParserRuleContext* ctx);

    mlir::FailureOr<mlir::Value> emitBinaryExpression(
        qasm3Parser::ExpressionContext* expression,
        size_t op,
        qasm3Parser::ExpressionContext* lhs,
        qasm3Parser::ExpressionContext* rhs);

    mlir::LogicalResult assign(
        QASMScope::Declaration &declaration,
        mlir::Value value,
        antlr4::ParserRuleContext* ctx);

    mlir::FailureOr<mlir::TypedAttr> evaluateBinaryConstant(
        qasm3Parser::ExpressionContext* expression,
        size_t op,
        qasm3Parser::ExpressionContext* lhs,
        qasm3Parser::ExpressionContext* rhs);

    mlir::FailureOr<int64_t>
    evaluateConstantInteger(qasm3Parser::ExpressionContext* expression);

    mlir::FailureOr<RegisterSelection> resolveRegisterSelection(
        qasm3Parser::IndexedIdentifierContext* operand,
        unsigned registerSize,
        llvm::StringRef indexKind);

    // Resolves the selection without capturing values or refining partitions.
    mlir::FailureOr<ResolvedQuantumOperand> resolveQuantumOperand(
        qasm3Parser::GateOperandContext &operand,
        llvm::StringRef indexKind);

    mlir::FailureOr<unsigned>
    resolveRegisterSize(qasm3Parser::DesignatorContext* designator);

    // A null destination discards the measurement result.
    mlir::LogicalResult emitMeasurement(
        qasm3Parser::MeasureExpressionContext &measurement,
        qasm3Parser::IndexedIdentifierContext* destination);

    mlir::LogicalResult
    ensureGateDefinition(GateDefinition &gate, mlir::Location loc);

    mlir::Location getLocation(antlr4::ParserRuleContext* ctx) const;

    void error(antlr4::ParserRuleContext* ctx, const llvm::Twine &message);

    mlir::MLIRContext &context;
    mlir::ModuleOp module;
    mlir::qpu::QPUModuleOp qpuModule;
    mlir::OpBuilder builder;
    mlir::qpu::CircuitOp mainCircuit;

    std::string filename;

    QASMScope &scope;
    GateLibrary &gateLibrary;
    QASMIncludeResolver &includeResolver;
    QASM3TranslationUnit &translationUnit;

    // TODO: write hadError on failure
    bool hadError = false;
};
} // namespace quantum::frontend::qasm3

#endif // QUANTUM_MLIR_FRONTEND_QASM_QASM3_QASM3VISITOR_H
