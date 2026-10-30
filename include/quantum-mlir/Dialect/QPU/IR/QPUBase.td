//===- Base.td - QPU dialect base --------------------------*- tablegen -*-===//
//
// This is the definitions file for the QPU dialect base.
//
//===----------------------------------------------------------------------===//

#ifndef QPU_BASE
#define QPU_BASE

include "mlir/IR/BuiltinAttributes.td"
include "mlir/IR/BuiltinTypes.td"
include "mlir/IR/AttrTypeBase.td"
include "mlir/IR/OpBase.td"
include "mlir/IR/EnumAttr.td"

def QPU_Dialect : Dialect {
    let name = "qpu";
    let cppNamespace = "::mlir::qpu";

    let summary = "Quantum Processing Unit Dialect";
    let description = [{
        A device-aware dialect that abstracts over the concrete device
        family. Only high-level device information required for 
        code transformation is captured.
    }];

    let hasOperationAttrVerify = 1;    
    let useDefaultAttributePrinterParser = 1;
    //let useDefaultTypePrinterParser = 1;


    code extraClassDeclaration = [{
    private:
        void registerOps();
        void registerTypes();
        void registerAttributes();
    }];
}

// Template for Types
class QPU_Type<string name, list<Trait> traits = []>
    : TypeDef<QPU_Dialect, name, traits> {
}

// Template for Ops
class QPU_Op<string mnemonic, list<Trait> traits = []>
        : Op<QPU_Dialect, mnemonic, traits>;

// Template for Attributes
class QPU_Attr<string attrName, string attrMnemonic, list<Trait> traits = []>
    : AttrDef<QPU_Dialect, attrName, traits> {
  let mnemonic = attrMnemonic;
}

#endif // QPU_BASE
