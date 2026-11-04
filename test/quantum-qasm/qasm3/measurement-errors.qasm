// RUN: quantum-qasm %s -split-input-file -verify-diagnostics
// RUN: not quantum-qasm %s -split-input-file 2>&1 | FileCheck %s --check-prefix=NO-IR

// NO-IR-NOT: qpu.module

// Source index.
OPENQASM 3.0;
qubit[2] q;
bit c;
// expected-error @+1 {{expected a constant measurement index within the register}}
measure q[2] -> c;

// -----

// Destination index.
OPENQASM 3.0;
qubit q;
bit[2] c;
// expected-error @+1 {{expected a constant measurement index within the register}}
measure q -> c[2];

// -----

// Range.
OPENQASM 3.0;
qubit[2] q;
bit[2] c;
// expected-error @+1 {{range step must not be zero}}
measure q[0:0:1] -> c;

// -----

// Size.
OPENQASM 3.0;
qubit[2] q;
bit c;
// expected-error @+1 {{measurement source and destination sizes must match}}
measure q -> c;

// -----

// Hardware.
OPENQASM 3.0;
// expected-error @+1 {{hardware qubit operands are not supported}}
measure $0;

// -----

// Assignment index.
OPENQASM 3.0;
qubit q;
bit[2] c;
// expected-error @+1 {{expected a constant measurement index within the register}}
c[2] = measure q;

// -----

// Compound add.
OPENQASM 3.0;
qubit q;
bit c;
// expected-error @+1 {{compound assignment operators are not supported}}
c += measure q;

// -----

// Compound xor.
OPENQASM 3.0;
qubit q;
bit c;
// expected-error @+1 {{compound assignment operators are not supported}}
c ^= measure q;

// -----

// Classical.
OPENQASM 3.0;
bit c;
// expected-error @+1 {{classical expression assignments are not supported}}
c = 0;

// -----

// Quantum call.
OPENQASM 3.0;
qubit q;
bit c;
// expected-error @+1 {{quantum call assignments are not supported}}
c = foo() q;
