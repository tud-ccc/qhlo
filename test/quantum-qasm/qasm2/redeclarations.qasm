// RUN: quantum-qasm %s -split-input-file -verify-diagnostics
// RUN: not quantum-qasm %s -split-input-file 2>&1 | FileCheck %s --check-prefix=NO-IR

// NO-IR-NOT: qpu.module

// Quantum.
OPENQASM 2.0;
qreg q[2];
// expected-error @+1 {{redefinition of 'q'}}
qreg q[2];

// -----

// Classical.
OPENQASM 2.0;
creg q[2];
// expected-error @+1 {{redefinition of 'q'}}
creg q[2];

// -----

// Quantum classical.
OPENQASM 2.0;
qreg q[2];
// expected-error @+1 {{redefinition of 'q'}}
creg q[2];

// -----

// Classical quantum.
OPENQASM 2.0;
creg q[2];
// expected-error @+1 {{redefinition of 'q'}}
qreg q[2];

// -----

// Gate parameters.
OPENQASM 2.0;
gate g(q, q) a {}
qreg q[2];
// expected-error @+1 {{redefinition of 'q'}}
g(1, 2) q[0];

// -----

// Gate qubits.
OPENQASM 2.0;
gate g q, q {}
qreg q[2];
// expected-error @+1 {{redefinition of 'q'}}
g q[0], q[1];

// -----

// Gate parameter qubit.
OPENQASM 2.0;
gate g(q) q {}
qreg q[2];
// expected-error @+1 {{redefinition of 'q'}}
g(1) q[0];
