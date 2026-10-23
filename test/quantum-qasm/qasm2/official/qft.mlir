// RUN: quantum-qasm %S/Inputs/qft.qasm | FileCheck %s

// The unmodified upstream source and provenance are in Inputs/ and README.md.
// Check typed operations, parameters, register slices and SSA flow through
// gates, barriers, measurements, classical conditions and circuit results.

// CHECK-LABEL: module {
// CHECK-NEXT:         qpu.module @qft {
// CHECK-NEXT:           "qpu.circuit"() <{function_type = () -> tensor<4xi1>, sym_name = "main"}> ({
// CHECK-NEXT:             %[[VAL_0:.*]] = "quantum.alloc"() : () -> !quantum.qubit<4>
// CHECK-NEXT:             %[[VAL_1:.*]]:2 = "quantum.split"(%[[VAL_0]]) : (!quantum.qubit<4>) -> (!quantum.qubit<1>, !quantum.qubit<3>)
// CHECK-NEXT:             %[[VAL_2:.*]] = "quantum.X"(%[[VAL_1]]#0) : (!quantum.qubit<1>) -> !quantum.qubit<1>
// CHECK-NEXT:             %[[VAL_3:.*]]:3 = "quantum.split"(%[[VAL_1]]#1) : (!quantum.qubit<3>) -> (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[VAL_4:.*]] = "quantum.X"(%[[VAL_3]]#1) : (!quantum.qubit<1>) -> !quantum.qubit<1>
// CHECK-NEXT:             %[[VAL_5:.*]]:4 = "quantum.barrier"(%[[VAL_2]], %[[VAL_3]]#0, %[[VAL_4]], %[[VAL_3]]#2) : (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[VAL_6:.*]] = "quantum.H"(%[[VAL_5]]#0) : (!quantum.qubit<1>) -> !quantum.qubit<1>
// CHECK-NEXT:             %[[CONSTANT_0:.*]] = arith.constant 3.1415926535897931 : f64
// CHECK-NEXT:             %[[CONSTANT_1:.*]] = arith.constant 2.000000e+00 : f64
// CHECK-NEXT:             %[[DIVF_0:.*]] = arith.divf %[[CONSTANT_0]], %[[CONSTANT_1]] : f64
// CHECK-NEXT:             %[[VAL_7:.*]], %[[VAL_8:.*]] = "quantum.CU1"(%[[VAL_5]]#1, %[[VAL_6]], %[[DIVF_0]]) : (!quantum.qubit<1>, !quantum.qubit<1>, f64) -> (!quantum.qubit<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[VAL_9:.*]] = "quantum.H"(%[[VAL_7]]) : (!quantum.qubit<1>) -> !quantum.qubit<1>
// CHECK-NEXT:             %[[CONSTANT_2:.*]] = arith.constant 3.1415926535897931 : f64
// CHECK-NEXT:             %[[CONSTANT_3:.*]] = arith.constant 4.000000e+00 : f64
// CHECK-NEXT:             %[[DIVF_1:.*]] = arith.divf %[[CONSTANT_2]], %[[CONSTANT_3]] : f64
// CHECK-NEXT:             %[[VAL_10:.*]], %[[VAL_11:.*]] = "quantum.CU1"(%[[VAL_5]]#2, %[[VAL_8]], %[[DIVF_1]]) : (!quantum.qubit<1>, !quantum.qubit<1>, f64) -> (!quantum.qubit<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[CONSTANT_4:.*]] = arith.constant 3.1415926535897931 : f64
// CHECK-NEXT:             %[[CONSTANT_5:.*]] = arith.constant 2.000000e+00 : f64
// CHECK-NEXT:             %[[DIVF_2:.*]] = arith.divf %[[CONSTANT_4]], %[[CONSTANT_5]] : f64
// CHECK-NEXT:             %[[VAL_12:.*]], %[[VAL_13:.*]] = "quantum.CU1"(%[[VAL_10]], %[[VAL_9]], %[[DIVF_2]]) : (!quantum.qubit<1>, !quantum.qubit<1>, f64) -> (!quantum.qubit<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[VAL_14:.*]] = "quantum.H"(%[[VAL_12]]) : (!quantum.qubit<1>) -> !quantum.qubit<1>
// CHECK-NEXT:             %[[CONSTANT_6:.*]] = arith.constant 3.1415926535897931 : f64
// CHECK-NEXT:             %[[CONSTANT_7:.*]] = arith.constant 8.000000e+00 : f64
// CHECK-NEXT:             %[[DIVF_3:.*]] = arith.divf %[[CONSTANT_6]], %[[CONSTANT_7]] : f64
// CHECK-NEXT:             %[[VAL_15:.*]], %[[VAL_16:.*]] = "quantum.CU1"(%[[VAL_5]]#3, %[[VAL_11]], %[[DIVF_3]]) : (!quantum.qubit<1>, !quantum.qubit<1>, f64) -> (!quantum.qubit<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[CONSTANT_8:.*]] = arith.constant 3.1415926535897931 : f64
// CHECK-NEXT:             %[[CONSTANT_9:.*]] = arith.constant 4.000000e+00 : f64
// CHECK-NEXT:             %[[DIVF_4:.*]] = arith.divf %[[CONSTANT_8]], %[[CONSTANT_9]] : f64
// CHECK-NEXT:             %[[VAL_17:.*]], %[[VAL_18:.*]] = "quantum.CU1"(%[[VAL_15]], %[[VAL_13]], %[[DIVF_4]]) : (!quantum.qubit<1>, !quantum.qubit<1>, f64) -> (!quantum.qubit<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[CONSTANT_10:.*]] = arith.constant 3.1415926535897931 : f64
// CHECK-NEXT:             %[[CONSTANT_11:.*]] = arith.constant 2.000000e+00 : f64
// CHECK-NEXT:             %[[DIVF_5:.*]] = arith.divf %[[CONSTANT_10]], %[[CONSTANT_11]] : f64
// CHECK-NEXT:             %[[VAL_19:.*]], %[[VAL_20:.*]] = "quantum.CU1"(%[[VAL_17]], %[[VAL_14]], %[[DIVF_5]]) : (!quantum.qubit<1>, !quantum.qubit<1>, f64) -> (!quantum.qubit<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[VAL_21:.*]] = "quantum.H"(%[[VAL_19]]) : (!quantum.qubit<1>) -> !quantum.qubit<1>
// CHECK-NEXT:             %[[CONSTANT_12:.*]] = arith.constant dense<false> : tensor<4xi1>
// CHECK-NEXT:             %[[VAL_22:.*]], %[[VAL_23:.*]] = "quantum.measure"(%[[VAL_16]]) : (!quantum.qubit<1>) -> (!quantum.measurement<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[VAL_24:.*]] = "quantum.to_tensor"(%[[VAL_22]]) : (!quantum.measurement<1>) -> tensor<1xi1>
// CHECK-NEXT:             %[[INSERT_SLICE_0:.*]] = tensor.insert_slice %[[VAL_24]] into %[[CONSTANT_12]][0] [1] [1] : tensor<1xi1> into tensor<4xi1>
// CHECK-NEXT:             %[[VAL_25:.*]], %[[VAL_26:.*]] = "quantum.measure"(%[[VAL_18]]) : (!quantum.qubit<1>) -> (!quantum.measurement<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[VAL_27:.*]] = "quantum.to_tensor"(%[[VAL_25]]) : (!quantum.measurement<1>) -> tensor<1xi1>
// CHECK-NEXT:             %[[INSERT_SLICE_1:.*]] = tensor.insert_slice %[[VAL_27]] into %[[INSERT_SLICE_0]][1] [1] [1] : tensor<1xi1> into tensor<4xi1>
// CHECK-NEXT:             %[[VAL_28:.*]], %[[VAL_29:.*]] = "quantum.measure"(%[[VAL_20]]) : (!quantum.qubit<1>) -> (!quantum.measurement<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[VAL_30:.*]] = "quantum.to_tensor"(%[[VAL_28]]) : (!quantum.measurement<1>) -> tensor<1xi1>
// CHECK-NEXT:             %[[INSERT_SLICE_2:.*]] = tensor.insert_slice %[[VAL_30]] into %[[INSERT_SLICE_1]][2] [1] [1] : tensor<1xi1> into tensor<4xi1>
// CHECK-NEXT:             %[[VAL_31:.*]], %[[VAL_32:.*]] = "quantum.measure"(%[[VAL_21]]) : (!quantum.qubit<1>) -> (!quantum.measurement<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[VAL_33:.*]] = "quantum.to_tensor"(%[[VAL_31]]) : (!quantum.measurement<1>) -> tensor<1xi1>
// CHECK-NEXT:             %[[INSERT_SLICE_3:.*]] = tensor.insert_slice %[[VAL_33]] into %[[INSERT_SLICE_2]][3] [1] [1] : tensor<1xi1> into tensor<4xi1>
// CHECK-DAG:             "quantum.deallocate"(%[[VAL_23]]) : (!quantum.qubit<1>) -> ()
// CHECK-DAG:             "quantum.deallocate"(%[[VAL_26]]) : (!quantum.qubit<1>) -> ()
// CHECK-DAG:             "quantum.deallocate"(%[[VAL_29]]) : (!quantum.qubit<1>) -> ()
// CHECK-DAG:             "quantum.deallocate"(%[[VAL_32]]) : (!quantum.qubit<1>) -> ()
// CHECK-NEXT:             "qpu.return"(%[[INSERT_SLICE_3]]) : (tensor<4xi1>) -> ()
// CHECK-NEXT:           }) : () -> ()
// CHECK-NEXT:         }
// CHECK-NEXT:         func.func @qasm_main() -> tensor<4xi1> {
// CHECK-NEXT:           %[[EMPTY_0:.*]] = tensor.empty() : tensor<4xi1>
// CHECK-NEXT:           %[[EXECUTE_0:.*]] = qpu.execute @qft::@main ins () outs (%[[EMPTY_0]] : tensor<4xi1>)
// CHECK-NEXT:           return %[[EXECUTE_0]] : tensor<4xi1>
// CHECK-NEXT:         }
// CHECK-NEXT:       }
