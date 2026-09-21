// RUN: quantum-qasm %s | FileCheck %s

OPENQASM 2.0;
include "qelib1.inc";

qreg q[2];
creg c[2];

U(pi/2, 0, pi) q[0];
CX q[0], q[1];
sxdg q[0];

// CHECK: "builtin.module"() ({
// CHECK-NEXT: "qpu.module"() <{sym_name = "qasm_generated"}> ({
// CHECK-NEXT: "quantum.gate"() <{function_type = (!quantum.qubit<1>) -> !quantum.qubit<1>, sym_name = "sxdg"}> ({
// CHECK-NEXT: ^bb0(%[[ARG:.*]]: !quantum.qubit<1>):
// CHECK-NEXT: %[[S1:.*]] = "quantum.S"(%[[ARG]]) : (!quantum.qubit<1>) -> !quantum.qubit<1>
// CHECK-NEXT: %[[H:.*]] = "quantum.H"(%[[S1]]) : (!quantum.qubit<1>) -> !quantum.qubit<1>
// CHECK-NEXT: %[[S2:.*]] = "quantum.S"(%[[H]]) : (!quantum.qubit<1>) -> !quantum.qubit<1>
// CHECK-NEXT: "quantum.return"(%[[S2]]) : (!quantum.qubit<1>) -> ()
// CHECK-NEXT: }) : () -> ()
// CHECK-NEXT: "qpu.circuit"() <{function_type = () -> (), sym_name = "main"}> ({
// CHECK: %[[Q:.*]] = "quantum.alloc"() : () -> !quantum.qubit<2>

// Accessing q[0] splits the register into two single-qubit SSA values.
// CHECK: %[[Q0:.*]]:2 = "quantum.split"(%[[Q]]) : (!quantum.qubit<2>) -> (!quantum.qubit<1>, !quantum.qubit<1>)

// Parameters of U(pi/2, 0, pi).
// CHECK: %[[PI1:.*]] = "arith.constant"() <{value = 3.1415926535897931 : f64}> : () -> f64
// CHECK: %[[TWO:.*]] = "arith.constant"() <{value = 2.000000e+00 : f64}> : () -> f64
// CHECK: %[[THETA:.*]] = "arith.divf"(%[[PI1]], %[[TWO]])
// CHECK: %[[PHI:.*]] = "arith.constant"() <{value = 0.000000e+00 : f64}> : () -> f64
// CHECK: %[[LAMBDA:.*]] = "arith.constant"() <{value = 3.1415926535897931 : f64}> : () -> f64

// U updates q[0].
// CHECK: %[[UQ0:.*]] = "quantum.U3"(%[[Q0]]#0, %[[THETA]], %[[PHI]], %[[LAMBDA]]) : (!quantum.qubit<1>, f64, f64, f64) -> !quantum.qubit<1>

// CX consumes the updated q[0] and the unchanged q[1].
// CHECK: %[[CQ:.*]]:2 = "quantum.CNOT"(%[[UQ0]], %[[Q0]]#1) : (!quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>)

// sxdg consumes the updated q[0] and calls the gate defined above.
// CHECK-NEXT: %[[SXDG:.*]] = "quantum.call"(%[[CQ]]#0) <{callee = @sxdg}> : (!quantum.qubit<1>) -> !quantum.qubit<1>
// CHECK-NEXT: }) : () -> ()
// CHECK-NEXT: }) : () -> ()
// CHECK-NEXT: }) : () -> ()
