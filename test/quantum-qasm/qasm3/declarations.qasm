// RUN: quantum-qasm %s -split-input-file > %t.mlir
// RUN: FileCheck %s --enable-var-scope < %t.mlir
// RUN: quantum-opt %t.mlir -split-input-file -o /dev/null

// Scalar declarations.
OPENQASM 3.0;
const int size = 2;
const int count = size * 2;
const float step = 1.5;
gate rotate(theta) a { rx(theta) a; rz(step) a; }
gate shadow(step) a { rx(step) a; }
float theta = step;
theta = 2;
int[32] n = 3;
int[32] m = n;
m = 4;
bool enabled = true;
const float negative = -1.5;
qubit[count] q;
rotate(theta) q[0];
shadow(1) q[1];
rx(negative) q[2];
reset q[size];

// Constants used by gates must be materialized inside the gate body.
// CHECK-LABEL: module {
// CHECK: sym_name = "rotate"
// CHECK: ^bb0(%{{.*}}: !quantum.qubit<1>, %[[THETA:.*]]: f64):
// CHECK: "quantum.Rx"(%{{.*}}, %[[THETA]])
// CHECK: %[[STEP:.*]] = arith.constant 1.500000e+00 : f64
// CHECK: "quantum.Rz"(%{{.*}}, %[[STEP]])
// CHECK: "quantum.return"
// CHECK: sym_name = "shadow"
// CHECK: "quantum.Rx"
// CHECK: "qpu.circuit"() <{function_type = () -> ()
// CHECK: arith.constant 2.000000e+00 : f64
// CHECK: arith.constant 3 : i32
// CHECK: arith.constant 4 : i32
// CHECK: arith.constant true
// CHECK: !quantum.qubit<4>
// CHECK: callee = @rotate
// CHECK: callee = @shadow
// CHECK: arith.constant -1.500000e+00 : f64

// -----

// Builtin constants.
OPENQASM 3.0;
// Both spellings of each built-in must have the same float[64] value.
float asciiPi = pi;
float unicodePi = π;
float asciiTau = tau;
float unicodeTau = τ;
float asciiEuler = euler;
float unicodeEuler = ℇ;
// Ordinary Unicode identifiers use the same scope lookup as ASCII names.
const float θ = π;
gate rotate(φ) a { rx(φ) a; rz(θ) a; }
qubit q;
rotate(τ) q;
// Includes inherit the built-in declarations, too.
include "Inputs/includes/builtin-constants.inc";

// CHECK-LABEL: module {
// CHECK: sym_name = "rotate"
// CHECK: ^bb0(%{{.*}}: !quantum.qubit<1>, %[[PARAM:.*]]: f64):
// CHECK: "quantum.Rx"(%{{.*}}, %[[PARAM]])
// CHECK: %[[CAPTURED:.*]] = arith.constant [[PI:3\.14159[0-9]*]] : f64
// CHECK: "quantum.Rz"(%{{.*}}, %[[CAPTURED]])
// CHECK: "qpu.circuit"
// CHECK: arith.constant [[PI]] : f64
// CHECK: arith.constant [[PI]] : f64
// CHECK: arith.constant [[TAU:6\.28318[0-9]*]] : f64
// CHECK: arith.constant [[TAU]] : f64
// CHECK: arith.constant [[E:2\.71828[0-9]*]] : f64
// CHECK: arith.constant [[E]] : f64
// CHECK: %[[ARG:.*]] = arith.constant [[TAU]] : f64
// CHECK: "quantum.call"(%{{.*}}, %[[ARG]]) <{callee = @rotate}>
// CHECK: %[[INCLUDED:.*]] = arith.constant [[E]] : f64
// CHECK: "quantum.Rx"(%{{.*}}, %[[INCLUDED]])

// -----

// Lexical scopes.
OPENQASM 3.0;
const float theta = 0.25;
gate rotate(parameter) a { rx(parameter) a; }
gate captured a { rz(theta) a; }
float rotation = 1.0;
qubit q;
{
    float rotation = 2.0;
    bit local;
    rotate(rotation) q;
    {
        rotation = 3.0;
        const float theta = 9.0;
        // Materialize captured from this block, using its definition scope.
        captured q;
    }
    rx(rotation) q;
    // An unqualified barrier also sees the enclosing qubit.
    barrier;
}
rx(rotation) q;
{
    // Sibling blocks have independent declaration namespaces.
    bit local;
}

// CHECK-LABEL: module {
// CHECK: sym_name = "rotate"
// CHECK: "quantum.Rx"
// CHECK: sym_name = "captured"
// CHECK: %[[CAPTURED:.*]] = arith.constant 2.500000e-01 : f64
// CHECK: "quantum.Rz"(%{{.*}}, %[[CAPTURED]])
// Local classical registers do not become circuit outputs.
// CHECK: "qpu.circuit"() <{function_type = () -> ()
// CHECK: %[[OUTER:.*]] = arith.constant 1.000000e+00 : f64
// CHECK: %[[INNER:.*]] = arith.constant 2.000000e+00 : f64
// CHECK: "quantum.call"(%{{.*}}, %[[INNER]]) <{callee = @rotate}>
// CHECK: %[[UPDATED:.*]] = arith.constant 3.000000e+00 : f64
// CHECK: callee = @captured
// CHECK: "quantum.Rx"(%{{.*}}, %[[UPDATED]])
// CHECK: "quantum.barrier"(%{{.*}})
// CHECK: "quantum.Rx"(%{{.*}}, %[[OUTER]])

// -----

// Register size.
OPENQASM 3.0;
qubit q;
qubit[((2))] qs;
bit c;
bit[((2))] cs;

// CHECK-LABEL: module {
// CHECK: !quantum.qubit<1>
// CHECK: !quantum.qubit<2>
// CHECK: tensor<1xi1>
// CHECK: tensor<2xi1>

// -----

// Numeric constant expressions are folded before IR emission.
OPENQASM 3.0;
const float half = pi / 2;
gate foldedPhase a { rz((pi + π) / 4) a; }
float sum = 1.5 + 2;
float difference = 5 - 1.5;
float product = (1 + 2.0) * 4;
// The destination type must not change integer division into float division.
float integerDivision = 5 / 2;
float floatDivision = 5 / 2.0;
const int[8] negative = -2;
float signedPromotion = 1.0 + negative;
float nested = 2 / (1 + 3.0);
float unary = -(pi / 2);
const int index = (7 + 5) * 2 / 3 % 5;
qubit[4] q;
h q[index];
foldedPhase q[0];
cp(half) q[0], q[1];
cp(pi / 4) q[0], q[1];
cp(pi / 8) q[0], q[1];

// CHECK-LABEL: module {
// CHECK: sym_name = "foldedPhase"
// CHECK: %[[GATE_PHASE:.*]] = arith.constant 1.5707963267948966 : f64
// CHECK: "quantum.Rz"(%{{.*}}, %[[GATE_PHASE]])
// CHECK: "qpu.circuit"
// CHECK: arith.constant 3.500000e+00 : f64
// CHECK: arith.constant 3.500000e+00 : f64
// CHECK: arith.constant 1.200000e+01 : f64
// CHECK: arith.constant 2.000000e+00 : f64
// CHECK: arith.constant 2.500000e+00 : f64
// CHECK: arith.constant -1.000000e+00 : f64
// CHECK: arith.constant 5.000000e-01 : f64
// CHECK: arith.constant -1.5707963267948966 : f64
// CHECK: callee = @foldedPhase
// CHECK: %[[HALF:.*]] = arith.constant 1.5707963267948966 : f64
// CHECK: "quantum.CU1"(%{{.*}}, %{{.*}}, %[[HALF]])
// CHECK: %[[QUARTER:.*]] = arith.constant 0.78539816339744828 : f64
// CHECK: "quantum.CU1"(%{{.*}}, %{{.*}}, %[[QUARTER]])
// CHECK: %[[EIGHTH:.*]] = arith.constant 0.39269908169872414 : f64
// CHECK: "quantum.CU1"(%{{.*}}, %{{.*}}, %[[EIGHTH]])
