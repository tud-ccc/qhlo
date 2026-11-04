// RUN: quantum-opt -canonicalize -split-input-file %s | FileCheck %s

// CHECK-LABEL: func.func @triple_h_cancel(
func.func @triple_h_cancel() -> !quantum.qubit<1> {
  // CHECK-DAG: %[[Q1:.+]] = "quantum.alloc"() : () -> !quantum.qubit<1>
  %q1 = "quantum.alloc"() : () -> (!quantum.qubit<1>)
  // CHECK-NOT: "quantum.H"
  %q2 = "quantum.H" (%q1) : (!quantum.qubit<1>) -> (!quantum.qubit<1>)
  %q3 = "quantum.H" (%q2) : (!quantum.qubit<1>) -> (!quantum.qubit<1>)
  // CHECK: %[[Q4:.+]] = "quantum.H"(%[[Q1]]) : (!quantum.qubit<1>) -> !quantum.qubit<1>
  %q4 = "quantum.H" (%q3) : (!quantum.qubit<1>) -> (!quantum.qubit<1>)
  // CHECK-NOT: "quantum.H"
  // CHECK: return %[[Q4]]
  return %q4 : !quantum.qubit<1>
}

// -----

// CHECK-LABEL: func.func @interleaved_gates_no_cancel(
func.func @interleaved_gates_no_cancel() -> !quantum.qubit<1> {
  // CHECK-DAG: %[[Q1:.+]] = "quantum.alloc"() : () -> !quantum.qubit<1>
  %q1 = "quantum.alloc"() : () -> (!quantum.qubit<1>)
  // CHECK-DAG: %[[Q2:.+]] = "quantum.H"(%[[Q1]]) : (!quantum.qubit<1>) -> !quantum.qubit<1>
  %q2 = "quantum.H" (%q1) : (!quantum.qubit<1>) -> (!quantum.qubit<1>)
  // CHECK-DAG: %[[Q3:.+]] = "quantum.X"(%[[Q2]]) : (!quantum.qubit<1>) -> !quantum.qubit<1>
  %q3 = "quantum.X" (%q2) : (!quantum.qubit<1>) -> (!quantum.qubit<1>)
  // CHECK-DAG: %[[Q4:.+]] = "quantum.H"(%[[Q3]]) : (!quantum.qubit<1>) -> !quantum.qubit<1>
  %q4 = "quantum.H" (%q3) : (!quantum.qubit<1>) -> (!quantum.qubit<1>)
  // CHECK: return %[[Q4]] : !quantum.qubit<1>
  return %q4 : !quantum.qubit<1>
}

// -----

// CHECK-LABEL: func.func @interleaved_gates_do_cancel(
func.func @interleaved_gates_do_cancel() -> !quantum.qubit<1> {
  // CHECK-DAG: %[[Q1:.+]] = "quantum.alloc"() : () -> !quantum.qubit<1>
  %q1 = "quantum.alloc"() : () -> (!quantum.qubit<1>)
  // CHECK-DAG: %[[Q2:.+]] = "quantum.alloc"() : () -> !quantum.qubit<1>
  %q2 = "quantum.alloc"() : () -> (!quantum.qubit<1>)
  // CHECK-NOT: "quantum.H"
  %q3 = "quantum.H" (%q1) : (!quantum.qubit<1>) -> (!quantum.qubit<1>)
  // CHECK: %[[Q4:.+]] = "quantum.X"(%[[Q2]]) : (!quantum.qubit<1>) -> !quantum.qubit<1>
  %q4 = "quantum.X" (%q2) : (!quantum.qubit<1>) -> (!quantum.qubit<1>)
  // CHECK-NOT: "quantum.H"
  %q5 = "quantum.H" (%q3) : (!quantum.qubit<1>) -> (!quantum.qubit<1>)
  // CHECK: "quantum.deallocate"(%[[Q4]]) : (!quantum.qubit<1>) -> ()
  "quantum.deallocate" (%q4) : (!quantum.qubit<1>) -> ()
  // CHECK-NOT: "quantum.H"
  // CHECK: return %[[Q1]] : !quantum.qubit<1>
  return %q5 : !quantum.qubit<1>
}

// -----

// Ensures different qubits are not affected.
// CHECK-LABEL: func.func @multi_qubit_no_h_cancel(
func.func @multi_qubit_no_h_cancel() -> (!quantum.qubit<1>, !quantum.qubit<1>) {
  // CHECK-DAG: %[[Q1:.+]] = "quantum.alloc"() : () -> !quantum.qubit<1>
  %q1 = "quantum.alloc"() : () -> (!quantum.qubit<1>)
  // CHECK-DAG: %[[Q2:.+]] = "quantum.alloc"() : () -> !quantum.qubit<1>
  %q2 = "quantum.alloc"() : () -> (!quantum.qubit<1>)
  // CHECK-DAG: %[[Q3:.+]] = "quantum.H"(%[[Q1]]) : (!quantum.qubit<1>) -> !quantum.qubit<1>
  %q3 = "quantum.H" (%q1) : (!quantum.qubit<1>) -> (!quantum.qubit<1>)
    // CHECK-DAG: %[[Q4:.+]] = "quantum.H"(%[[Q2]]) : (!quantum.qubit<1>) -> !quantum.qubit<1>
  %q4 = "quantum.H" (%q2) : (!quantum.qubit<1>) -> (!quantum.qubit<1>)
  return %q3, %q4 : !quantum.qubit<1>, !quantum.qubit<1>
}

// -----

// CHECK-LABEL: func.func @single_h_no_cancel(
func.func @single_h_no_cancel() -> !quantum.qubit<1> {
  // CHECK-DAG: %[[Q1:.+]] = "quantum.alloc"() : () -> !quantum.qubit<1>
  %q1 = "quantum.alloc"() : () -> (!quantum.qubit<1>)
  // CHECK-DAG: %[[Q2:.+]] = "quantum.H"(%[[Q1]]) : (!quantum.qubit<1>) -> !quantum.qubit<1>
  %q2 = "quantum.H" (%q1) : (!quantum.qubit<1>) -> (!quantum.qubit<1>)
  return %q2 : !quantum.qubit<1>
}

// -----

// CHECK-LABEL: func.func @single_x_no_cancel(
func.func @single_x_no_cancel() -> !quantum.qubit<1> {
  // CHECK-DAG: %[[Q1:.+]] = "quantum.alloc"() : () -> !quantum.qubit<1>
  %q1 = "quantum.alloc"() : () -> (!quantum.qubit<1>)
  // CHECK-DAG: %[[Q2:.+]] = "quantum.X"(%[[Q1]]) : (!quantum.qubit<1>) -> !quantum.qubit<1>
  %q2 = "quantum.X" (%q1) : (!quantum.qubit<1>) -> (!quantum.qubit<1>)
  return %q2 : !quantum.qubit<1>
}

// -----

// CHECK-LABEL: func.func @triple_x_cancel(
func.func @triple_x_cancel() -> !quantum.qubit<1> {
  // CHECK-DAG: %[[Q1:.+]] = "quantum.alloc"() : () -> !quantum.qubit<1>
  %q1 = "quantum.alloc"() : () -> (!quantum.qubit<1>)
  // CHECK-NOT: "quantum.X"
  %q2 = "quantum.X" (%q1) : (!quantum.qubit<1>) -> (!quantum.qubit<1>)
  %q3 = "quantum.X" (%q2) : (!quantum.qubit<1>) -> (!quantum.qubit<1>)
  // CHECK: %[[Q4:.+]] = "quantum.X"(%[[Q1]]) : (!quantum.qubit<1>) -> !quantum.qubit<1>
  %q4 = "quantum.X" (%q3) : (!quantum.qubit<1>) -> (!quantum.qubit<1>)
  // CHECK-NOT: "quantum.X"
  // CHECK: return %[[Q4]] : !quantum.qubit<1>
  return %q4 : !quantum.qubit<1>
}

// -----

// CHECK-LABEL: func.func @multi_qubit_no_x_cancel(
func.func @multi_qubit_no_x_cancel() -> (!quantum.qubit<1>, !quantum.qubit<1>) {
  // CHECK-DAG: %[[Q1:.+]] = "quantum.alloc"() : () -> !quantum.qubit<1>
  %q1 = "quantum.alloc"() : () -> (!quantum.qubit<1>)
  // CHECK-DAG: %[[Q2:.+]] = "quantum.alloc"() : () -> !quantum.qubit<1>
  %q2 = "quantum.alloc"() : () -> (!quantum.qubit<1>)
  // CHECK-DAG: %[[Q3:.+]] = "quantum.X"(%[[Q1]]) : (!quantum.qubit<1>) -> !quantum.qubit<1>
  %q3 = "quantum.X" (%q1) : (!quantum.qubit<1>) -> (!quantum.qubit<1>)
  // CHECK-DAG: %[[Q4:.+]] = "quantum.X"(%[[Q2]]) : (!quantum.qubit<1>) -> !quantum.qubit<1>
  %q4 = "quantum.X" (%q2) : (!quantum.qubit<1>) -> (!quantum.qubit<1>)
  return %q3, %q4 : !quantum.qubit<1>, !quantum.qubit<1>
}

// -----

// CHECK-LABEL: func.func @cnot_cancel(
func.func @cnot_cancel() -> (!quantum.qubit<1>, !quantum.qubit<1>) {
  // CHECK-DAG: %[[Q1:.+]] = "quantum.alloc"() : () -> !quantum.qubit<1>
  %q1 = "quantum.alloc"() : () -> (!quantum.qubit<1>)
  // CHECK-DAG: %[[Q2:.+]] = "quantum.alloc"() : () -> !quantum.qubit<1>
  %q2 = "quantum.alloc"() : () -> (!quantum.qubit<1>)
  // CHECK-NOT: "quantum.CNOT"
  %q3, %q4 = "quantum.CNOT" (%q1, %q2) : (!quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>)
  // CHECK-NOT: "quantum.CNOT"
  %q5, %q6 = "quantum.CNOT" (%q3, %q4) : (!quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>)
  // CHECK: return %[[Q1]], %[[Q2]]
  return %q5, %q6 : !quantum.qubit<1>, !quantum.qubit<1>
}

// -----

// CHECK-LABEL: func.func @ccnot_cancel(
func.func @ccnot_cancel() -> (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>) {
  // CHECK-DAG: %[[Q1:.+]] = "quantum.alloc"() : () -> !quantum.qubit<1>
  %q1 = "quantum.alloc"() : () -> (!quantum.qubit<1>)
  // CHECK-DAG: %[[Q2:.+]] = "quantum.alloc"() : () -> !quantum.qubit<1>
  %q2 = "quantum.alloc"() : () -> (!quantum.qubit<1>)
  // CHECK-DAG: %[[Q3:.+]] = "quantum.alloc"() : () -> !quantum.qubit<1>
  %q3 = "quantum.alloc"() : () -> (!quantum.qubit<1>)
  // CHECK-NOT: "quantum.CCX"
  %q4, %q5, %q6 = "quantum.CCX" (%q1, %q2, %q3) : (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>)
  // CHECK-NOT: "quantum.CCX"
  %q7, %q8, %q9 = "quantum.CCX" (%q4, %q5, %q6) : (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>)
  // CHECK: return %[[Q1]], %[[Q2]], %[[Q3]]
  return %q7, %q8, %q9 : !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>
}
