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
// CHECK-NEXT:             %[[VAL_7:.*]] = "quantum.to_tensor"(%[[VAL_5]]) : (!quantum.measurement<1>) -> tensor<1xi1>
// CHECK-NEXT:             %[[INSERT_SLICE_0:.*]] = tensor.insert_slice %[[VAL_7]] into %[[CONSTANT_0]][0] [1] [1] : tensor<1xi1> into tensor<1xi1>
// CHECK-NEXT:             %[[CONSTANT_1:.*]] = arith.constant dense<true> : tensor<1xi1>
// CHECK-NEXT:             %[[CMPI_0:.*]] = arith.cmpi eq, %[[INSERT_SLICE_0]], %[[CONSTANT_1]] : tensor<1xi1>
// CHECK-NEXT:             %[[CONSTANT_2:.*]] = arith.constant 0 : index
// CHECK-NEXT:             %[[EXTRACT_0:.*]] = tensor.extract %[[CMPI_0]]{{\[}}%[[CONSTANT_2]]] : tensor<1xi1>
// CHECK-NEXT:             %[[VAL_8:.*]]:2 = "quantum.split"(%[[VAL_3]]#1) : (!quantum.qubit<3>) -> (!quantum.qubit<1>, !quantum.qubit<2>)
// CHECK-NEXT:             %[[IF_0:.*]]:3 = scf.if %[[EXTRACT_0]] -> (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<2>) {
// CHECK-NEXT:               %[[CONSTANT_3:.*]] = arith.constant 3.1415926535897931 : f64
// CHECK-NEXT:               %[[CONSTANT_4:.*]] = arith.constant 2.000000e+00 : f64
// CHECK-NEXT:               %[[DIVF_0:.*]] = arith.divf %[[CONSTANT_3]], %[[CONSTANT_4]] : f64
// CHECK-NEXT:               %[[VAL_9:.*]] = "quantum.U1"(%[[VAL_8]]#0, %[[DIVF_0]]) : (!quantum.qubit<1>, f64) -> !quantum.qubit<1>
// CHECK-NEXT:               scf.yield %[[VAL_6]], %[[VAL_9]], %[[VAL_8]]#1 : !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<2>
// CHECK-NEXT:             } else {
// CHECK-NEXT:               scf.yield %[[VAL_6]], %[[VAL_8]]#0, %[[VAL_8]]#1 : !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<2>
// CHECK-NEXT:             }
// CHECK-NEXT:             %[[VAL_10:.*]] = "quantum.H"(%[[VAL_11:.*]]#1) : (!quantum.qubit<1>) -> !quantum.qubit<1>
// CHECK-NEXT:             %[[CONSTANT_5:.*]] = arith.constant dense<false> : tensor<1xi1>
// CHECK-NEXT:             %[[VAL_12:.*]], %[[VAL_13:.*]] = "quantum.measure"(%[[VAL_10]]) : (!quantum.qubit<1>) -> (!quantum.measurement<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[VAL_14:.*]] = "quantum.to_tensor"(%[[VAL_12]]) : (!quantum.measurement<1>) -> tensor<1xi1>
// CHECK-NEXT:             %[[INSERT_SLICE_1:.*]] = tensor.insert_slice %[[VAL_14]] into %[[CONSTANT_5]][0] [1] [1] : tensor<1xi1> into tensor<1xi1>
// CHECK-NEXT:             %[[CONSTANT_6:.*]] = arith.constant dense<true> : tensor<1xi1>
// CHECK-NEXT:             %[[CMPI_1:.*]] = arith.cmpi eq, %[[INSERT_SLICE_0]], %[[CONSTANT_6]] : tensor<1xi1>
// CHECK-NEXT:             %[[CONSTANT_7:.*]] = arith.constant 0 : index
// CHECK-NEXT:             %[[EXTRACT_1:.*]] = tensor.extract %[[CMPI_1]]{{\[}}%[[CONSTANT_7]]] : tensor<1xi1>
// CHECK-NEXT:             %[[VAL_15:.*]]:2 = "quantum.split"(%[[VAL_11]]#2) : (!quantum.qubit<2>) -> (!quantum.qubit<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[IF_1:.*]]:4 = scf.if %[[EXTRACT_1]] -> (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>) {
// CHECK-NEXT:               %[[CONSTANT_8:.*]] = arith.constant 3.1415926535897931 : f64
// CHECK-NEXT:               %[[CONSTANT_9:.*]] = arith.constant 4.000000e+00 : f64
// CHECK-NEXT:               %[[DIVF_1:.*]] = arith.divf %[[CONSTANT_8]], %[[CONSTANT_9]] : f64
// CHECK-NEXT:               %[[VAL_16:.*]] = "quantum.U1"(%[[VAL_15]]#0, %[[DIVF_1]]) : (!quantum.qubit<1>, f64) -> !quantum.qubit<1>
// CHECK-NEXT:               scf.yield %[[VAL_11]]#0, %[[VAL_13]], %[[VAL_16]], %[[VAL_15]]#1 : !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>
// CHECK-NEXT:             } else {
// CHECK-NEXT:               scf.yield %[[VAL_11]]#0, %[[VAL_13]], %[[VAL_15]]#0, %[[VAL_15]]#1 : !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>
// CHECK-NEXT:             }
// CHECK-NEXT:             %[[CONSTANT_10:.*]] = arith.constant dense<true> : tensor<1xi1>
// CHECK-NEXT:             %[[CMPI_2:.*]] = arith.cmpi eq, %[[INSERT_SLICE_1]], %[[CONSTANT_10]] : tensor<1xi1>
// CHECK-NEXT:             %[[CONSTANT_11:.*]] = arith.constant 0 : index
// CHECK-NEXT:             %[[EXTRACT_2:.*]] = tensor.extract %[[CMPI_2]]{{\[}}%[[CONSTANT_11]]] : tensor<1xi1>
// CHECK-NEXT:             %[[IF_2:.*]]:4 = scf.if %[[EXTRACT_2]] -> (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>) {
// CHECK-NEXT:               %[[CONSTANT_12:.*]] = arith.constant 3.1415926535897931 : f64
// CHECK-NEXT:               %[[CONSTANT_13:.*]] = arith.constant 2.000000e+00 : f64
// CHECK-NEXT:               %[[DIVF_2:.*]] = arith.divf %[[CONSTANT_12]], %[[CONSTANT_13]] : f64
// CHECK-NEXT:               %[[VAL_17:.*]] = "quantum.U1"(%[[VAL_18:.*]]#2, %[[DIVF_2]]) : (!quantum.qubit<1>, f64) -> !quantum.qubit<1>
// CHECK-NEXT:               scf.yield %[[VAL_18]]#0, %[[VAL_18]]#1, %[[VAL_17]], %[[VAL_18]]#3 : !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>
// CHECK-NEXT:             } else {
// CHECK-NEXT:               scf.yield %[[VAL_19:.*]]#0, %[[VAL_19]]#1, %[[VAL_19]]#2, %[[VAL_19]]#3 : !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>
// CHECK-NEXT:             }
// CHECK-NEXT:             %[[VAL_20:.*]] = "quantum.H"(%[[VAL_21:.*]]#2) : (!quantum.qubit<1>) -> !quantum.qubit<1>
// CHECK-NEXT:             %[[CONSTANT_14:.*]] = arith.constant dense<false> : tensor<1xi1>
// CHECK-NEXT:             %[[VAL_22:.*]], %[[VAL_23:.*]] = "quantum.measure"(%[[VAL_20]]) : (!quantum.qubit<1>) -> (!quantum.measurement<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[VAL_24:.*]] = "quantum.to_tensor"(%[[VAL_22]]) : (!quantum.measurement<1>) -> tensor<1xi1>
// CHECK-NEXT:             %[[INSERT_SLICE_2:.*]] = tensor.insert_slice %[[VAL_24]] into %[[CONSTANT_14]][0] [1] [1] : tensor<1xi1> into tensor<1xi1>
// CHECK-NEXT:             %[[CONSTANT_15:.*]] = arith.constant dense<true> : tensor<1xi1>
// CHECK-NEXT:             %[[CMPI_3:.*]] = arith.cmpi eq, %[[INSERT_SLICE_0]], %[[CONSTANT_15]] : tensor<1xi1>
// CHECK-NEXT:             %[[CONSTANT_16:.*]] = arith.constant 0 : index
// CHECK-NEXT:             %[[EXTRACT_3:.*]] = tensor.extract %[[CMPI_3]]{{\[}}%[[CONSTANT_16]]] : tensor<1xi1>
// CHECK-NEXT:             %[[IF_3:.*]]:4 = scf.if %[[EXTRACT_3]] -> (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>) {
// CHECK-NEXT:               %[[CONSTANT_17:.*]] = arith.constant 3.1415926535897931 : f64
// CHECK-NEXT:               %[[CONSTANT_18:.*]] = arith.constant 8.000000e+00 : f64
// CHECK-NEXT:               %[[DIVF_3:.*]] = arith.divf %[[CONSTANT_17]], %[[CONSTANT_18]] : f64
// CHECK-NEXT:               %[[VAL_25:.*]] = "quantum.U1"(%[[VAL_21]]#3, %[[DIVF_3]]) : (!quantum.qubit<1>, f64) -> !quantum.qubit<1>
// CHECK-NEXT:               scf.yield %[[VAL_21]]#0, %[[VAL_21]]#1, %[[VAL_23]], %[[VAL_25]] : !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>
// CHECK-NEXT:             } else {
// CHECK-NEXT:               scf.yield %[[VAL_21]]#0, %[[VAL_21]]#1, %[[VAL_23]], %[[VAL_21]]#3 : !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>
// CHECK-NEXT:             }
// CHECK-NEXT:             %[[CONSTANT_19:.*]] = arith.constant dense<true> : tensor<1xi1>
// CHECK-NEXT:             %[[CMPI_4:.*]] = arith.cmpi eq, %[[INSERT_SLICE_1]], %[[CONSTANT_19]] : tensor<1xi1>
// CHECK-NEXT:             %[[CONSTANT_20:.*]] = arith.constant 0 : index
// CHECK-NEXT:             %[[EXTRACT_4:.*]] = tensor.extract %[[CMPI_4]]{{\[}}%[[CONSTANT_20]]] : tensor<1xi1>
// CHECK-NEXT:             %[[IF_4:.*]]:4 = scf.if %[[EXTRACT_4]] -> (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>) {
// CHECK-NEXT:               %[[CONSTANT_21:.*]] = arith.constant 3.1415926535897931 : f64
// CHECK-NEXT:               %[[CONSTANT_22:.*]] = arith.constant 4.000000e+00 : f64
// CHECK-NEXT:               %[[DIVF_4:.*]] = arith.divf %[[CONSTANT_21]], %[[CONSTANT_22]] : f64
// CHECK-NEXT:               %[[VAL_26:.*]] = "quantum.U1"(%[[VAL_27:.*]]#3, %[[DIVF_4]]) : (!quantum.qubit<1>, f64) -> !quantum.qubit<1>
// CHECK-NEXT:               scf.yield %[[VAL_27]]#0, %[[VAL_27]]#1, %[[VAL_27]]#2, %[[VAL_26]] : !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>
// CHECK-NEXT:             } else {
// CHECK-NEXT:               scf.yield %[[VAL_28:.*]]#0, %[[VAL_28]]#1, %[[VAL_28]]#2, %[[VAL_28]]#3 : !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>
// CHECK-NEXT:             }
// CHECK-NEXT:             %[[CONSTANT_23:.*]] = arith.constant dense<true> : tensor<1xi1>
// CHECK-NEXT:             %[[CMPI_5:.*]] = arith.cmpi eq, %[[INSERT_SLICE_2]], %[[CONSTANT_23]] : tensor<1xi1>
// CHECK-NEXT:             %[[CONSTANT_24:.*]] = arith.constant 0 : index
// CHECK-NEXT:             %[[EXTRACT_5:.*]] = tensor.extract %[[CMPI_5]]{{\[}}%[[CONSTANT_24]]] : tensor<1xi1>
// CHECK-NEXT:             %[[IF_5:.*]]:4 = scf.if %[[EXTRACT_5]] -> (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>) {
// CHECK-NEXT:               %[[CONSTANT_25:.*]] = arith.constant 3.1415926535897931 : f64
// CHECK-NEXT:               %[[CONSTANT_26:.*]] = arith.constant 2.000000e+00 : f64
// CHECK-NEXT:               %[[DIVF_5:.*]] = arith.divf %[[CONSTANT_25]], %[[CONSTANT_26]] : f64
// CHECK-NEXT:               %[[VAL_29:.*]] = "quantum.U1"(%[[VAL_30:.*]]#3, %[[DIVF_5]]) : (!quantum.qubit<1>, f64) -> !quantum.qubit<1>
// CHECK-NEXT:               scf.yield %[[VAL_30]]#0, %[[VAL_30]]#1, %[[VAL_30]]#2, %[[VAL_29]] : !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>
// CHECK-NEXT:             } else {
// CHECK-NEXT:               scf.yield %[[VAL_31:.*]]#0, %[[VAL_31]]#1, %[[VAL_31]]#2, %[[VAL_31]]#3 : !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>
// CHECK-NEXT:             }
// CHECK-NEXT:             %[[VAL_32:.*]] = "quantum.H"(%[[VAL_33:.*]]#3) : (!quantum.qubit<1>) -> !quantum.qubit<1>
// CHECK-NEXT:             %[[CONSTANT_27:.*]] = arith.constant dense<false> : tensor<1xi1>
// CHECK-NEXT:             %[[VAL_34:.*]], %[[VAL_35:.*]] = "quantum.measure"(%[[VAL_32]]) : (!quantum.qubit<1>) -> (!quantum.measurement<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[VAL_36:.*]] = "quantum.to_tensor"(%[[VAL_34]]) : (!quantum.measurement<1>) -> tensor<1xi1>
// CHECK-NEXT:             %[[INSERT_SLICE_3:.*]] = tensor.insert_slice %[[VAL_36]] into %[[CONSTANT_27]][0] [1] [1] : tensor<1xi1> into tensor<1xi1>
// CHECK-DAG:             "quantum.deallocate"(%[[VAL_33]]#0) : (!quantum.qubit<1>) -> ()
// CHECK-DAG:             "quantum.deallocate"(%[[VAL_33]]#1) : (!quantum.qubit<1>) -> ()
// CHECK-DAG:             "quantum.deallocate"(%[[VAL_33]]#2) : (!quantum.qubit<1>) -> ()
// CHECK-DAG:             "quantum.deallocate"(%[[VAL_35]]) : (!quantum.qubit<1>) -> ()
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
