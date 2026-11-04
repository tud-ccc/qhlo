// RUN: quantum-qasm %s -split-input-file -verify-diagnostics

// Each chunk has independent expectations and parser line numbers.
OPENQASM 2.0;
// expected-error @+1 {{unknown quantum register 'missing'}}
reset missing[0];

// -----

// A successful chunk must also verify when it has no expected errors.
OPENQASM 3.0;
qubit q;
h q;

// -----

OPENQASM 3.0;
// expected-error @+1 {{unknown quantum register 'missing'}}
h missing;

// -----

// Parser diagnostics use the same verifier as semantic diagnostics.
OPENQASM 3.0;
qubit q
// expected-error @+1 {{missing ';' at 'reset'}}
reset q;
