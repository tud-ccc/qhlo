// RUN: quantum-opt %s -split-input-file -inline | FileCheck %s

// Inlining must preserve both circuit symbols and their distinct execute calls.
// CHECK-LABEL: qpu.module @test
qpu.module @test {
    // CHECK: "qpu.circuit"()
    // CHECK-SAME: sym_name = "test_circuit1"
    "qpu.circuit"() <{function_type = () -> (tensor<1xi1>), sym_name = "test_circuit1"}>({
        ^bb0():
        %q = "quantum.alloc"() : () -> (!quantum.qubit<1>)
        %m, %qm = "quantum.measure"(%q) : (!quantum.qubit<1>) -> (!quantum.measurement<1>, !quantum.qubit<1>)
        %mt = "qpu.to_bits"(%m) : (!quantum.measurement<1>) -> (tensor<1xi1>)
        "quantum.deallocate"(%qm) : (!quantum.qubit<1>) -> ()
        // CHECK: "qpu.return"
        "qpu.return"(%mt) : (tensor<1xi1>) -> ()
    }) : () -> ()

    // CHECK: "qpu.circuit"()
    // CHECK-SAME: sym_name = "test_circuit2"
    "qpu.circuit"() <{function_type = () -> (tensor<1xi1>), sym_name = "test_circuit2"}>({
        ^bb0():
        %q = "quantum.alloc"() : () -> (!quantum.qubit<1>)
        %qx = "quantum.X"(%q) : (!quantum.qubit<1>) -> (!quantum.qubit<1>)
        %rot = arith.constant 0.345 : f64
        %qr = "quantum.Rz"(%qx, %rot) : (!quantum.qubit<1>, f64) -> (!quantum.qubit<1>)
        %m, %qm = "quantum.measure"(%qr) : (!quantum.qubit<1>) -> (!quantum.measurement<1>, !quantum.qubit<1>)
        %mt = "qpu.to_bits"(%m) : (!quantum.measurement<1>) -> (tensor<1xi1>)
        "quantum.deallocate"(%qm) : (!quantum.qubit<1>) -> ()
        // CHECK: "qpu.return"
        "qpu.return"(%mt) : (tensor<1xi1>) -> ()
    }) : () -> ()
}

// CHECK-LABEL: func.func @main()
func.func @main() -> (tensor<1xi1>, tensor<1xi1>) {
    // CHECK-NEXT: %[[BUFFER:.*]] = tensor.empty() : tensor<1xi1>
    %res = tensor.empty() : tensor<1xi1>
    // CHECK-NEXT: %[[FIRST:.*]] = qpu.execute @test::@test_circuit1 ins () outs (%[[BUFFER]] : tensor<1xi1>)
    %res2 = qpu.execute @test::@test_circuit1 ins() outs(%res : tensor<1xi1>)
    // CHECK-NEXT: %[[SECOND:.*]] = qpu.execute @test::@test_circuit2 ins () outs (%[[BUFFER]] : tensor<1xi1>)
    %res3 = qpu.execute @test::@test_circuit2 ins() outs(%res : tensor<1xi1>)
    // CHECK-NEXT: return %[[FIRST]], %[[SECOND]] : tensor<1xi1>, tensor<1xi1>
    func.return %res2, %res3 : tensor<1xi1>, tensor<1xi1>
}
