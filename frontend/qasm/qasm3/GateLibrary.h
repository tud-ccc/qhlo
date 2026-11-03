//===---- GateLibrary.h -  Quantum Gate Definitions ---------------------===//
//
// @author  Lars Schütze (lars.schuetze@tu-dresden.de)
//===----------------------------------------------------------------------===//

#ifndef QUANTUM_MLIR_FRONTEND_QASM_QASM3_GATELIBRARY_H
#define QUANTUM_MLIR_FRONTEND_QASM_QASM3_GATELIBRARY_H

#include "../common/GateLibrary.h"
#include "qasm3Parser.h"

namespace quantum::frontend::qasm3 {

using GateDefinition =
    quantum::frontend::GateDefinition<qasm3Parser::ScopeContext>;
using GateLibrary = quantum::frontend::GateLibrary<qasm3Parser::ScopeContext>;

} // namespace quantum::frontend::qasm3

#endif // QUANTUM_MLIR_FRONTEND_QASM_QASM3_GATELIBRARY_H
