// RUN: quantum-qasm %S/Inputs/adder.qasm | FileCheck %s
// XFAIL: *
// QASM3 parsing/lowering is not implemented; see README.md for corpus limitations.
// Remove XFAIL when supported and extend the checks for this example's features.

// The unmodified upstream source and provenance are in Inputs/ and README.md.
// Coverage: Custom gates, integer inputs, loops and register slices.
// Require a completed circuit, not just the current empty module/circuit skeleton.

// CHECK: qpu.module @adder
// CHECK: sym_name = "main"
// CHECK: "qpu.return"
