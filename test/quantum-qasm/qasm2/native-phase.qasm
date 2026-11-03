// RUN: quantum-qasm %s | quantum-opt | FileCheck %s
OPENQASM 2.0;
qreg q[1];
p(1) q[0];
// CHECK: "quantum.P"({{.*}}) : (!quantum.qubit<1>, f64) -> !quantum.qubit<1>
