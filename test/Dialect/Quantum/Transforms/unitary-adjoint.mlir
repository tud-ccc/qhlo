// RUN: quantum-opt -canonicalize -split-input-file %s | FileCheck %s

// CHECK-LABEL: func.func @s_sdg_cancel(
func.func @s_sdg_cancel() -> (!quantum.qubit<1>) {
  // CHECK: %[[Q1:.+]] = "quantum.alloc"() : () -> !quantum.qubit<1>
  %q1 = "quantum.alloc"() : () -> (!quantum.qubit<1>)
  // CHECK-NOT: "quantum.S"
  %q2 = "quantum.S" (%q1) : (!quantum.qubit<1>) -> (!quantum.qubit<1>)
  // CHECK-NOT: "quantum.Sdg"
  %q3 = "quantum.Sdg" (%q2) : (!quantum.qubit<1>) -> (!quantum.qubit<1>)
  // CHECK: return %[[Q1]]
  return %q3 : !quantum.qubit<1>
}

// -----

// CHECK-LABEL: func.func @sdg_s_cancel(
func.func @sdg_s_cancel() -> (!quantum.qubit<1>) {
  // CHECK: %[[Q1:.+]] = "quantum.alloc"() : () -> !quantum.qubit<1>
  %q1 = "quantum.alloc"() : () -> (!quantum.qubit<1>)
  // CHECK-NOT: "quantum.S"
  %q2 = "quantum.Sdg" (%q1) : (!quantum.qubit<1>) -> (!quantum.qubit<1>)
  // CHECK-NOT: "quantum.Sdg"
  %q3 = "quantum.S" (%q2) : (!quantum.qubit<1>) -> (!quantum.qubit<1>)
  // CHECK: return %[[Q1]]
  return %q3 : !quantum.qubit<1>
}

// -----

// CHECK-LABEL: func.func @sdg_sdg_no_cancel(
func.func @sdg_sdg_no_cancel() -> (!quantum.qubit<1>) {
  // CHECK: %[[Q1:.+]] = "quantum.alloc"() : () -> !quantum.qubit<1>
  %q1 = "quantum.alloc"() : () -> (!quantum.qubit<1>)
  // CHECK: %[[Q2:.+]] = "quantum.Sdg"(%[[Q1]]) : (!quantum.qubit<1>) -> !quantum.qubit<1>
  %q2 = "quantum.Sdg" (%q1) : (!quantum.qubit<1>) -> (!quantum.qubit<1>)
  // CHECK: %[[Q3:.+]] = "quantum.Sdg"(%[[Q2]]) : (!quantum.qubit<1>) -> !quantum.qubit<1>
  %q3 = "quantum.Sdg" (%q2) : (!quantum.qubit<1>) -> (!quantum.qubit<1>)
  // CHECK: return %[[Q3]]
  return %q3 : !quantum.qubit<1>
}

// -----

// CHECK-LABEL: func.func @sx_sx_x(
func.func @sx_sx_x() -> (!quantum.qubit<1>) {
  // CHECK: %[[Q1:.+]] = "quantum.alloc"() : () -> !quantum.qubit<1>
  %q1 = "quantum.alloc"() : () -> (!quantum.qubit<1>)
  // CHECK: %[[Q2:.+]] = "quantum.X"(%[[Q1]]) : (!quantum.qubit<1>) -> !quantum.qubit<1>
  %q2 = "quantum.SX" (%q1) : (!quantum.qubit<1>) -> (!quantum.qubit<1>)
  // CHECK-NOT: "quantum.SX"
  %q3 = "quantum.SX" (%q2) : (!quantum.qubit<1>) -> (!quantum.qubit<1>)
  // CHECK: return %[[Q2]]
  return %q3 : !quantum.qubit<1>
}

// -----

// CHECK-LABEL: func.func @rz_rz(
func.func @rz_rz() -> (!quantum.qubit<1>) {
  // CHECK: %[[Q1:.+]] = "quantum.alloc"() : () -> !quantum.qubit<1>
  %q1 = "quantum.alloc"() : () -> (!quantum.qubit<1>)
  %theta = arith.constant 0.5 : f64
  %theta_neg = arith.constant -0.5 : f64
  // CHECK-NOT: "quantum.Rz"
  %q2 = "quantum.Rz" (%q1, %theta) : (!quantum.qubit<1>, f64) -> (!quantum.qubit<1>)
  %q3 = "quantum.Rz" (%q2, %theta_neg) : (!quantum.qubit<1>, f64) -> (!quantum.qubit<1>)
  // CHECK: return %[[Q1]]
  return %q3 : !quantum.qubit<1>
}

// -----

// CHECK-LABEL: func.func @tdg_s(
func.func @tdg_s() -> (!quantum.qubit<1>) {
  // CHECK: %[[Q1:.+]] = "quantum.alloc"() : () -> !quantum.qubit<1>
  %q1 = "quantum.alloc"() : () -> (!quantum.qubit<1>)
  // CHECK: %[[Q2:.+]] = "quantum.Tdg"(%[[Q1]]) : (!quantum.qubit<1>) -> !quantum.qubit<1>
  %q2 = "quantum.Tdg" (%q1) : (!quantum.qubit<1>) -> (!quantum.qubit<1>)
  // CHECK: %[[Q3:.+]] = "quantum.S"(%[[Q2]]) : (!quantum.qubit<1>) -> !quantum.qubit<1>
  %q3 = "quantum.S" (%q2) : (!quantum.qubit<1>) -> (!quantum.qubit<1>)
  // CHECK: return %[[Q3]]
  return %q3 : !quantum.qubit<1>
}

// -----

// A block argument has no defining operation. Folding must not dereference it
// or discard a controlled region without an applicable cancellation rule.
// CHECK-LABEL: func.func @control_only_block_argument(
// CHECK-SAME: %[[CONTROL:[^:]+]]: !quantum.qubit<1>
func.func @control_only_block_argument(%control: !quantum.qubit<1>) -> !quantum.qubit<1> {
  // CHECK: %[[R:.*]] = "quantum.ctrl"(%[[CONTROL]])
  // CHECK: "quantum.yield"() : () -> ()
  %r = "quantum.ctrl"(%control) ({
    "quantum.yield"() : () -> ()
  }) : (!quantum.qubit<1>) -> !quantum.qubit<1>
  // CHECK: return %[[R]] : !quantum.qubit<1>
  return %r : !quantum.qubit<1>
}
