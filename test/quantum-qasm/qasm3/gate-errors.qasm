// RUN: quantum-qasm %s -split-input-file -verify-diagnostics
// RUN: not quantum-qasm %s -split-input-file 2>&1 | FileCheck %s --check-prefix=NO-IR
// NO-IR-NOT: qpu.module

// A failure in a deferred gate body must fail the whole translation.
OPENQASM 3.0;
// expected-error @+1 {{unknown quantum register 'missing'}}
gate broken a { h missing; }
qubit q;
broken q;

// -----

OPENQASM 3.0;
qubit q;
// expected-error @+1 {{expected 1 qubit operands and 1 parameters, got 1 and 0}}
p q;

// -----

// Exercise the shared error listener through the QASM3 parser adapter.
OPENQASM 3.0;
// expected-error @+2 {{missing ';' at '<EOF>'}}
qubit q
