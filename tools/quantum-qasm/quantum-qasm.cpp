/// Main entry point for the quantum-qasm frontend driver.
///
/// @file
/// @author Lars Schütze (lars.schuetze@tu-dresden.de)

#include "frontend/qasm/QASMFrontend.h"

#include <llvm/Support/CommandLine.h>
#include <llvm/Support/InitLLVM.h>
#include <llvm/Support/MemoryBuffer.h>
#include <llvm/Support/SourceMgr.h>
#include <llvm/Support/raw_ostream.h>
#include <mlir/IR/BuiltinOps.h>
#include <mlir/IR/Diagnostics.h>
#include <mlir/IR/MLIRContext.h>
#include <mlir/Support/FileUtilities.h>
#include <mlir/Support/ToolUtilities.h>

namespace {

llvm::cl::opt<std::string> inputFilename(
    llvm::cl::Positional,
    llvm::cl::desc("<input QASM file>"),
    llvm::cl::init("-"),
    llvm::cl::value_desc("filename"));

llvm::cl::opt<bool> splitInputFile(
    "split-input-file",
    llvm::cl::desc("Split the input file into independent chunks"),
    llvm::cl::init(false));

llvm::cl::opt<bool> verifyDiagnostics(
    "verify-diagnostics",
    llvm::cl::desc("Verify emitted diagnostics against expected-* comments"),
    llvm::cl::init(false));

mlir::LogicalResult processBuffer(
    std::unique_ptr<llvm::MemoryBuffer> input,
    llvm::raw_ostream &output)
{
    mlir::MLIRContext context;
    llvm::SourceMgr sourceMgr;
    // Each chunk has its own source manager and parser line numbers. Keep the
    // physical filename so diagnostic matching and relative includes agree.
    sourceMgr.AddNewSourceBuffer(
        llvm::MemoryBuffer::getMemBuffer(
            input->getBuffer(),
            inputFilename,
            /*RequiresNullTerminator=*/false),
        llvm::SMLoc());
    const auto* buffer = sourceMgr.getMemoryBuffer(sourceMgr.getMainFileID());
    std::unique_ptr<mlir::SourceMgrDiagnosticVerifierHandler> verifier;
    if (verifyDiagnostics)
        verifier = std::make_unique<mlir::SourceMgrDiagnosticVerifierHandler>(
            sourceMgr,
            &context);

    auto module = quantum::frontend::parseQASM(
        buffer->getBuffer(),
        inputFilename,
        context);
    if (verifier) return verifier->verify();
    if (!module) return mlir::failure();

    module->print(output);
    output << '\n';
    return mlir::success();
}

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

    return mlir::failed(
        mlir::splitAndProcessBuffer(
            std::move(input),
            processBuffer,
            llvm::outs(),
            splitInputFile ? mlir::kDefaultSplitMarker : "",
            splitInputFile ? "// -----" : ""));
}
