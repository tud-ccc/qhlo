// RUN: quantum-qasm -split-input-file %s | quantum-opt -split-input-file | FileCheck %s --enable-var-scope

// Calls return all updated qubits, with the original values on the false path.
OPENQASM 2.0;
gate custom a, b { CX a, b; }
qreg q[3];
creg condition[1];
measure q[0] -> condition[0];
if(condition==1) custom q[1], q[2];
reset q[1];

// CHECK-LABEL: module {
// CHECK: %[[COND:.*]] = "qpu.bits_eq"
// CHECK: %[[INPUT:.*]]:2 = "quantum.split"
// CHECK: %[[CALL:.*]]:2 = scf.if %[[COND]] -> (!quantum.qubit<1>, !quantum.qubit<1>) {
// CHECK: %[[UPDATED:.*]]:2 = "quantum.call"(%[[INPUT]]#0, %[[INPUT]]#1)
// CHECK-NEXT: scf.yield %[[UPDATED]]#0, %[[UPDATED]]#1 : !quantum.qubit<1>, !quantum.qubit<1>
// CHECK-NEXT: } else {
// CHECK-NEXT: scf.yield %[[INPUT]]#0, %[[INPUT]]#1 : !quantum.qubit<1>, !quantum.qubit<1>
// CHECK: "quantum.reset"(%[[CALL]]#0)

// -----

// Reset returns its replacement qubit and preserves the input on the false path.
OPENQASM 2.0;
qreg q[1];
creg condition[1];
measure q[0] -> condition[0];
if(condition==1) reset q[0];
reset q[0];

// CHECK-LABEL: module {
// CHECK: %{{.*}}, %[[INPUT:.*]] = "quantum.measure"
// CHECK: %[[COND:.*]] = "qpu.bits_eq"
// CHECK: %[[RESET:.*]] = scf.if %[[COND]] -> (!quantum.qubit<1>) {
// CHECK: %[[UPDATED:.*]] = "quantum.reset"(%[[INPUT]])
// CHECK-NEXT: scf.yield %[[UPDATED]] : !quantum.qubit<1>
// CHECK-NEXT: } else {
// CHECK-NEXT: scf.yield %[[INPUT]] : !quantum.qubit<1>
// CHECK: "quantum.reset"(%[[RESET]])

// -----

// Indexed measurement returns the qubit and the entire destination tensor.
OPENQASM 2.0;
qreg q[2];
creg condition[1];
creg bits[2];
measure q[0] -> condition[0];
if(condition==1) measure q[1] -> bits[1];
if(bits==0) reset q[1];

// CHECK-LABEL: module {
// CHECK: %[[INPUT:.*]]:2 = "quantum.split"
// CHECK: %[[COND:.*]] = "qpu.bits_eq"
// CHECK: %[[OLD_BITS:.*]] = arith.constant dense<false> : tensor<2xi1>
// CHECK: %[[MEASURE:.*]]:2 = scf.if %[[COND]] -> (!quantum.qubit<1>, tensor<2xi1>) {
// CHECK: %[[MEASUREMENT:.*]], %[[QUBIT:.*]] = "quantum.measure"(%[[INPUT]]#1)
// CHECK: %[[BITS:.*]] = "qpu.to_bits"(%[[MEASUREMENT]])
// CHECK: %[[UPDATED_BITS:.*]] = tensor.insert_slice %[[BITS]] into %[[OLD_BITS]][1] [1] [1]
// CHECK-NEXT: scf.yield %[[QUBIT]], %[[UPDATED_BITS]] : !quantum.qubit<1>, tensor<2xi1>
// CHECK-NEXT: } else {
// CHECK-NEXT: scf.yield %[[INPUT]]#1, %[[OLD_BITS]] : !quantum.qubit<1>, tensor<2xi1>
// CHECK: %[[NEXT_COND:.*]] = "qpu.bits_eq"(%[[MEASURE]]#1,
// CHECK: scf.if %[[NEXT_COND]]
// CHECK: "quantum.reset"(%[[MEASURE]]#0)

// -----

// Whole-register measurement splits before the if and returns every qubit.
OPENQASM 2.0;
qreg q[1];
qreg r[2];
creg condition[1];
creg bits[2];
measure q[0] -> condition[0];
if(condition==1) measure r -> bits;
reset r[0];

// CHECK-LABEL: module {
// CHECK: %[[COND:.*]] = "qpu.bits_eq"
// CHECK: %[[INPUT:.*]]:2 = "quantum.split"
// CHECK: %[[OLD_BITS:.*]] = arith.constant dense<false> : tensor<2xi1>
// CHECK: %[[MEASURE:.*]]:3 = scf.if %[[COND]] -> (!quantum.qubit<1>, !quantum.qubit<1>, tensor<2xi1>) {
// CHECK: %{{.*}}, %[[Q0:.*]] = "quantum.measure"(%[[INPUT]]#0)
// CHECK: %{{.*}}, %[[Q1:.*]] = "quantum.measure"(%[[INPUT]]#1)
// CHECK: %[[BITS:.*]] = tensor.insert_slice
// CHECK-NEXT: scf.yield %[[Q0]], %[[Q1]], %[[BITS]] : !quantum.qubit<1>, !quantum.qubit<1>, tensor<2xi1>
// CHECK-NEXT: } else {
// CHECK-NEXT: scf.yield %[[INPUT]]#0, %[[INPUT]]#1, %[[OLD_BITS]] : !quantum.qubit<1>, !quantum.qubit<1>, tensor<2xi1>
// CHECK: "quantum.reset"(%[[MEASURE]]#0)

// -----

// Repeated measurement accepts an already split register and merges its state.
OPENQASM 2.0;
qreg q[1];
qreg r[2];
creg condition[1];
creg bits[2];
measure q[0] -> condition[0];
if(condition==1) measure r -> bits;
if(condition==1) measure r -> bits;

// CHECK-LABEL: module {
// CHECK: "qpu.bits_eq"(%[[CONDITION_BITS:.*]], %{{.*}}) : (tensor<1xi1>, i1) -> i1
// CHECK: %[[FIRST:.*]]:3 = scf.if
// CHECK: } else {
// CHECK: scf.yield
// CHECK: %[[COND:.*]] = "qpu.bits_eq"(%[[CONDITION_BITS]],
// CHECK: %[[SECOND:.*]]:3 = scf.if %[[COND]] -> (!quantum.qubit<1>, !quantum.qubit<1>, tensor<2xi1>) {
// CHECK: %{{.*}}, %[[Q0:.*]] = "quantum.measure"(%[[FIRST]]#0)
// CHECK: %{{.*}}, %[[Q1:.*]] = "quantum.measure"(%[[FIRST]]#1)
// CHECK: %[[BITS:.*]] = tensor.insert_slice
// CHECK-NEXT: scf.yield %[[Q0]], %[[Q1]], %[[BITS]] : !quantum.qubit<1>, !quantum.qubit<1>, tensor<2xi1>
// CHECK-NEXT: } else {
// CHECK-NEXT: scf.yield %[[FIRST]]#0, %[[FIRST]]#1, %[[FIRST]]#2 : !quantum.qubit<1>, !quantum.qubit<1>, tensor<2xi1>
// CHECK: "qpu.return"(%[[SECOND]]#2,

// -----

// Uppercase built-ins store their operands directly on the call parse node.
OPENQASM 2.0;
qreg q[2];
creg condition[1];
measure q[0] -> condition[0];
if(condition==1) U(0,0,0) q[0];
if(condition==1) CX q[0], q[1];

// CHECK-LABEL: module {
// CHECK: %{{.*}}, %[[INPUT:.*]] = "quantum.measure"
// CHECK: %[[U_COND:.*]] = "qpu.bits_eq"
// CHECK: %[[U:.*]] = scf.if %[[U_COND]] -> (!quantum.qubit<1>) {
// CHECK: %[[UPDATED:.*]] = "quantum.U3"(%[[INPUT]],
// CHECK-NEXT: scf.yield %[[UPDATED]] : !quantum.qubit<1>
// CHECK-NEXT: } else {
// CHECK-NEXT: scf.yield %[[INPUT]] : !quantum.qubit<1>
// CHECK: %[[CX_COND:.*]] = "qpu.bits_eq"
// CHECK: %[[CX:.*]]:2 = scf.if %[[CX_COND]] -> (!quantum.qubit<1>, !quantum.qubit<1>) {
// CHECK: %[[CONTROL:.*]], %[[TARGET:.*]] = "quantum.CNOT"(%[[U]], %[[OTHER:.*]]) : (!quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>)
// CHECK-NEXT: scf.yield %[[CONTROL]], %[[TARGET]] : !quantum.qubit<1>, !quantum.qubit<1>
// CHECK-NEXT: } else {
// CHECK-NEXT: scf.yield %[[U]], %[[OTHER]] : !quantum.qubit<1>, !quantum.qubit<1>
