// RUN: quantum-opt %s -split-input-file

qpu.module @test
    [#qpu.target<
        qubits = 3,
        coupling = [[0, 1], [1, 2]]
    >] {

    "qpu.circuit"() <{function_type = (f64) -> (tensor<1xi1>), sym_name = "test_circuit"}>({
        ^bb0(%theta : f64):
        %q = "quantum.alloc"() : () -> (!quantum.qubit<1>)
        %m, %qm = "quantum.measure"(%q) : (!quantum.qubit<1>) -> (!quantum.measurement<1>, !quantum.qubit<1>)
        %tm = "qpu.to_bits"(%m) : (!quantum.measurement<1>) -> (tensor<1xi1>)
        "quantum.deallocate"(%qm) : (!quantum.qubit<1>) -> ()
        "qpu.return"(%tm) : (tensor<1xi1>) -> ()
    }) : () -> ()
}

%theta = arith.constant 3.2 : f64
%res = tensor.empty() : tensor<1xi1>
%res2 = qpu.execute @test::@test_circuit ins(%theta : f64) outs(%res : tensor<1xi1>)
