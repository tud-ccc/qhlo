// RUN: quantum-qasm %S/Inputs/inverseqft2.qasm > %t.mlir
// RUN: FileCheck %s < %t.mlir
// RUN: quantum-opt %t.mlir -verify-linearity -o /dev/null

// The unmodified upstream source and provenance are in Inputs/ and README.md.
// Coverage: Scalar measurement bits and classical conditions.

// CHECK: qpu.module @inverseqft2
// CHECK: sym_name = "main"
// CHECK: "qpu.to_bits"
// CHECK: "qpu.bits_eq"
// Measurement-dependent rotations must remain conditional.
// CHECK-COUNT-6: scf.if
// CHECK: "qpu.return"
