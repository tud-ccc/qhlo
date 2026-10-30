module {
  func.func @main() -> (i1, i1, i1, i1) {
    %c0 = arith.constant 0 : index
    %c4 = arith.constant 4 : index
    %step = arith.constant 1 : index
    %init = arith.constant 0 : i1

    // scf.for loop iterating 4 times to prepare 4 Bell states
    %m0, %m1, %m2, %m3 = scf.for %i = %c0 to %c4 step %step iter_args(%r0 = %init, %r1 = %init, %r2 = %init, %r3 = %init) -> (i1, i1, i1, i1) {
      // Allocate two qubits for Bell state preparation
      %q0 = "qillr.alloc"() : () -> (!qillr.qubit)
      %q1 = "qillr.alloc"() : () -> (!qillr.qubit)

      // Allocate result registers
      %res0 = "qillr.ralloc"() : () -> (!qillr.result)
      %res1 = "qillr.ralloc"() : () -> (!qillr.result)

      // Prepare Bell states based on loop index
      %zero  = arith.constant 0 : index
      %one   = arith.constant 1 : index
      %two   = arith.constant 2 : index
      %three = arith.constant 3 : index

      %cmp0 = arith.cmpi eq, %i, %zero : index
      scf.if %cmp0 {
        "qillr.H"(%q0) : (!qillr.qubit) -> ()
        "qillr.CNOT"(%q0, %q1) : (!qillr.qubit, !qillr.qubit) -> ()
      }

      %cmp1 = arith.cmpi eq, %i, %one : index
      scf.if %cmp1 {
        "qillr.H"(%q0) : (!qillr.qubit) -> ()
        "qillr.Z"(%q0) : (!qillr.qubit) -> ()
        "qillr.CNOT"(%q0, %q1) : (!qillr.qubit, !qillr.qubit) -> ()
      }

      %cmp2 = arith.cmpi eq, %i, %two : index
      scf.if %cmp2 {
        "qillr.H"(%q0) : (!qillr.qubit) -> ()
        "qillr.X"(%q1) : (!qillr.qubit) -> ()
        "qillr.CNOT"(%q0, %q1) : (!qillr.qubit, !qillr.qubit) -> ()
      }

      %cmp3 = arith.cmpi eq, %i, %three : index
      scf.if %cmp3 {
        "qillr.H"(%q0) : (!qillr.qubit) -> ()
        "qillr.Z"(%q0) : (!qillr.qubit) -> ()
        "qillr.X"(%q1) : (!qillr.qubit) -> ()
        "qillr.CNOT"(%q0, %q1) : (!qillr.qubit, !qillr.qubit) -> ()
      }

      // Measure the qubits
      "qillr.measure"(%q0, %res0) : (!qillr.qubit, !qillr.result) -> ()
      "qillr.measure"(%q1, %res1) : (!qillr.qubit, !qillr.result) -> ()

      // Convert measurement results to classical bits via tensor extraction
      %m_out0_tensor = "qpu.to_bits"(%res0) : (!qillr.result) -> tensor<1xi1>
      %m_out1_tensor = "qpu.to_bits"(%res1) : (!qillr.result) -> tensor<1xi1>
      %idx = arith.constant 0 : index
      %m_out0 = tensor.extract %m_out0_tensor[%idx] : tensor<1xi1>
      %m_out1 = tensor.extract %m_out1_tensor[%idx] : tensor<1xi1>

      // Yield results to accumulate them across iterations (keeping r2 and r3 unchanged)
      scf.yield %m_out0, %m_out1, %r2, %r3 : i1, i1, i1, i1
    }

    // Return final measurement results after loop execution
    return %m0, %m1, %m2, %m3 : i1, i1, i1, i1
  }
}
