// RUN: quantum-qasm
// | quantum-opt --inline --convert-quantum-to-qillr | FileCheck %s
// Stripped down from QASMBenc small/qaoa_n3.qasm

// CHECK: module {
// CHECK:  qpu.module @qpu {
//     "qpu.circuit"() <{function_type = () -> tensor<3xi1>, sym_name = "main"}> ({
//       %0 = "quantum.alloc"() : () -> !quantum.qubit<3>
//       %1:2 = "quantum.split"(%0) : (!quantum.qubit<3>) -> (!quantum.qubit<1>, !quantum.qubit<2>)
//       %2 = "quantum.H"(%1#0) : (!quantum.qubit<1>) -> !quantum.qubit<1>
//       %3:2 = "quantum.split"(%1#1) : (!quantum.qubit<2>) -> (!quantum.qubit<1>, !quantum.qubit<1>)
//       %4 = "quantum.H"(%3#0) : (!quantum.qubit<1>) -> !quantum.qubit<1>
//       %5 = "quantum.H"(%3#1) : (!quantum.qubit<1>) -> !quantum.qubit<1>
//       %measurement, %result = "quantum.measure"(%5) : (!quantum.qubit<1>) -> (!quantum.measurement<1>, !quantum.qubit<1>)
//       %[[6:.+]] = "quantum.to_tensor"(%measurement) : (!quantum.measurement<1>) -> tensor<1xi1>
//       %measurement_0, %result_1 = "quantum.measure"(%2) : (!quantum.qubit<1>) -> (!quantum.measurement<1>, !quantum.qubit<1>)
//       %[[7:.+]] = "quantum.to_tensor"(%measurement_0) : (!quantum.measurement<1>) -> tensor<1xi1>
//       %measurement_2, %result_3 = "quantum.measure"(%4) : (!quantum.qubit<1>) -> (!quantum.measurement<1>, !quantum.qubit<1>)
//       %[[8:.]] = "quantum.to_tensor"(%measurement_2) : (!quantum.measurement<1>) -> tensor<1xi1>
//       "quantum.deallocate"(%result_1) : (!quantum.qubit<1>) -> ()
//       "quantum.deallocate"(%result_3) : (!quantum.qubit<1>) -> ()
//       "quantum.deallocate"(%result) : (!quantum.qubit<1>) -> ()
//       %concat = tensor.concat dim(0) %[[6]], %[[7]], %[[8]] : (tensor<1xi1>, tensor<1xi1>, tensor<1xi1>) -> tensor<3xi1>
//       "qpu.return"(%concat) : (tensor<3xi1>) -> ()
//     }) : () -> ()
//   }
//   func.func public @qasm_main() -> tensor<3xi1> {
//     %[[EMPTY:.+]] = tensor.empty() : tensor<3xi1>
//     %[[RES:.+]] = qpu.execute @qpu::@main ins() outs(%[[EMPTY]] : tensor<3xi1>)
//     return %[[RES]] : tensor<3xi1>
//   }
// }


OPENQASM 2.0;
include "qelib1.inc";

qreg q[3];
creg m2[1];
creg m0[1];
creg m1[1];

h q[0];
h q[1];
h q[2];

measure q[2] -> m2[0];
measure q[0] -> m0[0];
measure q[1] -> m1[0];
