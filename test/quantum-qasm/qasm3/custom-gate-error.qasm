// RUN: not quantum-qasm %s 2>&1 | FileCheck %s
OPENQASM 3.0;
gate broken a { h missing; }
qubit q;
broken q;
// CHECK: error: unknown quantum register 'missing'
// CHECK-NOT: qpu.module
