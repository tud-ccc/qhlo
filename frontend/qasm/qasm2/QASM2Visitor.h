//===---- QASM2Visitor.h -  OpenQASM 2.0 Quantum Visitor ------------------===//
//
// @author  Lars Schütze (lars.schuetze@tu-dresden.de)
//===----------------------------------------------------------------------===//

#pragma once

#include "mlir/IR/Builders.h"
#include "mlir/IR/BuiltinOps.h"
#include "mlir/IR/Value.h"
#include "qasm2ParserBaseVisitor.h"

#include "llvm/ADT/StringMap.h"
#include "llvm/ADT/StringRef.h"

#include <any>
#include <optional>
#include <string>

namespace quantum::frontend {

class QASM2Visitor final : public qasm2::qasm2ParserBaseVisitor {
public:
    QASM2Visitor(
        mlir::MLIRContext &context,
        mlir::ModuleOp module,
        llvm::StringRef filename);

    bool failed() const { return hadError; }

    std::any visitProgram(qasm2::qasm2Parser::ProgramContext* ctx) override;

    std::any visitVersion(qasm2::qasm2Parser::VersionContext* ctx) override;

    std::any visitOldStyleDeclarationStatement(
        qasm2::qasm2Parser::OldStyleDeclarationStatementContext* ctx) override;

    std::any visitGateCallStatement(
        qasm2::qasm2Parser::GateCallStatementContext* ctx) override;

    std::any visitMeasureArrowAssignmentStatement(
        qasm2::qasm2Parser::MeasureArrowAssignmentStatementContext* ctx)
        override;

    std::any visitResetStatement(
        qasm2::qasm2Parser::ResetStatementContext* ctx) override;

    std::any visitBarrierStatement(
        qasm2::qasm2Parser::BarrierStatementContext* ctx) override;

    std::any
    visitGateStatement(qasm2::qasm2Parser::GateStatementContext* ctx) override;

    std::any visitOpaqueDeclarationStatement(
        qasm2::qasm2Parser::OpaqueDeclarationStatementContext* ctx) override;

    std::any
    visitIfStatement(qasm2::qasm2Parser::IfStatementContext* ctx) override;

private:
    struct QuantumRegister {
        mlir::Value value;
        unsigned size;
    };

    struct ClassicalRegister {
        mlir::Value value;
        unsigned size;
    };

    struct QuantumOperand {
        QuantumRegister* reg;
        std::optional<unsigned> index;
    };

    mlir::Location location(antlr4::ParserRuleContext* ctx) const;

    void error(antlr4::ParserRuleContext* ctx, const llvm::Twine &message);

    std::optional<QuantumOperand>
    resolveQuantumOperand(qasm2::qasm2Parser::GateOperandContext* ctx);

    mlir::MLIRContext &context;
    mlir::ModuleOp module;
    mlir::OpBuilder builder;
    std::string filename;

    llvm::StringMap<QuantumRegister> qregs;
    llvm::StringMap<ClassicalRegister> cregs;

    bool hadError = false;
};

} // namespace quantum::frontend
