// RUN: quantum-opt %s -split-input-file -verify-diagnostics

func.func @zero_controls(%q: !quantum.qubit<1>) {
    // expected-error @+1 {{'nctrls' must be between one and the number of inputs}}
    %r = "quantum.ctrl"(%q) <{nctrls = 0 : index}> ({
    ^bb0(%t: !quantum.qubit<1>):
        "quantum.yield"(%t) : (!quantum.qubit<1>) -> ()
    }) : (!quantum.qubit<1>) -> !quantum.qubit<1>
    return
}

// -----

func.func @negative_controls(%q: !quantum.qubit<1>) {
    // expected-error @+1 {{'nctrls' must be between one and the number of inputs}}
    %r = "quantum.ctrl"(%q) <{nctrls = -1 : index}> ({
        "quantum.yield"() : () -> ()
    }) : (!quantum.qubit<1>) -> !quantum.qubit<1>
    return
}

// -----

func.func @too_many_controls(%q: !quantum.qubit<1>) {
    // expected-error @+1 {{'nctrls' must be between one and the number of inputs}}
    %r = "quantum.ctrl"(%q) <{nctrls = 2 : index}> ({
        "quantum.yield"() : () -> ()
    }) : (!quantum.qubit<1>) -> !quantum.qubit<1>
    return
}

// -----

func.func @register_control(%q: !quantum.qubit<2>) {
    // expected-error @+1 {{control operands must be single qubits}}
    %r = "quantum.ctrl"(%q) ({
        "quantum.yield"() : () -> ()
    }) : (!quantum.qubit<2>) -> !quantum.qubit<2>
    return
}

// -----

func.func @missing_result(%c: !quantum.qubit<1>, %q: !quantum.qubit<1>) {
    // expected-error @+1 {{failed to verify that all of {input, result} have same type}}
    %r = "quantum.ctrl"(%c, %q) ({
    ^bb0(%t: !quantum.qubit<1>):
        "quantum.yield"(%t) : (!quantum.qubit<1>) -> ()
    }) : (!quantum.qubit<1>, !quantum.qubit<1>) -> !quantum.qubit<1>
    return
}

// -----

func.func @missing_body(%c: !quantum.qubit<1>) {
    // expected-error @+1 {{requires a non-empty body}}
    %r = "quantum.ctrl"(%c) ({}) : (!quantum.qubit<1>) -> !quantum.qubit<1>
    return
}

// -----

func.func @missing_argument(%c: !quantum.qubit<1>, %q: !quantum.qubit<1>) {
    // expected-error @+1 {{body arguments must match the target operands}}
    %r:2 = "quantum.ctrl"(%c, %q) ({
        "quantum.yield"() : () -> ()
    }) : (!quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>)
    return
}

// -----

func.func @wrong_argument_type(%c: !quantum.qubit<1>, %q: !quantum.qubit<2>) {
    // expected-error @+1 {{body argument types must match the target operand types}}
    %r:2 = "quantum.ctrl"(%c, %q) ({
    ^bb0(%t: !quantum.qubit<1>):
        "quantum.yield"(%t) : (!quantum.qubit<1>) -> ()
    }) : (!quantum.qubit<1>, !quantum.qubit<2>) -> (!quantum.qubit<1>, !quantum.qubit<2>)
    return
}

// -----

func.func @missing_yield_value(%c: !quantum.qubit<1>, %q: !quantum.qubit<1>) {
    %r:2 = "quantum.ctrl"(%c, %q) ({
    ^bb0(%t: !quantum.qubit<1>):
        // expected-error @+1 {{must yield one value for each target result}}
        "quantum.yield"() : () -> ()
    }) : (!quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>)
    return
}

// -----

func.func @wrong_yield_type(%c: !quantum.qubit<1>, %q: !quantum.qubit<2>) {
    %r:2 = "quantum.ctrl"(%c, %q) ({
    ^bb0(%t: !quantum.qubit<2>):
        %a, %b = "quantum.split"(%t) : (!quantum.qubit<2>) -> (!quantum.qubit<1>, !quantum.qubit<1>)
        // expected-error @+1 {{operand types must match the target result types}}
        "quantum.yield"(%a) : (!quantum.qubit<1>) -> ()
    }) : (!quantum.qubit<1>, !quantum.qubit<2>) -> (!quantum.qubit<1>, !quantum.qubit<2>)
    return
}

// -----

func.func @captured_qubit(%c: !quantum.qubit<1>, %q: !quantum.qubit<1>) {
    %r:2 = "quantum.ctrl"(%c, %q) ({
    ^bb0(%t: !quantum.qubit<1>):
        // expected-error @+1 {{qubits must be passed through quantum.ctrl body arguments}}
        %x = "quantum.X"(%q) : (!quantum.qubit<1>) -> !quantum.qubit<1>
        "quantum.yield"(%x) : (!quantum.qubit<1>) -> ()
    }) : (!quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>)
    return
}

// -----

func.func @wrong_parent(%q: !quantum.qubit<1>) {
    // expected-error @+1 {{'quantum.yield' op expects parent op 'quantum.ctrl'}}
    "quantum.yield"(%q) : (!quantum.qubit<1>) -> ()
}

// -----

func.func @wrong_terminator(%c: !quantum.qubit<1>) {
    // expected-error @+1 {{body must terminate with quantum.yield}}
    %r = "quantum.ctrl"(%c) ({
        llvm.unreachable
    }) : (!quantum.qubit<1>) -> !quantum.qubit<1>
    return
}

// -----

func.func @multiple_blocks(%c: !quantum.qubit<1>) {
    // expected-error @+1 {{expects region #0 to have 0 or 1 blocks}}
    %r = "quantum.ctrl"(%c) ({
    ^bb0:
        cf.br ^bb1
    ^bb1:
        "quantum.yield"() : () -> ()
    }) : (!quantum.qubit<1>) -> !quantum.qubit<1>
    return
}
