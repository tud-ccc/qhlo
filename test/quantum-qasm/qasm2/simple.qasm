// RUN: quantum-qasm %s | FileCheck %s

OPENQASM 2.0;
include "qelib1.inc";

qreg q[2];
creg c[2];

U(pi/2, 0, pi) q[0];
CX q[0], q[1];
sxdg q[0];

// Track U parameters, split-register operands, CX results and the sxdg call.
// Check the complete operation sequence and SSA wiring.
// CHECK-LABEL: module {
// CHECK-NEXT:         qpu.module @simple {
// CHECK-NEXT:           "quantum.gate"() <{function_type = (!quantum.qubit<1>) -> !quantum.qubit<1>, sym_name = "sxdg"}> ({
// CHECK-NEXT:           ^bb0(%[[VAL_0:.*]]: !quantum.qubit<1>):
// CHECK-NEXT:             %[[VAL_1:.*]] = "quantum.S"(%[[VAL_0]]) : (!quantum.qubit<1>) -> !quantum.qubit<1>
// CHECK-NEXT:             %[[VAL_2:.*]] = "quantum.H"(%[[VAL_1]]) : (!quantum.qubit<1>) -> !quantum.qubit<1>
// CHECK-NEXT:             %[[VAL_3:.*]] = "quantum.S"(%[[VAL_2]]) : (!quantum.qubit<1>) -> !quantum.qubit<1>
// CHECK-NEXT:             "quantum.return"(%[[VAL_3]]) : (!quantum.qubit<1>) -> ()
// CHECK-NEXT:           }) : () -> ()
// CHECK-NEXT:           "qpu.circuit"() <{function_type = () -> (), sym_name = "main"}> ({
// CHECK-NEXT:             %[[VAL_4:.*]] = "quantum.alloc"() : () -> !quantum.qubit<2>
// CHECK-NEXT:             %[[VAL_5:.*]]:2 = "quantum.split"(%[[VAL_4]]) : (!quantum.qubit<2>) -> (!quantum.qubit<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[CONSTANT_0:.*]] = arith.constant 3.1415926535897931 : f64
// CHECK-NEXT:             %[[CONSTANT_1:.*]] = arith.constant 2.000000e+00 : f64
// CHECK-NEXT:             %[[DIVF_0:.*]] = arith.divf %[[CONSTANT_0]], %[[CONSTANT_1]] : f64
// CHECK-NEXT:             %[[CONSTANT_2:.*]] = arith.constant 0.000000e+00 : f64
// CHECK-NEXT:             %[[CONSTANT_3:.*]] = arith.constant 3.1415926535897931 : f64
// CHECK-NEXT:             %[[VAL_6:.*]] = "quantum.U3"(%[[VAL_5]]#0, %[[DIVF_0]], %[[CONSTANT_2]], %[[CONSTANT_3]]) : (!quantum.qubit<1>, f64, f64, f64) -> !quantum.qubit<1>
// CHECK-NEXT:             %[[VAL_7:.*]], %[[VAL_8:.*]] = "quantum.CNOT"(%[[VAL_6]], %[[VAL_5]]#1) : (!quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[VAL_9:.*]] = "quantum.call"(%[[VAL_7]]) <{callee = @sxdg}> : (!quantum.qubit<1>) -> !quantum.qubit<1>
// CHECK-DAG:             "quantum.deallocate"(%[[VAL_9]]) : (!quantum.qubit<1>) -> ()
// CHECK-DAG:             "quantum.deallocate"(%[[VAL_8]]) : (!quantum.qubit<1>) -> ()
// CHECK-NEXT:             "qpu.return"() : () -> ()
// CHECK-NEXT:           }) : () -> ()
// CHECK-NEXT:         }
// CHECK-NEXT:         func.func @qasm_main() {
// CHECK-NEXT:           qpu.execute @simple::@main ins () outs ()
// CHECK-NEXT:           return
// CHECK-NEXT:         }
// CHECK-NEXT:       }
