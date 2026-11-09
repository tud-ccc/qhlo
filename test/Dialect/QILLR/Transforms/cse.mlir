// RUN: quantum-opt %s -cse -split-input-file | FileCheck %s
// --debug -mlir-print-ir-after-all

// CHECK-LABEL: @single_read_replaced
func.func public @single_read_replaced() -> (tensor<1xi1>, tensor<1xi1>) {
// CHECK: %[[q:.+]] = "qillr.alloc"() <{size = 1 : i64}> : () -> !qillr.qubit
%0 = "qillr.alloc"() <{size = 1 : i64}> : () -> !qillr.qubit
// CHECK: %[[r:.+]] = "qillr.ralloc"() <{size = 1 : i64}> : () -> !qillr.result
%1 = "qillr.ralloc"() <{size = 1 : i64}> : () -> !qillr.result
// CHECK: "qillr.measure"(%[[q]], %[[r]]) <{inputIndex = [], resultIndex = []}> : (!qillr.qubit, !qillr.result) -> ()
"qillr.measure"(%0, %1) <{inputIndex = [], resultIndex = []}> : (!qillr.qubit, !qillr.result) -> ()
// CHECK: %[[m1:.+]] = "qpu.to_bits"(%[[r]]) : (!qillr.result) -> tensor<1xi1>
%3 = "qpu.to_bits"(%1) : (!qillr.result) -> tensor<1xi1>
// CHECK-NOT: "qpu.to_bits"(%[[r]]) : (!qillr.result) -> tensor<1xi1>
%5 = "qpu.to_bits"(%1) : (!qillr.result) -> tensor<1xi1>
// CHECK: "qillr.reset"(%[[q]]) <{index = []}> : (!qillr.qubit) -> ()
"qillr.reset"(%0) <{index = []}> : (!qillr.qubit) -> ()
// CHECK: return %[[m1]], %[[m1]] : tensor<1xi1>, tensor<1xi1>
return %3, %5 : tensor<1xi1>, tensor<1xi1>
}


// -----

// CHECK-LABEL: @multiple_measure_read_replaced
func.func public @multiple_measure_read_replaced() -> (tensor<1xi1>, tensor<1xi1>, tensor<1xi1>) {
// CHECK: %[[q:.+]] = "qillr.alloc"() <{size = 1 : i64}> : () -> !qillr.qubit
%0 = "qillr.alloc"() <{size = 1 : i64}> : () -> !qillr.qubit
// CHECK: %[[r:.+]] = "qillr.ralloc"() <{size = 1 : i64}> : () -> !qillr.result
%1 = "qillr.ralloc"() <{size = 1 : i64}> : () -> !qillr.result
// CHECK: "qillr.measure"(%[[q]], %[[r]]) <{inputIndex = [], resultIndex = []}> : (!qillr.qubit, !qillr.result) -> ()
"qillr.measure"(%0, %1) <{inputIndex = [], resultIndex = []}> : (!qillr.qubit, !qillr.result) -> ()
// CHECK: %[[m1:.+]] = "qpu.to_bits"(%[[r]]) : (!qillr.result) -> tensor<1xi1>
%3 = "qpu.to_bits"(%1) : (!qillr.result) -> tensor<1xi1>
// CHECK-NOT: "qpu.to_bits"(%[[r]])
%5 = "qpu.to_bits"(%1) : (!qillr.result) -> tensor<1xi1>
// CHECK: "qillr.reset"(%[[q]]) <{index = []}> : (!qillr.qubit) -> ()
"qillr.reset"(%0) <{index = []}> : (!qillr.qubit) -> ()
// CHECK: "qillr.measure"(%[[q]], %[[r]]) <{inputIndex = [], resultIndex = []}> : (!qillr.qubit, !qillr.result) -> ()
"qillr.measure"(%0, %1) <{inputIndex = [], resultIndex = []}> : (!qillr.qubit, !qillr.result) -> ()
// CHECK: %[[m2:.+]] = "qpu.to_bits"(%[[r]]) : (!qillr.result) -> tensor<1xi1>
%7 = "qpu.to_bits"(%1) : (!qillr.result) -> tensor<1xi1>
// CHECK: return %[[m1]], %[[m1]], %[[m2]]
return %3, %5, %7 : tensor<1xi1>, tensor<1xi1>, tensor<1xi1>
}


// -----
