// RUN: quantum-qasm %S/Inputs/teleportv2.qasm | FileCheck %s

// The unmodified upstream source and provenance are in Inputs/ and README.md.
// Check typed operations, parameters, register slices and SSA flow through
// gates, barriers, measurements, classical conditions and circuit results.

// CHECK-LABEL: module {
// CHECK-NEXT:         qpu.module @teleportv2 {
// CHECK-NEXT:           "quantum.gate"() <{function_type = (!quantum.qubit<1>) -> !quantum.qubit<1>, sym_name = "post"}> ({
// CHECK-NEXT:           ^bb0(%[[VAL_0:.*]]: !quantum.qubit<1>):
// CHECK-NEXT:             "quantum.return"(%[[VAL_0]]) : (!quantum.qubit<1>) -> ()
// CHECK-NEXT:           }) : () -> ()
// CHECK-NEXT:           "qpu.circuit"() <{function_type = () -> tensor<3xi1>, sym_name = "main"}> ({
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
// CHECK-NEXT:             %[[CONSTANT_3:.*]] = arith.constant dense<false> : tensor<3xi1>
// CHECK-NEXT:             %[[VAL_12:.*]], %[[VAL_13:.*]] = "quantum.measure"(%[[VAL_11]]) : (!quantum.qubit<1>) -> (!quantum.measurement<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[VAL_14:.*]] = "qpu.to_bits"(%[[VAL_12]]) : (!quantum.measurement<1>) -> tensor<1xi1>
// CHECK-NEXT:             %[[INSERT_SLICE_0:.*]] = tensor.insert_slice %[[VAL_14]] into %[[CONSTANT_3]][0] [1] [1] : tensor<1xi1> into tensor<3xi1>
// CHECK-NEXT:             %[[VAL_15:.*]], %[[VAL_16:.*]] = "quantum.measure"(%[[VAL_10]]) : (!quantum.qubit<1>) -> (!quantum.measurement<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[VAL_17:.*]] = "qpu.to_bits"(%[[VAL_15]]) : (!quantum.measurement<1>) -> tensor<1xi1>
// CHECK-NEXT:             %[[INSERT_SLICE_1:.*]] = tensor.insert_slice %[[VAL_17]] into %[[INSERT_SLICE_0]][1] [1] [1] : tensor<1xi1> into tensor<3xi1>
// CHECK-NEXT:             %[[CONSTANT_4:.*]] = arith.constant dense<[true, false, false]> : tensor<3xi1>
// CHECK-NEXT:             %[[CMPI_0:.*]] = arith.cmpi eq, %[[INSERT_SLICE_1]], %[[CONSTANT_4]] : tensor<3xi1>
// CHECK-NEXT:             %[[CONSTANT_5:.*]] = arith.constant 0 : index
// CHECK-NEXT:             %[[CONSTANT_6:.*]] = arith.constant 3 : index
// CHECK-NEXT:             %[[CONSTANT_7:.*]] = arith.constant 1 : index
// CHECK-NEXT:             %[[CONSTANT_8:.*]] = arith.constant true
// CHECK-NEXT:             %[[PARALLEL_0:.*]] = scf.parallel (%[[VAL_18:.*]]) = (%[[CONSTANT_5]]) to (%[[CONSTANT_6]]) step (%[[CONSTANT_7]]) init (%[[CONSTANT_8]]) -> i1 {
// CHECK-NEXT:               %[[EXTRACT_0:.*]] = tensor.extract %[[CMPI_0]]{{\[}}%[[VAL_18]]] : tensor<3xi1>
// CHECK-NEXT:               scf.reduce(%[[EXTRACT_0]] : i1) {
// CHECK-NEXT:               ^bb0(%[[VAL_19:.*]]: i1, %[[VAL_20:.*]]: i1):
// CHECK-NEXT:                 %[[ANDI_0:.*]] = arith.andi %[[VAL_19]], %[[VAL_20]] : i1
// CHECK-NEXT:                 scf.reduce.return %[[ANDI_0]] : i1
// CHECK-NEXT:               }
// CHECK-NEXT:             }
// CHECK-NEXT:             %[[IF_0:.*]]:3 = scf.if %[[PARALLEL_0]] -> (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>) {
// CHECK-NEXT:               %[[VAL_21:.*]] = "quantum.Z"(%[[VAL_8]]#2) : (!quantum.qubit<1>) -> !quantum.qubit<1>
// CHECK-NEXT:               scf.yield %[[VAL_13]], %[[VAL_16]], %[[VAL_21]] : !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>
// CHECK-NEXT:             } else {
// CHECK-NEXT:               scf.yield %[[VAL_13]], %[[VAL_16]], %[[VAL_8]]#2 : !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>
// CHECK-NEXT:             }
// CHECK-NEXT:             %[[CONSTANT_9:.*]] = arith.constant dense<[false, true, false]> : tensor<3xi1>
// CHECK-NEXT:             %[[CMPI_1:.*]] = arith.cmpi eq, %[[INSERT_SLICE_1]], %[[CONSTANT_9]] : tensor<3xi1>
// CHECK-NEXT:             %[[CONSTANT_10:.*]] = arith.constant 0 : index
// CHECK-NEXT:             %[[CONSTANT_11:.*]] = arith.constant 3 : index
// CHECK-NEXT:             %[[CONSTANT_12:.*]] = arith.constant 1 : index
// CHECK-NEXT:             %[[CONSTANT_13:.*]] = arith.constant true
// CHECK-NEXT:             %[[PARALLEL_1:.*]] = scf.parallel (%[[VAL_22:.*]]) = (%[[CONSTANT_10]]) to (%[[CONSTANT_11]]) step (%[[CONSTANT_12]]) init (%[[CONSTANT_13]]) -> i1 {
// CHECK-NEXT:               %[[EXTRACT_1:.*]] = tensor.extract %[[CMPI_1]]{{\[}}%[[VAL_22]]] : tensor<3xi1>
// CHECK-NEXT:               scf.reduce(%[[EXTRACT_1]] : i1) {
// CHECK-NEXT:               ^bb0(%[[VAL_23:.*]]: i1, %[[VAL_24:.*]]: i1):
// CHECK-NEXT:                 %[[ANDI_1:.*]] = arith.andi %[[VAL_23]], %[[VAL_24]] : i1
// CHECK-NEXT:                 scf.reduce.return %[[ANDI_1]] : i1
// CHECK-NEXT:               }
// CHECK-NEXT:             }
// CHECK-NEXT:             %[[IF_1:.*]]:3 = scf.if %[[PARALLEL_1]] -> (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>) {
// CHECK-NEXT:               %[[VAL_25:.*]] = "quantum.X"(%[[VAL_26:.*]]#2) : (!quantum.qubit<1>) -> !quantum.qubit<1>
// CHECK-NEXT:               scf.yield %[[VAL_26]]#0, %[[VAL_26]]#1, %[[VAL_25]] : !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>
// CHECK-NEXT:             } else {
// CHECK-NEXT:               scf.yield %[[VAL_27:.*]]#0, %[[VAL_27]]#1, %[[VAL_27]]#2 : !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>
// CHECK-NEXT:             }
// CHECK-NEXT:             %[[CONSTANT_14:.*]] = arith.constant dense<[true, true, false]> : tensor<3xi1>
// CHECK-NEXT:             %[[CMPI_2:.*]] = arith.cmpi eq, %[[INSERT_SLICE_1]], %[[CONSTANT_14]] : tensor<3xi1>
// CHECK-NEXT:             %[[CONSTANT_15:.*]] = arith.constant 0 : index
// CHECK-NEXT:             %[[CONSTANT_16:.*]] = arith.constant 3 : index
// CHECK-NEXT:             %[[CONSTANT_17:.*]] = arith.constant 1 : index
// CHECK-NEXT:             %[[CONSTANT_18:.*]] = arith.constant true
// CHECK-NEXT:             %[[PARALLEL_2:.*]] = scf.parallel (%[[VAL_28:.*]]) = (%[[CONSTANT_15]]) to (%[[CONSTANT_16]]) step (%[[CONSTANT_17]]) init (%[[CONSTANT_18]]) -> i1 {
// CHECK-NEXT:               %[[EXTRACT_2:.*]] = tensor.extract %[[CMPI_2]]{{\[}}%[[VAL_28]]] : tensor<3xi1>
// CHECK-NEXT:               scf.reduce(%[[EXTRACT_2]] : i1) {
// CHECK-NEXT:               ^bb0(%[[VAL_29:.*]]: i1, %[[VAL_30:.*]]: i1):
// CHECK-NEXT:                 %[[ANDI_2:.*]] = arith.andi %[[VAL_29]], %[[VAL_30]] : i1
// CHECK-NEXT:                 scf.reduce.return %[[ANDI_2]] : i1
// CHECK-NEXT:               }
// CHECK-NEXT:             }
// CHECK-NEXT:             %[[IF_2:.*]]:3 = scf.if %[[PARALLEL_2]] -> (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>) {
// CHECK-NEXT:               %[[VAL_31:.*]] = "quantum.Y"(%[[VAL_32:.*]]#2) : (!quantum.qubit<1>) -> !quantum.qubit<1>
// CHECK-NEXT:               scf.yield %[[VAL_32]]#0, %[[VAL_32]]#1, %[[VAL_31]] : !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>
// CHECK-NEXT:             } else {
// CHECK-NEXT:               scf.yield %[[VAL_33:.*]]#0, %[[VAL_33]]#1, %[[VAL_33]]#2 : !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>
// CHECK-NEXT:             }
// CHECK-NEXT:             %[[VAL_34:.*]] = "quantum.call"(%[[VAL_35:.*]]#2) <{callee = @post}> : (!quantum.qubit<1>) -> !quantum.qubit<1>
// CHECK-NEXT:             %[[VAL_36:.*]], %[[VAL_37:.*]] = "quantum.measure"(%[[VAL_34]]) : (!quantum.qubit<1>) -> (!quantum.measurement<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[VAL_38:.*]] = "qpu.to_bits"(%[[VAL_36]]) : (!quantum.measurement<1>) -> tensor<1xi1>
// CHECK-NEXT:             %[[INSERT_SLICE_2:.*]] = tensor.insert_slice %[[VAL_38]] into %[[INSERT_SLICE_1]][2] [1] [1] : tensor<1xi1> into tensor<3xi1>
// CHECK-DAG:             "quantum.deallocate"(%[[VAL_35]]#0) : (!quantum.qubit<1>) -> ()
// CHECK-DAG:             "quantum.deallocate"(%[[VAL_35]]#1) : (!quantum.qubit<1>) -> ()
// CHECK-DAG:             "quantum.deallocate"(%[[VAL_37]]) : (!quantum.qubit<1>) -> ()
// CHECK-NEXT:             "qpu.return"(%[[INSERT_SLICE_2]]) : (tensor<3xi1>) -> ()
// CHECK-NEXT:           }) : () -> ()
// CHECK-NEXT:         }
// CHECK-NEXT:         func.func @qasm_main() -> tensor<3xi1> {
// CHECK-NEXT:           %[[EMPTY_0:.*]] = tensor.empty() : tensor<3xi1>
// CHECK-NEXT:           %[[EXECUTE_0:.*]] = qpu.execute @teleportv2::@main ins () outs (%[[EMPTY_0]] : tensor<3xi1>)
// CHECK-NEXT:           return %[[EXECUTE_0]] : tensor<3xi1>
// CHECK-NEXT:         }
// CHECK-NEXT:       }
