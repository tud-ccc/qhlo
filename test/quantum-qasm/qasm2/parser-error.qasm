// RUN: not quantum-qasm %s 2>&1 | FileCheck %s
// A recovered parse tree must not be lowered after a syntax error.
OPENQASM 2.0;
qreg q[1]
// CHECK-NOT: qpu.module
// CHECK: loc("{{.*}}parser-error.qasm":{{[0-9]+}}:{{[0-9]+}}): error: missing ';' at '<EOF>'
// CHECK-NOT: qpu.module
