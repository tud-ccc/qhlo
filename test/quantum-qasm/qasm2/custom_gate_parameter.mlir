// RUN: quantum-qasm %S/Inputs/custom_gate_parameter.qasm | FileCheck %s

// CHECK-LABEL: module {
// CHECK-NEXT:         qpu.module @custom_gate_parameter {
// CHECK-NEXT:           "quantum.gate"() <{function_type = (!quantum.qubit<1>, f64) -> !quantum.qubit<1>, sym_name = "rotate"}> ({
// CHECK-NEXT:           ^bb0(%[[VAL_0:.*]]: !quantum.qubit<1>, %[[VAL_1:.*]]: f64):
// CHECK-NEXT:             %[[CONSTANT_0:.*]] = arith.constant 0.000000e+00 : f64
// CHECK-NEXT:             %[[CONSTANT_1:.*]] = arith.constant 0.000000e+00 : f64
// CHECK-NEXT:             %[[VAL_2:.*]] = "quantum.U3"(%[[VAL_0]], %[[VAL_1]], %[[CONSTANT_0]], %[[CONSTANT_1]]) : (!quantum.qubit<1>, f64, f64, f64) -> !quantum.qubit<1>
// CHECK-NEXT:             "quantum.return"(%[[VAL_2]]) : (!quantum.qubit<1>) -> ()
// CHECK-NEXT:           }) : () -> ()
// CHECK-NEXT:           "qpu.circuit"() <{function_type = () -> (), sym_name = "main"}> ({
// CHECK-NEXT:             %[[VAL_3:.*]] = "quantum.alloc"() : () -> !quantum.qubit<1>
// CHECK-NEXT:             %[[CONSTANT_2:.*]] = arith.constant 5.000000e-01 : f64
// CHECK-NEXT:             %[[VAL_4:.*]] = "quantum.call"(%[[VAL_3]], %[[CONSTANT_2]]) <{callee = @rotate}> : (!quantum.qubit<1>, f64) -> !quantum.qubit<1>
// CHECK-NEXT:             "quantum.deallocate"(%[[VAL_4]]) : (!quantum.qubit<1>) -> ()
// CHECK-NEXT:             "qpu.return"() : () -> ()
// CHECK-NEXT:           }) : () -> ()
// CHECK-NEXT:         }
// CHECK-NEXT:         func.func @qasm_main() {
// CHECK-NEXT:           qpu.execute @custom_gate_parameter::@main ins () outs ()
// CHECK-NEXT:           return
// CHECK-NEXT:         }
// CHECK-NEXT:       }
