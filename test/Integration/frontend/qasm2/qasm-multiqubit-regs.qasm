// RUN: quantum-qasm %s | quantum-opt --convert-quantum-to-qillr --canonicalize | FileCheck %s

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

// Check the complete operation sequence and SSA wiring.
// CHECK-LABEL: module {
// CHECK-NEXT:         qpu.module @"qasm-multiqubit-regs" {
// CHECK-NEXT:           "qpu.circuit"() <{function_type = () -> (tensor<1xi1>, tensor<1xi1>), sym_name = "main"}> ({
// CHECK-NEXT:             %[[CONSTANT_0:.*]] = arith.constant 0 : index
// CHECK-NEXT:             %[[CONSTANT_1:.*]] = arith.constant dense<false> : tensor<1xi1>
// CHECK-NEXT:             %[[VAL_0:.*]] = "qillr.alloc"() <{size = 2 : i64}> : () -> !qillr.qubit
// CHECK-NEXT:             %[[VAL_1:.*]] = "qillr.ralloc"() <{size = 1 : i64}> : () -> !qillr.result
// CHECK-NEXT:             "qillr.measure"(%[[VAL_0]], %[[VAL_1]]) <{inputIndex = [0], resultIndex = [0]}> : (!qillr.qubit, !qillr.result) -> ()
// CHECK-NEXT:             %[[VAL_2:.*]] = "qpu.to_bits"(%[[VAL_1]]) : (!qillr.result) -> tensor<1xi1>
// CHECK-NEXT:             %[[CMPI_0:.*]] = arith.cmpi eq, %[[VAL_2]], %[[CONSTANT_1]] : tensor<1xi1>
// CHECK-NEXT:             %[[EXTRACT_0:.*]] = tensor.extract %[[CMPI_0]]{{\[}}%[[CONSTANT_0]]] : tensor<1xi1>
// CHECK-NEXT:             scf.if %[[EXTRACT_0]] {
// CHECK-NEXT:               "qillr.X"(%[[VAL_0]]) <{index = [0]}> : (!qillr.qubit) -> ()
// CHECK-NEXT:             }
// CHECK-NEXT:             %[[VAL_3:.*]] = "qillr.ralloc"() <{size = 1 : i64}> : () -> !qillr.result
// CHECK-NEXT:             "qillr.measure"(%[[VAL_0]], %[[VAL_3]]) <{inputIndex = [1], resultIndex = [0]}> : (!qillr.qubit, !qillr.result) -> ()
// CHECK-NEXT:             %[[VAL_4:.*]] = "qpu.to_bits"(%[[VAL_3]]) : (!qillr.result) -> tensor<1xi1>
// CHECK-NEXT:             %[[CMPI_1:.*]] = arith.cmpi eq, %[[VAL_4]], %[[CONSTANT_1]] : tensor<1xi1>
// CHECK-NEXT:             %[[EXTRACT_1:.*]] = tensor.extract %[[CMPI_1]]{{\[}}%[[CONSTANT_0]]] : tensor<1xi1>
// CHECK-NEXT:             scf.if %[[EXTRACT_1]] {
// CHECK-NEXT:               "qillr.X"(%[[VAL_0]]) <{index = [1]}> : (!qillr.qubit) -> ()
// CHECK-NEXT:             }
// CHECK-NEXT:             "qillr.reset"(%[[VAL_0]]) <{index = [0]}> : (!qillr.qubit) -> ()
// CHECK-NEXT:             "qillr.reset"(%[[VAL_0]]) <{index = [1]}> : (!qillr.qubit) -> ()
// CHECK-NEXT:             "qillr.deallocate"(%[[VAL_0]]) <{index = [0]}> : (!qillr.qubit) -> ()
// CHECK-NEXT:             "qillr.deallocate"(%[[VAL_0]]) <{index = [1]}> : (!qillr.qubit) -> ()
// CHECK-NEXT:             "qpu.return"(%[[VAL_2]], %[[VAL_4]]) : (tensor<1xi1>, tensor<1xi1>) -> ()
// CHECK-NEXT:           }) : () -> ()
// CHECK-NEXT:         }
// CHECK-NEXT:         func.func @qasm_main() -> (tensor<1xi1>, tensor<1xi1>) {
// CHECK-NEXT:           %[[EMPTY_0:.*]] = tensor.empty() : tensor<1xi1>
// CHECK-NEXT:           %[[EMPTY_1:.*]] = tensor.empty() : tensor<1xi1>
// CHECK-NEXT:           %[[EXECUTE_0:.*]]:2 = qpu.execute @"qasm-multiqubit-regs"::@main ins () outs (%[[EMPTY_0]] : tensor<1xi1>, %[[EMPTY_1]] : tensor<1xi1>)
// CHECK-NEXT:           return %[[EXECUTE_0]]#0, %[[EXECUTE_0]]#1 : tensor<1xi1>, tensor<1xi1>
// CHECK-NEXT:         }
// CHECK-NEXT:       }
