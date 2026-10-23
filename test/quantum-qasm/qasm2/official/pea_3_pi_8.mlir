// RUN: quantum-qasm %S/Inputs/pea_3_pi_8.qasm | FileCheck %s
// XFAIL: *
// Valid upstream program: its cu declaration conflicts with the embedded qelib1.inc.
// Remove XFAIL when the frontend accepts this program; keep success as the expectation.

// The unmodified upstream source and provenance are in Inputs/ and README.md.
// Check the intended successful lowering, including phase-estimation stages.
// Parameter binding in custom gate bodies is also currently incomplete.

// CHECK: qpu.module @pea_3_pi_8
// CHECK: sym_name = "cu"
// CHECK: sym_name = "cu1fixed"
// CHECK: "quantum.CNOT"(
// CHECK: "quantum.CNOT"(
// CHECK: "quantum.return"(
// CHECK: function_type = () -> tensor<4xi1>, sym_name = "main"
// CHECK: "quantum.alloc"() : () -> !quantum.qubit<5>
// CHECK-COUNT-4: "quantum.H"(
// CHECK-COUNT-15: callee = @cu
// CHECK: "quantum.H"(
// CHECK: "quantum.CU1"(
// CHECK: "quantum.H"(
// CHECK-COUNT-2: "quantum.CU1"(
// CHECK: "quantum.H"(
// CHECK-COUNT-3: "quantum.CU1"(
// CHECK: "quantum.H"(
// CHECK: %[[M0:.*]], %[[Q0:.*]] = "quantum.measure"(
// CHECK-NEXT: %[[T0:.*]] = "quantum.to_tensor"(%[[M0]]) : (!quantum.measurement<1>) -> tensor<1xi1>
// CHECK-NEXT: %[[C0:.*]] = tensor.insert_slice %[[T0]] into %{{.*}}[0] [1] [1] : tensor<1xi1> into tensor<4xi1>
// CHECK: %[[M1:.*]], %[[Q1:.*]] = "quantum.measure"(
// CHECK-NEXT: %[[T1:.*]] = "quantum.to_tensor"(%[[M1]]) : (!quantum.measurement<1>) -> tensor<1xi1>
// CHECK-NEXT: %[[C1:.*]] = tensor.insert_slice %[[T1]] into %{{.*}}[1] [1] [1] : tensor<1xi1> into tensor<4xi1>
// CHECK: %[[M2:.*]], %[[Q2:.*]] = "quantum.measure"(
// CHECK-NEXT: %[[T2:.*]] = "quantum.to_tensor"(%[[M2]]) : (!quantum.measurement<1>) -> tensor<1xi1>
// CHECK-NEXT: %[[C2:.*]] = tensor.insert_slice %[[T2]] into %{{.*}}[2] [1] [1] : tensor<1xi1> into tensor<4xi1>
// CHECK: %[[M3:.*]], %[[Q3:.*]] = "quantum.measure"(
// CHECK-NEXT: %[[T3:.*]] = "quantum.to_tensor"(%[[M3]]) : (!quantum.measurement<1>) -> tensor<1xi1>
// CHECK-NEXT: %[[C3:.*]] = tensor.insert_slice %[[T3]] into %{{.*}}[3] [1] [1] : tensor<1xi1> into tensor<4xi1>
// CHECK: "quantum.deallocate"(
// CHECK: "qpu.return"(%[[C3]]) : (tensor<4xi1>) -> ()
// CHECK: func.func @qasm_main() -> tensor<4xi1> {
// CHECK-NEXT: %[[OUT:.*]] = tensor.empty() : tensor<4xi1>
// CHECK-NEXT: %[[RESULT:.*]] = qpu.execute @pea_3_pi_8::@main ins () outs (%[[OUT]] : tensor<4xi1>)
// CHECK-NEXT: return %[[RESULT]] : tensor<4xi1>
