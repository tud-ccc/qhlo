#include "QASMFrontend.h"

#include "qasm2/QASM2Frontend.h"
#include "qasm3/QASM3Frontend.h"

#include <mlir/IR/Diagnostics.h>

namespace quantum::frontend {
namespace {

enum class QASMVersion { QASM2, QASM3, Unknown };

QASMVersion detectQASMVersion(llvm::StringRef source)
{
    while (true) {
        source = source.ltrim();

        if (!source.starts_with("//")) break;

        const auto end = source.find('\n');
        if (end == llvm::StringRef::npos) return QASMVersion::Unknown;

        source = source.drop_front(end + 1);
    }

    if (!source.consume_front("OPENQASM")) return QASMVersion::Unknown;

    source = source.ltrim();

    const auto semicolon = source.find(';');
    if (semicolon == llvm::StringRef::npos) return QASMVersion::Unknown;

    const llvm::StringRef version = source.take_front(semicolon).trim();

    if (version == "2.0") return QASMVersion::QASM2;

    if (version.starts_with("3.")) return QASMVersion::QASM3;

    return QASMVersion::Unknown;
}

} // namespace

mlir::OwningOpRef<mlir::ModuleOp> parseQASM(
    llvm::StringRef source,
    llvm::StringRef filename,
    mlir::MLIRContext &context)
{
    switch (detectQASMVersion(source)) {
    case QASMVersion::QASM2: return parseQASM2(source, filename, context);

    case QASMVersion::QASM3: return parseQASM3(source, filename, context);

    case QASMVersion::Unknown:
        mlir::emitError(mlir::FileLineColLoc::get(&context, filename, 1, 1))
            << "expected 'OPENQASM 2.0;' or 'OPENQASM 3.x;'";
        return {};
    }

    llvm_unreachable("invalid QASM version");
}

} // namespace quantum::frontend
