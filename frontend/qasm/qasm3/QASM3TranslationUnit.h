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

using QASM3TranslationUnit = QASMTranslationUnit<ParsedQASM3Source>;

} // namespace quantum::frontend::qasm3

#endif // QUANTUM_MLIR_FRONTEND_QASM_QASM3_QASM3TRANSLATIONUNIT_H
