// RUN: quantum-qasm %S/Inputs/qpt.qasm | FileCheck %s

// The unmodified upstream source and provenance are in Inputs/ and README.md.
// Check typed operations, parameters, register slices and SSA flow through
// gates, barriers, measurements, classical conditions and circuit results.

// CHECK-LABEL: module {
// CHECK-NEXT:         qpu.module @qpt {
// CHECK-NEXT:           "quantum.gate"() <{function_type = (!quantum.qubit<1>) -> !quantum.qubit<1>, sym_name = "pre"}> ({
// CHECK-NEXT:           ^bb0(%[[PRE_ARG:.*]]: !quantum.qubit<1>):
// CHECK-NEXT:             "quantum.return"(%[[PRE_ARG]]) : (!quantum.qubit<1>) -> ()
// CHECK-NEXT:           }) : () -> ()
// CHECK-NEXT:           "quantum.gate"() <{function_type = (!quantum.qubit<1>) -> !quantum.qubit<1>, sym_name = "post"}> ({
// CHECK-NEXT:           ^bb0(%[[POST_ARG:.*]]: !quantum.qubit<1>):
// CHECK-NEXT:             "quantum.return"(%[[POST_ARG]]) : (!quantum.qubit<1>) -> ()
// CHECK-NEXT:           }) : () -> ()
// CHECK-NEXT:           "qpu.circuit"() <{function_type = () -> tensor<1xi1>, sym_name = "main"}> ({
// CHECK-NEXT:             %[[Q:.*]] = "quantum.alloc"() : () -> !quantum.qubit<1>
// CHECK-NEXT:             %[[PRE:.*]] = "quantum.call"(%[[Q]]) <{callee = @pre}> : (!quantum.qubit<1>) -> !quantum.qubit<1>
// CHECK-NEXT:             %[[BARRIER1:.*]] = "quantum.barrier"(%[[PRE]]) : (!quantum.qubit<1>) -> !quantum.qubit<1>
// CHECK-NEXT:             %[[H:.*]] = "quantum.H"(%[[BARRIER1]]) : (!quantum.qubit<1>) -> !quantum.qubit<1>
// CHECK-NEXT:             %[[BARRIER2:.*]] = "quantum.barrier"(%[[H]]) : (!quantum.qubit<1>) -> !quantum.qubit<1>
// CHECK-NEXT:             %[[POST:.*]] = "quantum.call"(%[[BARRIER2]]) <{callee = @post}> : (!quantum.qubit<1>) -> !quantum.qubit<1>
// CHECK-NEXT:             %[[CONSTANT_0:.*]] = arith.constant dense<false> : tensor<1xi1>
// CHECK-NEXT:             %[[MEASUREMENT:.*]], %[[MEASURED_Q:.*]] = "quantum.measure"(%[[POST]]) : (!quantum.qubit<1>) -> (!quantum.measurement<1>, !quantum.qubit<1>)
// CHECK-NEXT:             %[[BITS:.*]] = "qpu.to_bits"(%[[MEASUREMENT]]) : (!quantum.measurement<1>) -> tensor<1xi1>
// CHECK-NEXT:             %[[INSERT_SLICE_0:.*]] = tensor.insert_slice %[[BITS]] into %[[CONSTANT_0]][0] [1] [1] : tensor<1xi1> into tensor<1xi1>
// CHECK-DAG:             "quantum.deallocate"(%[[MEASURED_Q]]) : (!quantum.qubit<1>) -> ()
// CHECK-NEXT:             "qpu.return"(%[[INSERT_SLICE_0]]) : (tensor<1xi1>) -> ()
// CHECK-NEXT:           }) : () -> ()
// CHECK-NEXT:         }
// CHECK-NEXT:         func.func @qasm_main() -> tensor<1xi1> {
// CHECK-NEXT:           %[[EMPTY_0:.*]] = tensor.empty() : tensor<1xi1>
// CHECK-NEXT:           %[[EXECUTE_0:.*]] = qpu.execute @qpt::@main ins () outs (%[[EMPTY_0]] : tensor<1xi1>)
// CHECK-NEXT:           return %[[EXECUTE_0]] : tensor<1xi1>
// CHECK-NEXT:         }
// CHECK-NEXT:       }
