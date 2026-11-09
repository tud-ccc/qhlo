// RUN: quantum-translate --mlir-to-openqasm %s | FileCheck %s

module {
  qpu.module @qpu {
    "qpu.circuit"() <{function_type = () -> tensor<1xi1>, sym_name = "main"}> ({
// CHECK: OPENQASM 2.0;
// CHECK-NEXT: include "qelib1.inc";
// CHECK: qreg [[q:q.+]][1]; 
%q = "qillr.alloc"() <{size = 1 : i64}> : () -> !qillr.qubit
// CHECK: creg [[c:c.+]][1];
%r = "qillr.ralloc"() <{size = 1 : i64}> : () -> !qillr.result
 // CHECK-NEXT: measure [[q]][0] -> [[c]][0];
"qillr.measure"(%q, %r) <{inputIndex = [0], resultIndex = [0]}> : (!qillr.qubit, !qillr.result) -> ()
// CHECK-NOT: "qpu.to_bits"
%mt = "qpu.to_bits"(%r) : (!qillr.result) -> tensor<1xi1>
%cst = arith.constant dense<true> : tensor<1xi1>
%cmp = arith.cmpi eq, %mt, %cst : tensor<1xi1>
%c0 = arith.constant 0 : index
%b = tensor.extract %cmp[%c0] : tensor<1xi1>
// CHECK: if([[c]]==1)
scf.if %b {
  // CHECK: x [[q]][0];
  "qillr.X"(%q) <{index = [0]}> : (!qillr.qubit) -> ()
}
// CHECK-NOT: "qillr.deallocate"
"qillr.deallocate"(%q) <{index = [0]}> : (!qillr.qubit) -> ()
  "qpu.return"(%mt) : (tensor<1xi1>) -> ()
    }) : () -> ()
  }
  func.func public @qasm_main() -> tensor<1xi1> {
    %0 = tensor.empty() : tensor<1xi1>
    %1 = qpu.execute @qpu::@main ins() outs(%0 : tensor<1xi1>)
    return %1 : tensor<1xi1>
  }
}
