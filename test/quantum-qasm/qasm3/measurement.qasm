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
// CHECK: %[[C0:.*]] = tensor.insert_slice %[[BIT]] into %[[BITS]][0] [1] [1]
// CHECK: %[[WHOLE0:.*]], %[[WHOLE0Q:.*]] = "quantum.measure"(%[[Q]]#0)
// CHECK: %[[BIT0:.*]] = "qpu.to_bits"(%[[WHOLE0]])
// CHECK: %[[C1:.*]] = tensor.insert_slice %[[BIT0]] into %[[C0]][0] [1] [1]
// CHECK: %[[WHOLE1:.*]], %[[WHOLE1Q:.*]] = "quantum.measure"(%[[INDEXEDQ]])
// CHECK: %[[BIT1:.*]] = "qpu.to_bits"(%[[WHOLE1]])
// CHECK: tensor.insert_slice %[[BIT1]] into %[[C1]][1] [1] [1]
// CHECK: %[[DISCARD:.*]], %[[DISCARDQ:.*]] = "quantum.measure"(%[[WHOLE0Q]])
// CHECK-NOT: qpu.to_bits
// CHECK: %[[DISCARD0:.*]], %[[DISCARD0Q:.*]] = "quantum.measure"(%[[DISCARDQ]])
// CHECK: %[[DISCARD1:.*]], %[[DISCARD1Q:.*]] = "quantum.measure"(%[[WHOLE1Q]])
// CHECK: "quantum.reset"(%[[DISCARD0Q]])
// CHECK: "quantum.reset"(%[[DISCARD1Q]])
