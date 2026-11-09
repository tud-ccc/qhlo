// RUN: quantum-qasm %S/Inputs/cphase.qasm | FileCheck %s
// XFAIL: *
// The upstream fragment calls cphase with q[0], q[1] without declaring q.
// Its gate body also needs runtime arithmetic for theta / 2.

// The unmodified upstream source and provenance are in Inputs/ and README.md.
// Coverage: Parameterized gate, Unicode identifiers (illustrative fragment).
// Require a completed circuit, not just the current empty module/circuit skeleton.

// CHECK: qpu.module @cphase
// CHECK: sym_name = "main"
// CHECK: "qpu.return"
