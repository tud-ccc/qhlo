//===---- QASM3Visitor.h -  OpenQASM 3 Visitor ----------------------------===//
//
// @author  Lars Schütze (lars.schuetze@tu-dresden.de)
//===----------------------------------------------------------------------===//

#ifndef QUANTUM_MLIR_FRONTEND_QASM_QASM3_QASM3VISITOR_H
#define QUANTUM_MLIR_FRONTEND_QASM_QASM3_QASM3VISITOR_H

#include "GateLibrary.h"
#include "QASMScope.h"
#include "qasm3Parser.h"
#include "qasm3ParserBaseVisitor.h"
#include "quantum-mlir/Dialect/QPU/IR/QPUOps.h"

#include <any>
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
        GateLibrary &gateLibrary);

    bool failed() const { return hadError; }

    std::any visitProgram(qasm3Parser::ProgramContext* ctx) override;

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

    // TODO: write hadError on failure
    bool hadError = false;
};
} // namespace quantum::frontend::qasm3

#endif // QUANTUM_MLIR_FRONTEND_QASM_QASM3_QASM3VISITOR_H
