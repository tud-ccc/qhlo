// RUN: quantum-qasm %S/Inputs/qec.qasm | FileCheck %s

// The unmodified upstream source and provenance are in Inputs/ and README.md.
// Check typed operations, parameters, register slices and SSA flow through
// gates, barriers, measurements, classical conditions and circuit results.

// CHECK-LABEL: module {
// CHECK-NEXT:         qpu.module @qec {
// CHECK-NEXT:           "quantum.gate"() <{function_type = (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>), sym_name = "syndrome"}> ({
// CHECK-NEXT:           ^bb0(%[[VAL_0:.*]]: !quantum.qubit<1>, %[[VAL_1:.*]]: !quantum.qubit<1>, %[[VAL_2:.*]]: !quantum.qubit<1>, %[[VAL_3:.*]]: !quantum.qubit<1>, %[[VAL_4:.*]]: !quantum.qubit<1>):
// CHECK-NEXT:             %[[VAL_5:.*]], %[[VAL_6:.*]] = "quantum.CNOT"(%[[VAL_0]], %[[VAL_3]]) : (!quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[VAL_7:.*]], %[[VAL_8:.*]] = "quantum.CNOT"(%[[VAL_1]], %[[VAL_6]]) : (!quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[VAL_9:.*]], %[[VAL_10:.*]] = "quantum.CNOT"(%[[VAL_7]], %[[VAL_4]]) : (!quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[VAL_11:.*]], %[[VAL_12:.*]] = "quantum.CNOT"(%[[VAL_2]], %[[VAL_10]]) : (!quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>)
// CHECK-NEXT:             "quantum.return"(%[[VAL_5]], %[[VAL_9]], %[[VAL_11]], %[[VAL_8]], %[[VAL_12]]) : (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>) -> ()
// CHECK-NEXT:           }) : () -> ()
// CHECK-NEXT:           "qpu.circuit"() <{function_type = () -> (tensor<2xi1>, tensor<3xi1>), sym_name = "main"}> ({
// CHECK-NEXT:             %[[VAL_13:.*]] = "quantum.alloc"() : () -> !quantum.qubit<3>
// CHECK-NEXT:             %[[VAL_14:.*]] = "quantum.alloc"() : () -> !quantum.qubit<2>
// CHECK-NEXT:             %[[VAL_15:.*]]:2 = "quantum.split"(%[[VAL_13]]) : (!quantum.qubit<3>) -> (!quantum.qubit<1>, !quantum.qubit<2>)
// CHECK-NEXT:             %[[VAL_16:.*]] = "quantum.X"(%[[VAL_15]]#0) : (!quantum.qubit<1>) -> !quantum.qubit<1>
// CHECK-NEXT:             %[[VAL_17:.*]]:2 = "quantum.barrier"(%[[VAL_16]], %[[VAL_15]]#1) : (!quantum.qubit<1>, !quantum.qubit<2>) -> (!quantum.qubit<1>, !quantum.qubit<2>)
// CHECK-NEXT:             %[[VAL_18:.*]]:2 = "quantum.split"(%[[VAL_17]]#1) : (!quantum.qubit<2>) -> (!quantum.qubit<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[VAL_19:.*]]:2 = "quantum.split"(%[[VAL_14]]) : (!quantum.qubit<2>) -> (!quantum.qubit<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[VAL_20:.*]]:5 = "quantum.call"(%[[VAL_17]]#0, %[[VAL_18]]#0, %[[VAL_18]]#1, %[[VAL_19]]#0, %[[VAL_19]]#1) <{callee = @syndrome}> : (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[CONSTANT_0:.*]] = arith.constant dense<false> : tensor<2xi1>
// CHECK-NEXT:             %[[VAL_21:.*]], %[[VAL_22:.*]] = "quantum.measure"(%[[VAL_20]]#3) : (!quantum.qubit<1>) -> (!quantum.measurement<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[VAL_23:.*]] = "qpu.to_bits"(%[[VAL_21]]) : (!quantum.measurement<1>) -> tensor<1xi1>
// CHECK-NEXT:             %[[INSERT_SLICE_0:.*]] = tensor.insert_slice %[[VAL_23]] into %[[CONSTANT_0]][0] [1] [1] : tensor<1xi1> into tensor<2xi1>
// CHECK-NEXT:             %[[VAL_24:.*]], %[[VAL_25:.*]] = "quantum.measure"(%[[VAL_20]]#4) : (!quantum.qubit<1>) -> (!quantum.measurement<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[VAL_26:.*]] = "qpu.to_bits"(%[[VAL_24]]) : (!quantum.measurement<1>) -> tensor<1xi1>
// CHECK-NEXT:             %[[INSERT_SLICE_1:.*]] = tensor.insert_slice %[[VAL_26]] into %[[INSERT_SLICE_0]][1] [1] [1] : tensor<1xi1> into tensor<2xi1>
// CHECK-NEXT:             %[[CONSTANT_1:.*]] = arith.constant 1 : i2
// CHECK-NEXT:             %[[VAL_27:.*]] = "qpu.bits_eq"(%[[INSERT_SLICE_1]], %[[CONSTANT_1]]) : (tensor<2xi1>, i2) -> i1
// CHECK-NEXT:             %[[IF_0:.*]] = scf.if %[[VAL_27]] -> (!quantum.qubit<1>) {
// CHECK-NEXT:               %[[VAL_28:.*]] = "quantum.X"(%[[VAL_20]]#0) : (!quantum.qubit<1>) -> !quantum.qubit<1>
// CHECK-NEXT:               scf.yield %[[VAL_28]] : !quantum.qubit<1>
// CHECK-NEXT:             } else {
// CHECK-NEXT:               scf.yield %[[VAL_20]]#0 : !quantum.qubit<1>
// CHECK-NEXT:             }
// CHECK-NEXT:             %[[CONSTANT_2:.*]] = arith.constant -2 : i2
// CHECK-NEXT:             %[[VAL_29:.*]] = "qpu.bits_eq"(%[[INSERT_SLICE_1]], %[[CONSTANT_2]]) : (tensor<2xi1>, i2) -> i1
// CHECK-NEXT:             %[[IF_1:.*]] = scf.if %[[VAL_29]] -> (!quantum.qubit<1>) {
// CHECK-NEXT:               %[[VAL_30:.*]] = "quantum.X"(%[[VAL_20]]#2) : (!quantum.qubit<1>) -> !quantum.qubit<1>
// CHECK-NEXT:               scf.yield %[[VAL_30]] : !quantum.qubit<1>
// CHECK-NEXT:             } else {
// CHECK-NEXT:               scf.yield %[[VAL_20]]#2 : !quantum.qubit<1>
// CHECK-NEXT:             }
// CHECK-NEXT:             %[[CONSTANT_3:.*]] = arith.constant -1 : i2
// CHECK-NEXT:             %[[VAL_31:.*]] = "qpu.bits_eq"(%[[INSERT_SLICE_1]], %[[CONSTANT_3]]) : (tensor<2xi1>, i2) -> i1
// CHECK-NEXT:             %[[IF_2:.*]] = scf.if %[[VAL_31]] -> (!quantum.qubit<1>) {
// CHECK-NEXT:               %[[VAL_32:.*]] = "quantum.X"(%[[VAL_20]]#1) : (!quantum.qubit<1>) -> !quantum.qubit<1>
// CHECK-NEXT:               scf.yield %[[VAL_32]] : !quantum.qubit<1>
// CHECK-NEXT:             } else {
// CHECK-NEXT:               scf.yield %[[VAL_20]]#1 : !quantum.qubit<1>
// CHECK-NEXT:             }
// CHECK-NEXT:             %[[CONSTANT_4:.*]] = arith.constant dense<false> : tensor<3xi1>
// CHECK-NEXT:             %[[VAL_33:.*]], %[[VAL_34:.*]] = "quantum.measure"(%[[IF_0]]) : (!quantum.qubit<1>) -> (!quantum.measurement<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[VAL_35:.*]] = "qpu.to_bits"(%[[VAL_33]]) : (!quantum.measurement<1>) -> tensor<1xi1>
// CHECK-NEXT:             %[[INSERT_SLICE_2:.*]] = tensor.insert_slice %[[VAL_35]] into %[[CONSTANT_4]][0] [1] [1] : tensor<1xi1> into tensor<3xi1>
// CHECK-NEXT:             %[[VAL_36:.*]], %[[VAL_37:.*]] = "quantum.measure"(%[[IF_2]]) : (!quantum.qubit<1>) -> (!quantum.measurement<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[VAL_38:.*]] = "qpu.to_bits"(%[[VAL_36]]) : (!quantum.measurement<1>) -> tensor<1xi1>
// CHECK-NEXT:             %[[INSERT_SLICE_3:.*]] = tensor.insert_slice %[[VAL_38]] into %[[INSERT_SLICE_2]][1] [1] [1] : tensor<1xi1> into tensor<3xi1>
// CHECK-NEXT:             %[[VAL_39:.*]], %[[VAL_40:.*]] = "quantum.measure"(%[[IF_1]]) : (!quantum.qubit<1>) -> (!quantum.measurement<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[VAL_41:.*]] = "qpu.to_bits"(%[[VAL_39]]) : (!quantum.measurement<1>) -> tensor<1xi1>
// CHECK-NEXT:             %[[INSERT_SLICE_4:.*]] = tensor.insert_slice %[[VAL_41]] into %[[INSERT_SLICE_3]][2] [1] [1] : tensor<1xi1> into tensor<3xi1>
// CHECK-DAG:             "quantum.deallocate"(%[[VAL_34]]) : (!quantum.qubit<1>) -> ()
// CHECK-DAG:             "quantum.deallocate"(%[[VAL_37]]) : (!quantum.qubit<1>) -> ()
// CHECK-DAG:             "quantum.deallocate"(%[[VAL_40]]) : (!quantum.qubit<1>) -> ()
// CHECK-DAG:             "quantum.deallocate"(%[[VAL_22]]) : (!quantum.qubit<1>) -> ()
// CHECK-DAG:             "quantum.deallocate"(%[[VAL_25]]) : (!quantum.qubit<1>) -> ()
// CHECK-NEXT:             "qpu.return"(%[[INSERT_SLICE_1]], %[[INSERT_SLICE_4]]) : (tensor<2xi1>, tensor<3xi1>) -> ()
// CHECK-NEXT:           }) : () -> ()
// CHECK-NEXT:         }
// CHECK-NEXT:         func.func @qasm_main() -> (tensor<2xi1>, tensor<3xi1>) {
// CHECK-NEXT:           %[[EMPTY_0:.*]] = tensor.empty() : tensor<2xi1>
// CHECK-NEXT:           %[[EMPTY_1:.*]] = tensor.empty() : tensor<3xi1>
// CHECK-NEXT:           %[[EXECUTE_0:.*]]:2 = qpu.execute @qec::@main ins () outs (%[[EMPTY_0]] : tensor<2xi1>, %[[EMPTY_1]] : tensor<3xi1>)
// CHECK-NEXT:           return %[[EXECUTE_0]]#0, %[[EXECUTE_0]]#1 : tensor<2xi1>, tensor<3xi1>
// CHECK-NEXT:         }
// CHECK-NEXT:       }
