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
OPENQASM 2.0;
qreg q[2];
qreg q[2];

//--- classical.qasm
OPENQASM 2.0;
creg q[2];
creg q[2];

//--- quantum-classical.qasm
OPENQASM 2.0;
qreg q[2];
creg q[2];

//--- classical-quantum.qasm
OPENQASM 2.0;
creg q[2];
qreg q[2];

//--- gate-parameters.qasm
OPENQASM 2.0;
gate g(q, q) a {}
qreg q[2];
g(1, 2) q[0];

//--- gate-qubits.qasm
OPENQASM 2.0;
gate g q, q {}
qreg q[2];
g q[0], q[1];

//--- gate-parameter-qubit.qasm
OPENQASM 2.0;
gate g(q) q {}
qreg q[2];
g(1) q[0];
