//===---- GateLibrary.h -  Quantum Gate Definitions ---------------------===//
//
// @author  Lars Schütze (lars.schuetze@tu-dresden.de)
//===----------------------------------------------------------------------===//

#ifndef QUANTUM_MLIR_FRONTEND_QASM_QASM2_GATELIBRARY_H
#define QUANTUM_MLIR_FRONTEND_QASM_QASM2_GATELIBRARY_H

#include "quantum-mlir/Dialect/Quantum/IR/QuantumOps.h"

#include <llvm/ADT/SmallVector.h>
#include <llvm/ADT/StringMap.h>
#include <llvm/ADT/StringRef.h>
#include <qasm2Parser.h>

using namespace antlrcpp;
using namespace qasm2;

using namespace antlr4;

namespace quantum::frontend {

struct GateDefinition {
    std::string name;
    llvm::SmallVector<std::string> parameters;
    llvm::SmallVector<std::string> qubits;
    qasm2::qasm2Parser::ScopeContext* body;
    std::string filename;
    mlir::quantum::GateOp gateOp;
    bool realized{false};
};

class GateLibrary {
public:
    [[nodiscard]]
    bool insert(GateDefinition definition);

    [[nodiscard]]
    GateDefinition* lookup(llvm::StringRef name);

private:
    llvm::StringMap<GateDefinition> definitions;
};

} // namespace quantum::frontend

#endif // QUANTUM_MLIR_FRONTEND_QASM_QASM2_GATELIBRARY_H
