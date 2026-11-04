// RUN: quantum-qasm %s -split-input-file | quantum-opt -split-input-file --verify-linearity | \
// RUN:   FileCheck %s --enable-var-scope

// Contiguous.
// CHECK-LABEL: module {
OPENQASM 3.0;
qubit[8] q;
barrier q[0:3];
h q[2:5];
barrier q;
reset q[5:-1:2];

// CHECK: %[[Q:.*]] = "quantum.alloc"() : () -> !quantum.qubit<8>
// CHECK-NEXT: %[[HALVES:.*]]:2 = "quantum.split"(%[[Q]]) : (!quantum.qubit<8>) -> (!quantum.qubit<4>, !quantum.qubit<4>)
// CHECK-NEXT: %[[LEFT:.*]] = "quantum.barrier"(%[[HALVES]]#0)
// CHECK-NEXT: %[[A:.*]]:2 = "quantum.split"(%[[LEFT]]) : (!quantum.qubit<4>) -> (!quantum.qubit<2>, !quantum.qubit<2>)
// CHECK-NEXT: %[[B:.*]]:2 = "quantum.split"(%[[HALVES]]#1) : (!quantum.qubit<4>) -> (!quantum.qubit<2>, !quantum.qubit<2>)
// CHECK-NEXT: %[[SELECTED:.*]] = "quantum.merge"(%[[A]]#1, %[[B]]#0)
// CHECK-NEXT: %[[H:.*]] = "quantum.H"(%[[SELECTED]]) : (!quantum.qubit<4>) -> !quantum.qubit<4>
// CHECK-NEXT: %[[BARRIER:.*]]:3 = "quantum.barrier"(%[[A]]#0, %[[H]], %[[B]]#1)
// CHECK-NEXT: "quantum.reset"(%[[BARRIER]]#1) : (!quantum.qubit<4>)
// CHECK-NOT: "quantum.split"

// -----

// Stepped.
// CHECK-LABEL: module {
OPENQASM 3.0;
qubit[6] q;
bit[6] c;
h q[5:-2:1];
cx q[1:2:5], q[0:2:4];
measure q[5:-2:1] -> c[1:2:5];
c[5:-2:1] = measure q[0:2:4];

// CHECK: "quantum.merge"
// CHECK: "quantum.H"{{.*}} : (!quantum.qubit<3>)
// CHECK: "quantum.split"{{.*}} : (!quantum.qubit<3>) -> (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>)
// CHECK-COUNT-3: "quantum.CNOT"
// CHECK: "quantum.measure"{{.*}} : (!quantum.qubit<3>) -> (!quantum.measurement<3>, !quantum.qubit<3>)
// CHECK: tensor.insert_slice {{.*}}[1] [3] [2]
// CHECK: "quantum.measure"{{.*}} : (!quantum.qubit<3>) -> (!quantum.measurement<3>, !quantum.qubit<3>)
// CHECK: tensor.extract_slice {{.*}}[0] [1] [1]
// CHECK-NEXT: tensor.insert_slice {{.*}}[5] [1] [1]
// CHECK-NEXT: tensor.extract_slice {{.*}}[1] [1] [1]
// CHECK-NEXT: tensor.insert_slice {{.*}}[3] [1] [1]
// CHECK-NEXT: tensor.extract_slice {{.*}}[2] [1] [1]
// CHECK-NEXT: tensor.insert_slice {{.*}}[1] [1] [1]

// -----

// Broadcast.
// CHECK-LABEL: module {
OPENQASM 3.0;
qubit control;
qubit[5] q;
cx control, q[0:2:4];
barrier q[0:3], q[2:4];

// CHECK: %[[CONTROL:.*]] = "quantum.alloc"() : () -> !quantum.qubit<1>
// CHECK: %[[C0:.*]], %{{.*}} = "quantum.CNOT"(%[[CONTROL]],
// CHECK: %[[C1:.*]], %{{.*}} = "quantum.CNOT"(%[[C0]],
// CHECK: %[[C2:.*]], %{{.*}} = "quantum.CNOT"(%[[C1]],
// CHECK: "quantum.barrier"{{.*}} : (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>)

// -----

// Custom.
// CHECK-LABEL: module {
OPENQASM 3.0;
gate rotate(theta) a { rx(theta) a; }
qubit[3] q;
rotate(1) q[2:-1:0];

// CHECK: sym_name = "rotate"
// CHECK-COUNT-3: "quantum.call"

// -----

// Defaults.
// CHECK-LABEL: module {
OPENQASM 3.0;
qubit[6] q;
bit[6] c;
h q[:];
reset q[:3];
reset q[4:];
measure q[:-1:0] -> c[:];
h q[(1 + 1):2:(5 - 1)];
reset q[-2:-1];

// CHECK: "quantum.H"{{.*}} : (!quantum.qubit<6>)
// CHECK: "quantum.reset"{{.*}} : (!quantum.qubit<4>)
// CHECK: "quantum.reset"{{.*}} : (!quantum.qubit<2>)
// CHECK: "quantum.measure"{{.*}} : (!quantum.qubit<6>) -> (!quantum.measurement<6>, !quantum.qubit<6>)
// CHECK: "quantum.H"{{.*}} : (!quantum.qubit<2>)
