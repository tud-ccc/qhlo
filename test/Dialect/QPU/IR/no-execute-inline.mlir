// RUN: quantum-opt %s -split-input-file -inline

qpu.module @test {
    // CHECK-SAME
    "qpu.circuit"() <{function_type = () -> (tensor<1xi1>), sym_name = "test_circuit"}>({
        ^bb0():
        %q = "quantum.alloc"() : () -> (!quantum.qubit<1>)
        %m, %qm = "quantum.measure"(%q) : (!quantum.qubit<1>) -> (!quantum.measurement<1>, !quantum.qubit<1>)
        %mt = "qpu.to_bits"(%m) : (!quantum.measurement<1>) -> (tensor<1xi1>)
        "quantum.deallocate"(%qm) : (!quantum.qubit<1>) -> ()
        "qpu.return"(%mt) : (tensor<1xi1>) -> ()
    }) : () -> ()
}

func.func @main() -> tensor<1xi1> {
    %res = tensor.empty() : tensor<1xi1>
    // CHECK-SAME
    %res2 = qpu.execute @test::@test_circuit ins() outs(%res : tensor<1xi1>)
    func.return %res2 : tensor<1xi1>
}
