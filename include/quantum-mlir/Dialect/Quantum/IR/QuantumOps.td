//===- Ops.td - Quantum dialect ops ----------------------*- tablegen -*-===//
//
// This is the definitions file for the Quantum dialect ops.
//
//===----------------------------------------------------------------------===//

#ifndef QUANTUM_OPS
#define QUANTUM_OPS

include "quantum-mlir/Dialect/Quantum/IR/QuantumTypes.td"
include "quantum-mlir/Dialect/Quantum/Interfaces/InferRegisterRangesInterface.td"
include "quantum-mlir/Dialect/Quantum/Interfaces/InferPhasePolynomialInterface.td"
include "mlir/Interfaces/CastInterfaces.td"
include "mlir/Interfaces/ControlFlowInterfaces.td"
include "mlir/IR/SymbolInterfaces.td"
include "mlir/Interfaces/CallInterfaces.td"
include "mlir/Interfaces/FunctionInterfaces.td"
include "mlir/Interfaces/InferTypeOpInterface.td"
include "mlir/Interfaces/SideEffectInterfaces.td"


//===----------------------------------------------------------------------===//
// Quantum OP templates
//===----------------------------------------------------------------------===//

class Gate_Op<string mnemonic, list<Trait> traits = []>
        : Quantum_Op<mnemonic, traits>;

class Memory_Op<string mnemonic, list<Trait> traits = []>
        : Quantum_Op<mnemonic, traits # [ConditionallySpeculatable]>
{
    code extraClassDeclaration = [{
        ::mlir::Speculation::Speculatability getSpeculatability() const {
            return ::mlir::Speculation::NotSpeculatable;
        }
    }];
}

class Observable_Op<string mnemonic, list<Trait> traits = []>
        : Quantum_Op<mnemonic, traits # [Pure]>;

class Measurement_Op<string mnemonic, list<Trait> traits = []>
        : Quantum_Op<mnemonic, traits>; 

//===----------------------------------------------------------------------===//
// Quantum dialect traits.
//===----------------------------------------------------------------------===//

// Inject no clone theorem verifier into operations
// that produce qubits
def NoClone : NativeOpTrait<"NoClone"> {
  let cppNamespace = "::mlir::quantum";
}

def Hermitian : NativeOpTrait<"Hermitian"> {
  let cppNamespace = "::mlir::quantum";
}

def Unitary : NativeOpTrait<"Unitary"> {
  let cppNamespace = "::mlir::quantum";
}

def Adjoint : NativeOpTrait<"Adjoint"> {
  let cppNamespace = "::mlir::quantum";
}

class AdjointTo<string op>
  : ParamNativeOpTrait<"AdjointTo", op> {
  let cppNamespace = "::mlir::quantum";
}


//===----------------------------------------------------------------------===//
// Quantum gate operations.
//===----------------------------------------------------------------------===//

def Quantum_GateOp : Quantum_Op<
  "gate",
  [
    IsolatedFromAbove,
    FunctionOpInterface,
    NoClone
  ]> {
  let summary = "A quantum gate operation";
  let description = [{ A quantum gate operation. }];
  let arguments = (ins
    SymbolNameAttr:$sym_name,
    OptionalAttr<DictArrayAttr>:$arg_attrs,
    OptionalAttr<DictArrayAttr>:$res_attrs,
    TypeAttrOf<FunctionType>:$function_type
  );

  let regions = (region AnyRegion:$body);

  let builders = [OpBuilder<(ins
    "StringRef":$name, "FunctionType":$type,
    CArg<"ArrayRef<NamedAttribute>", "{}">:$attrs,
    CArg<"ArrayRef<DictionaryAttr>", "{}">:$argAttrs)
  >];

  let extraClassDeclaration = [{
    static GateOp create(Location location, StringRef name, FunctionType type,
                         ArrayRef<NamedAttribute> attrs = {});

    //===------------------------------------------------------------------===//
    // FunctionOpInterface Methods
    //===------------------------------------------------------------------===//

    /// Returns the region on the current operation that is callable.
    ::mlir::Region *getCallableRegion() { return &getBody(); }

    /// Returns the argument types of this function.
    ArrayRef<Type> getArgumentTypes() { return getFunctionType().getInputs(); }

    /// Returns the result types of this function.
    ArrayRef<Type> getResultTypes() { return getFunctionType().getResults(); }
    
    //===------------------------------------------------------------------===//
    // SymbolOpInterface Methods
    //===------------------------------------------------------------------===//

    bool isDeclaration() { return false; }

    bool canDiscardOnUseEmpty() { return true; }
  }];
}

def Quantum_GateCallOp : Gate_Op<
  "call",
  [
    CallOpInterface,
    DeclareOpInterfaceMethods<SymbolUserOpInterface>,
    NoClone
  ]> {
  let summary = "Gate call operation";
  let description = [{ Gate call operation. }];

  let arguments = (ins
    FlatSymbolRefAttr:$callee,
    Variadic<AnyType>:$operands,
    OptionalAttr<DictArrayAttr>:$arg_attrs,
    OptionalAttr<DictArrayAttr>:$res_attrs
  );

  let results = (outs Variadic<AnyType>);

  let builders = [
    OpBuilder<(ins "GateOp":$callee, CArg<"ValueRange", "{}">:$operands), [{
      $_state.addOperands(operands);
      $_state.addAttribute("callee", SymbolRefAttr::get(callee));
      $_state.addTypes(callee.getFunctionType().getResults());
    }]>,
    OpBuilder<(ins "SymbolRefAttr":$callee, "TypeRange":$results,
      CArg<"ValueRange", "{}">:$operands), [{
      $_state.addOperands(operands);
      $_state.addAttribute("callee", callee);
      $_state.addTypes(results);
    }]>,
    OpBuilder<(ins "StringAttr":$callee, "TypeRange":$results,
      CArg<"ValueRange", "{}">:$operands), [{
      build($_builder, $_state, SymbolRefAttr::get(callee), results, operands);
    }]>,
    OpBuilder<(ins "StringRef":$callee, "TypeRange":$results,
      CArg<"ValueRange", "{}">:$operands), [{
      build($_builder, $_state, StringAttr::get($_builder.getContext(), callee),
            results, operands);
    }]>
  ];

  let extraClassDeclaration = [{
    FunctionType getCalleeType();

    /// Get the argument operands to the called function.
    operand_range getArgOperands() {
      return {arg_operand_begin(), arg_operand_end()};
    }

    MutableOperandRange getArgOperandsMutable() {
      return getOperandsMutable();
    }

    operand_iterator arg_operand_begin() { return operand_begin(); }
    operand_iterator arg_operand_end() { return operand_end(); }

    /// Return the callee of this operation.
    CallInterfaceCallable getCallableForCallee() {
      return (*this)->getAttrOfType<SymbolRefAttr>("callee");
    }

    /// Set the callee for this operation.
    void setCalleeFromCallable(CallInterfaceCallable callee) {
      (*this)->setAttr("callee", cast<SymbolRefAttr>(callee));
    }
  }];
}

def Quantum_ReturnOp : Quantum_Op<
  "return",
  [
    Pure,
    HasParent<"GateOp">,
    ReturnLike,
    Terminator,
    NoClone
  ]> {
  let summary = "Quantum gate return operation";
  let description = [{
    The `quantum.return` operation represents a return operation within a
    gate body.
    The operation takes variable number of operands and produces no results.
    The operand number and types must match the signature of the gate's
    function type that contains the operation.
    ```
  }];

  let arguments = (ins Variadic<AnyType>:$operands);

  let builders = [OpBuilder<(ins), [{
    build($_builder, $_state, ::mlir::ValueRange{});
  }]>];

  let hasVerifier = 1;
}

//===----------------------------------------------------------------------===//
// Quantum memory operations.
//===----------------------------------------------------------------------===//

def Quantum_AllocOp : Memory_Op<
  "alloc",
  [
    MemoryEffects<[
      MemRead
    ]>,
    DeclareOpInterfaceMethods<
      InferRegisterRangesInterface, ["inferResultRanges"]
    >,
    DeclareOpInterfaceMethods<
      InferPhasePolynomialInterface, ["inferResultPolynomial"]
    >,
    NoClone
  ]> {
  let summary = "Allocate n qubits into a quantum register.";
  let description = [{
    Allocates a fixed number of N qubits into a single quantum register.

    Example:

    ```mlir
    %q0 = quantum.alloc : !quantum.qubit<5>
    ```
  }];

  let arguments = (ins
    OptionalAttr<ConfinedAttr<I32Attr, [IntNonNegative]>>:$pos
  );

  let results = (outs Quantum_QubitType:$result);
}

def Quantum_DeallocateOp : Memory_Op<
  "deallocate",
  [
    MemoryEffects<[
      MemRead,
      MemWrite
    ]>,
    DeclareOpInterfaceMethods<
      InferRegisterRangesInterface, ["inferResultRanges"]
    >,
    NoClone
  ]> {
    let summary = "Deallocate a quantum register.";
    let description = [{
    Use this operation on all qubit registers that are not measured.
    Deallocated qubits no longer can be used.

    Example:
    
    ```mlir
    %q0 = quantum.alloc : !quantum.qubit<5> 
    %quantum.deallocate (%q0) : !quantum.qubit<5> -> ()
    ```
    }];

    let arguments = (ins
      Quantum_QubitType:$input
    );
}

def Quantum_ResetOp : Memory_Op<
  "reset",
  [
    MemoryEffects<[
      MemRead,
      MemWrite
    ]>,
    InferRegisterRangesInterface,
    InferPhasePolynomialInterface,
    NoClone
  ]> {
    let summary = "Reset a quantum register.";
    let description = [{
    Reset qubits.

    Example:
    
    ```mlir
    %q0 = quantum.alloc : !quantum.qubit<5> 
    %quantum.reset (%q0) : !quantum.qubit<5> -> (!quantum.qubit<5>)
    ```
    }];

    let arguments = (ins
      Quantum_QubitType:$input
    );
    
    let results = (outs
      Quantum_QubitType:$result
    );
}

def Quantum_SplitOp : Memory_Op<
  "split",
  [
    MemoryEffects<[
      MemRead,
      MemWrite
    ]>,
    DeclareOpInterfaceMethods<
      InferRegisterRangesInterface, ["inferResultRanges"]
    >,
    DeclareOpInterfaceMethods<
      InferPhasePolynomialInterface, ["inferResultPolynomial"]
    >,
    NoClone
  ]> {
    let summary = "Split a qubit register into two sub-registers.";
    let description = [{
    Example: 

    ```mlir
    %q = quantum.alloc : !quantum.qubit<5>
    %q0, %q1 = quantum.split (%q) : (!quantum.qubit<5>) -> (!quantum.qubit<2>, !quantum.qubit<3>)
    ```
    }];

    let arguments = (ins Quantum_QubitType:$input);
    let results = (outs
      Variadic<Quantum_QubitType>:$result
    );
    let hasVerifier = 1;
}

def Quantum_MergeOp : Memory_Op<
  "merge",
  [
    MemoryEffects<[
      MemRead,
      MemWrite
    ]>,
    DeclareOpInterfaceMethods<
      InferRegisterRangesInterface, ["inferResultRanges"]
    >,
    NoClone
  ]> {
    let summary = "Combine qubit registers into a single one.";
    let description = [{
    Example:

    ```mlir
    %lhs = "quantum.alloc" () : () -> !quantum.qubit<3>
    %rhs = "quantum.alloc" () : () -> !quantum.qubit<2>
    %q = "quantum.merge" (%lhs, %rhs) : (!quantum.qubit<3>, !quantum.qubit<2>) -> (!quantum.qubit<5>)
    ```
    }];

    let arguments = (ins
        Variadic<Quantum_QubitType>:$input
    );

    let results = (outs Quantum_QubitType:$result);

    let hasVerifier = 1;
}

//===----------------------------------------------------------------------===//
// Quantum gate operations.
//===----------------------------------------------------------------------===//

class PrimitiveGate_Op<string mnemonic, list<Trait> traits = []> :
        Gate_Op<mnemonic, traits # [NoClone]>;

//===----------------------------------------------------------------------===//
// Single qubit gate operations.
//===----------------------------------------------------------------------===//

def Quantum_IdOp : PrimitiveGate_Op<
  "id",
  [
    Hermitian,
    AllTypesMatch<["input", "result"]>,
    InferRegisterRangesInterface,
    InferPhasePolynomialInterface
  ]> {
  let summary = "Identity gate operation";
  let description = [{
    Example:
    %q1 = "quantum.id" (%q0): !quantum.qubit<1> -> !quantum.qubit<1>
  }];

  let arguments = (ins Quantum_QubitType:$input);
  let results = (outs Quantum_QubitType:$result);         
}

def Quantum_HOp : PrimitiveGate_Op<
  "H",
  [
    Hermitian,
    NoMemoryEffect,
    AllTypesMatch<["input", "result"]>,
    InferRegisterRangesInterface,
    DeclareOpInterfaceMethods<
      InferPhasePolynomialInterface, ["inferResultPolynomial"]
    >
  ]> {
  let summary = "Hadamard gate operation";
  let description = [{
    Example:
    %q1 = "quantum.H" (%q0): !quantum.qubit<1> -> !quantum.qubit<1>
  }];

  let arguments = (ins Quantum_QubitType:$input);
  let results = (outs Quantum_QubitType:$result);
}

def Quantum_XOp : PrimitiveGate_Op<
  "X",
  [
    Hermitian,
    NoMemoryEffect,
    AllTypesMatch<["input", "result"]>,
    InferRegisterRangesInterface,
    InferPhasePolynomialInterface
  ]>{
  let summary = "X gate operation (NOT gate)";
  let description = [{%out = "quantum.X"(%qubit) : !quantum.qubit<1> -> !quantum.qubit<1>}]; 
  let arguments = (ins Quantum_QubitType:$input);
  let results = (outs Quantum_QubitType:$result);
}

def Quantum_YOp : PrimitiveGate_Op<
  "Y",
  [
    Hermitian,
    NoMemoryEffect,
    AllTypesMatch<["input", "result"]>,
    InferRegisterRangesInterface
  ]> {
  let summary = "Y gate operation (Pauli-Y gate)";
  let description = [{%out = "quantum.Y"(%qubit) : !quantum.qubit<1> -> !quantum.qubit<1>}];
  let arguments = (ins Quantum_QubitType:$input);
  let results = (outs Quantum_QubitType:$result);
}

def Quantum_ZOp : PrimitiveGate_Op<
  "Z",
  [
    Hermitian,
    NoMemoryEffect,
    AllTypesMatch<["input", "result"]>,
    InferRegisterRangesInterface
  ]> {
  let summary = "Z gate operation (Pauli-Z gate)";
  let description = [{%out = "quantum.Z"(%qubit) : !quantum.qubit<1> -> !quantum.qubit<1>}];
  let arguments = (ins Quantum_QubitType:$input);
  let results = (outs Quantum_QubitType:$result);
}

def Quantum_SOp : PrimitiveGate_Op<
  "S",
  [
    Unitary,
    AdjointTo<"SdgOp">,
    NoMemoryEffect,
    AllTypesMatch<["input", "result"]>,
    InferRegisterRangesInterface
  ]> {
  let summary = "S (phase) gate";
  let description = [{
    Example:
    %q1 = "quantum.S"(%q0): !quantum.qubit<1> -> !quantum.qubit<1>
  }];
  let arguments = (ins Quantum_QubitType:$input);
  let results = (outs Quantum_QubitType:$result);
}

def Quantum_SXOp : PrimitiveGate_Op<
  "SX",
  [
    Unitary,
    NoMemoryEffect,
    AllTypesMatch<["input", "result"]>,
    InferRegisterRangesInterface
  ]> {
  let summary = "SX (phase) gate";
  let description = [{
    Example:
    %q1 = "quantum.SX"(%q0): !quantum.qubit<1> -> !quantum.qubit<1>
  }];
  let arguments = (ins Quantum_QubitType:$input);
  let results = (outs Quantum_QubitType:$result);
  let hasCanonicalizeMethod = 1;
}

def Quantum_TOp : PrimitiveGate_Op<
  "T",
  [
    Unitary,
    AdjointTo<"TdgOp">,
    NoMemoryEffect,
    AllTypesMatch<["input", "result"]>,
    InferRegisterRangesInterface
  ]> {
  let summary = "T (pi/8) gate";
  let description = [{
    Example:
    %q1 = "quantum.T"(%q0): !quantum.qubit<1> -> !quantum.qubit<1>
  }];
  let arguments = (ins Quantum_QubitType:$input);
  let results = (outs Quantum_QubitType:$result);
}

def Quantum_SdgOp : PrimitiveGate_Op<
  "Sdg",
  [
    Unitary,
    AdjointTo<"SOp">,
    NoMemoryEffect,
    AllTypesMatch<["input", "result"]>,
    InferRegisterRangesInterface
  ]> {
  let summary = "S-dagger gate";
  let description = [{
    Example:
    %q1 = "quantum.Sdg"(%q0): !quantum.qubit<1> -> !quantum.qubit<1>
  }];
  let arguments = (ins Quantum_QubitType:$input);
  let results = (outs Quantum_QubitType:$result);
}

def Quantum_TdgOp : PrimitiveGate_Op<
  "Tdg",
  [
    Unitary,
    AdjointTo<"TOp">,
    NoMemoryEffect,
    AllTypesMatch<["input", "result"]>,
    InferRegisterRangesInterface
  ]> {
  let summary = "T-dagger gate";
  let description = [{
    Example:
    %q1 = "quantum.Tdg"(%q0): !quantum.qubit<1> -> !quantum.qubit<1>
  }];
  let arguments = (ins Quantum_QubitType:$input);
  let results = (outs Quantum_QubitType:$result);
}

//===----------------------------------------------------------------------===//
// Two qubit gate operations.
//===----------------------------------------------------------------------===//
def Quantum_CNOTOp : PrimitiveGate_Op<
  "CNOT",
  [
    Hermitian,
    NoMemoryEffect,
    AllTypesMatch<["input", "target", "control_out", "target_out"]>,
    InferRegisterRangesInterface,
    DeclareOpInterfaceMethods<
      InferPhasePolynomialInterface, ["inferResultPolynomial"]
    >
  ]> {
  let summary = "CNOT gate operation";
  let description = [{
    Example:
    ```mlir
    %qa1, %qb1 = "quantum.CNOT" (%qa0, %qb0) : (!quantum.qubit<1>, !quantum.qubit<1>) -> !quantum.qubit<1>, !quantum.qubit<1>
    ```
  }];

  let arguments = (ins
    Quantum_QubitType:$input,
    Quantum_QubitType:$target
  );
  let results = (outs
    Quantum_QubitType:$control_out,
    Quantum_QubitType:$target_out
  );
}

def Quantum_CZOp : PrimitiveGate_Op<
  "CZ",
  [
    Hermitian,
    NoMemoryEffect,
    AllTypesMatch<["control", "target", "control_out", "target_out"]>,
    InferRegisterRangesInterface
  ]> {
  let summary = "Controlled-Z gate";
  let description = [{
    Example:
    %q1, %q2 = "quantum.CZ"(%q0, %q1): (!quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>)
  }];
  let arguments = (ins Quantum_QubitType:$control, Quantum_QubitType:$target);
  let results = (outs Quantum_QubitType:$control_out, Quantum_QubitType:$target_out);
}

def Quantum_SWAPOp : PrimitiveGate_Op<
  "SWAP",
  [
    Hermitian,
    AllTypesMatch<[ "lhs", "rhs","result_lhs", "result_rhs"]>,
    InferRegisterRangesInterface,
    DeclareOpInterfaceMethods<
      InferPhasePolynomialInterface, ["inferResultPolynomial"]
    >
  ]> {
  let summary = "SWAP gate";
  let description = [{
    Swaps the states of two qubits.
  }];
  let arguments = (ins
    Quantum_QubitType:$lhs,
    Quantum_QubitType:$rhs
  );
  let results = (outs
    Quantum_QubitType:$result_lhs,
    Quantum_QubitType:$result_rhs
  );
}

//===----------------------------------------------------------------------===//
// Parametric single qubit gate operations.
//===----------------------------------------------------------------------===//
def Quantum_RxOp : PrimitiveGate_Op<
  "Rx",
  [
    Unitary,
    NoMemoryEffect,
    AllTypesMatch<["input", "result"]>,
    InferRegisterRangesInterface
  ]> {
  let summary = "x rotation gate operation";
  let description = [{
    Example:
    %theta = arith.constant 0.34 : f64
    %q1 = "quantum.Rx" (%q0, %theta): !quantum.qubit<1>, f64 -> !quantum.qubit<1>
  }];

  let arguments = (ins
    Quantum_QubitType:$input,
    F64:$theta
  );
  let results = (outs Quantum_QubitType:$result);
  let hasCanonicalizeMethod = 1;
}

def Quantum_RyOp : PrimitiveGate_Op<
  "Ry",
  [
    Unitary,
    NoMemoryEffect,
    AllTypesMatch<["input", "result"]>,
    InferRegisterRangesInterface
  ]> {
  let summary = "y rotation gate operation";
  let description = [{
    Example:
    %theta = arith.constant 0.34 : f64
    %q1 = "quantum.Ry" (%q0, %theta): !quantum.qubit<1>, f64 -> !quantum.qubit<1>
  }];

  let arguments = (ins
    Quantum_QubitType:$input,
    F64:$theta
  );
  let results = (outs Quantum_QubitType:$result);
  let hasCanonicalizeMethod = 1;
}

def Quantum_RzOp : PrimitiveGate_Op<
  "Rz",
  [
    Unitary,
    NoMemoryEffect,
    AllTypesMatch<["input", "result"]>,
    InferRegisterRangesInterface,
    InferPhasePolynomialInterface
  ]> {
  let summary = "z rotation gate operation";
  let description = [{
    Example:
    %theta = arith.constant 0.34 : f64
    %q1 = "quantum.Rz" (%q0, %theta): !quantum.qubit<1>, f64 -> !quantum.qubit<1>
  }];

  let arguments = (ins
    Quantum_QubitType:$input,
    F64:$theta
  );
  let results = (outs Quantum_QubitType:$result);
  let hasCanonicalizeMethod = 1;
}

def Quantum_PhaseOp : PrimitiveGate_Op<
  "P",
  [
    Hermitian,
    NoMemoryEffect,
    AllTypesMatch<["input", "result"]>,
    InferRegisterRangesInterface
  ]> {
  let summary = "Phase gate";
  let description = [{
    Example:
    %q1 = "quantum.P"(%q0, %theta): !quantum.qubit<1> -> !quantum.qubit<1>
  }];
  let arguments = (ins
    Quantum_QubitType:$input,
    F64:$theta
  );
  let results = (outs Quantum_QubitType:$result);
}

def Quantum_U3Op : PrimitiveGate_Op<
  "U3",
  [
    Unitary,
    NoMemoryEffect,
    AllTypesMatch<["input", "result"]>,
    InferRegisterRangesInterface
  ]> {
  let summary = "U3 universal single-qubit gate operation";
  let description = [{
    Example:
    %q1 = "quantum.U3"(%q0, %theta, %phi, %lambda) : (!quantum.qubit<1>, f64, f64, f64) -> !quantum.qubit<1>
  }];
  let arguments = (ins Quantum_QubitType:$input, F64:$theta, F64:$phi, F64:$lambda);
  let results = (outs Quantum_QubitType:$result);
}

def Quantum_U2Op : PrimitiveGate_Op<
  "U2",
  [
    Unitary,
    NoMemoryEffect,
    AllTypesMatch<["input", "result"]>,
    InferRegisterRangesInterface
  ]> {
  let summary = "U2 single-qubit gate operation";
  let description = [{
    Example:
    %q1 = "quantum.U2"(%q0, %phi, %lambda) : (!quantum.qubit<1>, f64, f64) -> !quantum.qubit<1>
  }];
  let arguments = (ins Quantum_QubitType:$input, F64:$phi, F64:$lambda);
  let results = (outs Quantum_QubitType:$result);
}

def Quantum_U1Op : PrimitiveGate_Op<
  "U1",
  [
    Unitary,
    NoMemoryEffect,
    AllTypesMatch<["input", "result"]>,
    InferRegisterRangesInterface
  ]> {
  let summary = "U1 phase gate operation";
  let description = [{
    Example:
    %q1 = "quantum.U1"(%q0, %lambda) : (!quantum.qubit<1>, f64) -> !quantum.qubit<1>
  }];
  let arguments = (ins Quantum_QubitType:$input, F64:$lambda);
  let results = (outs Quantum_QubitType:$result);
}

//===----------------------------------------------------------------------===//
// Controlled Parametric two qubit gate operations.
//===----------------------------------------------------------------------===//
def Quantum_CRzOp : PrimitiveGate_Op<
  "CRz",
  [
    Unitary,
    NoMemoryEffect,
    AllTypesMatch<["control", "target", "control_out", "target_out"]>,
    InferRegisterRangesInterface
  ]> {
  let summary = "Controlled-Rz gate operation";
  let description = [{
    Example:
    %q1, %q2 = "quantum.CRz"(%q0, %q1, %angle) : (!quantum.qubit<1>, !quantum.qubit<1>, f64) -> (!quantum.qubit<1>, !quantum.qubit<1>)
  }];
  let arguments = (ins Quantum_QubitType:$control, Quantum_QubitType:$target, F64:$angle);
  let results = (outs Quantum_QubitType:$control_out, Quantum_QubitType:$target_out);
  let hasCanonicalizeMethod = 1;
}

def Quantum_CRyOp : PrimitiveGate_Op<
  "CRy",
  [
    Unitary,
    NoMemoryEffect,
    AllTypesMatch<["control", "target", "control_out", "target_out"]>,
    InferRegisterRangesInterface
  ]> {
  let summary = "Controlled-Ry gate operation";
  let description = [{
    Example:
    %q1, %q2 = "quantum.CRy"(%q0, %q1, %angle) : (!quantum.qubit<1>, !quantum.qubit<1>, f64) -> (!quantum.qubit<1>, !quantum.qubit<1>)
  }];
  let arguments = (ins Quantum_QubitType:$control, Quantum_QubitType:$target, F64:$angle);
  let results = (outs Quantum_QubitType:$control_out, Quantum_QubitType:$target_out);
  let hasCanonicalizeMethod = 1;
}

def Quantum_CU1Op : PrimitiveGate_Op<
  "CU1",
  [
    Unitary,
    NoMemoryEffect,
    AllTypesMatch<["control", "target", "control_out", "target_out"]>,
    InferRegisterRangesInterface
  ]> {
  let summary = "Controlled-U1 gate operation";
  let description = [{
    Example:
    %q1, %q2 = "quantum.CU1"(%q0, %q1, %angle) : (!quantum.qubit<1>, !quantum.qubit<1>, f64) -> (!quantum.qubit<1>, !quantum.qubit<1>)
  }];
  let arguments = (ins Quantum_QubitType:$control, Quantum_QubitType:$target, F64:$angle);
  let results = (outs Quantum_QubitType:$control_out, Quantum_QubitType:$target_out);
}

//===----------------------------------------------------------------------===//
// Multiqubit/Universal/Custom gate operations.
//===----------------------------------------------------------------------===//
def Quantum_CCXOp : PrimitiveGate_Op<
  "CCX",
  [
    Hermitian,
    NoMemoryEffect,
    AllTypesMatch<["control1", "control2", "target", "control1_out", "control2_out", "target_out"]>,
    InferRegisterRangesInterface
  ]> {
  let summary = "Toffoli (CCX) gate";
  let description = [{
    Example:
    %q1, %q2, %q3 = "quantum.CCX"(%q0, %q1, %q2): (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>)
  }];
  let arguments = (ins Quantum_QubitType:$control1, Quantum_QubitType:$control2, Quantum_QubitType:$target);
  let results = (outs Quantum_QubitType:$control1_out, Quantum_QubitType:$control2_out, Quantum_QubitType:$target_out);
}

def Quantum_CSWAPOp : PrimitiveGate_Op<
  "CSWAP",
  [
    Hermitian,
    AllTypesMatch<["control", "control_out", "lhs", "rhs", "lhs_out", "rhs_out"]>,
    InferRegisterRangesInterface
  ]> {
  let summary = "Controlled-SWAP gate";
  let description = [{
    Controlled swap of the states of two qubits.
  }];
  let arguments = (ins
    Quantum_QubitType:$control,    
    Quantum_QubitType:$lhs,
    Quantum_QubitType:$rhs
  );
  let results = (outs
    Quantum_QubitType:$control_out,
    Quantum_QubitType:$lhs_out,
    Quantum_QubitType:$rhs_out
  );
}

def Quantum_BarrierOp : PrimitiveGate_Op<
  "barrier",
  [
    AllTypesMatch<["input", "result"]>,
    InferRegisterRangesInterface,
    DeclareOpInterfaceMethods<
      InferPhasePolynomialInterface, ["inferResultPolynomial"]
    >
  ]> {
  let summary = "Barrier operation";
  let description = [{
    Barrier operation acting as a synchronization point without modifying qubits.
  }];

  let arguments = (ins Variadic<Quantum_QubitType>:$input);
  let results = (outs Variadic<Quantum_QubitType>:$result);
}

//===----------------------------------------------------------------------===//
// Measurement related gate operations.
//===----------------------------------------------------------------------===//

def Quantum_MeasureOp : Memory_Op<
  "measure",
  [
    MemoryEffects<[MemRead]>,
    AllTypesMatch<["input", "result"]>,
    DeclareOpInterfaceMethods<
      InferRegisterRangesInterface, ["inferResultRanges"]
    >,
    NoClone
  ]> {
    let summary = "Measure a qubit register of size N.";
    let description = [{
      %q0 = quantum.allocate : !quantum.qubit<2>
      %m, %qm = quantum.measure (%q0) : !quantum.qubit<2> -> (!quantum.measurement<2>, !quantum.qubit<2>)
    }];

    let arguments = (ins Quantum_QubitType:$input);
    let results = (outs
      Quantum_MeasurementType:$measurement,
      Quantum_QubitType:$result
    );
}

#endif // QUANTUM_OPS
