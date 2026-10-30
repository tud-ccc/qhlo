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
// CHECK-NEXT:             %[[CONSTANT_1:.*]] = arith.constant dense<[true, false, false, false]> : tensor<4xi1>
// CHECK-NEXT:             %[[CMPI_0:.*]] = arith.cmpi eq, %[[INSERT_SLICE_0]], %[[CONSTANT_1]] : tensor<4xi1>
// CHECK-NEXT:             %[[CONSTANT_2:.*]] = arith.constant 0 : index
// CHECK-NEXT:             %[[CONSTANT_3:.*]] = arith.constant 4 : index
// CHECK-NEXT:             %[[CONSTANT_4:.*]] = arith.constant 1 : index
// CHECK-NEXT:             %[[CONSTANT_5:.*]] = arith.constant true
// CHECK-NEXT:             %[[PARALLEL_0:.*]] = scf.parallel (%[[VAL_8:.*]]) = (%[[CONSTANT_2]]) to (%[[CONSTANT_3]]) step (%[[CONSTANT_4]]) init (%[[CONSTANT_5]]) -> i1 {
// CHECK-NEXT:               %[[EXTRACT_0:.*]] = tensor.extract %[[CMPI_0]]{{\[}}%[[VAL_8]]] : tensor<4xi1>
// CHECK-NEXT:               scf.reduce(%[[EXTRACT_0]] : i1) {
// CHECK-NEXT:               ^bb0(%[[VAL_9:.*]]: i1, %[[VAL_10:.*]]: i1):
// CHECK-NEXT:                 %[[ANDI_0:.*]] = arith.andi %[[VAL_9]], %[[VAL_10]] : i1
// CHECK-NEXT:                 scf.reduce.return %[[ANDI_0]] : i1
// CHECK-NEXT:               }
// CHECK-NEXT:             }
// CHECK-NEXT:             %[[VAL_11:.*]]:2 = "quantum.split"(%[[VAL_3]]#1) : (!quantum.qubit<3>) -> (!quantum.qubit<1>, !quantum.qubit<2>)
// CHECK-NEXT:             %[[IF_0:.*]]:3 = scf.if %[[PARALLEL_0]] -> (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<2>) {
// CHECK-NEXT:               %[[CONSTANT_6:.*]] = arith.constant 3.1415926535897931 : f64
// CHECK-NEXT:               %[[CONSTANT_7:.*]] = arith.constant 2.000000e+00 : f64
// CHECK-NEXT:               %[[DIVF_0:.*]] = arith.divf %[[CONSTANT_6]], %[[CONSTANT_7]] : f64
// CHECK-NEXT:               %[[VAL_12:.*]] = "quantum.U1"(%[[VAL_11]]#0, %[[DIVF_0]]) : (!quantum.qubit<1>, f64) -> !quantum.qubit<1>
// CHECK-NEXT:               scf.yield %[[VAL_6]], %[[VAL_12]], %[[VAL_11]]#1 : !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<2>
// CHECK-NEXT:             } else {
// CHECK-NEXT:               scf.yield %[[VAL_6]], %[[VAL_11]]#0, %[[VAL_11]]#1 : !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<2>
// CHECK-NEXT:             }
// CHECK-NEXT:             %[[VAL_13:.*]] = "quantum.H"(%[[VAL_14:.*]]#1) : (!quantum.qubit<1>) -> !quantum.qubit<1>
// CHECK-NEXT:             %[[VAL_15:.*]], %[[VAL_16:.*]] = "quantum.measure"(%[[VAL_13]]) : (!quantum.qubit<1>) -> (!quantum.measurement<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[VAL_17:.*]] = "qpu.to_bits"(%[[VAL_15]]) : (!quantum.measurement<1>) -> tensor<1xi1>
// CHECK-NEXT:             %[[INSERT_SLICE_1:.*]] = tensor.insert_slice %[[VAL_17]] into %[[INSERT_SLICE_0]][1] [1] [1] : tensor<1xi1> into tensor<4xi1>
// CHECK-NEXT:             %[[CONSTANT_8:.*]] = arith.constant dense<[true, false, false, false]> : tensor<4xi1>
// CHECK-NEXT:             %[[CMPI_1:.*]] = arith.cmpi eq, %[[INSERT_SLICE_1]], %[[CONSTANT_8]] : tensor<4xi1>
// CHECK-NEXT:             %[[CONSTANT_9:.*]] = arith.constant 0 : index
// CHECK-NEXT:             %[[CONSTANT_10:.*]] = arith.constant 4 : index
// CHECK-NEXT:             %[[CONSTANT_11:.*]] = arith.constant 1 : index
// CHECK-NEXT:             %[[CONSTANT_12:.*]] = arith.constant true
// CHECK-NEXT:             %[[PARALLEL_1:.*]] = scf.parallel (%[[VAL_18:.*]]) = (%[[CONSTANT_9]]) to (%[[CONSTANT_10]]) step (%[[CONSTANT_11]]) init (%[[CONSTANT_12]]) -> i1 {
// CHECK-NEXT:               %[[EXTRACT_1:.*]] = tensor.extract %[[CMPI_1]]{{\[}}%[[VAL_18]]] : tensor<4xi1>
// CHECK-NEXT:               scf.reduce(%[[EXTRACT_1]] : i1) {
// CHECK-NEXT:               ^bb0(%[[VAL_19:.*]]: i1, %[[VAL_20:.*]]: i1):
// CHECK-NEXT:                 %[[ANDI_1:.*]] = arith.andi %[[VAL_19]], %[[VAL_20]] : i1
// CHECK-NEXT:                 scf.reduce.return %[[ANDI_1]] : i1
// CHECK-NEXT:               }
// CHECK-NEXT:             }
// CHECK-NEXT:             %[[VAL_21:.*]]:2 = "quantum.split"(%[[VAL_14]]#2) : (!quantum.qubit<2>) -> (!quantum.qubit<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[IF_1:.*]]:4 = scf.if %[[PARALLEL_1]] -> (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>) {
// CHECK-NEXT:               %[[CONSTANT_13:.*]] = arith.constant 3.1415926535897931 : f64
// CHECK-NEXT:               %[[CONSTANT_14:.*]] = arith.constant 4.000000e+00 : f64
// CHECK-NEXT:               %[[DIVF_1:.*]] = arith.divf %[[CONSTANT_13]], %[[CONSTANT_14]] : f64
// CHECK-NEXT:               %[[VAL_22:.*]] = "quantum.U1"(%[[VAL_21]]#0, %[[DIVF_1]]) : (!quantum.qubit<1>, f64) -> !quantum.qubit<1>
// CHECK-NEXT:               scf.yield %[[VAL_14]]#0, %[[VAL_16]], %[[VAL_22]], %[[VAL_21]]#1 : !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>
// CHECK-NEXT:             } else {
// CHECK-NEXT:               scf.yield %[[VAL_14]]#0, %[[VAL_16]], %[[VAL_21]]#0, %[[VAL_21]]#1 : !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>
// CHECK-NEXT:             }
// CHECK-NEXT:             %[[CONSTANT_15:.*]] = arith.constant dense<[false, true, false, false]> : tensor<4xi1>
// CHECK-NEXT:             %[[CMPI_2:.*]] = arith.cmpi eq, %[[INSERT_SLICE_1]], %[[CONSTANT_15]] : tensor<4xi1>
// CHECK-NEXT:             %[[CONSTANT_16:.*]] = arith.constant 0 : index
// CHECK-NEXT:             %[[CONSTANT_17:.*]] = arith.constant 4 : index
// CHECK-NEXT:             %[[CONSTANT_18:.*]] = arith.constant 1 : index
// CHECK-NEXT:             %[[CONSTANT_19:.*]] = arith.constant true
// CHECK-NEXT:             %[[PARALLEL_2:.*]] = scf.parallel (%[[VAL_23:.*]]) = (%[[CONSTANT_16]]) to (%[[CONSTANT_17]]) step (%[[CONSTANT_18]]) init (%[[CONSTANT_19]]) -> i1 {
// CHECK-NEXT:               %[[EXTRACT_2:.*]] = tensor.extract %[[CMPI_2]]{{\[}}%[[VAL_23]]] : tensor<4xi1>
// CHECK-NEXT:               scf.reduce(%[[EXTRACT_2]] : i1) {
// CHECK-NEXT:               ^bb0(%[[VAL_24:.*]]: i1, %[[VAL_25:.*]]: i1):
// CHECK-NEXT:                 %[[ANDI_2:.*]] = arith.andi %[[VAL_24]], %[[VAL_25]] : i1
// CHECK-NEXT:                 scf.reduce.return %[[ANDI_2]] : i1
// CHECK-NEXT:               }
// CHECK-NEXT:             }
// CHECK-NEXT:             %[[IF_2:.*]]:4 = scf.if %[[PARALLEL_2]] -> (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>) {
// CHECK-NEXT:               %[[CONSTANT_20:.*]] = arith.constant 3.1415926535897931 : f64
// CHECK-NEXT:               %[[CONSTANT_21:.*]] = arith.constant 2.000000e+00 : f64
// CHECK-NEXT:               %[[DIVF_2:.*]] = arith.divf %[[CONSTANT_20]], %[[CONSTANT_21]] : f64
// CHECK-NEXT:               %[[VAL_26:.*]] = "quantum.U1"(%[[VAL_27:.*]]#2, %[[DIVF_2]]) : (!quantum.qubit<1>, f64) -> !quantum.qubit<1>
// CHECK-NEXT:               scf.yield %[[VAL_27]]#0, %[[VAL_27]]#1, %[[VAL_26]], %[[VAL_27]]#3 : !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>
// CHECK-NEXT:             } else {
// CHECK-NEXT:               scf.yield %[[VAL_28:.*]]#0, %[[VAL_28]]#1, %[[VAL_28]]#2, %[[VAL_28]]#3 : !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>
// CHECK-NEXT:             }
// CHECK-NEXT:             %[[CONSTANT_22:.*]] = arith.constant dense<[true, true, false, false]> : tensor<4xi1>
// CHECK-NEXT:             %[[CMPI_3:.*]] = arith.cmpi eq, %[[INSERT_SLICE_1]], %[[CONSTANT_22]] : tensor<4xi1>
// CHECK-NEXT:             %[[CONSTANT_23:.*]] = arith.constant 0 : index
// CHECK-NEXT:             %[[CONSTANT_24:.*]] = arith.constant 4 : index
// CHECK-NEXT:             %[[CONSTANT_25:.*]] = arith.constant 1 : index
// CHECK-NEXT:             %[[CONSTANT_26:.*]] = arith.constant true
// CHECK-NEXT:             %[[PARALLEL_3:.*]] = scf.parallel (%[[VAL_29:.*]]) = (%[[CONSTANT_23]]) to (%[[CONSTANT_24]]) step (%[[CONSTANT_25]]) init (%[[CONSTANT_26]]) -> i1 {
// CHECK-NEXT:               %[[EXTRACT_3:.*]] = tensor.extract %[[CMPI_3]]{{\[}}%[[VAL_29]]] : tensor<4xi1>
// CHECK-NEXT:               scf.reduce(%[[EXTRACT_3]] : i1) {
// CHECK-NEXT:               ^bb0(%[[VAL_30:.*]]: i1, %[[VAL_31:.*]]: i1):
// CHECK-NEXT:                 %[[ANDI_3:.*]] = arith.andi %[[VAL_30]], %[[VAL_31]] : i1
// CHECK-NEXT:                 scf.reduce.return %[[ANDI_3]] : i1
// CHECK-NEXT:               }
// CHECK-NEXT:             }
// CHECK-NEXT:             %[[IF_3:.*]]:4 = scf.if %[[PARALLEL_3]] -> (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>) {
// CHECK-NEXT:               %[[CONSTANT_27:.*]] = arith.constant 3.1415926535897931 : f64
// CHECK-NEXT:               %[[CONSTANT_28:.*]] = arith.constant 2.000000e+00 : f64
// CHECK-NEXT:               %[[DIVF_3:.*]] = arith.divf %[[CONSTANT_27]], %[[CONSTANT_28]] : f64
// CHECK-NEXT:               %[[CONSTANT_29:.*]] = arith.constant 3.1415926535897931 : f64
// CHECK-NEXT:               %[[CONSTANT_30:.*]] = arith.constant 4.000000e+00 : f64
// CHECK-NEXT:               %[[DIVF_4:.*]] = arith.divf %[[CONSTANT_29]], %[[CONSTANT_30]] : f64
// CHECK-NEXT:               %[[ADDF_0:.*]] = arith.addf %[[DIVF_3]], %[[DIVF_4]] : f64
// CHECK-NEXT:               %[[VAL_32:.*]] = "quantum.U1"(%[[VAL_33:.*]]#2, %[[ADDF_0]]) : (!quantum.qubit<1>, f64) -> !quantum.qubit<1>
// CHECK-NEXT:               scf.yield %[[VAL_33]]#0, %[[VAL_33]]#1, %[[VAL_32]], %[[VAL_33]]#3 : !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>
// CHECK-NEXT:             } else {
// CHECK-NEXT:               scf.yield %[[VAL_34:.*]]#0, %[[VAL_34]]#1, %[[VAL_34]]#2, %[[VAL_34]]#3 : !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>
// CHECK-NEXT:             }
// CHECK-NEXT:             %[[VAL_35:.*]] = "quantum.H"(%[[VAL_36:.*]]#2) : (!quantum.qubit<1>) -> !quantum.qubit<1>
// CHECK-NEXT:             %[[VAL_37:.*]], %[[VAL_38:.*]] = "quantum.measure"(%[[VAL_35]]) : (!quantum.qubit<1>) -> (!quantum.measurement<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[VAL_39:.*]] = "qpu.to_bits"(%[[VAL_37]]) : (!quantum.measurement<1>) -> tensor<1xi1>
// CHECK-NEXT:             %[[INSERT_SLICE_2:.*]] = tensor.insert_slice %[[VAL_39]] into %[[INSERT_SLICE_1]][2] [1] [1] : tensor<1xi1> into tensor<4xi1>
// CHECK-NEXT:             %[[CONSTANT_31:.*]] = arith.constant dense<[true, false, false, false]> : tensor<4xi1>
// CHECK-NEXT:             %[[CMPI_4:.*]] = arith.cmpi eq, %[[INSERT_SLICE_2]], %[[CONSTANT_31]] : tensor<4xi1>
// CHECK-NEXT:             %[[CONSTANT_32:.*]] = arith.constant 0 : index
// CHECK-NEXT:             %[[CONSTANT_33:.*]] = arith.constant 4 : index
// CHECK-NEXT:             %[[CONSTANT_34:.*]] = arith.constant 1 : index
// CHECK-NEXT:             %[[CONSTANT_35:.*]] = arith.constant true
// CHECK-NEXT:             %[[PARALLEL_4:.*]] = scf.parallel (%[[VAL_40:.*]]) = (%[[CONSTANT_32]]) to (%[[CONSTANT_33]]) step (%[[CONSTANT_34]]) init (%[[CONSTANT_35]]) -> i1 {
// CHECK-NEXT:               %[[EXTRACT_4:.*]] = tensor.extract %[[CMPI_4]]{{\[}}%[[VAL_40]]] : tensor<4xi1>
// CHECK-NEXT:               scf.reduce(%[[EXTRACT_4]] : i1) {
// CHECK-NEXT:               ^bb0(%[[VAL_41:.*]]: i1, %[[VAL_42:.*]]: i1):
// CHECK-NEXT:                 %[[ANDI_4:.*]] = arith.andi %[[VAL_41]], %[[VAL_42]] : i1
// CHECK-NEXT:                 scf.reduce.return %[[ANDI_4]] : i1
// CHECK-NEXT:               }
// CHECK-NEXT:             }
// CHECK-NEXT:             %[[IF_4:.*]]:4 = scf.if %[[PARALLEL_4]] -> (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>) {
// CHECK-NEXT:               %[[CONSTANT_36:.*]] = arith.constant 3.1415926535897931 : f64
// CHECK-NEXT:               %[[CONSTANT_37:.*]] = arith.constant 8.000000e+00 : f64
// CHECK-NEXT:               %[[DIVF_5:.*]] = arith.divf %[[CONSTANT_36]], %[[CONSTANT_37]] : f64
// CHECK-NEXT:               %[[VAL_43:.*]] = "quantum.U1"(%[[VAL_36]]#3, %[[DIVF_5]]) : (!quantum.qubit<1>, f64) -> !quantum.qubit<1>
// CHECK-NEXT:               scf.yield %[[VAL_36]]#0, %[[VAL_36]]#1, %[[VAL_38]], %[[VAL_43]] : !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>
// CHECK-NEXT:             } else {
// CHECK-NEXT:               scf.yield %[[VAL_36]]#0, %[[VAL_36]]#1, %[[VAL_38]], %[[VAL_36]]#3 : !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>
// CHECK-NEXT:             }
// CHECK-NEXT:             %[[CONSTANT_38:.*]] = arith.constant dense<[false, true, false, false]> : tensor<4xi1>
// CHECK-NEXT:             %[[CMPI_5:.*]] = arith.cmpi eq, %[[INSERT_SLICE_2]], %[[CONSTANT_38]] : tensor<4xi1>
// CHECK-NEXT:             %[[CONSTANT_39:.*]] = arith.constant 0 : index
// CHECK-NEXT:             %[[CONSTANT_40:.*]] = arith.constant 4 : index
// CHECK-NEXT:             %[[CONSTANT_41:.*]] = arith.constant 1 : index
// CHECK-NEXT:             %[[CONSTANT_42:.*]] = arith.constant true
// CHECK-NEXT:             %[[PARALLEL_5:.*]] = scf.parallel (%[[VAL_44:.*]]) = (%[[CONSTANT_39]]) to (%[[CONSTANT_40]]) step (%[[CONSTANT_41]]) init (%[[CONSTANT_42]]) -> i1 {
// CHECK-NEXT:               %[[EXTRACT_5:.*]] = tensor.extract %[[CMPI_5]]{{\[}}%[[VAL_44]]] : tensor<4xi1>
// CHECK-NEXT:               scf.reduce(%[[EXTRACT_5]] : i1) {
// CHECK-NEXT:               ^bb0(%[[VAL_45:.*]]: i1, %[[VAL_46:.*]]: i1):
// CHECK-NEXT:                 %[[ANDI_5:.*]] = arith.andi %[[VAL_45]], %[[VAL_46]] : i1
// CHECK-NEXT:                 scf.reduce.return %[[ANDI_5]] : i1
// CHECK-NEXT:               }
// CHECK-NEXT:             }
// CHECK-NEXT:             %[[IF_5:.*]]:4 = scf.if %[[PARALLEL_5]] -> (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>) {
// CHECK-NEXT:               %[[CONSTANT_43:.*]] = arith.constant 3.1415926535897931 : f64
// CHECK-NEXT:               %[[CONSTANT_44:.*]] = arith.constant 4.000000e+00 : f64
// CHECK-NEXT:               %[[DIVF_6:.*]] = arith.divf %[[CONSTANT_43]], %[[CONSTANT_44]] : f64
// CHECK-NEXT:               %[[VAL_47:.*]] = "quantum.U1"(%[[VAL_48:.*]]#3, %[[DIVF_6]]) : (!quantum.qubit<1>, f64) -> !quantum.qubit<1>
// CHECK-NEXT:               scf.yield %[[VAL_48]]#0, %[[VAL_48]]#1, %[[VAL_48]]#2, %[[VAL_47]] : !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>
// CHECK-NEXT:             } else {
// CHECK-NEXT:               scf.yield %[[VAL_49:.*]]#0, %[[VAL_49]]#1, %[[VAL_49]]#2, %[[VAL_49]]#3 : !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>
// CHECK-NEXT:             }
// CHECK-NEXT:             %[[CONSTANT_45:.*]] = arith.constant dense<[true, true, false, false]> : tensor<4xi1>
// CHECK-NEXT:             %[[CMPI_6:.*]] = arith.cmpi eq, %[[INSERT_SLICE_2]], %[[CONSTANT_45]] : tensor<4xi1>
// CHECK-NEXT:             %[[CONSTANT_46:.*]] = arith.constant 0 : index
// CHECK-NEXT:             %[[CONSTANT_47:.*]] = arith.constant 4 : index
// CHECK-NEXT:             %[[CONSTANT_48:.*]] = arith.constant 1 : index
// CHECK-NEXT:             %[[CONSTANT_49:.*]] = arith.constant true
// CHECK-NEXT:             %[[PARALLEL_6:.*]] = scf.parallel (%[[VAL_50:.*]]) = (%[[CONSTANT_46]]) to (%[[CONSTANT_47]]) step (%[[CONSTANT_48]]) init (%[[CONSTANT_49]]) -> i1 {
// CHECK-NEXT:               %[[EXTRACT_6:.*]] = tensor.extract %[[CMPI_6]]{{\[}}%[[VAL_50]]] : tensor<4xi1>
// CHECK-NEXT:               scf.reduce(%[[EXTRACT_6]] : i1) {
// CHECK-NEXT:               ^bb0(%[[VAL_51:.*]]: i1, %[[VAL_52:.*]]: i1):
// CHECK-NEXT:                 %[[ANDI_6:.*]] = arith.andi %[[VAL_51]], %[[VAL_52]] : i1
// CHECK-NEXT:                 scf.reduce.return %[[ANDI_6]] : i1
// CHECK-NEXT:               }
// CHECK-NEXT:             }
// CHECK-NEXT:             %[[IF_6:.*]]:4 = scf.if %[[PARALLEL_6]] -> (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>) {
// CHECK-NEXT:               %[[CONSTANT_50:.*]] = arith.constant 3.1415926535897931 : f64
// CHECK-NEXT:               %[[CONSTANT_51:.*]] = arith.constant 4.000000e+00 : f64
// CHECK-NEXT:               %[[DIVF_7:.*]] = arith.divf %[[CONSTANT_50]], %[[CONSTANT_51]] : f64
// CHECK-NEXT:               %[[CONSTANT_52:.*]] = arith.constant 3.1415926535897931 : f64
// CHECK-NEXT:               %[[CONSTANT_53:.*]] = arith.constant 8.000000e+00 : f64
// CHECK-NEXT:               %[[DIVF_8:.*]] = arith.divf %[[CONSTANT_52]], %[[CONSTANT_53]] : f64
// CHECK-NEXT:               %[[ADDF_1:.*]] = arith.addf %[[DIVF_7]], %[[DIVF_8]] : f64
// CHECK-NEXT:               %[[VAL_53:.*]] = "quantum.U1"(%[[VAL_54:.*]]#3, %[[ADDF_1]]) : (!quantum.qubit<1>, f64) -> !quantum.qubit<1>
// CHECK-NEXT:               scf.yield %[[VAL_54]]#0, %[[VAL_54]]#1, %[[VAL_54]]#2, %[[VAL_53]] : !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>
// CHECK-NEXT:             } else {
// CHECK-NEXT:               scf.yield %[[VAL_55:.*]]#0, %[[VAL_55]]#1, %[[VAL_55]]#2, %[[VAL_55]]#3 : !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>
// CHECK-NEXT:             }
// CHECK-NEXT:             %[[CONSTANT_54:.*]] = arith.constant dense<[false, false, true, false]> : tensor<4xi1>
// CHECK-NEXT:             %[[CMPI_7:.*]] = arith.cmpi eq, %[[INSERT_SLICE_2]], %[[CONSTANT_54]] : tensor<4xi1>
// CHECK-NEXT:             %[[CONSTANT_55:.*]] = arith.constant 0 : index
// CHECK-NEXT:             %[[CONSTANT_56:.*]] = arith.constant 4 : index
// CHECK-NEXT:             %[[CONSTANT_57:.*]] = arith.constant 1 : index
// CHECK-NEXT:             %[[CONSTANT_58:.*]] = arith.constant true
// CHECK-NEXT:             %[[PARALLEL_7:.*]] = scf.parallel (%[[VAL_56:.*]]) = (%[[CONSTANT_55]]) to (%[[CONSTANT_56]]) step (%[[CONSTANT_57]]) init (%[[CONSTANT_58]]) -> i1 {
// CHECK-NEXT:               %[[EXTRACT_7:.*]] = tensor.extract %[[CMPI_7]]{{\[}}%[[VAL_56]]] : tensor<4xi1>
// CHECK-NEXT:               scf.reduce(%[[EXTRACT_7]] : i1) {
// CHECK-NEXT:               ^bb0(%[[VAL_57:.*]]: i1, %[[VAL_58:.*]]: i1):
// CHECK-NEXT:                 %[[ANDI_7:.*]] = arith.andi %[[VAL_57]], %[[VAL_58]] : i1
// CHECK-NEXT:                 scf.reduce.return %[[ANDI_7]] : i1
// CHECK-NEXT:               }
// CHECK-NEXT:             }
// CHECK-NEXT:             %[[IF_7:.*]]:4 = scf.if %[[PARALLEL_7]] -> (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>) {
// CHECK-NEXT:               %[[CONSTANT_59:.*]] = arith.constant 3.1415926535897931 : f64
// CHECK-NEXT:               %[[CONSTANT_60:.*]] = arith.constant 2.000000e+00 : f64
// CHECK-NEXT:               %[[DIVF_9:.*]] = arith.divf %[[CONSTANT_59]], %[[CONSTANT_60]] : f64
// CHECK-NEXT:               %[[VAL_59:.*]] = "quantum.U1"(%[[VAL_60:.*]]#3, %[[DIVF_9]]) : (!quantum.qubit<1>, f64) -> !quantum.qubit<1>
// CHECK-NEXT:               scf.yield %[[VAL_60]]#0, %[[VAL_60]]#1, %[[VAL_60]]#2, %[[VAL_59]] : !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>
// CHECK-NEXT:             } else {
// CHECK-NEXT:               scf.yield %[[VAL_61:.*]]#0, %[[VAL_61]]#1, %[[VAL_61]]#2, %[[VAL_61]]#3 : !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>
// CHECK-NEXT:             }
// CHECK-NEXT:             %[[CONSTANT_61:.*]] = arith.constant dense<[true, false, true, false]> : tensor<4xi1>
// CHECK-NEXT:             %[[CMPI_8:.*]] = arith.cmpi eq, %[[INSERT_SLICE_2]], %[[CONSTANT_61]] : tensor<4xi1>
// CHECK-NEXT:             %[[CONSTANT_62:.*]] = arith.constant 0 : index
// CHECK-NEXT:             %[[CONSTANT_63:.*]] = arith.constant 4 : index
// CHECK-NEXT:             %[[CONSTANT_64:.*]] = arith.constant 1 : index
// CHECK-NEXT:             %[[CONSTANT_65:.*]] = arith.constant true
// CHECK-NEXT:             %[[PARALLEL_8:.*]] = scf.parallel (%[[VAL_62:.*]]) = (%[[CONSTANT_62]]) to (%[[CONSTANT_63]]) step (%[[CONSTANT_64]]) init (%[[CONSTANT_65]]) -> i1 {
// CHECK-NEXT:               %[[EXTRACT_8:.*]] = tensor.extract %[[CMPI_8]]{{\[}}%[[VAL_62]]] : tensor<4xi1>
// CHECK-NEXT:               scf.reduce(%[[EXTRACT_8]] : i1) {
// CHECK-NEXT:               ^bb0(%[[VAL_63:.*]]: i1, %[[VAL_64:.*]]: i1):
// CHECK-NEXT:                 %[[ANDI_8:.*]] = arith.andi %[[VAL_63]], %[[VAL_64]] : i1
// CHECK-NEXT:                 scf.reduce.return %[[ANDI_8]] : i1
// CHECK-NEXT:               }
// CHECK-NEXT:             }
// CHECK-NEXT:             %[[IF_8:.*]]:4 = scf.if %[[PARALLEL_8]] -> (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>) {
// CHECK-NEXT:               %[[CONSTANT_66:.*]] = arith.constant 3.1415926535897931 : f64
// CHECK-NEXT:               %[[CONSTANT_67:.*]] = arith.constant 2.000000e+00 : f64
// CHECK-NEXT:               %[[DIVF_10:.*]] = arith.divf %[[CONSTANT_66]], %[[CONSTANT_67]] : f64
// CHECK-NEXT:               %[[CONSTANT_68:.*]] = arith.constant 3.1415926535897931 : f64
// CHECK-NEXT:               %[[CONSTANT_69:.*]] = arith.constant 8.000000e+00 : f64
// CHECK-NEXT:               %[[DIVF_11:.*]] = arith.divf %[[CONSTANT_68]], %[[CONSTANT_69]] : f64
// CHECK-NEXT:               %[[ADDF_2:.*]] = arith.addf %[[DIVF_10]], %[[DIVF_11]] : f64
// CHECK-NEXT:               %[[VAL_65:.*]] = "quantum.U1"(%[[VAL_66:.*]]#3, %[[ADDF_2]]) : (!quantum.qubit<1>, f64) -> !quantum.qubit<1>
// CHECK-NEXT:               scf.yield %[[VAL_66]]#0, %[[VAL_66]]#1, %[[VAL_66]]#2, %[[VAL_65]] : !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>
// CHECK-NEXT:             } else {
// CHECK-NEXT:               scf.yield %[[VAL_67:.*]]#0, %[[VAL_67]]#1, %[[VAL_67]]#2, %[[VAL_67]]#3 : !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>
// CHECK-NEXT:             }
// CHECK-NEXT:             %[[CONSTANT_70:.*]] = arith.constant dense<[false, true, true, false]> : tensor<4xi1>
// CHECK-NEXT:             %[[CMPI_9:.*]] = arith.cmpi eq, %[[INSERT_SLICE_2]], %[[CONSTANT_70]] : tensor<4xi1>
// CHECK-NEXT:             %[[CONSTANT_71:.*]] = arith.constant 0 : index
// CHECK-NEXT:             %[[CONSTANT_72:.*]] = arith.constant 4 : index
// CHECK-NEXT:             %[[CONSTANT_73:.*]] = arith.constant 1 : index
// CHECK-NEXT:             %[[CONSTANT_74:.*]] = arith.constant true
// CHECK-NEXT:             %[[PARALLEL_9:.*]] = scf.parallel (%[[VAL_68:.*]]) = (%[[CONSTANT_71]]) to (%[[CONSTANT_72]]) step (%[[CONSTANT_73]]) init (%[[CONSTANT_74]]) -> i1 {
// CHECK-NEXT:               %[[EXTRACT_9:.*]] = tensor.extract %[[CMPI_9]]{{\[}}%[[VAL_68]]] : tensor<4xi1>
// CHECK-NEXT:               scf.reduce(%[[EXTRACT_9]] : i1) {
// CHECK-NEXT:               ^bb0(%[[VAL_69:.*]]: i1, %[[VAL_70:.*]]: i1):
// CHECK-NEXT:                 %[[ANDI_9:.*]] = arith.andi %[[VAL_69]], %[[VAL_70]] : i1
// CHECK-NEXT:                 scf.reduce.return %[[ANDI_9]] : i1
// CHECK-NEXT:               }
// CHECK-NEXT:             }
// CHECK-NEXT:             %[[IF_9:.*]]:4 = scf.if %[[PARALLEL_9]] -> (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>) {
// CHECK-NEXT:               %[[CONSTANT_75:.*]] = arith.constant 3.1415926535897931 : f64
// CHECK-NEXT:               %[[CONSTANT_76:.*]] = arith.constant 2.000000e+00 : f64
// CHECK-NEXT:               %[[DIVF_12:.*]] = arith.divf %[[CONSTANT_75]], %[[CONSTANT_76]] : f64
// CHECK-NEXT:               %[[CONSTANT_77:.*]] = arith.constant 3.1415926535897931 : f64
// CHECK-NEXT:               %[[CONSTANT_78:.*]] = arith.constant 4.000000e+00 : f64
// CHECK-NEXT:               %[[DIVF_13:.*]] = arith.divf %[[CONSTANT_77]], %[[CONSTANT_78]] : f64
// CHECK-NEXT:               %[[ADDF_3:.*]] = arith.addf %[[DIVF_12]], %[[DIVF_13]] : f64
// CHECK-NEXT:               %[[VAL_71:.*]] = "quantum.U1"(%[[VAL_72:.*]]#3, %[[ADDF_3]]) : (!quantum.qubit<1>, f64) -> !quantum.qubit<1>
// CHECK-NEXT:               scf.yield %[[VAL_72]]#0, %[[VAL_72]]#1, %[[VAL_72]]#2, %[[VAL_71]] : !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>
// CHECK-NEXT:             } else {
// CHECK-NEXT:               scf.yield %[[VAL_73:.*]]#0, %[[VAL_73]]#1, %[[VAL_73]]#2, %[[VAL_73]]#3 : !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>
// CHECK-NEXT:             }
// CHECK-NEXT:             %[[CONSTANT_79:.*]] = arith.constant dense<[true, true, true, false]> : tensor<4xi1>
// CHECK-NEXT:             %[[CMPI_10:.*]] = arith.cmpi eq, %[[INSERT_SLICE_2]], %[[CONSTANT_79]] : tensor<4xi1>
// CHECK-NEXT:             %[[CONSTANT_80:.*]] = arith.constant 0 : index
// CHECK-NEXT:             %[[CONSTANT_81:.*]] = arith.constant 4 : index
// CHECK-NEXT:             %[[CONSTANT_82:.*]] = arith.constant 1 : index
// CHECK-NEXT:             %[[CONSTANT_83:.*]] = arith.constant true
// CHECK-NEXT:             %[[PARALLEL_10:.*]] = scf.parallel (%[[VAL_74:.*]]) = (%[[CONSTANT_80]]) to (%[[CONSTANT_81]]) step (%[[CONSTANT_82]]) init (%[[CONSTANT_83]]) -> i1 {
// CHECK-NEXT:               %[[EXTRACT_10:.*]] = tensor.extract %[[CMPI_10]]{{\[}}%[[VAL_74]]] : tensor<4xi1>
// CHECK-NEXT:               scf.reduce(%[[EXTRACT_10]] : i1) {
// CHECK-NEXT:               ^bb0(%[[VAL_75:.*]]: i1, %[[VAL_76:.*]]: i1):
// CHECK-NEXT:                 %[[ANDI_10:.*]] = arith.andi %[[VAL_75]], %[[VAL_76]] : i1
// CHECK-NEXT:                 scf.reduce.return %[[ANDI_10]] : i1
// CHECK-NEXT:               }
// CHECK-NEXT:             }
// CHECK-NEXT:             %[[IF_10:.*]]:4 = scf.if %[[PARALLEL_10]] -> (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>) {
// CHECK-NEXT:               %[[CONSTANT_84:.*]] = arith.constant 3.1415926535897931 : f64
// CHECK-NEXT:               %[[CONSTANT_85:.*]] = arith.constant 2.000000e+00 : f64
// CHECK-NEXT:               %[[DIVF_14:.*]] = arith.divf %[[CONSTANT_84]], %[[CONSTANT_85]] : f64
// CHECK-NEXT:               %[[CONSTANT_86:.*]] = arith.constant 3.1415926535897931 : f64
// CHECK-NEXT:               %[[CONSTANT_87:.*]] = arith.constant 4.000000e+00 : f64
// CHECK-NEXT:               %[[DIVF_15:.*]] = arith.divf %[[CONSTANT_86]], %[[CONSTANT_87]] : f64
// CHECK-NEXT:               %[[ADDF_4:.*]] = arith.addf %[[DIVF_14]], %[[DIVF_15]] : f64
// CHECK-NEXT:               %[[CONSTANT_88:.*]] = arith.constant 3.1415926535897931 : f64
// CHECK-NEXT:               %[[CONSTANT_89:.*]] = arith.constant 8.000000e+00 : f64
// CHECK-NEXT:               %[[DIVF_16:.*]] = arith.divf %[[CONSTANT_88]], %[[CONSTANT_89]] : f64
// CHECK-NEXT:               %[[ADDF_5:.*]] = arith.addf %[[ADDF_4]], %[[DIVF_16]] : f64
// CHECK-NEXT:               %[[VAL_77:.*]] = "quantum.U1"(%[[VAL_78:.*]]#3, %[[ADDF_5]]) : (!quantum.qubit<1>, f64) -> !quantum.qubit<1>
// CHECK-NEXT:               scf.yield %[[VAL_78]]#0, %[[VAL_78]]#1, %[[VAL_78]]#2, %[[VAL_77]] : !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>
// CHECK-NEXT:             } else {
// CHECK-NEXT:               scf.yield %[[VAL_79:.*]]#0, %[[VAL_79]]#1, %[[VAL_79]]#2, %[[VAL_79]]#3 : !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>
// CHECK-NEXT:             }
// CHECK-NEXT:             %[[VAL_80:.*]] = "quantum.H"(%[[VAL_81:.*]]#3) : (!quantum.qubit<1>) -> !quantum.qubit<1>
// CHECK-NEXT:             %[[VAL_82:.*]], %[[VAL_83:.*]] = "quantum.measure"(%[[VAL_80]]) : (!quantum.qubit<1>) -> (!quantum.measurement<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[VAL_84:.*]] = "qpu.to_bits"(%[[VAL_82]]) : (!quantum.measurement<1>) -> tensor<1xi1>
// CHECK-NEXT:             %[[INSERT_SLICE_3:.*]] = tensor.insert_slice %[[VAL_84]] into %[[INSERT_SLICE_2]][3] [1] [1] : tensor<1xi1> into tensor<4xi1>
// CHECK-DAG:             "quantum.deallocate"(%[[VAL_81]]#0) : (!quantum.qubit<1>) -> ()
// CHECK-DAG:             "quantum.deallocate"(%[[VAL_81]]#1) : (!quantum.qubit<1>) -> ()
// CHECK-DAG:             "quantum.deallocate"(%[[VAL_81]]#2) : (!quantum.qubit<1>) -> ()
// CHECK-DAG:             "quantum.deallocate"(%[[VAL_83]]) : (!quantum.qubit<1>) -> ()
// CHECK-NEXT:             "qpu.return"(%[[INSERT_SLICE_3]]) : (tensor<4xi1>) -> ()
// CHECK-NEXT:           }) : () -> ()
// CHECK-NEXT:         }
// CHECK-NEXT:         func.func @qasm_main() -> tensor<4xi1> {
// CHECK-NEXT:           %[[EMPTY_0:.*]] = tensor.empty() : tensor<4xi1>
// CHECK-NEXT:           %[[EXECUTE_0:.*]] = qpu.execute @inverseqft1::@main ins () outs (%[[EMPTY_0]] : tensor<4xi1>)
// CHECK-NEXT:           return %[[EXECUTE_0]] : tensor<4xi1>
// CHECK-NEXT:         }
// CHECK-NEXT:       }
