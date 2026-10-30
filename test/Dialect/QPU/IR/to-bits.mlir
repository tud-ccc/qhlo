// RUN: quantum-opt %s -cse | FileCheck %s

// Immutable measurement values can be read repeatedly without memory effects.
// CHECK-LABEL: @snapshot
func.func @snapshot(%m: !quantum.measurement<2>) -> (tensor<2xi1>, tensor<2xi1>) {
  // CHECK: %[[BITS:.*]] = "qpu.to_bits"
  // CHECK-NOT: "qpu.to_bits"
  // CHECK: return %[[BITS]], %[[BITS]]
  %a = "qpu.to_bits"(%m) : (!quantum.measurement<2>) -> tensor<2xi1>
  %b = "qpu.to_bits"(%m) : (!quantum.measurement<2>) -> tensor<2xi1>
  return %a, %b : tensor<2xi1>, tensor<2xi1>
}

// Mutable result storage must be read again after a measurement writes it.
// CHECK-LABEL: @storage
func.func @storage(%q: !qillr.qubit, %r: !qillr.result) -> (tensor<2xi1>, tensor<2xi1>) {
  // CHECK: %[[BEFORE:.*]] = "qpu.to_bits"
  %a = "qpu.to_bits"(%r) : (!qillr.result) -> tensor<2xi1>
  // CHECK: "qillr.measure"
  "qillr.measure"(%q, %r) : (!qillr.qubit, !qillr.result) -> ()
  // CHECK: %[[AFTER:.*]] = "qpu.to_bits"
  %b = "qpu.to_bits"(%r) : (!qillr.result) -> tensor<2xi1>
  // CHECK: return %[[BEFORE]], %[[AFTER]]
  return %a, %b : tensor<2xi1>, tensor<2xi1>
}

// Buffer materialization creates distinct allocations, even for the same source.
// CHECK-LABEL: @buffers
func.func @buffers(%m: !quantum.measurement<2>) -> (memref<2xi1>, memref<2xi1>) {
  // CHECK: %[[A:.*]] = "qpu.to_bits"
  // CHECK: %[[B:.*]] = "qpu.to_bits"
  // CHECK: return %[[A]], %[[B]]
  %a = "qpu.to_bits"(%m) : (!quantum.measurement<2>) -> memref<2xi1>
  %b = "qpu.to_bits"(%m) : (!quantum.measurement<2>) -> memref<2xi1>
  return %a, %b : memref<2xi1>, memref<2xi1>
}

// CHECK-LABEL: @storage_buffer
func.func @storage_buffer(%r: !qillr.result) -> memref<2xi1> {
  // CHECK: "qpu.to_bits"(%{{.*}}) : (!qillr.result) -> memref<2xi1>
  %bits = "qpu.to_bits"(%r) : (!qillr.result) -> memref<2xi1>
  return %bits : memref<2xi1>
}
