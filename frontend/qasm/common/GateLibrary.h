//===---- GateLibrary.h -  Quantum Gate Definitions ---------------------===//
//
// @author  Lars Schütze (lars.schuetze@tu-dresden.de)
//===----------------------------------------------------------------------===//

#ifndef QUANTUM_MLIR_FRONTEND_QASM_COMMON_GATELIBRARY_H
#define QUANTUM_MLIR_FRONTEND_QASM_COMMON_GATELIBRARY_H

#include "QASMScope.h"
#include "quantum-mlir/Dialect/Quantum/IR/QuantumOps.h"

#include <llvm/ADT/SmallVector.h>
#include <llvm/ADT/StringMap.h>
#include <llvm/ADT/StringRef.h>
#include <mlir/IR/BuiltinAttributes.h>
#include <string>
#include <utility>

namespace quantum::frontend {

template<typename BodyContext>
struct GateDefinition {
    std::string name;
    llvm::SmallVector<std::string> parameters;
    llvm::SmallVector<std::string> qubits;
    // The translation unit owns the context until deferred realization
    // completes.
    BodyContext* body = nullptr;
    std::string filename;
    mlir::quantum::GateOp gateOp;
    bool realized{false};
    QASMScope::Position lexicalPosition;
    bool realizing = false;
};

template<typename BodyContext>
class GateLibrary {
public:
    using Definition = GateDefinition<BodyContext>;

    [[nodiscard]]
    bool insert(Definition definition)
    {
        const std::string name = definition.name;
        return definitions.try_emplace(name, std::move(definition)).second;
    }

    [[nodiscard]]
    Definition* lookup(llvm::StringRef name)
    {
        const auto it = definitions.find(name);
        return it != definitions.end() ? &it->second : nullptr;
    }

private:
    llvm::StringMap<Definition> definitions;
};

} // namespace quantum::frontend

#endif // QUANTUM_MLIR_FRONTEND_QASM_COMMON_GATELIBRARY_H
