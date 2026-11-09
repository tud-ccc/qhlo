// RUN: quantum-qasm %S/Inputs/inverseqft2.qasm | FileCheck %s
// XFAIL: *
// Classical conditional lowering is not implemented; see README.md.
// Remove XFAIL when supported and extend the checks for this example's features.

// The unmodified upstream source and provenance are in Inputs/ and README.md.
// Coverage: Scalar measurement bits and classical conditions.
// Require a completed circuit, not just the current empty module/circuit skeleton.

// CHECK: qpu.module @inverseqft2
// CHECK: sym_name = "main"
// Constant folding must not hide the missing measurement-dependent branches.
// CHECK-COUNT-6: scf.if
// CHECK: "qpu.return"
