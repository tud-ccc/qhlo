// RUN: split-file %s %t
// RUN: not quantum-qasm %t/quantum.qasm 2>&1 | FileCheck %s
// RUN: not quantum-qasm %t/classical.qasm 2>&1 | FileCheck %s
// RUN: not quantum-qasm %t/quantum-classical.qasm 2>&1 | FileCheck %s
// RUN: not quantum-qasm %t/classical-quantum.qasm 2>&1 | FileCheck %s
// RUN: not quantum-qasm %t/gate-parameters.qasm 2>&1 | FileCheck %s
// RUN: not quantum-qasm %t/gate-qubits.qasm 2>&1 | FileCheck %s
// RUN: not quantum-qasm %t/gate-parameter-qubit.qasm 2>&1 | FileCheck %s

// CHECK: error: redefinition of 'q'
// CHECK-NOT: error:
// CHECK-NOT: qpu.module

//--- quantum.qasm
OPENQASM 3.0;
qubit[2] q;
qubit[2] q;

//--- classical.qasm
OPENQASM 3.0;
bit[2] q;
bit[2] q;

//--- quantum-classical.qasm
OPENQASM 3.0;
qubit[2] q;
bit[2] q;

//--- classical-quantum.qasm
OPENQASM 3.0;
bit[2] q;
qubit[2] q;

//--- gate-parameters.qasm
OPENQASM 3.0;
gate g(q, q) a {}
qubit[2] q;
g(1, 2) q[0];

//--- gate-qubits.qasm
OPENQASM 3.0;
gate g q, q {}
qubit[2] q;
g q[0], q[1];

//--- gate-parameter-qubit.qasm
OPENQASM 3.0;
gate g(q) q {}
qubit[2] q;
g(1) q[0];
