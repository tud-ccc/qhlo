//Example code to demonstrate basic parameter update in a naive vqa with no cost updates
module {
  // Main function for VQE, iteratively passing theta values stored in memrefs
  func.func @main() -> i32 {
    // Initial value for theta stored in memrefs
    %theta_memref = memref.alloc() : memref<2xf64>  // Allocate memory for 2 theta values
    %init_result = arith.constant 0 : i32
    %c0 = arith.constant 0 : index
    %c5 = arith.constant 5 : index  // Loop 5 times
    %step = arith.constant 1 : index

    // Store initial theta values in memory
    %theta1 = arith.constant 0.35 : f64
    %theta2 = arith.constant 0.45 : f64
    memref.store %theta1, %theta_memref[%c0] : memref<2xf64>
    memref.store %theta2, %theta_memref[%c5] : memref<2xf64>

    // Classical loop to run 5 times and update theta
    %final_result, %final_theta = scf.for %i = %c0 to %c5 step %step iter_args(%out = %init_result, %theta = %theta_memref) -> (i32, memref<2xf64>) {
      // Call quantum function with theta values from memory
      %result = func.call @quantum_kernel(%theta) : (memref<2xf64>) -> i32

      // Update theta values in memory (for example, adding 0.05 to each theta)
      %update = arith.constant 0.05 : f64
      %new_theta1 = arith.addf %theta1, %update : f64
      %new_theta2 = arith.addf %theta2, %update : f64
      memref.store %new_theta1, %theta_memref[%c0] : memref<2xf64>
      memref.store %new_theta2, %theta_memref[%c5] : memref<2xf64>

      // Yield the result and the updated theta for the next iteration
      scf.yield %result, %theta_memref : i32, memref<2xf64>
    }

    // Return 0 exit code (needed for tests to pass)
    %zero = arith.constant 0 : i32
    return %zero : i32
  }

  // Quantum kernel function that uses theta from memrefs for rotations
  func.func @quantum_kernel(%theta_memref: memref<2xf64>) -> i32 {
    %q0 = "qillr.alloc"() : () -> (!qillr.qubit)
    %q1 = "qillr.alloc"() : () -> (!qillr.qubit)
    %r0 = "qillr.ralloc"() : () -> (!qillr.result)
    %r1 = "qillr.ralloc"() : () -> (!qillr.result)
    %zero = arith.constant 0 : i32
    %one = arith.constant 1 : i32

    // Load theta values from memref
    %c0 = arith.constant 0 : index
    %c1 = arith.constant 1 : index
    %theta1 = memref.load %theta_memref[%c0] : memref<2xf64>
    %theta2 = memref.load %theta_memref[%c1] : memref<2xf64>

    // Create superposition state
    "qillr.H"(%q0) : (!qillr.qubit) -> ()

    // Apply parameterized rotations using the loaded theta values
    "qillr.Rx"(%q0, %theta1) : (!qillr.qubit, f64) -> ()
    "qillr.Rz"(%q1, %theta2) : (!qillr.qubit, f64) -> ()

    // Measure the qubits and get the results
    "qillr.measure"(%q0, %r0) : (!qillr.qubit, !qillr.result) -> ()
    "qillr.measure"(%q1, %r1) : (!qillr.qubit, !qillr.result) -> ()
    
    // Read measurements (returns a tensor<1xi1>) and extract the scalar value.
    %m_out0_tensor = "qpu.to_bits"(%r0) : (!qillr.result) -> tensor<1xi1>
    %m_out1_tensor = "qpu.to_bits"(%r1) : (!qillr.result) -> tensor<1xi1>
    %c_index = arith.constant 0 : index
    %m_out0 = tensor.extract %m_out0_tensor[%c_index] : tensor<1xi1>
    %m_out1 = tensor.extract %m_out1_tensor[%c_index] : tensor<1xi1>

    // Count the number of 1's from the measurements.
    // If the measurement result is true (1), count it as 1; otherwise, 0.
    %count0 = arith.select %m_out0, %one, %zero : i32
    %count1 = arith.select %m_out1, %one, %zero : i32
    %total_count = arith.addi %count0, %count1 : i32

    // Return the total count of measured 1's
    return %total_count : i32
  }
}
