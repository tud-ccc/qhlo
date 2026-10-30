// RUN: quantum-opt %s \
// RUN:   --pass-pipeline="builtin.module( \
// RUN:       convert-quantum-to-qillr, \
// RUN:       func.func(convert-scf-to-cf), \
// RUN:       convert-qillr-to-llvm, \
// RUN:       convert-func-to-llvm, \
// RUN:       convert-cf-to-llvm, \
// RUN:       convert-vector-to-llvm, \
// RUN:       one-shot-bufferize{allow-unknown-ops}, \
// RUN:       finalize-memref-to-llvm, \
// RUN:       convert-index-to-llvm, \
// RUN:       convert-arith-to-llvm, \
// RUN:       reconcile-unrealized-casts)" | \
// RUN: mlir-runner -e entry -entry-point-result=void \
// RUN:     --shared-libs=%qir_shlibs,%mlir_c_runner_utils | \
// RUN: FileCheck %s --match-full-lines

module {
//QASMbench dnn small example code converted to qillr dialect. 
 func.func @dnn_qasm_bench() {
    %0 = arith.constant 1.100000 : f64
    %1 = "qillr.alloc" () : () -> (!qillr.qubit)
    "qillr.Rx" (%1, %0) : (!qillr.qubit, f64) -> ()
    %2 = arith.constant 1.100000 : f64
    "qillr.Ry" (%1, %2) : (!qillr.qubit, f64) -> ()
    %3 = arith.constant 1.100000 : f64
    "qillr.Rz" (%1, %3) : (!qillr.qubit, f64) -> ()
    %4 = arith.constant 1.100000 : f64
    %5 = "qillr.alloc" () : () -> (!qillr.qubit)
    "qillr.Rx" (%5, %4) : (!qillr.qubit, f64) -> ()
    %6 = arith.constant 1.100000 : f64
    "qillr.Ry" (%5, %6) : (!qillr.qubit, f64) -> ()
    %7 = arith.constant 1.100000 : f64
    "qillr.Rz" (%5, %7) : (!qillr.qubit, f64) -> ()
    %8 = arith.constant 3.455752 : f64
    "qillr.Rz" (%1, %8) : (!qillr.qubit, f64) -> ()
    %9 = arith.constant 3.455752 : f64
    "qillr.Rz" (%5, %9) : (!qillr.qubit, f64) -> ()
    %10 = arith.constant 0.000000 : f64
    %11 = arith.constant 1.570796 : f64
    %12 = arith.constant 0.785398 : f64
    "qillr.U3" (%1, %11, %10, %12) : (!qillr.qubit, f64, f64, f64) -> ()
    %13 = arith.constant 3.141593 : f64
    %14 = arith.constant 1.570796 : f64
    %15 = arith.constant 2.356194 : f64
    "qillr.U3" (%5, %14, %13, %15) : (!qillr.qubit, f64, f64, f64) -> ()
    %16 = arith.constant 1.570796 : f64
    "qillr.Rx" (%1, %16) : (!qillr.qubit, f64) -> ()
    "qillr.CNOT" (%1, %5) : (!qillr.qubit, !qillr.qubit) -> ()
    %17 = arith.constant 1.256637 : f64
    "qillr.Rx" (%1, %17) : (!qillr.qubit, f64) -> ()
    %18 = arith.constant 1.570796 : f64
    "qillr.Ry" (%5, %18) : (!qillr.qubit, f64) -> ()
    "qillr.CNOT" (%5, %1) : (!qillr.qubit, !qillr.qubit) -> ()
    %19 = arith.constant -1.570796 : f64
    "qillr.Rx" (%5, %19) : (!qillr.qubit, f64) -> ()
    %20 = arith.constant 1.570796 : f64
    "qillr.Rz" (%5, %20) : (!qillr.qubit, f64) -> ()
    "qillr.CNOT" (%1, %5) : (!qillr.qubit, !qillr.qubit) -> ()
    %21 = arith.constant 2.042035 : f64
    %22 = arith.constant 1.570796 : f64
    %23 = arith.constant 3.141593 : f64
    "qillr.U3" (%1, %22, %21, %23) : (!qillr.qubit, f64, f64, f64) -> ()
    %24 = arith.constant 0.471239 : f64
    %25 = arith.constant 1.570796 : f64
    %26 = arith.constant 0.000000 : f64
    "qillr.U3" (%5, %25, %24, %26) : (!qillr.qubit, f64, f64, f64) -> ()
    %27 = arith.constant 3.141593 : f64
    %28 = arith.constant 0.000000 : f64
    %29 = arith.constant 1.570796 : f64
    "qillr.U3" (%1, %28, %27, %29) : (!qillr.qubit, f64, f64, f64) -> ()
    %30 = arith.constant 0.000000 : f64
    %31 = arith.constant 0.000000 : f64
    %32 = arith.constant 1.570796 : f64
    "qillr.U3" (%5, %31, %30, %32) : (!qillr.qubit, f64, f64, f64) -> ()
    %33 = arith.constant 1.570796 : f64
    "qillr.Rx" (%1, %33) : (!qillr.qubit, f64) -> ()
    "qillr.CNOT" (%1, %5) : (!qillr.qubit, !qillr.qubit) -> ()
    %34 = arith.constant 1.256637 : f64
    "qillr.Rx" (%1, %34) : (!qillr.qubit, f64) -> ()
    %35 = arith.constant 1.570796 : f64
    "qillr.Ry" (%5, %35) : (!qillr.qubit, f64) -> ()
    "qillr.CNOT" (%5, %1) : (!qillr.qubit, !qillr.qubit) -> ()
    %36 = arith.constant -1.570796 : f64
    "qillr.Rx" (%5, %36) : (!qillr.qubit, f64) -> ()
    %37 = arith.constant 1.570796 : f64
    "qillr.Rz" (%5, %37) : (!qillr.qubit, f64) -> ()
    "qillr.CNOT" (%1, %5) : (!qillr.qubit, !qillr.qubit) -> ()
    %38 = arith.constant 0.000000 : f64
    %39 = arith.constant 3.141593 : f64
    %40 = arith.constant 1.570796 : f64
    "qillr.U3" (%1, %39, %38, %40) : (!qillr.qubit, f64, f64, f64) -> ()
    %41 = arith.constant 0.000000 : f64
    %42 = arith.constant 3.141593 : f64
    %43 = arith.constant 4.712389 : f64
    "qillr.U3" (%5, %42, %41, %43) : (!qillr.qubit, f64, f64, f64) -> ()
    %44 = arith.constant 4.712389 : f64
    %45 = arith.constant 1.570796 : f64
    %46 = arith.constant 4.712389 : f64
    "qillr.U3" (%1, %45, %44, %46) : (!qillr.qubit, f64, f64, f64) -> ()
    %47 = arith.constant 1.570796 : f64
    %48 = arith.constant 1.570796 : f64
    %49 = arith.constant 4.712389 : f64
    "qillr.U3" (%5, %48, %47, %49) : (!qillr.qubit, f64, f64, f64) -> ()
    %50 = arith.constant 1.570796 : f64
    "qillr.Rx" (%1, %50) : (!qillr.qubit, f64) -> ()
    "qillr.CNOT" (%1, %5) : (!qillr.qubit, !qillr.qubit) -> ()
    %51 = arith.constant 1.256637 : f64
    "qillr.Rx" (%1, %51) : (!qillr.qubit, f64) -> ()
    %52 = arith.constant 1.570796 : f64
    "qillr.Ry" (%5, %52) : (!qillr.qubit, f64) -> ()
    "qillr.CNOT" (%5, %1) : (!qillr.qubit, !qillr.qubit) -> ()
    %53 = arith.constant -1.570796 : f64
    "qillr.Rx" (%5, %53) : (!qillr.qubit, f64) -> ()
    %54 = arith.constant 1.570796 : f64
    "qillr.Rz" (%5, %54) : (!qillr.qubit, f64) -> ()
    "qillr.CNOT" (%1, %5) : (!qillr.qubit, !qillr.qubit) -> ()
    %55 = arith.constant 1.570796 : f64
    %56 = arith.constant 1.570796 : f64
    %57 = arith.constant 1.570796 : f64
    "qillr.U3" (%1, %56, %55, %57) : (!qillr.qubit, f64, f64, f64) -> ()
    %58 = arith.constant 1.570796 : f64
    %59 = arith.constant 1.570796 : f64
    %60 = arith.constant 4.712389 : f64
    "qillr.U3" (%5, %59, %58, %60) : (!qillr.qubit, f64, f64, f64) -> ()
    %61 = arith.constant 1.100000 : f64
    "qillr.Rx" (%1, %61) : (!qillr.qubit, f64) -> ()
    %62 = arith.constant 1.100000 : f64
    "qillr.Ry" (%1, %62) : (!qillr.qubit, f64) -> ()
    %63 = arith.constant 1.100000 : f64
    "qillr.Rz" (%1, %63) : (!qillr.qubit, f64) -> ()
    %64 = arith.constant 1.100000 : f64
    "qillr.Rx" (%5, %64) : (!qillr.qubit, f64) -> ()
    %65 = arith.constant 1.100000 : f64
    "qillr.Ry" (%5, %65) : (!qillr.qubit, f64) -> ()
    %66 = arith.constant 1.100000 : f64
    "qillr.Rz" (%5, %66) : (!qillr.qubit, f64) -> ()
    %67 = arith.constant 1.100000 : f64
    "qillr.Rx" (%5, %67) : (!qillr.qubit, f64) -> ()
    %68 = arith.constant 1.100000 : f64
    "qillr.Ry" (%5, %68) : (!qillr.qubit, f64) -> ()
    %69 = arith.constant 1.100000 : f64
    "qillr.Rz" (%5, %69) : (!qillr.qubit, f64) -> ()
    %70 = arith.constant 1.100000 : f64
    "qillr.Rx" (%1, %70) : (!qillr.qubit, f64) -> ()
    %71 = arith.constant 1.100000 : f64
    "qillr.Ry" (%1, %71) : (!qillr.qubit, f64) -> ()
    %72 = arith.constant 1.100000 : f64
    "qillr.Rz" (%1, %72) : (!qillr.qubit, f64) -> ()
    %73 = arith.constant 3.455752 : f64
    "qillr.Rz" (%5, %73) : (!qillr.qubit, f64) -> ()
    %74 = arith.constant 3.455752 : f64
    "qillr.Rz" (%1, %74) : (!qillr.qubit, f64) -> ()
    %75 = arith.constant 0.000000 : f64
    %76 = arith.constant 1.570796 : f64
    %77 = arith.constant 0.785398 : f64
    "qillr.U3" (%5, %76, %75, %77) : (!qillr.qubit, f64, f64, f64) -> ()
    %78 = arith.constant 3.141593 : f64
    %79 = arith.constant 1.570796 : f64
    %80 = arith.constant 2.356194 : f64
    "qillr.U3" (%1, %79, %78, %80) : (!qillr.qubit, f64, f64, f64) -> ()
    %81 = arith.constant 1.570796 : f64
    "qillr.Rx" (%5, %81) : (!qillr.qubit, f64) -> ()
    "qillr.CNOT" (%5, %1) : (!qillr.qubit, !qillr.qubit) -> ()
    %82 = arith.constant 1.256637 : f64
    "qillr.Rx" (%5, %82) : (!qillr.qubit, f64) -> ()
    %83 = arith.constant 1.570796 : f64
    "qillr.Ry" (%1, %83) : (!qillr.qubit, f64) -> ()
    "qillr.CNOT" (%1, %5) : (!qillr.qubit, !qillr.qubit) -> ()
    %84 = arith.constant -1.570796 : f64
    "qillr.Rx" (%1, %84) : (!qillr.qubit, f64) -> ()
    %85 = arith.constant 1.570796 : f64
    "qillr.Rz" (%1, %85) : (!qillr.qubit, f64) -> ()
    "qillr.CNOT" (%5, %1) : (!qillr.qubit, !qillr.qubit) -> ()
    %86 = arith.constant 2.042035 : f64
    %87 = arith.constant 1.570796 : f64
    %88 = arith.constant 3.141593 : f64
    "qillr.U3" (%5, %87, %86, %88) : (!qillr.qubit, f64, f64, f64) -> ()
    %89 = arith.constant 0.471239 : f64
    %90 = arith.constant 1.570796 : f64
    %91 = arith.constant 0.000000 : f64
    "qillr.U3" (%1, %90, %89, %91) : (!qillr.qubit, f64, f64, f64) -> ()
    %92 = arith.constant 3.141593 : f64
    %93 = arith.constant 0.000000 : f64
    %94 = arith.constant 1.570796 : f64
    "qillr.U3" (%5, %93, %92, %94) : (!qillr.qubit, f64, f64, f64) -> ()
    %95 = arith.constant 0.000000 : f64
    %96 = arith.constant 0.000000 : f64
    %97 = arith.constant 1.570796 : f64
    "qillr.U3" (%1, %96, %95, %97) : (!qillr.qubit, f64, f64, f64) -> ()
    %98 = arith.constant 1.570796 : f64
    "qillr.Rx" (%5, %98) : (!qillr.qubit, f64) -> ()
    "qillr.CNOT" (%5, %1) : (!qillr.qubit, !qillr.qubit) -> ()
    %99 = arith.constant 1.256637 : f64
    "qillr.Rx" (%5, %99) : (!qillr.qubit, f64) -> ()
    %100 = arith.constant 1.570796 : f64
    "qillr.Ry" (%1, %100) : (!qillr.qubit, f64) -> ()
    "qillr.CNOT" (%1, %5) : (!qillr.qubit, !qillr.qubit) -> ()
    %101 = arith.constant -1.570796 : f64
    "qillr.Rx" (%1, %101) : (!qillr.qubit, f64) -> ()
    %102 = arith.constant 1.570796 : f64
    "qillr.Rz" (%1, %102) : (!qillr.qubit, f64) -> ()
    "qillr.CNOT" (%5, %1) : (!qillr.qubit, !qillr.qubit) -> ()
    %103 = arith.constant 0.000000 : f64
    %104 = arith.constant 3.141593 : f64
    %105 = arith.constant 1.570796 : f64
    "qillr.U3" (%5, %104, %103, %105) : (!qillr.qubit, f64, f64, f64) -> ()
    %106 = arith.constant 0.000000 : f64
    %107 = arith.constant 3.141593 : f64
    %108 = arith.constant 4.712389 : f64
    "qillr.U3" (%1, %107, %106, %108) : (!qillr.qubit, f64, f64, f64) -> ()
    %109 = arith.constant 4.712389 : f64
    %110 = arith.constant 1.570796 : f64
    %111 = arith.constant 4.712389 : f64
    "qillr.U3" (%5, %110, %109, %111) : (!qillr.qubit, f64, f64, f64) -> ()
    %112 = arith.constant 1.570796 : f64
    %113 = arith.constant 1.570796 : f64
    %114 = arith.constant 4.712389 : f64
    "qillr.U3" (%1, %113, %112, %114) : (!qillr.qubit, f64, f64, f64) -> ()
    %115 = arith.constant 1.570796 : f64
    "qillr.Rx" (%5, %115) : (!qillr.qubit, f64) -> ()
    "qillr.CNOT" (%5, %1) : (!qillr.qubit, !qillr.qubit) -> ()
    %116 = arith.constant 1.256637 : f64
    "qillr.Rx" (%5, %116) : (!qillr.qubit, f64) -> ()
    %117 = arith.constant 1.570796 : f64
    "qillr.Ry" (%1, %117) : (!qillr.qubit, f64) -> ()
    "qillr.CNOT" (%1, %5) : (!qillr.qubit, !qillr.qubit) -> ()
    %118 = arith.constant -1.570796 : f64
    "qillr.Rx" (%1, %118) : (!qillr.qubit, f64) -> ()
    %119 = arith.constant 1.570796 : f64
    "qillr.Rz" (%1, %119) : (!qillr.qubit, f64) -> ()
    "qillr.CNOT" (%5, %1) : (!qillr.qubit, !qillr.qubit) -> ()
    %120 = arith.constant 1.570796 : f64
    %121 = arith.constant 1.570796 : f64
    %122 = arith.constant 1.570796 : f64
    "qillr.U3" (%5, %121, %120, %122) : (!qillr.qubit, f64, f64, f64) -> ()
    %123 = arith.constant 1.570796 : f64
    %124 = arith.constant 1.570796 : f64
    %125 = arith.constant 4.712389 : f64
    "qillr.U3" (%1, %124, %123, %125) : (!qillr.qubit, f64, f64, f64) -> ()
    %126 = arith.constant 1.100000 : f64
    "qillr.Rx" (%5, %126) : (!qillr.qubit, f64) -> ()
    %127 = arith.constant 1.100000 : f64
    "qillr.Ry" (%5, %127) : (!qillr.qubit, f64) -> ()
    %128 = arith.constant 1.100000 : f64
    "qillr.Rz" (%5, %128) : (!qillr.qubit, f64) -> ()
    %129 = arith.constant 1.100000 : f64
    "qillr.Rx" (%1, %129) : (!qillr.qubit, f64) -> ()
    %130 = arith.constant 1.100000 : f64
    "qillr.Ry" (%1, %130) : (!qillr.qubit, f64) -> ()
    %131 = arith.constant 1.100000 : f64
    "qillr.Rz" (%1, %131) : (!qillr.qubit, f64) -> ()
    %132 = arith.constant -1.570796 : f64
    "qillr.Ry" (%5, %132) : (!qillr.qubit, f64) -> ()
    %133 = arith.constant 0.000000 : f64
    %134 = arith.constant 1.570796 : f64
    %135 = arith.constant 0.785398 : f64
    "qillr.U3" (%1, %134, %133, %135) : (!qillr.qubit, f64, f64, f64) -> ()
    %136 = arith.constant 3.141593 : f64
    %137 = arith.constant 1.570796 : f64
    %138 = arith.constant 2.356194 : f64
    "qillr.U3" (%5, %137, %136, %138) : (!qillr.qubit, f64, f64, f64) -> ()
    %139 = arith.constant 1.570796 : f64
    "qillr.Rx" (%1, %139) : (!qillr.qubit, f64) -> ()
    "qillr.CNOT" (%1, %5) : (!qillr.qubit, !qillr.qubit) -> ()
    %140 = arith.constant 0.157080 : f64
    "qillr.Rx" (%1, %140) : (!qillr.qubit, f64) -> ()
    %141 = arith.constant 1.570796 : f64
    "qillr.Ry" (%5, %141) : (!qillr.qubit, f64) -> ()
    "qillr.CNOT" (%5, %1) : (!qillr.qubit, !qillr.qubit) -> ()
    %142 = arith.constant -1.570796 : f64
    "qillr.Rx" (%5, %142) : (!qillr.qubit, f64) -> ()
    %143 = arith.constant 1.570796 : f64
    "qillr.Rz" (%5, %143) : (!qillr.qubit, f64) -> ()
    "qillr.CNOT" (%1, %5) : (!qillr.qubit, !qillr.qubit) -> ()
    %144 = arith.constant 0.942478 : f64
    %145 = arith.constant 1.570796 : f64
    %146 = arith.constant 3.141593 : f64
    "qillr.U3" (%1, %145, %144, %146) : (!qillr.qubit, f64, f64, f64) -> ()
    %147 = arith.constant 5.654867 : f64
    %148 = arith.constant 1.570796 : f64
    %149 = arith.constant 0.000000 : f64
    "qillr.U3" (%5, %148, %147, %149) : (!qillr.qubit, f64, f64, f64) -> ()
    %150 = arith.constant 1.570796 : f64
    "qillr.Ry" (%5, %150) : (!qillr.qubit, f64) -> ()
    %151 = arith.constant 0.000000 : f64
    %152 = arith.constant 1.570796 : f64
    %153 = arith.constant 0.785398 : f64
    "qillr.U3" (%1, %152, %151, %153) : (!qillr.qubit, f64, f64, f64) -> ()
    %154 = arith.constant 3.141593 : f64
    %155 = arith.constant 1.570796 : f64
    %156 = arith.constant 2.356194 : f64
    "qillr.U3" (%5, %155, %154, %156) : (!qillr.qubit, f64, f64, f64) -> ()
    %157 = arith.constant 1.570796 : f64
    "qillr.Rx" (%1, %157) : (!qillr.qubit, f64) -> ()
    "qillr.CNOT" (%1, %5) : (!qillr.qubit, !qillr.qubit) -> ()
    %158 = arith.constant 0.157080 : f64
    "qillr.Rx" (%1, %158) : (!qillr.qubit, f64) -> ()
    %159 = arith.constant 1.570796 : f64
    "qillr.Ry" (%5, %159) : (!qillr.qubit, f64) -> ()
    "qillr.CNOT" (%5, %1) : (!qillr.qubit, !qillr.qubit) -> ()
    %160 = arith.constant -1.570796 : f64
    "qillr.Rx" (%5, %160) : (!qillr.qubit, f64) -> ()
    %161 = arith.constant 1.570796 : f64
    "qillr.Rz" (%5, %161) : (!qillr.qubit, f64) -> ()
    "qillr.CNOT" (%1, %5) : (!qillr.qubit, !qillr.qubit) -> ()
    %162 = arith.constant 0.942478 : f64
    %163 = arith.constant 1.570796 : f64
    %164 = arith.constant 3.141593 : f64
    "qillr.U3" (%1, %163, %162, %164) : (!qillr.qubit, f64, f64, f64) -> ()
    %165 = arith.constant 5.654867 : f64
    %166 = arith.constant 1.570796 : f64
    %167 = arith.constant 0.000000 : f64
    "qillr.U3" (%5, %166, %165, %167) : (!qillr.qubit, f64, f64, f64) -> ()
    %168 = arith.constant 1.100000 : f64
    "qillr.Rx" (%1, %168) : (!qillr.qubit, f64) -> ()
    %169 = arith.constant 1.100000 : f64
    "qillr.Ry" (%1, %169) : (!qillr.qubit, f64) -> ()
    %170 = arith.constant 1.100000 : f64
    "qillr.Rz" (%1, %170) : (!qillr.qubit, f64) -> ()
    %171 = arith.constant 1.100000 : f64
    "qillr.Rx" (%5, %171) : (!qillr.qubit, f64) -> ()
    %172 = arith.constant 1.100000 : f64
    "qillr.Ry" (%5, %172) : (!qillr.qubit, f64) -> ()
    %173 = arith.constant 1.100000 : f64
    "qillr.Rz" (%5, %173) : (!qillr.qubit, f64) -> ()
    %174 = arith.constant 3.455752 : f64
    "qillr.Rz" (%1, %174) : (!qillr.qubit, f64) -> ()
    %175 = arith.constant 3.455752 : f64
    "qillr.Rz" (%5, %175) : (!qillr.qubit, f64) -> ()
    %176 = arith.constant 0.000000 : f64
    %177 = arith.constant 1.570796 : f64
    %178 = arith.constant 0.785398 : f64
    "qillr.U3" (%1, %177, %176, %178) : (!qillr.qubit, f64, f64, f64) -> ()
    %179 = arith.constant 3.141593 : f64
    %180 = arith.constant 1.570796 : f64
    %181 = arith.constant 2.356194 : f64
    "qillr.U3" (%5, %180, %179, %181) : (!qillr.qubit, f64, f64, f64) -> ()
    %182 = arith.constant 1.570796 : f64
    "qillr.Rx" (%1, %182) : (!qillr.qubit, f64) -> ()
    "qillr.CNOT" (%1, %5) : (!qillr.qubit, !qillr.qubit) -> ()
    %183 = arith.constant 1.256637 : f64
    "qillr.Rx" (%1, %183) : (!qillr.qubit, f64) -> ()
    %184 = arith.constant 1.570796 : f64
    "qillr.Ry" (%5, %184) : (!qillr.qubit, f64) -> ()
    "qillr.CNOT" (%5, %1) : (!qillr.qubit, !qillr.qubit) -> ()
    %185 = arith.constant -1.570796 : f64
    "qillr.Rx" (%5, %185) : (!qillr.qubit, f64) -> ()
    %186 = arith.constant 1.570796 : f64
    "qillr.Rz" (%5, %186) : (!qillr.qubit, f64) -> ()
    "qillr.CNOT" (%1, %5) : (!qillr.qubit, !qillr.qubit) -> ()
    %187 = arith.constant 2.042035 : f64
    %188 = arith.constant 1.570796 : f64
    %189 = arith.constant 3.141593 : f64
    "qillr.U3" (%1, %188, %187, %189) : (!qillr.qubit, f64, f64, f64) -> ()
    %190 = arith.constant 0.471239 : f64
    %191 = arith.constant 1.570796 : f64
    %192 = arith.constant 0.000000 : f64
    "qillr.U3" (%5, %191, %190, %192) : (!qillr.qubit, f64, f64, f64) -> ()
    %193 = arith.constant 3.141593 : f64
    %194 = arith.constant 0.000000 : f64
    %195 = arith.constant 1.570796 : f64
    "qillr.U3" (%1, %194, %193, %195) : (!qillr.qubit, f64, f64, f64) -> ()
    %196 = arith.constant 0.000000 : f64
    %197 = arith.constant 0.000000 : f64
    %198 = arith.constant 1.570796 : f64
    "qillr.U3" (%5, %197, %196, %198) : (!qillr.qubit, f64, f64, f64) -> ()
    %199 = arith.constant 1.570796 : f64
    "qillr.Rx" (%1, %199) : (!qillr.qubit, f64) -> ()
    "qillr.CNOT" (%1, %5) : (!qillr.qubit, !qillr.qubit) -> ()
    %200 = arith.constant 1.256637 : f64
    "qillr.Rx" (%1, %200) : (!qillr.qubit, f64) -> ()
    %201 = arith.constant 1.570796 : f64
    "qillr.Ry" (%5, %201) : (!qillr.qubit, f64) -> ()
    "qillr.CNOT" (%5, %1) : (!qillr.qubit, !qillr.qubit) -> ()
    %202 = arith.constant -1.570796 : f64
    "qillr.Rx" (%5, %202) : (!qillr.qubit, f64) -> ()
    %203 = arith.constant 1.570796 : f64
    "qillr.Rz" (%5, %203) : (!qillr.qubit, f64) -> ()
    "qillr.CNOT" (%1, %5) : (!qillr.qubit, !qillr.qubit) -> ()
    %204 = arith.constant 0.000000 : f64
    %205 = arith.constant 3.141593 : f64
    %206 = arith.constant 1.570796 : f64
    "qillr.U3" (%1, %205, %204, %206) : (!qillr.qubit, f64, f64, f64) -> ()
    %207 = arith.constant 0.000000 : f64
    %208 = arith.constant 3.141593 : f64
    %209 = arith.constant 4.712389 : f64
    "qillr.U3" (%5, %208, %207, %209) : (!qillr.qubit, f64, f64, f64) -> ()
    %210 = arith.constant 4.712389 : f64
    %211 = arith.constant 1.570796 : f64
    %212 = arith.constant 4.712389 : f64
    "qillr.U3" (%1, %211, %210, %212) : (!qillr.qubit, f64, f64, f64) -> ()
    %213 = arith.constant 1.570796 : f64
    %214 = arith.constant 1.570796 : f64
    %215 = arith.constant 4.712389 : f64
    "qillr.U3" (%5, %214, %213, %215) : (!qillr.qubit, f64, f64, f64) -> ()
    %216 = arith.constant 1.570796 : f64
    "qillr.Rx" (%1, %216) : (!qillr.qubit, f64) -> ()
    "qillr.CNOT" (%1, %5) : (!qillr.qubit, !qillr.qubit) -> ()
    %217 = arith.constant 1.256637 : f64
    "qillr.Rx" (%1, %217) : (!qillr.qubit, f64) -> ()
    %218 = arith.constant 1.570796 : f64
    "qillr.Ry" (%5, %218) : (!qillr.qubit, f64) -> ()
    "qillr.CNOT" (%5, %1) : (!qillr.qubit, !qillr.qubit) -> ()
    %219 = arith.constant -1.570796 : f64
    "qillr.Rx" (%5, %219) : (!qillr.qubit, f64) -> ()
    %220 = arith.constant 1.570796 : f64
    "qillr.Rz" (%5, %220) : (!qillr.qubit, f64) -> ()
    "qillr.CNOT" (%1, %5) : (!qillr.qubit, !qillr.qubit) -> ()
    %221 = arith.constant 1.570796 : f64
    %222 = arith.constant 1.570796 : f64
    %223 = arith.constant 1.570796 : f64
    "qillr.U3" (%1, %222, %221, %223) : (!qillr.qubit, f64, f64, f64) -> ()
    %224 = arith.constant 1.570796 : f64
    %225 = arith.constant 1.570796 : f64
    %226 = arith.constant 4.712389 : f64
    "qillr.U3" (%5, %225, %224, %226) : (!qillr.qubit, f64, f64, f64) -> ()
    %227 = arith.constant 1.100000 : f64
    "qillr.Rx" (%1, %227) : (!qillr.qubit, f64) -> ()
    %228 = arith.constant 1.100000 : f64
    "qillr.Ry" (%1, %228) : (!qillr.qubit, f64) -> ()
    %229 = arith.constant 1.100000 : f64
    "qillr.Rz" (%1, %229) : (!qillr.qubit, f64) -> ()
    %230 = arith.constant 1.100000 : f64
    "qillr.Rx" (%5, %230) : (!qillr.qubit, f64) -> ()
    %231 = arith.constant 1.100000 : f64
    "qillr.Ry" (%5, %231) : (!qillr.qubit, f64) -> ()
    %232 = arith.constant 1.100000 : f64
    "qillr.Rz" (%5, %232) : (!qillr.qubit, f64) -> ()
    %233 = arith.constant 1.100000 : f64
    "qillr.Rx" (%5, %233) : (!qillr.qubit, f64) -> ()
    %234 = arith.constant 1.100000 : f64
    "qillr.Ry" (%5, %234) : (!qillr.qubit, f64) -> ()
    %235 = arith.constant 1.100000 : f64
    "qillr.Rz" (%5, %235) : (!qillr.qubit, f64) -> ()
    %236 = arith.constant 1.100000 : f64
    "qillr.Rx" (%1, %236) : (!qillr.qubit, f64) -> ()
    %237 = arith.constant 1.100000 : f64
    "qillr.Ry" (%1, %237) : (!qillr.qubit, f64) -> ()
    %238 = arith.constant 1.100000 : f64
    "qillr.Rz" (%1, %238) : (!qillr.qubit, f64) -> ()
    %239 = arith.constant 3.455752 : f64
    "qillr.Rz" (%5, %239) : (!qillr.qubit, f64) -> ()
    %240 = arith.constant 3.455752 : f64
    "qillr.Rz" (%1, %240) : (!qillr.qubit, f64) -> ()
    %241 = arith.constant 0.000000 : f64
    %242 = arith.constant 1.570796 : f64
    %243 = arith.constant 0.785398 : f64
    "qillr.U3" (%5, %242, %241, %243) : (!qillr.qubit, f64, f64, f64) -> ()
    %244 = arith.constant 3.141593 : f64
    %245 = arith.constant 1.570796 : f64
    %246 = arith.constant 2.356194 : f64
    "qillr.U3" (%1, %245, %244, %246) : (!qillr.qubit, f64, f64, f64) -> ()
    %247 = arith.constant 1.570796 : f64
    "qillr.Rx" (%5, %247) : (!qillr.qubit, f64) -> ()
    "qillr.CNOT" (%5, %1) : (!qillr.qubit, !qillr.qubit) -> ()
    %248 = arith.constant 1.256637 : f64
    "qillr.Rx" (%5, %248) : (!qillr.qubit, f64) -> ()
    %249 = arith.constant 1.570796 : f64
    "qillr.Ry" (%1, %249) : (!qillr.qubit, f64) -> ()
    "qillr.CNOT" (%1, %5) : (!qillr.qubit, !qillr.qubit) -> ()
    %250 = arith.constant -1.570796 : f64
    "qillr.Rx" (%1, %250) : (!qillr.qubit, f64) -> ()
    %251 = arith.constant 1.570796 : f64
    "qillr.Rz" (%1, %251) : (!qillr.qubit, f64) -> ()
    "qillr.CNOT" (%5, %1) : (!qillr.qubit, !qillr.qubit) -> ()
    %252 = arith.constant 2.042035 : f64
    %253 = arith.constant 1.570796 : f64
    %254 = arith.constant 3.141593 : f64
    "qillr.U3" (%5, %253, %252, %254) : (!qillr.qubit, f64, f64, f64) -> ()
    %255 = arith.constant 0.471239 : f64
    %256 = arith.constant 1.570796 : f64
    %257 = arith.constant 0.000000 : f64
    "qillr.U3" (%1, %256, %255, %257) : (!qillr.qubit, f64, f64, f64) -> ()
    %258 = arith.constant 3.141593 : f64
    %259 = arith.constant 0.000000 : f64
    %260 = arith.constant 1.570796 : f64
    "qillr.U3" (%5, %259, %258, %260) : (!qillr.qubit, f64, f64, f64) -> ()
    %261 = arith.constant 0.000000 : f64
    %262 = arith.constant 0.000000 : f64
    %263 = arith.constant 1.570796 : f64
    "qillr.U3" (%1, %262, %261, %263) : (!qillr.qubit, f64, f64, f64) -> ()
    %264 = arith.constant 1.570796 : f64
    "qillr.Rx" (%5, %264) : (!qillr.qubit, f64) -> ()
    "qillr.CNOT" (%5, %1) : (!qillr.qubit, !qillr.qubit) -> ()
    %265 = arith.constant 1.256637 : f64
    "qillr.Rx" (%5, %265) : (!qillr.qubit, f64) -> ()
    %266 = arith.constant 1.570796 : f64
    "qillr.Ry" (%1, %266) : (!qillr.qubit, f64) -> ()
    "qillr.CNOT" (%1, %5) : (!qillr.qubit, !qillr.qubit) -> ()
    %267 = arith.constant -1.570796 : f64
    "qillr.Rx" (%1, %267) : (!qillr.qubit, f64) -> ()
    %268 = arith.constant 1.570796 : f64
    "qillr.Rz" (%1, %268) : (!qillr.qubit, f64) -> ()
    "qillr.CNOT" (%5, %1) : (!qillr.qubit, !qillr.qubit) -> ()
    %269 = arith.constant 0.000000 : f64
    %270 = arith.constant 3.141593 : f64
    %271 = arith.constant 1.570796 : f64
    "qillr.U3" (%5, %270, %269, %271) : (!qillr.qubit, f64, f64, f64) -> ()
    %272 = arith.constant 0.000000 : f64
    %273 = arith.constant 3.141593 : f64
    %274 = arith.constant 4.712389 : f64
    "qillr.U3" (%1, %273, %272, %274) : (!qillr.qubit, f64, f64, f64) -> ()
    %275 = arith.constant 4.712389 : f64
    %276 = arith.constant 1.570796 : f64
    %277 = arith.constant 4.712389 : f64
    "qillr.U3" (%5, %276, %275, %277) : (!qillr.qubit, f64, f64, f64) -> ()
    %278 = arith.constant 1.570796 : f64
    %279 = arith.constant 1.570796 : f64
    %280 = arith.constant 4.712389 : f64
    "qillr.U3" (%1, %279, %278, %280) : (!qillr.qubit, f64, f64, f64) -> ()
    %281 = arith.constant 1.570796 : f64
    "qillr.Rx" (%5, %281) : (!qillr.qubit, f64) -> ()
    "qillr.CNOT" (%5, %1) : (!qillr.qubit, !qillr.qubit) -> ()
    %282 = arith.constant 1.256637 : f64
    "qillr.Rx" (%5, %282) : (!qillr.qubit, f64) -> ()
    %283 = arith.constant 1.570796 : f64
    "qillr.Ry" (%1, %283) : (!qillr.qubit, f64) -> ()
    "qillr.CNOT" (%1, %5) : (!qillr.qubit, !qillr.qubit) -> ()
    %284 = arith.constant -1.570796 : f64
    "qillr.Rx" (%1, %284) : (!qillr.qubit, f64) -> ()
    %285 = arith.constant 1.570796 : f64
    "qillr.Rz" (%1, %285) : (!qillr.qubit, f64) -> ()
    "qillr.CNOT" (%5, %1) : (!qillr.qubit, !qillr.qubit) -> ()
    %286 = arith.constant 1.570796 : f64
    %287 = arith.constant 1.570796 : f64
    %288 = arith.constant 1.570796 : f64
    "qillr.U3" (%5, %287, %286, %288) : (!qillr.qubit, f64, f64, f64) -> ()
    %289 = arith.constant 1.570796 : f64
    %290 = arith.constant 1.570796 : f64
    %291 = arith.constant 4.712389 : f64
    "qillr.U3" (%1, %290, %289, %291) : (!qillr.qubit, f64, f64, f64) -> ()
    %292 = arith.constant 1.100000 : f64
    "qillr.Rx" (%5, %292) : (!qillr.qubit, f64) -> ()
    %293 = arith.constant 1.100000 : f64
    "qillr.Ry" (%5, %293) : (!qillr.qubit, f64) -> ()
    %294 = arith.constant 1.100000 : f64
    "qillr.Rz" (%5, %294) : (!qillr.qubit, f64) -> ()
    %295 = arith.constant 1.100000 : f64
    "qillr.Rx" (%1, %295) : (!qillr.qubit, f64) -> ()
    %296 = arith.constant 1.100000 : f64
    "qillr.Ry" (%1, %296) : (!qillr.qubit, f64) -> ()
    %297 = arith.constant 1.100000 : f64
    "qillr.Rz" (%1, %297) : (!qillr.qubit, f64) -> ()
    %298 = "qillr.ralloc" () : () -> (!qillr.result)
    "qillr.measure" (%1, %298) : (!qillr.qubit, !qillr.result) -> ()
    %m1_bits = "qpu.to_bits" (%298) : (!qillr.result) -> tensor<1xi1>
    %m1_idx = arith.constant 0 : index
    %m1 = tensor.extract %m1_bits[%m1_idx] : tensor<1xi1>
    %300 = "qillr.ralloc" () : () -> (!qillr.result)
    "qillr.measure" (%5, %300) : (!qillr.qubit, !qillr.result) -> ()
    %m2_bits = "qpu.to_bits" (%300) : (!qillr.result) -> tensor<1xi1>
    %m2_idx = arith.constant 0 : index
    %m2 = tensor.extract %m2_bits[%m2_idx] : tensor<1xi1>
   
    vector.print %m1 : i1
    vector.print %m2 : i1
    return
  }

    func.func @entry() {
    // CHECK: {{0|1}}
    // CHECK: {{0|1}}
    func.call @dnn_qasm_bench() : () -> ()
    return
  }
}
