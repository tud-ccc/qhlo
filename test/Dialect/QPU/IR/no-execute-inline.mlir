// RUN: quantum-opt %s -split-input-file -inline | FileCheck %s

// Executing a circuit must remain a call to its device module after inlining.
// CHECK-LABEL: qpu.module @test
qpu.module @test {
    // CHECK: "qpu.circuit"()
    // CHECK-SAME: sym_name = "test_circuit"
    "qpu.circuit"() <{function_type = () -> (tensor<1xi1>), sym_name = "test_circuit"}>({
        ^bb0():
        %q = "quantum.alloc"() : () -> (!quantum.qubit<1>)
        %m, %qm = "quantum.measure"(%q) : (!quantum.qubit<1>) -> (!quantum.measurement<1>, !quantum.qubit<1>)
        %mt = "qpu.to_bits"(%m) : (!quantum.measurement<1>) -> (tensor<1xi1>)
        "quantum.deallocate"(%qm) : (!quantum.qubit<1>) -> ()
        // CHECK: "qpu.return"
        "qpu.return"(%mt) : (tensor<1xi1>) -> ()
    }) : () -> ()
}

// CHECK-LABEL: func.func @main()
func.func @main() -> tensor<1xi1> {
    // CHECK-NEXT: %[[BUFFER:.*]] = tensor.empty() : tensor<1xi1>
    %res = tensor.empty() : tensor<1xi1>
    // CHECK-NEXT: %[[RESULT:.*]] = qpu.execute @test::@test_circuit ins () outs (%[[BUFFER]] : tensor<1xi1>)
    %res2 = qpu.execute @test::@test_circuit ins() outs(%res : tensor<1xi1>)
    // CHECK-NEXT: return %[[RESULT]] : tensor<1xi1>
    func.return %res2 : tensor<1xi1>
}
