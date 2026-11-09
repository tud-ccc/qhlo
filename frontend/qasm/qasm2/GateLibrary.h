//===---- GateLibrary.h -  Quantum Gate Definitions ---------------------===//
//
// @author  Lars Schütze (lars.schuetze@tu-dresden.de)
//===----------------------------------------------------------------------===//

#ifndef QUANTUM_MLIR_FRONTEND_QASM_QASM2_GATELIBRARY_H
#define QUANTUM_MLIR_FRONTEND_QASM_QASM2_GATELIBRARY_H

#include "../common/GateLibrary.h"
#include "qasm2Parser.h"

namespace quantum::frontend::qasm2 {

using GateDefinition =
    quantum::frontend::GateDefinition<qasm2Parser::ScopeContext>;
using GateLibrary = quantum::frontend::GateLibrary<qasm2Parser::ScopeContext>;

} // namespace quantum::frontend::qasm2

#endif // QUANTUM_MLIR_FRONTEND_QASM_QASM2_GATELIBRARY_H
