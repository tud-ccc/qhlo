// RUN: not quantum-qasm %s 2>&1 | FileCheck %s
OPENQASM 2.0;
qreg q[1];
barrier q[1];
// CHECK-NOT: qpu.module
// CHECK: loc("{{.*}}barrier-invalid.qasm":{{[0-9]+}}:{{[0-9]+}}): error: invalid or out-of-range qubit index
// CHECK-NOT: qpu.module
