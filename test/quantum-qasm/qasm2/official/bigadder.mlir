// RUN: quantum-qasm %S/Inputs/bigadder.qasm | FileCheck %s

// The unmodified upstream source and provenance are in Inputs/ and README.md.
// Check typed operations, parameters, register slices and SSA flow through
// gates, barriers, measurements, classical conditions and circuit results.

// CHECK-LABEL: module {
// CHECK-NEXT:         qpu.module @bigadder {
// CHECK-NEXT:           "quantum.gate"() <{function_type = (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>), sym_name = "add4"}> ({
// CHECK-NEXT:           ^bb0(%[[VAL_0:.*]]: !quantum.qubit<1>, %[[VAL_1:.*]]: !quantum.qubit<1>, %[[VAL_2:.*]]: !quantum.qubit<1>, %[[VAL_3:.*]]: !quantum.qubit<1>, %[[VAL_4:.*]]: !quantum.qubit<1>, %[[VAL_5:.*]]: !quantum.qubit<1>, %[[VAL_6:.*]]: !quantum.qubit<1>, %[[VAL_7:.*]]: !quantum.qubit<1>, %[[VAL_8:.*]]: !quantum.qubit<1>, %[[VAL_9:.*]]: !quantum.qubit<1>):
// CHECK-NEXT:             %[[VAL_10:.*]]:3 = "quantum.call"(%[[VAL_8]], %[[VAL_4]], %[[VAL_0]]) <{callee = @majority}> : (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[VAL_11:.*]]:3 = "quantum.call"(%[[VAL_10]]#2, %[[VAL_5]], %[[VAL_1]]) <{callee = @majority}> : (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[VAL_12:.*]]:3 = "quantum.call"(%[[VAL_11]]#2, %[[VAL_6]], %[[VAL_2]]) <{callee = @majority}> : (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[VAL_13:.*]]:3 = "quantum.call"(%[[VAL_12]]#2, %[[VAL_7]], %[[VAL_3]]) <{callee = @majority}> : (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[VAL_14:.*]], %[[VAL_15:.*]] = "quantum.CNOT"(%[[VAL_13]]#2, %[[VAL_9]]) : (!quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[VAL_16:.*]]:3 = "quantum.call"(%[[VAL_13]]#0, %[[VAL_13]]#1, %[[VAL_14]]) <{callee = @unmaj}> : (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[VAL_17:.*]]:3 = "quantum.call"(%[[VAL_12]]#0, %[[VAL_12]]#1, %[[VAL_16]]#0) <{callee = @unmaj}> : (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[VAL_18:.*]]:3 = "quantum.call"(%[[VAL_11]]#0, %[[VAL_11]]#1, %[[VAL_17]]#0) <{callee = @unmaj}> : (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[VAL_19:.*]]:3 = "quantum.call"(%[[VAL_10]]#0, %[[VAL_10]]#1, %[[VAL_18]]#0) <{callee = @unmaj}> : (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>)
// CHECK-NEXT:             "quantum.return"(%[[VAL_19]]#2, %[[VAL_18]]#2, %[[VAL_17]]#2, %[[VAL_16]]#2, %[[VAL_19]]#1, %[[VAL_18]]#1, %[[VAL_17]]#1, %[[VAL_16]]#1, %[[VAL_19]]#0, %[[VAL_15]]) : (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>) -> ()
// CHECK-NEXT:           }) : () -> ()
// CHECK-NEXT:           "quantum.gate"() <{function_type = (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>), sym_name = "majority"}> ({
// CHECK-NEXT:           ^bb0(%[[VAL_20:.*]]: !quantum.qubit<1>, %[[VAL_21:.*]]: !quantum.qubit<1>, %[[VAL_22:.*]]: !quantum.qubit<1>):
// CHECK-NEXT:             %[[VAL_23:.*]], %[[VAL_24:.*]] = "quantum.CNOT"(%[[VAL_22]], %[[VAL_21]]) : (!quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[VAL_25:.*]], %[[VAL_26:.*]] = "quantum.CNOT"(%[[VAL_23]], %[[VAL_20]]) : (!quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[VAL_27:.*]], %[[VAL_28:.*]], %[[VAL_29:.*]] = "quantum.CCX"(%[[VAL_26]], %[[VAL_24]], %[[VAL_25]]) : (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>)
// CHECK-NEXT:             "quantum.return"(%[[VAL_27]], %[[VAL_28]], %[[VAL_29]]) : (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>) -> ()
// CHECK-NEXT:           }) : () -> ()
// CHECK-NEXT:           "quantum.gate"() <{function_type = (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>), sym_name = "unmaj"}> ({
// CHECK-NEXT:           ^bb0(%[[VAL_30:.*]]: !quantum.qubit<1>, %[[VAL_31:.*]]: !quantum.qubit<1>, %[[VAL_32:.*]]: !quantum.qubit<1>):
// CHECK-NEXT:             %[[VAL_33:.*]], %[[VAL_34:.*]], %[[VAL_35:.*]] = "quantum.CCX"(%[[VAL_30]], %[[VAL_31]], %[[VAL_32]]) : (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[VAL_36:.*]], %[[VAL_37:.*]] = "quantum.CNOT"(%[[VAL_35]], %[[VAL_33]]) : (!quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[VAL_38:.*]], %[[VAL_39:.*]] = "quantum.CNOT"(%[[VAL_37]], %[[VAL_34]]) : (!quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>)
// CHECK-NEXT:             "quantum.return"(%[[VAL_38]], %[[VAL_39]], %[[VAL_36]]) : (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>) -> ()
// CHECK-NEXT:           }) : () -> ()
// CHECK-NEXT:           "qpu.circuit"() <{function_type = () -> (tensor<8xi1>, tensor<1xi1>), sym_name = "main"}> ({
// CHECK-NEXT:             %[[VAL_40:.*]] = "quantum.alloc"() : () -> !quantum.qubit<2>
// CHECK-NEXT:             %[[VAL_41:.*]] = "quantum.alloc"() : () -> !quantum.qubit<8>
// CHECK-NEXT:             %[[VAL_42:.*]] = "quantum.alloc"() : () -> !quantum.qubit<8>
// CHECK-NEXT:             %[[VAL_43:.*]]:2 = "quantum.split"(%[[VAL_41]]) : (!quantum.qubit<8>) -> (!quantum.qubit<1>, !quantum.qubit<7>)
// CHECK-NEXT:             %[[VAL_44:.*]] = "quantum.X"(%[[VAL_43]]#0) : (!quantum.qubit<1>) -> !quantum.qubit<1>
// CHECK-NEXT:             %[[VAL_45:.*]] = "quantum.X"(%[[VAL_42]]) : (!quantum.qubit<8>) -> !quantum.qubit<8>
// CHECK-NEXT:             %[[VAL_46:.*]]:3 = "quantum.split"(%[[VAL_45]]) : (!quantum.qubit<8>) -> (!quantum.qubit<6>, !quantum.qubit<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[VAL_47:.*]] = "quantum.X"(%[[VAL_46]]#1) : (!quantum.qubit<1>) -> !quantum.qubit<1>
// CHECK-NEXT:             %[[VAL_48:.*]]:2 = "quantum.split"(%[[VAL_43]]#1) : (!quantum.qubit<7>) -> (!quantum.qubit<1>, !quantum.qubit<6>)
// CHECK-NEXT:             %[[VAL_49:.*]]:2 = "quantum.split"(%[[VAL_48]]#1) : (!quantum.qubit<6>) -> (!quantum.qubit<1>, !quantum.qubit<5>)
// CHECK-NEXT:             %[[VAL_50:.*]]:2 = "quantum.split"(%[[VAL_49]]#1) : (!quantum.qubit<5>) -> (!quantum.qubit<1>, !quantum.qubit<4>)
// CHECK-NEXT:             %[[VAL_51:.*]]:2 = "quantum.split"(%[[VAL_46]]#0) : (!quantum.qubit<6>) -> (!quantum.qubit<1>, !quantum.qubit<5>)
// CHECK-NEXT:             %[[VAL_52:.*]]:2 = "quantum.split"(%[[VAL_51]]#1) : (!quantum.qubit<5>) -> (!quantum.qubit<1>, !quantum.qubit<4>)
// CHECK-NEXT:             %[[VAL_53:.*]]:2 = "quantum.split"(%[[VAL_52]]#1) : (!quantum.qubit<4>) -> (!quantum.qubit<1>, !quantum.qubit<3>)
// CHECK-NEXT:             %[[VAL_54:.*]]:2 = "quantum.split"(%[[VAL_53]]#1) : (!quantum.qubit<3>) -> (!quantum.qubit<1>, !quantum.qubit<2>)
// CHECK-NEXT:             %[[VAL_55:.*]]:2 = "quantum.split"(%[[VAL_40]]) : (!quantum.qubit<2>) -> (!quantum.qubit<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[VAL_56:.*]]:10 = "quantum.call"(%[[VAL_44]], %[[VAL_48]]#0, %[[VAL_49]]#0, %[[VAL_50]]#0, %[[VAL_51]]#0, %[[VAL_52]]#0, %[[VAL_53]]#0, %[[VAL_54]]#0, %[[VAL_55]]#0, %[[VAL_55]]#1) <{callee = @add4}> : (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[VAL_57:.*]]:2 = "quantum.split"(%[[VAL_50]]#1) : (!quantum.qubit<4>) -> (!quantum.qubit<1>, !quantum.qubit<3>)
// CHECK-NEXT:             %[[VAL_58:.*]]:2 = "quantum.split"(%[[VAL_57]]#1) : (!quantum.qubit<3>) -> (!quantum.qubit<1>, !quantum.qubit<2>)
// CHECK-NEXT:             %[[VAL_59:.*]]:2 = "quantum.split"(%[[VAL_58]]#1) : (!quantum.qubit<2>) -> (!quantum.qubit<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[VAL_60:.*]]:2 = "quantum.split"(%[[VAL_54]]#1) : (!quantum.qubit<2>) -> (!quantum.qubit<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[VAL_61:.*]]:10 = "quantum.call"(%[[VAL_57]]#0, %[[VAL_58]]#0, %[[VAL_59]]#0, %[[VAL_59]]#1, %[[VAL_60]]#0, %[[VAL_60]]#1, %[[VAL_47]], %[[VAL_46]]#2, %[[VAL_56]]#9, %[[VAL_56]]#8) <{callee = @add4}> : (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[CONSTANT_0:.*]] = arith.constant dense<false> : tensor<8xi1>
// CHECK-NEXT:             %[[VAL_62:.*]], %[[VAL_63:.*]] = "quantum.measure"(%[[VAL_56]]#4) : (!quantum.qubit<1>) -> (!quantum.measurement<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[VAL_64:.*]] = "qpu.to_bits"(%[[VAL_62]]) : (!quantum.measurement<1>) -> tensor<1xi1>
// CHECK-NEXT:             %[[INSERT_SLICE_0:.*]] = tensor.insert_slice %[[VAL_64]] into %[[CONSTANT_0]][0] [1] [1] : tensor<1xi1> into tensor<8xi1>
// CHECK-NEXT:             %[[VAL_65:.*]], %[[VAL_66:.*]] = "quantum.measure"(%[[VAL_56]]#5) : (!quantum.qubit<1>) -> (!quantum.measurement<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[VAL_67:.*]] = "qpu.to_bits"(%[[VAL_65]]) : (!quantum.measurement<1>) -> tensor<1xi1>
// CHECK-NEXT:             %[[INSERT_SLICE_1:.*]] = tensor.insert_slice %[[VAL_67]] into %[[INSERT_SLICE_0]][1] [1] [1] : tensor<1xi1> into tensor<8xi1>
// CHECK-NEXT:             %[[VAL_68:.*]], %[[VAL_69:.*]] = "quantum.measure"(%[[VAL_56]]#6) : (!quantum.qubit<1>) -> (!quantum.measurement<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[VAL_70:.*]] = "qpu.to_bits"(%[[VAL_68]]) : (!quantum.measurement<1>) -> tensor<1xi1>
// CHECK-NEXT:             %[[INSERT_SLICE_2:.*]] = tensor.insert_slice %[[VAL_70]] into %[[INSERT_SLICE_1]][2] [1] [1] : tensor<1xi1> into tensor<8xi1>
// CHECK-NEXT:             %[[VAL_71:.*]], %[[VAL_72:.*]] = "quantum.measure"(%[[VAL_56]]#7) : (!quantum.qubit<1>) -> (!quantum.measurement<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[VAL_73:.*]] = "qpu.to_bits"(%[[VAL_71]]) : (!quantum.measurement<1>) -> tensor<1xi1>
// CHECK-NEXT:             %[[INSERT_SLICE_3:.*]] = tensor.insert_slice %[[VAL_73]] into %[[INSERT_SLICE_2]][3] [1] [1] : tensor<1xi1> into tensor<8xi1>
// CHECK-NEXT:             %[[VAL_74:.*]], %[[VAL_75:.*]] = "quantum.measure"(%[[VAL_61]]#4) : (!quantum.qubit<1>) -> (!quantum.measurement<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[VAL_76:.*]] = "qpu.to_bits"(%[[VAL_74]]) : (!quantum.measurement<1>) -> tensor<1xi1>
// CHECK-NEXT:             %[[INSERT_SLICE_4:.*]] = tensor.insert_slice %[[VAL_76]] into %[[INSERT_SLICE_3]][4] [1] [1] : tensor<1xi1> into tensor<8xi1>
// CHECK-NEXT:             %[[VAL_77:.*]], %[[VAL_78:.*]] = "quantum.measure"(%[[VAL_61]]#5) : (!quantum.qubit<1>) -> (!quantum.measurement<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[VAL_79:.*]] = "qpu.to_bits"(%[[VAL_77]]) : (!quantum.measurement<1>) -> tensor<1xi1>
// CHECK-NEXT:             %[[INSERT_SLICE_5:.*]] = tensor.insert_slice %[[VAL_79]] into %[[INSERT_SLICE_4]][5] [1] [1] : tensor<1xi1> into tensor<8xi1>
// CHECK-NEXT:             %[[VAL_80:.*]], %[[VAL_81:.*]] = "quantum.measure"(%[[VAL_61]]#6) : (!quantum.qubit<1>) -> (!quantum.measurement<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[VAL_82:.*]] = "qpu.to_bits"(%[[VAL_80]]) : (!quantum.measurement<1>) -> tensor<1xi1>
// CHECK-NEXT:             %[[INSERT_SLICE_6:.*]] = tensor.insert_slice %[[VAL_82]] into %[[INSERT_SLICE_5]][6] [1] [1] : tensor<1xi1> into tensor<8xi1>
// CHECK-NEXT:             %[[VAL_83:.*]], %[[VAL_84:.*]] = "quantum.measure"(%[[VAL_61]]#7) : (!quantum.qubit<1>) -> (!quantum.measurement<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[VAL_85:.*]] = "qpu.to_bits"(%[[VAL_83]]) : (!quantum.measurement<1>) -> tensor<1xi1>
// CHECK-NEXT:             %[[INSERT_SLICE_7:.*]] = tensor.insert_slice %[[VAL_85]] into %[[INSERT_SLICE_6]][7] [1] [1] : tensor<1xi1> into tensor<8xi1>
// CHECK-NEXT:             %[[CONSTANT_1:.*]] = arith.constant dense<false> : tensor<1xi1>
// CHECK-NEXT:             %[[VAL_86:.*]], %[[VAL_87:.*]] = "quantum.measure"(%[[VAL_61]]#9) : (!quantum.qubit<1>) -> (!quantum.measurement<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[VAL_88:.*]] = "qpu.to_bits"(%[[VAL_86]]) : (!quantum.measurement<1>) -> tensor<1xi1>
// CHECK-NEXT:             %[[INSERT_SLICE_8:.*]] = tensor.insert_slice %[[VAL_88]] into %[[CONSTANT_1]][0] [1] [1] : tensor<1xi1> into tensor<1xi1>
// CHECK-DAG:             "quantum.deallocate"(%[[VAL_63]]) : (!quantum.qubit<1>) -> ()
// CHECK-DAG:             "quantum.deallocate"(%[[VAL_66]]) : (!quantum.qubit<1>) -> ()
// CHECK-DAG:             "quantum.deallocate"(%[[VAL_69]]) : (!quantum.qubit<1>) -> ()
// CHECK-DAG:             "quantum.deallocate"(%[[VAL_72]]) : (!quantum.qubit<1>) -> ()
// CHECK-DAG:             "quantum.deallocate"(%[[VAL_75]]) : (!quantum.qubit<1>) -> ()
// CHECK-DAG:             "quantum.deallocate"(%[[VAL_78]]) : (!quantum.qubit<1>) -> ()
// CHECK-DAG:             "quantum.deallocate"(%[[VAL_81]]) : (!quantum.qubit<1>) -> ()
// CHECK-DAG:             "quantum.deallocate"(%[[VAL_84]]) : (!quantum.qubit<1>) -> ()
// CHECK-DAG:             "quantum.deallocate"(%[[VAL_87]]) : (!quantum.qubit<1>) -> ()
// CHECK-DAG:             "quantum.deallocate"(%[[VAL_61]]#8) : (!quantum.qubit<1>) -> ()
// CHECK-DAG:             "quantum.deallocate"(%[[VAL_56]]#0) : (!quantum.qubit<1>) -> ()
// CHECK-DAG:             "quantum.deallocate"(%[[VAL_56]]#1) : (!quantum.qubit<1>) -> ()
// CHECK-DAG:             "quantum.deallocate"(%[[VAL_56]]#2) : (!quantum.qubit<1>) -> ()
// CHECK-DAG:             "quantum.deallocate"(%[[VAL_56]]#3) : (!quantum.qubit<1>) -> ()
// CHECK-DAG:             "quantum.deallocate"(%[[VAL_61]]#0) : (!quantum.qubit<1>) -> ()
// CHECK-DAG:             "quantum.deallocate"(%[[VAL_61]]#1) : (!quantum.qubit<1>) -> ()
// CHECK-DAG:             "quantum.deallocate"(%[[VAL_61]]#2) : (!quantum.qubit<1>) -> ()
// CHECK-DAG:             "quantum.deallocate"(%[[VAL_61]]#3) : (!quantum.qubit<1>) -> ()
// CHECK-NEXT:             "qpu.return"(%[[INSERT_SLICE_7]], %[[INSERT_SLICE_8]]) : (tensor<8xi1>, tensor<1xi1>) -> ()
// CHECK-NEXT:           }) : () -> ()
// CHECK-NEXT:         }
// CHECK-NEXT:         func.func @qasm_main() -> (tensor<8xi1>, tensor<1xi1>) {
// CHECK-NEXT:           %[[EMPTY_0:.*]] = tensor.empty() : tensor<8xi1>
// CHECK-NEXT:           %[[EMPTY_1:.*]] = tensor.empty() : tensor<1xi1>
// CHECK-NEXT:           %[[EXECUTE_0:.*]]:2 = qpu.execute @bigadder::@main ins () outs (%[[EMPTY_0]] : tensor<8xi1>, %[[EMPTY_1]] : tensor<1xi1>)
// CHECK-NEXT:           return %[[EXECUTE_0]]#0, %[[EXECUTE_0]]#1 : tensor<8xi1>, tensor<1xi1>
// CHECK-NEXT:         }
// CHECK-NEXT:       }
