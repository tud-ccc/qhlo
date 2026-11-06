// RUN: split-file %s %t
// RUN: quantum-qasm %t/main.qasm > %t.mlir
// RUN: FileCheck %s --check-prefix=IR < %t.mlir
// RUN: quantum-opt %t.mlir -o /dev/null
// RUN: quantum-qasm %t/main.qasm -split-input-file | FileCheck %s --check-prefix=IR
// RUN: quantum-qasm %t/errors.qasm -split-input-file -verify-diagnostics
// RUN: not quantum-qasm %t/errors.qasm -split-input-file 2>&1 | FileCheck %s --check-prefix=NO-IR
// RUN: not quantum-qasm %t/diagnostics.qasm -split-input-file 2>&1 | FileCheck %s --check-prefix=DIAG --implicit-check-not=qpu.module
// RUN: echo 'include "%t/Inputs/includes/standalone.inc";' > %t.absolute.qasm
// RUN: quantum-qasm %t.absolute.qasm | FileCheck %s --check-prefix=ABSOLUTE
// RUN: echo 'include "%t.alias.inc";' > %t.cycle.qasm
// RUN: ln -sf %t.cycle.qasm %t.alias.inc
// RUN: not quantum-qasm %t.cycle.qasm 2>&1 | FileCheck %s --check-prefix=CYCLE --implicit-check-not=qpu.module

// ABSOLUTE: sym_name = "identity"
// ABSOLUTE: callee = @identity
// CYCLE: error: include cycle detected for '
// NO-IR-NOT: qpu.module

//--- main.qasm
OPENQASM 3.0;
const int rootWidth = 3;
const float phase = 0.25;
float theta = 1.0;
qubit[rootWidth] q;
include "Inputs/includes/globals.inc";
imported(theta) q[0];
nested q[1];
bit[fromRoot] c;
c = measure q;
// Repeated includes are expansions, not implicit include-once imports.
include "Inputs/includes/reset.inc";
include 'Inputs/includes/reset.inc';

// IR: sym_name = "imported"
// IR: ^bb0(%{{.*}}: !quantum.qubit<1>, %[[ANGLE:.*]]: f64):
// IR: "quantum.Rx"(%{{.*}}, %[[ANGLE]])
// IR: sym_name = "nested"
// IR: arith.constant 2.500000e-01 : f64
// IR: callee = @imported
// IR: "qpu.circuit"
// IR: arith.constant 1.000000e+00 : f64
// IR: !quantum.qubit<3>
// IR: %[[THETA:.*]] = arith.constant 2.500000e+00 : f64
// IR: "quantum.call"(%{{.*}}, %[[THETA]]) <{callee = @imported}>
// IR: callee = @nested
// IR: tensor<3xi1>
// IR: "quantum.measure"
// IR: "quantum.reset"
// IR: "quantum.reset"

//--- errors.qasm
OPENQASM 3.0;
// expected-error @+1 {{failed to resolve include 'Inputs/missing-qasm3.inc'}}
include "Inputs/missing-qasm3.inc";
// -----
OPENQASM 3.0;
// expected-error @+1 {{include cycle detected for './errors.qasm'}}
include "./errors.qasm";
// -----
OPENQASM 3.0;
const int rootWidth = 3;
const float phase = 0.25;
float theta = 1.0;
include "Inputs/includes/globals.inc";
// expected-error @+1 {{unknown identifier 'localAngle'}}
float x = localAngle;
// -----
OPENQASM 3.0;
const int rootWidth = 3;
const float phase = 0.25;
float theta = 1.0;
include "Inputs/includes/globals.inc";
// expected-error @+1 {{redefinition of 'fromRoot'}}
const int fromRoot = 4;
// -----
OPENQASM 3.0;
gate g a {
    // expected-error @+1 {{include statements are only allowed at global scope}}
    include "Inputs/includes/reset.inc";
}
qubit q;
g q;
// -----
OPENQASM 3.0;
{
    // expected-error @+1 {{include statements are only allowed at global scope}}
    include "Inputs/includes/reset.inc";
}

//--- diagnostics.qasm
OPENQASM 3.0;
include "Inputs/includes/cycle-a.inc";
// DIAG: cycle-b.inc":1:1): error: include cycle detected for '../cycle-a.inc'
// -----
OPENQASM 3.0;
include "Inputs/includes/semantic-error.inc";
// DIAG: semantic-error.inc":1:7): error: unknown quantum register 'missing'
// -----
OPENQASM 3.0;
include "Inputs/includes/syntax-error.inc";
// DIAG: syntax-error.inc":2:1): error:
// -----
OPENQASM 3.0;
include "Inputs/includes/gate-error.inc";
qubit q;
broken q;
// DIAG: gate-error.inc":1:19): error: unknown quantum register 'missing'
// -----
OPENQASM 3.0;
const int rootWidth = 3;
const float phase = 0.25;
float theta = 1.0;
include "Inputs/includes/globals.inc";
include "Inputs/includes/globals.inc";
// DIAG: globals.inc":2:1): error: redefinition of 'fromRoot'

//--- Inputs/includes/cycle-a.inc
include "nested/cycle-b.inc";

//--- Inputs/includes/gate-error.inc
gate broken a { h missing; }

//--- Inputs/includes/globals.inc
// Read root declarations and contribute declarations to the same global scope.
const int fromRoot = rootWidth;
float fromRootVariable = theta;
theta = 2.5;
gate imported(localAngle) a { rx(localAngle) a; }
include "nested/declarations.inc";

//--- Inputs/includes/nested/cycle-b.inc
include "../cycle-a.inc";

//--- Inputs/includes/nested/declarations.inc
// This path must be resolved relative to globals.inc, not to the root program.
gate nested a { imported(phase) a; }

//--- Inputs/includes/reset.inc
reset q;

//--- Inputs/includes/semantic-error.inc
reset missing;

//--- Inputs/includes/standalone.inc
gate identity a {}
qubit q;
identity q;

//--- Inputs/includes/syntax-error.inc
qubit[1] q
