// RUN: split-file %s %t
// RUN: not quantum-qasm %t/source-index.qasm 2>&1 | FileCheck %s --check-prefix=INDEX
// RUN: not quantum-qasm %t/destination-index.qasm 2>&1 | FileCheck %s --check-prefix=INDEX
// RUN: not quantum-qasm %t/range.qasm 2>&1 | FileCheck %s --check-prefix=RANGE
// RUN: not quantum-qasm %t/size.qasm 2>&1 | FileCheck %s --check-prefix=SIZE
// RUN: not quantum-qasm %t/hardware.qasm 2>&1 | FileCheck %s --check-prefix=HARDWARE
// RUN: not quantum-qasm %t/assignment-index.qasm 2>&1 | FileCheck %s --check-prefix=INDEX
// RUN: not quantum-qasm %t/compound-add.qasm 2>&1 | FileCheck %s --check-prefix=COMPOUND
// RUN: not quantum-qasm %t/compound-xor.qasm 2>&1 | FileCheck %s --check-prefix=COMPOUND
// RUN: not quantum-qasm %t/classical.qasm 2>&1 | FileCheck %s --check-prefix=CLASSICAL
// RUN: not quantum-qasm %t/quantum-call.qasm 2>&1 | FileCheck %s --check-prefix=CALL

// INDEX: error: expected a constant measurement index within the register
// RANGE: error: range step must not be zero
// SIZE: error: measurement source and destination sizes must match
// HARDWARE: error: hardware qubit operands are not supported

//--- source-index.qasm
OPENQASM 3.0;
qubit[2] q;
bit c;
measure q[2] -> c;

//--- destination-index.qasm
OPENQASM 3.0;
qubit q;
bit[2] c;
measure q -> c[2];

//--- range.qasm
OPENQASM 3.0;
qubit[2] q;
bit[2] c;
measure q[0:0:1] -> c;

//--- size.qasm
OPENQASM 3.0;
qubit[2] q;
bit c;
measure q -> c;

//--- hardware.qasm
OPENQASM 3.0;
measure $0;

// COMPOUND: error: compound assignment operators are not supported
// COMPOUND-NOT: qpu.module
// CLASSICAL: error: classical expression assignments are not supported
// CALL: error: quantum call assignments are not supported

//--- assignment-index.qasm
OPENQASM 3.0;
qubit q;
bit[2] c;
c[2] = measure q;

//--- compound-add.qasm
OPENQASM 3.0;
qubit q;
bit c;
c += measure q;

//--- compound-xor.qasm
OPENQASM 3.0;
qubit q;
bit c;
c ^= measure q;

//--- classical.qasm
OPENQASM 3.0;
bit c;
c = 0;

//--- quantum-call.qasm
OPENQASM 3.0;
qubit q;
bit c;
c = foo() q;
