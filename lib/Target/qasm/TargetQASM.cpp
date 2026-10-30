//===- TargetQASM.cpp - QILLR to OpenQASM Translation ---------------------===//
//
// Translate QILLR dialect ops into OpenQASM 2.0.
//
/// @file
/// @author     Washim Neupane (washim.neupane@outlook.com)
/// @author     Lars Schütze (lars.schuetze@tu-dresden.de)
//===----------------------------------------------------------------------===//

#include "quantum-mlir/Target/qasm/TargetQASM.h"

#include "quantum-mlir/Dialect/QILLR/IR/QILLROps.h"
#include "quantum-mlir/Dialect/QPU/IR/QPU.h"
#include "quantum-mlir/Dialect/QPU/IR/QPUOps.h"

#include <atomic>
#include <cstddef>
#include <llvm/ADT/APInt.h>
#include <llvm/ADT/DenseMap.h>
#include <llvm/ADT/STLExtras.h>
#include <llvm/ADT/StringRef.h>
#include <llvm/ADT/TypeSwitch.h>
#include <llvm/Support/Casting.h>
#include <llvm/Support/FormatVariadic.h>
#include <llvm/Support/LogicalResult.h>
#include <mlir-c/Diagnostics.h>
#include <mlir/Dialect/Arith/IR/Arith.h>
#include <mlir/Dialect/SCF/IR/SCF.h>
#include <mlir/Dialect/Tensor/IR/Tensor.h>
#include <mlir/IR/BuiltinAttributes.h>
#include <mlir/IR/BuiltinOps.h>
#include <mlir/IR/Diagnostics.h>
#include <mlir/IR/Matchers.h>
#include <mlir/IR/Operation.h>
#include <mlir/IR/Visitors.h>
#include <mlir/Support/LogicalResult.h>
#include <optional>
#include <string>

using namespace mlir;
using namespace mlir::qillr;

using llvm::formatv;

namespace {
class QASMEmitter {
public:
    QASMEmitter(raw_ostream &o) : os(o), names() {}

    LogicalResult emitOperation(Operation &op);

    /// Return the mapped qubit register name or new name for value.
    std::string getOrCreateQubitRegisterName(Value value);

    /// Return the mapped classical register name or new name for value.
    std::string getOrCreateClassicalRegisterName(Value value);

    /// Returns the output stream.
    raw_ostream &ostream() { return os; };

private:
    raw_ostream &os;
    std::atomic_int nextQubitId{0};
    std::atomic_int nextRegisterId{0};
    llvm::DenseMap<Value, std::string> names;
};

static std::string printOperand(Value v)
{
    auto c = v.getDefiningOp<arith::ConstantOp>();
    auto result = mlir::cast<FloatAttr>(c.getValue());
    if (result)
        return std::to_string(result.getValueAsDouble());
    else
        emitError(v.getLoc(), "Defining op not a constant.");

    return "";
}

/// Emit the QASM header
static void printHeader(QASMEmitter &emitter)
{
    raw_ostream &os = emitter.ostream();
    os << "OPENQASM 2.0;\n"
          "include \"qelib1.inc\";\n\n";
}

LogicalResult printQubitAlloc(QASMEmitter &emitter, AllocOp op)
{
    std::string name = emitter.getOrCreateQubitRegisterName(op.getResult());
    int64_t size = op.getSize();
    raw_ostream &os = emitter.ostream();
    os << "qreg " << name << "[" << size << "];\n";
    return success();
}

static LogicalResult printResultAlloc(QASMEmitter &emitter, AllocResultOp op)
{
    std::string name = emitter.getOrCreateClassicalRegisterName(op.getResult());
    int64_t size = op.getSize();
    raw_ostream &os = emitter.ostream();
    os << "creg " << name << "[" << size << "];\n";
    return success();
}

template<typename OpTy>
static LogicalResult
printPrimitiveGate(QASMEmitter &emitter, OpTy op, std::string opName)
{
    raw_ostream &os = emitter.ostream();
    std::string name = emitter.getOrCreateQubitRegisterName(op.getInput());
    std::optional<int64_t> index = op.getIndex();
    os << opName << " " << name << "[" << index << "]" << ";\n";
    return success();
}

template<typename OpTy>
static LogicalResult
printRotationGate(QASMEmitter &emitter, OpTy op, std::string opName)
{
    raw_ostream &os = emitter.ostream();
    std::string name = emitter.getOrCreateQubitRegisterName(op.getInput());
    std::optional<int64_t> index = op.getIndex();
    std::string theta = printOperand(op.getAngle());
    os << opName << "(" << theta << ") " << name << "[" << index << "];\n";
    return success();
}

template<typename OpTy>
static LogicalResult
printControledGate(QASMEmitter &emitter, OpTy op, std::string opname)
{
    raw_ostream &os = emitter.ostream();
    std::string control = emitter.getOrCreateQubitRegisterName(op.getControl());
    std::optional<int64_t> ctrlIndex = op.getControlIndex();
    std::string target = emitter.getOrCreateQubitRegisterName(op.getTarget());
    std::optional<int64_t> targetIndex = op.getTargetIndex();
    os << opname << " " << control << "[" << ctrlIndex << "]" << ", " << target
       << "[" << targetIndex << "]" << ";\n";
    return success();
}

static LogicalResult printToffoli(QASMEmitter &emitter, CCXOp op)
{
    raw_ostream &os = emitter.ostream();
    std::string control1 =
        emitter.getOrCreateQubitRegisterName(op.getControl1());
    std::optional<int64_t> ctrl1Index = op.getControl1Index();

    std::string control2 =
        emitter.getOrCreateQubitRegisterName(op.getControl2());
    std::optional<int64_t> ctrl2Index = op.getControl2Index();

    std::string target = emitter.getOrCreateQubitRegisterName(op.getTarget());
    std::optional<int64_t> targetIndex = op.getTargetIndex();

    os << "ccx"
       << " " << control1 << "[" << ctrl1Index << "]" << ", " << control2 << "["
       << ctrl2Index << "]" << ", " << target << "[" << targetIndex << "]"
       << ";\n";
    return success();
}

static LogicalResult printSwap(QASMEmitter &emitter, SwapOp op)
{
    raw_ostream &os = emitter.ostream();
    std::string lhs = emitter.getOrCreateQubitRegisterName(op.getLhs());
    std::optional<int64_t> lhsIndex = op.getLhsIndex();
    std::string rhs = emitter.getOrCreateQubitRegisterName(op.getRhs());
    std::optional<int64_t> rhsIndex = op.getRhsIndex();

    os << "swap"
       << " " << lhs << "[" << lhsIndex << "]" << ", " << rhs << "[" << rhsIndex
       << "]" << ";\n";
    return success();
}

static LogicalResult printMeasure(QASMEmitter &emitter, MeasureOp op)
{
    raw_ostream &os = emitter.ostream();
    std::string input = emitter.getOrCreateQubitRegisterName(op.getInput());
    std::optional<int64_t> inputIndex = op.getInputIndex();

    std::string result =
        emitter.getOrCreateClassicalRegisterName(op.getResult());
    std::optional<int64_t> resultIndex = op.getResultIndex();

    os << "measure"
       << " " << input << "[" << inputIndex << "]" << " -> " << result << "["
       << resultIndex << "]" << ";\n";
    return success();
}

static LogicalResult printBarrier(QASMEmitter &emitter, BarrierOp op)
{
    raw_ostream &os = emitter.ostream();
    bool isFirst = true;

    os << "barrier ";
    for (auto &&[operand, index] :
         llvm::zip_equal(op->getOperands(), op.getIndices()->getValue())) {
        if (isFirst)
            isFirst = false;
        else
            os << ", ";
        int64_t i = llvm::cast<IntegerAttr>(index).getInt();
        os << emitter.getOrCreateQubitRegisterName(operand) << "[" << i << "]";
    }
    os << ";\n";
    return success();
}

template<typename OpTy>
static LogicalResult
printControledRotationGate(QASMEmitter &emitter, OpTy op, std::string opname)
{
    raw_ostream &os = emitter.ostream();
    std::string control = emitter.getOrCreateQubitRegisterName(op.getControl());
    std::optional<int64_t> ctrlIndex = op.getControlIndex();
    std::string target = emitter.getOrCreateQubitRegisterName(op.getTarget());
    std::optional<int64_t> targetIndex = op.getTargetIndex();
    std::string theta = printOperand(op.getAngle());

    os << opname << "(" << theta << ") " << control << "[" << ctrlIndex << "]"
       << ", " << target << "[" << targetIndex << "]" << ";\n";
    return success();
}

static LogicalResult printU3(QASMEmitter &emitter, U3Op op)
{
    std::string t = printOperand(op.getTheta());
    std::string p = printOperand(op.getPhi());
    std::string l = printOperand(op.getLambda());
    raw_ostream &os = emitter.ostream();
    std::string name = emitter.getOrCreateQubitRegisterName(op.getInput());
    std::optional<int64_t> index = op.getIndex();

    os << "u3(" << t << "," << p << "," << l << ") " << name << "[" << index
       << "]" << ";\n";
    return success();
}

static LogicalResult printU2(QASMEmitter &emitter, U2Op op)
{
    std::string p = printOperand(op.getPhi());
    std::string l = printOperand(op.getLambda());
    raw_ostream &os = emitter.ostream();
    std::string name = emitter.getOrCreateQubitRegisterName(op.getInput());
    std::optional<int64_t> index = op.getIndex();

    os << "u2(" << p << "," << l << ") " << name << "[" << index << "];\n";
    return success();
}

static LogicalResult printU1(QASMEmitter &emitter, U1Op op)
{
    std::string l = printOperand(op.getLambda());
    raw_ostream &os = emitter.ostream();
    std::string name = emitter.getOrCreateQubitRegisterName(op.getInput());
    std::optional<int64_t> index = op.getIndex();

    os << "u1(" << l << ") " << name << "[" << index << "];\n";
    return success();
}

static LogicalResult printCU1(QASMEmitter &emitter, CU1Op op)
{
    std::string l = printOperand(op.getAngle());
    raw_ostream &os = emitter.ostream();
    std::string control = emitter.getOrCreateQubitRegisterName(op.getControl());
    std::optional<int64_t> controlIndex = op.getControlIndex();
    std::string target = emitter.getOrCreateQubitRegisterName(op.getTarget());
    std::optional<int64_t> targetIndex = op.getTargetIndex();

    os << "cu1(" << l << ") " << control << "[" << controlIndex << "], "
       << target << "[" << targetIndex << "];\n";
    return success();
}

static LogicalResult printIfOp(QASMEmitter &emitter, scf::IfOp ifOp)
{
    raw_ostream &os = emitter.ostream();
    Operation* conditionOp = ifOp.getCondition().getDefiningOp();

    os << "if(";

    // TODO: Short path if condition is a constant boo
    std::string creg;
    std::string condition;

    // The anchor point: extracting the result of the comparison tensor
    tensor::ExtractOp extractOp;

    // Case 1: scf.parallel reduces over the bits after comparison of
    // the measurement to an comparison tensor
    if (auto parallelOp = llvm::dyn_cast<scf::ParallelOp>(conditionOp)) {
        extractOp =
            llvm::dyn_cast<tensor::ExtractOp>(parallelOp.getBody()->front());
    } else {
        // Case 2: tensor.extract on the condition and result tensor
        extractOp = llvm::dyn_cast<tensor::ExtractOp>(conditionOp);
    }

    auto extractedFromTensorOp = extractOp.getTensor().getDefiningOp();
    qpu::ToBitsOp mt;
    llvm::SmallString<64> str;
    if (auto cmpOp = llvm::dyn_cast<arith::CmpIOp>(extractedFromTensorOp)) {
        mt = llvm::dyn_cast<qpu::ToBitsOp>(cmpOp.getLhs().getDefiningOp());
        assert(
            cmpOp.getPredicate() == arith::CmpIPredicate::eq
            && "Current support limited to equals");
        auto cst =
            llvm::dyn_cast<arith::ConstantOp>(cmpOp.getRhs().getDefiningOp());
        auto denseAttr = llvm::dyn_cast<DenseElementsAttr>(cst.getValue());

        APInt cond(denseAttr.getNumElements(), 0);
        unsigned bitIndex = 0;
        for (bool value : denseAttr.getValues<bool>())
            cond.setBitVal(bitIndex++, value);

        cond.toString(str, 10, false);
    } else if ((mt = llvm::dyn_cast<qpu::ToBitsOp>(extractedFromTensorOp))) {
        APInt cond = APInt::getAllOnes(mt.getResult().getType().getDimSize(0));
        cond.toString(str, 10, false);
    }

    creg = emitter.getOrCreateClassicalRegisterName(mt.getSrc());
    os << creg << "==" << str << ") ";
    return success();
}

static LogicalResult printCSwap(QASMEmitter &emitter, CSwapOp op)
{
    raw_ostream &os = emitter.ostream();
    std::string control = emitter.getOrCreateQubitRegisterName(op.getControl());
    std::optional<int64_t> controlIndex = op.getControlIndex();
    std::string lhs = emitter.getOrCreateQubitRegisterName(op.getLhs());
    std::optional<int64_t> lhsIndex = op.getLhsIndex();
    std::string rhs = emitter.getOrCreateQubitRegisterName(op.getRhs());
    std::optional<int64_t> rhsIndex = op.getRhsIndex();

    os << "cswap" << control << "[" << controlIndex << "], " << lhs << "["
       << lhsIndex << "], " << rhs << "[" << rhsIndex << "]" << ";\n";
    return success();
}

std::string QASMEmitter::getOrCreateQubitRegisterName(Value value)
{
    if (names.contains(value)) return names[value];

    std::string name = "q" + std::to_string(nextQubitId++);
    names.insert({value, name});
    return name;
}

std::string QASMEmitter::getOrCreateClassicalRegisterName(Value value)
{
    if (names.contains(value)) return names[value];

    std::string name = "c" + std::to_string(nextRegisterId++);
    names.insert({value, name});
    return name;
}

static LogicalResult walk(QASMEmitter &emitter, Operation* op)
{
    auto walk = op->walk<WalkOrder::PreOrder>([&](Operation* child) {
        auto status = emitter.emitOperation(*child);

        if (status.failed())
            emitError(
                child->getLoc(),
                "Interrupt of QILLR to QASM translation.");

        return WalkResult(status);
    });
    return failure(walk.wasInterrupted());
}

template<typename Op, const char* Name>
struct GateEntry {
    using OpType = Op;
    static constexpr const char* name = Name;
};

template<typename Op>
struct IgnoredEntry {
    using OpType = Op;
};

inline constexpr char H_NAME[] = "h";
inline constexpr char X_NAME[] = "x";
inline constexpr char Y_NAME[] = "y";
inline constexpr char Z_NAME[] = "z";
inline constexpr char S_NAME[] = "s";
inline constexpr char P_NAME[] = "p";
inline constexpr char SDG_NAME[] = "sdg";
inline constexpr char T_NAME[] = "t";
inline constexpr char ID_NAME[] = "id";
inline constexpr char SX_NAME[] = "sx";
inline constexpr char TDG_NAME[] = "tdg";
inline constexpr char RESET_NAME[] = "reset";

inline constexpr char RX_NAME[] = "rx";
inline constexpr char RY_NAME[] = "ry";
inline constexpr char RZ_NAME[] = "rz";

inline constexpr char CNOT_NAME[] = "cx";
inline constexpr char CZ_NAME[] = "cz";

inline constexpr char CRZ_NAME[] = "crz";
inline constexpr char CRY_NAME[] = "cry";

template<typename... Ts>
struct TypeList {};

using PrimitiveGates = TypeList<
    GateEntry<HOp, H_NAME>,
    GateEntry<XOp, X_NAME>,
    GateEntry<YOp, Y_NAME>,
    GateEntry<ZOp, Z_NAME>,
    GateEntry<SOp, S_NAME>,
    GateEntry<PhaseOp, P_NAME>,
    GateEntry<SdgOp, SDG_NAME>,
    GateEntry<TOp, T_NAME>,
    GateEntry<IdOp, ID_NAME>,
    GateEntry<SXOp, SX_NAME>,
    GateEntry<TdgOp, TDG_NAME>,
    GateEntry<ResetOp, RESET_NAME>>;

using RotationGates = TypeList<
    GateEntry<RxOp, RX_NAME>,
    GateEntry<RyOp, RY_NAME>,
    GateEntry<RzOp, RZ_NAME>>;

using ControlledGates =
    TypeList<GateEntry<CNOTOp, CNOT_NAME>, GateEntry<CZOp, CZ_NAME>>;

using ControlledRotationGates =
    TypeList<GateEntry<CRzOp, CRZ_NAME>, GateEntry<CRyOp, CRY_NAME>>;

using NoCodeGenOps = TypeList<
    IgnoredEntry<qpu::CircuitOp>,
    IgnoredEntry<qpu::ReturnOp>,
    IgnoredEntry<qpu::ToBitsOp>,
    IgnoredEntry<DeallocateOp>,
    IgnoredEntry<scf::YieldOp>,
    IgnoredEntry<scf::ParallelOp>,
    IgnoredEntry<scf::ReduceOp>,
    IgnoredEntry<scf::ReduceReturnOp>,
    IgnoredEntry<arith::ConstantOp>,
    IgnoredEntry<arith::CmpIOp>,
    IgnoredEntry<arith::AndIOp>,
    IgnoredEntry<tensor::ExtractOp>,
    IgnoredEntry<tensor::ConcatOp>>;

template<typename... Entries, typename Fn>
void addCases(
    llvm::TypeSwitch<Operation*, LogicalResult> &ts,
    Fn fn,
    TypeList<Entries...>)
{
    (ts.template Case<typename Entries::OpType>(
         [&](typename Entries::OpType op) {
             return fn.template operator()<Entries>(op);
         }),
     ...);
}

template<auto Fn>
auto forwardTo(QASMEmitter &emitter)
{
    return [&](auto op) -> LogicalResult { return Fn(emitter, op); };
}

} // namespace

LogicalResult QASMEmitter::emitOperation(Operation &op)
{
    auto primitivePrinter = [&]<typename Entries>(auto op) {
        return printPrimitiveGate(*this, op, Entries::name);
    };
    auto rotationPrinter = [&]<typename Entries>(auto op) {
        return printRotationGate(*this, op, Entries::name);
    };
    auto controlledPrinter = [&]<typename Entries>(auto op) {
        return printControledGate(*this, op, Entries::name);
    };
    auto controlledRotationPrinter = [&]<typename Entries>(auto op) {
        return printControledRotationGate(*this, op, Entries::name);
    };

    auto ts = TypeSwitch<Operation*, LogicalResult>(&op);

    addCases(ts, primitivePrinter, PrimitiveGates{});
    addCases(ts, rotationPrinter, RotationGates{});
    addCases(ts, controlledPrinter, ControlledGates{});
    addCases(ts, controlledRotationPrinter, ControlledRotationGates{});
    addCases(
        ts,
        [&]<typename Entries>(auto) { return success(); },
        NoCodeGenOps{});

    LogicalResult result =
        ts
            // special cases
            .Case<AllocOp>(forwardTo<printQubitAlloc>(*this))
            .Case<AllocResultOp>(forwardTo<printResultAlloc>(*this))
            .Case<MeasureOp>(forwardTo<printMeasure>(*this))
            .Case<BarrierOp>(forwardTo<printBarrier>(*this))
            .Case<CCXOp>(forwardTo<printToffoli>(*this))
            .Case<SwapOp>(forwardTo<printSwap>(*this))
            .Case<CSwapOp>(forwardTo<printCSwap>(*this))
            .Case<U3Op>(forwardTo<printU3>(*this))
            .Case<U2Op>(forwardTo<printU2>(*this))
            .Case<U1Op>(forwardTo<printU1>(*this))
            .Case<CU1Op>(forwardTo<printCU1>(*this))
            .Case<scf::IfOp>(forwardTo<printIfOp>(*this))
            // rest unchanged
            .Default([](Operation* op) {
                emitError(
                    op->getLoc(),
                    llvm::formatv(
                        "No codegen for operation {}.",
                        op->getName()));
                return failure();
            });

    if (failed(result)) return failure();
    return result;
}

LogicalResult qillr::QILLRTranslateToQASM(Operation* op, raw_ostream &os)
{
    QASMEmitter emitter(os);
    printHeader(emitter);

    auto result = op->walk<WalkOrder::PreOrder>([&](qpu::CircuitOp circuit) {
        return WalkResult(walk(emitter, circuit));
    });
    return failure(result.wasInterrupted());
}
