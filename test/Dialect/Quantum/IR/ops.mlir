// RUN: quantum-opt %s -split-input-file | FileCheck %s --enable-var-scope

func.func @qubit_alloc_dealloc() -> () {
    %reg = "quantum.alloc" () : () -> (!quantum.qubit<3>)
    "quantum.deallocate" (%reg) : (!quantum.qubit<3>) -> ()
    return
}

// -----

func.func @qubit_split_merge(%reg : !quantum.qubit<3>) -> (!quantum.qubit<3>) {
    // split
    %q0, %q1 = "quantum.split" (%reg) : (!quantum.qubit<3>) -> (!quantum.qubit<2>, !quantum.qubit<1>)
    %q00, %q01 = "quantum.split" (%q0) : (!quantum.qubit<2>) -> (!quantum.qubit<1>, !quantum.qubit<1>)
    // merge
    %qm0 = "quantum.merge" (%q00, %q01) : (!quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<2>)
    %qm1 = "quantum.merge" (%qm0, %q1) : (!quantum.qubit<2>, !quantum.qubit<1>) -> (!quantum.qubit<3>)
    return %qm1 : !quantum.qubit<3>
}

// -----

func.func @qubit_measure_single(%reg : !quantum.qubit<1>) -> (tensor<1xi1>, !quantum.qubit<1>) {
    %m, %qm_single_out = "quantum.measure" (%reg) : (!quantum.qubit<1>) -> (!quantum.measurement<1>, !quantum.qubit<1>)
    %tm = "qpu.to_bits"(%m) : (!quantum.measurement<1>) -> (tensor<1xi1>)
    return %tm, %qm_single_out : tensor<1xi1>, !quantum.qubit<1>
}

// -----

func.func @qubit_measure_multiple(%reg : !quantum.qubit<2>) -> (tensor<2xi1>, !quantum.qubit<2>) {
    %m, %qm_out = "quantum.measure" (%reg) : (!quantum.qubit<2>) -> (!quantum.measurement<2>, !quantum.qubit<2>)
    %mt = "qpu.to_bits"(%m) : (!quantum.measurement<2>) -> tensor<2xi1>
    return %mt, %qm_out : tensor<2xi1>, !quantum.qubit<2>
}

// -----

func.func @qubit_pauli(%reg : !quantum.qubit<1>) -> (!quantum.qubit<1>) {
    %qX = "quantum.X" (%reg) : (!quantum.qubit<1>) -> (!quantum.qubit<1>)
    %qY = "quantum.Y" (%qX) : (!quantum.qubit<1>) -> (!quantum.qubit<1>)
    %qZ = "quantum.Z" (%qY) : (!quantum.qubit<1>) -> (!quantum.qubit<1>)
    %qH = "quantum.H" (%qZ) : (!quantum.qubit<1>) -> (!quantum.qubit<1>)
    return %qH : !quantum.qubit<1>
}

// -----

"quantum.gate"() <{function_type = (!quantum.qubit<1>) -> (!quantum.qubit<1>), sym_name = "test"}>({
    ^bb0(%arg0 : !quantum.qubit<1>):
    "quantum.return"(%arg0) : (!quantum.qubit<1>) -> ()
}) : () -> ()

func.func @quantum_gate(%reg : !quantum.qubit<1>) -> (!quantum.qubit<1>) {
    %out = "quantum.call"(%reg) <{callee = @test}> : (!quantum.qubit<1>) -> (!quantum.qubit<1>)
    return %out : !quantum.qubit<1>
}

// -----

// An omitted control count means one control; classical parameters may be captured.
// CHECK-LABEL: func.func @controlled_phase(
// CHECK-SAME: %[[CONTROL:[^:]+]]: !quantum.qubit<1>, %[[TARGET:[^:]+]]: !quantum.qubit<1>, %[[ANGLE:[^:]+]]: f64
// CHECK: %[[R:.*]]:2 = "quantum.ctrl"(%[[CONTROL]], %[[TARGET]]) <{nctrls = 1 : index}>
// CHECK: ^bb0(%[[ARG:[^:]+]]: !quantum.qubit<1>):
// CHECK: %[[PHASE:.*]] = "quantum.P"(%[[ARG]], %[[ANGLE]])
// CHECK: "quantum.yield"(%[[PHASE]]) : (!quantum.qubit<1>) -> ()
// CHECK: return %[[R]]#0, %[[R]]#1 : !quantum.qubit<1>, !quantum.qubit<1>
func.func @controlled_phase(%control: !quantum.qubit<1>, %target: !quantum.qubit<1>, %angle: f64) -> (!quantum.qubit<1>, !quantum.qubit<1>) {
    %r:2 = "quantum.ctrl"(%control, %target) ({
    ^bb0(%q: !quantum.qubit<1>):
        %phase = "quantum.P"(%q, %angle) : (!quantum.qubit<1>, f64) -> !quantum.qubit<1>
        "quantum.yield"(%phase) : (!quantum.qubit<1>) -> ()
    }) : (!quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>)
    return %r#0, %r#1 : !quantum.qubit<1>, !quantum.qubit<1>
}

// -----

// Controls are scalar; targets can be registers. Only targets enter the body.
// CHECK-LABEL: func.func @two_controls(
// CHECK-SAME: %[[C0:[^:]+]]: !quantum.qubit<1>, %[[C1:[^:]+]]: !quantum.qubit<1>, %[[TARGET:[^:]+]]: !quantum.qubit<2>
// CHECK: %[[R:.*]]:3 = "quantum.ctrl"(%[[C0]], %[[C1]], %[[TARGET]]) <{nctrls = 2 : index}>
// CHECK: ^bb0(%[[ARG:[^:]+]]: !quantum.qubit<2>):
// CHECK: %[[X:.*]] = "quantum.X"(%[[ARG]])
// CHECK: "quantum.yield"(%[[X]]) : (!quantum.qubit<2>) -> ()
// CHECK: return %[[R]]#0, %[[R]]#1, %[[R]]#2 : !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<2>
func.func @two_controls(%c0: !quantum.qubit<1>, %c1: !quantum.qubit<1>, %target: !quantum.qubit<2>) -> (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<2>) {
    %r:3 = "quantum.ctrl"(%c0, %c1, %target) <{nctrls = 2 : index}> ({
    ^bb0(%q: !quantum.qubit<2>):
        %flipped = "quantum.X"(%q) : (!quantum.qubit<2>) -> !quantum.qubit<2>
        "quantum.yield"(%flipped) : (!quantum.qubit<2>) -> ()
    }) : (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<2>) -> (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<2>)
    return %r#0, %r#1, %r#2 : !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<2>
}
