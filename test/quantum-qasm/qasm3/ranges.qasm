// RUN: split-file %s %t
// RUN: quantum-qasm %t/contiguous.qasm | FileCheck %s --check-prefix=CONTIGUOUS
// RUN: quantum-qasm %t/stepped.qasm | FileCheck %s --check-prefix=STEPPED
// RUN: quantum-qasm %t/broadcast.qasm | FileCheck %s --check-prefix=BROADCAST
// RUN: quantum-qasm %t/custom.qasm | FileCheck %s --check-prefix=CUSTOM
// RUN: quantum-qasm %t/defaults.qasm | FileCheck %s --check-prefix=DEFAULTS
// RUN: quantum-qasm %t/contiguous.qasm | quantum-opt --verify-linearity > /dev/null
// RUN: quantum-qasm %t/stepped.qasm | quantum-opt --verify-linearity > /dev/null
// RUN: quantum-qasm %t/broadcast.qasm | quantum-opt --verify-linearity > /dev/null
// RUN: quantum-qasm %t/custom.qasm | quantum-opt --verify-linearity > /dev/null

//--- contiguous.qasm
OPENQASM 3.0;
qubit[8] q;
barrier q[0:3];
h q[2:5];
barrier q;
reset q[5:-1:2];

// CONTIGUOUS: %[[Q:.*]] = "quantum.alloc"() : () -> !quantum.qubit<8>
// CONTIGUOUS-NEXT: %[[HALVES:.*]]:2 = "quantum.split"(%[[Q]]) : (!quantum.qubit<8>) -> (!quantum.qubit<4>, !quantum.qubit<4>)
// CONTIGUOUS-NEXT: %[[LEFT:.*]] = "quantum.barrier"(%[[HALVES]]#0)
// CONTIGUOUS-NEXT: %[[A:.*]]:2 = "quantum.split"(%[[LEFT]]) : (!quantum.qubit<4>) -> (!quantum.qubit<2>, !quantum.qubit<2>)
// CONTIGUOUS-NEXT: %[[B:.*]]:2 = "quantum.split"(%[[HALVES]]#1) : (!quantum.qubit<4>) -> (!quantum.qubit<2>, !quantum.qubit<2>)
// CONTIGUOUS-NEXT: %[[SELECTED:.*]] = "quantum.merge"(%[[A]]#1, %[[B]]#0)
// CONTIGUOUS-NEXT: %[[H:.*]] = "quantum.H"(%[[SELECTED]]) : (!quantum.qubit<4>) -> !quantum.qubit<4>
// CONTIGUOUS-NEXT: %[[BARRIER:.*]]:3 = "quantum.barrier"(%[[A]]#0, %[[H]], %[[B]]#1)
// CONTIGUOUS-NEXT: "quantum.reset"(%[[BARRIER]]#1) : (!quantum.qubit<4>)
// CONTIGUOUS-NOT: "quantum.split"

//--- stepped.qasm
OPENQASM 3.0;
qubit[6] q;
bit[6] c;
h q[5:-2:1];
cx q[1:2:5], q[0:2:4];
measure q[5:-2:1] -> c[1:2:5];
c[5:-2:1] = measure q[0:2:4];

// STEPPED: "quantum.merge"
// STEPPED: "quantum.H"{{.*}} : (!quantum.qubit<3>)
// STEPPED: "quantum.split"{{.*}} : (!quantum.qubit<3>) -> (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>)
// STEPPED-COUNT-3: "quantum.CNOT"
// STEPPED: "quantum.measure"{{.*}} : (!quantum.qubit<3>) -> (!quantum.measurement<3>, !quantum.qubit<3>)
// STEPPED: tensor.insert_slice {{.*}}[1] [3] [2]
// STEPPED: "quantum.measure"{{.*}} : (!quantum.qubit<3>) -> (!quantum.measurement<3>, !quantum.qubit<3>)
// STEPPED: tensor.extract_slice {{.*}}[0] [1] [1]
// STEPPED-NEXT: tensor.insert_slice {{.*}}[5] [1] [1]
// STEPPED-NEXT: tensor.extract_slice {{.*}}[1] [1] [1]
// STEPPED-NEXT: tensor.insert_slice {{.*}}[3] [1] [1]
// STEPPED-NEXT: tensor.extract_slice {{.*}}[2] [1] [1]
// STEPPED-NEXT: tensor.insert_slice {{.*}}[1] [1] [1]

//--- broadcast.qasm
OPENQASM 3.0;
qubit control;
qubit[5] q;
cx control, q[0:2:4];
barrier q[0:3], q[2:4];

// BROADCAST: %[[CONTROL:.*]] = "quantum.alloc"() : () -> !quantum.qubit<1>
// BROADCAST: %[[C0:.*]], %{{.*}} = "quantum.CNOT"(%[[CONTROL]],
// BROADCAST: %[[C1:.*]], %{{.*}} = "quantum.CNOT"(%[[C0]],
// BROADCAST: %[[C2:.*]], %{{.*}} = "quantum.CNOT"(%[[C1]],
// BROADCAST: "quantum.barrier"{{.*}} : (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>)

//--- custom.qasm
OPENQASM 3.0;
gate rotate(theta) a { rx(theta) a; }
qubit[3] q;
rotate(1) q[2:-1:0];

// CUSTOM: sym_name = "rotate"
// CUSTOM-COUNT-3: "quantum.call"

//--- defaults.qasm
OPENQASM 3.0;
qubit[6] q;
bit[6] c;
h q[:];
reset q[:3];
reset q[4:];
measure q[:-1:0] -> c[:];
h q[(1 + 1):2:(5 - 1)];
reset q[-2:-1];

// DEFAULTS: "quantum.H"{{.*}} : (!quantum.qubit<6>)
// DEFAULTS: "quantum.reset"{{.*}} : (!quantum.qubit<4>)
// DEFAULTS: "quantum.reset"{{.*}} : (!quantum.qubit<2>)
// DEFAULTS: "quantum.measure"{{.*}} : (!quantum.qubit<6>) -> (!quantum.measurement<6>, !quantum.qubit<6>)
// DEFAULTS: "quantum.H"{{.*}} : (!quantum.qubit<2>)
