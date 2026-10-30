//Example code to demonstrate quantum teleportation
module {
  func.func @main() -> (i1, i1) {
    // Allocate three qubits: 
    // q0 holds the state to teleport, q1 and q2 form an entangled pair.
    %q0 = "qillr.alloc"() : () -> (!qillr.qubit)
    %q1 = "qillr.alloc"() : () -> (!qillr.qubit)
    %q2 = "qillr.alloc"() : () -> (!qillr.qubit)

    // Entangle q1 and q2 to create a Bell pair.
    "qillr.H"(%q1) : (!qillr.qubit) -> ()
    "qillr.CNOT"(%q1, %q2) : (!qillr.qubit, !qillr.qubit) -> ()

    // --- Teleportation Protocol ---
    // 1. Prepare the Bell measurement between the qubit to teleport (q0)
    //    and one half of the entangled pair (q1).
    "qillr.CNOT"(%q0, %q1) : (!qillr.qubit, !qillr.qubit) -> ()
    "qillr.H"(%q0) : (!qillr.qubit) -> ()

    // 2. Measure q0 and q1 to obtain classical bits m0 and m1.
    %r0 = "qillr.ralloc"() : () -> (!qillr.result)
    "qillr.measure"(%q0, %r0) : (!qillr.qubit, !qillr.result) -> ()
    %m0_tensor = "qpu.to_bits"(%r0) : (!qillr.result) -> tensor<1xi1>
    
    %r1 = "qillr.ralloc"() : () -> (!qillr.result)
    "qillr.measure"(%q1, %r1) : (!qillr.qubit, !qillr.result) -> ()
    %m1_tensor = "qpu.to_bits"(%r1) : (!qillr.result) -> tensor<1xi1>

    // Create an index constant for extraction
    %c0 = arith.constant 0 : index
    %m0 = tensor.extract %m0_tensor[%c0] : tensor<1xi1>
    %m1 = tensor.extract %m1_tensor[%c0] : tensor<1xi1>

    // 3. Based on the measurement outcomes, correct the state on q2.
    // If m1 is true, apply an X gate.
    scf.if %m1 {
      "qillr.X"(%q2) : (!qillr.qubit) -> () 
    }
    
    // If m0 is true, apply a Z gate.
    scf.if %m0 {
      "qillr.Z"(%q2) : (!qillr.qubit) -> ()
    }

    // Measure the corrected qubit (q2_final) to verify teleportation.
    %r2 = "qillr.ralloc"() : () -> (!qillr.result)
    "qillr.measure"(%q2, %r2) : (!qillr.qubit, !qillr.result) -> ()
    %final_tensor = "qpu.to_bits"(%r2) : (!qillr.result) -> tensor<1xi1>
    %final = tensor.extract %final_tensor[%c0] : tensor<1xi1>

    // Return two classical bits for demonstration:
    // Here we return the measurement outcome m0 (from q0) and the final state from q2.
    return %m0, %final : i1, i1
  }
}
