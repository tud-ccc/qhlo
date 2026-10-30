//===- Ops.td - QPU dialect ops ----------------------*- tablegen -*-===//
//
// This is the definitions file for the QPU dialect ops.
//
//===----------------------------------------------------------------------===//

#ifndef QPU_OPS
#define QPU_OPS

include "quantum-mlir/Dialect/QPU/IR/QPUTypes.td"
include "mlir/Interfaces/CastInterfaces.td"
include "mlir/Interfaces/ControlFlowInterfaces.td"
include "mlir/IR/SymbolInterfaces.td"
include "mlir/IR/RegionKindInterface.td"
include "mlir/IR/OpAsmInterface.td"
include "mlir/Interfaces/CallInterfaces.td"
include "mlir/Interfaces/FunctionInterfaces.td"
include "mlir/Interfaces/InferTypeOpInterface.td"
include "mlir/Interfaces/SideEffectInterfaces.td"
include "mlir/Interfaces/DestinationStyleOpInterface.td"

//===----------------------------------------------------------------------===//
// QPU Op templates
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
// QPU dialect traits.
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
// QPU operations.
//===----------------------------------------------------------------------===//

def QPU_QPUModuleOp : QPU_Op<"module", [
    IsolatedFromAbove,
    NoRegionArguments,
    SymbolTable,
    Symbol
  ]
  # GraphRegionNoTerminator.traits> {
  let summary = "Top level compilation unit containing code to be run on a QPU.";
  let description = [{
  
  }];
  let arguments = (ins
    SymbolNameAttr:$sym_name,
    OptionalAttr<QPU_NonEmptyTargetArrayAttr>:$targets
  );
  let regions = (region SizedRegion<1>:$bodyRegion);
  let assemblyFormat = [{
    $sym_name
    ($targets^)?
    attr-dict-with-keyword $bodyRegion
  }];
}

def QPU_CircuitOp : QPU_Op<"circuit", [
    IsolatedFromAbove,
    HasParent<"QPUModuleOp">,
    FunctionOpInterface
  ]> {
  let summary = "Quantum circuit operation with coupling graph";
  let description = [{ A quantum circuit operation that operates on a device with a specified coupling graph. }];
  let arguments = (ins
    SymbolNameAttr:$sym_name,
    OptionalAttr<DictArrayAttr>:$arg_attrs,
    OptionalAttr<DictArrayAttr>:$res_attrs,
    TypeAttrOf<FunctionType>:$function_type
  );
  let regions = (region AnyRegion:$body);
  let builders = [OpBuilder<(ins
    "StringRef":$sym_name,
    "FunctionType":$type,
    CArg<"ArrayRef<NamedAttribute>", "{}">:$attrs,
    CArg<"ArrayRef<DictionaryAttr>", "{}">:$argAttrs)
  >];

  let extraClassDeclaration = [{
    static CircuitOp create(Location location, StringRef name,
                         FunctionType type, ArrayRef<NamedAttribute> attrs = {});

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
  }];
}

def QPU_ExecuteOp : QPU_Op<"execute", [
    AttrSizedOperandSegments,
    DestinationStyleOpInterface,
    RangedTypesMatchWith<
      "result types match output types",
      "output", "result", "$_self"
    >
  ]> {
  let summary = "Executed a quantum circuit.";
  let description = [{
    Execute a quantum circuit. If the circuit has free parameters
    these must be provided to the execute operation.
  }];
  let arguments = (ins
    SymbolRefAttr:$circuit,
    Variadic<AnyType>:$input,
    Variadic<AnyTensor>:$output
  );
  let results = (outs
    Variadic<AnyTensor>:$result
  );  
  let assemblyFormat = [{
    $circuit
    `ins` custom<ExecuteOperandList>($input, type($input))
    `outs` custom<ExecuteOperandList>($output, type($output))
    attr-dict
  }];

  let extraClassDeclaration = [{
    MutableOperandRange getDpsInitsMutable() {
      return getOutputMutable();
    }
  }];
}

def QPU_ReturnOp : QPU_Op<"return", [
  Pure,
  HasParent<"CircuitOp">,
  ReturnLike,
  Terminator]> {
  let summary = "Quantum circuit return operation";
  let description = [{
    The `qpu.return` operation represents a return operation within a
    circuit body.
    The operation takes variable number of operands and produces no results.
    The operand number and types must match the signature of the circuit's
    function type that contains the operation.
    ```
  }];

  let arguments = (ins Variadic<AnyType>:$operands);

  let builders = [OpBuilder<(ins), [{
    build($_builder, $_state, ::mlir::ValueRange{});
  }]>];

  //let hasVerifier = 1;
}

def QPU_ToBitsOp : QPU_Op<"to_bits", [
  DeclareOpInterfaceMethods<MemoryEffectsOpInterface>
  ]> {
  let summary = "Read a measurement source as a bit sequence";
  let description = [{
    Materializes measurement bits from a source implementing
    MeasurementSourceInterface. A tensor result is an immutable snapshot.
    A memref result owns newly allocated storage initialized with those bits.
    Reading a mutable source has a memory read effect on that source.
  }];
  let arguments = (ins QPU_MeasurementSource:$src);
  let results = (outs QPU_BitSequence:$dst);
}

def QPU_BitsEqOp : QPU_Op<"bits_eq", [
  DeclareOpInterfaceMethods<MemoryEffectsOpInterface>
  ]> {
  let summary = "Compare a bit sequence with an unsigned integer";
  let description = [{
    Compares the unsigned value represented by bits with cmp.
    Element i has weight 2^i. The sequence must have a static
    length equal to the bit width of cmp.
  }];
  let arguments = (ins
    QPU_BitSequence:$bits,
    AnyInteger:$cmp
  );
  let results = (outs I1:$dst);
  let hasVerifier = 1;
}

#endif // QPU_OPS
