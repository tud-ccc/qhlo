# Official OpenQASM 3 examples

Source: https://github.com/openqasm/openqasm
Branch at import: `main`
Pinned commit: `7fbf9e9eb3692a1288c014d6efd43523701886c6`

Upstream tree: https://github.com/openqasm/openqasm/tree/7fbf9e9eb3692a1288c014d6efd43523701886c6/examples

The files in `Inputs/` are byte-for-byte copies of all 21 `.qasm` examples
and `stdgates.inc` from the pinned upstream `examples/` directory, including
original comments and attribution. They are provided by the OpenQASM project
under Apache-2.0; the upstream `LICENSE` is copied unchanged alongside this
file. This revision has no root NOTICE file. The `.mlir` lit wrappers are
local additions; no upstream source was modified.

| Example | Coverage |
| --- | --- |
| `adder.qasm` | Custom gates, integer inputs, loops and register slices |
| `alignment.qasm` | Stretch expressions, delays and barriers |
| `arrays.qasm` | Multidimensional arrays, initializers, indexing and slicing |
| `cphase.qasm` | Parameterized gate, Unicode identifiers (illustrative fragment) |
| `dd.qasm` | Timing boxes, durationof and physical qubits |
| `defcal.qasm` | Calibration grammar and calibration bodies (illustrative pulse code) |
| `gateteleport.qasm` | Subroutines, extern functions and conditional correction |
| `inverseqft1.qasm` | Measurement assignment, casts and classical conditions |
| `inverseqft2.qasm` | Scalar measurement bits and classical conditions |
| `ipe.qasm` | Gate modifiers, angles, loops and compound assignments |
| `msd.qasm` | Magic-state distillation, subroutines and classical control flow |
| `qec.qasm` | Subroutine return values and syndrome-based correction |
| `qft.qasm` | Parameterized gates and register measurement |
| `qpt.qasm` | Empty custom gates, barriers and measurement |
| `rb.qasm` | Register operations and randomized benchmarking |
| `rus.qasm` | While loops, subroutine calls and mathematical expressions |
| `scqec.qasm` | Surface-code routines, extern declarations and nested loops |
| `t1.qasm` | Timing, calibration, physical qubits and nested loops |
| `teleport.qasm` | Measurement, conditional correction and empty custom gate |
| `varteleport.qasm` | Aliases, index sets and parameterized register sizes |
| `vqe.qasm` | Extern functions, subroutines, loops and classical arithmetic |

## Running and extending the tests

Run with `check-quantum-mlir-frontend`, or run lit against the configured build's
`test/quantum-qasm/qasm3/official` directory. Lit excludes `Inputs/` from discovery;
each `.mlir` wrapper invokes `quantum-qasm` on its corresponding original file
and checks for a main circuit with a `qpu.return` terminator. `stdgates.inc` is
an include library, not a standalone test, so it has no wrapper.

All wrappers initially use `XFAIL: *`. They retain successful frontend output
as the expectation rather than accepting a parser error as success. The QASM3 frontend parses the source, but lowering still creates an empty
circuit skeleton; the terminator check deliberately prevents that skeleton from
satisfying the tests.
Remove each XFAIL marker as support becomes available and add representative
FileCheck assertions for the features exercised by that example. Lit reports an
unexpected pass when a marked wrapper starts satisfying its checks. These initial
checks are scaffolding, not exhaustive parsing, lowering or semantic validation.

## Known corpus and frontend limitations

Most upstream files omit the optional OPENQASM version declaration. `teleport.qasm`
uses `OPENQASM 3;`, while `arrays.qasm` uses `OPENQASM 3.0;`. The frontend
dispatcher accepts both forms and defaults to QASM3 when the
version declaration is absent, skipping leading line and block comments.
The originals are kept unchanged. Include resolution for the adjacent
`stdgates.inc` will also need frontend support.

These are upstream examples, not a guaranteed semantically valid conformance
suite. For example, `cphase.qasm` references undeclared `q` and `CX`, `qft.qasm`
uses `cphase` without defining it, and `defcal.qasm` contains illustrative pulse
bodies with placeholders. Some examples use historical syntax (such as `creg`
in `scqec.qasm`). A remaining failure may therefore need an upstream correction,
a separately documented local test, or a diagnostic expectation rather than a
new language feature. Review each example before removing its expected-failure
marker; do not silently change the imported files to make compilation succeed.

## Integrity

SHA-256 hashes of the unmodified imported files:

```text
bd1800da8945bae7c48ec26bf8e0388ee01de4b7d96ebc98b29d120428180b8a  Inputs/adder.qasm
2f7ff88133ea86f977c91075ab2350062d4444dd0262b53d4e0ec8df837dacd1  Inputs/alignment.qasm
59c0bc640533a2020aebe2177be0cfba33336138760b22928b93f5b53af3756c  Inputs/arrays.qasm
a0394b1867dd2e5ef057efa59d36201f1f25388d190bac2b7d1cacb8d5f74cae  Inputs/cphase.qasm
fd8bfdf38200981a3b27b2ec26196e6d7ea4349932aeed4b2719889d6d03b5bb  Inputs/dd.qasm
7a0630e64215234716195ee46931924b2574265edcc9b3e55952344466e4e858  Inputs/defcal.qasm
d639fe83fdcfdef1d9bee99145a4a6ed14adccb412a6c5bae66ec03d03cb1dc3  Inputs/gateteleport.qasm
36f4fdc18fbf631afd698f84f35d0aef1f9599c1f112c199a2c5281715e40cef  Inputs/inverseqft1.qasm
66942382b8ae28fde838c3da462741b51df56b4efee2a5f5ed55ebaf71bd2829  Inputs/inverseqft2.qasm
84ea3c871e8e63fe8931061aaaf0484e5409f26a582bd805ed194ee01afc5d86  Inputs/ipe.qasm
8142ef82159d53fb9a01c938411b4a62dd4920799b030f2cd70676bf5216f249  Inputs/msd.qasm
11c58d2d0bb218c0ca0de6aa1732ee5860d9bd8540f1ceba270dec28a14a7f10  Inputs/qec.qasm
42053dea2eb817e3da4ca9e337765084e864ddc4dc3a77f85dac0fe5b58b4e84  Inputs/qft.qasm
df1c5082292afbed723cbd7431facfd17de33be10cb1e2dec78be5ad00012844  Inputs/qpt.qasm
c5d1efdf255a2b2467f9585913393482195ade36cd2493e2dd618192522888f1  Inputs/rb.qasm
4564860c7e373d9eb8b4f73d4e192b3ff8288e8589791367ffe1cd128e2d5d30  Inputs/rus.qasm
c1c800d224e9776c87e51eaba5cae300bcef378d89fd936f449afd7c84066a46  Inputs/scqec.qasm
b2b60afcbc0c2195bd3cb3ec0347c4c9f7447fd22efb28b36b5ab7ee721c11c0  Inputs/stdgates.inc
aad931fdbd130dfe0d027ff69db294685ee7ca33ba5ed1322909fadd6192527e  Inputs/t1.qasm
f9aa8882e6b1c0cde997b819dc2be4333e6c3bbeeb4c71be703fcc9a51a6f26d  Inputs/teleport.qasm
452c3735a1ec66d202923d4dd5f2b373e44fab358ecda392a3e3a765aa9a83f2  Inputs/varteleport.qasm
f3ba6f182b336f479f78ec95fe07b4407215aa9e5b6fa22672868cc464ec6d9b  Inputs/vqe.qasm
ebc659bca13f3e21142b73c1da286a2cb7db57879c7d2a068e48f62612f1fd5c  LICENSE
```
