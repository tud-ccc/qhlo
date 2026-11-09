// RUN: quantum-qasm %S/Inputs/qpt.qasm | FileCheck %s

// The unmodified upstream source and provenance are in Inputs/ and README.md.
// Expected lowering of scalar q/c using the frontend's one-element register ABI.
// Empty pre/post gates are identities. Preserve reset and both barriers, and
// thread each updated qubit through subsequent operations to avoid cloning.

// CHECK-LABEL: module {
// CHECK-NEXT: qpu.module @qpt {
// CHECK-NEXT: "quantum.gate"() <{function_type = (!quantum.qubit<1>) -> !quantum.qubit<1>, sym_name = "pre"}> ({
// CHECK-NEXT: ^bb0(%[[PRE_ARG:.+]]: !quantum.qubit<1>):
// CHECK-NEXT: "quantum.return"(%[[PRE_ARG]]) : (!quantum.qubit<1>) -> ()
// CHECK-NEXT: }) : () -> ()
// CHECK-NEXT: "quantum.gate"() <{function_type = (!quantum.qubit<1>) -> !quantum.qubit<1>, sym_name = "post"}> ({
// CHECK-NEXT: ^bb0(%[[POST_ARG:.+]]: !quantum.qubit<1>):
// CHECK-NEXT: "quantum.return"(%[[POST_ARG]]) : (!quantum.qubit<1>) -> ()
// CHECK-NEXT: }) : () -> ()
// CHECK-NEXT: "qpu.circuit"() <{function_type = () -> tensor<1xi1>, sym_name = "main"}> ({
// CHECK: %[[Q:.*]] = "quantum.alloc"() : () -> !quantum.qubit<1>
// CHECK-NEXT: %[[C:.*]] = arith.constant dense<false> : tensor<1xi1>
// CHECK: %[[RESET:.*]] = "quantum.reset"(%[[Q]]) : (!quantum.qubit<1>) -> !quantum.qubit<1>
// CHECK-NEXT: %[[PRE:.*]] = "quantum.call"(%[[RESET]]) <{callee = @pre}> : (!quantum.qubit<1>) -> !quantum.qubit<1>
// CHECK-NEXT: %[[BARRIER1:.*]] = "quantum.barrier"(%[[PRE]]) : (!quantum.qubit<1>) -> !quantum.qubit<1>
// CHECK-NEXT: %[[H:.*]] = "quantum.H"(%[[BARRIER1]]) : (!quantum.qubit<1>) -> !quantum.qubit<1>
// CHECK-NEXT: %[[BARRIER2:.*]] = "quantum.barrier"(%[[H]]) : (!quantum.qubit<1>) -> !quantum.qubit<1>
// CHECK-NEXT: %[[POST:.*]] = "quantum.call"(%[[BARRIER2]]) <{callee = @post}> : (!quantum.qubit<1>) -> !quantum.qubit<1>
// CHECK: %[[MEAS:.*]], %[[MEASURED_Q:.*]] = "quantum.measure"(%[[POST]]) : (!quantum.qubit<1>) -> (!quantum.measurement<1>, !quantum.qubit<1>)
// CHECK-NEXT: %[[BITS:.*]] = "qpu.to_bits"(%[[MEAS]]) : (!quantum.measurement<1>) -> tensor<1xi1>
// CHECK-NEXT: "quantum.deallocate"(%[[MEASURED_Q]]) : (!quantum.qubit<1>) -> ()
// CHECK-NEXT: "qpu.return"(%[[BITS]]) : (tensor<1xi1>) -> ()
// CHECK-NEXT: }) : () -> ()
// CHECK-NEXT: }
// CHECK-NEXT: func.func @qasm_main() -> tensor<1xi1> {
// CHECK-NEXT: %[[OUT:.*]] = tensor.empty() : tensor<1xi1>
// CHECK-NEXT: %[[RESULT:.*]] = qpu.execute @qpt::@main ins () outs (%[[OUT]] : tensor<1xi1>)
// CHECK-NEXT: return %[[RESULT]] : tensor<1xi1>
// CHECK-NEXT: }
// CHECK-NEXT: }
