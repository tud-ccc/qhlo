// RUN: quantum-qasm %s | FileCheck %s
OPENQASM 3.0;
qubit[2] q;
h q[0];
cx q[0], q[1];
p(1) q[1];
cp(2) q[0], q[1];
U(1, 2, 3) q[0];
reset q;

// CHECK: %[[SPLIT:.*]]:2 = "quantum.split"
// CHECK: %[[H:.*]] = "quantum.H"(%[[SPLIT]]#0)
// CHECK: %[[CX:.*]]:2 = "quantum.CNOT"(%[[H]], %[[SPLIT]]#1)
// CHECK: %[[P:.*]] = "quantum.P"(%[[CX]]#1,
// CHECK: %[[CP:.*]]:2 = "quantum.CU1"(%[[CX]]#0, %[[P]],
// CHECK: %[[U:.*]] = "quantum.U3"(%[[CP]]#0,
// CHECK: "quantum.reset"(%[[U]])
// CHECK: "quantum.reset"(%[[CP]]#1)
