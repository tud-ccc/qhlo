// RUN: quantum-qasm %s | FileCheck %s
// RUN: quantum-qasm %s | quantum-opt -o /dev/null
OPENQASM 2.0;
qreg q[2];
qreg r[1];
// Split q before using the whole register in a barrier.
U(0, 0, 0) q[0];
barrier q, r, q[0];
barrier q[1], r[0];
U(0, 0, 0) q[0];

// Preserve an unsplit register for subsequent whole-register gates.
qreg s[2];
barrier s;
U(0, 0, 0) s;

// Check the complete operation sequence and SSA wiring.
// CHECK-LABEL: module {
// CHECK-NEXT:         qpu.module @barrier {
// CHECK-NEXT:           "qpu.circuit"() <{function_type = () -> (), sym_name = "main"}> ({
// CHECK-NEXT:             %[[VAL_0:.*]] = "quantum.alloc"() : () -> !quantum.qubit<2>
// CHECK-NEXT:             %[[VAL_1:.*]] = "quantum.alloc"() : () -> !quantum.qubit<1>
// CHECK-NEXT:             %[[VAL_2:.*]]:2 = "quantum.split"(%[[VAL_0]]) : (!quantum.qubit<2>) -> (!quantum.qubit<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[CONSTANT_0:.*]] = arith.constant 0.000000e+00 : f64
// CHECK-NEXT:             %[[CONSTANT_1:.*]] = arith.constant 0.000000e+00 : f64
// CHECK-NEXT:             %[[CONSTANT_2:.*]] = arith.constant 0.000000e+00 : f64
// CHECK-NEXT:             %[[VAL_3:.*]] = "quantum.U3"(%[[VAL_2]]#0, %[[CONSTANT_0]], %[[CONSTANT_1]], %[[CONSTANT_2]]) : (!quantum.qubit<1>, f64, f64, f64) -> !quantum.qubit<1>
// CHECK-NEXT:             %[[VAL_4:.*]]:3 = "quantum.barrier"(%[[VAL_3]], %[[VAL_2]]#1, %[[VAL_1]]) : (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[VAL_5:.*]]:2 = "quantum.barrier"(%[[VAL_4]]#1, %[[VAL_4]]#2) : (!quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[CONSTANT_3:.*]] = arith.constant 0.000000e+00 : f64
// CHECK-NEXT:             %[[CONSTANT_4:.*]] = arith.constant 0.000000e+00 : f64
// CHECK-NEXT:             %[[CONSTANT_5:.*]] = arith.constant 0.000000e+00 : f64
// CHECK-NEXT:             %[[VAL_6:.*]] = "quantum.U3"(%[[VAL_4]]#0, %[[CONSTANT_3]], %[[CONSTANT_4]], %[[CONSTANT_5]]) : (!quantum.qubit<1>, f64, f64, f64) -> !quantum.qubit<1>
// CHECK-NEXT:             %[[VAL_7:.*]] = "quantum.alloc"() : () -> !quantum.qubit<2>
// CHECK-NEXT:             %[[VAL_8:.*]] = "quantum.barrier"(%[[VAL_7]]) : (!quantum.qubit<2>) -> !quantum.qubit<2>
// CHECK-NEXT:             %[[CONSTANT_6:.*]] = arith.constant 0.000000e+00 : f64
// CHECK-NEXT:             %[[CONSTANT_7:.*]] = arith.constant 0.000000e+00 : f64
// CHECK-NEXT:             %[[CONSTANT_8:.*]] = arith.constant 0.000000e+00 : f64
// CHECK-NEXT:             %[[VAL_9:.*]] = "quantum.U3"(%[[VAL_8]], %[[CONSTANT_6]], %[[CONSTANT_7]], %[[CONSTANT_8]]) : (!quantum.qubit<2>, f64, f64, f64) -> !quantum.qubit<2>
// CHECK-DAG:             "quantum.deallocate"(%[[VAL_9]]) : (!quantum.qubit<2>) -> ()
// CHECK-DAG:             "quantum.deallocate"(%[[VAL_5]]#1) : (!quantum.qubit<1>) -> ()
// CHECK-DAG:             "quantum.deallocate"(%[[VAL_6]]) : (!quantum.qubit<1>) -> ()
// CHECK-DAG:             "quantum.deallocate"(%[[VAL_5]]#0) : (!quantum.qubit<1>) -> ()
// CHECK-NEXT:             "qpu.return"() : () -> ()
// CHECK-NEXT:           }) : () -> ()
// CHECK-NEXT:         }
// CHECK-NEXT:         func.func @qasm_main() {
// CHECK-NEXT:           qpu.execute @barrier::@main ins () outs ()
// CHECK-NEXT:           return
// CHECK-NEXT:         }
// CHECK-NEXT:       }
