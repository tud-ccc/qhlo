// RUN: quantum-qasm %S/Inputs/teleport.qasm | FileCheck %s
// XFAIL: *
// QASM3 parsing/lowering is not implemented; see README.md for corpus limitations.
// Remove XFAIL when supported and extend the checks for this example's features.

// The unmodified upstream source and provenance are in Inputs/ and README.md.
// Coverage: Measurement, conditional correction and empty custom gate.
// Require a completed circuit, not just the current empty module/circuit skeleton.

// CHECK: qpu.module @teleport
// CHECK: sym_name = "main"
// Conditional correction must stay conditional after scalar literals lower.
// CHECK: scf.if
// CHECK: scf.if
// CHECK: "qpu.return"
