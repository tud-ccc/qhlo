// RUN: not quantum-qasm %s 2>&1 | FileCheck %s
// Exercise the shared error listener through the QASM3 parser adapter.
OPENQASM 3.0;
qubit q
// CHECK: error: missing ';' at '<EOF>'
// CHECK-NOT: qpu.module
