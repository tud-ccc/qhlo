// RUN: quantum-qasm %S/Inputs/W-state.qasm | FileCheck %s

// The unmodified upstream source and provenance are in Inputs/ and README.md.
// Check typed operations, parameters, register slices and SSA flow through
// gates, barriers, measurements, classical conditions and circuit results.

// CHECK-LABEL: module {
// CHECK-NEXT:         qpu.module @"W-state" {
// CHECK-NEXT:           "quantum.gate"() <{function_type = (!quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>), sym_name = "cH"}> ({
// CHECK-NEXT:           ^bb0(%[[VAL_0:.*]]: !quantum.qubit<1>, %[[VAL_1:.*]]: !quantum.qubit<1>):
// CHECK-NEXT:             %[[VAL_2:.*]] = "quantum.H"(%[[VAL_1]]) : (!quantum.qubit<1>) -> !quantum.qubit<1>
// CHECK-NEXT:             %[[VAL_3:.*]] = "quantum.Sdg"(%[[VAL_2]]) : (!quantum.qubit<1>) -> !quantum.qubit<1>
// CHECK-NEXT:             %[[VAL_4:.*]], %[[VAL_5:.*]] = "quantum.CNOT"(%[[VAL_0]], %[[VAL_3]]) : (!quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[VAL_6:.*]] = "quantum.H"(%[[VAL_5]]) : (!quantum.qubit<1>) -> !quantum.qubit<1>
// CHECK-NEXT:             %[[VAL_7:.*]] = "quantum.T"(%[[VAL_6]]) : (!quantum.qubit<1>) -> !quantum.qubit<1>
// CHECK-NEXT:             %[[VAL_8:.*]], %[[VAL_9:.*]] = "quantum.CNOT"(%[[VAL_4]], %[[VAL_7]]) : (!quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[VAL_10:.*]] = "quantum.T"(%[[VAL_9]]) : (!quantum.qubit<1>) -> !quantum.qubit<1>
// CHECK-NEXT:             %[[VAL_11:.*]] = "quantum.H"(%[[VAL_10]]) : (!quantum.qubit<1>) -> !quantum.qubit<1>
// CHECK-NEXT:             %[[VAL_12:.*]] = "quantum.S"(%[[VAL_11]]) : (!quantum.qubit<1>) -> !quantum.qubit<1>
// CHECK-NEXT:             %[[VAL_13:.*]] = "quantum.X"(%[[VAL_12]]) : (!quantum.qubit<1>) -> !quantum.qubit<1>
// CHECK-NEXT:             %[[VAL_14:.*]] = "quantum.S"(%[[VAL_8]]) : (!quantum.qubit<1>) -> !quantum.qubit<1>
// CHECK-NEXT:             "quantum.return"(%[[VAL_14]], %[[VAL_13]]) : (!quantum.qubit<1>, !quantum.qubit<1>) -> ()
// CHECK-NEXT:           }) : () -> ()
// CHECK-NEXT:           "qpu.circuit"() <{function_type = () -> tensor<3xi1>, sym_name = "main"}> ({
// CHECK-NEXT:             %[[VAL_15:.*]] = "quantum.alloc"() : () -> !quantum.qubit<3>
// CHECK-NEXT:             %[[VAL_16:.*]]:2 = "quantum.split"(%[[VAL_15]]) : (!quantum.qubit<3>) -> (!quantum.qubit<1>, !quantum.qubit<2>)
// CHECK-NEXT:             %[[CONSTANT_0:.*]] = arith.constant 1.910630e+00 : f64
// CHECK-NEXT:             %[[CONSTANT_1:.*]] = arith.constant 0.000000e+00 : f64
// CHECK-NEXT:             %[[CONSTANT_2:.*]] = arith.constant 0.000000e+00 : f64
// CHECK-NEXT:             %[[VAL_17:.*]] = "quantum.U3"(%[[VAL_16]]#0, %[[CONSTANT_0]], %[[CONSTANT_1]], %[[CONSTANT_2]]) : (!quantum.qubit<1>, f64, f64, f64) -> !quantum.qubit<1>
// CHECK-NEXT:             %[[VAL_18:.*]]:2 = "quantum.split"(%[[VAL_16]]#1) : (!quantum.qubit<2>) -> (!quantum.qubit<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[VAL_19:.*]]:2 = "quantum.call"(%[[VAL_17]], %[[VAL_18]]#0) <{callee = @cH}> : (!quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[VAL_20:.*]], %[[VAL_21:.*]], %[[VAL_22:.*]] = "quantum.CCX"(%[[VAL_19]]#0, %[[VAL_19]]#1, %[[VAL_18]]#1) : (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[VAL_23:.*]] = "quantum.X"(%[[VAL_20]]) : (!quantum.qubit<1>) -> !quantum.qubit<1>
// CHECK-NEXT:             %[[VAL_24:.*]] = "quantum.X"(%[[VAL_21]]) : (!quantum.qubit<1>) -> !quantum.qubit<1>
// CHECK-NEXT:             %[[VAL_25:.*]], %[[VAL_26:.*]] = "quantum.CNOT"(%[[VAL_23]], %[[VAL_24]]) : (!quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[CONSTANT_3:.*]] = arith.constant dense<false> : tensor<3xi1>
// CHECK-NEXT:             %[[VAL_27:.*]], %[[VAL_28:.*]] = "quantum.measure"(%[[VAL_25]]) : (!quantum.qubit<1>) -> (!quantum.measurement<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[VAL_29:.*]] = "qpu.to_bits"(%[[VAL_27]]) : (!quantum.measurement<1>) -> tensor<1xi1>
// CHECK-NEXT:             %[[INSERT_SLICE_0:.*]] = tensor.insert_slice %[[VAL_29]] into %[[CONSTANT_3]][0] [1] [1] : tensor<1xi1> into tensor<3xi1>
// CHECK-NEXT:             %[[VAL_30:.*]], %[[VAL_31:.*]] = "quantum.measure"(%[[VAL_26]]) : (!quantum.qubit<1>) -> (!quantum.measurement<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[VAL_32:.*]] = "qpu.to_bits"(%[[VAL_30]]) : (!quantum.measurement<1>) -> tensor<1xi1>
// CHECK-NEXT:             %[[INSERT_SLICE_1:.*]] = tensor.insert_slice %[[VAL_32]] into %[[INSERT_SLICE_0]][1] [1] [1] : tensor<1xi1> into tensor<3xi1>
// CHECK-NEXT:             %[[VAL_33:.*]], %[[VAL_34:.*]] = "quantum.measure"(%[[VAL_22]]) : (!quantum.qubit<1>) -> (!quantum.measurement<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[VAL_35:.*]] = "qpu.to_bits"(%[[VAL_33]]) : (!quantum.measurement<1>) -> tensor<1xi1>
// CHECK-NEXT:             %[[INSERT_SLICE_2:.*]] = tensor.insert_slice %[[VAL_35]] into %[[INSERT_SLICE_1]][2] [1] [1] : tensor<1xi1> into tensor<3xi1>
// CHECK-DAG:             "quantum.deallocate"(%[[VAL_28]]) : (!quantum.qubit<1>) -> ()
// CHECK-DAG:             "quantum.deallocate"(%[[VAL_31]]) : (!quantum.qubit<1>) -> ()
// CHECK-DAG:             "quantum.deallocate"(%[[VAL_34]]) : (!quantum.qubit<1>) -> ()
// CHECK-NEXT:             "qpu.return"(%[[INSERT_SLICE_2]]) : (tensor<3xi1>) -> ()
// CHECK-NEXT:           }) : () -> ()
// CHECK-NEXT:         }
// CHECK-NEXT:         func.func @qasm_main() -> tensor<3xi1> {
// CHECK-NEXT:           %[[EMPTY_0:.*]] = tensor.empty() : tensor<3xi1>
// CHECK-NEXT:           %[[EXECUTE_0:.*]] = qpu.execute @"W-state"::@main ins () outs (%[[EMPTY_0]] : tensor<3xi1>)
// CHECK-NEXT:           return %[[EXECUTE_0]] : tensor<3xi1>
// CHECK-NEXT:         }
// CHECK-NEXT:       }
