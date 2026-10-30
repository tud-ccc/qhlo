// RUN: not quantum-qasm -split-input-file %s 2>&1 | FileCheck %s --implicit-check-not=qpu.module

// Missing includes must fail the translation, not just emit a diagnostic.
OPENQASM 2.0;
include "missing-qasm2-review-test.inc";
// CHECK: error: failed to resolve include 'missing-qasm2-review-test.inc':

// -----

OPENQASM 2.0;
gate g a { U(0,0,0) a; }
gate g a { U(0,0,0) a; }
// CHECK: error: gate 'g' already defined

// -----

OPENQASM 2.0;
opaque g a;
// CHECK: error: opaque gate declarations are unsupported

// -----

// A comparison must never silently truncate to a different integer.
OPENQASM 2.0;
qreg q[1];
creg c[1];
measure q[0] -> c[0];
if(c==2) reset q[0];
// CHECK: error: comparison literal does not fit in the classical register

// -----

OPENQASM 2.0;
gate g a,b { CX a,b; }
qreg q[1];
g q[0];
// CHECK: error: gate 'g' expects 2 qubit operands and 0 parameters

// -----

OPENQASM 2.0;
gate g(theta) a { U(theta,0,0) a; }
qreg q[1];
g q[0];
// CHECK: error: gate 'g' expects 1 qubit operands and 1 parameters

// -----

OPENQASM 2.0;
gate g(theta) a { U(theta,0,0) a; }
qreg q[1];
g(1,2) q[0];
// CHECK: error: gate 'g' expects 1 qubit operands and 1 parameters

// -----

OPENQASM 2.0;
gate g a { U(0,0,0) a; }
qreg q[2];
g q;
// CHECK: error: custom gate operands must be individual qubits

// -----

OPENQASM 2.0;
gate g(theta) a { U(theta,0,0) a; }
qreg q[1];
creg c[1];
measure q[0] -> c[0];
g(sin(c)) q[0];
// CHECK: error: gate parameters must have type f64

// -----

// Conditional operand preparation must propagate the specific diagnostic once.
OPENQASM 2.0;
qreg q[1];
creg c[1];
measure q[0] -> c[0];
if(c==1) reset missing[0];
// CHECK: error: unknown quantum register 'missing'
// CHECK-NOT: error:

// -----

OPENQASM 2.0;
qreg q[999999999999999999999999999999999999];
// CHECK: error: invalid integer literal '999999999999999999999999999999999999'
// CHECK-NOT: error:

// -----

OPENQASM 2.0;
qreg q[1];
reset q[999999999999999999999999999999999999];
// CHECK: error: invalid integer literal '999999999999999999999999999999999999'
// CHECK-NOT: error:
