// RUN: quantum-opt %s | FileCheck %s

func.func @main() {
  // Allocate qubits and results.
  %q0 = "qillr.alloc" () <{size = 1 : i64}> : () -> (!qillr.qubit)
// CHECK: %[[Q0:.+]] = "qillr.alloc"() <{size = 1 : i64}> : () -> !qillr.qubit

  %q1 = "qillr.alloc" () <{size = 1 : i64}> : () -> (!qillr.qubit)
// CHECK: %[[Q1:.+]] = "qillr.alloc"() <{size = 1 : i64}> : () -> !qillr.qubit

  %q2 = "qillr.alloc" () <{size = 1 : i64}> : () -> (!qillr.qubit)
// CHECK: %[[Q2:.+]] = "qillr.alloc"() <{size = 1 : i64}> : () -> !qillr.qubit

  %r0 = "qillr.ralloc" () <{size = 1 : i64}> : () -> (!qillr.result)
// CHECK: %[[R0:.+]] = "qillr.ralloc"() <{size = 1 : i64}> : () -> !qillr.result 

  %r1 = "qillr.ralloc" () <{size = 1 : i64}> : () -> (!qillr.result)
// CHECK: %[[R1:.+]] = "qillr.ralloc"() <{size = 1 : i64}> : () -> !qillr.result 

  %r2 = "qillr.ralloc" () <{size = 1 : i64}> : () -> (!qillr.result)
// CHECK: %[[R2:.+]] = "qillr.ralloc"() <{size = 1 : i64}> : () -> !qillr.result 

  // Create constants for rotation angles.
  %c1 = arith.constant 0.34  : f64
// CHECK: %[[C1:.+]] = arith.constant 3.400000e-01 : f64

  %c2 = arith.constant 0.735 : f64
// CHECK: %[[C2:.+]] = arith.constant 7.350000e-01 : f64

  %c3 = arith.constant 0.23  : f64
// CHECK: %[[C3:.+]] = arith.constant 2.300000e-01 : f64

  // Single-qubit Pauli & Hadamard gates
  "qillr.X"(%q0)   : (!qillr.qubit) -> ()
// CHECK: "qillr.X"(%[[Q0]]) <{index = []}> : (!qillr.qubit) -> ()

  "qillr.Y"(%q0)   : (!qillr.qubit) -> ()
// CHECK: "qillr.Y"(%[[Q0]]) <{index = []}> : (!qillr.qubit) -> ()

  "qillr.Z"(%q0)   : (!qillr.qubit) -> ()
// CHECK: "qillr.Z"(%[[Q0]]) <{index = []}> : (!qillr.qubit) -> ()

  "qillr.H"(%q0)   : (!qillr.qubit) -> ()
// CHECK: "qillr.H"(%[[Q0]]) <{index = []}> : (!qillr.qubit) -> ()

  // Rotation gates
  "qillr.Rx"(%q0, %c1) : (!qillr.qubit, f64) -> ()
// CHECK: "qillr.Rx"(%[[Q0]], %[[C1]]) <{index = []}> : (!qillr.qubit, f64) -> ()

  "qillr.Ry"(%q0, %c2) : (!qillr.qubit, f64) -> ()
// CHECK: "qillr.Ry"(%[[Q0]], %[[C2]]) <{index = []}> : (!qillr.qubit, f64) -> ()

  "qillr.Rz"(%q0, %c3) : (!qillr.qubit, f64) -> ()
// CHECK: "qillr.Rz"(%[[Q0]], %[[C3]]) <{index = []}> : (!qillr.qubit, f64) -> ()

  // Parameterized single-qubit gates
  "qillr.U1"(%q0, %c1)              : (!qillr.qubit, f64) -> ()
// CHECK: "qillr.U1"(%[[Q0]], %[[C1]]) <{index = []}> : (!qillr.qubit, f64) -> ()

  "qillr.U2"(%q0, %c2, %c3)         : (!qillr.qubit, f64, f64) -> ()
// CHECK: "qillr.U2"(%[[Q0]], %[[C2]], %[[C3]]) <{index = []}> : (!qillr.qubit, f64, f64) -> ()

  "qillr.U3" (%q0, %c1, %c2, %c3)    : (!qillr.qubit, f64, f64, f64) -> ()
// CHECK: "qillr.U3"(%[[Q0]], %[[C1]], %[[C2]], %[[C3]]) <{index = []}> : (!qillr.qubit, f64, f64, f64) -> ()

  // Controlled and multi-qubit gates
  "qillr.CNOT"(%q0, %q1)            : (!qillr.qubit, !qillr.qubit) -> ()
// CHECK: "qillr.CNOT"(%[[Q0]], %[[Q1]]) <{controlIndex = [], targetIndex = []}> : (!qillr.qubit, !qillr.qubit) -> ()

  "qillr.CRz"(%q0, %q1, %c1)        : (!qillr.qubit, !qillr.qubit, f64) -> ()
// CHECK: "qillr.CRz"(%[[Q0]], %[[Q1]], %[[C1]]) <{controlIndex = [], targetIndex = []}> : (!qillr.qubit, !qillr.qubit, f64) -> ()

  "qillr.CRy"(%q0, %q1, %c2)        : (!qillr.qubit, !qillr.qubit, f64) -> ()
// CHECK: "qillr.CRy"(%[[Q0]], %[[Q1]], %[[C2]]) <{controlIndex = [], targetIndex = []}> : (!qillr.qubit, !qillr.qubit, f64) -> ()

  "qillr.CCX"(%q0, %q1, %q2)        : (!qillr.qubit, !qillr.qubit, !qillr.qubit) -> ()
// CHECK: "qillr.CCX"(%[[Q0]], %[[Q1]], %[[Q2]]) <{control1Index = [], control2Index = [], targetIndex = []}> : (!qillr.qubit, !qillr.qubit, !qillr.qubit) -> ()

  // Phase gates
  "qillr.S"(%q0)                    : (!qillr.qubit) -> ()
// CHECK: "qillr.S"(%[[Q0]]) <{index = []}> : (!qillr.qubit) -> ()

  "qillr.Sdg"(%q0)                  : (!qillr.qubit) -> ()
// CHECK: "qillr.Sdg"(%[[Q0]]) <{index = []}> : (!qillr.qubit) -> ()

  "qillr.T"(%q0)                    : (!qillr.qubit) -> ()
// CHECK: "qillr.T"(%[[Q0]]) <{index = []}> : (!qillr.qubit) -> ()

  "qillr.Tdg"(%q0)                  : (!qillr.qubit) -> ()
// CHECK: "qillr.Tdg"(%[[Q0]]) <{index = []}> : (!qillr.qubit) -> ()

  // Swap
  "qillr.swap"(%q0, %q1)            : (!qillr.qubit, !qillr.qubit) -> ()
// CHECK: "qillr.swap"(%[[Q0]], %[[Q1]]) <{lhsIndex = [], rhsIndex = []}> : (!qillr.qubit, !qillr.qubit) -> ()

  // Measurements
  "qillr.measure"(%q0, %r0)         : (!qillr.qubit, !qillr.result) -> ()
// CHECK: "qillr.measure"(%[[Q0]], %[[R0]]) <{inputIndex = [], resultIndex = []}> : (!qillr.qubit, !qillr.result) -> ()
  "qillr.measure"(%q1, %r1)         : (!qillr.qubit, !qillr.result) -> ()
// CHECK: "qillr.measure"(%[[Q1]], %[[R1]]) <{inputIndex = [], resultIndex = []}> : (!qillr.qubit, !qillr.result) -> ()
  "qillr.measure"(%q2, %r2)         : (!qillr.qubit, !qillr.result) -> ()
// CHECK: "qillr.measure"(%[[Q2]], %[[R2]]) <{inputIndex = [], resultIndex = []}> : (!qillr.qubit, !qillr.result) -> ()

  %m0 = "qpu.to_bits"(%r0) : (!qillr.result) -> tensor<1xi1>
// CHECK: %[[M0:.+]] = "qpu.to_bits"(%[[R0]]) : (!qillr.result) -> tensor<1xi1>

  // Reset
  "qillr.reset"(%q0)                : (!qillr.qubit) -> ()
// CHECK: "qillr.reset"(%[[Q0]]) <{index = []}> : (!qillr.qubit) -> ()

  return
}
