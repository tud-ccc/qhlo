// RUN: quantum-opt %s --split-input-file --convert-rvsdg-to-scf | FileCheck %s

// CHECK-LABEL: @test_complex
func.func @test_complex() {
    %cst = arith.constant dense<[false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, true]> : tensor<32xi1>
    %c1 = arith.constant 1 : index
    %c32 = arith.constant 32 : index
    %c0 = arith.constant 0 : index
    %true = arith.constant true
    %cst_0 = arith.constant dense<false> : tensor<32xi1>
    %0 = "qillr.alloc"() <{size = 32 : i64}> : () -> !qillr.qubit
    %1 = "qillr.ralloc"() <{size = 32 : i64}> : () -> !qillr.result
      "qillr.measure"(%0, %1) <{inputIndex = [31], resultIndex = [31]}> : (!qillr.qubit, !qillr.result) -> ()
      %2 = "qpu.to_bits"(%1) : (!qillr.result) -> tensor<32xi1>
      %3 = arith.cmpi eq, %2, %cst_0 : tensor<32xi1>
      %4 = scf.parallel (%arg0) = (%c0) to (%c32) step (%c1) init (%true) -> i1 {
        %extracted = tensor.extract %3[%arg0] : tensor<32xi1>
        scf.reduce(%extracted : i1) {
        ^bb0(%arg1: i1, %arg2: i1):
          %294 = arith.andi %arg1, %arg2 : i1
          scf.reduce.return %294 : i1
        }
      }
      %5 = rvsdg.match(%4 : i1) [#rvsdg.matchRule<1 -> 0>, #rvsdg.matchRule<0 -> 1>] -> <2>
      %6 = rvsdg.gamma(%5 : <2>) (%0: !qillr.qubit) : [
        (%arg0: !qillr.qubit): {
          "qillr.X"(%arg0) <{index = [31]}> : (!qillr.qubit) -> ()
          rvsdg.yield (%arg0: !qillr.qubit)
        }, 
        (%arg0: !qillr.qubit): {
          rvsdg.yield (%arg0: !qillr.qubit)
        }
      ] -> !qillr.qubit
    return
}
