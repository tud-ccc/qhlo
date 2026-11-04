// RUN: split-file %s %t
// RUN: not quantum-qasm %t/zero-step.qasm 2>&1 | FileCheck %s --check-prefix=ZERO-STEP
// RUN: not quantum-qasm %t/empty.qasm 2>&1 | FileCheck %s --check-prefix=EMPTY
// RUN: not quantum-qasm %t/endpoint.qasm 2>&1 | FileCheck %s --check-prefix=ENDPOINT
// RUN: not quantum-qasm %t/negative-endpoint.qasm 2>&1 | FileCheck %s --check-prefix=NEGATIVE-ENDPOINT
// RUN: not quantum-qasm %t/float-step.qasm 2>&1 | FileCheck %s --check-prefix=FLOAT-STEP
// RUN: not quantum-qasm %t/runtime-step.qasm 2>&1 | FileCheck %s --check-prefix=RUNTIME-STEP
// RUN: not quantum-qasm %t/unknown.qasm 2>&1 | FileCheck %s --check-prefix=UNKNOWN
// RUN: not quantum-qasm %t/multiple.qasm 2>&1 | FileCheck %s --check-prefix=MULTIPLE
// RUN: not quantum-qasm %t/set.qasm 2>&1 | FileCheck %s --check-prefix=SET
// RUN: not quantum-qasm %t/missing-step.qasm 2>&1 | FileCheck %s --check-prefix=MISSING-STEP
// RUN: not quantum-qasm %t/broadcast-size.qasm 2>&1 | FileCheck %s --check-prefix=BROADCAST-SIZE
// RUN: not quantum-qasm %t/one-element-slice.qasm 2>&1 | FileCheck %s --check-prefix=ONE-ELEMENT-SLICE
// RUN: not quantum-qasm %t/one-element-register.qasm 2>&1 | FileCheck %s --check-prefix=ONE-ELEMENT-REGISTER
// RUN: not quantum-qasm %t/alias.qasm 2>&1 | FileCheck %s --check-prefix=ALIAS
// RUN: not quantum-qasm %t/measurement-size.qasm 2>&1 | FileCheck %s --check-prefix=MEASUREMENT-SIZE
// RUN: not quantum-qasm %t/overflow.qasm 2>&1 | FileCheck %s --check-prefix=OVERFLOW
// RUN: not quantum-qasm %t/division-zero.qasm 2>&1 | FileCheck %s --check-prefix=DIVISION-ZERO

// ZERO-STEP: error: range step must not be zero
// ZERO-STEP-NOT: error:
// ZERO-STEP-NOT: qpu.module

//--- zero-step.qasm
OPENQASM 3.0;
qubit[4] q;
qubit[4] r;
qubit[1] single;
bit[4] c;
h q[0:0:3];

// EMPTY: error: register selection must not be empty
// EMPTY-NOT: error:
// EMPTY-NOT: qpu.module

//--- empty.qasm
OPENQASM 3.0;
qubit[4] q;
qubit[4] r;
qubit[1] single;
bit[4] c;
reset q[3:0];

// ENDPOINT: error: range endpoints must be within the register
// ENDPOINT-NOT: error:
// ENDPOINT-NOT: qpu.module

//--- endpoint.qasm
OPENQASM 3.0;
qubit[4] q;
qubit[4] r;
qubit[1] single;
bit[4] c;
barrier q[0:4];

// NEGATIVE-ENDPOINT: error: range endpoints must be within the register
// NEGATIVE-ENDPOINT-NOT: error:
// NEGATIVE-ENDPOINT-NOT: qpu.module

//--- negative-endpoint.qasm
OPENQASM 3.0;
qubit[4] q;
qubit[4] r;
qubit[1] single;
bit[4] c;
reset q[-5:-1];

// FLOAT-STEP: error: expected a constant integer expression
// FLOAT-STEP-NOT: error:
// FLOAT-STEP-NOT: qpu.module

//--- float-step.qasm
OPENQASM 3.0;
qubit[4] q;
qubit[4] r;
qubit[1] single;
bit[4] c;
h q[0:1.5:3];

// RUNTIME-STEP: error: expected a constant integer expression
// RUNTIME-STEP-NOT: error:
// RUNTIME-STEP-NOT: qpu.module

//--- runtime-step.qasm
OPENQASM 3.0;
qubit[4] q;
qubit[4] r;
qubit[1] single;
bit[4] c;
h q[0:c:3];

// UNKNOWN: error: unknown parameter 'missing'
// UNKNOWN-NOT: error:
// UNKNOWN-NOT: qpu.module

//--- unknown.qasm
OPENQASM 3.0;
qubit[4] q;
qubit[4] r;
qubit[1] single;
bit[4] c;
h q[missing:3];

// MULTIPLE: error: expected a single constant qubit index or range
// MULTIPLE-NOT: error:
// MULTIPLE-NOT: qpu.module

//--- multiple.qasm
OPENQASM 3.0;
qubit[4] q;
qubit[4] r;
qubit[1] single;
bit[4] c;
barrier q[0:1,2:3];

// SET: error: expected a single constant qubit index or range
// SET-NOT: error:
// SET-NOT: qpu.module

//--- set.qasm
OPENQASM 3.0;
qubit[4] q;
qubit[4] r;
qubit[1] single;
bit[4] c;
reset q[{0,2}];

// MISSING-STEP: error: expected a constant range step
// MISSING-STEP-NOT: error:
// MISSING-STEP-NOT: qpu.module

//--- missing-step.qasm
OPENQASM 3.0;
qubit[4] q;
qubit[4] r;
qubit[1] single;
bit[4] c;
reset q[0::3];

// BROADCAST-SIZE: error: broadcast register operands must have equal lengths
// BROADCAST-SIZE-NOT: error:
// BROADCAST-SIZE-NOT: qpu.module

//--- broadcast-size.qasm
OPENQASM 3.0;
qubit[4] q;
qubit[4] r;
qubit[1] single;
bit[4] c;
cx q[0:1], r[0:2];

// ONE-ELEMENT-SLICE: error: broadcast register operands must have equal lengths
// ONE-ELEMENT-SLICE-NOT: error:
// ONE-ELEMENT-SLICE-NOT: qpu.module

//--- one-element-slice.qasm
OPENQASM 3.0;
qubit[4] q;
qubit[4] r;
qubit[1] single;
bit[4] c;
cx q[0:0], r[0:2];

// ONE-ELEMENT-REGISTER: error: broadcast register operands must have equal lengths
// ONE-ELEMENT-REGISTER-NOT: error:
// ONE-ELEMENT-REGISTER-NOT: qpu.module

//--- one-element-register.qasm
OPENQASM 3.0;
qubit[4] q;
qubit[4] r;
qubit[1] single;
bit[4] c;
cx single, q[0:2];

// ALIAS: error: gate operands must refer to distinct qubits
// ALIAS-NOT: error:
// ALIAS-NOT: qpu.module

//--- alias.qasm
OPENQASM 3.0;
qubit[4] q;
qubit[4] r;
qubit[1] single;
bit[4] c;
cx q[0:2], q[0:2];

// MEASUREMENT-SIZE: error: measurement source and destination sizes must match
// MEASUREMENT-SIZE-NOT: error:
// MEASUREMENT-SIZE-NOT: qpu.module

//--- measurement-size.qasm
OPENQASM 3.0;
qubit[4] q;
qubit[4] r;
qubit[1] single;
bit[4] c;
measure q[0:2] -> c[0:1];

// OVERFLOW: error: constant integer expression overflows int64
// OVERFLOW-NOT: error:
// OVERFLOW-NOT: qpu.module

//--- overflow.qasm
OPENQASM 3.0;
qubit[4] q;
qubit[4] r;
qubit[1] single;
bit[4] c;
h q[(9223372036854775807 + 1):3];

// DIVISION-ZERO: error: division by zero in constant integer expression
// DIVISION-ZERO-NOT: error:
// DIVISION-ZERO-NOT: qpu.module

//--- division-zero.qasm
OPENQASM 3.0;
qubit[4] q;
qubit[4] r;
qubit[1] single;
bit[4] c;
measure q[(1 / 0):3] -> c;
