// RUN: split-file %s %t
// RUN: quantum-qasm %t/valid.qasm | FileCheck %s --check-prefix=VALID
// RUN: not quantum-qasm %t/zero.qasm 2>&1 | FileCheck %s --check-prefix=BOUNDS
// RUN: sed 's/qubit/bit/' %t/zero.qasm > %t/zero-bit.qasm
// RUN: not quantum-qasm %t/zero-bit.qasm 2>&1 | FileCheck %s --check-prefix=BOUNDS
// RUN: not quantum-qasm %t/overflow.qasm 2>&1 | FileCheck %s --check-prefix=BOUNDS
// RUN: sed 's/qubit/bit/' %t/overflow.qasm > %t/overflow-bit.qasm
// RUN: not quantum-qasm %t/overflow-bit.qasm 2>&1 | FileCheck %s --check-prefix=BOUNDS
// RUN: not quantum-qasm %t/negative.qasm 2>&1 | FileCheck %s --check-prefix=CONSTANT
// RUN: sed 's/qubit/bit/' %t/negative.qasm > %t/negative-bit.qasm
// RUN: not quantum-qasm %t/negative-bit.qasm 2>&1 | FileCheck %s --check-prefix=CONSTANT
// RUN: not quantum-qasm %t/compound.qasm 2>&1 | FileCheck %s --check-prefix=CONSTANT
// RUN: sed 's/qubit/bit/' %t/compound.qasm > %t/compound-bit.qasm
// RUN: not quantum-qasm %t/compound-bit.qasm 2>&1 | FileCheck %s --check-prefix=CONSTANT
// RUN: not quantum-qasm %t/noninteger.qasm 2>&1 | FileCheck %s --check-prefix=CONSTANT
// RUN: sed 's/qubit/bit/' %t/noninteger.qasm > %t/noninteger-bit.qasm
// RUN: not quantum-qasm %t/noninteger-bit.qasm 2>&1 | FileCheck %s --check-prefix=CONSTANT
// RUN: not quantum-qasm %t/unknown.qasm 2>&1 | FileCheck %s --check-prefix=UNKNOWN
// RUN: sed 's/qubit/bit/' %t/unknown.qasm > %t/unknown-bit.qasm
// RUN: not quantum-qasm %t/unknown-bit.qasm 2>&1 | FileCheck %s --check-prefix=UNKNOWN
// RUN: not quantum-qasm %t/invalid-literal.qasm 2>&1 | FileCheck %s --check-prefix=LITERAL
// RUN: sed 's/qubit/bit/' %t/invalid-literal.qasm > %t/invalid-literal-bit.qasm
// RUN: not quantum-qasm %t/invalid-literal-bit.qasm 2>&1 | FileCheck %s --check-prefix=LITERAL

// BOUNDS: error: register length must be a positive unsigned integer
// BOUNDS-NOT: error:
// BOUNDS-NOT: qpu.module
// CONSTANT: error: expected a constant integer register length
// CONSTANT-NOT: error:
// CONSTANT-NOT: qpu.module
// UNKNOWN: error: unknown parameter 'missing'
// UNKNOWN-NOT: error:
// UNKNOWN-NOT: qpu.module
// LITERAL: error: invalid numeric literal '9223372036854775808'
// LITERAL-NOT: error:
// LITERAL-NOT: qpu.module

//--- valid.qasm
OPENQASM 3.0;
qubit q;
qubit[((2))] qs;
bit c;
bit[((2))] cs;

// VALID: !quantum.qubit<1>
// VALID: !quantum.qubit<2>
// VALID: tensor<1xi1>
// VALID: tensor<2xi1>

//--- zero.qasm
OPENQASM 3.0;
qubit[0] q;

//--- overflow.qasm
OPENQASM 3.0;
qubit[4294967296] q;

//--- negative.qasm
OPENQASM 3.0;
qubit[-1] q;

//--- compound.qasm
OPENQASM 3.0;
qubit[1 + 2] q;

//--- noninteger.qasm
OPENQASM 3.0;
qubit[1.5] q;

//--- unknown.qasm
OPENQASM 3.0;
qubit[missing] q;

//--- invalid-literal.qasm
OPENQASM 3.0;
qubit[9223372036854775808] q;
