// RUN: quantum-qasm %s | quantum-opt --convert-quantum-to-qillr --canonicalize | FileCheck %s

// CHECK: module {
  // CHECK: qpu.module @qasm_generated {
    // CHECK: "qpu.circuit"() <{function_type = () -> (tensor<1xi1>, tensor<1xi1>), sym_name = "main"}> ({
      // CHECK: %[[C0:.+]] = arith.constant 0 : index
      // CHECK: %[[CST:.+]] = arith.constant dense<false> : tensor<1xi1>
      // CHECK: %[[QUBIT:.+]] = "qillr.alloc"() <{size = 2 : i64}> : () -> !qillr.qubit
      // CHECK: %[[RESULT:.+]] = "qillr.ralloc"() <{size = 1 : i64}> : () -> !qillr.result
      // CHECK: "qillr.measure"(%[[QUBIT]], %[[RESULT]]) <{inputIndex = [0], resultIndex = [0]}> : (!qillr.qubit, !qillr.result) -> ()
      // CHECK: %[[MEASUREMENT:.+]] = "qillr.read_measurement"(%[[RESULT]]) <{index = []}> : (!qillr.result) -> tensor<1xi1>
      // CHECK: %[[CMP:.+]] = arith.cmpi eq, %[[MEASUREMENT]], %[[CST]] : tensor<1xi1>
      // CHECK: %[[EXTRACTED:.+]] = tensor.extract %[[CMP]][%[[C0]]] : tensor<1xi1>
      // CHECK: scf.if %[[EXTRACTED]] {
        // CHECK-NEXT: "qillr.X"(%[[QUBIT]]) <{index = [0]}> : (!qillr.qubit) -> ()
      // CHECK-NEXT: }
      // CHECK: %[[RESULT_1:.+]] = "qillr.ralloc"() <{size = 1 : i64}> : () -> !qillr.result
      // CHECK: "qillr.measure"(%[[QUBIT]], %[[RESULT_1]]) <{inputIndex = [1], resultIndex = [0]}> : (!qillr.qubit, !qillr.result) -> ()
      // CHECK: %[[MEASUREMENT_1:.+]] = "qillr.read_measurement"(%[[RESULT_1]]) <{index = []}> : (!qillr.result) -> tensor<1xi1>
      // CHECK: %[[CMP_1:.+]] = arith.cmpi eq, %[[MEASUREMENT_1]], %[[CST]] : tensor<1xi1>
      // CHECK: %[[EXTRACTED_4:.+]] = tensor.extract %[[CMP_1]][%[[C0]]] : tensor<1xi1>
      // CHECK: scf.if %[[EXTRACTED_4]] {
        // CHECK-NEXT: "qillr.X"(%[[QUBIT]]) <{index = [1]}> : (!qillr.qubit) -> ()
      // CHECK-NEXT: }
      // CHECK: "qillr.reset"(%[[QUBIT]]) <{index = [0]}> : (!qillr.qubit) -> ()
      // CHECK: "qillr.reset"(%[[QUBIT]]) <{index = [1]}> : (!qillr.qubit) -> ()
      // CHECK: "qillr.deallocate"(%[[QUBIT]]) <{index = [0]}> : (!qillr.qubit) -> ()
      // CHECK: "qillr.deallocate"(%[[QUBIT]]) <{index = [1]}> : (!qillr.qubit) -> ()
      // CHECK: "qpu.return"(%[[MEASUREMENT]], %[[MEASUREMENT_1]]) : (tensor<1xi1>, tensor<1xi1>) -> ()

  // CHECK: func.func @qasm_main() -> (tensor<1xi1>, tensor<1xi1>) {
    // CHECK: %[[EMPTY0:.+]] = tensor.empty() : tensor<1xi1>
    // CHECK: %[[EMPTY1:.+]] = tensor.empty() : tensor<1xi1>
    // CHECK: %[[RES:.+]]:2 = qpu.execute @qasm_generated::@main ins () outs (%[[EMPTY0]] : tensor<1xi1>, %[[EMPTY1]] : tensor<1xi1>)
    // CHECK: return %[[RES]]#0, %[[RES]]#1 : tensor<1xi1>, tensor<1xi1>


OPENQASM 2.0;
include "qelib1.inc";
qreg q[2];
creg c1[1];
creg c2[1];
measure q[0] -> c1[0];
if(c1==0) x q[0];
measure q[1] -> c2[0];
if(c2==0) x q[1];
reset q[0];
reset q[1];
