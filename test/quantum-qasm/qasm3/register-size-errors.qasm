// RUN: quantum-qasm %s -split-input-file -verify-diagnostics
// RUN: not quantum-qasm %s -split-input-file 2>&1 | FileCheck %s --check-prefix=NO-IR

// NO-IR-NOT: qpu.module

// Zero-length quantum registers.
OPENQASM 3.0;
// expected-error @+1 {{register length must be a positive unsigned integer}}
qubit[0] q;

// -----

// Zero-length classical registers.
OPENQASM 3.0;
// expected-error @+1 {{register length must be a positive unsigned integer}}
bit[0] q;

// -----

// Oversized quantum registers.
OPENQASM 3.0;
// expected-error @+1 {{register length must be a positive unsigned integer}}
qubit[4294967296] q;

// -----

// Oversized classical registers.
OPENQASM 3.0;
// expected-error @+1 {{register length must be a positive unsigned integer}}
bit[4294967296] q;

// -----

// Negative-length quantum registers.
OPENQASM 3.0;
// expected-error @+1 {{expected a constant integer register length}}
qubit[-1] q;

// -----

// Negative-length classical registers.
OPENQASM 3.0;
// expected-error @+1 {{expected a constant integer register length}}
bit[-1] q;

// -----

// Compound-expression quantum registers.
OPENQASM 3.0;
// expected-error @+1 {{expected a constant integer register length}}
qubit[1 + 2] q;

// -----

// Compound-expression classical registers.
OPENQASM 3.0;
// expected-error @+1 {{expected a constant integer register length}}
bit[1 + 2] q;

// -----

// Noninteger quantum registers.
OPENQASM 3.0;
// expected-error @+1 {{expected a constant integer register length}}
qubit[1.5] q;

// -----

// Noninteger classical registers.
OPENQASM 3.0;
// expected-error @+1 {{expected a constant integer register length}}
bit[1.5] q;

// -----

// Unknown quantum registers.
OPENQASM 3.0;
// expected-error @+1 {{unknown identifier 'missing'}}
qubit[missing] q;

// -----

// Unknown classical registers.
OPENQASM 3.0;
// expected-error @+1 {{unknown identifier 'missing'}}
bit[missing] q;

// -----

// Overflowing integer literal in quantum registers.
OPENQASM 3.0;
// expected-error @+1 {{invalid numeric literal '9223372036854775808'}}
qubit[9223372036854775808] q;

// -----

// Overflowing integer literal in classical registers.
OPENQASM 3.0;
// expected-error @+1 {{invalid numeric literal '9223372036854775808'}}
bit[9223372036854775808] q;
