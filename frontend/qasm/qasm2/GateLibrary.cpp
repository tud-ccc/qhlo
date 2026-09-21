//===---- GateLibrary.cpp -  Quantum Gate Definitions -------------------===//
//
// @author  Lars Schütze (lars.schuetze@tu-dresden.de)
//===----------------------------------------------------------------------===//

#include "GateLibrary.h"

namespace quantum::frontend {

GateDefinition* GateLibrary::lookup(llvm::StringRef name)
{
    const auto it = definitions.find(name);
    return it != definitions.end() ? &it->second : nullptr;
}

bool GateLibrary::insert(GateDefinition definition)
{
    const std::string name = definition.name;

    auto [it, inserted] = definitions.try_emplace(name, std::move(definition));

    return inserted;
}

} // namespace quantum::frontend
