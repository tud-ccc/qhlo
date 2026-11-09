# Official OpenQASM 2 examples

Source: https://github.com/openqasm/openqasm
Branch at import: `OpenQASM2.x`
Pinned commit: `d1a100251bb5794e81cb46e55a69651ac9181554`

Upstream tree: https://github.com/openqasm/openqasm/tree/d1a100251bb5794e81cb46e55a69651ac9181554/examples

The files in `Inputs/` are byte-for-byte copies of the corresponding upstream
`examples/` files, including their original comments and attribution. They are
provided by the OpenQASM project under Apache-2.0; the upstream `LICENSE` is
copied unchanged alongside this file. This upstream revision has no NOTICE file.
The `.mlir` lit wrappers are local additions; no upstream source was modified.

| Example | Coverage |
| --- | --- |
| `qft.qasm` | Parameter expressions, controlled phases, whole-register measurement |
| `adder.qasm` | Custom gates, multiple registers, register-wide gates, indexed measurement |
| `teleport.qasm` | Empty gate body, measurements and classical conditions |
| `qec.qasm` | Five-operand custom gate, register measurements and multi-bit conditions |
| `W-state.qasm` | Custom controlled-H gate, Toffoli and indexed operands |
| `bigadder.qasm` | Nested custom gates and an eight-bit adder |
| `inverseqft1.qasm` | Conditional phases using one multi-bit classical register |
| `inverseqft2.qasm` | Conditional phases using separate classical registers |
| `ipea_3_pi_8.qasm` | Iterative phase estimation, parameterized gates and reset (expected failure) |
| `pea_3_pi_8.qasm` | Phase estimation and parameterized gates (expected failure) |
| `qpt.qasm` | Empty pre/post gate bodies and process tomography |
| `rb.qasm` | Controlled-Z gates and randomized benchmarking sequence |
| `teleportv2.qasm` | Teleportation with a single multi-bit classical register |

Run with `check-quantum-mlir-frontend`. Lit excludes `Inputs/` from discovery;
each wrapper invokes `quantum-qasm` on one original input and checks the full operation sequence and SSA connections with FileCheck.
Checks cover gate bodies and calls, parameter arithmetic, register splits,
barriers, measurement destinations, conditional branches, cleanup and host
execution. SSA names are captured rather than tied to printer numbering;
independent deallocations use unordered checks. These tests expect successful frontend compilation,
not simulation or exhaustive semantic-equivalence tests. Includes of `qelib1.inc`
use the frontend's embedded library, as in the other QASM2 frontend tests.

All 13 non-negative `.qasm` examples from the pinned revision are imported.
Only `invalid_gate_no_found.qasm` and `invalid_missing_semicolon.qasm` are excluded.
The upstream `qelib1.inc` is a library, not a standalone test; the frontend uses
its embedded version as described above.

The valid `ipea_3_pi_8.qasm` and `pea_3_pi_8.qasm` examples currently fail because
their `cu` definitions conflict with the frontend's embedded library. Their
wrappers retain successful compilation checks but are marked `XFAIL: *` to
record this known compatibility limitation. They are executed as expected
failures, not excluded or treated as invalid input. Remove the markers when
support is fixed; lit reports an unexpected pass if they begin succeeding.

## Integrity

SHA-256 hashes of the unmodified imported files:

```text
9077432a88fea0f3da2c3b24558333c1a329261b20836ba82b253418d8c7b0dd  Inputs/W-state.qasm
89af975627593648e7aca6ac6cb936d2c872093c1eedcaa1b2ab4fa14b602624  Inputs/adder.qasm
097ac44672d0bb9696cd77e561bc094a661f45fa84762373df840efddac4d094  Inputs/bigadder.qasm
b0e21e12bad9a7e995472909045d77308696128f7dd458b0b97a777ae10680b8  Inputs/inverseqft1.qasm
2b950bb566ea547918adcea27b13defb3ad31fb10bf3b4ccb25d51e91b5527b1  Inputs/inverseqft2.qasm
da2f2ddad04ae85d04114519b3f497d853aca0252359c06afc29bbc6f7883934  Inputs/ipea_3_pi_8.qasm
dfb4dd9937a4f1f5130f12b625f0da865be58da4b6118d274852aa39744a88b6  Inputs/pea_3_pi_8.qasm
dcf8d069188a5cf96a04aaaed23ff6f78e3663523c429609676e066a90332598  Inputs/qec.qasm
62c6c8c7ddd95ac2b5367420b9925dbf82d6fb45725f089f01619a639621ad60  Inputs/qft.qasm
5e98ebd3a30cbdadb2ce5b6801f8b783977f04766a3afdba73ef076b959e6b15  Inputs/qpt.qasm
ab011d19821777f0617e9449c1cd1f08204a5d8cb38f80055772fdabcc88d77c  Inputs/rb.qasm
3f3e8a4dba9ede385e6f17c3af852deade4f779a8a6042f6001f63f5a0e9c405  Inputs/teleport.qasm
d9831b5b12bf2a279a081a7341686abb2a73fd0f25448c23db0b38f530c7b2dd  Inputs/teleportv2.qasm
b40930bbcf80744c86c46a12bc9da056641d722716c378f5659b9e555ef833e1  LICENSE
```
