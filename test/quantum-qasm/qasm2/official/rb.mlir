// RUN: quantum-qasm %S/Inputs/rb.qasm | FileCheck %s

// The unmodified upstream source and provenance are in Inputs/ and README.md.
// Check typed operations, parameters, register slices and SSA flow through
// gates, barriers, measurements, classical conditions and circuit results.

// CHECK-LABEL: module {
// CHECK-NEXT:         qpu.module @rb {
// CHECK-NEXT:           "qpu.circuit"() <{function_type = () -> tensor<2xi1>, sym_name = "main"}> ({
// CHECK-NEXT:             %[[VAL_0:.*]] = "quantum.alloc"() : () -> !quantum.qubit<2>
// CHECK-NEXT:             %[[VAL_1:.*]]:2 = "quantum.split"(%[[VAL_0]]) : (!quantum.qubit<2>) -> (!quantum.qubit<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[VAL_2:.*]] = "quantum.H"(%[[VAL_1]]#0) : (!quantum.qubit<1>) -> !quantum.qubit<1>
// CHECK-NEXT:             %[[VAL_3:.*]]:2 = "quantum.barrier"(%[[VAL_2]], %[[VAL_1]]#1) : (!quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[VAL_4:.*]], %[[VAL_5:.*]] = "quantum.CZ"(%[[VAL_3]]#0, %[[VAL_3]]#1) : (!quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[VAL_6:.*]]:2 = "quantum.barrier"(%[[VAL_4]], %[[VAL_5]]) : (!quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[VAL_7:.*]] = "quantum.S"(%[[VAL_6]]#0) : (!quantum.qubit<1>) -> !quantum.qubit<1>
// CHECK-NEXT:             %[[VAL_8:.*]], %[[VAL_9:.*]] = "quantum.CZ"(%[[VAL_7]], %[[VAL_6]]#1) : (!quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[VAL_10:.*]]:2 = "quantum.barrier"(%[[VAL_8]], %[[VAL_9]]) : (!quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[VAL_11:.*]] = "quantum.S"(%[[VAL_10]]#0) : (!quantum.qubit<1>) -> !quantum.qubit<1>
// CHECK-NEXT:             %[[VAL_12:.*]] = "quantum.Z"(%[[VAL_11]]) : (!quantum.qubit<1>) -> !quantum.qubit<1>
// CHECK-NEXT:             %[[VAL_13:.*]] = "quantum.H"(%[[VAL_12]]) : (!quantum.qubit<1>) -> !quantum.qubit<1>
// CHECK-NEXT:             %[[VAL_14:.*]]:2 = "quantum.barrier"(%[[VAL_13]], %[[VAL_10]]#1) : (!quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[CONSTANT_0:.*]] = arith.constant dense<false> : tensor<2xi1>
// CHECK-NEXT:             %[[VAL_15:.*]], %[[VAL_16:.*]] = "quantum.measure"(%[[VAL_14]]#0) : (!quantum.qubit<1>) -> (!quantum.measurement<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[VAL_17:.*]] = "quantum.to_tensor"(%[[VAL_15]]) : (!quantum.measurement<1>) -> tensor<1xi1>
// CHECK-NEXT:             %[[INSERT_SLICE_0:.*]] = tensor.insert_slice %[[VAL_17]] into %[[CONSTANT_0]][0] [1] [1] : tensor<1xi1> into tensor<2xi1>
// CHECK-NEXT:             %[[VAL_18:.*]], %[[VAL_19:.*]] = "quantum.measure"(%[[VAL_14]]#1) : (!quantum.qubit<1>) -> (!quantum.measurement<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[VAL_20:.*]] = "quantum.to_tensor"(%[[VAL_18]]) : (!quantum.measurement<1>) -> tensor<1xi1>
// CHECK-NEXT:             %[[INSERT_SLICE_1:.*]] = tensor.insert_slice %[[VAL_20]] into %[[INSERT_SLICE_0]][1] [1] [1] : tensor<1xi1> into tensor<2xi1>
// CHECK-DAG:             "quantum.deallocate"(%[[VAL_16]]) : (!quantum.qubit<1>) -> ()
// CHECK-DAG:             "quantum.deallocate"(%[[VAL_19]]) : (!quantum.qubit<1>) -> ()
// CHECK-NEXT:             "qpu.return"(%[[INSERT_SLICE_1]]) : (tensor<2xi1>) -> ()
// CHECK-NEXT:           }) : () -> ()
// CHECK-NEXT:         }
// CHECK-NEXT:         func.func @qasm_main() -> tensor<2xi1> {
// CHECK-NEXT:           %[[EMPTY_0:.*]] = tensor.empty() : tensor<2xi1>
// CHECK-NEXT:           %[[EXECUTE_0:.*]] = qpu.execute @rb::@main ins () outs (%[[EMPTY_0]] : tensor<2xi1>)
// CHECK-NEXT:           return %[[EXECUTE_0]] : tensor<2xi1>
// CHECK-NEXT:         }
// CHECK-NEXT:       }
