// RUN: quantum-qasm %s | FileCheck %s

OPENQASM 2.0;
include "qelib1.inc";
qreg q[1];
creg c[1];
measure q[0] -> c[0];
if(c==0) x q[0];
if(c==0) x q[0];
measure q[0] -> c[0];
reset q[0];

// Check the complete operation sequence and SSA wiring.
// CHECK-LABEL: module {
// CHECK-NEXT:         qpu.module @"qasm-if" {
// CHECK-NEXT:           "qpu.circuit"() <{function_type = () -> tensor<1xi1>, sym_name = "main"}> ({
// CHECK-NEXT:             %[[VAL_0:.*]] = "quantum.alloc"() : () -> !quantum.qubit<1>
// CHECK-NEXT:             %[[CONSTANT_0:.*]] = arith.constant dense<false> : tensor<1xi1>
// CHECK-NEXT:             %[[VAL_1:.*]], %[[VAL_2:.*]] = "quantum.measure"(%[[VAL_0]]) : (!quantum.qubit<1>) -> (!quantum.measurement<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[VAL_3:.*]] = "qpu.to_bits"(%[[VAL_1]]) : (!quantum.measurement<1>) -> tensor<1xi1>
// CHECK-NEXT:             %[[INSERT_SLICE_0:.*]] = tensor.insert_slice %[[VAL_3]] into %[[CONSTANT_0]][0] [1] [1] : tensor<1xi1> into tensor<1xi1>
// CHECK-NEXT:             %[[CONSTANT_1:.*]] = arith.constant false
// CHECK-NEXT:             %[[VAL_4:.*]] = "qpu.bits_eq"(%[[INSERT_SLICE_0]], %[[CONSTANT_1]]) : (tensor<1xi1>, i1) -> i1
// CHECK-NEXT:             %[[IF_0:.*]] = scf.if %[[VAL_4]] -> (!quantum.qubit<1>) {
// CHECK-NEXT:               %[[VAL_5:.*]] = "quantum.X"(%[[VAL_2]]) : (!quantum.qubit<1>) -> !quantum.qubit<1>
// CHECK-NEXT:               scf.yield %[[VAL_5]] : !quantum.qubit<1>
// CHECK-NEXT:             } else {
// CHECK-NEXT:               scf.yield %[[VAL_2]] : !quantum.qubit<1>
// CHECK-NEXT:             }
// CHECK-NEXT:             %[[CONSTANT_2:.*]] = arith.constant false
// CHECK-NEXT:             %[[VAL_6:.*]] = "qpu.bits_eq"(%[[INSERT_SLICE_0]], %[[CONSTANT_2]]) : (tensor<1xi1>, i1) -> i1
// CHECK-NEXT:             %[[IF_1:.*]] = scf.if %[[VAL_6]] -> (!quantum.qubit<1>) {
// CHECK-NEXT:               %[[VAL_7:.*]] = "quantum.X"(%[[IF_0]]) : (!quantum.qubit<1>) -> !quantum.qubit<1>
// CHECK-NEXT:               scf.yield %[[VAL_7]] : !quantum.qubit<1>
// CHECK-NEXT:             } else {
// CHECK-NEXT:               scf.yield %[[IF_0]] : !quantum.qubit<1>
// CHECK-NEXT:             }
// CHECK-NEXT:             %[[VAL_8:.*]], %[[VAL_9:.*]] = "quantum.measure"(%[[IF_1]]) : (!quantum.qubit<1>) -> (!quantum.measurement<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[VAL_10:.*]] = "qpu.to_bits"(%[[VAL_8]]) : (!quantum.measurement<1>) -> tensor<1xi1>
// CHECK-NEXT:             %[[INSERT_SLICE_1:.*]] = tensor.insert_slice %[[VAL_10]] into %[[INSERT_SLICE_0]][0] [1] [1] : tensor<1xi1> into tensor<1xi1>
// CHECK-NEXT:             %[[VAL_11:.*]] = "quantum.reset"(%[[VAL_9]]) : (!quantum.qubit<1>) -> !quantum.qubit<1>
// CHECK-DAG:             "quantum.deallocate"(%[[VAL_11]]) : (!quantum.qubit<1>) -> ()
// CHECK-NEXT:             "qpu.return"(%[[INSERT_SLICE_1]]) : (tensor<1xi1>) -> ()
// CHECK-NEXT:           }) : () -> ()
// CHECK-NEXT:         }
// CHECK-NEXT:         func.func @qasm_main() -> tensor<1xi1> {
// CHECK-NEXT:           %[[EMPTY_0:.*]] = tensor.empty() : tensor<1xi1>
// CHECK-NEXT:           %[[EXECUTE_0:.*]] = qpu.execute @"qasm-if"::@main ins () outs (%[[EMPTY_0]] : tensor<1xi1>)
// CHECK-NEXT:           return %[[EXECUTE_0]] : tensor<1xi1>
// CHECK-NEXT:         }
// CHECK-NEXT:       }
