//===---- QASMTranslationUnit.h -  OpenQASM Translation Unit -----------===//
//
// @author  Lars Schütze (lars.schuetze@tu-dresden.de)
//===----------------------------------------------------------------------===//

#ifndef QUANTUM_MLIR_FRONTEND_QASM_COMMON_QASMTRANSLATIONUNIT_H
#define QUANTUM_MLIR_FRONTEND_QASM_COMMON_QASMTRANSLATIONUNIT_H

#include <antlr4-runtime.h>
#include <llvm/ADT/SmallVector.h>
#include <llvm/ADT/StringRef.h>
#include <memory>
#include <mlir/IR/Diagnostics.h>
#include <mlir/IR/Location.h>
#include <mlir/IR/MLIRContext.h>
#include <string>
#include <utility>

namespace quantum::frontend {

class QASMErrorListener final : public antlr4::BaseErrorListener {
public:
    QASMErrorListener(mlir::MLIRContext &context, llvm::StringRef filename)
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

template<typename LexerT, typename ParserT>
class ParsedQASMSource {
public:
    ParsedQASMSource(
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

    // ANTLR objects retain pointers to other members of this source.
    ParsedQASMSource(const ParsedQASMSource &) = delete;
    ParsedQASMSource &operator=(const ParsedQASMSource &) = delete;
    ParsedQASMSource(ParsedQASMSource &&) = delete;
    ParsedQASMSource &operator=(ParsedQASMSource &&) = delete;

    llvm::StringRef getFilename() const { return filename; }

    bool failed() const { return errorListener.failed(); }

protected:
    ParserT &getParser() { return parser; }

private:
    QASMErrorListener errorListener;
    // Declaration order matters because later objects reference earlier
    // ones.
    std::string source;
    std::string filename;

    antlr4::ANTLRInputStream input;
    LexerT lexer;
    antlr4::CommonTokenStream tokens;
    ParserT parser;
};

// Own sources until lowering finishes: gate bodies may retain parse-tree
// pointers.
template<typename ParsedSourceT>
class QASMTranslationUnit {
public:
    template<typename... Args>
    ParsedSourceT &addSource(Args &&... args)
    {
        auto source =
            std::make_unique<ParsedSourceT>(std::forward<Args>(args)...);

        auto &result = *source;
        sources.push_back(std::move(source));
        return result;
    }

private:
    llvm::SmallVector<std::unique_ptr<ParsedSourceT>> sources;
};

} // namespace quantum::frontend

#endif // QUANTUM_MLIR_FRONTEND_QASM_COMMON_QASMTRANSLATIONUNIT_H
