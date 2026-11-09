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

OPENQASM 3.0;
qubit q;
// expected-error @+1 {{control count must be a positive constant integer}}
ctrl(0) @ x q;

// -----

OPENQASM 3.0;
qubit q;
// expected-error @+1 {{control count must be a positive constant integer}}
ctrl(-1) @ x q;

// -----

OPENQASM 3.0;
qubit q;
// expected-error @+1 {{expected a constant integer expression}}
ctrl(1.5) @ x q;

// -----

OPENQASM 3.0;
int count = 1;
qubit q;
// expected-error @+1 {{expected a compile-time constant}}
ctrl(count) @ x q;

// -----

OPENQASM 3.0;
qubit q;
// expected-error @+1 {{control count is too large}}
ctrl(4294967296) @ x q;

// -----

OPENQASM 3.0;
qubit q;
// expected-error @+1 {{control count is too large}}
ctrl(4294967295) @ ctrl @ x q;

// -----

OPENQASM 3.0;
qubit q;
// expected-error @+1 {{expected 2 qubit operands and 0 parameters, got 1 and 0}}
ctrl @ x q;

// -----

OPENQASM 3.0;
qubit q;
// expected-error @+1 {{gate operands must refer to distinct qubits}}
ctrl @ x q, q;

// -----

OPENQASM 3.0;
qubit[2] controls;
qubit[3] targets;
// expected-error @+1 {{broadcast register operands must have equal lengths}}
ctrl @ x controls, targets;

// -----

OPENQASM 3.0;
qubit q;
// expected-error @+1 {{only ctrl gate modifiers are supported}}
negctrl @ x q;

// -----

OPENQASM 3.0;
qubit q;
// expected-error @+1 {{only ctrl gate modifiers are supported}}
inv @ x q;

// -----

OPENQASM 3.0;
qubit q;
// expected-error @+1 {{only ctrl gate modifiers are supported}}
pow(2) @ x q;

// -----

// Exercise the shared error listener through the QASM3 parser adapter.
OPENQASM 3.0;
// expected-error @+2 {{missing ';' at '<EOF>'}}
qubit q
