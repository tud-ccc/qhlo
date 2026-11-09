// RUN: quantum-qasm %s | FileCheck %s
// RUN: sed 's/measure \(.*\) -> \(.*\);/\2 = measure \1;/' %s > %t.qasm
// RUN: quantum-qasm %t.qasm | FileCheck %s
OPENQASM 3.0;
qubit[2] q;
bit[2] c;
measure q[1] -> c[0];
measure q -> c;
measure q[0];
measure q;
reset q;

// CHECK: %[[BITS:.*]] = arith.constant dense<false> : tensor<2xi1>
// CHECK: %[[Q:.*]]:2 = "quantum.split"
// CHECK: %[[INDEXED:.*]], %[[INDEXEDQ:.*]] = "quantum.measure"(%[[Q]]#1)
// CHECK: %[[BIT:.*]] = "qpu.to_bits"(%[[INDEXED]])
// CHECK: tensor.insert_slice %[[BIT]] into %[[BITS]][0] [1] [1]
// CHECK: %[[JOINED:.*]] = "quantum.merge"(%[[Q]]#0, %[[INDEXEDQ]])
// CHECK: %[[WHOLE:.*]], %[[WHOLEQ:.*]] = "quantum.measure"(%[[JOINED]]) : (!quantum.qubit<2>)
// CHECK: %[[WHOLEBITS:.*]] = "qpu.to_bits"(%[[WHOLE]])
// CHECK: %[[SPLIT:.*]]:2 = "quantum.split"(%[[WHOLEQ]])
// CHECK: %[[DISCARD:.*]], %[[DISCARDQ:.*]] = "quantum.measure"(%[[SPLIT]]#0)
// CHECK-NOT: qpu.to_bits
// CHECK: %[[REJOINED:.*]] = "quantum.merge"(%[[DISCARDQ]], %[[SPLIT]]#1)
// CHECK: %[[DISCARDALL:.*]], %[[DISCARDALLQ:.*]] = "quantum.measure"(%[[REJOINED]])
// CHECK-NOT: qpu.to_bits
// CHECK: "quantum.reset"(%[[DISCARDALLQ]]) : (!quantum.qubit<2>)
// CHECK: "qpu.return"(%[[WHOLEBITS]])
