// RUN: quantum-qasm %s -split-input-file > %t.mlir
// RUN: FileCheck %s --enable-var-scope < %t.mlir
// RUN: quantum-opt %t.mlir -split-input-file -o /dev/null

// Native gates.
OPENQASM 3.0;
qubit[2] q;
h q[0];
cx q[0], q[1];
CX q[0], q[1];
p(1) q[1];
cp(2) q[0], q[1];
U(1, 2, 3) q[0];
reset q;

// CHECK-LABEL: module {
// CHECK: %[[SPLIT:.*]]:2 = "quantum.split"
// CHECK: %[[H:.*]] = "quantum.H"(%[[SPLIT]]#0)
// CHECK: %[[CX_CONTROL:.*]], %[[CX_TARGET:.*]] = "quantum.CNOT"(%[[H]], %[[SPLIT]]#1)
// CHECK: %[[UPPER_CONTROL:.*]], %[[UPPER_TARGET:.*]] = "quantum.CNOT"(%[[CX_CONTROL]], %[[CX_TARGET]])
// CHECK: %[[P:.*]] = "quantum.P"(%[[UPPER_TARGET]],
// CHECK: %[[CP_CONTROL:.*]], %[[CP_TARGET:.*]] = "quantum.CU1"(%[[UPPER_CONTROL]], %[[P]],
// CHECK: %[[U:.*]] = "quantum.U3"(%[[CP_CONTROL]],
// CHECK: "quantum.reset"(%[[U]])
// CHECK: "quantum.reset"(%[[CP_TARGET]])

// -----

// Custom gates.
OPENQASM 3.0;
gate rotate(theta) a { rx(theta) a; }
gate outer(theta) a { rotate(theta) a; h a; }
gate identity a {}
qubit q;
outer(1) q;
outer(2) q;
identity q;
reset q;

// CHECK-LABEL: module {
// CHECK: "quantum.gate"() <{function_type = (!quantum.qubit<1>, f64) -> !quantum.qubit<1>, sym_name = "outer"}>
// CHECK: ^bb0(%[[ARG:.*]]: !quantum.qubit<1>, %[[THETA:.*]]: f64):
// CHECK: %[[INNER:.*]] = "quantum.call"(%[[ARG]], %[[THETA]]) <{callee = @rotate}>
// CHECK: %[[H:.*]] = "quantum.H"(%[[INNER]])
// CHECK: "quantum.return"(%[[H]])
// CHECK: "quantum.gate"() <{function_type = (!quantum.qubit<1>, f64) -> !quantum.qubit<1>, sym_name = "rotate"}>
// CHECK: ^bb0(%[[Q:.*]]: !quantum.qubit<1>, %[[PARAM:.*]]: f64):
// CHECK: %[[RX:.*]] = "quantum.Rx"(%[[Q]], %[[PARAM]])
// CHECK: "quantum.return"(%[[RX]])
// CHECK: "quantum.gate"() <{function_type = (!quantum.qubit<1>) -> !quantum.qubit<1>, sym_name = "identity"}>
// CHECK: ^bb0(%[[ID:.*]]: !quantum.qubit<1>):
// CHECK-NEXT: "quantum.return"(%[[ID]])
// CHECK: "qpu.circuit"
// CHECK: %[[ALLOC:.*]] = "quantum.alloc"
// CHECK: %[[FIRST:.*]] = "quantum.call"(%[[ALLOC]], {{.*}}) <{callee = @outer}>
// CHECK: %[[SECOND:.*]] = "quantum.call"(%[[FIRST]], {{.*}}) <{callee = @outer}>
// CHECK: %[[IDENTITY:.*]] = "quantum.call"(%[[SECOND]]) <{callee = @identity}>
// CHECK: "quantum.reset"(%[[IDENTITY]])
// CHECK-NOT: "quantum.gate"

// -----

// Controls and targets from the same register stay distinct in the region.
OPENQASM 3.0;
qubit[2] q;
ctrl @ p(pi / 2) q[0], q[1];
h q[0];
x q[1];

// CHECK-LABEL: module {
// CHECK: %[[ANGLE:.*]] = arith.constant 1.5707963267948966 : f64
// CHECK: %[[SPLIT:.*]]:2 = "quantum.split"
// CHECK: %[[CTRL:.*]]:2 = "quantum.ctrl"(%[[SPLIT]]#0, %[[SPLIT]]#1) <{nctrls = 1 : index}>
// CHECK: ^bb0(%[[TARGET:[^:]+]]: !quantum.qubit<1>):
// CHECK: %[[PHASE:.*]] = "quantum.P"(%[[TARGET]], %[[ANGLE]])
// CHECK: "quantum.yield"(%[[PHASE]])
// CHECK: "quantum.H"(%[[CTRL]]#0)
// CHECK: "quantum.X"(%[[CTRL]]#1)

// -----

// Explicit and chained positive controls prepend operands in source order.
OPENQASM 3.0;
const int count = 1 + 1;
qubit[4] q;
ctrl(count) @ x q[0], q[1], q[2];
ctrl @ ctrl(2) @ x q[0], q[1], q[2], q[3];

// CHECK-LABEL: module {
// CHECK: %[[FIRST:.*]]:3 = "quantum.ctrl"(%{{.*}}) <{nctrls = 2 : index}>
// CHECK: ^bb0(%[[TARGET:[^:]+]]: !quantum.qubit<1>):
// CHECK: %[[X:.*]] = "quantum.X"(%[[TARGET]])
// CHECK: "quantum.yield"(%[[X]])
// CHECK: %[[SECOND:.*]]:4 = "quantum.ctrl"(%[[FIRST]]#0, %[[FIRST]]#1, %[[FIRST]]#2, %{{.*}}) <{nctrls = 3 : index}>
// CHECK: ^bb0(%[[TARGET2:[^:]+]]: !quantum.qubit<1>):
// CHECK: %[[X2:.*]] = "quantum.X"(%[[TARGET2]])
// CHECK: "quantum.yield"(%[[X2]])

// -----

// Each broadcast iteration uses the target state returned by the previous one.
OPENQASM 3.0;
qubit[2] controls;
qubit target;
ctrl @ x controls, target;
h target;
h controls;

// CHECK-LABEL: module {
// CHECK: %[[CONTROLS:.*]] = "quantum.alloc"() : () -> !quantum.qubit<2>
// CHECK: %[[TARGET:.*]] = "quantum.alloc"() : () -> !quantum.qubit<1>
// CHECK: %[[SPLIT:.*]]:2 = "quantum.split"(%[[CONTROLS]])
// CHECK: %[[FIRST:.*]]:2 = "quantum.ctrl"(%[[SPLIT]]#0, %[[TARGET]])
// CHECK: "quantum.yield"
// CHECK: %[[SECOND:.*]]:2 = "quantum.ctrl"(%[[SPLIT]]#1, %[[FIRST]]#1)
// CHECK: "quantum.yield"
// CHECK: "quantum.H"(%[[SECOND]]#1)
// CHECK: %[[MERGED:.*]] = "quantum.merge"(%[[FIRST]]#0, %[[SECOND]]#0)
// CHECK: "quantum.H"(%[[MERGED]])

// -----

// Broadcast disjoint selections of a single register without rebinding its name.
OPENQASM 3.0;
qubit[4] q;
ctrl @ x q[0:1], q[2:3];

// CHECK-LABEL: module {
// CHECK: "quantum.ctrl"
// CHECK: "quantum.yield"
// CHECK: "quantum.ctrl"
// CHECK: "quantum.yield"

// -----

// Deferred custom gates capture classical parameters, never outer qubit values.
OPENQASM 3.0;
gate userPhase(theta) a { p(theta) a; }
gate controlledPhase(theta) a, b { ctrl @ userPhase(theta) a, b; }
qubit[2] q;
controlledPhase(0.5) q[0], q[1];

// CHECK-LABEL: module {
// CHECK: sym_name = "controlledPhase"
// CHECK: ^bb0(%[[CONTROL:[^:]+]]: !quantum.qubit<1>, %[[TARGET:[^:]+]]: !quantum.qubit<1>, %[[ANGLE:[^:]+]]: f64):
// CHECK: %[[CTRL:.*]]:2 = "quantum.ctrl"(%[[CONTROL]], %[[TARGET]])
// CHECK: ^bb0(%[[ARG:[^:]+]]: !quantum.qubit<1>):
// CHECK: %[[CALL:.*]] = "quantum.call"(%[[ARG]], %[[ANGLE]]) <{callee = @userPhase}>
// CHECK: "quantum.yield"(%[[CALL]])
// CHECK: "quantum.return"(%[[CTRL]]#0, %[[CTRL]]#1)
// CHECK: sym_name = "userPhase"
// CHECK: "qpu.circuit"
// CHECK: callee = @controlledPhase
