// RUN: quantum-opt %s \
// RUN:   --pass-pipeline="builtin.module( \
// RUN:       convert-quantum-to-qillr, \
// RUN:       func.func(convert-scf-to-cf), \
// RUN:       convert-qillr-to-llvm, \
// RUN:       convert-func-to-llvm, \
// RUN:       convert-cf-to-llvm, \
// RUN:       convert-vector-to-llvm, \
// RUN:       one-shot-bufferize{allow-unknown-ops}, \
// RUN:       finalize-memref-to-llvm, \
// RUN:       convert-index-to-llvm, \
// RUN:       convert-arith-to-llvm, \
// RUN:       reconcile-unrealized-casts)" | \
// RUN: mlir-runner -e entry -entry-point-result=void \
// RUN:     --shared-libs=%qir_shlibs,%mlir_c_runner_utils | \
// RUN: FileCheck %s --match-full-lines

module {

  // Function to allocate a qubit, apply an X gate, measure and read the result
  func.func @test_0_X_returns_1() -> ()  {
    %q = "quantum.alloc"() : () -> (!quantum.qubit<1>)
    %q1 = "quantum.X" (%q) : (!quantum.qubit<1>) -> (!quantum.qubit<1>)
    %mt, %q_m = "quantum.measure" (%q1) : (!quantum.qubit<1>) -> (tensor<1xi1>, !quantum.qubit<1>)
    "quantum.deallocate"(%q_m) : (!quantum.qubit<1>) -> ()
    %i = "index.constant" () {value = 0 : index} : () -> (index)
    %m = "tensor.extract" (%mt, %i) : (tensor<1xi1>, index) -> (i1)
    vector.print %m : i1
    return
  }

    // Function to allocate a qubit, apply an X gate, measure and read the result
  func.func @test_shots_based_simulation() -> ()  {
    %numShots = arith.constant 10 : index
    %zeroIdx = arith.constant 0 : index
    %oneIdx = arith.constant 1 : index
    %accum0 = arith.constant 0 : i32

    //Seed 23 always results in 7/10 shots measurement to return 1. so accumulated result is always 7. 
    %seed = arith.constant 23 : i64
    "qillr.seed"(%seed): (i64) -> () 
    %finalCount = scf.for %i = %zeroIdx to %numShots step %oneIdx iter_args(%curr = %accum0) -> i32 {
      //Initialise the simulator on each shot. 
      "qillr.init"() : () -> () 
      %q = "qillr.alloc"() : () -> (!qillr.qubit)
      %r = "qillr.ralloc"() : () -> (!qillr.result)

      "qillr.H"(%q) : (!qillr.qubit) -> ()
      "qillr.measure"(%q, %r) : (!qillr.qubit, !qillr.result) -> ()
      %m = "qpu.to_bits"(%r) : (!qillr.result) -> tensor<1xi1>

      %oneInt = arith.constant 1 : i32
      %zeroInt = arith.constant 0 : i32
      %shotVal = arith.select %m, %oneInt, %zeroInt : i32
      %newAccum = arith.addi %curr, %shotVal : i32
      scf.yield %newAccum : i32
    }
    vector.print %finalCount : i32
    return 
  }

func.func @test_qasm_output_correctness() -> ()  {
    %0 = "qillr.alloc" () : () -> (!qillr.qubit)
    %1 = "qillr.alloc" () : () -> (!qillr.qubit)
    %2 = "qillr.ralloc" () : () -> (!qillr.result)
    %3 = "qillr.ralloc" () : () -> (!qillr.result)

    "qillr.H" (%0) : (!qillr.qubit) -> ()
    "qillr.X" (%0) : (!qillr.qubit) -> ()

    %4 = arith.constant 3.141500 : f64
    "qillr.Rx" (%0, %4) : (!qillr.qubit, f64) -> ()
    "qillr.CNOT" (%0, %1) : (!qillr.qubit, !qillr.qubit) -> ()
    "qillr.swap" (%0, %1) : (!qillr.qubit, !qillr.qubit) -> ()
    "qillr.measure" (%0, %2) : (!qillr.qubit, !qillr.result) -> ()
    
    %5 = "qpu.to_bits" (%2) : (!qillr.result) -> tensor<1xi1>
    "qillr.measure" (%1, %3) : (!qillr.qubit, !qillr.result) -> ()
    %6 = "qpu.to_bits" (%3) : (!qillr.result) -> tensor<1xi1>

    "qillr.deallocate" (%0) : (!qillr.qubit) -> ()
    "qillr.deallocate" (%1) : (!qillr.qubit) -> ()
    vector.print %6 : i1
    return
  }

  func.func @entry() {
    // CHECK: 1
    func.call @test_0_X_returns_1() : () -> ()
    
    // CHECK: 7
    func.call @test_shots_based_simulation() : () -> ()

    // CHECK: 1
    func.call @test_qasm_output_correctness() : () -> ()
    return
  }
}
