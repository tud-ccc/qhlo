//===---- QASM2TranslationUnit.h -  OpenQASM Translation Unit -----------===//
//
// @author  Lars Schütze (lars.schuetze@tu-dresden.de)
//===----------------------------------------------------------------------===//

#ifndef QUANTUM_MLIR_FRONTEND_QASM_QASM2_QASM2TRANSLATIONUNIT_H
#define QUANTUM_MLIR_FRONTEND_QASM_QASM2_QASM2TRANSLATIONUNIT_H

#include "qasm2Lexer.h"
#include "qasm2Parser.h"

#include <ANTLRInputStream.h>
#include <llvm/ADT/SmallVector.h>
#include <llvm/ADT/StringRef.h>
#include <mlir/IR/BuiltinOps.h>
#include <mlir/IR/MLIRContext.h>

using namespace qasm2;

namespace quantum::frontend::qasm2 {

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

class ParsedQASM2Source {
public:
    ParsedQASM2Source(
        mlir::MLIRContext &context,
        llvm::StringRef source,
        llvm::StringRef filename)
            : errorListener(context, filename),
              source(source.str()),
              filename(filename.str()),
              input(this->source),
              lexer(&input),
              tokens(&lexer),
              parser(&tokens)
    {
        lexer.removeErrorListeners();
        lexer.addErrorListener(&errorListener);

        parser.removeErrorListeners();
        parser.addErrorListener(&errorListener);

        tokens.fill();
    }

    qasm2Parser::IncludeFileContext* parseInclude()
    { return parser.includeFile(); }

    qasm2Parser::ProgramContext* parseProgram() { return parser.program(); }

    llvm::StringRef getFilename() const { return filename; }

    bool failed() const { return errorListener.failed(); }

private:
    QASM2ErrorListener errorListener;
    // Declaration order matters because later objects reference earlier
    // ones.
    std::string source;
    std::string filename;

    antlr4::ANTLRInputStream input;
    qasm2Lexer lexer;
    antlr4::CommonTokenStream tokens;
    qasm2Parser parser;
};

class QASM2TranslationUnit {
public:
    template<typename... Args>
    ParsedQASM2Source &addSource(Args &&... args)
    {
        auto source =
            std::make_unique<ParsedQASM2Source>(std::forward<Args>(args)...);

        auto &result = *source;
        sources.push_back(std::move(source));
        return result;
    }

private:
    llvm::SmallVector<std::unique_ptr<ParsedQASM2Source>> sources;
};

} // namespace quantum::frontend::qasm2

#endif // QUANTUM_MLIR_FRONTEND_QASM_QASM2_QASM2TRANSLATIONUNIT_H
