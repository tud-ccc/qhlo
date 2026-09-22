# QHLO

`qhlo` is an MLIR-based compiler infrastructure for hybrid quantum-classical programs. It provides quantum-specific dialects, analyses, and optimization passes together with lowering paths to LLVM IR and the [Quantum Intermediate Representation (QIR)](https://github.com/qir-alliance/qir-spec).

The project also provides optional Python bindings, an OpenQASM frontend and OpenQASM2 codegen, and execution support through [QIR Runner](https://github.com/qir-alliance/qir-runner).

> **Status**
>
> This project is under active development. Dialects, compiler APIs, and command-line interfaces may change between releases.

## Features

- MLIR dialects for representing quantum and hybrid quantum-classical programs.
- Progressive lowering through MLIR to LLVM IR and QIR.
- Quantum-specific analyses and optimization passes.
- C and Python APIs for integrating the compiler into external tools.
- Optional OpenQASM frontend.
- Optional QIR Runner backend.
- `lit`/FileCheck dialect tests and C++ unit tests.

## Tested Toolchain

The project is currently built and tested with the following versions:

| Component | Tested version |
| --- | --- |
| LLVM / MLIR | `23.1.1` (`6dfe167`) |
| CMake | `3.23` or newer |
| Python | `3.12` |
| QIR Runner | `0.7.6` |

Newer versions may work, but are not necessarily part of the tested configuration.

## Repository Layout

```text
qhlo/
├── docs/        Documentation
├── frontend/    Frontends, including OpenQASM integration
├── include/     Public C++ and TableGen headers
├── lib/         Dialect, transformation, backend, and C API implementations
├── python/      Python bindings
├── test/        MLIR lit/FileCheck tests
├── tools/       Command-line tools
└── unittest/    C++ unit tests
```

## Requirements

A minimal build requires:

- a C++20-capable compiler,
- [CMake](https://cmake.org/) 3.23 or newer,
- [Ninja](https://ninja-build.org/),
- LLVM/MLIR 23.1.1.

Additional requirements depend on enabled components:

- Python 3.12 and the MLIR Python bindings for the Python API,
- Rust/Cargo and QIR Runner for the QIR Runner backend,
- `uv` is recommended for Python environment management.

The remainder of this document shows a reproducible development setup.

---

## Quick Start

If LLVM/MLIR 23.1.1 is already built and your local CMake preset is configured, the normal development workflow is:

```sh
# Create and activate the Python environment.
uv venv .venv --seed -p 3.12
source .venv/bin/activate

# Install project development dependencies.
uv pip install -r requirements.txt

# Configure and build.
cmake --preset llvm-23.1.1
cmake --build --preset llvm-23.1.1

# Run dialect tests.
cmake --build build/llvm-23.1.1 --target check-quantum-mlir

# Build and run C++ unit tests.
cmake --build build/llvm-23.1.1 --target quantum-mlir-tests
ctest --test-dir build/llvm-23.1.1 --output-on-failure
```

If you do not yet have LLVM/MLIR 23.1.1, follow the setup below.

---

## Building LLVM / MLIR

The tested LLVM release is `llvmorg-23.1.1`.

Choose source and build directories first:

```sh
export LLVM_SRC="$HOME/src/llvm-project"
export LLVM_BUILD="$LLVM_SRC/build"
export PROJECT_SRC="$HOME/src/qhlo"
export VENV_DIR="$PROJECT_SRC/.venv"
```

Clone the tested LLVM release:

```sh
git clone \
  --depth 1 \
  --branch llvmorg-23.1.1 \
  https://github.com/llvm/llvm-project.git \
  "$LLVM_SRC"
```

### Python environment for MLIR bindings

The project's Python API require MLIR's Python bindings. MLIR does not enable them by default.

Create a virtual environment:

```sh
uv venv "$VENV_DIR" --seed -p 3.12
source "$VENV_DIR/bin/activate"
```

Install the dependencies required by the MLIR Python bindings:

```sh
uv pip install -r "$LLVM_SRC/mlir/python/requirements.txt"
```

### Configure LLVM / MLIR

```sh
cmake \
  -S "$LLVM_SRC/llvm" \
  -B "$LLVM_BUILD" \
  -G Ninja \
  -DCMAKE_BUILD_TYPE=Debug \
  -DLLVM_ENABLE_PROJECTS="mlir" \
  -DLLVM_TARGETS_TO_BUILD="host" \
  -DLLVM_ENABLE_ASSERTIONS=ON \
  -DLLVM_BUILD_TOOLS=ON \
  -DLLVM_OPTIMIZED_TABLEGEN=ON \
  -DBUILD_SHARED_LIBS=ON \
  -DMLIR_ENABLE_EXECUTION_ENGINE=ON \
  -DMLIR_ENABLE_BINDINGS_PYTHON=ON \
  -DMLIR_BUILD_MLIR_C_DYLIB=ON \
  -DPython3_EXECUTABLE="$VENV_DIR/bin/python3" \
  -DCMAKE_C_VISIBILITY_PRESET=hidden \
  -DCMAKE_CXX_VISIBILITY_PRESET=hidden \
  -DCMAKE_VISIBILITY_INLINES_HIDDEN=ON
```

Build LLVM/MLIR:

```sh
cmake --build "$LLVM_BUILD" --parallel
```

The relevant CMake package directories are then:

```text
$LLVM_BUILD/lib/cmake/llvm
$LLVM_BUILD/lib/cmake/mlir
```

To verify the installation:

```sh
"$LLVM_BUILD/bin/mlir-opt" --version
"$LLVM_BUILD/bin/llvm-config" --version
```

---

## Optional Components

### OpenQASM Frontend

The OpenQASM frontend is optional and controlled by:

```text
FRONTEND_QASM=ON
```

To disable the frontend:

```sh
-DFRONTEND_QASM=OFF
```

### QIR Runner Backend

The QIR Runner backend is optional and controlled by:

```text
BACKEND_QIR=ON
```

The project is currently tested with custom-patched QIR Runner `0.7.6`.

Clone and build the tested release:

```sh
export QIR_SRC="$HOME/src/qir-runner"

git clone \
  --depth 1 \
  --branch v0.7.6 \
  https://github.com/qir-alliance/qir-runner.git \
  "$QIR_SRC"

cargo build \
  --manifest-path "$QIR_SRC/Cargo.toml" \
  --release
```

For the current project configuration, `QIR_DIR` points to the directory containing the built QIR Runner libraries:

```sh
export QIR_DIR="$QIR_SRC/target/release/deps"
```

To disable the backend:

```sh
-DBACKEND_QIR=OFF
```

---

## Building qhlo

### Recommended: CMake Presets

The recommended developer workflow uses CMake presets.

Machine-independent settings should be kept in the repository's `CMakePresets.json`. Local filesystem paths such as LLVM, MLIR, Python, and QIR Runner locations should be placed in an uncommitted `CMakeUserPresets.json`.

A local preset can inherit from the repository's LLVM 23 preset:

```json
{
  "version": 3,
  "configurePresets": [
    {
      "name": "local-llvm-23.1.1",
      "displayName": "Local LLVM 23.1.1",
      "inherits": "llvm-23.1.1",
      "cacheVariables": {
        "LLVM_DIR": "/absolute/path/to/llvm-project/build/lib/cmake/llvm",
        "MLIR_DIR": "/absolute/path/to/llvm-project/build/lib/cmake/mlir",
        "Python3_EXECUTABLE": "/absolute/path/to/qhlo/.venv/bin/python3",
        "QIR_DIR": "/absolute/path/to/qir-runner/target/release/deps"
      }
    }
  ],
  "buildPresets": [
    {
      "name": "local-llvm-23.1.1",
      "configurePreset": "local-llvm-23.1.1"
    }
  ]
}
```

List the available presets:

```sh
cmake --list-presets=all
```

Configure and build:

```sh
cmake --preset local-llvm-23.1.1
cmake --build --preset local-llvm-23.1.1
```

Use a different build directory for different LLVM versions. Do not reuse the same CMake cache across LLVM releases.

### Manual Configuration

The project can also be configured without presets:

```sh
source "$VENV_DIR/bin/activate"

cmake \
  -S "$PROJECT_SRC" \
  -B "$PROJECT_SRC/build" \
  -G Ninja \
  -DCMAKE_BUILD_TYPE=Debug \
  -DLLVM_DIR="$LLVM_BUILD/lib/cmake/llvm" \
  -DMLIR_DIR="$LLVM_BUILD/lib/cmake/mlir" \
  -DPython3_EXECUTABLE="$VENV_DIR/bin/python3" \
  -DMLIR_ENABLE_BINDINGS_PYTHON=ON \
  -DBACKEND_QIR=ON \
  -DQIR_DIR="$QIR_DIR" \
  -DFRONTEND_QASM=ON \
  -DBUILD_TESTING=ON \
  -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
```

Build:

```sh
cmake --build "$PROJECT_SRC/build" --parallel
```

If the OpenQASM frontend or QIR Runner backend is not needed, disable it explicitly:

```sh
-DFRONTEND_QASM=OFF
-DBACKEND_QIR=OFF
```

---

## Python Bindings

When `MLIR_ENABLE_BINDINGS_PYTHON=ON`, the build generates the project's Python package below the build directory.

For development, add the generated package to the active virtual environment with a `.pth` file:

```sh
python3 - <<'PY'
from pathlib import Path
import sysconfig

package = Path("build/python_packages/quantum").resolve()
pth = Path(sysconfig.get_path("purelib")) / "quantum-python-bindings.pth"
pth.write_text(f"{package}\n")

print(f"Added {package} to {pth}")
PY
```

When using a preset with a different binary directory, adjust `build/python_packages/quantum` accordingly.

---

## Running Tests

### MLIR Dialect Tests

The MLIR tests use LLVM's `lit` and FileCheck infrastructure:

```sh
cmake --build build --target check-quantum-mlir
```

With a preset-specific build directory, use that directory instead:

```sh
cmake --build build/llvm-23.1.1 --target check-quantum-mlir
```

### C++ Unit Tests

Build the unit-test executable:

```sh
cmake --build build --target quantum-mlir-tests
```

Run all CTest-registered tests:

```sh
ctest --test-dir build --output-on-failure
```

For verbose test output:

```sh
ctest --test-dir build -V
```

---

## Development

### Python Development Dependencies

The repository pins its Python development dependencies in the top-level `requirements.txt`.

```sh
uv venv .venv --seed -p 3.12
source .venv/bin/activate
uv pip install -r requirements.txt
```

### pre-commit

Install the provided pre-commit hooks once per clone:

```sh
pre-commit install
```

Run all hooks manually:

```sh
pre-commit run --all-files
```

This is recommended before opening a pull request because it catches formatting and static-analysis issues before CI.

### Recommended Validation Before a Pull Request

```sh
pre-commit run --all-files

cmake --build build --target check-quantum-mlir
cmake --build build --target quantum-mlir-tests
ctest --test-dir build --output-on-failure
```

---

## CMake Configuration

The most important project CMake variables are:

| Variable | Type | Description |
| --- | --- | --- |
| `MLIR_DIR` | `PATH` | Path to MLIR's CMake package directory, e.g. `$LLVM_BUILD/lib/cmake/mlir`. |
| `LLVM_DIR` | `PATH` | Path to LLVM's CMake package directory, e.g. `$LLVM_BUILD/lib/cmake/llvm`. Usually associated with the LLVM installation used by MLIR. |
| `Python3_EXECUTABLE` | `FILEPATH` | Python interpreter used for the Python bindings and frontend. Use the interpreter from the project's virtual environment. |
| `MLIR_ENABLE_BINDINGS_PYTHON` | `BOOL` | Enables this project's Python bindings. LLVM/MLIR itself must also have been built with Python bindings enabled. |
| `FRONTEND_QASM` | `BOOL` | Enables the OpenQASM frontend. |
| `BACKEND_QIR` | `BOOL` | Enables the QIR Runner backend. |
| `QIR_DIR` | `PATH` | Directory containing the built QIR Runner libraries, currently `$QIR_SRC/target/release/deps`. Required when `BACKEND_QIR=ON`. |
| `BUILD_TESTING` | `BOOL` | Enables C++ unit tests. |
| `CMAKE_BUILD_TYPE` | `STRING` | Build configuration for single-config generators such as Ninja, typically `Debug` or `Release`. |
| `CMAKE_EXPORT_COMPILE_COMMANDS` | `BOOL` | Generates `compile_commands.json` for tooling such as clangd. |

LLVM-specific variables such as `MLIR_BUILD_MLIR_C_DYLIB` belong to the LLVM/MLIR build and are not project options of `qhlo`.

---

## Troubleshooting

### CMake still uses an older LLVM version

LLVM versions must not share a build directory.

Delete the stale build directory or select a different preset-specific binary directory:

```sh
rm -rf build
cmake --preset local-llvm-23.1.1
```

Inspect the selected package locations in `CMakeCache.txt` if necessary:

```sh
grep -E '^(LLVM_DIR|MLIR_DIR):' build/CMakeCache.txt
```

### MLIR Python modules cannot be imported

Verify that:

1. LLVM/MLIR was configured with `MLIR_ENABLE_BINDINGS_PYTHON=ON`.
2. `Python3_EXECUTABLE` points to the same virtual environment used at runtime.
3. The generated project Python package is on `PYTHONPATH` or installed through the `.pth` file described above.

Check the active interpreter:

```sh
which python3
python3 -c "import sys; print(sys.executable)"
```

### QIR Runner cannot be found

Verify that the backend is enabled and that `QIR_DIR` points to the built library directory:

```sh
echo "$QIR_DIR"
ls "$QIR_DIR"
```

For the tested QIR Runner build this is typically:

```text
<qir-runner>/target/release/deps
```

### Reconfiguring after changing LLVM versions

Do not reuse a CMake cache that was generated against another LLVM/MLIR version.

Prefer:

```text
build/llvm-20.1.7/
build/llvm-23.1.1/
```

instead of a single shared `build/` directory.

---

## License

Distributed under the BSD 3-Clause Clear License. See [`LICENSE.txt`](LICENSE.txt) for details.
