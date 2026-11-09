// RUN: quantum-qasm %S/Inputs/inverseqft1.qasm | FileCheck %s

// The unmodified upstream source and provenance are in Inputs/ and README.md.
// Check typed operations, parameters, register slices and SSA flow through
// gates, barriers, measurements, classical conditions and circuit results.

// CHECK-LABEL: module {
// CHECK-NEXT:         qpu.module @inverseqft1 {
// CHECK-NEXT:           "qpu.circuit"() <{function_type = () -> tensor<4xi1>, sym_name = "main"}> ({
// CHECK-NEXT:             %[[VAL_0:.*]] = "quantum.alloc"() : () -> !quantum.qubit<4>
// CHECK-NEXT:             %[[VAL_1:.*]] = "quantum.H"(%[[VAL_0]]) : (!quantum.qubit<4>) -> !quantum.qubit<4>
// CHECK-NEXT:             %[[VAL_2:.*]] = "quantum.barrier"(%[[VAL_1]]) : (!quantum.qubit<4>) -> !quantum.qubit<4>
// CHECK-NEXT:             %[[VAL_3:.*]]:2 = "quantum.split"(%[[VAL_2]]) : (!quantum.qubit<4>) -> (!quantum.qubit<1>, !quantum.qubit<3>)
// CHECK-NEXT:             %[[VAL_4:.*]] = "quantum.H"(%[[VAL_3]]#0) : (!quantum.qubit<1>) -> !quantum.qubit<1>
// CHECK-NEXT:             %[[CONSTANT_0:.*]] = arith.constant dense<false> : tensor<4xi1>
// CHECK-NEXT:             %[[VAL_5:.*]], %[[VAL_6:.*]] = "quantum.measure"(%[[VAL_4]]) : (!quantum.qubit<1>) -> (!quantum.measurement<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[VAL_7:.*]] = "qpu.to_bits"(%[[VAL_5]]) : (!quantum.measurement<1>) -> tensor<1xi1>
// CHECK-NEXT:             %[[INSERT_SLICE_0:.*]] = tensor.insert_slice %[[VAL_7]] into %[[CONSTANT_0]][0] [1] [1] : tensor<1xi1> into tensor<4xi1>
// CHECK-NEXT:             %[[CONSTANT_1:.*]] = arith.constant 1 : i4
// CHECK-NEXT:             %[[VAL_8:.*]] = "qpu.bits_eq"(%[[INSERT_SLICE_0]], %[[CONSTANT_1]]) : (tensor<4xi1>, i4) -> i1
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
// CHECK-NEXT:             %[[VAL_12:.*]], %[[VAL_13:.*]] = "quantum.measure"(%[[VAL_11]]) : (!quantum.qubit<1>) -> (!quantum.measurement<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[VAL_14:.*]] = "qpu.to_bits"(%[[VAL_12]]) : (!quantum.measurement<1>) -> tensor<1xi1>
// CHECK-NEXT:             %[[INSERT_SLICE_1:.*]] = tensor.insert_slice %[[VAL_14]] into %[[INSERT_SLICE_0]][1] [1] [1] : tensor<1xi1> into tensor<4xi1>
// CHECK-NEXT:             %[[CONSTANT_4:.*]] = arith.constant 1 : i4
// CHECK-NEXT:             %[[VAL_15:.*]] = "qpu.bits_eq"(%[[INSERT_SLICE_1]], %[[CONSTANT_4]]) : (tensor<4xi1>, i4) -> i1
// CHECK-NEXT:             %[[VAL_16:.*]]:2 = "quantum.split"(%[[VAL_9]]#1) : (!quantum.qubit<2>) -> (!quantum.qubit<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[IF_1:.*]] = scf.if %[[VAL_15]] -> (!quantum.qubit<1>) {
// CHECK-NEXT:               %[[CONSTANT_5:.*]] = arith.constant 3.1415926535897931 : f64
// CHECK-NEXT:               %[[CONSTANT_6:.*]] = arith.constant 4.000000e+00 : f64
// CHECK-NEXT:               %[[DIVF_1:.*]] = arith.divf %[[CONSTANT_5]], %[[CONSTANT_6]] : f64
// CHECK-NEXT:               %[[VAL_17:.*]] = "quantum.U1"(%[[VAL_16]]#0, %[[DIVF_1]]) : (!quantum.qubit<1>, f64) -> !quantum.qubit<1>
// CHECK-NEXT:               scf.yield %[[VAL_17]] : !quantum.qubit<1>
// CHECK-NEXT:             } else {
// CHECK-NEXT:               scf.yield %[[VAL_16]]#0 : !quantum.qubit<1>
// CHECK-NEXT:             }
// CHECK-NEXT:             %[[CONSTANT_7:.*]] = arith.constant 2 : i4
// CHECK-NEXT:             %[[VAL_18:.*]] = "qpu.bits_eq"(%[[INSERT_SLICE_1]], %[[CONSTANT_7]]) : (tensor<4xi1>, i4) -> i1
// CHECK-NEXT:             %[[IF_2:.*]] = scf.if %[[VAL_18]] -> (!quantum.qubit<1>) {
// CHECK-NEXT:               %[[CONSTANT_8:.*]] = arith.constant 3.1415926535897931 : f64
// CHECK-NEXT:               %[[CONSTANT_9:.*]] = arith.constant 2.000000e+00 : f64
// CHECK-NEXT:               %[[DIVF_2:.*]] = arith.divf %[[CONSTANT_8]], %[[CONSTANT_9]] : f64
// CHECK-NEXT:               %[[VAL_19:.*]] = "quantum.U1"(%[[IF_1]], %[[DIVF_2]]) : (!quantum.qubit<1>, f64) -> !quantum.qubit<1>
// CHECK-NEXT:               scf.yield %[[VAL_19]] : !quantum.qubit<1>
// CHECK-NEXT:             } else {
// CHECK-NEXT:               scf.yield %[[IF_1]] : !quantum.qubit<1>
// CHECK-NEXT:             }
// CHECK-NEXT:             %[[CONSTANT_10:.*]] = arith.constant 3 : i4
// CHECK-NEXT:             %[[VAL_20:.*]] = "qpu.bits_eq"(%[[INSERT_SLICE_1]], %[[CONSTANT_10]]) : (tensor<4xi1>, i4) -> i1
// CHECK-NEXT:             %[[IF_3:.*]] = scf.if %[[VAL_20]] -> (!quantum.qubit<1>) {
// CHECK-NEXT:               %[[CONSTANT_11:.*]] = arith.constant 3.1415926535897931 : f64
// CHECK-NEXT:               %[[CONSTANT_12:.*]] = arith.constant 2.000000e+00 : f64
// CHECK-NEXT:               %[[DIVF_3:.*]] = arith.divf %[[CONSTANT_11]], %[[CONSTANT_12]] : f64
// CHECK-NEXT:               %[[CONSTANT_13:.*]] = arith.constant 3.1415926535897931 : f64
// CHECK-NEXT:               %[[CONSTANT_14:.*]] = arith.constant 4.000000e+00 : f64
// CHECK-NEXT:               %[[DIVF_4:.*]] = arith.divf %[[CONSTANT_13]], %[[CONSTANT_14]] : f64
// CHECK-NEXT:               %[[ADDF_0:.*]] = arith.addf %[[DIVF_3]], %[[DIVF_4]] : f64
// CHECK-NEXT:               %[[VAL_21:.*]] = "quantum.U1"(%[[IF_2]], %[[ADDF_0]]) : (!quantum.qubit<1>, f64) -> !quantum.qubit<1>
// CHECK-NEXT:               scf.yield %[[VAL_21]] : !quantum.qubit<1>
// CHECK-NEXT:             } else {
// CHECK-NEXT:               scf.yield %[[IF_2]] : !quantum.qubit<1>
// CHECK-NEXT:             }
// CHECK-NEXT:             %[[VAL_22:.*]] = "quantum.H"(%[[IF_3]]) : (!quantum.qubit<1>) -> !quantum.qubit<1>
// CHECK-NEXT:             %[[VAL_23:.*]], %[[VAL_24:.*]] = "quantum.measure"(%[[VAL_22]]) : (!quantum.qubit<1>) -> (!quantum.measurement<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[VAL_25:.*]] = "qpu.to_bits"(%[[VAL_23]]) : (!quantum.measurement<1>) -> tensor<1xi1>
// CHECK-NEXT:             %[[INSERT_SLICE_2:.*]] = tensor.insert_slice %[[VAL_25]] into %[[INSERT_SLICE_1]][2] [1] [1] : tensor<1xi1> into tensor<4xi1>
// CHECK-NEXT:             %[[CONSTANT_15:.*]] = arith.constant 1 : i4
// CHECK-NEXT:             %[[VAL_26:.*]] = "qpu.bits_eq"(%[[INSERT_SLICE_2]], %[[CONSTANT_15]]) : (tensor<4xi1>, i4) -> i1
// CHECK-NEXT:             %[[IF_4:.*]] = scf.if %[[VAL_26]] -> (!quantum.qubit<1>) {
// CHECK-NEXT:               %[[CONSTANT_16:.*]] = arith.constant 3.1415926535897931 : f64
// CHECK-NEXT:               %[[CONSTANT_17:.*]] = arith.constant 8.000000e+00 : f64
// CHECK-NEXT:               %[[DIVF_5:.*]] = arith.divf %[[CONSTANT_16]], %[[CONSTANT_17]] : f64
// CHECK-NEXT:               %[[VAL_27:.*]] = "quantum.U1"(%[[VAL_16]]#1, %[[DIVF_5]]) : (!quantum.qubit<1>, f64) -> !quantum.qubit<1>
// CHECK-NEXT:               scf.yield %[[VAL_27]] : !quantum.qubit<1>
// CHECK-NEXT:             } else {
// CHECK-NEXT:               scf.yield %[[VAL_16]]#1 : !quantum.qubit<1>
// CHECK-NEXT:             }
// CHECK-NEXT:             %[[CONSTANT_18:.*]] = arith.constant 2 : i4
// CHECK-NEXT:             %[[VAL_28:.*]] = "qpu.bits_eq"(%[[INSERT_SLICE_2]], %[[CONSTANT_18]]) : (tensor<4xi1>, i4) -> i1
// CHECK-NEXT:             %[[IF_5:.*]] = scf.if %[[VAL_28]] -> (!quantum.qubit<1>) {
// CHECK-NEXT:               %[[CONSTANT_19:.*]] = arith.constant 3.1415926535897931 : f64
// CHECK-NEXT:               %[[CONSTANT_20:.*]] = arith.constant 4.000000e+00 : f64
// CHECK-NEXT:               %[[DIVF_6:.*]] = arith.divf %[[CONSTANT_19]], %[[CONSTANT_20]] : f64
// CHECK-NEXT:               %[[VAL_29:.*]] = "quantum.U1"(%[[IF_4]], %[[DIVF_6]]) : (!quantum.qubit<1>, f64) -> !quantum.qubit<1>
// CHECK-NEXT:               scf.yield %[[VAL_29]] : !quantum.qubit<1>
// CHECK-NEXT:             } else {
// CHECK-NEXT:               scf.yield %[[IF_4]] : !quantum.qubit<1>
// CHECK-NEXT:             }
// CHECK-NEXT:             %[[CONSTANT_21:.*]] = arith.constant 3 : i4
// CHECK-NEXT:             %[[VAL_30:.*]] = "qpu.bits_eq"(%[[INSERT_SLICE_2]], %[[CONSTANT_21]]) : (tensor<4xi1>, i4) -> i1
// CHECK-NEXT:             %[[IF_6:.*]] = scf.if %[[VAL_30]] -> (!quantum.qubit<1>) {
// CHECK-NEXT:               %[[CONSTANT_22:.*]] = arith.constant 3.1415926535897931 : f64
// CHECK-NEXT:               %[[CONSTANT_23:.*]] = arith.constant 4.000000e+00 : f64
// CHECK-NEXT:               %[[DIVF_7:.*]] = arith.divf %[[CONSTANT_22]], %[[CONSTANT_23]] : f64
// CHECK-NEXT:               %[[CONSTANT_24:.*]] = arith.constant 3.1415926535897931 : f64
// CHECK-NEXT:               %[[CONSTANT_25:.*]] = arith.constant 8.000000e+00 : f64
// CHECK-NEXT:               %[[DIVF_8:.*]] = arith.divf %[[CONSTANT_24]], %[[CONSTANT_25]] : f64
// CHECK-NEXT:               %[[ADDF_1:.*]] = arith.addf %[[DIVF_7]], %[[DIVF_8]] : f64
// CHECK-NEXT:               %[[VAL_31:.*]] = "quantum.U1"(%[[IF_5]], %[[ADDF_1]]) : (!quantum.qubit<1>, f64) -> !quantum.qubit<1>
// CHECK-NEXT:               scf.yield %[[VAL_31]] : !quantum.qubit<1>
// CHECK-NEXT:             } else {
// CHECK-NEXT:               scf.yield %[[IF_5]] : !quantum.qubit<1>
// CHECK-NEXT:             }
// CHECK-NEXT:             %[[CONSTANT_26:.*]] = arith.constant 4 : i4
// CHECK-NEXT:             %[[VAL_32:.*]] = "qpu.bits_eq"(%[[INSERT_SLICE_2]], %[[CONSTANT_26]]) : (tensor<4xi1>, i4) -> i1
// CHECK-NEXT:             %[[IF_7:.*]] = scf.if %[[VAL_32]] -> (!quantum.qubit<1>) {
// CHECK-NEXT:               %[[CONSTANT_27:.*]] = arith.constant 3.1415926535897931 : f64
// CHECK-NEXT:               %[[CONSTANT_28:.*]] = arith.constant 2.000000e+00 : f64
// CHECK-NEXT:               %[[DIVF_9:.*]] = arith.divf %[[CONSTANT_27]], %[[CONSTANT_28]] : f64
// CHECK-NEXT:               %[[VAL_33:.*]] = "quantum.U1"(%[[IF_6]], %[[DIVF_9]]) : (!quantum.qubit<1>, f64) -> !quantum.qubit<1>
// CHECK-NEXT:               scf.yield %[[VAL_33]] : !quantum.qubit<1>
// CHECK-NEXT:             } else {
// CHECK-NEXT:               scf.yield %[[IF_6]] : !quantum.qubit<1>
// CHECK-NEXT:             }
// CHECK-NEXT:             %[[CONSTANT_29:.*]] = arith.constant 5 : i4
// CHECK-NEXT:             %[[VAL_34:.*]] = "qpu.bits_eq"(%[[INSERT_SLICE_2]], %[[CONSTANT_29]]) : (tensor<4xi1>, i4) -> i1
// CHECK-NEXT:             %[[IF_8:.*]] = scf.if %[[VAL_34]] -> (!quantum.qubit<1>) {
// CHECK-NEXT:               %[[CONSTANT_30:.*]] = arith.constant 3.1415926535897931 : f64
// CHECK-NEXT:               %[[CONSTANT_31:.*]] = arith.constant 2.000000e+00 : f64
// CHECK-NEXT:               %[[DIVF_10:.*]] = arith.divf %[[CONSTANT_30]], %[[CONSTANT_31]] : f64
// CHECK-NEXT:               %[[CONSTANT_32:.*]] = arith.constant 3.1415926535897931 : f64
// CHECK-NEXT:               %[[CONSTANT_33:.*]] = arith.constant 8.000000e+00 : f64
// CHECK-NEXT:               %[[DIVF_11:.*]] = arith.divf %[[CONSTANT_32]], %[[CONSTANT_33]] : f64
// CHECK-NEXT:               %[[ADDF_2:.*]] = arith.addf %[[DIVF_10]], %[[DIVF_11]] : f64
// CHECK-NEXT:               %[[VAL_35:.*]] = "quantum.U1"(%[[IF_7]], %[[ADDF_2]]) : (!quantum.qubit<1>, f64) -> !quantum.qubit<1>
// CHECK-NEXT:               scf.yield %[[VAL_35]] : !quantum.qubit<1>
// CHECK-NEXT:             } else {
// CHECK-NEXT:               scf.yield %[[IF_7]] : !quantum.qubit<1>
// CHECK-NEXT:             }
// CHECK-NEXT:             %[[CONSTANT_34:.*]] = arith.constant 6 : i4
// CHECK-NEXT:             %[[VAL_36:.*]] = "qpu.bits_eq"(%[[INSERT_SLICE_2]], %[[CONSTANT_34]]) : (tensor<4xi1>, i4) -> i1
// CHECK-NEXT:             %[[IF_9:.*]] = scf.if %[[VAL_36]] -> (!quantum.qubit<1>) {
// CHECK-NEXT:               %[[CONSTANT_35:.*]] = arith.constant 3.1415926535897931 : f64
// CHECK-NEXT:               %[[CONSTANT_36:.*]] = arith.constant 2.000000e+00 : f64
// CHECK-NEXT:               %[[DIVF_12:.*]] = arith.divf %[[CONSTANT_35]], %[[CONSTANT_36]] : f64
// CHECK-NEXT:               %[[CONSTANT_37:.*]] = arith.constant 3.1415926535897931 : f64
// CHECK-NEXT:               %[[CONSTANT_38:.*]] = arith.constant 4.000000e+00 : f64
// CHECK-NEXT:               %[[DIVF_13:.*]] = arith.divf %[[CONSTANT_37]], %[[CONSTANT_38]] : f64
// CHECK-NEXT:               %[[ADDF_3:.*]] = arith.addf %[[DIVF_12]], %[[DIVF_13]] : f64
// CHECK-NEXT:               %[[VAL_37:.*]] = "quantum.U1"(%[[IF_8]], %[[ADDF_3]]) : (!quantum.qubit<1>, f64) -> !quantum.qubit<1>
// CHECK-NEXT:               scf.yield %[[VAL_37]] : !quantum.qubit<1>
// CHECK-NEXT:             } else {
// CHECK-NEXT:               scf.yield %[[IF_8]] : !quantum.qubit<1>
// CHECK-NEXT:             }
// CHECK-NEXT:             %[[CONSTANT_39:.*]] = arith.constant 7 : i4
// CHECK-NEXT:             %[[VAL_38:.*]] = "qpu.bits_eq"(%[[INSERT_SLICE_2]], %[[CONSTANT_39]]) : (tensor<4xi1>, i4) -> i1
// CHECK-NEXT:             %[[IF_10:.*]] = scf.if %[[VAL_38]] -> (!quantum.qubit<1>) {
// CHECK-NEXT:               %[[CONSTANT_40:.*]] = arith.constant 3.1415926535897931 : f64
// CHECK-NEXT:               %[[CONSTANT_41:.*]] = arith.constant 2.000000e+00 : f64
// CHECK-NEXT:               %[[DIVF_14:.*]] = arith.divf %[[CONSTANT_40]], %[[CONSTANT_41]] : f64
// CHECK-NEXT:               %[[CONSTANT_42:.*]] = arith.constant 3.1415926535897931 : f64
// CHECK-NEXT:               %[[CONSTANT_43:.*]] = arith.constant 4.000000e+00 : f64
// CHECK-NEXT:               %[[DIVF_15:.*]] = arith.divf %[[CONSTANT_42]], %[[CONSTANT_43]] : f64
// CHECK-NEXT:               %[[ADDF_4:.*]] = arith.addf %[[DIVF_14]], %[[DIVF_15]] : f64
// CHECK-NEXT:               %[[CONSTANT_44:.*]] = arith.constant 3.1415926535897931 : f64
// CHECK-NEXT:               %[[CONSTANT_45:.*]] = arith.constant 8.000000e+00 : f64
// CHECK-NEXT:               %[[DIVF_16:.*]] = arith.divf %[[CONSTANT_44]], %[[CONSTANT_45]] : f64
// CHECK-NEXT:               %[[ADDF_5:.*]] = arith.addf %[[ADDF_4]], %[[DIVF_16]] : f64
// CHECK-NEXT:               %[[VAL_39:.*]] = "quantum.U1"(%[[IF_9]], %[[ADDF_5]]) : (!quantum.qubit<1>, f64) -> !quantum.qubit<1>
// CHECK-NEXT:               scf.yield %[[VAL_39]] : !quantum.qubit<1>
// CHECK-NEXT:             } else {
// CHECK-NEXT:               scf.yield %[[IF_9]] : !quantum.qubit<1>
// CHECK-NEXT:             }
// CHECK-NEXT:             %[[VAL_40:.*]] = "quantum.H"(%[[IF_10]]) : (!quantum.qubit<1>) -> !quantum.qubit<1>
// CHECK-NEXT:             %[[VAL_41:.*]], %[[VAL_42:.*]] = "quantum.measure"(%[[VAL_40]]) : (!quantum.qubit<1>) -> (!quantum.measurement<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[VAL_43:.*]] = "qpu.to_bits"(%[[VAL_41]]) : (!quantum.measurement<1>) -> tensor<1xi1>
// CHECK-NEXT:             %[[INSERT_SLICE_3:.*]] = tensor.insert_slice %[[VAL_43]] into %[[INSERT_SLICE_2]][3] [1] [1] : tensor<1xi1> into tensor<4xi1>
// CHECK-DAG:             "quantum.deallocate"(%[[VAL_6]]) : (!quantum.qubit<1>) -> ()
// CHECK-DAG:             "quantum.deallocate"(%[[VAL_13]]) : (!quantum.qubit<1>) -> ()
// CHECK-DAG:             "quantum.deallocate"(%[[VAL_24]]) : (!quantum.qubit<1>) -> ()
// CHECK-DAG:             "quantum.deallocate"(%[[VAL_42]]) : (!quantum.qubit<1>) -> ()
// CHECK-NEXT:             "qpu.return"(%[[INSERT_SLICE_3]]) : (tensor<4xi1>) -> ()
// CHECK-NEXT:           }) : () -> ()
// CHECK-NEXT:         }
// CHECK-NEXT:         func.func @qasm_main() -> tensor<4xi1> {
// CHECK-NEXT:           %[[EMPTY_0:.*]] = tensor.empty() : tensor<4xi1>
// CHECK-NEXT:           %[[EXECUTE_0:.*]] = qpu.execute @inverseqft1::@main ins () outs (%[[EMPTY_0]] : tensor<4xi1>)
// CHECK-NEXT:           return %[[EXECUTE_0]] : tensor<4xi1>
// CHECK-NEXT:         }
// CHECK-NEXT:       }
