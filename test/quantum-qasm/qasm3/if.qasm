// RUN: quantum-qasm %s -split-input-file > %t.mlir
// RUN: FileCheck %s --enable-var-scope < %t.mlir
// RUN: quantum-opt %t.mlir -split-input-file -verify-linearity -o /dev/null
// RUN: quantum-opt %t.mlir -split-input-file -convert-quantum-to-qillr -o /dev/null

// Different branch partitions must merge to a common whole-register result.
OPENQASM 3.0;
qubit[3] q;
bit[3] c;
h q[0];
if (c == 0) {
    x q[0];
} else {
    z q[2];
}
h q;

// CHECK-LABEL: module {
// CHECK: %[[BITS:.*]] = arith.constant dense<false> : tensor<3xi1>
// CHECK: %[[COND:.*]] = "qpu.bits_eq"(%[[BITS]], %{{.*}}) : (tensor<3xi1>, i3) -> i1
// CHECK: %[[INPUT:.*]] = "quantum.merge"
// CHECK: %[[IF:.*]]:2 = scf.if %[[COND]] -> (!quantum.qubit<3>, tensor<3xi1>) {
// CHECK: "quantum.split"(%[[INPUT]])
// CHECK: "quantum.X"
// CHECK: %[[THEN:.*]] = "quantum.merge"
// CHECK: scf.yield %[[THEN]], %[[BITS]]
// CHECK: } else {
// CHECK: "quantum.split"(%[[INPUT]])
// CHECK: "quantum.Z"
// CHECK: %[[ELSE:.*]] = "quantum.merge"
// CHECK: scf.yield %[[ELSE]], %[[BITS]]
// CHECK: "quantum.H"(%[[IF]]#0)
// CHECK: "qpu.return"(%[[IF]]#1)

// -----

// Measurement updates flow to later conditions and circuit outputs. The
// omitted else preserves both the incoming qubit and classical tensor.
OPENQASM 3.0;
qubit q;
bit c;
if (c) c = measure q;
if (c != 0) reset q;

// CHECK-LABEL: module {
// CHECK: %[[Q:.*]] = "quantum.alloc"
// CHECK: %[[BITS:.*]] = arith.constant dense<false> : tensor<1xi1>
// CHECK: "qpu.bits_eq"(%[[BITS]], %{{.*}}) : (tensor<1xi1>, i1) -> i1
// CHECK: %[[FIRST:.*]]:2 = scf.if
// CHECK: %[[MEAS:.*]], %[[RESULT:.*]] = "quantum.measure"(%[[Q]])
// CHECK: %[[READ:.*]] = "qpu.to_bits"(%[[MEAS]])
// CHECK: scf.yield %[[RESULT]], %[[READ]]
// CHECK: } else {
// CHECK: scf.yield %[[Q]], %[[BITS]]
// CHECK: "qpu.bits_eq"(%[[FIRST]]#1,
// CHECK: arith.xori
// CHECK: %[[SECOND:.*]]:2 = scf.if
// CHECK: "quantum.reset"(%[[FIRST]]#0)
// CHECK: "quantum.deallocate"(%[[SECOND]]#0)
// CHECK: "qpu.return"(%[[SECOND]]#1)

// -----

// Both branches start with the original scalar binding. Only the merged
// value may be used after the conditional.
OPENQASM 3.0;
qubit q;
bit c;
float theta = 1.0;
if (c[0]) theta = 2.0;
else theta = theta + 3.0;
rx(theta) q;
if (theta > 2.0 && !(c == 1)) x q;

// CHECK-LABEL: module {
// CHECK: %[[ORIGINAL:.*]] = arith.constant 1.000000e+00 : f64
// CHECK: tensor.extract
// CHECK: %[[IF:.*]]:3 = scf.if {{.*}} -> (!quantum.qubit<1>, f64, tensor<1xi1>) {
// CHECK: %[[THEN:.*]] = arith.constant 2.000000e+00 : f64
// CHECK: scf.yield %{{.*}}, %[[THEN]], %{{.*}}
// CHECK: } else {
// CHECK: %[[ELSE:.*]] = arith.constant 4.000000e+00 : f64
// CHECK: scf.yield %{{.*}}, %[[ELSE]], %{{.*}}
// CHECK: "quantum.Rx"(%[[IF]]#0, %[[IF]]#1)
// CHECK: arith.cmpf ogt, %[[IF]]#1,
// CHECK: "qpu.bits_eq"(%[[IF]]#2,
// CHECK: arith.xori
// CHECK: arith.andi
// CHECK: scf.if

// -----

// Nested branches and shadowed locals do not leak values or declarations.
OPENQASM 3.0;
qubit[2] q;
bit[2] c;
c = measure q;
int count = 0;
if (c[0] == true) {
    float count = 0.5;
    bit local;
    if (c[1] == 1) {
        rx(count) q[0];
        local = measure q[1];
    } else z q[1];
} else if (c[1]) count = 2;
if (count >= 1 || c[0] != false) h q[1];

// CHECK-LABEL: module {
// CHECK: "qpu.circuit"() <{function_type = () -> tensor<2xi1>
// CHECK: scf.if
// CHECK: scf.if
// CHECK: "qpu.to_bits"
// CHECK: } else {
// CHECK: "quantum.Z"
// CHECK: } else {
// CHECK: scf.if
// CHECK: arith.cmpi sge
// CHECK: arith.ori
// CHECK: scf.if
// CHECK: "quantum.H"

// -----

// Empty state and branch-local declarations still require valid terminators.
OPENQASM 3.0;
if (true) {} else { bool local = false; }
if (false) bool local = true;

// CHECK-LABEL: module {
// CHECK: "qpu.circuit"() <{function_type = () -> ()
// CHECK: scf.if
// CHECK: } else {
// CHECK: scf.if
// CHECK: "qpu.return"()
