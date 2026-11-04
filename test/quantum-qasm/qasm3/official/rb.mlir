// RUN: quantum-qasm %S/Inputs/rb.qasm | FileCheck %s

// The unmodified upstream source and provenance are in Inputs/ and README.md.
// Preserve the benchmarking sequence, including all four barriers and both CZ
// gates. Thread updated qubits through each gate and measure them in register
// order, returning the two measurement bits to the host.

// CHECK-LABEL: qpu.module @rb
// CHECK: "qpu.circuit"() <{function_type = () -> tensor<2xi1>, sym_name = "main"}>
// CHECK: %[[Q:.*]] = "quantum.alloc"() : () -> !quantum.qubit<2>
// CHECK: %[[RESET:.*]] = "quantum.reset"(%[[Q]]) : (!quantum.qubit<2>) -> !quantum.qubit<2>
// CHECK-NEXT: %[[SPLIT:.*]]:2 = "quantum.split"(%[[RESET]]) : (!quantum.qubit<2>) -> (!quantum.qubit<1>, !quantum.qubit<1>)
// CHECK-NEXT: %[[H1:.*]] = "quantum.H"(%[[SPLIT]]#0)
// CHECK-NEXT: %[[BARRIER1:.*]]:2 = "quantum.barrier"(%[[H1]], %[[SPLIT]]#1)
// CHECK-NEXT: %[[CZ1_CONTROL:.*]], %[[CZ1_TARGET:.*]] = "quantum.CZ"(%[[BARRIER1]]#0, %[[BARRIER1]]#1)
// CHECK-NEXT: %[[BARRIER2:.*]]:2 = "quantum.barrier"(%[[CZ1_CONTROL]], %[[CZ1_TARGET]])
// CHECK-NEXT: %[[S1:.*]] = "quantum.S"(%[[BARRIER2]]#0)
// CHECK-NEXT: %[[CZ2_CONTROL:.*]], %[[CZ2_TARGET:.*]] = "quantum.CZ"(%[[S1]], %[[BARRIER2]]#1)
// CHECK-NEXT: %[[BARRIER3:.*]]:2 = "quantum.barrier"(%[[CZ2_CONTROL]], %[[CZ2_TARGET]])
// CHECK-NEXT: %[[S2:.*]] = "quantum.S"(%[[BARRIER3]]#0)
// CHECK-NEXT: %[[Z:.*]] = "quantum.Z"(%[[S2]])
// CHECK-NEXT: %[[H2:.*]] = "quantum.H"(%[[Z]])
// CHECK-NEXT: %[[BARRIER4:.*]]:2 = "quantum.barrier"(%[[H2]], %[[BARRIER3]]#1)
// CHECK-NEXT: %[[MERGED:.*]] = "quantum.merge"(%[[BARRIER4]]#0, %[[BARRIER4]]#1)
// CHECK-NEXT: %[[MEAS:.*]], %[[MEASURED_Q:.*]] = "quantum.measure"(%[[MERGED]]) : (!quantum.qubit<2>) -> (!quantum.measurement<2>, !quantum.qubit<2>)
// CHECK-NEXT: %[[BITS:.*]] = "qpu.to_bits"(%[[MEAS]]) : (!quantum.measurement<2>) -> tensor<2xi1>
// CHECK-NEXT: "quantum.deallocate"(%[[MEASURED_Q]]) : (!quantum.qubit<2>) -> ()
// CHECK-NEXT: "qpu.return"(%[[BITS]]) : (tensor<2xi1>) -> ()

// CHECK-LABEL: func.func @qasm_main() -> tensor<2xi1>
// CHECK-NEXT: %[[OUT:.*]] = tensor.empty() : tensor<2xi1>
// CHECK-NEXT: %[[RESULT:.*]] = qpu.execute @rb::@main ins () outs (%[[OUT]] : tensor<2xi1>)
// CHECK-NEXT: return %[[RESULT]] : tensor<2xi1>
