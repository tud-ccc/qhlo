// RUN: quantum-qasm %S/Inputs/teleport.qasm > %t.mlir
// RUN: FileCheck %s < %t.mlir
// RUN: quantum-opt %t.mlir -verify-linearity -o /dev/null

// The unmodified upstream source and provenance are in Inputs/ and README.md.
// Coverage: Measurement, conditional correction and empty custom gate.

// CHECK: qpu.module @teleport
// CHECK: sym_name = "main"
// Conditional correction must stay conditional after scalar literals lower.
// CHECK: "qpu.to_bits"
// CHECK: "qpu.bits_eq"
// CHECK: scf.if
// CHECK: "quantum.Z"
// CHECK: "qpu.bits_eq"
// CHECK: scf.if
// CHECK: "quantum.X"
// CHECK: "qpu.return"
