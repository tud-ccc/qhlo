// RUN: quantum-qasm %s -verify-diagnostics
// RUN: quantum-qasm %s -split-input-file -verify-diagnostics

// Verification must resolve includes relative to the physical source file,
// even when split-input-file assigns a synthetic name to the chunk.
OPENQASM 2.0;
include "Inputs/relative-gate.inc";
qreg q[1];
local q[0];
// expected-error @+1 {{unknown quantum register 'missing'}}
reset missing[0];
