//===---- QASM3TranslationUnit.h - OpenQASM 3 Translation Unit --------===//
//
// @author  Lars Schütze (lars.schuetze@tu-dresden.de)
//===----------------------------------------------------------------------===//

#ifndef QUANTUM_MLIR_FRONTEND_QASM_QASM3_QASM3TRANSLATIONUNIT_H
#define QUANTUM_MLIR_FRONTEND_QASM_QASM3_QASM3TRANSLATIONUNIT_H

#include "QASMTranslationUnit.h"
#include "qasm3Lexer.h"
#include "qasm3Parser.h"

namespace quantum::frontend::qasm3 {

class ParsedQASM3Source final
        : public ParsedQASMSource<qasm3Lexer, qasm3Parser> {
public:
    using ParsedQASMSource::ParsedQASMSource;

    qasm3Parser::ProgramContext* parseInclude()
    { return getParser().program(); }

    qasm3Parser::ProgramContext* parseProgram()
    { return getParser().program(); }
};

class QASM3TranslationUnit final
        : public QASMTranslationUnit<ParsedQASM3Source> {
public:
    // Track the active expansion chain rather than all previously read files.
    // Repeated non-recursive includes must still contribute declarations.
    bool isSourceActive(llvm::StringRef filename) const;
    void enterSource(llvm::StringRef filename);
    void leaveSource();

private:
    llvm::SmallVector<std::string> activeSources;
};

} // namespace quantum::frontend::qasm3

#endif // QUANTUM_MLIR_FRONTEND_QASM_QASM3_QASM3TRANSLATIONUNIT_H
