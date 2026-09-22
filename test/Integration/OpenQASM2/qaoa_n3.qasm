// RUN: quantum-qasm %s | quantum-opt --inline | FileCheck %s
// RUN: quantum-qasm %s | quantum-opt --inline --convert-quantum-to-qillr | FileCheck %s --check-prefixes=CHECK2
// Stripped down from QASMBenc small/qaoa_n3.qasm

// CHECK: module {
// CHECK:  qpu.module @qasm_generated {
// CHECK:     "qpu.circuit"() <{function_type = () -> tensor<3xi1>, sym_name = "main"}> ({
// CHECK:       %0 = "quantum.alloc"() : () -> !quantum.qubit<3>
// CHECK:       %1:2 = "quantum.split"(%0) : (!quantum.qubit<3>) -> (!quantum.qubit<1>, !quantum.qubit<2>)
// CHECK:       %2 = "quantum.H"(%1#0) : (!quantum.qubit<1>) -> !quantum.qubit<1>
// CHECK:       %3:2 = "quantum.split"(%1#1) : (!quantum.qubit<2>) -> (!quantum.qubit<1>, !quantum.qubit<1>)
// CHECK:       %4 = "quantum.H"(%3#0) : (!quantum.qubit<1>) -> !quantum.qubit<1>
// CHECK:       %5 = "quantum.H"(%3#1) : (!quantum.qubit<1>) -> !quantum.qubit<1>
// CHECK:       %measurement, %result = "quantum.measure"(%5) : (!quantum.qubit<1>) -> (!quantum.measurement<1>, !quantum.qubit<1>)
// CHECK:       %[[6:.+]] = "quantum.to_tensor"(%measurement) : (!quantum.measurement<1>) -> tensor<1xi1>
// CHECK:       %measurement_0, %result_1 = "quantum.measure"(%2) : (!quantum.qubit<1>) -> (!quantum.measurement<1>, !quantum.qubit<1>)
// CHECK:       %[[7:.+]] = "quantum.to_tensor"(%measurement_0) : (!quantum.measurement<1>) -> tensor<1xi1>
// CHECK:       %measurement_2, %result_3 = "quantum.measure"(%4) : (!quantum.qubit<1>) -> (!quantum.measurement<1>, !quantum.qubit<1>)
// CHECK:       %[[8:.]] = "quantum.to_tensor"(%measurement_2) : (!quantum.measurement<1>) -> tensor<1xi1>
// CHECK:       "quantum.deallocate"(%result_1) : (!quantum.qubit<1>) -> ()
// CHECK:       "quantum.deallocate"(%result_3) : (!quantum.qubit<1>) -> ()
// CHECK:       "quantum.deallocate"(%result) : (!quantum.qubit<1>) -> ()
// CHECK:       %concat = tensor.concat dim(0) %[[6]], %[[7]], %[[8]] : (tensor<1xi1>, tensor<1xi1>, tensor<1xi1>) -> tensor<3xi1>
// CHECK:       "qpu.return"(%concat) : (tensor<3xi1>) -> ()
// CHECK:     }) : () -> ()
// CHECK:   }
// CHECK:   func.func public @qasm_main() -> tensor<3xi1> {
// CHECK:     %[[EMPTY:.+]] = tensor.empty() : tensor<3xi1>
// CHECK:     %[[RES:.+]] = qpu.execute @qpu::@main ins() outs(%[[EMPTY]] : tensor<3xi1>)
// CHECK:     return %[[RES]] : tensor<3xi1>
// CHECK:   }
// CHECK: }


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
