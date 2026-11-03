// RUN: quantum-qasm %s | FileCheck %s
OPENQASM 3.0;
gate rotate(theta) a { rx(theta) a; }
gate outer(theta) a { rotate(theta) a; h a; }
gate identity a {}
qubit q;
outer(1) q;
outer(2) q;
identity q;
reset q;

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
