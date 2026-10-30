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
// CHECK-NEXT:             %[[CONSTANT_1:.*]] = arith.constant dense<[true, false]> : tensor<2xi1>
// CHECK-NEXT:             %[[CMPI_0:.*]] = arith.cmpi eq, %[[INSERT_SLICE_1]], %[[CONSTANT_1]] : tensor<2xi1>
// CHECK-NEXT:             %[[CONSTANT_2:.*]] = arith.constant 0 : index
// CHECK-NEXT:             %[[CONSTANT_3:.*]] = arith.constant 2 : index
// CHECK-NEXT:             %[[CONSTANT_4:.*]] = arith.constant 1 : index
// CHECK-NEXT:             %[[CONSTANT_5:.*]] = arith.constant true
// CHECK-NEXT:             %[[PARALLEL_0:.*]] = scf.parallel (%[[VAL_27:.*]]) = (%[[CONSTANT_2]]) to (%[[CONSTANT_3]]) step (%[[CONSTANT_4]]) init (%[[CONSTANT_5]]) -> i1 {
// CHECK-NEXT:               %[[EXTRACT_0:.*]] = tensor.extract %[[CMPI_0]]{{\[}}%[[VAL_27]]] : tensor<2xi1>
// CHECK-NEXT:               scf.reduce(%[[EXTRACT_0]] : i1) {
// CHECK-NEXT:               ^bb0(%[[VAL_28:.*]]: i1, %[[VAL_29:.*]]: i1):
// CHECK-NEXT:                 %[[ANDI_0:.*]] = arith.andi %[[VAL_28]], %[[VAL_29]] : i1
// CHECK-NEXT:                 scf.reduce.return %[[ANDI_0]] : i1
// CHECK-NEXT:               }
// CHECK-NEXT:             }
// CHECK-NEXT:             %[[IF_0:.*]]:3 = scf.if %[[PARALLEL_0]] -> (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>) {
// CHECK-NEXT:               %[[VAL_30:.*]] = "quantum.X"(%[[VAL_20]]#0) : (!quantum.qubit<1>) -> !quantum.qubit<1>
// CHECK-NEXT:               scf.yield %[[VAL_30]], %[[VAL_20]]#1, %[[VAL_20]]#2 : !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>
// CHECK-NEXT:             } else {
// CHECK-NEXT:               scf.yield %[[VAL_20]]#0, %[[VAL_20]]#1, %[[VAL_20]]#2 : !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>
// CHECK-NEXT:             }
// CHECK-NEXT:             %[[CONSTANT_6:.*]] = arith.constant dense<[false, true]> : tensor<2xi1>
// CHECK-NEXT:             %[[CMPI_1:.*]] = arith.cmpi eq, %[[INSERT_SLICE_1]], %[[CONSTANT_6]] : tensor<2xi1>
// CHECK-NEXT:             %[[CONSTANT_7:.*]] = arith.constant 0 : index
// CHECK-NEXT:             %[[CONSTANT_8:.*]] = arith.constant 2 : index
// CHECK-NEXT:             %[[CONSTANT_9:.*]] = arith.constant 1 : index
// CHECK-NEXT:             %[[CONSTANT_10:.*]] = arith.constant true
// CHECK-NEXT:             %[[PARALLEL_1:.*]] = scf.parallel (%[[VAL_31:.*]]) = (%[[CONSTANT_7]]) to (%[[CONSTANT_8]]) step (%[[CONSTANT_9]]) init (%[[CONSTANT_10]]) -> i1 {
// CHECK-NEXT:               %[[EXTRACT_1:.*]] = tensor.extract %[[CMPI_1]]{{\[}}%[[VAL_31]]] : tensor<2xi1>
// CHECK-NEXT:               scf.reduce(%[[EXTRACT_1]] : i1) {
// CHECK-NEXT:               ^bb0(%[[VAL_32:.*]]: i1, %[[VAL_33:.*]]: i1):
// CHECK-NEXT:                 %[[ANDI_1:.*]] = arith.andi %[[VAL_32]], %[[VAL_33]] : i1
// CHECK-NEXT:                 scf.reduce.return %[[ANDI_1]] : i1
// CHECK-NEXT:               }
// CHECK-NEXT:             }
// CHECK-NEXT:             %[[IF_1:.*]]:3 = scf.if %[[PARALLEL_1]] -> (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>) {
// CHECK-NEXT:               %[[VAL_34:.*]] = "quantum.X"(%[[VAL_35:.*]]#2) : (!quantum.qubit<1>) -> !quantum.qubit<1>
// CHECK-NEXT:               scf.yield %[[VAL_35]]#0, %[[VAL_35]]#1, %[[VAL_34]] : !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>
// CHECK-NEXT:             } else {
// CHECK-NEXT:               scf.yield %[[VAL_36:.*]]#0, %[[VAL_36]]#1, %[[VAL_36]]#2 : !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>
// CHECK-NEXT:             }
// CHECK-NEXT:             %[[CONSTANT_11:.*]] = arith.constant dense<true> : tensor<2xi1>
// CHECK-NEXT:             %[[CMPI_2:.*]] = arith.cmpi eq, %[[INSERT_SLICE_1]], %[[CONSTANT_11]] : tensor<2xi1>
// CHECK-NEXT:             %[[CONSTANT_12:.*]] = arith.constant 0 : index
// CHECK-NEXT:             %[[CONSTANT_13:.*]] = arith.constant 2 : index
// CHECK-NEXT:             %[[CONSTANT_14:.*]] = arith.constant 1 : index
// CHECK-NEXT:             %[[CONSTANT_15:.*]] = arith.constant true
// CHECK-NEXT:             %[[PARALLEL_2:.*]] = scf.parallel (%[[VAL_37:.*]]) = (%[[CONSTANT_12]]) to (%[[CONSTANT_13]]) step (%[[CONSTANT_14]]) init (%[[CONSTANT_15]]) -> i1 {
// CHECK-NEXT:               %[[EXTRACT_2:.*]] = tensor.extract %[[CMPI_2]]{{\[}}%[[VAL_37]]] : tensor<2xi1>
// CHECK-NEXT:               scf.reduce(%[[EXTRACT_2]] : i1) {
// CHECK-NEXT:               ^bb0(%[[VAL_38:.*]]: i1, %[[VAL_39:.*]]: i1):
// CHECK-NEXT:                 %[[ANDI_2:.*]] = arith.andi %[[VAL_38]], %[[VAL_39]] : i1
// CHECK-NEXT:                 scf.reduce.return %[[ANDI_2]] : i1
// CHECK-NEXT:               }
// CHECK-NEXT:             }
// CHECK-NEXT:             %[[IF_2:.*]]:3 = scf.if %[[PARALLEL_2]] -> (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>) {
// CHECK-NEXT:               %[[VAL_40:.*]] = "quantum.X"(%[[VAL_41:.*]]#1) : (!quantum.qubit<1>) -> !quantum.qubit<1>
// CHECK-NEXT:               scf.yield %[[VAL_41]]#0, %[[VAL_40]], %[[VAL_41]]#2 : !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>
// CHECK-NEXT:             } else {
// CHECK-NEXT:               scf.yield %[[VAL_42:.*]]#0, %[[VAL_42]]#1, %[[VAL_42]]#2 : !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>
// CHECK-NEXT:             }
// CHECK-NEXT:             %[[CONSTANT_16:.*]] = arith.constant dense<false> : tensor<3xi1>
// CHECK-NEXT:             %[[VAL_43:.*]], %[[VAL_44:.*]] = "quantum.measure"(%[[VAL_45:.*]]#0) : (!quantum.qubit<1>) -> (!quantum.measurement<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[VAL_46:.*]] = "qpu.to_bits"(%[[VAL_43]]) : (!quantum.measurement<1>) -> tensor<1xi1>
// CHECK-NEXT:             %[[INSERT_SLICE_2:.*]] = tensor.insert_slice %[[VAL_46]] into %[[CONSTANT_16]][0] [1] [1] : tensor<1xi1> into tensor<3xi1>
// CHECK-NEXT:             %[[VAL_47:.*]], %[[VAL_48:.*]] = "quantum.measure"(%[[VAL_45]]#1) : (!quantum.qubit<1>) -> (!quantum.measurement<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[VAL_49:.*]] = "qpu.to_bits"(%[[VAL_47]]) : (!quantum.measurement<1>) -> tensor<1xi1>
// CHECK-NEXT:             %[[INSERT_SLICE_3:.*]] = tensor.insert_slice %[[VAL_49]] into %[[INSERT_SLICE_2]][1] [1] [1] : tensor<1xi1> into tensor<3xi1>
// CHECK-NEXT:             %[[VAL_50:.*]], %[[VAL_51:.*]] = "quantum.measure"(%[[VAL_45]]#2) : (!quantum.qubit<1>) -> (!quantum.measurement<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[VAL_52:.*]] = "qpu.to_bits"(%[[VAL_50]]) : (!quantum.measurement<1>) -> tensor<1xi1>
// CHECK-NEXT:             %[[INSERT_SLICE_4:.*]] = tensor.insert_slice %[[VAL_52]] into %[[INSERT_SLICE_3]][2] [1] [1] : tensor<1xi1> into tensor<3xi1>
// CHECK-DAG:             "quantum.deallocate"(%[[VAL_44]]) : (!quantum.qubit<1>) -> ()
// CHECK-DAG:             "quantum.deallocate"(%[[VAL_48]]) : (!quantum.qubit<1>) -> ()
// CHECK-DAG:             "quantum.deallocate"(%[[VAL_51]]) : (!quantum.qubit<1>) -> ()
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
