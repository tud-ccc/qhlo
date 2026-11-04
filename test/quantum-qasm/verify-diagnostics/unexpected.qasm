// RUN: not quantum-qasm %s -verify-diagnostics 2>&1 | FileCheck %s

// Diagnostics without a matching expectation must fail verification.
// CHECK: unexpected error: unknown quantum register 'missing'

OPENQASM 3.0;
h missing;
