// RUN: quantum-opt %s -replace-repeated-reads -split-input-file | FileCheck %s --check-prefixes=CHECK,READS
// RUN: quantum-opt %s -cse -split-input-file | FileCheck %s --check-prefixes=CHECK,CSE
// CSE conservatively retains reads nested inside regions.

// CHECK-LABEL: @single_read_replaced
func.func public @single_read_replaced() -> (tensor<1xi1>, tensor<1xi1>) {
// CHECK: %[[q:.+]] = "qillr.alloc"() <{size = 1 : i64}> : () -> !qillr.qubit
%0 = "qillr.alloc"() <{size = 1 : i64}> : () -> !qillr.qubit
// CHECK: %[[r:.+]] = "qillr.ralloc"() <{size = 1 : i64}> : () -> !qillr.result
%1 = "qillr.ralloc"() <{size = 1 : i64}> : () -> !qillr.result
// CHECK: "qillr.measure"(%[[q]], %[[r]]) <{inputIndex = [], resultIndex = []}> : (!qillr.qubit, !qillr.result) -> ()
"qillr.measure"(%0, %1) : (!qillr.qubit, !qillr.result) -> ()
// CHECK: %[[m1:.+]] = "qpu.to_bits"(%[[r]]) : (!qillr.result) -> tensor<1xi1>
%3 = "qpu.to_bits"(%1) : (!qillr.result) -> tensor<1xi1>
// CHECK-NOT: "qpu.to_bits"(%[[r]]) : (!qillr.result) -> tensor<1xi1>
%4 = "qpu.to_bits"(%1) : (!qillr.result) -> tensor<1xi1>
"qillr.reset"(%0) : (!qillr.qubit) -> ()
// CHECK: return %[[m1]], %[[m1]]
return %3, %4 : tensor<1xi1>, tensor<1xi1>
}


// -----

// CHECK-LABEL: @multiple_measure_read_replaced
func.func public @multiple_measure_read_replaced() -> (tensor<1xi1>, tensor<1xi1>, tensor<1xi1>) {
// CHECK: %[[q:.+]] = "qillr.alloc"() <{size = 1 : i64}> : () -> !qillr.qubit
%0 = "qillr.alloc"() <{size = 1 : i64}> : () -> !qillr.qubit
// CHECK: %[[r:.+]] = "qillr.ralloc"() <{size = 1 : i64}> : () -> !qillr.result
%1 = "qillr.ralloc"() <{size = 1 : i64}> : () -> !qillr.result
// CHECK: "qillr.measure"(%[[q]], %[[r]]) <{inputIndex = [], resultIndex = []}> : (!qillr.qubit, !qillr.result) -> ()
"qillr.measure"(%0, %1) : (!qillr.qubit, !qillr.result) -> ()
// CHECK: %[[m1:.+]] = "qpu.to_bits"(%[[r]]) : (!qillr.result) -> tensor<1xi1>
%3 = "qpu.to_bits"(%1) : (!qillr.result) -> tensor<1xi1>
// CHECK-NOT: "qpu.to_bits"(%[[r]]) : (!qillr.result) -> tensor<1xi1>
%4 = "qpu.to_bits"(%1) : (!qillr.result) -> tensor<1xi1>
"qillr.reset"(%0) : (!qillr.qubit) -> ()
// CHECK: "qillr.measure"(%[[q]], %[[r]]) <{inputIndex = [], resultIndex = []}> : (!qillr.qubit, !qillr.result) -> ()
"qillr.measure"(%0, %1) : (!qillr.qubit, !qillr.result) -> ()
// CHECK: %[[m2:.+]] = "qpu.to_bits"(%[[r]]) : (!qillr.result) -> tensor<1xi1>
%5 = "qpu.to_bits"(%1) : (!qillr.result) -> tensor<1xi1>
// CHECK: return %[[m1]], %[[m1]], %[[m2]]
return %3, %4, %5 : tensor<1xi1>, tensor<1xi1>, tensor<1xi1>
}


// -----

// CHECK-LABEL: @multiple_measure_read_replaced_in_if
func.func public @multiple_measure_read_replaced_in_if(%condition: i1) -> (tensor<1xi1>, tensor<1xi1>, tensor<1xi1>) {
// CHECK: %[[q:.+]] = "qillr.alloc"() <{size = 1 : i64}> : () -> !qillr.qubit
%0 = "qillr.alloc"() <{size = 1 : i64}> : () -> !qillr.qubit
// CHECK: %[[r:.+]] = "qillr.ralloc"() <{size = 1 : i64}> : () -> !qillr.result
%1 = "qillr.ralloc"() <{size = 1 : i64}> : () -> !qillr.result
// CHECK: "qillr.measure"(%[[q]], %[[r]]) <{inputIndex = [], resultIndex = []}> : (!qillr.qubit, !qillr.result) -> ()
"qillr.measure"(%0, %1) : (!qillr.qubit, !qillr.result) -> ()
// CHECK: %[[m1:.+]] = "qpu.to_bits"(%[[r]]) : (!qillr.result) -> tensor<1xi1>
%3 = "qpu.to_bits"(%1) : (!qillr.result) -> tensor<1xi1>
// CHECK: %[[if_result:.+]] = scf.if
%4 = scf.if %condition -> (tensor<1xi1>) {
  // READS-NOT: "qpu.to_bits"
  // CSE: %[[INNER:.*]] = "qpu.to_bits"
  %read = "qpu.to_bits"(%1) : (!qillr.result) -> tensor<1xi1>
  // READS: scf.yield %[[m1]] : tensor<1xi1>
  // CSE: scf.yield %[[INNER]] : tensor<1xi1>
  scf.yield %read : tensor<1xi1>
} else {
  // CHECK: scf.yield %[[m1]] : tensor<1xi1>
  scf.yield %3 : tensor<1xi1>
}
"qillr.reset"(%0) : (!qillr.qubit) -> ()
// CHECK: "qillr.measure"(%[[q]], %[[r]]) <{inputIndex = [], resultIndex = []}> : (!qillr.qubit, !qillr.result) -> ()
"qillr.measure"(%0, %1) : (!qillr.qubit, !qillr.result) -> ()
// CHECK: %[[m2:.+]] = "qpu.to_bits"(%[[r]]) : (!qillr.result) -> tensor<1xi1>
%5 = "qpu.to_bits"(%1) : (!qillr.result) -> tensor<1xi1>
// CHECK: return %[[m1]], %[[if_result]], %[[m2]]
return %3, %4, %5 : tensor<1xi1>, tensor<1xi1>, tensor<1xi1>
}

// -----

// A source passed into the function must not be replaced with zero merely
// because this function contains no measurement operation.
// CHECK-LABEL: @external_storage
func.func @external_storage(%r: !qillr.result) -> tensor<1xi1> {
  // CHECK: %[[BITS:.*]] = "qpu.to_bits"(%arg0)
  %bits = "qpu.to_bits"(%r) : (!qillr.result) -> tensor<1xi1>
  // CHECK: return %[[BITS]]
  return %bits : tensor<1xi1>
}

// -----

// A write inside a nested region invalidates an earlier snapshot.
// CHECK-LABEL: @conditional_write
func.func @conditional_write(%r: !qillr.result, %q: !qillr.qubit, %cond: i1) -> (tensor<1xi1>, tensor<1xi1>) {
  // CHECK: %[[BEFORE:.*]] = "qpu.to_bits"
  %before = "qpu.to_bits"(%r) : (!qillr.result) -> tensor<1xi1>
  // CHECK: scf.if
  scf.if %cond {
    "qillr.measure"(%q, %r) : (!qillr.qubit, !qillr.result) -> ()
  }
  // CHECK: %[[AFTER:.*]] = "qpu.to_bits"
  %after = "qpu.to_bits"(%r) : (!qillr.result) -> tensor<1xi1>
  // CHECK: return %[[BEFORE]], %[[AFTER]]
  return %before, %after : tensor<1xi1>, tensor<1xi1>
}

// -----

// A read in a loop cannot reuse a pre-loop snapshot: each iteration writes.
// CHECK-LABEL: @loop_write
func.func @loop_write(%r: !qillr.result, %q: !qillr.qubit) -> (tensor<1xi1>, tensor<1xi1>) {
  %c0 = arith.constant 0 : index
  %c1 = arith.constant 1 : index
  %c2 = arith.constant 2 : index
  // CHECK: %[[BEFORE:.*]] = "qpu.to_bits"
  %before = "qpu.to_bits"(%r) : (!qillr.result) -> tensor<1xi1>
  // CHECK: scf.for
  %last = scf.for %i = %c0 to %c2 step %c1 iter_args(%prev = %before) -> tensor<1xi1> {
    // CHECK: %[[CURRENT:.*]] = "qpu.to_bits"
    %current = "qpu.to_bits"(%r) : (!qillr.result) -> tensor<1xi1>
    "qillr.measure"(%q, %r) : (!qillr.qubit, !qillr.result) -> ()
    // CHECK: scf.yield %[[CURRENT]]
    scf.yield %current : tensor<1xi1>
  }
  return %before, %last : tensor<1xi1>, tensor<1xi1>
}
