// RUN: %PYTHON qasm-import -i %s -r | quantum-opt --convert-quantum-to-qillr --canonicalize | FileCheck %s


// CHECK: module {
  // CHECK: qpu.module @qpu {
    // CHECK: "qpu.circuit"() <{function_type = () -> tensor<2xi1>, sym_name = "main"}> ({
      // CHECK: %[[QUBIT:.+]] = "qillr.alloc"() <{size = 2 : i64}> : () -> !qillr.qubit
      // CHECK: %[[CST:.+]] = arith.constant dense<false> : tensor<1xi1>
      // CHECK: %[[CST_0:.+]] = arith.constant dense<false> : tensor<1xi1>
      // CHECK: %[[RESULT:.+]] = "qillr.ralloc"() <{size = 1 : i64}> : () -> !qillr.result
      // CHECK: "qillr.measure"(%[[QUBIT]], %[[RESULT]]) <{inputIndex = [0], resultIndex = [0]}> : (!qillr.qubit, !qillr.result) -> ()
      // CHECK: %[[MEASUREMENT:.+]] = "qillr.read_measurement"(%[[RESULT]]) <{index = []}> : (!qillr.result) -> tensor<1xi1>
      // CHECK: %[[CST_1:.+]] = arith.constant dense<false> : tensor<1xi1>
      // CHECK: %[[CMP:.+]] = arith.cmpi eq, %[[MEASUREMENT]], %[[CST_1]] : tensor<1xi1>
      // CHECK: %[[C0:.+]] = arith.constant 0 : index
      // CHECK: %[[EXTRACTED:.+]] = tensor.extract %[[CMP]][%[[C0]]] : tensor<1xi1>
      // CHECK: %[[MATCH:.+]] = rvsdg.match(%[[EXTRACTED]] : i1) [#rvsdg.matchRule<1 -> 0>, #rvsdg.matchRule<0 -> 1>] -> <2>
      // CHECK: %[[GAMMA:.+]] = rvsdg.gamma(%[[MATCH]] : <2>) (%[[QUBIT]]: !qillr.qubit) : [
        // CHECK: (%[[ARG0:.+]]: !qillr.qubit): {
          // CHECK: "qillr.X"(%[[ARG0]]) <{index = [0]}> : (!qillr.qubit) -> ()
          // CHECK: rvsdg.yield (%[[ARG0]]: !qillr.qubit)
        // CHECK: (%[[ARG0_1:.+]]: !qillr.qubit): {
          // CHECK: rvsdg.yield (%[[ARG0_1]]: !qillr.qubit)
      // CHECK: %[[RESULT_1:.+]] = "qillr.ralloc"() <{size = 1 : i64}> : () -> !qillr.result
      // CHECK: "qillr.measure"(%[[QUBIT]], %[[RESULT_1]]) <{inputIndex = [1], resultIndex = [0]}> : (!qillr.qubit, !qillr.result) -> ()
      // CHECK: %[[MEASUREMENT_1:.+]] = "qillr.read_measurement"(%[[RESULT_1]]) <{index = []}> : (!qillr.result) -> tensor<1xi1>
      // CHECK: %[[CST_2:.+]] = arith.constant dense<false> : tensor<1xi1>
      // CHECK: %[[CMP_1:.+]] = arith.cmpi eq, %[[MEASUREMENT_1]], %[[CST_2]] : tensor<1xi1>
      // CHECK: %[[C0_3:.+]] = arith.constant 0 : index
      // CHECK: %[[EXTRACTED_4:.+]] = tensor.extract %[[CMP_1]][%[[C0_3]]] : tensor<1xi1>
      // CHECK: %[[MATCH_1:.+]] = rvsdg.match(%[[EXTRACTED_4]] : i1) [#rvsdg.matchRule<1 -> 0>, #rvsdg.matchRule<0 -> 1>] -> <2>
      // CHECK: %[[GAMMA_1:.+]] = rvsdg.gamma(%[[MATCH_1]] : <2>) (%[[QUBIT]]: !qillr.qubit) : [
        // CHECK: (%[[ARG0_2:.+]]: !qillr.qubit): {
          // CHECK: "qillr.X"(%[[ARG0_2]]) <{index = [1]}> : (!qillr.qubit) -> ()
          // CHECK: rvsdg.yield (%[[ARG0_2]]: !qillr.qubit)
        // CHECK: (%[[ARG0_3:.+]]: !qillr.qubit): {
          // CHECK: rvsdg.yield (%[[ARG0_3]]: !qillr.qubit)
      // CHECK: "qillr.reset"(%[[GAMMA]]) <{index = [0]}> : (!qillr.qubit) -> ()
      // CHECK: "qillr.reset"(%[[GAMMA_1]]) <{index = [1]}> : (!qillr.qubit) -> ()
      // CHECK: "qillr.deallocate"(%[[GAMMA]]) <{index = [0]}> : (!qillr.qubit) -> ()
      // CHECK: "qillr.deallocate"(%[[GAMMA_1]]) <{index = [1]}> : (!qillr.qubit) -> ()
      // CHECK: %[[CONCAT:.+]] = tensor.concat dim(0) %[[MEASUREMENT]], %[[MEASUREMENT_1]] : (tensor<1xi1>, tensor<1xi1>) -> tensor<2xi1>
      // CHECK: "qpu.return"(%[[CONCAT]]) : (tensor<2xi1>) -> ()

  // CHECK: func.func public @qasm_main() -> tensor<2xi1> {
    // CHECK: %[[EMPTY:.+]] = tensor.empty() : tensor<2xi1>
    // CHECK: %[[RES:.+]] = qpu.execute @qpu::@main ins () outs (%[[EMPTY]] : tensor<2xi1>)
    // CHECK: return %[[RES]] : tensor<2xi1>


OPENQASM 2.0;
include "qelib1.inc";
qreg q[2];
creg c1[1];
creg c2[1];
measure q[0] -> c1[0];
if(c1==0) x q[0];
measure q[1] -> c2[0];
if(c2==0) x q[1];
reset q[0];
reset q[1];
