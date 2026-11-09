//===---- QASM2TranslationUnit.h - OpenQASM 2 Translation Unit --------===//
//
// @author  Lars Schütze (lars.schuetze@tu-dresden.de)
//===----------------------------------------------------------------------===//

#ifndef QUANTUM_MLIR_FRONTEND_QASM_QASM2_QASM2TRANSLATIONUNIT_H
#define QUANTUM_MLIR_FRONTEND_QASM_QASM2_QASM2TRANSLATIONUNIT_H

#include "QASMTranslationUnit.h"
#include "qasm2Lexer.h"
#include "qasm2Parser.h"

namespace quantum::frontend::qasm2 {

class ParsedQASM2Source final
        : public ParsedQASMSource<qasm2Lexer, qasm2Parser> {
public:
    using ParsedQASMSource::ParsedQASMSource;

    qasm2Parser::IncludeFileContext* parseInclude()
    { return getParser().includeFile(); }

    qasm2Parser::ProgramContext* parseProgram()
    { return getParser().program(); }
};

using QASM2TranslationUnit = QASMTranslationUnit<ParsedQASM2Source>;

} // namespace quantum::frontend::qasm2

#endif // QUANTUM_MLIR_FRONTEND_QASM_QASM2_QASM2TRANSLATIONUNIT_H
