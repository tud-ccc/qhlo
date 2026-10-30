// RUN: quantum-translate --mlir-to-openqasm %s | FileCheck %s

module {
  qpu.module @qpu {
    "qpu.circuit"() <{function_type = () -> tensor<32xi1>, sym_name = "main"}> ({
// CHECK: OPENQASM 2.0;
// CHECK-NEXT: include "qelib1.inc";
      %cst = arith.constant dense<[false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, true]> : tensor<32xi1>
      %c1 = arith.constant 1 : index
      %c32 = arith.constant 32 : index
      %c0 = arith.constant 0 : index
      %true = arith.constant true
      %cst_0 = arith.constant dense<false> : tensor<32xi1>
      %0 = "qillr.alloc"() <{size = 32 : i64}> : () -> !qillr.qubit
      "qillr.H"(%0) <{index = [0]}> : (!qillr.qubit) -> ()
      "qillr.H"(%0) <{index = [1]}> : (!qillr.qubit) -> ()
      "qillr.H"(%0) <{index = [2]}> : (!qillr.qubit) -> ()
      "qillr.H"(%0) <{index = [3]}> : (!qillr.qubit) -> ()
      "qillr.H"(%0) <{index = [4]}> : (!qillr.qubit) -> ()
      "qillr.H"(%0) <{index = [5]}> : (!qillr.qubit) -> ()
      "qillr.H"(%0) <{index = [6]}> : (!qillr.qubit) -> ()
      "qillr.H"(%0) <{index = [7]}> : (!qillr.qubit) -> ()
      "qillr.H"(%0) <{index = [8]}> : (!qillr.qubit) -> ()
      "qillr.H"(%0) <{index = [9]}> : (!qillr.qubit) -> ()
      "qillr.H"(%0) <{index = [10]}> : (!qillr.qubit) -> ()
      "qillr.H"(%0) <{index = [11]}> : (!qillr.qubit) -> ()
      "qillr.H"(%0) <{index = [12]}> : (!qillr.qubit) -> ()
      "qillr.H"(%0) <{index = [13]}> : (!qillr.qubit) -> ()
      "qillr.H"(%0) <{index = [14]}> : (!qillr.qubit) -> ()
      "qillr.H"(%0) <{index = [15]}> : (!qillr.qubit) -> ()
      "qillr.H"(%0) <{index = [16]}> : (!qillr.qubit) -> ()
      "qillr.H"(%0) <{index = [17]}> : (!qillr.qubit) -> ()
      "qillr.H"(%0) <{index = [18]}> : (!qillr.qubit) -> ()
      "qillr.H"(%0) <{index = [19]}> : (!qillr.qubit) -> ()
      "qillr.H"(%0) <{index = [20]}> : (!qillr.qubit) -> ()
      "qillr.H"(%0) <{index = [21]}> : (!qillr.qubit) -> ()
      "qillr.H"(%0) <{index = [22]}> : (!qillr.qubit) -> ()
      "qillr.H"(%0) <{index = [23]}> : (!qillr.qubit) -> ()
      "qillr.H"(%0) <{index = [24]}> : (!qillr.qubit) -> ()
      "qillr.H"(%0) <{index = [25]}> : (!qillr.qubit) -> ()
      "qillr.H"(%0) <{index = [26]}> : (!qillr.qubit) -> ()
      "qillr.H"(%0) <{index = [27]}> : (!qillr.qubit) -> ()
      "qillr.H"(%0) <{index = [28]}> : (!qillr.qubit) -> ()
      "qillr.H"(%0) <{index = [29]}> : (!qillr.qubit) -> ()
      "qillr.H"(%0) <{index = [30]}> : (!qillr.qubit) -> ()
      "qillr.CNOT"(%0, %0) <{controlIndex = [0], targetIndex = [31]}> : (!qillr.qubit, !qillr.qubit) -> ()
      "qillr.CNOT"(%0, %0) <{controlIndex = [1], targetIndex = [31]}> : (!qillr.qubit, !qillr.qubit) -> ()
      "qillr.CNOT"(%0, %0) <{controlIndex = [2], targetIndex = [31]}> : (!qillr.qubit, !qillr.qubit) -> ()
      "qillr.CNOT"(%0, %0) <{controlIndex = [3], targetIndex = [31]}> : (!qillr.qubit, !qillr.qubit) -> ()
      "qillr.CNOT"(%0, %0) <{controlIndex = [4], targetIndex = [31]}> : (!qillr.qubit, !qillr.qubit) -> ()
      "qillr.CNOT"(%0, %0) <{controlIndex = [5], targetIndex = [31]}> : (!qillr.qubit, !qillr.qubit) -> ()
      "qillr.CNOT"(%0, %0) <{controlIndex = [6], targetIndex = [31]}> : (!qillr.qubit, !qillr.qubit) -> ()
      "qillr.CNOT"(%0, %0) <{controlIndex = [7], targetIndex = [31]}> : (!qillr.qubit, !qillr.qubit) -> ()
      "qillr.CNOT"(%0, %0) <{controlIndex = [8], targetIndex = [31]}> : (!qillr.qubit, !qillr.qubit) -> ()
      "qillr.CNOT"(%0, %0) <{controlIndex = [9], targetIndex = [31]}> : (!qillr.qubit, !qillr.qubit) -> ()
      "qillr.CNOT"(%0, %0) <{controlIndex = [10], targetIndex = [31]}> : (!qillr.qubit, !qillr.qubit) -> ()
      "qillr.CNOT"(%0, %0) <{controlIndex = [11], targetIndex = [31]}> : (!qillr.qubit, !qillr.qubit) -> ()
      "qillr.CNOT"(%0, %0) <{controlIndex = [12], targetIndex = [31]}> : (!qillr.qubit, !qillr.qubit) -> ()
      "qillr.CNOT"(%0, %0) <{controlIndex = [13], targetIndex = [31]}> : (!qillr.qubit, !qillr.qubit) -> ()
      "qillr.CNOT"(%0, %0) <{controlIndex = [14], targetIndex = [31]}> : (!qillr.qubit, !qillr.qubit) -> ()
      "qillr.CNOT"(%0, %0) <{controlIndex = [15], targetIndex = [31]}> : (!qillr.qubit, !qillr.qubit) -> ()
      "qillr.CNOT"(%0, %0) <{controlIndex = [16], targetIndex = [31]}> : (!qillr.qubit, !qillr.qubit) -> ()
      "qillr.CNOT"(%0, %0) <{controlIndex = [17], targetIndex = [31]}> : (!qillr.qubit, !qillr.qubit) -> ()
      "qillr.CNOT"(%0, %0) <{controlIndex = [18], targetIndex = [31]}> : (!qillr.qubit, !qillr.qubit) -> ()
      "qillr.CNOT"(%0, %0) <{controlIndex = [19], targetIndex = [31]}> : (!qillr.qubit, !qillr.qubit) -> ()
      "qillr.CNOT"(%0, %0) <{controlIndex = [20], targetIndex = [31]}> : (!qillr.qubit, !qillr.qubit) -> ()
      "qillr.CNOT"(%0, %0) <{controlIndex = [21], targetIndex = [31]}> : (!qillr.qubit, !qillr.qubit) -> ()
      "qillr.CNOT"(%0, %0) <{controlIndex = [22], targetIndex = [31]}> : (!qillr.qubit, !qillr.qubit) -> ()
      "qillr.CNOT"(%0, %0) <{controlIndex = [23], targetIndex = [31]}> : (!qillr.qubit, !qillr.qubit) -> ()
      "qillr.CNOT"(%0, %0) <{controlIndex = [24], targetIndex = [31]}> : (!qillr.qubit, !qillr.qubit) -> ()
      "qillr.CNOT"(%0, %0) <{controlIndex = [25], targetIndex = [31]}> : (!qillr.qubit, !qillr.qubit) -> ()
      "qillr.CNOT"(%0, %0) <{controlIndex = [26], targetIndex = [31]}> : (!qillr.qubit, !qillr.qubit) -> ()
      "qillr.CNOT"(%0, %0) <{controlIndex = [27], targetIndex = [31]}> : (!qillr.qubit, !qillr.qubit) -> ()
      "qillr.CNOT"(%0, %0) <{controlIndex = [28], targetIndex = [31]}> : (!qillr.qubit, !qillr.qubit) -> ()
      "qillr.CNOT"(%0, %0) <{controlIndex = [29], targetIndex = [31]}> : (!qillr.qubit, !qillr.qubit) -> ()
      "qillr.CNOT"(%0, %0) <{controlIndex = [30], targetIndex = [31]}> : (!qillr.qubit, !qillr.qubit) -> ()
      %1 = "qillr.ralloc"() <{size = 32 : i64}> : () -> !qillr.result
      "qillr.measure"(%0, %1) <{inputIndex = [31], resultIndex = [31]}> : (!qillr.qubit, !qillr.result) -> ()
      %2 = "qpu.to_bits"(%1) : (!qillr.result) -> tensor<32xi1>
      %3 = arith.cmpi eq, %2, %cst_0 : tensor<32xi1>
      %4 = scf.parallel (%arg0) = (%c0) to (%c32) step (%c1) init (%true) -> i1 {
        %extracted = tensor.extract %3[%arg0] : tensor<32xi1>
        scf.reduce(%extracted : i1) {
        ^bb0(%arg1: i1, %arg2: i1):
          %164 = arith.andi %arg1, %arg2 : i1
          scf.reduce.return %164 : i1
        }
      }
      scf.if %4 {
        "qillr.X"(%0) <{index = [31]}> : (!qillr.qubit) -> ()
      }
      "qillr.deallocate"(%0) <{index = [31]}> : (!qillr.qubit) -> ()
      "qpu.return"(%2) : (tensor<32xi1>) -> ()
    }) : () -> ()
  }
  func.func public @qasm_main() -> tensor<32xi1> {
    %0 = tensor.empty() : tensor<32xi1>
    %1 = qpu.execute @qpu::@main ins() outs(%0 : tensor<32xi1>)
    return %1 : tensor<32xi1>
  }
}
