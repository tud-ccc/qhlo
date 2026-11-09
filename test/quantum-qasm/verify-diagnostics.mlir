// RUN: split-file %s %t
// RUN: quantum-qasm %t/chunks.qasm -split-input-file -verify-diagnostics
// RUN: quantum-qasm %t/expected.qasm -verify-diagnostics
// RUN: quantum-qasm -verify-diagnostics < %t/expected.qasm
// RUN: not quantum-qasm %t/expected.qasm 2>&1 | FileCheck %s --check-prefix=EXPECTED --implicit-check-not=qpu.module
// RUN: not quantum-qasm %t/missing.qasm -verify-diagnostics 2>&1 | FileCheck %s --check-prefix=MISSING
// RUN: not quantum-qasm %t/unexpected.qasm -verify-diagnostics 2>&1 | FileCheck %s --check-prefix=UNEXPECTED
// RUN: not quantum-qasm %t/location.qasm -verify-diagnostics 2>&1 | FileCheck %s --check-prefix=LOCATION
// RUN: quantum-qasm %t/relative-includes.qasm -verify-diagnostics
// RUN: quantum-qasm %t/relative-includes.qasm -split-input-file -verify-diagnostics

//--- chunks.qasm
// Each chunk has independent expectations and parser line numbers.
OPENQASM 2.0;
// expected-error @+1 {{unknown quantum register 'missing'}}
reset missing[0];

// -----

// A successful chunk must also verify when it has no expected errors.
OPENQASM 3.0;
qubit q;
h q;

// -----

OPENQASM 3.0;
// expected-error @+1 {{unknown quantum register 'missing'}}
h missing;

// -----

// Parser diagnostics use the same verifier as semantic diagnostics.
OPENQASM 3.0;
qubit q
// expected-error @+1 {{missing ';' at 'reset'}}
reset q;

//--- expected.qasm
// Verification accepts the same expected error from a file or stdin.
// Ordinary compilation must still fail despite the expected-error comment.
// EXPECTED: error: unknown quantum register 'missing'

OPENQASM 3.0;
// expected-error @+1 {{unknown quantum register 'missing'}}
h missing;

//--- missing.qasm
// This valid program emits no errors. The verifier must reject an unfulfilled
// expectation, even when compilation succeeds.
// MISSING: expected error "deliberately absent diagnostic" was not produced

OPENQASM 3.0;
qubit q;
// expected-error @+1 {{deliberately absent diagnostic}}
h q;

//--- unexpected.qasm
// Diagnostics without a matching expectation must fail verification.
// UNEXPECTED: unexpected error: unknown quantum register 'missing'

OPENQASM 3.0;
h missing;

//--- location.qasm
// Matching text on the wrong source line must fail verification.
// LOCATION: unexpected error: unknown quantum register 'missing'
// LOCATION: expected error "unknown quantum register 'missing'" was not produced

OPENQASM 3.0;
// expected-error @+1 {{unknown quantum register 'missing'}}
qubit q;
h missing;

//--- relative-includes.qasm
// Verification must resolve includes relative to the physical source file,
// even when split-input-file assigns a synthetic name to the chunk.
OPENQASM 2.0;
include "Inputs/relative-gate.inc";
qreg q[1];
local q[0];
// expected-error @+1 {{unknown quantum register 'missing'}}
reset missing[0];

//--- Inputs/relative-gate.inc
gate local a { U(0, 0, 0) a; }
