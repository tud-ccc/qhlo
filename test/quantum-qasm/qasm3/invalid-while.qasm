// RUN: quantum-qasm %s -split-input-file -verify-diagnostics
// RUN: not quantum-qasm %s -split-input-file 2>&1 | FileCheck %s --check-prefix=NO-IR
// NO-IR-NOT: qpu.module

OPENQASM 3.0;
// expected-error @+1 {{condition requires a bool or a single bit}}
while (1) {}

// -----
OPENQASM 3.0;
bit[2] bits;
// expected-error @+1 {{condition requires a bool or a single bit}}
while (bits) {}

// -----
OPENQASM 3.0;
// expected-error @+1 {{unknown identifier 'missing'}}
while (missing) {}

// -----
OPENQASM 3.0;
// The condition cannot refer to a declaration inside the body.
// expected-error @+1 {{unknown identifier 'local'}}
while (local) bool local = false;

// -----
OPENQASM 3.0;
while (false) bool local = true;
// expected-error @+1 {{unknown identifier 'local'}}
if (local) {}

// -----
OPENQASM 3.0;
while (true) {
    // expected-error @+1 {{unknown identifier 'missing'}}
    int count = missing;
}

// -----
OPENQASM 3.0;
while (true) {
    // expected-error @+1 {{unsupported control-flow statement}}
    break;
}

// -----
OPENQASM 3.0;
while (true) {
    if (true) {
        // expected-error @+1 {{unsupported control-flow statement}}
        continue;
    }
}

// -----
OPENQASM 3.0;
while (true) {
    // expected-error @+1 {{unsupported control-flow statement}}
    return;
}

// -----
OPENQASM 3.0;
while (true) {
    // expected-error @+1 {{unsupported control-flow statement}}
    end;
}

// -----
OPENQASM 3.0;
while (false) {
    // Even an initially false condition does not bypass semantic checks.
    // expected-error @+1 {{quantum declarations are only allowed at global scope}}
    qubit local;
}
