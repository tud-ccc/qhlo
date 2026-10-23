// RUN: quantum-qasm %S/Inputs/adder.qasm | FileCheck %s

// The unmodified upstream source and provenance are in Inputs/ and README.md.
// Check typed operations, parameters, register slices and SSA flow through
// gates, barriers, measurements, classical conditions and circuit results.

// CHECK-LABEL: module {
// CHECK-NEXT:         qpu.module @adder {
// CHECK-NEXT:           "quantum.gate"() <{function_type = (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>), sym_name = "majority"}> ({
// CHECK-NEXT:           ^bb0(%[[VAL_0:.*]]: !quantum.qubit<1>, %[[VAL_1:.*]]: !quantum.qubit<1>, %[[VAL_2:.*]]: !quantum.qubit<1>):
// CHECK-NEXT:             %[[VAL_3:.*]], %[[VAL_4:.*]] = "quantum.CNOT"(%[[VAL_2]], %[[VAL_1]]) : (!quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[VAL_5:.*]], %[[VAL_6:.*]] = "quantum.CNOT"(%[[VAL_3]], %[[VAL_0]]) : (!quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[VAL_7:.*]], %[[VAL_8:.*]], %[[VAL_9:.*]] = "quantum.CCX"(%[[VAL_6]], %[[VAL_4]], %[[VAL_5]]) : (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>)
// CHECK-NEXT:             "quantum.return"(%[[VAL_7]], %[[VAL_8]], %[[VAL_9]]) : (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>) -> ()
// CHECK-NEXT:           }) : () -> ()
// CHECK-NEXT:           "quantum.gate"() <{function_type = (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>), sym_name = "unmaj"}> ({
// CHECK-NEXT:           ^bb0(%[[VAL_10:.*]]: !quantum.qubit<1>, %[[VAL_11:.*]]: !quantum.qubit<1>, %[[VAL_12:.*]]: !quantum.qubit<1>):
// CHECK-NEXT:             %[[VAL_13:.*]], %[[VAL_14:.*]], %[[VAL_15:.*]] = "quantum.CCX"(%[[VAL_10]], %[[VAL_11]], %[[VAL_12]]) : (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[VAL_16:.*]], %[[VAL_17:.*]] = "quantum.CNOT"(%[[VAL_15]], %[[VAL_13]]) : (!quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[VAL_18:.*]], %[[VAL_19:.*]] = "quantum.CNOT"(%[[VAL_17]], %[[VAL_14]]) : (!quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>)
// CHECK-NEXT:             "quantum.return"(%[[VAL_18]], %[[VAL_19]], %[[VAL_16]]) : (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>) -> ()
// CHECK-NEXT:           }) : () -> ()
// CHECK-NEXT:           "qpu.circuit"() <{function_type = () -> tensor<5xi1>, sym_name = "main"}> ({
// CHECK-NEXT:             %[[VAL_20:.*]] = "quantum.alloc"() : () -> !quantum.qubit<1>
// CHECK-NEXT:             %[[VAL_21:.*]] = "quantum.alloc"() : () -> !quantum.qubit<4>
// CHECK-NEXT:             %[[VAL_22:.*]] = "quantum.alloc"() : () -> !quantum.qubit<4>
// CHECK-NEXT:             %[[VAL_23:.*]] = "quantum.alloc"() : () -> !quantum.qubit<1>
// CHECK-NEXT:             %[[VAL_24:.*]]:2 = "quantum.split"(%[[VAL_21]]) : (!quantum.qubit<4>) -> (!quantum.qubit<1>, !quantum.qubit<3>)
// CHECK-NEXT:             %[[VAL_25:.*]] = "quantum.X"(%[[VAL_24]]#0) : (!quantum.qubit<1>) -> !quantum.qubit<1>
// CHECK-NEXT:             %[[VAL_26:.*]] = "quantum.X"(%[[VAL_22]]) : (!quantum.qubit<4>) -> !quantum.qubit<4>
// CHECK-NEXT:             %[[VAL_27:.*]]:2 = "quantum.split"(%[[VAL_26]]) : (!quantum.qubit<4>) -> (!quantum.qubit<1>, !quantum.qubit<3>)
// CHECK-NEXT:             %[[VAL_28:.*]]:3 = "quantum.call"(%[[VAL_20]], %[[VAL_27]]#0, %[[VAL_25]]) <{callee = @majority}> : (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[VAL_29:.*]]:2 = "quantum.split"(%[[VAL_27]]#1) : (!quantum.qubit<3>) -> (!quantum.qubit<1>, !quantum.qubit<2>)
// CHECK-NEXT:             %[[VAL_30:.*]]:2 = "quantum.split"(%[[VAL_24]]#1) : (!quantum.qubit<3>) -> (!quantum.qubit<1>, !quantum.qubit<2>)
// CHECK-NEXT:             %[[VAL_31:.*]]:3 = "quantum.call"(%[[VAL_28]]#2, %[[VAL_29]]#0, %[[VAL_30]]#0) <{callee = @majority}> : (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[VAL_32:.*]]:2 = "quantum.split"(%[[VAL_29]]#1) : (!quantum.qubit<2>) -> (!quantum.qubit<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[VAL_33:.*]]:2 = "quantum.split"(%[[VAL_30]]#1) : (!quantum.qubit<2>) -> (!quantum.qubit<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[VAL_34:.*]]:3 = "quantum.call"(%[[VAL_31]]#2, %[[VAL_32]]#0, %[[VAL_33]]#0) <{callee = @majority}> : (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[VAL_35:.*]]:3 = "quantum.call"(%[[VAL_34]]#2, %[[VAL_32]]#1, %[[VAL_33]]#1) <{callee = @majority}> : (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[VAL_36:.*]], %[[VAL_37:.*]] = "quantum.CNOT"(%[[VAL_35]]#2, %[[VAL_23]]) : (!quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[VAL_38:.*]]:3 = "quantum.call"(%[[VAL_35]]#0, %[[VAL_35]]#1, %[[VAL_36]]) <{callee = @unmaj}> : (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[VAL_39:.*]]:3 = "quantum.call"(%[[VAL_34]]#0, %[[VAL_34]]#1, %[[VAL_38]]#0) <{callee = @unmaj}> : (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[VAL_40:.*]]:3 = "quantum.call"(%[[VAL_31]]#0, %[[VAL_31]]#1, %[[VAL_39]]#0) <{callee = @unmaj}> : (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[VAL_41:.*]]:3 = "quantum.call"(%[[VAL_28]]#0, %[[VAL_28]]#1, %[[VAL_40]]#0) <{callee = @unmaj}> : (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[CONSTANT_0:.*]] = arith.constant dense<false> : tensor<5xi1>
// CHECK-NEXT:             %[[VAL_42:.*]], %[[VAL_43:.*]] = "quantum.measure"(%[[VAL_41]]#1) : (!quantum.qubit<1>) -> (!quantum.measurement<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[VAL_44:.*]] = "quantum.to_tensor"(%[[VAL_42]]) : (!quantum.measurement<1>) -> tensor<1xi1>
// CHECK-NEXT:             %[[INSERT_SLICE_0:.*]] = tensor.insert_slice %[[VAL_44]] into %[[CONSTANT_0]][0] [1] [1] : tensor<1xi1> into tensor<5xi1>
// CHECK-NEXT:             %[[VAL_45:.*]], %[[VAL_46:.*]] = "quantum.measure"(%[[VAL_40]]#1) : (!quantum.qubit<1>) -> (!quantum.measurement<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[VAL_47:.*]] = "quantum.to_tensor"(%[[VAL_45]]) : (!quantum.measurement<1>) -> tensor<1xi1>
// CHECK-NEXT:             %[[INSERT_SLICE_1:.*]] = tensor.insert_slice %[[VAL_47]] into %[[INSERT_SLICE_0]][1] [1] [1] : tensor<1xi1> into tensor<5xi1>
// CHECK-NEXT:             %[[VAL_48:.*]], %[[VAL_49:.*]] = "quantum.measure"(%[[VAL_39]]#1) : (!quantum.qubit<1>) -> (!quantum.measurement<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[VAL_50:.*]] = "quantum.to_tensor"(%[[VAL_48]]) : (!quantum.measurement<1>) -> tensor<1xi1>
// CHECK-NEXT:             %[[INSERT_SLICE_2:.*]] = tensor.insert_slice %[[VAL_50]] into %[[INSERT_SLICE_1]][2] [1] [1] : tensor<1xi1> into tensor<5xi1>
// CHECK-NEXT:             %[[VAL_51:.*]], %[[VAL_52:.*]] = "quantum.measure"(%[[VAL_38]]#1) : (!quantum.qubit<1>) -> (!quantum.measurement<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[VAL_53:.*]] = "quantum.to_tensor"(%[[VAL_51]]) : (!quantum.measurement<1>) -> tensor<1xi1>
// CHECK-NEXT:             %[[INSERT_SLICE_3:.*]] = tensor.insert_slice %[[VAL_53]] into %[[INSERT_SLICE_2]][3] [1] [1] : tensor<1xi1> into tensor<5xi1>
// CHECK-NEXT:             %[[VAL_54:.*]], %[[VAL_55:.*]] = "quantum.measure"(%[[VAL_37]]) : (!quantum.qubit<1>) -> (!quantum.measurement<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[VAL_56:.*]] = "quantum.to_tensor"(%[[VAL_54]]) : (!quantum.measurement<1>) -> tensor<1xi1>
// CHECK-NEXT:             %[[INSERT_SLICE_4:.*]] = tensor.insert_slice %[[VAL_56]] into %[[INSERT_SLICE_3]][4] [1] [1] : tensor<1xi1> into tensor<5xi1>
// CHECK-DAG:             "quantum.deallocate"(%[[VAL_43]]) : (!quantum.qubit<1>) -> ()
// CHECK-DAG:             "quantum.deallocate"(%[[VAL_46]]) : (!quantum.qubit<1>) -> ()
// CHECK-DAG:             "quantum.deallocate"(%[[VAL_49]]) : (!quantum.qubit<1>) -> ()
// CHECK-DAG:             "quantum.deallocate"(%[[VAL_52]]) : (!quantum.qubit<1>) -> ()
// CHECK-DAG:             "quantum.deallocate"(%[[VAL_41]]#0) : (!quantum.qubit<1>) -> ()
// CHECK-DAG:             "quantum.deallocate"(%[[VAL_55]]) : (!quantum.qubit<1>) -> ()
// CHECK-DAG:             "quantum.deallocate"(%[[VAL_41]]#2) : (!quantum.qubit<1>) -> ()
// CHECK-DAG:             "quantum.deallocate"(%[[VAL_40]]#2) : (!quantum.qubit<1>) -> ()
// CHECK-DAG:             "quantum.deallocate"(%[[VAL_39]]#2) : (!quantum.qubit<1>) -> ()
// CHECK-DAG:             "quantum.deallocate"(%[[VAL_38]]#2) : (!quantum.qubit<1>) -> ()
// CHECK-NEXT:             "qpu.return"(%[[INSERT_SLICE_4]]) : (tensor<5xi1>) -> ()
// CHECK-NEXT:           }) : () -> ()
// CHECK-NEXT:         }
// CHECK-NEXT:         func.func @qasm_main() -> tensor<5xi1> {
// CHECK-NEXT:           %[[EMPTY_0:.*]] = tensor.empty() : tensor<5xi1>
// CHECK-NEXT:           %[[EXECUTE_0:.*]] = qpu.execute @adder::@main ins () outs (%[[EMPTY_0]] : tensor<5xi1>)
// CHECK-NEXT:           return %[[EXECUTE_0]] : tensor<5xi1>
// CHECK-NEXT:         }
// CHECK-NEXT:       }
