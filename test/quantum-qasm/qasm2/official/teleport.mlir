// RUN: quantum-qasm %S/Inputs/teleport.qasm | FileCheck %s

// The unmodified upstream source and provenance are in Inputs/ and README.md.
// Check typed operations, parameters, register slices and SSA flow through
// gates, barriers, measurements, classical conditions and circuit results.

// CHECK-LABEL: module {
// CHECK-NEXT:         qpu.module @teleport {
// CHECK-NEXT:           "quantum.gate"() <{function_type = (!quantum.qubit<1>) -> !quantum.qubit<1>, sym_name = "post"}> ({
// CHECK-NEXT:           ^bb0(%[[VAL_0:.*]]: !quantum.qubit<1>):
// CHECK-NEXT:             "quantum.return"(%[[VAL_0]]) : (!quantum.qubit<1>) -> ()
// CHECK-NEXT:           }) : () -> ()
// CHECK-NEXT:           "qpu.circuit"() <{function_type = () -> (tensor<1xi1>, tensor<1xi1>, tensor<1xi1>), sym_name = "main"}> ({
// CHECK-NEXT:             %[[VAL_1:.*]] = "quantum.alloc"() : () -> !quantum.qubit<3>
// CHECK-NEXT:             %[[VAL_2:.*]]:2 = "quantum.split"(%[[VAL_1]]) : (!quantum.qubit<3>) -> (!quantum.qubit<1>, !quantum.qubit<2>)
// CHECK-NEXT:             %[[CONSTANT_0:.*]] = arith.constant 3.000000e-01 : f64
// CHECK-NEXT:             %[[CONSTANT_1:.*]] = arith.constant 2.000000e-01 : f64
// CHECK-NEXT:             %[[CONSTANT_2:.*]] = arith.constant 1.000000e-01 : f64
// CHECK-NEXT:             %[[VAL_3:.*]] = "quantum.U3"(%[[VAL_2]]#0, %[[CONSTANT_0]], %[[CONSTANT_1]], %[[CONSTANT_2]]) : (!quantum.qubit<1>, f64, f64, f64) -> !quantum.qubit<1>
// CHECK-NEXT:             %[[VAL_4:.*]]:2 = "quantum.split"(%[[VAL_2]]#1) : (!quantum.qubit<2>) -> (!quantum.qubit<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[VAL_5:.*]] = "quantum.H"(%[[VAL_4]]#0) : (!quantum.qubit<1>) -> !quantum.qubit<1>
// CHECK-NEXT:             %[[VAL_6:.*]], %[[VAL_7:.*]] = "quantum.CNOT"(%[[VAL_5]], %[[VAL_4]]#1) : (!quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[VAL_8:.*]]:3 = "quantum.barrier"(%[[VAL_3]], %[[VAL_6]], %[[VAL_7]]) : (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[VAL_9:.*]], %[[VAL_10:.*]] = "quantum.CNOT"(%[[VAL_8]]#0, %[[VAL_8]]#1) : (!quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[VAL_11:.*]] = "quantum.H"(%[[VAL_9]]) : (!quantum.qubit<1>) -> !quantum.qubit<1>
// CHECK-NEXT:             %[[CONSTANT_3:.*]] = arith.constant dense<false> : tensor<1xi1>
// CHECK-NEXT:             %[[VAL_12:.*]], %[[VAL_13:.*]] = "quantum.measure"(%[[VAL_11]]) : (!quantum.qubit<1>) -> (!quantum.measurement<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[VAL_14:.*]] = "qpu.to_bits"(%[[VAL_12]]) : (!quantum.measurement<1>) -> tensor<1xi1>
// CHECK-NEXT:             %[[INSERT_SLICE_0:.*]] = tensor.insert_slice %[[VAL_14]] into %[[CONSTANT_3]][0] [1] [1] : tensor<1xi1> into tensor<1xi1>
// CHECK-NEXT:             %[[CONSTANT_4:.*]] = arith.constant dense<false> : tensor<1xi1>
// CHECK-NEXT:             %[[VAL_15:.*]], %[[VAL_16:.*]] = "quantum.measure"(%[[VAL_10]]) : (!quantum.qubit<1>) -> (!quantum.measurement<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[VAL_17:.*]] = "qpu.to_bits"(%[[VAL_15]]) : (!quantum.measurement<1>) -> tensor<1xi1>
// CHECK-NEXT:             %[[INSERT_SLICE_1:.*]] = tensor.insert_slice %[[VAL_17]] into %[[CONSTANT_4]][0] [1] [1] : tensor<1xi1> into tensor<1xi1>
// CHECK-NEXT:             %[[CONSTANT_5:.*]] = arith.constant dense<true> : tensor<1xi1>
// CHECK-NEXT:             %[[CMPI_0:.*]] = arith.cmpi eq, %[[INSERT_SLICE_0]], %[[CONSTANT_5]] : tensor<1xi1>
// CHECK-NEXT:             %[[CONSTANT_6:.*]] = arith.constant 0 : index
// CHECK-NEXT:             %[[EXTRACT_0:.*]] = tensor.extract %[[CMPI_0]]{{\[}}%[[CONSTANT_6]]] : tensor<1xi1>
// CHECK-NEXT:             %[[IF_0:.*]]:3 = scf.if %[[EXTRACT_0]] -> (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>) {
// CHECK-NEXT:               %[[VAL_18:.*]] = "quantum.Z"(%[[VAL_8]]#2) : (!quantum.qubit<1>) -> !quantum.qubit<1>
// CHECK-NEXT:               scf.yield %[[VAL_13]], %[[VAL_16]], %[[VAL_18]] : !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>
// CHECK-NEXT:             } else {
// CHECK-NEXT:               scf.yield %[[VAL_13]], %[[VAL_16]], %[[VAL_8]]#2 : !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>
// CHECK-NEXT:             }
// CHECK-NEXT:             %[[CONSTANT_7:.*]] = arith.constant dense<true> : tensor<1xi1>
// CHECK-NEXT:             %[[CMPI_1:.*]] = arith.cmpi eq, %[[INSERT_SLICE_1]], %[[CONSTANT_7]] : tensor<1xi1>
// CHECK-NEXT:             %[[CONSTANT_8:.*]] = arith.constant 0 : index
// CHECK-NEXT:             %[[EXTRACT_1:.*]] = tensor.extract %[[CMPI_1]]{{\[}}%[[CONSTANT_8]]] : tensor<1xi1>
// CHECK-NEXT:             %[[IF_1:.*]]:3 = scf.if %[[EXTRACT_1]] -> (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>) {
// CHECK-NEXT:               %[[VAL_19:.*]] = "quantum.X"(%[[VAL_20:.*]]#2) : (!quantum.qubit<1>) -> !quantum.qubit<1>
// CHECK-NEXT:               scf.yield %[[VAL_20]]#0, %[[VAL_20]]#1, %[[VAL_19]] : !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>
// CHECK-NEXT:             } else {
// CHECK-NEXT:               scf.yield %[[VAL_21:.*]]#0, %[[VAL_21]]#1, %[[VAL_21]]#2 : !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>
// CHECK-NEXT:             }
// CHECK-NEXT:             %[[VAL_22:.*]] = "quantum.call"(%[[VAL_23:.*]]#2) <{callee = @post}> : (!quantum.qubit<1>) -> !quantum.qubit<1>
// CHECK-NEXT:             %[[CONSTANT_9:.*]] = arith.constant dense<false> : tensor<1xi1>
// CHECK-NEXT:             %[[VAL_24:.*]], %[[VAL_25:.*]] = "quantum.measure"(%[[VAL_22]]) : (!quantum.qubit<1>) -> (!quantum.measurement<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[VAL_26:.*]] = "qpu.to_bits"(%[[VAL_24]]) : (!quantum.measurement<1>) -> tensor<1xi1>
// CHECK-NEXT:             %[[INSERT_SLICE_2:.*]] = tensor.insert_slice %[[VAL_26]] into %[[CONSTANT_9]][0] [1] [1] : tensor<1xi1> into tensor<1xi1>
// CHECK-DAG:             "quantum.deallocate"(%[[VAL_23]]#0) : (!quantum.qubit<1>) -> ()
// CHECK-DAG:             "quantum.deallocate"(%[[VAL_23]]#1) : (!quantum.qubit<1>) -> ()
// CHECK-DAG:             "quantum.deallocate"(%[[VAL_25]]) : (!quantum.qubit<1>) -> ()
// CHECK-NEXT:             "qpu.return"(%[[INSERT_SLICE_1]], %[[INSERT_SLICE_2]], %[[INSERT_SLICE_0]]) : (tensor<1xi1>, tensor<1xi1>, tensor<1xi1>) -> ()
// CHECK-NEXT:           }) : () -> ()
// CHECK-NEXT:         }
// CHECK-NEXT:         func.func @qasm_main() -> (tensor<1xi1>, tensor<1xi1>, tensor<1xi1>) {
// CHECK-NEXT:           %[[EMPTY_0:.*]] = tensor.empty() : tensor<1xi1>
// CHECK-NEXT:           %[[EMPTY_1:.*]] = tensor.empty() : tensor<1xi1>
// CHECK-NEXT:           %[[EMPTY_2:.*]] = tensor.empty() : tensor<1xi1>
// CHECK-NEXT:           %[[EXECUTE_0:.*]]:3 = qpu.execute @teleport::@main ins () outs (%[[EMPTY_0]] : tensor<1xi1>, %[[EMPTY_1]] : tensor<1xi1>, %[[EMPTY_2]] : tensor<1xi1>)
// CHECK-NEXT:           return %[[EXECUTE_0]]#0, %[[EXECUTE_0]]#1, %[[EXECUTE_0]]#2 : tensor<1xi1>, tensor<1xi1>, tensor<1xi1>
// CHECK-NEXT:         }
// CHECK-NEXT:       }
