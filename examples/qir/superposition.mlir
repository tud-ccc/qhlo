//Example code to demonstrate quantum superposition. Should yield ~50% |0⟩ and ~50% |1⟩ over multiple runs
func.func @main()  -> i1 {
  // Allocate a qubit and a classical result register
  %q0 = "qillr.alloc" () : () -> (!qillr.qubit)
  %q1 = "qillr.alloc" () : () -> (!qillr.qubit)
  %r0 = "qillr.ralloc" () : () -> (!qillr.result)

  // Apply Hadamard gate followed by CNOT to put q0, q1 into superposition: |+⟩ = (|0⟩ + |1⟩) / sqrt(2)
  "qillr.H" (%q0) : (!qillr.qubit) -> ()
  "qillr.CNOT" (%q0, %q1) : (!qillr.qubit, !qillr.qubit) -> ()

  // Measure the qubit
  "qillr.measure" (%q0, %r0) : (!qillr.qubit, !qillr.result) -> ()
  %output = "qpu.to_bits"(%r0) : (!qillr.result) -> tensor<1xi1>
  %c0 = arith.constant 0 : index
  %result = tensor.extract %output[%c0] : tensor<1xi1>
  return %result : i1 
}
