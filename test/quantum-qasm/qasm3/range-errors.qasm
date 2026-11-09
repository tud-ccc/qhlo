// RUN: quantum-qasm %s -split-input-file -verify-diagnostics
// RUN: not quantum-qasm %s -split-input-file 2>&1 | FileCheck %s --check-prefix=NO-IR

// NO-IR-NOT: qpu.module

// Zero step.
OPENQASM 3.0;
qubit[4] q;
// expected-error @+1 {{range step must not be zero}}
h q[0:0:3];

// -----

// Empty.
OPENQASM 3.0;
qubit[4] q;
// expected-error @+1 {{register selection must not be empty}}
reset q[3:0];

// -----

// Endpoint.
OPENQASM 3.0;
qubit[4] q;
// expected-error @+1 {{range endpoints must be within the register}}
barrier q[0:4];

// -----

// Negative endpoint.
OPENQASM 3.0;
qubit[4] q;
// expected-error @+1 {{range endpoints must be within the register}}
reset q[-5:-1];

// -----

// Float step.
OPENQASM 3.0;
qubit[4] q;
// expected-error @+1 {{expected a constant integer expression}}
h q[0:1.5:3];

// -----

// Runtime step.
OPENQASM 3.0;
qubit[4] q;
bit[4] c;
// expected-error @+1 {{expected a compile-time constant}}
h q[0:c:3];

// -----

// Unknown.
OPENQASM 3.0;
qubit[4] q;
// expected-error @+1 {{unknown identifier 'missing'}}
h q[missing:3];

// -----

// Multiple.
OPENQASM 3.0;
qubit[4] q;
// expected-error @+1 {{expected a single constant qubit index or range}}
barrier q[0:1,2:3];

// -----

// Set.
OPENQASM 3.0;
qubit[4] q;
// expected-error @+1 {{expected a single constant qubit index or range}}
reset q[{0,2}];

// -----

// Missing step.
OPENQASM 3.0;
qubit[4] q;
// expected-error @+1 {{expected a constant range step}}
reset q[0::3];

// -----

// Broadcast size.
OPENQASM 3.0;
qubit[4] q;
qubit[4] r;
// expected-error @+1 {{broadcast register operands must have equal lengths}}
cx q[0:1], r[0:2];

// -----

// One element slice.
OPENQASM 3.0;
qubit[4] q;
qubit[4] r;
// expected-error @+1 {{broadcast register operands must have equal lengths}}
cx q[0:0], r[0:2];

// -----

// One element register.
OPENQASM 3.0;
qubit[4] q;
qubit[1] single;
// expected-error @+1 {{broadcast register operands must have equal lengths}}
cx single, q[0:2];

// -----

// Alias.
OPENQASM 3.0;
qubit[4] q;
// expected-error @+1 {{gate operands must refer to distinct qubits}}
cx q[0:2], q[0:2];

// -----

// Measurement size.
OPENQASM 3.0;
qubit[4] q;
bit[4] c;
// expected-error @+1 {{measurement source and destination sizes must match}}
measure q[0:2] -> c[0:1];

// -----

// Overflow.
OPENQASM 3.0;
qubit[4] q;
// expected-error @+1 {{constant integer expression overflows int64}}
h q[(9223372036854775807 + 1):3];

// -----

// Division zero.
OPENQASM 3.0;
qubit[4] q;
bit[4] c;
// expected-error @+1 {{division by zero in constant integer expression}}
measure q[(1 / 0):3] -> c;

// -----

// Folding to a floating-point value must not make an expression a valid index.
OPENQASM 3.0;
qubit[4] q;
// expected-error @+1 {{expected a constant integer expression}}
h q[pi / 2];
