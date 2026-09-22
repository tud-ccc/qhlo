//===---- QASMIncludeResolver.h -  OpenQASM Include Resolution ----------===//
//
// @author  Lars Schütze (lars.schuetze@tu-dresden.de)
//===----------------------------------------------------------------------===//

#ifndef QUANTUM_MLIR_FRONTEND_QASM_COMMON_QASMINCLUDERESOLVER_H
#define QUANTUM_MLIR_FRONTEND_QASM_COMMON_QASMINCLUDERESOLVER_H

#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/StringMap.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/Support/Error.h"

#include <string>

namespace quantum::frontend {

struct ResolvedInclude {
    std::string filename;
    std::string source;
};

class QASMIncludeResolver {
public:
    void addBuiltin(
        llvm::StringRef name,
        llvm::StringRef source,
        llvm::StringRef logicalFilename);

    void addSearchPath(llvm::StringRef path);

    [[nodiscard]]
    llvm::Expected<ResolvedInclude>
    resolve(llvm::StringRef includeName, llvm::StringRef includingFile) const;

private:
    llvm::StringMap<ResolvedInclude> builtins;
    llvm::SmallVector<std::string> searchPaths;
};

} // namespace quantum::frontend

#endif // QUANTUM_MLIR_FRONTEND_QASM_COMMON_QASMINCLUDERESOLVER_H
