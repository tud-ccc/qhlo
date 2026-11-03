// RUN: not quantum-qasm %s 2>&1 | FileCheck %s
OPENQASM 3.0;
qubit q;
p q;
// CHECK: error: expected 1 qubit operands and 1 parameters, got 1 and 0
// CHECK-NOT: qpu.module
