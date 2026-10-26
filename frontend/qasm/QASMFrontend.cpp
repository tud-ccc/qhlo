//===---- QASMFrontend.cpp -  OpenQASM Frontend Dispatch ----------------===//
//
// @author  Lars Schütze (lars.schuetze@tu-dresden.de)
//===----------------------------------------------------------------------===//

#include "frontend/qasm/QASMFrontend.h"

#include "qasm2/QASM2Frontend.h"
#include "qasm3/QASM3Frontend.h"
#include "quantum-mlir/Dialect/QPU/IR/QPUBase.h"
#include "quantum-mlir/Dialect/Quantum/IR/QuantumBase.h"

#include <llvm/ADT/StringExtras.h>
#include <mlir/Dialect/Func/IR/FuncOps.h>
#include <mlir/Dialect/SCF/IR/SCF.h>
#include <mlir/Dialect/Tensor/IR/Tensor.h>
#include <mlir/IR/Diagnostics.h>

namespace quantum::frontend {
namespace {

enum class QASMVersion { QASM2, QASM3, Unknown };

QASMVersion detectQASMVersion(llvm::StringRef source)
{
    source = source.ltrim();
    while (source.starts_with("//") || source.starts_with("/*")) {
        if (source.consume_front("//")) {
            const auto end = source.find_first_of("\r\n");
            if (end == llvm::StringRef::npos) return QASMVersion::QASM3;
            source = source.drop_front(end);
        } else {
            const auto end = source.find("*/", 2);
            if (end == llvm::StringRef::npos) return QASMVersion::Unknown;
            source = source.drop_front(end + 2);
        }
        source = source.ltrim();
    }

    // An absent declaration selects QASM3. Its parser checks that any version
    // declaration occurs before all other statements.
    if (!source.consume_front("OPENQASM")) return QASMVersion::QASM3;
    if (!source.empty()
        && (llvm::isAlnum(source.front()) || source.front() == '_'))
        return QASMVersion::QASM3;

    const auto semicolon = source.find(';');
    if (semicolon == llvm::StringRef::npos) return QASMVersion::Unknown;

    const llvm::StringRef version = source.take_front(semicolon).trim();
    if (version == "2.0") return QASMVersion::QASM2;
    if (version == "3") return QASMVersion::QASM3;

    if (version.starts_with("3.")) {
        const auto minor = version.drop_front(2);
        if (!minor.empty()
            && minor.find_first_not_of("0123456789") == llvm::StringRef::npos)
            return QASMVersion::QASM3;
    }

    return QASMVersion::Unknown;
}

} // namespace

mlir::OwningOpRef<mlir::ModuleOp> parseQASM(
    llvm::StringRef source,
    llvm::StringRef filename,
    mlir::MLIRContext &context)
{

    context.loadDialect<
        mlir::quantum::QuantumDialect,
        mlir::qpu::QPUDialect,
        mlir::tensor::TensorDialect,
        mlir::arith::ArithDialect,
        mlir::scf::SCFDialect,
        mlir::func::FuncDialect>();

    switch (detectQASMVersion(source)) {
    case QASMVersion::QASM2:
        return qasm2::parseQASM2(source, filename, context);

    case QASMVersion::QASM3:
        return qasm3::parseQASM3(source, filename, context);

    case QASMVersion::Unknown:
        mlir::emitError(mlir::FileLineColLoc::get(&context, filename, 1, 1))
            << "expected 'OPENQASM 2.0;', 'OPENQASM 3;' or 'OPENQASM 3.x;'";
        return {};
    }

    llvm_unreachable("invalid QASM version");
}

} // namespace quantum::frontend
