// RUN: quantum-opt %s --convert-quantum-to-qillr -split-input-file | FileCheck %s

// CHECK-LABEL: func.func @return_single_qubit(
// CHECK: ) -> tensor<1xi1> {
func.func @return_single_qubit() -> tensor<1xi1> {
    // CHECK-DAG: %[[Q:.+]] = "qillr.alloc"() <{size = 1 : i64}> : () -> !qillr.qubit
    %q = "quantum.alloc" () : () -> (!quantum.qubit<1>)
    // CHECK-DAG: %[[R:.+]] = "qillr.ralloc"() <{size = 1 : i64}> : () -> !qillr.result
    %c = "arith.constant"() <{value = dense<false> : tensor<1xi1>}> : () -> tensor<1xi1>
    // CHECK-DAG: "qillr.measure"(%[[Q]], %[[R]]) <{inputIndex = [0], resultIndex = [0]}> : (!qillr.qubit, !qillr.result) -> ()
    // CHECK-DAG: %[[MT:.+]] = "qpu.to_bits"(%[[R]]) : (!qillr.result) -> tensor<1xi1>
    %m, %q_m = "quantum.measure" (%q) : (!quantum.qubit<1>) -> (!quantum.measurement<1>, !quantum.qubit<1>)
    %mt = "qpu.to_bits"(%m) : (!quantum.measurement<1>) -> (tensor<1xi1>)
    %cnew = "tensor.insert_slice"(%mt, %c) <{operandSegmentSizes = array<i32: 1, 1, 0, 0, 0>, static_offsets = array<i64: 0>, static_sizes = array<i64: 1>, static_strides = array<i64: 1>}> : (tensor<1xi1>, tensor<1xi1>) -> tensor<1xi1>
    // CHECK-DAG: "qillr.deallocate"(%[[Q]]) <{index = [0]}> : (!qillr.qubit) -> ()
    "quantum.deallocate" (%q_m) : (!quantum.qubit<1>) -> ()
    // CHECK-NEXT: return %[[MT]]
    func.return %cnew : tensor<1xi1>
}

// -----

// CHECK-LABEL: func.func @return_single_measurement_result(
// CHECK: ) -> tensor<1xi1> {
func.func @return_single_measurement_result() -> (tensor<1xi1>) {
    // CHECK-DAG: %[[Q:.+]] = "qillr.alloc"() <{size = 1 : i64}> : () -> !qillr.qubit
    %q = "quantum.alloc" () : () -> (!quantum.qubit<1>)
    // CHECK-DAG: %[[R:.+]] = "qillr.ralloc"() <{size = 1 : i64}> : () -> !qillr.result
    %c = "arith.constant"() <{value = dense<false> : tensor<1xi1>}> : () -> tensor<1xi1>
    // CHECK-DAG: "qillr.measure"(%[[Q]], %[[R]]) <{inputIndex = [0], resultIndex = [0]}> : (!qillr.qubit, !qillr.result) -> ()
    // CHECK-DAG: %[[MT:.+]] = "qpu.to_bits"(%[[R]]) : (!qillr.result) -> tensor<1xi1>
    %m, %q_m = "quantum.measure" (%q) : (!quantum.qubit<1>) -> (!quantum.measurement<1>, !quantum.qubit<1>)
    %mt = "qpu.to_bits"(%m) : (!quantum.measurement<1>) -> (tensor<1xi1>)
    %cnew = "tensor.insert_slice"(%mt, %c) <{operandSegmentSizes = array<i32: 1, 1, 0, 0, 0>, static_offsets = array<i64: 0>, static_sizes = array<i64: 1>, static_strides = array<i64: 1>}> : (tensor<1xi1>, tensor<1xi1>) -> tensor<1xi1>
    // CHECK-DAG: "qillr.deallocate"(%[[Q]]) <{index = [0]}> : (!qillr.qubit) -> ()
    "quantum.deallocate" (%q_m) : (!quantum.qubit<1>) -> ()
    // CHECK-DAG: return %[[MT]]
    func.return %cnew : tensor<1xi1>
}

// -----

// CHECK-LABEL: func.func @convertHOp(
func.func @convertHOp() -> () {
    // CHECK-NEXT: %[[Q:.+]] = "qillr.alloc"() <{size = 1 : i64}> : () -> !qillr.qubit
    %q = "quantum.alloc" () : () -> (!quantum.qubit<1>)
    // CHECK-NEXT: "qillr.H"(%[[Q]]) <{index = [0]}> : (!qillr.qubit) -> ()
    %q1 = "quantum.H" (%q) : (!quantum.qubit<1>) -> (!quantum.qubit<1>)
    // CHECK-DAG: "qillr.deallocate"(%[[Q]]) <{index = [0]}> : (!qillr.qubit) -> ()
    "quantum.deallocate" (%q1) : (!quantum.qubit<1>) -> ()
    // CHECK-NEXT: return
    return
}

// -----

// CHECK-LABEL: func.func @convertSwap(
func.func @convertSwap() -> () {
    // CHECK-NEXT: %[[Q1:.+]] = "qillr.alloc"() <{size = 1 : i64}>  : () -> !qillr.qubit
    // CHECK-NEXT: %[[Q2:.+]] = "qillr.alloc"() <{size = 1 : i64}>  : () -> !qillr.qubit
    %q1 = "quantum.alloc"() : () -> (!quantum.qubit<1>)
    %q2 = "quantum.alloc"() : () -> (!quantum.qubit<1>)
    // CHECK-NEXT: "qillr.swap"(%[[Q1]], %[[Q2]]) <{lhsIndex = [0], rhsIndex = [0]}> : (!qillr.qubit, !qillr.qubit) -> ()
    %q1_out, %q2_out = "quantum.SWAP"(%q1, %q2) : (!quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>)
    return
}

// -----

// CHECK-LABEL: func.func @convertFunc(
func.func @convertFunc() -> () {
    // CHECK-NEXT: %[[Q:.+]] = "qillr.alloc"() <{size = 1 : i64}>  : () -> !qillr.qubit
    %q = "quantum.alloc"() : () -> (!quantum.qubit<1>)
    // CHECK-DAG: "qillr.deallocate"(%[[Q]]) <{index = [0]}> : (!qillr.qubit) -> ()
    "quantum.deallocate"(%q) : (!quantum.qubit<1>) -> ()
    return
}

// -----

// CHECK-LABEL: func.func @convert_split(
func.func @convert_split() -> () {
    // CHECK-DAG: %[[Q:.+]] = "qillr.alloc"() <{size = 2 : i64}>  : () -> !qillr.qubit
    %q = "quantum.alloc"() : () -> (!quantum.qubit<2>)
    // CHECK-NOT: "quantum.split"
    %q1, %q2 = "quantum.split"(%q) : (!quantum.qubit<2>) -> (!quantum.qubit<1>, !quantum.qubit<1>)
    // CHECK-DAG: "qillr.deallocate"(%[[Q]]) <{index = [0]}> : (!qillr.qubit) -> ()
    "quantum.deallocate"(%q1) : (!quantum.qubit<1>) -> ()
    // CHECK-DAG: "qillr.deallocate"(%[[Q]]) <{index = [1]}> : (!qillr.qubit) -> ()
    "quantum.deallocate"(%q2) : (!quantum.qubit<1>) -> ()
    return
}

// -----

// CHECK-LABEL: func.func @convert_split_merge(
func.func @convert_split_merge() -> () {
    // CHECK-DAG: %[[Q:.+]] = "qillr.alloc"() <{size = 2 : i64}>  : () -> !qillr.qubit
    %q = "quantum.alloc"() : () -> (!quantum.qubit<2>)
    // CHECK-NOT: "quantum.split"
    %q1, %q2 = "quantum.split"(%q) : (!quantum.qubit<2>) -> (!quantum.qubit<1>, !quantum.qubit<1>)
    // CHECK-NOT: "quantum.merge"
    %q3 = "quantum.merge" (%q1, %q2) : (!quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<2>)
    // CHECK-DAG: "qillr.deallocate"(%[[Q]]) <{index = []}> : (!qillr.qubit) -> ()
    "quantum.deallocate"(%q3) : (!quantum.qubit<2>) -> ()
    return
}
