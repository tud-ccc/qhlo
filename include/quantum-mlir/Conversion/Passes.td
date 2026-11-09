//===- Passes.td - Quantum dialect passes ---------------------*- tablegen -*-===//
//
// This is the definitions file for the quantum-mlir dialect conversion passes.
//
//===----------------------------------------------------------------------===//

#ifndef QUANTUM_MLIR_CONVERSION_PASSES
#define QUANTUM_MLIR_CONVERSION_PASSES

include "mlir/Pass/PassBase.td"

def ConvertQuantumToQILLR : Pass<"convert-quantum-to-qillr"> {
    let summary = "Perform a dialect conversion from Quantum to QILLR";

    let constructor = "mlir::createConvertQuantumToQILLRPass()";

    let dependentDialects = [
        "quantum::QuantumDialect",
        "qillr::QILLRDialect",
        "qpu::QPUDialect",
        "tensor::TensorDialect"
    ];
}

def ConvertQILLRToLLVM : Pass<"convert-qillr-to-llvm"> {
    let summary = "Perform a dialect conversion from QILLR to LLVM MLIR";

    let constructor = "mlir::createConvertQILLRToLLVMPass()";
    
    let dependentDialects = [
        "qillr::QILLRDialect",
        "qpu::QPUDialect",
        "LLVM::LLVMDialect",
        "tensor::TensorDialect"
    ];
}

def ConvertScfToRVSDG : Pass<"convert-scf-to-rvsdg"> {
  let summary = "Transform `scf.if` and `scf.for` to RVSDG variants of the rvsdg dialect.";

  let description = [{
    This pass transforms structured control flow to the regionalized value state dependence
    graph (RVSDG) dialect.
  }];

  let constructor = "mlir::createConvertScfToRVSDGPass()";

  let dependentDialects = [
    "scf::SCFDialect",
    "rvsdg::RVSDGDialect"
  ];
}

def ConvertRVSDG : Pass<"convert-rvsdg"> {
  let summary = "Transform rvsdg dialect operations and types.";

  let description = [{
    This pass transforms RVSDG dialect operations' types and operations.
  }];

  let constructor = "mlir::createConvertRVSDGPass()";

  let dependentDialects = [
    "rvsdg::RVSDGDialect"
  ];
}

def ConvertRVSDGToScf : Pass<"convert-rvsdg-to-scf"> {
  let summary = "Transform rvsdg dialect to scf.";

  let description = [{
    This pass transforms RVSDG dialect to scf.
  }];

  let constructor = "mlir::createConvertRVSDGToScfPass()";

  let dependentDialects = [
    "rvsdg::RVSDGDialect",
    "scf::SCFDialect"
  ];
}


#endif // QUANTUM_MLIR_CONVERSION_PASSES
