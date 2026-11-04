// RUN: quantum-qasm %s -split-input-file -verify-diagnostics
// RUN: not quantum-qasm %s -split-input-file 2>&1 | FileCheck %s --check-prefix=NO-IR

// NO-IR-NOT: qpu.module

// Quantum.
OPENQASM 3.0;
qubit[2] q;
// expected-error @+1 {{redefinition of 'q'}}
qubit[2] q;

// -----

// Classical.
OPENQASM 3.0;
bit[2] q;
// expected-error @+1 {{redefinition of 'q'}}
bit[2] q;

// -----

// Quantum classical.
OPENQASM 3.0;
qubit[2] q;
// expected-error @+1 {{redefinition of 'q'}}
bit[2] q;

// -----

// Classical quantum.
OPENQASM 3.0;
bit[2] q;
// expected-error @+1 {{redefinition of 'q'}}
qubit[2] q;

// -----

// Gate parameters.
OPENQASM 3.0;
gate g(q, q) a {}
qubit[2] q;
// expected-error @+1 {{redefinition of 'q'}}
g(1, 2) q[0];

// -----

// Gate qubits.
OPENQASM 3.0;
gate g q, q {}
qubit[2] q;
// expected-error @+1 {{redefinition of 'q'}}
g q[0], q[1];

// -----

// Gate parameter qubit.
OPENQASM 3.0;
gate g(q) q {}
qubit[2] q;
// expected-error @+1 {{redefinition of 'q'}}
g(1) q[0];
