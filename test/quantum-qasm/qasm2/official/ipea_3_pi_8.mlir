// RUN: quantum-qasm %S/Inputs/ipea_3_pi_8.qasm | FileCheck %s
// XFAIL: *
// Valid upstream program: its cu declaration conflicts with the embedded qelib1.inc.
// Remove XFAIL when the frontend accepts this program; keep success as the expectation.

// The unmodified upstream source and provenance are in Inputs/ and README.md.
// Check the intended successful lowering, including phase-estimation stages.
// Parameter binding in custom gate bodies is also currently incomplete.

// CHECK: qpu.module @ipea_3_pi_8
// CHECK: sym_name = "cu"
// CHECK: sym_name = "cu1fixed"
// CHECK: "quantum.CNOT"(
// CHECK: "quantum.CNOT"(
// CHECK: "quantum.return"(
// CHECK: function_type = () -> tensor<4xi1>, sym_name = "main"
// CHECK: "quantum.alloc"() : () -> !quantum.qubit<2>

// Iteration 0: controlled powers, feedback, and output bit 0.
// CHECK: "quantum.H"(
// CHECK-COUNT-8: callee = @cu
// CHECK: "quantum.H"(
// CHECK: %[[M0:.*]], %[[Q0:.*]] = "quantum.measure"(
// CHECK-NEXT: %[[T0:.*]] = "quantum.to_tensor"(%[[M0]]) : (!quantum.measurement<1>) -> tensor<1xi1>
// CHECK-NEXT: %[[C0:.*]] = tensor.insert_slice %[[T0]] into %{{.*}}[0] [1] [1] : tensor<1xi1> into tensor<4xi1>

// Iteration 1: controlled powers, feedback, and output bit 1.
// CHECK: %[[RESET1:.*]] = "quantum.reset"(%[[Q0]])
// CHECK: "quantum.H"(%[[RESET1]])
// CHECK-COUNT-4: callee = @cu
// CHECK-COUNT-1: scf.if
// CHECK: "quantum.H"(
// CHECK: %[[M1:.*]], %[[Q1:.*]] = "quantum.measure"(
// CHECK-NEXT: %[[T1:.*]] = "quantum.to_tensor"(%[[M1]]) : (!quantum.measurement<1>) -> tensor<1xi1>
// CHECK-NEXT: %[[C1:.*]] = tensor.insert_slice %[[T1]] into %{{.*}}[1] [1] [1] : tensor<1xi1> into tensor<4xi1>

// Iteration 2: controlled powers, feedback, and output bit 2.
// CHECK: %[[RESET2:.*]] = "quantum.reset"(%[[Q1]])
// CHECK: "quantum.H"(%[[RESET2]])
// CHECK-COUNT-2: callee = @cu
// CHECK-COUNT-3: scf.if
// CHECK: "quantum.H"(
// CHECK: %[[M2:.*]], %[[Q2:.*]] = "quantum.measure"(
// CHECK-NEXT: %[[T2:.*]] = "quantum.to_tensor"(%[[M2]]) : (!quantum.measurement<1>) -> tensor<1xi1>
// CHECK-NEXT: %[[C2:.*]] = tensor.insert_slice %[[T2]] into %{{.*}}[2] [1] [1] : tensor<1xi1> into tensor<4xi1>

// Iteration 3: controlled powers, feedback, and output bit 3.
// CHECK: %[[RESET3:.*]] = "quantum.reset"(%[[Q2]])
// CHECK: "quantum.H"(%[[RESET3]])
// CHECK-COUNT-1: callee = @cu
// CHECK-COUNT-7: scf.if
// CHECK: "quantum.H"(
// CHECK: %[[M3:.*]], %[[Q3:.*]] = "quantum.measure"(
// CHECK-NEXT: %[[T3:.*]] = "quantum.to_tensor"(%[[M3]]) : (!quantum.measurement<1>) -> tensor<1xi1>
// CHECK-NEXT: %[[C3:.*]] = tensor.insert_slice %[[T3]] into %{{.*}}[3] [1] [1] : tensor<1xi1> into tensor<4xi1>
// CHECK: "quantum.deallocate"(
// CHECK: "qpu.return"(%[[C3]]) : (tensor<4xi1>) -> ()
// CHECK: func.func @qasm_main() -> tensor<4xi1> {
// CHECK-NEXT: %[[OUT:.*]] = tensor.empty() : tensor<4xi1>
// CHECK-NEXT: %[[RESULT:.*]] = qpu.execute @ipea_3_pi_8::@main ins () outs (%[[OUT]] : tensor<4xi1>)
// CHECK-NEXT: return %[[RESULT]] : tensor<4xi1>
