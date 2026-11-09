// RUN: quantum-qasm %s -split-input-file > %t.mlir
// RUN: FileCheck %s --enable-var-scope < %t.mlir
// RUN: quantum-opt %t.mlir -split-input-file -verify-linearity -o /dev/null
// RUN: quantum-opt %t.mlir -split-input-file -convert-quantum-to-qillr > %t.qillr.mlir
// RUN: FileCheck %s --check-prefix=QILLR --enable-var-scope < %t.qillr.mlir

// The condition and body use loop arguments, and later statements use results.
OPENQASM 3.0;
qubit q;
int count = 0;
while (count < 3) {
    x q;
    count = count + 1;
}
h q;
if (count == 3) z q;

// CHECK-LABEL: module {
// CHECK: %[[Q:.*]] = "quantum.alloc"
// CHECK: %[[INITIAL:.*]] = arith.constant 0 : i64
// CHECK: %[[LOOP:.*]]:2 = scf.while (%[[BEFORE_Q:.*]] = %[[Q]], %[[BEFORE_COUNT:.*]] = %[[INITIAL]]) : (!quantum.qubit<1>, i64) -> (!quantum.qubit<1>, i64) {
// CHECK: %[[COND:.*]] = arith.cmpi slt, %[[BEFORE_COUNT]],
// CHECK: scf.condition(%[[COND]]) %[[BEFORE_Q]], %[[BEFORE_COUNT]]
// CHECK: } do {
// CHECK: ^bb0(%[[BODY_Q:.*]]: !quantum.qubit<1>, %[[BODY_COUNT:.*]]: i64):
// CHECK: %[[UPDATED_Q:.*]] = "quantum.X"(%[[BODY_Q]])
// CHECK: %[[UPDATED_COUNT:.*]] = arith.addi %[[BODY_COUNT]],
// CHECK: scf.yield %[[UPDATED_Q]], %[[UPDATED_COUNT]]
// CHECK: "quantum.H"(%[[LOOP]]#0)
// CHECK: arith.cmpi eq, %[[LOOP]]#1,
// CHECK: scf.if
// QILLR-LABEL: module {

// -----

// Measurement feedback must be tested again each iteration. The final bit
// tensor and qubit come from the loop results even when no iteration runs.
OPENQASM 3.0;
qubit q;
bit flag;
while (!flag) {
    h q;
    flag = measure q;
}
reset q;

// CHECK-LABEL: module {
// CHECK: %[[Q:.*]] = "quantum.alloc"
// CHECK: %[[BITS:.*]] = arith.constant dense<false> : tensor<1xi1>
// CHECK: %[[LOOP:.*]]:2 = scf.while (%[[BEFORE_Q:.*]] = %[[Q]], %[[BEFORE_BITS:.*]] = %[[BITS]])
// CHECK: %[[EQUAL:.*]] = "qpu.bits_eq"(%[[BEFORE_BITS]],
// CHECK: %[[COND:.*]] = arith.xori %[[EQUAL]],
// CHECK: scf.condition(%[[COND]]) %[[BEFORE_Q]], %[[BEFORE_BITS]]
// CHECK: } do {
// CHECK: ^bb0(%[[BODY_Q:.*]]: !quantum.qubit<1>, %[[BODY_BITS:.*]]: tensor<1xi1>):
// CHECK: %[[H:.*]] = "quantum.H"(%[[BODY_Q]])
// CHECK: %[[MEAS:.*]], %[[RESULT:.*]] = "quantum.measure"(%[[H]])
// CHECK: %[[READ:.*]] = "qpu.to_bits"(%[[MEAS]])
// CHECK: scf.yield %[[RESULT]], %[[READ]]
// CHECK: "quantum.reset"(%[[LOOP]]#0)
// CHECK: "qpu.return"(%[[LOOP]]#1)
// QILLR-LABEL: module {

// -----

// A loop body can refine different register slices and contain conditionals.
OPENQASM 3.0;
qubit[3] q;
bit[3] bits;
h q[0];
while (bits == 0) {
    reset q[0];
    if (bits[1]) x q[2];
    else z q[1];
    bits = measure q;
}
h q;

// CHECK-LABEL: module {
// CHECK: %[[INPUT:.*]] = "quantum.merge"
// CHECK: %[[LOOP:.*]]:2 = scf.while (%[[BEFORE_Q:.*]] = %[[INPUT]], %[[BEFORE_BITS:.*]] = %{{.*}}) : (!quantum.qubit<3>, tensor<3xi1>) -> (!quantum.qubit<3>, tensor<3xi1>) {
// CHECK: "qpu.bits_eq"(%[[BEFORE_BITS]],
// CHECK: scf.condition
// CHECK: } do {
// CHECK: "quantum.split"
// CHECK: "quantum.reset"
// CHECK: %[[IF:.*]]:2 = scf.if
// CHECK: "quantum.X"
// CHECK: "quantum.merge"
// CHECK: "quantum.Z"
// CHECK: "quantum.merge"
// CHECK: %[[MEAS:.*]], %[[RESULT:.*]] = "quantum.measure"(%[[IF]]#0)
// CHECK: %[[READ:.*]] = "qpu.to_bits"(%[[MEAS]])
// CHECK: scf.yield %[[RESULT]], %[[READ]]
// CHECK: "quantum.H"(%[[LOOP]]#0)
// CHECK: "qpu.return"(%[[LOOP]]#1)
// QILLR-LABEL: module {
// QILLR: "qillr.alloc"() <{size = 3 : i64}>
// QILLR: "qillr.H"(%{{.*}}) <{index = [0]}>
// QILLR: scf.while
// QILLR: "qillr.reset"(%{{.*}}) <{index = [0]}>
// QILLR: scf.if
// QILLR: "qillr.X"(%{{.*}}) <{index = [2]}>
// QILLR: "qillr.Z"(%{{.*}}) <{index = [1]}>

// -----

// Nested loops have separate block arguments. Locals are initialized inside
// the outer body, and a shadowed variable does not replace the outer binding.
OPENQASM 3.0;
qubit q;
bit flag;
if (!flag) {
    int count = 0;
    while (count < 2) {
        int inner = 0;
        while (inner < 2) {
            float count = 0.5;
            rx(count) q;
            inner = inner + 1;
        }
        count = count + 1;
    }
}
reset q;

// CHECK-LABEL: module {
// CHECK: %[[IF:.*]]:2 = scf.if
// CHECK: %[[OUTER:.*]]:3 = scf.while
// CHECK: arith.cmpi slt
// CHECK: scf.condition
// CHECK: } do {
// CHECK: arith.constant 0 : i64
// CHECK: %[[INNER:.*]]:4 = scf.while
// CHECK: arith.cmpi slt
// CHECK: scf.condition
// CHECK: } do {
// CHECK: arith.constant 5.000000e-01 : f64
// CHECK: "quantum.Rx"
// CHECK: arith.addi
// CHECK: scf.yield
// CHECK: arith.addi %[[INNER]]#2,
// CHECK: scf.yield %[[INNER]]#0,
// CHECK: scf.yield %[[OUTER]]#0, %[[OUTER]]#2
// CHECK: "quantum.reset"(%[[IF]]#0)
// QILLR-LABEL: module {

// -----

// An initially false condition preserves incoming state on the exit edge.
OPENQASM 3.0;
qubit q;
int count = 7;
while (false) count = count + 1;
rx(count) q;

// CHECK-LABEL: module {
// CHECK: %[[LOOP:.*]]:2 = scf.while (%[[Q:.*]] = %{{.*}}, %[[COUNT:.*]] = %{{.*}})
// CHECK: %[[FALSE:.*]] = arith.constant false
// CHECK: scf.condition(%[[FALSE]]) %[[Q]], %[[COUNT]]
// CHECK: } do {
// CHECK: arith.addi
// CHECK: scf.yield
// CHECK: arith.sitofp %[[LOOP]]#1
// QILLR-LABEL: module {

// -----

// Empty state still needs a condition region and a body terminator.
OPENQASM 3.0;
while (false) bool local = true;

// CHECK-LABEL: module {
// CHECK: scf.while : () -> () {
// CHECK: scf.condition(%{{.*}})
// CHECK: } do {
// CHECK: arith.constant true
// CHECK: scf.yield
// CHECK: "qpu.return"()
// QILLR-LABEL: module {

// -----

// A Boolean variable is tested directly, without bit-sequence conversion.
OPENQASM 3.0;
bool running = true;
while (running) running = false;
if (running) bool local = true;

// CHECK-LABEL: module {
// CHECK: %[[INITIAL:.*]] = arith.constant true
// CHECK: %[[LOOP:.*]] = scf.while (%[[BEFORE:.*]] = %[[INITIAL]]) : (i1) -> i1 {
// CHECK-NEXT: scf.condition(%[[BEFORE]]) %[[BEFORE]] : i1
// CHECK: } do {
// CHECK: %[[FALSE:.*]] = arith.constant false
// CHECK: scf.yield %[[FALSE]] : i1
// CHECK: scf.if %[[LOOP]]
// QILLR-LABEL: module {
