// RUN: quantum-qasm %s -verify-diagnostics
// RUN: quantum-qasm -verify-diagnostics < %s
// RUN: not quantum-qasm %s 2>&1 | FileCheck %s

// Verification accepts the same expected error from a file or stdin.
// Ordinary compilation must still fail despite the expected-error comment.
// CHECK: error: unknown quantum register 'missing'

OPENQASM 3.0;
// expected-error @+1 {{unknown quantum register 'missing'}}
h missing;
