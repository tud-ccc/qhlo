// RUN: quantum-qasm %s -split-input-file -verify-diagnostics
// RUN: not quantum-qasm %s -split-input-file 2>&1 | FileCheck %s --check-prefix=NO-IR
// NO-IR-NOT: qpu.module

OPENQASM 3.0;
// expected-error @+1 {{condition requires a bool or a single bit}}
if (1) {}

// -----
OPENQASM 3.0;
bit[2] c;
// expected-error @+1 {{condition requires a bool or a single bit}}
if (c) {}

// -----
OPENQASM 3.0;
bit[2] c;
// expected-error @+1 {{comparison value does not fit in the bit sequence}}
if (c == 4) {}

// -----
OPENQASM 3.0;
bit[2] c;
// expected-error @+1 {{comparison value does not fit in the bit sequence}}
if (c == -1) {}

// -----
OPENQASM 3.0;
bit[2] c;
int value = 1;
// expected-error @+1 {{comparison integer width must match the bit sequence length}}
if (c == value) {}

// -----
OPENQASM 3.0;
bit c;
// expected-error @+1 {{bit sequences require equality with an integer or bool}}
if (c < 1) {}

// -----
OPENQASM 3.0;
bit c;
// expected-error @+1 {{classical bit index is out of range}}
if (c[1]) {}

// -----
OPENQASM 3.0;
// expected-error @+1 {{unknown identifier 'missing'}}
if (missing) {}

// -----
OPENQASM 3.0;
if (true) bool local = false;
// expected-error @+1 {{unknown identifier 'local'}}
if (local) {}

// -----
OPENQASM 3.0;
if (true) {
    // expected-error @+1 {{unsupported control-flow statement}}
    break;
}

// -----
OPENQASM 3.0;
if (true) {
    // expected-error @+1 {{unsupported control-flow statement}}
    continue;
}

// -----
OPENQASM 3.0;
if (true) {
    // expected-error @+1 {{unsupported control-flow statement}}
    return;
}

// -----
OPENQASM 3.0;
if (true) {
    // expected-error @+1 {{unsupported control-flow statement}}
    end;
}

// -----
OPENQASM 3.0;
if (true) {
    // expected-error @+1 {{unsupported control-flow statement}}
    for int i in [0:1] {}
}
