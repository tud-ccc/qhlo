// RUN: quantum-opt %s -split-input-file -inline

qpu.module @test {
    // CHECK-SAME
    "qpu.circuit"() <{function_type = () -> (tensor<1xi1>), sym_name = "test_circuit1"}>({
        ^bb0():
        %q = "quantum.alloc"() : () -> (!quantum.qubit<1>)
        %m, %qm = "quantum.measure"(%q) : (!quantum.qubit<1>) -> (!quantum.measurement<1>, !quantum.qubit<1>)
        %mt = "qpu.to_bits"(%m) : (!quantum.measurement<1>) -> (tensor<1xi1>)
        "quantum.deallocate"(%qm) : (!quantum.qubit<1>) -> ()
        "qpu.return"(%mt) : (tensor<1xi1>) -> ()
    }) : () -> ()

    // CHECK-SAME
    "qpu.circuit"() <{function_type = () -> (tensor<1xi1>), sym_name = "test_circuit2"}>({
        ^bb0():
        %q = "quantum.alloc"() : () -> (!quantum.qubit<1>)
        %qx = "quantum.X"(%q) : (!quantum.qubit<1>) -> (!quantum.qubit<1>)
        %rot = arith.constant 0.345 : f64
        %qr = "quantum.Rz"(%qx, %rot) : (!quantum.qubit<1>, f64) -> (!quantum.qubit<1>)
        %m, %qm = "quantum.measure"(%qr) : (!quantum.qubit<1>) -> (!quantum.measurement<1>, !quantum.qubit<1>)
        %mt = "qpu.to_bits"(%m) : (!quantum.measurement<1>) -> (tensor<1xi1>)
        "quantum.deallocate"(%qm) : (!quantum.qubit<1>) -> ()
        "qpu.return"(%mt) : (tensor<1xi1>) -> ()
    }) : () -> ()
}

func.func @main() -> (tensor<1xi1>, tensor<1xi1>) {
    %res = tensor.empty() : tensor<1xi1>
    // CHECK-SAME
    %res2 = qpu.execute @test::@test_circuit1 ins() outs(%res : tensor<1xi1>)
    %res3 = qpu.execute @test::@test_circuit2 ins() outs(%res : tensor<1xi1>)
    func.return %res2, %res3 : tensor<1xi1>, tensor<1xi1>
}
