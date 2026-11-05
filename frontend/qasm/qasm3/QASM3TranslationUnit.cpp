//===---- QASM3TranslationUnit.cpp - OpenQASM 3 Translation Unit --------===//
//
// @author  Lars Schütze (lars.schuetze@tu-dresden.de)
//===----------------------------------------------------------------------===//

#include "QASM3TranslationUnit.h"

#include <cassert>
#include <llvm/ADT/STLExtras.h>
#include <llvm/ADT/SmallString.h>
#include <llvm/Support/FileSystem.h>
#include <llvm/Support/Path.h>

namespace quantum::frontend::qasm3 {

static std::string getSourceIdentity(llvm::StringRef filename)
{
    if (filename.empty() || filename == "-" || filename.starts_with("<"))
        return filename.str();

    // Resolve symlinks as well as dot components so alternate spellings cannot
    // evade cycle detection. Keep diagnostic filenames independent of identity.
    llvm::SmallString<256> path;
    if (!llvm::sys::fs::real_path(filename, path)) return path.str().str();
    path = filename;
    if (llvm::sys::fs::make_absolute(path)) return filename.str();
    llvm::sys::path::remove_dots(path, true);
    return path.str().str();
}

bool QASM3TranslationUnit::isSourceActive(llvm::StringRef filename) const
{ return llvm::is_contained(activeSources, getSourceIdentity(filename)); }

void QASM3TranslationUnit::enterSource(llvm::StringRef filename)
{
    assert(!isSourceActive(filename) && "recursive include must be rejected");
    activeSources.push_back(getSourceIdentity(filename));
}

void QASM3TranslationUnit::leaveSource()
{
    assert(!activeSources.empty() && "no source is active");
    activeSources.pop_back();
}

} // namespace quantum::frontend::qasm3
