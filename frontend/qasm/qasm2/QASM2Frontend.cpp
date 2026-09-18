//===---- QASM2Frontend.h -  OpenQASM 2.0 Quantum Frontend ----------------===//
//
// @author  Lars Schütze (lars.schuetze@tu-dresden.de)
//===----------------------------------------------------------------------===//

#include "QASM2Frontend.h"

#include "QASM2Visitor.h"
#include "qasm2Lexer.h"
#include "qasm2Parser.h"

#include <antlr4-runtime.h>
#include <mlir/IR/Builders.h>
#include <mlir/IR/Diagnostics.h>
#include <mlir/IR/Location.h>

namespace quantum::frontend {
namespace {

class QASM2ErrorListener final : public antlr4::BaseErrorListener {
public:
    QASM2ErrorListener(mlir::MLIRContext &context, llvm::StringRef filename)
            : context(context),
              filename(filename.str())
    {}

    void syntaxError(
        antlr4::Recognizer*,
        antlr4::Token*,
        size_t line,
        size_t charPositionInLine,
        const std::string &message,
        std::exception_ptr) override
    {
        hadError = true;

        auto loc = mlir::FileLineColLoc::get(
            &context,
            filename,
            line,
            charPositionInLine + 1);

        mlir::emitError(loc) << message;
    }

    bool failed() const { return hadError; }

private:
    mlir::MLIRContext &context;
    std::string filename;
    bool hadError = false;
};

} // namespace

mlir::OwningOpRef<mlir::ModuleOp> parseQASM2(
    llvm::StringRef source,
    llvm::StringRef filename,
    mlir::MLIRContext &context)
{
    antlr4::ANTLRInputStream input(source.str());

    qasm2::qasm2Lexer lexer(&input);

    QASM2ErrorListener errorListener(context, filename);

    lexer.removeErrorListeners();
    lexer.addErrorListener(&errorListener);

    antlr4::CommonTokenStream tokens(&lexer);

    qasm2::qasm2Parser parser(&tokens);

    parser.removeErrorListeners();
    parser.addErrorListener(&errorListener);

    auto* program = parser.program();

    if (errorListener.failed()) return {};

    auto moduleLoc = mlir::FileLineColLoc::get(&context, filename, 1, 1);

    mlir::OwningOpRef<mlir::ModuleOp> module =
        mlir::ModuleOp::create(moduleLoc);

    QASM2Visitor visitor(context, *module, filename);
    visitor.visit(program);

    if (visitor.failed()) return {};

    return module;
}

} // namespace quantum::frontend
