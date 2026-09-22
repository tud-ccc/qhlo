// RUN: quantum-qasm %s | quantum-opt --inline | FileCheck %s

// quantum-qasm %s | quantum-opt --inline --convert-quantum-to-qillr | FileCheck %s --check-prefixes=CHECK2
// Stripped down from QASMBenc small/qaoa_n3.qasm

// CHECK: module {
// CHECK-NEXT: qpu.module @qasm_generated {
// CHECK-NEXT: "qpu.circuit"() <{function_type = () -> (tensor<1xi1>, tensor<1xi1>, tensor<1xi1>), sym_name = "main"}> ({
// CHECK-NEXT: %[[Q:.*]] = "quantum.alloc"() : () -> !quantum.qubit<3>
// CHECK-NEXT: %[[SPLIT0:.*]]:2 = "quantum.split"(%[[Q]]) : (!quantum.qubit<3>) -> (!quantum.qubit<1>, !quantum.qubit<2>)
// CHECK-NEXT: %[[H0:.*]] = "quantum.H"(%[[SPLIT0]]#0) : (!quantum.qubit<1>) -> !quantum.qubit<1>
// CHECK-NEXT: %[[SPLIT1:.*]]:2 = "quantum.split"(%[[SPLIT0]]#1) : (!quantum.qubit<2>) -> (!quantum.qubit<1>, !quantum.qubit<1>)
// CHECK-NEXT: %[[H1:.*]] = "quantum.H"(%[[SPLIT1]]#0) : (!quantum.qubit<1>) -> !quantum.qubit<1>
// CHECK-NEXT: %[[H2:.*]] = "quantum.H"(%[[SPLIT1]]#1) : (!quantum.qubit<1>) -> !quantum.qubit<1>
// CHECK-NEXT: %[[MEASURE2:.*]], %[[POST2:.*]] = "quantum.measure"(%[[H2]]) : (!quantum.qubit<1>) -> (!quantum.measurement<1>, !quantum.qubit<1>)
// CHECK-NEXT: %[[TENSOR2:.*]] = "quantum.to_tensor"(%[[MEASURE2]]) : (!quantum.measurement<1>) -> tensor<1xi1>
// CHECK-NEXT: %[[MEASURE0:.*]], %[[POST0:.*]] = "quantum.measure"(%[[H0]]) : (!quantum.qubit<1>) -> (!quantum.measurement<1>, !quantum.qubit<1>)
// CHECK-NEXT: %[[TENSOR0:.*]] = "quantum.to_tensor"(%[[MEASURE0]]) : (!quantum.measurement<1>) -> tensor<1xi1>
// CHECK-NEXT: %[[MEASURE1:.*]], %[[POST1:.*]] = "quantum.measure"(%[[H1]]) : (!quantum.qubit<1>) -> (!quantum.measurement<1>, !quantum.qubit<1>)
// CHECK-NEXT: %[[TENSOR1:.*]] = "quantum.to_tensor"(%[[MEASURE1]]) : (!quantum.measurement<1>) -> tensor<1xi1>
// CHECK-NEXT: "qpu.return"(%[[TENSOR0]], %[[TENSOR1]], %[[TENSOR2]]) : (tensor<1xi1>, tensor<1xi1>, tensor<1xi1>) -> ()
// CHECK-NEXT: }) : () -> ()
// CHECK-NEXT: }
// CHECK-NEXT: func.func @qasm_main() -> (tensor<1xi1>, tensor<1xi1>, tensor<1xi1>) {
// CHECK-NEXT: %[[EMPTY0:.*]] = tensor.empty() : tensor<1xi1>
// CHECK-NEXT: %[[EMPTY1:.*]] = tensor.empty() : tensor<1xi1>
// CHECK-NEXT: %[[EMPTY2:.*]] = tensor.empty() : tensor<1xi1>
// CHECK-NEXT: %[[EXEC:.*]]:3 = qpu.execute @qasm_generated::@main ins () outs (%[[EMPTY0]] : tensor<1xi1>, %[[EMPTY1]] : tensor<1xi1>, %[[EMPTY2]] : tensor<1xi1>)
// CHECK-NEXT: return %[[EXEC]]#0, %[[EXEC]]#1, %[[EXEC]]#2 : tensor<1xi1>, tensor<1xi1>, tensor<1xi1>
// CHECK-NEXT: }
// CHECK-NEXT: }

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
