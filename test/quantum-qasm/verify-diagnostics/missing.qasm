// RUN: not quantum-qasm %s -verify-diagnostics 2>&1 | FileCheck %s

// This valid program emits no errors. The verifier must reject an unfulfilled
// expectation, even when compilation succeeds.
// CHECK: expected error "deliberately absent diagnostic" was not produced

OPENQASM 3.0;
qubit q;
// expected-error @+1 {{deliberately absent diagnostic}}
h q;
