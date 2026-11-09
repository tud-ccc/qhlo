// RUN: quantum-qasm %s -split-input-file -verify-diagnostics
// RUN: not quantum-qasm %s -split-input-file 2>&1 | FileCheck %s --check-prefix=NO-IR
// NO-IR-NOT: qpu.module

// Scalar errors.
OPENQASM 3.0;
// expected-error @+1 {{unknown identifier 'missing'}}
float x = missing;
// -----
OPENQASM 3.0;
int x = 1;
// expected-error @+1 {{expected a compile-time constant}}
const int y = x;
// -----
OPENQASM 3.0;
const int x = 1;
// expected-error @+1 {{assignment requires a mutable scalar variable}}
x = 2;
// -----
OPENQASM 3.0;
// expected-error @+1 {{initializer or expression type does not match the declared type}}
int[8] x = 128;
// -----
OPENQASM 3.0;
// expected-error @+1 {{initializer or expression type does not match the declared type}}
bool x = 1;
// -----
OPENQASM 3.0;
float x = 1.0;
// expected-error @+1 {{expression type does not match the expected type}}
int y = x;
// -----
OPENQASM 3.0;
qubit q;
// expected-error @+1 {{identifier does not denote a classical value}}
float x = q;
// -----
OPENQASM 3.0;
int x = 1;
// expected-error @+1 {{redefinition of 'x'}}
gate x a {}
// -----
OPENQASM 3.0;
gate g a {}
// expected-error @+1 {{redefinition of 'g'}}
float g = 1;
// -----
OPENQASM 3.0;
const int size = 2;
// expected-error @+1 {{redefinition of 'size'}}
qubit[size] size;
// -----
OPENQASM 3.0;
gate g a {}
// expected-error @+1 {{identifier does not denote a classical value}}
float x = g;
// -----
OPENQASM 3.0;
gate g a { rx(later) a; }
const float later = 1.0;
qubit q;
// The diagnostic belongs to the deferred body, not the call site.
// expected-error @-4 {{unknown identifier 'later'}}
g q;
// -----
OPENQASM 3.0;
float global = 1.0;
gate g a { rx(global) a; }
qubit q;
// expected-error @-2 {{unknown identifier 'global'}}
g q;
// -----
OPENQASM 3.0;
// expected-error @+1 {{constant integer expression overflows int64}}
const int x = 9223372036854775807 + 1;
// -----
OPENQASM 3.0;
// expected-error @+1 {{scalar variables require an initializer}}
float x;
// -----
OPENQASM 3.0;
float rx = 1.0;
qubit q;
// expected-error @+1 {{identifier 'rx' does not denote a gate}}
rx(1) q;
// -----
OPENQASM 3.0;
gate g(theta) q { theta q; }
qubit q;
// expected-error @-2 {{identifier 'theta' does not denote a gate}}
g(1) q;

// -----

// Builtin constant errors.
OPENQASM 3.0;
// expected-error @+1 {{redefinition of 'pi'}}
float pi = 1.0;
// -----
OPENQASM 3.0;
// expected-error @+1 {{redefinition of 'π'}}
const float π = 1.0;
// -----
OPENQASM 3.0;
// expected-error @+1 {{assignment requires a mutable scalar variable}}
tau = 1.0;
// -----
OPENQASM 3.0;
// expected-error @+1 {{assignment requires a mutable scalar variable}}
ℇ = 1.0;
// -----
OPENQASM 3.0;
// The language defines 'euler', not 'e'.
// expected-error @+1 {{unknown identifier 'e'}}
float x = e;

// -----

// Lexical scope errors.
OPENQASM 3.0;
{ float local = 1.0; }
// expected-error @+1 {{unknown identifier 'local'}}
float x = local;
// -----
OPENQASM 3.0;
{
    float local = 1.0;
    // expected-error @+1 {{redefinition of 'local'}}
    float local = 2.0;
}
// -----
OPENQASM 3.0;
// expected-error @+1 {{gate 'later' cannot be resolved}}
gate first a { later a; }
gate later a { x a; }
qubit q;
first q;
// -----
OPENQASM 3.0;
// expected-error @+1 {{recursive gate call to 'recursive'}}
gate recursive a { recursive a; }
qubit q;
recursive q;
// -----
OPENQASM 3.0;
// expected-error @+1 {{gate 'second' cannot be resolved}}
gate first a { second a; }
gate second a { first a; }
qubit q;
first q;
// -----
OPENQASM 3.0;
gate rotate(theta) a {
    // Parameters and body declarations belong to the same lexical scope.
    // expected-error @+1 {{redefinition of 'theta'}}
    float theta = 1.0;
}
qubit q;
rotate(1) q;
// -----
OPENQASM 3.0;
{
    // expected-error @+1 {{gate declarations are only allowed at global scope}}
    gate nested a {}
}
// -----
OPENQASM 3.0;
float runtime = 1.0;
// expected-error @+1 {{unknown identifier 'runtime'}}
gate g a { { rx(runtime) a; } }
qubit q;
g q;
// -----
OPENQASM 3.0;
qubit q;
{
    float q = 1.0;
    // expected-error @+1 {{unknown quantum register 'q'}}
    reset q;
}
// -----
OPENQASM 3.0;
gate g a {}
qubit q;
{
    float g = 1.0;
    // expected-error @+1 {{identifier 'g' does not denote a gate}}
    g q;
}
// -----
OPENQASM 3.0;
{
    // expected-error @+1 {{quantum declarations are only allowed at global scope}}
    qubit local;
}
// -----
OPENQASM 3.0;
// expected-error @+1 {{gate 'laterFromInclude' cannot be resolved}}
gate first a { laterFromInclude a; }
include "Inputs/includes/lexical-later.inc";
qubit q;
first q;

// -----

// Redeclarations.
// Quantum.
OPENQASM 3.0;
qubit[2] q;
// expected-error @+1 {{redefinition of 'q'}}
qubit[2] q;

// -----

// Classical.
OPENQASM 3.0;
bit[2] q;
// expected-error @+1 {{redefinition of 'q'}}
bit[2] q;

// -----

// Quantum classical.
OPENQASM 3.0;
qubit[2] q;
// expected-error @+1 {{redefinition of 'q'}}
bit[2] q;

// -----

// Classical quantum.
OPENQASM 3.0;
bit[2] q;
// expected-error @+1 {{redefinition of 'q'}}
qubit[2] q;

// -----

// Gate parameters.
OPENQASM 3.0;
gate g(q, q) a {}
qubit[2] q;
// expected-error @+1 {{redefinition of 'q'}}
g(1, 2) q[0];

// -----

// Gate qubits.
OPENQASM 3.0;
gate g q, q {}
qubit[2] q;
// expected-error @+1 {{redefinition of 'q'}}
g q[0], q[1];

// -----

// Gate parameter qubit.
OPENQASM 3.0;
gate g(q) q {}
qubit[2] q;
// expected-error @+1 {{redefinition of 'q'}}
g(1) q[0];

// -----

OPENQASM 3.0;
// expected-error @+1 {{expected numeric constants in arithmetic expression}}
const int value = true + 1;

// -----

OPENQASM 3.0;
// expected-error @+1 {{expected a numeric constant for unary minus}}
const int value = -false;

// -----

OPENQASM 3.0;
// expected-error @+1 {{remainder requires integer constants}}
const float value = 3.0 % 2;

// -----

OPENQASM 3.0;
float runtime = 1.0;
// An SSA value initialized by a constant is not a language-level const.
// expected-error @+1 {{expected a compile-time constant}}
const float value = runtime + 1;

// -----

OPENQASM 3.0;
// expected-error @+1 {{unsupported constant expression}}
const int value = 1 << 2;

// -----

OPENQASM 3.0;
// expected-error @+1 {{constant integer expression overflows int64}}
const int value = -(-9223372036854775807 - 1);

// -----

OPENQASM 3.0;
// expected-error @+1 {{constant integer expression overflows int64}}
const int value = (-9223372036854775807 - 1) / -1;

// -----

OPENQASM 3.0;
// expected-error @+1 {{expected a constant integer expression}}
int[2.0 + 2] value = 1;
