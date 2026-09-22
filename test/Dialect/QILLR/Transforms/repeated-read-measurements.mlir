// RUN: quantum-opt %s -replace-repeated-reads -split-input-file | FileCheck %s
// RUN: quantum-opt %s -cse -split-input-file | FileCheck %s --check-prefixes=CHECK,CSE

// CHECK-LABEL: @single_read_replaced
func.func public @single_read_replaced() -> (tensor<1xi1>, tensor<1xi1>) {
// CHECK: %[[q:.+]] = "qillr.alloc"() <{size = 1 : i64}> : () -> !qillr.qubit
%0 = "qillr.alloc"() <{size = 1 : i64}> : () -> !qillr.qubit
// CHECK: %[[r:.+]] = "qillr.ralloc"() <{size = 1 : i64}> : () -> !qillr.result
%1 = "qillr.ralloc"() <{size = 1 : i64}> : () -> !qillr.result
// CHECK: "qillr.measure"(%[[q]], %[[r]]) <{inputIndex = [], resultIndex = []}> : (!qillr.qubit, !qillr.result) -> ()
"qillr.measure"(%0, %1) : (!qillr.qubit, !qillr.result) -> ()
// CHECK: %[[m1:.+]] = "qillr.read_measurement"(%[[r]]) <{index = []}> : (!qillr.result) -> tensor<1xi1>
%3 = "qillr.read_measurement"(%1) : (!qillr.result) -> tensor<1xi1>
// CHECK-NOT: "qillr.read_measurement"(%[[r]]) <{index = []}> : (!qillr.result) -> tensor<1xi1>
%4 = "qillr.read_measurement"(%1) : (!qillr.result) -> tensor<1xi1>
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
// CHECK: %[[m1:.+]] = "qillr.read_measurement"(%[[r]]) <{index = []}> : (!qillr.result) -> tensor<1xi1>
%3 = "qillr.read_measurement"(%1) : (!qillr.result) -> tensor<1xi1>
// CHECK-NOT: "qillr.read_measurement"(%[[r]]) <{index = []}> : (!qillr.result) -> tensor<1xi1>
%4 = "qillr.read_measurement"(%1) : (!qillr.result) -> tensor<1xi1>
"qillr.reset"(%0) : (!qillr.qubit) -> ()
// CHECK: "qillr.measure"(%[[q]], %[[r]]) <{inputIndex = [], resultIndex = []}> : (!qillr.qubit, !qillr.result) -> ()
"qillr.measure"(%0, %1) : (!qillr.qubit, !qillr.result) -> ()
// CHECK: %[[m2:.+]] = "qillr.read_measurement"(%[[r]]) <{index = []}> : (!qillr.result) -> tensor<1xi1>
%5 = "qillr.read_measurement"(%1) : (!qillr.result) -> tensor<1xi1>
// CHECK: return %[[m1]], %[[m1]], %[[m2]]
return %3, %4, %5 : tensor<1xi1>, tensor<1xi1>, tensor<1xi1>
}


// -----

// CSE-LABEL: @multiple_measure_read_replaced_in_if
func.func public @multiple_measure_read_replaced_in_if(%condition: i1) -> (tensor<1xi1>, tensor<1xi1>, tensor<1xi1>) {
// CSE: %[[q:.+]] = "qillr.alloc"() <{size = 1 : i64}> : () -> !qillr.qubit
%0 = "qillr.alloc"() <{size = 1 : i64}> : () -> !qillr.qubit
// CSE: %[[r:.+]] = "qillr.ralloc"() <{size = 1 : i64}> : () -> !qillr.result
%1 = "qillr.ralloc"() <{size = 1 : i64}> : () -> !qillr.result
// CSE: "qillr.measure"(%[[q]], %[[r]]) <{inputIndex = [], resultIndex = []}> : (!qillr.qubit, !qillr.result) -> ()
"qillr.measure"(%0, %1) : (!qillr.qubit, !qillr.result) -> ()
// CSE: %[[m1:.+]] = "qillr.read_measurement"(%[[r]]) <{index = []}> : (!qillr.result) -> tensor<1xi1>
%3 = "qillr.read_measurement"(%1) : (!qillr.result) -> tensor<1xi1>
// CSE: %[[if_result:.+]] = scf.if
%4 = scf.if %condition -> (tensor<1xi1>) {
  // CSE-NOT: "qillr.read_measurement"
  %read = "qillr.read_measurement"(%1) : (!qillr.result) -> tensor<1xi1>
  // CSE: scf.yield %[[m1]] : tensor<1xi1>
  scf.yield %read : tensor<1xi1>
} else {
  // CSE: scf.yield %[[m1]] : tensor<1xi1>
  scf.yield %3 : tensor<1xi1>
}
"qillr.reset"(%0) : (!qillr.qubit) -> ()
// CSE: "qillr.measure"(%[[q]], %[[r]]) <{inputIndex = [], resultIndex = []}> : (!qillr.qubit, !qillr.result) -> ()
"qillr.measure"(%0, %1) : (!qillr.qubit, !qillr.result) -> ()
// CSE: %[[m2:.+]] = "qillr.read_measurement"(%[[r]]) <{index = []}> : (!qillr.result) -> tensor<1xi1>
%5 = "qillr.read_measurement"(%1) : (!qillr.result) -> tensor<1xi1>
// CSE: return %[[m1]], %[[if_result]], %[[m2]]
return %3, %4, %5 : tensor<1xi1>, tensor<1xi1>, tensor<1xi1>
}
