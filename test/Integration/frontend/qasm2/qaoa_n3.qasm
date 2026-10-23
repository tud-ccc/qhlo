// RUN: quantum-qasm %s | quantum-opt --inline | FileCheck %s

// quantum-qasm %s | quantum-opt --inline --convert-quantum-to-qillr | FileCheck %s --check-prefixes=CHECK2
// Stripped down from QASMBenc small/qaoa_n3.qasm


OPENQASM 2.0;
include "qelib1.inc";

qreg q[3];
creg m2[1];
creg m0[1];
creg m1[1];

h q[0];
h q[1];
h q[2];

measure q[2] -> m2[0];
measure q[0] -> m0[0];
measure q[1] -> m1[0];

// Check the complete operation sequence and SSA wiring.
// CHECK-LABEL: module {
// CHECK-NEXT:         qpu.module @qaoa_n3 {
// CHECK-NEXT:           "qpu.circuit"() <{function_type = () -> (tensor<1xi1>, tensor<1xi1>, tensor<1xi1>), sym_name = "main"}> ({
// CHECK-NEXT:             %[[VAL_0:.*]] = "quantum.alloc"() : () -> !quantum.qubit<3>
// CHECK-NEXT:             %[[VAL_1:.*]]:2 = "quantum.split"(%[[VAL_0]]) : (!quantum.qubit<3>) -> (!quantum.qubit<1>, !quantum.qubit<2>)
// CHECK-NEXT:             %[[VAL_2:.*]] = "quantum.H"(%[[VAL_1]]#0) : (!quantum.qubit<1>) -> !quantum.qubit<1>
// CHECK-NEXT:             %[[VAL_3:.*]]:2 = "quantum.split"(%[[VAL_1]]#1) : (!quantum.qubit<2>) -> (!quantum.qubit<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[VAL_4:.*]] = "quantum.H"(%[[VAL_3]]#0) : (!quantum.qubit<1>) -> !quantum.qubit<1>
// CHECK-NEXT:             %[[VAL_5:.*]] = "quantum.H"(%[[VAL_3]]#1) : (!quantum.qubit<1>) -> !quantum.qubit<1>
// CHECK-NEXT:             %[[VAL_6:.*]], %[[VAL_7:.*]] = "quantum.measure"(%[[VAL_5]]) : (!quantum.qubit<1>) -> (!quantum.measurement<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[VAL_8:.*]] = "quantum.to_tensor"(%[[VAL_6]]) : (!quantum.measurement<1>) -> tensor<1xi1>
// CHECK-NEXT:             %[[VAL_9:.*]], %[[VAL_10:.*]] = "quantum.measure"(%[[VAL_2]]) : (!quantum.qubit<1>) -> (!quantum.measurement<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[VAL_11:.*]] = "quantum.to_tensor"(%[[VAL_9]]) : (!quantum.measurement<1>) -> tensor<1xi1>
// CHECK-NEXT:             %[[VAL_12:.*]], %[[VAL_13:.*]] = "quantum.measure"(%[[VAL_4]]) : (!quantum.qubit<1>) -> (!quantum.measurement<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[VAL_14:.*]] = "quantum.to_tensor"(%[[VAL_12]]) : (!quantum.measurement<1>) -> tensor<1xi1>
// CHECK-DAG:             "quantum.deallocate"(%[[VAL_10]]) : (!quantum.qubit<1>) -> ()
// CHECK-DAG:             "quantum.deallocate"(%[[VAL_13]]) : (!quantum.qubit<1>) -> ()
// CHECK-DAG:             "quantum.deallocate"(%[[VAL_7]]) : (!quantum.qubit<1>) -> ()
// CHECK-NEXT:             "qpu.return"(%[[VAL_11]], %[[VAL_14]], %[[VAL_8]]) : (tensor<1xi1>, tensor<1xi1>, tensor<1xi1>) -> ()
// CHECK-NEXT:           }) : () -> ()
// CHECK-NEXT:         }
// CHECK-NEXT:         func.func @qasm_main() -> (tensor<1xi1>, tensor<1xi1>, tensor<1xi1>) {
// CHECK-NEXT:           %[[EMPTY_0:.*]] = tensor.empty() : tensor<1xi1>
// CHECK-NEXT:           %[[EMPTY_1:.*]] = tensor.empty() : tensor<1xi1>
// CHECK-NEXT:           %[[EMPTY_2:.*]] = tensor.empty() : tensor<1xi1>
// CHECK-NEXT:           %[[EXECUTE_0:.*]]:3 = qpu.execute @qaoa_n3::@main ins () outs (%[[EMPTY_0]] : tensor<1xi1>, %[[EMPTY_1]] : tensor<1xi1>, %[[EMPTY_2]] : tensor<1xi1>)
// CHECK-NEXT:           return %[[EXECUTE_0]]#0, %[[EXECUTE_0]]#1, %[[EXECUTE_0]]#2 : tensor<1xi1>, tensor<1xi1>, tensor<1xi1>
// CHECK-NEXT:         }
// CHECK-NEXT:       }
