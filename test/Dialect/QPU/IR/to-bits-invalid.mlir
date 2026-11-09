// RUN: quantum-opt %s -verify-diagnostics
func.func @unsupported_source(%value: i32) -> tensor<1xi1> {
  // expected-error @+1 {{operand #0 must be measurement source}}
  %bits = "qpu.to_bits"(%value) : (i32) -> tensor<1xi1>
  return %bits : tensor<1xi1>
}
