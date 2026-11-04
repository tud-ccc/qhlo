// RUN: not quantum-qasm %s -verify-diagnostics 2>&1 | FileCheck %s

// Matching text on the wrong source line must fail verification.
// CHECK: unexpected error: unknown quantum register 'missing'
// CHECK: expected error "unknown quantum register 'missing'" was not produced

OPENQASM 3.0;
// expected-error @+1 {{unknown quantum register 'missing'}}
qubit q;
h missing;
