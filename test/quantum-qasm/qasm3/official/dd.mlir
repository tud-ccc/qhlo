// RUN: quantum-qasm %S/Inputs/dd.qasm | FileCheck %s
// XFAIL: *
// QASM3 parsing/lowering is not implemented; see README.md for corpus limitations.
// Remove XFAIL when supported and extend the checks for this example's features.

// The unmodified upstream source and provenance are in Inputs/ and README.md.
// Coverage: Timing boxes, durationof and physical qubits.
// Require a completed circuit, not just the current empty module/circuit skeleton.

// CHECK: qpu.module @qasm_generated
// CHECK: sym_name = "main"
// CHECK: "qpu.return"
