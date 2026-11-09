// RUN: quantum-qasm %S/Inputs/inverseqft2.qasm | FileCheck %s

// The unmodified upstream source and provenance are in Inputs/ and README.md.
// Check typed operations, parameters, register slices and SSA flow through
// gates, barriers, measurements, classical conditions and circuit results.

// CHECK-LABEL: module {
// CHECK-NEXT:         qpu.module @inverseqft2 {
// CHECK-NEXT:           "qpu.circuit"() <{function_type = () -> (tensor<1xi1>, tensor<1xi1>, tensor<1xi1>, tensor<1xi1>), sym_name = "main"}> ({
// CHECK-NEXT:             %[[VAL_0:.*]] = "quantum.alloc"() : () -> !quantum.qubit<4>
// CHECK-NEXT:             %[[VAL_1:.*]] = "quantum.H"(%[[VAL_0]]) : (!quantum.qubit<4>) -> !quantum.qubit<4>
// CHECK-NEXT:             %[[VAL_2:.*]] = "quantum.barrier"(%[[VAL_1]]) : (!quantum.qubit<4>) -> !quantum.qubit<4>
// CHECK-NEXT:             %[[VAL_3:.*]]:2 = "quantum.split"(%[[VAL_2]]) : (!quantum.qubit<4>) -> (!quantum.qubit<1>, !quantum.qubit<3>)
// CHECK-NEXT:             %[[VAL_4:.*]] = "quantum.H"(%[[VAL_3]]#0) : (!quantum.qubit<1>) -> !quantum.qubit<1>
// CHECK-NEXT:             %[[CONSTANT_0:.*]] = arith.constant dense<false> : tensor<1xi1>
// CHECK-NEXT:             %[[VAL_5:.*]], %[[VAL_6:.*]] = "quantum.measure"(%[[VAL_4]]) : (!quantum.qubit<1>) -> (!quantum.measurement<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[VAL_7:.*]] = "qpu.to_bits"(%[[VAL_5]]) : (!quantum.measurement<1>) -> tensor<1xi1>
// CHECK-NEXT:             %[[INSERT_SLICE_0:.*]] = tensor.insert_slice %[[VAL_7]] into %[[CONSTANT_0]][0] [1] [1] : tensor<1xi1> into tensor<1xi1>
// CHECK-NEXT:             %[[CONSTANT_1:.*]] = arith.constant true
// CHECK-NEXT:             %[[VAL_8:.*]] = "qpu.bits_eq"(%[[INSERT_SLICE_0]], %[[CONSTANT_1]]) : (tensor<1xi1>, i1) -> i1
// CHECK-NEXT:             %[[VAL_9:.*]]:2 = "quantum.split"(%[[VAL_3]]#1) : (!quantum.qubit<3>) -> (!quantum.qubit<1>, !quantum.qubit<2>)
// CHECK-NEXT:             %[[IF_0:.*]] = scf.if %[[VAL_8]] -> (!quantum.qubit<1>) {
// CHECK-NEXT:               %[[CONSTANT_2:.*]] = arith.constant 3.1415926535897931 : f64
// CHECK-NEXT:               %[[CONSTANT_3:.*]] = arith.constant 2.000000e+00 : f64
// CHECK-NEXT:               %[[DIVF_0:.*]] = arith.divf %[[CONSTANT_2]], %[[CONSTANT_3]] : f64
// CHECK-NEXT:               %[[VAL_10:.*]] = "quantum.U1"(%[[VAL_9]]#0, %[[DIVF_0]]) : (!quantum.qubit<1>, f64) -> !quantum.qubit<1>
// CHECK-NEXT:               scf.yield %[[VAL_10]] : !quantum.qubit<1>
// CHECK-NEXT:             } else {
// CHECK-NEXT:               scf.yield %[[VAL_9]]#0 : !quantum.qubit<1>
// CHECK-NEXT:             }
// CHECK-NEXT:             %[[VAL_11:.*]] = "quantum.H"(%[[IF_0]]) : (!quantum.qubit<1>) -> !quantum.qubit<1>
// CHECK-NEXT:             %[[CONSTANT_4:.*]] = arith.constant dense<false> : tensor<1xi1>
// CHECK-NEXT:             %[[VAL_12:.*]], %[[VAL_13:.*]] = "quantum.measure"(%[[VAL_11]]) : (!quantum.qubit<1>) -> (!quantum.measurement<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[VAL_14:.*]] = "qpu.to_bits"(%[[VAL_12]]) : (!quantum.measurement<1>) -> tensor<1xi1>
// CHECK-NEXT:             %[[INSERT_SLICE_1:.*]] = tensor.insert_slice %[[VAL_14]] into %[[CONSTANT_4]][0] [1] [1] : tensor<1xi1> into tensor<1xi1>
// CHECK-NEXT:             %[[CONSTANT_5:.*]] = arith.constant true
// CHECK-NEXT:             %[[VAL_15:.*]] = "qpu.bits_eq"(%[[INSERT_SLICE_0]], %[[CONSTANT_5]]) : (tensor<1xi1>, i1) -> i1
// CHECK-NEXT:             %[[VAL_16:.*]]:2 = "quantum.split"(%[[VAL_9]]#1) : (!quantum.qubit<2>) -> (!quantum.qubit<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[IF_1:.*]] = scf.if %[[VAL_15]] -> (!quantum.qubit<1>) {
// CHECK-NEXT:               %[[CONSTANT_6:.*]] = arith.constant 3.1415926535897931 : f64
// CHECK-NEXT:               %[[CONSTANT_7:.*]] = arith.constant 4.000000e+00 : f64
// CHECK-NEXT:               %[[DIVF_1:.*]] = arith.divf %[[CONSTANT_6]], %[[CONSTANT_7]] : f64
// CHECK-NEXT:               %[[VAL_17:.*]] = "quantum.U1"(%[[VAL_16]]#0, %[[DIVF_1]]) : (!quantum.qubit<1>, f64) -> !quantum.qubit<1>
// CHECK-NEXT:               scf.yield %[[VAL_17]] : !quantum.qubit<1>
// CHECK-NEXT:             } else {
// CHECK-NEXT:               scf.yield %[[VAL_16]]#0 : !quantum.qubit<1>
// CHECK-NEXT:             }
// CHECK-NEXT:             %[[CONSTANT_8:.*]] = arith.constant true
// CHECK-NEXT:             %[[VAL_18:.*]] = "qpu.bits_eq"(%[[INSERT_SLICE_1]], %[[CONSTANT_8]]) : (tensor<1xi1>, i1) -> i1
// CHECK-NEXT:             %[[IF_2:.*]] = scf.if %[[VAL_18]] -> (!quantum.qubit<1>) {
// CHECK-NEXT:               %[[CONSTANT_9:.*]] = arith.constant 3.1415926535897931 : f64
// CHECK-NEXT:               %[[CONSTANT_10:.*]] = arith.constant 2.000000e+00 : f64
// CHECK-NEXT:               %[[DIVF_2:.*]] = arith.divf %[[CONSTANT_9]], %[[CONSTANT_10]] : f64
// CHECK-NEXT:               %[[VAL_19:.*]] = "quantum.U1"(%[[IF_1]], %[[DIVF_2]]) : (!quantum.qubit<1>, f64) -> !quantum.qubit<1>
// CHECK-NEXT:               scf.yield %[[VAL_19]] : !quantum.qubit<1>
// CHECK-NEXT:             } else {
// CHECK-NEXT:               scf.yield %[[IF_1]] : !quantum.qubit<1>
// CHECK-NEXT:             }
// CHECK-NEXT:             %[[VAL_20:.*]] = "quantum.H"(%[[IF_2]]) : (!quantum.qubit<1>) -> !quantum.qubit<1>
// CHECK-NEXT:             %[[CONSTANT_11:.*]] = arith.constant dense<false> : tensor<1xi1>
// CHECK-NEXT:             %[[VAL_21:.*]], %[[VAL_22:.*]] = "quantum.measure"(%[[VAL_20]]) : (!quantum.qubit<1>) -> (!quantum.measurement<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[VAL_23:.*]] = "qpu.to_bits"(%[[VAL_21]]) : (!quantum.measurement<1>) -> tensor<1xi1>
// CHECK-NEXT:             %[[INSERT_SLICE_2:.*]] = tensor.insert_slice %[[VAL_23]] into %[[CONSTANT_11]][0] [1] [1] : tensor<1xi1> into tensor<1xi1>
// CHECK-NEXT:             %[[CONSTANT_12:.*]] = arith.constant true
// CHECK-NEXT:             %[[VAL_24:.*]] = "qpu.bits_eq"(%[[INSERT_SLICE_0]], %[[CONSTANT_12]]) : (tensor<1xi1>, i1) -> i1
// CHECK-NEXT:             %[[IF_3:.*]] = scf.if %[[VAL_24]] -> (!quantum.qubit<1>) {
// CHECK-NEXT:               %[[CONSTANT_13:.*]] = arith.constant 3.1415926535897931 : f64
// CHECK-NEXT:               %[[CONSTANT_14:.*]] = arith.constant 8.000000e+00 : f64
// CHECK-NEXT:               %[[DIVF_3:.*]] = arith.divf %[[CONSTANT_13]], %[[CONSTANT_14]] : f64
// CHECK-NEXT:               %[[VAL_25:.*]] = "quantum.U1"(%[[VAL_16]]#1, %[[DIVF_3]]) : (!quantum.qubit<1>, f64) -> !quantum.qubit<1>
// CHECK-NEXT:               scf.yield %[[VAL_25]] : !quantum.qubit<1>
// CHECK-NEXT:             } else {
// CHECK-NEXT:               scf.yield %[[VAL_16]]#1 : !quantum.qubit<1>
// CHECK-NEXT:             }
// CHECK-NEXT:             %[[CONSTANT_15:.*]] = arith.constant true
// CHECK-NEXT:             %[[VAL_26:.*]] = "qpu.bits_eq"(%[[INSERT_SLICE_1]], %[[CONSTANT_15]]) : (tensor<1xi1>, i1) -> i1
// CHECK-NEXT:             %[[IF_4:.*]] = scf.if %[[VAL_26]] -> (!quantum.qubit<1>) {
// CHECK-NEXT:               %[[CONSTANT_16:.*]] = arith.constant 3.1415926535897931 : f64
// CHECK-NEXT:               %[[CONSTANT_17:.*]] = arith.constant 4.000000e+00 : f64
// CHECK-NEXT:               %[[DIVF_4:.*]] = arith.divf %[[CONSTANT_16]], %[[CONSTANT_17]] : f64
// CHECK-NEXT:               %[[VAL_27:.*]] = "quantum.U1"(%[[IF_3]], %[[DIVF_4]]) : (!quantum.qubit<1>, f64) -> !quantum.qubit<1>
// CHECK-NEXT:               scf.yield %[[VAL_27]] : !quantum.qubit<1>
// CHECK-NEXT:             } else {
// CHECK-NEXT:               scf.yield %[[IF_3]] : !quantum.qubit<1>
// CHECK-NEXT:             }
// CHECK-NEXT:             %[[CONSTANT_18:.*]] = arith.constant true
// CHECK-NEXT:             %[[VAL_28:.*]] = "qpu.bits_eq"(%[[INSERT_SLICE_2]], %[[CONSTANT_18]]) : (tensor<1xi1>, i1) -> i1
// CHECK-NEXT:             %[[IF_5:.*]] = scf.if %[[VAL_28]] -> (!quantum.qubit<1>) {
// CHECK-NEXT:               %[[CONSTANT_19:.*]] = arith.constant 3.1415926535897931 : f64
// CHECK-NEXT:               %[[CONSTANT_20:.*]] = arith.constant 2.000000e+00 : f64
// CHECK-NEXT:               %[[DIVF_5:.*]] = arith.divf %[[CONSTANT_19]], %[[CONSTANT_20]] : f64
// CHECK-NEXT:               %[[VAL_29:.*]] = "quantum.U1"(%[[IF_4]], %[[DIVF_5]]) : (!quantum.qubit<1>, f64) -> !quantum.qubit<1>
// CHECK-NEXT:               scf.yield %[[VAL_29]] : !quantum.qubit<1>
// CHECK-NEXT:             } else {
// CHECK-NEXT:               scf.yield %[[IF_4]] : !quantum.qubit<1>
// CHECK-NEXT:             }
// CHECK-NEXT:             %[[VAL_30:.*]] = "quantum.H"(%[[IF_5]]) : (!quantum.qubit<1>) -> !quantum.qubit<1>
// CHECK-NEXT:             %[[CONSTANT_21:.*]] = arith.constant dense<false> : tensor<1xi1>
// CHECK-NEXT:             %[[VAL_31:.*]], %[[VAL_32:.*]] = "quantum.measure"(%[[VAL_30]]) : (!quantum.qubit<1>) -> (!quantum.measurement<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[VAL_33:.*]] = "qpu.to_bits"(%[[VAL_31]]) : (!quantum.measurement<1>) -> tensor<1xi1>
// CHECK-NEXT:             %[[INSERT_SLICE_3:.*]] = tensor.insert_slice %[[VAL_33]] into %[[CONSTANT_21]][0] [1] [1] : tensor<1xi1> into tensor<1xi1>
// CHECK-DAG:             "quantum.deallocate"(%[[VAL_6]]) : (!quantum.qubit<1>) -> ()
// CHECK-DAG:             "quantum.deallocate"(%[[VAL_13]]) : (!quantum.qubit<1>) -> ()
// CHECK-DAG:             "quantum.deallocate"(%[[VAL_22]]) : (!quantum.qubit<1>) -> ()
// CHECK-DAG:             "quantum.deallocate"(%[[VAL_32]]) : (!quantum.qubit<1>) -> ()
// CHECK-NEXT:             "qpu.return"(%[[INSERT_SLICE_1]], %[[INSERT_SLICE_2]], %[[INSERT_SLICE_0]], %[[INSERT_SLICE_3]]) : (tensor<1xi1>, tensor<1xi1>, tensor<1xi1>, tensor<1xi1>) -> ()
// CHECK-NEXT:           }) : () -> ()
// CHECK-NEXT:         }
// CHECK-NEXT:         func.func @qasm_main() -> (tensor<1xi1>, tensor<1xi1>, tensor<1xi1>, tensor<1xi1>) {
// CHECK-NEXT:           %[[EMPTY_0:.*]] = tensor.empty() : tensor<1xi1>
// CHECK-NEXT:           %[[EMPTY_1:.*]] = tensor.empty() : tensor<1xi1>
// CHECK-NEXT:           %[[EMPTY_2:.*]] = tensor.empty() : tensor<1xi1>
// CHECK-NEXT:           %[[EMPTY_3:.*]] = tensor.empty() : tensor<1xi1>
// CHECK-NEXT:           %[[EXECUTE_0:.*]]:4 = qpu.execute @inverseqft2::@main ins () outs (%[[EMPTY_0]] : tensor<1xi1>, %[[EMPTY_1]] : tensor<1xi1>, %[[EMPTY_2]] : tensor<1xi1>, %[[EMPTY_3]] : tensor<1xi1>)
// CHECK-NEXT:           return %[[EXECUTE_0]]#0, %[[EXECUTE_0]]#1, %[[EXECUTE_0]]#2, %[[EXECUTE_0]]#3 : tensor<1xi1>, tensor<1xi1>, tensor<1xi1>, tensor<1xi1>
// CHECK-NEXT:         }
// CHECK-NEXT:       }
