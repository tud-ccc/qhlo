//===---- QASM2Visitor.h -  OpenQASM 2.0 Quantum Visitor ------------------===//
//
// @author  Lars Schütze (lars.schuetze@tu-dresden.de)
//===----------------------------------------------------------------------===//

#ifndef QUANTUM_MLIR_FRONTEND_QASM_QASM2_QASM2VISITOR_H
#define QUANTUM_MLIR_FRONTEND_QASM_QASM2_QASM2VISITOR_H

#include "GateLibrary.h"
#include "QASM2TranslationUnit.h"
#include "QASMIncludeResolver.h"
#include "QASMScope.h"
#include "qasm2ParserBaseVisitor.h"
#include "quantum-mlir/Dialect/QPU/IR/QPUOps.h"

#include <any>
#include <llvm/ADT/StringRef.h>
#include <mlir/IR/Builders.h>
#include <mlir/IR/BuiltinOps.h>
#include <mlir/IR/Value.h>
#include <optional>
#include <string>

using namespace qasm2;

namespace quantum::frontend {

struct QuantumOperand {
    QASMScope::QuantumRegister* reg;
    std::optional<unsigned> index;
    mlir::Value value;
};

class QASM2Visitor final : public qasm2ParserBaseVisitor {
public:
    QASM2Visitor(
        mlir::MLIRContext &context,
        mlir::ModuleOp module,
        mlir::qpu::QPUModuleOp qpuModule,
        mlir::qpu::CircuitOp mainCircuit,
        llvm::StringRef filename,
        QASMScope &scope,
        GateLibrary &gateLibrary,
        QASMIncludeResolver &includeResolver,
        qasm2::QASM2TranslationUnit &translationUnit);

    bool failed() const { return hadError; }

    std::any visitProgram(qasm2Parser::ProgramContext* ctx) override;

    std::any
    visitIncludeStatement(qasm2Parser::IncludeStatementContext* ctx) override;

    std::any visitVersion(qasm2Parser::VersionContext* ctx) override;

    std::any visitOldStyleDeclarationStatement(
        qasm2Parser::OldStyleDeclarationStatementContext* ctx) override;

    std::any
    visitGateCallStatement(qasm2Parser::GateCallStatementContext* ctx) override;

    std::any visitMeasureArrowAssignmentStatement(
        qasm2Parser::MeasureArrowAssignmentStatementContext* ctx) override;

    std::any
    visitResetStatement(qasm2Parser::ResetStatementContext* ctx) override;

    std::any
    visitBarrierStatement(qasm2Parser::BarrierStatementContext* ctx) override;

    std::any
    visitGateStatement(qasm2Parser::GateStatementContext* ctx) override;

    std::any visitOpaqueDeclarationStatement(
        qasm2Parser::OpaqueDeclarationStatementContext* ctx) override;

    std::any visitIfStatement(qasm2Parser::IfStatementContext* ctx) override;

private:
    mlir::Location getLocation(antlr4::ParserRuleContext* ctx) const;

    std::optional<unsigned> parseUnsigned(
        antlr4::tree::TerminalNode* node,
        antlr4::ParserRuleContext* ctx);

    void error(antlr4::ParserRuleContext* ctx, const llvm::Twine &message);

    std::optional<QuantumOperand>
    resolveQuantumOperand(qasm2Parser::GateOperandContext* ctx);

    mlir::Value resolveExpression(qasm2Parser::ExpressionContext* ctx);
    mlir::Value resolveClassicExpression(qasm2Parser::ExpressionContext* ctx);

    mlir::MLIRContext &context;
    mlir::ModuleOp module;
    mlir::qpu::QPUModuleOp qpuModule;
    mlir::OpBuilder builder;
    mlir::qpu::CircuitOp mainCircuit;

    std::string filename;

    QASMScope &scope;
    GateLibrary &gateLibrary;
    QASMIncludeResolver &includeResolver;
    qasm2::QASM2TranslationUnit &translationUnit;

    bool hadError = false;
};

} // namespace quantum::frontend

#endif // QUANTUM_MLIR_FRONTEND_QASM_QASM2_QASM2VISITOR_H
