// RUN: quantum-qasm %S/Inputs/qft.qasm > %t.mlir
// RUN: FileCheck %s < %t.mlir
// RUN: quantum-opt %t.mlir -o /dev/null

// Keep the upstream source unchanged. Check its included cphase definition,
// all six folded angles, and SSA flow from preparation to register measurement.
// CHECK-LABEL: qpu.module @qft
// CHECK: sym_name = "cphase"
// CHECK: ^bb0(%[[CONTROL:[^:]+]]: !quantum.qubit<1>, %[[TARGET:[^:]+]]: !quantum.qubit<1>, %[[ANGLE:[^:]+]]: f64):
// CHECK: %[[CTRL:.*]]:2 = "quantum.ctrl"(%[[CONTROL]], %[[TARGET]]) <{nctrls = 1 : index}>
// CHECK: ^bb0(%[[ARG:[^:]+]]: !quantum.qubit<1>):
// CHECK: %[[PHASE:.*]] = "quantum.P"(%[[ARG]], %[[ANGLE]])
// CHECK: "quantum.yield"(%[[PHASE]])
// CHECK: "quantum.return"(%[[CTRL]]#0, %[[CTRL]]#1)

// CHECK: "qpu.circuit"() <{function_type = () -> tensor<4xi1>, sym_name = "main"}>
// CHECK: %[[ALLOC:.*]] = "quantum.alloc"() : () -> !quantum.qubit<4>
// CHECK: %[[RESET:.*]] = "quantum.reset"(%[[ALLOC]])
// CHECK: %[[LEFT:.*]]:2 = "quantum.split"(%[[RESET]])
// CHECK: %[[X0:.*]] = "quantum.X"(%[[LEFT]]#0)
// CHECK: %[[RIGHT:.*]]:3 = "quantum.split"(%[[LEFT]]#1)
// CHECK: %[[X2:.*]] = "quantum.X"(%[[RIGHT]]#1)
// CHECK: %[[B:.*]]:4 = "quantum.barrier"(%[[X0]], %[[RIGHT]]#0, %[[X2]], %[[RIGHT]]#2)
// CHECK: %[[H0:.*]] = "quantum.H"(%[[B]]#0)
// CHECK: %[[A0:.*]] = arith.constant 1.5707963267948966 : f64
// CHECK: %[[C0:.*]]:2 = "quantum.call"(%[[B]]#1, %[[H0]], %[[A0]]) <{callee = @cphase}>
// CHECK: %[[H1:.*]] = "quantum.H"(%[[C0]]#0)
// CHECK: %[[A1:.*]] = arith.constant 0.78539816339744828 : f64
// CHECK: %[[C1:.*]]:2 = "quantum.call"(%[[B]]#2, %[[C0]]#1, %[[A1]]) <{callee = @cphase}>
// CHECK: %[[A2:.*]] = arith.constant 1.5707963267948966 : f64
// CHECK: %[[C2:.*]]:2 = "quantum.call"(%[[C1]]#0, %[[H1]], %[[A2]]) <{callee = @cphase}>
// CHECK: %[[H2:.*]] = "quantum.H"(%[[C2]]#0)
// CHECK: %[[A3:.*]] = arith.constant 0.39269908169872414 : f64
// CHECK: %[[C3:.*]]:2 = "quantum.call"(%[[B]]#3, %[[C1]]#1, %[[A3]]) <{callee = @cphase}>
// CHECK: %[[A4:.*]] = arith.constant 0.78539816339744828 : f64
// CHECK: %[[C4:.*]]:2 = "quantum.call"(%[[C3]]#0, %[[C2]]#1, %[[A4]]) <{callee = @cphase}>
// CHECK: %[[A5:.*]] = arith.constant 1.5707963267948966 : f64
// CHECK: %[[C5:.*]]:2 = "quantum.call"(%[[C4]]#0, %[[H2]], %[[A5]]) <{callee = @cphase}>
// CHECK: %[[H3:.*]] = "quantum.H"(%[[C5]]#0)
// CHECK: %[[MERGED:.*]] = "quantum.merge"(%[[C3]]#1, %[[C4]]#1, %[[C5]]#1, %[[H3]])
// CHECK: %[[MEASURE:.*]], %[[AFTER:.*]] = "quantum.measure"(%[[MERGED]])
// CHECK: %[[BITS:.*]] = "qpu.to_bits"(%[[MEASURE]]) : (!quantum.measurement<4>) -> tensor<4xi1>
// CHECK: "quantum.deallocate"(%[[AFTER]])
// CHECK: "qpu.return"(%[[BITS]]) : (tensor<4xi1>) -> ()
// CHECK-LABEL: func.func @qasm_main() -> tensor<4xi1>
// CHECK: qpu.execute @qft::@main
