/// Main entry point for the quantum-qasm frontend driver.
///
/// @file
/// @author Lars Schütze (lars.schuetze@tu-dresden.de)

#include "frontend/qasm/QASMFrontend.h"

#include <llvm/Support/CommandLine.h>
#include <llvm/Support/InitLLVM.h>
#include <llvm/Support/MemoryBuffer.h>
#include <llvm/Support/raw_ostream.h>
#include <mlir/IR/BuiltinOps.h>
#include <mlir/IR/MLIRContext.h>
#include <mlir/Support/FileUtilities.h>

namespace {

llvm::cl::opt<std::string> inputFilename(
    llvm::cl::Positional,
    llvm::cl::desc("<input QASM file>"),
    llvm::cl::init("-"),
    llvm::cl::value_desc("filename"));

} // namespace

int main(int argc, char** argv)
{
    llvm::InitLLVM initLLVM(argc, argv);

    llvm::cl::ParseCommandLineOptions(
        argc,
        argv,
        "quantum-mlir OpenQASM frontend\n");

    // Read the input file. "-" means stdin.
    std::string errorMessage;
    auto input = mlir::openInputFile(inputFilename, &errorMessage);

    if (!input) {
        llvm::errs() << errorMessage << '\n';
        return 1;
    }

    // Create the MLIR context.
    mlir::MLIRContext context;

    // Parse QASM and lower it to MLIR.
    auto module = quantum::frontend::parseQASM(
        input->getBuffer(),
        inputFilename,
        context);

    if (!module) return 1;

    // Emit the resulting MLIR.
    module->print(llvm::outs());
    llvm::outs() << '\n';

    return 0;
}
