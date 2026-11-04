// RUN: quantum-qasm %s | FileCheck %s

OPENQASM 3.0;
qubit q;
qubit[((2))] qs;
bit c;
bit[((2))] cs;

// CHECK: !quantum.qubit<1>
// CHECK: !quantum.qubit<2>
// CHECK: tensor<1xi1>
// CHECK: tensor<2xi1>
